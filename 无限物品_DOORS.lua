--[[
	无限物品 · DOORS  (v4)
	从 Abysall Hub 提取：InfiniteItemsToggle + 假 prompt 系统 + 可靠的 prompt 触发内核
	无 UI，执行即用。

	═══════════ 为什么前三版都不行 ═══════════
	v1/v2：在真 prompt 的 PromptTriggered 里丢工具
	       → 服务器在你按下的那一刻就扣了，手里已经空 ✗
	v3    ：补了假 prompt，但触发真 prompt 用的是 fireproximityprompt
	       → 真 prompt 在 gethui() 里，mcd 只有 60，大概率直接失败 ✗
	v4    ：触发内核换成原版 7750-7773 的办法——
	       把 prompt 临时挂到相机前 0.1 studs 的透明 Part 上，
	       用 Roblox 原生 Prompt:InputHoldBegin() / InputHoldEnd()。
	       这是纯 Roblox API，不依赖执行器有没有 fireproximityprompt。

	═══════════ 三段式（对应原版行号）═══════════
	A. 藏真 prompt、原位置放客户端克隆        7486-7545
	B. 假货被按：先挂 Drops.ChildAdded → 丢工具  7991-8006
	C. 掉落物出现：点它的 ModulePrompt 捡回 → 触发真货开锁  7993-7998

	═══════════ 先跑一次看诊断 ═══════════
	执行后会立刻打印 4 行状态。如果哪一行是「没有 / 0 个」，那就是卡点：
	  · fireproximityprompt / InputHoldBegin 都没有 → 执行器不支持
	  · workspace.Drops 还没有                      → 正常，有人丢过东西才有
	  · 已接管 0 个锁类 prompt                      → prompt 名字变了，见 CONFIG
]]

if getgenv().AbyInfItemsStop then
	pcall(getgenv().AbyInfItemsStop)
	getgenv().AbyInfItemsStop = nil
end

local CONFIG = {
	Items = {
		Lockpick = true,
		SkeletonKey = true,
		Shears = true,
		Multitool = true,
	},

	-- 会被换成假 prompt 的提示名
	ConsumingPrompts = {
		UnlockPrompt = true,
		SkullPrompt = true,
		LockPrompt = true,
		ThingToEnable = true,
		FusesPrompt = true,
		CuttableVines = true,
		Chest_Vine = true,
		Cellar = true,
		SkullLock = true,
		Lock1 = true,
		Lock2 = true,
		ActivateEventPrompt = true,
	},

	InstantPrompts = true, -- 假 prompt 按住时长归零
	PromptReach = 60, -- 假 prompt 的可按距离（studs）
	PickupTries = 15,
	PickupDelay = 0.05,
	WatchTimeout = 2,
	Verbose = true,
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local running = true

local FakeOf = {} -- 假 → 真
local Fakes = {} -- 所有假货，停止时清掉
local SavedParent = {} -- 真 → 原父级

local function log(...)
	if CONFIG.Verbose then
		print("[无限物品] " .. table.concat({ ... }, " "))
	end
end

----------------------------------------------------------------------
-- 藏真 prompt 的容器
----------------------------------------------------------------------

local function getHiddenContainer()
	if type(gethui) == "function" then
		local ok, gui = pcall(gethui)
		if ok and gui then
			return gui
		end
	end
	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and cg then
		return cg
	end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local Container = Instance.new("Folder")
Container.Name = "AbyInfItemsPrompts"
Container.Parent = getHiddenContainer()

----------------------------------------------------------------------
-- ★ 可靠触发内核（原版 7750-7773）
----------------------------------------------------------------------
-- 优先用执行器的 fireproximityprompt；不行就把 prompt 临时挂到相机前，
-- 用纯 Roblox 的 InputHoldBegin/InputHoldEnd 打。两条路都失败才返回 false。

local fireStats = { executor = 0, native = 0, failed = 0 }

local function firePromptNative(prompt)
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end

	local saved = {}
	saved.Parent = prompt.Parent
	saved.Distance = prompt.MaxActivationDistance
	saved.Enabled = prompt.Enabled
	saved.Hold = prompt.HoldDuration
	saved.LOS = prompt.RequiresLineOfSight

	local part = Instance.new("Part")
	part.Name = "AbyInfTempPromptPart"
	part.Size = Vector3.new(0.001, 0.001, 0.001)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	part.Position = camera.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.1)).Position
	part.Parent = Workspace

	prompt.MaxActivationDistance = 99999
	prompt.Enabled = true
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	pcall(function()
		prompt.Parent = part
	end)

	local fired = false
	local conn = prompt.Triggered:Connect(function()
		fired = true
	end)

	for _ = 1, 5 do
		if fired then
			break
		end
		pcall(function()
			prompt:InputHoldBegin()
		end)
		pcall(function()
			prompt:InputHoldEnd()
		end)
		task.wait()
	end

	pcall(function()
		conn:Disconnect()
	end)

	pcall(function()
		prompt.MaxActivationDistance = saved.Distance
		prompt.Enabled = saved.Enabled
		prompt.HoldDuration = saved.Hold
		prompt.RequiresLineOfSight = saved.LOS
		if saved.Parent and saved.Parent.Parent then
			prompt.Parent = saved.Parent
		end
	end)

	pcall(function()
		part:Destroy()
	end)

	return fired
end

local function firePrompt(prompt)
	if not prompt or not prompt.Parent then
		return false
	end
	if type(prompt) ~= "userdata" and type(prompt) ~= "table" then
		return false
	end

	if type(fireproximityprompt) == "function" then
		local ok, result = pcall(fireproximityprompt, prompt)
		if ok then
			fireStats.executor = fireStats.executor + 1
			return true
		end
	end

	if firePromptNative(prompt) then
		fireStats.native = fireStats.native + 1
		return true
	end

	fireStats.failed = fireStats.failed + 1
	return false
end

----------------------------------------------------------------------
-- 小工具
----------------------------------------------------------------------

local function getWhitelistedTool()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then
		return nil
	end
	if not CONFIG.Items[tool.Name] then
		return nil
	end
	return tool
end

local function getDropsFolder()
	return Workspace:FindFirstChild("Drops")
end

local function getDropItemRemote()
	local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
	return remotes and remotes:FindFirstChild("DropItem")
end

local function isLockPrompt(prompt)
	if CONFIG.ConsumingPrompts[prompt.Name] then
		return true
	end
	local parent = prompt.Parent
	if parent then
		if parent:GetAttribute("Locked") == true then
			return true
		end
		if parent.Parent and parent.Parent.Name == "Locker_Small_Locked" then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- A. 假 prompt
----------------------------------------------------------------------

local fakedCount = 0

local function installFake(prompt)
	if not running or not prompt or not prompt.Parent then
		return false
	end
	if prompt:GetAttribute("FakePrompt") or prompt:GetAttribute("AbyInfFaked") then
		return false
	end
	if not isLockPrompt(prompt) then
		return false
	end

	prompt:SetAttribute("AbyInfFaked", true)
	prompt:SetAttribute("AbyInfHold", prompt.HoldDuration)
	prompt:SetAttribute("AbyInfReach", prompt.MaxActivationDistance)
	prompt:SetAttribute("AbyInfLOS", prompt.RequiresLineOfSight)

	local okFake, fake = pcall(function()
		return prompt:Clone()
	end)
	if not okFake or not fake then
		return false
	end

	fake:SetAttribute("FakePrompt", true)
	task.wait()

	local originalParent = prompt.Parent
	SavedParent[prompt] = originalParent
	fake.Parent = originalParent

	fake.HoldDuration = CONFIG.InstantPrompts and 0 or prompt.HoldDuration
	fake.RequiresLineOfSight = false
	fake.MaxActivationDistance = CONFIG.PromptReach

	FakeOf[fake] = prompt
	Fakes[#Fakes + 1] = fake

	local enabledConn = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if fake and fake.Parent then
			fake.Enabled = prompt.Enabled
		end
	end)

	prompt.MaxActivationDistance = 99999
	pcall(function()
		prompt.Parent = Container
	end)

	prompt.Destroying:Once(function()
		pcall(function()
			enabledConn:Disconnect()
		end)
		FakeOf[fake] = nil
		if fake and fake.Parent then
			fake:Destroy()
		end
	end)

	fake.Enabled = false
	task.wait()
	fake.Enabled = prompt.Enabled

	return true
end

local function scanPrompts(root)
	if not running then
		return
	end
	local ok, list = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or not list then
		return
	end
	for _, object in ipairs(list) do
		if object:IsA("ProximityPrompt") and installFake(object) then
			fakedCount = fakedCount + 1
		end
	end
end

----------------------------------------------------------------------
-- C. 掉落物 → 捡回 + 开锁
----------------------------------------------------------------------

local function handleDropped(model, realPrompt)
	task.spawn(function()
		local prompt
		for _ = 1, CONFIG.PickupTries do
			if not model or not model.Parent then
				break
			end
			prompt = model:FindFirstChild("ModulePrompt", true)
			if prompt then
				break
			end
			task.wait(CONFIG.PickupDelay)
		end

		if prompt then
			if firePrompt(prompt) then
				log(("已把 %s 捡回背包"):format(tostring(model.Name)))
			else
				warn("[无限物品] 捡回失败（触发内核两种办法都失败）")
			end
		else
			warn(("[无限物品] %s 上没有 ModulePrompt —— 这份要自己手动捡")
				:format(tostring(model and model.Name)))
		end

		if realPrompt then
			task.wait(0.05)
			if firePrompt(realPrompt) then
				log("已补触发真 prompt（开锁）")
			else
				warn("[无限物品] 开锁那一下触发失败 —— 这就是你看到「没用」的原因")
			end
		end
	end)
end

----------------------------------------------------------------------
-- B. 假货被按
----------------------------------------------------------------------

local function onPromptTriggered(triggered, player)
	if not running or player ~= LocalPlayer then
		return
	end
	if not triggered:GetAttribute("FakePrompt") then
		return
	end

	local realPrompt = FakeOf[triggered]
	if not realPrompt then
		return
	end

	local tool = getWhitelistedTool()
	if not tool then
		firePrompt(realPrompt)
		return
	end

	local drops = getDropsFolder()
	local remote = getDropItemRemote()
	if not drops or not remote then
		warn("[无限物品] 缺 " .. (not drops and "workspace.Drops" or "RemotesFolder.DropItem") .. "，走正常流程")
		firePrompt(realPrompt)
		return
	end

	local connection
	local settled = false
	local function finish()
		settled = true
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
			connection = nil
		end
	end

	connection = drops.ChildAdded:Connect(function(newChild)
		if settled then
			return
		end
		finish()
		if newChild then
			handleDropped(newChild, realPrompt)
		end
	end)

	task.delay(CONFIG.WatchTimeout, function()
		if not settled then
			finish()
			warn("[无限物品] 丢出去后 " .. CONFIG.WatchTimeout .. " 秒没等到掉落物 —— 补触发真 prompt")
			firePrompt(realPrompt)
		end
	end)

	local ok, err = pcall(function()
		remote:FireServer(tool)
	end)
	if not ok then
		finish()
		warn("[无限物品] DropItem 失败：" .. tostring(err))
		firePrompt(realPrompt)
		return
	end

	log(("按下 %s → 已丢出 %s"):format(triggered.Name, tool.Name))
end

----------------------------------------------------------------------
-- 启动 + 诊断
----------------------------------------------------------------------

getgenv().AbyInfItemsConn = ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

task.spawn(function()
	scanPrompts(Workspace)

	local samplePrompt
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			samplePrompt = v
			break
		end
	end
	log(("诊断  触发内核: fireproximityprompt=%s  原生InputHoldBegin=%s")
		:format(
			type(fireproximityprompt) == "function" and "有" or "没有",
			(samplePrompt and type(samplePrompt.InputHoldBegin) == "function") and "有" or "没有"
		))
	log(("诊断  workspace.Drops=%s   DropItem=%s")
		:format(getDropsFolder() and "有" or "还没有", getDropItemRemote() and "有" or "没有"))
	log(("诊断  已接管 %d 个锁类 prompt"):format(fakedCount))

	if fakedCount == 0 then
		warn("[无限物品] 没找到任何锁类 prompt。请走到有门/锁的地方。若那时仍然是 0，说明 prompt 名字变了——")
		warn("[无限物品] 在控制台跑这一行把名字发我：")
		warn([[for _,v in ipairs(game.Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then print(v.Name, v.Parent and v.Parent.Name) end end]])
	end

	log("用法：拿着 Lockpick / SkeletonKey / Shears / Multitool 去按锁，工具不消耗。")
	log("关掉：getgenv().AbyInfItemsStop()")
end)

local scanConn = Workspace.DescendantAdded:Connect(function(object)
	if not running then
		return
	end
	if object:IsA("ProximityPrompt") then
		task.defer(function()
			if installFake(object) then
				fakedCount = fakedCount + 1
				log(("新接管 %s（累计 %d）"):format(object.Name, fakedCount))
			end
		end)
	end
end)

getgenv().AbyInfItemsStop = function()
	running = false
	if getgenv().AbyInfItemsConn then
		pcall(function()
			getgenv().AbyInfItemsConn:Disconnect()
		end)
		getgenv().AbyInfItemsConn = nil
	end
	pcall(function()
		scanConn:Disconnect()
	end)

	for fake, real in pairs(FakeOf) do
		if real then
			local originalParent = SavedParent[real]
			pcall(function()
				if originalParent and originalParent.Parent then
					real.Parent = originalParent
				end
				real.MaxActivationDistance = real:GetAttribute("AbyInfReach") or real.MaxActivationDistance
				real.HoldDuration = real:GetAttribute("AbyInfHold") or real.HoldDuration
				real.RequiresLineOfSight = real:GetAttribute("AbyInfLOS")
			end)
		end
		pcall(function()
			fake:Destroy()
		end)
	end

	FakeOf = {}
	SavedParent = {}
	pcall(function()
		Container:Destroy()
	end)

	log(("已停止并还原。触发统计：执行器 %d 次 / 原生 %d 次 / 失败 %d 次")
		:format(fireStats.executor, fireStats.native, fireStats.failed))
end

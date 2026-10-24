--[[
	无限物品 · DOORS  (v3 / 完整复刻)
	从 Abysall Hub 提取：InfiniteItemsToggle + 它依赖的假 prompt 系统
	无 UI，执行即用。

	════════════════ 为什么 v1、v2 都不能用 ════════════════
	不是白名单写错，也不是事件挂错，是【时序上不可能对】：

	  你按下真 prompt 的那一刻，服务器就已经把工具扣掉了。
	  等客户端收到 PromptTriggered 再去丢，手里已经空了。

	原版之所以能用，是因为它先把真 prompt 藏进 gethui()，
	在原位置放一个**客户端克隆**，让你按到的永远是假货 ——
	假货服务器收不到，脚本这时才有时间「先丢工具、再手动触发真的」。

	所以这一版把三步全做了：
	  A. 藏真 prompt、放假 prompt        （原版 7486-7545）
	  B. 假 prompt 被按时：先挂监听 → 丢工具 （原版 7991-8006）
	  C. 掉落物出现 → 点它的 ModulePrompt 捡回，同时触发真的 → 开锁（原版 7993-7998）

	════════════════ 必须满足 ════════════════
	· 工具拿在手上（Character:FindFirstChildOfClass("Tool")）
	· 执行器有 fireproximityprompt（Delta 有）
	· 白名单默认 4 个：Lockpick / SkeletonKey / Shears / Multitool

	停止 / 还原：getgenv().AbyInfItemsStop()
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
		-- Key = true, KeyElectrical = true, KeyBackdoor = true,
		-- KeyIron = true, GeneratorFuse = true,
	},

	-- 会被替换成假 prompt 的提示名（原版 LockPromptNames + 剪藤蔓那几个）
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

	InstantPrompts = true, -- 假 prompt 按住时间归零（点一下就触发）
	PromptReach = 60, -- 真/假 prompt 的触发距离（studs）
	PickupTries = 15,
	PickupDelay = 0.05,
	WatchTimeout = 1.5,
	Verbose = true,
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local running = true

local FakeOf = {} -- 假 prompt → 真 prompt
local Fakes = {} -- 全部假 prompt（停止时清理）
local SavedParent = {} -- 真 prompt → 它原来的父级

local function log(...)
	if CONFIG.Verbose then
		print("[无限物品] " .. table.concat({ ... }, " "))
	end
end

----------------------------------------------------------------------
-- 藏真 prompt 用的容器
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

local Container
do
	local parent = getHiddenContainer()
	Container = Instance.new("Folder")
	Container.Name = "AbyInfItemsPrompts"
	Container.Parent = parent
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

local function firePrompt(prompt)
	if not prompt or not prompt.Parent then
		return false
	end
	if type(fireproximityprompt) ~= "function" then
		return false
	end
	local ok = pcall(fireproximityprompt, prompt)
	return ok
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
-- A. 把真 prompt 换成一个客户端克隆
----------------------------------------------------------------------

local function installFake(prompt)
	if not running then
		return false
	end
	if not prompt or not prompt.Parent then
		return false
	end
	if prompt:GetAttribute("FakePrompt") then
		return false
	end
	if prompt:GetAttribute("AbyInfFaked") then
		return false
	end
	if not isLockPrompt(prompt) then
		return false
	end

	prompt:SetAttribute("AbyInfFaked", true)

	local savedHold = prompt.HoldDuration
	local savedReach = prompt.MaxActivationDistance
	local savedLOS = prompt.RequiresLineOfSight
	prompt:SetAttribute("AbyInfHold", savedHold)
	prompt:SetAttribute("AbyInfReach", savedReach)
	prompt:SetAttribute("AbyInfLOS", savedLOS)

	local okFake, fake = pcall(function()
		return prompt:Clone()
	end)
	if not okFake or not fake then
		return false
	end

	fake:SetAttribute("FakePrompt", true)
	fake.Name = prompt.Name
	task.wait()
	fake.Parent = prompt.Parent

	fake.HoldDuration = CONFIG.InstantPrompts and 0 or savedHold
	fake.RequiresLineOfSight = false
	fake.MaxActivationDistance = CONFIG.PromptReach

	FakeOf[fake] = prompt
	Fakes[#Fakes + 1] = fake
	SavedParent[prompt] = prompt.Parent

	-- 真 prompt 的可用状态同步给假货
	local enabledConn = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if fake and fake.Parent then
			fake.Enabled = prompt.Enabled
		end
	end)

	-- 真 prompt 被搬进 gethui()，玩家再也按不到它
	local okMove = pcall(function()
		prompt.Parent = Container
	end)
	prompt.MaxActivationDistance = CONFIG.PromptReach

	-- 真的没了就把假的也清掉
	prompt.Destroying:Once(function()
		pcall(function()
			enabledConn:Disconnect()
		end)
		FakeOf[fake] = nil
		if fake and fake.Parent then
			fake:Destroy()
		end
	end)

	-- 假的先关一下再开，逼客户端重建提示
	fake.Enabled = false
	task.wait()
	fake.Enabled = prompt.Enabled

	return okMove
end

local fakedCount = 0

local function scanForPrompts(root)
	if not running then
		return
	end
	local ok, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or not descendants then
		return
	end
	for _, object in ipairs(descendants) do
		if object:IsA("ProximityPrompt") then
			if installFake(object) then
				fakedCount = fakedCount + 1
			end
		end
	end
end

----------------------------------------------------------------------
-- C. 掉落物出现 → 捡回 + 触发真 prompt
----------------------------------------------------------------------

local function pickUpDropped(model, realPrompt)
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
			local ok = firePrompt(prompt)
			if ok then
				log(("已把 %s 捡回"):format(tostring(model.Name)))
			else
				warn("[无限物品] 捡回时 fireproximityprompt 失败")
			end
		else
			warn(("[无限物品] 掉落物上没有 ModulePrompt（%s）—— 这次要自己手动捡")
				:format(tostring(model and model.Name)))
		end

		-- 不管有没有捡回来，真 prompt 都要触发，否则锁打不开
		if realPrompt then
			task.wait(0.05)
			firePrompt(realPrompt)
		end
	end)
end

----------------------------------------------------------------------
-- B. 假 prompt 被按下的处理
----------------------------------------------------------------------

local function onPromptTriggered(triggered, player)
	if not running then
		return
	end
	if player ~= LocalPlayer then
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
		-- 没拿白名单工具：直接补触发真的，等于正常操作
		firePrompt(realPrompt)
		return
	end

	local drops = getDropsFolder()
	local remote = getDropItemRemote()
	if not drops or not remote then
		warn("[无限物品] 缺少 " .. (not drops and "workspace.Drops" or "RemotesFolder.DropItem")
			.. "，这次直接走正常流程")
		firePrompt(realPrompt)
		return
	end

	-- ① 先挂监听（顺序不能反）
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
			pickUpDropped(newChild, realPrompt)
		end
	end)

	task.delay(CONFIG.WatchTimeout, function()
		if not settled then
			finish()
			warn("[无限物品] 丢出去后没等到掉落物，直接补触发真 prompt")
			firePrompt(realPrompt)
		end
	end)

	-- ② 把工具丢出去（服务器这边手里就空了）
	local ok, err = pcall(function()
		remote:FireServer(tool)
	end)
	if not ok then
		finish()
		warn("[无限物品] DropItem 调用失败：" .. tostring(err))
		firePrompt(realPrompt)
		return
	end

	log(("按下 %s → 丢出 %s"):format(triggered.Name, tool.Name))
end

----------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------

if type(fireproximityprompt) ~= "function" then
	warn("[无限物品] 执行器没有 fireproximityprompt，这个功能用不了")
	return
end

getgenv().AbyInfItemsConn = ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

-- 先扫当前房间，再盯着后续生成的
task.spawn(function()
	scanForPrompts(Workspace)
	log(("已接管 %d 个锁类 prompt"):format(fakedCount))
	if fakedCount == 0 then
		warn("[无限物品] 当前场景没有找到锁类 prompt —— 走到有门/锁的地方会自动接管")
	end
end)

local scanConn = Workspace.DescendantAdded:Connect(function(object)
	if object:IsA("ProximityPrompt") then
		task.defer(function()
			if installFake(object) then
				fakedCount = fakedCount + 1
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

	-- 把真 prompt 放回原位，删掉假的
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

	print("[无限物品] 已停止并把 prompt 全部还原")
end

log(("执行器 fireproximityprompt: %s；workspace.Drops: %s；DropItem remote: %s")
	:format(
		type(fireproximityprompt) == "function" and "有" or "没有",
		getDropsFolder() and "有" or "还没有",
		getDropItemRemote() and "有" or "没有"
	))
log("用法：拿着 Lockpick / SkeletonKey / Shears / Multitool 去按锁，工具不会消耗。")
log("关掉：getgenv().AbyInfItemsStop()")

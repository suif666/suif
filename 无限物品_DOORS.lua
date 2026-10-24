--[[
	无限物品 · DOORS  (v5)
	实现来源：小西源码/DOORSXIAOXI.lua 的 InfItems（6698-6965）
	         对照 Abysall 的 InfiniteItemsToggle（7954-8006）
	无 UI，执行即用。

	═══════════ 这次为什么能对 ═══════════
	前三版的方向是错的：

	v1/v2  在真 prompt 的 PromptTriggered 里丢工具
	       → 服务器按下那一刻就扣了，太晚 ✗
	v3     补了假 prompt，但把真 prompt 搬进 gethui() 再用 fireproximityprompt 打
	       → 搬走之后打不动 ✗
	v4     改成「相机前临时 Part + InputHoldBegin」
	       → InputHoldBegin 要求 prompt 可见，对已禁用的 prompt 必然失败 ✗

	小西这套的关键只有三句：
	   real.Enabled        = false      ← 真货只禁用，留在原地
	   real.ClickablePrompt= false
	   fake.Enabled        = true       ← 假货接在原位置
	   fake.ClickablePrompt= true

	而 fireproximityprompt 对【已禁用】的 prompt 依然有效 ——
	所以根本不需要搬去 gethui()，也不需要 InputHoldBegin。

	═══════════ 流程 ═══════════
	① 你身上（手上或背包）有某把工具时，才把它对应的锁类 prompt 换成假货
	② 你按假货 → 假货的 Triggered 在客户端触发（服务器收不到）
	③ DropItem:FireServer(工具)  → 工具离开你
	④ workspace.Drops.ChildAdded → 找到掉出来的那份上的 ProximityPrompt
	⑤ 先点亮它的 prompt（捡回来），再 fireproximityprompt(真货) → 开锁
	→ 锁开了，工具回来了

	停止 / 还原：getgenv().AbyInfItemsStop()
]]

if getgenv().AbyInfItemsStop then
	pcall(getgenv().AbyInfItemsStop)
	getgenv().AbyInfItemsStop = nil
end

local CONFIG = {
	-- 工具名                              → 对应的锁类 prompt
	Groups = {
		{
			Tools = { "Lockpick", "SkeletonKey", "Multitool" },
			Parents = {
				ChestBoxLocked = true,
				Locker_Small_Locked = true,
				Toolbox_Locked = true,
			},
			Names = {
				UnlockPrompt = true,
				ThingToEnable = true,
				LockPrompt = true,
				SkullPrompt = true,
				FusesPrompt = true,
				Lock1 = true,
				Lock2 = true,
				SkullLock = true,
				ActivateEventPrompt = true,
			},
		},
		{
			Tools = { "Shears", "Multitool" },
			Parents = {
				Chest_Vine = true,
				CuttableVines = true,
				Cellar = true,
			},
			Names = {
				SkullPrompt = true,
			},
		},
		{
			Tools = { "Key" },
			Parents = {
				Keyhole = true,
				LockedDoor = true,
			},
			Names = {
				KeyPrompt = true,
			},
		},
		{
			Tools = { "Crowbar" },
			Parents = {
				SealedCrate = true,
				Boarded = true,
			},
			Names = {
				PryPrompt = true,
			},
		},
	},

	AttachInterval = 0.2, -- 多久重新扫一次（有工具才接管）
	DropTimeout = 1, -- 丢出去后等掉落物最多多久
	CleanupDelay = 0.25, -- 捡回后多久断开监听
	Verbose = true,
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local running = true

local stats = { attached = 0, triggered = 0, fired = 0, failed = 0 }

local function log(...)
	if CONFIG.Verbose then
		print("[无限物品] " .. table.concat({ ... }, " "))
	end
end

----------------------------------------------------------------------
-- 基础
----------------------------------------------------------------------

local function getRemoteFolder()
	return ReplicatedStorage:FindFirstChild("EntityInfo")
		or ReplicatedStorage:FindFirstChild("RemotesFolder")
		or ReplicatedStorage:FindFirstChild("Bricks")
end

local function getDropItem()
	local folder = getRemoteFolder()
	return folder and folder:FindFirstChild("DropItem")
end

local function getRoomFolder()
	return Workspace:FindFirstChild("CurrentRooms")
end

-- 手上或背包里有就算有
local function hasToolAnywhere(toolName)
	local char = LocalPlayer.Character
	if char and char:FindFirstChild(toolName) then
		return true
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end
	return false
end

-- 按名字找工具：先手上，再背包
local function findToolByName(search)
	search = string.lower(search)
	local char = LocalPlayer.Character
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") and string.lower(child.Name):find(search, 1, true) then
				return child
			end
		end
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and string.lower(child.Name):find(search, 1, true) then
				return child
			end
		end
	end
	return nil
end

local function fireInteract(prompt)
	if not prompt or not prompt.Parent then
		return false
	end
	if type(fireproximityprompt) == "function" then
		local ok = pcall(fireproximityprompt, prompt)
		if ok then
			stats.fired = stats.fired + 1
			return true
		end
	end

	-- 兜底：临时启用后再打一次
	local wasEnabled = prompt.Enabled
	pcall(function()
		prompt.Enabled = true
	end)
	local ok = false
	if type(fireproximityprompt) == "function" then
		ok = pcall(fireproximityprompt, prompt)
	end
	pcall(function()
		prompt.Enabled = wasEnabled
	end)

	if ok then
		stats.fired = stats.fired + 1
	else
		stats.failed = stats.failed + 1
	end
	return ok
end

----------------------------------------------------------------------
-- 假 prompt
----------------------------------------------------------------------

local Fakes = {} -- fake → real（停止时还原）

local function addFake(realPrompt, toolName)
	if not running then
		return
	end
	if not realPrompt or not realPrompt:IsA("ProximityPrompt") then
		return
	end
	if realPrompt:GetAttribute("HasFake") then
		return
	end
	if not realPrompt.Parent then
		return
	end

	realPrompt:SetAttribute("HasFake", true)

	local okClone, fake = pcall(function()
		return realPrompt:Clone()
	end)
	if not okClone or not fake then
		return
	end

	fake.Name = "FakePrompt"
	fake.Parent = realPrompt.Parent
	fake.Enabled = true
	fake.ClickablePrompt = true
	fake.MaxActivationDistance = math.max(fake.MaxActivationDistance, 20)
	fake.RequiresLineOfSight = false
	fake.HoldDuration = 0

	realPrompt.Enabled = false
	realPrompt.ClickablePrompt = false

	Fakes[fake] = realPrompt
	stats.attached = stats.attached + 1

	fake.Triggered:Connect(function()
		if not running then
			return
		end
		if fake:GetAttribute("AbyInfBusy") then
			return
		end

		local tool = findToolByName(toolName)
		if not tool then
			return
		end

		local dropItem = getDropItem()
		local drops = Workspace:FindFirstChild("Drops")
		if not dropItem or not drops then
			warn("[无限物品] 缺 DropItem 或 workspace.Drops，走正常流程")
			fireInteract(realPrompt)
			return
		end

		fake:SetAttribute("AbyInfBusy", true)
		stats.triggered = stats.triggered + 1
		log(("按下 %s（%s）→ 丢出 %s"):format(fake.Name, toolName, tool.Name))

		-- 先挂监听，再丢
		local connection
		local timedOut = false

		connection = drops.ChildAdded:Connect(function(newChild)
			if timedOut then
				pcall(function()
					connection:Disconnect()
				end)
				return
			end

			-- 按类找，不按名字找
			local newPrompt = newChild:FindFirstChildOfClass("ProximityPrompt")
			if not newPrompt then
				return
			end

			pcall(function()
				connection:Disconnect()
			end)

			-- 顺序按工具分（照抄小西）
			local lower = string.lower(toolName)
			if lower:find("lockpick", 1, true) then
				fireInteract(newPrompt)
				fireInteract(realPrompt)
			elseif lower:find("shears", 1, true) then
				fireInteract(realPrompt)
				fireInteract(newPrompt)
			else
				fireInteract(newPrompt)
				fireInteract(realPrompt)
			end

			task.wait(CONFIG.CleanupDelay)
			pcall(function()
				connection:Disconnect()
			end)
			pcall(function()
				fake:SetAttribute("AbyInfBusy", nil)
			end)
		end)

		task.delay(CONFIG.DropTimeout, function()
			timedOut = true
			pcall(function()
				connection:Disconnect()
			end)
			pcall(function()
				fake:SetAttribute("AbyInfBusy", nil)
			end)
			warn("[无限物品] 丢出去后没等到掉落物，直接补触发真 prompt")
			fireInteract(realPrompt)
		end)

		local ok, err = pcall(function()
			dropItem:FireServer(tool)
		end)
		if not ok then
			pcall(function()
				connection:Disconnect()
			end)
			fake:SetAttribute("AbyInfBusy", nil)
			warn("[无限物品] DropItem 失败：" .. tostring(err))
			fireInteract(realPrompt)
		end
	end)
end

----------------------------------------------------------------------
-- 扫描 / 重新接管
----------------------------------------------------------------------

local Stores = {} -- 每组一份：{ group = G, list = {...} }

local function scanGroup(group)
	local rooms = getRoomFolder()
	local found = {}
	if not rooms then
		return found
	end
	for _, object in ipairs(rooms:GetDescendants()) do
		if object:IsA("ProximityPrompt") and object.Name ~= "FakePrompt" then
			local parentName = object.Parent and object.Parent.Name
			if (parentName and group.Parents[parentName]) or group.Names[object.Name] then
				found[#found + 1] = object
			end
		end
	end
	return found
end

local function tryAttachAll()
	if not running then
		return
	end
	for _, store in ipairs(Stores) do
		-- 只有身上有这把工具，才接管对应 prompt
		local owned = false
		for _, toolName in ipairs(store.group.Tools) do
			if hasToolAnywhere(toolName) then
				owned = true
				break
			end
		end

		if owned then
			for _, prompt in ipairs(store.list) do
				if prompt and prompt.Parent and not prompt:GetAttribute("HasFake") then
					local toolName = store.group.Tools[1]
					for _, name in ipairs(store.group.Tools) do
						if hasToolAnywhere(name) then
							toolName = name
							break
						end
					end
					addFake(prompt, toolName)
				end
			end
		end
	end
end

local function rescanAll()
	for _, store in ipairs(Stores) do
		store.list = scanGroup(store.group)
	end
	tryAttachAll()
end

local function cleanupEnableReal()
	for fake, real in pairs(Fakes) do
		pcall(function()
			fake:Destroy()
		end)
		if real then
			pcall(function()
				real.Enabled = true
				real.ClickablePrompt = true
				real:SetAttribute("HasFake", nil)
			end)
		end
	end
	Fakes = {}

	-- 兜底：把任何残留的假货也清掉
	local rooms = getRoomFolder()
	if rooms then
		for _, object in ipairs(rooms:GetDescendants()) do
			if object.Name == "FakePrompt" and object.Parent then
				pcall(function()
					object:Destroy()
				end)
			end
		end
	end
end

----------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------

if type(fireproximityprompt) ~= "function" then
	warn("[无限物品] 执行器没有 fireproximityprompt，这个功能用不了")
	return
end

for _, group in ipairs(CONFIG.Groups) do
	Stores[#Stores + 1] = { group = group, list = {} }
end

rescanAll()

local roomFolder = getRoomFolder()
local roomConn = roomFolder and roomFolder.ChildAdded:Connect(function()
	rescanAll()
end) or nil

local lastCheck = 0
local heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
	if not running then
		return
	end
	lastCheck = lastCheck + deltaTime
	if lastCheck < CONFIG.AttachInterval then
		return
	end
	lastCheck = 0
	tryAttachAll()
end)

-- 背包/角色里的工具变了就重扫
local function hookContainer(container)
	if not container then
		return
	end
	container.ChildAdded:Connect(rescanAll)
	container.ChildRemoved:Connect(rescanAll)
end

hookContainer(LocalPlayer:FindFirstChildOfClass("Backpack"))
LocalPlayer.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		hookContainer(child)
	end
end)
LocalPlayer.CharacterAdded:Connect(function(char)
	hookContainer(char)
	task.wait(0.5)
	rescanAll()
end)

if LocalPlayer.Character then
	hookContainer(LocalPlayer.Character)
end

----------------------------------------------------------------------
-- 状态 / 停止
----------------------------------------------------------------------

task.spawn(function()
	task.wait(0.5)
	local owned = {}
	for _, store in ipairs(Stores) do
		for _, toolName in ipairs(store.group.Tools) do
			if hasToolAnywhere(toolName) then
				owned[#owned + 1] = toolName
			end
		end
	end

	log(("诊断  DropItem=%s  workspace.Drops=%s  CurrentRooms=%s")
		:format(
			getDropItem() and "有" or "没有",
			Workspace:FindFirstChild("Drops") and "有" or "还没有",
			getRoomFolder() and "有" or "没有"
		))
	log(("诊断  身上有的工具：%s")
		:format(#owned > 0 and table.concat(owned, ", ") or "（还没有——先去拿一把 Lockpick / Shears / Key / Crowbar）"))
	log(("诊断  已接管 %d 个锁类 prompt"):format(stats.attached))

	if stats.attached == 0 and #owned == 0 then
		warn("[无限物品] 身上还没有可用工具，所以没接管任何 prompt。拿到工具会自动接管。")
	end
	if stats.attached == 0 and #owned > 0 then
		warn("[无限物品] 有工具但没找到对应 prompt —— 走到有锁的地方会自动接管。")
		warn("[无限物品] 如果到了锁旁边还是 0，把这一行的输出发我：")
		warn([[for _,v in ipairs(game.Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then print(v.Name, v.Parent and v.Parent.Name) end end]])
	end

	log("用法：手里或背包有工具时，去按锁 —— 锁开、工具不消耗。")
	log("关掉：getgenv().AbyInfItemsStop()")
end)

getgenv().AbyInfItemsStop = function()
	running = false

	pcall(function()
		if heartbeatConn then
			heartbeatConn:Disconnect()
		end
	end)
	pcall(function()
		if roomConn then
			roomConn:Disconnect()
		end
	end)

	cleanupEnableReal()

	log(("已停止并还原。接管 %d / 触发 %d / 成功 %d / 失败 %d")
		:format(stats.attached, stats.triggered, stats.fired, stats.failed))
end

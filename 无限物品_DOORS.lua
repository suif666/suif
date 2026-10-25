--[[
	无限物品 · DOORS  (v6)
	实现来源：Abysall原版_Main.luau 的 InfiniteItemsToggle
	           · FakePrompt 创建（7487-7545）
	           · PromptTriggered 处理（7954-8006）
	无 UI，执行即用。

	═══════════ v5 为什么一直失效 ═══════════
	v5 参考的是 小西源码/DOORSXIAOXI.lua，它把真 prompt 留在原地并 Enabled=false。
	但实测当前环境下 fireproximityprompt 对已禁用的 prompt 触发极不稳定，
	所以表现为「锁不开」或「工具还是消耗」。

	Abysall 的原版做法不同：
	  · 真 prompt 被挪进隐藏容器（gethui → CoreGui → PlayerGui），Enabled 保持 true
	  · 原位置放一个克隆的假 prompt
	  · 玩家只能按到假 prompt；假 prompt 触发后丢工具 → 捡回 → fire 真 prompt
	真 prompt 因为处于启用状态，fireproximityprompt 对它触发非常稳。

	═══════════ 用法 ═══════════
	手里拿上 Lockpick / SkeletonKey / Shears / Multitool，走到锁前按 E。
	脚本会接管所有锁类 prompt；按下去后工具不会消耗。

	═══════════ 关于互动距离 ═══════════
	已去掉距离加成：假 prompt 的互动距离与原 prompt 完全一致。
	保留了两项可开关的便利：
	  · InstantPrompts = true  （0 秒按住）
	  · RequiresLineOfSight = false （不需要视线）
	如果还想要更原版的交互，把 CONFIG.InstantPrompts 改成 false。

	═══════════ 如果还消耗道具 ═══════════
	默认 FireOrder = "pickup-first"（按 Abysall 原版顺序：先捡回再开锁）。
	如果仍然消耗，改成 FireOrder = "real-first"（先开锁再捡回），
	让服务器在试图消耗时工具还在地上。

	停止：getgenv().AbyInfItemsStop()
]]

if getgenv().AbyInfItemsStop then
	pcall(getgenv().AbyInfItemsStop)
	getgenv().AbyInfItemsStop = nil
end

local CONFIG = {
	-- 哪些工具启用无限（对应 Abysall 下拉框里的显示名）
	Items = {
		Lockpicks = true,
		["Skeleton Key"] = true,
		Shears = true,
		Multitool = true,
	},
	InstantPrompts = true, -- 是否把按住时长改成 0（true = 与 Abysall 默认一致）
	FireOrder = "pickup-first", -- "pickup-first" 按 Abysall 顺序；如果还消耗，改成 "real-first" 试
	Verbose = true,
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local running = true
local FakePrompts = {} -- fake ProximityPrompt -> real ProximityPrompt
local Connections = {}
local FakeCount = 0

local ItemNames = {
	Lockpick = "Lockpicks",
	SkeletonKey = "Skeleton Key",
	Shears = "Shears",
	Multitool = "Multitool",
}

local LockPromptNames = {
	UnlockPrompt = true,
	SkullPrompt = true,
	LockPrompt = true,
	ThingToEnable = true,
	FusesPrompt = true,
}

local function log(...)
	if CONFIG.Verbose then
		print("[无限物品] " .. table.concat({ ... }, " "))
	end
end

----------------------------------------------------------------------
-- 基础
----------------------------------------------------------------------

local function getHiddenContainer()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
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

local PromptContainer = Instance.new("Folder")
PromptContainer.Name = "AbyInfItemsPrompts"
PromptContainer.Parent = getHiddenContainer()

local RemotesFolder = ReplicatedStorage:FindFirstChild("EntityInfo")
	or ReplicatedStorage:FindFirstChild("RemotesFolder")
	or ReplicatedStorage:FindFirstChild("Bricks")
local DropItem = RemotesFolder and RemotesFolder:FindFirstChild("DropItem")

local firePrompt = (typeof(fireproximityprompt) == "function" and fireproximityprompt) or nil
if not firePrompt then
	warn("[无限物品] 当前执行器没有 fireproximityprompt，功能无法启动")
	return
end

local function getDrops()
	return Workspace:FindFirstChild("Drops")
end

local function isLockPrompt(object)
	if LockPromptNames[object.Name] then
		return true
	end
	if object.Parent and object.Parent:GetAttribute("Locked") == true then
		return true
	end
	if object.Parent and object.Parent.Parent and object.Parent.Parent.Name == "Locker_Small_Locked" and object.Name == "ActivateEventPrompt" then
		return true
	end
	return false
end

local function hasHeld(name)
	return Character:FindFirstChild(name) ~= nil
end

-- 检查当前场景是否允许这件工具开这把锁；不满足就正常放行
local function canUseHere(prompt)
	local parentName = prompt.Parent and prompt.Parent.Name or ""
	if (parentName == "CuttableVines" or parentName == "Chest_Vine" or parentName == "Cellar")
		and not hasHeld("Shears") and not hasHeld("Multitool") then
		return false
	end
	if parentName == "SkullLock" and not hasHeld("SkeletonKey") then
		return false
	end
	if (parentName == "Lock1" or parentName == "Lock2")
		and not hasHeld("Lockpick") and not hasHeld("Multitool") then
		return false
	end
	return true
end

----------------------------------------------------------------------
-- 做假 prompt（核心，照抄 Abysall）
----------------------------------------------------------------------

local function makeFake(object)
	if not running or not object or not object.Parent then
		return
	end
	if object:GetAttribute("FakePrompt") or object:GetAttribute("AbyInfFaked") then
		return
	end
	if not isLockPrompt(object) then
		return
	end

	object:SetAttribute("HoldDuration_Old", object.HoldDuration)
	object:SetAttribute("RequiresLineOfSight_Old", object.RequiresLineOfSight)
	object:SetAttribute("MaxActivationDistance_Old", object.MaxActivationDistance)

	-- 只改按住时长；互动距离保持原样（用户要求不加距离）
	if CONFIG.InstantPrompts then
		object.HoldDuration = 0
	end
	object.RequiresLineOfSight = false

	local ok, fake = pcall(function()
		return object:Clone()
	end)
	if not ok or not fake then
		return
	end

	object:SetAttribute("AbyInfFaked", true)
	fake:SetAttribute("FakePrompt", true)

	-- 同步旧属性到假货，方便停止时还原
	fake:SetAttribute("HoldDuration_Old", object:GetAttribute("HoldDuration_Old"))
	fake:SetAttribute("RequiresLineOfSight_Old", object:GetAttribute("RequiresLineOfSight_Old"))
	fake:SetAttribute("MaxActivationDistance_Old", object:GetAttribute("MaxActivationDistance_Old"))

	fake.HoldDuration = object.HoldDuration
	fake.RequiresLineOfSight = object.RequiresLineOfSight
	fake.MaxActivationDistance = object.MaxActivationDistance

	task.wait()
	fake.Parent = object.Parent

	FakePrompts[fake] = object
	FakeCount = FakeCount + 1

	-- 真身藏进隐藏容器，保持 Enabled = true
	pcall(function()
		object.Parent = PromptContainer
	end)

	local fpEnabledConn = object:GetPropertyChangedSignal("Enabled"):Connect(function()
		if fake and fake.Parent then
			fake.Enabled = object.Enabled
		end
	end)
	table.insert(Connections, fpEnabledConn)

	object:GetPropertyChangedSignal("ActionText"):Once(function()
		pcall(function()
			object.Parent = fake.Parent
		end)
		pcall(function()
			fake:Destroy()
		end)
		pcall(function()
			fpEnabledConn:Disconnect()
		end)
		if FakePrompts[fake] then
			FakeCount = FakeCount - 1
			FakePrompts[fake] = nil
		end
	end)

	object.Destroying:Once(function()
		pcall(function()
			fake:Destroy()
		end)
		pcall(function()
			fpEnabledConn:Disconnect()
		end)
		if FakePrompts[fake] then
			FakeCount = FakeCount - 1
			FakePrompts[fake] = nil
		end
	end)

	fake.Enabled = false
	task.wait()
	fake.Enabled = object.Enabled

	log("已接管", object.Name, "(" .. (object.Parent and object.Parent.Name or "?") .. ")")
end

local function onDescendantAdded(object)
	if not running then
		return
	end
	if object:IsA("ProximityPrompt") and not object:GetAttribute("FakePrompt") then
		task.defer(function()
			makeFake(object)
		end)
	end
end

local function scanAll()
	local rooms = Workspace:FindFirstChild("CurrentRooms")
	if not rooms then
		return
	end
	for _, object in ipairs(rooms:GetDescendants()) do
		onDescendantAdded(object)
	end
end

----------------------------------------------------------------------
-- 触发处理（Abysall 原版逻辑）
----------------------------------------------------------------------

local function onPromptTriggered(object, player)
	if not running then
		return
	end
	if player ~= LocalPlayer then
		return
	end
	if not object:GetAttribute("FakePrompt") then
		return
	end

	local realPrompt = FakePrompts[object]
	if not realPrompt then
		return
	end

	if not canUseHere(object) then
		firePrompt(realPrompt)
		return
	end

	local anyTool = Character:FindFirstChildOfClass("Tool")
	local toolData = anyTool and ItemNames[anyTool.Name]

	if anyTool and toolData and CONFIG.Items[toolData] then
		local drops = getDrops()
		if not drops or not DropItem then
			warn("[无限物品] 缺少 Drops 或 DropItem，走正常消耗")
			firePrompt(realPrompt)
			return
		end

		drops.ChildAdded:Once(function(newTool)
			log("掉落物出现:", newTool.Name)
			local prompt = newTool:FindFirstChild("ModulePrompt")
			if CONFIG.FireOrder == "real-first" then
				firePrompt(realPrompt)
				log("已触发真 prompt 开锁（real-first）")
				if prompt then
					firePrompt(prompt)
					log("已触发 ModulePrompt 捡回", newTool.Name)
				else
					warn("[无限物品] 掉落物", newTool.Name, "上找不到 ModulePrompt")
				end
			else
				if prompt then
					firePrompt(prompt)
					log("已触发 ModulePrompt 捡回", newTool.Name)
				else
					warn("[无限物品] 掉落物", newTool.Name, "上找不到 ModulePrompt")
				end
				firePrompt(realPrompt)
				log("已触发真 prompt 开锁（pickup-first）")
			end
		end)

		Character.ChildAdded:Once(function(newTool)
			if newTool.Name == "Shears" then
				local handle = newTool:FindFirstChild("Handle")
				local sound = handle and handle:FindFirstChild("sound_promptend")
				if sound then
					pcall(function()
						sound:Play()
					end)
				end
			end
		end)

		DropItem:FireServer(anyTool)
		log("触发", object.Name, "→ 已丢出", anyTool.Name, "并重新捡回（无限）")
	else
		-- 手里没拿目标工具，或拿的不是无限列表里的工具：正常放行
		firePrompt(realPrompt)
	end
end

----------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------

table.insert(Connections, ProximityPromptService.PromptTriggered:Connect(onPromptTriggered))
table.insert(Connections, Workspace.DescendantAdded:Connect(onDescendantAdded))
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	scanAll()
end))

scanAll()

----------------------------------------------------------------------
-- 状态 / 停止
----------------------------------------------------------------------

getgenv().AbyInfItemsStop = function()
	running = false

	for _, c in ipairs(Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	Connections = {}

	for fake, real in pairs(FakePrompts) do
		if real then
			pcall(function()
				if fake and fake.Parent then
					real.Parent = fake.Parent
				end
				real.HoldDuration = real:GetAttribute("HoldDuration_Old") or real.HoldDuration
				real.RequiresLineOfSight = real:GetAttribute("RequiresLineOfSight_Old")
				real.MaxActivationDistance = real:GetAttribute("MaxActivationDistance_Old") or real.MaxActivationDistance
				real:SetAttribute("AbyInfFaked", nil)
				real:SetAttribute("HoldDuration_Old", nil)
				real:SetAttribute("RequiresLineOfSight_Old", nil)
				real:SetAttribute("MaxActivationDistance_Old", nil)
			end)
		end
		pcall(function()
			fake:Destroy()
		end)
	end
	FakePrompts = {}
	FakeCount = 0

	pcall(function()
		PromptContainer:Destroy()
	end)

	log("已停止并还原所有 prompt")
end

task.spawn(function()
	task.wait(0.5)
	log("诊断  fireproximityprompt:", firePrompt and "有" or "无")
	log("诊断  DropItem:", DropItem and "有" or "没有")
	log("诊断  workspace.Drops:", getDrops() and "有" or "还没有")
	log("诊断  已接管锁类 prompt:", FakeCount)
	log("诊断  InstantPrompts:", CONFIG.InstantPrompts, "FireOrder:", CONFIG.FireOrder)
	log("用法：手里拿 Lockpick / SkeletonKey / Shears / Multitool，走到锁前按 E。")
	log("注意：工具必须拿在手里；在背包里不会被无限。")
	log("如果还消耗，改 CONFIG.FireOrder = \"real-first\" 再试一次。")
	log("停止：getgenv().AbyInfItemsStop()")
end)

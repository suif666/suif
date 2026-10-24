--[[
	无限物品 · DOORS
	从 Abysall Hub 的 "Infinite Items" 单独提取：无 UI，执行即用。

	原理（与 Abysall 一致）：
	  1. 锁类 Prompt 出现时，克隆一个「假 Prompt」放到世界里，把真 Prompt 挪进隐藏容器。
	  2. 你点的是假 Prompt；触发时脚本读取你手上正拿着的工具。
	  3. 用 ReplicatedStorage.RemotesFolder.DropItem 把手上的工具丢一份出去（进 workspace.Drops）。
	  4. 对丢出去的那一份补发它自己的 ModulePrompt + 真 Prompt →
	     游戏消费的是「丢出去的副本」，背包里那把不动，于是可以一直用。
	  5. 不满足条件（没对应道具 / 拿的是剪刀点非藤蔓门）就照常放行真 Prompt，不会出现死按钮。

	支持：Lockpicks / Skeleton Key / Shears / Multitool
--]]

-- 重复执行时先卸掉上一份
if getgenv().AbysallInfiniteItemsUnload then
	pcall(getgenv().AbysallInfiniteItemsUnload)
	getgenv().AbysallInfiniteItemsUnload = nil
end

local CONFIG = {
	-- 想无限哪个就把哪个改成 true / false
	Items = {
		Lockpicks = true,
		["Skeleton Key"] = true,
		Shears = true,
		Multitool = true,
	},
	InstantPrompts = false, -- true = 假 Prompt 改成 0 秒长按
	ReachMultiplier = 1, -- >1 = 加交互距离倍数，1 = 与原版一致
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- 基础工具
----------------------------------------------------------------------

local function getChar()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

-- 物品实例名 → 界面上的显示名（只保留本脚本关心的四个）
local ITEM_NAMES = {
	Lockpick = "Lockpicks",
	SkeletonKey = "Skeleton Key",
	Shears = "Shears",
	Multitool = "Multitool",
}

local KEY_ITEMS = {
	"Key", "GeneratorFuse", "KeyBackdoor", "KeyElectrical",
	"KeyIron", "Lockpick", "SkeletonKey", "Shears", "Multitool",
}

local OFFHAND_KEY_ITEMS = { "Key", "GeneratorFuse", "KeyElectrical", "KeyIron" }

-- 背包 + 角色身上找道具（OnlyCharacter = 只看角色，不看背包）
local function hasItem(name, onlyCharacter)
	local char = LocalPlayer.Character
	if char then
		local onChar = char:FindFirstChild(name)
		if onChar then
			return onChar
		end
	end
	if not onlyCharacter then
		local bag = LocalPlayer:FindFirstChildOfClass("Backpack")
		if bag then
			return bag:FindFirstChild(name)
		end
	end
	return nil
end

local LOCK_PROMPT_NAMES = {
	UnlockPrompt = true,
	SkullPrompt = true,
	LockPrompt = true,
	ThingToEnable = true,
	FusesPrompt = true,
}

local function isLockPrompt(prompt)
	if LOCK_PROMPT_NAMES[prompt.Name] then
		return true
	end
	local parent = prompt.Parent
	if parent and parent:GetAttribute("Locked") == true then
		return true
	end
	if parent and parent.Parent and parent.Parent.Name == "Locker_Small_Locked" and prompt.Name == "ActivateEventPrompt" then
		return true
	end
	return false
end

----------------------------------------------------------------------
-- 隐藏容器（放真 Prompt）
----------------------------------------------------------------------

local function getHiddenContainer()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
		end
	end
	return game:GetService("CoreGui")
end

local PromptContainer = Instance.new("Folder")
PromptContainer.Name = "AbysallInfItems_Prompts"

-- 真 Prompt 必须能被 fireproximityprompt 触发，所以容器一定要挂上；
-- gethui() → CoreGui → PlayerGui 逐级兜底（挂 PlayerGui 不会渲染出提示）。
for _, fallback in ipairs({
	function()
		return getHiddenContainer()
	end,
	function()
		return LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end,
}) do
	if PromptContainer.Parent then
		break
	end
	local ok, target = pcall(fallback)
	if ok and target then
		pcall(function()
			PromptContainer.Parent = target
		end)
	end
end

if not PromptContainer.Parent then
	warn("[无限物品] 找不到可用的隐藏容器，脚本不启动（避免让你丢道具）")
	return
end

----------------------------------------------------------------------
-- 触发 Prompt（优先用执行器的 fireproximityprompt）
----------------------------------------------------------------------

local executorFire
pcall(function()
	if typeof(fireproximityprompt) == "function" then
		executorFire = fireproximityprompt
	end
end)
if not executorFire then
	pcall(function()
		if typeof(getgenv().fireproximityprompt) == "function" then
			executorFire = getgenv().fireproximityprompt
		end
	end)
end

local firePrompt

if executorFire then
	firePrompt = function(prompt)
		if not prompt or not prompt.Parent then
			return
		end
		pcall(executorFire, prompt)
	end
else
	-- 兜底：把 Prompt 临时挪到镜头前的小零件上，模拟长按
	local pending, cooldown = {}, {}

	firePrompt = function(prompt)
		if not prompt or cooldown[prompt] or table.find(pending, prompt) then
			return
		end
		table.insert(pending, prompt)
	end

	task.spawn(function()
		while true do
			task.wait()
			local prompt = table.remove(pending, 1)
			if prompt then
				cooldown[prompt] = true
				task.spawn(function()
					local oldDist, oldEnabled = prompt.MaxActivationDistance, prompt.Enabled
					local oldParent, oldHold, oldLOS = prompt.Parent, prompt.HoldDuration, prompt.RequiresLineOfSight

					local carrier = Instance.new("Part")
					carrier.Size = Vector3.new(0.001, 0.001, 0.001)
					carrier.Transparency = 1
					carrier.CanCollide = false
					carrier.CanQuery = false
					carrier.CanTouch = false
					carrier.Anchored = true
					carrier.Parent = Workspace
					pcall(function()
						carrier.Position = Workspace.CurrentCamera.CFrame.Position
					end)

					prompt.MaxActivationDistance = 99999
					prompt.Enabled = true
					prompt.HoldDuration = 0
					prompt.RequiresLineOfSight = false
					pcall(function()
						prompt.Parent = carrier
					end)

					local fired = false
					local conn = prompt.Triggered:Connect(function()
						fired = true
					end)
					for _ = 1, 10 do
						if fired then
							break
						end
						pcall(function()
							prompt:InputHoldBegin()
							prompt:InputHoldEnd()
						end)
						task.wait()
					end
					conn:Disconnect()

					pcall(function()
						prompt.MaxActivationDistance = oldDist
						prompt.Enabled = oldEnabled
						prompt.HoldDuration = oldHold
						prompt.RequiresLineOfSight = oldLOS
						prompt.Parent = oldParent
					end)
					carrier:Destroy()
					cooldown[prompt] = nil
				end)
			end
		end
	end)
end

----------------------------------------------------------------------
-- 假 Prompt
----------------------------------------------------------------------

local FakePrompts = {}

local function installFake(real)
	if not real or not real.Parent then
		return
	end
	if real.ClassName ~= "ProximityPrompt" then
		return
	end
	if real:GetAttribute("FakePrompt") or real:GetAttribute("InfItemsDone") then
		return
	end
	if real:IsDescendantOf(PromptContainer) then
		return
	end
	if not isLockPrompt(real) then
		return
	end

	real:SetAttribute("InfItemsDone", true)
	real:SetAttribute("HoldDuration_Old", real.HoldDuration)
	real:SetAttribute("RequiresLineOfSight_Old", real.RequiresLineOfSight)
	real:SetAttribute("MaxActivationDistance_Old", real.MaxActivationDistance)

	if CONFIG.InstantPrompts then
		real.HoldDuration = 0
	end

	local originalParent = real.Parent

	local fake = real:Clone()
	fake:SetAttribute("FakePrompt", true)
	fake:SetAttribute("InfItemsFake", true)
	task.wait()
	fake.Parent = originalParent

	fake.HoldDuration = real.HoldDuration
	fake.RequiresLineOfSight = real.RequiresLineOfSight
	fake.MaxActivationDistance = real.MaxActivationDistance
	if CONFIG.ReachMultiplier ~= 1 then
		fake.MaxActivationDistance = real:GetAttribute("MaxActivationDistance_Old") * CONFIG.ReachMultiplier
	end

	FakePrompts[fake] = real
	pcall(function()
		real.Parent = PromptContainer
	end)

	local enabledConn = real:GetPropertyChangedSignal("Enabled"):Connect(function()
		if fake and fake.Parent then
			fake.Enabled = real.Enabled
		end
	end)

	local restored = false
	local function restore()
		if restored then
			return
		end
		restored = true
		if enabledConn then
			enabledConn:Disconnect()
			enabledConn = nil
		end
		if real and real.Parent == PromptContainer and originalParent then
			pcall(function()
				real.Parent = originalParent
			end)
		end
		FakePrompts[fake] = nil
		if fake and fake.Parent then
			fake:Destroy()
		end
	end

	real:GetPropertyChangedSignal("ActionText"):Once(restore)
	real.Destroying:Once(restore)
end

----------------------------------------------------------------------
-- 主逻辑
----------------------------------------------------------------------

local function getDropRemote()
	local rf = ReplicatedStorage:FindFirstChild("RemotesFolder")
	if not rf then
		return nil
	end
	local remote = rf:FindFirstChild("DropItem")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

-- 丢出去的那份进 Drops 后，补发它自己的 ModulePrompt + 真 Prompt
-- 返回 false = 没挂上钩子，此时绝对不能丢道具，否则道具就白丢了
local function armDropsHandler(realPrompt)
	local drops = Workspace:FindFirstChild("Drops")
	if not drops then
		return false
	end
	local conn
	conn = drops.ChildAdded:Connect(function(newTool)
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local modulePrompt = newTool:FindFirstChild("ModulePrompt")
		if not modulePrompt then
			modulePrompt = newTool:FindFirstChild("ModulePrompt", true)
		end
		if modulePrompt then
			firePrompt(modulePrompt)
		end
		if realPrompt and realPrompt.Parent then
			firePrompt(realPrompt)
		end
	end)
	task.delay(3, function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end)
	return true
end

local triggerConn = ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if not prompt:GetAttribute("FakePrompt") then
		return
	end
	local real = FakePrompts[prompt]
	if not real or not real.Parent then
		return
	end

	local function passthrough()
		firePrompt(real)
	end

	-- 假 Prompt 只在锁类上才会被创建，所以走到这里一定是锁

	-- 手上/背包里连钥匙类道具都没有 → 按普通交互放行
	local hasKey = false
	for _, name in ipairs(KEY_ITEMS) do
		if hasItem(name, true) then
			hasKey = true
			break
		end
	end
	if not hasKey then
		for _, name in ipairs(OFFHAND_KEY_ITEMS) do
			if hasItem(name) then
				hasKey = true
				break
			end
		end
	end
	if not hasKey then
		return passthrough()
	end

	local parentName = prompt.Parent and prompt.Parent.Name or ""
	local isVineLike = parentName == "CuttableVines" or parentName == "Chest_Vine" or parentName == "Cellar"
	local hasShears = hasItem("Shears", true) ~= nil
	local hasMultitool = hasItem("Multitool", true) ~= nil

	if isVineLike and not hasShears and not hasMultitool then
		return passthrough()
	end
	if parentName == "SkullLock" and not hasItem("SkeletonKey", true) then
		return passthrough()
	end
	if (parentName == "Lock1" or parentName == "Lock2") and not hasItem("Lockpick", true) and not hasMultitool then
		return passthrough()
	end
	-- 拿着剪刀时不要拿去开普通锁（剪刀是给藤蔓的）
	if hasShears and not isVineLike then
		return passthrough()
	end

	local char = getChar()
	local heldTool = char and char:FindFirstChildOfClass("Tool")
	local displayName = heldTool and ITEM_NAMES[heldTool.Name]
	if not heldTool or not displayName or not CONFIG.Items[displayName] then
		return passthrough()
	end

	local dropRemote = getDropRemote()
	if not dropRemote then
		return passthrough()
	end

	if not armDropsHandler(real) then
		return passthrough()
	end

	-- 剪刀用完的音效（纯装饰，失败无所谓）
	char.ChildAdded:Once(function(newTool)
		if newTool.Name == "Shears" then
			local handle = newTool:FindFirstChild("Handle")
			local sound = handle and handle:FindFirstChild("sound_promptend")
			if sound and sound.Play then
				pcall(function()
					sound:Play()
				end)
			end
		end
	end)

	local ok = pcall(function()
		dropRemote:FireServer(heldTool)
	end)
	if not ok then
		pcall(function()
			firePrompt(real)
		end)
	end
end)

----------------------------------------------------------------------
-- 监听 Prompt
----------------------------------------------------------------------

local function onInstance(instance)
	if instance and instance.ClassName == "ProximityPrompt" then
		task.spawn(installFake, instance)
	end
end

for _, object in ipairs(Workspace:GetDescendants()) do
	onInstance(object)
end

local descendantConn = Workspace.DescendantAdded:Connect(onInstance)

----------------------------------------------------------------------
-- 卸载句柄（重跑脚本时自动清掉上一份）
----------------------------------------------------------------------

getgenv().AbysallInfiniteItemsUnload = function()
	if triggerConn then
		triggerConn:Disconnect()
		triggerConn = nil
	end
	if descendantConn then
		descendantConn:Disconnect()
		descendantConn = nil
	end

	for fake, real in pairs(FakePrompts) do
		if real and real.Parent == PromptContainer then
			pcall(function()
				real.Parent = fake.Parent
			end)
		end
		if fake and fake.Parent then
			pcall(function()
				fake:Destroy()
			end)
		end
	end
	FakePrompts = {}

	if PromptContainer then
		pcall(function()
			PromptContainer:Destroy()
		end)
	end
end

print("[无限物品] 已加载 —— 拿着 Lockpick / Skeleton Key / Shears / Multitool 去点锁即可，不消耗次数。")

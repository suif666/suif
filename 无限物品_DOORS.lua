--[[
	无限物品 · DOORS
	从 Abysall Hub 提取：InfiniteItemsToggle（Exploits / Bypass 页，第 8 个）
	无 UI，执行即用。

	════════════════ 原理 ════════════════
	不是"复制物品"，是"用了不消耗"。

	你触发开锁/使用类 prompt 的那一刻：
	  ① 先挂一个 Drops.ChildAdded 监听
	  ② 把手里那把工具丢出去（DropItem）
	  ③ 掉出来的那份出现的瞬间，立刻点它的 ModulePrompt —— 捡回背包
	→ 锁开了，工具一件没少。

	白名单默认只有原版下拉框里那 4 个：
	    Lockpick / SkeletonKey / Shears / Multitool
	要加别的自己往 CONFIG.Items 里添。

	════════════════ 必须满足 ════════════════
	· 工具要拿在手上（Character:FindFirstChildOfClass("Tool")）
	· 执行器要有 fireproximityprompt（Delta 有）

	停止：getgenv().AbyInfItemsStop()
]]

if getgenv().AbyInfItemsStop then
	pcall(getgenv().AbyInfItemsStop)
	getgenv().AbyInfItemsStop = nil
end

local CONFIG = {
	-- 会走"丢→捡"流程的工具（按 Character 里 Tool 的 Name 判断）
	Items = {
		Lockpick = true,
		SkeletonKey = true,
		Shears = true,
		Multitool = true,
		-- 想扩展就打开下面这些：
		-- Key = true,
		-- KeyElectrical = true,
		-- KeyBackdoor = true,
		-- KeyIron = true,
		-- GeneratorFuse = true,
	},

	-- 判定为「消耗型」的 prompt 名字。不在名单里的 prompt 不会触发丢工具。
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

	PickupTries = 15, -- 找 ModulePrompt 的重试次数
	PickupDelay = 0.05, -- 每次重试间隔（秒）
	WatchTimeout = 1.5, -- 挂上去等掉落物最多等多久（秒），超时自动解除监听
	Verbose = true, -- 打印每次成功/失败
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local running = true

getgenv().AbyInfItemsStop = function()
	running = false
	if getgenv().AbyInfItemsConn then
		pcall(function()
			getgenv().AbyInfItemsConn:Disconnect()
		end)
		getgenv().AbyInfItemsConn = nil
	end
	print("[无限物品] 已停止")
end

----------------------------------------------------------------------
-- 小工具
----------------------------------------------------------------------

local function log(...)
	if CONFIG.Verbose then
		print("[无限物品] " .. table.concat({ ... }, " "))
	end
end

-- 手里拿着的、且在白名单里的工具
local function getWhitelistedEquippedTool()
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

-- 这个 prompt 会不会消耗物品
local function isConsumingPrompt(prompt)
	if CONFIG.ConsumingPrompts[prompt.Name] then
		return true
	end

	local parent = prompt.Parent
	if parent then
		-- 原版的两个兜底判定
		if parent:GetAttribute("Locked") == true then
			return true
		end
		if parent.Parent and parent.Parent.Name == "Locker_Small_Locked" then
			return true
		end
	end

	return false
end

local function getDropsFolder()
	return Workspace:FindFirstChild("Drops")
end

local function getDropItemRemote()
	local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
	return remotes and remotes:FindFirstChild("DropItem")
end

-- 找到掉落物上的 ModulePrompt 并点它，把工具捡回背包
local function pickUpDropped(model)
	task.spawn(function()
		local prompt
		for attempt = 1, CONFIG.PickupTries do
			if not model or not model.Parent then
				break
			end
			prompt = model:FindFirstChild("ModulePrompt", true)
			if prompt then
				break
			end
			task.wait(CONFIG.PickupDelay)
		end

		if not prompt then
			warn(("[无限物品] 掉落物上找不到 ModulePrompt（%s，第 %d 次重试后）—— 这次的东西要自己捡")
				:format(tostring(model and model.Name), CONFIG.PickupTries))
			return
		end

		local ok, err = pcall(function()
			fireproximityprompt(prompt)
		end)
		if ok then
			log(("已把 %s 捡回背包"):format(tostring(model.Name)))
		else
			warn("[无限物品] 捡回失败：" .. tostring(err))
		end
	end)
end

----------------------------------------------------------------------
-- 主逻辑
----------------------------------------------------------------------

local function onPromptTriggered(prompt, player)
	if not running then
		return
	end
	if player ~= LocalPlayer then
		return
	end

	local tool = getWhitelistedEquippedTool()
	if not tool then
		return
	end

	if not isConsumingPrompt(prompt) then
		return
	end

	local drops = getDropsFolder()
	if not drops then
		warn("[无限物品] 现在还没有 workspace.Drops（要有人丢过东西才会创建），这次跳过")
		return
	end

	local remote = getDropItemRemote()
	if not remote then
		warn("[无限物品] 找不到 ReplicatedStorage.RemotesFolder.DropItem，这次跳过")
		return
	end

	-- ① 先挂监听（顺序不能反，否则掉落物可能已经出现过了）
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
			pickUpDropped(newChild)
		end
	end)

	-- 等不到掉落物就自动放手，避免监听泄漏
	task.delay(CONFIG.WatchTimeout, function()
		if not settled then
			finish()
			warn("[无限物品] 丢出去之后 " .. CONFIG.WatchTimeout .. " 秒没等到掉落物，已解除监听")
		end
	end)

	-- ② 把工具丢出去
	local ok, err = pcall(function()
		remote:FireServer(tool)
	end)
	if not ok then
		finish()
		warn("[无限物品] DropItem 调用失败：" .. tostring(err))
		return
	end

	log(("触发 %s → 已丢出 %s，等它出现后捡回"):format(prompt.Name, tool.Name))
end

getgenv().AbyInfItemsConn = ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

log("已启用。白名单：" .. (function()
	local names = {}
	for name in pairs(CONFIG.Items) do
		names[#names + 1] = name
	end
	table.sort(names)
	return table.concat(names, ", ")
end)())
log("提示：工具要拿在手上才会触发。用 getgenv().AbyInfItemsStop() 关闭。")

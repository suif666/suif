--[[
	传送废品 · DOORS
	从 Abysall Hub 提取：StairwellLandingSpam（UI: "TP to trash and drop trash."）
	                     TPDropsToNearestGrinder（UI: "TP All Drops to Nearest Grinder"）
	无 UI，执行即用。

	两种模式（改下面 CONFIG.Mode）：
	  "trash"   传送到最近的楼梯间垃圾桶，把身上/背包里的东西全丢进去，反复刷
	  "grinder" 一次性：把 workspace.Drops 里所有掉落物挪到离你最近的研磨机

	相对原版修的两处：
	  ① 原版用 keypress(0x58) 按 X 丢东西 —— 依赖执行器有 keypress。
	     这里改成直接对 ReplicatedStorage.RemotesFolder.DropItem 发请求，
	     背包和手上的一起丢，不依赖按键；没有 DropItem 才退回按 X。
	  ② 原版找垃圾桶只认 StairwellLandingLogic，找不到就静默什么都不做。
	     这里再兜底一层 TrashcanPrompt，并且找不到会明确告诉你。

	停止：getgenv().AbyTrashStop()
--]]

-- 重复执行时先卸掉上一份
if getgenv().AbyTrashStop then
	pcall(getgenv().AbyTrashStop)
	getgenv().AbyTrashStop = nil
end

local CONFIG = {
	Mode = "trash", -- "trash" 或 "grinder"
	Interval = 0.15, -- trash 模式下每次重试的间隔（秒）
	MaxRounds = 120, -- trash 模式最多刷多少轮就自动停，0 = 不停
	DropKey = 0x58, -- 没有 DropItem remote 时的备用丢键（DOORS 是 X）
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- 基础
----------------------------------------------------------------------

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getRooms()
	return Workspace:FindFirstChild("CurrentRooms")
end

-- 丢光身上和背包里所有工具。返回丢出去的件数。
local function dropEverything()
	local remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
	local dropItem = remotes and remotes:FindFirstChild("DropItem")

	if dropItem and dropItem:IsA("RemoteEvent") then
		local count = 0
		local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }
		for _, container in ipairs(containers) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") then
						pcall(function()
							dropItem:FireServer(child)
						end)
						count = count + 1
					end
				end
			end
		end
		if count > 0 then
			return count
		end
	end

	-- 兜底：按 X
	local kp = (typeof(keypress) == "function") and keypress or nil
	local kr = (typeof(keyrelease) == "function") and keyrelease or nil
	if kp and kr then
		pcall(kp, CONFIG.DropKey)
		task.wait(0.03)
		pcall(kr, CONFIG.DropKey)
		return 1
	end

	return 0
end

----------------------------------------------------------------------
-- 找垃圾桶
----------------------------------------------------------------------

-- 优先 StairwellLandingLogic 下的带 Prompt 的模型；没有就兜底找 TrashcanPrompt
local function findTrashCans()
	local rooms = getRooms()
	local found = {}

	if rooms then
		for _, room in ipairs(rooms:GetChildren()) do
			local logic = room:FindFirstChild("StairwellLandingLogic")
			if logic then
				for _, model in ipairs(logic:GetChildren()) do
					if model:IsA("Model") then
						local prompts = {}
						for _, descendant in ipairs(model:GetDescendants()) do
							if descendant:IsA("ProximityPrompt") then
								prompts[#prompts + 1] = descendant
							end
						end
						if #prompts > 0 then
							found[#found + 1] = { Model = model, Prompts = prompts }
						end
					end
				end
			end
		end
	end

	if #found > 0 then
		return found, "StairwellLandingLogic"
	end

	-- 兜底：任何叫 TrashcanPrompt 的提示，把它所在的模型/零件当目标
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "TrashcanPrompt" then
			local host = descendant.Parent
			if host then
				found[#found + 1] = { Model = host, Prompts = { descendant } }
			end
		end
	end

	return found, "TrashcanPrompt"
end

local function pickNearest(list)
	local root = getRoot()
	local here = root and root.Position
	local best, bestDist = nil, math.huge

	for _, entry in ipairs(list) do
		local pivot
		pcall(function()
			pivot = entry.Model:GetPivot().Position
		end)
		if pivot then
			local dist = here and (here - pivot).Magnitude or math.huge
			if dist < bestDist then
				bestDist = dist
				best = entry
			end
		end
	end

	return best or list[1], bestDist
end

----------------------------------------------------------------------
-- grinder 模式（一次性）
----------------------------------------------------------------------

local function tpDropsToNearestGrinder()
	local drops = Workspace:FindFirstChild("Drops")
	local root = getRoot()
	local rooms = getRooms()

	if not drops then
		warn("[传送废品] workspace 里没有 Drops 文件夹")
		return false
	end
	if not root then
		warn("[传送废品] 找不到 HumanoidRootPart")
		return false
	end
	if not rooms then
		warn("[传送废品] 找不到 CurrentRooms")
		return false
	end

	local here = root.Position
	local nearest, nearestDist = nil, math.huge

	for _, room in ipairs(rooms:GetChildren()) do
		local scrapper = room:FindFirstChild("StairwellScrapper", true)
		if scrapper then
			for _, object in ipairs(scrapper:GetDescendants()) do
				if object.Name == "Grinder1" and (object:IsA("Model") or object:IsA("BasePart")) then
					local pivot
					pcall(function()
						pivot = object:GetPivot().Position
					end)
					if pivot then
						local dist = (here - pivot).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							nearest = object
						end
					end
				end
			end
		end
	end

	if not nearest then
		warn("[传送废品] 这一层没找到 Grinder1（研磨机只出现在有 StairwellScrapper 的楼层）")
		return false
	end

	local target
	pcall(function()
		target = nearest:GetPivot()
	end)
	if not target then
		return false
	end

	local moved = 0
	for _, item in ipairs(drops:GetChildren()) do
		if item:IsA("Model") or item:IsA("BasePart") then
			pcall(function()
				item:PivotTo(target)
			end)
			moved = moved + 1
		end
	end

	print(("[传送废品] 已把 %d 件掉落物送到最近研磨机（距离 %d studs）")
		:format(moved, math.floor(nearestDist)))
	return true
end

----------------------------------------------------------------------
-- trash 模式（循环）
----------------------------------------------------------------------

local running = true

getgenv().AbyTrashStop = function()
	running = false
	print("[传送废品] 已停止")
end

local function runTrashSpam()
	local list, source = findTrashCans()

	if #list == 0 then
		warn("[传送废品] 这一层没找到垃圾桶（StairwellLandingLogic 和 TrashcanPrompt 都没有）")
		warn("[传送废品] 楼梯间的垃圾桶只在有楼梯间的楼层出现，换层再试")
		return
	end

	local entry, dist = pickNearest(list)
	print(("[传送废品] 锁定垃圾桶（来源 %s，共 %d 个，最近约 %d studs）")
		:format(source, #list, math.floor(dist or 0)))

	local rounds = 0
	while running do
		local root = getRoot()
		if not root or not entry.Model.Parent then
			-- 角色重生或垃圾桶没了：重新找一次
			task.wait(0.5)
			list, source = findTrashCans()
			if #list == 0 then
				warn("[传送废品] 目标消失了，停止")
				break
			end
			entry = pickNearest(list)
			root = getRoot()
		end

		if root then
			-- 传送到垃圾桶上方，并把所有 Prompt 触发一遍
			pcall(function()
				root.CFrame = entry.Model:GetPivot() + Vector3.new(0, 5, 0)
			end)
			for _, prompt in ipairs(entry.Prompts) do
				if prompt.Parent and prompt.Enabled then
					pcall(function()
						fireproximityprompt(prompt)
					end)
				end
			end

			local dropped = dropEverything()
			rounds = rounds + 1

			if CONFIG.MaxRounds > 0 and rounds >= CONFIG.MaxRounds then
				print(("[传送废品] 已刷满 %d 轮，自动停止（身上已空就改 MaxRounds = 0 关掉上限）")
					:format(rounds))
				break
			end

			-- 什么都没有可丢的时候就别空转了
			if dropped == 0 and rounds > 3 then
				print("[传送废品] 已经没有可丢的东西了，停止")
				break
			end
		end

		task.wait(CONFIG.Interval)
	end

	running = false
end

----------------------------------------------------------------------
-- 入口
----------------------------------------------------------------------

task.spawn(function()
	if CONFIG.Mode == "grinder" then
		tpDropsToNearestGrinder()
	else
		runTrashSpam()
	end
end)

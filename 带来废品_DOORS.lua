--[[
	带来废品 · DOORS
	从 Abysall Hub 提取：BringDroppedItems（UI: "Bring Dropped Items"）
	无 UI，执行即用。

	原理：把 workspace.Drops 里每一件掉落物搬到你的 HumanoidRootPart 位置。
	      Model 用 PivotTo，BasePart 直接改 CFrame —— 跟原版一致。

	相对原版的改动：
	  ① 原版只找一次 workspace.Drops，找不到就静静什么都不做。
	     这里改成一直等它出现，并且明确告诉你现在是「还没出现」还是「是空的」。
	  ② 原版没告诉你搬了几件，所以你不知道到底有没有生效。
	     这里件数变了才打印一次，不刷屏。
	  ③ 加停止接口，不用重载脚本。

	停止：getgenv().AbyBringStop()
]]

-- 重复执行时先卸掉上一份
if getgenv().AbyBringStop then
	pcall(getgenv().AbyBringStop)
	getgenv().AbyBringStop = nil
end

local CONFIG = {
	Interval = 1, -- 秒。0 = 只搬一次就退出
	HeightOffset = 0, -- 搬到离你脚下多高。0 = 跟原版一样，正好在你身上
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local running = true

getgenv().AbyBringStop = function()
	running = false
	print("[带来废品] 已停止")
end

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- 搬一次。返回：成功时 件数, nil；失败时 nil, 原因字符串
local function bringOnce()
	local root = getRoot()
	if not root then
		return nil, "no-character"
	end

	local drops = Workspace:FindFirstChild("Drops")
	if not drops then
		return nil, "no-folder"
	end

	local target = CFrame.new(root.Position + Vector3.new(0, CONFIG.HeightOffset, 0))
	local moved = 0

	for _, item in ipairs(drops:GetChildren()) do
		local ok = pcall(function()
			if item:IsA("Model") then
				item:PivotTo(target)
			elseif item:IsA("BasePart") then
				item.CFrame = target
			end
		end)
		if ok then
			moved = moved + 1
		end
	end

	return moved
end

task.spawn(function()
	local lastMoved = -1
	local alreadyWarnedNoFolder = false

	while running do
		local moved, reason = bringOnce()

		if reason == "no-folder" then
			-- DOORS 里只有「有人丢过东西」之后才会有 Drops 这个文件夹
			if not alreadyWarnedNoFolder then
				warn("[带来废品] 现在还没有 workspace.Drops —— DOORS 要有人丢过东西之后才会创建它，等它出现就行")
				alreadyWarnedNoFolder = true
			end
			lastMoved = -1

		elseif reason == "no-character" then
			-- 角色还没加载 / 正在重生，静默等

		else
			alreadyWarnedNoFolder = false

			if moved ~= lastMoved then
				if moved == 0 then
					print("[带来废品] Drops 里现在是空的 —— 附近没有掉落物")
				else
					print(("[带来废品] 已把 %d 件掉落物搬到你身上"):format(moved))
				end
				lastMoved = moved
			end
		end

		if CONFIG.Interval <= 0 then
			break
		end

		task.wait(CONFIG.Interval)
	end

	running = false
end)

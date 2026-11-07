--[[
  SutureHub Loader v1.0
  独立加载器：虚化背景 + 雪花特效 + 标题渐显 + 圆角进度条（右侧数字进度 + 实时任务文字）
  + UI 附加队列（远程脚本先注册控件，WindUI 就绪后一次性批量附加，避免竞态卡顿）

  用法：
    local Loader = loadstring(game:HttpGet("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/SutureLoader.lua"))()
    Loader:Show()
    Loader:AddTask("正在加载 UI 库", function()
        _G.WindUI = loadstring(game:HttpGet("https://.../WindUI-Boreal.lua"))()
    end)
    -- 远程脚本注册 UI 控件（不立即附加）
    Loader:QueueUI("远程脚本A", function(Window) Window:AddTab({...}) end)
    Loader:Start(function()
        local Window = _G.WindUI:CreateWindow({...})
        Loader:FlushUI(Window)  -- 批量附加
        Loader:Finish()
    end)
]]

local Loader = {}
Loader.__index = Loader

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui")

local Font = Enum.Font.Gotham

local function New(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		obj[k] = v
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = obj
		end
	end
	return obj
end

local function Tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

function Loader.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Loader)
	self.Title = opts.Title or "Suture Hub"
	self.Subtitle = opts.Subtitle or ""
	self.Tasks = {}
	self.UIQueue = {}
	self.Running = false
	self.Finished = false
	self.Snowflakes = {}
	return self
end

-- 加入加载任务（名称 + 执行函数）
function Loader:AddTask(name, fn)
	table.insert(self.Tasks, { Name = name, Fn = fn })
	return self
end

-- 注册 UI 构建器（WindUI 就绪后由 FlushUI 批量附加）
function Loader:QueueUI(name, builder)
	table.insert(self.UIQueue, { Name = name, Builder = builder })
	return self
end

-- 显示加载界面
function Loader:Show()
	if self.Running then
		return self
	end
	self.Running = true

	local gui = New("ScreenGui", {
		Name = "SutureLoader",
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})
	self.Gui = gui

	-- 虚化背景（半透明深色）
	local Bg = New("Frame", {
		Name = "Bg",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(8, 10, 16),
		BackgroundTransparency = 0.32,
		Parent = gui,
	})
	self.Bg = Bg

	-- 标题（屏幕中间渐显）
	local Title = New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = self.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 36,
		Font = Font,
		FontWeight = Enum.FontWeight.Bold,
		TextTransparency = 1,
		TextStrokeTransparency = 0.5,
		Parent = gui,
	})
	self.TitleLbl = Title

	-- 副标题
	if self.Subtitle ~= "" then
		local Sub = New("TextLabel", {
			Name = "Subtitle",
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0.5, 0, 0.42, 60),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = self.Subtitle,
			TextColor3 = Color3.fromRGB(170, 180, 200),
			TextSize = 15,
			Font = Font,
			TextTransparency = 1,
			Parent = gui,
		})
		self.SubLbl = Sub
	end

	-- 进度条背景（圆角）
	local BarBg = New("Frame", {
		Name = "BarBg",
		Size = UDim2.new(0, 340, 0, 14),
		Position = UDim2.new(0.5, 0, 0.42, 96),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(28, 32, 40),
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	self.BarBg = BarBg

	-- 进度条填充（圆角 + 渐变）
	local Bar = New("Frame", {
		Name = "Bar",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(70, 150, 255),
		BackgroundTransparency = 0,
		Parent = BarBg,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 200, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 110, 255)),
			}),
			Rotation = 90,
		}),
	})
	self.Bar = Bar

	-- 数字进度（进度条右侧）
	local Pct = New("TextLabel", {
		Name = "Pct",
		Size = UDim2.new(0, 60, 0, 24),
		Position = UDim2.new(1, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text = "0%",
		TextColor3 = Color3.fromRGB(140, 200, 255),
		TextSize = 15,
		Font = Font,
		FontWeight = Enum.FontWeight.SemiBold,
		TextTransparency = 1,
		Parent = BarBg,
	})
	self.PctLbl = Pct

	-- 当前任务文字（进度条下方）
	local TaskLbl = New("TextLabel", {
		Name = "Task",
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0.5, 0, 0.42, 122),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(220, 226, 235),
		TextSize = 14,
		Font = Font,
		TextTransparency = 1,
		Parent = gui,
	})
	self.TaskLbl = TaskLbl

	-- 渐显动画
	Tween(Title, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
	if self.SubLbl then
		Tween(self.SubLbl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
	end
	Tween(Pct, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
	Tween(TaskLbl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })

	-- 雪花特效
	self:StartSnow(gui)

	return self
end

-- 雪花：白色雪花字符从顶部飘落（循环）
function Loader:StartSnow(gui)
	local chars = { "❄", "❅", "❆", "❄" }
	for _ = 1, 16 do
		local size = math.random(12, 20)
		local flake = New("TextLabel", {
			Name = "Snow",
			Size = UDim2.new(0, size, 0, size),
			Position = UDim2.new(math.random() * 1, 0, math.random() * -0.3, 0),
			BackgroundTransparency = 1,
			Text = chars[math.random(1, #chars)],
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = math.random() * 0.4 + 0.2,
			TextSize = size,
			Font = Font,
			Parent = gui,
		})
		table.insert(self.Snowflakes, flake)
		task.spawn(function()
			while self.Running and flake.Parent do
				local dur = math.random(6, 10)
				local targetX = math.random() * 1
				local tw = Tween(flake, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
					Position = UDim2.new(targetX, 0, 1.05, 0),
				})
				tw.Completed:Wait()
				if not self.Running or not flake.Parent then
					break
				end
				flake.Position = UDim2.new(math.random() * 1, 0, -0.15, 0)
				flake.TextTransparency = math.random() * 0.4 + 0.2
			end
		end)
	end
end

-- 设置进度（0-100，可选任务文字）
function Loader:SetProgress(p, label)
	if not self.Running or not self.BarBg then
		return
	end
	p = math.max(0, math.min(100, p))
	local w = self.BarBg.AbsoluteSize.X
	local h = self.BarBg.AbsoluteSize.Y
	Tween(self.Bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(math.floor(w * p / 100), h),
	})
	if self.PctLbl then
		self.PctLbl.Text = string.format("%d%%", math.floor(p))
	end
	if label and self.TaskLbl then
		self.TaskLbl.Text = label
	end
end

-- 开始逐个执行任务队列，完成后回调
function Loader:Start(cb)
	if not self.Running then
		self:Show()
	end
	local n = #self.Tasks
	if n == 0 then
		if cb then
			pcall(cb)
		end
		return self
	end
	task.spawn(function()
		for i, task in ipairs(self.Tasks) do
			if self.TaskLbl then
				self.TaskLbl.Text = task.Name
			end
			local ok, err = pcall(task.Fn)
			if not ok and err then
				warn("[SutureLoader] 任务失败: " .. tostring(task.Name) .. " - " .. tostring(err))
			end
			self:SetProgress((i / n) * 100)
			task.wait(0.06)
		end
		self:SetProgress(100, "加载完成")
		task.wait(0.4)
		if cb then
			pcall(cb)
		end
	end)
	return self
end

-- WindUI 就绪后：批量附加队列中的 UI 控件（一次性附加，避免逐帧塞入卡顿）
function Loader:FlushUI(Window)
	local n = #self.UIQueue
	for i, item in ipairs(self.UIQueue) do
		if self.TaskLbl then
			self.TaskLbl.Text = "正在附加 UI: " .. tostring(item.Name)
		end
		local ok, err = pcall(item.Builder, Window)
		if not ok and err then
			warn("[SutureLoader] UI 附加失败: " .. tostring(item.Name) .. " - " .. tostring(err))
		end
		if i < n then
			task.wait(0.03)
		end
	end
	table.clear(self.UIQueue)
	return self
end

-- 完成：淡出并销毁界面
function Loader:Finish()
	if self.Finished then
		return self
	end
	self.Finished = true
	self.Running = false
	local gui = self.Gui
	task.spawn(function()
		if not gui then
			return
		end
		local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if self.Bg then
			Tween(self.Bg, fade, { BackgroundTransparency = 1 })
		end
		if self.TitleLbl then
			Tween(self.TitleLbl, fade, { TextTransparency = 1 })
		end
		if self.SubLbl then
			Tween(self.SubLbl, fade, { TextTransparency = 1 })
		end
		if self.BarBg then
			Tween(self.BarBg, fade, { BackgroundTransparency = 1 })
		end
		if self.PctLbl then
			Tween(self.PctLbl, fade, { TextTransparency = 1 })
		end
		if self.TaskLbl then
			Tween(self.TaskLbl, fade, { TextTransparency = 1 })
		end
		for _, flake in ipairs(self.Snowflakes) do
			if flake and flake.Parent then
				Tween(flake, fade, { TextTransparency = 1 })
			end
		end
		task.wait(0.55)
		if gui and gui.Parent then
			gui:Destroy()
		end
	end)
	return self
end

return Loader

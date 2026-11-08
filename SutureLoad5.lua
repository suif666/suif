-- SutureLoad5 v1.3.1 [suture] - Suture Hub one-click launcher (flat, ASCII, compatible)
pcall(function()
    if rconsoleprint then
        rconsoleprint("[SutureLoad] boot v1.3.1 (SutureLoad5) - entry script is running\n")
    end
end)
warn("[SutureLoad] boot v1.3.1 (SutureLoad5) - entry script is running")
-- Single file: loader UI + WindUI preload + suif main script.
-- Run: loadstring(game:HttpGet("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/SutureLoad3.lua"))()

-----------------------------------------------------------------------
-- [1] Task compatibility wrappers (old executors may lack task.wait)
-----------------------------------------------------------------------
local TASK = (type(task) == "table" or type(task) == "userdata") and task or {}
local HAS_WAIT = type(TASK.wait) == "function"
local HAS_SPAWN = type(TASK.spawn) == "function"
local HAS_DELAY = type(TASK.delay) == "function"

local function Wait(t)
    if HAS_WAIT then
        return TASK.wait(t)
    end
    if wait then
        return wait(t)
    end
    return nil
end

local function Spawn(fn)
    if HAS_SPAWN then
        return TASK.spawn(fn)
    end
    if spawn then
        return spawn(fn)
    end
    local co = coroutine.create(fn)
    return coroutine.resume(co)
end

local function Delay(t, fn)
    if HAS_DELAY then
        return TASK.delay(t, fn)
    end
    if delay then
        return delay(t, fn)
    end
    Spawn(function()
        Wait(t)
        fn()
    end)
end

-----------------------------------------------------------------------
-- [2] Minimal GUI helpers
-----------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui")

local FONT_DEFAULT = Enum.Font.Gotham

local function New(class, props, children)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = obj
        end
    end
    return obj
end

local function Tween(obj, duration, props)
    local tw = TweenService:Create(obj, TweenInfo.new(duration), props)
    tw:Play()
    return tw
end

-----------------------------------------------------------------------
-- [3] Loader core
-----------------------------------------------------------------------
local Loader = {}
Loader.__index = Loader

function Loader.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Loader)
    self.Title = opts.Title or "Suture Hub"
    self.Subtitle = opts.Subtitle or ""
    self.Version = opts.Version or ""
    self.LogoImage = opts.LogoImage or ""
    self.Tasks = {}
    self.UIQueue = {}
    self.Running = false
    self.Finished = false
    self.Snowflakes = {}
    return self
end

function Loader:AddTask(name, fn)
    table.insert(self.Tasks, { Name = name, Fn = fn })
    return self
end

function Loader:QueueUI(name, builder)
    table.insert(self.UIQueue, { Name = name, Builder = builder })
    return self
end

function Loader:Show()
    if self.Running then
        return self
    end
    -- lazy init (safe even without Loader.new)
    self.Tasks = self.Tasks or {}
    self.UIQueue = self.UIQueue or {}
    self.Snowflakes = self.Snowflakes or {}
    self.Running = true

    -- 隐蔽宿主：优先挂到执行器隐藏容器（gethui），其次 CoreGui（游戏读不到），
    -- 都拿不到才退回 PlayerGui（名称伪装成常见 LoadingScreen）
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local okH, h = pcall(function()
        return gethui and gethui()
    end)
    local host = (okH and h) or nil
    if not host then
        local okC, cg = pcall(function()
            return game:GetService("CoreGui")
        end)
        host = (okC and cg) or pg
    end
    -- 顺手保护容器（有些执行器靠这个把容器从游戏可见范围摘出去）
    pcall(function()
        if protect_gui then
            protect_gui(host)
        elseif syn and syn.protect_gui then
            syn.protect_gui(host)
        end
    end)
    local gui = New("ScreenGui", {
        Name = "LoadingScreen",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = host,
    })
    self.Gui = gui

    -- ═══ 背景：渐变遮罩 ═══
    local Bg = New("Frame", {
        Name = "Bg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(6, 8, 14),
        BackgroundTransparency = 0.42,
        Parent = gui,
    }, {
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 16, 28)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 10, 18)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 12, 28)),
            }),
            Rotation = 90,
        }),
    })
    self.Bg = Bg

    -- ═══ 装饰光晕（缓慢漂浮） ═══
    local GlowData = {
        { Size = 340, X = 0.18, Y = 0.26, C = Color3.fromRGB(70, 150, 255), T = 0.93 },
        { Size = 260, X = 0.83, Y = 0.64, C = Color3.fromRGB(130, 90, 255), T = 0.94 },
        { Size = 190, X = 0.74, Y = 0.18, C = Color3.fromRGB(60, 210, 255), T = 0.95 },
    }
    self.Glows = {}
    for i, gd0 in ipairs(GlowData) do
        local gd = gd0
        local g = New("Frame", {
            Name = "Glow" .. i,
            Size = UDim2.fromOffset(gd.Size, gd.Size),
            Position = UDim2.new(gd.X, 0, gd.Y, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = gd.C,
            BackgroundTransparency = gd.T,
            Parent = gui,
        }, {
            New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })
        table.insert(self.Glows, g)
        Spawn(function()
            while self.Running and g.Parent do
                Tween(g, 3 + math.random() * 3, {
                    Position = UDim2.new(gd.X + (math.random() * 0.06 - 0.03), 0, gd.Y + (math.random() * 0.08 - 0.04), 0),
                })
                Wait(3 + math.random() * 3)
            end
        end)
    end

    -- ═══ 卡片阴影（双层） ═══
    local Shade2 = New("Frame", {
        Name = "Shade2",
        Size = UDim2.new(1, 26, 1, 26),
        Position = UDim2.new(0.5, 0, 0.5, 26),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.85,
        ZIndex = 1,
        Parent = gui,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 22) }),
    })
    local Shade1 = New("Frame", {
        Name = "Shade1",
        Size = UDim2.new(1, 14, 1, 14),
        Position = UDim2.new(0.5, 0, 0.5, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.72,
        ZIndex = 1,
        Parent = gui,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 22) }),
    })

    -- ═══ 中央卡片 ═══
    local Card = New("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(420, 330),
        Position = UDim2.new(0.5, 0, 0.5, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 28, 38),
        BackgroundTransparency = 0.35,
        ZIndex = 2,
        Parent = gui,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 22) }),
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 38, 52)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 23, 33)),
            }),
            Rotation = 0,
        }),
    })
    self.Card = Card
    pcall(function()
        local st = Instance.new("UIStroke")
        st.Color = Color3.fromRGB(130, 170, 255)
        st.Transparency = 0.8
        st.Thickness = 1
        st.Parent = Card
    end)

    -- ═══ Logo 圆标 ═══
    local Logo = New("Frame", {
        Name = "Logo",
        Size = UDim2.fromOffset(64, 64),
        Position = UDim2.new(0.5, 0, 0, 30),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(70, 130, 255),
        ZIndex = 2,
        Parent = Card,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 18) }),
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 200, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(95, 100, 255)),
            }),
            Rotation = 90,
        }),
    })
    self.Logo = Logo
    if self.LogoImage and self.LogoImage ~= "" then
        -- 自定义图片 Logo
        local LogoImg = New("ImageLabel", {
            Name = "LogoImg",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = self.LogoImage,
            ScaleType = Enum.ScaleType.Crop,
            ImageTransparency = 1,
            Parent = Logo,
        })
        self.LogoImg = LogoImg
        Tween(LogoImg, 0.6, { ImageTransparency = 0 })
    else
        -- 默认渐变圆 + 小号字母
        local LogoText = New("TextLabel", {
            Name = "LogoText",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "S",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 26,
            Font = Enum.Font.GothamBold,
            TextStrokeTransparency = 0.3,
            TextTransparency = 1,
            Parent = Logo,
        })
        self.LogoText = LogoText
        Tween(LogoText, 0.6, { TextTransparency = 0 })
    end

    -- ═══ 版本徽章 ═══
    local VerTag = New("Frame", {
        Name = "VerTag",
        Size = UDim2.fromOffset(76, 26),
        Position = UDim2.new(1, -16, 0, 14),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Color3.fromRGB(38, 66, 118),
        ZIndex = 2,
        Parent = Card,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    self.VerTag = VerTag
    local VerLbl = New("TextLabel", {
        Name = "VerLbl",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = self.Version or "",
        TextColor3 = Color3.fromRGB(150, 200, 255),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        Parent = VerTag,
    })
    self.VerLbl = VerLbl

    -- ═══ 标题 ═══
    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.new(0.5, 0, 0, 112),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 32,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        TextStrokeTransparency = 0.4,
        ZIndex = 2,
        Parent = Card,
    })
    self.TitleLbl = Title

    -- ═══ 副标题 ═══
    if self.Subtitle ~= "" then
        local Sub = New("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0.5, 0, 0, 158),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = self.Subtitle,
            TextColor3 = Color3.fromRGB(150, 160, 180),
            TextSize = 13,
            Font = FONT_DEFAULT,
            TextTransparency = 1,
            ZIndex = 2,
            Parent = Card,
        })
        self.SubLbl = Sub
    end

    -- ═══ 进度条 ═══
    local BarBg = New("Frame", {
        Name = "BarBg",
        Size = UDim2.new(0, 270, 0, 8),
        Position = UDim2.new(0.5, 0, 0, 196),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(40, 46, 60),
        BackgroundTransparency = 0.35,
        ZIndex = 2,
        Parent = Card,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    self.BarBg = BarBg

    local Bar = New("Frame", {
        Name = "Bar",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(70, 150, 255),
        BackgroundTransparency = 0,
        ClipsDescendants = true,
        ZIndex = 2,
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
    -- 前端流动高光
    local BarShine = New("Frame", {
        Name = "BarShine",
        Size = UDim2.fromOffset(90, 8),
        Position = UDim2.new(0, -90, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.78,
        Parent = Bar,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    self.BarShine = BarShine

    -- ═══ 百分比（大数字） ═══
    local Pct = New("TextLabel", {
        Name = "Pct",
        Size = UDim2.new(0, 64, 0, 26),
        Position = UDim2.new(1, 6, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Color3.fromRGB(140, 200, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        ZIndex = 2,
        Parent = BarBg,
    })
    self.PctLbl = Pct

    -- ═══ 任务文字 + 状态点 ═══
    local TaskRow = New("Frame", {
        Name = "TaskRow",
        Size = UDim2.new(1, -170, 0, 24),
        Position = UDim2.new(0.5, 0, 0, 220),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = Card,
    })
    local Dot = New("Frame", {
        Name = "Dot",
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(80, 220, 120),
        ZIndex = 2,
        Parent = TaskRow,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    self.Dot = Dot
    local TaskLbl = New("TextLabel", {
        Name = "Task",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(200, 208, 220),
        TextSize = 14,
        Font = FONT_DEFAULT,
        TextTransparency = 1,
        ZIndex = 2,
        Parent = TaskRow,
    })
    self.TaskLbl = TaskLbl

    -- ═══ 入场动画 ═══
    Tween(Card, 0.7, { Position = UDim2.new(0.5, 0, 0.5, 0) })
    Tween(Card, 0.7, { BackgroundTransparency = 0.12 })
    Tween(VerLbl, 0.6, { TextTransparency = 0 })
    Tween(Title, 0.8, { TextTransparency = 0 })
    if self.SubLbl then
        Tween(self.SubLbl, 0.8, { TextTransparency = 0 })
    end
    Tween(Pct, 0.8, { TextTransparency = 0 })
    Tween(TaskLbl, 0.8, { TextTransparency = 0 })

    -- ═══ 高光流动循环 ═══
    Spawn(function()
        while self.Running and BarShine.Parent do
            Tween(BarShine, 1.1, { Position = UDim2.new(1, 90, 0, 0) })
            Wait(1.1)
            BarShine.Position = UDim2.new(0, -90, 0, 0)
        end
    end)

    -- snow + particles
    self:StartSnow(gui)

    return self
end

function Loader:StartSnow(gui)
    -- 雪花（22 片，初始散布在可见区，循环下落）
    for _ = 1, 22 do
        local size = math.random(8, 14)
        local flake = New("TextLabel", {
            Name = "Snow",
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(math.random() * 1, 0, math.random() * 0.6, 0),
            BackgroundTransparency = 1,
            Text = "*",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = math.random() * 0.5 + 0.2,
            TextSize = size,
            Font = FONT_DEFAULT,
            Parent = gui,
        })
        table.insert(self.Snowflakes, flake)
        Spawn(function()
            while self.Running and flake.Parent do
                local dur = math.random(6, 11)
                local targetX = math.random() * 1
                local tw = TweenService:Create(flake, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(targetX, 0, 1.1, 0),
                })
                tw:Play()
                tw.Completed:Wait()
                if not self.Running or not flake.Parent then
                    break
                end
                flake.Position = UDim2.new(math.random() * 1, 0, -0.15, 0)
                flake.TextTransparency = math.random() * 0.5 + 0.2
            end
        end)
    end
    -- 光点粒子（16 颗，初始散布在可见区，循环上浮）
    for _ = 1, 16 do
        local size = math.random(3, 6)
        local p = New("Frame", {
            Name = "Particle",
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.new(math.random() * 1, 0, math.random() * 0.9 + 0.1, 0),
            BackgroundColor3 = Color3.fromRGB(160, 210, 255),
            BackgroundTransparency = math.random() * 0.5 + 0.25,
            Parent = gui,
        }, {
            New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })
        table.insert(self.Snowflakes, p)
        Spawn(function()
            while self.Running and p.Parent do
                local dur = math.random(7, 12)
                local tw = TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(math.random() * 1, 0, -0.15, 0),
                })
                tw:Play()
                tw.Completed:Wait()
                if not self.Running or not p.Parent then
                    break
                end
                p.Position = UDim2.new(math.random() * 1, 0, 1.15, 0)
            end
        end)
    end
end


function Loader:SetProgress(p, label)
    if not self.Running or not self.BarBg then
        return
    end
    p = math.max(0, math.min(100, p))
    local w = self.BarBg.AbsoluteSize.X
    local h = self.BarBg.AbsoluteSize.Y
    Tween(self.Bar, 0.25, {
        Size = UDim2.fromOffset(math.floor(w * p / 100), h),
    })
    if self.PctLbl then
        self.PctLbl.Text = string.format("%d%%", math.floor(p))
    end
    if label and self.TaskLbl then
        self.TaskLbl.Text = label
    end
end

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
    Spawn(function()
        for i, task in ipairs(self.Tasks) do
            if self.TaskLbl then
                self.TaskLbl.Text = task.Name
                self.TaskLbl.TextTransparency = 0.55
                Tween(self.TaskLbl, 0.25, { TextTransparency = 0 })
            end
            local ok, err = pcall(task.Fn)
            if not ok and err then
                warn("[SutureLoader] task failed: " .. tostring(task.Name) .. " - " .. tostring(err))
            end
            self:SetProgress((i / n) * 100)
            Wait(0.06)
        end
        self:SetProgress(100, "加载完成")
        Wait(0.4)
        if cb then
            pcall(cb)
        end
    end)
    return self
end

function Loader:FlushUI(Window)
    local n = #self.UIQueue
    for i, item in ipairs(self.UIQueue) do
        if self.TaskLbl then
            self.TaskLbl.Text = "正在附加 UI: " .. tostring(item.Name)
        end
        local ok, err = pcall(item.Builder, Window)
        if not ok and err then
            warn("[SutureLoader] UI failed: " .. tostring(item.Name) .. " - " .. tostring(err))
        end
        if i < n then
            Wait(0.03)
        end
    end
    self.UIQueue = {}
    return self
end

function Loader:Finish()
    if self.Finished then
        return self
    end
    self.Finished = true
    self.Running = false
    local gui = self.Gui
    Spawn(function()
        if not gui then
            return
        end
        -- 停雪花/粒子（雪花是 TextLabel，粒子是 Frame，属性不同分开 tween）
        for _, flake in ipairs(self.Snowflakes) do
            if flake and flake.Parent then
                pcall(function()
                    if flake:IsA("TextLabel") then
                        Tween(flake, 0.4, { TextTransparency = 1 })
                    else
                        Tween(flake, 0.4, { BackgroundTransparency = 1 })
                    end
                end)
            end
        end
        -- 卡片下坠+淡出
        if self.Card then
            Tween(self.Card, 0.4, { Position = UDim2.new(0.5, 0, 0.5, 14) })
            Tween(self.Card, 0.5, { BackgroundTransparency = 1 })
        end
        if self.Bg then
            Tween(self.Bg, 0.5, { BackgroundTransparency = 1 })
        end
        if self.TitleLbl then
            Tween(self.TitleLbl, 0.4, { TextTransparency = 1 })
        end
        if self.SubLbl then
            Tween(self.SubLbl, 0.4, { TextTransparency = 1 })
        end
        if self.BarBg then
            Tween(self.BarBg, 0.4, { BackgroundTransparency = 1 })
        end
        if self.PctLbl then
            Tween(self.PctLbl, 0.4, { TextTransparency = 1 })
        end
        if self.TaskLbl then
            Tween(self.TaskLbl, 0.4, { TextTransparency = 1 })
        end
        if self.VerLbl then
            Tween(self.VerLbl, 0.4, { TextTransparency = 1 })
        end
        if self.Logo then
            Tween(self.Logo, 0.4, { BackgroundTransparency = 1 })
        end
        if self.LogoText then
            Tween(self.LogoText, 0.4, { TextTransparency = 1 })
        end
        if self.LogoImg then
            Tween(self.LogoImg, 0.4, { ImageTransparency = 1 })
        end
        for _, g in ipairs(self.Glows or {}) do
            if g and g.Parent then
                Tween(g, 0.5, { BackgroundTransparency = 1 })
            end
        end
        Wait(0.55)
        if gui and gui.Parent then
            gui:Destroy()
        end
    end)
    -- 绝对兜底：动画协程任何一步崩了，2 秒后也强制销毁 GUI
    Delay(2, function()
        pcall(function()
            if gui and gui.Parent then
                gui:Destroy()
            end
        end)
    end)
    return self
end

-----------------------------------------------------------------------
-- [4] Entry logic: URLs
-----------------------------------------------------------------------
local SUIF_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif.lua"
local WINDUI_SRC = {
    "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua",
    "https://cdn.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
    "https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua",
    "https://gcore.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
}

local function TryLoad(url, execute)
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(src) ~= "string" or #src == 0 then
        return nil
    end
    local fn, cerr = loadstring(src)
    if not fn then
        return nil
    end
    if execute then
        -- 模块类（WindUI）：执行并返回模块
        local ran, mod = pcall(fn)
        if ran and mod then
            return mod
        end
        return nil
    end
    -- 脚本类（远程脚本）：只编译不执行，等窗口出现后统一挂载
    return fn
end

-----------------------------------------------------------------------
-- [5] Boot
-----------------------------------------------------------------------
local inst = Loader.new({ Title = "Suture Hub", Subtitle = "现代加载器 · 分帧挂载", Version = "v1.9" })
inst:Show()

local REMOTE_SPECS = {
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua", desc = "范围" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%94%A9%E9%A3%9E.lua", desc = "甩飞" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%98%BE%E7%A4%BAfps%E5%92%8Cping.lua", desc = "ping/fps显示" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua", desc = "雷达" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", desc = "玩家类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", desc = "自瞄类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua", desc = "发言类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua", desc = "ESP" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua", desc = "服务器类" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9D%90%E6%A0%87%E4%BC%A0%E9%80%81.lua", desc = "坐标传送" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/animation.lua", desc = "动作动画" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/actionpack.lua", desc = "动作包" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/animpack.lua", desc = "动画包" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/disguise.lua", desc = "伪装玩家" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/slowrun.lua", desc = "缓慢的快速跑" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/clicker.lua", desc = "自动连点器" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/npc.lua", desc = "NPC交互" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/trigger.lua", desc = "触发类" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/object.lua", desc = "控制物体" },
}

-- 预下载远程脚本：加载器阶段全部下载+编译排队，窗口出现瞬间一次性挂载
local function PreloadRemotes(inst)
    local g = (getgenv and getgenv()) or _G
    if not g then
        return
    end
    g.__SUIF_PENDING = g.__SUIF_PENDING or {}
    g.__PRELOADED_URLS = g.__PRELOADED_URLS or {}
    local total = #REMOTE_SPECS
    local done = 0
    local queue = {}
    for _, spec in ipairs(REMOTE_SPECS) do
        table.insert(queue, spec)
    end
    -- 4 路并发下载（比顺序快约 4 倍），进度实时刷新
    local function worker()
        while #queue > 0 do
            local spec = table.remove(queue, 1)
            local fn = TryLoad(spec.url, false)
            if fn then
                table.insert(g.__SUIF_PENDING, fn)
                g.__PRELOADED_URLS[spec.url] = true
            end
            done = done + 1
            if inst.TaskLbl then
                inst.TaskLbl.Text = "正在加载远程脚本 " .. done .. "/" .. total
            end
        end
    end
    for _ = 1, 4 do
        Spawn(worker)
    end
    -- 任务链是同步的：等全部下载完成再返回
    repeat
        Wait(0.1)
    until done >= total
end

inst:AddTask("正在加载 UI 库", function()
    local g = (getgenv and getgenv()) or _G
    for _, u in ipairs(WINDUI_SRC) do
        local mod = TryLoad(u, true)
        if mod then
            g.WindUI = mod
            return
        end
    end
    error("WindUI load failed (4 mirrors unavailable)")
end)

inst:AddTask("正在加载远程脚本 0/0", function()
    PreloadRemotes(inst)
end)

inst:AddTask("正在加载 Suture Hub", function()
    -- ★ [suture] 开启预编译模式：suif 主脚本内的远程脚本只下载+编译排队，
    --   等主窗口创建完成后由 suif 一次性批量挂载（不再逐个加载）
    local g = (getgenv and getgenv()) or _G
    if g then
        g.__SUIF_PRELOAD = true
        g.__SUIF_PENDING = g.__SUIF_PENDING or {}
    end
    local okSrc, src = pcall(function()
        return game:HttpGet(SUIF_URL)
    end)
    if not okSrc or type(src) ~= "string" or #src == 0 then
        error("suif main script fetch failed")
    end
    local fn, cerr = loadstring(src)
    if not fn then
        error(cerr)
    end
    fn()
end)

inst:Start(function()
    local g = (getgenv and getgenv()) or _G
    if g then
        g.__SUIF_READY = function()
            pcall(function()
                inst:Finish()
            end)
        end
    end
    Delay(10, function()
        pcall(function()
            inst:Finish()
        end)
    end)
end)

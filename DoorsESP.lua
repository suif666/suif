--[[
=====================================================================
  Doors · ESP 提取版 (原版行为)          自建 UI / 单文件 / 无外部依赖
=====================================================================
  提取来源: AbysallContinued  ·  Games/Doors/Main.luau  (318,523 B, md5 9cca1d64…)
            +  Components/ESP.luau  (17,870 B, 原样内联)

  ★ 设计原则: 视觉效果 = 原版。没有加任何原版没有的功能。
    - ESP 渲染完全用原版 Components/ESP.luau 那套
      (Highlight + ScreenGui 文字标签 + WorldToViewportPoint + RenderLimit)
    - 物品/实体/宝箱/门/藏身点… 的文字串、颜色、房间裁剪规则、默认值
      全部照搬原版 Main.luau，没有翻译、没有改名
    - 开关默认值也和原版一样(全是 false)，开了才有效果

  相对原版只动了这些(其他全是照搬):
    1. 视野滑条默认值 70 -> 120（你要求的）
    2. ESP 文字加了一个总开关「隐藏 ESP 文字」
       ——原版只有 Text Transparency 滑条，效果一样，这个只是好按
    3. 界面用自建 UI 重排；「Custom Fov 快捷键」默认 O 键切视野开关

  UI 是自己写的(拖动/标签页/开关/滑块/取色/下拉/多选/按键)，没有引用 WindUI。
  卸载: getgenv().DoorsESPX.Unload()
=====================================================================
]]

--=====================================================================
-- 0. 服务
--=====================================================================
local cloneref = cloneref or function(o) return o end

local Services = setmetatable({}, {
    __index = function(self, name)
        local svc = cloneref(game:GetService(name))
        rawset(self, name, svc)
        return svc
    end,
})

local Players           = Services.Players
local Workspace         = Services.Workspace
local RunService        = Services.RunService
local UserInputService  = Services.UserInputService
local TweenService      = Services.TweenService
local ReplicatedStorage = Services.ReplicatedStorage
local LocalPlayer       = Players.LocalPlayer

local STATE_KEY = "DoorsESPX"
if getgenv()[STATE_KEY] then
    pcall(function() getgenv()[STATE_KEY].Unload() end)
end

local function RandomString(n)
    local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local out, len = {}, #pool
    for i = 1, (n or 20) do
        local k = math.random(1, len)
        out[i] = pool:sub(k, k)
    end
    return table.concat(out)
end

local function Create(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function GetHiddenUI()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    return Services.CoreGui
end

--=====================================================================
-- 1. 自建 UI 库
--=====================================================================
local Theme = {
    Bg       = Color3.fromRGB(18, 19, 23),
    Panel    = Color3.fromRGB(26, 28, 34),
    Row      = Color3.fromRGB(32, 35, 42),
    RowHover = Color3.fromRGB(40, 44, 53),
    Stroke   = Color3.fromRGB(48, 52, 62),
    Text     = Color3.fromRGB(232, 236, 244),
    SubText  = Color3.fromRGB(140, 148, 164),
    Accent   = Color3.fromRGB(0, 200, 255),
    Font     = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
}

local Mini = {}

local function MakeRow(parent, height)
    local row = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, height),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    return row
end

local function MakeLabel(parent, text, x, w, color, font, size)
    return Create("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Font = font or Theme.Font,
        Text = text,
        TextSize = size or 13,
        TextColor3 = color or Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, w, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

function Mini.NewWindow(title, subtitle)
    local gui = Create("ScreenGui", {
        Name = RandomString(24),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    if protect_gui then pcall(protect_gui, gui) end
    gui.Parent = GetHiddenUI()

    local root = Create("Frame", {
        Name = "Root",
        Parent = gui,
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -320, 0.5, -215),
        Size = UDim2.fromOffset(640, 430),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, root)
    Create("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, root)

    local barHeight = 40
    local bar = Create("Frame", {
        Name = "Bar", Parent = root,
        BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, barHeight),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }, bar)
    Create("Frame", {
        Parent = bar, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8),
    })
    Create("Frame", {
        Parent = root, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, barHeight - 2), Size = UDim2.new(1, -20, 0, 2),
    })

    Create("TextLabel", {
        Parent = bar, BackgroundTransparency = 1, Font = Theme.FontBold,
        Text = title, TextSize = 15, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
    })
    Create("TextLabel", {
        Parent = bar, BackgroundTransparency = 1, Font = Theme.Font,
        Text = subtitle or "", TextSize = 11, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.35, 0, 0, 0), Size = UDim2.new(0.5, -46, 1, 0),
    })

    local closeBtn = Create("TextButton", {
        Parent = bar, BackgroundColor3 = Color3.fromRGB(46, 30, 32), BorderSizePixel = 0,
        AutoButtonColor = false, Font = Theme.FontBold, Text = "×",
        TextSize = 18, TextColor3 = Color3.fromRGB(255, 150, 150),
        Position = UDim2.new(1, -34, 0, 6), Size = UDim2.fromOffset(26, 26),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)
    local minBtn = Create("TextButton", {
        Parent = bar, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        AutoButtonColor = false, Font = Theme.FontBold, Text = "—",
        TextSize = 14, TextColor3 = Theme.SubText,
        Position = UDim2.new(1, -66, 0, 6), Size = UDim2.fromOffset(26, 26),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)

    local tabBar = Create("ScrollingFrame", {
        Parent = root, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, barHeight + 10),
        Size = UDim2.new(0, 130, 1, -(barHeight + 18)),
        ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, tabBar)
    Create("UIListLayout", {
        Parent = tabBar, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent = tabBar,
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
    })

    local pages = Create("Frame", {
        Parent = root, BackgroundTransparency = 1,
        Position = UDim2.new(0, 146, 0, barHeight + 10),
        Size = UDim2.new(1, -154, 1, -(barHeight + 18)),
    })

    local window = { Gui = gui, Root = root, Tabs = {}, ActiveTab = nil }

    do
        local dragging, dragStart, startPos = false, nil, nil
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, root.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(function() root.Visible = false end)
    minBtn.MouseButton1Click:Connect(function() root.Visible = false end)

    function window:SetVisible(v) root.Visible = v end
    function window:Toggle() root.Visible = not root.Visible end

    function window:Tab(name)
        local page = Create("ScrollingFrame", {
            Parent = pages, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Stroke,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        })
        Create("UIListLayout", {
            Parent = page, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local btn = Create("TextButton", {
            Parent = tabBar, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
            AutoButtonColor = false, Font = Theme.Font, Text = name, TextSize = 13,
            TextColor3 = Theme.SubText, Size = UDim2.new(1, -12, 0, 32),
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

        local tab = { Page = page, Button = btn, Name = name }
        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(window.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.15),
                    { BackgroundColor3 = Theme.Row }):Play()
                t.Button.TextColor3 = Theme.SubText
            end
            page.Visible = true
            TweenService:Create(btn, TweenInfo.new(0.15),
                { BackgroundColor3 = Color3.fromRGB(30, 62, 78) }):Play()
            btn.TextColor3 = Theme.Accent
            window.ActiveTab = tab
        end)

        window.Tabs[#window.Tabs + 1] = tab
        if not window.ActiveTab then
            page.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(30, 62, 78)
            btn.TextColor3 = Theme.Accent
            window.ActiveTab = tab
        end
        return tab
    end

    return window
end

function Mini.Toggle(parent, cfg)
    local row = MakeRow(parent, 34)
    local lbl = MakeLabel(row, cfg.Text, 12, 220, Theme.Text, Theme.Font, 13)
    if cfg.Tooltip then
        lbl.Size = UDim2.new(1, -78, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 3)
        Create("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Font = Theme.Font,
            Text = cfg.Tooltip, TextSize = 10, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 12, 0, 18), Size = UDim2.new(1, -78, 0, 13),
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
        })
    else
        lbl.Size = UDim2.new(1, -78, 1, 0)
    end

    local sw = Create("Frame", {
        Parent = row, BackgroundColor3 = Color3.fromRGB(52, 56, 66),
        BorderSizePixel = 0, Position = UDim2.new(1, -50, 0.5, -9),
        Size = UDim2.fromOffset(38, 18),
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
    local knob = Create("Frame", {
        Parent = sw, BackgroundColor3 = Color3.fromRGB(180, 186, 198),
        BorderSizePixel = 0, Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.fromOffset(14, 14),
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local btn = Create("TextButton", {
        Parent = row, BackgroundTransparency = 1, Text = "",
        Size = UDim2.fromScale(1, 1), AutoButtonColor = false,
    })

    local element = { Value = cfg.Default and true or false, Callbacks = {} }

    local function paint()
        local on = element.Value
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Theme.Accent or Color3.fromRGB(52, 56, 66) }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = on and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(180, 186, 198) }):Play()
    end

    function element:Set(v, silent)
        element.Value = v and true or false
        paint()
        if not silent then
            for _, cb in ipairs(element.Callbacks) do cb(element.Value) end
        end
    end
    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
        cb(element.Value)
    end

    btn.MouseButton1Click:Connect(function() element:Set(not element.Value) end)
    btn.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.RowHover end)
    btn.MouseLeave:Connect(function() row.BackgroundColor3 = Theme.Row end)

    paint()
    return element
end

function Mini.Slider(parent, cfg)
    local row = MakeRow(parent, 44)
    MakeLabel(row, cfg.Text, 12, 220, Theme.Text, Theme.Font, 13)
    local valueLbl = Create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Font = Theme.FontBold,
        Text = tostring(cfg.Default), TextSize = 13, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -70, 0, 5), Size = UDim2.fromOffset(58, 16),
    })
    local track = Create("Frame", {
        Parent = row, BackgroundColor3 = Color3.fromRGB(52, 56, 66),
        BorderSizePixel = 0, Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 5),
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = Create("Frame", {
        Parent = track, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local element = { Value = cfg.Default, Min = cfg.Min, Max = cfg.Max,
                      Rounding = cfg.Rounding or 0, Callbacks = {} }

    local function paint()
        local alpha = 0
        if element.Max > element.Min then
            alpha = (element.Value - element.Min) / (element.Max - element.Min)
        end
        fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
        valueLbl.Text = tostring(element.Value)
    end

    local dragging = false
    local function setFromX(px)
        local rel = math.clamp((px - track.AbsolutePosition.X)
            / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = element.Min + (element.Max - element.Min) * rel
        local step = 10 ^ (-element.Rounding)
        raw = math.floor(raw / step + 0.5) * step
        if element.Rounding == 0 then raw = math.floor(raw + 0.5) end
        raw = math.clamp(raw, element.Min, element.Max)
        if raw ~= element.Value then
            element.Value = raw
            paint()
            for _, cb in ipairs(element.Callbacks) do cb(raw) end
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    function element:Set(v, silent)
        element.Value = math.clamp(v, element.Min, element.Max)
        paint()
        if not silent then
            for _, cb in ipairs(element.Callbacks) do cb(element.Value) end
        end
    end
    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
        cb(element.Value)
    end

    paint()
    return element
end

function Mini.ColorPicker(parent, cfg)
    local row = MakeRow(parent, 38)
    MakeLabel(row, cfg.Text, 12, 200, Theme.Text, Theme.Font, 13)
    local swatch = Create("TextButton", {
        Parent = row, BackgroundColor3 = cfg.Default, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "",
        Position = UDim2.new(1, -46, 0.5, -11), Size = UDim2.fromOffset(34, 22),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 5) }, swatch)
    Create("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, swatch)

    local panel = Create("Frame", {
        Parent = parent, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 0), Visible = false, ClipsDescendants = true,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, panel)

    local element = { Value = cfg.Default, Callbacks = {} }
    local r = cfg.Default.R * 255
    local g = cfg.Default.G * 255
    local b = cfg.Default.B * 255

    local function apply(silent)
        element.Value = Color3.fromRGB(r, g, b)
        swatch.BackgroundColor3 = element.Value
        if not silent then
            for _, cb in ipairs(element.Callbacks) do cb(element.Value) end
        end
    end

    local function channel(text, order, get, set)
        local r2 = MakeRow(panel, 36)
        r2.LayoutOrder = order
        r2.BackgroundTransparency = 1
        MakeLabel(r2, text, 10, 16, Theme.SubText, Theme.FontBold, 12)
        local t = Create("Frame", {
            Parent = r2, BackgroundColor3 = Color3.fromRGB(52, 56, 66),
            BorderSizePixel = 0, Position = UDim2.new(0, 30, 0, 16),
            Size = UDim2.new(1, -60, 0, 5),
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, t)
        local f = Create("Frame", {
            Parent = t, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            Size = UDim2.fromScale(get() / 255, 1),
        })
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        local v = Create("TextLabel", {
            Parent = r2, BackgroundTransparency = 1, Font = Theme.Font,
            Text = tostring(get()), TextSize = 11, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Position = UDim2.new(1, -50, 0, 3), Size = UDim2.fromOffset(40, 14),
        })

        local function paintCh()
            f.Size = UDim2.fromScale(get() / 255, 1)
            v.Text = tostring(get())
        end

        local drag = false
        local function fromX(px)
            local rel = math.clamp((px - t.AbsolutePosition.X)
                / math.max(t.AbsoluteSize.X, 1), 0, 1)
            local nv = math.floor(rel * 255 + 0.5)
            if nv ~= get() then
                set(nv)
                paintCh()
                apply()
            end
        end
        t.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                drag = true
                fromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                fromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end)
    end

    Create("UIListLayout", {
        Parent = panel, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent = panel, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    })
    channel("R", 1, function() return r end, function(v2) r = v2 end)
    channel("G", 2, function() return g end, function(v2) g = v2 end)
    channel("B", 3, function() return b end, function(v2) b = v2 end)

    swatch.MouseButton1Click:Connect(function()
        if panel.Visible then
            TweenService:Create(panel, TweenInfo.new(0.18),
                { Size = UDim2.new(1, -10, 0, 0) }):Play()
            task.delay(0.19, function() panel.Visible = false end)
        else
            panel.Visible = true
            TweenService:Create(panel, TweenInfo.new(0.18),
                { Size = UDim2.new(1, -10, 0, 126) }):Play()
        end
    end)

    function element:Set(c, silent)
        r, g, b = c.R * 255, c.G * 255, c.B * 255
        apply(silent)
    end
    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
        cb(element.Value)
    end

    swatch.BackgroundColor3 = cfg.Default
    return element
end

function Mini.Button(parent, cfg)
    local row = MakeRow(parent, 34)
    local btn = Create("TextButton", {
        Parent = row, BackgroundColor3 = Color3.fromRGB(30, 62, 78),
        BorderSizePixel = 0, AutoButtonColor = false, Font = Theme.FontBold,
        Text = cfg.Text, TextSize = 13, TextColor3 = Theme.Accent,
        Size = UDim2.fromScale(1, 1),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    local element = { Callbacks = {} }
    btn.MouseButton1Click:Connect(function()
        for _, cb in ipairs(element.Callbacks) do cb() end
    end)
    function element:OnClick(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
    end
    return element
end

function Mini.Label(parent, text, color)
    local row = MakeRow(parent, 30)
    row.BackgroundTransparency = 1
    local lbl = MakeLabel(row, text, 4, 600, color or Theme.SubText, Theme.Font, 11)
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.TextWrapped = true
    return lbl
end

function Mini.Divider(parent)
    local d = Create("Frame", {
        Parent = parent, BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 1),
    })
    return d
end

-- 单选下拉（原版 ESPTextFont / ESPTracersOrigin 用）
function Mini.Dropdown(parent, cfg)
    local values = cfg.Values
    local openH = 34 + math.min(#values, 8) * 21
    local holder = Create("Frame", {
        Parent = parent, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 34), ClipsDescendants = true,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, holder)

    local header = Create("TextButton", {
        Parent = holder, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 34),
    })
    MakeLabel(header, cfg.Text, 12, 200, Theme.Text, Theme.Font, 13)
    local cur = Create("TextLabel", {
        Parent = header, BackgroundTransparency = 1, Font = Theme.Font,
        Text = "", TextSize = 11, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -150, 0, 0), Size = UDim2.fromOffset(138, 34),
    })

    local list = Create("ScrollingFrame", {
        Parent = holder, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, openH - 34),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {
        Parent = list, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local element = { Value = values[cfg.Default or 1], Callbacks = {} }
    local items = {}

    local function paintSelection()
        for name, item in pairs(items) do
            item.BackgroundColor3 = (name == element.Value) and Color3.fromRGB(30, 62, 78)
                or Theme.Row
        end
        cur.Text = tostring(element.Value)
    end

    for i, name in ipairs(values) do
        local item = Create("TextButton", {
            Parent = list, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = i,
        })
        MakeLabel(item, name, 10, 300, Theme.Text, Theme.Font, 12)
        items[name] = item
        item.MouseButton1Click:Connect(function()
            element.Value = name
            paintSelection()
            for _, cb in ipairs(element.Callbacks) do cb(element.Value) end
        end)
    end

    local open = false
    header.MouseButton1Click:Connect(function()
        open = not open
        TweenService:Create(holder, TweenInfo.new(0.2),
            { Size = open and UDim2.new(1, -10, 0, openH) or UDim2.new(1, -10, 0, 34) }):Play()
    end)

    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
        cb(element.Value)
    end

    paintSelection()
    return element
end

-- 多选下拉（原版 Entity List 用，AllowNull 语义 = 默认一个都不选）
function Mini.MultiSelect(parent, cfg)
    local entries = cfg.Values
    local openH = 34 + math.min(#entries, 8) * 22
    local holder = Create("Frame", {
        Parent = parent, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 34), ClipsDescendants = true,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, holder)

    local header = Create("TextButton", {
        Parent = holder, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 34),
    })
    MakeLabel(header, cfg.Text, 12, 220, Theme.Text, Theme.Font, 13)
    local count = Create("TextLabel", {
        Parent = header, BackgroundTransparency = 1, Font = Theme.Font,
        Text = "", TextSize = 11, TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -110, 0, 0), Size = UDim2.fromOffset(100, 34),
    })

    local list = Create("ScrollingFrame", {
        Parent = holder, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, openH - 34),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {
        Parent = list, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local element = { Selected = {}, Callbacks = {} }
    for _, v in ipairs(entries) do
        element.Selected[v] = (cfg.Default ~= nil) and cfg.Default[v] == true or false
    end

    local boxes = {}

    local function updateCount()
        local n = 0
        for _, v in pairs(element.Selected) do
            if v then n = n + 1 end
        end
        count.Text = "已选 " .. n
    end

    local function fire()
        for _, cb in ipairs(element.Callbacks) do cb(element.Selected) end
    end

    for i, name in ipairs(entries) do
        local item = Create("TextButton", {
            Parent = list, BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 21),
            LayoutOrder = i,
        })
        MakeLabel(item, name, 10, 240, Theme.Text, Theme.Font, 12)
        local box = Create("Frame", {
            Parent = item, BackgroundColor3 = Color3.fromRGB(52, 56, 66),
            BorderSizePixel = 0, Position = UDim2.new(1, -26, 0.5, -7),
            Size = UDim2.fromOffset(14, 14),
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
        boxes[name] = box

        local function paintItem()
            local on = element.Selected[name] == true
            box.BackgroundColor3 = on and Theme.Accent or Color3.fromRGB(52, 56, 66)
        end
        paintItem()

        item.MouseButton1Click:Connect(function()
            element.Selected[name] = not (element.Selected[name] == true)
            paintItem()
            updateCount()
            fire()
        end)
    end

    local open = false
    header.MouseButton1Click:Connect(function()
        open = not open
        TweenService:Create(holder, TweenInfo.new(0.2),
            { Size = open and UDim2.new(1, -10, 0, openH) or UDim2.new(1, -10, 0, 34) }):Play()
    end)

    -- 原版下拉用 Options.X.Value[...] 判断选中，这里让 .Value 指向 Selected
    element.Value = element.Selected

    updateCount()

    function element:SetAll(v)
        for k in pairs(element.Selected) do
            element.Selected[k] = v
            boxes[k].BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(52, 56, 66)
        end
        updateCount()
        fire()
    end
    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
        cb(element.Selected)
    end

    return element
end

function Mini.Keybind(parent, cfg)
    local row = MakeRow(parent, 34)
    MakeLabel(row, cfg.Text, 12, 200, Theme.Text, Theme.Font, 13)
    local btn = Create("TextButton", {
        Parent = row, BackgroundColor3 = Color3.fromRGB(52, 56, 66),
        BorderSizePixel = 0, AutoButtonColor = false, Font = Theme.FontBold,
        Text = tostring(cfg.Default and cfg.Default.Name or "?"), TextSize = 12,
        TextColor3 = Theme.Text,
        Position = UDim2.new(1, -84, 0.5, -11), Size = UDim2.fromOffset(72, 22),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

    local element = { Key = cfg.Default, Callbacks = {} }
    local capturing = false
    btn.MouseButton1Click:Connect(function()
        capturing = true
        btn.Text = "按键…"
    end)
    UserInputService.InputBegan:Connect(function(input)
        if not capturing then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            element.Key = input.KeyCode
            btn.Text = input.KeyCode.Name
            capturing = false
        end
    end)
    function element:OnChanged(cb)
        element.Callbacks[#element.Callbacks + 1] = cb
    end
    return element
end

--=====================================================================
-- 2. 原版数据表（照抄 Main.luau，一个字没改）
--=====================================================================

-- 原版 Entities / EntityESPLabels / NodeEntities（照抄 Main.luau，NotifyMessage 不搬）
local PortraitName = "MirrorRig_Portrait_" .. LocalPlayer.Name

local Entities = {
    ["TV_Stand"]         = { Alias = "Noise_TV" },
    [PortraitName]       = { Alias = "Portrait" },
    ["StemsEntity"]      = { Alias = "Balls" },
    ["NoiseModel"]       = { Alias = "Noise" },
    ["Creak"]            = { Alias = "Creak" },
    ["DronesStampede"]   = { Alias = "DronesStampede" },
    ["TellerRig"]        = { Alias = "Teller" },
    ["Scribbles"]        = { Alias = "Scribbles" },
    ["BashMoving"]       = { Alias = "Bash" },
    ["RushMoving"]       = { Alias = "Rush" },
    ["AmbushMoving"]     = { Alias = "Ambush" },
    ["Eyes"]             = { Alias = "Eyes" },
    ["Lookman"]          = { Alias = "Eyes" },
    ["BackdoorRush"]     = { Alias = "Blitz" },
    ["BackdoorLookman"]  = { Alias = "Lookman" },
    ["Groundskeeper"]    = { Alias = "Groundskeeper" },
    ["A60"]              = { Alias = "A-60" },
    ["A120"]             = { Alias = "A-120" },
    ["GloombatSwarm"]    = { Alias = "Gloombat Swarm" },
    ["GlitchRush"]       = { Alias = "RNIUSHCG==" },
    ["GlitchAmbush"]     = { Alias = "AR0xMBUSH" },
    ["MonumentEntity"]   = { Alias = "Monument" },
    ["JeffTheKiller"]    = { Alias = "Jeff the Killer" },
    ["CustomEntity"]     = { Alias = "Custom Entity" },
    ["FrozenAmbush"]     = { Alias = "Frozen Ambush" },
    ["SallyMoving"]      = { Alias = "Sally" },
}


local EntityESPLabels = {
    JeffTheKiller = "Jeff the Killer",
    GiggleCeiling = "Giggle",
    Snare = "Snare",
    GrumbleRig = "Grumble",
    Drakobloxxer = "Drakobloxxer",
    Hole = "Mandrake Hole",
    Groundskeeper = "Groundskeeper",
    LiveEntityBramble = "Bramble",
    Figure = "Figure", FigureRig = "Figure", FigureRagdoll = "Figure",
    FakeDoor = "Dupe", DoorFake = "Dupe",
}

local NodeEntities = {
    Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true,
    Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true,
    Sally = true, ["Jeff The Killer"] = true, Monument = true,
    ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true,
}

local RusherAliases = {
    Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true,
    Eyes = true, Lookman = true, Blitz = true, ["A-60"] = true, ["A-120"] = true,
    AR0xMBUSH = true, ["RNIUSHCG=="] = true, ["Custom Entity"] = true,
}

-- 原版 ItemNames
local ItemNames = {
    ["AbrahamHat"] = "Hat",
    ["LargeScrew"] = "Screw",
    ["DinkyLamp"] = "Lamp",
    ["BottleCrate"] = "18+ Bottles",
    ["GweenSodaPack"] = "Gween Soda Pack",
    ["BrokenMonitor"] = "Broken Monitor",
    ["JerryCan"] = "Jerry Can",
    ["SallyToyObtain"] = "Sally Toy",
    ["Leftovers"] = "Lunch Box",
    ["HoneyPot"] = "Honey Pot",
    ["FihFlakes"] = "Fih Food",
    ["SecretCD"] = "CD Disc",
    ["Pizza"] = "Pizza",
    ["PaperPlanePickup"] = "Paper Plane",
    ["Lighter"] = "Lighter",
    ["Flashlight"] = "Flashlight",
    ["Lockpick"] = "Lockpicks",
    ["Vitamins"] = "Vitamins",
    ["Bandage"] = "Bandage",
    ["StarVial"] = "Starlight Vial",
    ["StarBottle"] = "Starlight Bottle",
    ["StarJug"] = "Starlight Barrel",
    ["Shakelight"] = "Gummy Flashlight",
    ["Straplight"] = "Straplight",
    ["Bulklight"] = "Spotlight",
    ["Battery"] = "Battery",
    ["Candle"] = "Candle",
    ["Crucifix"] = "Crucifix",
    ["CrucifixWall"] = "Crucifix",
    ["Glowsticks"] = "Glowstick",
    ["SkeletonKey"] = "Skeleton Key",
    ["Candy"] = "Candy",
    ["ShieldMini"] = "Mini Shield Potion",
    ["ShieldBig"] = "Big Shield Potion",
    ["BandagePack"] = "Bandage Pack",
    ["BatteryPack"] = "Battery Pack",
    ["RiftCandle"] = "Moonlight Candle",
    ["LaserPointer"] = "Laser Pointer",
    ["HolyGrenade"] = "Holy Hand Grenade",
    ["Shears"] = "Shears",
    ["Smoothie"] = "Smoothie",
    ["Cheese"] = "Cheese",
    ["Bread"] = "Bread",
    ["AlarmClock"] = "Alarm Clock",
    ["RiftSmoothie"] = "Moonlight Smoothie",
    ["GweenSoda"] = "Gween Soda",
    ["GlitchCube"] = "Glitch Fragment",
    ["Scanner"] = "Tablet",
    ["Bomb"] = "Bomb",
    ["Knockbomb"] = "Knockbomb",
    ["Nanner"] = "Nanner",
    ["BigBomb"] = "Big Bomb",
    ["SnakeBox"] = "Hiding Box",
    ["GoldGun"] = "Golden Gun",
    ["StopSign"] = "Stop Sign",
    ["TipJar"] = "Tip Jar",
    ["Lantern"] = "Lantern",
    ["IronKey"] = "Iron Key",
    ["LotusPetal"] = "Lotus Petal",
    ["Compass"] = "Compass",
    ["LotusPetalPickup"] = "Lotus Petal",
    ["LanternLitItem"] = "Lantern",
    ["KeyIron"] = "Iron Key",
    ["IronKeyForCrypt"] = "Iron Key",
    ["LotusHolder"] = "Lotus Petal",
    ["Multitool"] = "Multitool",
    ["RiftJar"] = "Rift Jar",
    ["AloeVera"] = "Aloe Vera",
    ["Donut"] = "Donut",
    ["Lotus"] = "Lotus",
    ["BoxingGloves"] = "Boxing Gloves",
}

-- 原版 HidingSpotLabels / ChestLabels / ObjectiveLabels / MiscLabels
local HidingSpotLabels = {
    Wardrobe = "Closet", ["Backdoor_Wardrobe"] = "Closet", Toolshed = "Closet",
    RetroWardrobe = "Closet", ["Wardrobe-FOOLS26"] = "Closet",
    Locker_Large = "Locker", Rooms_Locker = "Hiding_Spot", Rooms_Locker_Fridge = "Locker",
    Bed = "Bed", Double_Bed = "Double Bed", CircularVent = "Vent", Dumpster = "Dumpster",
}

local ChestLabels = {
    ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
    Chest_Vine = "Vine Chest", Toolshed_Small = "Toolshed",
    Locker_Small_Locked = "Locked Item Locker", MouseHole = "Mouse",
}

local ObjectiveLabels = {
    ["KeyObtain"] = "Door Key",
    ["ElectricalKeyObtain"] = "Electrical Key",
    ["LiveHintBook"] = "Hint Book",
    ["LiveBreakerPolePickup"] = "Fuse Breaker",
    ["LibraryHintPaper"] = "Hint Paper",
    ["PickupItem"] = "Hint Paper",
    ["CringlePresent"] = "Present",
    ["LeverForGate"] = "Gate Lever",
    ["StairwellScrapper"] = "Scrapper",
    ["ArchivesPackageDeposit"] = "Package Deposit",
    ["Cellar"] = "Cellar",
    ["MinesGenerator"] = "Generator",
    ["FuseObtain"] = "Generator Fuse",
    ["MinesGateButton"] = "Gate Button",
    ["GardenGateButton"] = "Gate Button",
}

local MiscLabels = {
    ["StairwellLockpickDoor"] = "Garage Door",
    ["StiarwellLockpickDoor"] = "Garage Door",
    ["Mirror"] = "Mirror",
    ["StairwellFireAlarm"] = "Fire Alarm",
    ["ShoppingCart"] = "Shopping Cart",
    ["ArchivesFihTank"] = "Fih Tank",
    ["ArchivesFishTank"] = "Fih Tank",
}

-- 原版 Entity List 下拉项
local EntityListValues = {
    "Rush", "Bash", "Scribbles", "Teller", "DronesStampede", "Creak", "Noise",
    "Noise_TV", "Balls", "Portrait", "Ambush", "Eyes", "Dupe", "Figure",
    "Blitz", "Lookman", "Snare", "Giggle", "Gloombat Eggs", "Grumble",
    "A-60", "A-120", "Sally", "Jeff the Killer", "Groundskeeper",
    "Mandrake Hole", "Monument", "Bramble", "AR0xMBUSH", "RNIUSHCG==",
}

local FontValues = {
    "Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansLight",
    "SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi",
    "Arcade", "Fantasy", "Antique", "SourceSansSemibold", "Gotham", "GothamMedium",
    "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster", "DenkOne",
    "Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura",
    "Kalam", "LuckiestGuy", "Merriweather", "Michroma", "Nunito", "Oswald",
    "PatrickHand", "PermanentMarker", "Roboto", "RobotoCondensed", "RobotoMono",
    "Sarpanch", "SpecialElite", "TitilliumWeb", "Ubuntu", "BuilderSans",
    "BuilderSansMedium", "BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold",
}

-- 原版 AllowedInstances
local AllowedInstances = {
    Lava = true, GoldPile = true, KeyObtain = true, Drakobloxxer = true, FuseObtain = true,
    MinesGenerator = true, JeffTheKiller = true, Snare = true, FakeDoor = true,
    DoorFake = true, SideroomSpace = true, ChestBox = true, ChestBoxLocked = true,
    Chest_Vine = true, Locker_Small_Locked = true, Toolbox = true, Toolbox_Locked = true,
    Wardrobe = true, ["Wardrobe-FOOLS26"] = true, Toolshed = true, Toolshed_Small = true,
    Bed = true, MinesAnchor = true, Double_Bed = true, RetroWardrobe = true,
    Backdoor_Wardrobe = true, Rooms_Locker = true, Rooms_Locker_Fridge = true,
    Locker_Large = true, FigureRig = true, FigureRagdoll = true, TimerlLever = true,
    Lever = true, Seek_Arm = true, ChandelierObstruction = true, ScaryWall = true,
    Ladder = true, CircularVent = true, Dumpster = true, SquareGrate = true,
    TriggerEventCollision = true, GrumbleRig = true, GiggleCeiling = true,
    MinesGateButton = true, ElectricalKeyObtain = true, LibraryHintPaper = true,
    WaterPump = true, CringlePresent = true, Wheel = true, PickupItem = true,
    LiveHintBook = true, LiveBreakerPolePickup = true, LeverForGate = true,
    GloomPile = true, SeekFloodline = true, Door = true, Green_Herb = true, Bridge = true,
    MouseHole = true, BananaPeel = true, NannerPeel = true, PowerupPad = true,
    IndustrialGate = true, CollisionFloor = true, ElevatorCar = true, Wax_Door = true,
    ThingToOpen = true, MovingDoor = true, StardustPickup = true, Hole = true,
    Groundskeeper = true, MandrakeLive = true, GardenGateButton = true,
    LotusPetalPickup = true, VineGuillotine = true, LiveEntityBramble = true,
    ArchivesFihTank = true, RiftSpawn = true, ElevatorBreaker = true, RunnerNodes = true,
    PathLights = true, DuckBoard = true, Padlock = true, EyestalkEndCutscene = true,
    MinecartRig = true, SeekMovingNewClone = true, Cellar = true,
    ArchivesPackageDeposit = true, StairwellScrapper = true, StairwellFireAlarm = true,
    ShoppingCart = true, Mirror = true, StairwellLockpickDoor = true,
}
AllowedInstances.TimerLever = true
AllowedInstances.Figure = true

-- 原版 CutsceneNames（这些不参与实体 ESP）
local CutsceneNames = {
    "Figure", "FigureEnd", "FigureHotelEnd", "FigureHotelFire",
    "SeekIntroFools", "SeekIntroHotel", "SeekIntroMines", "SeekIntroMines2",
    "SerewSeekDrain", "SewerSeekLower", "GrumbleNestEnd", "EyestalkIntro",
}

--=====================================================================
-- 3. 原版 Components/ESP.luau —— 原文内联，逐字节未改
--=====================================================================
local ESPLibrary = (function()
local Library = {
	Font = Enum.Font.RobotoCondensed,
	Rainbow = false,
	Tracers = false,
	Unloaded = false,
	ShowDistance = false,
	MatchColors = true,
	Arrows = false,
	TextTransparency = 0,
	TracerOrigin = "Bottom",
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	TextOutlineTransparency = 0,
	FadeTime = 0,
	RenderLimit = 240,
	TracerSize = 0.5,
	ArrowRadius = 200,
	TextSize = 20,
	DistanceSizeRatio = 1,
	OutlineColor = Color3.fromRGB(255, 255, 255),
	RainbowColor = Color3.fromRGB(255, 255, 255),

	ElementsEnabled = {},
	TransparencyEnabled = {},
	Highlights = {},
	Labels = {},
	Frames = {},
	Lines = {},
	ArrowsTable = {},
	ColorTable = {},
	TextTable = {},
	ConnectionsTable = {},
	Objects = {},
	TotalObjects = {},
}

local RainbowState = {
	HueSetup = 0,
	Hue = 0,
	Step = 0,
	Color = Color3.new(),
}

local CloneReference = cloneref or function(O) return O end
local Players = CloneReference(game:GetService("Players"))
local CoreGui = getgenv and CloneReference(game:GetService("CoreGui")) or Players.LocalPlayer.PlayerGui
local Workspace = CloneReference(workspace)
local RunService = CloneReference(game:GetService("RunService"))
local TweenService = CloneReference(game:GetService("TweenService"))
local UserInputService = CloneReference(game:GetService("UserInputService"))
local Debris = CloneReference(game:GetService("Debris"))
local LocalPlayer = Players.LocalPlayer

local function GetHiddenUI()
	if gethui then return gethui() end
	local Folder = Instance.new("Folder", CoreGui)
	Folder.Name = ("%032x"):format(math.random(0, 2^31))
	return Folder
end

function Library:GenerateRandomString()
	local Chars = {}
	local Pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local PoolLen = #Pool
	for I = 1, 24 do
		local Idx = math.random(1, PoolLen)
		Chars[I] = Pool:sub(Idx, Idx)
	end
	return table.concat(Chars)
end

local HiddenUI = GetHiddenUI()
local Camera = Workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = Library:GenerateRandomString()
ScreenGui.Parent = HiddenUI

local HighlightsFolder = Instance.new("Folder")
HighlightsFolder.Name = Library:GenerateRandomString()
HighlightsFolder.Parent = ScreenGui

local BillboardsFolder = Instance.new("Folder")
BillboardsFolder.Name = Library:GenerateRandomString()
BillboardsFolder.Parent = ScreenGui

local TracersFrame = Instance.new("Frame")
TracersFrame.Size = UDim2.new(1, 0, 1, 0)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Visible = false
TracersFrame.Name = Library:GenerateRandomString()
TracersFrame.Parent = ScreenGui

local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Visible = false
ArrowsFrame.Name = Library:GenerateRandomString()
ArrowsFrame.Parent = ScreenGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://16368985219"
ArrowTemplate.Size = UDim2.new(0, 50, 0, 50)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 1
local ArrowConstraint = Instance.new("UIAspectRatioConstraint")
ArrowConstraint.AspectRatio = 1
ArrowConstraint.Name = Library:GenerateRandomString()
ArrowConstraint.Parent = ArrowTemplate

local TweenInfoQuad = TweenInfo.new(0, Enum.EasingStyle.Quad)
local function MakeTween(Instance_, Props)
	local Info = TweenInfo.new(Library.FadeTime, Enum.EasingStyle.Quad)
	return TweenService:Create(Instance_, Info, Props)
end

local function PlayTween(Instance_, Props)
	MakeTween(Instance_, Props):Play()
end

local function DestroyObjectData(Object)
	local Highlight = Library.Highlights[Object]
	if Highlight then
		Highlight:Destroy()
		Library.Highlights[Object] = nil
	end

	local Frame = Library.Frames[Object]
	if Frame then
		Frame:Destroy()
		Library.Frames[Object] = nil
	end

	local LineData = Library.Lines[Object]
	if LineData then
		if LineData[1] then LineData[1]:Destroy() end
		Library.Lines[Object] = nil
	end

	local Arrow = Library.ArrowsTable[Object]
	if Arrow then
		Arrow:Destroy()
		Library.ArrowsTable[Object] = nil
	end

	local Conns = Library.ConnectionsTable[Object]
	if Conns then
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
		Library.ConnectionsTable[Object] = nil
	end

	Library.Labels[Object] = nil
	Library.ColorTable[Object] = nil
	Library.TextTable[Object] = nil
	Library.ElementsEnabled[Object] = nil
	Library.TransparencyEnabled[Object] = nil
	Library.Objects[Object] = nil

	for Idx = #Library.TotalObjects, 1, -1 do
		if Library.TotalObjects[Idx] == Object then
			table.remove(Library.TotalObjects, Idx)
			break
		end
	end
end

function Library:AddESP(Parameters)
	local Object = Parameters.Object
	if Library.ElementsEnabled[Object] == true or Library.Unloaded == true then return end
	if not Object:IsA("BasePart") and not Object:IsA("Model") then return end

	Library.ElementsEnabled[Object] = true
	Library.TransparencyEnabled[Object] = false
	Library.ConnectionsTable[Object] = Library.ConnectionsTable[Object] or {}

	if Library.Highlights[Object] then
		Library.Highlights[Object]:Destroy()
		Library.Highlights[Object] = nil
	end

	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.Name = Library:GenerateRandomString()
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Adornee = Object
	Highlight.Parent = HighlightsFolder
	Library.Highlights[Object] = Highlight

	local TextFrame = Instance.new("Frame")
	TextFrame.Visible = false
	TextFrame.Name = Library:GenerateRandomString()
	TextFrame.Size = UDim2.fromScale(1, 1)
	TextFrame.BackgroundTransparency = 1
	TextFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	TextFrame.Parent = BillboardsFolder

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = Library:GenerateRandomString()
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = Parameters.Text
	TextLabel.TextTransparency = 1
	TextLabel.TextStrokeTransparency = Library.TextOutlineTransparency
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.Font = Library.Font
	TextLabel.TextSize = Library.TextSize
	TextLabel.RichText = true
	TextLabel.TextColor3 = Parameters.Color
	TextLabel.Parent = TextFrame

	Library.Frames[Object] = TextFrame
	Library.Labels[Object] = TextLabel
	Library.ColorTable[Object] = Parameters.Color
	Library.TextTable[Object] = Parameters.Text
	Library.Objects[Object] = Object
	table.insert(Library.TotalObjects, Object)

	PlayTween(Highlight, { FillTransparency = Library.FillTransparency })
	PlayTween(Highlight, { OutlineTransparency = Library.OutlineTransparency })

	local TextFadeIn = MakeTween(TextLabel, { TextTransparency = Library.TextTransparency })
	TextFadeIn.Completed:Once(function()
		Library.TransparencyEnabled[Object] = true
	end)
	TextFadeIn:Play()
	PlayTween(TextLabel, { TextStrokeTransparency = Library.TextOutlineTransparency })

	local LineFrame = Instance.new("Frame")
	LineFrame.Size = UDim2.new(0, 0, 0, 0)
	LineFrame.BackgroundTransparency = 1
	LineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LineFrame.Name = Library:GenerateRandomString()
	LineFrame.Parent = TracersFrame

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = Library.TracerSize
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Transparency = 1
	Stroke.Name = Library:GenerateRandomString()
	Stroke.Parent = LineFrame

	PlayTween(LineFrame, { BackgroundTransparency = 0 })
	PlayTween(Stroke, { Transparency = 0 })
	Library.Lines[Object] = { LineFrame, Stroke }

	task.spawn(function()
		local Last = 0
		local MinInterval = 1 / Library.RenderLimit

		local function Render()
			if not Object or not Object:IsDescendantOf(game) then
				Library:RemoveESP(Object)
				return
			end

			local ObjectPos = Object:GetPivot().Position
			local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(ObjectPos)

			local Frame = Library.Frames[Object]
			local Label = Library.Labels[Object]
			local CachedHighlight = Library.Highlights[Object]
			local LineData = Library.Lines[Object]

			if LineData and LineData[1] then
				LineData[1].Visible = OnScreen
			end

			if Frame then
				Frame.Visible = OnScreen
				if OnScreen then
					Frame.Position = UDim2.new(0, ScreenPoint.X, 0, ScreenPoint.Y)
				end
			end

			if not OnScreen then
				if CachedHighlight then
					CachedHighlight:Destroy()
					Library.Highlights[Object] = nil
					CachedHighlight = nil
				end
			elseif Library.ElementsEnabled[Object] == true and not CachedHighlight then
				CachedHighlight = Instance.new("Highlight")
				CachedHighlight.FillTransparency = 1
				CachedHighlight.OutlineTransparency = 1
				CachedHighlight.Name = Library:GenerateRandomString()
				CachedHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				CachedHighlight.Adornee = Object
				CachedHighlight.Parent = HighlightsFolder
				Library.Highlights[Object] = CachedHighlight
			end

			local ActiveColor = Library.Rainbow and RainbowState.Color or Library.ColorTable[Object] or Color3.fromRGB(255, 255, 255)

			if Label then
				Label.TextColor3 = ActiveColor
			end

			if CachedHighlight then
				local Distance = math.floor((Camera.CFrame.Position - ObjectPos).Magnitude)
				local DistanceText = Library.ShowDistance
					and ("\n" .. '<font size="' .. math.round(Library.TextSize * Library.DistanceSizeRatio) .. '">[' .. Distance .. ']</font>')
					or ""
				if Label then
					Label.Text = Library.TextTable[Object] .. DistanceText
				end

				CachedHighlight.Enabled = true
				CachedHighlight.FillColor = ActiveColor
				CachedHighlight.OutlineColor = Library.MatchColors and ActiveColor or Library.OutlineColor

				if Library.TransparencyEnabled[Object] == true then
					CachedHighlight.FillTransparency = Library.FillTransparency
					CachedHighlight.OutlineTransparency = Library.OutlineTransparency
					if Label then
						Label.TextTransparency = Library.TextTransparency
						Label.TextStrokeTransparency = Library.TextOutlineTransparency
					end
				end
			end

			if LineData and CachedHighlight and Library.Tracers == true and OnScreen then
				local ScreenSize = Camera.ViewportSize
				local Origin

				if Library.TracerOrigin == "Center" then
					Origin = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
				elseif Library.TracerOrigin == "Top" then
					Origin = Vector2.new(ScreenSize.X / 2, 0)
				elseif Library.TracerOrigin == "Mouse" then
					local MouseLoc = UserInputService:GetMouseLocation()
					Origin = Vector2.new(LocalPlayer:GetMouse().X, MouseLoc.Y)
				else
					Origin = Vector2.new(ScreenSize.X / 2, ScreenSize.Y)
				end

				local Destination = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
				local MidPoint = (Origin + Destination) / 2
				local Rotation = math.deg(math.atan2(Destination.Y - Origin.Y, Destination.X - Origin.X))
				local Length = (Origin - Destination).Magnitude
				local LF = LineData[1]
				local SK = LineData[2]

				LF.Position = UDim2.new(0, MidPoint.X, 0, MidPoint.Y)
				LF.Size = UDim2.new(0, Length, 0, 1)
				LF.Rotation = Rotation
				LF.BackgroundColor3 = ActiveColor
				LF.BorderSizePixel = 0
				LF.Visible = true
				SK.Color = ActiveColor
				SK.Thickness = Library.TracerSize
			end

			if Library.Arrows == true then
				local Arrow = Library.ArrowsTable[Object]
				if Arrow == nil and Library.ElementsEnabled[Object] == true then
					Arrow = ArrowTemplate:Clone()
					Arrow.Name = Library:GenerateRandomString()
					Arrow:WaitForChild(ArrowConstraint.Name, 5)
					Arrow.Parent = ArrowsFrame
					Library.ArrowsTable[Object] = Arrow
					PlayTween(Arrow, { ImageTransparency = 0 })
				elseif Arrow and Library.ElementsEnabled[Object] == true then
					if OnScreen and ScreenPoint.Z > 0 then
						Arrow.Visible = false
					else
						local ScreenSize = Camera.ViewportSize
						local ScreenCenter = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
						local ToObj = (ObjectPos - Camera.CFrame.Position).Unit
						local Dir = Vector2.new(ScreenPoint.X, ScreenPoint.Y) - ScreenCenter
						if Camera.CFrame.LookVector:Dot(ToObj) < 0 then
							Dir = -Dir
						end
						local Angle = math.atan2(Dir.Y, Dir.X)
						local Radius = math.min(ScreenSize.X, ScreenSize.Y) / 2 - (400 - Library.ArrowRadius)
						local ArrowPos = ScreenCenter + Dir.Unit * Radius

						Arrow.Position = UDim2.new(0, ArrowPos.X, 0, ArrowPos.Y)
						Arrow.Rotation = math.deg(Angle) - 90
						Arrow.Visible = true
						Arrow.ImageColor3 = Library.Rainbow and Library.RainbowColor or Library.ColorTable[Object]
					end
				end
			end
		end

		local Connection
		Connection = RunService.Heartbeat:Connect(function(Delta)
			Last = Last + Delta
			if Last >= 1 / Library.RenderLimit then
				Last = 0
				if Library.ElementsEnabled[Object] ~= true then
					Connection:Disconnect()
					return
				end
				Render()
			end
		end)
		table.insert(Library.ConnectionsTable[Object], Connection)
	end)
end

function Library:RemoveESP(Object)
	if Library.Unloaded == true or Library.ElementsEnabled[Object] ~= true then return end
	Library.ElementsEnabled[Object] = false
	Library.TransparencyEnabled[Object] = false

	local Label = Library.Labels[Object]
	if Label then
		PlayTween(Label, { TextTransparency = 1 })
	end

	local LineData = Library.Lines[Object]
	if LineData then
		if LineData[1] then PlayTween(LineData[1], { BackgroundTransparency = 1 }) end
		if LineData[2] then PlayTween(LineData[2], { Transparency = 1 }) end
	end

	local Highlight = Library.Highlights[Object]
	if Highlight then
		PlayTween(Highlight, { FillTransparency = 1 })
		PlayTween(Highlight, { OutlineTransparency = 1 })
	end

	local Arrow = Library.ArrowsTable[Object]
	if Arrow then
		PlayTween(Arrow, { ImageTransparency = 1 })
	end

	local FadeTime = Library.FadeTime

	if not Object.Parent then
		task.delay(FadeTime + 0.05, function()
			if Library.ElementsEnabled[Object] == false then
				DestroyObjectData(Object)
			end
		end)
	else
		task.delay(FadeTime + 0.05, function()
			if Library.ElementsEnabled[Object] == false then
				DestroyObjectData(Object)
			else
				local ReHighlight = Library.Highlights[Object]
				if ReHighlight then
					PlayTween(ReHighlight, { FillTransparency = Library.FillTransparency })
					PlayTween(ReHighlight, { OutlineTransparency = Library.OutlineTransparency })
				end
			end
		end)
	end
end

function Library:UpdateObjectText(Object, Text)
	if Library.TextTable[Object] ~= nil then
		Library.TextTable[Object] = Text
	end
end

function Library:UpdateObjectColor(Object, Color)
	Library.ColorTable[Object] = Color
	if Library.Labels[Object] and Library.Rainbow ~= true then
		Library.Labels[Object].TextColor3 = Color
	end
end

function Library:SetColorTable(Name, Color)
	Library.ColorTable[Name] = Color
end

function Library:SetFadeTime(Number)
	Library.FadeTime = Number
end

function Library:SetRenderLimit(Number)
	Library.RenderLimit = Number
end

function Library:SetTextTransparency(Number)
	Library.TextTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextTransparency = Number
	end
end

function Library:SetFillTransparency(Number)
	Library.FillTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.FillTransparency = Number
		end
	end
end

function Library:SetOutlineTransparency(Number)
	Library.OutlineTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.OutlineTransparency = Number
		end
	end
end

function Library:SetTextSize(Number)
	Library.TextSize = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextSize = Number
	end
end

function Library:SetTextOutlineTransparency(Number)
	Library.TextOutlineTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextStrokeTransparency = Number
	end
end

function Library:SetFont(Font)
	Library.Font = Font
	for _, Label in pairs(Library.Labels) do
		Label.Font = Font
	end
end

function Library:SetOutlineColor(Color)
	Library.OutlineColor = Color
end

function Library:SetRainbow(Value)
	Library.Rainbow = Value
end

function Library:SetShowDistance(Value)
	Library.ShowDistance = Value
end

function Library:SetMatchColors(Value)
	Library.MatchColors = Value
end

function Library:SetTracers(Value)
	Library.Tracers = Value
	TracersFrame.Visible = Value
end

function Library:SetArrows(Value)
	Library.Arrows = Value
	ArrowsFrame.Visible = Value
end

function Library:SetArrowRadius(Value)
	Library.ArrowRadius = Value
end

function Library:SetTracerOrigin(Value)
	Library.TracerOrigin = Value
end

function Library:SetDistanceSizeRatio(Value)
	Library.DistanceSizeRatio = Value
end

function Library:SetTracerSize(Value)
	Library.TracerSize = 0.5 * Value
end

function Library:Unload()
	if Library.Unloaded then return end
	Library.Unloaded = true
	for _, Object in pairs(Library.Objects) do
		Library:RemoveESP(Object)
	end
	for _, Conns in pairs(Library.ConnectionsTable) do
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
	end
	RainbowConnection:Disconnect()
	CameraConnection:Disconnect()
	ScreenGui.Enabled = false
end

RainbowConnection = RunService.RenderStepped:Connect(function(Delta)
	RainbowState.Step = RainbowState.Step + Delta
	if RainbowState.Step >= (1 / 60) then
		RainbowState.Step = 0
		RainbowState.HueSetup = RainbowState.HueSetup + (1 / 400)
		if RainbowState.HueSetup > 1 then RainbowState.HueSetup = 0 end
		RainbowState.Hue = RainbowState.HueSetup
		RainbowState.Color = Color3.fromHSV(RainbowState.Hue, 0.8, 1)
		Library.RainbowColor = RainbowState.Color
	end
end)

CameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

if getgenv then
	getgenv().ESPLibrary = Library
end

return Library
end)()

--=====================================================================
-- 4. 原版 Functions / Objects 表 / 扫描队列
--=====================================================================
local Globals = {}
local Connections = {}
local ESPConnections = {}
local ESPBlacklist = {}
local Functions = {}

-- Toggles / Options 必须先声明：Functions.HandleObject 里会引用到它们
local Toggles = {}
local Options = {}

local Objects = {
    Prompts = {}, Objectives = {}, Doors = {}, HidingSpots = {}, Entities = {},
    SeekObstructions = {}, Items = {}, Chests = {}, Currency = {}, Ladders = {},
    Misc = {}, Obstructions = {}, EventTriggers = {}, JumpscareModules = {},
    SeekHighlights = {}, EyestalkHighlights = {}, SeekNodes = {}, SeekDuckBoards = {},
    SeekBridges = {}, PathLights = {}
}

local GameData = ReplicatedStorage:FindFirstChild("GameData")
local Floor = "Unknown"
do
    if GameData then
        local f = GameData:FindFirstChild("Floor")
        if f then Floor = f.Value end
    end
end

getgenv().ESPLibrary = ESPLibrary

Functions.AddESP = function(ESPOptions, RoomBased)
    local Object = ESPOptions.Object

    if table.find(ESPBlacklist, Object) then
        return
    end

    if RoomBased then
        local CurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
        local ObjectRoom = tonumber(Object:GetAttribute("ParentRoom"))

        if ObjectRoom == CurrentRoom
            or (table.find(Objects.Doors, Object) and ObjectRoom == CurrentRoom + 1) then
            ESPLibrary:AddESP(ESPOptions)
        end

        local RoomConnection = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
            if ESPLibrary.ColorTable[Object] then
                ESPOptions.Color = ESPLibrary.ColorTable[Object]
            end

            local NewCurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
            local ObjRoom = tonumber(Object:GetAttribute("ParentRoom"))

            if ObjRoom == NewCurrentRoom
                or (table.find(Objects.Doors, Object) and ObjRoom == NewCurrentRoom + 1) then
                ESPLibrary:AddESP(ESPOptions)
            else
                ESPLibrary:RemoveESP(Object)
            end
        end)

        table.insert(Connections, RoomConnection)
        ESPConnections[Object] = RoomConnection

        Object.Destroying:Once(function()
            RoomConnection:Disconnect()
            ESPLibrary:RemoveESP(Object)
            local Pos = table.find(Connections, RoomConnection)
            if Pos then table.remove(Connections, Pos) end
        end)
    else
        ESPLibrary:AddESP(ESPOptions)
    end
end

Functions.RemoveESP = function(Object)
    local Conn = ESPConnections[Object]
    if Conn then
        Conn:Disconnect()
        ESPConnections[Object] = nil
        local Pos = table.find(Connections, Conn)
        if Pos then table.remove(Connections, Pos) end
    end
    ESPLibrary:RemoveESP(Object)
end

Functions.BlacklistESP = function(Object)
    table.insert(ESPBlacklist, Object)
end

Functions.GetDoorNumber = function(Object)
    local DoorNumber = tonumber(Object.Parent.Name) or tonumber(Object.Parent.Parent.Name)
    if DoorNumber then
        DoorNumber = DoorNumber + 1
    end
    if Floor == "Mines" then
        DoorNumber = DoorNumber + 100
    end
    if Floor == "Backdoor" then
        DoorNumber = DoorNumber - 50
    end
    return tostring(DoorNumber)
end

--─────────────────────────────────────────────────────────────────────
-- 原版 HandleObject —— 只保留 ESP 相关的分支，其余作弊功能没搬
-- 文字串 / 颜色 / RoomBased 参数与原版逐字一致
--─────────────────────────────────────────────────────────────────────
Functions.HandleObject = function(Object)
    local CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")

    if CurrentRooms then
        for _, Room in ipairs(CurrentRooms:GetChildren()) do
            if Object:IsDescendantOf(Room) then
                Object:SetAttribute("ParentRoom", tonumber(Room.Name))
                break
            end
            task.wait()
        end
    end

    local Name = Object.Name

    if Name == "KeyObtain" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Door Key",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "ElectricalKeyObtain" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Electrical Key",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "TimerLever" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                Object:SetAttribute("AddTime",
                    Object.TakeTimer.TextLabel.Text == "01:00" and 60 or 30)
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({
                        Object = Object,
                        Text = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "StairwellLockpickDoor" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Garage Door",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "Mirror" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Mirror",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "StairwellFireAlarm" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fire Alarm",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "ShoppingCart" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Shopping Cart",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "StairwellScrapper" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Scrapper",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "ArchivesPackageDeposit" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Package Deposit",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "Cellar" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Cellar",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "ArchivesFihTank" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fih Tank",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "LiveHintBook" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Hint Book",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LiveBreakerPolePickup" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fuse Breaker",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LibraryHintPaper" or Name == "PickupItem" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Hint Paper",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MinesAnchor" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({
                Object = Object,
                Text = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "WaterPump" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object:WaitForChild("Wheel"), Text = "Water Pump",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "CringlePresent" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Present",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LeverForGate" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Lever",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "VineGuillotine" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MandrakeLive" then
        if Toggles.ObjectiveESPToggle.Value
            and Options.EntityESPOptions.Value["Mandrake Hole"] then
            Functions.AddESP({ Object = Object.Hole, Text = "Mandrake Hole",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object.Hole)
    elseif Name == "MinesGenerator" then
        task.spawn(function()
            task.wait(0.75)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Generator",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "FuseObtain" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Generator Fuse",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MinesGateButton" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Button",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "GardenGateButton" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Button",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "Ladder" then
        if Toggles.LadderESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Ladder",
                Color = Options.LadderESPColor.Value }, true)
        end
        table.insert(Objects.Ladders, Object)
    elseif Name == "Door" and Object.Parent and tonumber(Object.Parent.Name) then
        local DoorParts = {}
        for _, Child in ipairs(Object:GetChildren()) do
            if Child.Name == "Door" and Child:IsA("BasePart") then
                table.insert(DoorParts, Child)
            end
        end

        if #DoorParts == 2 then
            local HighlightModel = Instance.new("Model", Object)
            HighlightModel.Name = "HighlightModel"
            Instance.new("Humanoid", HighlightModel).Name = "HighlightHumanoid"
            HighlightModel:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))

            for _, DoorPart in ipairs(DoorParts) do
                local HP = Instance.new("Part", HighlightModel)
                HP.Transparency = 0.999
                HP.Size = DoorPart.Size
                HP.CanCollide = false
                HP.CFrame = DoorPart.CFrame
                HP.Name = "HighlightPart"
                HP.Material = Enum.Material.Plastic
                HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
                local W = Instance.new("WeldConstraint", HP)
                W.Part0 = HP W.Part1 = DoorPart W.Enabled = true
            end
            table.insert(Objects.Doors, HighlightModel)
            if Toggles.DoorESPToggle.Value then
                Functions.AddESP({ Object = HighlightModel,
                    Text = "Door " .. Functions.GetDoorNumber(Object),
                    Color = Options.DoorESPColor.Value }, true)
            end
        else
            local Root = Object:WaitForChild("Door", 9e9)
            local HP = Instance.new("Part", Object)
            HP.Transparency = 0.999
            HP.Size = Root.Size
            HP.CanCollide = false
            HP.CFrame = Root.CFrame
            HP.Name = "HighlightPart"
            HP.Material = Enum.Material.Plastic
            HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
            local W = Instance.new("WeldConstraint", HP)
            W.Part0 = HP W.Part1 = Root W.Enabled = true
            Instance.new("Humanoid", Object).Name = "HighlightHumanoid"
            table.insert(Objects.Doors, HP)
            if Toggles.DoorESPToggle.Value then
                Functions.AddESP({ Object = HP,
                    Text = "Door " .. Functions.GetDoorNumber(Object),
                    Color = Options.DoorESPColor.Value }, true)
            end
        end

    elseif HidingSpotLabels[Name] or string.find(string.lower(Name), "hidingspot") then
        local Label = HidingSpotLabels[Name]
            or (string.find(string.lower(Name), "hidingspot") and "Hiding Spot" or nil)
        if Label and Toggles.HidingSpotESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.HidingSpotESPColor.Value }, true)
        end
        table.insert(Objects.HidingSpots, Object)
    elseif Object:FindFirstChild("HidingPrompt") or Object:FindFirstChild("HidePrompt") then
        table.insert(Objects.HidingSpots, Object)
    elseif Name == "ChestBox" or Name == "ChestBoxLocked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = Object:GetAttribute("Locked") and "Locked Chest" or "Chest",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Toolbox" or Name == "Toolbox_Locked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Chest_Vine" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Vine Chest",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Toolshed_Small" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Toolshed",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Locker_Small_Locked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Locked Item Locker",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "MouseHole" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Mouse",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif ItemNames[Name] and Object:FindFirstChild("ModulePrompt") then
        if Toggles.ItemESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = ItemNames[Name],
                Color = Options.ItemESPColor.Value },
                Object:GetAttribute("ParentRoom") ~= nil)
        end
        table.insert(Objects.Items, Object)
    elseif Name == "Green_Herb" then
        if Toggles.ItemESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Green Herb",
                Color = Options.ItemESPColor.Value }, true)
        end
        table.insert(Objects.Items, Object)
    elseif Name == "GoldPile" and Object:GetAttribute("GoldValue") then
        if Toggles.CurrencyESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]",
                Color = Options.CurrencyESPColor.Value }, true)
        end
        table.insert(Objects.Currency, Object)
    elseif Name == "StardustPickup" then
        if Toggles.CurrencyESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Stardust Pile",
                Color = Options.CurrencyESPColor.Value }, true)
        end
        table.insert(Objects.Currency, Object)
    elseif Name == "GiggleCeiling" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Giggle"] then
            Functions.AddESP({ Object = Object, Text = "Giggle",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "GloomPile" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Gloombat Eggs"] then
            Functions.AddESP({ Object = Object, Text = "Gloombat Eggs",
                Color = Options.EntityESPColor.Value })
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "DoorFake" or Name == "FakeDoor" then
        if Object.Parent and Object:FindFirstChild("Hidden") then
            if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Dupe"] then
                Functions.AddESP({ Object = Object, Text = "Dupe",
                    Color = Options.EntityESPColor.Value }, true)
            end
            table.insert(Objects.Entities, Object)
        end
    elseif Name == "SideroomSpace" then
        table.insert(Objects.Entities, Object)
    elseif Name == "Snare" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Snare"] then
            Functions.AddESP({ Object = Object, Text = "Snare",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "BananaPeel" then
        table.insert(Objects.Entities, Object)
    elseif Name == "JeffTheKiller" then
        table.insert(Objects.Entities, Object)
    elseif Name == "GrumbleRig" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Grumble"] then
            Functions.AddESP({ Object = Object, Text = "Grumble",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "LiveEntityBramble" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Bramble"] then
            Functions.AddESP({ Object = Object, Text = "Bramble",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "Groundskeeper" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Groundskeeper"] then
            Functions.AddESP({ Object = Object, Text = "Groundskeeper",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Figure"] then
            Functions.AddESP({ Object = Object, Text = "Figure",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    end
end

--─────────────────────────────────────────────────────────────────────
-- 原版 HandleEntitySpawn —— 只保留 ESP 部分（通知/聊天没搬）
--─────────────────────────────────────────────────────────────────────
local function HandleEntitySpawn(Entity)
    if not Entity or typeof(Entity) ~= "Instance" then return end

    local Model = Entity
    if Entity:IsA("Humanoid") then
        Model = Entity.Parent
    end
    if not Model or not Model:IsA("Model") then return end

    local EntityData = Entities[Model.Name]
    if not EntityData then return end
    if Model:GetAttribute("Abysall_EntityHandled") then return end
    Model:SetAttribute("Abysall_EntityHandled", true)

    while not Model.PrimaryPart do
        for _, Child in ipairs(Model:GetChildren()) do
            if Child:IsA("BasePart") then Model.PrimaryPart = Child end
        end
        if not Model.PrimaryPart then task.wait() end
    end
    task.wait(0.1)

    if not Model.PrimaryPart
        or LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) >= 10000 then
        return
    end

    local Alias = EntityData.Alias
    local RealAlias = Alias

    if Model.Name ~= "GloombatSwarm" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealAlias] then
            if Model.Name == "MonumentEntity" then
                Functions.AddESP({ Object = Model.Top, Text = Alias,
                    Color = Options.EntityESPColor.Value })
            else
                Functions.AddESP({ Object = Model, Text = Alias,
                    Color = Options.EntityESPColor.Value })
            end
        end
        table.insert(Objects.Entities, Model)
    end

    if RusherAliases[RealAlias] then
        Instance.new("Humanoid", Model).Name = "HighlightHumanoid"
        local Root = Model.PrimaryPart
        if Root then
            Root.Transparency = 0.999
            Root.Material = Enum.Material.Plastic
        end
    end
end

-- 原版 QueueObject + 逐帧消费队列
Globals.ObjectQueue = {}

Functions.QueueObject = function(Object)
    local IsHidingSpot = typeof(Object.Name) == "string"
        and string.find(string.lower(Object.Name), "hidingspot")
    if not AllowedInstances[Object.Name] and not IsHidingSpot
        and Object.ClassName ~= "ProximityPrompt"
        and Object.Parent ~= Services.Workspace:FindFirstChild("CurrentRooms")
        and not ItemNames[Object.Name] then
        return
    end
    table.insert(Globals.ObjectQueue, Object)
end

Connections.QueueConnection = Services.RunService.RenderStepped:Connect(function()
    local Object = table.remove(Globals.ObjectQueue, 1)
    if Object then
        Functions.HandleObject(Object)
    end
end)

for _, Object in ipairs(Services.Workspace:GetDescendants()) do
    task.spawn(function() Functions.QueueObject(Object) end)
end

Connections.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
    Functions.QueueObject(Object)
end)

Connections.EntityHandler = Services.Workspace.ChildAdded:Connect(function(Object)
    if Entities[Object.Name] then
        task.defer(function() HandleEntitySpawn(Object) end)
    end
end)

Connections.EntityDescendantHandler = Services.Workspace.DescendantAdded:Connect(function(Descendant)
    local EntityModel = Descendant:IsA("Humanoid") and Descendant.Parent or Descendant
    if EntityModel and EntityModel:IsA("Model") and Entities[EntityModel.Name] then
        task.defer(function() HandleEntitySpawn(Descendant) end)
    end
end)

-- 原版 Cleaner：对象没了就从表里摘掉
do
    local LastClean = tick()
    Connections.Cleaner = Services.RunService.Heartbeat:Connect(function()
        if tick() - LastClean <= 0.5 then return end
        LastClean = tick()

        for _, Array in pairs(Objects) do
            local I = #Array
            while I >= 1 do
                local Object = Array[I]
                if Object == nil or not Object:IsDescendantOf(Services.Workspace) then
                    table.remove(Array, I)
                    local Conn = ESPConnections[Object]
                    if Conn then
                        Conn:Disconnect()
                        ESPConnections[Object] = nil
                        local Pos = table.find(Connections, Conn)
                        if Pos then table.remove(Connections, Pos) end
                    end
                end
                I = I - 1
            end
        end
    end)
end

--=====================================================================
-- 5. 原版 ESP 开关（名字 / 默认值 / 颜色 全部照抄）
--=====================================================================
local Window = Mini.NewWindow("Doors · ESP 提取版", "原版行为 · 视野 120")

local tabESP = Window:Tab("ESP")
local tabSet = Window:Tab("ESP 设置")
local tabCam = Window:Tab("视野")
local tabCreak = Window:Tab("Creak")

--────────────────────────── ESP 开关页 ──────────────────────────
local ESPOrder = {
    { "DoorESPToggle", "Doors", "Highlights the next door.",
      "DoorESPColor", Color3.fromRGB(0, 200, 255) },
    { "HidingSpotESPToggle", "Hiding Spots", "Highlights places where you can hide from entities",
      "HidingSpotESPColor", Color3.fromRGB(255, 170, 0) },
    { "PlayerESPToggle", "Players", "Highlights other players.",
      "PlayerESPColor", Color3.fromRGB(255, 255, 255) },
    { "ChestESPToggle", "Chests", "Highlights objects that can contain loot.",
      "ChestESPColor", Color3.fromRGB(255, 255, 0) },
    { "ItemESPToggle", "Items", "Highlights all collectable items/consumables.",
      "ItemESPColor", Color3.fromRGB(170, 0, 255) },
    { "CurrencyESPToggle", "Currency", "Highlights all currency that spawns.",
      "CurrencyESPColor", Color3.fromRGB(255, 255, 0) },
    { "LadderESPToggle", "Ladders", "Highlights ladders that can be used to disable the anticheat.",
      "LadderESPColor", Color3.fromRGB(3, 67, 71) },
    { "MiscESPToggle", "Misc", "Highlights miscellaneous objects that can be used to disable the anticheat.",
      "MiscESPColor", Color3.fromRGB(255, 255, 255) },
    { "ObjectiveESPToggle", "Objectives", "",
      "ObjectiveESPColor", Color3.fromRGB(0, 255, 0) },
}

for _, def in ipairs(ESPOrder) do
    local t = Mini.Toggle(tabESP.Page, { Text = def[2], Default = false, Tooltip = def[3] })
    Toggles[def[1]] = t
    local c = Mini.ColorPicker(tabESP.Page, { Text = def[2] .. " Color", Default = def[5] })
    Options[def[4]] = c
end

Toggles.EntityESPToggle = Mini.Toggle(tabESP.Page, {
    Text = "Entities", Default = false, Tooltip = "Highlights all entities that spawn.",
})
Options.EntityESPColor = Mini.ColorPicker(tabESP.Page, {
    Text = "Entities Color", Default = Color3.fromRGB(255, 0, 0),
})

Mini.Label(tabESP.Page, "Entity List（默认不选，和原版 AllowNull 一致）", Theme.Text)
Options.EntityESPOptions = Mini.MultiSelect(tabESP.Page, {
    Text = "Entity List", Values = EntityListValues, Default = {},
})
Mini.Button(tabESP.Page, { Text = "全选" }):OnClick(function()
    Options.EntityESPOptions:SetAll(true)
end)
Mini.Button(tabESP.Page, { Text = "全不选" }):OnClick(function()
    Options.EntityESPOptions:SetAll(false)
end)

--────────────────────────── ESP 设置页 ──────────────────────────
Toggles.ESPRainbow = Mini.Toggle(tabSet.Page, {
    Text = "Rainbow Effect", Default = false,
    Tooltip = "Makes the esp objects change colour like a rainbow.",
})
Toggles.ESPShowDistance = Mini.Toggle(tabSet.Page, {
    Text = "Show Distance", Default = true,
    Tooltip = "Shows how far away your character is from the object.",
})
Mini.Divider(tabSet.Page)

Options.ESPFillTransparency = Mini.Slider(tabSet.Page, {
    Text = "Fill Transparency", Min = 0, Max = 1, Default = 0.75, Rounding = 2 })
Options.ESPOutlineTransparency = Mini.Slider(tabSet.Page, {
    Text = "Outline Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextTransparency = Mini.Slider(tabSet.Page, {
    Text = "Text Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextOutlineTransparency = Mini.Slider(tabSet.Page, {
    Text = "Text Outline Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPFadeTime = Mini.Slider(tabSet.Page, {
    Text = "Fade Time", Min = 0, Max = 1, Default = 0.25, Rounding = 2 })
Options.ESPRenderLimit = Mini.Slider(tabSet.Page, {
    Text = "Render Limit", Min = 30, Max = 240, Default = 240, Rounding = 0 })
Options.ESPTextSize = Mini.Slider(tabSet.Page, {
    Text = "Text Size", Min = 12, Max = 24, Default = 20, Rounding = 0 })
Options.ESPTextFont = Mini.Dropdown(tabSet.Page, {
    Text = "Text Font", Values = FontValues, Default = 12 })

Mini.Divider(tabSet.Page)
Options.ESPTracersOrigin = Mini.Dropdown(tabSet.Page, {
    Text = "Tracer Origin", Values = { "Bottom", "Center", "Top", "Mouse" }, Default = 1 })
Options.ESPTracerThickness = Mini.Slider(tabSet.Page, {
    Text = "Tracer Thickness", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2 })
Toggles.ESPTracersToggle = Mini.Toggle(tabSet.Page, {
    Text = "Enable Tracers", Default = false,
    Tooltip = "Draws a line to highlighted objects." })

Mini.Divider(tabSet.Page)
Options.ESPArrowsRadius = Mini.Slider(tabSet.Page, {
    Text = "Arrow Radius", Min = 100, Max = 500, Default = 250, Rounding = 0 })
Toggles.ESPArrowsToggle = Mini.Toggle(tabSet.Page, {
    Text = "Enable Arrows", Default = false,
    Tooltip = "Shows arrow that point to off-screen objects." })

Mini.Divider(tabSet.Page)
Mini.Label(tabSet.Page,
    "下面是便捷开关：把 Text Transparency 一键拉到 1（= 只留轮廓，没有文字）。",
    Theme.SubText)
local TextOffToggle
TextOffToggle = Mini.Toggle(tabSet.Page, {
    Text = "隐藏 ESP 文字", Default = false,
    Tooltip = "等于把 Text Transparency 拉到 1",
})
TextOffToggle:OnChanged(function(v)
    Options.ESPTextTransparency:Set(v and 1 or 0, true)
    ESPLibrary:SetTextTransparency(v and 1 or 0)
end)
Options.ESPTextTransparency:OnChanged(function(v)
    TextOffToggle:Set(v >= 1, true)
end)

--────────────────────────── 视野页 ──────────────────────────
Toggles.FOVToggle = Mini.Toggle(tabCam.Page, {
    Text = "Custom FOV", Default = true, Tooltip = "Only applies the Field of View slider when enabled.",
})
Options.FieldOfView = Mini.Slider(tabCam.Page, {
    Text = "Field of View", Min = 1, Max = 120, Default = 120, Rounding = 0 })
local FovKeybind = Mini.Keybind(tabCam.Page, {
    Text = "Custom Fov 快捷键", Default = Enum.KeyCode.O,
})

--=====================================================================
-- 6. 原版 ESP 库设置（数值照抄 5443-5458 行）
--=====================================================================
ESPLibrary:SetRainbow(false)
ESPLibrary:SetShowDistance(true)
ESPLibrary:SetFillTransparency(0.75)
ESPLibrary:SetOutlineTransparency(0)
ESPLibrary:SetTextTransparency(0)
ESPLibrary:SetTextOutlineTransparency(0)
ESPLibrary:SetRenderLimit(240)
ESPLibrary:SetFadeTime(0.25)
ESPLibrary:SetTextSize(20)
ESPLibrary:SetFont(Enum.Font.Highway)
ESPLibrary:SetTracers(false)
ESPLibrary:SetTracerSize(0.75)
ESPLibrary:SetTracerOrigin("Bottom")
ESPLibrary:SetArrows(false)
ESPLibrary:SetArrowRadius(250)
ESPLibrary:SetDistanceSizeRatio(0.8)

Toggles.ESPRainbow:OnChanged(function(V) ESPLibrary:SetRainbow(V) end)
Toggles.ESPShowDistance:OnChanged(function(V) ESPLibrary:SetShowDistance(V) end)
Options.ESPFillTransparency:OnChanged(function(V) ESPLibrary:SetFillTransparency(V) end)
Options.ESPOutlineTransparency:OnChanged(function(V) ESPLibrary:SetOutlineTransparency(V) end)
Options.ESPTextTransparency:OnChanged(function(V) ESPLibrary:SetTextTransparency(V) end)
Options.ESPTextOutlineTransparency:OnChanged(function(V) ESPLibrary:SetTextOutlineTransparency(V) end)
Options.ESPFadeTime:OnChanged(function(V) ESPLibrary:SetFadeTime(V) end)
Options.ESPRenderLimit:OnChanged(function(V) ESPLibrary:SetRenderLimit(V) end)
Options.ESPTextSize:OnChanged(function(V) ESPLibrary:SetTextSize(V) end)
Options.ESPTextFont:OnChanged(function(V) ESPLibrary:SetFont(Enum.Font[V]) end)
Toggles.ESPTracersToggle:OnChanged(function(V) ESPLibrary:SetTracers(V) end)
Options.ESPTracersOrigin:OnChanged(function(V) ESPLibrary:SetTracerOrigin(V) end)
Options.ESPTracerThickness:OnChanged(function(V) ESPLibrary:SetTracerSize(V) end)
Toggles.ESPArrowsToggle:OnChanged(function(V) ESPLibrary:SetArrows(V) end)
Options.ESPArrowsRadius:OnChanged(function(V) ESPLibrary:SetArrowRadius(V) end)

--=====================================================================
-- 7. 原版 ESP 开关的回调（照着 5244-5418 行写）
--=====================================================================
Toggles.DoorESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Doors) do
        if Value then
            Functions.AddESP({ Object = Object,
                Text = "Door " .. Functions.GetDoorNumber(Object),
                Color = Options.DoorESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.DoorESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Doors) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.HidingSpotESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.HidingSpots) do
        local Label = HidingSpotLabels[Object.Name]
        if Value and Label then
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.HidingSpotESPColor.Value }, true)
        elseif not Value then
            Functions.RemoveESP(Object)
        end
    end
end)
Options.HidingSpotESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.HidingSpots) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.PlayerESPToggle:OnChanged(function(Value)
    task.wait()
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player.Character and Player ~= LocalPlayer then
            if Value and Player:GetAttribute("Alive") == true then
                Functions.AddESP({ Object = Player.Character, Text = Player.Name,
                    Color = Options.PlayerESPColor.Value })
            else
                Functions.RemoveESP(Player.Character)
            end
        end
    end
end)
Options.PlayerESPColor:OnChanged(function(Value)
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player.Character and Player ~= LocalPlayer then
            ESPLibrary:UpdateObjectColor(Player.Character, Value)
        end
    end
end)

Toggles.ChestESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Chests) do
        if Value then
            local Label
            if Object.Name == "ChestBox" or Object.Name == "ChestBoxLocked" then
                Label = Object:GetAttribute("Locked") and "Locked Chest" or "Chest"
            elseif Object.Name == "Toolbox" or Object.Name == "Toolbox_Locked" then
                Label = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox"
            elseif ChestLabels[Object.Name] and ChestLabels[Object.Name] ~= true then
                Label = ChestLabels[Object.Name]
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ChestESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ChestESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Chests) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ItemESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Items) do
        if Value then
            local Label = ItemNames[Object.Name]
                or (Object.Name == "Green_Herb" and "Green Herb")
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ItemESPColor.Value },
                    Object:GetAttribute("ParentRoom") ~= nil)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ItemESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Items) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.CurrencyESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Currency) do
        if Value then
            local Label
            if Object.Name == "GoldPile" and Object:GetAttribute("GoldValue") then
                Label = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]"
            elseif Object.Name == "StardustPickup" then
                Label = "Stardust Pile"
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.CurrencyESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.CurrencyESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Currency) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

local function EntityLabel(Object)
    local Label = EntityESPLabels[Object.Name]
    if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
    if not Label and string.sub(Object.Name, 1, #"MirrorRig_Portrait") == "MirrorRig_Portrait" then
        Label = "Portrait"
    end
    return Label
end

Toggles.EntityESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Entities) do
        if Value then
            local Label = EntityLabel(Object)
            if Label and Options.EntityESPOptions.Value[Label] then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
            else
                Functions.RemoveESP(Object)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.EntityESPOptions:OnChanged(function()
    for _, Object in ipairs(Objects.Entities) do
        if Toggles.EntityESPToggle.Value then
            local Label = EntityLabel(Object)
            if Label and Options.EntityESPOptions.Value[Label] then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
            else
                Functions.RemoveESP(Object)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.EntityESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Entities) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.LadderESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Ladders) do
        if Value then
            Functions.AddESP({ Object = Object, Text = "Ladder",
                Color = Options.LadderESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.LadderESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Ladders) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.MiscESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Misc) do
        if Value then
            local Label = Object.Name
            if Object.Name == "StairwellLockpickDoor" or Object.Name == "StiarwellLockpickDoor" then
                Label = "Garage Door"
            elseif Object.Name == "StairwellFireAlarm" then
                Label = "Fire Alarm"
            elseif Object.Name == "ShoppingCart" then
                Label = "Shopping Cart"
            elseif Object.Name == "ArchivesFihTank" or Object.Name == "ArchivesFishTank" then
                Label = "Fish Tank"
            end
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.MiscESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.MiscESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Misc) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Objectives) do
        if Value then
            local Label = ObjectiveLabels[Object.Name]
            if Object.Name == "TimerLever" then
                Label = "Time Lever [+" .. tostring(Object:GetAttribute("AddTime")) .. "s]"
            elseif Object.Name == "MinesAnchor" then
                local Sign = Object:FindFirstChild("Sign")
                if Sign and Sign:FindFirstChild("TextLabel") then
                    Label = "Anchor [" .. Sign.TextLabel.Text .. "]"
                end
            elseif Object.Name == "WaterPump" then
                if Object:FindFirstChild("Wheel") then
                    Functions.AddESP({ Object = Object.Wheel, Text = "Water Pump",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                Label = false
            elseif Object.Name == "VineGuillotine" then
                if Object:FindFirstChild("Lever") then
                    Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                Label = false
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ObjectiveESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ObjectiveESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Objectives) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

-- 原版玩家 ESP 的加入/离开跟踪
for _, Player in ipairs(Services.Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        if Player.Character and Toggles.PlayerESPToggle.Value then
            Functions.AddESP({ Object = Player.Character, Text = Player.Name,
                Color = Options.PlayerESPColor.Value })
        end
        local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
            if Toggles.PlayerESPToggle.Value then
                Functions.AddESP({ Object = NewCharacter, Text = Player.Name,
                    Color = Options.PlayerESPColor.Value })
            end
        end)
        local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
            if Player:GetAttribute("Alive") ~= true and Player.Character then
                Functions.RemoveESP(Player.Character)
            end
        end)
        table.insert(Connections, CharConn)
        table.insert(Connections, DeadConn)
    end
end

Connections.PlayerHandler = Services.Players.PlayerAdded:Connect(function(Player)
    if Player == LocalPlayer then return end
    if Player.Character and Toggles.PlayerESPToggle.Value then
        Functions.AddESP({ Object = Player.Character, Text = Player.Name,
            Color = Options.PlayerESPColor.Value })
    end
    local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
        if Toggles.PlayerESPToggle.Value then
            Functions.AddESP({ Object = NewCharacter, Text = Player.Name,
                Color = Options.PlayerESPColor.Value })
        end
    end)
    local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
        if Player:GetAttribute("Alive") ~= true and Player.Character then
            Functions.RemoveESP(Player.Character)
        end
    end)
    table.insert(Connections, CharConn)
    table.insert(Connections, DeadConn)
end)

--=====================================================================
-- 8. 视野 FOV（原版写法；滑条默认值 70 -> 120，这是你要求的唯一改动）
--=====================================================================
local MainGame

task.spawn(function()
    local ok, res = pcall(function()
        local ui = LocalPlayer.PlayerGui
        if not ui then return nil end
        local ini = ui:FindFirstChild("MainUI")
        if not ini then return nil end
        local mg = ini:FindFirstChild("Initiator")
        if not mg then return nil end
        local mod = mg:FindFirstChild("Main_Game")
        if not mod then return nil end
        return require(mod)
    end)
    if ok and res then MainGame = res end
end)

local LastFovApply = 0
Connections.FovHandler = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.FOVToggle.Value then return end
    if tick() - LastFovApply < 0.1 then return end
    LastFovApply = tick()

    if MainGame then
        MainGame.fovtarget = Options.FieldOfView.Value
    else
        local cam = Services.Workspace.CurrentCamera
        if cam then cam.FieldOfView = Options.FieldOfView.Value end
    end
end)

--=====================================================================
-- 9. Creak 愤怒值（原版 3510-3694 行，Drawing 实现原样搬运）
--=====================================================================
local CreakAggressionMetersTable = {}
local CreakAggressionCamera = Services.Workspace.CurrentCamera
local CreakAggressionChildAddedConnection = nil

Toggles.CreakAggressionMeter = Mini.Toggle(tabCreak.Page, {
    Text = "Creak Aggression Meter", Default = false,
    Tooltip = "Shows Creak's aggression above its head.",
})

local function CleanupCreakAggressionMeter(CreakModel)
    local CreakMeterData = CreakAggressionMetersTable[CreakModel]
    if not CreakMeterData then return end

    CreakAggressionMetersTable[CreakModel] = nil

    if CreakMeterData.RenderConnection then
        CreakMeterData.RenderConnection:Disconnect()
    end
    if CreakMeterData.DestroyConnection then
        CreakMeterData.DestroyConnection:Disconnect()
    end

    for _, CreakDrawingObject in ipairs(CreakMeterData.Drawings) do
        pcall(function() CreakDrawingObject:Remove() end)
    end
end

local function GetCreakAggressionValue(CreakModel)
    local CreakAnimator = CreakModel:FindFirstChildOfClass("Animator")
        or (CreakModel:FindFirstChild("AnimationController")
            and CreakModel.AnimationController:FindFirstChildOfClass("Animator"))
        or CreakModel:FindFirstChildOfClass("AnimationController")

    if not CreakAnimator then return nil end

    for _, CreakAnimationTrack in ipairs(CreakAnimator:GetPlayingAnimationTracks()) do
        if CreakAnimationTrack.Name == "CreakGraph"
            or (CreakAnimationTrack.Animation
                and CreakAnimationTrack.Animation.Name == "CreakGraph") then
            local CreakSuccess, CreakAggressionValue =
                pcall(CreakAnimationTrack.GetParameter, CreakAnimationTrack, "Aggression")
            if CreakSuccess and typeof(CreakAggressionValue) == "number" then
                return math.clamp(CreakAggressionValue, 0, 1)
            end
        end
    end
    return nil
end

local function CreateCreakAggressionDrawings()
    local CreakDrawingList = {}

    local function CreateCreakDrawing(CreakDrawingType)
        local CreakNewDrawing = Drawing.new(CreakDrawingType)
        table.insert(CreakDrawingList, CreakNewDrawing)
        return CreakNewDrawing
    end

    local CreakTitleText = CreateCreakDrawing("Text")
    CreakTitleText.Text = "Aggression --%"
    CreakTitleText.Size = 16
    CreakTitleText.Font = Drawing.Fonts.Plex
    CreakTitleText.Color = Color3.fromRGB(255, 255, 255)
    CreakTitleText.Center = true
    CreakTitleText.Outline = true
    CreakTitleText.Visible = false

    local CreakBarBackground = CreateCreakDrawing("Square")
    CreakBarBackground.Size = Vector2.new(112, 6)
    CreakBarBackground.Filled = true
    CreakBarBackground.Color = Color3.fromRGB(58, 58, 64)
    CreakBarBackground.Transparency = 0.15
    CreakBarBackground.Visible = false

    local CreakBarFill = CreateCreakDrawing("Square")
    CreakBarFill.Size = Vector2.new(0, 6)
    CreakBarFill.Filled = true
    CreakBarFill.Visible = false

    return {
        Drawings = CreakDrawingList,
        TitleText = CreakTitleText,
        BarBackground = CreakBarBackground,
        BarFill = CreakBarFill
    }
end

local function AddCreakAggressionMeter(CreakModel)
    if not Toggles.CreakAggressionMeter.Value
        or CreakModel.Name ~= "Creak"
        or CreakAggressionMetersTable[CreakModel] then
        return
    end

    local CreakHeadPart = CreakModel:FindFirstChild("Head")
    if not CreakHeadPart or not CreakHeadPart:IsA("BasePart") then return end

    local CreakMeterData = CreateCreakAggressionDrawings()
    CreakAggressionMetersTable[CreakModel] = CreakMeterData

    CreakMeterData.RenderConnection = RunService.RenderStepped:Connect(function()
        if not Toggles.CreakAggressionMeter.Value or not CreakModel.Parent
            or not CreakHeadPart.Parent then
            CleanupCreakAggressionMeter(CreakModel)
            return
        end

        if not CreakAggressionCamera or not CreakAggressionCamera.Parent then
            CreakAggressionCamera = Services.Workspace.CurrentCamera
            if not CreakAggressionCamera then return end
        end

        local CreakScreenPosition, CreakIsOnScreen =
            CreakAggressionCamera:WorldToViewportPoint(
                CreakHeadPart.Position + Vector3.new(0, 1.85, 0))
        if not (CreakIsOnScreen and CreakScreenPosition.Z > 0) then
            CreakMeterData.TitleText.Visible = false
            CreakMeterData.BarBackground.Visible = false
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Position =
            Vector2.new(CreakScreenPosition.X, CreakScreenPosition.Y - 28)
        CreakMeterData.BarBackground.Position =
            Vector2.new(CreakScreenPosition.X - 56, CreakScreenPosition.Y - 6)
        CreakMeterData.BarFill.Position = CreakMeterData.BarBackground.Position

        local CreakAggressionValue = GetCreakAggressionValue(CreakModel)

        if not CreakAggressionValue then
            CreakMeterData.TitleText.Text = "Aggression --%"
            CreakMeterData.TitleText.Color = Color3.fromRGB(200, 200, 200)
            CreakMeterData.BarFill.Size = Vector2.new(0, 6)
            CreakMeterData.TitleText.Visible = true
            CreakMeterData.BarBackground.Visible = true
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Text =
            "Aggression " .. math.floor(CreakAggressionValue * 100 + 0.5) .. "%"
        CreakMeterData.TitleText.Color = Color3.fromRGB(255, 255, 255)
        CreakMeterData.BarFill.Size = Vector2.new(112 * CreakAggressionValue, 6)
        CreakMeterData.BarFill.Color = Color3.fromRGB(70, 220, 100)
            :Lerp(Color3.fromRGB(255, 55, 55), CreakAggressionValue)
        CreakMeterData.TitleText.Visible = true
        CreakMeterData.BarBackground.Visible = true
        CreakMeterData.BarFill.Visible = true
    end)

    CreakMeterData.DestroyConnection = CreakModel.Destroying:Connect(function()
        CleanupCreakAggressionMeter(CreakModel)
    end)
end

local function StartCreakAggressionListener()
    if CreakAggressionChildAddedConnection then return end

    local CreakLiveEntitiesFolder = Services.Workspace:FindFirstChild("LiveEntities")
    if not CreakLiveEntitiesFolder then return end

    CreakAggressionChildAddedConnection =
        CreakLiveEntitiesFolder.ChildAdded:Connect(function(CreakNewChild)
            if CreakNewChild.Name == "Creak" then
                AddCreakAggressionMeter(CreakNewChild)
            end
        end)
end

local function StopCreakAggressionListener()
    if CreakAggressionChildAddedConnection then
        CreakAggressionChildAddedConnection:Disconnect()
        CreakAggressionChildAddedConnection = nil
    end
end

Toggles.CreakAggressionMeter:OnChanged(function(CreakToggleEnabled)
    if CreakToggleEnabled then
        for _, CreakEntityModel in ipairs(Objects.Entities or {}) do
            AddCreakAggressionMeter(CreakEntityModel)
        end

        local CreakLiveEntitiesFolder = Services.Workspace:FindFirstChild("LiveEntities")
        local CreakExistingModel = CreakLiveEntitiesFolder
            and CreakLiveEntitiesFolder:FindFirstChild("Creak")
        if CreakExistingModel then
            AddCreakAggressionMeter(CreakExistingModel)
        end

        StartCreakAggressionListener()
    else
        StopCreakAggressionListener()

        for CreakEntityModel in pairs(CreakAggressionMetersTable) do
            CleanupCreakAggressionMeter(CreakEntityModel)
        end
    end
end)

-- 开关键
local kb = Mini.Keybind(tabSet.Page, { Text = "界面开关键", Default = Enum.KeyCode.RightShift })
Connections.Input = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == kb.Key then Window:Toggle() end
    if input.KeyCode == FovKeybind.Key then
        Toggles.FOVToggle:Set(not Toggles.FOVToggle.Value)
    end
end)

if not Drawing then
    warn("[DoorsESPX] 你的执行器没有 Drawing API，Creak 愤怒值血条不会显示（原版就是用的 Drawing）")
end

--=====================================================================
-- 10. 卸载
--=====================================================================
local Module = {}

function Module.Unload()
    for Key, Connection in pairs(Connections) do
        if type(Key) == "string" then
            pcall(function() Connection:Disconnect() end)
        else
            pcall(function() Key:Disconnect() end)
            pcall(function() Connection:Disconnect() end)
        end
    end

    StopCreakAggressionListener()
    for CreakEntityModel in pairs(CreakAggressionMetersTable) do
        CleanupCreakAggressionMeter(CreakEntityModel)
    end

    pcall(function() ESPLibrary:Unload() end)
    pcall(function() Window.Gui:Destroy() end)

    if getgenv()[STATE_KEY] == Module then
        getgenv()[STATE_KEY] = nil
    end
    print("[DoorsESPX] 已卸载")
end

-- 测试/调试用：暴露内部表（不改任何行为）
Module.Objects = Objects
Module.Toggles = Toggles
Module.Options = Options

getgenv()[STATE_KEY] = Module

print("[DoorsESPX] 载入完成 · 全部开关默认关闭（和原版一致）· RightShift 开关界面")
print("[DoorsESPX] 卸载 getgenv().DoorsESPX.Unload()")

return Module

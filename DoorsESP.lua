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
-- 0.5 界面多语言（只翻译界面文字；ESP 标签保持游戏原版名称）
--=====================================================================
local Lang = {
    Current  = "zh",
    Strings  = { zh = {}, en = {} },
    Registry = {},
    Names    = { zh = "中文", en = "English" },
}

function Lang.T(key)
    if not key then return nil end
    local t = Lang.Strings[Lang.Current]
    return t and t[key] or nil
end

function Lang.Has(key)
    return Lang.T(key) ~= nil
end

function Lang.Bind(inst, key, prop)
    if not key then return inst end
    Lang.Registry[#Lang.Registry + 1] = { inst = inst, key = key, prop = prop or "Text" }
    local v = Lang.T(key)
    if v ~= nil then inst[prop or "Text"] = v end
    return inst
end

-- 动态文字（比如「已选 3」）用回调，切换语言时重新算
function Lang.BindFn(inst, fn)
    Lang.Registry[#Lang.Registry + 1] = { inst = inst, fn = fn }
    inst.Text = fn()
    return inst
end

function Lang.Format(key, ...)
    local fmt = Lang.T(key)
    if not fmt then return tostring((...)) end
    local ok, out = pcall(string.format, fmt, ...)
    return ok and out or tostring((...))
end

function Lang.Set(code)
    if not Lang.Strings[code] then return false end
    Lang.Current = code
    for _, e in ipairs(Lang.Registry) do
        if e.fn then
            e.inst.Text = e.fn()
        else
            local v = Lang.T(e.key)
            if v ~= nil then e.inst[e.prop] = v end
        end
    end
    return true
end

-- UI 构建时用 L(...) 就地声明两种语言，省掉一张独立的 key 表
local function L(key, zh, en, zhTip, enTip)
    Lang.Strings.zh[key] = zh
    Lang.Strings.en[key] = en or zh
    if zhTip then
        Lang.Strings.zh[key .. ".tip"] = zhTip
        Lang.Strings.en[key .. ".tip"] = enTip or zhTip
    end
    return { Key = key, Text = zh, Tooltip = zhTip }
end

local function PickText(cfg)
    if type(cfg) == "table" then
        return (cfg.Key and Lang.T(cfg.Key)) or cfg.Text or ""
    end
    return tostring(cfg or "")
end

local function PickKey(cfg)
    if type(cfg) == "table" then return cfg.Key end
    return nil
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

local function MakeLabel(parent, text, x, w, color, font, size, key)
    local lbl = Create("TextLabel", {
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
    if key then Lang.Bind(lbl, key) end
    return lbl
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

    local titleLbl = Create("TextLabel", {
        Parent = bar, BackgroundTransparency = 1, Font = Theme.FontBold,
        Text = PickText(title), TextSize = 15, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
    })
    Lang.Bind(titleLbl, PickKey(title))
    local subLbl = Create("TextLabel", {
        Parent = bar, BackgroundTransparency = 1, Font = Theme.Font,
        Text = PickText(subtitle), TextSize = 11, TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.35, 0, 0, 0), Size = UDim2.new(0.5, -46, 1, 0),
    })
    Lang.Bind(subLbl, PickKey(subtitle))

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

    function window:Tab(nameCfg)
        local name = PickText(nameCfg)
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
        Lang.Bind(btn, PickKey(nameCfg), "Text")

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
    local lbl = MakeLabel(row, PickText(cfg), 12, 220, Theme.Text, Theme.Font, 13, PickKey(cfg))
    local tipKey = cfg.Key and (cfg.Key .. ".tip") or nil
    local tip = (tipKey and Lang.T(tipKey)) or cfg.Tooltip
    if not (tipKey and Lang.Has(tipKey)) then tipKey = nil end
    if tip then
        lbl.Size = UDim2.new(1, -78, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 3)
        local tipLbl = Create("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Font = Theme.Font,
            Text = tip, TextSize = 10, TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 12, 0, 18), Size = UDim2.new(1, -78, 0, 13),
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
        })
        Lang.Bind(tipLbl, tipKey)
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
    MakeLabel(row, PickText(cfg), 12, 220, Theme.Text, Theme.Font, 13, PickKey(cfg))
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
    MakeLabel(row, PickText(cfg), 12, 200, Theme.Text, Theme.Font, 13, PickKey(cfg))
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
        Text = PickText(cfg), TextSize = 13, TextColor3 = Theme.Accent,
        Size = UDim2.fromScale(1, 1),
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    Lang.Bind(btn, PickKey(cfg))
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
    local lbl = MakeLabel(row, PickText(text), 4, 600, color or Theme.SubText,
        Theme.Font, 11, PickKey(text))
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
    MakeLabel(header, PickText(cfg), 12, 200, Theme.Text, Theme.Font, 13, PickKey(cfg))
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
    MakeLabel(header, PickText(cfg), 12, 220, Theme.Text, Theme.Font, 13, PickKey(cfg))
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

    local function selectedCount()
        local n = 0
        for _, v in pairs(element.Selected) do
            if v then n = n + 1 end
        end
        return n
    end

    local function updateCount()
        count.Text = Lang.Format("ms.count", selectedCount())
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

    Lang.Strings.zh["ms.count"] = "已选 %d"
    Lang.Strings.en["ms.count"] = "%d selected"
    Lang.BindFn(count, function() return Lang.Format("ms.count", selectedCount()) end)

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
    MakeLabel(row, PickText(cfg), 12, 200, Theme.Text, Theme.Font, 13, PickKey(cfg))
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
        btn.Text = Lang.T("kb.press") or "…"
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
    SeekBridges = {}, PathLights = {}, Tasks = {}
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
        -- 闸门（原版挂在 Misc 里，和购物车同一条分支）→ 现在单独归到「任务」分类
        if Toggles.TaskESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Garage Door",
                Color = Options.TaskESPColor.Value }, true)
        end
        table.insert(Objects.Tasks, Object)
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
-- 5. UI 布局（每一页的控件名 / 默认值 / 颜色 照抄原版）
--=====================================================================
local Window = Mini.NewWindow(
    L("win.title", "Doors · ESP 提取版", "Doors · ESP Extraction"),
    L("win.sub",   "原版行为 · 视野 120", "Original behaviour · FOV 120"))

local tabLang   = Window:Tab(L("tab.lang",    "语言",      "Language"))
local tabESP    = Window:Tab(L("tab.esp",     "ESP",       "ESP"))
local tabSet    = Window:Tab(L("tab.set",     "ESP 设置",  "ESP Settings"))
local tabCam    = Window:Tab(L("tab.cam",     "相机",      "Camera"))
local tabChar   = Window:Tab(L("tab.char",    "角色",      "Character"))
local tabBypass = Window:Tab(L("tab.bypass",  "绕过",      "Bypass"))
local tabCreak  = Window:Tab(L("tab.creak",   "Creak",     "Creak"))

--────────────────────────── 语言 ──────────────────────────
local LangDropdown = Mini.Dropdown(tabLang.Page, {
    Key = "lang.pick", Text = "界面语言",
    Values = { "中文", "English" }, Default = 1,
})
LangDropdown:OnChanged(function(Value)
    Lang.Set(Value == "中文" and "zh" or "en")
end)
Mini.Label(tabLang.Page, L("lang.note",
    "切换语言只换界面文字。ESP 标签保持游戏里的原始名称（Lockpicks / Rush / Door 6 / Gold Pile [42] 这类），不翻译。",
    "Switching language only changes the interface. ESP labels keep the game's original names (Lockpicks / Rush / Door 6 / Gold Pile [42])."))
Mini.Label(tabLang.Page, L("lang.tip",
    "中文 / English 都可以，选完立刻生效，不用重载脚本。",
    "Pick Chinese or English; it applies immediately, no reload needed."))

--────────────────────────── ESP 开关 ──────────────────────────
local ESPOrder = {
    { "DoorESPToggle", "Doors",        "门",     "门",
      "Highlights the next door.", "高亮下一道门。",
      "DoorESPColor", Color3.fromRGB(0, 200, 255) },
    { "HidingSpotESPToggle", "Hiding Spots", "藏身点", "藏身点",
      "Highlights places where you can hide from entities", "高亮可以躲实体藏身点。",
      "HidingSpotESPColor", Color3.fromRGB(255, 170, 0) },
    { "PlayerESPToggle", "Players",    "玩家",   "玩家",
      "Highlights other players.", "高亮其他玩家。",
      "PlayerESPColor", Color3.fromRGB(255, 255, 255) },
    { "ChestESPToggle", "Chests",      "宝箱",   "宝箱",
      "Highlights objects that can contain loot.", "高亮可能出物资的箱子。",
      "ChestESPColor", Color3.fromRGB(255, 255, 0) },
    { "ItemESPToggle", "Items",        "物品",   "物品",
      "Highlights all collectable items/consumables.", "高亮所有可拾取物品 / 消耗品。",
      "ItemESPColor", Color3.fromRGB(170, 0, 255) },
    { "CurrencyESPToggle", "Currency", "货币",   "货币",
      "Highlights all currency that spawns.", "高亮刷出来的货币（金币堆 / 星尘）。",
      "CurrencyESPColor", Color3.fromRGB(255, 255, 0) },
    { "LadderESPToggle", "Ladders",    "梯子",   "梯子",
      "Highlights ladders that can be used to disable the anticheat.",
      "高亮梯子（爬一下可以关掉反作弊）。",
      "LadderESPColor", Color3.fromRGB(3, 67, 71) },
    { "MiscESPToggle", "Misc",         "杂项",   "杂项",
      "Highlights miscellaneous objects that can be used to disable the anticheat.",
      "高亮杂项物件（也能用来关反作弊）。",
      "MiscESPColor", Color3.fromRGB(255, 255, 255) },
    { "ObjectiveESPToggle", "Objectives", "目标物", "目标物",
      "Highlights objectives you have to interact with.", "高亮需要交互的任务目标。",
      "ObjectiveESPColor", Color3.fromRGB(0, 255, 0) },
}

local function BuildESPEntry(def)
    Toggles[def[1]] = Mini.Toggle(tabESP.Page, L(
        "esp." .. def[1], def[3], def[2], def[5], def[4]))
    local ColorCfg = L("col." .. def[1], def[4] .. " 颜色", def[2] .. " Color")
    ColorCfg.Default = def[8]
    Options[def[7]] = Mini.ColorPicker(tabESP.Page, ColorCfg)
end

-- 原版分类（Doors ~ Misc）
for i = 1, 8 do BuildESPEntry(ESPOrder[i]) end

--───────────────── 任务（闸门单独成类） ─────────────────
-- 闸门原来跟购物车挤在 Misc 里，现在单独挑出来，颜色也换掉了
Mini.Divider(tabESP.Page)
Mini.Label(tabESP.Page, L("cat.task", "任务", "Tasks"), Theme.Accent)
Toggles.TaskESPToggle = Mini.Toggle(tabESP.Page, L(
    "esp.task", "闸门", "Garage Door",
    "Highlights the garage door. The original kept it inside Misc, next to the shopping cart.",
    "高亮闸门。原版把它塞在「杂项」里跟购物车同一条，这里单独拎出来。"))
local TaskColorCfg = L("col.task", "闸门 颜色", "Garage Door Color")
TaskColorCfg.Default = Color3.fromRGB(255, 0, 170)
Options.TaskESPColor = Mini.ColorPicker(tabESP.Page, TaskColorCfg)

-- 原版分类（Objectives ~ Entities）
for i = 9, #ESPOrder do BuildESPEntry(ESPOrder[i]) end

Toggles.EntityESPToggle = Mini.Toggle(tabESP.Page, L(
    "esp.entity", "实体", "Entities",
    "Highlights all entities that spawn.", "高亮所有刷出来的实体。"))
local EntityColorCfg = L("col.entity", "实体 颜色", "Entities Color")
EntityColorCfg.Default = Color3.fromRGB(255, 0, 0)
Options.EntityESPColor = Mini.ColorPicker(tabESP.Page, EntityColorCfg)

Mini.Label(tabESP.Page, L("esp.entitylist.note",
    "Entity List 默认一个都不选（和原版 AllowNull 一样），点开下面的列表勾实体。",
    "Entity List starts with nothing selected (same as the original AllowNull). Open the list below and tick entities."))
Options.EntityESPOptions = Mini.MultiSelect(tabESP.Page, {
    Key = "esp.entitylist", Text = "实体列表",
    Values = EntityListValues, Default = {},
})
Mini.Button(tabESP.Page, L("btn.all",  "全选",   "Select All"))
    :OnClick(function() Options.EntityESPOptions:SetAll(true) end)
Mini.Button(tabESP.Page, L("btn.none", "全不选", "Clear"))
    :OnClick(function() Options.EntityESPOptions:SetAll(false) end)

--────────────────────────── ESP 设置 ──────────────────────────
Toggles.ESPRainbow = Mini.Toggle(tabSet.Page, L(
    "set.rainbow", "彩虹效果", "Rainbow Effect",
    "Makes the esp objects change colour like a rainbow.",
    "让 ESP 颜色像彩虹一样流动。"))
local ShowDistanceCfg = L("set.showdist", "显示距离", "Show Distance",
    "Shows how far away your character is from the object.",
    "在名字下面额外显示距离。")
ShowDistanceCfg.Default = true
Toggles.ESPShowDistance = Mini.Toggle(tabSet.Page, ShowDistanceCfg)
Mini.Divider(tabSet.Page)

Options.ESPFillTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.fill", Text = "填充透明度", Min = 0, Max = 1, Default = 0.75, Rounding = 2 })
Options.ESPOutlineTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.outline", Text = "轮廓透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.text", Text = "文字透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextOutlineTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.textoutline", Text = "文字描边透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPFadeTime = Mini.Slider(tabSet.Page, {
    Key = "set.fade", Text = "淡出时间", Min = 0, Max = 1, Default = 0.25, Rounding = 2 })
Options.ESPRenderLimit = Mini.Slider(tabSet.Page, {
    Key = "set.render", Text = "渲染上限", Min = 30, Max = 240, Default = 240, Rounding = 0 })
Options.ESPTextSize = Mini.Slider(tabSet.Page, {
    Key = "set.textsize", Text = "文字大小", Min = 12, Max = 24, Default = 20, Rounding = 0 })
Options.ESPTextFont = Mini.Dropdown(tabSet.Page, {
    Key = "set.font", Text = "文字字体", Values = FontValues, Default = 12 })

Mini.Divider(tabSet.Page)
Options.ESPTracersOrigin = Mini.Dropdown(tabSet.Page, {
    Key = "set.tracerorigin", Text = "连线起点",
    Values = { "Bottom", "Center", "Top", "Mouse" }, Default = 1 })
Options.ESPTracerThickness = Mini.Slider(tabSet.Page, {
    Key = "set.tracerthick", Text = "连线粗细", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2 })
Toggles.ESPTracersToggle = Mini.Toggle(tabSet.Page, L(
    "set.tracers", "开启连线", "Enable Tracers",
    "Draws a line to highlighted objects.", "从屏幕底部拉一条线指向高亮对象。"))

Mini.Divider(tabSet.Page)
Options.ESPArrowsRadius = Mini.Slider(tabSet.Page, {
    Key = "set.arrowradius", Text = "箭头半径", Min = 100, Max = 500, Default = 250, Rounding = 0 })
Toggles.ESPArrowsToggle = Mini.Toggle(tabSet.Page, L(
    "set.arrows", "开启箭头", "Enable Arrows",
    "Shows arrow that point to off-screen objects.", "屏幕外对象显示指向箭头。"))

Mini.Divider(tabSet.Page)
Mini.Label(tabSet.Page, L("set.hidetext.note",
    "下面的开关等于把「文字透明度」一键拉到 1：只留轮廓，一个名字都不显示。",
    "The switch below is a shortcut for pulling Text Transparency to 1: outlines only, no names."))
local TextOffToggle = Mini.Toggle(tabSet.Page, L(
    "set.hidetext", "隐藏 ESP 文字", "Hide ESP Text",
    "Same as Text Transparency = 1.", "等同于把文字透明度设成 1。"))
TextOffToggle:OnChanged(function(Value)
    Options.ESPTextTransparency:Set(Value and 1 or 0, true)
    ESPLibrary:SetTextTransparency(Value and 1 or 0)
end)
Options.ESPTextTransparency:OnChanged(function(Value)
    TextOffToggle:Set(Value >= 1, true)
end)

local UIKeybind = Mini.Keybind(tabSet.Page, {
    Key = "set.uikey", Text = "界面开关键", Default = Enum.KeyCode.RightShift })

--────────────────────────── 相机：FOV + 场景高亮 + 除雾 ──────────────────────────
local FovToggleCfg = L("cam.fov", "自定义视野", "Custom FOV",
    "Only applies the Field of View slider when enabled.",
    "只有在开着的时候视野滑条才生效。")
FovToggleCfg.Default = true
Toggles.FOVToggle = Mini.Toggle(tabCam.Page, FovToggleCfg)
Options.FieldOfView = Mini.Slider(tabCam.Page, {
    Key = "cam.fovslider", Text = "视野", Min = 1, Max = 120, Default = 120, Rounding = 0 })
local FovKeybind = Mini.Keybind(tabCam.Page, {
    Key = "cam.fovkey", Text = "视野快捷键", Default = Enum.KeyCode.O })

Mini.Divider(tabCam.Page)
Toggles.AmbientToggle = Mini.Toggle(tabCam.Page, L(
    "cam.ambient", "场景高亮", "Ambient",
    "Changes the lighting color to the specified value.",
    "把环境光强行拉成指定颜色，整个场景提亮。"))
local AmbientColorCfg = L("cam.ambientcolor", "环境光颜色", "Ambient Color")
AmbientColorCfg.Default = Color3.fromRGB(255, 255, 255)
Options.AmbientColor = Mini.ColorPicker(tabCam.Page, AmbientColorCfg)

Toggles.RemoveCameraFog = Mini.Toggle(tabCam.Page, L(
    "cam.fog", "除雾", "Remove Fog",
    "Removes all fog effects from the camera.",
    "把 FogEnd 拉满 + 所有 Atmosphere.Density 归零，远景不再灰蒙蒙。"))
Mini.Label(tabCam.Page, L("cam.note",
    "「场景高亮」每帧守着 Lighting.Ambient —— Doors 每进房间都会用 0.2 秒把它 Tween 回暗值，设一次没用；"
    .. "「除雾」改 FogEnd 和 Atmosphere.Density，游戏改回来也会被按回去。两个都跟 ESP 无关，关掉会还原。",
    "Ambient is re-applied every frame because Doors tweens Lighting.Ambient back to the room's dark value; "
    .. "Remove Fog forces FogEnd and every Atmosphere.Density back. Both are independent of the ESP settings and restore on disable."))

--────────────────────────── 角色：速度 / 穿墙 ──────────────────────────
Options.SpeedBoostSlider = Mini.Slider(tabChar.Page, {
    Key = "char.speedslider", Text = "速度加成", Min = 0, Max = 100, Default = 0, Rounding = 0 })
Toggles.SpeedBoostToggle = Mini.Toggle(tabChar.Page, L(
    "char.speed", "开启速度加成", "Enable Speed Boost",
    "Increases your walkspeed by the specified amount.",
    "在游戏当前移速上加你设定的数值。"))
Mini.Divider(tabChar.Page)
Toggles.NoclipToggle = Mini.Toggle(tabChar.Page, L(
    "char.noclip", "穿墙", "Noclip",
    "Allows your character to pass through solid objects.",
    "角色可以穿墙（每帧把 CanCollide 关掉）。"))
local NoclipKeybind = Mini.Keybind(tabChar.Page, {
    Key = "char.noclipkey", Text = "穿墙快捷键", Default = Enum.KeyCode.N })
Mini.Label(tabChar.Page, L("char.note",
    "速度是「游戏当前移速 + 加成」，药水、受伤、下蹲这些游戏自己的修正都算在内，所以不会把游戏的速度改坏。"
    .. "穿墙单独用会被 Doors 的反作弊拉回来，想稳就先开「绕过」那页的反作弊绕过（去爬一次梯子）。",
    "Speed is the game's current walkspeed plus your bonus, so potions/injuries/crouching still count. "
    .. "Noclip alone gets pulled back by Doors' anticheat; enable Anticheat Bypass on the Bypass tab (climb a ladder once) for a stable one."))

--────────────────────────── 绕过 ──────────────────────────
Toggles.DisableAnticheat = Mini.Toggle(tabBypass.Page, L(
    "by.anti", "反作弊绕过", "Anticheat Bypass",
    "Completely disables the anticheat, after interacting with a ladder.",
    "开好后去爬一次梯子，游戏的反作弊就会被关掉。"))
Lang.Strings.zh["by.anti.on"] = "当前状态：反作弊已关闭"
Lang.Strings.en["by.anti.on"] = "Status: anticheat disabled"

local Anticheat = { Disabled = false }
local function AnticheatText()
    if Anticheat.Disabled then
        return Lang.T("by.anti.on") or "anticheat disabled"
    end
    return Lang.T("by.anti.off") or "anticheat active"
end

local AnticheatStatus = Mini.Label(tabBypass.Page, L("by.anti.off",
    "当前状态：未关闭反作弊", "Status: anticheat still active"))
Lang.BindFn(AnticheatStatus, AnticheatText)
Mini.Divider(tabBypass.Page)
Toggles.VelocityManipulationToggle = Mini.Toggle(tabBypass.Page, L(
    "by.vel", "速度操控（防拉回）", "Velocity Manipulation",
    "Moves your character forward slowly, mitigating the game's anti-noclip.",
    "持续往前推，让游戏的反穿墙判定误以为你在正常移动。"))
Options.VelocityManipulationMode = Mini.Dropdown(tabBypass.Page, {
    Key = "by.velmode", Text = "操控方式", Values = { "Velocity", "Pivot" }, Default = 1 })
local VelocityKeybind = Mini.Keybind(tabBypass.Page, {
    Key = "by.velkey", Text = "速度操控快捷键", Default = Enum.KeyCode.V })
Mini.Label(tabBypass.Page, L("by.vel.note",
    "Velocity：给角色挂一个 2.25 的前向速度，最稳，推荐。"
    .. "Pivot：直接往前 PivotTo 2560 studs（穿墙用），Fools / OldHotel 层原版会跳过。",
    "Velocity: a constant 2.25 forward velocity, the stable option. "
    .. "Pivot: PivotTo 2560 studs forward each frame (wall phasing); skipped on Fools / OldHotel like the original."))

--────────────────────────── Creak 愤怒值（右下角） ──────────────────────────
Toggles.CreakAggressionMeter = Mini.Toggle(tabCreak.Page, L(
    "creak.meter", "Creak 愤怒值（右下角）", "Creak Aggression Meter (bottom-right)",
    "Shows Creak's aggression in the bottom-right corner.",
    "在屏幕右下角常驻显示 Creak 的愤怒值。"))
Mini.Label(tabCreak.Page, L("creak.note",
    "这块是独立的 HUD：固定贴在屏幕右下角，用 Drawing 画的，"
    .. "完全不受 ESP 设置（透明度 / 淡出 / 渲染上限 / 文字开关）影响。"
    .. "Creak 没出现时显示 --%。读的是 CreakGraph 动画轨道的 Aggression 参数。",
    "This is a standalone HUD pinned to the bottom-right corner, drawn with Drawing, so none of the "
    .. "ESP settings (transparency / fade / render limit / text toggle) affect it. Shows --% while Creak is absent. "
    .. "The value comes from the CreakGraph animation track's Aggression parameter."))

--=====================================================================
-- 6. 原版 ESP 库设置（数值照抄 Main.luau 5443-5458 行）
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
    for _, Object in ipairs(Objects.HidingSpots) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
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
    return Label
end

local function EntityPass(Value, Object)
    if not Value then
        Functions.RemoveESP(Object)
        return
    end
    local Label = EntityLabel(Object)
    if Label and Options.EntityESPOptions.Value[Label] then
        Functions.AddESP({ Object = Object, Text = Label,
            Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
    else
        Functions.RemoveESP(Object)
    end
end

Toggles.EntityESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Entities) do EntityPass(Value, Object) end
end)
Options.EntityESPOptions:OnChanged(function()
    for _, Object in ipairs(Objects.Entities) do
        EntityPass(Toggles.EntityESPToggle.Value, Object)
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
            if Object.Name == "StairwellFireAlarm" then
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

-- 任务分类：闸门（原版 Misc 里那条 StairwellLockpickDoor 分支）
Toggles.TaskESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Tasks) do
        if Value then
            Functions.AddESP({ Object = Object, Text = "Garage Door",
                Color = Options.TaskESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.TaskESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Tasks) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
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
    for _, Object in ipairs(Objects.Objectives) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
end)

-- 原版玩家 ESP 的加入 / 离开跟踪
local function WatchPlayer(Player)
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
end

for _, Player in ipairs(Services.Players:GetPlayers()) do WatchPlayer(Player) end
Connections.PlayerHandler = Services.Players.PlayerAdded:Connect(WatchPlayer)

--=====================================================================
-- 8. 视野 FOV + 场景高亮 + 除雾
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

local FovCamera = Services.Workspace.CurrentCamera

-- 原版 6774-6781 行：RenderStepped 每帧设一次，优先走游戏自己的 fovtarget
Connections.FovHandler = Services.RunService.RenderStepped:Connect(function()
    if not Toggles.FOVToggle.Value then return end

    local Camera = Services.Workspace:FindFirstChild("Camera")
    if not Camera then
        Camera = Services.Workspace.CurrentCamera
    end
    FovCamera = Camera
    if not FovCamera then return end

    if MainGame then
        task.wait()
        MainGame.fovtarget = Options.FieldOfView.Value
    else
        FovCamera.FieldOfView = Options.FieldOfView.Value
    end
end)

--────────────────────────── 场景高亮（原版 AmbientToggle） ──────────────────────────
local Lighting = Services.Lighting

local SceneOriginal = {
    Ambient = Lighting.Ambient,
    FogEnd  = Lighting.FogEnd,
}
local AtmoOriginal = {}

local AmbientConn, FogConn, AtmoAddedConn
local AtmoConns = {}

local function DisconnectScene()
    if AmbientConn then AmbientConn:Disconnect() AmbientConn = nil end
    if FogConn then FogConn:Disconnect() FogConn = nil end
    if AtmoAddedConn then AtmoAddedConn:Disconnect() AtmoAddedConn = nil end
    for _, c in ipairs(AtmoConns) do pcall(function() c:Disconnect() end) end
    AtmoConns = {}
end

Toggles.AmbientToggle:OnChanged(function(Value)
    if Value then
        SceneOriginal.Ambient = Lighting.Ambient
        Lighting.Ambient = Options.AmbientColor.Value
        -- Doors 每进房间都会用 0.2 秒 Tween 把 Ambient 拉回暗值，
        -- 所以必须每帧守着；RenderStepped 在渲染之前跑，画面不会闪暗。
        AmbientConn = Services.RunService.RenderStepped:Connect(function()
            if Toggles.AmbientToggle.Value
                and Lighting.Ambient ~= Options.AmbientColor.Value then
                Lighting.Ambient = Options.AmbientColor.Value
            end
        end)
    else
        if AmbientConn then AmbientConn:Disconnect() AmbientConn = nil end
        Lighting.Ambient = SceneOriginal.Ambient
    end
end)
Options.AmbientColor:OnChanged(function(Value)
    if Toggles.AmbientToggle.Value then Lighting.Ambient = Value end
end)

--────────────────────────── 除雾（原版 RemoveCameraFog） ──────────────────────────
local function WatchAtmosphere(Object)
    if not Object:IsA("Atmosphere") then return end
    if AtmoOriginal[Object] == nil then AtmoOriginal[Object] = Object.Density end

    local Conn = Object:GetPropertyChangedSignal("Density"):Connect(function()
        if Object.Density ~= 0 then AtmoOriginal[Object] = Object.Density end
        if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
    end)
    table.insert(AtmoConns, Conn)

    if Toggles.RemoveCameraFog.Value and Object.Density ~= 0 then
        AtmoOriginal[Object] = Object.Density
        Object.Density = 0
    end
end

Toggles.RemoveCameraFog:OnChanged(function(Value)
    if Value then
        SceneOriginal.FogEnd = Lighting.FogEnd
        Lighting.FogEnd = 10000000

        for _, Object in ipairs(Lighting:GetChildren()) do WatchAtmosphere(Object) end
        AtmoAddedConn = Lighting.DescendantAdded:Connect(function(Object)
            if Toggles.RemoveCameraFog.Value then WatchAtmosphere(Object) end
        end)

        FogConn = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if Lighting.FogEnd ~= 10000000 then
                SceneOriginal.FogEnd = Lighting.FogEnd
                if Toggles.RemoveCameraFog.Value then
                    Lighting.FogEnd = 10000000
                end
            end
        end)
    else
        if FogConn then FogConn:Disconnect() FogConn = nil end
        if AtmoAddedConn then AtmoAddedConn:Disconnect() AtmoAddedConn = nil end
        for _, c in ipairs(AtmoConns) do pcall(function() c:Disconnect() end) end
        AtmoConns = {}

        Lighting.FogEnd = SceneOriginal.FogEnd
        for Object, Density in pairs(AtmoOriginal) do
            if Object.Parent then Object.Density = Density end
        end
        AtmoOriginal = {}
    end
end)

--=====================================================================
-- 9. 角色：速度加成 / 穿墙
--=====================================================================
local Char = { Character = nil, Humanoid = nil, RootPart = nil }

-- 原版 6559-6560 行：只设 MaxForce，别的一个都不动
local ManipulateBody = Instance.new("BodyVelocity")
ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

local function GetLiveModifiers()
    return Services.ReplicatedStorage:FindFirstChild("LiveModifiers")
end

local function IsCrouching()
    if not Char.Character then return false end
    if Floor == "Fools" or Floor == "OldHotel" then
        return Char.Character:GetAttribute("Crouching") == true
    end
    local CP = Char.Character:FindFirstChild("CollisionPart")
        or Char.Character:FindFirstChild("Collision")
    if CP then return CP.CollisionGroup == "PlayerCrouching" end
    return Char.Character:GetAttribute("Crouching") == true
end

local function GetInjuriesSpeed()
    if not Char.Humanoid then return 0 end
    return 0.075 * (Char.Humanoid.MaxHealth - Char.Humanoid.Health)
end

-- 原版 Functions.GetCurrentSpeed（Main.luau 868 行）
local function GetCurrentSpeed()
    local Speed = 15
    if Char.Character then
        Speed = Speed + (Char.Character:GetAttribute("SpeedBoost") or 0)
        Speed = Speed + (Char.Character:GetAttribute("SpeedBoostBehind") or 0)
        Speed = Speed + (Char.Character:GetAttribute("SpeedBoostExtra") or 0)
    end
    if Floor == "Party" then Speed = Speed + 10 end

    local LiveModifiers = GetLiveModifiers()
    if LiveModifiers then
        if LiveModifiers:FindFirstChild("PlayerFast") then Speed = Speed + 3 end
        if LiveModifiers:FindFirstChild("PlayerFaster") then Speed = Speed + 6 end
        if LiveModifiers:FindFirstChild("PlayerFastest") then Speed = Speed + 20 end
        if LiveModifiers:FindFirstChild("PlayerSlow") then Speed = Speed - 3 end
        if LiveModifiers:FindFirstChild("PlayerSlowHealth") then
            Speed = Speed - GetInjuriesSpeed()
        end
    end

    if IsCrouching() then
        if LiveModifiers and LiveModifiers:FindFirstChild("PlayerCrouchSlow") then
            Speed = Speed - 8
        elseif LiveModifiers and LiveModifiers:FindFirstChild("PlayerSlow") then
            Speed = Speed - 8
        else
            Speed = Speed - 5
        end
    end
    return Speed
end

local function SetupCharacter(Character)
    if not Character then return end
    Char.Character = Character
    Char.Humanoid = Character:FindFirstChildOfClass("Humanoid")
    Char.RootPart = Character:FindFirstChild("HumanoidRootPart")
        or Character.PrimaryPart
        or Character:FindFirstChildWhichIsA("BasePart")
end

SetupCharacter(LocalPlayer.Character)
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(SetupCharacter)

Toggles.SpeedBoostToggle:OnChanged(function(Value)
    if Char.Humanoid then
        Char.Humanoid.WalkSpeed = GetCurrentSpeed()
            + (Value and Options.SpeedBoostSlider.Value or 0)
    end
end)
Options.SpeedBoostSlider:OnChanged(function(Value)
    if Toggles.SpeedBoostToggle.Value and Char.Humanoid then
        Char.Humanoid.WalkSpeed = GetCurrentSpeed() + Value
    end
end)

Connections.CharacterLoop = Services.RunService.RenderStepped:Connect(function()
    local Character, Humanoid, RootPart = Char.Character, Char.Humanoid, Char.RootPart
    if not Character or not Humanoid or not RootPart or not RootPart.Parent then return end
    if Humanoid.Health <= 0 then return end

    if Toggles.SpeedBoostToggle.Value then
        Humanoid.WalkSpeed = GetCurrentSpeed() + Options.SpeedBoostSlider.Value
    end

    local Noclip = Toggles.NoclipToggle.Value
    local VelocityManip = Toggles.VelocityManipulationToggle.Value

    if Noclip or VelocityManip then
        RootPart.CanCollide = false
        if Noclip then
            for _, Part in ipairs(Character:GetChildren()) do
                if Part:IsA("BasePart") then Part.CanCollide = false end
            end
        end
    end

    if VelocityManip and Options.VelocityManipulationMode.Value == "Velocity" then
        ManipulateBody.Parent = RootPart
        ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
    elseif ManipulateBody.Parent then
        ManipulateBody.Parent = nil
    end

    if VelocityManip and Options.VelocityManipulationMode.Value == "Pivot"
        and Floor ~= "Fools" and Floor ~= "OldHotel" then
        local cam = Services.Workspace.CurrentCamera
        if cam then
            Character:PivotTo(cam:GetPivot() * CFrame.new(0, 0, 2560))
        end
    end
end)

--=====================================================================
-- 10. 绕过：反作弊绕过
--=====================================================================
local RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")

local function SetAnticheatStatus()
    if AnticheatStatus then AnticheatStatus.Text = AnticheatText() end
end

Connections.AnticheatDisabler = LocalPlayer.CharacterAdded:Connect(function(Character)
    local ClimbConn = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
        if Character:GetAttribute("Climbing") ~= true then return end
        if not Toggles.DisableAnticheat.Value or Anticheat.Disabled then return end
        task.wait(0.25)
        Character:SetAttribute("Climbing", false)
        Anticheat.Disabled = true
        SetAnticheatStatus()
    end)
    table.insert(Connections, ClimbConn)
end)

if LocalPlayer.Character then
    local Character = LocalPlayer.Character
    local ClimbConn = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
        if Character:GetAttribute("Climbing") ~= true then return end
        if not Toggles.DisableAnticheat.Value or Anticheat.Disabled then return end
        task.wait(0.25)
        Character:SetAttribute("Climbing", false)
        Anticheat.Disabled = true
        SetAnticheatStatus()
    end)
    table.insert(Connections, ClimbConn)
end

task.spawn(function()
    if not RemotesFolder then
        local ok, res = pcall(function()
            return Services.ReplicatedStorage:WaitForChild("RemotesFolder", 60)
        end)
        if ok then RemotesFolder = res end
    end
    if not RemotesFolder then return end

    local Cutscene = RemotesFolder:WaitForChild("Cutscene", 30)
    if Cutscene then
        Connections.AnticheatEnableDetector1 = Cutscene.OnClientEvent:Connect(function(Name)
            if Anticheat.Disabled and typeof(Name) == "string"
                and not Name:find("SewerSeek") then
                Anticheat.Disabled = false
                SetAnticheatStatus()
            end
        end)
    end

    local UseEnemyModule = RemotesFolder:WaitForChild("UseEnemyModule", 30)
    if UseEnemyModule then
        Connections.AnticheatEnableDetector2 = UseEnemyModule.OnClientEvent:Connect(function(Name)
            if Name == "Void" or Name == "Glitch" then
                if Anticheat.Disabled then
                    Anticheat.Disabled = false
                    SetAnticheatStatus()
                end
            end
        end)
    end
end)

Toggles.DisableAnticheat:OnChanged(function(Value)
    if Anticheat.Disabled and not Value then
        local Folder = RemotesFolder
            or Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
        local Rem = Folder and Folder:FindFirstChild("ClimbLadder")
        if Rem then pcall(function() Rem:FireServer() end) end
        Anticheat.Disabled = false
    end
    SetAnticheatStatus()
end)

--=====================================================================
-- 11. Creak 愤怒值 —— 屏幕右下角常驻 HUD（Drawing，与 ESP 设置无关）
--=====================================================================
local CreakCamera = Services.Workspace.CurrentCamera
local HUD = {
    Drawings = {},
    Panel = nil, Title = nil, BarBG = nil, BarFill = nil,
}

local function CreateHudDrawing(kind)
    local d = Drawing.new(kind)
    table.insert(HUD.Drawings, d)
    return d
end

local function BuildHud()
    if HUD.Title then return end

    HUD.Panel = CreateHudDrawing("Square")
    HUD.Panel.Filled = true
    HUD.Panel.Color = Color3.fromRGB(12, 14, 18)
    HUD.Panel.Transparency = 0.35
    HUD.Panel.Visible = false

    HUD.Title = CreateHudDrawing("Text")
    HUD.Title.Text = "Aggression --%"
    HUD.Title.Size = 15
    HUD.Title.Font = (Drawing.Fonts and (Drawing.Fonts.Plex or Drawing.Fonts.UI)) or 1
    HUD.Title.Color = Color3.fromRGB(255, 255, 255)
    HUD.Title.Center = false
    HUD.Title.Outline = true
    HUD.Title.Visible = false

    HUD.BarBG = CreateHudDrawing("Square")
    HUD.BarBG.Size = Vector2.new(200, 8)
    HUD.BarBG.Filled = true
    HUD.BarBG.Color = Color3.fromRGB(58, 58, 64)
    HUD.BarBG.Transparency = 0.15
    HUD.BarBG.Visible = false

    HUD.BarFill = CreateHudDrawing("Square")
    HUD.BarFill.Size = Vector2.new(0, 8)
    HUD.BarFill.Filled = true
    HUD.BarFill.Visible = false
end

local function HideHud()
    if not HUD.Title then return end
    HUD.Panel.Visible = false
    HUD.Title.Visible = false
    HUD.BarBG.Visible = false
    HUD.BarFill.Visible = false
end

local function DestroyHud()
    for _, d in ipairs(HUD.Drawings) do pcall(function() d:Remove() end) end
    HUD.Drawings = {}
    HUD.Panel, HUD.Title, HUD.BarBG, HUD.BarFill = nil, nil, nil, nil
end

-- 读 CreakGraph 动画轨道的 Aggression 参数（原版方法）
local function GetCreakAggression(Model)
    if not Model then return nil end
    local Animator = Model:FindFirstChildOfClass("Animator")
        or (Model:FindFirstChild("AnimationController")
            and Model.AnimationController:FindFirstChildOfClass("Animator"))
        or Model:FindFirstChildOfClass("AnimationController")
    if not Animator then return nil end

    local ok, Tracks = pcall(function() return Animator:GetPlayingAnimationTracks() end)
    if not ok or not Tracks then return nil end

    for _, Track in ipairs(Tracks) do
        local IsCreakGraph = Track.Name == "CreakGraph"
            or (Track.Animation and Track.Animation.Name == "CreakGraph")
        if IsCreakGraph then
            local ok2, Value = pcall(Track.GetParameter, Track, "Aggression")
            if ok2 and type(Value) == "number" then
                return math.clamp(Value, 0, 1)
            end
        end
    end
    return nil
end

local function FindCreak()
    local Folder = Services.Workspace:FindFirstChild("LiveEntities")
    if not Folder then return nil end
    local Model = Folder:FindFirstChild("Creak")
    if Model and Model.Parent then return Model end
    return nil
end

Toggles.CreakAggressionMeter:OnChanged(function(Value)
    if Value then
        if not Drawing then
            warn("[DoorsESPX] 执行器没有 Drawing API，Creak 愤怒值 HUD 无法显示")
            return
        end
        BuildHud()
    else
        HideHud()
    end
end)

Connections.CreakHud = Services.RunService.RenderStepped:Connect(function()
    if not Toggles.CreakAggressionMeter.Value then return end
    if not HUD.Title then return end

    if not CreakCamera or not CreakCamera.Parent then
        CreakCamera = Services.Workspace.CurrentCamera
        if not CreakCamera then return end
    end

    local Viewport = CreakCamera.ViewportSize
    local W, H = 240, 52
    local X = Viewport.X - W - 20
    local Y = Viewport.Y - H - 20

    HUD.Panel.Position = Vector2.new(X, Y)
    HUD.Panel.Size = Vector2.new(W, H)
    HUD.Title.Position = Vector2.new(X + 12, Y + 8)
    HUD.BarBG.Position = Vector2.new(X + 12, Y + 32)
    HUD.BarBG.Size = Vector2.new(W - 24, 8)
    HUD.BarFill.Position = HUD.BarBG.Position

    HUD.Panel.Visible = true
    HUD.Title.Visible = true
    HUD.BarBG.Visible = true

    local Value = GetCreakAggression(FindCreak())
    if not Value then
        HUD.Title.Text = "Aggression --%"
        HUD.Title.Color = Color3.fromRGB(190, 190, 190)
        HUD.BarFill.Visible = false
        return
    end

    HUD.Title.Text = "Aggression " .. math.floor(Value * 100 + 0.5) .. "%"
    HUD.Title.Color = Color3.fromRGB(255, 255, 255)
    HUD.BarFill.Size = Vector2.new((W - 24) * Value, 8)
    HUD.BarFill.Color = Color3.fromRGB(70, 220, 100)
        :Lerp(Color3.fromRGB(255, 55, 55), Value)
    HUD.BarFill.Visible = true
end)

--=====================================================================
-- 12. 快捷键 / 启动 / 卸载
--=====================================================================
Connections.Input = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == UIKeybind.Key then Window:Toggle() end
    if input.KeyCode == FovKeybind.Key then
        Toggles.FOVToggle:Set(not Toggles.FOVToggle.Value)
    end
    if input.KeyCode == NoclipKeybind.Key then
        Toggles.NoclipToggle:Set(not Toggles.NoclipToggle.Value)
    end
    if input.KeyCode == VelocityKeybind.Key then
        Toggles.VelocityManipulationToggle:Set(
            not Toggles.VelocityManipulationToggle.Value)
    end
end)

if not Drawing then
    warn("[DoorsESPX] 你的执行器没有 Drawing API，Creak 愤怒值 HUD 不会显示（原版也是用 Drawing）")
end

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

    DisconnectScene()
    DestroyHud()

    if ManipulateBody then
        pcall(function() ManipulateBody:Destroy() end)
    end

    if Toggles.AmbientToggle.Value or Toggles.RemoveCameraFog.Value then
        pcall(function()
            Lighting.Ambient = SceneOriginal.Ambient
            Lighting.FogEnd = SceneOriginal.FogEnd
            for Object, Density in pairs(AtmoOriginal) do
                if Object.Parent then Object.Density = Density end
            end
        end)
    end

    pcall(function() ESPLibrary:Unload() end)
    pcall(function() Window.Gui:Destroy() end)

    if getgenv()[STATE_KEY] == Module then
        getgenv()[STATE_KEY] = nil
    end
    print("[DoorsESPX] 已卸载")
end

-- 测试 / 调试用：暴露内部表（不改任何行为）
Module.Objects = Objects
Module.Toggles = Toggles
Module.Options = Options
Module.Char = Char
Module.Lang = Lang
Module.Anticheat = Anticheat

getgenv()[STATE_KEY] = Module

print("[DoorsESPX] 载入完成 · ESP 开关默认全关（同原版）")
print("[DoorsESPX] " .. tostring(UIKeybind.Key.Name) .. " 开关界面 · "
    .. tostring(FovKeybind.Key.Name) .. " 视野 · "
    .. tostring(NoclipKeybind.Key.Name) .. " 穿墙 · "
    .. tostring(VelocityKeybind.Key.Name) .. " 速度操控")
print("[DoorsESPX] 卸载 getgenv().DoorsESPX.Unload()")

return Module

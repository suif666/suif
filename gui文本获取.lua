--[[

UI文本提取器 - 新UI重构版
风格参考：你给的设计图
功能：
1. 分区扫描文本
2. 搜索
3. 刷新
4. 自动刷新（勾选）
5. 单行 复制 / 删除 / 收藏
6. 收藏栏独立窗口
7. 导出当前分区为Lua
8. 导出收藏栏为Lua

注意：
- 这是 Roblox Lua 本地脚本风格
- 如执行器支持 setclipboard / writefile，会启用复制/导出功能

]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

pcall(function()
    if CoreGui:FindFirstChild("UI_Text_Collector_NewStyle") then
        CoreGui.UI_Text_Collector_NewStyle:Destroy()
    end
end)

pcall(function()
    if PlayerGui:FindFirstChild("UI_Text_Collector_NewStyle") then
        PlayerGui.UI_Text_Collector_NewStyle:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UI_Text_Collector_NewStyle"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = PlayerGui
end

--====================================================
-- 数据区
--====================================================

local Sections = {
    "全部",
    "PlayerGui",
    "Workspace",
    "CoreGui",
    "RobloxGui",
    "PlayerList",
    "第三方UI",
}

local CurrentSection = "全部"
local AutoRefresh = false
local AutoRefreshInterval = 1.8
local BlockMode = false
local CurrentDisplayText = ""
local Minimized = false

local SectionData = {}
local SectionButtons = {}

for _, name in ipairs(Sections) do
    SectionData[name] = {
        Texts = {},
        Map = {},
        AllText = "未检测到 UI 文本",
    }
end

local BlockedData = {}
for _, name in ipairs(Sections) do
    BlockedData[name] = {}
end

local FavoriteData = {
    Texts = {},
    Map = {},
}

local RobloxSystemNames = {
    "RobloxGui",
    "PlayerList",
    "Backpack",
    "Chat",
    "BubbleChat",
    "ExperienceChat",
    "TextChatService",
    "TopBar",
    "Topbar",
    "Health",
    "EmotesMenu",
    "Chrome",
    "InspectMenu",
    "PurchasePrompt",
    "ScreenshotHud",
}

--====================================================
-- 工具函数
--====================================================

local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function AddCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = obj
    return c
end

local function AddStroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(110, 120, 155)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.Parent = obj
    return s
end

local function AddGradient(obj, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2),
    })
    g.Rotation = rot or 0
    g.Parent = obj
    return g
end

local function StyleGlass(obj, radius)
    obj.BackgroundColor3 = Color3.fromRGB(42, 49, 74)
    obj.BackgroundTransparency = 0.18
    AddCorner(obj, radius or 18)
    AddStroke(obj, Color3.fromRGB(150, 160, 210), 1, 0.5)
end

local function StyleButton(btn, radius)
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    AddCorner(btn, radius or 14)
    AddStroke(btn, Color3.fromRGB(145, 155, 205), 1, 0.45)

    local normal = btn.BackgroundColor3
    local hover = Color3.fromRGB(
        math.clamp(normal.R * 255 + 10, 0, 255),
        math.clamp(normal.G * 255 + 10, 0, 255),
        math.clamp(normal.B * 255 + 10, 0, 255)
    )

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
    end)
end

local function CleanText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    text = text:gsub("\r", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function ContainsKeyword(text, list)
    text = string.lower(tostring(text or ""))
    for _, keyword in ipairs(list) do
        keyword = string.lower(tostring(keyword or ""))
        if keyword ~= "" and string.find(text, keyword, 1, true) then
            return true
        end
    end
    return false
end

local function CopyText(text, hint)
    text = tostring(text or "")
    if setclipboard then
        setclipboard(text)
        return true
    elseif toclipboard then
        toclipboard(text)
        return true
    end
    return false
end

local function EscapeLuaString(str)
    str = tostring(str or "")
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    str = str:gsub("\"", "\\\"")
    return str
end

local function GetObjectPath(obj)
    local names = {}
    local current = obj
    while current and current ~= game do
        table.insert(names, 1, current.Name)
        current = current.Parent
    end
    return table.concat(names, "/")
end

local function IsObjectVisible(obj)
    local current = obj
    while current and current ~= game do
        local ok, visible = pcall(function()
            return current.Visible
        end)
        if ok and visible == false then
            return false
        end
        current = current.Parent
    end
    return true
end

local function IsRobloxSystemObject(obj)
    local path = GetObjectPath(obj)
    if ContainsKeyword(obj.Name, RobloxSystemNames) then
        return true
    end
    if ContainsKeyword(path, RobloxSystemNames) then
        return true
    end
    return false
end

local function GetSectionCount(name)
    local data = SectionData[name]
    return data and #data.Texts or 0
end

local function RebuildSectionText(name)
    local data = SectionData[name]
    if not data then return end
    if #data.Texts == 0 then
        data.AllText = "未检测到 UI 文本"
    else
        data.AllText = table.concat(data.Texts, "\n")
    end
end

local function ShouldIgnoreText(text)
    text = CleanText(text)
    if text == "" then
        return true
    end
    if text == "未检测到 UI 文本" then
        return true
    end
    return false
end

local function IsTextBlocked(sectionName, text)
    text = CleanText(text)
    if not BlockMode then
        return false
    end
    return BlockedData[sectionName] and BlockedData[sectionName][text] == true
end

local function SaveTextToSection(sectionName, text)
    text = CleanText(text)
    if ShouldIgnoreText(text) then return false end
    if IsTextBlocked(sectionName, text) then return false end

    local data = SectionData[sectionName]
    if not data then return false end

    if not data.Map[text] then
        data.Map[text] = true
        table.insert(data.Texts, text)
        RebuildSectionText(sectionName)
        return true
    end

    return false
end

local function SaveTextWithSection(sourceSection, text)
    local added = false
    if SaveTextToSection(sourceSection, text) then
        added = true
        if sourceSection ~= "全部" then
            SaveTextToSection("全部", text)
        end
    end
    return added
end

local function BuildLuaExport(title, list)
    local lines = {}
    table.insert(lines, "-- " .. title)
    table.insert(lines, "return {")
    for _, text in ipairs(list) do
        table.insert(lines, '    "' .. EscapeLuaString(text) .. '",')
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

--====================================================
-- 主界面
--====================================================

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 1180, 0, 700),
    Position = UDim2.new(0.5, -590, 0.5, -350),
    BackgroundColor3 = Color3.fromRGB(42, 49, 74),
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Parent = ScreenGui,
})
StyleGlass(Main, 28)

local TitleLabel = New("TextLabel", {
    Size = UDim2.new(0, 600, 0, 60),
    Position = UDim2.new(0.5, -300, 0, -90),
    BackgroundTransparency = 1,
    Text = "UI文本提取器 - 分区版",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 32,
    Font = Enum.Font.GothamBold,
    Parent = ScreenGui,
})

local TopBar = New("Frame", {
    Size = UDim2.new(1, -40, 0, 44),
    Position = UDim2.new(0, 20, 0, 18),
    BackgroundTransparency = 1,
    Parent = Main,
})

local Dot1 = New("Frame", {
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(0, 8, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(255, 150, 85),
    BorderSizePixel = 0,
    Parent = TopBar,
})
AddCorner(Dot1, 99)

local Dot2 = New("Frame", {
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(0, 34, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(170, 170, 170),
    BorderSizePixel = 0,
    Parent = TopBar,
})
AddCorner(Dot2, 99)

local Dot3 = New("Frame", {
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(0, 60, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(147, 229, 98),
    BorderSizePixel = 0,
    Parent = TopBar,
})
AddCorner(Dot3, 99)

local MinBtn = New("TextButton", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(1, -100, 0, 0),
    BackgroundColor3 = Color3.fromRGB(70, 76, 100),
    Text = "–",
    TextColor3 = Color3.fromRGB(225, 230, 255),
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    Parent = TopBar,
})
StyleButton(MinBtn, 14)

local CloseBtn = New("TextButton", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(1, -50, 0, 0),
    BackgroundColor3 = Color3.fromRGB(201, 70, 78),
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Parent = TopBar,
})
StyleButton(CloseBtn, 14)

local ThemeBadge = New("TextButton", {
    Size = UDim2.new(0, 120, 0, 66),
    Position = UDim2.new(0, 30, 0, 98),
    BackgroundColor3 = Color3.fromRGB(38, 168, 255),
    Text = "渐变蓝",
    TextColor3 = Color3.fromRGB(240, 250, 255),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Parent = Main,
})
StyleButton(ThemeBadge, 18)
AddGradient(ThemeBadge, Color3.fromRGB(68, 236, 255), Color3.fromRGB(28, 99, 255), 0)

local ThemeStroke = ThemeBadge:FindFirstChildOfClass("UIStroke")
if ThemeStroke then
    ThemeStroke.Transparency = 0.2
end

local HeaderSearch = New("TextBox", {
    Size = UDim2.new(0, 250, 0, 48),
    Position = UDim2.new(0, 160, 0, 98),
    BackgroundColor3 = Color3.fromRGB(55, 62, 89),
    BackgroundTransparency = 0.1,
    Text = "",
    PlaceholderText = "LUU副本",
    PlaceholderColor3 = Color3.fromRGB(165, 172, 205),
    TextColor3 = Color3.fromRGB(240, 245, 255),
    TextSize = 18,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    Parent = Main,
})
StyleGlass(HeaderSearch, 16)

local HeaderSearchIcon = New("TextLabel", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(0, 14, 0.5, -12),
    BackgroundTransparency = 1,
    Text = "⌕",
    TextColor3 = Color3.fromRGB(200, 205, 230),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Parent = HeaderSearch,
})

HeaderSearch.TextXAlignment = Enum.TextXAlignment.Left
HeaderSearch.CursorPosition = -1
HeaderSearch.Text = "   "

HeaderSearch:GetPropertyChangedSignal("Text"):Connect(function()
    if HeaderSearch.Text == "" then
        HeaderSearch.Text = "   "
        HeaderSearch.CursorPosition = -1
    elseif string.sub(HeaderSearch.Text, 1, 3) ~= "   " then
        HeaderSearch.Text = "   " .. HeaderSearch.Text:gsub("^%s*", "")
        HeaderSearch.CursorPosition = #HeaderSearch.Text + 1
    end
end)

local SectionFrame = New("Frame", {
    Size = UDim2.new(1, -60, 0, 90),
    Position = UDim2.new(0, 30, 0, 175),
    BackgroundTransparency = 1,
    Parent = Main,
})

local function MakeSectionButton(name, index)
    local btn = New("TextButton", {
        Size = UDim2.new(0, 70, 0, 64),
        Position = UDim2.new(0, (index - 1) * 86, 0, 0),
        BackgroundColor3 = Color3.fromRGB(73, 82, 115),
        Text = name,
        TextColor3 = Color3.fromRGB(235, 240, 255),
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        Parent = SectionFrame,
    })
    StyleButton(btn, 18)
    SectionButtons[name] = btn
    return btn
end

for i, name in ipairs(Sections) do
    local btn = MakeSectionButton(name, i)
    btn.MouseButton1Click:Connect(function()
        CurrentSection = name
    end)
end

local SearchBar = New("TextBox", {
    Size = UDim2.new(0, 180, 0, 36),
    Position = UDim2.new(0, 30, 0, 270),
    BackgroundColor3 = Color3.fromRGB(58, 66, 94),
    BackgroundTransparency = 0.12,
    Text = "",
    PlaceholderText = "搜索文本",
    PlaceholderColor3 = Color3.fromRGB(155, 165, 198),
    TextColor3 = Color3.fromRGB(240, 245, 255),
    TextSize = 16,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    Parent = Main,
})
StyleGlass(SearchBar, 14)

local SearchIcon = New("TextButton", {
    Size = UDim2.new(0, 40, 0, 36),
    Position = UDim2.new(0, 220, 0, 270),
    BackgroundColor3 = Color3.fromRGB(58, 66, 94),
    Text = "⌕",
    TextColor3 = Color3.fromRGB(245, 250, 255),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Parent = Main,
})
StyleButton(SearchIcon, 14)

local RefreshBtn = New("TextButton", {
    Size = UDim2.new(0, 40, 0, 36),
    Position = UDim2.new(0, 268, 0, 270),
    BackgroundColor3 = Color3.fromRGB(58, 66, 94),
    Text = "⟳",
    TextColor3 = Color3.fromRGB(245, 250, 255),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Parent = Main,
})
StyleButton(RefreshBtn, 14)

local StatusLabel = New("TextLabel", {
    Size = UDim2.new(0, 350, 0, 30),
    Position = UDim2.new(1, -380, 0, 273),
    BackgroundTransparency = 1,
    Text = "状态：待机",
    TextColor3 = Color3.fromRGB(200, 210, 235),
    TextSize = 15,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = Main,
})

local ScrollHolder = New("Frame", {
    Size = UDim2.new(1, -60, 1, -260),
    Position = UDim2.new(0, 30, 0, 320),
    BackgroundTransparency = 1,
    Parent = Main,
})

local Scroll = New("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -100),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(46, 54, 81),
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 10,
    ScrollBarImageColor3 = Color3.fromRGB(110, 120, 165),
    Parent = ScrollHolder,
})
StyleGlass(Scroll, 18)

local ListLayout = New("UIListLayout", {
    Padding = UDim.new(0, 12),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = Scroll,
})

local BottomBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 80),
    Position = UDim2.new(0, 0, 1, -80),
    BackgroundTransparency = 1,
    Parent = ScrollHolder,
})

local BottomButtons = {}

local function MakeBottomButton(icon, key)
    local btn = New("TextButton", {
        Size = UDim2.new(0, 52, 0, 52),
        BackgroundColor3 = Color3.fromRGB(70, 78, 110),
        Text = icon,
        TextColor3 = Color3.fromRGB(235, 240, 255),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = BottomBar,
    })
    StyleButton(btn, 16)
    BottomButtons[key] = btn
    return btn
end

local RefreshSmall = MakeBottomButton("⟳", "refresh")
local FavoriteOpenBtn = MakeBottomButton("❐", "favorite")
local SearchRunBtn = MakeBottomButton("⌕", "search")
local AutoToggleBtn = MakeBottomButton("☐", "auto")
local CopyAllBtn = MakeBottomButton("☷", "copy")
local ExportBtn = MakeBottomButton("⚙", "export")
local BlockBtn = MakeBottomButton("◔", "block")
local SpacerLabel = New("TextLabel", {
    Size = UDim2.new(0, 40, 0, 52),
    BackgroundTransparency = 1,
    Text = "◇",
    TextColor3 = Color3.fromRGB(160, 170, 205),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    Parent = BottomBar,
})
local ClearBtn = MakeBottomButton("⌫", "clear")

local order = {RefreshSmall, FavoriteOpenBtn, SearchRunBtn, AutoToggleBtn, CopyAllBtn, ExportBtn, BlockBtn, SpacerLabel, ClearBtn}
for i, obj in ipairs(order) do
    obj.Position = UDim2.new(0, 360 + (i - 1) * 70, 0, 14)
end

local ResizeHandle = New("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -30, 1, -30),
    BackgroundColor3 = Color3.fromRGB(86, 94, 125),
    Text = "◢",
    TextColor3 = Color3.fromRGB(235, 240, 255),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = Main,
})
StyleButton(ResizeHandle, 10)

--====================================================
-- 收藏窗口
--====================================================

local FavoriteMain = New("Frame", {
    Size = UDim2.new(0, 520, 0, 430),
    Position = UDim2.new(0.5, -260, 0.5, -215),
    BackgroundColor3 = Color3.fromRGB(42, 49, 74),
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
    Draggable = true,
    Parent = ScreenGui,
})
StyleGlass(FavoriteMain, 24)

local FavoriteTitle = New("TextLabel", {
    Size = UDim2.new(1, -100, 0, 44),
    Position = UDim2.new(0, 20, 0, 14),
    BackgroundTransparency = 1,
    Text = "收藏列表",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = FavoriteMain,
})

local FavoriteClose = New("TextButton", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(1, -60, 0, 14),
    BackgroundColor3 = Color3.fromRGB(200, 70, 78),
    Text = "×",
    TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Parent = FavoriteMain,
})
StyleButton(FavoriteClose, 14)

local FavoriteStatus = New("TextLabel", {
    Size = UDim2.new(1, -40, 0, 24),
    Position = UDim2.new(0, 20, 0, 64),
    BackgroundTransparency = 1,
    Text = "收藏数量：0",
    TextColor3 = Color3.fromRGB(210, 220, 240),
    TextSize = 15,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = FavoriteMain,
})

local FavoriteScroll = New("ScrollingFrame", {
    Size = UDim2.new(1, -40, 1, -150),
    Position = UDim2.new(0, 20, 0, 96),
    BackgroundColor3 = Color3.fromRGB(46, 54, 81),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 8,
    ScrollBarImageColor3 = Color3.fromRGB(110, 120, 165),
    Parent = FavoriteMain,
})
StyleGlass(FavoriteScroll, 18)

local FavoriteLayout = New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = FavoriteScroll,
})

local FavoriteCopyAll = New("TextButton", {
    Size = UDim2.new(0.33, -10, 0, 40),
    Position = UDim2.new(0, 20, 1, -48),
    BackgroundColor3 = Color3.fromRGB(63, 123, 213),
    Text = "复制全部",
    TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = FavoriteMain,
})
StyleButton(FavoriteCopyAll, 14)

local FavoriteExport = New("TextButton", {
    Size = UDim2.new(0.33, -10, 0, 40),
    Position = UDim2.new(0.33, 5, 1, -48),
    BackgroundColor3 = Color3.fromRGB(67, 160, 186),
    Text = "导出Lua",
    TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = FavoriteMain,
})
StyleButton(FavoriteExport, 14)

local FavoriteClear = New("TextButton", {
    Size = UDim2.new(0.33, -10, 0, 40),
    Position = UDim2.new(0.66, -5, 1, -48),
    BackgroundColor3 = Color3.fromRGB(190, 76, 82),
    Text = "清空全部",
    TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = FavoriteMain,
})
StyleButton(FavoriteClear, 14)

--====================================================
-- 逻辑显示函数
--====================================================

local function UpdateStatus(msg)
    StatusLabel.Text = "状态：" .. tostring(msg or "待机")
end

local function UpdateSectionButtons()
    for name, btn in pairs(SectionButtons) do
        if name == CurrentSection then
            btn.BackgroundColor3 = Color3.fromRGB(38, 168, 255)
            local grad = btn:FindFirstChildOfClass("UIGradient")
            if not grad then
                AddGradient(btn, Color3.fromRGB(68, 236, 255), Color3.fromRGB(28, 99, 255), 0)
            end
        else
            btn.BackgroundColor3 = Color3.fromRGB(73, 82, 115)
            local grad = btn:FindFirstChildOfClass("UIGradient")
            if grad then grad:Destroy() end
        end
        btn.Text = name
    end
end

local function ResizeScrollCanvas()
    task.defer(function()
        task.wait()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
        FavoriteScroll.CanvasSize = UDim2.new(0, 0, 0, FavoriteLayout.AbsoluteContentSize.Y + 20)
    end)
end

local function BuildCurrentDisplay()
    local data = SectionData[CurrentSection]
    if not data then
        return "未检测到 UI 文本"
    end
    RebuildSectionText(CurrentSection)
    return data.AllText
end

local function RebuildAllSection()
    SectionData["全部"].Texts = {}
    SectionData["全部"].Map = {}
    SectionData["全部"].AllText = "未检测到 UI 文本"

    for _, name in ipairs(Sections) do
        if name ~= "全部" then
            for _, text in ipairs(SectionData[name].Texts) do
                SaveTextToSection("全部", text)
            end
        end
    end
    RebuildSectionText("全部")
end

local function RemoveTextFromSection(sectionName, text)
    local data = SectionData[sectionName]
    if not data then return end
    text = CleanText(text)
    data.Map[text] = nil
    for i = #data.Texts, 1, -1 do
        if data.Texts[i] == text then
            table.remove(data.Texts, i)
        end
    end
    RebuildSectionText(sectionName)
end

local function AddTextToFavorite(text)
    text = CleanText(text)
    if text == "" then return end
    if not FavoriteData.Map[text] then
        FavoriteData.Map[text] = true
        table.insert(FavoriteData.Texts, text)
    end
end

local function RefreshFavoriteUI()
    for _, child in ipairs(FavoriteScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, text in ipairs(FavoriteData.Texts) do
        local row = New("Frame", {
            Size = UDim2.new(1, -12, 0, 52),
            BackgroundColor3 = Color3.fromRGB(64, 74, 108),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = FavoriteScroll,
        })
        StyleGlass(row, 14)

        local label = New("TextButton", {
            Size = UDim2.new(1, -150, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Color3.fromRGB(245, 248, 255),
            TextSize = 15,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row,
        })

        local del = New("TextButton", {
            Size = UDim2.new(0, 52, 0, 34),
            Position = UDim2.new(1, -116, 0.5, -17),
            BackgroundColor3 = Color3.fromRGB(200, 78, 84),
            Text = "删",
            TextColor3 = Color3.fromRGB(255,255,255),
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            Parent = row,
        })
        StyleButton(del, 10)

        local cp = New("TextButton", {
            Size = UDim2.new(0, 52, 0, 34),
            Position = UDim2.new(1, -58, 0.5, -17),
            BackgroundColor3 = Color3.fromRGB(63, 123, 213),
            Text = "复",
            TextColor3 = Color3.fromRGB(255,255,255),
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            Parent = row,
        })
        StyleButton(cp, 10)

        cp.MouseButton1Click:Connect(function()
            CopyText(text)
            UpdateStatus("已复制收藏文本")
        end)

        del.MouseButton1Click:Connect(function()
            FavoriteData.Map[text] = nil
            for idx = #FavoriteData.Texts, 1, -1 do
                if FavoriteData.Texts[idx] == text then
                    table.remove(FavoriteData.Texts, idx)
                    break
                end
            end
            RefreshFavoriteUI()
        end)

        label.MouseButton1Click:Connect(function()
            CopyText(text)
            UpdateStatus("已复制收藏文本")
        end)
    end

    FavoriteStatus.Text = "收藏数量：" .. tostring(#FavoriteData.Texts)
    ResizeScrollCanvas()
end

local function SetDisplayText(text)
    CurrentDisplayText = text
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local idx = 0
    for line in string.gmatch(text .. "\n", "(.-)\n") do
        line = CleanText(line)
        if line ~= "" then
            idx = idx + 1
            local row = New("Frame", {
                Size = UDim2.new(1, -16, 0, 72),
                BackgroundColor3 = Color3.fromRGB(66, 76, 110),
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                Parent = Scroll,
            })
            StyleGlass(row, 18)

            local check = New("Frame", {
                Size = UDim2.new(0, 42, 0, 26),
                Position = UDim2.new(0, 16, 0.5, -13),
                BackgroundColor3 = Color3.fromRGB(123, 133, 173),
                BorderSizePixel = 0,
                Parent = row,
            })
            AddCorner(check, 8)

            local label = New("TextButton", {
                Size = UDim2.new(1, -270, 1, 0),
                Position = UDim2.new(0, 72, 0, 0),
                BackgroundTransparency = 1,
                Text = line,
                TextColor3 = Color3.fromRGB(242, 246, 255),
                TextSize = 16,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })

            local addBtn = New("TextButton", {
                Size = UDim2.new(0, 56, 0, 36),
                Position = UDim2.new(1, -184, 0.5, -18),
                BackgroundColor3 = Color3.fromRGB(88, 123, 212),
                Text = "藏",
                TextColor3 = Color3.fromRGB(255,255,255),
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                Parent = row,
            })
            StyleButton(addBtn, 12)

            local delBtn = New("TextButton", {
                Size = UDim2.new(0, 56, 0, 36),
                Position = UDim2.new(1, -122, 0.5, -18),
                BackgroundColor3 = Color3.fromRGB(200, 78, 84),
                Text = "删",
                TextColor3 = Color3.fromRGB(255,255,255),
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                Parent = row,
            })
            StyleButton(delBtn, 12)

            local copyBtn = New("TextButton", {
                Size = UDim2.new(0, 56, 0, 36),
                Position = UDim2.new(1, -60, 0.5, -18),
                BackgroundColor3 = Color3.fromRGB(63, 123, 213),
                Text = "复",
                TextColor3 = Color3.fromRGB(255,255,255),
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                Parent = row,
            })
            StyleButton(copyBtn, 12)

            label.MouseButton1Click:Connect(function()
                CopyText(line)
                UpdateStatus("已复制当前行")
            end)

            copyBtn.MouseButton1Click:Connect(function()
                CopyText(line)
                UpdateStatus("已复制当前行")
            end)

            addBtn.MouseButton1Click:Connect(function()
                AddTextToFavorite(line)
                RefreshFavoriteUI()
                UpdateStatus("已加入收藏")
            end)

            delBtn.MouseButton1Click:Connect(function()
                if BlockMode then
                    if CurrentSection == "全部" then
                        for _, sectionName in ipairs(Sections) do
                            BlockedData[sectionName][line] = true
                        end
                    else
                        BlockedData[CurrentSection][line] = true
                        BlockedData["全部"][line] = true
                    end
                end

                if CurrentSection == "全部" then
                    for _, sectionName in ipairs(Sections) do
                        RemoveTextFromSection(sectionName, line)
                    end
                else
                    RemoveTextFromSection(CurrentSection, line)
                    RebuildAllSection()
                end

                SetDisplayText(BuildCurrentDisplay())
                UpdateSectionButtons()
                UpdateStatus(BlockMode and "已删除并屏蔽" or "已删除当前行")
            end)
        end
    end

    if idx == 0 then
        local row = New("Frame", {
            Size = UDim2.new(1, -16, 0, 72),
            BackgroundColor3 = Color3.fromRGB(66, 76, 110),
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Parent = Scroll,
        })
        StyleGlass(row, 18)

        local label = New("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 15, 0, 0),
            BackgroundTransparency = 1,
            Text = "未检测到 UI 文本",
            TextColor3 = Color3.fromRGB(220, 225, 240),
            TextSize = 16,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
    end

    ResizeScrollCanvas()
end

local function SearchText()
    local keyword = CleanText(SearchBar.Text)
    local data = SectionData[CurrentSection]
    if not data then return end

    if keyword == "" then
        SetDisplayText(BuildCurrentDisplay())
        UpdateStatus("显示全部文本")
        return
    end

    local result = {}
    local lower = string.lower(keyword)
    for _, line in ipairs(data.Texts) do
        if string.find(string.lower(line), lower, 1, true) then
            table.insert(result, line)
        end
    end

    if #result == 0 then
        SetDisplayText("没有搜索到包含【" .. keyword .. "】的文本")
        UpdateStatus("搜索结果 0 条")
    else
        SetDisplayText(table.concat(result, "\n"))
        UpdateStatus("搜索结果 " .. tostring(#result) .. " 条")
    end
end

--====================================================
-- 扫描逻辑
--====================================================

local function ShouldObjectBelongToSection(obj, sectionName)
    if not obj then return false end
    if obj:IsDescendantOf(ScreenGui) then return false end
    if not IsObjectVisible(obj) then return false end

    local path = GetObjectPath(obj)

    if sectionName == "PlayerGui" then
        return obj:IsDescendantOf(PlayerGui)
    elseif sectionName == "Workspace" then
        return obj:IsDescendantOf(Workspace)
    elseif sectionName == "CoreGui" then
        return obj:IsDescendantOf(CoreGui)
    elseif sectionName == "RobloxGui" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "RobloxGui", 1, true) ~= nil
    elseif sectionName == "PlayerList" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "PlayerList", 1, true) ~= nil
    elseif sectionName == "第三方UI" then
        if obj:IsDescendantOf(CoreGui) and not IsRobloxSystemObject(obj) then
            return true
        end
        if obj:IsDescendantOf(PlayerGui) then
            return true
        end
        pcall(function()
            if gethui then
                local hui = gethui()
                if hui and obj:IsDescendantOf(hui) then
                    return true
                end
            end
        end)
        return false
    elseif sectionName == "全部" then
        return obj:IsDescendantOf(PlayerGui)
            or obj:IsDescendantOf(Workspace)
            or obj:IsDescendantOf(CoreGui)
    end

    return false
end

local function ReadTextObjectToSection(obj, sectionName)
    if not ShouldObjectBelongToSection(obj, sectionName) then
        return 0
    end

    local added = 0
    local function trySave(value)
        if SaveTextWithSection(sectionName, value) then
            added = added + 1
        end
    end

    pcall(function()
        if obj.Text then
            trySave(obj.Text)
        end
    end)
    pcall(function()
        if obj.ContentText then
            trySave(obj.ContentText)
        end
    end)
    pcall(function()
        if obj.PlaceholderText and obj.PlaceholderText ~= "" then
            trySave(obj.PlaceholderText)
        end
    end)

    return added
end

local function ScanOneContainerForSection(container, sectionName)
    local added = 0
    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                added = added + ReadTextObjectToSection(obj, sectionName)
            end
        end
    end)
    return added
end

local function ScanSection(sectionName)
    local added = 0

    if sectionName == "PlayerGui" then
        added = added + ScanOneContainerForSection(PlayerGui, "PlayerGui")
    elseif sectionName == "Workspace" then
        added = added + ScanOneContainerForSection(Workspace, "Workspace")
    elseif sectionName == "CoreGui" then
        added = added + ScanOneContainerForSection(CoreGui, "CoreGui")
    elseif sectionName == "RobloxGui" then
        added = added + ScanOneContainerForSection(CoreGui, "RobloxGui")
    elseif sectionName == "PlayerList" then
        added = added + ScanOneContainerForSection(CoreGui, "PlayerList")
    elseif sectionName == "第三方UI" then
        added = added + ScanOneContainerForSection(PlayerGui, "第三方UI")
        added = added + ScanOneContainerForSection(CoreGui, "第三方UI")
        pcall(function()
            if gethui then
                local hui = gethui()
                if hui then
                    added = added + ScanOneContainerForSection(hui, "第三方UI")
                end
            end
        end)
    elseif sectionName == "全部" then
        added = added + ScanSection("PlayerGui")
        added = added + ScanSection("Workspace")
        added = added + ScanSection("CoreGui")
        added = added + ScanSection("第三方UI")
    end

    RebuildSectionText(sectionName)
    RebuildSectionText("全部")
    return added
end

local function ManualRefresh()
    local added = ScanSection(CurrentSection)
    UpdateSectionButtons()
    if CleanText(SearchBar.Text) ~= "" then
        SearchText()
    else
        SetDisplayText(BuildCurrentDisplay())
    end
    UpdateStatus("刷新完成，新增 " .. tostring(added) .. " 条")
end

local function ExportCurrentSectionAsLua()
    local data = SectionData[CurrentSection]
    if not data then return end

    local luaText = BuildLuaExport("UI文本导出 - " .. CurrentSection, data.Texts)
    local copied = false
    local saved = false

    if CopyText(luaText) then copied = true end
    if writefile then
        local safeName = tostring(CurrentSection):gsub("[\\/:*?\"<>|]", "_")
        writefile("UITextExport_" .. safeName .. ".lua", luaText)
        saved = true
    end

    if copied and saved then
        UpdateStatus("已导出Lua：已复制并保存文件")
    elseif copied then
        UpdateStatus("已导出Lua：已复制")
    elseif saved then
        UpdateStatus("已导出Lua：已保存文件")
    else
        UpdateStatus("导出失败：当前环境不支持复制或写文件")
    end
end

local function ExportFavoriteAsLua()
    local luaText = BuildLuaExport("收藏列表导出", FavoriteData.Texts)
    local copied = false
    local saved = false

    if CopyText(luaText) then copied = true end
    if writefile then
        writefile("UITextExport_收藏列表.lua", luaText)
        saved = true
    end

    if copied and saved then
        UpdateStatus("收藏Lua已复制并保存")
    elseif copied then
        UpdateStatus("收藏Lua已复制")
    elseif saved then
        UpdateStatus("收藏Lua已保存")
    else
        UpdateStatus("导出失败")
    end
end

local function ClearCurrentSection()
    local data = SectionData[CurrentSection]
    if not data then return end

    if BlockMode then
        if CurrentSection == "全部" then
            for _, sectionName in ipairs(Sections) do
                for _, text in ipairs(SectionData[sectionName].Texts) do
                    BlockedData[sectionName][text] = true
                end
            end
        else
            for _, text in ipairs(data.Texts) do
                BlockedData[CurrentSection][text] = true
                BlockedData["全部"][text] = true
            end
        end
    end

    data.Texts = {}
    data.Map = {}
    data.AllText = "未检测到 UI 文本"

    if CurrentSection == "全部" then
        for _, name in ipairs(Sections) do
            SectionData[name].Texts = {}
            SectionData[name].Map = {}
            SectionData[name].AllText = "未检测到 UI 文本"
        end
    else
        RebuildAllSection()
    end

    SearchBar.Text = ""
    SetDisplayText(BuildCurrentDisplay())
    UpdateSectionButtons()
    UpdateStatus(BlockMode and "已清空并屏蔽" or "已清空当前分区")
end

--====================================================
-- 交互
--====================================================

local function UpdateAutoBtn()
    AutoToggleBtn.Text = AutoRefresh and "☑" or "☐"
    AutoToggleBtn.BackgroundColor3 = AutoRefresh and Color3.fromRGB(38, 168, 255) or Color3.fromRGB(70, 78, 110)
end

local function UpdateBlockBtn()
    BlockBtn.Text = BlockMode and "◉" or "◔"
    BlockBtn.BackgroundColor3 = BlockMode and Color3.fromRGB(160, 88, 186) or Color3.fromRGB(70, 78, 110)
end

RefreshBtn.MouseButton1Click:Connect(ManualRefresh)
RefreshSmall.MouseButton1Click:Connect(ManualRefresh)

SearchIcon.MouseButton1Click:Connect(SearchText)
SearchRunBtn.MouseButton1Click:Connect(SearchText)
SearchBar.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        SearchText()
    end
end)

AutoToggleBtn.MouseButton1Click:Connect(function()
    AutoRefresh = not AutoRefresh
    UpdateAutoBtn()
    UpdateStatus(AutoRefresh and "自动刷新已开启" or "自动刷新已关闭")
end)

CopyAllBtn.MouseButton1Click:Connect(function()
    if CopyText(CurrentDisplayText) then
        UpdateStatus("已复制当前显示全部")
    else
        UpdateStatus("当前环境不支持复制")
    end
end)

ExportBtn.MouseButton1Click:Connect(ExportCurrentSectionAsLua)

BlockBtn.MouseButton1Click:Connect(function()
    BlockMode = not BlockMode
    UpdateBlockBtn()
    UpdateStatus(BlockMode and "屏蔽文本已开启" or "屏蔽文本已关闭")
end)

ClearBtn.MouseButton1Click:Connect(ClearCurrentSection)

FavoriteOpenBtn.MouseButton1Click:Connect(function()
    FavoriteMain.Visible = true
    RefreshFavoriteUI()
end)

FavoriteClose.MouseButton1Click:Connect(function()
    FavoriteMain.Visible = false
end)

FavoriteCopyAll.MouseButton1Click:Connect(function()
    local txt = #FavoriteData.Texts > 0 and table.concat(FavoriteData.Texts, "\n") or "收藏列表为空"
    if CopyText(txt) then
        UpdateStatus("已复制收藏全部")
    else
        UpdateStatus("当前环境不支持复制")
    end
end)

FavoriteExport.MouseButton1Click:Connect(function()
    ExportFavoriteAsLua()
end)

FavoriteClear.MouseButton1Click:Connect(function()
    FavoriteData.Texts = {}
    FavoriteData.Map = {}
    RefreshFavoriteUI()
    UpdateStatus("收藏列表已清空")
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    ScrollHolder.Visible = not Minimized
    SectionFrame.Visible = not Minimized
    ThemeBadge.Visible = not Minimized
    HeaderSearch.Visible = not Minimized
    SearchBar.Visible = not Minimized
    SearchIcon.Visible = not Minimized
    RefreshBtn.Visible = not Minimized
    StatusLabel.Visible = not Minimized
    ResizeHandle.Visible = not Minimized

    if Minimized then
        Main.Size = UDim2.new(0, 600, 0, 90)
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 1180, 0, 700)
        MinBtn.Text = "–"
    end
end)

-- 缩放
local resizing = false
local resizeStartPos, resizeStartSize

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Main.AbsoluteSize
        Main.Draggable = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - resizeStartPos
    local newW = math.clamp(resizeStartSize.X + delta.X, 900, 1500)
    local newH = math.clamp(resizeStartSize.Y + delta.Y, 560, 900)
    Main.Size = UDim2.new(0, newW, 0, newH)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        Main.Draggable = true
    end
end)

--====================================================
-- 自动刷新循环
--====================================================

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if AutoRefresh then
            ManualRefresh()
        else
            UpdateSectionButtons()
        end
        task.wait(AutoRefreshInterval)
    end
end)

--====================================================
-- 启动
--====================================================

UpdateAutoBtn()
UpdateBlockBtn()
UpdateSectionButtons()
SetDisplayText("未检测到 UI 文本")
RefreshFavoriteUI()
UpdateStatus("初始化完成")
ManualRefresh()

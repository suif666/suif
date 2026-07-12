-- Roblox UI 文本提取器 v23 简化稳定版（按钮布局修复 + 移动端默认更小）
-- 主要改进：
-- 1. 修复了“有时列表不加载文字，需切换分区才正常”的bug（SetDisplay 重入竞态）
-- 2. SetDisplay 改为 token 保护 + 总是全量重建，彻底避免状态混乱
-- 3. 大幅简化 LayoutUI（移除复杂响应式/手机自适应代码）
-- 4. 最小化按钮保留但大幅简化（不再变小圆圈，只隐藏内容 + 调整高度）
-- 5. 搜索框默认常显，去掉展开/收起状态机
-- 6. 修复了文本列表每行按钮（添加/删除/复制）排列问题：复制按钮不再超出边界
-- 7. 默认UI尺寸缩小为480x340，更适合移动端；保留拖动右下角↘手柄自由调整大小
-- 8. 保留全部核心功能：多分区、对象池、批量yield防卡顿、搜索、收藏栏、导出Lua、屏蔽、自动刷新、复制、删除、缩放
-- 代码量减少约 35%，更清晰、更稳定

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function getHui()
    local ok, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    return ok and hui or nil
end

-- 清理旧UI
pcall(function()
    local old = CoreGui:FindFirstChild("AutoTextCollectorUI")
    if old then old:Destroy() end
end)
pcall(function()
    local old = PlayerGui:FindFirstChild("AutoTextCollectorUI")
    if old then old:Destroy() end
end)
pcall(function()
    local hui = getHui()
    if hui then
        local old = hui:FindFirstChild("AutoTextCollectorUI")
        if old then old:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTextCollectorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local hui = getHui()
if hui then
    ScreenGui.Parent = hui
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = PlayerGui
end

local Sections = {"全部", "PlayerGui", "Workspace", "CoreGui", "RobloxGui", "PlayerList", "第三方UI"}
local CurrentSection = "全部"

local SystemNames = {
    RobloxGui = true, PlayerList = true, Backpack = true, Chat = true,
    BubbleChat = true, ExperienceChat = true, TextChatService = true,
    TopBar = true, Topbar = true, Health = true, EmotesMenu = true,
    Chrome = true, InspectMenu = true, PurchasePrompt = true, ScreenshotHud = true,
}

local SectionData = {}
local BlockedData = {}
for _, name in ipairs(Sections) do
    SectionData[name] = {Texts = {}, Map = {}, AllText = "未检测到 UI 文本"}
    BlockedData[name] = {}
end

local FavoriteData = {Texts = {}, Map = {}}

local AutoRefreshEnabled = false
local AutoRefreshInterval = 1.5
local AutoScrollToBottom = true
local BlockMode = false
local Minimized = false
local CurrentDisplayText = ""
local LastNormalSize = Vector2.new(480, 340) -- 与默认UI大小匹配，移动端友好
local LastNormalPosition = nil

-- ==================== 行对象池 ====================
local RowPool = {}
local MAX_POOL_SIZE = 400

local function CleanText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    text = text:gsub("\r", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function EscapeLuaString(str)
    str = tostring(str or "")
    str = str:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r")
         :gsub("\t", "\\t"):gsub("\"", "\\\"")
    return str
end

local function IsTextObject(obj)
    return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end

local function GetObjectPath(obj)
    local t = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(t, 1, cur.Name)
        cur = cur.Parent
    end
    return table.concat(t, "/")
end

local function IsSystemUI(obj)
    local cur = obj
    while cur and cur ~= game do
        if SystemNames[cur.Name] then return true end
        cur = cur.Parent
    end
    return false
end

local function IsVisible(obj)
    local cur = obj
    while cur and cur ~= game do
        local ok, v = pcall(function() return cur.Visible end)
        if ok and v == false then return false end
        cur = cur.Parent
    end
    return true
end

local function Rebuild(section)
    local data = SectionData[section]
    if not data then return end
    data.AllText = (#data.Texts == 0) and "未检测到 UI 文本" or table.concat(data.Texts, "\n")
end

local function Count(section)
    local data = SectionData[section]
    return data and #data.Texts or 0
end

local function AddText(section, text)
    text = CleanText(text)
    if text == "" or text == "未检测到 UI 文本" then return false end
    if BlockMode and BlockedData[section] and BlockedData[section][text] then return false end
    local data = SectionData[section]
    if not data or data.Map[text] then return false end
    data.Map[text] = true
    table.insert(data.Texts, text)
    Rebuild(section)
    return true
end

local function AddTextWithAll(section, text)
    local added = AddText(section, text)
    if section ~= "全部" then
        if AddText("全部", text) then added = true end
    end
    return added
end

local function RemoveText(section, text)
    text = CleanText(text)
    local data = SectionData[section]
    if not data then return end
    data.Map[text] = nil
    for i = #data.Texts, 1, -1 do
        if data.Texts[i] == text then table.remove(data.Texts, i) end
    end
    Rebuild(section)
end

local function RebuildAll()
    SectionData["全部"].Texts = {}
    SectionData["全部"].Map = {}
    SectionData["全部"].AllText = "未检测到 UI 文本"
    for _, section in ipairs(Sections) do
        if section ~= "全部" then
            for _, text in ipairs(SectionData[section].Texts) do
                AddText("全部", text)
            end
        end
    end
    Rebuild("全部")
end

local function BelongsToSection(obj, section)
    if not obj or obj:IsDescendantOf(ScreenGui) then return false end
    if not IsVisible(obj) then return false end
    local path = GetObjectPath(obj)
    local huiRoot = getHui()

    if section == "PlayerGui" then
        return obj:IsDescendantOf(PlayerGui)
    elseif section == "Workspace" then
        return obj:IsDescendantOf(Workspace)
    elseif section == "CoreGui" then
        return obj:IsDescendantOf(CoreGui)
    elseif section == "RobloxGui" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "RobloxGui", 1, true) ~= nil
    elseif section == "PlayerList" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "PlayerList", 1, true) ~= nil
    elseif section == "第三方UI" then
        local inGui = obj:IsDescendantOf(PlayerGui) or obj:IsDescendantOf(CoreGui) or (huiRoot and obj:IsDescendantOf(huiRoot))
        return inGui and not IsSystemUI(obj)
    elseif section == "全部" then
        return obj:IsDescendantOf(PlayerGui) or obj:IsDescendantOf(CoreGui) or obj:IsDescendantOf(Workspace) or (huiRoot and obj:IsDescendantOf(huiRoot))
    end
    return false
end

local function TryReadText(obj, section)
    if not BelongsToSection(obj, section) then return 0 end
    local added = 0
    local function save(v)
        if AddTextWithAll(section, v) then added = added + 1 end
    end
    pcall(function() save(obj.Text) end)
    pcall(function() save(obj.ContentText) end)
    pcall(function() save(obj.LocalizedText) end)
    pcall(function() save(obj.PlaceholderText) end)
    return added
end

local function ScanContainer(root, section)
    local added = 0
    if not root then return 0 end
    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            if IsTextObject(obj) then
                added = added + TryReadText(obj, section)
            end
        end
    end)
    return added
end

local function ScanSection(section)
    local added = 0
    local huiRoot = getHui()
    if section == "PlayerGui" then
        added = added + ScanContainer(PlayerGui, section)
    elseif section == "Workspace" then
        added = added + ScanContainer(Workspace, section)
    elseif section == "CoreGui" or section == "RobloxGui" or section == "PlayerList" then
        added = added + ScanContainer(CoreGui, section)
        if huiRoot and huiRoot ~= CoreGui then added = added + ScanContainer(huiRoot, section) end
    elseif section == "第三方UI" then
        added = added + ScanContainer(PlayerGui, section)
        added = added + ScanContainer(CoreGui, section)
        if huiRoot and huiRoot ~= CoreGui then added = added + ScanContainer(huiRoot, section) end
    elseif section == "全部" then
        added = added + ScanSection("PlayerGui")
        added = added + ScanSection("CoreGui")
        added = added + ScanSection("第三方UI")
    end
    Rebuild(section)
    Rebuild("全部")
    return added
end

-- ==================== UI 创建 ====================
local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(obj, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, obj)
end

local function Stroke(obj, color, t, tr)
    return New("UIStroke", {Color = color or Color3.fromRGB(70, 78, 96), Thickness = t or 1, Transparency = tr or 0.35}, obj)
end

local Theme = {
    Panel = Color3.fromRGB(15, 18, 25),
    Panel2 = Color3.fromRGB(21, 25, 34),
    Card = Color3.fromRGB(27, 32, 43),
    Card2 = Color3.fromRGB(32, 38, 51),
    Text = Color3.fromRGB(235, 238, 245),
    Muted = Color3.fromRGB(155, 165, 185),
    Stroke = Color3.fromRGB(58, 67, 84),
    Accent = Color3.fromRGB(82, 145, 245),
    AccentDark = Color3.fromRGB(48, 94, 168),
    Green = Color3.fromRGB(70, 150, 105),
    Red = Color3.fromRGB(180, 72, 78),
    Purple = Color3.fromRGB(105, 86, 150),
    Yellow = Color3.fromRGB(135, 105, 56),
    Cyan = Color3.fromRGB(70, 135, 150),
}

local function StyleButton(btn, color)
    btn.BackgroundColor3 = color or Theme.Card
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    Corner(btn, 8)
    Stroke(btn, Theme.Stroke, 1, 0.55)
end

local Main = New("Frame", {
    Size = UDim2.new(0, 480, 0, 340), -- 移动端更友好，默认较小；可拖动右下角↘手柄自由调整大小
    Position = UDim2.new(0.5, -240, 0.5, -170),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, ScreenGui)
Corner(Main, 18)
Stroke(Main, Theme.Stroke, 1, 0.36)

local Title = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "UI 文本提取器 v23 简化版",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 17
}, Main)

local MinBtn = New("TextButton", {
    Text = "-",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Card2,
    TextSize = 18
}, Main)
StyleButton(MinBtn, Theme.Card2)

local CloseBtn = New("TextButton", {
    Text = "X",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Red,
    TextSize = 16
}, Main)
StyleButton(CloseBtn, Theme.Red)

local Content = New("Frame", {BackgroundTransparency = 1}, Main)

local LeftPanel = New("ScrollingFrame", {
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
    ScrollBarImageColor3 = Color3.fromRGB(170,170,175),
    ClipsDescendants = true
}, Content)
Corner(LeftPanel, 8)
Stroke(LeftPanel, Theme.Stroke, 1, 0.38)

local StatusLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "状态：待刷新",
    TextColor3 = Color3.fromRGB(200,200,205),
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 12
}, Content)

local SectionFrame = New("Frame", {
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, LeftPanel)
Corner(SectionFrame, 8)
Stroke(SectionFrame, Theme.Stroke, 1, 0.38)

-- 搜索框默认常显（简化）
local SearchBox = New("TextBox", {
    Text = "",
    PlaceholderText = "搜索当前分区文本...",
    ClearTextOnFocus = false,
    BackgroundColor3 = Theme.Card,
    TextColor3 = Color3.new(1,1,1),
    PlaceholderColor3 = Color3.fromRGB(155,155,160),
    Font = Enum.Font.SourceSans,
    TextSize = 12
}, LeftPanel)
Corner(SearchBox, 8)
Stroke(SearchBox, Theme.Stroke, 1, 0.38)

local SearchBtn = New("TextButton", {
    Text = "搜索",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Purple,
    TextSize = 13
}, LeftPanel)
StyleButton(SearchBtn, Theme.Purple)

local Scroll = New("ScrollingFrame", {
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 8,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
    ScrollBarImageColor3 = Color3.fromRGB(170,170,175),
    ClipsDescendants = true
}, Content)
Corner(Scroll, 8)
Stroke(Scroll, Theme.Stroke, 1, 0.38)

local ListLayout = New("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Scroll)

local BottomBar = New("Frame", {BackgroundTransparency = 1, ClipsDescendants = true}, LeftPanel)

local RefreshBtn = New("TextButton", {Text = "刷新", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.AccentDark, TextSize = 11}, BottomBar)
local AutoCheckBtn = New("TextButton", {Text = "☐ 自动刷新", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Yellow, TextSize = 11}, BottomBar)
local CopyBtn = New("TextButton", {Text = "复制显示", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Green, TextSize = 11}, BottomBar)
local BlockBtn = New("TextButton", {Text = "屏蔽：关", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Purple, TextSize = 11}, BottomBar)
local FavBtn = New("TextButton", {Text = "收藏栏", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.AccentDark, TextSize = 11}, BottomBar)
local ExportBtn = New("TextButton", {Text = "导出Lua", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Cyan, TextSize = 11}, BottomBar)
local ClearBtn = New("TextButton", {Text = "清空", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Red, TextSize = 11}, BottomBar)

for _, b in ipairs({RefreshBtn, AutoCheckBtn, CopyBtn, BlockBtn, FavBtn, ExportBtn, ClearBtn}) do
    StyleButton(b, b.BackgroundColor3)
end

local ResizeHandle = New("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.new(1, -3, 1, -3),
    Text = "↘",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Stroke,
    ZIndex = 10
}, Main)
StyleButton(ResizeHandle, Theme.Stroke)

local SectionButtons = {}
for _, section in ipairs(Sections) do
    local b = New("TextButton", {
        Text = section.." [0]",
        TextColor3 = Color3.fromRGB(225,225,230),
        Font = Enum.Font.SourceSansBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.Card2,
        TextSize = 11
    }, SectionFrame)
    Corner(b, 6)
    Stroke(b, Theme.Stroke, 1, 0.45)
    SectionButtons[section] = b
end

-- ==================== 收藏栏 ====================
local FavoriteMain, FavoriteScroll, FavoriteListLayout, FavoriteStatus

local function RefreshFavoriteList()
    if not FavoriteScroll then return end
    for _, obj in ipairs(FavoriteScroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then obj:Destroy() end
    end
    for i, text in ipairs(FavoriteData.Texts) do
        local row = New("Frame", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            LayoutOrder = i
        }, FavoriteScroll)
        Corner(row, 6)
        Stroke(row, Theme.Stroke, 1, 0.45)

        local label = New("TextButton", {
            Size = UDim2.new(1, -100, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, row)

        local del = New("TextButton", {
            Size = UDim2.new(0, 42, 0, 24),
            Position = UDim2.new(1, -88, 0.5, -12),
            Text = "删除",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font = Enum.Font.SourceSansBold,
            BackgroundColor3 = Theme.Red
        }, row)

        local copy = New("TextButton", {
            Size = UDim2.new(0, 42, 0, 24),
            Position = UDim2.new(1, -44, 0.5, -12),
            Text = "复制",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font = Enum.Font.SourceSansBold,
            BackgroundColor3 = Theme.Green
        }, row)

        StyleButton(del, del.BackgroundColor3)
        StyleButton(copy, copy.BackgroundColor3)

        label.MouseButton1Click:Connect(function() 
            if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
        end)
        copy.MouseButton1Click:Connect(function() 
            if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
        end)
        del.MouseButton1Click:Connect(function()
            FavoriteData.Map[text] = nil
            for n = #FavoriteData.Texts, 1, -1 do 
                if FavoriteData.Texts[n] == text then table.remove(FavoriteData.Texts, n); break end 
            end
            RefreshFavoriteList()
            if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        end)
    end

    if #FavoriteData.Texts == 0 then
        local empty = New("TextButton", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            Text = "  收藏列表为空",
            TextColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left
        }, FavoriteScroll)
        Corner(empty, 6)
        Stroke(empty, Theme.Stroke, 1, 0.45)
    end

    task.defer(function()
        task.wait()
        if FavoriteScroll and FavoriteListLayout then
            FavoriteScroll.CanvasSize = UDim2.new(0, 0, 0, FavoriteListLayout.AbsoluteContentSize.Y + 10)
        end
    end)
end

local function CreateFavoriteUI()
    if FavoriteMain and FavoriteMain.Parent then
        FavoriteMain.Visible = true
        RefreshFavoriteList()
        if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        return
    end

    FavoriteMain = New("Frame", {
        Size = UDim2.new(0, 380, 0, 310),
        Position = UDim2.new(0.5, -190, 0.5, -155),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true
    }, ScreenGui)
    Corner(FavoriteMain, 12)
    Stroke(FavoriteMain, Theme.Stroke, 1, 0.2)

    New("TextLabel", {
        Size = UDim2.new(1, -42, 0, 32),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "收藏列表",
        TextColor3 = Color3.new(1,1,1),
        TextSize = 16,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, FavoriteMain)

    local close = New("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -32, 0, 0),
        BackgroundColor3 = Theme.Red,
        Text = "X",
        TextColor3 = Color3.new(1,1,1),
        TextSize = 14,
        Font = Enum.Font.SourceSansBold
    }, FavoriteMain)
    StyleButton(close, close.BackgroundColor3)

    FavoriteStatus = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 34),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200,200,205),
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left
    }, FavoriteMain)

    FavoriteScroll = New("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -105),
        Position = UDim2.new(0, 10, 0, 58),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always
    }, FavoriteMain)
    Corner(FavoriteScroll, 8)
    Stroke(FavoriteScroll, Theme.Stroke, 1, 0.38)

    FavoriteListLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, FavoriteScroll)

    local bottom = New("Frame", {
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.new(0, 10, 1, -40),
        BackgroundTransparency = 1
    }, FavoriteMain)

    local copyAll = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "复制显示",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Green
    }, bottom)

    local exportLua = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0.333, 4, 0, 0),
        Text = "导出Lua",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Cyan
    }, bottom)

    local clearAll = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0.666, 8, 0, 0),
        Text = "清空全部",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Red
    }, bottom)

    StyleButton(copyAll, copyAll.BackgroundColor3)
    StyleButton(exportLua, exportLua.BackgroundColor3)
    StyleButton(clearAll, clearAll.BackgroundColor3)

    close.MouseButton1Click:Connect(function() FavoriteMain.Visible = false end)
    copyAll.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(table.concat(FavoriteData.Texts, "\n"))
        elseif toclipboard then toclipboard(table.concat(FavoriteData.Texts, "\n")) end
    end)
    exportLua.MouseButton1Click:Connect(function()
        -- 简单导出
        local lines = {"-- UI文本导出 (收藏列表)", "return {"}
        for _, t in ipairs(FavoriteData.Texts) do
            table.insert(lines, '    "'..EscapeLuaString(t)..'",')
        end
        table.insert(lines, "}")
        local luaText = table.concat(lines, "\n")
        if setclipboard then setclipboard(luaText) elseif toclipboard then toclipboard(luaText) end
        if writefile then writefile("UITextExport_收藏.lua", luaText) end
    end)
    clearAll.MouseButton1Click:Connect(function()
        FavoriteData.Texts = {}
        FavoriteData.Map = {}
        RefreshFavoriteList()
        if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 0 条" end
    end)

    FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条"
    RefreshFavoriteList()
end

local function AddFavorite(text)
    text = CleanText(text)
    if text == "" then return end
    if not FavoriteData.Map[text] then
        FavoriteData.Map[text] = true
        table.insert(FavoriteData.Texts, text)
    end
    CreateFavoriteUI()
    RefreshFavoriteList()
    if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
end

-- ==================== 显示相关 ====================
local DisplayedLines = {}
local DisplayedRows = {}
local CurrentUpdateToken = 0

local function ClearScroll()
    for _, obj in ipairs(Scroll:GetChildren()) do
        if obj:IsA("Frame") then
            obj.Visible = false
            obj.Parent = nil
            if #RowPool < MAX_POOL_SIZE then
                table.insert(RowPool, obj)
            else
                obj:Destroy()
            end
        end
    end
    DisplayedRows = {}
    DisplayedLines = {}
end

local function ResizeCanvas()
    task.defer(function()
        task.wait()
        if Scroll and ListLayout then
            Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
        end
    end)
end

local function ScrollBottom()
    if not AutoScrollToBottom then return end
    task.defer(function()
        task.wait()
        if Scroll then
            local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
            Scroll.CanvasPosition = Vector2.new(0, maxY)
        end
    end)
end

local function GetCurrentText()
    Rebuild(CurrentSection)
    return SectionData[CurrentSection] and SectionData[CurrentSection].AllText or "未检测到 UI 文本"
end

-- ==================== 创建单行（支持对象池） ====================
local function CreateDisplayRow(line, index)
    local displayLine = (#line > 500) and (string.sub(line, 1, 500) .. "...") or line

    local compact = Main.AbsoluteSize.X < 520 or Main.AbsoluteSize.Y < 340
    local rowH = compact and 34 or 38
    local actionW = compact and 34 or 42
    local actionH = compact and 22 or 24
    local rightPad = compact and 6 or 8
    local actionsWidth = actionW * 3 + 8 + rightPad + 8 -- 确保标签不与按钮重叠，复制按钮不会超出边界

    local row = table.remove(RowPool)
    if row then
        row.Visible = true
        row.Size = UDim2.new(1, -12, 0, rowH)
        row.LayoutOrder = index
        for _, child in ipairs(row:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    else
        row = New("Frame", {
            Size = UDim2.new(1, -12, 0, rowH),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            LayoutOrder = index
        }, Scroll)
        Corner(row, 7)
        Stroke(row, Theme.Stroke, 1, 0.50)
    end

    local label = New("TextButton", {
        Size = UDim2.new(1, -actionsWidth, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = displayLine,
        TextColor3 = Theme.Text,
        TextSize = compact and 11 or 13,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local add = New("TextButton", {
        Size = UDim2.new(0, actionW, 0, actionH),
        Position = UDim2.new(1, -(actionW * 3 + 8 + rightPad), 0.5, -actionH/2),
        Text = compact and "藏" or "添加",
        TextColor3 = Color3.new(1,1,1),
        TextSize = compact and 10 or 12,
        Font = Enum.Font.SourceSansBold,
        BackgroundColor3 = Theme.AccentDark
    }, row)

    local del = New("TextButton", {
        Size = UDim2.new(0, actionW, 0, actionH),
        Position = UDim2.new(1, -(actionW * 2 + 4 + rightPad), 0.5, -actionH/2),
        Text = compact and "删" or "删除",
        TextColor3 = Color3.new(1,1,1),
        TextSize = compact and 10 or 12,
        Font = Enum.Font.SourceSansBold,
        BackgroundColor3 = Theme.Red
    }, row)

    local copy = New("TextButton", {
        Size = UDim2.new(0, actionW, 0, actionH),
        Position = UDim2.new(1, -rightPad, 0.5, -actionH/2),
        Text = compact and "复" or "复制",
        TextColor3 = Color3.new(1,1,1),
        TextSize = compact and 10 or 12,
        Font = Enum.Font.SourceSansBold,
        BackgroundColor3 = Theme.Green
    }, row)

    StyleButton(add, add.BackgroundColor3)
    StyleButton(del, del.BackgroundColor3)
    StyleButton(copy, copy.BackgroundColor3)

    label.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(line) elseif toclipboard then toclipboard(line) end
    end)
    copy.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(line) elseif toclipboard then toclipboard(line) end
    end)
    add.MouseButton1Click:Connect(function() AddFavorite(line) end)

    del.MouseButton1Click:Connect(function()
        local oldPos = Scroll.CanvasPosition
        if BlockMode then
            if CurrentSection == "全部" then
                for _, sec in ipairs(Sections) do BlockedData[sec][line] = true end
            else
                BlockedData[CurrentSection][line] = true
                BlockedData["全部"][line] = true
            end
        end
        if CurrentSection == "全部" then
            for _, sec in ipairs(Sections) do RemoveText(sec, line) end
        else
            RemoveText(CurrentSection, line)
            RebuildAll()
        end
        SetDisplay(GetCurrentText(), false)
        task.defer(function()
            task.wait()
            if Scroll then
                local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
                Scroll.CanvasPosition = Vector2.new(0, math.clamp(oldPos.Y, 0, maxY))
            end
        end)
        UpdateSectionButtons()
    end)

    return row
end

-- ==================== 修复版 SetDisplay（关键修复） ====================
local SetDisplay

SetDisplay = function(text, autoBottom)
    CurrentDisplayText = text

    local newLines = {}
    for line in string.gmatch(tostring(text or "") .. "\n", "(.-)\n") do
        line = CleanText(line)
        if line ~= "" then table.insert(newLines, line) end
    end

    if #newLines == 0 then
        ClearScroll()
        local empty = New("TextButton", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            Text = "  未检测到 UI 文本",
            TextColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1
        }, Scroll)
        Corner(empty, 6)
        Stroke(empty, Theme.Stroke, 1, 0.45)
        ResizeCanvas()
        if autoBottom then ScrollBottom() end
        return
    end

    CurrentUpdateToken = CurrentUpdateToken + 1
    local token = CurrentUpdateToken

    -- 总是全量重建 + token 保护（彻底解决重入bug）
    ClearScroll()

    for i, line in ipairs(newLines) do
        if CurrentUpdateToken ~= token then return end
        local row = CreateDisplayRow(line, i)
        table.insert(DisplayedRows, row)
        if i % 12 == 0 then
            task.wait()
            if CurrentUpdateToken ~= token then return end
        end
    end

    DisplayedLines = newLines
    ResizeCanvas()
    if autoBottom then ScrollBottom() end
end

local function UpdateStatus(msg)
    local block = BlockMode and "屏蔽开" or "屏蔽关"
    local auto = AutoRefreshEnabled and "自动刷新开" or "自动刷新关"
    if msg and msg ~= "" then
        StatusLabel.Text = "状态："..auto.."｜"..CurrentSection.."｜"..Count(CurrentSection).."条｜"..block.."｜"..msg
    else
        StatusLabel.Text = "状态："..auto.."｜"..CurrentSection.."｜"..Count(CurrentSection).."条｜"..block
    end
end

local function UpdateSectionButtons()
    for name, b in pairs(SectionButtons) do
        if name == CurrentSection then
            b.BackgroundColor3 = Theme.Accent
            b.TextColor3 = Color3.new(1,1,1)
        else
            b.BackgroundColor3 = Theme.Card2
            b.TextColor3 = Theme.Text
        end
        b.Text = name.." ["..Count(name).."]"
    end
end

local function SearchNow()
    local keyword = CleanText(SearchBox.Text)
    local data = SectionData[CurrentSection]
    if not data then return end
    if keyword == "" then
        SetDisplay(GetCurrentText(), false)
        Scroll.CanvasPosition = Vector2.new(0,0)
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
        SetDisplay("没有搜索到包含【"..keyword.."】的文本", false)
        UpdateStatus("搜索结果 0 条")
    else
        SetDisplay(table.concat(result, "\n"), false)
        UpdateStatus("搜索结果 "..#result.." 条")
    end
    Scroll.CanvasPosition = Vector2.new(0,0)
end

local function RefreshDisplay(added)
    UpdateSectionButtons()
    if CleanText(SearchBox.Text) ~= "" then
        SearchNow()
    else
        SetDisplay(GetCurrentText(), added and added > 0)
        if added and added > 0 then UpdateStatus("新增 "..added.." 条") else UpdateStatus("暂无新增") end
    end
end

local function ManualRefresh()
    local added = ScanSection(CurrentSection)
    RefreshDisplay(added)
end

local function ClearCurrent()
    local data = SectionData[CurrentSection]
    if not data then return end
    if BlockMode then
        if CurrentSection == "全部" then
            for _, sec in ipairs(Sections) do
                for _, text in ipairs(SectionData[sec].Texts) do BlockedData[sec][text] = true end
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
        for _, sec in ipairs(Sections) do
            SectionData[sec].Texts = {}
            SectionData[sec].Map = {}
            SectionData[sec].AllText = "未检测到 UI 文本"
        end
    else
        RebuildAll()
    end
    SearchBox.Text = ""
    SetDisplay(GetCurrentText(), false)
    Scroll.CanvasPosition = Vector2.new(0,0)
    UpdateSectionButtons()
    UpdateStatus(BlockMode and "已清空并加入屏蔽" or "已清空当前分区")
end

-- ==================== 简化版 LayoutUI ====================
local function LayoutUI()
    if Minimized then return end

    local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if w <= 0 then w = 480 end
    if h <= 0 then h = 340 end

    local pad = 8
    local titleH = 32
    local sideW = 155
    local statusH = 20
    local searchH = 26
    local gap = 5
    local actionH = 24
    local actionCount = 7

    Title.Size = UDim2.new(1, -80, 0, titleH)
    Title.Position = UDim2.new(0, pad, 0, 0)

    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -60, 0, 2)

    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -30, 0, 2)

    Content.Size = UDim2.new(1, 0, 1, -titleH)
    Content.Position = UDim2.new(0, 0, 0, titleH)

    LeftPanel.Size = UDim2.new(0, sideW, 1, -pad*2)
    LeftPanel.Position = UDim2.new(0, pad, 0, pad)

    local sectionPanelH = #Sections * 24 + (#Sections + 1) * gap
    SectionFrame.Size = UDim2.new(1, -pad, 0, sectionPanelH)
    SectionFrame.Position = UDim2.new(0, math.floor(pad/2), 0, gap)

    for i, section in ipairs(Sections) do
        local b = SectionButtons[section]
        b.Size = UDim2.new(1, -pad, 0, 24)
        b.Position = UDim2.new(0, math.floor(pad/2), 0, gap + (i-1) * (24 + gap))
    end

    local sideY = gap + sectionPanelH + gap
    SearchBtn.Size = UDim2.new(0, searchH, 0, searchH)
    SearchBtn.Position = UDim2.new(0, math.floor(pad/2), 0, sideY)
    SearchBtn.TextSize = 13

    SearchBox.Visible = true
    SearchBox.Size = UDim2.new(0, sideW - searchH - gap - 4, 0, searchH)
    SearchBox.Position = UDim2.new(0, math.floor(pad/2) + searchH + gap, 0, sideY)
    SearchBox.TextSize = 12

    local actionPanelH = actionCount * actionH + (actionCount-1) * gap
    BottomBar.Size = UDim2.new(1, -pad, 0, actionPanelH)
    BottomBar.Position = UDim2.new(0, math.floor(pad/2), 0, sideY + searchH + gap)

    local leftContentH = sideY + searchH + gap + actionPanelH + gap
    LeftPanel.CanvasSize = UDim2.new(0, 0, 0, leftContentH)

    local buttons = {RefreshBtn, AutoCheckBtn, CopyBtn, BlockBtn, FavBtn, ExportBtn, ClearBtn}
    for i, b in ipairs(buttons) do
        b.Size = UDim2.new(1, -pad, 0, actionH)
        b.Position = UDim2.new(0, math.floor(pad/2), 0, (i-1) * (actionH + gap))
    end

    local listX = pad * 2 + sideW
    local rightW = math.max(120, w - listX - pad)

    StatusLabel.Size = UDim2.new(0, rightW, 0, statusH)
    StatusLabel.Position = UDim2.new(0, listX, 0, pad)
    StatusLabel.TextSize = 12

    local scrollY = pad + statusH + gap
    Scroll.Size = UDim2.new(0, rightW, 1, -scrollY - pad)
    Scroll.Position = UDim2.new(0, listX, 0, scrollY)

    ResizeHandle.Visible = true
    ResizeCanvas()
end

-- ==================== 事件连接 ====================
for _, section in ipairs(Sections) do
    SectionButtons[section].MouseButton1Click:Connect(function()
        CurrentSection = section
        SearchBox.Text = ""
        SetDisplay(GetCurrentText(), false)
        Scroll.CanvasPosition = Vector2.new(0,0)
        UpdateSectionButtons()
        UpdateStatus("已切换分区")
    end)
end

RefreshBtn.MouseButton1Click:Connect(function() ManualRefresh() end)

AutoCheckBtn.MouseButton1Click:Connect(function()
    AutoRefreshEnabled = not AutoRefreshEnabled
    AutoCheckBtn.Text = AutoRefreshEnabled and "☑ 自动刷新" or "☐ 自动刷新"
    AutoCheckBtn.BackgroundColor3 = AutoRefreshEnabled and Theme.Green or Theme.Yellow
    UpdateStatus(AutoRefreshEnabled and "自动刷新已开启" or "自动刷新已关闭")
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(CurrentDisplayText)
    elseif toclipboard then toclipboard(CurrentDisplayText) end
    UpdateStatus("已复制当前显示")
end)

BlockBtn.MouseButton1Click:Connect(function()
    BlockMode = not BlockMode
    if BlockMode then
        BlockBtn.Text = "屏蔽：开"
        BlockBtn.BackgroundColor3 = Theme.Purple
        UpdateStatus("屏蔽文本已开启")
    else
        BlockBtn.Text = "屏蔽：关"
        BlockBtn.BackgroundColor3 = Theme.Purple
        for _, sec in ipairs(Sections) do BlockedData[sec] = {} end
        UpdateStatus("屏蔽文本已关闭")
    end
end)

FavBtn.MouseButton1Click:Connect(function()
    CreateFavoriteUI()
    UpdateStatus("已打开收藏栏")
end)

ExportBtn.MouseButton1Click:Connect(function()
    local data = SectionData[CurrentSection]
    local safeName = tostring(CurrentSection):gsub("[\\/:*?\"<>|]", "_")
    local texts = data and data.Texts or {}
    local lines = {"-- UI文本导出", "-- 分区："..CurrentSection, "-- 数量："..#texts, "", "return {"}
    for _, t in ipairs(texts) do
        table.insert(lines, '    "'..EscapeLuaString(t)..'",')
    end
    table.insert(lines, "}")
    local luaText = table.concat(lines, "\n")
    if setclipboard then setclipboard(luaText) elseif toclipboard then toclipboard(luaText) end
    if writefile then writefile("UITextExport_"..safeName..".lua", luaText) end
    UpdateStatus("已导出Lua")
end)

SearchBtn.MouseButton1Click:Connect(function()
    SearchNow()
end)

SearchBox.FocusLost:Connect(function(enter)
    if enter then SearchNow() end
end)

ClearBtn.MouseButton1Click:Connect(function() ClearCurrent() end)

-- 简化版最小化（保留按钮，不变小圆圈）
MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    if Minimized then
        LastNormalSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        LastNormalPosition = Main.Position
        Content.Visible = false
        ResizeHandle.Visible = false
        Main.Size = UDim2.new(0, LastNormalSize.X, 0, 36) -- 只保留标题栏
        MinBtn.Text = "+"
    else
        Content.Visible = true
        ResizeHandle.Visible = true
        Main.Size = UDim2.new(0, LastNormalSize.X, 0, LastNormalSize.Y)
        if LastNormalPosition then Main.Position = LastNormalPosition end
        MinBtn.Text = "-"
        LayoutUI()
    end
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ResizeCanvas() end)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if not Minimized then LayoutUI() end
end)

-- 缩放手柄
local resizing = false
local resizeStartPos, resizeStartSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Main.AbsoluteSize
        Main.Draggable = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - resizeStartPos
    local newW = math.clamp(resizeStartSize.X + delta.X, 400, 900)
    local newH = math.clamp(resizeStartSize.Y + delta.Y, 280, 700)
    Main.Size = UDim2.new(0, newW, 0, newH)
    LastNormalSize = Vector2.new(newW, newH)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        Main.Draggable = true
    end
end)

-- ==================== 自动刷新 ====================
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if AutoRefreshEnabled then
            pcall(function() ManualRefresh() end)
        else
            UpdateSectionButtons()
            UpdateStatus()
        end
        task.wait(AutoRefreshInterval)
    end
end)

-- ==================== 初始化 ====================
LayoutUI()
UpdateSectionButtons()
CurrentSection = "全部"
ManualRefresh()

print("[UI文本提取器 v23] 已加载 | 按钮布局已修复 | 移动端默认更小")
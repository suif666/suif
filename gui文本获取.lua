-- Roblox UI 文本提取器 收藏列表完整版
-- 第1段：基础初始化 + 主UI创建
-- 注意：需要把所有分段按顺序拼接到同一个脚本里再执行

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

pcall(function()
    if CoreGui:FindFirstChild("AutoTextCollectorUI") then
        CoreGui.AutoTextCollectorUI:Destroy()
    end
end)

pcall(function()
    if PlayerGui:FindFirstChild("AutoTextCollectorUI") then
        PlayerGui.AutoTextCollectorUI:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTextCollectorUI"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = PlayerGui
end

local Sections = {
    "全部",
    "PlayerGui",
    "Workspace",
    "CoreGui",
    "RobloxGui",
    "PlayerList",
    "第三方UI"
}

local CurrentSection = "全部"

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

local TextFilterKeywords = {
    "未检测到 UI 文本",
}

local SectionData = {}

for _, name in ipairs(Sections) do
    SectionData[name] = {
        Texts = {},
        Map = {},
        AllText = "未检测到 UI 文本",
    }
end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 350)
Main.Position = UDim2.new(0.5, -230, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Text = "UI 文本提取器 - 分区版"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.BackgroundColor3 = Color3.fromRGB(80, 80, 88)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.Font = Enum.Font.SourceSansBold
Minimize.Parent = Main

local Close = Instance.new("TextButton")
Close.BackgroundColor3 = Color3.fromRGB(180, 55, 60)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.SourceSansBold
Close.Parent = Main

local ContentFrame = Instance.new("Frame")
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Main

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Text = "状态：自动检测中"
Status.TextColor3 = Color3.fromRGB(200, 200, 205)
Status.Font = Enum.Font.SourceSans
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextTruncate = Enum.TextTruncate.AtEnd
Status.Parent = ContentFrame

local SectionFrame = Instance.new("Frame")
SectionFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
SectionFrame.BorderSizePixel = 0
SectionFrame.Parent = ContentFrame

local SearchBox = Instance.new("TextBox")
SearchBox.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderText = "搜索当前分区文本..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(155, 155, 160)
SearchBox.Font = Enum.Font.SourceSans
SearchBox.ClearTextOnFocus = false
SearchBox.Text = ""
SearchBox.Parent = ContentFrame

local SearchBtn = Instance.new("TextButton")
SearchBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 180)
SearchBtn.Text = "搜索"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.SourceSansBold
SearchBtn.Parent = ContentFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
Scroll.ScrollBarThickness = 8
Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
Scroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
Scroll.ScrollBarImageColor3 = Color3.fromRGB(170, 170, 175)
Scroll.CanvasPosition = Vector2.new(0, 0)
Scroll.ClipsDescendants = true
Scroll.Parent = ContentFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Scroll

local BottomBar = Instance.new("Frame")
BottomBar.BackgroundTransparency = 1
BottomBar.Parent = ContentFrame

local Refresh = Instance.new("TextButton")
Refresh.BackgroundColor3 = Color3.fromRGB(65, 120, 200)
Refresh.Text = "刷新"
Refresh.TextColor3 = Color3.fromRGB(255, 255, 255)
Refresh.Font = Enum.Font.SourceSansBold
Refresh.Parent = BottomBar

local Copy = Instance.new("TextButton")
Copy.BackgroundColor3 = Color3.fromRGB(70, 165, 90)
Copy.Text = "复制全部"
Copy.TextColor3 = Color3.fromRGB(255, 255, 255)
Copy.Font = Enum.Font.SourceSansBold
Copy.Parent = BottomBar

local AutoBtn = Instance.new("TextButton")
AutoBtn.BackgroundColor3 = Color3.fromRGB(160, 120, 60)
AutoBtn.Text = "自动：开"
AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.Font = Enum.Font.SourceSansBold
AutoBtn.Parent = BottomBar

local BlockBtn = Instance.new("TextButton")
BlockBtn.BackgroundColor3 = Color3.fromRGB(110, 80, 150)
BlockBtn.Text = "屏蔽：关"
BlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BlockBtn.Font = Enum.Font.SourceSansBold
BlockBtn.Parent = BottomBar

local FavoriteBtn = Instance.new("TextButton")
FavoriteBtn.BackgroundColor3 = Color3.fromRGB(90, 130, 210)
FavoriteBtn.Text = "打开收藏栏"
FavoriteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FavoriteBtn.Font = Enum.Font.SourceSansBold
FavoriteBtn.Parent = BottomBar

local ExportLuaBtn = Instance.new("TextButton")
ExportLuaBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 160)
ExportLuaBtn.Text = "导出Lua"
ExportLuaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExportLuaBtn.Font = Enum.Font.SourceSansBold
ExportLuaBtn.Parent = BottomBar

local ClearAll = Instance.new("TextButton")
ClearAll.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
ClearAll.Text = "清空当前"
ClearAll.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearAll.Font = Enum.Font.SourceSansBold
ClearAll.Parent = BottomBar

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
ResizeHandle.AnchorPoint = Vector2.new(1, 1)
ResizeHandle.Position = UDim2.new(1, -3, 1, -3)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(95, 95, 105)
ResizeHandle.Text = "↘"
ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
ResizeHandle.TextSize = 14
ResizeHandle.Font = Enum.Font.SourceSansBold
ResizeHandle.ZIndex = 10
ResizeHandle.Parent = Main

local AutoRefresh = true
local Minimized = false
local CurrentDisplayText = ""
local SectionButtons = {}

local AutoScrollToBottom = true

local BlockMode = false
local BlockedData = {}

for _, name in ipairs(Sections) do
    BlockedData[name] = {}
end

local FavoriteData = {
    Texts = {},
    Map = {},
}

local FavoriteMain
local FavoriteScroll
local FavoriteListLayout
local FavoriteStatus

local AddTextToFavorite
local DeleteTextFromCurrentList

local MinWidth = 360
local MinHeight = 270
local MaxWidth = 760
local MaxHeight = 580
local LastNormalSize = Vector2.new(460, 350)
local MiniCircleSize = 46
local LastNormalPosition = nil
-- 第2段：样式函数 + 基础工具函数 + 收藏列表UI

local function AddCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
    return corner
end

local function AddStroke(obj, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(70, 70, 78)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.25
    stroke.Parent = obj
    return stroke
end

local function StyleButton(btn, bgColor)
    btn.BackgroundColor3 = bgColor or btn.BackgroundColor3
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    AddCorner(btn, 7)
    AddStroke(btn, Color3.fromRGB(95, 95, 105), 1, 0.4)
end

local function StyleBox(obj)
    obj.BorderSizePixel = 0
    AddCorner(obj, 8)
    AddStroke(obj, Color3.fromRGB(90, 90, 100), 1, 0.38)
end

local MainCorner = AddCorner(Main, 12)
AddStroke(Main, Color3.fromRGB(100, 100, 110), 1, 0.2)

StyleBox(SectionFrame)
StyleBox(SearchBox)
StyleBox(Scroll)

StyleButton(SearchBtn, Color3.fromRGB(120, 90, 180))
StyleButton(Refresh, Color3.fromRGB(65, 120, 200))
StyleButton(Copy, Color3.fromRGB(70, 165, 90))
StyleButton(AutoBtn, Color3.fromRGB(160, 120, 60))
StyleButton(BlockBtn, Color3.fromRGB(110, 80, 150))
StyleButton(FavoriteBtn, Color3.fromRGB(90, 130, 210))
StyleButton(ExportLuaBtn, Color3.fromRGB(80, 150, 160))
StyleButton(ClearAll, Color3.fromRGB(180, 70, 70))
StyleButton(Close, Color3.fromRGB(180, 55, 60))
StyleButton(ResizeHandle, Color3.fromRGB(95, 95, 105))

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

local function GetSectionCount(sectionName)
    local data = SectionData[sectionName]
    if not data then
        return 0
    end
    return #data.Texts
end

local function RebuildSectionText(sectionName)
    local data = SectionData[sectionName]
    if not data then
        return
    end

    if #data.Texts == 0 then
        data.AllText = "未检测到 UI 文本"
    else
        data.AllText = table.concat(data.Texts, "\n")
    end
end

local function UpdateStatus(extra)
    local mode = AutoRefresh and "自动检测中" or "自动检测已关闭"
    local count = GetSectionCount(CurrentSection)
    local block = BlockMode and "屏蔽开" or "屏蔽关"

    if extra and extra ~= "" then
        Status.Text = "状态：" .. mode .. "｜" .. CurrentSection .. "｜" .. count .. "条｜" .. block .. "｜" .. extra
    else
        Status.Text = "状态：" .. mode .. "｜" .. CurrentSection .. "｜" .. count .. "条｜" .. block
    end
end

local function UpdateSectionButtons()
    for name, btn in pairs(SectionButtons) do
        if name == CurrentSection then
            btn.BackgroundColor3 = Color3.fromRGB(75, 125, 215)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(58, 58, 66)
            btn.TextColor3 = Color3.fromRGB(225, 225, 230)
        end

        btn.Text = name .. " [" .. GetSectionCount(name) .. "]"
    end
end

local function CopyText(text, hint)
    text = tostring(text or "")

    if setclipboard then
        setclipboard(text)
        UpdateStatus(hint or "已复制")
    elseif toclipboard then
        toclipboard(text)
        UpdateStatus(hint or "已复制")
    else
        UpdateStatus("当前环境不支持自动复制")
    end
end

local function RebuildFavoriteText()
    if #FavoriteData.Texts == 0 then
        return "收藏列表为空"
    end

    return table.concat(FavoriteData.Texts, "\n")
end

local function UpdateFavoriteStatus()
    if FavoriteStatus then
        FavoriteStatus.Text = "收藏列表｜共 " .. #FavoriteData.Texts .. " 条"
    end
end

local function RefreshFavoriteList()
    if not FavoriteScroll then
        return
    end

    for _, obj in ipairs(FavoriteScroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then
            obj:Destroy()
        end
    end

    for i, text in ipairs(FavoriteData.Texts) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -12, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = FavoriteScroll

        AddCorner(row, 6)
        AddStroke(row, Color3.fromRGB(75, 75, 85), 1, 0.45)

        local label = Instance.new("TextButton")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 6, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(245, 245, 245)
        label.TextSize = 13
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Text = text
        label.Parent = row

        label.MouseButton1Click:Connect(function()
            CopyText(text, "已复制收藏行")
        end)

        local del = Instance.new("TextButton")
        del.Size = UDim2.new(0, 42, 0, 24)
        del.Position = UDim2.new(1, -88, 0.5, -12)
        del.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
        del.Text = "删除"
        del.TextColor3 = Color3.fromRGB(255, 255, 255)
        del.TextSize = 12
        del.Font = Enum.Font.SourceSansBold
        del.Parent = row

        StyleButton(del, Color3.fromRGB(180, 70, 70))

        local copy = Instance.new("TextButton")
        copy.Size = UDim2.new(0, 42, 0, 24)
        copy.Position = UDim2.new(1, -44, 0.5, -12)
        copy.BackgroundColor3 = Color3.fromRGB(70, 165, 90)
        copy.Text = "复制"
        copy.TextColor3 = Color3.fromRGB(255, 255, 255)
        copy.TextSize = 12
        copy.Font = Enum.Font.SourceSansBold
        copy.Parent = row

        StyleButton(copy, Color3.fromRGB(70, 165, 90))

        copy.MouseButton1Click:Connect(function()
            CopyText(text, "已复制收藏行")
        end)

        del.MouseButton1Click:Connect(function()
            FavoriteData.Map[text] = nil

            for index = #FavoriteData.Texts, 1, -1 do
                if FavoriteData.Texts[index] == text then
                    table.remove(FavoriteData.Texts, index)
                    break
                end
            end

            RefreshFavoriteList()
            UpdateFavoriteStatus()
        end)
    end

    if #FavoriteData.Texts == 0 then
        local empty = Instance.new("TextButton")
        empty.Size = UDim2.new(1, -12, 0, 30)
        empty.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
        empty.BorderSizePixel = 0
        empty.TextColor3 = Color3.fromRGB(180, 180, 180)
        empty.TextSize = 13
        empty.Font = Enum.Font.SourceSans
        empty.TextXAlignment = Enum.TextXAlignment.Left
        empty.Text = "  收藏列表为空"
        empty.Parent = FavoriteScroll

        AddCorner(empty, 6)
        AddStroke(empty, Color3.fromRGB(75, 75, 85), 1, 0.45)
    end

    task.defer(function()
        task.wait()
        FavoriteScroll.CanvasSize = UDim2.new(0, 0, 0, FavoriteListLayout.AbsoluteContentSize.Y + 10)
    end)
end
-- 第3段：收藏列表窗口 + 主列表显示函数

local function CreateFavoriteUI()
    if FavoriteMain and FavoriteMain.Parent then
        FavoriteMain.Visible = true
        return
    end

    FavoriteMain = Instance.new("Frame")
    FavoriteMain.Size = UDim2.new(0, 360, 0, 300)
    FavoriteMain.Position = UDim2.new(0.5, -180, 0.5, -150)
    FavoriteMain.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    FavoriteMain.BorderSizePixel = 0
    FavoriteMain.Active = true
    FavoriteMain.Draggable = true
    FavoriteMain.Parent = ScreenGui

    AddCorner(FavoriteMain, 12)
    AddStroke(FavoriteMain, Color3.fromRGB(100, 100, 110), 1, 0.2)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -42, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "收藏列表"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = FavoriteMain

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 32, 0, 32)
    close.Position = UDim2.new(1, -32, 0, 0)
    close.BackgroundColor3 = Color3.fromRGB(180, 55, 60)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 14
    close.Font = Enum.Font.SourceSansBold
    close.Parent = FavoriteMain

    StyleButton(close, Color3.fromRGB(180, 55, 60))

    FavoriteStatus = Instance.new("TextLabel")
    FavoriteStatus.Size = UDim2.new(1, -20, 0, 20)
    FavoriteStatus.Position = UDim2.new(0, 10, 0, 34)
    FavoriteStatus.BackgroundTransparency = 1
    FavoriteStatus.TextColor3 = Color3.fromRGB(200, 200, 205)
    FavoriteStatus.TextSize = 12
    FavoriteStatus.Font = Enum.Font.SourceSans
    FavoriteStatus.TextXAlignment = Enum.TextXAlignment.Left
    FavoriteStatus.Parent = FavoriteMain

    FavoriteScroll = Instance.new("ScrollingFrame")
    FavoriteScroll.Size = UDim2.new(1, -20, 1, -105)
    FavoriteScroll.Position = UDim2.new(0, 10, 0, 58)
    FavoriteScroll.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
    FavoriteScroll.BorderSizePixel = 0
    FavoriteScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    FavoriteScroll.ScrollBarThickness = 8
    FavoriteScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    FavoriteScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    FavoriteScroll.Parent = FavoriteMain

    StyleBox(FavoriteScroll)

    FavoriteListLayout = Instance.new("UIListLayout")
    FavoriteListLayout.Padding = UDim.new(0, 4)
    FavoriteListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FavoriteListLayout.Parent = FavoriteScroll

    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(1, -20, 0, 34)
    bottom.Position = UDim2.new(0, 10, 1, -40)
    bottom.BackgroundTransparency = 1
    bottom.Parent = FavoriteMain

    local copyAll = Instance.new("TextButton")
    copyAll.Size = UDim2.new(0.333, -4, 1, 0)
    copyAll.Position = UDim2.new(0, 0, 0, 0)
    copyAll.BackgroundColor3 = Color3.fromRGB(70, 165, 90)
    copyAll.Text = "复制全部"
    copyAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyAll.TextSize = 13
    copyAll.Font = Enum.Font.SourceSansBold
    copyAll.Parent = bottom

    local exportLua = Instance.new("TextButton")
exportLua.Size = UDim2.new(0.333, -4, 1, 0)
exportLua.Position = UDim2.new(0.333, 4, 0, 0)
exportLua.BackgroundColor3 = Color3.fromRGB(80, 150, 160)
exportLua.Text = "导出Lua"
exportLua.TextColor3 = Color3.fromRGB(255, 255, 255)
exportLua.TextSize = 13
exportLua.Font = Enum.Font.SourceSansBold
exportLua.Parent = bottom

StyleButton(exportLua, Color3.fromRGB(80, 150, 160))

    StyleButton(copyAll, Color3.fromRGB(70, 165, 90))

    local clearAll = Instance.new("TextButton")
   clearAll.Size = UDim2.new(0.333, -4, 1, 0)
clearAll.Position = UDim2.new(0.666, 8, 0, 0)
    clearAll.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearAll.Text = "清空全部"
    clearAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearAll.TextSize = 13
    clearAll.Font = Enum.Font.SourceSansBold
    clearAll.Parent = bottom

    StyleButton(clearAll, Color3.fromRGB(180, 70, 70))

    copyAll.MouseButton1Click:Connect(function()
    CopyText(RebuildFavoriteText(), "已复制收藏全部")
end)

exportLua.MouseButton1Click:Connect(function()
    local lines = {}

    table.insert(lines, "-- 收藏列表文本导出")
    table.insert(lines, "-- 数量：" .. tostring(#FavoriteData.Texts))
    table.insert(lines, "")
    table.insert(lines, "return {")

    for _, text in ipairs(FavoriteData.Texts) do
        text = tostring(text or "")
        text = text:gsub("\\", "\\\\")
        text = text:gsub("\n", "\\n")
        text = text:gsub("\r", "\\r")
        text = text:gsub("\t", "\\t")
        text = text:gsub("\"", "\\\"")

        table.insert(lines, "    \"" .. text .. "\",")
    end

    table.insert(lines, "}")

    local luaText = table.concat(lines, "\n")
    local copied = false
    local saved = false

    if setclipboard then
        setclipboard(luaText)
        copied = true
    elseif toclipboard then
        toclipboard(luaText)
        copied = true
    end

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
        UpdateStatus("导出失败：不支持复制或写文件")
    end
end)

clearAll.MouseButton1Click:Connect(function()
    FavoriteData.Texts = {}
    FavoriteData.Map = {}
    RefreshFavoriteList()
    UpdateFavoriteStatus()
end)

    close.MouseButton1Click:Connect(function()
        FavoriteMain.Visible = false
    end)

    UpdateFavoriteStatus()
    RefreshFavoriteList()
end

AddTextToFavorite = function(text)
    text = CleanText(text)

    if text == "" then
        return
    end

    if not FavoriteData.Map[text] then
        FavoriteData.Map[text] = true
        table.insert(FavoriteData.Texts, text)
    end

    CreateFavoriteUI()
    RefreshFavoriteList()
    UpdateFavoriteStatus()
    UpdateStatus("已添加进收藏列表")
end

local function ClearScrollItems()
    for _, obj in ipairs(Scroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then
            obj:Destroy()
        end
    end
end

local function ResizeScrollCanvas()
    task.defer(function()
        task.wait()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)
end

local function ScrollToBottom()
    if not AutoScrollToBottom then
        return
    end

    task.defer(function()
        task.wait()
        local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
        Scroll.CanvasPosition = Vector2.new(0, maxY)
    end)
end

local function SetDisplayText(text, autoBottom)
    CurrentDisplayText = text
    ClearScrollItems()

    local index = 0

    for line in string.gmatch(text .. "\n", "(.-)\n") do
        line = CleanText(line)

        if line ~= "" then
            index = index + 1

            local displayLine = line
            if #displayLine > 500 then
                displayLine = string.sub(displayLine, 1, 500) .. "..."
            end

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -12, 0, 31)
            row.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
            row.BorderSizePixel = 0
            row.LayoutOrder = index
            row.Parent = Scroll

            AddCorner(row, 6)
            AddStroke(row, Color3.fromRGB(75, 75, 85), 1, 0.45)

            local label = Instance.new("TextButton")
            label.Size = UDim2.new(1, -150, 1, 0)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(245, 245, 245)
            label.TextSize = 13
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.TextWrapped = false
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = displayLine
            label.Parent = row

            label.MouseButton1Click:Connect(function()
                CopyText(line, "已复制当前行")
            end)

            local addBtn = Instance.new("TextButton")
            addBtn.Size = UDim2.new(0, 42, 0, 24)
            addBtn.Position = UDim2.new(1, -138, 0.5, -12)
            addBtn.BackgroundColor3 = Color3.fromRGB(90, 130, 210)
            addBtn.Text = "添加"
            addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            addBtn.TextSize = 12
            addBtn.Font = Enum.Font.SourceSansBold
            addBtn.Parent = row

            StyleButton(addBtn, Color3.fromRGB(90, 130, 210))

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 42, 0, 24)
            delBtn.Position = UDim2.new(1, -92, 0.5, -12)
            delBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
            delBtn.Text = "删除"
            delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            delBtn.TextSize = 12
            delBtn.Font = Enum.Font.SourceSansBold
            delBtn.Parent = row

            StyleButton(delBtn, Color3.fromRGB(180, 70, 70))

            local copyBtn = Instance.new("TextButton")
            copyBtn.Size = UDim2.new(0, 42, 0, 24)
            copyBtn.Position = UDim2.new(1, -46, 0.5, -12)
            copyBtn.BackgroundColor3 = Color3.fromRGB(70, 165, 90)
            copyBtn.Text = "复制"
            copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyBtn.TextSize = 12
            copyBtn.Font = Enum.Font.SourceSansBold
            copyBtn.Parent = row

            StyleButton(copyBtn, Color3.fromRGB(70, 165, 90))

            addBtn.MouseButton1Click:Connect(function()
                AddTextToFavorite(line)
            end)

            delBtn.MouseButton1Click:Connect(function()
                if DeleteTextFromCurrentList then
                    DeleteTextFromCurrentList(line)
                end
            end)

            copyBtn.MouseButton1Click:Connect(function()
                CopyText(line, "已复制当前行")
            end)
        end
    end

    if index == 0 then
        local empty = Instance.new("TextButton")
        empty.Size = UDim2.new(1, -12, 0, 30)
        empty.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
        empty.BorderSizePixel = 0
        empty.TextColor3 = Color3.fromRGB(180, 180, 180)
        empty.TextSize = 13
        empty.Font = Enum.Font.SourceSans
        empty.TextXAlignment = Enum.TextXAlignment.Left
        empty.Text = "  未检测到 UI 文本"
        empty.LayoutOrder = 1
        empty.Parent = Scroll

        AddCorner(empty, 6)
        AddStroke(empty, Color3.fromRGB(75, 75, 85), 1, 0.45)
    end

    ResizeScrollCanvas()

    if autoBottom then
        ScrollToBottom()
    end
end
-- 第4段：文本保存/扫描/搜索/删除逻辑

local function ShouldIgnoreText(text)
    text = CleanText(text)

    if text == "" then
        return true
    end

    if ContainsKeyword(text, TextFilterKeywords) then
        return true
    end

    return false
end

local function IsTextBlocked(sectionName, text)
    text = CleanText(text)

    if not BlockMode then
        return false
    end

    if BlockedData[sectionName] and BlockedData[sectionName][text] then
        return true
    end

    return false
end

local function SaveTextToSection(sectionName, text)
    text = CleanText(text)

    if ShouldIgnoreText(text) then
        return false
    end

    if IsTextBlocked(sectionName, text) then
        return false
    end

    local data = SectionData[sectionName]
    if not data then
        return false
    end

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

    local sourceAdded = SaveTextToSection(sourceSection, text)

    if sourceAdded then
        added = true

        if sourceSection ~= "全部" then
            if SaveTextToSection("全部", text) then
                added = true
            end
        end
    end

    return added
end

local function ShouldObjectBelongToSection(obj, sectionName)
    if not obj then
        return false
    end

    if obj:IsDescendantOf(ScreenGui) then
        return false
    end

    if not IsObjectVisible(obj) then
        return false
    end

    local path = GetObjectPath(obj)

    if sectionName == "PlayerGui" then
        return obj:IsDescendantOf(PlayerGui)
    end

    if sectionName == "Workspace" then
        return obj:IsDescendantOf(Workspace)
    end

    if sectionName == "CoreGui" then
        return obj:IsDescendantOf(CoreGui)
    end

    if sectionName == "RobloxGui" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "RobloxGui", 1, true) ~= nil
    end

    if sectionName == "PlayerList" then
        return obj:IsDescendantOf(CoreGui) and string.find(path, "PlayerList", 1, true) ~= nil
    end

    if sectionName == "第三方UI" then
        if not obj:IsDescendantOf(CoreGui) then
            return false
        end

        if IsRobloxSystemObject(obj) then
            return false
        end

        return true
    end

    if sectionName == "全部" then
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
        if obj.LocalizedText then
            trySave(obj.LocalizedText)
        end
    end)

    return added
end

local function ScanOneContainerForSection(container, sectionName)
    local added = 0

    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox") then
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
        added = added + ScanOneContainerForSection(CoreGui, "第三方UI")
    elseif sectionName == "全部" then
        added = added + ScanSection("PlayerGui")
        added = added + ScanSection("Workspace")
        added = added + ScanSection("CoreGui")
    end

    RebuildSectionText(sectionName)
    RebuildSectionText("全部")

    return added
end

local function GetCurrentAllText()
    local data = SectionData[CurrentSection]

    if not data then
        return "未检测到 UI 文本"
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

local function BuildLuaExport()
    local data = SectionData[CurrentSection]
    local lines = {}

    table.insert(lines, "-- UI文本导出")
    table.insert(lines, "-- 分区：" .. CurrentSection)
    table.insert(lines, "-- 数量：" .. tostring(GetSectionCount(CurrentSection)))
    table.insert(lines, "")
    table.insert(lines, "return {")

    if data and #data.Texts > 0 then
        for _, text in ipairs(data.Texts) do
            table.insert(lines, "    \"" .. EscapeLuaString(text) .. "\",")
        end
    end

    table.insert(lines, "}")

    return table.concat(lines, "\n")
end

local function ExportCurrentSectionAsLua()
    local luaText = BuildLuaExport()

    local copied = false
    local saved = false

    if setclipboard then
        setclipboard(luaText)
        copied = true
    elseif toclipboard then
        toclipboard(luaText)
        copied = true
    end

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

    RebuildSectionText(CurrentSection)

    return data.AllText
end

local function SearchText()
    local keyword = CleanText(SearchBox.Text)
    local data = SectionData[CurrentSection]

    if not data then
        return
    end

    if keyword == "" then
        SetDisplayText(GetCurrentAllText(), false)
        Scroll.CanvasPosition = Vector2.new(0, 0)
        UpdateStatus("显示全部文本")
        return
    end

    local result = {}
    local lowerKeyword = string.lower(keyword)

    for _, line in ipairs(data.Texts) do
        if string.find(string.lower(line), lowerKeyword, 1, true) then
            table.insert(result, line)
        end
    end

    if #result == 0 then
        SetDisplayText("没有搜索到包含【" .. keyword .. "】的文本", false)
        UpdateStatus("搜索结果 0 条")
    else
        SetDisplayText(table.concat(result, "\n"), false)
        UpdateStatus("搜索结果 " .. #result .. " 条")
    end

    Scroll.CanvasPosition = Vector2.new(0, 0)
end

local function RefreshDisplay(added)
    UpdateSectionButtons()

    if CleanText(SearchBox.Text) ~= "" then
        SearchText()
    else
        if added and added > 0 then
            SetDisplayText(GetCurrentAllText(), true)
            UpdateStatus("新增 " .. added .. " 条，已自动滚动")
        else
            SetDisplayText(GetCurrentAllText(), false)
            UpdateStatus("暂无新增")
        end
    end
end

local function ManualRefresh()
    local added = ScanSection(CurrentSection)
    RefreshDisplay(added)
end

local function SwitchSection(sectionName)
    CurrentSection = sectionName
    SearchBox.Text = ""
    SetDisplayText(GetCurrentAllText(), false)
    Scroll.CanvasPosition = Vector2.new(0, 0)
    UpdateSectionButtons()
    UpdateStatus("已切换分区")
end

local function ClearBlockList()
    for _, name in ipairs(Sections) do
        BlockedData[name] = {}
    end
end

local function AddCurrentSectionToBlockList()
    if not BlockMode then
        return
    end

    if CurrentSection == "全部" then
        for _, sectionName in ipairs(Sections) do
            local sectionData = SectionData[sectionName]

            if sectionData then
                for _, text in ipairs(sectionData.Texts) do
                    text = CleanText(text)

                    if text ~= "" then
                        BlockedData[sectionName][text] = true
                    end
                end
            end
        end

        return
    end

    local data = SectionData[CurrentSection]

    if not data then
        return
    end

    for _, text in ipairs(data.Texts) do
        text = CleanText(text)

        if text ~= "" then
            BlockedData[CurrentSection][text] = true
            BlockedData["全部"][text] = true
        end
    end
end

local function RebuildAllSectionFromOtherSections()
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
    text = CleanText(text)

    local data = SectionData[sectionName]
    if not data then
        return
    end

    data.Map[text] = nil

    for i = #data.Texts, 1, -1 do
        if data.Texts[i] == text then
            table.remove(data.Texts, i)
        end
    end

    RebuildSectionText(sectionName)
end

DeleteTextFromCurrentList = function(text)
    text = CleanText(text)

    if text == "" then
        return
    end

    if BlockMode then
        if CurrentSection == "全部" then
            for _, sectionName in ipairs(Sections) do
                BlockedData[sectionName][text] = true
            end
        else
            BlockedData[CurrentSection][text] = true
            BlockedData["全部"][text] = true
        end
    end

    if CurrentSection == "全部" then
        for _, sectionName in ipairs(Sections) do
            RemoveTextFromSection(sectionName, text)
        end
    else
        RemoveTextFromSection(CurrentSection, text)
        RebuildAllSectionFromOtherSections()
    end

    local oldCanvasPosition = Scroll.CanvasPosition

if CleanText(SearchBox.Text) ~= "" then
    SearchText()
else
    SetDisplayText(GetCurrentAllText(), false)
end

task.defer(function()
    task.wait()
    local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
    Scroll.CanvasPosition = Vector2.new(0, math.clamp(oldCanvasPosition.Y, 0, maxY))
end)

UpdateSectionButtons()

    if BlockMode then
        UpdateStatus("已删除并加入屏蔽")
    else
        UpdateStatus("已从当前列表删除")
    end
end

local function ClearCurrentSection()
    local data = SectionData[CurrentSection]

    if not data then
        return
    end

    AddCurrentSectionToBlockList()

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
        RebuildAllSectionFromOtherSections()
    end

    SearchBox.Text = ""
    SetDisplayText(GetCurrentAllText(), false)
    Scroll.CanvasPosition = Vector2.new(0, 0)
    UpdateSectionButtons()

    if BlockMode then
        UpdateStatus("已清空并加入屏蔽")
    else
        UpdateStatus("已清空当前分区")
    end
end
-- 第5段：分区按钮 + 布局 + 所有按钮事件 + 启动循环

for i, sectionName in ipairs(Sections) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(58, 58, 66)
    btn.TextColor3 = Color3.fromRGB(225, 225, 230)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = sectionName .. " [0]"
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.BorderSizePixel = 0
    btn.Parent = SectionFrame

    AddCorner(btn, 6)
    AddStroke(btn, Color3.fromRGB(80, 80, 90), 1, 0.45)

    btn.MouseButton1Click:Connect(function()
        SwitchSection(sectionName)
    end)

    SectionButtons[sectionName] = btn
end

local function LayoutUI()
    if Minimized then
        return
    end

    local w = Main.AbsoluteSize.X
    local h = Main.AbsoluteSize.Y

    local compact = w < 420 or h < 315
    local tiny = w < 380 or h < 285

    local titleH = tiny and 28 or 32
    local pad = tiny and 5 or 8
    local titleSize = tiny and 14 or 16
    local buttonH = tiny and 28 or 34
    local searchH = tiny and 24 or 28
    local statusH = tiny and 18 or 20
    local sectionRows = compact and 3 or 2
    local sectionCols = compact and 3 or 4
    local sectionH = sectionRows * (tiny and 22 or 25) + 6

    Title.Size = UDim2.new(1, -76, 0, titleH)
    Title.Position = UDim2.new(0, pad, 0, 0)
    Title.TextSize = titleSize

    Minimize.Size = UDim2.new(0, titleH, 0, titleH)
    Minimize.Position = UDim2.new(1, -titleH * 2, 0, 0)
    Minimize.TextSize = titleSize + 2

    Close.Size = UDim2.new(0, titleH, 0, titleH)
    Close.Position = UDim2.new(1, -titleH, 0, 0)
    Close.TextSize = titleSize

    ContentFrame.Size = UDim2.new(1, 0, 1, -titleH)
    ContentFrame.Position = UDim2.new(0, 0, 0, titleH)

    Status.Size = UDim2.new(1, -pad * 2, 0, statusH)
    Status.Position = UDim2.new(0, pad, 0, 0)
    Status.TextSize = tiny and 10 or 12

    SectionFrame.Size = UDim2.new(1, -pad * 2, 0, sectionH)
    SectionFrame.Position = UDim2.new(0, pad, 0, statusH + 2)

    local btnWScale = 1 / sectionCols

    for i, sectionName in ipairs(Sections) do
        local btn = SectionButtons[sectionName]
        local row = math.floor((i - 1) / sectionCols)
        local col = (i - 1) % sectionCols
        local bh = tiny and 20 or 23

        btn.Size = UDim2.new(btnWScale, -5, 0, bh)
        btn.Position = UDim2.new(col * btnWScale, 3 + col * 1, 0, 3 + row * (bh + 3))
        btn.TextSize = tiny and 9 or 11
    end

    local searchY = statusH + 2 + sectionH + 6
    local searchBtnW = tiny and 58 or 72

    SearchBox.Size = UDim2.new(1, -pad * 2 - searchBtnW - 6, 0, searchH)
    SearchBox.Position = UDim2.new(0, pad, 0, searchY)
    SearchBox.TextSize = tiny and 11 or 13

    SearchBtn.Size = UDim2.new(0, searchBtnW, 0, searchH)
    SearchBtn.Position = UDim2.new(1, -pad - searchBtnW, 0, searchY)
    SearchBtn.TextSize = tiny and 11 or 13

    BottomBar.Size = UDim2.new(1, -pad * 2, 0, buttonH)
    BottomBar.Position = UDim2.new(0, pad, 1, -buttonH - pad)

   local bottomButtons = {Refresh, Copy, AutoBtn, BlockBtn, FavoriteBtn, ExportLuaBtn, ClearAll}
    local bw = 1 / #bottomButtons

    for i, btn in ipairs(bottomButtons) do
        btn.Size = UDim2.new(bw, -5, 1, 0)
        btn.Position = UDim2.new((i - 1) * bw, (i - 1) * 2, 0, 0)
        btn.TextSize = tiny and 9 or 12
    end

    local scrollY = searchY + searchH + 6
    local scrollBottom = buttonH + pad + 6
    local scrollH = math.max(70, h - titleH - scrollY - scrollBottom)

    Scroll.Size = UDim2.new(1, -pad * 2, 0, scrollH)
    Scroll.Position = UDim2.new(0, pad, 0, scrollY)

    ResizeHandle.Size = UDim2.new(0, tiny and 18 or 22, 0, tiny and 18 or 22)
    ResizeHandle.Position = UDim2.new(1, -3, 1, -3)

    ResizeScrollCanvas()
end

Refresh.MouseButton1Click:Connect(function()
    ManualRefresh()
end)

Copy.MouseButton1Click:Connect(function()
    CopyText(CurrentDisplayText, "已复制当前显示全部")
end)

AutoBtn.MouseButton1Click:Connect(function()
    AutoRefresh = not AutoRefresh

    if AutoRefresh then
        AutoBtn.Text = "自动：开"
    else
        AutoBtn.Text = "自动：关"
    end

    UpdateStatus()
end)

BlockBtn.MouseButton1Click:Connect(function()
    BlockMode = not BlockMode

    if BlockMode then
        BlockBtn.Text = "屏蔽：开"
        BlockBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 180)
        UpdateStatus("屏蔽文本已开启")
    else
        BlockBtn.Text = "屏蔽：关"
        BlockBtn.BackgroundColor3 = Color3.fromRGB(110, 80, 150)
        ClearBlockList()
        UpdateStatus("屏蔽文本已关闭，记录已清空")
    end
end)

FavoriteBtn.MouseButton1Click:Connect(function()
    CreateFavoriteUI()
    RefreshFavoriteList()
    UpdateFavoriteStatus()
    UpdateStatus("已打开收藏栏")
end)

ExportLuaBtn.MouseButton1Click:Connect(function()
    ExportCurrentSectionAsLua()
end)

SearchBtn.MouseButton1Click:Connect(function()
    SearchText()
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        SearchText()
    end
end)

ClearAll.MouseButton1Click:Connect(function()
    ClearCurrentSection()
end)

Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized

    if Minimized then
        LastNormalSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        LastNormalPosition = Main.Position

        ContentFrame.Visible = false
        Title.Visible = false
        Close.Visible = false
        ResizeHandle.Visible = false

        Main.Draggable = true
        Main.Size = UDim2.new(0, MiniCircleSize, 0, MiniCircleSize)
        MainCorner.CornerRadius = UDim.new(1, 0)

        Minimize.Size = UDim2.new(1, 0, 1, 0)
        Minimize.Position = UDim2.new(0, 0, 0, 0)
        Minimize.Text = "+"
        Minimize.TextSize = 24
        Minimize.BackgroundColor3 = Color3.fromRGB(75, 125, 215)
        Minimize.ZIndex = 20
    else
        ContentFrame.Visible = true
        Title.Visible = true
        Close.Visible = true
        ResizeHandle.Visible = true

        Main.Size = UDim2.new(0, LastNormalSize.X, 0, LastNormalSize.Y)

        if LastNormalPosition then
            Main.Position = LastNormalPosition
        end

        MainCorner.CornerRadius = UDim.new(0, 12)

        Minimize.Text = "-"
        Minimize.BackgroundColor3 = Color3.fromRGB(80, 80, 88)
        Minimize.ZIndex = 1

        LayoutUI()
    end
end)

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ResizeScrollCanvas()
end)

Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if not Minimized then
        LayoutUI()
    end
end)

local resizing = false
local resizeStartPos = nil
local resizeStartSize = nil

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Main.AbsoluteSize
        Main.Draggable = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not resizing then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - resizeStartPos
    local newW = math.clamp(resizeStartSize.X + delta.X, MinWidth, MaxWidth)
    local newH = math.clamp(resizeStartSize.Y + delta.Y, MinHeight, MaxHeight)

    Main.Size = UDim2.new(0, newW, 0, newH)
    LastNormalSize = Vector2.new(newW, newH)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        Main.Draggable = true
    end
end)

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if AutoRefresh then
            local added = ScanSection(CurrentSection)
            RefreshDisplay(added)
        else
            UpdateSectionButtons()
            UpdateStatus()
        end

        task.wait(1)
    end
end)

LayoutUI()
SwitchSection("全部")
ManualRefresh()

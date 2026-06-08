-- Roblox UI 文本提取器 v13 重写稳定版
-- 功能：分区扫描 / 手动刷新 / 自动刷新勾选 / 搜索 / 复制 / 收藏栏 / 导出Lua / 删除 / 屏蔽 / 缩放 / 最小化圆圈

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
    if ok then return hui end
    return nil
end

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
    RobloxGui = true,
    PlayerList = true,
    Backpack = true,
    Chat = true,
    BubbleChat = true,
    ExperienceChat = true,
    TextChatService = true,
    TopBar = true,
    Topbar = true,
    Health = true,
    EmotesMenu = true,
    Chrome = true,
    InspectMenu = true,
    PurchasePrompt = true,
    ScreenshotHud = true,
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
local LastNormalSize = Vector2.new(520, 380)
local LastNormalPosition = nil
local MiniCircleSize = 46

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
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    str = str:gsub("\"", "\\\"")
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
    if #data.Texts == 0 then
        data.AllText = "未检测到 UI 文本"
    else
        data.AllText = table.concat(data.Texts, "\n")
    end
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
    if not data then return false end
    if data.Map[text] then return false end
    data.Map[text] = true
    table.insert(data.Texts, text)
    Rebuild(section)
    return true
end

local function AddTextWithAll(section, text)
    local added = false
    if AddText(section, text) then added = true end
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
        if not inGui then return false end
        if IsSystemUI(obj) then return false end
        return true
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
        -- Workspace 很可能很大，全部分区不自动扫它，手动切到 Workspace 再刷新更稳
    end
    Rebuild(section)
    Rebuild("全部")
    return added
end

--====================================================
-- UI 创建
--====================================================

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
    return New("UIStroke", {Color = color or Color3.fromRGB(80,80,90), Thickness = t or 1, Transparency = tr or 0.35}, obj)
end

local function StyleButton(btn, color)
    btn.BackgroundColor3 = color or btn.BackgroundColor3
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    Corner(btn, 7)
    Stroke(btn, Color3.fromRGB(95,95,105), 1, 0.4)
end

local Main = New("Frame", {
    Size = UDim2.new(0, 520, 0, 380),
    Position = UDim2.new(0.5, -260, 0.5, -190),
    BackgroundColor3 = Color3.fromRGB(24,24,28),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, ScreenGui)
local MainCorner = Corner(Main, 12)
Stroke(Main, Color3.fromRGB(100,100,110), 1, 0.2)

local Title = New("TextLabel", {BackgroundTransparency=1, Text="UI 文本提取器 - 分区版", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, Main)
local MinBtn = New("TextButton", {Text="-", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(80,80,88)}, Main)
local CloseBtn = New("TextButton", {Text="X", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(180,55,60)}, Main)
StyleButton(MinBtn, Color3.fromRGB(80,80,88))
StyleButton(CloseBtn, Color3.fromRGB(180,55,60))

local Content = New("Frame", {BackgroundTransparency=1}, Main)
local StatusLabel = New("TextLabel", {BackgroundTransparency=1, Text="状态：待刷新", TextColor3=Color3.fromRGB(200,200,205), Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, Content)
local SectionFrame = New("Frame", {BackgroundColor3=Color3.fromRGB(32,32,38), BorderSizePixel=0}, Content)
Corner(SectionFrame,8); Stroke(SectionFrame, Color3.fromRGB(90,90,100),1,0.38)

local SearchBox = New("TextBox", {Text="", PlaceholderText="搜索当前分区文本...", ClearTextOnFocus=false, BackgroundColor3=Color3.fromRGB(38,38,45), TextColor3=Color3.new(1,1,1), PlaceholderColor3=Color3.fromRGB(155,155,160), Font=Enum.Font.SourceSans}, Content)
Corner(SearchBox,8); Stroke(SearchBox, Color3.fromRGB(90,90,100),1,0.38)
local SearchBtn = New("TextButton", {Text="搜索", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(120,90,180)}, Content)
StyleButton(SearchBtn, Color3.fromRGB(120,90,180))

local Scroll = New("ScrollingFrame", {BackgroundColor3=Color3.fromRGB(34,34,40), BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y, VerticalScrollBarInset=Enum.ScrollBarInset.Always, ScrollBarImageColor3=Color3.fromRGB(170,170,175), ClipsDescendants=true}, Content)
Corner(Scroll,8); Stroke(Scroll, Color3.fromRGB(90,90,100),1,0.38)
local ListLayout = New("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, Scroll)

local BottomBar = New("Frame", {BackgroundTransparency=1}, Content)
local RefreshBtn = New("TextButton", {Text="刷新", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(65,120,200)}, BottomBar)
local AutoCheckBtn = New("TextButton", {Text="☐ 自动刷新", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(160,120,60)}, BottomBar)
local CopyBtn = New("TextButton", {Text="复制全部", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(70,165,90)}, BottomBar)
local BlockBtn = New("TextButton", {Text="屏蔽：关", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(110,80,150)}, BottomBar)
local FavBtn = New("TextButton", {Text="打开收藏栏", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(90,130,210)}, BottomBar)
local ExportBtn = New("TextButton", {Text="导出Lua", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(80,150,160)}, BottomBar)
local ClearBtn = New("TextButton", {Text="清空当前", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(180,70,70)}, BottomBar)
for _, b in ipairs({RefreshBtn,AutoCheckBtn,CopyBtn,BlockBtn,FavBtn,ExportBtn,ClearBtn}) do StyleButton(b, b.BackgroundColor3) end

local ResizeHandle = New("TextButton", {Size=UDim2.new(0,22,0,22), AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-3,1,-3), Text="↘", TextColor3=Color3.new(1,1,1), TextSize=14, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(95,95,105), ZIndex=10}, Main)
StyleButton(ResizeHandle, Color3.fromRGB(95,95,105))

local SectionButtons = {}
for _, section in ipairs(Sections) do
    local b = New("TextButton", {Text=section.." [0]", TextColor3=Color3.fromRGB(225,225,230), Font=Enum.Font.SourceSansBold, TextTruncate=Enum.TextTruncate.AtEnd, BorderSizePixel=0, BackgroundColor3=Color3.fromRGB(58,58,66)}, SectionFrame)
    Corner(b,6); Stroke(b, Color3.fromRGB(80,80,90),1,0.45)
    b.MouseButton1Click:Connect(function()
        CurrentSection = section
        SearchBox.Text = ""
        -- later refresh display
    end)
    SectionButtons[section] = b
end

local FavoriteMain, FavoriteScroll, FavoriteListLayout, FavoriteStatus

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
            b.BackgroundColor3 = Color3.fromRGB(75,125,215)
            b.TextColor3 = Color3.new(1,1,1)
        else
            b.BackgroundColor3 = Color3.fromRGB(58,58,66)
            b.TextColor3 = Color3.fromRGB(225,225,230)
        end
        b.Text = name.." ["..Count(name).."]"
    end
end

local function CopyText(text, msg)
    text = tostring(text or "")
    if setclipboard then
        setclipboard(text); UpdateStatus(msg or "已复制")
    elseif toclipboard then
        toclipboard(text); UpdateStatus(msg or "已复制")
    else
        UpdateStatus("当前环境不支持复制")
    end
end

local function ExportLua(title, texts, fileName)
    local lines = {}
    table.insert(lines, "-- UI文本导出")
    table.insert(lines, "-- 名称："..tostring(title or "未知"))
    table.insert(lines, "-- 数量："..tostring(texts and #texts or 0))
    table.insert(lines, "")
    table.insert(lines, "return {")
    if texts then
        for _, text in ipairs(texts) do
            table.insert(lines, "    \""..EscapeLuaString(text).."\",")
        end
    end
    table.insert(lines, "}")
    local luaText = table.concat(lines, "\n")
    local copied, saved = false, false
    if setclipboard then setclipboard(luaText); copied = true elseif toclipboard then toclipboard(luaText); copied = true end
    if writefile then writefile(fileName or "UITextExport.lua", luaText); saved = true end
    if copied and saved then UpdateStatus("已导出Lua：已复制并保存") elseif copied then UpdateStatus("已导出Lua：已复制") elseif saved then UpdateStatus("已导出Lua：已保存") else UpdateStatus("导出失败：不支持复制或写文件") end
end

local function ClearScroll()
    for _, obj in ipairs(Scroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then obj:Destroy() end
    end
end

local function ResizeCanvas()
    task.defer(function()
        task.wait()
        Scroll.CanvasSize = UDim2.new(0,0,0,ListLayout.AbsoluteContentSize.Y + 10)
    end)
end

local function ScrollBottom()
    if not AutoScrollToBottom then return end
    task.defer(function()
        task.wait()
        local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
        Scroll.CanvasPosition = Vector2.new(0, maxY)
    end)
end

local function GetCurrentText()
    Rebuild(CurrentSection)
    return SectionData[CurrentSection] and SectionData[CurrentSection].AllText or "未检测到 UI 文本"
end

local function RefreshFavoriteList()
    if not FavoriteScroll then return end
    for _, obj in ipairs(FavoriteScroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then obj:Destroy() end
    end
    for i, text in ipairs(FavoriteData.Texts) do
        local row = New("Frame", {Size=UDim2.new(1,-12,0,30), BackgroundColor3=Color3.fromRGB(48,48,56), BorderSizePixel=0, LayoutOrder=i}, FavoriteScroll)
        Corner(row,6); Stroke(row, Color3.fromRGB(75,75,85),1,0.45)
        local label = New("TextButton", {Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,6,0,0), BackgroundTransparency=1, Text=text, TextColor3=Color3.fromRGB(245,245,245), TextSize=13, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
        local del = New("TextButton", {Size=UDim2.new(0,42,0,24), Position=UDim2.new(1,-88,0.5,-12), Text="删除", TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(180,70,70)}, row)
        local copy = New("TextButton", {Size=UDim2.new(0,42,0,24), Position=UDim2.new(1,-44,0.5,-12), Text="复制", TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(70,165,90)}, row)
        StyleButton(del, del.BackgroundColor3); StyleButton(copy, copy.BackgroundColor3)
        label.MouseButton1Click:Connect(function() CopyText(text, "已复制收藏行") end)
        copy.MouseButton1Click:Connect(function() CopyText(text, "已复制收藏行") end)
        del.MouseButton1Click:Connect(function()
            FavoriteData.Map[text] = nil
            for n = #FavoriteData.Texts, 1, -1 do if FavoriteData.Texts[n] == text then table.remove(FavoriteData.Texts,n); break end end
            RefreshFavoriteList()
            if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        end)
    end
    if #FavoriteData.Texts == 0 then
        local empty = New("TextButton", {Size=UDim2.new(1,-12,0,30), BackgroundColor3=Color3.fromRGB(48,48,56), BorderSizePixel=0, Text="  收藏列表为空", TextColor3=Color3.fromRGB(180,180,180), TextSize=13, Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left}, FavoriteScroll)
        Corner(empty,6); Stroke(empty, Color3.fromRGB(75,75,85),1,0.45)
    end
    task.defer(function() task.wait(); FavoriteScroll.CanvasSize = UDim2.new(0,0,0,FavoriteListLayout.AbsoluteContentSize.Y + 10) end)
end

local function CreateFavoriteUI()
    if FavoriteMain and FavoriteMain.Parent then
        FavoriteMain.Visible = true
        RefreshFavoriteList()
        if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        return
    end
    FavoriteMain = New("Frame", {Size=UDim2.new(0,380,0,310), Position=UDim2.new(0.5,-190,0.5,-155), BackgroundColor3=Color3.fromRGB(24,24,28), BorderSizePixel=0, Active=true, Draggable=true}, ScreenGui)
    Corner(FavoriteMain,12); Stroke(FavoriteMain, Color3.fromRGB(100,100,110),1,0.2)
    New("TextLabel", {Size=UDim2.new(1,-42,0,32), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text="收藏列表", TextColor3=Color3.new(1,1,1), TextSize=16, Font=Enum.Font.SourceSansBold, TextXAlignment=Enum.TextXAlignment.Left}, FavoriteMain)
    local close = New("TextButton", {Size=UDim2.new(0,32,0,32), Position=UDim2.new(1,-32,0,0), BackgroundColor3=Color3.fromRGB(180,55,60), Text="X", TextColor3=Color3.new(1,1,1), TextSize=14, Font=Enum.Font.SourceSansBold}, FavoriteMain)
    StyleButton(close, close.BackgroundColor3)
    FavoriteStatus = New("TextLabel", {Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,0,34), BackgroundTransparency=1, TextColor3=Color3.fromRGB(200,200,205), TextSize=12, Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left}, FavoriteMain)
    FavoriteScroll = New("ScrollingFrame", {Size=UDim2.new(1,-20,1,-105), Position=UDim2.new(0,10,0,58), BackgroundColor3=Color3.fromRGB(34,34,40), BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y, VerticalScrollBarInset=Enum.ScrollBarInset.Always}, FavoriteMain)
    Corner(FavoriteScroll,8); Stroke(FavoriteScroll, Color3.fromRGB(90,90,100),1,0.38)
    FavoriteListLayout = New("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, FavoriteScroll)
    local bottom = New("Frame", {Size=UDim2.new(1,-20,0,34), Position=UDim2.new(0,10,1,-40), BackgroundTransparency=1}, FavoriteMain)
    local copyAll = New("TextButton", {Size=UDim2.new(0.333,-4,1,0), Position=UDim2.new(0,0,0,0), Text="复制全部", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, TextSize=13, BackgroundColor3=Color3.fromRGB(70,165,90)}, bottom)
    local exportLua = New("TextButton", {Size=UDim2.new(0.333,-4,1,0), Position=UDim2.new(0.333,4,0,0), Text="导出Lua", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, TextSize=13, BackgroundColor3=Color3.fromRGB(80,150,160)}, bottom)
    local clearAll = New("TextButton", {Size=UDim2.new(0.333,-4,1,0), Position=UDim2.new(0.666,8,0,0), Text="清空全部", TextColor3=Color3.new(1,1,1), Font=Enum.Font.SourceSansBold, TextSize=13, BackgroundColor3=Color3.fromRGB(180,70,70)}, bottom)
    StyleButton(copyAll, copyAll.BackgroundColor3); StyleButton(exportLua, exportLua.BackgroundColor3); StyleButton(clearAll, clearAll.BackgroundColor3)
    close.MouseButton1Click:Connect(function() FavoriteMain.Visible = false end)
    copyAll.MouseButton1Click:Connect(function() CopyText(table.concat(FavoriteData.Texts,"\n"), "已复制收藏全部") end)
    exportLua.MouseButton1Click:Connect(function() ExportLua("收藏列表", FavoriteData.Texts, "UITextExport_收藏列表.lua") end)
    clearAll.MouseButton1Click:Connect(function() FavoriteData.Texts = {}; FavoriteData.Map = {}; RefreshFavoriteList(); FavoriteStatus.Text = "收藏列表｜共 0 条" end)
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
    UpdateStatus("已添加进收藏列表")
end

local function SetDisplay(text, autoBottom)
    CurrentDisplayText = text
    ClearScroll()
    local index = 0
    for line in string.gmatch(tostring(text or "") .. "\n", "(.-)\n") do
        line = CleanText(line)
        if line ~= "" then
            index = index + 1
            local displayLine = line
            if #displayLine > 500 then displayLine = string.sub(displayLine,1,500).."..." end
            local row = New("Frame", {Size=UDim2.new(1,-12,0,31), BackgroundColor3=Color3.fromRGB(48,48,56), BorderSizePixel=0, LayoutOrder=index}, Scroll)
            Corner(row,6); Stroke(row, Color3.fromRGB(75,75,85),1,0.45)
            local label = New("TextButton", {Size=UDim2.new(1,-150,1,0), Position=UDim2.new(0,6,0,0), BackgroundTransparency=1, Text=displayLine, TextColor3=Color3.fromRGB(245,245,245), TextSize=13, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center, TextWrapped=false, TextTruncate=Enum.TextTruncate.AtEnd}, row)
            local add = New("TextButton", {Size=UDim2.new(0,42,0,24), Position=UDim2.new(1,-138,0.5,-12), Text="添加", TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(90,130,210)}, row)
            local del = New("TextButton", {Size=UDim2.new(0,42,0,24), Position=UDim2.new(1,-92,0.5,-12), Text="删除", TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(180,70,70)}, row)
            local copy = New("TextButton", {Size=UDim2.new(0,42,0,24), Position=UDim2.new(1,-46,0.5,-12), Text="复制", TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.SourceSansBold, BackgroundColor3=Color3.fromRGB(70,165,90)}, row)
            StyleButton(add, add.BackgroundColor3); StyleButton(del, del.BackgroundColor3); StyleButton(copy, copy.BackgroundColor3)
            label.MouseButton1Click:Connect(function() CopyText(line, "已复制当前行") end)
            copy.MouseButton1Click:Connect(function() CopyText(line, "已复制当前行") end)
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
                    local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
                    Scroll.CanvasPosition = Vector2.new(0, math.clamp(oldPos.Y, 0, maxY))
                end)
                UpdateSectionButtons()
                UpdateStatus(BlockMode and "已删除并加入屏蔽" or "已从当前列表删除")
            end)
        end
    end
    if index == 0 then
        local empty = New("TextButton", {Size=UDim2.new(1,-12,0,30), BackgroundColor3=Color3.fromRGB(48,48,56), BorderSizePixel=0, Text="  未检测到 UI 文本", TextColor3=Color3.fromRGB(180,180,180), TextSize=13, Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1}, Scroll)
        Corner(empty,6); Stroke(empty, Color3.fromRGB(75,75,85),1,0.45)
    end
    ResizeCanvas()
    if autoBottom then ScrollBottom() end
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
        if string.find(string.lower(line), lower, 1, true) then table.insert(result, line) end
    end
    if #result == 0 then
        SetDisplay("没有搜索到包含【"..keyword.."】的文本", false)
        UpdateStatus("搜索结果 0 条")
    else
        SetDisplay(table.concat(result,"\n"), false)
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
    data.Texts = {}; data.Map = {}; data.AllText = "未检测到 UI 文本"
    if CurrentSection == "全部" then
        for _, sec in ipairs(Sections) do SectionData[sec].Texts = {}; SectionData[sec].Map = {}; SectionData[sec].AllText = "未检测到 UI 文本" end
    else
        RebuildAll()
    end
    SearchBox.Text = ""
    SetDisplay(GetCurrentText(), false)
    Scroll.CanvasPosition = Vector2.new(0,0)
    UpdateSectionButtons()
    UpdateStatus(BlockMode and "已清空并加入屏蔽" or "已清空当前分区")
end

local function LayoutUI()
    if Minimized then return end
    local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if w <= 0 then w = 520 end
    if h <= 0 then h = 380 end
    local compact = w < 460 or h < 330
    local tiny = w < 400 or h < 290
    local titleH = tiny and 28 or 32
    local pad = tiny and 5 or 8
    local statusH = tiny and 18 or 20
    local searchH = tiny and 24 or 28
    local buttonH = tiny and 28 or 34
    local sectionCols = compact and 3 or 4
    local sectionRows = compact and 3 or 2
    local sectionH = sectionRows * (tiny and 22 or 25) + 6

    Title.Size = UDim2.new(1,-76,0,titleH)
    Title.Position = UDim2.new(0,pad,0,0)
    Title.TextSize = tiny and 14 or 16
    MinBtn.Size = UDim2.new(0,titleH,0,titleH)
    MinBtn.Position = UDim2.new(1,-titleH*2,0,0)
    MinBtn.TextSize = tiny and 16 or 18
    CloseBtn.Size = UDim2.new(0,titleH,0,titleH)
    CloseBtn.Position = UDim2.new(1,-titleH,0,0)
    CloseBtn.TextSize = tiny and 14 or 16

    Content.Size = UDim2.new(1,0,1,-titleH)
    Content.Position = UDim2.new(0,0,0,titleH)
    StatusLabel.Size = UDim2.new(1,-pad*2,0,statusH)
    StatusLabel.Position = UDim2.new(0,pad,0,0)
    StatusLabel.TextSize = tiny and 10 or 12
    SectionFrame.Size = UDim2.new(1,-pad*2,0,sectionH)
    SectionFrame.Position = UDim2.new(0,pad,0,statusH+2)

    local bw = 1 / sectionCols
    for i, section in ipairs(Sections) do
        local b = SectionButtons[section]
        local row = math.floor((i-1)/sectionCols)
        local col = (i-1)%sectionCols
        local bh = tiny and 20 or 23
        b.Size = UDim2.new(bw,-5,0,bh)
        b.Position = UDim2.new(col*bw,3+col,0,3+row*(bh+3))
        b.TextSize = tiny and 9 or 11
    end

    local searchY = statusH + 2 + sectionH + 6
    local searchBtnW = tiny and 58 or 72
    SearchBox.Size = UDim2.new(1,-pad*2-searchBtnW-6,0,searchH)
    SearchBox.Position = UDim2.new(0,pad,0,searchY)
    SearchBox.TextSize = tiny and 11 or 13
    SearchBtn.Size = UDim2.new(0,searchBtnW,0,searchH)
    SearchBtn.Position = UDim2.new(1,-pad-searchBtnW,0,searchY)
    SearchBtn.TextSize = tiny and 11 or 13

    BottomBar.Size = UDim2.new(1,-pad*2,0,buttonH)
    BottomBar.Position = UDim2.new(0,pad,1,-buttonH-pad)
    local buttons = {RefreshBtn,AutoCheckBtn,CopyBtn,BlockBtn,FavBtn,ExportBtn,ClearBtn}
    local bscale = 1 / #buttons
    for i, b in ipairs(buttons) do
        b.Size = UDim2.new(bscale,-5,1,0)
        b.Position = UDim2.new((i-1)*bscale,(i-1)*2,0,0)
        b.TextSize = tiny and 8 or 11
    end

    local scrollY = searchY + searchH + 6
    local scrollBottom = buttonH + pad + 6
    local scrollH = math.max(70, h - titleH - scrollY - scrollBottom)
    Scroll.Size = UDim2.new(1,-pad*2,0,scrollH)
    Scroll.Position = UDim2.new(0,pad,0,scrollY)
    ResizeHandle.Size = UDim2.new(0,tiny and 18 or 22,0,tiny and 18 or 22)
    ResizeHandle.Position = UDim2.new(1,-3,1,-3)
    ResizeCanvas()
end

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
    AutoCheckBtn.BackgroundColor3 = AutoRefreshEnabled and Color3.fromRGB(80,150,90) or Color3.fromRGB(160,120,60)
    UpdateStatus(AutoRefreshEnabled and "自动刷新已开启" or "自动刷新已关闭")
end)
CopyBtn.MouseButton1Click:Connect(function() CopyText(CurrentDisplayText, "已复制当前显示全部") end)
BlockBtn.MouseButton1Click:Connect(function()
    BlockMode = not BlockMode
    if BlockMode then
        BlockBtn.Text = "屏蔽：开"
        BlockBtn.BackgroundColor3 = Color3.fromRGB(150,80,180)
        UpdateStatus("屏蔽文本已开启")
    else
        BlockBtn.Text = "屏蔽：关"
        BlockBtn.BackgroundColor3 = Color3.fromRGB(110,80,150)
        for _, sec in ipairs(Sections) do BlockedData[sec] = {} end
        UpdateStatus("屏蔽文本已关闭")
    end
end)
FavBtn.MouseButton1Click:Connect(function() CreateFavoriteUI(); UpdateStatus("已打开收藏栏") end)
ExportBtn.MouseButton1Click:Connect(function()
    local data = SectionData[CurrentSection]
    local safeName = tostring(CurrentSection):gsub("[\\/:*?\"<>|]", "_")
    ExportLua(CurrentSection, data and data.Texts or {}, "UITextExport_"..safeName..".lua")
end)
SearchBtn.MouseButton1Click:Connect(function() SearchNow() end)
SearchBox.FocusLost:Connect(function(enter) if enter then SearchNow() end end)
ClearBtn.MouseButton1Click:Connect(function() ClearCurrent() end)

MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    if Minimized then
        LastNormalSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        LastNormalPosition = Main.Position
        Content.Visible = false
        Title.Visible = false
        CloseBtn.Visible = false
        ResizeHandle.Visible = false
        Main.Size = UDim2.new(0,MiniCircleSize,0,MiniCircleSize)
        MainCorner.CornerRadius = UDim.new(1,0)
        MinBtn.Size = UDim2.new(1,0,1,0)
        MinBtn.Position = UDim2.new(0,0,0,0)
        MinBtn.Text = "+"
        MinBtn.TextSize = 24
        MinBtn.BackgroundColor3 = Color3.fromRGB(75,125,215)
        MinBtn.ZIndex = 20
    else
        Content.Visible = true
        Title.Visible = true
        CloseBtn.Visible = true
        ResizeHandle.Visible = true
        Main.Size = UDim2.new(0,LastNormalSize.X,0,LastNormalSize.Y)
        if LastNormalPosition then Main.Position = LastNormalPosition end
        MainCorner.CornerRadius = UDim.new(0,12)
        MinBtn.Text = "-"
        MinBtn.BackgroundColor3 = Color3.fromRGB(80,80,88)
        MinBtn.ZIndex = 1
        LayoutUI()
    end
end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ResizeCanvas() end)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if not Minimized then LayoutUI() end end)

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
    local newW = math.clamp(resizeStartSize.X + delta.X, 380, 820)
    local newH = math.clamp(resizeStartSize.Y + delta.Y, 280, 620)
    Main.Size = UDim2.new(0,newW,0,newH)
    LastNormalSize = Vector2.new(newW,newH)
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        Main.Draggable = true
    end
end)

-- 自动刷新：只复用手动刷新逻辑，不搞实时监听
local AutoBusy = false
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if AutoRefreshEnabled and not AutoBusy then
            AutoBusy = true
            pcall(function() ManualRefresh() end)
            AutoBusy = false
        else
            UpdateSectionButtons()
            UpdateStatus()
        end
        task.wait(AutoRefreshInterval)
    end
end)

LayoutUI()
UpdateSectionButtons()
CurrentSection = "全部"
ManualRefresh()

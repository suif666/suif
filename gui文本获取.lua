-- UI 文本提取器 WindUI 混合版 v2
-- WindUI 负责控制区；自定义列表负责大量文本显示，避免 WindUI 大量组件卡顿

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function getHui()
    local ok, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    return ok and hui or nil
end

local Sections = {"全部", "PlayerGui", "Workspace", "CoreGui", "RobloxGui", "PlayerList", "第三方UI"}
local CurrentSection = "第三方UI"
local SearchKeyword = ""
local AutoRefresh = false
local AutoRefreshInterval = 2
local BlockMode = false
local CurrentDisplayText = ""
local ListGui = nil

local SectionData, BlockedData = {}, {}
for _, name in ipairs(Sections) do
    SectionData[name] = {Texts = {}, Map = {}, AllText = "未检测到 UI 文本"}
    BlockedData[name] = {}
end
local FavoriteData = {Texts = {}, Map = {}}

local SystemNames = {
    RobloxGui=true, PlayerList=true, Backpack=true, Chat=true,
    BubbleChat=true, ExperienceChat=true, TextChatService=true,
    TopBar=true, Topbar=true, Health=true, EmotesMenu=true,
    Chrome=true, InspectMenu=true, PurchasePrompt=true, ScreenshotHud=true,
}

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
    local list = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(list, 1, cur.Name)
        cur = cur.Parent
    end
    return table.concat(list, "/")
end

local function IsVisible(obj)
    local cur = obj
    while cur and cur ~= game do
        local ok, visible = pcall(function() return cur.Visible end)
        if ok and visible == false then return false end
        cur = cur.Parent
    end
    return true
end

local function IsSystemUI(obj)
    local cur = obj
    while cur do
        if SystemNames[cur.Name] then return true end
        cur = cur.Parent
    end
    return false
end

local function Rebuild(section)
    local data = SectionData[section]
    if not data then return end
    data.AllText = (#data.Texts > 0) and table.concat(data.Texts, "\n") or "未检测到 UI 文本"
end

local function Count(section)
    local data = SectionData[section]
    return data and #data.Texts or 0
end

local function SaveText(section, text)
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

local function SaveTextWithSection(section, text)
    if SaveText(section, text) then
        if section ~= "全部" then SaveText("全部", text) end
        return true
    end
    return false
end

local function Belongs(obj, section)
    if not obj or not IsVisible(obj) then return false end
    if ListGui and obj:IsDescendantOf(ListGui) then return false end
    local hui = getHui()
    local path = GetObjectPath(obj)

    if section == "PlayerGui" then
        return obj:IsDescendantOf(PlayerGui)
    elseif section == "Workspace" then
        return obj:IsDescendantOf(Workspace)
    elseif section == "CoreGui" then
        return obj:IsDescendantOf(CoreGui) or (hui and obj:IsDescendantOf(hui))
    elseif section == "RobloxGui" then
        return (obj:IsDescendantOf(CoreGui) or (hui and obj:IsDescendantOf(hui))) and path:find("RobloxGui", 1, true) ~= nil
    elseif section == "PlayerList" then
        return (obj:IsDescendantOf(CoreGui) or (hui and obj:IsDescendantOf(hui))) and path:find("PlayerList", 1, true) ~= nil
    elseif section == "第三方UI" then
        if obj:IsDescendantOf(PlayerGui) and not IsSystemUI(obj) then return true end
        if obj:IsDescendantOf(CoreGui) and not IsSystemUI(obj) then return true end
        if hui and obj:IsDescendantOf(hui) and not IsSystemUI(obj) then return true end
        return false
    elseif section == "全部" then
        return obj:IsDescendantOf(PlayerGui) or obj:IsDescendantOf(CoreGui) or (hui and obj:IsDescendantOf(hui))
    end
    return false
end

local function ReadObject(obj, section)
    if not IsTextObject(obj) or not Belongs(obj, section) then return 0 end
    local added = 0
    local function try(v)
        if SaveTextWithSection(section, v) then added += 1 end
    end
    pcall(function() if obj.Text and obj.Text ~= "" then try(obj.Text) end end)
    pcall(function() if obj.ContentText and obj.ContentText ~= "" then try(obj.ContentText) end end)
    pcall(function() if obj.PlaceholderText and obj.PlaceholderText ~= "" then try(obj.PlaceholderText) end end)
    return added
end

local function ScanContainer(root, section)
    local added = 0
    if not root then return 0 end
    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            added += ReadObject(obj, section)
        end
    end)
    return added
end

local function ScanSection(section)
    local added = 0
    local hui = getHui()
    if section == "PlayerGui" then
        added += ScanContainer(PlayerGui, section)
    elseif section == "Workspace" then
        added += ScanContainer(Workspace, section)
    elseif section == "CoreGui" or section == "RobloxGui" or section == "PlayerList" then
        added += ScanContainer(CoreGui, section)
        if hui and hui ~= CoreGui then added += ScanContainer(hui, section) end
    elseif section == "第三方UI" then
        added += ScanContainer(PlayerGui, section)
        added += ScanContainer(CoreGui, section)
        if hui and hui ~= CoreGui then added += ScanContainer(hui, section) end
    elseif section == "全部" then
        added += ScanSection("PlayerGui")
        added += ScanSection("CoreGui")
        added += ScanSection("第三方UI")
    end
    Rebuild(section); Rebuild("全部")
    return added
end

local function BuildLua(title, list)
    local lines = {"-- " .. tostring(title or "UI文本导出"), "return {"}
    for _, text in ipairs(list or {}) do
        table.insert(lines, '    "' .. EscapeLuaString(text) .. '",')
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local function Clipboard(text)
    if setclipboard then setclipboard(text); return true end
    if toclipboard then toclipboard(text); return true end
    return false
end

local WindUI
local okWind, errWind = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not okWind or not WindUI then
    warn("WindUI 加载失败：", errWind)
end

local function Notify(title, content)
    if WindUI and WindUI.Notify then
        pcall(function()
            WindUI:Notify({Title = title or "提示", Content = content or "", Duration = 3})
        end)
    else
        warn((title or "提示") .. "：" .. (content or ""))
    end
end

--====================================================
-- 自定义文本列表窗口
--====================================================

pcall(function()
    local old = (getHui() or CoreGui):FindFirstChild("WindUITextCollectorList")
    if old then old:Destroy() end
end)

ListGui = Instance.new("ScreenGui")
ListGui.Name = "WindUITextCollectorList"
ListGui.ResetOnSpawn = false
ListGui.IgnoreGuiInset = true
ListGui.Parent = getHui() or CoreGui

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function Corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
end
local function Stroke(obj, color, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 68, 84)
    s.Transparency = trans or 0.45
    s.Thickness = 1
    s.Parent = obj
end

local ListFrame = New("Frame", {
    Size = UDim2.new(0, 430, 0, 330),
    Position = UDim2.new(1, -450, 0.5, -165),
    BackgroundColor3 = Color3.fromRGB(16, 19, 27),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, ListGui)
Corner(ListFrame, 14); Stroke(ListFrame, Color3.fromRGB(70, 80, 100), 0.36)

local ListTitle = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "文本列表",
    TextColor3 = Color3.fromRGB(238, 242, 250),
    Font = Enum.Font.SourceSansBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(1, -70, 0, 32),
    Position = UDim2.new(0, 10, 0, 0),
}, ListFrame)

local HideBtn = New("TextButton", {
    Text = "-",
    TextColor3 = Color3.new(1,1,1),
    BackgroundColor3 = Color3.fromRGB(34, 40, 54),
    Font = Enum.Font.SourceSansBold,
    TextSize = 16,
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -64, 0, 1),
}, ListFrame)
Corner(HideBtn, 8)
local CloseBtn = New("TextButton", {
    Text = "X",
    TextColor3 = Color3.new(1,1,1),
    BackgroundColor3 = Color3.fromRGB(168, 64, 72),
    Font = Enum.Font.SourceSansBold,
    TextSize = 14,
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -32, 0, 1),
}, ListFrame)
Corner(CloseBtn, 8)

local ListStatus = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "等待刷新",
    TextColor3 = Color3.fromRGB(160, 170, 190),
    Font = Enum.Font.SourceSans,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 34),
}, ListFrame)

local Scroll = New("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -64),
    Position = UDim2.new(0, 10, 0, 58),
    BackgroundColor3 = Color3.fromRGB(24, 29, 40),
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(0,0,0,0),
}, ListFrame)
Corner(Scroll, 10); Stroke(Scroll, Color3.fromRGB(56, 64, 82), 0.55)
local Layout = New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)

local function ResizeList()
    local cam = workspace.CurrentCamera
    local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local mobile = v.X <= 900 or v.Y <= 600
    if mobile then
        local w = math.floor(v.X * 0.82)
        local h = math.floor(v.Y * 0.72)
        ListFrame.Size = UDim2.new(0, math.max(300, w), 0, math.max(230, h))
        ListFrame.Position = UDim2.new(0.5, -ListFrame.AbsoluteSize.X/2, 0.5, -ListFrame.AbsoluteSize.Y/2)
    end
end

local function RefreshListDisplay(list)
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    list = list or {}
    for i, text in ipairs(list) do
        local row = New("Frame", {
            Size = UDim2.new(1, -10, 0, 34),
            BackgroundColor3 = Color3.fromRGB(31, 37, 50),
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, Scroll)
        Corner(row, 8); Stroke(row, Color3.fromRGB(64, 72, 90), 0.62)
        local label = New("TextButton", {
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Color3.fromRGB(232, 236, 245),
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1, -130, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
        }, row)
        local fav = New("TextButton", {Text="藏", TextSize=12, Font=Enum.Font.SourceSansBold, TextColor3=Color3.new(1,1,1), BackgroundColor3=Color3.fromRGB(48, 94, 168), Size=UDim2.new(0,34,0,24), Position=UDim2.new(1,-116,0.5,-12)}, row)
        local del = New("TextButton", {Text="删", TextSize=12, Font=Enum.Font.SourceSansBold, TextColor3=Color3.new(1,1,1), BackgroundColor3=Color3.fromRGB(168, 64, 72), Size=UDim2.new(0,34,0,24), Position=UDim2.new(1,-78,0.5,-12)}, row)
        local copy = New("TextButton", {Text="复", TextSize=12, Font=Enum.Font.SourceSansBold, TextColor3=Color3.new(1,1,1), BackgroundColor3=Color3.fromRGB(70, 145, 105), Size=UDim2.new(0,34,0,24), Position=UDim2.new(1,-40,0.5,-12)}, row)
        Corner(fav, 7); Corner(del, 7); Corner(copy, 7)
        label.MouseButton1Click:Connect(function() Clipboard(text); Notify("复制", "已复制当前行") end)
        copy.MouseButton1Click:Connect(function() Clipboard(text); Notify("复制", "已复制当前行") end)
        fav.MouseButton1Click:Connect(function()
            if not FavoriteData.Map[text] then
                FavoriteData.Map[text] = true
                table.insert(FavoriteData.Texts, text)
            end
            Notify("收藏", "已添加到收藏栏")
        end)
        del.MouseButton1Click:Connect(function()
            local data = SectionData[CurrentSection]
            if data then
                data.Map[text] = nil
                for n=#data.Texts,1,-1 do if data.Texts[n] == text then table.remove(data.Texts, n) end end
                Rebuild(CurrentSection)
            end
            RefreshListDisplay(data and data.Texts or {})
            Notify("删除", "已从当前分区删除")
        end)
    end
    if #list == 0 then
        local row = New("Frame", {Size=UDim2.new(1,-10,0,34), BackgroundColor3=Color3.fromRGB(31,37,50), BorderSizePixel=0}, Scroll)
        Corner(row, 8)
        New("TextLabel", {BackgroundTransparency=1, Text="未检测到 UI 文本", TextColor3=Color3.fromRGB(160,170,190), TextSize=12, Font=Enum.Font.SourceSans, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,8,0,0)}, row)
    end
    task.defer(function()
        task.wait()
        Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y + 10)
    end)
end

local function GetCurrentList()
    local data = SectionData[CurrentSection]
    if not data then return {} end
    if SearchKeyword == "" then return data.Texts end
    local out, low = {}, string.lower(SearchKeyword)
    for _, t in ipairs(data.Texts) do
        if string.find(string.lower(t), low, 1, true) then table.insert(out, t) end
    end
    return out
end

local function RefreshNow()
    local added = ScanSection(CurrentSection)
    local list = GetCurrentList()
    CurrentDisplayText = table.concat(list, "\n")
    ListTitle.Text = "文本列表 - " .. CurrentSection
    ListStatus.Text = "当前分区：" .. CurrentSection .. "｜保存 " .. tostring(Count(CurrentSection)) .. " 条｜新增 " .. tostring(added) .. " 条"
    RefreshListDisplay(list)
    ResizeList()
    Notify("刷新完成", "新增 " .. tostring(added) .. " 条")
end

local function ShowTextList()
    if not ListFrame or not ListFrame.Parent then return end
    ListFrame.Visible = true
    local list = GetCurrentList()
    CurrentDisplayText = table.concat(list, "\n")
    ListTitle.Text = "文本列表 - " .. CurrentSection
    ListStatus.Text = "当前分区：" .. CurrentSection .. "｜保存 " .. tostring(Count(CurrentSection)) .. " 条"
    RefreshListDisplay(list)
    ResizeList()
end

local function ShowFavoriteList()
    if not ListFrame or not ListFrame.Parent then return end
    ListFrame.Visible = true
    ListTitle.Text = "收藏列表"
    ListStatus.Text = "收藏数量：" .. tostring(#FavoriteData.Texts)
    RefreshListDisplay(FavoriteData.Texts)
    ResizeList()
end

local function HideListWindow()
    if ListFrame then
        ListFrame.Visible = false
    end
end

HideBtn.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)
CloseBtn.MouseButton1Click:Connect(function() ListFrame.Visible = false end)

--====================================================
-- WindUI 控制区
--====================================================

if WindUI then
    local Window = WindUI:CreateWindow({
        Title = "UI 文本提取器",
        Icon = "search",
        Author = "WindUI 混合版",
        Folder = "TextCollector",
        Size = UDim2.fromOffset(520, 420),
        Transparent = true,
        Theme = "Dark",
    })

    local MainTab = Window:Tab({Title = "文本提取", Icon = "scan-text"})
    local FavTab = Window:Tab({Title = "收藏栏", Icon = "bookmark"})

    MainTab:Dropdown({
        Title = "选择分区",
        Values = Sections,
        Value = CurrentSection,
        Callback = function(v)
            CurrentSection = v
            RefreshNow()
        end
    })

    MainTab:Input({
        Title = "搜索文本",
        Placeholder = "输入关键字后回车/确认",
        Callback = function(v)
            SearchKeyword = CleanText(v)
            RefreshListDisplay(GetCurrentList())
        end
    })

    MainTab:Button({Title = "刷新", Desc = "扫描当前分区文本", Callback = RefreshNow})
    MainTab:Toggle({Title = "自动刷新", Value = false, Callback = function(v)
        AutoRefresh = v
        Notify("自动刷新", v and "已开启" or "已关闭")
    end})
    MainTab:Toggle({Title = "屏蔽文本", Value = false, Callback = function(v)
        BlockMode = v
        Notify("屏蔽文本", v and "已开启" or "已关闭")
    end})
    MainTab:Button({Title = "复制当前显示", Callback = function()
        Clipboard(CurrentDisplayText ~= "" and CurrentDisplayText or table.concat(GetCurrentList(), "\n"))
        Notify("复制", "已复制当前显示文本")
    end})
    MainTab:Button({Title = "导出当前分区 Lua", Callback = function()
        local data = SectionData[CurrentSection]
        local luaText = BuildLua("UI文本导出 - " .. CurrentSection, data and data.Texts or {})
        Clipboard(luaText)
        if writefile then writefile("UITextExport_" .. tostring(CurrentSection):gsub("[\\/:*?\"<>|]", "_") .. ".lua", luaText) end
        Notify("导出Lua", "已导出当前分区")
    end})
    MainTab:Button({Title = "清空当前分区", Callback = function()
        local data = SectionData[CurrentSection]
        if data then
            data.Texts = {}; data.Map = {}; data.AllText = "未检测到 UI 文本"
        end
        RefreshListDisplay({})
        Notify("清空", "已清空当前分区")
    end})
    MainTab:Button({Title = "打开文本滚动列表", Desc = "重新显示主文本列表窗口", Callback = function()
        ShowTextList()
    end})
    MainTab:Button({Title = "隐藏文本滚动列表", Callback = function()
        HideListWindow()
    end})

    FavTab:Button({Title = "打开收藏滚动列表", Desc = "显示用户收藏过的文本", Callback = function()
        ShowFavoriteList()
    end})
    FavTab:Button({Title = "隐藏收藏滚动列表", Callback = function()
        HideListWindow()
    end})
    FavTab:Button({Title = "复制收藏全部", Callback = function()
        Clipboard(table.concat(FavoriteData.Texts, "\n"))
        Notify("收藏", "已复制收藏全部")
    end})
    FavTab:Button({Title = "导出收藏 Lua", Callback = function()
        local luaText = BuildLua("收藏列表导出", FavoriteData.Texts)
        Clipboard(luaText)
        if writefile then writefile("UITextExport_收藏列表.lua", luaText) end
        Notify("收藏", "已导出收藏 Lua")
    end})
    FavTab:Button({Title = "清空收藏", Callback = function()
        FavoriteData.Texts = {}; FavoriteData.Map = {}
        RefreshListDisplay(FavoriteData.Texts)
        Notify("收藏", "收藏栏已清空")
    end})
end

-- 自动刷新循环
task.spawn(function()
    while ListGui and ListGui.Parent do
        if AutoRefresh then
            pcall(RefreshNow)
        end
        task.wait(AutoRefreshInterval)
    end
end)

RefreshNow()

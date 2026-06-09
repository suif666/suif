local Translations = {
    --格式：["英文原文"] = "中文翻译",
    ["@Im_Patrick | control npc panel (old version fix)"] = "控制 NPC 面板（旧版修复）",
    ["check owner ( debug )"] = "检查所有者（调试）",
    ["network radius ( range )"] = "网络半径（范围）",
    ["value"] = "数值",
    ["following"] = "跟随",
    ["kill"] = "击杀",
    ["punish"] = "惩罚",
    ["bring"] = "传送",
    ["freeze"] = "冻结",
    ["Sit"] = "坐下",
    ["坐下"] = "坐下", 
    ["jump"] = "跳跃",
    ["walkspeed"] = "行走速度",
    ["jumppower"] = "跳跃力度",
    ["spin"] = "旋转",
    ["teleport to npc"] = "传送到 NPC",
    ["control"] = "控制",
    ["select = on"] = "选择 = 开启",
    ["select : off"] = "选择：关闭",
    ["select : on"] = "选择：开启",
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SystemUiNames = {
    ["RobloxGui"] = true,
    ["PlayerList"] = true,
    ["Backpack"] = true,
    ["Chat"] = true,
    ["BubbleChat"] = true,
    ["ExperienceChat"] = true,
    ["TextChatService"] = true,
    ["TopBar"] = true,
    ["Topbar"] = true,
    ["Health"] = true,
    ["EmotesMenu"] = true,
    ["Chrome"] = true,
    ["InspectMenu"] = true,
    ["PurchasePrompt"] = true,
    ["ScreenshotHud"] = true,
}

local Config = {
    FallbackScanInterval = 8,

    NewObjectDelay = 0.05,

    TextChangeDelay = 0.03,

    ScanPlayerGui = true,
    ScanCoreGui = true,
    ScanHui = true,
}

local WatchedRoots = setmetatable({}, { __mode = "k" })
local WatchedObjects = setmetatable({}, { __mode = "k" })
local TranslatingObjects = setmetatable({}, { __mode = "k" })

local function CleanText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    text = text:gsub("\r", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function TranslateText(text)
    if type(text) ~= "string" or text == "" then
        return text
    end

    if Translations[text] then
        return Translations[text]
    end

    local cleaned = CleanText(text)

    if Translations[cleaned] then
        return Translations[cleaned]
    end

    return text
end

local function IsTextObject(obj)
    return obj
        and (
            obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox")
        )
end

local function IsSystemUI(obj)
    local current = obj

    while current do
        if SystemUiNames[current.Name] then
            return true
        end

        current = current.Parent
    end

    return false
end

local function TranslateObject(obj)
    if not IsTextObject(obj) then
        return
    end

    if IsSystemUI(obj) then
        return
    end

    if TranslatingObjects[obj] then
        return
    end

    TranslatingObjects[obj] = true

    pcall(function()
        local oldText = obj.Text
        local newText = TranslateText(oldText)

        if newText ~= oldText then
            obj.Text = newText
        end
    end)

    pcall(function()
        local oldPlaceholder = obj.PlaceholderText
        local newPlaceholder = TranslateText(oldPlaceholder)

        if newPlaceholder ~= oldPlaceholder then
            obj.PlaceholderText = newPlaceholder
        end
    end)

    TranslatingObjects[obj] = nil
end

local function WatchTextObject(obj)
    if not IsTextObject(obj) then
        return
    end

    if WatchedObjects[obj] then
        return
    end

    WatchedObjects[obj] = true
    TranslateObject(obj)

    pcall(function()
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            if TranslatingObjects[obj] then
                return
            end

            task.delay(Config.TextChangeDelay, function()
                TranslateObject(obj)
            end)
        end)
    end)

    pcall(function()
        obj:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
            if TranslatingObjects[obj] then
                return
            end

            task.delay(Config.TextChangeDelay, function()
                TranslateObject(obj)
            end)
        end)
    end)
end

local function ScanRoot(root)
    if not root then
        return
    end

    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            if IsTextObject(obj) then
                WatchTextObject(obj)
            end
        end
    end)
end

local function WatchRoot(root)
    if not root then
        return
    end

    if WatchedRoots[root] then
        return
    end

    WatchedRoots[root] = true

    ScanRoot(root)

    pcall(function()
        root.DescendantAdded:Connect(function(obj)
            task.delay(Config.NewObjectDelay, function()
                if IsTextObject(obj) then
                    WatchTextObject(obj)
                    return
                end

                pcall(function()
                    for _, child in ipairs(obj:GetDescendants()) do
                        if IsTextObject(child) then
                            WatchTextObject(child)
                        end
                    end
                end)
            end)
        end)
    end)
end

local function AddRoot(roots, root)
    if root then
        table.insert(roots, root)
    end
end

local function GetRoots()
    local roots = {}

    if Config.ScanPlayerGui then
        AddRoot(roots, PlayerGui)
    end

    if Config.ScanCoreGui then
        pcall(function()
            AddRoot(roots, CoreGui)
        end)
    end

    if Config.ScanHui then
        pcall(function()
            if gethui then
                local hui = gethui()

                if hui then
                    AddRoot(roots, hui)
                end
            end
        end)
    end

    return roots
end

local function HookTextSetter()
    local ok, err = pcall(function()
        if not getrawmetatable or not setreadonly or not newcclosure then
            error("当前环境不支持元表 Hook")
        end

        local mt = getrawmetatable(game)
        local oldNewIndex = mt.__newindex

        setreadonly(mt, false)

        mt.__newindex = newcclosure(function(tbl, key, value)
            if IsTextObject(tbl) and not IsSystemUI(tbl) then
                if key == "Text" or key == "PlaceholderText" then
                    value = TranslateText(tostring(value))
                end
            end

            return oldNewIndex(tbl, key, value)
        end)

        setreadonly(mt, true)
    end)

    if not ok then
        warn("汉化 Hook 不可用，已使用监听/扫描模式：", err)
    end
end

local function StartTranslationEngine()
    HookTextSetter()

    for _, root in ipairs(GetRoots()) do
        WatchRoot(root)
    end

    task.spawn(function()
        while task.wait(Config.FallbackScanInterval) do
            for _, root in ipairs(GetRoots()) do
                WatchRoot(root)
                ScanRoot(root)
            end
        end
    end)
end

StartTranslationEngine()

local ScriptUrl = "https://raw.githubusercontent.com/randomstring0/qwertys/refs/heads/main/qwerty8.lua"

task.wait(0.5)

local ok, result = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if ok and result and result ~= "" then
    loadstring(result)()
else
    warn("原脚本获取失败：", result)
end

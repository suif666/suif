local Translations = {
    ["Homelander: OFF"] = "祖国人：关闭",
    ["Homelander: ON"] = "祖国人：开启",
    ["Random Voicelines"] = "随机语音",
    ["Ground Land: ON"] = "落地：开启",
    ["Fling: OFF"] = "投掷：关闭",
    ["X-Ray: OFF"] = "X光透视：关闭",
    ["Normal"] = "正常",
    ["fly idle:"] = "飞行待机：",
    ["idle V1"] = "待机 V1",
    ["lock buttons"] = "锁定按钮",
    ["camera follow: on"] = "相机跟随：开启",
    ["hide buttons"] = "隐藏按钮",
    ["camera lift during laser: on"] = "激光时相机抬升：开启",
    ["laser eye offset:"] = "激光眼偏移：",
    ["shiftlock: off"] = "Shift锁定：关闭",
    ["laser fling: on"] = "激光投掷：开启",
    ["camera X offset:"] = "相机 X 偏移：",
    ["idle V2"] = "待机 V2",
    ["idle V3"] = "待机 V3",
    ["idle V4"] = "待机 V4",
    ["Slow"] = "慢速",
    ["Fast"] = "快速",
    ["X-Ray: ON"] = "X光透视：开启",
    ["Fling: ON"] = "投掷：开启",
    ["Ground Land: OFF"] = "落地：关闭",
    ["unlock buttons"] = "解锁按钮",
    ["camera follow: off"] = "相机跟随：关闭",
    ["show buttons"] = "显示按钮",
    ["camera lift during laser: off"] = "激光时相机抬升：关闭",
    ["shiftlock: on"] = "Shift锁定：开启",
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

    -- 低频兜底扫描，防止漏翻
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

local ScriptUrl = "https://raw.githubusercontent.com/giobolqv1/homelander-by-GioBolqv1-/refs/heads/main/homelander.lua"

task.wait(0.5)

local ok, result = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if ok and result and result ~= "" then
    loadstring(result)()
else
    warn("原脚本获取失败：", result)
end

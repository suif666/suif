local Translations = {
    ["Auto Actions"] = "自动化",
    ["Auto Superball"] = "自动超级球",
    ["Collectibles"] = "传送类",
    ["Misc"] = "其它",
    ["Enable Premium & Donator only Animat "] = "仅限高级和捐赠者动画",
    ["Activation Distance (studs)"] = "触发距离 (单位)",
    ["studs"] = "单位",
    ["Auto Linebounce (Requires Auto Superball ON)"] = "自动反弹 (需要启用自动超级球)",
    ["Enable Auto Linebounce"] = "启用自动反弹",
    ["Linebounce Delay/Interval (s)"] = "反弹延迟/间隔 (秒)",
    ["Auto Guard (Attachment Method)"] = "自动格挡",
    ["Auto Guard"] = "自动格挡",
    ["Auto Guard Delay (seconds)"] = "自动格挡延迟 (秒)",
    ["Auto Sword"] = "自动剑",
    ["Item Teleporter"] = "物品传送",
    ["Select Item"] = "选择物品",
    ["- No Items Found -"] = "- 未找到物品 -",
    ["Teleport to Selected Item"] = "传送至选定物品",
    ["Card Teleporter"] = "卡牌传送",
    ["Sword Release Delay (seconds)"] = "剑释放延迟 (秒)",
    ["Use Sword on Flying Enemies"] = "对飞行敌人使用剑",
    ["Auto Launcher"] = "自动火箭筒",
    ["Select Card"] = "选择卡牌",
    ["- No Cards Found -"] = "- 未找到卡牌 -",
    ["Teleport to Selected Card"] = "传送至选定卡牌",
    ["BUX Teleporter"] = "BUX 传送",
    ["Select BUX"] = "选择 BUX",
    ["- No BUX Found -"] = "- 未找到 BUX -",
    ["Arena Enemy Targeter"] = "敌人选择器",
    ["Target Enemy"] = "目标敌人",
    ["None"] = "无",
    ["Auto Superball Action"] = "自动超级球",
    ["Enabl Auto Superball"] = "启用自动超级球",
    ["Enable Auto Launcher"] = "启用自动火箭筒",
    ["Auto Dynamite/Slingshot"] = "自动炸药/弹弓[Demo5已失效]",
    ["Enable Auto Dynamite/Slingshot"] = "启用自动炸药/弹弓",
    ["General Mods"] = "通用模组",
    ["Invincibility (Godmode)"] = "无敌 (上帝模式)",
    ["Speed Boost"] = "速度提升",
    ["x Multiplier"] = "倍乘数",
    ["Auto Fish"] = "自动钓鱼",
    ["Toggle Notifications"] = "切换通知",
    ["Toggle Debug Messages (Dev Console)"] = "切换调试消息 (开发控制台)",
    ["Enable Premium & Donor only Animation Flavors"] = "启用仅限高级与捐赠者动画风格",
    ["Teleport to Selected BUX"] = "传送至选定 BUX",
    ["Teleport Settings"] = "传送设置",
    ["Teleport Back To Original Position"] = "传送回原位置",
    ["Action Complete"] ="操作完成",
    ["Space pressed for Terrain"] ="已自动格挡",
    ["found in"] ="位于",
}

local TextClasses = {
    TextLabel = true,
    TextButton = true,
    TextBox = true,
}

local function isTextObject(obj)
    return obj and TextClasses[obj.ClassName] == true
end

local function translateText(text)
    if type(text) ~= "string" or text == "" then
        return text
    end

    -- 完全匹配，最稳定
    if Translations[text] then
        return Translations[text]
    end

    -- 包含匹配，使用 plain 模式，避免括号等符号报错
    for en, cn in pairs(Translations) do
        if string.find(text, en, 1, true) then
            text = string.gsub(text, en:gsub("(%W)", "%%%1"), cn)
        end
    end

    return text
end

local function translateObject(obj)
    if not isTextObject(obj) then
        return
    end

    pcall(function()
        local oldText = obj.Text
        local newText = translateText(oldText)

        if newText ~= oldText then
            obj.Text = newText
        end
    end)
end

local function scanContainer(container)
    if not container then
        return
    end

    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            translateObject(obj)
        end
    end)
end

local function listenContainer(container)
    if not container then
        return
    end

    pcall(function()
        container.DescendantAdded:Connect(function(obj)
            task.defer(function()
                task.wait(0.05)
                translateObject(obj)
            end)
        end)
    end)
end

local function setupFallbackTranslation()
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    scanContainer(CoreGui)
    listenContainer(CoreGui)

    if LocalPlayer then
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)

        if PlayerGui then
            scanContainer(PlayerGui)
            listenContainer(PlayerGui)
        end
    end

    -- 低频补漏扫描，不卡外部脚本
    task.spawn(function()
        while task.wait(3) do
            scanContainer(CoreGui)

            local player = Players.LocalPlayer
            if player and player:FindFirstChild("PlayerGui") then
                scanContainer(player.PlayerGui)
            end
        end
    end)
end

local function setupHookTranslation()
    local mt = getrawmetatable(game)
    local oldNewIndex = mt.__newindex

    setreadonly(mt, false)

    mt.__newindex = newcclosure(function(t, k, v)
        if isTextObject(t) and k == "Text" and type(v) == "string" then
            v = translateText(v)
        end

        return oldNewIndex(t, k, v)
    end)

    setreadonly(mt, true)
end

local function setupTranslationEngine()
    local success, err = pcall(function()
        setupHookTranslation()
    end)

    if success then
        print("翻译引擎：Hook模式已启用")
    else
        warn("Hook模式失败，已切换普通扫描模式：", err)
        setupFallbackTranslation()
    end
end

-- 先启动翻译引擎
setupTranslationEngine()

-- 再加载外部脚本
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TexRBLX/Roblox-stuff/refs/heads/main/block%20tales/revamp.lua"))()
end)

if not success then
    warn("加载失败:", err)
end
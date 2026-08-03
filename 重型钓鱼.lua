print("汉化脚本 v3.3")

-- ===== 精确翻译表（整句完全匹配）=====
-- 请在此按 ["英文原文"] = "中文翻译" 格式添加
local Translations = {
    -- 示例: ["Home"] = "主页",
    ["Miscellaneous"] = "杂项",
    ["AFK"] = "挂机",
    ["player"] = "玩家",
    ["entertainment"] = "娱乐",
    ["transport"] = "运输",
    ["Stop the automatic outfit change"] = "停止自动换装",
    ["Official Aero Community\n\n⚡ Script Updates\n🎧 Support\n🔔 Announcements\n👥 Community Chat"] = "官方 Aero 社区[suif汉化]\n\n⚡ 脚本更新\n🎧 支持\n🔔 公告\n👥 社区聊天",
    ["📋 Copy Discord Link"] = "📋 复制 Discord 链接",
    ["Automatic casting"] = "自动抛竿",
    ["Auto-phishing"] = "自动钓鱼",
    ["Automatic skills"] = "自动技能",
    ["Click on the green square for the auto mini-game"] = "点击绿色方块进行自动小游戏",
    ["Center point determination tolerance"] = "中心点判定容差",
    ["Precautions"] = "注意事项",
    ["After enabling filtering, only bosses will be targeted; if it's not a boss, the attempt will automatically be abandoned (currently unavailable due to maintenance)"] = "启用过滤后，只会瞄准Boss；如果不是Boss，将自动放弃尝试（目前因维护暂不可用）",
    ["Automatically filter out small fish"] = "自动过滤小鱼",
    ["Locked"] = "已锁定",
    ["Help others fish for the boss"] = "帮助他人钓Boss",
    ["After turning on this feature, the automatic function won't work or it'll conflict"] = "开启此功能后，自动功能将无法工作或产生冲突",
    ["Automatic weather updates"] = "自动天气更新",
    ["The gate will release automatically when the lever is broken"] = "杠杆断裂时门会自动释放",
    ["Rod gate release delay time"] = "鱼竿门释放延迟时间",
    ["Default is 30"] = "默认30",
    ["Automatic fish vending machine"] = "自动鱼售货机",
    ["Open the bait store"] = "打开鱼饵商店",
    ["Open up the bait-making ingredients"] = "打开制作鱼饵的材料",
    ["Automatically transports the boss"] = "自动运输Boss",
    ["Automatically bookmark rare fish"] = "自动标记稀有鱼",
    ["After automatically accepting Boss Liu's tasks, just hang up and finish all of Boss Liu's assignments, then claim new ones"] = "自动接受刘老板任务后，只需挂机完成所有任务，然后领取新任务",
    ["Automatically assign difficult tasks to Boss Liu"] = "自动将困难任务分配给刘老板",
    ["Automatically claim Boss Liu's task"] = "自动领取刘老板任务",
    ["Automatically buy ancestor bait"] = "自动购买祖先鱼饵",
    ["Automatically transports the little Taoist priest"] = "自动运输小道童",
    ["Auto-forward Maoshan"] = "自动前往茅山",
    ["speed up"] = "加速",
    ["moving speed"] = "移动速度",
    ["Getting a Hidden Fishing Wife"] = "获得隐藏的钓鱼伴侣",
    ["Transfer to: Initial island"] = "传送到：初始岛",
    ["Transfer to: Bamboo Island"] = "传送到：竹岛",
    ["Transfer to: Nuclear Bomb Island"] = "传送到：核弹岛",
    ["Transfer to: sovereign islands"] = "传送到：主权群岛",
    ["Transfer to: Perch Island"] = "传送到：鲈鱼岛",
    ["Transfer to: Extreme Ice Rivers"] = "传送到：极冰河",
    ["Transfer to: Coconut Island"] = "传送到：椰子岛",
    ["Transfer to: Amber Island"] = "传送到：琥珀岛",
    ["Transfer to: Battlefield Island"] = "传送到：战场岛",
    ["Transfer to: Mistpeak lsle"] = "传送到：雾峰岛",
}

-- ===== 部分替换表（子串替换）=====
-- 请在此按 ["英文子串"] = "中文替换" 格式添加
-- 注意：会替换文本中所有匹配的子串，请谨慎使用
local PartialTranslations = {
    -- 示例: yes no 
    --["yes"] = "是",
    
}

-- ===== 选择模式（带按钮的原生通知）=====
local function AskModeWithNotification()
    local StarterGui = game:GetService("StarterGui")
    local choice = nil

    local success, err = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "汉化模式选择",
            Text = "请选择翻译方式",
            Button1 = "Hook模式 (快速)",
            Button2 = "普通模式 (稳定)",
            Duration = 10,
            Callback = function(clicked)
                -- 兼容两种返回值：字符串或数字索引
                if clicked == "Hook模式 (快速)" or clicked == 1 then
                    choice = true
                elseif clicked == "普通模式 (稳定)" or clicked == 2 then
                    choice = false
                end
            end
        })
    end)

    if not success then
        warn("通知发送失败，使用普通模式:", err)
        return false
    end

    local start = os.clock()
    repeat
        wait(0.1)
    until choice ~= nil or os.clock() - start > 11

    if choice == nil then
        print("未选择，默认使用普通模式")
        return false
    end
    return choice
end

local UseHookTranslation = AskModeWithNotification()
print("最终使用模式:", UseHookTranslation and "Hook" or "普通监听")

-- ===== 翻译框架（监听模式为主）=====
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

if not PlayerGui then
    warn("未找到 PlayerGui，汉化可能无法正常工作")
end

local SystemUiNames = {
    RobloxGui=true, PlayerList=true, Backpack=true, Chat=true, BubbleChat=true,
    ExperienceChat=true, TextChatService=true, TopBar=true, Topbar=true, Health=true,
    EmotesMenu=true, Chrome=true, InspectMenu=true, PurchasePrompt=true,
    ScreenshotHud=true
}

local WatchedRoots, WatchedObjects, TranslatingObjects = setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"})

local function TranslateText(txt)
    if type(txt) ~= "string" or txt == "" then return txt end
    local clean = txt:gsub("<[^>]->", ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- 1. 精确匹配（整句）
    local exact = Translations[txt] or Translations[clean]
    if exact then return exact end

    -- 2. 部分替换（子串）
    local result = txt
    for original, translated in pairs(PartialTranslations) do
        result = result:gsub(original, translated)
    end
    return result
end

local function IsSysUI(obj)
    while obj do
        if SystemUiNames[obj.Name] then return true end
        obj = obj.Parent
    end
    return false
end

local function TranslateObj(obj)
    if IsSysUI(obj) or TranslatingObjects[obj] then return end
    TranslatingObjects[obj] = true
    pcall(function()
        local nText = TranslateText(obj.Text)
        if nText ~= obj.Text then obj.Text = nText end
        local nPlace = TranslateText(obj.PlaceholderText)
        if nPlace ~= obj.PlaceholderText then obj.PlaceholderText = nPlace end
    end)
    TranslatingObjects[obj] = nil
end

local function WatchObj(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
    if WatchedObjects[obj] then return end
    WatchedObjects[obj] = true

    TranslateObj(obj)

    local function onPropChange()
        if not TranslatingObjects[obj] then
            delay(0.03, function() TranslateObj(obj) end)
        end
    end

    pcall(function()
        obj:GetPropertyChangedSignal("Text"):Connect(onPropChange)
        obj:GetPropertyChangedSignal("PlaceholderText"):Connect(onPropChange)
    end)
end

local function GetRoots()
    local roots = {}
    if PlayerGui then table.insert(roots, PlayerGui) end
    pcall(function() table.insert(roots, CoreGui) end)
    pcall(function()
        if gethui then
            local hui = gethui()
            if hui then table.insert(roots, hui) end
        end
    end)
    return roots
end

local function ScanAndWatch(root)
    if not root or WatchedRoots[root] then return end
    WatchedRoots[root] = true

    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            WatchObj(obj)
        end
        root.DescendantAdded:Connect(function(obj)
            delay(0.05, function()
                WatchObj(obj)
                pcall(function()
                    for _, c in ipairs(obj:GetDescendants()) do
                        WatchObj(c)
                    end
                end)
            end)
        end)
    end)
end

-- ===== 如果用户选择了 Hook 模式，尝试安装 =====
local hookInstalled = false
if UseHookTranslation then
    local hookSuccess, hookErr = pcall(function()
        local mt = getrawmetatable(game)
        if not mt then error("getrawmetatable 失败") end
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(t, k, v)
            if (k == "Text" or k == "PlaceholderText") and
               (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) and
               not IsSysUI(t) then
                v = TranslateText(tostring(v))
            end
            return oldNewIndex(t, k, v)
        end)
        setreadonly(mt, true)
    end)
    if not hookSuccess then
        warn("Hook安装失败，降级为监听模式:", hookErr)
        UseHookTranslation = false
        hookInstalled = false
    else
        print("Hook模式已启用")
        hookInstalled = true
    end
else
    print("使用普通监听模式")
end

-- ===== 启动监听扫描（即使 Hook 成功也保留作为备用） =====
spawn(function()
    while true do
        for _, root in ipairs(GetRoots()) do
            ScanAndWatch(root)
            pcall(function()
                for _, obj in ipairs(root:GetDescendants()) do
                    WatchObj(obj)
                end
            end)
        end
        wait(hookInstalled and 20 or 12)
    end
end)

wait(0.5)

-- ===== 加载外部脚本 =====
local ScriptUrl = "https://api.jnkie.com/api/v1/luascripts/public/86b678525ebc850ba62a55acd2e92ceddc86cb15dee91b28a2d916854f1b4865/download"
print("开始下载外部脚本...")

local ok, content = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if not ok then
    warn("下载失败：", content)
elseif not content or content == "" then
    warn("内容为空")
else
    print("下载成功，长度：", #content)
    local func, err = loadstring(content)
    if not func then
        warn("编译失败：", err)
    else
        print("编译成功，执行外部脚本...")
        local execOk, execErr = pcall(func)
        if not execOk then
            warn("执行失败：", execErr)
        else
            print("外部脚本执行成功")
        end
    end
end

print("[汉化] 已加载")

local Translations = {
    --格式：["英文原文"] = "中文翻译",
    ["Rayfield Keybind"] = "Rayfield 快捷键",
    ["Keybind"] = "快捷键",
    ["Anonymised Analytics"] = "匿名分析",
    ["God-Mode Automated Farming"] = "自动农场",
    ["All-In-One Auto Farm Loop"] = "全自动农场循环",
    ["Individual Manual Farms"] = "单独农场",
    ["Auto Use Bucket Only"] = "仅自动使盛水",
    ["Auto Pour Only"] = "仅自动倒水",
    ["Auto Take Tokens Only"] = "仅自动拾取代币",
    ["Chest Options"] = "宝箱选项",
    ["Auto Open All Chests"] = "自动开启所有宝箱",
    ["Auto Open Chest + Safe Teleport"] = "自动开启宝箱 + 安全传送",
    ["Speed Control"] = "速度控制",
    ["Farm Speed Delay (Seconds)"] = "农场速度延迟（秒）",
    ["INF"] = "无限",
    ["Infinite Swim & Anti-Drown"] = "无限游泳 & 防溺水",
    ["Visual ESP Settings"] = "视觉 ESP 设置",
    ["ESP Text Size"] = "ESP 文字大小",
    ["ESP Shark Highlights (Red)"] = "ESP 鲨鱼高亮（红色）",
    ["ESP Phone Highlights (Blue)"] = "ESP 电话高亮（蓝色）",
    ["ESP Players Highlights (Green)"] = "ESP 玩家高亮（绿色）",
    ["Instant Object Teleports"] = "即时物体传送",
    ["Teleport to Phone"] = "传送到手机",
    ["button"] = "按钮",
    ["Teleport to Shark (Danger)"] = "传送到鲨鱼[为什么会有人要这么做]",
    ["Initializing"] = "初始化中[suif汉化]",
    ["Subscribe For More Videos!"] = "订阅获取更多视频！",
    ["Rayfield UI"] = "Rayfield UI",
    ["Farming"] = "农场",
    ["Survival"] = "生存",
    ["ESP Visuals"] = "ESP 视觉",
    ["Teleports"] = "传送",
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local SystemUiNames = {
    RobloxGui=true, PlayerList=true, Backpack=true, Chat=true, BubbleChat=true,
    ExperienceChat=true, TextChatService=true, TopBar=true, Topbar=true, Health=true,
    EmotesMenu=true, Chrome=true, InspectMenu=true, PurchasePrompt=true,
    ScreenshotHud=true, HookTranslateChoice=true
}

local WatchedRoots, WatchedObjects, TranslatingObjects = setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"})

local function AskHookMode()
    local choice, gui, tempChoice = nil, nil, false -- tempChoice 默认 false (普通翻译)
    pcall(function()
        gui = Instance.new("ScreenGui", PlayerGui)
        gui.Name, gui.ResetOnSpawn = "HookTranslateChoice", false

        -- 加大面板尺寸以容纳说明文字
        local f = Instance.new("Frame", gui)
        f.Size, f.Position, f.BackgroundColor3, f.BorderSizePixel = UDim2.new(0,400,0,260), UDim2.new(0.5,-200,0.5,-130), Color3.fromRGB(30,30,30), 0

        local t = Instance.new("TextLabel", f)
        t.Size, t.Position, t.BackgroundTransparency, t.Text, t.TextColor3, t.TextSize, t.Font = UDim2.new(1,0,0,40), UDim2.new(0,0,0,5), 1, "请选择汉化模式", Color3.new(1,1,1), 22, Enum.Font.SourceSansBold

        local i = Instance.new("TextLabel", f)
        i.Size, i.Position, i.BackgroundTransparency, i.Text, i.TextColor3, i.TextSize = UDim2.new(1,0,0,20), UDim2.new(0,0,0,38), 1, "15秒不确定将自动使用普通翻译", Color3.fromRGB(200,200,200), 14

        -- 优缺点说明文本标签
        local desc = Instance.new("TextLabel", f)
        desc.Size, desc.Position, desc.BackgroundTransparency, desc.TextColor3, desc.TextSize, desc.TextWrapped, desc.TextYAlignment, desc.TextXAlignment = UDim2.new(1,-40,0,70), UDim2.new(0,20,0,115), 1, Color3.new(0.9,0.9,0.9), 15, true, Enum.TextYAlignment.Top, Enum.TextXAlignment.Left

        local hb = Instance.new("TextButton", f)
        hb.Size, hb.Position, hb.BackgroundColor3, hb.Text, hb.TextColor3, hb.TextSize, hb.Font = UDim2.new(0,160,0,38), UDim2.new(0,20,0,65), Color3.fromRGB(60,60,60), "Hook翻译", Color3.new(1,1,1), 16, Enum.Font.SourceSansBold

        local nb = Instance.new("TextButton", f)
        nb.Size, nb.Position, nb.BackgroundColor3, nb.Text, nb.TextColor3, nb.TextSize, nb.Font = UDim2.new(0,160,0,38), UDim2.new(1,-180,0,65), Color3.fromRGB(40,150,80), "普通翻译 (默认)", Color3.new(1,1,1), 16, Enum.Font.SourceSansBold

        -- 确定按钮
        local cb = Instance.new("TextButton", f)
        cb.Size, cb.Position, cb.BackgroundColor3, cb.Text, cb.TextColor3, cb.TextSize, cb.Font = UDim2.new(0,200,0,40), UDim2.new(0.5,-100,1,-50), Color3.fromRGB(0,120,200), "确定选择", Color3.new(1,1,1), 18, Enum.Font.SourceSansBold

        local hookText = "【Hook翻译】\n✔️优点：底层拦截，翻译全面且瞬间完成，无视觉延迟。\n❌缺点：修改了底层环境，可能与部分反作弊或其他脚本发生冲突。"
        local normalText = "【普通翻译】（推荐）\n✔️优点：纯净监听，兼容性极强，几乎不会引起报错或冲突。\n❌缺点：动态出现的文字可能有极短延迟，极少部分特殊UI可能漏翻。"

        -- 更新UI显示状态
        local function updateUI()
            if tempChoice then
                hb.BackgroundColor3, nb.BackgroundColor3 = Color3.fromRGB(40,150,80), Color3.fromRGB(60,60,60)
                desc.Text = hookText
            else
                hb.BackgroundColor3, nb.BackgroundColor3 = Color3.fromRGB(60,60,60), Color3.fromRGB(40,150,80)
                desc.Text = normalText
            end
        end
        updateUI() -- 初始化显示

        -- 点击只切换状态
        hb.MouseButton1Click:Connect(function() tempChoice = true; updateUI() end)
        nb.MouseButton1Click:Connect(function() tempChoice = false; updateUI() end)
        
        -- 只有点击确定才会应用选择
        cb.MouseButton1Click:Connect(function() choice = tempChoice end)
    end)

    local start = os.clock()
    -- 等待直到 choice 有值（点击了确定）或者超时15秒
    repeat task.wait() until choice ~= nil or os.clock() - start >= 15
    pcall(function() if gui then gui:Destroy() end end)
    return choice == true
end

local UseHookTranslation = AskHookMode()

local function TranslateText(txt)
    if type(txt) ~= "string" or txt == "" then return txt end
    local clean = txt:gsub("<[^>]->", ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return Translations[txt] or Translations[clean] or txt
end

local function IsSysUI(obj)
    while obj do
        if SystemUiNames[obj.Name] then return true end
        obj = obj.Parent
    end return false
end

local function TranslateObj(obj)
    if IsSysUI(obj) or TranslatingObjects[obj] then return end
    TranslatingObjects[obj] = true
    pcall(function()
        local nText, nPlace = TranslateText(obj.Text), TranslateText(obj.PlaceholderText)
        if nText ~= obj.Text then obj.Text = nText end
        if nPlace ~= obj.PlaceholderText then obj.PlaceholderText = nPlace end
    end)
    TranslatingObjects[obj] = nil
end

local function WatchObj(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) or WatchedObjects[obj] then return end
    WatchedObjects[obj] = true
    TranslateObj(obj)

    for _, prop in ipairs({"Text", "PlaceholderText"}) do
        pcall(function()
            obj:GetPropertyChangedSignal(prop):Connect(function()
                if not TranslatingObjects[obj] then task.delay(0.03, function() TranslateObj(obj) end) end
            end)
        end)
    end
end

local function GetRoots()
    local roots = {PlayerGui}
    pcall(function() table.insert(roots, CoreGui) end)
    pcall(function() if gethui then table.insert(roots, gethui()) end end)
    return roots
end

local function ScanAndWatch(root)
    if not root or WatchedRoots[root] then return end
    WatchedRoots[root] = true

    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do WatchObj(obj) end
        root.DescendantAdded:Connect(function(obj)
            task.delay(0.05, function()
                WatchObj(obj)
                pcall(function() for _, c in ipairs(obj:GetDescendants()) do WatchObj(c) end end)
            end)
        end)
    end)
end

if UseHookTranslation then
    local ok, err = pcall(function()
        local mt = getrawmetatable(game)
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(t, k, v)
            if (k == "Text" or k == "PlaceholderText") and (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) and not IsSysUI(t) then
                v = TranslateText(tostring(v))
            end
            return oldNewIndex(t, k, v)
        end)
        setreadonly(mt, true)
    end)
    if not ok then warn("汉化 Hook 不可用，已使用监听/扫描模式：", err) end
end

task.spawn(function()
    while true do
        for _, root in ipairs(GetRoots()) do
            ScanAndWatch(root)
            pcall(function() for _, obj in ipairs(root:GetDescendants()) do WatchObj(obj) end end)
        end
        task.wait(8)
    end
end)

-- 加载原脚本
task.wait(0.5)
local ScriptUrl = "https://raw.githubusercontent.com/Kaitofyp/-Drain-the-Lake-Op-script/refs/heads/main/obf_5sc8Ei923Fv2TvU1F7uKl54i8Iw81o6GFg3u4CFNLAzycLcP9XqLJf3shJJAFahV.lua.txt"
local ok, result = pcall(function() return game:HttpGet(ScriptUrl) end)
if ok and result and result ~= "" then loadstring(result)() else warn("原脚本获取失败：", result) end

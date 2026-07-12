-- 划到最下面输入你的外部脚本链接
-- 精确翻译表（整句完全匹配）
local Translations = {
    -- 格式：["英文原文"] = "中文翻译"
    ["WordHelper V4"] = "单词助手 V4[suif汉化]",
    ["Fetching latest word list..."] = "正在获取最新单词列表...",
    ["Waiting..."] = "等待中...",
    ["Search words..."] = "搜索单词...",
    ["v Show Settings v"] = "▼ 打开设置 ▼",
    ["^ Hide Settings ^"] = "▲ 隐藏设置 ▲",
    ["Layout: QWERTY"] = "键盘布局：QWERTY",
    ["Humanize: ON"] = "拟人化：开启",
    ["10-Finger: ON"] = "十指打字：开启",
    ["Keyboard: OFF"] = "键盘显示：关闭",
    ["Sort: Random"] = "排序：随机",
    ["Auto Play: OFF"] = "自动游玩：关闭",
    ["Auto Join: OFF"] = "自动加入：关闭",
    ["1v1"] = "1v1",
    ["4 Player"] = "4人模式",
    ["8 Player"] = "8人模式",
    ["Blatant Mode: OFF"] = "暴力模式：关闭",
    ["Risky Mistakes: OFF"] = "风险错误：关闭",
    ["Manage Custom Words"] = "管理自定义单词",
    ["Word Browser"] = "单词浏览器",
    ["Server Browser"] = "服务器浏览器",
}

-- 部分替换表（只替换其中的词，保留其余）
-- 注意：避免替换单个字母（如 "s"），以免误伤
local PartialTranslations = {
    ["Loaded"] = "已加载",
    ["words!"] = "个单词！",
    ["Speed"] = "速度",
    ["CPM"] = "字符/分钟",
    ["Error Rate"] = "错误率",
    ["Think"] = "思考时间",
    -- 不要单独替换 "s"，容易误伤
    ["Words"] = "单词数",
    ["Layout"] = "键盘布局",
}

-- 下面不要动
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

-- ===== 选择翻译模式 =====
local function AskHookMode()
    local choice, gui, tempChoice = nil, nil, false
    pcall(function()
        gui = Instance.new("ScreenGui", PlayerGui)
        gui.Name, gui.ResetOnSpawn = "HookTranslateChoice", false

        local f = Instance.new("Frame", gui)
        f.Size, f.Position, f.BackgroundColor3, f.BorderSizePixel = UDim2.new(0,400,0,260), UDim2.new(0.5,-200,0.5,-130), Color3.fromRGB(30,30,30), 0

        local t = Instance.new("TextLabel", f)
        t.Size, t.Position, t.BackgroundTransparency, t.Text, t.TextColor3, t.TextSize, t.Font = UDim2.new(1,0,0,40), UDim2.new(0,0,0,5), 1, "请选择汉化模式", Color3.new(1,1,1), 22, Enum.Font.SourceSansBold

        local i = Instance.new("TextLabel", f)
        i.Size, i.Position, i.BackgroundTransparency, i.Text, i.TextColor3, i.TextSize = UDim2.new(1,0,0,20), UDim2.new(0,0,0,38), 1, "15秒不确定将自动使用普通翻译", Color3.fromRGB(200,200,200), 14

        local desc = Instance.new("TextLabel", f)
        desc.Size, desc.Position, desc.BackgroundTransparency, desc.TextColor3, desc.TextSize, desc.TextWrapped, desc.TextYAlignment, desc.TextXAlignment = UDim2.new(1,-40,0,70), UDim2.new(0,20,0,115), 1, Color3.new(0.9,0.9,0.9), 15, true, Enum.TextYAlignment.Top, Enum.TextXAlignment.Left

        local hb = Instance.new("TextButton", f)
        hb.Size, hb.Position, hb.BackgroundColor3, hb.Text, hb.TextColor3, hb.TextSize, hb.Font = UDim2.new(0,160,0,38), UDim2.new(0,20,0,65), Color3.fromRGB(60,60,60), "Hook翻译", Color3.new(1,1,1), 16, Enum.Font.SourceSansBold

        local nb = Instance.new("TextButton", f)
        nb.Size, nb.Position, nb.BackgroundColor3, nb.Text, nb.TextColor3, nb.TextSize, nb.Font = UDim2.new(0,160,0,38), UDim2.new(1,-180,0,65), Color3.fromRGB(40,150,80), "普通翻译 (默认)", Color3.new(1,1,1), 16, Enum.Font.SourceSansBold

        local cb = Instance.new("TextButton", f)
        cb.Size, cb.Position, cb.BackgroundColor3, cb.Text, cb.TextColor3, cb.TextSize, cb.Font = UDim2.new(0,200,0,40), UDim2.new(0.5,-100,1,-50), Color3.fromRGB(0,120,200), "确定选择", Color3.new(1,1,1), 18, Enum.Font.SourceSansBold

        local hookText = "【Hook翻译】\n✔️优点：底层拦截，翻译全面且瞬间完成，无视觉延迟。\n❌缺点：修改了底层环境，可能与部分反作弊或其他脚本发生冲突。"
        local normalText = "【普通翻译】（推荐）\n✔️优点：纯净监听，兼容性极强，几乎不会引起报错或冲突。\n❌缺点：动态出现的文字可能有极短延迟，极少部分特殊UI可能漏翻。"

        local function updateUI()
            if tempChoice then
                hb.BackgroundColor3, nb.BackgroundColor3 = Color3.fromRGB(40,150,80), Color3.fromRGB(60,60,60)
                desc.Text = hookText
            else
                hb.BackgroundColor3, nb.BackgroundColor3 = Color3.fromRGB(60,60,60), Color3.fromRGB(40,150,80)
                desc.Text = normalText
            end
        end
        updateUI()

        hb.MouseButton1Click:Connect(function() tempChoice = true; updateUI() end)
        nb.MouseButton1Click:Connect(function() tempChoice = false; updateUI() end)
        cb.MouseButton1Click:Connect(function() choice = tempChoice end)
    end)

    local start = os.clock()
    repeat task.wait() until choice ~= nil or os.clock() - start >= 15
    pcall(function() if gui then gui:Destroy() end end)
    return choice == true
end

local UseHookTranslation = AskHookMode()

-- ===== 核心翻译函数（精确匹配 + 部分替换） =====
local function TranslateText(txt)
    if type(txt) ~= "string" or txt == "" then return txt end
    local clean = txt:gsub("<[^>]->", ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- 1. 精确匹配（整句）
    local exact = Translations[txt] or Translations[clean]
    if exact then return exact end

    -- 2. 部分替换（只替换指定词）
    local result = txt
    for original, translated in pairs(PartialTranslations) do
        result = result:gsub(original, translated)   -- 区分大小写，全局替换
    end
    return result
end

-- ===== 以下为监听/扫描/Hook 逻辑 =====
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

-- ===== 加载外部脚本（带错误保护） =====
task.wait(0.5)

local ScriptUrl = "https://rawscripts.net/raw/Last-Letter-Word-Helper-V3-Auto-Follow-Auto-Typing-etc-73643"

-- 1. 获取脚本内容
local ok, content = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if not ok or not content or content == "" then
    warn("外部脚本下载失败：", content or "空内容")
else
    -- 2. 执行脚本
    local loadOk, func = pcall(function()
        return loadstring(content)
    end)
    if not loadOk then
        warn("外部脚本编译失败：", func)  -- func 是错误信息
    elseif not func then
        warn("外部脚本编译返回 nil")
    else
        local execOk, err = pcall(func)
        if not execOk then
            warn("外部脚本执行失败：", err)
        else
            print("外部脚本已成功加载并执行")
        end
    end
end

print("[汉化] 已加载（精确匹配 + 部分替换）")

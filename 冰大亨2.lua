print("汉化脚本 v3.3")

-- ===== 精确翻译表（整句完全匹配）=====
-- 请在此按 ["英文原文"] = "中文翻译" 格式添加
local Translations = {
    -- 示例: ["Home"] = "主页",
    ["Yuri"] = "Yuri[suif汉化]",
    ["Info"] = "信息",
    ["Main"] = "主要",
    ["Player"] = "玩家",
    ["Config"] = "配置",
    ["Information"] = "信息",
    ["Others"] = "其他",
    ["Join Discord Server"] = "加入 Discord 服务器",
    ["Autofarm"] = "自动农场",
    ["Badge"] = "徽章",
    ["Auto Coins"] = "自动金币",
    ["Auto Crates"] = "自动板条箱",
    ["Auto Fill"] = "自动填充",
    ["Auto Clean"] = "自动清洁",
    ["Auto Harvest"] = "自动收割",
    ["Auto Mine"] = "自动挖掘",
    ["Auto Dropper"] = "自动投掷器",
    ["Auto Buy"] = "自动购买",
    ["Auto Buy Tool"] = "自动购买工具",
    ["Teleport to Tycoon"] = "传送到大亨",
    ["Buy List"] = "购买列表",
    ["Any"] = "任意",
    ["Tool List"] = "工具列表",
    ["Collect Gems"] = "收集宝石",
    ["Collect Trophies"] = "收集奖杯",
    ["Decorative"] = "装饰",
    ["Progress"] = "进度",
    ["Expansion"] = "扩展",
    ["Achievement"] = "成就",
    ["Tool"] = "工具",
    ["Crystal"] = "水晶",
    ["General"] = "常规",
    ["WalkSpeed"] = "行走速度",
    ["TPWalk"] = "传送行走",
    ["JumpPower"] = "跳跃力度",
    ["HipHeight"] = "臀部高度",
    ["Noclip"] = "穿墙",
    ["Anti Knockback"] = "反击退",
    ["Disable 3D Rendering"] = "禁用 3D 渲染",
    ["Gravity"] = "重力",
    ["Camera Zoom"] = "相机缩放",
    ["Field of View"] = "视野",
    ["Set Max FPS"] = "设置最大 FPS",
    ["FPS Boost"] = "FPS 提升",
    ["Server"] = "服务器",
    ["Anti AFK"] = "防挂机",
    ["Anti Kick (Client)"] = "防踢出（客户端）",
    ["Auto Reconnect"] = "自动重连",
    ["No Gameplay Paused"] = "防止游戏暂停",
    ["Serverhop"] = "跳转服务器",
    ["Rejoin"] = "重新加入",
    ["Auto Serverhop"] = "自动跳转服务器",
    ["Game"] = "游戏",
    ["Instant Prompt"] = "即时提示",
    ["Fullbright"] = "全亮",
    ["No Fog"] = "无雾",
    ["Time Of Day"] = "时间",
    ["Unlock UI"] = "解锁界面",
    ["Menu"] = "菜单",
    ["Auto Show UI"] = "自动显示界面",
    ["Open Keybind Menu"] = "打开快捷键菜单",
    ["Custom Cursor"] = "自定义光标",
    ["Notification Side"] = "通知侧",
    ["Right"] = "右侧",
    ["DPI Scale"] = "DPI 缩放",
    ["Menu bind"] = "菜单快捷键",
    ["Unload"] = "卸载",
    ["Themes"] = "主题",
    ["Background color"] = "背景色",
    ["Main color"] = "主色",
    ["Accent color"] = "强调色",
    ["Outline color"] = "轮廓色",
    ["Font color"] = "字体颜色",
    [".webm Video Background (Link)"] = ".webm 视频背景（链接）",
    ["Theme list"] = "主题列表",
    ["Default"] = "默认",
    ["Set as default"] = "设为默认",
    ["Custom theme name"] = "自定义主题名",
    ["Create theme"] = "创建主题",
    ["Custom themes"] = "自定义主题",
    ["Load theme"] = "加载主题",
    ["Overwrite theme"] = "覆盖主题",
    ["Delete theme"] = "删除主题",
    ["Refresh list"] = "刷新列表",
    ["Reset default"] = "重置默认",
    ["Configuration"] = "配置",
    ["Config name"] = "配置名称",
    ["Create config"] = "创建配置",
    ["Config list"] = "配置列表",
    ["Load config"] = "加载配置",
    ["Overwrite config"] = "覆盖配置",
    ["Delete config"] = "删除配置",
    ["Set as autoload"] = "设为自动加载",
    ["Reset autoload"] = "重置自动加载",
    ["Left"] = "左侧",
}

-- ===== 部分替换表（子串替换）=====
-- 请在此按 ["英文子串"] = "中文替换" 格式添加
-- 注意：会替换文本中所有匹配的子串，请谨慎使用
local PartialTranslations = {
    -- 示例: yes no 
    --["yes"] = "是",
    ["Executor"] = "执行器",
    ["Status"] = "状态",
    ["Working"] = "运行中",
    ["Fill When"] = "填充阈值",
    ["Minutes"] = "分钟",
    ["Current autoload config"] = "当前自动加载配置",
    ["none"] = "无",
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
_G.autoExec = false
local ScriptUrl = "https://raw.githubusercontent.com/iLove-yuri/leeeeesbian/refs/heads/main/homumado.lua"
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

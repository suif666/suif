-- 划到最下面输入你的外部脚本链接
-- 精确翻译表（整句完全匹配）
local Translations = {
    -- 格式：["英文原文"] = "中文翻译"
    -- 示例: ["Mini world yyds"] = "迷你世界yyds"
    ["Main"] = "主要",
    ["Auto"] = "自动",
    ["Teleport"] = "传送",
    ["Tools"] = "工具",
    ["Miscellaneous"] = "杂项",
    ["Visuals"] = "视觉",
    ["Player"] = "玩家",
    ["Information"] = "信息",
    ["Credits"] = "鸣谢",
    ["Executor"] = "执行器",
    ["Settings"] = "设置",
    ["Configuration"] = "配置",
    ["Links & Debug"] = "链接与调试",
    ["Keybind"] = "快捷键",
    ["Current"] = "当前",
    ["None"] = "无",
    ["Element keybinds (1)"] = "元素快捷键 (1)",
    ["Bind"] = "绑定",
    ["Clear"] = "清空",
    ["RShift"] = "右 Shift",
    ["LCtrl"] = "左 Ctrl",
    ["Minimize GUI Keybind"] = "最小化界面快捷键",
    ["Config, theme and runtime controls"] = "配置、主题和运行时控制",
    ["Config"] = "配置",
    ["Theme"] = "主题",
    ["Info"] = "信息",
    ["Config Profile"] = "配置档案",
    ["default"] = "默认",
    ["Save"] = "保存",
    ["Load"] = "加载",
    ["Runtime"] = "运行时",
    ["Theme: koyukiTheme"] = "主题：koyukiTheme",
    ["Settings use glass morph layers and tabbed pages."] = "设置使用玻璃态模糊层和标签页。",
    ["WindUI Settings"] = "WindUI 设置",
    ["Use Config for save/load and Theme for quick visual switching."] = "使用配置进行保存/加载，使用主题进行快速视觉切换。",
    ["Folder"] = "文件夹",
    ["Foxname"] = "Foxname",
    ["Topbar"] = "顶栏",
    ["Default"] = "默认",
    ["Motion"] = "动效",
    ["Subtle"] = "柔和",
    ["Auto Check-In"] = "自动登记",
    ["Auto Treatment"] = "自动治疗",
    ["Auto Clean Slime"] = "自动清洁粘液",
    ["Automatically clean slime when it appears"] = "粘液出现时自动清洁",
    ["Auto Fix Camera"] = "自动修复摄像头",
    ["Automatically repair broken cameras"] = "自动修复损坏的摄像头",
    ["Auto Shutter on Anomaly"] = "异常时自动关闭百叶窗",
    ["Close the shutter when an anomaly is at the counter"] = "当异常在前台时关闭百叶窗",
    ["Auto Eliminate Anomaly During Treatment"] = "治疗期间自动消灭异常",
    ["Auto Help Patients"] = "自动帮助病人",
    ["Automatically use Help prompts on patients"] = "自动帮助病人",
    ["Select Categories to Auto Buy"] = "选择自动购买分类",
    ["Auto Buy Shop Items"] = "自动购买商店物品",
    ["Buy shop items matching the selected categories"] = "购买与所选分类匹配的商店物品",
    ["Auto Put Out Fire"] = "自动灭火",
    ["Automatically extinguish fires in rooms"] = "自动扑灭房间内的火焰",
    ["Auto Shutter on Barney"] = "巴尼时自动关闭百叶窗",
    ["Close the shutter when Barney is at the counter"] = "当巴尼在前台时关闭百叶窗",
    ["Auto Give Barney Coffee"] = "自动给巴尼咖啡",
    ["Equip coffee and give it to Barney when available"] = "拾取咖啡并在可用时给巴尼",
    ["Debug Mode"] = "调试模式",
    ["Print detailed script activity to the console"] = "将详细脚本活动打印到控制台",
    ["Auto Ask Anomaly to Leave"] = "自动要求异常离开",
    ["Automatically ask anomalies to leave"] = "自动要求异常离开",
    ["Quick Shift Safe Mode"] = "快速轮班安全模式",
    ["Prioritize check-in, treatment and recovery. Fire suppression is disabled while this mode is active."] = "优先处理登记、治疗和恢复。此模式激活时禁用灭火。",
    ["UPGRADE"] = "升级",
    ["TOOL"] = "工具",
    ["COSMETIC"] = "装饰",
    ["OTHER"] = "其他",
    ["Rejoin Server"] = "重新加入服务器",
    ["Server Hop"] = "跳转服务器",
    ["Check In"] = "登记",
    ["Shop"] = "商店",
    ["Security Cam PC"] = "安全摄像头电脑",
    ["Medical Cameras"] = "医疗摄像头",
    ["Emergency Cameras"] = "紧急摄像头",
    ["Coffee"] = "咖啡",
    ["Shutter Button"] = "百叶窗按钮",
    ["Trash"] = "垃圾桶",
    ["Teleport to Room 1"] = "传送到房间 1",
    ["Teleport to Room 2"] = "传送到房间 2",
    ["Teleport to Room 3"] = "传送到房间 3",
    ["Teleport to Room 4"] = "传送到房间 4",
    ["Teleport to Room 5"] = "传送到房间 5",
    ["Teleport to Room 6"] = "传送到房间 6",
    ["Teleport to Room 7"] = "传送到房间 7",
    ["Teleport to Room 8"] = "传送到房间 8",
    ["Complete Monitor Step Instantly"] = "立即完成监控步骤",
    ["Complete the monitor step without repeating scans"] = "无需重复扫描即可完成监控步骤",
    ["Auto Drink Coffee"] = "自动喝咖啡",
    ["Use any server-visible coffee machine when sanity is low"] = "理智值低时使用任意服务器可见的咖啡机",
    ["Sanity Threshold"] = "理智阈值",
    ["Stability Update"] = "稳定性更新",
    ["Entity ESP is available in Visuals. Weapon automation remains disabled; check-in, treatment, coffee, recovery and diagnostics remain available."] = "实体 ESP 可在视觉选项卡中使用。武器自动化仍处于禁用状态；登记、治疗、咖啡、恢复和诊断仍可用。",
    ["Local Player"] = "本地玩家",
    ["Speed"] = "速度",
    ["Jump Power"] = "跳跃力度",
    ["Noclip"] = "穿墙",
    ["Walk through collidable parts"] = "穿过可碰撞部件",
    ["Unlock Third Person"] = "解锁第三人称",
    ["Switch camera mode to Classic and expand the zoom range"] = "将相机模式切换为经典并扩大缩放范围",
    ["Other"] = "其他",
    ["Infinite Sanity + No Anomalies"] = "无限理智 + 无异常",
    ["Infinite Sanity (BETA)"] = "无限理智（测试版）",
    ["Keep sanity at 100 and block sanity-loss reports."] = "将理智值保持在 100 并拦截理智值丢失提示",
    ["Anti-Death"] = "防死亡",
    ["Hide the game-over screen and restore local controls"] = "隐藏游戏结束画面并恢复本地控制",
    ["Unlock the Second Coffee Machine"] = "解锁第二台咖啡机",
    ["Unlock 2nd Coffee Machine Instanly"] = "立即解锁第二台咖啡机",
    ["Instant Interaction"] = "即时交互",
    ["Copy Link"] = "复制链接",
    ["Owners and Script Developers"] = "所有者和脚本开发者",
    ["Hub owners, developers, and contributors"] = "中心所有者、开发者和贡献者",
    ["Foxname Hub"] = "Foxname Hub[suif汉化]",
    ["Owner of Foxname"] = "Foxname 所有者",
    ["Main developer"] = "主要开发者",
    ["Co-developer of the script"] = "脚本联合开发者",
    ["Developer and script tester"] = "开发者和脚本测试者",
    ["Language"] = "语言[嗯对没有中文]",
    ["Applied after running the script again"] = "重新运行脚本后生效",
    ["English"] = "英语",
    ["Configuration Name"] = "配置名称",
    ["Enter a configuration name..."] = "输入配置名称...",
    ["Create Configuration"] = "创建配置",
    ["Select Configuration"] = "选择配置",
    ["No configuration found"] = "未找到配置",
    ["Load Configuration"] = "加载配置",
    ["Overwrite Configuration"] = "覆盖配置",
    ["Delete Configuration"] = "删除配置",
    ["Auto-Load Configuration"] = "自动加载配置",
    ["Refresh Configuration List"] = "刷新配置列表",
    ["Background Selection"] = "背景选择",
    ["Gradient Start Color"] = "渐变起始颜色",
    ["Gradient End Color"] = "渐变结束颜色",
    ["Select Background"] = "选择背景",
    ["Blue Archive L2D - Kei (Video)"] = "蔚蓝档案 L2D - Kei (视频)",
    ["Background Visibility"] = "背景可见度",
    ["Lower visibility makes text easier to read"] = "降低可见度使文字更易于阅读",
    ["Custom Background"] = "自定义背景",
    ["Background ID / URL"] = "背景 ID / URL",
    ["https://example.com/bg.webm"] = "https://example.com/bg.webm",
    ["No Background"] = "无背景",
    ["Blue Archive L2D - Arona"] = "蔚蓝档案 L2D - Arona",
    ["Blue Archive L2D - Shiroko"] = "蔚蓝档案 L2D - Shiroko",
    ["Blue Archive L2D - Hoshino"] = "蔚蓝档案 L2D - Hoshino",
    ["Blue Archive L2D - Hina"] = "蔚蓝档案 L2D - Hina",
    ["Blue Archive L2D - Azusa"] = "蔚蓝档案 L2D - Azusa",
    ["Blue Archive L2D - Toki"] = "蔚蓝档案 L2D - Toki",
    ["Blue Archive L2D - Aris"] = "蔚蓝档案 L2D - Aris",
    ["Blue Archive L2D - Noa"] = "蔚蓝档案 L2D - Noa",
    ["Blue Archive L2D - Mika"] = "蔚蓝档案 L2D - Mika",
    ["Blue Archive L2D - Aru"] = "蔚蓝档案 L2D - Aru",
    ["Blue Archive L2D - Yuuka"] = "蔚蓝档案 L2D - Yuuka",
    ["Blue Archive L2D - Karin"] = "蔚蓝档案 L2D - Karin",
    ["Blue Archive L2D - Neru"] = "蔚蓝档案 L2D - Neru",
    ["Blue Archive L2D - Mutsuki"] = "蔚蓝档案 L2D - Mutsuki",
    ["Blue Archive L2D - Kisaki"] = "蔚蓝档案 L2D - Kisaki",
    ["Blue Archive L2D - Hoshino Summer"] = "蔚蓝档案 L2D - Hoshino Summer",
    ["Blue Archive L2D - Hina Dress"] = "蔚蓝档案 L2D - Hina Dress",
    ["Genshin - Furina"] = "原神 - 芙宁娜",
    ["Genshin - Raiden Shogun"] = "原神 - 雷电将军",
    ["Genshin - Nahida"] = "原神 - 纳西妲",
    ["Genshin - Hu Tao"] = "原神 - 胡桃",
    ["Genshin - Ayaka"] = "原神 - 神里绫华",
    ["Genshin - Yae Miko"] = "原神 - 八重神子",
    ["Genshin - Navia"] = "原神 - 娜维娅",
    ["Genshin - Neuvillette"] = "原神 - 那维莱特",
    ["Genshin - Wanderer"] = "原神 - 流浪者",
    ["Genshin - Zhongli"] = "原神 - 钟离",
    ["Genshin - Venti"] = "原神 - 温迪",
    ["Genshin - Nilou"] = "原神 - 妮露",
    ["Genshin - Keqing"] = "原神 - 刻晴",
    ["Genshin - Ganyu"] = "原神 - 甘雨",
    ["Genshin - Clorinde"] = "原神 - 克洛琳德",
    ["Genshin - Fontaine"] = "原神 - 枫丹",
    ["Teto - Kasane Teto"] = "Teto - 重音 Teto",
    ["Teto - Teto Classic"] = "Teto - Teto 经典",
    ["Teto - Teto Red"] = "Teto - Teto 红",
    ["Teto - Teto Stage"] = "Teto - Teto 舞台",
    ["Teto - Teto Smile"] = "Teto - Teto 微笑",
    ["Teto - Teto Idol"] = "Teto - Teto 偶像",
    ["Teto - Teto Neon"] = "Teto - Teto 霓虹",
    ["Teto - Teto Retro"] = "Teto - Teto 复古",
    ["Teto - Teto Dream"] = "Teto - Teto 梦幻",
    ["Teto - Twin Drill"] = "Teto - 双钻头",
    ["Miku - Miku Classic"] = "Miku - Miku 经典",
    ["Miku - Miku Stage"] = "Miku - Miku 舞台",
    ["Miku - Miku Aqua"] = "Miku - Miku 水蓝",
    ["Miku - Miku Live"] = "Miku - Miku 现场",
    ["Miku - Snow Miku"] = "Miku - 雪初音",
    ["Miku - Sakura Miku"] = "Miku - 樱花初音",
    ["Miku - Miku Expo"] = "Miku - Miku Expo",
    ["Miku - Project Diva"] = "Miku - Project Diva",
    ["Miku - Future Tone"] = "Miku - Future Tone",
    ["Miku - Miku Neon"] = "Miku - Miku 霓虹",
    ["Miku - Miku Smile"] = "Miku - Miku 微笑",
    ["Miku - Miku Skyline"] = "Miku - Miku 天际线",
    ["Miku - Miku Blue"] = "Miku - Miku 蓝",
    ["Miku - Miku Pop"] = "Miku - Miku 流行",
    ["Miku - Miku Memorial"] = "Miku - Miku 纪念",
    ["Limbus Company - Yi Sang"] = "边狱公司 - 以李箱",
    ["Limbus Company - Faust"] = "边狱公司 - 浮士德",
    ["Limbus Company - Don Quixote"] = "边狱公司 - 唐吉诃德",
    ["Limbus Company - Ryoshu"] = "边狱公司 - 良秀",
    ["Limbus Company - Meursault"] = "边狱公司 - 默尔索",
    ["Limbus Company - Hong Lu"] = "边狱公司 - 鸿璐",
    ["Limbus Company - Heathcliff"] = "边狱公司 - 希斯克利夫",
    ["Limbus Company - Ishmael"] = "边狱公司 - 以实玛利",
    ["Limbus Company - Rodion"] = "边狱公司 - 罗季昂",
    ["Limbus Company - Sinclair"] = "边狱公司 - 辛克莱",
    ["Limbus Company - Outis"] = "边狱公司 - 奥提斯",
    ["Limbus Company - Gregor"] = "边狱公司 - 格里高尔",
    ["Limbus Company - Vergilius"] = "边狱公司 - 维吉尔",
    ["Limbus Company - Bus Interior"] = "边狱公司 - 巴士内部",
    ["Limbus Company - Key Art"] = "边狱公司 - 主视觉图",
    ["Search..."] = "搜索...",
    ["Source"] = "来源",
    ["Runtime Diagnostics"] = "运行时诊断",
    ["Copy Debug Log"] = "复制调试日志",
    ["Reset Camera & Collision"] = "重置相机与碰撞",
    ["Show Runtime Health"] = "显示运行时状态",
    ["Foxname Hub | Animal Hospital"] = "Foxname Hub | 动物医院[suif汉化]",
    
    ["ESP Anomalies"] = "ESP 异常",
    ["Red highlight and label for anomalies"] = "为异常提供红色高亮和标签",
    ["ESP Patients"] = "ESP 病人",
    ["Green highlight and label for patients"] = "为病人提供绿色高亮和标签",
    ["ESP Visitors"] = "ESP 访客",
    ["Cyan highlight and label for visitors"] = "为访客提供青色高亮和标签",
    ["Full Bright"] = "全域高亮",
    ["No Fog"] = "除雾",
    ["Reduce Lag"] = "减少延迟",
    ["Executor Information"] = "执行器信息",
    ["Function Support"] = "功能支持",
    ["Copy Executor Report"] = "复制执行器报告",
    ["Optional:"] = "可选：",
    ["Required:"] = "必需：",
    ["Unsupported Functions"] = "不支持的功能",
    ["setclipboard [Clipboard]: Supported"] = "setclipboard [剪贴板]：支持",
}

-- 部分替换表（只替换其中的词，保留其余）
-- 注意：避免替换单个字母（如 "s"），以免误伤

local PartialTranslations = {
    --会用的就用 不会用的不用填
    -- 格式：["英文部分原文"] = "中文翻译"
    -- 示例: ["yes no"] = "是 否" 只想翻译yes↓↓↓
    -- 示例: ["yes"] = "是"
["saved configs"] = "保存配置",
["theme color"] = "主题颜色",
["theme color"] = "主题颜色",
["Name"] = "名称",
["Version"] = "版本",
["Script Compatibility"] = "脚本兼容性",
["Compatible"] = "兼容",
["Supported Functions"] = "支持的功能",
["Supported"] = "支持",
["Required"] = "必需",

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

-- ===== 翻译模式 =====
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

-- Hook
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

task.wait(0.5)

-- 外部脚本链接↓↓↓
-- 外部脚本链接↓↓↓
-- 外部脚本链接↓↓↓
local ScriptUrl = "https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/FN_AnimalHospital.lua"

-- 下面也别动
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

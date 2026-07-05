local Translations = {
    --格式：["英文原文"] = "中文翻译",
    ["Axon Hub"] = "Axon Hub[suif汉化]",
    ["The Animal Hospital"] = "动物医院",
    ["Free"] = "免费",
    ["HOSPITAL"] = "医院",
    ["Auto Check In"] = "自动登记",
    ["Auto Heal"] = "自动治疗",
    ["Patients"] = "病人",
    ["Survival"] = "生存",
    ["Shop"] = "商店",
    ["PLAYER"] = "玩家",
    ["Combat"] = "战斗",
    ["Player"] = "玩家",
    ["Teleport"] = "传送",
    ["MISC"] = "杂项",
    ["Round"] = "回合",
    ["Settings"] = "设置",
    ["Reception"] = "前台接待",
    ["Works the reception desk for you, in the exact in-game order:\n1) Stamp the form\n2) Take the photo\n3) Use the computer (register)\n4) Print the badge\n5) Take the printed badge\n6) (visitors) operate the shutters\n7) Talk to the person to hand the badge over and send them to their room.\nEach step unlocks the next; the loop keeps cycling so new arrivals get processed automatically. Teleports between stations (Roblox validates prompt distance server-side)."] = "按游戏内顺序自动完成前台工作：\n1) 盖印表格\n2) 拍照\n3) 使用电脑（注册）\n4) 打印徽章\n5) 取走打印好的徽章\n6)（访客）操作百叶窗\n7) 与访客交谈，交出徽章并将其送往房间。\n每个步骤解锁下一步；循环持续运行，新来者会被自动处理。在站点之间传送（Roblox 在服务器端验证提示距离）。",
    ["Check In Once"] = "登记一次",
    ["Teleport To Desk"] = "传送到前台",
    ["Timing"] = "时机",
    ["Loop Delay (s)"] = "循环延迟（秒）",
    ["Badge Print Wait (s)"] = "打印徽章等待时间（秒）",
    ["Return To Desk After Each"] = "每步后返回前台",
    ["Steps"] = "步骤",
    ["Which Steps To Do"] = "要执行的步骤",
    ["Turn individual reception steps on or off. Leave them all on for a normal check-in."] = "单独开启或关闭每个前台步骤。全部开启即为正常登记流程。",
    ["1. Stamp Form"] = "1. 盖印表格",
    ["2. Take Photo"] = "2. 拍照",
    ["3. Use Computer (Register)"] = "3. 使用电脑（注册）",
    ["4. Print Badge"] = "4. 打印徽章",
    ["5. Take Printed Badge"] = "5. 取走打印好的徽章",
    ["6. Open Shutters"] = "6. 打开百叶窗",
    ["7. Talk / Hand Over Badge"] = "7. 交谈 / 交出徽章",
    ["Extra"] = "额外",
    ["Reopen Shutters For Patients"] = "为病人重新打开百叶窗",
    ["Slam Shutters On Skinwalker"] = "对变形者猛关百叶窗",
    ["Treats patients for real: places them in beds, draws the blood sample, runs the analyzer & monitor (auto-completing each minigame so you never get stuck on the computer), READS the diagnosis off the monitor, grabs the EXACT cure each illness needs (Fever->Thermo, Bleeding->Bandages, Rash->Ointment, Canadian->Maple Syrup, Head Ache->Medicine, Dehydration->IV Drops, ...) and applies it. Handles multi-illness patients one cure at a time."] = "真正治疗病人：将其安置在病床上，抽取血样，运行分析仪和监护仪（自动完成每个小游戏，确保你不会卡在电脑上），从监护仪上读取诊断结果，提取每种疾病所需的确切治疗物品（发烧→温度计，出血→绷带，皮疹→药膏，加拿大病→枫糖浆，头痛→药品，脱水→静脉输液等）并使用。一次处理一种病症。",
    ["Heal All Now"] = "立即治疗所有",
    ["Run Machines Now"] = "立即运行机器",
    ["Force Unstuck (close screen)"] = "强制解除卡住（关闭屏幕）",
    ["Targeting & Timing"] = "目标与时机",
    ["Room • All Rooms"] = "房间 • 所有房间",
    ["Prioritize Critical Patients"] = "优先处理危急病人",
    ["Carry Attempt Time (s)"] = "搬运尝试时间（秒）",
    ["Return To Start After Each"] = "每步后返回起点",
    ["Steps & Options"] = "步骤与选项",
    ["Pipeline Steps"] = "流水线步骤",
    ["Turn each machine / treatment step on or off."] = "开启或关闭每台机器/治疗步骤。",
    ["Run Machines"] = "运行机器",
    ["Pick Up Fainted Patients"] = "抱起昏倒的病人",
    ["Place Patient / Set Up"] = "放置病人/准备",
    ["Take DNA Sample"] = "采集 DNA 样本",
    ["Begin X-Ray"] = "开始 X 光",
    ["Analyze Sample"] = "分析样本",
    ["Process Results"] = "处理结果",
    ["Auto Color Minigame"] = "自动颜色小游戏",
    ["Color: Fail First"] = "颜色：先失败",
    ["Auto Surgery (Sleep Patient)"] = "自动手术（让病人睡觉）",
    ["Apply Treatment (correct cure)"] = "应用治疗（正确药品）",
    ["Skinwalkers"] = "变形者",
    ["Kill Skinwalkers (wrong item)"] = "击杀变形者（错误物品）",
    ["Skip Skinwalker Patients"] = "跳过变形者病人",
    ["Live Diagnoses"] = "实时诊断",
    ["Press Refresh to load."] = "按刷新加载。",
    ["Refresh Diagnoses"] = "刷新诊断",
    ["Hospital Deaths"] = "医院死亡次数",
    ["All Rooms"] = "所有房间",
    ["Room1"] = "房间1",
    ["Room2"] = "房间2",
    ["Room3"] = "房间3",
    ["Room4"] = "房间4",
    ["Room5"] = "房间5",
    ["Room6"] = "房间6",
    ["Room7"] = "房间7",
    ["Room8"] = "房间8",
    ["Treat"] = "治疗",
    ["Patients (animals) must be diagnosed and given the matching medicine before they rack up strikes. Some are disguised anomalies (Skinwalker) - check the ESP tab before treating. This sweeps every bed and applies the correct cure."] = "病人（动物）必须在积累失误前得到诊断并给予匹配的药物。有些是伪装的异常（变形者）——治疗前请检查 ESP 选项卡。这会扫描每张病床并应用正确的治疗。",
    ["Heal All Patients"] = "治疗所有病人",
    ["Teleport To Nearest Patient"] = "传送到最近的病人",
    ["Diagnoses"] = "诊断",
    ["Current Diagnoses"] = "当前诊断",
    ["Refresh"] = "刷新",
    ["Sanity"] = "理智值",
    ["Sanity drops from job stress and anomalies; at 0 you go insane. 'Keep Sanity Full' pins your local Sanity to 100 (most effects are client-gated on it); the auto-item option walks you to Coffee / Chocolate when you drop below the threshold."] = "工作压力和异常会降低理智值；降到 0 你会发疯。'保持理智值满' 将本地理智值锁定在 100（大多数效果受客户端控制）；自动物品选项会在你低于阈值时引导你前往咖啡/巧克力。",
    ["Keep Sanity Full"] = "保持理智值满",
    ["Auto Coffee / Chocolate"] = "自动咖啡/巧克力",
    ["Item Threshold (%)"] = "物品阈值（%）",
    ["Help Others"] = "帮助他人",
    ["Anomalies & Teammates"] = "异常与队友",
    ["Auto-complete minigames instantly passes ANY minigame (heart-scan, the computer, Analyze Sample, Process Results) the moment it opens - this is what stops you getting stuck on the computer screen, and it's needed for the work loop to analyze samples. Auto-extinguish puts out fire/grime, auto-revive revives downed teammates, and the skinwalker door shuts the door on a disguised patient."] = "自动完成小游戏：任何小游戏（心跳扫描、电脑操作、分析样本、处理结果）一开启即瞬间完成——这能防止你卡在电脑屏幕上，也是工作循环分析样本所必需的。自动灭火可扑灭火焰/污垢，自动复活可复活倒下的队友，变形者门禁可关闭伪装病人的门。",
    ["Auto Complete Minigames"] = "自动完成小游戏",
    ["Auto Extinguish (Spray)"] = "自动灭火（喷雾）",
    ["Fire Check (s)"] = "火焰检查（秒）",
    ["Spray Time Per Target (s)"] = "每个目标喷雾时间（秒）",
    ["Max Targets Per Pass"] = "每轮最大目标数",
    ["Also Spray Fire Objects"] = "也喷洒火焰物体",
    ["Auto Revive Teammates"] = "自动复活队友",
    ["Revive Check (s)"] = "复活检查（秒）",
    ["Auto Close Door On Skinwalker"] = "对变形者自动关门",
    ["Skinwalker Check (s)"] = "变形者检查（秒）",
    ["Close Skinwalker Door Now"] = "立即关闭变形者门",
    ["Extinguish All Now"] = "立即扑灭所有",
    ["Detector"] = "探测器",
    ["Anomaly ESP"] = "异常 ESP",
    ["Real ESP: 3D boxes, name + distance labels, optional tracers, and through-wall chams. The Skinwalker detector reads the patient's real 'Skinwalker' attribute, so you know which animal is the disguised anomaly before it strikes."] = "真实 ESP：3D 方框、名称+距离标签、可选的轨迹线以及穿墙透视。变形者探测器读取病人的真实“变形者”属性，让你在伪装异常发动攻击前就知道哪个动物是变形者。",
    ["Enable ESP"] = "启用 ESP",
    ["Style"] = "样式",
    ["Boxes"] = "方框",
    ["Name + Distance"] = "名称 + 距离",
    ["Chams (fill)"] = "Chams（填充）",
    ["Tracers"] = "轨迹",
    ["Show"] = "显示",
    ["Targets"] = "目标",
    ["Skinwalker Detector"] = "变形者探测器",
    ["Shadow"] = "阴影",
    ["Monster Under Bed"] = "床底怪物",
    ["Tall Monster"] = "高个子怪物",
    ["Don't Look Up"] = "不要抬头",
    ["Fires"] = "火焰",
    ["Medicine Dispensers"] = "药品分配器",
    ["Players"] = "玩家",
    ["Buy"] = "购买",
    ["Upgrade Shop"] = "升级商店",
    ["Upgrade machines (computers, printers, DNA analyzers) and tool stands are bought by interacting with them. This teleports to each station and buys it. The server checks your Cash."] = "升级机器（电脑、打印机、DNA 分析仪）和工具架可通过与之互动购买。这会传送到每个站点并购买。服务器会检查你的现金。",
    ["Buy All Upgrades"] = "购买所有升级",
    ["Buy Shop Tools"] = "购买商店工具",
    ["Auto Buy Upgrades"] = "自动购买升级",
    ["Auto Buy Interval (s)"] = "自动购买间隔（秒）",
    ["Catalog"] = "目录",
    ["Shop Wares"] = "商店商品",
    ["Refresh Catalog"] = "刷新目录",
    ["Anomalies"] = "异常",
    ["Zombie Hit Aura"] = "僵尸攻击光环",
    ["During zombie anomaly events, hits every nearby zombie at once. Equip a melee tool for best results."] = "在僵尸异常事件期间，同时攻击附近所有僵尸。装备近战工具效果最佳。",
    ["Hit Interval (s)"] = "攻击间隔（秒）",
    ["Hit Zombies Now"] = "立即攻击僵尸",
    ["Notes"] = "备注",
    ["Co-op Game"] = "合作游戏",
    ["The Gun / Taser tools shock or shoot other PLAYERS (griefing), so they are not automated. Buy them in Shop and use manually if you want."] = "枪/电击枪工具会电击或射击其他玩家（恶意行为），因此不自动使用。如需可手动在商店购买使用。",
    ["Movement"] = "移动",
    ["Speed"] = "速度",
    ["WalkSpeed"] = "行走速度",
    ["Lock WalkSpeed"] = "锁定行走速度",
    ["Jump"] = "跳跃",
    ["JumpPower"] = "跳跃力度",
    ["Lock JumpPower"] = "锁定跳跃力度",
    ["Infinite Jump"] = "无限跳跃",
    ["Utilities"] = "实用工具",
    ["Fly / Clip"] = "飞行/穿墙",
    ["Fly (WASD + Space/Ctrl)"] = "飞行（WASD + 空格/Ctrl）",
    ["Fly Speed"] = "飞行速度",
    ["Noclip"] = "穿墙",
    ["Misc"] = "杂项",
    ["Anti AFK"] = "反 AFK",
    ["Quick"] = "快速",
    ["Nearest Patient"] = "最近病人",
    ["Nearest Dispenser"] = "最近分配器",
    ["Nearest Machine"] = "最近机器",
    ["Extinguisher Station"] = "灭火器站",
    ["Security Cameras"] = "安全摄像头",
    ["Player •"] = "玩家 •",
    ["Teleport To Player"] = "传送到玩家",
    ["Refresh Players"] = "刷新玩家",
    ["Round Control"] = "回合控制",
    ["Shift / Round"] = "轮班/回合",
    ["Controls the round flow. After dying you can vote to play again or head back to the lobby."] = "控制回合流程。死亡后你可以投票重新开始或返回大厅。",
    ["Begin Shift"] = "开始轮班",
    ["Vote Play Again"] = "投票重新开始",
    ["Teleport To Lobby"] = "传送到大厅",
    ["Rejoin Server"] = "重新加入服务器",
    ["Copy Job Id"] = "复制任务 ID",
    ["Stats"] = "统计",
    ["Your Stats"] = "你的统计",
    ["Refresh Stats"] = "刷新统计",
    ["Interface"] = "界面",
    ["Theme • Glass"] = "主题 • 玻璃",
    ["Acrylic"] = "亚克力",
    ["Transparency"] = "透明度",
    ["Minimize Bind"] = "最小化快捷键",
    ["RightShift"] = "右 Shift",
    ["Script"] = "脚本",
    ["Unload Script"] = "卸载脚本",
    ["Configuration"] = "配置",
    ["Config name"] = "配置名称",
    ["Config list..."] = "配置列表...",
    ["Create config"] = "创建配置",
    ["Load config"] = "加载配置",
    ["Overwrite config"] = "覆盖配置",
    ["Refresh list"] = "刷新列表",
    ["Set as autoload"] = "设为自动加载",
}
--放脚本链接的地方在底部
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
    ["HookTranslateChoice"] = true,
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

local function AskHookMode()
    local choice = nil
    local gui = nil

    local ok, err = pcall(function()
        gui = Instance.new("ScreenGui")
        gui.Name = "HookTranslateChoice"
        gui.ResetOnSpawn = false
        gui.Parent = PlayerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 155)
        frame.Position = UDim2.new(0.5, -150, 0.5, -77)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 0, 45)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "请选择汉化模式"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 21
        title.Font = Enum.Font.SourceSansBold
        title.Parent = frame

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 0, 35)
        info.Position = UDim2.new(0, 10, 0, 52)
        info.BackgroundTransparency = 1
        info.Text = "8秒不选择将自动使用普通翻译"
        info.TextColor3 = Color3.fromRGB(200, 200, 200)
        info.TextSize = 14
        info.Font = Enum.Font.SourceSans
        info.Parent = frame

        local hookBtn = Instance.new("TextButton")
        hookBtn.Size = UDim2.new(0, 120, 0, 38)
        hookBtn.Position = UDim2.new(0, 22, 1, -52)
        hookBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        hookBtn.Text = "Hook翻译"
        hookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        hookBtn.TextSize = 16
        hookBtn.Font = Enum.Font.SourceSansBold
        hookBtn.Parent = frame

        local normalBtn = Instance.new("TextButton")
        normalBtn.Size = UDim2.new(0, 120, 0, 38)
        normalBtn.Position = UDim2.new(1, -142, 1, -52)
        normalBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        normalBtn.Text = "普通翻译"
        normalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        normalBtn.TextSize = 16
        normalBtn.Font = Enum.Font.SourceSansBold
        normalBtn.Parent = frame

        hookBtn.MouseButton1Click:Connect(function()
            choice = true
        end)

        normalBtn.MouseButton1Click:Connect(function()
            choice = false
        end)
    end)

    if not ok then
        warn("选择窗口创建失败，自动使用普通翻译：", err)
        return false
    end

    local start = os.clock()

    repeat
        task.wait()
    until choice ~= nil or os.clock() - start >= 8

    if choice == nil then
        choice = false
    end

    pcall(function()
        if gui then
            gui:Destroy()
        end
    end)

    return choice
end

local UseHookTranslation = AskHookMode()

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
    if not UseHookTranslation then
        warn("已选择普通翻译模式：不启用 Hook")
        return
    end

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

local ScriptUrl = "https://api.luarmor.net/files/v3/loaders/97c3f6db55a2cf72141537a85458e5a7.lua"

task.wait(0.5)

local ok, result = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if ok and result and result ~= "" then
    loadstring(result)()
else
    warn("原脚本获取失败：", result)
end

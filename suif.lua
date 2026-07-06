-- 1. 远程加载 WindUI 库
local WindUI
do
    local ok, res = pcall(function()
        local source = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        local fn, compileErr = loadstring(source)
        if not fn then
            error(compileErr)
        end
        return fn()
    end)

    if not ok or not res then
        warn("WindUI 加载失败，脚本已停止:", res)
        return
    end

    WindUI = res
end

local plrs = game:GetService("Players")
local lighting = game:GetService("Lighting")
local teleport = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local lp = plrs.LocalPlayer

-- 【视觉体积优化版】全局通知函数：合并内容为单行，让气泡体积缩到最小
local function notify(title, content, icon, duration)
    local shortText = title
    if content and content ~= "" then
        shortText = title .. " | " .. content
    end

    local ok, err = pcall(function()
        WindUI:Notify({ Title = shortText, Duration = duration or 2, Icon = icon or "bell" })
    end)

    if not ok then
        warn("通知失败:", err)
    end
end

local function copy(text, msg)
    if setclipboard then
        setclipboard(text)
    else
        warn("复制失败：当前环境不支持 setclipboard")
    end
end

local function run(url, name)
    local ok, err = pcall(function()
        local source = game:HttpGet(url)
        local fn, compileErr = loadstring(source)
        if not fn then
            error(compileErr)
        end
        fn()
    end)

    if ok then
        notify("执行成功", (name or "脚本") .. " 已运行", "check", 2)
    else
        warn("执行失败: " .. tostring(err))
    end
end

local function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- 全局通用防爆杀 (Adonis Bypass) 提前放置在顶部
getgenv().bypass_adonis = true

if not getgenv().SutureHubAntiAFK then
    getgenv().SutureHubAntiAFK = true
    local vu = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
    notify("防挂机", "正在运行", "info", 2)
end

local uiSet = { Theme = "Dark", Transparent = true, HideSearchBar = false, SideBarWidth = 180 }

local win = WindUI:CreateWindow({
    Title = "Suture Hub", Icon = "aperture", Author = "by suif", Folder = "SutureHub",
    Size = UDim2.fromOffset(620, 460), MinSize = Vector2.new(560, 350), MaxSize = Vector2.new(900, 600),
    ToggleKey = Enum.KeyCode.RightShift, Transparent = uiSet.Transparent, Theme = uiSet.Theme,
    Resizable = true, SideBarWidth = uiSet.SideBarWidth, HideSearchBar = uiSet.HideSearchBar,
    ScrollBarEnabled = true, NewElements = true,
    User = { Enabled = true, Anonymous = false, Callback = function() print("当前用户:", lp.Name) end }
})

win:Tag({ Title = "free", Icon = "gem", Color = Color3.fromHex("#30ff6a"), Radius = 0 })

--// Suture Hub 彩虹边框｜安全防泄漏轻量版
task.delay(0.3, function()
    local ok, err = pcall(function()
        local main = win.UIElements and win.UIElements.Main

        if not main then
            warn("彩虹边框：未找到 win.UIElements.Main")
            return
        end

        local old = main:FindFirstChild("SutureRainbowBorder")
        if old then
            old:Destroy()
        end

        local stroke = Instance.new("UIStroke")
        stroke.Name = "SutureRainbowBorder"
        stroke.Thickness = 3
        stroke.LineJoinMode = Enum.LineJoinMode.Round
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = main

        local gradient = Instance.new("UIGradient")
        gradient.Name = "SutureRainbowGradient"
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        gradient.Parent = stroke

        getgenv().SutureRainbowBorderToken = (getgenv().SutureRainbowBorderToken or 0) + 1
        local token = getgenv().SutureRainbowBorderToken
        local angle = 0

        local borderConnection
        borderConnection = RunService.Heartbeat:Connect(function(dt)
            -- 当重新加载脚本(Token改变) 或 UI被意外销毁时，主动断开连接，彻底防内存泄漏
            if getgenv().SutureRainbowBorderToken ~= token or not gradient.Parent then
                if borderConnection then
                    borderConnection:Disconnect()
                end
                return
            end
            -- 使用 dt 确保开 FPS 解锁器时旋转速度不超速
            angle = (angle + dt * 100) % 360
            gradient.Rotation = angle
        end)
    end)

    if not ok then
        warn("彩虹边框加载失败:", err)
    end
end)


local dialog
dialog = win:Dialog({
    Icon = "megaphone", Title = "公告", Content = "写什么。。是个问题",
    Buttons = {
        {
            Title = "朕已阅",
            Callback = function()
                if dialog and dialog.Close then
                    dialog:Close()
                end
            end
        }
    }
})
task.delay(1, function()
    if dialog and dialog.Show then
        dialog:Show()
    end
end)

-- tabs
local mainTab = win:Tab({ Title = "主页", Icon = "house", Locked = false })

-- sections
local funcSec = win:Section({ Title = "功能", Icon = "folder", Opened = false })
local playerTab = funcSec:Tab({ Title = "玩家类", Icon = "user", Locked = false })
local visualTab = funcSec:Tab({ Title = "高亮类", Icon = "sun", Locked = false })
local fyTab = funcSec:Tab({ Title = "翻译类", Icon = "languages", Locked = false })
local toolTab = funcSec:Tab({ Title = "工具", Icon = "wrench", Locked = false })


local scriptSec = win:Section({ Title = "脚本类", Icon = "folder", Opened = false })
local tyscriptTab = scriptSec:Tab({ Title = "通用", Icon = "shell", Opened = false })
local fescriptTab = scriptSec:Tab({ Title = "Fe脚本", Icon = "shell", Opened = false })
local doorsTab = scriptSec:Tab({ Title = "doors/门", Icon = "shell", Locked = false })
local byqTab = scriptSec:Tab({ Title = "被遗弃", Icon = "shell", Locked = false })
local stgTab = scriptSec:Tab({ Title = "死铁轨", Icon = "shell", Locked = false })
local slTab = scriptSec:Tab({ Title = "扫雷", Icon = "shell", Locked = false })
local fkgsTab = scriptSec:Tab({ Title = "方块故事", Icon = "shell", Locked = false })
local zrzhTab = scriptSec:Tab({ Title = "自然灾害", Icon = "shell", Locked = false })
local xesqTab = scriptSec:Tab({ Title = "将会发生些邪恶事情", Icon = "shell", Locked = false })
local wqkTab = scriptSec:Tab({ Title = "武器库", Icon = "shell", Locked = false })
local wxlgTab = scriptSec:Tab({ Title = "无限旅馆", Icon = "shell", Locked = false })
local dwyyTab = scriptSec:Tab({ Title = "动物医院", Icon = "shell", Locked = false })


local settingsTab = win:Tab({ Title = "设置", Icon = "sliders-horizontal", Locked = false })

-- WindUI 原生顶栏反馈入口
local FeedbackURL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif%E8%84%9A%E6%9C%AC%E5%8F%8D%E9%A6%88%E6%B8%A0%E9%81%93.lua"

-- 屏蔽“执行脚本时反馈模块自己弹出的加载通知”
local function feedbackNotify(title, content, icon, duration)
    local msg = tostring(title or "") .. " " .. tostring(content or "")

    if msg:find("加载", 1, true)
        or msg:find("初始化", 1, true)
        or msg:find("入口", 1, true)
        or msg:find("已启动", 1, true)
        or msg:find("已就绪", 1, true)
    then
        warn("已屏蔽反馈启动通知:", msg)
        return
    end

    notify(title, content, icon, duration)
end

getgenv().SutureHubFeedback = {
    API = "https://suture-feedback.sfbdsl666.workers.dev/",
    WindUI = WindUI,
    Window = win,
    Notify = feedbackNotify
}

task.spawn(function()
    task.wait(0.5)

    local ok, err = pcall(function()
        local src = game:HttpGet(FeedbackURL)
        local fn, loadErr = loadstring(src)

        if not fn then
            error(loadErr)
        end

        fn()
    end)

    if not ok then
        warn("反馈模块加载失败:", err)
    end
end)


-- 主页
mainTab:Paragraph({ Title = "Suture Hub", Desc = "欢迎使用 Suture Hub\n作者：suif\n当前玩家：" .. lp.Name })
local countText = mainTab:Paragraph({ Title = "全网执行次数", Desc = "正在获取..." })
local function updateCount()
    local ok, res = pcall(function()
        return game:HttpGet("https://suture-hub-counter.sfbdsl666.workers.dev/count")
    end)

    if ok then
        res = tostring(res)
        if countText.SetDesc then
            countText:SetDesc("当前全网执行次数：" .. res)
        end
        notify("执行统计", "次数：" .. res, "activity", 2)
    else
        if countText.SetDesc then
            countText:SetDesc("获取失败")
        end
        warn("全网执行次数获取失败:", res)
    end
end

task.spawn(updateCount)

-- 玩家：轻量高效版属性锁定逻辑
getgenv().SutureMoveCfg = getgenv().SutureMoveCfg or {
    WalkSpeed = 16,
    JumpPower = 50,
    Lock = true
}

local MoveCfg = getgenv().SutureMoveCfg

local function applyMovementToHumanoid(h)
    if not h or not h.Parent then return end

    -- 去除高频 pcall，采用值对比，防止反复触发属性变动造成的卡顿
    if h.WalkSpeed ~= MoveCfg.WalkSpeed then
        h.WalkSpeed = MoveCfg.WalkSpeed
    end

    if not h.UseJumpPower then
        h.UseJumpPower = true
    end

    if h.JumpPower ~= MoveCfg.JumpPower then
        h.JumpPower = MoveCfg.JumpPower
    end
end

local function applyMovement()
    local h = getHum()
    if h then
        applyMovementToHumanoid(h)
    end
end

getgenv().SutureMoveToken = (getgenv().SutureMoveToken or 0) + 1
local MoveToken = getgenv().SutureMoveToken

task.spawn(function()
    while getgenv().SutureMoveToken == MoveToken do
        if MoveCfg.Lock then
            applyMovement()
        end
        task.wait(0.25)
    end
end)

lp.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local h = char:WaitForChild("Humanoid", 8)
        if h then
            task.wait(0.2)
            applyMovementToHumanoid(h)
        end
    end)
end)

playerTab:Slider({
    Title = "移动速度",
    Desc = "修改并锁定 WalkSpeed，防止被游戏重置",
    Step = 1,
    Value = { Min = 16, Max = 100, Default = MoveCfg.WalkSpeed or 16 },
    Callback = function(v)
        MoveCfg.WalkSpeed = tonumber(v) or 16
        applyMovement()
    end
})

playerTab:Slider({
    Title = "跳跃高度",
    Desc = "修改并锁定 JumpPower，防止被游戏重置",
    Step = 1,
    Value = { Min = 50, Max = 200, Default = MoveCfg.JumpPower or 50 },
    Callback = function(v)
        MoveCfg.JumpPower = tonumber(v) or 50
        applyMovement()
    end
})

playerTab:Toggle({
    Title = "锁定速度跳跃",
    Desc = "开启后会持续维持上面的速度和跳跃数值",
    Icon = "lock",
    Type = "Checkbox",
    Value = MoveCfg.Lock,
    Callback = function(s)
        MoveCfg.Lock = s
        if s then
            applyMovement()
        end
    end
})

playerTab:Button({
    Title = "恢复默认属性",
    Desc = "恢复默认速度和跳跃，并继续锁定默认值",
    Callback = function()
        MoveCfg.WalkSpeed = 16
        MoveCfg.JumpPower = 50
        MoveCfg.Lock = true
        applyMovement()
    end
})

playerTab:Button({
    Title = "重置角色",
    Desc = "让自己的角色重生",
    Callback = function()
        local h = getHum()
        if h then
            h.Health = 0
        end
    end
})

fyTab:Button({
    Title = "devastate翻译", Desc = "字面意思", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/dream6-e/rbx/refs/heads/main/%E7%BF%BB%E8%AF%91%E8%84%9A%E6%9C%AC.lua", "devastate翻译")
    end
})

-- 视觉
local defaultLighting = {
    Brightness = lighting.Brightness,
    ClockTime = lighting.ClockTime,
    FogStart = lighting.FogStart,
    FogEnd = lighting.FogEnd,
    GlobalShadows = lighting.GlobalShadows
}

local fb = { Enabled = true, Brightness = 2, ClockTime = 14, FogEnd = 100000, Shadows = false }

local function applyFB()
    if fb.Enabled then
        lighting.FogStart = 0
        lighting.Brightness = fb.Brightness
        lighting.ClockTime = fb.ClockTime
        lighting.FogEnd = fb.FogEnd
        lighting.GlobalShadows = fb.Shadows
    else
        lighting.Brightness = defaultLighting.Brightness
        lighting.ClockTime = defaultLighting.ClockTime
        lighting.FogStart = defaultLighting.FogStart
        lighting.FogEnd = defaultLighting.FogEnd
        lighting.GlobalShadows = defaultLighting.GlobalShadows
    end
end
visualTab:Toggle({
    Title = "高亮环境",
    Desc = "这辈子再也不怕黑了。。",
    Icon = "sun",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        fb.Enabled = s
        applyFB()
    end
})
visualTab:Slider({
    Title = "亮度大小", Step = 0.1, Value = { Min = 0, Max = 10, Default = fb.Brightness },
    Callback = function(v) fb.Brightness = v applyFB() end
})
visualTab:Slider({
    Title = "世界时间", Step = 0.5, Value = { Min = 0, Max = 24, Default = fb.ClockTime },
    Callback = function(v) fb.ClockTime = v applyFB() end
})
visualTab:Slider({
    Title = "雾气距离", Step = 1000, Value = { Min = 100, Max = 100000, Default = fb.FogEnd },
    Callback = function(v) fb.FogEnd = v applyFB() end
})
visualTab:Toggle({
    Title = "保留阴影", Desc = "关闭后画面会更亮", Icon = "cloud-sun", Type = "Checkbox", Value = false,
    Callback = function(s) fb.Shadows = s applyFB() end
})

visualTab:Button({
    Title = "恢复默认光照", Desc = "关闭高亮并恢复默认光照",
    Callback = function()
        fb.Enabled = false
        fb.Brightness = 2
        fb.ClockTime = 14
        fb.FogEnd = 100000
        fb.Shadows = false
        applyFB()
    end
})

-- 工具栏
toolTab:Button({
    Title = "重新加入服务器", Desc = "重新进入当前服务器",
    Callback = function() teleport:Teleport(game.PlaceId, lp) end
})

-- 即时互动：稳定版，支持新生成交互、循环补锁、关闭后恢复原值
getgenv().SutureHubPromptHoldCache = getgenv().SutureHubPromptHoldCache or setmetatable({}, { __mode = "k" })
local PromptHoldCache = getgenv().SutureHubPromptHoldCache

-- 重新执行脚本时，先恢复上一次留下的 0 秒交互，避免状态错乱
for prompt, oldHold in pairs(PromptHoldCache) do
    if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") and oldHold ~= nil then
        pcall(function()
            prompt.HoldDuration = oldHold
        end)
    end
    PromptHoldCache[prompt] = nil
end

getgenv().InstantInteract = false

local function setInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    if PromptHoldCache[prompt] == nil then
        PromptHoldCache[prompt] = prompt.HoldDuration
    end

    if prompt.HoldDuration ~= 0 then
        prompt.HoldDuration = 0
    end
end

local function restorePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    local oldHold = PromptHoldCache[prompt]
    if oldHold ~= nil then
        pcall(function()
            prompt.HoldDuration = oldHold
        end)
        PromptHoldCache[prompt] = nil
    end
end

local function scanInstantPrompts(state)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            if state then
                setInstantPrompt(v)
            else
                restorePrompt(v)
            end
        end
    end
end

local function applyInstantInteract(state)
    getgenv().InstantInteract = state
    scanInstantPrompts(state)
end

if getgenv().SuturePromptAddedConn then
    pcall(function()
        getgenv().SuturePromptAddedConn:Disconnect()
    end)
    getgenv().SuturePromptAddedConn = nil
end

getgenv().SuturePromptAddedConn = workspace.DescendantAdded:Connect(function(v)
    if getgenv().InstantInteract and v:IsA("ProximityPrompt") then
        task.defer(function()
            setInstantPrompt(v)
        end)
    end
end)

getgenv().SuturePromptToken = (getgenv().SuturePromptToken or 0) + 1
local PromptToken = getgenv().SuturePromptToken

task.spawn(function()
    while getgenv().SuturePromptToken == PromptToken do
        if getgenv().InstantInteract then
            scanInstantPrompts(true)
        end
        task.wait(0.5)
    end
end)

toolTab:Toggle({
    Title = "即时互动",
    Desc = "开启后无需按住，自动补锁新交互，关闭后恢复原值",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        applyInstantInteract(s)
    end
})

toolTab:Button({
    Title = "Gui文本获取", Desc = "自制 依旧ai神力", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/UI_Text_Collector_Optimized_v21.lua", "Gui文本获取") end
})

toolTab:Button({
    Title = "dex汉化", Desc = "顾名思义", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/dex.lua", "dex汉化") end
})

toolTab:Button({
    Title = "iy汉化", Desc = "顾名思义", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/config/iy%E6%B1%89%E5%8C%96%E7%89%88", "iy汉化") end
})

-- 脚本区域
doorsTab:Button({
    Title = "全自动刷旋钮", Desc = "字面意思 执行后什么都不用管了", Icon = "shell",
    Callback = function()
        getgenv().Config = { MinContainers = 10, MinCoins = 50, UseLockpick = false, UseRobuxKnobsBoost = false }
        run("https://api.luarmor.net/files/v4/loaders/6e87698669de88a8f81d6348ce368b73.lua", "Doors 脚本")
    end
})

doorsTab:Button({
    Title = "半自动刷旋钮",
    Desc = "字面意思 大厅执行后进游戏里收集金币就可以了",
    Icon = "shell",
    Callback = function()
        getgenv().Config = { MinContainers = 10, MinCoins = 50, UseLockpick = false, UseRobuxKnobsBoost = false }
        run("https://api.jnkie.com/api//luascripts/public/5d2e14fd21f767f03b28cfb5537f6260a6f45279ddeb806fd04e706153ed0ce0/download", "Doors 脚本")
    end
})

doorsTab:Button({
    Title = "mspaint",
    Desc = "需卡密 超好用",
    Icon = "shell",
    Callback = function()
        local link = "https://www.mspaint.cc/key"
        if setclipboard then
            setclipboard(link)
        else
            warn("复制失败：当前环境不支持复制链接")
        end
        run("https://api.luarmor.net/files/v3/loaders/002c19202c9946e6047b0c6e0ad51f84.lua", "Doors msp")
    end
})

doorsTab:Divider({ Title = "Doors 刷复活" })
doorsTab:Paragraph({
    Title = "Doors 刷复活",
    Desc = "填写主号、小号和数量后，点击按钮复制生成好的脚本。\n低性能设备建议 6666，高性能设备建议 8888。"
})

local reviveCfg = { MainAccount = "", AltAccount = "", DuplicationAmount = 6666 }
local function luaStr(s) return string.format("%q", tostring(s or "")) end

doorsTab:Input({
    Title = "主号用户名", Desc = "填写 MainAccount", Placeholder = "这里填主号用户名", Value = "",
    Callback = function(v) reviveCfg.MainAccount = v end
})
doorsTab:Input({
    Title = "小号用户名", Desc = "填写 AltAccount", Placeholder = "这里填小号用户名", Value = "",
    Callback = function(v) reviveCfg.AltAccount = v end
})
doorsTab:Dropdown({
    Title = "复制数量", Desc = "高性能设备建议 8888，低性能设备建议 6666", Values = { "6666", "8888" }, Value = "6666",
    Callback = function(v) reviveCfg.DuplicationAmount = tonumber(v) end
})
doorsTab:Paragraph({ Title = "数量提示", Desc = "低性能设备请选择 6666\n高性能设备可以选择 8888" })
doorsTab:Button({
    Title = "复制 Doors 刷复活脚本", Desc = "根据上面的参数生成脚本并复制", Icon = "copy",
    Callback = function()
        if reviveCfg.MainAccount == "" or reviveCfg.AltAccount == "" then
            return
        end
        local scriptText = 'MainAccount = ' .. luaStr(reviveCfg.MainAccount) .. ' -- 主号用户名\nAltAccount = ' .. luaStr(reviveCfg.AltAccount) .. ' -- 小号用户名\n\nDuplicationAmount = ' .. tostring(reviveCfg.DuplicationAmount) .. '\nloadstring(game:HttpGet("https://raw.githubusercontent.com/notpoiu/Scripts/refs/heads/main/doors/revives.lua"))()'
        if setclipboard then
            setclipboard(scriptText)
        else
            warn("复制失败：环境不支持，已输出至控制台")
            print(scriptText)
        end
    end
})

byqTab:Button({
    Title = "fart[suif汉化]", Desc = "无卡密 个人感觉很好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/fa%E6%B1%89%E5%8C%96", "被遗弃脚本") end
})

stgTab:Button({
    Title = "叶子", Desc = "需卡密 好长时间都没有更新了...", Icon = "shell",
    Callback = function() run("https://getnative.cc/script/loader", "死铁轨叶子") end
})

stgTab:Button({
    Title = "ringta[suif汉化]", Desc = "无卡密 老朋友了 更新速度还算可以", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/Ringta%E6%AD%BB%E9%93%81%E8%BD%A8.lua", "死铁轨ringta") end
})

slTab:Button({
    Title = "扫雷", Desc = "无卡密 支持服务器bLockerman's Minesweeper", Icon = "shell",
    Callback = function() run("https://project-xiaeo.vercel.app/api/v1/luascripts/public/3d7d1c298ca6ff866ccb419f77d6b97d9e22c6be0d239b80d46d753f539d31e8/download", "扫雷") end
})

slTab:Button({
    Title = "扫雷02", Desc = "无卡密 支持服务器bLockerman's Minesweeper", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/timmytim12354-png/simplescriptz/refs/heads/main/loader.lua?='", "扫雷") end
})

fkgsTab:Button({
    Title = "方块故事[suif汉化]", Desc = "无卡密 超好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%96%B9%E5%9D%97%E6%95%85%E4%BA%8B.lua", "方块故事") end
})

zrzhTab:Button({
    Title = "自然灾害 龙卷风", Desc = "无卡密 大风车呀滴溜溜的转...", Icon = "shell",
    Callback = function() run("https://pastebin.com/raw/JR7RBh2a", "自然灾害") end
})

xesqTab:Button({
    Title = "将会发生些邪恶事情", Desc = "无卡密 无限体力", Icon = "shell",
    Callback = function() run("https://rawscripts.net/raw/UPD-something-evil-will-happen-Inf-stamina-57438", "邪恶事情") end
})

wqkTab:Button({
    Title = "武器库 静默瞄准", Desc = "无卡密 没有esp..", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/PasteWare.lua", "武器库")
    end
})

-- 无限旅馆安全加载处理（防止网络崩溃拖垮整个脚本）
task.spawn(function()
    local ok, err = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%97%A0%E9%99%90%E6%97%85%E9%A6%86%E7%89%A9%E5%93%81%E9%AB%98%E4%BA%AE.lua")
        local fn = loadstring(src)
        if fn then
            fn().CreateUI(wxlgTab)
        else
            error("解析无限旅馆代码失败")
        end
    end)
    if not ok then
        warn("无限旅馆物品高亮加载失败:", err)
    end
end)

fescriptTab:Button({
    Title = "fe无敌少侠", Desc = "他人可见", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/giobolqvi1/universal-conquest-fly-by-GioBolqv1/refs/heads/main/lonely.lua", "无敌少侠")
    end
})

fescriptTab:Button({
    Title = "fe祖国人[suif汉化]", Desc = "晚安,阿祖", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%A5%96%E5%9B%BD%E4%BA%BA%E6%B1%89%E5%8C%96.lua", "祖国人")
    end
})

fescriptTab:Button({
    Title = "fe火车头[suif汉化]", Desc = "情侣拆散器", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%81%火%E8%BD%A4%E6%B1%89%E5%8C%96.lua", "火车头")
    end
})

fescriptTab:Button({
    Title = "fe死亡[suif汉化]", Desc = "他人可见 优质的动作脚本。。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/uhhhhhh.lua", "uhhhh")
    end
})


tyscriptTab:Button({
    Title = "飞行V3", Desc = "顾名思义", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/FlyGuiV3.lua", "飞行V3")
    end
})

tyscriptTab:Button({
    Title = "npc控制[suif汉化]", Desc = "可以控制npc", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/npc%E6%B1%89%E5%8C%96.lua", "npc控制")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类[suif汉化]", Desc = "无卡密 有些事件需要手动去完成 另外我用这个只活到15天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/HBtj3VFu", "动物医院")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类02[suif汉化]", Desc = "需卡密 有些事件需要手动去完成 没测试最高多少天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/pFzZvHum", "动物医院02")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类03[suif汉化]", Desc = "需卡密 高度自定义 至少ui挺好看 不好用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2%20%E5%8A%9F%E8%83%BD%E4%B8%B0%E5%AF%8C.lua", "动物医院03")
    end
})

-- UI设置
local themeMap = {
    ["深色"]="Dark", ["浅色"]="Light", ["玫瑰"]="Rose", ["植物"]="Plant", ["红色"]="Red",
    ["靛蓝"]="Indigo", ["天空蓝"]="Sky", ["紫罗兰"]="Violet", ["琥珀"]="Amber"
}
settingsTab:Dropdown({
    Title = "UI 主题", Desc = "切换 UI 主题",
    Values = { "深色","浅色","玫瑰","植物","红色","靛蓝","天空蓝","紫罗兰","琥珀" },
    Value = "深色",
    Callback = function(name)
        local real = themeMap[name]
        uiSet.Theme = real
        if WindUI.SetTheme then WindUI:SetTheme(real) elseif win.SetTheme then win:SetTheme(real) end
    end
})

notify("Suture Hub", "成功加载全部功能！", "bird", 3)
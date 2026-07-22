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

-- 【视觉体积优化版】全局通知函数
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

-- 全局通用防爆杀 (Adonis Bypass)
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

--// 【彩虹边框】原版 while 逻辑回归
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 3
UIStroke.LineJoinMode = Enum.LineJoinMode.Round
UIStroke.Parent = win.UIElements.Main

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
}
UIGradient.Parent = UIStroke

task.spawn(function()
    while true do
        for i = 0, 360, 1 do
            UIGradient.Rotation = i
            task.wait(0.005)
        end
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
local npcTab = funcSec:Tab({ Title = "NPC类", Icon = "user", Locked = false })
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
local pghsTab = scriptSec:Tab({ Title = "排干湖水", Icon = "shell", Locked = false })
local lcTab = scriptSec:Tab({ Title = "莱克星顿与康科德/lc", Icon = "shell", Locked = false })
local zhyfxTab = scriptSec:Tab({ Title = "最后一封信", Icon = "shell", Locked = false })
local sxmsaTab = scriptSec:Tab({ Title = "数学谋杀案", Icon = "shell", Locked = false })
local zbjscqtTab = scriptSec:Tab({ Title = "在北极生存7天", Icon = "shell", Locked = false })


local settingsTab = win:Tab({ Title = "设置", Icon = "sliders-horizontal", Locked = false })


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

-- 玩家
getgenv().SutureMoveCfg = getgenv().SutureMoveCfg or {
    WalkSpeed = 16,
    JumpPower = 50,
    Lock = true
}

local MoveCfg = getgenv().SutureMoveCfg

local function applyMovementToHumanoid(h)
    if not h or not h.Parent then return end

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

-- 即时互动
getgenv().SutureHubPromptHoldCache = getgenv().SutureHubPromptHoldCache or setmetatable({}, { __mode = "k" })
local PromptHoldCache = getgenv().SutureHubPromptHoldCache

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
    Title = "Gui文本获取v24", Desc = "自制 ai神力 感谢李藝州🙏🙏🙏", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/UI%E6%8F%90%E5%8F%96_v24_%E4%BF%AE%E5%A4%8D%E7%89%88.lua", "Gui文本获取v24") end
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

byqTab:Button({
    Title = "fart[suif汉化]", Desc = "无卡密 个人感觉很好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/fa%E6%B1%89%E5%8C%96", "被遗弃脚本") end
})

byqTab:Button({
    Title = "jnkie", Desc = "无卡密 依旧国外大手子制作", Icon = "shell",
    Callback = function() run("https://api.jnkie.com/api/v1/luascripts/public/d36d2b96db2abcbb0f20b5c556b53cc5260ff74db0f8bfc3bea83eaa1da7947f/download", "被遗弃脚本02") 
end
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
    Title = "方块故事[suif汉化]", Desc = "无卡密 支持方块故事战斗模拟器", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%96%B9%E5%9D%97%E6%95%85%E4%BA%8B%E6%B1%89%E5%8C%96.lua", "方块故事") end
})

zrzhTab:Button({
    Title = "自然灾害 龙卷风", Desc = "无卡密 大风车呀滴溜溜的转...", Icon = "shell",
    Callback = function() run("https://pastebin.com/raw/JR7RBh2a", "自然灾害") end
})

xesqTab:Button({
    Title = "将会发生些邪恶事情", Desc = "没有Gui 点击即执行 无限体力", Icon = "shell",
    Callback = function() run("https://rawscripts.net/raw/UPD-something-evil-will-happen-Inf-stamina-57438", "邪恶事情") end
})

wqkTab:Button({
    Title = "武器库 静默瞄准", Desc = "无卡密 没有esp 但是有静默瞄准", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/PasteWare.lua", "武器库")
    end
})

getgenv().Tabs = {
    wxlgTab = wxlgTab
}

run("https://pastebin.com/raw/wV07BGnS")

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
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%81%B3%E8%BD%A4%E6%B1%89%E5%8C%96.lua", "火车头")
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
    Title = "动物医院 自动类01[suif汉化]", Desc = "需卡密 有些事件需要手动去完成 另外我用这个只活到15天", Icon = "shell",
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
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2%20%E5%8A%9F%E8%83%BD%E4%B8%B0%E5%AF%8F.lua", "动物医院03")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类04[suif汉化]", Desc = "无卡密 美丽ui 挺好用 就是容易治死人导致游戏结束 等作者优化吧 启动时会有雷霆大叫[调低音量]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2Foxname%5Bsuifhanghang%5D.lua", "动物医院04")
    end
})

pghsTab:Button({
    Title = "排干湖水 自动类01[suif汉化]", Desc = "无卡密    离售卖机远了没法自动售卖  15分钟左右通关", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/heads/main/%E6%8E%92%E7%A9%BA%E6%B9%96%E6%B0%B4.lua", "排干湖水01")
    end
})

lcTab:Button({
    Title = "lc脚本01", Desc = "", Icon = "shell",
    Callback = function()
        local link = "heiqiang-fa84d1b1-141d-46ad-991a-73b65016038c"
        if setclipboard then
            setclipboard(link)
            notify("复制成功", "卡密已复制到剪贴板！", "clipboard", 2)
        end
        run("https://api.jnkie.com/api/v1/luascripts/public/6bd5c94e9da68dce4a2bdf5abd1f6fb9a1379f41faaadbc0354b98d543066f58/download", "lc莱克星顿与康科德")
    end
})

zhyfxTab:Button({
    Title = "最后一封信 自动类01[suif汉化]", Desc = "无卡密 有些词脚本想不出来 还是人脑牛逼👍🏻👍🏻👍🏻", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%86%99%E4%B8%80%E5%B0%81%E4%BF%A1%5B%E6%B1%89%E5%8C%96%5D.lua", "最后一封信01")
    end
})

sxmsaTab:Button({
    Title = "数学谋杀案 自动类01[suif汉化]", Desc = "无卡密 这游戏有什么好开的。。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%95%B0%E5%AD%A6%E8%B0%8B%E6%9D%80%E6%A1%88%5B%E6%B1%89%E5%8C%96%5D.lua", "数学谋杀案01")
    end
})

zbjscqtTab:Button({
    Title = "在北极生存7天 自动类01[suif汉化]", Desc = "需卡密 加载时间可能比较长 不好用", Icon = "shell",
    Callback = function()
        local link = "https://wayoutscript.netlify.app/getkey"
        if setclipboard then
            setclipboard(link)
            notify("复制成功", "解卡链接已复制到剪贴板！", "clipboard", 2)
        end
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9C%A8%E5%8C%97%E6%9E%81%E7%94%9F%E5%AD%987%E5%A4%A9.lua", "在北极生存7天01")
    end
})

getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.npcTab = npcTab

local npcRemoteUrl = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/npc类"
loadstring(game:HttpGet(npcRemoteUrl))()


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

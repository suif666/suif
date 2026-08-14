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

local function run(url, name)
    task.spawn(function()
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
    end)
end

-- 后台异步加载远程模块：失败自动重试，仍失败时给出可见提示
local function loadRemote(url, desc)
    task.spawn(function()
        local ok, err
        for attempt = 1, 3 do
            ok, err = pcall(function()
                local src = game:HttpGet(url)
                local fn, compileErr = loadstring(src)
                if not fn then
                    error(compileErr)
                end
                fn()
            end)
            if ok then
                return
            end
            task.wait(0.5 * attempt)
        end
        warn((desc or "远程脚本") .. " 加载失败:", err)
        pcall(notify, desc or "远程脚本", "加载失败：" .. tostring(err), "warning", 5)
    end)
end

-- 全局通用防爆杀 (Adonis Bypass)
getgenv().bypass_adonis = true
--反挂机
if not getgenv().SutureHubAntiAFK then
    getgenv().SutureHubAntiAFK = true

    local function disableIdleConnections()
        if not getconnections then
            return nil, "当前执行器不支持 getconnections"
        end

        local found = false
        for _, conn in ipairs(getconnections(lp.Idled)) do
            found = true
            if conn.Disable then
                conn:Disable()
            elseif conn.Disconnect then
                conn:Disconnect()
            end
        end
        if not found then
            return nil, "未发现闲置检测连接"
        end
        return true
    end

    local ok, res = pcall(disableIdleConnections)
    if ok and res then
        notify("防挂机", "正在运行", "info", 2)
        -- 定时复查：防止游戏脚本重新挂上闲置检测连接
        task.spawn(function()
            while getgenv().SutureHubAntiAFK do
                task.wait(180)
                pcall(disableIdleConnections)
            end
        end)
    elseif ok then
        warn("防挂机:", res)
    else
        warn("防挂机启动失败:", res)
    end
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

-- 主窗口可见性广播：子脚本的独立浮层（雷达、Ping/FPS 等）跟随主 UI 一起显示/隐藏
getgenv().SutureMainWindow = win
getgenv().SutureMainUIVisible = true
task.spawn(function()
    while true do
        task.wait(0.15)
        local ok, vis = pcall(function()
            return win.UIElements.Main.Visible
        end)
        getgenv().SutureMainUIVisible = ok and vis or false
    end
end)

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
        local dt = task.wait()
        UIGradient.Rotation = (UIGradient.Rotation + dt * 200) % 360
    end
end)


local dialog
dialog = win:Dialog({
    Icon = "megaphone", Title = "公告", Content = "觉得脚本好用的话可以分享给好友 如果感觉哪里不好可以点击右上角反馈按钮进行反馈",
    Buttons = {
        {
            Title = "我知晓",
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
-- 防止公告弹窗挡住关闭/最小化按钮：5 秒后自动关闭
task.delay(5, function()
    if dialog and dialog.Close then
        dialog:Close()
    end
end)

-- 主页
local mainTab = win:Tab({ Title = "主页", Icon = "house", Locked = false })
mainTab:Select()

-- 功能类
local funcSec = win:Section({ Title = "功能", Icon = "folder", Opened = false })
local playerTab = funcSec:Tab({ Title = "玩家类", Icon = "user", Locked = false })
local FwTab = funcSec:Tab({ Title = "范围类", Icon = "user", Locked = false })
local SfTab = funcSec:Tab({ Title = "甩飞类", Icon = "user", Locked = false })
local amTab = funcSec:Tab({ Title = "自瞄类", Icon = "user", Locked = false })
local sayTab = funcSec:Tab({ Title = "发言类", Icon = "user", Locked = false })
local fyTab = funcSec:Tab({ Title = "翻译类", Icon = "languages", Locked = false })
local toolTab = funcSec:Tab({ Title = "工具类", Icon = "wrench", Locked = false })
local serverTab = funcSec:Tab({ Title = "服务器类", Icon = "user", Locked = false })

-- 视觉类
local shijueSec = win:Section({ Title = "视觉类", Icon = "palette", Locked = false })
local espTab = shijueSec:Tab({ Title = "透视类", Icon = "user", Locked = false })
local pingfpsTab = shijueSec:Tab({ Title = "ping/fps显示", Icon = "rss", Locked = false })
local radarTab = shijueSec:Tab({ Title = "雷达", Icon = "radar", Locked = false })
local fovTab = shijueSec:Tab({ Title = "视野", Icon = "palette", Locked = false })

-- 脚本类
local scriptSec = win:Section({ Title = "脚本类", Icon = "folder", Opened = false })
local tyscriptTab = scriptSec:Tab({ Title = "通用", Icon = "shell", Opened = false })
local gnjbTab = scriptSec:Tab({ Title = "国内脚本", Icon = "shell", Opened = false })
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
local scjsjjcTab = scriptSec:Tab({ Title = "生存僵尸竞技场", Icon = "shell", Locked = false })
local nljjcTab = scriptSec:Tab({ Title = "能力竞技场", Icon = "shell", Locked = false })
local bdh2Tab = scriptSec:Tab({ Title = "冰大亨2", Icon = "shell", Locked = false })
local zxdyTab = scriptSec:Tab({ Title = "重型钓鱼", Icon = "shell", Locked = false })
local sqjjcTab = scriptSec:Tab({ Title = "手枪竞技场", Icon = "shell", Locked = false })
local hcyghdTab = scriptSec:Tab({ Title = "合成一个核弹", Icon = "shell", Locked = false })
local cclsTab = scriptSec:Tab({ Title = "储存猎手：开放世界", Icon = "shell", Locked = false })
local smnmTab = scriptSec:Tab({ Title = "售卖柠檬", Icon = "shell", Locked = false })
local csTab = scriptSec:Tab({ Title = "测试", Icon = "shell", Locked = false })


local settingsTab = win:Tab({ Title = "设置", Icon = "user", Locked = false })

-- WindUI 原生顶栏反馈入口
local FeedbackURL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif%E8%84%9A%E6%9C%AC%E5%8F%8D%E9%A6%88%E6%B8%A0%E9%81%93.lua"

-- 屏蔽“执行脚本时反馈模块自己弹出的加载通知”
-- 但保留用户真正发送反馈时可能需要的成功/失败提示
local function feedbackNotify(title, content, icon, duration)
    local msg = tostring(title or "") .. " " .. tostring(content or "")

    if msg:find("加载", 1, true)
        or msg:find("初始化", 1, true)
        or msg:find("入口", 1, true)
        or msg:find("已启动", 1, true)
        or msg:find("已就绪", 1, true)
    then
        warn("反馈模块已加载", msg)
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

mainTab:Paragraph({
    Title = "小提醒",
    Desc = "脚本右上角可以进行反馈\n脚本名字带有[🔑]则需要卡密 没有就是不需要"
})

mainTab:Paragraph({
    Title = "Suture Hub",
    Desc = "欢迎使用 Suture Hub\n作者：suif\n当前玩家：" .. lp.Name
})

local countText = mainTab:Paragraph({
    Title = "全网执行次数",
    Desc = "正在获取..."
})

local function updateCount()
    local ok, res = pcall(function()
        local player = game.Players.LocalPlayer
        local playerName = player.Name
        local displayName = player.DisplayName
        local userId = tostring(player.UserId)
        local accountAge = tostring(player.AccountAge)
        local maxPlayers = tostring(game.Players.MaxPlayers)

        -- 获取真实游戏名
        local gameName = game.Name
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name then
                gameName = info.Name
            end
        end)

        -- 获取注入器名称
        local executor = "未知"
        pcall(function()
            executor = identifyexecutor() or "未知"
        end)

        local HttpService = game:GetService("HttpService")
        local url = "https://suture-hub-counter.sfbdsl666.workers.dev/count"
            .. "?player="      .. HttpService:UrlEncode(playerName)
            .. "&displayname=" .. HttpService:UrlEncode(displayName)
            .. "&userid="      .. HttpService:UrlEncode(userId)
            .. "&game="        .. HttpService:UrlEncode(gameName)
            .. "&placeid="     .. HttpService:UrlEncode(tostring(game.PlaceId))
            .. "&accountage="  .. HttpService:UrlEncode(accountAge)
            .. "&executor="    .. HttpService:UrlEncode(executor)
            .. "&maxplayers="  .. HttpService:UrlEncode(maxPlayers)

        return game:HttpGet(url)
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

mainTab:Select()

fyTab:Paragraph({
    Title = "注意",
    Desc = "先用别人写好的 等我用空了在自己写一个"
})

fyTab:Space()

fyTab:Button({
    Title = "devastate翻译", Desc = "字面意思", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/dream6-e/rbx/refs/heads/main/%E7%BF%BB%E8%AF%91%E8%84%9A%E6%9C%AC.lua", "devastate翻译")
    end
})

-- 视觉

-- ============ 视野（FOV） ============
local RunService = game:GetService("RunService")
local fovConn = nil
pcall(function()
    fovTab:Slider({
        Title = "视野角度",
        Desc = "70 = 默认，120 = 广角，会持续锁定防止被游戏重置",
        Step = 1,
        Value = { Min = 70, Max = 120, Default = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70 },
        Callback = function(v)
            local fov = tonumber(v) or 70
            if fovConn then
                fovConn:Disconnect()
                fovConn = nil
            end
            fovConn = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                if cam and cam.FieldOfView ~= fov then
                    cam.FieldOfView = fov
                end
            end)
        end
    })
end)

-- 即时互动（极简版，几乎不掉帧）
getgenv().SutureHubPromptHoldCache = getgenv().SutureHubPromptHoldCache or setmetatable({}, { __mode = "k" })
local PromptHoldCache = getgenv().SutureHubPromptHoldCache

for prompt, oldHold in pairs(PromptHoldCache) do
    if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") and oldHold ~= nil then
        pcall(function() prompt.HoldDuration = oldHold end)
    end
    PromptHoldCache[prompt] = nil
end

getgenv().InstantInteract = false

local PromptConn

-- 断开上次执行遗留的连接
if getgenv().SuturePromptAddedConn then
    pcall(function() getgenv().SuturePromptAddedConn:Disconnect() end)
    getgenv().SuturePromptAddedConn = nil
end

local function setInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if PromptHoldCache[prompt] == nil then
        PromptHoldCache[prompt] = prompt.HoldDuration
    end
    if prompt.HoldDuration ~= 0 then
        prompt.HoldDuration = 0
    end
end

local function restoreAllPrompts()
    for prompt, oldHold in pairs(PromptHoldCache) do
        if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") then
            pcall(function() prompt.HoldDuration = oldHold end)
        end
        PromptHoldCache[prompt] = nil
    end
end

local function setPromptListener(enable)
    if enable then
        if not PromptConn then
            PromptConn = workspace.DescendantAdded:Connect(function(v)
                if v:IsA("ProximityPrompt") then
                    setInstantPrompt(v)
                end
            end)
            getgenv().SuturePromptAddedConn = PromptConn
        end
    elseif PromptConn then
        pcall(function() PromptConn:Disconnect() end)
        PromptConn = nil
        getgenv().SuturePromptAddedConn = nil
    end
end

toolTab:Toggle({
    Title = "即时互动",
    Desc = "关闭恢复初始数值，但可能需要玩家死亡一次或互动按钮刷新一次",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        getgenv().InstantInteract = s
        if s then
            setPromptListener(true)
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    setInstantPrompt(v)
                end
            end
        else
            setPromptListener(false)
            restoreAllPrompts()
        end
    end
})


toolTab:Button({
    Title = "Gui文本获取v25", Desc = "自制 ai神力 感谢李藝州🙏🙏🙏", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/UI%E6%96%87%E6%9C%AC%E6%8F%90%E5%8F%96.lua", "Gui文本获取v25") end
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
    Title = "[🔑]mspaint",
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
    Title = "fart[suif汉化]", Desc = "个人感觉很好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/fa%E6%B1%89%E5%8C%96", "被遗弃脚本") end
})

byqTab:Button({
    Title = "jnkie", Desc = "依旧国外大手子制作", Icon = "shell",
    Callback = function() run("https://api.jnkie.com/api/v1/luascripts/public/d36d2b96db2abcbb0f20b5c556b53cc5260ff74db0f8bfc3bea83eaa1da7947f/download", "被遗弃脚本02") 
end
})

stgTab:Button({
    Title = "[🔑]叶子", Desc = "好长时间都没有更新了...", Icon = "shell",
    Callback = function() run("https://getnative.cc/script/loader", "死铁轨叶子") end
})

stgTab:Button({
    Title = "ringta[suif汉化]", Desc = "应该是最好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/Ringta%E6%AD%BB%E9%93%81%E8%BD%A8.lua", "死铁轨ringta") end
})

stgTab:Button({
    Title = "Alkaline[suif汉化]", Desc = "对ringta拙劣的模仿 但还是有自己的功能的", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%AD%BB%E9%93%81%E8%BD%A8alkaline", "死铁轨Alkaline") end
})

stgTab:Button({
    Title = "死铁轨刷债券", Desc = "速度也是非常快好吧 蜗牛在修复司马😡😡😡", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/afkar-gg/sc/refs/heads/main/auto-bond", "死铁轨刷债券") end
})

slTab:Button({
    Title = "扫雷", Desc = "支持服务器bLockerman's Minesweeper", Icon = "shell",
    Callback = function() run("https://project-xiaeo.vercel.app/api/v1/luascripts/public/3d7d1c298ca6ff866ccb419f77d6b97d9e22c6be0d239b80d46d753f539d31e8/download", "扫雷") end
})

slTab:Button({
    Title = "扫雷02", Desc = "支持服务器bLockerman's Minesweeper", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/timmytim12354-png/simplescriptz/refs/heads/main/loader.lua?='", "扫雷") end
})

fkgsTab:Button({
    Title = "方块故事[suif汉化]", Desc = "支持方块故事战斗模拟器", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%96%B9%E5%9D%97%E6%95%85%E4%BA%8B%E6%B1%89%E5%8C%96.lua", "方块故事") end
})

--邪恶事情远程
getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.GameTab = xesqTab
getgenv().SutureGameTab = xesqTab
loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%82%AA%E6%81%B6%E4%BA%8B%E6%83%85%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "游戏辅助")

wqkTab:Button({
    Title = "武器库 静默瞄准", Desc = "没有esp 但是有静默瞄准", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/PasteWare.lua", "武器库")
    end
})

getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.wxlgTab = wxlgTab

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
    Title = "fe死亡[suif汉化]", Desc = "他人可见 优质的动作脚本", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/uhhhhhh.lua", "uhhhh")
    end
})

fescriptTab:Button({
    Title = "凋零风暴fe", Desc = "他人不可见 优质的fe脚本 建议在自然灾害执行", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Wither", "凋零风暴")
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
    Title = "[🔑]动物医院 自动类01[suif汉化]", Desc = "有些事件需要手动去完成 另外我用这个只活到15天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/HBtj3VFu", "动物医院")
    end
})

dwyyTab:Button({
    Title = "[🔑]动物医院 自动类02[suif汉化]", Desc = "有些事件需要手动去完成 没测试最高多少天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/pFzZvHum", "动物医院02")
    end
})

dwyyTab:Button({
    Title = "[🔑]动物医院 自动类03[suif汉化]", Desc = "高度自定义 至少ui挺好看 不好用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2%20%E5%8A%9F%E8%83%BD%E4%B8%B0%E5%AF%8F.lua", "动物医院03")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类04[suif汉化]", Desc = "美丽ui 挺好用 就是容易治死人导致游戏结束 等作者优化吧 启动时会有雷霆大叫[调低音量]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2Foxname%5Bsuifhanghang%5D.lua", "动物医院04")
    end
})

pghsTab:Button({
    Title = "排干湖水 自动类01[suif汉化]", Desc = "离售卖机远了没法自动售卖  15分钟左右通关", Icon = "shell",
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
    Title = "最后一封信 自动类01[suif汉化]", Desc = "有些词脚本想不出来 还是人脑牛逼👍🏻👍🏻👍🏻", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%86%99%E4%B8%80%E5%B0%81%E4%BF%A1%5B%E6%B1%89%E5%8C%96%5D.lua", "最后一封信01")
    end
})

sxmsaTab:Button({
    Title = "数学谋杀案 自动类01[suif汉化]", Desc = "这游戏有什么好开的。。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%95%B0%E5%AD%A6%E8%B0%8B%E6%9D%80%E6%A1%88%5B%E6%B1%89%E5%8C%96%5D.lua", "数学谋杀案01")
    end
})

zbjscqtTab:Button({
    Title = "[🔑]在北极生存7天 自动类01[suif汉化]", Desc = "加载时间可能比较长 不好用", Icon = "shell",
    Callback = function()
        local link = "https://wayoutscript.netlify.app/getkey"
        if setclipboard then
            setclipboard(link)
            notify("复制成功", "解卡链接已复制到剪贴板！", "clipboard", 2)
        end
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9C%A8%E5%8C%97%E6%9E%81%E7%94%9F%E5%AD%987%E5%A4%A9.lua", "在北极生存7天01")
    end
})



fescriptTab:Button({
    Title = "r15动作包[suif汉化]", Desc = "他人可见 注意只支持r15 r6用了会直接僵直", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/r15%E5%8A%A8%E4%BD%9C%E5%8C%85fe", "r15动作包")
    end
})

scjsjjcTab:Button({
    Title = "生存僵尸竞技场01[suif汉化]", Desc = "汉化不全 但无关紧要 主要的功能都是汉化过的 感觉还行", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/r15%E5%8A%A8%E4%BD%9C%E5%8C%85fe", "生存僵尸竞技场01")
    end
})

fescriptTab:Button({
    Title = "我的世界fe", Desc = "他人不可见 米米世界牛逼。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Steve", "我的世界fe")
    end
})

tyscriptTab:Button({
    Title = "定位传送", Desc = "借鉴[夜脚本]的闪电尖兵大招", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/Ctx5L33c", "定位传送")
    end
})

fescriptTab:Button({
    Title = "召唤吉吉fe", Desc = "他人不可见 嗯对没有蛋仔。", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/fqm5dDXN", "召唤吉吉fe")
    end
})


gnjbTab:Paragraph({
    Title = "注意",
    Desc = "我只收录我QQ群里看得见的脚本 不论好坏 如果你不想让你的脚本出现在这里 可以点击右上角反馈按钮进行反馈"
})

gnjbTab:Space()

gnjbTab:Button({
    Title = "叶脚本", Desc = "国内老资历 群[336554662]", Icon = "shell",
    Callback = function()
    run("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua", "夜脚本")
    end
})

gnjbTab:Button({
    Title = "夜脚本", Desc = "国内脚本 群[711757444]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/yejiaoben", "夜脚本")
    end
})

gnjbTab:Button({
    Title = "霖溺脚本", Desc = "国内脚本 群[744830231] 需加入roblox指定社区", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ShenJiaoBen/ScriptLoader/refs/heads/main/Linni_FreeLoader.lua", "霖溺")
    end
})

gnjbTab:Button({
    Title = "XA脚本", Desc = "国内脚本 群[1057545155] 可能有时执行不了", Icon = "shell",
    Callback = function()
        run("https://raw.gitcode.com/Xingtaiduan/Scripts/raw/main/Loader.lua", "XA脚本")
    end
})

gnjbTab:Button({
    Title = "黑白脚本", Desc = "国内脚本 群[1062578052]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/tfcygvunbind/Apple/main/%E9%BB%91%E7%99%BD%E8%84%9A%E6%9C%AC%E5%8A%A0%E8%BD%BD%E5%99%A8", "黑白脚本")
    end
})

gnjbTab:Button({
    Title = "kunkun脚本", Desc = "国内脚本 群[1009291930]", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/cfCbSrqr", "kunkun脚本")
    end
})

gnjbTab:Button({
    Title = "TrashHub脚本", Desc = "国内脚本 群[786284990]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/WasKKal/OnlyJumpToOther/main/loader.lua", "TrashHub脚本")
    end
})

gnjbTab:Button({
    Title = "Rb脚本", Desc = "国内脚本 群[1018099361]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/Rb-Hub", "Rb脚本")
    end
})

--范围远程
getgenv().Tabs.RangeTab = FwTab          -- 这里换成你实际创建的 Tab 变量名

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua?t=" .. tostring(tick()), "范围")

--甩飞远程
getgenv().Tabs.FlingTPTab = SfTab
getgenv().WindUI = WindUI

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%94%A9%E9%A3%9E.lua?t=" .. tostring(tick()), "甩飞")

--ping fps显示
getgenv().Tabs.PingFPSTab = pingfpsTab
getgenv().SuturePingFPSTab = pingfpsTab

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%98%BE%E7%A4%BAfps%E5%92%8Cping.lua?t=" .. tostring(tick()), "ping/fps显示")

--雷达
getgenv().Tabs.RadarTab = radarTab
getgenv().SutureRadarTab = radarTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "雷达")

--玩家类远程
getgenv().Tabs.PlayerTab = playerTab
getgenv().SuturePlayerTab = playerTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua?t=" .. tostring(tick()), "玩家类")

--自瞄类远程
getgenv().Tabs.AimbotTab = amTab
getgenv().SutureAimbotTab = amTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua?t=" .. tostring(tick()), "自瞄类")

--发言类远程
getgenv().Tabs.SayTab = sayTab
getgenv().SutureSayTab = sayTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "发言类")

--ESP远程
getgenv().Tabs.ESPTab = espTab
getgenv().SutureESPTab = espTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "ESP")

--服务器类远程
getgenv().Tabs.ServerTab = serverTab
getgenv().SutureServerTab = serverTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "服务器类")

--自然灾害远程
getgenv().Tabs.ZRZHTab = zrzhTab
getgenv().SutureZRZHTab = zrzhTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%84%B6%E7%81%BE%E5%AE%B3%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "自然灾害")



tyscriptTab:Button({
    Title = "绕过群组检测", Desc = "可以绕过部分脚本的群组检测", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/4LzyCSnp", "绕过群组检测")
    end
})

nzyhhyTab:Paragraph({
    Title = "占位符",
    Desc = "占位符"
})

nljjcTab:Button({
    Title = "[🔑]能力竞技场", Desc = "外网很多人在用 就搬过来了 不适合演戏 不适合手机游玩 功能挺多", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%83%BD%E5%8A%9B%E7%AB%9E%E6%8A%80%E5%9C%BA.lua", "能力竞技场")
    end
})

bdh2Tab:Paragraph({
    Title = "注意",
    Desc = "这个神人服务器长期霸占我主页 不找脚本有点过不去了"
})

bdh2Tab:Space()

bdh2Tab:Button({
    Title = "[🔑]冰大亨2[自动化]", Desc = "功能很多 自动化功能全开之后就可以睡觉了😛😛😛", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%86%B0%E5%A4%A7%E4%BA%A82.lua", "冰大亨2")
    end
})

zxdyTab:Button({
    Title = "[🔑]重型钓鱼", Desc = "感觉中规中矩 要是觉得不好用再右上角反馈功能进行反馈", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E9%87%8D%E5%9E%8B%E9%92%93%E9%B1%BC.lua", "重型钓鱼")
    end
})

sqjjcTab:Button({
    Title = "传送击杀", Desc = "大概就是搭配连点器发挥最大功效", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/eweucw5F", "手枪竞技场")
    end
})

hcyghdTab:Paragraph({
    Title = "注意",
    Desc = "因游戏判定有问题 极大可能出现抓错核弹合成不了的情况 建议挂个连点器一直点松手"
})

hcyghdTab:Button({
    Title = "自动类", Desc = "挺好用的 就是飞行和移动类功能不要开 不然容易被ban", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/vNgFeLGR", "合成一个核弹")
    end
})

cclsTab:Button({
    Title = "储存猎手01", Desc = "功能很多 会开可以实现全自动 不会开就是一坨了", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%82%A8%E5%AD%98%E7%8C%8E%E4%BA%BA.lua", "储存猎手01")
    end
})

cclsTab:Button({
    Title = "储存猎手02", Desc = "不如用上面的", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%82%A8%E5%AD%98%E7%8C%8E%E6%89%8B02.lua", "储存猎手02")
    end
})

smnmTab:Paragraph({
    Title = "注意",
    Desc = "还有两个需要卡密的 我看功能差不多就没加 要是觉得这个不好用我再考虑加上"
})

smnmTab:Button({
    Title = "售卖柠檬[自动化]", Desc = "神人小游戏 依旧通货膨胀", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%94%AE%E5%8D%96%E6%9F%A0%E6%AA%AC.lua", "售卖柠檬")
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

WindUI:Notify({
    Title = "Suture Hub",
    Content = "成功加载全部功能！",
    Icon = "aperture",
    Duration = 3
})

WindUI:Notify({
    Title = "小提示",
    Content = "遇到什么问题\n没有自己想玩的服务器\n脚本没法执行\n可以点右上角的反馈按钮进行反馈",
    Icon = "message-square-warning",
    Duration = 10
})

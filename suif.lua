-- 1. 远程加载 WindUI 库
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local plrs = game:GetService("Players")
local lighting = game:GetService("Lighting")
local teleport = game:GetService("TeleportService")
local lp = plrs.LocalPlayer

-- 【视觉体积优化版】全局通知函数：合并内容为单行，让气泡体积缩到最小
local function notify(title, content, icon, duration)
    local shortText = title
    if content and content ~= "" then shortText = title .. " | " .. content end
    WindUI:Notify({ Title = shortText, Duration = duration or 2, Icon = icon or "bell" })
end

local function copy(text, msg)
    if setclipboard then
        setclipboard(text)
        notify("复制成功", msg or "内容已复制", "check", 2)
    else
        warn("复制失败：当前环境不支持 setclipboard")
    end
end

local function run(url, name)
    local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
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

notify("Suture Hub", "正在加载...", "bird", 1.5)

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

win:Tag({ Title = "v1.0.0", Icon = "github", Color = Color3.fromHex("#30ff6a"), Radius = 0 })

local dialog = win:Dialog({
    Icon = "megaphone", Title = "公告", Content = "写什么。。是个问题",
    Buttons = { { Title = "朕已阅", Callback = function() dialog:Close() end } }
})
task.delay(1, function() dialog:Show() end)

-- tabs
local mainTab = win:Tab({ Title = "主页", Icon = "house", Locked = false })
local aboutTab = win:Tab({ Title = "关于", Icon = "info", Locked = false })

-- sections
local funcSec = win:Section({ Title = "功能", Icon = "folder", Opened = false })
local visSec = win:Section({ Title = "视觉", Icon = "folder", Opened = false })
local scriptSec = win:Section({ Title = "脚本", Icon = "folder", Opened = false })
local setSec = win:Section({ Title = "设置", Icon = "settings", Opened = false })

local playerTab = funcSec:Tab({ Title = "玩家", Icon = "user", Locked = false })
local toolTab = funcSec:Tab({ Title = "通用/工具", Icon = "wrench", Locked = false })
local visualTab = visSec:Tab({ Title = "高亮", Icon = "eye", Locked = false })
local settingsTab = setSec:Tab({ Title = "UI设置", Icon = "sliders-horizontal", Locked = false })

local doorsTab = scriptSec:Tab({ Title = "doors/门", Icon = "shell", Locked = false })
local byqTab = scriptSec:Tab({ Title = "被遗弃", Icon = "shell", Locked = false })
local stgTab = scriptSec:Tab({ Title = "死铁轨", Icon = "shell", Locked = false })
local slTab = scriptSec:Tab({ Title = "扫雷", Icon = "shell", Locked = false })
local fkgsTab = scriptSec:Tab({ Title = "方块故事", Icon = "shell", Locked = false })
local zrzhTab = scriptSec:Tab({ Title = "自然灾害", Icon = "shell", Locked = false })
local xesqTab = scriptSec:Tab({ Title = "将会发生些邪恶事情", Icon = "shell", Locked = false })
local wqkTab = scriptSec:Tab({ Title = "武器库", Icon = "shell", Locked = false })

-- 主页
mainTab:Paragraph({ Title = "Suture Hub", Desc = "欢迎使用 Suture Hub\n作者：suif\n当前玩家：" .. lp.Name })
local countText = mainTab:Paragraph({ Title = "全网执行次数", Desc = "正在获取..." })
local function updateCount()
    local ok, res = pcall(function() return game:HttpGet("https://suture-hub-counter.sfbdsl666.workers.dev/count") end)
    if ok then
        res = tostring(res)
        if countText.SetDesc then countText:SetDesc("当前全网执行次数：" .. res) end
        notify("执行统计", "次数：" .. res, "activity", 2)
    else
        if countText.SetDesc then countText:SetDesc("获取失败") end
        warn("全网执行次数获取失败:", res)
    end
end
updateCount()

-- 玩家
playerTab:Slider({
    Title = "移动速度", Desc = "修改 WalkSpeed", Step = 1,
    Value = { Min = 16, Max = 100, Default = 16 },
    Callback = function(v) local h = getHum() if h then h.WalkSpeed = v end end
})
playerTab:Slider({
    Title = "跳跃高度", Desc = "修改 JumpPower", Step = 1,
    Value = { Min = 50, Max = 200, Default = 50 },
    Callback = function(v) local h = getHum() if h then h.UseJumpPower = true h.JumpPower = v end end
})
playerTab:Button({
    Title = "恢复默认属性", Desc = "恢复默认速度和跳跃",
    Callback = function()
        local h = getHum()
        if h then
            h.WalkSpeed = 16
            h.UseJumpPower = true
            h.JumpPower = 50
        end
        notify("恢复成功", "已恢复默认", "check", 2)
    end
})
playerTab:Button({
    Title = "重置角色", Desc = "让自己的角色重生",
    Callback = function() local h = getHum() if h then h.Health = 0 end end
})

-- 视觉
local fb = { Enabled = false, Brightness = 2, ClockTime = 14, FogEnd = 100000, Shadows = false }
local function applyFB()
    lighting.FogStart = 0
    if fb.Enabled then
        lighting.Brightness = fb.Brightness
        lighting.ClockTime = fb.ClockTime
        lighting.FogEnd = fb.FogEnd
        lighting.GlobalShadows = fb.Shadows
    else
        lighting.Brightness = 1
        lighting.ClockTime = 12
        lighting.FogEnd = 100000
        lighting.GlobalShadows = true
    end
end
visualTab:Toggle({
    Title = "高亮环境", Desc = "开启后使用下面的亮度设置", Icon = "sun", Type = "Checkbox", Value = false,
    Callback = function(s) fb.Enabled = s applyFB() end
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
    Title = "删除本地雾气", Desc = "只影响本地画面",
    Callback = function()
        lighting.FogStart = 0
        lighting.FogEnd = 100000
        fb.FogEnd = 100000
        notify("雾气", "已删除本地雾气", "check", 2)
    end
})
visualTab:Button({
    Title = "恢复默认光照", Desc = "关闭高亮并恢复默认光照",
    Callback = function()
        fb.Enabled = false; fb.Brightness = 2; fb.ClockTime = 14; fb.FogEnd = 100000; fb.Shadows = false
        lighting.Brightness = 1; lighting.ClockTime = 12; lighting.FogStart = 0; lighting.FogEnd = 100000; lighting.GlobalShadows = true
        notify("恢复成功", "已恢复光照", "check", 2)
    end
})

-- 工具栏
toolTab:Button({
    Title = "复制玩家信息", Desc = "复制自己的用户名和 UserId",
    Callback = function() copy("Name: " .. lp.Name .. "\nUserId: " .. tostring(lp.UserId), "信息已复制") end
})
toolTab:Button({
    Title = "重新加入服务器", Desc = "重新进入当前服务器",
    Callback = function() teleport:Teleport(game.PlaceId, lp) end
})

-- 【已修改为：精简版可选式开关】
toolTab:Toggle({
    Title = "即时互动", Desc = "开启后所有交互无需按住", Icon = "zap", Value = false,
    Callback = function(s)
        getgenv().InstantInteract = s
        for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.HoldDuration = s and 0 or 0.5 end end
        notify("快速互动", s and "已开启" or "已关闭", "zap", 1.5)
    end
})
if not _G.IntHook then 
    _G.IntHook = workspace.DescendantAdded:Connect(function(v) 
        if getgenv().InstantInteract and v:IsA("ProximityPrompt") then v.HoldDuration = 0 end 
    end) 
end

-- 脚本区域
doorsTab:Button({
    Title = "全自动刷旋钮",
    Desc = "字面意思 执行后什么都不用管了",
    Icon = "shell",
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
        run("https://api.jnkie.com/api/v1/luascripts/public/5d2e14fd21f767f03b28cfb5537f6260a6f45279ddeb806fd04e706153ed0ce0/download", "Doors 脚本")
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
            notify("mspaint", "已自动复制解卡链接", "check", 2)
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
            notify("缺少参数", "请先填写账号名", "triangle-alert", 2)
            return
        end
        local scriptText = 'MainAccount = ' .. luaStr(reviveCfg.MainAccount) .. ' -- 主号用户名\nAltAccount = ' .. luaStr(reviveCfg.AltAccount) .. ' -- 小号用户名\n\nDuplicationAmount = ' .. tostring(reviveCfg.DuplicationAmount) .. '\nloadstring(game:HttpGet("https://raw.githubusercontent.com/notpoiu/Scripts/refs/heads/main/doors/revives.lua"))()'
        if setclipboard then
            setclipboard(scriptText)
            notify("复制成功", "脚本已复制到剪贴板", "check", 2)
        else
            warn("复制失败：环境不支持，已输出至控制台")
            print(scriptText)
        end
    end
})

byqTab:Button({
    Title = "fa", Desc = "无卡密 个人感觉很好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/ivannetta/ShitScripts/main/forsaken.lua", "被遗弃脚本") end
})

stgTab:Button({
    Title = "叶子", Desc = "需卡密 好长时间都没有更新了...", Icon = "shell",
    Callback = function() run("https://getnative.cc/script/loader", "死铁轨叶子") end
})

stgTab:Button({
    Title = "ringta", Desc = "无卡密 老朋友了 更新速度还算可以", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/erewe23/deadrailsring.github.io/refs/heads/main/ringta.lua", "死铁轨ringta") end
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
    Title = "方块故事", Desc = "无卡密 超好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/TexRBLX/Roblox-stuff/refs/heads/main/block%20tales/revamp.lua", "方块故事") end
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
        getgenv().bypass_adonis = true
        run("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/PasteWare.lua", "武器库")
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
        notify("主题切换", "当前：" .. name, "palette", 2)
    end
})

-- 关于
aboutTab:Button({
    Title = "复制作者B站链接", Desc = "",
    Callback = function() copy("https://space.bilibili.com/3493268314655259", "链接已复制") end
})

notify("Suture Hub", "成功加载全部功能！", "bird", 3)
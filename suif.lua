local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local function Notify(title, content, icon, duration)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Icon = icon or "bell",
    })
end

local function CopyText(text, successMsg)
    if setclipboard then
        setclipboard(text)
        Notify("复制成功", successMsg or "内容已复制到剪贴板", "check", 3)
    else
        Notify("复制失败", "当前环境不支持 setclipboard", "triangle-alert", 3)
    end
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

Notify("Suture Hub", "Suture Hub 正在加载...", "bird", 5)

local UISettings = {
    Theme = "Dark",
    Transparent = true,
    HideSearchBar = false,
    SideBarWidth = 180,
}

local Window = WindUI:CreateWindow({
    Title = "Suture Hub",
    Icon = "aperture",
    Author = "by suif",
    Folder = "SutureHub",

    Size = UDim2.fromOffset(620, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(900, 600),

    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = UISettings.Transparent,
    Theme = UISettings.Theme,
    Resizable = true,
    SideBarWidth = UISettings.SideBarWidth,
    HideSearchBar = UISettings.HideSearchBar,
    ScrollBarEnabled = true,

    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("当前用户:", LocalPlayer.Name)
        end,
    },
})

--// Tabs

local MainTab = Window:Tab({
    Title = "主页",
    Icon = "house",
    Locked = false,
})

local FunctionSection = Window:Section({
    Title = "功能",
    Icon = "folder",
    Opened = false,
})

local PlayerTab = FunctionSection:Tab({
    Title = "玩家",
    Icon = "user",
    Locked = false,
})

local ToolTab = FunctionSection:Tab({
    Title = "工具",
    Icon = "wrench",
    Locked = false,
})

local VisualSection = Window:Section({
    Title = "视觉",
    Icon = "folder",
    Opened = false,
})

local VisualTab = VisualSection:Tab({
    Title = "高亮",
    Icon = "eye",
    Locked = false,
})

local scriptSection = Window:Section({
    Title = "脚本",
    Icon = "folder",
    Opened = false,
})

local scripttab = scriptSection:Tab({
    Title = "doors/门",
    Icon = "door-closed",
    Locked = false,
})

local SettingsSection = Window:Section({
    Title = "设置",
    Icon = "settings",
    Opened = false,
})

local SettingsTab = SettingsSection:Tab({
    Title = "UI设置",
    Icon = "sliders-horizontal",
    Locked = false,
})

local AboutTab = SettingsSection:Tab({
    Title = "关于",
    Icon = "info",
    Locked = false,
})

--// 主页

MainTab:Paragraph({
    Title = "Suture Hub",
    Desc = "欢迎使用 Suture Hub\n作者：suif\n当前玩家：" .. LocalPlayer.Name
})

--// 玩家

PlayerTab:Slider({
    Title = "移动速度",
    Desc = "修改 WalkSpeed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 100,
        Default = 16,
    },
    Callback = function(value)
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = value
        end
    end
})

PlayerTab:Slider({
    Title = "跳跃高度",
    Desc = "修改 JumpPower",
    Step = 1,
    Value = {
        Min = 50,
        Max = 200,
        Default = 50,
    },
    Callback = function(value)
        local hum = GetHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = value
        end
    end
})

PlayerTab:Button({
    Title = "恢复默认属性",
    Desc = "恢复默认速度和跳跃",
    Locked = false,
    Callback = function()
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.UseJumpPower = true
            hum.JumpPower = 50
            Notify("恢复成功", "已恢复默认属性", "check", 3)
        end
    end
})

PlayerTab:Button({
    Title = "重置角色",
    Desc = "让自己的角色重生",
    Locked = false,
    Callback = function()
        local hum = GetHumanoid()
        if hum then
            hum.Health = 0
        end
    end
})

--// 视觉 / 高亮

local FullbrightSettings = {
    Enabled = false,
    Brightness = 2,
    ClockTime = 14,
    FogEnd = 100000,
    Shadows = false,
}

local function ApplyFullbright()
    Lighting.FogStart = 0

    if FullbrightSettings.Enabled then
        Lighting.Brightness = FullbrightSettings.Brightness
        Lighting.ClockTime = FullbrightSettings.ClockTime
        Lighting.FogEnd = FullbrightSettings.FogEnd
        Lighting.GlobalShadows = FullbrightSettings.Shadows
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end

VisualTab:Toggle({
    Title = "高亮环境",
    Desc = "开启后使用下面的亮度设置",
    Icon = "sun",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        FullbrightSettings.Enabled = state
        ApplyFullbright()
        Notify("高亮环境", state and "已开启" or "已关闭", "sun", 3)
    end
})

VisualTab:Slider({
    Title = "亮度大小",
    Desc = "控制 Lighting.Brightness",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 10,
        Default = FullbrightSettings.Brightness,
    },
    Callback = function(value)
        FullbrightSettings.Brightness = value
        ApplyFullbright()
    end
})

VisualTab:Slider({
    Title = "世界时间",
    Desc = "控制 ClockTime",
    Step = 0.5,
    Value = {
        Min = 0,
        Max = 24,
        Default = FullbrightSettings.ClockTime,
    },
    Callback = function(value)
        FullbrightSettings.ClockTime = value
        ApplyFullbright()
    end
})

VisualTab:Slider({
    Title = "雾气距离",
    Desc = "数值越高，雾气越少",
    Step = 1000,
    Value = {
        Min = 100,
        Max = 100000,
        Default = FullbrightSettings.FogEnd,
    },
    Callback = function(value)
        FullbrightSettings.FogEnd = value
        ApplyFullbright()
    end
})

VisualTab:Toggle({
    Title = "保留阴影",
    Desc = "关闭后画面会更亮",
    Icon = "cloud-sun",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        FullbrightSettings.Shadows = state
        ApplyFullbright()
    end
})

VisualTab:Button({
    Title = "删除本地雾气",
    Desc = "只影响本地画面",
    Locked = false,
    Callback = function()
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        FullbrightSettings.FogEnd = 100000
        Notify("雾气", "已删除本地雾气", "check", 3)
    end
})

VisualTab:Button({
    Title = "恢复默认光照",
    Desc = "关闭高亮并恢复默认光照",
    Locked = false,
    Callback = function()
        FullbrightSettings.Enabled = false
        FullbrightSettings.Brightness = 2
        FullbrightSettings.ClockTime = 14
        FullbrightSettings.FogEnd = 100000
        FullbrightSettings.Shadows = false

        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true

        Notify("恢复成功", "已关闭高亮并恢复默认光照", "check", 3)
    end
})

--// 工具

ToolTab:Button({
    Title = "复制玩家信息",
    Desc = "复制自己的用户名和 UserId",
    Locked = false,
    Callback = function()
        CopyText(
            "Name: " .. LocalPlayer.Name .. "\nUserId: " .. tostring(LocalPlayer.UserId),
            "玩家信息已复制"
        )
    end
})

ToolTab:Button({
    Title = "重新加入服务器",
    Desc = "重新进入当前服务器",
    Locked = false,
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})
--// 脚本类

scripttab:Button({
    Title = "刷旋钮",
    Desc = "大厅执行就行",
    Icon = "chart-line",
    Locked = false,
    Callback = function()
        RunScript("getgenv().Config = {
    MinContainers = 10,
    MinCoins = 50,
    UseLockpick = false,
    UseRobuxKnobsBoost = false
}
loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/6e87698669de88a8f81d6348ce368b73.lua"))()", "脚本 1")
    end
})

--// UI 设置

local ThemeMap = {
    ["深色"] = "Dark",
    ["浅色"] = "Light",
    ["玫瑰"] = "Rose",
    ["植物"] = "Plant",
    ["红色"] = "Red",
    ["靛蓝"] = "Indigo",
    ["天空蓝"] = "Sky",
    ["紫罗兰"] = "Violet",
    ["琥珀"] = "Amber",
}

SettingsTab:Dropdown({
    Title = "UI 主题",
    Desc = "切换 UI 主题",
    Values = {
        "深色",
        "浅色",
        "玫瑰",
        "植物",
        "红色",
        "靛蓝",
        "天空蓝",
        "紫罗兰",
        "琥珀"
    },
    Value = "深色",
    Callback = function(themeName)
        local realTheme = ThemeMap[themeName]
        UISettings.Theme = realTheme

        if WindUI.SetTheme then
            WindUI:SetTheme(realTheme)
        elseif Window.SetTheme then
            Window:SetTheme(realTheme)
        else
            warn("当前 WindUI 版本可能不支持运行时切换主题")
        end

        Notify("主题切换", "当前主题：" .. themeName, "palette", 3)
    end
})

--// 关于

AboutTab:Button({
    Title = "复制作者B站链接",
    Desc = "",
    Locked = false,
    Callback = function()
        CopyText(
            "https://space.bilibili.com/3493268314655259",
            "作者 B 站链接已复制"
        )
    end
})

Notify("Suture Hub", "Suture Hub 加载成功！", "bird", 5)

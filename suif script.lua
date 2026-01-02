local TextChatService = game:GetService("TextChatService") local ReplicatedStorage = game:GetService("ReplicatedStorage") local function SendChatMessage(message) if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then local textChannel = TextChatService.TextChannels.RBXGeneral textChannel:SendAsync(message) else ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All") end end SendChatMessage("欢迎使用") SendChatMessage("祝您玩的开心")
local LP = game:GetService("Players").LocalPlayer
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local customNotificationGui = Instance.new("ScreenGui")
customNotificationGui.Name = "CustomNotificationGui"
customNotificationGui.Parent = playerGui

local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 300, 0, 100)
notificationFrame.Position = UDim2.new(1, 0, 1, -110) 
notificationFrame.BackgroundColor3 = Color3.new(0, 0, 0) 
notificationFrame.BackgroundTransparency = 0.2 
notificationFrame.BorderSizePixel = 0 
notificationFrame.Parent = customNotificationGui

local loadingRing = Instance.new("ImageLabel")
loadingRing.Size = UDim2.new(1.2, 0, 1.2, 0) 
loadingRing.Position = UDim2.new(-0.1, 0, -0.1, 0) 
loadingRing.BackgroundTransparency = 1 
loadingRing.Image = "rbxassetid://1011584077" 
loadingRing.ImageColor3 = Color3.new(1, 1, 1) 
loadingRing.Parent = notificationFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1 
titleLabel.TextColor3 = Color3.new(1, 1, 1) 
titleLabel.Text = "suif脚本" 
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.Parent = notificationFrame

local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(1, -20, 0, 40)
contentLabel.Position = UDim2.new(0, 10, 0, 45)
contentLabel.BackgroundTransparency = 1
contentLabel.TextColor3 = Color3.new(1, 1, 1)
contentLabel.Text = "suif脚本加载完成" 
contentLabel.Font = Enum.Font.SourceSans
contentLabel.TextSize = 16
contentLabel.Parent = notificationFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -30, 0, 10)
closeButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
closeButton.Text = "❤️"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Parent = notificationFrame

closeButton.MouseButton1Click:Connect(function()
    customNotificationGui:Destroy()
end)

local rotateTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local rotateTween = TweenService:Create(loadingRing, rotateTweenInfo, {Rotation = 360})
rotateTween:Play()

local targetPosition = UDim2.new(1, -310, 1, -110)
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tween = TweenService:Create(notificationFrame, tweenInfo, {Position = targetPosition})
tween:Play()

wait(5)
customNotificationGui:Destroy()

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/bailib/Roblox/refs/heads/main/main/ESP.lua"))()
ESP.AddFolder("HiderESPFolder")
ESP.AddFolder("HunterESPFolder")
ESP.AddFolder("GlassESPFolder")

local WindUISuccess, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not WindUISuccess then
    error("❌ WindUI加载失败: "..tostring(WindUI))
    return
end

function gradient(text, startColor, endColor)
    if not text or #text == 0 then return "" end
    if not startColor or not endColor then
        warn("⚠️ 颜色参数无效，使用默认颜色")
        startColor = Color3.fromRGB(255,255,255)
        endColor = Color3.fromRGB(200,200,200)
    end

    local result = ""
    local length = #text

    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)

        local char = text:sub(i, i)
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, char)
    end

    return result
end

local Confirmed = false
local popupSuccess, popupResult = pcall(function()
    WindUI:Popup({
        Title = "欢迎使用suif脚本",
        Icon = "bird",
        Content = "emm"..gradient("suif", Color3.fromHex("#00FF87"), Color3.fromHex("#60EFFF")).."Speak To Me",
        Buttons = {
            {
                Title = "取消",
                Callback = function() end,
                Variant = "Secondary"
            },
            {
                Title = "继续",
                Icon = "arrow-right",
                Callback = function() Confirmed = true end,
                Variant = "Primary"
            }
        }
    })
end)

if not popupSuccess then
    warn("⚠️ 弹窗创建失败: "..tostring(popupResult))
    Confirmed = true
end

repeat task.wait() until Confirmed

local Window
local windowSuccess, windowResult = pcall(function()
    return WindUI:CreateWindow({
        Title = "suif脚本V1.0",
        Icon = "bird",
        Author = "只是一个臭二改罢了",
        Folder = "ColdSilence",
        Size = UDim2.fromOffset(300, 350),
        Theme = "Dark",
        User = {
            Enabled = true,
            Callback = function() print("用户按钮点击") end,
            Anonymous = false
        },
        KeySystem = {
            Key = { "suif", "月之暗面" },
            Note = "请输入有效密钥\n\n密钥[suif][月之暗面]",
            SaveKey = false
        }
    })
end)

if not windowSuccess then
    error("❌ 窗口创建失败: "..tostring(windowResult))
    return
else
    Window = windowResult
end

local function safeCreateButton(name, icon, callback, order)
    pcall(function()
        Window:CreateTopbarButton(name, icon, callback, order)
    end)
end

safeCreateButton("MyButton1", "bird", function() print("按钮1") end, 990)
safeCreateButton("MyButton2", "settings", function() Window:ToggleFullscreen() end, 989)

task.defer(function()
    collectgarbage("")
    print("✅ 内存优化完成 | 当前用量:", math.floor((collectgarbage("count")/1024)).."MB")
end)

print("🎉 Kenny脚本加载完成!")

local Tabs = {}
--主菜单
do
    Tabs.MainTab = Window:Section({Title = "通用脚本", Opened = true})   
   Tabs.HDTab = Tabs.MainTab:Tab({ Title = "黑洞大全", Icon = "zap" })
   Tabs.KFTab = Tabs.MainTab:Tab({ Title = "开发工具", Icon = "zap" })  
   Tabs.SFTab = Tabs.MainTab:Tab({ Title = "甩飞类", Icon = "zap" })
   Tabs.DZTab = Tabs.MainTab:Tab({ Title = "表情和动作类", Icon = "zap" })
   Tabs.TYGNTab = Tabs.MainTab:Tab({ Title = "通用", Icon = "zap" })
   Tabs.WJTab = Tabs.MainTab:Tab({ Title = "玩家类", Icon = "zap" })
end

do
    Tabs.LOLTab = Window:Section({Title = "服务器脚本", Opened = true})
Tabs.TGTab = Tabs.LOLTab:Tab({ Title = "死铁轨", Icon = "zap" })
Tabs.FKTab = Tabs.LOLTab:Tab({ Title = "方块故事", Icon = "zap" })
end

Tabs.WJTab:Button({
    Title = "实时数据",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/kenk/refs/heads/main/%E7%8E%A9%E5%AE%B6%E5%AE%9E%E6%97%B6%E6%95%B0%E6%8D%AE.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "阿尔宙斯飞行",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/kenk/refs/heads/main/%E9%98%BF%E5%B0%94%E5%AE%99%E6%96%AF%E9%A3%9E%E8%A1%8C.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "人物旋转",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/kenk/refs/heads/main/%E4%BA%BA%E7%89%A9%E6%97%8B%E8%BD%AC.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "反重力",
    Desc = "反重力",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/96XzjEiK"))()
    end
})

Tabs.WJTab:Button({
    Title = "跳墙",
    Desc = "跳墙",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ScpGuest666/Random-Roblox-script/refs/heads/main/Roblox%20WallHop%20V4%20script"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "坐标仪2",
    Desc = "第二种",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E4%BD%8D%E7%BD%AE%E4%BB%AA.txt"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "坐标仪1",
    Desc = "第一种",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%9D%90%E6%A0%87%E4%BB%AA.txt"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "本地音乐播放器2",
    Desc = "输入音乐ID使用",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E6%9C%AC%E5%9C%B0%E9%9F%B3%E4%B9%90%E6%92%AD%E6%94%BE%E5%99%A8.txt"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "iy指令",
    Desc = "iy",
    Callback = function()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
    end
})

Tabs.TYGNTab:Button({
    Title = "本地音乐播放器",
    Desc = "可以自定义音乐教程看我视频",
    Callback = function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/refs/heads/main/ScriptAuthorization%20Source'))()Ioad('7208e39603889391caf77f6ff7d21e01')
    end
})

Tabs.TYGNTab:Button({
    Title = "我的世界",
    Desc = "真的能玩但别人看不见",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Biem6ondo/mc/refs/heads/main/STARTUP"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "假朋友",
    Desc = "生成一个人机陪你",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmaboy123z/MYFRIENDSCRIPT/refs/heads/main/MYNEWFRIENDSPAWNER"))();
    end
})

Tabs.TYGNTab:Button({
    Title = "忍者同款键盘",
    Desc = "键盘",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E9%94%AE%E7%9B%98.txt"))()
    end
})

Tabs.TYGNTab:Button({
    Title = "时间",
    Desc = "实时显示北京时间",
    Callback = function()
local LBLG = Instance.new("ScreenGui", getParent)
local LBL = Instance.new("TextLabel", getParent)
local player = game.Players.LocalPlayer

LBLG.Name = "LBLG"
LBLG.Parent = game.CoreGui
LBLG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LBLG.Enabled = true
LBL.Name = "LBL"
LBL.Parent = LBLG
LBL.BackgroundColor3 = Color3.new(0, 3, 1)
LBL.BackgroundTransparency = 1
LBL.BorderColor3 = Color3.new(0, 3, 1)
LBL.Position = UDim2.new(0.75,0,0.010,0)
LBL.Size = UDim2.new(0, 133, 0, 30)
LBL.Font = Enum.Font.GothamSemibold
LBL.Text = "TextLabel"
LBL.TextColor3 = Color3.new(0, 3, 3)
LBL.TextScaled = true
LBL.TextSize = 14
LBL.TextWrapped = true
LBL.Visible = true

local FpsLabel = LBL
local Heartbeat = game:GetService("RunService").Heartbeat
local LastIteration, Start
local FrameUpdateTable = { }

local function HeartbeatUpdate()
  LastIteration = tick()
  for Index = #FrameUpdateTable, 1, -1 do
    FrameUpdateTable[Index + 1] = (FrameUpdateTable[Index] >= LastIteration - 1) and FrameUpdateTable[Index] or nil
  end
  FrameUpdateTable[1] = LastIteration
  local CurrentFPS = (tick() - Start >= 1 and #FrameUpdateTable) or (#FrameUpdateTable / (tick() - Start))
  CurrentFPS = CurrentFPS - CurrentFPS % 1
  FpsLabel.Text = ("当前时间:"..os.date("%H").."时"..os.date("%M").."分"..os.date("%S"))
end
Start = tick()
Heartbeat:Connect(HeartbeatUpdate)
      end
})

Tabs.PVPTab:Button({
    Title = "透视可开关",
    Desc = "透视",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZIONPCE/raw/refs/heads/main/ESP.lua"))()
    end
})

Tabs.PVPTab:Button({
    Title = "第一人称自瞄",
    Desc = "只能在第一人称射击游戏用",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Roblox-HttpSpy/Random-Silly-stuff/refs/heads/main/AimBotV2.lua"))()
    end
})

Tabs.PVPTab:Button({
    Title = "自瞄",
    Desc = "自瞄",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E4%B8%81%E4%B8%81%20%E6%B1%89%E5%8C%96%E8%87%AA%E7%9E%84.txt"))()
    end
})

Tabs.PVPTab:Button({
    Title = "超大范围",
    Desc = "可能不是所有服务器通用",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/KKY9EpZU"))()
    end
})

Tabs.PVPTab:Button({
    Title = "大范围",
    Desc = "可能不是所有服务器通用",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/x13bwrFb"))()
    end
})

Tabs.PVPTab:Button({
    Title = "小小范围",
    Desc = "可能不是所有服务器通用",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/yP09ddbu"))()
    end
})

Tabs.PVPTab:Button({
    Title = "小范围",
    Desc = "可能不是所有服务器通用",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/jiNwDbCN"))()
    end
})

Tabs.PVPTab:Button({
    Title = "中等范围",
    Desc = "可能不是所有服务器通用",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/FAY1au9v"))()
    end
})

Tabs.PVPTab:Button({
    Title = "vapev4",
    Desc = "超级强PVP脚本已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E6%B1%89%E5%8C%96vapev4.txt"))()
    end
})

Tabs.SFTab:Button({
    Title = "可选人甩飞",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://pastefy.app/A8Kfs9KV/raw", true))()
    end
})

Tabs.SFTab:Button({
    Title = "防甩飞",
    Desc = "谁知道有没有用",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ChinaQY/Scripts/Main/AntiFling.lua"))()
    end
})

Tabs.SFTab:Button({
    Title = "一键甩飞所有人",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))()
    end
})

Tabs.SFTab:Button({
    Title = "甩飞中心",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/OP-FLING-GUI/c1fd15bf3114e6c9e4b76951b7d516c123836efe/OP%20FLING%20GUI%20R6%20AND%20R15"))()
    end
})

Tabs.SFTab:Button({
    Title = "Kenny甩飞",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/DHJB%E7%94%A9%E9%A3%9E.txt"))()
    end
})

Tabs.SFTab:Button({
    Title = "触摸甩飞",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/LiarRise/FLN-X/refs/heads/main/README.md"))()
    end
})

Tabs.SFTab:Button({
    Title = "铁拳",
    Desc = "汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E6%B1%89%E5%8C%96%E9%93%81%E6%8B%B3.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "获取工具",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/BTools.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "蜘蛛侠",
    Desc = "四百大妈",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E8%9C%98%E8%9B%9B%E4%BE%A0.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "闪回",
    Desc = "闪回",
    Callback = function()
loadstring(game:HttpGet("https://mscripts.vercel.app/scfiles/reverse-script.lua"))()
    end
})

Tabs.WJTab:Input({
    Title = "重力设置",
    Value = "",
    Placeholder = "修改重力",
    Callback = function(input)
        game.Workspace.Gravity = tonumber(input) or game.Workspace.Gravity
    end
})

Tabs.WJTab:Button({
    Title = "爬墙",
    Desc = "爬墙",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/zXk4Rq2r"))() 
    end
})

Tabs.WJTab:Button({
    Title = "踏空",
    Desc = "踏空",
    Callback = function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float'))()
    end
})

Tabs.WJTab:Button({
    Title = "R15变R6",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/R15toR6"))()
    end
})

Tabs.WJTab:Button({
    Title = "飞车",
    Desc = "飞车",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E9%A3%9E%E8%BD%A6.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "反挂机",
    Desc = "反挂机",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/9fFu43FF"))()
    end
})

Tabs.WJTab:Toggle({
    Title = "夜视",
    Desc = "夜视功能",
    Default = false,
    Callback = function(value)
        if value then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
        else
            game.Lighting.Ambient = Color3.new(0, 0, 0)
        end
    end
})

Tabs.WJTab:Button({
    Title = "物理枪",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/FEwuliqiang"))()
    end
})

Tabs.WJTab:Button({
    Title = "查看别人物品栏",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E7%9C%8B%E7%89%A9%E5%93%81%E6%A0%8F.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "实时数据",
    Desc = "玩家实时数据",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%AE%9E%E6%97%B6%E6%95%B0%E6%8D%AE.txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "聊天查找器",
    Desc = "可以查找他人聊天记录",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/v-oidd/chat-tracker/main/chat-tracker.lua"))()
    end
})

Tabs.WJTab:Button({
    Title = "秘密聊天",
    Desc = "只有同样使用这个脚本的人可以看见",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/MtgpaZaf"))()
    end
})

Tabs.WJTab:Button({
    Title = "秒互动",
    Desc = "一秒互动",
    Callback = function()
game.ProximityPromptService.PromptButtonHoldBegan:Connect(function(v)
    v.HoldDuration = 0
end)
    end
})

Tabs.WJTab:Toggle({
    Title = "连跳",
    Value = false,
    Callback = function(value)
       Jump = value
        game.UserInputService.JumpRequest:Connect(function()
            if Jump then
                game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
            end
        end)
    end
})

Tabs.WJTab:Button({
    Title = "飞行",
    Desc = "飞行",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E9%A3%9E%E8%A1%8C%E8%84%9A%E6%9C%ACV3(%E5%85%A8%E6%B8%B8%E6%88%8F%E9%80%9A%E7%94%A8)%20(1)%20(1).txt"))()
    end
})

Tabs.WJTab:Button({
    Title = "刷屏机器",
    Desc = "一键自定义发言",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%88%B7%E5%B1%8F.txt"))()
    end
})

Tabs.WJTab:Toggle({
    Title = "穿墙",
    Value = false,
    Callback = function(value)
        WallTp = value
        if value then
            game:GetService("RunService").Stepped:Connect(function()
                if WallTp and game.Players.LocalPlayer.Character then
                    local Character = game.Players.LocalPlayer.Character
                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid then
                        for _, part in ipairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        else
            if game.Players.LocalPlayer.Character then
                for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

Tabs.WJTab:Button({
    Title = "点击传送工具",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Teleport-Tool-25249"))()     
    end
})

Tabs.WJTab:Slider({
    Title = "跳跃高度",
    Value = {
        Min = 1,
        Max = 9999,
        Default = 50,
    },
    Callback = function(value)
        local localPlayer = game.Players.LocalPlayer
        local character = localPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    end
})

Tabs.WJTab:Slider({
    Title = "跑步速度",
    Value = {
        Min = 1,
        Max = 99999,
        Default = 50,
    },
    Callback = function(value)
        local localPlayer = game.Players.LocalPlayer
        local character = localPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end
})

Tabs.WJTab:Button({
    Title = "假管理",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/sZpgTVas"))()
    end
})

Tabs.WJTab:Button({
    Title = "控制玩家",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/wanjiakongzhi"))()
    end
})

Tabs.WJTab:Button({
    Title = "R6假无头",
    Desc = "R6假无头",
    Callback = function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Gazer-Ha/Valiant-Ui-Lib-Gazed-/refs/heads/main/Head%20Pack'))()
    end
})

Tabs.WJTab:Button({
    Title = "失重",
    Desc = "失重",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Rawbr10/Roblox-Scripts/refs/heads/main/0%20Graviy%20Trip%20Universal"))()
    end
})

Tabs.WJTab:Button({
    Title = "偷别人物品",
    Desc = "一键获得所有人的物品",
    Callback = function()
for i,v in pairs (game.Players:GetChildren()) do
wait()
for i,b in pairs (v.Backpack:GetChildren()) do
b.Parent = game.Players.LocalPlayer.Backpack
end
end
    end
})

Tabs.WJTab:Button({
    Title = "隐身2",
    Desc = "通用",
    Callback = function()
loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()  
    end
})

Tabs.WJTab:Button({
    Title = "隐身",
    Desc = "这个自带加速",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/vP6CrQJj"))()        
    end
})

Tabs.WJTab:Button({
    Title = "火车头",
    Desc = "越跑越快",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E8%B6%8A%E8%B7%91%E8%B6%8A%E5%BF%AB.txt"))();
    end
})

Tabs.DZTab:Button({
    Title = "自定义角色动画",
    Desc = "可调节",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E8%87%AA%E5%AE%9A%E4%B9%89%E5%8A%A8%E7%94%BB.txt"))()
    end
})

Tabs.DZTab:Button({
    Title = "变成球",
    Desc = "滚动",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/KaterHub-Inc/scripts/refs/heads/main/unofficial-Projects/FEHamsterBall.lua"))()
    end
})

Tabs.DZTab:Button({
    Title = "爬行",
    Desc = "爬行",
    Callback = function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/0Ben1/fe/main/obf_vZDX8j5ggfAf58QhdJ59BVEmF6nmZgq4Mcjt2l8wn16CiStIW2P6EkNc605qv9K4.lua.txt'))()
    end
})

Tabs.DZTab:Button({
    Title = "VR手",
    Desc = "VR",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty45.lua"))()
    end
})

Tabs.DZTab:Button({
    Title = "在别人身上转",
    Desc = "旋转",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ShutUpJamesTheLoserAlt/hatspin/refs/heads/main/hat"))()        
    end
})

Tabs.DZTab:Button({
    Title = "青蛙走路特效",
    Desc = "仅自己可见",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/vhis9HZy"))()
    end
})

Tabs.DZTab:Button({
    Title = "遁地",
    Desc = "别人可见",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/0Ben1/fe/main/obf_rTvXTs8F16D8D2oiLxZ62E1E9jT1we312yUyJr2h72Vwqr32l37rirU1S89hqRV7.lua.txt"))()
    end
})

Tabs.DZTab:Button({
    Title = "镰刀死神可传送踏空",
    Desc = "只有自己能看到死神和镰刀特效",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/srzmnx/OLD-roblox-scripts/refs/heads/master/Scythe.txt"))()
    end
})

Tabs.DZTab:Button({
    Title = "开车",
    Desc = "开车",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/AstraOutlight/my-scripts/refs/heads/main/fe%20car%20v3"))()
    end
})

Tabs.DZTab:Button({
    Title = "头部宠物",
    Desc = "把自己变成别人宠物",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty40.lua"))()
    end
})

Tabs.DZTab:Button({
    Title = "超慢跑跳",
    Desc = "超慢跑跳",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Fake-lag-41217"))()
    end
})

Tabs.DZTab:Button({
    Title = "ucg表情",
    Desc = "ucg表情",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/1nJD7PkH",true))()       
    end
})

Tabs.DZTab:Button({
    Title = "r6动作",
    Desc = "很多很多别人可见",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-R6-Animations-Menu-By-Me-19427"))()
    end
})

Tabs.DZTab:Button({
    Title = "拥抱",
    Desc = "r6可用",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ExploitFin/Animations/refs/heads/main/Front%20and%20Back%20Hug%20Tool"))()       
    end
})

Tabs.DZTab:Button({
    Title = "r15无敌少侠飞行",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://github.com/Sinister-Scripts/Roblox-Exploits/raw/refs/heads/main/FE-Animated-Mobile-Fly"))()        
    end
})

Tabs.DZTab:Button({
    Title = "r15无敌少侠飞行2",
    Desc = "这个动作好一点",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Invinicible-Flight-R15-45414"))()     
    end
})

Tabs.DZTab:Button({
    Title = "r6无敌少侠飞行",
    Desc = "这个手机端需要配专属移动按键",
    Callback = function()
loadstring(game:HttpGet("https://gist.githubusercontent.com/JungleScripts/775c6366d91d39fe2633c5805a1d0c23/raw/c8de949402393510a27bcf4482c957b6c3bed2c2/gistfile1.txt"))()    
    end
})

Tabs.DZTab:Button({
    Title = "r6无敌少侠飞行专属按键",
    Desc = "移动端用这个来飞行",
    Callback = function()
loadstring(game:HttpGet("https://gist.githubusercontent.com/JungleScripts/8dc95c7ce10e86d353d606334a77de88/raw/08f3e2967701463da36f2fc28e9943e63799dd3f/gistfile1.txt"))() 
    end
})

Tabs.DZTab:Button({
    Title = "r6无敌少侠飞行2",
    Desc = "移动端用专属按键来飞",
    Callback = function()
loadstring(game:HttpGet('https://raw.githubusercontent.com/396abc/Script/refs/heads/main/Fly.lua'))()
    end
})

Tabs.DZTab:Button({
    Title = "r6无敌少侠飞行3",
    Desc = "可以直接用移动键来飞",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E6%97%A0%E6%95%8C%E5%B0%91%E4%BE%A0%E9%A3%9E%E8%A1%8Cr6.txt"))()
    end
})

Tabs.DZTab:Button({
    Title = "动画和表情",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-AFEM-14048"))()       
    end
})

Tabs.DZTab:Button({
    Title = "舞蹈",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Gazer-Ha/Free-emote/refs/heads/main/Delta%20mad%20stuffs"))()       
    end
})

Tabs.DZTab:Button({
    Title = "R6动作",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-R6-Animations-Menu-By-Me-19427"))()       
    end
})

Tabs.DZTab:Button({
    Title = "R15动作",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Boxten-Keyes/music/refs/heads/main/music%23%5Bscripts%5D/music%23%5Bmiscellaneous%5D/music%23%5Bfe%20r15%20animation%20player%5D.lua"))()        
    end
})

Tabs.DZTab:Button({
    Title = "900个动作",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Rootleak/roblox/refs/heads/main/main.lua"))()        
    end
})

Tabs.DZTab:Button({
    Title = "车动作",
    Desc = "FE",
    Callback = function()
loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-FE-SILLY-CAR-V1-48227"))()        
    end
})

Tabs.HDTab:Button({
    Title = "黑洞中心同款v3",
    Desc = "感谢黑洞中心。",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/1379qpalzmtygvezimaliexcvbnqplasdfg/11284/refs/heads/main/Protected_6980301799988851.lua.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "简陋黑洞",
    Desc = "我鸡吧好痒",
    Callback = function()
loadstring(game:HttpGet("https://codeberg.org/ajduoxcz/BS/raw/branch/main/199/%E4%BA%91Ul.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "终极黑洞",
    Desc = "感谢黑洞中心。",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/1379qpalzmtygvezimaliexcvbnqplasdfg/11284/refs/heads/main/Protected_2793948043438411.lua.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "直接吸",
    Desc = "黑洞",
    Callback = function()
loadstring(game:HttpGet("https://codeberg.org/ajduoxcz/BS/raw/branch/main/1234578/%E4%BA%91Ul.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "黑洞V1",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/V1.lua.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "黑洞V3",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/V3.txt"))()
    end
})

Tabs.KFTab:Button({
    Title = "动画spy",
    Desc = "获取角色动画",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%8A%A8%E7%94%BBSpy.lua.txt"))()
    end
})

Tabs.KFTab:Button({
    Title = "音频spy",
    Desc = "获取服务器音频链接",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/Alrthisfordetection.txt"))()
    end
})

Tabs.KFTab:Button({
    Title = "spy合集",
    Desc = "很多SPY融合在一块了",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/Simple_Spy_Utility.txt"))()
    end
})

Tabs.KFTab:Button({
    Title = "简洁spy",
    Desc = "UI简洁",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/fuckg1thub/RizzSpy/refs/heads/main/alright"))()
    end
})

Tabs.KFTab:Button({
    Title = "小spy",
    Desc = "UI小",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/EHvjE2sT"))()
    end
})

Tabs.KFTab:Button({
    Title = "贴花spy",
    Desc = "获取所有贴花ID",
    Callback = function()
loadstring(game:HttpGet('https://pastefy.app/gkqzwu88/raw'))()
    end
})

Tabs.KFTab:Button({
    Title = "西格玛spy",
    Desc = "更高级的spy",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Sigma-Spy/refs/heads/main/Main.lua"))()
    end
})

Tabs.KFTab:Button({
    Title = "dex++",
    Desc = "更好的dex",
    Callback = function()
loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
    end
})

Tabs.KFTab:Button({
    Title = "氯胺酮spy",
    Desc = "spy",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/InfernusScripts/Ketamine/refs/heads/main/Ketamine.lua"))()
    end
})

Tabs.KFTab:Button({
    Title = "绕过spy和dex检测",
    Desc = "等级低的执行器无法使用",
    Callback = function()
loadstring(game:HttpGet("https://gist.githubusercontent.com/Tesker-103/23ea97f58891617afd8f797f0a7446e6/raw/011b70e99abb44aa6fc970c587c3eb686b40594e/Securedexbytesker103"))()
    end
})

Tabs.KFTab:Button({
    Title = "http嗅探器",
    Desc = "httpspy",
    Callback = function()
loadstring(game:HttpGet("https://ripskids.lol/official/HttpSpy/loader.lua"))()
    end
})

Tabs.KFTab:Button({
    Title = "乌托邦spy",
    Desc = "spy",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Klinac/scripts/main/utopia_spy.lua", true))()
    end
})

Tabs.KFTab:Button({
    Title = "Cobaltspy",
    Desc = "spy",
    Callback = function()
loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
    end
})

Tabs.KFTab:Button({
    Title = "夜spyv3",
    Desc = "spy",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelo17123/NightSpyV3/refs/heads/main/NightSpy%20V4"))()
    end
})

Tabs.KFTab:Button({
    Title = "httpsSPY",
    Desc = "httpsspyWebhook销毁器",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hm5011/hussain/refs/heads/main/Links%20Spy"))()
    end
})

Tabs.KFTab:Button({
    Title = "Webhook拦截器webhookspy",
    Desc = "",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/offperms/emplicswebhookspy/main/release"))()
    end
})

Tabs.KFTab:Button({
    Title = "RedCodespy",
    Desc = "一般",
    Callback = function()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/RedCodeCheat/Roblox/refs/heads/main/RedCode_Remote_Spy.lua')))() 
    end
})

Tabs.KFTab:Button({
    Title = "HTTPspy",
    Desc = "撸鸡吧",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/293jOse0ejd8du/HttpSpy/refs/heads/main/main.lua"))() 
    end
})

Tabs.KFTab:Button({
    Title = "库尔斯克斯RSPY",
    Desc = "rspy",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/nizartitwaniii/Register-Roblox-/refs/heads/main/Protected_2944435597543940.txt"))() 
    end
})

Tabs.KFTab:Button({
    Title = "SpyOS",
    Desc = "HttpPost.HttpGet.SPY",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/RENBex6969/SpyOS/refs/heads/main/SpyOS_a2.lua"))() 
    end
})

Tabs.KFTab:Button({
    Title = "杰森SPY",
    Desc = "spy",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/wjF5j5YD"))() 
    end
})

Tabs.KFTab:Button({
    Title = "速度spy",
    Desc = "rspy改进",
    Callback = function()
loadstring(game:HttpGet('https://gist.githubusercontent.com/24rr/ec08ee90929e07f3b4d2dd22f15146dc/raw/b337951012d6ed330067058f196ee0c414b42df3/spy-velocity'))()
    end
})

Tabs.HDTab:Button({
    Title = "黑洞V4",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/V4.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "黑洞V5",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/V5.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "黑洞V6",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/V6.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "双环控制黑洞",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%8F%8C%E7%8E%AF%E6%8E%A7%E5%88%B6%E9%BB%91%E6%B4%9E.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "哥特风黑洞",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E5%93%A5%E7%89%B9%E9%A3%8E%E9%BB%91%E6%B4%9E.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "磁铁黑洞V2",
    Desc = "已汉化",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ke9460394-dot/ugik/refs/heads/main/%E7%A3%81%E9%93%81%E9%BB%91%E6%B4%9EV2.txt"))()
    end
})

Tabs.HDTab:Button({
    Title = "无敌黑洞什么都可以吸",
    Desc = "仅自己可见娱乐用",
    Callback = function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/iimateiYT/Scripts/main/Black%20Hole.lua"))()
    end
})

Tabs.HDTab:Button({
    Title = "磁铁黑洞",
    Desc = "未汉化但是好看",
    Callback = function()
loadstring(game:HttpGet("https://pastebin.com/raw/CMnEfnz8"))()  
    end
})

Tabs.HDTab:Button({
    Title = "可爱黑洞",
    Desc = "未汉化",
    Callback = function()
pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hellohellohell012321/KAWAII-AURA/main/kawaii_aura.lua", true))()
end)
    end
})

--fwqjb

Tabs.TGTab:Button({
    Title = "叶子脚本",
    Desc = "需解卡 未汉化",
    Callback = function()
pcall(function()
loadstring(game:HttpGet("https://getnative.cc/script/loader"))()
end)
    end
})

Tabs.FKTab:Button({
    Title = "方块故事",
    Desc = "未汉化",
    Callback = function()
pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/TexRBLX/Roblox-stuff/refs/heads/main/block%20tales/revamp.lua"))()
end)
    end
})

                        --主题设置
do
    Tabs.MainTab = Window:Section({Title = "主题设置", Opened = true})
    Tabs.WindowTab = Tabs.MainTab:Tab({ Title = "选择主题", Icon = "zap" })
    Tabs.CreateThemeTab = Tabs.MainTab:Tab({ Title = "自制主题", Icon = "zap" })
end

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.WindowTab:Dropdown({
    Title = "主题选择",
    Multi = false,
    AllowNone = false,
    Value = nil,
    Values = themeValues,
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})
themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.WindowTab:Toggle({
    Title = "透明切换",
    Callback = function(e)
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

Tabs.WindowTab:Section({ Title = "保存" })

local fileNameInput = ""
Tabs.WindowTab:Input({
    Title = "配置名输入与处理",
    PlaceholderText = "Enter file name",
    Callback = function(text)
        fileNameInput = text
    end
})

Tabs.WindowTab:Button({
    Title = "保存配置",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

filesDropdown = Tabs.WindowTab:Dropdown({
    Title = "选择配置",
    Multi = false,
    AllowNone = true,
    Values = files,
    Callback = function(selectedFile)
        fileNameInput = selectedFile
    end
})

Tabs.WindowTab:Button({
    Title = "加载配置",
    Callback = function()
        if fileNameInput ~= "" then
            local data = LoadFile(fileNameInput)
            if data then
                WindUI:Notify({
                    Title = "File Loaded",
                    Content = "Loaded data: " .. HttpService:JSONEncode(data),
                    Duration = 5,
                })
                if data.Transparent then 
                    Window:ToggleTransparency(data.Transparent)
                    ToggleTransparency:SetValue(data.Transparent)
                end
                if data.Theme then WindUI:SetTheme(data.Theme) end
            end
        end
    end
})

Tabs.WindowTab:Button({
    Title = "覆盖配置",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.WindowTab:Button({
    Title = "列表刷新",
    Callback = function()
        filesDropdown:Refresh(ListFiles())
    end
})

local currentThemeName = WindUI:GetCurrentTheme()
local themes = WindUI:GetThemes()

local ThemeAccent = themes[currentThemeName].Accent
local ThemeOutline = themes[currentThemeName].Outline
local ThemeText = themes[currentThemeName].Text
local ThemePlaceholderText = themes[currentThemeName].Placeholder

function updateTheme()
    WindUI:AddTheme({
        Name = currentThemeName,
        Accent = ThemeAccent,
        Outline = ThemeOutline,
        Text = ThemeText,
        Placeholder = ThemePlaceholderText
    })
    WindUI:SetTheme(currentThemeName)
end

local CreateInput = Tabs.CreateThemeTab:Input({
    Title = "主题名字",
    Value = currentThemeName,
    Callback = function(name)
        currentThemeName = name
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "背景色配置",
    Default = Color3.fromHex(ThemeAccent),
    Callback = function(color)
        ThemeAccent = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "轮廓颜色选择",
    Default = Color3.fromHex(ThemeOutline),
    Callback = function(color)
        ThemeOutline = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "文本颜色选择",
    Default = Color3.fromHex(ThemeText),
    Callback = function(color)
        ThemeText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "文本颜色配置",
    Default = Color3.fromHex(ThemePlaceholderText),
    Callback = function(color)
        ThemePlaceholderText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Button({
    Title = "主题更新",
    Callback = function()
        updateTheme()
    end
})

do



   Tabs.MXTab = Tabs.MainTab:Tab({ Title = "鸣谢名单", Icon = "zap" })
   Tabs.JBTab = Tabs.MainTab:Tab({ Title = "脚本", Icon = "zap" })
end



Tabs.MXTab:Paragraph({
    Title = "冷寂",
    Desc = "大红眼睛的恩情还不完",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("2893403284")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "群1057168892",
                    Duration = 2
                })
            end
        }
    }
})

Tabs.MXTab:Paragraph({
    Title = "唐尧",
    Desc = "提供了自动发言和坐标仪",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("唐尧")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "群1057168892",
                    Duration = 2
                })
            end
        }
    }
})

Tabs.MXTab:Paragraph({
    Title = "Kenny",
    Desc = "Kenny脚本制作人",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("1531514159")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "群1057168892",
                    Duration = 2
                })
            end
        }
    }
})

Tabs.MXTab:Paragraph({
    Title = "谢谢",
    Desc = "没这个源码我还二改不了👍🏻👍🏻👍🏻",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("2893403284")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "感谢Kenny",
                    Duration = 2
                })
            end
        }
    }
})

Tabs.JBTab:Paragraph({
    Title = "创世纪官方频道",
    Desc = "genesis",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("http://www.youtube.com/@GENESIS-FE")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "群1057168892",
                    Duration = 2
                })
            end
        }
    }
})

Tabs.JBTab:Paragraph({
    Title = "melon官方频道",
    Desc = "melon",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "点击复制",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("http://www.youtube.com/@MelonScripter")
                WindUI:Notify({
                    Title = "复制!",
                    Content = "群1057168892",
                    Duration = 2
                })
            end
        }
    }
})
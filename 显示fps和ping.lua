--[[
    Ping + FPS 显示脚本
    使用 WindUI
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 配置
local Config = {
    Enabled = true,
    Position = "右上",          -- 默认位置
}

-- 位置对应表
local PositionMap = {
    ["左上"] = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 12, 0, 12) },
    ["右上"] = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12) },
    ["左下"] = { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12) },
    ["右下"] = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12) },
    ["上"]   = { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12) },
    ["下"]   = { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12) },
    ["左"]   = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0) },
    ["右"]   = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0) },
    ["中"]   = { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0) },
}

-- 创建显示界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PingFPSDisplay"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.BackgroundTransparency = 1
Frame.Size = UDim2.new(0, 160, 0, 50)
Frame.Parent = ScreenGui

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPS"
FPSLabel.BackgroundTransparency = 1
FPSLabel.Size = UDim2.new(1, 0, 0, 24)
FPSLabel.Position = UDim2.new(0, 0, 0, 0)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 18
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
FPSLabel.TextStrokeTransparency = 0.6
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Text = "FPS: --"
FPSLabel.Parent = Frame

local PingLabel = Instance.new("TextLabel")
PingLabel.Name = "Ping"
PingLabel.BackgroundTransparency = 1
PingLabel.Size = UDim2.new(1, 0, 0, 24)
PingLabel.Position = UDim2.new(0, 0, 0, 24)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 18
PingLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
PingLabel.TextStrokeTransparency = 0.6
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.Text = "Ping: -- ms"
PingLabel.Parent = Frame

-- 更新位置函数
local function UpdatePosition(posName)
    local data = PositionMap[posName]
    if not data then return end

    Frame.AnchorPoint = data.AnchorPoint
    Frame.Position = data.Position

    -- 根据左右调整文字对齐
    if data.AnchorPoint.X >= 0.5 then
        FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
        PingLabel.TextXAlignment = Enum.TextXAlignment.Right
    else
        FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
        PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    end
end

UpdatePosition(Config.Position)

-- FPS 计算
local frames = 0
local lastTime = tick()
local currentFPS = 0

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - lastTime >= 1 then
        currentFPS = frames
        frames = 0
        lastTime = now
    end
end)

-- 主更新循环
local connection
local function StartUpdate()
    if connection then connection:Disconnect() end
    connection = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then
            Frame.Visible = false
            return
        end
        Frame.Visible = true

        -- FPS
        FPSLabel.Text = "FPS: " .. tostring(currentFPS)

        -- Ping
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        PingLabel.Text = "Ping: " .. ping .. " ms"
    end)
end

StartUpdate()

-- WindUI 界面
local Window = WindUI:CreateWindow({
    Title = "Ping & FPS",
    Icon = "activity",
    Theme = "Dark",
    Folder = "PingFPS",
})

local Tab = Window:Tab({
    Title = "显示设置",
    Icon = "monitor",
})

Tab:Toggle({
    Title = "启用显示",
    Value = true,
    Callback = function(value)
        Config.Enabled = value
        Frame.Visible = value
    end,
})

Tab:Dropdown({
    Title = "显示位置",
    Values = {"左上", "右上", "左下", "右下", "上", "下", "左", "右", "中"},
    Value = "右上",
    Callback = function(selected)
        Config.Position = selected
        UpdatePosition(selected)
    end,
})

Tab:Section({ Title = "说明" })

Tab:Paragraph({
    Title = "使用方法",
    Desc = "开启后屏幕上会实时显示 FPS 和 Ping 值。\n可通过下拉菜单切换九个位置。",
})

print("[Ping & FPS] 已加载")

--[[
    远程脚本 - Ping + FPS 显示
    依赖主脚本：getgenv().Tabs.PingFPSTab = Tab（或 getgenv().SuturePingFPSTab）
]]

-- 防重复加载：重复执行主脚本时不会再次创建叠加层
if getgenv().__PINGFPS_LOADED then
    return
end
getgenv().__PINGFPS_LOADED = true

local Tab = (getgenv().Tabs and getgenv().Tabs.PingFPSTab) or getgenv().SuturePingFPSTab

if not Tab then
    warn("[PingFPS] 未找到 PingFPSTab，请检查主脚本是否正确赋值")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 配置
local Config = {
    Enabled = true,
    Position = "右上",
    TextSize = 18,
}

-- 位置对应表（只保留四角）
local PositionMap = {
    ["左上"] = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 12, 0, 12) },
    ["右上"] = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12) },
    ["左下"] = { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12) },
    ["右下"] = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12) },
}

-- 创建显示界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PingFPSDisplay"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.BackgroundTransparency = 1
Frame.Size = UDim2.new(0, 180, 0, 55)
Frame.Parent = ScreenGui

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPS"
FPSLabel.BackgroundTransparency = 1
FPSLabel.Size = UDim2.new(1, 0, 0, 26)
FPSLabel.Position = UDim2.new(0, 0, 0, 0)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = Config.TextSize
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
FPSLabel.TextStrokeTransparency = 0.6
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Text = "FPS: --"
FPSLabel.Parent = Frame

local PingLabel = Instance.new("TextLabel")
PingLabel.Name = "Ping"
PingLabel.BackgroundTransparency = 1
PingLabel.Size = UDim2.new(1, 0, 0, 26)
PingLabel.Position = UDim2.new(0, 0, 0, 26)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = Config.TextSize
PingLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
PingLabel.TextStrokeTransparency = 0.6
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.Text = "Ping: -- ms"
PingLabel.Parent = Frame

-- 更新位置
local function UpdatePosition(posName)
    local data = PositionMap[posName]
    if not data then return end

    Frame.AnchorPoint = data.AnchorPoint
    Frame.Position = data.Position

    if data.AnchorPoint.X >= 0.5 then
        FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
        PingLabel.TextXAlignment = Enum.TextXAlignment.Right
    else
        FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
        PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    end
end

-- 更新文字大小
local function UpdateSize(size)
    Config.TextSize = size
    FPSLabel.TextSize = size
    PingLabel.TextSize = size

    -- 同步调整行高和整体高度
    local lineHeight = size + 8
    FPSLabel.Size = UDim2.new(1, 0, 0, lineHeight)
    PingLabel.Size = UDim2.new(1, 0, 0, lineHeight)
    PingLabel.Position = UDim2.new(0, 0, 0, lineHeight)
    Frame.Size = UDim2.new(0, math.max(160, size * 9), 0, lineHeight * 2)
end

UpdatePosition(Config.Position)
UpdateSize(Config.TextSize)

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

-- 主更新
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then
        Frame.Visible = false
        return
    end
    Frame.Visible = true

    FPSLabel.Text = "FPS: " .. tostring(currentFPS)

    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    PingLabel.Text = "Ping: " .. ping .. " ms"
end)

-- ==================== 往主脚本传入的 Tab 添加 UI ====================
local uiOk, uiErr = pcall(function()
    Tab:Toggle({
        Title = "启用 Ping & FPS 显示",
        Value = true,
        Callback = function(value)
            Config.Enabled = value
            Frame.Visible = value
        end,
    })

    Tab:Dropdown({
        Title = "显示位置",
        Values = {"左上", "右上", "左下", "右下"},
        Value = "左上",
        Callback = function(selected)
            Config.Position = selected
            UpdatePosition(selected)
        end,
    })

    Tab:Slider({
        Title = "显示大小",
        Step = 1,
        Value = {
            Min = 12,
            Max = 36,
            Default = 18,
        },
        Callback = function(value)
            UpdateSize(value)
        end,
    })

    Tab:Paragraph({
        Title = "说明",
        Desc = "实时显示当前 FPS 和 Ping 值。\n可切换四个角落位置，并调整文字大小。",
    })
end)

if not uiOk then
    warn("[PingFPS] Tab UI 创建失败:", uiErr)
else
    print("[PingFPS] 远程脚本已加载到 Tab")
end

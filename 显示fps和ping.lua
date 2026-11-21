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
-- ★ 统一隐藏容器：优先主脚本导出的 __SUIF_HIDDEN_GUI（gethui/CoreGui），
--   不落 PlayerGui（那是游戏 LocalScript 唯一能枚举到的地方）
local ScreenGui
do
    local g0 = (getgenv and getgenv()) or _G
    if type(g0.__SUIF_HIDDEN_GUI) == "function" then
        local ok, r = pcall(g0.__SUIF_HIDDEN_GUI, "PingFPSDisplay", 90)
        if ok and r then ScreenGui = r end
    end
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "PingFPSDisplay"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local okH, h = pcall(function() return gethui and gethui() end)
        if okH and h then
            ScreenGui.Parent = h
        else
            local okC = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
            if not okC then
                ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end
        end
        if type(g0.__SUIF_HIDE_GUI) == "function" then pcall(g0.__SUIF_HIDE_GUI, ScreenGui) end
    end
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

-- ★ 原来这里挂了两个永久连接：
--     ① RenderStepped 每帧自增计数（60~240fps → 每帧一次 Lua 回调）
--     ② Heartbeat 每帧写 FPSLabel/PingLabel（**每帧 UI 重绘**）+ 每帧调 GetNetworkPing
--   两个都不断开，就算显示关掉也照样每帧跑。
--   改成单协程：每秒量一次真实帧间隔、读一次 ping、写一次文本。零每帧开销。
local currentFPS = 0
do
    local RS = RunService
    task.spawn(function()
        while true do
            if Config.Enabled then
                -- 量一次真实帧间隔（只等一帧，不是常驻每帧回调）
                local ok, dt = pcall(function()
                    local t0 = os.clock()
                    RS.RenderStepped:Wait()
                    return os.clock() - t0
                end)
                local fps = 0
                if ok and dt and dt > 0 then
                    fps = math.floor(1 / dt)
                end
                if fps > 0 then
                    currentFPS = (currentFPS > 0) and math.floor(currentFPS * 0.6 + fps * 0.4) or fps
                end
                Frame.Visible = true
                FPSLabel.Text = "FPS: " .. tostring(currentFPS)
                local ok2, ping = pcall(function()
                    return math.floor(LocalPlayer:GetNetworkPing() * 1000)
                end)
                PingLabel.Text = "Ping: " .. tostring(ok2 and ping or 0) .. " ms"
            else
                Frame.Visible = false
            end
            task.wait(1)
        end
    end)
end

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

--[[
    落脚点 + 行动轨迹指示器 v6
    - 地面：身体下部行动轨迹 + 头顶起跳预测（两条不同颜色抛物线）
    - 起跳后：只保留行动轨迹，落点红色球 + 随高度缩小的外围圆圈
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 配置
local Config = {
    Enabled = false,
    JumpLineColor = Color3.fromRGB(0, 220, 255),      -- 起跳预测线（青色）
    ActionLineColor = Color3.fromRGB(0, 255, 140),    -- 行动轨迹线（绿色）
    JumpBallColor = Color3.fromRGB(0, 220, 255),      -- 起跳落点球
    InAirBallColor = Color3.fromRGB(255, 60, 60),     -- 空中落点球（红色）
    Thickness = 0.11,
    Segments = 28,
}

-- 可视化对象
local Visual = {
    JumpLines = {},
    ActionLines = {},
    JumpBall = nil,
    InAirBall = nil,
    InAirRing = nil,
    Connection = nil,
}

local function Cleanup()
    for _, t in pairs({Visual.JumpLines, Visual.ActionLines}) do
        for _, p in ipairs(t) do
            if p and p.Parent then p:Destroy() end
        end
        table.clear(t)
    end
    for _, name in ipairs({"JumpBall", "InAirBall", "InAirRing"}) do
        if Visual[name] then
            Visual[name]:Destroy()
            Visual[name] = nil
        end
    end
end

local function CreateLineSegments(count, color)
    local list = {}
    for i = 1, count do
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Material = Enum.Material.Neon
        p.Color = color
        p.Size = Vector3.new(Config.Thickness, Config.Thickness, 1)
        p.Transparency = 1
        p.Parent = workspace
        table.insert(list, p)
    end
    return list
end

local function CreateVisuals()
    Cleanup()

    Visual.JumpLines = CreateLineSegments(Config.Segments, Config.JumpLineColor)
    Visual.ActionLines = CreateLineSegments(Config.Segments, Config.ActionLineColor)

    -- 起跳落点球
    local jb = Instance.new("Part")
    jb.Name = "JumpBall"
    jb.Anchored = true
    jb.CanCollide = false
    jb.CanQuery = false
    jb.CanTouch = false
    jb.Material = Enum.Material.Neon
    jb.Color = Config.JumpBallColor
    jb.Size = Vector3.new(0.9, 0.9, 0.9)
    jb.Shape = Enum.PartType.Ball
    jb.Transparency = 1
    jb.Parent = workspace
    Visual.JumpBall = jb

    -- 空中红色落点球
    local ib = Instance.new("Part")
    ib.Name = "InAirBall"
    ib.Anchored = true
    ib.CanCollide = false
    ib.CanQuery = false
    ib.CanTouch = false
    ib.Material = Enum.Material.Neon
    ib.Color = Config.InAirBallColor
    ib.Size = Vector3.new(0.75, 0.75, 0.75)
    ib.Shape = Enum.PartType.Ball
    ib.Transparency = 1
    ib.Parent = workspace
    Visual.InAirBall = ib

    -- 空中外围圆圈（会缩小）
    local ring = Instance.new("Part")
    ring.Name = "InAirRing"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
    ring.Material = Enum.Material.Neon
    ring.Color = Config.InAirBallColor
    ring.Size = Vector3.new(3.5, 0.08, 3.5)
    ring.Shape = Enum.PartType.Cylinder
    ring.Transparency = 1
    ring.Parent = workspace
    Visual.InAirRing = ring
end

-- 真实跳跃初速度
local function GetJumpVelocity(humanoid)
    if humanoid.UseJumpPower then
        return humanoid.JumpPower
    end
    return math.sqrt(2 * workspace.Gravity * (humanoid.JumpHeight or 7.2))
end

-- 起跳预测速度（向前）
local function GetJumpPredictVelocity(root, humanoid)
    local jumpVel = GetJumpVelocity(humanoid)
    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude < 0.1 then
        moveDir = root.CFrame.LookVector
    end
    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    else
        moveDir = Vector3.new(0, 0, -1)
    end

    local currentH = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
    local speed = math.max(currentH, humanoid.WalkSpeed)
    local horizontal = moveDir * speed
    return Vector3.new(horizontal.X, jumpVel, horizontal.Z)
end

-- 生成抛物线点
local function GenerateTrajectory(startPos, velocity)
    local points = {}
    local gravity = workspace.Gravity
    local dt = 0.045
    local maxTime = 5.5

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local pos = startPos
    local vel = velocity
    table.insert(points, pos)

    for t = 0, maxTime, dt do
        local accel = Vector3.new(0, -gravity, 0)
        local nextVel = vel + accel * dt
        local nextPos = pos + vel * dt + 0.5 * accel * dt * dt

        local dir = nextPos - pos
        if dir.Magnitude > 0.01 then
            local result = workspace:Raycast(pos, dir, params)
            if result then
                table.insert(points, result.Position + Vector3.new(0, 0.1, 0)) -- 防止穿模
                break
            end
        end

        pos = nextPos
        vel = nextVel
        table.insert(points, pos)

        if pos.Y < -120 then break end
    end
    return points
end

-- 更新一组线段
local function UpdateLines(lines, points, color, thickness)
    local total = #lines
    if #points < 2 then
        for _, l in ipairs(lines) do l.Transparency = 1 end
        return
    end

    local step = (#points - 1) / total
    for i = 1, total do
        local line = lines[i]
        local idx1 = math.clamp(math.floor((i - 1) * step) + 1, 1, #points)
        local idx2 = math.clamp(math.floor(i * step) + 1, 1, #points)
        local p1, p2 = points[idx1], points[idx2]
        local dist = (p2 - p1).Magnitude

        if dist < 0.05 then
            line.Transparency = 1
        else
            line.Size = Vector3.new(thickness, thickness, dist)
            line.CFrame = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist / 2)
            line.Color = color
            line.Transparency = 0.2
        end
    end
end

-- 获取离地高度
local function GetHeightAboveGround(root)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), params)
    if result then
        return (root.Position - result.Position).Y
    end
    return 10
end

local function Update()
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not root or not humanoid or not head then return end

    local state = humanoid:GetState()
    local inAir = state == Enum.HumanoidStateType.Freefall
               or state == Enum.HumanoidStateType.Jumping
               or state == Enum.HumanoidStateType.FallingDown

    -- 行动轨迹（身体下部 / 真实速度）
    local actionStart = root.Position - Vector3.new(0, 2.5, 0) -- 身体下部
    local actionVel = root.AssemblyLinearVelocity
    local actionPoints = GenerateTrajectory(actionStart, actionVel)

    -- 起跳预测（头顶 / 向前起跳）
    local jumpPoints = nil
    if not inAir then
        local jumpVel = GetJumpPredictVelocity(root, humanoid)
        jumpPoints = GenerateTrajectory(head.Position, jumpVel)
    end

    -- ===== 绘制 =====
    if not inAir then
        -- 地面：两条线都画
        UpdateLines(Visual.ActionLines, actionPoints, Config.ActionLineColor, Config.Thickness)
        UpdateLines(Visual.JumpLines, jumpPoints, Config.JumpLineColor, Config.Thickness)

        -- 起跳落点球
        if jumpPoints and #jumpPoints > 0 and Visual.JumpBall then
            local pos = jumpPoints[#jumpPoints]
            Visual.JumpBall.CFrame = CFrame.new(pos)
            Visual.JumpBall.Color = Config.JumpBallColor
            Visual.JumpBall.Transparency = 0.1
        end

        -- 隐藏空中指示
        if Visual.InAirBall then Visual.InAirBall.Transparency = 1 end
        if Visual.InAirRing then Visual.InAirRing.Transparency = 1 end
    else
        -- 空中：只画行动轨迹，隐藏起跳线
        for _, l in ipairs(Visual.JumpLines) do l.Transparency = 1 end
        if Visual.JumpBall then Visual.JumpBall.Transparency = 1 end

        UpdateLines(Visual.ActionLines, actionPoints, Config.ActionLineColor, Config.Thickness)

        -- 红色落点球 + 缩小圆圈
        if actionPoints and #actionPoints > 0 then
            local landPos = actionPoints[#actionPoints]
            local height = GetHeightAboveGround(root)

            if Visual.InAirBall then
                Visual.InAirBall.CFrame = CFrame.new(landPos)
                Visual.InAirBall.Color = Config.InAirBallColor
                Visual.InAirBall.Transparency = 0.05
            end

            if Visual.InAirRing then
                -- 高度越高圆圈越大，越接近地面越小，最终合并进球
                local maxRing = 4.2
                local minRing = 0.9
                local t = math.clamp(height / 18, 0, 1) -- 18 studs 为参考高度
                local ringSize = minRing + (maxRing - minRing) * t

                Visual.InAirRing.Size = Vector3.new(ringSize, 0.08, ringSize)
                Visual.InAirRing.CFrame = CFrame.new(landPos) * CFrame.Angles(0, 0, math.rad(90))
                Visual.InAirRing.Color = Config.InAirBallColor
                Visual.InAirRing.Transparency = 0.25 + (1 - t) * 0.4 -- 接近地面时更透明
            end
        end
    end
end

-- UI
local Window = WindUI:CreateWindow({
    Title = "轨迹 + 起跳落点",
    Icon = "map-pin",
    Theme = "Dark",
    Folder = "TrajectoryIndicator",
})

local Tab = Window:Tab({
    Title = "功能",
    Icon = "crosshair",
})

Tab:Toggle({
    Title = "启用指示器",
    Value = false,
    Callback = function(value)
        Config.Enabled = value
        if value then
            CreateVisuals()
            if Visual.Connection then Visual.Connection:Disconnect() end
            Visual.Connection = RunService.RenderStepped:Connect(Update)
        else
            if Visual.Connection then
                Visual.Connection:Disconnect()
                Visual.Connection = nil
            end
            Cleanup()
        end
    end,
})

Tab:Colorpicker({
    Title = "起跳预测线颜色",
    Default = Config.JumpLineColor,
    Callback = function(c)
        Config.JumpLineColor = c
        Config.JumpBallColor = c
        for _, l in ipairs(Visual.JumpLines) do if l then l.Color = c end end
        if Visual.JumpBall then Visual.JumpBall.Color = c end
    end,
})

Tab:Colorpicker({
    Title = "行动轨迹线颜色",
    Default = Config.ActionLineColor,
    Callback = function(c)
        Config.ActionLineColor = c
        for _, l in ipairs(Visual.ActionLines) do if l then l.Color = c end end
    end,
})

Tab:Colorpicker({
    Title = "空中落点球颜色",
    Default = Config.InAirBallColor,
    Callback = function(c)
        Config.InAirBallColor = c
        if Visual.InAirBall then Visual.InAirBall.Color = c end
        if Visual.InAirRing then Visual.InAirRing.Color = c end
    end,
})

Tab:Slider({
    Title = "线条粗细",
    Step = 0.01,
    Value = { Min = 0.04, Max = 0.3, Default = 0.11 },
    Callback = function(v)
        Config.Thickness = v
    end,
})

Tab:Section({ Title = "说明" })

Tab:Paragraph({
    Title = "当前行为",
    Desc = "• 地面：身体下部绿色行动轨迹 + 头顶青色起跳预测（末端有球）\n• 真正起跳后：只保留行动轨迹，落点显示红色球 + 随离地高度缩小的圆圈\n• 圆圈会随着接近地面逐渐缩小并合并进红色小球",
})

LocalPlayer.CharacterAdded:Connect(function()
    if Config.Enabled then
        task.wait(0.6)
        CreateVisuals()
    end
end)

print("[轨迹 + 起跳落点] v6 已加载")

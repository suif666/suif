-- 远程脚本：甩飞 + 传送（纯功能，无窗口创建）
-- 依赖主脚本提供的 getgenv().Tabs.FlingTPTab 和 getgenv().WindUI

local Tab = getgenv().Tabs.FlingTPTab
local WindUI = getgenv().WindUI
if not Tab or not WindUI then
    error("主脚本未正确暴露 Tab 或 WindUI")
end

-- ===== 服务与工具 =====
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ===== 状态 =====
local FlingLoop = false
local Flinging = false
local TP_Loop = false
local SelectedTargets = {}
local AlreadyNotified = {}
local OldPos = nil
local playerNameList = {"ALL"}

local function Notify(title, content, duration)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3
        })
    end)
end

local function rebuildPlayerList()
    playerNameList = {"ALL"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerNameList, p.Name)
        end
    end
end
rebuildPlayerList()

-- ===== 核心甩飞 v2 =====
-- 原版的两个毛病：
--   A. 退出条件是 until BasePart.Velocity.Magnitude > 500（BasePart 是【对方】的 RootPart），
--      而 500 正是本脚本「防甩飞」里判定"正在被甩飞"的阈值 —— 等于一甩成功就立刻收手，
--      只给一个瞬时冲量，对方弹一下就落回来。而且穿模本身会让速度瞬间飙高（假信号），
--      经常还没真推开就已经满足退出条件了。
--   B. 全程没有任何反馈，SkidFling 不返回任何东西，所以不知道到底甩没甩动。
--
-- v2 的改动：
--   1. 不再用瞬时速度当成功判据，改成看【实际位移】—— 位置真的被推开了才算数
--   2. 最短持续时间 + 位移达标才收工，保证冲量够（物理权限转移也需要时间）
--   3. 冲量双向下发：自己和对方的 RootPart 都设速度（没权限时服务器忽略，包 pcall 无害）
--   4. 结束后测量位移 / 速度峰值 / 最高点 / 物理权限，并弹提示告诉你结果
local FLING = {
    MinTime     = 0.5,    -- 最短持续时间（物理权限转移需要时间，太短等于白甩）
    MaxTime     = 4.0,    -- 硬上限，防止卡太久
    SuccessDist = 30,     -- 位移超过这么多米就算甩动了
    Report      = true,   -- 是否弹结果提示
}

-- 查对方部件现在归谁做物理模拟。甩飞能不能生效，根本原因就在这一条：
-- 客户端只有拿到对方部件的物理权限，"推开"才会被服务器接受；
-- 拿不到的话，你在对方部件上写的速度会被服务器直接丢掉，位置也会被拉回去。
local function hasOwnership(part)
    if not part or not part.Parent then return false end
    local ok, owner = pcall(function() return part:GetNetworkOwner() end)
    if not ok then return false end
    return owner == LocalPlayer
end

-- 查一个部件现在归谁做物理模拟。这是甩飞能不能生效的根本原因：
-- 客户端只有拿到对方部件的物理权限，"推开"才会被服务器接受。
local function ownerNameOf(part)
    if not part or not part.Parent then return "部件已消失" end
    local ok, owner = pcall(function() return part:GetNetworkOwner() end)
    if not ok then return "未知" end
    if owner == nil then return "服务器(无权限)" end
    if owner == LocalPlayer then return "自己(有权限)" end
    return owner.Name .. "(无权限)"
end

local function SkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == LocalPlayer then return end
    if Flinging then return end
    Flinging = true

    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character

    if not (Character and Humanoid and RootPart and TCharacter) then
        Flinging = false
        return
    end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    local Camera = workspace.CurrentCamera

    local victimPart = TRootPart or THead or Handle
    if not victimPart then
        Flinging = false
        if FLING.Report then
            Notify("甩飞 " .. TargetPlayer.Name, "对方身上没有可用部件，跳过", 2)
        end
        return
    end

    local Dead = false
    local DeadConn
    DeadConn = LocalPlayer.CharacterAdded:Connect(function()
        Dead = true
        if DeadConn then DeadConn:Disconnect() DeadConn = nil end
    end)

    -- 原版 bug：只在自身速度 < 50 时才记 OldPos，连续甩飞时用的是上一轮的旧坐标，
    -- 善后逻辑会把你自己传回错误的位置。改成每次甩飞开始都重新记。
    OldPos = RootPart.CFrame

    if Camera then
        Camera.CameraSubject = THead or Handle or THumanoid
    end

    -- 测量基线
    local startPos = victimPart.Position
    local startTick = tick()
    local peakSpeed = 0
    local highest = startPos.Y

    local function track()
        if not victimPart or not victimPart.Parent then return end
        local p = victimPart.Position
        if p.Y > highest then highest = p.Y end
        local ok, v = pcall(function() return victimPart.AssemblyLinearVelocity.Magnitude end)
        if ok and v and v > peakSpeed then peakSpeed = v end
    end

    local function moved()
        if not victimPart or not victimPart.Parent then return 0 end
        return (victimPart.Position - startPos).Magnitude
    end

    local function FPos(BasePart, Pos, Ang)
        if Dead or not BasePart or not BasePart.Parent or not RootPart or not RootPart.Parent then return end
        local cf = CFrame.new(BasePart.Position) * Pos * Ang
        RootPart.CFrame = cf
        if Character.PrimaryPart then
            pcall(function() Character:SetPrimaryPartCFrame(cf) end)
        end
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)

        -- v2：把冲量也下发给对方。客户端只有拿到该部件的物理权限时才生效，
        -- 没权限时服务器直接忽略，所以包 pcall 保证不会出错。
        if not Dead and TRootPart and TRootPart.Parent then
            pcall(function()
                TRootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                TRootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end)
        end
    end

    local function SFBasePart(BasePart)
        local Angle = 0
        while true do
            if Dead or not BasePart or not BasePart.Parent or not RootPart or not RootPart.Parent then break end
            if not TRootPart or not TRootPart.Parent or not THumanoid or THumanoid.Health <= 0 then break end

            local elapsed = tick() - startTick
            local dist = moved()
            -- 最优收工：已经抢到物理权限，并且对方真的被推开了 → 立刻停手，少折腾自己
            if dist >= FLING.SuccessDist and hasOwnership(victimPart) then break end
            -- 次优收工：甩够 MinTime 且位移达标（有些游戏查不到权限，走这条兜底）
            if elapsed >= FLING.MinTime and dist >= FLING.SuccessDist then break end
            if elapsed >= FLING.MaxTime then break end

            if BasePart.Velocity.Magnitude > 1 then
                Angle = Angle + 100
                local move = THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25
                FPos(BasePart, CFrame.new(0, 1.5, 0) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait() track()
            else
                local walk = THumanoid.WalkSpeed
                local vel = TRootPart.Velocity.Magnitude / 1.25
                FPos(BasePart, CFrame.new(0, 1.5, walk), CFrame.Angles(math.rad(90), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, -walk), CFrame.Angles(0, 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, 1.5, vel), CFrame.Angles(math.rad(90), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, -vel), CFrame.Angles(0, 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait() track()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait() track()
            end
        end
    end

    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if not Dead then
        if TRootPart then SFBasePart(TRootPart)
        elseif THead then SFBasePart(THead)
        elseif Handle then SFBasePart(Handle) end
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

    -- 结算测量（必须在善后把一切都归零之前读）
    local dist = moved()
    local owner = ownerNameOf(victimPart)
    local rise = highest - startPos.Y
    local stillThere = victimPart.Parent ~= nil

    if Camera then
        local newHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if newHum then Camera.CameraSubject = newHum end
    end

    if not Dead and OldPos then
        local newChar = LocalPlayer.Character
        local newRoot = newChar and newChar:FindFirstChild("HumanoidRootPart")
        local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
        if newRoot and newHum then
            local start = tick()
            repeat
                newRoot.CFrame = OldPos * CFrame.new(0, 0.5, 0)
                if newChar.PrimaryPart then
                    pcall(function() newChar:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0)) end)
                end
                newHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, x in ipairs(newChar:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity = Vector3.zero
                        x.RotVelocity = Vector3.zero
                    end
                end
                task.wait()
            until (newRoot.Position - OldPos.Position).Magnitude < 25 or tick() - start > 3
        end
    end

    if DeadConn then DeadConn:Disconnect() DeadConn = nil end
    Flinging = false

    -- ===== 结果反馈：这就是原版完全缺失的部分 =====
    if FLING.Report then
        local verdict, detail
        if not stillThere then
            verdict = "甩出地图了"
            detail = "对方部件已消失"
        elseif dist >= FLING.SuccessDist then
            verdict = "甩飞成功"
            detail = string.format("位移 %.0f 米 / 峰值 %.0f / 升高 %.0f 米 / 权限 %s",
                dist, peakSpeed, rise, owner)
        elseif dist >= 5 then
            verdict = "只弹了一下就回来"
            detail = string.format("位移仅 %.0f 米 / 峰值 %.0f / 权限 %s（服务器把冲量压回去了）",
                dist, peakSpeed, owner)
        else
            verdict = "完全没甩动"
            detail = string.format("位移 %.0f 米 / 权限 %s（没拿到物理权限，甩不动）",
                dist, owner)
        end
        -- 循环模式下同一个结果只提示一次，避免刷屏
        local key = TargetPlayer.Name .. "|" .. verdict
        if not AlreadyNotified[key] then
            AlreadyNotified[key] = true
            Notify("甩飞 " .. TargetPlayer.Name, verdict .. "：" .. detail, 3)
        end
    end
end

-- ===== 防甩飞（参考 BS 的 AntiFling） =====
local AntiFling = false
local antiFlingConn = nil
local antiFlingPlayerConn = nil
local antiFlingCharConn = nil

local function setAllCharactersCollide(collide)
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CanCollide = collide
                    end)
                end
            end
        end
    end
end

local function startAntiFling()
    if AntiFling then return end
    AntiFling = true
    setAllCharactersCollide(false)

    antiFlingPlayerConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CanCollide = false
                    end)
                end
            end
        end)
    end)

    antiFlingCharConn = LocalPlayer.CharacterAdded:Connect(function(character)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = false
                end)
            end
        end
    end)

    -- 每帧只处理自己（速度/物理力，轻量）；全服 CanCollide 复查降到 2 秒一次
    local lastAntiFlingCheck = 0
    antiFlingConn = RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if root then
            if root.Velocity.Magnitude > 500 then
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
            end
            for _, child in ipairs(root:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") then
                    pcall(function()
                        child:Destroy()
                    end)
                end
            end
        end
        local now = os.clock()
        if now - lastAntiFlingCheck >= 2 then
            lastAntiFlingCheck = now
            pcall(setAllCharactersCollide, false)
        end
    end)
end

local function stopAntiFling()
    AntiFling = false
    if antiFlingConn then pcall(function() antiFlingConn:Disconnect() end) antiFlingConn = nil end
    if antiFlingPlayerConn then pcall(function() antiFlingPlayerConn:Disconnect() end) antiFlingPlayerConn = nil end
    if antiFlingCharConn then pcall(function() antiFlingCharConn:Disconnect() end) antiFlingCharConn = nil end
    setAllCharactersCollide(true)
end

-- ===== 传送 =====
local function TeleportToTarget()
    local target = nil
    if #SelectedTargets == 0 then
        Notify("错误", "请先选择目标", 2)
        return
    end

    if SelectedTargets[1] == "ALL" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                target = p
                break
            end
        end
    else
        target = SelectedTargets[1]
    end

    if not target or not target.Character then
        Notify("错误", "目标无效或未加载", 2)
        return
    end

    local root = target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and myRoot then
        myRoot.CFrame = root.CFrame * CFrame.new(0, 3, 0)
    end
end

-- ===== 循环控制 =====
local function StartFlingLoop()
    if FlingLoop then return end
    if #SelectedTargets == 0 then
        Notify("错误", "请先选择目标", 2)
        return
    end
    FlingLoop = true
    AlreadyNotified = {}

    task.spawn(function()
        while FlingLoop do
            local selfChar = LocalPlayer.Character
            local selfHum = selfChar and selfChar:FindFirstChildOfClass("Humanoid")
            if not selfChar or not selfHum or selfHum.Health <= 0 then
                task.wait(0.5)
            else
                local list = {}
                if SelectedTargets[1] == "ALL" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then table.insert(list, p) end
                    end
                else
                    list = SelectedTargets
                end

                for _, target in ipairs(list) do
                    if not FlingLoop then break end
                    if typeof(target) == "Instance" and target:IsA("Player") and target.Parent then
                        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local t = tick()
                            repeat task.wait() until not Flinging or tick() - t > 4
                            if FlingLoop then SkidFling(target) end
                            task.wait(0.15)
                        end
                    end
                end
                task.wait(0.3)
            end
        end
    end)
    Notify("甩飞", "循环甩飞已启动", 2)
end

local function StopFlingLoop()
    FlingLoop = false
    Notify("甩飞", "循环甩飞已停止", 2)
end

local selected = "选择脚本"

local Scripts = {
    ["碰撞甩飞"] = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Touch-fling-script-22447"))()
    end,
    ["动作甩飞"] = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/G63dPf2H"))()
    end,
}

Tab:Dropdown({
    Title = "甩飞外部脚本",
    Desc = "选中之后点下面的执行就可以执行选中的脚本",
    Values = {"碰撞甩飞", "动作甩飞"},
    Value = "选择脚本",
    Callback = function(v)
        selected = v
    end,
})

Tab:Button({
    Title = "执行",
    Desc = "执行上面单选框里面选择的外部脚本",
    Callback = function()
        if Scripts[selected] then
            Scripts[selected]()
        end
    end,
})

Tab:Space()


local function StartTPLoop()
    if TP_Loop then return end
    TP_Loop = true
    task.spawn(function()
        while TP_Loop do
            TeleportToTarget()
            task.wait(0.03)  -- 33次/秒：提高跟脚性，目标移动也能紧贴
        end
    end)
    Notify("传送", "循环传送已启动", 2)
end

local function StopTPLoop()
    TP_Loop = false
    Notify("传送", "循环传送已停止", 2)
end

-- ===== UI 控件（直接使用 Tab）=====
local TargetDropdown = nil
local listKey = ""
local lastListRefresh = 0
local selectedNames = {"ALL"}

local function updatePlayerList(force)
    -- 限流：3 秒内最多真正刷新一次，避免频繁重建下拉框导致卡顿
    local now = os.clock()
    if not force and now - lastListRefresh < 3 then return end
    rebuildPlayerList()
    local key = table.concat(playerNameList, ",")
    if force or key ~= listKey then
        listKey = key
        lastListRefresh = now
        pcall(function()
            if TargetDropdown.Refresh then
                TargetDropdown:Refresh(playerNameList, selectedNames)
            else
                TargetDropdown:SetValues(playerNameList)
            end
        end)
    end
end

TargetDropdown = Tab:Dropdown({
    Title = "选择目标",
 Desc = "可多选嗯对",
    Values = playerNameList,
    Value = {"ALL"},
    Multi = true,
    Callback = function(values)
        selectedNames = {}
        for _, name in ipairs(values) do
            table.insert(selectedNames, name)
        end
        SelectedTargets = {}
        for _, name in ipairs(values) do
            if name == "ALL" then
                SelectedTargets = {"ALL"}
                break
            else
                local plr = Players:FindFirstChild(name)
                if plr then table.insert(SelectedTargets, plr) end
            end
        end
    end
})

Tab:Button({
    Title = "刷新玩家列表",
    Desc = "手动刷新目标选择列表（玩家进出会自动更新，列表异常时点这个）",
    Icon = "refresh-cw",
    Callback = function()
        updatePlayerList(true)
        Notify("已刷新", "玩家列表已更新", 2)
    end
})

Tab:Button({
    Title = "单次甩飞",
 Desc = "字面意思 对选中的玩家执行一次甩飞 如果多选的话则会按顺序执行甩飞",
    Callback = function()
        if #SelectedTargets == 0 then
            Notify("错误", "请先选择目标", 2)
            return
        end
        AlreadyNotified = {}   -- 单选模式每次点击都重新报结果，不做去重
        task.spawn(function()
            local list = SelectedTargets[1] == "ALL" and Players:GetPlayers() or SelectedTargets
            for _, p in ipairs(list) do
                if p ~= LocalPlayer and typeof(p) == "Instance" then
                    SkidFling(p)
                    repeat task.wait() until not Flinging
                    task.wait(0.1)
                end
            end
        end)
    end
})

Tab:Toggle({
    Title = "循环甩飞",
 Desc = "和上面的单次甩飞一样 只不过改成循环的了",
    Value = false,
    Callback = function(v)
        if v then StartFlingLoop() else StopFlingLoop() end
    end
})

Tab:Toggle({
    Title = "防甩飞",
    Desc = "开启后小学生会不会急眼🤡",
    Value = false,
    Callback = function(v)
        if v then
            startAntiFling()
        else
            stopAntiFling()
        end
    end
})

Tab:Button({
    Title = "单次传送玩家",
 Desc = "和甩飞共用一个玩家表 如果你多选的话则只会传送列表靠上的选中玩家",
    Callback = function()
        TeleportToTarget()
    end
})

Tab:Toggle({
    Title = "循环传送",
 Desc = "字面意思 和上面单次传送原理一致",
    Value = false,
    Callback = function(v)
        if v then StartTPLoop() else StopTPLoop() end
    end
})

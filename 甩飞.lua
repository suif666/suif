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

-- ===== 核心甩飞 v8 =====
-- 判据：瞬时速度（VelGoal 500）。
--
-- v8 改的是【调度】，不是甩飞函数本身 —— 借鉴 SkidFling 原始版（pastebin zqyDSUWX）：
--
--   参考版：
--       for _,x in next, Players:GetPlayers() do
--           SkidFling(x)
--       end
--   一口气，中间【没有任何等待】，而且【不检查自己血量】。
--
--   本站原来：
--       SkidFling(p)
--       repeat task.wait() until not Flinging    -- 等上一个人甩完
--       task.wait(0.1)                           -- 再等 0.1 秒
--   每个目标之间等 0.1~0.3 秒；循环模式下一旦自己血量 <= 0 就整轮跳过。
--   结果就是「只甩到第一个人」。
--
-- 关键点：SkidFling 本身就是【同步】的（内部 task.wait() 会让出，跑完才返回），
-- 所以直接顺序调用就已经是「一个接一个」，多余的等待只会让你更早被打断。
--
-- 关于死亡：参考版和叶脚本在这类游戏里同样会死（用户实测），
-- 所以死亡不是本脚本独有的问题。参考版的优势是【先把所有人甩完再死】，
-- v8 就是把这个结构搬过来。

-- 判据：瞬时速度（VelGoal 500）。目标是把对面甩出去。
--
-- v7 是把两处【我自己加的、反而害人的东西】退回去：
--
-- 【1】FallenPartsDestroyHeight 不再还原 —— 这是"甩完第一个人之后就死"的真正原因
--     参考版那行 workspace.FallenPartsDestroyHeight = getgenv().FPDH 里的
--     getgenv().FPDH 从没被赋过值，也就是它其实执行失败了 ——
--     于是参考版的销毁高度永远停在 NaN，全程受保护。
--     v6 把这个"bug"修正成正确还原，等于每次甩完就撤掉保护，
--     而人当时还带着余速在飞，掉下去就被销毁 = 死。
--     现在跟参考版一致：改成 NaN 之后不再还原（纯本地属性，不影响别人）。
--
-- 【2】善后落点退回"直接记你站的这一格"
--     v6 改成了往下打 500 格射线的命中点。在平台/屋顶/树上时，
--     射线打到的是脚下很远的地面，善后会把你传到那里去，比原来更危险。
--     v1 和参考版都是直接记 RootPart.CFrame。
--
-- 保留的（这些经测试确认有效）：
--   不写对方的速度（v5 起；参考版和落叶 Pro 也都不写）
--   头/根距离检测 —— 布娃娃目标改用 Head 当支点
--   分支条件 < 50、else 分支 10 次 FPos —— 对齐参考版
--   退出条件含 THumanoid.Sit
--   一行结果提示 + pcall 防 Flinging 卡死

-- 判据：瞬时速度（与原版一致，VelGoal 500）。目标是把对面甩出去，不观察过程。
--
-- v6 相对 v5 的改动，全部来自对照 SkidFling 原始版（AnthonyIsntHere，pastebin zqyDSUWX）：
--
-- 【1】掉出地图销毁保护 —— 直接针对"还是会死"
--     workspace.FallenPartsDestroyHeight = 0/0   (NaN)
--     甩飞把人以极高速度甩出地图，落到销毁高度以下部件就被销毁 = 死亡。
--     NaN 参与的比较永远为 false，销毁判定就永不成立。
--     参考版结束时恢复到 getgenv().FPDH，但那个值从没被赋过 —— 它的 bug，这里修正：
--     开头存下真实值，结束时还原。
--
-- 【2】头/根距离检测
--     角色被布娃娃化后 RootPart 会掉在原地，真正在动的是 Head，
--     这时必须用 Head 当支点才甩得动。参考版：两件都有的情况下比较两者距离。
--
-- 【3】分支条件对齐参考版
--     参考版是 if BasePart.Velocity.Magnitude < 50 then（静止/慢速走旋转分支）
--     之前这份脚本写的是 > 1，语义反了。
--
-- 【4】else 分支从 6 次 FPos 补成参考版的 10 次
--
-- 【5】退出条件补上目标坐下（THumanoid.Sit）
--
-- 仍然保留：不写对方的速度（v5 已删，这是"还会死"的另一半原因）、
--          善后落点用射线打地面、OldPos 只在站定时更新、一行结果提示、pcall 防卡死。

-- 判据：瞬时速度（与原版一致，VelGoal 500）。目标就是把对面甩出去，不观察过程。
--
-- v5 相对 v4 的两处改动，都来自对照其它脚本源码：
--
-- 【1】删掉"双向冲量"（向对方写 Velocity/RotVelocity）—— 这是死亡的原因。
--     对照落叶 Pro（通用.lua 的「甩飞所有人」）和原版甩飞：
--       落叶 Pro：bv.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
--                 lr.CFrame = CFrame.new(bp.Position) * ...
--                 —— 从头到尾【只动自己】，一次都没碰对方的速度
--       原版甩飞：也是只在自己的 RootPart 上写速度
--     只有我 v3 加的"双向冲量"会去写对方的 Velocity/RotVelocity，
--     而一旦你拿到了对方的物理权限，那个 9e7/9e8 就是真的生效的 ——
--     对方连同贴身在一起的你被一起弹飞，人就死了。
--     注：mock 测试里这条冲量因为"没拿到物理权限"一直被服务器丢弃，
--     所以模拟里量不出它的危害，只有真机上会炸。
--
-- 【2】善后落点改成"射线打到地面"（落叶 Pro 的做法）。
--     只记脚下坐标有个坑：跳跃最高点时速度接近 0，会被判成"站定"，
--     半空那个点就成了要回去的地方。射线打地面能避免。

-- 判据仍是【瞬时速度】：对方速度一超过 VelGoal 就收手。
--
-- v4 修的是 v3 引入的一个 bug（同时也是"人很容易死"的元凶）：
--   v3 把 OldPos 改成了"每次甩飞都记录当前位置"。但原版那个
--       if RootPart.Velocity.Magnitude < 50 then OldPos = RootPart.CFrame end
--   是有意为之 —— 只在你【站定】时记一个安全落点。
--   改成每次都记之后，第二次甩飞时你人还在半空高速飞，OldPos 就成了半空中的点，
--   善后逻辑直接把你传过去 → 摔死。摔死后角色反复重建，后面的甩飞自然就"没甩动"了。
--
-- v4 的两处改动：
--   1. OldPos 恢复原版条件（只在自身速度 < 50 时记录），并补首次为空时的兜底
--   2. 整个甩飞过程包 pcall。以前中途一旦报错，Flinging 会永久卡在 true，
--      之后每次甩飞都会被最前面那句 if Flinging then return end 直接挡掉
--      —— 这正是"只有前几个有效、后面全没反应"的另一个成因
local FLING = {
    VelGoal = 500,    -- 对方速度超过这个值就算甩动，收手（与原版一致）
    MaxTime = 2.0,    -- 硬上限（与原版一致）
    Report  = true,   -- 甩完弹一行结果
}

local function SkidFlingInner(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character

    if not (Character and Humanoid and RootPart and TCharacter) then
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
        return
    end

    -- 掉出地图销毁保护：甩飞会把人（和贴在一起的你）以极高速度甩出地图，
    -- 一旦落到 workspace.FallenPartsDestroyHeight 以下，部件会被销毁 = 死亡。
    -- 参考版的做法是把它设成 NaN —— NaN 参与的比较永远为 false，销毁判定就永不成立。
    -- 注意参考版这里有个 bug：它结束时恢复到 getgenv().FPDH，但那个值从没被赋值过。
    -- 这里改成在开头存下真实值，结束时还原。
    -- 掉出地图销毁保护。设成 NaN 后 y < NaN 永远为 false，
    -- "掉到销毁高度以下就销毁部件"这条判定永不成立，人和目标不会因为掉出地图而死。
    --
    -- 【关键】这里【不还原】。参考版写的是 workspace.FallenPartsDestroyHeight = getgenv().FPDH，
    -- 而 getgenv().FPDH 从没被赋过值 —— 那一行其实是执行失败的，
    -- 所以参考版的销毁高度永远停在 NaN，全程受保护。
    -- v6 曾经把它"修正"成正确还原原值，结果就是：【每次甩完保护就失效】，
    -- 而人这时还带着甩飞的余速在飞 → 掉下去 → 部件被销毁 → 死。
    -- 症状就是"甩完第一个人之后就死"。所以这里跟参考版保持一致，改了就不还原。
    -- FallenPartsDestroyHeight 是纯本地属性，不影响服务器和其它玩家。
    pcall(function()
        if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
            workspace.FallenPartsDestroyHeight = 0 / 0
        end
    end)

    local Dead = false
    local DeadConn
    DeadConn = LocalPlayer.CharacterAdded:Connect(function()
        Dead = true
        if DeadConn then DeadConn:Disconnect() DeadConn = nil end
    end)

    -- 只在站定（速度很小）时更新安全落点 —— 这是原版的行为，别改。
    -- 否则连续甩飞时会把你半空中的位置记成"要回去的地方"，善后等于把你摔死。
    -- 直接记你站的这一格 —— v1 和参考版都是这么做的，别改。
    -- 试过改成"往下打射线找地面"，结果是在平台上/屋顶上会被传到地面去，反而更危险。
    if RootPart.Velocity.Magnitude < 50 then
        OldPos = RootPart.CFrame
    elseif not OldPos then
        OldPos = RootPart.CFrame   -- 兜底：第一次甩飞时若已在移动，至少有个记录
    end

    if Camera then
        Camera.CameraSubject = THead or Handle or THumanoid
    end

    local startPos = victimPart.Position

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

    end

    local function SFBasePart(BasePart)
        local Time = tick()
        local Angle = 0
        repeat
            if Dead or not BasePart or not BasePart.Parent or not RootPart or not RootPart.Parent then break end
            if not TRootPart or not TRootPart.Parent or not THumanoid or THumanoid.Health <= 0 then break end

            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100
                local move = THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25
                FPos(BasePart, CFrame.new(0, 1.5, 0) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + move, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until BasePart.Velocity.Magnitude > FLING.VelGoal
            or not BasePart.Parent or Dead or THumanoid.Sit or tick() > Time + FLING.MaxTime
    end

    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    pcall(function()
        -- 头/根距离检测（学自参考版）：角色被布娃娃化后 RootPart 会掉在原地，
        -- 真正在动的是 Head。这时必须用 Head 当支点，否则甩不动。
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end
    end)

    pcall(function() BV:Destroy() end)
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)

    local dist = moved()
    local stillThere = victimPart.Parent ~= nil

    if Camera then
        local newHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if newHum then Camera.CameraSubject = newHum end
    end

    -- 善后：回到那个"站定时记下的"安全落点
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

    if DeadConn then pcall(function() DeadConn:Disconnect() end) DeadConn = nil end

    if FLING.Report then
        local msg
        if not stillThere then
            msg = "甩出去了（对方部件已消失）"
        elseif dist >= 30 then
            msg = string.format("甩飞成功，位移 %.0f 米", dist)
        elseif dist >= 5 then
            msg = string.format("只弹了一下，位移 %.0f 米", dist)
        else
            msg = "没甩动"
        end
        local key = TargetPlayer.Name .. "|" .. msg
        if not AlreadyNotified[key] then
            AlreadyNotified[key] = true
            Notify("甩飞 " .. TargetPlayer.Name, msg, 2)
        end
    end
end

-- 外层包一层 pcall：以前中途一旦报错，Flinging 会永久卡在 true，
-- 之后每次甩飞都会被最前面的判断挡掉（表现就是"只有前几个有效"）。
-- 这里保证无论成功失败，Flinging 一定被复位。
local function SkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == LocalPlayer then return end
    if Flinging then return end
    Flinging = true
    local ok, err = pcall(SkidFlingInner, TargetPlayer)
    Flinging = false
    if not ok then
        pcall(function() Notify("甩飞", "本次出错已跳过", 2) end)
        pcall(function() warn("[甩飞] " .. tostring(err)) end)
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
            -- 只在角色确实不存在时等一等。
            -- 原来还带 selfHum.Health <= 0 —— 那会让人刚断气就整轮空转，后面的目标都甩不到。
            if not selfChar or not selfHum then
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

                -- 同样一口气甩完（借鉴 SkidFling 原始版）。
                -- 【不再】检查自己的血量来决定跳不跳过 —— 参考版也不检查。
                -- 检查了反而会让人刚断气就整轮什么都不做，后面的目标一个都甩不到。
                for _, target in ipairs(list) do
                    if not FlingLoop then break end
                    if typeof(target) == "Instance" and target:IsA("Player") and target.Parent then
                        SkidFling(target)
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
            -- 一口气甩完：中间不等待、不检查自己血量。
            -- 借鉴 SkidFling 原始版的写法：
            --     for _,x in next, Players:GetPlayers() do SkidFling(x) end
            -- SkidFling 本身是同步的（内部 task.wait() 会让出，跑完才返回），
            -- 所以这里直接顺序调用就已经是「一个接一个」，
            -- 不需要 repeat task.wait() until not Flinging，也不需要 task.wait(0.1)。
            -- 那些等待只会让你更早被打断，甩不到后面的人。
            for _, p in ipairs(list) do
                if p ~= LocalPlayer and typeof(p) == "Instance" then
                    SkidFling(p)
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

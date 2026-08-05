-- 范围脚本（两种放大方式，均为真实部件放大）
-- 1. 普通部件放大：部件按倍率放大，保留原外观
-- 2. 半透明方框放大（BS 风格）：固定放大根部件，统一改成正方形方块，半透明红色霓虹
if getgenv().__RANGE_ENLARGE_LOADED then return end
getgenv().__RANGE_ENLARGE_LOADED = true

local Tab = (getgenv().Tabs and getgenv().Tabs.RangeTab) or getgenv().SutureRangeTab
if not Tab then
    warn("[RangeEnlarge] 未找到 getgenv().Tabs.RangeTab，请先在主脚本赋值")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Enable = false,
    TargetMode = "全部",
    PlayerMode = "半透明方框放大",  -- 默认方框模式，一眼可见
    Scale = 1.8,            -- 范围大小（两种方式共用，1~10，默认 1.8）
    Transparency = 0.7,     -- 半透明方框模式的透明度
    PhysicalCollide = false,-- 近战物理碰撞
    TeamCheck = false,      -- 队友检测：开启后跳过同队玩家
    Parts = {"身体"}        -- 普通放大默认部位；半透明方框模式固定用根部件
}

local State = {
    originals = {},   -- 快照（恢复后即清空）
    enlarged = {},    -- 当前已放大的模型
    pending = {},     -- 首次看到目标的 os.clock() 时间（等尺寸稳定再快照）
    npcList = {},
    lastNpcUpdate = 0,
    refreshQueued = false
}

-- 部件分组（兼容 R6/R15 命名）
local PART_GROUPS = {
    ["头部"] = { "Head", "head" },
    ["身体"] = { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "RootPart", "HumanoidRoot", "Body", "Chest", "Hip" },
    ["根部件"] = { "HumanoidRootPart", "RootPart", "HumanoidRoot" },
    ["左臂"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    ["右臂"] = { "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
    ["左腿"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
    ["右腿"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}

local function getCharacterRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChildWhichIsA("BasePart")
end

-- 更宽松的 NPC 判定（递归找 Humanoid / AnimationController）
local function isNpcModel(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
                  or model:FindFirstChildWhichIsA("Humanoid", true)
    local anim = model:FindFirstChildOfClass("AnimationController")
              or model:FindFirstChild("AnimationController", true)

    local root = model:FindFirstChild("HumanoidRootPart")
              or model.PrimaryPart
              or model:FindFirstChildWhichIsA("BasePart")

    return (humanoid ~= nil or anim ~= nil) and root ~= nil
end

local function isAllowed(model)
    if model == LocalPlayer.Character then return false end
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then
        if Config.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
            return false
        end
        return Config.TargetMode == "玩家" or Config.TargetMode == "全部"
    end
    return isNpcModel(model) and (Config.TargetMode == "NPC" or Config.TargetMode == "全部")
end

-- ============ 快照 / 恢复 ============
local function snapshotPart(part)
    if not State.originals[part] then
        local okM, mass = pcall(function()
            return part:GetMass()
        end)
        State.originals[part] = {
            Size = part.Size,
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
            Massless = part.Massless,
            Mass = okM and mass or nil,
            PhysProps = part.CustomPhysicalProperties,
            Material = part.Material,
            Color = part.Color
        }
    end
end

local function restorePart(part)
    local old = State.originals[part]
    if old and part and part.Parent then
        pcall(function()
            part.Size = old.Size
            part.Transparency = old.Transparency
            part.CanCollide = old.CanCollide
            part.Massless = old.Massless
            part.CustomPhysicalProperties = old.PhysProps
            part.Material = old.Material
            part.Color = old.Color
        end)
    end
end

local function restoreCharacter(model)
    if not model then return end
    State.pending[model] = nil
    for part, _ in pairs(State.originals) do
        if (not part.Parent) or model:IsAncestorOf(part) then
            restorePart(part)
            State.originals[part] = nil
        end
    end
    State.enlarged[model] = nil
end

local function restoreAll()
    for part, _ in pairs(State.originals) do
        restorePart(part)
    end
    State.originals = {}
    State.enlarged = {}
    State.pending = {}
end

-- ============ 部件选择 ============
local function hasPart(name)
    for _, v in ipairs(Config.Parts) do
        if v == name then return true end
    end
    return false
end

local function getSelectedParts(character)
    -- 半透明方框模式固定放大根部件，部位选择只对普通放大生效
    if Config.PlayerMode == "半透明方框放大" then
        local root = getCharacterRoot(character)
        if root then return { root } end
        return {}
    end

    local parts = {}
    local added = {}

    local function add(part)
        if part and part:IsA("BasePart") and not added[part] then
            table.insert(parts, part)
            added[part] = true
        end
    end

    if hasPart("全部") then
        for _, p in ipairs(character:GetDescendants()) do
            add(p)
        end
        return parts
    end

    for groupName, names in pairs(PART_GROUPS) do
        if hasPart(groupName) then
            for _, name in ipairs(names) do
                add(character:FindFirstChild(name))
            end
        end
    end

    -- 兜底：选了身体但标准部件都没找到时
    if hasPart("身体") and #parts == 0 then
        add(character.PrimaryPart)
        add(character:FindFirstChildWhichIsA("BasePart"))
    end

    return parts
end

-- ============ 放大：两种模式都用真实部件 ============
local function applyEnlarge(character)
    local firstApply = not State.enlarged[character]
    local parts = getSelectedParts(character)
    for _, part in ipairs(parts) do
        if not part or not part.Parent then continue end
        snapshotPart(part)
        local old = State.originals[part]
        if not old then continue end
        pcall(function()
            local targetSize, targetTransparency, targetMaterial, targetColor
            if Config.PlayerMode == "普通部件放大" then
                -- 普通放大：按倍率放大，保留原外观
                targetSize = old.Size * Config.Scale
                targetTransparency = old.Transparency
                targetMaterial = old.Material
                targetColor = old.Color
            else
                -- 半透明方框放大（BS 风格）：统一改成正方形方块，半透明红色霓虹
                local s = math.max(old.Size.X, old.Size.Y, old.Size.Z) * Config.Scale
                targetSize = Vector3.new(s, s, s)
                targetTransparency = Config.Transparency
                targetMaterial = Enum.Material.Neon
                targetColor = Color3.fromRGB(255, 0, 0)
            end

            -- 只在值不同时才写入，避免每帧反复覆盖（防巨大/闪烁）
            if part.Size ~= targetSize then part.Size = targetSize end
            if part.Transparency ~= targetTransparency then part.Transparency = targetTransparency end
            if part.Material ~= targetMaterial then part.Material = targetMaterial end
            if part.Color ~= targetColor then part.Color = targetColor end
            if part.CanCollide ~= Config.PhysicalCollide then part.CanCollide = Config.PhysicalCollide end
            if not part.CanQuery then part.CanQuery = true end
            if not part.CanTouch then part.CanTouch = true end

            -- 首次放大时保持总质量与原部件一致（密度按体积反比调小），
            -- 钩子拉人等物理效果不受影响
            if firstApply then
                local oldVol = old.Size.X * old.Size.Y * old.Size.Z
                local newVol = targetSize.X * targetSize.Y * targetSize.Z
                if old.Mass and old.Mass > 0 and oldVol > 0 and newVol > 0 then
                    local density = old.Mass / newVol
                    if old.PhysProps then
                        part.CustomPhysicalProperties = PhysicalProperties.new(
                            density,
                            old.PhysProps.Friction,
                            old.PhysProps.Elasticity,
                            old.PhysProps.FrictionWeight,
                            old.PhysProps.ElasticityWeight
                        )
                    else
                        part.CustomPhysicalProperties = PhysicalProperties.new(density, 0.3, 0.5)
                    end
                end
            end
        end)
    end
end

-- 每帧处理单个目标：只做状态变化，放大不每帧重写
local function processTarget(model)
    if not Config.Enable or not model or not model.Parent then return end

    local eligible = isAllowed(model)

    if eligible then
        if not State.enlarged[model] then
            -- 新角色先等 0.5 秒再快照放大，避免把出生瞬间的临时大尺寸当原始尺寸；
            -- 用每帧计时而不是 task.delay，防止延迟回调不执行导致漏放大
            if not State.pending[model] then
                State.pending[model] = os.clock()
            else
                local rootReady = Config.PlayerMode ~= "半透明方框放大" or getCharacterRoot(model) ~= nil
                if not rootReady then
                    -- 根部件还没出现，重新计时，等它出现并稳定后再放大
                    State.pending[model] = os.clock()
                elseif os.clock() - State.pending[model] >= 0.5 then
                    State.pending[model] = nil
                    applyEnlarge(model)
                    State.enlarged[model] = true
                end
            end
        end
    elseif State.enlarged[model] or State.pending[model] then
        State.pending[model] = nil
        if State.enlarged[model] then
            restoreCharacter(model)
        end
    end
end

-- NPC 列表：增量收集为主，全量扫描 3 秒兜底
local function updateNpcList()
    local now = os.clock()
    if now - State.lastNpcUpdate < 3 then return end
    State.lastNpcUpdate = now

    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isNpcModel(obj) then
            table.insert(list, obj)
        end
    end
    State.npcList = list
end

local function rebuildAll()
    restoreAll()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            processTarget(plr.Character)
        end
    end
    updateNpcList()
    for _, npc in ipairs(State.npcList) do
        processTarget(npc)
    end
end

local function queueRefresh()
    if State.refreshQueued then return end
    State.refreshQueued = true
    task.defer(function()
        task.wait(0.05)
        State.refreshQueued = false
        if Config.Enable then
            rebuildAll()
        else
            restoreAll()
        end
    end)
end

-- 主循环：状态处理每帧跑，已放大目标每帧锁定尺寸（值相同则不写入）
RunService.Heartbeat:Connect(function()
    if not Config.Enable then return end

    if os.clock() - State.lastNpcUpdate >= 3 then
        updateNpcList()
    end

    -- 每帧锁定已放大的目标：游戏/服务器把尺寸改大后，下一帧立刻改回，防巨大
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and State.enlarged[plr.Character] then
            pcall(applyEnlarge, plr.Character)
        end
    end
    for _, npc in ipairs(State.npcList) do
        if State.enlarged[npc] then
            pcall(applyEnlarge, npc)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            pcall(processTarget, plr.Character)
        end
    end

    for _, npc in ipairs(State.npcList) do
        pcall(processTarget, npc)
    end
end)

-- 新生成的 NPC 实时补充
workspace.DescendantAdded:Connect(function(obj)
    if not Config.Enable then return end
    if obj:IsA("Model") and isNpcModel(obj) then
        table.insert(State.npcList, obj)
        processTarget(obj)
    end
end)

-- ============ UI ============
Tab:Toggle({
    Title = "主开关",
    Value = false,
    Callback = function(v)
        Config.Enable = v
        if v then
            queueRefresh()
        else
            restoreAll()
        end
    end
})

Tab:Space()

Tab:Dropdown({
    Title = "放大对象",
    Values = {"玩家", "NPC", "全部"},
    Value = Config.TargetMode,
    Callback = function(v)
        Config.TargetMode = v
        queueRefresh()
    end
})

Tab:Toggle({
    Title = "队友检测",
    Desc = "开启后跳过同队玩家（只影响玩家目标，NPC 不受影响）",
    Value = Config.TeamCheck,
    Callback = function(v)
        Config.TeamCheck = v
        queueRefresh()
    end
})

Tab:Dropdown({
    Title = "放大方式",
    Values = {"普通部件放大", "半透明方框放大"},
    Value = Config.PlayerMode,
    Callback = function(v)
        Config.PlayerMode = v
        queueRefresh()
    end
})

Tab:Dropdown({
    Title = "放大部位（可多选）",
    Desc = "仅普通部件放大模式生效，半透明方框模式固定放大根部件",
    Values = {"头部", "身体", "左臂", "右臂", "左腿", "右腿", "全部"},
    Value = Config.Parts,
    Multi = true,
    Callback = function(v)
        Config.Parts = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "范围大小",
    Desc = "普通部件放大和半透明方框放大共用，最低 1，最高 10",
    Step = 0.1,
    Value = { Min = 1, Max = 10, Default = Config.Scale },
    Callback = function(v)
        Config.Scale = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "透明度",
    Desc = "半透明方框模式生效，0 全透明，1 不透明",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = Config.Transparency },
    Callback = function(v)
        Config.Transparency = v
        if Config.PlayerMode == "半透明方框放大" then
            for part, _ in pairs(State.originals) do
                if part and part.Parent then
                    part.Transparency = v
                end
            end
        end
    end
})

Tab:Toggle({
    Title = "物理碰撞（近战命中）",
    Desc = "开启后武器实体碰到也算命中，但会挡人",
    Value = Config.PhysicalCollide,
    Callback = function(v)
        Config.PhysicalCollide = v
        for part, _ in pairs(State.originals) do
            if part and part.Parent then
                part.CanCollide = v
            end
        end
    end
})

print("[RangeEnlarge] 范围脚本加载完成")

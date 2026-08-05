-- 部件放大：把选中的真实部件放大成可调大小的红色半透明立方体（真实命中体积）
-- 半透明方框：生成独立透明块框住目标（同样真实可命中）
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
    PlayerMode = "部件放大",
    Range = 150,            -- 有效距离
    CubeSize = 10,          -- 立方体边长（自由调节，最低 10）
    Transparency = 0.7,     -- 统一透明度
    PhysicalCollide = false,-- 近战物理碰撞
    Parts = {"头部"}        -- 多选部件
}

local State = {
    originals = {},   -- 部件放大模式的快照（恢复后即清空）
    enlarged = {},    -- 当前已放大的模型
    boxes = {},       -- 半透明方框模式：模型 -> 透明块
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

local function getDistanceToLocal(character)
    local myRoot = LocalPlayer.Character and getCharacterRoot(LocalPlayer.Character)
    local theirRoot = getCharacterRoot(character)
    if not myRoot or not theirRoot then return math.huge end
    return (myRoot.Position - theirRoot.Position).Magnitude
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
        return Config.TargetMode == "玩家" or Config.TargetMode == "全部"
    end
    return isNpcModel(model) and (Config.TargetMode == "NPC" or Config.TargetMode == "全部")
end

-- ============ 快照 / 恢复（部件放大模式） ============
local function snapshotPart(part)
    if not State.originals[part] then
        State.originals[part] = {
            Size = part.Size,
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
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
            part.Material = old.Material
            part.Color = old.Color
        end)
    end
end

local function restoreCharacter(model)
    if not model then return end
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
end

-- ============ 半透明方框模式：独立透明块（真实命中体积） ============
local function getPrimaryPart(character)
    local hasHead = false
    for _, v in ipairs(Config.Parts) do
        if v == "头部" then
            hasHead = true
            break
        end
    end
    if hasHead then
        local head = character:FindFirstChild("Head") or character:FindFirstChild("head")
        if head then return head end
    end
    return getCharacterRoot(character)
end

local function updateBox(box, model)
    local part = getPrimaryPart(model)
    if not part then return end

    box.CFrame = part.CFrame
    box.Size = Vector3.new(Config.CubeSize, Config.CubeSize, Config.CubeSize)
    box.Transparency = Config.Transparency
    box.Color = Color3.fromRGB(255, 0, 0)
    box.CanCollide = Config.PhysicalCollide
end

local function createBox(model)
    local part = getPrimaryPart(model)
    if not part then return end

    local ok, box = pcall(function()
        local b = Instance.new("Part")
        b.Name = "RangeEnlargeBox"
        b.Anchored = true
        b.CanCollide = Config.PhysicalCollide
        b.CanQuery = true
        b.CanTouch = true
        b.Material = Enum.Material.Neon
        b.Transparency = Config.Transparency
        b.Color = Color3.fromRGB(255, 0, 0)
        b.Size = Vector3.new(Config.CubeSize, Config.CubeSize, Config.CubeSize)
        b.Parent = model
        return b
    end)
    if ok and box then
        State.boxes[model] = box
        updateBox(box, model)
    end
end

local function destroyBox(model)
    local box = State.boxes[model]
    if box then
        pcall(function() box:Destroy() end)
    end
    State.boxes[model] = nil
end

local function destroyAllBoxes()
    for model, box in pairs(State.boxes) do
        if box then
            pcall(function() box:Destroy() end)
        end
    end
    State.boxes = {}
end

-- ============ 部件选择 ============
local function hasPart(name)
    for _, v in ipairs(Config.Parts) do
        if v == name then return true end
    end
    return false
end

local function getSelectedParts(character)
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

-- ============ 部件放大模式：BS 风格，选中部件变成真实大立方体 ============
local function applyEnlarge(character)
    local parts = getSelectedParts(character)
    for _, part in ipairs(parts) do
        snapshotPart(part)
        local old = State.originals[part]
        if not old then continue end
        pcall(function()
            part.Size = Vector3.new(Config.CubeSize, Config.CubeSize, Config.CubeSize)
            part.Transparency = Config.Transparency
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(255, 0, 0)
            part.CanCollide = Config.PhysicalCollide
            part.CanQuery = true
            part.CanTouch = true
        end)
    end
end

-- 每帧处理单个目标：只做状态变化时的恢复/创建，放大按帧锁定
local function processTarget(model)
    if not Config.Enable or not model or not model.Parent then
        if model then destroyBox(model) end
        return
    end

    local eligible = isAllowed(model) and getDistanceToLocal(model) <= Config.Range

    if Config.PlayerMode == "半透明方框" then
        local box = State.boxes[model]
        if eligible then
            if not box then
                createBox(model)
            else
                updateBox(box, model)
            end
        elseif box then
            destroyBox(model)
        end
    else
        if eligible then
            applyEnlarge(model)
            State.enlarged[model] = true
        elseif State.enlarged[model] then
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
    destroyAllBoxes()

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
            destroyAllBoxes()
        end
    end)
end

-- 主循环
RunService.Heartbeat:Connect(function()
    if not Config.Enable then return end

    if os.clock() - State.lastNpcUpdate >= 3 then
        updateNpcList()
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
        task.delay(0.15, function()
            if obj.Parent and isAllowed(obj) then
                processTarget(obj)
            end
        end)
    end
end)

-- ============ UI ============
local mainToggle = Tab:Toggle({
    Title = "主开关",
    Value = false,
    Callback = function(v)
        Config.Enable = v
        if v then
            queueRefresh()
        else
            restoreAll()
            destroyAllBoxes()
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

Tab:Dropdown({
    Title = "放大部位（可多选）",
    Values = {"头部", "身体", "根部件", "左臂", "右臂", "左腿", "右腿", "全部"},
    Value = Config.Parts,
    Multi = true,
    Callback = function(v)
        Config.Parts = v
        queueRefresh()
    end
})

Tab:Dropdown({
    Title = "放大方式",
    Values = {"部件放大", "半透明方框"},
    Value = Config.PlayerMode,
    Callback = function(v)
        Config.PlayerMode = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "有效范围",
    Step = 1,
    Value = { Min = 0, Max = 500, Default = Config.Range },
    Callback = function(v)
        Config.Range = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "范围大小",
    Desc = "立方体边长（studs），最低 10",
    Step = 1,
    Value = { Min = 10, Max = 2500, Default = Config.CubeSize },
    Callback = function(v)
        Config.CubeSize = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "透明度",
    Desc = "0 全透明，1 不透明，改动即时生效",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = Config.Transparency },
    Callback = function(v)
        Config.Transparency = v
        for part, _ in pairs(State.originals) do
            if part and part.Parent then
                part.Transparency = v
            end
        end
        for _, box in pairs(State.boxes) do
            if box then
                box.Transparency = v
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
        for _, box in pairs(State.boxes) do
            if box then
                box.CanCollide = v
            end
        end
    end
})

Tab:Button({
    Title = "恢复正常大小",
    Callback = function()
        Config.Enable = false
        restoreAll()
        destroyAllBoxes()
        if mainToggle and mainToggle.Set then
            pcall(mainToggle.Set, mainToggle, false)
        end
    end
})

print("[RangeEnlarge] 范围脚本加载完成")

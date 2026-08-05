-- 范围放大/范围方框（优化版）
-- 部件放大：修改原部件尺寸（锁定防重置）
-- 半透明方框：生成独立透明块框住目标，原部件完全不动
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
    Range = 150,
    Scale = 1.8,
    BoxTransparency = 0.55,
    Color = Color3.fromRGB(255, 60, 60),
    Parts = {"头部"}
}

local State = {
    originals = {},   -- 部件放大模式的快照（恢复后即清空）
    enlarged = {},    -- 当前已放大的模型
    boxes = {},       -- 半透明方框模式：模型 -> 透明块
    npcList = {},
    lastNpcUpdate = 0,
    refreshQueued = false
}

-- 兼容更多 NPC 的身体部件名
local bodyPartNames = {
    "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso",
    "RootPart", "HumanoidRoot", "Body", "Chest", "Hip"
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

-- ============ 部件放大模式：快照 / 恢复 ============
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

-- 恢复某个模型的所有快照部件，并清掉对应快照（不再残留）
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

-- ============ 半透明方框模式：独立透明块 ============
local function updateBox(box, model)
    local ok, cf, size = pcall(function()
        return model:GetBoundingBox()
    end)
    if not ok or not cf then return end

    box.CFrame = cf
    local s = math.max(size.X, size.Y, size.Z) * Config.Scale
    box.Size = Vector3.new(s, s, s)
    box.Transparency = Config.BoxTransparency
    box.Color = Config.Color
end

local function createBox(model)
    local ok, box = pcall(function()
        local b = Instance.new("Part")
        b.Name = "RangeEnlargeBox"
        b.Anchored = true
        b.CanCollide = false
        b.CanQuery = false
        b.CanTouch = false
        b.Material = Enum.Material.Neon
        b.Transparency = Config.BoxTransparency
        b.Color = Config.Color
        b.Size = Vector3.new(1, 1, 1)
        b.Parent = workspace
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

-- ============ 目标处理 ============
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

    if hasPart("头部") then
        add(character:FindFirstChild("Head"))
        add(character:FindFirstChild("head"))
    end

    if hasPart("身体") then
        for _, name in ipairs(bodyPartNames) do
            add(character:FindFirstChild(name))
        end
        if #parts == 0 then
            add(character.PrimaryPart)
            add(character:FindFirstChildWhichIsA("BasePart"))
        end
    end

    return parts
end

local function applyEnlarge(character)
    local parts = getSelectedParts(character)
    for _, part in ipairs(parts) do
        snapshotPart(part)
        local old = State.originals[part]
        if not old then continue end
        pcall(function()
            part.Size = old.Size * Config.Scale
            part.CanCollide = false
            part.CanQuery = true
        end)
    end
end

-- 每帧/每次变更处理单个目标：只做状态变化时的恢复/创建，放大按帧锁定
local function processTarget(model)
    if not Config.Enable or not model or not model.Parent then return end

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

-- NPC 列表：增量收集为主，全量扫描降频到 3 秒兜底
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

-- 配置变化后的完整重建（已节流）
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

-- 主循环：只处理玩家 + NPC 列表，不再每帧全量恢复
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
    Values = {"头部", "身体"},
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
    Title = "放大倍率",
    Step = 0.1,
    Value = { Min = 1, Max = 10, Default = Config.Scale },
    Callback = function(v)
        Config.Scale = v
        queueRefresh()
    end
})

Tab:Slider({
    Title = "方框透明度",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = Config.BoxTransparency },
    Callback = function(v)
        Config.BoxTransparency = v
        for _, box in pairs(State.boxes) do
            if box then
                box.Transparency = v
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

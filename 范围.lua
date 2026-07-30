if getgenv().__RANGE_ENLARGE_LOADED then return end
getgenv().__RANGE_ENLARGE_LOADED = true

local Tab = getgenv().Tabs and getgenv().Tabs.RangeTab
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
    originals = {},
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
    local head = model:FindFirstChild("Head") or model:FindFirstChild("head")
    if head then restorePart(head) end
    for _, name in ipairs(bodyPartNames) do
        local p = model:FindFirstChild(name)
        if p then restorePart(p) end
    end
    -- 兜底恢复 PrimaryPart
    if model.PrimaryPart then restorePart(model.PrimaryPart) end
end

local function restoreAll()
    for part, _ in pairs(State.originals) do
        restorePart(part)
    end
end

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
        -- 如果一个标准部件都没找到，就用 PrimaryPart 或任意 BasePart 兜底
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
            if Config.PlayerMode == "部件放大" then
                part.Size = old.Size * Config.Scale
                part.Transparency = old.Transparency
                part.Material = old.Material
                part.Color = old.Color
            else
                -- 半透明方框：强制立方体 + Neon
                local s = math.max(old.Size.X, old.Size.Y, old.Size.Z) * Config.Scale
                part.Size = Vector3.new(s, s, s)
                part.Transparency = Config.BoxTransparency
                part.Material = Enum.Material.Neon
                part.Color = Config.Color
            end
            part.CanCollide = false
            part.CanQuery = true
        end)
    end
end

local function refreshCharacter(model)
    if not Config.Enable or not model or not model.Parent then return end

    if not isAllowed(model) or getDistanceToLocal(model) > Config.Range then
        restoreCharacter(model)
        return
    end

    applyEnlarge(model)
end

local function updateNpcList()
    local now = os.clock()
    if now - State.lastNpcUpdate < 0.8 then return end
    State.lastNpcUpdate = now

    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isNpcModel(obj) then
            table.insert(list, obj)
        end
    end
    State.npcList = list
end

local function refreshAll()
    restoreAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            refreshCharacter(plr.Character)
        end
    end
    updateNpcList()
    for _, npc in ipairs(State.npcList) do
        refreshCharacter(npc)
    end
end

local function queueRefresh()
    if State.refreshQueued then return end
    State.refreshQueued = true
    task.defer(function()
        task.wait(0.05)
        State.refreshQueued = false
        if Config.Enable then
            refreshAll()
        else
            restoreAll()
        end
    end)
end

-- 主循环
RunService.Heartbeat:Connect(function()
    if not Config.Enable then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            refreshCharacter(plr.Character)
        end
    end

    updateNpcList()
    for _, npc in ipairs(State.npcList) do
        refreshCharacter(npc)
    end
end)

-- 新生成的 NPC 实时补充
workspace.DescendantAdded:Connect(function(obj)
    if not Config.Enable then return end
    if obj:IsA("Model") and isNpcModel(obj) then
        task.delay(0.15, function()
            if obj.Parent and isAllowed(obj) then
                refreshCharacter(obj)
            end
        end)
    end
end)

-- UI
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
    end
})

Tab:Button({
    Title = "恢复正常大小",
    Callback = function()
        Config.Enable = false
        restoreAll()
    end
})

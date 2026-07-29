-- 远程范围脚本（只负责功能，不创建UI窗口）
return function(Tab)
    if getgenv().__RANGE_ENLARGE_LOADED then return end
    getgenv().__RANGE_ENLARGE_LOADED = true

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

    local bodyPartNames = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}

    local function getCharacterRoot(character)
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    end

    local function getDistanceToLocal(character)
        local myRoot = LocalPlayer.Character and getCharacterRoot(LocalPlayer.Character)
        local theirRoot = getCharacterRoot(character)
        if not myRoot or not theirRoot then return math.huge end
        return (myRoot.Position - theirRoot.Position).Magnitude
    end

    local function isNpcModel(model)
        if not model or not model:IsA("Model") then return false end
        if Players:GetPlayerFromCharacter(model) then return false end
        return model:FindFirstChildOfClass("Humanoid") ~= nil or model:FindFirstChild("AnimationController") ~= nil
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
        local head = model:FindFirstChild("Head")
        if head then restorePart(head) end
        for _, name in ipairs(bodyPartNames) do
            local p = model:FindFirstChild(name)
            if p then restorePart(p) end
        end
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
        if hasPart("头部") then
            local head = character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                table.insert(parts, head)
            end
        end
        if hasPart("身体") then
            for _, name in ipairs(bodyPartNames) do
                local p = character:FindFirstChild(name)
                if p and p:IsA("BasePart") then
                    table.insert(parts, p)
                end
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
        if now - State.lastNpcUpdate < 1.2 then return end
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

    -- 把控件添加到主脚本传进来的 Tab 上
    Tab:Toggle({
        Title = "主开关",
        Value = false,
        Callback = function(v)
            Config.Enable = v
            if v then queueRefresh() else restoreAll() end
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
end

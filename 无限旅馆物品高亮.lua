local M = {}

local CoreGui = game:GetService("CoreGui")

local Running = false
local HighlightFolder = nil

local FillTransparency = 0.85
local OutlineTransparency = 0
local TextSize = 12

local ObjectIds = setmetatable({}, { __mode = "k" })
local NextId = 0

local function getId(obj)
    if not ObjectIds[obj] then
        NextId = NextId + 1
        ObjectIds[obj] = tostring(NextId)
    end

    return ObjectIds[obj]
end

local function getFolder()
    if HighlightFolder and HighlightFolder.Parent then
        return HighlightFolder
    end

    local old = CoreGui:FindFirstChild("SutureItemHighlights")
    if old then
        old:Destroy()
    end

    HighlightFolder = Instance.new("Folder")
    HighlightFolder.Name = "SutureItemHighlights"
    HighlightFolder.Parent = CoreGui

    return HighlightFolder
end

local function getServer()
    return workspace:FindFirstChild("Server")
end

local function getRoot()
    return getServer() or workspace
end

local function getLabelAdornee(obj)
    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end

        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("BasePart") then
                return v
            end
        end
    end

    return nil
end

local function makeHighlight(obj, prefix, color, text)
    if not obj then return end

    local folder = getFolder()
    local name = prefix .. "_" .. getId(obj)

    local old = folder:FindFirstChild(name)
    if old and old:IsA("Highlight") and old.Adornee == obj then
        return
    elseif old then
        old:Destroy()
    end

    local oldText = folder:FindFirstChild(name .. "_Text")
    if oldText then
        oldText:Destroy()
    end

    local h = Instance.new("Highlight")
    h.Name = name
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = FillTransparency
    h.OutlineTransparency = OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = true
    h.Parent = folder

    local adornee = getLabelAdornee(obj)
    if adornee then
        local bill = Instance.new("BillboardGui")
        bill.Name = name .. "_Text"
        bill.Adornee = adornee
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0, 95, 0, 20)
        bill.StudsOffset = Vector3.new(0, -2, 0)
        bill.Parent = folder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.25
        label.TextScaled = false
        label.TextSize = TextSize
        label.Font = Enum.Font.SourceSansBold
        label.Parent = bill
    end
end

local function cleanInvalid()
    local folder = getFolder()

    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Highlight") then
            if not obj.Adornee or obj.Adornee.Parent == nil then
                local text = folder:FindFirstChild(obj.Name .. "_Text")
                if text then
                    text:Destroy()
                end

                obj:Destroy()
            end
        elseif obj:IsA("BillboardGui") then
            if not obj.Adornee or obj.Adornee.Parent == nil then
                obj:Destroy()
            end
        end
    end
end

local function highlightSimpleObjects()
    local root = getRoot()

    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == "HideTansu" then
            makeHighlight(
                obj,
                "HideTansu",
                Color3.fromRGB(255, 255, 0),
                "柜子"
            )

        elseif obj.Name == "BoxBottom" and obj.Parent and obj.Parent.Name == "OfudaBox2" then
            makeHighlight(
                obj,
                "OfudaBox",
                Color3.fromRGB(0, 255, 255),
                "箱子"
            )

        elseif obj.Name == "Meshes/safe_Safe" then
            makeHighlight(
                obj,
                "Safe",
                Color3.fromRGB(0, 255, 0),
                "保险柜"
            )

        elseif obj.Name == "HintPaper" then
            makeHighlight(
                obj,
                "HintPaper",
                Color3.fromRGB(255, 170, 255),
                "提示纸"
            )

        elseif obj.Name == "hanging scroll_base" then
            makeHighlight(
                obj,
                "EvilRoom",
                Color3.fromRGB(255, 0, 0),
                "邪恶房间"
            )

        elseif obj.Name == "DollBlackHead" and obj:IsA("MeshPart") then
            makeHighlight(
                obj,
                "DollBlackHead",
                Color3.fromRGB(255, 80, 80),
                "洋娃娃头"
            )

        elseif obj.Name == "Zataku" then
            makeHighlight(
                obj,
                "Zataku",
                Color3.fromRGB(255, 140, 0),
                "桌子"
            )

        elseif obj.Name == "Dish" and obj:IsA("BasePart") then
            makeHighlight(
                obj,
                "Dish",
                Color3.fromRGB(240, 240, 240),
                "盘子"
            )

        elseif obj.Name == "dirty sheet" and obj:IsA("MeshPart") then
            makeHighlight(
                obj,
                "SacrificeBoard",
                Color3.fromRGB(170, 100, 40),
                "祭祀"
            )
        end
    end
end

local function highlightDolls()
    local server = getServer()
    if not server then return end

    local spawned = server:FindFirstChild("SpawnedItems")
    if not spawned then return end

    for _, obj in ipairs(spawned:GetDescendants()) do
        if obj:IsA("Model") then
            local hasHead = obj:FindFirstChild("DollHead", true)
            local hasTorso = obj:FindFirstChild("DollTorso", true)

            if hasHead and hasTorso then
                makeHighlight(
                    obj,
                    "Doll",
                    Color3.fromRGB(255, 105, 180),
                    "洋娃娃"
                )
            end
        end
    end
end

local function highlightTV()
    local root = getRoot()

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Model") then
            local hasBase0 = obj:FindFirstChild("base0", true)
            local hasBase02 = obj:FindFirstChild("base02", true)
            local hasPoint1 = obj:FindFirstChild("Point1", true)

            if hasBase0 and hasBase02 and hasPoint1 then
                makeHighlight(
                    obj,
                    "TV",
                    Color3.fromRGB(80, 170, 255),
                    "电视机"
                )
            end
        end
    end
end

local function highlightLighter()
    local root = getRoot()

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Model") then
            local hasOil = obj:FindFirstChild("oil", true)
            local hasMetal = obj:FindFirstChild("metal01", true)
            local hasBase01 = obj:FindFirstChild("base01", true)
            local hasBase02 = obj:FindFirstChild("base02", true)
            local hasBase04 = obj:FindFirstChild("base04", true)

            if hasOil and hasMetal and (hasBase01 or hasBase02 or hasBase04) then
                makeHighlight(
                    obj,
                    "Lighter",
                    Color3.fromRGB(0, 255, 120),
                    "打火机"
                )
            end
        end
    end
end

local function highlightPasswordBox()
    local root = getRoot()

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Model") then
            local hasBase = obj:FindFirstChild("base", true)
            local hasRope01 = obj:FindFirstChild("rope01", true)
            local hasRope02 = obj:FindFirstChild("rope02", true)
            local hasRopeSpawn = obj:FindFirstChild("RopeSpawnPoint", true)

            if hasBase and (hasRope01 or hasRope02 or hasRopeSpawn) then
                makeHighlight(
                    obj,
                    "PasswordBox",
                    Color3.fromRGB(255, 215, 0),
                    "密码箱"
                )
            end
        end
    end
end

local function scan()
    highlightSimpleObjects()
    highlightDolls()
    highlightTV()
    highlightLighter()
    highlightPasswordBox()
    cleanInvalid()
end

function M.Start()
    if Running then
        return
    end

    Running = true
    getFolder()

    task.spawn(function()
        while Running do
            pcall(scan)
            task.wait(1)
        end
    end)
end

function M.Stop()
    Running = false

    if HighlightFolder then
        HighlightFolder:Destroy()
        HighlightFolder = nil
    end
end

function M.IsRunning()
    return Running
end

return M

local M = {}

local CoreGui = game:GetService("CoreGui")

local Running = false
local HighlightFolder = nil
local Enabled = {}
local Registry = {}
local ObjectIds = setmetatable({}, { __mode = "k" })
local NextId = 0

local FillTransparency = 0.85
local OutlineTransparency = 0
local TextSize = 12

local function getId(obj)
    if not ObjectIds[obj] then
        NextId = NextId + 1
        ObjectIds[obj] = tostring(NextId)
    end
    return ObjectIds[obj]
end

local function getFolder()
    if HighlightFolder and HighlightFolder.Parent then return HighlightFolder end
    local old = CoreGui:FindFirstChild("SutureItemHighlights")
    if old then old:Destroy() end
    HighlightFolder = Instance.new("Folder")
    HighlightFolder.Name = "SutureItemHighlights"
    HighlightFolder.Parent = CoreGui
    return HighlightFolder
end

local function getServer()
    return workspace:FindFirstChild("Server")
end

local function getRooms()
    local server = getServer()
    if not server then return nil end
    local map = server:FindFirstChild("MapGenerated")
    if not map then return nil end
    return map:FindFirstChild("Rooms")
end

local function getSpawnedItems()
    local server = getServer()
    if not server then return nil end
    return server:FindFirstChild("SpawnedItems")
end

local function getLabelAdornee(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("BasePart") then return v end
        end
    end
    return nil
end

local function getGroupRegistry(group)
    Registry[group] = Registry[group] or setmetatable({}, { __mode = "k" })
    return Registry[group]
end

local function destroyRecord(record)
    if not record then return end
    if record.Highlight then pcall(function() record.Highlight:Destroy() end) end
    if record.Billboard then pcall(function() record.Billboard:Destroy() end) end
end

local function removeGroup(group)
    local reg = Registry[group]
    if not reg then return end
    for obj, record in pairs(reg) do
        destroyRecord(record)
        reg[obj] = nil
    end
end

local function makeBillboard(folder, name, group, adornee, text)
    local bill = Instance.new("BillboardGui")
    bill.Name = name .. "_Text"
    bill.Adornee = adornee
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 95, 0, 20)
    bill.StudsOffset = Vector3.new(0, -2, 0)
    bill:SetAttribute("Group", group)
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
    return bill
end

local function makeHighlight(group, obj, prefix, color, text)
    if not Enabled[group] or not obj or not obj.Parent then return end

    local reg = getGroupRegistry(group)
    local record = reg[obj]

    if record and record.Highlight and record.Highlight.Parent then
        local h = record.Highlight
        h.Adornee = obj
        h.Enabled = true
        h.FillTransparency = FillTransparency
        h.OutlineTransparency = OutlineTransparency
        return
    end

    destroyRecord(record)

    local folder = getFolder()
    local name = prefix .. "_" .. getId(obj)

    local h = Instance.new("Highlight")
    h.Name = name
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = FillTransparency
    h.OutlineTransparency = OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = true
    h:SetAttribute("Group", group)
    h.Parent = folder

    local bill = nil
    local adornee = getLabelAdornee(obj)
    if adornee then
        bill = makeBillboard(folder, name, group, adornee, text)
    end

    reg[obj] = { Highlight = h, Billboard = bill }
end

local function cleanInvalid()
    for group, reg in pairs(Registry) do
        for obj, record in pairs(reg) do
            if not obj or not obj.Parent or not record or not record.Highlight or not record.Highlight.Parent then
                destroyRecord(record)
                reg[obj] = nil
            end
        end
    end
end

local function anyEnabled()
    for _, v in pairs(Enabled) do
        if v then return true end
    end
    return false
end

local function scanRooms()
    local rooms = getRooms()
    if not rooms then return end

    for _, room in ipairs(rooms:GetChildren()) do
        local props = room:FindFirstChild("Props")

        -- workspace.Server.MapGenerated.Rooms.RoomF.Props.HideTansu
        if Enabled.Cabinet and props then
            local obj = props:FindFirstChild("HideTansu")
            if obj then makeHighlight("Cabinet", obj, "Cabinet", Color3.fromRGB(255, 255, 0), "柜子") end
        end

        -- workspace.Server.MapGenerated.Rooms.Room.Props.Safe["Meshes/safe_Safe"]
        if Enabled.Safe and props then
            local safe = props:FindFirstChild("Safe")
            local obj = safe and safe:FindFirstChild("Meshes/safe_Safe")
            if obj then makeHighlight("Safe", obj, "Safe", Color3.fromRGB(0, 255, 0), "保险柜") end
        end

        -- workspace.Server.MapGenerated.Rooms.Room.DialGimmick.DialShelf.base
        if Enabled.Box then
            local dial = room:FindFirstChild("DialGimmick")
            local shelf = dial and dial:FindFirstChild("DialShelf")
            local obj = shelf and shelf:FindFirstChild("base")
            if obj then makeHighlight("Box", obj, "DialShelfBox", Color3.fromRGB(0, 255, 255), "箱子") end
        end

        -- workspace.Server.MapGenerated.Rooms:GetChildren()[14].Props.TelevisionN
        if Enabled.TV and props then
            for _, obj in ipairs(props:GetChildren()) do
                local n = tostring(obj.Name)
                if n == "TelevisionN" or n == "TelevisionW" or n == "TelevisionE" or n == "TelevisionS" then
                    makeHighlight("TV", obj, "Television", Color3.fromRGB(80, 170, 255), "电视")
                end
            end
        end
    end

    for _, obj in ipairs(rooms:GetDescendants()) do
        if Enabled.HintPaper and obj.Name == "HintPaper" then
            makeHighlight("HintPaper", obj, "HintPaper", Color3.fromRGB(255, 170, 255), "提示纸")
        elseif Enabled.EvilRoom and obj.Name == "hanging scroll_base" then
            makeHighlight("EvilRoom", obj, "EvilRoom", Color3.fromRGB(255, 0, 0), "邪恶房间")
        elseif Enabled.Table and obj.Name == "Zataku" then
            makeHighlight("Table", obj, "Table", Color3.fromRGB(255, 140, 0), "桌子")
        elseif Enabled.Dish and obj.Name == "Dish" and obj:IsA("BasePart") then
            makeHighlight("Dish", obj, "Dish", Color3.fromRGB(240, 240, 240), "盘子")
        elseif Enabled.Sacrifice and obj.Name == "dirty sheet" and obj:IsA("MeshPart") then
            makeHighlight("Sacrifice", obj, "Sacrifice", Color3.fromRGB(170, 100, 40), "祭祀")
        elseif Enabled.Lighter and obj.Name == "oil" and obj:IsA("BasePart") then
            makeHighlight("Lighter", obj, "Lighter", Color3.fromRGB(0, 255, 120), "打火机")
        elseif Enabled.DollBlackHead and obj.Name == "DollBlackHead" and obj:IsA("MeshPart") then
            makeHighlight("DollBlackHead", obj, "DollBlackHead", Color3.fromRGB(255, 80, 80), "洋娃娃头")
        end
    end
end

local function scanSpawned()
    local spawned = getSpawnedItems()
    if not spawned then return end

    -- workspace.Server.SpawnedItems.OfudaBox2.BoxBottom
    if Enabled.Box then
        local box = spawned:FindFirstChild("OfudaBox2")
        local obj = box and box:FindFirstChild("BoxBottom")
        if obj then makeHighlight("Box", obj, "OfudaBox", Color3.fromRGB(0, 255, 255), "箱子") end
    end

    for _, obj in ipairs(spawned:GetDescendants()) do
        if Enabled.DollBlackHead and obj.Name == "DollBlackHead" and obj:IsA("MeshPart") then
            makeHighlight("DollBlackHead", obj, "DollBlackHead", Color3.fromRGB(255, 80, 80), "洋娃娃头")
        elseif Enabled.Lighter and obj.Name == "oil" and obj:IsA("BasePart") then
            makeHighlight("Lighter", obj, "Lighter", Color3.fromRGB(0, 255, 120), "打火机")
        end
    end

    if Enabled.Doll then
        for _, obj in ipairs(spawned:GetDescendants()) do
            if obj:IsA("Model") then
                local hasHead = obj:FindFirstChild("DollHead", true)
                local hasTorso = obj:FindFirstChild("DollTorso", true)
                if hasHead and hasTorso then
                    makeHighlight("Doll", obj, "Doll", Color3.fromRGB(255, 105, 180), "洋娃娃")
                end
            end
        end
    end
end

local function scan()
    scanRooms()
    scanSpawned()
    -- 密码箱没有精准路径，暂不处理，避免误高亮。
    cleanInvalid()
end

local function startLoop()
    if Running then return end
    Running = true
    task.spawn(function()
        while Running do
            pcall(scan)
            task.wait(1)
        end
    end)
end

function M.Set(key, state)
    Enabled[key] = state and true or false
    if state then
        getFolder()
        startLoop()
    else
        removeGroup(key)
        if not anyEnabled() then Running = false end
    end
end

function M.Enable(key)
    M.Set(key, true)
end

function M.Disable(key)
    M.Set(key, false)
end

function M.DisableAll()
    for key in pairs(Enabled) do
        Enabled[key] = false
        removeGroup(key)
    end
    Running = false
    if HighlightFolder then
        HighlightFolder:Destroy()
        HighlightFolder = nil
    end
end

function M.IsEnabled(key)
    return Enabled[key] == true
end

return M

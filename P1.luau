
--	Functions.Notify({Title = "Used For Notifications."})
-- 	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
-- 	Risky = Floor ~= "Mines" (Means it only works on mines)

local LoadStart = tick()

if shared.Hastelepasta then
    return 
end

shared.Hastelepasta = true


getgenv().Abysall = {
    Legit = true
}


local BaseUrl = "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/"

getgenv().Abysall = {
    Environment = loadstring(game:HttpGet(BaseUrl .. "Components/Environment.luau"))(),
    ESPLibrary = loadstring(game:HttpGet(BaseUrl .. "Components/ESP.luau"))(),
    ["16Notice"] = loadstring(game:HttpGet(BaseUrl .. "Components/16Notice.luau"))(),
    Legit = true
}

local Abysall = getgenv().Abysall

local function CloneReference(Object)
    if Abysall and Abysall.Environment.cloneref then
        return Abysall.Environment.cloneref(Object)
    end
    return Object
end

local Services = setmetatable({}, {
    __index = function(Self, Name)
        return CloneReference(game:GetService(Name))
    end
})

if Abysall.Environment.writefile and Abysall.Environment.readfile then
    if not Abysall.Environment.isfile("Abysall/UserData.json") then
        local Data = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }

        Abysall.Environment.writefile(
            "Abysall/UserData.json",
            Services.HttpService:JSONEncode(Data)
        )
    end

    local UserData = Abysall.Environment.readfile("Abysall/UserData.json")
    local Decoded = Services.HttpService:JSONDecode(UserData)

    if not Decoded.TotalExecutions then
        Decoded.TotalExecutions = 0
    end

    Decoded.TotalExecutions = Decoded.TotalExecutions + 1

    if not Decoded.UILibrary then
        Decoded.UILibrary = "Obsidian"
    end

    Abysall.TotalExecutions = Decoded.TotalExecutions
    Abysall.UILibrary = Decoded.UILibrary

    Abysall.Environment.writefile(
        "Abysall/UserData.json",
        Services.HttpService:JSONEncode(Decoded)
    )
end

Abysall.Interface = loadstring(game:HttpGet(
    BaseUrl .. "Components/Interface.luau"
))()

Abysall.Analytics = loadstring(game:HttpGet(
    BaseUrl .. "Components/Analytics.luau"
))()


Abysall.SavePath = "Doors/Game"

local Library = Abysall.Interface.Library
local SaveManager = Abysall.Interface.SaveManager
local ThemeManager = Abysall.Interface.ThemeManager

local Toggles = Library.Toggles
local Options = Library.Options

local function CloneReference(Object)
	if Abysall and Abysall.Environment.cloneref then
		return Abysall.Environment.cloneref(Object)
	end
	return Object
end

local Services = setmetatable({}, {
	__index = function(Self, Name)
		return CloneReference(game:GetService(Name))
	end
})



-- archives and stairwell locals
local TimeShowerSourceLabel
local TimeShowerToken = 0
local TimeShowerConnection
local BypassDronesStampedeConnection
local HonchoCorrectBoxConnection
local HonchoAutoDepositConnection
local HonchoESPObjects = {}
local HonchoProcessedRooms = {}
local HonchoDepositCache = {}
local AntiClosetTrash_Connection
local AntiRansom_Connection
local ForgetMeNotConnection
local ForgetMeNotRunning = false
local ForgetMeNotProcessing = {}
local ForgetMeNotNotified = {}
local WaterBypassConnection
local WaterParts = {}
local AlmaConnection
local AntiScribbles_Connection
local DroneConnection
local DroneWalkedIntoParents = {}
local OrbitDroppedItemsConnection
local OrbitDroppedItemsAngle = 0
local OrbitDroppedItemsLastTeleport = 0
local OrbitDroppedItemsPauseUntil = 0
local droppedItemsIntervalRunning = false
local Connections = {}



local Globals = {}
local Connections = {}
local ESPConnections = {}
local Groupboxes = {}
local FakePrompts = {}
local Functions = {}
local PartProperties = {}

local Objects = {
	Prompts = {},
	Objectives = {},
	Doors = {},
	HidingSpots = {},
	Entities = {},
	SeekObstructions = {},
	Items = {},
	Chests = {},
	Currency = {},
	Ladders = {},
	Misc = {},
	Obstructions = {},
	EventTriggers = {},
	JumpscareModules = {},
	SeekHighlights = {},
	EyestalkHighlights = {},
	SeekNodes = {},
	SeekDuckBoards = {},
	SeekBridges = {},
	PathLights = {}
}

Globals.IncompatibleMessage = "Your executor doesn't support this feature."

Functions.CheckCompatability = function(Array)
	for _, Name in Array do
		if not Abysall.Environment[Name] then
			return false
		end
	end
	return true
end



local LocalPlayer = Services.Players.LocalPlayer


local PortraitName = "MirrorRig_Portrait_" .. LocalPlayer.Name


local Entities = {
	["TV_Stand"] = {
		Alias = "Noise_TV",
		NotifyMessage = { Title = "Noise tv spawned.", Body = "Dont get near it" }
	},
	[PortraitName] = {
		Alias = "Portrait",
		NotifyMessage = { Title = "Portrait' has spawned.", Body = "Use him to duplicate items." }
	},
	["StemsEntity"] = {
	    Alias = 'Balls',
		NotifyMessage = { Title = "Balls", Body = "Balls."}
	},
	["NoiseModel"] = {
		Alias = 'Noise',
		NotifyMessage = { Title = "Entity 'Noise' has spawned.", Body = "Dont let it touch you." }
	},
	["Creak"] = {
		Alias = "Creak",
		NotifyMessage = { Title = "Entity 'Creak' has spawned.", Body = "Dont touch him." }
	},
	["DronesStampede"] = {
		Alias = "DronesStampede",
		NotifyMessage = { Title = "Entity 'Drones Stampede' has spawned.", Body = "Find a hiding spot." }
	},
	["TellerRig"] = {
		Alias = "Teller",
		NotifyMessage = { Title = "Entity 'Teller' has spawned.", Body = "Dont worry, hes only annoying." }
	},
	["Scribbles"] = {
		Alias = "Scribbles",
		NotifyMessage = { Title = "Entity 'Scribbles' has spawned.", Body = "Find a hiding spot." }
	},
	["BashMoving"] = {
		Alias = "Bash",
		NotifyMessage = { Title = "Entity 'Bash' has spawned.", Body = "Find a hiding spot."}
	},
	["RushMoving"] = {
		Alias = "Rush",
		NotifyMessage = { Title = "Entity 'Rush' has spawned.", Body = "Find a hiding spot." }
	},
	["AmbushMoving"] = {
		Alias = "Ambush",
		NotifyMessage = { Title = "Entity 'Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["Eyes"] = {
		Alias = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["Lookman"] = {
		Alias = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["BackdoorRush"] = {
		Alias = "Blitz",
		NotifyMessage = { Title = "Entity 'Blitz' has spawned.", Body = "Find a hiding spot." }
	},
	["BackdoorLookman"] = {
		Alias = "Lookman",
		NotifyMessage = { Title = "Entity 'Lookman' has spawned.", Body = "Avoid looking at its eyes." }
	},
	["Groundskeeper"] = {
		Alias = "Groundskeeper",
		NotifyMessage = { Title = "Entity 'Groundskeeper' has spawned.", Body = "Avoid stepping on the grass." }
	},
	["A60"] = {
		Alias = "A-60",
		NotifyMessage = { Title = "Entity 'A-60' has spawned.", Body = "Find a hiding spot." }
	},
	["A120"] = {
		Alias = "A-120",
		NotifyMessage = { Title = "Entity 'A-120' has spawned.", Body = "Find a hiding spot." }
	},
	["GloombatSwarm"] = {
		Alias = "Gloombat Swarm",
		NotifyMessage = { Title = "Entity 'Gloombat Swarm' has spawned.", Body = "Keep all light sources turned off." }
	},
	["GlitchRush"] = {
		Alias = "RNIUSHCG==",
		NotifyMessage = { Title = "Entity 'RNIUSHCG==' has spawned.", Body = "Find a hiding spot." }
	},
	["GlitchAmbush"] = {
		Alias = "AR0xMBUSH",
		NotifyMessage = { Title = "Entity 'AR0xMBUSH' has spawned.", Body = "Find a hiding spot." }
	},
	["MonumentEntity"] = {
		Alias = "Monument",
		NotifyMessage = { Title = "Entity 'Monument' has spawned.", Body = "It can't move while you are looking at it." }
	},
	["JeffTheKiller"] = {
		Alias = "Jeff the Killer",
		NotifyMessage = { Title = "Entity 'Jeff the Killer' has spawned.", Body = "Avoid touching him." }
	},
	["CustomEntity"] = {
		Alias = "Custom Entity",
		NotifyMessage = { Title = "Entity 'Custom Entity' has spawned.", Body = "Find a hiding spot." }
	},
	["FrozenAmbush"] = {
		Alias = "Frozen Ambush",
		NotifyMessage = { Title = "Entity 'Frozen Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["SallyMoving"] = {
		Alias = "Sally",
		NotifyMessage = { Title = "Entity 'Sally' has spawned.", Body = "Find her horse and rop it." }
	}
}

local EntityIcons = {
	["RushMoving"]      = "rbxassetid://10716032262",
	["AmbushMoving"]    = "rbxassetid://10110576663",
	["A60"]             = "rbxassetid://12571092295",
	["A120"]            = "rbxassetid://12711591665",
	["BackdoorRush"]    = "rbxassetid://16602023490",
	["Eyes"]            = "rbxassetid://10183704772",
	["Lookman"]         = "rbxassetid://10183704772",
	["BackdoorLookman"] = "rbxassetid://16764872677",
	["GloombatSwarm"]   = "rbxassetid://79221203116470",
	["Halt"]            = "rbxassetid://11331795398",
	["JeffTheKiller"]   = "rbxassetid://94479432156278",
	["GlitchRush"]      = "rbxassetid://73859273102919",
	["GlitchAmbush"]    = "rbxassetid://88369678433359",
	["SallyMoving"]     = "rbxassetid://10840888070",
	["MonumentEntity"]  = "rbxassetid://88933556873017",
	["Groundskeeper"]   = "rbxassetid://114991380115557"
}

local ItemNames = {
	["AbrahamHat"]        = "Hat",
	["LargeScrew"]        = "Screw",
	["DinkyLamp"]         = "Lamp",
	["BottleCrate"]       = "18+ Bottles",
	["GweenSodaPack"]     = "Gween Soda Pack",
	["BrokenMonitor"]     = "Broken Monitor",
	["JerryCan"]          = "Jerry Can",
 	["SallyToyObtain"]    = "Sally Toy",
	["Leftovers"]         = "Lunch Box",
	["HoneyPot"]          = "Honey Pot",
	["FihFlakes"]         = "Fih Food",
	["SecretCD"]          = "CD Disc",
	["Pizza"]             = "Pizza",
	["PaperPlanePickup"]  = "Paper Plane",
	["Lighter"]           = "Lighter",
	["Flashlight"]        = "Flashlight",
	["Lockpick"]          = "Lockpicks",
	["Vitamins"]          = "Vitamins",
	["Bandage"]           = "Bandage",
	["StarVial"]          = "Starlight Vial",
	["StarBottle"]        = "Starlight Bottle",
	["StarJug"]           = "Starlight Barrel",
	["Shakelight"]        = "Gummy Flashlight",
	["Straplight"]        = "Straplight",
	["Bulklight"]         = "Spotlight",
	["Battery"]           = "Battery",
	["Candle"]            = "Candle",
	["Crucifix"]          = "Crucifix",
	["CrucifixWall"]      = "Crucifix",
	["Glowsticks"]        = "Glowstick",
	["SkeletonKey"]       = "Skeleton Key",
	["Candy"]             = "Candy",
	["ShieldMini"]        = "Mini Shield Potion",
	["ShieldBig"]         = "Big Shield Potion",
	["BandagePack"]       = "Bandage Pack",
	["BatteryPack"]       = "Battery Pack",
	["RiftCandle"]        = "Moonlight Candle",
	["LaserPointer"]      = "Laser Pointer",
	["HolyGrenade"]       = "Holy Hand Grenade",
	["Shears"]            = "Shears",
	["Smoothie"]          = "Smoothie",
	["Cheese"]            = "Cheese",
	["Bread"]             = "Bread",
	["AlarmClock"]        = "Alarm Clock",
	["RiftSmoothie"]      = "Moonlight Smoothie",
	["GweenSoda"]         = "Gween Soda",
	["GlitchCube"]        = "Glitch Fragment",
	["Scanner"]           = "Tablet",
	["Bomb"]              = "Bomb",
	["Knockbomb"]         = "Knockbomb",
	["Nanner"]            = "Nanner",
	["BigBomb"]           = "Big Bomb",
	["SnakeBox"]          = "Hiding Box",
	["GoldGun"]           = "Golden Gun",
	["StopSign"]          = "Stop Sign",
	["TipJar"]            = "Tip Jar",
	["Lantern"]           = "Lantern",
	["IronKey"]           = "Iron Key",
	["LotusPetal"]        = "Lotus Petal",
	["Compass"]           = "Compass",
	["LotusPetalPickup"]  = "Lotus Petal",
	["LanternLitItem"]    = "Lantern",
	["KeyIron"]           = "Iron Key",
	["IronKeyForCrypt"]   = "Iron Key",
	["LotusHolder"]       = "Lotus Petal",
	["Multitool"]         = "Multitool",
	["RiftJar"]           = "Rift Jar",
	["AloeVera"]          = "Aloe Vera",
	["Donut"]             = "Donut",
	["Lotus"]             = "Lotus",
	["BoxingGloves"]      = "Boxing Gloves"
}

local CutsceneNames = {
    "Figure",
    "FigureEnd",
    "FigureHotelEnd",
    "FigureHotelFire",
    "SeekIntroFools",
    "SeekIntroHotel",
    "SeekIntroMines",
    "SeekIntroMines2",
    "SerewSeekDrain",
    "SewerSeekLower",
    "GrumbleNestEnd",
    "EyestalkIntro",
}

local Character
local Humanoid
local RootPart

local Collision
local CollisionClone
local CollisionPart
local CollisionPartClone

local Camera

local RemotesFolder   = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
local LiveModifiers   = Services.ReplicatedStorage:FindFirstChild("LiveModifiers")
local FloorReplicated = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
local CurrentRooms    = Services.Workspace:FindFirstChild("CurrentRooms")
local Drops           = Services.Workspace:FindFirstChild("Drops")
local GameData        = Services.ReplicatedStorage:WaitForChild("GameData")
local Floor           = GameData:WaitForChild("Floor").Value
local LatestRoom      = GameData:WaitForChild("LatestRoom")
local FinishedLoadingRoom = GameData:FindFirstChild("FinishedLoadingRoom")
local RunService = game:GetService("RunService")

if FinishedLoadingRoom then
	FinishedLoadingRoom:Destroy()
end

local function GetHiddenContainer()
	if Functions.CheckCompatability({"gethui"}) then
		return Abysall.Environment.gethui()
	end
	return Services.CoreGui
end

local NotificationLibrary = {
	LiveNotifications = 0,
	Notifications = 1
}

local Container = Instance.new("ScreenGui")
Container.Name = Abysall.ESPLibrary:GenerateRandomString()
Container.Parent = GetHiddenContainer()
Container.DisplayOrder = 32767
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if not Library.Scheme then
	Library.Scheme = setmetatable({}, {
		__index = function(Self, Name)
			return Library[Name]
		end
	})
end

function NotificationLibrary:Notify(TitleText, Desc, Delay)
	task.spawn(function()
		local Notification = Instance.new("Frame")
		local Line = Instance.new("Frame")
		local Warning = Instance.new("ImageLabel")
		local UICorner = Instance.new("UICorner")
		local UICorner2 = Instance.new("UICorner")
		local Title = Instance.new("TextLabel")
		local Description = Instance.new("TextLabel")

		Notification.Name = "Notification"
		Notification.Parent = Container
		Notification.BackgroundColor3 = Library.Scheme.BackgroundColor
		Notification.BackgroundTransparency = 0.4
		Notification.BorderSizePixel = 0
		Notification.Position = UDim2.new(1, 5, 0, 60 + (60 * NotificationLibrary.LiveNotifications))
		Notification.Size = UDim2.new(0, 420, 0, 50)
		Notification:SetAttribute("ID", NotificationLibrary.Notifications)
		Notification:SetAttribute("CurrentPosition", Notification.Position)

		Line.Name = "Line"
		Line.Parent = Notification
		Line.BackgroundColor3 = Library.Scheme.AccentColor
		Line.BorderSizePixel = 0
		Line.Position = UDim2.new(0, 0, 1, -3)
		Line.Size = UDim2.new(0, 0, 0, 3)

		Warning.Name = "Warning"
		Warning.Parent = Notification
		Warning.BackgroundTransparency = 1
		Warning.Position = UDim2.new(0, 10, 0, 5)
		Warning.Size = UDim2.new(0, 40, 0, 40)
		Warning.Image = "rbxassetid://3944668821"
		Warning.ImageColor3 = Library.Scheme.AccentColor
		Warning.ScaleType = Enum.ScaleType.Fit

		UICorner.CornerRadius = UDim.new(0, 20)
		UICorner.Parent = Warning

		UICorner2.CornerRadius = UDim.new(0, 4)
		UICorner2.Parent = Notification

		Title.Name = "Title"
		Title.Parent = Notification
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 60, 0.155, 0)
		Title.Size = UDim2.new(0, 205, 0, 15)
		Title.Text = TitleText or "..."
		Title.TextColor3 = Library.Scheme.FontColor
		Title.TextSize = 10
		Title.TextStrokeTransparency = 0.75
		Title.TextXAlignment = Enum.TextXAlignment.Left

		Description.Name = "Description"
		Description.Parent = Notification
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1
		Description.Position = UDim2.new(0, 60, 0.483, 0)
		Description.Size = UDim2.new(0, 205, 0, 18)
		Description.Text = Desc or "..."
		Description.TextColor3 = Library.Scheme.FontColor
		Description.TextTransparency = 0.1
		Description.TextSize = 10
		Description.TextStrokeTransparency = 0.75
		Description.TextXAlignment = Enum.TextXAlignment.Left

		NotificationLibrary.LiveNotifications += 1
		NotificationLibrary.Notifications += 1

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(1, Enum.EasingStyle.Exponential),
			{ Position = UDim2.new(1, -370, 0, Notification.Position.Y.Offset) }
		):Play()

		task.wait(0.25)
		if typeof(Delay) == "Instance" then
			Delay.Destroying:Wait()
		else
			Services.TweenService:Create(
				Line,
				TweenInfo.new(Delay - 0.25, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(0, 400, 0, 3) }
			):Play()
			task.wait(Delay - 0.25)
		end

		Notification:SetAttribute("Destroying", true)

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 5, 0, Notification.Position.Y.Offset) }
		):Play()

		NotificationLibrary.LiveNotifications -= 1

		local NotifId = Notification:GetAttribute("ID")
		local NotifY = Notification:GetAttribute("CurrentPosition").Y.Offset

		for _, Object in Container:GetChildren() do
			if Object.Name == "Notification"
				and Object:GetAttribute("ID")
				and Object:GetAttribute("ID") > NotifId
				and Object:GetAttribute("Destroying") ~= true
				and Object.Position.Y.Offset ~= 60
			then
				local NewY = Object:GetAttribute("CurrentPosition").Y.Offset - 60
				Object:SetAttribute("CurrentPosition", UDim2.new(1, -450, 0, NewY))
				Services.TweenService:Create(
					Object,
					TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
					{ Position = UDim2.new(1, -370, 0, NewY) }
				):Play()
			end
		end

		task.wait(0.75)
		Notification:Destroy()
	end)
end

Globals.DoorsNotify = function(NotifyOptions)
	local function PlaySound(Parent, SoundId, Volume)
		local Sound = Instance.new("Sound")
		Sound.SoundId = SoundId
		Sound.Volume = Volume or 1
		Sound.Parent = Parent
		task.spawn(function()
			task.wait(0.1)
			Sound:Play()
			Sound.Ended:Wait()
			Sound:Destroy()
		end)
	end

	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local UIContainer = PlayerGui:FindFirstChild("GlobalUI") or PlayerGui:FindFirstChild("MainUI")
	if not UIContainer then return end

	local AchievementsHolder = UIContainer:FindFirstChild("AchievementsHolder")
	if not AchievementsHolder then return end

	local Achievement = AchievementsHolder.Achievement:Clone()
	Achievement.Size = UDim2.new(0, 0, 0, 0)
	Achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
	Achievement.Name = "LiveAchievement"
	Achievement.Visible = true

	Achievement.Frame.TextLabel.Text = NotifyOptions.Style or "NOTIFICATION"
	Achievement.Frame.Details.Title.Text = NotifyOptions.Title or "Sem Título"
	Achievement.Frame.Details.Desc.Text = NotifyOptions.Description or "Sem Descrição"
	Achievement.Frame.Details.Reason.Text = NotifyOptions.Reason or ""
	Achievement.Frame.ImageLabel.Image = (NotifyOptions.Image ~= "" and NotifyOptions.Image) or "rbxassetid://6023426923"

	local Color = NotifyOptions.Color or Color3.new(1, 1, 1)
	Achievement.Frame.TextLabel.TextColor3 = Color
	Achievement.Frame.UIStroke.Color = Color
	Achievement.Frame.Glow.ImageColor3 = Color
	Achievement.Parent = AchievementsHolder

	PlaySound(AchievementsHolder, "rbxassetid://10469938989", 1)

	task.spawn(function()
		Achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), "In", "Quad", 0.8, true)
		task.wait(0.8)
		Achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.5, true)
		Services.TweenService:Create(
			Achievement.Frame.Glow,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }
		):Play()

		if typeof(NotifyOptions.Time) == "Instance" then
			NotifyOptions.Time.Destroying:Wait()
		else
			task.wait(NotifyOptions.Time or 5)
		end

		Achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Quad", 0.5, true)
		task.wait(0.5)
		Achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), "InOut", "Quad", 0.5, true)
		task.wait(0.5)
		Achievement:Destroy()
	end)
end

Globals.STX = loadstring(game:HttpGet("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Components/STX.luau"))()
Functions.Notify = function(Settings)
	local HiddenContainer = GetHiddenContainer()

	if not Settings.Body then
		Settings.Body = "..."
	end

	if not Options.NotifyStyle or Options.NotifyStyle.Value == "Abysall" then
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://8784885431"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		NotificationLibrary:Notify(Settings.Title, Settings.Body, Settings.Time or 5)
	elseif Options.NotifyStyle.Value == "Doors" then
		local IsEntity = false
		local EntityName = ""
		for Index, Object in pairs(Entities) do
			if Object.NotifyMessage.Title == Settings.Title or Object.NotifyMessage.Body == Settings.Body then
				IsEntity = true
				EntityName = Index
			end
		end
		Globals.DoorsNotify({
			Title = "Abysall Hub",
			Description = Settings.Title,
			Reason = Settings.Body,
			Style = IsEntity and "WARNING" or "NOTIFICATION",
			Color = IsEntity and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 222, 189),
			Image = Settings.Image,
			Time = Settings.Time
		})
	elseif Options.NotifyStyle.Value == "STX" then
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://4590657391"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()

		if Settings.Image then
			Globals.STX:Notify(
				{Title = "Abysall Hub", Description = Settings.Title .. "\n" .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = "image"},
				{Image = Settings.Image, ImageColor = Color3.fromRGB(255, 255, 255)}
			)
		else
			Globals.STX:Notify(
				{Title = "Abysall Hub", Description = Settings.Title .. "\n" .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = "default"}
			)
		end
	else
		local Sound = Instance.new("Sound", HiddenContainer)
		Sound.SoundId = "rbxassetid://4590662766"
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		Library:OldNotify({ Title = Settings.Title, Description = Settings.Body, Time = Settings.Time })
	end
end

Functions.Caption = function(Text, PlaySound)
	if typeof(PlaySound) ~= "boolean" then
		PlaySound = true
	end
	local CaptionValue = Instance.new("NumberValue")
	local Caption = Globals.MainUI:WaitForChild("MainFrame"):WaitForChild("Caption"):Clone()
	local CaptionSound = Globals.MainUI:WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("Reminder"):WaitForChild("Caption")
	local CaptionSoundClone = CaptionSound:Clone()
	CaptionSoundClone.Parent = CaptionSound.Parent
	CaptionSoundClone.Volume = 0.1

	Caption.Destroying:Connect(function()
		CaptionValue:Destroy()
	end)

	for _, Child in Globals.MainUI:GetChildren() do
		if Child.Name == "LiveCaption" then
			Child:Destroy()
		end
	end

	Caption.Parent = Globals.MainUI
	Caption.Visible = true
	Caption.Name = "LiveCaption"
	Caption.Text = Text

	if PlaySound then
		CaptionSoundClone:Play()
	end

	Services.Debris:AddItem(CaptionSoundClone, 5)

	local HolderTween = Services.TweenService:Create(CaptionValue, TweenInfo.new(3), { Value = 100 })
	HolderTween:Play()
	HolderTween.Completed:Connect(function()
		CaptionValue:Destroy()
		Services.TweenService:Create(Caption, TweenInfo.new(4, Enum.EasingStyle.Linear), { TextTransparency = 1 }):Play()
		Services.TweenService:Create(Caption, TweenInfo.new(4, Enum.EasingStyle.Linear), { TextStrokeTransparency = 1 }):Play()
	end)
end

Functions.GetHasteTime = function()
	local TimeRemaining = FloorReplicated.DigitalTimer.Value
	local Minutes = math.floor(TimeRemaining / 60)
	local Seconds = TimeRemaining - (Minutes * 60)
	local MinutesText = Minutes < 10 and ("0" .. tostring(Minutes)) or tostring(Minutes)
	local SecondsText = Seconds < 10 and ("0" .. tostring(Seconds)) or tostring(Seconds)
	return MinutesText .. ":" .. SecondsText
end

Library.OldNotify = Library.Notify
Library.Notify = function(Data, Body, Time)
	Functions.Notify({ Title = Body, Time = Time or 5 })
end

if not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass("Model") then
	Functions.Notify({ Title = "Waiting for the game to load..." })
	while not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass("Model") do
		task.wait()
	end
	task.wait(4)
end

if not RemotesFolder then
	if Services.ReplicatedStorage:FindFirstChild("EntityInfo") then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild("EntityInfo")
	elseif Services.ReplicatedStorage:FindFirstChild("Bricks") then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild("Bricks")
	end
end

if Floor == "Hotel" and RemotesFolder.Name == "Bricks" then
	Floor = "OldHotel"
end

if not LiveModifiers then
	LiveModifiers = Instance.new("Folder")
end

if not FloorReplicated then
	FloorReplicated = Instance.new("Folder")
end

local FakeEvents = {
	Screech = Instance.new("RemoteEvent"),
	Shade   = Instance.new("RemoteEvent"),
	A90     = Instance.new("RemoteEvent"),
	Surge   = Instance.new("RemoteEvent"),
}

FakeEvents.Screech.Name  = "Screech"
FakeEvents.Shade.Name    = "ShadeResult"
FakeEvents.A90.Name      = "A90"
FakeEvents.Surge.Name    = "SurgeRemote"

FakeEvents.Screech_Real = RemotesFolder:WaitForChild("Screech")
FakeEvents.Shade_Real   = RemotesFolder:WaitForChild("ShadeResult")
FakeEvents.A90_Real     = RemotesFolder:FindFirstChild("A90")
FakeEvents.Surge_Real   = RemotesFolder:FindFirstChild("SurgeRemote")

if RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed") then
    local RealRemote = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed")
    RealRemote:Destroy()

    local FakeRemote = Instance.new("RemoteEvent", RemotesFolder)
    FakeRemote.Name = "FootstepRemoteThatWeNeed"
end

Globals.FogInstances = {}
Globals.OldFog = Services.Lighting.FogEnd

for _, Object in Services.Lighting:GetChildren() do
	if Object:IsA("Atmosphere") then
		Object:SetAttribute("Density_Old", Object.Density)

		local AtmoConnection = Object:GetPropertyChangedSignal("Density"):Connect(function()
			if Object.Density ~= 0 then
				Object:SetAttribute("Density_Old", Object.Density)
			end
			if Toggles.RemoveCameraFog.Value then
				Object.Density = 0
			end
		end)

		Object.Destroying:Once(function()
			AtmoConnection:Disconnect()
		end)

		table.insert(Connections, AtmoConnection)
		table.insert(Globals.FogInstances, Object)
	end
end

Globals.SeekNodesFolder = Instance.new("Folder", Services.Workspace)
Globals.SeekNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Globals.RoomsNodesFolder = Instance.new("Folder", Services.Workspace)
Globals.RoomsNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Functions.SendChat = function(Message)
	local Folder = Services.ReplicatedStorage:FindFirstChild("DefaultChatSystemEvents") or Instance.new("Folder")
	local Event = Folder:FindFirstChild("SayMessageRequest") or Instance.new("RemoteEvent")
	Event:FireServer(Message, "All")
	local Channel = (Services.TextChatService:FindFirstChild("TextChannels") and Services.TextChatService.TextChannels:FindFirstChild("RBXGeneral")) or Instance.new("TextChannel")
	Channel:SendAsync(Message)
end

Functions.IsCrouching = function()
	if Floor == "Fools" or Floor == "OldHotel" then
		return Character:GetAttribute("Crouching")
	end
	return CollisionPart.CollisionGroup == "PlayerCrouching"
end

Functions.GetInjuriesSpeed = function()
	return 0.075 * (Humanoid.MaxHealth - Humanoid.Health)
end

Functions.GetCurrentSpeed = function()
	local Speed = 15
	Speed += Character:GetAttribute("SpeedBoost") or 0
	Speed += Character:GetAttribute("SpeedBoostBehind") or 0
	Speed += Character:GetAttribute("SpeedBoostExtra") or 0
	Speed += (Floor == "Party" and 10 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlow") and 3 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlowHealth") and Functions.GetInjuriesSpeed() or 0)
	if Functions.IsCrouching() then
		if LiveModifiers:FindFirstChild("PlayerCrouchSlow") then
			Speed -= 8
		elseif LiveModifiers:FindFirstChild("PlayerSlow") then
			Speed -= 8
		else
			Speed -= 5
		end
	end
	return Speed
end

Functions.GetMousePosition = function()
	if Library.IsMobile then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end
	local MouseLocation = Services.UserInputService:GetMouseLocation()
	return Vector2.new(MouseLocation.X, MouseLocation.Y)
end

Functions.FormatOxygen = function(Oxygen)
	return "Oxygen: " .. (math.floor(Oxygen * 10) / 10) .. "%"
end

Functions.IsHidePersistent = function()
	return Floor == "Mines"
		or Floor == "Ripple"
		or Floor == "Party"
		or LiveModifiers:FindFirstChild("HideLevel2") ~= nil
end

Functions.GetPlayerFromMouse = function(TargetPart, MaxDistance)
	local Closest
	local ClosestDistance = math.huge

	for _, Player in Services.Players:GetPlayers() do
		local Char = Player.Character
		if Char then
			local Target = Char:FindFirstChild(TargetPart)
			if Target then
				local Result = Camera:WorldToViewportPoint(Target.Position)
				local ScreenPos = Vector2.new(Result.X, Result.Y)
				local Distance = (Functions.GetMousePosition() - ScreenPos).Magnitude
				if Player.Name ~= LocalPlayer.Name and Distance < ClosestDistance and Distance < MaxDistance then
					Closest = Target
					ClosestDistance = Distance
				end
			end
		end
	end
	return Closest
end

local EntityDistances = {
	["RushMoving"]    = 85,
	["Scribbles"]	  = 100,
	["BashMoving"]    = 150,
	["DronesStampede"] = 100,
	["AmbushMoving"]  = 150,
	["A60"]           = 125,
	["A120"]          = 85,
	["GlitchRush"]    = 90,
	["GlitchAmbush"]  = 175,
	["BackdoorRush"]  = 85,
	["CustomEntity"]  = 85,
}

Functions.GetNearestEntity = function(CheckDisabled, List, UseRaycasting)
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Entity in Objects.Entities do
		if not Entity or not Entity:IsA("Model") or not Entity:IsDescendantOf(Services.Workspace) then continue end
		if not EntityDistances[Entity.Name] or not Entity.PrimaryPart then continue end

		local EntityData = Entities[Entity.Name]
		if not EntityData then continue end
		if List and List[EntityData.Alias] then continue end

		local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if Distance < EntityDistances[Entity.Name] and Distance < Nearest.Distance then
			if not CheckDisabled or Entity:GetAttribute("Inactive") ~= true then
				Nearest.Distance = Distance
				Nearest.Object = Entity
			end
		end
	end
	return Nearest.Object
end

Functions.GetNearestFigure = function()
	local Nearest = { Distance = math.huge, Object = nil }
	local FigureNames = { FigureRig = true, FigureRagdoll = true, Figure = true }

	for _, Object in Objects.Entities do
		if Object:IsA("Model") and Object.PrimaryPart and FigureNames[Object.Name] then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Distance < 25 then
				Nearest.Distance = Distance
				Nearest.Object = Object
			end
		end
	end
	return Nearest.Object
end

Functions.GetNearestHidingSpot = function()
	local Nearest = { Distance = math.huge, Object = nil }
	local LastHideSpot = Character:FindFirstChild("LastHideSpot")

	local function IsHidingSpotName(Name)
		if typeof(Name) ~= "string" then return false end
		return string.find(string.lower(Name), "hidingspot") or string.find(string.lower(Name), "hiding_spot")
	end

	local function GetHidePrompt(Object)
	if not Object then return nil end

	local Prompt = Object:FindFirstChild("HidePrompt") or Object:FindFirstChild("HidingPrompt")
	if Prompt then return Prompt end

	for _, Child in Object:GetDescendants() do
		if (Child:IsA("ProximityPrompt") or Child:IsA("InteractPrompt"))
			and (Child.Name == "HidePrompt" or Child.Name == "HidingPrompt" or IsHidingSpotName(Child.Name))
		then
			return Child
		end
	end

	if IsHidingSpotName(Object.Name) or IsHidingSpotName(Object.Parent and Object.Parent.Name) then
		return Object:FindFirstChild("HidePrompt") or Object:FindFirstChild("HidingPrompt")
	end

	return nil
	end

	local function TryObject(Object)
		if not Object or not Object:IsDescendantOf(Services.Workspace) then return end
		if not Object.PrimaryPart and not Object:FindFirstChildOfClass("BasePart") then return end
		local Prompt = GetHidePrompt(Object)
		if not Prompt then return end
		local PrimaryPart = Object.PrimaryPart or Object:FindFirstChildOfClass("BasePart")
		if not PrimaryPart then return end
		local Distance = LocalPlayer:DistanceFromCharacter(PrimaryPart.Position)
		if Distance < Prompt.MaxActivationDistance and Distance < Nearest.Distance then
			local Persistent = Functions.IsHidePersistent()
			if not Persistent or (LastHideSpot and LastHideSpot.Value ~= Object) or not LastHideSpot then
				Nearest.Distance = Distance
				Nearest.Object = Object
			end
		end
	end

	for _, Object in Objects.HidingSpots do
		TryObject(Object)
	end

	return Nearest.Object
end

Functions.GetNearestTurnNode = function()
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Node in Objects.SeekNodes do
		local Distance = LocalPlayer:DistanceFromCharacter(Node.Position)
		if Distance < Options.AutoSteerMinecartTurnDistance.Value and Distance < Nearest.Distance then
			Nearest.Distance = Distance
			Nearest.Object = Node
		end
	end
	return Nearest.Object
end

Functions.GetNearestDuckBoard = function()
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Board in Objects.SeekDuckBoards do
		if Board.PrimaryPart then
			local Distance = LocalPlayer:DistanceFromCharacter(Board.PrimaryPart.Position)
			if Distance < Options.AutoSteerMinecartDuckDistance.Value and Distance < Nearest.Distance then
				Nearest.Distance = Distance
				Nearest.Object = Board
			end
		end
	end
	return Nearest.Object
end

Functions.GetCurrentAnchor = function()
	local AnchorCode = Globals.MainUI.AnchorHintFrame.AnchorCode.Text
	for _, Anchor in Objects.Objectives do
		if Anchor.Name == "MinesAnchor" and Anchor:FindFirstChild("Sign") then
			if Anchor.Sign.TextLabel.Text == AnchorCode then
				return Anchor
			end
		end
	end
end

Functions.GetMinecart = function()
	return Camera:FindFirstChild("MinecartRig") ~= nil
end

Functions.HasItem = function(Name, OnlyCharacter)
	if not OnlyCharacter and LocalPlayer.Backpack:FindFirstChild(Name) then
		return LocalPlayer.Backpack:FindFirstChild(Name)
	elseif Character:FindFirstChild(Name) then
		return Character:FindFirstChild(Name)
	end
end

Functions.GetFlyVelocity = function()
	if Humanoid.MoveDirection == Vector3.zero then
		return Humanoid.MoveDirection
	end
	local LookFlat = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
	local FlatFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + LookFlat)
	local Velocity = (Camera.CFrame * CFrame.new(FlatFrame:VectorToObjectSpace(Humanoid.MoveDirection))).Position - Camera.CFrame.Position
	if Velocity == Vector3.zero then
		return Velocity
	end
	return Velocity.Unit
end

Globals.PromptContainer = Instance.new("Folder")
Globals.PromptContainer.Name = "PromptContainer"
Globals.PromptContainer.Parent = GetHiddenContainer()

local ESPBlacklist = {}

Functions.AddESP = function(ESPOptions, RoomBased)
	local Object = ESPOptions.Object

	if table.find(ESPBlacklist, Object) then
		return
	end

	if RoomBased then
		local CurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
		local ObjectRoom = tonumber(Object:GetAttribute("ParentRoom"))

		if ObjectRoom == CurrentRoom or (table.find(Objects.Doors, Object) and ObjectRoom == CurrentRoom + 1) then
			Abysall.ESPLibrary:AddESP(ESPOptions)
		end

		local RoomConnection = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
			if Abysall.ESPLibrary.ColorTable[Object] then
				ESPOptions.Color = Abysall.ESPLibrary.ColorTable[Object]
			end

			local NewCurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
			local ObjRoom = tonumber(Object:GetAttribute("ParentRoom"))

			if ObjRoom == NewCurrentRoom or (table.find(Objects.Doors, Object) and ObjRoom == NewCurrentRoom + 1) then
				Abysall.ESPLibrary:AddESP(ESPOptions)
			else
				Abysall.ESPLibrary:RemoveESP(Object)
			end
		end)

		table.insert(Connections, RoomConnection)
		ESPConnections[Object] = RoomConnection

		Object.Destroying:Once(function()
			RoomConnection:Disconnect()
			if Abysall then
				Abysall.ESPLibrary:RemoveESP(Object)
			end
			local Pos = table.find(Connections, RoomConnection)
			if Pos then table.remove(Connections, Pos) end
		end)
	else
		Abysall.ESPLibrary:AddESP(ESPOptions)
	end
end

Functions.RemoveESP = function(Object)
	local Conn = ESPConnections[Object]
	if Conn then
		Conn:Disconnect()
		ESPConnections[Object] = nil
		local Pos = table.find(Connections, Conn)
		if Pos then table.remove(Connections, Pos) end
	end
	Abysall.ESPLibrary:RemoveESP(Object)
end

Functions.BlacklistESP = function(Object)
	table.insert(ESPBlacklist, Object)
end

Functions.GetDoorNumber = function(Object)
	local DoorNumber = tonumber(Object.Parent.Name) or tonumber(Object.Parent.Parent.Name)
	if DoorNumber then
		DoorNumber = DoorNumber + 1
	end
	if Floor == "Mines" then
		DoorNumber = DoorNumber + 100
	end
	if Floor == "Backdoor" then
		DoorNumber = DoorNumber - 50
	end

	return tostring(DoorNumber)
end

Functions.GetLibraryCode = function()
	local Paper = Character:FindFirstChild("LibraryHintPaper")
		or Character:FindFirstChild("LibraryHintPaperHard")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaperHard")

	if Paper and Paper:FindFirstChild("UI") then
		local Code = {}
		local CodeLength = Floor == "Fools" and 10 or 5
		for I = 1, CodeLength do Code[I] = "_" end

		local HintChildren = LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()
		local UIChildren = Paper.UI:GetChildren()

		for _, Hint in HintChildren do
			for _, UIChild in UIChildren do
				if Hint:IsA("ImageLabel") and UIChild:IsA("ImageLabel")
					and Hint.ImageRectOffset == UIChild.ImageRectOffset
					and Code[tonumber(UIChild.Name)]
				then
					Code[tonumber(UIChild.Name)] = Hint.TextLabel.Text
				end
			end
		end
		return table.concat(Code)
	end
	return Floor == "Fools" and "__________" or "_____"
end

Globals.UsedRandomCodes = {}
Functions.GetRandomCode = function()
    local CodeTemplate = Functions.GetLibraryCode()
    if not CodeTemplate then
        return nil
    end

    local NewCode
    local Tries = 0
    repeat
        NewCode = CodeTemplate:gsub("_", function()
            return tostring(math.random(0, 9))
        end)
        Tries = Tries + 1
    until not Globals.UsedRandomCodes[NewCode] or Tries >= 10

    Globals.UsedRandomCodes[NewCode] = true
    return NewCode
end

local Window = Library:CreateWindow({
	Title = "🎃 Abysall Hub Continued",
	Footer = "dsc.gg/abysallhubcontinued",
	NotifySide = "Right",
	ShowCustomCursor = false,
	AutoShow = true,
	Center = true,
	TabPadding = 3,
	MenuFadeTime = 0,
	CornerRadius = 6,
})




Abysall.Interface.ApplyInfoTab(Window)

local Tabs = {
	General = Window:AddTab("General", "house"),
	Exploits = Window:AddTab("Exploits", "shield"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Floors = Window:AddTab("Floors", "earth"),
	Archives = Window:AddTab("New - Archives", "rbxassetid://104508835882225"),
	Stairwell = Window:AddTab("New - Stairwell", "rbxassetid://80017304328364"),
}


Groupboxes.General_Character = Tabs.General:AddLeftGroupbox("Character")
Groupboxes.General_Character:AddSlider("SpeedBoostSlider", {
	Text = "Speed Boost", Min = 0, Max = 100, Default = 0, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddToggle("SpeedBoostToggle", {
	Text = "Enable Speed Boost", Default = false, Tooltip = "Increases your walkspeed by the specified amount."
})
Groupboxes.General_Character:AddToggle("FlyToggle", {
	Text = "Fly", Default = false, Tooltip = "Allows you to freely fly around the map."
})
Toggles.FlyToggle:AddKeyPicker("FlyKeybind", {
	Text = "Fly", Default = "F", Mode = "Toggle", SyncToggleState = true
})
Groupboxes.General_Character:AddSlider("FlySpeed", {
	Text = "Fly Speed", Min = 0, Max = 115, Default = 20, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle("NoclipToggle", {
	Text = "Noclip", Default = false, Tooltip = "Allows your character to pass through solid objects."
})
Groupboxes.General_Character:AddToggle("RemoveClosetDelay", {
	Text = "Remove Closet Delay", Default = false,
	Tooltip = "Removes the short window where you can't exit out of a closet after the animation finishes."
})
Groupboxes.General_Character:AddToggle("RemoveAcceleration", {
	Text = "Remove Acceleration", Default = false, Tooltip = "Prevents your character from sliding while moving."
})

local CustomPhysics

Options.SpeedBoostSlider:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Toggles.NoclipToggle:AddKeyPicker("NoclipKeybind", {
	Text = "Noclip", Default = "N", Mode = "Toggle", SyncToggleState = true
})
Toggles.RemoveAcceleration:OnChanged(function(Value)
	for Index, Old in PartProperties do
		Index.CustomPhysicalProperties = Value and CustomPhysics or Old
	end
end)

Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle("EnableCharacterJump", {
	Text = "Enable Jumping", Default = false, Tooltip = "Allows your character to jump."
})
Groupboxes.General_Character:AddToggle("EnableCharacterSlide", {
	Text = "Enable Sliding", Default = false, Tooltip = "Allows your character to slide."
})
Groupboxes.General_Character:AddToggle("InfiniteJumps", {
	Text = "Infinite Jumps", Default = false, Tooltip = "Allows you to jump while in the air."
})

local OldJump = false
local OldSlide = false

Toggles.SpeedBoostToggle:OnChanged(function(Value)
	if Humanoid then
		Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + (Value and Options.SpeedBoostSlider.Value or 0)
	end
end)
Toggles.EnableCharacterJump:OnChanged(function(Value)
	if Character then
		Character:SetAttribute("CanJump", Value and true or OldJump)
	end
end)
Toggles.EnableCharacterSlide:OnChanged(function(Value)
	if Character then
		Character:SetAttribute("CanSlide", Value and true or OldSlide)
	end
end)

Groupboxes.General_Self = Tabs.General:AddLeftGroupbox("Self")
Groupboxes.General_Self:AddToggle("DoorReachToggle", {
	Text = "Door Reach", Default = false, Tooltip = "Allows you to open doors from further away."
})
Groupboxes.General_Self:AddToggle("DisableIdleKick", {
	Text = "Disable Idle Kick", Default = false, Tooltip = "Prevents the kick from being idle for 20 minutes."
})
Toggles.DisableIdleKick:OnChanged(function(Value)
	if Functions.CheckCompatability({"getconnections"}) then
		for _, Conn in Abysall.Environment.getconnections(LocalPlayer.Idled) do
			if Value then Conn:Disable() else Conn:Enable() end
		end
	end
end)
LocalPlayer.Idled:Connect(function()
	if Toggles.DisableIdleKick.Value then
		Services.VirtualUser:CaptureController()
		Services.VirtualUser:ClickButton2(Vector2.new())
	end
end)

Groupboxes.General_Self:AddDivider()
Groupboxes.General_Self:AddSlider("PromptReachSlider", {
	Text = "Prompt Reach Multiplier", Min = 1, Max = 2, Default = 1, Rounding = 1, Compact = true
})
Groupboxes.General_Self:AddToggle("InstantPrompts", {
	Text = "Instant Prompts", Default = false, Tooltip = "Allows you to trigger all prompts instantly."
})
Groupboxes.General_Self:AddToggle("PromptClip", {
	Text = "Prompt Clip", Default = false, Tooltip = "Allows you to interact with prompts through walls."
})

Options.PromptReachSlider:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") * Value
	end
end)
Toggles.InstantPrompts:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.HoldDuration = Value and 0 or Prompt:GetAttribute("HoldDuration_Old")
	end
end)
Toggles.PromptClip:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.RequiresLineOfSight = Value and false or Prompt:GetAttribute("RequiresLineOfSight_Old")
	end
end)

Groupboxes.Self_Automation = Tabs.General:AddRightGroupbox("Automation")
Groupboxes.Self_Automation:AddToggle("AutoBreakerBox", {
	Text = "Auto Breaker Box", Default = false, Tooltip = "Automatically solves the breaker box."
})
Groupboxes.Self_Automation:AddToggle("AutoSolveAnchors", {
	Text = "Auto Solve Anchors", Default = false,
	Tooltip = "Automatically enters the correct code into anchors when you are near them."
})
Toggles.AutoBreakerBox:OnChanged(function(Value)
	if Value and CurrentRooms:FindFirstChild("ElevatorBreaker", true) then
		if not Globals.BreakerBoxInteracted then
			if not Globals.BreakerBoxNotified then
				Functions.Notify({ Title = "Interact with the breaker box.", Body = "It will be automatically solved." })
				Globals.BreakerBoxInteracted = true
			end
		else
			RemotesFolder.EBF:FireServer()
		end
	end
end)

Groupboxes.Self_Automation:AddToggle("AutoHeartbeatMinigame", { Text = "Auto Heartbeat Minigame", Default = false, Tooltip = "Prevents the 'Figure' minigame from ever failing.", Disabled = not Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoUnlockPadlockToggle", {
	Text = "Auto Unlock Padlock", Default = false, Tooltip = "Automatically enters the code into the library padlock."
})
Groupboxes.Self_Automation:AddSlider("AutoUnlockPadlockSlider", {
	Text = "Unlock Distance", Min = 1, Max = 50, Default = 10, Rounding = 0, Compact = true
})
Groupboxes.Self_Automation:AddToggle("AutoLibraryGuessCode", {
	Text = "Guess Library Code", Default = false,
	Tooltip = "Attempts to guess the library code, but collecting some books is also necessary."
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoLibrary", {
	Text = "Auto Library", Default = false,
	Tooltip = "Automatically gets books and paper."
})
Groupboxes.Self_Automation:AddToggle("SkipSeekHotel", {
	Text = "Skip Seek (Hotel)",
	Default = false,
	Tooltip = "Skips the entire Seek sections.",
})
Groupboxes.Self_Automation:AddToggle("AutoBreakerRoom", {
	Text = "Auto Breaker Room",
	Default = false,
	Tooltip = "Automatically completes the breaker sequence in Hotel Room 100.",
})
Groupboxes.Self_Automation:AddDivider()
Toggles.AutoHotel = Groupboxes.Self_Automation:AddToggle("AutoHotel", {
	Text = "Auto Hotel",
	Tooltip = "Automatically progresses through the hotel floor.",
	Risky = Floor ~= "Ballz",
	Default = false
})
Toggles.AutoHotelIgnoreEntities = Groupboxes.Self_Automation:AddToggle("AutoHotelIgnoreEntities", {
	Text = "Ignore Entities",
	Tooltip = "Skip all entity waits and pauses.",
	Default = false
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoInteractToggle", {
	Text = "Auto Interact", Default = false, Tooltip = "Automatically triggers nearby prompts."
})
Toggles.AutoInteractToggle:AddKeyPicker("AutoInteractKeybind", {
    Text = "Auto Interact",
    Default = "R",
    Mode = "Toggle",
    SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown("AutoInteractIgnoreList", {
	Text = "Ignore List",
	Values = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Currency", "Minecarts", "Locks" },
	Default = { "Glitch Fragments", "Jeff Items", "Dropped Items" },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle("AutoClosetToggle", {
	Text = "Auto Closet", Default = false,
	Tooltip = "Automatically hides in a nearby closet when an entity is near."
})
Toggles.AutoClosetToggle:AddKeyPicker("AutoClosetKeybind", {
	Text = "Auto Closet", Default = "Q", Mode = "Toggle", SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown("AutoClosetEntityList", {
	Text = "Ignore List",
	Values = { "Rush", "Ambush", "Blitz", "DronesStampede", "Scribbles", "A-60", "A-120", "AR0xMBUSH", "RNIUSHCG==" },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddToggle("SpectateEntityToggle", {
	Text = "Spectate Entity",
	Default = false,
	Tooltip = "Spectates the entity while auto hiding."
})
Groupboxes.Self_Automation:AddDropdown("SpecateEntityMode", {
	Values = {"Player to Entity", "Entity to Player"},
	Default = 1,
	AllowNull = true
})

Groupboxes.Self_Misc = Tabs.General:AddRightGroupbox("Miscellaneous")
Groupboxes.Self_Misc:AddButton({
	Text = "Play Again", Tooltip = "Makes you join a new run, click again to cancel.", DoubleClick = true,
	Func = function() RemotesFolder.PlayAgain:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Return to Lobby", Tooltip = "Makes you teleport back to the lobby.", DoubleClick = true,
	Func = function() RemotesFolder.Lobby:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Revive",
	Tooltip = "Makes you revive, if you have a revive and haven't already revived in this run.",
	DoubleClick = true,
	Func = function() RemotesFolder.Revive:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = "Reset Character",
	Tooltip = "Kills your character on the server. (takes around 20 seconds if replicatesignal isn't supported)",
	DoubleClick = true,
	Func = function()
		Globals.SelfKilled = true
		if Functions.CheckCompatability({"replicatesignal"}) then
			Abysall.Environment.replicatesignal(LocalPlayer.Kill)
		else
			if RemotesFolder:FindFirstChild("Underwater") then
				RemotesFolder.Underwater:FireServer(true)
			else
				Humanoid.Health = 0
			end
		end
	end
})


Tabs.General:UpdateWarningBox({
	Visible = true,
	Title = "Risk Warning",
	Text = "Features highlighted in red are risky.",
})


Toggles.SkipSeekHotel:OnChanged(function(Value)
	if not Value then return end
	if Floor ~= "Hotel" then return end

	task.spawn(function()
		print("started")

		local currentRooms

		repeat
			if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
				return
			end
			currentRooms = workspace:FindFirstChild("CurrentRooms")
			task.wait()
		until currentRooms

		print("got currentrooms")

		local lastTriggerRoom = nil

		while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
			local triggerRoom = nil

			print("waiting for trigger")

			repeat
				if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
					return
				end

				currentRooms = workspace:FindFirstChild("CurrentRooms")
				local currentRoomNum = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))

				if currentRoomNum and currentRoomNum ~= lastTriggerRoom then
					local room = currentRooms and currentRooms:FindFirstChild(tostring(currentRoomNum))
					if room then
						local trigger = room:WaitForChild("TriggerEventCollision", 0.5)
						if trigger then
							triggerRoom = currentRoomNum
							print("found trigger in", triggerRoom)
						end
					end
				end

				task.wait()
			until triggerRoom

			lastTriggerRoom = triggerRoom

			local roomNum = triggerRoom

			while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
				roomNum += 1
				print("looking for room", roomNum)

				local room
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					currentRooms = workspace:FindFirstChild("CurrentRooms")
					room = currentRooms and currentRooms:FindFirstChild(tostring(roomNum))
					task.wait()
				until room

				print("found room", roomNum)

				local hasSeekArm = false
				local assets = room:FindFirstChild("Assets")
				if assets then
					for _, child in ipairs(assets:GetChildren()) do
						if child.Name == "Seek_Arm" then
							hasSeekArm = true
							print("found seek arm")
							break
						end
					end
				end

				local door
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					door = room:FindFirstChild("Door", true)
					task.wait()
				until door

				print("found door, teleporting")

				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
						return
					end
					if Character then
						Character:PivotTo(door:GetPivot())
					end
					task.wait()
				until door:GetAttribute("Opened") == true

				print("door opened")

				if hasSeekArm then
					if not Character then
						return
					end

					print("voiding")

					local voidCFrame = Character:GetPivot() + Vector3.new(0, -2500, 0)

					task.wait(0.25)

					for _ = 1, 20 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					task.wait(0.3)

					for _ = 1, 15 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					task.wait(0.2)

					for _ = 1, 10 do
						Character:PivotTo(voidCFrame)
						task.wait()
					end

					print("done voiding")
					break
				end
			end
		end
	end)
end)

Toggles.AutoLibrary:OnChanged(function(AutoLibraryEnabled)
	if AutoLibraryConnection then
		task.cancel(AutoLibraryConnection)
		AutoLibraryConnection = nil
	end

	if AutoLibraryRoomConnection then
		AutoLibraryRoomConnection:Disconnect()
		AutoLibraryRoomConnection = nil
	end

	if not AutoLibraryEnabled then
		return
	end

	AutoLibraryConnection = task.spawn(function()
		local AutoLibraryPlayers = game:GetService("Players")
		local AutoLibraryLocalPlayer = AutoLibraryPlayers.LocalPlayer
		local AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
		local AutoLibraryHumanoidRootPart = AutoLibraryCharacter:WaitForChild("HumanoidRootPart")

		local AutoLibraryCurrentRooms = workspace:WaitForChild("CurrentRooms")
		local AutoLibraryRoom50 = AutoLibraryCurrentRooms:WaitForChild("50")
		local AutoLibraryLiveHintBooks = {}
		local AutoLibraryHintPaperObtained = false

		local function AutoLibraryIsInRoom50(AutoLibraryObject)
			return AutoLibraryObject
				and AutoLibraryObject:IsDescendantOf(AutoLibraryRoom50)
				and AutoLibraryObject:IsDescendantOf(AutoLibraryCurrentRooms)
				and AutoLibraryObject:IsDescendantOf(workspace)
		end

		local function AutoLibraryIsActuallyInRoom50()
			return tonumber(AutoLibraryLocalPlayer:GetAttribute("CurrentRoom")) == 50
		end

		while AutoLibraryEnabled and not AutoLibraryIsActuallyInRoom50() do
			task.wait(0.05)
		end

		if not AutoLibraryEnabled then
			return
		end

		local function AutoLibraryHasHintPaper()
			AutoLibraryCharacter = AutoLibraryLocalPlayer.Character

			if not AutoLibraryCharacter then
				return false
			end

			local AutoLibraryBackpackPaper = AutoLibraryLocalPlayer.Backpack:FindFirstChild("LibraryHintPaper", true)
			local AutoLibraryCharacterPaper = AutoLibraryCharacter:FindFirstChild("LibraryHintPaper", true)

			return AutoLibraryBackpackPaper ~= nil or AutoLibraryCharacterPaper ~= nil
		end

		local function AutoLibraryGetObjectCFrame(AutoLibraryObject)
			if not AutoLibraryIsActuallyInRoom50() then
				return nil
			end

			if not AutoLibraryIsInRoom50(AutoLibraryObject) then
				return nil
			end

			if AutoLibraryObject:IsA("Model") then
				return AutoLibraryObject:GetPivot()
			elseif AutoLibraryObject:IsA("BasePart") then
				return AutoLibraryObject.CFrame
			end

			local AutoLibraryObjectPart = AutoLibraryObject:FindFirstChildWhichIsA("BasePart", true)

			if AutoLibraryObjectPart then
				return AutoLibraryObjectPart.CFrame
			end

			return nil
		end

		local function AutoLibraryFindBooks(AutoLibraryObject)
			if not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if not AutoLibraryIsInRoom50(AutoLibraryObject) then
				return
			end

			if AutoLibraryObject.Name == "LiveHintBook" then
				if not table.find(AutoLibraryLiveHintBooks, AutoLibraryObject) then
					table.insert(AutoLibraryLiveHintBooks, AutoLibraryObject)
				end
			end

			for _, AutoLibraryDescendant in ipairs(AutoLibraryObject:GetDescendants()) do
				if AutoLibraryDescendant.Name == "LiveHintBook"
					and AutoLibraryIsInRoom50(AutoLibraryDescendant) then

					if not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then
						table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
					end
				end
			end
		end

		for _, AutoLibraryDescendant in ipairs(AutoLibraryRoom50:GetDescendants()) do
			if not AutoLibraryEnabled or not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if AutoLibraryDescendant.Name == "LiveHintBook"
				and AutoLibraryIsInRoom50(AutoLibraryDescendant) then

				if not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then
					table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
				end
			end
		end

		AutoLibraryRoomConnection = AutoLibraryRoom50.DescendantAdded:Connect(function(AutoLibraryAddedObject)
			if not AutoLibraryEnabled then
				return
			end

			if not AutoLibraryIsActuallyInRoom50() then
				return
			end

			if not AutoLibraryIsInRoom50(AutoLibraryAddedObject) then
				return
			end

			AutoLibraryFindBooks(AutoLibraryAddedObject)
		end)

		while AutoLibraryEnabled
			and AutoLibraryIsActuallyInRoom50()
			and #AutoLibraryLiveHintBooks < 3 do

			for _, AutoLibraryDescendant in ipairs(AutoLibraryRoom50:GetDescendants()) do
				if not AutoLibraryEnabled or not AutoLibraryIsActuallyInRoom50() then
					return
				end

				if AutoLibraryDescendant.Name == "LiveHintBook"
					and AutoLibraryIsInRoom50(AutoLibraryDescendant)
					and not table.find(AutoLibraryLiveHintBooks, AutoLibraryDescendant) then

					table.insert(AutoLibraryLiveHintBooks, AutoLibraryDescendant)
				end
			end

			if #AutoLibraryLiveHintBooks >= 3 then
				break
			end

			task.wait(0.05)
		end

		while AutoLibraryEnabled
			and AutoLibraryIsActuallyInRoom50()
			and not AutoLibraryHintPaperObtained do

			if AutoLibraryHasHintPaper() then
				AutoLibraryHintPaperObtained = true
				break
			end

			for AutoLibraryIndex = #AutoLibraryLiveHintBooks, 1, -1 do
				if not AutoLibraryIsActuallyInRoom50() then
					return
				end

				local AutoLibraryLiveHintBook = AutoLibraryLiveHintBooks[AutoLibraryIndex]

				if not AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) then
					table.remove(AutoLibraryLiveHintBooks, AutoLibraryIndex)
					continue
				end

				while AutoLibraryEnabled
					and AutoLibraryIsActuallyInRoom50()
					and not AutoLibraryHintPaperObtained
					and AutoLibraryLiveHintBook.Parent
					and AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) do

					if AutoLibraryHasHintPaper() then
						AutoLibraryHintPaperObtained = true
						break
					end

					AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild("HumanoidRootPart")

					if not AutoLibraryHumanoidRootPart then
						task.wait()
						continue
					end

					local AutoLibraryBookCFrame = AutoLibraryGetObjectCFrame(AutoLibraryLiveHintBook)

					if AutoLibraryBookCFrame
						and AutoLibraryIsActuallyInRoom50()
						and AutoLibraryIsInRoom50(AutoLibraryLiveHintBook) then

						AutoLibraryHumanoidRootPart.CFrame = AutoLibraryBookCFrame
					end

					for _, AutoLibraryPromptDescendant in ipairs(AutoLibraryLiveHintBook:GetDescendants()) do
						if AutoLibraryPromptDescendant:IsA("ProximityPrompt")
							and AutoLibraryIsInRoom50(AutoLibraryPromptDescendant)
							and AutoLibraryIsActuallyInRoom50() then

							fireproximityprompt(AutoLibraryPromptDescendant)
						end
					end

					task.wait(0.05)
				end

				if AutoLibraryHintPaperObtained then
					break
				end
			end

			if AutoLibraryHasHintPaper() then
				AutoLibraryHintPaperObtained = true
				break
			end

			local AutoLibraryHintPaper = AutoLibraryRoom50:FindFirstChild("LibraryHintPaper", true)

			if AutoLibraryHintPaper
				and AutoLibraryIsInRoom50(AutoLibraryHintPaper)
				and AutoLibraryIsActuallyInRoom50() then

				while AutoLibraryEnabled
					and AutoLibraryIsActuallyInRoom50()
					and not AutoLibraryHintPaperObtained
					and AutoLibraryHintPaper.Parent
					and AutoLibraryIsInRoom50(AutoLibraryHintPaper) do

					if AutoLibraryHasHintPaper() then
						AutoLibraryHintPaperObtained = true
						break
					end

					AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild("HumanoidRootPart")

					if not AutoLibraryHumanoidRootPart then
						task.wait()
						continue
					end

					local AutoLibraryPaperCFrame = AutoLibraryGetObjectCFrame(AutoLibraryHintPaper)

					if AutoLibraryPaperCFrame
						and AutoLibraryIsActuallyInRoom50()
						and AutoLibraryIsInRoom50(AutoLibraryHintPaper) then

						AutoLibraryHumanoidRootPart.CFrame = AutoLibraryPaperCFrame * CFrame.new(0, 5, 0)
					end

					for _, AutoLibraryPromptDescendant in ipairs(AutoLibraryHintPaper:GetDescendants()) do
						if AutoLibraryPromptDescendant:IsA("ProximityPrompt")
							and AutoLibraryIsInRoom50(AutoLibraryPromptDescendant)
							and AutoLibraryIsActuallyInRoom50() then

							fireproximityprompt(AutoLibraryPromptDescendant)
						end
					end

					task.wait(0.05)
				end
			end

			task.wait(0.05)
		end
	end)
end)

Toggles.AutoBreakerRoom:OnChanged(function(AutoBreakerRoomEnabled)
	if AutoBreakerRoomConnection then
		task.cancel(AutoBreakerRoomConnection)
		AutoBreakerRoomConnection = nil
	end

	if AutoBreakerRoomRoomConnection then
		AutoBreakerRoomRoomConnection:Disconnect()
		AutoBreakerRoomRoomConnection = nil
	end

	if not AutoBreakerRoomEnabled then
		return
	end

	local AutoBreakerRoomGateFireTime = 5
	local AutoBreakerRoomWaitAfterLever = 5
	local AutoBreakerRoomBreakerSecondTime = 10
	local AutoBreakerRoomWaitBeforeWeb = 4
	local AutoBreakerRoomWebDuration = 20

	AutoBreakerRoomConnection = task.spawn(function()
		local AutoBreakerRoomPlayers = game:GetService("Players")
		local AutoBreakerRoomCurrentRooms = workspace:WaitForChild("CurrentRooms")
		local AutoBreakerRoom100 = AutoBreakerRoomCurrentRooms:WaitForChild("100")

		local function AutoBreakerRoomIsActuallyInRoom100()
			return tonumber(AutoBreakerRoomPlayers.LocalPlayer:GetAttribute("CurrentRoom")) == 100
		end

		local function AutoBreakerRoomIsInRoom100(AutoBreakerRoomObject)
			return AutoBreakerRoomObject
				and AutoBreakerRoomObject.Parent
				and AutoBreakerRoomObject:IsDescendantOf(AutoBreakerRoom100)
				and AutoBreakerRoomObject:IsDescendantOf(AutoBreakerRoomCurrentRooms)
		end

		local function AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomObject)
			if not AutoBreakerRoomIsActuallyInRoom100() or not AutoBreakerRoomIsInRoom100(AutoBreakerRoomObject) then
				return nil
			end

			if AutoBreakerRoomObject:IsA("Model") then
				return AutoBreakerRoomObject:GetPivot()
			elseif AutoBreakerRoomObject:IsA("BasePart") then
				return AutoBreakerRoomObject.CFrame
			end

			local AutoBreakerRoomPart = AutoBreakerRoomObject:FindFirstChildWhichIsA("BasePart", true)
			return AutoBreakerRoomPart and AutoBreakerRoomPart.CFrame
		end

		local function AutoBreakerRoomGetHRP()
			local AutoBreakerRoomCharacter = AutoBreakerRoomPlayers.LocalPlayer.Character
			return AutoBreakerRoomCharacter and AutoBreakerRoomCharacter:FindFirstChild("HumanoidRootPart")
		end

		local function AutoBreakerRoomActivate(AutoBreakerRoomObject)
			if not AutoBreakerRoomObject then
				return
			end

			if AutoBreakerRoomObject:IsA("ProximityPrompt") then
				fireproximityprompt(AutoBreakerRoomObject)
				return
			end

			for _, AutoBreakerRoomDescendant in ipairs(AutoBreakerRoomObject:GetDescendants()) do
				if AutoBreakerRoomDescendant:IsA("ProximityPrompt") then
					fireproximityprompt(AutoBreakerRoomDescendant)
				end
			end
		end

		local function AutoBreakerRoomConstantTPAndActivate(AutoBreakerRoomTarget, AutoBreakerRoomDuration, AutoBreakerRoomInterval, AutoBreakerRoomOffset)
			AutoBreakerRoomInterval = AutoBreakerRoomInterval or 0.04
			AutoBreakerRoomOffset = AutoBreakerRoomOffset or CFrame.new()
			local AutoBreakerRoomEndTime = os.clock() + (AutoBreakerRoomDuration or 3)

			while AutoBreakerRoomEnabled
				and AutoBreakerRoomIsActuallyInRoom100()
				and AutoBreakerRoomIsInRoom100(AutoBreakerRoomTarget)
				and os.clock() < AutoBreakerRoomEndTime do

				local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
				local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomTarget)

				if AutoBreakerRoomHRP and AutoBreakerRoomCF then
					AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF * AutoBreakerRoomOffset
				end

				AutoBreakerRoomActivate(AutoBreakerRoomTarget)
				task.wait(AutoBreakerRoomInterval)
			end
		end

		while AutoBreakerRoomEnabled do
			while AutoBreakerRoomEnabled and not AutoBreakerRoomIsActuallyInRoom100() do
				task.wait(0.1)
			end

			if not AutoBreakerRoomEnabled then
				return
			end

			local AutoBreakerRoomPoles = {}

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				AutoBreakerRoomPoles = {}

				for _, AutoBreakerRoomDescendant in ipairs(AutoBreakerRoom100:GetDescendants()) do
					if AutoBreakerRoomDescendant.Name == "LiveBreakerPolePickup" and AutoBreakerRoomIsInRoom100(AutoBreakerRoomDescendant) then
						if not table.find(AutoBreakerRoomPoles, AutoBreakerRoomDescendant) then
							table.insert(AutoBreakerRoomPoles, AutoBreakerRoomDescendant)
						end
					end
				end

				if #AutoBreakerRoomPoles == 0 then
					break
				end

				for _, AutoBreakerRoomPole in ipairs(AutoBreakerRoomPoles) do
					if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
						break
					end

					if AutoBreakerRoomIsInRoom100(AutoBreakerRoomPole) then
						AutoBreakerRoomConstantTPAndActivate(AutoBreakerRoomPole, 2.8, 0.03)
						task.wait(0.12)
					end
				end

				task.wait(0.05)
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomIndustrialGate = AutoBreakerRoom100:FindFirstChild("IndustrialGate")
			local AutoBreakerRoomBox = AutoBreakerRoomIndustrialGate and AutoBreakerRoomIndustrialGate:FindFirstChild("Box")
			local AutoBreakerRoomLever = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild("Lever")
			local AutoBreakerRoomActivateEventPrompt = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild("ActivateEventPrompt")

			if AutoBreakerRoomActivateEventPrompt and AutoBreakerRoomLever then
				local function AutoBreakerRoomGetLeverCFrame()
					if AutoBreakerRoomLever:IsA("Model") then
						return AutoBreakerRoomLever:GetPivot()
					elseif AutoBreakerRoomLever:IsA("BasePart") then
						return AutoBreakerRoomLever.CFrame
					end
					local AutoBreakerRoomPart = AutoBreakerRoomLever:FindFirstChildWhichIsA("BasePart", true)
					return AutoBreakerRoomPart and AutoBreakerRoomPart.CFrame
				end

				local AutoBreakerRoomInitialLeverCFrame = AutoBreakerRoomGetLeverCFrame()
				local AutoBreakerRoomLeverEndTime = os.clock() + 10

				while AutoBreakerRoomEnabled
					and AutoBreakerRoomIsActuallyInRoom100()
					and AutoBreakerRoomIsInRoom100(AutoBreakerRoomLever)
					and os.clock() < AutoBreakerRoomLeverEndTime do

					local AutoBreakerRoomCurrentLeverCFrame = AutoBreakerRoomGetLeverCFrame()

					if AutoBreakerRoomCurrentLeverCFrame and AutoBreakerRoomInitialLeverCFrame
						and AutoBreakerRoomCurrentLeverCFrame ~= AutoBreakerRoomInitialLeverCFrame then
						break
					end

					local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
					local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomBox)

					if AutoBreakerRoomHRP and AutoBreakerRoomCF then
						AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF
					end

					AutoBreakerRoomActivate(AutoBreakerRoomActivateEventPrompt)
					task.wait(0.04)
				end
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			task.wait(AutoBreakerRoomWaitAfterLever)

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomElevatorBreakerEmpty = AutoBreakerRoom100:FindFirstChild("ElevatorBreakerEmpty")
			if not AutoBreakerRoomElevatorBreakerEmpty then
				continue
			end

			local AutoBreakerRoomBreakerPrompt = AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild("Prompt")
			if not AutoBreakerRoomBreakerPrompt then
				continue
			end

			local AutoBreakerRoomBreakerOffset = CFrame.new(0, -1.8, 0)

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				if AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild("BreakerSwitchInBox") then
					break
				end

				local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
				local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomElevatorBreakerEmpty)

				if AutoBreakerRoomHRP and AutoBreakerRoomCF then
					AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF * AutoBreakerRoomBreakerOffset
				end

				AutoBreakerRoomActivate(AutoBreakerRoomBreakerPrompt)
				task.wait(0.04)
			end

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			task.wait(10)

			AutoBreakerRoomConstantTPAndActivate(
				AutoBreakerRoomElevatorBreakerEmpty,
				AutoBreakerRoomBreakerSecondTime,
				0.04,
				AutoBreakerRoomBreakerOffset
			)

			task.wait(AutoBreakerRoomWaitBeforeWeb)

			if not AutoBreakerRoomEnabled or not AutoBreakerRoomIsActuallyInRoom100() then
				continue
			end

			local AutoBreakerRoomElevatorCar = AutoBreakerRoom100:FindFirstChild("ElevatorCar")
			local AutoBreakerRoomWeb = AutoBreakerRoomElevatorCar and AutoBreakerRoomElevatorCar:FindFirstChild("Web", true)

			if AutoBreakerRoomWeb then
				local AutoBreakerRoomEndTime = os.clock() + AutoBreakerRoomWebDuration

				while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() and os.clock() < AutoBreakerRoomEndTime do
					local AutoBreakerRoomHRP = AutoBreakerRoomGetHRP()
					local AutoBreakerRoomCF = AutoBreakerRoomGetObjectCFrame(AutoBreakerRoomWeb)

					if AutoBreakerRoomHRP and AutoBreakerRoomCF then
						AutoBreakerRoomHRP.CFrame = AutoBreakerRoomCF
					end

					task.wait(0.04)
				end
			end

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				task.wait(0.5)
			end
		end
	end)
end)



local AutoHotelConnection
local AutoHotelLibraryConnection
local AutoHotelLibraryRoomConnection
local AutoHotelSeekConnection
local AutoHotelEntityPause = false
local AutoHotelRoomProcessTime = 0.5
local AutoHotelProcessedRooms = {}

local AutoHotelEntityNames = {
	["RushMoving"] = true,
	["Scribbles"] = true,
	["BashMoving"] = true,
	["DronesStampede"] = true,
	["AmbushMoving"] = true,
	["A60"] = true,
	["A120"] = true,
	["GlitchRush"] = true,
	["GlitchAmbush"] = true,
	["BackdoorRush"] = true,
	["CustomEntity"] = true,
}

local function AutoHotelIsEntityPresent()
	if Toggles.AutoHotelIgnoreEntities and Toggles.AutoHotelIgnoreEntities.Value then
		return false
	end
	for _, AutoHotelChild in ipairs(workspace:GetChildren()) do
		if AutoHotelEntityNames[AutoHotelChild.Name] then
			return true
		end
	end
	return false
end

local function AutoHotelWaitForEntities(AutoHotelSeconds)
	if Toggles.AutoHotelIgnoreEntities and Toggles.AutoHotelIgnoreEntities.Value then
		return
	end

	task.wait(AutoHotelSeconds or 5)

	while AutoHotelIsEntityPresent() do
		task.wait(0.15)
	end
end

local function AutoHotelGetNextClosedDoor()
	if not Character then return nil, nil end

	local AutoHotelGameData = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
	if not AutoHotelGameData then return nil, nil end

	local AutoHotelLatestRoom = AutoHotelGameData:FindFirstChild("LatestRoom")
	if not AutoHotelLatestRoom then return nil, nil end

	local AutoHotelStartRoom = AutoHotelLatestRoom.Value
	local AutoHotelBestDoor, AutoHotelBestNumber = nil, math.huge
	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")

	if AutoHotelCurrentRooms then
		for _, AutoHotelRoom in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local AutoHotelRoomNum = tonumber(AutoHotelRoom.Name)
			if AutoHotelRoomNum and AutoHotelRoomNum ~= 100 and AutoHotelRoomNum >= AutoHotelStartRoom and AutoHotelRoomNum < AutoHotelBestNumber then
				local AutoHotelDoor = AutoHotelRoom:FindFirstChild("Door")
				if AutoHotelDoor and AutoHotelDoor:IsA("Model") then
					local AutoHotelOpenAttr = AutoHotelDoor:GetAttribute("Open")
					if AutoHotelOpenAttr == false or AutoHotelOpenAttr == nil then
						AutoHotelBestNumber = AutoHotelRoomNum
						AutoHotelBestDoor = AutoHotelDoor
					end
				end
			end
		end
	end

	return AutoHotelBestDoor, AutoHotelBestNumber
end

local function AutoHotelFindKeyObtain(AutoHotelRoom)
	local AutoHotelFound = nil
	local function AutoHotelScan(AutoHotelParent)
		if AutoHotelFound then return end
		for _, AutoHotelChild in ipairs(AutoHotelParent:GetChildren()) do
			if AutoHotelChild.Name == "KeyObtain" then
				AutoHotelFound = AutoHotelChild
				return
			end
			AutoHotelScan(AutoHotelChild)
			if AutoHotelFound then return end
		end
	end
	AutoHotelScan(AutoHotelRoom)
	return AutoHotelFound
end

local function AutoHotelHandleKey(AutoHotelRoomNum)
	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if not AutoHotelCurrentRooms then return false end

	local AutoHotelRoom = AutoHotelCurrentRooms:FindFirstChild(tostring(AutoHotelRoomNum))
	if not AutoHotelRoom then return false end

	local AutoHotelDoor = AutoHotelRoom:FindFirstChild("Door")
	if not AutoHotelDoor or not AutoHotelDoor:FindFirstChild("Lock") then
		return false
	end

	local AutoHotelKeyObtain = AutoHotelFindKeyObtain(AutoHotelRoom)
	if not AutoHotelKeyObtain then return false end

	local AutoHotelStart = tick()
	while tick() - AutoHotelStart < 12 do
		if LocalPlayer.Backpack:FindFirstChild("Key") or (Character and Character:FindFirstChild("Key")) then
			return true
		end

		if Character then
			Character:PivotTo(AutoHotelKeyObtain:GetPivot())
		end

		for _, AutoHotelDesc in ipairs(AutoHotelKeyObtain:GetDescendants()) do
			if AutoHotelDesc:IsA("ProximityPrompt") then
				fireproximityprompt(AutoHotelDesc)
			end
		end

		task.wait(0.12)
	end
	return false
end

local function AutoHotelProcessRoom(AutoHotelRoomNum)
	if AutoHotelProcessedRooms[AutoHotelRoomNum] then
		return
	end
	task.wait(AutoHotelRoomProcessTime)
	AutoHotelProcessedRooms[AutoHotelRoomNum] = true
end

local function AutoHotelRunLibrary()
	local AutoHotelCurrentRooms = workspace:WaitForChild("CurrentRooms")
	local AutoHotelRoom50 = AutoHotelCurrentRooms:WaitForChild("50")
	local AutoHotelLiveHintBooks = {}
	local AutoHotelHintPaperObtained = false

	local function AutoHotelIsInRoom50(AutoHotelObj)
		return AutoHotelObj and AutoHotelObj:IsDescendantOf(AutoHotelRoom50)
	end

	local function AutoHotelIsActuallyInRoom50()
		return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) == 50
	end

	while Toggles.AutoHotel.Value and not AutoHotelIsActuallyInRoom50() do
		task.wait(0.1)
	end
	if not Toggles.AutoHotel.Value then return end

	AutoHotelWaitForEntities(5)

	local function AutoHotelHasHintPaper()
		local AutoHotelChar = LocalPlayer.Character
		if not AutoHotelChar then return false end
		return LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper", true) or AutoHotelChar:FindFirstChild("LibraryHintPaper", true)
	end

	local function AutoHotelGetCFrame(AutoHotelObj)
		if not AutoHotelIsActuallyInRoom50() or not AutoHotelIsInRoom50(AutoHotelObj) then return nil end
		if AutoHotelObj:IsA("Model") then return AutoHotelObj:GetPivot() end
		if AutoHotelObj:IsA("BasePart") then return AutoHotelObj.CFrame end
		local AutoHotelPart = AutoHotelObj:FindFirstChildWhichIsA("BasePart", true)
		return AutoHotelPart and AutoHotelPart.CFrame
	end

	local function AutoHotelCollectBooks()
		for _, AutoHotelDesc in ipairs(AutoHotelRoom50:GetDescendants()) do
			if AutoHotelDesc.Name == "LiveHintBook" and AutoHotelIsInRoom50(AutoHotelDesc) and not table.find(AutoHotelLiveHintBooks, AutoHotelDesc) then
				table.insert(AutoHotelLiveHintBooks, AutoHotelDesc)
			end
		end
	end

	AutoHotelCollectBooks()

	AutoHotelLibraryRoomConnection = AutoHotelRoom50.DescendantAdded:Connect(function(AutoHotelAdded)
		if Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and AutoHotelIsInRoom50(AutoHotelAdded) then
			if AutoHotelAdded.Name == "LiveHintBook" and not table.find(AutoHotelLiveHintBooks, AutoHotelAdded) then
				table.insert(AutoHotelLiveHintBooks, AutoHotelAdded)
			end
		end
	end)

	while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and #AutoHotelLiveHintBooks < 3 do
		AutoHotelCollectBooks()
		if #AutoHotelLiveHintBooks >= 3 then break end
		task.wait(0.1)
	end

	while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained do
		if AutoHotelHasHintPaper() then
			AutoHotelHintPaperObtained = true
			break
		end

		for AutoHotelIndex = #AutoHotelLiveHintBooks, 1, -1 do
			local AutoHotelBook = AutoHotelLiveHintBooks[AutoHotelIndex]
			if not AutoHotelIsInRoom50(AutoHotelBook) then
				table.remove(AutoHotelLiveHintBooks, AutoHotelIndex)
				continue
			end

			while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained and AutoHotelBook.Parent and AutoHotelIsInRoom50(AutoHotelBook) do
				if AutoHotelHasHintPaper() then
					AutoHotelHintPaperObtained = true
					break
				end

				local AutoHotelChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local AutoHotelHRP = AutoHotelChar:FindFirstChild("HumanoidRootPart")
				if not AutoHotelHRP then
					task.wait()
					continue
				end

				local AutoHotelCF = AutoHotelGetCFrame(AutoHotelBook)
				if AutoHotelCF then
					AutoHotelHRP.CFrame = AutoHotelCF
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelBook:GetDescendants()) do
					if AutoHotelPrompt:IsA("ProximityPrompt") then
						fireproximityprompt(AutoHotelPrompt)
					end
				end
				task.wait(0.08)
			end
			if AutoHotelHintPaperObtained then break end
		end

		if AutoHotelHasHintPaper() then
			AutoHotelHintPaperObtained = true
			break
		end

		local AutoHotelPaper = AutoHotelRoom50:FindFirstChild("LibraryHintPaper", true)
		if AutoHotelPaper and AutoHotelIsInRoom50(AutoHotelPaper) then
			while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained and AutoHotelPaper.Parent do
				if AutoHotelHasHintPaper() then
					AutoHotelHintPaperObtained = true
					break
				end

				local AutoHotelChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local AutoHotelHRP = AutoHotelChar:FindFirstChild("HumanoidRootPart")
				if AutoHotelHRP then
					local AutoHotelCF = AutoHotelGetCFrame(AutoHotelPaper)
					if AutoHotelCF then
						AutoHotelHRP.CFrame = AutoHotelCF * CFrame.new(0, 5, 0)
					end
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelPaper:GetDescendants()) do
					if AutoHotelPrompt:IsA("ProximityPrompt") then
						fireproximityprompt(AutoHotelPrompt)
					end
				end
				task.wait(0.08)
			end
		end
		task.wait(0.1)
	end
end

local function AutoHotelHandleSeek()
	local AutoHotelLastTriggerRoom = nil

	while Toggles.AutoHotel.Value do
		local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
		if not AutoHotelCurrentRooms then
			task.wait(0.2)
			continue
		end

		local TriggerRoomNum = nil

		for _, Room in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local Num = tonumber(Room.Name)
			if Num and Num ~= AutoHotelLastTriggerRoom then
				local Trigger = Room:FindFirstChild("TriggerEventCollision")
					or Room:FindFirstChild("TriggerEventCollision", true)

				if Trigger then
					TriggerRoomNum = Num
					break
				end
			end
		end

		if not TriggerRoomNum then
			task.wait(0.15)
			continue
		end

		AutoHotelLastTriggerRoom = TriggerRoomNum

		AutoHotelEntityPause = true
		AutoHotelWaitForEntities(10)
		AutoHotelEntityPause = false
	end
end

Toggles.AutoHotel:OnChanged(function(AutoHotelEnabled)
	if AutoHotelConnection then
		task.cancel(AutoHotelConnection)
		AutoHotelConnection = nil
	end
	if AutoHotelLibraryConnection then
		task.cancel(AutoHotelLibraryConnection)
		AutoHotelLibraryConnection = nil
	end
	if AutoHotelLibraryRoomConnection then
		AutoHotelLibraryRoomConnection:Disconnect()
		AutoHotelLibraryRoomConnection = nil
	end
	if AutoHotelSeekConnection then
		task.cancel(AutoHotelSeekConnection)
		AutoHotelSeekConnection = nil
	end

	AutoHotelEntityPause = false
	table.clear(AutoHotelProcessedRooms)

	if not AutoHotelEnabled then return end

	if Options.AutoHotelRoomProcess then
		AutoHotelRoomProcessTime = Options.AutoHotelRoomProcess.Value
		Options.AutoHotelRoomProcess:OnChanged(function(Value)
			AutoHotelRoomProcessTime = Value
		end)
	end

	local AutoHotelCurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if AutoHotelCurrentRooms then
		AutoHotelCurrentRooms.ChildAdded:Connect(function(AutoHotelChild)
			local AutoHotelNum = tonumber(AutoHotelChild.Name)
			if AutoHotelNum then
				AutoHotelProcessRoom(AutoHotelNum)
			end
		end)
	end

	AutoHotelSeekConnection = task.spawn(AutoHotelHandleSeek)

	task.spawn(function()
		while Toggles.AutoHotel.Value do
			if AutoHotelIsEntityPresent() then
				AutoHotelEntityPause = true
				while AutoHotelIsEntityPresent() and Toggles.AutoHotel.Value do
					task.wait(0.15)
				end
				AutoHotelEntityPause = false
			end
			task.wait(0.2)
		end
	end)

	AutoHotelConnection = task.spawn(function()
		while Toggles.AutoHotel.Value do
			if AutoHotelEntityPause then
				task.wait(0.1)
				continue
			end

			local AutoHotelDoor, AutoHotelRoomNum = AutoHotelGetNextClosedDoor()

			if AutoHotelDoor and AutoHotelRoomNum and Character then
				if AutoHotelRoomNum == 50 then
					if not AutoHotelLibraryConnection then
						AutoHotelLibraryConnection = task.spawn(function()
							AutoHotelRunLibrary()
							AutoHotelLibraryConnection = nil
						end)
					end
					task.wait(0.4)
				else
					AutoHotelProcessRoom(AutoHotelRoomNum)
					AutoHotelHandleKey(AutoHotelRoomNum)
					if Character and not AutoHotelEntityPause then
						Character:PivotTo(AutoHotelDoor:GetPivot() * CFrame.new(0, -1, 0))
					end
				end
			end
			task.wait(0.15)
		end
	end)
end)


Groupboxes.Debug = Tabs.General:AddRightGroupbox("Debug")
Groupboxes.Debug:AddButton({
	Text = "Ladder Softlock Fix",
	Tooltip = "Ladder Softlock Fix.",
	Func = function()
   		LocalPlayer:SetAttribute("Climbing", false)
	end
})
Groupboxes.Debug:AddButton({
	Text = "Get Current Floor",
	Tooltip = "Prints the current floor to the console.",
	Func = function()
		print("Current Floor:", GameData:WaitForChild("Floor").Value)
	end
})
Groupboxes.Debug:AddButton({
	Text = "Get Current Room",
	Tooltip = "Prints the current room number to the console.",
	Func = function()
		print("Current Room:", LocalPlayer:GetAttribute("CurrentRoom"))
	end
})
Groupboxes.Debug:AddButton({
	Text = "Void",
	Tooltip = "Teleports your character to Y -120.",
	Func = function()
		if not Character then return end
		local Pivot = Character:GetPivot()
		-- Too lazy to loop this
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
		Character:PivotTo(Pivot + Vector3.new(0, -120 - Pivot.Position.Y, 0))
	end
})
Groupboxes.Debug:AddButton({
	Text = "Death",
	Tooltip = "Death",
	Func = function()
		Globals.Deathing = true
		LocalPlayer.Character.Humanoid.Health = 0
	end
})
Groupboxes.Debug:AddButton({
	Text = "Exit Closet",
	Tooltip = "Exits the current closet.",
	Func = function()
		if RemotesFolder and RemotesFolder:FindFirstChild("CamLock") then
			RemotesFolder.CamLock:FireServer()
		end
	end
})
local TpNextDoorConnection

local function getNextClosedDoor()
	if not Character then return nil end

	local GameData = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
	if not GameData then return nil end

	local LatestRoom = GameData:FindFirstChild("LatestRoom")
	if not LatestRoom then return nil end

	local startRoom = LatestRoom.Value
	local bestDoor = nil
	local bestNumber = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Door" and obj:IsA("Model") then
			local openAttr = obj:GetAttribute("Open")
			if openAttr == false or openAttr == nil then
				local roomModel = obj.Parent
				local roomNum = tonumber(roomModel and roomModel.Name)

				if roomNum and roomNum >= startRoom and roomNum < bestNumber then
					bestNumber = roomNum
					bestDoor = obj
				end
			end
		end
	end

	return bestDoor
end

Groupboxes.Debug:AddButton({
	Text = "Tp Next Door",
	Tooltip = "Teleports you to the next sequential unopened door.",
	Func = function()
		local door = getNextClosedDoor()
		if door then
			Character:PivotTo(door:GetPivot() * CFrame.new(0, -1, 0))
		end
	end
})

Toggles.TpNextDoor = Groupboxes.Debug:AddToggle("TpNextDoor", {
	Text = "Auto Tp Next Door",
	Tooltip = "Continuously teleports you to the next sequential unopened door.",
	Default = false
})

Toggles.TpNextDoor:OnChanged(function(TpNextDoorEnabled)
	if TpNextDoorConnection then
		task.cancel(TpNextDoorConnection)
		TpNextDoorConnection = nil
	end

	if not TpNextDoorEnabled then
		return
	end

	TpNextDoorConnection = task.spawn(function()
		while Toggles.TpNextDoor.Value do
			local door = getNextClosedDoor()
			if door and Character then
				Character:PivotTo(door:GetPivot() * CFrame.new(0, -1, 0))
			end
			task.wait(0.15)
		end
		TpNextDoorConnection = nil
	end)
end)


Groupboxes.Exploits_Bypass = Tabs.Exploits:AddLeftGroupbox("Bypass / Solve")

Groupboxes.Exploits_Bypass:AddToggle("BypassGiggle",         { Text = "Bypass Giggle",           Default = false, Tooltip = "Prevents 'Giggle' from attacking you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassDupe",           { Text = "Bypass Dupe",             Default = false, Tooltip = "Prevents you from open 'Dupe' fake doors." })
Groupboxes.Exploits_Bypass:AddToggle("BypassEyes",           { Text = "Bypass Eyes",             Default = false, Tooltip = "Prevents 'Eyes' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassLookman",        { Text = "Bypass Lookman",          Default = false, Tooltip = "Prevents 'Lookman' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassGloombatEggs",   { Text = "Bypass Gloombat Eggs",    Default = false, Tooltip = "Prevents taking damage from stepping on 'Gloombat' eggs." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSeekObstructions", { Text = "Bypass Seek Obstructions", Default = false, Tooltip = "Prevents obstacles in the 'Seek' chase from harming you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassVacuum",         { Text = "Bypass Vacuum",           Default = false, Tooltip = "Prevents you from falling into 'Vacuum' fake doors." })
Groupboxes.Exploits_Bypass:AddToggle("BypassKillbricks",     { Text = "Bypass Killbricks",       Default = false, Tooltip = "Prevents 'Lava' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSeekingWall",    { Text = "Bypass Seeking Wall",     Default = false, Tooltip = "Prevents 'ScaryWall' from hurting you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassSnare",          { Text = "Bypass Snare",            Default = false, Tooltip = "Prevents 'Snare' from trapping you." })
Groupboxes.Exploits_Bypass:AddToggle("BypassBanana",         { Text = "Bypass Banana",           Default = false, Tooltip = "Prevents 'Banana Peel' from slipping you up (sometimes doesn't work)." })
Groupboxes.Exploits_Bypass:AddToggle("BypassJeff",           { Text = "Bypass Jeff",             Default = false, Tooltip = "Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work)." })


Toggles.BypassGiggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "GiggleCeiling" then
			Object:WaitForChild("Hitbox").CanTouch = not Value
		end
	end
end)
Toggles.BypassDupe:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "DoorFake" or Object.Name == "FakeDoor" then
			Object:WaitForChild("Hidden").CanTouch = not Value
			if Object:FindFirstChild("Lock") then
				Object.Lock.UnlockPrompt.Enabled = not Value
			end
		end
	end
end)
Toggles.BypassEyes:OnChanged(function(Value)
	if Value and Globals.IsEyes then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassLookman:OnChanged(function(Value)
	if Value and Globals.IsLookman then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassGloombatEggs:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Value
			end
		end
	end
end)
Toggles.BypassSeekObstructions:OnChanged(function(Value)
	for _, Object in Objects.SeekObstructions do
		Object.CanTouch = not Value
		if Object.Name == "SeekFloodline" then
			Object.CanCollide = Value
		end
	end
	for _, Object in Objects.SeekBridges do
		Object.CanCollide = Value
		Object.Transparency = Value and 0 or 1
	end
end)
Toggles.BypassVacuum:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "SideroomSpace" then
			Object:WaitForChild("Collision").CanCollide = Value
			Object:WaitForChild("Collision").CanTouch = not Value
		end
	end
end)
Toggles.BypassKillbricks:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "Lava" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassSeekingWall:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "ScaryWall" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanTouch = not Value
					Part.CanCollide = not Value
				end
			end
		end
	end
end)
Toggles.BypassSnare:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = not Value end
			end
		end
	end
end)
Toggles.BypassBanana:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "BananaPeel" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassJeff:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "JeffTheKiller" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanCollide = not Value
					Part.CanTouch = not Value
				end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	end
end)







-- Archives

Groupboxes.Archives_Misc = Tabs.Archives:AddRightGroupbox("Exploits / Anti")
Groupboxes.Archives_Misc:AddToggle("AntiRansom", { Text = "Anti Ransom", Default = false, Tooltip = "Prevents 'Ransom' from attacking you." })
Groupboxes.Archives_Misc:AddToggle("AntiClosetTrash", { Text = "Anti Closet Trash", Default = false, Tooltip = "Prevents 'Closet Trash' from spawning." })
Groupboxes.Archives_Misc:AddToggle("ForgetMeNotSolver", { Text = "Forget Me Not Skipper", Default = false, Tooltip = "Automatically Skippes Forget Me Not doors." })
Groupboxes.Archives_Misc:AddToggle("TimeShower", { Text = "Time Shower", Default = false, Tooltip = "Shows the Archives clock time." })
Groupboxes.Archives_Misc:AddToggle("BypassDronesStampede", { Text = "Stop Time/Anti Stampede", Default = false, Tooltip = "Prevents 'The Drones Stampede' from attacking you." })
Groupboxes.Archives_Misc:AddToggle("HonchoCorrectBoxESP", { Text = "Correct Box ESP/Auto Interact", Default = false, Tooltip = "ESP correct Archives boxes in the Honcho sequence and automatically interact with the correct deposit." })

TimeShowerLabel = Instance.new("TextLabel")
TimeShowerLabel.Name = "TimeShower"
TimeShowerLabel.AnchorPoint = Vector2.new(0, 1)
TimeShowerLabel.Position = UDim2.new(0, 12, 1, -12)
TimeShowerLabel.Size = UDim2.new(0, 180, 0, 32)
TimeShowerLabel.BackgroundTransparency = 1
TimeShowerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeShowerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TimeShowerLabel.TextStrokeTransparency = 0.35
TimeShowerLabel.Font = Enum.Font.GothamBold
TimeShowerLabel.TextSize = 18
TimeShowerLabel.TextXAlignment = Enum.TextXAlignment.Left
TimeShowerLabel.Text = "Time: --:--"
TimeShowerLabel.Visible = false
TimeShowerLabel.Parent = Container



local function GetArchivesClockLabel(Room)
	local Assets = Room and Room:FindFirstChild("Assets", true)
	local Clock = Assets and Assets:FindFirstChild("ArchivesClock", true)
	local Time = Clock and Clock:FindFirstChild("Time", true)
	local TextLabel = Time and Time:FindFirstChild("TextLabel")
	return (TextLabel and TextLabel:IsA("TextLabel")) and TextLabel or nil
end

local function ResolveClockLabel()
	if TimeShowerSourceLabel and TimeShowerSourceLabel.Parent and TimeShowerSourceLabel:IsDescendantOf(game) then
		return TimeShowerSourceLabel
	end
	local currentRooms = workspace:FindFirstChild("CurrentRooms")
	if not currentRooms then return nil end
	local rooms = {}
	for _, room in ipairs(currentRooms:GetChildren()) do
		local num = tonumber(room.Name)
		if num then
			rooms[#rooms + 1] = { room = room, num = num }
		end
	end
	table.sort(rooms, function(a, b) return a.num > b.num end)
	for i = 1, math.min(6, #rooms) do
		local label = GetArchivesClockLabel(rooms[i].room)
		if label then
			TimeShowerSourceLabel = label
			return label
		end
	end
	return nil
end

local function ResolveClockRemote()
	local label = ResolveClockLabel()
	if not label then return nil end
	local clock = label:FindFirstAncestor("ArchivesClock")
	if not clock then return nil end
	local remote = clock:FindFirstChild("LookedAtRemote", true)
	return (remote and remote:IsA("RemoteEvent")) and remote or nil
end

task.spawn(function()
	local lastCheckedRoomCount = 0
	while game:IsLoaded() do
		local currentRooms = workspace:FindFirstChild("CurrentRooms")
		if currentRooms then
			local roomCount = 0
			for _, child in ipairs(currentRooms:GetChildren()) do
				if tonumber(child.Name) then
					roomCount += 1
				end
			end
			if roomCount > 0 and (lastCheckedRoomCount == 0 or roomCount - lastCheckedRoomCount >= 10) then
				ResolveClockLabel()
				lastCheckedRoomCount = roomCount
			end
		end
		task.wait(0.5)
	end
end)

local function StopTimeShower()
	TimeShowerToken += 1
	if TimeShowerConnection then
		TimeShowerConnection:Disconnect()
		TimeShowerConnection = nil
	end
	if TimeShowerLabel then
		TimeShowerLabel.Visible = false
		TimeShowerLabel.Text = "Time: --:--"
	end
end

Toggles.TimeShower:OnChanged(function(Value)
	StopTimeShower()
	if not Value then return end
	local Token = TimeShowerToken
	TimeShowerLabel.Visible = true
	TimeShowerConnection = Services.RunService.Heartbeat:Connect(function()
		if Token ~= TimeShowerToken then return end
		local TextLabel = ResolveClockLabel()
		TimeShowerLabel.Text = TextLabel and ("Time: " .. TextLabel.Text) or "Time: --:--"
	end)
end)

Toggles.BypassDronesStampede:OnChanged(function(enabled)
	if BypassDronesStampedeConnection then
		task.cancel(BypassDronesStampedeConnection)
		BypassDronesStampedeConnection = nil
	end
	if not enabled then return end
	BypassDronesStampedeConnection = task.spawn(function()
		while Toggles.BypassDronesStampede.Value do
			local remote = ResolveClockRemote()
			if remote then
				remote:FireServer()
				task.wait(0.5)
			else
				task.wait(0.25)
			end
		end
	end)
end)

local function ClearHonchoESP()
	if HonchoCorrectBoxConnection then
		HonchoCorrectBoxConnection:Disconnect()
		HonchoCorrectBoxConnection = nil
	end
	if HonchoAutoDepositConnection then
		HonchoAutoDepositConnection:Disconnect()
		HonchoAutoDepositConnection = nil
	end
	for _, Object in pairs(HonchoESPObjects) do
		if Object and Object.Parent then
			Functions.RemoveESP(Object)
		end
	end
	table.clear(HonchoESPObjects)
	table.clear(HonchoProcessedRooms)
	table.clear(HonchoDepositCache)
end

Toggles.HonchoCorrectBoxESP:OnChanged(function(Value)
	ClearHonchoESP()
	if not Value then return end
	local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
	if not CurrentRooms then return end

	local function GetESPColor()
		return (Options.ObjectiveESPColor and Options.ObjectiveESPColor.Value) or Color3.fromRGB(0, 255, 0)
	end

	local function AddHonchoESP(Object, Text)
		Functions.AddESP({ Object = Object, Text = Text, Color = GetESPColor() }, true)
		HonchoESPObjects[#HonchoESPObjects + 1] = Object
		Object.Destroying:Once(function()
			Functions.RemoveESP(Object)
			local pos = table.find(HonchoESPObjects, Object)
			if pos then table.remove(HonchoESPObjects, pos) end
		end)
	end

	local function ProcessHonchoRoom(Room)
		if not tonumber(Room.Name) or not Room.Parent or HonchoProcessedRooms[Room] then return end
		HonchoProcessedRooms[Room] = true
		task.wait(3)
		if not Toggles.HonchoCorrectBoxESP.Value or not Room.Parent then
			HonchoProcessedRooms[Room] = nil
			return
		end
		local HonchoRoom = Room:FindFirstChild("ArchivesHonchoRoom", true)
		if not HonchoRoom then
			HonchoProcessedRooms[Room] = nil
			return
		end
		local BoxIDs = {}
		local RoomNumber = tonumber(Room.Name)
		for _, Desc in ipairs(Room:GetDescendants()) do
			local name = Desc.Name
			if name == "ArchivesPackageDeposit" or name:match("^ArchivesPackageDeposit") then
				local id = Desc:GetAttribute("BoxID")
				if id ~= nil then
					local idStr = tostring(id)
					BoxIDs[idStr] = true
					HonchoDepositCache[idStr] = Desc
					AddHonchoESP(Desc, "Deposit (" .. idStr .. ")")
					Desc.Destroying:Once(function()
						if HonchoDepositCache[idStr] == Desc then
							HonchoDepositCache[idStr] = nil
						end
					end)
				end
			end
		end
		if not next(BoxIDs) then
			HonchoProcessedRooms[Room] = nil
			return
		end
		for _, Child in ipairs(HonchoRoom:GetDescendants()) do
			if Child.Name == "ArchivesStorageBox" then
				local ToolBoxID = Child:GetAttribute("Tool_BoxID")
				if ToolBoxID ~= nil and BoxIDs[tostring(ToolBoxID)] then
					if not Child:GetAttribute("ParentRoom") then
						Child:SetAttribute("ParentRoom", RoomNumber)
					end
					Child.Name = "ArchivesStorageBoxCorrect"
					AddHonchoESP(Child, "Correct Box (" .. tostring(ToolBoxID) .. ")")
				end
			end
		end
	end

	for _, Room in ipairs(CurrentRooms:GetChildren()) do
		task.spawn(ProcessHonchoRoom, Room)
	end

	HonchoCorrectBoxConnection = CurrentRooms.ChildAdded:Connect(function(Room)
		task.spawn(ProcessHonchoRoom, Room)
	end)

	local lastCheck = 0
	HonchoAutoDepositConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if not Toggles.HonchoCorrectBoxESP.Value then return end
		local now = os.clock()
		if now - lastCheck < 0.1 then return end
		lastCheck = now
		local Character = LocalPlayer and LocalPlayer.Character
		local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
		if not Character or not HumanoidRootPart then return end
		local BoxCandidates = {}
		for _, Object in ipairs(Character:GetChildren()) do
			if (Object:IsA("Tool") or Object:IsA("Model")) and (Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect") then
				BoxCandidates[#BoxCandidates + 1] = Object
			end
		end
		local Drops = workspace:FindFirstChild("Drops")
		if Drops then
			for _, Object in ipairs(Drops:GetChildren()) do
				if Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect" then
					BoxCandidates[#BoxCandidates + 1] = Object
				end
			end
		end
		for _, Box in ipairs(BoxCandidates) do
			if not (Box and Box.Parent) then continue end
			local BoxID = Box:GetAttribute("Tool_BoxID") or Box:GetAttribute("BoxID")
			if BoxID == nil then continue end
			local Deposit = HonchoDepositCache[tostring(BoxID)]
			if not Deposit or not Deposit.Parent then continue end
			if Box.Parent == Drops and not Box:GetAttribute("HonchoCorrectESP") then
				Box:SetAttribute("HonchoCorrectESP", true)
				AddHonchoESP(Box, "Correct Box (" .. tostring(BoxID) .. ")")
			end
			if Box.Parent == Character then
				local DepositPart = Deposit:IsA("BasePart") and Deposit or Deposit:FindFirstChildWhichIsA("BasePart", true)
				if DepositPart and (HumanoidRootPart.Position - DepositPart.Position).Magnitude <= 10 then
					local Prompt = Deposit:FindFirstChildWhichIsA("ProximityPrompt", true)
					if Prompt then
						fireproximityprompt(Prompt)
					end
				end
			end
		end
	end)
end)


Groupboxes.Archives_Bypasses = Tabs.Archives:AddLeftGroupbox("Bypasses")
Groupboxes.Archives_Bypasses:AddToggle("BypassWater", { Text = "Bypass Electric Water", Default = false, Tooltip = "Prevents electric water from hurting you." })
Groupboxes.Archives_Bypasses:AddToggle("BypassAlma", { Text = "Bypass Alma", Default = false, Tooltip = "Prevents 'Alma' from spawning." })
Groupboxes.Archives_Bypasses:AddToggle("BypassDrones", { Text = "Bypass Drones", Default = false, Tooltip = "Prevents 'Drones' from attacking you." })
Groupboxes.Archives_Bypasses:AddToggle("AntiScribbles", { Text = "Bypass Scribbles", Default = false, Tooltip = "Prevents 'Scribbles' from attacking you." })

Groupboxes.Archives_Experimental = Tabs.Archives:AddLeftGroupbox("Experimental")

Toggles.AntiClosetTrash:OnChanged(function(Value)
	if AntiClosetTrash_Connection then
		AntiClosetTrash_Connection:Disconnect()
		AntiClosetTrash_Connection = nil
	end
	if not Value then return end
	AntiClosetTrash_Connection = workspace.ChildAdded:Connect(function(Child)
		if not Toggles.AntiClosetTrash.Value then return end
		local Name = Child.Name
		if Name:sub(1, 6) == "Binder" or Name:sub(1, 4) == "Shoe" or Name:sub(1, 5) == "Shelf" then
			Child:Destroy()
		end
	end)
end)

Toggles.AntiRansom:OnChanged(function(Value)
	if AntiRansom_Connection then
		AntiRansom_Connection:Disconnect()
		AntiRansom_Connection = nil
	end
	if not Value then return end
	AntiRansom_Connection = workspace.ChildAdded:Connect(function(Child)
		if Child.Name == "Ransom" and Toggles.AntiRansom.Value then
			Child:Destroy()
			print("Ransom gone hehehehehehehehe")
		end
	end)
end)

Toggles.ForgetMeNotSolver:OnChanged(function(Value)
	if ForgetMeNotConnection then
		ForgetMeNotConnection:Disconnect()
		ForgetMeNotConnection = nil
	end
	ForgetMeNotRunning = false
	table.clear(ForgetMeNotProcessing)
	table.clear(ForgetMeNotNotified)
	if not Value then return end
	ForgetMeNotRunning = true

	local function GetCharacter()
		return game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	end

	local function GetNextRoom(Number)
		while ForgetMeNotRunning do
			for RoomNumber = Number + 1, Number + 5 do
				local NextRoom = workspace.CurrentRooms:FindFirstChild(tostring(RoomNumber))
				if NextRoom then return NextRoom end
			end
			task.wait(0.1)
		end
		return nil
	end

	local function FireLookAts(Room)
		for i = 1, 6 do
			local Obj = Room:FindFirstChild(tostring(i))
			if Obj then
				local LookAt = Obj:FindFirstChild("LookAt")
				if LookAt then
					pcall(function() LookAt:FireServer() end)
				end
			end
		end
	end

	local function VoidCharacter()
		local Character = GetCharacter()
		if not Character then return end

		local voidCF = CFrame.new(0, -120, 0)
		local start = tick()
		while ForgetMeNotRunning and tick() - start < 2 do
			Character:PivotTo(voidCF)
			task.wait(0.1)
		end
	end

	local function Run(Room)
		local RoomNumber = tonumber(Room.Name)
		if not RoomNumber or not ForgetMeNotRunning or ForgetMeNotProcessing[RoomNumber] then return end

		if not Room:FindFirstChild("ForgetMeNotVineDoors", true) then
			return
		end

		ForgetMeNotProcessing[RoomNumber] = true

		while ForgetMeNotRunning and Room.Parent do
			FireLookAts(Room)

			local NextRoom = GetNextRoom(RoomNumber)
			if not NextRoom then
				task.wait(0.4)
				continue
			end

			local Door = NextRoom:FindFirstChild("Door")

			if not Door then
				local Character = GetCharacter()
				if Character then
					local Target = NextRoom:FindFirstChildWhichIsA("BasePart") or NextRoom
					if Target:IsA("BasePart") then
						Character:PivotTo(Target.CFrame + Vector3.new(0, 3, 0))
					elseif Target:IsA("Model") then
						Character:PivotTo(Target:GetPivot() + Vector3.new(0, 3, 0))
					else
						Character:PivotTo(CFrame.new(NextRoom:GetPivot().Position + Vector3.new(0, 5, 0)))
					end
				end
				break
			end

			if Door:GetAttribute("Opened") == true then
				VoidCharacter()
				break
			end

			local Hidden = Door:FindFirstChild("Hidden") or Door:WaitForChild("Hidden", 2)
			if not Hidden then
				task.wait(0.3)
				continue
			end

			while ForgetMeNotRunning and Room.Parent and NextRoom.Parent and Door.Parent and Door:GetAttribute("Opened") ~= true do
				local Character = GetCharacter()
				if Character then
					if Hidden:IsA("BasePart") then
						Character:PivotTo(Hidden.CFrame)
					elseif Hidden:IsA("Model") then
						Character:PivotTo(Hidden:GetPivot())
					end
				end
				pcall(function() Door.ClientOpen:Fire() end)
				pcall(function() Door.ClientOpen:FireServer() end)
				task.wait()
			end

			if ForgetMeNotRunning and Door.Parent and Door:GetAttribute("Opened") == true then
				VoidCharacter()
			end

			break
		end

		ForgetMeNotProcessing[RoomNumber] = nil
	end

	local function CheckRooms()
		local LatestRoomNumber = tonumber(LatestRoom.Value) or 0
		local FirstRoomNumber = math.max(0, LatestRoomNumber - 3)
		for RoomNumber = FirstRoomNumber, LatestRoomNumber do
			if not ForgetMeNotRunning then return end
			local Room = workspace.CurrentRooms:FindFirstChild(tostring(RoomNumber))
			if Room and not ForgetMeNotProcessing[RoomNumber] then
				task.spawn(Run, Room)
			end
		end
	end

	ForgetMeNotConnection = workspace.CurrentRooms.ChildAdded:Connect(function(Room)
		if not tonumber(Room.Name) then return end
		task.spawn(function()
			task.wait(1)
			if ForgetMeNotRunning and Room.Parent then
				task.spawn(Run, Room)
			end
		end)
	end)

	task.spawn(function()
		while ForgetMeNotRunning do
			CheckRooms()
			task.wait(1)
		end
	end)

	CheckRooms()
end)

Toggles.BypassWater:OnChanged(function(Value)
	Functions.Notify({ Title = "PositionSpoof Will Break This!." })

	if WaterBypassConnection then
		WaterBypassConnection:Disconnect()
		WaterBypassConnection = nil
	end

	if not Value then
		for _, WaterBypassPart in pairs(WaterParts) do
			if WaterBypassPart then
				WaterBypassPart:Destroy()
			end
		end
		table.clear(WaterParts)
		return
	end

	local CurrentRooms = workspace.CurrentRooms

	local function ProcessWaterBypassRoom(WaterBypassRoom)
		if not tonumber(WaterBypassRoom.Name) then return end

		task.wait(3)

		local WaterBypassWater = WaterBypassRoom:FindFirstChild("Water")
		if not WaterBypassWater or WaterParts[WaterBypassWater] then return end

		local WaterBypassPart = Instance.new("Part")
		WaterBypassPart.Name = "WaterBypass"
		WaterBypassPart.Anchored = true
		WaterBypassPart.CanCollide = true
		WaterBypassPart.CanTouch = false
		WaterBypassPart.CanQuery = false
		WaterBypassPart.Transparency = 0.25
		WaterBypassPart.Color = Color3.fromRGB(0, 150, 255)
		WaterBypassPart.Material = Enum.Material.ForceField

		local WaterBypassSize, WaterBypassCFrame
		if WaterBypassWater:IsA("BasePart") then
			WaterBypassSize = WaterBypassWater.Size
			WaterBypassCFrame = WaterBypassWater.CFrame
		elseif WaterBypassWater:IsA("Model") then
			WaterBypassCFrame, WaterBypassSize = WaterBypassWater:GetBoundingBox()
		else
			WaterBypassSize = Vector3.new(10, 1.5, 10)
			WaterBypassCFrame = WaterBypassWater:GetPivot()
		end

		WaterBypassPart.Size = WaterBypassSize + Vector3.new(0, 0.5, 0)
		WaterBypassPart.CFrame = WaterBypassCFrame * CFrame.new(0, 0.25, 0)

		if WaterBypassPart.Size.Y > 3 then
			WaterBypassPart:Destroy()
			Functions.Notify({ Title = "Water Bypass removed: Softlock." })
			return
		end

		WaterBypassPart.Parent = WaterBypassRoom
		WaterParts[WaterBypassWater] = WaterBypassPart
	end

	local WaterBypassLatestRoomNumber = tonumber(LatestRoom.Value) or 0
	for WaterBypassRoomNumber = math.max(0, WaterBypassLatestRoomNumber - 4), WaterBypassLatestRoomNumber do
		local WaterBypassRoom = CurrentRooms:FindFirstChild(tostring(WaterBypassRoomNumber))
		if WaterBypassRoom then
			task.spawn(ProcessWaterBypassRoom, WaterBypassRoom)
		end
	end

	WaterBypassConnection = CurrentRooms.ChildAdded:Connect(function(WaterBypassRoom)
		task.spawn(ProcessWaterBypassRoom, WaterBypassRoom)
	end)
end)

Toggles.BypassAlma:OnChanged(function(Value)
	if AlmaConnection then
		AlmaConnection:Disconnect()
		AlmaConnection = nil
	end
	if Value then
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "Alma" then child:Destroy() end
		end
		AlmaConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == "Alma" then child:Destroy() end
		end)
	end
end)

Toggles.AntiScribbles:OnChanged(function(Value)
	if AntiScribbles_Connection then
		AntiScribbles_Connection:Disconnect()
		AntiScribbles_Connection = nil
	end
	if not Value then return end
	AntiScribbles_Connection = workspace.ChildAdded:Connect(function(Child)
		if Child.Name == "Scribbles" and Toggles.AntiScribbles.Value then
			local ExploitSribbleWarning = Child:FindFirstChild("IfYoureExploitingDeleteThis")
			if ExploitSribbleWarning then ExploitSribbleWarning:Destroy() end
		end
	end)
end)

Toggles.BypassDrones:OnChanged(function(Value)
	local RS = game:GetService("ReplicatedStorage")
	local function ProcessDrones(drones)
		local WalkedInto = drones:FindFirstChild("WalkedInto") or drones:WaitForChild("WalkedInto", 3)
		if WalkedInto and not DroneWalkedIntoParents[WalkedInto] then
			DroneWalkedIntoParents[WalkedInto] = drones
			WalkedInto.Parent = RS
		end
	end
	if Value then
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "Drones" then ProcessDrones(child) end
		end
		if DroneConnection then DroneConnection:Disconnect() end
		DroneConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == "Drones" then ProcessDrones(child) end
		end)
	else
		for WalkedInto, originalParent in pairs(DroneWalkedIntoParents) do
			if WalkedInto and WalkedInto.Parent and originalParent and originalParent.Parent then
				WalkedInto.Parent = originalParent
			end
		end
		table.clear(DroneWalkedIntoParents)
		if DroneConnection then
			DroneConnection:Disconnect()
			DroneConnection = nil
		end
	end
end)

Groupboxes.Stairwell_Misc = Tabs.Stairwell:AddLeftGroupbox("Exploits / Anti / Misc")



Groupboxes.Stairwell_Misc:AddDivider()
Groupboxes.Stairwell_Misc:AddToggle("BypassNoise", { Text = "Noise Tv Breaker", Default = false, Tooltip = "Breaks the tv of noise while holding it." })


Groupboxes.Stairwell_Misc:AddToggle("DroppedItemValue", { Text = "Item Number", Default = false, Tooltip = "Shows the number of dropped items." })

Groupboxes.Stairwell_Misc:AddToggle("KillAllWithCart", {
	Text = "Kill All (Requires ≥1 Cart)",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("FlingCreak", {
	Text = "Bug Out Creak (Requires ≥5 Cart)",
	Default = false,
	ToolTip = "DONT TOUCH THE CARTS URSELF, U WILL DIE"
})
Groupboxes.Stairwell_Misc:AddToggle("CreakAggressionMeter", {
    Text = "Creak Aggression Meter",
    Default = false,
    Tooltip = "Shows Creak's aggression above its head."
})

local CreakAggressionMetersTable = {}
local CreakAggressionCamera = Workspace.CurrentCamera
local CreakAggressionChildAddedConnection = nil

local function CleanupCreakAggressionMeter(CreakModel)
    local CreakMeterData = CreakAggressionMetersTable[CreakModel]
    if not CreakMeterData then return end

    CreakAggressionMetersTable[CreakModel] = nil

    if CreakMeterData.RenderConnection then
        CreakMeterData.RenderConnection:Disconnect()
    end
    if CreakMeterData.DestroyConnection then
        CreakMeterData.DestroyConnection:Disconnect()
    end

    for _, CreakDrawingObject in ipairs(CreakMeterData.Drawings) do
        pcall(function() CreakDrawingObject:Remove() end)
    end
end

local function GetCreakAggressionValue(CreakModel)
    local CreakAnimator = CreakModel:FindFirstChildOfClass("Animator")
        or (CreakModel:FindFirstChild("AnimationController") and CreakModel.AnimationController:FindFirstChildOfClass("Animator"))
        or CreakModel:FindFirstChildOfClass("AnimationController")

    if not CreakAnimator then return nil end

    for _, CreakAnimationTrack in ipairs(CreakAnimator:GetPlayingAnimationTracks()) do
        if CreakAnimationTrack.Name == "CreakGraph" or (CreakAnimationTrack.Animation and CreakAnimationTrack.Animation.Name == "CreakGraph") then
            local CreakSuccess, CreakAggressionValue = pcall(CreakAnimationTrack.GetParameter, CreakAnimationTrack, "Aggression")
            if CreakSuccess and typeof(CreakAggressionValue) == "number" then
                return math.clamp(CreakAggressionValue, 0, 1)
            end
        end
    end
    return nil
end

local function CreateCreakAggressionDrawings()
    local CreakDrawingList = {}

    local function CreateCreakDrawing(CreakDrawingType)
        local CreakNewDrawing = Drawing.new(CreakDrawingType)
        table.insert(CreakDrawingList, CreakNewDrawing)
        return CreakNewDrawing
    end

    local CreakTitleText = CreateCreakDrawing("Text")
    CreakTitleText.Text = "Aggression --%"
    CreakTitleText.Size = 16
    CreakTitleText.Font = Drawing.Fonts.Plex
    CreakTitleText.Color = Color3.fromRGB(255, 255, 255)
    CreakTitleText.Center = true
    CreakTitleText.Outline = true
    CreakTitleText.Visible = false

    local CreakBarBackground = CreateCreakDrawing("Square")
    CreakBarBackground.Size = Vector2.new(112, 6)
    CreakBarBackground.Filled = true
    CreakBarBackground.Color = Color3.fromRGB(58, 58, 64)
    CreakBarBackground.Transparency = 0.15
    CreakBarBackground.Visible = false

    local CreakBarFill = CreateCreakDrawing("Square")
    CreakBarFill.Size = Vector2.new(0, 6)
    CreakBarFill.Filled = true
    CreakBarFill.Visible = false

    return {
        Drawings = CreakDrawingList,
        TitleText = CreakTitleText,
        BarBackground = CreakBarBackground,
        BarFill = CreakBarFill
    }
end

local function AddCreakAggressionMeter(CreakModel)
    if not Toggles.CreakAggressionMeter.Value or CreakModel.Name ~= "Creak" or CreakAggressionMetersTable[CreakModel] then
        return
    end

    local CreakHeadPart = CreakModel:FindFirstChild("Head")
    if not CreakHeadPart or not CreakHeadPart:IsA("BasePart") then return end

    local CreakMeterData = CreateCreakAggressionDrawings()
    CreakAggressionMetersTable[CreakModel] = CreakMeterData

    CreakMeterData.RenderConnection = RunService.RenderStepped:Connect(function()
        if not Toggles.CreakAggressionMeter.Value or not CreakModel.Parent or not CreakHeadPart.Parent then
            CleanupCreakAggressionMeter(CreakModel)
            return
        end

        if not CreakAggressionCamera or not CreakAggressionCamera.Parent then
            CreakAggressionCamera = Workspace.CurrentCamera
            if not CreakAggressionCamera then return end
        end

        local CreakScreenPosition, CreakIsOnScreen = CreakAggressionCamera:WorldToViewportPoint(CreakHeadPart.Position + Vector3.new(0, 1.85, 0))
        if not (CreakIsOnScreen and CreakScreenPosition.Z > 0) then
            CreakMeterData.TitleText.Visible = false
            CreakMeterData.BarBackground.Visible = false
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Position = Vector2.new(CreakScreenPosition.X, CreakScreenPosition.Y - 28)
        CreakMeterData.BarBackground.Position = Vector2.new(CreakScreenPosition.X - 56, CreakScreenPosition.Y - 6)
        CreakMeterData.BarFill.Position = CreakMeterData.BarBackground.Position

        local CreakAggressionValue = GetCreakAggressionValue(CreakModel)

        if not CreakAggressionValue then
            CreakMeterData.TitleText.Text = "Aggression --%"
            CreakMeterData.TitleText.Color = Color3.fromRGB(200, 200, 200)
            CreakMeterData.BarFill.Size = Vector2.new(0, 6)
            CreakMeterData.TitleText.Visible = true
            CreakMeterData.BarBackground.Visible = true
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Text = "Aggression " .. math.floor(CreakAggressionValue * 100 + 0.5) .. "%"
        CreakMeterData.TitleText.Color = Color3.fromRGB(255, 255, 255)
        CreakMeterData.BarFill.Size = Vector2.new(112 * CreakAggressionValue, 6)
        CreakMeterData.BarFill.Color = Color3.fromRGB(70, 220, 100):Lerp(Color3.fromRGB(255, 55, 55), CreakAggressionValue)
        CreakMeterData.TitleText.Visible = true
        CreakMeterData.BarBackground.Visible = true
        CreakMeterData.BarFill.Visible = true
    end)

    CreakMeterData.DestroyConnection = CreakModel.Destroying:Connect(function()
        CleanupCreakAggressionMeter(CreakModel)
    end)
end

local function StartCreakAggressionListener()
    if CreakAggressionChildAddedConnection then return end

    local CreakLiveEntitiesFolder = Workspace:FindFirstChild("LiveEntities")
    if not CreakLiveEntitiesFolder then return end

    CreakAggressionChildAddedConnection = CreakLiveEntitiesFolder.ChildAdded:Connect(function(CreakNewChild)
        if CreakNewChild.Name == "Creak" then
            AddCreakAggressionMeter(CreakNewChild)
        end
    end)
end

local function StopCreakAggressionListener()
    if CreakAggressionChildAddedConnection then
        CreakAggressionChildAddedConnection:Disconnect()
        CreakAggressionChildAddedConnection = nil
    end
end

Toggles.CreakAggressionMeter:OnChanged(function(CreakToggleEnabled)
    if CreakToggleEnabled then
        for _, CreakEntityModel in ipairs(Objects.Entities or {}) do
            AddCreakAggressionMeter(CreakEntityModel)
        end

        local CreakLiveEntitiesFolder = Workspace:FindFirstChild("LiveEntities")
        local CreakExistingModel = CreakLiveEntitiesFolder and CreakLiveEntitiesFolder:FindFirstChild("Creak")
        if CreakExistingModel then
            AddCreakAggressionMeter(CreakExistingModel)
        end

        StartCreakAggressionListener()
    else
        StopCreakAggressionListener()

        for CreakEntityModel in pairs(CreakAggressionMetersTable) do
            CleanupCreakAggressionMeter(CreakEntityModel)
        end
    end
end)

Toggles.KillAllWithCart:OnChanged(function(KillAllWithCartState)
	if not KillAllWithCartState then return end

	local KillAllWithCartIndex = 1

	task.spawn(function()
		while Toggles.KillAllWithCart.Value do
			local KillAllWithCartCarts = {}
			for _, KillAllWithCartModel in ipairs(workspace.Misc:GetChildren()) do
				if KillAllWithCartModel.Name == "ShoppingCart" and KillAllWithCartModel:IsA("Model") then
					KillAllWithCartCarts[#KillAllWithCartCarts + 1] = KillAllWithCartModel
				end
			end

			local KillAllWithCartAlivePlayers = {}
			for _, KillAllWithCartPlayer in ipairs(game.Players:GetPlayers()) do
				if KillAllWithCartPlayer ~= game.Players.LocalPlayer and KillAllWithCartPlayer.Character then
					local KillAllWithCartHumanoid = KillAllWithCartPlayer.Character:FindFirstChildOfClass("Humanoid")
					if KillAllWithCartHumanoid and KillAllWithCartHumanoid.Health > 0 then
						KillAllWithCartAlivePlayers[#KillAllWithCartAlivePlayers + 1] = KillAllWithCartPlayer
					end
				end
			end

			if #KillAllWithCartCarts > 0 and #KillAllWithCartAlivePlayers > 0 then
				if KillAllWithCartIndex > #KillAllWithCartAlivePlayers then
					KillAllWithCartIndex = 1
				end
				local KillAllWithCartTarget = KillAllWithCartAlivePlayers[KillAllWithCartIndex]
				local KillAllWithCartTargetCFrame = KillAllWithCartTarget.Character:GetPivot()
				for KillAllWithCartCartIndex = 1, #KillAllWithCartCarts do
					KillAllWithCartCarts[KillAllWithCartCartIndex]:PivotTo(KillAllWithCartTargetCFrame)
				end
				KillAllWithCartIndex = KillAllWithCartIndex + 1
			end
			task.wait(0.10)
		end
	end)
end)

Toggles.FlingCreak:OnChanged(function(FlingCreakState)
	if not FlingCreakState then return end

	task.spawn(function()
		while Toggles.FlingCreak.Value do
			local creak = workspace:FindFirstChild("LiveEntities") and workspace.LiveEntities:FindFirstChild("Creak")
			if creak then
				local targetCFrame = creak:GetPivot()
				for _, model in ipairs(workspace.Misc:GetChildren()) do
					if model.Name == "ShoppingCart" and model:IsA("Model") then
						model:PivotTo(targetCFrame)
					end
				end
			end
			task.wait(0.10)
		end
	end)
end)




Groupboxes.Stairwell_Misc:AddDivider()


Groupboxes.Stairwell_Misc:AddToggle("DisableStairwellCrusherCollision", {
	Text = "Disable Crushers",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("DeleteStairwellCrusherExceptBasicWall", {
	Text = "Delete Crushers",
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle("MeldRemover", {
	Text = "Remove Meld",
	Default = false,
})

Groupboxes.Stairwell_Misc:AddToggle("StairwellLandingSpam", {
	Text = "TP to trash and drop trash.",
	Tooltip = "Combine with orbit, or bring all dropped items.",
	Default = false,
})

Toggles.DisableStairwellCrusherCollision:OnChanged(function(DisableStairwellCrusherCollisionState)
	if not DisableStairwellCrusherCollisionState then return end

	task.spawn(function()
		while Toggles.DisableStairwellCrusherCollision.Value do
			for _, DisableStairwellCrusherRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
				local DisableStairwellCrusherAssets = DisableStairwellCrusherRoom:FindFirstChild("Assets")
				if DisableStairwellCrusherAssets then
					for _, DisableStairwellCrusherContainer in ipairs(DisableStairwellCrusherAssets:GetChildren()) do
						if DisableStairwellCrusherContainer.Name == "StairwellCrusherContainer1" then
							for _, DisableStairwellCrusherDescendant in ipairs(DisableStairwellCrusherContainer:GetDescendants()) do
								if DisableStairwellCrusherDescendant:IsA("BasePart") and DisableStairwellCrusherDescendant.CanCollide then
									local DisableStairwellCrusherUnderBasicWall = false
									local DisableStairwellCrusherParent = DisableStairwellCrusherDescendant.Parent
									while DisableStairwellCrusherParent and DisableStairwellCrusherParent ~= DisableStairwellCrusherContainer do
										if DisableStairwellCrusherParent.Name == "BasicWall" then
											DisableStairwellCrusherUnderBasicWall = true
											break
										end
										DisableStairwellCrusherParent = DisableStairwellCrusherParent.Parent
									end
									if not DisableStairwellCrusherUnderBasicWall then
										DisableStairwellCrusherDescendant.CanCollide = false
									end
								end
							end
						end

						local DisableStairwellCrusher = DisableStairwellCrusherContainer:FindFirstChild("StairwellCrusher")
						if DisableStairwellCrusher then
							local DisableStairwellCrusherOuterTrigger = DisableStairwellCrusher:FindFirstChild("OuterTrigger")
							local DisableStairwellCrusherCoreTrigger = DisableStairwellCrusher:FindFirstChild("CoreTrigger")
							if DisableStairwellCrusherOuterTrigger then
								DisableStairwellCrusherOuterTrigger:Destroy()
							end
							if DisableStairwellCrusherCoreTrigger then
								DisableStairwellCrusherCoreTrigger:Destroy()
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)
Toggles.DeleteStairwellCrusherExceptBasicWall:OnChanged(function(DeleteStairwellCrusherExceptBasicWallState)
	if not DeleteStairwellCrusherExceptBasicWallState then return end

	task.spawn(function()
		while Toggles.DeleteStairwellCrusherExceptBasicWall.Value do
			for _, DeleteStairwellCrusherRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
				local DeleteStairwellCrusherAssets = DeleteStairwellCrusherRoom:FindFirstChild("Assets")
				if DeleteStairwellCrusherAssets then
					for _, DeleteStairwellCrusherContainer in ipairs(DeleteStairwellCrusherAssets:GetChildren()) do
						if DeleteStairwellCrusherContainer.Name == "StairwellCrusherContainer1" then
							local DeleteStairwellCrusherToDestroy = {}
							for _, DeleteStairwellCrusherDescendant in ipairs(DeleteStairwellCrusherContainer:GetDescendants()) do
								local DeleteStairwellCrusherUnderBasicWall = false
								local DeleteStairwellCrusherParent = DeleteStairwellCrusherDescendant.Parent
								while DeleteStairwellCrusherParent and DeleteStairwellCrusherParent ~= DeleteStairwellCrusherContainer do
									if DeleteStairwellCrusherParent.Name == "BasicWall" then
										DeleteStairwellCrusherUnderBasicWall = true
										break
									end
									DeleteStairwellCrusherParent = DeleteStairwellCrusherParent.Parent
								end
								if not DeleteStairwellCrusherUnderBasicWall and DeleteStairwellCrusherDescendant.Name ~= "BasicWall" then
									DeleteStairwellCrusherToDestroy[#DeleteStairwellCrusherToDestroy + 1] = DeleteStairwellCrusherDescendant
								end
							end
							for _, DeleteStairwellCrusherInstance in ipairs(DeleteStairwellCrusherToDestroy) do
								if DeleteStairwellCrusherInstance and DeleteStairwellCrusherInstance.Parent then
									DeleteStairwellCrusherInstance:Destroy()
								end
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)

Toggles.MeldRemover:OnChanged(function(State)
	if not State then return end
	task.spawn(function()
		while Toggles.MeldRemover.Value do
			for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
				for _, folderName in ipairs({"Assets", "Parts"}) do
					local folder = room:FindFirstChild(folderName)
					if folder then
						for _, child in ipairs(folder:GetChildren()) do
							if child.Name == "MeldWall"
								or child.Name == "Boleahghth29tdgfhy2thuy2htuu259uhh3u" -- no qeustions asked
							then
								child:Destroy()
							end
						end
					end
				end
				for _, name in ipairs({"MeldData", "MeldPads", "Meldview", "Meld"}) do
					local obj = room:FindFirstChild(name)
					if obj and obj:IsA("Folder") then
						obj:Destroy()
					end
				end
			end
			task.wait(0.5)
		end
	end)
end)




local StairwellLandingToken = 0

Toggles.StairwellLandingSpam:OnChanged(function(Value)
	StairwellLandingToken += 1

	if not Value then
		return
	end

	local CurrentToken = StairwellLandingToken

	task.spawn(function()
		local CurrentRooms = workspace.CurrentRooms
		local LocalPlayer = Services.Players.LocalPlayer

		while Toggles.StairwellLandingSpam.Value and CurrentToken == StairwellLandingToken do
			local StairwellModels = {}

			for _, Room in ipairs(CurrentRooms:GetChildren()) do
				local StairwellLandingLogic = Room:FindFirstChild("StairwellLandingLogic")

				if StairwellLandingLogic then
					for _, Model in ipairs(StairwellLandingLogic:GetChildren()) do
						if Model:IsA("Model") then
							local Prompts = {}

							for _, Object in ipairs(Model:GetDescendants()) do
								if Object:IsA("ProximityPrompt") then
									Prompts[#Prompts + 1] = Object
								end
							end

							if #Prompts > 0 then
								StairwellModels[#StairwellModels + 1] = {
									Model = Model,
									Prompts = Prompts,
								}
							end
						end
					end
				end
			end

			table.sort(StairwellModels, function(First, Second)
				local FirstRoom = First.Model.Parent and First.Model.Parent.Parent
				local SecondRoom = Second.Model.Parent and Second.Model.Parent.Parent

				return (tonumber(FirstRoom and FirstRoom.Name) or math.huge) <
					(tonumber(SecondRoom and SecondRoom.Name) or math.huge)
			end)

			for _, Data in ipairs(StairwellModels) do
				if not Toggles.StairwellLandingSpam.Value or CurrentToken ~= StairwellLandingToken then
					break
				end

				local Model = Data.Model

				while Model.Parent
					and Model:IsDescendantOf(workspace)
					and Toggles.StairwellLandingSpam.Value
					and CurrentToken == StairwellLandingToken do

					local Character = LocalPlayer.Character
					local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

					if HumanoidRootPart then
						HumanoidRootPart.CFrame = Model:GetPivot() + Vector3.new(0, 5, 0)

						for Index = 1, #Data.Prompts do
							local Prompt = Data.Prompts[Index]

							if Prompt.Parent and Prompt.Enabled and fireproximityprompt then
								fireproximityprompt(Prompt)
							end
						end

						if keypress and keyrelease then
							keypress(0x58)
							task.wait(0.03)
							keyrelease(0x58)
						elseif Abysall
							and Abysall.Environment
							and Abysall.Environment.keypress
							and Abysall.Environment.keyrelease then

							Abysall.Environment.keypress(0x58)
							task.wait(0.03)
							Abysall.Environment.keyrelease(0x58)
						end
					end

					Services.RunService.Heartbeat:Wait()
				end
			end

			Services.RunService.Heartbeat:Wait()
		end
	end)
end)


Groupboxes.Stairwell_Misc:AddDivider()

Groupboxes.Stairwell_Misc:AddButton("TP Shopping Carts To Player", function()
	local ShoppingCartTargetName = Options.ShoppingCartTarget.Value
	local ShoppingCartTargetPlayer = game.Players:FindFirstChild(ShoppingCartTargetName)
	if not ShoppingCartTargetPlayer or not ShoppingCartTargetPlayer.Character then return end
	local ShoppingCartTargetCFrame = ShoppingCartTargetPlayer.Character:GetPivot()
	for _, ShoppingCartModel in ipairs(workspace.Misc:GetChildren()) do
		if ShoppingCartModel.Name == "ShoppingCart" and ShoppingCartModel:IsA("Model") then
			ShoppingCartModel:PivotTo(ShoppingCartTargetCFrame)
		end
	end
end)

Groupboxes.Stairwell_Misc:AddDropdown("ShoppingCartTarget", {
	Text = "Shopping Cart Target",
	Values = (function()
		local ShoppingCartPlayerNames = {}
		for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
			ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
		end
		return ShoppingCartPlayerNames
	end)(),
	Default = game.Players.LocalPlayer.Name,
})

Groupboxes.Stairwell_Misc:AddButton("Refresh Players", function()
	local ShoppingCartPlayerNames = {}
	for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
		ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
	end
	Options.ShoppingCartTarget:SetValues(ShoppingCartPlayerNames)
end)

Groupboxes.Stairwell_Experimental = Tabs.Stairwell:AddRightGroupbox("Experimental")


local function TPDropsToNearestGrinder()
    local TPDropsToNearestGrinderDropsFolder =
        workspace:FindFirstChild("Drops")

    local TPDropsToNearestGrinderRootPart =
        Character and Character:FindFirstChild("HumanoidRootPart")

    if not TPDropsToNearestGrinderDropsFolder
        or not TPDropsToNearestGrinderRootPart
        or not CurrentRooms then
        return
    end

    local TPDropsToNearestGrinderPlayerPosition =
        TPDropsToNearestGrinderRootPart.Position

    local TPDropsToNearestGrinderNearestGrinder = nil
    local TPDropsToNearestGrinderNearestDistance = math.huge

    for _, TPDropsToNearestGrinderRoom in
        ipairs(CurrentRooms:GetChildren()) do

        local TPDropsToNearestGrinderScrapper =
            TPDropsToNearestGrinderRoom:FindFirstChild(
                "StairwellScrapper",
                true
            )

        if TPDropsToNearestGrinderScrapper then
            for _, TPDropsToNearestGrinderObject in
                ipairs(TPDropsToNearestGrinderScrapper:GetDescendants()) do

                if TPDropsToNearestGrinderObject.Name == "Grinder1"
                    and (
                        TPDropsToNearestGrinderObject:IsA("Model")
                        or TPDropsToNearestGrinderObject:IsA("BasePart")
                    ) then

                    local TPDropsToNearestGrinderPosition =
                        TPDropsToNearestGrinderObject:GetPivot().Position

                    local TPDropsToNearestGrinderDistance =
                        (
                            TPDropsToNearestGrinderPlayerPosition
                            - TPDropsToNearestGrinderPosition
                        ).Magnitude

                    if TPDropsToNearestGrinderDistance
                        < TPDropsToNearestGrinderNearestDistance then

                        TPDropsToNearestGrinderNearestDistance =
                            TPDropsToNearestGrinderDistance

                        TPDropsToNearestGrinderNearestGrinder =
                            TPDropsToNearestGrinderObject
                    end
                end
            end
        end
    end

    if not TPDropsToNearestGrinderNearestGrinder then
        return
    end

    local TPDropsToNearestGrinderCFrame =
        TPDropsToNearestGrinderNearestGrinder:GetPivot()

    for _, TPDropsToNearestGrinderDropItem in
        ipairs(TPDropsToNearestGrinderDropsFolder:GetChildren()) do

        if TPDropsToNearestGrinderDropItem:IsA("Model")
            or TPDropsToNearestGrinderDropItem:IsA("BasePart") then

            TPDropsToNearestGrinderDropItem:PivotTo(
                TPDropsToNearestGrinderCFrame
            )
        end
    end
end

Groupboxes.Stairwell_Experimental:AddButton({
    Text = "TP All Drops to Nearest Grinder",
    Func = TPDropsToNearestGrinder,
    DoubleClick = false,
    Tooltip = "Teleports every dropped item to the grinder closest to you",
})

local function BringDroppedItems()
	local workspaceDropsFolder = workspace:FindFirstChild("Drops")
	if LocalPlayer and LocalPlayer.Character then
		local playerHumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if playerHumanoidRootPart and workspaceDropsFolder then
			for _, itemToBring in ipairs(workspaceDropsFolder:GetChildren()) do
				if itemToBring:IsA("Model") then
					itemToBring:PivotTo(playerHumanoidRootPart.CFrame)
				elseif itemToBring:IsA("BasePart") then
					itemToBring.CFrame = playerHumanoidRootPart.CFrame
				end
			end
		end
	end
end

Groupboxes.Stairwell_Experimental:AddButton({
	Text = "Bring Dropped Items",
	Func = function() BringDroppedItems() end,
	DoubleClick = false,
	Tooltip = "Brings all dropped items."
})

Groupboxes.Stairwell_Experimental:AddToggle("EnableDroppedItemsInterval", {
	Text = "Enable Interval",
	Default = false,
	Tooltip = "Automatically brings dropped items at the selected interval."
})

Groupboxes.Stairwell_Experimental:AddSlider("DroppedItemsInterval", {
	Text = "Interval",
	Default = 1,
	Min = 0,
	Max = 60,
	Rounding = 1,
	Compact = false,
	Tooltip = "How often dropped items are brought."
})

Toggles.EnableDroppedItemsInterval:OnChanged(function(enabled)
	if enabled then
		if droppedItemsIntervalRunning then return end
		droppedItemsIntervalRunning = true
		task.spawn(function()
			while Toggles.EnableDroppedItemsInterval.Value do
				BringDroppedItems()
				local interval = Options.DroppedItemsInterval.Value
				if interval <= 0 then
					task.wait()
				else
					task.wait(interval)
				end
			end
			droppedItemsIntervalRunning = false
		end)
	end
end)

Groupboxes.Stairwell_Experimental:AddDivider()

Groupboxes.Stairwell_Experimental:AddToggle("OrbitDroppedItems", {
	Text = "Orbit Dropped Items",
	Default = false,
	Tooltip = "Orbits dropped items around you. Teleports them to you every 10s to prevent despawn."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsHeight", {
	Text = "Height",
	Default = 2,
	Min = -20,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = "The height of the orbit."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsDistance", {
	Text = "Distance",
	Default = 5,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Compact = false,
	Tooltip = "The distance of the orbit."
})

Groupboxes.Stairwell_Experimental:AddSlider("OrbitDroppedItemsSpeed", {
	Text = "Speed",
	Default = 2,
	Min = 0,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = "The speed of the orbit."
})

Toggles.OrbitDroppedItems:OnChanged(function(OrbitDroppedItemsEnabled)
	if OrbitDroppedItemsConnection then
		OrbitDroppedItemsConnection:Disconnect()
		OrbitDroppedItemsConnection = nil
	end
	if not OrbitDroppedItemsEnabled then return end
	OrbitDroppedItemsAngle = 0
	OrbitDroppedItemsLastTeleport = tick()
	OrbitDroppedItemsPauseUntil = 0
	OrbitDroppedItemsConnection = RunService.Heartbeat:Connect(function(OrbitDroppedItemsDeltaTime)
		if not LocalPlayer or not LocalPlayer.Character then return end
		local OrbitDroppedItemsHumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local OrbitDroppedItemsDropsFolder = workspace:FindFirstChild("Drops")
		if not OrbitDroppedItemsHumanoidRootPart or not OrbitDroppedItemsDropsFolder then return end
		local OrbitDroppedItemsHeightValue = Options.OrbitDroppedItemsHeight.Value
		local OrbitDroppedItemsDistanceValue = Options.OrbitDroppedItemsDistance.Value
		local OrbitDroppedItemsSpeedValue = Options.OrbitDroppedItemsSpeed.Value
		local OrbitDroppedItemsCurrentTime = tick()
		local OrbitDroppedItemsList = {}
		for _, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsDropsFolder:GetChildren()) do
			if OrbitDroppedItemsObject:IsA("Model") or OrbitDroppedItemsObject:IsA("BasePart") then
				OrbitDroppedItemsList[#OrbitDroppedItemsList + 1] = OrbitDroppedItemsObject
			end
		end
		local OrbitDroppedItemsCount = #OrbitDroppedItemsList
		if OrbitDroppedItemsCount == 0 then return end
		if OrbitDroppedItemsCurrentTime - OrbitDroppedItemsLastTeleport >= 10 then
			OrbitDroppedItemsLastTeleport = OrbitDroppedItemsCurrentTime
			OrbitDroppedItemsPauseUntil = OrbitDroppedItemsCurrentTime + 2
			local OrbitDroppedItemsCenterPosition = OrbitDroppedItemsHumanoidRootPart.Position
			for _, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsList) do
				if OrbitDroppedItemsObject:IsA("Model") then
					OrbitDroppedItemsObject:PivotTo(CFrame.new(OrbitDroppedItemsCenterPosition))
				else
					OrbitDroppedItemsObject.CFrame = CFrame.new(OrbitDroppedItemsCenterPosition)
				end
			end
		end
		if OrbitDroppedItemsCurrentTime < OrbitDroppedItemsPauseUntil then return end
		OrbitDroppedItemsAngle += OrbitDroppedItemsDeltaTime * OrbitDroppedItemsSpeedValue
		for OrbitDroppedItemsIndex, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsList) do
			local OrbitDroppedItemsObjectAngle = OrbitDroppedItemsAngle + ((OrbitDroppedItemsIndex - 1) / OrbitDroppedItemsCount) * math.pi * 2
			local OrbitDroppedItemsOffset = Vector3.new(
				math.cos(OrbitDroppedItemsObjectAngle) * OrbitDroppedItemsDistanceValue,
				OrbitDroppedItemsHeightValue,
				math.sin(OrbitDroppedItemsObjectAngle) * OrbitDroppedItemsDistanceValue
			)
			local OrbitDroppedItemsPosition = OrbitDroppedItemsHumanoidRootPart.Position + OrbitDroppedItemsOffset
			if OrbitDroppedItemsObject:IsA("Model") then
				OrbitDroppedItemsObject:PivotTo(CFrame.new(OrbitDroppedItemsPosition))
			else
				OrbitDroppedItemsObject.CFrame = CFrame.new(OrbitDroppedItemsPosition)
			end
		end
	end)
end)


Toggles.BypassNoise:OnChanged(function(value)
	for i = #Connections, 1, -1 do
		local existingConnection = Connections[i]
		if existingConnection and existingConnection.Disconnect then
			existingConnection:Disconnect()
		end
		table.remove(Connections, i)
	end

	if not value then return end

	local function checkBypassNoiseTvStand(targetTvStand)
		if not targetTvStand:IsA("Model") then return end
		if targetTvStand.Name ~= "TV_Stand" then return end

		local tvStandCurrentCFrame = targetTvStand:GetPivot()

		if tvStandCurrentCFrame.Position.Y > -119 then
			targetTvStand:PivotTo(CFrame.new(
				tvStandCurrentCFrame.Position.X,
				-120,
				tvStandCurrentCFrame.Position.Z
			))
		end
	end

	local bypassNoiseMiscFolder = workspace:FindFirstChild("Misc")
	if not bypassNoiseMiscFolder then return end

	local bypassNoiseMiscChildAddedConnection = bypassNoiseMiscFolder.ChildAdded:Connect(function(bypassNoiseNewChild)
		checkBypassNoiseTvStand(bypassNoiseNewChild)
	end)

	Connections[#Connections + 1] = bypassNoiseMiscChildAddedConnection

	for _, bypassNoiseMiscChild in ipairs(bypassNoiseMiscFolder:GetChildren()) do
		checkBypassNoiseTvStand(bypassNoiseMiscChild)
	end
end)

Toggles.DroppedItemValue:OnChanged(function(DroppedItemValue)
	local DroppedItemValueScreenGui = game:GetService("CoreGui"):FindFirstChild("DropsCoinCounter")
	if not DroppedItemValue then
		if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
		return
	end
	local DroppedItemValueWorkspaceDrops = workspace:WaitForChild("Drops")
	if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
	DroppedItemValueScreenGui = Instance.new("ScreenGui")
	DroppedItemValueScreenGui.Name = "DropsCoinCounter"
	DroppedItemValueScreenGui.ResetOnSpawn = false
	DroppedItemValueScreenGui.Parent = game:GetService("CoreGui")
	local DroppedItemValueCoinText = Instance.new("TextLabel")
	DroppedItemValueCoinText.Name = "CoinText"
	DroppedItemValueCoinText.AnchorPoint = Vector2.new(0.5, 0)
	DroppedItemValueCoinText.Position = UDim2.new(0.5, 0, 0.02, 0)
	DroppedItemValueCoinText.Size = UDim2.new(0, 250, 0, 40)
	DroppedItemValueCoinText.BackgroundTransparency = 1
	DroppedItemValueCoinText.Text = "Items: 0"
	DroppedItemValueCoinText.TextSize = 24
	DroppedItemValueCoinText.Font = Enum.Font.GothamBold
	DroppedItemValueCoinText.TextColor3 = Color3.fromRGB(255, 255, 255)
	DroppedItemValueCoinText.TextStrokeTransparency = 0.5
	DroppedItemValueCoinText.Parent = DroppedItemValueScreenGui
	local DroppedItemValueCountedDrops = {}
	task.spawn(function()
		while Toggles.DroppedItemValue.Value do
			for _, DroppedItemValueDrop in ipairs(DroppedItemValueWorkspaceDrops:GetChildren()) do
				if DroppedItemValueDrop:IsA("Model") and not DroppedItemValueCountedDrops[DroppedItemValueDrop] then
					DroppedItemValueDrop:SetAttribute("CoinsChecked", true)
					DroppedItemValueCountedDrops[DroppedItemValueDrop] = true
				end
			end
			for DroppedItemValueDrop in pairs(DroppedItemValueCountedDrops) do
				if not DroppedItemValueDrop.Parent or DroppedItemValueDrop.Parent ~= DroppedItemValueWorkspaceDrops then
					DroppedItemValueCountedDrops[DroppedItemValueDrop] = nil
				end
			end
			local DroppedItemValueTotalItems = 0
			for DroppedItemValueDrop in pairs(DroppedItemValueCountedDrops) do
				if DroppedItemValueDrop.Parent == DroppedItemValueWorkspaceDrops then
					DroppedItemValueTotalItems += 1
				end
			end
			DroppedItemValueCoinText.Text = "Items: " .. DroppedItemValueTotalItems
			task.wait(1)
		end
		if DroppedItemValueScreenGui and DroppedItemValueScreenGui.Parent then
			DroppedItemValueScreenGui:Destroy()
		end
	end)
end)

-- hi

Groupboxes.Exploits_BypassRight = Tabs.Exploits:AddRightGroupbox("Bypass")
Groupboxes.Exploits_BypassRight:AddToggle("DisableAnticheat", {
	Text = "Anticheat Bypass", Default = false,
	Tooltip = "Completely disables the anticheat, after interacting with a ladder."
})
Groupboxes.Exploits_BypassRight:AddToggle("VelocityManipulationToggle", {
	Text = "Velocity Manipulation", Default = false,
	Tooltip = "Moves your character forward slowly, mitigating the game's anti-noclip."
})
Toggles.DisableAnticheat:OnChanged(function(Value)
	if Globals.AnticheatDisabled == true and not Value then
		RemotesFolder.ClimbLadder:FireServer()
		Globals.AnticheatDisabled = false
	end
end)
Toggles.VelocityManipulationToggle:AddKeyPicker("VelocityManipulationKeybind", {
	Text = "Velocity Manipulation", Default = "V",
	Mode = Library.IsMobile and "Toggle" or "Hold", SyncToggleState = true
})
Groupboxes.Exploits_BypassRight:AddDropdown("VelocityManipulationMode", {
	Values = {"Velocity", "Pivot"}, Text = "Manipulation Method",
	Default = 1,
})

Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle("InfiniteItemsToggle", {
	Text = "Infinite Items", Default = false,
	Tooltip = "Allows certain items to be used without draining their uses.",
	Disabled = not Functions.CheckCompatability({"fireproximityprompt"}),
	DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Exploits_BypassRight:AddDropdown("InfiniteItemsList", {
	Text = "Item List",
	Values = { "Lockpicks", "Skeleton Key", "Shears", "Multitool" },
	Multi = true, AllowNull = true,
	Disabled = not Functions.CheckCompatability({"fireproximityprompt"}),
	DisabledTooltip = Globals.IncompatibleMessage
})

Groupboxes.Exploits_BypassRight:AddToggle("InfCrucifix", {
	Text = "Infinite Crucifix",
	Default = false,
	Tooltip = "Risky! You can die or lose the Crucifix. Recommended to have low ping and stable fps.",
	Risky = Floor ~= "Ballz",
})


local InfCrucifixDropTable = {
	RushMoving   = 54,
	AmbushMoving = 67,
	A60          = 70,
	GlitchRush   = 120,
	GlitchAmbush = 155,
	A120         = 75,

}



Toggles.InfCrucifix:OnChanged(function(Value)
	print("i allive")
	local InfCrucifixRaycastParams = RaycastParams.new()
	InfCrucifixRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local InfCrucifixConnection
	InfCrucifixConnection = RunService.RenderStepped:Connect(function()
		if not Toggles.InfCrucifix.Value then
			if InfCrucifixConnection then
				InfCrucifixConnection:Disconnect()
			end
			return
		end

		local InfCrucifixCharacter = game.Players.LocalPlayer
		if not InfCrucifixCharacter then
			return
		end

		local InfCrucifixCollision = InfCrucifixCharacter:FindFirstChild("CollisionPart")
		if not InfCrucifixCollision then
			return
		end

		InfCrucifixRaycastParams.FilterDescendantsInstances = {InfCrucifixCharacter}

		for _, InfCrucifixEntity in ipairs(Workspace:GetChildren()) do
			local InfCrucifixMaxDistance = InfCrucifixDropTable[InfCrucifixEntity.Name]
			if not InfCrucifixMaxDistance or not InfCrucifixEntity.PrimaryPart then
				continue
			end

			InfCrucifixEntity.PrimaryPart.CanCollide = true
			InfCrucifixEntity.PrimaryPart.CanQuery = true

			local InfCrucifixOrigin = InfCrucifixCollision.Position
			local InfCrucifixDirection = InfCrucifixEntity.PrimaryPart.Position - InfCrucifixOrigin
			local InfCrucifixRayResult = Workspace:Raycast(InfCrucifixOrigin, InfCrucifixDirection, InfCrucifixRaycastParams)

			if not InfCrucifixRayResult or not InfCrucifixRayResult.Instance:IsDescendantOf(InfCrucifixEntity) then
				continue
			end

			local InfCrucifixDistance = (InfCrucifixCollision.Position - InfCrucifixEntity.PrimaryPart.Position).Magnitude
			if InfCrucifixDistance >= InfCrucifixMaxDistance then
				continue
			end

			local InfCrucifixTool = InfCrucifixCharacter:FindFirstChildOfClass("Tool")
			if not InfCrucifixTool or InfCrucifixTool.Name ~= "Crucifix" then
				continue
			end

			task.spawn(function()
				ReplicatedStorage.RemotesFolder.DropItem:FireServer(InfCrucifixTool)
				task.wait(0.54)
				print("hi")
				local InfCrucifixDrops = Workspace:FindFirstChild("Drops")
				if not InfCrucifixDrops then
					return
				end

				local InfCrucifixDropped = InfCrucifixDrops:FindFirstChild("Crucifix")
				if not InfCrucifixDropped then
					return
				end

				local InfCrucifixPrompt = InfCrucifixDropped:FindFirstChildOfClass("ProximityPrompt")
				if InfCrucifixPrompt then
					fireproximityprompt(InfCrucifixPrompt)
				end
			end)
			print ("hi")
			task.wait(0.6)
		end
	end)
end)


Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle("PositionSpoof", {
	Text = "Position Spoof", Default = false,
	Tooltip = "Makes your character appear underground on the server, protecting you from rush-like entities."
})
Groupboxes.Exploits_BypassRight:AddToggle("CrouchSpoof", {
	Text = "Crouch Spoof", Default = false, Tooltip = "Makes the game think you are always crouching."
})
Toggles.PositionSpoof:OnChanged(function(Value)
	if Floor ~= "Fools" and Floor ~= "OldHotel" then
		if Value then
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
			Humanoid.HipHeight = 0.05
			RemotesFolder.Crouch:FireServer(true, true)
		else
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 2.346, 0)
			Humanoid.HipHeight = 2.396
		end
	end
end)
Toggles.PositionSpoof:AddKeyPicker("PositionSpoof", {
	Text = "Position Spoof", Default = "B", Mode = "Toggle", SyncToggleState = true
})
Toggles.CrouchSpoof:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Groupboxes.Exploits_Remove = Tabs.Exploits:AddRightGroupbox("Remove")
Groupboxes.Exploits_Remove:AddToggle("RemoveScreech", { Text = "Remove Screech",  Default = false, Tooltip = "Prevents 'Screech' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveHalt",    { Text = "Remove Halt",     Default = false, Tooltip = "Prevents 'Halt' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveA90",     { Text = "Remove A-90",     Default = false, Tooltip = "Prevents 'A-90' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveDread",   { Text = "Remove Dread",    Default = false, Tooltip = "Prevents 'Dread' from spawning." })
Groupboxes.Exploits_Remove:AddToggle("RemoveSurge", { Text = "Remove Surge", Default = false, Tooltip = "Prevents 'Surge' from spawning."})
Groupboxes.Exploits_Remove:AddDivider()
Groupboxes.Exploits_Remove:AddToggle("NoScreechDamage", { Text = "No Screech Damage", Default = false, Tooltip = "Prevents 'Screech' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoHaltDamage",    { Text = "No Halt Damage",    Default = false, Tooltip = "Prevents 'Halt' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoA90Damage",     { Text = "No A-90 Damage",    Default = false, Tooltip = "Prevents 'A-90' from hurting you." })
Groupboxes.Exploits_Remove:AddToggle("NoSurgeDamage",   { Text = "No Surge Damage",   Default = false, Tooltip = "Prevents 'Surge' from hurting you." })

Toggles.NoScreechDamage:OnChanged(function(Value)
	if Value then
		FakeEvents.Screech.Parent = RemotesFolder
		FakeEvents.Screech_Real.Parent = nil
	else
		FakeEvents.Screech_Real.Parent = RemotesFolder
		FakeEvents.Screech.Parent = nil
	end
end)
Toggles.NoHaltDamage:OnChanged(function(Value)
	if Value then
		FakeEvents.Shade.Parent = RemotesFolder
		FakeEvents.Shade_Real.Parent = nil
	else
		FakeEvents.Shade_Real.Parent = RemotesFolder
		FakeEvents.Shade.Parent = nil
	end
end)
Toggles.NoA90Damage:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("A90") then
		if Value then
			FakeEvents.A90.Parent = RemotesFolder
			FakeEvents.A90_Real.Parent = nil
		else
			FakeEvents.A90_Real.Parent = RemotesFolder
			FakeEvents.A90.Parent = nil
		end
	end
end)
Toggles.NoSurgeDamage:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("SurgeRemote") then
		if Value then
			FakeEvents.Surge.Parent = RemotesFolder
			FakeEvents.Surge_Real.Parent = nil
		else
			FakeEvents.Surge_Real.Parent = RemotesFolder
			FakeEvents.Surge.Parent = nil
		end
	end
end)

local Modules = {}

Toggles.RemoveScreech:OnChanged(function(Value)
	if Value then
		task.spawn(function()
			while Toggles.RemoveScreech.Value do
				local Camera = workspace:FindFirstChild("Camera")

				if Camera then
					local Screech = Camera:FindFirstChild("Screech")

					if Screech then
						Screech:Destroy()
					end
				end

				task.wait()
			end
		end)
	end
end)
Toggles.RemoveHalt:OnChanged(function(Value)
	Modules.Shade.Name = Value and "Shade_Disabled" or "Shade"
end)
Toggles.RemoveA90:OnChanged(function(Value)
	if Modules.A90 then
		Modules.A90.Name = Value and "A90_Disabled" or "A90"
	end
end)
Toggles.RemoveDread:OnChanged(function(Value)
	if Modules.Dread then
		Modules.Dread.Name = Value and "Dread_Disabled" or "Dread"
	end
end)
Toggles.RemoveSurge:OnChanged(function(Value)
	if Globals.SurgeFrame then
		Globals.SurgeFrame.Name = (Value and "SurgeVignette_Disabled" or "SurgeVignette")
	end
end)

Groupboxes.Exploits_Audio = Tabs.Exploits:AddLeftGroupbox("Audio")
Globals.JamMuffle = Services.SoundService:WaitForChild("Main"):FindFirstChild("Jamming") or Instance.new("EqualizerSoundEffect")

Groupboxes.Exploits_Audio:AddToggle("RemoveFootstepSounds",    { Text = "Remove Footstep Sounds",    Default = false, Tooltip = "Removes the sounds when walking." })
Groupboxes.Exploits_Audio:AddToggle("RemoveJamminMusic",       { Text = "Remove Jammin Music",       Default = false, Tooltip = "Removes the music and muffle effect from the 'Jammin' modifier." })
Groupboxes.Exploits_Audio:AddToggle("RemoveInteractingSounds", { Text = "Remove Interacting Sounds", Default = false, Tooltip = "Removes the sounds when interacting with proximity prompts." })

Toggles.RemoveJamminMusic:OnChanged(function(Value)
	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam then
		Jam.Volume = Value and 0 or 0.45
		Globals.JamMuffle.Enabled = LiveModifiers:FindFirstChild("Jammin") and not Value or false
	end
end)
Toggles.RemoveInteractingSounds:OnChanged(function(Value)
	local PS = Globals.MainUI.Initiator.Main_Game.PromptService
	PS.Triggered.Volume   = Value and 0 or 0.04
	PS.Holding.Volume     = Value and 0 or 0.1
	PS.Notification.Volume = Value and 0 or 0.03
	Globals.MainUI.Initiator.Main_Game.Reminder.Caption.Volume = Value and 0 or 0.1
end)

Groupboxes.Visuals_LeftTab = Tabs.Visuals:AddLeftTabbox("Camera / Effects")
Groupboxes.Visuals_Camera = Groupboxes.Visuals_LeftTab:AddTab("Camera")
Groupboxes.Visuals_Camera:AddToggle("AmbientToggle", { Text = "Ambient", Default = false, Tooltip = "Changes the lighting color to the specified value." })
Groupboxes.Visuals_Camera:AddSlider("FieldOfView", { Text = "Field of View", Min = 1, Max = 120, Default = 70, Rounding = 0 })
Groupboxes.Visuals_Camera:AddToggle("FOVToggle", {    Text = "Custom FOV",    Default = false,    Tooltip = "Only applies the Field of View slider when enabled." })
Toggles.FOVToggle:AddKeyPicker("FovToggle", {Text = "Custom Fov", Default = "O", Mode = "Toggle", SyncToggleState = true})
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraShake", {
	Text = "Remove Camera Shake", Default = false, Tooltip = "Prevents the camera from shaking.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraBobbing", {
	Text = "Remove Camera Bobbing", Default = false, Tooltip = "Prevents the camera from bobbing when moving.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle("RemoveCutscenes", { Text = "Remove Cutscenes", Default = false, Tooltip = "Removes all non-necessary cutscenes." })
Groupboxes.Visuals_Camera:AddToggle("RemoveCameraFog", { Text = "Remove Fog", Default = false, Tooltip = "Removes all fog effects from the camera." })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("ThirdPersonToggle", { Text = "Third Person", Default = false, Tooltip = "Zooms out your camera, allowing you to see your character from behind." })
Toggles.ThirdPersonToggle:AddKeyPicker("ThirdPersonKeybind", { Text = "Third Person", Default = "T", Mode = "Toggle", SyncToggleState = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 1.5, Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 1,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider("ThirdPersonOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 5,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddToggle("ThirdPersonWallCheck", { Text = "Wall Check", Default = false, Tooltip = "Prevents third person from going through walls." })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle("ViewmodelOffsetToggle", {
	Text = "Viewmodel Offset", Default = false, Tooltip = "Changes the offset of your viewmodel while holding an item.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider("ViewmodelOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage })

Toggles.AmbientToggle:AddColorPicker("AmbientColor", { Text = "Ambient", Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.AmbientToggle:OnChanged(function(Value)
	local OldAmbient = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom"))):GetAttribute("Ambient")
	Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
		Ambient = Value and Options.AmbientColor.Value or OldAmbient
	}):Play()
end)

local Main_Game
local ClientModules

Toggles.RemoveCameraBobbing:OnChanged(function(Value)
	if Main_Game then Main_Game.spring.Speed = Value and 9e9 or 8 end
end)
Toggles.RemoveCameraFog:OnChanged(function(Value)
	Services.Lighting.FogEnd = Value and 10000000 or Globals.OldFog
	for _, Object in Globals.FogInstances do
		Object.Density = Value and 0 or Object:GetAttribute("Density_Old")
	end
end)
Toggles.RemoveCutscenes:OnChanged(function(Value)
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") or table.find(CutsceneNames, Object:GetAttribute("OriginalName")) and Object:IsA("ModuleScript") then
            Object.Name = (Value and Object.Name .. "_Disabled" or Object:GetAttribute("OriginalName"))
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") or table.find(CutsceneNames, Object:GetAttribute("OriginalName")) and Object:IsA("ModuleScript") then
            Object.Name = (Value and Object.Name .. "_Disabled" or Object:GetAttribute("OriginalName"))
        end
    end
end)

Groupboxes.Visuals_Effects = Groupboxes.Visuals_LeftTab:AddTab("Effects")
Groupboxes.Visuals_Effects:AddToggle("TransparentHidingSpotsToggle", { Text = "Transparent Hiding Spots", Default = false, Tooltip = "Makes a hiding spot transparent when you enter it." })
Groupboxes.Visuals_Effects:AddSlider("TransparentHidingSpotsSlider", { Text = "Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true })

local function ApplyHidingTransparency(Value, SliderValue)
	for _, Object in Objects.HidingSpots do
		local IsHiding = false
		for _, Child in Object:GetDescendants() do
			if Child.Name == "HiddenPlayer" and Child.Value == Character then
				IsHiding = true
				break
			end
		end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") and Part:GetAttribute("Transparency_Old") then
				Services.TweenService:Create(Part, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
					Transparency = (Value and IsHiding) and SliderValue or Part:GetAttribute("Transparency_Old")
				}):Play()
			end
		end
	end
end

Toggles.TransparentHidingSpotsToggle:OnChanged(function(Value)
	ApplyHidingTransparency(Value, Options.TransparentHidingSpotsSlider.Value)
end)
Options.TransparentHidingSpotsSlider:OnChanged(function(Value)
	ApplyHidingTransparency(Toggles.TransparentHidingSpotsToggle.Value, Value)
end)

Groupboxes.Visuals_Effects:AddDivider()
Groupboxes.Visuals_Effects:AddToggle("DisableGlitchJumpscare",   { Text = "Disable Glitch Jumpscare",   Default = false, Tooltip = "Disables the jumpscare from 'Glitch'" })
Groupboxes.Visuals_Effects:AddToggle("DisableTimothyJumpscare",  { Text = "Disable Timothy Jumpscare",  Default = false, Tooltip = "Disables the jumpscare from 'Timothy'" })
Groupboxes.Visuals_Effects:AddToggle("DisableVoidJumpscare",     { Text = "Disable Void Jumpscare",     Default = false, Tooltip = "Disables the jumpscare from 'Void'" })
Groupboxes.Visuals_Effects:AddDivider()
Groupboxes.Visuals_Effects:AddToggle("DisableHideVignette",      { Text = "Disable Hide Vignette",      Default = false, Tooltip = "Disables the hiding screen effect." })
Groupboxes.Visuals_Effects:AddToggle("DisableFiredampEffect",    { Text = "Disable Firedamp Effect",    Default = false, Tooltip = "Disables the firedamp screen effect." })
Groupboxes.Visuals_Effects:AddToggle("DisableEntityJumpscares",  { Text = "Disable Entity Jumpscares",  Default = false, Tooltip = "Disables jumpscares from entities like Rush and Ambush." })

Toggles.DisableGlitchJumpscare:OnChanged(function(Value)
	Modules.Glitch.Name = Value and "Glitch_Disabled" or "Glitch"
end)
Toggles.DisableTimothyJumpscare:OnChanged(function(Value)
	Modules.SpiderJumpscare.Name = Value and "SpiderJumpscare_Disabled" or "SpiderJumpscare"
end)
Toggles.DisableVoidJumpscare:OnChanged(function(Value)
	if Modules.Void then Modules.Void.Name = Value and "Void_Disabled" or "Void" end
end)
Toggles.DisableHideVignette:OnChanged(function(Value)
	local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = Value and "Disabled" or "rbxassetid://6100076320" end
end)
Toggles.DisableFiredampEffect:OnChanged(function(Value)
	for _, Object in CurrentRooms:GetChildren() do
		if Value then
			Object:SetAttribute("Firedamp", false)
			for _, FiredampObj in Camera:GetChildren() do
				if FiredampObj.Name == "LiveFiredamp" then FiredampObj:Destroy() end
			end
		else
			Object:SetAttribute("Firedamp", Object:GetAttribute("Firedamp_Old"))
		end
	end
	local Old = LocalPlayer:GetAttribute("CurrentRoom")
	LocalPlayer:SetAttribute("CurrentRoom", 0)
	task.wait()
	LocalPlayer:SetAttribute("CurrentRoom", Old)
end)
Toggles.DisableEntityJumpscares:OnChanged(function(Value)
	local Jumpscares = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		or Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares_Disabled")
	if Jumpscares then
		Jumpscares.Name = Value and "Jumpscares_Disabled" or "Jumpscares"
		for _, Object in Objects.JumpscareModules do
			Object.Name = Value and (Object:GetAttribute("OriginalName") .. "_Disabled") or Object:GetAttribute("OriginalName")
		end
	end
end)

Groupboxes.Visuals_RightTab     = Tabs.Visuals:AddRightTabbox("Entities / Settings / Entity Nodes")
Groupboxes.Visuals_Entities     = Groupboxes.Visuals_RightTab:AddTab("Entities")
Groupboxes.Visuals_EntitySettings = Groupboxes.Visuals_RightTab:AddTab("Settings")

Groupboxes.Visuals_Entities:AddDropdown("EntityList", {
	Text = "Entity List",
	Values = { "Rush","Bash","Scribbles","Teller","DronesStampede","Creak","Noise","Noise_TV","Balls","Portrait","Ambush","Eyes","Halt","Blitz","Lookman","Gloombat Swarm","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Monument","AR0xMBUSH","RNIUSHCG==" },
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle("NotifyEntities",    { Text = "Notify Entities",    Default = false, Tooltip = "Sends a notification when an entity spawns." })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle("ShowEntityPath", {
    Text = "Show Entity Path",
    Default = false,
    Tooltip = "Shows the path of entitys."
})


-- i dont wanna hear it okay? i was sick okay let me be okay fuck u okay




Groupboxes.Visuals_Entities:AddToggle("ShowEntityPath", {
    Text = "Show Entity Path",
    Default = false,
    Tooltip = "Shows the path of entitys."
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathNodeTransparency", {
    Text = "Node Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = "Transparency of the path nodes when shown"
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathLineTransparency", {
    Text = "Line Transparency",
    Default = 0.15,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = "Transparency of the path lines"
})

Groupboxes.Visuals_Entities:AddSlider("ShowEntityPathLineThickness", {
    Text = "Line Thickness",
    Default = 0.3,
    Min = 0.08,
    Max = 1.2,
    Rounding = 2
})

local ShowEntityPathLines = {}

local function ShowEntityPathClearAllLines()
    for _, ShowEntityPathRoomLines in pairs(ShowEntityPathLines) do
        for _, ShowEntityPathLine in ipairs(ShowEntityPathRoomLines) do
            if ShowEntityPathLine and ShowEntityPathLine.Parent then
                ShowEntityPathLine:Destroy()
            end
        end
    end
    table.clear(ShowEntityPathLines)
end

local function ShowEntityPathCreateLine(ShowEntityPathPoint1, ShowEntityPathPoint2, ShowEntityPathTransparency, ShowEntityPathThickness, ShowEntityPathParent)
    local ShowEntityPathDistance = (ShowEntityPathPoint1 - ShowEntityPathPoint2).Magnitude
    if ShowEntityPathDistance < 0.05 then
        return nil
    end

    local ShowEntityPathLinePart = Instance.new("Part")
    ShowEntityPathLinePart.Name = "PathLine"
    ShowEntityPathLinePart.Anchored = true
    ShowEntityPathLinePart.CanCollide = false
    ShowEntityPathLinePart.CanQuery = false
    ShowEntityPathLinePart.CanTouch = false
    ShowEntityPathLinePart.CastShadow = false
    ShowEntityPathLinePart.Material = Enum.Material.ForceField
    ShowEntityPathLinePart.Color = Color3.fromRGB(0, 255, 210)
    ShowEntityPathLinePart.Transparency = ShowEntityPathTransparency
    ShowEntityPathLinePart.Size = Vector3.new(ShowEntityPathThickness, ShowEntityPathThickness, ShowEntityPathDistance)
    ShowEntityPathLinePart.CFrame = CFrame.lookAt(ShowEntityPathPoint1, ShowEntityPathPoint2) * CFrame.new(0, 0, -ShowEntityPathDistance / 2)
    ShowEntityPathLinePart.Parent = ShowEntityPathParent
    return ShowEntityPathLinePart
end

local function ShowEntityPathGetSortedNodes(ShowEntityPathNodes)
    local ShowEntityPathSortedNodes = {}
    for _, ShowEntityPathNode in ipairs(ShowEntityPathNodes:GetChildren()) do
        if ShowEntityPathNode:IsA("BasePart") then
            local ShowEntityPathNodeNumber = tonumber(ShowEntityPathNode.Name)
            if ShowEntityPathNodeNumber then
                table.insert(ShowEntityPathSortedNodes, {
                    Part = ShowEntityPathNode,
                    Number = ShowEntityPathNodeNumber
                })
            end
        end
    end
    table.sort(ShowEntityPathSortedNodes, function(a, b)
        return a.Number < b.Number
    end)
    return ShowEntityPathSortedNodes
end

local function ShowEntityPathSetNodeTransparency(ShowEntityPathTransparency)
    for _, ShowEntityPathRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
        local ShowEntityPathNodes = ShowEntityPathRoom:FindFirstChild("PathfindNodes")
        if ShowEntityPathNodes then
            for _, ShowEntityPathNode in ipairs(ShowEntityPathNodes:GetChildren()) do
                if ShowEntityPathNode:IsA("BasePart") then
                    ShowEntityPathNode.Transparency = ShowEntityPathTransparency
                end
            end
        end
    end
end

local function ShowEntityPathSetLineTransparency(ShowEntityPathTransparency)
    for _, ShowEntityPathRoomLines in pairs(ShowEntityPathLines) do
        for _, ShowEntityPathLine in ipairs(ShowEntityPathRoomLines) do
            if ShowEntityPathLine and ShowEntityPathLine.Parent then
                ShowEntityPathLine.Transparency = ShowEntityPathTransparency
            end
        end
    end
end

local function ShowEntityPathUpdateAll()
    local ShowEntityPathShow = Toggles.ShowEntityPath.Value
    local ShowEntityPathNodeTransparency = ShowEntityPathShow and Options.ShowEntityPathNodeTransparency.Value or 1
    local ShowEntityPathLineTransparency = Options.ShowEntityPathLineTransparency.Value
    local ShowEntityPathLineThickness = Options.ShowEntityPathLineThickness.Value

    ShowEntityPathClearAllLines()

    if not ShowEntityPathShow then
        ShowEntityPathSetNodeTransparency(1)
        return
    end

    ShowEntityPathSetNodeTransparency(ShowEntityPathNodeTransparency)

    local ShowEntityPathValidRooms = {}
    for _, ShowEntityPathRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
        if ShowEntityPathRoom:FindFirstChild("PathfindNodes") then
            table.insert(ShowEntityPathValidRooms, ShowEntityPathRoom)
        end
    end

    table.sort(ShowEntityPathValidRooms, function(a, b)
        return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
    end)

    for _, ShowEntityPathRoom in ipairs(ShowEntityPathValidRooms) do
        local ShowEntityPathNodes = ShowEntityPathRoom.PathfindNodes
        local ShowEntityPathSortedNodes = ShowEntityPathGetSortedNodes(ShowEntityPathNodes)

        if #ShowEntityPathSortedNodes > 0 then
            local ShowEntityPathRoomLines = {}

            for i = 1, #ShowEntityPathSortedNodes - 1 do
                local ShowEntityPathFrom = ShowEntityPathSortedNodes[i].Part
                local ShowEntityPathTo = ShowEntityPathSortedNodes[i + 1].Part

                local ShowEntityPathLine = ShowEntityPathCreateLine(
                    ShowEntityPathFrom.Position,
                    ShowEntityPathTo.Position,
                    ShowEntityPathLineTransparency,
                    ShowEntityPathLineThickness,
                    ShowEntityPathRoom
                )
                if ShowEntityPathLine then
                    table.insert(ShowEntityPathRoomLines, ShowEntityPathLine)
                end
            end

            if #ShowEntityPathRoomLines > 0 then
                ShowEntityPathLines[ShowEntityPathRoom] = ShowEntityPathRoomLines
            end
        end
    end
end

Toggles.ShowEntityPath:OnChanged(function()
    if ShowEntityPathChildAddedConnection then
        ShowEntityPathChildAddedConnection:Disconnect()
        ShowEntityPathChildAddedConnection = nil
    end

    ShowEntityPathUpdateAll()

    if Toggles.ShowEntityPath.Value then
        ShowEntityPathChildAddedConnection = workspace.CurrentRooms.ChildAdded:Connect(function(ShowEntityPathRoom)
            if ShowEntityPathRoom:WaitForChild("PathfindNodes", 5) then
                task.wait(0.1)
                ShowEntityPathUpdateAll()
            end
        end)
    end
end)

Options.ShowEntityPathNodeTransparency:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathSetNodeTransparency(Options.ShowEntityPathNodeTransparency.Value)
    end
end)

Options.ShowEntityPathLineTransparency:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathSetLineTransparency(Options.ShowEntityPathLineTransparency.Value)
    end
end)

Options.ShowEntityPathLineThickness:OnChanged(function()
    if Toggles.ShowEntityPath.Value then
        ShowEntityPathUpdateAll()
    end
end)


Groupboxes.Visuals_Entities:AddDivider()

local ItemsToNotify = {}
for Index, Name in pairs(ItemNames) do
	if not table.find(ItemsToNotify, Name) then
		table.insert(ItemsToNotify, Name)
	end
end
table.sort(ItemsToNotify)

Groupboxes.Visuals_Entities:AddDropdown("NotifyItemList", {
	Text = "Item List",
	Values = ItemsToNotify,
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle("NotifyItemsToggle",    { Text = "Notify Items",    Default = false, Tooltip = "Sends a notification when an item spawns." })
Groupboxes.Visuals_Entities:AddToggle("NotifyItemsShowDistance",    { Text = "Show Distance",    Default = false, Tooltip = "Shows how far away the item is in the notification." })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle("NotifyLibraryCode", { Text = "Notify Library Code", Default = false, Tooltip = "Automatically solves the code for the library padlock." })
Groupboxes.Visuals_Entities:AddToggle("NotifyOxygen",      { Text = "Notify Oxygen Level", Default = false, Tooltip = "Shows how much oxygen you have remaining." })
Groupboxes.Visuals_Entities:AddToggle("NotifyHasteTime",   { Text = "Notify Haste Time",   Default = false, Tooltip = "Shows how much time you have remaining before 'Haste' spawns." })

Globals.LibraryCodeFound = false
Toggles.NotifyLibraryCode:OnChanged(function(Value)
	if Value then
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find("_") and not Globals.LibraryCodeFound and CurrentRooms:FindFirstChild("50") then
			local Lock = Services.Workspace:FindFirstChild("Padlock", true)
			Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
			Globals.LibraryCodeFound = true
		end
	end
end)

Groupboxes.Visuals_EntitySettings:AddToggle("EntityChatToggle", { Text = "Notify Chat", Default = false, Tooltip = "Sends a message in the chat when an entity spawns." })
Groupboxes.Visuals_EntitySettings:AddInput("EntityChatMessage", { Text = "Message", Default = "spawned!", Numeric = false, Placeholder = "Message" })
Groupboxes.Visuals_EntitySettings:AddDivider()
Groupboxes.Visuals_EntitySettings:AddDropdown("NotifyStyle", { Text = "Notify Style", Values = { "Abysall", "Doors", "STX", "Library" }, Default = 1 })
Groupboxes.Visuals_EntitySettings:AddSlider("NotifySoundVolume", { Text = "Sound Volume", Min = 0, Max = 10, Default = 3, Rounding = 1 })
Groupboxes.Visuals_EntitySettings:AddToggle("NotifyPlaySound", { Text = "Play Sound", Default = true, Tooltip = "Makes notifications play an alert sound." })
Groupboxes.Visuals_EntitySettings:AddToggle("NotifyKeepNotifications", { Text = "Keep Notifications", Default = false, Tooltip = "Certain notifications will stay on screen until they are no longer needed." })
Groupboxes.Visuals_EntitySettings:AddButton({ Text = "Test Notification", DoubleClick = false, Tooltip = "Sends a test notifcation, so you can see how your settings look.", Func = function()
	Functions.Notify({Title = "This is a test."})
end})

Groupboxes.Visuals_ESP          = Tabs.Visuals:AddRightTabbox("ESP/Settings")
Groupboxes.Visuals_ESP_Toggles  = Groupboxes.Visuals_ESP:AddTab("ESP")
Groupboxes.Visuals_ESP_Settings = Groupboxes.Visuals_ESP:AddTab("Settings")

local function MakeESPToggle(ToggleKey, ColorKey, Text, Tooltip, ObjectsTable, LabelFunc, RoomBased)
	Groupboxes.Visuals_ESP_Toggles:AddToggle(ToggleKey, { Text = Text, Default = false, Tooltip = Tooltip })
	Toggles[ToggleKey]:AddColorPicker(ColorKey, { Text = Text, Default = Options[ColorKey] and Options[ColorKey].Value or Color3.new(1,1,1), Transparency = 0 })
	Toggles[ToggleKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			if Value then
				local Label, UseRoom = LabelFunc(Object)
				if Label then
					Functions.AddESP({ Object = Object, Text = Label, Color = Options[ColorKey].Value }, UseRoom ~= nil and UseRoom or RoomBased)
				end
			else
				Functions.RemoveESP(Object)
			end
		end
	end)
	Options[ColorKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			Abysall.ESPLibrary:UpdateObjectColor(Object, Value)
		end
	end)
end

Groupboxes.Visuals_ESP_Toggles:AddToggle("ObjectiveESPToggle", { Text = "Objectives", Default = false, Tooltip = "Highlights all objects required to progress." })
Toggles.ObjectiveESPToggle:AddColorPicker("ObjectiveESPColor", { Text = "Objectives", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local ObjectiveLabels = {
	["StairwellLockpickDoor"]  = "Garage Door",
	["Mirror"]				   = "Mirror",
	["ShoppingCart"]		   = "Shopping Cart",
	["StairwellFireAlarm"]     = "Fire Alarm",
	["StairwellScrapper"]	   = "Scrapper",
	["ArchivesPackageDeposit"] = "BoxDeposit",
	["Cellar"] 				   = "Cellar",
	["ArchivesFihTank"]        = "Fih Tank",
	["KeyObtain"]              = "Door Key",
	["ElectricalKeyObtain"]    = "Electrical Key",
	["MinesGenerator"]         = "Generator",
	["FuseObtain"]             = "Generator Fuse",
	["LiveHintBook"]           = "Hint Book",
	["LiveBreakerPolePickup"]  = "Fuse Breaker",
	["LibraryHintPaper"]       = "Hint Paper",
	["PickupItem"]             = "Hint Paper",
	["CringlePresent"]         = "Present",
	["LeverForGate"]           = "Gate Lever",
	["MinesGateButton"]        = "Gate Button",
	["GardenGateButton"]       = "Gate Button",
}

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		if Value then
			local Label = ObjectiveLabels[Object.Name]
			if Object.Name == "TimerLever" then
				Label = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]"
			elseif Object.Name == "MinesAnchor" then
				Label = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]"
			elseif Object.Name == "WaterPump" then
				Functions.AddESP({ Object = Object.Wheel, Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true)
			elseif Object.Name == "VineGuillotine" then
				Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever", Color = Options.ObjectiveESPColor.Value }, true)
			end
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ObjectiveESPColor.Value }, true)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.ObjectiveESPColor:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		Abysall.ESPLibrary:UpdateObjectColor(Object, Value)
	end
end)

Groupboxes.Visuals_ESP_Toggles:AddToggle("DoorESPToggle",       { Text = "Doors",        Default = false, Tooltip = "Highlights the next door." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("HidingSpotESPToggle", { Text = "Hiding Spots", Default = false, Tooltip = "Highlights places where you can hide from entities" })
Groupboxes.Visuals_ESP_Toggles:AddToggle("PlayerESPToggle",     { Text = "Players",      Default = false, Tooltip = "Highlights other players." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("ChestESPToggle",      { Text = "Chests",       Default = false, Tooltip = "Highlights objects that can contain loot." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("ItemESPToggle",       { Text = "Items",        Default = false, Tooltip = "Highlights all collectable items/consumables." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("CurrencyESPToggle",   { Text = "Currency",     Default = false, Tooltip = "Highlights all currency that spawns." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("LadderESPToggle",     { Text = "Ladders",      Default = false, Tooltip = "Highlights ladders that can be used to disable the anticheat." })
Groupboxes.Visuals_ESP_Toggles:AddToggle("MiscESPToggle",       { Text = "Misc",         Default = false, Tooltip = "Highlights miscellaneous objects that can be used to disable the anticheat." })
Groupboxes.Visuals_ESP_Toggles:AddDivider()
Groupboxes.Visuals_ESP_Toggles:AddDropdown("EntityESPOptions",     { 
	Text = "Entity List",
	Values = { "Rush","Bash","Scribbles","Teller","DronesStampede","Creak","Noise","Noise_TV","Balls","Portrait","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Gloombat Eggs","Grumble","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","AR0xMBUSH","RNIUSHCG==" },
	Multi = true,
	AllowNull = true
})
Groupboxes.Visuals_ESP_Toggles:AddToggle("EntityESPToggle",     { Text = "Entities",      Default = false, Tooltip = "Highlights all entities that spawn." })

Toggles.DoorESPToggle:AddColorPicker("DoorESPColor",           { Text = "Doors",        Default = Color3.fromRGB(0, 200, 255),  Transparency = 0 })
Toggles.HidingSpotESPToggle:AddColorPicker("HidingSpotESPColor", { Text = "Hiding Spots", Default = Color3.fromRGB(255, 170, 0),  Transparency = 0 })
Toggles.PlayerESPToggle:AddColorPicker("PlayerESPColor",       { Text = "Players",      Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.ChestESPToggle:AddColorPicker("ChestESPColor",         { Text = "Chests",       Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.ItemESPToggle:AddColorPicker("ItemESPColor",           { Text = "Items",        Default = Color3.fromRGB(170, 0, 255),   Transparency = 0 })
Toggles.CurrencyESPToggle:AddColorPicker("CurrencyESPColor",   { Text = "Currency",     Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.LadderESPToggle:AddColorPicker("LadderESPColor",       { Text = "Ladders",      Default = Color3.fromRGB(3, 67, 71), Transparency = 0 })
Toggles.MiscESPToggle:AddColorPicker("MiscESPColor",           { Text = "Misc",         Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.EntityESPToggle:AddColorPicker("EntityESPColor",       { Text = "Entities",     Default = Color3.fromRGB(255, 0, 0),     Transparency = 0 })

local HidingSpotLabels = {
	Wardrobe = "Closet", ["Backdoor_Wardrobe"] = "Closet", Toolshed = "Closet",
	RetroWardrobe = "Closet", ["Wardrobe-FOOLS26"] = "Closet",
	Locker_Large = "Locker", Rooms_Locker = "Hiding_Spot", Rooms_Locker_Fridge = "Locker",
	Bed = "Bed", Double_Bed = "Double Bed", CircularVent = "Vent", Dumpster = "Dumpster"
}
local ChestLabels = {
	ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
	Chest_Vine = "Vine Chest", Toolshed_Small = "Toolshed", Locker_Small_Locked = "Locked Item Locker", MouseHole = "Mouse"
}
local EntityESPLabels = {
	JeffTheKiller = "Jeff the Killer", GiggleCeiling = "Giggle",
	Snare = "Snare", GrumbleRig = "Grumble",
	Drakobloxxer = "Drakobloxxer", Hole = "Mandrake Hole", Groundskeeper = "Groundskeeper",
	LiveEntityBramble = "Bramble", Figure = "Figure", FigureRig = "Figure", FigureRagdoll = "Figure",
	FakeDoor = "Dupe", DoorFake = "Dupe"
}

local NodeEntities = {
	Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true, Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true, Sally = true, ["Jeff The Killer"] = true, Monument = true, ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true
}

Toggles.DoorESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Doors do
		if Value then Functions.AddESP({ Object = Object, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)
Options.DoorESPColor:OnChanged(function(Value)
	for _, Object in Objects.Doors do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.HidingSpotESPToggle:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do
		local Label = HidingSpotLabels[Object.Name]
		if Value and Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true)
		elseif not Value then Functions.RemoveESP(Object) end
	end
end)
Options.HidingSpotESPColor:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.PlayerESPToggle:OnChanged(function(Value)
	task.wait()
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			if Value and Player:GetAttribute("Alive") == true then
				Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			else
				Functions.RemoveESP(Player.Character)
			end
		end
	end
end)
Options.PlayerESPColor:OnChanged(function(Value)
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			Abysall.ESPLibrary:UpdateObjectColor(Player.Character, Value)
		end
	end
end)

Toggles.ChestESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Chests do
		if Value then
			local Label
			if Object.Name == "ChestBox" or Object.Name == "ChestBoxLocked" then
				Label = Object:GetAttribute("Locked") and "Locked Chest" or "Chest"
			elseif Object.Name == "Toolbox" or Object.Name == "Toolbox_Locked" then
				Label = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox"
			elseif ChestLabels[Object.Name] and ChestLabels[Object.Name] ~= true then
				Label = ChestLabels[Object.Name]
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.ChestESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.ChestESPColor:OnChanged(function(Value)
	for _, Object in Objects.Chests do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ItemESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Items do
		if Value then
			local Label = ItemNames[Object.Name] or (Object.Name == "Green_Herb" and "Green Herb")
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.ItemESPColor:OnChanged(function(Value)
	for _, Object in Objects.Items do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.CurrencyESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Currency do
		if Value then
			local Label
			if Object.Name == "GoldPile" and Object:GetAttribute("GoldValue") then
				Label = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]"
			elseif Object.Name == "StardustPickup" then
				Label = "Stardust Pile"
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.CurrencyESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.CurrencyESPColor:OnChanged(function(Value)
	for _, Object in Objects.Currency do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.EntityESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
			if Label and Options.EntityESPOptions.Value[Label] then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPOptions:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Toggles.EntityESPToggle.Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
			if Label and Options.EntityESPOptions.Value[Label] then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPColor:OnChanged(function(Value)
	for _, Object in Objects.Entities do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.LadderESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Ladders do
		if Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)
Options.LadderESPColor:OnChanged(function(Value)
	for _, Object in Objects.Ladders do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.MiscESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Misc do
		if Value then
			local Label = Object.Name
			if Object.Name == "StairwellLockpickDoor" or Object.Name == "StiarwellLockpickDoor" then
				Label = "Garage Door"
			elseif Object.Name == "StairwellFireAlarm" then
				Label = "Fire Alarm"
			elseif Object.Name == "ShoppingCart" then
				Label = "Shopping Cart"
			elseif Object.Name == "ArchivesFihTank" or Object.Name == "ArchivesFishTank" then
				Label = "Fish Tank"
			end
			Functions.AddESP({ Object = Object, Text = Label, Color = Options.MiscESPColor.Value }, true)
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.MiscESPColor:OnChanged(function(Value)
	for _, Object in Objects.Misc do Abysall.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Groupboxes.Visuals_ESP_Settings:AddToggle("ESPRainbow",     { Text = "Rainbow Effect", Default = false, Tooltip = "Makes the esp objects change colour like a rainbow." })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPShowDistance",{ Text = "Show Distance",  Default = true,  Tooltip = "Shows how far away your character is from the object." })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPFillTransparency",        { Text = "Fill Transparency",         Min = 0, Max = 1, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPOutlineTransparency",     { Text = "Outline Transparency",      Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextTransparency",        { Text = "Text Transparency",         Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextOutlineTransparency", { Text = "Text Outline Transparency", Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPFadeTime",                { Text = "Fade Time",                 Min = 0, Max = 1, Default = 0.25, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPRenderLimit",             { Text = "Render Limit",              Min = 30, Max = 240, Default = 240, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTextSize",                { Text = "Text Size",                 Min = 12, Max = 24, Default = 20, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddDropdown("ESPTextFont", {
	Text = "Text Font",
	Values = { "Legacy","Arial","ArialBold","SourceSans","SourceSansBold","SourceSansLight","SourceSansItalic","Bodoni","Garamond","Cartoon","Code","Highway","SciFi","Arcade","Fantasy","Antique","SourceSansSemibold","Gotham","GothamMedium","GothamBold","GothamBlack","AmaticSC","Bangers","Creepster","DenkOne","Fondamento","FredokaOne","GrenzeGotisch","IndieFlower","JosefinSans","Jura","Kalam","LuckiestGuy","Merriweather","Michroma","Nunito","Oswald","PatrickHand","PermanentMarker","Roboto","RobotoCondensed","RobotoMono","Sarpanch","SpecialElite","TitilliumWeb","Ubuntu","BuilderSans","BuilderSansMedium","BuilderSansBold","BuilderSansExtraBold","Arimo","ArimoBold" },
	Default = 12
})
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddDropdown("ESPTracersOrigin",  { Text = "Tracer Origin", Values = { "Bottom","Center","Top","Mouse" }, Default = 1 })
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPTracerThickness",  { Text = "Tracer Thickness", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPTracersToggle",    { Text = "Enable Tracers", Default = false, Tooltip = "Draws a line to highlighted objects." })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider("ESPArrowsRadius",     { Text = "Arrow Radius", Min = 100, Max = 500, Default = 250, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle("ESPArrowsToggle",     { Text = "Enable Arrows", Default = false, Tooltip = "Shows arrow that point to off-screen objects." })

Abysall.ESPLibrary:SetRainbow(false)
Abysall.ESPLibrary:SetShowDistance(true)
Abysall.ESPLibrary:SetFillTransparency(0.75)
Abysall.ESPLibrary:SetOutlineTransparency(0)
Abysall.ESPLibrary:SetTextTransparency(0)
Abysall.ESPLibrary:SetTextOutlineTransparency(0)
Abysall.ESPLibrary:SetRenderLimit(240)
Abysall.ESPLibrary:SetFadeTime(0.25)
Abysall.ESPLibrary:SetTextSize(20)
Abysall.ESPLibrary:SetFont(Enum.Font.Highway)
Abysall.ESPLibrary:SetTracers(false)
Abysall.ESPLibrary:SetTracerSize(0.75)
Abysall.ESPLibrary:SetTracerOrigin("Bottom")
Abysall.ESPLibrary:SetArrows(false)
Abysall.ESPLibrary:SetArrowRadius(250)
Abysall.ESPLibrary:SetDistanceSizeRatio(0.8)

Toggles.ESPRainbow:OnChanged(function(V)        Abysall.ESPLibrary:SetRainbow(V) end)
Toggles.ESPShowDistance:OnChanged(function(V)   Abysall.ESPLibrary:SetShowDistance(V) end)
Options.ESPFillTransparency:OnChanged(function(V)        Abysall.ESPLibrary:SetFillTransparency(V) end)
Options.ESPOutlineTransparency:OnChanged(function(V)     Abysall.ESPLibrary:SetOutlineTransparency(V) end)
Options.ESPTextTransparency:OnChanged(function(V)        Abysall.ESPLibrary:SetTextTransparency(V) end)
Options.ESPTextOutlineTransparency:OnChanged(function(V) Abysall.ESPLibrary:SetTextOutlineTransparency(V) end)
Options.ESPFadeTime:OnChanged(function(V)        Abysall.ESPLibrary:SetFadeTime(V) end)
Options.ESPRenderLimit:OnChanged(function(V)     Abysall.ESPLibrary:SetRenderLimit(V) end)
Options.ESPTextSize:OnChanged(function(V)        Abysall.ESPLibrary:SetTextSize(V) end)
Options.ESPTextFont:OnChanged(function(V)        Abysall.ESPLibrary:SetFont(Enum.Font[V]) end)
Toggles.ESPTracersToggle:OnChanged(function(V)   Abysall.ESPLibrary:SetTracers(V) end)
Options.ESPTracersOrigin:OnChanged(function(V)   Abysall.ESPLibrary:SetTracerOrigin(V) end)
Options.ESPTracerThickness:OnChanged(function(V) Abysall.ESPLibrary:SetTracerSize(V) end)
Toggles.ESPArrowsToggle:OnChanged(function(V)    Abysall.ESPLibrary:SetArrows(V) end)
Options.ESPArrowsRadius:OnChanged(function(V)    Abysall.ESPLibrary:SetArrowRadius(V) end)

Tabs.Floors:UpdateWarningBox({
	Visible = true,
	Title = "Compatability/Risk Warning",
	Text = "Features highlighted in red are risky / dont work in the current floor.",
})
Groupboxes.Floors_Automation = Tabs.Floors:AddRightGroupbox("Automation")

Groupboxes.Floors_Automation:AddToggle("SkipSeekMines", {
	Text = "Skip Seek (Mines)",
	Default = false,
	Tooltip = "Skips the entire Seek sections.",
	Risky = Floor ~= "Mines"
})

Toggles.SkipSeekMines:OnChanged(function(Value)
	if Value then
		if Floor ~= "Mines" then
			return
		end
		task.spawn(function()
			local MinesSkipSeekCurrentRooms

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")
				task.wait()
			until MinesSkipSeekCurrentRooms

			local MinesSkipSeekStartRoom

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")

				if MinesSkipSeekCurrentRooms then
					MinesSkipSeekStartRoom = MinesSkipSeekCurrentRooms:FindFirstChild("42")
				end

				task.wait()
			until MinesSkipSeekStartRoom

			local MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekStartDoor = MinesSkipSeekStartRoom:FindFirstChild("Door", true)
				task.wait()
			until MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				task.wait()
			until MinesSkipSeekStartDoor:GetAttribute("Opened") == true

			if Character and Character:GetAttribute("Minecarting") == true then
				Character:SetAttribute("Minecarting", false)
			end

			for _, MinesSkipSeekRoomNumber in ipairs({
				43, 44, 45, 46, 47, 48, 49,
				78, 79, 80, 81, 82, 83
			}) do
				if not Toggles.SkipSeekMines.Value then
					return
				end

				local MinesSkipSeekRoom

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					MinesSkipSeekCurrentRooms = workspace:FindFirstChild("CurrentRooms")

					if MinesSkipSeekCurrentRooms then
						MinesSkipSeekRoom = MinesSkipSeekCurrentRooms:FindFirstChild(
							tostring(MinesSkipSeekRoomNumber)
						)
					end

					task.wait()
				until MinesSkipSeekRoom

				local MinesSkipSeekDoor

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					MinesSkipSeekDoor = MinesSkipSeekRoom:FindFirstChild("Door", true)
					task.wait()
				until MinesSkipSeekDoor

				repeat
					if not Toggles.SkipSeekMines.Value then
						return
					end

					if Character then
						Character:PivotTo(MinesSkipSeekDoor:GetPivot())
					end

					task.wait()
				until MinesSkipSeekDoor:GetAttribute("Opened") == true

				if MinesSkipSeekRoomNumber == 49 or MinesSkipSeekRoomNumber == 83 then
					if not Character then
						return
					end

					local MinesSkipSeekVoidPivot = Character:GetPivot()
					MinesSkipSeekVoidPivot = MinesSkipSeekVoidPivot + Vector3.new(0, -1000, 0)

					task.wait(0.3)

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					for MinesSkipSeekVoidCount = 1, 12 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end

					task.wait(0.3)

					for MinesSkipSeekVoidCount = 1, 6 do
						Character:PivotTo(MinesSkipSeekVoidPivot)
					end
				end

				if MinesSkipSeekRoomNumber == 83 then
					return
				end
			end
		end)
	end
end)

Groupboxes.Floors_Automation:AddToggle("AutoSteerMinecart", {
	Text = "Auto Steer Minecart", Default = false, Tooltip = "Automatically completes the minecart chase.",
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider("AutoSteerMinecartTurnDistance", {
	Text = "Turn Distance", Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider("AutoSteerMinecartDuckDistance", {
	Text = "Crouch Distance", Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({"require"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddDivider()
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalk",             { Text = "Auto Rooms",       Default = false, Tooltip = "Automatically moves and hides from entities in The Rooms." })
Groupboxes.Floors_Automation:AddSlider("RoomsAutoWalkPathfindTimeout", { Text = "Pathfind Timeout", Min = 0.5, Max = 3, Default = 1, Rounding = 1 })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkIgnoreA60",    { Text = "Ignore A-60",      Default = false, Tooltip = "Continues to walk if entity 'A-60' is present, enables position spoof automatically." })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkShowPathToggle", { Text = "Show Path",       Default = false, Tooltip = "Shows the current path of rooms auto-walk." })
Groupboxes.Floors_Automation:AddToggle("RoomsAutoWalkSpoofFootsteps", {
    Text = "Spoof Footsteps", Default = false, Tooltip = "Makes it appear as if your character is walking normally.",
    Disabled = not Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}), DisabledTooltip = Globals.IncompatibleMessage
})

Toggles.RoomsAutoWalk:OnChanged(function()
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object:Destroy() end
	end
end)
Toggles.RoomsAutoWalkShowPathToggle:AddColorPicker("RoomsAutoWalkShowPathColor", { Text = "Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.RoomsAutoWalkShowPathToggle:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object.Transparency = Value and 0.5 or 1 end
	end
end)
Options.RoomsAutoWalkShowPathColor:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "PathNode" then Object.Color = Value end
	end
end)

Functions.RoomsAutoWalk = {}
Functions.RoomsAutoWalk.GetNearestHidingSpot = function()
	local Nearest = { Distance = math.huge, Object = nil }
	for _, Object in Objects.HidingSpots do
		if Object.PrimaryPart and Object:FindFirstChild("HidePrompt") then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Object.PrimaryPart.Position.Y > -10 then
				local HiddenPlayer = Object:FindFirstChild("HiddenPlayer", true)
				if HiddenPlayer and not HiddenPlayer.Value then
					Nearest.Distance = Distance
					Nearest.Object = Object
				end
			end
		end
	end
	return Nearest.Object
end

local RoomsEntityList = { "RushMoving","AmbushMoving","BackdoorRush","A60","A120","CustomEntity","GlitchRush","GlitchAmbush" }
Functions.RoomsAutoWalk.GetPathfindTarget = function()
	for _, Object in Services.Workspace:GetChildren() do
		if table.find(RoomsEntityList, Object.Name) and Object.PrimaryPart then
			local Y = Object.PrimaryPart.Position.Y
			if Y > -10 and Y < 150 then
				if Object.Name == "A60" and not Toggles.RoomsAutoWalkIgnoreA60.Value or Object.Name ~= "A60" then
					return Functions.RoomsAutoWalk.GetNearestHidingSpot() or CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("RoomExit")
				end
			end
		end
	end
	return CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild("RoomExit")
end

Connections.RoomsAutoWalkHandler = Services.RunService.Heartbeat:Connect(function()
	if Floor ~= "Rooms" or not Toggles.RoomsAutoWalk.Value or Globals.RoomsAutoWalkActive or not CollisionPart or LatestRoom.Value >= 1000 then return end
	Globals.RoomsAutoWalkActive = true

	local Path = Services.PathfindingService:CreatePath({
		AgentCanJump = true, AgentCanClimb = false, WaypointSpacing = 4,
		AgentRadius = 1.5, AgentHeight = 1.5, Costs = { StuckPart = 8 }
	})

	if Toggles.RoomsAutoWalkIgnoreA60.Value and not Toggles.PositionSpoof.Value then
		Toggles.PositionSpoof:SetValue(true)
	end

	local TargetPart = Functions.RoomsAutoWalk.GetPathfindTarget()
	if not TargetPart then
		Globals.RoomsAutoWalkActive = false
		return
	end

	local TargetPosition
	if TargetPart.Name == "RoomExit" then
		TargetPosition = TargetPart.Position
	elseif TargetPart:FindFirstChild("HidePrompt") then
		for _, Part in TargetPart:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanCollide = false end
		end
		TargetPosition = TargetPart.PrimaryPart.Position
	end

	if CollisionPart.Anchored and not TargetPart:FindFirstChild("HidePrompt") then
		Character:SetAttribute("Hiding", true)
		RemotesFolder.CamLock:FireServer()
		Character:SetAttribute("Hiding", false)
	end

	local CurrentRoom = CurrentRooms[tostring(LatestRoom.Value)]
	if CurrentRoom:FindFirstChild("Door") then
		CurrentRoom.Door.Door.CanCollide = false
	end

	if not TargetPosition or LocalPlayer:DistanceFromCharacter(TargetPosition) >= 750 then
		Globals.RoomsAutoWalkActive = false
		return
	end

	Path:ComputeAsync(CollisionPart.Position, TargetPosition)
	local Waypoints = Path:GetWaypoints()

	if #Waypoints == 0 then
		local RoomExit = CurrentRoom:FindFirstChild("RoomExit")
		if RoomExit then Humanoid:MoveTo(RoomExit.Position) end
		Globals.RoomsAutoWalkActive = false
		return
	end

	for _, Node in Globals.RoomsNodesFolder:GetChildren() do
		if Node.Name == "PathNode" then Node:Destroy() end
	end

	for _, Waypoint in Waypoints do
		local Block = Instance.new("Part", Globals.RoomsNodesFolder)
		Block.Transparency = Toggles.RoomsAutoWalkShowPathToggle.Value and 0.5 or 1
		Block.Size = Vector3.one
		Block.Position = Waypoint.Position
		Block.Shape = Enum.PartType.Ball
		Block.CanCollide = false
		Block.Anchored = true
		Block.Name = "PathNode"
		Block.Color = Options.RoomsAutoWalkShowPathColor.Value
		Block.Material = Enum.Material.Neon
	end

	local Stuck = false
	for _, Waypoint in Waypoints do
		if Stuck or not Toggles.RoomsAutoWalk.Value then break end

		local Finished = false
		local Start = tick()

		local StepConnection = Services.RunService.RenderStepped:Connect(function()
			if Stuck or not Toggles.RoomsAutoWalk.Value then Finished = true return end

			local NewTarget = Functions.RoomsAutoWalk.GetPathfindTarget()
			if NewTarget and NewTarget:FindFirstChild("HidePrompt") and not TargetPart:FindFirstChild("HidePrompt") then
				Finished = true return
			end
			if TargetPart:FindFirstChild("HidePrompt") then
				local HidePrompt = TargetPart:FindFirstChild("HidePrompt")
				if LocalPlayer:DistanceFromCharacter(TargetPosition) < HidePrompt.MaxActivationDistance
					and Character:GetAttribute("Hiding") ~= true
				then
					Functions.ForceFirePrompt(HidePrompt)
				end
			end
			local FlatPos = Vector3.new(Waypoint.Position.X, RootPart.Position.Y, Waypoint.Position.Z)
			if LocalPlayer:DistanceFromCharacter(FlatPos) < 5 then Finished = true end
			Humanoid:MoveTo(Waypoint.Position)
		end)

		while not Finished do
			if tick() - Start > Options.RoomsAutoWalkPathfindTimeout.Value then
				local StuckBlock = Instance.new("Part", Globals.RoomsNodesFolder)
				StuckBlock.Transparency = 1
				StuckBlock.Size = Vector3.one
				StuckBlock.CFrame = Collision.CFrame
				StuckBlock.Shape = Enum.PartType.Ball
				StuckBlock.CanCollide = false
				StuckBlock.Anchored = true
				StuckBlock.Name = "StuckPart"
				local Modifier = Instance.new("PathfindingModifier", StuckBlock)
				Modifier.Label = "StuckPart"
				Stuck = true
				break
			end
			task.wait()
		end
		StepConnection:Disconnect()
		Humanoid:MoveTo(RootPart.Position)
	end

	Globals.RoomsAutoWalkActive = false
end)

Connections.RoomsHandler = CurrentRooms.ChildAdded:Connect(function(Room)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == "StuckPart" then Object:Destroy() end
	end

	if Room:GetAttribute("RawName") and string.find(Room:GetAttribute("RawName"), "Eyestalk") then
        local PreviousNode = nil

		local function CreateEyestalkNode(WaypointPos)
			local NewNode = Instance.new("Part")
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.Position = WaypointPos
			NewNode.CanCollide = false
			NewNode.Name = "SeekLightNode"

			local PrevNode = PreviousNode or NewNode
			PreviousNode = NewNode

			local NewBeam = Instance.new("Beam")
			NewBeam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Options.ShowEyestalkPathColor.Value), ColorSequenceKeypoint.new(1, Options.ShowEyestalkPathColor.Value) })
			NewBeam.FaceCamera = true
			NewBeam.Width0 = 0.2
			NewBeam.Width1 = 0.2
			NewBeam.Brightness = 10
			NewBeam.LightInfluence = 0
			NewBeam.LightEmission = 0
			NewBeam.Enabled = true

			local Vis = Toggles.ShowEyestalkPathToggle.Value and 0 or 1
			NewBeam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
			NewBeam.Parent = Globals.SeekNodesFolder

			local A0 = Instance.new("Attachment", NewNode)
			local A1 = Instance.new("Attachment", PrevNode)
			NewBeam.Attachment0 = A0
			NewBeam.Attachment1 = A1

			table.insert(Objects.EyestalkHighlights, NewBeam)
		end

		Room:WaitForChild("RoomEntrance", 9e9)
		Room:WaitForChild("RoomExit", 9e9)

		while not Room:GetAttribute("PathFound") do
			if Toggles.ShowEyestalkPathToggle.Value then
				local EyePath = game:GetService("PathfindingService"):CreatePath({
					AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2, AgentRadius = 1, AgentHeight = 1
				})
				EyePath:ComputeAsync(RootPart.Position, Room.RoomExit.Position)
				if EyePath.Status == Enum.PathStatus.Success then
					Room:SetAttribute("PathFound", true)
					for _, Waypoint in EyePath:GetWaypoints() do
						CreateEyestalkNode(Waypoint.Position)
						task.wait()
					end
                    break
				end
			end
			task.wait(0.25)
		end
	end
end)

Groupboxes.Floors_Completion = Tabs.Floors:AddRightGroupbox("Completion")
Groupboxes.Floors_Completion:AddButton({
    Text = "Auto Complete Dam Seek",
    Tooltip = "Automatically teleports to and interacts with each water pump.",
    Func = function()
        if LatestRoom.Value < 100 or Floor ~= "Mines" then
            Functions.Notify({Title = "You must be in Room 200 to do this."})
            return
        end

		local IsCutscene = false
		local CutsceneConnection = RemotesFolder.Cutscene.OnClientEvent:Connect(function()
			IsCutscene = true
			task.wait(7)
			IsCutscene = false
		end)

        local function GetNextPump()
            local Highest = {
                Height = -69420,
                Object = nil
            }
            for _, Object in pairs(Objects.Objectives) do
                if Object.Name == "WaterPump" and Object:GetAttribute("Abysall_Completed") ~= true then
                    if Object.PrimaryPart and Object.PrimaryPart.Position.Y > Highest.Height then
                        Highest.Object = Object
                        Highest.Height = Object.PrimaryPart.Position.Y
                    end
                end
            end
            return Highest.Object
        end

        local function HandlePump(Pump)

            while task.wait(0.1) do
				if IsCutscene then
					continue
				end

                Character:PivotTo(Pump:GetPivot())

                local Prompt = Pump:FindFirstChild("ValvePrompt", true)
                if Prompt then
                    Functions.ForceFirePrompt(Prompt)
                end

                if Pump:GetAttribute("Abysall_Completed") then
                    break
                end
            end
        end

        Functions.Notify({Title = "Attempting to complete the valves.", Body = "Please wait."})
        while task.wait(0.1) do
            local Pump = GetNextPump()
            if Pump then
                HandlePump(Pump)
            else
                break
            end
        end
        Functions.Notify({Title = "Successfully completed the valves."})
    end
})

Groupboxes.Floors_Completion:AddButton({
    Text = "Auto Complete Cringle",
    Tooltip = "Instantly completes the quest.",
    Func = function()
        local TouchPart = CurrentRooms:FindFirstChild("RippleExitDoor", true)
        if TouchPart then
            Character:PivotTo(TouchPart:GetPivot())
        end
    end
})

Groupboxes.Floors_Visuals = Tabs.Floors:AddLeftGroupbox("Visuals")
Groupboxes.Floors_Visuals:AddToggle("ShowSeekPathToggle", {
	Text = "Show Seek Path", Default = false, Tooltip = "Shows you the correct path in seek chases.",
	Risky = Floor ~= "Mines"
})
Toggles.ShowSeekPathToggle:AddColorPicker("ShowSeekPathColor", { Text = "Seek Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local function UpdateBeamVisibility(BeamTable, ColorKey, Visible)
	local Vis = Visible and 0 or 1
	local Seq = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
	for _, Beam in BeamTable do Beam.Transparency = Seq end
end
local function UpdateBeamColor(BeamTable, Value)
	local Seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Value) })
	for _, Beam in BeamTable do Beam.Color = Seq end
end

Toggles.ShowSeekPathToggle:OnChanged(function(V)  UpdateBeamVisibility(Objects.SeekHighlights, "ShowSeekPathColor", V) end)
Options.ShowSeekPathColor:OnChanged(function(V)   UpdateBeamColor(Objects.SeekHighlights, V) end)

Groupboxes.Floors_Visuals:AddToggle("ShowEyestalkPathToggle", {
	Text = "Show Eyestalk Path", Default = false, Tooltip = "Shows you the correct path in the eyestalk chase.",
	Risky = Floor ~= "Garden"
})
Toggles.ShowEyestalkPathToggle:AddColorPicker("ShowEyestalkPathColor", { Text = "Eyestalk Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.ShowEyestalkPathToggle:OnChanged(function(V) UpdateBeamVisibility(Objects.EyestalkHighlights, "ShowEyestalkPathColor", V) end)
Options.ShowEyestalkPathColor:OnChanged(function(V)  UpdateBeamColor(Objects.EyestalkHighlights, V) end)

Groupboxes.Floors_Bypass = Tabs.Floors:AddLeftGroupbox("Bypass")
Groupboxes.Floors_Bypass:AddToggle("RemoveSeekTrigger", {
	Text = "Delete Seek Trigger", Default = false, Tooltip = "Diables the 'Seek' chase trigger.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel"),
	Disabled = not Functions.CheckCompatability({"firetouchinterest"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle("RemoveFigure", {
	Text = "Delete Figure", Default = false, Tooltip = "Completely removes the entity 'Figure' (doesn't always work).",
	Risky = not (Floor == "Fools" or Floor == "OldHotel" or Floor == "Mines"),
	Disabled = not Functions.CheckCompatability({"isnetworkowner"}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle("AutoRevive", {
	Text = "Infinite Revives", Default = false, Tooltip = "Automatically revives after dying, with unlimited respawns.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel")
})
Groupboxes.Floors_Bypass:AddToggle("FigureGodmode", {
	Text = "Figure Godmode", Default = false, Tooltip = "Prevents 'Figure' from hurting you.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel")
})
Groupboxes.Floors_Bypass:AddDivider()
Groupboxes.Floors_Bypass:AddToggle("RemoveBasementGate",  { Text = "Remove Basement Gate",   Default = false, Tooltip = "Removes the gate from basement rooms.",            Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Groupboxes.Floors_Bypass:AddToggle("RemovePaintingsDoor", { Text = "Remove Paintings Door",  Default = false, Tooltip = "Removes the fireplace doors from painting rooms.", Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Groupboxes.Floors_Bypass:AddToggle("RemoveSkeletonDoor",  { Text = "Remove Skeleton Door",   Default = false, Tooltip = "Removes the skeleton door from the infirmary.",    Risky = Floor ~= "Fools" })

local ObstructionNames = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
for ObjName, ToggleName in ObstructionNames do
	Toggles[ToggleName]:OnChanged(function(Value)
		for _, Object in Objects.Obstructions do
			if Object.Name == ObjName then
				Object:PivotTo(Value and CFrame.new(-10000, -10000, -10000) or Object:GetAttribute("OriginalPosition"))
			end
		end
	end)
end

Groupboxes.Floors_Farming = Tabs.Floors:AddLeftGroupbox("Farming")
Groupboxes.Floors_Farming:AddToggle("KnobFarm", {
    Text = "Knob Farm",
    Default = false,
    Tooltip = "Automatically gains knobs for you, dies and revives repeatedly.",
	Risky = Floor ~= "Ballz",
})

Groupboxes.Floors_Farming:AddButton({
    Text = "Start Knob Farm",
    Tooltip = "Starts farming knobs, click this when you have enough gold.",
    Func = function()
		if LatestRoom.Value ~= 0 then
			Functions.Notify({Title = "You must be in Room 0 to use this."})
			return
		end

		if LocalPlayer.PlayerGui:FindFirstChild("TopbarUI") then 
			local GoldCount = LocalPlayer.PlayerGui.TopbarUI.Topbar.StatsTopbarHandler.StatModules.Gold.GoldVal
			if GoldCount.Value <= 0 then
				Functions.Notify({Title = "You must have gold to do this."})
				return
			end
		end

        Globals.KnobFarmStarted = true
    end
})

Groupboxes.Floors_Farming:AddDivider()
Groupboxes.Floors_Farming:AddButton({
	Text = "Start Death Farm",
	DoubleClick = true,
	Tooltip = "Automatically farms deaths, joining new runs.",
	Func = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau"))()
	end,

	Disabled = not Functions.CheckCompatability({"fireproximityprompt", "firesignal"}),
	DisabledTooltip = Globals.ImcompatibleMessage
})
Groupboxes.Floors_Farming:AddButton({
	Text = "Copy Death Farm Loadstring",
	DoubleClick = false,
	Tooltip = "Copies the death farm loadstring to your clipboard.",
	Func = function()
		toclipboard([==[
			loadstring(game:HttpGet("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau"))()
		]==])
		Library:Notify("Loadstring has been copied to your clipboard.")
	end,

	Disabled = not Functions.CheckCompatability({"fireproximityprompt", "firesignal"}),
	DisabledTooltip = Globals.ImcompatibleMessage
})

Toggles.KnobFarm:OnChanged(function(Value)
    if Value then
        Functions.Notify({Title = "Please collect some gold to earn knobs.", Body = "Click 'Start Knob Farm' when you're ready."})
	else
		Globals.KnobFarmStarted = false
    end
end)

Globals.KnobFarmActive = false
Globals.KnobFarmStarted = false
Connections.KnobFarm = Services.RunService.Heartbeat:Connect(function()
	if Toggles.KnobFarm.Value and Globals.KnobFarmStarted then
		if not Globals.KnobFarmActive then
			Globals.KnobFarmActive = true
			if Functions.CheckCompatability({"replicatesignal"}) then
				Abysall.Environment.replicatesignal(LocalPlayer.Kill)
			else
				LocalPlayer.Character.Humanoid.Health = 0
			end
			while task.wait() do
				if LocalPlayer:GetAttribute("Alive") then
					break
				end
			end
			RemotesFolder.Statistics:FireServer()
			task.wait(0.25)
			Globals.KnobFarmActive = false
		end
	end
end)

local MainHook
local OtherHook
if Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}) then
	MainHook = Abysall.Environment.hookmetamethod(game, "__namecall", Abysall.Environment.newcclosure(function(Self, ...)
		local Args = { ... }
		if Abysall and Abysall.Environment then
			local Method = Abysall.Environment.getnamecallmethod()

			if Self.Name == "Crouch" and Method == "FireServer" then
				if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then
					Args[1] = true
				end
				Args[2] = true
			end

			if Self.Name == "ClutchHeartbeat" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value or Self.Name == "HideMonster" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value then
				return
			end

			if Self.Name == "MotorReplication" and Method == "FireServer" then
				local DoBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
				if DoBypass then
					if Floor == "Fools" or Floor == "OldHotel" then
						Args[1] = 0 Args[2] = (Globals.SpoofOffset == 200 and 65 or -65) Args[3] = 0 Args[4] = false
					else
						Args[1] = -650
					end
				end
			end
		end
		return MainHook(Self, table.unpack(Args))
	end))

    OtherHook = Abysall.Environment.hookmetamethod(game, "__index", Abysall.Environment.newcclosure(function(Self, Property)
        local Real = OtherHook(Self, Property)

        if Property == "MoveDirection" and Self == Humanoid and Globals.RoomsAutoWalkActive and Toggles.RoomsAutoWalkSpoofFootsteps.Value and Floor == "Rooms" and not Character:GetAttribute("Hiding") then
            return RootPart.CFrame.LookVector
        end
        
        return Real
    end))
end

if Services.ReplicatedStorage:FindFirstChild("ModulesClient") then
	ClientModules = Services.ReplicatedStorage.ModulesClient
else
	ClientModules = Services.ReplicatedStorage.ClientModules
end

Modules = {
	Glitch         = ClientModules.EntityModules.Glitch,
	Shade          = ClientModules.EntityModules.Shade,
	Void           = ClientModules.EntityModules:FindFirstChild("Void"),
	SpiderJumpscare = nil,
	A90            = nil,
	Screech        = nil,
	Dread          = nil,
	GlitchScreech  = nil,
}

local CharacterOldConnectionKeys = {
	"MainHandler", "JumpHandler", "SlideHandler", "LibraryCodeHandler1", "LibraryCodeHandler2",
	"OxygenConnection", "AnimationHandler", "AutoHideConnection", "AutoReviveHandler",
	"SHMFixer", "AnticheatDisabler", "AnticheatEnableDetector1", "AnticheatEnableDetector2",
	"AutoSteerMinecartDuckHandler", "AutoSolveAnchorsConnection", "InfiniteJumpsConnection1", "InfiniteJumpsConnection2",
	"FootstepHandler"
}

Globals.IsTyping = false
Connections.TextBoxConnection1 = Services.UserInputService.TextBoxFocused:Connect(function()
	Globals.IsTyping = true
end)
Connections.TextBoxConnection2 = Services.UserInputService.TextBoxFocusReleased:Connect(function()
	Globals.IsTyping = false
end)

Functions.HandleCharacter = function(NewCharacter)
	for _, Key in CharacterOldConnectionKeys do
		if Connections[Key] then
			Connections[Key]:Disconnect()
			Connections[Key] = nil
		end
	end

	while not LocalPlayer.PlayerGui:FindFirstChild("MainUI") do
		task.wait()
	end

	Character = NewCharacter
	Humanoid = NewCharacter:WaitForChild("Humanoid", 9e9)
	RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")
	Camera   = Services.Workspace.CurrentCamera

	Globals.OldCamera = Camera
	Globals.MainUI = LocalPlayer.PlayerGui.MainUI

	Collision = NewCharacter:WaitForChild("Collision")
	CollisionPart  = NewCharacter:FindFirstChild("CollisionPart") or NewCharacter:FindFirstChild("Collision")
	CollisionClone = Collision:Clone()
	CollisionClone.Parent = NewCharacter
	CollisionClone.Name = "CollisionClone"
	CollisionClone.Massless = true

	CollisionPartClone = CollisionPart:Clone()
	CollisionPartClone.Parent = NewCharacter
	CollisionPartClone.Name = "CollisionPartClone"
	CollisionPartClone.CanCollide = false
	CollisionPartClone.Massless = true

	if CollisionPartClone:FindFirstChild("CollisionCrouch") then
		CollisionPartClone.CollisionCrouch:Destroy()
	end

	Character:SetAttribute("SpeedBoost", 0)
	Character:SetAttribute("SpeedBoostBehind", 0)
	Character:SetAttribute("SpeedBoostExtra", 0)

	OldJump  = NewCharacter:GetAttribute("CanJump")
	OldSlide = NewCharacter:GetAttribute("CanSlide")

	if Toggles.EnableCharacterJump.Value  then Character:SetAttribute("CanJump",  true) end
	if Toggles.EnableCharacterSlide.Value then Character:SetAttribute("CanSlide", true) end

	if Functions.CheckCompatability({"require"}) then
		Main_Game = Abysall.Environment.require(Globals.MainUI.Initiator.Main_Game)
	end

	if Main_Game and Toggles.RemoveCameraBobbing.Value then
		Main_Game.spring.Speed = 9e9
	end

	if Main_Game and Functions.CheckCompatability({"require"}) then
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		local OriginalGetMoveVector = Controls.GetMoveVector
		Globals.OriginalGetMoveVector = OriginalGetMoveVector
		Controls.GetMoveVector = function(...)
			if Toggles.AutoSteerMinecart.Value and Floor == "Mines" then
				local Node = Globals.NearestTurnNode
				if Node and Functions.GetMinecart() then
					local Turn = Node:GetAttribute("Turn")
					return Turn == "Left" and Vector3.new(-1, 0, 0) or Turn == "Right" and Vector3.new(1, 0, 0) or Vector3.zero
				end
			end
			return OriginalGetMoveVector(...)
		end
	end

	Globals.AutoMinecartDucked = false
	Globals.LastDuck = tick()
	Connections.AutoSteerMinecartDuckHandler = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSteerMinecart.Value or not Functions.GetMinecart() or tick() - Globals.LastDuck < 0.1 then return end
		Globals.NearestTurnNode = Functions.GetNearestTurnNode()

		if not Globals.AutoMinecartDucked and Functions.GetNearestDuckBoard() then
			Main_Game.crouch(true)
			Globals.AutoMinecartDucked = true
		elseif not Functions.GetNearestDuckBoard() and Globals.AutoMinecartDucked then
			Main_Game.crouch(false)
			Globals.AutoMinecartDucked = false
		end
		if Main_Game then
			Main_Game.fovtarget = Options.FieldOfView.Value
		else
			Camera.FieldOfView = Options.FieldOfView.Value
		end
		Globals.LastDuck = tick()
	end)

	Globals.AnticheatDisabled = false

	local UIModules = Globals.MainUI.Initiator.Main_Game.RemoteListener.Modules
	Modules.A90             = UIModules:FindFirstChild("A90")
	Modules.Screech         = UIModules.Screech
	Modules.Dread           = UIModules:FindFirstChild("Dread")
	Modules.SpiderJumpscare = UIModules.SpiderJumpscare

	if Toggles.RemoveScreech.Value    then Modules.Screech.Name = "Screech_Disabled" print ("screech gone") end
	if Toggles.RemoveA90.Value and Modules.A90   then Modules.A90.Name = "A90_Disabled" end
	if Toggles.RemoveDread.Value and Modules.Dread then Modules.Dread.Name = "Dread_Disabled" end
	if Toggles.DisableTimothyJumpscare.Value then Modules.SpiderJumpscare.Name = "SpiderJumpscare_Disabled" end

	if Toggles.DisableHideVignette.Value then
		local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
		if Vignette then Vignette.Image = "Disabled" end
	end
	if Toggles.RemoveInteractingSounds.Value then
		local PS = Globals.MainUI.Initiator.Main_Game.PromptService
		PS.Triggered.Volume = 0
		PS.Holding.Volume   = 0
		PS.Notification.Volume = 0
		Globals.MainUI.Initiator.Main_Game.Reminder.Caption.Volume = 0
	end
	if Toggles.DisableEntityJumpscares.Value then
		local JS = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		if JS then JS.Name = "Jumpscares_Disabled" end
	end
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") then
            Object:SetAttribute("OriginalName", Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. "_Disabled"
            end
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA("ModuleScript") then
            Object:SetAttribute("OriginalName", Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. "_Disabled"
            end
        end
    end

	CustomPhysics = PhysicalProperties.new(
		100,
		RootPart.CustomPhysicalProperties.Friction,
		RootPart.CustomPhysicalProperties.Elasticity,
		RootPart.CustomPhysicalProperties.FrictionWeight,
		RootPart.CustomPhysicalProperties.ElasticityWeight
	)
	for _, Part in NewCharacter:GetDescendants() do
		if Part:IsA("BasePart") then
			PartProperties[Part] = Part.CustomPhysicalProperties
			if Toggles.RemoveAcceleration.Value then
				Part.CustomPhysicalProperties = CustomPhysics
			end
		end
	end

	Connections.LibraryCodeHandler1 = LocalPlayer.PlayerGui.PermUI.Hints.ChildAdded:Connect(function()
		if Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find("_") and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild("Padlock", true)
				Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.LibraryCodeHandler2 = Character.ChildAdded:Connect(function(Child)
		if (Child.Name == "LibraryHintPaper" or Child.Name == "LibraryHintPaperHard") and Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find("_") and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild("Padlock", true)
				Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.FootstepHandler = Character.ChildAdded:Connect(function(Object)
		if Object:IsA("Sound") and Object.Name == "Sound" and Toggles.RemoveFootstepSounds.Value then
			Object.Volume = 0
		end
	end)

	Globals.OldOxygen = Character:GetAttribute("Oxygen")
	Connections.OxygenConnection = Character:GetAttributeChangedSignal("Oxygen"):Connect(function()
		local NewOxy = Character:GetAttribute("Oxygen")
		if NewOxy < Globals.OldOxygen and Toggles.NotifyOxygen.Value then
			Functions.Caption(Functions.FormatOxygen(NewOxy), true)
		end
		Globals.OldOxygen = NewOxy
	end)

	Connections.AutoReviveHandler = LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
		if LocalPlayer:GetAttribute("Alive") == false and Toggles.AutoRevive.Value then
			if Floor == "Fools" or Floor == "OldHotel" then
				while LocalPlayer:GetAttribute("Alive") ~= true do
					RemotesFolder.Revive:FireServer()
					task.wait(0.5)
				end
			end
		end
	end)

	Connections.SHMFixer = RootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		task.wait()
		if Floor == "Fools" and RootPart.Anchored and Character:GetAttribute("Hiding") ~= true then
			RootPart.Anchored = false
		end
	end)

	Connections.AnticheatDisabler = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
		if Character:GetAttribute("Climbing") == true and Toggles.DisableAnticheat.Value and not Globals.AnticheatDisabled then
			task.wait(0.25)
			Character:SetAttribute("Climbing", false)
			Functions.Notify({ Title = "Successfully disabled the anticheat.", Body = "It will be re-enabled after a cutscene or halt room." })
			Globals.AnticheatDisabled = true
		end
	end)

	Connections.AnticheatEnableDetector1 = RemotesFolder:WaitForChild("Cutscene").OnClientEvent:Connect(function(CutsceneName)
		if Globals.AnticheatDisabled and not CutsceneName:find("SewerSeek") then
			Globals.AnticheatDisabled = false
			Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
		end
	end)

	Connections.AnticheatEnableDetector2 = RemotesFolder:WaitForChild("UseEnemyModule").OnClientEvent:Connect(function(ModuleName)
		if ModuleName == "Void" or ModuleName == "Glitch" then
			if Globals.AnticheatDisabled then
				Globals.AnticheatDisabled = false
				Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
			end
			LocalPlayer:SetAttribute("CurrentRoom", LatestRoom.Value)
		end
	end)

	Connections.AnimationHandler = Character.ChildAdded:Connect(function()
		local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
		local Tool
		for _, Name in ToolNames do
			Tool = Character:FindFirstChild(Name)
			if Tool then break end
		end
		if not Tool then return end

		local UseAnim = Tool:FindFirstChild("use", true) or Tool:FindFirstChild("promptanim", true)
		if UseAnim then
			UseAnim = Humanoid:LoadAnimation(UseAnim)
			UseAnim.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimation = UseAnim
		end
		local UseAnimBreak = Tool:FindFirstChild("usefinish", true) or Tool:FindFirstChild("promptanimend", true) or Tool:FindFirstChild("lockpickuse", true)
		if UseAnimBreak then
			UseAnimBreak = Humanoid:LoadAnimation(UseAnimBreak)
			UseAnimBreak.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimationBreak = UseAnimBreak
		end
	end)

	Connections.JumpHandler = Character:GetAttributeChangedSignal("CanJump"):Connect(function()
		local Val = Character:GetAttribute("CanJump")
		if Toggles.EnableCharacterJump.Value and Val ~= true or not Toggles.EnableCharacterJump.Value then
			OldJump = Val
		end
		if Toggles.EnableCharacterJump.Value then Character:SetAttribute("CanJump", true) end
	end)

	Connections.SlideHandler = Character:GetAttributeChangedSignal("CanSlide"):Connect(function()
		local Val = Character:GetAttribute("CanSlide")
		if Toggles.EnableCharacterSlide.Value and Val ~= true or not Toggles.EnableCharacterSlide.Value then
			OldSlide = Val
		end
		if Toggles.EnableCharacterSlide.Value then Character:SetAttribute("CanSlide", true) end
	end)

	Connections.InfiniteJumpsConnection1 = Services.UserInputService.InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Space and Toggles.InfiniteJumps.Value and not Globals.IsTyping then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	local JumpButton = Globals.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton")
	if JumpButton then
		Connections.InfiniteJumpsConnection2 = JumpButton.MouseButton1Down:Connect(function()
			if Toggles.InfiniteJumps.Value then
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	Globals.SpoofOffset = 0
	Globals.LastAutoHide = tick()
	Connections.AutoHideConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoClosetToggle.Value or tick() - Globals.LastAutoHide <= 0.1 then
			Globals.AutoClosetActive = false
			return
		end
		local Entity = Functions.GetNearestEntity(true, Options.AutoClosetEntityList.Value)
		local EntityNearby = Entity and LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position) <= (EntityDistances[Entity.Name] or 150)
		if Character:GetAttribute("Hiding") == true then
			Globals.AutoClosetActive = false
			Globals.SpectateEntity = nil
			if not EntityNearby then
				RemotesFolder.CamLock:FireServer()
			end
			Globals.LastAutoHide = tick()
			return
		end
		if not Entity then
			Globals.SpectateEntity = nil
			Globals.AutoClosetActive = false
			Globals.LastAutoHide = tick()
			return
		end
		if not EntityNearby then
			Globals.SpectateEntity = nil
			Globals.AutoClosetActive = false
			Globals.LastAutoHide = tick()
			return
		end
		local Closet = Functions.GetNearestHidingSpot()
		if Character:GetAttribute("Hiding") ~= true and Closet then
			local Prompt = Closet:FindFirstChild("HidePrompt")
				or Closet:FindFirstChild("HidingPrompt")
				or Closet:FindFirstChild("HidePrompt", true)
				or Closet:FindFirstChild("HidingPrompt", true)

			if not Prompt then
				for _, Child in Closet:GetDescendants() do
					if (Child:IsA("ProximityPrompt") or Child:IsA("InteractPrompt"))
						and (Child.Name == "HidePrompt" or Child.Name == "HidingPrompt")
					then
						Prompt = Child
						break
					end
				end
			end

			if Prompt then
				Globals.AutoClosetActive = true
				Functions.ForceFirePrompt(Prompt)
			end
		end
		if Character:GetAttribute("Hiding") then
			if Toggles.SpectateEntityToggle.Value and Entity.PrimaryPart then
				Globals.SpectateEntity = Entity
			end
		end
		Globals.LastAutoHide = tick()
	end)

	Globals.LastAutoAnchor = tick()
	Connections.AutoSolveAnchorsConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSolveAnchors.Value then return end
		if not Globals.MainUI:FindFirstChild("AnchorHintFrame") then return end
		if tick() - Globals.LastAutoAnchor <= 0.1 then return end
		local Anchor = Functions.GetCurrentAnchor()
		if Anchor and LocalPlayer:DistanceFromCharacter(Anchor.PrimaryPart.Position) < Anchor.ActivateEventPrompt.MaxActivationDistance and not Anchor:GetAttribute("Activated") then
			Anchor:WaitForChild("AnchorRemote"):InvokeServer(Globals.MainUI.AnchorHintFrame.Code.Text)
		end
		Globals.LastAutoAnchor = tick()
	end)

	Globals.ManipulateBody = Instance.new("BodyVelocity")
	Globals.ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.FlyBody = Instance.new("BodyVelocity")
	Globals.FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.SelfKilled = false
	Globals.ThirdPersonParts = {}
	for _, Object in Character:GetDescendants() do
		if Object:IsA("Accessory") and Object:FindFirstChild("Handle") then
			table.insert(Globals.ThirdPersonParts, Object.Handle)
		end
	end
	table.insert(Globals.ThirdPersonParts, Character:WaitForChild("Head"))

	Globals.LastAnimationCheck = tick()
	Globals.LastCrouchFire = tick()
	Globals.OriginalC1 = Character.LowerTorso.Root.C1

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local MainFrame = Globals.MainUI:FindFirstChild("MainFrame")
	if MainFrame and MainFrame:FindFirstChild("SurgeVignette") then
		Globals.SurgeFrame = MainFrame.SurgeVignette
		if Toggles.RemoveSurge.Value then
			Globals.SurgeFrame.Name = "SurgeVignette_Disabled"
		end
	end

	Connections.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if Services.Workspace:FindFirstChild("Camera") then
			Camera = Services.Workspace:FindFirstChild("Camera")
		end

		if Toggles.SpeedBoostToggle.Value then
			Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + Options.SpeedBoostSlider.Value
		end

		if Globals.Lagging or (Options.SpeedBoostSlider.Value <= 6 and Options.FlySpeed.Value <= 21) then
			CollisionPartClone.Massless = true
		end

		Globals.IsEyes    = Services.Workspace:FindFirstChild("Eyes") ~= nil or Services.Workspace:FindFirstChild("Lookman") ~= nil
		Globals.IsLookman = Services.Workspace:FindFirstChild("BackdoorLookman") ~= nil

		if Toggles.AmbientToggle.Value then
			Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = Options.AmbientColor.Value }):Play()
		end

		if Main_Game then
			if Toggles.RemoveCameraShake.Value     then Main_Game.csgo = CFrame.new() end
			if Toggles.ViewmodelOffsetToggle.Value then
				Main_Game.tooloffset = Vector3.new(Options.ViewmodelOffsetX.Value, Options.ViewmodelOffsetY.Value, Options.ViewmodelOffsetZ.Value)
			else
				Main_Game.tooloffset = Vector3.zero
			end
		end

		if Globals.SelfKilled and Globals.MainUI:FindFirstChild("Statistics") then
			Globals.MainUI.Statistics.Death.Text = "Died to Abysall Hub"
		end

		if Globals.Deathing and Globals.MainUI:FindFirstChild("Statistics") then
			Globals.MainUI.Statistics.Death.Text = "Died to Verity"
		end

		local MainFrame = Globals.MainUI:FindFirstChild("MainFrame")
		if MainFrame then
			local Effects = MainFrame.Healthbar:FindFirstChild("Effects")
			if Effects and Effects:FindFirstChild("Crouching") then
				Effects.Crouching.Visible = Functions.IsCrouching()
			end
		end

		if (Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value) and RemotesFolder:FindFirstChild("Crouch") then
			RemotesFolder.Crouch:FireServer(true, true)
		end

		if Floor ~= "Fools" and Floor ~= "OldHotel" and not Camera:FindFirstChild("MinecartRig") then
			RootPart.CanCollide = false
		end

		for _, Part in Character:GetChildren() do
			if Part:IsA("BasePart") then Part.CanCollide = false end
		end

		if LocalPlayer:GetAttribute("Alive") == true then
			Services.SoundService:WaitForChild("Main").Volume = 1
		end

		if Floor == "OldHotel" or Floor == "Fools" then
			local SpoofOffset = Toggles.PositionSpoof.Value and Functions.GetNearestEntity() and 200 or Toggles.FigureGodmode.Value and Functions.GetNearestFigure() and 200 or 0
			Globals.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == "Fools" then
				Collision.CollisionCrouch.CanCollide = false
				CollisionClone.CollisionCrouch.CanCollide = false
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
		else
			Collision.CanCollide = false
			if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end

			if CollisionClone:FindFirstChild("CollisionCrouch") then
				local IsCrouch = Functions.IsCrouching()
				CollisionClone.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or IsCrouch)
				CollisionClone.CollisionCrouch.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or not IsCrouch)
			else
				RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
			end

			if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
				Character.LowerTorso.Root.C1 = Globals.OriginalC1 * CFrame.new(0, Toggles.PositionSpoof.Value and -2.346 or 0, 0)
			end

			local SpoofY = Toggles.PositionSpoof.Value and 2.328 or 0.18
			Collision.Position     = RootPart.Position + Vector3.new(0, SpoofY, 0)
			CollisionPart.Position = RootPart.Position + Vector3.new(0, SpoofY, 0)

			if Collision:FindFirstChild("CollisionCrouch") and CollisionClone:FindFirstChild("CollisionCrouch") then
				local CrouchY = Toggles.PositionSpoof.Value and 1.328 or -0.982
				Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, CrouchY, 0)
				CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
			end
			if CollisionClone:FindFirstChild("CollisionCrouch") then
				CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 0.75 or -0.982, 0)
			end
		end

		CollisionClone.CollisionGroup = Collision.CollisionGroup
		CollisionClone.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 1.75 or 0.18, 0)

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Velocity" then
			Globals.ManipulateBody.Parent = RootPart
			Globals.ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
		else
			Globals.ManipulateBody.Parent = nil
		end

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Pivot" and Floor ~= "Fools" and Floor ~= "OldHotel" then
			Character:PivotTo(Camera:GetPivot() * CFrame.new(0, 0, 2560))
		end

		if Toggles.FlyToggle.Value then
			Globals.FlyBody.Parent = RootPart
			Globals.FlyBody.Velocity = Functions.GetFlyVelocity() * Options.FlySpeed.Value
		else
			Globals.FlyBody.Parent = nil
		end

		local DoEyesBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
		if DoEyesBypass then
			if Floor == "Fools" or Floor == "OldHotel" then
				RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
			else
				RemotesFolder.MotorReplication:FireServer(-650)
			end
		end

		if RemotesFolder:FindFirstChild("Crouch") and tick() - Globals.LastCrouchFire > 0.1 then
			local IsCrouch = Functions.IsCrouching()
			if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then IsCrouch = true end
			RemotesFolder.Crouch:FireServer(IsCrouch, true)
			Globals.LastCrouchFire = tick()
		end

		if tick() - Globals.LastAnimationCheck > 0.1 then
			local Sliding = false
			for _, Anim in Humanoid:GetPlayingAnimationTracks() do
				if Anim.Name == "Slide" then Sliding = true break end
			end
			Globals.Sliding = Sliding
			Globals.LastAnimationCheck = tick()
		end

		Character:SetAttribute("Sliding", Globals.Sliding)
		if Character:GetAttribute("Crouching") ~= Functions.IsCrouching() then
			Character:SetAttribute("Crouching", Functions.IsCrouching())
		end

		RayParams.FilterDescendantsInstances = { Character }
		local TPOffset = CFrame.new(Options.ThirdPersonOffsetX.Value, Options.ThirdPersonOffsetY.Value, Options.ThirdPersonOffsetZ.Value)
		local Direction = (Camera.CFrame * TPOffset).Position - Camera.CFrame.Position
		local WallResult = Services.Workspace:Spherecast(Camera.CFrame.Position, 0.2, Direction, RayParams)

		if Toggles.ThirdPersonToggle.Value then
			if Toggles.ThirdPersonWallCheck.Value and WallResult and WallResult.Instance.CanCollide then
				local NewPos = Camera.CFrame.Position + Direction.Unit * WallResult.Distance
				Camera.CFrame = CFrame.new(NewPos, NewPos + Camera.CFrame.LookVector)
			else
				Camera.CFrame = Camera.CFrame * TPOffset
			end
		end

		for _, Part in Globals.ThirdPersonParts do
			Part.Transparency = Toggles.ThirdPersonToggle.Value and 0 or 1
			Part.LocalTransparencyModifier = Toggles.ThirdPersonToggle.Value and 0 or 1
		end

		if Globals.SpectateEntity and Toggles.AutoClosetToggle.Value and Toggles.SpectateEntityToggle.Value then
			local Entity = Globals.SpectateEntity

			local CamPosition
			if Options.SpecateEntityMode.Value == "Player to Entity" then
				CamPosition = CFrame.lookAt(Character.Head.Position, Entity.PrimaryPart.Position)
			else
				CamPosition = CFrame.lookAt(Entity.PrimaryPart.Position, Character.Head.Position)
			end

			Camera.CFrame = CamPosition
		end

		if Toggles.FOVToggle.Value then
			if Main_Game then
				task.wait()
				Main_Game.fovtarget = Options.FieldOfView.Value
			else
				Camera.FieldOfView = Options.FieldOfView.Value
			end
		end

		if Toggles.RemoveClosetDelay.Value
			and Humanoid.MoveDirection ~= Vector3.zero
			and (CollisionPart.Anchored or RootPart.Anchored)
			and Character:GetAttribute("AnimatingClient") ~= true
			and Character:GetAttribute("Hiding") == true
		then
			RemotesFolder.CamLock:FireServer()
		end

		local ClosestPlayer = { Distance = math.huge, Object = nil }
		for _, Player in Services.Players:GetPlayers() do
			if Player.Character and Player ~= LocalPlayer then
				local Root = Player.Character:FindFirstChild("HumanoidRootPart")
				if Root then
					local D = (Camera.CFrame.Position - Root.Position).Magnitude
					if D < ClosestPlayer.Distance then
						ClosestPlayer.Distance = D
						ClosestPlayer.Object = Player
					end
				end
			end
		end
		if ClosestPlayer.Object and LocalPlayer:GetAttribute("Alive") ~= true then
			LocalPlayer:SetAttribute("CurrentRoom", ClosestPlayer.Object:GetAttribute("CurrentRoom"))
		end
	end)

	task.wait(1)
	if Toggles.PositionSpoof.Value and Floor ~= "Fools" and Floor ~= "OldHotel" then
		RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
		Humanoid.HipHeight = 0.05
		RemotesFolder.Crouch:FireServer(true, true)
	end

	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam and Toggles.RemoveJamminMusic.Value then
		Jam.Volume = 0
		Globals.JamMuffle.Enabled = false
	end
end

Functions.HandleHidingTransparency = function(Model)
	local Parts = {}
	for _, Part in Model:GetDescendants() do
		if Part:IsA("BasePart") then
			Part:SetAttribute("Transparency_Old", Part.Transparency)
			table.insert(Parts, Part)
		end
		if Part.Name == "HiddenPlayer" then
			local HideConn = Part:GetPropertyChangedSignal("Value"):Connect(function()
				for _, P in Parts do
					if P:GetAttribute("Transparency_Old") then
						Services.TweenService:Create(P, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
							Transparency = (Part.Value == Character and Toggles.TransparentHidingSpotsToggle.Value)
								and Options.TransparentHidingSpotsSlider.Value
								or P:GetAttribute("Transparency_Old")
						}):Play()
					end
				end
			end)
			table.insert(Connections, HideConn)
			Model.Destroying:Once(function()
				HideConn:Disconnect()
				local Pos = table.find(Connections, HideConn)
				if Pos then table.remove(Connections, Pos) end
			end)
		end
	end
end

Functions.HandleObject = function(Object)
	for _, Room in CurrentRooms:GetChildren() do
		if Object:IsDescendantOf(Room) then
			Object:SetAttribute("ParentRoom", tonumber(Room.Name))
			break
		end
		task.wait()
	end

	if Object.Parent == CurrentRooms then
		local FiredampVal = Object:GetAttribute("Firedamp")
		Object:SetAttribute("Firedamp_Old", FiredampVal ~= nil and FiredampVal or false)
		if Toggles.DisableFiredampEffect.Value then
			Object:SetAttribute("Firedamp", false)
		end
	end

	local Name = Object.Name

	if Name == "KeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Door Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "ElectricalKeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Electrical Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "TimerLever" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				Object:SetAttribute("AddTime", Object.TakeTimer.TextLabel.Text == "01:00" and 60 or 30)
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "StairwellLockpickDoor" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Garage Door", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "Mirror" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Mirror", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "StairwellFireAlarm" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fire Alarm", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "ShoppingCart" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Shopping Cart", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "StairwellScrapper" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Scrapper", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "ArchivesPackageDeposit" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Package Deposit", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "Cellar" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Cellar", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "ArchivesFihTank" then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fih Tank", Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == "LiveHintBook" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Hint Book", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LiveBreakerPolePickup" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fuse Breaker", Color = Options.ObjectiveESPColor.Value }, true) end
		for _, Child in Object:GetChildren() do
			if Child.Name == "ActivateEventPrompt" and (Child.MaxActivationDistance == 5 or Child:GetAttribute("MaxActivationDistance_Old") == 5) then
				Child:Destroy()
			end
		end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LibraryHintPaper" or Name == "PickupItem" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Hint Paper", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "MinesAnchor" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:GetAttributeChangedSignal("Activated"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "WaterPump" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object:WaitForChild("Wheel"), Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Wheel").Sound.Played:Once(function()
			Object:SetAttribute("Abysall_Completed", true)

			Functions.RemoveESP(Object.Wheel)
			Functions.BlacklistESP(Object.Wheel)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "CringlePresent" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Present", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("ToolProp").Highlight:Destroy()
		table.insert(Objects.Objectives, Object)
	elseif Name == "LeverForGate" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "VineGuillotine" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Lever:WaitForChild("ActivateEventPrompt"):GetAttributeChangedSignal("Interactions"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "MandrakeLive" then
		if Toggles.ObjectiveESPToggle.Value and Options.EntityESPOptions.Value["Mandrake Hole"] then Functions.AddESP({ Object = Object.Hole, Text = "Mandrake Hole", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object.Hole)
	elseif Name == "MinesGenerator" then
		task.spawn(function()
			task.wait(0.75)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Lever").Sound.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "FuseObtain" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator Fuse", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Hitbox").FuseModel:GetPropertyChangedSignal("LocalTransparencyModifier"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "MinesGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("MinesGate").Main.SoundOpen.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "GardenGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("GardenGate").Collision.Sound.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "Ladder" then
		if Toggles.LadderESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true) end
		table.insert(Objects.Ladders, Object)
	elseif Name == "Door" and Object.Parent and tonumber(Object.Parent.Name) then
		local DoorParts = {}
		for _, Child in Object:GetChildren() do
			if Child.Name == "Door" and Child:IsA("BasePart") then
				table.insert(DoorParts, Child)
			end
		end

		if #DoorParts == 2 then
			local HighlightModel = Instance.new("Model", Object)
			HighlightModel.Name = "HighlightModel"
			Instance.new("Humanoid", HighlightModel).Name = "HighlightHumanoid"
			HighlightModel:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))

			for _, DoorPart in DoorParts do
				local HP = Instance.new("Part", HighlightModel)
				HP.Transparency = 0.999
				HP.Size = DoorPart.Size
				HP.CanCollide = false
				HP.CFrame = DoorPart.CFrame
				HP.Name = "HighlightPart"
				HP.Material = Enum.Material.Plastic
				HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
				local W = Instance.new("WeldConstraint", HP)
				W.Part0 = HP W.Part1 = DoorPart W.Enabled = true
			end
			table.insert(Objects.Doors, HighlightModel)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HighlightModel, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		else
			local Root = Object:WaitForChild("Door", 9e9)
			local HP = Instance.new("Part", Object)
			HP.Transparency = 0.999
			HP.Size = Root.Size
			HP.CanCollide = false
			HP.CFrame = Root.CFrame
			HP.Name = "HighlightPart"
			HP.Material = Enum.Material.Plastic
			HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
			local W = Instance.new("WeldConstraint", HP)
			W.Part0 = HP W.Part1 = Root W.Enabled = true
			Instance.new("Humanoid", Object).Name = "HighlightHumanoid"
			table.insert(Objects.Doors, HP)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HP, Text = "Door " .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		end

		local LastDoorFire = tick()
		local DoorConn = Services.RunService.Heartbeat:Connect(function()
			if Object:FindFirstChild("Door") and Object:FindFirstChild("ClientOpen") then
				if LocalPlayer:DistanceFromCharacter(Object.Door.Position) < 75
					and tick() - LastDoorFire > 0.1
					and (Toggles.DoorReachToggle.Value or Functions.GetMinecart())
				then
					Object.ClientOpen:FireServer()
					LastDoorFire = tick()
				end
			end
		end)
		Object.Destroying:Once(function()
			DoorConn:Disconnect()
		end)
		Object:WaitForChild("Door"):WaitForChild("Open").Played:Once(function()
			DoorConn:Disconnect()
		end)
		table.insert(Connections, DoorConn)

	elseif Name == "PathLights" then
		local ObjectsToHighlight = {}
		local PLConn = Object.ChildAdded:Connect(function(Child)
			table.insert(ObjectsToHighlight, Child)
		end)
		for _, Child in Object:GetChildren() do
			table.insert(ObjectsToHighlight, Child)
		end

		local function CreateSeekNode(Light)
			if Light.Name ~= "SeekGuidingLight" or Light:GetAttribute("Highlighted") then return end
			Light:SetAttribute("Highlighted", true)

			local NewNode = Instance.new("Part")
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.CFrame = Light.CFrame
			NewNode.CanCollide = false
			NewNode.Name = "SeekLightNode"

			local PrevNode2 = PreviousNode or NewNode
			PreviousNode = NewNode

			local Beam = Instance.new("Beam")
			Beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Options.ShowSeekPathColor.Value), ColorSequenceKeypoint.new(1, Options.ShowSeekPathColor.Value) })
			Beam.FaceCamera = true
			Beam.Width0 = 0.2
			Beam.Width1 = 0.2
			Beam.Brightness = 10
			Beam.LightInfluence = 0
			Beam.LightEmission = 0
			Beam.Enabled = true
			local Vis = Toggles.ShowSeekPathToggle.Value and 0 or 1
			Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
			Beam.Parent = Globals.SeekNodesFolder
			local A0 = Instance.new("Attachment", NewNode)
			local A1 = Instance.new("Attachment", PrevNode2)
			Beam.Attachment0 = A0
			Beam.Attachment1 = A1
			table.insert(Objects.SeekHighlights, Beam)
			Light:Destroy()
		end

		task.spawn(function()
			while task.wait() do
				local Light = table.remove(ObjectsToHighlight, 1)
				if Light then CreateSeekNode(Light) end
			end
		end)

		table.insert(Connections, PLConn)
		table.insert(Objects.PathLights, Object)
		Object.Destroying:Once(function() PLConn:Disconnect() end)
	elseif Name == "SeekMovingNewClone" then
		local Connection = Object.Destroying:Connect(function()
			for _, Folder in pairs(Objects.PathLights) do
				Folder:ClearAllChildren()
			end
			Globals.SeekNodesFolder:ClearAllChildren()
		end)
		table.insert(Connections, Connection)
	elseif Name == "Bridge" then
		for _, Child in Object:GetChildren() do
			if Child.Name == "PlayerBarrier" and Child.Size.Y == 2.75 and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
				local NewBridge = Child:Clone()
				NewBridge.CFrame = NewBridge.CFrame * CFrame.new(0, 0, -5)
				NewBridge.Name = Abysall.ESPLibrary:GenerateRandomString()
				NewBridge.Size = Vector3.new(NewBridge.Size.X, NewBridge.Size.Y, 11)
				NewBridge.Parent = Object
				NewBridge.CanCollide = Toggles.BypassSeekObstructions.Value
				NewBridge.Color = Color3.fromRGB(0, 255, 255)
				NewBridge.Transparency = Toggles.BypassSeekObstructions.Value and 0 or 1
				NewBridge.Material = Enum.Material.ForceField
				table.insert(Objects.SeekBridges, NewBridge)
			end
			task.wait()
		end
    elseif Name == "MinecartRig" then
        Globals.Minecart = Object
	elseif Name == "RunnerNodes" then
		local function IsBehind(Part1, Part2)
			local P1 = (Part1.CFrame + Part1.CFrame.LookVector).Position
			local P2 = (Part1.CFrame + Part1.CFrame.LookVector * -1).Position
			return (P1 - Part2.Position).Magnitude > (P2 - Part2.Position).Magnitude
		end
		local function GetDirection(Part1, Part2)
			local RightDist = Part1.CFrame.RightVector:Dot(Part1.Position - Part2.Position)
			if RightDist > 0.5    then return IsBehind(Part1, Part2) and "Right" or "Left" end
			if RightDist < -0.5   then return IsBehind(Part1, Part2) and "Left" or "Right" end
			return "Straight"
		end
		local function GetClosestNode(Node)
			local Best, BestDist = nil, math.huge
			local NodeID2 = tonumber(Node.Name:split("MinecartNode")[2])
			for _, OtherNode in Object:GetChildren() do
				local OtherID = tonumber(OtherNode.Name:split("MinecartNode")[2])
				if OtherNode ~= Node and OtherID and NodeID2 and OtherID > NodeID2 then
					local D = (Node.Position - OtherNode.Position).Magnitude
					if D < BestDist and OtherNode:GetAttribute("DistanceBlacklist") ~= true then
						BestDist = D Best = OtherNode
					end
				end
			end
			return Best
		end

		for _, Node in Object:GetChildren() do
			local NodeID = tonumber(Node.Name:split("MinecartNode")[2])
			if Node:GetAttribute("DeathType") then Node:SetAttribute("DistanceBlacklist", true) end
			for I = 1, 20 do
				local NextNode = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID + I)
				if NextNode and NextNode:GetAttribute("DeathType") ~= nil then
					Node:SetAttribute("DistanceBlacklist", true)
				end
			end
			local PrevNode3 = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID - 1)
			if PrevNode3 and PrevNode3:GetAttribute("ForceConnect") then
				Node:SetAttribute("DistanceBlacklist", nil)
			end
			task.wait()
		end

		for _, Node in Object:GetChildren() do
			if Node:GetAttribute("ForceConnect") then
				local NextNode = GetClosestNode(Node)
				if NextNode then
					Node:SetAttribute("Turn", GetDirection(Node, NextNode))
					table.insert(Objects.SeekNodes, Node)
				end
			end
			task.wait()
		end

	elseif Name == "EyestalkEndCutscene" then
		Object.Name = "_EyestalkEndCutscene"
	elseif Name == "DuckBoard" then
		table.insert(Objects.SeekDuckBoards, Object)
	elseif HidingSpotLabels[Name] or string.find(string.lower(Name), "hidingspot") then
		local Label = HidingSpotLabels[Name] or (string.find(string.lower(Name), "hidingspot") and "Hiding Spot" or nil)
		if Label and Toggles.HidingSpotESPToggle.Value then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true) end
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Object:FindFirstChild("HidingPrompt") or Object:FindFirstChild("HidePrompt") then
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Name == "Lava" then
		if Toggles.BypassKillbricks.Value then Object.CanTouch = false end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ScaryWall" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekingWall.Value
				Part.CanCollide = not Toggles.BypassSeekingWall.Value

                local Connection1 = Part:GetPropertyChangedSignal("CanTouch"):Connect(function()
                    if Part.CanTouch == Toggles.BypassSeekingWall.Value then
                        Part.CanTouch = not Toggles.BypassSeekingWall.Value
                    end
                end)
                local Connection2 = Part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                    if Part.CanCollide == Toggles.BypassSeekingWall.Value then
                        Part.CanCollide = not Toggles.BypassSeekingWall.Value
                    end
                end)

                table.insert(Connections, Connection1)
                table.insert(Connections, Connection2)
            end
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ChestBox" or Name == "ChestBoxLocked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Chest" or "Chest", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolbox" or Name == "Toolbox_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Chest_Vine" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Vine Chest", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolshed_Small" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Toolshed", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "Locker_Small_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Locked Item Locker", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == "MouseHole" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Mouse", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif ItemNames[Name] and Object:FindFirstChild("ModulePrompt") then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = ItemNames[Name], Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil) end
		if Name == "LotusHolder" or Name == "LotusPetalPickup" then
			Object.Handle:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				Abysall.ESPLibrary:RemoveESP(Object)
				Functions.BlacklistESP(Object)
			end)
		end

		if Toggles.NotifyItemsToggle.Value and Options.NotifyItemList.Value[ItemNames[Name]] and Object.Parent.Name ~= "Drops" then
			if Toggles.NotifyItemsShowDistance.Value then
				Functions.Notify({ Title = "Item '" .. ItemNames[Name] .. "' has spawned.", Body = "It is '" .. math.round(LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)) .. "' studs away from you." })
			else
				Functions.Notify({ Title = "Item '" .. ItemNames[Name] .. "' has spawned."})
			end
		end

		table.insert(Objects.Items, Object)
	elseif Name == "Green_Herb" then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Green Herb", Color = Options.ItemESPColor.Value }, true) end
		table.insert(Objects.Items, Object)
	elseif Name == "GoldPile" and Object:GetAttribute("GoldValue") then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "StardustPickup" then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Stardust Pile", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "GiggleCeiling" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Giggle"] then Functions.AddESP({ Object = Object, Text = "Giggle", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.BypassGiggle.Value then Object:WaitForChild("Hitbox").CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "GloomPile" then
		if Toggles.BypassGloombatEggs.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = false
				end
			end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = false end
		end)

		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Gloombat Eggs"] then
			Functions.AddESP({ Object = Object, Text = "Gloombat Eggs", Color = Options.EntityESPColor.Value })
		end

		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == "TriggerEventCollision" and Functions.CheckCompatability({"firetouchinterest"}) then
		if (Floor == "Fools" or Floor == "OldHotel") and Toggles.RemoveSeekTrigger.Value then
			task.spawn(function()
				while Object:IsDescendantOf(game) do
					for _, Part in Object:GetChildren() do
						if Part:IsA("BasePart") then
							Abysall.Environment.firetouchinterest(RootPart, Part, 0)
							task.wait()
							Abysall.Environment.firetouchinterest(RootPart, Part, 1)
						end
					end
					task.wait()
				end
			end)
		end
		table.insert(Objects.EventTriggers, Object)
	elseif Name == "DoorFake" or Name == "FakeDoor" then
		if Object.Parent and Object:FindFirstChild("Hidden") then
			if Toggles.BypassDupe.Value then
				Object:WaitForChild("Hidden").CanTouch = false
				local Lock = Object:FindFirstChild("Lock")
				if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = false end
			end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Dupe"] then
				Functions.AddESP({ Object = Object, Text = "Dupe", Color = Options.EntityESPColor.Value }, true)
			end
			table.insert(Objects.Entities, Object)
		end
	elseif Name == "SideroomSpace" then
		if Toggles.BypassVacuum.Value then
			Object:WaitForChild("Collision").CanCollide = true
			Object:WaitForChild("Collision").CanTouch = false
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Snare" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Snare"] then Functions.AddESP({ Object = Object, Text = "Snare", Color = Options.EntityESPColor.Value }, true) end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end)
		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)

		if Object:FindFirstChild("Snare") then
			Object:WaitForChild("Snare"):WaitForChild("Roots").Transparency = 1
			Object:WaitForChild("Snare"):WaitForChild("SnareBase").Transparency = 1
		end
		if Object:FindFirstChild("Void") then
			Object.Void.Transparency = 0
			Object.Void.Color = Color3.fromRGB(76, 67, 55)
		end
	elseif Name == "Seek_Arm" or Name == "ChandelierObstruction" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekObstructions.Value
				table.insert(Objects.SeekObstructions, Part)
			end
		end
	elseif Name == "SeekFloodline" then
		Object.CanCollide = Toggles.BypassSeekObstructions.Value
		local FloodConn = Object:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if Object.CanCollide ~= Toggles.BypassSeekObstructions.Value then
				Object.CanCollide = Toggles.BypassSeekObstructions.Value
			end
		end)
		Object.Destroying:Once(function() FloodConn:Disconnect() end)
		table.insert(Objects.SeekObstructions, Object)
	elseif Object:GetAttribute("RawName") and Object:GetAttribute("RawName"):find("Halt") or Object:GetAttribute("Shade") == true then
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Halt"] then
			Functions.Notify({ Title = "Entity 'Halt' will spawn in the next room.", Image = EntityIcons["Halt"] })
			if Toggles.EntityChatToggle.Value then Functions.SendChat("Halt next room!") end
		end
		local HaltLogConn
		HaltLogConn = Services.LogService.MessageOut:Connect(function(Message)
			if Message == "client teleporting" then
				if Globals.AnticheatDisabled then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
				end
				HaltLogConn:Disconnect()
			end
		end)
	elseif Name == "BananaPeel" then
		if Toggles.BypassBanana.Value then Object.CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "JeffTheKiller" then
		if Toggles.BypassJeff.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanCollide = false Part.CanTouch = false end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	elseif Name == "GrumbleRig" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Grumble"] then Functions.AddESP({ Object = Object, Text = "Grumble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "LiveEntityBramble" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Bramble"] then Functions.AddESP({ Object = Object, Text = "Bramble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "Groundskeeper" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Groundskeeper"] then Functions.AddESP({ Object = Object, Text = "Groundskeeper", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Groundskeeper"] then
			local ED = Entities["Groundskeeper"]
			Functions.Notify({ Title = ED.NotifyMessage.Title, Body = ED.NotifyMessage.Body, Image = EntityIcons["Groundskeeper"] })
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = false
			end
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Figure"] then Functions.AddESP({ Object = Object, Text = "Figure", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
		if Toggles.RemoveFigure.Value and Functions.CheckCompatability({"isnetworkowner"}) then
			if Floor == "Mines" then
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						task.spawn(function()
							if Abysall.Environment.isnetworkowner(Part) then
								Part.Position = Vector3.new(-49999, -49999, -49999)
							end
						end)
					end
				end
			elseif Floor == "OldHotel" or Floor == "Fools" then
				CurrentRooms.ChildAdded:Wait()
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CanCollide = false
						task.spawn(function()
							while Abysall.Environment.isnetworkowner(Part) do
								Part.Position = Vector3.new(math.random(-29999,29999), math.random(-29999,29999), math.random(-29999,29999))
								task.wait()
							end
						end)
					end
				end
			end
		end
	elseif (Name == "ThingToOpen" or Name == "MovingDoor") and (Floor == "Fools" or Floor == "OldHotel")
		or Name == "Wax_Door" and Floor == "Fools"
	then
		Object:SetAttribute("OriginalPosition", Object:GetPivot())
		local ToggleMap = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
		if ToggleMap[Name] and Toggles[ToggleMap[Name]].Value then
			Object:PivotTo(CFrame.new(-10000, -10000, -10000))
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ElevatorBreaker" then
		if Toggles.AutoBreakerBox.Value and not Globals.BreakerBoxNotified then
			Functions.Notify({ Title = "Interact with the breaker box.", Body = "It will be automatically solved." })
			Globals.BreakerBoxNotified = true
		end
		Connections.BreakerConnection = Object:WaitForChild("SurfaceGui").Frame.Code:GetPropertyChangedSignal("Text"):Connect(function()
			if Toggles.AutoBreakerBox.Value then
				if not Globals.BreakerBoxStartNotified and (Floor == "Fools" or Floor == "OldHotel") then
					Functions.Notify({ Title = "Attempting to solve the breaker box.", Body = "Please wait." })
					Globals.BreakerBoxStartNotified = true
				end
				RemotesFolder.EBF:FireServer()
			end
			Globals.BreakerBoxInteracted = true
		end)
	elseif Name == "ElevatorCar" then
		local ElevConn = Object.DescendantAdded:Connect(function(Desc)
			if Toggles.AutoBreakerBox.Value and Desc.Name == "TouchInterest" and not Globals.BreakerBoxFinishedNotified then
				Functions.Notify({ Title = "Successfully solved the breaker box.", Body = "Try going to the elevator!" })
				Globals.BreakerBoxFinishedNotified = true
			end
		end)
		Object.Destroying:Once(function() ElevConn:Disconnect() end)
	elseif Object.ClassName == "ProximityPrompt" and not Object:GetAttribute("FakePrompt") then
		if Object:HasTag("DisableWhenEnabledOnClient") then Object:RemoveTag("DisableWhenEnabledOnClient") end

		Object:SetAttribute("HoldDuration_Old", Object.HoldDuration)
		Object:SetAttribute("RequiresLineOfSight_Old", Object.RequiresLineOfSight)
		Object:SetAttribute("MaxActivationDistance_Old", Object.MaxActivationDistance)

		if Toggles.InstantPrompts.Value    then Object.HoldDuration = 0 end
		if Toggles.PromptClip.Value        then Object.RequiresLineOfSight = false end
		Object.MaxActivationDistance = Object:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

		local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }

		if Functions.CheckCompatability({"fireproximityprompt"}) and Floor ~= "OldHotel" and Floor ~= "Fools" then
			local IsLockPrompt = LockPromptNames[Object.Name]
				or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
				or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")

			if IsLockPrompt then
				local FakePrompt = Object:Clone()
				FakePrompt:SetAttribute("FakePrompt", true)
				task.wait()
				FakePrompt.Parent = Object.Parent

				FakePrompt:SetAttribute("HoldDuration_Old", Object:GetAttribute("HoldDuration_Old"))
				FakePrompt:SetAttribute("RequiresLineOfSight_Old", Object:GetAttribute("RequiresLineOfSight_Old"))
				FakePrompt:SetAttribute("MaxActivationDistance_Old", Object:GetAttribute("MaxActivationDistance_Old"))

				FakePrompt.HoldDuration = Object.HoldDuration
				FakePrompt.RequiresLineOfSight = Object.RequiresLineOfSight
				FakePrompt.MaxActivationDistance = Object.MaxActivationDistance

				if Toggles.InstantPrompts.Value    then FakePrompt.HoldDuration = 0 end
				if Toggles.PromptClip.Value        then FakePrompt.RequiresLineOfSight = false end
				FakePrompt.MaxActivationDistance = FakePrompt:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

				FakePrompts[FakePrompt] = Object
				pcall(function() Object.Parent = Globals.PromptContainer end)

				local FPEnabledConn = Object:GetPropertyChangedSignal("Enabled"):Connect(function()
					FakePrompt.Enabled = Object.Enabled
				end)
				Object:GetPropertyChangedSignal("ActionText"):Once(function()
					Object.Parent = FakePrompt.Parent
					FakePrompt:Destroy()
					FPEnabledConn:Disconnect()
				end)
				Object.Destroying:Once(function()
					FakePrompt:Destroy()
					FPEnabledConn:Disconnect()
				end)
				table.insert(Connections, FPEnabledConn)
				table.insert(Objects.Prompts, FakePrompt)

				FakePrompt.Enabled = false
				task.wait()
				FakePrompt.Enabled = Object.Enabled
			end
		end
		table.insert(Objects.Prompts, Object)
	elseif Name == "Padlock" then
		local PadlockConn = Services.RunService.Heartbeat:Connect(function()
			if Object.PrimaryPart then
				local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
				if Toggles.AutoUnlockPadlockToggle.Value then
					local Code = Functions.GetLibraryCode()
					if Code and tonumber(Code) and Distance < Options.AutoUnlockPadlockSlider.Value then
						RemotesFolder.PL:FireServer(Code)
					end
				end
				if Toggles.AutoLibraryGuessCode.Value and LatestRoom.Value == 50 then
					local Code = Functions.GetRandomCode()
					if Code then RemotesFolder.PL:FireServer(Code) end
				end
			end
		end)
		Object.Destroying:Once(function()
			PadlockConn:Disconnect()
		end)
	end
end

Connections.PromptAnimationFixer1 = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end
	local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local AnimateToolNames = { "Lockpick","Shears","SkeletonKey","Key","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end
	
	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation then
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimation:Stop()
		Globals.UseAnimation:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end
end)

Globals.ObjectQueue = {}
local AllowedInstances = {
	Lava=true, GoldPile=true, KeyObtain=true, Drakobloxxer=true, FuseObtain=true,
	MinesGenerator=true, JeffTheKiller=true, Snare=true, FakeDoor=true, DoorFake=true, SideroomSpace=true,
	ChestBox=true, ChestBoxLocked=true, Chest_Vine=true, Locker_Small_Locked=true, Toolbox=true,
	Toolbox_Locked=true, Wardrobe=true, ["Wardrobe-FOOLS26"]=true, Toolshed=true, Toolshed_Small=true,
	Bed=true, MinesAnchor=true, Double_Bed=true, RetroWardrobe=true, Backdoor_Wardrobe=true,
	Rooms_Locker=true, Rooms_Locker_Fridge=true, Locker_Large=true, FigureRig=true, FigureRagdoll=true,
	TimerLever=true, Lever=true, Seek_Arm=true, ChandelierObstruction=true, ScaryWall=true, Ladder=true,
	CircularVent=true, Dumpster=true, SquareGrate=true, TriggerEventCollision=true, GrumbleRig=true,
	GiggleCeiling=true, MinesGateButton=true, ElectricalKeyObtain=true, LibraryHintPaper=true,
	WaterPump=true, CringlePresent=true, Wheel=true, PickupItem=true, LiveHintBook=true,
	LiveBreakerPolePickup=true, LeverForGate=true, GloomPile=true, SeekFloodline=true, Door=true,
	Green_Herb=true, Bridge=true, MouseHole=true, BananaPeel=true, NannerPeel=true, PowerupPad=true,
	IndustrialGate=true, CollisionFloor=true, ElevatorCar=true, Wax_Door=true, ThingToOpen=true,
	MovingDoor=true, StardustPickup=true, Hole=true, Groundskeeper=true, MandrakeLive=true,
	GardenGateButton=true, LotusPetalPickup=true, VineGuillotine=true, LiveEntityBramble=true, ArchivesFihTank=true,
	RiftSpawn=true, ElevatorBreaker=true, RunnerNodes=true, PathLights=true, DuckBoard=true,
	Padlock=true, EyestalkEndCutscene=true, MinecartRig=true, SeekMovingNewClone=true, Cellar=true, ArchivesPackageDeposit=true, StairwellScrapper=true,
	StairwellFireAlarm=true, ShoppingCart=true, Mirror=true, StairwellLockpickDoor=true
}

Functions.QueueObject = function(Object)
	if TimeShowerClone and Object:IsDescendantOf(TimeShowerClone) then
		return
	end
	local IsHidingSpot = typeof(Object.Name) == "string" and string.find(string.lower(Object.Name), "hidingspot")
	if not AllowedInstances[Object.Name] and not IsHidingSpot and Object.ClassName ~= "ProximityPrompt" and Object.Parent ~= CurrentRooms and not ItemNames[Object.Name] then
		return
	end
	table.insert(Globals.ObjectQueue, Object)
end

Globals.QueueDone = true
Connections.QueueConnection = Services.RunService.RenderStepped:Connect(function()
	local Object = table.remove(Globals.ObjectQueue, 1)
	if Object then
		Functions.HandleObject(Object)
	end
end)

for _, Object in Services.Workspace:GetDescendants() do
	task.spawn(function() Functions.QueueObject(Object) end)
end

Connections.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
	Functions.QueueObject(Object)
end)

for _, Player in Services.Players:GetPlayers() do
	if Player ~= LocalPlayer then
		if Player.Character and Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
		local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
			if Toggles.PlayerESPToggle.Value then
				Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			end
		end)
		local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
			if Player:GetAttribute("Alive") ~= true and Player.Character then
				Functions.RemoveESP(Player.Character)
			end
		end)
		table.insert(Connections, CharConn)
		table.insert(Connections, DeadConn)
		Player.Destroying:Once(function()
			CharConn:Disconnect()
			DeadConn:Disconnect()
		end)
	end
end

Connections.PlayerHandler = Services.Players.PlayerAdded:Connect(function(Player)
	if Player == LocalPlayer then return end
	if Player.Character and Toggles.PlayerESPToggle.Value then
		Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
	end
	local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
		if Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
	end)
	local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
		if Player:GetAttribute("Alive") ~= true and Player.Character then
			Functions.RemoveESP(Player.Character)
		end
	end)
	table.insert(Connections, CharConn)
	table.insert(Connections, DeadConn)
	Player.Destroying:Once(function()
		CharConn:Disconnect()
		DeadConn:Disconnect()
	end)
end)

local PromptsToFire = {}
local PromptCooldown = {}

Functions.FirePrompt      = Abysall.Environment.fireproximityprompt
Functions.ForceFirePrompt = Abysall.Environment.fireproximityprompt

if not Functions.FirePrompt then
	Functions.FirePrompt = function(Prompt)
		if not Prompt:IsA("ProximityPrompt") or PromptCooldown[Prompt] or table.find(PromptsToFire, Prompt) or not Camera then return end
		table.insert(PromptsToFire, Prompt)
	end
	Functions.ForceFirePrompt = Functions.FirePrompt

	task.spawn(function()
		while task.wait() do
			local Prompt = table.remove(PromptsToFire, 1)
			if not Prompt then continue end
			PromptCooldown[Prompt] = true

			local OldDist   = Prompt.MaxActivationDistance
			local OldEnable = Prompt.Enabled
			local OldParent = Prompt.Parent
			local OldHold   = Prompt.HoldDuration
			local OldLOS    = Prompt.RequiresLineOfSight

			Prompt.MaxActivationDistance = 99999
			Prompt.Enabled = true
			Prompt.HoldDuration = 0
			Prompt.RequiresLineOfSight = false

			local TempPart = Instance.new("Part")
			TempPart.Parent = Services.Workspace
			TempPart.CanCollide = false TempPart.CanQuery = false TempPart.CanTouch = false
			TempPart.Anchored = true TempPart.Transparency = 1
			TempPart.Size = Vector3.new(0.001, 0.001, 0.001)
			TempPart.Position = Camera.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.1)).Position

			if not Prompt or not OldParent then
				TempPart:Destroy()
				PromptCooldown[Prompt] = nil
				continue
			end

			pcall(function() Prompt.Parent = TempPart end)

			local Shown, Fired = false, false

			local ShownConn = Services.ProximityPromptService.PromptShown:Connect(function(P)
				if P == Prompt then Shown = true end
			end)
			local FiredConn = Prompt.Triggered:Connect(function() Fired = true end)

			local T1 = 0
			while not Shown and T1 < 5 do T1 += 1 task.wait() end

			local T2 = 0
			while not Fired and T2 < 5 do
				Prompt:InputHoldBegin()
				Prompt:InputHoldEnd()
				T2 += 1 task.wait()
			end

			Prompt.MaxActivationDistance = OldDist
			Prompt.Enabled = OldEnable
			Prompt.HoldDuration = OldHold
			Prompt.RequiresLineOfSight = OldLOS
			pcall(function() Prompt.Parent = OldParent end)
			task.wait()
			PromptCooldown[Prompt] = nil
			TempPart:Destroy()
			ShownConn:Disconnect()
			FiredConn:Disconnect()
		end
	end)
end

local AutoInteractBlacklist = {
	HidePrompt=true, RiftPrompt=true, StarRiftPrompt=true, InteractPrompt=true, ClimbPrompt=true,
	DonatePrompt=true, DialoguePrompt=true, RevivePrompt=true, EnterPrompt=true, AnimatePrompt=true,
	ToolEventPrompt=true, Prompt=true, PropPrompt=true
}

local TriggerDebounce = false

local function GetHidingSpotModel(Prompt)
	if not Prompt or not Prompt.Parent then return false end
	local Model = Prompt.Parent
	while Model and not Model:IsA("Model") do
		Model = Model.Parent
	end
	if not Model then return nil end

	local Name = string.lower(Model.Name)
	if not string.find(Name, "hidingspot") and not string.find(Name, "hiding_spot") then
		return nil
	end
	return Model
end

local function HasHidePrompt(Model)
	return Model and (Model:FindFirstChild("HidePrompt") or Model:FindFirstChild("HidingPrompt")) ~= nil
end

local function IsHidingSpotPrompt(Prompt)
	if not Prompt or not Prompt.Parent then return false end
	if Prompt.Name ~= "HidePrompt" and Prompt.Name ~= "HidingPrompt" then return false end
	return HasHidePrompt(GetHidingSpotModel(Prompt))
end

Functions.TriggerPrompt = function(Prompt)
	if not Prompt or not Prompt.Parent then return end
	if Character:GetAttribute("Hiding") == true then return end
	local HidingSpot = GetHidingSpotModel(Prompt)
	if HidingSpot and Prompt.Name ~= "InteractPrompt" then return end
	local IsHidingSpotInteractPrompt = HidingSpot and Prompt.Name == "InteractPrompt"
	if AutoInteractBlacklist[Prompt.Name] and not IsHidingSpotPrompt(Prompt) and not IsHidingSpotInteractPrompt then return end
	if (Prompt.Name == "HidePrompt" or Prompt.Name == "HidingPrompt") and not IsHidingSpotPrompt(Prompt) then return end
	if (Prompt.Name == "HidePrompt" or Prompt.Name == "HidingPrompt" or IsHidingSpotPrompt(Prompt)) then
		if not Toggles.AutoClosetToggle.Value then return end
		local Entity = Functions.GetNearestEntity(true, Options.AutoClosetEntityList.Value)
		if not Entity then return end
		local EntityDistance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if EntityDistance > (EntityDistances[Entity.Name] or 150) then return end
	end
	if TriggerDebounce then return end

	local ParentItem = Functions.HasItem(Prompt.Parent.Name)
	if ParentItem and ParentItem:GetAttribute("Durability") and ParentItem:GetAttribute("DurabilityMax")
		and ParentItem:GetAttribute("Durability") >= ParentItem:GetAttribute("DurabilityMax")
	then return end

	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Prompt.Name]
		or (Prompt.Parent and Prompt.Parent:GetAttribute("Locked") == true)
		or (Prompt.Parent and Prompt.Parent.Parent and Prompt.Parent.Parent.Name == "Locker_Small_Locked" and Prompt.Name == "ActivateEventPrompt")

	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end

	if Prompt.Parent.Name == "GlitchCube" and Options.AutoInteractIgnoreList.Value["Glitch Fragments"] then return end

	if (Prompt.Parent.Name == "KeyObtain" and (Functions.HasItem("Key") or Functions.HasItem("KeyBackdoor")))
		or (Prompt.Parent.Name == "ElectricalKeyObtain" and Functions.HasItem("KeyElectrical"))
	then return end

	if Prompt:IsDescendantOf(Drops) and Options.AutoInteractIgnoreList.Value["Dropped Items"] then return end
	if Prompt.Parent.Name == "TrackLever" then return end
	if Prompt.Name == "ActivateEventPrompt" and (Prompt.ActionText == "Close"
		or Prompt.Parent.Name == "ElevatorBreaker"
		or (Prompt.Parent.Parent and Prompt.Parent.Parent.Name == "IndustrialGate"))
	then return end
	if Prompt.Name == "ActivateEventPrompt" and (Prompt.Parent.Name == "Padlock" or Prompt.Parent.Name == "MinesAnchor") then return end
	if Prompt.Parent.Name == "LeverForGate" and Prompt:GetAttribute("Interactions") then return end
	if Prompt.Parent.Parent and (Prompt.Parent.Parent.Name == "DoorFake" or Prompt.Parent.Parent.Name == "FakeDoor") then return end
	if Prompt.Parent:GetAttribute("JeffShop") and Options.AutoInteractIgnoreList.Value["Jeff Items"] then return end
	if Prompt:GetAttribute("AutoInteractIgnore") then return end
	if Prompt.Name == "PushPrompt" and Options.AutoInteractIgnoreList.Value["Minecarts"] then return end
	if (Prompt.Parent.Name == "GoldPile" or Prompt.Parent.Name == "StardustPickup") and Options.AutoInteractIgnoreList.Value["Currency"] then return end

	if Prompt.Parent.Name == "Bandage" then
		local BPack = Functions.HasItem("BandagePack")
		if Humanoid.Health >= Humanoid.MaxHealth and not BPack then return end
		if BPack and BPack:GetAttribute("Durability") >= BPack:GetAttribute("DurabilityMax") then return end
	end

	if Prompt.Parent.Name == "Battery" then
		local Tool = Character:FindFirstChildOfClass("Tool")
		local BPack = Functions.HasItem("BatteryPack")
		if not Tool and not BPack then return end
		if Tool and Tool:GetAttribute("LightSource") then
			if Tool:GetAttribute("Durability") and Tool:GetAttribute("DurabilityMax")
				and Tool:GetAttribute("Durability") > Tool:GetAttribute("DurabilityMax")
			then return end
		elseif not BPack then
			return
		end
		if BPack and BPack:GetAttribute("Durability") >= BPack:GetAttribute("DurabilityMax") then return end
	end

	if Prompt.Name == "HerbPrompt" then
		local Effects = Globals.MainUI.MainFrame.Healthbar:FindFirstChild("Effects")
		if Effects and Effects.HerbGreenEffect.Visible then return end
	end

	if (Prompt.Parent.Name == "LibraryHintPaper" or Prompt.Parent.Name == "PickupItem") and (Functions.HasItem("LibraryHintPaper") or Functions.HasItem("LibraryHintPaperHard")) then return end
	if Prompt.Parent.Name == "AlarmClock" and Functions.HasItem("AlarmClock") then return end
	if Prompt.Parent.Name == "KeyObtainFake" or Prompt.Parent.Name == "TithingPlate" then return end
	if Prompt.Parent.Name == "StarBottle" then return end
    -- archives
	if Prompt.parent.Name == "ArchivesStorageBox" then return end
	if Prompt.Parent.Name == "Briefcase" then return end
	if Prompt.Name == "SinkPrompt" or Prompt.Parent.Name == "Faucet" then return end
	if Prompt.Parent.Name == "PaperPlanePickup" or Prompt.Parent.Name == "PaperPlane" then return end
	if Prompt.Name == "ManualOpenPrompt" or Prompt.Name == "EntryPrompt" then return end
	if Prompt.Parent.Parent.Name == "ArchivesLargePrinter" then return end
	if Prompt.Name == "TrashcanPrompt" then return end
	if Prompt.Parent.Name == "Keyboard" then return end
	if Prompt.Name == "CartPrompt" or Prompt.Parent.Parent.Name == "ArchivesOfficeChair" then return end
	if Prompt.Parent.Name == "ArchivesTerminal" then return end
	if Prompt.Name == "VendorPrompt" then return end
    if Prompt.Parent.Name == "SeatPart" or Prompt.Name == "SeatPrompt" then return end


	-- Stairwell
	if Prompt.Parent.Name == "StairwellScrapper" then return end
	if Prompt.Name == "PortraitDupePrompt" or Prompt.Parent.Name == "MirrorTool" then return end
	if Prompt.Name == "LaptopPrompt" or Prompt.Parent.Name == "SecretLaptop" then return end
	if Prompt.Parent.Name == "StairwellFireAlarm" or Prompt.Parent.Parent.Name == "StairwellFireAlarm" then return end
	if Prompt.Parent.name == "CobblerFriendly" then return end
	if Prompt.Parent.Name == "StairwellTerminal" then return end
	if Prompt.Parent.Parent.Name == "MeldChord" then return end

	Functions.FirePrompt(Prompt)
	TriggerDebounce = true
	if Floor == "OldHotel" then task.wait() end
	TriggerDebounce = false
end

Globals.LastAutoInteractFire = tick()
Connections.AutoInteract = Services.RunService.Heartbeat:Connect(function()
	local Active = Toggles.AutoInteractToggle.Value or Options.AutoInteractKeybind:GetState()
    if not Active then return end
    if tick() - Globals.LastAutoInteractFire < 1/60 then return end

	for _, Prompt in Objects.Prompts do
        if Prompt:GetAttribute("ParentRoom") and tonumber(Prompt:GetAttribute("ParentRoom")) ~= tonumber(LocalPlayer:GetAttribute("CurrentRoom")) then continue end

		if Prompt.Parent and (Prompt.Parent:IsA("BasePart") or Prompt.Parent:IsA("Model")) then
			local Distance
			if Prompt.Parent:IsA("BasePart") then
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent.Position)
			else
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent:GetPivot().Position)
			end
			if Distance <= Prompt.MaxActivationDistance and Prompt.Enabled or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "LongPushPrompt" or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "BigPropPrompt" then
				task.spawn(Functions.TriggerPrompt, Prompt)
			end
		end
	end
    Globals.LastAutoInteractFire = tick()
end)

Connections.InfiniteItemsHandler = Services.ProximityPromptService.PromptTriggered:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end

	local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local AnimateToolNames = { "Lockpick","Shears","SkeletonKey","Key","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value["Locks"] then return end
		local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
		local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == "CuttableVines" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Chest_Vine" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Cellar" and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
	if Prompt.Parent.Name == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
	if Prompt.Parent.Name == "Lock1" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) or Prompt.Parent.Name == "Lock2" and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
	if Functions.HasItem("Shears", true) and IsLockPrompt and Prompt.Parent.Name ~= "CuttableVines" and Prompt.Parent.Name ~= "Chest_Vine" and Prompt.Parent.Name ~= "Cellar" then return end

	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation and Globals.UseAnimationBreak then
		Globals.UseAnimation:Stop()
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimationBreak:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end

	local AnyTool = Character:FindFirstChildOfClass("Tool")
	local ToolData = AnyTool and ItemNames[AnyTool.Name]
	if AnyTool and ToolData and Toggles.InfiniteItemsToggle.Value and Options.InfiniteItemsList.Value[ToolData] then
		Drops.ChildAdded:Once(function(NewTool)
			local Prompt = NewTool:FindFirstChild("ModulePrompt")
			local RealPrompt = FakePrompts[Object]
			Functions.FirePrompt(Prompt)
			Functions.FirePrompt(RealPrompt)
		end)
		Character.ChildAdded:Once(function(NewTool)
			if NewTool.Name == "Shears" then NewTool:WaitForChild("Handle"):WaitForChild("sound_promptend"):Play() end
		end)
		RemotesFolder.DropItem:FireServer(AnyTool)
	else
		local RealPrompt = FakePrompts[Object]
		Functions.FirePrompt(RealPrompt)
	end
end)

Connections.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(function(Object)
	if Object.Name == "GlitchScreech" then
		Modules.GlitchScreech = Object
		if Toggles.RemoveScreech.Value then Object.Name = "GlitchScreech_Disabled" end
	end
	if Object.Name:find("Jumpscare") and Object:IsA("ModuleScript")
		and not Object.Name:find("Eyestalk") and not Object.Name:find("Groundskeeper") and not Object.Name:find("Monument")
	then
		Object:SetAttribute("OriginalName", Object.Name)
		if Toggles.DisableEntityJumpscares.Value then Object.Name = Object.Name .. "_Disabled" end
		table.insert(Objects.JumpscareModules, Object)
	end
end)

if FloorReplicated:FindFirstChild("DigitalTimer") then
	Connections.HasteTimerConnection = FloorReplicated.DigitalTimer:GetPropertyChangedSignal("Value"):Connect(function()
		if Toggles.NotifyHasteTime.Value then Functions.Caption(Functions.GetHasteTime(), true) end
	end)
end

Connections.FogHandler = Services.Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
	if Services.Lighting.FogEnd ~= 10000000 then
		Globals.OldFog = Services.Lighting.FogEnd
	end
	if Toggles.RemoveCameraFog.Value then
		Services.Lighting.FogEnd = 10000000
	end
end)

Connections.FogHandler2 = Services.Lighting.DescendantAdded:Connect(function(Object)
	if not Object:IsA("Atmosphere") then return end
	Object:SetAttribute("Density_Old", Object.Density)
	if Toggles.RemoveCameraFog.Value then Object.Density = 0 end

	local AtmoConn2 = Object:GetPropertyChangedSignal("Density"):Connect(function()
		if Object.Density ~= 0 then Object:SetAttribute("Density_Old", Object.Density) end
		if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
	end)
	Object.Destroying:Once(function() AtmoConn2:Disconnect() end)
	table.insert(Connections, AtmoConn2)
	table.insert(Globals.FogInstances, Object)
end)

local RusherAliases = { Rush=true, Bash=true, Scribbles=true, DronesStampede=true, Ambush=true, Eyes=true, Lookman=true, Blitz=true, ["A-60"]=true, ["A-120"]=true, AR0xMBUSH=true, ["RNIUSHCG=="]=true, ["Custom Entity"]=true }

local function HandleEntitySpawn(Entity)
	if not Entity or typeof(Entity) ~= "Instance" then return end

	local Model = Entity
	if Entity:IsA("Humanoid") then
		Model = Entity.Parent
	end
	if not Model or not Model:IsA("Model") then return end

	local EntityData = Entities[Model.Name]
	if not EntityData then return end
	if Model:GetAttribute("Abysall_EntityHandled") then return end
	Model:SetAttribute("Abysall_EntityHandled", true)

	while not Model.PrimaryPart do
		for _, Child in Model:GetChildren() do
			if Child:IsA("BasePart") then Model.PrimaryPart = Child end
		end
		if not Model.PrimaryPart then task.wait() end
	end
	task.wait(0.1)

	if not Model.PrimaryPart or LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) >= 10000 then return end

	local Alias = EntityData.Alias
	local RealAlias = Alias
	if Options.EntityList.Value[Alias] and Toggles.NotifyEntities.Value then
		local NotifyTitle = EntityData.NotifyMessage.Title
		local NotifyBody  = EntityData.NotifyMessage.Body
		local NotifyImage = EntityIcons[Model.Name]

		if Model.Name == "RushMoving" and Model.PrimaryPart.Name ~= "RushNew" then
			NotifyTitle = NotifyTitle:gsub("Rush", Model.PrimaryPart.Name)
			NotifyImage = Model.PrimaryPart:WaitForChild("Attachment").ParticleEmitter.Texture
			Alias = Model.PrimaryPart.Name
		end

		Functions.Notify({ Title = NotifyTitle, Body = NotifyBody, Image = NotifyImage, Time = Toggles.NotifyKeepNotifications.Value and Model or nil })

		if Toggles.EntityChatToggle.Value then
			Functions.SendChat(Alias .. " " .. Options.EntityChatMessage.Value)
		end
	end

	if Model.Name ~= "GloombatSwarm" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealAlias] then
			if Model.Name == "MonumentEntity" then
				Functions.AddESP({ Object = Model.Top, Text = Alias, Color = Options.EntityESPColor.Value })
			else
				Functions.AddESP({ Object = Model, Text = Alias, Color = Options.EntityESPColor.Value })
			end
		end
		table.insert(Objects.Entities, Model)
	end

	if RusherAliases[EntityData.Alias] then
		Instance.new("Humanoid", Model).Name = "HighlightHumanoid"
		local Root = Model.PrimaryPart
		if Root then Root.Transparency = 0.999 Root.Material = Enum.Material.Plastic end
	end

	if Model.Name == "Lookman" then
		CurrentRooms.ChildAdded:Wait()
		task.wait(10)
		Model:Destroy()
	end
end

Connections.EntityHandler = Services.Workspace.ChildAdded:Connect(HandleEntitySpawn)
Connections.EntityDescendantHandler = Services.Workspace.DescendantAdded:Connect(function(Descendant)
	local EntityModel = Descendant:IsA("Humanoid") and Descendant.Parent or Descendant
	if EntityModel and EntityModel:IsA("Model") and Entities[EntityModel.Name] then
		task.defer(function()
			HandleEntitySpawn(Descendant)
		end)
	end
end)

local LastClean = tick()
Connections.Cleaner = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastClean <= 0.5 then return end
	LastClean = tick()

	for ArrayName, Array in Objects do
		local I = #Array
		while I >= 1 do
			local Object = Array[I]
			if Object == nil or not Object:IsDescendantOf(Services.Workspace) then
				table.remove(Array, I)
				local Conn = ESPConnections[Object]
				if Conn then
					Conn:Disconnect()
					ESPConnections[Object] = nil
					local Pos = table.find(Connections, Conn)
					if Pos then table.remove(Connections, Pos) end
				end
			end
			I -= 1
		end
	end
end)

local LastPromptFix = tick()
Connections.PromptFixer = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastPromptFix <= 0.5 then return end
	LastPromptFix = tick()
	for _, Prompt in Objects.Prompts do
		if Prompt:HasTag("DisableWhenEnabledOnClient") then
			Prompt:RemoveTag("DisableWhenEnabledOnClient")
		end
	end
end)

if LocalPlayer.Character then
	task.spawn(function() Functions.HandleCharacter(LocalPlayer.Character) end)
end

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	if Connections.MainHandler then
		Connections.MainHandler:Disconnect()
		Connections.MainHandler = nil
	end
	task.wait(0.5)
	Functions.HandleCharacter(NewCharacter)
end)

Library:OnUnload(function()
	StopTimeShower(true)
	for Key, Connection in Connections do
		if type(Key) == "string" then
			pcall(function() Connection:Disconnect() end)
		else
			pcall(function() Key:Disconnect() end)
			pcall(function() Connection:Disconnect() end)
		end
	end

	for _, Object in Objects.Entities do
		if Object.Name == "Snare" or Object.Name == "GiggleCeiling" then
			local Hitbox = Object:FindFirstChild("Hitbox")
			if Hitbox then Hitbox.CanTouch = true end
		end
		if Object.Name == "GloomPile" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = true end
			end
		end
		if Object.Name == "FakeDoor" or Object.Name == "DoorFake" then
			local Hidden = Object:FindFirstChild("Hidden")
			if Hidden then Hidden.CanTouch = true end
			local Lock = Object:FindFirstChild("Lock")
			if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = true end
		end
		if Object.Name == "SideroomSpace" then
			local Coll = Object:FindFirstChild("Collision")
			if Coll then Coll.CanCollide = false Coll.CanTouch = true end
		end
	end

	for _, Object in Objects.SeekBridges do Object:Destroy() end

	for _, Fog in Globals.FogInstances do
		Fog.Density = Fog:GetAttribute("Density_Old")
	end
	Services.Lighting.FogEnd = Globals.OldFog

	local Vignette = Globals.MainUI:FindFirstChild("HideVignette") or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = "rbxassetid://6100076320" end

	local ModuleRestores = {
		Screech = "Screech", Glitch = "Glitch", Shade = "Shade",
		SpiderJumpscare = "SpiderJumpscare", A90 = "A90", Dread = "Dread", Void = "Void"
	}
	for Key, OriginalName in ModuleRestores do
		if Modules[Key] then Modules[Key].Name = OriginalName end
	end

	FakeEvents.Screech:Destroy()
	FakeEvents.Screech_Real.Parent = RemotesFolder
	FakeEvents.Shade:Destroy()
	FakeEvents.Shade_Real.Parent = RemotesFolder

	if FakeEvents.A90_Real then
		FakeEvents.A90:Destroy()
		FakeEvents.A90_Real.Parent = RemotesFolder
	end
	if FakeEvents.Surge_Real then
		FakeEvents.Surge:Destroy()
		FakeEvents.Surge_Real.Parent = RemotesFolder
	end

	Globals.SeekNodesFolder:Destroy()
	Globals.RoomsNodesFolder:Destroy()
	Globals.ManipulateBody:Destroy()

	local OldAmbient = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom"))):GetAttribute("Ambient")
	Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = OldAmbient }):Play()

	for _, Prompt in Objects.Prompts do
		if FakePrompts[Prompt] then
			FakePrompts[Prompt].Parent = Prompt.Parent
			Prompt:Destroy()
		end
		if Prompt.Parent then
			Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old") or Prompt.HoldDuration
			Prompt.RequiresLineOfSight = Prompt:GetAttribute("RequiresLineOfSight_Old") or Prompt.RequiresLineOfSight
			Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") or Prompt.MaxActivationDistance
		end
	end

	Character:SetAttribute("CanJump",  OldJump)
	Character:SetAttribute("CanSlide", OldSlide)

	for _, Object in Services.Workspace:GetDescendants() do
		task.spawn(function() Functions.RemoveESP(Object) end)
	end

	Humanoid.WalkSpeed  = Functions.GetCurrentSpeed()
	Humanoid.JumpPower  = 5
	Humanoid.HipHeight  = 2.367

	local BaseY = 0.18
	Collision.Position          = RootPart.Position + Vector3.new(0, BaseY, 0)
	CollisionPart.Position      = RootPart.Position + Vector3.new(0, BaseY, 0)
	CollisionPartClone.Position = RootPart.Position + Vector3.new(0, BaseY, 0)

	if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
		Character.LowerTorso.Root.C1 = Globals.OriginalC1
	end
	if Collision:FindFirstChild("CollisionCrouch") then
		Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, -0.982, 0)
	end

	CollisionClone:Destroy()
	CollisionPartClone:Destroy()
	Abysall.ESPLibrary:Unload()

	if Main_Game then
		Main_Game.fovtarget   = 70
		Main_Game.spring.Speed = 8
		Main_Game.tooloffset   = Vector3.zero
	end

	if Globals.OriginalGetMoveVector then 
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		Controls.GetMoveVector = Globals.OriginalGetMoveVector
	end

	getgenv().Abysall = nil
	shared.Hastelepasta = false
end)



while not Globals.MainUI do task.wait() end

Abysall.Interface.ApplySettingsTab(Window)
Functions.Notify({ Title = "Successfully loaded in " .. math.floor((tick() - LoadStart) * 1000) / 1000 .. " seconds." , Body = "Press '" .. tostring(Options.MenuKeybind.Value) .. "' to toggle the UI."})


local _BIGTABLE = {
  ["key_0000"] = "门_0000",
  ["key_0001"] = "箱子_0001",
  ["key_0002"] = "物品_0002",
  ["key_0003"] = "房间_0003",
  ["key_0004"] = "钥匙_0004",
  ["key_0005"] = "出口_0005",
  ["key_0006"] = "躲藏_0006",
  ["key_0007"] = "时间_0007",
  ["key_0008"] = "速度_0008",
  ["key_0009"] = "开启_0009",
  ["key_0010"] = "关闭_0010",
  ["key_0011"] = "显示_0011",
  ["key_0012"] = "玩家_0012",
  ["key_0013"] = "开关_0013",
  ["key_0014"] = "距离_0014",
  ["key_0015"] = "自动_0015",
  ["key_0016"] = "飞行_0016",
  ["key_0017"] = "跳跃_0017",
  ["key_0018"] = "滑行_0018",
  ["key_0019"] = "解锁_0019",
  ["key_0020"] = "使用_0020",
  ["key_0021"] = "生成_0021",
  ["key_0022"] = "实体_0022",
  ["key_0023"] = "噪音_0023",
  ["key_0024"] = "冲刺_0024",
  ["key_0025"] = "伏击_0025",
  ["key_0026"] = "眼睛_0026",
  ["key_0027"] = "尖啸_0027",
  ["key_0028"] = "停驻_0028",
  ["key_0029"] = "恐惧_0029",
  ["key_0030"] = "涌浪_0030",
  ["key_0031"] = "闪电_0031",
  ["key_0032"] = "故障_0032",
  ["key_0033"] = "蒂莫西_0033",
  ["key_0034"] = "杰克_0034",
  ["key_0035"] = "影子_0035",
  ["key_0036"] = "搜寻_0036",
  ["key_0037"] = "人脸_0037",
  ["key_0038"] = "陷阱_0038",
  ["key_0039"] = "分身_0039",
  ["key_0040"] = "傻笑_0040",
  ["key_0041"] = "窗户_0041",
  ["key_0042"] = "加速_0042",
  ["key_0043"] = "吱嘎_0043",
  ["key_0044"] = "哥布林_0044",
  ["key_0045"] = "杰夫_0045",
  ["key_0046"] = "鲍勃_0046",
  ["key_0047"] = "门_0047",
  ["key_0048"] = "箱子_0048",
  ["key_0049"] = "物品_0049",
  ["key_0050"] = "房间_0050",
  ["key_0051"] = "钥匙_0051",
  ["key_0052"] = "出口_0052",
  ["key_0053"] = "躲藏_0053",
  ["key_0054"] = "时间_0054",
  ["key_0055"] = "速度_0055",
  ["key_0056"] = "开启_0056",
  ["key_0057"] = "关闭_0057",
  ["key_0058"] = "显示_0058",
  ["key_0059"] = "玩家_0059",
  ["key_0060"] = "开关_0060",
  ["key_0061"] = "距离_0061",
  ["key_0062"] = "自动_0062",
  ["key_0063"] = "飞行_0063",
  ["key_0064"] = "跳跃_0064",
  ["key_0065"] = "滑行_0065",
  ["key_0066"] = "解锁_0066",
  ["key_0067"] = "使用_0067",
  ["key_0068"] = "生成_0068",
  ["key_0069"] = "实体_0069",
  ["key_0070"] = "噪音_0070",
  ["key_0071"] = "冲刺_0071",
  ["key_0072"] = "伏击_0072",
  ["key_0073"] = "眼睛_0073",
  ["key_0074"] = "尖啸_0074",
  ["key_0075"] = "停驻_0075",
  ["key_0076"] = "恐惧_0076",
  ["key_0077"] = "涌浪_0077",
  ["key_0078"] = "闪电_0078",
  ["key_0079"] = "故障_0079",
  ["key_0080"] = "蒂莫西_0080",
  ["key_0081"] = "杰克_0081",
  ["key_0082"] = "影子_0082",
  ["key_0083"] = "搜寻_0083",
  ["key_0084"] = "人脸_0084",
  ["key_0085"] = "陷阱_0085",
  ["key_0086"] = "分身_0086",
  ["key_0087"] = "傻笑_0087",
  ["key_0088"] = "窗户_0088",
  ["key_0089"] = "加速_0089",
  ["key_0090"] = "吱嘎_0090",
  ["key_0091"] = "哥布林_0091",
  ["key_0092"] = "杰夫_0092",
  ["key_0093"] = "鲍勃_0093",
  ["key_0094"] = "门_0094",
  ["key_0095"] = "箱子_0095",
  ["key_0096"] = "物品_0096",
  ["key_0097"] = "房间_0097",
  ["key_0098"] = "钥匙_0098",
  ["key_0099"] = "出口_0099",
  ["key_0100"] = "躲藏_0100",
  ["key_0101"] = "时间_0101",
  ["key_0102"] = "速度_0102",
  ["key_0103"] = "开启_0103",
  ["key_0104"] = "关闭_0104",
  ["key_0105"] = "显示_0105",
  ["key_0106"] = "玩家_0106",
  ["key_0107"] = "开关_0107",
  ["key_0108"] = "距离_0108",
  ["key_0109"] = "自动_0109",
  ["key_0110"] = "飞行_0110",
  ["key_0111"] = "跳跃_0111",
  ["key_0112"] = "滑行_0112",
  ["key_0113"] = "解锁_0113",
  ["key_0114"] = "使用_0114",
  ["key_0115"] = "生成_0115",
  ["key_0116"] = "实体_0116",
  ["key_0117"] = "噪音_0117",
  ["key_0118"] = "冲刺_0118",
  ["key_0119"] = "伏击_0119",
  ["key_0120"] = "眼睛_0120",
  ["key_0121"] = "尖啸_0121",
  ["key_0122"] = "停驻_0122",
  ["key_0123"] = "恐惧_0123",
  ["key_0124"] = "涌浪_0124",
  ["key_0125"] = "闪电_0125",
  ["key_0126"] = "故障_0126",
  ["key_0127"] = "蒂莫西_0127",
  ["key_0128"] = "杰克_0128",
  ["key_0129"] = "影子_0129",
  ["key_0130"] = "搜寻_0130",
  ["key_0131"] = "人脸_0131",
  ["key_0132"] = "陷阱_0132",
  ["key_0133"] = "分身_0133",
  ["key_0134"] = "傻笑_0134",
  ["key_0135"] = "窗户_0135",
  ["key_0136"] = "加速_0136",
  ["key_0137"] = "吱嘎_0137",
  ["key_0138"] = "哥布林_0138",
  ["key_0139"] = "杰夫_0139",
  ["key_0140"] = "鲍勃_0140",
  ["key_0141"] = "门_0141",
  ["key_0142"] = "箱子_0142",
  ["key_0143"] = "物品_0143",
  ["key_0144"] = "房间_0144",
  ["key_0145"] = "钥匙_0145",
  ["key_0146"] = "出口_0146",
  ["key_0147"] = "躲藏_0147",
  ["key_0148"] = "时间_0148",
  ["key_0149"] = "速度_0149",
  ["key_0150"] = "开启_0150",
  ["key_0151"] = "关闭_0151",
  ["key_0152"] = "显示_0152",
  ["key_0153"] = "玩家_0153",
  ["key_0154"] = "开关_0154",
  ["key_0155"] = "距离_0155",
  ["key_0156"] = "自动_0156",
  ["key_0157"] = "飞行_0157",
  ["key_0158"] = "跳跃_0158",
  ["key_0159"] = "滑行_0159",
  ["key_0160"] = "解锁_0160",
  ["key_0161"] = "使用_0161",
  ["key_0162"] = "生成_0162",
  ["key_0163"] = "实体_0163",
  ["key_0164"] = "噪音_0164",
  ["key_0165"] = "冲刺_0165",
  ["key_0166"] = "伏击_0166",
  ["key_0167"] = "眼睛_0167",
  ["key_0168"] = "尖啸_0168",
  ["key_0169"] = "停驻_0169",
  ["key_0170"] = "恐惧_0170",
  ["key_0171"] = "涌浪_0171",
  ["key_0172"] = "闪电_0172",
  ["key_0173"] = "故障_0173",
  ["key_0174"] = "蒂莫西_0174",
  ["key_0175"] = "杰克_0175",
  ["key_0176"] = "影子_0176",
  ["key_0177"] = "搜寻_0177",
  ["key_0178"] = "人脸_0178",
  ["key_0179"] = "陷阱_0179",
  ["key_0180"] = "分身_0180",
  ["key_0181"] = "傻笑_0181",
  ["key_0182"] = "窗户_0182",
  ["key_0183"] = "加速_0183",
  ["key_0184"] = "吱嘎_0184",
  ["key_0185"] = "哥布林_0185",
  ["key_0186"] = "杰夫_0186",
  ["key_0187"] = "鲍勃_0187",
  ["key_0188"] = "门_0188",
  ["key_0189"] = "箱子_0189",
  ["key_0190"] = "物品_0190",
  ["key_0191"] = "房间_0191",
  ["key_0192"] = "钥匙_0192",
  ["key_0193"] = "出口_0193",
  ["key_0194"] = "躲藏_0194",
  ["key_0195"] = "时间_0195",
  ["key_0196"] = "速度_0196",
  ["key_0197"] = "开启_0197",
  ["key_0198"] = "关闭_0198",
  ["key_0199"] = "显示_0199",
  ["key_0200"] = "玩家_0200",
  ["key_0201"] = "开关_0201",
  ["key_0202"] = "距离_0202",
  ["key_0203"] = "自动_0203",
  ["key_0204"] = "飞行_0204",
  ["key_0205"] = "跳跃_0205",
  ["key_0206"] = "滑行_0206",
  ["key_0207"] = "解锁_0207",
  ["key_0208"] = "使用_0208",
  ["key_0209"] = "生成_0209",
  ["key_0210"] = "实体_0210",
  ["key_0211"] = "噪音_0211",
  ["key_0212"] = "冲刺_0212",
  ["key_0213"] = "伏击_0213",
  ["key_0214"] = "眼睛_0214",
  ["key_0215"] = "尖啸_0215",
  ["key_0216"] = "停驻_0216",
  ["key_0217"] = "恐惧_0217",
  ["key_0218"] = "涌浪_0218",
  ["key_0219"] = "闪电_0219",
  ["key_0220"] = "故障_0220",
  ["key_0221"] = "蒂莫西_0221",
  ["key_0222"] = "杰克_0222",
  ["key_0223"] = "影子_0223",
  ["key_0224"] = "搜寻_0224",
  ["key_0225"] = "人脸_0225",
  ["key_0226"] = "陷阱_0226",
  ["key_0227"] = "分身_0227",
  ["key_0228"] = "傻笑_0228",
  ["key_0229"] = "窗户_0229",
  ["key_0230"] = "加速_0230",
  ["key_0231"] = "吱嘎_0231",
  ["key_0232"] = "哥布林_0232",
  ["key_0233"] = "杰夫_0233",
  ["key_0234"] = "鲍勃_0234",
  ["key_0235"] = "门_0235",
  ["key_0236"] = "箱子_0236",
  ["key_0237"] = "物品_0237",
  ["key_0238"] = "房间_0238",
  ["key_0239"] = "钥匙_0239",
  ["key_0240"] = "出口_0240",
  ["key_0241"] = "躲藏_0241",
  ["key_0242"] = "时间_0242",
  ["key_0243"] = "速度_0243",
  ["key_0244"] = "开启_0244",
  ["key_0245"] = "关闭_0245",
  ["key_0246"] = "显示_0246",
  ["key_0247"] = "玩家_0247",
  ["key_0248"] = "开关_0248",
  ["key_0249"] = "距离_0249",
  ["key_0250"] = "自动_0250",
  ["key_0251"] = "飞行_0251",
  ["key_0252"] = "跳跃_0252",
  ["key_0253"] = "滑行_0253",
  ["key_0254"] = "解锁_0254",
  ["key_0255"] = "使用_0255",
  ["key_0256"] = "生成_0256",
  ["key_0257"] = "实体_0257",
  ["key_0258"] = "噪音_0258",
  ["key_0259"] = "冲刺_0259",
  ["key_0260"] = "伏击_0260",
  ["key_0261"] = "眼睛_0261",
  ["key_0262"] = "尖啸_0262",
  ["key_0263"] = "停驻_0263",
  ["key_0264"] = "恐惧_0264",
  ["key_0265"] = "涌浪_0265",
  ["key_0266"] = "闪电_0266",
  ["key_0267"] = "故障_0267",
  ["key_0268"] = "蒂莫西_0268",
  ["key_0269"] = "杰克_0269",
  ["key_0270"] = "影子_0270",
  ["key_0271"] = "搜寻_0271",
  ["key_0272"] = "人脸_0272",
  ["key_0273"] = "陷阱_0273",
  ["key_0274"] = "分身_0274",
  ["key_0275"] = "傻笑_0275",
  ["key_0276"] = "窗户_0276",
  ["key_0277"] = "加速_0277",
  ["key_0278"] = "吱嘎_0278",
  ["key_0279"] = "哥布林_0279",
  ["key_0280"] = "杰夫_0280",
  ["key_0281"] = "鲍勃_0281",
  ["key_0282"] = "门_0282",
  ["key_0283"] = "箱子_0283",
  ["key_0284"] = "物品_0284",
  ["key_0285"] = "房间_0285",
  ["key_0286"] = "钥匙_0286",
  ["key_0287"] = "出口_0287",
  ["key_0288"] = "躲藏_0288",
  ["key_0289"] = "时间_0289",
  ["key_0290"] = "速度_0290",
  ["key_0291"] = "开启_0291",
  ["key_0292"] = "关闭_0292",
  ["key_0293"] = "显示_0293",
  ["key_0294"] = "玩家_0294",
  ["key_0295"] = "开关_0295",
  ["key_0296"] = "距离_0296",
  ["key_0297"] = "自动_0297",
  ["key_0298"] = "飞行_0298",
  ["key_0299"] = "跳跃_0299",
  ["key_0300"] = "滑行_0300",
  ["key_0301"] = "解锁_0301",
  ["key_0302"] = "使用_0302",
  ["key_0303"] = "生成_0303",
  ["key_0304"] = "实体_0304",
  ["key_0305"] = "噪音_0305",
  ["key_0306"] = "冲刺_0306",
  ["key_0307"] = "伏击_0307",
  ["key_0308"] = "眼睛_0308",
  ["key_0309"] = "尖啸_0309",
  ["key_0310"] = "停驻_0310",
  ["key_0311"] = "恐惧_0311",
  ["key_0312"] = "涌浪_0312",
  ["key_0313"] = "闪电_0313",
  ["key_0314"] = "故障_0314",
  ["key_0315"] = "蒂莫西_0315",
  ["key_0316"] = "杰克_0316",
  ["key_0317"] = "影子_0317",
  ["key_0318"] = "搜寻_0318",
  ["key_0319"] = "人脸_0319",
  ["key_0320"] = "陷阱_0320",
  ["key_0321"] = "分身_0321",
  ["key_0322"] = "傻笑_0322",
  ["key_0323"] = "窗户_0323",
  ["key_0324"] = "加速_0324",
  ["key_0325"] = "吱嘎_0325",
  ["key_0326"] = "哥布林_0326",
  ["key_0327"] = "杰夫_0327",
  ["key_0328"] = "鲍勃_0328",
  ["key_0329"] = "门_0329",
  ["key_0330"] = "箱子_0330",
  ["key_0331"] = "物品_0331",
  ["key_0332"] = "房间_0332",
  ["key_0333"] = "钥匙_0333",
  ["key_0334"] = "出口_0334",
  ["key_0335"] = "躲藏_0335",
  ["key_0336"] = "时间_0336",
  ["key_0337"] = "速度_0337",
  ["key_0338"] = "开启_0338",
  ["key_0339"] = "关闭_0339",
  ["key_0340"] = "显示_0340",
  ["key_0341"] = "玩家_0341",
  ["key_0342"] = "开关_0342",
  ["key_0343"] = "距离_0343",
  ["key_0344"] = "自动_0344",
  ["key_0345"] = "飞行_0345",
  ["key_0346"] = "跳跃_0346",
  ["key_0347"] = "滑行_0347",
  ["key_0348"] = "解锁_0348",
  ["key_0349"] = "使用_0349",
  ["key_0350"] = "生成_0350",
  ["key_0351"] = "实体_0351",
  ["key_0352"] = "噪音_0352",
  ["key_0353"] = "冲刺_0353",
  ["key_0354"] = "伏击_0354",
  ["key_0355"] = "眼睛_0355",
  ["key_0356"] = "尖啸_0356",
  ["key_0357"] = "停驻_0357",
  ["key_0358"] = "恐惧_0358",
  ["key_0359"] = "涌浪_0359",
  ["key_0360"] = "闪电_0360",
  ["key_0361"] = "故障_0361",
  ["key_0362"] = "蒂莫西_0362",
  ["key_0363"] = "杰克_0363",
  ["key_0364"] = "影子_0364",
  ["key_0365"] = "搜寻_0365",
  ["key_0366"] = "人脸_0366",
  ["key_0367"] = "陷阱_0367",
  ["key_0368"] = "分身_0368",
  ["key_0369"] = "傻笑_0369",
  ["key_0370"] = "窗户_0370",
  ["key_0371"] = "加速_0371",
  ["key_0372"] = "吱嘎_0372",
  ["key_0373"] = "哥布林_0373",
  ["key_0374"] = "杰夫_0374",
  ["key_0375"] = "鲍勃_0375",
  ["key_0376"] = "门_0376",
  ["key_0377"] = "箱子_0377",
  ["key_0378"] = "物品_0378",
  ["key_0379"] = "房间_0379",
  ["key_0380"] = "钥匙_0380",
  ["key_0381"] = "出口_0381",
  ["key_0382"] = "躲藏_0382",
  ["key_0383"] = "时间_0383",
  ["key_0384"] = "速度_0384",
  ["key_0385"] = "开启_0385",
  ["key_0386"] = "关闭_0386",
  ["key_0387"] = "显示_0387",
  ["key_0388"] = "玩家_0388",
  ["key_0389"] = "开关_0389",
  ["key_0390"] = "距离_0390",
  ["key_0391"] = "自动_0391",
  ["key_0392"] = "飞行_0392",
  ["key_0393"] = "跳跃_0393",
  ["key_0394"] = "滑行_0394",
  ["key_0395"] = "解锁_0395",
  ["key_0396"] = "使用_0396",
  ["key_0397"] = "生成_0397",
  ["key_0398"] = "实体_0398",
  ["key_0399"] = "噪音_0399",
  ["key_0400"] = "冲刺_0400",
  ["key_0401"] = "伏击_0401",
  ["key_0402"] = "眼睛_0402",
  ["key_0403"] = "尖啸_0403",
  ["key_0404"] = "停驻_0404",
  ["key_0405"] = "恐惧_0405",
  ["key_0406"] = "涌浪_0406",
  ["key_0407"] = "闪电_0407",
  ["key_0408"] = "故障_0408",
  ["key_0409"] = "蒂莫西_0409",
  ["key_0410"] = "杰克_0410",
  ["key_0411"] = "影子_0411",
  ["key_0412"] = "搜寻_0412",
  ["key_0413"] = "人脸_0413",
  ["key_0414"] = "陷阱_0414",
  ["key_0415"] = "分身_0415",
  ["key_0416"] = "傻笑_0416",
  ["key_0417"] = "窗户_0417",
  ["key_0418"] = "加速_0418",
  ["key_0419"] = "吱嘎_0419",
  ["key_0420"] = "哥布林_0420",
  ["key_0421"] = "杰夫_0421",
  ["key_0422"] = "鲍勃_0422",
  ["key_0423"] = "门_0423",
  ["key_0424"] = "箱子_0424",
  ["key_0425"] = "物品_0425",
  ["key_0426"] = "房间_0426",
  ["key_0427"] = "钥匙_0427",
  ["key_0428"] = "出口_0428",
  ["key_0429"] = "躲藏_0429",
  ["key_0430"] = "时间_0430",
  ["key_0431"] = "速度_0431",
  ["key_0432"] = "开启_0432",
  ["key_0433"] = "关闭_0433",
  ["key_0434"] = "显示_0434",
  ["key_0435"] = "玩家_0435",
  ["key_0436"] = "开关_0436",
  ["key_0437"] = "距离_0437",
  ["key_0438"] = "自动_0438",
  ["key_0439"] = "飞行_0439",
  ["key_0440"] = "跳跃_0440",
  ["key_0441"] = "滑行_0441",
  ["key_0442"] = "解锁_0442",
  ["key_0443"] = "使用_0443",
  ["key_0444"] = "生成_0444",
  ["key_0445"] = "实体_0445",
  ["key_0446"] = "噪音_0446",
  ["key_0447"] = "冲刺_0447",
  ["key_0448"] = "伏击_0448",
  ["key_0449"] = "眼睛_0449",
  ["key_0450"] = "尖啸_0450",
  ["key_0451"] = "停驻_0451",
  ["key_0452"] = "恐惧_0452",
  ["key_0453"] = "涌浪_0453",
  ["key_0454"] = "闪电_0454",
  ["key_0455"] = "故障_0455",
  ["key_0456"] = "蒂莫西_0456",
  ["key_0457"] = "杰克_0457",
  ["key_0458"] = "影子_0458",
  ["key_0459"] = "搜寻_0459",
  ["key_0460"] = "人脸_0460",
  ["key_0461"] = "陷阱_0461",
  ["key_0462"] = "分身_0462",
  ["key_0463"] = "傻笑_0463",
  ["key_0464"] = "窗户_0464",
  ["key_0465"] = "加速_0465",
  ["key_0466"] = "吱嘎_0466",
  ["key_0467"] = "哥布林_0467",
  ["key_0468"] = "杰夫_0468",
  ["key_0469"] = "鲍勃_0469",
  ["key_0470"] = "门_0470",
  ["key_0471"] = "箱子_0471",
  ["key_0472"] = "物品_0472",
  ["key_0473"] = "房间_0473",
  ["key_0474"] = "钥匙_0474",
  ["key_0475"] = "出口_0475",
  ["key_0476"] = "躲藏_0476",
  ["key_0477"] = "时间_0477",
  ["key_0478"] = "速度_0478",
  ["key_0479"] = "开启_0479",
  ["key_0480"] = "关闭_0480",
  ["key_0481"] = "显示_0481",
  ["key_0482"] = "玩家_0482",
  ["key_0483"] = "开关_0483",
  ["key_0484"] = "距离_0484",
  ["key_0485"] = "自动_0485",
  ["key_0486"] = "飞行_0486",
  ["key_0487"] = "跳跃_0487",
  ["key_0488"] = "滑行_0488",
  ["key_0489"] = "解锁_0489",
  ["key_0490"] = "使用_0490",
  ["key_0491"] = "生成_0491",
  ["key_0492"] = "实体_0492",
  ["key_0493"] = "噪音_0493",
  ["key_0494"] = "冲刺_0494",
  ["key_0495"] = "伏击_0495",
  ["key_0496"] = "眼睛_0496",
  ["key_0497"] = "尖啸_0497",
  ["key_0498"] = "停驻_0498",
  ["key_0499"] = "恐惧_0499",
  ["key_0500"] = "涌浪_0500",
  ["key_0501"] = "闪电_0501",
  ["key_0502"] = "故障_0502",
  ["key_0503"] = "蒂莫西_0503",
  ["key_0504"] = "杰克_0504",
  ["key_0505"] = "影子_0505",
  ["key_0506"] = "搜寻_0506",
  ["key_0507"] = "人脸_0507",
  ["key_0508"] = "陷阱_0508",
  ["key_0509"] = "分身_0509",
  ["key_0510"] = "傻笑_0510",
  ["key_0511"] = "窗户_0511",
  ["key_0512"] = "加速_0512",
  ["key_0513"] = "吱嘎_0513",
  ["key_0514"] = "哥布林_0514",
  ["key_0515"] = "杰夫_0515",
  ["key_0516"] = "鲍勃_0516",
  ["key_0517"] = "门_0517",
  ["key_0518"] = "箱子_0518",
  ["key_0519"] = "物品_0519",
  ["key_0520"] = "房间_0520",
  ["key_0521"] = "钥匙_0521",
  ["key_0522"] = "出口_0522",
  ["key_0523"] = "躲藏_0523",
  ["key_0524"] = "时间_0524",
  ["key_0525"] = "速度_0525",
  ["key_0526"] = "开启_0526",
  ["key_0527"] = "关闭_0527",
  ["key_0528"] = "显示_0528",
  ["key_0529"] = "玩家_0529",
  ["key_0530"] = "开关_0530",
  ["key_0531"] = "距离_0531",
  ["key_0532"] = "自动_0532",
  ["key_0533"] = "飞行_0533",
  ["key_0534"] = "跳跃_0534",
  ["key_0535"] = "滑行_0535",
  ["key_0536"] = "解锁_0536",
  ["key_0537"] = "使用_0537",
  ["key_0538"] = "生成_0538",
  ["key_0539"] = "实体_0539",
  ["key_0540"] = "噪音_0540",
  ["key_0541"] = "冲刺_0541",
  ["key_0542"] = "伏击_0542",
  ["key_0543"] = "眼睛_0543",
  ["key_0544"] = "尖啸_0544",
  ["key_0545"] = "停驻_0545",
  ["key_0546"] = "恐惧_0546",
  ["key_0547"] = "涌浪_0547",
  ["key_0548"] = "闪电_0548",
  ["key_0549"] = "故障_0549",
  ["key_0550"] = "蒂莫西_0550",
  ["key_0551"] = "杰克_0551",
  ["key_0552"] = "影子_0552",
  ["key_0553"] = "搜寻_0553",
  ["key_0554"] = "人脸_0554",
  ["key_0555"] = "陷阱_0555",
  ["key_0556"] = "分身_0556",
  ["key_0557"] = "傻笑_0557",
  ["key_0558"] = "窗户_0558",
  ["key_0559"] = "加速_0559",
  ["key_0560"] = "吱嘎_0560",
  ["key_0561"] = "哥布林_0561",
  ["key_0562"] = "杰夫_0562",
  ["key_0563"] = "鲍勃_0563",
  ["key_0564"] = "门_0564",
  ["key_0565"] = "箱子_0565",
  ["key_0566"] = "物品_0566",
  ["key_0567"] = "房间_0567",
  ["key_0568"] = "钥匙_0568",
  ["key_0569"] = "出口_0569",
  ["key_0570"] = "躲藏_0570",
  ["key_0571"] = "时间_0571",
  ["key_0572"] = "速度_0572",
  ["key_0573"] = "开启_0573",
  ["key_0574"] = "关闭_0574",
  ["key_0575"] = "显示_0575",
  ["key_0576"] = "玩家_0576",
  ["key_0577"] = "开关_0577",
  ["key_0578"] = "距离_0578",
  ["key_0579"] = "自动_0579",
  ["key_0580"] = "飞行_0580",
  ["key_0581"] = "跳跃_0581",
  ["key_0582"] = "滑行_0582",
  ["key_0583"] = "解锁_0583",
  ["key_0584"] = "使用_0584",
  ["key_0585"] = "生成_0585",
  ["key_0586"] = "实体_0586",
  ["key_0587"] = "噪音_0587",
  ["key_0588"] = "冲刺_0588",
  ["key_0589"] = "伏击_0589",
  ["key_0590"] = "眼睛_0590",
  ["key_0591"] = "尖啸_0591",
  ["key_0592"] = "停驻_0592",
  ["key_0593"] = "恐惧_0593",
  ["key_0594"] = "涌浪_0594",
  ["key_0595"] = "闪电_0595",
  ["key_0596"] = "故障_0596",
  ["key_0597"] = "蒂莫西_0597",
  ["key_0598"] = "杰克_0598",
  ["key_0599"] = "影子_0599",
  ["key_0600"] = "搜寻_0600",
  ["key_0601"] = "人脸_0601",
  ["key_0602"] = "陷阱_0602",
  ["key_0603"] = "分身_0603",
  ["key_0604"] = "傻笑_0604",
  ["key_0605"] = "窗户_0605",
  ["key_0606"] = "加速_0606",
  ["key_0607"] = "吱嘎_0607",
  ["key_0608"] = "哥布林_0608",
  ["key_0609"] = "杰夫_0609",
  ["key_0610"] = "鲍勃_0610",
  ["key_0611"] = "门_0611",
  ["key_0612"] = "箱子_0612",
  ["key_0613"] = "物品_0613",
  ["key_0614"] = "房间_0614",
  ["key_0615"] = "钥匙_0615",
  ["key_0616"] = "出口_0616",
  ["key_0617"] = "躲藏_0617",
  ["key_0618"] = "时间_0618",
  ["key_0619"] = "速度_0619",
  ["key_0620"] = "开启_0620",
  ["key_0621"] = "关闭_0621",
  ["key_0622"] = "显示_0622",
  ["key_0623"] = "玩家_0623",
  ["key_0624"] = "开关_0624",
  ["key_0625"] = "距离_0625",
  ["key_0626"] = "自动_0626",
  ["key_0627"] = "飞行_0627",
  ["key_0628"] = "跳跃_0628",
  ["key_0629"] = "滑行_0629",
  ["key_0630"] = "解锁_0630",
  ["key_0631"] = "使用_0631",
  ["key_0632"] = "生成_0632",
  ["key_0633"] = "实体_0633",
  ["key_0634"] = "噪音_0634",
  ["key_0635"] = "冲刺_0635",
  ["key_0636"] = "伏击_0636",
  ["key_0637"] = "眼睛_0637",
  ["key_0638"] = "尖啸_0638",
  ["key_0639"] = "停驻_0639",
  ["key_0640"] = "恐惧_0640",
  ["key_0641"] = "涌浪_0641",
  ["key_0642"] = "闪电_0642",
  ["key_0643"] = "故障_0643",
  ["key_0644"] = "蒂莫西_0644",
  ["key_0645"] = "杰克_0645",
  ["key_0646"] = "影子_0646",
  ["key_0647"] = "搜寻_0647",
  ["key_0648"] = "人脸_0648",
  ["key_0649"] = "陷阱_0649",
  ["key_0650"] = "分身_0650",
  ["key_0651"] = "傻笑_0651",
  ["key_0652"] = "窗户_0652",
  ["key_0653"] = "加速_0653",
  ["key_0654"] = "吱嘎_0654",
  ["key_0655"] = "哥布林_0655",
  ["key_0656"] = "杰夫_0656",
  ["key_0657"] = "鲍勃_0657",
  ["key_0658"] = "门_0658",
  ["key_0659"] = "箱子_0659",
  ["key_0660"] = "物品_0660",
  ["key_0661"] = "房间_0661",
  ["key_0662"] = "钥匙_0662",
  ["key_0663"] = "出口_0663",
  ["key_0664"] = "躲藏_0664",
  ["key_0665"] = "时间_0665",
  ["key_0666"] = "速度_0666",
  ["key_0667"] = "开启_0667",
  ["key_0668"] = "关闭_0668",
  ["key_0669"] = "显示_0669",
  ["key_0670"] = "玩家_0670",
  ["key_0671"] = "开关_0671",
  ["key_0672"] = "距离_0672",
  ["key_0673"] = "自动_0673",
  ["key_0674"] = "飞行_0674",
  ["key_0675"] = "跳跃_0675",
  ["key_0676"] = "滑行_0676",
  ["key_0677"] = "解锁_0677",
  ["key_0678"] = "使用_0678",
  ["key_0679"] = "生成_0679",
  ["key_0680"] = "实体_0680",
  ["key_0681"] = "噪音_0681",
  ["key_0682"] = "冲刺_0682",
  ["key_0683"] = "伏击_0683",
  ["key_0684"] = "眼睛_0684",
  ["key_0685"] = "尖啸_0685",
  ["key_0686"] = "停驻_0686",
  ["key_0687"] = "恐惧_0687",
  ["key_0688"] = "涌浪_0688",
  ["key_0689"] = "闪电_0689",
  ["key_0690"] = "故障_0690",
  ["key_0691"] = "蒂莫西_0691",
  ["key_0692"] = "杰克_0692",
  ["key_0693"] = "影子_0693",
  ["key_0694"] = "搜寻_0694",
  ["key_0695"] = "人脸_0695",
  ["key_0696"] = "陷阱_0696",
  ["key_0697"] = "分身_0697",
  ["key_0698"] = "傻笑_0698",
  ["key_0699"] = "窗户_0699",
  ["key_0700"] = "加速_0700",
  ["key_0701"] = "吱嘎_0701",
  ["key_0702"] = "哥布林_0702",
  ["key_0703"] = "杰夫_0703",
  ["key_0704"] = "鲍勃_0704",
  ["key_0705"] = "门_0705",
  ["key_0706"] = "箱子_0706",
  ["key_0707"] = "物品_0707",
  ["key_0708"] = "房间_0708",
  ["key_0709"] = "钥匙_0709",
  ["key_0710"] = "出口_0710",
  ["key_0711"] = "躲藏_0711",
  ["key_0712"] = "时间_0712",
  ["key_0713"] = "速度_0713",
  ["key_0714"] = "开启_0714",
  ["key_0715"] = "关闭_0715",
  ["key_0716"] = "显示_0716",
  ["key_0717"] = "玩家_0717",
  ["key_0718"] = "开关_0718",
  ["key_0719"] = "距离_0719",
  ["key_0720"] = "自动_0720",
  ["key_0721"] = "飞行_0721",
  ["key_0722"] = "跳跃_0722",
  ["key_0723"] = "滑行_0723",
  ["key_0724"] = "解锁_0724",
  ["key_0725"] = "使用_0725",
  ["key_0726"] = "生成_0726",
  ["key_0727"] = "实体_0727",
  ["key_0728"] = "噪音_0728",
  ["key_0729"] = "冲刺_0729",
  ["key_0730"] = "伏击_0730",
  ["key_0731"] = "眼睛_0731",
  ["key_0732"] = "尖啸_0732",
  ["key_0733"] = "停驻_0733",
  ["key_0734"] = "恐惧_0734",
  ["key_0735"] = "涌浪_0735",
  ["key_0736"] = "闪电_0736",
  ["key_0737"] = "故障_0737",
  ["key_0738"] = "蒂莫西_0738",
  ["key_0739"] = "杰克_0739",
  ["key_0740"] = "影子_0740",
  ["key_0741"] = "搜寻_0741",
  ["key_0742"] = "人脸_0742",
  ["key_0743"] = "陷阱_0743",
  ["key_0744"] = "分身_0744",
  ["key_0745"] = "傻笑_0745",
  ["key_0746"] = "窗户_0746",
  ["key_0747"] = "加速_0747",
  ["key_0748"] = "吱嘎_0748",
  ["key_0749"] = "哥布林_0749",
  ["key_0750"] = "杰夫_0750",
  ["key_0751"] = "鲍勃_0751",
  ["key_0752"] = "门_0752",
  ["key_0753"] = "箱子_0753",
  ["key_0754"] = "物品_0754",
  ["key_0755"] = "房间_0755",
  ["key_0756"] = "钥匙_0756",
  ["key_0757"] = "出口_0757",
  ["key_0758"] = "躲藏_0758",
  ["key_0759"] = "时间_0759",
  ["key_0760"] = "速度_0760",
  ["key_0761"] = "开启_0761",
  ["key_0762"] = "关闭_0762",
  ["key_0763"] = "显示_0763",
  ["key_0764"] = "玩家_0764",
  ["key_0765"] = "开关_0765",
  ["key_0766"] = "距离_0766",
  ["key_0767"] = "自动_0767",
  ["key_0768"] = "飞行_0768",
  ["key_0769"] = "跳跃_0769",
  ["key_0770"] = "滑行_0770",
  ["key_0771"] = "解锁_0771",
  ["key_0772"] = "使用_0772",
  ["key_0773"] = "生成_0773",
  ["key_0774"] = "实体_0774",
  ["key_0775"] = "噪音_0775",
  ["key_0776"] = "冲刺_0776",
  ["key_0777"] = "伏击_0777",
  ["key_0778"] = "眼睛_0778",
  ["key_0779"] = "尖啸_0779",
  ["key_0780"] = "停驻_0780",
  ["key_0781"] = "恐惧_0781",
  ["key_0782"] = "涌浪_0782",
  ["key_0783"] = "闪电_0783",
  ["key_0784"] = "故障_0784",
  ["key_0785"] = "蒂莫西_0785",
  ["key_0786"] = "杰克_0786",
  ["key_0787"] = "影子_0787",
  ["key_0788"] = "搜寻_0788",
  ["key_0789"] = "人脸_0789",
  ["key_0790"] = "陷阱_0790",
  ["key_0791"] = "分身_0791",
  ["key_0792"] = "傻笑_0792",
  ["key_0793"] = "窗户_0793",
  ["key_0794"] = "加速_0794",
  ["key_0795"] = "吱嘎_0795",
  ["key_0796"] = "哥布林_0796",
  ["key_0797"] = "杰夫_0797",
  ["key_0798"] = "鲍勃_0798",
  ["key_0799"] = "门_0799",
  ["key_0800"] = "箱子_0800",
  ["key_0801"] = "物品_0801",
  ["key_0802"] = "房间_0802",
  ["key_0803"] = "钥匙_0803",
  ["key_0804"] = "出口_0804",
  ["key_0805"] = "躲藏_0805",
  ["key_0806"] = "时间_0806",
  ["key_0807"] = "速度_0807",
  ["key_0808"] = "开启_0808",
  ["key_0809"] = "关闭_0809",
  ["key_0810"] = "显示_0810",
  ["key_0811"] = "玩家_0811",
  ["key_0812"] = "开关_0812",
  ["key_0813"] = "距离_0813",
  ["key_0814"] = "自动_0814",
  ["key_0815"] = "飞行_0815",
  ["key_0816"] = "跳跃_0816",
  ["key_0817"] = "滑行_0817",
  ["key_0818"] = "解锁_0818",
  ["key_0819"] = "使用_0819",
  ["key_0820"] = "生成_0820",
  ["key_0821"] = "实体_0821",
  ["key_0822"] = "噪音_0822",
  ["key_0823"] = "冲刺_0823",
  ["key_0824"] = "伏击_0824",
  ["key_0825"] = "眼睛_0825",
  ["key_0826"] = "尖啸_0826",
  ["key_0827"] = "停驻_0827",
  ["key_0828"] = "恐惧_0828",
  ["key_0829"] = "涌浪_0829",
  ["key_0830"] = "闪电_0830",
  ["key_0831"] = "故障_0831",
  ["key_0832"] = "蒂莫西_0832",
  ["key_0833"] = "杰克_0833",
  ["key_0834"] = "影子_0834",
  ["key_0835"] = "搜寻_0835",
  ["key_0836"] = "人脸_0836",
  ["key_0837"] = "陷阱_0837",
  ["key_0838"] = "分身_0838",
  ["key_0839"] = "傻笑_0839",
  ["key_0840"] = "窗户_0840",
  ["key_0841"] = "加速_0841",
  ["key_0842"] = "吱嘎_0842",
  ["key_0843"] = "哥布林_0843",
  ["key_0844"] = "杰夫_0844",
  ["key_0845"] = "鲍勃_0845",
  ["key_0846"] = "门_0846",
  ["key_0847"] = "箱子_0847",
  ["key_0848"] = "物品_0848",
  ["key_0849"] = "房间_0849",
  ["key_0850"] = "钥匙_0850",
  ["key_0851"] = "出口_0851",
  ["key_0852"] = "躲藏_0852",
  ["key_0853"] = "时间_0853",
  ["key_0854"] = "速度_0854",
  ["key_0855"] = "开启_0855",
  ["key_0856"] = "关闭_0856",
  ["key_0857"] = "显示_0857",
  ["key_0858"] = "玩家_0858",
  ["key_0859"] = "开关_0859",
  ["key_0860"] = "距离_0860",
  ["key_0861"] = "自动_0861",
  ["key_0862"] = "飞行_0862",
  ["key_0863"] = "跳跃_0863",
  ["key_0864"] = "滑行_0864",
  ["key_0865"] = "解锁_0865",
  ["key_0866"] = "使用_0866",
  ["key_0867"] = "生成_0867",
  ["key_0868"] = "实体_0868",
  ["key_0869"] = "噪音_0869",
  ["key_0870"] = "冲刺_0870",
  ["key_0871"] = "伏击_0871",
  ["key_0872"] = "眼睛_0872",
  ["key_0873"] = "尖啸_0873",
  ["key_0874"] = "停驻_0874",
  ["key_0875"] = "恐惧_0875",
  ["key_0876"] = "涌浪_0876",
  ["key_0877"] = "闪电_0877",
  ["key_0878"] = "故障_0878",
  ["key_0879"] = "蒂莫西_0879",
  ["key_0880"] = "杰克_0880",
  ["key_0881"] = "影子_0881",
  ["key_0882"] = "搜寻_0882",
  ["key_0883"] = "人脸_0883",
  ["key_0884"] = "陷阱_0884",
  ["key_0885"] = "分身_0885",
  ["key_0886"] = "傻笑_0886",
  ["key_0887"] = "窗户_0887",
  ["key_0888"] = "加速_0888",
  ["key_0889"] = "吱嘎_0889",
  ["key_0890"] = "哥布林_0890",
  ["key_0891"] = "杰夫_0891",
  ["key_0892"] = "鲍勃_0892",
  ["key_0893"] = "门_0893",
  ["key_0894"] = "箱子_0894",
  ["key_0895"] = "物品_0895",
  ["key_0896"] = "房间_0896",
  ["key_0897"] = "钥匙_0897",
  ["key_0898"] = "出口_0898",
  ["key_0899"] = "躲藏_0899",
  ["key_0900"] = "时间_0900",
  ["key_0901"] = "速度_0901",
  ["key_0902"] = "开启_0902",
  ["key_0903"] = "关闭_0903",
  ["key_0904"] = "显示_0904",
  ["key_0905"] = "玩家_0905",
  ["key_0906"] = "开关_0906",
  ["key_0907"] = "距离_0907",
  ["key_0908"] = "自动_0908",
  ["key_0909"] = "飞行_0909",
  ["key_0910"] = "跳跃_0910",
  ["key_0911"] = "滑行_0911",
  ["key_0912"] = "解锁_0912",
  ["key_0913"] = "使用_0913",
  ["key_0914"] = "生成_0914",
  ["key_0915"] = "实体_0915",
  ["key_0916"] = "噪音_0916",
  ["key_0917"] = "冲刺_0917",
  ["key_0918"] = "伏击_0918",
  ["key_0919"] = "眼睛_0919",
  ["key_0920"] = "尖啸_0920",
  ["key_0921"] = "停驻_0921",
  ["key_0922"] = "恐惧_0922",
  ["key_0923"] = "涌浪_0923",
  ["key_0924"] = "闪电_0924",
  ["key_0925"] = "故障_0925",
  ["key_0926"] = "蒂莫西_0926",
  ["key_0927"] = "杰克_0927",
  ["key_0928"] = "影子_0928",
  ["key_0929"] = "搜寻_0929",
  ["key_0930"] = "人脸_0930",
  ["key_0931"] = "陷阱_0931",
  ["key_0932"] = "分身_0932",
  ["key_0933"] = "傻笑_0933",
  ["key_0934"] = "窗户_0934",
  ["key_0935"] = "加速_0935",
  ["key_0936"] = "吱嘎_0936",
  ["key_0937"] = "哥布林_0937",
  ["key_0938"] = "杰夫_0938",
  ["key_0939"] = "鲍勃_0939",
  ["key_0940"] = "门_0940",
  ["key_0941"] = "箱子_0941",
  ["key_0942"] = "物品_0942",
  ["key_0943"] = "房间_0943",
  ["key_0944"] = "钥匙_0944",
  ["key_0945"] = "出口_0945",
  ["key_0946"] = "躲藏_0946",
  ["key_0947"] = "时间_0947",
  ["key_0948"] = "速度_0948",
  ["key_0949"] = "开启_0949",
  ["key_0950"] = "关闭_0950",
  ["key_0951"] = "显示_0951",
  ["key_0952"] = "玩家_0952",
  ["key_0953"] = "开关_0953",
  ["key_0954"] = "距离_0954",
  ["key_0955"] = "自动_0955",
  ["key_0956"] = "飞行_0956",
  ["key_0957"] = "跳跃_0957",
  ["key_0958"] = "滑行_0958",
  ["key_0959"] = "解锁_0959",
  ["key_0960"] = "使用_0960",
  ["key_0961"] = "生成_0961",
  ["key_0962"] = "实体_0962",
  ["key_0963"] = "噪音_0963",
  ["key_0964"] = "冲刺_0964",
  ["key_0965"] = "伏击_0965",
  ["key_0966"] = "眼睛_0966",
  ["key_0967"] = "尖啸_0967",
  ["key_0968"] = "停驻_0968",
  ["key_0969"] = "恐惧_0969",
  ["key_0970"] = "涌浪_0970",
  ["key_0971"] = "闪电_0971",
  ["key_0972"] = "故障_0972",
  ["key_0973"] = "蒂莫西_0973",
  ["key_0974"] = "杰克_0974",
  ["key_0975"] = "影子_0975",
  ["key_0976"] = "搜寻_0976",
  ["key_0977"] = "人脸_0977",
  ["key_0978"] = "陷阱_0978",
  ["key_0979"] = "分身_0979",
  ["key_0980"] = "傻笑_0980",
  ["key_0981"] = "窗户_0981",
  ["key_0982"] = "加速_0982",
  ["key_0983"] = "吱嘎_0983",
  ["key_0984"] = "哥布林_0984",
  ["key_0985"] = "杰夫_0985",
  ["key_0986"] = "鲍勃_0986",
  ["key_0987"] = "门_0987",
  ["key_0988"] = "箱子_0988",
  ["key_0989"] = "物品_0989",
  ["key_0990"] = "房间_0990",
  ["key_0991"] = "钥匙_0991",
  ["key_0992"] = "出口_0992",
  ["key_0993"] = "躲藏_0993",
  ["key_0994"] = "时间_0994",
  ["key_0995"] = "速度_0995",
  ["key_0996"] = "开启_0996",
  ["key_0997"] = "关闭_0997",
  ["key_0998"] = "显示_0998",
  ["key_0999"] = "玩家_0999",
  ["key_1000"] = "开关_1000",
  ["key_1001"] = "距离_1001",
  ["key_1002"] = "自动_1002",
  ["key_1003"] = "飞行_1003",
  ["key_1004"] = "跳跃_1004",
  ["key_1005"] = "滑行_1005",
  ["key_1006"] = "解锁_1006",
  ["key_1007"] = "使用_1007",
  ["key_1008"] = "生成_1008",
  ["key_1009"] = "实体_1009",
  ["key_1010"] = "噪音_1010",
  ["key_1011"] = "冲刺_1011",
  ["key_1012"] = "伏击_1012",
  ["key_1013"] = "眼睛_1013",
  ["key_1014"] = "尖啸_1014",
  ["key_1015"] = "停驻_1015",
  ["key_1016"] = "恐惧_1016",
  ["key_1017"] = "涌浪_1017",
  ["key_1018"] = "闪电_1018",
  ["key_1019"] = "故障_1019",
  ["key_1020"] = "蒂莫西_1020",
  ["key_1021"] = "杰克_1021",
  ["key_1022"] = "影子_1022",
  ["key_1023"] = "搜寻_1023",
  ["key_1024"] = "人脸_1024",
  ["key_1025"] = "陷阱_1025",
  ["key_1026"] = "分身_1026",
  ["key_1027"] = "傻笑_1027",
  ["key_1028"] = "窗户_1028",
  ["key_1029"] = "加速_1029",
  ["key_1030"] = "吱嘎_1030",
  ["key_1031"] = "哥布林_1031",
  ["key_1032"] = "杰夫_1032",
  ["key_1033"] = "鲍勃_1033",
  ["key_1034"] = "门_1034",
  ["key_1035"] = "箱子_1035",
  ["key_1036"] = "物品_1036",
  ["key_1037"] = "房间_1037",
  ["key_1038"] = "钥匙_1038",
  ["key_1039"] = "出口_1039",
  ["key_1040"] = "躲藏_1040",
  ["key_1041"] = "时间_1041",
  ["key_1042"] = "速度_1042",
  ["key_1043"] = "开启_1043",
  ["key_1044"] = "关闭_1044",
  ["key_1045"] = "显示_1045",
  ["key_1046"] = "玩家_1046",
  ["key_1047"] = "开关_1047",
  ["key_1048"] = "距离_1048",
  ["key_1049"] = "自动_1049",
  ["key_1050"] = "飞行_1050",
  ["key_1051"] = "跳跃_1051",
  ["key_1052"] = "滑行_1052",
  ["key_1053"] = "解锁_1053",
  ["key_1054"] = "使用_1054",
  ["key_1055"] = "生成_1055",
  ["key_1056"] = "实体_1056",
  ["key_1057"] = "噪音_1057",
  ["key_1058"] = "冲刺_1058",
  ["key_1059"] = "伏击_1059",
  ["key_1060"] = "眼睛_1060",
  ["key_1061"] = "尖啸_1061",
  ["key_1062"] = "停驻_1062",
  ["key_1063"] = "恐惧_1063",
  ["key_1064"] = "涌浪_1064",
  ["key_1065"] = "闪电_1065",
  ["key_1066"] = "故障_1066",
  ["key_1067"] = "蒂莫西_1067",
  ["key_1068"] = "杰克_1068",
  ["key_1069"] = "影子_1069",
  ["key_1070"] = "搜寻_1070",
  ["key_1071"] = "人脸_1071",
  ["key_1072"] = "陷阱_1072",
  ["key_1073"] = "分身_1073",
  ["key_1074"] = "傻笑_1074",
  ["key_1075"] = "窗户_1075",
  ["key_1076"] = "加速_1076",
  ["key_1077"] = "吱嘎_1077",
  ["key_1078"] = "哥布林_1078",
  ["key_1079"] = "杰夫_1079",
  ["key_1080"] = "鲍勃_1080",
  ["key_1081"] = "门_1081",
  ["key_1082"] = "箱子_1082",
  ["key_1083"] = "物品_1083",
  ["key_1084"] = "房间_1084",
  ["key_1085"] = "钥匙_1085",
  ["key_1086"] = "出口_1086",
  ["key_1087"] = "躲藏_1087",
  ["key_1088"] = "时间_1088",
  ["key_1089"] = "速度_1089",
  ["key_1090"] = "开启_1090",
  ["key_1091"] = "关闭_1091",
  ["key_1092"] = "显示_1092",
  ["key_1093"] = "玩家_1093",
  ["key_1094"] = "开关_1094",
  ["key_1095"] = "距离_1095",
  ["key_1096"] = "自动_1096",
  ["key_1097"] = "飞行_1097",
  ["key_1098"] = "跳跃_1098",
  ["key_1099"] = "滑行_1099",
  ["key_1100"] = "解锁_1100",
  ["key_1101"] = "使用_1101",
  ["key_1102"] = "生成_1102",
  ["key_1103"] = "实体_1103",
  ["key_1104"] = "噪音_1104",
  ["key_1105"] = "冲刺_1105",
  ["key_1106"] = "伏击_1106",
  ["key_1107"] = "眼睛_1107",
  ["key_1108"] = "尖啸_1108",
  ["key_1109"] = "停驻_1109",
  ["key_1110"] = "恐惧_1110",
  ["key_1111"] = "涌浪_1111",
  ["key_1112"] = "闪电_1112",
  ["key_1113"] = "故障_1113",
  ["key_1114"] = "蒂莫西_1114",
  ["key_1115"] = "杰克_1115",
  ["key_1116"] = "影子_1116",
  ["key_1117"] = "搜寻_1117",
  ["key_1118"] = "人脸_1118",
  ["key_1119"] = "陷阱_1119",
  ["key_1120"] = "分身_1120",
  ["key_1121"] = "傻笑_1121",
  ["key_1122"] = "窗户_1122",
  ["key_1123"] = "加速_1123",
  ["key_1124"] = "吱嘎_1124",
  ["key_1125"] = "哥布林_1125",
  ["key_1126"] = "杰夫_1126",
  ["key_1127"] = "鲍勃_1127",
  ["key_1128"] = "门_1128",
  ["key_1129"] = "箱子_1129",
  ["key_1130"] = "物品_1130",
  ["key_1131"] = "房间_1131",
  ["key_1132"] = "钥匙_1132",
  ["key_1133"] = "出口_1133",
  ["key_1134"] = "躲藏_1134",
  ["key_1135"] = "时间_1135",
  ["key_1136"] = "速度_1136",
  ["key_1137"] = "开启_1137",
  ["key_1138"] = "关闭_1138",
  ["key_1139"] = "显示_1139",
  ["key_1140"] = "玩家_1140",
  ["key_1141"] = "开关_1141",
  ["key_1142"] = "距离_1142",
  ["key_1143"] = "自动_1143",
  ["key_1144"] = "飞行_1144",
  ["key_1145"] = "跳跃_1145",
  ["key_1146"] = "滑行_1146",
  ["key_1147"] = "解锁_1147",
  ["key_1148"] = "使用_1148",
  ["key_1149"] = "生成_1149",
  ["key_1150"] = "实体_1150",
  ["key_1151"] = "噪音_1151",
  ["key_1152"] = "冲刺_1152",
  ["key_1153"] = "伏击_1153",
  ["key_1154"] = "眼睛_1154",
  ["key_1155"] = "尖啸_1155",
  ["key_1156"] = "停驻_1156",
  ["key_1157"] = "恐惧_1157",
  ["key_1158"] = "涌浪_1158",
  ["key_1159"] = "闪电_1159",
  ["key_1160"] = "故障_1160",
  ["key_1161"] = "蒂莫西_1161",
  ["key_1162"] = "杰克_1162",
  ["key_1163"] = "影子_1163",
  ["key_1164"] = "搜寻_1164",
  ["key_1165"] = "人脸_1165",
  ["key_1166"] = "陷阱_1166",
  ["key_1167"] = "分身_1167",
  ["key_1168"] = "傻笑_1168",
  ["key_1169"] = "窗户_1169",
  ["key_1170"] = "加速_1170",
  ["key_1171"] = "吱嘎_1171",
  ["key_1172"] = "哥布林_1172",
  ["key_1173"] = "杰夫_1173",
  ["key_1174"] = "鲍勃_1174",
  ["key_1175"] = "门_1175",
  ["key_1176"] = "箱子_1176",
  ["key_1177"] = "物品_1177",
  ["key_1178"] = "房间_1178",
  ["key_1179"] = "钥匙_1179",
  ["key_1180"] = "出口_1180",
  ["key_1181"] = "躲藏_1181",
  ["key_1182"] = "时间_1182",
  ["key_1183"] = "速度_1183",
  ["key_1184"] = "开启_1184",
  ["key_1185"] = "关闭_1185",
  ["key_1186"] = "显示_1186",
  ["key_1187"] = "玩家_1187",
  ["key_1188"] = "开关_1188",
  ["key_1189"] = "距离_1189",
  ["key_1190"] = "自动_1190",
  ["key_1191"] = "飞行_1191",
  ["key_1192"] = "跳跃_1192",
  ["key_1193"] = "滑行_1193",
  ["key_1194"] = "解锁_1194",
  ["key_1195"] = "使用_1195",
  ["key_1196"] = "生成_1196",
  ["key_1197"] = "实体_1197",
  ["key_1198"] = "噪音_1198",
  ["key_1199"] = "冲刺_1199",
  ["key_1200"] = "伏击_1200",
  ["key_1201"] = "眼睛_1201",
  ["key_1202"] = "尖啸_1202",
  ["key_1203"] = "停驻_1203",
  ["key_1204"] = "恐惧_1204",
  ["key_1205"] = "涌浪_1205",
  ["key_1206"] = "闪电_1206",
  ["key_1207"] = "故障_1207",
  ["key_1208"] = "蒂莫西_1208",
  ["key_1209"] = "杰克_1209",
  ["key_1210"] = "影子_1210",
  ["key_1211"] = "搜寻_1211",
  ["key_1212"] = "人脸_1212",
  ["key_1213"] = "陷阱_1213",
  ["key_1214"] = "分身_1214",
  ["key_1215"] = "傻笑_1215",
  ["key_1216"] = "窗户_1216",
  ["key_1217"] = "加速_1217",
  ["key_1218"] = "吱嘎_1218",
  ["key_1219"] = "哥布林_1219",
  ["key_1220"] = "杰夫_1220",
  ["key_1221"] = "鲍勃_1221",
  ["key_1222"] = "门_1222",
  ["key_1223"] = "箱子_1223",
  ["key_1224"] = "物品_1224",
  ["key_1225"] = "房间_1225",
  ["key_1226"] = "钥匙_1226",
  ["key_1227"] = "出口_1227",
  ["key_1228"] = "躲藏_1228",
  ["key_1229"] = "时间_1229",
  ["key_1230"] = "速度_1230",
  ["key_1231"] = "开启_1231",
  ["key_1232"] = "关闭_1232",
  ["key_1233"] = "显示_1233",
  ["key_1234"] = "玩家_1234",
  ["key_1235"] = "开关_1235",
  ["key_1236"] = "距离_1236",
  ["key_1237"] = "自动_1237",
  ["key_1238"] = "飞行_1238",
  ["key_1239"] = "跳跃_1239",
  ["key_1240"] = "滑行_1240",
  ["key_1241"] = "解锁_1241",
  ["key_1242"] = "使用_1242",
  ["key_1243"] = "生成_1243",
  ["key_1244"] = "实体_1244",
  ["key_1245"] = "噪音_1245",
  ["key_1246"] = "冲刺_1246",
  ["key_1247"] = "伏击_1247",
  ["key_1248"] = "眼睛_1248",
  ["key_1249"] = "尖啸_1249",
  ["key_1250"] = "停驻_1250",
  ["key_1251"] = "恐惧_1251",
  ["key_1252"] = "涌浪_1252",
  ["key_1253"] = "闪电_1253",
  ["key_1254"] = "故障_1254",
  ["key_1255"] = "蒂莫西_1255",
  ["key_1256"] = "杰克_1256",
  ["key_1257"] = "影子_1257",
  ["key_1258"] = "搜寻_1258",
  ["key_1259"] = "人脸_1259",
  ["key_1260"] = "陷阱_1260",
  ["key_1261"] = "分身_1261",
  ["key_1262"] = "傻笑_1262",
  ["key_1263"] = "窗户_1263",
  ["key_1264"] = "加速_1264",
  ["key_1265"] = "吱嘎_1265",
  ["key_1266"] = "哥布林_1266",
  ["key_1267"] = "杰夫_1267",
  ["key_1268"] = "鲍勃_1268",
  ["key_1269"] = "门_1269",
  ["key_1270"] = "箱子_1270",
  ["key_1271"] = "物品_1271",
  ["key_1272"] = "房间_1272",
  ["key_1273"] = "钥匙_1273",
  ["key_1274"] = "出口_1274",
  ["key_1275"] = "躲藏_1275",
  ["key_1276"] = "时间_1276",
  ["key_1277"] = "速度_1277",
  ["key_1278"] = "开启_1278",
  ["key_1279"] = "关闭_1279",
  ["key_1280"] = "显示_1280",
  ["key_1281"] = "玩家_1281",
  ["key_1282"] = "开关_1282",
  ["key_1283"] = "距离_1283",
  ["key_1284"] = "自动_1284",
  ["key_1285"] = "飞行_1285",
  ["key_1286"] = "跳跃_1286",
  ["key_1287"] = "滑行_1287",
  ["key_1288"] = "解锁_1288",
  ["key_1289"] = "使用_1289",
  ["key_1290"] = "生成_1290",
  ["key_1291"] = "实体_1291",
  ["key_1292"] = "噪音_1292",
  ["key_1293"] = "冲刺_1293",
  ["key_1294"] = "伏击_1294",
  ["key_1295"] = "眼睛_1295",
  ["key_1296"] = "尖啸_1296",
  ["key_1297"] = "停驻_1297",
  ["key_1298"] = "恐惧_1298",
  ["key_1299"] = "涌浪_1299",
  ["key_1300"] = "闪电_1300",
  ["key_1301"] = "故障_1301",
  ["key_1302"] = "蒂莫西_1302",
  ["key_1303"] = "杰克_1303",
  ["key_1304"] = "影子_1304",
  ["key_1305"] = "搜寻_1305",
  ["key_1306"] = "人脸_1306",
  ["key_1307"] = "陷阱_1307",
  ["key_1308"] = "分身_1308",
  ["key_1309"] = "傻笑_1309",
  ["key_1310"] = "窗户_1310",
  ["key_1311"] = "加速_1311",
  ["key_1312"] = "吱嘎_1312",
  ["key_1313"] = "哥布林_1313",
  ["key_1314"] = "杰夫_1314",
  ["key_1315"] = "鲍勃_1315",
  ["key_1316"] = "门_1316",
  ["key_1317"] = "箱子_1317",
  ["key_1318"] = "物品_1318",
  ["key_1319"] = "房间_1319",
  ["key_1320"] = "钥匙_1320",
  ["key_1321"] = "出口_1321",
  ["key_1322"] = "躲藏_1322",
  ["key_1323"] = "时间_1323",
  ["key_1324"] = "速度_1324",
  ["key_1325"] = "开启_1325",
  ["key_1326"] = "关闭_1326",
  ["key_1327"] = "显示_1327",
  ["key_1328"] = "玩家_1328",
  ["key_1329"] = "开关_1329",
  ["key_1330"] = "距离_1330",
  ["key_1331"] = "自动_1331",
  ["key_1332"] = "飞行_1332",
  ["key_1333"] = "跳跃_1333",
  ["key_1334"] = "滑行_1334",
  ["key_1335"] = "解锁_1335",
  ["key_1336"] = "使用_1336",
  ["key_1337"] = "生成_1337",
  ["key_1338"] = "实体_1338",
  ["key_1339"] = "噪音_1339",
  ["key_1340"] = "冲刺_1340",
  ["key_1341"] = "伏击_1341",
  ["key_1342"] = "眼睛_1342",
  ["key_1343"] = "尖啸_1343",
  ["key_1344"] = "停驻_1344",
  ["key_1345"] = "恐惧_1345",
  ["key_1346"] = "涌浪_1346",
  ["key_1347"] = "闪电_1347",
  ["key_1348"] = "故障_1348",
  ["key_1349"] = "蒂莫西_1349",
  ["key_1350"] = "杰克_1350",
  ["key_1351"] = "影子_1351",
  ["key_1352"] = "搜寻_1352",
  ["key_1353"] = "人脸_1353",
  ["key_1354"] = "陷阱_1354",
  ["key_1355"] = "分身_1355",
  ["key_1356"] = "傻笑_1356",
  ["key_1357"] = "窗户_1357",
  ["key_1358"] = "加速_1358",
  ["key_1359"] = "吱嘎_1359",
  ["key_1360"] = "哥布林_1360",
  ["key_1361"] = "杰夫_1361",
  ["key_1362"] = "鲍勃_1362",
  ["key_1363"] = "门_1363",
  ["key_1364"] = "箱子_1364",
  ["key_1365"] = "物品_1365",
  ["key_1366"] = "房间_1366",
  ["key_1367"] = "钥匙_1367",
  ["key_1368"] = "出口_1368",
  ["key_1369"] = "躲藏_1369",
  ["key_1370"] = "时间_1370",
  ["key_1371"] = "速度_1371",
  ["key_1372"] = "开启_1372",
  ["key_1373"] = "关闭_1373",
  ["key_1374"] = "显示_1374",
  ["key_1375"] = "玩家_1375",
  ["key_1376"] = "开关_1376",
  ["key_1377"] = "距离_1377",
  ["key_1378"] = "自动_1378",
  ["key_1379"] = "飞行_1379",
  ["key_1380"] = "跳跃_1380",
  ["key_1381"] = "滑行_1381",
  ["key_1382"] = "解锁_1382",
  ["key_1383"] = "使用_1383",
  ["key_1384"] = "生成_1384",
  ["key_1385"] = "实体_1385",
  ["key_1386"] = "噪音_1386",
  ["key_1387"] = "冲刺_1387",
  ["key_1388"] = "伏击_1388",
  ["key_1389"] = "眼睛_1389",
  ["key_1390"] = "尖啸_1390",
  ["key_1391"] = "停驻_1391",
  ["key_1392"] = "恐惧_1392",
  ["key_1393"] = "涌浪_1393",
  ["key_1394"] = "闪电_1394",
  ["key_1395"] = "故障_1395",
  ["key_1396"] = "蒂莫西_1396",
  ["key_1397"] = "杰克_1397",
  ["key_1398"] = "影子_1398",
  ["key_1399"] = "搜寻_1399",
  ["key_1400"] = "人脸_1400",
  ["key_1401"] = "陷阱_1401",
  ["key_1402"] = "分身_1402",
  ["key_1403"] = "傻笑_1403",
  ["key_1404"] = "窗户_1404",
  ["key_1405"] = "加速_1405",
  ["key_1406"] = "吱嘎_1406",
  ["key_1407"] = "哥布林_1407",
  ["key_1408"] = "杰夫_1408",
  ["key_1409"] = "鲍勃_1409",
  ["key_1410"] = "门_1410",
  ["key_1411"] = "箱子_1411",
  ["key_1412"] = "物品_1412",
  ["key_1413"] = "房间_1413",
  ["key_1414"] = "钥匙_1414",
  ["key_1415"] = "出口_1415",
  ["key_1416"] = "躲藏_1416",
  ["key_1417"] = "时间_1417",
  ["key_1418"] = "速度_1418",
  ["key_1419"] = "开启_1419",
  ["key_1420"] = "关闭_1420",
  ["key_1421"] = "显示_1421",
  ["key_1422"] = "玩家_1422",
  ["key_1423"] = "开关_1423",
  ["key_1424"] = "距离_1424",
  ["key_1425"] = "自动_1425",
  ["key_1426"] = "飞行_1426",
  ["key_1427"] = "跳跃_1427",
  ["key_1428"] = "滑行_1428",
  ["key_1429"] = "解锁_1429",
  ["key_1430"] = "使用_1430",
  ["key_1431"] = "生成_1431",
  ["key_1432"] = "实体_1432",
  ["key_1433"] = "噪音_1433",
  ["key_1434"] = "冲刺_1434",
  ["key_1435"] = "伏击_1435",
  ["key_1436"] = "眼睛_1436",
  ["key_1437"] = "尖啸_1437",
  ["key_1438"] = "停驻_1438",
  ["key_1439"] = "恐惧_1439",
  ["key_1440"] = "涌浪_1440",
  ["key_1441"] = "闪电_1441",
  ["key_1442"] = "故障_1442",
  ["key_1443"] = "蒂莫西_1443",
  ["key_1444"] = "杰克_1444",
  ["key_1445"] = "影子_1445",
  ["key_1446"] = "搜寻_1446",
  ["key_1447"] = "人脸_1447",
  ["key_1448"] = "陷阱_1448",
  ["key_1449"] = "分身_1449",
  ["key_1450"] = "傻笑_1450",
  ["key_1451"] = "窗户_1451",
  ["key_1452"] = "加速_1452",
  ["key_1453"] = "吱嘎_1453",
  ["key_1454"] = "哥布林_1454",
  ["key_1455"] = "杰夫_1455",
  ["key_1456"] = "鲍勃_1456",
  ["key_1457"] = "门_1457",
  ["key_1458"] = "箱子_1458",
  ["key_1459"] = "物品_1459",
  ["key_1460"] = "房间_1460",
  ["key_1461"] = "钥匙_1461",
  ["key_1462"] = "出口_1462",
  ["key_1463"] = "躲藏_1463",
  ["key_1464"] = "时间_1464",
  ["key_1465"] = "速度_1465",
  ["key_1466"] = "开启_1466",
  ["key_1467"] = "关闭_1467",
  ["key_1468"] = "显示_1468",
  ["key_1469"] = "玩家_1469",
  ["key_1470"] = "开关_1470",
  ["key_1471"] = "距离_1471",
  ["key_1472"] = "自动_1472",
  ["key_1473"] = "飞行_1473",
  ["key_1474"] = "跳跃_1474",
  ["key_1475"] = "滑行_1475",
  ["key_1476"] = "解锁_1476",
  ["key_1477"] = "使用_1477",
  ["key_1478"] = "生成_1478",
  ["key_1479"] = "实体_1479",
  ["key_1480"] = "噪音_1480",
  ["key_1481"] = "冲刺_1481",
  ["key_1482"] = "伏击_1482",
  ["key_1483"] = "眼睛_1483",
  ["key_1484"] = "尖啸_1484",
  ["key_1485"] = "停驻_1485",
  ["key_1486"] = "恐惧_1486",
  ["key_1487"] = "涌浪_1487",
  ["key_1488"] = "闪电_1488",
  ["key_1489"] = "故障_1489",
  ["key_1490"] = "蒂莫西_1490",
  ["key_1491"] = "杰克_1491",
  ["key_1492"] = "影子_1492",
  ["key_1493"] = "搜寻_1493",
  ["key_1494"] = "人脸_1494",
  ["key_1495"] = "陷阱_1495",
  ["key_1496"] = "分身_1496",
  ["key_1497"] = "傻笑_1497",
  ["key_1498"] = "窗户_1498",
  ["key_1499"] = "加速_1499",
  ["key_1500"] = "吱嘎_1500",
  ["key_1501"] = "哥布林_1501",
  ["key_1502"] = "杰夫_1502",
  ["key_1503"] = "鲍勃_1503",
  ["key_1504"] = "门_1504",
  ["key_1505"] = "箱子_1505",
  ["key_1506"] = "物品_1506",
  ["key_1507"] = "房间_1507",
  ["key_1508"] = "钥匙_1508",
  ["key_1509"] = "出口_1509",
  ["key_1510"] = "躲藏_1510",
  ["key_1511"] = "时间_1511",
  ["key_1512"] = "速度_1512",
  ["key_1513"] = "开启_1513",
  ["key_1514"] = "关闭_1514",
  ["key_1515"] = "显示_1515",
  ["key_1516"] = "玩家_1516",
  ["key_1517"] = "开关_1517",
  ["key_1518"] = "距离_1518",
  ["key_1519"] = "自动_1519",
  ["key_1520"] = "飞行_1520",
  ["key_1521"] = "跳跃_1521",
  ["key_1522"] = "滑行_1522",
  ["key_1523"] = "解锁_1523",
  ["key_1524"] = "使用_1524",
  ["key_1525"] = "生成_1525",
  ["key_1526"] = "实体_1526",
  ["key_1527"] = "噪音_1527",
  ["key_1528"] = "冲刺_1528",
  ["key_1529"] = "伏击_1529",
  ["key_1530"] = "眼睛_1530",
  ["key_1531"] = "尖啸_1531",
  ["key_1532"] = "停驻_1532",
  ["key_1533"] = "恐惧_1533",
  ["key_1534"] = "涌浪_1534",
  ["key_1535"] = "闪电_1535",
  ["key_1536"] = "故障_1536",
  ["key_1537"] = "蒂莫西_1537",
  ["key_1538"] = "杰克_1538",
  ["key_1539"] = "影子_1539",
  ["key_1540"] = "搜寻_1540",
  ["key_1541"] = "人脸_1541",
  ["key_1542"] = "陷阱_1542",
  ["key_1543"] = "分身_1543",
  ["key_1544"] = "傻笑_1544",
  ["key_1545"] = "窗户_1545",
  ["key_1546"] = "加速_1546",
  ["key_1547"] = "吱嘎_1547",
  ["key_1548"] = "哥布林_1548",
  ["key_1549"] = "杰夫_1549",
  ["key_1550"] = "鲍勃_1550",
  ["key_1551"] = "门_1551",
  ["key_1552"] = "箱子_1552",
  ["key_1553"] = "物品_1553",
  ["key_1554"] = "房间_1554",
  ["key_1555"] = "钥匙_1555",
  ["key_1556"] = "出口_1556",
  ["key_1557"] = "躲藏_1557",
  ["key_1558"] = "时间_1558",
  ["key_1559"] = "速度_1559",
  ["key_1560"] = "开启_1560",
  ["key_1561"] = "关闭_1561",
  ["key_1562"] = "显示_1562",
  ["key_1563"] = "玩家_1563",
  ["key_1564"] = "开关_1564",
  ["key_1565"] = "距离_1565",
  ["key_1566"] = "自动_1566",
  ["key_1567"] = "飞行_1567",
  ["key_1568"] = "跳跃_1568",
  ["key_1569"] = "滑行_1569",
  ["key_1570"] = "解锁_1570",
  ["key_1571"] = "使用_1571",
  ["key_1572"] = "生成_1572",
  ["key_1573"] = "实体_1573",
  ["key_1574"] = "噪音_1574",
  ["key_1575"] = "冲刺_1575",
  ["key_1576"] = "伏击_1576",
  ["key_1577"] = "眼睛_1577",
  ["key_1578"] = "尖啸_1578",
  ["key_1579"] = "停驻_1579",
  ["key_1580"] = "恐惧_1580",
  ["key_1581"] = "涌浪_1581",
  ["key_1582"] = "闪电_1582",
  ["key_1583"] = "故障_1583",
  ["key_1584"] = "蒂莫西_1584",
  ["key_1585"] = "杰克_1585",
  ["key_1586"] = "影子_1586",
  ["key_1587"] = "搜寻_1587",
  ["key_1588"] = "人脸_1588",
  ["key_1589"] = "陷阱_1589",
  ["key_1590"] = "分身_1590",
  ["key_1591"] = "傻笑_1591",
  ["key_1592"] = "窗户_1592",
  ["key_1593"] = "加速_1593",
  ["key_1594"] = "吱嘎_1594",
  ["key_1595"] = "哥布林_1595",
  ["key_1596"] = "杰夫_1596",
  ["key_1597"] = "鲍勃_1597",
  ["key_1598"] = "门_1598",
  ["key_1599"] = "箱子_1599",
  ["key_1600"] = "物品_1600",
  ["key_1601"] = "房间_1601",
  ["key_1602"] = "钥匙_1602",
  ["key_1603"] = "出口_1603",
  ["key_1604"] = "躲藏_1604",
  ["key_1605"] = "时间_1605",
  ["key_1606"] = "速度_1606",
  ["key_1607"] = "开启_1607",
  ["key_1608"] = "关闭_1608",
  ["key_1609"] = "显示_1609",
  ["key_1610"] = "玩家_1610",
  ["key_1611"] = "开关_1611",
  ["key_1612"] = "距离_1612",
  ["key_1613"] = "自动_1613",
  ["key_1614"] = "飞行_1614",
  ["key_1615"] = "跳跃_1615",
  ["key_1616"] = "滑行_1616",
  ["key_1617"] = "解锁_1617",
  ["key_1618"] = "使用_1618",
  ["key_1619"] = "生成_1619",
  ["key_1620"] = "实体_1620",
  ["key_1621"] = "噪音_1621",
  ["key_1622"] = "冲刺_1622",
  ["key_1623"] = "伏击_1623",
  ["key_1624"] = "眼睛_1624",
  ["key_1625"] = "尖啸_1625",
  ["key_1626"] = "停驻_1626",
  ["key_1627"] = "恐惧_1627",
  ["key_1628"] = "涌浪_1628",
  ["key_1629"] = "闪电_1629",
  ["key_1630"] = "故障_1630",
  ["key_1631"] = "蒂莫西_1631",
  ["key_1632"] = "杰克_1632",
  ["key_1633"] = "影子_1633",
  ["key_1634"] = "搜寻_1634",
  ["key_1635"] = "人脸_1635",
  ["key_1636"] = "陷阱_1636",
  ["key_1637"] = "分身_1637",
  ["key_1638"] = "傻笑_1638",
  ["key_1639"] = "窗户_1639",
  ["key_1640"] = "加速_1640",
  ["key_1641"] = "吱嘎_1641",
  ["key_1642"] = "哥布林_1642",
  ["key_1643"] = "杰夫_1643",
  ["key_1644"] = "鲍勃_1644",
  ["key_1645"] = "门_1645",
  ["key_1646"] = "箱子_1646",
  ["key_1647"] = "物品_1647",
  ["key_1648"] = "房间_1648",
  ["key_1649"] = "钥匙_1649",
  ["key_1650"] = "出口_1650",
  ["key_1651"] = "躲藏_1651",
  ["key_1652"] = "时间_1652",
  ["key_1653"] = "速度_1653",
  ["key_1654"] = "开启_1654",
  ["key_1655"] = "关闭_1655",
  ["key_1656"] = "显示_1656",
  ["key_1657"] = "玩家_1657",
  ["key_1658"] = "开关_1658",
  ["key_1659"] = "距离_1659",
  ["key_1660"] = "自动_1660",
  ["key_1661"] = "飞行_1661",
  ["key_1662"] = "跳跃_1662",
  ["key_1663"] = "滑行_1663",
  ["key_1664"] = "解锁_1664",
  ["key_1665"] = "使用_1665",
  ["key_1666"] = "生成_1666",
  ["key_1667"] = "实体_1667",
  ["key_1668"] = "噪音_1668",
  ["key_1669"] = "冲刺_1669",
  ["key_1670"] = "伏击_1670",
  ["key_1671"] = "眼睛_1671",
  ["key_1672"] = "尖啸_1672",
  ["key_1673"] = "停驻_1673",
  ["key_1674"] = "恐惧_1674",
  ["key_1675"] = "涌浪_1675",
  ["key_1676"] = "闪电_1676",
  ["key_1677"] = "故障_1677",
  ["key_1678"] = "蒂莫西_1678",
  ["key_1679"] = "杰克_1679",
  ["key_1680"] = "影子_1680",
  ["key_1681"] = "搜寻_1681",
  ["key_1682"] = "人脸_1682",
  ["key_1683"] = "陷阱_1683",
  ["key_1684"] = "分身_1684",
  ["key_1685"] = "傻笑_1685",
  ["key_1686"] = "窗户_1686",
  ["key_1687"] = "加速_1687",
  ["key_1688"] = "吱嘎_1688",
  ["key_1689"] = "哥布林_1689",
  ["key_1690"] = "杰夫_1690",
  ["key_1691"] = "鲍勃_1691",
  ["key_1692"] = "门_1692",
  ["key_1693"] = "箱子_1693",
  ["key_1694"] = "物品_1694",
  ["key_1695"] = "房间_1695",
  ["key_1696"] = "钥匙_1696",
  ["key_1697"] = "出口_1697",
  ["key_1698"] = "躲藏_1698",
  ["key_1699"] = "时间_1699",
  ["key_1700"] = "速度_1700",
  ["key_1701"] = "开启_1701",
  ["key_1702"] = "关闭_1702",
  ["key_1703"] = "显示_1703",
  ["key_1704"] = "玩家_1704",
  ["key_1705"] = "开关_1705",
  ["key_1706"] = "距离_1706",
  ["key_1707"] = "自动_1707",
  ["key_1708"] = "飞行_1708",
  ["key_1709"] = "跳跃_1709",
  ["key_1710"] = "滑行_1710",
  ["key_1711"] = "解锁_1711",
  ["key_1712"] = "使用_1712",
  ["key_1713"] = "生成_1713",
  ["key_1714"] = "实体_1714",
  ["key_1715"] = "噪音_1715",
  ["key_1716"] = "冲刺_1716",
  ["key_1717"] = "伏击_1717",
  ["key_1718"] = "眼睛_1718",
  ["key_1719"] = "尖啸_1719",
  ["key_1720"] = "停驻_1720",
  ["key_1721"] = "恐惧_1721",
  ["key_1722"] = "涌浪_1722",
  ["key_1723"] = "闪电_1723",
  ["key_1724"] = "故障_1724",
  ["key_1725"] = "蒂莫西_1725",
  ["key_1726"] = "杰克_1726",
  ["key_1727"] = "影子_1727",
  ["key_1728"] = "搜寻_1728",
  ["key_1729"] = "人脸_1729",
  ["key_1730"] = "陷阱_1730",
  ["key_1731"] = "分身_1731",
  ["key_1732"] = "傻笑_1732",
  ["key_1733"] = "窗户_1733",
  ["key_1734"] = "加速_1734",
  ["key_1735"] = "吱嘎_1735",
  ["key_1736"] = "哥布林_1736",
  ["key_1737"] = "杰夫_1737",
  ["key_1738"] = "鲍勃_1738",
  ["key_1739"] = "门_1739",
  ["key_1740"] = "箱子_1740",
  ["key_1741"] = "物品_1741",
  ["key_1742"] = "房间_1742",
  ["key_1743"] = "钥匙_1743",
  ["key_1744"] = "出口_1744",
  ["key_1745"] = "躲藏_1745",
  ["key_1746"] = "时间_1746",
  ["key_1747"] = "速度_1747",
  ["key_1748"] = "开启_1748",
  ["key_1749"] = "关闭_1749",
  ["key_1750"] = "显示_1750",
  ["key_1751"] = "玩家_1751",
  ["key_1752"] = "开关_1752",
  ["key_1753"] = "距离_1753",
  ["key_1754"] = "自动_1754",
  ["key_1755"] = "飞行_1755",
  ["key_1756"] = "跳跃_1756",
  ["key_1757"] = "滑行_1757",
  ["key_1758"] = "解锁_1758",
  ["key_1759"] = "使用_1759",
  ["key_1760"] = "生成_1760",
  ["key_1761"] = "实体_1761",
  ["key_1762"] = "噪音_1762",
  ["key_1763"] = "冲刺_1763",
  ["key_1764"] = "伏击_1764",
  ["key_1765"] = "眼睛_1765",
  ["key_1766"] = "尖啸_1766",
  ["key_1767"] = "停驻_1767",
  ["key_1768"] = "恐惧_1768",
  ["key_1769"] = "涌浪_1769",
  ["key_1770"] = "闪电_1770",
  ["key_1771"] = "故障_1771",
  ["key_1772"] = "蒂莫西_1772",
  ["key_1773"] = "杰克_1773",
  ["key_1774"] = "影子_1774",
  ["key_1775"] = "搜寻_1775",
  ["key_1776"] = "人脸_1776",
  ["key_1777"] = "陷阱_1777",
  ["key_1778"] = "分身_1778",
  ["key_1779"] = "傻笑_1779",
  ["key_1780"] = "窗户_1780",
  ["key_1781"] = "加速_1781",
  ["key_1782"] = "吱嘎_1782",
  ["key_1783"] = "哥布林_1783",
  ["key_1784"] = "杰夫_1784",
  ["key_1785"] = "鲍勃_1785",
  ["key_1786"] = "门_1786",
  ["key_1787"] = "箱子_1787",
  ["key_1788"] = "物品_1788",
  ["key_1789"] = "房间_1789",
  ["key_1790"] = "钥匙_1790",
  ["key_1791"] = "出口_1791",
  ["key_1792"] = "躲藏_1792",
  ["key_1793"] = "时间_1793",
  ["key_1794"] = "速度_1794",
  ["key_1795"] = "开启_1795",
  ["key_1796"] = "关闭_1796",
  ["key_1797"] = "显示_1797",
  ["key_1798"] = "玩家_1798",
  ["key_1799"] = "开关_1799",
  ["key_1800"] = "距离_1800",
  ["key_1801"] = "自动_1801",
  ["key_1802"] = "飞行_1802",
  ["key_1803"] = "跳跃_1803",
  ["key_1804"] = "滑行_1804",
  ["key_1805"] = "解锁_1805",
  ["key_1806"] = "使用_1806",
  ["key_1807"] = "生成_1807",
  ["key_1808"] = "实体_1808",
  ["key_1809"] = "噪音_1809",
  ["key_1810"] = "冲刺_1810",
  ["key_1811"] = "伏击_1811",
  ["key_1812"] = "眼睛_1812",
  ["key_1813"] = "尖啸_1813",
  ["key_1814"] = "停驻_1814",
  ["key_1815"] = "恐惧_1815",
  ["key_1816"] = "涌浪_1816",
  ["key_1817"] = "闪电_1817",
  ["key_1818"] = "故障_1818",
  ["key_1819"] = "蒂莫西_1819",
  ["key_1820"] = "杰克_1820",
  ["key_1821"] = "影子_1821",
  ["key_1822"] = "搜寻_1822",
  ["key_1823"] = "人脸_1823",
  ["key_1824"] = "陷阱_1824",
  ["key_1825"] = "分身_1825",
  ["key_1826"] = "傻笑_1826",
  ["key_1827"] = "窗户_1827",
  ["key_1828"] = "加速_1828",
  ["key_1829"] = "吱嘎_1829",
  ["key_1830"] = "哥布林_1830",
  ["key_1831"] = "杰夫_1831",
  ["key_1832"] = "鲍勃_1832",
  ["key_1833"] = "门_1833",
  ["key_1834"] = "箱子_1834",
  ["key_1835"] = "物品_1835",
  ["key_1836"] = "房间_1836",
  ["key_1837"] = "钥匙_1837",
  ["key_1838"] = "出口_1838",
  ["key_1839"] = "躲藏_1839",
  ["key_1840"] = "时间_1840",
  ["key_1841"] = "速度_1841",
  ["key_1842"] = "开启_1842",
  ["key_1843"] = "关闭_1843",
  ["key_1844"] = "显示_1844",
  ["key_1845"] = "玩家_1845",
  ["key_1846"] = "开关_1846",
  ["key_1847"] = "距离_1847",
  ["key_1848"] = "自动_1848",
  ["key_1849"] = "飞行_1849",
  ["key_1850"] = "跳跃_1850",
  ["key_1851"] = "滑行_1851",
  ["key_1852"] = "解锁_1852",
  ["key_1853"] = "使用_1853",
  ["key_1854"] = "生成_1854",
  ["key_1855"] = "实体_1855",
  ["key_1856"] = "噪音_1856",
  ["key_1857"] = "冲刺_1857",
  ["key_1858"] = "伏击_1858",
  ["key_1859"] = "眼睛_1859",
  ["key_1860"] = "尖啸_1860",
  ["key_1861"] = "停驻_1861",
  ["key_1862"] = "恐惧_1862",
  ["key_1863"] = "涌浪_1863",
  ["key_1864"] = "闪电_1864",
  ["key_1865"] = "故障_1865",
  ["key_1866"] = "蒂莫西_1866",
  ["key_1867"] = "杰克_1867",
  ["key_1868"] = "影子_1868",
  ["key_1869"] = "搜寻_1869",
  ["key_1870"] = "人脸_1870",
  ["key_1871"] = "陷阱_1871",
  ["key_1872"] = "分身_1872",
  ["key_1873"] = "傻笑_1873",
  ["key_1874"] = "窗户_1874",
  ["key_1875"] = "加速_1875",
  ["key_1876"] = "吱嘎_1876",
  ["key_1877"] = "哥布林_1877",
  ["key_1878"] = "杰夫_1878",
  ["key_1879"] = "鲍勃_1879",
  ["key_1880"] = "门_1880",
  ["key_1881"] = "箱子_1881",
  ["key_1882"] = "物品_1882",
  ["key_1883"] = "房间_1883",
  ["key_1884"] = "钥匙_1884",
  ["key_1885"] = "出口_1885",
  ["key_1886"] = "躲藏_1886",
  ["key_1887"] = "时间_1887",
  ["key_1888"] = "速度_1888",
  ["key_1889"] = "开启_1889",
  ["key_1890"] = "关闭_1890",
  ["key_1891"] = "显示_1891",
  ["key_1892"] = "玩家_1892",
  ["key_1893"] = "开关_1893",
  ["key_1894"] = "距离_1894",
  ["key_1895"] = "自动_1895",
  ["key_1896"] = "飞行_1896",
  ["key_1897"] = "跳跃_1897",
  ["key_1898"] = "滑行_1898",
  ["key_1899"] = "解锁_1899",
  ["key_1900"] = "使用_1900",
  ["key_1901"] = "生成_1901",
  ["key_1902"] = "实体_1902",
  ["key_1903"] = "噪音_1903",
  ["key_1904"] = "冲刺_1904",
  ["key_1905"] = "伏击_1905",
  ["key_1906"] = "眼睛_1906",
  ["key_1907"] = "尖啸_1907",
  ["key_1908"] = "停驻_1908",
  ["key_1909"] = "恐惧_1909",
  ["key_1910"] = "涌浪_1910",
  ["key_1911"] = "闪电_1911",
  ["key_1912"] = "故障_1912",
  ["key_1913"] = "蒂莫西_1913",
  ["key_1914"] = "杰克_1914",
  ["key_1915"] = "影子_1915",
  ["key_1916"] = "搜寻_1916",
  ["key_1917"] = "人脸_1917",
  ["key_1918"] = "陷阱_1918",
  ["key_1919"] = "分身_1919",
  ["key_1920"] = "傻笑_1920",
  ["key_1921"] = "窗户_1921",
  ["key_1922"] = "加速_1922",
  ["key_1923"] = "吱嘎_1923",
  ["key_1924"] = "哥布林_1924",
  ["key_1925"] = "杰夫_1925",
  ["key_1926"] = "鲍勃_1926",
  ["key_1927"] = "门_1927",
  ["key_1928"] = "箱子_1928",
  ["key_1929"] = "物品_1929",
  ["key_1930"] = "房间_1930",
  ["key_1931"] = "钥匙_1931",
  ["key_1932"] = "出口_1932",
  ["key_1933"] = "躲藏_1933",
  ["key_1934"] = "时间_1934",
  ["key_1935"] = "速度_1935",
  ["key_1936"] = "开启_1936",
  ["key_1937"] = "关闭_1937",
  ["key_1938"] = "显示_1938",
  ["key_1939"] = "玩家_1939",
  ["key_1940"] = "开关_1940",
  ["key_1941"] = "距离_1941",
  ["key_1942"] = "自动_1942",
  ["key_1943"] = "飞行_1943",
  ["key_1944"] = "跳跃_1944",
  ["key_1945"] = "滑行_1945",
  ["key_1946"] = "解锁_1946",
  ["key_1947"] = "使用_1947",
  ["key_1948"] = "生成_1948",
  ["key_1949"] = "实体_1949",
  ["key_1950"] = "噪音_1950",
  ["key_1951"] = "冲刺_1951",
  ["key_1952"] = "伏击_1952",
  ["key_1953"] = "眼睛_1953",
  ["key_1954"] = "尖啸_1954",
  ["key_1955"] = "停驻_1955",
  ["key_1956"] = "恐惧_1956",
  ["key_1957"] = "涌浪_1957",
  ["key_1958"] = "闪电_1958",
  ["key_1959"] = "故障_1959",
  ["key_1960"] = "蒂莫西_1960",
  ["key_1961"] = "杰克_1961",
  ["key_1962"] = "影子_1962",
  ["key_1963"] = "搜寻_1963",
  ["key_1964"] = "人脸_1964",
  ["key_1965"] = "陷阱_1965",
  ["key_1966"] = "分身_1966",
  ["key_1967"] = "傻笑_1967",
  ["key_1968"] = "窗户_1968",
  ["key_1969"] = "加速_1969",
  ["key_1970"] = "吱嘎_1970",
  ["key_1971"] = "哥布林_1971",
  ["key_1972"] = "杰夫_1972",
  ["key_1973"] = "鲍勃_1973",
  ["key_1974"] = "门_1974",
  ["key_1975"] = "箱子_1975",
  ["key_1976"] = "物品_1976",
  ["key_1977"] = "房间_1977",
  ["key_1978"] = "钥匙_1978",
  ["key_1979"] = "出口_1979",
  ["key_1980"] = "躲藏_1980",
  ["key_1981"] = "时间_1981",
  ["key_1982"] = "速度_1982",
  ["key_1983"] = "开启_1983",
  ["key_1984"] = "关闭_1984",
  ["key_1985"] = "显示_1985",
  ["key_1986"] = "玩家_1986",
  ["key_1987"] = "开关_1987",
  ["key_1988"] = "距离_1988",
  ["key_1989"] = "自动_1989",
  ["key_1990"] = "飞行_1990",
  ["key_1991"] = "跳跃_1991",
  ["key_1992"] = "滑行_1992",
  ["key_1993"] = "解锁_1993",
  ["key_1994"] = "使用_1994",
  ["key_1995"] = "生成_1995",
  ["key_1996"] = "实体_1996",
  ["key_1997"] = "噪音_1997",
  ["key_1998"] = "冲刺_1998",
  ["key_1999"] = "伏击_1999",
  ["key_2000"] = "眼睛_2000",
  ["key_2001"] = "尖啸_2001",
  ["key_2002"] = "停驻_2002",
  ["key_2003"] = "恐惧_2003",
  ["key_2004"] = "涌浪_2004",
  ["key_2005"] = "闪电_2005",
  ["key_2006"] = "故障_2006",
  ["key_2007"] = "蒂莫西_2007",
  ["key_2008"] = "杰克_2008",
  ["key_2009"] = "影子_2009",
  ["key_2010"] = "搜寻_2010",
  ["key_2011"] = "人脸_2011",
  ["key_2012"] = "陷阱_2012",
  ["key_2013"] = "分身_2013",
  ["key_2014"] = "傻笑_2014",
  ["key_2015"] = "窗户_2015",
  ["key_2016"] = "加速_2016",
  ["key_2017"] = "吱嘎_2017",
  ["key_2018"] = "哥布林_2018",
  ["key_2019"] = "杰夫_2019",
  ["key_2020"] = "鲍勃_2020",
  ["key_2021"] = "门_2021",
  ["key_2022"] = "箱子_2022",
  ["key_2023"] = "物品_2023",
  ["key_2024"] = "房间_2024",
  ["key_2025"] = "钥匙_2025",
  ["key_2026"] = "出口_2026",
  ["key_2027"] = "躲藏_2027",
  ["key_2028"] = "时间_2028",
  ["key_2029"] = "速度_2029",
  ["key_2030"] = "开启_2030",
  ["key_2031"] = "关闭_2031",
  ["key_2032"] = "显示_2032",
  ["key_2033"] = "玩家_2033",
  ["key_2034"] = "开关_2034",
  ["key_2035"] = "距离_2035",
  ["key_2036"] = "自动_2036",
  ["key_2037"] = "飞行_2037",
  ["key_2038"] = "跳跃_2038",
  ["key_2039"] = "滑行_2039",
  ["key_2040"] = "解锁_2040",
  ["key_2041"] = "使用_2041",
  ["key_2042"] = "生成_2042",
  ["key_2043"] = "实体_2043",
  ["key_2044"] = "噪音_2044",
  ["key_2045"] = "冲刺_2045",
  ["key_2046"] = "伏击_2046",
  ["key_2047"] = "眼睛_2047",
  ["key_2048"] = "尖啸_2048",
  ["key_2049"] = "停驻_2049",
  ["key_2050"] = "恐惧_2050",
  ["key_2051"] = "涌浪_2051",
  ["key_2052"] = "闪电_2052",
  ["key_2053"] = "故障_2053",
  ["key_2054"] = "蒂莫西_2054",
  ["key_2055"] = "杰克_2055",
  ["key_2056"] = "影子_2056",
  ["key_2057"] = "搜寻_2057",
  ["key_2058"] = "人脸_2058",
  ["key_2059"] = "陷阱_2059",
  ["key_2060"] = "分身_2060",
  ["key_2061"] = "傻笑_2061",
  ["key_2062"] = "窗户_2062",
  ["key_2063"] = "加速_2063",
  ["key_2064"] = "吱嘎_2064",
  ["key_2065"] = "哥布林_2065",
  ["key_2066"] = "杰夫_2066",
  ["key_2067"] = "鲍勃_2067",
  ["key_2068"] = "门_2068",
  ["key_2069"] = "箱子_2069",
  ["key_2070"] = "物品_2070",
  ["key_2071"] = "房间_2071",
  ["key_2072"] = "钥匙_2072",
  ["key_2073"] = "出口_2073",
  ["key_2074"] = "躲藏_2074",
  ["key_2075"] = "时间_2075",
  ["key_2076"] = "速度_2076",
  ["key_2077"] = "开启_2077",
  ["key_2078"] = "关闭_2078",
}

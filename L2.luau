local _CN = {}
local function _L(s) local v = _CN[s]; if v ~= nil then return v end return s end

--	Functions.Notify({Title = _L("Used For Notifications.")})
-- 	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
-- 	Risky = Floor ~= _L("Mines") (Means it only works on mines)

local LoadStart = tick()

if shared.Hastelepasta then
    return 
end

shared.Hastelepasta = true


getgenv().Abysall = {
    Legit = true
}


local BaseUrl = _L("https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/")

getgenv().Abysall = {
    Environment = loadstring(game:HttpGet(BaseUrl .. _L("Components/Environment.luau")))(),
    ESPLibrary = loadstring(game:HttpGet(BaseUrl .. _L("Components/ESP.luau")))(),
    [_L("16Notice")] = loadstring(game:HttpGet(BaseUrl .. _L("Components/16Notice.luau")))(),
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
    if not Abysall.Environment.isfile(_L("Abysall/UserData.json")) then
        local Data = {
            TotalExecutions = 0,
            UILibrary = _L("Obsidian")
        }

        Abysall.Environment.writefile(
            _L("Abysall/UserData.json"),
            Services.HttpService:JSONEncode(Data)
        )
    end

    local UserData = Abysall.Environment.readfile(_L("Abysall/UserData.json"))
    local Decoded = Services.HttpService:JSONDecode(UserData)

    if not Decoded.TotalExecutions then
        Decoded.TotalExecutions = 0
    end

    Decoded.TotalExecutions = Decoded.TotalExecutions + 1

    if not Decoded.UILibrary then
        Decoded.UILibrary = _L("Obsidian")
    end

    Abysall.TotalExecutions = Decoded.TotalExecutions
    Abysall.UILibrary = Decoded.UILibrary

    Abysall.Environment.writefile(
        _L("Abysall/UserData.json"),
        Services.HttpService:JSONEncode(Decoded)
    )
end

Abysall.Interface = loadstring(game:HttpGet(
    BaseUrl .. _L("Components/Interface.luau")
))()

Abysall.Analytics = loadstring(game:HttpGet(
    BaseUrl .. _L("Components/Analytics.luau")
))()


Abysall.SavePath = _L("Doors/Game")

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

Globals.IncompatibleMessage = _L("Your executor doesn't support this feature.")

Functions.CheckCompatability = function(Array)
	for _, Name in Array do
		if not Abysall.Environment[Name] then
			return false
		end
	end
	return true
end



local LocalPlayer = Services.Players.LocalPlayer


local PortraitName = _L("MirrorRig_Portrait_") .. LocalPlayer.Name


local Entities = {
	[_L("TV_Stand")] = {
		Alias = _L("Noise_TV"),
		NotifyMessage = { Title = _L("Noise tv spawned."), Body = _L("Dont get near it") }
	},
	[PortraitName] = {
		Alias = _L("Portrait"),
		NotifyMessage = { Title = _L("Portrait' has spawned."), Body = _L("Use him to duplicate items.") }
	},
	[_L("StemsEntity")] = {
	    Alias = 'Balls',
		NotifyMessage = { Title = _L("Balls"), Body = _L("Balls.")}
	},
	[_L("NoiseModel")] = {
		Alias = 'Noise',
		NotifyMessage = { Title = _L("Entity 'Noise' has spawned."), Body = _L("Dont let it touch you.") }
	},
	[_L("Creak")] = {
		Alias = _L("Creak"),
		NotifyMessage = { Title = _L("Entity 'Creak' has spawned."), Body = _L("Dont touch him.") }
	},
	[_L("DronesStampede")] = {
		Alias = _L("DronesStampede"),
		NotifyMessage = { Title = _L("Entity 'Drones Stampede' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("TellerRig")] = {
		Alias = _L("Teller"),
		NotifyMessage = { Title = _L("Entity 'Teller' has spawned."), Body = _L("Dont worry, hes only annoying.") }
	},
	[_L("Scribbles")] = {
		Alias = _L("Scribbles"),
		NotifyMessage = { Title = _L("Entity 'Scribbles' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("BashMoving")] = {
		Alias = _L("Bash"),
		NotifyMessage = { Title = _L("Entity 'Bash' has spawned."), Body = _L("Find a hiding spot.")}
	},
	[_L("RushMoving")] = {
		Alias = _L("Rush"),
		NotifyMessage = { Title = _L("Entity 'Rush' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("AmbushMoving")] = {
		Alias = _L("Ambush"),
		NotifyMessage = { Title = _L("Entity 'Ambush' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("Eyes")] = {
		Alias = _L("Eyes"),
		NotifyMessage = { Title = _L("Entity 'Eyes' has spawned."), Body = _L("Avoid looking at it.") }
	},
	[_L("Lookman")] = {
		Alias = _L("Eyes"),
		NotifyMessage = { Title = _L("Entity 'Eyes' has spawned."), Body = _L("Avoid looking at it.") }
	},
	[_L("BackdoorRush")] = {
		Alias = _L("Blitz"),
		NotifyMessage = { Title = _L("Entity 'Blitz' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("BackdoorLookman")] = {
		Alias = _L("Lookman"),
		NotifyMessage = { Title = _L("Entity 'Lookman' has spawned."), Body = _L("Avoid looking at its eyes.") }
	},
	[_L("Groundskeeper")] = {
		Alias = _L("Groundskeeper"),
		NotifyMessage = { Title = _L("Entity 'Groundskeeper' has spawned."), Body = _L("Avoid stepping on the grass.") }
	},
	[_L("A60")] = {
		Alias = _L("A-60"),
		NotifyMessage = { Title = _L("Entity 'A-60' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("A120")] = {
		Alias = _L("A-120"),
		NotifyMessage = { Title = _L("Entity 'A-120' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("GloombatSwarm")] = {
		Alias = _L("Gloombat Swarm"),
		NotifyMessage = { Title = _L("Entity 'Gloombat Swarm' has spawned."), Body = _L("Keep all light sources turned off.") }
	},
	[_L("GlitchRush")] = {
		Alias = _L("RNIUSHCG=="),
		NotifyMessage = { Title = _L("Entity 'RNIUSHCG==' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("GlitchAmbush")] = {
		Alias = _L("AR0xMBUSH"),
		NotifyMessage = { Title = _L("Entity 'AR0xMBUSH' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("MonumentEntity")] = {
		Alias = _L("Monument"),
		NotifyMessage = { Title = _L("Entity 'Monument' has spawned."), Body = _L("It can't move while you are looking at it.") }
	},
	[_L("JeffTheKiller")] = {
		Alias = _L("Jeff the Killer"),
		NotifyMessage = { Title = _L("Entity 'Jeff the Killer' has spawned."), Body = _L("Avoid touching him.") }
	},
	[_L("CustomEntity")] = {
		Alias = _L("Custom Entity"),
		NotifyMessage = { Title = _L("Entity 'Custom Entity' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("FrozenAmbush")] = {
		Alias = _L("Frozen Ambush"),
		NotifyMessage = { Title = _L("Entity 'Frozen Ambush' has spawned."), Body = _L("Find a hiding spot.") }
	},
	[_L("SallyMoving")] = {
		Alias = _L("Sally"),
		NotifyMessage = { Title = _L("Entity 'Sally' has spawned."), Body = _L("Find her horse and rop it.") }
	}
}

local EntityIcons = {
	[_L("RushMoving")]      = _L("rbxassetid://10716032262"),
	[_L("AmbushMoving")]    = _L("rbxassetid://10110576663"),
	[_L("A60")]             = _L("rbxassetid://12571092295"),
	[_L("A120")]            = _L("rbxassetid://12711591665"),
	[_L("BackdoorRush")]    = _L("rbxassetid://16602023490"),
	[_L("Eyes")]            = _L("rbxassetid://10183704772"),
	[_L("Lookman")]         = _L("rbxassetid://10183704772"),
	[_L("BackdoorLookman")] = _L("rbxassetid://16764872677"),
	[_L("GloombatSwarm")]   = _L("rbxassetid://79221203116470"),
	[_L("Halt")]            = _L("rbxassetid://11331795398"),
	[_L("JeffTheKiller")]   = _L("rbxassetid://94479432156278"),
	[_L("GlitchRush")]      = _L("rbxassetid://73859273102919"),
	[_L("GlitchAmbush")]    = _L("rbxassetid://88369678433359"),
	[_L("SallyMoving")]     = _L("rbxassetid://10840888070"),
	[_L("MonumentEntity")]  = _L("rbxassetid://88933556873017"),
	[_L("Groundskeeper")]   = _L("rbxassetid://114991380115557")
}

local ItemNames = {
	[_L("AbrahamHat")]        = _L("Hat"),
	[_L("LargeScrew")]        = _L("Screw"),
	[_L("DinkyLamp")]         = _L("Lamp"),
	[_L("BottleCrate")]       = _L("18+ Bottles"),
	[_L("GweenSodaPack")]     = _L("Gween Soda Pack"),
	[_L("BrokenMonitor")]     = _L("Broken Monitor"),
	[_L("JerryCan")]          = _L("Jerry Can"),
 	[_L("SallyToyObtain")]    = _L("Sally Toy"),
	[_L("Leftovers")]         = _L("Lunch Box"),
	[_L("HoneyPot")]          = _L("Honey Pot"),
	[_L("FihFlakes")]         = _L("Fih Food"),
	[_L("SecretCD")]          = _L("CD Disc"),
	[_L("Pizza")]             = _L("Pizza"),
	[_L("PaperPlanePickup")]  = _L("Paper Plane"),
	[_L("Lighter")]           = _L("Lighter"),
	[_L("Flashlight")]        = _L("Flashlight"),
	[_L("Lockpick")]          = _L("Lockpicks"),
	[_L("Vitamins")]          = _L("Vitamins"),
	[_L("Bandage")]           = _L("Bandage"),
	[_L("StarVial")]          = _L("Starlight Vial"),
	[_L("StarBottle")]        = _L("Starlight Bottle"),
	[_L("StarJug")]           = _L("Starlight Barrel"),
	[_L("Shakelight")]        = _L("Gummy Flashlight"),
	[_L("Straplight")]        = _L("Straplight"),
	[_L("Bulklight")]         = _L("Spotlight"),
	[_L("Battery")]           = _L("Battery"),
	[_L("Candle")]            = _L("Candle"),
	[_L("Crucifix")]          = _L("Crucifix"),
	[_L("CrucifixWall")]      = _L("Crucifix"),
	[_L("Glowsticks")]        = _L("Glowstick"),
	[_L("SkeletonKey")]       = _L("Skeleton Key"),
	[_L("Candy")]             = _L("Candy"),
	[_L("ShieldMini")]        = _L("Mini Shield Potion"),
	[_L("ShieldBig")]         = _L("Big Shield Potion"),
	[_L("BandagePack")]       = _L("Bandage Pack"),
	[_L("BatteryPack")]       = _L("Battery Pack"),
	[_L("RiftCandle")]        = _L("Moonlight Candle"),
	[_L("LaserPointer")]      = _L("Laser Pointer"),
	[_L("HolyGrenade")]       = _L("Holy Hand Grenade"),
	[_L("Shears")]            = _L("Shears"),
	[_L("Smoothie")]          = _L("Smoothie"),
	[_L("Cheese")]            = _L("Cheese"),
	[_L("Bread")]             = _L("Bread"),
	[_L("AlarmClock")]        = _L("Alarm Clock"),
	[_L("RiftSmoothie")]      = _L("Moonlight Smoothie"),
	[_L("GweenSoda")]         = _L("Gween Soda"),
	[_L("GlitchCube")]        = _L("Glitch Fragment"),
	[_L("Scanner")]           = _L("Tablet"),
	[_L("Bomb")]              = _L("Bomb"),
	[_L("Knockbomb")]         = _L("Knockbomb"),
	[_L("Nanner")]            = _L("Nanner"),
	[_L("BigBomb")]           = _L("Big Bomb"),
	[_L("SnakeBox")]          = _L("Hiding Box"),
	[_L("GoldGun")]           = _L("Golden Gun"),
	[_L("StopSign")]          = _L("Stop Sign"),
	[_L("TipJar")]            = _L("Tip Jar"),
	[_L("Lantern")]           = _L("Lantern"),
	[_L("IronKey")]           = _L("Iron Key"),
	[_L("LotusPetal")]        = _L("Lotus Petal"),
	[_L("Compass")]           = _L("Compass"),
	[_L("LotusPetalPickup")]  = _L("Lotus Petal"),
	[_L("LanternLitItem")]    = _L("Lantern"),
	[_L("KeyIron")]           = _L("Iron Key"),
	[_L("IronKeyForCrypt")]   = _L("Iron Key"),
	[_L("LotusHolder")]       = _L("Lotus Petal"),
	[_L("Multitool")]         = _L("Multitool"),
	[_L("RiftJar")]           = _L("Rift Jar"),
	[_L("AloeVera")]          = _L("Aloe Vera"),
	[_L("Donut")]             = _L("Donut"),
	[_L("Lotus")]             = _L("Lotus"),
	[_L("BoxingGloves")]      = _L("Boxing Gloves")
}

local CutsceneNames = {
    _L("Figure"),
    _L("FigureEnd"),
    _L("FigureHotelEnd"),
    _L("FigureHotelFire"),
    _L("SeekIntroFools"),
    _L("SeekIntroHotel"),
    _L("SeekIntroMines"),
    _L("SeekIntroMines2"),
    _L("SerewSeekDrain"),
    _L("SewerSeekLower"),
    _L("GrumbleNestEnd"),
    _L("EyestalkIntro"),
}

local Character
local Humanoid
local RootPart

local Collision
local CollisionClone
local CollisionPart
local CollisionPartClone

local Camera

local RemotesFolder   = Services.ReplicatedStorage:FindFirstChild(_L("RemotesFolder"))
local LiveModifiers   = Services.ReplicatedStorage:FindFirstChild(_L("LiveModifiers"))
local FloorReplicated = Services.ReplicatedStorage:FindFirstChild(_L("FloorReplicated"))
local CurrentRooms    = Services.Workspace:FindFirstChild(_L("CurrentRooms"))
local Drops           = Services.Workspace:FindFirstChild(_L("Drops"))
local GameData        = Services.ReplicatedStorage:WaitForChild(_L("GameData"))
local Floor           = GameData:WaitForChild(_L("Floor")).Value
local LatestRoom      = GameData:WaitForChild(_L("LatestRoom"))
local FinishedLoadingRoom = GameData:FindFirstChild(_L("FinishedLoadingRoom"))
local RunService = game:GetService(_L("RunService"))

if FinishedLoadingRoom then
	FinishedLoadingRoom:Destroy()
end

local function GetHiddenContainer()
	if Functions.CheckCompatability({_L("gethui")}) then
		return Abysall.Environment.gethui()
	end
	return Services.CoreGui
end

local NotificationLibrary = {
	LiveNotifications = 0,
	Notifications = 1
}

local Container = Instance.new(_L("ScreenGui"))
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
		local Notification = Instance.new(_L("Frame"))
		local Line = Instance.new(_L("Frame"))
		local Warning = Instance.new(_L("ImageLabel"))
		local UICorner = Instance.new(_L("UICorner"))
		local UICorner2 = Instance.new(_L("UICorner"))
		local Title = Instance.new(_L("TextLabel"))
		local Description = Instance.new(_L("TextLabel"))

		Notification.Name = _L("Notification")
		Notification.Parent = Container
		Notification.BackgroundColor3 = Library.Scheme.BackgroundColor
		Notification.BackgroundTransparency = 0.4
		Notification.BorderSizePixel = 0
		Notification.Position = UDim2.new(1, 5, 0, 60 + (60 * NotificationLibrary.LiveNotifications))
		Notification.Size = UDim2.new(0, 420, 0, 50)
		Notification:SetAttribute(_L("ID"), NotificationLibrary.Notifications)
		Notification:SetAttribute(_L("CurrentPosition"), Notification.Position)

		Line.Name = _L("Line")
		Line.Parent = Notification
		Line.BackgroundColor3 = Library.Scheme.AccentColor
		Line.BorderSizePixel = 0
		Line.Position = UDim2.new(0, 0, 1, -3)
		Line.Size = UDim2.new(0, 0, 0, 3)

		Warning.Name = _L("Warning")
		Warning.Parent = Notification
		Warning.BackgroundTransparency = 1
		Warning.Position = UDim2.new(0, 10, 0, 5)
		Warning.Size = UDim2.new(0, 40, 0, 40)
		Warning.Image = _L("rbxassetid://3944668821")
		Warning.ImageColor3 = Library.Scheme.AccentColor
		Warning.ScaleType = Enum.ScaleType.Fit

		UICorner.CornerRadius = UDim.new(0, 20)
		UICorner.Parent = Warning

		UICorner2.CornerRadius = UDim.new(0, 4)
		UICorner2.Parent = Notification

		Title.Name = _L("Title")
		Title.Parent = Notification
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 60, 0.155, 0)
		Title.Size = UDim2.new(0, 205, 0, 15)
		Title.Text = TitleText or _L("...")
		Title.TextColor3 = Library.Scheme.FontColor
		Title.TextSize = 10
		Title.TextStrokeTransparency = 0.75
		Title.TextXAlignment = Enum.TextXAlignment.Left

		Description.Name = _L("Description")
		Description.Parent = Notification
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1
		Description.Position = UDim2.new(0, 60, 0.483, 0)
		Description.Size = UDim2.new(0, 205, 0, 18)
		Description.Text = Desc or _L("...")
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
		if typeof(Delay) == _L("Instance") then
			Delay.Destroying:Wait()
		else
			Services.TweenService:Create(
				Line,
				TweenInfo.new(Delay - 0.25, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(0, 400, 0, 3) }
			):Play()
			task.wait(Delay - 0.25)
		end

		Notification:SetAttribute(_L("Destroying"), true)

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 5, 0, Notification.Position.Y.Offset) }
		):Play()

		NotificationLibrary.LiveNotifications -= 1

		local NotifId = Notification:GetAttribute(_L("ID"))
		local NotifY = Notification:GetAttribute(_L("CurrentPosition")).Y.Offset

		for _, Object in Container:GetChildren() do
			if Object.Name == _L("Notification")
				and Object:GetAttribute(_L("ID"))
				and Object:GetAttribute(_L("ID")) > NotifId
				and Object:GetAttribute(_L("Destroying")) ~= true
				and Object.Position.Y.Offset ~= 60
			then
				local NewY = Object:GetAttribute(_L("CurrentPosition")).Y.Offset - 60
				Object:SetAttribute(_L("CurrentPosition"), UDim2.new(1, -450, 0, NewY))
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
		local Sound = Instance.new(_L("Sound"))
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

	local PlayerGui = LocalPlayer:WaitForChild(_L("PlayerGui"))
	local UIContainer = PlayerGui:FindFirstChild(_L("GlobalUI")) or PlayerGui:FindFirstChild(_L("MainUI"))
	if not UIContainer then return end

	local AchievementsHolder = UIContainer:FindFirstChild(_L("AchievementsHolder"))
	if not AchievementsHolder then return end

	local Achievement = AchievementsHolder.Achievement:Clone()
	Achievement.Size = UDim2.new(0, 0, 0, 0)
	Achievement.Frame.Position = UDim2.new(1.1, 0, 0, 0)
	Achievement.Name = _L("LiveAchievement")
	Achievement.Visible = true

	Achievement.Frame.TextLabel.Text = NotifyOptions.Style or _L("NOTIFICATION")
	Achievement.Frame.Details.Title.Text = NotifyOptions.Title or _L("Sem Título")
	Achievement.Frame.Details.Desc.Text = NotifyOptions.Description or _L("Sem Descrição")
	Achievement.Frame.Details.Reason.Text = NotifyOptions.Reason or _L("")
	Achievement.Frame.ImageLabel.Image = (NotifyOptions.Image ~= _L("") and NotifyOptions.Image) or _L("rbxassetid://6023426923")

	local Color = NotifyOptions.Color or Color3.new(1, 1, 1)
	Achievement.Frame.TextLabel.TextColor3 = Color
	Achievement.Frame.UIStroke.Color = Color
	Achievement.Frame.Glow.ImageColor3 = Color
	Achievement.Parent = AchievementsHolder

	PlaySound(AchievementsHolder, _L("rbxassetid://10469938989"), 1)

	task.spawn(function()
		Achievement:TweenSize(UDim2.new(1, 0, 0.2, 0), _L("In"), _L("Quad"), 0.8, true)
		task.wait(0.8)
		Achievement.Frame:TweenPosition(UDim2.new(0, 0, 0, 0), _L("Out"), _L("Quad"), 0.5, true)
		Services.TweenService:Create(
			Achievement.Frame.Glow,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ ImageTransparency = 1 }
		):Play()

		if typeof(NotifyOptions.Time) == _L("Instance") then
			NotifyOptions.Time.Destroying:Wait()
		else
			task.wait(NotifyOptions.Time or 5)
		end

		Achievement.Frame:TweenPosition(UDim2.new(1.1, 0, 0, 0), _L("In"), _L("Quad"), 0.5, true)
		task.wait(0.5)
		Achievement:TweenSize(UDim2.new(1, 0, -0.1, 0), _L("InOut"), _L("Quad"), 0.5, true)
		task.wait(0.5)
		Achievement:Destroy()
	end)
end

Globals.STX = loadstring(game:HttpGet(_L("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Components/STX.luau")))()
Functions.Notify = function(Settings)
	local HiddenContainer = GetHiddenContainer()

	if not Settings.Body then
		Settings.Body = _L("...")
	end

	if not Options.NotifyStyle or Options.NotifyStyle.Value == _L("Abysall") then
		local Sound = Instance.new(_L("Sound"), HiddenContainer)
		Sound.SoundId = _L("rbxassetid://8784885431")
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		NotificationLibrary:Notify(Settings.Title, Settings.Body, Settings.Time or 5)
	elseif Options.NotifyStyle.Value == _L("Doors") then
		local IsEntity = false
		local EntityName = _L("")
		for Index, Object in pairs(Entities) do
			if Object.NotifyMessage.Title == Settings.Title or Object.NotifyMessage.Body == Settings.Body then
				IsEntity = true
				EntityName = Index
			end
		end
		Globals.DoorsNotify({
			Title = _L("Abysall Hub"),
			Description = Settings.Title,
			Reason = Settings.Body,
			Style = IsEntity and _L("WARNING") or _L("NOTIFICATION"),
			Color = IsEntity and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 222, 189),
			Image = Settings.Image,
			Time = Settings.Time
		})
	elseif Options.NotifyStyle.Value == _L("STX") then
		local Sound = Instance.new(_L("Sound"), HiddenContainer)
		Sound.SoundId = _L("rbxassetid://4590657391")
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()

		if Settings.Image then
			Globals.STX:Notify(
				{Title = _L("Abysall Hub"), Description = Settings.Title .. _L("\\n") .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = _L("image")},
				{Image = Settings.Image, ImageColor = Color3.fromRGB(255, 255, 255)}
			)
		else
			Globals.STX:Notify(
				{Title = _L("Abysall Hub"), Description = Settings.Title .. _L("\\n") .. Settings.Body},
				{OutlineColor = Library.Scheme.AccentColor,Time = Settings.Time or 5, Type = _L("default")}
			)
		end
	else
		local Sound = Instance.new(_L("Sound"), HiddenContainer)
		Sound.SoundId = _L("rbxassetid://4590662766")
		Sound.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
		Sound.PlayOnRemove = true
		Sound:Destroy()
		Library:OldNotify({ Title = Settings.Title, Description = Settings.Body, Time = Settings.Time })
	end
end

Functions.Caption = function(Text, PlaySound)
	if typeof(PlaySound) ~= _L("boolean") then
		PlaySound = true
	end
	local CaptionValue = Instance.new(_L("NumberValue"))
	local Caption = Globals.MainUI:WaitForChild(_L("MainFrame")):WaitForChild(_L("Caption")):Clone()
	local CaptionSound = Globals.MainUI:WaitForChild(_L("Initiator")):WaitForChild(_L("Main_Game")):WaitForChild(_L("Reminder")):WaitForChild(_L("Caption"))
	local CaptionSoundClone = CaptionSound:Clone()
	CaptionSoundClone.Parent = CaptionSound.Parent
	CaptionSoundClone.Volume = 0.1

	Caption.Destroying:Connect(function()
		CaptionValue:Destroy()
	end)

	for _, Child in Globals.MainUI:GetChildren() do
		if Child.Name == _L("LiveCaption") then
			Child:Destroy()
		end
	end

	Caption.Parent = Globals.MainUI
	Caption.Visible = true
	Caption.Name = _L("LiveCaption")
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
	local MinutesText = Minutes < 10 and (_L("0") .. tostring(Minutes)) or tostring(Minutes)
	local SecondsText = Seconds < 10 and (_L("0") .. tostring(Seconds)) or tostring(Seconds)
	return MinutesText .. _L(":") .. SecondsText
end

Library.OldNotify = Library.Notify
Library.Notify = function(Data, Body, Time)
	Functions.Notify({ Title = Body, Time = Time or 5 })
end

if not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass(_L("Model")) then
	Functions.Notify({ Title = _L("Waiting for the game to load...") })
	while not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass(_L("Model")) do
		task.wait()
	end
	task.wait(4)
end

if not RemotesFolder then
	if Services.ReplicatedStorage:FindFirstChild(_L("EntityInfo")) then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild(_L("EntityInfo"))
	elseif Services.ReplicatedStorage:FindFirstChild(_L("Bricks")) then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild(_L("Bricks"))
	end
end

if Floor == _L("Hotel") and RemotesFolder.Name == _L("Bricks") then
	Floor = _L("OldHotel")
end

if not LiveModifiers then
	LiveModifiers = Instance.new(_L("Folder"))
end

if not FloorReplicated then
	FloorReplicated = Instance.new(_L("Folder"))
end

local FakeEvents = {
	Screech = Instance.new(_L("RemoteEvent")),
	Shade   = Instance.new(_L("RemoteEvent")),
	A90     = Instance.new(_L("RemoteEvent")),
	Surge   = Instance.new(_L("RemoteEvent")),
}

FakeEvents.Screech.Name  = _L("Screech")
FakeEvents.Shade.Name    = _L("ShadeResult")
FakeEvents.A90.Name      = _L("A90")
FakeEvents.Surge.Name    = _L("SurgeRemote")

FakeEvents.Screech_Real = RemotesFolder:WaitForChild(_L("Screech"))
FakeEvents.Shade_Real   = RemotesFolder:WaitForChild(_L("ShadeResult"))
FakeEvents.A90_Real     = RemotesFolder:FindFirstChild(_L("A90"))
FakeEvents.Surge_Real   = RemotesFolder:FindFirstChild(_L("SurgeRemote"))

if RemotesFolder:FindFirstChild(_L("FootstepRemoteThatWeNeed")) then
    local RealRemote = RemotesFolder:FindFirstChild(_L("FootstepRemoteThatWeNeed"))
    RealRemote:Destroy()

    local FakeRemote = Instance.new(_L("RemoteEvent"), RemotesFolder)
    FakeRemote.Name = _L("FootstepRemoteThatWeNeed")
end

Globals.FogInstances = {}
Globals.OldFog = Services.Lighting.FogEnd

for _, Object in Services.Lighting:GetChildren() do
	if Object:IsA(_L("Atmosphere")) then
		Object:SetAttribute(_L("Density_Old"), Object.Density)

		local AtmoConnection = Object:GetPropertyChangedSignal(_L("Density")):Connect(function()
			if Object.Density ~= 0 then
				Object:SetAttribute(_L("Density_Old"), Object.Density)
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

Globals.SeekNodesFolder = Instance.new(_L("Folder"), Services.Workspace)
Globals.SeekNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Globals.RoomsNodesFolder = Instance.new(_L("Folder"), Services.Workspace)
Globals.RoomsNodesFolder.Name = Abysall.ESPLibrary:GenerateRandomString()

Functions.SendChat = function(Message)
	local Folder = Services.ReplicatedStorage:FindFirstChild(_L("DefaultChatSystemEvents")) or Instance.new(_L("Folder"))
	local Event = Folder:FindFirstChild(_L("SayMessageRequest")) or Instance.new(_L("RemoteEvent"))
	Event:FireServer(Message, _L("All"))
	local Channel = (Services.TextChatService:FindFirstChild(_L("TextChannels")) and Services.TextChatService.TextChannels:FindFirstChild(_L("RBXGeneral"))) or Instance.new(_L("TextChannel"))
	Channel:SendAsync(Message)
end

Functions.IsCrouching = function()
	if Floor == _L("Fools") or Floor == _L("OldHotel") then
		return Character:GetAttribute(_L("Crouching"))
	end
	return CollisionPart.CollisionGroup == _L("PlayerCrouching")
end

Functions.GetInjuriesSpeed = function()
	return 0.075 * (Humanoid.MaxHealth - Humanoid.Health)
end

Functions.GetCurrentSpeed = function()
	local Speed = 15
	Speed += Character:GetAttribute(_L("SpeedBoost")) or 0
	Speed += Character:GetAttribute(_L("SpeedBoostBehind")) or 0
	Speed += Character:GetAttribute(_L("SpeedBoostExtra")) or 0
	Speed += (Floor == _L("Party") and 10 or 0)
	Speed += (LiveModifiers:FindFirstChild(_L("PlayerFast")) and 3 or 0)
	Speed += (LiveModifiers:FindFirstChild(_L("PlayerFaster")) and 6 or 0)
	Speed += (LiveModifiers:FindFirstChild(_L("PlayerFastest")) and 20 or 0)
	Speed -= (LiveModifiers:FindFirstChild(_L("PlayerSlow")) and 3 or 0)
	Speed -= (LiveModifiers:FindFirstChild(_L("PlayerSlowHealth")) and Functions.GetInjuriesSpeed() or 0)
	if Functions.IsCrouching() then
		if LiveModifiers:FindFirstChild(_L("PlayerCrouchSlow")) then
			Speed -= 8
		elseif LiveModifiers:FindFirstChild(_L("PlayerSlow")) then
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
	return _L("Oxygen: ") .. (math.floor(Oxygen * 10) / 10) .. _L("%")
end

Functions.IsHidePersistent = function()
	return Floor == _L("Mines")
		or Floor == _L("Ripple")
		or Floor == _L("Party")
		or LiveModifiers:FindFirstChild(_L("HideLevel2")) ~= nil
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
	[_L("RushMoving")]    = 85,
	[_L("Scribbles")]	  = 100,
	[_L("BashMoving")]    = 150,
	[_L("DronesStampede")] = 100,
	[_L("AmbushMoving")]  = 150,
	[_L("A60")]           = 125,
	[_L("A120")]          = 85,
	[_L("GlitchRush")]    = 90,
	[_L("GlitchAmbush")]  = 175,
	[_L("BackdoorRush")]  = 85,
	[_L("CustomEntity")]  = 85,
}

Functions.GetNearestEntity = function(CheckDisabled, List, UseRaycasting)
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Entity in Objects.Entities do
		if not Entity or not Entity:IsA(_L("Model")) or not Entity:IsDescendantOf(Services.Workspace) then continue end
		if not EntityDistances[Entity.Name] or not Entity.PrimaryPart then continue end

		local EntityData = Entities[Entity.Name]
		if not EntityData then continue end
		if List and List[EntityData.Alias] then continue end

		local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if Distance < EntityDistances[Entity.Name] and Distance < Nearest.Distance then
			if not CheckDisabled or Entity:GetAttribute(_L("Inactive")) ~= true then
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
		if Object:IsA(_L("Model")) and Object.PrimaryPart and FigureNames[Object.Name] then
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
	local LastHideSpot = Character:FindFirstChild(_L("LastHideSpot"))

	local function IsHidingSpotName(Name)
		if typeof(Name) ~= _L("string") then return false end
		return string.find(string.lower(Name), _L("hidingspot")) or string.find(string.lower(Name), _L("hiding_spot"))
	end

	local function GetHidePrompt(Object)
	if not Object then return nil end

	local Prompt = Object:FindFirstChild(_L("HidePrompt")) or Object:FindFirstChild(_L("HidingPrompt"))
	if Prompt then return Prompt end

	for _, Child in Object:GetDescendants() do
		if (Child:IsA(_L("ProximityPrompt")) or Child:IsA(_L("InteractPrompt")))
			and (Child.Name == _L("HidePrompt") or Child.Name == _L("HidingPrompt") or IsHidingSpotName(Child.Name))
		then
			return Child
		end
	end

	if IsHidingSpotName(Object.Name) or IsHidingSpotName(Object.Parent and Object.Parent.Name) then
		return Object:FindFirstChild(_L("HidePrompt")) or Object:FindFirstChild(_L("HidingPrompt"))
	end

	return nil
	end

	local function TryObject(Object)
		if not Object or not Object:IsDescendantOf(Services.Workspace) then return end
		if not Object.PrimaryPart and not Object:FindFirstChildOfClass(_L("BasePart")) then return end
		local Prompt = GetHidePrompt(Object)
		if not Prompt then return end
		local PrimaryPart = Object.PrimaryPart or Object:FindFirstChildOfClass(_L("BasePart"))
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
		if Anchor.Name == _L("MinesAnchor") and Anchor:FindFirstChild(_L("Sign")) then
			if Anchor.Sign.TextLabel.Text == AnchorCode then
				return Anchor
			end
		end
	end
end

Functions.GetMinecart = function()
	return Camera:FindFirstChild(_L("MinecartRig")) ~= nil
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

Globals.PromptContainer = Instance.new(_L("Folder"))
Globals.PromptContainer.Name = _L("PromptContainer")
Globals.PromptContainer.Parent = GetHiddenContainer()

local ESPBlacklist = {}

Functions.AddESP = function(ESPOptions, RoomBased)
	local Object = ESPOptions.Object

	if table.find(ESPBlacklist, Object) then
		return
	end

	if RoomBased then
		local CurrentRoom = tonumber(LocalPlayer:GetAttribute(_L("CurrentRoom")))
		local ObjectRoom = tonumber(Object:GetAttribute(_L("ParentRoom")))

		if ObjectRoom == CurrentRoom or (table.find(Objects.Doors, Object) and ObjectRoom == CurrentRoom + 1) then
			Abysall.ESPLibrary:AddESP(ESPOptions)
		end

		local RoomConnection = LocalPlayer:GetAttributeChangedSignal(_L("CurrentRoom")):Connect(function()
			if Abysall.ESPLibrary.ColorTable[Object] then
				ESPOptions.Color = Abysall.ESPLibrary.ColorTable[Object]
			end

			local NewCurrentRoom = tonumber(LocalPlayer:GetAttribute(_L("CurrentRoom")))
			local ObjRoom = tonumber(Object:GetAttribute(_L("ParentRoom")))

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
	if Floor == _L("Mines") then
		DoorNumber = DoorNumber + 100
	end
	if Floor == _L("Backdoor") then
		DoorNumber = DoorNumber - 50
	end

	return tostring(DoorNumber)
end

Functions.GetLibraryCode = function()
	local Paper = Character:FindFirstChild(_L("LibraryHintPaper"))
		or Character:FindFirstChild(_L("LibraryHintPaperHard"))
		or LocalPlayer.Backpack:FindFirstChild(_L("LibraryHintPaper"))
		or LocalPlayer.Backpack:FindFirstChild(_L("LibraryHintPaperHard"))

	if Paper and Paper:FindFirstChild(_L("UI")) then
		local Code = {}
		local CodeLength = Floor == _L("Fools") and 10 or 5
		for I = 1, CodeLength do Code[I] = _L("_") end

		local HintChildren = LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()
		local UIChildren = Paper.UI:GetChildren()

		for _, Hint in HintChildren do
			for _, UIChild in UIChildren do
				if Hint:IsA(_L("ImageLabel")) and UIChild:IsA(_L("ImageLabel"))
					and Hint.ImageRectOffset == UIChild.ImageRectOffset
					and Code[tonumber(UIChild.Name)]
				then
					Code[tonumber(UIChild.Name)] = Hint.TextLabel.Text
				end
			end
		end
		return table.concat(Code)
	end
	return Floor == _L("Fools") and _L("__________") or _L("_____")
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
        NewCode = CodeTemplate:gsub(_L("_"), function()
            return tostring(math.random(0, 9))
        end)
        Tries = Tries + 1
    until not Globals.UsedRandomCodes[NewCode] or Tries >= 10

    Globals.UsedRandomCodes[NewCode] = true
    return NewCode
end

local Window = Library:CreateWindow({
	Title = _L("🎃 Abysall Hub Continued"),
	Footer = _L("dsc.gg/abysallhubcontinued"),
	NotifySide = _L("Right"),
	ShowCustomCursor = false,
	AutoShow = true,
	Center = true,
	TabPadding = 3,
	MenuFadeTime = 0,
	CornerRadius = 6,
})




Abysall.Interface.ApplyInfoTab(Window)

local Tabs = {
	General = Window:AddTab(_L("General"), _L("house")),
	Exploits = Window:AddTab(_L("Exploits"), _L("shield")),
	Visuals = Window:AddTab(_L("Visuals"), _L("eye")),
	Floors = Window:AddTab(_L("Floors"), _L("earth")),
	Archives = Window:AddTab(_L("New - Archives"), _L("rbxassetid://104508835882225")),
	Stairwell = Window:AddTab(_L("New - Stairwell"), _L("rbxassetid://80017304328364")),
}


Groupboxes.General_Character = Tabs.General:AddLeftGroupbox(_L("Character"))
Groupboxes.General_Character:AddSlider(_L("SpeedBoostSlider"), {
	Text = _L("Speed Boost"), Min = 0, Max = 100, Default = 0, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddToggle(_L("SpeedBoostToggle"), {
	Text = _L("Enable Speed Boost"), Default = false, Tooltip = _L("Increases your walkspeed by the specified amount.")
})
Groupboxes.General_Character:AddToggle(_L("FlyToggle"), {
	Text = _L("Fly"), Default = false, Tooltip = _L("Allows you to freely fly around the map.")
})
Toggles.FlyToggle:AddKeyPicker(_L("FlyKeybind"), {
	Text = _L("Fly"), Default = _L("F"), Mode = _L("Toggle"), SyncToggleState = true
})
Groupboxes.General_Character:AddSlider(_L("FlySpeed"), {
	Text = _L("Fly Speed"), Min = 0, Max = 115, Default = 20, Rounding = 0, Compact = true
})
Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle(_L("NoclipToggle"), {
	Text = _L("Noclip"), Default = false, Tooltip = _L("Allows your character to pass through solid objects.")
})
Groupboxes.General_Character:AddToggle(_L("RemoveClosetDelay"), {
	Text = _L("Remove Closet Delay"), Default = false,
	Tooltip = _L("Removes the short window where you can't exit out of a closet after the animation finishes.")
})
Groupboxes.General_Character:AddToggle(_L("RemoveAcceleration"), {
	Text = _L("Remove Acceleration"), Default = false, Tooltip = _L("Prevents your character from sliding while moving.")
})

local CustomPhysics

Options.SpeedBoostSlider:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild(_L("Crouch")) then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Toggles.NoclipToggle:AddKeyPicker(_L("NoclipKeybind"), {
	Text = _L("Noclip"), Default = _L("N"), Mode = _L("Toggle"), SyncToggleState = true
})
Toggles.RemoveAcceleration:OnChanged(function(Value)
	for Index, Old in PartProperties do
		Index.CustomPhysicalProperties = Value and CustomPhysics or Old
	end
end)

Groupboxes.General_Character:AddDivider()
Groupboxes.General_Character:AddToggle(_L("EnableCharacterJump"), {
	Text = _L("Enable Jumping"), Default = false, Tooltip = _L("Allows your character to jump.")
})
Groupboxes.General_Character:AddToggle(_L("EnableCharacterSlide"), {
	Text = _L("Enable Sliding"), Default = false, Tooltip = _L("Allows your character to slide.")
})
Groupboxes.General_Character:AddToggle(_L("InfiniteJumps"), {
	Text = _L("Infinite Jumps"), Default = false, Tooltip = _L("Allows you to jump while in the air.")
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
		Character:SetAttribute(_L("CanJump"), Value and true or OldJump)
	end
end)
Toggles.EnableCharacterSlide:OnChanged(function(Value)
	if Character then
		Character:SetAttribute(_L("CanSlide"), Value and true or OldSlide)
	end
end)

Groupboxes.General_Self = Tabs.General:AddLeftGroupbox(_L("Self"))
Groupboxes.General_Self:AddToggle(_L("DoorReachToggle"), {
	Text = _L("Door Reach"), Default = false, Tooltip = _L("Allows you to open doors from further away.")
})
Groupboxes.General_Self:AddToggle(_L("DisableIdleKick"), {
	Text = _L("Disable Idle Kick"), Default = false, Tooltip = _L("Prevents the kick from being idle for 20 minutes.")
})
Toggles.DisableIdleKick:OnChanged(function(Value)
	if Functions.CheckCompatability({_L("getconnections")}) then
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
Groupboxes.General_Self:AddSlider(_L("PromptReachSlider"), {
	Text = _L("Prompt Reach Multiplier"), Min = 1, Max = 2, Default = 1, Rounding = 1, Compact = true
})
Groupboxes.General_Self:AddToggle(_L("InstantPrompts"), {
	Text = _L("Instant Prompts"), Default = false, Tooltip = _L("Allows you to trigger all prompts instantly.")
})
Groupboxes.General_Self:AddToggle(_L("PromptClip"), {
	Text = _L("Prompt Clip"), Default = false, Tooltip = _L("Allows you to interact with prompts through walls.")
})

Options.PromptReachSlider:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.MaxActivationDistance = Prompt:GetAttribute(_L("MaxActivationDistance_Old")) * Value
	end
end)
Toggles.InstantPrompts:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.HoldDuration = Value and 0 or Prompt:GetAttribute(_L("HoldDuration_Old"))
	end
end)
Toggles.PromptClip:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.RequiresLineOfSight = Value and false or Prompt:GetAttribute(_L("RequiresLineOfSight_Old"))
	end
end)

Groupboxes.Self_Automation = Tabs.General:AddRightGroupbox(_L("Automation"))
Groupboxes.Self_Automation:AddToggle(_L("AutoBreakerBox"), {
	Text = _L("Auto Breaker Box"), Default = false, Tooltip = _L("Automatically solves the breaker box.")
})
Groupboxes.Self_Automation:AddToggle(_L("AutoSolveAnchors"), {
	Text = _L("Auto Solve Anchors"), Default = false,
	Tooltip = _L("Automatically enters the correct code into anchors when you are near them.")
})
Toggles.AutoBreakerBox:OnChanged(function(Value)
	if Value and CurrentRooms:FindFirstChild(_L("ElevatorBreaker"), true) then
		if not Globals.BreakerBoxInteracted then
			if not Globals.BreakerBoxNotified then
				Functions.Notify({ Title = _L("Interact with the breaker box."), Body = _L("It will be automatically solved.") })
				Globals.BreakerBoxInteracted = true
			end
		else
			RemotesFolder.EBF:FireServer()
		end
	end
end)

Groupboxes.Self_Automation:AddToggle(_L("AutoHeartbeatMinigame"), { Text = _L("Auto Heartbeat Minigame"), Default = false, Tooltip = _L("Prevents the 'Figure' minigame from ever failing."), Disabled = not Functions.CheckCompatability({_L("hookmetamethod"), _L("newcclosure"), _L("getnamecallmethod")}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle(_L("AutoUnlockPadlockToggle"), {
	Text = _L("Auto Unlock Padlock"), Default = false, Tooltip = _L("Automatically enters the code into the library padlock.")
})
Groupboxes.Self_Automation:AddSlider(_L("AutoUnlockPadlockSlider"), {
	Text = _L("Unlock Distance"), Min = 1, Max = 50, Default = 10, Rounding = 0, Compact = true
})
Groupboxes.Self_Automation:AddToggle(_L("AutoLibraryGuessCode"), {
	Text = _L("Guess Library Code"), Default = false,
	Tooltip = _L("Attempts to guess the library code, but collecting some books is also necessary.")
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle(_L("AutoLibrary"), {
	Text = _L("Auto Library"), Default = false,
	Tooltip = _L("Automatically gets books and paper.")
})
Groupboxes.Self_Automation:AddToggle(_L("SkipSeekHotel"), {
	Text = _L("Skip Seek (Hotel)"),
	Default = false,
	Tooltip = _L("Skips the entire Seek sections."),
})
Groupboxes.Self_Automation:AddToggle(_L("AutoBreakerRoom"), {
	Text = _L("Auto Breaker Room"),
	Default = false,
	Tooltip = _L("Automatically completes the breaker sequence in Hotel Room 100."),
})
Groupboxes.Self_Automation:AddDivider()
Toggles.AutoHotel = Groupboxes.Self_Automation:AddToggle(_L("AutoHotel"), {
	Text = _L("Auto Hotel"),
	Tooltip = _L("Automatically progresses through the hotel floor."),
	Risky = Floor ~= _L("Ballz"),
	Default = false
})
Toggles.AutoHotelIgnoreEntities = Groupboxes.Self_Automation:AddToggle(_L("AutoHotelIgnoreEntities"), {
	Text = _L("Ignore Entities"),
	Tooltip = _L("Skip all entity waits and pauses."),
	Default = false
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle(_L("AutoInteractToggle"), {
	Text = _L("Auto Interact"), Default = false, Tooltip = _L("Automatically triggers nearby prompts.")
})
Toggles.AutoInteractToggle:AddKeyPicker(_L("AutoInteractKeybind"), {
    Text = _L("Auto Interact"),
    Default = _L("R"),
    Mode = _L("Toggle"),
    SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown(_L("AutoInteractIgnoreList"), {
	Text = _L("Ignore List"),
	Values = { _L("Glitch Fragments"), _L("Jeff Items"), _L("Dropped Items"), _L("Currency"), _L("Minecarts"), _L("Locks") },
	Default = { _L("Glitch Fragments"), _L("Jeff Items"), _L("Dropped Items") },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddDivider()
Groupboxes.Self_Automation:AddToggle(_L("AutoClosetToggle"), {
	Text = _L("Auto Closet"), Default = false,
	Tooltip = _L("Automatically hides in a nearby closet when an entity is near.")
})
Toggles.AutoClosetToggle:AddKeyPicker(_L("AutoClosetKeybind"), {
	Text = _L("Auto Closet"), Default = _L("Q"), Mode = _L("Toggle"), SyncToggleState = true
})
Groupboxes.Self_Automation:AddDropdown(_L("AutoClosetEntityList"), {
	Text = _L("Ignore List"),
	Values = { _L("Rush"), _L("Ambush"), _L("Blitz"), _L("DronesStampede"), _L("Scribbles"), _L("A-60"), _L("A-120"), _L("AR0xMBUSH"), _L("RNIUSHCG==") },
	Multi = true, AllowNull = true
})
Groupboxes.Self_Automation:AddToggle(_L("SpectateEntityToggle"), {
	Text = _L("Spectate Entity"),
	Default = false,
	Tooltip = _L("Spectates the entity while auto hiding.")
})
Groupboxes.Self_Automation:AddDropdown(_L("SpecateEntityMode"), {
	Values = {_L("Player to Entity"), _L("Entity to Player")},
	Default = 1,
	AllowNull = true
})

Groupboxes.Self_Misc = Tabs.General:AddRightGroupbox(_L("Miscellaneous"))
Groupboxes.Self_Misc:AddButton({
	Text = _L("Play Again"), Tooltip = _L("Makes you join a new run, click again to cancel."), DoubleClick = true,
	Func = function() RemotesFolder.PlayAgain:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = _L("Return to Lobby"), Tooltip = _L("Makes you teleport back to the lobby."), DoubleClick = true,
	Func = function() RemotesFolder.Lobby:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = _L("Revive"),
	Tooltip = _L("Makes you revive, if you have a revive and haven't already revived in this run."),
	DoubleClick = true,
	Func = function() RemotesFolder.Revive:FireServer() end
})
Groupboxes.Self_Misc:AddButton({
	Text = _L("Reset Character"),
	Tooltip = _L("Kills your character on the server. (takes around 20 seconds if replicatesignal isn't supported)"),
	DoubleClick = true,
	Func = function()
		Globals.SelfKilled = true
		if Functions.CheckCompatability({_L("replicatesignal")}) then
			Abysall.Environment.replicatesignal(LocalPlayer.Kill)
		else
			if RemotesFolder:FindFirstChild(_L("Underwater")) then
				RemotesFolder.Underwater:FireServer(true)
			else
				Humanoid.Health = 0
			end
		end
	end
})


Tabs.General:UpdateWarningBox({
	Visible = true,
	Title = _L("Risk Warning"),
	Text = _L("Features highlighted in red are risky."),
})


Toggles.SkipSeekHotel:OnChanged(function(Value)
	if not Value then return end
	if Floor ~= _L("Hotel") then return end

	task.spawn(function()
		print(_L("started"))

		local currentRooms

		repeat
			if not Toggles.SkipSeekHotel.Value or Floor ~= _L("Hotel") then
				return
			end
			currentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
			task.wait()
		until currentRooms

		print(_L("got currentrooms"))

		local lastTriggerRoom = nil

		while Toggles.SkipSeekHotel.Value and Floor == _L("Hotel") do
			local triggerRoom = nil

			print(_L("waiting for trigger"))

			repeat
				if not Toggles.SkipSeekHotel.Value or Floor ~= _L("Hotel") then
					return
				end

				currentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
				local currentRoomNum = tonumber(LocalPlayer:GetAttribute(_L("CurrentRoom")))

				if currentRoomNum and currentRoomNum ~= lastTriggerRoom then
					local room = currentRooms and currentRooms:FindFirstChild(tostring(currentRoomNum))
					if room then
						local trigger = room:WaitForChild(_L("TriggerEventCollision"), 0.5)
						if trigger then
							triggerRoom = currentRoomNum
							print(_L("found trigger in"), triggerRoom)
						end
					end
				end

				task.wait()
			until triggerRoom

			lastTriggerRoom = triggerRoom

			local roomNum = triggerRoom

			while Toggles.SkipSeekHotel.Value and Floor == _L("Hotel") do
				roomNum += 1
				print(_L("looking for room"), roomNum)

				local room
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= _L("Hotel") then
						return
					end
					currentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
					room = currentRooms and currentRooms:FindFirstChild(tostring(roomNum))
					task.wait()
				until room

				print(_L("found room"), roomNum)

				local hasSeekArm = false
				local assets = room:FindFirstChild(_L("Assets"))
				if assets then
					for _, child in ipairs(assets:GetChildren()) do
						if child.Name == _L("Seek_Arm") then
							hasSeekArm = true
							print(_L("found seek arm"))
							break
						end
					end
				end

				local door
				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= _L("Hotel") then
						return
					end
					door = room:FindFirstChild(_L("Door"), true)
					task.wait()
				until door

				print(_L("found door, teleporting"))

				repeat
					if not Toggles.SkipSeekHotel.Value or Floor ~= _L("Hotel") then
						return
					end
					if Character then
						Character:PivotTo(door:GetPivot())
					end
					task.wait()
				until door:GetAttribute(_L("Opened")) == true

				print(_L("door opened"))

				if hasSeekArm then
					if not Character then
						return
					end

					print(_L("voiding"))

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

					print(_L("done voiding"))
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
		local AutoLibraryPlayers = game:GetService(_L("Players"))
		local AutoLibraryLocalPlayer = AutoLibraryPlayers.LocalPlayer
		local AutoLibraryCharacter = AutoLibraryLocalPlayer.Character or AutoLibraryLocalPlayer.CharacterAdded:Wait()
		local AutoLibraryHumanoidRootPart = AutoLibraryCharacter:WaitForChild(_L("HumanoidRootPart"))

		local AutoLibraryCurrentRooms = workspace:WaitForChild(_L("CurrentRooms"))
		local AutoLibraryRoom50 = AutoLibraryCurrentRooms:WaitForChild(_L("50"))
		local AutoLibraryLiveHintBooks = {}
		local AutoLibraryHintPaperObtained = false

		local function AutoLibraryIsInRoom50(AutoLibraryObject)
			return AutoLibraryObject
				and AutoLibraryObject:IsDescendantOf(AutoLibraryRoom50)
				and AutoLibraryObject:IsDescendantOf(AutoLibraryCurrentRooms)
				and AutoLibraryObject:IsDescendantOf(workspace)
		end

		local function AutoLibraryIsActuallyInRoom50()
			return tonumber(AutoLibraryLocalPlayer:GetAttribute(_L("CurrentRoom"))) == 50
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

			local AutoLibraryBackpackPaper = AutoLibraryLocalPlayer.Backpack:FindFirstChild(_L("LibraryHintPaper"), true)
			local AutoLibraryCharacterPaper = AutoLibraryCharacter:FindFirstChild(_L("LibraryHintPaper"), true)

			return AutoLibraryBackpackPaper ~= nil or AutoLibraryCharacterPaper ~= nil
		end

		local function AutoLibraryGetObjectCFrame(AutoLibraryObject)
			if not AutoLibraryIsActuallyInRoom50() then
				return nil
			end

			if not AutoLibraryIsInRoom50(AutoLibraryObject) then
				return nil
			end

			if AutoLibraryObject:IsA(_L("Model")) then
				return AutoLibraryObject:GetPivot()
			elseif AutoLibraryObject:IsA(_L("BasePart")) then
				return AutoLibraryObject.CFrame
			end

			local AutoLibraryObjectPart = AutoLibraryObject:FindFirstChildWhichIsA(_L("BasePart"), true)

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

			if AutoLibraryObject.Name == _L("LiveHintBook") then
				if not table.find(AutoLibraryLiveHintBooks, AutoLibraryObject) then
					table.insert(AutoLibraryLiveHintBooks, AutoLibraryObject)
				end
			end

			for _, AutoLibraryDescendant in ipairs(AutoLibraryObject:GetDescendants()) do
				if AutoLibraryDescendant.Name == _L("LiveHintBook")
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

			if AutoLibraryDescendant.Name == _L("LiveHintBook")
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

				if AutoLibraryDescendant.Name == _L("LiveHintBook")
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
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild(_L("HumanoidRootPart"))

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
						if AutoLibraryPromptDescendant:IsA(_L("ProximityPrompt"))
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

			local AutoLibraryHintPaper = AutoLibraryRoom50:FindFirstChild(_L("LibraryHintPaper"), true)

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
					AutoLibraryHumanoidRootPart = AutoLibraryCharacter:FindFirstChild(_L("HumanoidRootPart"))

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
						if AutoLibraryPromptDescendant:IsA(_L("ProximityPrompt"))
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
		local AutoBreakerRoomPlayers = game:GetService(_L("Players"))
		local AutoBreakerRoomCurrentRooms = workspace:WaitForChild(_L("CurrentRooms"))
		local AutoBreakerRoom100 = AutoBreakerRoomCurrentRooms:WaitForChild(_L("100"))

		local function AutoBreakerRoomIsActuallyInRoom100()
			return tonumber(AutoBreakerRoomPlayers.LocalPlayer:GetAttribute(_L("CurrentRoom"))) == 100
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

			if AutoBreakerRoomObject:IsA(_L("Model")) then
				return AutoBreakerRoomObject:GetPivot()
			elseif AutoBreakerRoomObject:IsA(_L("BasePart")) then
				return AutoBreakerRoomObject.CFrame
			end

			local AutoBreakerRoomPart = AutoBreakerRoomObject:FindFirstChildWhichIsA(_L("BasePart"), true)
			return AutoBreakerRoomPart and AutoBreakerRoomPart.CFrame
		end

		local function AutoBreakerRoomGetHRP()
			local AutoBreakerRoomCharacter = AutoBreakerRoomPlayers.LocalPlayer.Character
			return AutoBreakerRoomCharacter and AutoBreakerRoomCharacter:FindFirstChild(_L("HumanoidRootPart"))
		end

		local function AutoBreakerRoomActivate(AutoBreakerRoomObject)
			if not AutoBreakerRoomObject then
				return
			end

			if AutoBreakerRoomObject:IsA(_L("ProximityPrompt")) then
				fireproximityprompt(AutoBreakerRoomObject)
				return
			end

			for _, AutoBreakerRoomDescendant in ipairs(AutoBreakerRoomObject:GetDescendants()) do
				if AutoBreakerRoomDescendant:IsA(_L("ProximityPrompt")) then
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
					if AutoBreakerRoomDescendant.Name == _L("LiveBreakerPolePickup") and AutoBreakerRoomIsInRoom100(AutoBreakerRoomDescendant) then
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

			local AutoBreakerRoomIndustrialGate = AutoBreakerRoom100:FindFirstChild(_L("IndustrialGate"))
			local AutoBreakerRoomBox = AutoBreakerRoomIndustrialGate and AutoBreakerRoomIndustrialGate:FindFirstChild(_L("Box"))
			local AutoBreakerRoomLever = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild(_L("Lever"))
			local AutoBreakerRoomActivateEventPrompt = AutoBreakerRoomBox and AutoBreakerRoomBox:FindFirstChild(_L("ActivateEventPrompt"))

			if AutoBreakerRoomActivateEventPrompt and AutoBreakerRoomLever then
				local function AutoBreakerRoomGetLeverCFrame()
					if AutoBreakerRoomLever:IsA(_L("Model")) then
						return AutoBreakerRoomLever:GetPivot()
					elseif AutoBreakerRoomLever:IsA(_L("BasePart")) then
						return AutoBreakerRoomLever.CFrame
					end
					local AutoBreakerRoomPart = AutoBreakerRoomLever:FindFirstChildWhichIsA(_L("BasePart"), true)
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

			local AutoBreakerRoomElevatorBreakerEmpty = AutoBreakerRoom100:FindFirstChild(_L("ElevatorBreakerEmpty"))
			if not AutoBreakerRoomElevatorBreakerEmpty then
				continue
			end

			local AutoBreakerRoomBreakerPrompt = AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild(_L("Prompt"))
			if not AutoBreakerRoomBreakerPrompt then
				continue
			end

			local AutoBreakerRoomBreakerOffset = CFrame.new(0, -1.8, 0)

			while AutoBreakerRoomEnabled and AutoBreakerRoomIsActuallyInRoom100() do
				if AutoBreakerRoomElevatorBreakerEmpty:FindFirstChild(_L("BreakerSwitchInBox")) then
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

			local AutoBreakerRoomElevatorCar = AutoBreakerRoom100:FindFirstChild(_L("ElevatorCar"))
			local AutoBreakerRoomWeb = AutoBreakerRoomElevatorCar and AutoBreakerRoomElevatorCar:FindFirstChild(_L("Web"), true)

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
	[_L("RushMoving")] = true,
	[_L("Scribbles")] = true,
	[_L("BashMoving")] = true,
	[_L("DronesStampede")] = true,
	[_L("AmbushMoving")] = true,
	[_L("A60")] = true,
	[_L("A120")] = true,
	[_L("GlitchRush")] = true,
	[_L("GlitchAmbush")] = true,
	[_L("BackdoorRush")] = true,
	[_L("CustomEntity")] = true,
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

	local AutoHotelGameData = game:GetService(_L("ReplicatedStorage")):FindFirstChild(_L("GameData"))
	if not AutoHotelGameData then return nil, nil end

	local AutoHotelLatestRoom = AutoHotelGameData:FindFirstChild(_L("LatestRoom"))
	if not AutoHotelLatestRoom then return nil, nil end

	local AutoHotelStartRoom = AutoHotelLatestRoom.Value
	local AutoHotelBestDoor, AutoHotelBestNumber = nil, math.huge
	local AutoHotelCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))

	if AutoHotelCurrentRooms then
		for _, AutoHotelRoom in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local AutoHotelRoomNum = tonumber(AutoHotelRoom.Name)
			if AutoHotelRoomNum and AutoHotelRoomNum ~= 100 and AutoHotelRoomNum >= AutoHotelStartRoom and AutoHotelRoomNum < AutoHotelBestNumber then
				local AutoHotelDoor = AutoHotelRoom:FindFirstChild(_L("Door"))
				if AutoHotelDoor and AutoHotelDoor:IsA(_L("Model")) then
					local AutoHotelOpenAttr = AutoHotelDoor:GetAttribute(_L("Open"))
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
			if AutoHotelChild.Name == _L("KeyObtain") then
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
	local AutoHotelCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
	if not AutoHotelCurrentRooms then return false end

	local AutoHotelRoom = AutoHotelCurrentRooms:FindFirstChild(tostring(AutoHotelRoomNum))
	if not AutoHotelRoom then return false end

	local AutoHotelDoor = AutoHotelRoom:FindFirstChild(_L("Door"))
	if not AutoHotelDoor or not AutoHotelDoor:FindFirstChild(_L("Lock")) then
		return false
	end

	local AutoHotelKeyObtain = AutoHotelFindKeyObtain(AutoHotelRoom)
	if not AutoHotelKeyObtain then return false end

	local AutoHotelStart = tick()
	while tick() - AutoHotelStart < 12 do
		if LocalPlayer.Backpack:FindFirstChild(_L("Key")) or (Character and Character:FindFirstChild(_L("Key"))) then
			return true
		end

		if Character then
			Character:PivotTo(AutoHotelKeyObtain:GetPivot())
		end

		for _, AutoHotelDesc in ipairs(AutoHotelKeyObtain:GetDescendants()) do
			if AutoHotelDesc:IsA(_L("ProximityPrompt")) then
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
	local AutoHotelCurrentRooms = workspace:WaitForChild(_L("CurrentRooms"))
	local AutoHotelRoom50 = AutoHotelCurrentRooms:WaitForChild(_L("50"))
	local AutoHotelLiveHintBooks = {}
	local AutoHotelHintPaperObtained = false

	local function AutoHotelIsInRoom50(AutoHotelObj)
		return AutoHotelObj and AutoHotelObj:IsDescendantOf(AutoHotelRoom50)
	end

	local function AutoHotelIsActuallyInRoom50()
		return tonumber(LocalPlayer:GetAttribute(_L("CurrentRoom"))) == 50
	end

	while Toggles.AutoHotel.Value and not AutoHotelIsActuallyInRoom50() do
		task.wait(0.1)
	end
	if not Toggles.AutoHotel.Value then return end

	AutoHotelWaitForEntities(5)

	local function AutoHotelHasHintPaper()
		local AutoHotelChar = LocalPlayer.Character
		if not AutoHotelChar then return false end
		return LocalPlayer.Backpack:FindFirstChild(_L("LibraryHintPaper"), true) or AutoHotelChar:FindFirstChild(_L("LibraryHintPaper"), true)
	end

	local function AutoHotelGetCFrame(AutoHotelObj)
		if not AutoHotelIsActuallyInRoom50() or not AutoHotelIsInRoom50(AutoHotelObj) then return nil end
		if AutoHotelObj:IsA(_L("Model")) then return AutoHotelObj:GetPivot() end
		if AutoHotelObj:IsA(_L("BasePart")) then return AutoHotelObj.CFrame end
		local AutoHotelPart = AutoHotelObj:FindFirstChildWhichIsA(_L("BasePart"), true)
		return AutoHotelPart and AutoHotelPart.CFrame
	end

	local function AutoHotelCollectBooks()
		for _, AutoHotelDesc in ipairs(AutoHotelRoom50:GetDescendants()) do
			if AutoHotelDesc.Name == _L("LiveHintBook") and AutoHotelIsInRoom50(AutoHotelDesc) and not table.find(AutoHotelLiveHintBooks, AutoHotelDesc) then
				table.insert(AutoHotelLiveHintBooks, AutoHotelDesc)
			end
		end
	end

	AutoHotelCollectBooks()

	AutoHotelLibraryRoomConnection = AutoHotelRoom50.DescendantAdded:Connect(function(AutoHotelAdded)
		if Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and AutoHotelIsInRoom50(AutoHotelAdded) then
			if AutoHotelAdded.Name == _L("LiveHintBook") and not table.find(AutoHotelLiveHintBooks, AutoHotelAdded) then
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
				local AutoHotelHRP = AutoHotelChar:FindFirstChild(_L("HumanoidRootPart"))
				if not AutoHotelHRP then
					task.wait()
					continue
				end

				local AutoHotelCF = AutoHotelGetCFrame(AutoHotelBook)
				if AutoHotelCF then
					AutoHotelHRP.CFrame = AutoHotelCF
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelBook:GetDescendants()) do
					if AutoHotelPrompt:IsA(_L("ProximityPrompt")) then
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

		local AutoHotelPaper = AutoHotelRoom50:FindFirstChild(_L("LibraryHintPaper"), true)
		if AutoHotelPaper and AutoHotelIsInRoom50(AutoHotelPaper) then
			while Toggles.AutoHotel.Value and AutoHotelIsActuallyInRoom50() and not AutoHotelHintPaperObtained and AutoHotelPaper.Parent do
				if AutoHotelHasHintPaper() then
					AutoHotelHintPaperObtained = true
					break
				end

				local AutoHotelChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local AutoHotelHRP = AutoHotelChar:FindFirstChild(_L("HumanoidRootPart"))
				if AutoHotelHRP then
					local AutoHotelCF = AutoHotelGetCFrame(AutoHotelPaper)
					if AutoHotelCF then
						AutoHotelHRP.CFrame = AutoHotelCF * CFrame.new(0, 5, 0)
					end
				end

				for _, AutoHotelPrompt in ipairs(AutoHotelPaper:GetDescendants()) do
					if AutoHotelPrompt:IsA(_L("ProximityPrompt")) then
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
		local AutoHotelCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
		if not AutoHotelCurrentRooms then
			task.wait(0.2)
			continue
		end

		local TriggerRoomNum = nil

		for _, Room in ipairs(AutoHotelCurrentRooms:GetChildren()) do
			local Num = tonumber(Room.Name)
			if Num and Num ~= AutoHotelLastTriggerRoom then
				local Trigger = Room:FindFirstChild(_L("TriggerEventCollision"))
					or Room:FindFirstChild(_L("TriggerEventCollision"), true)

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

	local AutoHotelCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
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


Groupboxes.Debug = Tabs.General:AddRightGroupbox(_L("Debug"))
Groupboxes.Debug:AddButton({
	Text = _L("Ladder Softlock Fix"),
	Tooltip = _L("Ladder Softlock Fix."),
	Func = function()
   		LocalPlayer:SetAttribute(_L("Climbing"), false)
	end
})
Groupboxes.Debug:AddButton({
	Text = _L("Get Current Floor"),
	Tooltip = _L("Prints the current floor to the console."),
	Func = function()
		print(_L("Current Floor:"), GameData:WaitForChild(_L("Floor")).Value)
	end
})
Groupboxes.Debug:AddButton({
	Text = _L("Get Current Room"),
	Tooltip = _L("Prints the current room number to the console."),
	Func = function()
		print(_L("Current Room:"), LocalPlayer:GetAttribute(_L("CurrentRoom")))
	end
})
Groupboxes.Debug:AddButton({
	Text = _L("Void"),
	Tooltip = _L("Teleports your character to Y -120."),
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
	Text = _L("Death"),
	Tooltip = _L("Death"),
	Func = function()
		Globals.Deathing = true
		LocalPlayer.Character.Humanoid.Health = 0
	end
})
Groupboxes.Debug:AddButton({
	Text = _L("Exit Closet"),
	Tooltip = _L("Exits the current closet."),
	Func = function()
		if RemotesFolder and RemotesFolder:FindFirstChild(_L("CamLock")) then
			RemotesFolder.CamLock:FireServer()
		end
	end
})
local TpNextDoorConnection

local function getNextClosedDoor()
	if not Character then return nil end

	local GameData = game:GetService(_L("ReplicatedStorage")):FindFirstChild(_L("GameData"))
	if not GameData then return nil end

	local LatestRoom = GameData:FindFirstChild(_L("LatestRoom"))
	if not LatestRoom then return nil end

	local startRoom = LatestRoom.Value
	local bestDoor = nil
	local bestNumber = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == _L("Door") and obj:IsA(_L("Model")) then
			local openAttr = obj:GetAttribute(_L("Open"))
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
	Text = _L("Tp Next Door"),
	Tooltip = _L("Teleports you to the next sequential unopened door."),
	Func = function()
		local door = getNextClosedDoor()
		if door then
			Character:PivotTo(door:GetPivot() * CFrame.new(0, -1, 0))
		end
	end
})

Toggles.TpNextDoor = Groupboxes.Debug:AddToggle(_L("TpNextDoor"), {
	Text = _L("Auto Tp Next Door"),
	Tooltip = _L("Continuously teleports you to the next sequential unopened door."),
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


Groupboxes.Exploits_Bypass = Tabs.Exploits:AddLeftGroupbox(_L("Bypass / Solve"))

Groupboxes.Exploits_Bypass:AddToggle(_L("BypassGiggle"),         { Text = _L("Bypass Giggle"),           Default = false, Tooltip = _L("Prevents 'Giggle' from attacking you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassDupe"),           { Text = _L("Bypass Dupe"),             Default = false, Tooltip = _L("Prevents you from open 'Dupe' fake doors.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassEyes"),           { Text = _L("Bypass Eyes"),             Default = false, Tooltip = _L("Prevents 'Eyes' from hurting you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassLookman"),        { Text = _L("Bypass Lookman"),          Default = false, Tooltip = _L("Prevents 'Lookman' from hurting you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassGloombatEggs"),   { Text = _L("Bypass Gloombat Eggs"),    Default = false, Tooltip = _L("Prevents taking damage from stepping on 'Gloombat' eggs.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassSeekObstructions"), { Text = _L("Bypass Seek Obstructions"), Default = false, Tooltip = _L("Prevents obstacles in the 'Seek' chase from harming you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassVacuum"),         { Text = _L("Bypass Vacuum"),           Default = false, Tooltip = _L("Prevents you from falling into 'Vacuum' fake doors.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassKillbricks"),     { Text = _L("Bypass Killbricks"),       Default = false, Tooltip = _L("Prevents 'Lava' from hurting you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassSeekingWall"),    { Text = _L("Bypass Seeking Wall"),     Default = false, Tooltip = _L("Prevents 'ScaryWall' from hurting you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassSnare"),          { Text = _L("Bypass Snare"),            Default = false, Tooltip = _L("Prevents 'Snare' from trapping you.") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassBanana"),         { Text = _L("Bypass Banana"),           Default = false, Tooltip = _L("Prevents 'Banana Peel' from slipping you up (sometimes doesn't work).") })
Groupboxes.Exploits_Bypass:AddToggle(_L("BypassJeff"),           { Text = _L("Bypass Jeff"),             Default = false, Tooltip = _L("Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work).") })


Toggles.BypassGiggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == _L("GiggleCeiling") then
			Object:WaitForChild(_L("Hitbox")).CanTouch = not Value
		end
	end
end)
Toggles.BypassDupe:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == _L("DoorFake") or Object.Name == _L("FakeDoor") then
			Object:WaitForChild(_L("Hidden")).CanTouch = not Value
			if Object:FindFirstChild(_L("Lock")) then
				Object.Lock.UnlockPrompt.Enabled = not Value
			end
		end
	end
end)
Toggles.BypassEyes:OnChanged(function(Value)
	if Value and Globals.IsEyes then
		if Floor == _L("Fools") or Floor == _L("OldHotel") then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassLookman:OnChanged(function(Value)
	if Value and Globals.IsLookman then
		if Floor == _L("Fools") or Floor == _L("OldHotel") then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end)
Toggles.BypassGloombatEggs:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) then
				Part.CanTouch = not Value
			end
		end
	end
end)
Toggles.BypassSeekObstructions:OnChanged(function(Value)
	for _, Object in Objects.SeekObstructions do
		Object.CanTouch = not Value
		if Object.Name == _L("SeekFloodline") then
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
		if Object.Name == _L("SideroomSpace") then
			Object:WaitForChild(_L("Collision")).CanCollide = Value
			Object:WaitForChild(_L("Collision")).CanTouch = not Value
		end
	end
end)
Toggles.BypassKillbricks:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == _L("Lava") then Object.CanTouch = not Value end
	end
end)
Toggles.BypassSeekingWall:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == _L("ScaryWall") then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then
					Part.CanTouch = not Value
					Part.CanCollide = not Value
				end
			end
		end
	end
end)
Toggles.BypassSnare:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == _L("Snare") then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then Part.CanTouch = not Value end
			end
		end
	end
end)
Toggles.BypassBanana:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == _L("BananaPeel") then Object.CanTouch = not Value end
	end
end)
Toggles.BypassJeff:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == _L("JeffTheKiller") then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then
					Part.CanCollide = not Value
					Part.CanTouch = not Value
				end
			end
			Object:WaitForChild(_L("Humanoid")).Health = 0
		end
	end
end)







-- Archives

Groupboxes.Archives_Misc = Tabs.Archives:AddRightGroupbox(_L("Exploits / Anti"))
Groupboxes.Archives_Misc:AddToggle(_L("AntiRansom"), { Text = _L("Anti Ransom"), Default = false, Tooltip = _L("Prevents 'Ransom' from attacking you.") })
Groupboxes.Archives_Misc:AddToggle(_L("AntiClosetTrash"), { Text = _L("Anti Closet Trash"), Default = false, Tooltip = _L("Prevents 'Closet Trash' from spawning.") })
Groupboxes.Archives_Misc:AddToggle(_L("ForgetMeNotSolver"), { Text = _L("Forget Me Not Skipper"), Default = false, Tooltip = _L("Automatically Skippes Forget Me Not doors.") })
Groupboxes.Archives_Misc:AddToggle(_L("TimeShower"), { Text = _L("Time Shower"), Default = false, Tooltip = _L("Shows the Archives clock time.") })
Groupboxes.Archives_Misc:AddToggle(_L("BypassDronesStampede"), { Text = _L("Stop Time/Anti Stampede"), Default = false, Tooltip = _L("Prevents 'The Drones Stampede' from attacking you.") })
Groupboxes.Archives_Misc:AddToggle(_L("HonchoCorrectBoxESP"), { Text = _L("Correct Box ESP/Auto Interact"), Default = false, Tooltip = _L("ESP correct Archives boxes in the Honcho sequence and automatically interact with the correct deposit.") })

TimeShowerLabel = Instance.new(_L("TextLabel"))
TimeShowerLabel.Name = _L("TimeShower")
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
TimeShowerLabel.Text = _L("Time: --:--")
TimeShowerLabel.Visible = false
TimeShowerLabel.Parent = Container



local function GetArchivesClockLabel(Room)
	local Assets = Room and Room:FindFirstChild(_L("Assets"), true)
	local Clock = Assets and Assets:FindFirstChild(_L("ArchivesClock"), true)
	local Time = Clock and Clock:FindFirstChild(_L("Time"), true)
	local TextLabel = Time and Time:FindFirstChild(_L("TextLabel"))
	return (TextLabel and TextLabel:IsA(_L("TextLabel"))) and TextLabel or nil
end

local function ResolveClockLabel()
	if TimeShowerSourceLabel and TimeShowerSourceLabel.Parent and TimeShowerSourceLabel:IsDescendantOf(game) then
		return TimeShowerSourceLabel
	end
	local currentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
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
	local clock = label:FindFirstAncestor(_L("ArchivesClock"))
	if not clock then return nil end
	local remote = clock:FindFirstChild(_L("LookedAtRemote"), true)
	return (remote and remote:IsA(_L("RemoteEvent"))) and remote or nil
end

task.spawn(function()
	local lastCheckedRoomCount = 0
	while game:IsLoaded() do
		local currentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
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
		TimeShowerLabel.Text = _L("Time: --:--")
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
		TimeShowerLabel.Text = TextLabel and (_L("Time: ") .. TextLabel.Text) or _L("Time: --:--")
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
	local CurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
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
		local HonchoRoom = Room:FindFirstChild(_L("ArchivesHonchoRoom"), true)
		if not HonchoRoom then
			HonchoProcessedRooms[Room] = nil
			return
		end
		local BoxIDs = {}
		local RoomNumber = tonumber(Room.Name)
		for _, Desc in ipairs(Room:GetDescendants()) do
			local name = Desc.Name
			if name == _L("ArchivesPackageDeposit") or name:match(_L("^ArchivesPackageDeposit")) then
				local id = Desc:GetAttribute(_L("BoxID"))
				if id ~= nil then
					local idStr = tostring(id)
					BoxIDs[idStr] = true
					HonchoDepositCache[idStr] = Desc
					AddHonchoESP(Desc, _L("Deposit (") .. idStr .. _L(")"))
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
			if Child.Name == _L("ArchivesStorageBox") then
				local ToolBoxID = Child:GetAttribute(_L("Tool_BoxID"))
				if ToolBoxID ~= nil and BoxIDs[tostring(ToolBoxID)] then
					if not Child:GetAttribute(_L("ParentRoom")) then
						Child:SetAttribute(_L("ParentRoom"), RoomNumber)
					end
					Child.Name = _L("ArchivesStorageBoxCorrect")
					AddHonchoESP(Child, _L("Correct Box (") .. tostring(ToolBoxID) .. _L(")"))
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
	HonchoAutoDepositConnection = game:GetService(_L("RunService")).Heartbeat:Connect(function()
		if not Toggles.HonchoCorrectBoxESP.Value then return end
		local now = os.clock()
		if now - lastCheck < 0.1 then return end
		lastCheck = now
		local Character = LocalPlayer and LocalPlayer.Character
		local HumanoidRootPart = Character and Character:FindFirstChild(_L("HumanoidRootPart"))
		if not Character or not HumanoidRootPart then return end
		local BoxCandidates = {}
		for _, Object in ipairs(Character:GetChildren()) do
			if (Object:IsA(_L("Tool")) or Object:IsA(_L("Model"))) and (Object.Name == _L("ArchivesStorageBox") or Object.Name == _L("ArchivesStorageBoxCorrect")) then
				BoxCandidates[#BoxCandidates + 1] = Object
			end
		end
		local Drops = workspace:FindFirstChild(_L("Drops"))
		if Drops then
			for _, Object in ipairs(Drops:GetChildren()) do
				if Object.Name == _L("ArchivesStorageBox") or Object.Name == _L("ArchivesStorageBoxCorrect") then
					BoxCandidates[#BoxCandidates + 1] = Object
				end
			end
		end
		for _, Box in ipairs(BoxCandidates) do
			if not (Box and Box.Parent) then continue end
			local BoxID = Box:GetAttribute(_L("Tool_BoxID")) or Box:GetAttribute(_L("BoxID"))
			if BoxID == nil then continue end
			local Deposit = HonchoDepositCache[tostring(BoxID)]
			if not Deposit or not Deposit.Parent then continue end
			if Box.Parent == Drops and not Box:GetAttribute(_L("HonchoCorrectESP")) then
				Box:SetAttribute(_L("HonchoCorrectESP"), true)
				AddHonchoESP(Box, _L("Correct Box (") .. tostring(BoxID) .. _L(")"))
			end
			if Box.Parent == Character then
				local DepositPart = Deposit:IsA(_L("BasePart")) and Deposit or Deposit:FindFirstChildWhichIsA(_L("BasePart"), true)
				if DepositPart and (HumanoidRootPart.Position - DepositPart.Position).Magnitude <= 10 then
					local Prompt = Deposit:FindFirstChildWhichIsA(_L("ProximityPrompt"), true)
					if Prompt then
						fireproximityprompt(Prompt)
					end
				end
			end
		end
	end)
end)


Groupboxes.Archives_Bypasses = Tabs.Archives:AddLeftGroupbox(_L("Bypasses"))
Groupboxes.Archives_Bypasses:AddToggle(_L("BypassWater"), { Text = _L("Bypass Electric Water"), Default = false, Tooltip = _L("Prevents electric water from hurting you.") })
Groupboxes.Archives_Bypasses:AddToggle(_L("BypassAlma"), { Text = _L("Bypass Alma"), Default = false, Tooltip = _L("Prevents 'Alma' from spawning.") })
Groupboxes.Archives_Bypasses:AddToggle(_L("BypassDrones"), { Text = _L("Bypass Drones"), Default = false, Tooltip = _L("Prevents 'Drones' from attacking you.") })
Groupboxes.Archives_Bypasses:AddToggle(_L("AntiScribbles"), { Text = _L("Bypass Scribbles"), Default = false, Tooltip = _L("Prevents 'Scribbles' from attacking you.") })

Groupboxes.Archives_Experimental = Tabs.Archives:AddLeftGroupbox(_L("Experimental"))

Toggles.AntiClosetTrash:OnChanged(function(Value)
	if AntiClosetTrash_Connection then
		AntiClosetTrash_Connection:Disconnect()
		AntiClosetTrash_Connection = nil
	end
	if not Value then return end
	AntiClosetTrash_Connection = workspace.ChildAdded:Connect(function(Child)
		if not Toggles.AntiClosetTrash.Value then return end
		local Name = Child.Name
		if Name:sub(1, 6) == _L("Binder") or Name:sub(1, 4) == _L("Shoe") or Name:sub(1, 5) == _L("Shelf") then
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
		if Child.Name == _L("Ransom") and Toggles.AntiRansom.Value then
			Child:Destroy()
			print(_L("Ransom gone hehehehehehehehe"))
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
				local LookAt = Obj:FindFirstChild(_L("LookAt"))
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

		if not Room:FindFirstChild(_L("ForgetMeNotVineDoors"), true) then
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

			local Door = NextRoom:FindFirstChild(_L("Door"))

			if not Door then
				local Character = GetCharacter()
				if Character then
					local Target = NextRoom:FindFirstChildWhichIsA(_L("BasePart")) or NextRoom
					if Target:IsA(_L("BasePart")) then
						Character:PivotTo(Target.CFrame + Vector3.new(0, 3, 0))
					elseif Target:IsA(_L("Model")) then
						Character:PivotTo(Target:GetPivot() + Vector3.new(0, 3, 0))
					else
						Character:PivotTo(CFrame.new(NextRoom:GetPivot().Position + Vector3.new(0, 5, 0)))
					end
				end
				break
			end

			if Door:GetAttribute(_L("Opened")) == true then
				VoidCharacter()
				break
			end

			local Hidden = Door:FindFirstChild(_L("Hidden")) or Door:WaitForChild(_L("Hidden"), 2)
			if not Hidden then
				task.wait(0.3)
				continue
			end

			while ForgetMeNotRunning and Room.Parent and NextRoom.Parent and Door.Parent and Door:GetAttribute(_L("Opened")) ~= true do
				local Character = GetCharacter()
				if Character then
					if Hidden:IsA(_L("BasePart")) then
						Character:PivotTo(Hidden.CFrame)
					elseif Hidden:IsA(_L("Model")) then
						Character:PivotTo(Hidden:GetPivot())
					end
				end
				pcall(function() Door.ClientOpen:Fire() end)
				pcall(function() Door.ClientOpen:FireServer() end)
				task.wait()
			end

			if ForgetMeNotRunning and Door.Parent and Door:GetAttribute(_L("Opened")) == true then
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
	Functions.Notify({ Title = _L("PositionSpoof Will Break This!.") })

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

		local WaterBypassWater = WaterBypassRoom:FindFirstChild(_L("Water"))
		if not WaterBypassWater or WaterParts[WaterBypassWater] then return end

		local WaterBypassPart = Instance.new(_L("Part"))
		WaterBypassPart.Name = _L("WaterBypass")
		WaterBypassPart.Anchored = true
		WaterBypassPart.CanCollide = true
		WaterBypassPart.CanTouch = false
		WaterBypassPart.CanQuery = false
		WaterBypassPart.Transparency = 0.25
		WaterBypassPart.Color = Color3.fromRGB(0, 150, 255)
		WaterBypassPart.Material = Enum.Material.ForceField

		local WaterBypassSize, WaterBypassCFrame
		if WaterBypassWater:IsA(_L("BasePart")) then
			WaterBypassSize = WaterBypassWater.Size
			WaterBypassCFrame = WaterBypassWater.CFrame
		elseif WaterBypassWater:IsA(_L("Model")) then
			WaterBypassCFrame, WaterBypassSize = WaterBypassWater:GetBoundingBox()
		else
			WaterBypassSize = Vector3.new(10, 1.5, 10)
			WaterBypassCFrame = WaterBypassWater:GetPivot()
		end

		WaterBypassPart.Size = WaterBypassSize + Vector3.new(0, 0.5, 0)
		WaterBypassPart.CFrame = WaterBypassCFrame * CFrame.new(0, 0.25, 0)

		if WaterBypassPart.Size.Y > 3 then
			WaterBypassPart:Destroy()
			Functions.Notify({ Title = _L("Water Bypass removed: Softlock.") })
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
			if child.Name == _L("Alma") then child:Destroy() end
		end
		AlmaConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == _L("Alma") then child:Destroy() end
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
		if Child.Name == _L("Scribbles") and Toggles.AntiScribbles.Value then
			local ExploitSribbleWarning = Child:FindFirstChild(_L("IfYoureExploitingDeleteThis"))
			if ExploitSribbleWarning then ExploitSribbleWarning:Destroy() end
		end
	end)
end)

Toggles.BypassDrones:OnChanged(function(Value)
	local RS = game:GetService(_L("ReplicatedStorage"))
	local function ProcessDrones(drones)
		local WalkedInto = drones:FindFirstChild(_L("WalkedInto")) or drones:WaitForChild(_L("WalkedInto"), 3)
		if WalkedInto and not DroneWalkedIntoParents[WalkedInto] then
			DroneWalkedIntoParents[WalkedInto] = drones
			WalkedInto.Parent = RS
		end
	end
	if Value then
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == _L("Drones") then ProcessDrones(child) end
		end
		if DroneConnection then DroneConnection:Disconnect() end
		DroneConnection = workspace.ChildAdded:Connect(function(child)
			if child.Name == _L("Drones") then ProcessDrones(child) end
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

Groupboxes.Stairwell_Misc = Tabs.Stairwell:AddLeftGroupbox(_L("Exploits / Anti / Misc"))



Groupboxes.Stairwell_Misc:AddDivider()
Groupboxes.Stairwell_Misc:AddToggle(_L("BypassNoise"), { Text = _L("Noise Tv Breaker"), Default = false, Tooltip = _L("Breaks the tv of noise while holding it.") })


Groupboxes.Stairwell_Misc:AddToggle(_L("DroppedItemValue"), { Text = _L("Item Number"), Default = false, Tooltip = _L("Shows the number of dropped items.") })

Groupboxes.Stairwell_Misc:AddToggle(_L("KillAllWithCart"), {
	Text = _L("Kill All (Requires ≥1 Cart)"),
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle(_L("FlingCreak"), {
	Text = _L("Bug Out Creak (Requires ≥5 Cart)"),
	Default = false,
	ToolTip = _L("DONT TOUCH THE CARTS URSELF, U WILL DIE")
})
Groupboxes.Stairwell_Misc:AddToggle(_L("CreakAggressionMeter"), {
    Text = _L("Creak Aggression Meter"),
    Default = false,
    Tooltip = _L("Shows Creak's aggression above its head.")
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
    local CreakAnimator = CreakModel:FindFirstChildOfClass(_L("Animator"))
        or (CreakModel:FindFirstChild(_L("AnimationController")) and CreakModel.AnimationController:FindFirstChildOfClass(_L("Animator")))
        or CreakModel:FindFirstChildOfClass(_L("AnimationController"))

    if not CreakAnimator then return nil end

    for _, CreakAnimationTrack in ipairs(CreakAnimator:GetPlayingAnimationTracks()) do
        if CreakAnimationTrack.Name == _L("CreakGraph") or (CreakAnimationTrack.Animation and CreakAnimationTrack.Animation.Name == _L("CreakGraph")) then
            local CreakSuccess, CreakAggressionValue = pcall(CreakAnimationTrack.GetParameter, CreakAnimationTrack, _L("Aggression"))
            if CreakSuccess and typeof(CreakAggressionValue) == _L("number") then
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

    local CreakTitleText = CreateCreakDrawing(_L("Text"))
    CreakTitleText.Text = _L("Aggression --%")
    CreakTitleText.Size = 16
    CreakTitleText.Font = Drawing.Fonts.Plex
    CreakTitleText.Color = Color3.fromRGB(255, 255, 255)
    CreakTitleText.Center = true
    CreakTitleText.Outline = true
    CreakTitleText.Visible = false

    local CreakBarBackground = CreateCreakDrawing(_L("Square"))
    CreakBarBackground.Size = Vector2.new(112, 6)
    CreakBarBackground.Filled = true
    CreakBarBackground.Color = Color3.fromRGB(58, 58, 64)
    CreakBarBackground.Transparency = 0.15
    CreakBarBackground.Visible = false

    local CreakBarFill = CreateCreakDrawing(_L("Square"))
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
    if not Toggles.CreakAggressionMeter.Value or CreakModel.Name ~= _L("Creak") or CreakAggressionMetersTable[CreakModel] then
        return
    end

    local CreakHeadPart = CreakModel:FindFirstChild(_L("Head"))
    if not CreakHeadPart or not CreakHeadPart:IsA(_L("BasePart")) then return end

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
            CreakMeterData.TitleText.Text = _L("Aggression --%")
            CreakMeterData.TitleText.Color = Color3.fromRGB(200, 200, 200)
            CreakMeterData.BarFill.Size = Vector2.new(0, 6)
            CreakMeterData.TitleText.Visible = true
            CreakMeterData.BarBackground.Visible = true
            CreakMeterData.BarFill.Visible = false
            return
        end

        CreakMeterData.TitleText.Text = _L("Aggression ") .. math.floor(CreakAggressionValue * 100 + 0.5) .. _L("%")
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

    local CreakLiveEntitiesFolder = Workspace:FindFirstChild(_L("LiveEntities"))
    if not CreakLiveEntitiesFolder then return end

    CreakAggressionChildAddedConnection = CreakLiveEntitiesFolder.ChildAdded:Connect(function(CreakNewChild)
        if CreakNewChild.Name == _L("Creak") then
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

        local CreakLiveEntitiesFolder = Workspace:FindFirstChild(_L("LiveEntities"))
        local CreakExistingModel = CreakLiveEntitiesFolder and CreakLiveEntitiesFolder:FindFirstChild(_L("Creak"))
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
				if KillAllWithCartModel.Name == _L("ShoppingCart") and KillAllWithCartModel:IsA(_L("Model")) then
					KillAllWithCartCarts[#KillAllWithCartCarts + 1] = KillAllWithCartModel
				end
			end

			local KillAllWithCartAlivePlayers = {}
			for _, KillAllWithCartPlayer in ipairs(game.Players:GetPlayers()) do
				if KillAllWithCartPlayer ~= game.Players.LocalPlayer and KillAllWithCartPlayer.Character then
					local KillAllWithCartHumanoid = KillAllWithCartPlayer.Character:FindFirstChildOfClass(_L("Humanoid"))
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
			local creak = workspace:FindFirstChild(_L("LiveEntities")) and workspace.LiveEntities:FindFirstChild(_L("Creak"))
			if creak then
				local targetCFrame = creak:GetPivot()
				for _, model in ipairs(workspace.Misc:GetChildren()) do
					if model.Name == _L("ShoppingCart") and model:IsA(_L("Model")) then
						model:PivotTo(targetCFrame)
					end
				end
			end
			task.wait(0.10)
		end
	end)
end)




Groupboxes.Stairwell_Misc:AddDivider()


Groupboxes.Stairwell_Misc:AddToggle(_L("DisableStairwellCrusherCollision"), {
	Text = _L("Disable Crushers"),
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle(_L("DeleteStairwellCrusherExceptBasicWall"), {
	Text = _L("Delete Crushers"),
	Default = false,
})
Groupboxes.Stairwell_Misc:AddToggle(_L("MeldRemover"), {
	Text = _L("Remove Meld"),
	Default = false,
})

Groupboxes.Stairwell_Misc:AddToggle(_L("StairwellLandingSpam"), {
	Text = _L("TP to trash and drop trash."),
	Tooltip = _L("Combine with orbit, or bring all dropped items."),
	Default = false,
})

Toggles.DisableStairwellCrusherCollision:OnChanged(function(DisableStairwellCrusherCollisionState)
	if not DisableStairwellCrusherCollisionState then return end

	task.spawn(function()
		while Toggles.DisableStairwellCrusherCollision.Value do
			for _, DisableStairwellCrusherRoom in ipairs(workspace.CurrentRooms:GetChildren()) do
				local DisableStairwellCrusherAssets = DisableStairwellCrusherRoom:FindFirstChild(_L("Assets"))
				if DisableStairwellCrusherAssets then
					for _, DisableStairwellCrusherContainer in ipairs(DisableStairwellCrusherAssets:GetChildren()) do
						if DisableStairwellCrusherContainer.Name == _L("StairwellCrusherContainer1") then
							for _, DisableStairwellCrusherDescendant in ipairs(DisableStairwellCrusherContainer:GetDescendants()) do
								if DisableStairwellCrusherDescendant:IsA(_L("BasePart")) and DisableStairwellCrusherDescendant.CanCollide then
									local DisableStairwellCrusherUnderBasicWall = false
									local DisableStairwellCrusherParent = DisableStairwellCrusherDescendant.Parent
									while DisableStairwellCrusherParent and DisableStairwellCrusherParent ~= DisableStairwellCrusherContainer do
										if DisableStairwellCrusherParent.Name == _L("BasicWall") then
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

						local DisableStairwellCrusher = DisableStairwellCrusherContainer:FindFirstChild(_L("StairwellCrusher"))
						if DisableStairwellCrusher then
							local DisableStairwellCrusherOuterTrigger = DisableStairwellCrusher:FindFirstChild(_L("OuterTrigger"))
							local DisableStairwellCrusherCoreTrigger = DisableStairwellCrusher:FindFirstChild(_L("CoreTrigger"))
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
				local DeleteStairwellCrusherAssets = DeleteStairwellCrusherRoom:FindFirstChild(_L("Assets"))
				if DeleteStairwellCrusherAssets then
					for _, DeleteStairwellCrusherContainer in ipairs(DeleteStairwellCrusherAssets:GetChildren()) do
						if DeleteStairwellCrusherContainer.Name == _L("StairwellCrusherContainer1") then
							local DeleteStairwellCrusherToDestroy = {}
							for _, DeleteStairwellCrusherDescendant in ipairs(DeleteStairwellCrusherContainer:GetDescendants()) do
								local DeleteStairwellCrusherUnderBasicWall = false
								local DeleteStairwellCrusherParent = DeleteStairwellCrusherDescendant.Parent
								while DeleteStairwellCrusherParent and DeleteStairwellCrusherParent ~= DeleteStairwellCrusherContainer do
									if DeleteStairwellCrusherParent.Name == _L("BasicWall") then
										DeleteStairwellCrusherUnderBasicWall = true
										break
									end
									DeleteStairwellCrusherParent = DeleteStairwellCrusherParent.Parent
								end
								if not DeleteStairwellCrusherUnderBasicWall and DeleteStairwellCrusherDescendant.Name ~= _L("BasicWall") then
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
				for _, folderName in ipairs({_L("Assets"), _L("Parts")}) do
					local folder = room:FindFirstChild(folderName)
					if folder then
						for _, child in ipairs(folder:GetChildren()) do
							if child.Name == _L("MeldWall")
								or child.Name == _L("Boleahghth29tdgfhy2thuy2htuu259uhh3u") -- no qeustions asked
							then
								child:Destroy()
							end
						end
					end
				end
				for _, name in ipairs({_L("MeldData"), _L("MeldPads"), _L("Meldview"), _L("Meld")}) do
					local obj = room:FindFirstChild(name)
					if obj and obj:IsA(_L("Folder")) then
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
				local StairwellLandingLogic = Room:FindFirstChild(_L("StairwellLandingLogic"))

				if StairwellLandingLogic then
					for _, Model in ipairs(StairwellLandingLogic:GetChildren()) do
						if Model:IsA(_L("Model")) then
							local Prompts = {}

							for _, Object in ipairs(Model:GetDescendants()) do
								if Object:IsA(_L("ProximityPrompt")) then
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
					local HumanoidRootPart = Character and Character:FindFirstChild(_L("HumanoidRootPart"))

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

Groupboxes.Stairwell_Misc:AddButton(_L("TP Shopping Carts To Player"), function()
	local ShoppingCartTargetName = Options.ShoppingCartTarget.Value
	local ShoppingCartTargetPlayer = game.Players:FindFirstChild(ShoppingCartTargetName)
	if not ShoppingCartTargetPlayer or not ShoppingCartTargetPlayer.Character then return end
	local ShoppingCartTargetCFrame = ShoppingCartTargetPlayer.Character:GetPivot()
	for _, ShoppingCartModel in ipairs(workspace.Misc:GetChildren()) do
		if ShoppingCartModel.Name == _L("ShoppingCart") and ShoppingCartModel:IsA(_L("Model")) then
			ShoppingCartModel:PivotTo(ShoppingCartTargetCFrame)
		end
	end
end)

Groupboxes.Stairwell_Misc:AddDropdown(_L("ShoppingCartTarget"), {
	Text = _L("Shopping Cart Target"),
	Values = (function()
		local ShoppingCartPlayerNames = {}
		for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
			ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
		end
		return ShoppingCartPlayerNames
	end)(),
	Default = game.Players.LocalPlayer.Name,
})

Groupboxes.Stairwell_Misc:AddButton(_L("Refresh Players"), function()
	local ShoppingCartPlayerNames = {}
	for _, ShoppingCartPlayer in ipairs(game.Players:GetPlayers()) do
		ShoppingCartPlayerNames[#ShoppingCartPlayerNames + 1] = ShoppingCartPlayer.Name
	end
	Options.ShoppingCartTarget:SetValues(ShoppingCartPlayerNames)
end)

Groupboxes.Stairwell_Experimental = Tabs.Stairwell:AddRightGroupbox(_L("Experimental"))


local function TPDropsToNearestGrinder()
    local TPDropsToNearestGrinderDropsFolder =
        workspace:FindFirstChild(_L("Drops"))

    local TPDropsToNearestGrinderRootPart =
        Character and Character:FindFirstChild(_L("HumanoidRootPart"))

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
                _L("StairwellScrapper"),
                true
            )

        if TPDropsToNearestGrinderScrapper then
            for _, TPDropsToNearestGrinderObject in
                ipairs(TPDropsToNearestGrinderScrapper:GetDescendants()) do

                if TPDropsToNearestGrinderObject.Name == _L("Grinder1")
                    and (
                        TPDropsToNearestGrinderObject:IsA(_L("Model"))
                        or TPDropsToNearestGrinderObject:IsA(_L("BasePart"))
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

        if TPDropsToNearestGrinderDropItem:IsA(_L("Model"))
            or TPDropsToNearestGrinderDropItem:IsA(_L("BasePart")) then

            TPDropsToNearestGrinderDropItem:PivotTo(
                TPDropsToNearestGrinderCFrame
            )
        end
    end
end

Groupboxes.Stairwell_Experimental:AddButton({
    Text = _L("TP All Drops to Nearest Grinder"),
    Func = TPDropsToNearestGrinder,
    DoubleClick = false,
    Tooltip = _L("Teleports every dropped item to the grinder closest to you"),
})

local function BringDroppedItems()
	local workspaceDropsFolder = workspace:FindFirstChild(_L("Drops"))
	if LocalPlayer and LocalPlayer.Character then
		local playerHumanoidRootPart = LocalPlayer.Character:FindFirstChild(_L("HumanoidRootPart"))
		if playerHumanoidRootPart and workspaceDropsFolder then
			for _, itemToBring in ipairs(workspaceDropsFolder:GetChildren()) do
				if itemToBring:IsA(_L("Model")) then
					itemToBring:PivotTo(playerHumanoidRootPart.CFrame)
				elseif itemToBring:IsA(_L("BasePart")) then
					itemToBring.CFrame = playerHumanoidRootPart.CFrame
				end
			end
		end
	end
end

Groupboxes.Stairwell_Experimental:AddButton({
	Text = _L("Bring Dropped Items"),
	Func = function() BringDroppedItems() end,
	DoubleClick = false,
	Tooltip = _L("Brings all dropped items.")
})

Groupboxes.Stairwell_Experimental:AddToggle(_L("EnableDroppedItemsInterval"), {
	Text = _L("Enable Interval"),
	Default = false,
	Tooltip = _L("Automatically brings dropped items at the selected interval.")
})

Groupboxes.Stairwell_Experimental:AddSlider(_L("DroppedItemsInterval"), {
	Text = _L("Interval"),
	Default = 1,
	Min = 0,
	Max = 60,
	Rounding = 1,
	Compact = false,
	Tooltip = _L("How often dropped items are brought.")
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

Groupboxes.Stairwell_Experimental:AddToggle(_L("OrbitDroppedItems"), {
	Text = _L("Orbit Dropped Items"),
	Default = false,
	Tooltip = _L("Orbits dropped items around you. Teleports them to you every 10s to prevent despawn.")
})

Groupboxes.Stairwell_Experimental:AddSlider(_L("OrbitDroppedItemsHeight"), {
	Text = _L("Height"),
	Default = 2,
	Min = -20,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = _L("The height of the orbit.")
})

Groupboxes.Stairwell_Experimental:AddSlider(_L("OrbitDroppedItemsDistance"), {
	Text = _L("Distance"),
	Default = 5,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Compact = false,
	Tooltip = _L("The distance of the orbit.")
})

Groupboxes.Stairwell_Experimental:AddSlider(_L("OrbitDroppedItemsSpeed"), {
	Text = _L("Speed"),
	Default = 2,
	Min = 0,
	Max = 20,
	Rounding = 1,
	Compact = false,
	Tooltip = _L("The speed of the orbit.")
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
		local OrbitDroppedItemsHumanoidRootPart = LocalPlayer.Character:FindFirstChild(_L("HumanoidRootPart"))
		local OrbitDroppedItemsDropsFolder = workspace:FindFirstChild(_L("Drops"))
		if not OrbitDroppedItemsHumanoidRootPart or not OrbitDroppedItemsDropsFolder then return end
		local OrbitDroppedItemsHeightValue = Options.OrbitDroppedItemsHeight.Value
		local OrbitDroppedItemsDistanceValue = Options.OrbitDroppedItemsDistance.Value
		local OrbitDroppedItemsSpeedValue = Options.OrbitDroppedItemsSpeed.Value
		local OrbitDroppedItemsCurrentTime = tick()
		local OrbitDroppedItemsList = {}
		for _, OrbitDroppedItemsObject in ipairs(OrbitDroppedItemsDropsFolder:GetChildren()) do
			if OrbitDroppedItemsObject:IsA(_L("Model")) or OrbitDroppedItemsObject:IsA(_L("BasePart")) then
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
				if OrbitDroppedItemsObject:IsA(_L("Model")) then
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
			if OrbitDroppedItemsObject:IsA(_L("Model")) then
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
		if not targetTvStand:IsA(_L("Model")) then return end
		if targetTvStand.Name ~= _L("TV_Stand") then return end

		local tvStandCurrentCFrame = targetTvStand:GetPivot()

		if tvStandCurrentCFrame.Position.Y > -119 then
			targetTvStand:PivotTo(CFrame.new(
				tvStandCurrentCFrame.Position.X,
				-120,
				tvStandCurrentCFrame.Position.Z
			))
		end
	end

	local bypassNoiseMiscFolder = workspace:FindFirstChild(_L("Misc"))
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
	local DroppedItemValueScreenGui = game:GetService(_L("CoreGui")):FindFirstChild(_L("DropsCoinCounter"))
	if not DroppedItemValue then
		if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
		return
	end
	local DroppedItemValueWorkspaceDrops = workspace:WaitForChild(_L("Drops"))
	if DroppedItemValueScreenGui then DroppedItemValueScreenGui:Destroy() end
	DroppedItemValueScreenGui = Instance.new(_L("ScreenGui"))
	DroppedItemValueScreenGui.Name = _L("DropsCoinCounter")
	DroppedItemValueScreenGui.ResetOnSpawn = false
	DroppedItemValueScreenGui.Parent = game:GetService(_L("CoreGui"))
	local DroppedItemValueCoinText = Instance.new(_L("TextLabel"))
	DroppedItemValueCoinText.Name = _L("CoinText")
	DroppedItemValueCoinText.AnchorPoint = Vector2.new(0.5, 0)
	DroppedItemValueCoinText.Position = UDim2.new(0.5, 0, 0.02, 0)
	DroppedItemValueCoinText.Size = UDim2.new(0, 250, 0, 40)
	DroppedItemValueCoinText.BackgroundTransparency = 1
	DroppedItemValueCoinText.Text = _L("Items: 0")
	DroppedItemValueCoinText.TextSize = 24
	DroppedItemValueCoinText.Font = Enum.Font.GothamBold
	DroppedItemValueCoinText.TextColor3 = Color3.fromRGB(255, 255, 255)
	DroppedItemValueCoinText.TextStrokeTransparency = 0.5
	DroppedItemValueCoinText.Parent = DroppedItemValueScreenGui
	local DroppedItemValueCountedDrops = {}
	task.spawn(function()
		while Toggles.DroppedItemValue.Value do
			for _, DroppedItemValueDrop in ipairs(DroppedItemValueWorkspaceDrops:GetChildren()) do
				if DroppedItemValueDrop:IsA(_L("Model")) and not DroppedItemValueCountedDrops[DroppedItemValueDrop] then
					DroppedItemValueDrop:SetAttribute(_L("CoinsChecked"), true)
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
			DroppedItemValueCoinText.Text = _L("Items: ") .. DroppedItemValueTotalItems
			task.wait(1)
		end
		if DroppedItemValueScreenGui and DroppedItemValueScreenGui.Parent then
			DroppedItemValueScreenGui:Destroy()
		end
	end)
end)

-- hi

Groupboxes.Exploits_BypassRight = Tabs.Exploits:AddRightGroupbox(_L("Bypass"))
Groupboxes.Exploits_BypassRight:AddToggle(_L("DisableAnticheat"), {
	Text = _L("Anticheat Bypass"), Default = false,
	Tooltip = _L("Completely disables the anticheat, after interacting with a ladder.")
})
Groupboxes.Exploits_BypassRight:AddToggle(_L("VelocityManipulationToggle"), {
	Text = _L("Velocity Manipulation"), Default = false,
	Tooltip = _L("Moves your character forward slowly, mitigating the game's anti-noclip.")
})
Toggles.DisableAnticheat:OnChanged(function(Value)
	if Globals.AnticheatDisabled == true and not Value then
		RemotesFolder.ClimbLadder:FireServer()
		Globals.AnticheatDisabled = false
	end
end)
Toggles.VelocityManipulationToggle:AddKeyPicker(_L("VelocityManipulationKeybind"), {
	Text = _L("Velocity Manipulation"), Default = _L("V"),
	Mode = Library.IsMobile and _L("Toggle") or _L("Hold"), SyncToggleState = true
})
Groupboxes.Exploits_BypassRight:AddDropdown(_L("VelocityManipulationMode"), {
	Values = {_L("Velocity"), _L("Pivot")}, Text = _L("Manipulation Method"),
	Default = 1,
})

Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle(_L("InfiniteItemsToggle"), {
	Text = _L("Infinite Items"), Default = false,
	Tooltip = _L("Allows certain items to be used without draining their uses."),
	Disabled = not Functions.CheckCompatability({_L("fireproximityprompt")}),
	DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Exploits_BypassRight:AddDropdown(_L("InfiniteItemsList"), {
	Text = _L("Item List"),
	Values = { _L("Lockpicks"), _L("Skeleton Key"), _L("Shears"), _L("Multitool") },
	Multi = true, AllowNull = true,
	Disabled = not Functions.CheckCompatability({_L("fireproximityprompt")}),
	DisabledTooltip = Globals.IncompatibleMessage
})

Groupboxes.Exploits_BypassRight:AddToggle(_L("InfCrucifix"), {
	Text = _L("Infinite Crucifix"),
	Default = false,
	Tooltip = _L("Risky! You can die or lose the Crucifix. Recommended to have low ping and stable fps."),
	Risky = Floor ~= _L("Ballz"),
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
	print(_L("i allive"))
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

		local InfCrucifixCollision = InfCrucifixCharacter:FindFirstChild(_L("CollisionPart"))
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

			local InfCrucifixTool = InfCrucifixCharacter:FindFirstChildOfClass(_L("Tool"))
			if not InfCrucifixTool or InfCrucifixTool.Name ~= _L("Crucifix") then
				continue
			end

			task.spawn(function()
				ReplicatedStorage.RemotesFolder.DropItem:FireServer(InfCrucifixTool)
				task.wait(0.54)
				print(_L("hi"))
				local InfCrucifixDrops = Workspace:FindFirstChild(_L("Drops"))
				if not InfCrucifixDrops then
					return
				end

				local InfCrucifixDropped = InfCrucifixDrops:FindFirstChild(_L("Crucifix"))
				if not InfCrucifixDropped then
					return
				end

				local InfCrucifixPrompt = InfCrucifixDropped:FindFirstChildOfClass(_L("ProximityPrompt"))
				if InfCrucifixPrompt then
					fireproximityprompt(InfCrucifixPrompt)
				end
			end)
			print (_L("hi"))
			task.wait(0.6)
		end
	end)
end)


Groupboxes.Exploits_BypassRight:AddDivider()
Groupboxes.Exploits_BypassRight:AddToggle(_L("PositionSpoof"), {
	Text = _L("Position Spoof"), Default = false,
	Tooltip = _L("Makes your character appear underground on the server, protecting you from rush-like entities.")
})
Groupboxes.Exploits_BypassRight:AddToggle(_L("CrouchSpoof"), {
	Text = _L("Crouch Spoof"), Default = false, Tooltip = _L("Makes the game think you are always crouching.")
})
Toggles.PositionSpoof:OnChanged(function(Value)
	if Floor ~= _L("Fools") and Floor ~= _L("OldHotel") then
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
Toggles.PositionSpoof:AddKeyPicker(_L("PositionSpoof"), {
	Text = _L("Position Spoof"), Default = _L("B"), Mode = _L("Toggle"), SyncToggleState = true
})
Toggles.CrouchSpoof:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild(_L("Crouch")) then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Groupboxes.Exploits_Remove = Tabs.Exploits:AddRightGroupbox(_L("Remove"))
Groupboxes.Exploits_Remove:AddToggle(_L("RemoveScreech"), { Text = _L("Remove Screech"),  Default = false, Tooltip = _L("Prevents 'Screech' from spawning.") })
Groupboxes.Exploits_Remove:AddToggle(_L("RemoveHalt"),    { Text = _L("Remove Halt"),     Default = false, Tooltip = _L("Prevents 'Halt' from spawning.") })
Groupboxes.Exploits_Remove:AddToggle(_L("RemoveA90"),     { Text = _L("Remove A-90"),     Default = false, Tooltip = _L("Prevents 'A-90' from spawning.") })
Groupboxes.Exploits_Remove:AddToggle(_L("RemoveDread"),   { Text = _L("Remove Dread"),    Default = false, Tooltip = _L("Prevents 'Dread' from spawning.") })
Groupboxes.Exploits_Remove:AddToggle(_L("RemoveSurge"), { Text = _L("Remove Surge"), Default = false, Tooltip = _L("Prevents 'Surge' from spawning.")})
Groupboxes.Exploits_Remove:AddDivider()
Groupboxes.Exploits_Remove:AddToggle(_L("NoScreechDamage"), { Text = _L("No Screech Damage"), Default = false, Tooltip = _L("Prevents 'Screech' from hurting you.") })
Groupboxes.Exploits_Remove:AddToggle(_L("NoHaltDamage"),    { Text = _L("No Halt Damage"),    Default = false, Tooltip = _L("Prevents 'Halt' from hurting you.") })
Groupboxes.Exploits_Remove:AddToggle(_L("NoA90Damage"),     { Text = _L("No A-90 Damage"),    Default = false, Tooltip = _L("Prevents 'A-90' from hurting you.") })
Groupboxes.Exploits_Remove:AddToggle(_L("NoSurgeDamage"),   { Text = _L("No Surge Damage"),   Default = false, Tooltip = _L("Prevents 'Surge' from hurting you.") })

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
	if RemotesFolder:FindFirstChild(_L("A90")) then
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
	if RemotesFolder:FindFirstChild(_L("SurgeRemote")) then
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
				local Camera = workspace:FindFirstChild(_L("Camera"))

				if Camera then
					local Screech = Camera:FindFirstChild(_L("Screech"))

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
	Modules.Shade.Name = Value and _L("Shade_Disabled") or _L("Shade")
end)
Toggles.RemoveA90:OnChanged(function(Value)
	if Modules.A90 then
		Modules.A90.Name = Value and _L("A90_Disabled") or _L("A90")
	end
end)
Toggles.RemoveDread:OnChanged(function(Value)
	if Modules.Dread then
		Modules.Dread.Name = Value and _L("Dread_Disabled") or _L("Dread")
	end
end)
Toggles.RemoveSurge:OnChanged(function(Value)
	if Globals.SurgeFrame then
		Globals.SurgeFrame.Name = (Value and _L("SurgeVignette_Disabled") or _L("SurgeVignette"))
	end
end)

Groupboxes.Exploits_Audio = Tabs.Exploits:AddLeftGroupbox(_L("Audio"))
Globals.JamMuffle = Services.SoundService:WaitForChild(_L("Main")):FindFirstChild(_L("Jamming")) or Instance.new(_L("EqualizerSoundEffect"))

Groupboxes.Exploits_Audio:AddToggle(_L("RemoveFootstepSounds"),    { Text = _L("Remove Footstep Sounds"),    Default = false, Tooltip = _L("Removes the sounds when walking.") })
Groupboxes.Exploits_Audio:AddToggle(_L("RemoveJamminMusic"),       { Text = _L("Remove Jammin Music"),       Default = false, Tooltip = _L("Removes the music and muffle effect from the 'Jammin' modifier.") })
Groupboxes.Exploits_Audio:AddToggle(_L("RemoveInteractingSounds"), { Text = _L("Remove Interacting Sounds"), Default = false, Tooltip = _L("Removes the sounds when interacting with proximity prompts.") })

Toggles.RemoveJamminMusic:OnChanged(function(Value)
	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild(_L("Jam"))
	if Jam then
		Jam.Volume = Value and 0 or 0.45
		Globals.JamMuffle.Enabled = LiveModifiers:FindFirstChild(_L("Jammin")) and not Value or false
	end
end)
Toggles.RemoveInteractingSounds:OnChanged(function(Value)
	local PS = Globals.MainUI.Initiator.Main_Game.PromptService
	PS.Triggered.Volume   = Value and 0 or 0.04
	PS.Holding.Volume     = Value and 0 or 0.1
	PS.Notification.Volume = Value and 0 or 0.03
	Globals.MainUI.Initiator.Main_Game.Reminder.Caption.Volume = Value and 0 or 0.1
end)

Groupboxes.Visuals_LeftTab = Tabs.Visuals:AddLeftTabbox(_L("Camera / Effects"))
Groupboxes.Visuals_Camera = Groupboxes.Visuals_LeftTab:AddTab(_L("Camera"))
Groupboxes.Visuals_Camera:AddToggle(_L("AmbientToggle"), { Text = _L("Ambient"), Default = false, Tooltip = _L("Changes the lighting color to the specified value.") })
Groupboxes.Visuals_Camera:AddSlider(_L("FieldOfView"), { Text = _L("Field of View"), Min = 1, Max = 120, Default = 70, Rounding = 0 })
Groupboxes.Visuals_Camera:AddToggle(_L("FOVToggle"), {    Text = _L("Custom FOV"),    Default = false,    Tooltip = _L("Only applies the Field of View slider when enabled.") })
Toggles.FOVToggle:AddKeyPicker(_L("FovToggle"), {Text = _L("Custom Fov"), Default = _L("O"), Mode = _L("Toggle"), SyncToggleState = true})
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle(_L("RemoveCameraShake"), {
	Text = _L("Remove Camera Shake"), Default = false, Tooltip = _L("Prevents the camera from shaking."),
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle(_L("RemoveCameraBobbing"), {
	Text = _L("Remove Camera Bobbing"), Default = false, Tooltip = _L("Prevents the camera from bobbing when moving."),
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddToggle(_L("RemoveCutscenes"), { Text = _L("Remove Cutscenes"), Default = false, Tooltip = _L("Removes all non-necessary cutscenes.") })
Groupboxes.Visuals_Camera:AddToggle(_L("RemoveCameraFog"), { Text = _L("Remove Fog"), Default = false, Tooltip = _L("Removes all fog effects from the camera.") })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle(_L("ThirdPersonToggle"), { Text = _L("Third Person"), Default = false, Tooltip = _L("Zooms out your camera, allowing you to see your character from behind.") })
Toggles.ThirdPersonToggle:AddKeyPicker(_L("ThirdPersonKeybind"), { Text = _L("Third Person"), Default = _L("T"), Mode = _L("Toggle"), SyncToggleState = true })
Groupboxes.Visuals_Camera:AddSlider(_L("ThirdPersonOffsetX"), { Text = _L("X Offset"), Min = -10, Max = 10, Default = 1.5, Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider(_L("ThirdPersonOffsetY"), { Text = _L("Y Offset"), Min = -10, Max = 10, Default = 1,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddSlider(_L("ThirdPersonOffsetZ"), { Text = _L("Z Offset"), Min = -10, Max = 10, Default = 5,   Rounding = 1, Compact = true })
Groupboxes.Visuals_Camera:AddToggle(_L("ThirdPersonWallCheck"), { Text = _L("Wall Check"), Default = false, Tooltip = _L("Prevents third person from going through walls.") })
Groupboxes.Visuals_Camera:AddDivider()
Groupboxes.Visuals_Camera:AddToggle(_L("ViewmodelOffsetToggle"), {
	Text = _L("Viewmodel Offset"), Default = false, Tooltip = _L("Changes the offset of your viewmodel while holding an item."),
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Visuals_Camera:AddSlider(_L("ViewmodelOffsetX"), { Text = _L("X Offset"), Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider(_L("ViewmodelOffsetY"), { Text = _L("Y Offset"), Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage })
Groupboxes.Visuals_Camera:AddSlider(_L("ViewmodelOffsetZ"), { Text = _L("Z Offset"), Min = -10, Max = 10, Default = 0, Rounding = 1, Compact = true, Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage })

Toggles.AmbientToggle:AddColorPicker(_L("AmbientColor"), { Text = _L("Ambient"), Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.AmbientToggle:OnChanged(function(Value)
	local OldAmbient = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute(_L("CurrentRoom")))):GetAttribute(_L("Ambient"))
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
		Object.Density = Value and 0 or Object:GetAttribute(_L("Density_Old"))
	end
end)
Toggles.RemoveCutscenes:OnChanged(function(Value)
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA(_L("ModuleScript")) or table.find(CutsceneNames, Object:GetAttribute(_L("OriginalName"))) and Object:IsA(_L("ModuleScript")) then
            Object.Name = (Value and Object.Name .. _L("_Disabled") or Object:GetAttribute(_L("OriginalName")))
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA(_L("ModuleScript")) or table.find(CutsceneNames, Object:GetAttribute(_L("OriginalName"))) and Object:IsA(_L("ModuleScript")) then
            Object.Name = (Value and Object.Name .. _L("_Disabled") or Object:GetAttribute(_L("OriginalName")))
        end
    end
end)

Groupboxes.Visuals_Effects = Groupboxes.Visuals_LeftTab:AddTab(_L("Effects"))
Groupboxes.Visuals_Effects:AddToggle(_L("TransparentHidingSpotsToggle"), { Text = _L("Transparent Hiding Spots"), Default = false, Tooltip = _L("Makes a hiding spot transparent when you enter it.") })
Groupboxes.Visuals_Effects:AddSlider(_L("TransparentHidingSpotsSlider"), { Text = _L("Transparency"), Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true })

local function ApplyHidingTransparency(Value, SliderValue)
	for _, Object in Objects.HidingSpots do
		local IsHiding = false
		for _, Child in Object:GetDescendants() do
			if Child.Name == _L("HiddenPlayer") and Child.Value == Character then
				IsHiding = true
				break
			end
		end
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) and Part:GetAttribute(_L("Transparency_Old")) then
				Services.TweenService:Create(Part, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
					Transparency = (Value and IsHiding) and SliderValue or Part:GetAttribute(_L("Transparency_Old"))
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
Groupboxes.Visuals_Effects:AddToggle(_L("DisableGlitchJumpscare"),   { Text = _L("Disable Glitch Jumpscare"),   Default = false, Tooltip = _L("Disables the jumpscare from 'Glitch'") })
Groupboxes.Visuals_Effects:AddToggle(_L("DisableTimothyJumpscare"),  { Text = _L("Disable Timothy Jumpscare"),  Default = false, Tooltip = _L("Disables the jumpscare from 'Timothy'") })
Groupboxes.Visuals_Effects:AddToggle(_L("DisableVoidJumpscare"),     { Text = _L("Disable Void Jumpscare"),     Default = false, Tooltip = _L("Disables the jumpscare from 'Void'") })
Groupboxes.Visuals_Effects:AddDivider()
Groupboxes.Visuals_Effects:AddToggle(_L("DisableHideVignette"),      { Text = _L("Disable Hide Vignette"),      Default = false, Tooltip = _L("Disables the hiding screen effect.") })
Groupboxes.Visuals_Effects:AddToggle(_L("DisableFiredampEffect"),    { Text = _L("Disable Firedamp Effect"),    Default = false, Tooltip = _L("Disables the firedamp screen effect.") })
Groupboxes.Visuals_Effects:AddToggle(_L("DisableEntityJumpscares"),  { Text = _L("Disable Entity Jumpscares"),  Default = false, Tooltip = _L("Disables jumpscares from entities like Rush and Ambush.") })

Toggles.DisableGlitchJumpscare:OnChanged(function(Value)
	Modules.Glitch.Name = Value and _L("Glitch_Disabled") or _L("Glitch")
end)
Toggles.DisableTimothyJumpscare:OnChanged(function(Value)
	Modules.SpiderJumpscare.Name = Value and _L("SpiderJumpscare_Disabled") or _L("SpiderJumpscare")
end)
Toggles.DisableVoidJumpscare:OnChanged(function(Value)
	if Modules.Void then Modules.Void.Name = Value and _L("Void_Disabled") or _L("Void") end
end)
Toggles.DisableHideVignette:OnChanged(function(Value)
	local Vignette = Globals.MainUI:FindFirstChild(_L("HideVignette")) or Globals.MainUI.MainFrame:FindFirstChild(_L("HideVignette"))
	if Vignette then Vignette.Image = Value and _L("Disabled") or _L("rbxassetid://6100076320") end
end)
Toggles.DisableFiredampEffect:OnChanged(function(Value)
	for _, Object in CurrentRooms:GetChildren() do
		if Value then
			Object:SetAttribute(_L("Firedamp"), false)
			for _, FiredampObj in Camera:GetChildren() do
				if FiredampObj.Name == _L("LiveFiredamp") then FiredampObj:Destroy() end
			end
		else
			Object:SetAttribute(_L("Firedamp"), Object:GetAttribute(_L("Firedamp_Old")))
		end
	end
	local Old = LocalPlayer:GetAttribute(_L("CurrentRoom"))
	LocalPlayer:SetAttribute(_L("CurrentRoom"), 0)
	task.wait()
	LocalPlayer:SetAttribute(_L("CurrentRoom"), Old)
end)
Toggles.DisableEntityJumpscares:OnChanged(function(Value)
	local Jumpscares = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild(_L("Jumpscares"))
		or Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild(_L("Jumpscares_Disabled"))
	if Jumpscares then
		Jumpscares.Name = Value and _L("Jumpscares_Disabled") or _L("Jumpscares")
		for _, Object in Objects.JumpscareModules do
			Object.Name = Value and (Object:GetAttribute(_L("OriginalName")) .. _L("_Disabled")) or Object:GetAttribute(_L("OriginalName"))
		end
	end
end)

Groupboxes.Visuals_RightTab     = Tabs.Visuals:AddRightTabbox(_L("Entities / Settings / Entity Nodes"))
Groupboxes.Visuals_Entities     = Groupboxes.Visuals_RightTab:AddTab(_L("Entities"))
Groupboxes.Visuals_EntitySettings = Groupboxes.Visuals_RightTab:AddTab(_L("Settings"))

Groupboxes.Visuals_Entities:AddDropdown(_L("EntityList"), {
	Text = _L("Entity List"),
	Values = { _L("Rush"),_L("Bash"),_L("Scribbles"),_L("Teller"),_L("DronesStampede"),_L("Creak"),_L("Noise"),_L("Noise_TV"),_L("Balls"),_L("Portrait"),_L("Ambush"),_L("Eyes"),_L("Halt"),_L("Blitz"),_L("Lookman"),_L("Gloombat Swarm"),_L("A-60"),_L("A-120"),_L("Sally"),_L("Jeff the Killer"),_L("Groundskeeper"),_L("Monument"),_L("AR0xMBUSH"),_L("RNIUSHCG==") },
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyEntities"),    { Text = _L("Notify Entities"),    Default = false, Tooltip = _L("Sends a notification when an entity spawns.") })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle(_L("ShowEntityPath"), {
    Text = _L("Show Entity Path"),
    Default = false,
    Tooltip = _L("Shows the path of entitys.")
})


-- i dont wanna hear it okay? i was sick okay let me be okay fuck u okay




Groupboxes.Visuals_Entities:AddToggle(_L("ShowEntityPath"), {
    Text = _L("Show Entity Path"),
    Default = false,
    Tooltip = _L("Shows the path of entitys.")
})

Groupboxes.Visuals_Entities:AddSlider(_L("ShowEntityPathNodeTransparency"), {
    Text = _L("Node Transparency"),
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = _L("Transparency of the path nodes when shown")
})

Groupboxes.Visuals_Entities:AddSlider(_L("ShowEntityPathLineTransparency"), {
    Text = _L("Line Transparency"),
    Default = 0.15,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = _L("Transparency of the path lines")
})

Groupboxes.Visuals_Entities:AddSlider(_L("ShowEntityPathLineThickness"), {
    Text = _L("Line Thickness"),
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

    local ShowEntityPathLinePart = Instance.new(_L("Part"))
    ShowEntityPathLinePart.Name = _L("PathLine")
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
        if ShowEntityPathNode:IsA(_L("BasePart")) then
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
        local ShowEntityPathNodes = ShowEntityPathRoom:FindFirstChild(_L("PathfindNodes"))
        if ShowEntityPathNodes then
            for _, ShowEntityPathNode in ipairs(ShowEntityPathNodes:GetChildren()) do
                if ShowEntityPathNode:IsA(_L("BasePart")) then
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
        if ShowEntityPathRoom:FindFirstChild(_L("PathfindNodes")) then
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
            if ShowEntityPathRoom:WaitForChild(_L("PathfindNodes"), 5) then
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

Groupboxes.Visuals_Entities:AddDropdown(_L("NotifyItemList"), {
	Text = _L("Item List"),
	Values = ItemsToNotify,
	Multi = true, AllowNull = true
})
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyItemsToggle"),    { Text = _L("Notify Items"),    Default = false, Tooltip = _L("Sends a notification when an item spawns.") })
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyItemsShowDistance"),    { Text = _L("Show Distance"),    Default = false, Tooltip = _L("Shows how far away the item is in the notification.") })
Groupboxes.Visuals_Entities:AddDivider()
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyLibraryCode"), { Text = _L("Notify Library Code"), Default = false, Tooltip = _L("Automatically solves the code for the library padlock.") })
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyOxygen"),      { Text = _L("Notify Oxygen Level"), Default = false, Tooltip = _L("Shows how much oxygen you have remaining.") })
Groupboxes.Visuals_Entities:AddToggle(_L("NotifyHasteTime"),   { Text = _L("Notify Haste Time"),   Default = false, Tooltip = _L("Shows how much time you have remaining before 'Haste' spawns.") })

Globals.LibraryCodeFound = false
Toggles.NotifyLibraryCode:OnChanged(function(Value)
	if Value then
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find(_L("_")) and not Globals.LibraryCodeFound and CurrentRooms:FindFirstChild(_L("50")) then
			local Lock = Services.Workspace:FindFirstChild(_L("Padlock"), true)
			Functions.Notify({ Title = _L("Padlock code found!"), Body = _L("The code is: '") .. Code .. _L("'"), Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
			Globals.LibraryCodeFound = true
		end
	end
end)

Groupboxes.Visuals_EntitySettings:AddToggle(_L("EntityChatToggle"), { Text = _L("Notify Chat"), Default = false, Tooltip = _L("Sends a message in the chat when an entity spawns.") })
Groupboxes.Visuals_EntitySettings:AddInput(_L("EntityChatMessage"), { Text = _L("Message"), Default = _L("spawned!"), Numeric = false, Placeholder = _L("Message") })
Groupboxes.Visuals_EntitySettings:AddDivider()
Groupboxes.Visuals_EntitySettings:AddDropdown(_L("NotifyStyle"), { Text = _L("Notify Style"), Values = { _L("Abysall"), _L("Doors"), _L("STX"), _L("Library") }, Default = 1 })
Groupboxes.Visuals_EntitySettings:AddSlider(_L("NotifySoundVolume"), { Text = _L("Sound Volume"), Min = 0, Max = 10, Default = 3, Rounding = 1 })
Groupboxes.Visuals_EntitySettings:AddToggle(_L("NotifyPlaySound"), { Text = _L("Play Sound"), Default = true, Tooltip = _L("Makes notifications play an alert sound.") })
Groupboxes.Visuals_EntitySettings:AddToggle(_L("NotifyKeepNotifications"), { Text = _L("Keep Notifications"), Default = false, Tooltip = _L("Certain notifications will stay on screen until they are no longer needed.") })
Groupboxes.Visuals_EntitySettings:AddButton({ Text = _L("Test Notification"), DoubleClick = false, Tooltip = _L("Sends a test notifcation, so you can see how your settings look."), Func = function()
	Functions.Notify({Title = _L("This is a test.")})
end})

Groupboxes.Visuals_ESP          = Tabs.Visuals:AddRightTabbox(_L("ESP/Settings"))
Groupboxes.Visuals_ESP_Toggles  = Groupboxes.Visuals_ESP:AddTab(_L("ESP"))
Groupboxes.Visuals_ESP_Settings = Groupboxes.Visuals_ESP:AddTab(_L("Settings"))

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

Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("ObjectiveESPToggle"), { Text = _L("Objectives"), Default = false, Tooltip = _L("Highlights all objects required to progress.") })
Toggles.ObjectiveESPToggle:AddColorPicker(_L("ObjectiveESPColor"), { Text = _L("Objectives"), Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local ObjectiveLabels = {
	[_L("StairwellLockpickDoor")]  = _L("Garage Door"),
	[_L("Mirror")]				   = _L("Mirror"),
	[_L("ShoppingCart")]		   = _L("Shopping Cart"),
	[_L("StairwellFireAlarm")]     = _L("Fire Alarm"),
	[_L("StairwellScrapper")]	   = _L("Scrapper"),
	[_L("ArchivesPackageDeposit")] = _L("BoxDeposit"),
	[_L("Cellar")] 				   = _L("Cellar"),
	[_L("ArchivesFihTank")]        = _L("Fih Tank"),
	[_L("KeyObtain")]              = _L("Door Key"),
	[_L("ElectricalKeyObtain")]    = _L("Electrical Key"),
	[_L("MinesGenerator")]         = _L("Generator"),
	[_L("FuseObtain")]             = _L("Generator Fuse"),
	[_L("LiveHintBook")]           = _L("Hint Book"),
	[_L("LiveBreakerPolePickup")]  = _L("Fuse Breaker"),
	[_L("LibraryHintPaper")]       = _L("Hint Paper"),
	[_L("PickupItem")]             = _L("Hint Paper"),
	[_L("CringlePresent")]         = _L("Present"),
	[_L("LeverForGate")]           = _L("Gate Lever"),
	[_L("MinesGateButton")]        = _L("Gate Button"),
	[_L("GardenGateButton")]       = _L("Gate Button"),
}

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		if Value then
			local Label = ObjectiveLabels[Object.Name]
			if Object.Name == _L("TimerLever") then
				Label = _L("Time Lever [+") .. Object:GetAttribute(_L("AddTime")) .. _L("s]")
			elseif Object.Name == _L("MinesAnchor") then
				Label = _L("Anchor [") .. Object:WaitForChild(_L("Sign")).TextLabel.Text .. _L("]")
			elseif Object.Name == _L("WaterPump") then
				Functions.AddESP({ Object = Object.Wheel, Text = _L("Water Pump"), Color = Options.ObjectiveESPColor.Value }, true)
			elseif Object.Name == _L("VineGuillotine") then
				Functions.AddESP({ Object = Object.Lever, Text = _L("Vine Lever"), Color = Options.ObjectiveESPColor.Value }, true)
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

Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("DoorESPToggle"),       { Text = _L("Doors"),        Default = false, Tooltip = _L("Highlights the next door.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("HidingSpotESPToggle"), { Text = _L("Hiding Spots"), Default = false, Tooltip = _L("Highlights places where you can hide from entities") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("PlayerESPToggle"),     { Text = _L("Players"),      Default = false, Tooltip = _L("Highlights other players.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("ChestESPToggle"),      { Text = _L("Chests"),       Default = false, Tooltip = _L("Highlights objects that can contain loot.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("ItemESPToggle"),       { Text = _L("Items"),        Default = false, Tooltip = _L("Highlights all collectable items/consumables.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("CurrencyESPToggle"),   { Text = _L("Currency"),     Default = false, Tooltip = _L("Highlights all currency that spawns.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("LadderESPToggle"),     { Text = _L("Ladders"),      Default = false, Tooltip = _L("Highlights ladders that can be used to disable the anticheat.") })
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("MiscESPToggle"),       { Text = _L("Misc"),         Default = false, Tooltip = _L("Highlights miscellaneous objects that can be used to disable the anticheat.") })
Groupboxes.Visuals_ESP_Toggles:AddDivider()
Groupboxes.Visuals_ESP_Toggles:AddDropdown(_L("EntityESPOptions"),     { 
	Text = _L("Entity List"),
	Values = { _L("Rush"),_L("Bash"),_L("Scribbles"),_L("Teller"),_L("DronesStampede"),_L("Creak"),_L("Noise"),_L("Noise_TV"),_L("Balls"),_L("Portrait"),_L("Ambush"),_L("Eyes"),_L("Dupe"),_L("Figure"),_L("Blitz"),_L("Lookman"),_L("Snare"),_L("Giggle"),_L("Gloombat Eggs"),_L("Grumble"),_L("A-60"),_L("A-120"),_L("Sally"),_L("Jeff the Killer"),_L("Groundskeeper"),_L("Mandrake Hole"),_L("Monument"),_L("Bramble"),_L("AR0xMBUSH"),_L("RNIUSHCG==") },
	Multi = true,
	AllowNull = true
})
Groupboxes.Visuals_ESP_Toggles:AddToggle(_L("EntityESPToggle"),     { Text = _L("Entities"),      Default = false, Tooltip = _L("Highlights all entities that spawn.") })

Toggles.DoorESPToggle:AddColorPicker(_L("DoorESPColor"),           { Text = _L("Doors"),        Default = Color3.fromRGB(0, 200, 255),  Transparency = 0 })
Toggles.HidingSpotESPToggle:AddColorPicker(_L("HidingSpotESPColor"), { Text = _L("Hiding Spots"), Default = Color3.fromRGB(255, 170, 0),  Transparency = 0 })
Toggles.PlayerESPToggle:AddColorPicker(_L("PlayerESPColor"),       { Text = _L("Players"),      Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.ChestESPToggle:AddColorPicker(_L("ChestESPColor"),         { Text = _L("Chests"),       Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.ItemESPToggle:AddColorPicker(_L("ItemESPColor"),           { Text = _L("Items"),        Default = Color3.fromRGB(170, 0, 255),   Transparency = 0 })
Toggles.CurrencyESPToggle:AddColorPicker(_L("CurrencyESPColor"),   { Text = _L("Currency"),     Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.LadderESPToggle:AddColorPicker(_L("LadderESPColor"),       { Text = _L("Ladders"),      Default = Color3.fromRGB(3, 67, 71), Transparency = 0 })
Toggles.MiscESPToggle:AddColorPicker(_L("MiscESPColor"),           { Text = _L("Misc"),         Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.EntityESPToggle:AddColorPicker(_L("EntityESPColor"),       { Text = _L("Entities"),     Default = Color3.fromRGB(255, 0, 0),     Transparency = 0 })

local HidingSpotLabels = {
	Wardrobe = _L("Closet"), [_L("Backdoor_Wardrobe")] = _L("Closet"), Toolshed = _L("Closet"),
	RetroWardrobe = _L("Closet"), [_L("Wardrobe-FOOLS26")] = _L("Closet"),
	Locker_Large = _L("Locker"), Rooms_Locker = _L("Hiding_Spot"), Rooms_Locker_Fridge = _L("Locker"),
	Bed = _L("Bed"), Double_Bed = _L("Double Bed"), CircularVent = _L("Vent"), Dumpster = _L("Dumpster")
}
local ChestLabels = {
	ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
	Chest_Vine = _L("Vine Chest"), Toolshed_Small = _L("Toolshed"), Locker_Small_Locked = _L("Locked Item Locker"), MouseHole = _L("Mouse")
}
local EntityESPLabels = {
	JeffTheKiller = _L("Jeff the Killer"), GiggleCeiling = _L("Giggle"),
	Snare = _L("Snare"), GrumbleRig = _L("Grumble"),
	Drakobloxxer = _L("Drakobloxxer"), Hole = _L("Mandrake Hole"), Groundskeeper = _L("Groundskeeper"),
	LiveEntityBramble = _L("Bramble"), Figure = _L("Figure"), FigureRig = _L("Figure"), FigureRagdoll = _L("Figure"),
	FakeDoor = _L("Dupe"), DoorFake = _L("Dupe")
}

local NodeEntities = {
	Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true, Eyes = true, Blitz = true, Lookman = true, [_L("A-60")] = true, [_L("A-120")] = true, Sally = true, [_L("Jeff The Killer")] = true, Monument = true, [_L("AR0xMBUSH")] = true, [_L("RNIUSHCG==")] = true
}

Toggles.DoorESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Doors do
		if Value then Functions.AddESP({ Object = Object, Text = _L("Door ") .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true)
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
			if Value and Player:GetAttribute(_L("Alive")) == true then
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
			if Object.Name == _L("ChestBox") or Object.Name == _L("ChestBoxLocked") then
				Label = Object:GetAttribute(_L("Locked")) and _L("Locked Chest") or _L("Chest")
			elseif Object.Name == _L("Toolbox") or Object.Name == _L("Toolbox_Locked") then
				Label = Object:GetAttribute(_L("Locked")) and _L("Locked Toolbox") or _L("Toolbox")
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
			local Label = ItemNames[Object.Name] or (Object.Name == _L("Green_Herb") and _L("Green Herb"))
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ItemESPColor.Value }, Object:GetAttribute(_L("ParentRoom")) ~= nil)
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
			if Object.Name == _L("GoldPile") and Object:GetAttribute(_L("GoldValue")) then
				Label = _L("Gold Pile [") .. Object:GetAttribute(_L("GoldValue")) .. _L("]")
			elseif Object.Name == _L("StardustPickup") then
				Label = _L("Stardust Pile")
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
		if Value then Functions.AddESP({ Object = Object, Text = _L("Ladder"), Color = Options.LadderESPColor.Value }, true)
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
			if Object.Name == _L("StairwellLockpickDoor") or Object.Name == _L("StiarwellLockpickDoor") then
				Label = _L("Garage Door")
			elseif Object.Name == _L("StairwellFireAlarm") then
				Label = _L("Fire Alarm")
			elseif Object.Name == _L("ShoppingCart") then
				Label = _L("Shopping Cart")
			elseif Object.Name == _L("ArchivesFihTank") or Object.Name == _L("ArchivesFishTank") then
				Label = _L("Fish Tank")
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

Groupboxes.Visuals_ESP_Settings:AddToggle(_L("ESPRainbow"),     { Text = _L("Rainbow Effect"), Default = false, Tooltip = _L("Makes the esp objects change colour like a rainbow.") })
Groupboxes.Visuals_ESP_Settings:AddToggle(_L("ESPShowDistance"),{ Text = _L("Show Distance"),  Default = true,  Tooltip = _L("Shows how far away your character is from the object.") })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPFillTransparency"),        { Text = _L("Fill Transparency"),         Min = 0, Max = 1, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPOutlineTransparency"),     { Text = _L("Outline Transparency"),      Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPTextTransparency"),        { Text = _L("Text Transparency"),         Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPTextOutlineTransparency"), { Text = _L("Text Outline Transparency"), Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPFadeTime"),                { Text = _L("Fade Time"),                 Min = 0, Max = 1, Default = 0.25, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPRenderLimit"),             { Text = _L("Render Limit"),              Min = 30, Max = 240, Default = 240, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPTextSize"),                { Text = _L("Text Size"),                 Min = 12, Max = 24, Default = 20, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddDropdown(_L("ESPTextFont"), {
	Text = _L("Text Font"),
	Values = { _L("Legacy"),_L("Arial"),_L("ArialBold"),_L("SourceSans"),_L("SourceSansBold"),_L("SourceSansLight"),_L("SourceSansItalic"),_L("Bodoni"),_L("Garamond"),_L("Cartoon"),_L("Code"),_L("Highway"),_L("SciFi"),_L("Arcade"),_L("Fantasy"),_L("Antique"),_L("SourceSansSemibold"),_L("Gotham"),_L("GothamMedium"),_L("GothamBold"),_L("GothamBlack"),_L("AmaticSC"),_L("Bangers"),_L("Creepster"),_L("DenkOne"),_L("Fondamento"),_L("FredokaOne"),_L("GrenzeGotisch"),_L("IndieFlower"),_L("JosefinSans"),_L("Jura"),_L("Kalam"),_L("LuckiestGuy"),_L("Merriweather"),_L("Michroma"),_L("Nunito"),_L("Oswald"),_L("PatrickHand"),_L("PermanentMarker"),_L("Roboto"),_L("RobotoCondensed"),_L("RobotoMono"),_L("Sarpanch"),_L("SpecialElite"),_L("TitilliumWeb"),_L("Ubuntu"),_L("BuilderSans"),_L("BuilderSansMedium"),_L("BuilderSansBold"),_L("BuilderSansExtraBold"),_L("Arimo"),_L("ArimoBold") },
	Default = 12
})
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddDropdown(_L("ESPTracersOrigin"),  { Text = _L("Tracer Origin"), Values = { _L("Bottom"),_L("Center"),_L("Top"),_L("Mouse") }, Default = 1 })
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPTracerThickness"),  { Text = _L("Tracer Thickness"), Min = 0.5, Max = 2, Default = 0.75, Rounding = 2, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle(_L("ESPTracersToggle"),    { Text = _L("Enable Tracers"), Default = false, Tooltip = _L("Draws a line to highlighted objects.") })
Groupboxes.Visuals_ESP_Settings:AddDivider()
Groupboxes.Visuals_ESP_Settings:AddSlider(_L("ESPArrowsRadius"),     { Text = _L("Arrow Radius"), Min = 100, Max = 500, Default = 250, Rounding = 0, Compact = true })
Groupboxes.Visuals_ESP_Settings:AddToggle(_L("ESPArrowsToggle"),     { Text = _L("Enable Arrows"), Default = false, Tooltip = _L("Shows arrow that point to off-screen objects.") })

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
Abysall.ESPLibrary:SetTracerOrigin(_L("Bottom"))
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
	Title = _L("Compatability/Risk Warning"),
	Text = _L("Features highlighted in red are risky / dont work in the current floor."),
})
Groupboxes.Floors_Automation = Tabs.Floors:AddRightGroupbox(_L("Automation"))

Groupboxes.Floors_Automation:AddToggle(_L("SkipSeekMines"), {
	Text = _L("Skip Seek (Mines)"),
	Default = false,
	Tooltip = _L("Skips the entire Seek sections."),
	Risky = Floor ~= _L("Mines")
})

Toggles.SkipSeekMines:OnChanged(function(Value)
	if Value then
		if Floor ~= _L("Mines") then
			return
		end
		task.spawn(function()
			local MinesSkipSeekCurrentRooms

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))
				task.wait()
			until MinesSkipSeekCurrentRooms

			local MinesSkipSeekStartRoom

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))

				if MinesSkipSeekCurrentRooms then
					MinesSkipSeekStartRoom = MinesSkipSeekCurrentRooms:FindFirstChild(_L("42"))
				end

				task.wait()
			until MinesSkipSeekStartRoom

			local MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				MinesSkipSeekStartDoor = MinesSkipSeekStartRoom:FindFirstChild(_L("Door"), true)
				task.wait()
			until MinesSkipSeekStartDoor

			repeat
				if not Toggles.SkipSeekMines.Value then
					return
				end

				task.wait()
			until MinesSkipSeekStartDoor:GetAttribute(_L("Opened")) == true

			if Character and Character:GetAttribute(_L("Minecarting")) == true then
				Character:SetAttribute(_L("Minecarting"), false)
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

					MinesSkipSeekCurrentRooms = workspace:FindFirstChild(_L("CurrentRooms"))

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

					MinesSkipSeekDoor = MinesSkipSeekRoom:FindFirstChild(_L("Door"), true)
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
				until MinesSkipSeekDoor:GetAttribute(_L("Opened")) == true

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

Groupboxes.Floors_Automation:AddToggle(_L("AutoSteerMinecart"), {
	Text = _L("Auto Steer Minecart"), Default = false, Tooltip = _L("Automatically completes the minecart chase."),
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider(_L("AutoSteerMinecartTurnDistance"), {
	Text = _L("Turn Distance"), Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddSlider(_L("AutoSteerMinecartDuckDistance"), {
	Text = _L("Crouch Distance"), Min = 20, Max = 40, Default = 30, Rounding = 0,
	Disabled = not Functions.CheckCompatability({_L("require")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Automation:AddDivider()
Groupboxes.Floors_Automation:AddToggle(_L("RoomsAutoWalk"),             { Text = _L("Auto Rooms"),       Default = false, Tooltip = _L("Automatically moves and hides from entities in The Rooms.") })
Groupboxes.Floors_Automation:AddSlider(_L("RoomsAutoWalkPathfindTimeout"), { Text = _L("Pathfind Timeout"), Min = 0.5, Max = 3, Default = 1, Rounding = 1 })
Groupboxes.Floors_Automation:AddToggle(_L("RoomsAutoWalkIgnoreA60"),    { Text = _L("Ignore A-60"),      Default = false, Tooltip = _L("Continues to walk if entity 'A-60' is present, enables position spoof automatically.") })
Groupboxes.Floors_Automation:AddToggle(_L("RoomsAutoWalkShowPathToggle"), { Text = _L("Show Path"),       Default = false, Tooltip = _L("Shows the current path of rooms auto-walk.") })
Groupboxes.Floors_Automation:AddToggle(_L("RoomsAutoWalkSpoofFootsteps"), {
    Text = _L("Spoof Footsteps"), Default = false, Tooltip = _L("Makes it appear as if your character is walking normally."),
    Disabled = not Functions.CheckCompatability({_L("hookmetamethod"), _L("newcclosure"), _L("getnamecallmethod")}), DisabledTooltip = Globals.IncompatibleMessage
})

Toggles.RoomsAutoWalk:OnChanged(function()
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == _L("PathNode") then Object:Destroy() end
	end
end)
Toggles.RoomsAutoWalkShowPathToggle:AddColorPicker(_L("RoomsAutoWalkShowPathColor"), { Text = _L("Path"), Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.RoomsAutoWalkShowPathToggle:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == _L("PathNode") then Object.Transparency = Value and 0.5 or 1 end
	end
end)
Options.RoomsAutoWalkShowPathColor:OnChanged(function(Value)
	for _, Object in Globals.RoomsNodesFolder:GetChildren() do
		if Object.Name == _L("PathNode") then Object.Color = Value end
	end
end)

Functions.RoomsAutoWalk = {}
Functions.RoomsAutoWalk.GetNearestHidingSpot = function()
	local Nearest = { Distance = math.huge, Object = nil }
	for _, Object in Objects.HidingSpots do
		if Object.PrimaryPart and Object:FindFirstChild(_L("HidePrompt")) then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Object.PrimaryPart.Position.Y > -10 then
				local HiddenPlayer = Object:FindFirstChild(_L("HiddenPlayer"), true)
				if HiddenPlayer and not HiddenPlayer.Value then
					Nearest.Distance = Distance
					Nearest.Object = Object
				end
			end
		end
	end
	return Nearest.Object
end

local RoomsEntityList = { _L("RushMoving"),_L("AmbushMoving"),_L("BackdoorRush"),_L("A60"),_L("A120"),_L("CustomEntity"),_L("GlitchRush"),_L("GlitchAmbush") }
Functions.RoomsAutoWalk.GetPathfindTarget = function()
	for _, Object in Services.Workspace:GetChildren() do
		if table.find(RoomsEntityList, Object.Name) and Object.PrimaryPart then
			local Y = Object.PrimaryPart.Position.Y
			if Y > -10 and Y < 150 then
				if Object.Name == _L("A60") and not Toggles.RoomsAutoWalkIgnoreA60.Value or Object.Name ~= _L("A60") then
					return Functions.RoomsAutoWalk.GetNearestHidingSpot() or CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild(_L("RoomExit"))
				end
			end
		end
	end
	return CurrentRooms[tostring(LatestRoom.Value)]:FindFirstChild(_L("RoomExit"))
end

Connections.RoomsAutoWalkHandler = Services.RunService.Heartbeat:Connect(function()
	if Floor ~= _L("Rooms") or not Toggles.RoomsAutoWalk.Value or Globals.RoomsAutoWalkActive or not CollisionPart or LatestRoom.Value >= 1000 then return end
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
	if TargetPart.Name == _L("RoomExit") then
		TargetPosition = TargetPart.Position
	elseif TargetPart:FindFirstChild(_L("HidePrompt")) then
		for _, Part in TargetPart:GetDescendants() do
			if Part:IsA(_L("BasePart")) then Part.CanCollide = false end
		end
		TargetPosition = TargetPart.PrimaryPart.Position
	end

	if CollisionPart.Anchored and not TargetPart:FindFirstChild(_L("HidePrompt")) then
		Character:SetAttribute(_L("Hiding"), true)
		RemotesFolder.CamLock:FireServer()
		Character:SetAttribute(_L("Hiding"), false)
	end

	local CurrentRoom = CurrentRooms[tostring(LatestRoom.Value)]
	if CurrentRoom:FindFirstChild(_L("Door")) then
		CurrentRoom.Door.Door.CanCollide = false
	end

	if not TargetPosition or LocalPlayer:DistanceFromCharacter(TargetPosition) >= 750 then
		Globals.RoomsAutoWalkActive = false
		return
	end

	Path:ComputeAsync(CollisionPart.Position, TargetPosition)
	local Waypoints = Path:GetWaypoints()

	if #Waypoints == 0 then
		local RoomExit = CurrentRoom:FindFirstChild(_L("RoomExit"))
		if RoomExit then Humanoid:MoveTo(RoomExit.Position) end
		Globals.RoomsAutoWalkActive = false
		return
	end

	for _, Node in Globals.RoomsNodesFolder:GetChildren() do
		if Node.Name == _L("PathNode") then Node:Destroy() end
	end

	for _, Waypoint in Waypoints do
		local Block = Instance.new(_L("Part"), Globals.RoomsNodesFolder)
		Block.Transparency = Toggles.RoomsAutoWalkShowPathToggle.Value and 0.5 or 1
		Block.Size = Vector3.one
		Block.Position = Waypoint.Position
		Block.Shape = Enum.PartType.Ball
		Block.CanCollide = false
		Block.Anchored = true
		Block.Name = _L("PathNode")
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
			if NewTarget and NewTarget:FindFirstChild(_L("HidePrompt")) and not TargetPart:FindFirstChild(_L("HidePrompt")) then
				Finished = true return
			end
			if TargetPart:FindFirstChild(_L("HidePrompt")) then
				local HidePrompt = TargetPart:FindFirstChild(_L("HidePrompt"))
				if LocalPlayer:DistanceFromCharacter(TargetPosition) < HidePrompt.MaxActivationDistance
					and Character:GetAttribute(_L("Hiding")) ~= true
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
				local StuckBlock = Instance.new(_L("Part"), Globals.RoomsNodesFolder)
				StuckBlock.Transparency = 1
				StuckBlock.Size = Vector3.one
				StuckBlock.CFrame = Collision.CFrame
				StuckBlock.Shape = Enum.PartType.Ball
				StuckBlock.CanCollide = false
				StuckBlock.Anchored = true
				StuckBlock.Name = _L("StuckPart")
				local Modifier = Instance.new(_L("PathfindingModifier"), StuckBlock)
				Modifier.Label = _L("StuckPart")
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
		if Object.Name == _L("StuckPart") then Object:Destroy() end
	end

	if Room:GetAttribute(_L("RawName")) and string.find(Room:GetAttribute(_L("RawName")), _L("Eyestalk")) then
        local PreviousNode = nil

		local function CreateEyestalkNode(WaypointPos)
			local NewNode = Instance.new(_L("Part"))
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.Position = WaypointPos
			NewNode.CanCollide = false
			NewNode.Name = _L("SeekLightNode")

			local PrevNode = PreviousNode or NewNode
			PreviousNode = NewNode

			local NewBeam = Instance.new(_L("Beam"))
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

			local A0 = Instance.new(_L("Attachment"), NewNode)
			local A1 = Instance.new(_L("Attachment"), PrevNode)
			NewBeam.Attachment0 = A0
			NewBeam.Attachment1 = A1

			table.insert(Objects.EyestalkHighlights, NewBeam)
		end

		Room:WaitForChild(_L("RoomEntrance"), 9e9)
		Room:WaitForChild(_L("RoomExit"), 9e9)

		while not Room:GetAttribute(_L("PathFound")) do
			if Toggles.ShowEyestalkPathToggle.Value then
				local EyePath = game:GetService(_L("PathfindingService")):CreatePath({
					AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2, AgentRadius = 1, AgentHeight = 1
				})
				EyePath:ComputeAsync(RootPart.Position, Room.RoomExit.Position)
				if EyePath.Status == Enum.PathStatus.Success then
					Room:SetAttribute(_L("PathFound"), true)
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

Groupboxes.Floors_Completion = Tabs.Floors:AddRightGroupbox(_L("Completion"))
Groupboxes.Floors_Completion:AddButton({
    Text = _L("Auto Complete Dam Seek"),
    Tooltip = _L("Automatically teleports to and interacts with each water pump."),
    Func = function()
        if LatestRoom.Value < 100 or Floor ~= _L("Mines") then
            Functions.Notify({Title = _L("You must be in Room 200 to do this.")})
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
                if Object.Name == _L("WaterPump") and Object:GetAttribute(_L("Abysall_Completed")) ~= true then
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

                local Prompt = Pump:FindFirstChild(_L("ValvePrompt"), true)
                if Prompt then
                    Functions.ForceFirePrompt(Prompt)
                end

                if Pump:GetAttribute(_L("Abysall_Completed")) then
                    break
                end
            end
        end

        Functions.Notify({Title = _L("Attempting to complete the valves."), Body = _L("Please wait.")})
        while task.wait(0.1) do
            local Pump = GetNextPump()
            if Pump then
                HandlePump(Pump)
            else
                break
            end
        end
        Functions.Notify({Title = _L("Successfully completed the valves.")})
    end
})

Groupboxes.Floors_Completion:AddButton({
    Text = _L("Auto Complete Cringle"),
    Tooltip = _L("Instantly completes the quest."),
    Func = function()
        local TouchPart = CurrentRooms:FindFirstChild(_L("RippleExitDoor"), true)
        if TouchPart then
            Character:PivotTo(TouchPart:GetPivot())
        end
    end
})

Groupboxes.Floors_Visuals = Tabs.Floors:AddLeftGroupbox(_L("Visuals"))
Groupboxes.Floors_Visuals:AddToggle(_L("ShowSeekPathToggle"), {
	Text = _L("Show Seek Path"), Default = false, Tooltip = _L("Shows you the correct path in seek chases."),
	Risky = Floor ~= _L("Mines")
})
Toggles.ShowSeekPathToggle:AddColorPicker(_L("ShowSeekPathColor"), { Text = _L("Seek Path"), Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

local function UpdateBeamVisibility(BeamTable, ColorKey, Visible)
	local Vis = Visible and 0 or 1
	local Seq = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
	for _, Beam in BeamTable do Beam.Transparency = Seq end
end
local function UpdateBeamColor(BeamTable, Value)
	local Seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Value) })
	for _, Beam in BeamTable do Beam.Color = Seq end
end

Toggles.ShowSeekPathToggle:OnChanged(function(V)  UpdateBeamVisibility(Objects.SeekHighlights, _L("ShowSeekPathColor"), V) end)
Options.ShowSeekPathColor:OnChanged(function(V)   UpdateBeamColor(Objects.SeekHighlights, V) end)

Groupboxes.Floors_Visuals:AddToggle(_L("ShowEyestalkPathToggle"), {
	Text = _L("Show Eyestalk Path"), Default = false, Tooltip = _L("Shows you the correct path in the eyestalk chase."),
	Risky = Floor ~= _L("Garden")
})
Toggles.ShowEyestalkPathToggle:AddColorPicker(_L("ShowEyestalkPathColor"), { Text = _L("Eyestalk Path"), Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.ShowEyestalkPathToggle:OnChanged(function(V) UpdateBeamVisibility(Objects.EyestalkHighlights, _L("ShowEyestalkPathColor"), V) end)
Options.ShowEyestalkPathColor:OnChanged(function(V)  UpdateBeamColor(Objects.EyestalkHighlights, V) end)

Groupboxes.Floors_Bypass = Tabs.Floors:AddLeftGroupbox(_L("Bypass"))
Groupboxes.Floors_Bypass:AddToggle(_L("RemoveSeekTrigger"), {
	Text = _L("Delete Seek Trigger"), Default = false, Tooltip = _L("Diables the 'Seek' chase trigger."),
	Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel")),
	Disabled = not Functions.CheckCompatability({_L("firetouchinterest")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle(_L("RemoveFigure"), {
	Text = _L("Delete Figure"), Default = false, Tooltip = _L("Completely removes the entity 'Figure' (doesn't always work)."),
	Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel") or Floor == _L("Mines")),
	Disabled = not Functions.CheckCompatability({_L("isnetworkowner")}), DisabledTooltip = Globals.IncompatibleMessage
})
Groupboxes.Floors_Bypass:AddToggle(_L("AutoRevive"), {
	Text = _L("Infinite Revives"), Default = false, Tooltip = _L("Automatically revives after dying, with unlimited respawns."),
	Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel"))
})
Groupboxes.Floors_Bypass:AddToggle(_L("FigureGodmode"), {
	Text = _L("Figure Godmode"), Default = false, Tooltip = _L("Prevents 'Figure' from hurting you."),
	Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel"))
})
Groupboxes.Floors_Bypass:AddDivider()
Groupboxes.Floors_Bypass:AddToggle(_L("RemoveBasementGate"),  { Text = _L("Remove Basement Gate"),   Default = false, Tooltip = _L("Removes the gate from basement rooms."),            Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel")) })
Groupboxes.Floors_Bypass:AddToggle(_L("RemovePaintingsDoor"), { Text = _L("Remove Paintings Door"),  Default = false, Tooltip = _L("Removes the fireplace doors from painting rooms."), Risky = not (Floor == _L("Fools") or Floor == _L("OldHotel")) })
Groupboxes.Floors_Bypass:AddToggle(_L("RemoveSkeletonDoor"),  { Text = _L("Remove Skeleton Door"),   Default = false, Tooltip = _L("Removes the skeleton door from the infirmary."),    Risky = Floor ~= _L("Fools") })

local ObstructionNames = { ThingToOpen = _L("RemoveBasementGate"), MovingDoor = _L("RemovePaintingsDoor"), Wax_Door = _L("RemoveSkeletonDoor") }
for ObjName, ToggleName in ObstructionNames do
	Toggles[ToggleName]:OnChanged(function(Value)
		for _, Object in Objects.Obstructions do
			if Object.Name == ObjName then
				Object:PivotTo(Value and CFrame.new(-10000, -10000, -10000) or Object:GetAttribute(_L("OriginalPosition")))
			end
		end
	end)
end

Groupboxes.Floors_Farming = Tabs.Floors:AddLeftGroupbox(_L("Farming"))
Groupboxes.Floors_Farming:AddToggle(_L("KnobFarm"), {
    Text = _L("Knob Farm"),
    Default = false,
    Tooltip = _L("Automatically gains knobs for you, dies and revives repeatedly."),
	Risky = Floor ~= _L("Ballz"),
})

Groupboxes.Floors_Farming:AddButton({
    Text = _L("Start Knob Farm"),
    Tooltip = _L("Starts farming knobs, click this when you have enough gold."),
    Func = function()
		if LatestRoom.Value ~= 0 then
			Functions.Notify({Title = _L("You must be in Room 0 to use this.")})
			return
		end

		if LocalPlayer.PlayerGui:FindFirstChild(_L("TopbarUI")) then 
			local GoldCount = LocalPlayer.PlayerGui.TopbarUI.Topbar.StatsTopbarHandler.StatModules.Gold.GoldVal
			if GoldCount.Value <= 0 then
				Functions.Notify({Title = _L("You must have gold to do this.")})
				return
			end
		end

        Globals.KnobFarmStarted = true
    end
})

Groupboxes.Floors_Farming:AddDivider()
Groupboxes.Floors_Farming:AddButton({
	Text = _L("Start Death Farm"),
	DoubleClick = true,
	Tooltip = _L("Automatically farms deaths, joining new runs."),
	Func = function()
		loadstring(game:HttpGet(_L("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau")))()
	end,

	Disabled = not Functions.CheckCompatability({_L("fireproximityprompt"), _L("firesignal")}),
	DisabledTooltip = Globals.ImcompatibleMessage
})
Groupboxes.Floors_Farming:AddButton({
	Text = _L("Copy Death Farm Loadstring"),
	DoubleClick = false,
	Tooltip = _L("Copies the death farm loadstring to your clipboard."),
	Func = function()
		toclipboard([==[
			loadstring(game:HttpGet(_L("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Scripts/DeathFarm.luau")))()
		]==])
		Library:Notify(_L("Loadstring has been copied to your clipboard."))
	end,

	Disabled = not Functions.CheckCompatability({_L("fireproximityprompt"), _L("firesignal")}),
	DisabledTooltip = Globals.ImcompatibleMessage
})

Toggles.KnobFarm:OnChanged(function(Value)
    if Value then
        Functions.Notify({Title = _L("Please collect some gold to earn knobs."), Body = _L("Click 'Start Knob Farm' when you're ready.")})
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
			if Functions.CheckCompatability({_L("replicatesignal")}) then
				Abysall.Environment.replicatesignal(LocalPlayer.Kill)
			else
				LocalPlayer.Character.Humanoid.Health = 0
			end
			while task.wait() do
				if LocalPlayer:GetAttribute(_L("Alive")) then
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
if Functions.CheckCompatability({_L("hookmetamethod"), _L("newcclosure"), _L("getnamecallmethod")}) then
	MainHook = Abysall.Environment.hookmetamethod(game, _L("__namecall"), Abysall.Environment.newcclosure(function(Self, ...)
		local Args = { ... }
		if Abysall and Abysall.Environment then
			local Method = Abysall.Environment.getnamecallmethod()

			if Self.Name == _L("Crouch") and Method == _L("FireServer") then
				if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then
					Args[1] = true
				end
				Args[2] = true
			end

			if Self.Name == _L("ClutchHeartbeat") and Method == _L("FireServer") and Toggles.AutoHeartbeatMinigame.Value or Self.Name == _L("HideMonster") and Method == _L("FireServer") and Toggles.AutoHeartbeatMinigame.Value then
				return
			end

			if Self.Name == _L("MotorReplication") and Method == _L("FireServer") then
				local DoBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
				if DoBypass then
					if Floor == _L("Fools") or Floor == _L("OldHotel") then
						Args[1] = 0 Args[2] = (Globals.SpoofOffset == 200 and 65 or -65) Args[3] = 0 Args[4] = false
					else
						Args[1] = -650
					end
				end
			end
		end
		return MainHook(Self, table.unpack(Args))
	end))

    OtherHook = Abysall.Environment.hookmetamethod(game, _L("__index"), Abysall.Environment.newcclosure(function(Self, Property)
        local Real = OtherHook(Self, Property)

        if Property == _L("MoveDirection") and Self == Humanoid and Globals.RoomsAutoWalkActive and Toggles.RoomsAutoWalkSpoofFootsteps.Value and Floor == _L("Rooms") and not Character:GetAttribute(_L("Hiding")) then
            return RootPart.CFrame.LookVector
        end
        
        return Real
    end))
end

if Services.ReplicatedStorage:FindFirstChild(_L("ModulesClient")) then
	ClientModules = Services.ReplicatedStorage.ModulesClient
else
	ClientModules = Services.ReplicatedStorage.ClientModules
end

Modules = {
	Glitch         = ClientModules.EntityModules.Glitch,
	Shade          = ClientModules.EntityModules.Shade,
	Void           = ClientModules.EntityModules:FindFirstChild(_L("Void")),
	SpiderJumpscare = nil,
	A90            = nil,
	Screech        = nil,
	Dread          = nil,
	GlitchScreech  = nil,
}

local CharacterOldConnectionKeys = {
	_L("MainHandler"), _L("JumpHandler"), _L("SlideHandler"), _L("LibraryCodeHandler1"), _L("LibraryCodeHandler2"),
	_L("OxygenConnection"), _L("AnimationHandler"), _L("AutoHideConnection"), _L("AutoReviveHandler"),
	_L("SHMFixer"), _L("AnticheatDisabler"), _L("AnticheatEnableDetector1"), _L("AnticheatEnableDetector2"),
	_L("AutoSteerMinecartDuckHandler"), _L("AutoSolveAnchorsConnection"), _L("InfiniteJumpsConnection1"), _L("InfiniteJumpsConnection2"),
	_L("FootstepHandler")
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

	while not LocalPlayer.PlayerGui:FindFirstChild(_L("MainUI")) do
		task.wait()
	end

	Character = NewCharacter
	Humanoid = NewCharacter:WaitForChild(_L("Humanoid"), 9e9)
	RootPart = NewCharacter:FindFirstChild(_L("HumanoidRootPart"))
	Camera   = Services.Workspace.CurrentCamera

	Globals.OldCamera = Camera
	Globals.MainUI = LocalPlayer.PlayerGui.MainUI

	Collision = NewCharacter:WaitForChild(_L("Collision"))
	CollisionPart  = NewCharacter:FindFirstChild(_L("CollisionPart")) or NewCharacter:FindFirstChild(_L("Collision"))
	CollisionClone = Collision:Clone()
	CollisionClone.Parent = NewCharacter
	CollisionClone.Name = _L("CollisionClone")
	CollisionClone.Massless = true

	CollisionPartClone = CollisionPart:Clone()
	CollisionPartClone.Parent = NewCharacter
	CollisionPartClone.Name = _L("CollisionPartClone")
	CollisionPartClone.CanCollide = false
	CollisionPartClone.Massless = true

	if CollisionPartClone:FindFirstChild(_L("CollisionCrouch")) then
		CollisionPartClone.CollisionCrouch:Destroy()
	end

	Character:SetAttribute(_L("SpeedBoost"), 0)
	Character:SetAttribute(_L("SpeedBoostBehind"), 0)
	Character:SetAttribute(_L("SpeedBoostExtra"), 0)

	OldJump  = NewCharacter:GetAttribute(_L("CanJump"))
	OldSlide = NewCharacter:GetAttribute(_L("CanSlide"))

	if Toggles.EnableCharacterJump.Value  then Character:SetAttribute(_L("CanJump"),  true) end
	if Toggles.EnableCharacterSlide.Value then Character:SetAttribute(_L("CanSlide"), true) end

	if Functions.CheckCompatability({_L("require")}) then
		Main_Game = Abysall.Environment.require(Globals.MainUI.Initiator.Main_Game)
	end

	if Main_Game and Toggles.RemoveCameraBobbing.Value then
		Main_Game.spring.Speed = 9e9
	end

	if Main_Game and Functions.CheckCompatability({_L("require")}) then
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		local OriginalGetMoveVector = Controls.GetMoveVector
		Globals.OriginalGetMoveVector = OriginalGetMoveVector
		Controls.GetMoveVector = function(...)
			if Toggles.AutoSteerMinecart.Value and Floor == _L("Mines") then
				local Node = Globals.NearestTurnNode
				if Node and Functions.GetMinecart() then
					local Turn = Node:GetAttribute(_L("Turn"))
					return Turn == _L("Left") and Vector3.new(-1, 0, 0) or Turn == _L("Right") and Vector3.new(1, 0, 0) or Vector3.zero
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
	Modules.A90             = UIModules:FindFirstChild(_L("A90"))
	Modules.Screech         = UIModules.Screech
	Modules.Dread           = UIModules:FindFirstChild(_L("Dread"))
	Modules.SpiderJumpscare = UIModules.SpiderJumpscare

	if Toggles.RemoveScreech.Value    then Modules.Screech.Name = _L("Screech_Disabled") print (_L("screech gone")) end
	if Toggles.RemoveA90.Value and Modules.A90   then Modules.A90.Name = _L("A90_Disabled") end
	if Toggles.RemoveDread.Value and Modules.Dread then Modules.Dread.Name = _L("Dread_Disabled") end
	if Toggles.DisableTimothyJumpscare.Value then Modules.SpiderJumpscare.Name = _L("SpiderJumpscare_Disabled") end

	if Toggles.DisableHideVignette.Value then
		local Vignette = Globals.MainUI:FindFirstChild(_L("HideVignette")) or Globals.MainUI.MainFrame:FindFirstChild(_L("HideVignette"))
		if Vignette then Vignette.Image = _L("Disabled") end
	end
	if Toggles.RemoveInteractingSounds.Value then
		local PS = Globals.MainUI.Initiator.Main_Game.PromptService
		PS.Triggered.Volume = 0
		PS.Holding.Volume   = 0
		PS.Notification.Volume = 0
		Globals.MainUI.Initiator.Main_Game.Reminder.Caption.Volume = 0
	end
	if Toggles.DisableEntityJumpscares.Value then
		local JS = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild(_L("Jumpscares"))
		if JS then JS.Name = _L("Jumpscares_Disabled") end
	end
    local Cutscenes = Globals.MainUI.Initiator.Main_Game.RemoteListener.Cutscenes
    for _, Object in pairs(Cutscenes:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA(_L("ModuleScript")) then
            Object:SetAttribute(_L("OriginalName"), Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. _L("_Disabled")
            end
        end
    end
    for _, Object in pairs(FloorReplicated:GetChildren()) do
        if table.find(CutsceneNames, Object.Name) and Object:IsA(_L("ModuleScript")) then
            Object:SetAttribute(_L("OriginalName"), Object.Name)
            if Toggles.RemoveCutscenes.Value then
                Object.Name = Object.Name .. _L("_Disabled")
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
		if Part:IsA(_L("BasePart")) then
			PartProperties[Part] = Part.CustomPhysicalProperties
			if Toggles.RemoveAcceleration.Value then
				Part.CustomPhysicalProperties = CustomPhysics
			end
		end
	end

	Connections.LibraryCodeHandler1 = LocalPlayer.PlayerGui.PermUI.Hints.ChildAdded:Connect(function()
		if Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find(_L("_")) and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild(_L("Padlock"), true)
				Functions.Notify({ Title = _L("Padlock code found!"), Body = _L("The code is: '") .. Code .. _L("'"), Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.LibraryCodeHandler2 = Character.ChildAdded:Connect(function(Child)
		if (Child.Name == _L("LibraryHintPaper") or Child.Name == _L("LibraryHintPaperHard")) and Toggles.NotifyLibraryCode.Value then
			local Code = Functions.GetLibraryCode()
			if Code and not Code:find(_L("_")) and not Globals.LibraryCodeFound then
				local Lock = Services.Workspace:FindFirstChild(_L("Padlock"), true)
				Functions.Notify({ Title = _L("Padlock code found!"), Body = _L("The code is: '") .. Code .. _L("'"), Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
				Globals.LibraryCodeFound = true
			end
		end
	end)

	Connections.FootstepHandler = Character.ChildAdded:Connect(function(Object)
		if Object:IsA(_L("Sound")) and Object.Name == _L("Sound") and Toggles.RemoveFootstepSounds.Value then
			Object.Volume = 0
		end
	end)

	Globals.OldOxygen = Character:GetAttribute(_L("Oxygen"))
	Connections.OxygenConnection = Character:GetAttributeChangedSignal(_L("Oxygen")):Connect(function()
		local NewOxy = Character:GetAttribute(_L("Oxygen"))
		if NewOxy < Globals.OldOxygen and Toggles.NotifyOxygen.Value then
			Functions.Caption(Functions.FormatOxygen(NewOxy), true)
		end
		Globals.OldOxygen = NewOxy
	end)

	Connections.AutoReviveHandler = LocalPlayer:GetAttributeChangedSignal(_L("Alive")):Connect(function()
		if LocalPlayer:GetAttribute(_L("Alive")) == false and Toggles.AutoRevive.Value then
			if Floor == _L("Fools") or Floor == _L("OldHotel") then
				while LocalPlayer:GetAttribute(_L("Alive")) ~= true do
					RemotesFolder.Revive:FireServer()
					task.wait(0.5)
				end
			end
		end
	end)

	Connections.SHMFixer = RootPart:GetPropertyChangedSignal(_L("Anchored")):Connect(function()
		task.wait()
		if Floor == _L("Fools") and RootPart.Anchored and Character:GetAttribute(_L("Hiding")) ~= true then
			RootPart.Anchored = false
		end
	end)

	Connections.AnticheatDisabler = Character:GetAttributeChangedSignal(_L("Climbing")):Connect(function()
		if Character:GetAttribute(_L("Climbing")) == true and Toggles.DisableAnticheat.Value and not Globals.AnticheatDisabled then
			task.wait(0.25)
			Character:SetAttribute(_L("Climbing"), false)
			Functions.Notify({ Title = _L("Successfully disabled the anticheat."), Body = _L("It will be re-enabled after a cutscene or halt room.") })
			Globals.AnticheatDisabled = true
		end
	end)

	Connections.AnticheatEnableDetector1 = RemotesFolder:WaitForChild(_L("Cutscene")).OnClientEvent:Connect(function(CutsceneName)
		if Globals.AnticheatDisabled and not CutsceneName:find(_L("SewerSeek")) then
			Globals.AnticheatDisabled = false
			Functions.Notify({ Title = _L("The anticheat has been re-enabled."), Body = _L("Interact with a ladder to disable it again.") })
		end
	end)

	Connections.AnticheatEnableDetector2 = RemotesFolder:WaitForChild(_L("UseEnemyModule")).OnClientEvent:Connect(function(ModuleName)
		if ModuleName == _L("Void") or ModuleName == _L("Glitch") then
			if Globals.AnticheatDisabled then
				Globals.AnticheatDisabled = false
				Functions.Notify({ Title = _L("The anticheat has been re-enabled."), Body = _L("Interact with a ladder to disable it again.") })
			end
			LocalPlayer:SetAttribute(_L("CurrentRoom"), LatestRoom.Value)
		end
	end)

	Connections.AnimationHandler = Character.ChildAdded:Connect(function()
		local ToolNames = { _L("Lockpick"),_L("Shears"),_L("SkeletonKey"),_L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyBackdoor"),_L("KeyIron"), _L("Multitool") }
		local Tool
		for _, Name in ToolNames do
			Tool = Character:FindFirstChild(Name)
			if Tool then break end
		end
		if not Tool then return end

		local UseAnim = Tool:FindFirstChild(_L("use"), true) or Tool:FindFirstChild(_L("promptanim"), true)
		if UseAnim then
			UseAnim = Humanoid:LoadAnimation(UseAnim)
			UseAnim.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimation = UseAnim
		end
		local UseAnimBreak = Tool:FindFirstChild(_L("usefinish"), true) or Tool:FindFirstChild(_L("promptanimend"), true) or Tool:FindFirstChild(_L("lockpickuse"), true)
		if UseAnimBreak then
			UseAnimBreak = Humanoid:LoadAnimation(UseAnimBreak)
			UseAnimBreak.Priority = Enum.AnimationPriority.Action4
			Globals.UseAnimationBreak = UseAnimBreak
		end
	end)

	Connections.JumpHandler = Character:GetAttributeChangedSignal(_L("CanJump")):Connect(function()
		local Val = Character:GetAttribute(_L("CanJump"))
		if Toggles.EnableCharacterJump.Value and Val ~= true or not Toggles.EnableCharacterJump.Value then
			OldJump = Val
		end
		if Toggles.EnableCharacterJump.Value then Character:SetAttribute(_L("CanJump"), true) end
	end)

	Connections.SlideHandler = Character:GetAttributeChangedSignal(_L("CanSlide")):Connect(function()
		local Val = Character:GetAttribute(_L("CanSlide"))
		if Toggles.EnableCharacterSlide.Value and Val ~= true or not Toggles.EnableCharacterSlide.Value then
			OldSlide = Val
		end
		if Toggles.EnableCharacterSlide.Value then Character:SetAttribute(_L("CanSlide"), true) end
	end)

	Connections.InfiniteJumpsConnection1 = Services.UserInputService.InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Space and Toggles.InfiniteJumps.Value and not Globals.IsTyping then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	local JumpButton = Globals.MainUI.MainFrame.MobileButtons:FindFirstChild(_L("JumpButton"))
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
		if Character:GetAttribute(_L("Hiding")) == true then
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
		if Character:GetAttribute(_L("Hiding")) ~= true and Closet then
			local Prompt = Closet:FindFirstChild(_L("HidePrompt"))
				or Closet:FindFirstChild(_L("HidingPrompt"))
				or Closet:FindFirstChild(_L("HidePrompt"), true)
				or Closet:FindFirstChild(_L("HidingPrompt"), true)

			if not Prompt then
				for _, Child in Closet:GetDescendants() do
					if (Child:IsA(_L("ProximityPrompt")) or Child:IsA(_L("InteractPrompt")))
						and (Child.Name == _L("HidePrompt") or Child.Name == _L("HidingPrompt"))
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
		if Character:GetAttribute(_L("Hiding")) then
			if Toggles.SpectateEntityToggle.Value and Entity.PrimaryPart then
				Globals.SpectateEntity = Entity
			end
		end
		Globals.LastAutoHide = tick()
	end)

	Globals.LastAutoAnchor = tick()
	Connections.AutoSolveAnchorsConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSolveAnchors.Value then return end
		if not Globals.MainUI:FindFirstChild(_L("AnchorHintFrame")) then return end
		if tick() - Globals.LastAutoAnchor <= 0.1 then return end
		local Anchor = Functions.GetCurrentAnchor()
		if Anchor and LocalPlayer:DistanceFromCharacter(Anchor.PrimaryPart.Position) < Anchor.ActivateEventPrompt.MaxActivationDistance and not Anchor:GetAttribute(_L("Activated")) then
			Anchor:WaitForChild(_L("AnchorRemote")):InvokeServer(Globals.MainUI.AnchorHintFrame.Code.Text)
		end
		Globals.LastAutoAnchor = tick()
	end)

	Globals.ManipulateBody = Instance.new(_L("BodyVelocity"))
	Globals.ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.FlyBody = Instance.new(_L("BodyVelocity"))
	Globals.FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.SelfKilled = false
	Globals.ThirdPersonParts = {}
	for _, Object in Character:GetDescendants() do
		if Object:IsA(_L("Accessory")) and Object:FindFirstChild(_L("Handle")) then
			table.insert(Globals.ThirdPersonParts, Object.Handle)
		end
	end
	table.insert(Globals.ThirdPersonParts, Character:WaitForChild(_L("Head")))

	Globals.LastAnimationCheck = tick()
	Globals.LastCrouchFire = tick()
	Globals.OriginalC1 = Character.LowerTorso.Root.C1

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local MainFrame = Globals.MainUI:FindFirstChild(_L("MainFrame"))
	if MainFrame and MainFrame:FindFirstChild(_L("SurgeVignette")) then
		Globals.SurgeFrame = MainFrame.SurgeVignette
		if Toggles.RemoveSurge.Value then
			Globals.SurgeFrame.Name = _L("SurgeVignette_Disabled")
		end
	end

	Connections.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if Services.Workspace:FindFirstChild(_L("Camera")) then
			Camera = Services.Workspace:FindFirstChild(_L("Camera"))
		end

		if Toggles.SpeedBoostToggle.Value then
			Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + Options.SpeedBoostSlider.Value
		end

		if Globals.Lagging or (Options.SpeedBoostSlider.Value <= 6 and Options.FlySpeed.Value <= 21) then
			CollisionPartClone.Massless = true
		end

		Globals.IsEyes    = Services.Workspace:FindFirstChild(_L("Eyes")) ~= nil or Services.Workspace:FindFirstChild(_L("Lookman")) ~= nil
		Globals.IsLookman = Services.Workspace:FindFirstChild(_L("BackdoorLookman")) ~= nil

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

		if Globals.SelfKilled and Globals.MainUI:FindFirstChild(_L("Statistics")) then
			Globals.MainUI.Statistics.Death.Text = _L("Died to Abysall Hub")
		end

		if Globals.Deathing and Globals.MainUI:FindFirstChild(_L("Statistics")) then
			Globals.MainUI.Statistics.Death.Text = _L("Died to Verity")
		end

		local MainFrame = Globals.MainUI:FindFirstChild(_L("MainFrame"))
		if MainFrame then
			local Effects = MainFrame.Healthbar:FindFirstChild(_L("Effects"))
			if Effects and Effects:FindFirstChild(_L("Crouching")) then
				Effects.Crouching.Visible = Functions.IsCrouching()
			end
		end

		if (Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value) and RemotesFolder:FindFirstChild(_L("Crouch")) then
			RemotesFolder.Crouch:FireServer(true, true)
		end

		if Floor ~= _L("Fools") and Floor ~= _L("OldHotel") and not Camera:FindFirstChild(_L("MinecartRig")) then
			RootPart.CanCollide = false
		end

		for _, Part in Character:GetChildren() do
			if Part:IsA(_L("BasePart")) then Part.CanCollide = false end
		end

		if LocalPlayer:GetAttribute(_L("Alive")) == true then
			Services.SoundService:WaitForChild(_L("Main")).Volume = 1
		end

		if Floor == _L("OldHotel") or Floor == _L("Fools") then
			local SpoofOffset = Toggles.PositionSpoof.Value and Functions.GetNearestEntity() and 200 or Toggles.FigureGodmode.Value and Functions.GetNearestFigure() and 200 or 0
			Globals.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == _L("Fools") then
				Collision.CollisionCrouch.CanCollide = false
				CollisionClone.CollisionCrouch.CanCollide = false
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
		else
			Collision.CanCollide = false
			if Collision:FindFirstChild(_L("CollisionCrouch")) then Collision.CollisionCrouch.CanCollide = false end

			if CollisionClone:FindFirstChild(_L("CollisionCrouch")) then
				local IsCrouch = Functions.IsCrouching()
				CollisionClone.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or IsCrouch)
				CollisionClone.CollisionCrouch.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or not IsCrouch)
			else
				RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
			end

			if Character:FindFirstChild(_L("LowerTorso")) and Character.LowerTorso:FindFirstChild(_L("Root")) then
				Character.LowerTorso.Root.C1 = Globals.OriginalC1 * CFrame.new(0, Toggles.PositionSpoof.Value and -2.346 or 0, 0)
			end

			local SpoofY = Toggles.PositionSpoof.Value and 2.328 or 0.18
			Collision.Position     = RootPart.Position + Vector3.new(0, SpoofY, 0)
			CollisionPart.Position = RootPart.Position + Vector3.new(0, SpoofY, 0)

			if Collision:FindFirstChild(_L("CollisionCrouch")) and CollisionClone:FindFirstChild(_L("CollisionCrouch")) then
				local CrouchY = Toggles.PositionSpoof.Value and 1.328 or -0.982
				Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, CrouchY, 0)
				CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
			end
			if CollisionClone:FindFirstChild(_L("CollisionCrouch")) then
				CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 0.75 or -0.982, 0)
			end
		end

		CollisionClone.CollisionGroup = Collision.CollisionGroup
		CollisionClone.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 1.75 or 0.18, 0)

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == _L("Velocity") then
			Globals.ManipulateBody.Parent = RootPart
			Globals.ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
		else
			Globals.ManipulateBody.Parent = nil
		end

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == _L("Pivot") and Floor ~= _L("Fools") and Floor ~= _L("OldHotel") then
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
			if Floor == _L("Fools") or Floor == _L("OldHotel") then
				RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
			else
				RemotesFolder.MotorReplication:FireServer(-650)
			end
		end

		if RemotesFolder:FindFirstChild(_L("Crouch")) and tick() - Globals.LastCrouchFire > 0.1 then
			local IsCrouch = Functions.IsCrouching()
			if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then IsCrouch = true end
			RemotesFolder.Crouch:FireServer(IsCrouch, true)
			Globals.LastCrouchFire = tick()
		end

		if tick() - Globals.LastAnimationCheck > 0.1 then
			local Sliding = false
			for _, Anim in Humanoid:GetPlayingAnimationTracks() do
				if Anim.Name == _L("Slide") then Sliding = true break end
			end
			Globals.Sliding = Sliding
			Globals.LastAnimationCheck = tick()
		end

		Character:SetAttribute(_L("Sliding"), Globals.Sliding)
		if Character:GetAttribute(_L("Crouching")) ~= Functions.IsCrouching() then
			Character:SetAttribute(_L("Crouching"), Functions.IsCrouching())
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
			if Options.SpecateEntityMode.Value == _L("Player to Entity") then
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
			and Character:GetAttribute(_L("AnimatingClient")) ~= true
			and Character:GetAttribute(_L("Hiding")) == true
		then
			RemotesFolder.CamLock:FireServer()
		end

		local ClosestPlayer = { Distance = math.huge, Object = nil }
		for _, Player in Services.Players:GetPlayers() do
			if Player.Character and Player ~= LocalPlayer then
				local Root = Player.Character:FindFirstChild(_L("HumanoidRootPart"))
				if Root then
					local D = (Camera.CFrame.Position - Root.Position).Magnitude
					if D < ClosestPlayer.Distance then
						ClosestPlayer.Distance = D
						ClosestPlayer.Object = Player
					end
				end
			end
		end
		if ClosestPlayer.Object and LocalPlayer:GetAttribute(_L("Alive")) ~= true then
			LocalPlayer:SetAttribute(_L("CurrentRoom"), ClosestPlayer.Object:GetAttribute(_L("CurrentRoom")))
		end
	end)

	task.wait(1)
	if Toggles.PositionSpoof.Value and Floor ~= _L("Fools") and Floor ~= _L("OldHotel") then
		RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
		Humanoid.HipHeight = 0.05
		RemotesFolder.Crouch:FireServer(true, true)
	end

	local Jam = Globals.MainUI.Initiator.Main_Game.Health:FindFirstChild(_L("Jam"))
	if Jam and Toggles.RemoveJamminMusic.Value then
		Jam.Volume = 0
		Globals.JamMuffle.Enabled = false
	end
end

Functions.HandleHidingTransparency = function(Model)
	local Parts = {}
	for _, Part in Model:GetDescendants() do
		if Part:IsA(_L("BasePart")) then
			Part:SetAttribute(_L("Transparency_Old"), Part.Transparency)
			table.insert(Parts, Part)
		end
		if Part.Name == _L("HiddenPlayer") then
			local HideConn = Part:GetPropertyChangedSignal(_L("Value")):Connect(function()
				for _, P in Parts do
					if P:GetAttribute(_L("Transparency_Old")) then
						Services.TweenService:Create(P, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
							Transparency = (Part.Value == Character and Toggles.TransparentHidingSpotsToggle.Value)
								and Options.TransparentHidingSpotsSlider.Value
								or P:GetAttribute(_L("Transparency_Old"))
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
			Object:SetAttribute(_L("ParentRoom"), tonumber(Room.Name))
			break
		end
		task.wait()
	end

	if Object.Parent == CurrentRooms then
		local FiredampVal = Object:GetAttribute(_L("Firedamp"))
		Object:SetAttribute(_L("Firedamp_Old"), FiredampVal ~= nil and FiredampVal or false)
		if Toggles.DisableFiredampEffect.Value then
			Object:SetAttribute(_L("Firedamp"), false)
		end
	end

	local Name = Object.Name

	if Name == _L("KeyObtain") then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Door Key"), Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == _L("ElectricalKeyObtain") then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Electrical Key"), Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == _L("TimerLever") then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				Object:SetAttribute(_L("AddTime"), Object.TakeTimer.TextLabel.Text == _L("01:00") and 60 or 30)
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Time Lever [+") .. Object:GetAttribute(_L("AddTime")) .. _L("s]"), Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild(_L("Main")).SoundToPlay.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == _L("StairwellLockpickDoor") then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Garage Door"), Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == _L("Mirror") then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Mirror"), Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == _L("StairwellFireAlarm") then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Fire Alarm"), Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == _L("ShoppingCart") then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Shopping Cart"), Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == _L("StairwellScrapper") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Scrapper"), Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("ArchivesPackageDeposit") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Package Deposit"), Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("Cellar") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Cellar"), Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("ArchivesFihTank") then
		if Toggles.MiscESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Fih Tank"), Color = Options.MiscESPColor.Value }, true) end
		table.insert(Objects.Misc, Object)
	elseif Name == _L("LiveHintBook") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Hint Book"), Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("LiveBreakerPolePickup") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Fuse Breaker"), Color = Options.ObjectiveESPColor.Value }, true) end
		for _, Child in Object:GetChildren() do
			if Child.Name == _L("ActivateEventPrompt") and (Child.MaxActivationDistance == 5 or Child:GetAttribute(_L("MaxActivationDistance_Old")) == 5) then
				Child:Destroy()
			end
		end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("LibraryHintPaper") or Name == _L("PickupItem") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Hint Paper"), Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("MinesAnchor") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Anchor [") .. Object:WaitForChild(_L("Sign")).TextLabel.Text .. _L("]"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object:GetAttributeChangedSignal(_L("Activated")):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("WaterPump") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object:WaitForChild(_L("Wheel")), Text = _L("Water Pump"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild(_L("Wheel")).Sound.Played:Once(function()
			Object:SetAttribute(_L("Abysall_Completed"), true)

			Functions.RemoveESP(Object.Wheel)
			Functions.BlacklistESP(Object.Wheel)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("CringlePresent") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Present"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild(_L("ToolProp")).Highlight:Destroy()
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("LeverForGate") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Gate Lever"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild(_L("Main")).SoundToPlay.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("VineGuillotine") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object.Lever, Text = _L("Vine Lever"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Lever:WaitForChild(_L("ActivateEventPrompt")):GetAttributeChangedSignal(_L("Interactions")):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("MandrakeLive") then
		if Toggles.ObjectiveESPToggle.Value and Options.EntityESPOptions.Value[_L("Mandrake Hole")] then Functions.AddESP({ Object = Object.Hole, Text = _L("Mandrake Hole"), Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object.Hole)
	elseif Name == _L("MinesGenerator") then
		task.spawn(function()
			task.wait(0.75)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Generator"), Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild(_L("Lever")).Sound.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == _L("FuseObtain") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Generator Fuse"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild(_L("Hitbox")).FuseModel:GetPropertyChangedSignal(_L("LocalTransparencyModifier")):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("MinesGateButton") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Gate Button"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild(_L("MinesGate")).Main.SoundOpen.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("GardenGateButton") then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Gate Button"), Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild(_L("GardenGate")).Collision.Sound.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == _L("Ladder") then
		if Toggles.LadderESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Ladder"), Color = Options.LadderESPColor.Value }, true) end
		table.insert(Objects.Ladders, Object)
	elseif Name == _L("Door") and Object.Parent and tonumber(Object.Parent.Name) then
		local DoorParts = {}
		for _, Child in Object:GetChildren() do
			if Child.Name == _L("Door") and Child:IsA(_L("BasePart")) then
				table.insert(DoorParts, Child)
			end
		end

		if #DoorParts == 2 then
			local HighlightModel = Instance.new(_L("Model"), Object)
			HighlightModel.Name = _L("HighlightModel")
			Instance.new(_L("Humanoid"), HighlightModel).Name = _L("HighlightHumanoid")
			HighlightModel:SetAttribute(_L("ParentRoom"), tonumber(Object.Parent.Name))

			for _, DoorPart in DoorParts do
				local HP = Instance.new(_L("Part"), HighlightModel)
				HP.Transparency = 0.999
				HP.Size = DoorPart.Size
				HP.CanCollide = false
				HP.CFrame = DoorPart.CFrame
				HP.Name = _L("HighlightPart")
				HP.Material = Enum.Material.Plastic
				HP:SetAttribute(_L("ParentRoom"), tonumber(Object.Parent.Name))
				local W = Instance.new(_L("WeldConstraint"), HP)
				W.Part0 = HP W.Part1 = DoorPart W.Enabled = true
			end
			table.insert(Objects.Doors, HighlightModel)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HighlightModel, Text = _L("Door ") .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		else
			local Root = Object:WaitForChild(_L("Door"), 9e9)
			local HP = Instance.new(_L("Part"), Object)
			HP.Transparency = 0.999
			HP.Size = Root.Size
			HP.CanCollide = false
			HP.CFrame = Root.CFrame
			HP.Name = _L("HighlightPart")
			HP.Material = Enum.Material.Plastic
			HP:SetAttribute(_L("ParentRoom"), tonumber(Object.Parent.Name))
			local W = Instance.new(_L("WeldConstraint"), HP)
			W.Part0 = HP W.Part1 = Root W.Enabled = true
			Instance.new(_L("Humanoid"), Object).Name = _L("HighlightHumanoid")
			table.insert(Objects.Doors, HP)
			if Toggles.DoorESPToggle.Value then Functions.AddESP({ Object = HP, Text = _L("Door ") .. Functions.GetDoorNumber(Object), Color = Options.DoorESPColor.Value }, true) end
		end

		local LastDoorFire = tick()
		local DoorConn = Services.RunService.Heartbeat:Connect(function()
			if Object:FindFirstChild(_L("Door")) and Object:FindFirstChild(_L("ClientOpen")) then
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
		Object:WaitForChild(_L("Door")):WaitForChild(_L("Open")).Played:Once(function()
			DoorConn:Disconnect()
		end)
		table.insert(Connections, DoorConn)

	elseif Name == _L("PathLights") then
		local ObjectsToHighlight = {}
		local PLConn = Object.ChildAdded:Connect(function(Child)
			table.insert(ObjectsToHighlight, Child)
		end)
		for _, Child in Object:GetChildren() do
			table.insert(ObjectsToHighlight, Child)
		end

		local function CreateSeekNode(Light)
			if Light.Name ~= _L("SeekGuidingLight") or Light:GetAttribute(_L("Highlighted")) then return end
			Light:SetAttribute(_L("Highlighted"), true)

			local NewNode = Instance.new(_L("Part"))
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Globals.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.CFrame = Light.CFrame
			NewNode.CanCollide = false
			NewNode.Name = _L("SeekLightNode")

			local PrevNode2 = PreviousNode or NewNode
			PreviousNode = NewNode

			local Beam = Instance.new(_L("Beam"))
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
			local A0 = Instance.new(_L("Attachment"), NewNode)
			local A1 = Instance.new(_L("Attachment"), PrevNode2)
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
	elseif Name == _L("SeekMovingNewClone") then
		local Connection = Object.Destroying:Connect(function()
			for _, Folder in pairs(Objects.PathLights) do
				Folder:ClearAllChildren()
			end
			Globals.SeekNodesFolder:ClearAllChildren()
		end)
		table.insert(Connections, Connection)
	elseif Name == _L("Bridge") then
		for _, Child in Object:GetChildren() do
			if Child.Name == _L("PlayerBarrier") and Child.Size.Y == 2.75 and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
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
    elseif Name == _L("MinecartRig") then
        Globals.Minecart = Object
	elseif Name == _L("RunnerNodes") then
		local function IsBehind(Part1, Part2)
			local P1 = (Part1.CFrame + Part1.CFrame.LookVector).Position
			local P2 = (Part1.CFrame + Part1.CFrame.LookVector * -1).Position
			return (P1 - Part2.Position).Magnitude > (P2 - Part2.Position).Magnitude
		end
		local function GetDirection(Part1, Part2)
			local RightDist = Part1.CFrame.RightVector:Dot(Part1.Position - Part2.Position)
			if RightDist > 0.5    then return IsBehind(Part1, Part2) and _L("Right") or _L("Left") end
			if RightDist < -0.5   then return IsBehind(Part1, Part2) and _L("Left") or _L("Right") end
			return _L("Straight")
		end
		local function GetClosestNode(Node)
			local Best, BestDist = nil, math.huge
			local NodeID2 = tonumber(Node.Name:split(_L("MinecartNode"))[2])
			for _, OtherNode in Object:GetChildren() do
				local OtherID = tonumber(OtherNode.Name:split(_L("MinecartNode"))[2])
				if OtherNode ~= Node and OtherID and NodeID2 and OtherID > NodeID2 then
					local D = (Node.Position - OtherNode.Position).Magnitude
					if D < BestDist and OtherNode:GetAttribute(_L("DistanceBlacklist")) ~= true then
						BestDist = D Best = OtherNode
					end
				end
			end
			return Best
		end

		for _, Node in Object:GetChildren() do
			local NodeID = tonumber(Node.Name:split(_L("MinecartNode"))[2])
			if Node:GetAttribute(_L("DeathType")) then Node:SetAttribute(_L("DistanceBlacklist"), true) end
			for I = 1, 20 do
				local NextNode = NodeID and Object:FindFirstChild(_L("MinecartNode") .. NodeID + I)
				if NextNode and NextNode:GetAttribute(_L("DeathType")) ~= nil then
					Node:SetAttribute(_L("DistanceBlacklist"), true)
				end
			end
			local PrevNode3 = NodeID and Object:FindFirstChild(_L("MinecartNode") .. NodeID - 1)
			if PrevNode3 and PrevNode3:GetAttribute(_L("ForceConnect")) then
				Node:SetAttribute(_L("DistanceBlacklist"), nil)
			end
			task.wait()
		end

		for _, Node in Object:GetChildren() do
			if Node:GetAttribute(_L("ForceConnect")) then
				local NextNode = GetClosestNode(Node)
				if NextNode then
					Node:SetAttribute(_L("Turn"), GetDirection(Node, NextNode))
					table.insert(Objects.SeekNodes, Node)
				end
			end
			task.wait()
		end

	elseif Name == _L("EyestalkEndCutscene") then
		Object.Name = _L("_EyestalkEndCutscene")
	elseif Name == _L("DuckBoard") then
		table.insert(Objects.SeekDuckBoards, Object)
	elseif HidingSpotLabels[Name] or string.find(string.lower(Name), _L("hidingspot")) then
		local Label = HidingSpotLabels[Name] or (string.find(string.lower(Name), _L("hidingspot")) and _L("Hiding Spot") or nil)
		if Label and Toggles.HidingSpotESPToggle.Value then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true) end
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Object:FindFirstChild(_L("HidingPrompt")) or Object:FindFirstChild(_L("HidePrompt")) then
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Name == _L("Lava") then
		if Toggles.BypassKillbricks.Value then Object.CanTouch = false end
		table.insert(Objects.Obstructions, Object)
	elseif Name == _L("ScaryWall") then
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) then
				Part.CanTouch = not Toggles.BypassSeekingWall.Value
				Part.CanCollide = not Toggles.BypassSeekingWall.Value

                local Connection1 = Part:GetPropertyChangedSignal(_L("CanTouch")):Connect(function()
                    if Part.CanTouch == Toggles.BypassSeekingWall.Value then
                        Part.CanTouch = not Toggles.BypassSeekingWall.Value
                    end
                end)
                local Connection2 = Part:GetPropertyChangedSignal(_L("CanCollide")):Connect(function()
                    if Part.CanCollide == Toggles.BypassSeekingWall.Value then
                        Part.CanCollide = not Toggles.BypassSeekingWall.Value
                    end
                end)

                table.insert(Connections, Connection1)
                table.insert(Connections, Connection2)
            end
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == _L("ChestBox") or Name == _L("ChestBoxLocked") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute(_L("Locked")) and _L("Locked Chest") or _L("Chest"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == _L("Toolbox") or Name == _L("Toolbox_Locked") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute(_L("Locked")) and _L("Locked Toolbox") or _L("Toolbox"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == _L("Chest_Vine") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Vine Chest"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == _L("Toolshed_Small") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Toolshed"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == _L("Locker_Small_Locked") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Locked Item Locker"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif Name == _L("MouseHole") then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Mouse"), Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif ItemNames[Name] and Object:FindFirstChild(_L("ModulePrompt")) then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = ItemNames[Name], Color = Options.ItemESPColor.Value }, Object:GetAttribute(_L("ParentRoom")) ~= nil) end
		if Name == _L("LotusHolder") or Name == _L("LotusPetalPickup") then
			Object.Handle:GetPropertyChangedSignal(_L("LocalTransparencyModifier")):Connect(function()
				Abysall.ESPLibrary:RemoveESP(Object)
				Functions.BlacklistESP(Object)
			end)
		end

		if Toggles.NotifyItemsToggle.Value and Options.NotifyItemList.Value[ItemNames[Name]] and Object.Parent.Name ~= _L("Drops") then
			if Toggles.NotifyItemsShowDistance.Value then
				Functions.Notify({ Title = _L("Item '") .. ItemNames[Name] .. _L("' has spawned."), Body = _L("It is '") .. math.round(LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)) .. _L("' studs away from you.") })
			else
				Functions.Notify({ Title = _L("Item '") .. ItemNames[Name] .. _L("' has spawned.")})
			end
		end

		table.insert(Objects.Items, Object)
	elseif Name == _L("Green_Herb") then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Green Herb"), Color = Options.ItemESPColor.Value }, true) end
		table.insert(Objects.Items, Object)
	elseif Name == _L("GoldPile") and Object:GetAttribute(_L("GoldValue")) then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Gold Pile [") .. Object:GetAttribute(_L("GoldValue")) .. _L("]"), Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == _L("StardustPickup") then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = _L("Stardust Pile"), Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == _L("GiggleCeiling") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Giggle")] then Functions.AddESP({ Object = Object, Text = _L("Giggle"), Color = Options.EntityESPColor.Value }, true) end
		if Toggles.BypassGiggle.Value then Object:WaitForChild(_L("Hitbox")).CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("GloomPile") then
		if Toggles.BypassGloombatEggs.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then Part.CanTouch = false
				end
			end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA(_L("BasePart")) then Part.CanTouch = false end
		end)

		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Gloombat Eggs")] then
			Functions.AddESP({ Object = Object, Text = _L("Gloombat Eggs"), Color = Options.EntityESPColor.Value })
		end

		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == _L("TriggerEventCollision") and Functions.CheckCompatability({_L("firetouchinterest")}) then
		if (Floor == _L("Fools") or Floor == _L("OldHotel")) and Toggles.RemoveSeekTrigger.Value then
			task.spawn(function()
				while Object:IsDescendantOf(game) do
					for _, Part in Object:GetChildren() do
						if Part:IsA(_L("BasePart")) then
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
	elseif Name == _L("DoorFake") or Name == _L("FakeDoor") then
		if Object.Parent and Object:FindFirstChild(_L("Hidden")) then
			if Toggles.BypassDupe.Value then
				Object:WaitForChild(_L("Hidden")).CanTouch = false
				local Lock = Object:FindFirstChild(_L("Lock"))
				if Lock and Lock:FindFirstChild(_L("UnlockPrompt")) then Lock.UnlockPrompt.Enabled = false end
			end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Dupe")] then
				Functions.AddESP({ Object = Object, Text = _L("Dupe"), Color = Options.EntityESPColor.Value }, true)
			end
			table.insert(Objects.Entities, Object)
		end
	elseif Name == _L("SideroomSpace") then
		if Toggles.BypassVacuum.Value then
			Object:WaitForChild(_L("Collision")).CanCollide = true
			Object:WaitForChild(_L("Collision")).CanTouch = false
		end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("Snare") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Snare")] then Functions.AddESP({ Object = Object, Text = _L("Snare"), Color = Options.EntityESPColor.Value }, true) end
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) then Part.CanTouch = not Toggles.BypassSnare.Value end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA(_L("BasePart")) then Part.CanTouch = not Toggles.BypassSnare.Value end
		end)
		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)

		if Object:FindFirstChild(_L("Snare")) then
			Object:WaitForChild(_L("Snare")):WaitForChild(_L("Roots")).Transparency = 1
			Object:WaitForChild(_L("Snare")):WaitForChild(_L("SnareBase")).Transparency = 1
		end
		if Object:FindFirstChild(_L("Void")) then
			Object.Void.Transparency = 0
			Object.Void.Color = Color3.fromRGB(76, 67, 55)
		end
	elseif Name == _L("Seek_Arm") or Name == _L("ChandelierObstruction") then
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) then
				Part.CanTouch = not Toggles.BypassSeekObstructions.Value
				table.insert(Objects.SeekObstructions, Part)
			end
		end
	elseif Name == _L("SeekFloodline") then
		Object.CanCollide = Toggles.BypassSeekObstructions.Value
		local FloodConn = Object:GetPropertyChangedSignal(_L("CanCollide")):Connect(function()
			if Object.CanCollide ~= Toggles.BypassSeekObstructions.Value then
				Object.CanCollide = Toggles.BypassSeekObstructions.Value
			end
		end)
		Object.Destroying:Once(function() FloodConn:Disconnect() end)
		table.insert(Objects.SeekObstructions, Object)
	elseif Object:GetAttribute(_L("RawName")) and Object:GetAttribute(_L("RawName")):find(_L("Halt")) or Object:GetAttribute(_L("Shade")) == true then
		if Toggles.NotifyEntities.Value and Options.EntityList.Value[_L("Halt")] then
			Functions.Notify({ Title = _L("Entity 'Halt' will spawn in the next room."), Image = EntityIcons[_L("Halt")] })
			if Toggles.EntityChatToggle.Value then Functions.SendChat(_L("Halt next room!")) end
		end
		local HaltLogConn
		HaltLogConn = Services.LogService.MessageOut:Connect(function(Message)
			if Message == _L("client teleporting") then
				if Globals.AnticheatDisabled then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = _L("The anticheat has been re-enabled."), Body = _L("Interact with a ladder to disable it again.") })
				end
				HaltLogConn:Disconnect()
			end
		end)
	elseif Name == _L("BananaPeel") then
		if Toggles.BypassBanana.Value then Object.CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("JeffTheKiller") then
		if Toggles.BypassJeff.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then Part.CanCollide = false Part.CanTouch = false end
			end
			Object:WaitForChild(_L("Humanoid")).Health = 0
		end
	elseif Name == _L("GrumbleRig") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Grumble")] then Functions.AddESP({ Object = Object, Text = _L("Grumble"), Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("LiveEntityBramble") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Bramble")] then Functions.AddESP({ Object = Object, Text = _L("Bramble"), Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("Groundskeeper") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Groundskeeper")] then Functions.AddESP({ Object = Object, Text = _L("Groundskeeper"), Color = Options.EntityESPColor.Value }, true) end
		if Toggles.NotifyEntities.Value and Options.EntityList.Value[_L("Groundskeeper")] then
			local ED = Entities[_L("Groundskeeper")]
			Functions.Notify({ Title = ED.NotifyMessage.Title, Body = ED.NotifyMessage.Body, Image = EntityIcons[_L("Groundskeeper")] })
		end
		table.insert(Objects.Entities, Object)
	elseif Name == _L("Figure") or Name == _L("FigureRig") or Name == _L("FigureRagdoll") then
		for _, Part in Object:GetDescendants() do
			if Part:IsA(_L("BasePart")) then
				Part.CanTouch = false
			end
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[_L("Figure")] then Functions.AddESP({ Object = Object, Text = _L("Figure"), Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
		if Toggles.RemoveFigure.Value and Functions.CheckCompatability({_L("isnetworkowner")}) then
			if Floor == _L("Mines") then
				for _, Part in Object:GetDescendants() do
					if Part:IsA(_L("BasePart")) then
						task.spawn(function()
							if Abysall.Environment.isnetworkowner(Part) then
								Part.Position = Vector3.new(-49999, -49999, -49999)
							end
						end)
					end
				end
			elseif Floor == _L("OldHotel") or Floor == _L("Fools") then
				CurrentRooms.ChildAdded:Wait()
				for _, Part in Object:GetDescendants() do
					if Part:IsA(_L("BasePart")) then
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
	elseif (Name == _L("ThingToOpen") or Name == _L("MovingDoor")) and (Floor == _L("Fools") or Floor == _L("OldHotel"))
		or Name == _L("Wax_Door") and Floor == _L("Fools")
	then
		Object:SetAttribute(_L("OriginalPosition"), Object:GetPivot())
		local ToggleMap = { ThingToOpen = _L("RemoveBasementGate"), MovingDoor = _L("RemovePaintingsDoor"), Wax_Door = _L("RemoveSkeletonDoor") }
		if ToggleMap[Name] and Toggles[ToggleMap[Name]].Value then
			Object:PivotTo(CFrame.new(-10000, -10000, -10000))
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == _L("ElevatorBreaker") then
		if Toggles.AutoBreakerBox.Value and not Globals.BreakerBoxNotified then
			Functions.Notify({ Title = _L("Interact with the breaker box."), Body = _L("It will be automatically solved.") })
			Globals.BreakerBoxNotified = true
		end
		Connections.BreakerConnection = Object:WaitForChild(_L("SurfaceGui")).Frame.Code:GetPropertyChangedSignal(_L("Text")):Connect(function()
			if Toggles.AutoBreakerBox.Value then
				if not Globals.BreakerBoxStartNotified and (Floor == _L("Fools") or Floor == _L("OldHotel")) then
					Functions.Notify({ Title = _L("Attempting to solve the breaker box."), Body = _L("Please wait.") })
					Globals.BreakerBoxStartNotified = true
				end
				RemotesFolder.EBF:FireServer()
			end
			Globals.BreakerBoxInteracted = true
		end)
	elseif Name == _L("ElevatorCar") then
		local ElevConn = Object.DescendantAdded:Connect(function(Desc)
			if Toggles.AutoBreakerBox.Value and Desc.Name == _L("TouchInterest") and not Globals.BreakerBoxFinishedNotified then
				Functions.Notify({ Title = _L("Successfully solved the breaker box."), Body = _L("Try going to the elevator!") })
				Globals.BreakerBoxFinishedNotified = true
			end
		end)
		Object.Destroying:Once(function() ElevConn:Disconnect() end)
	elseif Object.ClassName == _L("ProximityPrompt") and not Object:GetAttribute(_L("FakePrompt")) then
		if Object:HasTag(_L("DisableWhenEnabledOnClient")) then Object:RemoveTag(_L("DisableWhenEnabledOnClient")) end

		Object:SetAttribute(_L("HoldDuration_Old"), Object.HoldDuration)
		Object:SetAttribute(_L("RequiresLineOfSight_Old"), Object.RequiresLineOfSight)
		Object:SetAttribute(_L("MaxActivationDistance_Old"), Object.MaxActivationDistance)

		if Toggles.InstantPrompts.Value    then Object.HoldDuration = 0 end
		if Toggles.PromptClip.Value        then Object.RequiresLineOfSight = false end
		Object.MaxActivationDistance = Object:GetAttribute(_L("MaxActivationDistance_Old")) * Options.PromptReachSlider.Value

		local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }

		if Functions.CheckCompatability({_L("fireproximityprompt")}) and Floor ~= _L("OldHotel") and Floor ~= _L("Fools") then
			local IsLockPrompt = LockPromptNames[Object.Name]
				or (Object.Parent and Object.Parent:GetAttribute(_L("Locked")) == true)
				or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == _L("Locker_Small_Locked") and Object.Name == _L("ActivateEventPrompt"))

			if IsLockPrompt then
				local FakePrompt = Object:Clone()
				FakePrompt:SetAttribute(_L("FakePrompt"), true)
				task.wait()
				FakePrompt.Parent = Object.Parent

				FakePrompt:SetAttribute(_L("HoldDuration_Old"), Object:GetAttribute(_L("HoldDuration_Old")))
				FakePrompt:SetAttribute(_L("RequiresLineOfSight_Old"), Object:GetAttribute(_L("RequiresLineOfSight_Old")))
				FakePrompt:SetAttribute(_L("MaxActivationDistance_Old"), Object:GetAttribute(_L("MaxActivationDistance_Old")))

				FakePrompt.HoldDuration = Object.HoldDuration
				FakePrompt.RequiresLineOfSight = Object.RequiresLineOfSight
				FakePrompt.MaxActivationDistance = Object.MaxActivationDistance

				if Toggles.InstantPrompts.Value    then FakePrompt.HoldDuration = 0 end
				if Toggles.PromptClip.Value        then FakePrompt.RequiresLineOfSight = false end
				FakePrompt.MaxActivationDistance = FakePrompt:GetAttribute(_L("MaxActivationDistance_Old")) * Options.PromptReachSlider.Value

				FakePrompts[FakePrompt] = Object
				pcall(function() Object.Parent = Globals.PromptContainer end)

				local FPEnabledConn = Object:GetPropertyChangedSignal(_L("Enabled")):Connect(function()
					FakePrompt.Enabled = Object.Enabled
				end)
				Object:GetPropertyChangedSignal(_L("ActionText")):Once(function()
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
	elseif Name == _L("Padlock") then
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
	if not Object:GetAttribute(_L("FakePrompt")) then return end
	local ToolNames = { _L("Lockpick"),_L("Shears"),_L("SkeletonKey"),_L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyBackdoor"),_L("KeyIron"), _L("Multitool") }
	local AnimateToolNames = { _L("Lockpick"),_L("Shears"),_L("SkeletonKey"),_L("Key"),_L("KeyElectrical"),_L("KeyBackdoor"),_L("KeyIron"), _L("Multitool") }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute(_L("Locked")) == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == _L("Locker_Small_Locked") and Object.Name == _L("ActivateEventPrompt"))
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value[_L("Locks")] then return end
		local KeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyBackdoor"),_L("KeyElectrical"),_L("KeyIron"),_L("Lockpick"),_L("SkeletonKey"),_L("Shears"),_L("Multitool") }
		local OffhandKeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyIron") }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == _L("CuttableVines") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Chest_Vine") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Cellar") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Prompt.Parent.Name == _L("SkullLock") and not Functions.HasItem(_L("SkeletonKey"), true) then return end
	if Prompt.Parent.Name == _L("Lock1") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Lock2") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Functions.HasItem(_L("Shears"), true) and IsLockPrompt and Prompt.Parent.Name ~= _L("CuttableVines") and Prompt.Parent.Name ~= _L("Chest_Vine") and Prompt.Parent.Name ~= _L("Cellar") then return end
	
	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation then
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimation:Stop()
		Globals.UseAnimation:Play()
		if Tool.Name == _L("Shears") then Tool:WaitForChild(_L("Handle")):WaitForChild(_L("sound_prompt")):Play() end
	end
end)

Globals.ObjectQueue = {}
local AllowedInstances = {
	Lava=true, GoldPile=true, KeyObtain=true, Drakobloxxer=true, FuseObtain=true,
	MinesGenerator=true, JeffTheKiller=true, Snare=true, FakeDoor=true, DoorFake=true, SideroomSpace=true,
	ChestBox=true, ChestBoxLocked=true, Chest_Vine=true, Locker_Small_Locked=true, Toolbox=true,
	Toolbox_Locked=true, Wardrobe=true, [_L("Wardrobe-FOOLS26")]=true, Toolshed=true, Toolshed_Small=true,
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
	local IsHidingSpot = typeof(Object.Name) == _L("string") and string.find(string.lower(Object.Name), _L("hidingspot"))
	if not AllowedInstances[Object.Name] and not IsHidingSpot and Object.ClassName ~= _L("ProximityPrompt") and Object.Parent ~= CurrentRooms and not ItemNames[Object.Name] then
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
		local DeadConn = Player:GetAttributeChangedSignal(_L("Alive")):Connect(function()
			if Player:GetAttribute(_L("Alive")) ~= true and Player.Character then
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
	local DeadConn = Player:GetAttributeChangedSignal(_L("Alive")):Connect(function()
		if Player:GetAttribute(_L("Alive")) ~= true and Player.Character then
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
		if not Prompt:IsA(_L("ProximityPrompt")) or PromptCooldown[Prompt] or table.find(PromptsToFire, Prompt) or not Camera then return end
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

			local TempPart = Instance.new(_L("Part"))
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
	while Model and not Model:IsA(_L("Model")) do
		Model = Model.Parent
	end
	if not Model then return nil end

	local Name = string.lower(Model.Name)
	if not string.find(Name, _L("hidingspot")) and not string.find(Name, _L("hiding_spot")) then
		return nil
	end
	return Model
end

local function HasHidePrompt(Model)
	return Model and (Model:FindFirstChild(_L("HidePrompt")) or Model:FindFirstChild(_L("HidingPrompt"))) ~= nil
end

local function IsHidingSpotPrompt(Prompt)
	if not Prompt or not Prompt.Parent then return false end
	if Prompt.Name ~= _L("HidePrompt") and Prompt.Name ~= _L("HidingPrompt") then return false end
	return HasHidePrompt(GetHidingSpotModel(Prompt))
end

Functions.TriggerPrompt = function(Prompt)
	if not Prompt or not Prompt.Parent then return end
	if Character:GetAttribute(_L("Hiding")) == true then return end
	local HidingSpot = GetHidingSpotModel(Prompt)
	if HidingSpot and Prompt.Name ~= _L("InteractPrompt") then return end
	local IsHidingSpotInteractPrompt = HidingSpot and Prompt.Name == _L("InteractPrompt")
	if AutoInteractBlacklist[Prompt.Name] and not IsHidingSpotPrompt(Prompt) and not IsHidingSpotInteractPrompt then return end
	if (Prompt.Name == _L("HidePrompt") or Prompt.Name == _L("HidingPrompt")) and not IsHidingSpotPrompt(Prompt) then return end
	if (Prompt.Name == _L("HidePrompt") or Prompt.Name == _L("HidingPrompt") or IsHidingSpotPrompt(Prompt)) then
		if not Toggles.AutoClosetToggle.Value then return end
		local Entity = Functions.GetNearestEntity(true, Options.AutoClosetEntityList.Value)
		if not Entity then return end
		local EntityDistance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
		if EntityDistance > (EntityDistances[Entity.Name] or 150) then return end
	end
	if TriggerDebounce then return end

	local ParentItem = Functions.HasItem(Prompt.Parent.Name)
	if ParentItem and ParentItem:GetAttribute(_L("Durability")) and ParentItem:GetAttribute(_L("DurabilityMax"))
		and ParentItem:GetAttribute(_L("Durability")) >= ParentItem:GetAttribute(_L("DurabilityMax"))
	then return end

	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Prompt.Name]
		or (Prompt.Parent and Prompt.Parent:GetAttribute(_L("Locked")) == true)
		or (Prompt.Parent and Prompt.Parent.Parent and Prompt.Parent.Parent.Name == _L("Locker_Small_Locked") and Prompt.Name == _L("ActivateEventPrompt"))

	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value[_L("Locks")] then return end
		local KeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyBackdoor"),_L("KeyElectrical"),_L("KeyIron"),_L("Lockpick"),_L("SkeletonKey"),_L("Shears"),_L("Multitool") }
		local OffhandKeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyIron") }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == _L("CuttableVines") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Chest_Vine") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Cellar") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Prompt.Parent.Name == _L("SkullLock") and not Functions.HasItem(_L("SkeletonKey"), true) then return end
	if Prompt.Parent.Name == _L("Lock1") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Lock2") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Functions.HasItem(_L("Shears"), true) and IsLockPrompt and Prompt.Parent.Name ~= _L("CuttableVines") and Prompt.Parent.Name ~= _L("Chest_Vine") and Prompt.Parent.Name ~= _L("Cellar") then return end

	if Prompt.Parent.Name == _L("GlitchCube") and Options.AutoInteractIgnoreList.Value[_L("Glitch Fragments")] then return end

	if (Prompt.Parent.Name == _L("KeyObtain") and (Functions.HasItem(_L("Key")) or Functions.HasItem(_L("KeyBackdoor"))))
		or (Prompt.Parent.Name == _L("ElectricalKeyObtain") and Functions.HasItem(_L("KeyElectrical")))
	then return end

	if Prompt:IsDescendantOf(Drops) and Options.AutoInteractIgnoreList.Value[_L("Dropped Items")] then return end
	if Prompt.Parent.Name == _L("TrackLever") then return end
	if Prompt.Name == _L("ActivateEventPrompt") and (Prompt.ActionText == _L("Close")
		or Prompt.Parent.Name == _L("ElevatorBreaker")
		or (Prompt.Parent.Parent and Prompt.Parent.Parent.Name == _L("IndustrialGate")))
	then return end
	if Prompt.Name == _L("ActivateEventPrompt") and (Prompt.Parent.Name == _L("Padlock") or Prompt.Parent.Name == _L("MinesAnchor")) then return end
	if Prompt.Parent.Name == _L("LeverForGate") and Prompt:GetAttribute(_L("Interactions")) then return end
	if Prompt.Parent.Parent and (Prompt.Parent.Parent.Name == _L("DoorFake") or Prompt.Parent.Parent.Name == _L("FakeDoor")) then return end
	if Prompt.Parent:GetAttribute(_L("JeffShop")) and Options.AutoInteractIgnoreList.Value[_L("Jeff Items")] then return end
	if Prompt:GetAttribute(_L("AutoInteractIgnore")) then return end
	if Prompt.Name == _L("PushPrompt") and Options.AutoInteractIgnoreList.Value[_L("Minecarts")] then return end
	if (Prompt.Parent.Name == _L("GoldPile") or Prompt.Parent.Name == _L("StardustPickup")) and Options.AutoInteractIgnoreList.Value[_L("Currency")] then return end

	if Prompt.Parent.Name == _L("Bandage") then
		local BPack = Functions.HasItem(_L("BandagePack"))
		if Humanoid.Health >= Humanoid.MaxHealth and not BPack then return end
		if BPack and BPack:GetAttribute(_L("Durability")) >= BPack:GetAttribute(_L("DurabilityMax")) then return end
	end

	if Prompt.Parent.Name == _L("Battery") then
		local Tool = Character:FindFirstChildOfClass(_L("Tool"))
		local BPack = Functions.HasItem(_L("BatteryPack"))
		if not Tool and not BPack then return end
		if Tool and Tool:GetAttribute(_L("LightSource")) then
			if Tool:GetAttribute(_L("Durability")) and Tool:GetAttribute(_L("DurabilityMax"))
				and Tool:GetAttribute(_L("Durability")) > Tool:GetAttribute(_L("DurabilityMax"))
			then return end
		elseif not BPack then
			return
		end
		if BPack and BPack:GetAttribute(_L("Durability")) >= BPack:GetAttribute(_L("DurabilityMax")) then return end
	end

	if Prompt.Name == _L("HerbPrompt") then
		local Effects = Globals.MainUI.MainFrame.Healthbar:FindFirstChild(_L("Effects"))
		if Effects and Effects.HerbGreenEffect.Visible then return end
	end

	if (Prompt.Parent.Name == _L("LibraryHintPaper") or Prompt.Parent.Name == _L("PickupItem")) and (Functions.HasItem(_L("LibraryHintPaper")) or Functions.HasItem(_L("LibraryHintPaperHard"))) then return end
	if Prompt.Parent.Name == _L("AlarmClock") and Functions.HasItem(_L("AlarmClock")) then return end
	if Prompt.Parent.Name == _L("KeyObtainFake") or Prompt.Parent.Name == _L("TithingPlate") then return end
	if Prompt.Parent.Name == _L("StarBottle") then return end
    -- archives
	if Prompt.parent.Name == _L("ArchivesStorageBox") then return end
	if Prompt.Parent.Name == _L("Briefcase") then return end
	if Prompt.Name == _L("SinkPrompt") or Prompt.Parent.Name == _L("Faucet") then return end
	if Prompt.Parent.Name == _L("PaperPlanePickup") or Prompt.Parent.Name == _L("PaperPlane") then return end
	if Prompt.Name == _L("ManualOpenPrompt") or Prompt.Name == _L("EntryPrompt") then return end
	if Prompt.Parent.Parent.Name == _L("ArchivesLargePrinter") then return end
	if Prompt.Name == _L("TrashcanPrompt") then return end
	if Prompt.Parent.Name == _L("Keyboard") then return end
	if Prompt.Name == _L("CartPrompt") or Prompt.Parent.Parent.Name == _L("ArchivesOfficeChair") then return end
	if Prompt.Parent.Name == _L("ArchivesTerminal") then return end
	if Prompt.Name == _L("VendorPrompt") then return end
    if Prompt.Parent.Name == _L("SeatPart") or Prompt.Name == _L("SeatPrompt") then return end


	-- Stairwell
	if Prompt.Parent.Name == _L("StairwellScrapper") then return end
	if Prompt.Name == _L("PortraitDupePrompt") or Prompt.Parent.Name == _L("MirrorTool") then return end
	if Prompt.Name == _L("LaptopPrompt") or Prompt.Parent.Name == _L("SecretLaptop") then return end
	if Prompt.Parent.Name == _L("StairwellFireAlarm") or Prompt.Parent.Parent.Name == _L("StairwellFireAlarm") then return end
	if Prompt.Parent.name == _L("CobblerFriendly") then return end
	if Prompt.Parent.Name == _L("StairwellTerminal") then return end
	if Prompt.Parent.Parent.Name == _L("MeldChord") then return end

	Functions.FirePrompt(Prompt)
	TriggerDebounce = true
	if Floor == _L("OldHotel") then task.wait() end
	TriggerDebounce = false
end

Globals.LastAutoInteractFire = tick()
Connections.AutoInteract = Services.RunService.Heartbeat:Connect(function()
	local Active = Toggles.AutoInteractToggle.Value or Options.AutoInteractKeybind:GetState()
    if not Active then return end
    if tick() - Globals.LastAutoInteractFire < 1/60 then return end

	for _, Prompt in Objects.Prompts do
        if Prompt:GetAttribute(_L("ParentRoom")) and tonumber(Prompt:GetAttribute(_L("ParentRoom"))) ~= tonumber(LocalPlayer:GetAttribute(_L("CurrentRoom"))) then continue end

		if Prompt.Parent and (Prompt.Parent:IsA(_L("BasePart")) or Prompt.Parent:IsA(_L("Model"))) then
			local Distance
			if Prompt.Parent:IsA(_L("BasePart")) then
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent.Position)
			else
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent:GetPivot().Position)
			end
			if Distance <= Prompt.MaxActivationDistance and Prompt.Enabled or Distance <= Prompt.MaxActivationDistance and Prompt.Name == _L("LongPushPrompt") or Distance <= Prompt.MaxActivationDistance and Prompt.Name == _L("BigPropPrompt") then
				task.spawn(Functions.TriggerPrompt, Prompt)
			end
		end
	end
    Globals.LastAutoInteractFire = tick()
end)

Connections.InfiniteItemsHandler = Services.ProximityPromptService.PromptTriggered:Connect(function(Object)
	if not Object:GetAttribute(_L("FakePrompt")) then return end

	local ToolNames = { _L("Lockpick"),_L("Shears"),_L("SkeletonKey"),_L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyBackdoor"),_L("KeyIron"), _L("Multitool") }
	local AnimateToolNames = { _L("Lockpick"),_L("Shears"),_L("SkeletonKey"),_L("Key"),_L("KeyElectrical"),_L("KeyBackdoor"),_L("KeyIron"), _L("Multitool") }
	local Tool
	for _, N in ToolNames do Tool = Character:FindFirstChild(N) if Tool then break end end

	local Prompt = Object
	local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
	local IsLockPrompt = LockPromptNames[Object.Name]
		or (Object.Parent and Object.Parent:GetAttribute(_L("Locked")) == true)
		or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == _L("Locker_Small_Locked") and Object.Name == _L("ActivateEventPrompt"))
	if IsLockPrompt then
		if Options.AutoInteractIgnoreList.Value[_L("Locks")] then return end
		local KeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyBackdoor"),_L("KeyElectrical"),_L("KeyIron"),_L("Lockpick"),_L("SkeletonKey"),_L("Shears"),_L("Multitool") }
		local OffhandKeyItems = { _L("Key"),_L("GeneratorFuse"),_L("KeyElectrical"),_L("KeyIron") }
		local HasKey = false
		for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
		for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
		if not HasKey then return end
	end

	if Prompt.Parent.Name == _L("CuttableVines") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Chest_Vine") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Cellar") and not Functions.HasItem(_L("Shears"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Prompt.Parent.Name == _L("SkullLock") and not Functions.HasItem(_L("SkeletonKey"), true) then return end
	if Prompt.Parent.Name == _L("Lock1") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) or Prompt.Parent.Name == _L("Lock2") and not Functions.HasItem(_L("Lockpick"), true) and not Functions.HasItem(_L("Multitool"), true) then return end
	if Functions.HasItem(_L("Shears"), true) and IsLockPrompt and Prompt.Parent.Name ~= _L("CuttableVines") and Prompt.Parent.Name ~= _L("Chest_Vine") and Prompt.Parent.Name ~= _L("Cellar") then return end

	if Tool and table.find(AnimateToolNames, Tool.Name) and Globals.UseAnimation and Globals.UseAnimationBreak then
		Globals.UseAnimation:Stop()
		Globals.UseAnimationBreak:Stop()
		Globals.UseAnimationBreak:Play()
		if Tool.Name == _L("Shears") then Tool:WaitForChild(_L("Handle")):WaitForChild(_L("sound_prompt")):Play() end
	end

	local AnyTool = Character:FindFirstChildOfClass(_L("Tool"))
	local ToolData = AnyTool and ItemNames[AnyTool.Name]
	if AnyTool and ToolData and Toggles.InfiniteItemsToggle.Value and Options.InfiniteItemsList.Value[ToolData] then
		Drops.ChildAdded:Once(function(NewTool)
			local Prompt = NewTool:FindFirstChild(_L("ModulePrompt"))
			local RealPrompt = FakePrompts[Object]
			Functions.FirePrompt(Prompt)
			Functions.FirePrompt(RealPrompt)
		end)
		Character.ChildAdded:Once(function(NewTool)
			if NewTool.Name == _L("Shears") then NewTool:WaitForChild(_L("Handle")):WaitForChild(_L("sound_promptend")):Play() end
		end)
		RemotesFolder.DropItem:FireServer(AnyTool)
	else
		local RealPrompt = FakePrompts[Object]
		Functions.FirePrompt(RealPrompt)
	end
end)

Connections.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(function(Object)
	if Object.Name == _L("GlitchScreech") then
		Modules.GlitchScreech = Object
		if Toggles.RemoveScreech.Value then Object.Name = _L("GlitchScreech_Disabled") end
	end
	if Object.Name:find(_L("Jumpscare")) and Object:IsA(_L("ModuleScript"))
		and not Object.Name:find(_L("Eyestalk")) and not Object.Name:find(_L("Groundskeeper")) and not Object.Name:find(_L("Monument"))
	then
		Object:SetAttribute(_L("OriginalName"), Object.Name)
		if Toggles.DisableEntityJumpscares.Value then Object.Name = Object.Name .. _L("_Disabled") end
		table.insert(Objects.JumpscareModules, Object)
	end
end)

if FloorReplicated:FindFirstChild(_L("DigitalTimer")) then
	Connections.HasteTimerConnection = FloorReplicated.DigitalTimer:GetPropertyChangedSignal(_L("Value")):Connect(function()
		if Toggles.NotifyHasteTime.Value then Functions.Caption(Functions.GetHasteTime(), true) end
	end)
end

Connections.FogHandler = Services.Lighting:GetPropertyChangedSignal(_L("FogEnd")):Connect(function()
	if Services.Lighting.FogEnd ~= 10000000 then
		Globals.OldFog = Services.Lighting.FogEnd
	end
	if Toggles.RemoveCameraFog.Value then
		Services.Lighting.FogEnd = 10000000
	end
end)

Connections.FogHandler2 = Services.Lighting.DescendantAdded:Connect(function(Object)
	if not Object:IsA(_L("Atmosphere")) then return end
	Object:SetAttribute(_L("Density_Old"), Object.Density)
	if Toggles.RemoveCameraFog.Value then Object.Density = 0 end

	local AtmoConn2 = Object:GetPropertyChangedSignal(_L("Density")):Connect(function()
		if Object.Density ~= 0 then Object:SetAttribute(_L("Density_Old"), Object.Density) end
		if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
	end)
	Object.Destroying:Once(function() AtmoConn2:Disconnect() end)
	table.insert(Connections, AtmoConn2)
	table.insert(Globals.FogInstances, Object)
end)

local RusherAliases = { Rush=true, Bash=true, Scribbles=true, DronesStampede=true, Ambush=true, Eyes=true, Lookman=true, Blitz=true, [_L("A-60")]=true, [_L("A-120")]=true, AR0xMBUSH=true, [_L("RNIUSHCG==")]=true, [_L("Custom Entity")]=true }

local function HandleEntitySpawn(Entity)
	if not Entity or typeof(Entity) ~= _L("Instance") then return end

	local Model = Entity
	if Entity:IsA(_L("Humanoid")) then
		Model = Entity.Parent
	end
	if not Model or not Model:IsA(_L("Model")) then return end

	local EntityData = Entities[Model.Name]
	if not EntityData then return end
	if Model:GetAttribute(_L("Abysall_EntityHandled")) then return end
	Model:SetAttribute(_L("Abysall_EntityHandled"), true)

	while not Model.PrimaryPart do
		for _, Child in Model:GetChildren() do
			if Child:IsA(_L("BasePart")) then Model.PrimaryPart = Child end
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

		if Model.Name == _L("RushMoving") and Model.PrimaryPart.Name ~= _L("RushNew") then
			NotifyTitle = NotifyTitle:gsub(_L("Rush"), Model.PrimaryPart.Name)
			NotifyImage = Model.PrimaryPart:WaitForChild(_L("Attachment")).ParticleEmitter.Texture
			Alias = Model.PrimaryPart.Name
		end

		Functions.Notify({ Title = NotifyTitle, Body = NotifyBody, Image = NotifyImage, Time = Toggles.NotifyKeepNotifications.Value and Model or nil })

		if Toggles.EntityChatToggle.Value then
			Functions.SendChat(Alias .. _L(" ") .. Options.EntityChatMessage.Value)
		end
	end

	if Model.Name ~= _L("GloombatSwarm") then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealAlias] then
			if Model.Name == _L("MonumentEntity") then
				Functions.AddESP({ Object = Model.Top, Text = Alias, Color = Options.EntityESPColor.Value })
			else
				Functions.AddESP({ Object = Model, Text = Alias, Color = Options.EntityESPColor.Value })
			end
		end
		table.insert(Objects.Entities, Model)
	end

	if RusherAliases[EntityData.Alias] then
		Instance.new(_L("Humanoid"), Model).Name = _L("HighlightHumanoid")
		local Root = Model.PrimaryPart
		if Root then Root.Transparency = 0.999 Root.Material = Enum.Material.Plastic end
	end

	if Model.Name == _L("Lookman") then
		CurrentRooms.ChildAdded:Wait()
		task.wait(10)
		Model:Destroy()
	end
end

Connections.EntityHandler = Services.Workspace.ChildAdded:Connect(HandleEntitySpawn)
Connections.EntityDescendantHandler = Services.Workspace.DescendantAdded:Connect(function(Descendant)
	local EntityModel = Descendant:IsA(_L("Humanoid")) and Descendant.Parent or Descendant
	if EntityModel and EntityModel:IsA(_L("Model")) and Entities[EntityModel.Name] then
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
		if Prompt:HasTag(_L("DisableWhenEnabledOnClient")) then
			Prompt:RemoveTag(_L("DisableWhenEnabledOnClient"))
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
		if type(Key) == _L("string") then
			pcall(function() Connection:Disconnect() end)
		else
			pcall(function() Key:Disconnect() end)
			pcall(function() Connection:Disconnect() end)
		end
	end

	for _, Object in Objects.Entities do
		if Object.Name == _L("Snare") or Object.Name == _L("GiggleCeiling") then
			local Hitbox = Object:FindFirstChild(_L("Hitbox"))
			if Hitbox then Hitbox.CanTouch = true end
		end
		if Object.Name == _L("GloomPile") then
			for _, Part in Object:GetDescendants() do
				if Part:IsA(_L("BasePart")) then Part.CanTouch = true end
			end
		end
		if Object.Name == _L("FakeDoor") or Object.Name == _L("DoorFake") then
			local Hidden = Object:FindFirstChild(_L("Hidden"))
			if Hidden then Hidden.CanTouch = true end
			local Lock = Object:FindFirstChild(_L("Lock"))
			if Lock and Lock:FindFirstChild(_L("UnlockPrompt")) then Lock.UnlockPrompt.Enabled = true end
		end
		if Object.Name == _L("SideroomSpace") then
			local Coll = Object:FindFirstChild(_L("Collision"))
			if Coll then Coll.CanCollide = false Coll.CanTouch = true end
		end
	end

	for _, Object in Objects.SeekBridges do Object:Destroy() end

	for _, Fog in Globals.FogInstances do
		Fog.Density = Fog:GetAttribute(_L("Density_Old"))
	end
	Services.Lighting.FogEnd = Globals.OldFog

	local Vignette = Globals.MainUI:FindFirstChild(_L("HideVignette")) or Globals.MainUI.MainFrame:FindFirstChild(_L("HideVignette"))
	if Vignette then Vignette.Image = _L("rbxassetid://6100076320") end

	local ModuleRestores = {
		Screech = _L("Screech"), Glitch = _L("Glitch"), Shade = _L("Shade"),
		SpiderJumpscare = _L("SpiderJumpscare"), A90 = _L("A90"), Dread = _L("Dread"), Void = _L("Void")
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

	local OldAmbient = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute(_L("CurrentRoom")))):GetAttribute(_L("Ambient"))
	Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = OldAmbient }):Play()

	for _, Prompt in Objects.Prompts do
		if FakePrompts[Prompt] then
			FakePrompts[Prompt].Parent = Prompt.Parent
			Prompt:Destroy()
		end
		if Prompt.Parent then
			Prompt.HoldDuration = Prompt:GetAttribute(_L("HoldDuration_Old")) or Prompt.HoldDuration
			Prompt.RequiresLineOfSight = Prompt:GetAttribute(_L("RequiresLineOfSight_Old")) or Prompt.RequiresLineOfSight
			Prompt.MaxActivationDistance = Prompt:GetAttribute(_L("MaxActivationDistance_Old")) or Prompt.MaxActivationDistance
		end
	end

	Character:SetAttribute(_L("CanJump"),  OldJump)
	Character:SetAttribute(_L("CanSlide"), OldSlide)

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

	if Character:FindFirstChild(_L("LowerTorso")) and Character.LowerTorso:FindFirstChild(_L("Root")) then
		Character.LowerTorso.Root.C1 = Globals.OriginalC1
	end
	if Collision:FindFirstChild(_L("CollisionCrouch")) then
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
Functions.Notify({ Title = _L("Successfully loaded in ") .. math.floor((tick() - LoadStart) * 1000) / 1000 .. _L(" seconds.") , Body = _L("Press '") .. tostring(Options.MenuKeybind.Value) .. _L("' to toggle the UI.")})

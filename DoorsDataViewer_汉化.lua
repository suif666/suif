mspaint.AddonInfo = {
    Name = "DoorsDataViewer",
    Title = "Doors 数据查看器",
    Game = {6516141723,6839171747,12308344607}
}

local addonName = mspaint.AddonInfo.Name
local addonTitle = mspaint.AddonInfo.Title

if getgenv()._DOORS_DV_VALUES then
	getgenv()._DOORS_DV_VALUES.Reload.Value = true
	if getgenv()._DOORS_DV_VALUES.Loaded.Value then
		getgenv()._DOORS_DV_VALUES.Loaded:GetPropertyChangedSignal("Value"):Wait()
	end
end

cloneref = cloneref or function(...) return ... end
Services = setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		else
			error("无效服务：" .. tostring(name))
		end
	end
})

local function genName()
	local str = ""
	for _ = 1,64 do
		str ..= string.char(math.random(33,126))
	end
	return str
end

local ReloadSignals
if debug.setinfo then
	if getgenv()._DOORS_DV_VALUES then
		for _, bool in getgenv()._DOORS_DV_VALUES do
			bool:Destroy()
		end
		getgenv()._DOORS_DV_VALUES = nil
	end
	getgenv()._DOORS_DV_VALUES = {
		Loaded = Instance.new("BoolValue"),
		Reload = Instance.new("BoolValue")
	}
	getgenv()._DOORS_DV_VALUES.Loaded.Value = true
	ReloadSignals = {}
end

local function destroyUnloadSignal(name)
	for index, func in Library.UnloadSignals do
		if debug.getinfo(func).name == name then
			table.remove(Library.UnloadSignals, index)
			break
		end
	end
end

local reloadConnection; reloadConnection = getgenv()._DOORS_DV_VALUES and getgenv()._DOORS_DV_VALUES.Reload:GetPropertyChangedSignal("Value"):Connect(function()
	if getgenv()._DOORS_DV_VALUES.Reload.Value then
		reloadConnection:Disconnect()
		for name, reloadFunc in ReloadSignals do
			destroyUnloadSignal(name)
			local success, err = pcall(reloadFunc, true)
			if not success then
				Library:Notify({
					Title = 'wow something went wrong while reloading',
					Description = err,
					Time = 10
				})
			end
		end
		ReloadSignals = nil
		task.wait(.1)
		getgenv()._DOORS_DV_VALUES.Loaded.Value = false
	end
end)

Library:OnUnload(function()
	if ReloadSignals then
		ReloadSignals = nil
	else
		return -- the addon was reloaded, don't try to unload using this function
	end
	if getgenv()._DOORS_DV_VALUES then
		for _, bool in getgenv()._DOORS_DV_VALUES do
			bool:Destroy()
		end
		getgenv()._DOORS_DV_VALUES = nil
	end
	if getgenv()._DOORS_DV_CONFIG then
		getgenv()._DOORS_DV_CONFIG = nil
	end
end)

local function OnUnload(func: (WasReloaded: boolean?) -> ()): ()
	if debug.setinfo then
		local funcName = genName()
		debug.setinfo(func, {name = funcName})
		Library:OnUnload(func)
		ReloadSignals[funcName] = func
	else
		Library:OnUnload(func)
	end
end

local TextChatService = Services.TextChatService
local UserService = Services.UserService
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local HttpService = Services.HttpService
local isLobby = game.PlaceId == 6516141723

-- 100% skidded (i forgot who made this)
local SpecialCharacters = {['\a'] = '\\a', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\v'] = '\\v', ['\0'] = '\\0'}
local Keywords = { ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true, ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true, ['until'] = true, ['while'] = true, ['continue'] = true}
local Functions = {[DockWidgetPluginGuiInfo.new] = "DockWidgetPluginGuiInfo.new"; [warn] = "warn"; [CFrame.fromMatrix] = "CFrame.fromMatrix"; [CFrame.fromAxisAngle] = "CFrame.fromAxisAngle"; [CFrame.fromOrientation] = "CFrame.fromOrientation"; [CFrame.fromEulerAnglesXYZ] = "CFrame.fromEulerAnglesXYZ"; [CFrame.Angles] = "CFrame.Angles"; [CFrame.fromEulerAnglesYXZ] = "CFrame.fromEulerAnglesYXZ"; [CFrame.new] = "CFrame.new"; [gcinfo] = "gcinfo"; [os.clock] = "os.clock"; [os.difftime] = "os.difftime"; [os.time] = "os.time"; [os.date] = "os.date"; [tick] = "tick"; [bit32.band] = "bit32.band"; [bit32.extract] = "bit32.extract"; [bit32.bor] = "bit32.bor"; [bit32.bnot] = "bit32.bnot"; [bit32.arshift] = "bit32.arshift"; [bit32.rshift] = "bit32.rshift"; [bit32.rrotate] = "bit32.rrotate"; [bit32.replace] = "bit32.replace"; [bit32.lshift] = "bit32.lshift"; [bit32.lrotate] = "bit32.lrotate"; [bit32.btest] = "bit32.btest"; [bit32.bxor] = "bit32.bxor"; [pairs] = "pairs"; [NumberSequence.new] = "NumberSequence.new"; [assert] = "assert"; [tonumber] = "tonumber"; [Color3.fromHSV] = "Color3.fromHSV"; [Color3.toHSV] = "Color3.toHSV"; [Color3.fromRGB] = "Color3.fromRGB"; [Color3.new] = "Color3.new"; [Delay] = "Delay"; [Stats] = "Stats"; [UserSettings] = "UserSettings"; [coroutine.resume] = "coroutine.resume"; [coroutine.yield] = "coroutine.yield"; [coroutine.running] = "coroutine.running"; [coroutine.status] = "coroutine.status"; [coroutine.wrap] = "coroutine.wrap"; [coroutine.create] = "coroutine.create"; [coroutine.isyieldable] = "coroutine.isyieldable"; [NumberRange.new] = "NumberRange.new"; [PhysicalProperties.new] = "PhysicalProperties.new"; [PluginManager] = "PluginManager"; [Ray.new] = "Ray.new"; [NumberSequenceKeypoint.new] = "NumberSequenceKeypoint.new"; [Version] = "Version"; [Vector2.new] = "Vector2.new"; [Instance.new] = "Instance.new"; [delay] = "delay"; [spawn] = "spawn"; [unpack] = "unpack"; [string.split] = "string.split"; [string.match] = "string.match"; [string.gmatch] = "string.gmatch"; [string.upper] = "string.upper"; [string.gsub] = "string.gsub"; [string.format] = "string.format"; [string.lower] = "string.lower"; [string.sub] = "string.sub"; [string.pack] = "string.pack"; [string.rep] = "string.rep"; [string.char] = "string.char"; [string.packsize] = "string.packsize"; [string.reverse] = "string.reverse"; [string.byte] = "string.byte"; [string.unpack] = "string.unpack"; [string.len] = "string.len"; [string.find] = "string.find"; [CellId.new] = "CellId.new"; [ypcall] = "ypcall"; [version] = "version"; [print] = "print"; [stats] = "stats"; [printidentity] = "printidentity"; [settings] = "settings"; [UDim2.fromOffset] = "UDim2.fromOffset"; [UDim2.fromScale] = "UDim2.fromScale"; [UDim2.new] = "UDim2.new"; [table.pack] = "table.pack"; [table.move] = "table.move"; [table.insert] = "table.insert"; [table.getn] = "table.getn"; [table.foreachi] = "table.foreachi"; [table.maxn] = "table.maxn"; [table.foreach] = "table.foreach"; [table.concat] = "table.concat"; [table.unpack] = "table.unpack"; [table.find] = "table.find"; [table.create] = "table.create"; [table.sort] = "table.sort"; [table.remove] = "table.remove"; [TweenInfo.new] = "TweenInfo.new"; [loadstring] = "loadstring"; [require] = "require"; [Vector3.FromNormalId] = "Vector3.FromNormalId"; [Vector3.FromAxis] = "Vector3.FromAxis"; [Vector3.fromAxis] = "Vector3.fromAxis"; [Vector3.fromNormalId] = "Vector3.fromNormalId"; [Vector3.new] = "Vector3.new"; [Vector3int16.new] = "Vector3int16.new"; [setmetatable] = "setmetatable"; [next] = "next"; [Wait] = "Wait"; [wait] = "wait"; [ipairs] = "ipairs"; [elapsedTime] = "elapsedTime"; [time] = "time"; [rawequal] = "rawequal"; [Vector2int16.new] = "Vector2int16.new"; [collectgarbage] = "collectgarbage"; [newproxy] = "newproxy"; [Spawn] = "Spawn"; [PluginDrag.new] = "PluginDrag.new"; [Region3.new] = "Region3.new"; [utf8.offset] = "utf8.offset"; [utf8.codepoint] = "utf8.codepoint"; [utf8.nfdnormalize] = "utf8.nfdnormalize"; [utf8.char] = "utf8.char"; [utf8.codes] = "utf8.codes"; [utf8.len] = "utf8.len"; [utf8.graphemes] = "utf8.graphemes"; [utf8.nfcnormalize] = "utf8.nfcnormalize"; [xpcall] = "xpcall"; [tostring] = "tostring"; [rawset] = "rawset"; [PathWaypoint.new] = "PathWaypoint.new"; [DateTime.fromUnixTimestamp] = "DateTime.fromUnixTimestamp"; [DateTime.now] = "DateTime.now"; [DateTime.fromIsoDate] = "DateTime.fromIsoDate"; [DateTime.fromUnixTimestampMillis] = "DateTime.fromUnixTimestampMillis"; [DateTime.fromLocalTime] = "DateTime.fromLocalTime"; [DateTime.fromUniversalTime] = "DateTime.fromUniversalTime"; [Random.new] = "Random.new"; [typeof] = "typeof"; [RaycastParams.new] = "RaycastParams.new"; [math.log] = "math.log"; [math.ldexp] = "math.ldexp"; [math.rad] = "math.rad"; [math.cosh] = "math.cosh"; [math.random] = "math.random"; [math.frexp] = "math.frexp"; [math.tanh] = "math.tanh"; [math.floor] = "math.floor"; [math.max] = "math.max"; [math.sqrt] = "math.sqrt"; [math.modf] = "math.modf"; [math.pow] = "math.pow"; [math.atan] = "math.atan"; [math.tan] = "math.tan"; [math.cos] = "math.cos"; [math.sign] = "math.sign"; [math.clamp] = "math.clamp"; [math.log10] = "math.log10"; [math.noise] = "math.noise"; [math.acos] = "math.acos"; [math.abs] = "math.abs"; [math.sinh] = "math.sinh"; [math.asin] = "math.asin"; [math.min] = "math.min"; [math.deg] = "math.deg"; [math.fmod] = "math.fmod"; [math.randomseed] = "math.randomseed"; [math.atan2] = "math.atan2"; [math.ceil] = "math.ceil"; [math.sin] = "math.sin"; [math.exp] = "math.exp"; [getfenv] = "getfenv"; [pcall] = "pcall"; [ColorSequenceKeypoint.new] = "ColorSequenceKeypoint.new"; [ColorSequence.new] = "ColorSequence.new"; [type] = "type"; [Region3int16.new] = "Region3int16.new"; [ElapsedTime] = "ElapsedTime"; [select] = "select"; [getmetatable] = "getmetatable"; [rawget] = "rawget"; [Faces.new] = "Faces.new"; [Rect.new] = "Rect.new"; [BrickColor.Blue] = "BrickColor.Blue"; [BrickColor.White] = "BrickColor.White"; [BrickColor.Yellow] = "BrickColor.Yellow"; [BrickColor.Red] = "BrickColor.Red"; [BrickColor.Gray] = "BrickColor.Gray"; [BrickColor.palette] = "BrickColor.palette"; [BrickColor.New] = "BrickColor.New"; [BrickColor.Black] = "BrickColor.Black"; [BrickColor.Green] = "BrickColor.Green"; [BrickColor.Random] = "BrickColor.Random"; [BrickColor.DarkGray] = "BrickColor.DarkGray"; [BrickColor.random] = "BrickColor.random"; [BrickColor.new] = "BrickColor.new"; [setfenv] = "setfenv"; [UDim.new] = "UDim.new"; [Axes.new] = "Axes.new"; [error] = "error"; [debug.traceback] = "debug.traceback"; [debug.profileend] = "debug.profileend"; [debug.profilebegin] = "debug.profilebegin"}

function GetHierarchy(Object)
	local Hierarchy = {}

	local ChainLength = 1
	local Parent = Object
	
	while Parent do
		Parent = Parent.Parent
		ChainLength = ChainLength + 1
	end

	Parent = Object
	local Num = 0
	while Parent do
		Num = Num + 1

		local ObjName = string.gsub(Parent.Name, '[%c%z]', SpecialCharacters)
		ObjName = Parent == game and 'game' or ObjName

		if Keywords[ObjName] or not string.match(ObjName, '^[_%a][_%w]*$') then
			ObjName = '["' .. ObjName .. '"]'
		elseif Num ~= ChainLength - 1 then
			ObjName = '.' .. ObjName
		end

		Hierarchy[ChainLength - Num] = ObjName
		Parent = Parent.Parent
	end

	return table.concat(Hierarchy)
end
local function SerializeType(Value, Class)
	if Class == 'string' then
		-- Not using %q as it messes up the special characters fix
		return string.format('"%s"', string.gsub(Value, '[%c%z]', SpecialCharacters))
	elseif Class == 'Instance' then
		return GetHierarchy(Value)
	elseif type(Value) ~= Class then -- CFrame, Vector3, UDim2, ...
		return Class .. '.new(' .. tostring(Value) .. ')'
	elseif Class == 'function' then
		return Functions[Value] or '\'[Unknown ' .. (pcall(setfenv, Value, getfenv(Value)) and 'Lua' or 'C')  .. ' ' .. tostring(Value) .. ']\''
	elseif Class == 'userdata' then
		return 'newproxy(' .. tostring(not not getmetatable(Value)) .. ')'
	elseif Class == 'thread' then
		return '\'' .. tostring(Value) ..  ', status: ' .. coroutine.status(Value) .. '\''
	else -- thread, number, boolean, nil, ...
		return tostring(Value)
	end
end
local function TableToString(Table, IgnoredTables, DepthData, Path)
	IgnoredTables = IgnoredTables or {}
	local CyclicData = IgnoredTables[Table]
	if CyclicData then
		return ((CyclicData[1] == DepthData[1] - 1 and '\'[Cyclic Parent ' or '\'[Cyclic ') .. tostring(Table) .. ', path: ' .. CyclicData[2] .. ']\'')
	end

	Path = Path or 'ROOT'
	DepthData = DepthData or {0, Path}
	local Depth = DepthData[1] + 1
	DepthData[1] = Depth
	DepthData[2] = Path

	IgnoredTables[Table] = DepthData
	local Tab = string.rep('  ', Depth)
	local TrailingTab = string.rep('  ', Depth - 1)
	local Result = '{'

	local LineTab = '\n' .. Tab
	local HasOrder = true
	local Index = 1

	local IsEmpty = true
	for Key, Value in next, Table do
		IsEmpty = false
		if Index ~= Key then
			HasOrder = false
		else
			Index = Index + 1
		end

		local KeyClass, ValueClass = typeof(Key), typeof(Value)
		local HasBrackets = false
		if KeyClass == 'string' then
			Key = string.gsub(Key, '[%c%z]', SpecialCharacters)
			if Keywords[Key] or not string.match(Key, '^[_%a][_%w]*$') then
				HasBrackets = true
				Key = string.format('["%s"]', Key)
			end
		else
			HasBrackets = true
			Key = '[' .. (KeyClass == 'table' and string.gsub(TableToString(Key, IgnoredTables, {Depth + 1, Path}), '^%s*(.-)%s*$', '%1') or SerializeType(Key, KeyClass)) .. ']'
		end

		Value = ValueClass == 'table' and TableToString(Value, IgnoredTables, {Depth + 1, Path}, Path .. (HasBrackets and '' or '.') .. Key) or SerializeType(Value, ValueClass)
		Result = Result .. LineTab .. (HasOrder and Value or Key .. ' = ' .. Value) .. ','
	end

	return IsEmpty and Result .. '}' or string.sub(Result,  1, -2) .. '\n' .. TrailingTab .. '}'
end

require = require or function(...) return nil end
local localplayer = Players.LocalPlayer
local main = localplayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Lobby") or localplayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game")
local caption = require(main).caption
local gamedata = Services.TeleportService:GetLocalPlayerTeleportData()
local player = localplayer
local friendmodule, replicamodule, badgesmodule, rankmodule, plrdata, progress_all, secrets_all, badges_all, nameui_additions = require(ReplicatedStorage.ModulesClient.FriendCheck), require(ReplicatedStorage.ReplicaController), require(ReplicatedStorage.ModulesClient.AchievementInfo), require(ReplicatedStorage.RankInfo), nil, 0, 0, 0, false
local replicaremotes = {}
local rankedleaderboard = {}
local howmanyonline = 0
local connections = {}
local toggles = {}
local stufftoremove = {}
local viewport

badgesmodule = badgesmodule.GetAll()

if friendmodule then
    task.spawn(friendmodule.GetFriendsInServer)
end

for _, remote in ReplicatedStorage.ReplicaRemoteEvents:GetChildren() do
    replicaremotes[remote.Name:gsub("Replica_Replica", "")] = remote
end

--[[local s,e = pcall(function()
    for _,info in workspace.Lobby._BloxxerBoard.UI._BoardFrame:GetChildren() do
        if info:IsA("TextLabel") then
            rankedleaderboard[tonumber(info.Place.Text)] = {
                UserId = tonumber(info.Name),
                Points = info.Value.Text
            }
        end
    end
end)]]

local function on_off(bool)
    return bool and {"已开启","是"} or {"已关闭","否"}
end

local function admintype(number)
    return number == 0 and "玩家" or number == 1 and "管理员" or number == 2 and "房主" or number >= 3 and "Doors 开发者" or "未知"
end

local function getplayerreplica(player)
    for i,v in replicamodule._replicas do
        if v.Tags.Player == player then
            return v, i
        end
    end
    return nil, nil
end

local function getplayerbyreplicaid(replicaid)
    for i,v in replicamodule._replicas do
        if i == replicaid then
            return typeof(v.Tags) == "table" and v.Tags.Player
        end
    end
    return nil
end

local function nameui2replica(nameui)
    local plr = Players:FindFirstChild(string.gsub(nameui.Name, "NameUI", "", 1))
    if plr then
        local replica, id = getplayerreplica(plr)
        return {plr, replica, id}
    end
    return nil
end

local function refreshnameuis()
    if not isLobby then return end
    localplayer.PlayerScripts.LobbyPlayerUI.Enabled = false
    task.wait()
    for _,nameui in pairs(localplayer.PlayerGui:GetChildren()) do
        if string.find(nameui.Name, "NameUI") then
            nameui:Destroy()
        end
    end
    task.wait()
    localplayer.PlayerScripts.LobbyPlayerUI.Enabled = true
end

local function getplaceinrankedlb(player)
    for place, plr in rankedleaderboard or {} do
        if plr.UserId == player.UserId then
            return place
        end
    end
    return nil
end

local Groupbox = mspaint.Groupbox

if badgesmodule then
    for n, badge in badgesmodule do
        if badge.Secret then
            secrets_all += 1
        else
            progress_all += 1
            secrets_all += 1
        end
    end
end

if replicamodule and isLobby then
    Groupbox:AddDivider({
	    Text = "大厅",
	    MarginTop = 2,
	    MarginBottom = -2
    })

    Groupbox:AddButton("refresh", {
        Text = "刷新名牌",
        Func = function()
            task.spawn(refreshnameuis)
        end
    })

    toggles.nameui_additions = Groupbox:AddToggle("nameui_additions", {
        Text = "启用名牌增强",
        Default = nameui_additions,

        Callback = function(bool)
            nameui_additions = bool
            task.spawn(refreshnameuis)
        end
    })

    local lobbyelevators = workspace.Lobby.LobbyElevators
    local list = localplayer.PlayerGui.MainUI.LobbyFrame.OpenGames.List
    local elevators = {}
    local nameuievents = {}
    connections.NameUIAdded = localplayer.PlayerGui.ChildAdded:Connect(function(nameui)
        local replica = nameui2replica(nameui)
        local plr = replica[1]
        local username = nameui.Username.Username
        if username.Text == "[ 非真人 ]" then
            task.delay(1, function()
                username.Text = plr.DisplayName.." [ 非真人 ]"
                if plr and plr.Character then
                    plr.Character:WaitForChild("Humanoid", 30):ApplyDescriptionResetAsync()
                end
            end)
        end
        nameui.Stuff.Size = UDim2.new(1,0,0,0)
        local playerdata, id = replica[2] and replica[2].Data, replica[3]
        if playerdata and id then
            local Stuff = nameui.Stuff.Frame
            local progress, secrets = 0, 0
            for n, badge in badgesmodule do
                if table.find(playerdata.Achievements, n) then
                    if badge.Secret then
                        secrets += 1
                    else
                        progress += 1
                        secrets += 1
                    end
                end
            end

            Stuff.CompletionistCrazy.Visible = secrets >= secrets_all
            if Stuff.Completionist.Visible and Stuff.CompletionistCrazy.Visible then
                Stuff.Completionist.Visible = false
            end

            if not nameui_additions then return end
            Stuff:WaitForChild("TextEscapes")
            nameui.Size = UDim2.new(0,1200,0,100)

            Stuff.SeparatorStreak.LayoutOrder += 1
            Stuff.IconStreak.LayoutOrder += 1
            Stuff.TextStreak.LayoutOrder += 1

            local template = Instance.new("Frame")
            local layout = Stuff.UIListLayout:Clone()
            layout.Parent = template
            layout.Padding = UDim.new(0,8)
            template.Name = "Frame2" -- fix doors not showing badges
            template.BackgroundTransparency = 1
            template.AutomaticSize = "XY"
            local sep = Stuff.SeparatorEscapes:Clone()sep.Parent = template sep.Visible = true sep.Size = UDim2.new(0,1,1,0)sep.Name = "Separator"
            local icon = Stuff.IconEscapesHolder:Clone()icon.Parent = template icon.Visible = true icon.Size = UDim2.new(1,0,1,0)icon.Name = "IconHolder"
            local text = Stuff.TextEscapes:Clone()text.Parent = template text.Visible = true text.Size = UDim2.new(0,0,0,0)text.AutomaticSize = "XY"text.Name = "Text"
            Instance.new("UISizeConstraint", sep).MaxSize = Vector2.new(1/0,28)

            local NUStuff = nameui.Stuff
            local layout = Stuff.UIListLayout:Clone()layout.Parent = NUStuff layout.FillDirection = "Vertical"layout.Padding = UDim.new(0,0)
            local extraFrame = Stuff:Clone()
            extraFrame.Parent = NUStuff
            extraFrame.LayoutOrder = 1
            extraFrame.UIListLayout.Padding = UDim.new(0,8)

            nameui.UIListLayout.Padding = UDim.new(0,12)

            Stuff.Size = UDim2.fromScale(1,1)
            extraFrame.Size = UDim2.fromScale(1,.5)

            connections[nameui] = RunService.RenderStepped:Connect(function()
                NUStuff.Visible = NUStuff.Size.Y.Offset > 0
            end)
            
            for _, obj in extraFrame:GetChildren() do
                if obj:IsA("GuiObject") then
                    obj:Destroy()
                end
            end

            local datas = {}
            local lol = 0
            local function add_stat(name, iconsize, iconid, iconcolor, textcolor)
                local main = template:Clone()
                local data = {
                    ForceVisible = false,
                    MainFrame = main
                }
                local text = main.Text
                local sep = main.Separator
                local icon = main.IconHolder

                local function update()
                    local n = tonumber(text.Text)
                    main.Visible = n and n > 0
                    if data.ForceVisible then
                        main.Visible = true
                    end
                    local exclude = true
                    for _, data in datas do
                        if data.MainFrame and data.MainFrame:FindFirstChild("Separator") then
                            data.MainFrame.Separator.Visible = not exclude
                            if exclude and data.MainFrame.Visible then
                                exclude = false
                            end
                        end
                    end
                end

                function data:SetForceVisible(value)
                    self.ForceVisible = value
                    update()
                end

                main.LayoutOrder = lol
                lol += 1
                main.Name = name
                icon.Size = iconsize or icon.Size
                icon.ImageLabel.Image = iconid
                icon.ImageLabel.ImageColor3 = iconcolor
                text.TextColor3 = textcolor
                main.Parent = extraFrame

                text.Changed:Connect(update)
                update()

                setmetatable(data, {
                    __index = function(self, prop)
                        return text[prop]
                    end,
                    __newindex = function(self, prop, new)
                        text[prop] = new
                    end
                })

                table.insert(datas, data)
                return data
            end

            local isDDV = false
            for _, anim in plr.Character:WaitForChild("Humanoid", 1/0):GetPlayingAnimationTracks() do
                isDDV = anim.Speed == 1924 and (anim.WeightCurrent == 0 or anim.WeightTarget == 0) and anim.Animation.AnimationId == "rbxassetid://19004509699"
                if isDDV then
                    break
                end
            end

            local text1 = add_stat("Escapes", nil, "rbxassetid://10100630346", Color3.fromRGB(170,237,255), Color3.fromRGB(170,237,255))
            local text2 = add_stat("Doors", UDim2.fromScale(.8,.8), "rbxassetid://10099841910", Color3.fromRGB(170,170,170), Color3.fromRGB(241,241,241))
            local text3 = add_stat("Knobs", nil, "rbxassetid://16587915599", Color3.fromRGB(170,170,170), Color3.fromRGB(241,191,151))
            local text4 = add_stat("Revives", nil, "rbxassetid://16587986504", Color3.fromRGB(170,170,170), Color3.fromRGB(241,151,151))
            local text5 = add_stat("Stardust", nil, "rbxassetid://116078176383033", Color3.fromRGB(170,170,170), Color3.fromRGB(241,191,121))
            local text6 = add_stat("Boosts", nil, "rbxassetid://10448639430", Color3.fromRGB(255,222,189), Color3.fromRGB(241,191,121))
            local textddv = add_stat("DDVUser", nil, "rbxassetid://95816097006870", Color3.fromRGB(200,200,200), Color3.fromRGB(151,201,241))
            textddv.ForceVisible = isDDV
            textddv.Text = "已装 DDV"

            local function setText(textl, text, bool)
                if bool then
                    textl.Text = text
                end
            end

            local function render(arg)
                if not arg or arg == "Stats" or arg == "Knobs" or arg == "Revives" or arg == "Stardust" or arg == "Boosts" then
                    setText(text1, playerdata.Stats.Escape or 0, not arg or arg == "Stats")
                    setText(text2, playerdata.Stats.DoorsOpened or 0, not arg or arg == "Stats")
                    setText(text3, playerdata.Knobs or 0, not arg or arg == "Knobs")
                    setText(text4, playerdata.Revives or 0, not arg or arg == "Revives")
                    setText(text5, playerdata.Stardust or 0, not arg or arg == "Stardust")
                    setText(text6, playerdata.Boosts or 0, not arg or arg == "Boosts")
                end
            end

            connections["{plr.UserId}_LVYChanged"] = plr.Character:WaitForChild("Humanoid", 1/0).AnimationPlayed:Connect(function()
                local isDDV = false
                for _, anim in plr.Character:WaitForChild("Humanoid", 1/0):GetPlayingAnimationTracks() do
                    isDDV = anim.Speed == 1924 and (anim.WeightCurrent == 0 or anim.WeightTarget == 0) and anim.Animation.AnimationId == "rbxassetid://19004509699"
                    if isDDV then
                        break
                    end
                end
                textddv.ForceVisible = isDDV
            end)

            render()

            local event = Instance.new("BindableEvent")
            nameuievents[plr.UserId] = event
            connections[`{plr.UserId}_OnChange`] = event.Event:Connect(function(key, value)
                playerdata[key] = value
                render(key)
            end)

            connections[`{plr.UserId}_OnPlayerParentChanged`] = plr.AncestryChanged:Connect(function()
                nameui:Destroy()
            end)

            connections[`{plr.UserId}_NameUIDestroyed`] = nameui.AncestryChanged:Connect(function(parent)
                if parent then return end
                if nameuievents[plr.UserId] then
                    nameuievents[plr.UserId]:Destroy()
                    nameuievents[plr.UserId] = nil
                end
                if connections[nameui] then
                    connections[nameui]:Disconnect()
                    connections[nameui] = nil
                end
                if connections[`{plr.UserId}_OnChange`] then
                    connections[`{plr.UserId}_OnChange`]:Disconnect()
                    connections[`{plr.UserId}_OnChange`] = nil
                end
                if connections[`{plr.UserId}_OnPlayerParentChanged`] then
                    connections[`{plr.UserId}_OnPlayerParentChanged`]:Disconnect()
                    connections[`{plr.UserId}_OnPlayerParentChanged`] = nil
                end
                if connections["{plr.UserId}_LVYChanged"] then
                    connections["{plr.UserId}_LVYChanged"]:Disconnect()
                    connections["{plr.UserId}_LVYChanged"] = nil
                end
            end)
        end
    end)
    connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
        local name_ui = localplayer.PlayerGui:FindFirstChild("NameUI"..plr.Name)
        if name_ui then
            name_ui:Destroy()
        end
    end)
    connections.OnSetValue = replicaremotes.SetValue.OnClientEvent:Connect(function(replicaid, key, value)
        local player = getplayerbyreplicaid(replicaid)
        local nameuievent = player and nameuievents[player.UserId]
        if nameuievent then
            nameuievent:Fire(key[1], value)
        end
    end)
    connections.ElevatorAdded = lobbyelevators.ChildAdded:Connect(function(elevator)
        local friendsonly = false
        local solo = true
        if elevator:GetAttribute("FriendsOnly") then
            if not friendmodule.IsFriendsWith(Players:FindFirstChild(elevator:GetAttribute("Host")) and Players[elevator:GetAttribute("Host")].UserId or 1) then
                elevator:SetAttribute("FriendsOnly", false)
            end
            friendsonly = true
        end
        if elevator:GetAttribute("Max") > 1 then
            solo = false
        else
            elevator:SetAttribute("Max", 99)
            elevator:GetAttributeChangedSignal("Full"):Connect(function()
                elevator:SetAttribute("Full", false)
            end)
        end
        if elevator:FindFirstChild("Whitelist") then
            elevator.Whitelist.Name = "_Whitelist"
        end
        elevators[elevator.Name] = {
            Solo = solo,
            FriendsOnly = friendsonly
        }
        elevator:SetAttribute("Username", `{elevator:GetAttribute("Host")}, {elevator:GetAttribute("Destination")}, {elevator:GetAttribute("DestinationSpecific") and `{elevator:GetAttribute("DestinationSpecific")}, ` or ""}ID={elevator:GetAttribute("ID")}, {solo and "单人" or "上限="..elevator:GetAttribute("Max")}{elevator:GetAttribute("UsingSaveFile") and "，存档模式" or ""}{friendsonly and "，仅好友" or ""}`)
    end)
    connections.ElevatorRemoved = lobbyelevators.ChildRemoved:Connect(function(elevator)
        elevators[elevator.Name] = nil
    end)
    connections.ListSizeFix = RunService.Heartbeat:Connect(function()
        list.Size = UDim2.new(1.4, list.Size.X.Offset, list.Size.Y.Scale, list.Size.Y.Offset)
    end)
    connections.LiveTipDisabler = localplayer.PlayerGui.MainUI.LobbyFrame.ChildAdded:Connect(function(child)
        if child.Name == "LiveTip" then
            child.Visible = false
        end
    end)
    connections.ElevatorAddedList = list.ChildAdded:Connect(function(elevator)
        if elevator.Name:sub(1, 14) == "PlayerElevator" and elevators[elevator.Name] then
            if elevators[elevator.Name].Solo then
                elevator.MouseButton1Click:Connect(function()
                    caption("不能加入单人电梯！")
                end)
            elseif elevators[elevator.Name].FriendsOnly and not friendmodule.IsFriendsWith(Players:FindFirstChild(elevator.Name:split("-")[2]) and Players[elevator.Name:split("-")[2]].UserId or 1) then
                elevator.MouseButton1Click:Connect(function()
                    caption("这部电梯仅限好友！")
                end)
            end
        end
    end)
    task.spawn(refreshnameuis)
elseif not replicamodule and isLobby then
    Library:Notify({
        Title = "错误！",
        Description = "ReplicaController 未加载，玩家头顶的更多统计和电梯的详细信息都看不到",
        Time = 6
    })
end

local function clone(instance)
    local clonedinstance
    if not instance.Archivable then
        instance.Archivable = true
        clonedinstance = instance:Clone()
        instance.Archivable = false
    end
    clonedinstance = clonedinstance or instance:Clone()
    return clonedinstance
end

Groupbox:AddDivider({
	Text = "选择玩家",
	MarginTop = 2,
	MarginBottom = -2
})

Groupbox:AddDropdown("player", {
    SpecialType = "Player",
    ExcludeLocalPlayer = false,
    Searchable = true,
    Text = "玩家",
    Default = localplayer,
    Callback = function(value)
        pcall(function()
            player = value
            viewport:SetObject(clone(player.Character))
            viewport:Focus()
        end)
    end
})

viewport = Groupbox:AddViewport("playermodel", {
    Object = clone(localplayer.Character),
    Camera = Instance.new("Camera"),
    Interactive = true,
    AutoFocus = true,
    Height = 200
})

viewport:Focus()

Groupbox:AddDivider({
	Text = "数据查看器",
	MarginTop = 2,
	MarginBottom = -2
})

local function format_data(player, plrdata)
    local plrcodes = {}
    local plrugcs = {}
    for i,v in plrdata.Codes do
        if v:find("boughtugcitem") then
            local sigma = v:gsub("boughtugcitem", "")
            table.insert(plrugcs, tonumber(sigma))
        else
            table.insert(plrcodes, v)
        end
    end
    plrcodes = #plrcodes > 0 and plrcodes or {"没有已兑换的码"}
    plrugcs = #plrugcs > 0 and plrugcs or {"没有 UGC 物品"}
    local plrrank = {}
    if rankmodule then
        if player:GetAttribute("RankedRank") then
            plrrank.Rank = rankmodule.GetRankInfo(player:GetAttribute("RankedRank")).Name
        end
        if plrrank.Rank == "Bloxxer" then
            if player:GetAttribute("BloxxerRank") then
                plrrank.BloxxerRank = tostring(player:GetAttribute("BloxxerRank"))
            else
                plrrank.BloxxerRank = "100+"
            end
        end
    end
    local plrjoined = os.time() - plrdata.LastTimeJoined
    local hms = {
        year = math.floor(plrjoined/60^2/24/365),
        day = math.floor(plrjoined/60^2/24),
        hour = math.floor(plrjoined/60^2),
        minute = math.floor(plrjoined/60%60),
        second = plrjoined%60
    }
    plrjoined = nil
    for i,v in hms do
        if v > 0 then
            plrjoined = `{tostring(v)} {i}(s) ago`
            break
        end
    end
    local finalResult = ''
    local result = {
        {
            Name = "Knobs",
            Value = plrdata.Knobs
        },
        {
            Name = "Revives",
            Value = plrdata.Revives
        },
        {
            Name = "Stardust",
            Value = plrdata.Stardust
        },
        {
            Name = "Boosts",
            Value = plrdata.Boosts
        },
        {
            Name = "拾取金币",
            Value = plrdata.Stats.GoldPicked
        },
        {
            Name = "Runs",
            Value = plrdata.Stats.Runs
        },
        {
            Name = "开门数",
            Value = plrdata.Stats.DoorsOpened
        },
        {
            Name = "开锁数",
            Value = plrdata.Stats.LocksOpened
        },
        {
            Name = "Interactions",
            Value = plrdata.Stats.Interactions
        },
        {
            Name = "Deaths",
            Value = plrdata.Stats.Deaths
        },
        {
            Name = "旅馆死亡",
            Value = plrdata.Stats.Runs
        },
        {
            Name = "房间死亡",
            Value = plrdata.Stats.DeathRooms
        },
        {
            Name = "后门死亡",
            Value = plrdata.Stats.DeathBackdoor
        },
        {
            Name = "矿洞死亡",
            Value = plrdata.Stats.DeathMines
        },
        {
            Name = "户外死亡",
            Value = plrdata.Stats.DeathGarden
        },
        {
            Name = "档案室死亡",
            Value = plrdata.Stats.DeathArchives
        },
        {
            Name = "楼梯间死亡",
            Value = plrdata.Stats.DeathStairwell
        },
        {
            Name = "Escapes",
            Value = plrdata.Stats.Escape
        },
        {
            Name = "旅馆通关",
            Value = plrdata.Stats.Runs
        },
        {
            Name = "房间通关",
            Value = plrdata.Stats.EscapedRooms
        },
        {
            Name = "后门通关",
            Value = plrdata.Stats.EscapedBackdoor
        },
        {
            Name = "矿洞通关",
            Value = plrdata.Stats.EscapedMines
        },
        {
            Name = "户外通关",
            Value = plrdata.Stats.EscapedGarden
        },
        {
            Name = "档案室通关",
            Value = plrdata.Stats.EscapedArchives
        },
        {
            Name = "楼梯间通关",
            Value = plrdata.Stats.EscapedStairwell
        },
        {
            Name = "首次加入",
            Value = plrjoined or `{0} second(s) ago`
        },
        {
            Name = "裂缝物品",
            Value = plrdata.RiftItem.Exists and "无物品" or plrdata.RiftItem.Name
        },
        {
            Name = "星星裂缝物品",
            Value = plrdata.StarRiftItem.Exists and "无物品" or plrdata.StarRiftItem.Name
        },
        {
            Name = "排位段位",
            Value = plrrank.Rank
        },
        {
            Name = "Bloxxer 段位",
            Value = plrrank.BloxxerRank
        },
        {
            Name = "已兑换码",
            Value = table.concat(plrcodes, ", ")
        },
        {
            Name = "UGC 物品",
            Value = table.concat(plrugcs, ", ")
        },
        {
            Name = "赠送 Robux",
            Value = plrdata.Stats.GiftRobuxAmount
        },
        {
            Name = "捐赠 Robux",
            Value = plrdata.PaidInKnobs
        }
    }
    for _, info in result do
        if (typeof(info.Value) == "number" and info.Value <= 0) or not info.Value then continue end
        finalResult ..= `{info.Name}: {info.Value}\n`
    end
    return finalResult:sub(1,-2)
    --return `Knobs：{plrdata.Knobs}\n复活次数：{plrdata.Revives}\n星尘：{plrdata.Stardust}\n增益：{plrdata.Boosts}\n拾取金币：{plrdata.Stats.GoldPicked}\n局数：{(plrdata.Stats.Runs or 0)}\n开门数：{(plrdata.Stats.DoorsOpened or 0)}\n开锁数：{(plrdata.Stats.LocksOpened or 0)}\n交互数：{(plrdata.Stats.Interactions or 0)}\n死亡：{(plrdata.Stats.Deaths or 0)}\n旅馆死亡：{(plrdata.Stats.DeathHotel or 0)}\n后门死亡：{(plrdata.Stats.DeathBackdoor or 0)}\n矿洞死亡：{(plrdata.Stats.DeathMines or 0)}\n户外死亡：{(plrdata.Stats.DeathGarden or 0)}\n房间死亡：{(plrdata.Stats.DeathRooms or 0)}\n通关：{(plrdata.Stats.Escape or 0)}\n旅馆通关：{(plrdata.Stats.EscapedHotel or 0)}\n后门通关：{(plrdata.Stats.EscapedBackdoor or 0)}\n矿洞通关：{(plrdata.Stats.EscapedMines or 0)}\n户外通关：{(plrdata.Stats.EscapedGarden or 0)}\n房间通关：{(plrdata.Stats.EscapedRooms or 0)}\n首次加入：{(plrjoined or "0 second(s) ago")}\n裂缝物品：{(plrdata.RiftItem.Exists and "无物品" or plrdata.RiftItem.Name or "Doesn't exists")}\n星星裂缝物品：{(plrdata.StarRiftItem.Exists and "无物品" or plrdata.StarRiftItem.Name or "Doesn't exists")}\n排位段位：{plrrank.Rank}\nBloxxer 段位：{plrrank.BloxxerRank}\n已兑换码：{table.concat(plrcodes, ", ")}\nUGC 物品：{table.concat(plrugcs, ", ")}\n赠送 Robux：{plrdata.Stats.GiftRobuxAmount or 0}\n捐赠 Robux：{plrdata.PaidInKnobs}`
end

local function format_badges(plrdata)
    local plrbadges = {}
    local progress, secrets = 0, 0
    for n, badge in badgesmodule do
        if table.find(plrdata.Achievements, n) then
            if badge.Secret then
                secrets += 1
            else
                progress += 1
                secrets += 1
            end
            table.insert(plrbadges, badge.Title)
        end
    end
    return `进度：{progress}/{progress_all}\n秘密：{secrets}/{secrets_all}\n\n`..table.concat(plrbadges, ", ")
end

local function format_skins(plrdata)
    local itemskins = {}
    for name, _ in plrdata.ItemsEquipped do
        split = string.split(name, "_")
        table.insert(itemskins, `{split[2]}: {split[3]}`)
    end
    return table.concat(itemskins, "\n")
end

local function format_settings(plrdata)
    local settings = plrdata.Settings
    return `游戏音乐音量：{tostring(settings.VolumeMusic/100)}\n大厅音乐音量：{tostring(settings.VolumeMusicLobby/100)}\n灵敏度：{tostring(settings.Sensitivity/100)}\n切换蹲下：{on_off(settings.ToggleCrouch)[1]}\n减少动态效果：{on_off(settings.ReduceMotion)[1]}\n隐藏自身衣物：{on_off(settings.HideLayers)[1]}`
end

local function format_saves(plrdata)
    local saves = plrdata.Saves
    local saves_addon = nil
    local count = 1
    for _, save in saves do
        if not save.Used then return end
        save = save.TeleportData
        local save_addon = `[{count} Save]: {"{"}\n具体目的地：{save.DestinationSpecific}\n目的地：{save.Destination}\nYouTube 或 Twitch：{save.Settings.youtube ~= "" and save.Settings.youtube or save.Settings.twitch ~= "" and save.Settings.twitch or "未填写链接"}\n种子：{save.Settings.seed}\n玩家数：{#save.Players}\n房主：{save.Host or "无房主"}\n{"}"}`
        if not saves_addon then
            saves_addon = ""
        end
        saves_addon ..= saves_addon == "" and save_addon or "\n"..save_addon
    end
    return saves_addon
end

Groupbox:AddButton("getdata", {
    Text = "获取 ReplicaID",
    Tooltip = "ReplicaID 可配合 ReplicaRemoteEvents 在客户端改数据",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule then
            local replica = player and {getplayerreplica(player)}
            local replica, id = unpack(replica)
            if not (replica and id) then warn(replica, id) return end
            Library:Notify({
                Title = player.Name.." 的 ReplicaID：",
                Description = id,
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("getdata", {
    Text = "获取数据",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            Library:Notify({
                Title = player.Name.." 的数据：",
                Description = format_data(player, plrdata),
                Time = 6
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("savedata", {
    Text = "保存数据",
    DisabledTooltip = replicamodule and "执行器不支持" or "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not (replicamodule and makefolder and writefile),
    Func = function()
        if player and replicamodule then
            makefolder(addonName)
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            writefile(`{addonName}/{player.Name}_{player.UserId}_data_{tick()}.txt`, `-- 主要统计 --\n\n{format_data(player, plrdata)}\n\n-- 设置 --\n\n{format_settings(plrdata)}\n\n-- 已获成就 --\n\n{format_badges(plrdata)}\n\n-- 已装备皮肤 --\n\n{format_skins(plrdata)}\n\n-- 存档 --\n\n{format_saves(plrdata) or "没有找到存档"}\n\n（由 @tplaygd 的 {addonName} 保存）`)
            Library:Notify({
                Title = "保存数据",
                Description = player.Name.." 的数据已保存！",
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("saverawdata", {
    Text = "保存原始数据",
    DisabledTooltip = replicamodule and "执行器不支持" or "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not (replicamodule and makefolder and writefile),
    Func = function()
        if player and replicamodule then
            makefolder(addonName)
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            writefile(`{addonName}/{player.Name}_{player.UserId}_rawdata_{tick()}.txt`, `{TableToString(plrdata)}\n\n（由 @tplaygd 的 {addonName} 保存）`)
            Library:Notify({
                Title = "保存原始数据",
                Description = player.Name.." 的原始数据已保存！",
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

local function ReadFileUrl(url: string, name: string?, alwayscache: boolean?): string
    if makefolder then
        makefolder(`{addonName}/cache`)
    end
    local fileName = `{addonName}/cache/{name}` or `{addonName}/cache/TMP_{tick()}`
	local result = isfile and readfile and isfile(fileName) and readfile(fileName)
	if result and result:match("%S") and (alwayscache or tick()-tonumber(result:split("\n\n")[1]) < 604800) then
		local result = result:split("\n\n")
        table.remove(result, 1)
        return table.concat(result, "\n\n")
	else
		result = game:HttpGet(url)
		if result and writefile then
			writefile(fileName, `{math.floor(tick())}\n\n{result}`)
			if not name and delfile then
				delfile(fileName)
			end
		end
		return result
	end
    return nil
end

local TableViewer
local Finished = false
task.spawn(function()
    TableViewer = loadstring(ReadFileUrl("https://raw.githubusercontent.com/tplaygd/Tplays-Addon-Stuff/7810ac045e10406c6ff014db54d7573e273014be/TableViewer.lua", "TableViewer.lua", true) or "return nil")()
    Finished = true
end)

local opened
local openrawdata; openrawdata = Groupbox:AddButton("openrawdata", {
    Text = "打开原始数据",
    DisabledTooltip = replicamodule and "请稍等…" or "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not (replicamodule and TableViewer),
    Func = function()
        if opened then
            opened._ui.Parent:Destroy()
            opened = nil
            openrawdata:SetText("打开原始数据")
            return
        end
        if player and replicamodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            opened = TableViewer.new(plrdata, {
	            Title = `{player.Name} 的原始数据`,
            })
            openrawdata:SetText("关闭原始数据")
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

task.spawn(function()
    repeat task.wait() until Finished
    if TableViewer and replicamodule and openrawdata.Disabled then
        openrawdata:SetDisabled(false)
    end
end)

Groupbox:AddButton("savedata", {
    Text = "保存背包",
    DisabledTooltip = replicamodule and "执行器不支持" or "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not (replicamodule and makefolder and writefile),
    Func = function()
        if player and replicamodule then
            makefolder(addonName)
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            writefile(`{addonName}/{player.Name}_{player.UserId}_inv_{tick()}.txt`, `{TableToString(plrdata.Items)}\n\n（由 @tplaygd 的 {addonName} 保存）`)
            Library:Notify({
                Title = "保存背包",
                Description = player.Name.." 的背包已保存！",
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("getbadges", {
    Text = "获取成就",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule and badgesmodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            Library:Notify({
                Title = player.Name.." 的成就：",
                Description = format_badges(plrdata),
                Time = 6
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("geteis", {
    Text = "获取已装备皮肤",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule and badgesmodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            Library:Notify({
                Title = player.Name.." 的已装备皮肤：",
                Description = format_skins(plrdata),
                Time = 5
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("getsettings", {
    Text = "获取设置",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            Library:Notify({
                Title = player.Name.." 的设置：",
                Description = format_settings(plrdata),
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

Groupbox:AddButton("getsaves", {
    Text = "获取存档",
    DisabledTooltip = "ReplicaController 未加载（执行器可能不支持 require）",
    Disabled = not replicamodule,
    Func = function()
        if player and replicamodule then
            local replica = player and getplayerreplica(player)
            plrdata = replica and replica.Data
            if not plrdata then return end
            Library:Notify({
                Title = player.Name.." 的存档：",
                Description = format_saves(plrdata) or "没有找到存档",
                Time = 3
            })
        else
            Library:Notify({
                Title = "错误！",
                Description = "找不到玩家",
                Time = 3
            })
        end
    end
})

if game.PlaceId == 6839171747 then
    Groupbox:AddButton("getinfo", {
        Text = "获取玩家状态",
        Func = function()
            if player then
                Library:Notify({
                    Title = player.Name.." 的状态：",
                    Description = `蹲下：{on_off((player.Character:GetAttribute("Crouching") or false))[2]}\n加速：{tostring((player.Character:GetAttribute("Speedboost") or 0))}\n被眩晕：{on_off((player.Character:GetAttribute("Stunned") or false))[2]}\n水下：{on_off((player.Character:GetAttribute("Underwater") or false))[2]}\n氧气：{tostring((player.Character:GetAttribute("Oxygen") or 0))}\n挂机：{on_off((player:GetAttribute("AFK") or "Unknown"))[2]}\n存活：{on_off((player:GetAttribute("Alive") or "Unknown"))[2]}\n当前房间：{tostring((player:GetAttribute("CurrentRoom") or 0))}\n故障等级：{tostring((player:GetAttribute("GlitchLevel") or 0))}\n金币：{tostring((player.Gold.Value or 0))}\n管理员类型：{(admintype(player:GetAttribute("ServerAdmin")) or "NonAdmin")}`,
                    Time = 6
                })
            else
                Library:Notify({
                    Title = "错误！",
                    Description = "找不到玩家",
                    Time = 3
                })
            end
        end
    })
end

Groupbox:AddDivider({
	Text = "杂项",
	MarginTop = 2,
	MarginBottom = -2
})

if isLobby then
    Groupbox:AddButton("playersindoors", {
        Text = "局内玩家",
        Func = function()
            local final_output = ""
            local total = 0
            for _, iv in ReplicatedStorage.FloorPlayerCounts:GetChildren() do
                final_output ..= `{iv.Name}: {iv.Value}\n`
                total += iv.Value
            end

            Library:Notify({
                Title = `局内玩家：`,
                Description = `{final_output}\n总计：{total}`,
                Time = 5
            })
        end
    })

    local RBXSystem
    task.spawn(function()
        RBXSystem = TextChatService:WaitForChild("TextChannels", 5) and TextChatService.TextChannels:WaitForChild("RBXSystem", 5)
        RBXSystem = RBXSystem or TextChatService:FindFirstChildWhichIsA("TextChannel", true)
        if toggles.msgonjoin then
            toggles.msgonjoin:SetDisabled(false)
        end
    end)

    toggles.msgonjoin = Groupbox:AddToggle("msgonjoin", {
        Text = "进房时发消息",
        DisabledTooltip = "请稍等，插件正在查找文本频道…",
        Default = false,
        Disabled = not RBXSystem,
        Callback = function(bool)
            if bool then
                connections.ChatConnection = replicaremotes.Create.OnClientEvent:Connect(function(replicaid, data)
                    if typeof(data) == "table" and data[1] == "PlayerProfile" and typeof(data[2]) == "table" and typeof(data[2].Player) == "Instance" and data[2].Player:IsA("Player") and typeof(data[3]) == "table" then
                        local jplr = data[2].Player
                        local stats = data[3].Stats
                        RBXSystem:DisplaySystemMessage(`[📜]: {jplr.DisplayName}{jplr.DisplayName==jplr.Name and""or` (@{jplr.Name})`} 加入了服务器（死亡：{stats and stats.Deaths or 0}, 通关：{stats and stats.Escape or 0})`)
                    end
                end)
            else
                if connections.ChatConnection then
                    connections.ChatConnection:Disconnect()
                end
            end
        end
    })

    toggles.saverawdataonjoin = Groupbox:AddToggle("saverawdataonjoin", {
        Text = "进房时保存原始数据",
        DisabledTooltip = replicamodule and "执行器不支持" or "ReplicaController 未加载（执行器可能不支持 require）",
        Disabled = not (replicamodule and makefolder and writefile),
        Default = false,
        Callback = function(bool)
            if bool then
                connections.SaveRawDataConnection = replicaremotes.Create.OnClientEvent:Connect(function(replicaid, data)
                    if typeof(data) == "table" and data[1] == "PlayerProfile" and typeof(data[2]) == "table" and typeof(data[2].Player) == "Instance" and data[2].Player:IsA("Player") and typeof(data[3]) == "table" then
                        local jplr = data[2].Player
                        makefolder(`{addonName}/AutomaticallySavedRawDatas`)
                        writefile(`{addonName}/AutomaticallySavedRawDatas/{jplr.Name}_{jplr.UserId}.txt`, `{TableToString(data[3])}\n\n（由 @tplaygd 的 {addonName} 保存，时间戳：{tick()}）`)
                    end
                end)
            else
                if connections.SaveRawDataConnection then
                    connections.SaveRawDataConnection:Disconnect()
                end
            end
        end
    })
else
    Groupbox:AddButton("getgamedata", {
        Text = "获取游戏数据",
        Func = function()
            if gamedata then
                Library:Notify({
                    Title = "游戏数据：",
                    Description = `房主 UserId：{gamedata and gamedata.Host or "无房主"}\n房主用户名：{gamedata and gamedata.Host and Players:GetNameFromUserIdAsync(gamedata.Host) or "无房主"}\nToken：{gamedata and gamedata.Token or "找不到"}`,
                    Time = 5
                })
            else
                Library:Notify({
                    Title = "错误！",
                    Description = "获取游戏数据失败",
                    Time = 3
                })
            end
        end
    })
end

Groupbox:AddDivider({
	Text = "排位",
	MarginTop = 2,
	MarginBottom = -2
})

local formattedRankedLB = {}

local place = Groupbox:AddSlider("rlplace", {
    Text = "排位榜名次",
    Tooltip = "RL - 排位排行榜",
    Max = 100,
    Min = 1,
    Rounding = 0,
    Default = 1,
    DisabledTooltip = "正在加载排位榜信息…（可能要等一会）",
    Disabled = true
})

local button = Groupbox:AddButton("getrl", {
    Text = "从排位榜找玩家",
    Tooltip = "RL - 排位排行榜",
    DisabledTooltip = "正在加载排位榜信息…（可能要等一会）",
    Disabled = true,
    Func = function()
        Library:Notify({
            Title = tostring(place.Value).." 名次：",
            Description = `\n用户 ID：{tostring(formattedRankedLB[place.Value].Id)}\n用户名：{formattedRankedLB[place.Value].Username}\n显示名：{formattedRankedLB[place.Value].DisplayName}\n分数：{formattedRankedLB[place.Value].Points}`,
            Time = 5
        })
    end
})

local animtrack
if isLobby then
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://19004509699"
    animtrack = localplayer.Character:WaitForChild("Humanoid", 1/0):LoadAnimation(animation)
    while animtrack do
        if animtrack.Speed ~= 1924 then
            animtrack:AdjustSpeed(1924)
        end
        if animtrack.WeightCurrent ~= 0 or animtrack.WeightTarget ~= 0 then
            animtrack:AdjustWeight(0)
        end
        if animtrack.Priority ~= Enum.AnimationPriority.Core then
            animtrack.Priority = Enum.AnimationPriority.Core
        end
        if not animtrack.Looped then
            animtrack.Looped = true
        end
        if not animtrack.IsPlaying then
            animtrack:Play()
        end
        RunService.PreRender:Wait()
    end
end

task.spawn(function()
    rankedleaderboard = HttpService:JSONDecode(ReadFileUrl("https://raw.githubusercontent.com/tplaygd/Tplays-Addon-Stuff/refs/heads/main/RL.json", "RankedLeaderboard.json") or "{\"data\": []}").data
    if not rankedleaderboard or #rankedleaderboard < 1 then return end
    local userIds = {}
    for place, player in rankedleaderboard do
        userIds[place] = player.UserId
    end
    local success, userInfos
    while not success and not userInfos do
        success, userInfos = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, userIds)
        task.wait(5)
    end
    userInfos = success and userInfos or {}
    for place, player in rankedleaderboard do
        for index, plr in userInfos do
            if plr.Id == player.UserId then
                userInfos[index].Points = player.Points
                formattedRankedLB[place] = userInfos[index]
                table.remove(userInfos, index)
                break
            end
        end
    end
    place:SetDisabled(false)
    button:SetDisabled(false)
end)

OnUnload(function()
    if opened then
        pcall(openrawdata.Func)
    end
    if isLobby then
        ReplicatedStorage.RemotesFolder.MotorReplication:FireServer(0)
    end
    for _, toggle in toggles do
        if toggle.Value then
            pcall(toggle.Callback, false)
        end
    end
    for _, what in stufftoremove do
        if typeof(what) == "Instance" then
            pcall(game.Destroy, what)
        end
    end
    toggles = nil
    stufftoremove = nil
    local count = 0
    local success = 0
    for _, connection in connections do
        local s, _ = pcall(function()
            connection:Disconnect()
        end)
        success += s and 1 or 0
        count += 1
    end
    if animtrack then
        animtrack:Stop()
        animtrack:Destroy()
        animtrack = nil
    end
	task.spawn(refreshnameuis)
    print(`[{addonTitle:upper()}]: unloaded! (disconnected {success} connections out of {count})`)
end)
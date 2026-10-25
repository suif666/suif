local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local replicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
local collectionService = cloneref(game:GetService('CollectionService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local bt = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	bt = {
		Ambassador = require(replicatedFirst.Ambassador),
		BattleClient = getsenv(lplr.PlayerScripts.Battle.BattleClient),
		Enemy = require(replicatedFirst.Classes.Entities.Enemy),
		Network = require(replicatedFirst.Network),
		Shucky = require(replicatedFirst.Modules.Shucky),
		Variables = require(replicatedFirst.Variables)
	}

	vape:Clean(function()
		table.clear(bt)
	end)
end)

for _, v in {'AimAssist', 'Reach', 'SilentAim', 'TriggerBot', 'AntiFall', 'HitBoxes', 'Invisible', 'Jesus', 'Killaura', 'TargetStrafe', 'AntiRagdoll', 'Disabler', 'MurderMystery', 'Freecam', 'ChatSpammer', 'SpinBot'} do
	vape:Remove(v)
end

run(function()
	local AutoAction
	local Attack
	local Block
	local actions = {
		press = function(impact, atick)
			if impact and (bt.Variables.window or 0) > 0 then
				local diff = (impact - (bt.Variables.window * 0.3))
	
				if atick < impact and diff <= atick then
					bt.Ambassador.Fire('ButtonA', 'down')
					bt.Ambassador.Fire('ButtonA', 'up')
				end
			end
		end,
		hold = function(impact, atick)
			if bt.Variables.promptuheld then
				if atick <= (bt.Variables.promptuheld + bt.Variables.holdingtime) then
					local holdtick = (tick() + 0.01 - bt.Variables.atick - bt.Variables.promptuheld) % bt.Variables.loopfor / bt.Variables.loopfor
					if holdtick > 0.5 then
						holdtick = 1 - holdtick
					end
	
					holdtick = math.clamp(holdtick * 2, 0, 1)
					if holdtick > bt.Variables.greenmin + ((bt.Variables.greenmax - bt.Variables.greenmin) / 2) and holdtick < bt.Variables.greenmax then
						bt.Ambassador.Fire('ButtonA', 'up')
					end
				end
			else
				if bt.Variables.holdfrom <= atick and atick <= (bt.Variables.holdfrom + bt.Variables.holdtimeout) then
					bt.Ambassador.Fire('ButtonA', 'down')
				end
			end
		end,
		mash = function(impact, atick)
			if bt.Variables.filled and bt.Variables.filled[1] and (tick() - bt.Variables.filled[1]) > 0.5 then
				local gui = lplr.PlayerGui.HUD.Battle.DOITNOW3
				local checker = gui.Meter.checker
				local fillbar = gui.Meter.Fill
				local fillpos = fillbar.AbsoluteSize.X + fillbar.AbsolutePosition.X
	
				for _, v in checker:GetChildren() do
					if not v:GetAttribute('Skipped') then
						local checkpos = (v.AbsolutePosition.X - 6)
						if fillpos > checkpos + (v.AbsoluteSize.X / 2) and fillpos <= (checkpos + v.AbsoluteSize.X + 12) then
							bt.Ambassador.Fire('ButtonA', 'down')
							bt.Ambassador.Fire('ButtonA', 'up')
							break
						end
					end
				end
			end
		end
	}
	
	local function isMyTurn()
		if bt.Variables.myturn and bt.Variables.arena and bt.Variables.arena:GetAttribute('State') == 'Attacking' then
			if Attack.Enabled and bt.Variables.itsme then
				return true
			end
	
			if Block.Enabled and not bt.Variables.itsme then
				return true
			end
		end
	
		return false
	end
	
	AutoAction = vape.Categories.Combat:CreateModule({
		Name = '自动动作',
		Function = function(callback)
			if callback then
				repeat
					if isMyTurn() then
						local impact = bt.Variables.timehere or bt.Variables.impact
						local atick = tick() - (bt.Variables.atick or 0)
	
						if actions[bt.Variables.atktype] then
							actions[bt.Variables.atktype](impact, atick)
						end
					end
	
					task.wait()
				until not AutoAction.Enabled
			end
		end,
		Tooltip = '自动闪避所有来袭攻击以抵消伤害。'
	})
	Attack = AutoAction:CreateToggle({
		Name = '攻击',
		Default = true,
		Tooltip = '自动输入攻击招式。'
	})
	Block = AutoAction:CreateToggle({
		Name = '格挡',
		Default = true,
		Tooltip = '自动闪避来袭的攻击招式。'
	})
end)

run(function()
	local MissCooldown
	local index = game.PlaceId ~= 16483433878 and 20 or 53
	
	MissCooldown = vape.Categories.Combat:CreateModule({
		Name = '未命中冷却',
		Function = function(callback)
			if callback then
				debug.setconstant(bt.BattleClient.input, index, 0)
			else
				debug.setconstant(bt.BattleClient.input, index, 0.2)
			end
		end,
		Tooltip = '取消格挡或动作失误后的冷却。'
	})
end)

run(function()
	local AntiHazard
	local old
	
	AntiHazard = vape.Categories.Blatant:CreateModule({
		Name = '防环境伤害',
		Function = function(callback)
			if callback then
				old = hookfunction(bt.Network.FireServer, function(...)
					local event = ...
					if event == 'TakeDamage' then
						return
					end
	
					return old(...)
				end)
			else
				if old then
					hookfunction(bt.Network.FireServer, old)
					old = nil
				end
			end
		end,
		Tooltip = '让你在地面区域不受伤害。'
	})
end)

local Fly
local LongJump
run(function()
	local UpKey
	local DownKey
	local Value
	local VerticalValue
	local up, down = 0, 0

	Fly = vape.Categories.Blatant:CreateModule({
		Name = '飞行',
		Function = function(callback)
			if callback then
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing or bt.Variables.transitioning then return end

						local movevec = entitylib.character.Humanoid.MoveDirection * Value.Value
                    	root.AssemblyLinearVelocity = Vector3.new(movevec.X, 1 + ((up + down) * VerticalValue.Value), movevec.Z)
					end
				end))

				up, down = 0, 0
				Fly:Clean(UpKey.Triggered:Connect(function(isDown)
					up = isDown and 1 or 0
				end))

				Fly:Clean(DownKey.Triggered:Connect(function(isDown)
					down = isDown and -1 or 0
				end))

				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			end
		end,
		ExtraText = function()
			return 'Velocity'
		end,
		Tooltip = '让你飞速移动。'
	})
	UpKey = Fly:CreateBind({
		Name = 'Up Key',
		Default = {'Space'},
		Hold = true,
		Tooltip = '向上飞行的按键'
	})
	DownKey = Fly:CreateBind({
		Name = 'Down Key',
		Default = {'LeftControl'},
		Hold = true,
		Tooltip = '向下飞行的按键'
	})
	Value = Fly:CreateSlider({
		Name = '速度',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = '垂直速度',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local FlyingAttack
	
	FlyingAttack = vape.Categories.Blatant:CreateModule({
		Name = '飞行攻击',
		Function = function(callback)
			if callback then
				debug.setconstant(bt.Shucky.PossibleFirst, 7, '_Flying')
			else
				debug.setconstant(bt.Shucky.PossibleFirst, 7, 'Flying')
			end
		end,
		Tooltip = '允许用地面攻击打到飞行敌人。'
	})
end)

run(function()
	local Value
	local AutoDisable
	
	LongJump = vape.Categories.Blatant:CreateModule({
		Name = '远跳',
		Function = function(callback)
			if callback then
				local exempt = tick() + 0.1
				LongJump:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive then
						if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							if exempt < tick() and AutoDisable.Enabled then
								if LongJump.Enabled then
									LongJump:Toggle()
								end
							else
								entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end
	
						local root = entitylib.character.RootPart
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing or bt.Variables.transitioning then return end
	
						local movevec = entitylib.character.Humanoid.MoveDirection * Value.Value
	                    root.AssemblyLinearVelocity = Vector3.new(movevec.X, root.AssemblyLinearVelocity.Y, movevec.Z)
					end
				end))
			end
		end,
		ExtraText = function()
			return 'Velocity'
		end,
		Tooltip = '允许跳得更远'
	})
	Value = LongJump:CreateSlider({
		Name = '速度',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AutoDisable = LongJump:CreateToggle({
		Name = '自动禁用',
		Default = true
	})
end)

run(function()
	local PickupTP
	
	PickupTP = vape.Categories.Blatant:CreateModule({
		Name = '拾取传送',
		Function = function(callback)
			if callback then
				local old
				repeat
					if entitylib.isAlive then
						local success = true
						for _, v in collectionService:GetTagged('Pickup') do
							if not v:GetAttribute('Inactive') then
								if not old then
									old = entitylib.character.RootPart.CFrame
								end
	
								success = false
								entitylib.character.RootPart.CFrame = v.CFrame
								break
							end
						end
	
						if success and old then
							entitylib.character.RootPart.CFrame = old
							old = nil
						end
					else
						old = nil
					end
	
					task.wait(0.4)
				until not PickupTP.Enabled
			end
		end,
		Tooltip = '传送到附近任意可拾取物。'
	})
end)

run(function()
	local Speed
	local Value
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = '速度',
		Function = function(callback)
			if callback then
				Speed:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not Fly.Enabled and not LongJump.Enabled then
						local root = entitylib.character.RootPart
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing or bt.Variables.transitioning then return end
	
						local movevec = entitylib.character.Humanoid.MoveDirection * Value.Value
						root.AssemblyLinearVelocity = Vector3.new(movevec.X, root.AssemblyLinearVelocity.Y, movevec.Z)
					end
				end))
			end
		end,
		ExtraText = function()
			return 'Velocity'
		end,
		Tooltip = '用多种方式提升移动能力。'
	})
	Value = Speed:CreateSlider({
		Name = '速度',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local SpeedSpin
	local Value
	local old
	
	SpeedSpin = vape.Categories.Blatant:CreateModule({
		Name = '高速旋转',
		Function = function(callback)
			if callback then
				old = hookfunction(bt.Shucky.HasBadge, function(...)
					local self, badge = ...
					if badge == 'Speed Spin' then
						return Value.Value
					end
	
					return old(...)
				end)
			else
				if old then
					hookfunction(bt.Shucky.HasBadge, old)
					old = nil
				end
			end
		end,
		Tooltip = '伪造你持有的速度旋转卡数量。'
	})
	Value = SpeedSpin:CreateSlider({
		Name = '卡片数量',
		Min = 0,
		Max = 10,
		Default = 4
	})
end)

run(function()
	local PickupTracers
	local Color
	local Transparency
	local Bux
	local Reference = {}
	
	local function Added(ent)
		if vape.ThreadFix then
			setthreadidentity(8)
		end
	
		if Bux.Enabled and ent.Name ~= 'BUX' then
			return
		end
	
		local EntityTracer = Drawing.new('Line')
		EntityTracer.Thickness = 1
		EntityTracer.Transparency = 1 - Transparency.Value
		EntityTracer.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		Reference[ent] = EntityTracer
	end
	
	local function Removed(ent)
		local v = Reference[ent]
		if v then
			if vape.ThreadFix then
				setthreadidentity(8)
			end
	
			Reference[ent] = nil
			pcall(function()
				v.Visible = false
				v:Remove()
			end)
		end
	end
	
	local function ColorFunc(hue, sat, val)
		local tracerColor = Color3.fromHSV(hue, sat, val)
		for ent, EntityTracer in Reference do
			EntityTracer.Color = tracerColor
		end
	end
	
	local function Loop()
		local screenSize = vape.gui.AbsoluteSize
		local startVector = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
	
		for ent, EntityTracer in Reference do
			if ent:GetAttribute('Inactive') then
				EntityTracer.Visible = false
				continue
			end
	
			local pos = ent.Position
			local rootPos, rootVis = gameCamera:WorldToViewportPoint(pos)
	
			if not rootVis then
				local tempPos = gameCamera.CFrame:PointToObjectSpace(pos)
				tempPos = CFrame.Angles(0, 0, (math.atan2(tempPos.Y, tempPos.X) + math.pi)):VectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):VectorToWorldSpace(Vector3.new(0, 0, -1))))
				rootPos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(tempPos))
				rootVis = true
			end
	
			local endVector = Vector2.new(rootPos.X, rootPos.Y)
			EntityTracer.Visible = rootVis
			EntityTracer.From = startVector
			EntityTracer.To = endVector
		end
	end
	
	PickupTracers = vape.Categories.Render:CreateModule({
		Name = '拾取追踪线',
		Function = function(callback)
			if callback then
				PickupTracers:Clean(collectionService:GetInstanceAddedSignal('Pickup'):Connect(function(ent)
					if Reference[ent] then
						Removed(ent)
					end
					Added(ent)
				end))
				PickupTracers:Clean(collectionService:GetInstanceRemovedSignal('Pickup'):Connect(Removed))
				for _, v in collectionService:GetTagged('Pickup') do
					if Reference[v] then
						Removed(v)
					end
					Added(v)
				end
				PickupTracers:Clean(runService.RenderStepped:Connect(Loop))
			else
				for i in Reference do
					Removed(i)
				end
			end
		end,
		Tooltip = '在拾取物上绘制追踪线。'
	})
	Color = PickupTracers:CreateColorSlider({
		Name = 'BUX颜色',
		Function = function(hue, sat, val)
			if PickupTracers.Enabled then
				ColorFunc(hue, sat, val)
			end
		end
	})
	Transparency = PickupTracers:CreateSlider({
		Name = '透明度',
		Min = 0,
		Max = 1,
		Function = function(val)
			for _, tracer in Reference do
				tracer.Transparency = 1 - val
			end
		end,
		Decimal = 10
	})
	Bux = PickupTracers:CreateToggle({
		Name = '仅BUX',
		Function = function()
			if PickupTracers.Enabled then
				PickupTracers:Toggle()
				PickupTracers:Toggle()
			end
		end,
		Tooltip = '隐藏非 BUX 的拾取物'
	})
end)

run(function()
	local AutoCamel
	
	AutoCamel = vape.Categories.Utility:CreateModule({
		Name = '自动骆驼',
		Function = function(callback)
			if callback then
				local camel = workspace.NPCs:FindFirstChild('Abu Baba')
				if not camel then
					notif('AutoCamel', 'Missing camel seller!', 5, 'warning')
					AutoCamel:Toggle()
					return
				end
	
				local module = require(camel.Dialogue:FindFirstChild('RunScript', true).ModuleScript)
				repeat
					if (lplr:GetAttribute('TIX') or 0) >= 30 then
						module:Run()
					end
	
					task.wait(0.5)
				until not AutoCamel.Enabled
			end
		end,
		Tooltip = '自动购买骆驼'
	})
end)

run(function()
	local AutoCloudGrind
	
	AutoCloudGrind = vape.Categories.Utility:CreateModule({
		Name = '自动云刷',
		Function = function(callback)
			if callback then
				repeat
					if bt.Variables.arena and bt.Variables.arena:GetAttribute('State') == 'Picking' then
						local doRun = true
						for _, v in bt.Variables.arena.Goon:GetChildren() do
							local drop = v.Value and v.Value:GetAttribute('Item_Drop')
	
							if drop and drop:find('FX ') and not bt.Variables.data.CardCollection[drop] then
								doRun = false
							end
						end
	
						if doRun then
							bt.Network.FireServer('CommitToMove', 'Run Away', nil, nil)
							task.wait(3)
						else
							workspace.Sounds.Money:Play()
							workspace.Sounds.Money.Ended:Wait()
						end
					end
	
					task.wait(0.05)
				until not AutoCloudGrind.Enabled
			end
		end,
		Tooltip = '自动刷 Cloudie（51 层）的音效卡'
	})
end)

run(function()
	local AutoFish
	local KeepList
	local old
	
	AutoFish = vape.Categories.Utility:CreateModule({
		Name = '自动钓鱼',
		Function = function(callback)
			if callback then
				local fishman = workspace.NPCs:FindFirstChild('The Seller')
				if not fishman then
					notif('AutoFish', 'Missing fisherman!', 5, 'warning')
					AutoFish:Toggle()
					return
				end
	
				old = workspace.Sounds.Money.Volume
				workspace.Sounds.Money.Volume = 0
	
				repeat
					local fish = lplr.Status:GetAttribute('NextFish')
					local res = bt.Network.InvokeServer('FishItem')
					if res == true then
						if not table.find(KeepList.ListEnabled, fish) then
							bt.Network.InvokeServer('UseItem', fish, fishman)
						end
	
						bt.Network.InvokeServer('BuyItem', fishman.ShopItems:GetChildren()[1], fishman)
					end
	
					task.wait()
				until not AutoFish.Enabled
			else
				if old then
					workspace.Sounds.Money.Volume = old
				end
			end
		end,
		Tooltip = '自动卖鱼和买鱼'
	})
	KeepList = AutoFish:CreateTextList({
		Name = '保留列表',
		Placeholder = '物品'
	})
end)

run(function()
	local AutoPaint
	
	AutoPaint = vape.Categories.Utility:CreateModule({
		Name = '自动喷漆',
		Function = function(callback)
			if callback then
				local gui = lplr.PlayerGui.HUD.Painter
				local canvas = gui:FindFirstChild('CanvasTime', true).Parent
				local colorpicker = gui.ColorPicker
	
				repeat
					if gui.Visible and bt.Variables.paintingflag and not bt.Variables.canvas:GetAttribute('Completed') then
						local solution = bt.Variables.canvas.Parent:FindFirstChild('Solution Easel')
	
						if solution then
							for _, v in solution.solution:GetDescendants() do
								if v:IsA('BasePart') and bt.Variables.canvas[v.Parent.Name][v.Name].BrickColor ~= v.BrickColor then
									local element = canvas:FindFirstChild(v.Parent.Name:sub(4)..'_'..v.Name)
									if element then
										for _, color in colorpicker:GetChildren() do
											if color:GetAttribute('BGColor') == v.BrickColor.Color then
												bt.Ambassador.Fire('ButtonPress', color)
												break
											end
										end
	
										bt.Ambassador.Fire('ButtonPress', element)
									end
	
									break
								end
							end
						end
					end
	
					task.wait(0.05)
				until not AutoPaint.Enabled
			end
		end,
		Tooltip = '自动绘制画布照片'
	})
end)
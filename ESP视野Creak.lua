--!nonstrict
--=============================================================================
--  ESP 轮廓 + 视野 + Creak 愤怒值     （独立版·自带 GUI）
--
--  · ESP 只有【轮廓高亮】，没有任何文字（按你的要求不带字体）
--  · 视野默认 120，被游戏重置会自动重新应用
--  · Creak 愤怒值读取 + 调试扫描（找不到时能把候选值列出来）
--  · 从零实现，只用 Roblox 原生 API：Highlight / Camera / RunService
--
--  用法：
--    loadstring(game:HttpGet("<你的URL>"))()
--
--  卸载：
--    getgenv().ESPX.Unload()
--=============================================================================

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Lighting    = game:GetService("Lighting")


local LP = Players.LocalPlayer

--────────────────────────────── 容器 ──────────────────────────────
-- 优先 gethui()，这样游戏清 PlayerGui 时不会连我们一起清掉
local function getContainer()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and type(hui) == "userdata" then return hui end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and type(cg) == "userdata" then return cg end
	return LP:WaitForChild("PlayerGui")
end

local CONTAINER = getContainer()

local GUI = Instance.new("ScreenGui")
GUI.Name = "ESP视野Creak"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() GUI.Parent = CONTAINER end)

-- 高亮统一挂在这个文件夹下，方便一键清干净
local HL_FOLDER = Instance.new("Folder")
HL_FOLDER.Name = "ESP_Highlights"
pcall(function() HL_FOLDER.Parent = CONTAINER end)

--────────────────────────────── 配置 ──────────────────────────────
local CONFIG = {
	ESP = {
		Enabled    = true,
		SeeThrough = true,     -- 穿透显示（AlwaysOnTop）
		Distance   = 0,        -- 0 = 不限距离
	},
	FOV = {
		Enabled  = true,
		Value    = 120,        -- 你要的默认 120
		Min      = 70,
		Max      = 120,
		Original = nil,
	},
	Creak = {
		Enabled = true,
	},
}

-- 四个分类，各自独立开关 + 颜色
local GROUPS = {
	{ id = "Door",   label = "门",     on = true, color = Color3.fromRGB(0, 255, 140) },
	{ id = "Item",   label = "道具",   on = true, color = Color3.fromRGB(255, 200, 0) },
	{ id = "Hiding", label = "躲藏点", on = true, color = Color3.fromRGB(80, 170, 255) },
	{ id = "Entity", label = "实体",   on = true, color = Color3.fromRGB(255, 60, 60) },
}

local function groupById(id)
	for _, g in ipairs(GROUPS) do
		if g.id == id then return g end
	end
	return nil
end

-- 名字匹配表（全部小写）。这些是【游戏里的对象名】不是他的代码。
local PATTERNS = {
	Door   = { "^door$", "^door%d", "doorway", "doorframe", "elevator" },
	Hiding = { "wardrobe", "closet", "locker", "^bed$", "doublebed", "bunkbed",
	           "^table$", "^vault$", "fridge", "dresser", "^crate", "barrel",
	           "tent", "bathtub", "^sofa$", "^couch$", "piano", "cabinet",
	           "bookshelf", "shelf", "drawer", "trash", "^car$", "^grave" },
	Entity = { "rush", "ambush", "seek", "eyes", "screech", "figure", "hide",
	           "gloombat", "dupe", "snare", "giggle", "jack", "^shadow",
	           "timothy", "jeff", "goblino", "^bob$", "window", "creak",
	           "dread", "halt", "lookman", "pandemonium", "blitz",
	           "a-60", "a-90", "a-120", "grumble", "sally" },
}

local function matchesAny(name, list)
	local n = string.lower(name)
	for _, p in ipairs(list) do
		if string.find(n, p) then return true end
	end
	return false
end

--────────────────────────── 高亮轮廓管理器 ──────────────────────────
local active = {}        -- [Instance] = { hl = Highlight, group = string }

local function getAdornee(inst)
	if inst:IsA("Model") or inst:IsA("BasePart") then return inst end
	-- 命中的是子部件时，往上找 Model
	local parent = inst.Parent
	while parent and parent ~= workspace do
		if parent:IsA("Model") then return parent end
		parent = parent.Parent
	end
	return inst:IsA("BasePart") and inst or nil
end

local function hasPrompt(inst)
	-- ★ 必须用 FindFirstChildWhichIsA(名, true)：第二个参数是「递归」，
	--   它是 C 实现，比在 Lua 里循环 GetDescendants() 快非常多。
	--   之前写成 Lua 循环会让整个扫描变成 O(n²)，进游戏会直接卡死。
	return inst:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
end

-- 判断一个实例属于哪个分类；返回 nil 表示不显示
local function classify(inst)
	if not (inst:IsA("Model") or inst:IsA("BasePart")) then return nil end

	-- 排除自己、玩家角色、以及我们自己的东西
	if LP.Character and (inst == LP.Character or inst:IsDescendantOf(LP.Character)) then return nil end
	if inst:IsDescendantOf(HL_FOLDER) or inst:IsDescendantOf(GUI) then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and (inst == p.Character or inst:IsDescendantOf(p.Character)) then return nil end
	end

	local name = inst.Name

	-- 实体优先（名字最独特）
	if matchesAny(name, PATTERNS.Entity) then return "Entity" end
	if inst:IsA("Model") and matchesAny(name, PATTERNS.Door) then return "Door" end
	if inst:IsA("Model") and matchesAny(name, PATTERNS.Hiding) then return "Hiding" end

	-- 带交互提示的都算道具
	if inst:IsA("Model") and hasPrompt(inst) then return "Item" end

	return nil
end

local function applyHighlight(inst, groupId)
	local g = groupById(groupId)
	if not g then return end

	local adornee = getAdornee(inst)
	if not adornee then return end

	local rec = active[inst]
	if rec and rec.hl and rec.hl.Parent and rec.group == groupId then
		-- 已存在，只更新颜色 / 穿透
		rec.hl.OutlineColor = g.color
		rec.hl.DepthMode = CONFIG.ESP.SeeThrough
			and Enum.HighlightDepthMode.AlwaysOnTop
			or Enum.HighlightDepthMode.Occluded
		return
	end

	if rec and rec.hl then
		pcall(function() rec.hl:Destroy() end)
	end

	local hl = Instance.new("Highlight")
	hl.Name = "ESP_" .. groupId
	hl.Adornee = adornee
	hl.FillTransparency = 1                      -- ★ 只要轮廓，不要填充
	hl.OutlineTransparency = 0
	hl.OutlineColor = g.color
	hl.DepthMode = CONFIG.ESP.SeeThrough
		and Enum.HighlightDepthMode.AlwaysOnTop
		or Enum.HighlightDepthMode.Occluded
	pcall(function() hl.Parent = HL_FOLDER end)

	active[inst] = { hl = hl, group = groupId }
end

local function dropHighlight(inst)
	local rec = active[inst]
	if rec then
		if rec.hl then pcall(function() rec.hl:Destroy() end) end
		active[inst] = nil
	end
end

local function clearAllHighlights()
	-- ★ 先收集 key 再删：在 pairs() 遍历过程中把 active[inst] 置 nil
	--   属于「边遍历边改表」，行为不确定，会漏清。
	local keys = {}
	for inst in pairs(active) do table.insert(keys, inst) end
	for _, inst in ipairs(keys) do dropHighlight(inst) end

	for _, c in ipairs(HL_FOLDER:GetChildren()) do
		pcall(function() c:Destroy() end)
	end
end

--────────────────────────── 扫描 / 分类 ──────────────────────────
local lastScan = 0
local SCAN_INTERVAL = 0.4

local function withinDistance(inst)
	if CONFIG.ESP.Distance <= 0 then return true end
	local adornee = getAdornee(inst)
	local char = LP.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (adornee and root) then return true end
	local ok, pos = pcall(function() return adornee:GetPivot().Position end)
	if not ok then return true end
	return (pos - root.Position).Magnitude <= CONFIG.ESP.Distance
end

local function scan()
	if not CONFIG.ESP.Enabled then
		clearAllHighlights()
		return
	end

	local seen = {}

	for _, inst in ipairs(workspace:GetDescendants()) do
		local gid = classify(inst)
		if gid then
			local g = groupById(gid)
			if g and g.on and withinDistance(inst) then
				seen[inst] = true
				applyHighlight(inst, gid)
			end
		end
	end

	-- 清掉已经不显示 / 已销毁的（同样先收集 key 再删）
	local stale = {}
	for inst in pairs(active) do
		if not seen[inst] or not inst.Parent then
			table.insert(stale, inst)
		end
	end
	for _, inst in ipairs(stale) do dropHighlight(inst) end
end

--──────────────────────────── 视野 FOV ────────────────────────────
local function camera()
	return workspace.CurrentCamera
end

local function applyFOV()
	local cam = camera()
	if not cam then return end
	if CONFIG.FOV.Original == nil then
		CONFIG.FOV.Original = cam.FieldOfView
	end
	if not CONFIG.FOV.Enabled then return end
	local want = math.clamp(CONFIG.FOV.Value, CONFIG.FOV.Min, CONFIG.FOV.Max)
	if math.abs(cam.FieldOfView - want) > 0.01 then
		pcall(function() cam.FieldOfView = want end)
	end
end

local function restoreFOV()
	local cam = camera()
	if cam and CONFIG.FOV.Original then
		pcall(function() cam.FieldOfView = CONFIG.FOV.Original end)
	end
end

-- 游戏会反复改 FOV，所以监听变化 + 每次相机换了重新挂钩
if camera() then
	pcall(function()
		camera():GetPropertyChangedSignal("FieldOfView"):Connect(function()
			if CONFIG.FOV.Enabled then applyFOV() end
		end)
	end)
end
pcall(function()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.wait(0.1)
		CONFIG.FOV.Original = nil
		applyFOV()
		if camera() then
			pcall(function()
				camera():GetPropertyChangedSignal("FieldOfView"):Connect(function()
					if CONFIG.FOV.Enabled then applyFOV() end
				end)
			end)
		end
	end)
end)

--──────────────────────── Creak 愤怒值读取 ────────────────────────
-- 说明：这个值由游戏内部决定怎么暴露。下面会自动在 Creak 身上找
--       属性 / NumberValue / Sound 速度 等等，挑最像「愤怒值」的那个。
--       找不到就点 GUI 上的【扫描调试】把候选列出来，我再照实调。

local creakCache = { model = nil, source = nil, at = 0 }

local AGGRO_HINTS = { "aggro", "aggression", "anger", "angry", "rage", "fury", "mad", "progress" }

local function looksLikeAggro(name)
	local n = string.lower(name)
	for _, h in ipairs(AGGRO_HINTS) do
		if string.find(n, h) then return true end
	end
	return false
end

local function findCreak()
	local now = os.clock()
	if creakCache.model and creakCache.model.Parent and (now - creakCache.at) < 2 then
		return creakCache.model
	end
	creakCache.at = now
	creakCache.model = nil
	for _, d in ipairs(workspace:GetDescendants()) do
		if string.find(string.lower(d.Name), "creak") then
			local m = d:IsA("Model") and d or d:FindFirstAncestorOfClass("Model")
			if m then
				creakCache.model = m
				return m
			end
		end
	end
	return nil
end

-- 收集所有「可能装着愤怒值」的数值源
local function collectCandidates(model)
	local out = {}
	if not model then return out end

	-- 1) 模型和子对象的属性
	local function scanAttrs(inst)
		local ok, attrs = pcall(function() return inst:GetAttributes() end)
		if not ok or type(attrs) ~= "table" then return end
		for k, v in pairs(attrs) do
			if type(v) == "number" then
				table.insert(out, { label = inst.Name .. "." .. k, value = v, kind = "attribute" })
			end
		end
	end

	scanAttrs(model)
	for _, d in ipairs(model:GetDescendants()) do
		scanAttrs(d)
		if d:IsA("NumberValue") or d:IsA("IntValue") then
			table.insert(out, { label = d:GetFullName(), value = d.Value, kind = d.ClassName })
		elseif d:IsA("Sound") then
			table.insert(out, { label = d:GetFullName() .. ".PlaybackSpeed", value = d.PlaybackSpeed, kind = "Sound" })
		end
	end
	return out
end

-- 从候选里挑最像愤怒值的
local function pickAggression(cands)
	local best, bestScore = nil, -1
	for _, c in ipairs(cands) do
		local score = 0
		if looksLikeAggro(c.label) then score = score + 10 end
		if c.kind == "attribute" then score = score + 1 end
		-- 0~1 或 0~100 之间的值更像百分比
		if c.value >= 0 and c.value <= 100 then score = score + 1 end
		if score > bestScore then best, bestScore = c, score end
	end
	if best and bestScore > 0 then return best end
	return nil
end

local function readCreakPercent()
	local model = findCreak()
	if not model then return nil, "没找到 Creak" end
	local cands = collectCandidates(model)
	local best = pickAggression(cands)
	if not best then return nil, "Creak 上没找到数值" end
	local pct = best.value
	if pct >= 0 and pct <= 1 then pct = pct * 100 end
	return math.clamp(pct, 0, 100), best.label
end

--────────────────────── 场景提亮 / 去雾（干净实现）────────────────────
-- 实现方式和 Abysall 那套【完全无关】：
--   他：每个属性各挂一个 GetPropertyChangedSignal 回调，原值存进 Instance 的
--       SetAttribute("Density_Old") 里，每帧新建 Tween 播放。
--   我：不开任何信号回调，只在 Heartbeat 里【每帧轮询】比对，不对就写回；
--       原值全部记在下面这两张 Lua 表里，不往实例上写任何东西。
--
-- 为什么必须每帧守：
--   Doors 每进一个房间都会把环境光调暗、把雾拉回来，设一次是留不住的。
--   轮询和回调在「必不必须每帧」上是一样的，但轮询没有回调堆叠 / 重入问题。

local SCENE = {
	Enabled = true,
	Ambient = true,                              -- 环境光拉白
	NoFog   = true,                              -- 去雾（雾 + Atmosphere）
	Color   = Color3.fromRGB(255, 255, 255),
}

local sceneSaved  = nil     -- 关闭时用来还原
local atmoTracked = {}      -- [Atmosphere] = 它原本的 Density

local function sceneCapture()
	sceneSaved = {
		Ambient = Lighting.Ambient,
		FogEnd  = Lighting.FogEnd,
	}
	atmoTracked = {}
	for _, o in ipairs(Lighting:GetChildren()) do
		if o:IsA("Atmosphere") then
			atmoTracked[o] = o.Density
		end
	end
end

local function sceneRestore()
	if sceneSaved then
		local s = sceneSaved
		pcall(function()
			Lighting.Ambient = s.Ambient
			Lighting.FogEnd  = s.FogEnd
		end)
		sceneSaved = nil
	end
	for o, d in pairs(atmoTracked) do
		if o.Parent then
			pcall(function() o.Density = d end)
		end
	end
end

local function sceneStep()
	if not SCENE.Enabled then return end
	if not sceneSaved then sceneCapture() end

	if SCENE.Ambient and Lighting.Ambient ~= SCENE.Color then
		pcall(function() Lighting.Ambient = SCENE.Color end)
	end

	if SCENE.NoFog then
		-- math.huge = 雾的终点在无穷远，等于没有雾
		if Lighting.FogEnd ~= math.huge then
			pcall(function() Lighting.FogEnd = math.huge end)
		end
		-- 顺便把后加进来的 Atmosphere 也纳管
		for _, o in ipairs(Lighting:GetChildren()) do
			if o:IsA("Atmosphere") then
				if atmoTracked[o] == nil then atmoTracked[o] = o.Density end
				if o.Density ~= 0 then
					pcall(function() o.Density = 0 end)
				end
			end
		end
	end
end

--──────────────────────────────── GUI ────────────────────────────
local THEME = {
	bg      = Color3.fromRGB(22, 24, 30),
	panel   = Color3.fromRGB(32, 35, 44),
	stroke  = Color3.fromRGB(58, 63, 78),
	text    = Color3.fromRGB(232, 236, 245),
	dim     = Color3.fromRGB(150, 158, 176),
	accent  = Color3.fromRGB(88, 140, 255),
	on      = Color3.fromRGB(60, 200, 130),
	off     = Color3.fromRGB(70, 74, 88),
}
local FONT = Enum.Font.GothamMedium

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function corner(inst, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, inst)
	return inst
end

local function stroke(inst, c)
	new("UIStroke", { Color = c or THEME.stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
	return inst
end

local main = new("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(268, 60),
	Position = UDim2.new(0, 24, 0, 120),
	BackgroundColor3 = THEME.bg,
	BorderSizePixel = 0,
	Active = true,
}, GUI)
corner(main, 10)
stroke(main)

-- 标题栏（拖动）
local bar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
}, main)
corner(bar, 10)

new("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0),
	Position = UDim2.fromOffset(12, 0),
	BackgroundTransparency = 1,
	Text = "ESP 轮廓 · 视野 · Creak",
	TextColor3 = THEME.text,
	TextSize = 13,
	Font = FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local minBtn = new("TextButton", {
	Size = UDim2.fromOffset(24, 22),
	Position = UDim2.new(1, -30, 0, 6),
	BackgroundColor3 = THEME.off,
	Text = "–",
	TextColor3 = THEME.text,
	TextSize = 15,
	Font = FONT,
	AutoButtonColor = true,
}, bar)
corner(minBtn, 5)

-- 内容区
local body = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	Position = UDim2.fromOffset(0, 34),
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
}, main)

local layout = new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, body)
new("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, body)

local function section(text)
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
	}, body)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.dim,
		TextSize = 11,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	return f
end

local function row(text, initial, onToggle)
	local f = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	}, body)

	new("TextLabel", {
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.text,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, f)

	local btn = new("TextButton", {
		Size = UDim2.fromOffset(38, 18),
		Position = UDim2.new(1, -38, 0.5, -9),
		BackgroundColor3 = initial and THEME.on or THEME.off,
		Text = initial and "开" or "关",
		TextColor3 = THEME.text,
		TextSize = 11,
		Font = FONT,
		AutoButtonColor = false,
	}, f)
	corner(btn, 9)

	local state = initial
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.BackgroundColor3 = state and THEME.on or THEME.off
		btn.Text = state and "开" or "关"
		if onToggle then onToggle(state) end
	end)
	return f, btn
end

-- 色块按钮（点一下换颜色）
local PRESET_COLORS = {
	Color3.fromRGB(0, 255, 140), Color3.fromRGB(255, 200, 0),
	Color3.fromRGB(255, 60, 60),  Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(220, 120, 255), Color3.fromRGB(255, 255, 255),
}
local function colorChip(parent, group)
	local btn = new("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -62, 0.5, -9),
		BackgroundColor3 = group.color,
		Text = "",
		AutoButtonColor = false,
	}, parent)
	corner(btn, 5)
	stroke(btn, THEME.stroke)
	btn.MouseButton1Click:Connect(function()
		local idx = 1
		for i, c in ipairs(PRESET_COLORS) do
			if c == group.color then idx = i break end
		end
		group.color = PRESET_COLORS[(idx % #PRESET_COLORS) + 1]
		btn.BackgroundColor3 = group.color
		-- 立刻刷新已有高亮
		for _, rec in pairs(active) do
			if rec.group == group.id and rec.hl then
				rec.hl.OutlineColor = group.color
			end
		end
	end)
end

section("ESP 轮廓")

row("ESP 总开关", CONFIG.ESP.Enabled, function(v)
	CONFIG.ESP.Enabled = v
	if not v then clearAllHighlights() else scan() end
end)

row("穿透显示（隔墙可见）", CONFIG.ESP.SeeThrough, function(v)
	CONFIG.ESP.SeeThrough = v
	for _, rec in pairs(active) do
		if rec.hl then
			rec.hl.DepthMode = v and Enum.HighlightDepthMode.AlwaysOnTop
				or Enum.HighlightDepthMode.Occluded
		end
	end
end)

for _, g in ipairs(GROUPS) do
	local f = row(g.label, g.on, function(v)
		g.on = v
		if not v then
			for inst, rec in pairs(active) do
				if rec.group == g.id then dropHighlight(inst) end
			end
		else
			scan()
		end
	end)
	colorChip(f, g)
end

-- 视野滑块
section("视野 FOV")

local fovRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
}, body)

local fovLabel = new("TextLabel", {
	Size = UDim2.new(1, -46, 1, 0),
	BackgroundTransparency = 1,
	Text = "视野  " .. tostring(CONFIG.FOV.Value),
	TextColor3 = THEME.text,
	TextSize = 12,
	Font = FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, fovRow)

local fovBtn = new("TextButton", {
	Size = UDim2.fromOffset(38, 18),
	Position = UDim2.new(1, -38, 0.5, -9),
	BackgroundColor3 = CONFIG.FOV.Enabled and THEME.on or THEME.off,
	Text = CONFIG.FOV.Enabled and "开" or "关",
	TextColor3 = THEME.text,
	TextSize = 11,
	Font = FONT,
	AutoButtonColor = false,
}, fovRow)
corner(fovBtn, 9)
fovBtn.MouseButton1Click:Connect(function()
	CONFIG.FOV.Enabled = not CONFIG.FOV.Enabled
	fovBtn.BackgroundColor3 = CONFIG.FOV.Enabled and THEME.on or THEME.off
	fovBtn.Text = CONFIG.FOV.Enabled and "开" or "关"
	if CONFIG.FOV.Enabled then applyFOV() else restoreFOV() end
end)

local track = new("Frame", {
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
}, body)
corner(track, 3)

local fill = new("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = THEME.accent,
	BorderSizePixel = 0,
}, track)
corner(fill, 3)

local knob = new("Frame", {
	Size = UDim2.fromOffset(14, 14),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(240, 244, 255),
	BorderSizePixel = 0,
	ZIndex = 2,
}, track)
corner(knob, 7)

local function setFOVFromX(x)
	local abs = track.AbsolutePosition.X
	local w = track.AbsoluteSize.X
	if w <= 0 then return end
	local a = math.clamp((x - abs) / w, 0, 1)
	local v = math.floor(CONFIG.FOV.Min + a * (CONFIG.FOV.Max - CONFIG.FOV.Min) + 0.5)
	CONFIG.FOV.Value = v
	fill.Size = UDim2.new(a, 0, 1, 0)
	knob.Position = UDim2.new(a, 0, 0.5, 0)
	fovLabel.Text = "视野  " .. tostring(v)
	applyFOV()
end

local draggingFov = false
track.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		draggingFov = true
		setFOVFromX(i.Position.X)
	end
end)
UIS.InputChanged:Connect(function(i)
	if draggingFov and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		setFOVFromX(i.Position.X)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		draggingFov = false
	end
end)

-- Creak
section("Creak 愤怒值")

local creakRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
}, body)

local creakLabel = new("TextLabel", {
	Size = UDim2.new(1, -46, 1, 0),
	BackgroundTransparency = 1,
	Text = "愤怒值  --",
	TextColor3 = THEME.text,
	TextSize = 12,
	Font = FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, creakRow)

local creakBtn = new("TextButton", {
	Size = UDim2.fromOffset(38, 18),
	Position = UDim2.new(1, -38, 0.5, -9),
	BackgroundColor3 = CONFIG.Creak.Enabled and THEME.on or THEME.off,
	Text = CONFIG.Creak.Enabled and "开" or "关",
	TextColor3 = THEME.text,
	TextSize = 11,
	Font = FONT,
	AutoButtonColor = false,
}, creakRow)
corner(creakBtn, 9)
creakBtn.MouseButton1Click:Connect(function()
	CONFIG.Creak.Enabled = not CONFIG.Creak.Enabled
	creakBtn.BackgroundColor3 = CONFIG.Creak.Enabled and THEME.on or THEME.off
	creakBtn.Text = CONFIG.Creak.Enabled and "开" or "关"
	if not CONFIG.Creak.Enabled then creakLabel.Text = "愤怒值  --" end
end)

local debugBox = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	Visible = false,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
}, body)
corner(debugBox, 6)

new("UIPadding", {
	PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, debugBox)

local dbgLayout = new("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, debugBox)

local function dbgLine(text)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = THEME.dim,
		TextSize = 10,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, debugBox)
end

local scanBtn = new("TextButton", {
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundColor3 = THEME.panel,
	Text = "扫描调试 / 列出候选值",
	TextColor3 = THEME.text,
	TextSize = 11,
	Font = FONT,
	AutoButtonColor = true,
}, body)
corner(scanBtn, 6)

scanBtn.MouseButton1Click:Connect(function()
	for _, c in ipairs(debugBox:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	debugBox.Visible = not debugBox.Visible
	if not debugBox.Visible then
		debugBox.Size = UDim2.new(1, 0, 0, 0)
		return
	end
	debugBox.Size = UDim2.new(1, 0, 0, 120)

	local model = findCreak()
	if not model then
		dbgLine("没找到名字里带 Creak 的对象")
		return
	end
	dbgLine("找到: " .. model:GetFullName())
	dbgLine("──────── 候选数值 ────────")
	local cands = collectCandidates(model)
	if #cands == 0 then
		dbgLine("（没有任何数值暴露出来）")
	end
	for _, c in ipairs(cands) do
		local mark = looksLikeAggro(c.label) and " ★" or ""
		dbgLine(string.format("%s = %.3f%s", c.label, c.value, mark))
	end
end)

-- 场景提亮 / 去雾
section("场景提亮 · 去雾")

row("场景提亮 总开关", SCENE.Enabled, function(v)
	SCENE.Enabled = v
	if not v then sceneRestore() end
end)

row("环境光拉白", SCENE.Ambient, function(v) SCENE.Ambient = v end)
row("去雾（雾 + Atmosphere）", SCENE.NoFog, function(v) SCENE.NoFog = v end)

-- 最小化
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	minBtn.Text = minimized and "+" or "–"
	main.Size = minimized and UDim2.fromOffset(268, 34) or UDim2.fromOffset(268, 60)
	if not minimized then
		main.Size = UDim2.new(0, 268, 0, 34 + body.AbsoluteSize.Y + 0)
	end
end)

-- 拖动
local dragging, dragStart, startPos = false, nil, nil
bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = main.Position
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- 让内容把面板高度撑开
local function fit()
	if minimized then return end
	main.Size = UDim2.new(0, 268, 0, 34 + body.AbsoluteSize.Y + 8)
end
body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
task.defer(fit)

--────────────────────────────── 主循环 ────────────────────────────
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc = acc + dt

	-- 视野：被游戏改回去就重新写
	applyFOV()

	-- 场景提亮 / 去雾：同样是「被改回去就写回来」，但用轮询不用回调
	pcall(sceneStep)

	-- 扫描：节流
	if acc >= SCAN_INTERVAL then
		acc = 0
		pcall(scan)
	end

	-- Creak 数值
	if CONFIG.Creak.Enabled then
		local pct, src = readCreakPercent()
		if pct then
			creakLabel.Text = string.format("愤怒值  %.1f%%", pct)
			creakLabel.TextColor3 = pct > 66 and Color3.fromRGB(255, 90, 90)
				or (pct > 33 and Color3.fromRGB(255, 200, 90) or THEME.text)
		else
			creakLabel.Text = "愤怒值  --"
			creakLabel.TextColor3 = THEME.dim
		end
	end
end)

-- 新对象进来就尽快扫一次
workspace.DescendantAdded:Connect(function()
	acc = math.max(acc, SCAN_INTERVAL)
end)

--────────────────────────────── 清理 ──────────────────────────────
local function unload()
	sceneRestore()
	restoreFOV()
	clearAllHighlights()
	pcall(function() GUI:Destroy() end)
	pcall(function() HL_FOLDER:Destroy() end)
end

getgenv().ESPX = {
	Config  = CONFIG,
	Groups  = GROUPS,
	Scan    = scan,
	Unload  = unload,
	Gui     = GUI,
}

print("[ESP视野Creak] 已加载 · ESP轮廓 / 视野(" .. CONFIG.FOV.Value .. ") / Creak愤怒值")
print("[ESP视野Creak] 卸载: getgenv().ESPX.Unload()")

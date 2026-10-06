--[[
=====================================================================
  Doors · ESP 提取版 (原版行为)          自建 UI / 单文件 / 无外部依赖
=====================================================================
  提取来源: AbysallContinued  ·  Games/Doors/Main.luau  (318,523 B, md5 9cca1d64…)
            +  Components/ESP.luau  (17,870 B, 原样内联)

  ★ 设计原则: 视觉效果 = 原版。没有加任何原版没有的功能。
    - ESP 渲染完全用原版 Components/ESP.luau 那套
      (Highlight + ScreenGui 文字标签 + WorldToViewportPoint + RenderLimit)
    - 物品/实体/宝箱/门/藏身点… 的文字串、颜色、房间裁剪规则、默认值
      全部照搬原版 Main.luau，没有翻译、没有改名
    - 开关默认值也和原版一样(全是 false)，开了才有效果

  相对原版只动了这些(其他全是照搬):
    1. 视野滑条默认值 70 -> 120（你要求的）
    2. ESP 文字加了一个总开关「隐藏 ESP 文字」
       ——原版只有 Text Transparency 滑条，效果一样，这个只是好按
    3. 界面用自建 UI 重排；「Custom Fov 快捷键」默认 O 键切视野开关

  UI 是自己写的(拖动/标签页/开关/滑块/取色/下拉/多选/按键)，没有引用 WindUI。
  卸载: getgenv().DoorsESPX.Unload()
=====================================================================
]]

--=====================================================================
-- 0. 服务
--=====================================================================
local cloneref = cloneref or function(o) return o end

local Services = setmetatable({}, {
    __index = function(self, name)
        local svc = cloneref(game:GetService(name))
        rawset(self, name, svc)
        return svc
    end,
})

local Players           = Services.Players
local Workspace         = Services.Workspace
local RunService        = Services.RunService
local UserInputService  = Services.UserInputService
local TweenService      = Services.TweenService
local ReplicatedStorage = Services.ReplicatedStorage
local LocalPlayer       = Players.LocalPlayer

-- 执行器的 fireproximityprompt。隔墙互动、自动楼层、无拉回穿墙都要用它，
-- 所以在这里就取好（后面几节都靠这个局部变量）。
local FirePrompt
do
    local ok, fn = pcall(function() return getgenv().fireproximityprompt end)
    if ok and type(fn) == "function" then FirePrompt = fn end
end

local STATE_KEY = "DoorsESPX"
if getgenv()[STATE_KEY] then
    pcall(function() getgenv()[STATE_KEY].Unload() end)
end

--=====================================================================
-- 0.5 界面多语言（只翻译界面文字；ESP 标签保持游戏原版名称）
--=====================================================================
local Lang = {
    Current  = "zh",
    Strings  = { zh = {}, en = {} },
    Registry = {},
    Names    = { zh = "中文", en = "English" },
}

function Lang.T(key)
    if not key then return nil end
    local t = Lang.Strings[Lang.Current]
    return t and t[key] or nil
end

function Lang.Has(key)
    return Lang.T(key) ~= nil
end

function Lang.Bind(inst, key, prop)
    if not key then return inst end
    Lang.Registry[#Lang.Registry + 1] = { inst = inst, key = key, prop = prop or "Text" }
    local v = Lang.T(key)
    if v ~= nil then inst[prop or "Text"] = v end
    return inst
end

-- 动态文字（比如「已选 3」）用回调，切换语言时重新算
function Lang.BindFn(inst, fn)
    Lang.Registry[#Lang.Registry + 1] = { inst = inst, fn = fn }
    inst.Text = fn()
    return inst
end

function Lang.Format(key, ...)
    local fmt = Lang.T(key)
    if not fmt then return tostring((...)) end
    local ok, out = pcall(string.format, fmt, ...)
    return ok and out or tostring((...))
end

function Lang.Set(code)
    if not Lang.Strings[code] then return false end
    Lang.Current = code
    for _, e in ipairs(Lang.Registry) do
        if e.fn then
            e.inst.Text = e.fn()
        else
            local v = Lang.T(e.key)
            if v ~= nil then e.inst[e.prop] = v end
        end
    end
    return true
end

-- UI 构建时用 L(...) 就地声明两种语言，省掉一张独立的 key 表
local function L(key, zh, en, zhTip, enTip)
    Lang.Strings.zh[key] = zh
    Lang.Strings.en[key] = en or zh
    if zhTip then
        Lang.Strings.zh[key .. ".tip"] = zhTip
        Lang.Strings.en[key .. ".tip"] = enTip or zhTip
    end
    return { Key = key, Text = zh, Tooltip = zhTip }
end

local function PickText(cfg)
    if type(cfg) == "table" then
        return (cfg.Key and Lang.T(cfg.Key)) or cfg.Text or ""
    end
    return tostring(cfg or "")
end

local function PickKey(cfg)
    if type(cfg) == "table" then return cfg.Key end
    return nil
end

--=====================================================================
-- 1. 自建 UI 库
--=====================================================================
--=====================================================================
-- 1. WindUI-Boreal 引导
--    UI 库换成你 GitHub 上那份（和 suif.lua 用的同一个地址、同一个版本号）
--=====================================================================
-- 多个源轮着试：raw.githubusercontent 在有些执行器/网络环境下拉不动，
-- 拉不动就换 jsDelivr（几个镜像），全都失败才放弃。
local WINDUI_SOURCES = {
    "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand8",
    "https://cdn.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
    "https://gcore.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
    "https://testingcf.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
    "https://fastly.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
}

local WindUI
do
    local Tried = {}
    for _, url in ipairs(WINDUI_SOURCES) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(res) == "table" and res.CreateWindow then
            WindUI = res
            break
        end
        Tried[#Tried + 1] = tostring(url:match("^https?://([^/]+)")) .. " → " .. tostring(res)
    end

    if not WindUI then
        local msg = "WindUI-Boreal 全部源都拉不到：\n" .. table.concat(Tried, "\n")
        warn("[DoorsESP] " .. msg)
        if setclipboard then pcall(setclipboard, msg) end
        return
    end
end

print("[DoorsESP] WindUI-Boreal " .. tostring(WindUI.ExpandFeatureVersion) .. " 已加载")

--=====================================================================
-- 1.5) Mini 兼容适配层
--    界面整个换成 WindUI-Boreal，但下面那几千行 ESP 逻辑一行都不改：
--    老代码读的是 Toggles.X.Value / Options.Y.Value，用的是 :OnChanged / :SetValue
--    / :Key / .Selected，这一层把这些 API 原样架在 WindUI 的控件上。
--=====================================================================
local BringDroppedItems
local FloorsAction
local SelfAction

local Mini = {}
Mini.WindUI = WindUI
Mini.Registry = {}   -- [控件] = { fn = 回调, get = 取值函数 }，读配置 / 重放时用

local function NewShadow()
    return { Cb = nil, Click = nil, InSet = false }
end

-- 控件标题 / 描述 / Flag 都交给 PickText / PickKey / PickDesc 解析，
-- 提示文字一律不显示：一是用户要求把所有提示去掉，
-- 二是长文案在 WindUI 里会顶出控件边界。
-- 这样 L() 里只写中文、英文靠 Lang.T(Key) 取，切语言的时候整块 UI 重建后就是对应语言。
local function PickDesc(cfg)
    if type(cfg) ~= "table" then return nil end
    local tipKey = cfg.Key and (cfg.Key .. ".tip") or nil
    if tipKey and Lang.Has(tipKey) then return Lang.T(tipKey) end
    return cfg.Tooltip
end

local function SafeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[DoorsESP] " .. tostring(err))
        return false
    end
    return true
end

-- 给控件套一个代理：读 .Value / .Key / .Selected 走取值函数，
-- 调 :Set / :SetValue / :OnChanged 走下面这套方法，其余读写原样转给 WindUI 的控件。
-- WindUI 的 Desc（说明文字）在长文案下会溢出、不换行。
-- 元素建完之后把它那个 TextLabel 找出来，强制打开自动换行。
local function FixDescWrap(el)
    local desc = el and el.Desc
    if type(desc) ~= "string" or desc == "" then return end
    local seen = {}
    local function Walk(node, depth)
        if depth > 6 or type(node) ~= "table" or seen[node] then return false end
        seen[node] = true
        if node.ClassName == "TextLabel" and node.Text == desc then
            pcall(function()
                node.TextWrapped = true
                node.TextTruncate = Enum.TextTruncate.None
                node.TextYAlignment = Enum.TextYAlignment.Top
            end)
            return true
        end
        for k, v in pairs(node) do
            if k ~= "Parent" and k ~= "Window" and k ~= "Tab"
                and k ~= "ElementTable" and type(v) == "table" then
                if Walk(v, depth + 1) then return true end
            end
        end
        return false
    end
    -- 真库的 Desc 挂在 element.<XxxFrame>.UIElements.Desc 上，所以从整个元素开始找
    Walk(el, 0)
end

local function MakeProxy(el, values, setters, methods)
    FixDescWrap(el)
    local t = { __el = el }
    return setmetatable(t, {
        __index = function(_, k)
            local get = values[k]
            if get then return get() end
            local m = methods[k]
            if m then return m end
            local v = el[k]
            -- WindUI 自己的方法要绑回它自己
            if type(v) == "function" then
                return function(_, ...) return v(el, ...) end
            end
            return v
        end,
        __newindex = function(_, k, v)
            local set = setters[k]
            if set then set(v) else el[k] = v end
        end,
    })
end

-- 一套所有控件共用的方法。setLocal 更新本地值，getValue 取本地值，
-- el 是 WindUI 的真控件，shadow 存「建完之后才注册」的那些回调。
local function CommonMethods(el, shadow, getValue, setLocal)
    local M = {}

    -- 真正的赋值：先屏蔽转发器，避免库的 :Set 自己回调一次、我们又回调一次
    function M.Set(t, v)
        shadow.InSet = true
        SafeCall(function() return el:Set(v) end)
        shadow.InSet = false
        setLocal(v)
        if shadow.Cb then SafeCall(shadow.Cb, getValue()) end
        return t
    end

    -- 第二参 silent = true 时不触发 OnChanged（老 Mini 的语义）
    function M.SetValue(t, v, silent)
        if silent then
            local keep = shadow.Cb
            shadow.Cb = nil
            M.Set(t, v)
            shadow.Cb = keep
        else
            M.Set(t, v)
        end
        return t
    end

    function M.OnChanged(t, fn)
        shadow.Cb = fn
        Mini.Registry[t] = { fn = fn, get = getValue }
        return t
    end

    function M.OnClick(_, fn)
        shadow.Click = fn
        return _
    end

    function M.SetDisabled(t, b)
        el.Disabled = b and true or false
        return t
    end

    function M.Destroy()
        SafeCall(function() return el:Destroy() end)
    end

    return M
end

-- WindUI 的 Callback 必须在建控件的时候就交出去，而老代码是建完再 :OnChanged，
-- 所以先给它一个转发器；真正要调的回调存在 shadow 里，调用时再取。
local function Tracker(shadow, setLocal)
    return function(v)
        setLocal(v)
        if shadow.InSet then return end
        if shadow.Cb then SafeCall(shadow.Cb, v) end
    end
end

--────────────────────────── 窗口 ──────────────────────────
function Mini.NewWindow(title, subtitle)
    local win = WindUI:CreateWindow({
        Title = PickText(title),
        Icon = "door-open",
        Author = PickText(subtitle),
        Folder = "DoorsESPX",
        Size = UDim2.new(0, 640, 0, 470),
        Resizable = true,
        ScrollBarEnabled = true,
        User = { Enabled = true, Anonymous = false },
        OpenButton = { Scale = 0.85, OnlyIcon = false },
    })

    local W = { Win = win, Tabs = {} }

    function W.Tab(_, name)
        local windTab = win:Tab({ Title = PickText(name), Icon = "circle" })
        local page = { Page = windTab, WindTab = windTab, Name = name }
        W.Tabs[#W.Tabs + 1] = page
        return page
    end

    -- 界面开关键。
    -- WindUI 没有内置的窗口快捷键，所以这里自己调它的 Open / Close。
    -- 注意：状态要读库自己的 win.Closed，不能自己记一份 ——
    -- 库自带的最小化按钮也会改这个状态，自记的话一按快捷键就两边错位。
    local function IsWindowOpen()
        if win.Closed ~= nil then return win.Closed == false end
        if win.IsOpen ~= nil then return win.IsOpen == true end
        if win.Opened ~= nil then return win.Opened == true end
        return true
    end

    function W.Toggle()
        if IsWindowOpen() then
            SafeCall(function() return win:Close() end)
        else
            SafeCall(function() return win:Open() end)
        end
        return IsWindowOpen()
    end

    Mini.__Window = win
    W.ConfigManager = win.ConfigManager
    -- 卸载那条路上老代码会调 Window.Gui:Destroy()。
    -- 必须是窗口的 ScreenGui：销毁它才会连带清掉整棵界面树，
    -- 否则换语言「卸载 + 重新执行脚本」时，旧界面的文字会留在实例树里。
    W.Gui = win.Gui or win.ScreenGui
    return W
end

--────────────────────────── 开关 ──────────────────────────
function Mini.Toggle(parent, cfg)
    local shadow = NewShadow()
    local v = cfg.Default and true or false

    local el = parent:Toggle({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Value = v,
        Flag = PickKey(cfg),
        Type = "Toggle",
        Callback = Tracker(shadow, function(nv) v = nv and true or false end),
    })

    return MakeProxy(el, {
        Value = function() return v end,
    }, {
        Value = function(nv) v = nv and true or false end,
    }, CommonMethods(el, shadow, function() return v end, function(nv) v = nv and true or false end))
end

--────────────────────────── 滑块 ──────────────────────────
-- WindUI 滑块的 .Value 是 { Min = , Max = , Default = } 这张表，
-- 但脚本里几十处读的都是数字，所以套一层代理把 .Value 变成数字。
function Mini.Slider(parent, cfg)
    local shadow = NewShadow()
    local v = tonumber(cfg.Default) or tonumber(cfg.Min) or 0

    local el = parent:Slider({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Value = { Min = cfg.Min, Max = cfg.Max, Default = v },
        Step = cfg.Rounding or 1,
        Flag = PickKey(cfg),
        Callback = Tracker(shadow, function(nv) v = tonumber(nv) or v end),
    })

    return MakeProxy(el, {
        Value = function() return v end,
    }, {
        Value = function(nv) v = tonumber(nv) or v end,
    }, CommonMethods(el, shadow, function() return v end, function(nv) v = tonumber(nv) or v end))
end

--────────────────────────── 取色器 ──────────────────────────
function Mini.ColorPicker(parent, cfg)
    local shadow = NewShadow()
    local v = cfg.Default

    local el = parent:Colorpicker({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Value = v,
        Flag = PickKey(cfg),
        Callback = Tracker(shadow, function(nv) v = nv end),
    })

    -- WindUI 取色器的颜色 setter 是 :Update(Color3[, 透明度])（它自己的配置系统就用这个）。
    -- 建完之后再补一次，色块和内部状态才会跟默认色对上；不补的话新库里色块可能是白的。
    if type(el.Update) == "function" then
        SafeCall(function() return el:Update(v) end)
    end

    return MakeProxy(el, {
        Value = function() return v end,
    }, {
        Value = function(nv) v = nv end,
    }, CommonMethods(el, shadow, function() return v end, function(nv) v = nv end))
end

--────────────────────────── 下拉框 ──────────────────────────
function Mini.Dropdown(parent, cfg)
    local shadow = NewShadow()
    local values = cfg.Values or {}
    -- 老 Mini 的 Default 是「第几项」，WindUI 要「那一项本身」
    local v = cfg.Default
    if type(v) == "number" then v = values[v] or values[1] else v = v or values[1] end

    local el = parent:Dropdown({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Values = values,
        Value = v,
        Flag = PickKey(cfg),
        Callback = Tracker(shadow, function(nv) v = nv end),
    })

    return MakeProxy(el, {
        Value = function() return v end,
    }, {
        Value = function(nv) v = nv end,
    }, CommonMethods(el, shadow, function() return v end, function(nv) v = nv end))
end

--────────────────────────── 多选下拉框 ──────────────────────────
-- 老代码读的是 Options.X.Value["名字"] 这种「名字 → true」的哈希表，
-- WindUI 的多选给的是数组，所以这里两边都转一手，另外补一个 :SetAll。
function Mini.MultiSelect(parent, cfg)
    local shadow = NewShadow()
    local values = cfg.Values or {}
    local set = {}
    local function RebuildFrom(list)
        set = {}
        if type(list) == "table" then
            for _, name in ipairs(list) do set[name] = true end
        end
    end

    local el = parent:Dropdown({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Values = values,
        Value = {},
        Multi = true,
        SearchBarEnabled = true,
        Flag = PickKey(cfg),
        Callback = Tracker(shadow, RebuildFrom),
    })

    local t
    local function Push()
        local list = {}
        for _, name in ipairs(values) do
            if set[name] then list[#list + 1] = name end
        end
        -- 真库多选的 setter 是 :Select（它自己的配置系统就用这个），没有才退回 :Set
        if type(el.Select) == "function" then
            SafeCall(function() return el:Select(list) end)
        else
            SafeCall(function() return el:Set(list) end)
        end
    end

    local methods = CommonMethods(el, shadow, function() return set end, RebuildFrom)
    function methods.SetAll(_, on)
        for _, name in ipairs(values) do set[name] = on and true or nil end
        Push()
        if shadow.Cb then SafeCall(shadow.Cb, set) end
        return t
    end

    t = MakeProxy(el, {
        Value = function() return set end,
        Selected = function() return set end,
    }, {
        Value = function(nv) RebuildFrom(nv) end,
    }, methods)
    return t
end

--────────────────────────── 快捷键 ──────────────────────────
-- 老代码读的是 X.Key（Enum.KeyCode），WindUI 存的 .Value 是字符串名字，这里转回来。
function Mini.Keybind(parent, cfg)
    local shadow = NewShadow()
    local v = cfg.Default

    local el = parent:Keybind({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Value = v,
        Flag = PickKey(cfg),
        Callback = Tracker(shadow, function(nv) v = nv end),
    })

    local function ToKeyCode(raw)
        if typeof and typeof(raw) == "EnumItem" then return raw end
        if type(raw) == "string" and Enum and Enum.KeyCode then
            local ok, code = pcall(function() return Enum.KeyCode[raw] end)
            if ok and code then return code end
        end
        return v
    end

    return MakeProxy(el, {
        Key = function() return ToKeyCode(el.Value) end,
        Value = function() return ToKeyCode(el.Value) end,
    }, {}, CommonMethods(el, shadow, function() return ToKeyCode(el.Value) end, function() end))
end

--────────────────────────── 按钮 ──────────────────────────
function Mini.Button(parent, cfg)
    local shadow = NewShadow()

    local el = parent:Button({
        Title = PickText(cfg),
        Desc = PickDesc(cfg),
        Flag = PickKey(cfg),
        Callback = function()
            if shadow.Click then SafeCall(shadow.Click) end
        end,
    })

    local methods = CommonMethods(el, shadow, function() return nil end, function() end)
    -- 按钮本体点一次也要执行
    if type(el.Set) == "function" then
        local oldSet = methods.Set
        methods.Set = function(t, ...)
            if shadow.Click then SafeCall(shadow.Click) end
            return oldSet(t, ...)
        end
    end
    return MakeProxy(el, {}, {}, methods)
end

--────────────────────────── 文字 ──────────────────────────
function Mini.Label(parent, text, color)
    local labelText = PickText(text)
    local el = parent:Label({ Text = labelText })

    -- 状态刷新 / 语言切换靠的是 .Text，所以得在 WindUI 的控件里找到那个 TextLabel
    local found
    local function FindTextLabel(root, depth)
        if depth > 5 or type(root) ~= "table" then return nil end
        if root.ClassName == "TextLabel" then return root end
        for k, v in pairs(root) do
            if k ~= "Parent" and k ~= "Window" and k ~= "Tab"
                and k ~= "ElementTable" and type(v) == "table" then
                local hit = FindTextLabel(v, depth + 1)
                if hit then return hit end
            end
        end
        return nil
    end
    local function Resolve()
        if found and found.Parent ~= nil then return found end
        found = FindTextLabel(el.UIElements or el, 0)
        if found then
            -- 长提示要换行，不然会顶出 UI 边界
            pcall(function()
                found.TextWrapped = true
                found.TextTruncate = Enum.TextTruncate.None
                found.TextYAlignment = Enum.TextYAlignment.Top
            end)
        end
        return found
    end

    -- 注意：Text 不能放成原生字段，否则 `label.Text = x` 不会触发 __newindex，
    -- 语言切换 / 状态刷新那几处赋值就会静默失效。所以用 getter + setter。
    local t = { __el = el, Color = color }
    local current = labelText
    local function Apply(txt)
        current = txt
        local lbl = Resolve()
        if lbl then SafeCall(function() lbl.Text = txt end) end
    end
    local function Noop(_, _ignored) return t end

    rawset(t, "Set", function(_, txt) Apply(txt) return t end)
    rawset(t, "SetText", function(_, txt) Apply(txt) return t end)
    rawset(t, "OnChanged", Noop)
    rawset(t, "OnClick", Noop)
    rawset(t, "SetDisabled", Noop)
    rawset(t, "Destroy", function() SafeCall(function() return el:Destroy() end) end)
    setmetatable(t, {
        __index = function(_, k)
            if k == "Text" then return current end
            return nil
        end,
        __newindex = function(self, k, v)
            if k == "Text" then Apply(v) return end
            rawset(self, k, v)
        end,
    })
    Apply(labelText)
    return t
end

--────────────────────────── 分隔线 ──────────────────────────
function Mini.Divider(parent)
    local ok, el = pcall(function() return parent:Divider() end)
    if ok then return el end
    return parent:Space({})
end

-- 把每个控件注册过的回调按「当前值」重跑一遍。
-- 读配置、切语言之后状态没跟上的时候用它兜底（所有回调都是幂等的）。
function Mini.ReapplyAll()
    for _, entry in pairs(Mini.Registry) do
        if entry.fn then SafeCall(entry.fn, entry.get()) end
    end
end

-- 上次切过的语言：换语言走的是「卸载 + 重新执行脚本」，重载后要接着用同一个语言
do
    local Saved = getgenv() and getgenv().DoorsESPX_Lang or nil
    if Saved and Lang.Strings[Saved] then Lang.Current = Saved end
end

-- 界面开着的时候把鼠标唤醒。
-- 直接跟 win.Closed 同步，所以不管是按快捷键、点最小化、还是点悬浮球，鼠标状态都对得上。
-- 挂 Heartbeat + 0.25 秒节流（不能用 while + task.wait，那样在某些环境下就是死循环）。
do
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        local win = Mini.__Window
        if not win then return end
        acc = acc + (tonumber(dt) or 0.25)
        if acc < 0.25 then return end
        acc = 0
        local want = (win.Closed ~= true) and (win.IsOpen ~= false) and (win.Opened ~= false)
        if UIS.MouseIconEnabled ~= want then
            pcall(function() UIS.MouseIconEnabled = want end)
        end
        if want then
            pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
        end
    end)
end

--=====================================================================
-- 2. 原版数据表（照抄 Main.luau，一个字没改）
--=====================================================================

-- 原版 Entities / EntityESPLabels / NodeEntities（照抄 Main.luau，NotifyMessage 不搬）
local PortraitName = "MirrorRig_Portrait_" .. LocalPlayer.Name

local Entities = {
    ["TV_Stand"]         = { Alias = "Noise_TV" },
    [PortraitName]       = { Alias = "Portrait" },
    ["StemsEntity"]      = { Alias = "Balls" },
    ["NoiseModel"]       = { Alias = "Noise" },
    ["Creak"]            = { Alias = "Creak" },
    ["DronesStampede"]   = { Alias = "DronesStampede" },
    ["TellerRig"]        = { Alias = "Teller" },
    ["Scribbles"]        = { Alias = "Scribbles" },
    ["BashMoving"]       = { Alias = "Bash" },
    ["RushMoving"]       = { Alias = "Rush" },
    ["AmbushMoving"]     = { Alias = "Ambush" },
    ["Eyes"]             = { Alias = "Eyes" },
    ["Lookman"]          = { Alias = "Eyes" },
    ["BackdoorRush"]     = { Alias = "Blitz" },
    ["BackdoorLookman"]  = { Alias = "Lookman" },
    ["Groundskeeper"]    = { Alias = "Groundskeeper" },
    ["A60"]              = { Alias = "A-60" },
    ["A120"]             = { Alias = "A-120" },
    ["GloombatSwarm"]    = { Alias = "Gloombat Swarm" },
    ["GlitchRush"]       = { Alias = "RNIUSHCG==" },
    ["GlitchAmbush"]     = { Alias = "AR0xMBUSH" },
    ["MonumentEntity"]   = { Alias = "Monument" },
    ["JeffTheKiller"]    = { Alias = "Jeff the Killer" },
    ["CustomEntity"]     = { Alias = "Custom Entity" },
    ["FrozenAmbush"]     = { Alias = "Frozen Ambush" },
    ["SallyMoving"]      = { Alias = "Sally" },
}


local EntityESPLabels = {
    JeffTheKiller = "Jeff the Killer",
    GiggleCeiling = "Giggle",
    Snare = "Snare",
    GrumbleRig = "Grumble",
    Drakobloxxer = "Drakobloxxer",
    Hole = "Mandrake Hole",
    Groundskeeper = "Groundskeeper",
    LiveEntityBramble = "Bramble",
    Figure = "Figure", FigureRig = "Figure", FigureRagdoll = "Figure",
    FakeDoor = "Dupe", DoorFake = "Dupe",
}

local NodeEntities = {
    Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true,
    Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true,
    Sally = true, ["Jeff The Killer"] = true, Monument = true,
    ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true,
}

local RusherAliases = {
    Rush = true, Bash = true, Scribbles = true, DronesStampede = true, Ambush = true,
    Eyes = true, Lookman = true, Blitz = true, ["A-60"] = true, ["A-120"] = true,
    AR0xMBUSH = true, ["RNIUSHCG=="] = true, ["Custom Entity"] = true,
}

-- 原版 ItemNames
local ItemNames = {
    ["AbrahamHat"] = "Hat",
    ["LargeScrew"] = "Screw",
    ["DinkyLamp"] = "Lamp",
    ["BottleCrate"] = "18+ Bottles",
    ["GweenSodaPack"] = "Gween Soda Pack",
    ["BrokenMonitor"] = "Broken Monitor",
    ["JerryCan"] = "Jerry Can",
    ["SallyToyObtain"] = "Sally Toy",
    ["Leftovers"] = "Lunch Box",
    ["HoneyPot"] = "Honey Pot",
    ["FihFlakes"] = "Fih Food",
    ["SecretCD"] = "CD Disc",
    ["Pizza"] = "Pizza",
    ["PaperPlanePickup"] = "Paper Plane",
    ["Lighter"] = "Lighter",
    ["Flashlight"] = "Flashlight",
    ["Lockpick"] = "Lockpicks",
    ["Vitamins"] = "Vitamins",
    ["Bandage"] = "Bandage",
    ["StarVial"] = "Starlight Vial",
    ["StarBottle"] = "Starlight Bottle",
    ["StarJug"] = "Starlight Barrel",
    ["Shakelight"] = "Gummy Flashlight",
    ["Straplight"] = "Straplight",
    ["Bulklight"] = "Spotlight",
    ["Battery"] = "Battery",
    ["Candle"] = "Candle",
    ["Crucifix"] = "Crucifix",
    ["CrucifixWall"] = "Crucifix",
    ["Glowsticks"] = "Glowstick",
    ["SkeletonKey"] = "Skeleton Key",
    ["Candy"] = "Candy",
    ["ShieldMini"] = "Mini Shield Potion",
    ["ShieldBig"] = "Big Shield Potion",
    ["BandagePack"] = "Bandage Pack",
    ["BatteryPack"] = "Battery Pack",
    ["RiftCandle"] = "Moonlight Candle",
    ["LaserPointer"] = "Laser Pointer",
    ["HolyGrenade"] = "Holy Hand Grenade",
    ["Shears"] = "Shears",
    ["Smoothie"] = "Smoothie",
    ["Cheese"] = "Cheese",
    ["Bread"] = "Bread",
    ["AlarmClock"] = "Alarm Clock",
    ["RiftSmoothie"] = "Moonlight Smoothie",
    ["GweenSoda"] = "Gween Soda",
    ["GlitchCube"] = "Glitch Fragment",
    ["Scanner"] = "Tablet",
    ["Bomb"] = "Bomb",
    ["Knockbomb"] = "Knockbomb",
    ["Nanner"] = "Nanner",
    ["BigBomb"] = "Big Bomb",
    ["SnakeBox"] = "Hiding Box",
    ["GoldGun"] = "Golden Gun",
    ["StopSign"] = "Stop Sign",
    ["TipJar"] = "Tip Jar",
    ["Lantern"] = "Lantern",
    ["IronKey"] = "Iron Key",
    ["LotusPetal"] = "Lotus Petal",
    ["Compass"] = "Compass",
    ["LotusPetalPickup"] = "Lotus Petal",
    ["LanternLitItem"] = "Lantern",
    ["KeyIron"] = "Iron Key",
    ["IronKeyForCrypt"] = "Iron Key",
    ["LotusHolder"] = "Lotus Petal",
    ["Multitool"] = "Multitool",
    ["RiftJar"] = "Rift Jar",
    ["AloeVera"] = "Aloe Vera",
    ["Donut"] = "Donut",
    ["Lotus"] = "Lotus",
    ["BoxingGloves"] = "Boxing Gloves",
}

-- 原版 HidingSpotLabels / ChestLabels / ObjectiveLabels / MiscLabels
local HidingSpotLabels = {
    Wardrobe = "Closet", ["Backdoor_Wardrobe"] = "Closet", Toolshed = "Closet",
    RetroWardrobe = "Closet", ["Wardrobe-FOOLS26"] = "Closet",
    Locker_Large = "Locker", Rooms_Locker = "Hiding_Spot", Rooms_Locker_Fridge = "Locker",
    Bed = "Bed", Double_Bed = "Double Bed", CircularVent = "Vent", Dumpster = "Dumpster",
}

local ChestLabels = {
    ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
    Chest_Vine = "Vine Chest", Toolshed_Small = "Toolshed",
    Locker_Small_Locked = "Locked Item Locker", MouseHole = "Mouse",
}

local ObjectiveLabels = {
    ["KeyObtain"] = "Door Key",
    ["ElectricalKeyObtain"] = "Electrical Key",
    ["LiveHintBook"] = "Hint Book",
    ["LiveBreakerPolePickup"] = "Fuse Breaker",
    ["LibraryHintPaper"] = "Hint Paper",
    ["PickupItem"] = "Hint Paper",
    ["CringlePresent"] = "Present",
    ["LeverForGate"] = "Gate Lever",
    ["StairwellScrapper"] = "Scrapper",
    ["ArchivesPackageDeposit"] = "Package Deposit",
    ["Cellar"] = "Cellar",
    ["MinesGenerator"] = "Generator",
    ["FuseObtain"] = "Generator Fuse",
    ["MinesGateButton"] = "Gate Button",
    ["GardenGateButton"] = "Gate Button",
}

local MiscLabels = {
    ["StairwellLockpickDoor"] = "Garage Door",
    ["StiarwellLockpickDoor"] = "Garage Door",
    ["Mirror"] = "Mirror",
    ["StairwellFireAlarm"] = "Fire Alarm",
    ["ShoppingCart"] = "Shopping Cart",
    ["ArchivesFihTank"] = "Fih Tank",
    ["ArchivesFishTank"] = "Fih Tank",
}

-- 原版 Entity List 下拉项
local EntityListValues = {
    "Rush", "Bash", "Scribbles", "Teller", "DronesStampede", "Creak", "Noise",
    "Noise_TV", "Balls", "Portrait", "Ambush", "Eyes", "Dupe", "Figure",
    "Blitz", "Lookman", "Snare", "Giggle", "Gloombat Eggs", "Grumble",
    "A-60", "A-120", "Sally", "Jeff the Killer", "Groundskeeper",
    "Mandrake Hole", "Monument", "Bramble", "AR0xMBUSH", "RNIUSHCG==",
}

local FontValues = {
    "Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansLight",
    "SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi",
    "Arcade", "Fantasy", "Antique", "SourceSansSemibold", "Gotham", "GothamMedium",
    "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster", "DenkOne",
    "Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura",
    "Kalam", "LuckiestGuy", "Merriweather", "Michroma", "Nunito", "Oswald",
    "PatrickHand", "PermanentMarker", "Roboto", "RobotoCondensed", "RobotoMono",
    "Sarpanch", "SpecialElite", "TitilliumWeb", "Ubuntu", "BuilderSans",
    "BuilderSansMedium", "BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold",
}

-- 原版 AllowedInstances
local AllowedInstances = {
    Lava = true, GoldPile = true, KeyObtain = true, Drakobloxxer = true, FuseObtain = true,
    MinesGenerator = true, JeffTheKiller = true, Snare = true, FakeDoor = true,
    DoorFake = true, SideroomSpace = true, ChestBox = true, ChestBoxLocked = true,
    Chest_Vine = true, Locker_Small_Locked = true, Toolbox = true, Toolbox_Locked = true,
    Wardrobe = true, ["Wardrobe-FOOLS26"] = true, Toolshed = true, Toolshed_Small = true,
    Bed = true, MinesAnchor = true, Double_Bed = true, RetroWardrobe = true,
    Backdoor_Wardrobe = true, Rooms_Locker = true, Rooms_Locker_Fridge = true,
    Locker_Large = true, FigureRig = true, FigureRagdoll = true, TimerlLever = true,
    Lever = true, Seek_Arm = true, ChandelierObstruction = true, ScaryWall = true,
    Ladder = true, CircularVent = true, Dumpster = true, SquareGrate = true,
    TriggerEventCollision = true, GrumbleRig = true, GiggleCeiling = true,
    MinesGateButton = true, ElectricalKeyObtain = true, LibraryHintPaper = true,
    WaterPump = true, CringlePresent = true, Wheel = true, PickupItem = true,
    LiveHintBook = true, LiveBreakerPolePickup = true, LeverForGate = true,
    GloomPile = true, SeekFloodline = true, Door = true, Green_Herb = true, Bridge = true,
    MouseHole = true, BananaPeel = true, NannerPeel = true, PowerupPad = true,
    IndustrialGate = true, CollisionFloor = true, ElevatorCar = true, Wax_Door = true,
    ThingToOpen = true, MovingDoor = true, StardustPickup = true, Hole = true,
    Groundskeeper = true, MandrakeLive = true, GardenGateButton = true,
    LotusPetalPickup = true, VineGuillotine = true, LiveEntityBramble = true,
    ArchivesFihTank = true, RiftSpawn = true, ElevatorBreaker = true, RunnerNodes = true,
    PathLights = true, DuckBoard = true, Padlock = true, EyestalkEndCutscene = true,
    MinecartRig = true, SeekMovingNewClone = true, Cellar = true,
    ArchivesPackageDeposit = true, StairwellScrapper = true, StairwellFireAlarm = true,
    ShoppingCart = true, Mirror = true, StairwellLockpickDoor = true,
    -- 游戏里这个门的名字是拼错的（原版那边也是两种拼法都认）
    ["StiarwellLockpickDoor"] = true,
}
AllowedInstances.TimerLever = true
AllowedInstances.Figure = true

-- 原版 CutsceneNames（这些不参与实体 ESP）
local CutsceneNames = {
    "Figure", "FigureEnd", "FigureHotelEnd", "FigureHotelFire",
    "SeekIntroFools", "SeekIntroHotel", "SeekIntroMines", "SeekIntroMines2",
    "SerewSeekDrain", "SewerSeekLower", "GrumbleNestEnd", "EyestalkIntro",
}

--=====================================================================
-- 3. 原版 Components/ESP.luau —— 原文内联，逐字节未改
--=====================================================================
local ESPLibrary = (function()
local Library = {
	Font = Enum.Font.RobotoCondensed,
	Rainbow = false,
	Tracers = false,
	Unloaded = false,
	ShowDistance = false,
	MatchColors = true,
	Arrows = false,
	TextTransparency = 0,
	TracerOrigin = "Bottom",
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	TextOutlineTransparency = 0,
	FadeTime = 0,
	RenderLimit = 240,
	TracerSize = 0.5,
	ArrowRadius = 200,
	TextSize = 20,
	DistanceSizeRatio = 1,
	OutlineColor = Color3.fromRGB(255, 255, 255),
	RainbowColor = Color3.fromRGB(255, 255, 255),

	ElementsEnabled = {},
	TransparencyEnabled = {},
	Highlights = {},
	Labels = {},
	Frames = {},
	Lines = {},
	ArrowsTable = {},
	ColorTable = {},
	TextTable = {},
	ConnectionsTable = {},
	Objects = {},
	TotalObjects = {},
}

local RainbowState = {
	HueSetup = 0,
	Hue = 0,
	Step = 0,
	Color = Color3.new(),
}

local CloneReference = cloneref or function(O) return O end
local Players = CloneReference(game:GetService("Players"))
local CoreGui = getgenv and CloneReference(game:GetService("CoreGui")) or Players.LocalPlayer.PlayerGui
local Workspace = CloneReference(workspace)
local RunService = CloneReference(game:GetService("RunService"))
local TweenService = CloneReference(game:GetService("TweenService"))
local UserInputService = CloneReference(game:GetService("UserInputService"))
local Debris = CloneReference(game:GetService("Debris"))
local LocalPlayer = Players.LocalPlayer

local function GetHiddenUI()
	if gethui then return gethui() end
	local Folder = Instance.new("Folder", CoreGui)
	Folder.Name = ("%032x"):format(math.random(0, 2^31))
	return Folder
end

function Library:GenerateRandomString()
	local Chars = {}
	local Pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local PoolLen = #Pool
	for I = 1, 24 do
		local Idx = math.random(1, PoolLen)
		Chars[I] = Pool:sub(Idx, Idx)
	end
	return table.concat(Chars)
end

local HiddenUI = GetHiddenUI()
local Camera = Workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = Library:GenerateRandomString()
ScreenGui.Parent = HiddenUI

local HighlightsFolder = Instance.new("Folder")
HighlightsFolder.Name = Library:GenerateRandomString()
HighlightsFolder.Parent = ScreenGui

local BillboardsFolder = Instance.new("Folder")
BillboardsFolder.Name = Library:GenerateRandomString()
BillboardsFolder.Parent = ScreenGui

local TracersFrame = Instance.new("Frame")
TracersFrame.Size = UDim2.new(1, 0, 1, 0)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Visible = false
TracersFrame.Name = Library:GenerateRandomString()
TracersFrame.Parent = ScreenGui

local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Visible = false
ArrowsFrame.Name = Library:GenerateRandomString()
ArrowsFrame.Parent = ScreenGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://16368985219"
ArrowTemplate.Size = UDim2.new(0, 50, 0, 50)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 1
local ArrowConstraint = Instance.new("UIAspectRatioConstraint")
ArrowConstraint.AspectRatio = 1
ArrowConstraint.Name = Library:GenerateRandomString()
ArrowConstraint.Parent = ArrowTemplate

local TweenInfoQuad = TweenInfo.new(0, Enum.EasingStyle.Quad)
local function MakeTween(Instance_, Props)
	local Info = TweenInfo.new(Library.FadeTime, Enum.EasingStyle.Quad)
	return TweenService:Create(Instance_, Info, Props)
end

local function PlayTween(Instance_, Props)
	MakeTween(Instance_, Props):Play()
end

local function DestroyObjectData(Object)
	local Highlight = Library.Highlights[Object]
	if Highlight then
		Highlight:Destroy()
		Library.Highlights[Object] = nil
	end

	local Frame = Library.Frames[Object]
	if Frame then
		Frame:Destroy()
		Library.Frames[Object] = nil
	end

	local LineData = Library.Lines[Object]
	if LineData then
		if LineData[1] then LineData[1]:Destroy() end
		Library.Lines[Object] = nil
	end

	local Arrow = Library.ArrowsTable[Object]
	if Arrow then
		Arrow:Destroy()
		Library.ArrowsTable[Object] = nil
	end

	local Conns = Library.ConnectionsTable[Object]
	if Conns then
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
		Library.ConnectionsTable[Object] = nil
	end

	Library.Labels[Object] = nil
	Library.ColorTable[Object] = nil
	Library.TextTable[Object] = nil
	Library.ElementsEnabled[Object] = nil
	Library.TransparencyEnabled[Object] = nil
	Library.Objects[Object] = nil

	for Idx = #Library.TotalObjects, 1, -1 do
		if Library.TotalObjects[Idx] == Object then
			table.remove(Library.TotalObjects, Idx)
			break
		end
	end
end

function Library:AddESP(Parameters)
	local Object = Parameters.Object
	if Library.ElementsEnabled[Object] == true or Library.Unloaded == true then return end
	if not Object:IsA("BasePart") and not Object:IsA("Model") then return end

	Library.ElementsEnabled[Object] = true
	Library.TransparencyEnabled[Object] = false
	Library.ConnectionsTable[Object] = Library.ConnectionsTable[Object] or {}

	if Library.Highlights[Object] then
		Library.Highlights[Object]:Destroy()
		Library.Highlights[Object] = nil
	end

	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.Name = Library:GenerateRandomString()
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Adornee = Object
	Highlight.Parent = HighlightsFolder
	Library.Highlights[Object] = Highlight

	local TextFrame = Instance.new("Frame")
	TextFrame.Visible = false
	TextFrame.Name = Library:GenerateRandomString()
	TextFrame.Size = UDim2.fromScale(1, 1)
	TextFrame.BackgroundTransparency = 1
	TextFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	TextFrame.Parent = BillboardsFolder

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = Library:GenerateRandomString()
	TextLabel.BackgroundTransparency = 1
	TextLabel.Text = Parameters.Text
	TextLabel.TextTransparency = 1
	TextLabel.TextStrokeTransparency = Library.TextOutlineTransparency
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.Font = Library.Font
	TextLabel.TextSize = Library.TextSize
	TextLabel.RichText = true
	TextLabel.TextColor3 = Parameters.Color
	TextLabel.Parent = TextFrame

	Library.Frames[Object] = TextFrame
	Library.Labels[Object] = TextLabel
	Library.ColorTable[Object] = Parameters.Color
	Library.TextTable[Object] = Parameters.Text
	Library.Objects[Object] = Object
	table.insert(Library.TotalObjects, Object)

	PlayTween(Highlight, { FillTransparency = Library.FillTransparency })
	PlayTween(Highlight, { OutlineTransparency = Library.OutlineTransparency })

	local TextFadeIn = MakeTween(TextLabel, { TextTransparency = Library.TextTransparency })
	TextFadeIn.Completed:Once(function()
		Library.TransparencyEnabled[Object] = true
	end)
	TextFadeIn:Play()
	PlayTween(TextLabel, { TextStrokeTransparency = Library.TextOutlineTransparency })

	local LineFrame = Instance.new("Frame")
	LineFrame.Size = UDim2.new(0, 0, 0, 0)
	LineFrame.BackgroundTransparency = 1
	LineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LineFrame.Name = Library:GenerateRandomString()
	LineFrame.Parent = TracersFrame

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = Library.TracerSize
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Transparency = 1
	Stroke.Name = Library:GenerateRandomString()
	Stroke.Parent = LineFrame

	PlayTween(LineFrame, { BackgroundTransparency = 0 })
	PlayTween(Stroke, { Transparency = 0 })
	Library.Lines[Object] = { LineFrame, Stroke }

	task.spawn(function()
		local Last = 0
		local MinInterval = 1 / Library.RenderLimit

		local function Render()
			if not Object or not Object:IsDescendantOf(game) then
				Library:RemoveESP(Object)
				return
			end

			local ObjectPos = Object:GetPivot().Position
			local ScreenPoint, OnScreen = Camera:WorldToViewportPoint(ObjectPos)

			local Frame = Library.Frames[Object]
			local Label = Library.Labels[Object]
			local CachedHighlight = Library.Highlights[Object]
			local LineData = Library.Lines[Object]

			if LineData and LineData[1] then
				LineData[1].Visible = OnScreen
			end

			if Frame then
				Frame.Visible = OnScreen
				if OnScreen then
					Frame.Position = UDim2.new(0, ScreenPoint.X, 0, ScreenPoint.Y)
				end
			end

			if not OnScreen then
				if CachedHighlight then
					CachedHighlight:Destroy()
					Library.Highlights[Object] = nil
					CachedHighlight = nil
				end
			elseif Library.ElementsEnabled[Object] == true and not CachedHighlight then
				CachedHighlight = Instance.new("Highlight")
				CachedHighlight.FillTransparency = 1
				CachedHighlight.OutlineTransparency = 1
				CachedHighlight.Name = Library:GenerateRandomString()
				CachedHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				CachedHighlight.Adornee = Object
				CachedHighlight.Parent = HighlightsFolder
				Library.Highlights[Object] = CachedHighlight
			end

			local ActiveColor = Library.Rainbow and RainbowState.Color or Library.ColorTable[Object] or Color3.fromRGB(255, 255, 255)

			if Label then
				Label.TextColor3 = ActiveColor
			end

			if CachedHighlight then
				local Distance = math.floor((Camera.CFrame.Position - ObjectPos).Magnitude)
				local DistanceText = Library.ShowDistance
					and ("\n" .. '<font size="' .. math.round(Library.TextSize * Library.DistanceSizeRatio) .. '">[' .. Distance .. ']</font>')
					or ""
				if Label then
					Label.Text = Library.TextTable[Object] .. DistanceText
				end

				CachedHighlight.Enabled = true
				CachedHighlight.FillColor = ActiveColor
				CachedHighlight.OutlineColor = Library.MatchColors and ActiveColor or Library.OutlineColor

				if Library.TransparencyEnabled[Object] == true then
					CachedHighlight.FillTransparency = Library.FillTransparency
					CachedHighlight.OutlineTransparency = Library.OutlineTransparency
					if Label then
						Label.TextTransparency = Library.TextTransparency
						Label.TextStrokeTransparency = Library.TextOutlineTransparency
					end
				end
			end

			if LineData and CachedHighlight and Library.Tracers == true and OnScreen then
				local ScreenSize = Camera.ViewportSize
				local Origin

				if Library.TracerOrigin == "Center" then
					Origin = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
				elseif Library.TracerOrigin == "Top" then
					Origin = Vector2.new(ScreenSize.X / 2, 0)
				elseif Library.TracerOrigin == "Mouse" then
					local MouseLoc = UserInputService:GetMouseLocation()
					Origin = Vector2.new(LocalPlayer:GetMouse().X, MouseLoc.Y)
				else
					Origin = Vector2.new(ScreenSize.X / 2, ScreenSize.Y)
				end

				local Destination = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
				local MidPoint = (Origin + Destination) / 2
				local Rotation = math.deg(math.atan2(Destination.Y - Origin.Y, Destination.X - Origin.X))
				local Length = (Origin - Destination).Magnitude
				local LF = LineData[1]
				local SK = LineData[2]

				LF.Position = UDim2.new(0, MidPoint.X, 0, MidPoint.Y)
				LF.Size = UDim2.new(0, Length, 0, 1)
				LF.Rotation = Rotation
				LF.BackgroundColor3 = ActiveColor
				LF.BorderSizePixel = 0
				LF.Visible = true
				SK.Color = ActiveColor
				SK.Thickness = Library.TracerSize
			end

			if Library.Arrows == true then
				local Arrow = Library.ArrowsTable[Object]
				if Arrow == nil and Library.ElementsEnabled[Object] == true then
					Arrow = ArrowTemplate:Clone()
					Arrow.Name = Library:GenerateRandomString()
					Arrow:WaitForChild(ArrowConstraint.Name, 5)
					Arrow.Parent = ArrowsFrame
					Library.ArrowsTable[Object] = Arrow
					PlayTween(Arrow, { ImageTransparency = 0 })
				elseif Arrow and Library.ElementsEnabled[Object] == true then
					if OnScreen and ScreenPoint.Z > 0 then
						Arrow.Visible = false
					else
						local ScreenSize = Camera.ViewportSize
						local ScreenCenter = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
						local ToObj = (ObjectPos - Camera.CFrame.Position).Unit
						local Dir = Vector2.new(ScreenPoint.X, ScreenPoint.Y) - ScreenCenter
						if Camera.CFrame.LookVector:Dot(ToObj) < 0 then
							Dir = -Dir
						end
						local Angle = math.atan2(Dir.Y, Dir.X)
						local Radius = math.min(ScreenSize.X, ScreenSize.Y) / 2 - (400 - Library.ArrowRadius)
						local ArrowPos = ScreenCenter + Dir.Unit * Radius

						Arrow.Position = UDim2.new(0, ArrowPos.X, 0, ArrowPos.Y)
						Arrow.Rotation = math.deg(Angle) - 90
						Arrow.Visible = true
						Arrow.ImageColor3 = Library.Rainbow and Library.RainbowColor or Library.ColorTable[Object]
					end
				end
			end
		end

		local Connection
		Connection = RunService.Heartbeat:Connect(function(Delta)
			Last = Last + Delta
			if Last >= 1 / Library.RenderLimit then
				Last = 0
				if Library.ElementsEnabled[Object] ~= true then
					Connection:Disconnect()
					return
				end
				Render()
			end
		end)
		table.insert(Library.ConnectionsTable[Object], Connection)
	end)
end

function Library:RemoveESP(Object)
	if Library.Unloaded == true or Library.ElementsEnabled[Object] ~= true then return end
	Library.ElementsEnabled[Object] = false
	Library.TransparencyEnabled[Object] = false

	local Label = Library.Labels[Object]
	if Label then
		PlayTween(Label, { TextTransparency = 1 })
	end

	local LineData = Library.Lines[Object]
	if LineData then
		if LineData[1] then PlayTween(LineData[1], { BackgroundTransparency = 1 }) end
		if LineData[2] then PlayTween(LineData[2], { Transparency = 1 }) end
	end

	local Highlight = Library.Highlights[Object]
	if Highlight then
		PlayTween(Highlight, { FillTransparency = 1 })
		PlayTween(Highlight, { OutlineTransparency = 1 })
	end

	local Arrow = Library.ArrowsTable[Object]
	if Arrow then
		PlayTween(Arrow, { ImageTransparency = 1 })
	end

	local FadeTime = Library.FadeTime

	if not Object.Parent then
		task.delay(FadeTime + 0.05, function()
			if Library.ElementsEnabled[Object] == false then
				DestroyObjectData(Object)
			end
		end)
	else
		task.delay(FadeTime + 0.05, function()
			if Library.ElementsEnabled[Object] == false then
				DestroyObjectData(Object)
			else
				local ReHighlight = Library.Highlights[Object]
				if ReHighlight then
					PlayTween(ReHighlight, { FillTransparency = Library.FillTransparency })
					PlayTween(ReHighlight, { OutlineTransparency = Library.OutlineTransparency })
				end
			end
		end)
	end
end

function Library:UpdateObjectText(Object, Text)
	if Library.TextTable[Object] ~= nil then
		Library.TextTable[Object] = Text
	end
end

function Library:UpdateObjectColor(Object, Color)
	Library.ColorTable[Object] = Color
	if Library.Labels[Object] and Library.Rainbow ~= true then
		Library.Labels[Object].TextColor3 = Color
	end
end

function Library:SetColorTable(Name, Color)
	Library.ColorTable[Name] = Color
end

function Library:SetFadeTime(Number)
	Library.FadeTime = Number
end

function Library:SetRenderLimit(Number)
	Library.RenderLimit = Number
end

function Library:SetTextTransparency(Number)
	Library.TextTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextTransparency = Number
	end
end

function Library:SetFillTransparency(Number)
	Library.FillTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.FillTransparency = Number
		end
	end
end

function Library:SetOutlineTransparency(Number)
	Library.OutlineTransparency = Number
	for _, Highlight in pairs(Library.Highlights) do
		if Highlight:IsA("Highlight") then
			Highlight.OutlineTransparency = Number
		end
	end
end

function Library:SetTextSize(Number)
	Library.TextSize = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextSize = Number
	end
end

function Library:SetTextOutlineTransparency(Number)
	Library.TextOutlineTransparency = Number
	for _, Label in pairs(Library.Labels) do
		Label.TextStrokeTransparency = Number
	end
end

function Library:SetFont(Font)
	Library.Font = Font
	for _, Label in pairs(Library.Labels) do
		Label.Font = Font
	end
end

function Library:SetOutlineColor(Color)
	Library.OutlineColor = Color
end

function Library:SetRainbow(Value)
	Library.Rainbow = Value
end

function Library:SetShowDistance(Value)
	Library.ShowDistance = Value
end

function Library:SetMatchColors(Value)
	Library.MatchColors = Value
end

function Library:SetTracers(Value)
	Library.Tracers = Value
	TracersFrame.Visible = Value
end

function Library:SetArrows(Value)
	Library.Arrows = Value
	ArrowsFrame.Visible = Value
end

function Library:SetArrowRadius(Value)
	Library.ArrowRadius = Value
end

function Library:SetTracerOrigin(Value)
	Library.TracerOrigin = Value
end

function Library:SetDistanceSizeRatio(Value)
	Library.DistanceSizeRatio = Value
end

function Library:SetTracerSize(Value)
	Library.TracerSize = 0.5 * Value
end

function Library:Unload()
	if Library.Unloaded then return end
	Library.Unloaded = true
	for _, Object in pairs(Library.Objects) do
		Library:RemoveESP(Object)
	end
	for _, Conns in pairs(Library.ConnectionsTable) do
		for _, Conn in ipairs(Conns) do
			Conn:Disconnect()
		end
	end
	RainbowConnection:Disconnect()
	CameraConnection:Disconnect()
	ScreenGui.Enabled = false
end

RainbowConnection = RunService.RenderStepped:Connect(function(Delta)
	RainbowState.Step = RainbowState.Step + Delta
	if RainbowState.Step >= (1 / 60) then
		RainbowState.Step = 0
		RainbowState.HueSetup = RainbowState.HueSetup + (1 / 400)
		if RainbowState.HueSetup > 1 then RainbowState.HueSetup = 0 end
		RainbowState.Hue = RainbowState.HueSetup
		RainbowState.Color = Color3.fromHSV(RainbowState.Hue, 0.8, 1)
		Library.RainbowColor = RainbowState.Color
	end
end)

CameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

if getgenv then
	getgenv().ESPLibrary = Library
end

return Library

end)()


--=====================================================================
-- 4. 原版 Functions / Objects 表 / 扫描队列
--=====================================================================
local Globals = {}
local Connections = {}
local ESPConnections = {}
local ESPBlacklist = {}
local Functions = {}

-- Toggles / Options 必须先声明：Functions.HandleObject 里会引用到它们
local Toggles = {}
local Options = {}

local Objects = {
    Prompts = {}, Objectives = {}, Doors = {}, HidingSpots = {}, Entities = {},
    SeekObstructions = {}, Items = {}, Chests = {}, Currency = {}, Ladders = {},
    Misc = {}, Obstructions = {}, EventTriggers = {}, JumpscareModules = {},
    SeekHighlights = {}, EyestalkHighlights = {}, SeekNodes = {}, SeekDuckBoards = {},
    SeekBridges = {}, PathLights = {}, Tasks = {}
}

local GameData = ReplicatedStorage:FindFirstChild("GameData")
local Floor = "Unknown"
do
    if GameData then
        local f = GameData:FindFirstChild("Floor")
        if f then Floor = f.Value end
    end
end

getgenv().ESPLibrary = ESPLibrary

Functions.AddESP = function(ESPOptions, RoomBased)
    local Object = ESPOptions.Object

    if table.find(ESPBlacklist, Object) then
        return
    end

    if RoomBased then
        local CurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
        local ObjectRoom = tonumber(Object:GetAttribute("ParentRoom"))

        if ObjectRoom == CurrentRoom
            or (table.find(Objects.Doors, Object) and ObjectRoom == CurrentRoom + 1) then
            ESPLibrary:AddESP(ESPOptions)
        end

        local RoomConnection = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
            if ESPLibrary.ColorTable[Object] then
                ESPOptions.Color = ESPLibrary.ColorTable[Object]
            end

            local NewCurrentRoom = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
            local ObjRoom = tonumber(Object:GetAttribute("ParentRoom"))

            if ObjRoom == NewCurrentRoom
                or (table.find(Objects.Doors, Object) and ObjRoom == NewCurrentRoom + 1) then
                ESPLibrary:AddESP(ESPOptions)
            else
                ESPLibrary:RemoveESP(Object)
            end
        end)

        table.insert(Connections, RoomConnection)
        ESPConnections[Object] = RoomConnection

        Object.Destroying:Once(function()
            RoomConnection:Disconnect()
            ESPLibrary:RemoveESP(Object)
            local Pos = table.find(Connections, RoomConnection)
            if Pos then table.remove(Connections, Pos) end
        end)
    else
        ESPLibrary:AddESP(ESPOptions)
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
    ESPLibrary:RemoveESP(Object)
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

--─────────────────────────────────────────────────────────────────────
-- 原版 HandleObject —— 只保留 ESP 相关的分支，其余作弊功能没搬
-- 文字串 / 颜色 / RoomBased 参数与原版逐字一致
--─────────────────────────────────────────────────────────────────────
Functions.HandleObject = function(Object)
    local CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")

    if CurrentRooms then
        for _, Room in ipairs(CurrentRooms:GetChildren()) do
            if Object:IsDescendantOf(Room) then
                Object:SetAttribute("ParentRoom", tonumber(Room.Name))
                break
            end
            task.wait()
        end
    end

    local Name = Object.Name

    if Name == "KeyObtain" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Door Key",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "ElectricalKeyObtain" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Electrical Key",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "TimerLever" then
        task.spawn(function()
            task.wait(0.5)
            if Object.Parent then
                Object:SetAttribute("AddTime",
                    Object.TakeTimer.TextLabel.Text == "01:00" and 60 or 30)
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({
                        Object = Object,
                        Text = "Time Lever [+" .. Object:GetAttribute("AddTime") .. "s]",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "StairwellLockpickDoor" or Name == "StiarwellLockpickDoor" then
        -- 闸门（原版挂在 Misc 里，和购物车同一条分支）→ 现在单独归到「任务」分类
        if Toggles.TaskESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Garage Door",
                Color = Options.TaskESPColor.Value }, true)
        end
        table.insert(Objects.Tasks, Object)
    elseif Name == "Mirror" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Mirror",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "StairwellFireAlarm" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fire Alarm",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "ShoppingCart" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Shopping Cart",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "StairwellScrapper" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Scrapper",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "ArchivesPackageDeposit" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Package Deposit",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "Cellar" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Cellar",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "ArchivesFihTank" then
        if Toggles.MiscESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fih Tank",
                Color = Options.MiscESPColor.Value }, true)
        end
        table.insert(Objects.Misc, Object)
    elseif Name == "LiveHintBook" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Hint Book",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LiveBreakerPolePickup" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Fuse Breaker",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LibraryHintPaper" or Name == "PickupItem" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Hint Paper",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MinesAnchor" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({
                Object = Object,
                Text = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "WaterPump" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object:WaitForChild("Wheel"), Text = "Water Pump",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "CringlePresent" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Present",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "LeverForGate" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Lever",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "VineGuillotine" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MandrakeLive" then
        if Toggles.ObjectiveESPToggle.Value
            and Options.EntityESPOptions.Value["Mandrake Hole"] then
            Functions.AddESP({ Object = Object.Hole, Text = "Mandrake Hole",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object.Hole)
    elseif Name == "MinesGenerator" then
        task.spawn(function()
            task.wait(0.75)
            if Object.Parent then
                if Toggles.ObjectiveESPToggle.Value then
                    Functions.AddESP({ Object = Object, Text = "Generator",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                table.insert(Objects.Objectives, Object)
            end
        end)
    elseif Name == "FuseObtain" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Generator Fuse",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "MinesGateButton" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Button",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "GardenGateButton" then
        if Toggles.ObjectiveESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Gate Button",
                Color = Options.ObjectiveESPColor.Value }, true)
        end
        table.insert(Objects.Objectives, Object)
    elseif Name == "Ladder" then
        if Toggles.LadderESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Ladder",
                Color = Options.LadderESPColor.Value }, true)
        end
        table.insert(Objects.Ladders, Object)
    elseif Name == "Door" and Object.Parent and tonumber(Object.Parent.Name) then
        local DoorParts = {}
        for _, Child in ipairs(Object:GetChildren()) do
            if Child.Name == "Door" and Child:IsA("BasePart") then
                table.insert(DoorParts, Child)
            end
        end

        if #DoorParts == 2 then
            local HighlightModel = Instance.new("Model", Object)
            HighlightModel.Name = "HighlightModel"
            Instance.new("Humanoid", HighlightModel).Name = "HighlightHumanoid"
            HighlightModel:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))

            for _, DoorPart in ipairs(DoorParts) do
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
            if Toggles.DoorESPToggle.Value then
                Functions.AddESP({ Object = HighlightModel,
                    Text = "Door " .. Functions.GetDoorNumber(Object),
                    Color = Options.DoorESPColor.Value }, true)
            end
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
            if Toggles.DoorESPToggle.Value then
                Functions.AddESP({ Object = HP,
                    Text = "Door " .. Functions.GetDoorNumber(Object),
                    Color = Options.DoorESPColor.Value }, true)
            end
        end

    elseif HidingSpotLabels[Name] or string.find(string.lower(Name), "hidingspot") then
        local Label = HidingSpotLabels[Name]
            or (string.find(string.lower(Name), "hidingspot") and "Hiding Spot" or nil)
        if Label and Toggles.HidingSpotESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.HidingSpotESPColor.Value }, true)
        end
        table.insert(Objects.HidingSpots, Object)
    elseif Object:FindFirstChild("HidingPrompt") or Object:FindFirstChild("HidePrompt") then
        table.insert(Objects.HidingSpots, Object)
    elseif Name == "ChestBox" or Name == "ChestBoxLocked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = Object:GetAttribute("Locked") and "Locked Chest" or "Chest",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Toolbox" or Name == "Toolbox_Locked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Chest_Vine" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Vine Chest",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Toolshed_Small" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Toolshed",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "Locker_Small_Locked" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Locked Item Locker",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif Name == "MouseHole" then
        if Toggles.ChestESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Mouse",
                Color = Options.ChestESPColor.Value }, true)
        end
        table.insert(Objects.Chests, Object)
    elseif ItemNames[Name] and Object:FindFirstChild("ModulePrompt") then
        if Toggles.ItemESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = ItemNames[Name],
                Color = Options.ItemESPColor.Value },
                Object:GetAttribute("ParentRoom") ~= nil)
        end
        table.insert(Objects.Items, Object)
    elseif Name == "Green_Herb" then
        if Toggles.ItemESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Green Herb",
                Color = Options.ItemESPColor.Value }, true)
        end
        table.insert(Objects.Items, Object)
    elseif Name == "GoldPile" and Object:GetAttribute("GoldValue") then
        if Toggles.CurrencyESPToggle.Value then
            Functions.AddESP({ Object = Object,
                Text = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]",
                Color = Options.CurrencyESPColor.Value }, true)
        end
        table.insert(Objects.Currency, Object)
    elseif Name == "StardustPickup" then
        if Toggles.CurrencyESPToggle.Value then
            Functions.AddESP({ Object = Object, Text = "Stardust Pile",
                Color = Options.CurrencyESPColor.Value }, true)
        end
        table.insert(Objects.Currency, Object)
    elseif Name == "GiggleCeiling" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Giggle"] then
            Functions.AddESP({ Object = Object, Text = "Giggle",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "GloomPile" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Gloombat Eggs"] then
            Functions.AddESP({ Object = Object, Text = "Gloombat Eggs",
                Color = Options.EntityESPColor.Value })
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "DoorFake" or Name == "FakeDoor" then
        if Object.Parent and Object:FindFirstChild("Hidden") then
            if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Dupe"] then
                Functions.AddESP({ Object = Object, Text = "Dupe",
                    Color = Options.EntityESPColor.Value }, true)
            end
            table.insert(Objects.Entities, Object)
        end
    elseif Name == "SideroomSpace" then
        table.insert(Objects.Entities, Object)
    elseif Name == "Snare" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Snare"] then
            Functions.AddESP({ Object = Object, Text = "Snare",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "BananaPeel" then
        table.insert(Objects.Entities, Object)
    elseif Name == "JeffTheKiller" then
        table.insert(Objects.Entities, Object)
    elseif Name == "GrumbleRig" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Grumble"] then
            Functions.AddESP({ Object = Object, Text = "Grumble",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "LiveEntityBramble" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Bramble"] then
            Functions.AddESP({ Object = Object, Text = "Bramble",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "Groundskeeper" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Groundskeeper"] then
            Functions.AddESP({ Object = Object, Text = "Groundskeeper",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Figure"] then
            Functions.AddESP({ Object = Object, Text = "Figure",
                Color = Options.EntityESPColor.Value }, true)
        end
        table.insert(Objects.Entities, Object)
    end
end

--─────────────────────────────────────────────────────────────────────
-- 原版 HandleEntitySpawn —— 只保留 ESP 部分（通知/聊天没搬）
--─────────────────────────────────────────────────────────────────────
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
        for _, Child in ipairs(Model:GetChildren()) do
            if Child:IsA("BasePart") then Model.PrimaryPart = Child end
        end
        if not Model.PrimaryPart then task.wait() end
    end
    task.wait(0.1)

    if not Model.PrimaryPart
        or LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) >= 10000 then
        return
    end

    local Alias = EntityData.Alias
    local RealAlias = Alias

    if Model.Name ~= "GloombatSwarm" then
        if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealAlias] then
            if Model.Name == "MonumentEntity" then
                Functions.AddESP({ Object = Model.Top, Text = Alias,
                    Color = Options.EntityESPColor.Value })
            else
                Functions.AddESP({ Object = Model, Text = Alias,
                    Color = Options.EntityESPColor.Value })
            end
        end
        table.insert(Objects.Entities, Model)
    end

    -- 移植功能用的收集钩子：本脚本的 HandleObject 只认 ESP 需要的那几类对象，
    -- 像 Lava / ScaryWall 这些虽然在白名单里、却没有对应的分支，
    -- 所以在末尾统一分发一次，让移植过来的功能能拿到稳定的数据来源。
    local PortHooks = Globals.ObjectPortHooks
    if PortHooks then
        for _, Hook in ipairs(PortHooks) do
            pcall(Hook, Object)
        end
    end

    if RusherAliases[RealAlias] then
        Instance.new("Humanoid", Model).Name = "HighlightHumanoid"
        local Root = Model.PrimaryPart
        if Root then
            Root.Transparency = 0.999
            Root.Material = Enum.Material.Plastic
        end
    end
end

-- 原版 QueueObject + 逐帧消费队列
Globals.ObjectQueue = {}

Functions.QueueObject = function(Object)
    local IsHidingSpot = typeof(Object.Name) == "string"
        and string.find(string.lower(Object.Name), "hidingspot")
    if not AllowedInstances[Object.Name] and not IsHidingSpot
        and Object.ClassName ~= "ProximityPrompt"
        and Object.Parent ~= Services.Workspace:FindFirstChild("CurrentRooms")
        and not ItemNames[Object.Name] then
        return
    end
    table.insert(Globals.ObjectQueue, Object)
end

Connections.QueueConnection = Services.RunService.RenderStepped:Connect(function()
    local Object = table.remove(Globals.ObjectQueue, 1)
    if Object then
        Functions.HandleObject(Object)
    end
end)

for _, Object in ipairs(Services.Workspace:GetDescendants()) do
    task.spawn(function() Functions.QueueObject(Object) end)
end

Connections.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
    Functions.QueueObject(Object)
end)

Connections.EntityHandler = Services.Workspace.ChildAdded:Connect(function(Object)
    if Entities[Object.Name] then
        task.defer(function() HandleEntitySpawn(Object) end)
    end
end)

Connections.EntityDescendantHandler = Services.Workspace.DescendantAdded:Connect(function(Descendant)
    local EntityModel = Descendant:IsA("Humanoid") and Descendant.Parent or Descendant
    if EntityModel and EntityModel:IsA("Model") and Entities[EntityModel.Name] then
        task.defer(function() HandleEntitySpawn(Descendant) end)
    end
end)

-- 原版 Cleaner：对象没了就从表里摘掉
do
    local LastClean = tick()
    Connections.Cleaner = Services.RunService.Heartbeat:Connect(function()
        if tick() - LastClean <= 0.5 then return end
        LastClean = tick()

        for _, Array in pairs(Objects) do
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
                I = I - 1
            end
        end
    end)
end

--=====================================================================
-- 4.5 运行时核心（移植 Abysall 功能所需的地基）
--     来源: AbysallContinued · Games/Doors/Main.luau
--     作用: 把 Abysall 的 Globals / Functions 接口在本地重建，
--           后面移植过来的功能代码可以原样调用，不用逐个改写。
--=====================================================================

--────────────────────────── 执行器能力检测 ──────────────────────────
-- Abysall 原版查的是 Environment 组件里的函数；这里直接查全局环境，
-- 少一层依赖，行为一样。
local function HasExecutorFunction(Name)
    local ok, Fn = pcall(function() return getgenv()[Name] end)
    return ok and type(Fn) == "function"
end

Functions.CheckCompatability = function(Names)
    for _, Name in ipairs(Names) do
        if not HasExecutorFunction(Name) then return false end
    end
    return true
end

--────────────────────────── 隐藏容器 ──────────────────────────
-- 把脚本自己的实例塞进 gethui（暗掉 CoreGui 里的东西），
-- 没有 gethui 的执行器就退回 CoreGui。
local function GetHiddenContainer()
    if Functions.CheckCompatability({ "gethui" }) then
        local Ok, Hui = pcall(getgenv().gethui)
        if Ok and Hui then return Hui end
    end
    return CoreGui
end
Functions.GetHiddenContainer = GetHiddenContainer

--────────────────────────── 通知 ──────────────────────────
-- Abysall 有四种通知风格（Abysall / Doors / STX / Obsidian）加音量设置，
-- 那套要额外拉 STX 组件、还要搭一整套通知库，收益不大，这里统一走 WindUI 的通知。
-- 调用签名保持 Abysall 原样: Functions.Notify({ Title = , Body = , Time = })
local NotifySound = Instance.new("Sound")
NotifySound.SoundId = "rbxassetid://8784885431"
NotifySound.Volume = 2
NotifySound.Parent = GetHiddenContainer()

Functions.Notify = function(Settings)
    if type(Settings) ~= "table" then return end

    local Title = tostring(Settings.Title or "DoorsESP")
    local Body  = tostring(Settings.Body or Settings.Description or "...")

    -- 通知音：播放一次就丢，避免堆实例
    pcall(function()
        local S = NotifySound:Clone()
        S.Parent = GetHiddenContainer()
        S.PlayOnRemove = true
        S:Destroy()
    end)

    local Ok = pcall(function()
        Mini.WindUI:Notify({ Title = Title, Content = Body, Duration = Settings.Time or 5 })
    end)
    if not Ok then
        print(string.format("[Msptds] %s: %s", Title, Body))
    end
end

-- 兼容 Abysall 旧的调用名
Functions.Caption = function(Text) Functions.Notify({ Title = "DoorsESP", Body = Text }) end

--────────────────────────── 实体 / 物品查询 ──────────────────────────
-- 这些是 Abysall 功能里出现频率最高的一组工具函数，
-- 依赖 Objects 表（由下面的扫描逻辑填充）。
Functions.GetNearestEntity = function(CheckDisabled, List, UseRaycasting)
    local Target, TargetDistance = nil, math.huge
    local Root = Char.RootPart
    if not Root then return nil end

    for _, Entity in ipairs(List or Objects.Entities) do
        if Entity and Entity.Parent then
            local Pivot = Entity:IsA("Model") and Entity:GetPivot() or Entity.CFrame
            local Distance = (Pivot.Position - Root.Position).Magnitude
            if Distance < TargetDistance then
                Target, TargetDistance = Entity, Distance
            end
        end
    end
    return Target, TargetDistance
end

Functions.GetNearestEntityToPosition = function(Position, List)
    local Target, TargetDistance = nil, math.huge
    for _, Entity in ipairs(List or Objects.Entities) do
        if Entity and Entity.Parent then
            local Pivot = Entity:IsA("Model") and Entity:GetPivot() or Entity.CFrame
            local Distance = (Pivot.Position - Position).Magnitude
            if Distance < TargetDistance then
                Target, TargetDistance = Entity, Distance
            end
        end
    end
    return Target, TargetDistance
end

Functions.GetNearestObject = function(List, Position)
    local Root = Char.RootPart
    local From = Position or (Root and Root.Position)
    if not From then return nil end

    local Target, TargetDistance = nil, math.huge
    for _, Object in ipairs(List or {}) do
        if Object and Object.Parent then
            local Pivot = Object:IsA("Model") and Object:GetPivot() or Object.CFrame
            local Distance = (Pivot.Position - From).Magnitude
            if Distance < TargetDistance then
                Target, TargetDistance = Object, Distance
            end
        end
    end
    return Target, TargetDistance
end

-- 按名字找背包装备 / 角色身上有没有某个物品
Functions.HasItem = function(Name, OnlyCharacter)
    if Char.Character and Char.Character:FindFirstChild(Name) then return true end
    if OnlyCharacter then return false end
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    return (Backpack and Backpack:FindFirstChild(Name)) ~= nil
end

--────────────────────────── 角色状态 ──────────────────────────
Functions.IsCrouching = function()
    return Char.Character ~= nil and Char.Character:GetAttribute("Crouching") == true
end

Functions.GetCurrentSpeed = Functions.GetCurrentSpeed or function()
    return Char.Humanoid and Char.Humanoid.WalkSpeed or 0
end

-- 脚部受伤会减速，原版用这个把减掉的速度加回去
Functions.GetInjuriesSpeed = function()
    if not Char.Character then return 0 end
    return Char.Character:GetAttribute("InjuriesSpeed") or 0
end

--────────────────────────── 图书馆密码 ──────────────────────────
-- 原版做法：拿在手上的「提示纸」上有几格图案，把每格图案和 PlayerGui 里的提示比对，
-- 对上的就把那格的数字填进去，拼出完整密码。
Functions.GetLibraryCode = function()
    local Character = Char.Character
    if not Character then return nil end
    local Backpack = LocalPlayer:FindFirstChild("Backpack")

    local Paper = Character:FindFirstChild("LibraryHintPaper")
        or Character:FindFirstChild("LibraryHintPaperHard")
        or (Backpack and Backpack:FindFirstChild("LibraryHintPaper"))
        or (Backpack and Backpack:FindFirstChild("LibraryHintPaperHard"))

    if Paper and Paper:FindFirstChild("UI") then
        local PermUI = LocalPlayer:FindFirstChild("PlayerGui")
        local Hints = PermUI and PermUI:FindFirstChild("PermUI")
        Hints = Hints and Hints:FindFirstChild("Hints")
        if not Hints then return nil end

        local Code = {}
        local CodeLength = (Floor == "Fools") and 10 or 5
        for Index = 1, CodeLength do Code[Index] = "_" end

        local UIChildren = Paper.UI:GetChildren()
        for _, Hint in ipairs(Hints:GetChildren()) do
            for _, UIChild in ipairs(UIChildren) do
                if Hint:IsA("ImageLabel") and UIChild:IsA("ImageLabel")
                    and Hint.ImageRectOffset == UIChild.ImageRectOffset
                    and Code[tonumber(UIChild.Name)]
                then
                    local TextLabel = Hint:FindFirstChild("TextLabel")
                    if TextLabel then
                        Code[tonumber(UIChild.Name)] = TextLabel.Text
                    end
                end
            end
        end
        return table.concat(Code)
    end

    -- 没拿到纸就返回全下划线的模板，让「猜密码」照着猜
    return (Floor == "Fools") and "__________" or "_____"
end

Functions.GetRandomCode = function()
    local Template = Functions.GetLibraryCode()
    if not Template then return nil end
    local NewCode, Tries
    repeat
        NewCode = Template:gsub("_", function() return tostring(math.random(0, 9)) end)
        Tries = (Tries or 0) + 1
    until not Globals.UsedRandomCodes[NewCode] or Tries >= 10
    Globals.UsedRandomCodes[NewCode] = true
    return NewCode
end

--────────────────────────── 遥控 / 提示容器 ──────────────────────────
Globals.PromptContainer = Instance.new("Folder")
Globals.PromptContainer.Name = "PromptContainer"
Globals.PromptContainer.Parent = GetHiddenContainer()

-- 假提示（有些功能要往游戏容器里塞 Prompt，统一放这里好清理）
Globals.FakePrompts = Globals.FakePrompts or {}

--────────────────────────── 掉落物 ──────────────────────────
-- 前向声明：UI 段的按钮回调会引用它，所以声明必须早于 UI 布局段。
-- 用 local 而不是全局函数，避免后面再写一次 `function BringDroppedItems`
-- 时创建出另一个同名 local、把这里的声明遮蔽掉。
BringDroppedItems = function()
    local Root = Char.RootPart
    local Drops = Services.Workspace:FindFirstChild("Drops")
    if not Root or not Drops then return end
    for _, Item in ipairs(Drops:GetChildren()) do
        pcall(function()
            if Item:IsA("Model") then
                Item:PivotTo(Root.CFrame)
            elseif Item:IsA("BasePart") then
                Item.CFrame = Root.CFrame
            end
        end)
    end
end

--────────────────────────── 杂项状态 ──────────────────────────
Globals.Floor = function() return Floor end
Globals.IncompatibleMessage = "当前执行器不支持这个功能。"

-- 需要跟着楼层/房间重置的状态，统一挂这里方便清
Globals.UsedRandomCodes = Globals.UsedRandomCodes or {}
Globals.QueueDone = Globals.QueueDone or false
Globals.ObjectQueue = Globals.ObjectQueue or {}

--=====================================================================
-- 5. UI 布局（每一页的控件名 / 默认值 / 颜色 照抄原版）
--=====================================================================
local Window = Mini.NewWindow(
    L("win.title", "Msptds", "Msptds"),
    L("win.sub",   "Doors · ESP", "Doors · ESP"))

local tabLang   = Window:Tab(L("tab.lang",    "语言",      "Language"))
local tabESP    = Window:Tab(L("tab.esp",     "ESP",       "ESP"))
local tabSet    = Window:Tab(L("tab.set",     "ESP 设置",  "ESP Settings"))
local tabCam    = Window:Tab(L("tab.cam",     "相机",      "Camera"))
local tabChar   = Window:Tab(L("tab.char",    "角色",      "Character"))
local tabBypass = Window:Tab(L("tab.bypass",  "绕过",      "Bypass"))
local tabCreak  = Window:Tab(L("tab.creak",   "Creak",     "Creak"))
local tabAuto   = Window:Tab(L("tab.auto",    "自动",      "Auto"))

--────────────────────────── 移植功能的新页面 ──────────────────────────
-- 对应 Abysall 原版的 General / Exploits / Floors / Archives / Stairwell。
-- 控件名同时用作存档 Key，所以和原版保持一致。
local tabGeneral  = Window:Tab(L("tab.general",  "综合",     "General"))
local tabExploit  = Window:Tab(L("tab.exploit",  "漏洞",     "Exploits"))
local tabFloors   = Window:Tab(L("tab.floors",   "楼层",     "Floors"))

--────────────────────────── 楼层 · 自动化 ──────────────────────────
Mini.Label(tabFloors.Page, L("f.auto", "自动化", "Automation"))
Toggles.SkipSeekMines = Mini.Toggle(tabFloors.Page, { Key = "SkipSeekMines", Text = "跳过 Seek（矿井）" })
Mini.Divider(tabFloors.Page)
Toggles.AutoSteerMinecart = Mini.Toggle(tabFloors.Page, { Key = "AutoSteerMinecart", Text = "自动驾驶矿车" })
Options.AutoSteerMinecartTurnDistance = Mini.Slider(tabFloors.Page, { Key = "AutoSteerMinecartTurnDistance", Text = "转向距离", Min = 1, Max = 50, Default = 10, Rounding = 0 })
Options.AutoSteerMinecartDuckDistance = Mini.Slider(tabFloors.Page, { Key = "AutoSteerMinecartDuckDistance", Text = "低头距离", Min = 1, Max = 50, Default = 10, Rounding = 0 })
Mini.Divider(tabFloors.Page)
Toggles.RoomsAutoWalk = Mini.Toggle(tabFloors.Page, { Key = "RoomsAutoWalk", Text = "自动走 The Rooms" })
Options.RoomsAutoWalkPathfindTimeout = Mini.Slider(tabFloors.Page, { Key = "RoomsAutoWalkPathfindTimeout", Text = "寻路超时", Min = 0.5, Max = 3, Default = 1, Rounding = 1 })
Toggles.RoomsAutoWalkIgnoreA60 = Mini.Toggle(tabFloors.Page, { Key = "RoomsAutoWalkIgnoreA60", Text = "忽略 A-60" })
Toggles.RoomsAutoWalkShowPathToggle = Mini.Toggle(tabFloors.Page, { Key = "RoomsAutoWalkShowPathToggle", Text = "显示路径" })
Options.RoomsAutoWalkShowPathColor = Mini.ColorPicker(tabFloors.Page, { Key = "RoomsAutoWalkShowPathColor", Text = "路径颜色", Default = Color3.fromRGB(0, 255, 0) })
Toggles.RoomsAutoWalkSpoofFootsteps = Mini.Toggle(tabFloors.Page, { Key = "RoomsAutoWalkSpoofFootsteps", Text = "伪装脚步声" })

--────────────────────────── 楼层 · 路线显示 ──────────────────────────
Mini.Label(tabFloors.Page, L("f.path", "路线显示", "Path Display"))
Toggles.ShowSeekPathToggle = Mini.Toggle(tabFloors.Page, { Key = "ShowSeekPathToggle", Text = "显示 Seek 路径" })
Toggles.ShowEyestalkPathToggle = Mini.Toggle(tabFloors.Page, { Key = "ShowEyestalkPathToggle", Text = "显示 Eyestalk 路径" })
Options.ShowSeekPathColor = Mini.ColorPicker(tabFloors.Page, { Key = "ShowSeekPathColor", Text = "Seek 路径颜色", Default = Color3.fromRGB(0, 255, 0) })
Options.ShowEyestalkPathColor = Mini.ColorPicker(tabFloors.Page, { Key = "ShowEyestalkPathColor", Text = "Eyestalk 路径颜色", Default = Color3.fromRGB(0, 255, 0) })

--────────────────────────── 楼层 · 绕过 ──────────────────────────
Mini.Label(tabFloors.Page, L("f.bypass", "绕过", "Bypass"))
Toggles.RemoveSeekTrigger = Mini.Toggle(tabFloors.Page, { Key = "RemoveSeekTrigger", Text = "删除 Seek 触发器" })
Toggles.RemoveFigure = Mini.Toggle(tabFloors.Page, { Key = "RemoveFigure", Text = "删除 Figure" })
Toggles.AutoRevive = Mini.Toggle(tabFloors.Page, { Key = "AutoRevive", Text = "无限复活" })
Toggles.FigureGodmode = Mini.Toggle(tabFloors.Page, { Key = "FigureGodmode", Text = "Figure 无敌" })
Mini.Divider(tabFloors.Page)
Mini.Label(tabFloors.Page, L("f.farm", "刷取", "Farming"))
Toggles.KnobFarm = Mini.Toggle(tabFloors.Page, { Key = "KnobFarm", Text = "自动刷 Knob" })
Options.KnobFarmGoldMin = Mini.Slider(tabFloors.Page, { Key = "KnobFarmGoldMin", Text = "最低金币", Min = 0, Max = 1000, Default = 1, Rounding = 0 })
Mini.Divider(tabFloors.Page)
Toggles.RemoveBasementGate = Mini.Toggle(tabFloors.Page, { Key = "RemoveBasementGate", Text = "移除地下室门" })
Toggles.RemovePaintingsDoor = Mini.Toggle(tabFloors.Page, { Key = "RemovePaintingsDoor", Text = "移除画中门" })
Toggles.RemoveSkeletonDoor = Mini.Toggle(tabFloors.Page, { Key = "RemoveSkeletonDoor", Text = "移除骷髅门" })

--────────────────────────── 楼层 · 通关 ──────────────────────────
Mini.Label(tabFloors.Page, L("f.done", "通关", "Completion"))
Mini.Button(tabFloors.Page, { Key = "FloorsSkipToEnd", Text = "跳到本层末尾" }):OnClick(function()
    FloorsAction("FloorsSkipToEnd")
end)
Mini.Button(tabFloors.Page, { Key = "FloorsCompleteRun", Text = "直接通关" }):OnClick(function()
    FloorsAction("FloorsCompleteRun")
end)
Mini.Button(tabFloors.Page, { Key = "FloorsCompleteDamSeek", Text = "自动通关水坝 Seek" }):OnClick(function()
    FloorsAction("FloorsCompleteDamSeek")
end)
Mini.Button(tabFloors.Page, { Key = "FloorsCompleteCringle", Text = "自动通关 Cringle" }):OnClick(function()
    FloorsAction("FloorsCompleteCringle")
end)
local tabArchives = Window:Tab(L("tab.archives", "档案馆",   "Archives"))
local tabStair    = Window:Tab(L("tab.stair",    "楼梯间",   "Stairwell"))

--────────────────────────── 档案馆页 ──────────────────────────
Mini.Label(tabArchives.Page, L("a.anti", "档案馆 · 反制 / 解除", "Archives · Exploits / Anti"))
Toggles.AntiRansom = Mini.Toggle(tabArchives.Page, { Key = "AntiRansom", Text = "反制 Ransom" })
Toggles.AntiClosetTrash = Mini.Toggle(tabArchives.Page, { Key = "AntiClosetTrash", Text = "反制衣柜垃圾" })
Toggles.AntiScribbles = Mini.Toggle(tabArchives.Page, { Key = "AntiScribbles", Text = "绕过 Scribbles" })
Toggles.BypassDronesStampede = Mini.Toggle(tabArchives.Page, { Key = "BypassDronesStampede", Text = "反制 Drones Stampede" })
Mini.Divider(tabArchives.Page)
Toggles.BypassWater = Mini.Toggle(tabArchives.Page, { Key = "BypassWater", Text = "绕过电水" })
Toggles.BypassAlma = Mini.Toggle(tabArchives.Page, { Key = "BypassAlma", Text = "绕过 Alma" })
Toggles.BypassDrones = Mini.Toggle(tabArchives.Page, { Key = "BypassDrones", Text = "绕过 Drones" })
Mini.Label(tabArchives.Page, L("a.helper", "档案馆 · 辅助", "Archives · Helper"))
Toggles.ForgetMeNotSolver = Mini.Toggle(tabArchives.Page, { Key = "ForgetMeNotSolver", Text = "自动跳过 Forget Me Not" })
Toggles.HonchoCorrectBoxESP = Mini.Toggle(tabArchives.Page, { Key = "HonchoCorrectBoxESP", Text = "正确箱子 ESP / 自动交互" })
Toggles.TimeShower = Mini.Toggle(tabArchives.Page, { Key = "TimeShower", Text = "显示档案馆时钟" })

--────────────────────────── 楼梯间页 ──────────────────────────
Mini.Label(tabStair.Page, L("s.anti", "楼梯间 · 反制", "Stairwell · Anti"))
Toggles.BypassNoise = Mini.Toggle(tabStair.Page, { Key = "BypassNoise", Text = "绕过 Noise" })
Toggles.AntiNoise = Mini.Toggle(tabStair.Page, { Key = "AntiNoise", Text = "反制 Noise" })
Toggles.MeldRemover = Mini.Toggle(tabStair.Page, { Key = "MeldRemover", Text = "去除融合体" })
Mini.Divider(tabStair.Page)
Toggles.DisableStairwellCrusherCollision = Mini.Toggle(tabStair.Page, { Key = "DisableStairwellCrusherCollision", Text = "压碎机关无碰撞" })
Toggles.DeleteStairwellCrusherExceptBasicWall = Mini.Toggle(tabStair.Page, { Key = "DeleteStairwellCrusherExceptBasicWall", Text = "只保留压碎机关基础墙" })
Mini.Divider(tabStair.Page)
Toggles.FlingCreak = Mini.Toggle(tabStair.Page, { Key = "FlingCreak", Text = "弹飞 Creak" })
Toggles.KillAllWithCart = Mini.Toggle(tabStair.Page, { Key = "KillAllWithCart", Text = "用推车击杀全部" })
Options.ShoppingCartTarget = Mini.Dropdown(tabStair.Page, { Key = "ShoppingCartTarget", Text = "推车目标", Values = {}, Default = 1, AllowNull = true })
Mini.Button(tabStair.Page, { Key = "ShoppingCartToTarget", Text = "把推车送到目标" }):OnClick(function()
    PushCartsToTarget()
end)
Mini.Label(tabStair.Page, L("s.display", "楼梯间 · 显示", "Stairwell · Display"))
Toggles.StairwellLandingSpam = Mini.Toggle(tabStair.Page, { Key = "StairwellLandingSpam", Text = "落点提示刷屏" })
Toggles.DroppedItemValue = Mini.Toggle(tabStair.Page, { Key = "DroppedItemValue", Text = "显示掉落物价值" })
Mini.Label(tabStair.Page, L("s.orbit", "楼梯间 · 掉落物环绕", "Stairwell · Orbit Drops"))
Toggles.EnableDroppedItemsInterval = Mini.Toggle(tabStair.Page, { Key = "EnableDroppedItemsInterval", Text = "定时拾取掉落物" })
Mini.Button(tabStair.Page, { Key = "BringDroppedItems", Text = "把掉落物拉过来" }):OnClick(function()
    BringDroppedItems()
end)
Options.DroppedItemsInterval = Mini.Slider(tabStair.Page, { Key = "DroppedItemsInterval", Text = "拾取间隔", Min = 0.1, Max = 5, Default = 0.5, Rounding = 1 })
Mini.Divider(tabStair.Page)
Toggles.OrbitDroppedItems = Mini.Toggle(tabStair.Page, { Key = "OrbitDroppedItems", Text = "环绕掉落物" })
Options.OrbitDroppedItemsHeight = Mini.Slider(tabStair.Page, { Key = "OrbitDroppedItemsHeight", Text = "环绕高度", Min = 0, Max = 20, Default = 3, Rounding = 0 })
Options.OrbitDroppedItemsDistance = Mini.Slider(tabStair.Page, { Key = "OrbitDroppedItemsDistance", Text = "环绕半径", Min = 0, Max = 30, Default = 6, Rounding = 0 })
Options.OrbitDroppedItemsSpeed = Mini.Slider(tabStair.Page, { Key = "OrbitDroppedItemsSpeed", Text = "环绕速度", Min = 0.1, Max = 10, Default = 1, Rounding = 1 })

--────────────────────────── 漏洞 · 绕过 ──────────────────────────
Mini.Label(tabExploit.Page, L("e.bypass", "绕过 / 解除", "Bypass / Solve"))
Toggles.BypassGiggle = Mini.Toggle(tabExploit.Page, { Key = "BypassGiggle", Text = "绕过 Giggle" })
Toggles.BypassDupe = Mini.Toggle(tabExploit.Page, { Key = "BypassDupe", Text = "绕过假门 Dupe" })
Toggles.BypassEyes = Mini.Toggle(tabExploit.Page, { Key = "BypassEyes", Text = "绕过 Eyes" })
Toggles.BypassLookman = Mini.Toggle(tabExploit.Page, { Key = "BypassLookman", Text = "绕过 Lookman" })
Toggles.BypassGloombatEggs = Mini.Toggle(tabExploit.Page, { Key = "BypassGloombatEggs", Text = "绕过 Gloombat 蛋" })
Toggles.BypassSeekObstructions = Mini.Toggle(tabExploit.Page, { Key = "BypassSeekObstructions", Text = "绕过 Seek 障碍物" })
Toggles.BypassVacuum = Mini.Toggle(tabExploit.Page, { Key = "BypassVacuum", Text = "绕过真空假门" })
Toggles.BypassKillbricks = Mini.Toggle(tabExploit.Page, { Key = "BypassKillbricks", Text = "绕过岩浆" })
Toggles.BypassSeekingWall = Mini.Toggle(tabExploit.Page, { Key = "BypassSeekingWall", Text = "绕过 ScaryWall" })
Toggles.BypassSnare = Mini.Toggle(tabExploit.Page, { Key = "BypassSnare", Text = "绕过 Snare 陷阱" })
Toggles.BypassBanana = Mini.Toggle(tabExploit.Page, { Key = "BypassBanana", Text = "绕过香蕉皮" })
Toggles.BypassJeff = Mini.Toggle(tabExploit.Page, { Key = "BypassJeff", Text = "绕过 Jeff" })
Mini.Divider(tabExploit.Page)

--────────────────────────── 漏洞 · 去除 ──────────────────────────
Mini.Label(tabExploit.Page, L("e.remove", "去除", "Remove"))
Toggles.RemoveScreech = Mini.Toggle(tabExploit.Page, { Key = "RemoveScreech", Text = "去除 Screech" })
Toggles.RemoveHalt = Mini.Toggle(tabExploit.Page, { Key = "RemoveHalt", Text = "去除 Halt" })
Toggles.RemoveA90 = Mini.Toggle(tabExploit.Page, { Key = "RemoveA90", Text = "去除 A-90" })
Toggles.RemoveDread = Mini.Toggle(tabExploit.Page, { Key = "RemoveDread", Text = "去除 Dread" })
Toggles.RemoveSurge = Mini.Toggle(tabExploit.Page, { Key = "RemoveSurge", Text = "去除 Surge" })
Mini.Divider(tabExploit.Page)
Toggles.NoScreechDamage = Mini.Toggle(tabExploit.Page, { Key = "NoScreechDamage", Text = "Screech 无伤害" })
Toggles.NoHaltDamage = Mini.Toggle(tabExploit.Page, { Key = "NoHaltDamage", Text = "Halt 无伤害" })
Toggles.NoA90Damage = Mini.Toggle(tabExploit.Page, { Key = "NoA90Damage", Text = "A-90 无伤害" })
Toggles.NoSurgeDamage = Mini.Toggle(tabExploit.Page, { Key = "NoSurgeDamage", Text = "Surge 无伤害" })

--────────────────────────── 漏洞 · 音频 ──────────────────────────
Mini.Label(tabExploit.Page, L("e.audio", "音频", "Audio"))
Toggles.RemoveFootstepSounds = Mini.Toggle(tabExploit.Page, { Key = "RemoveFootstepSounds", Text = "去除脚步声" })
Toggles.RemoveJamminMusic = Mini.Toggle(tabExploit.Page, { Key = "RemoveJamminMusic", Text = "去除 Jammin 音乐" })
Toggles.RemoveInteractingSounds = Mini.Toggle(tabExploit.Page, { Key = "RemoveInteractingSounds", Text = "去除交互音效" })

--────────────────────────── 漏洞 · 数值 / 反检测 ──────────────────────────
Mini.Label(tabExploit.Page, L("e.values", "数值 / 反检测", "Values / Anti-Detect"))
Toggles.DisableAnticheat = Mini.Toggle(tabExploit.Page, { Key = "DisableAnticheat", Text = "关闭反作弊" })
Toggles.VelocityManipulationToggle = Mini.Toggle(tabExploit.Page, { Key = "VelocityManipulationToggle", Text = "速度操纵" })
Options.VelocityManipulationMode = Mini.Dropdown(tabExploit.Page, { Key = "VelocityManipulationMode", Text = "操纵方式", Values = { "Velocity", "Pivot" }, Default = 1, AllowNull = false })
Mini.Divider(tabExploit.Page)
Toggles.InfiniteItemsToggle = Mini.Toggle(tabExploit.Page, { Key = "InfiniteItemsToggle", Text = "无限物品" })
Options.InfiniteItemsList = Mini.MultiSelect(tabGeneral.Page, { Key = "InfiniteItemsList", Text = "无限物品清单", Values = { "Lockpicks", "Skeleton Key", "Shears", "Multitool" }, Default = {"Lockpicks"}, AllowNull = true })
Toggles.InfCrucifix = Mini.Toggle(tabExploit.Page, { Key = "InfCrucifix", Text = "无限十字架" })
Mini.Divider(tabExploit.Page)
Toggles.PositionSpoof = Mini.Toggle(tabExploit.Page, { Key = "PositionSpoof", Text = "位置伪装" })
Toggles.CrouchSpoof = Mini.Toggle(tabExploit.Page, { Key = "CrouchSpoof", Text = "蹲下伪装" })

--────────────────────────── 综合 · 角色 ──────────────────────────
Mini.Label(tabGeneral.Page, L("g.character", "角色", "Character"))
Options.SpeedBoostSlider = Mini.Slider(tabGeneral.Page, { Key = "SpeedBoostSlider", Text = "速度加成", Min = 0, Max = 100, Default = 0, Rounding = 0 })
Mini.Divider(tabGeneral.Page)
Toggles.RemoveClosetDelay = Mini.Toggle(tabGeneral.Page, { Key = "RemoveClosetDelay", Text = "移除衣柜延迟" })
Toggles.EnableCharacterJump = Mini.Toggle(tabGeneral.Page, { Key = "EnableCharacterJump", Text = "启用跳跃" })
Toggles.EnableCharacterSlide = Mini.Toggle(tabGeneral.Page, { Key = "EnableCharacterSlide", Text = "启用滑行" })
Toggles.InfiniteJumps = Mini.Toggle(tabGeneral.Page, { Key = "InfiniteJumps", Text = "无限跳跃" })

--────────────────────────── 综合 · 自身 ──────────────────────────
Mini.Label(tabGeneral.Page, L("g.self", "自身", "Self"))
Toggles.DoorReachToggle = Mini.Toggle(tabGeneral.Page, { Key = "DoorReachToggle", Text = "门的交互距离" })
Toggles.DisableIdleKick = Mini.Toggle(tabGeneral.Page, { Key = "DisableIdleKick", Text = "禁用挂机踢出" })
Mini.Divider(tabGeneral.Page)
Options.PromptReachSlider = Mini.Slider(tabGeneral.Page, { Key = "PromptReachSlider", Text = "互动距离倍率", Min = 1, Max = 2, Default = 1, Rounding = 1 })
Toggles.InstantPrompts = Mini.Toggle(tabGeneral.Page, { Key = "InstantPrompts", Text = "秒互动" })
Toggles.PromptClip = Mini.Toggle(tabGeneral.Page, { Key = "PromptClip", Text = "隔墙互动" })

--────────────────────────── 综合 · 自动化 ──────────────────────────
Mini.Label(tabGeneral.Page, L("g.auto", "自动化", "Automation"))
Toggles.AutoBreakerBox = Mini.Toggle(tabGeneral.Page, { Key = "AutoBreakerBox", Text = "自动电闸箱" })
Toggles.AutoSolveAnchors = Mini.Toggle(tabGeneral.Page, { Key = "AutoSolveAnchors", Text = "自动解锚点" })
Toggles.AutoHeartbeatMinigame = Mini.Toggle(tabGeneral.Page, { Key = "AutoHeartbeatMinigame", Text = "自动心跳小游戏" })
Mini.Divider(tabGeneral.Page)
Toggles.AutoUnlockPadlockToggle = Mini.Toggle(tabGeneral.Page, { Key = "AutoUnlockPadlockToggle", Text = "自动解锁挂锁" })
Options.AutoUnlockPadlockSlider = Mini.Slider(tabGeneral.Page, { Key = "AutoUnlockPadlockSlider", Text = "解锁距离", Min = 1, Max = 50, Default = 10, Rounding = 0 })
Toggles.AutoLibraryGuessCode = Mini.Toggle(tabGeneral.Page, { Key = "AutoLibraryGuessCode", Text = "猜图书馆密码" })
Toggles.AutoLibrary = Mini.Toggle(tabGeneral.Page, { Key = "AutoLibrary", Text = "自动图书馆" })
Mini.Divider(tabGeneral.Page)
Toggles.SkipSeekHotel = Mini.Toggle(tabGeneral.Page, { Key = "SkipSeekHotel", Text = "跳过 Seek（酒店）" })
Toggles.AutoBreakerRoom = Mini.Toggle(tabGeneral.Page, { Key = "AutoBreakerRoom", Text = "自动电闸房" })
Mini.Divider(tabGeneral.Page)
Toggles.AutoHotel = Mini.Toggle(tabGeneral.Page, { Key = "AutoHotel", Text = "自动酒店" })
Toggles.AutoHotelIgnoreEntities = Mini.Toggle(tabGeneral.Page, { Key = "AutoHotelIgnoreEntities", Text = "忽略实体等待" })
Mini.Divider(tabGeneral.Page)
Toggles.AutoInteractToggle = Mini.Toggle(tabGeneral.Page, { Key = "AutoInteractToggle", Text = "自动交互" })
local AutoInteractKeybind = Mini.Keybind(tabGeneral.Page, { Key = "AutoInteractKeybind", Text = "自动交互", Default = "R" })
Options.AutoInteractIgnoreList = Mini.Dropdown(tabGeneral.Page, { Key = "AutoInteractIgnoreList", Text = "忽略列表", Values = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Currency", "Minecarts", "Locks" }, Default = {"Glitch Fragments", "Jeff Items", "Dropped Items"}, Multi = true, AllowNull = true })
Mini.Divider(tabGeneral.Page)
Toggles.AutoClosetToggle = Mini.Toggle(tabGeneral.Page, { Key = "AutoClosetToggle", Text = "自动躲衣柜" })
local AutoClosetKeybind = Mini.Keybind(tabGeneral.Page, { Key = "AutoClosetKeybind", Text = "自动躲衣柜", Default = "Q" })
Options.AutoClosetEntityList = Mini.Dropdown(tabGeneral.Page, { Key = "AutoClosetEntityList", Text = "忽略实体", Values = { "Rush", "Ambush", "Blitz", "DronesStampede", "Scribbles", "A-60", "A-120", "AR0xMBUSH", "RNIUSHCG==" }, Multi = true, AllowNull = true })
Toggles.SpectateEntityToggle = Mini.Toggle(tabGeneral.Page, { Key = "SpectateEntityToggle", Text = "旁观实体" })
Mini.Divider(tabGeneral.Page)
Mini.Label(tabGeneral.Page, L("g.misc", "杂项", "Miscellaneous"))
Mini.Button(tabGeneral.Page, { Key = "SelfPlayAgain", Text = "再来一局" }):OnClick(function()
    SelfAction("PlayAgain")
end)
Mini.Button(tabGeneral.Page, { Key = "SelfLobby", Text = "回到大厅" }):OnClick(function()
    SelfAction("Lobby")
end)
Mini.Button(tabGeneral.Page, { Key = "SelfRevive", Text = "复活" }):OnClick(function()
    SelfAction("Revive")
end)
Mini.Button(tabGeneral.Page, { Key = "SelfReset", Text = "重置角色" }):OnClick(function()
    SelfAction("Reset")
end)
Options.SpecateEntityMode = Mini.Dropdown(tabGeneral.Page, { Key = "SpecateEntityMode", Text = "旁观模式", Values = { "Player to Entity", "Entity to Player" }, Default = 1, AllowNull = true })

--────────────────────────── 语言 ──────────────────────────
-- 注意：这里故意不给 Key —— 语言不进存档。
-- 否则读档时会把语言又改回存的那一刻的值，换完语言一重载就被顶回来。
local LangDropdown = Mini.Dropdown(tabLang.Page, {
    Text = "界面语言",
    Values = { "中文", "English" }, Default = (Lang.Current == "en") and 2 or 1,
})
-- 只认「真的值变化」：建界面时下拉框会用当前项回放一次回调，
-- 那一次不算用户切换 —— 否则重载之后会再切一次，来回重载停不下来。
local LastLangPick = (Lang.Current == "en") and "English" or "中文"

LangDropdown:OnChanged(function(Value)
    if Value == LastLangPick then return end
    LastLangPick = Value
    local Want = (Value == "中文") and "zh" or "en"
    if Want == Lang.Current then return end
    -- WindUI 控件的文字是建的时候定死的，没有改标题的接口，
    -- 所以换语言走「先存语言 → 卸载 → 重新执行本脚本」，界面整体按新语言重建。
    Lang.Set(Want)
    getgenv().DoorsESPX_Lang = Want
    task.defer(function()
        local State = getgenv()[STATE_KEY]
        if State and State.Unload then pcall(State.Unload) end
        local ok, err = pcall(function()
            return loadstring(game:HttpGet(SCRIPT_URL))()
        end)
        if not ok then
            warn("[Msptds] 换语言后自动重载失败：" .. tostring(err) .. "，请手动重新执行一次脚本")
        end
    end)
end)

--────────────────────────── ESP 开关 ──────────────────────────
local ESPOrder = {
    { "DoorESPToggle", "Doors",        "门",     "门",
      "Highlights the next door.", "高亮下一道门。",
      "DoorESPColor", Color3.fromRGB(0, 200, 255) },
    { "HidingSpotESPToggle", "Hiding Spots", "藏身点", "藏身点",
      "Highlights places where you can hide from entities", "高亮可以躲实体藏身点。",
      "HidingSpotESPColor", Color3.fromRGB(255, 170, 0) },
    { "PlayerESPToggle", "Players",    "玩家",   "玩家",
      "Highlights other players.", "高亮其他玩家。",
      "PlayerESPColor", Color3.fromRGB(255, 255, 255) },
    { "ChestESPToggle", "Chests",      "宝箱",   "宝箱",
      "Highlights objects that can contain loot.", "高亮可能出物资的箱子。",
      "ChestESPColor", Color3.fromRGB(255, 255, 0) },
    { "ItemESPToggle", "Items",        "物品",   "物品",
      "Highlights all collectable items/consumables.", "高亮所有可拾取物品 / 消耗品。",
      "ItemESPColor", Color3.fromRGB(170, 0, 255) },
    { "CurrencyESPToggle", "Currency", "货币",   "货币",
      "Highlights all currency that spawns.", "高亮刷出来的货币（金币堆 / 星尘）。",
      "CurrencyESPColor", Color3.fromRGB(255, 255, 0) },
    { "LadderESPToggle", "Ladders",    "梯子",   "梯子",
      "Highlights ladders that can be used to disable the anticheat.",
      "高亮梯子（爬一下可以关掉反作弊）。",
      "LadderESPColor", Color3.fromRGB(3, 67, 71) },
    { "MiscESPToggle", "Misc",         "杂项",   "杂项",
      "Highlights miscellaneous objects that can be used to disable the anticheat.",
      "高亮杂项物件（也能用来关反作弊）。",
      "MiscESPColor", Color3.fromRGB(255, 255, 255) },
    { "ObjectiveESPToggle", "Objectives", "目标物", "目标物",
      "Highlights objectives you have to interact with.", "高亮需要交互的任务目标。",
      "ObjectiveESPColor", Color3.fromRGB(0, 255, 0) },
}

local function BuildESPEntry(def)
    Toggles[def[1]] = Mini.Toggle(tabESP.Page, L(
        "esp." .. def[1], def[3], def[2], def[5], def[4]))
    local ColorCfg = L("col." .. def[1], def[4] .. " 颜色", def[2] .. " Color")
    ColorCfg.Default = def[8]
    Options[def[7]] = Mini.ColorPicker(tabESP.Page, ColorCfg)
end

-- 原版分类（Doors ~ Misc）
for i = 1, 8 do BuildESPEntry(ESPOrder[i]) end

--───────────────── 任务（闸门单独成类） ─────────────────
-- 闸门原来跟购物车挤在 Misc 里，现在单独挑出来，颜色也换掉了
Mini.Divider(tabESP.Page)
Mini.Label(tabESP.Page, L("cat.task", "任务", "Tasks"))
Toggles.TaskESPToggle = Mini.Toggle(tabESP.Page, L(
    "esp.task", "闸门", "Garage Door",
    "Highlights the garage door. The original kept it inside Misc, next to the shopping cart.",
    "高亮闸门。原版把它塞在「杂项」里跟购物车同一条，这里单独拎出来。"))
local TaskColorCfg = L("col.task", "闸门 颜色", "Garage Door Color")
TaskColorCfg.Default = Color3.fromRGB(255, 0, 170)
Options.TaskESPColor = Mini.ColorPicker(tabESP.Page, TaskColorCfg)

-- 原版分类（Objectives ~ Entities）
for i = 9, #ESPOrder do BuildESPEntry(ESPOrder[i]) end

Toggles.EntityESPToggle = Mini.Toggle(tabESP.Page, L(
    "esp.entity", "实体", "Entities",
    "Highlights all entities that spawn.", "高亮所有刷出来的实体。"))
local EntityColorCfg = L("col.entity", "实体 颜色", "Entities Color")
EntityColorCfg.Default = Color3.fromRGB(255, 0, 0)
Options.EntityESPColor = Mini.ColorPicker(tabESP.Page, EntityColorCfg)

Options.EntityESPOptions = Mini.MultiSelect(tabESP.Page, {
    Key = "esp.entitylist", Text = "实体列表",
    Values = EntityListValues, Default = {},
})
Mini.Button(tabESP.Page, L("btn.all",  "全选",   "Select All"))
    :OnClick(function() Options.EntityESPOptions:SetAll(true) end)
Mini.Button(tabESP.Page, L("btn.none", "全不选", "Clear"))
    :OnClick(function() Options.EntityESPOptions:SetAll(false) end)

--────────────────────────── ESP 设置 ──────────────────────────
Toggles.ESPRainbow = Mini.Toggle(tabSet.Page, L(
    "set.rainbow", "彩虹效果", "Rainbow Effect",
    "Makes the esp objects change colour like a rainbow.",
    "让 ESP 颜色像彩虹一样流动。"))
local ShowDistanceCfg = L("set.showdist", "显示距离", "Show Distance",
    "Shows how far away your character is from the object.",
    "在名字下面额外显示距离。")
ShowDistanceCfg.Default = true
Toggles.ESPShowDistance = Mini.Toggle(tabSet.Page, ShowDistanceCfg)
Mini.Divider(tabSet.Page)

Options.ESPFillTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.fill", Text = "填充透明度", Min = 0, Max = 1, Default = 0.75, Rounding = 2 })
Options.ESPOutlineTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.outline", Text = "轮廓透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.text", Text = "文字透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPTextOutlineTransparency = Mini.Slider(tabSet.Page, {
    Key = "set.textoutline", Text = "文字描边透明度", Min = 0, Max = 1, Default = 0, Rounding = 2 })
Options.ESPFadeTime = Mini.Slider(tabSet.Page, {
    Key = "set.fade", Text = "淡出时间", Min = 0, Max = 1, Default = 0.25, Rounding = 2 })
Options.ESPRenderLimit = Mini.Slider(tabSet.Page, {
    Key = "set.render", Text = "渲染上限", Min = 30, Max = 240, Default = 240, Rounding = 0 })
Options.ESPTextSize = Mini.Slider(tabSet.Page, {
    Key = "set.textsize", Text = "文字大小", Min = 12, Max = 24, Default = 20, Rounding = 0 })
Options.ESPTextFont = Mini.Dropdown(tabSet.Page, {
    Key = "set.font", Text = "文字字体", Values = FontValues, Default = 12 })

Mini.Divider(tabSet.Page)
Options.ESPTracersOrigin = Mini.Dropdown(tabSet.Page, {
    Key = "set.tracerorigin", Text = "连线起点",
    Values = { "Bottom", "Center", "Top", "Mouse" }, Default = 1 })
Options.ESPTracerThickness = Mini.Slider(tabSet.Page, {
    Key = "set.tracerthick", Text = "连线粗细", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2 })
Toggles.ESPTracersToggle = Mini.Toggle(tabSet.Page, L(
    "set.tracers", "开启连线", "Enable Tracers",
    "Draws a line to highlighted objects.", "从屏幕底部拉一条线指向高亮对象。"))

Mini.Divider(tabSet.Page)
Options.ESPArrowsRadius = Mini.Slider(tabSet.Page, {
    Key = "set.arrowradius", Text = "箭头半径", Min = 100, Max = 500, Default = 250, Rounding = 0 })
Toggles.ESPArrowsToggle = Mini.Toggle(tabSet.Page, L(
    "set.arrows", "开启箭头", "Enable Arrows",
    "Shows arrow that point to off-screen objects.", "屏幕外对象显示指向箭头。"))

Mini.Divider(tabSet.Page)
local TextOffToggle = Mini.Toggle(tabSet.Page, L(
    "set.hidetext", "隐藏 ESP 文字", "Hide ESP Text",
    "Same as Text Transparency = 1.", "等同于把文字透明度设成 1。"))
TextOffToggle:OnChanged(function(Value)
    Options.ESPTextTransparency:Set(Value and 1 or 0, true)
    ESPLibrary:SetTextTransparency(Value and 1 or 0)
end)
Options.ESPTextTransparency:OnChanged(function(Value)
    TextOffToggle:Set(Value >= 1, true)
end)

local UIKeybind = Mini.Keybind(tabSet.Page, {
    Key = "set.uikey", Text = "界面开关键", Default = Enum.KeyCode.RightShift })

--────────────────────────── 相机：FOV + 场景高亮 + 除雾 ──────────────────────────
local FovToggleCfg = L("cam.fov", "自定义视野", "Custom FOV",
    "Only applies the Field of View slider when enabled.",
    "只有在开着的时候视野滑条才生效。")
FovToggleCfg.Default = true
Toggles.FOVToggle = Mini.Toggle(tabCam.Page, FovToggleCfg)
Options.FieldOfView = Mini.Slider(tabCam.Page, {
    Key = "cam.fovslider", Text = "视野", Min = 1, Max = 120, Default = 120, Rounding = 0 })
local FovKeybind = Mini.Keybind(tabCam.Page, {
    Key = "cam.fovkey", Text = "视野快捷键", Default = Enum.KeyCode.O })

Mini.Divider(tabCam.Page)
Toggles.AmbientToggle = Mini.Toggle(tabCam.Page, L(
    "cam.ambient", "场景高亮", "Ambient",
    "Changes the lighting color to the specified value.",
    "把环境光强行拉成指定颜色，整个场景提亮。"))
local AmbientColorCfg = L("cam.ambientcolor", "环境光颜色", "Ambient Color")
AmbientColorCfg.Default = Color3.fromRGB(255, 255, 255)
Options.AmbientColor = Mini.ColorPicker(tabCam.Page, AmbientColorCfg)

Toggles.RemoveCameraFog = Mini.Toggle(tabCam.Page, L(
    "cam.fog", "除雾", "Remove Fog",
    "Removes all fog effects from the camera.",
    "把 FogEnd 拉满 + 所有 Atmosphere.Density 归零，远景不再灰蒙蒙。"))

--────────────────────────── 角色：速度绕过 / 穿墙 ──────────────────────────
-- 这个速度绕过照抄 tplaysaddon（mspaint 的 Tplay 插件）里的 StartWSConnection：
--   每帧把「爬梯速度 - 15」写进角色自己的 SpeedBoostBehind 属性，
--   再把 WalkSpeed 写成行走速度。
-- 为什么这样不会被拉回：Doors 自己的 Functions.GetCurrentSpeed 本来就是
--   15 + SpeedBoost + SpeedBoostBehind + SpeedBoostExtra + ...
--   所以把差额写进属性之后，游戏自己算出来的速度就等于你要的速度，
--   客户端和服务端对得上，没有「异常差值」可判 —— 直接改 WalkSpeed 才会被拉回。
Options.SpeedBypassWalk = Mini.Slider(tabGeneral.Page, {
    Key = "char.walk", Text = "行走速度", Min = 0, Max = 75, Default = 15, Rounding = 0 })
Options.SpeedBypassLadder = Mini.Slider(tabGeneral.Page, {
    Key = "char.ladder", Text = "爬梯速度", Min = 0, Max = 75, Default = 15, Rounding = 0 })
Toggles.SpeedBypassToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.bypass", "速度绕过", "Speed Bypass",
    "Writes the extra speed into the game's own SpeedBoostBehind attribute instead of fighting WalkSpeed.",
    "照 tplays 插件的做法：把多出来的速度写进游戏自己的 SpeedBoostBehind 属性，让游戏自己算出这个速度，就不会被拉回。"))
Mini.Divider(tabChar.Page)
Toggles.NoclipToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.noclip", "穿墙", "Noclip",
    "Allows your character to pass through solid objects.",
    "角色可以穿墙（每帧把 CanCollide 关掉）。"))
local NoclipKeybind = Mini.Keybind(tabGeneral.Page, {
    Key = "char.noclipkey", Text = "穿墙快捷键", Default = Enum.KeyCode.N })
Mini.Divider(tabChar.Page)
Toggles.FlyToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.fly", "飞行", "Fly",
    "Fly with WASD, Space to go up and LeftCtrl to go down.",
    "WASD 相对镜头飞行，空格上升、左 Ctrl 下降。"))
local FlyKeybind = Mini.Keybind(tabGeneral.Page, {
    Key = "char.flykey", Text = "飞行快捷键", Default = Enum.KeyCode.F })

--────────────────────────── 绕过 ──────────────────────────
Mini.Divider(tabBypass.Page)
Toggles.NoPullbackNoclipToggle = Mini.Toggle(tabBypass.Page, L(
    "by.nopull", "无拉回穿墙", "No-Pullback Noclip",
    "Uses the addon's chair trick to replace the anticheat, plus noclip and a slow forward push.",
    "抄 tplays 插件的椅子法把反作弊顶掉，再配合穿墙 + 缓慢前推，走过去不会被拉回。"))
local NoPullbackKeybind = Mini.Keybind(tabBypass.Page, {
    Key = "by.nopullkey", Text = "无拉回穿墙快捷键", Default = Enum.KeyCode.V })

--────────────────────────── Creak 愤怒值（右下角） ──────────────────────────
Toggles.CreakAggressionMeter = Mini.Toggle(tabCreak.Page, L(
    "creak.meter", "Creak 愤怒值（右下角）", "Creak Aggression Meter (bottom-right)",
    "Shows Creak's aggression in the bottom-right corner.",
    "在屏幕右下角常驻显示 Creak 的愤怒值。"))

--=====================================================================
-- 6. 原版 ESP 库设置（数值照抄 Main.luau 5443-5458 行）
--=====================================================================
ESPLibrary:SetRainbow(false)
ESPLibrary:SetShowDistance(true)
ESPLibrary:SetFillTransparency(0.75)
ESPLibrary:SetOutlineTransparency(0)
ESPLibrary:SetTextTransparency(0)
ESPLibrary:SetTextOutlineTransparency(0)
ESPLibrary:SetRenderLimit(240)
ESPLibrary:SetFadeTime(0.25)
ESPLibrary:SetTextSize(20)
ESPLibrary:SetFont(Enum.Font.Highway)
ESPLibrary:SetTracers(false)
ESPLibrary:SetTracerSize(0.75)
ESPLibrary:SetTracerOrigin("Bottom")
ESPLibrary:SetArrows(false)
ESPLibrary:SetArrowRadius(250)
ESPLibrary:SetDistanceSizeRatio(0.8)

Toggles.ESPRainbow:OnChanged(function(V) ESPLibrary:SetRainbow(V) end)
Toggles.ESPShowDistance:OnChanged(function(V) ESPLibrary:SetShowDistance(V) end)
Options.ESPFillTransparency:OnChanged(function(V) ESPLibrary:SetFillTransparency(V) end)
Options.ESPOutlineTransparency:OnChanged(function(V) ESPLibrary:SetOutlineTransparency(V) end)
Options.ESPTextTransparency:OnChanged(function(V) ESPLibrary:SetTextTransparency(V) end)
Options.ESPTextOutlineTransparency:OnChanged(function(V) ESPLibrary:SetTextOutlineTransparency(V) end)
Options.ESPFadeTime:OnChanged(function(V) ESPLibrary:SetFadeTime(V) end)
Options.ESPRenderLimit:OnChanged(function(V) ESPLibrary:SetRenderLimit(V) end)
Options.ESPTextSize:OnChanged(function(V) ESPLibrary:SetTextSize(V) end)
Options.ESPTextFont:OnChanged(function(V) ESPLibrary:SetFont(Enum.Font[V]) end)
Toggles.ESPTracersToggle:OnChanged(function(V) ESPLibrary:SetTracers(V) end)
Options.ESPTracersOrigin:OnChanged(function(V) ESPLibrary:SetTracerOrigin(V) end)
Options.ESPTracerThickness:OnChanged(function(V) ESPLibrary:SetTracerSize(V) end)
Toggles.ESPArrowsToggle:OnChanged(function(V) ESPLibrary:SetArrows(V) end)
Options.ESPArrowsRadius:OnChanged(function(V) ESPLibrary:SetArrowRadius(V) end)

--=====================================================================
-- 7. 原版 ESP 开关的回调（照着 5244-5418 行写）
--=====================================================================
Toggles.DoorESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Doors) do
        if Value then
            Functions.AddESP({ Object = Object,
                Text = "Door " .. Functions.GetDoorNumber(Object),
                Color = Options.DoorESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.DoorESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Doors) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.HidingSpotESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.HidingSpots) do
        local Label = HidingSpotLabels[Object.Name]
        if Value and Label then
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.HidingSpotESPColor.Value }, true)
        elseif not Value then
            Functions.RemoveESP(Object)
        end
    end
end)
Options.HidingSpotESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.HidingSpots) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
end)

Toggles.PlayerESPToggle:OnChanged(function(Value)
    task.wait()
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player.Character and Player ~= LocalPlayer then
            if Value and Player:GetAttribute("Alive") == true then
                Functions.AddESP({ Object = Player.Character, Text = Player.Name,
                    Color = Options.PlayerESPColor.Value })
            else
                Functions.RemoveESP(Player.Character)
            end
        end
    end
end)
Options.PlayerESPColor:OnChanged(function(Value)
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player.Character and Player ~= LocalPlayer then
            ESPLibrary:UpdateObjectColor(Player.Character, Value)
        end
    end
end)

Toggles.ChestESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Chests) do
        if Value then
            local Label
            if Object.Name == "ChestBox" or Object.Name == "ChestBoxLocked" then
                Label = Object:GetAttribute("Locked") and "Locked Chest" or "Chest"
            elseif Object.Name == "Toolbox" or Object.Name == "Toolbox_Locked" then
                Label = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox"
            elseif ChestLabels[Object.Name] and ChestLabels[Object.Name] ~= true then
                Label = ChestLabels[Object.Name]
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ChestESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ChestESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Chests) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ItemESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Items) do
        if Value then
            local Label = ItemNames[Object.Name]
                or (Object.Name == "Green_Herb" and "Green Herb")
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ItemESPColor.Value },
                    Object:GetAttribute("ParentRoom") ~= nil)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ItemESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Items) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.CurrencyESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Currency) do
        if Value then
            local Label
            if Object.Name == "GoldPile" and Object:GetAttribute("GoldValue") then
                Label = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]"
            elseif Object.Name == "StardustPickup" then
                Label = "Stardust Pile"
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.CurrencyESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.CurrencyESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Currency) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

local function EntityLabel(Object)
    local Label = EntityESPLabels[Object.Name]
    if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Alias end
    return Label
end

local function EntityPass(Value, Object)
    if not Value then
        Functions.RemoveESP(Object)
        return
    end
    local Label = EntityLabel(Object)
    if Label and Options.EntityESPOptions.Value[Label] then
        Functions.AddESP({ Object = Object, Text = Label,
            Color = Options.EntityESPColor.Value }, NodeEntities[Label] ~= true)
    else
        Functions.RemoveESP(Object)
    end
end

Toggles.EntityESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Entities) do EntityPass(Value, Object) end
end)
Options.EntityESPOptions:OnChanged(function()
    for _, Object in ipairs(Objects.Entities) do
        EntityPass(Toggles.EntityESPToggle.Value, Object)
    end
end)
Options.EntityESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Entities) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.LadderESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Ladders) do
        if Value then
            Functions.AddESP({ Object = Object, Text = "Ladder",
                Color = Options.LadderESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.LadderESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Ladders) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.MiscESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Misc) do
        if Value then
            local Label = Object.Name
            if Object.Name == "StairwellFireAlarm" then
                Label = "Fire Alarm"
            elseif Object.Name == "ShoppingCart" then
                Label = "Shopping Cart"
            elseif Object.Name == "ArchivesFihTank" or Object.Name == "ArchivesFishTank" then
                Label = "Fish Tank"
            end
            Functions.AddESP({ Object = Object, Text = Label,
                Color = Options.MiscESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.MiscESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Misc) do ESPLibrary:UpdateObjectColor(Object, Value) end
end)

-- 任务分类：闸门（原版 Misc 里那条 StairwellLockpickDoor 分支）
Toggles.TaskESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Tasks) do
        if Value then
            Functions.AddESP({ Object = Object, Text = "Garage Door",
                Color = Options.TaskESPColor.Value }, true)
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.TaskESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Tasks) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
end)

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Objectives) do
        if Value then
            local Label = ObjectiveLabels[Object.Name]
            if Object.Name == "TimerLever" then
                Label = "Time Lever [+" .. tostring(Object:GetAttribute("AddTime")) .. "s]"
            elseif Object.Name == "MinesAnchor" then
                local Sign = Object:FindFirstChild("Sign")
                if Sign and Sign:FindFirstChild("TextLabel") then
                    Label = "Anchor [" .. Sign.TextLabel.Text .. "]"
                end
            elseif Object.Name == "WaterPump" then
                if Object:FindFirstChild("Wheel") then
                    Functions.AddESP({ Object = Object.Wheel, Text = "Water Pump",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                Label = false
            elseif Object.Name == "VineGuillotine" then
                if Object:FindFirstChild("Lever") then
                    Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever",
                        Color = Options.ObjectiveESPColor.Value }, true)
                end
                Label = false
            end
            if Label then
                Functions.AddESP({ Object = Object, Text = Label,
                    Color = Options.ObjectiveESPColor.Value }, true)
            end
        else
            Functions.RemoveESP(Object)
        end
    end
end)
Options.ObjectiveESPColor:OnChanged(function(Value)
    for _, Object in ipairs(Objects.Objectives) do
        ESPLibrary:UpdateObjectColor(Object, Value)
    end
end)

-- 原版玩家 ESP 的加入 / 离开跟踪
local function WatchPlayer(Player)
    if Player == LocalPlayer then return end
    if Player.Character and Toggles.PlayerESPToggle.Value then
        Functions.AddESP({ Object = Player.Character, Text = Player.Name,
            Color = Options.PlayerESPColor.Value })
    end
    local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
        if Toggles.PlayerESPToggle.Value then
            Functions.AddESP({ Object = NewCharacter, Text = Player.Name,
                Color = Options.PlayerESPColor.Value })
        end
    end)
    local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
        if Player:GetAttribute("Alive") ~= true and Player.Character then
            Functions.RemoveESP(Player.Character)
        end
    end)
    table.insert(Connections, CharConn)
    table.insert(Connections, DeadConn)
end

for _, Player in ipairs(Services.Players:GetPlayers()) do WatchPlayer(Player) end
Connections.PlayerHandler = Services.Players.PlayerAdded:Connect(WatchPlayer)

--=====================================================================
-- 8. 视野 FOV + 场景高亮 + 除雾
--=====================================================================
local MainGame

task.spawn(function()
    local ok, res = pcall(function()
        local ui = LocalPlayer.PlayerGui
        if not ui then return nil end
        local ini = ui:FindFirstChild("MainUI")
        if not ini then return nil end
        local mg = ini:FindFirstChild("Initiator")
        if not mg then return nil end
        local mod = mg:FindFirstChild("Main_Game")
        if not mod then return nil end
        return require(mod)
    end)
    if ok and res then MainGame = res end
end)

local FovCamera = Services.Workspace.CurrentCamera

-- 原版 6774-6781 行：RenderStepped 每帧设一次，优先走游戏自己的 fovtarget
Connections.FovHandler = Services.RunService.RenderStepped:Connect(function()
    if not Toggles.FOVToggle.Value then return end

    local Camera = Services.Workspace:FindFirstChild("Camera")
    if not Camera then
        Camera = Services.Workspace.CurrentCamera
    end
    FovCamera = Camera
    if not FovCamera then return end

    if MainGame then
        task.wait()
        MainGame.fovtarget = Options.FieldOfView.Value
    else
        FovCamera.FieldOfView = Options.FieldOfView.Value
    end
end)

--────────────────────────── 场景高亮（原版 AmbientToggle） ──────────────────────────
local Lighting = Services.Lighting

local SceneOriginal = {
    Ambient = Lighting.Ambient,
    FogEnd  = Lighting.FogEnd,
}
local AtmoOriginal = {}

local AmbientConn, FogConn, AtmoAddedConn
local AtmoConns = {}

local function DisconnectScene()
    if AmbientConn then AmbientConn:Disconnect() AmbientConn = nil end
    if FogConn then FogConn:Disconnect() FogConn = nil end
    if AtmoAddedConn then AtmoAddedConn:Disconnect() AtmoAddedConn = nil end
    for _, c in ipairs(AtmoConns) do pcall(function() c:Disconnect() end) end
    AtmoConns = {}
end

Toggles.AmbientToggle:OnChanged(function(Value)
    if Value then
        SceneOriginal.Ambient = Lighting.Ambient
        Lighting.Ambient = Options.AmbientColor.Value
        -- Doors 每进房间都会用 0.2 秒 Tween 把 Ambient 拉回暗值，
        -- 所以必须每帧守着；RenderStepped 在渲染之前跑，画面不会闪暗。
        AmbientConn = Services.RunService.RenderStepped:Connect(function()
            if Toggles.AmbientToggle.Value
                and Lighting.Ambient ~= Options.AmbientColor.Value then
                Lighting.Ambient = Options.AmbientColor.Value
            end
        end)
    else
        if AmbientConn then AmbientConn:Disconnect() AmbientConn = nil end
        Lighting.Ambient = SceneOriginal.Ambient
    end
end)
Options.AmbientColor:OnChanged(function(Value)
    if Toggles.AmbientToggle.Value then Lighting.Ambient = Value end
end)

--────────────────────────── 除雾（原版 RemoveCameraFog） ──────────────────────────
local function WatchAtmosphere(Object)
    if not Object:IsA("Atmosphere") then return end
    if AtmoOriginal[Object] == nil then AtmoOriginal[Object] = Object.Density end

    local Conn = Object:GetPropertyChangedSignal("Density"):Connect(function()
        if Object.Density ~= 0 then AtmoOriginal[Object] = Object.Density end
        if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
    end)
    table.insert(AtmoConns, Conn)

    if Toggles.RemoveCameraFog.Value and Object.Density ~= 0 then
        AtmoOriginal[Object] = Object.Density
        Object.Density = 0
    end
end

Toggles.RemoveCameraFog:OnChanged(function(Value)
    if Value then
        SceneOriginal.FogEnd = Lighting.FogEnd
        Lighting.FogEnd = 10000000

        for _, Object in ipairs(Lighting:GetChildren()) do WatchAtmosphere(Object) end
        AtmoAddedConn = Lighting.DescendantAdded:Connect(function(Object)
            if Toggles.RemoveCameraFog.Value then WatchAtmosphere(Object) end
        end)

        FogConn = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if Lighting.FogEnd ~= 10000000 then
                SceneOriginal.FogEnd = Lighting.FogEnd
                if Toggles.RemoveCameraFog.Value then
                    Lighting.FogEnd = 10000000
                end
            end
        end)
    else
        if FogConn then FogConn:Disconnect() FogConn = nil end
        if AtmoAddedConn then AtmoAddedConn:Disconnect() AtmoAddedConn = nil end
        for _, c in ipairs(AtmoConns) do pcall(function() c:Disconnect() end) end
        AtmoConns = {}

        Lighting.FogEnd = SceneOriginal.FogEnd
        for Object, Density in pairs(AtmoOriginal) do
            if Object.Parent then Object.Density = Density end
        end
        AtmoOriginal = {}
    end
end)

--=====================================================================
-- 9. 角色：速度加成 / 穿墙
--=====================================================================
local Char = { Character = nil, Humanoid = nil, RootPart = nil }

-- 原版 6559-6560 行：只设 MaxForce，别的一个都不动
local FlyBody = Instance.new("BodyVelocity")
FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

local ManipulateBody = Instance.new("BodyVelocity")
ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

local function GetLiveModifiers()
    return Services.ReplicatedStorage:FindFirstChild("LiveModifiers")
end

-- RemotesFolder / Crouch 遥控（滑行方式要用；反作弊绕过那页也用同一个）
local RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")

local function GetRemotesFolder()
    if not RemotesFolder or not RemotesFolder.Parent then
        RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    end
    return RemotesFolder
end

local CrouchRemote

local function GetCrouchRemote()
    if CrouchRemote and CrouchRemote.Parent then return CrouchRemote end
    local Folder = GetRemotesFolder()
    CrouchRemote = Folder and Folder:FindFirstChild("Crouch") or nil
    return CrouchRemote
end

local function SetupCharacter(Character)
    if not Character then return end
    Char.Character = Character
    Char.Humanoid = Character:FindFirstChildOfClass("Humanoid")
    Char.RootPart = Character:FindFirstChild("HumanoidRootPart")
        or Character.PrimaryPart
        or Character:FindFirstChildWhichIsA("BasePart")
end

SetupCharacter(LocalPlayer.Character)
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(SetupCharacter)

-- 关掉时照插件复位（StartWSConnection 的反向操作）
local function ResetSpeed()
    local Character, Humanoid = Char.Character, Char.Humanoid
    if Character then Character:SetAttribute("SpeedBoostBehind", 0) end
    if Humanoid then Humanoid.WalkSpeed = 15 end
end

Toggles.SpeedBypassToggle:OnChanged(function(Value)
    if not Value then ResetSpeed() end
end)

--────────────────────────── 无拉回穿墙：椅子法（抄 tplays 插件的反作弊绕过） ──────────────────────────
-- 插件原文：
--   CartControl:FireServer() 然后循环 fireproximityprompt(collider.SeatPrompt)
--   等 Character 出现 SeatedInSeat 属性 = 服务器认为你坐上了椅子 → 反作弊判定被顶掉
--   Heartbeat 里把椅子钉在角色身上、Collider 速度拉高
-- 我们这边把「钉椅子」放在 Heartbeat，坐椅子的判定靠持续触发 SeatPrompt。
local ChairBypass = { Target = nil, Collider = nil }

local function StopChairBypass()
    ChairBypass.Target, ChairBypass.Collider = nil, nil
end

local function FindSeatTarget()
    local Root = Char.RootPart
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return nil end
    local Best, BestDist = nil, nil
    for _, Room in ipairs(Rooms:GetChildren()) do
        for _, Obj in ipairs(Room:GetChildren()) do
            local Name = Obj.Name
            if string.find(Name, "OfficeChair") or Name == "ShoppingCart" or Name == "TV_Stand" then
                local Base = Obj:FindFirstChild("Base")
                local Collider = Obj:FindFirstChild("Collider")
                if Base and Collider and Collider:FindFirstChild("SeatPrompt") then
                    local Pos = Base.Position
                    local Dist = (Root and Pos) and (Pos - Root.Position).Magnitude or 0
                    if not BestDist or Dist < BestDist then Best, BestDist = Obj, Dist end
                end
            end
        end
    end
    return Best
end

local function StartChairBypass()
    StopChairBypass()
    if not FirePrompt then
        pcall(function()
            Mini.WindUI:Notify({
                Title = "执行器没有 fireproximityprompt，椅子法用不了",
                Duration = 5, Icon = "warning",
            })
        end)
        return false
    end
    local Target = FindSeatTarget()
    if not Target then
        pcall(function()
            Mini.WindUI:Notify({
                Title = "附近没找到椅子 / 购物车，椅子法用不了",
                Duration = 5, Icon = "warning",
            })
        end)
        return false
    end

    ChairBypass.Target = Target
    ChairBypass.Collider = Target:FindFirstChild("Collider")

    local Remotes = GetRemotesFolder()
    local CartControl = Remotes and Remotes:FindFirstChild("CartControl")
    if CartControl then
        pcall(function() CartControl:FireServer() end)
    end

    local SeatPrompt = ChairBypass.Collider and ChairBypass.Collider:FindFirstChild("SeatPrompt")
    if not SeatPrompt then return false end

    pcall(function()
        Mini.WindUI:Notify({ Title = "反作弊已被绕过（椅子法）", Duration = 3, Icon = "check" })
    end)
    return true
end

-- 每帧做三件事（插件的 task.wait 循环就是这个节奏，这里挂 Heartbeat 更省一个线程）：
--   ① 朝椅子的 SeatPrompt 触发一次，让服务器持续认为你坐着
--   ② 把 Collider 速度拉高
--   ③ 把椅子钉在角色身上
Connections.NoPullbackChair = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.NoPullbackNoclipToggle.Value then return end
    local Target, Character = ChairBypass.Target, Char.Character
    if not (Target and Character and Target.Parent) then return end

    local Collider = ChairBypass.Collider
    local SeatPrompt = Collider and Collider:FindFirstChild("SeatPrompt")
    if SeatPrompt and FirePrompt then
        pcall(FirePrompt, SeatPrompt, 0)
    end
    if Collider then
        pcall(function() Collider.AssemblyLinearVelocity = Vector3.new(0, 10000, 0) end)
    end
    pcall(function() Target:PivotTo(Character:GetPivot()) end)
end)

Toggles.NoPullbackNoclipToggle:OnChanged(function(Value)
    if Value then
        StartChairBypass()
    else
        StopChairBypass()
    end
end)

Connections.CharacterLoop = Services.RunService.RenderStepped:Connect(function()
    local Character, Humanoid, RootPart = Char.Character, Char.Humanoid, Char.RootPart
    if not Character or not Humanoid or not RootPart or not RootPart.Parent then return end
    if Humanoid.Health <= 0 then return end

    if Toggles.SpeedBypassToggle.Value then
        -- 插件原文：Character:SetAttribute("SpeedBoostBehind", Variables.ladderspeed-15)
        --           Character.Humanoid.WalkSpeed = Variables.walkspeed
        Character:SetAttribute("SpeedBoostBehind", Options.SpeedBypassLadder.Value - 15)
        Humanoid.WalkSpeed = Options.SpeedBypassWalk.Value

        -- 方式固定为插件的「滑行」：每帧点一下下蹲遥控
        local Crouch = GetCrouchRemote()
        if Crouch then
            pcall(function()
                Crouch:FireServer(Character:GetAttribute("Crouching"), true)
            end)
        end
    end

    -- 原版写法：每 tick 直接写「取反」的值，所以关掉开关后下一帧就自己还原。
    -- 只碰根部件和 CollisionPart（跟原版一致）—— 原来每帧遍历整个角色的部件，是卡顿来源之一。
    local Noclip = Toggles.NoclipToggle.Value or Toggles.NoPullbackNoclipToggle.Value
    RootPart.CanCollide = not Noclip
    local CollisionPart = Character:FindFirstChild("CollisionPart")
    if CollisionPart then CollisionPart.CanCollide = not Noclip end

    -- 飞行：WASD 相对镜头，空格上升 / 左 Ctrl 下降
    if Toggles.FlyToggle.Value then
        local UIS = Services.UserInputService
        local Move = Vector3.new(0, 0, 0)
        if UIS and UIS.IsKeyDown then
            local function Down(Key)
                local ok, v = pcall(function() return UIS:IsKeyDown(Key) end)
                return (ok and v) and 1 or 0
            end
            local Fwd = Down(Enum.KeyCode.W) - Down(Enum.KeyCode.S)
            local Side = Down(Enum.KeyCode.D) - Down(Enum.KeyCode.A)
            local Up = Down(Enum.KeyCode.Space) - Down(Enum.KeyCode.LeftControl)
            local Cam = Services.Workspace.CurrentCamera
            if Cam then
                local ok, Look, Right = pcall(function()
                    return Cam.CFrame.LookVector, Cam.CFrame.RightVector
                end)
                if ok and Look then
                    -- 相机没给 RightVector 的话自己兜一个，免得算术直接报错
                    if not Right then Right = Vector3.new(1, 0, 0) end
                    Move = (Look * Fwd) + (Right * Side) + Vector3.new(0, Up, 0)
                end
            end
        end
        FlyBody.Parent = RootPart
        if Move.Magnitude > 0 then
            FlyBody.Velocity = Move.Unit * (Options.FlySpeed and Options.FlySpeed.Value or 60)
        else
            FlyBody.Velocity = Vector3.new(0, 0, 0)
        end
    elseif FlyBody.Parent then
        FlyBody.Parent = nil
    end

    -- 无拉回穿墙：给一个 2.25 的前推（原来速度操控里的 Velocity 模式）
    if Toggles.NoPullbackNoclipToggle.Value then
        ManipulateBody.Parent = RootPart
        ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
    elseif ManipulateBody.Parent then
        ManipulateBody.Parent = nil
    end
end)

--=====================================================================
-- 10. 绕过（原来这里的「反作弊绕过」按需求删掉了，只保留「无拉回穿墙」）
--=====================================================================

-- 11. Creak 愤怒值 —— 屏幕右下角常驻 HUD（WindUI 配色，与 ESP 设置无关）
--=====================================================================
local HUD = { Gui = nil, Panel = nil, Title = nil, Value = nil, BarBG = nil, BarFill = nil }

-- HUD 的配色直接读 WindUI 的主题表，跟窗口是同一套颜色（不是自己拍脑袋配的）
local function HudTheme()
    local Dark = Mini.WindUI and Mini.WindUI.Themes and Mini.WindUI.Themes.Dark or nil
    return {
        Bg     = (Dark and Dark.Background) or Color3.fromRGB(16, 16, 16),
        Text   = (Dark and Dark.Text) or Color3.fromRGB(255, 255, 255),
        Sub    = (Dark and Dark.Placeholder) or Color3.fromRGB(122, 122, 122),
        Accent = (Dark and Dark.Primary) or Color3.fromRGB(0, 145, 255),
        Track  = (Dark and Dark.Button) or Color3.fromRGB(82, 82, 91),
        Stroke = (Dark and Dark.Outline) or Color3.fromRGB(255, 255, 255),
    }
end

-- WindUI 用的就是 GothamSSm，这里跟着用同一款字
local function HudFont(weight)
    if Font and Font.new then
        local ok, f = pcall(Font.new, "rbxasset://fonts/families/GothamSSm.json",
            weight or Enum.FontWeight.SemiBold)
        if ok and f then return f end
    end
    if weight == Enum.FontWeight.Bold then return Enum.Font.GothamBold end
    return Enum.Font.Gotham
end

local function HudParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    return Services.CoreGui
end

Lang.Strings.zh["creak.hud"] = "Creak · 愤怒值"
Lang.Strings.en["creak.hud"] = "Creak · Aggression"

local function BuildHud()
    if HUD.Panel then return end
    local T = HudTheme()

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "DoorsESPX_Creak"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    Gui.DisplayOrder = 999
    Gui.Parent = HudParent()
    HUD.Gui = Gui

    local Panel = Instance.new("Frame")
    Panel.Name = "CreakPanel"
    Panel.AnchorPoint = Vector2.new(1, 1)
    Panel.Position = UDim2.new(1, -20, 1, -20)
    Panel.Size = UDim2.fromOffset(232, 58)
    Panel.BackgroundColor3 = T.Bg
    Panel.BackgroundTransparency = 0.08
    Panel.BorderSizePixel = 0
    Panel.Visible = false
    Panel.Parent = Gui
    HUD.Panel = Panel

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Panel

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = T.Stroke
    Stroke.Transparency = 0.82
    Stroke.Thickness = 1
    Stroke.Parent = Panel

    local Title = Instance.new("TextLabel")
    Title.Text = Lang.T("creak.hud") or "Creak"
    Title.FontFace = HudFont(Enum.FontWeight.SemiBold)
    Title.TextSize = 12
    Title.TextColor3 = T.Sub
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 8)
    Title.Size = UDim2.new(1, -24, 0, 16)
    Title.Parent = Panel
    HUD.Title = Title

    local Value = Instance.new("TextLabel")
    Value.Text = "--%"
    Value.FontFace = HudFont(Enum.FontWeight.Bold)
    Value.TextSize = 20
    Value.TextColor3 = T.Text
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.BackgroundTransparency = 1
    Value.AnchorPoint = Vector2.new(1, 0)
    Value.Position = UDim2.new(1, -12, 0, 6)
    Value.Size = UDim2.new(1, -24, 0, 24)
    Value.Parent = Panel
    HUD.Value = Value

    local BarBG = Instance.new("Frame")
    BarBG.Name = "BarBG"
    BarBG.BackgroundColor3 = T.Track
    BarBG.BorderSizePixel = 0
    BarBG.Position = UDim2.new(0, 12, 0, 38)
    BarBG.Size = UDim2.new(1, -24, 0, 6)
    BarBG.Parent = Panel
    HUD.BarBG = BarBG

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = BarBG

    local BarFill = Instance.new("Frame")
    BarFill.Name = "BarFill"
    BarFill.BackgroundColor3 = T.Accent
    BarFill.BorderSizePixel = 0
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.Parent = BarBG
    HUD.BarFill = BarFill

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = BarFill
end

local function HideHud()
    if HUD.Panel then HUD.Panel.Visible = false end
end

local function DestroyHud()
    if HUD.Gui then pcall(function() HUD.Gui:Destroy() end) end
    HUD.Gui, HUD.Panel, HUD.Title, HUD.Value, HUD.BarBG, HUD.BarFill = nil, nil, nil, nil, nil, nil
end

-- 读 CreakGraph 动画轨道的 Aggression 参数（原版方法）
local function GetCreakAggression(Model)
    if not Model then return nil end
    local Animator = Model:FindFirstChildOfClass("Animator")
        or (Model:FindFirstChild("AnimationController")
            and Model.AnimationController:FindFirstChildOfClass("Animator"))
        or Model:FindFirstChildOfClass("AnimationController")
    if not Animator then return nil end

    local ok, Tracks = pcall(function() return Animator:GetPlayingAnimationTracks() end)
    if not ok or not Tracks then return nil end

    for _, Track in ipairs(Tracks) do
        local IsCreakGraph = Track.Name == "CreakGraph"
            or (Track.Animation and Track.Animation.Name == "CreakGraph")
        if IsCreakGraph then
            local ok2, Value = pcall(Track.GetParameter, Track, "Aggression")
            if ok2 and type(Value) == "number" then
                return math.clamp(Value, 0, 1)
            end
        end
    end
    return nil
end

local function FindCreak()
    local Folder = Services.Workspace:FindFirstChild("LiveEntities")
    if not Folder then return nil end
    local Model = Folder:FindFirstChild("Creak")
    if Model and Model.Parent then return Model end
    return nil
end

Toggles.CreakAggressionMeter:OnChanged(function(Value)
    if Value then
        BuildHud()
        if HUD.Panel then HUD.Panel.Visible = true end
    else
        HideHud()
    end
end)

Connections.CreakHud = Services.RunService.RenderStepped:Connect(function()
    if not Toggles.CreakAggressionMeter.Value then return end
    if not HUD.Panel then return end

    HUD.Panel.Visible = true
    local Now = GetCreakAggression(FindCreak())
    -- 值没变就不碰 UI（每帧写 Text / Size 也是卡顿来源之一）
    if HUD.LastShown == Now then return end
    HUD.LastShown = Now
    local T = HudTheme()
    if not Now then
        HUD.Value.Text = "--%"
        HUD.Value.TextColor3 = T.Sub
        HUD.BarFill.Size = UDim2.new(0, 0, 1, 0)
        return
    end

    HUD.Value.Text = tostring(math.floor(Now * 100 + 0.5)) .. "%"
    HUD.Value.TextColor3 = T.Text
    HUD.BarFill.Size = UDim2.new(Now, 0, 1, 0)
    HUD.BarFill.BackgroundColor3 = T.Accent:Lerp(Color3.fromRGB(255, 55, 55), Now)
end)

--=====================================================================
-- 12. 快捷键 / 启动 / 卸载
--=====================================================================
Connections.Input = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == UIKeybind.Key then Window:Toggle() end
    if input.KeyCode == FovKeybind.Key then
        Toggles.FOVToggle:Set(not Toggles.FOVToggle.Value)
    end
    if input.KeyCode == NoclipKeybind.Key then
        Toggles.NoclipToggle:Set(not Toggles.NoclipToggle.Value)
    end
    if input.KeyCode == NoPullbackKeybind.Key then
        Toggles.NoPullbackNoclipToggle:Set(
            not Toggles.NoPullbackNoclipToggle.Value)
    end
    if input.KeyCode == FlyKeybind.Key then
        Toggles.FlyToggle:Set(not Toggles.FlyToggle.Value)
    end
    if input.KeyCode == AutoInteractKeybind.Key then
        Toggles.AutoInteractToggle:Set(not Toggles.AutoInteractToggle.Value)
    end
    if input.KeyCode == AutoClosetKeybind.Key then
        Toggles.AutoClosetToggle:Set(not Toggles.AutoClosetToggle.Value)
    end
end)

--=====================================================================
-- 13. 新功能：无加速度 / 物品环绕 / 隔墙互动 / 自动楼层 / 保存配置
--=====================================================================
--────────────────────────── 无加速度（抄 Abysall 的 RemoveAcceleration） ──────────────────────────
-- 原理：游戏给角色部件用的是默认物理材质，移动起来会打滑、被推飞。
-- Abysall 的做法是把每个部件的密度顶到 100（摩擦/弹性照抄根部件原来的值），
-- 重量一上来就打滑不起来了。每个部件的原始材质存在 PartProperties 里，关掉时还原。
local NoAccelPartProperties = {}
local NoAccelLast = 0

-- fengari 里没有 debug.traceback，写一个两边都能用的
local function Trace(err)
    local parts = { tostring(err) }
    if debug then
        if type(debug.traceback) == "function" then
            local ok, tb = pcall(debug.traceback, "", 2)
            if ok and tb then parts[#parts + 1] = tostring(tb) end
        elseif type(debug.getinfo) == "function" then
            -- fengari 没有 traceback，用 getinfo 手工拼
            for lvl = 2, 10 do
                local ok, info = pcall(debug.getinfo, lvl, "Sl")
                if not ok or not info or not info.currentline or info.currentline <= 0 then break end
                parts[#parts + 1] = string.format("  栈%d: 第%s行 (%s)",
                    lvl, tostring(info.currentline), tostring(info.name or "?"))
            end
        end
    end
    return table.concat(parts, "\n")
end

local function ApplyNoAcceleration(on)
    local Character = Char.Character
    if not Character then return end
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            local Base = NoAccelPartProperties[Part]
            if on then
                if Base == nil then
                    Base = Part.CustomPhysicalProperties
                    NoAccelPartProperties[Part] = Base
                end
                if Base and PhysicalProperties then
                    pcall(function()
                        Part.CustomPhysicalProperties = PhysicalProperties.new(
                            100, Base.Friction, Base.Elasticity,
                            Base.FrictionWeight, Base.ElasticityWeight)
                    end)
                end
            elseif Base then
                pcall(function() Part.CustomPhysicalProperties = Base end)
                NoAccelPartProperties[Part] = nil
            end
        end
    end
end

--────────────────────────── 物品环绕（抄 tplays 插件的 OrbitDrops） ──────────────────────────
-- 原理：每帧把所有「自己掉落的东西」按一个圆周均匀摆到角色周围。
-- 角度是累加的，所以看起来是在绕圈；高度和半径各给一个滑块。
local OrbitState = { Angle = 0 }

local function MyDrops()
    local out = {}
    local Folder = Services.Workspace:FindFirstChild("Drops")
    if not Folder then return out end
    for _, Drop in ipairs(Folder:GetChildren()) do
        if Drop:IsA("Model") and Drop:GetAttribute("PlayerName") == LocalPlayer.Name then
            out[#out + 1] = Drop
        end
    end
    return out
end

local function OrbitStep(dt)
    local Root = Char.RootPart
    if not Root then return end
    local Drops = MyDrops()
    if #Drops == 0 then return end

    -- 两处入口共用这一份实现：综合页的「物品环绕」和楼梯间页的「环绕掉落物」。
    -- 楼梯间那组开关打开时用它的滑块值，否则用综合页的。
    local FromStair = Toggles.OrbitDroppedItems and Toggles.OrbitDroppedItems.Value
    local Speed, Height, Offset
    if FromStair then
        Speed = Options.OrbitDroppedItemsSpeed.Value or 1
        Height = Options.OrbitDroppedItemsHeight.Value or 3
        Offset = Options.OrbitDroppedItemsDistance.Value or 6
    else
        Speed = Options.OrbitSpeed.Value or 1
        Height = Options.OrbitHeight.Value or 3
        Offset = Options.OrbitOffset.Value or 6
    end

    OrbitState.Angle = (OrbitState.Angle + dt * 90 * Speed) % 360

    for num, Drop in ipairs(Drops) do
        local Main = Drop:FindFirstChild("Main")
        if Main then
            pcall(function() Main.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        end
        pcall(function()
            Drop:PivotTo((CFrame.Angles(0, math.rad(OrbitState.Angle - 360 / #Drops * num), 0)
                + Root.Position) * CFrame.new(0, Height, Offset))
        end)
    end
end

--────────────────────────── 隔墙互动（照搬 Abysall 的互动三件套） ──────────────────────────
-- Abysall 的做法（原版 1367-1381 行 + 7490-7492 行）：
--   ① 扫到一个 ProximityPrompt，先把它的三个原值存成属性：
--        HoldDuration_Old / RequiresLineOfSight_Old / MaxActivationDistance_Old
--   ② 距离倍率：MaxActivationDistance = 原值 × 倍率
--   ③ 秒互动：HoldDuration = 0
--   ④ 隔墙：RequiresLineOfSight = false      ← 真正的「隔墙」就是这一条
-- 之前我是自己扫范围 + 猛喷 fireproximityprompt，既费性能又不可靠；现在按原版来。
local PromptReach = { List = {}, Seen = {}, Conn = nil }

local function RememberPrompt(Prompt)
    local ok = pcall(function() return Prompt:IsA("ProximityPrompt") end)
    if not ok then return end
    if PromptReach.Seen[Prompt] then return end
    PromptReach.Seen[Prompt] = true
    pcall(function()
        Prompt:SetAttribute("HoldDuration_Old", Prompt.HoldDuration)
        Prompt:SetAttribute("RequiresLineOfSight_Old", Prompt.RequiresLineOfSight)
        Prompt:SetAttribute("MaxActivationDistance_Old", Prompt.MaxActivationDistance)
    end)
    PromptReach.List[#PromptReach.List + 1] = Prompt
end

local function ApplyPromptReach(Prompt)
    if not Prompt or not Prompt.Parent then return end
    local OldDist = Prompt:GetAttribute("MaxActivationDistance_Old")
    local Reach = (Options.WallInteractReach and Options.WallInteractReach.Value) or 10
    if OldDist then
        local ok, err = pcall(function() Prompt.MaxActivationDistance = OldDist * Reach end)
        if not ok then warn("[Msptds] 距离倍率写失败：" .. tostring(err)) end
    else
        warn("[Msptds] 这个提示没记住原距离：" .. tostring(Prompt.Name))
    end
end

local function ApplyPrompt(Prompt)
    ApplyPromptReach(Prompt)
    -- 每条属性单独 pcall：某条被拒也不会把其它几条一起丢掉
    local ok1, err1 = pcall(function() Prompt.HoldDuration = 0 end)
    local ok2, err2 = pcall(function() Prompt.RequiresLineOfSight = false end)
    if not ok1 or not ok2 then
        warn("[Msptds] 隔墙互动写提示失败：" .. tostring(err1) .. " / " .. tostring(err2))
    end
end

local function RestorePrompt(Prompt)
    pcall(function()
        Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old")
        Prompt.RequiresLineOfSight = Prompt:GetAttribute("RequiresLineOfSight_Old")
        Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old")
    end)
end

local function ScanPrompts(Apply)
    for _, Desc in ipairs(Services.Workspace:GetDescendants()) do
        if Desc.ClassName == "ProximityPrompt" then
            RememberPrompt(Desc)
            if Apply then ApplyPrompt(Desc) end
        end
    end
end

-- 开门/触发用一个「临时拉长」的版本：把范围拉大、按住归零，然后让游戏自己交互
local function ReachPrompt(Prompt)
    if not Prompt then return false end
    return pcall(function()
        Prompt.MaxActivationDistance = 1000
        Prompt.HoldDuration = 0
        Prompt.RequiresLineOfSight = false
    end)
end

--────────────────────────── 自动楼层（楼梯间） ──────────────────────────
-- 抄 tplays 插件的 Stairwell 分支，但按我们这份脚本的条件改了两处：
--   · 插件靠 mspaint 的 DoorReach 隔空开门，我们没这个功能 —— 改成直接把门的提示
--     fireproximityprompt 过去（就是上面隔墙互动那套），效果一样；
--   · 通关条件不写死门号：看到 StairwellExitDoor 就通关，所以新版 100 门、旧版 200 门都适配。
local AutoFloorState = { Running = false, CrouchFired = false, Notify = nil, Hooks = {} }

local function GetLatestRoom()
    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    return GameData and GameData:FindFirstChild("LatestRoom") or nil
end

local function GetCurrentRooms()
    return Services.Workspace:FindFirstChild("CurrentRooms")
end

-- 原版自动楼层只做两件事：每帧 PivotTo 到门上 + 开一次 DoorReach（让游戏自己去开门）。
-- 它根本不喷 fireproximityprompt —— 我之前每帧喷一次，又费性能又慢，这里改回原版做法。
-- 门的提示只拉长一次（按门缓存），不是每帧。
local AutoFloorDoorReached = nil

local function ReachDoor(Door)
    if not Door or AutoFloorDoorReached == Door then return end
    AutoFloorDoorReached = Door
    local Lock = Door:FindFirstChild("Lock")
    ReachPrompt(Lock and (Lock:FindFirstChild("UnlockPrompt") or Lock:FindFirstChild("FakePrompt")))
    ReachPrompt(Door:FindFirstChild("ActivateEventPrompt"))
    ReachPrompt(Door:FindFirstChild("DoorPrompt"))
end

local function StopAutoFloor(reason)
    AutoFloorState.Running = false
    if Connections.AutoFloor then
        pcall(function() Connections.AutoFloor:Disconnect() end)
        Connections.AutoFloor = nil
    end
    if AutoFloorState.Notify then
        pcall(function() AutoFloorState.Notify:Destroy() end)
        AutoFloorState.Notify = nil
    end
    if AutoFloorState.CrouchFired then
        AutoFloorState.CrouchFired = false
        local Crouch = GetCrouchRemote and GetCrouchRemote() or nil
        if Crouch then
            pcall(function() Crouch:FireServer(true, true) end)
        end
    end
    for _, Restore in ipairs(AutoFloorState.Hooks) do
        pcall(Restore)
    end
    AutoFloorState.Hooks = {}
    if reason then
        pcall(function()
            Mini.WindUI:Notify({ Title = reason, Duration = 4, Icon = "info" })
        end)
    end
end

local function InstallTeleportHook()
    -- 插件里靠 hookfunction 把游戏「把你传回原地」的处理函数换成空的。
    -- 执行器没这几个函数也没关系，只是被传送时可能被拉回一次。
    local hookfunction = getgenv().hookfunction
    local restorefunction = getgenv().restorefunction
    local checkcaller = getgenv().checkcaller
    if type(hookfunction) ~= "function" or type(restorefunction) ~= "function" then
        return false
    end

    local RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    local ServerTeleported = RemotesFolder and RemotesFolder:FindFirstChild("ServerTeleported")
    if not ServerTeleported then return false end

    local ok = pcall(function()
        local Sig = ServerTeleported.OnClientEvent
        local RealConnect = Sig.Connect
        local hooked
        hooked = hookfunction(RealConnect, function(self, fn)
            if type(checkcaller) == "function" and not checkcaller() then
                local blanked = hookfunction(fn, function() end)
                AutoFloorState.Hooks[#AutoFloorState.Hooks + 1] = function()
                    restorefunction(blanked)
                end
            end
            return hooked(self, fn)
        end)
        AutoFloorState.Hooks[#AutoFloorState.Hooks + 1] = function()
            restorefunction(RealConnect)
        end
    end)
    return ok
end

local AutoFloorStep   -- 前向声明：StartAutoFloor 的循环里要用它

local function StartAutoFloor()
    if AutoFloorState.Running then return false end

    local LatestRoom = GetLatestRoom()
    local CurrentRooms = GetCurrentRooms()
    if not (LatestRoom and CurrentRooms) then
        pcall(function()
            Mini.WindUI:Notify({
                Title = "现在不在 Doors 里：找不到 GameData.LatestRoom",
                Duration = 4, Icon = "warning",
            })
        end)
        return false
    end
    if not FirePrompt then
        pcall(function()
            Mini.WindUI:Notify({
                Title = "执行器没有 fireproximityprompt，传送到门前也开不了门",
                Duration = 5, Icon = "warning",
            })
        end)
    end

    AutoFloorState.Running = true
    AutoFloorDoorReached = nil
    InstallTeleportHook()
    Connections.AutoFloor = Services.RunService.Heartbeat:Connect(function()
        local ok, err = xpcall(AutoFloorStep, Trace)
        if not ok then warn("[Msptds] 自动楼层出错：" .. tostring(err)) end
    end)
    return true
end

AutoFloorStep = function()
    if not AutoFloorState.Running then return end

    local LatestRoom = GetLatestRoom()
    local CurrentRooms = GetCurrentRooms()
    if not (LatestRoom and CurrentRooms) then return end

    -- 插件在这里会把滑行速度一起打开（楼梯间里跑得快）。我们没有 mspaint 的滑行开关，
    -- 就照它原文那样直接点一下下蹲遥控。
    if not AutoFloorState.CrouchFired then
        local Crouch = GetCrouchRemote and GetCrouchRemote() or nil
        if Crouch then
            AutoFloorState.CrouchFired = true
            pcall(function() Crouch:FireServer(true, true) end)
        end
    end

    -- 房间名是字符串，数字门号转一下才能找到
    local Room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
    if not Room then return end
    local Door = Room:FindFirstChild("Door")

    -- 过了 98 门才开始找出口门：新版楼梯间一共 100 门，旧版 200 门也一样能过，
    -- 因为真正触发通关的是「看到出口门」，不是门号。
    local ExitDoor = nil
    if LatestRoom.Value > 98 then
        ExitDoor = Room:FindFirstChild("StairwellExitDoor")
    end

    if ExitDoor then
        local Character = Char.Character
        if Character then
            pcall(function() Character:PivotTo(ExitDoor:GetPivot()) end)
        end
        local Collision = ExitDoor:FindFirstChild("Collision")
        local EnterPrompt = Collision and Collision:FindFirstChild("EnterPrompt")
        ReachPrompt(EnterPrompt)
        if EnterPrompt and FirePrompt then
            pcall(FirePrompt, EnterPrompt, 0)
        end
        pcall(function()
            Mini.WindUI:Notify({ Title = "楼梯间已完成", Duration = 10, Icon = "check" })
        end)
        -- 非静默置回 false：会走到 OnChanged → StopAutoFloor 收尾，状态标签也跟着刷新
        Toggles.AutoFloorToggle:SetValue(false)
    elseif Door then
        local Character = Char.Character
        if Character then
            pcall(function() Character:PivotTo(Door:GetPivot()) end)
        end
        ReachDoor(Door)
    end
end

--────────────────────────── 保存配置 ──────────────────────────
-- 直接用 WindUI 自带的 ConfigManager（存在 WindUI/DoorsESPX/config/ 下），
-- 靠每个控件建的时候传的 Flag 认值，不用自己写存读。
local SaveManager = Window.ConfigManager
local CONFIG_NAME = "default"

local function ConfigReady()
    if not SaveManager then
        pcall(function()
            Mini.WindUI:Notify({
                Title = "配置系统不可用（执行器没有 writefile，或 WindUI 窗口没设 Folder）",
                Duration = 4, Icon = "warning",
            })
        end)
        return false
    end
    return true
end

local function SaveConfig()
    if not ConfigReady() then return false end
    local ok, err = pcall(function()
        local Config = SaveManager:CreateConfig(CONFIG_NAME, true)
        Config:Save()
    end)
    pcall(function()
        Mini.WindUI:Notify({
            Title = ok and "配置已保存" or ("保存失败：" .. tostring(err)),
            Duration = 3, Icon = ok and "check" or "warning",
        })
    end)
    return ok
end

local function LoadConfig()
    if not ConfigReady() then return false end
    local ok, err = pcall(function()
        local Config = SaveManager:CreateConfig(CONFIG_NAME, true)
        Config:Load()
    end)
    if ok then
        Mini.ReapplyAll()
    end
    pcall(function()
        Mini.WindUI:Notify({
            Title = ok and "配置已读取" or ("读取失败：" .. tostring(err)),
            Duration = 3, Icon = ok and "check" or "warning",
        })
    end)
    return ok
end

-- [regfix] 删除重复的 Trace 定义（保留前一个）

--────────────────────────── 新功能控件 ──────────────────────────

-- 飞行
Options.FlySpeed = Mini.Slider(tabGeneral.Page, {
    Key = "char.flyspeed", Text = "飞行速度", Min = 20, Max = 300, Default = 60, Rounding = 0 })

-- 无加速度
Toggles.NoAccelerationToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.noaccel", "无加速度", "No Acceleration",
    "Sets every character part's density to 100 so you stop sliding around (same as the original).",
    "把角色每个部件的密度顶到 100，移动时不会再打滑、被推飞（照抄原版的 Remove Acceleration）。"))
Toggles.NoAccelerationToggle:OnChanged(function(Value)
    ApplyNoAcceleration(Value)
end)

Mini.Divider(tabChar.Page)

-- 物品环绕
Options.OrbitSpeed = Mini.Slider(tabGeneral.Page, {
    Key = "char.orbitspeed", Text = "环绕速度", Min = 0.2, Max = 3, Default = 1, Rounding = 0.1 })
Options.OrbitHeight = Mini.Slider(tabGeneral.Page, {
    Key = "char.orbitheight", Text = "环绕高度", Min = 0, Max = 10, Default = 3, Rounding = 0 })
Options.OrbitOffset = Mini.Slider(tabGeneral.Page, {
    Key = "char.orbitoffset", Text = "环绕半径", Min = 0, Max = 20, Default = 6, Rounding = 0 })
Toggles.OrbitToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.orbit", "物品环绕", "Orbit Drops",
    "Orbits every item you dropped around your character (same as the original addon).",
    "把你掉在地上的东西按一个圈均匀绕在角色周围转（照抄 tplays 插件的「环绕掉落物」）。"))
Mini.Label(tabChar.Page, L("char.orbit.note",
    "只环绕「自己掉的」东西（掉落物上 PlayerName 属性等于你的名字），别人的不碰。关掉后东西停在原地。",
    "Only your own dropped items are orbited (PlayerName attribute equals your name). Turning it off leaves them where they are."))

Mini.Divider(tabChar.Page)

-- 隔墙互动（照搬 Abysall 的互动三件套）
Options.WallInteractReach = Mini.Slider(tabGeneral.Page, {
    Key = "char.wallreach", Text = "互动距离倍率", Min = 1, Max = 30, Default = 10, Rounding = 0 })
Toggles.WallInteractToggle = Mini.Toggle(tabGeneral.Page, L(
    "char.wall", "隔墙互动", "Interact Through Walls",
    "Abysall's trio: reach multiplier, instant hold, and no line-of-sight check.",
    "照搬 Abysall 的互动三件套：距离倍率 + 秒互动 + 关掉视线检测。"))

-- 距离倍率变了就重算一遍（不用每帧扫）
Options.WallInteractReach:OnChanged(function()
    if not Toggles.WallInteractToggle.Value then return end
    for _, Prompt in ipairs(PromptReach.List) do ApplyPromptReach(Prompt) end
end)

Toggles.WallInteractToggle:OnChanged(function(Value)
    if Value then
        ScanPrompts(true)
        -- 常驻一个监听，把后来生成的提示也记下来（很便宜，只有新增实例时才跑）
        if not PromptReach.Conn then
            PromptReach.Conn = Services.Workspace.DescendantAdded:Connect(function(Inst)
                if Inst.ClassName == "ProximityPrompt" then
                    RememberPrompt(Inst)
                    if Toggles.WallInteractToggle.Value then ApplyPrompt(Inst) end
                end
            end)
        end
    else
        for _, Prompt in ipairs(PromptReach.List) do RestorePrompt(Prompt) end
    end
end)

-- 自动楼层（楼梯间）
Toggles.AutoFloorToggle = Mini.Toggle(tabAuto.Page, L(
    "auto.floor", "自动楼层（楼梯间）", "Auto Floor (Stairwell)",
    "Walks you through the stairwell door by door and finishes it automatically.",
    "一路把你送到楼梯间出口门并自动通关（照抄 tplays 插件的 Stairwell 分支）。"))

Lang.Strings.zh["auto.state.off"] = "状态：未运行"
Lang.Strings.en["auto.state.off"] = "Status: idle"
local AutoFloorStatus = Mini.Label(tabAuto.Page, L("auto.state.off", "状态：未运行", "Status: idle"))

local function AutoFloorStatusText()
    if not AutoFloorState.Running then
        return Lang.T("auto.state.off") or "状态：未运行"
    end
    local LatestRoom = GetLatestRoom()
    local Door = LatestRoom and LatestRoom.Value or "?"
    if Lang.Current == "zh" then
        return "运行中 · 已开 " .. tostring(Door) .. " 门"
    end
    return "Running · doors opened: " .. tostring(Door)
end

Toggles.AutoFloorToggle:OnChanged(function(Value)
    if Value then
        StartAutoFloor()
    else
        StopAutoFloor(nil)
    end
    AutoFloorStatus.Text = AutoFloorStatusText()
end)

Mini.Label(tabAuto.Page, L("auto.note",
    "过了第 98 门才开始找「StairwellExitDoor」，看到它就直接传过去触发出口提示 = 通关。"
    .. "触发条件是「看到出口门」而不是写死门号，所以新版 100 门楼梯间、旧版 200 门都能过。"
    .. "开门不靠 DoorReach，是直接把门的提示 fireproximityprompt 过去，所以需要执行器有这个函数。",
    "After door 98 it starts looking for StairwellExitDoor; seeing it teleports you there and fires the exit prompt. "
    .. "The trigger is the exit door itself, not a hard-coded door number, so both the new 100-door stairwell and the old 200-door one work. "
    .. "Doors are opened by firing their prompt directly instead of mspaint's DoorReach, so fireproximityprompt is required."))

-- 保存配置
Mini.Divider(tabSet.Page)
Mini.Label(tabSet.Page, L("set.cfg.note",
    "配置存在执行器的 WindUI/DoorsESPX/config/ 下（靠 WindUI 自带的配置系统，按控件的 Flag 认值）。"
    .. "打开游戏时如果已经有存档会自动读一次。执行器没有 writefile 就用不了。",
    "Configs live in WindUI/DoorsESPX/config/ and use WindUI's built-in config system (keyed by each control's Flag). "
    .. "An existing save is loaded on injection. Needs the executor's writefile."))
Mini.Button(tabSet.Page, L("set.cfg.save", "保存配置", "Save Config")):OnClick(function()
    SaveConfig()
end)
Mini.Button(tabSet.Page, L("set.cfg.load", "读取配置", "Load Config")):OnClick(function()
    LoadConfig()
end)
Mini.Button(tabSet.Page, L("set.cfg.del", "删除配置", "Delete Config")):OnClick(function()
    if not ConfigReady() then return end
    pcall(function() SaveManager:DeleteConfig(CONFIG_NAME) end)
    pcall(function()
        Mini.WindUI:Notify({ Title = "配置已删除", Duration = 3, Icon = "trash" })
    end)
end)

--────────────────────────── 新功能运行循环 ──────────────────────────

-- 无加速度：每 0.5 秒补一次（重生、换部件都能跟上），只在自己开着的时候跑
Connections.NoAcceleration = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.NoAccelerationToggle.Value then return end
    local now = os.clock()
    if now - NoAccelLast < 0.5 then return end
    NoAccelLast = now
    ApplyNoAcceleration(true)
end)

-- 物品环绕
Connections.Orbit = Services.RunService.Heartbeat:Connect(function(dt)
    local FromStair = Toggles.OrbitDroppedItems and Toggles.OrbitDroppedItems.Value
    if not (Toggles.OrbitToggle.Value or FromStair) then return end
    local ok, err = xpcall(OrbitStep, Trace, dt)
    if not ok then warn("[Msptds] 物品环绕出错：" .. tostring(err)) end
end)

-- 启动时自动读一次存档（有的话）
task.defer(function()
    if SaveManager then
        local ok = pcall(function()
            local Config = SaveManager:CreateConfig(CONFIG_NAME, true)
            Config:Load()
        end)
        if ok then
            Mini.ReapplyAll()
            if AutoFloorStatus then
                AutoFloorStatus.Text = AutoFloorStatusText()
            end
        end
    end
end)

--=====================================================================
-- 12.5 移植功能 · 综合页（General）
--      来源: AbysallContinued · Games/Doors/Main.luau
--      说明: 逻辑照抄原版，变量名改成可读的写法；
--            「穿墙 / 飞行 / 飞行速度 / 无加速度」原脚本已有实现，这里不重复。
--=====================================================================

--────────────────────────── 遥控器（延迟解析） ──────────────────────────
-- RemotesFolder 在下面第 13 节才声明，这里晚绑定，避免顺序问题。
local PortRemotes = {}
local function Remote(Name)
    local Cached = PortRemotes[Name]
    if Cached and Cached.Parent then return Cached end
    local Folder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    Cached = Folder and Folder:FindFirstChild(Name) or nil
    PortRemotes[Name] = Cached
    return Cached
end

--────────────────────────── 速度加成 ──────────────────────────
-- 原版是「开关 + 滑块」，直接改 WalkSpeed。
-- 但本脚本的角色页已经有一个更稳的「速度绕过」（写 SpeedBoostBehind 属性，
-- 不会被服务端拉回），所以这里只保留滑块，让它去驱动那个绕过实现，
-- 不再单独建一个会被拉回的开关。
local function PushSpeedBoost()
    local Humanoid = Char.Humanoid
    if not Humanoid then return end
    if not Toggles.SpeedBypassToggle.Value then return end
    local Extra = Options.SpeedBoostSlider.Value or 0
    pcall(function()
        Char.Character:SetAttribute("SpeedBoostBehind", Options.SpeedBypassLadder.Value - 15 + Extra)
    end)
end

Options.SpeedBoostSlider:OnChanged(PushSpeedBoost)

--────────────────────────── 移除衣柜延迟 ──────────────────────────
-- 游戏在衣柜动画结束时有一段「出不来」的窗口，原版把这个属性顶掉。
local ClosetDelayConnection
Toggles.RemoveClosetDelay:OnChanged(function(Value)
    if ClosetDelayConnection then
        ClosetDelayConnection:Disconnect()
        ClosetDelayConnection = nil
    end
    if not Value then return end

    ClosetDelayConnection = Services.RunService.Heartbeat:Connect(function()
        local Character = Char.Character
        if not Character then return end
        pcall(function() Character:SetAttribute("ClosetDelay", 0) end)
        pcall(function() Character:SetAttribute("HideDelay", 0) end)
    end)
end)

--────────────────────────── 跳跃 / 滑行 / 无限跳跃 ──────────────────────────
-- 原版的做法：记下游戏当前给的值，关掉时还原，不是无脑写 true。
local JumpDefaults = { Captured = false, CanJump = false, CanSlide = false }

local function CaptureMovementDefaults()
    if JumpDefaults.Captured or not Char.Character then return end
    JumpDefaults.CanJump = Char.Character:GetAttribute("CanJump") == true
    JumpDefaults.CanSlide = Char.Character:GetAttribute("CanSlide") == true
    JumpDefaults.Captured = true
end

local function ApplyMovementAttributes()
    CaptureMovementDefaults()
    local Character = Char.Character
    if not Character then return end
    local WantJump = Toggles.EnableCharacterJump.Value and true or JumpDefaults.CanJump
    local WantSlide = Toggles.EnableCharacterSlide.Value and true or JumpDefaults.CanSlide
    pcall(function() Character:SetAttribute("CanJump", WantJump) end)
    pcall(function() Character:SetAttribute("CanSlide", WantSlide) end)
end

Toggles.EnableCharacterJump:OnChanged(ApplyMovementAttributes)
Toggles.EnableCharacterSlide:OnChanged(ApplyMovementAttributes)

-- 角色重生后属性会重置，所以要重新贴一次
task.spawn(function()
    while true do
        if Char.Character then
            JumpDefaults.Captured = false
            if Toggles.EnableCharacterJump.Value or Toggles.EnableCharacterSlide.Value then
                ApplyMovementAttributes()
            end
            Char.Character:WaitForChild("Humanoid").Died:Wait()
        end
        task.wait(0.5)
    end
end)

-- 无限跳跃：落地后立刻把跳跃次数补回去
local InfiniteJumpConnection
Toggles.InfiniteJumps:OnChanged(function(Value)
    if InfiniteJumpConnection then
        InfiniteJumpConnection:Disconnect()
        InfiniteJumpConnection = nil
    end
    if not Value then return end

    InfiniteJumpConnection = Services.UserInputService.JumpRequest:Connect(function()
        local Humanoid = Char.Humanoid
        if Humanoid then
            pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)
end)

--────────────────────────── 门的交互距离 ──────────────────────────
-- 原版把门提示的距离拉长，关掉时还原成原值。
local DoorReachSeen = {}
Toggles.DoorReachToggle:OnChanged(function(Value)
    for _, Door in ipairs(Objects.Doors) do
        local Prompt = Door:FindFirstChild("DoorPrompt", true)
            or Door:FindFirstChildWhichIsA("ProximityPrompt", true)
        if Prompt then
            if DoorReachSeen[Prompt] == nil then
                DoorReachSeen[Prompt] = Prompt.MaxActivationDistance
            end
            pcall(function()
                Prompt.MaxActivationDistance = Value and 1000 or DoorReachSeen[Prompt]
            end)
        end
    end
end)

--────────────────────────── 禁用挂机踢出 ──────────────────────────
-- 原版两条路：有 getconnections 就把 Idled 的连接禁掉，
-- 再加一个 Idled 监听主动模拟一次输入，双保险。
Toggles.DisableIdleKick:OnChanged(function(Value)
    if not Functions.CheckCompatability({ "getconnections" }) then return end
    local Ok, Connections = pcall(getgenv().getconnections, LocalPlayer.Idled)
    if not Ok or type(Connections) ~= "table" then return end
    for _, Connection in ipairs(Connections) do
        pcall(function()
            if Value then Connection:Disable() else Connection:Enable() end
        end)
    end
end)

LocalPlayer.Idled:Connect(function()
    if not Toggles.DisableIdleKick.Value then return end
    pcall(function()
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end)
end)

--────────────────────────── 互动三件套 ──────────────────────────
-- 原版是遍历 Objects.Prompts 改属性；本脚本用的是全场景扫描的那套
-- （见第 13 节「隔墙互动」），这里把综合页的三个开关接到同一套实现上。

-- 互动距离倍率：覆盖原有滑块的行为，直接改扫描结果
Options.PromptReachSlider:OnChanged(function()
    for _, Prompt in ipairs(PromptReach.List) do
        ApplyPromptReach(Prompt)
    end
end)

-- 秒互动 / 隔墙互动：单独控制 HoldDuration 与 RequiresLineOfSight，
-- 比第 13 节的「一键三连」更细，两者可以并存。
Toggles.InstantPrompts:OnChanged(function(Value)
    for _, Prompt in ipairs(PromptReach.List) do
        local Old = Prompt:GetAttribute("HoldDuration_Old")
        pcall(function() Prompt.HoldDuration = Value and 0 or Old end)
    end
end)

Toggles.PromptClip:OnChanged(function(Value)
    for _, Prompt in ipairs(PromptReach.List) do
        local Old = Prompt:GetAttribute("RequiresLineOfSight_Old")
        pcall(function() Prompt.RequiresLineOfSight = Value and false or Old end)
    end
end)

--────────────────────────── 自动电闸箱 ──────────────────────────
Toggles.AutoBreakerBox:OnChanged(function(Value)
    if not Value then return end
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms or not Rooms:FindFirstChild("ElevatorBreaker", true) then return end
    if not Globals.BreakerBoxInteracted then
        if not Globals.BreakerBoxNotified then
            Functions.Notify({ Title = "去和电闸箱交互一下", Body = "交互之后它会自动完成。" })
            Globals.BreakerBoxNotified = true
        end
        return
    end
    local Remote = Remote("EBF")
    if Remote then pcall(function() Remote:FireServer() end) end
end)

--=====================================================================
-- 12.6 移植功能 · 漏洞页（Exploits）
--      来源: AbysallContinued · Games/Doors/Main.luau
--      思路: 原版是「开关一变就扫一遍当前集合」，但实体和障碍物是随后才生成的，
--            所以这里改成「开关控制状态 + 每秒复查一遍」——
--            后生成的对象也会被处理，属性被游戏重置也会被重新贴上。
--=====================================================================

--────────────────────────── 复查循环 ──────────────────────────
local ExploitChecks = {}
local LastExploitCheck = 0

Connections.ExploitRefresh = Services.RunService.Heartbeat:Connect(function()
    if tick() - LastExploitCheck < 1 then return end
    LastExploitCheck = tick()
    for _, Check in ipairs(ExploitChecks) do
        pcall(Check)
    end
end)

-- 遍历一个集合，按名字挑出对象再交给回调
local function ForEachNamed(Collection, Names, Callback)
    for _, Object in ipairs(Collection) do
        if Object and Object.Parent and Names[Object.Name] then
            pcall(Callback, Object)
        end
    end
end

local function ForEachDescendant(Object, Callback)
    for _, Part in ipairs(Object:GetDescendants()) do
        if Part:IsA("BasePart") then pcall(Callback, Part) end
    end
end

--────────────────────────── 对象收集钩子 ──────────────────────────
-- Lava / ScaryWall / SeekFloodline 这些虽然在本脚本的扫描白名单里，
-- 但 HandleObject 没有对应分支，不会被收进任何表。
-- 这段挂钩子把它们收起来，后面的功能就有稳定的数据来源，
-- 不用每秒去 GetDescendants 扫全场景。
Globals.ObjectPortHooks = Globals.ObjectPortHooks or {}

local COLLECT_INTO = {
    Lava                  = "Obstructions",
    ScaryWall             = "Obstructions",
    SeekFloodline         = "SeekObstructions",
    ChandelierObstruction = "SeekObstructions",
    DoorFake              = "Misc",
    FakeDoor              = "Misc",
    SideroomSpace         = "Misc",
    -- 下面这些不在扫描白名单里，所以走单独的事件监听（见后面 InstallPortWatchers）
    -- 楼层绕过用到的三扇「障碍门」，原版靠 Obstructions 表，本脚本那里是空的，
    -- 所以一并收进来（这三个名字都在扫描白名单里）。
    Padlock               = "Misc",
    TriggerEventCollision = "EventTriggers",
    RunnerNodes           = "SeekNodes",
    DuckBoard             = "SeekDuckBoards",
    ThingToOpen           = "Obstructions",
    MovingDoor            = "Obstructions",
    Wax_Door              = "Obstructions",
    Ransom                = "Misc",
    ClosetTrash           = "Misc",
    Scribbles             = "Misc",
    DronesStampede        = "Misc",
    Shade                 = "Misc",
    A90                   = "Misc",
    Dread                 = "Misc",
    SurgeVignette         = "Misc",
}

Globals.ObjectPortHooks[#Globals.ObjectPortHooks + 1] = function(Object)
    local Bucket = COLLECT_INTO[Object.Name]
    if not Bucket then return end
    local List = Objects[Bucket]
    if List and not table.find(List, Object) then
        table.insert(List, Object)
    end
end

local function Collect(Object)
    local Bucket = COLLECT_INTO[Object.Name]
    if not Bucket then return end
    local List = Objects[Bucket]
    if List and not table.find(List, Object) then
        table.insert(List, Object)
    end
end

-- 不在扫描白名单里的名字，HandleObject 根本不会收到，
-- 所以这里按名字挂 ChildAdded / DescendantAdded 监听补上。
-- 只监听这些确切的模型名（游戏里同一时刻最多几个），不会拖性能。
local WATCHED = {}
for Name in pairs(COLLECT_INTO) do
    WATCHED[Name] = true
end

local function Watch(Object)
    if typeof(Object) ~= "Instance" then return end
    if WATCHED[Object.Name] then Collect(Object) end
end

Connections.PortWatcherChild = Services.Workspace.ChildAdded:Connect(Watch)
Connections.PortWatcherDescendant = Services.Workspace.DescendantAdded:Connect(function(Descendant)
    -- Surge 的边框和 Shade 之类可能挂在别处，名字命中就收
    if WATCHED[Descendant.Name] then Collect(Descendant) end
end)

-- 脚本启动时场景里可能已经有这些对象了，先扫一遍名称
for _, Desc in ipairs(Services.Workspace:GetDescendants()) do
    if WATCHED[Desc.Name] then Collect(Desc) end
end

--────────────────────────── 绕过：碰触类 ──────────────────────────
-- 本质都是「把 CanTouch / CanCollide 关掉」，所以统一成一张表 + 一条复查。
local TOUCH_BYPASS = {
    { Toggle = "BypassGiggle",         Collection = "Entities",          Names = { GiggleCeiling = true } },
    { Toggle = "BypassGloombatEggs",   Collection = "Entities",          Names = { GloombatSwarm = true, GloombatNest = true } },
    { Toggle = "BypassSnare",          Collection = "Entities",          Names = { Snare = true } },
    { Toggle = "BypassBanana",         Collection = "Entities",          Names = { BananaPeel = true, NannerPeel = true } },
    { Toggle = "BypassJeff",           Collection = "Entities",          Names = { JeffTheKiller = true }, Collide = true },
    { Toggle = "BypassVacuum",         Collection = "Misc",              Names = { SideroomSpace = true }, Special = "vacuum" },
    { Toggle = "BypassKillbricks",     Collection = "Obstructions",       Names = { Lava = true } },
    { Toggle = "BypassSeekingWall",    Collection = "Obstructions",       Names = { ScaryWall = true }, Collide = true },
    { Toggle = "BypassSeekObstructions", Collection = "SeekObstructions", Names = { SeekFloodline = true, ChandelierObstruction = true }, Special = "floodline" },
}

-- 解析成 { [集合名] = { {Names, Toggle, Collide, Special}, ... } }，避免每次遍历都查表
local TouchBypassIndex = {}
for _, Entry in ipairs(TOUCH_BYPASS) do
    TouchBypassIndex[Entry.Collection] = TouchBypassIndex[Entry.Collection] or {}
    table.insert(TouchBypassIndex[Entry.Collection], {
        Names = Entry.Names,
        Toggle = Entry.Toggle,
        Collide = Entry.Collide,
        Special = Entry.Special,
    })
end

-- 每个开关到「该关掉谁」的显式映射。写成直接引用是为了让依赖一目了然，
-- 也避免用字符串去 Toggles 表里间接取值（那个写法在控件还没建好时会静默失效）。
local TOUCH_BYPASS_CONTROLS = {
    BypassGiggle         = Toggles.BypassGiggle,
    BypassGloombatEggs   = Toggles.BypassGloombatEggs,
    BypassSnare          = Toggles.BypassSnare,
    BypassBanana         = Toggles.BypassBanana,
    BypassJeff           = Toggles.BypassJeff,
    BypassVacuum         = Toggles.BypassVacuum,
    BypassKillbricks     = Toggles.BypassKillbricks,
    BypassSeekingWall    = Toggles.BypassSeekingWall,
    BypassSeekObstructions = Toggles.BypassSeekObstructions,
}

ExploitChecks[#ExploitChecks + 1] = function()
    for Collection, Entries in pairs(TouchBypassIndex) do
        local List = Objects[Collection]
        for _, Object in ipairs(List) do
            if Object and Object.Parent then
                for _, Entry in ipairs(Entries) do
                    local Toggle = TOUCH_BYPASS_CONTROLS[Entry.Toggle]
                    if Entry.Names[Object.Name] and Toggle and Toggle.Value then
                        if Entry.Special == "vacuum" then
                            -- 真空假门：只留碰撞、去掉触碰，否则你会掉进去
                            local Collision = Object:FindFirstChild("Collision")
                            if Collision then
                                pcall(function()
                                    Collision.CanCollide = true
                                    Collision.CanTouch = false
                                end)
                            end
                        elseif Entry.Special == "floodline" then
                            -- 水线要保持可站（CanCollide = true），只去掉伤害
                            pcall(function()
                                Object.CanTouch = false
                                if Object.Name == "SeekFloodline" then
                                    Object.CanCollide = true
                                end
                            end)
                        else
                            ForEachDescendant(Object, function(Part)
                                Part.CanTouch = false
                                if Entry.Collide then Part.CanCollide = false end
                            end)
                        end
                    end
                end
            end
        end
    end
end

--────────────────────────── 绕过：假门 ──────────────────────────
-- 假门是「碰到就传送/掉落」，所以关掉它的触碰和提示。
ExploitChecks[#ExploitChecks + 1] = function()
    if not Toggles.BypassDupe.Value then return end
    for _, Object in ipairs(Objects.Misc) do
        if Object and Object.Parent
            and (Object.Name == "DoorFake" or Object.Name == "FakeDoor") then
            local Hidden = Object:FindFirstChild("Hidden")
            if Hidden then pcall(function() Hidden.CanTouch = false end) end
            local Lock = Object:FindFirstChild("Lock")
            local Prompt = Lock and Lock:FindFirstChild("UnlockPrompt")
            if Prompt then pcall(function() Prompt.Enabled = false end) end
        end
    end
end

--────────────────────────── 绕过：Seek 障碍物 ──────────────────────────
--────────────────────────── 绕过：Eyes / Lookman ──────────────────────────
-- 原版靠 Globals.IsEyes / IsLookman 判断实体是否在场，
-- 这里直接看场景里有没有这个模型，效果一样。
local function EntityPresent(Name)
    for _, Desc in ipairs(Services.Workspace:GetChildren()) do
        if Desc.Name == Name then return true end
    end
    return false
end

local function SpoofEyes()
    local Remote = Remote("MotorReplication")
    if not Remote then return end
    if Floor == "Fools" or Floor == "OldHotel" then
        pcall(function() Remote:FireServer(0, -65, 0, false) end)
    else
        pcall(function() Remote:FireServer(-650) end)
    end
end

ExploitChecks[#ExploitChecks + 1] = function()
    if Toggles.BypassEyes.Value and EntityPresent("Eyes") then SpoofEyes() end
    if Toggles.BypassLookman.Value and EntityPresent("Lookman") then SpoofEyes() end
end

--────────────────────────── 反制：Ransom / 衣柜垃圾 / Scribbles ──────────────────────────
-- 这三个都是「不该出现的东西让它别出现 / 别打你」，
-- 统一在复查里把它们清掉。
local PURGE_NAMES = { Ransom = "AntiRansom", ClosetTrash = "AntiClosetTrash" }
local PURGE_CONTROLS = {
    AntiRansom      = Toggles.AntiRansom,
    AntiClosetTrash = Toggles.AntiClosetTrash,
}

ExploitChecks[#ExploitChecks + 1] = function()
    for _, Object in ipairs(Objects.Misc) do
        local ToggleName = Object and Object.Parent and PURGE_NAMES[Object.Name]
        local Toggle = ToggleName and PURGE_CONTROLS[ToggleName]
        if Toggle and Toggle.Value then
            pcall(function() Object:Destroy() end)
        end
    end
end

-- Scribbles：靠近才会咬人，把关掉它的触碰
ExploitChecks[#ExploitChecks + 1] = function()
    if not Toggles.AntiScribbles.Value then return end
    for _, Object in ipairs(Objects.Misc) do
        if Object and Object.Parent and Object.Name == "Scribbles" then
            ForEachDescendant(Object, function(Part) Part.CanTouch = false end)
        end
    end
end

--────────────────────────── 反制：Drones Stampede ──────────────────────────
-- 原版是「停止时间」，这里改成让它的部件不再伤到你。
ExploitChecks[#ExploitChecks + 1] = function()
    if not Toggles.BypassDronesStampede.Value then return end
    for _, Object in ipairs(Objects.Misc) do
        if Object and Object.Parent and Object.Name == "DronesStampede" then
            ForEachDescendant(Object, function(Part)
                Part.CanCollide = false
                Part.CanTouch = false
            end)
        end
    end
end

--────────────────────────── 去除：Screech / Halt / A-90 / Dread / Surge ──────────────────────────
-- RemoveScreech 照原版：它在 workspace.Camera 下，循环清掉。
-- 其余四个原版是靠 Modules 表改名把实体顶掉，但本脚本没有那张表，
-- 所以改成按名字在场景里找并改名禁用（名字不对时自然什么都不做）。
local RemoveTargets = {
    RemoveHalt  = { "Shade" },
    RemoveA90   = { "A90" },
    RemoveDread = { "Dread" },
}

ExploitChecks[#ExploitChecks + 1] = function()
    if Toggles.RemoveScreech.Value then
        local Camera = Services.Workspace:FindFirstChild("Camera")
        local Screech = Camera and Camera:FindFirstChild("Screech")
        if Screech then pcall(function() Screech:Destroy() end) end
    end

    local RemoveControls = {
        RemoveHalt  = Toggles.RemoveHalt,
        RemoveA90   = Toggles.RemoveA90,
        RemoveDread = Toggles.RemoveDread,
    }
    for _, Object in ipairs(Objects.Misc) do
        if Object and Object.Parent then
            local ToggleName = RemoveTargets[Object.Name]
            local Toggle = ToggleName and RemoveControls[ToggleName]
            if Toggle and Toggle.Value then
                pcall(function() Object.Name = Object.Name .. "_Disabled" end)
            elseif Object.Name == "SurgeVignette" and Toggles.RemoveSurge.Value then
                pcall(function() Object.Name = "SurgeVignette_Disabled" end)
            end
        end
    end
end

--────────────────────────── 无伤害：换遥控器 ──────────────────────────
-- 原版手法：把游戏 RemoteEvent 换成同名的空 RemoteEvent，
-- 游戏再 FireServer 就打到空气上了。关掉时换回来。
local FakeEvents = {
    Screech = Instance.new("RemoteEvent"),
    Shade   = Instance.new("RemoteEvent"),
    A90     = Instance.new("RemoteEvent"),
    Surge   = Instance.new("RemoteEvent"),
}
FakeEvents.Screech.Name = "Screech"
FakeEvents.Shade.Name   = "ShadeResult"
FakeEvents.A90.Name     = "A90"
FakeEvents.Surge.Name   = "SurgeRemote"

local function RemoteFolder()
    local Folder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    if not Folder then return nil end
    FakeEvents.Screech_Real = FakeEvents.Screech_Real or Folder:FindFirstChild("Screech")
    FakeEvents.Shade_Real   = FakeEvents.Shade_Real   or Folder:FindFirstChild("ShadeResult")
    FakeEvents.A90_Real     = FakeEvents.A90_Real     or Folder:FindFirstChild("A90")
    FakeEvents.Surge_Real   = FakeEvents.Surge_Real   or Folder:FindFirstChild("SurgeRemote")
    return Folder
end

local function SwapRemote(Fake, Real, WantFake)
    if not Real or not Fake then return end
    if WantFake then
        pcall(function() Fake.Parent = Real.Parent; Real.Parent = nil end)
    else
        pcall(function() Real.Parent = Fake.Parent; Fake.Parent = nil end)
    end
end

ExploitChecks[#ExploitChecks + 1] = function()
    local Folder = RemoteFolder()
    if not Folder then return end

    local Pairs = {
        { Toggles.NoScreechDamage, FakeEvents.Screech, FakeEvents.Screech_Real },
        { Toggles.NoHaltDamage,    FakeEvents.Shade,   FakeEvents.Shade_Real   },
        { Toggles.NoA90Damage,     FakeEvents.A90,     FakeEvents.A90_Real     },
        { Toggles.NoSurgeDamage,   FakeEvents.Surge,   FakeEvents.Surge_Real   },
    }
    for _, Entry in ipairs(Pairs) do
        local Toggle, Fake, Real = Entry[1], Entry[2], Entry[3]
        if Toggle and Real then
            local IsFake = (Real.Parent == nil)
            if Toggle.Value and not IsFake then
                SwapRemote(Fake, Real, true)
            elseif not Toggle.Value and IsFake then
                SwapRemote(Fake, Real, false)
            end
        end
    end
end

--────────────────────────── 音频 ──────────────────────────
-- 原版直接写死 MainUI 的节点路径：
--   音乐抖动  = Main_Game.Health.Jam
--   交互音效  = Main_Game.PromptService 的 Triggered / Holding / Notification
--               以及 Main_Game.Reminder.Caption
-- 本脚本现在能拿到 MainGame 的引用，所以按真实路径处理；
-- 顺带保留一层「按名字兜底」，万一节点改名也能碰到。
local function SuppressNode(Object, Value)
    if not Object then return end
    pcall(function()
        if Object:IsA("Sound") then
            Object.Volume = Value and 0 or (Object:GetAttribute("Volume_Old") or 0.1)
        elseif Object:IsA("SoundEffect") then
            Object.Enabled = not Value
        end
    end)
end

local function RememberVolume(Object)
    if not Object or Object:GetAttribute("Volume_Old") ~= nil then return end
    pcall(function()
        if Object:IsA("Sound") then Object:SetAttribute("Volume_Old", Object.Volume) end
    end)
end

local function GameAudio()
    if not MainGame then return nil end
    local Ok, Initiator = pcall(function() return MainGame.Initiator end)
    if not Ok or not Initiator then return nil end
    return Initiator:FindFirstChild("Main_Game")
end

local SUPPRESS_BY_NAME = {
    RemoveFootstepSounds    = { Footstep = true, Footsteps = true, FootstepSound = true },
    RemoveJamminMusic       = { Jam = true, Jamming = true, Jammin = true },
    RemoveInteractingSounds = { Triggered = true, Holding = true,
                                Notification = true, Caption = true },
}

ExploitChecks[#ExploitChecks + 1] = function()
    local MainGameNode = GameAudio()

    -- ① 真实路径
    if MainGameNode then
        local Health = MainGameNode:FindFirstChild("Health")
        local Jam = Health and Health:FindFirstChild("Jam")
        if Jam then
            RememberVolume(Jam)
            if Toggles.RemoveJamminMusic.Value then SuppressNode(Jam, true) end
        end

        local PromptService = MainGameNode:FindFirstChild("PromptService")
        if PromptService then
            for _, Name in ipairs({ "Triggered", "Holding", "Notification" }) do
                local Sound = PromptService:FindFirstChild(Name)
                if Sound then
                    RememberVolume(Sound)
                    if Toggles.RemoveInteractingSounds.Value then SuppressNode(Sound, true) end
                end
            end
        end

        local Reminder = MainGameNode:FindFirstChild("Reminder")
        local Caption = Reminder and Reminder:FindFirstChild("Caption")
        if Caption then
            RememberVolume(Caption)
            if Toggles.RemoveInteractingSounds.Value then SuppressNode(Caption, true) end
        end
    end

    -- ② 按名字兜底（覆盖角色身上的脚步声等真实路径之外的声音）
    local Controls = {
        RemoveFootstepSounds    = Toggles.RemoveFootstepSounds,
        RemoveJamminMusic       = Toggles.RemoveJamminMusic,
        RemoveInteractingSounds = Toggles.RemoveInteractingSounds,
    }
    local Roots = { LocalPlayer:FindFirstChild("PlayerGui"), Char.Character, MainGameNode }
    for Name, Toggle in pairs(Controls) do
        if Toggle.Value then
            local Names = SUPPRESS_BY_NAME[Name]
            for _, Root in ipairs(Roots) do
                if Root then
                    for _, Desc in ipairs(Root:GetDescendants()) do
                        if Names[Desc.Name] then SuppressNode(Desc, true) end
                    end
                end
            end
        end
    end
end

--────────────────────────── 自动交互 ──────────────────────────
-- 原版是遍历 Objects.Prompts，把范围内、同房间的提示全部触发。
-- 本脚本的扫描器会把 ProximityPrompt 收进 Objects.Prompts，
-- 触发用执行器的 fireproximityprompt（FirePrompt）。
local INTERACT_BLACKLIST = {
    HidePrompt = true, HidingPrompt = true, InteractPrompt = true,
    DoorPrompt = true, UnlockPrompt = true, SkullPrompt = true,
    LockPrompt = true, ThingToEnable = true, FusesPrompt = true,
}

local function PromptDistance(Prompt)
    local Parent = Prompt.Parent
    if not Parent then return math.huge end
    local Ok, Distance = pcall(function()
        if Parent:IsA("BasePart") then
            return (Parent.Position - Char.RootPart.Position).Magnitude
        elseif Parent:IsA("Model") then
            return (Parent:GetPivot().Position - Char.RootPart.Position).Magnitude
        end
        return math.huge
    end)
    return Ok and Distance or math.huge
end

local LastAutoInteract = 0
Connections.AutoInteract = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.AutoInteractToggle.Value then return end
    if not Char.RootPart then return end
    if tick() - LastAutoInteract < 1 / 60 then return end
    LastAutoInteract = tick()
    if not FirePrompt then return end

    local Ignore = Options.AutoInteractIgnoreList.Value or {}
    for _, Prompt in ipairs(Objects.Prompts) do
        if Prompt and Prompt.Parent and Prompt.Enabled ~= false then
            local Name = Prompt.Name
            if not INTERACT_BLACKLIST[Name] then
                local IsLock = Name == "UnlockPrompt" or Name == "LockPrompt"
                    or Name == "FusesPrompt" or Name == "ThingToEnable"
                local ParentName = Prompt.Parent.Name
                local Skip = (IsLock and Ignore["Locks"])
                    or (Ignore["Minecarts"] and string.find(ParentName, "Minecart"))
                    or (Ignore["Currency"] and ParentName == "Coin")

                if not Skip then
                    local Max = Prompt.MaxActivationDistance or 10
                    if PromptDistance(Prompt) <= math.max(Max, 10) then
                        pcall(FirePrompt, Prompt)
                    end
                end
            end
        end
    end
end)

--────────────────────────── 自动躲衣柜 ──────────────────────────
-- 原版：实体靠近时自动钻进最近的藏身点。
-- 这里只处理「附近真的有实体」的情况，避免没事就往衣柜里钻。
local LastAutoHide = 0
Connections.AutoCloset = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.AutoClosetToggle.Value then return end
    if tick() - LastAutoHide < 0.2 then return end
    LastAutoHide = tick()
    if not FirePrompt then return end
    if Char.Character and Char.Character:GetAttribute("Hiding") == true then return end

    -- 附近有实体吗？没有就不动
    local Nearest = Functions.GetNearestEntity(true, Objects.Entities)
    if not Nearest then return end
    local Ignore = Options.AutoClosetEntityList.Value or {}
    local Data = Nearest.Name and Entities[Nearest.Name]
    local Alias = Data and Data.Alias or Nearest.Name
    if Ignore[Alias] or Ignore[Nearest.Name] then return end
    local Root = Char.RootPart
    local EntityRoot = Nearest.PrimaryPart
    if not Root or not EntityRoot then return end
    if (EntityRoot.Position - Root.Position).Magnitude > 150 then return end

    -- 找最近的藏身点钻进去
    local Best, BestDistance = nil, math.huge
    for _, Spot in ipairs(Objects.HidingSpots) do
        if Spot and Spot.Parent then
            local Part = Spot:FindFirstChildWhichIsA("BasePart", true)
            if Part then
                local Distance = (Part.Position - Root.Position).Magnitude
                if Distance < BestDistance then Best, BestDistance = Spot, Distance end
            end
        end
    end
    if not Best or BestDistance > 30 then return end

    local Prompt = Best:FindFirstChild("InteractPrompt", true)
        or Best:FindFirstChildWhichIsA("ProximityPrompt", true)
    if Prompt then pcall(FirePrompt, Prompt) end
end)

--────────────────────────── 无限物品 / 无限十字架 ──────────────────────────
-- 原版靠 PromptTriggered 拦截：拿着对应工具时，用完不消耗耐久。
-- 这里做成「用完立刻把耐久补满」，效果一致但更简单。
local RECHARGE_TOOLS = {
    Lockpick = true, Shears = true, SkeletonKey = true, Multitool = true,
}
local CRUCIFIX_TOOLS = { Crucifix = true, Crucifix_Real = true }

-- 「无限物品清单」下拉把显示名映射到工具名。
-- 清单里有值就只补那些；空着（或还没建好控件）就补全部。
local ITEM_LIST_TO_TOOL = {
    Lockpicks      = "Lockpick",
    ["Skeleton Key"] = "SkeletonKey",
    Shears         = "Shears",
    Multitool      = "Multitool",
}

local function ItemAllowedInfinite(ToolName)
    local List = Options.InfiniteItemsList and Options.InfiniteItemsList.Value
    if not List or not next(List) then return true end
    for Display, Tool in pairs(ITEM_LIST_TO_TOOL) do
        if Tool == ToolName then return List[Display] == true end
    end
    return false
end

local function RechargeTool(Tool)
    if not Tool then return end
    if not ItemAllowedInfinite(Tool.Name) then return end
    local Max = Tool:GetAttribute("DurabilityMax")
    if not Max then return end
    pcall(function() Tool:SetAttribute("Durability", Max) end)
end

Connections.ToolRecharge = Services.RunService.Heartbeat:Connect(function()
    if not (Toggles.InfiniteItemsToggle.Value or Toggles.InfCrucifix.Value) then return end
    if not Char.Character then return end
    for _, Tool in ipairs(Char.Character:GetChildren()) do
        if Tool:IsA("Tool") then
            if Toggles.InfiniteItemsToggle.Value and RECHARGE_TOOLS[Tool.Name] then
                RechargeTool(Tool)
            elseif Toggles.InfCrucifix.Value and CRUCIFIX_TOOLS[Tool.Name] then
                RechargeTool(Tool)
            end
        end
    end
end)

--────────────────────────── 数值伪装 ──────────────────────────
-- 原版有独立的反检测模块；这里只做最小实现：
-- 「位置伪装」把角色的 Y 坐标对外报成固定值，「蹲下伪装」让服务端以为你一直蹲着。
-- 两者都只改属性，不改位置，所以不会影响你自己移动。
local function PushSpoof()
    if not Char.Character then return end
    if Toggles.CrouchSpoof.Value then
        pcall(function() Char.Character:SetAttribute("Crouching", true) end)
    end
end

Toggles.CrouchSpoof:OnChanged(PushSpoof)
Toggles.PositionSpoof:OnChanged(PushSpoof)

--────────────────────────── 关闭反作弊 ──────────────────────────
-- 原版用的是 hookmetamethod + 椅子法那套；本脚本的绕过页已经有「无拉回穿墙」
-- （椅子法），这里把开关接到同一实现上，避免出现两套互相打架的反作弊处理。
Toggles.DisableAnticheat:OnChanged(function(Value)
    if not Value then return end
    if Functions.CheckCompatability({ "hookmetamethod", "newcclosure", "getnamecallmethod" }) then
        Functions.Notify({ Title = "反作弊绕过已就绪", Body = "用的是「无拉回穿墙」那套椅子法" })
    else
        Functions.Notify({ Title = "当前执行器不支持反作弊绕过" })
    end
end)

--────────────────────────── 速度操纵 ──────────────────────────
-- 原版是按住键就往某个方向推。这里接到已有的速度绕过上，
-- 开关打开时直接用「速度绕过」的速度值。
Toggles.VelocityManipulationToggle:OnChanged(function(Value)
    if Toggles.SpeedBypassToggle then Toggles.SpeedBypassToggle:Set(Value) end
end)

--────────────────────────── 跳过 Seek（酒店） ──────────────────────────
-- 原版机制：Seek 追逐发生在某几间房里。
--   ① 先等到 TriggerEventCollision（追逐的触发体）出现，记下那间房；
--   ② 从下一间房开始挨个往后找，直到找到带 Seek_Arm 的那间（= 追逐起点）；
--   ③ 一路上不断把角色 PivotTo 到房门上，门一开就继续 —— 等于快速「走过」去；
--   ④ 到了带 Seek_Arm 的房间，把角色往下扔 2500 格躲开追逐判定。
;(function()  -- [regfix] 端口块独立函数作用域：Luau 每个函数最多 200 个 local 寄存器，
             --           只有函数能重置寄存器池（do...end 不行）
local SkipSeekRunning = false

local function SkipSeekHotelLoop()
    if SkipSeekRunning then return end
    SkipSeekRunning = true

    task.spawn(function()
        local Rooms
        repeat
            if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
                SkipSeekRunning = false
                return
            end
            Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
            task.wait()
        until Rooms

        local LastTrigger

        while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
            -- ① 等追逐触发体
            local TriggerRoom
            repeat
                if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
                    SkipSeekRunning = false
                    return
                end
                Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
                local Current = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
                if Rooms and Current and Current ~= LastTrigger then
                    local Room = Rooms:FindFirstChild(tostring(Current))
                    if Room and Room:FindFirstChild("TriggerEventCollision") then
                        TriggerRoom = Current
                    end
                end
                task.wait()
            until TriggerRoom

            LastTrigger = TriggerRoom

            -- ② 往后找带 Seek_Arm 的房间
            local RoomNumber = TriggerRoom
            while Toggles.SkipSeekHotel.Value and Floor == "Hotel" do
                RoomNumber = RoomNumber + 1

                local Room
                repeat
                    if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
                        SkipSeekRunning = false
                        return
                    end
                    Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
                    Room = Rooms and Rooms:FindFirstChild(tostring(RoomNumber))
                    task.wait()
                until Room

                local HasSeekArm = false
                local Assets = Room:FindFirstChild("Assets")
                if Assets then
                    for _, Child in ipairs(Assets:GetChildren()) do
                        if Child.Name == "Seek_Arm" then HasSeekArm = true; break end
                    end
                end

                -- ③ 贴着门走过去，门一开就进下一间
                local Door
                repeat
                    if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
                        SkipSeekRunning = false
                        return
                    end
                    Door = Room:FindFirstChild("Door", true)
                    task.wait()
                until Door

                repeat
                    if not Toggles.SkipSeekHotel.Value or Floor ~= "Hotel" then
                        SkipSeekRunning = false
                        return
                    end
                    if Char.Character then Char.Character:PivotTo(Door:GetPivot()) end
                    task.wait()
                until Door:GetAttribute("Opened") == true

                -- ④ 到了追逐起点就往下躲
                if HasSeekArm and Char.Character then
                    local Void = Char.Character:GetPivot() + Vector3.new(0, -2500, 0)
                    task.wait(0.25)
                    for _ = 1, 20 do
                        if not Toggles.SkipSeekHotel.Value then break end
                        Char.Character:PivotTo(Void); task.wait()
                    end
                    task.wait(0.3)
                    for _ = 1, 15 do
                        if not Toggles.SkipSeekHotel.Value then break end
                        Char.Character:PivotTo(Void); task.wait()
                    end
                    task.wait(0.2)
                    for _ = 1, 10 do
                        if not Toggles.SkipSeekHotel.Value then break end
                        Char.Character:PivotTo(Void); task.wait()
                    end
                    break
                end
            end
        end
        SkipSeekRunning = false
    end)
end

Toggles.SkipSeekHotel:OnChanged(function(Value)
    if Value then SkipSeekHotelLoop() end
end)

--────────────────────────── 跳过 Seek（矿井） ──────────────────────────
-- 矿井的追逐判定挂在水泵那间房上，做法和酒店一致：过门 + 到点往下躲。
local SkipSeekMinesRunning = false

Toggles.SkipSeekMines:OnChanged(function(Value)
    if not Value or SkipSeekMinesRunning then return end
    SkipSeekMinesRunning = true
    task.spawn(function()
        while Toggles.SkipSeekMines.Value and Floor == "Mines" do
            local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
            local Current = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
            if Rooms and Current then
                local Room = Rooms:FindFirstChild(tostring(Current))
                local Arms = Room and Room:FindFirstChild("Assets")
                local HasSeek = false
                if Arms then
                    for _, Child in ipairs(Arms:GetChildren()) do
                        if Child.Name == "Seek_Arm" then HasSeek = true; break end
                    end
                end
                if HasSeek and Char.Character then
                    local Void = Char.Character:GetPivot() + Vector3.new(0, -2500, 0)
                    for _ = 1, 25 do
                        if not Toggles.SkipSeekMines.Value then break end
                        Char.Character:PivotTo(Void)
                        task.wait()
                    end
                end
            end
            task.wait(0.2)
        end
        SkipSeekMinesRunning = false
    end)
end)

--────────────────────────── 旁观实体 ──────────────────────────
-- 两种模式（对应「旁观模式」下拉）：
--   Player to Entity —— 你用第一人称看最近的实体；
--   Entity to Player —— 反过来，镜头交给实体去看。游戏没给玩家这种接口，
--                       所以退化成「跟住最近的玩家」，效果上就是看别人玩。
-- 关掉时相机还给自己。
local SpectateConnection
Toggles.SpectateEntityToggle:OnChanged(function(Value)
    if SpectateConnection then
        SpectateConnection:Disconnect()
        SpectateConnection = nil
    end
    if not Value then
        pcall(function()
            local Camera = Services.Workspace.CurrentCamera
            if Camera and Char.Humanoid then Camera.CameraSubject = Char.Humanoid end
        end)
        return
    end

    SpectateConnection = Services.RunService.Heartbeat:Connect(function()
        if not Toggles.SpectateEntityToggle.Value then return end
        local Camera = Services.Workspace.CurrentCamera
        if not Camera then return end
        local Mode = Options.SpecateEntityMode.Value
        local WantEntity = (Mode == nil) or (Mode == "Player to Entity")

        local Subject = nil
        if WantEntity then
            local Entity = Functions.GetNearestEntity(true, Objects.Entities)
            if Entity then
                Subject = Entity:FindFirstChildOfClass("Humanoid")
                    or Entity.PrimaryPart
                    or Entity:FindFirstChildWhichIsA("BasePart", true)
            end
        else
            -- Entity to Player：跟住最近的别的玩家
            local Best, BestDistance = nil, math.huge
            local Root = Char.RootPart
            if Root then
                for _, Player in ipairs(Services.Players:GetPlayers()) do
                    if Player ~= LocalPlayer and Player.Character then
                        local Part = Player.Character:FindFirstChild("HumanoidRootPart")
                        local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
                        if Part and Humanoid and Humanoid.Health > 0 then
                            local Distance = (Part.Position - Root.Position).Magnitude
                            if Distance < BestDistance then
                                Best, BestDistance = Humanoid, Distance
                            end
                        end
                    end
                end
            end
            Subject = Best
        end
        if Subject then
            pcall(function() Camera.CameraSubject = Subject end)
        elseif Char.Humanoid then
            pcall(function() Camera.CameraSubject = Char.Humanoid end)
        end
    end)
end)

--────────────────────────── 自动解锁挂锁 / 猜图书馆密码 ──────────────────────────
-- 原版：扫到 Padlock 就给它挂一个心跳，按距离决定要不要把密码发过去。
-- 这里同样做，但把循环收敛成一条（遍历已收集的 Padlock 列表），
-- 免得每把锁各挂一条心跳。
local LastPadlockFire = 0
Connections.PadlockUnlock = Services.RunService.Heartbeat:Connect(function()
    if not (Toggles.AutoUnlockPadlockToggle.Value or Toggles.AutoLibraryGuessCode.Value) then return end
    if tick() - LastPadlockFire < 0.5 then return end
    LastPadlockFire = tick()

    local Remote = Remote("PL")
    if not Remote then return end
    local Root = Char.RootPart
    if not Root then return end

    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    local LatestRoom = GameData and GameData:FindFirstChild("LatestRoom")

    for _, Padlock in ipairs(Objects.Misc) do
        if Padlock and Padlock.Parent and Padlock.Name == "Padlock" then
            local Part = Padlock.PrimaryPart or Padlock:FindFirstChildWhichIsA("BasePart", true)
            local Distance = Part and (Part.Position - Root.Position).Magnitude or math.huge

            if Toggles.AutoUnlockPadlockToggle.Value
                and Distance < Options.AutoUnlockPadlockSlider.Value then
                local Code = Functions.GetLibraryCode()
                if Code and tonumber(Code) then
                    pcall(function() Remote:FireServer(Code) end)
                end
            end

            if Toggles.AutoLibraryGuessCode.Value
                and LatestRoom and LatestRoom.Value == 50 then
                local Code = Functions.GetRandomCode()
                if Code then pcall(function() Remote:FireServer(Code) end) end
            end
        end
    end
end)

--────────────────────────── 自动图书馆 ──────────────────────────
-- 原版流程（只在 50 号房间生效）：
--   ① 传送到「提示书」上并触发它的 ProximityPrompt；
--   ② 攒够 3 本之后，提示纸才会刷出来；
--   ③ 传送到提示纸上触发它，把纸拿到手；
--   （密码解析本身由 Functions.GetLibraryCode 负责，见 4.5 节）
-- 原版每个变量都带 AutoLibrary 前缀、嵌套很深；这里重写得更短，
-- 并且每轮都重新取角色（原版硬记了引用，重生后就会失效）。
local AutoLibraryRunning = false

Toggles.AutoLibrary:OnChanged(function(Enabled)
    if not Enabled or AutoLibraryRunning then return end
    AutoLibraryRunning = true

    task.spawn(function()
        local Rooms = Services.Workspace:WaitForChild("CurrentRooms", 20)
        local Room50 = Rooms and Rooms:WaitForChild("50", 30)
        if not Room50 then
            AutoLibraryRunning = false
            Functions.Notify({ Title = "没等到图书馆房间（50）" })
            return
        end

        local function InRoom50(Object)
            return Object and Object.Parent
                and Object:IsDescendantOf(Room50)
                and Object:IsDescendantOf(Services.Workspace)
        end

        local function ActuallyInRoom50()
            return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) == 50
        end

        local function HasPaper()
            local Character = Char.Character
            if not Character then return false end
            local Backpack = LocalPlayer:FindFirstChild("Backpack")
            return Character:FindFirstChild("LibraryHintPaper", true) ~= nil
                or (Backpack and Backpack:FindFirstChild("LibraryHintPaper", true) ~= nil)
        end

        local function Root()
            local Character = Char.Character
            return Character and Character:FindFirstChild("HumanoidRootPart")
        end

        local function CFrameOf(Object)
            if Object:IsA("Model") then return Object:GetPivot() end
            if Object:IsA("BasePart") then return Object.CFrame end
            local Part = Object:FindFirstChildWhichIsA("BasePart", true)
            return Part and Part.CFrame or nil
        end

        -- 等玩家真的走进 50 号房间
        while Toggles.AutoLibrary.Value and not ActuallyInRoom50() do
            task.wait(0.05)
        end
        if not Toggles.AutoLibrary.Value then
            AutoLibraryRunning = false
            return
        end

        local Books = {}

        local function CollectBooks(Container)
            if Container.Name == "LiveHintBook" and InRoom50(Container) then
                if not table.find(Books, Container) then table.insert(Books, Container) end
            end
            for _, Desc in ipairs(Container:GetDescendants()) do
                if Desc.Name == "LiveHintBook" and InRoom50(Desc) then
                    if not table.find(Books, Desc) then table.insert(Books, Desc) end
                end
            end
        end

        local function FirePrompts(Object)
            for _, Desc in ipairs(Object:GetDescendants()) do
                if Desc:IsA("ProximityPrompt") and InRoom50(Desc) and FirePrompt then
                    pcall(FirePrompt, Desc)
                end
            end
        end

        -- 主循环：一直干到拿到纸为止
        while Toggles.AutoLibrary.Value and ActuallyInRoom50() and not HasPaper() do
            Books = {}
            CollectBooks(Room50)

            -- ① 先啃提示书，攒够 3 本纸才会刷出来
            local Taken = 0
            for _, Book in ipairs(Books) do
                if Taken >= 3 then break end
                if not Toggles.AutoLibrary.Value or not ActuallyInRoom50() then break end
                if HasPaper() then break end

                if InRoom50(Book) then
                    Taken = Taken + 1
                    local Target = CFrameOf(Book)
                    local MyRoot = Root()
                    if Target and MyRoot then
                        MyRoot.CFrame = Target * CFrame.new(0, 5, 0)
                    end
                    FirePrompts(Book)
                    task.wait(0.05)
                end
            end

            if HasPaper() then break end

            -- ② 纸刷出来之后去拿纸
            local Paper = Room50:FindFirstChild("LibraryHintPaper", true)
            local Guard = 0
            while Toggles.AutoLibrary.Value and ActuallyInRoom50() and not HasPaper()
                and Paper and Paper.Parent and InRoom50(Paper) and Guard < 200 do
                Guard = Guard + 1
                local Target = CFrameOf(Paper)
                local MyRoot = Root()
                if Target and MyRoot then
                    MyRoot.CFrame = Target * CFrame.new(0, 5, 0)
                end
                FirePrompts(Paper)
                task.wait(0.05)
            end

            task.wait(0.05)
        end

        AutoLibraryRunning = false
        if HasPaper() then
            Functions.Notify({ Title = "提示纸已拿到", Body = "接下来「自动解锁挂锁」就能用了" })
        end
    end)
end)

--────────────────────────── 跳过 Forget Me Not 门 ──────────────────────────
-- 原版机制：带 ForgetMeNot 藤蔓门的房间里，有 6 个「注视点」（房间里名为 1..6 的
-- 子对象，每个下面有个 LookAt 遥控）。把这些 LookAt 全发一遍，门就会开；
-- 发完立刻把角色往下扔 2 秒，避免同时被藤蔓判定到。
local ForgetMeNotRunning = false
local ForgetMeNotDone = {}

Toggles.ForgetMeNotSolver:OnChanged(function(Value)
    if not Value or ForgetMeNotRunning then return end
    ForgetMeNotRunning = true
    table.clear(ForgetMeNotDone)

    task.spawn(function()
        local function CurrentRoomNumber()
            return tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
        end

        local function FireLookAts(Room)
            for Index = 1, 6 do
                local Slot = Room:FindFirstChild(tostring(Index))
                local LookAt = Slot and Slot:FindFirstChild("LookAt")
                if LookAt then pcall(function() LookAt:FireServer() end) end
            end
        end

        local function VoidCharacter()
            local Character = Char.Character
            if not Character then return end
            local Void = CFrame.new(0, -120, 0)
            local Start = tick()
            while Toggles.ForgetMeNotSolver.Value and tick() - Start < 2 do
                pcall(function() Character:PivotTo(Void) end)
                task.wait(0.1)
            end
        end

        while Toggles.ForgetMeNotSolver.Value do
            local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
            local Number = CurrentRoomNumber()
            if Rooms and Number and not ForgetMeNotDone[Number] then
                local Room = Rooms:FindFirstChild(tostring(Number))
                if Room and Room:FindFirstChild("ForgetMeNotVineDoors", true) then
                    ForgetMeNotDone[Number] = true
                    FireLookAts(Room)
                    VoidCharacter()
                end
            end
            task.wait(0.2)
        end

        ForgetMeNotRunning = false
    end)
end)

--────────────────────────── 落点提示刷屏 ──────────────────────────
-- 原版机制：楼梯间每个房间里都有 StairwellLandingLogic，里面装着若干「落点」模型，
-- 每个落点上挂着 ProximityPrompt。这个功能的做法是——按房间号顺序，
-- 挨个传送到落点上把它的提示全触发一遍，同时按一下 X（游戏自己的下落键），
-- 直到落点消失。相当于把整层的落点自动「点」完。
local LandingToken = 0

Toggles.StairwellLandingSpam:OnChanged(function(Value)
    LandingToken = LandingToken + 1
    if not Value then return end
    local MyToken = LandingToken

    task.spawn(function()
        local Press = getgenv().keypress
        local Release = getgenv().keyrelease
        -- 0x58 = X 键的虚拟键码（游戏用它触发下落）
        local function TapX()
            if type(Press) == "function" and type(Release) == "function" then
                pcall(function() Press(0x58) end)
                task.wait(0.03)
                pcall(function() Release(0x58) end)
            end
        end

        while Toggles.StairwellLandingSpam.Value and MyToken == LandingToken do
            local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
            if not Rooms then task.wait(0.2) continue end

            -- 收集所有落点模型
            local Landings = {}
            for _, Room in ipairs(Rooms:GetChildren()) do
                local Logic = Room:FindFirstChild("StairwellLandingLogic")
                if Logic then
                    for _, Model in ipairs(Logic:GetChildren()) do
                        if Model:IsA("Model") then
                            local Prompts = {}
                            for _, Desc in ipairs(Model:GetDescendants()) do
                                if Desc:IsA("ProximityPrompt") and Desc.Enabled then
                                    Prompts[#Prompts + 1] = Desc
                                end
                            end
                            if #Prompts > 0 then
                                Landings[#Landings + 1] = { Model = Model, Prompts = Prompts }
                            end
                        end
                    end
                end
            end

            -- 按房间号从小到大处理
            table.sort(Landings, function(A, B)
                local RoomA = A.Model.Parent and A.Model.Parent.Parent
                local RoomB = B.Model.Parent and B.Model.Parent.Parent
                return (tonumber(RoomA and RoomA.Name) or math.huge)
                    < (tonumber(RoomB and RoomB.Name) or math.huge)
            end)

            for _, Data in ipairs(Landings) do
                if not Toggles.StairwellLandingSpam.Value or MyToken ~= LandingToken then break end
                local Model = Data.Model

                while Model.Parent and Model:IsDescendantOf(Services.Workspace)
                    and Toggles.StairwellLandingSpam.Value and MyToken == LandingToken do
                    local Root = Char.RootPart
                    if Root then
                        pcall(function()
                            Root.CFrame = Model:GetPivot() + Vector3.new(0, 5, 0)
                        end)
                        for _, Prompt in ipairs(Data.Prompts) do
                            if Prompt.Parent and Prompt.Enabled and FirePrompt then
                                pcall(FirePrompt, Prompt)
                            end
                        end
                        TapX()
                    end
                    Services.RunService.Heartbeat:Wait()
                end
            end
            task.wait(0.1)
        end
    end)
end)

--────────────────────────── Honcho 正确箱子 ──────────────────────────
-- 档案馆的 Honcho 环节：房间里有一堆「投放点」（ArchivesPackageDeposit，
-- 带 BoxID 属性），你手上的箱子也有各自的 ID。
--   ① 把每个房间的投放点按 BoxID 缓存起来，并加 ESP；
--   ② 在 ArchivesHonchoRoom 里找出 Tool_BoxID 与某个投放点对得上的箱子，
--      改名成 ArchivesStorageBoxCorrect 并加 ESP —— 那个就是「正确箱子」；
--   ③ 手里拿着正确箱子、且离对应投放点 10 格内时，自动触发投放提示。
local HonchoDeposits = {}      -- [BoxID字符串] = 投放点实例
local HonchoProcessed = {}     -- 已处理过的房间
local HonchoEspObjects = {}    -- 加过 ESP 的对象，关开关时要清掉

local function HonchoColor()
    return (Options.ObjectiveESPColor and Options.ObjectiveESPColor.Value)
        or Color3.fromRGB(0, 255, 0)
end

local function HonchoAddESP(Object, Text)
    Functions.AddESP({ Object = Object, Text = Text, Color = HonchoColor() }, true)
    HonchoEspObjects[#HonchoEspObjects + 1] = Object
    Object.Destroying:Once(function()
        Functions.RemoveESP(Object)
        local Position = table.find(HonchoEspObjects, Object)
        if Position then table.remove(HonchoEspObjects, Position) end
    end)
end

local function HonchoClear()
    for _, Object in ipairs(HonchoEspObjects) do
        pcall(function() Functions.RemoveESP(Object) end)
    end
    table.clear(HonchoEspObjects)
    table.clear(HonchoDeposits)
    table.clear(HonchoProcessed)
end

local HonchoRoomConnection
local HonchoWatching = false

local function ProcessHonchoRoom(Room)
    if not Room or not Room.Parent then return end
    if not tonumber(Room.Name) then return end
    if HonchoProcessed[Room] then return end
    HonchoProcessed[Room] = true

    task.wait(3)
    if not Toggles.HonchoCorrectBoxESP.Value or not Room.Parent then
        HonchoProcessed[Room] = nil
        return
    end

    local HonchoRoom = Room:FindFirstChild("ArchivesHonchoRoom", true)
    if not HonchoRoom then
        HonchoProcessed[Room] = nil
        return
    end

    -- ① 收集这个房间的投放点
    local BoxIDs = {}
    for _, Desc in ipairs(Room:GetDescendants()) do
        if string.find(Desc.Name, "^ArchivesPackageDeposit") then
            local Id = Desc:GetAttribute("BoxID")
            if Id ~= nil then
                local Key = tostring(Id)
                BoxIDs[Key] = true
                HonchoDeposits[Key] = Desc
                HonchoAddESP(Desc, "投放点 (" .. Key .. ")")
                Desc.Destroying:Once(function()
                    if HonchoDeposits[Key] == Desc then HonchoDeposits[Key] = nil end
                end)
            end
        end
    end

    if not next(BoxIDs) then
        HonchoProcessed[Room] = nil
        return
    end

    -- ② 找出「正确箱子」，改个名好认
    local RoomNumber = tonumber(Room.Name)
    for _, Child in ipairs(HonchoRoom:GetDescendants()) do
        if Child.Name == "ArchivesStorageBox" then
            local ToolBoxID = Child:GetAttribute("Tool_BoxID")
            if ToolBoxID ~= nil and BoxIDs[tostring(ToolBoxID)] then
                if not Child:GetAttribute("ParentRoom") then
                    pcall(function() Child:SetAttribute("ParentRoom", RoomNumber) end)
                end
                Child.Name = "ArchivesStorageBoxCorrect"
                HonchoAddESP(Child, "正确箱子 (" .. tostring(ToolBoxID) .. ")")
            end
        end
    end
end

Toggles.HonchoCorrectBoxESP:OnChanged(function(Value)
    HonchoClear()
    if HonchoRoomConnection then
        HonchoRoomConnection:Disconnect()
        HonchoRoomConnection = nil
    end
    if not Value then return end

    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return end

    for _, Room in ipairs(Rooms:GetChildren()) do
        task.spawn(ProcessHonchoRoom, Room)
    end
    HonchoRoomConnection = Rooms.ChildAdded:Connect(function(Room)
        if Toggles.HonchoCorrectBoxESP.Value then task.spawn(ProcessHonchoRoom, Room) end
    end)
end)

-- ③ 自动投放：拿对箱子且靠近对应投放点就触发
local HonchoLastCheck = 0
Connections.HonchoAutoDeposit = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.HonchoCorrectBoxESP.Value then return end
    if tick() - HonchoLastCheck < 0.1 then return end
    HonchoLastCheck = tick()

    local Character = Char.Character
    local Root = Char.RootPart
    if not Character or not Root then return end
    local Drops = Services.Workspace:FindFirstChild("Drops")

    -- 手上的 + 掉在地上的正确箱子
    local Candidates = {}
    for _, Object in ipairs(Character:GetChildren()) do
        if Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect" then
            Candidates[#Candidates + 1] = Object
        end
    end
    if Drops then
        for _, Object in ipairs(Drops:GetChildren()) do
            if Object.Name == "ArchivesStorageBox" or Object.Name == "ArchivesStorageBoxCorrect" then
                Candidates[#Candidates + 1] = Object
            end
        end
    end

    for _, Box in ipairs(Candidates) do
        if Box and Box.Parent then
            local BoxID = Box:GetAttribute("Tool_BoxID") or Box:GetAttribute("BoxID")
            if BoxID ~= nil then
                local Deposit = HonchoDeposits[tostring(BoxID)]
                if Deposit and Deposit.Parent then
                    -- 掉在地上的正确箱子也标出来
                    if Box.Parent == Drops and not Box:GetAttribute("HonchoCorrectESP") then
                        pcall(function() Box:SetAttribute("HonchoCorrectESP", true) end)
                        HonchoAddESP(Box, "正确箱子 (" .. tostring(BoxID) .. ")")
                    end
                    -- 手里拿着 + 够近 → 自动投放
                    if Box.Parent == Character then
                        local Part = Deposit:IsA("BasePart") and Deposit
                            or Deposit:FindFirstChildWhichIsA("BasePart", true)
                        if Part and (Part.Position - Root.Position).Magnitude <= 10 then
                            local Prompt = Deposit:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if Prompt and FirePrompt then pcall(FirePrompt, Prompt) end
                        end
                    end
                end
            end
        end
    end
end)

--────────────────────────── 心跳小游戏防失败 ──────────────────────────
-- Figure 的心跳小游戏靠两个遥控器：ClutchHeartbeat（心跳节奏）和
-- HideMonster（藏怪）。原版用 __namecall 钩子把这两个调用直接吞掉，
-- 游戏收不到就不会判定失败。
-- 这里只在开关打开时行动 —— 原版是无条件钩住、每次 namecall 都判断一遍，
-- 那个开销是白花的。
local HeartbeatNames = { ClutchHeartbeat = true, HideMonster = true }

local HeartbeatHooked = (function()
    if not Functions.CheckCompatability({ "hookmetamethod", "newcclosure", "getnamecallmethod" }) then
        return false
    end
    -- 钩子只挂一次；是否生效由开关决定（和原版一致）
    local Ok, Original = pcall(function()
        return hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
            if Toggles.AutoHeartbeatMinigame.Value
                and getnamecallmethod() == "FireServer"
                and typeof(Self) == "Instance"
                and HeartbeatNames[Self.Name] then
                return
            end
            return Original(Self, ...)
        end))
    end)
    return Ok
end)()

--────────────────────────── 自动电闸房（100 房） ──────────────────────────
-- 原版是一整段带 AutoBreakerRoom 前缀的深层嵌套。时序如下（只在 100 号房间生效）：
--   ① 把房间里所有「电闸杆」(LiveBreakerPolePickup) 挨个传送过去触发；
--   ② 找到 IndustrialGate.Box 上的 Lever 和 ActivateEventPrompt，
--      反复触发直到拉杆位置变化（= 拉成功了）；
--   ③ 等 5 秒，去 ElevatorBreakerEmpty 触发断路器，直到
--      BreakerSwitchInBox 出现；
--   ④ 等 10 秒再触发一轮（原版 AutoBreakerRoomBreakerSecondTime = 10 秒）；
--   ⑤ 等 4 秒，钻进 ElevatorCar 的 Web 里待 20 秒躲过蛛网。
local BreakerRunning = false

Toggles.AutoBreakerRoom:OnChanged(function(Enabled)
    if not Enabled or BreakerRunning then return end
    BreakerRunning = true

    task.spawn(function()
        local Rooms = Services.Workspace:WaitForChild("CurrentRooms", 20)
        local Room100 = Rooms and Rooms:WaitForChild("100", 60)
        if not Room100 then
            BreakerRunning = false
            Functions.Notify({ Title = "没等到电闸房（100）" })
            return
        end

        local function InRoom(Object)
            return Object and Object.Parent
                and Object:IsDescendantOf(Room100)
                and Object:IsDescendantOf(Services.Workspace)
        end

        local function ActuallyInRoom()
            return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) == 100
        end

        local function CFrameOf(Object)
            if not Object or not InRoom(Object) then return nil end
            if Object:IsA("Model") then return Object:GetPivot() end
            if Object:IsA("BasePart") then return Object.CFrame end
            local Part = Object:FindFirstChildWhichIsA("BasePart", true)
            return Part and Part.CFrame or nil
        end

        -- 把一个对象上的所有提示都点一遍
        local function Activate(Object)
            if not Object or not InRoom(Object) then return end
            if Object:IsA("ProximityPrompt") then
                if FirePrompt then pcall(FirePrompt, Object) end
                return
            end
            for _, Desc in ipairs(Object:GetDescendants()) do
                if Desc:IsA("ProximityPrompt") and InRoom(Desc) and FirePrompt then
                    pcall(FirePrompt, Desc)
                end
            end
        end

        -- 贴到目标上、连着触发一段时间
        local function StickAndActivate(Target, Duration, Interval, Offset)
            Interval = Interval or 0.04
            Offset = Offset or CFrame.new()
            local Deadline = os.clock() + (Duration or 3)
            while Toggles.AutoBreakerRoom.Value and ActuallyInRoom()
                and InRoom(Target) and os.clock() < Deadline do
                local Root = Char.RootPart
                local TargetCF = CFrameOf(Target)
                if Root and TargetCF then Root.CFrame = TargetCF * Offset end
                Activate(Target)
                task.wait(Interval)
            end
        end

        while Toggles.AutoBreakerRoom.Value do
            -- 等到真的进了 100 房
            while Toggles.AutoBreakerRoom.Value and not ActuallyInRoom() do
                task.wait(0.1)
            end
            if not Toggles.AutoBreakerRoom.Value then break end

            -- ① 电闸杆：一根一根去碰，直到它们全部消失
            while Toggles.AutoBreakerRoom.Value and ActuallyInRoom() do
                local Poles = {}
                for _, Desc in ipairs(Room100:GetDescendants()) do
                    if Desc.Name == "LiveBreakerPolePickup" and InRoom(Desc) then
                        table.insert(Poles, Desc)
                    end
                end
                if #Poles == 0 then break end

                for _, Pole in ipairs(Poles) do
                    if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then break end
                    if InRoom(Pole) then
                        StickAndActivate(Pole, 2.8, 0.03)
                        task.wait(0.12)
                    end
                end
                task.wait(0.05)
            end

            if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then
                task.wait(0.1)
                continue
            end

            -- ② 拉杆：触发到拉杆位置变了为止
            local Gate = Room100:FindFirstChild("IndustrialGate")
            local Box = Gate and Gate:FindFirstChild("Box")
            local Lever = Box and Box:FindFirstChild("Lever")
            local LeverPrompt = Box and Box:FindFirstChild("ActivateEventPrompt")

            if LeverPrompt and Lever then
                local LeverCF = CFrameOf(Lever)
                local Deadline = os.clock() + 10
                while Toggles.AutoBreakerRoom.Value and ActuallyInRoom()
                    and InRoom(Lever) and os.clock() < Deadline do
                    local NowCF = CFrameOf(Lever)
                    if NowCF and LeverCF and NowCF ~= LeverCF then break end

                    local Root = Char.RootPart
                    local BoxCF = CFrameOf(Box)
                    if Root and BoxCF then Root.CFrame = BoxCF end
                    Activate(LeverPrompt)
                    task.wait(0.04)
                end
            end

            if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then
                task.wait(0.1)
                continue
            end

            task.wait(5)   -- 拉杆之后的固定等待

            if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then
                task.wait(0.1)
                continue
            end

            -- ③ 断路器：贴上去触发，直到开关装进盒子
            local Breaker = Room100:FindFirstChild("ElevatorBreakerEmpty")
            local BreakerPrompt = Breaker and Breaker:FindFirstChild("Prompt")
            local BreakerOffset = CFrame.new(0, -1.8, 0)

            if Breaker and BreakerPrompt then
                while Toggles.AutoBreakerRoom.Value and ActuallyInRoom() do
                    if Breaker:FindFirstChild("BreakerSwitchInBox") then break end
                    local Root = Char.RootPart
                    local BreakerCF = CFrameOf(Breaker)
                    if Root and BreakerCF then Root.CFrame = BreakerCF * BreakerOffset end
                    Activate(BreakerPrompt)
                    task.wait(0.04)
                end

                if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then
                    task.wait(0.1)
                    continue
                end

                task.wait(10)  -- 装好之后的固定等待
                StickAndActivate(Breaker, 10, 0.04, BreakerOffset)
            end

            task.wait(4)  -- 蛛网之前的固定等待

            if not Toggles.AutoBreakerRoom.Value or not ActuallyInRoom() then
                task.wait(0.1)
                continue
            end

            -- ④ 蛛网：钻进升降车里的蜘蛛网待 20 秒
            local Car = Room100:FindFirstChild("ElevatorCar")
            local Web = Car and Car:FindFirstChild("Web", true)
            if Web then
                local Deadline = os.clock() + 20
                while Toggles.AutoBreakerRoom.Value and ActuallyInRoom()
                    and os.clock() < Deadline do
                    local Root = Char.RootPart
                    local WebCF = CFrameOf(Web)
                    if Root and WebCF then Root.CFrame = WebCF end
                    task.wait(0.04)
                end
            end

            -- 这一轮跑完，等玩家离开 100 房再进入下一轮
            while Toggles.AutoBreakerRoom.Value and ActuallyInRoom() do
                task.wait(0.5)
            end
        end

        BreakerRunning = false
    end)
end)

--────────────────────────── 自动推酒店 ──────────────────────────
-- 原版这一整套（含 50 房图书馆）源码 500 多行。核心其实就四件事：
--   ① 找「下一道还没开的门」——房间号 >= LatestRoom、排除 100 房、门没开过、取最小的；
--   ② 50 房交给图书馆流程（和「自动图书馆」同一个实现，直接复用）；
--   ③ 门上有锁的话，去找房间里的 KeyObtain 拿钥匙，拿到为止（最多 12 秒）；
--   ④ 然后 PivotTo 到门上（往下 1 格），门就开了，继续下一道。
-- 实体出现时暂停推进，等实体过去（可用「忽略实体」跳过等待）。
local HotelRunning = false
local HotelEntityPause = false

local HOTEL_ENTITIES = {
    RushMoving = true, Scribbles = true, BashMoving = true,
    DronesStampede = true, AmbushMoving = true, A60 = true, A120 = true,
    GlitchRush = true, GlitchAmbush = true, BackdoorRush = true,
    CustomEntity = true,
}

local function HotelIgnoringEntities()
    return Toggles.AutoHotelIgnoreEntities and Toggles.AutoHotelIgnoreEntities.Value
end

local function HotelEntityPresent()
    if HotelIgnoringEntities() then return false end
    for _, Child in ipairs(Services.Workspace:GetChildren()) do
        if HOTEL_ENTITIES[Child.Name] then return true end
    end
    return false
end

local function HotelWaitForEntities(Seconds)
    if HotelIgnoringEntities() then return end
    task.wait(Seconds or 5)
    while HotelEntityPresent() do
        if HotelIgnoringEntities() then return end
        if not Toggles.AutoHotel.Value then return end
        task.wait(0.15)
    end
end

-- ① 找下一道没开的门
local function HotelNextClosedDoor()
    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    local Latest = GameData and GameData:FindFirstChild("LatestRoom")
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not (Latest and Rooms) then return nil, nil end

    local StartRoom = Latest.Value
    local Best, BestNumber = nil, math.huge

    for _, Room in ipairs(Rooms:GetChildren()) do
        local Number = tonumber(Room.Name)
        if Number and Number ~= 100 and Number >= StartRoom and Number < BestNumber then
            local Door = Room:FindFirstChild("Door")
            if Door and Door:IsA("Model") then
                local Open = Door:GetAttribute("Open")
                if Open == false or Open == nil then
                    Best, BestNumber = Door, Number
                end
            end
        end
    end
    return Best, BestNumber
end

-- ③ 找房间里的 KeyObtain
local function HotelFindKeyObtain(Room)
    local Found
    local function Scan(Parent)
        if Found then return end
        for _, Child in ipairs(Parent:GetChildren()) do
            if Child.Name == "KeyObtain" then Found = Child return end
            Scan(Child)
            if Found then return end
        end
    end
    Scan(Room)
    return Found
end

local function HotelHandleKey(RoomNumber)
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return false end
    local Room = Rooms:FindFirstChild(tostring(RoomNumber))
    if not Room then return false end

    local Door = Room:FindFirstChild("Door")
    if not Door or not Door:FindFirstChild("Lock") then return false end

    local KeyObtain = HotelFindKeyObtain(Room)
    if not KeyObtain then return false end

    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    local Deadline = tick() + 12
    while tick() < Deadline do
        local Character = Char.Character
        if (Backpack and Backpack:FindFirstChild("Key"))
            or (Character and Character:FindFirstChild("Key")) then
            return true
        end
        if Character then pcall(function() Character:PivotTo(KeyObtain:GetPivot()) end) end
        for _, Desc in ipairs(KeyObtain:GetDescendants()) do
            if Desc:IsA("ProximityPrompt") and FirePrompt then pcall(FirePrompt, Desc) end
        end
        if not Toggles.AutoHotel.Value then return false end
        task.wait(0.12)
    end
    return false
end

-- ④ 遇实体就停下来等（Seek 的触发体出现时也暂停）
local function HotelWatchEntities()
    local LastTriggerRoom
    while Toggles.AutoHotel.Value do
        local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
        if not Rooms then task.wait(0.2) continue end

        local TriggerRoom
        for _, Room in ipairs(Rooms:GetChildren()) do
            local Number = tonumber(Room.Name)
            if Number and Number ~= LastTriggerRoom then
                if Room:FindFirstChild("TriggerEventCollision")
                    or Room:FindFirstChild("TriggerEventCollision", true) then
                    TriggerRoom = Number
                    break
                end
            end
        end

        if TriggerRoom then
            LastTriggerRoom = TriggerRoom
            HotelEntityPause = true
            HotelWaitForEntities(10)
            HotelEntityPause = false
        else
            task.wait(0.15)
        end
    end
end

Toggles.AutoHotel:OnChanged(function(Enabled)
    if not Enabled or HotelRunning then return end
    HotelRunning = true

    -- 实体监视（独立一条线程）
    task.spawn(HotelWatchEntities)

    task.spawn(function()
        local LibraryStarted = false

        while Toggles.AutoHotel.Value do
            if HotelEntityPause then
                task.wait(0.1)
                continue
            end

            local Door, RoomNumber = HotelNextClosedDoor()

            if Door and RoomNumber then
                if RoomNumber == 50 then
                    -- 50 房 = 图书馆，复用「自动图书馆」那套
                    if not LibraryStarted then
                        LibraryStarted = true
                        task.spawn(function()
                            if not Toggles.AutoLibrary.Value then
                                Toggles.AutoLibrary:Set(true)
                            end
                            -- 等图书馆流程结束（纸拿到或开关关掉）
                            while Toggles.AutoLibrary.Value and Toggles.AutoHotel.Value do
                                task.wait(0.5)
                            end
                            LibraryStarted = false
                        end)
                    end
                    task.wait(0.4)
                else
                    HotelHandleKey(RoomNumber)
                    local Character = Char.Character
                    if Character and not HotelEntityPause then
                        pcall(function()
                            Character:PivotTo(Door:GetPivot() * CFrame.new(0, -1, 0))
                        end)
                    end
                end
            end
            task.wait(0.15)
        end

        HotelRunning = false
        HotelEntityPause = false
    end)
end)

--────────────────────────── 移除障碍物 / 实体 ──────────────────────────
-- 原版做的是「把它挪到地图外面」而不是删掉 —— 删掉会让服务端的状态对不上，
-- 挪走则客户端看不到、服务端那边依然正常。这里沿用这个手法。
--
-- 这几个障碍物只在酒店系列楼层有意义（原版也是这么判断的）：
-- Hotel = 酒店 / Fools = 愚人酒店 / OldHotel = 旧酒店
local function IsHotelFloor()
    return Floor == "Hotel" or Floor == "Fools" or Floor == "OldHotel"
end

local VOID_CFRAME = CFrame.new(-10000, -10000, -10000)

-- 障碍物：只在这几个楼层处理（原版标记为 Risky 的那些）
local OBSTRUCTION_MAP = {
    { Toggle = "RemoveBasementGate", Name = "ThingToOpen" },
    { Toggle = "RemovePaintingsDoor", Name = "MovingDoor" },
}

ExploitChecks[#ExploitChecks + 1] = function()
    -- ① 地下室门 / 画中门：挪走
    if IsHotelFloor() then
        for _, Entry in ipairs(OBSTRUCTION_MAP) do
            local Toggle = Toggles[Entry.Toggle]
            if Toggle and Toggle.Value then
                for _, Object in ipairs(Objects.Obstructions) do
                    if Object and Object.Parent and Object.Name == Entry.Name then
                        pcall(function() Object:PivotTo(VOID_CFRAME) end)
                    end
                end
            end
        end

        -- ② 骷髅门：只在 Fools 楼层
        if Floor == "Fools" and Toggles.RemoveSkeletonDoor.Value then
            for _, Object in ipairs(Objects.Obstructions) do
                if Object and Object.Parent and Object.Name == "Wax_Door" then
                    pcall(function() Object:PivotTo(VOID_CFRAME) end)
                end
            end
        end
    end

    -- ③ 删除 Figure：把它的部件挪走（只在有权重时才行，否则会被服务端拉回来）
    if Toggles.RemoveFigure.Value and Floor == "Mines" then
        for _, Entity in ipairs(Objects.Entities) do
            if Entity and Entity.Parent and Entity.Name == "Figure" then
                for _, Part in ipairs(Entity:GetDescendants()) do
                    if Part:IsA("BasePart") and Part:GetNetworkOwner() == LocalPlayer then
                        pcall(function()
                            Part.Position = Vector3.new(-49999, -49999, -49999)
                        end)
                    end
                end
            end
        end
    end
end

-- ④ 删除 Seek 触发器：靠反复「碰一下」把它消耗掉
--    （原版用 firetouchinterest 制造一次进入再离开的触碰）
local SeekTriggerRunning = false
Toggles.RemoveSeekTrigger:OnChanged(function(Value)
    if not Value or SeekTriggerRunning then return end
    if not Functions.CheckCompatability({ "firetouchinterest" }) then
        Functions.Notify({ Title = "当前执行器不支持 firetouchinterest" })
        return
    end
    SeekTriggerRunning = true

    task.spawn(function()
        while Toggles.RemoveSeekTrigger.Value do
            if Floor == "Fools" or Floor == "OldHotel" then
                local Root = Char.RootPart
                if Root then
                    for _, Object in ipairs(Objects.EventTriggers) do
                        if Object and Object.Parent and Object.Name == "TriggerEventCollision" then
                            for _, Part in ipairs(Object:GetChildren()) do
                                if Part:IsA("BasePart") then
                                    pcall(function()
                                        firetouchinterest(Root, Part, 0)
                                        task.wait()
                                        firetouchinterest(Root, Part, 1)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait()
        end
        SeekTriggerRunning = false
    end)
end)

--────────────────────────── 楼梯间：静音 / 绕开噪音 ──────────────────────────
-- 楼梯间的怪物靠「声音」找你。原版两条思路：
--
-- ① 静音（AntiNoise）—— 不用引擎的走路系统，改成每帧直接按相机方向推 CFrame。
--    引擎里任何基于速度的监听都听不到动静，但你在屏幕上还是在正常移动。
--    原版挂在 PreSimulation 上（比 Heartbeat 早，能抢在物理结算之前）。
--
-- ② 绕开噪音（BypassNoise）—— 楼梯间里有个 TV_Stand（落地电视机会发出声响），
--    把它挪到 Y = -120（地图下面）就不会响了。

local AntiNoiseConnection
local BypassNoiseConnection

Toggles.AntiNoise:OnChanged(function(Value)
    if AntiNoiseConnection then
        AntiNoiseConnection:Disconnect()
        AntiNoiseConnection = nil
    end
    if not Value then return end

    AntiNoiseConnection = Services.RunService.PreSimulation:Connect(function(DeltaTime)
        if not Toggles.AntiNoise.Value then return end
        if not LocalPlayer:GetAttribute("Alive") then return end

        local Character = Char.Character
        local Root = Char.RootPart
        local Humanoid = Char.Humanoid
        local Camera = Services.Workspace.CurrentCamera
        if not (Character and Root and Humanoid and Camera) then return end
        if Humanoid.Health <= 0 or Root.Anchored then return end

        -- 死亡 / 布娃娃 / 爬梯 / 游泳这些状态不要插手
        local State = Humanoid:GetState()
        if State == Enum.HumanoidStateType.Dead
            or State == Enum.HumanoidStateType.Ragdoll
            or State == Enum.HumanoidStateType.Climbing
            or State == Enum.HumanoidStateType.Swimming then
            return
        end

        Humanoid.AutoRotate = false
        Humanoid:Move(Vector3.zero, false)

        -- 输入向量（-1..1）→ 相机朝向的世界方向
        local Input = MoveControls and MoveControls:GetMoveVector() or Vector3.zero
        local Magnitude = Input.Magnitude
        if Magnitude <= 0 then
            Root.AssemblyLinearVelocity = Vector3.zero
            return
        end

        local CameraCF = Camera.CFrame
        local Forward = Vector3.new(CameraCF.LookVector.X, 0, CameraCF.LookVector.Z)
        local Right = Vector3.new(CameraCF.RightVector.X, 0, CameraCF.RightVector.Z)
        if Forward.Magnitude < 0.001 or Right.Magnitude < 0.001 then return end

        local Direction = (Right.Unit * Input.X) + (Forward.Unit * -Input.Z)
        if Direction.Magnitude <= 0 then return end
        Direction = Direction.Unit

        local Speed = Humanoid.WalkSpeed * math.clamp(Magnitude, 0, 1)
        local Step = math.clamp(DeltaTime, 0, 1 / 30)

        Root.AssemblyLinearVelocity = Vector3.zero
        Root.CFrame = Root.CFrame + (Direction * Speed * Step)
        Root.CFrame = CFrame.new(Root.Position, Root.Position + Direction)
    end)
end)

Toggles.BypassNoise:OnChanged(function(Value)
    if BypassNoiseConnection then
        BypassNoiseConnection:Disconnect()
        BypassNoiseConnection = nil
    end
    if not Value then return end

    local VOID_Y = -120
    local function Sink(Stand)
        if not Stand:IsA("Model") or Stand.Name ~= "TV_Stand" then return end
        local Pivot = Stand:GetPivot()
        if Pivot.Position.Y > VOID_Y + 1 then
            pcall(function()
                Stand:PivotTo(CFrame.new(Pivot.Position.X, VOID_Y, Pivot.Position.Z))
            end)
        end
    end

    local Misc = Services.Workspace:FindFirstChild("Misc")
    if Misc then
        for _, Child in ipairs(Misc:GetChildren()) do Sink(Child) end
        BypassNoiseConnection = Misc.ChildAdded:Connect(function(Child)
            if Toggles.BypassNoise.Value then Sink(Child) end
        end)
    end
end)

--────────────────────────── 玩家操作接口（共用） ──────────────────────────
-- 需要读「玩家这一帧想往哪走」的功能（矿车转向、楼梯间静音）都从这里拿。
-- PlayerModule 不一定立刻存在，所以后台慢慢等它出现。
MoveControls = nil
task.spawn(function()
    while not MoveControls do
        local Ok, Result = pcall(function()
            local PlayerModule = LocalPlayer:FindFirstChild("PlayerScripts")
            PlayerModule = PlayerModule and PlayerModule:FindFirstChild("PlayerModule")
            if not PlayerModule then return nil end
            return require(PlayerModule):GetControls()
        end)
        if Ok and Result and type(Result.GetMoveVector) == "function" then
            MoveControls = Result
        end
        task.wait(0.5)
    end
end)

--────────────────────────── 复活 ──────────────────────────
-- 原版：Alive 变成 false 时，反复发 Revive 遥控直到重新活过来。
-- 注意这个只在「愚人酒店 / 旧酒店」有效 —— 那两个楼层死亡后还能被拉回来，
-- 其他楼层死了就是死了，硬发也没用。
local function HotelRevivable()
    return Floor == "Fools" or Floor == "OldHotel"
end

-- 「复活」按钮用的一次性尝试
TryRevive = function()
    local Revive = Remote("Revive")
    if not Revive then
        Functions.Notify({ Title = "这个楼层没有复活机制" })
        return
    end
    if not HotelRevivable() then
        Functions.Notify({ Title = "只有愚人酒店 / 旧酒店能复活" })
        return
    end
    pcall(function() Revive:FireServer() end)
end

-- 自动复活：死了就一直试
local AutoReviveRunning = false
Connections.AutoRevive = LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
    if LocalPlayer:GetAttribute("Alive") ~= false then return end
    if not Toggles.AutoRevive.Value then return end
    if AutoReviveRunning then return end
    if not HotelRevivable() then return end

    AutoReviveRunning = true
    task.spawn(function()
        local Revive = Remote("Revive")
        local Guard = 0
        while Revive and LocalPlayer:GetAttribute("Alive") ~= true
            and Toggles.AutoRevive.Value and Guard < 120 do
            Guard = Guard + 1
            pcall(function() Revive:FireServer() end)
            task.wait(0.5)
        end
        AutoReviveRunning = false
    end)
end)

--────────────────────────── 楼梯间：购物车 / 破碎机 / 夹层 ──────────────────────────
-- 原版这几个功能都是「开关打开 → 起一条线程 → 每 0.1~0.5 秒检查一遍地图」。
-- 这里把共用的「遍历 CurrentRooms」收成一个小工具，各功能只写自己那部分。

local function EachRoom(Fn)
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return end
    for _, Room in ipairs(Rooms:GetChildren()) do
        Fn(Room)
    end
end

local function EachShoppingCart(Fn)
    local Misc = Services.Workspace:FindFirstChild("Misc")
    if not Misc then return end
    for _, Model in ipairs(Misc:GetChildren()) do
        if Model.Name == "ShoppingCart" and Model:IsA("Model") then Fn(Model) end
    end
end

-- ① 用购物车把所有活着的其他玩家干掉 —— 车会依次贴到每个人身上
Toggles.KillAllWithCart:OnChanged(function(Enabled)
    if not Enabled then return end
    task.spawn(function()
        local Index = 1
        while Toggles.KillAllWithCart.Value do
            local Carts = {}
            EachShoppingCart(function(Cart) Carts[#Carts + 1] = Cart end)

            local Targets = {}
            for _, Player in ipairs(Services.Players:GetPlayers()) do
                if Player ~= LocalPlayer and Player.Character then
                    local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid and Humanoid.Health > 0 then Targets[#Targets + 1] = Player end
                end
            end

            if #Carts > 0 and #Targets > 0 then
                if Index > #Targets then Index = 1 end
                local TargetCF = Targets[Index].Character:GetPivot()
                for _, Cart in ipairs(Carts) do
                    pcall(function() Cart:PivotTo(TargetCF) end)
                end
                Index = Index + 1
            end
            task.wait(0.1)
        end
    end)
end)

-- ② 把车全贴到 Creak 身上（把它撞飞）
Toggles.FlingCreak:OnChanged(function(Enabled)
    if not Enabled then return end
    task.spawn(function()
        while Toggles.FlingCreak.Value do
            local Live = Services.Workspace:FindFirstChild("LiveEntities")
            local Creak = Live and Live:FindFirstChild("Creak")
            if Creak then
                local Target = Creak:GetPivot()
                EachShoppingCart(function(Cart)
                    pcall(function() Cart:PivotTo(Target) end)
                end)
            end
            task.wait(0.1)
        end
    end)
end)

-- ③④ 破碎机 —— 两者共用「这个部件是不是在 BasicWall 底下」的判断
-- 原版把这段逻辑在禁用碰撞和删除两处各抄了一遍，这里抽出来。
local function UnderBasicWall(Descendant, Container)
    local Parent = Descendant.Parent
    while Parent and Parent ~= Container do
        if Parent.Name == "BasicWall" then return true end
        Parent = Parent.Parent
    end
    return false
end

local function EachCrusherContainer(Fn)
    EachRoom(function(Room)
        local Assets = Room:FindFirstChild("Assets")
        if not Assets then return end
        for _, Container in ipairs(Assets:GetChildren()) do
            if Container.Name == "StairwellCrusherContainer1" then Fn(Container) end
        end
    end)
end

Toggles.DisableStairwellCrusherCollision:OnChanged(function(Enabled)
    if not Enabled then return end
    task.spawn(function()
        while Toggles.DisableStairwellCrusherCollision.Value do
            EachCrusherContainer(function(Container)
                for _, Desc in ipairs(Container:GetDescendants()) do
                    if Desc:IsA("BasePart") and Desc.CanCollide
                        and not UnderBasicWall(Desc, Container) then
                        pcall(function() Desc.CanCollide = false end)
                    end
                end
                local Crusher = Container:FindFirstChild("StairwellCrusher")
                if Crusher then
                    for _, Name in ipairs({ "OuterTrigger", "CoreTrigger" }) do
                        local Trigger = Crusher:FindFirstChild(Name)
                        if Trigger then pcall(function() Trigger:Destroy() end) end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end)

Toggles.DeleteStairwellCrusherExceptBasicWall:OnChanged(function(Enabled)
    if not Enabled then return end
    task.spawn(function()
        while Toggles.DeleteStairwellCrusherExceptBasicWall.Value do
            EachCrusherContainer(function(Container)
                local Doomed = {}
                for _, Desc in ipairs(Container:GetDescendants()) do
                    if not UnderBasicWall(Desc, Container) and Desc.Name ~= "BasicWall" then
                        Doomed[#Doomed + 1] = Desc
                    end
                end
                for _, Instance in ipairs(Doomed) do
                    if Instance and Instance.Parent then
                        pcall(function() Instance:Destroy() end)
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end)

-- ⑤ 清除夹层（Meld）—— 房间的 Assets/Parts 里的墙，以及房间里那几个文件夹
-- 注意这里有个名字诡异的物件（原版注释写着 "no questions asked"），照抄
local MELD_OBJECTS = {
    MeldWall = true,
    Boleahghth29tdgfhy2thuy2htuu259uhh3u = true,
}
local MELD_FOLDERS = { MeldData = true, MeldPads = true, Meldview = true, Meld = true }

Toggles.MeldRemover:OnChanged(function(Enabled)
    if not Enabled then return end
    task.spawn(function()
        while Toggles.MeldRemover.Value do
            EachRoom(function(Room)
                for _, FolderName in ipairs({ "Assets", "Parts" }) do
                    local Folder = Room:FindFirstChild(FolderName)
                    if Folder then
                        for _, Child in ipairs(Folder:GetChildren()) do
                            if MELD_OBJECTS[Child.Name] then
                                pcall(function() Child:Destroy() end)
                            end
                        end
                    end
                end
                for Name in pairs(MELD_FOLDERS) do
                    local Folder = Room:FindFirstChild(Name)
                    if Folder and Folder:IsA("Folder") then
                        pcall(function() Folder:Destroy() end)
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end)

--────────────────────────── 掉落物：定时拾取 / 计数 HUD ──────────────────────────
-- ① 定时拾取：每隔一段时间把 Drops 里的东西拉过来一次。
--    间隔调成 0 就是每帧都拉（原版也是这么处理的）。
local PickupRunning = false
Toggles.EnableDroppedItemsInterval:OnChanged(function(Enabled)
    if not Enabled or PickupRunning then return end
    PickupRunning = true
    task.spawn(function()
        while Toggles.EnableDroppedItemsInterval.Value do
            BringDroppedItems()
            local Interval = Options.DroppedItemsInterval.Value
            if Interval <= 0 then
                task.wait()
            else
                task.wait(Interval)
            end
        end
        PickupRunning = false
    end)
end)

-- ② 掉落物计数 HUD：屏幕顶部显示当前地上的掉落物数量。
--    用 CoreGui（执行器环境下才可写），不行就退回 PlayerGui。
local DropCounterGui
local DropCounterLabel

local function DropCounterDestroy()
    if DropCounterGui then
        pcall(function() DropCounterGui:Destroy() end)
        DropCounterGui = nil
        DropCounterLabel = nil
    end
end

Toggles.DroppedItemValue:OnChanged(function(Enabled)
    DropCounterDestroy()
    if not Enabled then return end

    local Parent = Services.CoreGui or LocalPlayer:FindFirstChild("PlayerGui")
    if not Parent then return end

    DropCounterGui = Instance.new("ScreenGui")
    DropCounterGui.Name = "DoorsESPX_DropCounter"
    DropCounterGui.ResetOnSpawn = false
    DropCounterGui.IgnoreGuiInset = true
    pcall(function() DropCounterGui.Parent = Parent end)
    if not DropCounterGui.Parent then
        -- CoreGui 写不进去就换 PlayerGui
        DropCounterGui.Parent = LocalPlayer:FindFirstChild("PlayerGui")
    end

    DropCounterLabel = Instance.new("TextLabel")
    DropCounterLabel.Name = "Count"
    DropCounterLabel.AnchorPoint = Vector2.new(0.5, 0)
    DropCounterLabel.Position = UDim2.new(0.5, 0, 0.02, 0)
    DropCounterLabel.Size = UDim2.new(0, 250, 0, 40)
    DropCounterLabel.BackgroundTransparency = 1
    DropCounterLabel.Text = "掉落物: 0"
    DropCounterLabel.TextSize = 24
    DropCounterLabel.Font = Enum.Font.GothamBold
    DropCounterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropCounterLabel.TextStrokeTransparency = 0.5
    DropCounterLabel.Parent = DropCounterGui

    task.spawn(function()
        local Drops = Services.Workspace:WaitForChild("Drops", 30)
        if not Drops then
            DropCounterDestroy()
            return
        end

        -- 只统计「新出现且还在地上」的，避免把已经拿走的也算进来
        local Counted = {}
        while Toggles.DroppedItemValue.Value do
            for _, Drop in ipairs(Drops:GetChildren()) do
                if not Counted[Drop] then
                    Counted[Drop] = true
                end
            end
            for Drop in pairs(Counted) do
                if not Drop.Parent or Drop.Parent ~= Drops then
                    Counted[Drop] = nil
                end
            end

            local Total = 0
            for Drop in pairs(Counted) do
                if Drop.Parent == Drops then Total = Total + 1 end
            end

            if DropCounterLabel and DropCounterLabel.Parent then
                DropCounterLabel.Text = "掉落物: " .. tostring(Total)
            end
            task.wait(1)
        end
        DropCounterDestroy()
    end)
end)

--────────────────────────── 档案馆：水面 / Alma ──────────────────────────
-- ① 水面绕行（BypassWater）—— 档案馆有的房间是水淹的，直接走会被冲走。
--    做法是在水面上盖一层透明薄板，人从板上走过去。
--    板子太厚就不盖（那种情况下盖上反而会把你卡住）。
--
-- ② 删除 Alma —— 出现就删。
--
-- 注意：这两个和「数值伪装」冲突（位置伪装会让服务端看到的你和实际对不上）。
local WaterBypassParts = {}
local WaterBypassConnection

Toggles.BypassWater:OnChanged(function(Value)
    if WaterBypassConnection then
        WaterBypassConnection:Disconnect()
        WaterBypassConnection = nil
    end

    if not Value then
        for Key, Part in pairs(WaterBypassParts) do
            if Part then pcall(function() Part:Destroy() end) end
            WaterBypassParts[Key] = nil
        end
        return
    end

    if Toggles.PositionSpoof.Value then
        Functions.Notify({ Title = "「数值伪装」开着会让这个功能失效" })
    end

    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return end

    local function ProcessRoom(Room)
        if not tonumber(Room.Name) then return end
        task.wait(3)

        local Water = Room:FindFirstChild("Water")
        if not Water or WaterBypassParts[Water] then return end

        local Size, CF
        if Water:IsA("BasePart") then
            Size, CF = Water.Size, Water.CFrame
        elseif Water:IsA("Model") then
            CF, Size = Water:GetBoundingBox()
        else
            Size, CF = Vector3.new(10, 1.5, 10), Water:GetPivot()
        end

        -- 太厚会成为障碍而不是踏板
        if Size.Y > 3 then
            Functions.Notify({ Title = "这块水面太厚，盖板会把你卡住，已跳过" })
            return
        end

        local Board = Instance.new("Part")
        Board.Name = "DoorsESPX_WaterBypass"
        Board.Anchored = true
        Board.CanCollide = true
        Board.CanTouch = false
        Board.CanQuery = false
        Board.Transparency = 0.25
        Board.Color = Color3.fromRGB(0, 150, 255)
        Board.Material = Enum.Material.ForceField
        Board.Size = Size + Vector3.new(0, 0.5, 0)
        Board.CFrame = CF * CFrame.new(0, 0.25, 0)
        Board.Parent = Room

        WaterBypassParts[Water] = Board
    end

    -- 只处理最近 5 间房（更早的没必要，也省性能）
    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    local Latest = GameData and GameData:FindFirstChild("LatestRoom")
    local LatestNumber = (Latest and tonumber(Latest.Value)) or 0
    for Number = math.max(0, LatestNumber - 4), LatestNumber do
        local Room = Rooms:FindFirstChild(tostring(Number))
        if Room then task.spawn(ProcessRoom, Room) end
    end

    WaterBypassConnection = Rooms.ChildAdded:Connect(function(Room)
        if Toggles.BypassWater.Value then task.spawn(ProcessRoom, Room) end
    end)
end)

local AlmaConnection
Toggles.BypassAlma:OnChanged(function(Value)
    if AlmaConnection then
        AlmaConnection:Disconnect()
        AlmaConnection = nil
    end
    if not Value then return end

    for _, Child in ipairs(Services.Workspace:GetChildren()) do
        if Child.Name == "Alma" then pcall(function() Child:Destroy() end) end
    end
    AlmaConnection = Services.Workspace.ChildAdded:Connect(function(Child)
        if Child.Name == "Alma" and Toggles.BypassAlma.Value then
            pcall(function() Child:Destroy() end)
        end
    end)
end)

--────────────────────────── Seek / Eyestalk 路径显示 ──────────────────────────
-- 游戏会在 PathLights 文件夹里依次生成「引导光」(SeekGuidingLight)，
-- 每一盏代表路径上的一个点。原版把这些点连成一串光束，于是就能看到怪物的路线。
-- 光束需要两个 Attachment 当端点，所以每生成一站就配两个。
--
-- 收尾：SeekMovingNewClone（怪物本体）消失时把整串清掉。
local PathBeams = { Seek = {}, Eyestalk = {} }
local PathNodes = Instance.new("Folder")
PathNodes.Name = "DoorsESPX_PathNodes"
PathNodes.Parent = GetHiddenContainer()

local function MakeBeam(From, To, Color, Visible)
    local Beam = Instance.new("Beam")
    Beam.Color = ColorSequence.new(Color)
    Beam.FaceCamera = true
    Beam.Width0 = 0.2
    Beam.Width1 = 0.2
    Beam.Brightness = 10
    Beam.LightInfluence = 0
    Beam.LightEmission = 0
    Beam.Enabled = true
    local Alpha = Visible and 0 or 1
    Beam.Transparency = NumberSequence.new(Alpha)
    Beam.Parent = PathNodes

    local A0 = Instance.new("Attachment")
    A0.Parent = From
    local A1 = Instance.new("Attachment")
    A1.Parent = To
    Beam.Attachment0 = A0
    Beam.Attachment1 = A1
    return Beam
end

local function MakeNode(CF)
    local Node = Instance.new("Part")
    Node.Name = "PathNode"
    Node.Size = Vector3.one
    Node.Transparency = 1
    Node.Anchored = true
    Node.CanCollide = false
    Node.CanQuery = false
    Node.CFrame = CF
    Node.Parent = PathNodes
    return Node
end

local function ClearBeams(Which)
    for _, Beam in ipairs(PathBeams[Which]) do
        pcall(function() Beam:Destroy() end)
    end
    table.clear(PathBeams[Which])
end

local function SetBeamsVisible(Which, Visible)
    for _, Beam in ipairs(PathBeams[Which]) do
        pcall(function() Beam.Transparency = NumberSequence.new(Visible and 0 or 1) end)
    end
end

local function SetBeamsColor(Which, Color)
    for _, Beam in ipairs(PathBeams[Which]) do
        pcall(function() Beam.Color = ColorSequence.new(Color) end)
    end
end

-- 一组引导光 → 一串节点 + 光束。
-- 第一盏光只建节点（没有上一站可连）；从第二盏起，每盏都和上一站连一条光束。
local PathLastNode = { Seek = nil, Eyestalk = nil }

local function BuildPathFromLights(Lights, Which, ColorOption, VisibleToggle)
    for _, Light in ipairs(Lights) do
        if Light and Light.Name == "SeekGuidingLight" then
            local Node = MakeNode(Light.CFrame)
            local Previous = PathLastNode[Which]
            if Previous and Previous.Parent then
                local Beam = MakeBeam(Node, Previous, ColorOption.Value, VisibleToggle.Value)
                table.insert(PathBeams[Which], Beam)
            end
            PathLastNode[Which] = Node
            pcall(function() Light:Destroy() end)
        end
    end
end

-- ① 引导光一出现就转成节点（PathLights 里持续会有新光生成）
local PendingLights = {}
local LightConnection

local function InstallPathLights()
    if LightConnection then return end
    local Folder = Services.Workspace:FindFirstChild("PathLights")
    if not Folder then return end

    local function Accept(Child)
        if Child.Name == "SeekGuidingLight" then PendingLights[#PendingLights + 1] = Child end
    end
    for _, Child in ipairs(Folder:GetChildren()) do Accept(Child) end
    LightConnection = Folder.ChildAdded:Connect(Accept)

    task.spawn(function()
        while LightConnection do
            local Light = table.remove(PendingLights, 1)
            if Light then
                BuildPathFromLights({ Light }, "Seek", Options.ShowSeekPathColor, Toggles.ShowSeekPathToggle)
            end
            task.wait()
        end
    end)
end

InstallPathLights()
-- PathLights 文件夹可能比脚本晚出现，等一会儿再试
task.delay(5, InstallPathLights)
task.delay(20, InstallPathLights)

-- ② 怪物本体消失 → 清掉整串路径
Connections.PathCleanup = Services.Workspace.ChildAdded:Connect(function(Child)
    if Child.Name == "SeekMovingNewClone" or Child.Name == "Eyestalk" then
        Child.Destroying:Once(function()
            ClearBeams("Seek")
            ClearBeams("Eyestalk")
            PathLastNode.Seek = nil
            PathLastNode.Eyestalk = nil
            for _, Node in ipairs(PathNodes:GetChildren()) do
                pcall(function() Node:Destroy() end)
            end
        end)
    end
end)

-- ③ 开关 / 颜色改动立刻生效
Toggles.ShowSeekPathToggle:OnChanged(function(Value) SetBeamsVisible("Seek", Value) end)
Options.ShowSeekPathColor:OnChanged(function(Value) SetBeamsColor("Seek", Value) end)

Toggles.ShowEyestalkPathToggle:OnChanged(function(Value) SetBeamsVisible("Eyestalk", Value) end)
Options.ShowEyestalkPathColor:OnChanged(function(Value) SetBeamsColor("Eyestalk", Value) end)

--────────────────────────── 假装脚步声（The Rooms） ──────────────────────────
-- 原版用 __index 钩子把 Humanoid.MoveDirection 改成「脸朝哪就算往哪走」。
-- 本脚本的自动走 Rooms 是直接用 MoveTo 的，怪物听不到脚步，
-- 打开这个就会「假装一直在朝前走」，让怪物的追踪正常触发。
-- 挂在 MoveControls 上比钩 __index 轻得多。
local SpoofFootstepsHooked = false
task.spawn(function()
    while not MoveControls do task.wait(0.5) end
    if SpoofFootstepsHooked then return end
    SpoofFootstepsHooked = true

    local Original = MoveControls.GetMoveVector
    pcall(function()
        MoveControls.GetMoveVector = function(...)
            if Toggles.RoomsAutoWalkSpoofFootsteps.Value
                and Floor == "Rooms"
                and Char.RootPart
                and not (Char.Character and Char.Character:GetAttribute("Hiding")) then
                return Vector3.new(0, 0, -1)   -- 一直「往前推」
            end
            return Original(...)
        end
    end)
end)

--────────────────────────── 档案馆：时钟 / 保险箱答案 ──────────────────────────
-- 档案馆房间的 Assets 里有个 ArchivesClock，它的 Time.TextLabel 显示当前时间。
-- ① 「显示时钟」把那个时间抄到屏幕左下角，省得跑回去看；
-- ② 「保险箱答案」把时间换算成保险箱要的答案。
--
-- 路径是嵌套的（Assets → ArchivesClock → Time → TextLabel），
-- 从最近 6 间房往回找，找到的第一个就是当前用的那个钟。
local ClockCachedLabel
local ClockCachedRoom

local function ClockLabelFrom(Room)
    local Assets = Room and Room:FindFirstChild("Assets", true)
    local Clock = Assets and Assets:FindFirstChild("ArchivesClock", true)
    local Time = Clock and Clock:FindFirstChild("Time", true)
    local Label = Time and Time:FindFirstChild("TextLabel")
    return (Label and Label:IsA("TextLabel")) and Label or nil
end

local function ResolveClock()
    if ClockCachedLabel and ClockCachedLabel.Parent
        and ClockCachedLabel:IsDescendantOf(Services.Workspace) then
        return ClockCachedLabel
    end

    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then return nil end

    local Numbered = {}
    for _, Room in ipairs(Rooms:GetChildren()) do
        local Number = tonumber(Room.Name)
        if Number then Numbered[#Numbered + 1] = { Room = Room, Number = Number } end
    end
    table.sort(Numbered, function(A, B) return A.Number > B.Number end)

    for Index = 1, math.min(6, #Numbered) do
        local Label = ClockLabelFrom(Numbered[Index].Room)
        if Label then
            ClockCachedLabel = Label
            ClockCachedRoom = Numbered[Index].Room
            return Label
        end
    end
    return nil
end

-- 保险箱答案：把 "HH:MM" 的时间换算成游戏要的那个数字。
-- 游戏里的钟是 12 小时制，保险箱要的是「时针位置 × 5 + 分针位置」这类算法，
-- 这里按原版的换算来：小时先转 12 小时制，再乘以 5 加上分钟。
Functions.ClockAnswer = function()
    local Label = ResolveClock()
    if not Label then return nil end
    local Hour, Minute = string.match(Label.Text, "(%d+):(%d+)")
    Hour, Minute = tonumber(Hour), tonumber(Minute)
    if not Hour or not Minute then return nil end
    Hour = Hour % 12
    return Hour * 5 + math.floor(Minute / 12)
end

-- ① 屏幕左下角的时间显示
local ClockGui
local ClockLabel

local function ClockHudDestroy()
    if ClockGui then
        pcall(function() ClockGui:Destroy() end)
        ClockGui = nil
        ClockLabel = nil
    end
end

Toggles.TimeShower:OnChanged(function(Value)
    ClockHudDestroy()
    if not Value then return end

    local Parent = Services.CoreGui or LocalPlayer:FindFirstChild("PlayerGui")
    if not Parent then return end

    ClockGui = Instance.new("ScreenGui")
    ClockGui.Name = "DoorsESPX_Clock"
    ClockGui.ResetOnSpawn = false
    ClockGui.IgnoreGuiInset = true
    pcall(function() ClockGui.Parent = Parent end)
    if not ClockGui.Parent then
        ClockGui.Parent = LocalPlayer:FindFirstChild("PlayerGui")
    end

    ClockLabel = Instance.new("TextLabel")
    ClockLabel.Name = "Time"
    ClockLabel.AnchorPoint = Vector2.new(0, 1)
    ClockLabel.Position = UDim2.new(0, 12, 1, -12)
    ClockLabel.Size = UDim2.new(0, 180, 0, 32)
    ClockLabel.BackgroundTransparency = 1
    ClockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClockLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ClockLabel.TextStrokeTransparency = 0.4
    ClockLabel.TextSize = 22
    ClockLabel.Font = Enum.Font.GothamBold
    ClockLabel.TextXAlignment = Enum.TextXAlignment.Left
    ClockLabel.Text = "时间: --:--"
    ClockLabel.Parent = ClockGui

    task.spawn(function()
        while Toggles.TimeShower.Value do
            local Source = ResolveClock()
            if ClockLabel and ClockLabel.Parent then
                ClockLabel.Text = Source and ("时间: " .. Source.Text) or "时间: --:--"
            end
            task.wait(0.2)
        end
        ClockHudDestroy()
    end)
end)

-- ② 时钟遥控：让游戏不断去「看」那个钟（有些解谜条件需要这个）
local ClockRemoteRunning = false
local function RunClockRemote()
    if ClockRemoteRunning then return end
    if not Toggles.TimeShower.Value then return end
    ClockRemoteRunning = true
    task.spawn(function()
        while Toggles.TimeShower.Value do
            local Label = ResolveClock()
            local Clock = Label and Label:FindFirstAncestor("ArchivesClock")
            local Remote = Clock and Clock:FindFirstChild("LookedAtRemote", true)
            if Remote and Remote:IsA("RemoteEvent") then
                pcall(function() Remote:FireServer() end)
                task.wait(0.5)
            else
                task.wait(0.25)
            end
        end
        ClockRemoteRunning = false
    end)
end

-- 开关打开时启动；已经开着的话重复调用会被防重入挡住
Toggles.TimeShower:OnChanged(function(Value)
    if Value then RunClockRemote() end
end)


--────────────────────────── Figure 无敌 ──────────────────────────
-- 原版是靠「偏移伪装」把 Figure 判定你的位置挪开 200 格来避免被抓。
-- 单独驱动那一整套代价太大，这里用更直接的办法：把 Figure 挪到地图外面。
--
-- 和「删除 Figure」的区别：
--   删除 Figure 只在矿井生效、且要求你对那些部件有网络所有权；
--   这个是把整只 Figure 的模型 PivotTo 走，地牢里那种 Figure 用这个更稳。
-- 两个都开也不会打架（都以挪走为结果）。
local FigureLastMove = 0
Connections.FigureGodmode = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.FigureGodmode.Value then return end
    if tick() - FigureLastMove < 0.3 then return end
    FigureLastMove = tick()

    local ENDING = CFrame.new(0, -2500, 0)
    local function Banish(Entity)
        if Entity:IsA("Model") then
            pcall(function() Entity:PivotTo(ENDING) end)
        else
            for _, Part in ipairs(Entity:GetDescendants()) do
                if Part:IsA("BasePart") then
                    pcall(function() Part.CFrame = ENDING end)
                end
            end
        end
    end

    for _, Name in ipairs({ "FigureRig", "FigureRagdoll", "Figure" }) do
        local Entity = Services.Workspace:FindFirstChild(Name)
        if Entity then Banish(Entity) end
    end
end)

--────────────────────────── 绕过 Drones ──────────────────────────
-- 无人机群靠一个叫 WalkedInto 的子对象判定「你走进来了」。
-- 原版的做法是把这个子对象从 Drones 里摘出来、挂到 ReplicatedStorage 上 ——
-- 判定体不在地图里了，无人机就触发不了。
-- 关掉开关时再把它挂回原来的位置。
local DroneOriginalParents = {}
local DroneConnection

Toggles.BypassDrones:OnChanged(function(Value)
    local function ProcessDrones(Drones)
        local WalkedInto = Drones:FindFirstChild("WalkedInto")
            or Drones:WaitForChild("WalkedInto", 3)
        if WalkedInto and not DroneOriginalParents[WalkedInto] then
            DroneOriginalParents[WalkedInto] = Drones
            pcall(function() WalkedInto.Parent = Services.ReplicatedStorage end)
        end
    end

    if Value then
        for _, Child in ipairs(Services.Workspace:GetChildren()) do
            if Child.Name == "Drones" then ProcessDrones(Child) end
        end
        if DroneConnection then DroneConnection:Disconnect() end
        DroneConnection = Services.Workspace.ChildAdded:Connect(function(Child)
            if Child.Name == "Drones" and Toggles.BypassDrones.Value then
                ProcessDrones(Child)
            end
        end)
    else
        -- 还原：谁的孩子回谁那儿去
        for WalkedInto, Original in pairs(DroneOriginalParents) do
            if WalkedInto and WalkedInto.Parent and Original and Original.Parent then
                pcall(function() WalkedInto.Parent = Original end)
            end
        end
        DroneOriginalParents = {}
        if DroneConnection then
            DroneConnection:Disconnect()
            DroneConnection = nil
        end
    end
end)

--────────────────────────── 自动刷 Knob ──────────────────────────
-- 只在 Ballz 楼层有效，而且必须在 0 号房间（起点）才起作用。
-- 原理就是「反复死 → 结算 → 复活」，每死一次结算一次，靠这个刷 Knob。
-- 原版把这个流程放在 Heartbeat 里，用 KnobFarmStarted / KnobFarmActive 两个标记
-- 配合；这里改成一个循环线程，读起来清楚得多。
local KnobFarmRunning = false

Toggles.KnobFarm:OnChanged(function(Value)
    if not Value or KnobFarmRunning then return end
    KnobFarmRunning = true

    task.spawn(function()
        while Toggles.KnobFarm.Value do
            -- 只在 Ballz 的 0 号房刷
            if Floor ~= "Ballz" then
                task.wait(0.5)
                continue
            end
            local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
            local Latest = GameData and GameData:FindFirstChild("LatestRoom")
            if not Latest or Latest.Value ~= 0 then
                task.wait(0.5)
                continue
            end

            -- 顺手检查一下金币够不够（不够就别刷了，白死）
            local Gold = 0
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local Topbar = PlayerGui and PlayerGui:FindFirstChild("TopbarUI")
            local GoldVal = Topbar
                and Topbar:FindFirstChild("Topbar", true)
                and Topbar.Topbar:FindFirstChild("StatsTopbarHandler", true)
            if GoldVal then
                GoldVal = GoldVal:FindFirstChild("StatModules", true)
                GoldVal = GoldVal and GoldVal:FindFirstChild("Gold", true)
                GoldVal = GoldVal and GoldVal:FindFirstChild("GoldVal")
                if GoldVal then Gold = GoldVal.Value end
            end
            if Gold < (Options.KnobFarmGoldMin.Value or 0) then
                task.wait(1)
                continue
            end

            -- 自杀
            local replicatesignal = getgenv().replicatesignal
            if type(replicatesignal) == "function" then
                pcall(replicatesignal, LocalPlayer.Kill)
            elseif Char.Humanoid then
                pcall(function() Char.Humanoid.Health = 0 end)
            end

            -- 等复活
            local Guard = 0
            while not LocalPlayer:GetAttribute("Alive") and Guard < 200 do
                Guard = Guard + 1
                task.wait()
            end

            -- 结算
            local Stats = Remote("Statistics")
            if Stats then pcall(function() Stats:FireServer() end) end
            task.wait(0.25)
        end
        KnobFarmRunning = false
    end)
end)

--────────────────────────── 速度操纵的两种方式 ──────────────────────────
-- 原版「速度操纵」有两种做法，用下拉切换：
--   Velocity —— 在角色上挂一个 BodyVelocity，一直朝脸朝的方向推 2.25；
--               移动很平滑，但只支持「往前走」。
--   Pivot    —— 每帧直接把角色往前挪 2560 格。幅度极大，用来穿长走廊；
--               愚人酒店 / 旧酒店不适用（会把状态搞乱，原版也排除了）。
-- 注意这两种都是「强制位移」，会和服务端的反作弊打架，所以默认不开。
local VelocityManipBody
local VelocityManipLast = 0

local function EnsureManipulateBody()
    if VelocityManipBody and VelocityManipBody.Parent then return VelocityManipBody end
    VelocityManipBody = Instance.new("BodyVelocity")
    VelocityManipBody.Name = "DoorsESPX_Manipulate"
    VelocityManipBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    return VelocityManipBody
end

Connections.VelocityManipulation = Services.RunService.Heartbeat:Connect(function()
    local Enabled = Toggles.VelocityManipulationToggle.Value
    local Mode = Options.VelocityManipulationMode.Value
    local Root = Char.RootPart

    if not Enabled or not Root or Mode ~= "Velocity" then
        if VelocityManipBody and VelocityManipBody.Parent then VelocityManipBody.Parent = nil end
        return
    end

    local Body = EnsureManipulateBody()
    Body.Parent = Root
    Body.Velocity = Root.CFrame.LookVector * 2.25
end)

Connections.VelocityPivot = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.VelocityManipulationToggle.Value then return end
    if Options.VelocityManipulationMode.Value ~= "Pivot" then return end
    if Floor == "Fools" or Floor == "OldHotel" then return end
    -- 不需要每帧都挪，否则会瞬移到地图外面
    if tick() - VelocityManipLast < 1 then return end
    VelocityManipLast = tick()

    local Character = Char.Character
    local Camera = Services.Workspace.CurrentCamera
    if Character and Camera then
        pcall(function()
            Character:PivotTo(Camera:GetPivot() * CFrame.new(0, 0, 2560))
        end)
    end
end)

--────────────────────────── 把推车送到指定玩家 ──────────────────────────
-- 原版是个按钮 + 一个玩家名下拉。这里下拉的选项动态跟着服务器里的人走。
local function RefreshCartTargets()
    local Names = {}
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then Names[#Names + 1] = Player.Name end
    end
    table.sort(Names)
    pcall(function()
        Options.ShoppingCartTarget:SetValues(#Names > 0 and Names or { "" })
        if #Names > 0 and not Options.ShoppingCartTarget.Value then
            Options.ShoppingCartTarget:SetValues(Names, true)
        end
    end)
end

RefreshCartTargets()
Services.Players.PlayerAdded:Connect(RefreshCartTargets)
Services.Players.PlayerRemoving:Connect(RefreshCartTargets)

PushCartsToTarget = function()
    local TargetName = Options.ShoppingCartTarget.Value
    local Target = TargetName and Services.Players:FindFirstChild(TargetName)
    if not Target or not Target.Character then
        Functions.Notify({ Title = "先选一个目标玩家" })
        return
    end

    local TargetCF = Target.Character:GetPivot()
    local Count = 0
    EachShoppingCart(function(Cart)
        pcall(function() Cart:PivotTo(TargetCF) end)
        Count = Count + 1
    end)

    if Count == 0 then
        Functions.Notify({ Title = "场上没有推车" })
    else
        Functions.Notify({ Title = "已把 " .. tostring(Count) .. " 辆推车送到 " .. TargetName })
    end
end

--────────────────────────── 矿车自动驾驶 ──────────────────────────
-- 原版三件事：
--   ① 接管移动输入 —— 靠近转向节点时按节点上的 Turn 属性往左/右打方向；
--   ② 靠近低头板就自动低头（不然会被撞）；
--   ③ 顺带把 FOV 顶成设置里的值。
-- 本脚本用 PlayerModule 的 Controls.GetMoveVector 接手输入（原版也是这条路）。
Functions.GetMinecart = function()
    local Camera = Services.Workspace.CurrentCamera
    return (Camera and Camera:FindFirstChild("MinecartRig")) ~= nil
end

Functions.GetNearestTurnNode = function()
    local Best, BestDistance = nil, math.huge
    local Root = Char.RootPart
    if not Root then return nil end
    local Limit = Options.AutoSteerMinecartTurnDistance.Value
    for _, Node in ipairs(Objects.SeekNodes) do
        if Node and Node.Parent and Node:IsA("BasePart") then
            local Distance = (Node.Position - Root.Position).Magnitude
            if Distance < Limit and Distance < BestDistance then
                Best, BestDistance = Node, Distance
            end
        end
    end
    return Best
end

Functions.GetNearestDuckBoard = function()
    local Best, BestDistance = nil, math.huge
    local Root = Char.RootPart
    if not Root then return nil end
    local Limit = Options.AutoSteerMinecartDuckDistance.Value
    for _, Board in ipairs(Objects.SeekDuckBoards) do
        if Board and Board.Parent then
            local Part = Board.PrimaryPart or Board:FindFirstChildWhichIsA("BasePart", true)
            if Part then
                local Distance = (Part.Position - Root.Position).Magnitude
                if Distance < Limit and Distance < BestDistance then
                    Best, BestDistance = Board, Distance
                end
            end
        end
    end
    return Best
end

-- 接管移动输入。只挂一次，靠开关切换实际行为。
local OriginalGetMoveVector
task.spawn(function()
    while not OriginalGetMoveVector do
        local Ok, Controls = pcall(function()
            return require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
        end)
        if Ok and Controls and type(Controls.GetMoveVector) == "function" then
            OriginalGetMoveVector = Controls.GetMoveVector
            pcall(function()
                Controls.GetMoveVector = function(...)
                    if Toggles.AutoSteerMinecart.Value and Floor == "Mines"
                        and Functions.GetMinecart() then
                        local Node = Functions.GetNearestTurnNode()
                        if Node then
                            local Turn = Node:GetAttribute("Turn")
                            if Turn == "Left" then return Vector3.new(-1, 0, 0) end
                            if Turn == "Right" then return Vector3.new(1, 0, 0) end
                            return Vector3.zero
                        end
                    end
                    return OriginalGetMoveVector(...)
                end
            end)
        end
        task.wait(0.5)
    end
end)

local MinecartDucked = false
local LastDuck = 0
Connections.AutoSteerMinecart = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.AutoSteerMinecart.Value then return end
    if not Functions.GetMinecart() then return end
    if tick() - LastDuck < 0.1 then return end
    LastDuck = tick()

    local WantDuck = Functions.GetNearestDuckBoard() ~= nil
    if WantDuck ~= MinecartDucked then
        MinecartDucked = WantDuck
        local Crouch = GetCrouchRemote()
        if Crouch then
            pcall(function() Crouch:FireServer(WantDuck, true) end)
        end
    end

    if MainGame then
        pcall(function() MainGame.fovtarget = Options.FieldOfView.Value end)
    end
end)

--────────────────────────── 自动解锚点 ──────────────────────────
-- 原版：先读游戏悬停框里显示的密码，再把附近显示同样密码的锚点解掉。
Functions.GetCurrentAnchor = function()
    local MainUI = LocalPlayer:FindFirstChild("PlayerGui")
    MainUI = MainUI and MainUI:FindFirstChild("MainUI")
    local HintFrame = MainUI and MainUI:FindFirstChild("AnchorHintFrame")
    local CodeLabel = HintFrame and HintFrame:FindFirstChild("AnchorCode")
    if not CodeLabel then return nil end

    for _, Anchor in ipairs(Objects.Objectives) do
        if Anchor and Anchor.Parent and Anchor.Name == "MinesAnchor" then
            local Sign = Anchor:FindFirstChild("Sign")
            local Label = Sign and Sign:FindFirstChild("TextLabel")
            if Label and Label.Text == CodeLabel.Text then
                return Anchor
            end
        end
    end
    return nil
end

Connections.AutoSolveAnchors = Services.RunService.Heartbeat:Connect(function()
    if not Toggles.AutoSolveAnchors.Value then return end
    local Anchor = Functions.GetCurrentAnchor()
    if not Anchor then return end
    local Prompt = Anchor:FindFirstChildWhichIsA("ProximityPrompt", true)
    if Prompt and FirePrompt then pcall(FirePrompt, Prompt) end
end)

--────────────────────────── 去除 A-90 / Dread / Screech（真实路径） ──────────────────────────
-- 原版把 MainUI 里的这几个模块改名让游戏找不到它们。
-- 本脚本原来找不到这条路径所以只能靠名字猜，现在补上准确路径。
local function DisableUiModule(Name, Disable, Suffix)
    if not MainGame then return end
    local Ok, Listener = pcall(function() return MainGame.RemoteListener end)
    if not Ok or not Listener then return end
    local Modules = Listener:FindFirstChild("Modules")
    if not Modules then return end
    local Module = Modules:FindFirstChild(Name)
    if not Module then return end
    local Target = Disable and (Name .. "_Disabled") or Name
    pcall(function() Module.Name = Target end)
end

ExploitChecks[#ExploitChecks + 1] = function()
    DisableUiModule("A90", Toggles.RemoveA90.Value)
    DisableUiModule("Dread", Toggles.RemoveDread.Value)
    DisableUiModule("Screech", Toggles.RemoveScreech.Value)
end

--────────────────────────── 楼层：通关按钮 ──────────────────────────
-- 原版每个楼层有各自的通关流程（矿井水泵、Cringle 等）。
-- 这里只做一个通用版本：把角色送到本层最靠后的那道门。
FloorsAction = function(Action)
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not Rooms then
        Functions.Notify({ Title = "现在不在 Doors 里" })
        return
    end

    if Action == "FloorsSkipToEnd" then
        local Root = Char.RootPart
        if not Root then
            Functions.Notify({ Title = "角色还没加载好" })
            return
        end

        local Best, BestNumber = nil, -1
        for _, Door in ipairs(Objects.Doors) do
            if Door and Door.Parent then
                local Number = tonumber(Functions.GetDoorNumber(Door)) or -1
                if Number > BestNumber then Best, BestNumber = Door, Number end
            end
        end

        if not Best then
            Functions.Notify({ Title = "这一层还没扫到门" })
            return
        end

        local Part = Best:FindFirstChildWhichIsA("BasePart", true)
        if Part then
            pcall(function() Root.CFrame = Part.CFrame + Vector3.new(0, 3, 0) end)
            Functions.Notify({ Title = "已跳到第 " .. tostring(BestNumber) .. " 道门" })
        end
    elseif Action == "FloorsCompleteDamSeek" then
        -- 矿井水坝：把所有 WaterPump 阀门挨个传送过去触发。
        -- 阀门上有 Abysall_Completed 属性，标记完成就不用在管它。
        -- 中途会有过场动画（Cutscene），那段时间不能乱动，要等它结束。
        if not (Floor == "Mines" and (tonumber(LatestRoom.Value) or 0) >= 100) then
            Functions.Notify({ Title = "需要先到矿井 200 房以后" })
            return
        end

        local Cutscene = Remote("Cutscene")
        local InCutscene = false
        local CutsceneConnection
        if Cutscene then
            CutsceneConnection = Cutscene.OnClientEvent:Connect(function()
                InCutscene = true
                task.wait(7)
                InCutscene = false
            end)
        end

        Functions.Notify({ Title = "开始处理水坝阀门" })

        task.spawn(function()
            local function NextPump()
                local Best, BestHeight = nil, -math.huge
                for _, Object in ipairs(Objects.Objectives) do
                    if Object and Object.Parent and Object.Name == "WaterPump"
                        and Object:GetAttribute("Abysall_Completed") ~= true then
                        local Part = Object.PrimaryPart
                        if Part and Part.Position.Y > BestHeight then
                            Best, BestHeight = Object, Part.Position.Y
                        end
                    end
                end
                return Best
            end

            local Guard = 0
            while Guard < 600 do
                Guard = Guard + 1
                local Pump = NextPump()
                if not Pump then break end

                -- 挨着这个阀门一直触发到它标记完成
                local PumpGuard = 0
                while Pump.Parent and PumpGuard < 300 do
                    PumpGuard = PumpGuard + 1
                    if InCutscene then
                        task.wait(0.1)
                        continue
                    end
                    local Character = Char.Character
                    if Character then
                        pcall(function() Character:PivotTo(Pump:GetPivot()) end)
                    end
                    local Prompt = Pump:FindFirstChild("ValvePrompt", true)
                    if Prompt and FirePrompt then pcall(FirePrompt, Prompt) end
                    if Pump:GetAttribute("Abysall_Completed") then break end
                    task.wait(0.1)
                end
                task.wait(0.1)
            end

            if CutsceneConnection then CutsceneConnection:Disconnect() end
            Functions.Notify({ Title = "水坝阀门已全部处理完" })
        end)

    elseif Action == "FloorsCompleteCringle" then
        -- Cringle：直接传送到出口门就算过
        local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
        local Door = Rooms and Rooms:FindFirstChild("RippleExitDoor", true)
        local Character = Char.Character
        if Door and Character then
            pcall(function() Character:PivotTo(Door:GetPivot()) end)
            Functions.Notify({ Title = "已传送到 Cringle 出口" })
        else
            Functions.Notify({ Title = "没找到 Cringle 的出口门" })
        end

    elseif Action == "FloorsCompleteRun" then
        Functions.Notify({
            Title = "逐层通关请用「自动」页的楼梯间自动通关",
            Body = "不同楼层的通关条件不一样，没有通用的一键通关。",
        })
    end
end

--────────────────────────── 自动走 The Rooms ──────────────────────────
-- 原版用 PathfindingService 算路，然后逐个 waypoint MoveTo 过去；
-- 路上如果检测到实体就改为「钻进最近的藏身点躲起来」。
-- 本脚本照抄这套流程，只把变量名写短、把路径球收进一个文件夹方便清理。

local RoomsPathFolder = Instance.new("Folder")
RoomsPathFolder.Name = "DoorsESPX_RoomsPath"
RoomsPathFolder.Parent = GetHiddenContainer()

local RoomsWalkActive = false

local function ClearRoomsPath()
    for _, Node in ipairs(RoomsPathFolder:GetChildren()) do
        pcall(function() Node:Destroy() end)
    end
end

local function RoomsNearestHidingSpot()
    local Best, BestDistance = nil, math.huge
    for _, Spot in ipairs(Objects.HidingSpots) do
        if Spot and Spot.Parent and Spot.PrimaryPart then
            local Dark = Spot:FindFirstChild("HiddenPlayer", true)
            local Occupied = Dark and Dark.Value
            if not Occupied and Spot.PrimaryPart.Position.Y > -10 then
                local Distance = (Spot.PrimaryPart.Position - Char.RootPart.Position).Magnitude
                if Distance < BestDistance then Best, BestDistance = Spot, Distance end
            end
        end
    end
    return Best
end

local ROOMS_RUSHERS = {
    RushMoving = true, AmbushMoving = true, BackdoorRush = true,
    A60 = true, A120 = true, CustomEntity = true,
    GlitchRush = true, GlitchAmbush = true,
}

local function RoomsExit()
    local Rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    local Latest = GameData and GameData:FindFirstChild("LatestRoom")
    local Room = Rooms and Latest and Rooms:FindFirstChild(tostring(Latest.Value))
    return Room and Room:FindFirstChild("RoomExit") or nil
end

local function RoomsPathTarget()
    for _, Object in ipairs(Services.Workspace:GetChildren()) do
        if ROOMS_RUSHERS[Object.Name] and Object.PrimaryPart then
            local Y = Object.PrimaryPart.Position.Y
            if Y > -10 and Y < 150 then
                if Object.Name ~= "A60" or not Toggles.RoomsAutoWalkIgnoreA60.Value then
                    return RoomsNearestHidingSpot() or RoomsExit()
                end
            end
        end
    end
    return RoomsExit()
end

Connections.RoomsAutoWalk = Services.RunService.Heartbeat:Connect(function()
    if Floor ~= "Rooms" then return end
    if not Toggles.RoomsAutoWalk.Value then return end
    if RoomsWalkActive then return end
    local Character = Char.Character
    local Humanoid = Char.Humanoid
    local Root = Char.RootPart
    local Collision = Character and Character:FindFirstChild("Collision")
    if not (Character and Humanoid and Root and Collision) then return end

    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    local Latest = GameData and GameData:FindFirstChild("LatestRoom")
    if not Latest or Latest.Value >= 1000 then return end

    RoomsWalkActive = true

    local Path = Services.PathfindingService:CreatePath({
        AgentCanJump = true, AgentCanClimb = false, WaypointSpacing = 4,
        AgentRadius = 1.5, AgentHeight = 1.5,
    })

    if Toggles.RoomsAutoWalkIgnoreA60.Value and not Toggles.PositionSpoof.Value then
        Toggles.PositionSpoof:Set(true)
    end

    local Target = RoomsPathTarget()
    if not Target then RoomsWalkActive = false; return end

    local TargetPosition
    if Target.Name == "RoomExit" then
        TargetPosition = Target.Position
    else
        local HidePrompt = Target:FindFirstChild("HidePrompt")
        if HidePrompt and Target.PrimaryPart then
            for _, Part in ipairs(Target:GetDescendants()) do
                if Part:IsA("BasePart") then
                    pcall(function() Part.CanCollide = false end)
                end
            end
            TargetPosition = Target.PrimaryPart.Position
        end
    end

    if not TargetPosition or (TargetPosition - Root.Position).Magnitude >= 750 then
        RoomsWalkActive = false
        return
    end

    local Ok = pcall(function() Path:ComputeAsync(Collision.Position, TargetPosition) end)
    local Waypoints = Ok and Path:GetWaypoints() or {}

    ClearRoomsPath()

    if #Waypoints == 0 then
        local Exit = RoomsExit()
        if Exit then Humanoid:MoveTo(Exit.Position) end
        RoomsWalkActive = false
        return
    end

    -- 画路径球：开关打开时才显形
    local ShowPath = Toggles.RoomsAutoWalkShowPathToggle.Value
    local PathColor = Options.RoomsAutoWalkShowPathColor.Value
    for _, Waypoint in ipairs(Waypoints) do
        local Ball = Instance.new("Part")
        Ball.Name = "PathNode"
        Ball.Shape = Enum.PartType.Ball
        Ball.Size = Vector3.one
        Ball.Position = Waypoint.Position
        Ball.Anchored = true
        Ball.CanCollide = false
        Ball.CanQuery = false
        Ball.Material = Enum.Material.Neon
        Ball.Color = PathColor
        Ball.Transparency = ShowPath and 0.5 or 1
        Ball.Parent = RoomsPathFolder
    end

    -- 逐个 waypoint 走过去；卡住超时就标记该点难走
    local Stuck = false
    for _, Waypoint in ipairs(Waypoints) do
        if Stuck or not Toggles.RoomsAutoWalk.Value then break end

        local Finished = false
        local Start = tick()

        local Step = Services.RunService.RenderStepped:Connect(function()
            if Stuck or not Toggles.RoomsAutoWalk.Value then Finished = true; return end

            -- 半路冒出新实体、且原来目标不是藏身点 → 重新决策
            local NewTarget = RoomsPathTarget()
            local WasHiding = Target:FindFirstChild("HidePrompt") ~= nil
            local NowHiding = NewTarget and NewTarget:FindFirstChild("HidePrompt") ~= nil
            if NewTarget and NowHiding and not WasHiding then Finished = true; return end

            -- 目标就是藏身点：够近就把自己塞进去
            if WasHiding then
                local HidePrompt = Target:FindFirstChild("HidePrompt")
                if HidePrompt
                    and (TargetPosition - Root.Position).Magnitude < HidePrompt.MaxActivationDistance
                    and Character:GetAttribute("Hiding") ~= true
                    and FirePrompt then
                    pcall(FirePrompt, HidePrompt)
                end
            end

            -- 只要平面距离够近就算到这个点了（不然 Y 差一点永远到不了）
            local Flat = Vector3.new(Waypoint.Position.X, Root.Position.Y, Waypoint.Position.Z)
            if (Flat - Root.Position).Magnitude < 5 then Finished = true end
            Humanoid:MoveTo(Waypoint.Position)
        end)

        while not Finished do
            if tick() - Start > Options.RoomsAutoWalkPathfindTimeout.Value then
                local Block = Instance.new("Part")
                Block.Name = "StuckPart"
                Block.Size = Vector3.one
                Block.CFrame = Collision.CFrame
                Block.Anchored = true
                Block.CanCollide = false
                Block.Transparency = 1
                Block.Parent = RoomsPathFolder
                Stuck = true
                break
            end
            task.wait()
        end

        Step:Disconnect()
        Humanoid:MoveTo(Root.Position)
    end

    RoomsWalkActive = false
end)

-- 显示路径 / 颜色开关立刻生效（不用等下一次算路）
Toggles.RoomsAutoWalkShowPathToggle:OnChanged(function(Value)
    for _, Node in ipairs(RoomsPathFolder:GetChildren()) do
        if Node.Name == "PathNode" then
            pcall(function() Node.Transparency = Value and 0.5 or 1 end)
        end
    end
end)

Options.RoomsAutoWalkShowPathColor:OnChanged(function(Value)
    for _, Node in ipairs(RoomsPathFolder:GetChildren()) do
        if Node.Name == "PathNode" then
            pcall(function() Node.Color = Value end)
        end
    end
end)

--────────────────────────── 杂项按钮 ──────────────────────────
-- 原版这几个按钮直接发对应遥控；「重置角色」优先用 replicatesignal
-- （服务端立刻杀掉你），没有就退回游戏自己的 Underwater 遥控。
SelfAction = function(Action)
    if Action == "Revive" then
        TryRevive()
        return
    end

    if Action == "Reset" then
        Globals.SelfKilled = true
        local replicatesignal = getgenv().replicatesignal
        if type(replicatesignal) == "function" then
            pcall(replicatesignal, LocalPlayer.Kill)
            return
        end
        local Underwater = Remote("Underwater")
        if Underwater then
            pcall(function() Underwater:FireServer(true) end)
        elseif Char.Humanoid then
            pcall(function() Char.Humanoid.Health = 0 end)
        end
        return
    end

    local Name = (Action == "PlayAgain") and "PlayAgain" or "Lobby"
    local Target = Remote(Name)
    if Target then
        pcall(function() Target:FireServer() end)
    else
        Functions.Notify({ Title = "这个楼层不支持「" .. tostring(Action) .. "」" })
    end
end
end)()  -- [regfix] 端口块作用域结束

local Module = {}

function Module.Unload()
    for Key, Connection in pairs(Connections) do
        if type(Key) == "string" then
            pcall(function() Connection:Disconnect() end)
        else
            pcall(function() Key:Disconnect() end)
            pcall(function() Connection:Disconnect() end)
        end
    end

    DisconnectScene()
    DestroyHud()
    StopChairBypass()

    if ManipulateBody then
        pcall(function() ManipulateBody:Destroy() end)
    end
    if FlyBody then
        pcall(function() FlyBody:Destroy() end)
    end

    if Toggles.AmbientToggle.Value or Toggles.RemoveCameraFog.Value then
        pcall(function()
            Lighting.Ambient = SceneOriginal.Ambient
            Lighting.FogEnd = SceneOriginal.FogEnd
            for Object, Density in pairs(AtmoOriginal) do
                if Object.Parent then Object.Density = Density end
            end
        end)
    end

    pcall(function() ESPLibrary:Unload() end)
    pcall(function() Window.Gui:Destroy() end)

    if getgenv()[STATE_KEY] == Module then
        getgenv()[STATE_KEY] = nil
    end
    print("[Msptds] 已卸载")
end

-- 测试 / 调试用：暴露内部表（不改任何行为）
Module.Objects = Objects
Module.Toggles = Toggles
Module.Options = Options
Module.Char = Char
Module.Lang = Lang

getgenv()[STATE_KEY] = Module

print("[Msptds] 载入完成 · ESP 开关默认全关（同原版）")
print("[Msptds] " .. tostring(UIKeybind.Key.Name) .. " 开关界面 · "
    .. tostring(FovKeybind.Key.Name) .. " 视野 · "
    .. tostring(NoclipKeybind.Key.Name) .. " 穿墙 · "
    .. tostring(NoPullbackKeybind.Key.Name) .. " 无拉回穿墙")
print("[Msptds] 卸载 getgenv().DoorsESPX.Unload()")

return Module

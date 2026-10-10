local function PickDesc(cfg)
    -- 提示 / 说明文字一律不显示：一是用户要求把所有提示去掉，
    -- 二是长文案在 WindUI 里会顶出控件边界。
    return nil
end

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

-- 换语言要重新执行本脚本，所以必须知道自己的地址。
-- ★ 这里原来**根本没有这个变量**：老代码写的是
--       State.Unload()                          -- 先把界面销毁
--       loadstring(game:HttpGet(SCRIPT_URL))()  -- 再 HttpGet(nil) → 直接报错
--   于是界面已经被销毁、新脚本又没跑起来 ——
--   表现就是「一切语言，整个界面没了、大部分功能失效」。这就是那个 bug 的根。
--   同时顺序也改成了「先取到、先编译，成功才卸载」（见下面的换语言处理）。
local SCRIPT_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/DoorsESP.lua"
-- 和 WindUI 那几个源同一套路：主源拉不动就换镜像，全都失败才放弃（放弃时保留当前界面）
local SCRIPT_MIRRORS = {
    SCRIPT_URL,
    "https://cdn.jsdelivr.net/gh/suif666/suif@main/DoorsESP.lua",
    "https://gcore.jsdelivr.net/gh/suif666/suif@main/DoorsESP.lua",
    "https://testingcf.jsdelivr.net/gh/suif666/suif@main/DoorsESP.lua",
    "https://fastly.jsdelivr.net/gh/suif666/suif@main/DoorsESP.lua",
}

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
    -- ★ 每一项单独 pcall。
    --   原来的写法只要某一项抛错（WindUI 控件已被销毁、或某个控件不接受这个属性），
    --   整个循环就在中途断掉，后面所有项的标题都更新不到 ——
    --   表现就是「一切语言，界面中英混杂、一大片功能像失效了」。
    for _, e in ipairs(Lang.Registry) do
        if e.fn then
            pcall(function() e.inst.Text = e.fn() end)
        else
            local v = Lang.T(e.key)
            if v ~= nil then
                pcall(function() e.inst[e.prop] = v end)
            end
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
local Mini = {}
Mini.WindUI = WindUI
Mini.Registry = {}   -- [控件] = { fn = 回调, get = 取值函数 }，读配置 / 重放时用

local function NewShadow()
    return { Cb = nil, Click = nil, InSet = false }
end

-- 控件标题 / 描述 / Flag 都交给 PickText / PickKey / PickDesc 解析，
-- 这样 L() 里只写中文、英文靠 Lang.T(Key) 取，切语言的时候整块 UI 重建后就是对应语言。
local function PickDesc(cfg)
    -- ★ 这里必须返回 nil。
    --   文件开头也定义过一份 PickDesc（就是同样的 return nil），但被这一份覆盖了，
    --   于是所有说明文字又显示出来 —— 长文案在 WindUI 里会把控件顶出边界，
    --   后面新增的控件（比如「秒互动」）就被挤到可视区外面，看着像"没加上"。
    return nil
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
    -- ★ 说明文字一律不创建：用户不需要这些描述，而且长文案在 WindUI 里会把
    --   后面的控件顶出可视区（「秒互动」开关看不见就是这个原因之一）。
    --   返回一个哑对象，让调用方照旧能赋 .Text / 调 :Set() 而不报错。
    --   注意：Lua 的 return 必须是块的最后一条语句，所以这里用 if true then ... end
    --   把下面的原始实现留成不可达代码（语法合法，运行不到）。
    if true then
        return {
            Text = "",
            Set = function(self) return self end,
            SetText = function(self) return self end,
            Destroy = function() end,
        }
    end
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
-- ★ 关键：Roblox 的相机脚本每帧都会把 MouseBehavior 顶回 LockCenter，
--   所以 MouseBehavior 必须每帧写（RenderStepped）。原来用 0.25 秒节流，
--   写完下一帧就被锁回去，等于没唤醒 —— 这就是「开着界面鼠标还是被锁」的原因。
--   MouseIconEnabled 是持久状态，用低频 Heartbeat 同步就够。
do
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- WindUI 的窗口只有 .Closed / .Destroyed 两个状态位。
    -- 原来还读了 .IsOpen / .Opened（WindUI 里没有这两个字段），
    -- 靠 `nil ~= false` 恰好为真才没报错，这里直接简化掉。
    local function WindowShown()
        local win = Mini.__Window
        if not win then return false end
        if win.Closed == true or win.Destroyed == true then return false end
        return true
    end

    -- 每帧：把鼠标行为顶成 Default。
    -- ★ 必须绑在「相机之后」执行（Enum.RenderPriority.Camera.Value + 1）。
    --   默认相机的鼠标锁定就是在 Camera 这个优先级里写 MouseBehavior 的，
    --   普通 RenderStepped / Heartbeat 都跑在它**之前**，写完下一行就被相机覆盖 ——
    --   这就是「明明每帧都在设，鼠标还是被锁」的原因。
    local function UnlockMouse()
        if not WindowShown() then return end
        pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
    end
    pcall(function()
        RunService:BindToRenderStep("DoorsESPX_UnlockMouse",
            Enum.RenderPriority.Camera.Value + 1, UnlockMouse)
    end)

    -- 低频：同步鼠标图标显隐（这个是持久状态，不需要每帧）
    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        acc = acc + (tonumber(dt) or 0)
        if acc < 0.25 then return end
        acc = 0
        local want = WindowShown()
        if UIS.MouseIconEnabled ~= want then
            pcall(function() UIS.MouseIconEnabled = want end)
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
    local Was = Lang.Current
    Lang.Set(Want)
    getgenv().DoorsESPX_Lang = Want

    task.defer(function()
        -- ★ 顺序修正：先取脚本、先编译，全都成功了才卸载旧界面。
        --   原来是「先 Unload 再 HttpGet」—— 网络拉不动时界面已经被销毁，
        --   新脚本又没跑起来，表现就是「一切语言，整个界面没了、大部分功能失效」。
        local Source
        local Tried = {}
        for _, url in ipairs(SCRIPT_MIRRORS) do
            local ok, got = pcall(function() return game:HttpGet(url) end)
            if ok and type(got) == "string" and #got > 1000 then
                Source = got
                break
            end
            Tried[#Tried + 1] = tostring(url:match("^https?://([^/]+)")) .. "→" .. tostring(got)
        end
        if not Source then
            -- 失败就把语言回退到切换前，界面原封不动继续用
            Lang.Set(Was)
            getgenv().DoorsESPX_Lang = Was
            LastLangPick = (Was == "en") and "English" or "中文"
            warn("[Msptds] 换语言失败：所有源都取不到脚本（" .. table.concat(Tried, "  ") .. "）。已保留当前界面。")
            return
        end

        local okLoad, Chunk = pcall(loadstring, Source)
        if not okLoad or type(Chunk) ~= "function" then
            Lang.Set(Was)
            getgenv().DoorsESPX_Lang = Was
            LastLangPick = (Was == "en") and "English" or "中文"
            warn("[Msptds] 换语言失败：脚本编译不过。已保留当前界面。")
            return
        end

        local State = getgenv()[STATE_KEY]
        if State and State.Unload then pcall(State.Unload) end

        local okRun, err = pcall(Chunk)
        if not okRun then
            warn("[Msptds] 换语言后重载失败：" .. tostring(err) .. "，请手动重新执行一次脚本")
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
Options.SpeedBypassWalk = Mini.Slider(tabChar.Page, {
    Key = "char.walk", Text = "行走速度", Min = 0, Max = 75, Default = 15, Rounding = 0 })
Options.SpeedBypassLadder = Mini.Slider(tabChar.Page, {
    Key = "char.ladder", Text = "爬梯速度", Min = 0, Max = 75, Default = 15, Rounding = 0 })
Toggles.SpeedBypassToggle = Mini.Toggle(tabChar.Page, L(
    "char.bypass", "速度绕过", "Speed Bypass",
    "Writes the extra speed into the game's own SpeedBoostBehind attribute instead of fighting WalkSpeed.",
    "照 tplays 插件的做法：把多出来的速度写进游戏自己的 SpeedBoostBehind 属性，让游戏自己算出这个速度，就不会被拉回。"))
Mini.Divider(tabChar.Page)
Toggles.NoclipToggle = Mini.Toggle(tabChar.Page, L(
    "char.noclip", "穿墙", "Noclip",
    "Allows your character to pass through solid objects.",
    "角色可以穿墙（每帧把 CanCollide 关掉）。"))
local NoclipKeybind = Mini.Keybind(tabChar.Page, {
    Key = "char.noclipkey", Text = "穿墙快捷键", Default = Enum.KeyCode.N })
Mini.Divider(tabChar.Page)
Toggles.FlyToggle = Mini.Toggle(tabChar.Page, L(
    "char.fly", "飞行", "Fly",
    "Fly with WASD, Space to go up and LeftCtrl to go down.",
    "WASD 相对镜头飞行，空格上升、左 Ctrl 下降。"))

--────────────────────────── 绕过 ──────────────────────────
Mini.Divider(tabBypass.Page)
Toggles.NoPullbackNoclipToggle = Mini.Toggle(tabBypass.Page, L(
    "by.nopull", "无拉回穿墙", "No-Pullback Noclip",
    "tplays addon's anticheat bypass: grab a chair/cart so you stop being pulled back, plus noclip.",
    "对应 tplays 插件的『反作弊绕过』：抓一把椅子/购物车把反作弊顶掉，再配合穿墙，走过去不会被拉回。"))
local NoPullbackKeybind = Mini.Keybind(tabBypass.Page, {
    Key = "by.nopullkey", Text = "无拉回穿墙快捷键", Default = Enum.KeyCode.V })

-- 反作弊操作替代（tplays 插件同名功能；跟上面的椅子法、跟速度绕过都不是一回事）
Toggles.ACMABypassToggle = Mini.Toggle(tabBypass.Page, L(
    "by.acma", "反作弊操作替代", "Anticheat Operation Substitute",
    "tplays addon: parent a BodyVelocity to your root, push along the camera at 2.25, and force noclip.",
    "对应 tplays 插件的『反作弊操作替代』：BodyVelocity 挂到根部件，沿视线方向推 2.25，并强制开穿墙。"))
local ACMAKeybind = Mini.Keybind(tabBypass.Page, {
    Key = "by.acmakey", Text = "反作弊操作替代快捷键", Default = Enum.KeyCode.B })
Toggles.ACMABypassToggle:OnChanged(function(Value)
    if Value then StartACMA() else StopACMA() end
end)

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

--────────────────────────── 反作弊操作替代（tplays 插件同名功能，来源 Abysall） ──────────
-- ★ 这跟上面的「无拉回穿墙」（椅子法）和「速度绕过」是**三个不同的功能**，不要混：
--     无拉回穿墙      = 抓一把椅子/购物车，靠椅子把反作弊顶掉（t 的『反作弊绕过』）
--     速度绕过        = 改 WalkSpeed / 滑行（t 的『速度绕过』）
--     反作弊操作替代  = 本段（t 的『反作弊操作替代』，tplaysaddon L3743-3772）
--
-- t 原文：
--     StuffToRemoveLater.body.Parent = Character.HumanoidRootPart
--     RenderStepped:  StuffToRemoveLater.body.Velocity = Camera.CFrame.LookVector * 2.25
--     if Variables.Noclip.Value then Variables.noclipOn = true else Variables.Noclip:SetValue(true) end
--     Variables.Noclip:SetDisabled(true)
--   [垫片] StuffToRemoveLater.body → 就地建一个 BodyVelocity（下面叫 ACMA.Body）
--   [垫片] Variables.Noclip         → 本脚本的 Toggles.NoclipToggle
local ACMA = { Body = nil, Conn = nil, NoclipWasOn = false }

local function StopACMA()
    if ACMA.Body then
        pcall(function() ACMA.Body.Parent = nil end)
        ACMA.Body = nil
    end
    if ACMA.Conn then
        pcall(function() ACMA.Conn:Disconnect() end)
        ACMA.Conn = nil
    end
    -- 插件原文：pcall(Variables.Noclip.SetDisabled, Variables.Noclip, false)
    local Noclip = Toggles.NoclipToggle
    if Noclip and Noclip.SetDisabled then
        pcall(function() Noclip:SetDisabled(false) end)
    end
    -- 插件原文：if not Variables.noclipOn then pcall(SetValue, false) end
    if not ACMA.NoclipWasOn and Noclip and Noclip.SetValue then
        pcall(function() Noclip:SetValue(false) end)
    end
    ACMA.NoclipWasOn = false
end

local function StartACMA()
    StopACMA()
    local Character, RootPart = Char.Character, Char.RootPart
    if not (Character and RootPart and RootPart.Parent) then
        pcall(function()
            Mini.WindUI:Notify({ Title = "反作弊操作替代：角色还没加载好", Duration = 4, Icon = "warning" })
        end)
        return false
    end

    -- 插件原文：StuffToRemoveLater.body.Parent = Character.HumanoidRootPart
    local Body = Instance.new("BodyVelocity")
    Body.Name = "DoorsESPX_ACMA"
    Body.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Body.Velocity = Vector3.new(0, 0, 0)
    Body.Parent = RootPart
    ACMA.Body = Body

    -- 插件原文：RenderStepped: body.Velocity = Camera.CFrame.LookVector * 2.25
    ACMA.Conn = Services.RunService.RenderStepped:Connect(function()
        if not ACMA.Body or not ACMA.Body.Parent then return end
        local Cam = Services.Workspace.CurrentCamera
        if not Cam then return end
        pcall(function() ACMA.Body.Velocity = Cam.CFrame.LookVector * 2.25 end)
    end)

    -- 插件原文：if Variables.Noclip.Value then Variables.noclipOn = true else SetValue(true) end
    local Noclip = Toggles.NoclipToggle
    if Noclip and Noclip.Value then
        ACMA.NoclipWasOn = true
    else
        ACMA.NoclipWasOn = false
        if Noclip and Noclip.SetValue then
            pcall(function() Noclip:SetValue(true) end)
        end
    end
    -- 插件原文：pcall(Variables.Noclip.SetDisabled, Variables.Noclip, true)
    if Noclip and Noclip.SetDisabled then
        pcall(function() Noclip:SetDisabled(true) end)
    end
    return true
end

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
    if input.KeyCode == ACMAKeybind.Key then
        Toggles.ACMABypassToggle:Set(not Toggles.ACMABypassToggle.Value)
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

    OrbitState.Angle = (OrbitState.Angle + dt * 90 * (Options.OrbitSpeed.Value or 1)) % 360
    local Height = Options.OrbitHeight.Value or 3
    local Offset = Options.OrbitOffset.Value or 6

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
    local Reach = (Options.WallInteractReach and Options.WallInteractReach.Value) or 1
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
    -- 照 Aby 拆成两个独立开关：秒互动(InstantPrompts) 管 HoldDuration，隔墙(PromptClip) 管视线检测。
    -- 注意不能用 `COND and false or Old` —— COND 为真时 false 会被 or 跳过，拿回旧值，等于没生效。
    local ok1, err1 = pcall(function()
        local Instant = Toggles.InstantPromptsToggle and Toggles.InstantPromptsToggle.Value
        if Instant then
            Prompt.HoldDuration = 0
        else
            Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old")
        end
    end)
    local ok2, err2 = pcall(function()
        local Clip = Toggles.WallInteractToggle and Toggles.WallInteractToggle.Value
        if Clip then
            Prompt.RequiresLineOfSight = false
        else
            Prompt.RequiresLineOfSight = Prompt:GetAttribute("RequiresLineOfSight_Old")
        end
    end)
    if not ok1 or not ok2 then
        warn("[Msptds] 互动属性写失败：" .. tostring(err1) .. " / " .. tostring(err2))
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

--────────────────────────── 自动互动（照搬 Abysall 的 AutoInteract） ──────────────────────────
-- Aby 的做法（原版 7877-7899 行）：
--   Heartbeat 里遍历已收集的提示，距离进入触发范围就 fire，节流 1/60 秒；
--   同房间判断用提示的 ParentRoom 属性对玩家的 CurrentRoom。
-- 这边没有 Aby 那套忽略名单 / 藏身点数据结构，所以只做「附近的提示自动触发」。
local AutoInteract = { Last = 0, Conn = nil }

-- 收集提示的常驻监听。原来只在「隔墙互动」打开时才建，导致单独开自动互动时列表是空的。
local function EnsurePromptWatch()
    if PromptReach.Conn then return end
    ScanPrompts(false)
    PromptReach.Conn = Services.Workspace.DescendantAdded:Connect(function(Inst)
        if Inst.ClassName == "ProximityPrompt" then
            RememberPrompt(Inst)
            if Toggles.WallInteractToggle and Toggles.WallInteractToggle.Value then ApplyPrompt(Inst) end
        end
    end)
end

local function PromptInSameRoom(Prompt)
    local Room = Prompt:GetAttribute("ParentRoom")
    if not Room then return true end
    local LP = Players.LocalPlayer
    local Cur = LP and LP:GetAttribute("CurrentRoom")
    if Cur == nil then return true end
    return tonumber(Room) == tonumber(Cur)
end

local function AutoFirePrompt(Prompt)
    if not Prompt or not Prompt.Parent or not Prompt.Enabled then return end
    if not PromptInSameRoom(Prompt) then return end
    local LP = Players.LocalPlayer
    if not LP then return end

    local Parent = Prompt.Parent
    local Position
    if Parent:IsA("BasePart") then
        Position = Parent.Position
    elseif Parent:IsA("Model") then
        local ok, Pivot = pcall(function() return Parent:GetPivot().Position end)
        if not ok then return end
        Position = Pivot
    else
        return
    end

    if LP:DistanceFromCharacter(Position) > Prompt.MaxActivationDistance then return end

    -- 触发前先放宽（和隔墙互动同一套），触发后 ApplyPrompt 会维持
    ReachPrompt(Prompt)
    local Fire = getgenv().fireproximityprompt
    if type(Fire) ~= "function" then
        local ok, Global = pcall(function() return fireproximityprompt end)
        Fire = ok and Global or nil
    end
    if type(Fire) == "function" then
        pcall(Fire, Prompt)
    end
end

local function StartAutoInteract()
    if AutoInteract.Conn then return end
    EnsurePromptWatch()
    AutoInteract.Conn = Services.RunService.Heartbeat:Connect(function()
        if not (Toggles.AutoInteractToggle and Toggles.AutoInteractToggle.Value) then return end
        local Now = tick()
        if Now - AutoInteract.Last < 1 / 60 then return end
        AutoInteract.Last = Now
        for _, Prompt in ipairs(PromptReach.List) do
            task.spawn(AutoFirePrompt, Prompt)
        end
    end)
end

local function StopAutoInteract()
    if AutoInteract.Conn then pcall(function() AutoInteract.Conn:Disconnect() end) end
    AutoInteract.Conn = nil
end

--────────────────────────── 自动楼层（楼梯间，照搬 tplays 插件） ──────────────────────────
-- 这里是插件 `Variables.AutoFloors.Stairwell`（tplaysaddon-v2.4.0 L8927-9037）的逐句搬运。
-- 插件那份代码调用了它自己内部的一批东西，本脚本里没有，所以下面先给它们做「等价垫片」：
-- 同名、同行为、就地实现，让下面的原文能原样跑。垫片全部标了 [垫片]。
--
--   [垫片] Library:Notify                → Mini.WindUI:Notify
--   [垫片] Library.Toggles.DoorReach     → 本脚本的 ReachDoor（把门的提示拉长，让游戏自己开门）
--   [垫片] Toggles.AntiTeleport*         → 本脚本没有这两个开关，做成空开关
--   [垫片] Variables.StuffToKeepEnabled  → 本脚本没有那批「防实体」开关，留空表
--   [垫片] getTpFunction                 → 用 getconnections 找 ServerTeleported 的处理函数
--   [垫片] hookfunction / checkcaller / restorefunction / isfunctionhooked
--                                        → 执行器自带，取不到就退化成「不挂钩」
--   [垫片] ServerTeleported / CurrentRooms / LatestRoom / Crouch → 直接从游戏里找
local AutoFloorState = {
    Running = false, Notify = nil, Hooks = {},
    slideSH = false, raknet_at_hook = false, tpFunction = nil,
    CurrentDoor = nil,
}

-- [垫片] 对应插件的 GameData.LatestRoom
local function GetLatestRoom()
    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    return GameData and GameData:FindFirstChild("LatestRoom") or nil
end

-- [垫片] 对应插件的 workspace.CurrentRooms
local function GetCurrentRooms()
    return Services.Workspace:FindFirstChild("CurrentRooms")
end

-- [垫片] 对应插件的 ReplicatedStorage.RemotesFolder.ServerTeleported
local function GetServerTeleported()
    local RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    return RemotesFolder and RemotesFolder:FindFirstChild("ServerTeleported") or nil
end

local AutoFloorDoorReached = nil

local function ReachDoor(Door)
    if not Door or AutoFloorDoorReached == Door then return end
    AutoFloorDoorReached = Door
    local Lock = Door:FindFirstChild("Lock")
    ReachPrompt(Lock and (Lock:FindFirstChild("UnlockPrompt") or Lock:FindFirstChild("FakePrompt")))
    ReachPrompt(Door:FindFirstChild("ActivateEventPrompt"))
    ReachPrompt(Door:FindFirstChild("DoorPrompt"))
end

-- [垫片] Library.Toggles.DoorReach —— 插件每帧把它置 true，效果是隔空开门。
--        这里做成同名接口：置 true 时就去把当前门的提示拉长，等价。
local DoorReachShim = { Value = false, Disabled = false }
function DoorReachShim:SetValue(v)
    self.Value = v and true or false
    if self.Value then ReachDoor(AutoFloorState.CurrentDoor) end
end
function DoorReachShim:SetDisabled(v) self.Disabled = v and true or false end

-- [垫片] Toggles.AntiTeleport / AntiTeleportRaknet —— 本脚本没有这两个开关，空实现
local function StubToggle()
    return {
        Value = false, Disabled = false,
        SetValue = function(self, v) self.Value = v and true or false end,
        SetDisabled = function(self, v) self.Disabled = v and true or false end,
    }
end
local AntiTeleportStub, AntiTeleportRaknetStub = StubToggle(), StubToggle()

-- [垫片] Variables.StuffToKeepEnabled —— 插件靠它每帧把一批「防实体」开关顶开，
--        本脚本没有那批开关，所以留空表（有的话往这里塞，行为和插件一致）。
local StuffToKeepEnabled = {}

-- [垫片] Library:Notify(Title, Description, Time)
local function AFNotify(Title, Description, Time)
    local Text = tostring(Title or "")
    if Description ~= nil then Text = Text .. "：" .. tostring(Description) end
    pcall(function()
        Mini.WindUI:Notify({ Title = Text, Duration = tonumber(Time) or 4, Icon = "info" })
    end)
end

-- [垫片] getTpFunction（插件 L4229-4233 原文）
local function getTpFunction()
    local ServerTeleported = GetServerTeleported()
    if not ServerTeleported then return nil end
    local getconnections = getgenv().getconnections
    local connections = getconnections and getconnections(ServerTeleported.OnClientEvent)
    local connection = connections and connections[1]
    return connection and connection.Function
end

-- 停：对应插件 Callback 的 else 分支
local function StopAutoFloor(reason)
    AutoFloorState.Running = false
    if AutoFloorState.Notify then
        pcall(function() AutoFloorState.Notify:Destroy() end)
        AutoFloorState.Notify = nil
    end
    -- 插件原文：if not Toggles.SlideSpeedHack and Variables.slideSH then
    if AutoFloorState.slideSH then
        AutoFloorState.slideSH = false
        local Crouch = GetCrouchRemote and GetCrouchRemote() or nil
        if Crouch then pcall(function() Crouch:FireServer(true, true) end) end
    end
    AntiTeleportStub:SetDisabled(false)
    if AutoFloorState.raknet_at_hook then
        AntiTeleportRaknetStub:SetDisabled(false)
    end
    -- 插件原文：if isfunctionhooked and restorefunction then ... end
    local isfunctionhooked = getgenv().isfunctionhooked
    local restorefunction = getgenv().restorefunction
    if type(isfunctionhooked) == "function" and type(restorefunction) == "function" then
        if AutoFloorState.tpFunction then
            pcall(function()
                if isfunctionhooked(AutoFloorState.tpFunction) then
                    restorefunction(AutoFloorState.tpFunction)
                end
            end)
        end
        local ServerTeleported = GetServerTeleported()
        if ServerTeleported then
            pcall(function()
                if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
                    restorefunction(ServerTeleported.OnClientEvent.Connect)
                end
            end)
        end
    end
    for _, Restore in ipairs(AutoFloorState.Hooks) do pcall(Restore) end
    AutoFloorState.Hooks = {}
    if AutoFloorState.LatestRoomChanged then
        pcall(function() AutoFloorState.LatestRoomChanged:Disconnect() end)
        AutoFloorState.LatestRoomChanged = nil
    end
    if Connections.AutoFloor then
        pcall(function() Connections.AutoFloor:Disconnect() end)
        Connections.AutoFloor = nil
    end
    if reason then AFNotify(reason, nil, 4) end
end

-- 插件 Callback 的 then 分支里、hook 相关的部分（插件 L8947-8962 原文结构）
local function InstallTeleportHook()
    local hookfunction = getgenv().hookfunction
    local restorefunction = getgenv().restorefunction
    local checkcaller = getgenv().checkcaller
    if type(hookfunction) ~= "function" or type(restorefunction) ~= "function" then
        return false   -- 执行器不支持：只是被传送时可能被拉回一次，不影响开门
    end
    local ServerTeleported = GetServerTeleported()
    if not ServerTeleported then return false end

    AutoFloorState.tpFunction = getTpFunction()
    local ok = pcall(function()
        if AutoFloorState.tpFunction then
            local tp
            tp = hookfunction(AutoFloorState.tpFunction, function(...)
                if type(checkcaller) == "function" and checkcaller() then
                    tp(...)
                end
            end)
        end
        local RealConnect = ServerTeleported.OnClientEvent.Connect
        local hooked
        hooked = hookfunction(RealConnect, function(self, func)
            if type(checkcaller) == "function" and not checkcaller() then
                local blanked = hookfunction(func, function() end)
                AutoFloorState.Hooks[#AutoFloorState.Hooks + 1] = function()
                    pcall(restorefunction, blanked)
                end
                AutoFloorState.tpFunction = func
            end
            return hooked(self, func)
        end)
        AutoFloorState.Hooks[#AutoFloorState.Hooks + 1] = function()
            pcall(restorefunction, RealConnect)
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
        AFNotify("现在不在 Doors 里：找不到 GameData.LatestRoom", nil, 4)
        return false
    end
    if not FirePrompt then
        AFNotify("执行器没有 fireproximityprompt，传送到门前也开不了门", nil, 5)
    end

    AutoFloorState.Running = true
    AutoFloorState.CurrentDoor = nil
    AutoFloorDoorReached = nil

    -- 插件原文（L8936-8946）：先关掉反传送开关，再挂钩
    AntiTeleportStub:SetValue(false)
    AntiTeleportRaknetStub:SetValue(false)
    Services.RunService.RenderStepped:Wait()
    AntiTeleportStub:SetDisabled(true)
    AntiTeleportRaknetStub:SetDisabled(true)

    InstallTeleportHook()
    Services.RunService.Heartbeat:Wait()

    -- 插件原文（L8963-8968）：建一个常驻提示，显示已开门数 / 当前房间
    local tempRoom = GetCurrentRooms() and GetCurrentRooms():FindFirstChild(tostring(LatestRoom.Value))
    local Raw = tempRoom and tempRoom:GetAttribute("RawName") or "?"
    AutoFloorState.Notify = { Destroy = function() end }   -- [垫片] 插件是 Library:Notify({Persist=true})，这里用日志提示代替
    AFNotify(string.format("自动楼层已启动  已开门 %s  当前房间 %s", tostring(LatestRoom.Value), tostring(Raw)), nil, 5)

    Connections.AutoFloor = Services.RunService.Heartbeat:Connect(function()
        local ok, err = xpcall(AutoFloorStep, Trace)
        if not ok then warn("[Msptds] 自动楼层出错：" .. tostring(err)) end
    end)

    -- 插件原文（L9004-9008）：门号变化时更新提示
    AutoFloorState.LatestRoomChanged = LatestRoom.Changed:Connect(function()
        local R = GetCurrentRooms() and GetCurrentRooms():FindFirstChild(tostring(LatestRoom.Value))
        local RN = R and R:GetAttribute("RawName") or "?"
        AFNotify(string.format("已开门 %s  当前房间 %s", tostring(LatestRoom.Value), tostring(RN)), nil, 3)
    end)
    return true
end

-- 插件原文（L8971-9003）的 Heartbeat 循环体
AutoFloorStep = function()
    if not AutoFloorState.Running then return end

    local LatestRoom = GetLatestRoom()
    local CurrentRooms = GetCurrentRooms()
    if not (LatestRoom and CurrentRooms) then return end

    local Room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
    local Door = Room and Room:FindFirstChild("Door")

    -- 插件原文：if not Variables.slideSH then Variables.slideSH = true; Crouch:FireServer(true,true) end
    if not AutoFloorState.slideSH then
        AutoFloorState.slideSH = true
        local Crouch = GetCrouchRemote and GetCrouchRemote() or nil
        if Crouch then pcall(function() Crouch:FireServer(true, true) end) end
    end

    -- 插件原文：for _, toggle in Variables.StuffToKeepEnabled do ... end
    for _, toggle in ipairs(StuffToKeepEnabled) do
        if not toggle.Value and not toggle.Disabled then
            pcall(function() toggle:SetValue(true) end)
        end
    end

    local stairwellexit
    if LatestRoom.Value > 98 then
        stairwellexit = Room and Room:FindFirstChild("StairwellExitDoor")
    end

    AutoFloorState.CurrentDoor = Door or AutoFloorState.CurrentDoor

    if stairwellexit then
        local Character = Char.Character
        if Character then pcall(function() Character:PivotTo(stairwellexit:GetPivot()) end) end
        local Collision = stairwellexit:FindFirstChild("Collision")
        local EnterPrompt = Collision and Collision:FindFirstChild("EnterPrompt")
        ReachPrompt(EnterPrompt)
        if EnterPrompt and FirePrompt then pcall(FirePrompt, EnterPrompt) end
        AFNotify("楼梯间已完成！", nil, 10)
        Toggles.AutoFloorToggle:SetValue(false)
        -- 插件原文：Toggles.AutoFloor:SetDisabled(true)
        if Toggles.AutoFloorToggle.SetDisabled then Toggles.AutoFloorToggle:SetDisabled(true) end
    elseif Door then
        local Character = Char.Character
        if Character then pcall(function() Character:PivotTo(Door:GetPivot()) end) end
    end

    -- 插件原文：if not Library.Toggles.DoorReach.Value then ... SetValue(true) end
    if not DoorReachShim.Value then
        DoorReachShim:SetValue(true)
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

--────────────────────────── 新功能控件 ──────────────────────────

-- 飞行
Options.FlySpeed = Mini.Slider(tabChar.Page, {
    Key = "char.flyspeed", Text = "飞行速度", Min = 20, Max = 300, Default = 60, Rounding = 0 })

-- 无加速度
Toggles.NoAccelerationToggle = Mini.Toggle(tabChar.Page, L(
    "char.noaccel", "无加速度", "No Acceleration",
    "Sets every character part's density to 100 so you stop sliding around (same as the original).",
    "把角色每个部件的密度顶到 100，移动时不会再打滑、被推飞（照抄原版的 Remove Acceleration）。"))
Toggles.NoAccelerationToggle:OnChanged(function(Value)
    ApplyNoAcceleration(Value)
end)

Mini.Divider(tabChar.Page)

-- 物品环绕
Options.OrbitSpeed = Mini.Slider(tabChar.Page, {
    Key = "char.orbitspeed", Text = "环绕速度", Min = 0.2, Max = 3, Default = 1, Rounding = 0.1 })
Options.OrbitHeight = Mini.Slider(tabChar.Page, {
    Key = "char.orbitheight", Text = "环绕高度", Min = 0, Max = 10, Default = 3, Rounding = 0 })
Options.OrbitOffset = Mini.Slider(tabChar.Page, {
    Key = "char.orbitoffset", Text = "环绕半径", Min = 0, Max = 20, Default = 6, Rounding = 0 })
Toggles.OrbitToggle = Mini.Toggle(tabChar.Page, L(
    "char.orbit", "物品环绕", "Orbit Drops",
    "Orbits every item you dropped around your character (same as the original addon).",
    "把你掉在地上的东西按一个圈均匀绕在角色周围转（照抄 tplays 插件的「环绕掉落物」）。"))
Mini.Label(tabChar.Page, L("char.orbit.note",
    "只环绕「自己掉的」东西（掉落物上 PlayerName 属性等于你的名字），别人的不碰。关掉后东西停在原地。",
    "Only your own dropped items are orbited (PlayerName attribute equals your name). Turning it off leaves them where they are."))

Mini.Divider(tabChar.Page)

Mini.Divider(tabChar.Page)

-- 隔墙互动 / 秒互动（照搬 Abysall 的互动三件套，拆成三个独立开关）
Options.WallInteractReach = Mini.Slider(tabChar.Page, {
    -- 数值照 Abysall 原版：Min 1 / Max 2 / Default 1 / Rounding 1
    -- 原来写的 1~30、默认 10 太大，游戏不认（ProximityPrompt 的实际生效范围有上限）
    Key = "char.wallreach", Text = "互动距离倍率", Min = 1, Max = 2, Default = 1, Rounding = 1 })
Toggles.InstantPromptsToggle = Mini.Toggle(tabChar.Page, L(
    "char.instant", "秒互动", "Instant Prompts",
    "All prompts trigger with no hold time (HoldDuration = 0).",
    "所有提示都不要按住时间（HoldDuration 归零），照搬 Abysall 的 Instant Prompts。"))
Toggles.WallInteractToggle = Mini.Toggle(tabChar.Page, L(
    "char.wall", "隔墙互动", "Interact Through Walls",
    "Prompts ignore the line-of-sight check, so you can interact through walls.",
    "关掉提示的视线检测，隔着墙也能交互，照搬 Abysall 的 Prompt Clip。"))

-- 距离倍率变了就重算一遍（不用每帧扫）
Options.WallInteractReach:OnChanged(function()
    if not (Toggles.WallInteractToggle.Value or Toggles.InstantPromptsToggle.Value) then return end
    for _, Prompt in ipairs(PromptReach.List) do ApplyPromptReach(Prompt) end
end)

Toggles.InstantPromptsToggle:OnChanged(function(Value)
    if Value then EnsurePromptWatch() end
    for _, Prompt in ipairs(PromptReach.List) do
        pcall(function()
            if Value then
                Prompt.HoldDuration = 0
            else
                Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old")
            end
        end)
    end
end)

Toggles.WallInteractToggle:OnChanged(function(Value)
    if Value then
        EnsurePromptWatch()
        ScanPrompts(true)
    else
        for _, Prompt in ipairs(PromptReach.List) do RestorePrompt(Prompt) end
    end
end)

-- 交互距离 / 秒互动 / 隔墙：常驻重写。
-- ★ 原来只在「开关变化」和「滑条变化」那两下写一次，游戏下一帧就把
--   MaxActivationDistance / HoldDuration / RequiresLineOfSight 写回自己的值，
--   所以表现就是「滑条拖了没用、距离不管用」。
--   这里低频（10 次/秒）把已记住的提示重新写一遍，才真的生效。
local PromptReachLoop = { Acc = 0 }
Connections.PromptReachKeep = Services.RunService.Heartbeat:Connect(function(dt)
    local Reach = tonumber(Options.WallInteractReach and Options.WallInteractReach.Value) or 1
    local Instant = Toggles.InstantPromptsToggle and Toggles.InstantPromptsToggle.Value
    local Clip = Toggles.WallInteractToggle and Toggles.WallInteractToggle.Value
    if not (Instant or Clip or Reach ~= 1) then return end

    PromptReachLoop.Acc = PromptReachLoop.Acc + (tonumber(dt) or 0)
    if PromptReachLoop.Acc < 0.1 then return end
    PromptReachLoop.Acc = 0

    EnsurePromptWatch()
    for _, Prompt in ipairs(PromptReach.List) do
        pcall(function()
            if not Prompt.Parent then return end
            local Old = Prompt:GetAttribute("MaxActivationDistance_Old")
            if Old then Prompt.MaxActivationDistance = Old * Reach end
            if Instant then Prompt.HoldDuration = 0 end
            if Clip then Prompt.RequiresLineOfSight = false end
        end)
    end
end)

-- 自动互动（照搬 Abysall 的 Auto Interact）
Toggles.AutoInteractToggle = Mini.Toggle(tabAuto.Page, L(
    "auto.interact", "自动互动", "Auto Interact",
    "Automatically fires nearby prompts.",
    "自动触发附近的提示，照搬 Abysall 的 Auto Interact。"))
Toggles.AutoInteractToggle:OnChanged(function(Value)
    if Value then StartAutoInteract() else StopAutoInteract() end
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
    if not Toggles.OrbitToggle.Value then return end
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
    .. tostring(NoPullbackKeybind.Key.Name) .. " 无拉回穿墙 · "
    .. tostring(ACMAKeybind.Key.Name) .. " 反作弊操作替代")
print("[Msptds] 卸载 getgenv().DoorsESPX.Unload()")

return Module

-- Roblox UI 文本提取器 v24（响应式布局 + 圆形最小化 + 动画）
-- 本版改进（在 v23 基础上）：
-- 1. 【真正修复】复制按钮错位 bug：原代码复制按钮定位公式少减了一个按钮宽度，导致复制按钮
--    右侧超出行容器边界，被 Scroll 的 ClipsDescendants 裁掉一部分，看起来"错位/显示不全"
-- 2. 【真正修复】收藏/删除按钮显示不全：与上面同一处坐标计算连带问题，一并修正
-- 3. 【修复】文本框偶发不显示、需切换分区才恢复的bug：SetDisplay 在"空文本"分支里没有
--    使当前 token 失效，导致后台一个尚未跑完的旧渲染协程会在清空后继续插入行，造成显示错乱。
--    现在无论走哪个分支，一进入 SetDisplay 就立刻使旧 token 失效。
-- 4. 【新增】整个UI（含所有按钮/文字/间距）根据窗口大小连续缩放：UI越大，间距和字号越宽松；
--    UI越小，越紧凑。拖动右下角↘手柄时实时生效，且只更新已存在的行属性（不重建实例），
--    对低配设备友好。
-- 5. 【新增】最小化不再收起成标题栏，而是收起成一个可拖动的小圆点悬浮球，点击圆点还原。
-- 6. 【新增】动画效果：最小化/还原使用缩放+淡出/淡入过渡；切换分区时列表有轻微滑入过渡；
--    动画时长很短（≤0.22秒）且只对单个Frame做Tween（不逐行Tween），保证低配设备流畅。
-- 7. 【优化】自动刷新时如果内容与上次显示完全一致，不再重建整个列表（避免每1.5秒重复重建UI）。
-- 8. 保留全部核心功能：多分区、对象池、批量yield防卡顿、搜索、收藏栏、导出Lua、屏蔽、自动刷新、复制、删除、缩放

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function getHui()
    local ok, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    return ok and hui or nil
end

-- 清理旧UI
pcall(function()
    local old = CoreGui:FindFirstChild("AutoTextCollectorUI")
    if old then old:Destroy() end
end)
pcall(function()
    local old = PlayerGui:FindFirstChild("AutoTextCollectorUI")
    if old then old:Destroy() end
end)
pcall(function()
    local hui = getHui()
    if hui then
        local old = hui:FindFirstChild("AutoTextCollectorUI")
        if old then old:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTextCollectorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local hui = getHui()
if hui then
    ScreenGui.Parent = hui
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = PlayerGui
end

local Sections = {"全部", "PlayerGui", "Workspace", "CoreGui", "RobloxGui", "PlayerList", "第三方UI"}
local CurrentSection = "全部"

local SystemNames = {
    RobloxGui = true, PlayerList = true, Backpack = true, Chat = true,
    BubbleChat = true, ExperienceChat = true, TextChatService = true,
    TopBar = true, Topbar = true, Health = true, EmotesMenu = true,
    Chrome = true, InspectMenu = true, PurchasePrompt = true, ScreenshotHud = true,
}

local SectionData = {}
local BlockedData = {}
for _, name in ipairs(Sections) do
    SectionData[name] = {Texts = {}, Map = {}, Info = {}, AllText = "未检测到 UI 文本"}
    BlockedData[name] = {}
end

local FavoriteData = {Texts = {}, Map = {}}

local AutoRefreshEnabled = false
local St = {}
St.AutoRefresh = 2
St.Live = true          -- 事件驱动实时更新（文本改动立刻反映）
St.Hidden = false      -- 是否把不可见（Visible=false）的元素也算进来
St.Regex = false          -- 搜索按正则匹配
St.Case = false      -- 搜索区分大小写
St.SortModes = {"default", "text", "textdesc", "len", "cls", "path"}
St.SortLabels = {default = "默认", text = "文本↑", textdesc = "文本↓", len = "长度", cls = "类名", path = "路径"}
St.Sort = "default"       -- 当前排序方式
St.Dirty = false          -- 数据被增量改动过，等下一拍只重画不重扫
local AutoScrollToBottom = true
local BlockMode = false
local Minimized = false
local Animating = false -- 最小化/还原动画进行中时，屏蔽重复触发
local CurrentDisplayText = ""
local LastNormalSize = Vector2.new(540, 370) -- 与默认UI大小匹配
local LastNormalPosition = nil
local LastCirclePosition = nil -- 悬浮圆点最后拖动到的位置

-- 当前UI整体缩放（由 LayoutUI 根据窗口大小计算），用于让文本列表行响应式排版
local CurrentUIScale = 1

-- ==================== 创建单行（支持对象池） ====================
local RowPool = {}
local MAX_POOL_SIZE = 400
local ScanErrorLog = 0 -- 扫描错误日志计数（只打印前几条，避免刷屏）

-- 搜索防抖相关
local SearchDebounceTimer = nil
local LastSearchKeyword = ""
local LastSearchSection = ""
local LastSearchResult = nil

local function CleanText(text)
    text = tostring(text or "")
    text = text:gsub("<[^>]->", "")
    text = text:gsub("\r", "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function EscapeLuaString(str)
    str = tostring(str or "")
    str = str:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r")
         :gsub("\t", "\\t"):gsub("\"", "\\\"")
    return str
end

local function IsTextObject(obj)
    return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end

-- ==================== 祖先链：一趟走完「可见性 + 系统UI + 路径」 ====================
-- 原版这里是三个独立函数（IsVisible / IsSystemUI / GetObjectPath），每个文本对象要把
-- 祖先链走最多 3 遍；其中 IsVisible 每一级祖先都 pcall(function() return cur.Visible end)
-- —— 每级分配一个闭包；GetObjectPath 用 table.insert(t, 1, ...)，深度 d 就是 O(d²) 搬移。
-- 合并后：单个对象从 ~3×深度 次调用 + 一堆闭包，降到 1×深度 次调用、零闭包。
local function Analyze(obj)
    local names, depth = {}, 0
    local visible, system = true, false
    local cur = obj
    while cur and cur ~= game do
        depth = depth + 1
        if depth > 96 then break end
        names[depth] = cur.Name
        -- 只有 GuiObject 才有 Visible（ScreenGui 是 Enabled，Folder 之类根本没有该属性），
        -- 用 IsA 判断远比 pcall 便宜
        if visible and cur:IsA("GuiObject") and cur.Visible == false then
            visible = false
        end
        if not system and SystemNames[cur.Name] then
            system = true
        end
        cur = cur.Parent
    end
    local parts = table.create(depth)
    for i = 1, depth do
        parts[i] = names[depth - i + 1]
    end
    return visible, system, table.concat(parts, "/")
end

-- ==================== 读取文本字段（按类探测，结果缓存） ====================
-- 原版每个对象都跑 4 次 pcall + 4 个闭包；这里每个「类」只探测一次，之后直接读属性
local TEXT_PROP_NAMES = {"Text", "ContentText", "LocalizedText", "PlaceholderText"}
St.ClassProps = {}
local function TextPropsOf(obj)
    local cls = obj.ClassName
    local cached = St.ClassProps[cls]
    if cached then return cached end
    local list = {}
    for i = 1, #TEXT_PROP_NAMES do
        local name = TEXT_PROP_NAMES[i]
        if pcall(function() return obj[name] end) then
            list[#list + 1] = name
        end
    end
    St.ClassProps[cls] = list
    return list
end

-- 复用的读取缓冲（FeedObject 不会重入，安全）
St.Buf = {}
local function ReadTextsInto(obj, out)
    local props = TextPropsOf(obj)
    local n = 0
    for i = 1, #props do
        local v = obj[props[i]]
        if type(v) == "string" and v ~= "" then
            n = n + 1
            out[n] = v
        end
    end
    return n
end

-- ==================== 数据层 ====================
-- data.Texts 保持「字符串数组」，显示/搜索/导出等下游逻辑完全不用改；
-- 另外用 data.Info[文本] 记录来源对象，这是「显示来源 / 定位高亮 / 复制路径 /
-- 带路径导出 / 重复计数」的基础。
--   Info[text] = { obj = 首个对象, path = 路径, cls = 类名,
--                  count = 使用该文本的对象数, objs = { [对象] = 路径 } }
St.ObjIndex = setmetatable({}, {__mode = "k"})   -- [对象] = { [文本] = true }

local function Rebuild(section)
    local data = SectionData[section]
    if not data then return end
    data.AllText = (#data.Texts == 0) and "未检测到 UI 文本" or table.concat(data.Texts, "\n")
end

local function Count(section)
    local data = SectionData[section]
    return data and #data.Texts or 0
end

local function AddText(section, text, obj, path, cls)
    text = CleanText(text)
    if text == "" or text == "未检测到 UI 文本" then return false end
    if BlockMode and BlockedData[section] and BlockedData[section][text] then return false end
    local data = SectionData[section]
    if not data then return false end

    if obj then
        local idx = St.ObjIndex[obj]
        if not idx then idx = {}; St.ObjIndex[obj] = idx end
        idx[text] = true
    end

    local info = data.Info[text]
    if info then
        -- 同一句话被多个对象使用：只登记来源，不重复计入条数
        if obj and info.objs[obj] == nil then
            info.objs[obj] = path or ""
            info.count = info.count + 1
        end
        return false
    end

    data.Map[text] = true
    table.insert(data.Texts, text)
    local objs = {}
    if obj then objs[obj] = path or "" end
    data.Info[text] = {
        obj = obj, path = path or "", cls = cls or "",
        count = obj and 1 or 0, objs = objs,
    }
    return true
end

local function AddTextWithAll(section, text, obj, path, cls)
    local added = AddText(section, text, obj, path, cls)
    if section ~= "全部" then
        if AddText("全部", text, obj, path, cls) then added = true end
    end
    return added
end

local function RemoveText(section, text)
    text = CleanText(text)
    local data = SectionData[section]
    if not data then return end
    data.Map[text] = nil
    data.Info[text] = nil
    for i = #data.Texts, 1, -1 do
        if data.Texts[i] == text then table.remove(data.Texts, i) end
    end
    Rebuild(section)
end

-- 按「对象」撤销它贡献的所有文本；若某条文本还有别的对象在用则保留（修掉了原版
-- 去重后无法区分来源、删掉一个对象就误删整条文本的问题）
local function RemoveObject(obj)
    local idx = St.ObjIndex[obj]
    if not idx then return end
    St.ObjIndex[obj] = nil
    for _, section in ipairs(Sections) do
        local data = SectionData[section]
        if data then
            for text in pairs(idx) do
                local info = data.Info[text]
                if info and info.objs[obj] ~= nil then
                    info.objs[obj] = nil
                    info.count = info.count - 1
                    if info.count <= 0 then
                        data.Map[text] = nil
                        data.Info[text] = nil
                        for i = #data.Texts, 1, -1 do
                            if data.Texts[i] == text then table.remove(data.Texts, i) end
                        end
                    end
                end
            end
        end
    end
end

local function RebuildAll()
    SectionData["全部"].Texts = {}
    SectionData["全部"].Map = {}
    SectionData["全部"].Info = {}
    SectionData["全部"].AllText = "未检测到 UI 文本"
    for _, section in ipairs(Sections) do
        if section ~= "全部" then
            for _, text in ipairs(SectionData[section].Texts) do
                local info = SectionData[section].Info[text]
                AddText("全部", text, info and info.obj, info and info.path, info and info.cls)
            end
        end
    end
    Rebuild("全部")
end

-- ==================== 扫描：单遍多桶 ====================
-- 原版：每个分区各扫一遍容器；选「全部」时它会连带把 PlayerGui / CoreGui / 第三方UI
-- 各扫一次，而「第三方UI」内部又扫一次 PlayerGui + CoreGui
-- —— 一次刷新等于对整棵树做 5 遍 GetDescendants。
-- 现在：整棵树只走一遍，同一个文本对象一次性归入它所属的所有分区。
local huiRootCache = nil

local function RefreshHuiRoot()
    huiRootCache = getHui()
    return huiRootCache
end

local function ScanRootsList(huiRoot)
    local roots, seen = {}, {}
    local function add(r)
        if r and not seen[r] then seen[r] = true; roots[#roots + 1] = r end
    end
    add(PlayerGui)
    add(CoreGui)
    add(Workspace)
    -- hui 根若已在 CoreGui/PlayerGui 里就不重复扫（否则整棵子树扫两遍）
    if huiRoot and not huiRoot:IsDescendantOf(CoreGui) and not huiRoot:IsDescendantOf(PlayerGui) then
        add(huiRoot)
    end
    return roots
end

local function FeedTo(section, texts, n, obj, path, cls)
    local added = 0
    for i = 1, n do
        if AddText(section, texts[i], obj, path, cls) then added = added + 1 end
    end
    return added
end

-- 把一个文本对象一次性归入它所属的所有分区
local function FeedObject(obj, huiRoot)
    if obj == ScreenGui or obj:IsDescendantOf(ScreenGui) then return 0 end
    local visible, system, path = Analyze(obj)
    if not visible and not St.Hidden then return 0 end
    local n = ReadTextsInto(obj, St.Buf)
    if n == 0 then return 0 end
    local cls = obj.ClassName
    local inPG = obj:IsDescendantOf(PlayerGui)
    local inCG = obj:IsDescendantOf(CoreGui)
    local inWS = obj:IsDescendantOf(Workspace)
    local inHUI = huiRoot ~= nil and obj:IsDescendantOf(huiRoot)

    local added = 0
    if inPG then added = added + FeedTo("PlayerGui", St.Buf, n, obj, path, cls) end
    if inWS then added = added + FeedTo("Workspace", St.Buf, n, obj, path, cls) end
    if inCG or inHUI then
        added = added + FeedTo("CoreGui", St.Buf, n, obj, path, cls)
        if string.find(path, "RobloxGui", 1, true) then
            added = added + FeedTo("RobloxGui", St.Buf, n, obj, path, cls)
        end
        if string.find(path, "PlayerList", 1, true) then
            added = added + FeedTo("PlayerList", St.Buf, n, obj, path, cls)
        end
    end
    if (inPG or inCG or inHUI) and not system then
        added = added + FeedTo("第三方UI", St.Buf, n, obj, path, cls)
    end
    -- 「全部」沿用原版口径：PlayerGui + CoreGui + hui（不含 Workspace，Workspace 有单独分区）
    if inPG or inCG or inHUI then
        added = added + FeedTo("全部", St.Buf, n, obj, path, cls)
    end
    return added
end

-- 全量扫描：整棵树只走一遍（原版「全部」走 5 遍）
local function ScanAll()
    -- 重扫前必须先清空。原版 ScanSection 就是先清空再扫，我把多个分区合并成
    -- 一趟之后漏了这一步 —— 后果是「本轮已经消失的文本」会永远留在列表里。
    for _, section in ipairs(Sections) do
        local d = SectionData[section]
        if d then
            d.Texts, d.Map, d.Info = {}, {}, {}
            d.AllText = "未检测到 UI 文本"
        end
    end
    St.ObjIndex = setmetatable({}, {__mode = "k"})
    local huiRoot = RefreshHuiRoot()
    local roots = ScanRootsList(huiRoot)
    local total, lastYield = 0, os.clock()
    for r = 1, #roots do
        local root = roots[r]
        local ok, list = pcall(root.GetDescendants, root)
        if ok and list then
            for i = 1, #list do
                local obj = list[i]
                if IsTextObject(obj) then
                    local ok2, n = pcall(FeedObject, obj, huiRoot)
                    if ok2 then
                        total = total + n
                    elseif ScanErrorLog < 5 then
                        ScanErrorLog = ScanErrorLog + 1
                        warn("[UI提取] 跳过文本对象（扫描出错）")
                    end
                end
                -- 按「耗时」让帧（原版按个数每 400 个让一帧）：对象多也不至于反复空等
                local now = os.clock()
                if now - lastYield > 0.006 then
                    lastYield = now
                    task.wait()
                end
            end
        end
    end
    for i = 1, #Sections do Rebuild(Sections[i]) end
    return total
end

-- 保留原函数名：现在任何一次刷新都是一趟全树，等价于原来「全部」的成本
local function ScanSection(section)
    return ScanAll()
end

-- ==================== 增量更新（事件驱动） ====================
-- 原版自动刷新每 1.5 秒全量重扫。这里挂上事件：
--   新出现的文本对象 -> 只处理它自己
--   对象消失         -> 只摘掉它贡献的条目
--   文本被改写       -> 只重算这一个对象
-- 定时轮询退化成兜底（间隔也放宽了）。
St.Conns = setmetatable({}, {__mode = "k"})   -- [对象] = { 连接... }

local function MarkDirtyUI()
    St.Dirty = true
end

local function HookObject(obj) end      -- 前置声明，下面重新赋值
local function UnhookObject(obj) end
local function RefreshOneObject(obj) end

local function DoHookObject(obj)
    if St.Conns[obj] then return end
    if not St.Live then return end
    local props = TextPropsOf(obj)
    local list = {}
    -- 除了文本属性，还必须监听 Visible：可见性一变，这个对象该不该进列表就变了。
    -- 回调统一走 task.defer：批量替换会在遍历过程中改这些属性，同步回调会边遍历边改数据。
    local watch = {"Visible"}
    for i = 1, #props do watch[#watch + 1] = props[i] end
    for i = 1, #watch do
        local ok, conn = pcall(function()
            return obj:GetPropertyChangedSignal(watch[i]):Connect(function()
                task.defer(function() pcall(RefreshOneObject, obj) end)
            end)
        end)
        if ok and conn then list[#list + 1] = conn end
    end
    St.Conns[obj] = list
end

local function DoUnhookObject(obj)
    local list = St.Conns[obj]
    if list then
        St.Conns[obj] = nil
        for i = 1, #list do pcall(function() list[i]:Disconnect() end) end
    end
    RemoveObject(obj)
end

local function DoRefreshOneObject(obj)
    if not obj or not obj.Parent then return end
    if obj == ScreenGui or obj:IsDescendantOf(ScreenGui) then return end
    RemoveObject(obj)
    DoHookObject(obj)
    local ok, n = pcall(FeedObject, obj, huiRootCache)
    if ok and n and n > 0 then MarkDirtyUI() end
end

HookObject = DoHookObject
UnhookObject = DoUnhookObject
RefreshOneObject = DoRefreshOneObject

local IncrementalAttached = false
local function AttachIncremental()
    if IncrementalAttached then return end
    IncrementalAttached = true
    local function onAdded(inst)
        if IsTextObject(inst) then
            task.defer(function() pcall(RefreshOneObject, inst) end)
        end
    end
    local function onRemoving(inst)
        if IsTextObject(inst) then
            pcall(UnhookObject, inst)
            MarkDirtyUI()
        end
    end
    local roots = {PlayerGui, CoreGui, Workspace}
    for i = 1, #roots do
        local r = roots[i]
        pcall(function()
            r.DescendantAdded:Connect(onAdded)
            r.DescendantRemoving:Connect(onRemoving)
        end)
    end
end

-- ==================== UI 创建 ====================
local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(obj, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r or 8)}, obj)
end

local function Stroke(obj, color, t, tr)
    return New("UIStroke", {Color = color or Color3.fromRGB(70, 78, 96), Thickness = t or 1, Transparency = tr or 0.35}, obj)
end

local Theme = {
    -- 主面板：上下渐变，不再是死板的一块纯色
    Panel      = Color3.fromRGB(18, 21, 30),
    PanelTop   = Color3.fromRGB(27, 31, 45),
    PanelBot   = Color3.fromRGB(13, 15, 23),
    Panel2     = Color3.fromRGB(24, 28, 39),
    Card       = Color3.fromRGB(31, 36, 50),
    Card2      = Color3.fromRGB(38, 44, 60),
    Text       = Color3.fromRGB(236, 240, 250),
    Muted      = Color3.fromRGB(148, 158, 182),
    Stroke     = Color3.fromRGB(62, 71, 95),
    Accent     = Color3.fromRGB(96, 140, 255),
    AccentDark = Color3.fromRGB(52, 82, 170),
    AccentGlow = Color3.fromRGB(150, 190, 255),
    Green      = Color3.fromRGB(74, 160, 118),
    Red        = Color3.fromRGB(198, 82, 92),
    Purple     = Color3.fromRGB(128, 102, 190),
    Yellow     = Color3.fromRGB(180, 142, 68),
    Cyan       = Color3.fromRGB(78, 158, 178),
    -- 标题高光条用的渐变两端
    HeaderA    = Color3.fromRGB(58, 96, 190),
    HeaderB    = Color3.fromRGB(120, 165, 255),
}

-- 通用动画辅助函数：轻量、单实例Tween，低配设备也能流畅运行
-- 支持可选的回调（动画完成后执行）
-- 渐变（纯装饰）：给面板/高光条用，让界面不再是纯色块
local function Gradient(obj, c1, c2, rot, transparency)
    return New("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rot or 0,
        Transparency = transparency or NumberSequence.new(0),
    }, obj)
end

local function Tween(obj, props, duration, style, dir, callback)
    local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    if callback then
        tw.Completed:Connect(callback)
    end
    tw:Play()
    return tw
end

local BtnBase = {}   -- [按钮] = 静止时的底色（悬停/按下动效要基于它来提亮压暗）

local function TintColor(c, k)
    return Color3.new(
        math.clamp(c.R * k, 0, 1),
        math.clamp(c.G * k, 0, 1),
        math.clamp(c.B * k, 0, 1))
end

local function StyleButton(btn, color)
    local base = color or Theme.Card
    btn.BackgroundColor3 = base
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false   -- 改成自制动效：悬停提亮、按下压暗，比默认的灰蒙蒙明显
    -- 反复调用（例如工具按钮切换状态）时不要重复添加装饰实例
    if not btn:FindFirstChildOfClass("UICorner") then Corner(btn, 8) end
    if not btn:FindFirstChildOfClass("UIStroke") then Stroke(btn, Theme.Stroke, 1, 0.55) end
    BtnBase[btn] = base
    if btn:GetAttribute("UIStyled") then return end
    btn:SetAttribute("UIStyled", true)
    btn.MouseEnter:Connect(function()
        local b = BtnBase[btn]
        if b then Tween(btn, {BackgroundColor3 = TintColor(b, 1.26)}, 0.12) end
    end)
    btn.MouseLeave:Connect(function()
        local b = BtnBase[btn]
        if b then Tween(btn, {BackgroundColor3 = b}, 0.18) end
    end)
    btn.MouseButton1Down:Connect(function()
        local b = BtnBase[btn]
        if b then Tween(btn, {BackgroundColor3 = TintColor(b, 0.76)}, 0.07) end
    end)
    btn.MouseButton1Up:Connect(function()
        local b = BtnBase[btn]
        if b then Tween(btn, {BackgroundColor3 = TintColor(b, 1.26)}, 0.10) end
    end)
end

local Main = New("Frame", {
    Size = UDim2.new(0, 540, 0, 370), -- 默认给得紧凑些；拖动右下角↘手柄可以自由调整
    Position = UDim2.new(0.5, -270, 0.5, -185),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
}, ScreenGui)
Corner(Main, 18)
Stroke(Main, Theme.Stroke, 1, 0.36)
Gradient(Main, Theme.PanelTop, Theme.PanelBot, 90)   -- 整块面板从上到下的柔和渐变

local TitleAccent = New("Frame", {
    Name = "TitleAccent",
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 2,
}, Main)
Corner(TitleAccent, 2)
Gradient(TitleAccent, Theme.HeaderA, Theme.HeaderB, 0)

local Title = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "UI 文本提取器 v25",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 17
}, Main)

local MinBtn = New("TextButton", {
    Text = "-",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Card2,
    TextSize = 18
}, Main)
StyleButton(MinBtn, Theme.Card2)

local CloseBtn = New("TextButton", {
    Text = "X",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Red,
    TextSize = 16
}, Main)
StyleButton(CloseBtn, Theme.Red)

local Content = New("Frame", {BackgroundTransparency = 1}, Main)

local LeftPanel = New("ScrollingFrame", {
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
    ScrollBarImageColor3 = Color3.fromRGB(120, 132, 160),
    ClipsDescendants = true
}, Content)
Corner(LeftPanel, 10)
Stroke(LeftPanel, Theme.Stroke, 1, 0.38)

local StatusLabel = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = "状态：待刷新",
    TextColor3 = Color3.fromRGB(200,200,205),
    Font = Enum.Font.SourceSans,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextSize = 12
}, Content)

local SectionFrame = New("Frame", {
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, LeftPanel)
Corner(SectionFrame, 8)
Stroke(SectionFrame, Theme.Stroke, 1, 0.38)

-- 搜索框：必须放在 Content 而非 LeftPanel（ScrollingFrame），
-- 因为 Roblox 的 ScrollingFrame 内嵌 TextBox 会导致输入捕获冲突，
-- 轻则无法输入，重则整个滚动面板操作失效
local SearchBox = New("TextBox", {
    Text = "",
    PlaceholderText = "搜索当前分区文本...",
    ClearTextOnFocus = false,
    BackgroundColor3 = Theme.Card,
    TextColor3 = Color3.new(1,1,1),
    PlaceholderColor3 = Color3.fromRGB(155,155,160),
    Font = Enum.Font.SourceSans,
    TextSize = 12
}, Content)
Corner(SearchBox, 8)
Stroke(SearchBox, Theme.Stroke, 1, 0.38)

local SearchBtn = New("TextButton", {
    Text = "搜索",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Purple,
    TextSize = 13
}, Content)
StyleButton(SearchBtn, Theme.Purple)

-- ==================== 功能列表（右栏） ====================
-- 和文本列表分家：中间那栏只负责「看文字」，所有功能都放到右边这一栏，
-- 并且按用途分组、每个按钮鼠标停上去都有说明（完整说明在「帮助」里）。
local Tool = {}
Tool.Panel = New("Frame", {
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Content)
Corner(Tool.Panel, 8)
Stroke(Tool.Panel, Theme.Stroke, 1, 0.38)

Tool.Order = {}
Tool.ByKey = {}
Tool.Headers = {}

local function MakeTool(key, text, color)
    local b = New("TextButton", {
        Name = key,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 11,
        BackgroundColor3 = color,
    }, Tool.Panel)
    StyleButton(b, color)
    Tool.Order[#Tool.Order + 1] = b
    Tool.ByKey[key] = b
    return b
end

local function MakeHeader(text)
    local hdr = New("TextLabel", {
        Text = text,
        TextColor3 = Theme.Muted,
        BackgroundTransparency = 1,
        Font = Enum.Font.SourceSansBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Tool.Panel)
    Tool.Headers[#Tool.Headers + 1] = hdr
    return hdr
end

Tool.HeaderExport = MakeHeader("导出")
Tool.Trans  = MakeTool("Trans", "汉化表", Theme.Cyan)
Tool.Json   = MakeTool("Json", "JSON", Theme.Purple)
Tool.Csv    = MakeTool("Csv", "CSV", Theme.Purple)
Tool.Txt    = MakeTool("Txt", "TXT", Theme.Card2)

Tool.HeaderAct = MakeHeader("操作")
Tool.Diff       = MakeTool("Diff", "对比", Theme.Yellow)
Tool.ReplaceBtn = MakeTool("ReplaceBtn", "替换", Theme.Red)

Tool.Replace = New("TextBox", {
    Text = "",
    PlaceholderText = "替换为…",
    ClearTextOnFocus = false,
    BackgroundColor3 = Theme.Card,
    TextColor3 = Color3.new(1, 1, 1),
    PlaceholderColor3 = Theme.Muted,
    Font = Enum.Font.SourceSans,
    TextSize = 12,
}, Tool.Panel)
Corner(Tool.Replace, 8)
Stroke(Tool.Replace, Theme.Stroke, 1, 0.38)

Tool.HeaderView = MakeHeader("视图")
Tool.Hidden = MakeTool("Hidden", "含隐藏:关", Theme.Card2)
Tool.Regex  = MakeTool("Regex", "正则:关", Theme.Card2)
Tool.Sort   = MakeTool("Sort", "排序:默认", Theme.Card2)

Tool.HeaderStore = MakeHeader("存档 · 其它")
Tool.Save = MakeTool("Save", "保存", Theme.Green)
Tool.Load = MakeTool("Load", "读取", Theme.Green)
Tool.Perf = MakeTool("Perf", "性能", Theme.AccentDark)
Tool.Help = MakeTool("Help", "帮助", Theme.Accent)

-- 右栏的分组顺序（LayoutUI 按这个顺序往下排）
Tool.Layout = {
    {header = Tool.HeaderExport, items = {Tool.Trans, Tool.Json, Tool.Csv, Tool.Txt}},
    {header = Tool.HeaderAct,    items = {Tool.Diff, Tool.ReplaceBtn}, after = Tool.Replace},
    {header = Tool.HeaderView,   items = {Tool.Hidden, Tool.Regex, Tool.Sort}},
    {header = Tool.HeaderStore,  items = {Tool.Save, Tool.Load, Tool.Perf, Tool.Help}},
}

-- ==================== 功能说明（新人友好） ====================
-- 每条 = {分组, 键, 显示名, 说明}。鼠标停在对应按钮上就把说明显示到状态栏；
-- 「帮助」按钮会把这张表整份列出来。键和 Tool.ByKey / 下面 _G 的映射对应。
local HELP_ROWS = {
    {"分区", "sec", "分区",
     "切换只看某个容器里的文字（全部 / PlayerGui / Workspace / CoreGui / RobloxGui / PlayerList / 第三方UI）。方括号里的数字是这个分区当前的文本条数。"},
    {"分区", "search", "搜索框",
     "在列表里筛文字。空格＝同时包含几个词；-词＝排除；class:类名 和 path:路径 只匹配对应字段；\"引号\" 可以把带空格的整句包起来。右键搜索框可以切换「区分大小写」。"},
    {"分区", "rowText", "列表里的文字",
     "点一下直接复制这句。鼠标停在上面时，状态栏会显示它来自哪个控件、完整路径，以及有几个控件在用同一句话（行首会标 [×N]）。"},
    {"分区", "rowLocate", "定位",
     "在屏幕上把那句话所在的控件用发光框圈出来，Studio 里还会同时选中它。同一句话对应多个控件时，反复点会在它们之间轮换。"},
    {"分区", "rowFav", "收藏",
     "把这句加进收藏栏。收藏内容会和屏蔽词一起保存，下次执行自动恢复。"},
    {"分区", "rowDel", "删除",
     "从列表里删掉这条。「屏蔽」打开时，删掉的同时会把它拉黑，以后扫描不再收录。"},
    {"分区", "rowCopy", "复制",
     "复制这条文字（和直接点文字效果一样）。"},

    {"常用", "Refresh", "刷新",
     "重新扫描整棵 UI 树，把界面上现有的文字全部重新收集一遍。快捷键 Ctrl+R。"},
    {"常用", "Auto", "自动刷新",
     "开启后定时自动重扫。关掉也没关系：新增控件、改写文字、删除控件都会实时反映到列表里。"},
    {"常用", "CopyAll", "复制显示",
     "把当前列表里的所有文字一次性复制到剪贴板。"},
    {"常用", "Block", "屏蔽",
     "开启后，点某一行的「删除」会把那句文字加入黑名单，以后不再收录。屏蔽词随配置一起保存。"},
    {"常用", "Fav", "收藏栏",
     "打开 / 收起收藏面板。收藏项会和屏蔽词一起保存，下次执行自动读回。"},
    {"常用", "ExportLua", "导出Lua",
     "按原版格式导出当前分区的文字，兼容以前的用法。"},
    {"常用", "Clear", "清空",
     "清空当前分区的列表。屏蔽模式开着时，被清掉的内容会同时加入黑名单。"},

    {"导出", "Trans", "汉化表",
     "导出成 return { [\"原文\"] = \"\", } 的 Lua 表，可以直接贴进汉化模板。快捷键 Ctrl+E。"},
    {"导出", "Json", "JSON",
     "导出带 text / class / path / count 字段的 JSON，方便给别的工具或脚本用。"},
    {"导出", "Csv", "CSV",
     "导出 CSV，带 UTF-8 BOM，Excel 双击打开不会乱码。"},
    {"导出", "Txt", "TXT",
     "导出纯文本，一行一条，最省事。"},

    {"操作", "Diff", "对比",
     "左键＝和上次快照比较，列出【新增】和【消失】的文字；右键＝把当前状态重新记成快照。"},
    {"操作", "ReplaceBtn", "替换",
     "把搜索框里的内容当成查找条件，替换成右边输入框填的内容。改写的是你本机的界面文字，只影响自己。"},
    {"操作", "replaceBox", "替换输入框",
     "要替换成的内容。查找条件用上面的搜索框，搜索开了正则就按正则替换。"},

    {"视图", "Hidden", "含隐藏",
     "是否把 Visible = false（看不见）的控件也算进来。默认只统计看得见的。"},
    {"视图", "Regex", "正则",
     "搜索按正则表达式匹配。左键切换开关，右键切换「区分大小写」。"},
    {"视图", "Sort", "排序",
     "切换排序方式：默认 / 文本↑ / 文本↓ / 长度 / 类名 / 路径。左键下一个，右键上一个。"},

    {"存档 · 其它", "Save", "保存",
     "把收藏和屏蔽词写入本地配置文件，下次执行自动读回。快捷键 Ctrl+S。"},
    {"存档 · 其它", "Load", "读取",
     "从本地配置文件恢复收藏和屏蔽词。"},
    {"存档 · 其它", "Perf", "性能",
     "显示运行数据：扫描耗时、文本对象数、已挂监听数、列表条数、已实例化的行数。"},
    {"存档 · 其它", "Help", "帮助",
     "打开这份功能说明。再点一次或者按 Esc 关闭。"},
}

local TIPS = {}
for _, r in ipairs(HELP_ROWS) do TIPS[r[2]] = {name = r[3], desc = r[4]} end

-- 数 UTF-8 字符个数（中文一个字算一个），用来算说明文字要占几行
local function Utf8Chars(str)
    local n = 0
    for _ in tostring(str):gmatch("[%z\1-\127\194-\244][\128-\191]*") do n = n + 1 end
    return n
end

-- 悬停提示：鼠标停在按钮上就弹出这个功能的说明。
-- 真正实现在后面（要用到 Main 的尺寸），这里先占位，省得提前声明一堆局部变量。
local Tip = {}
Tip.show = function() end
Tip.hide = function() end

local function AttachTip(obj, key)
    local t = TIPS[key]
    if not obj or not t then return end
    pcall(function()
        obj.MouseEnter:Connect(function() Tool.Tip.show(obj, t.name, t.desc) end)
    end)
    pcall(function()
        obj.MouseLeave:Connect(function() Tool.Tip.hide() end)
    end)
end
Tool.Tip = Tip
Tool.AttachTip = AttachTip
-- 列表行里那几个按钮的说明键
Tool.RowTipKeys = {LocateBtn = "rowLocate", FavBtn = "rowFav", DelBtn = "rowDel", CopyBtn = "rowCopy"}

-- 提示浮层本体
Tip.Box = New("Frame", {
    Name = "TipBox",
    BackgroundColor3 = Theme.Panel2,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 60,
    Size = UDim2.new(0, 200, 0, 40),
}, Content)
Corner(Tip.Box, 6)
Stroke(Tip.Box, Theme.Accent, 1, 0.12)

Tip.Label = New("TextLabel", {
    BackgroundTransparency = 1,
    TextColor3 = Theme.Text,
    Font = Enum.Font.SourceSans,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 61,
}, Tip.Box)

-- 帮助面板：把上面那张说明表整份列出来，新人不用挨个悬停也能一次看完
local Help = {}
Help.Panel = New("Frame", {
    Name = "Help.Panel",
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = 0.03,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40,
}, Content)
Corner(Help.Panel, 10)
Stroke(Help.Panel, Theme.Accent, 1, 0.28)

Help.Title = New("TextLabel", {
    Text = "功能说明　（鼠标停在任意按钮上也会弹出提示）",
    BackgroundTransparency = 1,
    TextColor3 = Theme.AccentGlow,
    Font = Enum.Font.SourceSansBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 41,
}, Help.Panel)

Help.Close = New("TextButton", {
    Text = "✕",
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Theme.Red,
    Font = Enum.Font.SourceSansBold,
    TextSize = 13,
    ZIndex = 42,
}, Help.Panel)
Corner(Help.Close, 6)
StyleButton(Help.Close, Theme.Red)

Help.Scroll = New("ScrollingFrame", {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
    ScrollBarImageColor3 = Theme.Muted,
    ClipsDescendants = true,
    ZIndex = 41,
}, Help.Panel)

Help.Items = {}
do
    local lastGroup = nil
    for _, r in ipairs(HELP_ROWS) do
        if r[1] ~= lastGroup then
            lastGroup = r[1]
            local g = New("TextLabel", {
                Text = "· " .. r[1] .. " ·",
                BackgroundTransparency = 1,
                TextColor3 = Theme.Cyan,
                Font = Enum.Font.SourceSansBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 41,
            }, Help.Scroll)
            Help.Items[#Help.Items + 1] = {kind = "group", obj = g}
        end
        local nameObj = New("TextLabel", {
            Text = r[3],
            BackgroundTransparency = 1,
            TextColor3 = Theme.Yellow,
            Font = Enum.Font.SourceSansBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 41,
        }, Help.Scroll)
        local descObj = New("TextLabel", {
            Text = r[4],
            BackgroundTransparency = 1,
            TextColor3 = Theme.Text,
            Font = Enum.Font.SourceSans,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 41,
        }, Help.Scroll)
        Help.Items[#Help.Items + 1] = {kind = "row", name = nameObj, desc = descObj}
    end
end

-- 性能数据（「性能」按钮展示）
St.Perf = {scanMs = 0, total = 0, hooked = 0, roots = 0, at = "尚未扫描"}

local Scroll = New("ScrollingFrame", {
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 8,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
    ScrollBarImageColor3 = Color3.fromRGB(170,170,175),
    ClipsDescendants = true
}, Content)
Corner(Scroll, 8)
Stroke(Scroll, Theme.Stroke, 1, 0.38)

local ListLayout = New("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Scroll)

local BottomBar = New("Frame", {BackgroundTransparency = 1, ClipsDescendants = true}, LeftPanel)

local RefreshBtn = New("TextButton", {Text = "刷新", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.AccentDark, TextSize = 11}, BottomBar)
local AutoCheckBtn = New("TextButton", {Text = "☐ 自动刷新", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Yellow, TextSize = 11}, BottomBar)
local CopyBtn = New("TextButton", {Text = "复制显示", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Green, TextSize = 11}, BottomBar)
local BlockBtn = New("TextButton", {Text = "屏蔽：关", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Purple, TextSize = 11}, BottomBar)
local FavBtn = New("TextButton", {Text = "收藏栏", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.AccentDark, TextSize = 11}, BottomBar)
local ExportBtn = New("TextButton", {Text = "导出Lua", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Cyan, TextSize = 11}, BottomBar)
local ClearBtn = New("TextButton", {Text = "清空", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, BackgroundColor3 = Theme.Red, TextSize = 11}, BottomBar)

for _, b in ipairs({RefreshBtn, AutoCheckBtn, CopyBtn, BlockBtn, FavBtn, ExportBtn, ClearBtn}) do
    StyleButton(b, b.BackgroundColor3)
end

local ResizeHandle = New("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.new(1, -3, 1, -3),
    Text = "↘",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    Font = Enum.Font.SourceSansBold,
    BackgroundColor3 = Theme.Stroke,
    ZIndex = 10
}, Main)
StyleButton(ResizeHandle, Theme.Stroke)

-- ==================== 最小化悬浮圆点 ====================
local MiniCircle = New("TextButton", {
    Name = "MiniCircle",
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(0.5, -27, 0.5, -27),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 0,
    Text = "文本",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.SourceSansBold,
    TextSize = 14,
    AutoButtonColor = true,
    Active = true,
    Draggable = true,
    Visible = false,
    ZIndex = 20,
}, ScreenGui)
Corner(MiniCircle, 27) -- 圆形
Stroke(MiniCircle, Theme.Stroke, 1.5, 0.2)

local SectionButtons = {}
for _, section in ipairs(Sections) do
    local b = New("TextButton", {
        Text = section.." [0]",
        TextColor3 = Color3.fromRGB(225,225,230),
        Font = Enum.Font.SourceSansBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.Card2,
        TextSize = 11
    }, SectionFrame)
    Corner(b, 6)
    Stroke(b, Theme.Stroke, 1, 0.45)
    SectionButtons[section] = b
end

-- ==================== 收藏栏 ====================
local FavoriteMain, FavoriteScroll, FavoriteListLayout, FavoriteStatus

local function RefreshFavoriteList()
    if not FavoriteScroll then return end
    for _, obj in ipairs(FavoriteScroll:GetChildren()) do
        if obj:IsA("Frame") or obj:IsA("TextButton") then obj:Destroy() end
    end
    for i, text in ipairs(FavoriteData.Texts) do
        local row = New("Frame", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            LayoutOrder = i
        }, FavoriteScroll)
        Corner(row, 6)
        Stroke(row, Theme.Stroke, 1, 0.45)

        local label = New("TextButton", {
            Size = UDim2.new(1, -100, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, row)

        local del = New("TextButton", {
            Size = UDim2.new(0, 42, 0, 24),
            Position = UDim2.new(1, -88, 0.5, -12),
            Text = "删除",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font = Enum.Font.SourceSansBold,
            BackgroundColor3 = Theme.Red
        }, row)

        local copy = New("TextButton", {
            Size = UDim2.new(0, 42, 0, 24),
            Position = UDim2.new(1, -44, 0.5, -12),
            Text = "复制",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font = Enum.Font.SourceSansBold,
            BackgroundColor3 = Theme.Green
        }, row)

        StyleButton(del, del.BackgroundColor3)
        StyleButton(copy, copy.BackgroundColor3)

        label.MouseButton1Click:Connect(function() 
            if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
        end)
        copy.MouseButton1Click:Connect(function() 
            if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
        end)
        del.MouseButton1Click:Connect(function()
            FavoriteData.Map[text] = nil
            for n = #FavoriteData.Texts, 1, -1 do 
                if FavoriteData.Texts[n] == text then table.remove(FavoriteData.Texts, n); break end 
            end
            RefreshFavoriteList()
            if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        end)
    end

    if #FavoriteData.Texts == 0 then
        local empty = New("TextButton", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            Text = "  收藏列表为空",
            TextColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left
        }, FavoriteScroll)
        Corner(empty, 6)
        Stroke(empty, Theme.Stroke, 1, 0.45)
    end

    task.defer(function()
        task.wait()
        if FavoriteScroll and FavoriteListLayout then
            FavoriteScroll.CanvasSize = UDim2.new(0, 0, 0, FavoriteListLayout.AbsoluteContentSize.Y + 10)
        end
    end)
end

local function CreateFavoriteUI()
    if FavoriteMain and FavoriteMain.Parent then
        FavoriteMain.Visible = true
        RefreshFavoriteList()
        if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
        return
    end

    FavoriteMain = New("Frame", {
        Size = UDim2.new(0, 380, 0, 310),
        Position = UDim2.new(0.5, -190, 0.5, -155),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true
    }, ScreenGui)
    Corner(FavoriteMain, 12)
    Stroke(FavoriteMain, Theme.Stroke, 1, 0.2)

    New("TextLabel", {
        Size = UDim2.new(1, -42, 0, 32),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "收藏列表",
        TextColor3 = Color3.new(1,1,1),
        TextSize = 16,
        Font = Enum.Font.SourceSansBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, FavoriteMain)

    local close = New("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -32, 0, 0),
        BackgroundColor3 = Theme.Red,
        Text = "X",
        TextColor3 = Color3.new(1,1,1),
        TextSize = 14,
        Font = Enum.Font.SourceSansBold
    }, FavoriteMain)
    StyleButton(close, close.BackgroundColor3)

    FavoriteStatus = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 34),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200,200,205),
        TextSize = 12,
        Font = Enum.Font.SourceSans,
        TextXAlignment = Enum.TextXAlignment.Left
    }, FavoriteMain)

    FavoriteScroll = New("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -105),
        Position = UDim2.new(0, 10, 0, 58),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 8,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always
    }, FavoriteMain)
    Corner(FavoriteScroll, 8)
    Stroke(FavoriteScroll, Theme.Stroke, 1, 0.38)

    FavoriteListLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, FavoriteScroll)

    local bottom = New("Frame", {
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.new(0, 10, 1, -40),
        BackgroundTransparency = 1
    }, FavoriteMain)

    local copyAll = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "复制显示",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Green
    }, bottom)

    local exportLua = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0.333, 4, 0, 0),
        Text = "导出Lua",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Cyan
    }, bottom)

    local clearAll = New("TextButton", {
        Size = UDim2.new(0.333, -4, 1, 0),
        Position = UDim2.new(0.666, 8, 0, 0),
        Text = "清空全部",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SourceSansBold,
        TextSize = 13,
        BackgroundColor3 = Theme.Red
    }, bottom)

    StyleButton(copyAll, copyAll.BackgroundColor3)
    StyleButton(exportLua, exportLua.BackgroundColor3)
    StyleButton(clearAll, clearAll.BackgroundColor3)

    close.MouseButton1Click:Connect(function() FavoriteMain.Visible = false end)
    copyAll.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(table.concat(FavoriteData.Texts, "\n"))
        elseif toclipboard then toclipboard(table.concat(FavoriteData.Texts, "\n")) end
    end)
    exportLua.MouseButton1Click:Connect(function()
        -- 简单导出
        local lines = {"-- UI文本导出 (收藏列表)", "return {"}
        for _, t in ipairs(FavoriteData.Texts) do
            table.insert(lines, '    "'..EscapeLuaString(t)..'",')
        end
        table.insert(lines, "}")
        local luaText = table.concat(lines, "\n")
        if setclipboard then setclipboard(luaText) elseif toclipboard then toclipboard(luaText) end
        if writefile then
            local ok, err = pcall(function() writefile("UITextExport_收藏.lua", luaText) end)
            if not ok then print("writefile 失败:", err) end
        end
    end)
    clearAll.MouseButton1Click:Connect(function()
        FavoriteData.Texts = {}
        FavoriteData.Map = {}
        RefreshFavoriteList()
        if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 0 条" end
    end)

    FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条"
    RefreshFavoriteList()
end

local function AddFavorite(text)
    text = CleanText(text)
    if text == "" then return end
    if not FavoriteData.Map[text] then
        FavoriteData.Map[text] = true
        table.insert(FavoriteData.Texts, text)
    end
    CreateFavoriteUI()
    RefreshFavoriteList()
    if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 "..#FavoriteData.Texts.." 条" end
end

-- ==================== 显示相关 ====================
local DisplayedLines = {}
local DisplayedRows = {}
local CurrentUpdateToken = 0
local Win = {}
Win.Total = 0        -- 当前分区总条数（虚拟化下 != 已实例化的行数）

-- 虚拟化状态：只保留「视口 + 上下缓冲」这么多行实例，滚动时复用
Win.Pad = 4           -- 行间距（替代原本由 UIListLayout 提供的 Padding）
Win.Buf = 8
Win.Rows = {}
Win.First, Win.Count = -1, -1
Win.Line, Win.Meta, Win.Index = {}, {}, {}
local RenderWindow              -- 前置声明（定义在下面的虚拟化渲染里）
local UpdateStatus              -- 前置声明（定义在 SetDisplay 之后）

local function ClearScroll()
    for _, obj in ipairs(Scroll:GetChildren()) do
        if obj:IsA("UIListLayout") then
            -- 保留布局对象
        elseif obj:IsA("Frame") then
            obj.Visible = false
            obj.Parent = nil
            if #RowPool < MAX_POOL_SIZE then
                table.insert(RowPool, obj)
            else
                obj:Destroy()
            end
        else
            -- 空提示（TextButton）等非 Frame 子元素直接销毁，避免无限累积
            obj:Destroy()
        end
    end
    DisplayedRows = {}
    DisplayedLines = {}
    Win.Total = 0
    Win.Rows = {}
    Win.First, Win.Count = -1, -1
end

local function ResizeCanvas()
    task.defer(function()
        task.wait()
        if not Scroll then return end
        if RenderWindow then
            -- 虚拟化：画布高度由渲染函数按「总条数 × 行距」算，不再依赖 UIListLayout
            RenderWindow(true)
        elseif ListLayout then
            Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
        end
    end)
end

local function ScrollBottom()
    if not AutoScrollToBottom then return end
    task.defer(function()
        task.wait()
        if Scroll then
            local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
            Scroll.CanvasPosition = Vector2.new(0, maxY)
        end
    end)
end

local function GetCurrentText()
    Rebuild(CurrentSection)
    return SectionData[CurrentSection] and SectionData[CurrentSection].AllText or "未检测到 UI 文本"
end

-- 显示层直接使用数据条目（行数组），避免含换行的文本被拆散后无法匹配删除/复制
local function GetCurrentLines()
    local data = SectionData[CurrentSection]
    return data and data.Texts or {}
end

-- ==================== 行尺寸计算（响应式：UI越大越宽松，越小越紧凑） ====================
-- 行内动作按钮：定位 / 收藏 / 删除 / 复制
local ROW_ACTIONS = 4

local function ComputeRowMetrics()
    local s = CurrentUIScale or 1
    local rowH = math.floor(math.clamp(38 * s, 30, 56))
    local actionW = math.floor(math.clamp(26 * s, 22, 44))
    local actionH = math.floor(math.clamp(23 * s, 18, 32))
    local rightPad = math.floor(math.clamp(7 * s, 5, 12))
    local gap = math.floor(math.clamp(4 * s, 3, 8))
    local labelTextSize = math.floor(math.clamp(12.5 * s, 10, 17))
    local actionTextSize = math.floor(math.clamp(11 * s, 9, 14))
    local compact = actionW <= 36
    -- 从右到左：rightPad | 复制 | gap | 删除 | gap | 收藏 | gap | 定位 | gap(与标签的间隔)
    local actionsWidth = rightPad + actionW * ROW_ACTIONS + gap * (ROW_ACTIONS - 1) + gap
    return {
        rowH = rowH, actionW = actionW, actionH = actionH, rightPad = rightPad, gap = gap,
        labelTextSize = labelTextSize, actionTextSize = actionTextSize,
        actionsWidth = actionsWidth, compact = compact,
    }
end

-- slot: 0 = 最靠右。原版复制按钮错位就是因为公式少减了一个按钮宽度
local function PlaceAction(btn, m, slot)
    if not btn then return end
    btn.Size = UDim2.new(0, m.actionW, 0, m.actionH)
    btn.Position = UDim2.new(1, -(m.rightPad + m.actionW * (slot + 1) + m.gap * slot), 0.5, -m.actionH / 2)
    btn.TextSize = m.actionTextSize
end

local function MakeAction(row, name, slot, color, m, full, short)
    local btn = New("TextButton", {
        Name = name,
        Size = UDim2.new(0, m.actionW, 0, m.actionH),
        Position = UDim2.new(1, -(m.rightPad + m.actionW * (slot + 1) + m.gap * slot), 0.5, -m.actionH / 2),
        Text = m.compact and short or full,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = m.actionTextSize,
        Font = Enum.Font.SourceSansBold,
        BackgroundColor3 = color,
    }, row)
    StyleButton(btn, color)
    AttachTip(btn, Tool.RowTipKeys[name])
    return btn
end

-- 把一个已存在的行排到新尺寸上（只改属性、不重建实例，拖动手柄时实时生效）
local function ApplyRowMetrics(row, m)
    if not row or not row.Parent then return end
    row.Size = UDim2.new(1, -12, 0, m.rowH)
    local label = row:FindFirstChild("Label")
    local locate = row:FindFirstChild("LocateBtn")
    local fav = row:FindFirstChild("FavBtn")
    local del = row:FindFirstChild("DelBtn")
    local copy = row:FindFirstChild("CopyBtn")
    if label then
        label.Size = UDim2.new(1, -m.actionsWidth, 1, 0)
        label.TextSize = m.labelTextSize
    end
    PlaceAction(copy, m, 0)
    PlaceAction(del, m, 1)
    PlaceAction(fav, m, 2)
    PlaceAction(locate, m, 3)
    if copy then copy.Text = m.compact and "复" or "复制" end
    if del then del.Text = m.compact and "删" or "删除" end
    if fav then fav.Text = m.compact and "藏" or "收藏" end
    if locate then locate.Text = m.compact and "位" or "定位" end
end

-- 拖动手柄/窗口尺寸变化时调用：只更新已显示行的属性，不重建任何实例
local function RestyleVisibleRows()
    local m = ComputeRowMetrics()
    for i = 1, #DisplayedRows do
        ApplyRowMetrics(DisplayedRows[i], m)
    end
end

-- ==================== 定位到原对象 ====================
-- Highlight 对 GUI 无效（它只作用于 3D 的 BasePart/Model），所以这里：
--   1) Studio 里顺手 Selection:Set 选中它
--   2) 在屏幕上把该对象的绝对矩形用一层发光描边框出来（对任何 GuiObject 都有效）
--   3) 同一个文本对应多个对象时，反复点「定位」会在它们之间轮换
local LocateCursor = {}

local function FlashObjectBounds(obj)
    local ok = pcall(function()
        local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
        -- 连点「定位」时先把上一个框收掉，避免残留
        local old = ScreenGui:FindFirstChild("UITextLocateBox")
        if old then pcall(function() old:Destroy() end) end

        local box = New("Frame", {
            Name = "UITextLocateBox",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 5000,
            Size = UDim2.new(0, math.max(2, size.X), 0, math.max(2, size.Y)),
            Position = UDim2.new(0, pos.X, 0, pos.Y),
        }, ScreenGui)

        -- 清理必须紧跟着创建就登记：后面任何装饰出错也不会把框永久留在屏幕上
        task.delay(1.4, function()
            pcall(function()
                Tween(box, {BackgroundTransparency = 1}, 0.25)
                task.wait(0.26)
                if box then box:Destroy() end
            end)
        end)

        Corner(box, 4)
        Stroke(box, Color3.fromRGB(120, 190, 255), 2, 0)   -- 注意：UIStroke 没有 ZIndex 属性
        local tag = New("TextLabel", {
            BackgroundTransparency = 0.15,
            BackgroundColor3 = Color3.fromRGB(40, 90, 160),
            Text = obj.ClassName,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.SourceSansBold,
            ZIndex = 5001,
            Size = UDim2.new(0, 84, 0, 15),
            Position = UDim2.new(0, 0, 0, -16),
        }, box)
        Corner(tag, 3)
    end)
    return ok
end

local function LocateText(text)
    local data = SectionData[CurrentSection]
    local info = data and data.Info[text]
    if not info then
        StatusLabel.Text = "来源：已不在当前分区（可能已被清空或屏蔽）"
        return false
    end
    local list, n = {}, 0
    for obj in pairs(info.objs) do
        if obj and obj.Parent then n = n + 1; list[n] = obj end
    end
    if n == 0 then
        if info.obj and info.obj.Parent then list, n = {info.obj}, 1
        else
            StatusLabel.Text = "来源：原对象已被销毁"
            return false
        end
    end
    local idx = ((LocateCursor[text] or 0) % n) + 1
    LocateCursor[text] = idx
    local obj = list[idx]
    pcall(function()
        local sel = game:GetService("Selection")
        if sel then sel:Set({obj}) end
    end)
    FlashObjectBounds(obj)
    local same = info.count > 1 and ("　同文本 " .. info.count .. " 处（第 " .. idx .. "/" .. n .. "）") or ""
    StatusLabel.Text = "定位：" .. (info.cls ~= "" and info.cls or "?") .. " › " ..
        (info.path ~= "" and info.path or "?") .. same
    return true
end

-- ==================== 虚拟化列表 ====================
-- 原版给每一条文本都建一个 Frame：1000 条 = 1000 个实例（对象池上限只有 400，超了就开始
-- 反复 Instance.new / Destroy）。现在改成：只保留「视口 + 上下缓冲」这么多行实例，
-- 滚动时复用它们重新绑定数据，实例数恒定在几十个。
local function RowPitch()
    return ComputeRowMetrics().rowH + Win.Pad
end

local function RowDisplayText(row, line)
    local info = Win.Meta[row]
    local t = line
    if info and info.count and info.count > 1 then
        t = "[×" .. info.count .. "] " .. t
    end
    t = string.gsub(t, "\n", " ⏎ ")
    if #t > 500 then t = string.sub(t, 1, 500) .. "..." end
    return t
end

local function BindRow(row, line, index, m)
    Win.Line[row] = line
    Win.Index[row] = index
    local data = SectionData[CurrentSection]
    Win.Meta[row] = (data and data.Info[line]) or {path = "", cls = "", count = 0}
    local label = row:FindFirstChild("Label")
    if label then label.Text = RowDisplayText(row, line) end
    ApplyRowMetrics(row, m)
end

local function CreateRowShell(m)
    local row = New("Frame", {
        Size = UDim2.new(1, -12, 0, m.rowH),
        BackgroundColor3 = Theme.Card2,
        BorderSizePixel = 0,
    }, Scroll)
    Corner(row, 7)
    Stroke(row, Theme.Stroke, 1, 0.50)

    local label = New("TextButton", {
        Name = "Label",
        Size = UDim2.new(1, -m.actionsWidth, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = m.labelTextSize,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
    }, row)
    AttachTip(label, "rowText")

    local locate = MakeAction(row, "LocateBtn", 3, Theme.Accent, m, "定位", "位")
    local fav = MakeAction(row, "FavBtn", 2, Theme.AccentDark, m, "收藏", "藏")
    local del = MakeAction(row, "DelBtn", 1, Theme.Red, m, "删除", "删")
    local copy = MakeAction(row, "CopyBtn", 0, Theme.Green, m, "复制", "复")

    -- 悬停显示来源（类名 + 完整路径 + 同文本出现次数）
    label.MouseEnter:Connect(function()
        local info = Win.Meta[row]
        if not info then return end
        local same = (info.count and info.count > 1) and ("　同文本 " .. info.count .. " 处") or ""
        StatusLabel.Text = "来源：" .. (info.cls ~= "" and info.cls or "?") .. " › " ..
            (info.path ~= "" and info.path or "?") .. same
    end)
    label.MouseLeave:Connect(function()
        if UpdateStatus then UpdateStatus() end
    end)

    label.MouseButton1Click:Connect(function()
        local line = Win.Line[row]
        if not line then return end
        if setclipboard then setclipboard(line) elseif toclipboard then toclipboard(line) end
        StatusLabel.Text = "已复制：" .. string.sub(line, 1, 60)
    end)
    copy.MouseButton1Click:Connect(function()
        local line = Win.Line[row]
        if not line then return end
        if setclipboard then setclipboard(line) elseif toclipboard then toclipboard(line) end
        StatusLabel.Text = "已复制：" .. string.sub(line, 1, 60)
    end)
    locate.MouseButton1Click:Connect(function()
        local line = Win.Line[row]
        if line then LocateText(line) end
    end)
    fav.MouseButton1Click:Connect(function()
        local line = Win.Line[row]
        if line then AddFavorite(line) end
    end)
    del.MouseButton1Click:Connect(function()
        local line = Win.Line[row]
        if not line then return end
        local oldPos = Scroll.CanvasPosition
        if BlockMode then
            if CurrentSection == "全部" then
                for _, sec in ipairs(Sections) do BlockedData[sec][line] = true end
            else
                BlockedData[CurrentSection][line] = true
                BlockedData["全部"][line] = true
            end
        end
        if CurrentSection == "全部" then
            for _, sec in ipairs(Sections) do RemoveText(sec, line) end
        else
            RemoveText(CurrentSection, line)
            RebuildAll()
        end
        SetDisplay(GetCurrentLines(), false)
        task.defer(function()
            task.wait()
            if Scroll then
                local maxY = math.max(0, Scroll.CanvasSize.Y.Offset - Scroll.AbsoluteSize.Y)
                Scroll.CanvasPosition = Vector2.new(0, math.clamp(oldPos.Y, 0, maxY))
            end
        end)
        UpdateSectionButtons()
    end)

    return row
end

-- 把窗口挪到并绑定 [first, first+count-1] 这些行；复用已有实例，不重复创建
local function RenderWindow(force)
    if not Scroll then return end
    local m = ComputeRowMetrics()
    local pitch = m.rowH + Win.Pad
    local total = #DisplayedLines
    if total == 0 then
        -- 留一点画布高度，空状态提示「未检测到 UI 文本」才不会被裁掉
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 44)
        return
    end
    local viewH = Scroll.AbsoluteSize.Y
    if viewH <= 0 then viewH = 320 end
    local span = math.ceil(viewH / pitch) + Win.Buf * 2 + 2
    local first = math.floor(Scroll.CanvasPosition.Y / pitch) - Win.Buf
    -- 关键：first 必须夹在 [1, total-span+1] 内。滚到底（CanvasPosition 超出内容）时
    -- first 会算到 total 之外，count 变成负数，下面清理行的循环就会一直减到 0，
    -- table.remove(t, 0) 直接抛 "position out of bounds"，并且把 Win.Rows 留在半损坏状态。
    local maxFirst = total - span + 1
    if maxFirst < 1 then maxFirst = 1 end
    if first > maxFirst then first = maxFirst end
    if first < 1 then first = 1 end
    local last = first + span - 1
    if last > total then last = total end
    local count = last - first + 1
    if count < 1 then count = 1 end

    if not force and first == Win.First and count == Win.Count then
        return
    end
    Win.First, Win.Count = first, count

    while #Win.Rows < count do
        local row = table.remove(RowPool)
        if row then
            row.Visible = true
            row.Parent = Scroll
        else
            row = CreateRowShell(m)
        end
        Win.Rows[#Win.Rows + 1] = row
    end
    -- 复用不用的行：始终从尾部拿，避免依赖 table.remove 的下标校验
    while #Win.Rows > count do
        local row = Win.Rows[#Win.Rows]
        Win.Rows[#Win.Rows] = nil
        if row then
            row.Visible = false
            row.Parent = nil
            if #RowPool < MAX_POOL_SIZE then
                table.insert(RowPool, row)
            else
                row:Destroy()
            end
        end
    end

    DisplayedRows = Win.Rows
    for k = 1, count do
        local idx = first + k - 1
        local row = Win.Rows[k]
        row.Position = UDim2.new(0, 6, 0, (idx - 1) * pitch)
        row.LayoutOrder = idx
        BindRow(row, DisplayedLines[idx], idx, m)
    end
    Scroll.CanvasSize = UDim2.new(0, 0, 0, total * pitch + 8)
end

local function CreateDisplayRow(line, index)
    local m = ComputeRowMetrics()
    local row = table.remove(RowPool)
    if row then
        row.Visible = true
        row.Parent = Scroll
    else
        row = CreateRowShell(m)
    end
    BindRow(row, line, index, m)
    return row
end

-- 虚拟化用绝对定位摆放行，必须让 UIListLayout 让位（它是 LayoutOrder 排序，会覆盖 Position）。
-- 注意：UIListLayout 没有 Enabled 属性（官方文档只有 Padding/SortOrder/FillDirection/Wraps/Flex 等），
-- 关掉它的唯一办法是把它从父级摘掉。
if ListLayout then
    pcall(function() ListLayout.Parent = nil end)
end

-- 滚动时把窗口挪过去（复用实例，不新建）
if Scroll then
    pcall(function()
        Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            RenderWindow(false)
        end)
    end)
end

local function PrepareLines(text)
    local lines = {}
    if type(text) == "table" then
        for _, line in ipairs(text) do
            line = CleanText(line)
            if line ~= "" then table.insert(lines, line) end
        end
    else
        for line in string.gmatch(tostring(text or "") .. "\n", "(.-)\n") do
            line = CleanText(line)
            if line ~= "" then table.insert(lines, line) end
        end
    end
    return lines
end

-- ==================== SetDisplay ====================
-- 原版要分批 task.wait() 建行 + 用 token 取消后台渲染协程；虚拟化之后渲染只涉及
-- 几十个实例、完全同步，所以整段 token 竞态逻辑都不需要了
SetDisplay = function(text, autoBottom, animate, forceRebuild)
    local newLines = PrepareLines(text)
    CurrentDisplayText = table.concat(newLines, "\n")
    CurrentUpdateToken = CurrentUpdateToken + 1

    if #newLines == 0 then
        ClearScroll()
        New("TextButton", {
            Size = UDim2.new(1, -12, 0, 34),
            BackgroundColor3 = Theme.Card2,
            BorderSizePixel = 0,
            Text = "  未检测到 UI 文本",
            TextColor3 = Theme.Muted,
            TextSize = 13,
            Font = Enum.Font.SourceSans,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
        }, Scroll)
        task.defer(function()
            task.wait()
            if Scroll then Scroll.CanvasSize = UDim2.new(0, 0, 0, 44) end
        end)
        return
    end

    -- 内容与当前显示完全一致时（自动刷新最常见的情况）只重排窗口，不重建任何实例
    if not forceRebuild and #newLines == #DisplayedLines then
        local same = true
        for i = 1, #newLines do
            if newLines[i] ~= DisplayedLines[i] then
                same = false
                break
            end
        end
        if same then
            RenderWindow(true)
            if autoBottom then ScrollBottom() end
            return
        end
    end

    DisplayedLines = newLines
    Win.First, Win.Count = -1, -1
    RenderWindow(true)
    if autoBottom then ScrollBottom() end
end

function UpdateStatus(msg)
    local block = BlockMode and "屏蔽开" or "屏蔽关"
    local auto = AutoRefreshEnabled and "自动刷新开" or "自动刷新关"
    if msg and msg ~= "" then
        StatusLabel.Text = "状态："..auto.."｜"..CurrentSection.."｜"..Count(CurrentSection).."条｜"..block.."｜"..msg
    else
        -- 平时省掉「自动刷新」「屏蔽」这两项（按钮上本来就写着），腾出位置给新人提示
        StatusLabel.Text = "状态："..CurrentSection.." "..Count(CurrentSection).."条｜"..block.."　·　鼠标停在按钮上看说明"
    end
end

local function UpdateSectionButtons()
    for name, b in pairs(SectionButtons) do
        local selected = (name == CurrentSection)
        local color = selected and Theme.Accent or Theme.Card2
        b.BackgroundColor3 = color
        BtnBase[b] = color            -- 让悬停动效知道当前静止色
        b.TextColor3 = selected and Color3.new(1, 1, 1) or Theme.Text
        b.Font = selected and Enum.Font.SourceSansBold or Enum.Font.SourceSans
        b.Text = name .. " [" .. Count(name) .. "]"
        -- 选中时左侧一条发光竖条
        local bar = b:FindFirstChild("SelBar")
        if selected then
            if not bar then
                bar = New("Frame", {
                    Name = "SelBar",
                    Size = UDim2.new(0, 3, 1, -8),
                    Position = UDim2.new(0, 3, 0, 4),
                    BackgroundColor3 = Theme.AccentGlow,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                }, b)
                Corner(bar, 2)
            end
            bar.Visible = true
        elseif bar then
            bar.Visible = false
        end
    end
end

-- ==================== 查询：过滤 + 排序 ====================
-- 原版只有纯子串匹配（string.find plain），且完全没有排序。现在支持：
--   关键词        空格分隔多个词 = AND（全部命中才算）
--   -排除词       以 - 开头 = 排除
--   class:xxx     按类名过滤        path:xxx  按路径过滤
--   "带空格的词"   引号包起来
--   正则开关       打开后每个词按 Lua 正则（string.find pattern）匹配
local function ParseQuery(q)
    local terms, i, n = {}, 1, #q
    while i <= n do
        local c = string.sub(q, i, i)
        if c == " " or c == "\t" then
            i = i + 1
        elseif c == "\"" then
            local j = string.find(q, "\"", i + 1, true)
            if not j then j = n + 1 end
            local word = string.sub(q, i + 1, j - 1)
            if word ~= "" then terms[#terms + 1] = {neg = false, kind = "text", value = word} end
            i = j + 1
        else
            local j = string.find(q, "%s", i)
            if not j then j = n + 1 end
            local word = string.sub(q, i, j - 1)
            i = j
            if word ~= "" then
                local neg = false
                if string.sub(word, 1, 1) == "-" and #word > 1 then
                    neg = true
                    word = string.sub(word, 2)
                end
                local kind, value = "text", word
                local pre, rest = string.match(word, "^(%a+):(.*)$")
                if pre == "class" then kind, value = "class", rest
                elseif pre == "path" then kind, value = "path", rest
                end
                terms[#terms + 1] = {neg = neg, kind = kind, value = value}
            end
        end
    end
    return terms
end

local function MatchTerms(line, info, terms)
    for i = 1, #terms do
        local t = terms[i]
        local hay
        if t.kind == "class" then hay = (info and info.cls) or ""
        elseif t.kind == "path" then hay = (info and info.path) or ""
        else hay = line end
        local hit
        if St.Regex then
            local ok, a = pcall(string.find, hay, t.value)
            hit = ok and a ~= nil
        elseif St.Case then
            hit = string.find(hay, t.value, 1, true) ~= nil
        else
            hit = string.find(string.lower(hay), string.lower(t.value), 1, true) ~= nil
        end
        if t.neg then hit = not hit end
        if not hit then return false end
    end
    return true
end

local function SortLabel()
    return St.SortLabels[St.Sort] or "默认"
end

local function SortResult(list, data)
    if St.Sort == "default" or #list < 2 then return list end
    table.sort(list, function(a, b)
        local ia, ib = data.Info[a], data.Info[b]
        if St.Sort == "text" then
            local la, lb = string.lower(a), string.lower(b)
            if la == lb then return a < b end
            return la < lb
        elseif St.Sort == "textdesc" then
            local la, lb = string.lower(a), string.lower(b)
            if la == lb then return a > b end
            return la > lb
        elseif St.Sort == "len" then
            if #a == #b then return a < b end
            return #a < #b
        elseif St.Sort == "cls" then
            local ca, cb = (ia and ia.cls) or "", (ib and ib.cls) or ""
            if ca == cb then return a < b end
            return ca < cb
        elseif St.Sort == "path" then
            local pa, pb = (ia and ia.path) or "", (ib and ib.path) or ""
            if pa == pb then return a < b end
            return pa < pb
        end
        return false
    end)
    return list
end

-- 当前分区 + 当前查询条件 -> 要显示的行（过滤 + 排序都在这里，导出也复用它）
local function QueryLines()
    local data = SectionData[CurrentSection]
    if not data then return {} end
    local q = CleanText(SearchBox.Text)
    local out, n = {}, 0
    if q == "" then
        for i = 1, #data.Texts do n = n + 1; out[n] = data.Texts[i] end
    else
        local terms = ParseQuery(q)
        for i = 1, #data.Texts do
            local line = data.Texts[i]
            if MatchTerms(line, data.Info[line], terms) then
                n = n + 1
                out[n] = line
            end
        end
    end
    return SortResult(out, data)
end

local function SearchNow()
    local q = CleanText(SearchBox.Text)
    LastSearchSection = CurrentSection
    LastSearchKeyword = q
    local result = QueryLines()
    LastSearchResult = result
    if q == "" then
        SetDisplay(result, false, true)
        Scroll.CanvasPosition = Vector2.new(0, 0)
        if St.Sort ~= "default" then
            UpdateStatus("已按「" .. SortLabel() .. "」排序，共 " .. #result .. " 条")
        else
            UpdateStatus("显示全部文本")
        end
        return
    end
    if #result == 0 then
        SetDisplay("没有匹配【" .. q .. "】的文本", false, true, true)
        UpdateStatus("匹配 0 条")
    else
        SetDisplay(result, false, true, true)
        UpdateStatus("匹配 " .. #result .. " 条")
    end
    Scroll.CanvasPosition = Vector2.new(0, 0)
end

local function RefreshDisplay(added)
    UpdateSectionButtons()
    if CleanText(SearchBox.Text) ~= "" or St.Sort ~= "default" then
        SearchNow()
    else
        SetDisplay(GetCurrentLines(), added and added > 0)
        if added and added > 0 then UpdateStatus("新增 " .. added .. " 条") else UpdateStatus("暂无新增") end
    end
end

local function ManualRefresh()
    local added = ScanSection(CurrentSection)
    RefreshDisplay(added)
end

local function ClearCurrent()
    local data = SectionData[CurrentSection]
    if not data then return end
    if BlockMode then
        if CurrentSection == "全部" then
            for _, sec in ipairs(Sections) do
                for _, text in ipairs(SectionData[sec].Texts) do BlockedData[sec][text] = true end
            end
        else
            for _, text in ipairs(data.Texts) do
                BlockedData[CurrentSection][text] = true
                BlockedData["全部"][text] = true
            end
        end
    end
    data.Texts = {}
    data.Map = {}
    data.AllText = "未检测到 UI 文本"
    if CurrentSection == "全部" then
        for _, sec in ipairs(Sections) do
            SectionData[sec].Texts = {}
            SectionData[sec].Map = {}
            SectionData[sec].AllText = "未检测到 UI 文本"
        end
    else
        RebuildAll()
    end
    SearchBox.Text = ""
    SetDisplay(GetCurrentLines(), false)
    Scroll.CanvasPosition = Vector2.new(0,0)
    UpdateSectionButtons()
    UpdateStatus(BlockMode and "已清空并加入屏蔽" or "已清空当前分区")
end

-- ==================== 响应式 LayoutUI（UI越大越宽松，越小越紧凑） ====================
-- 与旧版最大区别：不再是"大屏/小屏"两档切换，而是根据窗口的实际宽高连续计算一个缩放系数 scale，
-- 所有间距、按钮尺寸、字号都乘以这个系数（并做min/max限制防止极端情况下过大或过小到无法使用）。
-- 拖动右下角↘手柄时，Main.AbsoluteSize 变化会实时触发本函数，所以整个UI会跟手缩放。
local function LayoutUI()
    if Minimized or Animating then return end

    local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if w <= 0 then w = 480 end
    if h <= 0 then h = 340 end

    -- 基准尺寸为默认的 480x340，scale=1 时还原成默认版式
    -- 用几何平均：任意方向拖动都会触发整体缩放。原 min 版本只在宽高同时
    -- 同比例变化时才缩放，只拉宽/只拉高时左侧功能区纹丝不动
    local scale = math.clamp(math.sqrt((w / 480) * (h / 340)), 0.72, 1.7)
    CurrentUIScale = scale

    local pad = math.floor(math.clamp(7 * scale, 5, 12))
    local titleH = math.floor(math.clamp(30 * scale, 24, 44))
    local sideW = math.floor(math.clamp(88 * scale, 76, 130))
    local toolW = math.floor(math.clamp(140 * scale, 124, 190))
    local statusH = math.floor(math.clamp(19 * scale, 15, 28))
    local searchH = math.floor(math.clamp(25 * scale, 19, 36))
    local gap = math.floor(math.clamp(5 * scale, 3, 9))
    local actionH = math.floor(math.clamp(23 * scale, 17, 34))
    local sectionH = math.floor(math.clamp(23 * scale, 17, 34))
    local actionCount = 7

    local titleTextSize = math.floor(math.clamp(16 * scale, 12, 22))
    local topBtnSize = math.floor(math.clamp(26 * scale, 20, 38))
    local sectionTextSize = math.floor(math.clamp(11 * scale, 9, 15))
    local searchTextSize = math.floor(math.clamp(12 * scale, 10, 16))
    local searchBtnTextSize = math.floor(math.clamp(12 * scale, 10, 17))
    local actionTextSize = math.floor(math.clamp(11 * scale, 9, 15))
    local statusTextSize = math.floor(math.clamp(11 * scale, 9, 15))
    local helpTextSize = math.floor(math.clamp(11 * scale, 9, 14))

    Title.Size = UDim2.new(1, -math.floor(80*scale), 0, titleH)
    Title.Position = UDim2.new(0, pad, 0, 0)
    Title.TextSize = titleTextSize
    TitleAccent.Size = UDim2.new(1, -pad * 2, 0, 2)
    TitleAccent.Position = UDim2.new(0, pad, 0, titleH - 5)

    MinBtn.Size = UDim2.new(0, topBtnSize, 0, topBtnSize)
    MinBtn.Position = UDim2.new(1, -(topBtnSize*2 + 4), 0, 2)
    MinBtn.TextSize = math.floor(math.clamp(17 * scale, 13, 22))

    CloseBtn.Size = UDim2.new(0, topBtnSize, 0, topBtnSize)
    CloseBtn.Position = UDim2.new(1, -(topBtnSize + 2), 0, 2)
    CloseBtn.TextSize = math.floor(math.clamp(15 * scale, 11, 20))

    Content.Size = UDim2.new(1, 0, 1, -titleH)
    Content.Position = UDim2.new(0, 0, 0, titleH)

    -- ---------- 左栏：分区 + 常用操作 ----------
    LeftPanel.Size = UDim2.new(0, sideW, 1, -pad*2)
    LeftPanel.Position = UDim2.new(0, pad, 0, pad)

    local sectionPanelH = #Sections * sectionH + (#Sections + 1) * gap
    SectionFrame.Size = UDim2.new(1, -pad, 0, sectionPanelH)
    SectionFrame.Position = UDim2.new(0, math.floor(pad/2), 0, gap)

    for i, section in ipairs(Sections) do
        local b = SectionButtons[section]
        b.Size = UDim2.new(1, -pad, 0, sectionH)
        b.Position = UDim2.new(0, math.floor(pad/2), 0, gap + (i-1) * (sectionH + gap))
        b.TextSize = sectionTextSize
    end

    local sideY = gap + sectionPanelH + gap
    local actionPanelH = actionCount * actionH + (actionCount-1) * gap
    BottomBar.Size = UDim2.new(1, -pad, 0, actionPanelH)
    BottomBar.Position = UDim2.new(0, math.floor(pad/2), 0, sideY)

    local leftContentH = sideY + actionPanelH + gap
    LeftPanel.CanvasSize = UDim2.new(0, 0, 0, leftContentH)

    local buttons = {RefreshBtn, AutoCheckBtn, CopyBtn, BlockBtn, FavBtn, ExportBtn, ClearBtn}
    for i, b in ipairs(buttons) do
        b.Size = UDim2.new(1, -pad, 0, actionH)
        b.Position = UDim2.new(0, math.floor(pad/2), 0, (i-1) * (actionH + gap))
        b.TextSize = actionTextSize
    end

    -- ---------- 中栏：状态栏 + 搜索 + 文本列表 ----------
    local listX = pad * 2 + sideW
    local centerW = math.max(150, w - listX - toolW - gap - pad)
    local toolX = listX + centerW + gap

    StatusLabel.Size = UDim2.new(0, centerW, 0, statusH)
    StatusLabel.Position = UDim2.new(0, listX, 0, pad)
    StatusLabel.TextSize = statusTextSize

    local searchRowY = pad + statusH + gap
    local searchBtnW = math.floor(searchH * 1.7)
    SearchBtn.Size = UDim2.new(0, searchBtnW, 0, searchH)
    SearchBtn.Position = UDim2.new(0, listX, 0, searchRowY)
    SearchBtn.TextSize = searchBtnTextSize

    SearchBox.Visible = true
    SearchBox.Size = UDim2.new(0, math.max(60, centerW - searchBtnW - gap), 0, searchH)
    SearchBox.Position = UDim2.new(0, listX + searchBtnW + gap, 0, searchRowY)
    SearchBox.TextSize = searchTextSize

    local scrollY = searchRowY + searchH + gap
    Scroll.Size = UDim2.new(0, centerW, 1, -scrollY - pad)
    Scroll.Position = UDim2.new(0, listX, 0, scrollY)

    -- ---------- 右栏：功能列表 ----------
    -- 按组竖排。按钮高度由「可用高度 / 总行数」反推，所以窗口拉大拉小都不会溢出。
    local toolPad = math.floor(math.clamp(5 * scale, 3, 8))
    local headerH = math.floor(math.clamp(11 * scale, 9, 14))
    local toolGap = math.floor(math.clamp(3 * scale, 2, 5))
    local groupGap = math.floor(math.clamp(6 * scale, 4, 10))
    local toolTop = pad
    local toolH = h - titleH - pad * 2

    local toolCols = 2
    local toolRows = 0
    for _, g in ipairs(Tool.Layout) do
        toolRows = toolRows + math.max(1, math.ceil(#g.items / toolCols))
    end

    local fixedH = #Tool.Layout * (headerH + 2) + (#Tool.Layout - 1) * groupGap
        + (toolRows + 1) * toolGap + toolPad * 2
    local unitH = (toolH - fixedH) / math.max(1, toolRows + 1)
    local toolBtnH = math.floor(math.clamp(unitH - toolGap, 14, 30))
    local replaceH = math.floor(math.clamp(unitH - toolGap, 15, searchH))
    local btnW = (toolW - toolPad * 2 - (toolCols - 1) * toolGap) / toolCols

    Tool.Panel.Size = UDim2.new(0, toolW, 0, toolH)
    Tool.Panel.Position = UDim2.new(0, toolX, 0, toolTop)

    local cy = toolPad
    for gi, g in ipairs(Tool.Layout) do
        g.header.Size = UDim2.new(1, -toolPad * 2, 0, headerH)
        g.header.Position = UDim2.new(0, toolPad, 0, cy)
        g.header.TextSize = math.floor(math.clamp(10 * scale, 8, 13))
        cy = cy + headerH + 2

        local col = 0
        for _, b in ipairs(g.items) do
            b.Size = UDim2.new(0, btnW, 0, toolBtnH)
            b.Position = UDim2.new(0, toolPad + col * (btnW + toolGap), 0, cy)
            b.TextSize = math.floor(math.clamp(10 * scale, 8, 13))
            col = col + 1
            if col >= toolCols then
                col = 0
                cy = cy + toolBtnH + toolGap
            end
        end
        if col > 0 then cy = cy + toolBtnH + toolGap end

        if g.after then
            g.after.Size = UDim2.new(1, -toolPad * 2, 0, replaceH)
            g.after.Position = UDim2.new(0, toolPad, 0, cy)
            g.after.TextSize = math.floor(math.clamp(11 * scale, 9, 14))
            cy = cy + replaceH + toolGap
        end
        if gi < #Tool.Layout then cy = cy + groupGap - toolGap end
    end

    -- ---------- 悬停提示浮层 ----------
    Tip.Label.TextSize = math.floor(math.clamp(11 * scale, 9, 14))

    -- ---------- 帮助面板 ----------
    if Help.Panel.Visible then
        local hp = pad
        local hTitleH = math.floor(math.clamp(20 * scale, 16, 26))
        local closeW = math.floor(math.clamp(20 * scale, 16, 26))
        Help.Panel.Position = UDim2.new(0, pad, 0, pad)
        Help.Panel.Size = UDim2.new(1, -pad * 2, 1, -pad * 2)
        local helpW = w - pad * 2
        Help.Title.Size = UDim2.new(1, -(hp * 2 + closeW + gap), 0, hTitleH)
        Help.Title.Position = UDim2.new(0, hp, 0, hp)
        Help.Title.TextSize = helpTextSize
        Help.Close.Size = UDim2.new(0, closeW, 0, closeW)
        Help.Close.Position = UDim2.new(1, -(closeW + hp), 0, hp)
        Help.Close.TextSize = helpTextSize

        local hScrollTop = hp + hTitleH + gap
        Help.Scroll.Position = UDim2.new(0, hp, 0, hScrollTop)
        Help.Scroll.Size = UDim2.new(1, -hp * 2, 1, -(hScrollTop + hp))

        local nameW = math.floor(math.clamp(64 * scale, 52, 92))
        local descX = hp + nameW + gap
        local descW = math.max(80, helpW - descX - hp - gap)
        local charsPerLine = math.max(8, math.floor(descW / (helpTextSize * 0.62)))
        local lineH = helpTextSize + 3
        local hy = 0
        for _, item in ipairs(Help.Items) do
            if item.kind == "group" then
                hy = hy + gap
                item.obj.Size = UDim2.new(1, -hp * 2, 0, lineH)
                item.obj.Position = UDim2.new(0, hp, 0, hy)
                item.obj.TextSize = helpTextSize
                hy = hy + lineH
            else
                local lines = math.max(1, math.ceil(Utf8Chars(item.desc.Text) / charsPerLine))
                local rowH = lines * lineH
                item.name.Size = UDim2.new(0, nameW, 0, lineH)
                item.name.Position = UDim2.new(0, hp, 0, hy)
                item.name.TextSize = helpTextSize
                item.desc.Size = UDim2.new(0, descW, 0, rowH)
                item.desc.Position = UDim2.new(0, descX, 0, hy)
                item.desc.TextSize = helpTextSize
                hy = hy + rowH + 2
            end
        end
        Help.Scroll.CanvasSize = UDim2.new(0, 0, 0, hy + hp)
    end

    ResizeHandle.Visible = true
    ResizeCanvas()

    -- 同步已经显示在列表里的行（复制/删除/添加按钮 + 文本行高）到新的缩放比例，
    -- 只更新属性、不重建实例，所以拖动手柄的过程中也很流畅
    RestyleVisibleRows()
end

-- ==================== 导出与工具函数 ====================
local function SafeFileName(s)
    local t = tostring(s or "全部"):gsub("[\\/:*?\"<>|]", "_")
    if t == "" then t = "全部" end
    return t
end

local function WriteOut(name, text)
    if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
    if writefile then
        local ok, err = pcall(function() writefile(name, text) end)
        if ok then
            StatusLabel.Text = "已导出并复制：" .. name .. "（" .. #text .. " 字节）"
        else
            StatusLabel.Text = "已复制到剪贴板，但 writefile 失败：" .. tostring(err)
        end
    else
        StatusLabel.Text = "已复制到剪贴板（当前执行器无 writefile）：" .. name
    end
end

local function ItemsOfLines(lines)
    local data = SectionData[CurrentSection]
    local items = {}
    for i = 1, #lines do
        local info = data and data.Info[lines[i]]
        items[i] = {
            text = lines[i],
            cls = (info and info.cls) or "",
            path = (info and info.path) or "",
            count = (info and info.count) or 1,
        }
    end
    return items
end

-- 汉化表：直接就是「原文 -> 译文」的空表，能贴进汉化模板
local function ExportTranslations()
    local lines = QueryLines()
    if #lines == 0 then StatusLabel.Text = "没有可导出的文本"; return end
    local out = {
        "-- UI文本汉化表（原文 -> 译文）",
        "-- 分区：" .. CurrentSection .. "　共 " .. #lines .. " 条",
        "-- 生成时间：" .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        "return {",
    }
    for i = 1, #lines do
        out[#out + 1] = "    [\"" .. EscapeLuaString(lines[i]) .. "\"] = \"\","
    end
    out[#out + 1] = "}"
    WriteOut("UITextExport_" .. SafeFileName(CurrentSection) .. "_汉化.lua", table.concat(out, "\n"))
end

local function JsonEscape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    s = s:gsub("[%z\1-\31]", function(c) return string.format("\\u%04x", string.byte(c)) end)
    return s
end

local function ExportJson()
    local lines = QueryLines()
    if #lines == 0 then StatusLabel.Text = "没有可导出的文本"; return end
    local items = ItemsOfLines(lines)
    local out = {"{", "  \"section\": \"" .. JsonEscape(CurrentSection) .. "\",", "  \"count\": " .. #items .. ",", "  \"items\": ["}
    for i = 1, #items do
        local it = items[i]
        out[#out + 1] = string.format(
            "    {\"text\": \"%s\", \"class\": \"%s\", \"path\": \"%s\", \"count\": %d}%s",
            JsonEscape(it.text), JsonEscape(it.cls), JsonEscape(it.path), it.count,
            i < #items and "," or "")
    end
    out[#out + 1] = "  ]"
    out[#out + 1] = "}"
    WriteOut("UITextExport_" .. SafeFileName(CurrentSection) .. ".json", table.concat(out, "\n"))
end

local function CsvCell(s)
    s = tostring(s or "")
    if string.find(s, "[\",\n\r]") then
        s = "\"" .. s:gsub("\"", "\"\"") .. "\""
    end
    return s
end

local function ExportCsv()
    local lines = QueryLines()
    if #lines == 0 then StatusLabel.Text = "没有可导出的文本"; return end
    local items = ItemsOfLines(lines)
    -- 前置 UTF-8 BOM，Excel 打开才不会乱码
    local out = {"\239\187\191text,class,path,count"}
    for i = 1, #items do
        local it = items[i]
        out[#out + 1] = CsvCell(it.text) .. "," .. CsvCell(it.cls) .. "," .. CsvCell(it.path) .. "," .. it.count
    end
    WriteOut("UITextExport_" .. SafeFileName(CurrentSection) .. ".csv", table.concat(out, "\r\n"))
end

local function ExportTxt()
    local lines = QueryLines()
    if #lines == 0 then StatusLabel.Text = "没有可导出的文本"; return end
    WriteOut("UITextExport_" .. SafeFileName(CurrentSection) .. ".txt", table.concat(lines, "\n"))
end

-- 差异对比：第一次点记录快照，之后每次点都跟这份快照比（右键「对比」重新记录）
local Snapshot = nil
local function TakeSnapshot()
    local lines = QueryLines()
    local set = {}
    for i = 1, #lines do set[lines[i]] = true end
    Snapshot = {section = CurrentSection, set = set, count = #lines, time = os.date("%H:%M:%S")}
end

local function ShowDiff()
    if not Snapshot then
        TakeSnapshot()
        StatusLabel.Text = "已记录快照：" .. Snapshot.section .. " " .. Snapshot.count .. " 条（" .. Snapshot.time .. "）"
        return
    end
    if Snapshot.section ~= CurrentSection then
        TakeSnapshot()
        StatusLabel.Text = "快照分区已切到「" .. CurrentSection .. "」（" .. Snapshot.time .. "），再点一次看差异"
        return
    end
    local lines = QueryLines()
    local now, added, removed = {}, {}, {}
    for i = 1, #lines do
        now[lines[i]] = true
        if not Snapshot.set[lines[i]] then added[#added + 1] = lines[i] end
    end
    for text in pairs(Snapshot.set) do
        if not now[text] then removed[#removed + 1] = text end
    end
    local out = {}
    for i = 1, #added do out[#out + 1] = "[+ 新增] " .. added[i] end
    for i = 1, #removed do out[#out + 1] = "[- 消失] " .. removed[i] end
    if #out == 0 then
        SetDisplay("与快照（" .. Snapshot.time .. "）完全一致，没有变化", false, true, true)
        UpdateStatus("差异 0 条")
    else
        SetDisplay(out, false, true, true)
        UpdateStatus("对比快照 " .. Snapshot.time .. "：新增 " .. #added .. " / 消失 " .. #removed)
    end
end

-- 批量替换：搜索框 = 查找（可开正则），ReplaceBox = 替换为
-- 会直接改写原对象上的文本属性（只影响本机客户端）
local function BuildReplacePattern(q)
    if St.Regex then return q end
    return (q:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function BatchReplace()
    local q = CleanText(SearchBox.Text)
    if q == "" then StatusLabel.Text = "请先在搜索框填写查找条件"; return end
    local rep = Tool.Replace.Text or ""
    local data = SectionData[CurrentSection]
    if not data then return end
    local terms = ParseQuery(q)
    local target = {}
    for i = 1, #data.Texts do
        if MatchTerms(data.Texts[i], data.Info[data.Texts[i]], terms) then
            target[#target + 1] = data.Texts[i]
        end
    end
    if #target == 0 then StatusLabel.Text = "没有匹配到可替换的文本"; return end
    local pat = BuildReplacePattern(q)
    local changed, objs = 0, 0
    for i = 1, #target do
        local old = target[i]
        local info = data.Info[old]
        local ok, new = pcall(string.gsub, old, pat, function() return rep end)
        if ok and new ~= old and info then
            for obj in pairs(info.objs) do
                if obj and obj.Parent then
                    objs = objs + 1
                    pcall(function()
                        for _, prop in ipairs(TextPropsOf(obj)) do
                            if type(obj[prop]) == "string" and obj[prop] == old then
                                obj[prop] = new
                            end
                        end
                    end)
                end
            end
            changed = changed + 1
        end
    end
    StatusLabel.Text = "替换完成：命中 " .. #target .. " 条，改写 " .. changed .. " 条 / " .. objs .. " 个对象"
    ManualRefresh()
end

-- 配置持久化：收藏栏 + 各分区的屏蔽词（原版重执行就全丢）
local CONFIG_FILE = "UITextExport_配置.lua"

local function SaveConfig()
    if not writefile then StatusLabel.Text = "当前执行器没有 writefile，无法保存配置"; return end
    local out = {"-- UI文本提取器 配置（收藏栏 + 屏蔽词）", "return {", "  Favorites = {"}
    for i = 1, #FavoriteData.Texts do
        out[#out + 1] = "    \"" .. EscapeLuaString(FavoriteData.Texts[i]) .. "\","
    end
    out[#out + 1] = "  },"
    out[#out + 1] = "  Blocked = {"
    for _, sec in ipairs(Sections) do
        out[#out + 1] = "    [\"" .. EscapeLuaString(sec) .. "\"] = {"
        for text in pairs(BlockedData[sec]) do
            out[#out + 1] = "      \"" .. EscapeLuaString(text) .. "\","
        end
        out[#out + 1] = "    },"
    end
    out[#out + 1] = "  },"
    out[#out + 1] = "}"
    local ok, err = pcall(function() writefile(CONFIG_FILE, table.concat(out, "\n")) end)
    StatusLabel.Text = ok and ("收藏/屏蔽已保存到 " .. CONFIG_FILE) or ("保存失败：" .. tostring(err))
end

local function LoadConfig(silent)
    if not (readfile and isfile) then
        if not silent then StatusLabel.Text = "当前执行器不支持 readfile" end
        return false
    end
    local okE, exists = pcall(isfile, CONFIG_FILE)
    if not okE or not exists then
        if not silent then StatusLabel.Text = "没有找到 " .. CONFIG_FILE end
        return false
    end
    local okR, src = pcall(readfile, CONFIG_FILE)
    if not okR or type(src) ~= "string" then
        if not silent then StatusLabel.Text = "读取失败" end
        return false
    end
    local chunk = loadstring or load
    local okC, fn = pcall(chunk, src)
    local cfg = okC and fn and fn()
    if type(cfg) ~= "table" then
        if not silent then StatusLabel.Text = "配置文件格式不对" end
        return false
    end
    local nf, nb = 0, 0
    FavoriteData.Texts = {}
    FavoriteData.Map = {}
    for _, t in ipairs(cfg.Favorites or {}) do
        if type(t) == "string" and not FavoriteData.Map[t] then
            FavoriteData.Map[t] = true
            FavoriteData.Texts[#FavoriteData.Texts + 1] = t
            nf = nf + 1
        end
    end
    for _, sec in ipairs(Sections) do
        BlockedData[sec] = {}
        local list = (cfg.Blocked or {})[sec]
        if type(list) == "table" then
            for _, t in ipairs(list) do
                if type(t) == "string" then
                    BlockedData[sec][t] = true
                    nb = nb + 1
                end
            end
        end
    end
    if FavoriteStatus then FavoriteStatus.Text = "收藏列表｜共 " .. #FavoriteData.Texts .. " 条" end
    if type(RefreshFavoriteList) == "function" then pcall(RefreshFavoriteList) end
    StatusLabel.Text = "配置已读取：收藏 " .. nf .. " 条 / 屏蔽 " .. nb .. " 条"
    return true
end

local function ShowPerf()
    local msg = string.format(
        "性能：扫描 %d ms｜文本对象 %d 个｜已挂监听 %d 个｜根 %d 个｜列表 %d 条｜已实例化行 %d 个｜快照 %s",
        St.Perf.scanMs, St.Perf.total, St.Perf.hooked, St.Perf.roots,
        #DisplayedLines, #Win.Rows, St.Perf.at)
    StatusLabel.Text = msg
    print("[UI文本提取器] " .. msg)
end

local function UpdateToolLabels()
    Tool.Hidden.Text = St.Hidden and "含隐藏:开" or "含隐藏:关"
    Tool.Hidden.BackgroundColor3 = St.Hidden and Theme.Green or Theme.Card2
    StyleButton(Tool.Hidden, Tool.Hidden.BackgroundColor3)
    local rl = St.Regex and "正则:开" or "正则:关"
    if St.Case then rl = rl .. "·Aa" end
    Tool.Regex.Text = rl
    Tool.Regex.BackgroundColor3 = St.Regex and Theme.Accent or Theme.Card2
    StyleButton(Tool.Regex, Tool.Regex.BackgroundColor3)
    Tool.Sort.Text = "排序:" .. SortLabel()
    Tool.Sort.BackgroundColor3 = (St.Sort ~= "default") and Theme.Purple or Theme.Card2
    StyleButton(Tool.Sort, Tool.Sort.BackgroundColor3)
end

-- ==================== 工具按钮事件 ====================
Tool.Trans.MouseButton1Click:Connect(function() pcall(ExportTranslations) end)
Tool.Json.MouseButton1Click:Connect(function() pcall(ExportJson) end)
Tool.Csv.MouseButton1Click:Connect(function() pcall(ExportCsv) end)
Tool.Txt.MouseButton1Click:Connect(function() pcall(ExportTxt) end)
Tool.Perf.MouseButton1Click:Connect(function() pcall(ShowPerf) end)
Tool.ReplaceBtn.MouseButton1Click:Connect(function() pcall(BatchReplace) end)
Tool.Save.MouseButton1Click:Connect(function() pcall(SaveConfig) end)
Tool.Load.MouseButton1Click:Connect(function() pcall(LoadConfig) end)

Tool.Diff.MouseButton1Click:Connect(function()
    pcall(ShowDiff)
end)
Tool.Diff.MouseButton2Click:Connect(function()
    TakeSnapshot()
    StatusLabel.Text = "已重新记录快照：" .. Snapshot.section .. " " .. Snapshot.count .. " 条（" .. Snapshot.time .. "）"
end)

Tool.Hidden.MouseButton1Click:Connect(function()
    St.Hidden = not St.Hidden
    UpdateToolLabels()
    ManualRefresh()
    UpdateStatus(St.Hidden and "已包含不可见元素" or "只统计可见元素")
end)

-- 点一下切正则；右键切「区分大小写」
Tool.Regex.MouseButton1Click:Connect(function()
    St.Regex = not St.Regex
    UpdateToolLabels()
    if CleanText(SearchBox.Text) ~= "" then SearchNow() end
    UpdateStatus(St.Regex and "搜索：正则模式" or "搜索：普通模式")
end)
Tool.Regex.MouseButton2Click:Connect(function()
    St.Case = not St.Case
    UpdateToolLabels()
    if CleanText(SearchBox.Text) ~= "" then SearchNow() end
    UpdateStatus(St.Case and "搜索：区分大小写" or "搜索：忽略大小写")
end)

-- 点一下向后切排序；右键向前
local function CycleSort(step)
    local idx = 1
    for i = 1, #St.SortModes do
        if St.SortModes[i] == St.Sort then idx = i break end
    end
    idx = ((idx - 1 + step) % #St.SortModes) + 1
    St.Sort = St.SortModes[idx]
    UpdateToolLabels()
    SearchNow()
end
Tool.Sort.MouseButton1Click:Connect(function() pcall(CycleSort, 1) end)
Tool.Sort.MouseButton2Click:Connect(function() pcall(CycleSort, -1) end)

UpdateToolLabels()

-- ==================== 事件连接 ====================
for _, section in ipairs(Sections) do
    SectionButtons[section].MouseButton1Click:Connect(function()
        CurrentSection = section
        SearchBox.Text = ""
        SetDisplay(GetCurrentLines(), false, true, true)
        Scroll.CanvasPosition = Vector2.new(0,0)
        UpdateSectionButtons()
        UpdateStatus("已切换分区")
    end)
end

RefreshBtn.MouseButton1Click:Connect(function() ManualRefresh() end)

AutoCheckBtn.MouseButton1Click:Connect(function()
    AutoRefreshEnabled = not AutoRefreshEnabled
    AutoCheckBtn.Text = AutoRefreshEnabled and "☑ 自动刷新" or "☐ 自动刷新"
    AutoCheckBtn.BackgroundColor3 = AutoRefreshEnabled and Theme.Green or Theme.Yellow
    UpdateStatus(AutoRefreshEnabled and "自动刷新已开启" or "自动刷新已关闭")
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(CurrentDisplayText)
    elseif toclipboard then toclipboard(CurrentDisplayText) end
    UpdateStatus("已复制当前显示")
end)

BlockBtn.MouseButton1Click:Connect(function()
    BlockMode = not BlockMode
    if BlockMode then
        BlockBtn.Text = "屏蔽：开"
        BlockBtn.BackgroundColor3 = Theme.Purple
        UpdateStatus("屏蔽文本已开启")
    else
        BlockBtn.Text = "屏蔽：关"
        BlockBtn.BackgroundColor3 = Theme.Purple
        for _, sec in ipairs(Sections) do BlockedData[sec] = {} end
        UpdateStatus("屏蔽文本已关闭")
    end
end)

FavBtn.MouseButton1Click:Connect(function()
    CreateFavoriteUI()
    UpdateStatus("已打开收藏栏")
end)

ExportBtn.MouseButton1Click:Connect(function()
    local data = SectionData[CurrentSection]
    local safeName = tostring(CurrentSection):gsub("[\\/:*?\"<>|]", "_")
    local texts = data and data.Texts or {}
    local lines = {"-- UI文本导出", "-- 分区："..CurrentSection, "-- 数量："..#texts, "", "return {"}
    for _, t in ipairs(texts) do
        table.insert(lines, '    "'..EscapeLuaString(t)..'",')
    end
    table.insert(lines, "}")
    local luaText = table.concat(lines, "\n")
    if setclipboard then setclipboard(luaText) elseif toclipboard then toclipboard(luaText) end
    if writefile then
        local ok, err = pcall(function() writefile("UITextExport_"..safeName..".lua", luaText) end)
        if not ok then
            UpdateStatus("导出失败：无法写入文件")
            print("writefile 失败:", err)
            return
        end
    end
    UpdateStatus("已导出Lua")
end)

SearchBtn.MouseButton1Click:Connect(function()
    SearchNow()
end)

-- 搜索框获焦/失焦时的视觉高亮反馈
SearchBox.Focused:Connect(function()
    Tween(SearchBox, {BackgroundColor3 = Theme.AccentDark}, 0.15)
end)
SearchBox.FocusLost:Connect(function()
    Tween(SearchBox, {BackgroundColor3 = Theme.Card}, 0.15)
end)

SearchBox.FocusLost:Connect(function(enter)
    if enter then
        -- 回车键提交搜索
        SearchNow()
    elseif CleanText(SearchBox.Text) ~= "" then
        -- 移动端点击其他区域失去焦点时也自动搜索（不一定有回车键）
        SearchNow()
    end
end)

-- 搜索框文本变化时防抖搜索（0.3秒），避免每输入一个字符就重建列表
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if SearchDebounceTimer then
        task.cancel(SearchDebounceTimer)
        SearchDebounceTimer = nil
    end
    local keyword = CleanText(SearchBox.Text)
    if keyword ~= "" then
        SearchDebounceTimer = task.delay(0.3, function()
            SearchDebounceTimer = nil
            SearchNow()
        end)
    end
end)

ClearBtn.MouseButton1Click:Connect(function() ClearCurrent() end)

-- ==================== 最小化 <-> 悬浮圆点（带动画） ====================
-- 需求：点击[-]不再收缩成标题栏，而是收缩成一个可拖动的小圆点；再次点击圆点还原，
-- 且过程要有缩放/淡入淡出动画，同时保证在低配设备上依旧流畅（只对单个Frame做Tween）。
local MIN_ANIM_TIME = 0.22

local function GetCircleTargetPosition()
    if LastCirclePosition then return LastCirclePosition end
    -- 默认目标：屏幕左侧居中
    local vw, vh = 800, 600
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y end
    end)
    local x = math.clamp(16, 10, math.max(10, vw - 64))
    local y = math.clamp(math.floor(vh / 2 - 80), 10, math.max(10, vh - 64))
    return UDim2.new(0, x, 0, y)
end

local function MinimizeToCircle()
    if Animating then return end
    Animating = true
    Minimized = true

    LastNormalSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
    LastNormalPosition = Main.Position

    -- 收起时立即隐藏内容区，避免子元素在缩小动画期间来回重排（对低配设备更友好）
    Content.Visible = false
    ResizeHandle.Visible = false
    Main.BackgroundTransparency = 0

    local target = GetCircleTargetPosition()
    Tween(Main, {
        Size = UDim2.new(0, 40, 0, 40),
        Position = target,
        BackgroundTransparency = 1,
    }, MIN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    task.delay(MIN_ANIM_TIME, function()
        Main.Visible = false
        -- 还原 Main 尺寸属性（此时不可见，不会造成视觉跳变），方便下次还原动画计算
        Main.Size = UDim2.new(0, LastNormalSize.X, 0, LastNormalSize.Y)
        Main.Position = LastNormalPosition

        MiniCircle.Position = target
        MiniCircle.Size = UDim2.new(0, 10, 0, 10)
        MiniCircle.BackgroundTransparency = 1
        MiniCircle.Visible = true
        Tween(MiniCircle, {
            Size = UDim2.new(0, 54, 0, 54),
            BackgroundTransparency = 0,
        }, MIN_ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Animating = false
    end)
end

local function RestoreFromCircle()
    if Animating then return end
    Animating = true
    Minimized = false

    LastCirclePosition = MiniCircle.Position -- 记住用户拖动圆点后的位置，方便下次最小化回到这里

    Tween(MiniCircle, {
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
    }, MIN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    task.delay(MIN_ANIM_TIME, function()
        MiniCircle.Visible = false

        Main.Position = LastCirclePosition or MiniCircle.Position
        Main.Size = UDim2.new(0, 40, 0, 40)
        Main.BackgroundTransparency = 1
        Main.Visible = true

        Tween(Main, {
            Size = UDim2.new(0, LastNormalSize.X, 0, LastNormalSize.Y),
            Position = LastNormalPosition or UDim2.new(0.5, -LastNormalSize.X/2, 0.5, -LastNormalSize.Y/2),
            BackgroundTransparency = 0,
        }, MIN_ANIM_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        task.delay(MIN_ANIM_TIME, function()
            Content.Visible = true
            ResizeHandle.Visible = true
            LayoutUI()
            Animating = false
        end)
    end)
end

MinBtn.MouseButton1Click:Connect(function()
    if Minimized then RestoreFromCircle() else MinimizeToCircle() end
end)

MiniCircle.MouseButton1Click:Connect(function()
    RestoreFromCircle()
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ResizeCanvas() end)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if not Minimized then LayoutUI() end
end)

-- 缩放手柄
local resizing = false
local resizeStartPos, resizeStartSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Main.AbsoluteSize
        Main.Draggable = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - resizeStartPos
    local newW = math.clamp(resizeStartSize.X + delta.X, 400, 900)
    local newH = math.clamp(resizeStartSize.Y + delta.Y, 280, 700)
    Main.Size = UDim2.new(0, newW, 0, newH)
    LastNormalSize = Vector2.new(newW, newH)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
        Main.Draggable = true
    end
end)

-- ==================== 自动刷新（兜底轮询） ====================
-- 平时靠事件驱动：文本对象新增 / 消失 / 文本被改写都会立刻更新数据（见 AttachIncremental）。
-- 这个定时器只做两件事：
--   1) DataDirty 时只重画列表，不重扫（几乎零成本）
--   2) 每 15 拍兜底全量重扫一次，防止漏事件
-- 原版是每 1.5 秒无条件全量重扫（且「全部」要扫 5 遍整棵树）。
local PollTick = 0
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(St.AutoRefresh)
        PollTick = PollTick + 1
        if St.Live and St.Dirty then
            St.Dirty = false
            pcall(function() RefreshDisplay(0) end)
        end
        if AutoRefreshEnabled and PollTick % 15 == 0 then
            pcall(ManualRefresh)
        elseif PollTick % 5 == 0 then
            UpdateSectionButtons()
            UpdateStatus()
        end
    end
end)

-- ==================== 悬停说明 + 帮助面板 ====================
-- 说明动辄几十个字，塞进状态栏那一行会被截断，所以做成贴在按钮旁边的浮层。
Tool.Tip.show = function(obj, name, desc)
    local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    if w <= 0 then w = 540 end
    if h <= 0 then h = 370 end

    local text = name .. "：" .. desc
    Tip.Label.Text = text
    local ts = Tip.Label.TextSize
    local tw = math.floor(math.clamp(w * 0.46, 150, 330))
    local perLine = math.max(10, math.floor((tw - 16) / (ts * 0.62)))
    local lines = math.max(1, math.ceil(Utf8Chars(text) / perLine))
    local th = lines * (ts + 3) + 12
    Tip.Box.Size = UDim2.new(0, tw, 0, th)

    -- 贴着按钮放：按钮在左半边就放右边，在右半边就放左边，免得挡住正在看的按钮
    local ax, ay, aw = 0, 0, 0
    pcall(function()
        ax = obj.AbsolutePosition.X - Main.AbsolutePosition.X
        ay = obj.AbsolutePosition.Y - Main.AbsolutePosition.Y
        aw = obj.AbsoluteSize.X
    end)
    local x
    if (ax + aw / 2) < w / 2 then x = ax + aw + 6 else x = ax - tw - 6 end
    local tH = math.floor(math.clamp(30 * (CurrentUIScale or 1), 24, 44))
    x = math.clamp(x, 4, math.max(4, w - tw - 4))
    local y = math.clamp(ay + 8, tH + 4, math.max(tH + 4, h - th - 4))
    Tip.Box.Position = UDim2.new(0, x, 0, y)
    Tip.Box.Visible = true
end

Tool.Tip.hide = function()
    Tip.Box.Visible = false
end

Help.Toggle = function()
    Help.Panel.Visible = not Help.Panel.Visible
    Tool.Tip.hide()
    if Help.Panel.Visible then
        StatusLabel.Text = "功能说明：滚轮翻页，点右上角 ✕ 或按 Esc 关闭"
    else
        UpdateStatus()
    end
    LayoutUI()
end

Tool.Help.MouseButton1Click:Connect(function() pcall(Help.Toggle) end)
Help.Close.MouseButton1Click:Connect(function() pcall(Help.Toggle) end)

-- 每个功能都挂上悬停说明（列表行里的按钮在 MakeAction 里单独挂）
for _, section in ipairs(Sections) do AttachTip(SectionButtons[section], "sec") end
AttachTip(RefreshBtn, "Refresh")
AttachTip(AutoCheckBtn, "Auto")
AttachTip(CopyBtn, "CopyAll")
AttachTip(BlockBtn, "Block")
AttachTip(FavBtn, "Fav")
AttachTip(ExportBtn, "ExportLua")
AttachTip(ClearBtn, "Clear")
AttachTip(SearchBox, "search")
AttachTip(Tool.Replace, "replaceBox")

-- ==================== 快捷键 ====================
-- Ctrl+F 聚焦搜索　Ctrl+R 刷新　Ctrl+E 导出汉化表　Ctrl+S 保存配置　Esc 取消输入焦点
pcall(function()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            pcall(function() SearchBox:ReleaseFocus() end)
            pcall(function() Tool.Replace:ReleaseFocus() end)
            if Help.Panel.Visible then pcall(Help.Toggle) end
            pcall(function() Tool.Tip.hide() end)
            return
        end
        local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        if not ctrl then return end
        if input.KeyCode == Enum.KeyCode.F then
            pcall(function() SearchBox:CaptureFocus() end)
        elseif input.KeyCode == Enum.KeyCode.R then
            pcall(ManualRefresh)
        elseif input.KeyCode == Enum.KeyCode.E then
            pcall(ExportTranslations)
        elseif input.KeyCode == Enum.KeyCode.S then
            pcall(SaveConfig)
        end
    end)
end)

-- ==================== 初始化 ====================
LayoutUI()
UpdateSectionButtons()
CurrentSection = "全部"
UpdateToolLabels()

do
    local t0 = os.clock()
    ManualRefresh()
    St.Perf.scanMs = math.floor((os.clock() - t0) * 1000)
    St.Perf.at = os.date("%H:%M:%S")
    St.Perf.total = 0
    for _ in pairs(St.ObjIndex) do St.Perf.total = St.Perf.total + 1 end
    St.Perf.roots = #ScanRootsList(huiRootCache)
end

-- 给已发现的文本对象挂上属性监听：之后游戏里文本被改写会实时反映进来
task.spawn(function()
    local n = 0
    for obj in pairs(St.ObjIndex) do
        if obj.Parent then
            HookObject(obj)
            n = n + 1
        end
    end
    St.Perf.hooked = n
    if n > 0 then print("[UI文本提取器] 已为 " .. n .. " 个文本对象挂上实时监听") end
end)

AttachIncremental()
pcall(LoadConfig, true)   -- 有上次保存的配置就自动读回来

print(string.format("[UI文本提取器 v25] 已加载 | 单遍扫描 %d ms｜%d 个文本对象｜虚拟化列表 + 实时增量更新",
    St.Perf.scanMs, St.Perf.total))
print("[UI文本提取器] 新人提示：鼠标停在任意按钮上会弹出该功能的说明；右栏「帮助」可看完整功能表")

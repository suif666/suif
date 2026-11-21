-- ══════════════════════════════════════════════════════════════════════════════
-- 【脚本库 / rscripts】远程脚本（从主脚本打包）
-- 自建 ScreenGui 卡片列表 UI，数据来自 worker /rscripts，按当前 placeId 自动筛选
-- 依赖注入：
--   __SUIF_WIN     WindUI 窗口对象（建分组用）
--   __SUIF_RUN     执行函数 run(url, name)
--   __SUIF_RS_TAB  主脚本预建的「rscripts 脚本库」页签
-- ══════════════════════════════════════════════════════════════════════════════
local _G = getgenv and getgenv() or _G
local win = _G.__SUIF_WIN
local run = _G.__SUIF_RUN
local _rsTabInjected = _G.__SUIF_RS_TAB

if not win then
    warn("[脚本库] 缺少 win 注入，无法创建界面")
    return
end
if not run then
    run = function(url, name) end
end

-- ═══════════════════════════════════════════════════════════════════════
-- rscripts 脚本库 · 自建 UI
--
-- 为什么不用 WindUI 的 Dropdown：下拉框只能显示一行，作者/赞数/风险/简介
-- 全塞不下，只能压成「1. ⚠ 🔑 标题…」，根本没法看。所以这里自己建
-- ScreenGui，做成卡片列表，每个脚本一行卡片，信息一次看全。
--
-- 数据来自我们自己的 Worker（/rscripts），密钥存在 Worker 里，客户端看不到。
-- 执行复用现有的 run(url)：API 给的 rawScript 是公开裸源码 URL，直接
-- game:HttpGet 就行，源码不经过 Worker。
--
-- 最值钱的一点：placeId 用当前游戏的。玩家在任意游戏里打开，看到的都是
-- 【那个游戏可用】的脚本，全自动，不用人工整理。
-- ═══════════════════════════════════════════════════════════════════════
do
    local RS_API = "https://suture-hub-counter.sfbdsl666.workers.dev/rscripts"
    local RS_LIMIT = 30        -- 列表端点上限 48，取 30 够用又省流量
    local RS_SEARCH_LIMIT = 20 -- 搜索端点上限只有 20（填 30 会报错）

    local RS = {
        Win = Color3.fromRGB(28, 28, 36),   -- 外框
        Panel = Color3.fromRGB(34, 34, 44), -- 内容区
        Card = Color3.fromRGB(43, 43, 56),  -- 卡片
        CardHi = Color3.fromRGB(56, 56, 74),-- 卡片悬停
        Accent = Color3.fromRGB(99, 102, 241),
        Accent2 = Color3.fromRGB(129, 132, 255),
        Text = Color3.fromRGB(236, 236, 245),
        Text2 = Color3.fromRGB(158, 158, 178),
        Good = Color3.fromRGB(88, 205, 128),
        Warn = Color3.fromRGB(242, 186, 82),
        Bad = Color3.fromRGB(238, 100, 100),
        Line = Color3.fromRGB(60, 60, 76),
    }

    local FONT = Enum.Font.Gotham
    local FONT_B = Enum.Font.GothamBold
    local FONT_M = Enum.Font.GothamMedium

    local rsState = { mode = "place", q = "", page = 1, busy = false, list = {} }
    local rsLoad   -- 前置声明：下面建 UI 时的按钮回调要用到它，而它定义在后面
    local rsGui, rsPanel, rsList, rsStatus, rsSearchBox, rsSearchBar
    local rsModeBtns = {}

    -- ── 小工具 ──────────────────────────────────────────────────────────
    local function corner(obj, r)
        local c = Instance.new("UICorner", obj)
        c.CornerRadius = UDim.new(0, r or 6)
        return c
    end

    local function stroke(obj, color, thick)
        local s = Instance.new("UIStroke", obj)
        s.Color = color or RS.Line
        s.Thickness = thick or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        return s
    end

    local function label(parent, text, size, color, bold)
        local t = Instance.new("TextLabel", parent)
        t.BackgroundTransparency = 1
        t.Text = text
        t.TextSize = size or 13
        t.TextColor3 = color or RS.Text
        t.Font = bold and FONT_B or FONT
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Center
        return t
    end

    -- ── 建 UI（只建一次，之后复用）───────────────────────────────────────
    local function rsBuild()
        if rsGui and rsGui.Parent then return end

        rsGui = Instance.new("ScreenGui")
        rsGui.Name = __HARD and __rnd(12) or "SutureRscripts"  -- ★ 开关关掉就用回原名
        rsGui.ResetOnSpawn = false
        rsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        rsGui.DisplayOrder = 100
        rsGui.Parent = HIDDEN        -- ★ 原来挂 PlayerGui，改挂隐藏容器

        rsPanel = Instance.new("Frame", rsGui)
        rsPanel.Name = "Panel"
        rsPanel.Size = UDim2.fromOffset(640, 470)
        rsPanel.Position = UDim2.new(0.5, -320, 0.5, -235)
        rsPanel.BackgroundColor3 = RS.Win
        rsPanel.BorderSizePixel = 0
        rsPanel.Active = true
        corner(rsPanel, 12)
        stroke(rsPanel, RS.Line, 1)

        -- 标题栏（拖动区）
        local bar = Instance.new("Frame", rsPanel)
        bar.Name = "TitleBar"
        bar.Size = UDim2.new(1, 0, 0, 42)
        bar.BackgroundColor3 = RS.Panel
        bar.BorderSizePixel = 0
        bar.Active = true
        corner(bar, 12)
        local barFix = Instance.new("Frame", bar)  -- 盖住下边缘的圆角
        barFix.Size = UDim2.new(1, 0, 0, 12)
        barFix.Position = UDim2.new(0, 0, 1, -12)
        barFix.BackgroundColor3 = RS.Panel
        barFix.BorderSizePixel = 0

        local titleL = label(bar, "rscripts 脚本库", 16, RS.Text, true)
        titleL.Position = UDim2.new(0, 46, 0, 0)
        titleL.Size = UDim2.new(1, -160, 1, 0)

        -- 小圆点装饰（和 hub 主题色一致）
        local dot = Instance.new("Frame", bar)
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.new(0, 18, 0.5, -6)
        dot.BackgroundColor3 = RS.Accent
        dot.BorderSizePixel = 0
        corner(dot, 6)

        local close = Instance.new("TextButton", bar)
        close.Size = UDim2.fromOffset(30, 30)
        close.Position = UDim2.new(1, -38, 0.5, -15)
        close.BackgroundColor3 = RS.Card
        close.Text = "✕"
        close.TextSize = 14
        close.Font = FONT_B
        close.TextColor3 = RS.Text2
        close.AutoButtonColor = false
        close.BorderSizePixel = 0
        corner(close, 8)
        close.MouseEnter:Connect(function() close.BackgroundColor3 = RS.Bad end)
        close.MouseLeave:Connect(function() close.BackgroundColor3 = RS.Card end)
        close.MouseButton1Click:Connect(function()
            if rsGui then rsGui.Enabled = false end
        end)

        -- 拖动
        local dragging, dragStart, startPos
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = rsPanel.Position
            end
        end)
        bar.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                rsPanel.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        -- 工具栏：搜索框 + 分区按钮
        local tools = Instance.new("Frame", rsPanel)
        tools.Size = UDim2.new(1, -24, 0, 38)
        tools.Position = UDim2.new(0, 12, 0, 50)
        tools.BackgroundTransparency = 1

        rsSearchBar = Instance.new("Frame", tools)
        rsSearchBar.Size = UDim2.new(1, -300, 1, 0)
        rsSearchBar.BackgroundColor3 = RS.Panel
        rsSearchBar.BorderSizePixel = 0
        corner(rsSearchBar, 8)
        stroke(rsSearchBar, RS.Line, 1)

        rsSearchBox = Instance.new("TextBox", rsSearchBar)
        rsSearchBox.Size = UDim2.new(1, -14, 1, 0)
        rsSearchBox.Position = UDim2.new(0, 7, 0, 0)
        rsSearchBox.BackgroundTransparency = 1
        rsSearchBox.Text = ""
        rsSearchBox.PlaceholderText = "🔍  搜索脚本，回车执行（例如 aimbot / auto farm）"
        rsSearchBox.PlaceholderColor3 = RS.Text2
        rsSearchBox.TextColor3 = RS.Text
        rsSearchBox.TextSize = 13
        rsSearchBox.Font = FONT
        rsSearchBox.ClearTextOnFocus = false
        rsSearchBox.TextXAlignment = Enum.TextXAlignment.Left

        local function modeBtn(text, key, xOff)
            local b = Instance.new("TextButton", tools)
            b.Size = UDim2.fromOffset(90, 38)
            b.Position = UDim2.new(1, xOff, 0, 0)
            b.BackgroundColor3 = RS.Panel
            b.Text = text
            b.TextSize = 13
            b.Font = FONT_M
            b.TextColor3 = RS.Text2
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            corner(b, 8)
            stroke(b, RS.Line, 1)
            rsModeBtns[key] = b
            b.MouseButton1Click:Connect(function()
                rsLoad(key)
            end)
            return b
        end
        modeBtn("本游戏", "place", -272)
        modeBtn("最新", "newest", -178)
        modeBtn("热门", "trending", -84)

        -- 状态行
        rsStatus = label(rsPanel, "点「本游戏」列出这个游戏能用的脚本", 12, RS.Text2)
        rsStatus.Size = UDim2.new(1, -24, 0, 20)
        rsStatus.Position = UDim2.new(0, 12, 0, 94)

        -- 卡片列表
        local holder = Instance.new("Frame", rsPanel)
        holder.Size = UDim2.new(1, -24, 1, -126)
        holder.Position = UDim2.new(0, 12, 0, 116)
        holder.BackgroundColor3 = RS.Panel
        holder.BorderSizePixel = 0
        corner(holder, 10)
        stroke(holder, RS.Line, 1)

        rsList = Instance.new("ScrollingFrame", holder)
        rsList.Size = UDim2.new(1, -10, 1, -10)
        rsList.Position = UDim2.new(0, 5, 0, 5)
        rsList.BackgroundTransparency = 1
        rsList.BorderSizePixel = 0
        rsList.ScrollBarThickness = 5
        rsList.ScrollBarImageColor3 = RS.Accent
        rsList.CanvasSize = UDim2.new(0, 0, 0, 0)
        rsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        rsList.ScrollingDirection = Enum.ScrollingDirection.Y

        local pad = Instance.new("UIPadding", rsList)
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)

        local lay = Instance.new("UIListLayout", rsList)
        lay.Padding = UDim.new(0, 8)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- ── 一张卡片 ────────────────────────────────────────────────────────
    local function rsCard(x, index)
        local card = Instance.new("Frame")
        card.Name = "Card" .. index
        card.Size = UDim2.new(1, 0, 0, 76)
        card.BackgroundColor3 = RS.Card
        card.BorderSizePixel = 0
        card.LayoutOrder = index
        corner(card, 9)

        -- 左侧：游戏封面图；加载不出来就显示游戏名首字（不留空白）
        local thumbWrap = Instance.new("Frame", card)
        thumbWrap.Size = UDim2.fromOffset(56, 56)
        thumbWrap.Position = UDim2.new(0, 10, 0.5, -28)
        thumbWrap.BackgroundColor3 = RS.Panel
        thumbWrap.BorderSizePixel = 0
        thumbWrap.ZIndex = 2
        corner(thumbWrap, 8)

        local initial = label(thumbWrap, string.sub(x.game ~= "" and x.game or x.title or "?", 1, 1),
            22, RS.Text2, true)
        initial.Size = UDim2.new(1, 0, 1, 0)
        initial.TextXAlignment = Enum.TextXAlignment.Center

        if x.img and x.img ~= "" then
            local img = Instance.new("ImageLabel", thumbWrap)
            img.Size = UDim2.new(1, 0, 1, 0)
            img.BackgroundTransparency = 1
            img.Image = x.img
            img.ZIndex = 3
            corner(img, 8)
            -- ImageFailed 不是所有执行器都有，取不到就让占位首字留在下面
            pcall(function() img.ImageFailed:Connect(function() img:Destroy() end) end)
        end

        -- 标题
        local title = label(card, x.title ~= "" and x.title or "（无标题）", 14, RS.Text, true)
        title.Size = UDim2.new(1, -240, 0, 20)
        title.Position = UDim2.new(0, 76, 0, 10)
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.ZIndex = 2

        -- 作者 · 赞 · 浏览
        local meta = {}
        if x.author ~= "" then table.insert(meta, x.author) end
        if x.verified then table.insert(meta, "✔") end
        table.insert(meta, "👍 " .. tostring(x.likes or 0))
        table.insert(meta, "👁 " .. tostring(x.views or 0))
        local metaL = label(card, table.concat(meta, "   "), 12, RS.Text2)
        metaL.Size = UDim2.new(1, -240, 0, 16)
        metaL.Position = UDim2.new(0, 76, 0, 30)
        metaL.TextTruncate = Enum.TextTruncate.AtEnd
        metaL.ZIndex = 2

        -- 状态徽章：一眼看出能不能用
        local badges = Instance.new("Frame", card)
        badges.Size = UDim2.new(1, -240, 0, 20)
        badges.Position = UDim2.new(0, 76, 0, 48)
        badges.BackgroundTransparency = 1
        badges.ZIndex = 2
        local bl = Instance.new("UIListLayout", badges)
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.Padding = UDim.new(0, 6)
        bl.SortOrder = Enum.SortOrder.LayoutOrder

        local function badge(text, color, order)
            local b = Instance.new("Frame", badges)
            b.BackgroundColor3 = color
            b.BackgroundTransparency = 0.82
            b.BorderSizePixel = 0
            b.LayoutOrder = order or 1
            b.ZIndex = 3
            corner(b, 5)
            local t = Instance.new("TextLabel", b)
            t.BackgroundTransparency = 1
            t.Text = text
            t.TextSize = 11
            t.Font = FONT_M
            t.TextColor3 = color
            t.Size = UDim2.new(1, 0, 1, 0)
            t.ZIndex = 4
            local pad2 = Instance.new("UIPadding", b)
            pad2.PaddingLeft = UDim.new(0, 7)
            pad2.PaddingRight = UDim.new(0, 7)
            -- 宽度跟着文字走。中文一个字比英文宽近一倍，分开算才不会挤
            local wide = 0
            for i = 1, #text do
                local byte = string.byte(text, i)
                if byte >= 0xE0 then wide = wide + 1 end   -- UTF-8 多字节 = 中文/emoji
            end
            local narrow = #text - wide * 2
            b.Size = UDim2.fromOffset(math.max(50, 18 + narrow * 7 + wide * 13), 20)
            return b
        end

        local o = 1
        if x.patched then
            badge("⚠ 已被游戏方修复", RS.Bad, o); o = o + 1
        else
            badge("✅ 可直接用", RS.Good, o); o = o + 1
        end
        if x.key then
            badge("🔑 需要卡密", RS.Warn, o); o = o + 1
        end
        if x.paid then
            badge("💰 付费", RS.Warn, o); o = o + 1
        end
        if x.risk and x.risk ~= "" and x.risk ~= "Safe" then
            badge("风险 " .. x.risk, RS.Warn, o); o = o + 1
        end
        if x.game and x.game ~= "" then
            badge(x.game, RS.Accent2, o); o = o + 1
        end

        -- 右侧：执行按钮
        local go = Instance.new("TextButton", card)
        go.Size = UDim2.fromOffset(88, 34)
        go.Position = UDim2.new(1, -100, 0.5, -17)
        go.BackgroundColor3 = x.patched and RS.Card or RS.Accent
        go.Text = x.patched and "仍要执行" or "执行"
        go.TextSize = 13
        go.Font = FONT_B
        go.TextColor3 = x.patched and RS.Text2 or Color3.new(1, 1, 1)
        go.AutoButtonColor = false
        go.BorderSizePixel = 0
        go.ZIndex = 4
        corner(go, 8)

        if x.patched then
            -- 已修复的脚本默认不给绿色按钮，避免误点
            stroke(go, RS.Line, 1)
        end

        go.MouseEnter:Connect(function()
            go.BackgroundColor3 = x.patched and RS.CardHi or RS.Accent2
        end)
        go.MouseLeave:Connect(function()
            go.BackgroundColor3 = x.patched and RS.Card or RS.Accent
        end)
        go.MouseButton1Click:Connect(function()
            if not x.raw or x.raw == "" then
                notify("脚本库", "这个脚本没有可执行地址", "warning", 3)
                return
            end
            if x.key and x.keyUrl and x.keyUrl ~= "" then
                notify("脚本库", "需要卡密，先去：" .. x.keyUrl, "warning", 5)
            end
            if x.patched then
                notify("脚本库", "这个脚本已被游戏方修复，多半无效", "warning", 4)
            end
            run(x.raw, x.title or "rscripts 脚本")
        end)

        -- 悬停高亮：直接改卡片自己的底色（原来的做法是加一层 Frame，
        -- 但那一层在卡片背景【下面】，根本看不见）
        card.MouseEnter:Connect(function() card.BackgroundColor3 = RS.CardHi end)
        card.MouseLeave:Connect(function() card.BackgroundColor3 = RS.Card end)

        card.Parent = rsList
        return card
    end

    -- ── 把一个空状态/提示塞进列表 ────────────────────────────────────────
    local function rsHint(text, color)
        local f = Instance.new("Frame", rsList)
        f.Size = UDim2.new(1, 0, 0, 120)
        f.BackgroundTransparency = 1
        local t = label(f, text, 13, color or RS.Text2)
        t.Size = UDim2.new(1, 0, 1, 0)
        t.TextXAlignment = Enum.TextXAlignment.Center
        t.TextWrapped = true
    end

    local function rsClear()
        for _, c in ipairs(rsList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function rsMarkMode()
        for k, b in pairs(rsModeBtns) do
            local on = (k == rsState.mode)
            b.BackgroundColor3 = on and RS.Accent or RS.Panel
            b.TextColor3 = on and Color3.new(1, 1, 1) or RS.Text2
        end
    end

    -- ── 拉数据 + 渲染 ───────────────────────────────────────────────────
    rsLoad = function(mode)
        if rsState.busy then
            notify("脚本库", "上一次还在加载中", "info", 2)
            return
        end
        rsBuild()
        rsGui.Enabled = true

        if mode then rsState.mode = mode end
        if rsState.mode == "search" and rsState.q == "" then
            notify("脚本库", "先在搜索框里输入关键词", "info", 2)
            return
        end

        rsState.busy = true
        rsMarkMode()
        rsClear()
        rsHint("正在加载…")
        rsStatus.Text = "正在请求…"

        task.spawn(function()
            local http = game:GetService("HttpService")
            local url
            if rsState.mode == "search" then
                url = RS_API .. "?q=" .. http:UrlEncode(rsState.q) .. "&limit=" .. RS_SEARCH_LIMIT
            elseif rsState.mode == "trending" then
                url = RS_API .. "?trending=1"
            elseif rsState.mode == "newest" then
                url = RS_API .. "?sort=newest&limit=" .. RS_LIMIT
            else
                url = RS_API .. "?placeid=" .. http:UrlEncode(tostring(game.PlaceId)) .. "&limit=" .. RS_LIMIT
            end

            local ok, res = pcall(function() return game:HttpGet(url, true) end)
            if not ok then
                rsState.busy = false
                rsClear(); rsHint("加载失败：网络请求异常\n点上面的分区按钮重试", RS.Bad)
                rsStatus.Text = "加载失败"
                return
            end

            local okDec, data = pcall(function() return http:JSONDecode(tostring(res)) end)
            if not okDec or type(data) ~= "table" then
                rsState.busy = false
                rsClear(); rsHint("加载失败：返回内容无法解析", RS.Bad)
                rsStatus.Text = "加载失败"
                return
            end
            if not data.ok then
                rsState.busy = false
                rsClear(); rsHint("加载失败：" .. tostring(data.error or "未知错误"), RS.Bad)
                rsStatus.Text = "加载失败"
                return
            end

            -- 热门模式返回两组，合并
            local list = {}
            if data.trending then
                for _, x in ipairs(data.rising or {}) do x.__tag = "上升"; table.insert(list, x) end
                for _, x in ipairs(data.trending or {}) do x.__tag = "热门"; table.insert(list, x) end
            else
                list = data.scripts or {}
            end
            rsState.list = list

            rsClear()
            if #list == 0 then
                rsHint("没有找到脚本\n换个分区，或者换个关键词试试")
                rsStatus.Text = "没有结果"
            else
                for i, x in ipairs(list) do rsCard(x, i) end
                local total = (data.meta and data.meta.total) or #list
                if rsState.mode == "place" then
                    rsStatus.Text = ("本游戏「%s」共 %s 个脚本，已列出 %d 个 —— 往下滑"):format(
                        game.Name, tostring(total), #list)
                elseif rsState.mode == "search" then
                    rsStatus.Text = ("搜索「%s」共 %s 个，已列出 %d 个"):format(
                        rsState.q, tostring(total), #list)
                elseif rsState.mode == "trending" then
                    rsStatus.Text = ("热门 + 上升共 %d 个"):format(#list)
                else
                    rsStatus.Text = ("最新上传：共 %s 个，已列出 %d 个"):format(tostring(total), #list)
                end
            end
            rsState.busy = false
        end)
    end

    -- 搜索框回车 = 搜索
    local function rsHookSearch()
        if not rsSearchBox then return end
        rsSearchBox.FocusLost:Connect(function(enterPressed)
            rsState.q = tostring(rsSearchBox.Text or "")
            if enterPressed and rsState.q ~= "" then
                rsLoad("search")
            end
        end)
    end

    -- ═══ 挂到 WindUI 分区上：一个入口按钮 ═══
    -- 页签由主脚本预建（getgenv().__SUIF_RS_TAB），这里直接用，不重复建分组
    local rsSec = nil
    local rsTab = _rsTabInjected
    if not rsTab then
        warn("[脚本库] 页签注入无效，放弃挂载")
        return
    end

    rsTab:Paragraph({
        Title = "rscripts 脚本库",
        Desc = "点下面的按钮打开脚本列表。\n"
            .. "「本游戏」用的是当前游戏的 PlaceId，所以你在任何游戏里点开，\n"
            .. "看到的都是【那个游戏能用】的脚本，全自动，不用手动找。"
    })

    rsTab:Button({
        Title = "打开脚本库",
        Desc = "卡片列表：封面、作者、点赞、以及能不能直接用的标记",
        Icon = "layout-grid",
        Callback = function()
            rsBuild()
            rsHookSearch()
            rsGui.Enabled = true
            if #rsState.list == 0 then
                rsLoad("place")
            else
                rsMarkMode()
            end
        end
    })

    rsTab:Button({
        Title = "直接列出本游戏脚本",
        Desc = "跳过 UI，直接刷新本游戏的脚本列表",
        Icon = "gamepad-2",
        Callback = function()
            rsBuild()
            rsHookSearch()
            rsLoad("place")
        end
    })

    -- 主题跟随（hub 支持切主题，这里只跟着强调色走，不跟深浅）
    pcall(function()
        if getgenv().SutureRscriptsAccent then
            RS.Accent = getgenv().SutureRscriptsAccent
        end
    end)

    -- 退出脚本时一起销毁，避免留一个关不掉的悬浮窗
    getgenv().SutureDestroyRscripts = function()
        pcall(function() if rsGui then rsGui:Destroy() end end)
        rsGui = nil
    end

    getgenv().Tabs = getgenv().Tabs or {}
    getgenv().Tabs.RscriptsTab = rsTab
    getgenv().SutureRscriptsTab = rsTab
end

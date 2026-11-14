-- ═══════════════════════════════════════════════════════════════
--  报错诊断 v1.0（独立脚本，不属于加载器/主脚本）
--  用途：加载器或主脚本加载失败时自动弹出诊断 UI
--  用法：本脚本会被加载器/主脚本自动静默加载（平时无任何界面）；
--       加载出错时自动弹出诊断面板。
--  也可手动执行本脚本后再加载 SutureLoad5.lua / suif.lua。
--  手动触发（其他脚本可调用）：
--       getgenv().ShowDiagnose = function(errText) ... end
-- ═══════════════════════════════════════════════════════════════

-- 防重复启动：加载器/主脚本都可能自动拉取本脚本，只允许一个监控实例
do
    local _g = (getgenv and getgenv()) or _G
    if _g and _g.__SUTURE_DIAG_ACTIVE then
        return
    end
    if _g then
        _g.__SUTURE_DIAG_ACTIVE = true
    end
end

-- 配置：要监控的加载器地址（"重新加载"按钮用它）
local LOADER_URL = "https://raw.githubusercontent.com/suif666/suif/main/SutureLoad5.lua"

-- 反馈接口（与 suif 脚本反馈功能同一个入口）
local FEEDBACK_API = "https://suture-feedback.sfbdsl666.workers.dev/"
local FEEDBACK_TOKEN = "suture_fb_2025_zh"

-- 报错信息里出现这些关键词才算"加载相关"（过滤游戏内其他脚本的噪音报错）
local LOAD_KEYWORDS = {
    "SutureLoad", "SutureLoader", "suif", "WindUI", "Boreal", "加载", "预载",
    "HttpGet", "Http", "timeout", "Timeout", "connect", "GET", "POST",
    "loadstring", "attempt to", "unexpected symbol", "malformed",
    "404", "500", "memory", "stack overflow", "kick", "Teleport",
}

-- 报错诊断规则：按关键词匹配，给出人工建议
local DIAGNOSTICS = {
    { pat = "timeout",            msg = "加载超时：当前网络环境可能存在问题，请更换加速器或更换网络后重新加载。" },
    { pat = "Http",               msg = "网络请求失败：可能被防火墙/加速器规则拦截，请更换加速器节点或网络后重试。" },
    { pat = "404",                msg = "资源不存在（404）：脚本可能已更新/链接失效，请等待维护者修复或检查更新源。" },
    { pat = "500",                msg = "服务器暂时不可用（500）：请稍后重试，或切换加载源（jsDelivr/gh-proxy 镜像）。" },
    { pat = "unexpected symbol",  msg = "代码解析失败：下载可能被截断或文件损坏，请重新加载；多次失败请清缓存后重试。" },
    { pat = "attempt to call",    msg = "运行时调用了不存在的函数：可能是版本不兼容或依赖（如 WindUI）未加载成功，请重新加载。" },
    { pat = "memory",             msg = "执行器内存不足：请重启执行器后重新加载，避免同时开多个大脚本。" },
    { pat = "stack overflow",     msg = "脚本栈溢出（递归过深）：请重启执行器后重试，并反馈给维护者。" },
    { pat = "kick",               msg = "可能被游戏反作弊/服务器踢出：请更换执行器或调整脚本设置后重试。" },
    { pat = "WindUI",             msg = "UI 库（WindUI/Boreal）加载失败：多为网络问题导致库未下载成功，请更换加速器后重试。" },
}

local function diagnose(msg)
    local low = string.lower(tostring(msg))
    for _, rule in ipairs(DIAGNOSTICS) do
        if string.find(low, string.lower(rule.pat), 1, true) then
            return rule.msg
        end
    end
    return "未知错误：请点击「发送信息」把下方报错发给维护者，感谢反馈。"
end

-----------------------------------------------------------------------
-- 基础工具
-----------------------------------------------------------------------
local TASK = (type(task) == "table" or type(task) == "userdata") and task or {}
local function Wait(t) if TASK.wait then return TASK.wait(t) end return wait(t) end
local function Spawn(fn) if TASK.spawn then return TASK.spawn(fn) end return spawn(fn) end

local function New(class, props, children)
    local obj = Instance.new(class)
    if props then for k, v in pairs(props) do obj[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = obj end end
    return obj
end

-- 北京时间（UTC+8）
local WEEK_CN = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" }
local function BeijingTime()
    local t = os.time() + 8 * 3600
    local date = os.date("!%Y-%m-%d", t)
    local hms = os.date("!%H:%M:%S", t)
    local wd = tonumber(os.date("!%w", t)) or 0
    return date .. "  " .. WEEK_CN[wd + 1] .. "  " .. hms
end

-- 游戏名（子服务器时显示主服务器名）
local GameName = "（获取中…）"
local function FetchGameName()
    local MPS = game:GetService("MarketplaceService")
    local mainName, subName, isSub = nil, nil, false
    pcall(function()
        local info = MPS:GetProductInfo(game.PlaceId)
        subName = info and info.Name or nil
    end)
    -- 尝试找主服务器（Experience 主 Place）
    pcall(function()
        local mainId = nil
        pcall(function() mainId = game.MainPlaceId end)
        if not mainId then
            pcall(function() mainId = game:GetService("Game").MainPlaceId end)
        end
        if mainId and mainId ~= game.PlaceId then
            local info = MPS:GetProductInfo(mainId)
            if info and info.Name then
                mainName = info.Name
                isSub = true
            end
        end
    end)
    if isSub and mainName then
        GameName = mainName .. "（子服务器：" .. (subName or "?") .. "）"
    else
        GameName = subName or "未知游戏"
    end
end

-----------------------------------------------------------------------
-- 隐蔽宿主：优先 gethui 隐藏容器，其次 CoreGui（游戏读不到），最后 PlayerGui
-----------------------------------------------------------------------
local function GetHost()
    local pg = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local okH, h = pcall(function() return gethui and gethui() end)
    local host = (okH and h) or nil
    if not host then
        local okC, cg = pcall(function() return game:GetService("CoreGui") end)
        host = (okC and cg) or pg
    end
    pcall(function()
        if protect_gui then protect_gui(host)
        elseif syn and syn.protect_gui then syn.protect_gui(host) end
    end)
    return host
end

-----------------------------------------------------------------------
-- 诊断 UI（自建，不依赖任何 UI 库）
-----------------------------------------------------------------------
local MonitorActive = true
local DiagnoseGui = nil

local function MakeCard(parent, title, body)
    local card = New("Frame", {
        Name = "DiagCard",
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = Color3.fromRGB(20, 24, 34),
        BackgroundTransparency = 0.5,
        Parent = parent,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        New("UIStroke", { Color = Color3.fromRGB(70, 84, 118), Transparency = 0.7, Thickness = 1 }),
    })
    New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 8, 0, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 200, 120),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    New("TextLabel", {
        Name = "Body",
        Size = UDim2.new(1, -16, 0, 36),
        Position = UDim2.new(0, 8, 0, 25),
        BackgroundTransparency = 1,
        Text = body,
        TextColor3 = Color3.fromRGB(200, 208, 222),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ClipsDescendants = true,
        Parent = card,
    })
    return card
end

local function SetCardBody(card, text)
    local body = card:FindFirstChild("Body")
    if body then
        body.Text = text
    end
end

local LastErrorText = ""

local function ShowDiagnoseUI(errorText, manual)
    if DiagnoseGui and DiagnoseGui.Parent then
        return
    end
    LastErrorText = errorText or "（无报错信息）"
    local host = GetHost()
    local gui = New("ScreenGui", {
        Name = "DiagPanel",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = host,
    })
    DiagnoseGui = gui

    -- 背景遮罩
    New("Frame", {
        Name = "Bg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(4, 6, 10),
        BackgroundTransparency = 0.45,
        Parent = gui,
    })

    -- 主卡片
    local Card = New("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(500, 600),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(17, 20, 29),
        BackgroundTransparency = 0.12,
        Parent = gui,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 16) }),
        New("UIStroke", { Color = Color3.fromRGB(255, 90, 90), Transparency = 0.55, Thickness = 1 }),
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 26, 34)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 26)),
            }),
            Rotation = 90,
        }),
    })

    -- 标题
    New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        Text = "⚠️  报错诊断",
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Parent = Card,
    })
    -- 副标题（说明触发原因）
    New("TextLabel", {
        Name = "Sub",
        Size = UDim2.new(1, -32, 0, 18),
        Position = UDim2.new(0, 16, 0, 48),
        BackgroundTransparency = 1,
        Text = manual and "手动触发的诊断" or "检测到加载器/主脚本加载出错",
        TextColor3 = Color3.fromRGB(150, 160, 180),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Card,
    })

    -- 信息区容器（从 y=72 开始）
    local InfoArea = New("Frame", {
        Name = "InfoArea",
        Size = UDim2.new(1, -32, 0, 320),
        Position = UDim2.new(0, 16, 0, 74),
        BackgroundTransparency = 1,
        Parent = Card,
    })

    -- 区块 1：北京时间
    local TimeCard = MakeCard(InfoArea, "🕐  北京时间", BeijingTime())
    TimeCard.Position = UDim2.new(0, 0, 0, 0)

    -- 区块 2：当前游戏
    local GameCard = MakeCard(InfoArea, "🎮  当前游戏", GameName .. "（PlaceId: " .. tostring(game.PlaceId) .. "）")
    GameCard.Position = UDim2.new(0, 0, 0, 72)

    -- 区块 3：报错信息（摘录控制台报错）
    local ErrCard = MakeCard(InfoArea, "❌  报错信息", LastErrorText)
    ErrCard.Position = UDim2.new(0, 0, 0, 144)
    ErrCard.Size = UDim2.new(1, 0, 0, 96)

    -- 区块 4：报错诊断
    local DiagCard = MakeCard(InfoArea, "🔍  报错诊断", diagnose(LastErrorText))
    DiagCard.Position = UDim2.new(0, 0, 0, 246)

    -- 按钮行（y=410 起）
    local BtnArea = New("Frame", {
        Name = "BtnArea",
        Size = UDim2.new(1, -32, 0, 46),
        Position = UDim2.new(0, 16, 0, 404),
        BackgroundTransparency = 1,
        Parent = Card,
    })
    local BtnNames = { "复制信息", "发送信息", "重新加载", "关闭脚本" }
    local BtnColors = {
        Color3.fromRGB(70, 90, 130),
        Color3.fromRGB(60, 130, 90),
        Color3.fromRGB(130, 100, 60),
        Color3.fromRGB(150, 60, 60),
    }
    local buttons = {}
    for i = 1, 4 do
        local b = New("TextButton", {
            Name = "Btn" .. i,
            Size = UDim2.new(0, 108, 0, 40),
            Position = UDim2.new(0, (i - 1) * 114, 0, 3),
            BackgroundColor3 = BtnColors[i],
            BackgroundTransparency = 0.3,
            Text = BtnNames[i],
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
            Parent = BtnArea,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })
        buttons[i] = b
    end

    -- 底部状态提示（复制/发送结果）
    local Status = New("TextLabel", {
        Name = "Status",
        Size = UDim2.new(1, -32, 0, 20),
        Position = UDim2.new(0, 16, 0, 462),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(150, 200, 150),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        Parent = Card,
    })

local function ExecutorName()
    local g = (getgenv and getgenv()) or _G
    if g and g.exploit_name then
        return tostring(g.exploit_name)
    end
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name then
            return tostring(name)
        end
    end
    return "未知"
end

    -- 组装诊断全文（复制/发送用）
    local function BuildReport()
        local lines = {
            "【Suture Hub 报错诊断】",
            "时间（北京）: " .. BeijingTime(),
            "游戏: " .. GameName,
            "PlaceId: " .. tostring(game.PlaceId),
            "JobId: " .. tostring(game.JobId or "?"),
            "执行器: " .. ExecutorName(),
            "---- 报错信息 ----",
            LastErrorText,
            "---- 诊断建议 ----",
            diagnose(LastErrorText),
        }
        return table.concat(lines, "\n")
    end

    -- 按钮 1：复制信息
    buttons[1].MouseButton1Click:Connect(function()
        local clip = setclipboard or (getgenv and getgenv().setclipboard)
        local ok = clip and pcall(clip, BuildReport()) or false
        Status.Text = ok and "✅ 已复制到剪贴板" or "❌ 当前环境不支持复制"
    end)

    -- 按钮 2：发送信息（复用反馈接口）
    buttons[2].MouseButton1Click:Connect(function()
        Status.Text = "⏳ 发送中…"
        Spawn(function()
            local HS = game:GetService("HttpService")
            local body = {
                message = "[报错诊断] " .. BuildReport(),
                username = "报错诊断",
                userId = "0",
                placeId = tostring(game.PlaceId),
                jobId = tostring(game.JobId or ""),
                gameName = GameName,
                ip = "",
                timestamp = os.time(),
                nonce = "diag" .. tostring(math.random(100000000, 999999999)),
                token = FEEDBACK_TOKEN,
            }
            local ok, res = pcall(function()
                return HS:PostAsync(FEEDBACK_API, HS:JSONEncode(body), Enum.HttpContentType.ApplicationJson, false)
            end)
            if ok and type(res) == "string" and res:find('"ok":true', 1, true) then
                Status.Text = "✅ 已发送给维护者"
            else
                Status.Text = "❌ 发送失败：" .. tostring(ok and res or "网络异常")
            end
        end)
    end)

    -- 按钮 3：重新加载（重新执行加载器）
    buttons[3].MouseButton1Click:Connect(function()
        Status.Text = "⏳ 正在重新加载…"
        Spawn(function()
            local ok, res = pcall(function()
                local src = game:HttpGet(LOADER_URL)
                local fn = loadstring(src)
                if not fn then
                    error("loadstring 失败")
                end
                fn()
                return true
            end)
            if ok then
                Status.Text = "✅ 已重新加载"
                -- 稍后由加载器自行接管；若 3 秒内无新错误保持面板
            else
                Status.Text = "❌ 重新加载失败：" .. tostring(res)
            end
        end)
    end)

    -- 按钮 4：关闭脚本（销毁诊断 UI 并停止监控）
    buttons[4].MouseButton1Click:Connect(function()
        MonitorActive = false
        if DiagnoseGui then
            pcall(function() DiagnoseGui:Destroy() end)
            DiagnoseGui = nil
        end
    end)

    -- 入场动画
    pcall(function()
        local TweenService = game:GetService("TweenService")
        Card.Position = UDim2.new(0.5, 0, 0.55, 0)
        TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
    end)

    -- 异步补游戏名（不影响弹窗）
    Spawn(function()
        if GameName:find("获取中") then
            FetchGameName()
            SetCardBody(GameCard, GameName .. "（PlaceId: " .. tostring(game.PlaceId) .. "）")
        end
    end)
end

-- 对外暴露：其他脚本可手动触发诊断
local function Expose()
    local g = (getgenv and getgenv()) or _G
    g.ShowDiagnose = function(errText, manual)
        ShowDiagnoseUI(errText, manual)
    end
end

-----------------------------------------------------------------------
-- 常驻监控：轮询 LogService，出现加载相关报错 → 自动弹出诊断
-----------------------------------------------------------------------
local function IsLoaderRelated(msg)
    local low = string.lower(tostring(msg or ""))
    for _, kw in ipairs(LOAD_KEYWORDS) do
        if string.find(low, string.lower(kw), 1, true) then
            return true
        end
    end
    return false
end

Spawn(function()
    local LogService = game:GetService("LogService")
    local lastCount = 0
    while MonitorActive do
        Wait(1.5)
        local ok, log = pcall(function()
            return LogService:GetLogHistory()
        end)
        if ok and type(log) == "table" then
            if #log > lastCount and lastCount > 0 then
                local hit = nil
                for i = lastCount + 1, #log do
                    local entry = log[i]
                    local m = tostring(entry and entry.message or "")
                    local mt = entry and entry.messageType
                    local isErr = (mt == Enum.MessageType.MessageError) or (mt == Enum.MessageType.MessageWarning)
                    if isErr and IsLoaderRelated(m) then
                        hit = m
                        break
                    end
                end
                if hit then
                    -- 只弹一次，避免反复弹
                    if not (DiagnoseGui and DiagnoseGui.Parent) then
                        ShowDiagnoseUI(hit, false)
                    end
                end
            end
            lastCount = #log
        end
    end
end)

-- 初始化：暴露接口 + 拉游戏名
Spawn(function()
    Expose()
    FetchGameName()
end)

-- 静默启动：不输出任何控制台内容（用户无感）

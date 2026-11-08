--// Suture Hub Feedback | WindUI 原生顶栏版（防滥用版 v2）
--// 改动：
--//   1. 新增 ip 参数：HttpService:GetIPAddress() 获取反馈人 IP（服务器侧另有 CF-Connecting-IP 交叉验证）
--//   2. 新增 token 参数：防完全裸请求（与 Worker 端 AUTH_TOKEN 一致）
--//   3. 新增 timestamp + nonce：防重放（Worker 端校验时间新鲜度）
--//   4. 客户端频率限制：两次发送间隔 >= 20 秒
--//   5. 反馈内容首尾去空格后再校验（防纯空白刷屏）
local cfg = getgenv().SutureHubFeedback or {}

local WindUI = cfg.WindUI
local Window = cfg.Window

-- ★ 客户端令牌（与 Worker 环境变量 AUTH_TOKEN 保持一致；换令牌时两边一起换）
local AUTH_TOKEN = cfg.Token or "suture_fb_2025_zh"

local function notify(t, c, i, d)
    if cfg.Notify then
        return cfg.Notify(t, c, i, d)
    end

    if WindUI and WindUI.Notify then
        pcall(function()
            WindUI:Notify({
                Title = t,
                Content = c or "",
                Icon = i or "bell",
                Duration = d or 3
            })
        end)
    else
        warn(t, c)
    end
end

local function cleanUrl(u)
    u = tostring(u or ""):gsub("%s+", "")
    if u == "" then return "" end
    if not u:match("^https?://") then
        u = "https://" .. u
    end
    return u
end

local API = cleanUrl(cfg.API or cfg.Url or cfg.FeedbackAPI or getgenv().FeedbackAPI or _G.FeedbackAPI)

if API == "" then
    return notify("反馈模块", "API为空，请检查配置", "triangle-alert", 4)
end

if not Window then
    return notify("反馈模块", "缺少 Window = win", "triangle-alert", 4)
end

if not Window.CreateTopbarButton then
    return notify("反馈模块", "当前WindUI不支持顶栏按钮", "triangle-alert", 4)
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local busy = false
local FeedbackTab = nil
local FeedbackText = ""

-- ★ 客户端频率限制（秒）
local RATE_LIMIT_SECONDS = 20
local lastSentAt = 0

-- ★ 获取反馈人 IP（pcall 兜底：executor 屏蔽时返回空串，Worker 端仍会记录真实 IP）
local function getIP()
    local ok, ip = pcall(function()
        return HttpService:GetIPAddress()
    end)
    return ok and tostring(ip or "") or ""
end

local function rateLimited()
    local now = os.time()
    if now - lastSentAt < RATE_LIMIT_SECONDS then
        return true, (RATE_LIMIT_SECONDS - (now - lastSentAt))
    end
    lastSentAt = now
    return false, 0
end

local function requestFunc()
    return (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
end

local function enc(v)
    return HttpService:UrlEncode(tostring(v or ""))
end

-- ★ 组装带防滥用参数的数据表（POST body 与 GET query 共用）
local function buildPayload(msg)
    return {
        message = msg,
        username = lp.Name,
        displayName = lp.DisplayName,
        userId = lp.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        gameName = game.Name,
        ip = getIP(),
        timestamp = os.time(),
        nonce = HttpService:GenerateGUID(false),
        token = AUTH_TOKEN
    }
end

local function getUrl(p)
    local sep = API:find("?", 1, true) and "&" or "?"

    return API .. sep
        .. "message=" .. enc(p.message)
        .. "&username=" .. enc(p.username)
        .. "&displayName=" .. enc(p.displayName)
        .. "&userId=" .. enc(p.userId)
        .. "&placeId=" .. enc(p.placeId)
        .. "&jobId=" .. enc(p.jobId)
        .. "&gameName=" .. enc(p.gameName)
        .. "&ip=" .. enc(p.ip)
        .. "&timestamp=" .. enc(p.timestamp)
        .. "&nonce=" .. enc(p.nonce)
        .. "&token=" .. enc(p.token)
end

local function okStatus(res)
    local code = res and (res.StatusCode or res.Status or res.status_code) or 0
    return code >= 200 and code < 300
end

local function callRequest(method, url, body)
    local req = requestFunc()

    if not req then
        return false, "当前执行器不支持 request"
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "SutureHub"
    }

    local data = {
        Url = url,
        url = url,
        Method = method,
        method = method,
        Headers = headers,
        headers = headers,
        Body = body,
        body = body
    }

    local ok, res = pcall(function()
        return req(data)
    end)

    if ok and okStatus(res) then
        return true
    end

    if ok then
        local code = res and (res.StatusCode or res.Status or res.status_code) or "?"
        return false, "HTTP " .. tostring(code)
    end

    return false, tostring(res)
end

local function sendFeedback(msg)
    local p = buildPayload(msg)

    -- POST 优先（JSON body，含 ip/timestamp/nonce/token）
    local body = HttpService:JSONEncode(p)

    local ok1 = callRequest("POST", API, body)
    if ok1 then return true end

    -- GET 降级（query 同样携带全部防滥用参数）
    local url = getUrl(p)

    local ok2 = callRequest("GET", url)
    if ok2 then return true end

    local ok3, err3 = pcall(function()
        return game:HttpGet(url)
    end)

    if ok3 then return true end

    return false, tostring(err3)
end

local function selectFeedbackTab()
    if FeedbackTab and FeedbackTab.Select then
        local ok = pcall(function()
            FeedbackTab:Select()
        end)
        if ok then return true end
    end

    if Window.SelectTab then
        local ok = pcall(function()
            Window:SelectTab(FeedbackTab)
        end)
        if ok then return true end
    end

    return false
end

local function createFeedbackTab()
    if FeedbackTab then
        if not selectFeedbackTab() then
            notify("反馈模块", "请在左侧点击反馈页", "info", 3)
        end
        return
    end

    FeedbackTab = Window:Tab({
        Title = "反馈",
        Icon = "message-square",
        Locked = false
    })

    FeedbackTab:Paragraph({
        Title = "反馈",
        Desc = "这里可以向作者发送建议或Bug反馈。"
    })

    FeedbackTab:Input({
        Title = "反馈内容",
        Desc = "输入你想反馈的问题或建议",
        Type = "Textarea",
        Placeholder = "例如：按钮失效、脚本打不开、UI显示异常等等\n或许你还可以向作者提出想要哪个游戏的脚本。。[记得发游戏英文名]",
        Value = "",
        Callback = function(v)
            FeedbackText = tostring(v or "")
        end
    })

    FeedbackTab:Button({
        Title = "发送反馈",
        Desc = "将反馈发送给作者",
        Icon = "send",
        Callback = function()
            if busy then
                return notify("反馈", "正在发送中", "loader", 2)
            end

            -- ★ 内容去首尾空格后再校验（防纯空白刷屏）
            local text = tostring(FeedbackText or ""):gsub("^%s+", ""):gsub("%s+$", "")

            if #text < 2 then
                return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
            end

            -- ★ 客户端频率限制
            local limited, waitSec = rateLimited()
            if limited then
                return notify("反馈", ("发送过于频繁，请 %d 秒后再试"):format(waitSec), "triangle-alert", 3)
            end

            busy = true
            local ok, err = sendFeedback(text)
            busy = false

            if ok then
                FeedbackText = ""
                notify("反馈成功", "已发送给作者", "check", 3)
            else
                notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
            end
        end
    })

    if not selectFeedbackTab() then
        notify("反馈模块", "反馈页已创建，请在左侧点击反馈", "info", 3)
    end
end

Window:CreateTopbarButton("suture-feedback", "message-square", function()
    createFeedbackTab()
end, 989)

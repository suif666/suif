--// Suture Hub Feedback | WindUI 原生精简版

local cfg = getgenv().SutureHubFeedback or {}

local WindUI = cfg.WindUI
local Tab = cfg.Tab or cfg.ParentTab

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

    if u == "" then
        return ""
    end

    if not u:match("^https?://") then
        u = "https://" .. u
    end

    return u
end

local API = cleanUrl(cfg.API or cfg.Url or cfg.FeedbackAPI or getgenv().FeedbackAPI or _G.FeedbackAPI)

if API == "" then
    return notify("反馈模块", "API为空，请检查主脚本配置", "triangle-alert", 5)
end

if not Tab then
    return notify("反馈模块", "Tab为空，请检查 settingsTab", "triangle-alert", 5)
end

if getgenv().SutureHubFeedbackTab == Tab then
    return
end

getgenv().SutureHubFeedbackTab = Tab

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local text = ""
local busy = false

local function requestFunc()
    return (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
end

local function enc(v)
    return HttpService:UrlEncode(tostring(v or ""))
end

local function getUrl(msg)
    local sep = API:find("?", 1, true) and "&" or "?"

    return API .. sep
        .. "message=" .. enc(msg)
        .. "&username=" .. enc(lp.Name)
        .. "&displayName=" .. enc(lp.DisplayName)
        .. "&userId=" .. enc(lp.UserId)
        .. "&placeId=" .. enc(game.PlaceId)
        .. "&jobId=" .. enc(game.JobId)
        .. "&gameName=" .. enc(game.Name)
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

    local data = {
        Url = url,
        url = url,

        Method = method,
        method = method,

        Headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "SutureHub"
        },
        headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "SutureHub"
        },

        Body = body,
        body = body
    }

    local ok, res = pcall(function()
        return req(data)
    end)

    if ok and okStatus(res) then
        return true
    end

    return false, ok and tostring(res and res.Body or "状态码异常") or tostring(res)
end

local function send(msg)
    local body = HttpService:JSONEncode({
        message = msg,
        username = lp.Name,
        displayName = lp.DisplayName,
        userId = lp.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        gameName = game.Name
    })

    local ok1 = callRequest("POST", API, body)
    if ok1 then
        return true
    end

    local url = getUrl(msg)

    local ok2 = callRequest("GET", url)
    if ok2 then
        return true
    end

    local ok3, err3 = pcall(function()
        return game:HttpGet(url)
    end)

    if ok3 then
        return true
    end

    return false, tostring(err3)
end

pcall(function()
    Tab:Divider({
        Title = "反馈"
    })
end)

Tab:Input({
    Title = "反馈内容",
    Desc = "输入你想反馈的问题或建议",
    Placeholder = "例如：按钮失效、脚本打不开、UI显示异常...",
    Value = "",
    Callback = function(v)
        text = tostring(v or "")
    end
})

Tab:Button({
    Title = "发送反馈",
    Desc = "将反馈发送给作者",
    Icon = "send",
    Callback = function()
        if busy then
            return notify("反馈", "正在发送中", "loader", 2)
        end

        if #text < 2 then
            return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
        end

        busy = true

        local ok, err = send(text)

        busy = false

        if ok then
            text = ""
            notify("反馈成功", "已发送给作者", "check", 3)
        else
            notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
        end
    end
})

notify("反馈模块", "已加载到设置页", "check", 2)

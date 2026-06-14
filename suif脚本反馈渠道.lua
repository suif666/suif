--// Suture Hub Feedback | WindUI 原生精简版
local cfg = getgenv().SutureHubFeedback or {}

local API = tostring(cfg.API or ""):gsub("%s+", "")

if API ~= "" and not API:match("^https?://") then
    API = "https://" .. API
end

local WindUI = cfg.WindUI
local Tab = cfg.Tab or cfg.ParentTab

local notify = cfg.Notify or function(t, c, i, d)
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

if not API or not Tab then
    return notify("反馈模块", "缺少 API 或 Tab", "triangle-alert", 4)
end

if getgenv().SutureHubFeedbackTab == Tab then return end
getgenv().SutureHubFeedbackTab = Tab

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer
local text, busy = "", false

local function requestFunc()
    return (syn and syn.request) or (http and http.request) or http_request or request
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
    local code = res and (res.StatusCode or res.Status) or 0
    return code >= 200 and code < 300
end

local function send(msg)
    local req = requestFunc()
    local body = HttpService:JSONEncode({
        message = msg,
        username = lp.Name,
        displayName = lp.DisplayName,
        userId = lp.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        gameName = game.Name
    })

    if req then
        local ok, res = pcall(req, {
            Url = API,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["User-Agent"] = "SutureHub"},
            Body = body
        })
        if ok and okStatus(res) then return true end

        local ok2, res2 = pcall(req, {
            Url = getUrl(msg),
            Method = "GET",
            Headers = {["User-Agent"] = "SutureHub"}
        })
        if ok2 and okStatus(res2) then return true end
    end

    local ok3, err3 = pcall(function()
        game:HttpGet(getUrl(msg))
    end)
    return ok3, err3
end

pcall(function()
    Tab:Divider({Title = "反馈"})
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
        if busy then return notify("反馈", "正在发送中", "loader", 2) end
        if #text < 2 then return notify("反馈失败", "请先输入内容", "triangle-alert", 3) end

        busy = true
        local ok, err = send(text)
        busy = false

        if ok then
            text = ""
            notify("反馈成功", "已发送给作者", "check", 3)
        else
            notify("反馈失败", tostring(err or "ConnectFail"), "triangle-alert", 5)
        end
    end
})

notify("反馈模块", "已加载到设置页", "check", 2)

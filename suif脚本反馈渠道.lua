--// Suture Hub Feedback | WindUI 独立窗口版
--// 用法：主脚本传入 getgenv().SutureHubFeedback = { API, WindUI, Window, Notify }

local cfg = getgenv().SutureHubFeedback or {}

local API = tostring(cfg.API or cfg.Url or cfg.FeedbackAPI or ""):gsub("%s+", "")
local WindUI = cfg.WindUI
local MainWindow = cfg.Window

if API ~= "" and not API:match("^https?://") then
    API = "https://" .. API
end

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

if not WindUI then
    return notify("反馈模块", "缺少 WindUI", "triangle-alert", 4)
end

if not MainWindow then
    return notify("反馈模块", "缺少主窗口 Window", "triangle-alert", 4)
end

if API == "" then
    return notify("反馈模块", "API为空", "triangle-alert", 4)
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local feedbackWindow = nil
local feedbackText = ""
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

local function buildGetUrl(msg)
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

    local headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "SutureHub"
    }

    local ok, res = pcall(function()
        return req({
            Url = url,
            url = url,

            Method = method,
            method = method,

            Headers = headers,
            headers = headers,

            Body = body,
            body = body
        })
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

    local getUrl = buildGetUrl(msg)

    local ok2 = callRequest("GET", getUrl)
    if ok2 then
        return true
    end

    local ok3, err3 = pcall(function()
        return game:HttpGet(getUrl)
    end)

    if ok3 then
        return true
    end

    return false, tostring(err3)
end

local function closeFeedbackWindow()
    if not feedbackWindow then
        return
    end

    local closed = false

    pcall(function()
        if feedbackWindow.Close then
            feedbackWindow:Close()
            closed = true
        end
    end)

    pcall(function()
        if not closed and feedbackWindow.Destroy then
            feedbackWindow:Destroy()
            closed = true
        end
    end)

    feedbackWindow = nil
    feedbackText = ""
end

local function showFeedbackWindow()
    if feedbackWindow then
        notify("反馈", "反馈窗口已打开", "message-square", 2)
        return
    end

    feedbackWindow = WindUI:CreateWindow({
        Title = "反馈",
        Icon = "message-square",
        Author = "Suture Hub",
        Folder = "SutureHubFeedback",

        Size = UDim2.fromOffset(420, 310),
        MinSize = Vector2.new(380, 260),
        MaxSize = Vector2.new(520, 420),

        Transparent = true,
        Theme = "Dark",
        Resizable = true,
        SideBarWidth = 130,
        HideSearchBar = true,
        ScrollBarEnabled = true,
        NewElements = true
    })

    local tab = feedbackWindow:Tab({
        Title = "反馈",
        Icon = "send",
        Locked = false
    })

    tab:Paragraph({
        Title = "反馈说明",
        Desc = "这里可以向作者发送问题、建议或 Bug 反馈。"
    })

    tab:Input({
        Title = "反馈内容",
        Desc = "请输入你想反馈的问题或建议",
        Placeholder = "例如：按钮失效、脚本打不开、UI显示异常...",
        Value = "",
        Callback = function(v)
            feedbackText = tostring(v or "")
        end
    })

    tab:Button({
        Title = "发送反馈",
        Desc = "将反馈发送给作者",
        Icon = "send",
        Callback = function()
            if busy then
                return notify("反馈", "正在发送中", "loader", 2)
            end

            if #feedbackText < 2 then
                return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
            end

            busy = true

            local ok, err = sendFeedback(feedbackText)

            busy = false

            if ok then
                feedbackText = ""
                notify("反馈成功", "已发送给作者", "check", 3)
            else
                notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
            end
        end
    })

    tab:Button({
        Title = "关闭反馈窗口",
        Desc = "关闭当前反馈窗口",
        Icon = "x",
        Callback = closeFeedbackWindow
    })

    notify("反馈", "反馈窗口已打开", "message-square", 2)
end

local function createEntry()
    if getgenv().SutureHubFeedbackEntryCreated then
        return
    end

    getgenv().SutureHubFeedbackEntryCreated = true

    if MainWindow.CreateTopbarButton then
        MainWindow:CreateTopbarButton("suture-feedback", "message-square", function()
            showFeedbackWindow()
        end, 989)

        notify("反馈模块", "顶栏入口已加载", "check", 2)
        return
    end

    local tab = MainWindow:Tab({
        Title = "反馈入口",
        Icon = "message-square",
        Locked = false
    })

    tab:Button({
        Title = "打开反馈窗口",
        Desc = "点击后打开独立反馈窗口",
        Icon = "message-square",
        Callback = showFeedbackWindow
    })

    notify("反馈模块", "反馈入口已加载", "check", 2)
end

createEntry()

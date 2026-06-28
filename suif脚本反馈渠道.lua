--// Suture Hub Feedback | 独立 WindUI 窗口修复版
local cfg = getgenv().SutureHubFeedback or {}

local WindUI = cfg.WindUI
local MainWindow = cfg.Window

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

if not WindUI then
    return notify("反馈模块", "缺少 WindUI", "triangle-alert", 4)
end

if not MainWindow then
    return notify("反馈模块", "缺少 Window = win", "triangle-alert", 4)
end

if not MainWindow.CreateTopbarButton then
    return notify("反馈模块", "当前 WindUI 不支持顶栏按钮", "triangle-alert", 4)
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local busy = false
local FeedbackWindow = nil
local FeedbackTab = nil
local FeedbackText = ""

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
    if ok1 then return true end

    local url = getUrl(msg)

    local ok2 = callRequest("GET", url)
    if ok2 then return true end

    local ok3, err3 = pcall(function()
        return game:HttpGet(url)
    end)

    if ok3 then return true end

    return false, tostring(err3)
end

local function showFeedbackWindow()
    if FeedbackWindow then
        pcall(function()
            if FeedbackWindow.Show then
                FeedbackWindow:Show()
            end
        end)

        pcall(function()
            if FeedbackTab and FeedbackTab.Select then
                FeedbackTab:Select()
            end
        end)

        return
    end

    FeedbackWindow = WindUI:CreateWindow({
        Title = "反馈",
        Icon = "message-square",
        Author = "Suture Hub",
        Folder = "SutureHubFeedback",
        Size = UDim2.fromOffset(420, 300),
        MinSize = Vector2.new(360, 260),
        MaxSize = Vector2.new(520, 380),
        Transparent = true,
        Theme = "Dark",
        Resizable = true,
        SideBarWidth = 120,
        HideSearchBar = true,
        ScrollBarEnabled = true,
        NewElements = true
    })

    FeedbackTab = FeedbackWindow:Tab({
        Title = "反馈",
        Icon = "message-square",
        Locked = false
    })

    FeedbackTab:Paragraph({
        Title = "反馈",
        Desc = "这里可以向作者发送建议或 Bug 反馈。"
    })

    FeedbackTab:Input({
        Title = "反馈内容",
        Desc = "输入你想反馈的问题或建议",
        Type = "Textarea",
        Placeholder = "例如：按钮失效、脚本打不开、UI显示异常等等\n也可以提出想要哪个游戏的脚本，记得发游戏英文名。",
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

            if #FeedbackText < 2 then
                return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
            end

            busy = true
            local ok, err = sendFeedback(FeedbackText)
            busy = false

            if ok then
                FeedbackText = ""
                notify("反馈成功", "已发送给作者", "check", 3)
            else
                notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
            end
        end
    })

    pcall(function()
        if FeedbackWindow.Show then
            FeedbackWindow:Show()
        end
    end)

    pcall(function()
        if FeedbackTab.Select then
            FeedbackTab:Select()
        end
    end)
end

MainWindow:CreateTopbarButton("suture-feedback", "message-square", function()
    local ok, err = pcall(showFeedbackWindow)
    if not ok then
        warn("反馈窗口打开失败:", err)
        notify("反馈模块", "反馈窗口打开失败", "triangle-alert", 3)
    end
end, 989)

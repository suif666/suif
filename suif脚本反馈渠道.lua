--// Suture Hub WindUI 原生反馈模块
--// 作者注释位：你的B站UID

local cfg = getgenv().SutureHubFeedback or {}

local API = cfg.API
local WindUI = cfg.WindUI
local ParentTab = cfg.ParentTab

if not API or API == "" then
    warn("反馈模块加载失败：缺少 API")
    return
end

if not ParentTab then
    warn("反馈模块加载失败：缺少 ParentTab")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local FeedbackText = ""

local function getRequest()
    return syn and syn.request
        or http and http.request
        or http_request
        or request
end

local function notify(title, content, icon, duration)
    if WindUI then
        pcall(function()
            WindUI:Notify({
                Title = title,
                Content = content or "",
                Icon = icon or "message-square",
                Duration = duration or 3
            })
        end)
    else
        warn(title, content)
    end
end

local function sendFeedback(message)
    local req = getRequest()

    if not req then
        notify("反馈失败", "当前执行器不支持 request/http_request", "triangle-alert", 4)
        return false
    end

    local body = HttpService:JSONEncode({
        message = message,
        username = LocalPlayer.Name,
        displayName = LocalPlayer.DisplayName,
        userId = LocalPlayer.UserId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        gameName = game.Name,
        time = os.date("%Y-%m-%d %H:%M:%S")
    })

    local ok, res = pcall(function()
        return req({
            Url = API,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)

    if not ok then
        notify("反馈失败", tostring(res), "triangle-alert", 5)
        warn("反馈请求失败:", res)
        return false
    end

    local status = res.StatusCode or res.Status or 0
    local responseBody = tostring(res.Body or "")

    if status >= 200 and status < 300 then
        notify("反馈成功", "你的反馈已发送", "check", 3)
        return true
    else
        notify("反馈失败", "状态码：" .. tostring(status), "triangle-alert", 5)
        warn("反馈状态码:", status)
        warn("反馈返回内容:", responseBody)
        return false
    end
end

ParentTab:Divider({
    Title = "反馈"
})

ParentTab:Input({
    Title = "反馈内容",
    Desc = "输入你想反馈的问题或建议",
    Placeholder = "例如：某个按钮失效、某个脚本打不开、UI显示异常...",
    Value = "",
    Callback = function(value)
        FeedbackText = tostring(value or "")
    end
})

ParentTab:Button({
    Title = "发送反馈",
    Desc = "将反馈发送给作者",
    Icon = "send",
    Callback = function()
        if FeedbackText == "" or #FeedbackText < 2 then
            notify("反馈失败", "请先输入反馈内容", "triangle-alert", 3)
            return
        end

        sendFeedback(FeedbackText)
    end
})

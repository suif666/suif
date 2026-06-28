--// Suture Hub Feedback | 无左侧Tab版
local cfg = getgenv().SutureHubFeedback or {}

local WindUI = cfg.WindUI
local Window = cfg.Window

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
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer
local busy = false
local gui
local panel
local inputBox

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

local function createFeedbackPanel()
    if gui and gui.Parent then
        return
    end

    local old = CoreGui:FindFirstChild("SutureFeedbackPanel")
    if old then
        old:Destroy()
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "SutureFeedbackPanel"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 330, 0, 210)
    panel.Position = UDim2.new(0.5, -165, 0.5, -105)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    panel.Visible = false
    panel.ZIndex = 100
    panel.Parent = gui

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(80, 160, 255)
    stroke.Transparency = 0.15
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 36)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "反馈"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 101
    title.Parent = panel

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -40, 0, 8)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 24
    close.Font = Enum.Font.GothamBold
    close.ZIndex = 101
    close.Parent = panel

    inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -28, 0, 105)
    inputBox.Position = UDim2.new(0, 14, 0, 50)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = "请输入反馈内容..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    inputBox.Text = ""
    inputBox.TextWrapped = true
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.TextYAlignment = Enum.TextYAlignment.Top
    inputBox.ClearTextOnFocus = false
    inputBox.MultiLine = true
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.ZIndex = 101
    inputBox.Parent = panel

    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 10)

    local send = Instance.new("TextButton")
    send.Size = UDim2.new(1, -28, 0, 36)
    send.Position = UDim2.new(0, 14, 1, -46)
    send.BackgroundColor3 = Color3.fromRGB(45, 120, 255)
    send.TextColor3 = Color3.fromRGB(255, 255, 255)
    send.Text = "发送反馈"
    send.TextSize = 15
    send.Font = Enum.Font.GothamBold
    send.ZIndex = 101
    send.Parent = panel

    Instance.new("UICorner", send).CornerRadius = UDim.new(0, 10)

    close.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    send.MouseButton1Click:Connect(function()
        if busy then
            return notify("反馈", "正在发送中", "loader", 2)
        end

        local text = tostring(inputBox.Text or "")

        if #text < 2 then
            return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
        end

        busy = true
        send.Text = "发送中..."

        local ok, err = sendFeedback(text)

        busy = false
        send.Text = "发送反馈"

        if ok then
            inputBox.Text = ""
            panel.Visible = false
            notify("反馈成功", "已发送给作者", "check", 3)
        else
            notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
        end
    end)
end

local function toggleFeedbackPanel()
    createFeedbackPanel()

    if panel then
        panel.Visible = not panel.Visible
    end
end

Window:CreateTopbarButton("suture-feedback", "message-square", function()
    toggleFeedbackPanel()
end, 989)

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

local CoreGui = game:GetService("CoreGui")
local TitleText = cfg.Title or "Suture Hub"

local function getUiContainer()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end

    return CoreGui
end

local function findWindUIRoot()
    local container = getUiContainer()
    local list = {}

    for _, v in ipairs(container:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and tostring(v.Text):find(TitleText, 1, true) then
            local p = v.Parent

            while p and not p:IsA("ScreenGui") do
                if p:IsA("Frame") or p:IsA("ImageLabel") or p:IsA("CanvasGroup") then
                    table.insert(list, p)
                end
                p = p.Parent
            end
        end
    end

    local best, area = nil, 0

    for _, v in ipairs(list) do
        local s = v.AbsoluteSize
        local a = s.X * s.Y

        if a > area and s.X > 260 and s.Y > 80 then
            best = v
            area = a
        end
    end

    return best
end

local Root

for _ = 1, 40 do
    Root = findWindUIRoot()
    if Root then
        break
    end
    task.wait(0.1)
end

if not Root then
    return notify("反馈模块", "未找到WindUI窗口", "triangle-alert", 4)
end

if Root:FindFirstChild("SutureFeedbackButton") then
    Root.SutureFeedbackButton:Destroy()
end

if Root:FindFirstChild("SutureFeedbackPanel") then
    Root.SutureFeedbackPanel:Destroy()
end

local Btn = Instance.new("TextButton")
Btn.Name = "SutureFeedbackButton"
Btn.Parent = Root
Btn.Size = UDim2.fromOffset(32, 32)
Btn.AnchorPoint = Vector2.new(1, 0)
Btn.Position = UDim2.new(1, cfg.ButtonX or -150, 0, cfg.ButtonY or 18)
Btn.BackgroundTransparency = 1
Btn.Text = "✎"
Btn.TextSize = 21
Btn.Font = Enum.Font.GothamBold
Btn.TextColor3 = Color3.fromRGB(255, 220, 60)
Btn.ZIndex = 999

local Panel = Instance.new("Frame")
Panel.Name = "SutureFeedbackPanel"
Panel.Parent = Root
Panel.Size = UDim2.fromOffset(430, 255)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
Panel.BackgroundTransparency = 0.03
Panel.Visible = false
Panel.ZIndex = 1000

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Parent = Panel
Stroke.Color = Color3.fromRGB(255, 220, 60)
Stroke.Thickness = 1.4
Stroke.Transparency = 0.25

local Title = Instance.new("TextLabel")
Title.Parent = Panel
Title.Size = UDim2.new(1, -60, 0, 42)
Title.Position = UDim2.fromOffset(18, 8)
Title.BackgroundTransparency = 1
Title.Text = "反馈"
Title.TextColor3 = Color3.fromRGB(255, 235, 90)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 1001

local Close = Instance.new("TextButton")
Close.Parent = Panel
Close.Size = UDim2.fromOffset(36, 36)
Close.Position = UDim2.new(1, -46, 0, 9)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(180, 180, 180)
Close.TextSize = 28
Close.Font = Enum.Font.GothamBold
Close.ZIndex = 1001

local Box = Instance.new("TextBox")
Box.Parent = Panel
Box.Size = UDim2.new(1, -36, 0, 125)
Box.Position = UDim2.fromOffset(18, 58)
Box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Box.TextColor3 = Color3.fromRGB(240, 240, 240)
Box.PlaceholderText = "请输入反馈内容..."
Box.PlaceholderColor3 = Color3.fromRGB(145, 145, 145)
Box.Text = ""
Box.TextSize = 16
Box.Font = Enum.Font.Gotham
Box.TextXAlignment = Enum.TextXAlignment.Left
Box.TextYAlignment = Enum.TextYAlignment.Top
Box.ClearTextOnFocus = false
Box.MultiLine = true
Box.ZIndex = 1001

Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 10)

local Send = Instance.new("TextButton")
Send.Parent = Panel
Send.Size = UDim2.new(1, -36, 0, 42)
Send.Position = UDim2.new(0, 18, 1, -56)
Send.BackgroundColor3 = Color3.fromRGB(255, 220, 55)
Send.Text = "发送反馈"
Send.TextColor3 = Color3.fromRGB(20, 20, 20)
Send.TextSize = 17
Send.Font = Enum.Font.GothamBold
Send.ZIndex = 1001

Instance.new("UICorner", Send).CornerRadius = UDim.new(0, 10)

Btn.MouseButton1Click:Connect(function()
    Panel.Visible = not Panel.Visible
end)

Close.MouseButton1Click:Connect(function()
    Panel.Visible = false
end)

Send.MouseButton1Click:Connect(function()
    if busy then
        return notify("反馈", "正在发送中", "loader", 2)
    end

    local msg = tostring(Box.Text or "")

    if #msg < 2 then
        return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
    end

    busy = true
    Send.Text = "发送中..."

    local ok, err = send(msg)

    busy = false
    Send.Text = "发送反馈"

    if ok then
        Box.Text = ""
        Panel.Visible = false
        notify("反馈成功", "已发送给作者", "check", 3)
    else
        notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
    end
end)

notify("反馈模块", "右上角入口已加载", "check", 2)

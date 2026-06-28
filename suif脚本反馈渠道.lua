--// Suture Hub Feedback | WindUI窗口优先 + 失败自动降级版
--// 说明：优先尝试旧版“点击后创建独立 WindUI 窗口”。如果 WindUI:CreateWindow 创建失败，自动改用独立反馈面板。

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
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local busy = false

local FeedbackWindow = nil
local FeedbackTab = nil
local FeedbackText = ""

local FallbackGui = nil
local FallbackPanel = nil
local FallbackBox = nil

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

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

local function createFallbackPanel()
    if FallbackGui and FallbackGui.Parent then
        return
    end

    local old = CoreGui:FindFirstChild("SutureFeedbackFallback")
    if old then
        old:Destroy()
    end

    FallbackGui = Instance.new("ScreenGui")
    FallbackGui.Name = "SutureFeedbackFallback"
    FallbackGui.ResetOnSpawn = false
    FallbackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FallbackGui.Parent = CoreGui

    FallbackPanel = Instance.new("Frame")
    FallbackPanel.Name = "Panel"
    FallbackPanel.Size = UDim2.new(0, 420, 0, 270)
    FallbackPanel.Position = UDim2.new(0.5, -210, 0.5, -135)
    FallbackPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    FallbackPanel.BorderSizePixel = 0
    FallbackPanel.Visible = false
    FallbackPanel.Active = true
    FallbackPanel.ZIndex = 500
    FallbackPanel.Parent = FallbackGui

    Instance.new("UICorner", FallbackPanel).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Border"
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 160, 255)
    stroke.Transparency = 0.05
    stroke.Parent = FallbackPanel

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 180))
    })
    gradient.Rotation = 35
    gradient.Parent = stroke

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 501
    titleBar.Parent = FallbackPanel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -54, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "反馈"
    title.TextColor3 = Color3.fromRGB(245, 245, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 502
    title.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 32, 0, 32)
    close.Position = UDim2.new(1, -40, 0, 5)
    close.BackgroundTransparency = 1
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 24
    close.Font = Enum.Font.GothamBold
    close.ZIndex = 503
    close.Parent = titleBar

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -28, 0, 28)
    desc.Position = UDim2.new(0, 14, 0, 42)
    desc.BackgroundTransparency = 1
    desc.Text = "这里可以向作者发送建议或 Bug 反馈。"
    desc.TextColor3 = Color3.fromRGB(165, 165, 180)
    desc.TextSize = 13
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 501
    desc.Parent = FallbackPanel

    FallbackBox = Instance.new("TextBox")
    FallbackBox.Size = UDim2.new(1, -28, 0, 125)
    FallbackBox.Position = UDim2.new(0, 14, 0, 76)
    FallbackBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    FallbackBox.BorderSizePixel = 0
    FallbackBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    FallbackBox.PlaceholderText = "例如：按钮失效、脚本打不开、UI显示异常等等"
    FallbackBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 155)
    FallbackBox.Text = ""
    FallbackBox.TextWrapped = true
    FallbackBox.TextXAlignment = Enum.TextXAlignment.Left
    FallbackBox.TextYAlignment = Enum.TextYAlignment.Top
    FallbackBox.ClearTextOnFocus = false
    FallbackBox.MultiLine = true
    FallbackBox.Font = Enum.Font.Gotham
    FallbackBox.TextSize = 14
    FallbackBox.ZIndex = 501
    FallbackBox.Parent = FallbackPanel

    Instance.new("UICorner", FallbackBox).CornerRadius = UDim.new(0, 10)

    local send = Instance.new("TextButton")
    send.Size = UDim2.new(1, -28, 0, 40)
    send.Position = UDim2.new(0, 14, 1, -54)
    send.BackgroundColor3 = Color3.fromRGB(45, 120, 255)
    send.BorderSizePixel = 0
    send.TextColor3 = Color3.fromRGB(255, 255, 255)
    send.Text = "发送反馈"
    send.TextSize = 15
    send.Font = Enum.Font.GothamBold
    send.ZIndex = 501
    send.Parent = FallbackPanel

    Instance.new("UICorner", send).CornerRadius = UDim.new(0, 10)

    makeDraggable(FallbackPanel, titleBar)

    close.MouseButton1Click:Connect(function()
        FallbackPanel.Visible = false
    end)

    send.MouseButton1Click:Connect(function()
        if busy then
            return notify("反馈", "正在发送中", "loader", 2)
        end

        local text = tostring(FallbackBox.Text or "")
        if #text < 2 then
            return notify("反馈失败", "请先输入内容", "triangle-alert", 3)
        end

        busy = true
        send.Text = "发送中..."

        local ok, err = sendFeedback(text)

        busy = false
        send.Text = "发送反馈"

        if ok then
            FallbackBox.Text = ""
            FallbackPanel.Visible = false
            notify("反馈成功", "已发送给作者", "check", 3)
        else
            notify("反馈失败", tostring(err or "发送失败"), "triangle-alert", 5)
        end
    end)
end

local function showFallbackPanel(reason)
    if reason then
        warn("反馈模块已降级为独立面板:", reason)
    end

    createFallbackPanel()

    if FallbackPanel then
        FallbackPanel.Visible = true
        FallbackPanel.Position = UDim2.new(0.5, -210, 0.5, -135)
        FallbackPanel.BackgroundTransparency = 0.08

        pcall(function()
            TweenService:Create(
                FallbackPanel,
                TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = 0 }
            ):Play()
        end)
    end
end

local function showFeedbackWindow()
    -- 先尝试旧版：独立 WindUI 窗口
    if FeedbackWindow and not FeedbackTab then
        FeedbackWindow = nil
    end

    if FeedbackWindow and FeedbackTab then
        local shown = false

        pcall(function()
            if FeedbackWindow.Show then
                FeedbackWindow:Show()
                shown = true
            elseif FeedbackWindow.Open then
                FeedbackWindow:Open()
                shown = true
            elseif FeedbackWindow.SetVisible then
                FeedbackWindow:SetVisible(true)
                shown = true
            end
        end)

        pcall(function()
            if FeedbackTab.Select then
                FeedbackTab:Select()
            end
        end)

        if not shown then
            showFallbackPanel("已有 WindUI 窗口无法 Show/Open")
        end

        return
    end

    local newWindow
    local okCreate, errCreate = pcall(function()
        newWindow = WindUI:CreateWindow({
            Title = "反馈",
            Icon = "message-square",
            Author = "Suture Hub",
            Folder = "SutureHubFeedback_" .. tostring(math.random(1000, 9999)),
            Size = UDim2.fromOffset(420, 300),
            MinSize = Vector2.new(360, 260),
            MaxSize = Vector2.new(520, 380),
            ToggleKey = Enum.KeyCode.RightControl,
            Transparent = true,
            Theme = "Dark",
            Resizable = true,
            SideBarWidth = 120,
            HideSearchBar = true,
            ScrollBarEnabled = true,
            NewElements = true
        })
    end)

    if not okCreate or not newWindow then
        FeedbackWindow = nil
        FeedbackTab = nil
        return showFallbackPanel("WindUI:CreateWindow 创建失败：" .. tostring(errCreate))
    end

    FeedbackWindow = newWindow

    local okTab, errTab = pcall(function()
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
    end)

    if not okTab then
        FeedbackWindow = nil
        FeedbackTab = nil
        return showFallbackPanel("WindUI 页面创建失败：" .. tostring(errTab))
    end

    local shown = false
    pcall(function()
        if FeedbackWindow.Show then
            FeedbackWindow:Show()
            shown = true
        elseif FeedbackWindow.Open then
            FeedbackWindow:Open()
            shown = true
        elseif FeedbackWindow.SetVisible then
            FeedbackWindow:SetVisible(true)
            shown = true
        end
    end)

    pcall(function()
        if FeedbackTab.Select then
            FeedbackTab:Select()
        end
    end)

    if not shown then
        showFallbackPanel("WindUI 窗口创建后无法显示")
    end
end

local function openFeedback()
    local ok, err = pcall(showFeedbackWindow)
    if not ok then
        warn("反馈窗口打开失败:", err)
        showFallbackPanel("openFeedback 报错：" .. tostring(err))
    end
end

task.delay(1, function()
    local ok, err = pcall(function()
        MainWindow:CreateTopbarButton(
            "suture-feedback-window-v4",
            "message-square",
            openFeedback,
            989
        )
    end)

    if not ok then
        warn("反馈顶栏按钮创建失败:", err)
        notify("反馈模块", "顶栏按钮创建失败", "triangle-alert", 3)
    end
end)

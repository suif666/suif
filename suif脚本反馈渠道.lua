-- SutureHubFeedback.lua
-- 放到 GitHub Raw 后，在主脚本里 loadstring(game:HttpGet(FeedbackModuleURL))() 加载
-- 用法：
-- local Feedback = loadstring(game:HttpGet(FeedbackModuleURL))()
-- Feedback({
--     Window = win,
--     MainTab = mainTab,
--     Notify = notify,
--     LocalPlayer = lp,
--     HttpService = httpService,
--     UISet = uiSet,
--     FeedbackAPI = "https://你的worker地址.workers.dev"
-- })

return function(ctx)
    local Window = ctx.Window
    local MainTab = ctx.MainTab
    local notify = ctx.Notify or function(t, c) warn(t, c) end
    local lp = ctx.LocalPlayer or game:GetService("Players").LocalPlayer
    local httpService = ctx.HttpService or game:GetService("HttpService")
    local uiSet = ctx.UISet or { SideBarWidth = 180 }
    local FeedbackAPI = ctx.FeedbackAPI or ""

    if not Window then
        warn("SutureHubFeedback: 缺少 Window")
        return
    end

    if getgenv().SutureHubFeedbackLoaded then
        return
    end
    getgenv().SutureHubFeedbackLoaded = true

    local FeedbackText = ""

    local function getUIRoots()
        local roots = {}

        pcall(function()
            table.insert(roots, game:GetService("CoreGui"))
        end)

        pcall(function()
            local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 2)
            if pg then
                table.insert(roots, pg)
            end
        end)

        return roots
    end

    local function findSutureMainWindow()
        local bestWindow = nil
        local bestArea = 0

        local function checkCandidate(obj)
            if not obj or not obj:IsA("GuiObject") or not obj.Visible then
                return
            end

            local size = obj.AbsoluteSize
            local area = size.X * size.Y

            if size.X >= 480 and size.X <= 1000 and size.Y >= 300 and size.Y <= 750 and area > bestArea then
                bestWindow = obj
                bestArea = area
            end
        end

        for _, root in ipairs(getUIRoots()) do
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    local txt = tostring(v.Text or "")
                    if string.find(txt, "Suture Hub", 1, true) or string.find(txt, "v1.0.0", 1, true) then
                        local cur = v
                        while cur and cur ~= root do
                            checkCandidate(cur)
                            cur = cur.Parent
                        end
                    end
                end
            end
        end

        return bestWindow
    end

    local function sendPost(url, body)
        local req = nil

        if syn and syn.request then
            req = syn.request
        elseif http_request then
            req = http_request
        elseif request then
            req = request
        elseif fluxus and fluxus.request then
            req = fluxus.request
        elseif krnl and krnl.request then
            req = krnl.request
        elseif secure_request then
            req = secure_request
        elseif http and http.request then
            req = http.request
        end

        if req then
            local res = req({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = body
            })

            local status = tonumber(res and (res.StatusCode or res.Status or res.status_code)) or 200
            local responseBody = tostring(res and (res.Body or res.body or "") or "")

            if status < 200 or status >= 300 then
                error("HTTP " .. tostring(status) .. " " .. responseBody)
            end

            return responseBody
        end

        if game.HttpPost then
            return game:HttpPost(url, body, "application/json")
        end

        return httpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
    end

    local function postFeedback(message)
        message = tostring(message or "")

        if message:gsub("%s+", "") == "" then
            notify("反馈失败", "内容不能为空", "triangle-alert", 2)
            return false
        end

        if #message > 1000 then
            notify("反馈失败", "内容太长", "triangle-alert", 2)
            return false
        end

        if FeedbackAPI == "" or string.find(FeedbackAPI, "你的worker地址", 1, true) then
            notify("反馈失败", "请先填写 Worker 地址", "triangle-alert", 3)
            return false
        end

        local payload = {
            message = message,
            username = lp.Name,
            displayName = lp.DisplayName,
            userId = lp.UserId,
            placeId = game.PlaceId,
            jobId = game.JobId,
            executorTime = os.date("%Y-%m-%d %H:%M:%S")
        }

        local body = httpService:JSONEncode(payload)

        local ok, res = pcall(function()
            return sendPost(FeedbackAPI, body)
        end)

        if ok then
            notify("反馈成功", "已发送", "check", 2)
            return true
        else
            warn("反馈发送失败:", res)
            notify("反馈失败", tostring(res):sub(1, 80), "triangle-alert", 4)
            return false
        end
    end

    local feedbackTab = Window:Tab({
        Title = "反馈",
        Icon = "message-circle",
        Locked = false
    })

    feedbackTab:Paragraph({
        Title = "反馈中心",
        Desc = "请输入你遇到的问题或建议，点击发送后会提交到 Discord。"
    })

    feedbackTab:Input({
        Title = "反馈内容",
        Desc = "最多 1000 字",
        Placeholder = "在这里输入反馈内容...",
        Type = "Textarea",
        Value = "",
        Callback = function(v)
            FeedbackText = tostring(v or "")
        end
    })

    feedbackTab:Button({
        Title = "发送反馈",
        Desc = "发送到 Discord 反馈频道",
        Icon = "send",
        Callback = function()
            if postFeedback(FeedbackText) then
                FeedbackText = ""
            end
        end
    })

    feedbackTab:Button({
        Title = "返回主页",
        Desc = "回到主页",
        Icon = "house",
        Callback = function()
            if MainTab and MainTab.Select then
                MainTab:Select()
            end
        end
    })

    local function hideFeedbackTabInSidebar()
        local mainWindow = findSutureMainWindow()
        if not mainWindow then
            return false
        end

        local winLeft = mainWindow.AbsolutePosition.X
        local winTop = mainWindow.AbsolutePosition.Y
        local winBottom = winTop + mainWindow.AbsoluteSize.Y
        local sidebarRight = winLeft + math.max(160, (uiSet.SideBarWidth or 180) + 80)

        for _, v in ipairs(mainWindow:GetDescendants()) do
            if (v:IsA("TextLabel") or v:IsA("TextButton")) and tostring(v.Text or "") == "反馈" then
                local pos = v.AbsolutePosition
                if pos.X >= winLeft and pos.X <= sidebarRight and pos.Y >= winTop and pos.Y <= winBottom then
                    local cur = v
                    while cur and cur ~= mainWindow do
                        if cur:IsA("GuiButton") or cur:IsA("Frame") then
                            local s = cur.AbsoluteSize
                            if s.X >= 80 and s.X <= 260 and s.Y >= 24 and s.Y <= 70 then
                                cur.Visible = false
                                return true
                            end
                        end
                        cur = cur.Parent
                    end
                end
            end
        end

        return false
    end

    local function createEmbeddedFeedbackButton()
        local mainWindow = findSutureMainWindow()
        if not mainWindow then
            return false
        end

        if getgenv().SutureHubFeedbackButton and getgenv().SutureHubFeedbackButton.Parent then
            getgenv().SutureHubFeedbackButton:Destroy()
            getgenv().SutureHubFeedbackButton = nil
        end

        local btn = Instance.new("TextButton")
        btn.Name = "SutureHubFeedbackButton"
        btn.Text = "反馈"
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.Size = UDim2.fromOffset(54, 30)

        -- 右上角三个功能键前面。
        -- 如果还需要微调：-230 越小越靠左，越大越靠右；20 越小越靠上。
        btn.Position = UDim2.new(1, -230, 0, 20)

        btn.ZIndex = 999
        btn.Parent = mainWindow

        btn.MouseButton1Click:Connect(function()
            feedbackTab:Select()
        end)

        getgenv().SutureHubFeedbackButton = btn
        return true
    end

    task.spawn(function()
        for _ = 1, 20 do
            local hidden = hideFeedbackTabInSidebar()
            local embedded = createEmbeddedFeedbackButton()

            if hidden and embedded then
                break
            end

            task.wait(0.5)
        end
    end)
end

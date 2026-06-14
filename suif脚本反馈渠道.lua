--// Embedded Feedback Module
--// 作者注释位：你的B站UID

local FeedbackAPI = _G.FeedbackAPI or ""
local WindowTitle = _G.FeedbackWindowTitle or "刘某脚本"

if FeedbackAPI == "" then
    warn("反馈模块加载失败：缺少 _G.FeedbackAPI")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function GetRequest()
    return syn and syn.request
        or http and http.request
        or http_request
        or request
end

local function FindWindUIRoot(titleText)
    local roots = {}

    for _, gui in ipairs(CoreGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            if tostring(gui.Text):find(titleText) then
                local obj = gui
                while obj and not obj:IsA("ScreenGui") do
                    table.insert(roots, obj)
                    obj = obj.Parent
                end
            end
        end
    end

    local best, bestArea = nil, 0

    for _, obj in ipairs(roots) do
        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("CanvasGroup") then
            local s = obj.AbsoluteSize
            local area = s.X * s.Y

            if area > bestArea and s.X > 300 and s.Y > 200 then
                best = obj
                bestArea = area
            end
        end
    end

    return best
end

local Root

for _ = 1, 30 do
    Root = FindWindUIRoot(WindowTitle)
    if Root then
        break
    end
    task.wait(0.1)
end

if not Root then
    warn("反馈模块加载失败：未找到 WindUI 主窗口，请检查 _G.FeedbackWindowTitle")
    return
end

if Root:FindFirstChild("EmbeddedFeedbackButton") then
    Root.EmbeddedFeedbackButton:Destroy()
end

if Root:FindFirstChild("EmbeddedFeedbackPanel") then
    Root.EmbeddedFeedbackPanel:Destroy()
end

local Btn = Instance.new("TextButton")
Btn.Name = "EmbeddedFeedbackButton"
Btn.Parent = Root
Btn.Size = UDim2.new(0, 34, 0, 34)
Btn.AnchorPoint = Vector2.new(1, 0)
Btn.Position = UDim2.new(1, -158, 0, 28)
Btn.BackgroundTransparency = 1
Btn.Text = "✎"
Btn.TextSize = 22
Btn.Font = Enum.Font.GothamBold
Btn.TextColor3 = Color3.fromRGB(255, 230, 60)
Btn.ZIndex = 999

local Panel = Instance.new("Frame")
Panel.Name = "EmbeddedFeedbackPanel"
Panel.Parent = Root
Panel.Size = UDim2.new(0, 430, 0, 260)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
Panel.BackgroundTransparency = 0.04
Panel.Visible = false
Panel.ZIndex = 1000

local Corner = Instance.new("UICorner")
Corner.Parent = Panel
Corner.CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Parent = Panel
Stroke.Color = Color3.fromRGB(255, 220, 60)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.25

local Title = Instance.new("TextLabel")
Title.Parent = Panel
Title.Size = UDim2.new(1, -60, 0, 42)
Title.Position = UDim2.new(0, 18, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "反馈"
Title.TextColor3 = Color3.fromRGB(255, 235, 90)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 1001

local Close = Instance.new("TextButton")
Close.Parent = Panel
Close.Size = UDim2.new(0, 36, 0, 36)
Close.Position = UDim2.new(1, -46, 0, 10)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(180, 180, 180)
Close.TextSize = 28
Close.Font = Enum.Font.GothamBold
Close.ZIndex = 1001

local Box = Instance.new("TextBox")
Box.Parent = Panel
Box.Size = UDim2.new(1, -36, 0, 130)
Box.Position = UDim2.new(0, 18, 0, 58)
Box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Box.TextColor3 = Color3.fromRGB(240, 240, 240)
Box.PlaceholderText = "请输入反馈内容..."
Box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
Box.Text = ""
Box.TextSize = 16
Box.Font = Enum.Font.Gotham
Box.TextXAlignment = Enum.TextXAlignment.Left
Box.TextYAlignment = Enum.TextYAlignment.Top
Box.ClearTextOnFocus = false
Box.MultiLine = true
Box.ZIndex = 1001

local BoxCorner = Instance.new("UICorner")
BoxCorner.Parent = Box
BoxCorner.CornerRadius = UDim.new(0, 10)

local Send = Instance.new("TextButton")
Send.Parent = Panel
Send.Size = UDim2.new(1, -36, 0, 42)
Send.Position = UDim2.new(0, 18, 1, -58)
Send.BackgroundColor3 = Color3.fromRGB(255, 220, 55)
Send.Text = "发送反馈"
Send.TextColor3 = Color3.fromRGB(20, 20, 20)
Send.TextSize = 17
Send.Font = Enum.Font.GothamBold
Send.ZIndex = 1001

local SendCorner = Instance.new("UICorner")
SendCorner.Parent = Send
SendCorner.CornerRadius = UDim.new(0, 10)

local function Notify(text)
    if WindUI then
        pcall(function()
            WindUI:Notify({
                Title = "反馈",
                Content = text,
                Duration = 3
            })
        end)
    else
        warn(text)
    end
end

Btn.MouseButton1Click:Connect(function()
    Panel.Visible = not Panel.Visible
end)

Close.MouseButton1Click:Connect(function()
    Panel.Visible = false
end)

Send.MouseButton1Click:Connect(function()
    local content = Box.Text

    if content == "" or #content < 2 then
        Notify("请输入反馈内容")
        return
    end

    local req = GetRequest()

    if not req then
        Notify("当前执行器不支持网络请求")
        return
    end

    Send.Text = "发送中..."

    local ok = pcall(function()
        req({
            Url = FeedbackAPI,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                username = LocalPlayer.Name,
                userid = LocalPlayer.UserId,
                displayName = LocalPlayer.DisplayName,
                message = content,
                game = game.Name,
                placeId = game.PlaceId,
                jobId = game.JobId
            })
        })
    end)

    if ok then
        Box.Text = ""
        Panel.Visible = false
        Notify("反馈已发送")
    else
        Notify("反馈发送失败")
    end

    Send.Text = "发送反馈"
end)

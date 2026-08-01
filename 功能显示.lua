--[[
    功能显示系统 · 无大黑框 · 逻辑修复版
    基于 WindUI
]]

-- ================= 加载 WindUI =================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ================= 功能显示系统 =================
local FeatureDisplayEnabled = true
local EnabledFeatures = {}          -- 唯一数据源
local FeatureItems = {}             -- name → Frame

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

-- 主界面（完全透明，只用来放条目）
local FeatureGui = Instance.new("ScreenGui")
FeatureGui.Name = "FeatureDisplay_Modern"
FeatureGui.ResetOnSpawn = false
FeatureGui.IgnoreGuiInset = true
FeatureGui.Parent = game:GetService("CoreGui")

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.AnchorPoint = Vector2.new(1, 0)
Container.Position = UDim2.new(1, -14, 0, 14)
Container.Size = UDim2.new(0, 220, 0, 500)
Container.BackgroundTransparency = 1
Container.Parent = FeatureGui

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Container

-- 彩虹
local function Rainbow(offset)
    return Color3.fromHSV((tick() * 0.18 + (offset or 0)) % 1, 0.85, 1)
end

-- 计算文字宽度
local function GetTextWidth(text)
    local size = TextService:GetTextSize(text, 13, Enum.Font.GothamMedium, Vector2.new(1000, 20))
    return size.X
end

-- 创建单个功能条目
local function CreateFeatureItem(name, index)
    local width = GetTextWidth(name) + 28

    local item = Instance.new("Frame")
    item.Name = name
    item.Size = UDim2.new(0, 0, 0, 0)
    item.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    item.BackgroundTransparency = 1
    item.BorderSizePixel = 0
    item.ClipsDescendants = true
    item.Parent = Container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = item

    -- 左侧彩色指示条
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 3, 1, -8)
    bar.Position = UDim2.new(0, 4, 0, 4)
    bar.BackgroundColor3 = Color3.fromRGB(120, 160, 255)
    bar.BorderSizePixel = 0
    bar.Parent = item

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    -- 文字
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTransparency = 1
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.Parent = item

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.65
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = label

    -- 彩虹循环
    task.spawn(function()
        local t = index * 0.13
        while item and item.Parent do
            local c = Rainbow(t)
            if bar and bar.Parent then
                bar.BackgroundColor3 = c
            end
            task.wait(0.06)
        end
    end)

    return item, width
end

-- 核心刷新函数（已重写）
local function RefreshFeatureUI()
    -- 关闭状态：销毁所有条目
    if not FeatureDisplayEnabled then
        for name, item in pairs(FeatureItems) do
            if item and item.Parent then
                TweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, item.Size.X.Offset * 0.7, 0, 0),
                    BackgroundTransparency = 1
                }):Play()

                local label = item:FindFirstChild("Label")
                if label then
                    TweenService:Create(label, TweenInfo.new(0.15), {
                        TextTransparency = 1
                    }):Play()
                end

                task.delay(0.22, function()
                    if item then item:Destroy() end
                end)
            end
        end
        FeatureItems = {}
        return
    end

    -- 开启状态：先删除多余的，再补缺失的
    for name, item in pairs(FeatureItems) do
        if not table.find(EnabledFeatures, name) then
            if item and item.Parent then
                TweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, item.Size.X.Offset * 0.7, 0, 0),
                    BackgroundTransparency = 1
                }):Play()

                local label = item:FindFirstChild("Label")
                if label then
                    TweenService:Create(label, TweenInfo.new(0.15), {
                        TextTransparency = 1
                    }):Play()
                end

                task.delay(0.22, function()
                    if item then item:Destroy() end
                end)
            end
            FeatureItems[name] = nil
        end
    end

    -- 补全缺失的条目
    for i, name in ipairs(EnabledFeatures) do
        if not FeatureItems[name] then
            local item, width = CreateFeatureItem(name, i)
            FeatureItems[name] = item

            -- 飞入动画
            item.Size = UDim2.new(0, width * 0.55, 0, 0)
            item.BackgroundTransparency = 1

            task.spawn(function()
                task.wait(0.03 * (i - 1))
                TweenService:Create(item, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, width, 0, 26),
                    BackgroundTransparency = 0.22
                }):Play()

                local label = item:FindFirstChild("Label")
                if label then
                    task.wait(0.08)
                    TweenService:Create(label, TweenInfo.new(0.22), {
                        TextTransparency = 0
                    }):Play()
                end
            end)
        end
    end
end

-- 添加功能（防重复）
local function AddFeature(name)
    if not name or name == "" then return end
    if table.find(EnabledFeatures, name) then return end

    if name == "夜脚本" then
        table.insert(EnabledFeatures, 1, name)
    else
        table.insert(EnabledFeatures, name)
    end

    RefreshFeatureUI()
end

-- 移除功能
local function RemoveFeature(name)
    for i, v in ipairs(EnabledFeatures) do
        if v == name then
            table.remove(EnabledFeatures, i)
            break
        end
    end
    RefreshFeatureUI()
end

-- 初始化只添加一次夜脚本
task.defer(function()
    AddFeature("夜脚本")
end)

-- ================= WindUI 窗口 =================
local Window = WindUI:CreateWindow({
    Title = "功能显示 · 修复版",
    Author = "无大黑框",
    Folder = "FeatureDisplayFix",
    Size = UDim2.fromOffset(430, 380),
    Transparent = true,
    Theme = "Dark",
    NewElements = true,
    SideBarWidth = 140,
})

local Tab = Window:Tab({
    Title = "功能显示",
    Icon = "list"
})

Tab:Toggle({
    Title = "功能列表显示",
    Default = true,
    Callback = function(v)
        FeatureDisplayEnabled = v
        RefreshFeatureUI()
    end
})

Tab:Paragraph({
    Title = "说明",
    Desc = "已去掉外面大黑框\n关闭再打开会完整重建当前所有已开启功能"
})

Tab:Section({ Title = "演示开关" })

local demoFeatures = {
    "速度修改",
    "无限跳",
    "穿墙",
    "自由视角",
    "玩家透视",
    "自瞄",
    "夜视",
}

for _, name in ipairs(demoFeatures) do
    Tab:Toggle({
        Title = name,
        Default = false,
        Callback = function(v)
            if v then
                AddFeature(name)
            else
                RemoveFeature(name)
            end
        end
    })
end

Tab:Section({ Title = "测试" })

Tab:Button({
    Title = "添加随机功能",
    Callback = function()
        AddFeature("测试功能 " .. math.random(10, 99))
    end
})

Tab:Button({
    Title = "清空（保留夜脚本）",
    Callback = function()
        local keep = {}
        for _, name in ipairs(EnabledFeatures) do
            if name == "夜脚本" then
                table.insert(keep, name)
            end
        end
        EnabledFeatures = keep

        -- 强制清空视觉
        for _, item in pairs(FeatureItems) do
            if item then item:Destroy() end
        end
        FeatureItems = {}
        RefreshFeatureUI()
    end
})

WindUI:Notify({
    Title = "加载成功",
    Content = "功能显示已修复",
    Duration = 3,
    Icon = "check"
})

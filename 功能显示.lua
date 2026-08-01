--[[
    功能显示系统 · 现代化独立版
    基于 WindUI
    已修复重复生成问题 + 视觉升级
]]

-- ================= 加载 WindUI =================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ================= 功能显示系统 =================
local FeatureDisplayEnabled = true
local EnabledFeatures = {}          -- 严格唯一列表
local FeatureItems = {}             -- name → Frame

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

-- 主容器
local FeatureGui = Instance.new("ScreenGui")
FeatureGui.Name = "FeatureDisplay_Modern"
FeatureGui.ResetOnSpawn = false
FeatureGui.IgnoreGuiInset = true
FeatureGui.Parent = game:GetService("CoreGui")

-- 整体背景面板（玻璃拟态）
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.AnchorPoint = Vector2.new(1, 0)
Panel.Position = UDim2.new(1, -14, 0, 14)
Panel.Size = UDim2.new(0, 0, 0, 0) -- 会动态计算
Panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Panel.BackgroundTransparency = 0.35
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.Parent = FeatureGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Thickness = 1
PanelStroke.Color = Color3.fromRGB(255, 255, 255)
PanelStroke.Transparency = 0.88
PanelStroke.Parent = Panel

-- 列表容器
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -16, 1, -16)
Container.Position = UDim2.new(0, 8, 0, 8)
Container.BackgroundTransparency = 1
Container.Parent = Panel

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Container

-- 彩虹颜色
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
    item.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
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

    -- 轻微描边让文字更清晰
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = label

    -- 彩虹循环（指示条 + 文字轻微变化）
    task.spawn(function()
        local t = index * 0.12
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

-- 刷新整个列表（核心逻辑，已彻底防重复）
local function RefreshFeatureUI()
    if not FeatureDisplayEnabled then
        -- 隐藏时优雅收起
        if Panel.Visible then
            TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            for _, item in pairs(FeatureItems) do
                if item and item.Parent then
                    TweenService:Create(item, TweenInfo.new(0.2), {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, item.Size.X.Offset, 0, 0)
                    }):Play()
                end
            end
            task.delay(0.25, function()
                Panel.Visible = false
            end)
        end
        return
    end

    Panel.Visible = true
    TweenService:Create(Panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.35
    }):Play()

    -- 1. 删除不再存在的功能
    for name, item in pairs(FeatureItems) do
        if not table.find(EnabledFeatures, name) then
            if item and item.Parent then
                TweenService:Create(item, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, item.Size.X.Offset * 0.7, 0, 0),
                    BackgroundTransparency = 1
                }):Play()

                local label = item:FindFirstChild("Label")
                if label then
                    TweenService:Create(label, TweenInfo.new(0.18), {
                        TextTransparency = 1
                    }):Play()
                end

                task.delay(0.25, function()
                    if item then item:Destroy() end
                end)
            end
            FeatureItems[name] = nil
        end
    end

    -- 2. 添加缺失的功能
    local maxWidth = 0
    for i, name in ipairs(EnabledFeatures) do
        if not FeatureItems[name] then
            local item, width = CreateFeatureItem(name, i)
            FeatureItems[name] = item
            maxWidth = math.max(maxWidth, width)

            -- 飞入动画
            item.Size = UDim2.new(0, width * 0.6, 0, 0)
            item.BackgroundTransparency = 1

            task.spawn(function()
                task.wait(0.02 * i) -- 错开一点更自然
                TweenService:Create(item, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, width, 0, 26),
                    BackgroundTransparency = 0.25
                }):Play()

                local label = item:FindFirstChild("Label")
                if label then
                    task.wait(0.08)
                    TweenService:Create(label, TweenInfo.new(0.25), {
                        TextTransparency = 0
                    }):Play()
                end
            end)
        else
            -- 已存在的也更新一下宽度记录
            local item = FeatureItems[name]
            if item then
                maxWidth = math.max(maxWidth, item.Size.X.Offset)
            end
        end
    end

    -- 3. 动态调整面板大小
    local count = #EnabledFeatures
    local height = count > 0 and (count * 32 + 10) or 0
    local targetWidth = math.clamp(maxWidth + 20, 120, 220)

    TweenService:Create(Panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, targetWidth, 0, height)
    }):Play()
end

-- 添加功能（严格防重复）
local function AddFeature(name)
    if not name or name == "" then return end

    -- 已存在则直接返回
    if table.find(EnabledFeatures, name) then
        return
    end

    if name == "夜脚本" then
        -- 强制放在第一位
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

-- 初始化时只添加一次“夜脚本”
task.defer(function()
    AddFeature("夜脚本")
end)

-- ================= WindUI 窗口 =================
local Window = WindUI:CreateWindow({
    Title = "功能显示 · 现代版",
    Author = "优化版",
    Folder = "FeatureDisplayModern",
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
    Desc = "右上角现代化功能列表\n已修复重复生成问题，视觉已升级"
})

Tab:Section({ Title = "演示开关" })

local demoFeatures = {
    { name = "速度修改", key = "速度修改" },
    { name = "无限跳", key = "无限跳" },
    { name = "穿墙", key = "穿墙" },
    { name = "自由视角", key = "自由视角" },
    { name = "玩家透视", key = "玩家透视" },
    { name = "自瞄", key = "自瞄" },
    { name = "夜视", key = "夜视" },
}

for _, feat in ipairs(demoFeatures) do
    Tab:Toggle({
        Title = feat.name,
        Default = false,
        Callback = function(v)
            if v then
                AddFeature(feat.key)
            else
                RemoveFeature(feat.key)
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
        -- 强制清理所有条目后重建
        for name, item in pairs(FeatureItems) do
            if item then item:Destroy() end
        end
        FeatureItems = {}
        RefreshFeatureUI()
    end
})

WindUI:Notify({
    Title = "加载成功",
    Content = "现代化功能显示已启动",
    Duration = 3,
    Icon = "check"
})

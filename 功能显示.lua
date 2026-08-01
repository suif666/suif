--[[
    功能显示系统 · 独立版
    基于 WindUI
    提取自夜脚本
]]

-- ================= 加载 WindUI =================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ================= 功能显示系统 =================
local FeatureDisplayEnabled = true
local EnabledFeatures = {}
local FeatureItems = {}

local FeatureGui = Instance.new("ScreenGui")
FeatureGui.Name = "FeatureDisplay"
FeatureGui.ResetOnSpawn = false
FeatureGui.Parent = game:GetService("CoreGui")

local Container = Instance.new("Frame")
Container.AnchorPoint = Vector2.new(1, 0)
Container.Position = UDim2.new(1, -10, 0, 10)
Container.Size = UDim2.new(0, 200, 0, 400)
Container.BackgroundTransparency = 1
Container.Parent = FeatureGui

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 4)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Container

local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local function Rainbow()
    return Color3.fromHSV((tick() * 0.25) % 1, 1, 1)
end

-- 刷新 UI
local function RefreshFeatureUI()
    Container.Visible = FeatureDisplayEnabled
    if not FeatureDisplayEnabled then return end

    -- 删除已关闭的功能（带动画）
    for name, item in pairs(FeatureItems) do
        if not table.find(EnabledFeatures, name) then
            if item and item.Parent then
                TweenService:Create(item, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, item.Size.X.Offset, 0, 0),
                    BackgroundTransparency = 1
                }):Play()

                for _, v in pairs(item:GetChildren()) do
                    if v:IsA("TextLabel") then
                        TweenService:Create(v, TweenInfo.new(0.2), {
                            TextTransparency = 1,
                            TextStrokeTransparency = 1
                        }):Play()
                    end
                end

                task.delay(0.25, function()
                    if item then item:Destroy() end
                end)
            end
            FeatureItems[name] = nil
        end
    end

    -- 添加新功能
    for _, name in ipairs(EnabledFeatures) do
        if FeatureItems[name] then continue end

        local textSize = TextService:GetTextSize(name, 14, Enum.Font.SourceSansBold, Vector2.new(1000, 20))
        local width = textSize.X + 14

        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 0, 0, 16)
        item.BackgroundTransparency = 1
        item.BackgroundColor3 = Color3.new(0, 0, 0)
        item.BorderSizePixel = 0
        item.Parent = Container

        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -6, 1, 0)
        label.Position = UDim2.new(0, 3, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextTransparency = 1
        label.TextStrokeTransparency = 1
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = item

        -- 彩虹文字
        task.spawn(function()
            while label and label.Parent do
                label.TextColor3 = Rainbow()
                task.wait(0.05)
            end
        end)

        -- 飞入动画
        task.spawn(function()
            task.wait()
            TweenService:Create(item, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, width, 0, 20),
                BackgroundTransparency = 0.5
            }):Play()

            task.wait(0.1)
            TweenService:Create(label, TweenInfo.new(0.3), {
                TextTransparency = 0,
                TextStrokeTransparency = 0.3
            }):Play()
        end)

        FeatureItems[name] = item
    end
end

-- 添加功能
local function AddFeature(name)
    if name == "夜脚本" then
        -- 强制放在最前面
        for i, v in ipairs(EnabledFeatures) do
            if v == "夜脚本" then
                table.remove(EnabledFeatures, i)
                break
            end
        end
        table.insert(EnabledFeatures, 1, name)
    else
        if not table.find(EnabledFeatures, name) then
            table.insert(EnabledFeatures, name)
        end
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

-- 初始化（默认显示夜脚本）
task.spawn(function()
    task.wait(0.1)
    AddFeature("夜脚本")
end)

-- ================= 创建 WindUI 窗口 =================
local Window = WindUI:CreateWindow({
    Title = "功能显示 · 独立版",
    Author = "提取自夜脚本",
    Folder = "FeatureDisplayDemo",
    Size = UDim2.fromOffset(420, 360),
    Transparent = true,
    Theme = "Dark",
    NewElements = true,
    SideBarWidth = 140,
})

local Tab = Window:Tab({
    Title = "功能显示",
    Icon = "list"
})

-- 功能列表开关
Tab:Toggle({
    Title = "功能列表显示",
    Default = true,
    Callback = function(v)
        FeatureDisplayEnabled = v
        if v then
            -- 重新显示时重新添加一次
            for _, name in ipairs(EnabledFeatures) do
                FeatureItems[name] = nil
            end
            RefreshFeatureUI()
        else
            RefreshFeatureUI()
        end
    end
})

Tab:Paragraph({
    Title = "说明",
    Desc = "右上角会实时显示当前开启的功能\n带彩虹文字和飞入飞出动画"
})

-- 演示用开关
Tab:Section({ Title = "演示开关（测试用）" })

Tab:Toggle({
    Title = "速度修改",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("速度修改")
        else
            RemoveFeature("速度修改")
        end
    end
})

Tab:Toggle({
    Title = "无限跳",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("无限跳")
        else
            RemoveFeature("无限跳")
        end
    end
})

Tab:Toggle({
    Title = "穿墙",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("穿墙")
        else
            RemoveFeature("穿墙")
        end
    end
})

Tab:Toggle({
    Title = "自由视角",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("自由视角")
        else
            RemoveFeature("自由视角")
        end
    end
})

Tab:Toggle({
    Title = "玩家透视",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("玩家透视")
        else
            RemoveFeature("玩家透视")
        end
    end
})

Tab:Toggle({
    Title = "自瞄",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("自瞄")
        else
            RemoveFeature("自瞄")
        end
    end
})

-- 手动操作
Tab:Section({ Title = "手动操作" })

Tab:Button({
    Title = "添加自定义功能",
    Callback = function()
        AddFeature("自定义功能 " .. math.random(1, 99))
    end
})

Tab:Button({
    Title = "清空所有功能（保留夜脚本）",
    Callback = function()
        local keep = {}
        for _, name in ipairs(EnabledFeatures) do
            if name == "夜脚本" then
                table.insert(keep, name)
            end
        end
        EnabledFeatures = keep
        RefreshFeatureUI()
    end
})

-- 通知
WindUI:Notify({
    Title = "加载成功",
    Content = "功能显示系统已启动",
    Duration = 3,
    Icon = "check"
})

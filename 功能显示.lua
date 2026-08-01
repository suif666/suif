-- =================== 功能显示系统（独立 WindUI 脚本） ===================
-- 功能：在屏幕右上角显示已开启的功能列表（彩虹标签）
-- 来源：夜脚本源.lua - 功能显示系统（终极进阶版）
-- 独立运行，不依赖任何外部变量

print("[功能显示] 脚本开始加载...")

-- ===== 1. 加载 WindUI =====
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then
    error("[功能显示] WindUI 加载失败，请检查网络")
end
print("[功能显示] WindUI 加载成功")

-- ===== 2. 创建独立窗口 =====
local Window = WindUI:CreateWindow({
    Title = "功能显示系统",
    Icon = "list",
    Size = UDim2.new(0, 400, 0, 320),
    Theme = "Dark"
})
print("[功能显示] 窗口创建成功")

-- ===== 3. 创建标签页 =====
local tab = Window:CreateTab("功能显示")
print("[功能显示] 标签页创建成功")

-- ===== 4. 功能显示系统核心代码 =====
--（从夜脚本源.lua 提取，仅修改了 Notify 为 WindUI 通知）

local FeatureDisplayEnabled = true
local EnabledFeatures = {}
local FeatureItems = {}

-- 创建 UI（独立于 WindUI 窗口，直接放在 CoreGui）
local FeatureGui = Instance.new("ScreenGui")
FeatureGui.Name = "FeatureDisplay"
FeatureGui.Parent = game.CoreGui

local Container = Instance.new("Frame")
Container.AnchorPoint = Vector2.new(1, 0)
Container.Position = UDim2.new(1, -10, 0, 10)
Container.Size = UDim2.new(0, 200, 0, 300)
Container.BackgroundTransparency = 1
Container.Parent = FeatureGui

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 4)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIList.Parent = Container

local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

-- 彩虹颜色循环
local function Rainbow()
    return Color3.fromHSV((tick() * 0.25) % 1, 1, 1)
end

-- 刷新 UI
local function RefreshFeatureUI()
    Container.Visible = FeatureDisplayEnabled
    if not FeatureDisplayEnabled then return end

    -- 删除旧的（带动画）
    for name, item in pairs(FeatureItems) do
        if not table.find(EnabledFeatures, name) then
            if item then
                TweenService:Create(item, TweenInfo.new(
                    0.25,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.In
                ), {
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

    -- 添加新 UI
    for _, name in ipairs(EnabledFeatures) do
        if FeatureItems[name] then continue end

        local textSize = TextService:GetTextSize(
            name, 14, Enum.Font.SourceSansBold, Vector2.new(1000, 20)
        )
        local width = textSize.X + 10

        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 0, 0, 16)
        item.BackgroundTransparency = 1
        item.BackgroundColor3 = Color3.new(0, 0, 0)
        item.BorderSizePixel = 0
        item.Parent = Container

        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)

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

        -- 彩虹颜色循环
        task.spawn(function()
            while label.Parent do
                label.TextColor3 = Rainbow()
                task.wait(0.05)
            end
        end)

        -- 飞入动画
        task.spawn(function()
            task.wait()
            TweenService:Create(item, TweenInfo.new(
                0.4,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ), {
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
    if name == "功能显示系统" then
        for i, v in ipairs(EnabledFeatures) do
            if v == "功能显示系统" then
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

-- 删除功能
local function RemoveFeature(name)
    for i, v in ipairs(EnabledFeatures) do
        if v == name then
            table.remove(EnabledFeatures, i)
            break
        end
    end
    RefreshFeatureUI()
end

print("[功能显示] 核心系统已加载")

-- ===== 5. 创建 UI 控件 =====
print("[功能显示] 开始创建 UI 控件...")

-- 总开关（控制功能显示列表是否可见）
tab:Toggle({
    Title = "启用功能列表显示",
    Default = true,
    Callback = function(v)
        FeatureDisplayEnabled = v
        if v then
            RefreshFeatureUI()
        else
            Container.Visible = false
        end
    end
})

-- 分隔线（用 Paragraph 模拟）
tab:Paragraph({
    Title = "📌 演示功能开关",
    Desc = "开启下方功能，它们会出现在右上角的列表中"
})

-- 演示功能 1
local demo1 = false
tab:Toggle({
    Title = "功能 A",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("功能 A")
        else
            RemoveFeature("功能 A")
        end
        demo1 = v
    end
})

-- 演示功能 2
local demo2 = false
tab:Toggle({
    Title = "功能 B",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("功能 B")
        else
            RemoveFeature("功能 B")
        end
        demo2 = v
    end
})

-- 演示功能 3
local demo3 = false
tab:Toggle({
    Title = "功能 C",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("功能 C")
        else
            RemoveFeature("功能 C")
        end
        demo3 = v
    end
})

-- 演示功能 4
local demo4 = false
tab:Toggle({
    Title = "功能 D",
    Default = false,
    Callback = function(v)
        if v then
            AddFeature("功能 D")
        else
            RemoveFeature("功能 D")
        end
        demo4 = v
    end
})

-- 一键清除所有演示功能
tab:Button({
    Title = "清除所有演示功能",
    Callback = function()
        -- 关闭所有演示 Toggle（需要保存 Toggle 引用，这里简化用全局变量）
        -- 由于无法直接操作其他 Toggle，我们直接移除所有以"功能"开头的功能
        local toRemove = {}
        for _, name in ipairs(EnabledFeatures) do
            if string.find(name, "功能 ") then
                table.insert(toRemove, name)
            end
        end
        for _, name in ipairs(toRemove) do
            RemoveFeature(name)
        end
        -- 重置状态（简单处理）
        print("[功能显示] 已清除所有演示功能")
    end
})

-- 说明
tab:Paragraph({
    Title = "💡 使用说明",
    Desc = "开启/关闭上面的演示功能，它们会自动显示/消失在右上角。\n功能列表会以彩虹渐变色显示。"
})

print("[功能显示] UI 控件创建完成")

-- ===== 6. 初始化 =====
-- 默认添加"功能显示系统"到列表
task.spawn(function()
    for _, item in pairs(FeatureItems) do
        if item then item:Destroy() end
    end
    FeatureItems = {}
    task.wait(0.05)
    AddFeature("功能显示系统")
    RefreshFeatureUI()
end)

print("[功能显示] 初始化完成")

-- ===== 7. 启动完成 =====
WindUI:Notify({
    Title = "功能显示系统",
    Content = "独立窗口已加载，右上角显示功能列表",
    Duration = 3,
    Icon = "check"
})

print("[功能显示] 脚本加载完成！")

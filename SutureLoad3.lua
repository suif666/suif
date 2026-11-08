-- SutureLoad3 v1.3.1 [suture] - Suture Hub one-click launcher (flat, ASCII, compatible)
pcall(function()
    if rconsoleprint then
        rconsoleprint("[SutureLoad] boot v1.3.1 - entry script is running\n")
    end
end)
warn("[SutureLoad] boot v1.3.1 - entry script is running")
-- Single file: loader UI + WindUI preload + suif main script.
-- Run: loadstring(game:HttpGet("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/SutureLoad3.lua"))()

-----------------------------------------------------------------------
-- [1] Task compatibility wrappers (old executors may lack task.wait)
-----------------------------------------------------------------------
local TASK = (type(task) == "table" or type(task) == "userdata") and task or {}
local HAS_WAIT = type(TASK.wait) == "function"
local HAS_SPAWN = type(TASK.spawn) == "function"
local HAS_DELAY = type(TASK.delay) == "function"

local function Wait(t)
    if HAS_WAIT then
        return TASK.wait(t)
    end
    if wait then
        return wait(t)
    end
    return nil
end

local function Spawn(fn)
    if HAS_SPAWN then
        return TASK.spawn(fn)
    end
    if spawn then
        return spawn(fn)
    end
    local co = coroutine.create(fn)
    return coroutine.resume(co)
end

local function Delay(t, fn)
    if HAS_DELAY then
        return TASK.delay(t, fn)
    end
    if delay then
        return delay(t, fn)
    end
    Spawn(function()
        Wait(t)
        fn()
    end)
end

-----------------------------------------------------------------------
-- [2] Minimal GUI helpers
-----------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui")

local FONT_DEFAULT = Enum.Font.Gotham

local function New(class, props, children)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = obj
        end
    end
    return obj
end

local function Tween(obj, duration, props)
    local tw = TweenService:Create(obj, TweenInfo.new(duration), props)
    tw:Play()
    return tw
end

-----------------------------------------------------------------------
-- [3] Loader core
-----------------------------------------------------------------------
local Loader = {}
Loader.__index = Loader

function Loader.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Loader)
    self.Title = opts.Title or "Suture Hub"
    self.Subtitle = opts.Subtitle or ""
    self.Tasks = {}
    self.UIQueue = {}
    self.Running = false
    self.Finished = false
    self.Snowflakes = {}
    return self
end

function Loader:AddTask(name, fn)
    table.insert(self.Tasks, { Name = name, Fn = fn })
    return self
end

function Loader:QueueUI(name, builder)
    table.insert(self.UIQueue, { Name = name, Builder = builder })
    return self
end

function Loader:Show()
    if self.Running then
        return self
    end
    -- lazy init (safe even without Loader.new)
    self.Tasks = self.Tasks or {}
    self.UIQueue = self.UIQueue or {}
    self.Snowflakes = self.Snowflakes or {}
    self.Running = true

    local gui = New("ScreenGui", {
        Name = "SutureLoader",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })
    self.Gui = gui

    -- dim background
    local Bg = New("Frame", {
        Name = "Bg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(8, 10, 16),
        BackgroundTransparency = 0.32,
        Parent = gui,
    })
    self.Bg = Bg

    -- title
    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 52),
        Position = UDim2.new(0.5, 0, 0.42, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 36,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        TextStrokeTransparency = 0.5,
        Parent = gui,
    })
    self.TitleLbl = Title

    -- subtitle
    if self.Subtitle ~= "" then
        local Sub = New("TextLabel", {
            Name = "Subtitle",
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0.5, 0, 0.42, 60),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = self.Subtitle,
            TextColor3 = Color3.fromRGB(170, 180, 200),
            TextSize = 15,
            Font = FONT_DEFAULT,
            TextTransparency = 1,
            Parent = gui,
        })
        self.SubLbl = Sub
    end

    -- progress bar bg
    local BarBg = New("Frame", {
        Name = "BarBg",
        Size = UDim2.new(0, 340, 0, 14),
        Position = UDim2.new(0.5, 0, 0.42, 96),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(28, 32, 40),
        BackgroundTransparency = 0.25,
        Parent = gui,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
    })
    self.BarBg = BarBg

    -- progress bar fill
    local Bar = New("Frame", {
        Name = "Bar",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(70, 150, 255),
        BackgroundTransparency = 0,
        Parent = BarBg,
    }, {
        New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 200, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 110, 255)),
            }),
            Rotation = 90,
        }),
    })
    self.Bar = Bar

    -- percent label (right of bar)
    local Pct = New("TextLabel", {
        Name = "Pct",
        Size = UDim2.new(0, 60, 0, 24),
        Position = UDim2.new(1, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Color3.fromRGB(140, 200, 255),
        TextSize = 15,
        Font = Enum.Font.GothamSemibold,
        TextTransparency = 1,
        Parent = BarBg,
    })
    self.PctLbl = Pct

    -- task label (below bar)
    local TaskLbl = New("TextLabel", {
        Name = "Task",
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0.5, 0, 0.42, 122),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(220, 226, 235),
        TextSize = 14,
        Font = FONT_DEFAULT,
        TextTransparency = 1,
        Parent = gui,
    })
    self.TaskLbl = TaskLbl

    -- fade-in
    Tween(Title, 0.9, { TextTransparency = 0 })
    if self.SubLbl then
        Tween(self.SubLbl, 0.9, { TextTransparency = 0 })
    end
    Tween(Pct, 0.9, { TextTransparency = 0 })
    Tween(TaskLbl, 0.9, { TextTransparency = 0 })

    -- snow effect
    self:StartSnow(gui)

    return self
end

function Loader:StartSnow(gui)
    for _ = 1, 14 do
        local size = math.random(10, 16)
        local flake = New("TextLabel", {
            Name = "Snow",
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(math.random() * 1, 0, math.random() * -0.3, 0),
            BackgroundTransparency = 1,
            Text = "*",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = math.random() * 0.4 + 0.2,
            TextSize = size,
            Font = FONT_DEFAULT,
            Parent = gui,
        })
        table.insert(self.Snowflakes, flake)
        Spawn(function()
            while self.Running and flake.Parent do
                local dur = math.random(6, 10)
                local targetX = math.random() * 1
                local tw = TweenService:Create(flake, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(targetX, 0, 1.05, 0),
                })
                tw:Play()
                tw.Completed:Wait()
                if not self.Running or not flake.Parent then
                    break
                end
                flake.Position = UDim2.new(math.random() * 1, 0, -0.15, 0)
                flake.TextTransparency = math.random() * 0.4 + 0.2
            end
        end)
    end
end

function Loader:SetProgress(p, label)
    if not self.Running or not self.BarBg then
        return
    end
    p = math.max(0, math.min(100, p))
    local w = self.BarBg.AbsoluteSize.X
    local h = self.BarBg.AbsoluteSize.Y
    Tween(self.Bar, 0.25, {
        Size = UDim2.fromOffset(math.floor(w * p / 100), h),
    })
    if self.PctLbl then
        self.PctLbl.Text = string.format("%d%%", math.floor(p))
    end
    if label and self.TaskLbl then
        self.TaskLbl.Text = label
    end
end

function Loader:Start(cb)
    if not self.Running then
        self:Show()
    end
    local n = #self.Tasks
    if n == 0 then
        if cb then
            pcall(cb)
        end
        return self
    end
    Spawn(function()
        for i, task in ipairs(self.Tasks) do
            if self.TaskLbl then
                self.TaskLbl.Text = task.Name
            end
            local ok, err = pcall(task.Fn)
            if not ok and err then
                warn("[SutureLoader] task failed: " .. tostring(task.Name) .. " - " .. tostring(err))
            end
            self:SetProgress((i / n) * 100)
            Wait(0.06)
        end
        self:SetProgress(100, "加载完成")
        Wait(0.4)
        if cb then
            pcall(cb)
        end
    end)
    return self
end

function Loader:FlushUI(Window)
    local n = #self.UIQueue
    for i, item in ipairs(self.UIQueue) do
        if self.TaskLbl then
            self.TaskLbl.Text = "正在附加 UI: " .. tostring(item.Name)
        end
        local ok, err = pcall(item.Builder, Window)
        if not ok and err then
            warn("[SutureLoader] UI failed: " .. tostring(item.Name) .. " - " .. tostring(err))
        end
        if i < n then
            Wait(0.03)
        end
    end
    self.UIQueue = {}
    return self
end

function Loader:Finish()
    if self.Finished then
        return self
    end
    self.Finished = true
    self.Running = false
    local gui = self.Gui
    Spawn(function()
        if not gui then
            return
        end
        local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if self.Bg then
            Tween(self.Bg, 0.5, { BackgroundTransparency = 1 })
        end
        if self.TitleLbl then
            Tween(self.TitleLbl, 0.5, { TextTransparency = 1 })
        end
        if self.SubLbl then
            Tween(self.SubLbl, 0.5, { TextTransparency = 1 })
        end
        if self.BarBg then
            Tween(self.BarBg, 0.5, { BackgroundTransparency = 1 })
        end
        if self.PctLbl then
            Tween(self.PctLbl, 0.5, { TextTransparency = 1 })
        end
        if self.TaskLbl then
            Tween(self.TaskLbl, 0.5, { TextTransparency = 1 })
        end
        for _, flake in ipairs(self.Snowflakes) do
            if flake and flake.Parent then
                Tween(flake, 0.5, { TextTransparency = 1 })
            end
        end
        Wait(0.55)
        if gui and gui.Parent then
            gui:Destroy()
        end
    end)
    return self
end

-----------------------------------------------------------------------
-- [4] Entry logic: URLs
-----------------------------------------------------------------------
local SUIF_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif.lua"
local WINDUI_SRC = {
    "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua",
    "https://cdn.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
    "https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua",
    "https://gcore.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
}

local function TryLoad(url)
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(src) ~= "string" or #src == 0 then
        return nil
    end
    local fn, cerr = loadstring(src)
    if not fn then
        return nil
    end
    local ran, mod = pcall(fn)
    if ran and mod then
        return mod
    end
    return nil
end

-----------------------------------------------------------------------
-- [5] Boot
-----------------------------------------------------------------------
local inst = Loader.new({ Title = "Suture Hub" })
inst:Show()

local REMOTE_SPECS = {
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua", desc = "范围" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%94%A9%E9%A3%9E.lua", desc = "甩飞" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%98%BE%E7%A4%BAfps%E5%92%8Cping.lua", desc = "ping/fps显示" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua", desc = "雷达" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", desc = "玩家类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", desc = "自瞄类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua", desc = "发言类" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua", desc = "ESP" },
    { url = "https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua", desc = "服务器类" },
    { url = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9D%90%E6%A0%87%E4%BC%A0%E9%80%81.lua", desc = "坐标传送" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/animation.lua", desc = "动作动画" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/actionpack.lua", desc = "动作包" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/animpack.lua", desc = "动画包" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/disguise.lua", desc = "伪装玩家" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/slowrun.lua", desc = "缓慢的快速跑" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/clicker.lua", desc = "自动连点器" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/npc.lua", desc = "NPC交互" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/trigger.lua", desc = "触发类" },
    { url = "https://raw.githubusercontent.com/suif666/tu/main/hb/object.lua", desc = "控制物体" },
}

-- 预下载远程脚本：加载器阶段全部下载+编译排队，窗口出现瞬间一次性挂载
local function PreloadRemotes(inst)
    local g = (getgenv and getgenv()) or _G
    if not g then
        return
    end
    g.__SUIF_PENDING = g.__SUIF_PENDING or {}
    g.__PRELOADED_URLS = g.__PRELOADED_URLS or {}
    local total = #REMOTE_SPECS
    local done = 0
    for _, spec in ipairs(REMOTE_SPECS) do
        local fn = TryLoad(spec.url)
        if fn then
            table.insert(g.__SUIF_PENDING, fn)
            g.__PRELOADED_URLS[spec.url] = true
        end
        done = done + 1
        if inst.TaskLbl then
            inst.TaskLbl.Text = "正在加载远程脚本 " .. done .. "/" .. total
        end
    end
end

inst:AddTask("正在加载 UI 库", function()
    local g = (getgenv and getgenv()) or _G
    for _, u in ipairs(WINDUI_SRC) do
        local mod = TryLoad(u)
        if mod then
            g.WindUI = mod
            return
        end
    end
    error("WindUI load failed (4 mirrors unavailable)")
end)

inst:AddTask("正在加载远程脚本 0/0", function()
    PreloadRemotes(inst)
end)

inst:AddTask("正在加载 Suture Hub", function()
    -- ★ [suture] 开启预编译模式：suif 主脚本内的远程脚本只下载+编译排队，
    --   等主窗口创建完成后由 suif 一次性批量挂载（不再逐个加载）
    local g = (getgenv and getgenv()) or _G
    if g then
        g.__SUIF_PRELOAD = true
        g.__SUIF_PENDING = g.__SUIF_PENDING or {}
    end
    local okSrc, src = pcall(function()
        return game:HttpGet(SUIF_URL)
    end)
    if not okSrc or type(src) ~= "string" or #src == 0 then
        error("suif main script fetch failed")
    end
    local fn, cerr = loadstring(src)
    if not fn then
        error(cerr)
    end
    fn()
end)

inst:Start(function()
    local g = (getgenv and getgenv()) or _G
    if g then
        g.__SUIF_READY = function()
            pcall(function()
                inst:Finish()
            end)
        end
    end
    Delay(10, function()
        pcall(function()
            inst:Finish()
        end)
    end)
end)

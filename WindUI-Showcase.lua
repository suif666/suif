-- WindUI Showcase v2.0 [suture] - full controls demo (per official docs)
-- 展示 WindUI 全部控件（按官方文档 https://footagesus.github.io/WindUI-Docs/docs）
-- 重点：Dialog / Popup / Tag / Notification 为公告候选控件
-- 执行本脚本 = 打开展示窗口，每个控件一个实例；分支没有的控件会打印"不可用"

-- ═══════════ Load WindUI (4 mirrors) ═══════════
local WINDUI_SRC = {
    "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand22",
    "https://cdn.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
    "https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand22",
    "https://gcore.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
}

local okWind, WindUI = pcall(function()
    for _, u in ipairs(WINDUI_SRC) do
        local got, src = pcall(function()
            return game:HttpGet(u)
        end)
        if got and type(src) == "string" and #src > 0 then
            local fn, cerr = loadstring(src)
            if fn then
                local ran, mod = pcall(fn)
                if ran and mod then
                    return mod
                end
            end
        end
    end
    error("WindUI load failed")
end)

if not okWind or not WindUI then
    warn("WindUI 加载失败:", WindUI)
    return
end

local Try = function(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        print("[showcase] " .. name .. " 不可用: " .. tostring(err))
    else
        print("[showcase] " .. name .. " OK")
    end
end

-- ═══════════ Window ═══════════
local win = WindUI:CreateWindow({
    Title = "WindUI 控件展示 v2",
    Icon = "aperture",
    Author = "by suif",
    Folder = "SutureShowcase",
    Size = UDim2.fromOffset(640, 480),
    MinSize = Vector2.new(560, 360),
    MaxSize = Vector2.new(900, 620),
    ToggleKey = Enum.KeyCode.RightShift,
    Resizable = true,
    HideSearchBar = false,
})

-- ═══════════ Tab 1: 公告候选 ═══════════
local home = win:Tab({ Title = "公告候选", Icon = "megaphone", Locked = false })
home:Paragraph({
    Title = "四个公告候选控件",
    Content = "1) Popup 模块级弹窗：无需窗口即可弹出，模态+多按钮(Variant样式)，公告确认首选。\n2) Dialog 窗口级对话框：需窗口已存在，样式与Popup相似，适合窗口内弹窗。\n3) Notification 角落通知：轻量短消息。\n4) Tag 版本徽章：显示版本号。\n5) 公告区块(Section+Paragraph)：嵌在窗口里常驻可见。\n下面逐个演示。",
})

home:Button({
    Title = "[候选1] Popup 弹窗",
    Callback = function()
        WindUI:Popup({
            Title = "Suture Hub 公告",
            Icon = "megaphone",
            Content = "Popup 是模块级弹窗：不需要窗口就能弹出，适合在加载阶段展示公告。按钮支持 Variant 样式（Primary 主按钮 / Tertiary 次要按钮）。",
            Buttons = {
                { Title = "取消", Callback = function() end, Variant = "Tertiary" },
                { Title = "复制公告", Icon = "copy", Callback = function()
                    local clip = setclipboard or (getgenv and getgenv().setclipboard)
                    if clip then clip("公告内容") end
                end, Variant = "Secondary" },
                { Title = "执行", Icon = "arrow-right", Callback = function()
                    WindUI:Notify({ Title = "已执行", Duration = 1.5, Icon = "check" })
                end, Variant = "Primary" },
            },
        })
    end,
})

home:Button({
    Title = "[候选2] Dialog 对话框",
    Callback = function()
        local Dialog = win:Dialog({
            Icon = "bird",
            Title = "Dialog 公告",
            Content = "Dialog 是窗口级对话框：需要窗口已存在。样式与 Popup 类似，同样支持多按钮。",
            Buttons = {
                { Title = "Confirm", Callback = function()
                    WindUI:Notify({ Title = "Confirmed!", Duration = 1.5, Icon = "check" })
                end, Variant = "Primary" },
                { Title = "Cancel", Callback = function() end, Variant = "Tertiary" },
            },
        })
        if Dialog and Dialog.Show then
            Dialog:Show()
        end
    end,
})

home:Button({
    Title = "[候选3] Notification 通知",
    Callback = function()
        WindUI:Notify({
            Title = "通知公告",
            Content = "角落弹出，几秒后消失，只适合短提示",
            Duration = 3,
            Icon = "bell",
        })
    end,
})

home:Button({
    Title = "[候选4] Tag 版本徽章",
    Callback = function()
        Try("Tag", function()
            win:Tag({
                Title = "v1.6.53",
                Icon = "github",
                Color = Color3.fromHex("#30ff6a"),
                Radius = 8,
            })
        end)
    end,
})

home:Button({
    Title = "[候选5] 常驻公告区块",
    Callback = function()
        local sec = win:Section({ Title = "公告", Icon = "megaphone", Opened = true })
        sec:Paragraph({
            Title = "公告标题",
            Content = "嵌在窗口里的常驻公告区，用户随时可翻到，不会被弹窗打断操作。适合长期公告/更新日志。",
        })
        sec:Button({
            Title = "标记已读",
            Callback = function()
                WindUI:Notify({ Title = "已读", Duration = 1.5, Icon = "check" })
            end,
        })
    end,
})

-- ═══════════ Tab 2: 全部元素控件 ═══════════
local ctrl = win:Tab({ Title = "元素控件", Icon = "wrench", Locked = false })

ctrl:Paragraph({ Title = "Paragraph 段落", Content = "多行文字，适合公告正文/说明。" })

ctrl:Button({
    Title = "Button 按钮",
    Callback = function()
        WindUI:Notify({ Title = "按钮被点击", Duration = 1.5, Icon = "check" })
    end,
})

ctrl:Toggle({
    Title = "Toggle 开关",
    Default = false,
    Callback = function(v)
        WindUI:Notify({ Title = "Toggle: " .. tostring(v), Duration = 1.5, Icon = "toggle" })
    end,
})

ctrl:Slider({
    Title = "Slider 滑条",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(v)
        WindUI:Notify({ Title = "Slider: " .. tostring(v), Duration = 1.5, Icon = "sliders" })
    end,
})

ctrl:Dropdown({
    Title = "Dropdown 下拉",
    Values = { "选项A", "选项B", "选项C" },
    Callback = function(v)
        WindUI:Notify({ Title = "Dropdown: " .. tostring(v), Duration = 1.5, Icon = "chevron-down" })
    end,
})

Try("Input 输入框", function()
    ctrl:Input({
        Title = "Input 输入框",
        Placeholder = "输入点什么...",
        Callback = function(v)
            WindUI:Notify({ Title = "Input: " .. tostring(v), Duration = 1.5, Icon = "text" })
        end,
    })
end)

Try("Keybind 按键绑定", function()
    ctrl:Keybind({
        Title = "Keybind 按键绑定",
        Key = Enum.KeyCode.RightShift,
        Callback = function()
            WindUI:Notify({ Title = "Keybind 触发", Duration = 1.5, Icon = "key" })
        end,
    })
end)

Try("Colorpicker 取色器", function()
    ctrl:Colorpicker({
        Title = "Colorpicker 取色器",
        Default = Color3.fromRGB(70, 150, 255),
        Callback = function(c)
            WindUI:Notify({ Title = "Color: " .. tostring(c), Duration = 1.5, Icon = "palette" })
        end,
    })
end)

Try("Code 代码块", function()
    ctrl:Code({
        Title = "Code 代码块",
        Code = "print('hello windui')",
    })
end)

Try("Section 区块", function()
    ctrl:Section({ Title = "内嵌 Section 区块", Icon = "folder", Opened = false })
end)

-- ═══════════ Tab 3: 窗口级 UI 组件 ═══════════
local wnd = win:Tab({ Title = "窗口组件", Icon = "layout", Locked = false })

wnd:Paragraph({
    Title = "窗口级组件说明",
    Content = "Window / Tab / TabSection / Dialog / Popup / Tag / Notification / Divider / Space 属于窗口级。\nDivider(分割线) 与 Space(间距) 用于排版。",
})

Try("Divider 分割线", function()
    wnd:Divider()
end)

Try("Space 间距", function()
    wnd:Space({ Size = 20 })
end)

Try("TabSection 标签分组", function()
    local ts = wnd:TabSection({ Title = "Tab 分组", Icon = "folder" })
    ts:Tab({ Title = "子标签A", Icon = "file" })
    ts:Tab({ Title = "子标签B", Icon = "file" })
end)

wnd:Button({
    Title = "窗口主题切换",
    Callback = function()
        local themes = WindUI.GetThemes and WindUI:GetThemes() or nil
        if themes and next(themes) then
            local name = themes[1]
            WindUI:SetTheme(name)
            WindUI:Notify({ Title = "主题: " .. tostring(name), Duration = 2, Icon = "palette" })
        else
            WindUI:Notify({ Title = "无可用主题", Duration = 2, Icon = "warning" })
        end
    end,
})

print("[showcase] WindUI 控件展示窗口已打开")

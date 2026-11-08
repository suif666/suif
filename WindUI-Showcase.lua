-- WindUI Showcase v1.0 [suture]
-- 展示 WindUI 全部可用控件，供判断哪个最适合当「公告」弹窗
-- 执行本脚本 = 打开一个展示窗口，每个控件一个实例

-- ═══════════ 加载 WindUI（4 镜像容错） ═══════════
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

-- ═══════════ 创建展示窗口 ═══════════
local win = WindUI:CreateWindow({
    Title = "WindUI 控件展示",
    Icon = "aperture",
    Author = "by suif",
    Folder = "SutureShowcase",
    Size = UDim2.fromOffset(620, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(900, 600),
    ToggleKey = Enum.KeyCode.RightShift,
    Resizable = true,
    HideSearchBar = false,
})

-- ═══════════ Tab 1：公告候选 ═══════════
local home = win:Tab({ Title = "公告候选", Icon = "megaphone", Locked = false })
home:Paragraph({
    Title = "候选控件说明",
    Content = "1) Popup 模态弹窗：全屏遮罩+居中卡片，自带按钮回调（复制/执行），最适合公告确认。\n2) Notify 角落通知：轻量提示条，只适合短消息。\n3) 独立公告窗口：完整窗口，可放长文+滚动，正式但较重。\n下面两个按钮分别演示 Popup 和 Notify 的真实效果。",
})
home:Button({
    Title = "演示 Popup（公告候选）",
    Callback = function()
        WindUI:Popup({
            Title = "Suture Hub 公告",
            Content = "这是一条用 Popup 做的公告内容。Popup 是全屏遮罩+居中卡片，支持图标、多按钮回调。点击下方按钮体验交互。",
            Icon = "megaphone",
            Buttons = {
                { Title = "取消", Callback = function() end },
                { Title = "复制", Callback = function()
                    local clip = setclipboard or (getgenv and getgenv().setclipboard)
                    if clip then
                        clip("公告内容已复制")
                    end
                end },
                { Title = "执行", Callback = function() end },
            },
        })
    end,
})
home:Button({
    Title = "演示 Notify（轻量通知）",
    Callback = function()
        WindUI:Notify({
            Title = "这是一条 Notify",
            Content = "角落弹出，几秒后消失，只适合短提示",
            Duration = 3,
            Icon = "bell",
        })
    end,
})

-- ═══════════ Tab 2：基础控件全展示 ═══════════
local ctrl = win:Tab({ Title = "基础控件", Icon = "wrench", Locked = false })

ctrl:Paragraph({
    Title = "Paragraph 段落",
    Content = "适合放公告正文/说明文字，可多行。",
})

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

-- 以下控件可能因版本差异 API 名不同，逐个 try，可用则显示，不可用则打印提示
local function Try(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        print("[showcase] " .. name .. " 不可用: " .. tostring(err))
    else
        print("[showcase] " .. name .. " OK")
    end
end

Try("TextBox", function()
    ctrl:TextBox({
        Title = "TextBox 输入框",
        Placeholder = "输入点什么...",
        Callback = function(v)
            WindUI:Notify({ Title = "TextBox: " .. tostring(v), Duration = 1.5, Icon = "text" })
        end,
    })
end)

Try("Keybind", function()
    ctrl:Keybind({
        Title = "Keybind 按键绑定",
        Key = Enum.KeyCode.RightShift,
        Callback = function()
            WindUI:Notify({ Title = "Keybind 触发", Duration = 1.5, Icon = "key" })
        end,
    })
end)

Try("ColorPicker", function()
    ctrl:ColorPicker({
        Title = "ColorPicker 取色器",
        Default = Color3.fromRGB(70, 150, 255),
        Callback = function(c)
            WindUI:Notify({ Title = "Color: " .. tostring(c), Duration = 1.5, Icon = "palette" })
        end,
    })
end)

Try("Label", function()
    ctrl:Label({ Title = "Label 纯文本标签" })
end)

Try("Divider", function()
    ctrl:Divider()
end)

-- ═══════════ Tab 3：窗口级控件 ═══════════
local wnd = win:Tab({ Title = "窗口/分组", Icon = "layout", Locked = false })
wnd:Paragraph({
    Title = "Section 分组 + Tab 多标签",
    Content = "整个 Suture Hub 就是由 Section（分组）+ Tab（标签页）+ 控件组成的。\n公告也可以做成一个独立 Section，嵌进主页，随时可见。",
})
wnd:Button({
    Title = "创建公告 Section",
    Callback = function()
        local sec = win:Section({ Title = "公告", Icon = "megaphone", Opened = true })
        sec:Paragraph({
            Title = "公告标题",
            Content = "这是嵌在窗口里的公告区块，用户随时能翻到，不会被弹窗打断。",
        })
        sec:Button({
            Title = "标记已读",
            Callback = function()
                WindUI:Notify({ Title = "已读", Duration = 1.5, Icon = "check" })
            end,
        })
    end,
})

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

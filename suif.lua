local WindUI
do
    local ok, res = pcall(function()
        local source = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
        local fn, compileErr = loadstring(source)
        if not fn then
            error(compileErr)
        end
        return fn()
    end)

    if not ok or not res then
        warn("WindUI 加载失败，脚本已停止:", res)
        return
    end

    WindUI = res
end

local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

-- 【视觉体积优化版】全局通知函数
local function notify(title, content, icon, duration)
    local shortText = title
    if content and content ~= "" then
        shortText = title .. " | " .. content
    end

    local ok, err = pcall(function()
        WindUI:Notify({ Title = shortText, Duration = duration or 2, Icon = icon or "bell" })
    end)

    if not ok then
        warn("通知失败:", err)
    end
end

local function run(url, name)
    task.spawn(function()
        local ok, err = pcall(function()
            local source = game:HttpGet(url)
            local fn, compileErr = loadstring(source)
            if not fn then
                error(compileErr)
            end
            fn()
        end)

        if ok then
            notify("执行成功", (name or "脚本") .. " 已运行", "check", 2)
        else
            warn("执行失败: " .. tostring(err))
        end
    end)
end

-- 后台异步加载远程模块：失败自动重试，仍失败时给出可见提示
local function loadRemote(url, desc)
    task.spawn(function()
        local ok, err
        for attempt = 1, 3 do
            ok, err = pcall(function()
                local src = game:HttpGet(url)
                local fn, compileErr = loadstring(src)
                if not fn then
                    error(compileErr)
                end
                fn()
            end)
            if ok then
                return
            end
            task.wait(0.5 * attempt)
        end
        warn((desc or "远程脚本") .. " 加载失败:", err)
        pcall(notify, desc or "远程脚本", "加载失败：" .. tostring(err), "warning", 5)
    end)
end

-- 全局通用防爆杀 (Adonis Bypass)
getgenv().bypass_adonis = true
--反挂机
if not getgenv().SutureHubAntiAFK then
    getgenv().SutureHubAntiAFK = true

    local function disableIdleConnections()
        if not getconnections then
            return nil, "当前执行器不支持 getconnections"
        end

        local found = false
        for _, conn in ipairs(getconnections(lp.Idled)) do
            found = true
            if conn.Disable then
                conn:Disable()
            elseif conn.Disconnect then
                conn:Disconnect()
            end
        end
        if not found then
            return nil, "未发现闲置检测连接"
        end
        return true
    end

    local ok, res = pcall(disableIdleConnections)
    if ok and res then
        notify("防挂机", "正在运行", "info", 2)
        -- 定时复查：防止游戏脚本重新挂上闲置检测连接
        task.spawn(function()
            while getgenv().SutureHubAntiAFK do
                task.wait(180)
                pcall(disableIdleConnections)
            end
        end)
    elseif ok then
        warn("防挂机:", res)
    else
        warn("防挂机启动失败:", res)
    end
end

local uiSet = { Theme = "Dark", Transparent = true, HideSearchBar = false, SideBarWidth = 180 }

local win = WindUI:CreateWindow({
    Title = "Suture Hub", Icon = "aperture", Author = "by suif", Folder = "SutureHub",
    Size = UDim2.fromOffset(620, 460), MinSize = Vector2.new(560, 350), MaxSize = Vector2.new(900, 600),
    ToggleKey = Enum.KeyCode.RightShift, Transparent = uiSet.Transparent, Theme = uiSet.Theme,
    Resizable = true, SideBarWidth = uiSet.SideBarWidth, HideSearchBar = uiSet.HideSearchBar,
    ScrollBarEnabled = true, NewElements = true,
    User = { Enabled = true, Anonymous = false, Callback = function() print("当前用户:", lp.Name) end }
})

win:Tag({ Title = "free", Icon = "gem", Color = Color3.fromHex("#30ff6a"), Radius = 0 })

-- 主窗口可见性广播：子脚本的独立浮层（雷达、Ping/FPS 等）跟随主 UI 一起显示/隐藏
getgenv().SutureMainWindow = win
getgenv().SutureMainUIVisible = true
task.spawn(function()
    while true do
        task.wait(0.15)
        local ok, vis = pcall(function()
            return win.UIElements.Main.Visible
        end)
        getgenv().SutureMainUIVisible = ok and vis or false
    end
end)

--// 【彩虹边框】原版 while 逻辑回归
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 3
UIStroke.LineJoinMode = Enum.LineJoinMode.Round
UIStroke.Parent = win.UIElements.Main

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
}
UIGradient.Parent = UIStroke

task.spawn(function()
    while true do
        local dt = task.wait()
        UIGradient.Rotation = (UIGradient.Rotation + dt * 200) % 360
    end
end)


local dialog
dialog = win:Dialog({
    Icon = "megaphone", Title = "公告", Content = "觉得脚本好用的话可以分享给好友 如果感觉哪里不好可以点击右上角反馈按钮进行反馈",
    Buttons = {
        {
            Title = "我知晓",
            Callback = function()
                if dialog and dialog.Close then
                    dialog:Close()
                end
            end
        }
    }
})
task.delay(1, function()
    if dialog and dialog.Show then
        dialog:Show()
    end
end)
-- 防止公告弹窗挡住关闭/最小化按钮：5 秒后自动关闭
task.delay(5, function()
    if dialog and dialog.Close then
        dialog:Close()
    end
end)

-- 主页
local mainTab = win:Tab({ Title = "主页", Icon = "house", Locked = false })
mainTab:Select()

-- 功能类
local funcSec = win:Section({ Title = "功能", Icon = "folder", Opened = false })
local playerTab = funcSec:Tab({ Title = "玩家类", Icon = "user", Locked = false })
local FwTab = funcSec:Tab({ Title = "范围类", Icon = "user", Locked = false })
local SfTab = funcSec:Tab({ Title = "甩飞类", Icon = "user", Locked = false })
local amTab = funcSec:Tab({ Title = "自瞄类", Icon = "user", Locked = false })
local sayTab = funcSec:Tab({ Title = "发言类", Icon = "user", Locked = false })
local fyTab = funcSec:Tab({ Title = "翻译类", Icon = "languages", Locked = false })
local toolTab = funcSec:Tab({ Title = "工具类", Icon = "wrench", Locked = false })
local serverTab = funcSec:Tab({ Title = "服务器类", Icon = "user", Locked = false })

-- 视觉类
local shijueSec = win:Section({ Title = "视觉类", Icon = "palette", Locked = false })
local espTab = shijueSec:Tab({ Title = "透视类", Icon = "user", Locked = false })
local pingfpsTab = shijueSec:Tab({ Title = "ping/fps显示", Icon = "rss", Locked = false })
local radarTab = shijueSec:Tab({ Title = "雷达", Icon = "radar", Locked = false })
local fovTab = shijueSec:Tab({ Title = "视野", Icon = "palette", Locked = false })

-- 脚本类
local scriptSec = win:Section({ Title = "脚本类", Icon = "folder", Opened = false })
-- 脚本区由后台动态配置生成（/scriptconfig）
local HttpService = game:GetService("HttpService")
getgenv().Tabs = getgenv().Tabs or {}

local scriptConfigOk, scriptConfig = pcall(function()
	local src = game:HttpGet("https://suture-hub-counter.sfbdsl666.workers.dev/scriptconfig", true)
	return HttpService:JSONDecode(src)
end)

if scriptConfigOk and type(scriptConfig) == "table" and type(scriptConfig.tabs) == "table" then
	for _, tabData in ipairs(scriptConfig.tabs) do
		local tab = scriptSec:Tab({ Title = tabData.name or "未命名", Icon = tabData.icon or "shell", Locked = false })
		getgenv().Tabs[tabData.var or tabData.name] = tab
		if tabData.var == "xesqTab" then
			getgenv().SutureGameTab = tab
			getgenv().Tabs.GameTab = tab
		elseif tabData.var == "zrzhTab" then
			getgenv().SutureZRZHTab = tab
			getgenv().Tabs.ZRZHTab = tab
		end
		local frags = tabData.codeFrags
		if type(frags) ~= "table" or #frags == 0 then
			-- 兼容旧配置：按 notes/scripts/module/autoRun 顺序渲染
			for _, note in ipairs(tabData.notes or {}) do
				tab:Paragraph({ Title = note.title or "", Desc = note.desc or "" })
			end
			for _, s in ipairs(tabData.scripts or {}) do
				tab:Button({
					Title = s.name or "脚本",
					Icon = "shell",
					Callback = function()
						if s.preCode and s.preCode ~= "" then
							local preFn, preErr = loadstring(s.preCode)
							if preFn then
								pcall(preFn)
							else
								warn("[SutureHub] 前置代码错误:", preErr)
							end
						end
						run(s.url, s.displayName or s.name)
					end
				})
			end
			if tabData.moduleUrl and tabData.moduleUrl ~= "" then
				local moduleUrl = tabData.moduleUrl
				if moduleUrl:find("?t=", 1, true) then
					moduleUrl = moduleUrl .. tostring(tick())
				elseif moduleUrl:find("?", 1, true) then
					moduleUrl = moduleUrl .. "&t=" .. tostring(tick())
				else
					moduleUrl = moduleUrl .. "?t=" .. tostring(tick())
				end
				loadRemote(moduleUrl, tabData.name or "模块")
			end
			for _, autoUrl in ipairs(tabData.autoRun or {}) do
				run(autoUrl, tabData.name or "自动脚本")
			end
		else
			-- 按 codeFrags 顺序渲染（后台可调整位置，游戏内同样生效）
			for _, frag in ipairs(frags) do
				if frag.type == "paragraph" then
					local n = tabData.notes and tabData.notes[frag.noteIdx]
					if n then
						tab:Paragraph({ Title = n.title or "", Desc = n.desc or "" })
					end
				elseif frag.type == "space" then
					tab:Space()
				elseif frag.type == "button" then
					local s = nil
					if frag.scriptId then
						for _, x in ipairs(tabData.scripts or {}) do
							if x.id == frag.scriptId then
								s = x
								break
							end
						end
					end
					if s then
						tab:Button({
							Title = s.name or "脚本",
							Icon = "shell",
							Callback = function()
								if s.preCode and s.preCode ~= "" then
									local preFn, preErr = loadstring(s.preCode)
									if preFn then
										pcall(preFn)
									else
										warn("[SutureHub] 前置代码错误:", preErr)
									end
								end
								run(s.url, s.displayName or s.name)
							end
						})
					end
				elseif frag.type == "module" then
					if tabData.moduleUrl and tabData.moduleUrl ~= "" then
						local moduleUrl = tabData.moduleUrl
						if moduleUrl:find("?t=", 1, true) then
							moduleUrl = moduleUrl .. tostring(tick())
						elseif moduleUrl:find("?", 1, true) then
							moduleUrl = moduleUrl .. "&t=" .. tostring(tick())
						else
							moduleUrl = moduleUrl .. "?t=" .. tostring(tick())
						end
						loadRemote(moduleUrl, tabData.name or "模块")
					end
				elseif frag.type == "run" then
					local u = tabData.autoRun and tabData.autoRun[frag.runIdx]
					if u and u ~= "" then
						run(u, tabData.name or "自动脚本")
					end
				end
				-- line 片段：getgenv 引用已由上方特判处理，直接跳过
			end
		end
	end
else
	warn("[SutureHub] 后台脚本配置加载失败，脚本区为空")
end

local settingsTab = win:Tab({ Title = "设置", Icon = "user", Locked = false })

-- WindUI 原生顶栏反馈入口
local FeedbackURL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif%E8%84%9A%E6%9C%AC%E5%8F%8D%E9%A6%88%E6%B8%A0%E9%81%93.lua"

-- 屏蔽“执行脚本时反馈模块自己弹出的加载通知”
-- 但保留用户真正发送反馈时可能需要的成功/失败提示
local function feedbackNotify(title, content, icon, duration)
    local msg = tostring(title or "") .. " " .. tostring(content or "")

    if msg:find("加载", 1, true)
        or msg:find("初始化", 1, true)
        or msg:find("入口", 1, true)
        or msg:find("已启动", 1, true)
        or msg:find("已就绪", 1, true)
    then
        warn("反馈模块已加载", msg)
        return
    end

    notify(title, content, icon, duration)
end

getgenv().SutureHubFeedback = {
    API = "https://suture-feedback.sfbdsl666.workers.dev/",
    WindUI = WindUI,
    Window = win,
    Notify = feedbackNotify
}

task.spawn(function()
    task.wait(0.5)

    local ok, err = pcall(function()
        local src = game:HttpGet(FeedbackURL)
        local fn, loadErr = loadstring(src)

        if not fn then
            error(loadErr)
        end

        fn()
    end)

    if not ok then
        warn("反馈模块加载失败:", err)
    end
end)



-- 主页

mainTab:Paragraph({
    Title = "小提醒",
    Desc = "脚本右上角可以进行反馈\n脚本名字带有[🔑]则需要卡密 没有就是不需要"
})

mainTab:Paragraph({
    Title = "Suture Hub",
    Desc = "欢迎使用 Suture Hub\n作者：suif\n当前玩家：" .. lp.Name
})

local countText = mainTab:Paragraph({
    Title = "全网执行次数",
    Desc = "正在获取..."
})

local function updateCount()
    local ok, res = pcall(function()
        local player = game.Players.LocalPlayer
        local playerName = player.Name
        local displayName = player.DisplayName
        local userId = tostring(player.UserId)
        local accountAge = tostring(player.AccountAge)
        local maxPlayers = tostring(game.Players.MaxPlayers)

        -- 获取真实游戏名
        local gameName = game.Name
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name then
                gameName = info.Name
            end
        end)

        -- 获取注入器名称
        local executor = "未知"
        pcall(function()
            executor = identifyexecutor() or "未知"
        end)

        local HttpService = game:GetService("HttpService")
        local url = "https://suture-hub-counter.sfbdsl666.workers.dev/count"
            .. "?player="      .. HttpService:UrlEncode(playerName)
            .. "&displayname=" .. HttpService:UrlEncode(displayName)
            .. "&userid="      .. HttpService:UrlEncode(userId)
            .. "&game="        .. HttpService:UrlEncode(gameName)
            .. "&placeid="     .. HttpService:UrlEncode(tostring(game.PlaceId))
            .. "&accountage="  .. HttpService:UrlEncode(accountAge)
            .. "&executor="    .. HttpService:UrlEncode(executor)
            .. "&maxplayers="  .. HttpService:UrlEncode(maxPlayers)

        return game:HttpGet(url)
    end)

    if ok then
        res = tostring(res)
        if countText.SetDesc then
            countText:SetDesc("当前全网执行次数：" .. res)
        end
        notify("执行统计", "次数：" .. res, "activity", 2)
    else
        if countText.SetDesc then
            countText:SetDesc("获取失败")
        end
        warn("全网执行次数获取失败:", res)
    end
end

task.spawn(updateCount)

mainTab:Select()

fyTab:Paragraph({
    Title = "注意",
    Desc = "先用别人写好的 等我用空了在自己写一个"
})

fyTab:Space()

fyTab:Button({
    Title = "devastate翻译", Desc = "字面意思", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/dream6-e/rbx/refs/heads/main/%E7%BF%BB%E8%AF%91%E8%84%9A%E6%9C%AC.lua", "devastate翻译")
    end
})

-- 视觉

-- ============ 视野（FOV） ============
local RunService = game:GetService("RunService")
local fovConn = nil
pcall(function()
    fovTab:Slider({
        Title = "视野角度",
        Desc = "70 = 默认，120 = 广角，会持续锁定防止被游戏重置",
        Step = 1,
        Value = { Min = 70, Max = 120, Default = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70 },
        Callback = function(v)
            local fov = tonumber(v) or 70
            if fovConn then
                fovConn:Disconnect()
                fovConn = nil
            end
            fovConn = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                if cam and cam.FieldOfView ~= fov then
                    cam.FieldOfView = fov
                end
            end)
        end
    })
end)

-- 即时互动（极简版，几乎不掉帧）
getgenv().SutureHubPromptHoldCache = getgenv().SutureHubPromptHoldCache or setmetatable({}, { __mode = "k" })
local PromptHoldCache = getgenv().SutureHubPromptHoldCache

for prompt, oldHold in pairs(PromptHoldCache) do
    if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") and oldHold ~= nil then
        pcall(function() prompt.HoldDuration = oldHold end)
    end
    PromptHoldCache[prompt] = nil
end

getgenv().InstantInteract = false

local PromptConn

-- 断开上次执行遗留的连接
if getgenv().SuturePromptAddedConn then
    pcall(function() getgenv().SuturePromptAddedConn:Disconnect() end)
    getgenv().SuturePromptAddedConn = nil
end

local function setInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if PromptHoldCache[prompt] == nil then
        PromptHoldCache[prompt] = prompt.HoldDuration
    end
    if prompt.HoldDuration ~= 0 then
        prompt.HoldDuration = 0
    end
end

local function restoreAllPrompts()
    for prompt, oldHold in pairs(PromptHoldCache) do
        if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") then
            pcall(function() prompt.HoldDuration = oldHold end)
        end
        PromptHoldCache[prompt] = nil
    end
end

local function setPromptListener(enable)
    if enable then
        if not PromptConn then
            PromptConn = workspace.DescendantAdded:Connect(function(v)
                if v:IsA("ProximityPrompt") then
                    setInstantPrompt(v)
                end
            end)
            getgenv().SuturePromptAddedConn = PromptConn
        end
    elseif PromptConn then
        pcall(function() PromptConn:Disconnect() end)
        PromptConn = nil
        getgenv().SuturePromptAddedConn = nil
    end
end

toolTab:Toggle({
    Title = "即时互动",
    Desc = "关闭恢复初始数值，但可能需要玩家死亡一次或互动按钮刷新一次",
    Icon = "zap",
    Type = "Checkbox",
    Value = false,
    Callback = function(s)
        getgenv().InstantInteract = s
        if s then
            setPromptListener(true)
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    setInstantPrompt(v)
                end
            end
        else
            setPromptListener(false)
            restoreAllPrompts()
        end
    end
})


toolTab:Button({
    Title = "Gui文本获取v25", Desc = "自制 ai神力 感谢李藝州🙏🙏🙏", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/UI%E6%96%87%E6%9C%AC%E6%8F%90%E5%8F%96.lua", "Gui文本获取v25") end
})

toolTab:Button({
    Title = "dex汉化", Desc = "顾名思义", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/dex.lua", "dex汉化") end
})

toolTab:Button({
    Title = "iy汉化", Desc = "顾名思义", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/config/iy%E6%B1%89%E5%8C%96%E7%89%88", "iy汉化") end
})



--范围远程
getgenv().Tabs.RangeTab = FwTab          -- 这里换成你实际创建的 Tab 变量名

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua?t=" .. tostring(tick()), "范围")

--甩飞远程
getgenv().Tabs.FlingTPTab = SfTab
getgenv().WindUI = WindUI

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%94%A9%E9%A3%9E.lua?t=" .. tostring(tick()), "甩飞")

--ping fps显示
getgenv().Tabs.PingFPSTab = pingfpsTab
getgenv().SuturePingFPSTab = pingfpsTab

loadRemote("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%98%BE%E7%A4%BAfps%E5%92%8Cping.lua?t=" .. tostring(tick()), "ping/fps显示")

--雷达
getgenv().Tabs.RadarTab = radarTab
getgenv().SutureRadarTab = radarTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "雷达")

--玩家类远程
getgenv().Tabs.PlayerTab = playerTab
getgenv().SuturePlayerTab = playerTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua?t=" .. tostring(tick()), "玩家类")

--自瞄类远程
getgenv().Tabs.AimbotTab = amTab
getgenv().SutureAimbotTab = amTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua?t=" .. tostring(tick()), "自瞄类")

--发言类远程
getgenv().Tabs.SayTab = sayTab
getgenv().SutureSayTab = sayTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "发言类")

--ESP远程
getgenv().Tabs.ESPTab = espTab
getgenv().SutureESPTab = espTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "ESP")

--服务器类远程
getgenv().Tabs.ServerTab = serverTab
getgenv().SutureServerTab = serverTab

loadRemote("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua?t=" .. tostring(tick()), "服务器类")

-- UI设置
local themeMap = {
    ["深色"]="Dark", ["浅色"]="Light", ["玫瑰"]="Rose", ["植物"]="Plant", ["红色"]="Red",
    ["靛蓝"]="Indigo", ["天空蓝"]="Sky", ["紫罗兰"]="Violet", ["琥珀"]="Amber"
}
settingsTab:Dropdown({
    Title = "UI 主题", Desc = "切换 UI 主题",
    Values = { "深色","浅色","玫瑰","植物","红色","靛蓝","天空蓝","紫罗兰","琥珀" },
    Value = "深色",
    Callback = function(name)
        local real = themeMap[name]
        uiSet.Theme = real
        if WindUI.SetTheme then WindUI:SetTheme(real) elseif win.SetTheme then win:SetTheme(real) end
    end
})

WindUI:Notify({
    Title = "Suture Hub",
    Content = "成功加载全部功能！",
    Icon = "aperture",
    Duration = 3
})

WindUI:Notify({
    Title = "小提示",
    Content = "遇到什么问题\n没有自己想玩的服务器\n脚本没法执行\n可以点右上角的反馈按钮进行反馈",
    Icon = "message-square-warning",
    Duration = 10
})

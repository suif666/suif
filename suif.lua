-- ══════════════════════════════════════════════════════════════════════════════
-- 【防护加固】远程脚本，加载脚本时自动下载并执行（不需要点任何按钮）
-- 原 1-196 行（静默层 + 全局 print/warn 过滤 + 安全 task + 容器代名支持）
-- 全部在「防护加固.lua」里；这里同步拉取执行，失败自动降级为「无加固但能跑」。
-- 开关：getgenv().SutureNoHarden = true 全关；getgenv().SutureVerbose = true 打日志
-- ══════════════════════════════════════════════════════════════════════════════
local HARDEN = {}
pcall(function()
    local HSvc = game:GetService("HttpService")
    local rawUrl = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/" .. HSvc:UrlEncode("防护加固.lua")
    local proxy = "https://suture-hub-counter.sfbdsl666.workers.dev/proxy?url=" .. HSvc:UrlEncode(rawUrl)
    local body = nil
    local ok1, r1 = pcall(function() return game:HttpGet(proxy, true) end)
    if ok1 and type(r1) == "string" and #r1 > 500 then
        body = r1
    else
        local ok2, r2 = pcall(function() return game:HttpGet(rawUrl, true) end)
        if ok2 and type(r2) == "string" and #r2 > 500 then
            body = r2
        end
    end
    if body then
        local fn = loadstring(body)
        if fn then
            local R = fn()
            if type(R) == "table" then HARDEN = R end
        end
    end
end)

-- 从加固表接管能力（加固脚本内部已替换全局 print/warn 并定义安全 task）
local __HARD = HARDEN.HARD ~= false
local task = (type(HARDEN.task) == "table") and HARDEN.task or task
local __sutLog = type(HARDEN.log) == "function" and HARDEN.log or function(...) end
local __sandbox = type(HARDEN.sandbox) == "function" and HARDEN.sandbox or function(fn) return fn end


-- ★ 多源加载：raw.githubusercontent 在某些网络下会被掐，jsDelivr 更稳。
--   两条都是通用 CDN 域名，交替重试，避免单点失效导致整个脚本加载不出来。
local __WINDUI_SRC = {
    -- ★ WindUI-Boreal.lua 主文件已直接覆盖为 v0.0.3 [suture] 改造版：
    --   v0.2.1：滑条移除 / Expand WinUI / Slider 输入超限 / Dropdown 放大菜单（克隆+内部点击修复+hover）
    --   cdn/gcore 用 @commit 锁定版本（零缓存问题）；下次改库上传后必须同步更新下面两个 commit！
    --   当前锁定 commit: 2f7140bc37b525d1cdd154db7cb0b05c0379de01
    "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand11",
    "https://cdn.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
    "https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand11",
    "https://gcore.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
}
local __LoadedVersion = "未知"
local ok, WindUI = pcall(function()
    -- [suture] 加载器预载模式：_G.WindUI 已存在则直接使用，避免重复加载双实例
    local g = (getgenv and getgenv()) or _G
    if g and g.WindUI then
        __LoadedVersion = "WindUI（由加载器预载）✓"
        return g.WindUI
    end
    local lastErr
    for _, u in ipairs(__WINDUI_SRC) do
        local got, src = pcall(function() return game:HttpGet(u) end)
        if got and type(src) == "string" and #src > 0 then
            local fn, cerr = loadstring(src)
            __sandbox(fn)                      -- ★ 静默 WindUI 自己的 20 处 warn
            if fn then
                local ran, mod = pcall(fn)
                if ran and mod then
                    -- ★ 加载版本检测：[suture] 标记 = v0.0.2 改造版
                    if src:find("Version: v0.0.7", 1, true) then
                        __LoadedVersion = "WindUI v0.0.7 [suture 改造版] ✓（居中放大菜单+横排+标题栏）"
                    elseif src:find("-- [suture]", 1, true) then
                        __LoadedVersion = "WindUI 旧改造版 ⚠（非 v0.0.7，需清缓存重载）"
                    else
                        __LoadedVersion = "WindUI 原版 ⚠（改造版未加载成功，已回退）"
                    end
                    return mod
                end
                lastErr = mod
            else
                lastErr = cerr
            end
        else
            lastErr = src
        end
    end
    error(lastErr)
end)
if ok and WindUI then
    -- 执行器控制台可见提示（部分执行器支持 rconsoleprint）
    pcall(function() if rconsoleprint then rconsoleprint("[" .. __LoadedVersion .. "] 加载源列表见 SutureLog(true)") end end)
    print("[suture] " .. __LoadedVersion)      -- 走静默层内存日志，SutureLog(true) 可查
end

if not ok or not WindUI then
    warn("WindUI(Boreal) 加载失败:", WindUI)
    pcall(function()
        if setclipboard then
            setclipboard("Boreal加载失败: " .. tostring(WindUI))
        end
    end)
    return
end

local lp = game:GetService("Players").LocalPlayer

-- ══════════════════════════════════════════════════════════════════════════════
-- 【隐藏容器】ScreenGui 只有挂在 PlayerGui 或 CoreGui 下才会渲染。
-- 但 PlayerGui 是游戏自己的 LocalScript 能枚举到的地方 ——
-- 「PlayerGui.DescendantAdded 监听 + ScreenGui 名字黑名单」是游戏抓脚本 UI
-- 最常用的一招：UI 一挂上去就上报，你还没开任何功能，封禁已经下来了。
-- CoreGui 游戏读不到，所以优先 gethui()，退化到 CoreGui；
-- 两条路都拿不到才退回 PlayerGui（那种情况下名字也随机，尽量降低被匹配概率）。
-- ══════════════════════════════════════════════════════════════════════════════
local __rnd = function(len)
    local out = {}
    for i = 1, (len or 12) do out[i] = ("%x"):format(math.random(0, 15)) end
    return table.concat(out)
end

local HIDDEN = (function()
    if not __HARD then return lp:WaitForChild("PlayerGui") end   -- ★ 开关关掉就挂回原处
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local okc, cg = pcall(function() return game:GetService("CoreGui") end)
    if okc and cg then return cg end
    return lp:WaitForChild("PlayerGui")     -- 最后退路
end)()

-- 拿到就顺手保护起来（有些执行器靠这个把容器从游戏的可见范围里摘出去）
pcall(function()
    if not __HARD then return end
    if protect_gui then protect_gui(HIDDEN)
    elseif syn and syn.protect_gui then syn.protect_gui(HIDDEN) end
end)

-- 【视觉体积优化版】全局通知函数
local function notify(title, content, icon, duration)
    -- ★ 配置恢复期间静音：套用存档会触发几十个控件的 Callback，每个都弹一下就是刷屏。
    --   设 getgenv().__SUIF_QUIET = true 期间全部丢弃，读完只弹一条汇总。
    local _gq = (getgenv and getgenv()) or _G
    if _gq and _gq.__SUIF_QUIET then
        return
    end

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

-- ★ worker 代理优先：加速器环境可能只有 workers.dev 可达
local PROXY_API = "https://suture-hub-counter.sfbdsl666.workers.dev/proxy?url="
local function httpGetWithProxy(url)
    local HS = game:GetService("HttpService")
    local ok, src = pcall(function()
        return game:HttpGet(PROXY_API .. HS:UrlEncode(url))
    end)
    if ok and type(src) == "string" and #src > 0 then
        return src
    end
    return game:HttpGet(url)  -- 代理失败回退直连
end

local function run(url, name)
    task.spawn(function()
        local ok, err = pcall(function()
            local source = httpGetWithProxy(url)
            local fn, compileErr = loadstring(source)
            __sandbox(fn)                      -- ★ 远程脚本静默
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

-- 后台异步加载远程模块：失败自动重试 3 次，成功回调 onSuccess，仍失败时给出可见提示并回调 onFail
-- ★ [suture] 预编译模式：加载器驱动时（getgenv().__SUIF_PRELOAD=true）远程脚本只下载+编译
--   不立即执行，存入 __SUIF_PENDING 队列；等主窗口创建完成后由 initMainScript 一次性批量挂载
local function loadRemote(url, desc, onSuccess, onFail)
    task.spawn(function()
        local ok, err
        for attempt = 1, 3 do
            ok, err = pcall(function()
                local g2 = (getgenv and getgenv()) or _G
                -- ★ 预编译缓存命中：加载器已经把源码下载并编译好了，直接执行，不重复下载
                local cached = g2 and g2.__PRELOADED_FNS and g2.__PRELOADED_FNS[url]
                if type(cached) == "function" then
                    g2.__PRELOADED_FNS[url] = nil   -- 一次性消费，避免重复挂载出两份控件
                    cached()
                    return
                end
                local src = httpGetWithProxy(url)
                local fn, compileErr = loadstring(src)
                __sandbox(fn)                  -- ★ 远程脚本静默
                if not fn then
                    error(compileErr)
                end
                if g2 and g2.__SUIF_PRELOAD then
                    -- 排队交给常驻挂载循环消费（它每 0.1 秒检查一次新任务，
                    -- 所以点页签这种晚到的加载也能被执行，不会再"点了没反应"）
                    g2.__SUIF_PENDING = g2.__SUIF_PENDING or {}
                    table.insert(g2.__SUIF_PENDING, fn)
                else
                    fn()
                end
            end)
            if ok then
                if onSuccess then
                    pcall(onSuccess)
                end
                return
            end
            task.wait(0.5 * attempt)
        end
        warn((desc or "远程脚本") .. " 加载失败:", err)
        pcall(notify, desc or "远程脚本", "加载失败：" .. tostring(err), "warning", 5)
        if onFail then
            pcall(onFail)
        end
    end)
end

-- 懒加载登记表：Index -> item{ url, desc, state }
-- state: pending(未加载) / loading(加载中) / done(成功) / failed(失败待重试)
local lazyTabs = {}
local lazyOrder = {}
-- 统一加载入口：状态机驱动
local function startLoad(item)
    item.state = "loading"
    loadRemote(item.url, item.desc,
        function()
            item.state = "done"
        end,
        function()
            item.state = "failed"
        end)
end

-- onDemand=true 的游戏专属脚本：点对应 Tab 时才加载（避免启动全量加载卡顿）
local function lazyLoad(url, desc, tab, onDemand)
    -- ★ 原来要求 tab.Index 必须存在，批量创建时若 Index 还没赋值会整个跳过注册
    --   → 远程脚本永远不加载。现在 tab 存在就注册，Index 缺失用对象自身当 key。
    if tab then
        local tabKey = tab.Index
        if tabKey == nil then tabKey = tab end
        local item = { url = url, desc = desc, state = "pending", onDemand = onDemand or false }
        -- ★ 不再因为「已预下载」就标 done：那样点页签永远不挂载。
        --   预下载只是把编译结果缓存到 __PRELOADED_FNS，实际挂载由点页签时的
        --   startLoad → loadRemote 消费缓存完成（瞬间完成，无下载延迟）。
        lazyTabs[tabKey] = item
        lazyOrder[#lazyOrder + 1] = item
        if onDemand then
            -- 挂 Tab 栏按钮点击（普通 Tab 的点击对象是 tab.UIElements.Main，
            -- TabItem 只有 Dropdown 类型 Tab 才用，挂它点不动）
            -- ★ UI 是分批创建的，页签按钮可能很晚才出现（原来只等 2 秒容易漏挂）：
            --   这里最多等 60 秒；等到就先挂；始终没等到就退化为「直接加载」，保证一定能用。
            task.spawn(function()
                local hooked = false
                for retry = 1, 600 do
                    local btn = tab.UIElements and tab.UIElements.Main
                    if btn and btn.MouseButton1Click then
                        local okHook = pcall(function()
                            btn.MouseButton1Click:Connect(function()
                                -- ★ 用户主动点开页签 → 立刻切运行期模式（同步建控件，点开即显示）
                                pcall(function()
                                    local _g = (getgenv and getgenv()) or _G
                                    if _g and _g.__SUIF_RUNTIME_MODE then _g.__SUIF_RUNTIME_MODE() end
                                end)
                                if item.state == "pending" or item.state == "failed" then
                                    startLoad(item)
                                end
                            end)
                        end)
                        if okHook then
                            hooked = true
                            break
                        end
                    end
                    task.wait(0.1)
                end
                if not hooked and item.state == "pending" then
                    -- 兜底：页签按钮一直没出现 → 直接加载，避免"点了没反应"
                    startLoad(item)
                end
            end)
        end
    end
end

-- ============ 主脚本主体：公告确认后才执行 ============
local function initMainScript()

-- ══════════════════════════════════════════════════════════════════════════════
-- 【富玩家条目】给各远程脚本的「玩家下拉框」用
-- 每个玩家一个条目：头像(rbxthumb) + 名字 + DisplayName · 血量状态
-- 用法：getgenv().__SUIF_RICH_PLAYERS({ all = true, excludeLocal = true })
--   返回 { {Title="玩家名", Desc="显示名 · HP 100", Image="rbxthumb://..."} , ... }
--   远程脚本拿到后直接当 Dropdown 的 Values 用；Boreal 原生支持
--   Values 里是 table 时按 Title/Desc/Image 渲染成带头像的卡片。
-- ══════════════════════════════════════════════════════════════════════════════
getgenv().__SUIF_RICH_PLAYERS = function(opts)
    opts = opts or {}
    local PSvc = game:GetService("Players")
    local me = PSvc.LocalPlayer
    local out = {}
    if opts.all then
        out[#out + 1] = {
            Title = "ALL",
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(me and me.UserId or 1) .. "&w=48&h=48",
        }
    end
    for _, p in ipairs(PSvc:GetPlayers()) do
        if not (opts.excludeLocal and p == me) then
            out[#out + 1] = {
                Title = p.Name,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(p.UserId) .. "&w=48&h=48",
            }
        end
    end
    return out
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 【玩家下拉框 · 只用放大面板】
-- 普通小菜单（贴按钮下方那个）在刷新后容易位置错乱、点不中；
-- 这里把 Dropdown 的 Open 直接改成 OpenBig：点一下直接弹出居中大面板
-- （自带搜索 / 多选 / 头像，视觉和原版放大按钮一致）。
-- ══════════════════════════════════════════════════════════════════════════════
getgenv().__SUIF_BIGONLY = function(dd)
    if not dd then return dd end
    local ok = pcall(function()
        if dd.__bigOnly then return end
        local dm = dd.DropdownMenu
        if not dm or type(dm.OpenBig) ~= "function" then return end
        dd.__bigOnly = true
        dm.Open = function(self, ...)
            -- 已经在放大面板里 → 再点一次关掉
            if self.__BigOpen then
                pcall(function()
                    if type(self.__CloseBig) == "function" then self.__CloseBig() end
                end)
                return
            end
            -- 小菜单若开着，先关掉再开大面板（Close 会同步把 Opened 置 false）
            if self.Opened then
                pcall(function() self:Close() end)
            end
            return self:OpenBig(...)
        end
        dd.Open = dm.Open          -- 别名同步，外部调 dd:Open() 也走大面板
    end)
    if not ok then
        warn("[suture] __SUIF_BIGONLY 应用失败（该下拉框可能不支持放大面板）")
    end
    return dd
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 【玩家下拉框 · 全局刷新总线】
-- 每个玩家下拉框注册进来（附带各自的重新填充函数）。
-- 任何一个脚本里的「刷新玩家列表」按钮，都会刷全部注册过的玩家下拉框。
--   __SUIF_REGISTER_PLAYER_DD(dd, refillFn, "甩飞")
--   __SUIF_REFRESH_ALL_PLAYERS()  → 返回成功刷新的个数
-- ══════════════════════════════════════════════════════════════════════════════
getgenv().__SUIF_PLAYER_DDS = getgenv().__SUIF_PLAYER_DDS or {}

getgenv().__SUIF_REGISTER_PLAYER_DD = function(dd, refill, owner)
    if not dd then return dd end
    local list = getgenv().__SUIF_PLAYER_DDS
    list[#list + 1] = { dd = dd, refill = refill, owner = tostring(owner or "") }
    return dd
end

getgenv().__SUIF_REFRESH_ALL_PLAYERS = function()
    local list = getgenv().__SUIF_PLAYER_DDS or {}
    local n = 0
    for i = #list, 1, -1 do
        local e = list[i]
        local dd = e.dd
        if dd and type(e.refill) == "function" then
            local ok = pcall(e.refill, dd)
            if ok then n = n + 1 else table.remove(list, i) end
        else
            table.remove(list, i)
        end
    end
    return n
end

-- 从富条目或裸字符串里取玩家名（远程脚本解析回调用）
getgenv().__SUIF_ITEM_NAME = function(v)
    if type(v) == "table" then
        return v.Title or v.Name or v.Value
    end
    return v
end

-- 全局通用防爆杀 (Adonis Bypass)
-- ★ 说明：这个键名是[公开约定]，游戏侧的反作弊理论上可以直接读它来判定在用第三方。
--   但 Adonis 的绕过依赖它，删了会失去这层保护，所以保留 —— 这是本脚本仅剩的
--   一处"约定名暴露"。不想留就把下面一行注释掉。
pcall(function() getgenv().bypass_adonis = true end)

local uiSet = { Theme = "Dark", Transparent = true, HideSearchBar = false, SideBarWidth = 180 }

local win = WindUI:CreateWindow({
    Title = "Suture Hub", Icon = "aperture", Author = "by suif", Folder = "SutureHub",
    Size = UDim2.fromOffset(620, 460), MinSize = Vector2.new(560, 350), MaxSize = Vector2.new(900, 600),
    ToggleKey = Enum.KeyCode.RightShift, Transparent = uiSet.Transparent, Theme = uiSet.Theme,
    Resizable = true, SideBarWidth = uiSet.SideBarWidth, HideSearchBar = uiSet.HideSearchBar,
    -- [suture] ScrollBarEnabled 已移除：v0.0.2 库强制关掉右侧滑条（防误触）
    User = { Enabled = true, Anonymous = false, Callback = function() print("当前用户:", lp.Name) end },
    OpenButton = { Scale = 0.85, OnlyIcon = false }
})

-- ══════════════════════════════════════════════════════════════════════════════
-- 【全局 UI 容器统一】WindUI 自己的 4 个 ScreenGui（主窗口 / 通知 / 下拉菜单 /
-- 工具提示）默认走 gethui()，但执行器不支持时会退回 PlayerGui —— 那正好是
-- 游戏 LocalScript 唯一能枚举到的容器。这里一律强制迁到 HIDDEN，并逐个保护。
--
-- 同时导出给所有远程脚本：
--   getgenv().__SUIF_HOST                 → 隐藏容器本身
--   getgenv().__SUIF_HIDDEN_GUI(name)     → 建一个挂在隐藏容器里的 ScreenGui
-- 远程脚本里任何 ScreenGui 都必须用这两样，不要再挂 PlayerGui。
-- ══════════════════════════════════════════════════════════════════════════════
do
    local g = (getgenv and getgenv()) or _G

    local function protectGui(o)
        pcall(function()
            if protect_gui then
                protect_gui(o)
            elseif syn and syn.protect_gui then
                syn.protect_gui(o)
            elseif type(getgenv().protect_gui) == "function" then
                getgenv().protect_gui(o)
            end
        end)
    end

    -- 把 WindUI 的四个 Gui 全部搬到隐藏容器
    pcall(function()
        if type(WindUI.SetParent) == "function" then
            WindUI:SetParent(HIDDEN)
        end
    end)
    -- 兜底：SetParent 不可用 / 有遗漏时，按名字直查
    pcall(function()
        local known = { "ScreenGui", "NotificationGui", "DropdownGui", "TooltipGui" }
        for _, k in ipairs(known) do
            local o = WindUI[k]
            if o and o.Parent ~= HIDDEN then
                pcall(function() o.Parent = HIDDEN end)
            end
        end
    end)
    -- 再兜底：把 HIDDEN 里名字像 WindUI 的 Gui 也保护一遍
    pcall(function()
        for _, c in ipairs(HIDDEN:GetChildren()) do
            if c:IsA("ScreenGui") and string.find(string.lower(c.Name), "windui", 1, true) then
                protectGui(c)
            end
        end
    end)

    if g then
        g.__SUIF_HOST = HIDDEN
        g.__SUIF_HIDDEN_GUI = function(name, displayOrder)
            local gui = Instance.new("ScreenGui")
            gui.Name = tostring(name or ("SutureUI_" .. __rnd(8)))
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.DisplayOrder = displayOrder or 999999
            gui.Parent = HIDDEN
            protectGui(gui)
            return gui
        end
        -- 把已有的 Gui 搬进隐藏容器（远程脚本里拿到的旧引用也能用）
        g.__SUIF_HIDE_GUI = function(gui)
            if gui and gui.Parent ~= HIDDEN then
                pcall(function() gui.Parent = HIDDEN end)
            end
            protectGui(gui)
            return gui
        end
    end

    print(("[suture] UI 容器已统一到 %s（%d 个 ScreenGui）"):format(
        tostring(HIDDEN:GetFullName()), #HIDDEN:GetChildren()))
end

-- ══════════════════════════════════════════════════════════════════
-- [suture] 控件分批创建：避免一次性创建上百控件触发 UIListLayout 重排卡死界面
-- 原理：hook Section:Tab -> tab 的控件方法，把创建调用排进队列，每帧只建 4 个
-- ══════════════════════════════════════════════════════════════════
do
    local UI_BATCH_QUEUE, UI_BATCH_BUSY = {}, false
    -- 队列排空标志：挂载循环用它等所有控件建完才宣布完成（避免窗口打开控件还在冒）
    local UI_QUEUE_EMPTY = true
    -- 布局冻结已消除 UIListLayout 全量重排（O(n²)→O(n)），
    -- 每帧批量自适应：根据实测帧耗时在 4~32 之间动态调整（重了就减半，轻了就加倍）
    local UI_BATCH_PER_FRAME = 12
    local UI_BATCH_MIN, UI_BATCH_MAX = 4, 32
    local UI_CTRL_METHODS = { "Button", "Toggle", "Slider", "Dropdown", "ColorPicker", "Keybind", "Textbox", "Paragraph", "Label", "Space" }
    -- ★ [suture] 批处理/冻结只用于「启动期一次性建 UI」。
    --   运行期（用户点页签加载远程脚本、下拉框刷新）必须同步建控件，否则：
    --     1) FreezeContainer 摘掉 UIListLayout → 后加的控件不参与布局 → 要切走再切回才显示
    --     2) Dropdown 在冻结的容器里刷新 → 位置算错（错位/点不中）
    --     3) 反复 Freeze/Thaw → UIListLayout 反复全量重排 → 周期性卡顿
    do
        local _g0 = (getgenv and getgenv()) or _G
        if _g0 and _g0.__SUIF_BATCH_ACTIVE == nil then
            _g0.__SUIF_BATCH_ACTIVE = true
        end
    end
    local function BatchActive()
        local _g = (getgenv and getgenv()) or _G
        return _g == nil or _g.__SUIF_BATCH_ACTIVE ~= false
    end

    -- ★ 只有「调用方不保留返回值」的控件可以排队。
    --   Toggle/Slider/Dropdown/ColorPicker/Keybind/Textbox 常被远程脚本存下来
    --   （local dd = tab:Dropdown(...); dd:Refresh(...)），排队会导致返回 self(Tab)
    --   → 后续 Refresh 打到 Tab 上 → 下拉框刷新错位 / 点不动 / 报错。
    local UI_QUEUEABLE = { Button = true, Paragraph = true, Label = true, Space = true }

    -- ★ 下拉框刷新后重算菜单位置
    --   WindUI 的 UpdatePosition() 只在 DropdownMenu:Open() 里调用一次。
    --   刷新会销毁并重建全部选项 → 列表高度变了但位置不会重算
    --   → 展开状态下刷新必然「整体错位、点不中」。
    --   这里在刷新完成后（等布局算完两帧）按 WindUI 同一套算法重算尺寸+位置。
    local function RepositionDropdownMenu(dd)
        pcall(function()
            local ui = dd and dd.UIElements
            if not ui then return end
            if dd.__BigOpen then return end                            -- 放大菜单有自己的布局，别碰
            local canvas = ui.MenuCanvas
            if not canvas or not canvas.Visible then return end
            local btn = ui.Dropdown
                or (dd.DropdownFrame and dd.DropdownFrame.UIElements and dd.DropdownFrame.UIElements.Main)
            if not btn then return end

            local cam = workspace.CurrentCamera
            local vpY = (cam and cam.ViewportSize.Y) or 1080

            local pad = 6
            pcall(function()
                local pb = ui.Menu and ui.Menu:FindFirstChildOfClass("UIPadding")
                if pb then
                    local v = math.max(pb.PaddingLeft.Offset, pb.PaddingTop.Offset)
                    if v > 0 then pad = v end
                end
            end)

            -- ① 尺寸：按真实内容高度重算（Refresh 时 AbsoluteContentSize 可能还是旧值）
            local list = ui.UIListLayout
            if list then
                local contentY = list.AbsoluteContentSize.Y
                if contentY > 0 then
                    local sb = ui.Menu and ui.Menu:FindFirstChild("SearchBar")
                    local extra = (sb and (sb.AbsoluteSize.Y + pad * 3)) or (pad * 2)
                    local need = contentY + extra
                    local maxH = vpY * 0.6
                    if need > maxH then need = maxH end
                    canvas.Size = UDim2.fromOffset(canvas.AbsoluteSize.X, need)
                end
            end

            -- ② 位置：与 WindUI UpdatePosition 同逻辑
            local btnBottom = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y
            local spaceBelow = vpY - btnBottom - pad - 54
            local menuH = canvas.AbsoluteSize.Y + pad
            local liftUp = -54
            if spaceBelow < menuH then
                liftUp = menuH - spaceBelow - 54
            end
            canvas.Position = UDim2.new(
                0,
                btn.AbsolutePosition.X + btn.AbsoluteSize.X,
                0,
                btnBottom - liftUp + (pad * 2)
            )
        end)
    end

    local function ScheduleReposition(dd)
        task.defer(function()
            task.wait()
            task.wait()
            RepositionDropdownMenu(dd)
        end)
    end

    -- ★ 下拉框刷新节流：WindUI 的 Dropdown:Refresh 会销毁并重建整个选项列表。
    --   玩家进出时多个脚本同时刷新 → 周期性卡顿。这里把 150ms 内的多次刷新合并成一次。
    local function ThrottleDropdown(dd)
        if type(dd) ~= "table" then return dd end
        if dd.__sutureThrottled then return dd end
        local origRefresh = dd.Refresh
        if type(origRefresh) ~= "function" then return dd end
        dd.__sutureThrottled = true
        local pending, scheduled = nil, false
        local firstCall = true
        dd.Refresh = function(self, ...)
            -- 首次（多用于构建初始选项）直接执行，不能延迟，否则下拉框一开始是空的
            if firstCall then
                firstCall = false
                local r = origRefresh(self, ...)
                ScheduleReposition(self)
                return r
            end
            pending = { ... }
            if scheduled then return self end
            scheduled = true
            task.delay(0.15, function()
                scheduled = false
                local a = pending
                pending = nil
                if a then
                    pcall(function()
                        origRefresh(self, table.unpack(a))
                    end)
                    ScheduleReposition(self)
                end
            end)
            return self
        end
        -- ★ SpecialType="Player" 的下拉框走 RefreshSpecialValues（Boreal 内部自动刷新：
        --   玩家一进/一退就重建整个选项列表 + 重算 CanvasSize）。同样合并到 150ms 一次，
        --   避免刚进出玩家那几帧连续重建导致的卡顿。
        local origSpecial = dd.RefreshSpecialValues
        if type(origSpecial) == "function" then
            local spPending, spScheduled = nil, false
            local spFirst = true
            dd.RefreshSpecialValues = function(self, ...)
                if spFirst then
                    spFirst = false
                    local r = origSpecial(self, ...)
                    ScheduleReposition(self)
                    return r
                end
                spPending = { ... }
                if spScheduled then return self end
                spScheduled = true
                task.delay(0.15, function()
                    spScheduled = false
                    local a = spPending
                    spPending = nil
                    if a then
                        pcall(function()
                            origSpecial(self, table.unpack(a))
                        end)
                        ScheduleReposition(self)
                    end
                end)
                return self
            end
        end
        return dd
    end
    -- ★ 源头优化：WindUI 每个控件加入容器都会触发 UIListLayout 全量重排（O(n²)）。
    --   创建期间冻结布局（摘掉 UIListLayout + 隐藏容器），全部创建完成一次性恢复（O(n)）。
    local UI_FROZEN = {}   -- container -> UIListLayout
    local function FreezeContainer(tabObj)
        local container = tabObj and tabObj.UIElements and tabObj.UIElements.Container
        if not container or UI_FROZEN[container] then return end
        local ll = container:FindFirstChildOfClass("UIListLayout")
        if ll then
            UI_FROZEN[container] = ll
            ll.Parent = nil
        end
        container.Visible = false
    end
    local function ThawContainers(onDone)
        local list = {}
        for c, ll in pairs(UI_FROZEN) do
            table.insert(list, { c = c, ll = ll })
        end
        UI_FROZEN = {}
        if #list == 0 then
            if onDone then onDone() end
            return
        end
        if #list <= 2 then
            for _, it in ipairs(list) do
                if it.ll and not it.ll.Parent then it.ll.Parent = it.c end
                it.c.Visible = true
            end
            if onDone then onDone() end
            return
        end
        -- 分批恢复：每帧最多 2 个容器，布局重排分散到多帧
        task.spawn(function()
            for i, it in ipairs(list) do
                if it.ll and not it.ll.Parent then it.ll.Parent = it.c end
                it.c.Visible = true
                if i % 2 == 0 then task.wait(0.02) end
            end
            if onDone then onDone() end
        end)
    end
    local function UIBatchFlush()
        if UI_BATCH_BUSY then return end
        UI_BATCH_BUSY = true
        task.spawn(function()
            UI_QUEUE_EMPTY = false
            local _g = (getgenv and getgenv()) or _G
            _g.__SUIF_UI_QUEUE_EMPTY = false
            while #UI_BATCH_QUEUE > 0 do
                local batchT0 = os.clock()
                local n = 0
                while #UI_BATCH_QUEUE > 0 and n < UI_BATCH_PER_FRAME do
                    local job = table.remove(UI_BATCH_QUEUE, 1)
                    pcall(job)
                    n = n + 1
                end
                -- 自适应：这批太慢就减少下批数量，很快则增加（保持每帧 4~8ms 稳定开销）
                local dt = os.clock() - batchT0
                if dt > 0.008 then
                    UI_BATCH_PER_FRAME = math.max(UI_BATCH_MIN, math.floor(UI_BATCH_PER_FRAME * 0.6))
                elseif dt < 0.0035 then
                    UI_BATCH_PER_FRAME = math.min(UI_BATCH_MAX, UI_BATCH_PER_FRAME + 2)
                end
                task.wait(0.02)
            end
            ThawContainers(function()
                UI_QUEUE_EMPTY = true
                _g.__SUIF_UI_QUEUE_EMPTY = true
            end)
            UI_BATCH_BUSY = false
        end)
    end
    local function BatchizeTab(tabObj)
        if type(tabObj) ~= "table" then return end
        -- Section 创建是同步的（返回值要立刻用），无法排队；
        -- 但至少要冻结容器，避免 Section 加入时触发 UIListLayout 全量重排
        local origSectionM = tabObj.Section
        if type(origSectionM) == "function" then
            tabObj.Section = function(self, cfg)
                if BatchActive() then pcall(FreezeContainer, self) end
                return origSectionM(self, cfg)
            end
        end
        for _, m in ipairs(UI_CTRL_METHODS) do
            local orig = tabObj[m]
            if type(orig) == "function" then
                local queueable = UI_QUEUEABLE[m] == true
                tabObj[m] = function(self, cfg)
                    -- 运行期 / 需要返回对象的控件：同步创建（布局正常、返回真对象）
                    if not queueable or not BatchActive() then
                        local r = orig(self, cfg)
                        if m == "Dropdown" then pcall(ThrottleDropdown, r) end
                        return r
                    end
                    FreezeContainer(self)
                    table.insert(UI_BATCH_QUEUE, function()
                        orig(self, cfg)
                    end)
                    UIBatchFlush()
                    return self
                end
            end
        end
    end
    local function BatchizeSection(secObj)
        if type(secObj) ~= "table" then return end
        local origTab = secObj.Tab
        if type(origTab) == "function" then
            secObj.Tab = function(self, cfg)
                local t = origTab(self, cfg)
                BatchizeTab(t)
                return t
            end
        end
        -- 关键：Section 的控件方法也必须排队+冻结（远程脚本几乎全用 Tab:Section + sec:Button 写法）
        for _, m in ipairs(UI_CTRL_METHODS) do
            local origM = secObj[m]
            if type(origM) == "function" then
                local queueable = UI_QUEUEABLE[m] == true
                secObj[m] = function(self, cfg)
                    if not queueable or not BatchActive() then
                        local r = origM(self, cfg)
                        if m == "Dropdown" then pcall(ThrottleDropdown, r) end
                        return r
                    end
                    FreezeContainer(self)
                    table.insert(UI_BATCH_QUEUE, function()
                        origM(self, cfg)
                    end)
                    UIBatchFlush()
                    return self
                end
            end
        end
    end
    -- ★ 切到「运行期模式」：关掉批处理/冻结，并把残留冻结的容器立刻解冻。
    --   之后所有控件同步创建，页签点开即显示、下拉框刷新不错位、不再反复重排。
    do
        local _g1 = (getgenv and getgenv()) or _G
        if _g1 then
            _g1.__SUIF_RUNTIME_MODE = function()
                if _g1.__SUIF_BATCH_ACTIVE == false then return end
                _g1.__SUIF_BATCH_ACTIVE = false
                -- 立刻把还冻结着的容器解冻（否则它们会一直 Visible=false）
                pcall(function()
                    local list = {}
                    for c, ll in pairs(UI_FROZEN) do
                        table.insert(list, { c = c, ll = ll })
                    end
                    UI_FROZEN = {}
                    for _, it in ipairs(list) do
                        if it.ll and not it.ll.Parent then it.ll.Parent = it.c end
                        it.c.Visible = true
                    end
                end)
                -- ★ 不在这里同步补队列：一帧内建上千个控件会直接卡死。
                --   UIBatchFlush 本来就在分批消费，让它继续跑即可。
                pcall(UIBatchFlush)
            end
        end
    end

    local origWinSection = win.Section
    if type(origWinSection) == "function" then
        win.Section = function(self, cfg)
            local s = origWinSection(self, cfg)
            BatchizeSection(s)
            return s
        end
    end
end

-- ============ 最小化方式：小圆圈（可选，替代胶囊栏）============
local minimizeMode = "capsule"  -- capsule=胶囊栏(默认) / ball=小圆圈
local sgBall = Instance.new("ScreenGui")
sgBall.Name = __HARD and __rnd(12) or "SutureBall"   -- ★ 开关关掉就用回原名
sgBall.ResetOnSpawn = false
sgBall.Enabled = false
sgBall.Parent = HIDDEN       -- ★ 原来挂 PlayerGui（游戏可枚举），改挂隐藏容器

-- 自定义样式（加载前可用 getgenv() 覆盖）：
--   getgenv().SutureBallImage = "rbxassetid://xxx"
--   getgenv().SutureBallSize  = 60          （大小，默认 48）
--   getgenv().SutureBallColor = Color3.fromRGB(255,0,0)  （颜色，默认紫）
-- ★ 内置圆圈图片（推荐）：图片上传到 Roblox 素材库后，把 ID 填到下面
--   例：local BALL_IMAGE_ID = "rbxassetid://1234567890"
--   留空 = 用默认的 ◉ 紫色圆圈
local BALL_IMAGE_ID = ""
local ballSize = getgenv().SutureBallSize or 48
local ballColor = getgenv().SutureBallColor or Color3.fromRGB(99, 102, 241)
local ballImg = getgenv().SutureBallImage or BALL_IMAGE_ID

local ball = Instance.new("TextButton", sgBall)
ball.Size = UDim2.fromOffset(ballSize, ballSize)
ball.Position = UDim2.new(0.9, -(ballSize + 12), 0.9, -(ballSize + 12))
ball.BackgroundColor3 = ballColor
ball.Text = "◉"
ball.TextColor3 = Color3.new(1, 1, 1)
ball.Font = Enum.Font.GothamBold
ball.TextSize = ballSize * 0.45
ball.AutoButtonColor = false
ball.Active = true
ball.Draggable = true
Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

-- 自定义图片（加载失败自动回退成 ◉）
if ballImg ~= "" then
    ball.Image = ballImg
    ball.Text = ""
    ball.ImageColor3 = Color3.new(1, 1, 1)
    ball.ImageError:Connect(function()
        ball.Image = ""
        ball.Text = "◉"
        ball.TextColor3 = Color3.new(1, 1, 1)
    end)
end

ball.MouseButton1Click:Connect(function()
    sgBall.Enabled = false
    win:Open()
end)

-- 窗口无论怎么打开，圆圈都隐藏
win:OnOpen(function()
    sgBall.Enabled = false
end)

-- 拦截右上角最小化按钮（点最小化 → 弹圆圈）
local minBtn
for _, v in pairs(win.TopBarButtons or {}) do
    if v.Name == "Minimize" then
        minBtn = v
        break
    end
end
if minBtn and minBtn.Object then
    minBtn.Object.MouseButton1Click:Connect(function()
        if minimizeMode == "ball" then
            sgBall.Enabled = true
        end
    end)
end

-- 切换最小化方式
local function setMinimizeMode(mode)
    minimizeMode = mode
    if mode == "ball" then
        pcall(function() win:EditOpenButton({ Enabled = false }) end)
    else
        win.IsOpenButtonEnabled = true
    end
end

win:Tag({ Title = "free", Icon = "gem", Color = Color3.fromHex("#30ff6a"), Radius = 0 })

-- 主窗口可见性广播：子脚本的独立浮层（雷达、Ping/FPS 等）跟随主 UI 一起显示/隐藏
getgenv().SutureMainWindow = win
getgenv().SutureMainUIVisible = true
do
    -- ★ 原来 0.3 秒轮询读一次 Visible；改成监听属性变化，完全不占帧。
    local mainUi = win.UIElements.Main
    local function sync()
        getgenv().SutureMainUIVisible = mainUi and mainUi.Visible or false
    end
    sync()
    pcall(function()
        mainUi:GetPropertyChangedSignal("Visible"):Connect(sync)
    end)
end

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

--// 【彩虹边框】窗口可见时 0.08s 一步；窗口隐藏时休眠（1s 一次空唤醒），不空转
task.spawn(function()
    while true do
        local main = win.UIElements.Main
        if main and main.Visible then
            UIGradient.Rotation = (UIGradient.Rotation + 12) % 360
            task.wait(0.15)          -- 原来 0.08（12.5次/秒），写 UIGradient 每次都触发 UI 重绘
        else
            task.wait(1)
        end
    end
end)


-- 固定公告弹窗已移除：公告统一走后台公告系统（公告确认 Popup）

-- 主页
local mainTab = win:Tab({ Title = "主页", Icon = "house", Locked = false })
mainTab:Select()

-- 功能类
local funcSec = win:Section({ Title = "功能", Icon = "folder", Opened = false })
local playerTab = funcSec:Tab({ Title = "玩家类", Icon = "user", Locked = false })
local fovTab = funcSec:Tab({ Title = "视野", Icon = "palette", Locked = false })
local FwTab = funcSec:Tab({ Title = "范围类", Icon = "user", Locked = false })
local SfTab = funcSec:Tab({ Title = "甩飞类", Icon = "user", Locked = false })
local amTab = funcSec:Tab({ Title = "自瞄类", Icon = "user", Locked = false })
local sayTab = funcSec:Tab({ Title = "发言类", Icon = "user", Locked = false })
local fyTab = funcSec:Tab({ Title = "翻译类", Icon = "languages", Locked = false })
local toolTab = funcSec:Tab({ Title = "工具类", Icon = "wrench", Locked = false })
local coordTab = funcSec:Tab({ Title = "传送类", Icon = "map-pin", Locked = false })
local serverTab = funcSec:Tab({ Title = "服务器类", Icon = "user", Locked = false })
-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】A 功能类 3 个黑白页签
-- ║ 需要时把下面整段的 --[[ ]] 去掉即可恢复（内容一字未改）
-- ╚══════════════════════════════════════════════════════════════╝

-- ── 黑白提取：功能类页签（NPC交互 / 控制物体 已按要求移除）──
local hbTriggerTab = funcSec:Tab({ Title = "触发类",   Icon = "zap",    Locked = false })

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】A 功能类 3 个黑白页签 结束
-- ╚══════════════════════════════════════════════════════════════╝

-- 视觉类
local shijueSec = win:Section({ Title = "视觉类", Icon = "palette", Locked = false })
local espTab = shijueSec:Tab({ Title = "透视类", Icon = "user", Locked = false })
local pingfpsTab = shijueSec:Tab({ Title = "ping/fps显示", Icon = "rss", Locked = false })
local radarTab = shijueSec:Tab({ Title = "雷达", Icon = "radar", Locked = false })
-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】B 视觉类 2 个黑白页签
-- ║ 需要时把下面整段的 --[[ ]] 去掉即可恢复（内容一字未改）
-- ╚══════════════════════════════════════════════════════════════╝

-- ── 黑白提取：视觉类新增两个页签 ──
local hbAnimTab     = shijueSec:Tab({ Title = "动作/动画", Icon = "music", Locked = false })
local hbDisguiseTab = shijueSec:Tab({ Title = "伪装玩家",  Icon = "user",  Locked = false })

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】B 视觉类 2 个黑白页签 结束
-- ╚══════════════════════════════════════════════════════════════╝

-- 脚本类
local scriptSec = win:Section({ Title = "脚本类", Icon = "folder", Opened = false })
local tyscriptTab = scriptSec:Tab({ Title = "通用", Icon = "shell", Opened = false })
local gnjbTab = scriptSec:Tab({ Title = "国内脚本", Icon = "shell", Opened = false })
local fescriptTab = scriptSec:Tab({ Title = "Fe脚本", Icon = "shell", Opened = false })
local doorsTab = scriptSec:Tab({ Title = "doors/门", Icon = "shell", Locked = false })
local byqTab = scriptSec:Tab({ Title = "被遗弃", Icon = "shell", Locked = false })
local stgTab = scriptSec:Tab({ Title = "死铁轨", Icon = "shell", Locked = false })
local slTab = scriptSec:Tab({ Title = "扫雷", Icon = "shell", Locked = false })
local fkgsTab = scriptSec:Tab({ Title = "方块故事", Icon = "shell", Locked = false })
local zrzhTab = scriptSec:Tab({ Title = "自然灾害", Icon = "shell", Locked = false })
local xesqTab = scriptSec:Tab({ Title = "将会发生些邪恶事情", Icon = "shell", Locked = false })
local wqkTab = scriptSec:Tab({ Title = "武器库", Icon = "shell", Locked = false })
local wxlgTab = scriptSec:Tab({ Title = "无限旅馆", Icon = "shell", Locked = false })
local dwyyTab = scriptSec:Tab({ Title = "动物医院", Icon = "shell", Locked = false })
local pghsTab = scriptSec:Tab({ Title = "排干湖水", Icon = "shell", Locked = false })
local lcTab = scriptSec:Tab({ Title = "莱克星顿与康科德/lc", Icon = "shell", Locked = false })
local zhyfxTab = scriptSec:Tab({ Title = "最后一封信", Icon = "shell", Locked = false })
local sxmsaTab = scriptSec:Tab({ Title = "数学谋杀案", Icon = "shell", Locked = false })
local zbjscqtTab = scriptSec:Tab({ Title = "在北极生存7天", Icon = "shell", Locked = false })
local scjsjjcTab = scriptSec:Tab({ Title = "生存僵尸竞技场", Icon = "shell", Locked = false })
local nljjcTab = scriptSec:Tab({ Title = "能力竞技场", Icon = "shell", Locked = false })
local bdh2Tab = scriptSec:Tab({ Title = "冰大亨2", Icon = "shell", Locked = false })
local zxdyTab = scriptSec:Tab({ Title = "重型钓鱼", Icon = "shell", Locked = false })
local sqjjcTab = scriptSec:Tab({ Title = "手枪竞技场", Icon = "shell", Locked = false })
local sgTab = scriptSec:Tab({ Title = "闪光", Icon = "shell", Locked = false })
local hcyghdTab = scriptSec:Tab({ Title = "合成一个核弹", Icon = "shell", Locked = false })
local cclsTab = scriptSec:Tab({ Title = "储存猎手：开放世界", Icon = "shell", Locked = false })
local smnmTab = scriptSec:Tab({ Title = "售卖柠檬", Icon = "shell", Locked = false })
local podpoTab = scriptSec:Tab({ Title = "po大po", Icon = "shell", Locked = false })
local slaTab = scriptSec:Tab({ Title = "圣里奥", Icon = "shell", Locked = false })
local hbhswTab = scriptSec:Tab({ Title = "烘焙或死亡", Icon = "shell", Locked = false })
local tpzTab = scriptSec:Tab({ Title = "逃跑者", Icon = "shell", Locked = false })
local qlsylyTab = scriptSec:Tab({ Title = "清理所有落叶", Icon = "shell", Locked = false })
local swsxxmsTab = scriptSec:Tab({ Title = "死亡顺序：西蒙说", Icon = "shell", Locked = false })
local llcqTab = scriptSec:Tab({ Title = "力量传奇", Icon = "shell", Locked = false })
local bcmjbTab = scriptSec:Tab({ Title = "保持门紧闭", Icon = "shell", Locked = false })
local bzyyzyzTab = scriptSec:Tab({ Title = "捕捉一亿只鸭子", Icon = "shell", Locked = false })
local hbbTab = scriptSec:Tab({ Title = "汉堡包", Icon = "shell", Locked = false })
local zslzd99yTab = scriptSec:Tab({ Title = "在森林中的99夜", Icon = "shell", Locked = false })
local msjdTab = scriptSec:Tab({ Title = "谋杀决斗", Icon = "shell", Locked = false })
local tykdTab = scriptSec:Tab({ Title = "偷一颗蛋", Icon = "shell", Locked = false })
local xzTab = scriptSec:Tab({ Title = "小猪", Icon = "shell", Locked = false })
local gTab = scriptSec:Tab({ Title = "狗", Icon = "shell", Locked = false })
local zqzcTab = scriptSec:Tab({ Title = "最强战场", Icon = "shell", Locked = false })

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
        __sandbox(fn)                          -- ★ 反馈模块静默

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
    Desc = "欢迎使用 Suture Hub\n作者：suif\n企鹅群462989034\n当前玩家：" .. lp.Name
})

mainTab:Paragraph({
    Title = "群聊",
    Desc = "462989034"
})

local countText = mainTab:Paragraph({
    Title = "全网执行次数",
    Desc = "正在获取..."
})

-- 历史公告查看：请求后台历史公告列表，一次 Popup 显示全部（内容区可滚动）
mainTab:Button({
    Title = "历史公告",
    Desc = "查看后台发布过的历史公告（一次显示全部）",
    Icon = "history",
    Callback = function()
        task.spawn(function()
            local http = game:GetService("HttpService")
            local api = "https://suture-hub-counter.sfbdsl666.workers.dev/announcement"
            local ok, res = pcall(function()
                return game:HttpGet(api .. "?history=1", true)
            end)
            if not ok then
                notify("历史公告", "获取失败：网络请求异常", "warning", 3)
                return
            end
            local okDecode, list = pcall(function()
                return http:JSONDecode(tostring(res))
            end)
            if not okDecode or type(list) ~= "table" then
                notify("历史公告", "暂无历史公告", "info", 3)
                return
            end
            if #list == 0 then
                notify("历史公告", "暂无历史公告", "info", 3)
                return
            end
            -- 全部历史拼成一个大文本，一次 Popup 显示（最新在前）
            local parts = {}
            for _, h in ipairs(list) do
                local head = (h.title or "公告")
                if h.version and h.version ~= "" then
                    head = head .. "  " .. h.version
                end
                if h.time and h.time ~= "" then
                    head = head .. "\n" .. h.time
                end
                table.insert(parts, head .. "\n" .. (h.content or ""))
            end
            WindUI:Popup({
                Title = "历史公告（共 " .. #list .. " 条）",
                Content = table.concat(parts, "\n\n──────────────────\n\n"),
                Icon = "history",
                Buttons = {
                    { Title = "关闭", Callback = function() end }
                }
            })
        end)
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- 脚本库（rscripts）· 主脚本建页签，控件与逻辑在远程脚本「脚本库.lua」里
-- ═══════════════════════════════════════════════════════════════════════════
do
    local rsSec = win:Section({ Title = "脚本库" })
    local rsTab = rsSec:Tab({ Title = "rscripts 脚本库", Icon = "library", Locked = false })

    getgenv().Tabs = getgenv().Tabs or {}
    getgenv().Tabs.RscriptsTab = rsTab
    getgenv().SutureRscriptsTab = rsTab

    -- 自动连点器（tu/hb 提取）依赖 ToolTab 页签，主脚本工具类页签就是它
    getgenv().Tabs.ToolTab = toolTab
    getgenv().SutureToolTab = toolTab

    -- 依赖注入（远程脚本要建 UI / 执行脚本）
    getgenv().__SUIF_WIN = win
    getgenv().__SUIF_RUN = run

    -- 远程脚本：点开页签时加载（控件全部由远程添加）
    lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/"
        .. game:GetService("HttpService"):UrlEncode("脚本库.lua"), "脚本库", rsTab, true)
end

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
            -- ★ 缓存击穿：八个参数在「同一玩家 + 同一游戏 + 同一执行器」时逐字相同，
            --   加了时间戳+随机数后每次 URL 都不同，任何一层的缓存都不可能命中。
            --   worker 的 /count 只读 player/game/... 这几个具名参数，多余参数直接忽略，
            --   所以不会影响计数结果。
            .. "&_t=" .. tostring(os.time()) .. tostring(math.random(100000, 999999))

        -- ★ 第二参数 true = 不走 HttpGet 缓存。
        --   原来这里是 game:HttpGet(url)（漏了 true），同 URL 第二次执行直接返回缓存，
        --   请求压根没发出去 —— 这就是后台「不计数」的根因。
        --   本文件其它远程请求（13 行 / 17 行 / 1158 行）都带了 true，只有这里漏了。
        local okH, resH = pcall(function()
            return game:HttpGet(url, true)
        end)
        if okH and type(resH) == "string" and resH ~= "" then
            return resH
        end

        -- 兜底：执行器自带 request。它能设 UA、也天然不受 HttpGet 缓存影响。
        for _, pair in ipairs({ { "syn", "request" }, { "http", "request" }, { "fluxus", "request" } }) do
            local holder = rawget(_G, pair[1])
            if type(holder) == "table" and type(holder[pair[2]]) == "function" then
                local okR, rR = pcall(holder[pair[2]], {
                    Url = url,
                    Method = "GET",
                    Headers = { ["User-Agent"] = "Roblox/WinInet" },
                })
                if okR and type(rR) == "table" and type(rR.Body) == "string" and rR.Body ~= "" then
                    return rR.Body
                end
            end
        end
        if type(request) == "function" then
            local okR2, rR2 = pcall(request, {
                Url = url, Method = "GET",
                Headers = { ["User-Agent"] = "Roblox/WinInet" },
            })
            if okR2 and type(rR2) == "table" and type(rR2.Body) == "string" and rR2.Body ~= "" then
                return rR2.Body
            end
        end

        -- 最后一搏：再试一次带 nocache 的 HttpGet
        task.wait(0.4)
        return game:HttpGet(url, true)
    end)

    if ok then
        res = tostring(res)
        if countText.SetDesc then
            countText:SetDesc("当前全网执行次数：" .. res)
        end
        notify("执行统计", "次数：" .. res, "activity", 2)
    else
        if countText.SetDesc then
            countText:SetDesc("获取失败：" .. tostring(res):sub(1, 60))
        end
        warn("[执行统计] 获取失败:", res)
        warn("[执行统计] 如果是网络问题可以忽略；反复失败说明 /count 走不通")
    end
end

-- ★ 延迟 3 秒再统计：刚启动时 UI 构建 + 远程预载会占满网络，
--   这时候发请求最容易超时。等界面稳定了再打，成功率高得多。
task.delay(3, updateCount)

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
                -- ★ fovConn 现在存的是协程令牌（table），不是 RBXScriptConnection。
                --   直接 :Disconnect() 会抛 "attempt to index"，把整个滑条回调打断。
                if type(fovConn) == "table" and type(fovConn.Disconnect) == "function" then
                    pcall(function() fovConn:Disconnect() end)
                end
                fovConn = nil      -- 置空后旧协程的 while 条件自然失效
            end
            -- ★ 原来用 RenderStepped 每帧回调：只要拖过一次滑条，这段连接就一直活着，
            --   60~240fps 下每帧都要进一次 Lua（哪怕什么都不用改）。改成独立协程
            --   每 0.15 秒检查一次 —— 被重置后最多 0.15 秒补回来，肉眼无差，开销归零。
            local token = {}
            fovConn = token
            task.spawn(function()
                while fovConn == token do
                    task.wait(0.15)
                    local cam = workspace.CurrentCamera
                    if cam and cam.FieldOfView ~= fov then
                        cam.FieldOfView = fov
                    end
                end
            end)
        end
    })
end)

-- ==================== Xray 透视（IY 同款 + 可调节）====================
-- 位置：视觉 →「透视类」标签页
-- IY 的做法：改 workspace 里所有部件的 LocalTransparencyModifier。
-- 这个属性是纯客户端的，不会同步到服务器 —— 也就是别人看不到你在透视。
-- 这里比 IY 多三个调节项：透明度滑块 / 是否排除角色 / 循环模式（且用 0.5 秒节流，
-- 不照 IY 那样每帧全场景扫一遍，手机上不卡）。
do
    local XRAY = { on = false, alpha = 0.5, skipChars = true, loop = true, saved = {}, conn = nil, next = 0 }

    local function xrayIsCharPart(v)
        local p = v.Parent
        if not p then return false end
        if p:FindFirstChildWhichIsA("Humanoid") then return true end
        local pp = p.Parent
        if pp and pp:FindFirstChildWhichIsA("Humanoid") then return true end
        return false
    end

    local function xrayApply()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local skip = XRAY.skipChars and xrayIsCharPart(v)
                if not skip then
                    if XRAY.saved[v] == nil then
                        XRAY.saved[v] = v.LocalTransparencyModifier
                    end
                    -- ★ 已经是目标值就不再写（属性写入有开销，全场景重写是卡顿主因）
                    if v.LocalTransparencyModifier ~= XRAY.alpha then
                        pcall(function() v.LocalTransparencyModifier = XRAY.alpha end)
                    end
                end
            end
        end
    end

    -- 单个部件即时处理（新生成的部件立刻透视，不用等全量扫描）
    local function xrayApplyOne(v)
        if not v:IsA("BasePart") then return end
        if XRAY.skipChars and xrayIsCharPart(v) then return end
        if XRAY.saved[v] == nil then
            XRAY.saved[v] = v.LocalTransparencyModifier
        end
        if v.LocalTransparencyModifier ~= XRAY.alpha then
            pcall(function() v.LocalTransparencyModifier = XRAY.alpha end)
        end
    end

    -- 把"被改过的角色部件"还原（切到排除角色时用）
    local function xrayRestoreChars()
        for part, old in pairs(XRAY.saved) do
            if part and part.Parent and xrayIsCharPart(part) then
                pcall(function() part.LocalTransparencyModifier = old end)
                XRAY.saved[part] = nil
            end
        end
    end

    local function xrayRestore()
        for part, old in pairs(XRAY.saved) do
            if part and part.Parent then
                pcall(function() part.LocalTransparencyModifier = old end)
            end
        end
        XRAY.saved = {}
    end

    local function xrayLoopStart()
        if XRAY.conn or not XRAY.loop then return end
        -- ★ 原来每 0.5 秒全量扫一遍 workspace（几万个实例全改透明度）→ 周期性卡顿。
        --   改成：新部件靠 DescendantAdded 即时处理，全量扫描只做 2 秒一次的兜底对账。
        -- ★ 原来挂 RunService.Heartbeat：即使 Xray 关着，每帧也要进一次 Lua 回调。
        --   改成协程：只在开启期间每 2 秒对账一次，关闭即退出，零每帧开销。
        local token = {}
        XRAY.conn = token
        task.spawn(function()
            while XRAY.on and XRAY.conn == token do
                xrayApply()
                task.wait(2.0)
            end
        end)
        if not XRAY.addConn then
            XRAY.addConn = workspace.DescendantAdded:Connect(function(v)
                if not XRAY.on then return end
                pcall(xrayApplyOne, v)
            end)
        end
    end

    local function xrayLoopStop()
        if XRAY.conn then
            if type(XRAY.conn) == "table" and type(XRAY.conn.Disconnect) == "function" then
                pcall(function() XRAY.conn:Disconnect() end)
            end
            XRAY.conn = nil        -- 协程令牌置空，循环自行退出
        end
        if XRAY.addConn then
            pcall(function() XRAY.addConn:Disconnect() end)
            XRAY.addConn = nil
        end
    end

    espTab:Toggle({
        Title = "Xray 透视",
        Expand = {
            BallTitle = "X光",
            Elements = function(h)
                h:Slider({
                    Title = "Xray 透明度",
                    Desc = "0.1 = 墙几乎看不见，1 = 完全透明；默认 0.5",
                    Step = 0.05,
                    Value = { Min = 0.1, Max = 1, Default = 0.5 },
                    Callback = function(v)
                        XRAY.alpha = tonumber(v) or 0.5
                        if XRAY.on then xrayApply() end
                    end
                })
            end
        },
        Desc = "把所有建筑变半透明（纯客户端，别人看不到）；关掉自动还原原样",
        Icon = "eye",
        Type = "Toggle",
        Value = false,
        Callback = function(s)
            XRAY.on = s
            if s then
                xrayApply()
                xrayLoopStart()
                notify("Xray", "已开启 · 透明度 " .. string.format("%.2f", XRAY.alpha), "check", 3)
            else
                xrayLoopStop()
                xrayRestore()
                notify("Xray", "已关闭并还原", "info", 3)
            end
        end
    })

    espTab:Toggle({
        Title = "Xray 排除角色",
        Expand = { BallTitle = "排除角色" },
        Desc = "开：只透视建筑，玩家/自己不变透明（默认）；关：连角色一起透明",
        Icon = "user",
        Type = "Toggle",
        Value = true,
        Callback = function(s)
            XRAY.skipChars = s
            if XRAY.on then
                if s then xrayRestoreChars() end
                xrayApply()
            end
        end
    })

    espTab:Toggle({
        Title = "Xray 循环模式",
        Expand = { BallTitle = "循环模式" },
        Desc = "开：持续给新出现的部件生效（每 0.5 秒补一次）；关：只处理当前场景一次",
        Icon = "refresh-cw",
        Type = "Toggle",
        Value = true,
        Callback = function(s)
            XRAY.loop = s
            if not XRAY.on then return end
            if s then xrayLoopStart() else xrayLoopStop() end
        end
    })
end

-- ==================== 透视皮脚本成员（群 35063401「皮脚本」）====================
-- 名单由 工具/爬群组成员.mjs 爬好推到 GitHub，进游戏时下载一次（253KB），之后只在本地比对。
-- 群成员有变动时，本机重跑一次爬取再上传，这里点「刷新皮脚本名单」即可。
do
    local PJS = {
        on = false,          -- 总开关
        self = false,        -- 连自己一起高亮
        tag = true,          -- 头顶名牌
        fillT = 0.45,        -- 高亮填充透明度
        color = Color3.fromRGB(255, 80, 80),
        colorName = "红",
        ids = nil,           -- { [userId] = true }
        count = 0,
        loadedAt = nil,
        hits = 0,
        busy = false,
        marks = {},          -- [player] = { hl = Highlight, gui = BillboardGui, lbl = TextLabel }
        -- 名单源：按顺序试，第一个能用的就用。
        -- raw.githubusercontent.com 在很多网络下直接连不通（实测 HTTP 000），
        -- 所以备多个镜像；几份内容完全一致（已核对 sha256）。
        -- 直连能用时它排第一（最新）；镜像作为回退。
        urls = {
            "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/groupdata/group_35063401_ids.txt",
            "https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/groupdata/group_35063401_ids.txt",
            "https://ghproxy.net/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/groupdata/group_35063401_ids.txt",
            "https://cdn.jsdelivr.net/gh/suif666/suif@main/groupdata/group_35063401_ids.txt",
            "https://gcore.jsdelivr.net/gh/suif666/suif@main/groupdata/group_35063401_ids.txt",
            "https://fastly.jsdelivr.net/gh/suif666/suif@main/groupdata/group_35063401_ids.txt",
        },
        source = nil,        -- 这次实际用上的源
    }
    local PJS_COLORS = {
        ["红"] = Color3.fromRGB(255, 80, 80),
        ["绿"] = Color3.fromRGB(90, 255, 130),
        ["蓝"] = Color3.fromRGB(90, 165, 255),
        ["黄"] = Color3.fromRGB(255, 220, 60),
        ["紫"] = Color3.fromRGB(195, 115, 255),
        ["青"] = Color3.fromRGB(70, 240, 240),
        ["白"] = Color3.fromRGB(255, 255, 255),
    }
    local PJSPlayers = game:GetService("Players")
    local pjsMe = PJSPlayers.LocalPlayer

    local function pjsSay(msg, kind, dur)
        notify("皮脚本透视", msg, kind or "check", dur or 4)
    end

    local function pjsClearOne(plr)
        local m = PJS.marks[plr]
        if not m then return end
        if m.hl then pcall(function() m.hl:Destroy() end) end
        if m.gui then pcall(function() m.gui:Destroy() end) end
        PJS.marks[plr] = nil
    end

    local function pjsClearAll()
        for plr in pairs(PJS.marks) do
            pjsClearOne(plr)
        end
    end

    -- 给一个人在角色上挂高亮 + 名牌；不是成员就清掉
    local function pjsMark(plr)
        if not PJS.on or not PJS.ids then
            pjsClearOne(plr)
            return
        end
        if plr == pjsMe and not PJS.self then
            pjsClearOne(plr)
            return
        end
        if not PJS.ids[plr.UserId] then
            pjsClearOne(plr)
            return
        end

        local char = plr.Character
        if not char or not char.Parent then
            pjsClearOne(plr)
            return
        end

        local m = PJS.marks[plr]
        -- 已经挂好且角色没换，就别每 3 秒重建一遍实例
        if m and m.hl and m.hl.Parent and m.hl.Adornee == char then
            return
        end
        pjsClearOne(plr)

        local hl = Instance.new("Highlight")
        hl.Name = "PJS_Highlight"
        hl.Adornee = char
        hl.FillColor = PJS.color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = PJS.fillT
        hl.OutlineTransparency = 0
        -- 关键：AlwaysOnTop = 墙后面也能看见，这才是「透视」
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char

        -- 先登记再建名牌：名牌那几行万一出错，高亮也不会变成清不掉的野实例
        m = { hl = hl }
        PJS.marks[plr] = m

        if PJS.tag then
            pcall(function()
                local gui = Instance.new("BillboardGui")
                m.gui = gui                     -- 同样先登记，出错也能被清掉
                gui.Name = "PJS_Tag"
                gui.Size = UDim2.new(0, 150, 0, 26)
                gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
                gui.AlwaysOnTop = true
                gui.MaxDistance = 400
                local lbl = Instance.new("TextLabel")
                m.lbl = lbl
                lbl.Size = UDim2.fromScale(1, 1)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.SourceSansBold
                lbl.TextSize = 16
                lbl.TextColor3 = PJS.color
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.TextStrokeTransparency = 0.25
                lbl.Text = "皮脚本 | " .. plr.Name
                lbl.Parent = gui
                gui.Adornee = char
                gui.Parent = char
            end)
        end
    end

    -- 扫一遍当前服务器的所有人
    local function pjsRescan()
        local hits = 0
        for _, plr in ipairs(PJSPlayers:GetPlayers()) do
            if PJS.ids and PJS.ids[plr.UserId] and (plr ~= pjsMe or PJS.self) then
                hits = hits + 1
                pjsMark(plr)
            else
                pjsClearOne(plr)
            end
        end
        PJS.hits = hits
        return hits
    end

    -- 下载名单（253KB，约 1 秒）
    -- 域名，用于提示里显示是哪个源生效了
    local function pjsHost(u)
        return (tostring(u):match("^https?://([^/]+)") or "?")
    end

    -- 依次试各个源，返回第一个能解析出足够多 ID 的
    local function pjsFetch()
        local report = {}
        for _, u in ipairs(PJS.urls) do
            local host = pjsHost(u)
            local ok, text = pcall(function() return game:HttpGet(u, true) end)
            if ok and type(text) == "string" and #text > 1000 then
                local set, n = {}, 0
                for id in text:gmatch("%d+") do
                    local v = tonumber(id)
                    if v then
                        set[v] = true
                        n = n + 1
                    end
                end
                -- 真名单有 2 万多个 ID。数量太少说明拿到的多半是错误页，
                -- 不能当成名单用（否则会静默地一个人都匹配不上）。
                if n >= 5000 then
                    return set, n, u
                end
                report[#report + 1] = host .. " 只有 " .. n .. " 个"
            else
                report[#report + 1] = host .. " 连不上"
            end
        end
        return nil, 0, nil, report
    end

    local function pjsLoad(silent)
        if PJS.busy then return false, "正在下载中" end
        PJS.busy = true
        local set, n, used, report = pjsFetch()
        PJS.busy = false

        if not set then
            local why = (report and #report > 0) and table.concat(report, "；") or "未知"
            if not silent then
                pjsSay("名单下载失败，试了 " .. #PJS.urls .. " 个源：" .. why:sub(1, 130), "x", 12)
            end
            return false, why
        end

        PJS.ids, PJS.count, PJS.loadedAt, PJS.source = set, n, os.time(), used
        if not silent then
            pjsSay("已加载 " .. n .. " 名成员（源：" .. pjsHost(used) .. "）", "check", 5)
        end
        return true
    end

    local function pjsStart()
        if PJS.ids then
            local hits = pjsRescan()
            pjsSay("开始透视 ｜ 本服命中 " .. hits .. " 人", "check", 4)
            return
        end
        task.spawn(function()
            if pjsLoad(true) then
                local hits = pjsRescan()
                pjsSay("名单 " .. PJS.count .. " 人 ｜ 本服命中 " .. hits .. " 人", "check", 5)
            else
                PJS.on = false
                pjsClearAll()
                pjsSay("名单没加载成功，已自动关掉。检查一下网络/加速器", "x", 8)
            end
        end)
    end

    local function pjsStop()
        pjsClearAll()
        pjsSay("已关闭并清除高亮", "info", 3)
    end

    -- 事件挂钩只建一次，重复执行脚本不会越挂越多
    if getgenv().PJSConns then
        for _, c in ipairs(getgenv().PJSConns) do
            pcall(function() c:Disconnect() end)
        end
    end
    getgenv().PJSConns = {}
    getgenv().PJSGen = (getgenv().PJSGen or 0) + 1
    local pjsGen = getgenv().PJSGen

    local function pjsHook(sig, fn)
        local c = sig:Connect(fn)
        getgenv().PJSConns[#getgenv().PJSConns + 1] = c
        return c
    end

    local function pjsWatch(plr)
        pjsHook(plr.CharacterAdded, function()
            task.wait(0.4)          -- 等角色装好再挂，不然 Adornee 会指到旧模型
            if PJS.on then pjsMark(plr) end
        end)
    end

    pjsHook(PJSPlayers.PlayerAdded, pjsWatch)
    pjsHook(PJSPlayers.PlayerRemoving, function(plr) pjsClearOne(plr) end)
    for _, plr in ipairs(PJSPlayers:GetPlayers()) do
        pjsWatch(plr)
    end

    -- 兜底轮询：角色重生、名单刚加载完、有人换号，3 秒对一次
    task.spawn(function()
        while true do
            task.wait(3)
            if getgenv().PJSGen ~= pjsGen then return end   -- 脚本被重跑了，老循环退出
            if PJS.on then pjsRescan() end
        end
    end)

    espTab:Toggle({
        Title = "透视皮脚本成员",
        Expand = {
            BallTitle = "皮脚本透视",
            Elements = function(h)
                h:Slider({
                    Title = "高亮透明度",
                    Desc = "越小越显眼；0.45 是默认",
                    Step = 0.05,
                    Value = { Min = 0, Max = 0.9, Default = 0.45 },
                    Callback = function(v)
                        PJS.fillT = tonumber(v) or 0.45
                        for _, m in pairs(PJS.marks) do
                            if m.hl then pcall(function() m.hl.FillTransparency = PJS.fillT end) end
                        end
                    end
                })
            end
        },
        Desc = "群「皮脚本」成员进服时，给角色加穿墙高亮（纯本地，别人看不到）；不是成员不会高亮",
        Icon = "users",
        Type = "Toggle",
        Value = false,
        Callback = function(s)
            PJS.on = s
            if s then pjsStart() else pjsStop() end
        end
    })

    espTab:Toggle({
        Title = "皮脚本透视 · 头顶名牌",
        Expand = { BallTitle = "头顶名牌" },
        Desc = "开：成员头顶显示「皮脚本 | 用户名」（默认）；关：只高亮不显示字",
        Icon = "tag",
        Type = "Toggle",
        Value = true,
        Callback = function(s)
            PJS.tag = s
            if PJS.on then pjsClearAll(); pjsRescan() end
        end
    })

    espTab:Toggle({
        Title = "皮脚本透视 · 连自己一起",
        Expand = { BallTitle = "连自己一起" },
        Desc = "开：你自己在这个群里的话也高亮（默认关，省得挡自己视野）",
        Icon = "user-check",
        Type = "Toggle",
        Value = false,
        Callback = function(s)
            PJS.self = s
            if PJS.on then pjsRescan() end
        end
    })

    espTab:Dropdown({
        Title = "皮脚本透视 · 高亮颜色",
        Desc = "换颜色不用重开，立即生效",
        Values = { "红", "绿", "蓝", "黄", "紫", "青", "白" },
        Value = "红",
        Callback = function(name)
            local c = PJS_COLORS[name]
            if not c then return end
            PJS.color, PJS.colorName = c, name
            for _, m in pairs(PJS.marks) do
                if m.hl then pcall(function() m.hl.FillColor = c end) end
                if m.lbl then pcall(function() m.lbl.TextColor3 = c end) end
            end
        end
    })

    espTab:Button({
        Title = "刷新皮脚本名单",
        Desc = "重新下载最新名单（群成员变动后，本机爬完上传了再点这个）",
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(function()
                if pjsLoad(true) then
                    local hits = PJS.on and pjsRescan() or 0
                    pjsSay("名单已刷新 ｜ " .. PJS.count .. " 人" .. (PJS.on and (" ｜ 本服命中 " .. hits .. " 人") or ""), "check", 5)
                else
                    pjsSay("刷新失败，网络或地址有问题（原来的名单还在用）", "x", 6)
                end
            end)
        end
    })

    espTab:Paragraph({
        Title = "皮脚本透视 说明",
        Desc = "名单：皮脚本（群 35063401），共 23421 人，来自 GitHub。\n" ..
               "GitHub 直连不通时会自动换镜像（jsDelivr / gh-proxy），无需手动设置。\n" ..
               "只在本地比对，全程不发任何数据出去；别人看不到你的高亮，也看不到你的名牌。\n" ..
               "群成员变动后：本机跑一次爬取 → 上传 → 回来点「刷新皮脚本名单」。"
    })
end

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
    Expand = { BallTitle = "即时互动" },
    Desc = "关闭恢复初始数值，但可能需要玩家死亡一次或互动按钮刷新一次",
    Icon = "zap",
    Type = "Toggle",
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
    Title = "运行诊断", Desc = "独立运行报错诊断面板（查看当前环境信息/手动诊断）", Icon = "activity",
    Callback = function()
        local _g = (getgenv and getgenv()) or _G
        if _g and _g.ShowDiagnose then
            _g.ShowDiagnose("手动运行诊断（查看当前环境信息）", true)
        else
            notify("运行诊断", "报错诊断未在运行（加载器/主脚本启动时会自动加载）", "warning", 4)
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
    Title = "iy汉化", Desc = "infiniteyield的汉化版 功能可能不会和原版同步", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/config/iy%E6%B1%89%E5%8C%96%E7%89%88", "iy汉化") end
})

toolTab:Button({
    Title = "iy原版[英文]", Desc = "顾名思义", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", "iy原版") end
})

-- ==================== 屏蔽购买弹窗（IY 同款做法）====================
-- IY 的 noprompts 只有一行：CoreGui.PurchasePromptApp.Enabled = false
-- Roblox 的购买/会员提示都挂在这个容器里，把它关掉弹窗就不再显示。
-- 这里额外给了「持续压制」开关：每 2 秒复查一次，防止游戏脚本或引擎又把它打开。
do
    local function bbRoot()
        local cg
        pcall(function() cg = (gethui and gethui()) or nil end)
        if not cg then pcall(function() cg = game:GetService("CoreGui") end) end
        if not cg then pcall(function() cg = lp:FindFirstChild("PlayerGui") end) end
        return cg
    end

    local function bbPromptApp()
        local cg = bbRoot()
        if not cg then return nil end
        local app = cg:FindFirstChild("PurchasePromptApp")
        if app then return app end
        -- 名字/层级偶尔不同，兜底扫一遍
        local ok, found = pcall(function()
            for _, d in ipairs(cg:GetChildren()) do
                if d:IsA("ScreenGui") and tostring(d.Name):lower():find("purchaseprompt", 1, true) then
                    return d
                end
            end
        end)
        if ok then return found end
        return nil
    end

    local function bbDumpCoreGui()
        local cg = bbRoot()
        if not cg then return "连 CoreGui 都拿不到（执行器权限问题）" end
        local ok, list = pcall(function()
            local t = {}
            for _, d in ipairs(cg:GetChildren()) do
                t[#t + 1] = d.Name .. "(" .. d.ClassName .. ")"
            end
            return table.concat(t, ", ")
        end)
        return ok and list or "读取 CoreGui 失败"
    end

    local function bbSet(blocked)
        local app = bbPromptApp()
        if not app then
            -- 把 CoreGui 里现有容器名打到控制台，方便排查是不是名字变了
            warn("[屏蔽购买弹窗] 没找到 PurchasePromptApp。当前 CoreGui 内容：" .. bbDumpCoreGui())
            return nil, "没找到 PurchasePromptApp（换成弹窗正显示时再点一次；控制台已列出 CoreGui 内容）"
        end
        local ok, err = pcall(function() app.Enabled = not blocked end)
        if not ok then return nil, "写入被拦：" .. tostring(err) end
        return true
    end

    local bbRunning = false
    local function bbLoopStart()
        if bbRunning then return end
        bbRunning = true
        task.spawn(function()
            while getgenv().SutureNoPrompts and getgenv().SutureNoPromptsLoop do
                task.wait(2)
                pcall(bbSet, true)
            end
            bbRunning = false
        end)
    end

    getgenv().SutureNoPromptsLoop = true

    toolTab:Toggle({
        Title = "屏蔽购买弹窗",
        Expand = { BallTitle = "屏蔽弹窗" },
        Desc = "IY 同款：关掉 CoreGui.PurchasePromptApp，购买/会员提示不再弹出",
        Icon = "shield-off",
        Type = "Toggle",
        Value = false,
        Callback = function(s)
            getgenv().SutureNoPrompts = s
            if not s then
                pcall(bbSet, false)
                notify("屏蔽购买弹窗", "已关闭（弹窗恢复显示）", "info", 3)
                return
            end
            local ok, err = bbSet(true)
            if ok then
                notify("屏蔽购买弹窗", "已开启" .. (getgenv().SutureNoPromptsLoop and " · 持续压制中" or ""), "check", 3)
            else
                -- 容器是懒加载的，现在可能还没生成：照样挂上压制，等它一出现就关掉
                notify("屏蔽购买弹窗", tostring(err) .. "（已挂上持续压制，弹窗一出现就会自动关）", "info", 6)
            end
            if getgenv().SutureNoPromptsLoop then bbLoopStart() end
        end
    })

    toolTab:Toggle({
        Title = "持续压制弹窗",
        Expand = { BallTitle = "压制弹窗" },
        Desc = "每 2 秒复查一次，防止游戏把 PurchasePromptApp 又打开（需要上面的开关先打开）",
        Icon = "refresh-cw",
        Type = "Toggle",
        Value = true,
        Callback = function(s)
            getgenv().SutureNoPromptsLoop = s
            if s and getgenv().SutureNoPrompts then
                bbLoopStart()
            end
        end
    })
end

-- 脚本区域
doorsTab:Button({
    Title = "[🔑]mspaint",
    Desc = "需卡密 超好用",
    Icon = "shell",
    Callback = function()
        local link = "https://www.mspaint.cc/key"
        if setclipboard then
            setclipboard(link)
        else
            warn("复制失败：当前环境不支持复制链接")
        end
        run("https://api.luarmor.net/files/v3/loaders/002c19202c9946e6047b0c6e0ad51f84.lua", "Doors msp")
    end
})

doorsTab:Button({
    Title = "Abysall[原版最新]", Desc = "不如msp 但胜在无卡密", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/Games/Doors/Main.luau", "Abysall脚本") end
})

doorsTab:Button({
    Title = "Abysall[汉化中文]", Desc = "和上面的Abysall是一样的 只不过是汉化版 功能可能不是最新", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/XxwanhexxX/doors-zh/refs/heads/main/Abysall.Hub", "Abysall脚本汉化") end
})

doorsTab:Button({
    Title = "[🔑]msdoors", Desc = "据说是msp的巴西粉丝做的 功能方面还算可以", Icon = "shell",
    Callback = function() run("https://rawscripts.net/raw/DOORS-MsDoors-58188", "msdoors脚本") end
})


byqTab:Button({
    Title = "fart[suif汉化]", Desc = "个人感觉很好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/fa%E6%B1%89%E5%8C%96", "被遗弃脚本") end
})

byqTab:Button({
    Title = "jnkie", Desc = "依旧国外大手子制作", Icon = "shell",
    Callback = function() run("https://api.jnkie.com/api/v1/luascripts/public/d36d2b96db2abcbb0f20b5c556b53cc5260ff74db0f8bfc3bea83eaa1da7947f/download", "被遗弃脚本02") 
end
})

stgTab:Button({
    Title = "[🔑]叶子", Desc = "好长时间都没有更新了...", Icon = "shell",
    Callback = function() run("https://getnative.cc/script/loader", "死铁轨叶子") end
})

stgTab:Button({
    Title = "ringta[suif汉化]", Desc = "应该是最好用", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/Ringta%E6%AD%BB%E9%93%81%E8%BD%A8.lua", "死铁轨ringta") end
})

stgTab:Button({
    Title = "Alkaline[suif汉化]", Desc = "对ringta拙劣的模仿 但还是有自己的功能的", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%AD%BB%E9%93%81%E8%BD%A8alkaline", "死铁轨Alkaline") end
})

stgTab:Button({
    Title = "死铁轨刷债券", Desc = "速度也是非常快好吧 蜗牛在修复司马😡😡😡", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/afkar-gg/sc/refs/heads/main/auto-bond", "死铁轨刷债券") end
})

slTab:Paragraph({
    Title = "注意",
    Desc = "此区域下的所有脚本均只适用于bLockerman's Minesweeper"
})


slTab:Button({
    Title = "扫雷01", Desc = "无gui 带问号的方块谨慎踩踏", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/Nattalz/rblx/refs/heads/main/blockerman_full.lua?='", "扫雷") end
})

 --扫雷远程
  getgenv().Tabs = getgenv().Tabs or {}
  getgenv().Tabs.MinesweeperTab = slTab
  getgenv().SutureMinesweeperTab = slTab
  lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%89%AB%E9%9B%B7%E7%A4%BA%E4%BE%8B.lua", "自写扫雷", slTab, true)

fkgsTab:Button({
    Title = "方块故事[suif汉化]", Desc = "支持方块故事战斗模拟器", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%96%B9%E5%9D%97%E6%95%85%E4%BA%8B%E6%B1%89%E5%8C%96.lua", "方块故事") end
})

xesqTab:Button({
    Title = "Ouroboros", Desc = "无汉化 功能总共没几个 全开就行", Icon = "shell",
    Callback = function() run("https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua", "将会发生些邪恶事情") end
})

--邪恶事情远程
getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.GameTab = xesqTab
getgenv().SutureGameTab = xesqTab
lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%82%AA%E6%81%B6%E4%BA%8B%E6%83%85%E7%A4%BA%E4%BE%8B.lua", "邪恶事情", xesqTab, true)

wqkTab:Button({
    Title = "武器库 静默瞄准", Desc = "没有esp 但是有静默瞄准", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/PasteWare.lua", "武器库")
    end
})

getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.wxlgTab = wxlgTab

lazyLoad("https://pastebin.com/raw/wV07BGnS", "无限旅馆", wxlgTab, true)

fescriptTab:Button({
    Title = "fe无敌少侠", Desc = "他人可见", Icon = "shell",
    Callback = function()
        run("ttps://raw.githubusercontent.com/giobolqv1/invincible-characters-animations-by-GioBolqv1-/refs/heads/main/universal.lua", "无敌少侠")
    end
})

fescriptTab:Button({
    Title = "fe祖国人[suif汉化]", Desc = "晚安,阿祖", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%A5%96%E5%9B%BD%E4%BA%BA%E6%B1%89%E5%8C%96.lua", "祖国人")
    end
})

fescriptTab:Button({
    Title = "fe火车头[suif汉化]", Desc = "情侣拆散器", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%81%AB%E8%BD%A6%E5%A4%B4%E6%B1%89%E5%8C%96.lua", "火车头")
    end
})

fescriptTab:Button({
    Title = "fe死亡[suif汉化]", Desc = "他人可见 优质的动作脚本", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/uhhhhhh.lua", "uhhhh")
    end
})

fescriptTab:Button({
    Title = "凋零风暴fe", Desc = "他人不可见 优质的fe脚本 建议在自然灾害执行", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Wither", "凋零风暴")
    end
})


tyscriptTab:Button({
    Title = "飞行V3", Desc = "顾名思义", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/FlyGuiV3.lua", "飞行V3")
    end
})

tyscriptTab:Button({
    Title = "npc控制[suif汉化]", Desc = "可以控制npc", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/npc%E6%B1%89%E5%8C%96.lua", "npc控制")
    end
})

dwyyTab:Button({
    Title = "[🔑]动物医院 自动类01[suif汉化]", Desc = "有些事件需要手动去完成 另外我用这个只活到15天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/HBtj3VFu", "动物医院")
    end
})

dwyyTab:Button({
    Title = "[🔑]动物医院 自动类02[suif汉化]", Desc = "有些事件需要手动去完成 没测试最高多少天", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/pFzZvHum", "动物医院02")
    end
})

dwyyTab:Button({
    Title = "[🔑]动物医院 自动类03[suif汉化]", Desc = "高度自定义 至少ui挺好看 不好用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2%20%E5%8A%9F%E8%83%BD%E4%B8%B0%E5%AF%8C.lua", "动物医院03")
    end
})

dwyyTab:Button({
    Title = "动物医院 自动类04[suif汉化]", Desc = "美丽ui 挺好用 就是容易治死人导致游戏结束 等作者优化吧 启动时会有雷霆大叫[调低音量]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%8A%A8%E7%89%A9%E5%8C%BB%E9%99%A2Foxname%5Bsuifhanghang%5D.lua", "动物医院04")
    end
})

pghsTab:Button({
    Title = "排干湖水 自动类01[suif汉化]", Desc = "离售卖机远了没法自动售卖  15分钟左右通关", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%8E%92%E7%A9%BA%E6%B9%96%E6%B0%B4.lua", "排干湖水01")
    end
})

lcTab:Button({
    Title = "lc脚本01", Desc = "", Icon = "shell",
    Callback = function()
        local link = "heiqiang-fa84d1b1-141d-46ad-991a-73b65016038c"
        if setclipboard then
            setclipboard(link)
            notify("复制成功", "卡密已复制到剪贴板！", "clipboard", 2)
        end
        run("https://api.jnkie.com/api/v1/luascripts/public/6bd5c94e9da68dce4a2bdf5abd1f6fb9a1379f41faaadbc0354b98d543066f58/download", "lc莱克星顿与康科德")
    end
})

zhyfxTab:Button({
    Title = "最后一封信 自动类01[suif汉化]", Desc = "有些词脚本想不出来 还是人脑牛逼👍🏻👍🏻👍🏻", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%86%99%E4%B8%80%E5%B0%81%E4%BF%A1%5B%E6%B1%89%E5%8C%96%5D.lua", "最后一封信01")
    end
})

sxmsaTab:Button({
    Title = "数学谋杀案 自动类01[suif汉化]", Desc = "这游戏有什么好开的。。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%95%B0%E5%AD%A6%E8%B0%8B%E6%9D%80%E6%A1%88%5B%E6%B1%89%E5%8C%96%5D.lua", "数学谋杀案01")
    end
})

--数学谋杀案远程
getgenv().Tabs.SXMSATab = sxmsaTab
getgenv().SutureSXMSATab = sxmsaTab
lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%95%B0%E5%AD%A6%E8%B0%8B%E6%9D%80%E6%A1%88%E7%A4%BA%E4%BE%8B.lua", "数学谋杀案自动答题", sxmsaTab, true)

zbjscqtTab:Button({
    Title = "[🔑]在北极生存7天 自动类01[suif汉化]", Desc = "加载时间可能比较长 不好用", Icon = "shell",
    Callback = function()
        local link = "https://wayoutscript.netlify.app/getkey"
        if setclipboard then
            setclipboard(link)
            notify("复制成功", "解卡链接已复制到剪贴板！", "clipboard", 2)
        end
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9C%A8%E5%8C%97%E6%9E%81%E7%94%9F%E5%AD%987%E5%A4%A9.lua", "在北极生存7天01")
    end
})


fescriptTab:Button({
    Title = "r15动作包[suif汉化]", Desc = "他人可见 注意只支持r15 r6用了会直接僵直", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/r15%E5%8A%A8%E4%BD%9C%E5%8C%85fe", "r15动作包")
    end
})

scjsjjcTab:Button({
    Title = "生存僵尸竞技场01[suif汉化]", Desc = "汉化不全 但无关紧要 主要的功能都是汉化过的 感觉还行", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/r15%E5%8A%A8%E4%BD%9C%E5%8C%85fe", "生存僵尸竞技场01")
    end
})

fescriptTab:Button({
    Title = "我的世界fe", Desc = "他人不可见 米米世界牛逼。", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ian49972/SCRIPTS/refs/heads/main/Steve", "我的世界fe")
    end
})

tyscriptTab:Button({
    Title = "定位传送", Desc = "借鉴[夜脚本]的闪电尖兵大招", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/Ctx5L33c", "定位传送")
    end
})

fescriptTab:Button({
    Title = "召唤吉吉fe", Desc = "他人不可见 嗯对没有蛋仔。", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/fqm5dDXN", "召唤吉吉fe")
    end
})


gnjbTab:Paragraph({
    Title = "注意",
    Desc = "我只收录我QQ群里看得见的脚本 不论好坏 如果你不想让你的脚本出现在这里 可以点击右上角反馈按钮进行反馈"
})

gnjbTab:Space()

gnjbTab:Button({
    Title = "叶脚本", Desc = "国内老资历 群[336554662]", Icon = "shell",
    Callback = function()
    run("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua", "夜脚本")
    end
})

gnjbTab:Button({
    Title = "夜脚本", Desc = "国内脚本 群[711757444]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/yejiaoben", "夜脚本")
    end
})

gnjbTab:Button({
    Title = "霖溺脚本", Desc = "国内脚本 群[744830231] 需加入roblox指定社区", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/ShenJiaoBen/ScriptLoader/refs/heads/main/Linni_FreeLoader.lua", "霖溺")
    end
})

gnjbTab:Button({
    Title = "XA脚本", Desc = "国内脚本 群[1057545155] 可能有时执行不了", Icon = "shell",
    Callback = function()
        run("https://raw.gitcode.com/Xingtaiduan/Scripts/raw/main/Loader.lua", "XA脚本")
    end
})

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 黑白脚本加载器按钮已彻底移除（2026-11 用户要求）：
-- ║ 它是独立 UI 脚本（Luraph 混淆），加载会创建第二个"黑白脚本"
-- ║ 界面并与主脚本并存；功能已由加载器预载的 tu/hb 提取脚本提供
-- ╚══════════════════════════════════════════════════════════════╝

gnjbTab:Button({
    Title = "kunkun脚本", Desc = "国内脚本 群[1009291930]", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/cfCbSrqr", "kunkun脚本")
    end
})

gnjbTab:Button({
    Title = "TrashHub脚本", Desc = "国内脚本 群[786284990]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/WasKKal/OnlyJumpToOther/main/loader.lua", "TrashHub脚本")
    end
})

gnjbTab:Button({
    Title = "Rb脚本", Desc = "国内脚本 群[1018099361]", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/Yungengxin/roblox/refs/heads/main/Rb-Hub", "Rb脚本")
    end
})

--范围远程
getgenv().Tabs.RangeTab = FwTab          -- 这里换成你实际创建的 Tab 变量名

lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua", "范围", FwTab, true)

--甩飞远程
getgenv().Tabs.FlingTPTab = SfTab
getgenv().WindUI = WindUI

lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E7%94%A9%E9%A3%9E.lua", "甩飞", SfTab)

--ping fps显示
getgenv().Tabs.PingFPSTab = pingfpsTab
getgenv().SuturePingFPSTab = pingfpsTab

lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E6%98%BE%E7%A4%BAfps%E5%92%8Cping.lua", "ping/fps显示", pingfpsTab)

--雷达
getgenv().Tabs.RadarTab = radarTab
getgenv().SutureRadarTab = radarTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua", "雷达", radarTab, true)

--玩家类远程
getgenv().Tabs.PlayerTab = playerTab
getgenv().SuturePlayerTab = playerTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", "玩家类", playerTab, true)

--自瞄类远程
getgenv().Tabs.AimbotTab = amTab
getgenv().SutureAimbotTab = amTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", "自瞄类", amTab, true)

--发言类远程
getgenv().Tabs.SayTab = sayTab
getgenv().SutureSayTab = sayTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua", "发言类", sayTab)

--ESP远程
getgenv().Tabs.ESPTab = espTab
getgenv().SutureESPTab = espTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua", "ESP", espTab, true)

--服务器类远程
getgenv().Tabs.ServerTab = serverTab
getgenv().SutureServerTab = serverTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua", "服务器类", serverTab, true)

--自然灾害远程
getgenv().Tabs.ZRZHTab = zrzhTab
getgenv().SutureZRZHTab = zrzhTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%84%B6%E7%81%BE%E5%AE%B3%E7%A4%BA%E4%BE%8B.lua", "自然灾害", zrzhTab, true)

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%84%B6%E7%81%BE%E5%AE%B3%E5%8A%9F%E8%83%BD.lua", "自然灾害功能", zrzhTab, true)

--po大po 功能远程
getgenv().Tabs.POTab = podpoTab
getgenv().SuturePOTab = podpoTab
lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/PO%E5%A4%A7PO%E7%A4%BA%E4%BE%8B.lua", "po大po功能", podpoTab, true)

--坐标传送远程（把 Tab 交给远程脚本，界面直接建在主窗口的「坐标传送」标签页里）
getgenv().Tabs = getgenv().Tabs or {}
getgenv().Tabs.CoordTPTab = coordTab
getgenv().SutureCoordTPTab = coordTab
getgenv().WindUI = WindUI

coordTab:Paragraph({
    Title = "坐标传送",
    Desc = "执行脚本时自动加载（远程脚本）\n"
        .. "功能：显示/复制/保存坐标、手动输入数值传送、过滤非当前游戏坐标",
})

lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%9D%90%E6%A0%87%E4%BC%A0%E9%80%81.lua", "坐标传送", coordTab)


tyscriptTab:Button({
    Title = "绕过群组检测", Desc = "可以绕过部分脚本的群组检测", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/4LzyCSnp", "绕过群组检测")
    end
})

nljjcTab:Button({
    Title = "[🔑]能力竞技场", Desc = "外网很多人在用 就搬过来了 不适合演戏 不适合手机游玩 功能挺多", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%83%BD%E5%8A%9B%E7%AB%9E%E6%8A%80%E5%9C%BA.lua", "能力竞技场")
    end
})

bdh2Tab:Paragraph({
    Title = "注意",
    Desc = "这个神人服务器长期霸占我主页 不找脚本有点过不去了"
})

bdh2Tab:Space()

bdh2Tab:Button({
    Title = "[🔑]冰大亨2[自动化]", Desc = "功能很多 自动化功能全开之后就可以睡觉了😛😛😛", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%86%B0%E5%A4%A7%E4%BA%A82.lua", "冰大亨2")
    end
})

zxdyTab:Button({
    Title = "[🔑]重型钓鱼", Desc = "感觉中规中矩 要是觉得不好用再右上角反馈功能进行反馈", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E9%87%8D%E5%9E%8B%E9%92%93%E9%B1%BC.lua", "重型钓鱼")
    end
})

sqjjcTab:Button({
    Title = "传送击杀", Desc = "大概就是搭配连点器发挥最大功效", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/eweucw5F", "手枪竞技场")
    end
})

--手枪竞技场 Ragebot 远程
getgenv().Tabs.SQJJC = sqjjcTab
getgenv().SutureSQJJC = sqjjcTab
lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%89%8B%E6%9E%AA%E7%AB%9E%E6%8A%80%E5%9C%BA%E7%A4%BA%E4%BE%8B.lua", "手枪竞技场Ragebot", sqjjcTab, true)

--闪光 Ragebot 远程（子弹追踪）
getgenv().Tabs.SGTab = sgTab
getgenv().SutureSGTab = sgTab
lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%97%AA%E5%85%89%E7%A4%BA%E4%BE%8B.lua", "闪光Ragebot", sgTab, true)


hcyghdTab:Paragraph({
    Title = "注意",
    Desc = "因游戏判定有问题 极大可能出现抓错核弹合成不了的情况 建议挂个连点器一直点松手"
})

hcyghdTab:Button({
    Title = "自动类", Desc = "挺好用的 就是飞行和移动类功能不要开 不然容易被ban", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/vNgFeLGR", "合成一个核弹")
    end
})

cclsTab:Button({
    Title = "储存猎手01", Desc = "功能很多 会开可以实现全自动 不会开就是一坨了", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E5%82%A8%E5%AD%98%E7%8C%8E%E4%BA%BA.lua", "储存猎手01")
    end
})

cclsTab:Button({
    Title = "储存猎手02", Desc = "不如用上面的", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%82%A8%E5%AD%98%E7%8C%8E%E6%89%8B02.lua", "储存猎手02")
    end
})

smnmTab:Paragraph({
    Title = "注意",
    Desc = "还有两个需要卡密的 我看功能差不多就没加 要是觉得这个不好用我再考虑加上"
})

smnmTab:Button({
    Title = "售卖柠檬[自动化]", Desc = "神人小游戏 依旧通货膨胀", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%94%AE%E5%8D%96%E6%9F%A0%E6%AA%AC.lua", "售卖柠檬")
    end
})

slaTab:Paragraph({
    Title = "注意",
    Desc = "此游戏反作弊较强 谨慎游玩"
})

slaTab:Button({
    Title = "[🔑]vxsans", Desc = "外网最火 功能很多", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%9C%A3%E5%A5%A5%E9%87%8Cvx.lua", "圣里奥vx")
    end
})

slaTab:Button({
    Title = "sanx", Desc = "外网第二火 功能比较少", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%9C%A3%E5%A5%A5%E9%87%8Csanx.lua", "圣里奥sanx")
    end
})

slaTab:Button({
    Title = "恐脚本", Desc = "国内圣里奥", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/恐脚本.NB", "恐脚本圣里奥")
    end
})

hbhswTab:Button({
    Title = "烘焙或死亡", Desc = "功能很多 近战光环好像不能用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E7%83%98%E7%84%99%E6%88%96%E6%AD%BB%E4%BA%A1.lua", "烘焙或死亡")
    end
})

tpzTab:Button({
    Title = "ouroboros", Desc = "应该最强 可以拿来演戏", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E9%80%83%E8%B7%91%E8%80%85our.lua", "逃跑者ouroboros")
    end
})

tpzTab:Button({
    Title = "逃跑者刷钱", Desc = "脚本介绍说一局4k左右 对加速器、设备要求较高 不然没法正常运行", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/MyQGSFSJ", "逃跑者刷钱4k")
    end
})

tpzTab:Button({
    Title = "逃跑者02", Desc = "功能很多 可以拿来演戏", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E9%80%83%E8%B7%91%E8%80%85r.lua", "逃跑者02")
    end
})

qlsylyTab:Button({
    Title = "清理所有落叶", Desc = "不适合演戏 建议单人游玩", Icon = "shell",
    Callback = function()
        run("https://pastefy.app/kz8yf2Zq/raw", "清理所有落叶")
    end
})

swsxxmsTab:Button({
    Title = "Ouroboros", Desc = "功能还算可以 主要也没什么好用的", Icon = "shell",
    Callback = function()
        run("https://pastefy.app/BTiTpOkj/raw", "Ouroboros西蒙说")
    end
})

swsxxmsTab:Button({
    Title = "[🔑]yuri西蒙说", Desc = "没上面那个好用 拿来充数的", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/JsbyK9Ff", "yuri西蒙说")
    end
})

llcqTab:Button({
    Title = "刘脚本", Desc = "b站找的 看上去挺好用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/LYHfailing/Muscle-Legends/refs/heads/main/%E5%88%98%E8%84%9A%E6%9C%AC%E5%8A%9B%E9%87%8F%E4%BC%A0%E5%A5%87-%E4%BD%9C%E8%80%852903144038%E8%84%9A%E6%9C%AC%E7%BE%A4810470906-%E5%85%8D%E8%B4%B9%E8%84%9A%E6%9C%AC.lua", "刘脚本")
    end
})

bcmjbTab:Button({
    Title = "保持门紧闭", Desc = "功能较多 油管较火", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E4%BF%9D%E6%8C%81%E9%97%A8%E7%B4%A7%E9%97%AD.lua", "保持门紧闭")
    end
})

bzyyzyzTab:Button({
    Title = "捕捉一亿只鸭子", Desc = "油管最火 非常稳定", Icon = "shell",
    Callback = function()
        run("https://pastebin.com/raw/nNZRLkh4", "捕捉一亿只鸭子")
    end
})

hbbTab:Paragraph({
    Title = "注意",
    Desc = "此游戏当前热度较低 脚本比较少"
})

hbbTab:Space()

hbbTab:Button({
    Title = "[未汉化]汉堡包", Desc = "ai制作 功能不保证有效", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/keeloby/-/refs/heads/main/alisonburgerz", "汉堡包")
    end
})

zslzd99yTab:Button({
    Title = "[未汉化]ringta", Desc = "非常好用 并还在积极更新", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/wehibuyfgyuwe/99nights.github.io/refs/heads/main/ringta.lua", "在森林中的99夜")
    end
})

zslzd99yTab:Button({
    Title = "[未汉化]Voidware", Desc = "外网较火 功能很多", Icon = "shell",
    Callback = function()
        run("https://files.vapevoidware.xyz/VapeVoidware/VW-Add/main/nightsintheforest.lua", "在森林中的99夜")
    end
})

zslzd99yTab:Button({
    Title = "[未汉化]FoxnameHub", Desc = "脚本网站比较火爆 不保证功能可用性", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/FoxnameHub.lua", "在森林中的99夜")
    end
})

msjdTab:Paragraph({
    Title = "注意",
    Desc = "youtube上的脚本都是几个月前的 不保证功能可用"
})

msjdTab:Space()

msjdTab:Button({
    Title = "[未汉化]eueuem", Desc = "找了个功能较多 发布时间近期的", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/eueuem/folk/refs/heads/main/Load.luau", "谋杀决斗")
    end
})

msjdTab:Button({
    Title = "[未汉化]murder-duels", Desc = "功能不多 反响较好", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/imshrak/murder-duels/refs/heads/main/main", "谋杀决斗")
    end
})

msjdTab:Button({
    Title = "[未汉化]MurderDuels", Desc = "两个月前的了 不保证功能能用", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/gumanba/Scripts/main/MurderDuels", "谋杀决斗")
    end
})

tykdTab:Button({
    Title = "Cyrus", Desc = "纯粹看着顺眼 功能什么的还可以", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/Cyrus%E5%81%B7%E8%9B%8B.lua", "偷一颗蛋")
    end
})

tykdTab:Button({
    Title = "伪装脚本", Desc = "由rblxscripts脚本网站制作 可以伪装你的蛋 宠物等", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%81%B7%E8%9B%8B%E4%BC%AA%E8%A3%85.lua", "偷一颗蛋")
    end
})

xzTab:Button({
    Title = "[🔑]小猪", Desc = "只找到这一个 功能很多 很齐全", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E5%B0%8F%E7%8C%AA.lua", "小猪")
    end
})

gTab:Button({
    Title = "[🔑]HollyScriptX",
    Desc = "总共没几个 把最好用的拿上来了",
    Icon = "shell",
    Callback = function()
        local link = "HSX-7562-3194-0835-4981-2470-1488-1029-6967"
        if setclipboard then
            setclipboard(link)
        else
            warn("复制失败：当前环境不支持复制")
        end
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E7%8B%97.lua", "狗")
    end
})

zqzcTab:Button({
    Title = "[🔑]自动农场", Desc = "字面意思 可以挂机刷人头", Icon = "shell",
    Callback = function()
        run("https://raw.githubusercontent.com/suif666/new/refs/heads/main/%E6%9C%80%E5%BC%BA%E6%88%98%E5%9C%BA%E8%87%AA%E5%8A%A8%E5%86%9C%E5%9C%BA.lua", "自动农场")
    end
})


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

settingsTab:Dropdown({
    Title = "最小化方式", Desc = "胶囊栏：最小化后按RightShift恢复（手机点胶囊栏）；小圆圈：最小化后弹出圆圈，点圆圈恢复",
    Values = { "胶囊栏(默认)", "小圆圈" },
    Value = "胶囊栏(默认)",
    Callback = function(v)
        setMinimizeMode(v == "小圆圈" and "ball" or "capsule")
    end
})

settingsTab:Button({
    Title = "退出脚本", Desc = "彻底关闭脚本 UI（销毁全部界面，不再显示）", Icon = "power",
    Callback = function()
        -- 先销毁自建 UI。它不在 WindUI 的树里，win:Destroy() 管不到它，
        -- 不显式销毁就会留一个关不掉的悬浮窗。
        if getgenv().SutureDestroyRscripts then
            pcall(getgenv().SutureDestroyRscripts)
        end
        pcall(function() win:Destroy() end)
        notify("Suture Hub", "已退出脚本，UI 已彻底关闭", "info", 3)
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

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】D 黑白提取远程脚本整段
-- ║ 需要时把下面整段的 --[[ ]] 去掉即可恢复（内容一字未改）
-- ╚══════════════════════════════════════════════════════════════╝

-- ============================================================
-- 黑白提取（远程脚本）——主脚本只建页签，功能全在远程脚本里
-- 远程文件托管在 suif666/tu 的 hb/ 目录
-- ============================================================

-- 重跑清场：远程脚本用 __HB_XXX_LOADED 防重复加载，不清掉的话
-- 第二次执行本脚本时远程脚本会直接 return，页签会是空的。
for _, k in ipairs({ "ANIMATION", "ACTIONPACK", "ANIMPACK", "DISGUISE",
                     "SLOWRUN", "CLICKER", "NPC", "TRIGGER", "OBJECT", "DISASTER" }) do
	getgenv()["__HB_" .. k .. "_LOADED"] = nil
end

-- 远程脚本要用的共享环境（它们拿不到这里的局部变量）
getgenv().HB_WindUI = WindUI
getgenv().HB_win    = win
getgenv().HB_notify = notify

local HB_REMOTE_BASE = "https://raw.githubusercontent.com/suif666/tu/main/hb/"

-- ══════════════════════════════════════════════════════════════════════════════
-- ★★★ 黑白远程脚本总开关 ★★★
-- 排查卡顿时先整体关掉这一批，看卡顿是否消失。
--   默认关闭（false 之外的写法都不会加载）；
--   想全部恢复：在游戏里执行  getgenv().SutureDisableHB = false  再重启脚本
-- ══════════════════════════════════════════════════════════════════════════════
do
    local g = (getgenv and getgenv()) or _G
    if g and g.SutureDisableHB == nil then
        -- 脚本已全部重写（自实现、无远程混淆、无轮询），默认启用。
        -- 若仍遇卡顿：游戏里执行 getgenv().SutureDisableHB = true 后重启脚本即可全停。
        g.SutureDisableHB = false
    end
end

local function hbLoad(url, desc, tab, onDemand)
    local g = (getgenv and getgenv()) or _G
    if g and g.SutureDisableHB then
        return   -- 总开关关闭中：这批判定全部不加载
    end
    lazyLoad(url, desc, tab, onDemand)
end

-- 视觉类 → 动作/动画（三个远程脚本塞进同一个页签）
getgenv().Tabs.HBAnimTab     = hbAnimTab
getgenv().SutureHBAnimTab    = hbAnimTab
hbLoad(HB_REMOTE_BASE .. "animation.lua",  "动作动画", hbAnimTab)
hbLoad(HB_REMOTE_BASE .. "actionpack.lua", "动作包",   hbAnimTab)
hbLoad(HB_REMOTE_BASE .. "animpack.lua",   "动画包",   hbAnimTab)

-- 视觉类 → 伪装玩家
getgenv().Tabs.HBDisguiseTab  = hbDisguiseTab
getgenv().SutureHBDisguiseTab = hbDisguiseTab
hbLoad(HB_REMOTE_BASE .. "disguise.lua", "伪装玩家", hbDisguiseTab)

-- 玩家类（复用 suif.lua 已有的 playerTab）
-- ★ 缓慢的快速跑：已按需求移除，不再加载（脚本文件仍留在仓库，需要时取消注释即可）
-- hbLoad(HB_REMOTE_BASE .. "slowrun.lua", "缓慢的快速跑", playerTab)

-- 工具类（复用 suif.lua 已有的 toolTab）
hbLoad(HB_REMOTE_BASE .. "clicker.lua", "自动连点器", toolTab)

-- 功能类 → 独立页签
getgenv().Tabs.HBTriggerTab  = hbTriggerTab
getgenv().SutureHBTriggerTab = hbTriggerTab
hbLoad(HB_REMOTE_BASE .. "trigger.lua", "触发类", hbTriggerTab)

-- 脚本类 → 自然灾害（复用 suif.lua 已有的 zrzhTab；该页签已挂两个远程脚本，
-- 这里跟着用 onDemand=true，点开页签时才加载）
hbLoad(HB_REMOTE_BASE .. "disaster.lua", "灾害预警", zrzhTab, true)

-- ╔══════════════════════════════════════════════════════════════╗
-- ║ 【已恢复】D 黑白提取远程脚本整段 结束
-- ╚══════════════════════════════════════════════════════════════╝

-- ============ [suture] 分帧挂载：统一消费 __SUIF_PENDING 队列 ============
-- 常驻循环：启动阶段的预载脚本 + 之后点页签/自动加载的脚本，全部由它消费
-- ★ 启动条件只看 __SUIF_PRELOAD：即使加载器这次没预载任何东西，循环也要跑起来，
--   否则后续 lazyLoad 塞进队列的任务永远没人执行（页签点开是空的）。
pcall(function()
    local g = (getgenv and getgenv()) or _G
    if g and g.__SUIF_PRELOAD then
        g.__SUIF_PENDING = g.__SUIF_PENDING or {}
        local pending = g.__SUIF_PENDING
        local totalCount = #pending
        g.__SUIF_MOUNT = { total = totalCount, done = 0 }
        -- ★ 帧预算制挂载：每帧最多花 10ms 执行挂载 fn，剩余留到下一帧。
        --   比"固定 1 个 + 0.05s 等待"更平滑：轻的 fn 一帧能挂多个，重的 fn 自动拆到多帧。
        local MOUNT_FRAME_BUDGET = 0.010
        local announced = false
        local function mountBatch()
            -- ★ 每轮重新取队列引用：lazyLoad 晚到（用户点页签）时会塞进新的队列
            local q = g.__SUIF_PENDING
            if not q or #q <= 0 then
                -- 空闲：宣布一次完成，然后低频轮询等新任务（不再退出，否则点页签没人消费）
                if not announced then
                    announced = true
                    g.__SUIF_MOUNT = nil
                    task.spawn(function()
                        local _g = (getgenv and getgenv()) or _G
                        while not _g.__SUIF_UI_QUEUE_EMPTY do
                            task.wait(0.03)
                        end
                        -- ★ 等「全量下载循环」也结束，否则功能类脚本还没下载完就淡出加载器
                        local guard = 0
                        while not _g.__SUIF_AUTOLOAD_DONE and guard < 1200 do
                            guard = guard + 1
                            task.wait(0.1)
                        end
                        -- 启动期 UI 已全部建完 → 切运行期模式（之后的动态挂载/刷新都同步）
                        pcall(function()
                            if _g and _g.__SUIF_RUNTIME_MODE then _g.__SUIF_RUNTIME_MODE() end
                        end)
                        if not _g.__SUIF_READY_FIRED then
                            _g.__SUIF_READY_FIRED = true
                            if g.__SUIF_READY then
                                g.__SUIF_READY()
                            end
                        end
                    end)
                end
                task.wait(0.1)
                mountBatch()
                return
            end
            announced = false
            g.__SUIF_MOUNT = g.__SUIF_MOUNT or { total = 0, done = 0 }
            local t0 = os.clock()
            while true do
                local cur = g.__SUIF_PENDING
                if not cur or #cur <= 0 then break end
                if (os.clock() - t0) >= MOUNT_FRAME_BUDGET then break end
                local fn = table.remove(cur, 1)
                if fn then
                    pcall(fn)
                end
                g.__SUIF_MOUNT.done = (g.__SUIF_MOUNT.done or 0) + 1
            end
            task.spawn(function()
                task.wait()
                mountBatch()
            end)
        end
        mountBatch()
    end
end)

-- ============ 全量自动加载全部远程脚本 ============
-- 位置放在所有 lazyLoad 登记点之后，确保 lazyOrder 已全部登记
-- 每个脚本间隔 0.5 秒错开加载（柔和化，避免 10 个请求同时炸出卡顿）
-- 每个脚本加载成功/失败都会通知
local AUTO_LOAD_DELAY = 0.5
task.spawn(function()
    task.wait(0.3)
    for _, item in ipairs(lazyOrder) do
        -- onDemand 跳过：等用户点对应 Tab 时才加载。
        -- ★ 范围/雷达/玩家类/自瞄类/ESP/服务器类 这 6 个重脚本现在都是 onDemand：
        --   它们都带常驻循环（每帧 Heartbeat / 每帧遍历 workspace / 高频属性写），
        --   开局全挂上去就是十几个循环同时跑 —— 那才是"莫名其妙卡一下"的来源。
        --   加载器那边已经把它们的源码预下载并编译好（__PRELOADED_FNS），
        --   点页签瞬间执行，没有下载等待。
        if not item.onDemand and (item.state == "pending" or item.state == "failed") then
            startLoad(item)
        end
        task.wait(AUTO_LOAD_DELAY)
    end
    -- [suture] 挂载统一交给常驻 mountBatch 循环消费 __SUIF_PENDING。
    --   这里只打一个"下载全部结束"的标记，让它知道可以宣布 READY 了
    --   （否则功能类还没下载完就淡出加载器，看起来像挂载失败）。
    pcall(function()
        local g = (getgenv and getgenv()) or _G
        if g then g.__SUIF_AUTOLOAD_DONE = true end
    end)
end)

-- [suture] 批量挂载已移至上方「全量自动加载」循环末尾（下载完成后执行，时机正确）
-- [suture] READY 通知：预编译模式下由全量加载末尾统一触发；非预编译模式（独立执行）立即触发
pcall(function()
    local g = (getgenv and getgenv()) or _G
    if g and g.__SUIF_READY and not g.__SUIF_PRELOAD and not g.__SUIF_READY_FIRED then
        g.__SUIF_READY_FIRED = true
        g.__SUIF_READY()
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- 【配置保存 / 读取】—— 放在脚本最末尾执行，并且整块 pcall 包裹：
--   万一某个控件调用不兼容，只打一行 warn，绝不会把主界面/页签一起拖下来。
--   · 遍历 win.AllElements 里所有带状态的控件（开关 / 拉条 / 下拉框 / 输入框 /
--     按键绑定 / 取色器），一次性存档
--   · 文件落在执行器工作区：suture_configs/<自定义名字>.json
--   · 不用 WindUI 自带 ConfigManager —— 那套要求控件创建时带 Flag，
--     本脚本所有控件都没有 Flag，用它存出来是空文件。
-- ══════════════════════════════════════════════════════════════════════════════
task.defer(function()
    local okBlock, errBlock = pcall(function()
        -- ★ 关键：必须在建控件之前切到"运行期同步模式"。
        --   启动期的 UI 是分批排队的，Section(...) 在这种模式下可能返回 nil，
        --   接着 cfgSec:Textbox 就是对 nil 取索引 → 3243 行那个报错。
        local _g0 = (getgenv and getgenv()) or _G
        if _g0 and type(_g0.__SUIF_RUNTIME_MODE) == "function" then
            pcall(_g0.__SUIF_RUNTIME_MODE)
        end

        local CFG_DIR = "suture_configs"
        local hasFS = (type(writefile) == "function") and (type(readfile) == "function")

        local CFG_READ = {
            Toggle = function(el) return el.Value end,
            Slider = function(el) return el.Value and el.Value.Default or nil end,
            Dropdown = function(el) return el.Value end,
            Input = function(el) return el.Value end,
            Keybind = function(el) return el.Value end,
            Colorpicker = function(el)
                local c = el.Default
                if typeof and typeof(c) == "Color3" then return c:ToHex() end
                return nil
            end,
        }
        local CFG_WRITE = {
            Toggle = function(el, v)
                if type(el.Set) == "function" then pcall(function() el:Set(v and true or false) end) end
            end,
            Slider = function(el, v)
                local n = tonumber(v)
                if n and type(el.Set) == "function" then pcall(function() el:Set(n) end) end
            end,
            Dropdown = function(el, v)
                if type(el.Select) == "function" then pcall(function() el:Select(v) end) end
            end,
            Input = function(el, v)
                if type(el.Set) == "function" then pcall(function() el:Set(v) end) end
            end,
            Keybind = function(el, v)
                if type(el.Set) == "function" then pcall(function() el:Set(v) end) end
            end,
            Colorpicker = function(el, v)
                if type(v) == "string" and type(el.Update) == "function" then
                    pcall(function() el:Update(Color3.fromHex(v)) end)
                end
            end,
        }

        local function cfgCollect()
            local list, seen = {}, {}
            local all = win and win.AllElements
            if type(all) ~= "table" then return list end
            for _, el in ipairs(all) do
                local t = el.__type
                if t and CFG_READ[t] then
                    local title = tostring(el.Title or "")
                    local key
                    if type(el.Flag) == "string" and el.Flag ~= "" then
                        key = t .. "|" .. el.Flag
                    elseif title ~= "" then
                        key = t .. "|" .. title
                    else
                        key = t .. "|#" .. tostring(el.GlobalIndex or #list)
                    end
                    seen[key] = (seen[key] or 0) + 1
                    if seen[key] > 1 then key = key .. "|" .. tostring(seen[key]) end
                    table.insert(list, { key = key, el = el, type = t })
                end
            end
            return list
        end

        local function cfgSanitize(name)
            name = tostring(name or "")
            name = name:gsub("[/\\:*?\"<>|]", "_")
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            return name
        end

        local function cfgList()
            local out = {}
            if not hasFS then return out end
            pcall(function()
                if type(listfiles) == "function" then
                    for _, p in ipairs(listfiles(CFG_DIR)) do
                        local n = tostring(p):match("([^/\\]+)%.json$")
                        if n then table.insert(out, n) end
                    end
                end
            end)
            table.sort(out)
            return out
        end

        local function cfgSave(name, isOverwrite)
            if not hasFS then
                notify("保存配置", "这个执行器不支持写文件（writefile）", "alert-triangle", 6)
                return false
            end
            name = cfgSanitize(name)
            if name == "" then
                notify("保存配置", "先在上面填一个配置名字", "alert-triangle", 6)
                return false
            end
            pcall(function()
                if type(isfolder) == "function" and type(makefolder) == "function" then
                    if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
                end
            end)

            local items = cfgCollect()
            local data, saved = {}, 0
            for _, it in ipairs(items) do
                local ok, v = pcall(CFG_READ[it.type], it.el)
                if ok and v ~= nil then
                    data[it.key] = { t = it.type, v = v }
                    saved = saved + 1
                end
            end

            local okEnc, js = pcall(function()
                return game:GetService("HttpService"):JSONEncode(data)
            end)
            if not okEnc then
                notify("保存配置", "编码失败", "alert-triangle", 6)
                return false
            end

            local path = CFG_DIR .. "/" .. name .. ".json"
            local okW = pcall(function() writefile(path, js) end)
            if not okW then
                notify("保存配置", "写入失败", "alert-triangle", 6)
                return false
            end
            if isOverwrite then
                notify("覆盖配置", ("%s.json 已覆盖为 %d 项"):format(name, saved), "check", 4)
            else
                notify("保存配置", ("%s.json 已保存 %d 项"):format(name, saved), "check", 4)
            end
            print(("[配置] 已%s → %s（%d 项）"):format(isOverwrite and "覆盖" or "保存", path, saved))
            return true
        end

        local function cfgLoad(name)
            if not hasFS then
                notify("读取配置", "这个执行器不支持读文件", "alert-triangle", 6)
                return false
            end
            name = cfgSanitize(name)
            if name == "" then
                notify("读取配置", "先选一个配置", "alert-triangle", 6)
                return false
            end
            local path = CFG_DIR .. "/" .. name .. ".json"
            if type(isfile) == "function" and not isfile(path) then
                notify("读取配置", "找不到 " .. path, "alert-triangle", 6)
                return false
            end
            local okR, raw = pcall(function() return readfile(path) end)
            if not okR or type(raw) ~= "string" then
                notify("读取配置", "读取失败", "alert-triangle", 6)
                return false
            end
            local okD, data = pcall(function()
                return game:GetService("HttpService"):JSONDecode(raw)
            end)
            if not okD or type(data) ~= "table" then
                notify("读取配置", "文件解析失败", "alert-triangle", 6)
                return false
            end

            local byKey = {}
            for _, it in ipairs(cfgCollect()) do byKey[it.key] = it end

            -- ★ 静音：套用过程中每个控件 Callback 里的通知一律丢弃，
            --   否则一次恢复能弹几十条。同时屏蔽 WindUI:Notify 直连的调用。
            local _g = (getgenv and getgenv()) or _G
            local prevQuiet = _g and _g.__SUIF_QUIET
            local prevWUNotify = WindUI and WindUI.Notify
            if _g then _g.__SUIF_QUIET = true end
            if WindUI then
                WindUI.Notify = function() return nil end
            end

            local applied, missing = 0, 0
            pcall(function()
                for key, rec in pairs(data) do
                    local it = byKey[key]
                    local t = (type(rec) == "table") and rec.t or nil
                    if it and t and CFG_WRITE[t] then
                        if pcall(CFG_WRITE[t], it.el, rec.v) then
                            applied = applied + 1
                        else
                            missing = missing + 1
                        end
                    else
                        missing = missing + 1
                    end
                end
            end)

            if _g then _g.__SUIF_QUIET = prevQuiet end
            if WindUI and type(prevWUNotify) == "function" then
                WindUI.Notify = prevWUNotify
            end

            -- 只留这一条
            notify("读取配置", ("成功恢复 %d 项"):format(applied), "check", 4)
            print(("[配置] 已读取 %s：%d 项，缺失 %d"):format(path, applied, missing))
            return true
        end

        local function cfgDelete(name)
            if not hasFS then return false end
            name = cfgSanitize(name)
            if name == "" then return false end
            local path = CFG_DIR .. "/" .. name .. ".json"
            local ok = pcall(function()
                if type(isfile) == "function" and not isfile(path) then return end
                if type(delfile) == "function" then delfile(path) end
            end)
            if ok then notify("配置管理", "已删除 " .. name .. ".json", "trash-2", 4) end
            return ok
        end

        ------------------------------------------------------------------
        -- UI —— 直接挂在「设置」页签上（不建 Section：
        -- Section() 在报错现场返回过 nil，tab 上的控件方法是稳定可用的）
        ------------------------------------------------------------------
        local cfgSec = settingsTab or win     -- 兜底：settingsTab 万一是 nil 就挂到 window 上
        -- ★ 不在这里 error：类型判断一旦误判就会把整个配置区连标题都不留。
        --   改成逐项 pcall + 诊断输出，能建几个算几个，失败也只在控制台留痕。
        do
            local tObj = type(cfgSec)
            local tTb, tBtn, tSec, tDd
            pcall(function() tTb = type(cfgSec.Textbox) end)
            local tIn
            pcall(function() tIn = type(cfgSec.Input) end)
            print("[配置] 诊断 Input 方法类型: " .. tostring(tIn))
            pcall(function() tBtn = type(cfgSec.Button) end)
            pcall(function() tSec = type(cfgSec.Section) end)
            pcall(function() tDd = type(cfgSec.Dropdown) end)
            print(("[配置] 诊断 settingsTab: 对象=%s Textbox=%s Button=%s Section=%s Dropdown=%s")
                :format(tObj, tostring(tTb), tostring(tBtn), tostring(tSec), tostring(tDd)))
            if tObj == "nil" then
                error("settingsTab 为 nil，配置区无法创建")
            end
        end
        local cfgName = "default"
        local cfgPick = nil
        local cfgDropdown = nil

        local function cfgValuesSafe()
            local list = cfgList()
            if #list == 0 then return { "（还没有存档）" } end
            return list
        end

        local made, failed = 0, {}

        local function build(name, fn)
            local ok, err = pcall(fn)
            if ok then
                made = made + 1
            else
                table.insert(failed, name .. ":" .. tostring(err))
            end
            return ok
        end

        build("Label", function()
            cfgSec:Label({
                Title = "配置保存 / 读取",
                Desc = "把所有开关 / 拉条 / 下拉框 / 输入框 / 按键 / 颜色一次性存档",
            })
        end)

        -- ★ WindUI-Boreal 里文本框叫 :Input（控件 __type 也是 Input），
        --   没有 :Textbox() 这个方法。两个都试，哪个能用用哪个。
        build("Input", function()
            local cfgBox = {
                Title = "配置名称",
                Desc = "自定义名字；存到执行器工作区 " .. CFG_DIR .. "/<名字>.json",
                Value = "default",
                Placeholder = "例如 我的配置 / pvp / 挂机",
                Callback = function(v) cfgName = tostring(v or "") end,
            }
            local okIn = pcall(function() cfgSec:Input(cfgBox) end)
            if not okIn then
                cfgSec:Textbox(cfgBox)      -- 万一某个版本叫 Textbox
            end
        end)

        build("保存按钮", function()
            cfgSec:Button({
                Title = "保存当前配置",
                Desc = "把当前所有开关 / 拉条 / 下拉框 / 输入框 / 按键 / 颜色都存下来",
                Callback = function()
                    cfgSave(cfgName)
                    if cfgDropdown and type(cfgDropdown.Refresh) == "function" then
                        pcall(function() cfgDropdown:Refresh(cfgValuesSafe()) end)
                    end
                end,
            })
        end)

        build("覆盖配置按钮", function()
            cfgSec:Button({
                Title = "覆盖配置",
                Desc = "把当前所有设置写回「已保存的配置」里选中的那个（直接覆盖原文件）",
                Callback = function()
                    local target = cfgPick
                    if not target or target == "（还没有存档）" then
                        notify("覆盖配置", "先在下面选一个要覆盖的配置", "alert-triangle", 4)
                        return
                    end
                    local exists = false
                    for _, n in ipairs(cfgList()) do
                        if n == target then exists = true break end
                    end
                    if not exists then
                        notify("覆盖配置", target .. " 不存在，用「保存当前配置」新建", "alert-triangle", 5)
                        return
                    end
                    cfgSave(target, true)
                    cfgName = tostring(target)     -- 名字框同步成被覆盖的那个
                end,
            })
        end)

        build("Dropdown", function()
            cfgDropdown = cfgSec:Dropdown({
                Title = "已保存的配置",
                Desc = "选一个再点下面的读取 / 删除",
                Values = cfgValuesSafe(),
                Callback = function(v)
                    if type(v) == "table" then v = v.Title or v.Value or v.Name end
                    cfgPick = v
                    if v and v ~= "（还没有存档）" then cfgName = tostring(v) end
                end,
            })
        end)

        build("刷新按钮", function()
            cfgSec:Button({
                Title = "刷新配置列表",
                Callback = function()
                    if cfgDropdown and type(cfgDropdown.Refresh) == "function" then
                        pcall(function() cfgDropdown:Refresh(cfgValuesSafe()) end)
                        notify("配置管理", ("找到 %d 个配置"):format(#cfgList()), "list", 3)
                    end
                end,
            })
        end)

        build("读取按钮", function()
            cfgSec:Button({
                Title = "读取选中配置",
                Desc = "把存档里的值套回所有控件",
                Callback = function() cfgLoad(cfgPick or cfgName) end,
            })
        end)

        build("删除按钮", function()
            cfgSec:Button({
                Title = "删除选中配置",
                Desc = "删掉 suture_configs 里对应的 json",
                Callback = function()
                    if cfgDelete(cfgPick or cfgName) then
                        if cfgDropdown and type(cfgDropdown.Refresh) == "function" then
                            pcall(function() cfgDropdown:Refresh(cfgValuesSafe()) end)
                        end
                    end
                end,
            })
        end)

        build("Paragraph", function()
            cfgSec:Paragraph({
                Title = "说明",
                Desc = "存档位置：执行器工作区 " .. CFG_DIR .. "/<名字>.json。"
                    .. "「保存」= 新建/写入名字框里的名字；「覆盖」= 写回下拉框里选中的那份。"
                    .. "按钮类控件没有状态，不参与保存。"
                    .. "游戏专属脚本是点页签才加载的，先点开对应页签再保存，才能把它一并记下来。",
            })
        end)

        print(("[配置] 控件创建：成功 %d 个"):format(made))
        if #failed > 0 then
            warn("[配置] 以下控件创建失败（其它功能不受影响）:")
            for _, t in ipairs(failed) do warn("  - " .. t) end
        end

        pcall(function()
            local g = (getgenv and getgenv()) or _G
            if g then
                g.__SUIF_CONFIG = {
                    Save = cfgSave, Load = cfgLoad, Delete = cfgDelete,
                    List = cfgList, Dir = CFG_DIR, Collect = cfgCollect,
                }
            end
        end)
        print("[配置] 配置保存/读取已就绪（目录 " .. CFG_DIR .. "）")
    end)
    if not okBlock then
        warn("[配置] 配置区块初始化失败（不影响其它功能）:", errBlock)
    end
end)

end

-- ============ 公告已移至加载器右侧面板展示，主脚本直接启动 ============
initMainScript()

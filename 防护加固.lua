-- ══════════════════════════════════════════════════════════════════════════════
-- 【防护加固】远程脚本（从主脚本 1-196 行打包出来）
-- 静默层 + 全局 print/warn 过滤 + 安全 task + 容器搬迁/改名支持
-- 用法：主脚本启动时同步加载并执行，返回：
--   HARD  布尔   加固开关（getgenv().SutureNoHarden = true 可关）
--   log   函数   静默日志写入
--   rnd   函数   随机名字生成
--   task  表     安全版 task（防协议异常）
-- 加载失败时主脚本自动降级为「无加固但能跑」
-- ══════════════════════════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════════════════════════
-- 【静默层】加载期一个字节都不往控制台输出
--
-- 为什么必须做：执行器里 print / warn 的内容会进 LogService.MessageOut，
-- 游戏只要连一条监听就能在你按下执行、UI 还没画出来的时候抓到脚本特征串；
-- 未捕获的报错还会进 ScriptContext.Error（带调用栈）并被判定为外来脚本。
-- 所以本文件内的 print / warn 被整体替换为写内存缓冲，控制台完全静默。
--
-- 想看日志：控制台执行  =getgenv().SutureLog(true)  会返回整段日志
--           执行  getgenv().SutureLog()           会返回条数
-- ══════════════════════════════════════════════════════════════════════════════
local __LOG, __LOGCAP = {}, 300
-- ★ 排障开关：加载前执行  getgenv().SutureVerbose = true
--   日志就会同时打到控制台（默认全静默）。出了"公告不出来"这类问题先开它。
local __VERBOSE = false
pcall(function()
    local g = getgenv and getgenv()
    if g and g.SutureVerbose then __VERBOSE = true end
end)
-- ★★ 总开关：加载前执行  getgenv().SutureNoHarden = true
--    则下面所有加固逐条失效，脚本回到"原版行为"：
--      不搬容器（GUI 挂回 PlayerGui）、不改名（用回 SutureBall/SutureRscripts）、
--      任务直通（不包 xpcall）、不过滤全局 print/warn、不调 protect_gui。
--    用途：出任何怪问题时先开这个开关，一眼分辨"是不是加固引起的"。
--    日常用不着，默认关闭。
local __HARD = true
pcall(function()
    local g = getgenv and getgenv()
    if g and g.SutureNoHarden then __HARD = false end
end)
local __realPrint = print          -- ★ 在 shadow 之前抓住原生的
local function __lg(...)
    local cnt, parts = select("#", ...), {}
    for i = 1, cnt do parts[i] = tostring((select(i, ...))) end
    local joined = table.concat(parts, " ")
    __LOG[#__LOG + 1] = joined
    if #__LOG > __LOGCAP then table.remove(__LOG, 1) end
    if __VERBOSE then pcall(__realPrint, "[Suture] " .. joined) end
end
local print, warn = __lg, __lg      -- ★ 本文件内彻底静音（含所有嵌套函数）

-- ══════════════════════════════════════════════════════════════════
-- 报错诊断（静默后台）：加载器/主脚本出错时自动弹诊断 UI，平时无感。
-- 加载器已启动过（__SUTURE_DIAG_ACTIVE）则本处自动跳过（防重）。
-- ══════════════════════════════════════════════════════════════════
pcall(function()
    if task and task.spawn then
        task.spawn(function()
            pcall(function()
                local diagSrc = game:HttpGet("https://raw.githubusercontent.com/suif666/suif/main/%E6%8A%A5%E9%94%99%E8%AF%8A%E6%96%AD.lua")
                local diagFn = loadstring(diagSrc)
                if diagFn then diagFn() end
            end)
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- 【任务包装层】task.spawn / task.delay / task.defer 包一层 xpcall。
-- 本文件里原本有 6 处 task.spawn 没被 pcall 保护，其中两个是 while true 常驻循环 ——
-- 里面一旦抛错就会以"未捕获错误"的形式进控制台，同时进 LogService.MessageOut
-- 和 ScriptContext.Error（带调用栈），等于主动告诉游戏"有个外来脚本在我这儿崩了"。
--
-- ★ 写法上的两个硬要求（踩过坑）：
--   1. 绝对不能遍历 task 表去拷贝 —— 有些执行器的 task 是代理，pairs 拿不到键，
--      拷贝出来就是空表，task.spawn 变 nil，本文件末尾拉公告那句会直接报错，
--      表现就是"公告加载不出来"。这里改成 __index 代理，其余键全部落回原生 task。
--   2. 必须自检：万一代理不可用，就原样用回原生 task，宁可少一层保护也不能把脚本弄崩。
-- ══════════════════════════════════════════════════════════════════════════════
local __taskRaw = task                     -- ★ 原生引用留一份，开关关掉时用回它
local __taskSafe = __taskRaw               -- 默认就是原生 task：任何一步出问题都不改行为
pcall(function()
    local t = task
    if type(t) ~= "table" and type(t) ~= "userdata" then return end
    local rawSpawn, rawDelay, rawDefer = t.spawn, t.delay, t.defer
    local __unpack = table.unpack or unpack
    local function wrap(fn)
        if type(fn) ~= "function" then return fn end
        return function(...)
            -- ★ 不依赖 xpcall 转发额外参数（老环境不支持），自己收好再传
            local n = select("#", ...)
            local args = { ... }
            local ok, err = xpcall(function() return fn(__unpack(args, 1, n)) end,
                                   function(e) return tostring(e) end)
            if not ok then __lg("task 内未捕获错误（已吞）：" .. tostring(err)) end
        end
    end
    local proxy = setmetatable({}, { __index = t })    -- ★ 不遍历，其余键透传
    if type(rawSpawn) == "function" then
        rawset(proxy, "spawn", function(fn, ...) return rawSpawn(wrap(fn), ...) end)
    end
    if type(rawDelay) == "function" then
        rawset(proxy, "delay", function(a, fn, ...) return rawDelay(a, wrap(fn), ...) end)
    end
    if type(rawDefer) == "function" then
        rawset(proxy, "defer", function(fn, ...) return rawDefer(wrap(fn), ...) end)
    end
    -- ★ 自检：wait / spawn 都拿得到才启用
    if type(proxy.wait) == "function" and type(proxy.spawn) == "function" then
        __taskSafe = proxy
    end
end)
local task = (__HARD and __taskSafe) or __taskRaw   -- ★ 开关决定走安全版还是原生版

-- ══════════════════════════════════════════════════════════════════════════════
-- 【关于服务引用脱钩 —— 结论：不做】
-- 本来想用 local game = cloneref(game) 来废掉"代理元表记录外来索引"这套陷阱，
-- 实测证明这条路会把脚本弄坏，原因很简单：
--   cloneref 返回的是"干净克隆"，执行器给 game 加的扩展方法全部消失 ——
--   game.HttpGet / game.HttpGetAsync / game.HttpGetAsync 之类当场变 nil。
--   而 WindUI-Boreal 自己就在用它拉两个东西：
--     L386  图标集        l = loadstring(game.HttpGetAsync and game:HttpGetAsync(j) or h:GetAsync(j))()
--     L1938 Luarmor 卡密库 loadstring(game.HttpGetAsync and game:HttpGetAsync(ad) or HttpService:GetAsync(ad))()
--   game.HttpGetAsync 一没，就退到 HttpService:GetAsync（客户端没这个权限）→ 拿到 nil
--   → loadstring(nil)() → "attempt to call a nil value" → 界面报 "Boreal加载失败"。
-- 所以这里彻底不做 game/workspace 脱钩：原样保留执行器包装的 game。
-- 代理元表那类检测的收益，远不值"把 WindUI 弄坏"这个代价。
-- ══════════════════════════════════════════════════════════════════════════════

pcall(function()
    local g = (getgenv and getgenv()) or _G
    if g then
        g.SutureLog = function(full)
            if full == true then return table.concat(__LOG, "\n") end
            return #__LOG
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- 【远程脚本静音】loadstring 出来的代码默认在全局环境里跑，它自己的 print/warn
-- 会绕过上面的本地静默层、直接进 LogService.MessageOut。
-- 实测：WindUI-Boreal 本体有 20 处 warn，L17 的 "[Boreal] GetIcons 获取失败"
-- 在加载阶段就会触发，L20121 是 "[ WindUI ] Unknown theme"，L5234 是
-- "[ WindUI.ConfigManager ]" —— 全是公开库名，正好是游戏黑名单会匹配的东西。
--
-- ★★ 这里绝对不能用 setfenv / 换环境（踩过大坑，2025 修了一轮）：
--    WindUI-Boreal 里有一段 "tick","assert","shared","loadstring","tonumber",...
--    的全局名清单 —— 它会【枚举当前环境】来给它内部 loadstring 出来的子 chunk
--    拼一个新环境。一旦我们把它的 chunk env 换成只有几个键的表，它枚举出来的
--    环境里就没有 loadstring / tick / assert，内部子 chunk 一调用就报
--    "attempt to call a nil value"，表现就是界面上写着 "Boreal加载失败"。
--    所以：不碰任何 chunk 的环境，只把全局 print/warn 换一层过滤 ——
--    命中特征串的吞掉（仍然记进日志，不丢），其余原样放行。
--    对任何库都是零侵入，不可能改坏它的内部逻辑。
--
-- 代价：print 从原生 C 函数变成一个闭包，理论上 tostring(print) 查得出来。
-- 但"改坏 WindUI"比"理论上的可检测性"严重得多，所以选了这条路。
-- ══════════════════════════════════════════════════════════════════════════════
local __SIG = {
    "windui", "boreal", "expand", "configmanager", "window.background",
    "addicons", "suture", "msptds", "doorsesp", "suif",
}
local __installed = false

local function __installFilter()
    if __installed then return end
    __installed = true
    local function makeFilt(real)
        return function(...)
            local cnt, parts = select("#", ...), {}
            for i = 1, cnt do parts[i] = tostring((select(i, ...))) end
            local joined = table.concat(parts, " ")
            local lower = joined:lower()
            for _, pat in ipairs(__SIG) do
                if string.find(lower, pat, 1, true) then
                    __lg(joined)          -- ★ 吞掉，但记进缓冲，别丢
                    return
                end
            end
            return real(...)
        end
    end
    -- ★ 必须"一定装上"，不能"环境有才装"：
    --   旧版用 setfenv 时是显式把 print/warn 塞进沙箱环境的，所以沙箱 chunk 一定有 warn；
    --   改成全局过滤后如果写成"只在 _G.warn 存在时才替换"，那些 _G.warn 恰好缺失的
    --   环境里，远程脚本的 warn(...) 就会直接 "attempt to call a nil value"。
    --   所以这里 print/warn 一律给出可用实现：优先包住原生的，没有就用转发的。
    local rp = rawget(_G, "print")
    if type(rp) ~= "function" then rp = print end
    local rw = rawget(_G, "warn")
    if type(rw) ~= "function" then
        -- 没有原生 warn 就用 print 转发一份（Roblox 里 warn 一定存在，这里只是兜底）
        rw = function(...) return rp(...) end
    end
    pcall(function() rawset(_G, "print", makeFilt(rp)) end)
    pcall(function() rawset(_G, "warn", makeFilt(rw)) end)
end

-- 兼容旧调用点：仍然写 __sandbox(fn)，但它只负责装过滤，绝不动环境
local function __sandbox(fn)
    if __HARD then __installFilter() end
    return fn
end

if __HARD then pcall(__installFilter) end

-- ═══ 返回给调用方 ═══
return {
    HARD = __HARD,
    log = __log,
    rnd = __rnd,
    task = task,
    sandbox = __sandbox,
}

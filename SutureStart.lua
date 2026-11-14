-- ═══════════════════════════════════════════════════════════════
--  Suture Hub 入口（GitHub 版，替代 pastebin 入口）
--  用法：
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/suif666/suif/main/SutureStart.lua"))()
--  镜像入口（raw 被墙/限流时）：
--    loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/suif666/suif@main/SutureStart.lua"))()
--    loadstring(game:HttpGet("https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/main/SutureStart.lua"))()
--  功能：游戏黑名单检测 → 账号封禁检测 → 多镜像加载 SutureLoad5 加载器
-- ═══════════════════════════════════════════════════════════════
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/SutureLoad5.lua"
local CHECK_API = "https://suture-hub-counter.sfbdsl666.workers.dev/check"

local HttpService = game:GetService("HttpService")
local lp = game:GetService("Players").LocalPlayer

-- 本地 URL 解码（Roblox HttpService 没有 UrlDecode，手动解码 %XX）
local function urlDecode(str)
    str = tostring(str):gsub("+", " ")
    return str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

-- 1) 游戏检测：后台返回 detected 表示当前游戏在黑名单中
local okGame, resGame = pcall(function()
    return game:HttpGet(CHECK_API .. "?placeid=" .. HttpService:UrlEncode(tostring(game.PlaceId)), true)
end)

if not okGame then
    warn("[SutureHub] 无法连接后台，已停止加载")
    return
end

local gameBody = tostring(resGame)
warn("[SutureHub] 后台响应: ", gameBody)
if gameBody:find("detected", 1, true) then
    -- 后台可配置踢出提示，响应格式：detected 或 detected|UrlEncode(提示)
    local msg = "当前游戏已被检测，为避免封禁已自动退出"
    local _, pos = gameBody:find("detected|", 1, true)
    if pos then
        local decoded = urlDecode(gameBody:sub(pos + 1))
        if decoded ~= "" then
            msg = decoded
        end
    end
    warn("[SutureHub] 使用踢出提示: ", msg)
    if lp then
        pcall(function()
            lp:Kick(msg)
        end)
    end
    return
end

-- 2) 账号状态校验：被封禁不加载
local okUser, resUser = pcall(function()
    return game:HttpGet(CHECK_API .. "?userid=" .. HttpService:UrlEncode(tostring(lp and lp.UserId or 0)), true)
end)

if not okUser then
    warn("[SutureHub] 无法连接后台，已停止加载")
    return
end

if tostring(resUser):find("banned", 1, true) then
    warn("[SutureHub] 账号已被封禁，无法执行主脚本")
    return
end

-- 3) 多镜像回退加载主脚本（raw → jsDelivr → gh-proxy → gitcode）
local function rawToMirrors(rawUrl)
    local owner, repo, rest = rawUrl:match("^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/(.+)$")
    if not owner then
        return { rawUrl }
    end
    local branch, path
    local h = rest:match("^refs/heads/([^/]+)/(.+)$")
    if h then
        branch, path = h
    else
        branch, path = rest:match("^([^/]+)/(.+)$")
    end
    if not branch or not path then
        return { rawUrl }
    end
    local base = owner .. "/" .. repo
    return {
        rawUrl,
        "https://cdn.jsdelivr.net/gh/" .. base .. "@" .. branch .. "/" .. path,
        "https://gh-proxy.com/https://raw.githubusercontent.com/" .. base .. "/" .. branch .. "/" .. path,
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/" .. base .. "/" .. branch .. "/" .. path,
        "https://raw.gitcode.com/" .. base .. "/raw/" .. branch .. "/" .. path,
    }
end

local function tryLoadAny(urls)
    for _, u in ipairs(urls or {}) do
        local ok, src = pcall(function()
            return game:HttpGet(u)
        end)
        if ok and type(src) == "string" and #src > 0 then
            local fn, cerr = loadstring(src)
            if fn then
                return fn
            end
        end
    end
    return nil
end

local fn = tryLoadAny(rawToMirrors(MAIN_SCRIPT_URL))
if fn then
    pcall(fn)
else
    warn("[SutureHub] 脚本加载失败: 所有镜像源均不可用，请检查网络或更换加速器节点")
end

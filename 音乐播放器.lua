-- ═══════════════════════════════════════════════════════════════════════════════
--  音乐播放器  ·  WindUI 独立脚本
--  搜索 网易云  →  取真实 CDN 直链  →  下载到工作区  →  getcustomasset 注册
--  →  Sound.SoundId 播放
--
--  为什么必须绕这一圈：
--    Sound.SoundId 只认 rbxassetid:// 和 rbxasset:// 两种 scheme。
--    直接把 https://xxx.mp3 塞进去，客户端 ContentProvider 会拒绝加载，
--    控制台只会留一句 Failed to load sound。
--    getcustomasset() 把工作区里的本地文件注册成 rbxasset:// 资源，
--    这样客户端才会真的去解码它 —— 这是播放非托管音频的唯一通道。
--
--  需要的执行器能力（缺一个就不出声，脚本里能自检）：
--    writefile / readfile / isfile / delfile
--    getcustomasset        （Synapse: getsynasset 也行，脚本两个都试）
--    http.request 或 syn.request 或 request   （要能自定义 header、拿二进制 Body）
-- ═══════════════════════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────────────────
-- WindUI
-- ─────────────────────────────────────────────────────────────────────────────
local WindUI
do
    local g = (getgenv and getgenv()) or _G
    WindUI = g.WindUI or g.HB_WindUI
    if not WindUI then
        for _, u in ipairs({
            "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua",
            "https://cdn.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
            "https://gcore.jsdelivr.net/gh/suif666/suif@main/WindUI-Boreal.lua",
        }) do
            local ok, m = pcall(function() return loadstring(game:HttpGet(u))() end)
            if ok and m then WindUI = m break end
        end
    end
    if not WindUI then warn("[音乐] WindUI 加载失败") return end
end

local function notify(title, content, icon, dur)
    pcall(function()
        WindUI:Notify({
            Title = tostring(title),
            Content = content and tostring(content) or nil,
            Icon = icon or "music",
            Duration = dur or 4,
        })
    end)
end

local HIDDEN = (function()
    local g = (getgenv and getgenv()) or _G
    if g and g.__SUIF_HOST then return g.__SUIF_HOST end
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local okc, cg = pcall(function() return game:GetService("CoreGui") end)
    if okc and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end)()

-- ─────────────────────────────────────────────────────────────────────────────
-- 环境探测
-- ─────────────────────────────────────────────────────────────────────────────
local ENV = {
    writefile = type(writefile) == "function",
    readfile  = type(readfile)  == "function",
    isfile    = type(isfile)    == "function",
    delfile   = type(delfile)   == "function",
    asset     = nil,   -- function(path) -> rbxasset://...
    assetName = "无",
    http      = nil,   -- function({Url,Method,Headers}) -> {StatusCode, Body, Headers}
    httpName  = "无（降级 game:HttpGet）",
}

do
    local g = (getgenv and getgenv()) or _G

    -- 资产注册函数：不同执行器名字不同
    for _, n in ipairs({ "getcustomasset", "getsynasset" }) do
        local fn = rawget(_G, n) or (g and g[n])
        if type(fn) == "function" then
            ENV.asset = function(p) return fn(p) end
            ENV.assetName = n
            break
        end
    end

    -- HTTP
    if type(syn) == "table" and type(syn.request) == "function" then
        ENV.http = function(o) return syn.request(o) end
        ENV.httpName = "syn.request"
    elseif type(http) == "table" and type(http.request) == "function" then
        ENV.http = function(o) return http.request(o) end
        ENV.httpName = "http.request"
    elseif type(fluxus) == "table" and type(fluxus.request) == "function" then
        ENV.http = function(o) return fluxus.request(o) end
        ENV.httpName = "fluxus.request"
    elseif type(request) == "function" then
        ENV.http = function(o) return request(o) end
        ENV.httpName = "request"
    end

    -- 工作区绝对路径（用于交给系统播放器）
    for _, fn in ipairs({ "getworkspace", "getWorkspace" }) do
        local f = rawget(_G, fn) or (g and g[fn])
        if type(f) == "function" then
            local ok, p = pcall(f)
            if ok and type(p) == "string" then ENV.workspace = p break end
        end
    end
    if not ENV.workspace and type(syn) == "table" and type(syn.workspace) == "string" then
        ENV.workspace = syn.workspace
    end

    -- 系统命令执行能力
    ENV.exec = nil
    for _, fn in ipairs({ "os.execute", "io.popen" }) do
        local a, b = fn:match("^(%w+)%.(.+)$")
        local holder = ({ os = os, io = io })[a]
        if holder and type(holder[b]) == "function" then
            ENV.exec = function(cmd)
                if b == "execute" then return holder.execute(cmd) end
                local p = holder.popen(cmd)
                if p then pcall(function() p:close() end) end
                return true
            end
            ENV.execName = fn
            break
        end
    end
end

local READY = ENV.writefile and (ENV.asset ~= nil)

-- ─────────────────────────────────────────────────────────────────────────────
-- HTTP 封装
-- ─────────────────────────────────────────────────────────────────────────────
local REFERER = "https://music.163.com/"
local UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15"

local function req(url, headers, follow)
    headers = headers or {}
    if ENV.http then
        local ok, res = pcall(ENV.http, {
            Url = url,
            Method = "GET",
            Headers = headers,
        })
        if ok and type(res) == "table" then
            local code = tonumber(res.StatusCode or res.Status or res.status) or 0
            local body = res.Body or res.body or ""
            local hdrs = res.Headers or res.headers or {}
            -- 302 手动跟一次（有些执行器不自动跳）
            if follow and (code == 301 or code == 302 or code == 307 or code == 308) then
                local loc = hdrs.Location or hdrs.location
                if type(loc) == "table" then loc = loc[1] end
                if type(loc) == "string" and loc ~= "" then
                    return req(loc, headers, false)
                end
            end
            return code, body, hdrs
        end
    end
    -- 降级
    local ok2, body2 = pcall(function() return game:HttpGet(url, true) end)
    if ok2 and type(body2) == "string" then return 200, body2, {} end
    return 0, "", {}
end

local function jsonDecode(s)
    if type(s) ~= "string" or s == "" then return nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(s) end)
    if ok then return d end
    return nil
end

local function urlEncode(s)
    return (tostring(s):gsub("([^%w%-%._~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 判定二进制是不是音频
-- ─────────────────────────────────────────────────────────────────────────────
local function isAudioData(body)
    if type(body) ~= "string" or #body < 2048 then return false end
    local b1, b2, b3, b4 = string.byte(body, 1, 4)
    if b3 and body:sub(1, 3) == "ID3" then return true end     -- MP3 带 ID3
    if b1 == 0xFF and b2 and (b2 >= 0xE0) then return true end  -- MP3 帧同步
    if body:sub(1, 4) == "OggS" then return true end            -- OGG
    if body:sub(1, 4) == "fLaC" then return true end            -- FLAC
    if b1 == 0x00 and b2 == 0x00 and b3 and b3 >= 0x00 then end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 搜索
-- ─────────────────────────────────────────────────────────────────────────────
local function searchSongs(keyword)
    local url = "https://music.163.com/api/search/get/web?s=" .. urlEncode(keyword)
        .. "&type=1&limit=30&offset=0"
    local code, body = req(url, { ["Referer"] = REFERER, ["User-Agent"] = UA })
    if code ~= 200 then return nil, "搜索接口无响应（HTTP " .. tostring(code) .. "）" end

    local data = jsonDecode(body)
    if not data then return nil, "搜索返回不是 JSON（可能被拦或需要登录）" end
    local res = data.result
    if type(res) ~= "table" or type(res.songs) ~= "table" or #res.songs == 0 then
        return nil, "没搜到结果"
    end

    local out = {}
    for _, s in ipairs(res.songs) do
        local singers = {}
        if type(s.artists) == "table" then
            for _, a in ipairs(s.artists) do
                if a.name then table.insert(singers, tostring(a.name)) end
            end
        end
        local dur = tonumber(s.duration) or 0
        table.insert(out, {
            id       = s.id,
            name     = tostring(s.name or "未知"),
            singer   = #singers > 0 and table.concat(singers, " / ") or "未知",
            album    = (type(s.album) == "table" and tostring(s.album.name or "")) or "",
            duration = dur,
            durText  = ("%d:%02d"):format(math.floor(dur / 60000), math.floor(dur / 1000) % 60),
        })
    end
    return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 取链（三路冗余）
-- ─────────────────────────────────────────────────────────────────────────────
local function tryEnhanceApi(songId, br)
    local url = ("https://music.163.com/api/song/enhance/player/url?ids=[%d]&br=%d")
        :format(songId, br)
    local code, body = req(url, { ["Referer"] = REFERER, ["User-Agent"] = UA })
    if code ~= 200 then return nil end
    local d = jsonDecode(body)
    if type(d) ~= "table" or type(d.data) ~= "table" or not d.data[1] then return nil end
    local u = d.data[1].url
    if type(u) == "string" and u ~= "" then
        return u, tonumber(d.data[1].br) or br
    end
    return nil
end

local function tryOuterUrl(songId)
    local url = ("https://music.163.com/song/media/outer/url?id=%d.mp3"):format(songId)
    local code, body, hdrs = req(url, { ["Referer"] = REFERER, ["User-Agent"] = UA }, true)
    if code ~= 200 then return nil end
    if isAudioData(body) then return nil, body end        -- 直接拿到音频
    return nil
end

local function tryMeting(songId)
    local url = ("https://api.injahow.cn/meting/?server=netease&type=url&id=%d"):format(songId)
    local code, body = req(url, { ["User-Agent"] = UA }, true)
    if code ~= 200 then return nil end
    if isAudioData(body) then return nil, body end
    local t = body:match("^%s*(https?://[^\r\n]+)%s*$")
    if t then return t end
    return nil
end

-- 返回：body（已下载的二进制）| url（真实直链，需再下载）| nil, err
local function resolveAudio(songId, quality)
    local br = (quality == "320k") and 320000 or 128000

    -- ① enhance API 拿真实 CDN URL（最准，能指定码率）
    local u1 = tryEnhanceApi(songId, br)
    if u1 then return nil, u1, "enhance" end

    -- ② outer/url 让服务端 302，能直接拿到音频体
    local _, body2 = tryOuterUrl(songId)
    if body2 and isAudioData(body2) then return body2, nil, "outer" end

    -- ③ Meting 代理
    local u3, body3 = tryMeting(songId)
    if body3 and isAudioData(body3) then return body3, nil, "meting" end
    if u3 then return nil, u3, "meting" end

    return nil, nil, nil
end

local function downloadAudio(url)
    local code, body = req(url, { ["User-Agent"] = UA }, true)
    if code ~= 200 then return nil, "下载失败（HTTP " .. tostring(code) .. "）" end
    if not isAudioData(body) then
        return nil, "下载到的不是音频（多半是版权/VIP 拦截页）"
    end
    return body
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 缓存表
-- ─────────────────────────────────────────────────────────────────────────────
local CACHE_JSON = "music_cache.json"
local cacheMap = {}

do
    local ok, raw = pcall(function()
        if ENV.readfile and ENV.isfile and isfile(CACHE_JSON) then return readfile(CACHE_JSON) end
    end)
    if ok and type(raw) == "string" and raw ~= "" then
        local d = jsonDecode(raw)
        if type(d) == "table" then cacheMap = d end
    end
end

local function saveCache()
    pcall(function()
        if ENV.writefile then writefile(CACHE_JSON, HttpService:JSONEncode(cacheMap)) end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 播放器状态
-- ─────────────────────────────────────────────────────────────────────────────
local sound       = nil
local LAST_STATUS = nil       -- 最近一次播放状态快照（诊断用）
local current     = nil       -- 当前歌曲信息
local currentFile = nil
local loopOn      = false
local volume      = 0.5
local seeking     = false

-- ═══════════════════════════════════════════════════════════════════════════
-- 宿主 Sound 机制
--   本环境里脚本自建的 Sound 不推进 TimePosition（对照测试点了没反应就是这个），
--   说明客户端不接受"凭空创建"的音频对象。
--   但游戏自己的 Sound 一定在出声 —— 那就借一个来用：
--   把它的 SoundId 换成我们注册好的本地资产，然后 Play。
-- ═══════════════════════════════════════════════════════════════════════════
local hostSound = nil          -- 被借用的游戏 Sound
local hostOrigin = nil         -- 它的原始 SoundId / Looped / Volume（用完还原）

local function scanSounds(root, out, depth)
    if depth > 3 then return end
    local ok, kids = pcall(function() return root:GetChildren() end)
    if not ok then return end
    for _, c in ipairs(kids) do
        local ok2, isSnd = pcall(function() return c:IsA("Sound") end)
        if ok2 and isSnd then table.insert(out, c) end
        scanSounds(c, out, depth + 1)
    end
end

-- 找候选宿主：优先正在播放的，其次时长已加载的
local function findHostCandidates()
    local all = {}
    scanSounds(SoundService, all, 2)
    scanSounds(workspace, all, 3)
    pcall(function() scanSounds(workspace.CurrentCamera, all, 2) end)

    local playing, loaded = {}, {}
    for _, s in ipairs(all) do
        local ok, len = pcall(function() return s.TimeLength end)
        if ok and len and len > 0 then
            local okp, p = pcall(function() return s.IsPlaying end)
            if okp and p then table.insert(playing, s) else table.insert(loaded, s) end
        end
    end
    -- 正在播放的排前面
    for _, s in ipairs(playing) do table.insert(loaded, 1, s) end
    return loaded, #playing
end

local function grabHost()
    local list = findHostCandidates()
    if #list == 0 then return nil end
    local s = list[1]
    hostSound = s
    hostOrigin = {
        SoundId = s.SoundId,
        Looped  = s.Looped,
        Volume  = s.Volume,
    }
    print("[音乐] 借用宿主 Sound: " .. tostring(s:GetFullName()) .. " | 原时长 "
        .. tostring(s.TimeLength))
    return s
end

local function releaseHost()
    if not hostSound or not hostOrigin then return end
    pcall(function()
        hostSound.SoundId = hostOrigin.SoundId
        hostSound.Looped  = hostOrigin.Looped
        hostSound.Volume  = hostOrigin.Volume
        hostSound:Play()
    end)
    print("[音乐] 已还原宿主 Sound")
    hostSound, hostOrigin = nil, nil
end

local function ensureSound()
    if sound and sound.Parent then return sound end
    local ok, s = pcall(function()
        local snd = Instance.new("Sound")
        snd.Name    = "SutureMusicPlayer"
        snd.Volume  = volume
        snd.Looped  = loopOn
        snd.Parent  = SoundService
        return snd
    end)
    if ok then sound = s end
    return sound
end

-- 把文件注册成 rbxasset 并播放（自适应：自建对象不行就借游戏的）
local function playFile(fileName, info, onStatus)
    local asset
    for _, p in ipairs({ fileName, "./" .. fileName }) do
        local ok, a = pcall(ENV.asset, p)
        if ok and type(a) == "string" and a ~= "" then asset = a break end
    end
    if not asset then
        notify("注册失败", ENV.assetName .. "() 没返回可用的资产路径", "alert-triangle", 7)
        if onStatus then onStatus("注册失败：" .. ENV.assetName) end
        return false
    end

    current     = info
    currentFile = fileName

    -- ① 先试自建 Sound
    local snd = ensureSound()
    local usedHost = false

    local function attempt(sound, tag)
        sound.SoundId = asset
        sound.Volume  = volume
        sound.Looped  = loopOn
        pcall(function() sound.TimePosition = 0 end)
        pcall(function() sound:Play() end)
        pcall(function() SoundService:PlayLocalSound(sound) end)

        -- 等 1.2 秒看 TimePosition 是否推进
        local t0 = 0
        pcall(function() t0 = sound.TimePosition end)
        task.wait(1.2)
        local t1 = 0
        pcall(function() t1 = sound.TimePosition end)
        print(("[音乐] %s: TimePos %.2f → %.2f | IsPlaying=%s | TimeLen=%.1f")
            :format(tag, t0, t1, tostring(sound.IsPlaying), sound.TimeLength or 0))
        return t1 > t0
    end

    -- ①-a 自建 Sound，挂在 SoundService（2D 全局音效）
    if snd then
        if attempt(snd, "自建/SoundService") then
            if onStatus then
                onStatus(("正在播放：%s - %s\n方式：SoundService（2D）\n文件：%s")
                    :format(tostring(info.name), tostring(info.singer), fileName))
            end
            notify("正在播放", tostring(info.name) .. " - " .. tostring(info.singer), "play", 4)
            return true
        end
        pcall(function() snd:Stop() end)
    end

    -- ①-b 换挂到相机下，作为 3D 音效
    --     SoundService 里是 2D 通道，workspace 下走 3D 空间音频通道。
    --     两条路的混音链路不同，2D 被静音时 3D 常常还能出声。
    local cam = workspace.CurrentCamera
    if cam then
        local ok3, s3 = pcall(function()
            local s = Instance.new("Sound")
            s.Name            = "SutureMusic3D"
            s.RollOffMode     = Enum.RollOffMode.InverseTapered
            s.RollOffMinDistance = 100000      -- 让衰减半径拉到极大 → 始终满音量
            s.RollOffMaxDistance = 100000
            s.Parent          = cam
            return s
        end)
        if ok3 and s3 then
            if attempt(s3, "自建/Camera 3D") then
                snd = s3
                if onStatus then
                    onStatus(("正在播放：%s - %s\n方式：相机下 3D 音效\n文件：%s")
                        :format(tostring(info.name), tostring(info.singer), fileName))
                end
                notify("正在播放", tostring(info.name) .. " - " .. tostring(info.singer)
                    .. "（3D 通道）", "play", 4)
                return true
            end
            pcall(function() s3:Destroy() end)
        end
    end

    -- ② 自建不行 → 借宿主
    local host = grabHost()
    if host then
        usedHost = true
        if attempt(host, "宿主 Sound(" .. tostring(host:GetFullName()) .. ")") then
            if onStatus then
                onStatus(("正在播放：%s - %s\n方式：借用游戏内的 Sound\n宿主：%s\n文件：%s")
                    :format(tostring(info.name), tostring(info.singer), tostring(host:GetFullName()), fileName))
            end
            notify("正在播放", tostring(info.name) .. " - " .. tostring(info.singer)
                .. "（借用游戏音源）", "play", 4)
            return true
        end
        releaseHost()
    end

    -- ③ 都不行
    if onStatus then
        onStatus(("注册成功但播不出来：%s\n\n自建 Sound 和借用宿主都没有推进 TimePosition。\n"
            .. "说明这个执行器环境不允许脚本播放音频。\n\n"
            .. "可用的替代：点「控制 → 复制当前歌曲直链」拿去浏览器听。")
            :format(fileName))
    end
    notify("播不出来", "自建 Sound 和借用宿主都无效，去「环境」页看诊断", "alert-triangle", 8)
    return false
end

-- 主流程：搜到的歌 → 下载 → 播放
local function playSong(song, quality, onStatus)
    if not READY then
        notify("环境不完整", "缺 writefile 或 " .. ENV.assetName, "alert-triangle", 7)
        return
    end
    if type(song) ~= "table" or not song.id then
        notify("播放", "先搜一首歌并选中", "alert-triangle")
        return
    end

    local fileName = ("music_%d.mp3"):format(song.id)
    local cached = false
    pcall(function()
        if ENV.isfile and isfile(fileName) then cached = true end
    end)

    if cached then
        if onStatus then onStatus("命中缓存，直接播放…") end
        playFile(fileName, song, onStatus)
        return
    end

    task.spawn(function()
        if onStatus then onStatus("取链中（" .. quality .. "）…") end
        local body, url, via = resolveAudio(song.id, quality)

        if not body and url then
            if onStatus then onStatus("下载中…\n" .. url:sub(1, 90)) end
            local b, err = downloadAudio(url)
            if not b then
                notify("下载失败", err, "alert-triangle", 7)
                if onStatus then onStatus("失败：" .. tostring(err)) end
                return
            end
            body = b
        elseif not body then
            notify("取链失败", "三条通道都没拿到音频（这首歌可能需要 VIP）", "alert-triangle", 7)
            if onStatus then
                onStatus("取链失败。\n· enhance API 无返回\n· outer/url 非音频\n· meting 无返回\n多半是 VIP / 版权限制。")
            end
            return
        end

        local mb = #body / 1048576
        if onStatus then onStatus(("写入文件（%.1f MB，via %s）…"):format(mb, tostring(via))) end

        local okW, eW = pcall(function() writefile(fileName, body) end)
        if not okW then
            notify("写入失败", "writefile 失败：" .. tostring(eW) .. "\n（可能超出执行器文件大小上限）",
                "alert-triangle", 8)
            if onStatus then onStatus("写入失败：" .. tostring(eW)) end
            return
        end

        cacheMap[fileName] = {
            id = song.id, name = song.name, singer = song.singer,
            album = song.album, durText = song.durText, size = #body,
        }
        saveCache()

        playFile(fileName, song, onStatus)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 窗口
-- ─────────────────────────────────────────────────────────────────────────────
local win = WindUI:CreateWindow({
    Title         = "音乐播放器",
    Icon          = "music",
    Author        = "网易云搜索 → 本地资产 → 真播放",
    Folder        = "SutureMusic",
    Size          = UDim2.fromOffset(640, 470),
    Transparent   = true,
    Theme         = "Dark",
    Resizable     = true,
    SideBarWidth  = 180,
    HideSearchBar = true,
})

pcall(function()
    if type(WindUI.SetParent) == "function" then WindUI:SetParent(HIDDEN) end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- Tab 1 · 搜索
-- ═════════════════════════════════════════════════════════════════════════════
local searchTab = win:Tab({ Title = "搜索", Icon = "search" })
local sSec      = searchTab:Section({ Title = "找歌", Opened = true })
local statusPara
local results   = {}
local quality   = "320k"
local resultDrop

local function setStatus(t)
    if statusPara then pcall(function() statusPara:SetDesc(tostring(t)) end) end
end

local keyword = ""
sSec:Input({
    Title       = "关键词",
    Desc        = "歌名 或 歌手，回车后点搜索",
    Value       = "",
    Placeholder = "例如 晴天 周杰伦",
    Callback    = function(v) keyword = tostring(v or "") end,
})

sSec:Dropdown({
    Title    = "音质",
    Desc     = "320k 文件大一些，音质好",
    Values   = { "320k", "128k" },
    Value    = "320k",
    Callback = function(v)
        if type(v) == "table" then v = v.Title or v.Value end
        quality = (v == "128k") and "128k" or "320k"
    end,
})

sSec:Button({
    Title    = "搜索",
    Desc     = "网易云公开接口，最多 30 条",
    Callback = function()
        if keyword == "" then
            notify("搜索", "先填关键词", "alert-triangle")
            return
        end
        task.spawn(function()
            setStatus("搜索中：" .. keyword)
            local list, err = searchSongs(keyword)
            if not list then
                notify("搜索失败", tostring(err), "alert-triangle", 6)
                setStatus("搜索失败：" .. tostring(err))
                return
            end
            results = list
            local vals = {}
            for _, s in ipairs(list) do
                table.insert(vals, ("%s - %s  [%s]"):format(s.name, s.singer, s.durText))
            end
            if resultDrop then
                pcall(function() resultDrop:Refresh(vals) end)
            end
            notify("搜索完成", ("%d 首"):format(#list), "check", 3)
            setStatus(("搜到 %d 首，下拉框里选一首再点播放"):format(#list))
        end)
    end,
})

resultDrop = sSec:Dropdown({
    Title    = "结果",
    Desc     = "选中后点下面的播放",
    Values   = { "（先点搜索）" },
    Callback = function() end,
})

sSec:Button({
    Title    = "播放选中",
    Desc     = "下载 → 注册为本地资产 → 出声",
    Callback = function()
        local pick
        pcall(function() pick = resultDrop.Value end)
        if type(pick) == "table" then pick = pick.Title or pick.Value end
        for _, s in ipairs(results) do
            local label = ("%s - %s  [%s]"):format(s.name, s.singer, s.durText)
            if label == pick then
                playSong(s, quality, setStatus)
                return
            end
        end
        notify("播放", "先在下拉框里选一首", "alert-triangle")
    end,
})

local stSec = searchTab:Section({ Title = "状态", Opened = true })
statusPara = stSec:Paragraph({
    Title = "当前",
    Desc  = READY and "就绪。输入关键词 → 搜索 → 选歌 → 播放。"
        or ("环境不完整：缺 " .. (ENV.writefile and "" or "writefile ")
            .. (ENV.asset and "" or ENV.assetName)),
})

-- ═════════════════════════════════════════════════════════════════════════════
-- Tab 2 · 控制
-- ═════════════════════════════════════════════════════════════════════════════
local ctrlTab = win:Tab({ Title = "控制", Icon = "sliders" })
local cSec    = ctrlTab:Section({ Title = "播放控制", Opened = true })

cSec:Toggle({
    Title    = "循环当前歌曲",
    Value    = false,
    Callback = function(on)
        loopOn = on and true or false
        if sound then pcall(function() sound.Looped = loopOn end) end
    end,
})

cSec:Slider({
    Title    = "音量",
    Desc     = "0.5 = 默认",
    Step     = 0.05,
    Value    = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        volume = tonumber(v) or 0.5
        if sound then pcall(function() sound.Volume = volume end) end
    end,
})

local seekSlider
seekSlider = cSec:Slider({
    Title    = "进度",
    Desc     = "拖动跳转（播放中才有效）",
    Step     = 1,
    Value    = { Min = 0, Max = 100, Default = 0 },
    Callback = function(v)
        if seeking then return end
        if not sound or not sound.IsPlaying then return end
        if sound.TimeLength <= 0 then return end
        seeking = true
        local target = (tonumber(v) or 0) / 100 * sound.TimeLength
        pcall(function() sound.TimePosition = target end)
        task.delay(0.35, function() seeking = false end)
    end,
})

cSec:Button({
    Title    = "暂停 / 继续",
    Callback = function()
        if not sound or not sound.Parent then
            notify("控制", "还没在播放", "info")
            return
        end
        if sound.IsPlaying then
            pcall(function() sound:Pause() end)
        else
            pcall(function() sound:Resume() end)
        end
    end,
})

cSec:Button({
    Title    = "停止",
    Callback = function()
        if sound then pcall(function() sound:Stop() end) end
        if seekSlider then pcall(function() seekSlider:Set(0) end) end
    end,
})

cSec:Button({
    Title    = "★ 用系统播放器打开（绕过 Roblox 音频限制）",
    Desc     = "把下好的 mp3 交给电脑上的播放器，声音从扬声器出，不经过 Roblox",
    Callback = function()
        if not currentFile or not current then
            notify("打开", "先播放或下载一首", "alert-triangle")
            return
        end
        local exists = false
        pcall(function()
            if ENV.isfile and isfile(currentFile) then exists = true end
        end)
        if not exists then
            notify("打开", currentFile .. " 不存在，先下一首", "alert-triangle", 6)
            return
        end

        local abs = (ENV.workspace and (ENV.workspace .. "/" .. currentFile)) or currentFile

        if not ENV.exec then
            notify("不支持系统命令", "这个执行器禁用了 os.execute / io.popen\n文件路径：" .. abs,
                "alert-triangle", 10)
            pcall(function() setclipboard(abs) end)
            return
        end

        local tried = {}
        local ok = false
        for _, cmd in ipairs({
            'start "" "' .. abs .. '"',                    -- Windows
            'cmd /c start "" "' .. abs .. '"',
            'xdg-open "' .. abs .. '"',                    -- Linux
            'open "' .. abs .. '"',                        -- macOS
            'am start -a android.intent.action.VIEW -d "file://' .. abs .. '"',  -- Android
        }) do
            local okc = pcall(ENV.exec, cmd)
            table.insert(tried, (okc and "✓ " or "✗ ") .. cmd:sub(1, 60))
            if okc then ok = true break end
        end

        local msg = ("路径：%s\n方式：%s\n\n尝试记录：\n%s"):format(
            abs, tostring(ENV.execName), table.concat(tried, "\n"))
        diagPara:SetDesc(msg)
        print("[音乐] 系统播放:\n" .. msg)
        if ok then
            notify("已交给系统", "应该会在外部播放器打开", "external-link", 7)
        else
            pcall(function() setclipboard(abs) end)
            notify("都失败了", "路径已复制到剪贴板，手动打开", "alert-triangle", 9)
        end
    end,
})

cSec:Button({
    Title    = "复制当前歌曲直链",
    Desc     = "拿去浏览器 / VLC 听",
    Callback = function()
        if not current then
            notify("复制", "还没播放过", "info")
            return
        end
        local u = ("https://music.163.com/song/media/outer/url?id=%d.mp3"):format(current.id)
        local ok = pcall(function() setclipboard(u) end)
        notify("复制直链", ok and "已复制到剪贴板" or u, "clipboard", 7)
        print("[音乐] 直链: " .. u)
    end,
})

-- 进度条刷新（只在播放中，1 秒一次，避免每帧）
task.spawn(function()
    while true do
        task.wait(1)
        if sound and sound.Parent and sound.IsPlaying and sound.TimeLength > 0 and not seeking then
            local pct = math.floor(sound.TimePosition / sound.TimeLength * 100)
            if seekSlider then pcall(function() seekSlider:Set(pct) end) end
        end
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- Tab 3 · 已下载
-- ═════════════════════════════════════════════════════════════════════════════
local cacheTab = win:Tab({ Title = "已下载", Icon = "download" })
local caSec    = cacheTab:Section({ Title = "本地缓存", Opened = true })

local function cacheValues()
    local v = {}
    for _, m in pairs(cacheMap) do
        table.insert(v, ("%s - %s"):format(tostring(m.name), tostring(m.singer)))
    end
    table.sort(v)
    if #v == 0 then v = { "（还没有下载过）" } end
    return v
end

local cacheDrop = caSec:Dropdown({
    Title    = "已下载歌曲",
    Values   = cacheValues(),
    Callback = function() end,
})

caSec:Button({
    Title    = "刷新列表",
    Callback = function()
        pcall(function() cacheDrop:Refresh(cacheValues()) end)
        notify("缓存", ("%d 首"):format(#cacheValues()), "list", 3)
    end,
})

caSec:Button({
    Title    = "播放已下载",
    Callback = function()
        local pick
        pcall(function() pick = cacheDrop.Value end)
        if type(pick) == "table" then pick = pick.Title or pick.Value end
        for file, m in pairs(cacheMap) do
            if ("%s - %s"):format(tostring(m.name), tostring(m.singer)) == pick then
                playFile(file, m, setStatus)
                return
            end
        end
        notify("播放", "先选一首已下载的", "alert-triangle")
    end,
})

caSec:Button({
    Title    = "删除选中",
    Callback = function()
        local pick
        pcall(function() pick = cacheDrop.Value end)
        if type(pick) == "table" then pick = pick.Title or pick.Value end
        for file, m in pairs(cacheMap) do
            if ("%s - %s"):format(tostring(m.name), tostring(m.singer)) == pick then
                pcall(function() if ENV.delfile then delfile(file) end end)
                cacheMap[file] = nil
                saveCache()
                pcall(function() cacheDrop:Refresh(cacheValues()) end)
                notify("已删除", tostring(m.name), "trash-2", 3)
                return
            end
        end
    end,
})

caSec:Button({
    Title    = "清空全部缓存",
    Callback = function()
        local n = 0
        for file in pairs(cacheMap) do
            pcall(function() if ENV.delfile then delfile(file) end end)
            cacheMap[file] = nil
            n = n + 1
        end
        saveCache()
        pcall(function() cacheDrop:Refresh(cacheValues()) end)
        notify("清空缓存", ("删掉 %d 个文件"):format(n), "trash-2", 4)
    end,
})

-- ═════════════════════════════════════════════════════════════════════════════
-- Tab 4 · 环境
-- ═════════════════════════════════════════════════════════════════════════════
local diagTab = win:Tab({ Title = "环境", Icon = "terminal" })
local dSec    = diagTab:Section({ Title = "执行器自检", Opened = true })

local diagPara = dSec:Paragraph({
    Title = "点下面按钮检测",
    Desc  = READY and "关键函数都在，理论上能出声。" or "缺关键函数，播不了。",
})

dSec:Button({
    Title    = "★ 扫描游戏内的 Sound（直接的办法）",
    Desc     = "列出这个游戏里所有能出声的 Sound，播放器会借一个来用",
    Callback = function()
        local list, playing = findHostCandidates()
        local L = {}
        table.insert(L, ("扫到 %d 个已加载的 Sound（%d 个正在播放）"):format(#list, playing))
        table.insert(L, "")
        for i, s in ipairs(list) do
            if i > 12 then
                table.insert(L, ("  …还有 %d 个"):format(#list - 12))
                break
            end
            table.insert(L, ("%d. %s"):format(i, tostring(s:GetFullName())))
            table.insert(L, ("    时长 %.1f 秒 | 播放中 %s | 音量 %.2f | Id %s"):format(
                s.TimeLength or 0, tostring(s.IsPlaying), s.Volume or 0,
                tostring(s.SoundId):sub(1, 50)))
        end
        if #list == 0 then
            table.insert(L, "")
            table.insert(L, "一个都没有 —— 这个游戏没有任何已加载的 Sound，")
            table.insert(L, "借宿主的办法也用不了。")
        end

        local txt = table.concat(L, "\n")
        diagPara:SetDesc(txt)
        print("[音乐] Sound 扫描:\n" .. txt)

        if #list > 0 then
            notify("找到宿主", ("%d 个候选，播放时会自动借用"):format(#list), "check", 4)
        else
            notify("没有宿主", "这个游戏没加载任何 Sound", "alert-triangle", 5)
        end
    end,
})

dSec:Button({
    Title    = "还原宿主 Sound",
    Desc     = "把借来的游戏音源换回去（退出前点一下）",
    Callback = function()
        if hostSound then
            releaseHost()
            notify("已还原", "游戏原音源已恢复", "rotate-ccw", 4)
        else
            notify("还原", "当前没有借用任何 Sound", "info", 3)
        end
    end,
})

dSec:Button({
    Title    = "★ 对照测试（先跑这个定位问题）",
    Desc     = "用 Roblox 官方音效做对照，判断是「客户端静音」还是「本地资产播不了」",
    Callback = function()
        local L = {}
        local function add(s) table.insert(L, s) end
        add("═══ 对照测试 ═══")
        add(("SoundService.Volume = %.2f"):format(SoundService.Volume))
        add(("SoundService.RolloffScale = %s"):format(tostring(SoundService.RolloffScale)))

        -- 对照组：Roblox 官方 UI 音效（rbxassetid）
        add("")
        add("【对照组】rbxassetid://9118823101（官方 UI 音效，音量 5）")
        local s1 = Instance.new("Sound")
        s1.SoundId = "rbxassetid://9118823101"
        s1.Volume  = 5
        s1.Parent  = SoundService
        pcall(function() SoundService:PlayLocalSound(s1) end)
        task.wait(2.5)
        add(("  IsPlaying=%s  IsLoaded=%s  TimeLen=%.2f  TimePos=%.2f")
            :format(tostring(s1.IsPlaying), tostring(s1.IsLoaded),
                s1.TimeLength or 0, s1.TimePosition or 0))
        pcall(function() s1:Destroy() end)

        local ctrlOk = (s1.TimeLength or 0) > 0
        add(ctrlOk and "  → 官方音效可以加载" or "  → 官方音效都加载不了，客户端音频可能被禁")

        -- 实验组：本地资产（如果有音频文件）
        add("")
        add("【实验组】本地 rbxasset 资产")
        local testFile
        for file in pairs(cacheMap) do testFile = file break end
        if not testFile then
            add("  没有已下载的文件，先去搜索页下 1 首")
        else
            local asset
            for _, p in ipairs({ testFile, "./" .. testFile }) do
                local ok, a = pcall(ENV.asset, p)
                if ok and type(a) == "string" then asset = a break end
            end
            if not asset then
                add("  " .. ENV.assetName .. " 失败")
            else
                add("  资产路径：" .. asset)
                local s2 = Instance.new("Sound")
                s2.SoundId = asset
                s2.Volume  = 5
                s2.Parent  = SoundService
                local w = 0
                while not s2.IsLoaded and w < 8 do task.wait(0.1) w = w + 0.1 end
                add(("  等待加载 %.1f 秒后 IsLoaded=%s"):format(w, tostring(s2.IsLoaded)))
                pcall(function() SoundService:PlayLocalSound(s2) end)
                task.wait(2.5)
                add(("  IsPlaying=%s  TimeLen=%.2f  TimePos=%.2f")
                    :format(tostring(s2.IsPlaying), s2.TimeLength or 0, s2.TimePosition or 0))
                pcall(function() s2:Destroy() end)
            end
        end

        add("")
        add("【结论怎么读】")
        add("  对照组有声、实验组没声 → getcustomasset 的音频客户端不解码")
        add("  两组都没声            → 客户端/设备静音，或游戏锁了 SoundService")
        add("  两组都显示 IsPlaying 但没声 → 输出设备问题，检查系统音量")
        local txt = table.concat(L, "\n")
        diagPara:SetDesc(txt)
        print("[音乐] 对照测试:\n" .. txt)
    end,
})

dSec:Button({
    Title    = "打印当前播放状态",
    Desc     = "播放中卡住时点一下，看 TimePosition 有没有在走",
    Callback = function()
        if not sound then
            notify("状态", "还没创建过 Sound", "info")
            return
        end
        local t1 = sound.TimePosition or 0
        task.wait(1.5)
        local t2 = sound.TimePosition or 0
        local L = {
            ("SoundId    = %s"):format(tostring(sound.SoundId):sub(1, 80)),
            ("IsLoaded   = %s"):format(tostring(sound.IsLoaded)),
            ("IsPlaying  = %s"):format(tostring(sound.IsPlaying)),
            ("TimeLength = %.2f"):format(sound.TimeLength or 0),
            ("TimePos    = %.2f → %.2f（%s）"):format(t1, t2, (t2 > t1) and "在走 ✓" or "没走 ✗"),
            ("Volume     = %.2f"):format(sound.Volume or 0),
            ("SvcVol     = %.2f"):format(SoundService.Volume),
            ("SoundGroup = %s"):format(tostring(sound.SoundGroup)),
            ("Parent     = %s"):format(tostring(sound.Parent)),
        }
        local txt = table.concat(L, "\n")
        diagPara:SetDesc(txt)
        print("[音乐] 状态:\n" .. txt)
        if t2 <= t1 then
            notify("没有在推进", "TimePosition 不动 = 客户端没真正开始播", "alert-triangle", 6)
        end
    end,
})

dSec:Button({
    Title    = "运行自检",
    Callback = function()
        local L = {}
        local function mark(name, v, extra)
            table.insert(L, ("  %s %s%s"):format(v and "✓" or "✗", name, extra and ("  " .. extra) or ""))
        end
        mark("writefile", ENV.writefile)
        mark("readfile", ENV.readfile)
        mark("isfile", ENV.isfile)
        mark("delfile", ENV.delfile)
        mark("资产注册", ENV.asset ~= nil, "(" .. ENV.assetName .. ")")
        mark("HTTP 请求", ENV.http ~= nil, "(" .. ENV.httpName .. ")")
        table.insert(L, "")

        -- 真跑一次下载 + 注册，验证闭环
        if READY then
            table.insert(L, "实测一次完整闭环（下载 1 首小样 → 注册 → 播放）…")
            local txt = table.concat(L, "\n")
            diagPara:SetDesc(txt)
            task.spawn(function()
                local body, url, via = resolveAudio(2668397359, "128k")
                if not body and url then body = downloadAudio(url) end
                if not body then
                    table.insert(L, "  ✗ 取链失败（网络或 VIP 限制）")
                    diagPara:SetDesc(table.concat(L, "\n"))
                    return
                end
                table.insert(L, ("  ✓ 取链成功 via %s，%.1f MB"):format(tostring(via), #body / 1048576))
                local testFile = "music_selftest.mp3"
                local okW, eW = pcall(function() writefile(testFile, body) end)
                if not okW then
                    table.insert(L, "  ✗ writefile 失败：" .. tostring(eW))
                    diagPara:SetDesc(table.concat(L, "\n"))
                    return
                end
                table.insert(L, "  ✓ writefile 成功")
                local okA, asset = pcall(ENV.asset, testFile)
                if not okA or type(asset) ~= "string" then
                    table.insert(L, "  ✗ " .. ENV.assetName .. " 失败：" .. tostring(asset))
                else
                    table.insert(L, "  ✓ 注册成功 → " .. asset:sub(1, 70))
                    local snd = ensureSound()
                    snd.SoundId = asset
                    pcall(function() snd:Play() end)
                    task.wait(3)
                    if snd.TimeLength > 0 then
                        table.insert(L, ("  ✓ 客户端解码成功，时长 %.1f 秒"):format(snd.TimeLength))
                        table.insert(L, "")
                        table.insert(L, "→ 全链路通过，直接去「搜索」页开始用。")
                    else
                        table.insert(L, "  ✗ 客户端没解码（TimeLength=0）")
                        table.insert(L, "")
                        table.insert(L, "→ 音频注册成功但客户端不认，可能被 fflag 拦或被限制扩展名。")
                    end
                    pcall(function() snd:Stop() end)
                end
                diagPara:SetDesc(table.concat(L, "\n"))
                print("[音乐] 自检:\n" .. table.concat(L, "\n"))
            end)
            return
        end

        table.insert(L, "→ 缺 writefile 或资产注册函数，播不了。")
        diagPara:SetDesc(table.concat(L, "\n"))
        print("[音乐] 自检:\n" .. table.concat(L, "\n"))
    end,
})

dSec:Paragraph({
    Title = "为什么不能直接塞 mp3 链接",
    Desc  = "Sound.SoundId 只认 rbxassetid:// 和 rbxasset://。"
        .. "getcustomasset 把工作区里的文件注册成 rbxasset:// 资源，"
        .. "这是让客户端播放非 Roblox 托管音频的唯一办法。"
        .. "\n\n注意：网易云上大量歌曲（尤其原版热门）需要 VIP，"
        .. "enhance API 会返回空 url，脚本会明确报「取链失败」而不是假装播放。",
})

-- 启动
print(("[音乐] 就绪 | READY=%s | 资产=%s | HTTP=%s")
    :format(tostring(READY), ENV.assetName, ENV.httpName))

if not READY then
    task.delay(1, function()
        notify("环境不完整",
            "缺 writefile 或 " .. ENV.assetName .. "，播放会失败。去「环境」页看自检。",
            "alert-triangle", 9)
    end)
else
    task.delay(1, function()
        notify("音乐播放器", "就绪。建议先去「环境」页点一次自检验证闭环。", "music", 6)
    end)
end
--[[
═══════════════════════════════════════════════════════════════════════════
  Abysall Hub 汉化 · 加载器   (运行时注入，原版脚本零改动)
═══════════════════════════════════════════════════════════════════════════

  为什么这样写：
    Abysall 的保护会判定「主脚本文件被改过」= 盗版 → 踢出（错误码 267）。
    实测结论：
      官方原文逐字节不改        → 不踢
      官方原文 + 一行注释       → 不踢
      官方原文 + 末尾加汉化表   → 不踢
      任何改动正文的汉化版      → 踢
    所以：主脚本一个字节都不碰，汉化放在【独立的覆盖层文件】里，
          由本加载器在运行时读入并执行，覆盖层只替换界面文字，只读不写。

  用法：
    第一次要在执行器里建好本地文件（见交付说明里的两条 writefile）。
    之后每次只要一行：
        loadstring(readfile("abycn/loader.lua"))()

  接口：
    getgenv().AbysallCN.Off()     关闭汉化
    getgenv().AbysallCN.Fix()     立刻重刷一遍
    getgenv().AbysallCN.Stats()   看命中统计
═══════════════════════════════════════════════════════════════════════════
]]

-- 覆盖层地址。原来的写法有两个坑：
--   ① 只走 cdn.jsdelivr.net —— 本机实测 Connection reset（http 000）
--   ② @43ed6b2… 把 commit 钉死了 —— 仓库以后更新也永远拉不到
-- 现在改成 @main（跟仓库最新）+ 多线路兜底，顺序按实测速度排。
local RemoteList = {
	"https://testingcf.jsdelivr.net/gh/suif666/suif@main/AbysallCN_Overlay.lua",
	"https://gcore.jsdelivr.net/gh/suif666/suif@main/AbysallCN_Overlay.lua",
	"https://fastly.jsdelivr.net/gh/suif666/suif@main/AbysallCN_Overlay.lua",
	"https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/main/AbysallCN_Overlay.lua",
	"https://cdn.jsdelivr.net/gh/suif666/suif@main/AbysallCN_Overlay.lua",
}
local Local  = "abycn/overlay.lua"

local function readAny(path)
    -- isfile 不是所有执行器都有，所以能问就问，问不了就直接试着读
    if type(isfile) == "function" then
        local ok, exists = pcall(isfile, path)
        if not ok or not exists then return nil end
    end
    local ok, data = pcall(readfile, path)
    if ok and type(data) == "string" and #data > 1000 then return data end
    return nil
end

local function getOverlay()
    -- ① 优先用执行器本地文件：这样游戏内不产生任何指向第三方仓库的请求
    local local_data = readAny(Local)
    if local_data then
        print("[汉化] 使用本地覆盖层 " .. Local)
        return local_data
    end
    -- ② 本地没有就联网取一次，并顺手存到本地，下次就不用联网了
    print("[汉化] 本地没有 " .. Local .. "，联网获取中…")
    local data, failed = nil, {}
    for _, url in ipairs(RemoteList) do
        local ok, got = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(got) == "string" and #got > 1000 then
            data = got
            print("[汉化] 覆盖层取自 " .. (url:match("^https://([^/]+)") or url))
            break
        end
        failed[#failed + 1] = url:match("^https://([^/]+)") or url
    end
    if not data then
        error("[汉化] 覆盖层获取失败，所有线路都不通：" .. table.concat(failed, ", ")
            .. "。请手动把覆盖层存成 " .. Local, 0)
    end
    pcall(writefile, Local, data)
    print("[汉化] 已保存到本地，下次直接用本地文件")
    return data
end

local src = getOverlay()

local fn, err = loadstring(src, "=AbysallCN_Overlay")
if not fn then
    error("[汉化] 覆盖层编译失败: " .. tostring(err), 0)
end

fn()
print("[汉化] 覆盖层已加载，正在从官方源载入原版脚本…")

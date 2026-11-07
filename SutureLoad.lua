--[[
  SutureLoad v1.0 —— Suture Hub 一键启动（加载器入口）
  执行这一条脚本 = 加载器界面 + 加载 WindUI + 启动 Suture Hub

  流程：
    1. 加载 SutureLoader（虚化背景 + 雪花 + 标题渐显 + 圆角进度条）
    2. 任务1「正在加载 UI 库」→ 预载 WindUI 到 _G.WindUI（suif 主脚本检测到后不再重复加载）
    3. 任务2「正在加载 Suture Hub」→ 执行 suif 主脚本（弹公告，点"执行"后构建主界面）
    4. suif 主界面构建完成（__SUIF_READY）→ 加载器淡出
]]

-- ═══════════ 链接配置 ═══════════
local LOADER_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/SutureLoader.lua?v=loader101"
local SUIF_URL = "https://raw.githubusercontent.com/suif666/suif/refs/heads/main/suif.lua?v=suif102"

-- WindUI-Boreal（suif 主脚本同源 4 镜像）
local WINDUI_SRC = {
	"https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand21",
	"https://cdn.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
	"https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/refs/heads/main/WindUI-Boreal.lua?v=expand11",
	"https://gcore.jsdelivr.net/gh/suif666/suif@2f7140bc37b525d1cdd154db7cb0b05c0379de01/WindUI-Boreal.lua",
}

local function tryLoad(url)
	local ok, src = pcall(function() return game:HttpGet(url) end)
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

-- ═══════════ 启动 ═══════════
local okLoader, Loader = pcall(function()
	return loadstring(game:HttpGet(LOADER_URL))()
end)
if not okLoader or not Loader then
	warn("[SutureLoad] 加载器获取失败:", Loader)
	-- 加载器拿不到就直接执行 suif（保持可用）
	local fn = loadstring(game:HttpGet(SUIF_URL))
	if fn then fn() end
	return
end

Loader:Show()

Loader:AddTask("正在加载 UI 库", function()
	local g = (getgenv and getgenv()) or _G
	for _, u in ipairs(WINDUI_SRC) do
		local mod = tryLoad(u)
		if mod then
			g.WindUI = mod
			return
		end
	end
	error("WindUI 加载失败（4 个镜像均不可用）")
end)

Loader:AddTask("正在加载 Suture Hub", function()
	local okSrc, src = pcall(function() return game:HttpGet(SUIF_URL) end)
	if not okSrc or type(src) ~= "string" or #src == 0 then
		error("suif 主脚本获取失败")
	end
	local fn, cerr = loadstring(src)
	if not fn then
		error(cerr)
	end
	fn()
end)

Loader:Start(function()
	local g = (getgenv and getgenv()) or _G
	if g then
		g.__SUIF_READY = function()
			pcall(function() Loader:Finish() end)
		end
	end
	-- 兜底：10 秒后无论如何淡出（防回调丢失导致加载器卡屏）
	task.delay(10, function()
		pcall(function() Loader:Finish() end)
	end)
end)

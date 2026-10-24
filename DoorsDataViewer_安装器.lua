--[[
	Doors Data Viewer 汉化版 · 安装器
	────────────────────────────────────────────────────────────
	为什么需要这个：DoorsDataViewer 是 **mspaint 的插件**，
	不是独立脚本。它第 1 行就是 `mspaint.AddonInfo = {...}`，
	直接 loadstring 运行会报：

	    attempt to index nil with 'AddonInfo'

	因为那时 mspaint 本体没加载，`mspaint` 这个全局是 nil。

	本安装器干三件事：
	  ① 打印你机器上 mspaint 的真实目录结构（探路，不靠猜）
	  ② 找到 mspaint 放插件的目录，把汉化版写进去
	  ③ 回读校验，告诉你下一步怎么让它生效

	用法：直接执行本文件。装完重载 mspaint 即可。
]]

local URLS = {
	"https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/main/DoorsDataViewer_汉化.lua",
	"https://testingcf.jsdelivr.net/gh/suif666/suif@main/DoorsDataViewer_%E6%B1%89%E5%8C%96.lua",
	"https://gcore.jsdelivr.net/gh/suif666/suif@main/DoorsDataViewer_%E6%B1%89%E5%8C%96.lua",
}

local TARGET_FILE = "DoorsDataViewer.lua"
local MIN_SIZE = 50000 -- 汉化版约 63 KB，小于这个数说明下载到的是错误页

local function out(fmt, ...)
	print("[安装器] " .. string.format(fmt, ...))
end

local function fail(fmt, ...)
	warn("[安装器] " .. string.format(fmt, ...))
end

----------------------------------------------------------------------
-- ① 环境检查
----------------------------------------------------------------------

local missing = {}
for _, name in ipairs({ "isfolder", "makefolder", "listfiles", "writefile", "readfile" }) do
	if type(_G[name]) ~= "function" then
		missing[#missing + 1] = name
	end
end
if #missing > 0 then
	fail("这个执行器缺文件系统函数：%s", table.concat(missing, ", "))
	fail("没有这些函数就没法装插件。")
	return
end

if not isfolder("mspaint") then
	fail("没找到 mspaint 文件夹。")
	fail("说明 mspaint 本体还没装好，或者还从没成功运行过一次。")
	fail("先把 mspaint 跑起来一次（它会建好自己的目录），再来执行本安装器。")
	return
end

----------------------------------------------------------------------
-- ② 打印真实目录结构（两层，够看清插件放哪）
----------------------------------------------------------------------

out("mspaint 目录结构：")

local function walk(dir, depth)
	local ok, items = pcall(listfiles, dir)
	if not ok or type(items) ~= "table" then
		return
	end
	table.sort(items)
	for _, full in ipairs(items) do
		local name = full:match("[^/\\]+$") or full
		local isDir = false
		pcall(function()
			isDir = isfolder(full)
		end)
		out("%s%s%s", string.rep("    ", depth), name, isDir and "/" or "")
		if isDir and depth < 1 then
			walk(full, depth + 1)
		end
	end
end

walk("mspaint", 0)

----------------------------------------------------------------------
-- ③ 找插件目录
----------------------------------------------------------------------

local addonDir = nil
local existingAddons = {}

local okRoot, rootItems = pcall(listfiles, "mspaint")
if okRoot and type(rootItems) == "table" then
	table.sort(rootItems)
	for _, full in ipairs(rootItems) do
		local isDir = false
		pcall(function()
			isDir = isfolder(full)
		end)
		if isDir then
			local leaf = full:match("[^/\\]+$") or ""
			-- 目录名里带 addon / plugin 的，优先
			if leaf:lower():find("addon", 1, true) or leaf:lower():find("plugin", 1, true) then
				addonDir = full
				break
			end
		end
	end
end

if addonDir then
	out("找到插件目录：%s", addonDir)
	-- 顺便看看里面已经有哪些插件，确认命名习惯
	local okList, files = pcall(listfiles, addonDir)
	if okList and type(files) == "table" then
		for _, full in ipairs(files) do
			if full:lower():sub(-4) == ".lua" then
				existingAddons[#existingAddons + 1] = full:match("[^/\\]+$") or full
			end
		end
		if #existingAddons > 0 then
			out("里面已有的插件（%d 个）：%s", #existingAddons,
				table.concat(existingAddons, ", "))
		else
			out("里面暂时没有 .lua 插件")
		end
	end
else
	addonDir = "mspaint/Addons"
	out("没找到名字带 addon 的目录，按惯例新建：%s", addonDir)
	local okMk = pcall(makefolder, addonDir)
	if not okMk then
		fail("建目录失败：%s", addonDir)
		fail("请把上面打印出来的目录结构发给我，我按你的实际布局改路径。")
		return
	end
end

local targetPath = addonDir .. "/" .. TARGET_FILE

----------------------------------------------------------------------
-- ④ 下载（多镜像）
----------------------------------------------------------------------

local source = nil
local lastErr = nil

for i, url in ipairs(URLS) do
	local ok, res = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(res) == "string" and #res >= MIN_SIZE then
		-- 内容自检：必须真的是这个插件
		if res:find("mspaint.AddonInfo", 1, true) then
			source = res
			out("下载成功（镜像 %d，%d 字节）", i, #res)
			break
		else
			lastErr = string.format("镜像 %d 内容不对（%d 字节，没有 mspaint.AddonInfo）", i, #res)
			fail("%s", lastErr)
		end
	else
		lastErr = string.format("镜像 %d 失败（%s）", i, ok and ("只有 " .. tostring(type(res) == "string" and #res or 0) .. " 字节") or tostring(res))
		fail("%s", lastErr)
	end
end

if not source then
	fail("三个镜像都没拿到文件。最后一次：%s", tostring(lastErr))
	fail("检查网络后重跑本安装器。")
	return
end

----------------------------------------------------------------------
-- ⑤ 写入并回读校验
----------------------------------------------------------------------

local okWrite, writeErr = pcall(writefile, targetPath, source)
if not okWrite then
	fail("写入失败：%s", tostring(writeErr))
	fail("目标路径：%s", targetPath)
	return
end

local okRead, back = pcall(readfile, targetPath)
if not okRead or type(back) ~= "string" then
	fail("写入后回读失败，路径：%s", targetPath)
	return
end

if #back == #source then
	out("✓ 已装好：%s（%d 字节，回读一致）", targetPath, #back)
else
	fail("回读长度不一致：写入 %d，读回 %d", #source, #back)
	fail("路径：%s", targetPath)
	return
end

----------------------------------------------------------------------
-- ⑥ 下一步
----------------------------------------------------------------------

out("──────────────────────────────────────────────")
out("接下来让它生效：")
out("  1. 在 mspaint 窗口里重新加载 / 重开 mspaint")
out("     （插件是 mspaint 启动时扫描目录加载的，改完文件必须重载）")
out("  2. 游戏内进入 DOORS 相关地图")
out("     （本插件支持的 PlaceId：6516141723 / 6839171747 / 12308344607）")
out("  3. 在 mspaint 里找「Doors 数据查看器」这个标签")
out("")
out("如果重载 mspaint 后还是看不到，把上面打印的目录结构发我，")
out("我按你机器上的实际路径改安装位置。")
out("──────────────────────────────────────────────")

-- 顺带提示：如果插件目录里已经有同名文件，说明是覆盖安装
if #existingAddons > 0 then
	for _, name in ipairs(existingAddons) do
		if name == TARGET_FILE then
			out("（这次是覆盖了旧的 %s）", TARGET_FILE)
			break
		end
	end
end

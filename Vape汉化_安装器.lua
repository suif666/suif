--[[
	Vape V4 简体中文汉化包 · 安装器
	────────────────────────────────────────────────────────────
	原理（利用 Vape 自己的缓存机制，不改任何逻辑）：

	  Vape 的 loader 里 downloadFile() 只在这个条件成立时才下载：
	      if not isfile(path) then ... 下载 ... end
	  也就是说 **本地已经有文件就永远用它**。

	  而 wipeFolder() 只删除「开头带英文水印注释」的文件：
	      --This watermark is used to delete the file if its cached...

	  仓库里的原始文件本身不带这句水印（水印是运行时拼上去的），
	  所以把汉化文件直接写进 newvape/ 下：
	      · 不会被 downloadFile 覆盖
	      · 不会被 wipeFolder 删掉
	      · Vape 更新也不动它

	代价：这些文件被固定在当前版本，上游更新后不会自动跟进。
	想恢复英文原版：执行 getgenv().VapeZH_Restore() 后重跑 Vape。

	用法：直接执行本文件，装完重新执行一次 Vape 的 loadstring。
]]

local MIRRORS = {
	'https://gh-proxy.com/https://raw.githubusercontent.com/suif666/suif/main/vape%E6%B1%89%E5%8C%96/',
	'https://gcore.jsdelivr.net/gh/suif666/suif@main/vape%E6%B1%89%E5%8C%96/',
	'https://testingcf.jsdelivr.net/gh/suif666/suif@main/vape%E6%B1%89%E5%8C%96/',
}

-- 扁平文件名 → { 目标路径, 期望字节数 }
local FILES = {
	['guis_new.lua']              = { path = 'newvape/guis/new.lua',              size = 249680 },
	['guis_old.lua']              = { path = 'newvape/guis/old.lua',              size = 142857 },
	['guis_liquidbounce.lua']     = { path = 'newvape/guis/liquidbounce.lua',     size = 93198 },

	['games_universal.lua']       = { path = 'newvape/games/universal.lua',       size = 273320 },
	['games_6872274481.lua']      = { path = 'newvape/games/6872274481.lua',      size = 257751 },
	['games_155615604.lua']       = { path = 'newvape/games/155615604.lua',       size = 107446 },
	['games_606849621.lua']       = { path = 'newvape/games/606849621.lua',       size = 76109 },
	['games_72169370437173.lua']  = { path = 'newvape/games/72169370437173.lua',  size = 58253 },
	['games_8768229691.lua']      = { path = 'newvape/games/8768229691.lua',      size = 51243 },
	['games_5938036553.lua']      = { path = 'newvape/games/5938036553.lua',      size = 47943 },
	['games_115875349872417.lua'] = { path = 'newvape/games/115875349872417.lua', size = 41551 },
	['games_139566161526375.lua'] = { path = 'newvape/games/139566161526375.lua', size = 31925 },
	['games_132768098780837.lua'] = { path = 'newvape/games/132768098780837.lua', size = 30255 },
	['games_77790193039862.lua']  = { path = 'newvape/games/77790193039862.lua',  size = 28213 },
	['games_16483433878.lua']     = { path = 'newvape/games/16483433878.lua',     size = 18764 },
	['games_893973440.lua']       = { path = 'newvape/games/893973440.lua',       size = 12175 },
	['games_6872265039.lua']      = { path = 'newvape/games/6872265039.lua',      size = 4230 },
}

local function out(...)
	print('[Vape汉化] ' .. table.concat({ ... }, ' '))
end
local function err(...)
	warn('[Vape汉化] ' .. table.concat({ ... }, ' '))
end

----------------------------------------------------------------------
-- 环境检查
----------------------------------------------------------------------
for _, n in ipairs({ 'isfile', 'isfolder', 'makefolder', 'writefile', 'readfile' }) do
	if type(_G[n]) ~= 'function' then
		err('执行器缺少 ' .. n .. '，装不了')
		return
	end
end

for _, dir in ipairs({ 'newvape', 'newvape/guis', 'newvape/games', 'newvape/profiles' }) do
	if not isfolder(dir) then
		pcall(makefolder, dir)
	end
end
if not isfolder('newvape') then
	err('建不了 newvape 目录 —— 先成功跑一次 Vape 本体，再来装汉化')
	return
end

----------------------------------------------------------------------
-- 下载 + 校验 + 写入
----------------------------------------------------------------------
-- 字节数允许 ±4% 浮动（CDN / 换行处理可能带来细微差异）
local function sizeOK(got, want)
	return got == want or (got >= want * 0.96 and got <= want * 1.04)
end

local okCount, failCount = 0, 0
local failList = {}

for flat, info in pairs(FILES) do
	local body
	for _, base in ipairs(MIRRORS) do
		local ok, res = pcall(function()
			return game:HttpGet(base .. flat, true)
		end)
		if ok and type(res) == 'string' and sizeOK(#res, info.size) then
			body = res
			break
		end
	end

	if not body then
		failCount = failCount + 1
		failList[#failList + 1] = flat .. ' 下载失败或长度不符（期望约 ' .. info.size .. ' 字节）'
	else
		local okW, eW = pcall(writefile, info.path, body)
		if not okW then
			failCount = failCount + 1
			failList[#failList + 1] = flat .. ' 写入失败：' .. tostring(eW)
		else
			local okR, back = pcall(readfile, info.path)
			if okR and type(back) == 'string' and #back == #body then
				okCount = okCount + 1
				out('OK  ' .. info.path .. '  ' .. #back .. ' B')
			else
				failCount = failCount + 1
				failList[#failList + 1] = flat .. ' 回读不一致'
			end
		end
	end
end

----------------------------------------------------------------------
-- 结果
----------------------------------------------------------------------
out('──────────────────────────────────')
out(('装好 %d 个，失败 %d 个'):format(okCount, failCount))
for _, f in ipairs(failList) do
	err('  ' .. f)
end

if okCount > 0 then
	out('下一步：重新执行一次 Vape 的 loadstring，界面就是中文了')
	out('  loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()')
end
out('想恢复英文原版：getgenv().VapeZH_Restore() 然后重跑 Vape')

getgenv().VapeZH_Restore = function()
	local n = 0
	for _, info in pairs(FILES) do
		if pcall(delfile, info.path) then
			n = n + 1
		end
	end
	print(('[Vape汉化] 已删除 %d 个汉化文件，重跑 Vape 会自动下载英文原版'):format(n))
end

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/suif666/suif/main/vapebuild/zh3/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local assetVer = '1'
	-- 汉化版自托管：版本号固定；改这个值会触发一次缓存清空重下
	local commit = 'zh3'

	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		-- 清掉早期汉化补丁写入的文件（它们不带水印，wipeFolder 删不掉）
		pcall(delfile, 'newvape/main.lua')
		pcall(delfile, 'newvape/guis/new.lua')
		pcall(delfile, 'newvape/guis/old.lua')
		pcall(delfile, 'newvape/guis/liquidbounce.lua')
		pcall(delfile, 'newvape/games/universal.lua')
		pcall(delfile, 'newvape/games/6872274481.lua')
		pcall(delfile, 'newvape/games/155615604.lua')
		pcall(delfile, 'newvape/games/606849621.lua')
		pcall(delfile, 'newvape/games/72169370437173.lua')
		pcall(delfile, 'newvape/games/5938036553.lua')
		pcall(delfile, 'newvape/games/8768229691.lua')
		pcall(delfile, 'newvape/games/139566161526375.lua')
		pcall(delfile, 'newvape/games/77790193039862.lua')
		pcall(delfile, 'newvape/games/115875349872417.lua')
		pcall(delfile, 'newvape/games/16483433878.lua')
		pcall(delfile, 'newvape/games/132768098780837.lua')
		pcall(delfile, 'newvape/games/893973440.lua')
		pcall(delfile, 'newvape/games/6872265039.lua')
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end

	if (isfile('newvape/profiles/asset.txt') and readfile('newvape/profiles/asset.txt') or '') ~= assetVer then
		wipeFolder('newvape/assets')
	end

	writefile('newvape/profiles/asset.txt', assetVer)
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
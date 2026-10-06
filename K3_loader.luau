-- AbysallCN loader: load dict from local file, then run the ASCII core
local path = "abycn/dict.luau"
local ok, src = pcall(readfile, path)
if not ok then error("[CN] cannot read " .. path, 0) end
local fn, err = loadstring(src, "=dict")
if not fn then error("[CN] dict compile failed: " .. tostring(err), 0) end
getgenv().AbysallCN_Dict = fn()
local ok2, core = pcall(readfile, "abycn/core.luau")
if not ok2 then error("[CN] cannot read core", 0) end
loadstring(core, "=core")()

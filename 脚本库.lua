-- ══════════════════════════════════════════════════════════════════════════════
-- 【脚本库】远程脚本（从主脚本打包出来）
-- 41 个游戏页签 + 全部游戏脚本按钮 / 远程挂载
-- 依赖由主脚本通过 getgenv 注入：
--   __SUIF_SCRIPT_SEC  脚本类分组（win:Section）
--   __SUIF_RUN         运行函数 run(url, name)
--   __SUIF_LAZYLOAD    lazyLoad(url, name, tab, onDemand)
--   __SUIF_NOTIFY      notify(title, content, icon, duration)
-- ══════════════════════════════════════════════════════════════════════════════
local _G = getgenv and getgenv() or _G
local scriptSec = _G.__SUIF_SCRIPT_SEC
local run = _G.__SUIF_RUN
local lazyLoad = _G.__SUIF_LAZYLOAD
local notify = _G.__SUIF_NOTIFY

if not scriptSec then
    warn("[脚本库] 缺少 scriptSec 注入，无法挂载")
    return
end
if not run then
    warn("[脚本库] 缺少 run 注入，脚本按钮将不可用")
    run = function(url, name) end
end
if not lazyLoad then
    lazyLoad = function() end
end
if not notify then
    notify = function() end
end

-- ═══ 页签声明（41 个）═══
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

-- ═══ 反查主脚本已注册的页签（这些 Tab 在主脚本里创建，远程脚本里取引用）═══
local _T = _G.Tabs or {}
local FwTab = _T.RangeTab
local SfTab = _T.FlingTPTab
local pingfpsTab = _T.PingFPSTab
local radarTab = _T.RadarTab
local playerTab = _T.PlayerTab
local amTab = _T.AimbotTab
local sayTab = _T.SayTab
local espTab = _T.ESPTab
local serverTab = _T.ServerTab
local coordTab = _T.CoordTPTab

-- ═══ 脚本库控件 ═══
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

lazyLoad("https://raw.githubusercontent.com/suif666/suif/refs/heads/main/%E8%8C%83%E5%9B%B4.lua", "范围", FwTab)

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

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E9%9B%B7%E8%BE%BE%E7%A4%BA%E4%BE%8B.lua", "雷达", radarTab)

--玩家类远程
getgenv().Tabs.PlayerTab = playerTab
getgenv().SuturePlayerTab = playerTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E7%8E%A9%E5%AE%B6%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", "玩家类", playerTab)

--自瞄类远程
getgenv().Tabs.AimbotTab = amTab
getgenv().SutureAimbotTab = amTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E7%9E%84%E7%B1%BB%E8%BF%9C%E7%A8%8B.lua", "自瞄类", amTab)

--发言类远程
getgenv().Tabs.SayTab = sayTab
getgenv().SutureSayTab = sayTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E8%87%AA%E5%8A%A8%E5%8F%91%E8%A8%80%E7%A4%BA%E4%BE%8B.lua", "发言类", sayTab)

--ESP远程
getgenv().Tabs.ESPTab = espTab
getgenv().SutureESPTab = espTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/esp%E7%A4%BA%E4%BE%8B.lua", "ESP", espTab)

--服务器类远程
getgenv().Tabs.ServerTab = serverTab
getgenv().SutureServerTab = serverTab

lazyLoad("https://raw.githubusercontent.com/suif666/testing/refs/heads/main/%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%A4%BA%E4%BE%8B.lua", "服务器类", serverTab)

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

_G.__SUIF_SCRIPTLIB_DONE = true

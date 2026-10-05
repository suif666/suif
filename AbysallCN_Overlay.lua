--[[
═══════════════════════════════════════════════════════════════════════════
  Abysall Hub 中文覆盖层  (运行时汉化)
═══════════════════════════════════════════════════════════════════════════

  原理：不改原脚本一个字。
        从【官方源】加载原版 → 保护的完整性校验不会触发 → 作者照样拿到流量
        然后在运行时把「显示出来的文字」换成中文。

  三条路线各管一块：
    ① 钩 Abysall.ESPLibrary.AddESP   → ESP 文字（不论远程库用 Drawing 还是 GUI 画）
    ② 遍历 PlayerGui / CoreGui       → 界面、通知、掉落物计数
    ③ 钩 Drawing.new                 → Creak 攻击性条那种 Drawing 画的东西

  用法：
      loadstring(game:HttpGet("<这个文件的地址>"))()

  关闭汉化：getgenv().AbysallCN.Off()
  随时手动翻：getgenv().AbysallCN.Fix()
═══════════════════════════════════════════════════════════════════════════
]]

local OFFICIAL_URL = "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/Games/Doors/Main.luau"

local ZH = {
    [" seconds."] = " 秒。",
    ["' has spawned."] = "' 出现了。",
    ["' studs away from you."] = " studs。",
    ["' to toggle the UI."] = "' 开关界面。",
    ["..."] = "...",
    ["18+ Bottles"] = "18+ 瓶子",
    ["A-120"] = "A-120",
    ["A-60"] = "A-60",
    ["AR0xMBUSH"] = "AR0xMBUSH",
    ["Abysall Hub"] = "Abysall Hub",
    ["Aggression "] = "攻击性 ",
    ["Aggression --%"] = "攻击性 --%",
    ["Alarm Clock"] = "闹钟",
    ["Allows certain items to be used without draining their uses."] = "让某些物品使用时不消耗次数。",
    ["Allows you to freely fly around the map."] = "让你可以自由在地图上飞行。",
    ["Allows you to interact with prompts through walls."] = "让你可以隔墙交互。",
    ["Allows you to jump while in the air."] = "让你可以在空中跳跃。",
    ["Allows you to open doors from further away."] = "让你从更远处开门。",
    ["Allows you to trigger all prompts instantly."] = "让你瞬间触发所有交互提示。",
    ["Allows your character to jump."] = "让你的角色可以跳跃。",
    ["Allows your character to pass through solid objects."] = "让角色可以穿过固体物体。",
    ["Allows your character to slide."] = "让你的角色可以滑行。",
    ["Aloe Vera"] = "芦荟",
    ["Ambient"] = "环境光",
    ["Anchor ["] = "锚点 [",
    ["Anti Closet Trash"] = "防衣柜垃圾",
    ["Anti Noise"] = "防噪音",
    ["Anti Ransom"] = "防 Ransom",
    ["Anticheat Bypass"] = "反作弊绕过",
    ["Arrow Radius"] = "箭头范围",
    ["Attempting to complete the valves."] = "正在尝试完成阀门。",
    ["Attempting to solve the breaker box."] = "正在尝试解配电箱。",
    ["Attempts to guess the library code, but collecting some books is also necessary."] = "尝试猜出图书馆密码，但仍需要收集一些书。",
    ["Auto Breaker Box"] = "自动配电箱",
    ["Auto Breaker Room"] = "自动配电室",
    ["Auto Closet"] = "自动躲衣柜",
    ["Auto Complete Cringle"] = "自动完成 Cringle",
    ["Auto Complete Dam Seek"] = "自动完成大坝 Seek",
    ["Auto Heartbeat Minigame"] = "自动心跳小游戏",
    ["Auto Hotel"] = "自动酒店",
    ["Auto Interact"] = "自动交互",
    ["Auto Library"] = "自动图书馆",
    ["Auto Rooms"] = "自动过房间",
    ["Auto Solve Anchors"] = "自动解锚点",
    ["Auto Steer Minecart"] = "自动开矿车",
    ["Auto Tp Next Door"] = "自动传送下一道门",
    ["Auto Unlock Padlock"] = "自动解锁挂锁",
    ["Automatically Skippes Forget Me Not doors."] = "自动跳过 Forget Me Not 的门。",
    ["Automatically brings dropped items at the selected interval."] = "按设定的间隔自动把掉落物品捡回来。",
    ["Automatically completes the breaker sequence in Hotel Room 100."] = "自动完成酒店 100 号房间的配电序列。",
    ["Automatically completes the minecart chase."] = "自动完成矿车追逐。",
    ["Automatically enters the code into the library padlock."] = "自动把密码输入图书馆挂锁。",
    ["Automatically enters the correct code into anchors when you are near them."] = "靠近锚点时自动输入正确密码。",
    ["Automatically farms deaths, joining new runs."] = "自动刷死亡，不断开新局。",
    ["Automatically gains knobs for you, dies and revives repeatedly."] = "自动帮你刷旋钮，反复死亡和复活。",
    ["Automatically gets books and paper."] = "自动收集书和纸。",
    ["Automatically hides in a nearby closet when an entity is near."] = "附近有实体时自动躲进旁边的衣柜。",
    ["Automatically moves and hides from entities in The Rooms."] = "在 The Rooms 自动移动并躲避实体。",
    ["Automatically progresses through the hotel floor."] = "自动推进酒店楼层。",
    ["Automatically revives after dying, with unlimited respawns."] = "死亡后自动复活，次数无限。",
    ["Automatically solves the breaker box."] = "自动解开配电箱。",
    ["Automatically solves the code for the library padlock."] = "自动解开图书馆挂锁的密码。",
    ["Automatically teleports to and interacts with each water pump."] = "自动传送到每个水泵并与之交互。",
    ["Automatically triggers nearby prompts."] = "自动触发附近的交互提示。",
    ["Avoid looking at it."] = "别盯着它看。",
    ["Avoid looking at its eyes."] = "别盯着它的眼睛看。",
    ["Avoid stepping on the grass."] = "别踩到草。",
    ["Avoid touching him."] = "别碰到他。",
    ["Ball"] = "球",
    ["Balls"] = "球",
    ["Balls."] = "球。",
    ["Bandage"] = "绷带",
    ["Bandage Pack"] = "绷带包",
    ["Bash"] = "Bash",
    ["Battery"] = "电池",
    ["Battery Pack"] = "电池组",
    ["Bed"] = "床",
    ["Big Bomb"] = "大炸弹",
    ["Big Shield Potion"] = "大护盾药水",
    ["Blitz"] = "Blitz",
    ["Bomb"] = "炸弹",
    ["BoxDeposit"] = "箱子投放点",
    ["Boxing Gloves"] = "拳击手套",
    ["Bramble"] = "Bramble",
    ["Bread"] = "面包",
    ["Breaks the tv of noise while holding it."] = "拿着噪音电视时把它弄坏。",
    ["Bring Dropped Items"] = "拾回掉落物品",
    ["Brings all dropped items."] = "把所有掉落的物品捡回来。",
    ["Broken Monitor"] = "破损显示器",
    ["Bug Out Creak (Requires ≥5 Cart)"] = "卡出 Creak（需要 ≥5 辆推车）",
    ["Bypass / Solve"] = "绕过 / 解谜",
    ["Bypass Alma"] = "绕过 Alma",
    ["Bypass Banana"] = "绕过香蕉皮",
    ["Bypass Drones"] = "绕过 Drones",
    ["Bypass Dupe"] = "绕过 Dupe",
    ["Bypass Electric Water"] = "绕过电水",
    ["Bypass Eyes"] = "绕过 Eyes",
    ["Bypass Giggle"] = "绕过 Giggle",
    ["Bypass Gloombat Eggs"] = "绕过 Gloombat 卵",
    ["Bypass Jeff"] = "绕过 Jeff",
    ["Bypass Killbricks"] = "绕过秒杀砖",
    ["Bypass Lookman"] = "绕过 Lookman",
    ["Bypass Scribbles"] = "绕过 Scribbles",
    ["Bypass Seek Obstructions"] = "绕过 Seek 障碍",
    ["Bypass Seeking Wall"] = "绕过 Seek 墙",
    ["Bypass Snare"] = "绕过 Snare",
    ["Bypass Vacuum"] = "绕过 Vacuum",
    ["CD Disc"] = "CD 光盘",
    ["Camera / Effects"] = "镜头 / 效果",
    ["Candle"] = "蜡烛",
    ["Candy"] = "糖果",
    ["Cellar"] = "地窖",
    ["Certain notifications will stay on screen until they are no longer needed."] = "某些通知会一直留在屏幕上，直到不再需要。",
    ["Changes the lighting color to the specified value."] = "把环境光改成指定的颜色。",
    ["Changes the offset of your viewmodel while holding an item."] = "改变手持物品时手部模型的偏移。",
    ["Cheese"] = "奶酪",
    ["Chest"] = "箱子",
    ["Chests"] = "箱子",
    ["Click 'Start Knob Farm' when you're ready."] = "准备好后点「开始刷旋钮」。",
    ["Closet"] = "衣柜",
    ["Combine with orbit, or bring all dropped items."] = "配合绕物旋转使用，或直接用拾回全部掉落物。",
    ["Compass"] = "指南针",
    ["Compatability Warning"] = "兼容性警告",
    ["Compatability/Risk Warning"] = "兼容性 / 风险警告",
    ["Completely disables the anticheat, after interacting with a ladder."] = "与梯子交互后彻底禁用反作弊。",
    ["Completely removes the entity 'Figure' (doesn't always work)."] = "彻底移除实体 'Figure'（不总是有效）。",
    ["Continues to walk if entity 'A-60' is present, enables position spoof automatically."] = "'A-60' 出现时继续前进，并自动开启位置欺骗。",
    ["Continuously teleports you to the next sequential unopened door."] = "持续把你传送到下一道还没开的门。",
    ["Copies the death farm loadstring to your clipboard."] = "把死亡刷取脚本复制到剪贴板。",
    ["Copy Death Farm Loadstring"] = "复制死亡刷取脚本",
    ["Correct Box"] = "正确的箱子",
    ["Correct Box ("] = "正确的箱子 (",
    ["Correct Box ESP/Auto Interact"] = "正确箱子 ESP / 自动交互",
    ["Creak"] = "Creak",
    ["Creak Aggression Meter"] = "Creak 攻击性条",
    ["Crouch Distance"] = "蹲下距离",
    ["Crouch Spoof"] = "蹲下欺骗",
    ["Crucifix"] = "十字架",
    ["Currency"] = "货币",
    ["Custom Entity"] = "自定义实体",
    ["Custom FOV"] = "自定义视野",
    ["Custom Fov"] = "自定义视野",
    ["Death"] = "死亡",
    ["Delete Crushers"] = "删除压碎机",
    ["Delete Figure"] = "删除 Figure",
    ["Delete Seek Trigger"] = "删除 Seek 触发器",
    ["Deposit ("] = "投放点 (",
    ["Diables the 'Seek' chase trigger."] = "禁用 'Seek' 追逐触发器。",
    ["Died to Abysall Hub"] = "死于 Abysall Hub",
    ["Died to Verity"] = "死于 Verity",
    ["Disable Crushers"] = "禁用压碎机",
    ["Disable Entity Jumpscares"] = "禁用实体跳吓",
    ["Disable Firedamp Effect"] = "禁用瓦斯效果",
    ["Disable Glitch Jumpscare"] = "禁用 Glitch 跳吓",
    ["Disable Hide Vignette"] = "禁用躲藏暗角",
    ["Disable Idle Kick"] = "禁用挂机踢出",
    ["Disable Timothy Jumpscare"] = "禁用 Timothy 跳吓",
    ["Disable Void Jumpscare"] = "禁用 Void 跳吓",
    ["Disables jumpscares from entities like Rush and Ambush."] = "禁用 Rush、Ambush 这类实体的跳吓。",
    ["Disables the firedamp screen effect."] = "禁用瓦斯的画面效果。",
    ["Disables the hiding screen effect."] = "禁用躲藏时的画面效果。",
    ["Disables the jumpscare from 'Glitch'"] = "禁用 'Glitch' 的跳吓",
    ["Disables the jumpscare from 'Timothy'"] = "禁用 'Timothy' 的跳吓",
    ["Disables the jumpscare from 'Void'"] = "禁用 'Void' 的跳吓",
    ["Distance"] = "距离",
    ["Dont get near it"] = "别靠近它。",
    ["Dont let it touch you."] = "别让它碰到你。",
    ["Dont touch him."] = "别碰他。",
    ["Dont worry, hes only annoying."] = "别担心，他只是烦人。",
    ["Donut"] = "甜甜圈",
    ["Door "] = "门 ",
    ["Door Key"] = "门钥匙",
    ["Door Reach"] = "开门距离",
    ["Doors"] = "门",
    ["Double Bed"] = "双人床",
    ["Drakobloxxer"] = "Drakobloxxer",
    ["Draws a line to highlighted objects."] = "向被高亮的物体画一条线。",
    ["Dumpster"] = "垃圾箱",
    ["Dupe"] = "Dupe",
    ["ESP correct Archives boxes in the Honcho sequence and automatically interact with the correct deposit."] = "在 Honcho 流程中高亮档案室的正确箱子，并自动与正确的投放点交互。",
    ["ESP/Settings"] = "ESP / 设置",
    ["ESPs the Archives Correct Boxes."] = "高亮档案室的正确箱子。",
    ["Electrical Key"] = "电力钥匙",
    ["Enable Arrows"] = "启用箭头",
    ["Enable Interval"] = "启用间隔",
    ["Enable Jumping"] = "启用跳跃",
    ["Enable Sliding"] = "启用滑行",
    ["Enable Speed Boost"] = "启用加速",
    ["Enable Tracers"] = "启用追踪线",
    ["Entities"] = "实体",
    ["Entities / Settings"] = "实体 / 设置",
    ["Entity 'A-120' has spawned."] = "实体 'A-120' 出现了。",
    ["Entity 'A-60' has spawned."] = "实体 'A-60' 出现了。",
    ["Entity 'AR0xMBUSH' has spawned."] = "实体 'AR0xMBUSH' 出现了。",
    ["Entity 'Ambush' has spawned."] = "实体 'Ambush' 出现了。",
    ["Entity 'Bash' has spawned."] = "实体 'Bash' 出现了。",
    ["Entity 'Blitz' has spawned."] = "实体 'Blitz' 出现了。",
    ["Entity 'Creak' has spawned."] = "实体 'Creak' 出现了。",
    ["Entity 'Custom Entity' has spawned."] = "实体 '自定义实体' 出现了。",
    ["Entity 'Drones Stampede' has spawned."] = "实体 'Drones 踩踏' 出现了。",
    ["Entity 'Eyes' has spawned."] = "实体 'Eyes' 出现了。",
    ["Entity 'Frozen Ambush' has spawned."] = "实体 'Frozen Ambush' 出现了。",
    ["Entity 'Gloombat Swarm' has spawned."] = "实体 'Gloombat 群' 出现了。",
    ["Entity 'Groundskeeper' has spawned."] = "实体 '园丁' 出现了。",
    ["Entity 'Halt' will spawn in the next room."] = "实体 'Halt' 将在下一个房间出现。",
    ["Entity 'Jeff the Killer' has spawned."] = "实体 'Jeff the Killer' 出现了。",
    ["Entity 'Lookman' has spawned."] = "实体 'Lookman' 出现了。",
    ["Entity 'Monument' has spawned."] = "实体 'Monument' 出现了。",
    ["Entity 'Noise' has spawned."] = "实体 'Noise' 出现了。",
    ["Entity 'RNIUSHCG==' has spawned."] = "实体 'RNIUSHCG==' 出现了。",
    ["Entity 'Rush' has spawned."] = "实体 'Rush' 出现了。",
    ["Entity 'Sally' has spawned."] = "实体 'Sally' 出现了。",
    ["Entity 'Scribbles' has spawned."] = "实体 'Scribbles' 出现了。",
    ["Entity 'Teller' has spawned."] = "实体 'Teller' 出现了。",
    ["Entity List"] = "实体列表",
    ["Exit Closet"] = "退出衣柜",
    ["Exits the current closet."] = "从当前衣柜里出来。",
    ["Exploits / Anti"] = "作弊 / 防护",
    ["Eyes"] = "Eyes",
    ["Eyestalk Path"] = "Eyestalk 路径",
    ["Fade Time"] = "淡出时长",
    ["Features highlighted in red are risky / dont work in the current floor."] = "标红的功能有风险，或在当前楼层不可用。",
    ["Features highlighted in red are risky."] = "标红的功能有风险。",
    ["Features highlighted in red do not work in the current floor."] = "红色的功能在当前楼层不可用。",
    ["Field of View"] = "视野",
    ["Figure"] = "Figure",
    ["Figure Godmode"] = "Figure 无敌",
    ["Fih Food"] = "Fih 食物",
    ["Fih Tank"] = "鱼缸",
    ["Fill Transparency"] = "填充透明度",
    ["Find a hiding spot."] = "找个地方躲起来。",
    ["Find her horse and rop it."] = "找到她的马并套住它。",
    ["Fire Alarm"] = "火警",
    ["Fish Tank"] = "鱼缸",
    ["Flashlight"] = "手电筒",
    ["Fly"] = "飞行",
    ["Fly Speed"] = "飞行速度",
    ["Forget Me Not Skipper"] = "跳过 Forget Me Not",
    ["Frozen Ambush"] = "冰封 Ambush",
    ["Fuse Breaker"] = "保险丝断路器",
    ["Garage Door"] = "车库门",
    ["Gate Button"] = "大门按钮",
    ["Gate Lever"] = "大门拉杆",
    ["Generator"] = "发电机",
    ["Generator Fuse"] = "发电机保险丝",
    ["Get Current Floor"] = "获取当前楼层",
    ["Get Current Room"] = "获取当前房间",
    ["Giggle"] = "Giggle",
    ["Glitch Fragment"] = "故障碎片",
    ["Gloombat Eggs"] = "Gloombat 卵",
    ["Gloombat Swarm"] = "Gloombat 群",
    ["Glowstick"] = "荧光棒",
    ["Gold Pile ["] = "金币堆 [",
    ["Golden Gun"] = "黄金枪",
    ["Green Herb"] = "绿色草药",
    ["Groundskeeper"] = "园丁",
    ["Grumble"] = "Grumble",
    ["Guess Library Code"] = "猜图书馆密码",
    ["Gummy Flashlight"] = "软糖手电筒",
    ["Gween Soda"] = "Gween 汽水",
    ["Gween Soda Pack"] = "Gween 汽水包",
    ["Halt"] = "Halt",
    ["Hat"] = "帽子",
    ["Height"] = "高度",
    ["Hello again streamer...."] = "又见面了，主播....",
    ["Hiding Box"] = "躲藏箱",
    ["Hiding Spot"] = "躲藏点",
    ["Hiding Spots"] = "躲藏点",
    ["Hiding_Spot"] = "躲藏点",
    ["Highlights all collectable items/consumables."] = "高亮所有可拾取物品/消耗品。",
    ["Highlights all currency that spawns."] = "高亮所有出现的货币。",
    ["Highlights all entities that spawn."] = "高亮所有出现的实体。",
    ["Highlights all objects required to progress."] = "高亮所有推进流程必需的物体。",
    ["Highlights ladders that can be used to disable the anticheat."] = "高亮可以用来禁用反作弊的梯子。",
    ["Highlights miscellaneous objects that can be used to disable the anticheat."] = "高亮各种可以用来禁用反作弊的杂物。",
    ["Highlights objects that can contain loot."] = "高亮可能装有战利品的物体。",
    ["Highlights other players."] = "高亮其他玩家。",
    ["Highlights places where you can hide from entities"] = "高亮可以躲开实体的地方",
    ["Highlights the next door."] = "高亮下一道门。",
    ["Hint Book"] = "提示书",
    ["Hint Paper"] = "提示纸",
    ["Holy Hand Grenade"] = "神圣手雷",
    ["Honcho Correct Box ESP"] = "Honcho 正确箱子 ESP",
    ["Honey Pot"] = "蜂蜜罐",
    ["How often dropped items are brought."] = "多久把掉落物品捡回来一次。",
    ["Ignore A-60"] = "无视 A-60",
    ["Ignore Entities"] = "忽略实体",
    ["Ignore List"] = "忽略列表",
    ["Increases your walkspeed by the specified amount."] = "按设定值提高你的行走速度。",
    ["Infinite Crucifix"] = "无限十字架",
    ["Infinite Items"] = "无限物品",
    ["Infinite Jumps"] = "无限跳跃",
    ["Infinite Revives"] = "无限复活",
    ["Instant Prompts"] = "瞬间交互",
    ["Instantly completes the quest."] = "立刻完成任务。",
    ["Interact with a ladder to disable it again."] = "再和梯子交互一次即可再次禁用它。",
    ["Interact with the breaker box."] = "去和配电箱交互。",
    ["Interval"] = "间隔",
    ["Iron Key"] = "铁钥匙",
    ["It can't move while you are looking at it."] = "你看着它的时候它不能动。",
    ["It is '"] = "距离你 ",
    ["It will be automatically solved."] = "它会被自动解开。",
    ["It will be re-enabled after a cutscene or halt room."] = "过场动画或 Halt 房间之后它会重新启用。",
    ["Item '"] = "物品 '",
    ["Item List"] = "物品列表",
    ["Item Number"] = "物品数量",
    ["Items"] = "物品",
    ["Items: "] = "物品: ",
    ["Items: 0"] = "物品: 0",
    ["Jeff the Killer"] = "Jeff the Killer",
    ["Jerry Can"] = "油桶",
    ["Keep Notifications"] = "常驻通知",
    ["Keep all light sources turned off."] = "把所有光源都关掉。",
    ["Kill All (Requires ≥1 Cart)"] = "全部击杀（需要 ≥1 辆推车）",
    ["Kills your character on the server. (takes around 20 seconds if replicatesignal isn't supported)"] = "在服务器上杀死你的角色。（若不支持 replicatesignal 约需 20 秒）",
    ["Knob Farm"] = "旋钮刷取",
    ["Knockbomb"] = "击退炸弹",
    ["Ladder"] = "梯子",
    ["Ladder Softlock Fix"] = "梯子卡死修复",
    ["Ladder Softlock Fix."] = "梯子卡死修复。",
    ["Ladders"] = "梯子",
    ["Lamp"] = "台灯",
    ["Lantern"] = "提灯",
    ["Laser Pointer"] = "激光笔",
    ["Lighter"] = "打火机",
    ["Line Thickness"] = "线条粗细",
    ["Line Transparency"] = "线条透明度",
    ["Loadstring has been copied to your clipboard."] = "脚本已复制到剪贴板。",
    ["Locked Chest"] = "上锁的箱子",
    ["Locked Item Locker"] = "上锁的物品柜",
    ["Locked Toolbox"] = "上锁的工具箱",
    ["Locker"] = "储物柜",
    ["Lockpicks"] = "撬锁工具",
    ["Lookman"] = "Lookman",
    ["Lotus"] = "莲花",
    ["Lotus Petal"] = "莲花瓣",
    ["Lunch Box"] = "午餐盒",
    ["Makes a hiding spot transparent when you enter it."] = "进入躲藏点后让它变透明。",
    ["Makes it appear as if your character is walking normally."] = "让你的角色看起来像在正常走路。",
    ["Makes notifications play an alert sound."] = "让通知播放提示音。",
    ["Makes the esp objects change colour like a rainbow."] = "让 ESP 物体的颜色像彩虹一样变化。",
    ["Makes the game think you are always crouching."] = "让游戏以为你一直处于蹲下状态。",
    ["Makes you join a new run, click again to cancel."] = "让你加入新一局，再点一次取消。",
    ["Makes you revive, if you have a revive and haven't already revived in this run."] = "如果你有复活且本局还没用过，就自动复活。",
    ["Makes you teleport back to the lobby."] = "把你传送回大厅。",
    ["Makes your character appear underground on the server, protecting you from rush-like entities."] = "让角色在服务器看来位于地下，从而免受 Rush 类实体伤害。",
    ["Mandrake Hole"] = "曼德拉草洞",
    ["Manipulation Method"] = "操控方式",
    ["Message"] = "消息",
    ["Mini Shield Potion"] = "小护盾药水",
    ["Mirror"] = "镜子",
    ["Misc"] = "杂项",
    ["Moonlight Candle"] = "月光蜡烛",
    ["Moonlight Smoothie"] = "月光冰沙",
    ["Mouse"] = "老鼠",
    ["Moves your character forward slowly, mitigating the game's anti-noclip."] = "让角色缓慢前移，以规避游戏的反穿墙检测。",
    ["Multitool"] = "多功能工具",
    ["Nanner"] = "香蕉",
    ["No A-90 Damage"] = "A-90 无伤害",
    ["No Halt Damage"] = "Halt 无伤害",
    ["No Screech Damage"] = "Screech 无伤害",
    ["No Surge Damage"] = "Surge 无伤害",
    ["Noclip"] = "穿墙",
    ["Node Transparency"] = "节点透明度",
    ["Noise Tv Breaker"] = "噪音电视断路器",
    ["Noise tv spawned."] = "噪音电视出现了。",
    ["Noise_TV"] = "噪音电视",
    ["Notify Chat"] = "聊天栏通知",
    ["Notify Entities"] = "实体通知",
    ["Notify Haste Time"] = "Haste 倒计时通知",
    ["Notify Items"] = "物品通知",
    ["Notify Library Code"] = "图书馆密码通知",
    ["Notify Oxygen Level"] = "氧气量通知",
    ["Notify Style"] = "通知样式",
    ["Objectives"] = "任务目标",
    ["Only applies the Field of View slider when enabled."] = "只在开启时才应用视野滑块的值。",
    ["Orbit Dropped Items"] = "掉落物绕身旋转",
    ["Orbits dropped items around you. Teleports them to you every 10s to prevent despawn."] = "让掉落物绕着你转，每 10 秒传送回你身边以防消失。",
    ["Outline Transparency"] = "描边透明度",
    ["Oxygen: "] = "氧气: ",
    ["Package Deposit"] = "包裹投放点",
    ["Padlock code found!"] = "找到挂锁密码！",
    ["Paper Plane"] = "纸飞机",
    ["Path"] = "路径",
    ["Pathfind Timeout"] = "寻路超时",
    ["Pizza"] = "披萨",
    ["Play Again"] = "再来一局",
    ["Play Sound"] = "播放提示音",
    ["Players"] = "玩家",
    ["Please Enter The First ForgetMeNot Door"] = "请先进入第一道 ForgetMeNot 门",
    ["Please collect some gold to earn knobs."] = "先捡一些金币才能获得旋钮。",
    ["Please wait."] = "请稍候。",
    ["Portrait"] = "Portrait",
    ["Portrait' has spawned."] = "Portrait 出现了。",
    ["Position Spoof"] = "位置欺骗",
    ["PositionSpoof Will Break This!."] = "位置欺骗开启时这个会失效！",
    ["Present"] = "礼物",
    ["Press '"] = "按 '",
    ["Prevents 'A-90' from hurting you."] = "阻止 'A-90' 伤害你。",
    ["Prevents 'A-90' from spawning."] = "阻止 'A-90' 出现。",
    ["Prevents 'Alma' from spawning."] = "阻止 'Alma' 出现。",
    ["Prevents 'Banana Peel' from slipping you up (sometimes doesn't work)."] = "阻止 '香蕉皮' 让你滑倒（有时无效）。",
    ["Prevents 'Closet Trash' from spawning."] = "阻止 '衣柜垃圾' 出现。",
    ["Prevents 'Dread' from spawning."] = "阻止 'Dread' 出现。",
    ["Prevents 'Drones' from attacking you."] = "阻止 'Drones' 攻击你。",
    ["Prevents 'Eyes' from hurting you."] = "阻止 'Eyes' 伤害你。",
    ["Prevents 'Figure' from hurting you."] = "阻止 'Figure' 伤害你。",
    ["Prevents 'Giggle' from attacking you."] = "阻止 'Giggle' 攻击你。",
    ["Prevents 'Halt' from hurting you."] = "阻止 'Halt' 伤害你。",
    ["Prevents 'Halt' from spawning."] = "阻止 'Halt' 出现。",
    ["Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work)."] = "阻止 'Jeff the Killer' 捅你（有时无效）。",
    ["Prevents 'Lava' from hurting you."] = "阻止岩浆伤害你。",
    ["Prevents 'Lookman' from hurting you."] = "阻止 'Lookman' 伤害你。",
    ["Prevents 'Ransom' from attacking you."] = "阻止 'Ransom' 攻击你。",
    ["Prevents 'ScaryWall' from hurting you."] = "阻止 'ScaryWall' 伤害你。",
    ["Prevents 'Screech' from hurting you"] = "阻止 'Screech' 伤害你",
    ["Prevents 'Screech' from hurting you."] = "阻止 'Screech' 伤害你。",
    ["Prevents 'Screech' from spawning."] = "阻止 'Screech' 出现。",
    ["Prevents 'Scribbles' from attacking you."] = "阻止 'Scribbles' 攻击你。",
    ["Prevents 'Snare' from trapping you."] = "阻止 'Snare' 困住你。",
    ["Prevents 'Surge' from hurting you."] = "阻止 'Surge' 伤害你。",
    ["Prevents 'Surge' from spawning."] = "阻止 'Surge' 出现。",
    ["Prevents 'The Drones Stampede' from attacking you."] = "阻止 'The Drones Stampede' 攻击你。",
    ["Prevents electric water from hurting you."] = "阻止电水伤害你。",
    ["Prevents obstacles in the 'Seek' chase from harming you."] = "阻止 'Seek' 追逐中的障碍伤害你。",
    ["Prevents taking damage from stepping on 'Gloombat' eggs."] = "阻止踩到 'Gloombat' 卵时受伤。",
    ["Prevents the 'Figure' minigame from ever failing."] = "让 'Figure' 小游戏永远不会失败。",
    ["Prevents the camera from bobbing when moving."] = "阻止移动时的镜头晃动。",
    ["Prevents the camera from shaking."] = "阻止镜头抖动。",
    ["Prevents the game from making noise when moving (Visual studio auto ai lmfao ✌)."] = "阻止游戏在你移动时发出噪音（Visual studio auto ai 哈哈 ✌）。",
    ["Prevents the kick from being idle for 20 minutes."] = "防止挂机 20 分钟被踢出。",
    ["Prevents third person from going through walls."] = "阻止第三人称视角穿墙。",
    ["Prevents you from falling into 'Vacuum' fake doors."] = "阻止你掉进 'Vacuum' 的假门。",
    ["Prevents you from open 'Dupe' fake doors."] = "阻止你打开 'Dupe' 的假门。",
    ["Prevents your character from sliding while moving."] = "阻止角色移动时滑行。",
    ["Prints the current floor to the console."] = "把当前楼层打印到控制台。",
    ["Prints the current room number to the console."] = "把当前房间号打印到控制台。",
    ["Prompt Clip"] = "穿墙交互",
    ["Prompt Reach Multiplier"] = "交互距离倍率",
    ["Rainbow Effect"] = "彩虹效果",
    ["Ransom gone hehehehehehehehe"] = "Ransom 走了 哈哈哈哈哈哈哈哈",
    ["Remove A-90"] = "移除 A-90",
    ["Remove Acceleration"] = "移除加速度",
    ["Remove Basement Gate"] = "移除地下室大门",
    ["Remove Camera Bobbing"] = "移除镜头晃动",
    ["Remove Camera Shake"] = "移除镜头抖动",
    ["Remove Closet Delay"] = "移除衣柜延迟",
    ["Remove Cutscenes"] = "移除过场动画",
    ["Remove Dread"] = "移除 Dread",
    ["Remove Fog"] = "移除雾",
    ["Remove Footstep Sounds"] = "移除脚步声",
    ["Remove Halt"] = "移除 Halt",
    ["Remove Interacting Sounds"] = "移除交互音效",
    ["Remove Jammin Music"] = "移除 Jammin 音乐",
    ["Remove Meld"] = "移除 Meld",
    ["Remove Paintings Door"] = "移除画门",
    ["Remove Screech"] = "移除 Screech",
    ["Remove Skeleton Door"] = "移除骷髅门",
    ["Remove Surge"] = "移除 Surge",
    ["Removes all fog effects from the camera."] = "移除镜头上的所有雾效果。",
    ["Removes all non-necessary cutscenes."] = "移除所有非必要的过场动画。",
    ["Removes the fireplace doors from painting rooms."] = "移除画室的壁炉门。",
    ["Removes the gate from basement rooms."] = "移除地下室房间的大门。",
    ["Removes the music and muffle effect from the 'Jammin' modifier."] = "移除 'Jammin' 修正的音乐和闷音效果。",
    ["Removes the short window where you can't exit out of a closet after the animation finishes."] = "移除动画结束后那一小段无法出衣柜的时间。",
    ["Removes the skeleton door from the infirmary."] = "移除医务室的骷髅门。",
    ["Removes the sounds when interacting with proximity prompts."] = "移除与交互提示互动时的音效。",
    ["Removes the sounds when walking."] = "移除走路时的音效。",
    ["Render Limit"] = "渲染距离",
    ["Reset Character"] = "重置角色",
    ["Return to Lobby"] = "返回大厅",
    ["Revive"] = "复活",
    ["Rift Jar"] = "裂隙罐",
    ["Risk Warning"] = "风险警告",
    ["Risky! You can die or lose the Crucifix. Recommended to have low ping and stable fps."] = "有风险！你可能会死或弄丢十字架。建议低延迟且帧率稳定时使用。",
    ["Rush"] = "Rush",
    ["Sally"] = "Sally",
    ["Sally Toy"] = "Sally 玩具",
    ["Scrapper"] = "Scrapper",
    ["Screw"] = "螺丝",
    ["Scribbles"] = "Scribbles",
    ["Seek Path"] = "Seek 路径",
    ["Sends a message in the chat when an entity spawns."] = "有实体出现时在聊天栏发消息。",
    ["Sends a notification when an entity spawns."] = "有实体出现时发送通知。",
    ["Sends a notification when an item spawns."] = "有物品出现时发送通知。",
    ["Sends a test notifcation, so you can see how your settings look."] = "发一条测试通知，方便你看设置效果。",
    ["Shears"] = "剪刀",
    ["Shopping Cart"] = "购物车",
    ["Shopping Cart Target"] = "购物车目标",
    ["Show Distance"] = "显示距离",
    ["Show Entity Path"] = "显示实体路径",
    ["Show Eyestalk Path"] = "显示 Eyestalk 路径",
    ["Show Path"] = "显示路径",
    ["Show Seek Path"] = "显示 Seek 路径",
    ["Shows Creak's aggression above its head."] = "在 Creak 头顶显示它的攻击性。",
    ["Shows arrow that point to off-screen objects."] = "显示指向屏幕外物体的箭头。",
    ["Shows how far away the item is in the notification."] = "在通知里显示物品有多远。",
    ["Shows how far away your character is from the object."] = "显示角色离物体有多远。",
    ["Shows how much oxygen you have remaining."] = "显示你还剩多少氧气。",
    ["Shows how much time you have remaining before 'Haste' spawns."] = "显示距离 'Haste' 出现还剩多少时间。",
    ["Shows the Archives clock time."] = "显示档案室的时钟时间。",
    ["Shows the current path of rooms auto-walk."] = "显示自动过房间的当前路径。",
    ["Shows the number of dropped items."] = "显示掉落物品的数量。",
    ["Shows the path of entitys."] = "显示实体的移动路径。",
    ["Shows you the correct path in seek chases."] = "在 Seek 追逐中显示正确路线。",
    ["Shows you the correct path in the eyestalk chase."] = "在 Eyestalk 追逐中显示正确路线。",
    ["Skeleton Key"] = "万能钥匙",
    ["Skip Seek (Hotel)"] = "跳过 Seek（酒店）",
    ["Skip Seek (Mines)"] = "跳过 Seek（矿洞）",
    ["Skip all entity waits and pauses."] = "跳过所有实体等待和停顿。",
    ["Skips the entire Seek sections."] = "跳过整个 Seek 段落。",
    ["Smoothie"] = "冰沙",
    ["Snare"] = "Snare",
    ["Sound Volume"] = "音效音量",
    ["Spam Void In Debug If Stuck In ForgetMeNot"] = "卡在 ForgetMeNot 时用调试刷 Void",
    ["Spectate Entity"] = "观战实体",
    ["Spectates the entity while auto hiding."] = "自动躲藏时观战该实体。",
    ["Speed"] = "速度",
    ["Speed Boost"] = "加速",
    ["Spoof Footsteps"] = "伪造脚步声",
    ["Spotlight"] = "聚光灯",
    ["Stardust Pile"] = "星尘堆",
    ["Starlight Barrel"] = "星光桶",
    ["Starlight Bottle"] = "星光瓶",
    ["Starlight Vial"] = "星光小瓶",
    ["Start Death Farm"] = "开始死亡刷取",
    ["Start Knob Farm"] = "开始刷旋钮",
    ["Starts farming knobs, click this when you have enough gold."] = "开始刷旋钮，攒够金币后点这里。",
    ["Stop Sign"] = "停车标志",
    ["Stop Time/Anti Stampede"] = "停止时间/防踩踏",
    ["Straplight"] = "绑带灯",
    ["StuckPart"] = "卡位部件",
    ["Successfully completed the valves."] = "成功完成阀门。",
    ["Successfully disabled the anticheat."] = "成功禁用反作弊。",
    ["Successfully loaded in "] = "加载成功，用时 ",
    ["Successfully solved the breaker box."] = "成功解开配电箱。",
    ["TP All Drops to Nearest Grinder"] = "把所有掉落物传到最近的研磨机",
    ["TP to trash and drop trash."] = "传送到垃圾桶并丢垃圾。",
    ["Tablet"] = "平板",
    ["Teleport"] = "传送",
    ["Teleports every dropped item to the grinder closest to you"] = "把每个掉落物品传送到离你最近的研磨机",
    ["Teleports you to the next sequential unopened door."] = "把你传送到下一道还没开的门。",
    ["Teleports your character to Y -120."] = "把角色传送到 Y = -120。",
    ["Teller"] = "Teller",
    ["Test Notification"] = "测试通知",
    ["Text Font"] = "字体",
    ["Text Outline Transparency"] = "文字描边透明度",
    ["Text Size"] = "字号",
    ["Text Transparency"] = "文字透明度",
    ["The anticheat has been re-enabled."] = "反作弊已重新启用。",
    ["The code is: '"] = "密码是: '",
    ["The distance of the orbit."] = "旋转的半径。",
    ["The height of the orbit."] = "旋转的高度。",
    ["The speed of the orbit."] = "旋转的速度。",
    ["Third Person"] = "第三人称",
    ["This is a test."] = "这是一条测试。",
    ["Time Lever [+"] = "时间拉杆 [+",
    ["Time Shower"] = "时间显示",
    ["Time: "] = "时间: ",
    ["Time: --:--"] = "时间: --:--",
    ["Tip Jar"] = "小费罐",
    ["Toolshed"] = "工具棚",
    ["Tp Next Door"] = "传送下一道门",
    ["Tracer Origin"] = "追踪线起点",
    ["Tracer Thickness"] = "追踪线粗细",
    ["Transparency"] = "透明度",
    ["Transparency of the path lines"] = "路径线条的透明度",
    ["Transparency of the path nodes when shown"] = "路径节点显示时的透明度",
    ["Transparent Hiding Spots"] = "躲藏点透明",
    ["Try going to the elevator!"] = "试试去电梯！",
    ["Turn Distance"] = "转向距离",
    ["Unequip the tv."] = "把电视卸下。",
    ["Unlock Distance"] = "解锁距离",
    ["Use him to duplicate items."] = "用他来复制物品。",
    ["Velocity Manipulation"] = "速度操控",
    ["Vent"] = "通风口",
    ["Viewmodel Offset"] = "手部模型偏移",
    ["Vine Chest"] = "藤蔓箱子",
    ["Vine Lever"] = "藤蔓拉杆",
    ["Vitamins"] = "维生素",
    ["Void"] = "Void",
    ["Waiting for the game to load..."] = "正在等待游戏加载...",
    ["Wall Check"] = "穿墙检测",
    ["Water Bypass removed: Softlock."] = "水路绕过已移除：会卡死。",
    ["Water Pump"] = "水泵",
    ["X Offset"] = "X 偏移",
    ["Y Offset"] = "Y 偏移",
    ["You must be in Room 0 to use this."] = "需要在 0 号房间才能用。",
    ["You must be in Room 200 to do this."] = "需要在 200 号房间才能做这个。",
    ["You must have gold to do this."] = "做这个需要先有金币。",
    ["Your executor doesn't support this feature."] = "你的执行器不支持这个功能。",
    ["Z Offset"] = "Z 偏移",
    ["Zooms out your camera, allowing you to see your character from behind."] = "拉远镜头，让你从背后看到自己的角色。",
    ["s]"] = "秒]",
    ["🎃 Abysall Hub Continued"] = "🎃 Abysall Hub 续作",
}

-- 拼接型：句子片段，子串替换（从官方脚本里扫出来的全部显示型片段）
local CONCAT = {
    { " seconds.", " 秒。" },
    { "' has spawned.", "' 出现了。" },
    { "' studs away from you.", " studs。" },
    { "' to toggle the UI.", "' 开关界面。" },
    { "Aggression ", "攻击性 " },
    { "Anchor [", "锚点 [" },
    { "Correct Box (", "正确的箱子 (" },
    { "Deposit (", "投放点 (" },
    { "Door ", "门 " },
    { "Gold Pile [", "金币堆 [" },
    { "It is '", "距离你 " },
    { "Item '", "物品 '" },
    { "Items: ", "物品: " },
    { "Oxygen: ", "氧气: " },
    { "Press '", "按 '" },
    { "Successfully loaded in ", "加载成功，用时 " },
    { "The code is: '", "密码是: '" },
    { "Time Lever [+", "时间拉杆 [+" },
    { "Time: ", "时间: " },
    { "s]", "秒]" },
}

-- ═══════════════════ 翻译函数 ═══════════════════
local CACHE = {}

-- 玩家名绝对不能翻（万一有人叫 "Battery" 就变「电池」了）
local function isPlayerName(s)
	local Players = game:GetService("Players")
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == s or p.DisplayName == s then return true end
	end
	return false
end

local function esc(s)
	return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"))
end

-- 单词型：加词边界，避免 "Bed" 命中 "Bedroom" 这种
local WORDS = {}
for k, v in pairs(ZH) do
	local isFragment = false
	for _, c in ipairs(CONCAT) do
		if c[1] == k then isFragment = true break end
	end
	if not isFragment and #k >= 3 and k:match("^[%w%s'%-_%./%(%)%[%]]+$") then
		table.insert(WORDS, { k, v, esc(k) })
	end
end
table.sort(WORDS, function(a, b) return #a[1] > #b[1] end)   -- 长的先匹配

local function translate(s)
	if type(s) ~= "string" or s == "" then return s end
	local exact = ZH[s]
	if exact then
		if isPlayerName(s) then return s end
		return exact
	end
	local cached = CACHE[s]
	if cached ~= nil then return cached end
	if isPlayerName(s) then CACHE[s] = s return s end

	local t = s
	-- ① 句子片段（"Door " / "Time: " 这类）
	for _, c in ipairs(CONCAT) do
		if t:find(c[1], 1, true) then
			t = t:gsub(esc(c[1]), (c[2]:gsub("%%", "%%%%")))
		end
	end
	-- ② 单词型：手工判定词边界
	--    不能用 %f[%w]，因为 Lua 的 %w 不含下划线，"Chest_Vine" 会被 "Chest" 命中
	--    所以用位置捕获，前后只要挨着 字母/数字/下划线 就跳过
	for _, w in ipairs(WORDS) do
		if t:find(w[1], 1, true) then
			local repl = (w[2]:gsub("%%", "%%%%"))
			t = t:gsub("()" .. w[3] .. "()", function(p1, p2)
				local before = p1 > 1 and t:sub(p1 - 1, p1 - 1) or ""
				local after = p2 <= #t and t:sub(p2, p2) or ""
				if before:match("[%w_]") or after:match("[%w_]") then
					return nil
				end
				return repl
			end)
		end
	end
	CACHE[s] = t
	return t
end

local ENABLED = true
local STATS = { ESP = 0, GUI = 0, DRAW = 0 }
local WORD_COUNT = #WORDS

-- ═══════════════════ ① ESP：钩远程库的 AddESP ═══════════════════
local ESP_HOOKED = false

local function hookESP()
	if ESP_HOOKED then return true end
	local A = getgenv().Abysall
	if type(A) ~= "table" then return false end
	local lib = A.ESPLibrary
	if type(lib) ~= "table" or type(lib.AddESP) ~= "function" then return false end

	local oldAdd = lib.AddESP
	lib.AddESP = function(self, opts, ...)
		if ENABLED and type(opts) == "table" and type(opts.Text) == "string" then
			local nt = translate(opts.Text)
			if nt ~= opts.Text then
				opts.Text = nt
				STATS.ESP = STATS.ESP + 1
			end
		end
		return oldAdd(self, opts, ...)
	end
	ESP_HOOKED = true
	return true
end

-- ═══════════════════ ② 界面：遍历 PlayerGui / CoreGui ═══════════════════
-- 注意：TextBox 只翻 PlaceholderText，绝不碰 .Text（那是玩家自己输入的内容）
local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }

local function fixOne(inst)
	local cls = inst.ClassName
	if not TEXT_CLASSES[cls] then return end

	if cls ~= "TextBox" then
		local ok, t = pcall(function() return inst.Text end)
		if ok and type(t) == "string" and t ~= "" then
			local nt = translate(t)
			if nt ~= t then
				pcall(function() inst.Text = nt end)
				STATS.GUI = STATS.GUI + 1
			end
		end
	else
		local ok, p = pcall(function() return inst.PlaceholderText end)
		if ok and type(p) == "string" and p ~= "" then
			local np = translate(p)
			if np ~= p then
				pcall(function() inst.PlaceholderText = np end)
				STATS.GUI = STATS.GUI + 1
			end
		end
	end
end

local function scan(root)
	if not root then return end
	pcall(function()
		for _, d in ipairs(root:GetDescendants()) do
			pcall(fixOne, d)
		end
	end)
end

local function fixAllGui()
	if not ENABLED then return end
	local lp = game:GetService("Players").LocalPlayer
	if lp then
		local pg = lp:FindFirstChild("PlayerGui")
		if pg then scan(pg) end
	end
	pcall(function() scan(game:GetService("CoreGui")) end)
end

-- ═══════════════════ ③ Drawing：Creak 攻击性条那一类 ═══════════════════
local DRAWINGS = {}
local DRAW_HOOKED = false

local function hookDrawing()
	if DRAW_HOOKED then return end
	local D = rawget(getgenv(), "Drawing") or rawget(_G, "Drawing") or Drawing
	if type(D) ~= "table" or type(D.new) ~= "function" then return end
	DRAW_HOOKED = true

	local oldNew = D.new
	D.new = function(kind)
		local obj = oldNew(kind)
		table.insert(DRAWINGS, obj)
		return obj
	end
end

local function fixDrawings()
	if not ENABLED then return end
	for i = #DRAWINGS, 1, -1 do
		local d = DRAWINGS[i]
		local ok, t = pcall(function() return d.Text end)
		if not ok then
			table.remove(DRAWINGS, i)
		elseif type(t) == "string" and t ~= "" then
			local nt = translate(t)
			if nt ~= t then
				pcall(function() d.Text = nt end)
				STATS.DRAW = STATS.DRAW + 1
			end
		end
	end
end

-- ═══════════════════ 调度 ═══════════════════
-- 尽早钩 Drawing（原脚本建 Creak 条时会用到）
hookDrawing()

task.spawn(function()
	local RunService = game:GetService("RunService")
	local deadline = tick() + 30
	while not ESP_HOOKED and tick() < deadline do
		hookESP()
		if not ESP_HOOKED then task.wait(0.05) end
	end
	local espState = ESP_HOOKED and "已接上 ESP 钩子" or "⚠ 没等到 Abysall.ESPLibrary（ESP 文字可能不翻）"
	print("[汉化] " .. espState)
	print(string.format("[汉化] 词表 %d 条（%d 片段 + %d 单词）", #ZH, #CONCAT, WORD_COUNT))

	fixAllGui()

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc = acc + dt
		if acc < 0.25 then return end
		acc = 0
		if not ESP_HOOKED then hookESP() end
		fixAllGui()
		fixDrawings()
	end)

	task.spawn(function()
		local cg = game:GetService("CoreGui")
		cg.DescendantAdded:Connect(function()
			task.wait(0.1)
			if ENABLED then fixAllGui() end
		end)
	end)
end)

getgenv().AbysallCN = {
	Translate = translate,
	Fix = function() fixAllGui(); fixDrawings() end,
	Off = function()
		ENABLED = false
		print("[汉化] 已关闭（界面文字会保持现状，重开界面即恢复英文）")
	end,
	On = function() ENABLED = true; fixAllGui() end,
	Stats = function()
		print(string.format("[汉化] ESP %d 次 / 界面 %d 次 / Drawing %d 次", STATS.ESP, STATS.GUI, STATS.DRAW))
	end,
	Dict = ZH,
}

-- ═══════════════════ 加载官方原版 ═══════════════════
print("[汉化] 从官方源加载原版脚本…")
loadstring(game:HttpGet(OFFICIAL_URL))()

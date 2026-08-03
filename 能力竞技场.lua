print("汉化脚本 v3.3")

-- ===== 精确翻译表（整句完全匹配）=====
-- 请在此按 ["英文原文"] = "中文翻译" 格式添加
local Translations = {
    -- 示例: ["Home"] = "主页",
    ["Kronos • Ability Arena"] = "Kronos • Ability Arena[suif汉化]",
    ["Tab"] = "标签页",
    ["Search..."] = "搜索...",
    ["Ability Arena"] = "能力竞技场[suif汉化]",
    ["Combat"] = "战斗",
    ["Visuals"] = "视觉",
    ["Misc"] = "杂项",
    ["Player"] = "玩家",
    ["Server"] = "服务器",
    ["Optimization"] = "优化",
    ["Hide UI"] = "隐藏界面",
    ["Show UI"] = "显示界面",
    ["Close UI"] = "关闭界面",
    ["Main"] = "主要",
    ["Auto Follow Near Player"] = "自动跟随附近玩家",
    ["Continuously tracks the closest valid player and keeps your character positioned behind them with smooth target switching."] = "持续追踪最近玩家，并将你的角色置于其身后，实现平滑目标切换。",
    ["Hitbox Expander"] = "命中箱扩展器",
    ["Claims network ownership and expands all enemy body parts (Head, torso, arms, legs) proportionally to increase hit registration."] = "获取网络所有权并按比例扩展所有敌人身体部位（头部、躯干、手臂、腿部），以提高命中判定",
    ["Hitbox Range Assist"] = "命中框范围辅助",
    ["Moves you into real server range when a target is inside the expanded hitbox zone."] = "当目标位于扩展命中框区域内时，将你移入真实服务器范围内。",
    ["Expander Size"] = "扩展器大小",
    ["Extra studs added to each axis of every enemy body part."] = "每个敌人身体部位额外增加的单位",
    ["Anti Void"] = "防虚空",
    ["Multi-layer ground probing with velocity prediction, edge detection, 5-frame safe history, and fan-pattern recovery search."] = "多层地面探测，包含速度预测、边缘检测、5帧安全历史记录和扇形模式恢复搜索。",
    ["Void Now"] = "立即防虚空",
    ["Immediately runs the Anti Void recovery logic for testing or emergency repositioning."] = "立即运行防虚空恢复逻辑，用于测试或紧急重新定位。",
    ["Aimbot"] = "自瞄",
    ["Select Mode"] = "选择模式",
    ["Choose how the aimbot selects targets."] = "选择目标的方式。",
    ["Closest"] = "最近",
    ["Select Target"] = "选择目标",
    ["Choose the body part used for camera aim."] = "选择用于相机瞄准的身体部位。",
    ["Head"] = "头部",
    ["Enable Aimbot"] = "启用自瞄",
    ["Smoothly aims the camera at the selected target type while respecting filters."] = "在遵循过滤规则的同时，平滑地将相机对准所选目标类型。",
    ["Prediction Enabled"] = "启用预测",
    ["Adds velocity prediction to moving targets."] = "为移动目标添加速度预测",
    ["Prediction Amount"] = "预测量",
    ["Controls how much target velocity is added to aim position."] = "控制添加到瞄准位置的目标速度量。",
    ["Smoothness Enabled"] = "启用平滑度",
    ["Uses smooth camera interpolation instead of direct snapping."] = "使用平滑相机插值而非生硬跳转。",
    ["Smoothness"] = "平滑度",
    ["Higher values produce slower and smoother camera movement."] = "数值越高，相机移动越慢越平滑。",
    ["FOV Enabled"] = "启用视野",
    ["Restricts target selection to the configured field-of-view circle."] = "将目标选择限制在配置的视野圆环内。",
    ["FOV Radius"] = "视野半径",
    ["Controls the circular aimbot field-of-view radius."] = "控制圆形自瞄视野半径。",
    ["Team Check"] = "队伍检测",
    ["Ignores players on your team when team data is available."] = "当队伍数据可用时，忽略同队玩家。",
    ["Wall Check"] = "穿墙检测",
    ["Requires a clean camera raycast before aiming at a target."] = "检测前方是否拥有墙壁 有则暂停自瞄 无则继续自瞄",
    ["Show FOV Circle"] = "显示视野圆环",
    ["Draws a clean circular FOV indicator when the aimbot is active."] = "自瞄激活时绘制清晰的圆形视野指示器。",
    ["Dynamic Prediction"] = "动态预测",
    ["Scales prediction using distance for more stable long-range tracking."] = "使用距离缩放预测，以实现更稳定的远程追踪。",
    ["Priority Low Health"] = "优先低血量",
    ["Gives damaged targets higher priority during target selection."] = "在目标选择时给予已受伤目标更高优先级。",
    ["Priority Closest To Crosshair"] = "优先准星最近",
    ["Prioritizes the target closest to your cursor or screen center."] = "优先选择离你光标或屏幕中心最近的目标。",
    ["Search options..."] = "搜索选项...",
    ["Visible"] = "可见",
    ["Nearest"] = "最近",
    ["Torso"] = "躯干",
    ["Enable"] = "启用",
    ["Enable Players ESP"] = "启用玩家 ESP",
    ["Draws clean Kronos player overlays with distance, health, tool, and team context using reusable Drawing objects."] = "使用可复用的 Drawing 对象绘制清晰的 Kronos 玩家叠加层，包含距离、生命值、工具和队伍信息。",
    ["Configurations"] = "配置",
    ["Show Box"] = "显示方框",
    ["Displays a box around visible player characters."] = "在可见玩家角色周围显示方框。",
    ["Show Tracers"] = "显示轨迹线",
    ["Draws a tracer line from the bottom of the screen to each rendered player."] = "从屏幕底部向每个渲染的玩家绘制轨迹线。",
    ["Show Name"] = "显示名称",
    ["Shows the player name above each ESP box."] = "在每个 ESP 方框上方显示玩家名称。",
    ["Show Healthbar"] = "显示生命条",
    ["Renders a compact health bar beside each player box."] = "在每个玩家方框旁渲染紧凑生命条。",
    ["Show Distance"] = "显示距离",
    ["Shows the distance between you and the rendered player."] = "显示你与渲染玩家之间的距离。",
    ["Show Equipped Tool"] = "显示装备工具",
    ["Includes the equipped tool name in the player label when available."] = "在可用时于玩家标签中包含装备工具名称。",
    ["Show Team Status"] = "显示队伍状态",
    ["Adds ally, enemy, or neutral status when team data exists."] = "当队伍数据存在时，添加盟友、敌人或中立状态。",
    ["Max Distance"] = "最大距离",
    ["Maximum ESP render distance unless the distance limit is ignored."] = "最大 ESP 渲染距离，除非忽略距离限制。",
    ["Ignore Distance Limit"] = "忽略距离限制",
    ["Allows ESP to render players beyond the configured maximum distance."] = "允许 ESP 渲染超出配置最大距离的玩家。",
    ["Only Visible Targets"] = "仅可见目标",
    ["Only renders players with a clear camera line of sight."] = "仅渲染有清晰相机视线的玩家。",
    ["Box Color"] = "方框颜色",
    ["Color used for player ESP boxes."] = "玩家 ESP 方框使用的颜色。",
    ["Tracer Color"] = "轨迹颜色",
    ["Color used for tracer lines."] = "轨迹线使用的颜色。",
    ["Name Color"] = "名称颜色",
    ["Color used for player name labels."] = "玩家名称标签使用的颜色。",
    ["Healthbar Color"] = "生命条颜色",
    ["Color used for health bar fill."] = "生命条填充使用的颜色。",
    ["Distance Color"] = "距离颜色",
    ["Color used for distance labels."] = "距离标签使用的颜色。",
    ["Skeleton ESP"] = "骨骼 ESP",
    ["Enable Skeleton ESP"] = "启用骨骼 ESP",
    ["Draws a connected bone skeleton overlay on the nearest enemy player using real body part positions."] = "使用真实身体部位位置在最近的敌人玩家上绘制连接的骨骼叠加层。",
    ["Skeleton Color"] = "骨骼颜色",
    ["Color used for the skeleton bone lines."] = "骨骼线条使用的颜色。",
    ["Line Thickness"] = "线条粗细",
    ["Thickness of the skeleton outline lines."] = "骨骼轮廓线条的粗细。",
    ["3D Box ESP"] = "3D 方框 ESP",
    ["Enable 3D Box ESP"] = "启用 3D 方框 ESP",
    ["Renders an oriented 3D bounding box around the nearest enemy that rotates with their character."] = "在最近敌人周围渲染方向性 3D 边界框，随其角色旋转。",
    ["Color used for the 3D box edges."] = "3D 方框边缘使用的颜色。",
    ["Edge Thickness"] = "边缘粗细",
    ["Thickness of the 3D box edge lines."] = "3D 方框边缘线条的粗细。",
    ["Filled Faces"] = "填充面",
    ["Fills the 3D box faces with a semi-transparent color for stronger visual presence."] = "用半透明颜色填充 3D 方框面，增强视觉效果。",
    ["Fill Transparency"] = "填充透明度",
    ["How transparent the filled box faces are. Lower = more visible fill."] = "填充方框面的透明度。数值越低 = 填充越明显。",
    ["Projectile ESP"] = "投射物 ESP",
    ["Enable Projectile ESP"] = "启用投射物 ESP",
    ["Automatically detects and tracks enemy projectiles, spells, and fast-moving objects in the world."] = "自动检测并追踪世界中的敌人投射物、法术和快速移动物体。",
    ["Projectile Color"] = "投射物颜色",
    ["Color used for projectile boxes and tracers."] = "投射物方框和轨迹使用的颜色。",
    ["Draws a line from your screen center to each tracked projectile."] = "从屏幕中心向每个追踪的投射物绘制线条。",
    ["Box Size"] = "方框大小",
    ["Screen size of the projectile indicator box in pixels."] = "投射物指示器方框的屏幕像素大小。",
    ["Enemy Radar"] = "敌人雷达",
    ["Enable Enemy Radar"] = "启用敌人雷达",
    ["Displays a clean minimap-style radar overlay showing enemy and ally positions relative to you. Rotates with your camera."] = "显示清晰的小地图风格雷达叠加层，显示敌人和盟友相对于你的位置。随相机旋转。",
    ["Radar Size"] = "雷达大小",
    ["Diameter of the radar display in pixels. Auto-scales for mobile."] = "雷达显示器的像素直径。移动端自动缩放。",
    ["Position"] = "位置",
    ["Corner of the screen where the radar appears."] = "雷达出现的屏幕角落。",
    ["TopRight"] = "右上",
    ["Radar Range"] = "雷达范围",
    ["How far the radar scans for players in studs."] = "雷达扫描玩家的距离（单位）。",
    ["Dot Size"] = "点大小",
    ["Size of player dots on the radar."] = "雷达上玩家点的大小。",
    ["Show Names"] = "显示名称",
    ["Displays player names next to their dots on the radar."] = "在雷达上玩家点旁边显示名称。",
    ["Maximum world distance at which players appear on the radar."] = "玩家在雷达上出现的最大世界距离。",
    ["Enemy Dot Color"] = "敌人点颜色",
    ["Color for enemy player dots on the radar."] = "雷达上敌人玩家点的颜色。",
    ["Ally Dot Color"] = "盟友点颜色",
    ["Color for ally player dots on the radar."] = "雷达上盟友玩家点的颜色。",
    ["Self Dot Color"] = "自身点颜色",
    ["Color for your own position dot at the radar center."] = "雷达中心自身位置点的颜色。",
    ["Border Color"] = "边框颜色",
    ["Color of the radar border and crosshair lines."] = "雷达边框和准星线的颜色。",
    ["Background Color"] = "背景颜色",
    ["Fill color behind the radar area."] = "雷达区域后的填充颜色。",
    ["Background Transparency"] = "背景透明度",
    ["How transparent the radar background is. 1 = fully invisible."] = "雷达背景的透明度。1 = 完全不可见。",
    ["TopLeft"] = "左上",
    ["BottomRight"] = "右下",
    ["BottomLeft"] = "左下",
    ["Spectate"] = "观战",
    ["Select Player"] = "选择玩家",
    ["Choose a player for spectating or teleport actions. The list refreshes automatically as players join or leave."] = "选择用于观战或传送操作的玩家。列表随玩家加入或离开自动刷新。",
    ["Alvinkwoo"] = "Alvinkwoo",
    ["Sets your camera subject to the selected player's humanoid and automatically recovers when disabled or unavailable."] = "将相机主题设为所选玩家的人形对象，并在禁用或不可用时自动恢复。",
    ["Teleport To Player"] = "传送到玩家",
    ["Safely moves your character behind the selected player's HumanoidRootPart."] = "将你的角色安全移动到所选玩家的 HumanoidRootPart 后方。",
    ["Notify"] = "通知",
    ["Alert Damaged Players"] = "提醒受伤玩家",
    ["Shows a Fluent notification when any player's health percentage drops below the selected threshold."] = "当任意玩家生命值百分比低于所选阈值时显示 Fluent 通知。",
    ["Threshold (%)"] = "阈值（%）",
    ["Health percentage required before injured-player notifications are shown."] = "显示受伤玩家通知所需的生命值百分比。",
    ["Movement"] = "移动",
    ["Set WalkSpeed"] = "设置行走速度",
    ["Continuously applies your configured movement speed and reapplies it after respawn."] = "持续应用你配置的移动速度，并在重生后重新应用。",
    ["WalkSpeed"] = "行走速度",
    ["Movement speed value applied while Set WalkSpeed is enabled."] = "启用设置行走速度时应用的移动速度值。",
    ["Set JumpPower"] = "设置跳跃力度",
    ["Continuously applies jump power and supports respawn recovery."] = "持续应用跳跃力度，并支持重生恢复。",
    ["JumpPower"] = "跳跃力度",
    ["Jump power value applied while Set JumpPower is enabled."] = "启用设置跳跃力度时应用的跳跃力度值。",
    ["Noclip"] = "穿墙",
    ["Keeps your character collision disabled while active."] = "激活时保持角色碰撞禁用状态。",
    ["Infinite Jump"] = "无限跳跃",
    ["Lets you jump again while airborne on PC and mobile jump input."] = "允许你在空中再次跳跃，支持 PC 和移动端跳跃输入。",
    ["Utility"] = "实用工具",
    ["Anti AFK"] = "防挂机",
    ["Periodically sends lightweight input to reduce idle disconnects."] = "定期发送轻量输入以减少闲置断开连接。",
    ["Anti AFK Interval"] = "防挂机间隔",
    ["Seconds between anti-idle input pulses."] = "防闲置输入脉冲之间的秒数。",
    ["Reset Character Camera"] = "重置角色相机",
    ["Restores your camera subject to your own humanoid."] = "将相机主题恢复为你自己的人形对象。",
    ["Rejoin Server"] = "重新加入服务器",
    ["Reconnects to the current Ability Arena server with duplicate-operation protection."] = "在防止重复操作保护下重新连接到当前 Ability Arena 服务器。",
    ["Server Hop"] = "跳转服务器",
    ["Finds and joins another public server for this place."] = "查找并加入该游戏场所的另一个公共服务器。",
    ["Low Player Server"] = "低人数服务器",
    ["Searches for a lower-population public server."] = "搜索人数较少的公共服务器。",
    ["Copy Job ID"] = "复制任务 ID",
    ["Copies the current server JobId when your executor supports clipboard access."] = "当执行器支持剪贴板访问时复制当前服务器 JobId。",
    ["Performance"] = "性能",
    ["FPS Booster"] = "FPS 提升",
    ["Applies a balanced group of visual reductions for smoother performance."] = "应用平衡的视觉缩减组以获得更流畅的性能。",
    ["Target FPS"] = "目标 FPS",
    ["Sets an executor FPS cap when supported."] = "在支持时设置执行器 FPS 上限。",
    ["Hide Other Players"] = "隐藏其他玩家",
    ["Locally hides other player character parts to reduce visual clutter and render cost."] = "本地隐藏其他玩家角色部件以减少视觉杂乱和渲染开销。",
    ["Reduce Terrain"] = "减少地形",
    ["Disables terrain decoration when supported."] = "在支持时禁用地形装饰。",
    ["Disable Wind"] = "禁用风效",
    ["Sets Workspace.GlobalWind to zero when supported."] = "在支持时将 Workspace.GlobalWind 设为零。",
    ["Render Cleanup"] = "渲染清理",
    ["Remove Shadows"] = "移除阴影",
    ["Disables global shadows while active."] = "激活时禁用全局阴影。",
    ["Remove Fog"] = "移除雾效",
    ["Extends fog distance for clearer visibility."] = "延长雾距离以获得更清晰的可见度。",
    ["Remove Bloom"] = "移除泛光",
    ["Disables BloomEffect instances."] = "禁用 BloomEffect 实例。",
    ["Remove Blur"] = "移除模糊",
    ["Disables blur and depth-of-field effects."] = "禁用模糊和景深效果。",
    ["Remove Sun Rays"] = "移除太阳光晕",
    ["Disables SunRaysEffect instances."] = "禁用 SunRaysEffect 实例。",
    ["Remove Color Correction"] = "移除颜色校正",
    ["Disables ColorCorrectionEffect instances."] = "禁用 ColorCorrectionEffect 实例。",
    ["Remove Particles"] = "移除粒子",
    ["Disables particles, trails, beams, smoke, fire, and sparkles."] = "禁用粒子、轨迹、光束、烟雾、火焰和火花效果。",
    ["Remove Decals"] = "移除贴花",
    ["Hides decals and textures locally while active."] = "激活时本地隐藏贴花和纹理。",
    ["Remove Billboards"] = "移除广告牌",
    ["Disables BillboardGui instances to reduce overhead."] = "禁用 BillboardGui 实例以减少开销。",
    ["Reapply Optimizations"] = "重新应用优化",
    ["Runs a fresh optimization sweep across lighting, workspace, and players."] = "在光照、工作区和玩家上运行全新优化扫描。",
    ["Restore Visuals"] = "恢复视觉效果",
    ["Restores properties modified by optimization controls."] = "恢复被优化控制修改的属性。",
    ["Configuration"] = "配置",
    ["Config name"] = "配置名称",
    ["Config list"] = "配置列表",
    ["--"] = "--",
    ["Create config"] = "创建配置",
    ["Load config"] = "加载配置",
    ["Overwrite config"] = "覆盖配置",
    ["Refresh list"] = "刷新列表",
    ["Set as autoload"] = "设为自动加载",
    ["Current autoload: none"] = "当前自动加载：无",
    ["Interface"] = "界面",
    ["Theme"] = "主题",
    ["Changes the interface theme."] = "更改界面主题。",
    ["Animated Window"] = "动画窗口",
    ["Enables shine/stroke animation on theme."] = "启用主题的闪光/描边动画。",
    ["Transparency"] = "透明度",
    ["Makes the interface transparent."] = "使界面透明。",
    ["Disable Background Images"] = "禁用背景图片",
    ["Hides theme background images."] = "隐藏主题背景图片。",
    ["Acrylic"] = "亚克力",
    ["Requires graphic quality 8+."] = "需要图形质量 8 级以上。",
    ["Font Manager"] = "字体管理器",
    ["Changes the UI font."] = "更改界面字体。",
    ["GothamSSm"] = "GothamSSm",
    ["Minimize Bind"] = "最小化快捷键",
    ["LeftControl"] = "左 Ctrl",
    ["Fluent UI"] = "Fluent 界面",
    ["Kronos UI settings"] = "Kronos 界面设置",
    ["Manage Fluent UI Library themes, acrylic, transparency, configuration files, and autoload behavior for Ability Arena."] = "管理 Ability Arena 的 Fluent UI 库主题、亚克力、透明度、配置文件和自动加载行为。",
    ["Safety Diagnostics"] = "安全诊断",
    ["Anti Void Debug"] = "防虚空调试",
    ["Emits throttled internal traces for safe updates, unsafe detections, and recovery attempts."] = "为安全更新、不安全检测和恢复尝试输出限流内部跟踪信息。",
}

-- ===== 部分替换表（子串替换）=====
-- 请在此按 ["英文子串"] = "中文替换" 格式添加
-- 注意：会替换文本中所有匹配的子串，请谨慎使用
local PartialTranslations = {
    -- 示例: yes no 
    --["yes"] = "是",
    
}

-- ===== 选择模式（带按钮的原生通知）=====
local function AskModeWithNotification()
    local StarterGui = game:GetService("StarterGui")
    local choice = nil

    local success, err = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "汉化模式选择",
            Text = "请选择翻译方式",
            Button1 = "Hook模式 (快速)",
            Button2 = "普通模式 (稳定)",
            Duration = 10,
            Callback = function(clicked)
                -- 兼容两种返回值：字符串或数字索引
                if clicked == "Hook模式 (快速)" or clicked == 1 then
                    choice = true
                elseif clicked == "普通模式 (稳定)" or clicked == 2 then
                    choice = false
                end
            end
        })
    end)

    if not success then
        warn("通知发送失败，使用普通模式:", err)
        return false
    end

    local start = os.clock()
    repeat
        wait(0.1)
    until choice ~= nil or os.clock() - start > 11

    if choice == nil then
        print("未选择，默认使用普通模式")
        return false
    end
    return choice
end

local UseHookTranslation = AskModeWithNotification()
print("最终使用模式:", UseHookTranslation and "Hook" or "普通监听")

-- ===== 翻译框架（监听模式为主）=====
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

if not PlayerGui then
    warn("未找到 PlayerGui，汉化可能无法正常工作")
end

local SystemUiNames = {
    RobloxGui=true, PlayerList=true, Backpack=true, Chat=true, BubbleChat=true,
    ExperienceChat=true, TextChatService=true, TopBar=true, Topbar=true, Health=true,
    EmotesMenu=true, Chrome=true, InspectMenu=true, PurchasePrompt=true,
    ScreenshotHud=true
}

local WatchedRoots, WatchedObjects, TranslatingObjects = setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"})

local function TranslateText(txt)
    if type(txt) ~= "string" or txt == "" then return txt end
    local clean = txt:gsub("<[^>]->", ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- 1. 精确匹配（整句）
    local exact = Translations[txt] or Translations[clean]
    if exact then return exact end

    -- 2. 部分替换（子串）
    local result = txt
    for original, translated in pairs(PartialTranslations) do
        result = result:gsub(original, translated)
    end
    return result
end

local function IsSysUI(obj)
    while obj do
        if SystemUiNames[obj.Name] then return true end
        obj = obj.Parent
    end
    return false
end

local function TranslateObj(obj)
    if IsSysUI(obj) or TranslatingObjects[obj] then return end
    TranslatingObjects[obj] = true
    pcall(function()
        local nText = TranslateText(obj.Text)
        if nText ~= obj.Text then obj.Text = nText end
        local nPlace = TranslateText(obj.PlaceholderText)
        if nPlace ~= obj.PlaceholderText then obj.PlaceholderText = nPlace end
    end)
    TranslatingObjects[obj] = nil
end

local function WatchObj(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
    if WatchedObjects[obj] then return end
    WatchedObjects[obj] = true

    TranslateObj(obj)

    local function onPropChange()
        if not TranslatingObjects[obj] then
            delay(0.03, function() TranslateObj(obj) end)
        end
    end

    pcall(function()
        obj:GetPropertyChangedSignal("Text"):Connect(onPropChange)
        obj:GetPropertyChangedSignal("PlaceholderText"):Connect(onPropChange)
    end)
end

local function GetRoots()
    local roots = {}
    if PlayerGui then table.insert(roots, PlayerGui) end
    pcall(function() table.insert(roots, CoreGui) end)
    pcall(function()
        if gethui then
            local hui = gethui()
            if hui then table.insert(roots, hui) end
        end
    end)
    return roots
end

local function ScanAndWatch(root)
    if not root or WatchedRoots[root] then return end
    WatchedRoots[root] = true

    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            WatchObj(obj)
        end
        root.DescendantAdded:Connect(function(obj)
            delay(0.05, function()
                WatchObj(obj)
                pcall(function()
                    for _, c in ipairs(obj:GetDescendants()) do
                        WatchObj(c)
                    end
                end)
            end)
        end)
    end)
end

-- ===== 如果用户选择了 Hook 模式，尝试安装 =====
local hookInstalled = false
if UseHookTranslation then
    local hookSuccess, hookErr = pcall(function()
        local mt = getrawmetatable(game)
        if not mt then error("getrawmetatable 失败") end
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(t, k, v)
            if (k == "Text" or k == "PlaceholderText") and
               (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) and
               not IsSysUI(t) then
                v = TranslateText(tostring(v))
            end
            return oldNewIndex(t, k, v)
        end)
        setreadonly(mt, true)
    end)
    if not hookSuccess then
        warn("Hook安装失败，降级为监听模式:", hookErr)
        UseHookTranslation = false
        hookInstalled = false
    else
        print("Hook模式已启用")
        hookInstalled = true
    end
else
    print("使用普通监听模式")
end

-- ===== 启动监听扫描（即使 Hook 成功也保留作为备用） =====
spawn(function()
    while true do
        for _, root in ipairs(GetRoots()) do
            ScanAndWatch(root)
            pcall(function()
                for _, obj in ipairs(root:GetDescendants()) do
                    WatchObj(obj)
                end
            end)
        end
        wait(hookInstalled and 20 or 12)
    end
end)

wait(0.5)

-- ===== 加载外部脚本 =====
local ScriptUrl = "https://raw.githubusercontent.com/Nanana291/Kronos/refs/heads/main/Loader.lua"
print("开始下载外部脚本...")

local ok, content = pcall(function()
    return game:HttpGet(ScriptUrl)
end)

if not ok then
    warn("下载失败：", content)
elseif not content or content == "" then
    warn("内容为空")
else
    print("下载成功，长度：", #content)
    local func, err = loadstring(content)
    if not func then
        warn("编译失败：", err)
    else
        print("编译成功，执行外部脚本...")
        local execOk, execErr = pcall(func)
        if not execOk then
            warn("执行失败：", execErr)
        else
            print("外部脚本执行成功")
        end
    end
end

print("[汉化] 已加载")

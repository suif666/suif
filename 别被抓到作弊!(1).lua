
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    AntiCaught     = true,
    InstantSearch  = true,
    AutoAnswer     = true,
    SpoofState     = true,
    SpoofProgress  = true,
    SpoofView      = false,
    BlockSearching = false,
    CleanInject    = true,
    UpvalueHack    = true,
    AutoAdSkip     = true,
    FullAuto       = false,
    AutoDelay      = 0.3,
    LogLevel       = 1,
    InjectInterval = 0.15,
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local R = {}
for _, name in ipairs({
    "ClassroomPlayerStateUpdate", "ClassroomProgressUpdate",
    "ClassroomViewState", "ClassroomLookUpdate",
    "ForceCaughtCamera", "ClassroomItemRemote", "ClassroomAdSlot",
}) do
    R[name] = Remotes:WaitForChild(name, 15)
end

local R_State    = R.ClassroomPlayerStateUpdate
local R_Progress = R.ClassroomProgressUpdate
local R_View     = R.ClassroomViewState
local R_Look     = R.ClassroomLookUpdate
local R_Caught   = R.ForceCaughtCamera
local R_Item     = R.ClassroomItemRemote
local R_Ad       = R.ClassroomAdSlot

local hasGetupvalues = type(getupvalues) == "function"
local hasSetupvalue   = type(setupvalue) == "function"
local hasGetconns     = type(getconnections) == "function"
local hasHookfunc     = type(hookfunction) == "function"
local hasHookmeta     = type(hookmetamethod) == "function"

local Internal, Internals

local Diag = {
    hookmeta    = false,
    hookfunc    = false,
    getconns    = false,
    getupvalues = false,
    setupvalue  = false,
    namecallBlock = false,
    cleanInject = false,
    upvalueHack = false,
    attrReset   = false,
    connDisable = false,
    setViewHook = false,
}

local logQueue = {}
local notifyQueue = {}

local function log(lv, msg, ...)
    if Config.LogLevel >= lv then
        local entry = string.format("[%s] %s", lv >= 2 and "DBG" or "INF", tostring(msg))
        local args = {...}
        for i = 1, #args do entry = entry .. " " .. tostring(args[i]) end
        table.insert(logQueue, {text = entry, level = lv, time = os.clock()})
        if #logQueue > 200 then table.remove(logQueue, 1) end
        print("[CheatHub]", msg, ...)
    end
end

local function notify(msg, color)
    table.insert(notifyQueue, {text = msg, color = color or "accent", time = os.clock()})
    if #notifyQueue > 5 then table.remove(notifyQueue, 1) end
end

local HookManager = {
    namecallHandlers = {},
    indexHandlers    = {},
    installed        = false,
    BLOCK = {},
}

function HookManager.registerNamecall(fn)
    table.insert(HookManager.namecallHandlers, fn)
    HookManager.install()
end

function HookManager.registerIndex(fn)
    table.insert(HookManager.indexHandlers, fn)
    HookManager.install()
end

function HookManager.install()
    if HookManager.installed or not hasHookmeta then return end
    HookManager.installed = true
    Diag.hookmeta = true

    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", function(...)
            local self = ...
            local method = getnamecallmethod()
            local args = table.pack(...)
            for _, handler in ipairs(HookManager.namecallHandlers) do
                local result = handler(self, method, args)
                if result ~= nil then
                    if result == HookManager.BLOCK then return end
                    return result
                end
            end
            return old(table.unpack(args, 1, args.n))
        end)
    end)

    pcall(function()
        local old
        old = hookmetamethod(game, "__index", function(self, key)
            for _, handler in ipairs(HookManager.indexHandlers) do
                local result = handler(self, key)
                if result ~= nil then return result end
            end
            return old(self, key)
        end)
    end)

    log(1, "HookManager: hookmetamethod 已安装")
end

local RemoteGuard = {}
local guardActive = false
local spoofStats = { state = 0, look = 0, view = 0, progress = 0, blocked = 0 }

function RemoteGuard.enable()
    if guardActive then return end
    guardActive = true

    HookManager.registerNamecall(function(self, method, args)
        if not guardActive or method ~= "FireServer" then return nil end

        if Config.SpoofState and rawequal(self, R_State) then
            local state = args[2]
            if state == "SEARCHING" or state == "WRITING" then
                local curView = Internal and Internal.getCurrentView and Internal.getCurrentView() or nil
                if curView == "CHEAT" or curView == "EXAM" then
                elseif Config.BlockSearching then
                    spoofStats.state = spoofStats.state + 1
                    spoofStats.blocked = spoofStats.blocked + 1
                    log(2, "BLOCK StateUpdate:", state)
                    return HookManager.BLOCK
                else
                    spoofStats.state = spoofStats.state + 1
                    args[2] = "IDLE"
                    log(2, "MODIFY StateUpdate:", state, "-> IDLE")
                end
            end
        end

        if Config.SpoofView and rawequal(self, R_Look) then
            if args[2] and args[2] ~= "FREE" then
                spoofStats.look = spoofStats.look + 1
                args[2] = "FREE"
            end
        end

        if Config.SpoofView and rawequal(self, R_View) then
            if args[2] and args[2] ~= "FREE" then
                spoofStats.view = spoofStats.view + 1
                args[2] = "FREE"
            end
        end

        if Config.SpoofProgress and rawequal(self, R_Progress) then
            local data = args[2]
            if type(data) == "table" then
                spoofStats.progress = spoofStats.progress + 1
                data.cheatSeconds = 0
                data.examSeconds = 0
                log(2, "ProgressUpdate 已篡改 (仅清零cheat/examSeconds)")
            end
        end

        return nil
    end)

    Diag.namecallBlock = true
    log(1, "RemoteGuard 已启用 (namecall BLOCK+MODIFY 模式)")
end

function RemoteGuard.disable()
    guardActive = false
    log(1, "RemoteGuard 已关闭")
end

function RemoteGuard.getStats()
    return spoofStats
end

local CleanInjector = {}
local injectActive = false
local injectCount = 0

function CleanInjector.enable()
    if injectActive then return end
    injectActive = true
    Diag.cleanInject = true

    task.spawn(function()
        while injectActive do
            if Internal and Internal.isInRound and Internal.isInRound() then
                local goal = Internal.getGoalAnswers and Internal.getGoalAnswers() or 10
                local written = Internal.getAnswersWritten and Internal.getAnswersWritten() or 0
                local searched = 0
                local currentView = Internal.getCurrentView and Internal.getCurrentView() or "FREE"
                if Internals.submitExamChoice and hasGetupvalues then
                    local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
                    if ok and ups and type(ups[12]) == "number" then
                        searched = ups[12]
                    end
                end

                if currentView == "CHEAT" or currentView == "EXAM" then
                else
                    local cleanData = {
                        answersWritten   = written,
                        searchedAnswers  = searched,
                        goalAnswers      = goal,
                        hasSearchedAnswer = false,
                        searchProgress   = 0,
                        examSeconds      = 0,
                        cheatSeconds     = 0,
                        view             = currentView or "FREE",
                        action           = "IDLE",
                        passed           = goal <= written,
                    }

                    pcall(function()
                        R_Progress:FireServer(cleanData)
                    end)
                    injectCount = injectCount + 1
                end
            end
            task.wait(Config.InjectInterval)
        end
    end)

    log(1, string.format("CleanInjector 已启用 (间隔: %.2fs)", Config.InjectInterval))
    notify("定时器注入已启用", "green")
end

function CleanInjector.disable()
    injectActive = false
    log(1, "CleanInjector 已关闭")
end

function CleanInjector.getStats()
    return { count = injectCount, active = injectActive }
end

local AntiCaught = {}
local antiCaughtActive = false
local fakeSignal = Instance.new("BindableEvent")

local blockedAttrs = {
    ["TeacherCaughtCameraActive"]      = true,
    ["TeacherObservationCameraActive"] = true,
}

function AntiCaught.enable()
    if antiCaughtActive then return end
    antiCaughtActive = true

    if hasHookmeta then
        HookManager.registerNamecall(function(self, method, args)
            if not antiCaughtActive then return nil end
            if self == LocalPlayer then
                if method == "GetAttribute" and blockedAttrs[args[2]] then
                    return false
                end
                if method == "GetAttributeChangedSignal" and blockedAttrs[args[2]] then
                    return fakeSignal.Event
                end
            end
            return nil
        end)

        HookManager.registerIndex(function(self, key)
            if antiCaughtActive and key == "OnClientEvent" and rawequal(self, R_Caught) then
                return fakeSignal.Event
            end
            return nil
        end)
    end

    Diag.attrReset = true
    for attrName in pairs(blockedAttrs) do
        LocalPlayer:GetAttributeChangedSignal(attrName):Connect(function()
            if antiCaughtActive and LocalPlayer:GetAttribute(attrName) == true then
                LocalPlayer:SetAttribute(attrName, false)
                log(2, "属性重置:", attrName, "-> false")
            end
        end)
    end

    task.spawn(function()
        while antiCaughtActive do
            for attrName in pairs(blockedAttrs) do
                if LocalPlayer:GetAttribute(attrName) == true then
                    LocalPlayer:SetAttribute(attrName, false)
                end
            end
            task.wait(0.1)
        end
    end)

    if hasGetconns then
        Diag.connDisable = true
        Diag.getconns = true
        local function disableCaughtConns()
            for _, conn in ipairs(getconnections(R_Caught.OnClientEvent)) do
                if conn.Enabled then
                    pcall(function() conn:Disable() end)
                end
            end
        end
        disableCaughtConns()

        task.spawn(function()
            while antiCaughtActive do
                disableCaughtConns()
                task.wait(2)
            end
        end)

        for _, remote in ipairs({R_Look, R_View}) do
            pcall(function()
                for _, conn in ipairs(getconnections(remote.OnClientEvent)) do
                    pcall(function() conn:Disable() end)
                end
            end)
        end
    end

    AntiCaught.tryHookSetView()

    task.spawn(function()
        while antiCaughtActive do
            local cam = workspace.CurrentCamera
            if cam and cam.CameraType == Enum.CameraType.Scriptable then
                local view = Internal.getCurrentView and Internal.getCurrentView() or nil
                if view == "CAUGHT" or (LocalPlayer:GetAttribute("TeacherCaughtCameraActive") == true) then
                    cam.CameraType = Enum.CameraType.Custom
                    log(2, "相机强制恢复: Scriptable -> Custom")
                end
            end
            task.wait(0.2)
        end
    end)

    log(1, "反被抓系统已启用 (7层防御)")
    notify("7层反被抓已激活", "green")
end

function AntiCaught.disable()
    antiCaughtActive = false
    log(1, "反被抓系统已关闭")
end

function AntiCaught.tryHookSetView()
    if not antiCaughtActive then return end
    if not Internals.setView or not hasHookfunc then return end
    if Diag.setViewHook then return end
    Diag.setViewHook = true
    pcall(function()
        local old
        old = hookfunction(Internals.setView, function(view, ...)
            if antiCaughtActive and view == "CAUGHT" then
                log(2, "setView 拦截: CAUGHT -> 跳过")
                return
            end
            return old(view, ...)
        end)
    end)
    log(1, "setView hook 已安装")
    notify("setView hook 已安装", "green")
end

local UpvalueHack = {}
local upvalueTargets = {}
local upvalueActive = false

function UpvalueHack.scan()
    if not hasGetupvalues or not hasGetconns then
        log(1, "UpvalueHack: 执行器不支持 getupvalues/getconnections")
        return false
    end
    Diag.getupvalues = true
    Diag.setupvalue = hasSetupvalue

    local found = false

    for _, conn in ipairs(getconnections(RunService.Heartbeat)) do
        if conn.Function then
            local ok, ups = pcall(getupvalues, conn.Function)
            if ok and ups then
                for i, up in ipairs(ups) do
                    if type(up) == "number" and i > 5 then
                    end
                    if type(up) == "function" then
                        local ok2, ups2 = pcall(getupvalues, up)
                        if ok2 and ups2 then
                            for j, up2 in ipairs(ups2) do
                                if up2 == "CHEAT" or up2 == "FREE" or up2 == "EXAM" then
                                    upvalueTargets = {
                                        func = up,
                                        viewIdx = j,
                                        indices = {},
                                    }
                                    for k, up3 in ipairs(ups2) do
                                        if type(up3) == "number" then
                                            upvalueTargets.indices[k] = true
                                        end
                                    end
                                    log(2, string.format("UpvalueHack: 找到状态函数 (view@%d, %d个数值变量)", j, #upvalueTargets.indices))
                                    found = true
                                    break
                                end
                            end
                        end
                    end
                    if found then break end
                end
            end
            if found then break end
        end
    end

    if not found then
        for _, conn in ipairs(getconnections(RunService.RenderStepped)) do
            if conn.Function then
                local ok, ups = pcall(getupvalues, conn.Function)
                if ok and ups then
                    for i, up in ipairs(ups) do
                        if type(up) == "function" then
                            local ok2, ups2 = pcall(getupvalues, up)
                            if ok2 and ups2 then
                                for j, up2 in ipairs(ups2) do
                                    if up2 == "CHEAT" or up2 == "FREE" then
                                        upvalueTargets = { func = up, viewIdx = j, indices = {} }
                                        for k, up3 in ipairs(ups2) do
                                            if type(up3) == "number" then
                                                upvalueTargets.indices[k] = true
                                            end
                                        end
                                        log(2, "UpvalueHack: 在 RenderStepped 中找到状态函数")
                                        found = true
                                        break
                                    end
                                end
                            end
                        end
                        if found then break end
                    end
                end
                if found then break end
            end
        end
    end

    if not Internals.setView then
        for _, conn in ipairs(getconnections(R_Caught.OnClientEvent)) do
            if conn.Function then
                local ok, ups = pcall(getupvalues, conn.Function)
                if ok and ups then
                    for i, up in ipairs(ups) do
                        if type(up) == "function" then
                            local ok2, ups2 = pcall(getupvalues, up)
                            if ok2 and ups2 then
                                for j, up2 in ipairs(ups2) do
                                    if up2 == "FREE" or up2 == "CAUGHT" then
                                        Internals.setView = up
                                        log(2, "UpvalueHack: 找到 setView")
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if found then
        Diag.upvalueHack = true
        log(1, "UpvalueHack: 扫描完成,已找到目标函数")
    else
        log(1, "UpvalueHack: 未找到目标函数 (降级模式)")
    end

    return found
end

function UpvalueHack.enable()
    if upvalueActive then return end
    if not hasSetupvalue then return end
    upvalueActive = true

    task.spawn(function()
        while upvalueActive do
            if upvalueTargets.func then
                local ok, ups = pcall(getupvalues, upvalueTargets.func)
                if ok and ups then
                    for idx in pairs(upvalueTargets.indices) do
                        if type(ups[idx]) == "number" and ups[idx] ~= 0 then
                            pcall(setupvalue, upvalueTargets.func, idx, 0)
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    log(1, "UpvalueHack 已启用")
end

function UpvalueHack.disable()
    upvalueActive = false
    log(1, "UpvalueHack 已关闭")
end

Internals = { found = false }

local function discoverInternals()
    Internals.found = false
    if not hasGetconns or not hasGetupvalues then
        log(1, "执行器不支持 getconnections/getupvalues — 降级模式")
        return false
    end

    for _, conn in ipairs(getconnections(R_Caught.OnClientEvent)) do
        if conn.Function then
            local ok, ups = pcall(getupvalues, conn.Function)
            if ok and ups and type(ups[2]) == "function" then
                Internals.setView = ups[2]
                log(2, "找到 setView")
                break
            end
        end
    end

    for _, conn in ipairs(getconnections(R_Item.OnClientEvent)) do
        if conn.Function then
            local ok, ups = pcall(getupvalues, conn.Function)
            if ok and ups and type(ups[1]) == "table" then
                if type(ups[1].completePhoneSearch) == "function" then
                    Internals.phoneApi = ups[1]
                    log(2, "找到 phoneApi")
                    break
                end
            end
        end
    end

    local function scanButtons(parent)
        if not parent then return false end
        for _, gui in ipairs(parent:GetDescendants()) do
            if gui:IsA("GuiButton") and (gui.Name == "A" or gui.Name == "B" or gui.Name == "C" or gui.Name == "D") then
                for _, conn in ipairs(getconnections(gui.Activated)) do
                    if conn.Function then
                        local ok, ups = pcall(getupvalues, conn.Function)
                        if ok and ups and type(ups[1]) == "function" then
                            Internals.submitExamChoice = ups[1]
                            log(2, "找到 submitExamChoice (按钮:", gui.Name, ")")
                            return true
                        end
                    end
                end
            end
        end
        return false
    end
    scanButtons(PlayerGui)
    if not Internals.submitExamChoice then
        for _, cls in ipairs(workspace:GetChildren()) do
            if scanButtons(cls) then break end
        end
    end

    if Config.UpvalueHack then
        UpvalueHack.scan()
    end

    if Internals.setView and Internals.submitExamChoice then
        Internals.found = true
        log(1, "内部函数发现完成 — 全功能就绪")
    elseif Internals.phoneApi then
        Internals.found = true
        log(1, "部分内部函数发现 — 降级模式")
    else
        log(1, "未找到内部函数 — 仅 remote hook + 定时器注入模式")
    end
    return Internals.found
end

Internal = {}

function Internal.getCurrentView()
    if Internals.submitExamChoice then
        local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
        if ok and ups then return ups[3] end
    end
    if LocalPlayer:GetAttribute("TeacherCaughtCameraActive") == true then return "CAUGHT" end
    return nil
end

function Internal.hasAnswer()
    if not Internals.submitExamChoice then return false end
    local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
    return ok and ups and ups[4] == true or false
end

function Internal.getCorrectAnswer()
    if not Internals.submitExamChoice then return nil end
    local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
    return ok and ups and ups[5] or nil
end

function Internal.getAnswersWritten()
    if not Internals.submitExamChoice then return 0 end
    local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
    return ok and ups and ups[11] or 0
end

function Internal.getSearchProgress()
    if not Internals.submitExamChoice then return 0 end
    local ok, ups = pcall(getupvalues, Internals.submitExamChoice)
    return ok and ups and ups[13] or 0
end

function Internal.getGoalAnswers()
    local attr = LocalPlayer:GetAttribute("ClassroomGoalAnswers")
    if type(attr) == "number" then return math.clamp(math.floor(attr + 0.5), 1, 50) end
    return 10
end

function Internal.isInRound()
    if LocalPlayer:GetAttribute("ClassroomInRound") ~= true then return false end
    local active = LocalPlayer:GetAttribute("ClassroomRoundActive")
    if type(active) == "boolean" then return active end
    local endsAt = LocalPlayer:GetAttribute("ClassroomRoundEndsAt")
    if type(endsAt) ~= "number" then endsAt = workspace:GetAttribute("ClassroomRoundEndsAt") end
    if type(endsAt) == "number" then return math.max(0, endsAt - workspace:GetServerTimeNow()) > 0 end
    return false
end

function Internal.getAnswerFromGUI()
    local function scan(parent)
        if not parent then return nil end
        for _, lbl in ipairs(parent:GetDescendants()) do
            if lbl:IsA("TextLabel") then
                local ans = lbl.Text:match("ANSWER:%s*([ABCD])")
                if ans then return ans end
            end
        end
        return nil
    end
    local ans = scan(PlayerGui)
    if ans then return ans end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SurfaceGui") then
            ans = scan(obj)
            if ans then return ans end
        end
    end
    return nil
end

local Search = {}

function Search.instant()
    if Internals.phoneApi and Internals.phoneApi.completePhoneSearch then
        local ok, err = pcall(Internals.phoneApi.completePhoneSearch)
        if ok then
            local ans = Internal.getCorrectAnswer() or Internal.getAnswerFromGUI()
            log(1, "瞬间搜题完成! 答案:", ans or "?")
            notify("搜题完成: " .. (ans or "?"), "green")
            return ans
        end
        log(1, "瞬间搜题失败:", err)
    elseif Internals.submitExamChoice and hasSetupvalue then
        local answers = {"A", "B", "C", "D"}
        local ans = answers[math.random(1, #answers)]
        pcall(setupvalue, Internals.submitExamChoice, 4, true)
        pcall(setupvalue, Internals.submitExamChoice, 5, ans)
        pcall(setupvalue, Internals.submitExamChoice, 13, 100)
        log(1, "瞬间搜题(降级) 答案:", ans)
        return ans
    end
    log(1, "无法执行瞬间搜题")
    notify("搜题失败", "red")
    return nil
end

local Answer = {}

function Answer.submit(answer)
    answer = answer or Internal.getCorrectAnswer() or Internal.getAnswerFromGUI()
    if not answer then
        log(1, "自动答题: 未找到答案")
        return false
    end
    if Internals.submitExamChoice then
        local currentView = Internal.getCurrentView()
        if currentView ~= "EXAM" and hasSetupvalue then
            pcall(setupvalue, Internals.submitExamChoice, 3, "EXAM")
        end
        local ok, err = pcall(Internals.submitExamChoice, answer)
        if ok then
            log(1, "已提交答案:", answer)
            notify("已答题: " .. answer, "green")
            if currentView and currentView ~= "EXAM" and hasSetupvalue then
                task.wait(0.1)
                pcall(setupvalue, Internals.submitExamChoice, 3, currentView)
            end
            return true
        end
        log(1, "答题失败:", err)
    end
    return false
end

local AdSkip = {}
local adConn

function AdSkip.enable()
    if adConn then adConn:Disconnect() end
    adConn = R_Ad.OnClientEvent:Connect(function(action, slotId)
        if action == "Granted" then
            task.wait(0.1)
            pcall(function() R_Ad:FireServer("Release", slotId) end)
            if Internals.phoneApi and Internals.phoneApi.stopPhoneAd then
                pcall(Internals.phoneApi.stopPhoneAd)
            end
            log(1, "已跳过广告")
        end
    end)
end

function AdSkip.disable()
    if adConn then adConn:Disconnect() adConn = nil end
end

local AutoEngine = {}
local autoRunning = false
local autoCycles = 0

function AutoEngine.start()
    if autoRunning then return end
    autoRunning = true
    Config.FullAuto = true
    task.spawn(function()
        log(1, "全自动引擎启动")
        notify("全自动已启动", "accent")
        while autoRunning do
            if not Internal.isInRound() then task.wait(1) continue end
            local written = Internal.getAnswersWritten()
            local goal = Internal.getGoalAnswers()
            if written >= goal then task.wait(2) continue end
            local ans = Search.instant()
            if not ans then task.wait(1) continue end
            task.wait(Config.AutoDelay)
            Answer.submit(ans)
            autoCycles = autoCycles + 1
            task.wait(Config.AutoDelay)
        end
        log(1, "全自动引擎停止 (共执行", autoCycles, "次)")
    end)
end

function AutoEngine.stop()
    autoRunning = false
    Config.FullAuto = false
    notify("全自动已停止", "yellow")
end

function AutoEngine.singleCycle()
    task.spawn(function()
        if not Internal.isInRound() then log(1, "不在回合中") return end
        local ans = Search.instant()
        task.wait(0.2)
        if ans then Answer.submit(ans) end
        autoCycles = autoCycles + 1
    end)
end

local UI = {}
local guiInstance = nil
local miniMode = false

local C = {
    bg       = Color3.fromRGB(12, 14, 22),
    bg2      = Color3.fromRGB(18, 21, 32),
    card     = Color3.fromRGB(24, 28, 42),
    card2    = Color3.fromRGB(30, 35, 52),
    accent   = Color3.fromRGB(0, 220, 255),
    accent2  = Color3.fromRGB(150, 100, 255),
    green    = Color3.fromRGB(60, 230, 130),
    red      = Color3.fromRGB(255, 65, 80),
    yellow   = Color3.fromRGB(255, 210, 70),
    orange   = Color3.fromRGB(255, 140, 50),
    text     = Color3.fromRGB(230, 235, 250),
    textDim  = Color3.fromRGB(130, 140, 165),
    border   = Color3.fromRGB(40, 48, 70),
}

local function getColor(name)
    return C[name] or C.text
end

local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.bg or C.card
    f.BackgroundTransparency = props.transparency or 0
    f.BorderSizePixel = 0
    f.Size = props.size or UDim2.new(1, 0, 0, 30)
    f.Position = props.pos or UDim2.new()
    f.Visible = props.visible ~= false
    f.Parent = props.parent or parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, props.radius or 10)
    c.Parent = f
    if props.stroke then
        local s = Instance.new("UIStroke")
        s.Color = props.strokeColor or C.border
        s.Thickness = props.stroke
        s.Transparency = props.strokeTransparency or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = f
    end
    return f
end

local function makeButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = color or C.card2
    btn.BackgroundTransparency = 0.2
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = (color or C.card2):Lerp(C.accent, 0.3)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = btn

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, (color or C.card2):Lerp(Color3.new(1,1,1), 0.05)),
        ColorSequenceKeypoint.new(1, (color or C.card2):Lerp(Color3.new(0,0,0), 0.3)),
    })
    grad.Rotation = 90
    grad.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = C.text
    lbl.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0, Thickness = 1.5}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.5, Thickness = 1}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.05), {Size = UDim2.new(0.97, 0, 0, 24)}):Play()
        task.wait(0.05)
        TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 26)}):Play()
        if callback then callback() end
    end)
    return btn
end

local function makeToggle(parent, name, desc, default, callback)
    local container = makeFrame(parent, {size = UDim2.new(1, 0, 0, 32), radius = 7, transparency = 0.3})

    local icon = Instance.new("Frame")
    icon.Size = UDim2.fromOffset(24, 24)
    icon.Position = UDim2.fromOffset(4, 4)
    icon.BackgroundColor3 = C.card2
    icon.Parent = container
    local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 5) ic.Parent = icon
    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 1, 0)
    emoji.BackgroundTransparency = 1
    emoji.Text = desc or ""
    emoji.Font = Enum.Font.GothamBold
    emoji.TextSize = 11
    emoji.TextColor3 = C.accent
    emoji.Parent = icon

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 13)
    title.Position = UDim2.fromOffset(32, 4)
    title.BackgroundTransparency = 1
    title.Text = name
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 9
    title.TextColor3 = C.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -80, 0, 10)
    subtitle.Position = UDim2.fromOffset(32, 17)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = ""
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 7
    subtitle.TextColor3 = C.textDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = container

    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(30, 16)
    sw.Position = UDim2.new(1, -36, 0.5, -8)
    sw.BackgroundColor3 = default and C.green or Color3.fromRGB(45, 50, 65)
    sw.Parent = container
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(1, 0) sc.Parent = sw
    local ss = Instance.new("UIStroke")
    ss.Color = default and C.green or C.border
    ss.Thickness = 1
    ss.Transparency = 0.5
    ss.Parent = sw

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = sw
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1, 0) kc.Parent = knob

    local state = default
    local inputStartPos = nil
    local inputStartObj = nil
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            inputStartPos = input.Position
            inputStartObj = input
        end
    end)
    container.InputEnded:Connect(function(input)
        if not inputStartPos then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local delta = (input.Position - inputStartPos).Magnitude
            inputStartPos = nil
            if delta > 10 then return end

            state = not state
            local tween = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            TweenService:Create(sw, tween, {
                BackgroundColor3 = state and C.green or Color3.fromRGB(45, 50, 65)
            }):Play()
            TweenService:Create(ss, tween, {
                Color = state and C.green or C.border
            }):Play()
            TweenService:Create(knob, tween, {
                Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(2, 2)
            }):Play()
            if callback then callback(state) end
        end
    end)

    return container, subtitle
end

local function makeProgressBar(parent, color)
    local bar = makeFrame(parent, {size = UDim2.new(1, 0, 0, 6), bg = C.bg2, radius = 3})
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = color or C.accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 3) fc.Parent = fill
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, (color or C.accent):Lerp(Color3.new(1,1,1), 0.2)),
        ColorSequenceKeypoint.new(1, color or C.accent),
    })
    grad.Parent = fill
    return bar, fill
end

local function makeTab(parent, text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 1, 0)
    btn.BackgroundColor3 = C.bg2
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 9
    btn.TextColor3 = C.textDim
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 0, 0, 2)
    indicator.Position = UDim2.new(0.5, 0, 1, -2)
    indicator.AnchorPoint = Vector2.new(0.5, 0)
    indicator.BackgroundColor3 = C.accent
    indicator.BorderSizePixel = 0
    indicator.Parent = btn

    local glow = Instance.new("UIStroke")
    glow.Color = C.accent
    glow.Thickness = 0
    glow.Transparency = 1
    glow.Parent = btn

    btn.MouseEnter:Connect(function()
        if btn.TextColor3 == C.textDim then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.TextColor3 == C.textDim then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        callback(btn, indicator, glow)
    end)
    return btn, indicator, glow
end

function UI.create()
    pcall(function()
        if CoreGui:FindFirstChild("CheatHub") then CoreGui.CheatHub:Destroy() end
        if PlayerGui:FindFirstChild("CheatHub") then PlayerGui.CheatHub:Destroy() end
    end)

    local guiParent = pcall(function() return CoreGui end) and CoreGui or PlayerGui

    local sg = Instance.new("ScreenGui")
    sg.Name = "CheatHub"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = guiParent
    guiInstance = sg

    local main = makeFrame(sg, {
        size = UDim2.fromOffset(260, 340),
        pos = UDim2.fromScale(0.02, 0.1),
        bg = C.bg,
        radius = 12,
        transparency = 0.05,
    })
    main.Active = true
    main.Draggable = true
    main.ClipsDescendants = true

    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = C.accent
    outerStroke.Thickness = 1.5
    outerStroke.Transparency = 0.4
    outerStroke.Parent = main

    task.spawn(function()
        while sg.Parent do
            TweenService:Create(outerStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.15
            }):Play()
            task.wait(1.5)
            TweenService:Create(outerStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.5
            }):Play()
            task.wait(1.5)
        end
    end)

    local titleBar = makeFrame(main, {size = UDim2.new(1, 0, 0, 30), pos = UDim2.fromOffset(0, 0), bg = C.bg2, radius = 12, transparency = 0.1})

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.fromOffset(22, 22)
    logo.Position = UDim2.fromOffset(6, 4)
    logo.BackgroundTransparency = 1
    logo.Text = "◈"
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 14
    logo.TextColor3 = C.accent
    logo.Parent = titleBar

    task.spawn(function()
        while sg.Parent do
            TweenService:Create(logo, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextColor3 = C.accent2
            }):Play()
            task.wait(2)
            TweenService:Create(logo, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextColor3 = C.accent
            }):Play()
            task.wait(2)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 14)
    title.Position = UDim2.fromOffset(30, 4)
    title.BackgroundTransparency = 1
    title.Text = "CHEATHUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextColor3 = C.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(1, -90, 0, 10)
    ver.Position = UDim2.fromOffset(30, 18)
    ver.BackgroundTransparency = 1
    ver.Text = "Classroom v4.3 · NEON"
    ver.Font = Enum.Font.Gotham
    ver.TextSize = 8
    ver.TextColor3 = C.accent
    ver.TextXAlignment = Enum.TextXAlignment.Left
    ver.Parent = titleBar

    local dots = {}
    for i, info in ipairs({{"S", C.green}, {"A", C.accent}, {"D", C.yellow}}) do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(8, 8)
        dot.Position = UDim2.new(1, -82 + (i-1)*13, 0, 11)
        dot.BackgroundColor3 = info[2]
        dot.Parent = titleBar
        local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = dot
        local dl = Instance.new("TextLabel")
        dl.Size = UDim2.new(1, 0, 1, 0)
        dl.BackgroundTransparency = 1
        dl.Text = info[1]
        dl.Font = Enum.Font.GothamBold
        dl.TextSize = 6
        dl.TextColor3 = C.bg
        dl.Parent = dot
        dots[i] = dot
    end

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(18, 18)
    minBtn.Position = UDim2.new(1, -42, 0, 6)
    minBtn.BackgroundColor3 = C.card2
    minBtn.Text = ""
    minBtn.Parent = titleBar
    local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 5) mc.Parent = minBtn
    local ml = Instance.new("TextLabel")
    ml.Size = UDim2.new(1, 0, 1, 0)
    ml.BackgroundTransparency = 1
    ml.Text = "—"
    ml.Font = Enum.Font.GothamBold
    ml.TextSize = 11
    ml.TextColor3 = C.text
    ml.Parent = minBtn
    minBtn.MouseButton1Click:Connect(function()
        miniMode = not miniMode
        if miniMode then
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(260, 30)
            }):Play()
            statusBar.Visible = false
        else
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(260, 340)
            }):Play()
            statusBar.Visible = true
        end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(18, 18)
    closeBtn.Position = UDim2.new(1, -22, 0, 6)
    closeBtn.BackgroundColor3 = C.red
    closeBtn.Text = ""
    closeBtn.Parent = titleBar
    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 5) cc.Parent = closeBtn
    local cl = Instance.new("TextLabel")
    cl.Size = UDim2.new(1, 0, 1, 0)
    cl.BackgroundTransparency = 1
    cl.Text = "X"
    cl.Font = Enum.Font.GothamBold
    cl.TextSize = 10
    cl.TextColor3 = Color3.fromRGB(255, 255, 255)
    cl.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -10, 0, 20)
    tabBar.Position = UDim2.fromOffset(5, 32)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 1)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -10, 0, 256)
    contentArea.Position = UDim2.fromOffset(5, 54)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = main

    local statusBar = makeFrame(main, {size = UDim2.new(1, -10, 0, 18), pos = UDim2.new(0, 5, 1, -22), bg = C.bg2, radius = 6, transparency = 0.2})
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -10, 1, 0)
    statusText.Position = UDim2.fromOffset(5, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.Code
    statusText.TextSize = 8
    statusText.TextColor3 = C.textDim
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusBar

    local notifyContainer = Instance.new("Frame")
    notifyContainer.Size = UDim2.fromOffset(180, 100)
    notifyContainer.Position = UDim2.new(1, 6, 0, 40)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = main
    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.Padding = UDim.new(0, 4)
    notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifyLayout.Parent = notifyContainer

    local tabs = {}
    local pages = {}

    local function selectTab(name)
        for tabName, page in pairs(pages) do
            if tabName == name then
                page.Visible = true
                TweenService:Create(page, TweenInfo.new(0.2), {Position = UDim2.fromOffset(0, 0)}):Play()
            else
                page.Visible = false
            end
        end
        for tabName, data in pairs(tabs) do
            local isActive = (tabName == name)
            TweenService:Create(data.btn, TweenInfo.new(0.15), {
                TextColor3 = isActive and C.text or C.textDim,
                BackgroundTransparency = isActive and 0 or 0.3,
            }):Play()
            TweenService:Create(data.indicator, TweenInfo.new(0.15), {
                Size = isActive and UDim2.new(0.8, 0, 0, 2) or UDim2.new(0, 0, 0, 2),
            }):Play()
            TweenService:Create(data.glow, TweenInfo.new(0.15), {
                Thickness = isActive and 1 or 0,
                Transparency = isActive and 0.3 or 1,
            }):Play()
        end
    end

    local tabNames = {"总览", "防护", "作弊", "自动", "控制台", "设置"}
    for i, name in ipairs(tabNames) do
        local btn, indicator, glow = makeTab(tabBar, name, i, function()
            selectTab(name)
        end)
        tabs[name] = { btn = btn, indicator = indicator, glow = glow }
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Position = UDim2.fromOffset(0, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = C.border
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = contentArea
        page.ClipsDescendants = true
        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 4)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = page
        local pp = Instance.new("UIPadding")
        pp.PaddingLeft = UDim.new(0, 2)
        pp.PaddingRight = UDim.new(0, 4)
        pp.PaddingTop = UDim.new(0, 2)
        pp.PaddingBottom = UDim.new(0, 4)
        pp.Parent = page
        pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pl.AbsoluteContentSize + 8)
        end)
        pages[name] = page
    end

    local p1 = pages["总览"]

    local sysCard = makeFrame(p1, {size = UDim2.new(1, 0, 0, 86), bg = C.card, radius = 8, transparency = 0.1})
    local sysTitle = Instance.new("TextLabel")
    sysTitle.Size = UDim2.new(1, -12, 0, 14)
    sysTitle.Position = UDim2.fromOffset(8, 5)
    sysTitle.BackgroundTransparency = 1
    sysTitle.Text = "系统状态"
    sysTitle.Font = Enum.Font.GothamBold
    sysTitle.TextSize = 10
    sysTitle.TextColor3 = C.accent
    sysTitle.TextXAlignment = Enum.TextXAlignment.Left
    sysTitle.Parent = sysCard

    local sysGrid = Instance.new("Frame")
    sysGrid.Size = UDim2.new(1, -12, 0, 64)
    sysGrid.Position = UDim2.fromOffset(6, 18)
    sysGrid.BackgroundTransparency = 1
    sysGrid.Parent = sysCard
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -3, 0, 18)
    gridLayout.CellPadding = UDim2.new(0, 3, 0, 2)
    gridLayout.Parent = sysGrid

    local dashItems = {}
    for _, info in ipairs({
        {"hook", "Hook"}, {"inject", "注入"}, {"upval", "Upval"},
        {"conn", "连接"}, {"attr", "属性"}, {"setView", "setView"},
    }) do
        local item = Instance.new("Frame")
        item.BackgroundTransparency = 1
        item.Parent = sysGrid
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(7, 7)
        dot.Position = UDim2.fromOffset(0, 6)
        dot.BackgroundColor3 = C.red
        local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = dot
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -12, 0, 16)
        lbl.Position = UDim2.fromOffset(10, 2)
        lbl.BackgroundTransparency = 1
        lbl.Text = info[2]
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 9
        lbl.TextColor3 = C.textDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = item
        dashItems[info[1]] = {dot = dot, lbl = lbl}
    end

    local quickLabel = Instance.new("TextLabel")
    quickLabel.Size = UDim2.new(1, 0, 0, 16)
    quickLabel.BackgroundTransparency = 1
    quickLabel.Text = "快捷操作"
    quickLabel.Font = Enum.Font.GothamBold
    quickLabel.TextSize = 11
    quickLabel.TextColor3 = C.accent
    quickLabel.TextXAlignment = Enum.TextXAlignment.Left
    quickLabel.Parent = p1

    makeButton(p1, "⚡ 一键搜题 + 答题", C.accent2, function()
        AutoEngine.singleCycle()
    end)

    local autoBtnLabel = "🤖 启动全自动"
    local autoBtn = makeButton(p1, autoBtnLabel, C.card2, function()
        if autoRunning then AutoEngine.stop() else AutoEngine.start() end
    end)

    local metricsCard = makeFrame(p1, {size = UDim2.new(1, 0, 0, 54), bg = C.card, radius = 7, transparency = 0.1})
    local metricsLbl = Instance.new("TextLabel")
    metricsLbl.Size = UDim2.new(1, -10, 1, -4)
    metricsLbl.Position = UDim2.fromOffset(5, 2)
    metricsLbl.BackgroundTransparency = 1
    metricsLbl.Font = Enum.Font.Code
    metricsLbl.TextSize = 7
    metricsLbl.TextColor3 = C.textDim
    metricsLbl.TextXAlignment = Enum.TextXAlignment.Left
    metricsLbl.TextWrapped = true
    metricsLbl.Parent = metricsCard

    local progLabel = Instance.new("TextLabel")
    progLabel.Size = UDim2.new(1, 0, 0, 12)
    progLabel.BackgroundTransparency = 1
    progLabel.Text = "搜索进度"
    progLabel.Font = Enum.Font.GothamBold
    progLabel.TextSize = 9
    progLabel.TextColor3 = C.accent
    progLabel.TextXAlignment = Enum.TextXAlignment.Left
    progLabel.Parent = p1

    local progBar, progFill = makeProgressBar(p1, C.accent)

    local ansProgLabel = Instance.new("TextLabel")
    ansProgLabel.Size = UDim2.new(1, 0, 0, 12)
    ansProgLabel.BackgroundTransparency = 1
    ansProgLabel.Text = "答题进度"
    ansProgLabel.Font = Enum.Font.GothamBold
    ansProgLabel.TextSize = 9
    ansProgLabel.TextColor3 = C.green
    ansProgLabel.TextXAlignment = Enum.TextXAlignment.Left
    ansProgLabel.Parent = p1

    local ansProgBar, ansProgFill = makeProgressBar(p1, C.green)

    local p2 = pages["防护"]

    local shieldCard = makeFrame(p2, {size = UDim2.new(1, 0, 0, 60), bg = C.card, radius = 8, transparency = 0.1})
    local shieldTitle = Instance.new("TextLabel")
    shieldTitle.Size = UDim2.new(1, -12, 0, 14)
    shieldTitle.Position = UDim2.fromOffset(8, 5)
    shieldTitle.BackgroundTransparency = 1
    shieldTitle.Text = "防护层状态"
    shieldTitle.Font = Enum.Font.GothamBold
    shieldTitle.TextSize = 10
    shieldTitle.TextColor3 = C.accent
    shieldTitle.TextXAlignment = Enum.TextXAlignment.Left
    shieldTitle.Parent = shieldCard

    local shieldDetail = Instance.new("TextLabel")
    shieldDetail.Size = UDim2.new(1, -10, 0, 38)
    shieldDetail.Position = UDim2.fromOffset(5, 18)
    shieldDetail.BackgroundTransparency = 1
    shieldDetail.Font = Enum.Font.Code
    shieldDetail.TextSize = 7
    shieldDetail.TextColor3 = C.green
    shieldDetail.TextXAlignment = Enum.TextXAlignment.Left
    shieldDetail.TextWrapped = true
    shieldDetail.Parent = shieldCard

    makeToggle(p2, "反被抓系统 (7层防御)", "🛡", Config.AntiCaught, function(on)
        Config.AntiCaught = on
        if on then AntiCaught.enable() else AntiCaught.disable() end
    end)

    makeToggle(p2, "StateUpdate 拦截 (BLOCK模式)", "🚫", Config.SpoofState, function(on)
        Config.SpoofState = on
        Config.BlockSearching = on
    end)

    local _, progSub = makeToggle(p2, "ProgressUpdate 篡改", "📊", Config.SpoofProgress, function(on)
        Config.SpoofProgress = on
    end)
    if Config.SpoofProgress then
        progSub.Text = "cheat→0  exam→0  (保留view/action/search)"
        progSub.TextColor3 = C.green
    end

    makeToggle(p2, "视角伪装 (CHEAT→FREE)", "👁", Config.SpoofView, function(on)
        Config.SpoofView = on
        if on then
            notify("警告: 视角伪装可能导致答题/作弊界面无法打开", "yellow")
        end
    end)

    makeToggle(p2, "定时器注入 (不依赖hook)", "💉", Config.CleanInject, function(on)
        Config.CleanInject = on
        if on then CleanInjector.enable() else CleanInjector.disable() end
    end)

    makeToggle(p2, "Upvalue 操控", "🔧", Config.UpvalueHack, function(on)
        Config.UpvalueHack = on
        if on then UpvalueHack.enable() else UpvalueHack.disable() end
    end)

    makeToggle(p2, "自动跳广告", "📱", Config.AutoAdSkip, function(on)
        Config.AutoAdSkip = on
        if on then AdSkip.enable() else AdSkip.disable() end
    end)

    local statsCard = makeFrame(p2, {size = UDim2.new(1, 0, 0, 60), bg = C.card, radius = 8, transparency = 0.1})
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, -10, 0, 13)
    statsTitle.Position = UDim2.fromOffset(5, 4)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "拦截统计"
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextSize = 9
    statsTitle.TextColor3 = C.accent
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left
    statsTitle.Parent = statsCard

    local statsLbl = Instance.new("TextLabel")
    statsLbl.Size = UDim2.new(1, -10, 0, 40)
    statsLbl.Position = UDim2.fromOffset(5, 17)
    statsLbl.BackgroundTransparency = 1
    statsLbl.Font = Enum.Font.Code
    statsLbl.TextSize = 7
    statsLbl.TextColor3 = C.textDim
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.TextWrapped = true
    statsLbl.Parent = statsCard

    local blockBar, blockFill = makeProgressBar(p2, C.accent2)

    local p3 = pages["作弊"]

    local ansCard = makeFrame(p3, {size = UDim2.new(1, 0, 0, 68), bg = C.card, radius = 8, transparency = 0.1})
    local ansTitle = Instance.new("TextLabel")
    ansTitle.Size = UDim2.new(1, -12, 0, 14)
    ansTitle.Position = UDim2.fromOffset(8, 6)
    ansTitle.BackgroundTransparency = 1
    ansTitle.Text = "当前答案"
    ansTitle.Font = Enum.Font.GothamBold
    ansTitle.TextSize = 10
    ansTitle.TextColor3 = C.accent
    ansTitle.TextXAlignment = Enum.TextXAlignment.Left
    ansTitle.Parent = ansCard

    local ansDisplay = Instance.new("TextLabel")
    ansDisplay.Size = UDim2.fromOffset(44, 44)
    ansDisplay.Position = UDim2.fromOffset(6, 18)
    ansDisplay.BackgroundColor3 = C.card2
    ansDisplay.BackgroundTransparency = 0.3
    ansDisplay.Text = "?"
    ansDisplay.Font = Enum.Font.GothamBlack
    ansDisplay.TextSize = 24
    ansDisplay.TextColor3 = C.yellow
    ansDisplay.Parent = ansCard
    local adc = Instance.new("UICorner") adc.CornerRadius = UDim.new(0, 8) adc.Parent = ansDisplay
    local ads = Instance.new("UIStroke")
    ads.Color = C.yellow
    ads.Thickness = 1
    ads.Transparency = 0.5
    ads.Parent = ansDisplay

    local ansInfo = Instance.new("TextLabel")
    ansInfo.Size = UDim2.new(1, -58, 0, 42)
    ansInfo.Position = UDim2.fromOffset(56, 18)
    ansInfo.BackgroundTransparency = 1
    ansInfo.Font = Enum.Font.Code
    ansInfo.TextSize = 7
    ansInfo.TextColor3 = C.textDim
    ansInfo.TextXAlignment = Enum.TextXAlignment.Left
    ansInfo.TextWrapped = true
    ansInfo.Parent = ansCard

    makeToggle(p3, "瞬间搜题", "⚡", Config.InstantSearch, function(on)
        Config.InstantSearch = on
    end)
    makeToggle(p3, "自动答题", "✓", Config.AutoAnswer, function(on)
        Config.AutoAnswer = on
    end)

    makeButton(p3, "⚡ 搜题 + 答题", C.accent2, function()
        AutoEngine.singleCycle()
    end)

    makeButton(p3, "🔍 仅搜题", C.card2, function()
        Search.instant()
    end)

    local viewLabel = Instance.new("TextLabel")
    viewLabel.Size = UDim2.new(1, 0, 0, 16)
    viewLabel.BackgroundTransparency = 1
    viewLabel.Text = "视角切换"
    viewLabel.Font = Enum.Font.GothamBold
    viewLabel.TextSize = 10
    viewLabel.TextColor3 = C.accent
    viewLabel.TextXAlignment = Enum.TextXAlignment.Left
    viewLabel.Parent = p3

    local viewContainer = Instance.new("Frame")
    viewContainer.Size = UDim2.new(1, 0, 0, 28)
    viewContainer.BackgroundTransparency = 1
    viewContainer.Parent = p3
    local vLayout = Instance.new("UIListLayout")
    vLayout.FillDirection = Enum.FillDirection.Horizontal
    vLayout.Padding = UDim.new(0, 3)
    vLayout.Parent = viewContainer

    for _, view in ipairs({"FREE", "CHEAT", "EXAM"}) do
        local vb = Instance.new("TextButton")
        vb.BackgroundColor3 = C.card2
        vb.BackgroundTransparency = 0.2
        vb.Text = view
        vb.Font = Enum.Font.GothamMedium
        vb.TextSize = 9
        vb.TextColor3 = C.text
        vb.AutoButtonColor = false
        vb.Parent = viewContainer
        local vc = Instance.new("UICorner") vc.CornerRadius = UDim.new(0, 7) vc.Parent = vb
        local vs = Instance.new("UIStroke")
        vs.Color = C.border
        vs.Thickness = 1
        vs.Parent = vb
        vb.LayoutOrder = ({FREE=1, CHEAT=2, EXAM=3})[view]
        vb.Size = UDim2.new(0.32, 0, 1, 0)

        vb.MouseButton1Click:Connect(function()
            if Internals.setView then
                pcall(Internals.setView, view)
                notify("视角: " .. view, "accent")
            else
                notify("未找到 setView", "red")
            end
        end)
    end

    local p4 = pages["自动"]

    local autoCard = makeFrame(p4, {size = UDim2.new(1, 0, 0, 58), bg = C.card, radius = 8, transparency = 0.1})
    local autoStatus = Instance.new("TextLabel")
    autoStatus.Size = UDim2.new(1, -12, 1, 0)
    autoStatus.Position = UDim2.fromOffset(8, 0)
    autoStatus.BackgroundTransparency = 1
    autoStatus.Font = Enum.Font.Code
    autoStatus.TextSize = 10
    autoStatus.TextColor3 = C.textDim
    autoStatus.TextXAlignment = Enum.TextXAlignment.Left
    autoStatus.TextWrapped = true
    autoStatus.Parent = autoCard

    makeToggle(p4, "全自动模式", "🤖", Config.FullAuto, function(on)
        Config.FullAuto = on
        if on then AutoEngine.start() else AutoEngine.stop() end
    end)

    local speedCard = makeFrame(p4, {size = UDim2.new(1, 0, 0, 48), bg = C.card, radius = 8, transparency = 0.1})
    local speedLbl = Instance.new("TextLabel")
    speedLbl.Size = UDim2.new(1, -12, 0, 14)
    speedLbl.Position = UDim2.fromOffset(8, 6)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "循环间隔: " .. tostring(Config.AutoDelay) .. "s"
    speedLbl.Font = Enum.Font.GothamMedium
    speedLbl.TextSize = 11
    speedLbl.TextColor3 = C.text
    speedLbl.TextXAlignment = Enum.TextXAlignment.Left
    speedLbl.Parent = speedCard

    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(1, -16, 0, 26)
    slider.Position = UDim2.fromOffset(8, 22)
    slider.BackgroundColor3 = C.card2
    slider.BackgroundTransparency = 0.2
    slider.Text = tostring(Config.AutoDelay)
    slider.Font = Enum.Font.Code
    slider.TextSize = 11
    slider.TextColor3 = C.accent
    slider.Parent = speedCard
    local slc = Instance.new("UICorner") slc.CornerRadius = UDim.new(0, 7) slc.Parent = slider
    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val and val >= 0.1 and val <= 5 then
            Config.AutoDelay = val
            speedLbl.Text = "循环间隔: " .. tostring(val) .. "s"
        else
            slider.Text = tostring(Config.AutoDelay)
        end
    end)

    local injCard = makeFrame(p4, {size = UDim2.new(1, 0, 0, 48), bg = C.card, radius = 8, transparency = 0.1})
    local injLbl = Instance.new("TextLabel")
    injLbl.Size = UDim2.new(1, -12, 0, 14)
    injLbl.Position = UDim2.fromOffset(8, 6)
    injLbl.BackgroundTransparency = 1
    injLbl.Text = "注入间隔: " .. tostring(Config.InjectInterval) .. "s"
    injLbl.Font = Enum.Font.GothamMedium
    injLbl.TextSize = 11
    injLbl.TextColor3 = C.text
    injLbl.TextXAlignment = Enum.TextXAlignment.Left
    injLbl.Parent = injCard

    local injSlider = Instance.new("TextBox")
    injSlider.Size = UDim2.new(1, -16, 0, 26)
    injSlider.Position = UDim2.fromOffset(8, 22)
    injSlider.BackgroundColor3 = C.card2
    injSlider.BackgroundTransparency = 0.2
    injSlider.Text = tostring(Config.InjectInterval)
    injSlider.Font = Enum.Font.Code
    injSlider.TextSize = 11
    injSlider.TextColor3 = C.accent
    injSlider.Parent = injCard
    local ilc = Instance.new("UICorner") ilc.CornerRadius = UDim.new(0, 7) ilc.Parent = injSlider
    injSlider.FocusLost:Connect(function()
        local val = tonumber(injSlider.Text)
        if val and val >= 0.05 and val <= 1 then
            Config.InjectInterval = val
            injLbl.Text = "注入间隔: " .. tostring(val) .. "s"
        else
            injSlider.Text = tostring(Config.InjectInterval)
        end
    end)

    makeButton(p4, "▶ 执行单次循环", C.accent2, function()
        AutoEngine.singleCycle()
    end)

    makeButton(p4, "■ 停止全自动", C.red, function()
        AutoEngine.stop()
    end)

    makeButton(p4, "🔄 重新发现内部函数", C.card2, function()
        discoverInternals()
        if Config.UpvalueHack then UpvalueHack.scan() end
        if Config.AntiCaught then AntiCaught.tryHookSetView() end
        notify("重新扫描完成", "accent")
    end)

    local p5 = pages["控制台"]

    local cmdContainer = makeFrame(p5, {size = UDim2.new(1, 0, 0, 30), bg = C.card, radius = 7, transparency = 0.2})
    local cmdInput = Instance.new("TextBox")
    cmdInput.Size = UDim2.new(1, -12, 0, 24)
    cmdInput.Position = UDim2.fromOffset(6, 3)
    cmdInput.BackgroundTransparency = 1
    cmdInput.Text = ""
    cmdInput.PlaceholderText = "输入命令... (help 查看帮助)"
    cmdInput.PlaceholderColor3 = C.textDim
    cmdInput.Font = Enum.Font.Code
    cmdInput.TextSize = 10
    cmdInput.TextColor3 = C.accent
    cmdInput.TextXAlignment = Enum.TextXAlignment.Left
    cmdInput.Parent = cmdContainer

    local cmdHint = Instance.new("TextLabel")
    cmdHint.Size = UDim2.new(1, 0, 0, 14)
    cmdHint.BackgroundTransparency = 1
    cmdHint.Text = "命令: search answer auto stop shield inject clear view help"
    cmdHint.Font = Enum.Font.Code
    cmdHint.TextSize = 8
    cmdHint.TextColor3 = C.textDim
    cmdHint.TextXAlignment = Enum.TextXAlignment.Left
    cmdHint.TextWrapped = true
    cmdHint.Parent = p5

    local logCard = makeFrame(p5, {size = UDim2.new(1, 0, 0, 180), bg = Color3.fromRGB(8, 10, 16), radius = 7})
    local logStroke = Instance.new("UIStroke")
    logStroke.Color = C.border
    logStroke.Thickness = 1
    logStroke.Parent = logCard

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -8, 1, -8)
    logScroll.Position = UDim2.fromOffset(4, 4)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 3
    logScroll.ScrollBarImageColor3 = C.border
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Parent = logCard
    local logLayout = Instance.new("UIListLayout")
    logLayout.Padding = UDim.new(0, 1)
    logLayout.Parent = logScroll
    logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        logScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize + 4)
    end)

    local cmdHistory = {}
    local cmdIndex = 0

    local function processCommand(cmd)
        cmd = cmd:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if cmd == "" then return end

        table.insert(cmdHistory, cmd)
        cmdIndex = #cmdHistory

        log(1, "> " .. cmd)

        if cmd == "help" then
            log(1, "可用命令:")
            log(1, "  search    - 瞬间搜题")
            log(1, "  answer    - 自动答题")
            log(1, "  auto      - 启动全自动")
            log(1, "  stop      - 停止全自动")
            log(1, "  shield    - 切换反被抓")
            log(1, "  inject    - 切换定时器注入")
            log(1, "  clear     - 清空日志")
            log(1, "  view X    - 切换视角 (FREE/CHEAT/EXAM)")
            log(1, "  diag      - 运行诊断")
            log(1, "  stats     - 查看统计")
        elseif cmd == "search" then
            Search.instant()
        elseif cmd == "answer" then
            Answer.submit()
        elseif cmd == "auto" then
            AutoEngine.start()
        elseif cmd == "stop" then
            AutoEngine.stop()
        elseif cmd == "shield" then
            Config.AntiCaught = not Config.AntiCaught
            if Config.AntiCaught then AntiCaught.enable() else AntiCaught.disable() end
        elseif cmd == "inject" then
            Config.CleanInject = not Config.CleanInject
            if Config.CleanInject then CleanInjector.enable() else CleanInjector.disable() end
        elseif cmd == "clear" then
            for _, child in ipairs(logScroll:GetChildren()) do
                if child:IsA("TextLabel") then child:Destroy() end
            end
            logQueue = {}
        elseif cmd:sub(1, 5) == "view " then
            local view = cmd:sub(6):upper()
            if Internals.setView then
                pcall(Internals.setView, view)
                log(1, "视角切换:", view)
            else
                log(1, "未找到 setView")
            end
        elseif cmd == "diag" then
            log(1, "=== 诊断报告 ===")
            log(1, "hookmetamethod:", Diag.hookmeta and "OK" or "FAIL")
            log(1, "hookfunction:", Diag.hookfunc and "OK" or "FAIL")
            log(1, "getconnections:", Diag.getconns and "OK" or "FAIL")
            log(1, "getupvalues:", Diag.getupvalues and "OK" or "FAIL")
            log(1, "namecallBlock:", Diag.namecallBlock and "OK" or "FAIL")
            log(1, "cleanInject:", Diag.cleanInject and "OK" or "FAIL")
            log(1, "upvalueHack:", Diag.upvalueHack and "OK" or "FAIL")
            log(1, "attrReset:", Diag.attrReset and "OK" or "FAIL")
            log(1, "connDisable:", Diag.connDisable and "OK" or "FAIL")
            log(1, "setViewHook:", Diag.setViewHook and "OK" or "FAIL")
        elseif cmd == "stats" then
            local s = RemoteGuard.getStats()
            local ci = CleanInjector.getStats()
            log(1, "=== 统计 ===")
            log(1, string.format("State拦截: %d  Look: %d  View: %d", s.state, s.look, s.view))
            log(1, string.format("Progress篡改: %d  BLOCK: %d", s.progress, s.blocked))
            log(1, string.format("注入次数: %d  注入活跃: %s", ci.count, ci.active and "是" or "否"))
            log(1, string.format("自动循环: %d  自动状态: %s", autoCycles, autoRunning and "运行" or "停止"))
        else
            log(1, "未知命令:", cmd, "(输入 help 查看帮助)")
        end
    end

    cmdInput.FocusLost:Connect(function(enter)
        if enter and cmdInput.Text ~= "" then
            processCommand(cmdInput.Text)
            cmdInput.Text = ""
        end
        cmdInput:CaptureFocus()
    end)

    cmdInput.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Up then
            if cmdIndex > 1 then
                cmdIndex = cmdIndex - 1
                cmdInput.Text = cmdHistory[cmdIndex] or ""
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if cmdIndex < #cmdHistory then
                cmdIndex = cmdIndex + 1
                cmdInput.Text = cmdHistory[cmdIndex] or ""
            else
                cmdInput.Text = ""
            end
        end
    end)

    makeButton(p5, "清空日志", C.card2, function()
        for _, child in ipairs(logScroll:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        logQueue = {}
    end)

    local p6 = pages["设置"]

    local keybindCard = makeFrame(p6, {size = UDim2.new(1, 0, 0, 72), bg = C.card, radius = 8, transparency = 0.1})
    local kbTitle = Instance.new("TextLabel")
    kbTitle.Size = UDim2.new(1, -12, 0, 14)
    kbTitle.Position = UDim2.fromOffset(8, 6)
    kbTitle.BackgroundTransparency = 1
    kbTitle.Text = "快捷键"
    kbTitle.Font = Enum.Font.GothamBold
    kbTitle.TextSize = 10
    kbTitle.TextColor3 = C.accent
    kbTitle.TextXAlignment = Enum.TextXAlignment.Left
    kbTitle.Parent = keybindCard

    local kbText = Instance.new("TextLabel")
    kbText.Size = UDim2.new(1, -12, 0, 58)
    kbText.Position = UDim2.fromOffset(8, 22)
    kbText.BackgroundTransparency = 1
    kbText.Font = Enum.Font.Code
    kbText.TextSize = 10
    kbText.TextColor3 = C.textDim
    kbText.TextXAlignment = Enum.TextXAlignment.Left
    kbText.TextWrapped = true
    kbText.Text = "RightShift  显示/隐藏面板\nF8          单次搜题+答题\nF9          全自动开关\nEnter       控制台发送命令"
    kbText.Parent = keybindCard

    local diagCard = makeFrame(p6, {size = UDim2.new(1, 0, 0, 132), bg = C.card, radius = 8, transparency = 0.1})
    local diagTitle = Instance.new("TextLabel")
    diagTitle.Size = UDim2.new(1, -12, 0, 14)
    diagTitle.Position = UDim2.fromOffset(8, 5)
    diagTitle.BackgroundTransparency = 1
    diagTitle.Text = "执行器诊断"
    diagTitle.Font = Enum.Font.GothamBold
    diagTitle.TextSize = 10
    diagTitle.TextColor3 = C.accent
    diagTitle.TextXAlignment = Enum.TextXAlignment.Left
    diagTitle.Parent = diagCard

    local diagText = Instance.new("TextLabel")
    diagText.Size = UDim2.new(1, -12, 0, 110)
    diagText.Position = UDim2.fromOffset(8, 20)
    diagText.BackgroundTransparency = 1
    diagText.Font = Enum.Font.Code
    diagText.TextSize = 7
    diagText.TextColor3 = C.textDim
    diagText.TextXAlignment = Enum.TextXAlignment.Left
    diagText.TextWrapped = true
    diagText.Parent = diagCard

    local aboutCard = makeFrame(p6, {size = UDim2.new(1, 0, 0, 132), bg = C.card, radius = 8, transparency = 0.1})
    local aboutText = Instance.new("TextLabel")
    aboutText.Size = UDim2.new(1, -12, 1, 0)
    aboutText.Position = UDim2.fromOffset(8, 0)
    aboutText.BackgroundTransparency = 1
    aboutText.Font = Enum.Font.Code
    aboutText.TextSize = 7
    aboutText.TextColor3 = C.textDim
    aboutText.TextXAlignment = Enum.TextXAlignment.Left
    aboutText.TextYAlignment = Enum.TextYAlignment.Top
    aboutText.TextWrapped = true
    aboutText.Text = [[
CheatHub Classroom v4.3 NEON
━━━━━━━━━━━━━━━━━━━━━━━━━━
v4.3: 缩小UI 260x340
v4.2: 修复答题/作弊键秒关
· 保留真实action/view,不发IDLE
· 修复UI重叠/滚动/文字溢出
v4.0 核心改进:
· 定时器注入 (不依赖hook的防护层)
· Upvalue操控 (从源头清零作弊数据)
· 7层防御 + 诊断系统
· 霓虹UI + 命令控制台
]]
    aboutText.Parent = aboutCard

    makeButton(p6, "🔄 运行诊断", C.accent2, function()
        UpvalueHack.scan()
        discoverInternals()
        notify("诊断完成", "accent")
    end)

    makeButton(p6, "重新加载脚本", C.card2, function()
        notify("请在执行器中重新运行", "yellow")
    end)

    selectTab("总览")

    task.spawn(function()
        while sg.Parent do
            local view = Internal.getCurrentView() or "?"
            local written = Internal.getAnswersWritten()
            local goal = Internal.getGoalAnswers()
            local inRound = Internal.isInRound()
            local stats = RemoteGuard.getStats()
            local ci = CleanInjector.getStats()

            statusText.Text = string.format(
                "● %s | V:%s | %d/%d | S:%d P:%d I:%d",
                inRound and "回合中" or "大厅",
                view, written, goal,
                stats.state, stats.progress, ci.count
            )

            metricsLbl.Text = string.format(
                "视角: %s  |  回合: %s\n已答: %d/%d  |  搜索进度: %.0f%%\n注入: %d次  |  循环: %d次\n答案: %s  |  已搜: %s",
                view, inRound and "是" or "否",
                written, goal, Internal.getSearchProgress(),
                ci.count, autoCycles,
                Internal.getCorrectAnswer() or Internal.getAnswerFromGUI() or "?",
                Internal.hasAnswer() and "是" or "否"
            )

            local searchProg = Internal.getSearchProgress() / 100
            TweenService:Create(progFill, TweenInfo.new(0.2), {Size = UDim2.fromScale(math.clamp(searchProg, 0, 1), 1)}):Play()

            local ansProg = goal > 0 and written / goal or 0
            TweenService:Create(ansProgFill, TweenInfo.new(0.2), {Size = UDim2.fromScale(math.clamp(ansProg, 0, 1), 1)}):Play()

            local ans = Internal.getCorrectAnswer() or Internal.getAnswerFromGUI()
            if ans then
                ansDisplay.Text = ans
                ansDisplay.TextColor3 = C.green
                ads.Color = C.green
            else
                ansDisplay.Text = "?"
                ansDisplay.TextColor3 = C.yellow
                ads.Color = C.yellow
            end
            ansInfo.Text = string.format(
                "已搜到: %s\n已答: %d/%d\n搜索进度: %.0f%%",
                Internal.hasAnswer() and "是" or "否",
                written, goal,
                Internal.getSearchProgress()
            )

            local activeLayers = 0
            local totalLayers = 7
            if Diag.namecallBlock then activeLayers = activeLayers + 1 end
            if Diag.cleanInject then activeLayers = activeLayers + 1 end
            if Diag.upvalueHack then activeLayers = activeLayers + 1 end
            if Diag.connDisable then activeLayers = activeLayers + 1 end
            if Diag.attrReset then activeLayers = activeLayers + 1 end
            if Diag.setViewHook then activeLayers = activeLayers + 1 end
            if Diag.hookmeta then activeLayers = activeLayers + 1 end

            shieldDetail.Text = string.format(
                "活跃: %d/%d 层  |  hookmeta: %s\ninject: %s  upval: %s  conn: %s\nattr: %s  setView: %s",
                activeLayers, totalLayers,
                Diag.hookmeta and "OK" or "X",
                Diag.cleanInject and "OK" or "X",
                Diag.upvalueHack and "OK" or "X",
                Diag.connDisable and "OK" or "X",
                Diag.attrReset and "OK" or "X",
                Diag.setViewHook and "OK" or "X"
            )

            statsLbl.Text = string.format(
                "State: %d (BLOCK:%d)\nLook: %d  View: %d\nProgress: %d  注入: %d",
                stats.state, stats.blocked,
                stats.look, stats.view,
                stats.progress, ci.count
            )

            local blockPct = math.clamp((stats.state + stats.progress) / 20, 0, 1)
            TweenService:Create(blockFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(blockPct, 1)}):Play()

            autoStatus.Text = string.format(
                "状态: %s\n循环: %d  间隔: %.1fs\n注入: %d次 (%.2fs)\n内部函数: %s",
                autoRunning and "运行中 ●" or "已停止 ○",
                autoCycles, Config.AutoDelay,
                ci.count, Config.InjectInterval,
                Internals.found and "已找到" or "未找到"
            )

            if autoBtn then
                autoBtn:FindFirstChild("TextLabel").Text = autoRunning and "■ 停止全自动" or "🤖 启动全自动"
            end

            local function updateDot(item, active)
                if item then
                    TweenService:Create(item.dot, TweenInfo.new(0.2), {
                        BackgroundColor3 = active and C.green or C.red
                    }):Play()
                    item.lbl.TextColor3 = active and C.text or C.textDim
                end
            end
            updateDot(dashItems.hook, Diag.hookmeta)
            updateDot(dashItems.inject, Diag.cleanInject)
            updateDot(dashItems.upval, Diag.upvalueHack)
            updateDot(dashItems.conn, Diag.connDisable)
            updateDot(dashItems.attr, Diag.attrReset)
            updateDot(dashItems.setView, Diag.setViewHook)

            diagText.Text = string.format(
                "hookmetamethod: %s  hookfunction: %s\ngetconnections: %s  getupvalues: %s\nsetupvalue: %s\n━━━ 防护层 ━━━\nnamecallBlock: %s\ncleanInject: %s\nupvalueHack: %s\nconnDisable: %s\nattrReset: %s\nsetViewHook: %s",
                hasHookmeta and "✓" or "✗", hasHookfunc and "✓" or "✗",
                hasGetconns and "✓" or "✗", hasGetupvalues and "✓" or "✗",
                hasSetupvalue and "✓" or "✗",
                Diag.namecallBlock and "✓" or "✗",
                Diag.cleanInject and "✓" or "✗",
                Diag.upvalueHack and "✓" or "✗",
                Diag.connDisable and "✓" or "✗",
                Diag.attrReset and "✓" or "✗",
                Diag.setViewHook and "✓" or "✗"
            )

            local logChildren = logScroll:GetChildren()
            local logCount = 0
            for _, c in ipairs(logChildren) do if c:IsA("TextLabel") then logCount = logCount + 1 end end
            if #logQueue > logCount then
                for i = math.max(1, #logQueue - 80), #logQueue do
                    if not logQueue[i]._displayed then
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 0, 14)
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.Code
                        lbl.TextSize = 9
                        if logQueue[i].level >= 2 then
                            lbl.TextColor3 = C.textDim
                        elseif logQueue[i].text:find("BLOCK") or logQueue[i].text:find("拦截") then
                            lbl.TextColor3 = C.accent2
                        elseif logQueue[i].text:find("完成") or logQueue[i].text:find("成功") or logQueue[i].text:find("启用") then
                            lbl.TextColor3 = C.green
                        elseif logQueue[i].text:find("失败") or logQueue[i].text:find("错误") then
                            lbl.TextColor3 = C.red
                        else
                            lbl.TextColor3 = C.text
                        end
                        lbl.TextXAlignment = Enum.TextXAlignment.Left
                        lbl.Text = logQueue[i].text
                        lbl.Parent = logScroll
                        logQueue[i]._displayed = true
                    end
                end
                task.spawn(function()
                    task.wait(0.05)
                    logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
                end)
            end

            for i = #notifyQueue, 1, -1 do
                local n = notifyQueue[i]
                if not n._shown then
                    n._shown = true
                    local toast = makeFrame(notifyContainer, {
                        size = UDim2.new(1, 0, 0, 28),
                        bg = C.card2,
                        radius = 7,
                        transparency = 0.1,
                    })
                    local ts = Instance.new("UIStroke")
                    ts.Color = getColor(n.color)
                    ts.Thickness = 1
                    ts.Transparency = 0.3
                    ts.Parent = toast

                    local tlbl = Instance.new("TextLabel")
                    tlbl.Size = UDim2.new(1, -12, 1, 0)
                    tlbl.Position = UDim2.fromOffset(6, 0)
                    tlbl.BackgroundTransparency = 1
                    tlbl.Text = n.text
                    tlbl.Font = Enum.Font.GothamMedium
                    tlbl.TextSize = 10
                    tlbl.TextColor3 = getColor(n.color)
                    tlbl.TextXAlignment = Enum.TextXAlignment.Left
                    tlbl.Parent = toast

                    toast.Position = UDim2.new(1, 50, 0, 0)
                    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 0, 0, 0)
                    }):Play()

                    task.delay(3, function()
                        TweenService:Create(toast, TweenInfo.new(0.3), {
                            Position = UDim2.new(1, 50, 0, 0),
                            BackgroundTransparency = 1
                        }):Play()
                        task.wait(0.3)
                        toast:Destroy()
                    end)
                end
            end

            task.wait(0.3)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
        elseif input.KeyCode == Enum.KeyCode.F8 then
            AutoEngine.singleCycle()
        elseif input.KeyCode == Enum.KeyCode.F9 then
            if autoRunning then AutoEngine.stop() else AutoEngine.start() end
        end
    end)

    log(1, "GUI 已创建 — RightShift 显示/隐藏, F8 单次, F9 全自动")
    notify("CheatHub v4.0 已启动", "accent")
    return sg
end

local function init()
    log(1, "══════════════════════════════")
    log(1, "  CheatHub Classroom v4.0 NEON")
    log(1, "══════════════════════════════")

    task.wait(1)

    discoverInternals()

    if Config.SpoofState or Config.SpoofProgress or Config.SpoofView then
        RemoteGuard.enable()
    end

    if Config.AntiCaught then
        AntiCaught.enable()
    end

    if Config.CleanInject then
        CleanInjector.enable()
    end

    if Config.UpvalueHack and hasSetupvalue then
        UpvalueHack.enable()
    end

    if Config.AutoAdSkip then
        AdSkip.enable()
    end

    UI.create()

    log(1, "══════════════════════════════")
    log(1, "  诊断报告:")
    log(1, string.format("  hookmetamethod: %s", hasHookmeta and "✓ 可用" or "✗ 不可用"))
    log(1, string.format("  hookfunction: %s", hasHookfunc and "✓ 可用" or "✗ 不可用"))
    log(1, string.format("  getconnections: %s", hasGetconns and "✓ 可用" or "✗ 不可用"))
    log(1, string.format("  getupvalues: %s", hasGetupvalues and "✓ 可用" or "✗ 不可用"))
    log(1, string.format("  setupvalue: %s", hasSetupvalue and "✓ 可用" or "✗ 不可用"))
    if not hasHookmeta then
        log(1, "  ⚠ hookmetamethod 不可用! namecall 拦截失效")
        log(1, "  ⚠ 依赖定时器注入 + 属性重置 + Upvalue操控")
    end
    log(1, "══════════════════════════════")
    log(1, "  RightShift: 显示/隐藏面板")
    log(1, "  F8: 单次搜题+答题")
    log(1, "  F9: 全自动开关")
    log(1, "  控制台: 输入 help 查看命令")
    log(1, "══════════════════════════════")

    if Config.InstantSearch and Config.AutoAnswer and Internals.found then
        task.wait(2)
        if Internal.isInRound() then
            log(1, "检测到回合中,自动执行一次...")
            AutoEngine.singleCycle()
        end
    end
end

local ok, err = pcall(init)
if not ok then
    warn("[CheatHub] 初始化失败:", err)
end

_G.CheatHub = {
    Config = Config, Internals = Internals, Internal = Internal,
    Search = Search, Answer = Answer, AutoEngine = AutoEngine,
    AntiCaught = AntiCaught, RemoteGuard = RemoteGuard, AdSkip = AdSkip,
    CleanInjector = CleanInjector, UpvalueHack = UpvalueHack,
    Diag = Diag, UI = UI, discoverInternals = discoverInternals,
}

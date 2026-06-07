-- UI Text Collector 实时低卡顿版 v6
-- 优化：事件实时获取 + 低频兜底扫描，减少卡顿

local Players=game:GetService("Players")
local CoreGui=game:GetService("CoreGui")
local Workspace=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local LP=Players.LocalPlayer
local PlayerGui=LP:WaitForChild("PlayerGui")

pcall(function() CoreGui.AutoTextCollectorUI:Destroy() end)
pcall(function() PlayerGui.AutoTextCollectorUI:Destroy() end)

local SG=Instance.new("ScreenGui")
SG.Name="AutoTextCollectorUI"
SG.ResetOnSpawn=false
if gethui then SG.Parent=gethui()
elseif syn and syn.protect_gui then syn.protect_gui(SG); SG.Parent=CoreGui
else SG.Parent=PlayerGui end

local HuiRoot=nil
pcall(function() if gethui then HuiRoot=gethui() end end)
local function AddUniqueRoot(list,root)
    if not root then return end
    for _,v in ipairs(list) do
        if v==root then return end
    end
    table.insert(list,root)
end

-- UIRoots：专门扫 CoreGui / gethui
local UIRoots={}
AddUniqueRoot(UIRoots,CoreGui)
AddUniqueRoot(UIRoots,HuiRoot)

-- WideRoots：第三方UI宽松扫描范围
-- 有些第三方UI不在CoreGui，而在PlayerGui或gethui的独立容器里
local WideRoots={}
AddUniqueRoot(WideRoots,PlayerGui)
AddUniqueRoot(WideRoots,Workspace)
AddUniqueRoot(WideRoots,CoreGui)
AddUniqueRoot(WideRoots,HuiRoot)

local Sections={"全部","PlayerGui","Workspace","CoreGui","RobloxGui","PlayerList","第三方UI"}
local SystemNames={"RobloxGui","PlayerList","Backpack","Chat","BubbleChat","ExperienceChat","TextChatService","TopBar","Topbar","Health","EmotesMenu","Chrome","InspectMenu","PurchasePrompt","ScreenshotHud"}
local IgnoreTexts={["未检测到 UI 文本"]=true}

local CurrentSection="全部"
local AutoRefresh=true
local BlockMode=false
local Minimized=false
local CurrentDisplayText=""
local AutoScrollToBottom=true

local Data,Blocked={},{}
for _,s in ipairs(Sections) do
    Data[s]={Texts={},Map={},AllText="未检测到 UI 文本"}
    Blocked[s]={}
end

local Fav={Texts={},Map={}}
local FavMain,FavScroll,FavLayout,FavStatus
local SectionBtns={}

local function N(class,props,parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end

local function Corner(o,r)
    return N("UICorner",{CornerRadius=UDim.new(0,r or 8)},o)
end

local function Stroke(o,c,t,a)
    return N("UIStroke",{Color=c or Color3.fromRGB(90,90,100),Thickness=t or 1,Transparency=a or .35},o)
end

local function Style(o,r,c)
    o.BorderSizePixel=0
    if c then o.BackgroundColor3=c end
    Corner(o,r or 8)
    Stroke(o)
end

local function Button(txt,color,parent)
    local b=N("TextButton",{
        BackgroundColor3=color,
        Text=txt,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.SourceSansBold,
        TextSize=12,
        AutoButtonColor=true,
        BorderSizePixel=0
    },parent)
    Style(b,7,color)
    return b
end

local function Clean(s)
    s=tostring(s or "")
    s=s:gsub("<[^>]->",""):gsub("\r",""):gsub("^%s+",""):gsub("%s+$","")
    return s
end

local function HasKeyword(str,list)
    str=string.lower(tostring(str or ""))
    for _,k in ipairs(list) do
        k=string.lower(tostring(k or ""))
        if k~="" and string.find(str,k,1,true) then return true end
    end
    return false
end

local function ObjPath(o)
    local t={}
    while o and o~=game do table.insert(t,1,o.Name); o=o.Parent end
    return table.concat(t,"/")
end

local function IsVisible(o)
    while o and o~=game do
        local ok,v=pcall(function() return o.Visible end)
        if ok and v==false then return false end
        o=o.Parent
    end
    return true
end

local function IsSystem(o)
    local p=ObjPath(o)
    return HasKeyword(o.Name,SystemNames) or HasKeyword(p,SystemNames)
end

local function InUIRoots(o)
    for _,root in ipairs(UIRoots) do
        if o:IsDescendantOf(root) then return true end
    end
    return false
end

local function InWideRoots(o)
    for _,root in ipairs(WideRoots) do
        if o:IsDescendantOf(root) then return true end
    end
    return false
end

local function Rebuild(s)
    local d=Data[s]
    if not d then return end
    d.AllText=(#d.Texts>0) and table.concat(d.Texts,"\n") or "未检测到 UI 文本"
end

local function Count(s)
    return Data[s] and #Data[s].Texts or 0
end

local function Status(msg)
    local mode=AutoRefresh and "自动" or "暂停"
    local block=BlockMode and "屏蔽开" or "屏蔽关"
    StatusLabel.Text="状态："..mode.."｜"..CurrentSection.."｜"..Count(CurrentSection).."条｜"..block..(msg and ("｜"..msg) or "")
end

local function EscapeLua(s)
    s=tostring(s or "")
    s=s:gsub("\\","\\\\"):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t"):gsub('"','\\"')
    return s
end

local function BuildLua(name,texts)
    local out={"-- UI文本导出","-- 分区："..tostring(name),"-- 数量："..tostring(#texts),"","return {"}
    for _,v in ipairs(texts) do table.insert(out,'    "'..EscapeLua(v)..'",') end
    table.insert(out,"}")
    return table.concat(out,"\n")
end

local function ExportLua(name,texts,fileName)
    local code=BuildLua(name,texts)
    local copied,saved=false,false
    if setclipboard then setclipboard(code); copied=true
    elseif toclipboard then toclipboard(code); copied=true end
    if writefile then writefile(fileName,code); saved=true end
    if copied and saved then Status("Lua已复制并保存")
    elseif copied then Status("Lua已复制")
    elseif saved then Status("Lua已保存")
    else Status("导出失败：不支持复制/写文件") end
end

local function CopyText(s,msg)
    s=tostring(s or "")
    if setclipboard then setclipboard(s); Status(msg or "已复制")
    elseif toclipboard then toclipboard(s); Status(msg or "已复制")
    else Status("当前环境不支持自动复制") end
end

local function UpdateSectionBtns()
    for s,b in pairs(SectionBtns) do
        b.Text=s.." ["..Count(s).."]"
        b.BackgroundColor3=(s==CurrentSection) and Color3.fromRGB(75,125,215) or Color3.fromRGB(58,58,66)
    end
end

-- 主窗口
local Main=N("Frame",{Size=UDim2.new(0,460,0,350),Position=UDim2.new(.5,-230,.5,-175),BackgroundColor3=Color3.fromRGB(24,24,28),BorderSizePixel=0,Active=true,Draggable=true},SG)
local MainCorner=Corner(Main,12); Stroke(Main,Color3.fromRGB(100,100,110),1,.2)

local Title=N("TextLabel",{BackgroundTransparency=1,Text="UI 文本提取器 - 精简版",TextColor3=Color3.new(1,1,1),Font=Enum.Font.SourceSansBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},Main)
local MinBtn=Button("-",Color3.fromRGB(80,80,88),Main)
local CloseBtn=Button("X",Color3.fromRGB(180,55,60),Main)

local Content=N("Frame",{BackgroundTransparency=1},Main)
local StatusLabel=N("TextLabel",{BackgroundTransparency=1,Text="状态：自动检测中",TextColor3=Color3.fromRGB(200,200,205),Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},Content)
local SectionFrame=N("Frame",{BackgroundColor3=Color3.fromRGB(32,32,38),BorderSizePixel=0},Content); Style(SectionFrame,8)

local Search=N("TextBox",{BackgroundColor3=Color3.fromRGB(38,38,45),TextColor3=Color3.new(1,1,1),PlaceholderText="搜索当前分区文本...",PlaceholderColor3=Color3.fromRGB(155,155,160),Font=Enum.Font.SourceSans,ClearTextOnFocus=false,Text=""},Content); Style(Search,8)
local SearchBtn=Button("搜索",Color3.fromRGB(120,90,180),Content)

local Scroll=N("ScrollingFrame",{BackgroundColor3=Color3.fromRGB(34,34,40),BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollBarThickness=8,ScrollingDirection=Enum.ScrollingDirection.Y,VerticalScrollBarInset=Enum.ScrollBarInset.Always,ScrollBarImageColor3=Color3.fromRGB(170,170,175),ClipsDescendants=true},Content); Style(Scroll,8)
local Layout=N("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},Scroll)

local Bottom=N("Frame",{BackgroundTransparency=1},Content)
local RefreshBtn=Button("刷新",Color3.fromRGB(65,120,200),Bottom)
local CopyBtn=Button("复制",Color3.fromRGB(70,165,90),Bottom)
local AutoBtn=Button("自动",Color3.fromRGB(160,120,60),Bottom)
local BlockBtn=Button("屏蔽",Color3.fromRGB(110,80,150),Bottom)
local FavBtn=Button("收藏",Color3.fromRGB(90,130,210),Bottom)
local ExportBtn=Button("导出",Color3.fromRGB(80,150,160),Bottom)
local ClearBtn=Button("清空",Color3.fromRGB(180,70,70),Bottom)

local Resize=Button("↘",Color3.fromRGB(95,95,105),Main)
Resize.Size=UDim2.new(0,22,0,22); Resize.AnchorPoint=Vector2.new(1,1); Resize.Position=UDim2.new(1,-3,1,-3); Resize.ZIndex=10

local function ResizeCanvas()
    task.defer(function()
        task.wait()
        Scroll.CanvasSize=UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+10)
        if AutoScrollToBottom then
            local maxY=math.max(0,Scroll.CanvasSize.Y.Offset-Scroll.AbsoluteSize.Y)
            Scroll.CanvasPosition=Vector2.new(0,maxY)
        end
    end)
end

local function ClearList()
    for _,o in ipairs(Scroll:GetChildren()) do
        if o:IsA("Frame") or o:IsA("TextButton") then o:Destroy() end
    end
end

local function RemoveFromSection(s,text)
    local d=Data[s]; if not d then return end
    text=Clean(text); d.Map[text]=nil
    for i=#d.Texts,1,-1 do if d.Texts[i]==text then table.remove(d.Texts,i) end end
    Rebuild(s)
end

local function RebuildAll()
    Data["全部"]={Texts={},Map={},AllText="未检测到 UI 文本"}
    for _,s in ipairs(Sections) do
        if s~="全部" then
            for _,t in ipairs(Data[s].Texts) do
                if not Data["全部"].Map[t] then
                    Data["全部"].Map[t]=true
                    table.insert(Data["全部"].Texts,t)
                end
            end
        end
    end
    Rebuild("全部")
end

local function DeleteCurrent(text)
    text=Clean(text)
    if text=="" then return end
    local old=Scroll.CanvasPosition
    if BlockMode then
        if CurrentSection=="全部" then
            for _,s in ipairs(Sections) do Blocked[s][text]=true end
        else
            Blocked[CurrentSection][text]=true; Blocked["全部"][text]=true
        end
    end
    if CurrentSection=="全部" then
        for _,s in ipairs(Sections) do RemoveFromSection(s,text) end
    else
        RemoveFromSection(CurrentSection,text); RebuildAll()
    end
    if Search.Text~="" then
        SearchBtn:Activate()
    end
    -- 直接刷新显示
    task.defer(function()
        local maxY=math.max(0,Scroll.CanvasSize.Y.Offset-Scroll.AbsoluteSize.Y)
        Scroll.CanvasPosition=Vector2.new(0,math.clamp(old.Y,0,maxY))
    end)
    UpdateSectionBtns()
    Status(BlockMode and "已删除并屏蔽" or "已删除")
end

local function FavoriteWindow()
    if FavMain and FavMain.Parent then FavMain.Visible=true end
    if FavMain and FavMain.Parent then return end

    FavMain=N("Frame",{Size=UDim2.new(0,360,0,300),Position=UDim2.new(.5,-180,.5,-150),BackgroundColor3=Color3.fromRGB(24,24,28),BorderSizePixel=0,Active=true,Draggable=true},SG)
    Style(FavMain,12)
    N("TextLabel",{Size=UDim2.new(1,-42,0,32),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text="收藏列表",TextColor3=Color3.new(1,1,1),TextSize=16,Font=Enum.Font.SourceSansBold,TextXAlignment=Enum.TextXAlignment.Left},FavMain)
    local close=Button("X",Color3.fromRGB(180,55,60),FavMain); close.Size=UDim2.new(0,32,0,32); close.Position=UDim2.new(1,-32,0,0)
    FavStatus=N("TextLabel",{Size=UDim2.new(1,-20,0,20),Position=UDim2.new(0,10,0,34),BackgroundTransparency=1,TextColor3=Color3.fromRGB(200,200,205),TextSize=12,Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left},FavMain)
    FavScroll=N("ScrollingFrame",{Size=UDim2.new(1,-20,1,-105),Position=UDim2.new(0,10,0,58),BackgroundColor3=Color3.fromRGB(34,34,40),BorderSizePixel=0,CanvasSize=UDim2.new(),ScrollBarThickness=8,ScrollingDirection=Enum.ScrollingDirection.Y,VerticalScrollBarInset=Enum.ScrollBarInset.Always},FavMain); Style(FavScroll,8)
    FavLayout=N("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},FavScroll)
    local bot=N("Frame",{Size=UDim2.new(1,-20,0,34),Position=UDim2.new(0,10,1,-40),BackgroundTransparency=1},FavMain)
    local copy=Button("复制全部",Color3.fromRGB(70,165,90),bot)
    local export=Button("导出Lua",Color3.fromRGB(80,150,160),bot)
    local clear=Button("清空全部",Color3.fromRGB(180,70,70),bot)
    copy.Size=UDim2.new(.333,-4,1,0); export.Size=UDim2.new(.333,-4,1,0); export.Position=UDim2.new(.333,4,0,0); clear.Size=UDim2.new(.333,-4,1,0); clear.Position=UDim2.new(.666,8,0,0)
    close.MouseButton1Click:Connect(function() FavMain.Visible=false end)
    copy.MouseButton1Click:Connect(function() CopyText((#Fav.Texts>0 and table.concat(Fav.Texts,"\n") or "收藏列表为空"),"已复制收藏") end)
    export.MouseButton1Click:Connect(function() ExportLua("收藏列表",Fav.Texts,"UITextExport_收藏列表.lua") end)
    clear.MouseButton1Click:Connect(function() Fav={Texts={},Map={}}; RefreshFav() end)
end

function RefreshFav()
    if not FavScroll then return end
    for _,o in ipairs(FavScroll:GetChildren()) do if o:IsA("Frame") or o:IsA("TextButton") then o:Destroy() end end
    FavStatus.Text="收藏列表｜共 "..#Fav.Texts.." 条"
    for i,text in ipairs(Fav.Texts) do
        local row=N("Frame",{Size=UDim2.new(1,-12,0,30),BackgroundColor3=Color3.fromRGB(48,48,56),BorderSizePixel=0,LayoutOrder=i},FavScroll); Style(row,6)
        local lab=N("TextButton",{Size=UDim2.new(1,-100,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(245,245,245),TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Text=text},row)
        local del=Button("删除",Color3.fromRGB(180,70,70),row); del.Size=UDim2.new(0,42,0,24); del.Position=UDim2.new(1,-88,.5,-12)
        local cp=Button("复制",Color3.fromRGB(70,165,90),row); cp.Size=UDim2.new(0,42,0,24); cp.Position=UDim2.new(1,-44,.5,-12)
        lab.MouseButton1Click:Connect(function() CopyText(text,"已复制收藏行") end)
        cp.MouseButton1Click:Connect(function() CopyText(text,"已复制收藏行") end)
        del.MouseButton1Click:Connect(function()
            Fav.Map[text]=nil
            for n=#Fav.Texts,1,-1 do if Fav.Texts[n]==text then table.remove(Fav.Texts,n); break end end
            RefreshFav()
        end)
    end
    if #Fav.Texts==0 then
        local e=N("TextButton",{Size=UDim2.new(1,-12,0,30),BackgroundColor3=Color3.fromRGB(48,48,56),TextColor3=Color3.fromRGB(180,180,180),TextSize=13,Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,Text="  收藏列表为空"},FavScroll); Style(e,6)
    end
    task.defer(function() task.wait(); FavScroll.CanvasSize=UDim2.new(0,0,0,FavLayout.AbsoluteContentSize.Y+10) end)
end

local function AddFav(text)
    text=Clean(text)
    if text~="" and not Fav.Map[text] then Fav.Map[text]=true; table.insert(Fav.Texts,text) end
    FavoriteWindow(); RefreshFav(); Status("已添加收藏")
end

local function SetDisplay(text,bottom)
    CurrentDisplayText=text
    ClearList()
    local i=0
    for line in string.gmatch(text.."\n","(.-)\n") do
        line=Clean(line)
        if line~="" then
            i+=1
            local row=N("Frame",{Size=UDim2.new(1,-12,0,31),BackgroundColor3=Color3.fromRGB(48,48,56),BorderSizePixel=0,LayoutOrder=i},Scroll); Style(row,6)
            local shown=(#line>500 and string.sub(line,1,500).."..." or line)
            local lab=N("TextButton",{Size=UDim2.new(1,-150,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(245,245,245),TextSize=13,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Text=shown},row)
            local add=Button("添加",Color3.fromRGB(90,130,210),row); add.Size=UDim2.new(0,42,0,24); add.Position=UDim2.new(1,-138,.5,-12)
            local del=Button("删除",Color3.fromRGB(180,70,70),row); del.Size=UDim2.new(0,42,0,24); del.Position=UDim2.new(1,-92,.5,-12)
            local cp=Button("复制",Color3.fromRGB(70,165,90),row); cp.Size=UDim2.new(0,42,0,24); cp.Position=UDim2.new(1,-46,.5,-12)
            lab.MouseButton1Click:Connect(function() CopyText(line,"已复制当前行") end)
            add.MouseButton1Click:Connect(function() AddFav(line) end)
            del.MouseButton1Click:Connect(function() DeleteCurrent(line); SetDisplay(GetCurrentText(),false) end)
            cp.MouseButton1Click:Connect(function() CopyText(line,"已复制当前行") end)
        end
    end
    if i==0 then local e=N("TextButton",{Size=UDim2.new(1,-12,0,30),BackgroundColor3=Color3.fromRGB(48,48,56),TextColor3=Color3.fromRGB(180,180,180),TextSize=13,Font=Enum.Font.SourceSans,TextXAlignment=Enum.TextXAlignment.Left,Text="  未检测到 UI 文本"},Scroll); Style(e,6) end
    AutoScrollToBottom=bottom and true or false
    ResizeCanvas()
    task.defer(function() task.wait(); AutoScrollToBottom=true end)
end

function GetCurrentText()
    Rebuild(CurrentSection)
    return Data[CurrentSection] and Data[CurrentSection].AllText or "未检测到 UI 文本"
end

local function IgnoreText(t)
    t=Clean(t)
    return t=="" or IgnoreTexts[t]
end

local function Save(s,t)
    t=Clean(t)
    if IgnoreText(t) or (BlockMode and Blocked[s] and Blocked[s][t]) then return false end
    local d=Data[s]; if not d then return false end
    if not d.Map[t] then d.Map[t]=true; table.insert(d.Texts,t); Rebuild(s); return true end
    return false
end

local function SaveFrom(s,t)
    local ok=Save(s,t)
    if ok and s~="全部" then Save("全部",t) end
    return ok
end

local function InSection(o,s)
    if not o or o:IsDescendantOf(SG) or not IsVisible(o) then return false end
    local p=ObjPath(o)
    if s=="PlayerGui" then return o:IsDescendantOf(PlayerGui) end
    if s=="Workspace" then return o:IsDescendantOf(Workspace) end
    if s=="CoreGui" then return InUIRoots(o) end
    if s=="RobloxGui" then return InUIRoots(o) and p:find("RobloxGui",1,true)~=nil end
    if s=="PlayerList" then return InUIRoots(o) and p:find("PlayerList",1,true)~=nil end
    -- 第三方UI改为宽松扫描：PlayerGui / Workspace / CoreGui / gethui 都会尝试
    -- 只排除本脚本UI和明显Roblox系统UI，避免漏掉第三方脚本窗口
    if s=="第三方UI" then return InWideRoots(o) and not IsSystem(o) end
    if s=="全部" then return o:IsDescendantOf(PlayerGui) or o:IsDescendantOf(Workspace) or InUIRoots(o) end
    return false
end

local function ReadObj(o,s)
    if not InSection(o,s) then return 0 end
    local n=0
    for _,prop in ipairs({"Text","ContentText","LocalizedText"}) do
        pcall(function() if o[prop] and SaveFrom(s,o[prop]) then n+=1 end end)
    end
    return n
end

local function ScanContainer(c,s)
    local n=0
    pcall(function()
        for _,o in ipairs(c:GetDescendants()) do
            if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then n+=ReadObj(o,s) end
        end
    end)
    return n
end

local function ScanUIRoots(s)
    local n=0
    for _,root in ipairs(UIRoots) do
        n+=ScanContainer(root,s)
    end
    return n
end

local function ScanWideRoots(s)
    local n=0
    for _,root in ipairs(WideRoots) do
        n+=ScanContainer(root,s)
    end
    return n
end

local function Scan(s)
    local n=0
    if s=="全部" then
        n+=Scan("PlayerGui")
        n+=Scan("Workspace")
        n+=Scan("CoreGui")
        n+=Scan("第三方UI")
    elseif s=="PlayerGui" then n+=ScanContainer(PlayerGui,s)
    elseif s=="Workspace" then n+=ScanContainer(Workspace,s)
    elseif s=="第三方UI" then n+=ScanWideRoots(s)
    else n+=ScanUIRoots(s) end
    Rebuild(s); Rebuild("全部")
    return n
end

local function ScanAllSections()
    local n=0
    n+=Scan("PlayerGui")
    n+=Scan("Workspace")
    n+=Scan("CoreGui")
    n+=Scan("RobloxGui")
    n+=Scan("PlayerList")
    n+=Scan("第三方UI")
    Rebuild("全部")
    return n
end

local function SearchNow()
    local kw=Clean(Search.Text)
    if kw=="" then SetDisplay(GetCurrentText(),false); Scroll.CanvasPosition=Vector2.new(); Status("显示全部"); return end
    local res={}
    for _,v in ipairs(Data[CurrentSection].Texts) do if string.find(string.lower(v),string.lower(kw),1,true) then table.insert(res,v) end end
    SetDisplay(#res>0 and table.concat(res,"\n") or ("没有搜索到包含【"..kw.."】的文本"),false)
    Scroll.CanvasPosition=Vector2.new()
    Status("搜索结果 "..#res.." 条")
end

local function RefreshDisplay(add)
    UpdateSectionBtns()
    if Search.Text~="" then SearchNow()
    else SetDisplay(GetCurrentText(),add and add>0); Status((add and add>0) and ("新增 "..add.." 条") or "暂无新增") end
end

local function ClearCurrent()
    if BlockMode then
        for _,v in ipairs(Data[CurrentSection].Texts) do
            if CurrentSection=="全部" then for _,s in ipairs(Sections) do Blocked[s][v]=true end
            else Blocked[CurrentSection][v]=true; Blocked["全部"][v]=true end
        end
    end
    if CurrentSection=="全部" then
        for _,s in ipairs(Sections) do Data[s]={Texts={},Map={},AllText="未检测到 UI 文本"} end
    else
        Data[CurrentSection]={Texts={},Map={},AllText="未检测到 UI 文本"}
        RebuildAll()
    end
    Search.Text=""; SetDisplay(GetCurrentText(),false); UpdateSectionBtns(); Status(BlockMode and "已清空并屏蔽" or "已清空")
end

for _,s in ipairs(Sections) do
    local b=Button(s.." [0]",Color3.fromRGB(58,58,66),SectionFrame)
    b.MouseButton1Click:Connect(function() CurrentSection=s; Search.Text=""; SetDisplay(GetCurrentText(),false); Scroll.CanvasPosition=Vector2.new(); UpdateSectionBtns(); Status("已切换") end)
    SectionBtns[s]=b
end

local LastSize=Vector2.new(460,350)
local MiniSize=46
local LastPos=nil
local MinW,MinH,MaxW,MaxH=360,270,760,580

local function LayoutUI()
    if Minimized then return end
    local w,h=Main.AbsoluteSize.X,Main.AbsoluteSize.Y
    local tiny=w<380 or h<285
    local compact=w<420 or h<315
    local titleH=tiny and 28 or 32
    local pad=tiny and 5 or 8
    local statusH=tiny and 18 or 20
    local searchH=tiny and 24 or 28
    local btnH=tiny and 28 or 34
    local cols=compact and 3 or 4
    local rows=compact and 3 or 2
    local secH=rows*(tiny and 22 or 25)+6
    Title.Size=UDim2.new(1,-76,0,titleH); Title.Position=UDim2.new(0,pad,0,0); Title.TextSize=tiny and 14 or 16
    MinBtn.Size=UDim2.new(0,titleH,0,titleH); MinBtn.Position=UDim2.new(1,-titleH*2,0,0)
    CloseBtn.Size=UDim2.new(0,titleH,0,titleH); CloseBtn.Position=UDim2.new(1,-titleH,0,0)
    Content.Size=UDim2.new(1,0,1,-titleH); Content.Position=UDim2.new(0,0,0,titleH)
    StatusLabel.Size=UDim2.new(1,-pad*2,0,statusH); StatusLabel.Position=UDim2.new(0,pad,0,0); StatusLabel.TextSize=tiny and 10 or 12
    SectionFrame.Size=UDim2.new(1,-pad*2,0,secH); SectionFrame.Position=UDim2.new(0,pad,0,statusH+2)
    for i,s in ipairs(Sections) do
        local b=SectionBtns[s]; local row=math.floor((i-1)/cols); local col=(i-1)%cols; local bh=tiny and 20 or 23
        b.Size=UDim2.new(1/cols,-5,0,bh); b.Position=UDim2.new(col/cols,3+col,0,3+row*(bh+3)); b.TextSize=tiny and 9 or 11
    end
    local sy=statusH+secH+10; local sbw=tiny and 58 or 72
    Search.Size=UDim2.new(1,-pad*2-sbw-6,0,searchH); Search.Position=UDim2.new(0,pad,0,sy); Search.TextSize=tiny and 11 or 13
    SearchBtn.Size=UDim2.new(0,sbw,0,searchH); SearchBtn.Position=UDim2.new(1,-pad-sbw,0,sy); SearchBtn.TextSize=tiny and 11 or 13
    Bottom.Size=UDim2.new(1,-pad*2,0,btnH); Bottom.Position=UDim2.new(0,pad,1,-btnH-pad)
    local btns={RefreshBtn,CopyBtn,AutoBtn,BlockBtn,FavBtn,ExportBtn,ClearBtn}
    for i,b in ipairs(btns) do b.Size=UDim2.new(1/#btns,-5,1,0); b.Position=UDim2.new((i-1)/#btns,(i-1)*2,0,0); b.TextSize=tiny and 9 or 12 end
    local scrollY=sy+searchH+6
    Scroll.Size=UDim2.new(1,-pad*2,0,math.max(70,h-titleH-scrollY-btnH-pad-6))
    Scroll.Position=UDim2.new(0,pad,0,scrollY)
    Resize.Size=UDim2.new(0,tiny and 18 or 22,0,tiny and 18 or 22); Resize.Position=UDim2.new(1,-3,1,-3)
    ResizeCanvas()
end

RefreshBtn.MouseButton1Click:Connect(function() RefreshDisplay(Scan(CurrentSection)) end)
CopyBtn.MouseButton1Click:Connect(function() CopyText(CurrentDisplayText,"已复制当前显示") end)
AutoBtn.MouseButton1Click:Connect(function() AutoRefresh=not AutoRefresh; AutoBtn.Text=AutoRefresh and "自动" or "暂停"; Status() end)
BlockBtn.MouseButton1Click:Connect(function()
    BlockMode=not BlockMode; BlockBtn.Text=BlockMode and "屏蔽开" or "屏蔽"
    if not BlockMode then for _,s in ipairs(Sections) do Blocked[s]={} end end
    Status(BlockMode and "屏蔽文本已开启" or "屏蔽已关闭")
end)
FavBtn.MouseButton1Click:Connect(function() FavoriteWindow(); RefreshFav(); Status("已打开收藏栏") end)
ExportBtn.MouseButton1Click:Connect(function()
    local safe=tostring(CurrentSection):gsub('[\\/:*?"<>|]',"_")
    ExportLua(CurrentSection,Data[CurrentSection].Texts,"UITextExport_"..safe..".lua")
end)
SearchBtn.MouseButton1Click:Connect(SearchNow)
Search.FocusLost:Connect(function(e) if e then SearchNow() end end)
ClearBtn.MouseButton1Click:Connect(ClearCurrent)
CloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

MinBtn.MouseButton1Click:Connect(function()
    Minimized=not Minimized
    if Minimized then
        LastSize=Vector2.new(Main.AbsoluteSize.X,Main.AbsoluteSize.Y); LastPos=Main.Position
        Content.Visible=false; Title.Visible=false; CloseBtn.Visible=false; Resize.Visible=false
        Main.Size=UDim2.new(0,MiniSize,0,MiniSize); MainCorner.CornerRadius=UDim.new(1,0)
        MinBtn.Size=UDim2.new(1,0,1,0); MinBtn.Position=UDim2.new(); MinBtn.Text="+"; MinBtn.TextSize=24; MinBtn.BackgroundColor3=Color3.fromRGB(75,125,215); MinBtn.ZIndex=20
    else
        Content.Visible=true; Title.Visible=true; CloseBtn.Visible=true; Resize.Visible=true
        Main.Size=UDim2.new(0,LastSize.X,0,LastSize.Y); if LastPos then Main.Position=LastPos end
        MainCorner.CornerRadius=UDim.new(0,12)
        MinBtn.Text="-"; MinBtn.BackgroundColor3=Color3.fromRGB(80,80,88); MinBtn.ZIndex=1
        LayoutUI()
    end
end)

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(ResizeCanvas)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if not Minimized then LayoutUI() end end)

local resizing=false
local rStartPos,rStartSize
Resize.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        resizing=true; rStartPos=input.Position; rStartSize=Main.AbsoluteSize; Main.Draggable=false
    end
end)
UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-rStartPos
        Main.Size=UDim2.new(0,math.clamp(rStartSize.X+d.X,MinW,MaxW),0,math.clamp(rStartSize.Y+d.Y,MinH,MaxH))
        LastSize=Vector2.new(Main.AbsoluteSize.X,Main.AbsoluteSize.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing=false; Main.Draggable=true end
end)

-- 低卡顿实时监听自动获取 v6
-- 事件触发优先：新UI出现 / 文本变化会实时收集
-- 低频兜底扫描：避免持续全量扫描导致卡顿
local RealtimeScheduled=false
local WatchedObjects=setmetatable({}, {__mode="k"})
local WatchedRoots=setmetatable({}, {__mode="k"})
local PendingObjects=setmetatable({}, {__mode="k"})
local PendingCount=0
local LastFallbackScan=0
local FallbackInterval=5 -- 秒。想更省性能可改成 8；想更实时可改成 3
local EventDelay=0.18     -- 事件合并延迟，避免一堆UI同时出现时连扫很多次

local function IsTextObject(o)
    return o and (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox"))
end

local function RefreshRoots()
    HuiRoot=nil
    pcall(function() if gethui then HuiRoot=gethui() end end)
    UIRoots={}
    AddUniqueRoot(UIRoots,CoreGui)
    AddUniqueRoot(UIRoots,HuiRoot)
    WideRoots={}
    AddUniqueRoot(WideRoots,PlayerGui)
    AddUniqueRoot(WideRoots,Workspace)
    AddUniqueRoot(WideRoots,CoreGui)
    AddUniqueRoot(WideRoots,HuiRoot)
end

local function ScanObjectAllSections(o)
    if not IsTextObject(o) then return 0 end
    local n=0
    n+=ReadObj(o,"PlayerGui")
    n+=ReadObj(o,"Workspace")
    n+=ReadObj(o,"CoreGui")
    n+=ReadObj(o,"RobloxGui")
    n+=ReadObj(o,"PlayerList")
    n+=ReadObj(o,"第三方UI")
    Rebuild("全部")
    return n
end

local function RefreshCurrentDisplay(added, reason)
    UpdateSectionBtns()

    if Search.Text~="" then
        SearchNow()
        return
    end

    if added and added>0 then
        SetDisplay(GetCurrentText(), true)
        Status((reason or "实时新增").." "..added.." 条")
    else
        Status(reason or "实时检测中")
    end
end

local function FlushPending(reason)
    if not AutoRefresh then return end
    RefreshRoots()

    local before=Count(CurrentSection)
    local added=0

    for o in pairs(PendingObjects) do
        added += ScanObjectAllSections(o)
    end

    PendingObjects=setmetatable({}, {__mode="k"})
    PendingCount=0

    local after=Count(CurrentSection)

    if added>0 or after~=before then
        RefreshCurrentDisplay(added, reason)
    else
        Status(reason or "实时检测中")
    end
end

local function QueueFlush(reason)
    if RealtimeScheduled or not AutoRefresh then return end
    RealtimeScheduled=true
    task.defer(function()
        task.wait(EventDelay)
        RealtimeScheduled=false
        FlushPending(reason)
    end)
end

local function QueueObject(o, reason)
    if not IsTextObject(o) or not AutoRefresh then return end
    if not PendingObjects[o] then
        PendingObjects[o]=true
        PendingCount += 1
    end
    QueueFlush(reason)
end

local function WatchTextObject(o)
    if not IsTextObject(o) or WatchedObjects[o] then return end
    WatchedObjects[o]=true

    pcall(function()
        o:GetPropertyChangedSignal("Text"):Connect(function()
            QueueObject(o,"文本变化")
        end)
    end)

    pcall(function()
        o:GetPropertyChangedSignal("Visible"):Connect(function()
            QueueObject(o,"显示变化")
        end)
    end)

    pcall(function()
        o:GetPropertyChangedSignal("Parent"):Connect(function()
            QueueObject(o,"层级变化")
        end)
    end)
end

local function WatchDescendantsOnce(root)
    -- 只在首次监听时扫一遍已有文本对象。Workspace 很大时跳过，避免启动卡顿。
    if root==Workspace then return end
    pcall(function()
        for _,o in ipairs(root:GetDescendants()) do
            if IsTextObject(o) then
                WatchTextObject(o)
            end
        end
    end)
end

local function WatchRoot(root)
    if not root or WatchedRoots[root] then return end
    WatchedRoots[root]=true

    WatchDescendantsOnce(root)

    pcall(function()
        root.DescendantAdded:Connect(function(o)
            if IsTextObject(o) then
                WatchTextObject(o)
                QueueObject(o,"新UI文本")
            else
                -- 新容器出现时，只扫描这个新容器的后代，不全量扫整棵树
                task.defer(function()
                    pcall(function()
                        for _,c in ipairs(o:GetDescendants()) do
                            if IsTextObject(c) then
                                WatchTextObject(c)
                                QueueObject(c,"新UI")
                            end
                        end
                    end)
                end)
            end
        end)
    end)
end

local function FallbackScanIfNeeded(force)
    if not AutoRefresh then return end
    local now=os.clock()
    if not force and now-LastFallbackScan < FallbackInterval then return end
    LastFallbackScan=now

    local before=Count(CurrentSection)
    local added=ScanAllSections()
    local after=Count(CurrentSection)

    UpdateSectionBtns()

    if Search.Text~="" then
        SearchNow()
    elseif added>0 or after~=before then
        SetDisplay(GetCurrentText(), added>0)
        Status((added>0) and ("兜底新增 "..added.." 条") or "已同步")
    else
        Status("实时监听中")
    end
end

task.spawn(function()
    -- 启动时先全量扫一次，之后靠事件实时获取 + 低频兜底
    LayoutUI()
    CurrentSection="全部"
    RefreshRoots()
    RefreshDisplay(ScanAllSections())
    LastFallbackScan=os.clock()

    while SG and SG.Parent do
        RefreshRoots()
        WatchRoot(PlayerGui)
        WatchRoot(Workspace)
        for _,root in ipairs(UIRoots) do WatchRoot(root) end
        for _,root in ipairs(WideRoots) do WatchRoot(root) end

        if AutoRefresh then
            FallbackScanIfNeeded(false)
        else
            UpdateSectionBtns()
            Status()
        end

        task.wait(1.0)
    end
end)

local SCRIPT_NAME,SCRIPT_VERSION = "Script","v1.0"
local WIN_WIDTH,WIN_HEIGHT = 700,500
local TOGGLE_KEY = Enum.KeyCode.RightShift
local NOTIF_DURATION,WM_SHOW = 3,true

local T = {
    A=Color3.fromRGB(180,170,255), BG=Color3.fromRGB(14,14,18),
    B1=Color3.fromRGB(20,20,26),  B2=Color3.fromRGB(26,26,34),
    B3=Color3.fromRGB(34,34,44),  B4=Color3.fromRGB(44,44,58),
    BD=Color3.fromRGB(54,54,72),  TX=Color3.fromRGB(235,235,245),
    MT=Color3.fromRGB(120,120,150),SUB=Color3.fromRGB(75,75,100),
}

local Players=game:GetService("Players")
local TS=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local HS=game:GetService("HttpService")
local LP=Players.LocalPlayer

for _,v in ipairs({game:GetService("CoreGui"),LP.PlayerGui}) do
    pcall(function() if v:FindFirstChild("EtherUI") then v.EtherUI:Destroy() end end)
end

local AL,Flags,togByFlag={},{},{}
local toggleKey,listeningForKey,ICON_ID=TOGGLE_KEY,false,""
local function setA(c) T.A=c; for _,fn in ipairs(AL) do pcall(fn,c) end end

local CFG_PREFIX,CFG_INDEX,CFG_AUTO="EtherUI_cfg_","EtherUI_cfglist.json","EtherUI_autoload.txt"
local function _encode()
    local out={}
    for k,v in pairs(Flags) do
        local t=typeof(v)
        if t=="boolean"or t=="number"or t=="string" then out[k]=v
        elseif t=="Color3" then out[k]={r=v.R,g=v.G,b=v.B,__type="Color3"}
        elseif t=="EnumItem" then out[k]={name=v.Name,__type="EnumItem",enumType=tostring(v.EnumType)} end
    end; return out
end
local function _apply(data)
    if type(data)~="table" then return end
    for k,v in pairs(data) do
        if type(v)=="table" then
            if v.__type=="Color3" then Flags[k]=Color3.new(v.r,v.g,v.b)
            elseif v.__type=="EnumItem" then pcall(function() Flags[k]=Enum[v.enumType][v.name] end) end
        else Flags[k]=v end
    end
end
local function cfgList()
    if not readfile or not isfile or not isfile(CFG_INDEX) then return {} end
    local ok,d=pcall(function() return HS:JSONDecode(readfile(CFG_INDEX)) end)
    return (ok and type(d)=="table") and d or {}
end
local function cfgSave(name)
    if not writefile or not name or name=="" then return false end
    pcall(function()
        writefile(CFG_PREFIX..name..".json",HS:JSONEncode(_encode()))
        local list=cfgList(); local found=false
        for _,v in ipairs(list) do if v==name then found=true; break end end
        if not found then table.insert(list,name); writefile(CFG_INDEX,HS:JSONEncode(list)) end
    end); return true
end
local function cfgLoad(name)
    if not readfile or not isfile then return false end
    local f=CFG_PREFIX..name..".json"
    if not isfile(f) then return false end
    local ok,d=pcall(function() return HS:JSONDecode(readfile(f)) end)
    if ok then _apply(d) end; return ok
end
local function cfgDelete(name)
    pcall(function()
        local f=CFG_PREFIX..name..".json"
        if isfile and isfile(f) and delfile then delfile(f) end
        local list=cfgList()
        for i,v in ipairs(list) do if v==name then table.remove(list,i); break end end
        if writefile then writefile(CFG_INDEX,HS:JSONEncode(list)) end
    end)
end
local function cfgSetAuto(name) pcall(function() if writefile then writefile(CFG_AUTO,name or "") end end) end
local function cfgGetAuto()
    if not readfile or not isfile or not isfile(CFG_AUTO) then return nil end
    local n=readfile(CFG_AUTO):gsub("%s",""); return n~="" and n or nil
end
local _auto=cfgGetAuto(); if _auto then cfgLoad(_auto) end

local function tw(o,p,t,s) TS:Create(o,TweenInfo.new(t or 0.15,s or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end
local FONT=Enum.Font.Gotham
local FONT_B=Enum.Font.GothamMedium
local _TC={TextLabel=true,TextButton=true,TextBox=true}
local function new(cls,props,parent)
    local o=Instance.new(cls)
    if cls=="Frame"or cls=="ScrollingFrame" then pcall(function() o.BorderSizePixel=0 end) end
    if _TC[cls] then pcall(function() o.Font=FONT end) end
    for k,v in pairs(props or {}) do pcall(function() o[k]=v end) end
    if parent then o.Parent=parent end; return o
end
local function cr(r,p) return new("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function st(c,t,p) return new("UIStroke",{Color=c,Thickness=t or 1},p) end
local function pad(t,b,l,r,p) return new("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p) end
local function tl(props,parent) return new("TextLabel",props,parent) end
local function hexToColor(h)
    h=h:gsub("#",""); if #h~=6 then return nil end
    local r,g,b=tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)
    return (r and g and b) and Color3.fromRGB(r,g,b) or nil
end
local function toHex(c) return string.format("%02X%02X%02X",math.round(c.R*255),math.round(c.G*255),math.round(c.B*255)) end

local SG=new("ScreenGui",{Name="EtherUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=99})
pcall(function()
    if gethui then SG.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(SG); SG.Parent=game:GetService("CoreGui")
    elseif protect_gui then protect_gui(SG); SG.Parent=game:GetService("CoreGui")
    else SG.Parent=game:GetService("CoreGui") end
end)
if not SG.Parent then SG.Parent=LP.PlayerGui end

local nh=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-14,1,-14),Size=UDim2.new(0,280,1,-28),BackgroundTransparency=1,ZIndex=999},SG)
new("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,VerticalAlignment=Enum.VerticalAlignment.Bottom,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},nh)
local nCol={Success=Color3.fromRGB(120,200,150),Error=Color3.fromRGB(220,110,110),Warning=Color3.fromRGB(220,170,90),Info=T.A}
local function Notify(title,body,ntype,dur)
    local col=nCol[ntype] or T.A
    local nf=new("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=T.B2,ZIndex=999,BackgroundTransparency=1},nh); cr(6,nf)
    st(T.BD,1,nf)
    nf.Position=UDim2.new(1.1,0,0,0)
    tw(nf,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},0.25)
    local bar=new("Frame",{Size=UDim2.new(0,2,1,-16),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,8,0.5,0),BackgroundColor3=col,ZIndex=1000},nf); cr(99,bar)
    tl({Position=UDim2.new(0,18,0,10),Size=UDim2.new(1,-22,0,16),BackgroundTransparency=1,Text=title,Font=FONT_B,TextColor3=T.TX,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1000},nf)
    tl({Position=UDim2.new(0,18,0,28),Size=UDim2.new(1,-22,0,22),BackgroundTransparency=1,Text=body,TextColor3=T.MT,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=1000},nf)
    task.delay(dur or NOTIF_DURATION,function()
        tw(nf,{Position=UDim2.new(1.1,0,0,0),BackgroundTransparency=1},0.2)
        task.delay(0.22,function() nf:Destroy() end)
    end)
end

local bgOverlay=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.55,ZIndex=1,Visible=false},SG)
local overlayEnabled=true
local function setOverlay(v) overlayEnabled=v; bgOverlay.Visible=v end

local snowCont=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=5,Visible=false},SG)
local flakes,snowConn={},nil
for i=1,28 do
    local sz=math.random(2,4)
    local f=new("Frame",{Size=UDim2.new(0,sz,0,sz),BackgroundColor3=Color3.fromRGB(220,220,235),BackgroundTransparency=0.35,ZIndex=6},snowCont); cr(99,f)
    flakes[i]={ui=f,x=math.random(0,100)/100,y=math.random(-10,110)/100,spd=math.random(3,9)/100,dx=math.random(-12,12)/10000}
    f.Position=UDim2.new(flakes[i].x,0,flakes[i].y,0)
end
local function startSnow()
    if snowConn then return end
    snowCont.Visible=true
    snowConn=RS.Heartbeat:Connect(function(dt)
        for _,fl in ipairs(flakes) do
            fl.y+=fl.spd*dt; fl.x+=fl.dx
            if fl.y>1.05 then fl.y=-0.04; fl.x=math.random(0,100)/100 end
            fl.x=fl.x<0 and 1 or fl.x>1 and 0 or fl.x
            fl.ui.Position=UDim2.new(fl.x,0,fl.y,0)
        end
    end)
end
local function stopSnow()
    if snowConn then snowConn:Disconnect(); snowConn=nil end
    snowCont.Visible=false
    for _,fl in ipairs(flakes) do fl.ui.Position=UDim2.new(2,0,2,0) end
end

local WW,WH=WIN_WIDTH,WIN_HEIGHT
local winOpen,winMin=true,false
local baseW,baseH=WW,WH

local function getCenterPos(w,h)
    local vp=workspace.CurrentCamera.ViewportSize
    return UDim2.new(0,math.floor(vp.X/2-w/2),0,math.floor(vp.Y/2-h/2))
end

local Win=new("Frame",{
    Name="Window",AnchorPoint=Vector2.new(0,0),
    Position=getCenterPos(WW,WH),Size=UDim2.new(0,WW,0,WH),
    BackgroundColor3=T.BG,ClipsDescendants=false,ZIndex=10,
    Visible=false,BackgroundTransparency=1,
},SG)
cr(8,Win)

local WinInner=new("Frame",{
    Size=UDim2.new(1,0,1,0),BackgroundColor3=T.BG,
    ClipsDescendants=true,ZIndex=10,
},Win)
cr(8,WinInner)
st(T.BD,1,Win)

local TBar=new("Frame",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0,44),BackgroundColor3=T.B1,ZIndex=11},WinInner)
cr(8,TBar)
new("Frame",{Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0.5,0),BackgroundColor3=T.B1,ZIndex=11},TBar)
local titleSep=new("Frame",{
    AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
    Size=UDim2.new(1,0,0,1),BackgroundColor3=T.BD,
    ZIndex=12,
},TBar)

local titleIcon=new("ImageLabel",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,14,0.5,0),Size=UDim2.new(0,20,0,20),BackgroundTransparency=1,Image="",ZIndex=12,Visible=false},TBar)
local titleDot=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,14,0.5,0),Size=UDim2.new(0,8,0,8),BackgroundColor3=T.A,ZIndex=12},TBar); cr(99,titleDot)
table.insert(AL,function(c) titleDot.BackgroundColor3=c end)
local titleLabel=tl({AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,32,0.5,0),Size=UDim2.new(0,240,0,18),BackgroundTransparency=1,Text=SCRIPT_NAME,Font=FONT_B,TextColor3=T.TX,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},TBar)

local pb=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-44,0.5,0),Size=UDim2.new(0,28,0,24),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=T.B2,ZIndex=12},TBar); cr(4,pb); pad(0,0,4,8,pb)
local avImg=new("ImageLabel",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,3,0.5,0),Size=UDim2.new(0,16,0,16),BackgroundColor3=T.B3,Image="",ZIndex=13},pb); cr(4,avImg)
local pbNameLabel=tl({AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,23,0.5,0),Size=UDim2.new(0,0,0,12),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=LP.DisplayName,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},pb)
task.spawn(function()
    pcall(function()
        avImg.Image=Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60)
    end)
end)

local mb=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.new(0,22,0,16),BackgroundColor3=T.B2,Text="",ZIndex=13},TBar); cr(4,mb)
local mbBar=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,8,0,1),BackgroundColor3=T.MT,ZIndex=14},mb)
mb.MouseEnter:Connect(function() tw(mb,{BackgroundColor3=T.B3}); tw(mbBar,{BackgroundColor3=T.TX}) end)
mb.MouseLeave:Connect(function() tw(mb,{BackgroundColor3=T.B2}); tw(mbBar,{BackgroundColor3=T.MT}) end)
mb.MouseButton1Click:Connect(function()
    winMin=not winMin
    tw(Win,{Size=winMin and UDim2.new(0,WW,0,44) or UDim2.new(0,WW,0,WH)},0.2,Enum.EasingStyle.Quint)
end)

local drag,dragStart,winStart=false,nil,nil
TBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; dragStart=i.Position
        winStart=UDim2.new(0,Win.Position.X.Offset,0,Win.Position.Y.Offset)
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        local vp=workspace.CurrentCamera.ViewportSize; local ws=Win.AbsoluteSize
        Win.Position=UDim2.new(0,math.clamp(winStart.X.Offset+d.X,0,math.max(0,vp.X-ws.X)),0,math.clamp(winStart.Y.Offset+d.Y,0,math.max(0,vp.Y-ws.Y)))
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end)

local uiReady=false
local function setVisible(v)
    if not uiReady then return end
    winOpen=v
    if v then
        Win.Visible=true; Win.BackgroundTransparency=1
        tw(Win,{BackgroundTransparency=0},0.18)
        if overlayEnabled then bgOverlay.Visible=true; bgOverlay.BackgroundTransparency=1; tw(bgOverlay,{BackgroundTransparency=0.55},0.18) end
        snowCont.Visible=true
    else
        Win.Visible=false; bgOverlay.Visible=false; snowCont.Visible=false
    end
end
UIS.InputBegan:Connect(function(i) if not listeningForKey and i.KeyCode==toggleKey then setVisible(not winOpen) end end)

local function scaleWindow()
    local vp=workspace.CurrentCamera.ViewportSize
    local s=math.clamp(math.min(vp.X/1280,vp.Y/720),0.45,1.0)
    local sw,sh=math.floor(baseW*s),math.floor(baseH*s)
    WW=sw; WH=sh
    Win.Size=winMin and UDim2.new(0,sw,0,44) or UDim2.new(0,sw,0,sh)
    Win.Position=getCenterPos(sw,winMin and 44 or sh)
end
scaleWindow()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(scaleWindow)

local SIDEBAR_W=160
local Sidebar=new("Frame",{Position=UDim2.new(0,0,0,44),Size=UDim2.new(0,SIDEBAR_W,1,-44),BackgroundColor3=T.B1,ZIndex=11},WinInner)
new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=T.BD,ZIndex=12},Sidebar)

local searchBg=new("Frame",{Position=UDim2.new(0,10,0,10),Size=UDim2.new(1,-20,0,26),BackgroundColor3=T.B2,ZIndex=12},Sidebar); cr(4,searchBg)
local searchSt=st(T.BD,1,searchBg)
local searchBox=new("TextBox",{Position=UDim2.new(0,10,0,0),Size=UDim2.new(1,-16,1,0),BackgroundTransparency=1,Text="",PlaceholderText="Search",PlaceholderColor3=T.MT,TextColor3=T.TX,TextSize=12,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},searchBg)
searchBox.Focused:Connect(function() tw(searchSt,{Color=T.A}) end)
searchBox.FocusLost:Connect(function() tw(searchSt,{Color=T.BD}) end)

local tabScroll=new("ScrollingFrame",{Position=UDim2.new(0,0,0,46),Size=UDim2.new(1,0,1,-46),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=T.BD,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=11},Sidebar)
new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},tabScroll)
pad(4,8,8,8,tabScroll)

local ContentArea=new("Frame",{Position=UDim2.new(0,SIDEBAR_W,0,44),Size=UDim2.new(1,-SIDEBAR_W,1,-44),BackgroundTransparency=1,ClipsDescendants=true},WinInner)

local searchOverlay=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=T.BG,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.BD,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ZIndex=50},ContentArea)
new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},searchOverlay)
pad(10,10,12,12,searchOverlay)

local searchItems={}
local function rebuildSearch(q)
    q=q:lower():gsub("%s","")
    if q=="" then searchOverlay.Visible=false; return end
    searchOverlay.Visible=true
    for _,c in ipairs(searchOverlay:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local found=0
    for _,item in ipairs(searchItems) do
        if item.keywords:lower():gsub("%s",""):find(q,1,true) then
            found+=1
            local res=new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=T.B2,LayoutOrder=found,ZIndex=51},searchOverlay); cr(4,res)
            tl({Position=UDim2.new(0,14,0,0),Size=UDim2.new(0.6,0,1,0),BackgroundTransparency=1,Text=item.label,Font=FONT_B,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52},res)
            tl({AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0.3,0,1,0),BackgroundTransparency=1,Text=item.tab,TextColor3=T.MT,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=52},res)
            local rowBtn=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=53},res)
            rowBtn.MouseEnter:Connect(function() tw(res,{BackgroundColor3=T.B3},0.08) end)
            rowBtn.MouseLeave:Connect(function() tw(res,{BackgroundColor3=T.B2},0.08) end)
            rowBtn.MouseButton1Click:Connect(function() if item.switch then item.switch() end; searchBox.Text="" end)
        end
    end
    if found==0 then tl({Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Text="No results",TextColor3=T.MT,TextSize=12,ZIndex=51},searchOverlay) end
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() rebuildSearch(searchBox.Text) end)

local tabFrames,tabBtns={},{}
local activeTabIndex=0

local function addTab(name)
    local idx=#tabFrames+1

    local btnHolder=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=idx},tabScroll)
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},btnHolder)

    local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=T.B1,BackgroundTransparency=1,Text="",ZIndex=12,LayoutOrder=1,AutoButtonColor=false},btnHolder)
    cr(4,btn)
    local pip=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(0,2,0,16),BackgroundColor3=T.A,Visible=false,ZIndex=13},btn); cr(99,pip)
    table.insert(AL,function(c) pip.BackgroundColor3=c end)
    local btnLbl=tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-30,1,0),BackgroundTransparency=1,Text=name,TextColor3=T.MT,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},btn)

    local subArrow=tl({AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.new(0,10,0,10),BackgroundTransparency=1,Text="",TextColor3=T.MT,TextSize=10,ZIndex=13,Visible=false},btn)

    local subHolder=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=2,Visible=false},btnHolder)
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},subHolder)
    pad(2,2,0,0,subHolder)

    local frame=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},ContentArea)

    local function makeCol(xs,xo,wo)
        local col=new("ScrollingFrame",{Position=UDim2.new(xs,xo,0,8),Size=UDim2.new(0.5,wo,1,-16),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.BD,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},frame)
        new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},col)
        pad(4,6,0,0,col); return col
    end
    local colL=makeCol(0,10,-15); local colR=makeCol(0.5,5,-15)

    table.insert(tabFrames,frame)
    table.insert(tabBtns,{b=btn,p=pip,l=btnLbl,idx=idx,subs={},sh=subHolder,sa=subArrow,subOpen=false})

    local tabData=tabBtns[#tabBtns]

    local function switchToTab()
        for i,f in ipairs(tabFrames) do
            if i==activeTabIndex and i~=idx then f.Visible=false end
        end
        for _,td in ipairs(tabBtns) do
            for _,s in ipairs(td.subs) do s.frame.Visible=false end
        end
        frame.Visible=true
        for _,bd in ipairs(tabBtns) do
            if bd.idx==idx then
                tw(bd.b,{BackgroundTransparency=0,BackgroundColor3=T.B2},0.12)
                tw(bd.l,{TextColor3=T.TX},0.12)
                bd.p.Visible=true
            else
                tw(bd.b,{BackgroundTransparency=1},0.12)
                tw(bd.l,{TextColor3=T.MT},0.12)
                bd.p.Visible=false
            end
        end
        for _,s in ipairs(tabData.subs) do
            tw(s.btn,{BackgroundTransparency=1},0.1)
            tw(s.lbl,{TextColor3=T.MT},0.1)
            tw(s.pip,{BackgroundColor3=T.MT},0.1)
        end
        activeTabIndex=idx; searchBox.Text=""
    end

    btn.MouseEnter:Connect(function() if activeTabIndex~=idx then tw(btnLbl,{TextColor3=T.TX},0.1) end end)
    btn.MouseLeave:Connect(function() if activeTabIndex~=idx then tw(btnLbl,{TextColor3=T.MT},0.1) end end)
    btn.MouseButton1Click:Connect(switchToTab)

    if idx==1 then task.defer(switchToTab) end

    local tabAPI={colL=colL,colR=colR,name=name,switch=switchToTab}

    function tabAPI:AddSubTab(subName)
        subArrow.Visible=true
        subArrow.Text=tabData.subOpen and "v" or ">"

        local subBtn=new("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundColor3=T.B1,BackgroundTransparency=1,Text="",ZIndex=12,AutoButtonColor=false},subHolder)
        cr(4,subBtn)
        local subPip=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,10,0.5,0),Size=UDim2.new(0,3,0,3),BackgroundColor3=T.MT,ZIndex=13},subBtn); cr(99,subPip)
        local subLbl=tl({Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-26,1,0),BackgroundTransparency=1,Text=subName,TextColor3=T.MT,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},subBtn)

        local subFrame=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},ContentArea)
        local function makeSubCol(xs,xo,wo)
            local col=new("ScrollingFrame",{Position=UDim2.new(xs,xo,0,8),Size=UDim2.new(0.5,wo,1,-16),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.BD,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},subFrame)
            new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},col)
            pad(4,6,0,0,col); return col
        end
        local sColL=makeSubCol(0,10,-15); local sColR=makeSubCol(0.5,5,-15)

        local activeSub={frame=subFrame,btn=subBtn,lbl=subLbl,pip=subPip,colL=sColL,colR=sColR,name=subName}
        table.insert(tabData.subs,activeSub)

        local function switchToSub()
            for i,f in ipairs(tabFrames) do
                if i==activeTabIndex and i~=idx then f.Visible=false end
            end
            for _,td in ipairs(tabBtns) do
                for _,s in ipairs(td.subs) do s.frame.Visible=false end
            end
            for _,bd in ipairs(tabBtns) do
                if bd.idx==idx then
                    tw(bd.b,{BackgroundTransparency=0,BackgroundColor3=T.B2},0.12)
                    tw(bd.l,{TextColor3=T.TX},0.12)
                    bd.p.Visible=true
                else
                    tw(bd.b,{BackgroundTransparency=1},0.12)
                    tw(bd.l,{TextColor3=T.MT},0.12)
                    bd.p.Visible=false
                end
            end
            activeTabIndex=idx
            frame.Visible=false
            for _,s in ipairs(tabData.subs) do
                if s==activeSub then
                    s.frame.Visible=true
                    tw(s.btn,{BackgroundTransparency=0,BackgroundColor3=T.B2},0.1)
                    tw(s.lbl,{TextColor3=T.TX},0.1)
                    tw(s.pip,{BackgroundColor3=T.A},0.1)
                else
                    tw(s.btn,{BackgroundTransparency=1},0.1)
                    tw(s.lbl,{TextColor3=T.MT},0.1)
                    tw(s.pip,{BackgroundColor3=T.MT},0.1)
                end
            end
            searchBox.Text=""
        end

        subBtn.MouseEnter:Connect(function() tw(subLbl,{TextColor3=T.TX},0.1) end)
        subBtn.MouseLeave:Connect(function()
            if not activeSub.frame.Visible then tw(subLbl,{TextColor3=T.MT},0.1) end
        end)
        subBtn.MouseButton1Click:Connect(switchToSub)

        if not tabData.subOpen then
            tabData.subOpen=true
            subHolder.Visible=true
            subArrow.Text="v"
        end

        return sColL,sColR,subName,switchToSub
    end

    return colL,colR,name,switchToTab,tabAPI
end

local function makeSection(parent,title)
    local sec=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=T.B1,ClipsDescendants=true},parent)
    cr(6,sec)
    st(T.BD,1,sec)
    local body=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},sec)
    pad(6,8,0,0,body)
    new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},body)
    local lo=0; local function nl() lo+=1; return lo end
    local tabName,tabSwitch,collapsed="",nil,false

    if title and title~="" then
        local hdr=new("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=0,Text="",ZIndex=2,AutoButtonColor=false},body)
        tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(0.7,-16,1,0),BackgroundTransparency=1,Text=title,Font=FONT_B,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},hdr)
        local arrowLbl=tl({AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-12,0.5,0),Size=UDim2.new(0,12,0,12),BackgroundTransparency=1,Text="-",TextColor3=T.MT,TextSize=14,ZIndex=3},hdr)
        new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,8,1,0),Size=UDim2.new(1,-16,0,1),BackgroundColor3=T.BD,BackgroundTransparency=0.5},hdr)
        hdr.MouseEnter:Connect(function() tw(arrowLbl,{TextColor3=T.TX},0.1) end)
        hdr.MouseLeave:Connect(function() tw(arrowLbl,{TextColor3=T.MT},0.1) end)
        hdr.MouseButton1Click:Connect(function()
            collapsed=not collapsed
            arrowLbl.Text=collapsed and "+" or "-"
            if collapsed then
                local contentH=body.AbsoluteSize.Y
                sec.AutomaticSize=Enum.AutomaticSize.None
                sec.Size=UDim2.new(1,0,0,contentH)
                tw(sec,{Size=UDim2.new(1,0,0,28)},0.18,Enum.EasingStyle.Quint)
            else
                local targetH=body.AbsoluteSize.Y
                sec.AutomaticSize=Enum.AutomaticSize.None
                sec.Size=UDim2.new(1,0,0,28)
                tw(sec,{Size=UDim2.new(1,0,0,math.max(targetH,29))},0.18,Enum.EasingStyle.Quint)
                task.delay(0.2,function()
                    if not collapsed then
                        sec.AutomaticSize=Enum.AutomaticSize.Y
                        sec.Size=UDim2.new(1,0,0,0)
                    end
                end)
            end
        end)
    end

    local api={}
    api._tabName=function(n,fn) tabName=n; tabSwitch=fn end
    api.Destroy=function() sec:Destroy() end

    local slideCBs,slideActive={},nil
    UIS.InputChanged:Connect(function(i) if slideActive and i.UserInputType==Enum.UserInputType.MouseMovement then local cb=slideCBs[slideActive]; if cb then cb(i.Position.X,i.Position.Y) end end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then slideActive=nil end end)
    local function regSlide(id,startFn,moveFn,obj)
        slideCBs[id]=moveFn
        obj.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then slideActive=id; startFn(i.Position.X,i.Position.Y) end end)
    end

    function api:AddCheckbox(cfg)
        local flg=cfg.Flag or cfg.Name
        local on=(Flags[flg]~=nil) and Flags[flg] or (cfg.Default==true); Flags[flg]=on
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local hbg=new("Frame",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),BackgroundColor3=T.B3,BackgroundTransparency=1},row); cr(4,hbg)
        tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
        local cbBG=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,14,0,14),BackgroundColor3=T.B2},row); cr(3,cbBG)
        local cbSt=st(T.BD,1,cbBG)
        local cbFill=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0.6,0,0.6,0),BackgroundColor3=T.A,Visible=false},cbBG); cr(2,cbFill)
        local function upd()
            if on then cbFill.Visible=true; tw(cbSt,{Color=T.A}); tw(cbFill,{BackgroundColor3=T.A})
            else cbFill.Visible=false; tw(cbSt,{Color=T.BD}) end
        end
        table.insert(AL,function(c) if on then cbFill.BackgroundColor3=c; cbSt.Color=c end end)
        local btn=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=2},row)
        btn.MouseEnter:Connect(function() tw(hbg,{BackgroundTransparency=0.85},0.08) end)
        btn.MouseLeave:Connect(function() tw(hbg,{BackgroundTransparency=1},0.08) end)
        btn.MouseButton1Click:Connect(function() on=not on; Flags[flg]=on; upd(); if cfg.Callback then cfg.Callback(on) end end)
        upd()
        return {Set=function(v) on=v; Flags[flg]=v; upd() end, Get=function() return on end}
    end

    function api:AddToggle(cfg)
        local flg=cfg.Flag or cfg.Name
        local on=(Flags[flg]~=nil) and Flags[flg] or (cfg.Default==true); Flags[flg]=on
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local hbg=new("Frame",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),BackgroundColor3=T.B3,BackgroundTransparency=1},row); cr(4,hbg)
        tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-58,1,0),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
        local track=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,28,0,14),BackgroundColor3=T.B2},row); cr(99,track)
        local trkSt=st(T.BD,1,track)
        local knob=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,2,0.5,0),Size=UDim2.new(0,10,0,10),BackgroundColor3=T.MT,ZIndex=2},track); cr(99,knob)
        local function upd(anim)
            local t=anim and 0.15 or 0
            if on then tw(track,{BackgroundColor3=T.A},t); tw(trkSt,{Color=T.A},t); tw(knob,{Position=UDim2.new(1,-12,0.5,0),BackgroundColor3=Color3.new(1,1,1)},t)
            else tw(track,{BackgroundColor3=T.B2},t); tw(trkSt,{Color=T.BD},t); tw(knob,{Position=UDim2.new(0,2,0.5,0),BackgroundColor3=T.MT},t) end
        end
        table.insert(AL,function(c) if on then track.BackgroundColor3=c; trkSt.Color=c end end)
        if not togByFlag[flg] then togByFlag[flg]={} end
        local function _setOn(v,anim) on=v; upd(anim) end
        table.insert(togByFlag[flg],_setOn)
        local function _syncSiblings(v) for _,fn in ipairs(togByFlag[flg]) do pcall(fn,v,true) end end
        if cfg.Keybind then
            local kc=typeof(cfg.Keybind)=="EnumItem" and cfg.Keybind or Enum.KeyCode[tostring(cfg.Keybind)]
            if kc then UIS.InputBegan:Connect(function(i) if not listeningForKey and i.KeyCode==kc then on=not on; Flags[flg]=on; _syncSiblings(on); if cfg.Callback then cfg.Callback(on) end end end) end
        end
        local btn=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=2},row)
        btn.MouseEnter:Connect(function() tw(hbg,{BackgroundTransparency=0.85},0.08) end)
        btn.MouseLeave:Connect(function() tw(hbg,{BackgroundTransparency=1},0.08) end)
        btn.MouseButton1Click:Connect(function() on=not on; Flags[flg]=on; _syncSiblings(on); if cfg.Callback then cfg.Callback(on) end end)
        upd(false)
        return {Set=function(v) Flags[flg]=v; _syncSiblings(v) end,Get=function() return on end}
    end

    function api:AddSlider(cfg)
        local flg=cfg.Flag or cfg.Name
        local val=(Flags[flg]~=nil) and Flags[flg] or (cfg.Default or cfg.Min or 0)
        local dec=cfg.Decimals or 0; Flags[flg]=val
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local function fmt(v) return dec>0 and string.format("%."..dec.."f",v) or tostring(math.round(v)) end
        local wr=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=nl()},body)
        tl({Position=UDim2.new(0,12,0,4),Size=UDim2.new(0.6,-16,0,14),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},wr)
        local vl=new("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,4),Size=UDim2.new(0,52,0,14),BackgroundTransparency=1,Text=fmt(val),Font=FONT_B,TextColor3=T.A,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=2},wr)
        table.insert(AL,function(c) vl.TextColor3=c end)
        local eb=new("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",TextColor3=T.A,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Visible=false,ClearTextOnFocus=true,ZIndex=3},vl)
        local trackHit=new("Frame",{Position=UDim2.new(0,12,0,26),Size=UDim2.new(1,-24,0,12),BackgroundTransparency=1},wr)
        local track=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0,3),BackgroundColor3=T.B2},trackHit); cr(99,track)
        local p0=(val-cfg.Min)/(cfg.Max-cfg.Min)
        local fil=new("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=T.A},track); cr(99,fil)
        table.insert(AL,function(c) fil.BackgroundColor3=c end)
        local thumb=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(p0,0,0.5,0),Size=UDim2.new(0,10,0,10),BackgroundColor3=T.A,ZIndex=2},track); cr(99,thumb)
        table.insert(AL,function(c) thumb.BackgroundColor3=c end)
        local function setVal(v)
            v=math.clamp(v,cfg.Min,cfg.Max)
            v=dec==0 and math.round(v) or math.floor(v*10^dec+0.5)/10^dec
            val=v; Flags[flg]=v
            local p=(v-cfg.Min)/(cfg.Max-cfg.Min)
            tw(fil,{Size=UDim2.new(p,0,1,0)},0.05); tw(thumb,{Position=UDim2.new(p,0,0.5,0)},0.05)
            vl.Text=fmt(v); if cfg.Callback then cfg.Callback(v) end
        end
        vl.MouseButton1Click:Connect(function() eb.Text=fmt(val); eb.Visible=true; vl.Text=""; eb:CaptureFocus() end)
        eb.FocusLost:Connect(function() eb.Visible=false; local n=tonumber(eb.Text); if n then setVal(n) end; vl.Text=fmt(val) end)
        local function fromX(x) setVal(cfg.Min+math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(cfg.Max-cfg.Min)) end
        regSlide("sl_"..flg,fromX,function(x) fromX(x) end,trackHit)
        return {Set=setVal,Get=function() return val end}
    end

    function api:AddDropdown(cfg)
        local flg=cfg.Flag or cfg.Name
        local dv=Flags[flg] or cfg.Default or (cfg.Items and cfg.Items[1]) or ""; Flags[flg]=dv
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local wr=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=nl(),ClipsDescendants=false,ZIndex=5},body)
        tl({Position=UDim2.new(0,12,0,4),Size=UDim2.new(1,-20,0,13),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},wr)
        local sb=new("TextButton",{Position=UDim2.new(0,12,0,20),Size=UDim2.new(1,-24,0,20),BackgroundColor3=T.B2,Text="",ZIndex=5},wr); cr(4,sb)
        local sbSt=st(T.BD,1,sb)
        local selLbl=new("TextLabel",{Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-22,1,0),BackgroundTransparency=1,Text=Flags[flg],TextColor3=T.TX,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},sb)
        new("TextLabel",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),Size=UDim2.new(0,10,1,0),BackgroundTransparency=1,Text="v",TextColor3=T.MT,TextSize=10,ZIndex=6},sb)
        sb.MouseEnter:Connect(function() tw(sbSt,{Color=T.A}) end)
        sb.MouseLeave:Connect(function() tw(sbSt,{Color=T.BD}) end)
        local open,lf,oc=false,nil,nil
        local function closeDd()
            if not open then return end; open=false
            body.Parent.ClipsDescendants=true
            if oc then oc:Disconnect(); oc=nil end
            if lf then tw(lf,{Size=UDim2.new(1,-24,0,0)},0.12); tw(wr,{Size=UDim2.new(1,0,0,44)},0.12); task.delay(0.13,function() if lf then lf:Destroy(); lf=nil end end) end
        end
        sb.MouseButton1Click:Connect(function()
            open=not open
            if open then
                body.Parent.ClipsDescendants=false
                lf=new("Frame",{Position=UDim2.new(0,12,0,42),Size=UDim2.new(1,-24,0,0),BackgroundColor3=T.B2,ClipsDescendants=true,ZIndex=20},wr); cr(4,lf); st(T.BD,1,lf)
                new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},lf)
                for _,item in ipairs(cfg.Items or {}) do
                    local op=new("TextButton",{Size=UDim2.new(1,0,0,20),BackgroundColor3=T.B2,Text="  "..item,TextColor3=item==Flags[flg] and T.A or T.TX,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},lf)
                    op.MouseEnter:Connect(function() tw(op,{BackgroundColor3=T.B3},0.07) end)
                    op.MouseLeave:Connect(function() tw(op,{BackgroundColor3=T.B2},0.07) end)
                    op.MouseButton1Click:Connect(function() Flags[flg]=item; selLbl.Text=item; closeDd(); if cfg.Callback then cfg.Callback(item) end end)
                end
                local h=#(cfg.Items or {})*20
                tw(lf,{Size=UDim2.new(1,-24,0,h)},0.14); tw(wr,{Size=UDim2.new(1,0,0,44+h+2)},0.14)
                task.delay(0.05,function()
                    if not open then return end
                    oc=UIS.InputBegan:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                            task.delay(0.05,function() closeDd() end)
                        end
                    end)
                end)
            else closeDd() end
        end)
        local obj={Get=function() return Flags[flg] end}
        function obj:Set(v) Flags[flg]=v; selLbl.Text=tostring(v) end
        function obj:Rebuild(items) cfg.Items=items; Flags[flg]=items[1] or ""; selLbl.Text=Flags[flg] end
        return obj
    end

    function api:AddButton(cfg)
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name,tab=tabName,switch=tabSwitch})
        local wr=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local btn=new("TextButton",{Position=UDim2.new(0,12,0.5,-10),Size=UDim2.new(1,-24,0,20),BackgroundColor3=T.B2,Text=cfg.Name,TextColor3=T.TX,TextSize=12,AutoButtonColor=false},wr); cr(4,btn)
        local bSt=st(T.BD,1,btn)
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.B3}); tw(bSt,{Color=T.A},0.1) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.B2}); tw(bSt,{Color=T.BD},0.1) end)
        btn.MouseButton1Down:Connect(function() tw(btn,{BackgroundColor3=T.B4},0.06) end)
        btn.MouseButton1Click:Connect(function()
            tw(btn,{BackgroundColor3=T.B3},0.08)
            task.delay(0.1,function() tw(btn,{BackgroundColor3=T.B2},0.12) end)
            if cfg.Callback then cfg.Callback() end
        end)
    end

    function api:AddTextBox(cfg)
        local flg=cfg.Flag or cfg.Name; Flags[flg]=Flags[flg] or cfg.Default or ""
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local wr=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=nl()},body)
        tl({Position=UDim2.new(0,12,0,4),Size=UDim2.new(1,-20,0,13),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},wr)
        local bg=new("Frame",{Position=UDim2.new(0,12,0,20),Size=UDim2.new(1,-24,0,20),BackgroundColor3=T.B2},wr); cr(4,bg)
        local tSt=st(T.BD,1,bg)
        local tb=new("TextBox",{Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-16,1,0),BackgroundTransparency=1,Text=Flags[flg],PlaceholderText=cfg.Placeholder or "",PlaceholderColor3=T.MT,TextColor3=T.TX,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},bg)
        tb.Focused:Connect(function() tw(tSt,{Color=T.A}) end)
        tb.FocusLost:Connect(function(e) tw(tSt,{Color=T.BD}); Flags[flg]=tb.Text; if e and cfg.Callback then cfg.Callback(tb.Text) end end)
        return {Get=function() return tb.Text end,Set=function(v) tb.Text=tostring(v); Flags[flg]=tb.Text end}
    end

    function api:AddColorPicker(cfg)
        local flg=cfg.Flag or cfg.Name
        local sv=Flags[flg]; local cur=(typeof(sv)=="Color3" and sv) or cfg.Default or T.A; Flags[flg]=cur
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local cH,cS,cV=Color3.toHSV(cur)
        local rebuild
        local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nl()},body)
        tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-50,1,0),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
        local sw=new("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,22,0,14),BackgroundColor3=cur},row); cr(3,sw); st(T.BD,1,sw)
        local svRow=new("Frame",{Size=UDim2.new(1,0,0,90),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local svBox=new("Frame",{Position=UDim2.new(0,12,0,4),Size=UDim2.new(1,-24,0,82),BackgroundColor3=Color3.fromHSV(cH,1,1)},svRow); cr(4,svBox); st(T.BD,1,svBox)
        local sG=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1)},svBox)
        new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}},sG)
        local vG=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0)},svBox)
        new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)},Rotation=90},vG)
        local svT=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(cS,0,1-cV,0),Size=UDim2.new(0,10,0,10),BackgroundColor3=Color3.new(1,1,1),ZIndex=3},svBox); cr(99,svT); st(Color3.new(0,0,0),1.5,svT)
        local function applySV(x,y)
            cS=math.clamp((x-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X,0,1)
            cV=1-math.clamp((y-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y,0,1)
            svT.Position=UDim2.new(cS,0,1-cV,0); rebuild(); sw.BackgroundColor3=cur
        end
        regSlide("sv_"..flg,applySV,applySV,svBox)
        local hRow=new("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local hTrk=new("Frame",{Position=UDim2.new(0,12,0.5,-3),Size=UDim2.new(1,-24,0,6),BackgroundColor3=Color3.new(1,1,1)},hRow); cr(99,hTrk)
        new("UIGradient",{Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(0.17,Color3.fromHSV(0.17,1,1)),
            ColorSequenceKeypoint.new(0.33,Color3.fromHSV(0.33,1,1)),ColorSequenceKeypoint.new(0.5,Color3.fromHSV(0.5,1,1)),
            ColorSequenceKeypoint.new(0.67,Color3.fromHSV(0.67,1,1)),ColorSequenceKeypoint.new(0.83,Color3.fromHSV(0.83,1,1)),
            ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1)),
        }},hTrk)
        local hT=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(cH,0,0.5,0),Size=UDim2.new(0,10,0,10),BackgroundColor3=Color3.new(1,1,1),ZIndex=2},hTrk); cr(99,hT); st(T.BD,1,hT)
        local function applyH(x)
            cH=math.clamp((x-hTrk.AbsolutePosition.X)/hTrk.AbsoluteSize.X,0,1)
            hT.Position=UDim2.new(cH,0,0.5,0); svBox.BackgroundColor3=Color3.fromHSV(cH,1,1); rebuild(); sw.BackgroundColor3=cur
        end
        regSlide("hue_"..flg,applyH,function(x) applyH(x) end,hTrk)
        local hexRow=new("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,LayoutOrder=nl()},body)
        local hxBg=new("Frame",{Position=UDim2.new(0,12,0.5,-8),Size=UDim2.new(1,-24,0,16),BackgroundColor3=T.B2},hexRow); cr(3,hxBg)
        local hxSt=st(T.BD,1,hxBg)
        tl({Position=UDim2.new(0,6,0,0),Size=UDim2.new(0,12,1,0),BackgroundTransparency=1,Text="#",TextColor3=T.MT,TextSize=11},hxBg)
        local hxBox=new("TextBox",{Position=UDim2.new(0,16,0,0),Size=UDim2.new(1,-20,1,0),BackgroundTransparency=1,Text=toHex(cur),PlaceholderColor3=T.MT,TextColor3=T.TX,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false},hxBg)
        hxBox.Focused:Connect(function() tw(hxSt,{Color=T.A}) end)
        hxBox.FocusLost:Connect(function()
            tw(hxSt,{Color=T.BD})
            local c=hexToColor(hxBox.Text)
            if c then
                cur=c; cH,cS,cV=Color3.toHSV(c)
                sw.BackgroundColor3=c; svBox.BackgroundColor3=Color3.fromHSV(cH,1,1)
                svT.Position=UDim2.new(cS,0,1-cV,0); hT.Position=UDim2.new(cH,0,0.5,0)
                Flags[flg]=c; if cfg.Callback then cfg.Callback(c) end
            end
            hxBox.Text=toHex(cur)
        end)
        rebuild=function() cur=Color3.fromHSV(cH,cS,cV); Flags[flg]=cur; hxBox.Text=toHex(cur); if cfg.Callback then cfg.Callback(cur) end end
    end

    function api:AddLabel(cfg)
        local lbl=tl({Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=cfg.Name or "",TextColor3=T.MT,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=nl()},body)
        pad(0,0,12,0,lbl)
        return {Set=function(t) lbl.Text=t end}
    end

    function api:AddDivider()
        local wr=new("Frame",{Size=UDim2.new(1,0,0,8),BackgroundTransparency=1,LayoutOrder=nl()},body)
        new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,12,0.5,0),Size=UDim2.new(1,-24,0,1),BackgroundColor3=T.BD,BackgroundTransparency=0.5},wr)
    end

    function api:AddKeybind(cfg)
        local flg=cfg.Flag or cfg.Name
        local cur=Flags[flg] or cfg.Default or Enum.KeyCode.RightShift; Flags[flg]=cur
        local listening=false
        table.insert(searchItems,{label=cfg.Name,keywords=cfg.Name..(cfg.Flag or ""),tab=tabName,switch=tabSwitch})
        local row=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nl()},body)
        tl({Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-90,1,0),BackgroundTransparency=1,Text=cfg.Name,TextColor3=T.TX,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
        local badge=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,68,0,18),BackgroundColor3=T.B2,Text=cur.Name,TextColor3=T.A,TextSize=11},row)
        cr(4,badge); local bSt=st(T.BD,1,badge)
        table.insert(AL,function(c) if not listening then badge.TextColor3=c end end)
        badge.MouseButton1Click:Connect(function()
            if listening then return end
            listening=true; listeningForKey=true
            badge.Text="..."; badge.TextColor3=T.MT
            tw(badge,{BackgroundColor3=T.B3}); tw(bSt,{Color=T.A})
            local conn; conn=UIS.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Keyboard then
                    listening=false; listeningForKey=false; cur=i.KeyCode; Flags[flg]=cur
                    if flg=="tkey" then toggleKey=cur end
                    badge.Text=cur.Name; badge.TextColor3=T.A
                    tw(badge,{BackgroundColor3=T.B2}); tw(bSt,{Color=T.BD})
                    if cfg.Callback then cfg.Callback(cur) end; conn:Disconnect()
                end
            end)
        end)
        return {Get=function() return cur end,Set=function(k) cur=k; Flags[flg]=k; badge.Text=k.Name end}
    end

    function api:AddCanvas(cfg)
        local h=cfg and cfg.Height or 0
        local autoSize=h==0
        local wr=new("Frame",{
            Size=autoSize and UDim2.new(1,0,0,0) or UDim2.new(1,0,0,h),
            AutomaticSize=autoSize and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3=(cfg and cfg.Color) or T.BG,
            BackgroundTransparency=(cfg and cfg.Color) and 0 or 1,
            ClipsDescendants=cfg and cfg.Clip or false,
            LayoutOrder=nl(),
        },body)
        if cfg and cfg.Radius then cr(cfg.Radius,wr) end
        return wr
    end

    return api
end

local wmFrame=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,12,1,-12),Size=UDim2.new(0,0,0,28),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=T.B1,BackgroundTransparency=0.05,ZIndex=100,Visible=false},SG)
cr(6,wmFrame); st(T.BD,1,wmFrame)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},wmFrame)
pad(0,0,8,10,wmFrame)
local wmIconImg=new("ImageLabel",{Size=UDim2.new(0,18,0,18),BackgroundTransparency=1,Image="",ZIndex=101,LayoutOrder=1,Visible=false},wmFrame)
local wmIconDot=new("Frame",{Size=UDim2.new(0,6,0,6),BackgroundColor3=T.A,LayoutOrder=1,ZIndex=101},wmFrame); cr(99,wmIconDot)
table.insert(AL,function(c) wmIconDot.BackgroundColor3=c end)
local wmScript=tl({Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=SCRIPT_NAME,Font=FONT_B,TextColor3=T.TX,TextSize=12,LayoutOrder=2,ZIndex=101},wmFrame)
new("Frame",{Size=UDim2.new(0,1,0,12),BackgroundColor3=T.BD,LayoutOrder=3,ZIndex=101},wmFrame)
local wmVer=tl({Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=SCRIPT_VERSION,TextColor3=T.MT,TextSize=11,LayoutOrder=4,ZIndex=101},wmFrame)
local wmNameLabel=new("TextLabel",{Visible=false,Size=UDim2.new(0,0,0,0),Text=LP.Name},SG)

local function showLoadingScreen(onDone)
    Win.Visible=false; bgOverlay.Visible=false
    local loadBg=new("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(10,10,14),BackgroundTransparency=0.15,ZIndex=200},SG)
    local card=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.55,0),Size=UDim2.new(0,240,0,170),BackgroundColor3=T.B1,BackgroundTransparency=1,ZIndex=202},loadBg); cr(8,card)
    st(T.BD,1,card)
    tw(card,{BackgroundTransparency=0.02,Position=UDim2.new(0.5,0,0.5,0)},0.35,Enum.EasingStyle.Quint)
    local topLine=new("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.A,ZIndex=203},card)
    table.insert(AL,function(c) topLine.BackgroundColor3=c end)

    if ICON_ID~="" then
        new("ImageLabel",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,28),Size=UDim2.new(0,40,0,40),BackgroundTransparency=1,Image=ICON_ID,ZIndex=203},card)
    else
        local dot=new("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,40),Size=UDim2.new(0,14,0,14),BackgroundColor3=T.A,ZIndex=203},card); cr(99,dot)
        table.insert(AL,function(c) dot.BackgroundColor3=c end)
    end

    tl({AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,78),Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=SCRIPT_NAME,Font=FONT_B,TextColor3=T.TX,TextSize=16,ZIndex=203},card)
    tl({AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,102),Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=SCRIPT_VERSION,TextColor3=T.MT,TextSize=11,ZIndex=203},card)

    local progBg=new("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-22),Size=UDim2.new(0.7,0,0,2),BackgroundColor3=T.B3,ZIndex=203},card); cr(99,progBg)
    local progFil=new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=T.A,ZIndex=204},progBg); cr(99,progFil)
    table.insert(AL,function(c) progFil.BackgroundColor3=c end)

    task.spawn(function()
        tw(progFil,{Size=UDim2.new(0.6,0,1,0)},0.7)
        task.wait(0.75); tw(progFil,{Size=UDim2.new(1,0,1,0)},0.35)
    end)

    task.delay(1.3,function()
        tw(loadBg,{BackgroundTransparency=1},0.3)
        tw(card,{BackgroundTransparency=1,Position=UDim2.new(0.5,0,0.45,0)},0.3)
        for _,c in ipairs(card:GetDescendants()) do
            if c:IsA("GuiObject") then
                pcall(function() tw(c,{ImageTransparency=1},0.25) end)
                pcall(function() tw(c,{TextTransparency=1},0.25) end)
                pcall(function() tw(c,{BackgroundTransparency=1},0.25) end)
            end
        end
        task.delay(0.35,function()
            loadBg:Destroy()
            if onDone then onDone() end
        end)
    end)
end

local function Setup(cfg)
    cfg=cfg or {}
    if cfg.Name then
        SCRIPT_NAME=cfg.Name
        titleLabel.Text=cfg.Name
        wmScript.Text=cfg.Name
    end
    if cfg.Version then
        SCRIPT_VERSION=cfg.Version
        wmVer.Text=cfg.Version
    end
    if cfg.Icon and cfg.Icon~="" then
        ICON_ID=cfg.Icon
        titleIcon.Image=cfg.Icon
        titleIcon.Visible=true
        titleDot.Visible=false
        titleLabel.Position=UDim2.new(0,40,0.5,0)
        wmIconImg.Image=cfg.Icon
        wmIconImg.Visible=true
        wmIconDot.Visible=false
    end
    if cfg.WatermarkSubtext and cfg.WatermarkSubtext~="" then
        new("Frame",{Size=UDim2.new(0,1,0,12),BackgroundColor3=T.BD,LayoutOrder=5,ZIndex=101},wmFrame)
        tl({Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Text=cfg.WatermarkSubtext,TextColor3=T.MT,TextSize=11,LayoutOrder=6,ZIndex=101},wmFrame)
    end
    if cfg.Snow==true then startSnow() elseif cfg.Snow==false then stopSnow() end

    showLoadingScreen(function()
        uiReady=true
        Win.Visible=true
        Win.BackgroundTransparency=1
        tw(Win,{BackgroundTransparency=0},0.25)
        if overlayEnabled then
            bgOverlay.Visible=true
            bgOverlay.BackgroundTransparency=1
            tw(bgOverlay,{BackgroundTransparency=0.55},0.25)
        end
        if WM_SHOW then
            wmFrame.Visible=true
            wmFrame.BackgroundTransparency=1
            tw(wmFrame,{BackgroundTransparency=0.05},0.25)
        end
        if snowConn then snowCont.Visible=true end
        task.delay(0.4,function()
            Notify("Welcome",("Press %s to toggle"):format(toggleKey.Name),"Info",4)
        end)
    end)
end

return {
    Setup=Setup,
    AddTab=addTab,
    MakeSection=makeSection,
    Notify=Notify,
    SetAccent=setA,
    StartSnow=startSnow,
    StopSnow=stopSnow,
    SetOverlay=setOverlay,
    Flags=Flags,
    pbNameLabel=pbNameLabel,
    avImg=avImg,
    wmFrame=wmFrame,
    wmNameLabel=wmNameLabel,
    SaveConfig=cfgSave,
    LoadConfig=cfgLoad,
    DeleteConfig=cfgDelete,
    ListConfigs=cfgList,
    SetAutoLoad=cfgSetAuto,
    GetAutoLoad=cfgGetAuto,
    Destroy=function() pcall(stopSnow); pcall(function() SG:Destroy() end) end,
}

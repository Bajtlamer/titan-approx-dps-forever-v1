local _,ns=...
-- Results window: header with the key values, tabs, filters (drop-downs and search),
-- and scrollable lists. All content comes from ns.ViewModel; this file only renders.
local W={tab='Overview'};ns.Window=W
local VM=ns.ViewModel
local S=ns.Style
local Wd=ns.Widgets
local FRAME_W,FRAME_H=1000,700
local FOOTER=56
local WITH_DETAIL={Overview=true,Weapons=true}
W.query=VM.NewQuery()
W.lists={}

local function environment()
 local recorder=ns.recorder or {}
 return {recording=not recorder.paused,meter=ns.capabilities and ns.capabilities.damage,spells=ns.capabilities and ns.capabilities.spells,
  gap=recorder.gap,controls='Scrollable lists with scroll bars, search box and drop-down menus (core frame controls)'}
end

local function number(v)return v and ns.DamageNumber(v) or 'Unavailable'end

local function setQuery(field,value)
 W.query[field]=value
 if field=='scope' and ns.store then ns.store.saved.settings.mode=value;if ns.Titan then ns.Titan.Refresh()end end
 if field=='tab' then W.query.sortKey=nil;W.query.sortDesc=true;W.query.selected=nil end
 W.Refresh()
end

local function options(values,labelFor)
 local out={};for _,v in ipairs(values)do out[#out+1]={key=v,label=labelFor(v)}end;return out
end

local function statBlock(frame,x,label)
 local caption=Wd.Text(frame,'hint',S.colors.hint);caption:SetPoint('TOPLEFT',frame,'TOPLEFT',x,-30);caption:SetText(label)
 local value=Wd.Text(frame,'primary');value:SetPoint('TOPLEFT',frame,'TOPLEFT',x,-44)
 return value
end

local function build()
 local f=CreateFrame('Frame','TitanApproxDPSWindow',UIParent,'BasicFrameTemplateWithInset');W.frame=f
 f:SetSize(FRAME_W,FRAME_H);f:SetPoint('CENTER');f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true)
 f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',f.StartMoving);f:SetScript('OnDragStop',f.StopMovingOrSizing)
 f.TitleText:SetText('Titan Approx DPS '..ns.version)
 if UISpecialFrames then table.insert(UISpecialFrames,'TitanApproxDPSWindow')end

 W.lifetime=statBlock(f,16,'Character lifetime damage (protected)')
 W.bestFight=statBlock(f,300,'Best fight (protected)')
 W.bestDps=statBlock(f,520,'Best DPS in one fight (protected)')
 W.character=Wd.Text(f,'body',S.colors.label,'RIGHT');W.character:SetPoint('TOPRIGHT',f,'TOPRIGHT',-16,-60);W.character:SetWidth(300)
 W.exportButton=Wd.Button(f,'Export',80,22,function()ns.TransferView.Show(false)end);W.exportButton:SetPoint('TOPRIGHT',f,'TOPRIGHT',-104,-30)
 W.importButton=Wd.Button(f,'Import',80,22,function()ns.TransferView.Show(true)end);W.importButton:SetPoint('TOPRIGHT',f,'TOPRIGHT',-16,-30)

 W.tabButtons={}
 for i,name in ipairs(VM.Tabs)do
  local tab=name
  local b=Wd.Button(f,name,112,24,function()W.tab=tab;setQuery('tab',tab)end)
  b:SetPoint('TOPLEFT',f,'TOPLEFT',16+(i-1)*116,-84);W.tabButtons[name]=b
 end

 W.dropdowns={}
 W.dropdowns.scope=Wd.Dropdown(f,200,'Scope',function()return options(VM.Scopes,function(v)return VM.ScopeLabels[v]end),W.query.scope end,function(v)setQuery('scope',v)end)
 W.dropdowns.category=Wd.Dropdown(f,190,'Category',function()return options(VM.CategoryChoices,VM.CategoryLabel),W.query.category end,function(v)setQuery('category',v)end)
 W.dropdowns.period=Wd.Dropdown(f,170,'Period',function()return options(VM.Periods,function(v)return VM.PeriodLabels[v]end),W.query.period end,function(v)setQuery('period',v)end)
 W.dropdowns.scope.button:SetPoint('TOPLEFT',f,'TOPLEFT',16,-116)
 W.dropdowns.category.button:SetPoint('TOPLEFT',f,'TOPLEFT',224,-116)
 W.dropdowns.period.button:SetPoint('TOPLEFT',f,'TOPLEFT',422,-116)
 W.search=Wd.SearchBox(f,230,'Search weapons, spells, targets...',function(text)W.query.search=text;W.Refresh()end)
 W.search:SetPoint('TOPLEFT',f,'TOPLEFT',606,-117)
 W.hiddenButton=Wd.Button(f,'Hidden: off',110,24,function()setQuery('showHidden',not W.query.showHidden)end)
 W.hiddenButton:SetPoint('TOPLEFT',f,'TOPLEFT',850,-116)

 local function compareOptions()return W.result and W.result.compare and W.result.compare.options or {}end
 W.dropdowns.compareA=Wd.Dropdown(f,440,'First',function()return compareOptions(),W.result and W.result.compare and W.result.compare.a end,function(v)setQuery('compareA',v)end)
 W.dropdowns.compareB=Wd.Dropdown(f,440,'Second',function()return compareOptions(),W.result and W.result.compare and W.result.compare.b end,function(v)setQuery('compareB',v)end)
 W.dropdowns.compareA.button:SetPoint('TOPLEFT',f,'TOPLEFT',16,-148)
 W.dropdowns.compareB.button:SetPoint('TOPLEFT',f,'TOPLEFT',464,-148)

 W.lists.main=Wd.List(f,{rowHeight=22})
 W.lists.detail=Wd.List(f,{rowHeight=20})
 W.detailTitle=Wd.Text(f,'title',S.colors.title)
 W.lists.main.onSelect=function(key)if WITH_DETAIL[W.query.tab]then W.query.selected=key;W.Refresh()end end
 W.lists.main.onSort=function(key)
  local q=W.query
  if q.sortKey==key then q.sortDesc=not q.sortDesc
  else
   q.sortKey=key
   local desc=true;for _,col in ipairs(W.result.columns)do if col.key==key and col.align=='left' then desc=false end end
   q.sortDesc=desc
  end
  W.Refresh()
 end
 W.hint=Wd.Text(f,'hint',S.colors.hint);W.hint:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',16,14);W.hint:SetWidth(FRAME_W-32);W.hint:SetWordWrap(true);W.hint:SetHeight(34);W.hint:SetJustifyV('TOP')
end

local function layout(result)
 local compare=W.query.tab=='Compare'
 for _,name in ipairs({'compareA','compareB'})do if compare then W.dropdowns[name].button:Show()else W.dropdowns[name].button:Hide()end end
 local top=compare and -180 or -150
 local bottom=-(FRAME_H-FOOTER)
 local width=FRAME_W-32
 if result.detail then
  local mainHeight=250
  W.lists.main:SetBox(16,top,width,mainHeight)
  W.detailTitle:ClearAllPoints();W.detailTitle:SetPoint('TOPLEFT',W.frame,'TOPLEFT',20,top-mainHeight-6);W.detailTitle:Show()
  local detailTop=top-mainHeight-26
  W.lists.detail.frame:Show();W.lists.detail:SetBox(16,detailTop,width,bottom*-1+detailTop)
 else
  W.lists.main:SetBox(16,top,width,-bottom+top)
  W.lists.detail.frame:Hide();W.detailTitle:Hide()
 end
end

function W.Refresh()
 if not W.frame or not W.frame:IsShown() or not ns.store then return end
 local c=ns.store:Character()
 if not c then return end
 local result=VM.Build(ns.store,W.query,environment());W.result=result
 local q=W.query
 W.lifetime:SetText(S.Color(number(result.header.lifetime),S.colors.lifetime))
 W.bestFight:SetText(S.Color(number(result.header.bestFight),result.header.bestFight and S.colors.record or S.colors.unavailable))
 W.bestDps:SetText(S.Color(result.header.bestDps and string.format('%.1f',result.header.bestDps) or 'Unavailable',result.header.bestDps and S.colors.record or S.colors.unavailable))
 W.character:SetText((result.header.name or 'Recorded character')..(result.header.class and (' - '..result.header.class:sub(1,1)..result.header.class:sub(2):lower()) or ''))
 for name,b in pairs(W.tabButtons)do if name==q.tab then b:Disable()else b:Enable()end end
 W.dropdowns.scope:SetValue(VM.ScopeLabels[q.scope])
 W.dropdowns.category:SetValue(VM.CategoryLabel(q.category))
 W.dropdowns.period:SetValue(VM.PeriodLabels[q.period])
 W.hiddenButton:SetText('Hidden: '..(q.showHidden and 'shown' or 'off'))
 if result.compare then
  local function label(key)for _,o in ipairs(result.compare.options)do if o.key==key then return o.label end end;return 'None'end
  W.dropdowns.compareA:SetValue(label(result.compare.a));W.dropdowns.compareB:SetValue(label(result.compare.b))
 end
 layout(result)
 W.lists.main:SetData(result.columns,result.rows,result.selected,result.sortKey,result.sortDesc,result.empty)
 if result.detail then
  W.detailTitle:SetText('Spells and abilities: '..result.detail.title)
  W.lists.detail:SetData(result.detail.columns,result.detail.rows,nil,nil,nil,'No spell breakdown is available for this group.')
 end
 W.hint:SetText(result.hint)
end

local known={}
for _,name in ipairs(VM.Tabs)do known[name]=true end
function W.Show(tab)
 if not ns.store then return end
 if not W.frame then build()end
 local target=known[tab] and tab or (tab==nil and W.query.tab) or 'Overview'
 W.tab=target;W.query.tab=target
 if not W.shown_before then W.query.scope=ns.store.saved.settings.mode or 'all';W.shown_before=true end
 W.frame:Show();W.Refresh()
end
function W.Toggle(tab)
 if W.frame and W.frame:IsShown() and (tab==nil or W.query.tab==tab) then W.frame:Hide();return end
 W.Show(tab)
end

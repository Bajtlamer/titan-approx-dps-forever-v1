-- Window behavior with stub frames: structure, tabs, search, scrolling, menus, no paging.
local ns={}
local all={}
local function object(kind,template,parent)
 local o={kind=kind,template=template,parent=parent,children={},scripts={},shown=true,w=0,h=0,value=0,min=0,max=0,enabled=true}
 setmetatable(o,{__index=function(t,k)
  if k=='SetText'then return function(self,x)self.text=x end end
  if k=='GetText'then return function(self)return self.text or ''end end
  if k=='SetScript'then return function(self,n,f)self.scripts[n]=f end end
  if k=='GetScript'then return function(self,n)return self.scripts[n]end end
  if k=='Show'then return function(self)self.shown=true end end
  if k=='Hide'then return function(self)self.shown=false end end
  if k=='SetShown'then return function(self,v)self.shown=v end end
  if k=='IsShown'then return function(self)return self.shown end end
  if k=='Enable'then return function(self)self.enabled=true end end
  if k=='Disable'then return function(self)self.enabled=false end end
  if k=='SetSize'then return function(self,w,h)self.w=w;self.h=h end end
  if k=='SetWidth'then return function(self,w)self.w=w end end
  if k=='SetHeight'then return function(self,h)self.h=h end end
  if k=='GetWidth'then return function(self)return self.w end end
  if k=='GetHeight'then return function(self)return self.h end end
  if k=='SetFontObject'then return function(self,f)self.font=f end end
  if k=='SetMinMaxValues'then return function(self,a,b)self.min=a;self.max=b end end
  if k=='SetValue'then return function(self,v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end end
  if k=='GetValue'then return function(self)return self.value end end
  if k=='CreateFontString'then return function(self)local c=object('FontString',nil,self);self.children[#self.children+1]=c;all[#all+1]=c;return c end end
  if k=='CreateTexture'then return function(self)local c=object('Texture',nil,self);self.children[#self.children+1]=c;return c end end
  return function()end
 end})
 return o
end
UIParent=object('Frame');UISpecialFrames={}
CreateFrame=function(kind,name,parent,template)local o=object(kind,template,parent);o.name=name;o.TitleText=object('FontString');all[#all+1]=o;if parent and parent.children then parent.children[#parent.children+1]=o end;return o end
local menus={}
MenuUtil={CreateContextMenu=function(owner,generator)
 local root={radios={}}
 function root:CreateRadio(label,selected,set)self.radios[#self.radios+1]={label=label,selected=selected,set=set}end
 function root:SetScrollMode()end
 generator(owner,root);menus[#menus+1]=root
end}
C_Spell={IsRangedAutoAttackSpell=function(id)return id==75 or id>=1000 end,GetSpellName=function(id)return ({[75]='Auto Shot',[3044]='Arcane Shot',[2973]='Raptor Strike'})[id] end}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','UI/ViewModel','UI/Widgets','UI/Window'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
ns.capabilities={damage=true,spells=true};ns.recorder={paused=false}
ns.TransferView={Show=function()end}
local PROFILE='16:30:0;17:empty;18:20:0'
local db=ns.Storage.Open({},'p');ns.store=db;local c=db:Character();c.class='HUNTER';c.name='Tester'
c.profiles[PROFILE]='|cff1eff00|Hitem:30:0|h[Staff]|h|r / |cff1eff00|Hitem:20:0|h[Bow]|h|r'
local many={{spellID=75,origin='player',damage={value=900}},{spellID=2973,origin='player',damage={value=100}}}
for id=1000,1039 do many[#many+1]={spellID=id,origin='player',damage={value=10}}end
local total=0;for _,s in ipairs(many)do total=total+s.damage.value end
for i=1,5 do db:UpsertContribution({receiptID='f'..i,profile=PROFILE,mode='pve',damage=total,seconds=10,context={targetName='Boar'},spells=many})end
db.saved.settings.mode='all'

ns.Window.Show('Overview')
local W=ns.Window
assert(W.frame and W.frame:IsShown(),'window shown')
assert(UISpecialFrames[1]=='TitanApproxDPSWindow','closes with Escape')

-- structure: six tabs, filters, search, no pagination controls anywhere
local labels={};for _,o in ipairs(all)do if type(rawget(o,'text'))=='string' then labels[#labels+1]=rawget(o,'text') end end
local joined=table.concat(labels,'|')
for _,tab in ipairs({'Overview','Weapons','Spells','Compare','History','Data'})do assert(W.tabButtons[tab],'tab '..tab)end
assert(not joined:find('Previous',1,true) and not joined:find('Next',1,true) and not joined:find('Page ',1,true),'no pagination')
assert(W.search and W.dropdowns.scope and W.dropdowns.category and W.dropdowns.period,'filters')
assert(not W.tabButtons.Overview.enabled and W.tabButtons.Weapons.enabled,'selected tab is disabled')
assert(W.dropdowns.scope.button.text=='Scope: All fights')

-- header uses the primary font and protected-value colors
assert(W.lifetime.font=='TitanApproxDPSPrimary' and W.lifetime.text:find('cffFFE680',1,true) and W.lifetime.text:find(ns.DamageNumber(db:Character().totalDamage),1,true))
assert(W.bestFight.text:find('cffFF8000',1,true),'record color')
assert(W.hint.font=='TitanApproxDPSHint' and #W.hint.text>20,'tips in the hint font')

-- every list has a scroll bar
for name,list in pairs(W.lists)do assert(list.slider and list.slider.kind=='Slider',name..' list has a scroll bar')end
local main=W.lists.main
assert(#main.rows==2 and main.pool[1].cells[1].text:find('Bow',1,true),'bow group is listed first')

-- detail list is virtualized and scrollable over all 42 spells
local detail=W.lists.detail
assert(#detail.rows==41,'all spells in the detail list, got '..#detail.rows)
assert(detail.visible<41 and detail.slider.max==41-detail.visible,'needs scrolling')
assert(detail.slider.shown,'scroll bar visible when needed')
local first=detail.pool[1].cells[1].text
detail.frame.scripts.OnMouseWheel(detail.frame,-1)
assert(detail.offset==3 and detail.pool[1].cells[1].text~=first,'wheel scrolls the list')
detail.slider.scripts.OnValueChanged(detail.slider,detail.slider.max)
assert(detail.offset==detail.slider.max,'scroll bar drags the list')
detail.frame.scripts.OnMouseWheel(detail.frame,-50);assert(detail.offset==detail.slider.max,'offset clamps at the end')
detail.frame.scripts.OnMouseWheel(detail.frame,50);assert(detail.offset==0,'offset clamps at the start')
assert(detail.pool[1].cells[1].text:find('Auto Shot',1,true) or detail.pool[1].cells[1].text:find('Spell',1,true))

-- tabs switch the columns and reset sorting
W.tabButtons.Spells.scripts.OnClick()
assert(W.query.tab=='Spells' and W.lists.main.columns[1].key=='spell' and not W.lists.detail.frame:IsShown(),'spells tab')
assert(#W.lists.main.rows==42)
-- search filters the list as you type and shows an empty state
W.search:SetText('arcane');W.search.scripts.OnTextChanged(W.search)
assert(W.query.search=='arcane' and #W.lists.main.rows==0 and W.lists.main.empty.shown,'empty state for a spell not present')
W.search:SetText('raptor');W.search.scripts.OnTextChanged(W.search)
assert(#W.lists.main.rows==1 and not W.lists.main.empty.shown)
W.search:SetText('');W.search.scripts.OnTextChanged(W.search);assert(#W.lists.main.rows==42)
-- headings sort, a second click reverses
local before=W.lists.main.pool[1].cells[1].text
W.lists.main.headers[1].scripts.OnClick(W.lists.main.headers[1])
local ascText=W.lists.main.pool[1].cells[1].text
W.lists.main.headers[1].scripts.OnClick(W.lists.main.headers[1])
assert(W.query.sortDesc==true and W.lists.main.pool[1].cells[1].text~=ascText,'second click reverses')
assert(W.lists.main.headers[1].label.text:find('desc',1,true),'active sort is shown')

-- drop-downs open the native menu with one radio per option and apply the choice
W.dropdowns.category.button.scripts.OnClick(W.dropdowns.category.button)
local menu=menus[#menus];assert(#menu.radios==6,'category menu has six options')
assert(menu.radios[1].selected()==true)
menu.radios[3].set();assert(W.query.category=='ranged' and W.dropdowns.category.button.text=='Category: Ranged')
W.dropdowns.scope.button.scripts.OnClick(W.dropdowns.scope.button)
menus[#menus].radios[3].set();assert(W.query.scope=='pvp' and db.saved.settings.mode=='pvp','scope is shared with the Titan tooltip')
menus[#menus].radios[1].set()
-- without MenuUtil a drop-down cycles through its options
local saveMenu=MenuUtil;MenuUtil=nil
W.dropdowns.period.button.scripts.OnClick(W.dropdowns.period.button);assert(W.query.period=='lifetime','fallback cycles')
MenuUtil=saveMenu;W.dropdowns.period.button.scripts.OnClick(W.dropdowns.period.button);menus[#menus].radios[1].set();assert(W.query.period=='period')

-- compare tab shows two weapon selectors
W.query.category='all';W.tabButtons.Compare.scripts.OnClick()
assert(W.dropdowns.compareA.button:IsShown() and W.dropdowns.compareB.button:IsShown(),'compare selectors visible')
W.tabButtons.History.scripts.OnClick();assert(not W.dropdowns.compareA.button:IsShown(),'selectors hidden elsewhere')
assert(W.lists.main.pool[1].cells[1].text:find('Boar',1,true),'history rows')
W.tabButtons.Data.scripts.OnClick();assert(#W.lists.main.rows>=8)

-- toggling
W.Toggle();assert(not W.frame:IsShown(),'toggle hides');W.Toggle();assert(W.frame:IsShown(),'toggle shows')
W.Show('Pets');assert(W.query.tab=='Overview','unknown tab falls back to Overview')
print('PASS window: tabs, filters, search, sortable scrolling lists with scroll bars, menus, compare selectors, no pagination')

-- Window behavior with stub frames, in two modes: native controls (drop-down menus, panel
-- tabs, search box, check box as in the Forever client) and the fallback without them.
local function run(native)
 local ns={}
 local all={}
 local calls={tabs=0,setTab=nil,numTabs=nil}
 local nativeTemplates={WowStyle1DropdownTemplate=true,PanelTabButtonTemplate=true,SearchBoxTemplate=true,UICheckButtonTemplate=true}
 local function object(kind,template,parent)
  local o={kind=kind,template=template,parent=parent,children={},scripts={},hooks={},shown=true,w=0,h=0,value=0,min=0,max=0,enabled=true,checked=false}
  setmetatable(o,{__index=function(t,k)
   if k=='SetText'then return function(self,x)self.text=x end end
   if k=='GetText'then return function(self)return self.text or ''end end
   if k=='SetScript'then return function(self,n,f)self.scripts[n]=f end end
   if k=='HookScript'then return function(self,n,f)self.hooks[n]=f end end
   if k=='Show'then return function(self)self.shown=true end end
   if k=='Hide'then return function(self)self.shown=false end end
   if k=='IsShown'then return function(self)return self.shown end end
   if k=='Enable'then return function(self)self.enabled=true end end
   if k=='Disable'then return function(self)self.enabled=false end end
   if k=='SetSize'then return function(self,w,h)self.w=w;self.h=h end end
   if k=='SetWidth'then return function(self,w)self.w=w end end
   if k=='SetHeight'then return function(self,h)self.h=h end end
   if k=='SetID'then return function(self,id)self.id=id end end
   if k=='SetFontObject'then return function(self,f)self.font=f end end
   if k=='SetMinMaxValues'then return function(self,a,b)self.min=a;self.max=b end end
   if k=='SetValue'then return function(self,v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end end
   if k=='GetValue'then return function(self)return self.value end end
   if k=='SetChecked'then return function(self,v)self.checked=v end end
   if k=='GetChecked'then return function(self)return self.checked end end
   if k=='SetupMenu'then return function(self,generator)self.menuGenerator=generator end end
   if k=='GenerateMenu'then return function(self)self.generated=(rawget(self,'generated') or 0)+1 end end
   if k=='CreateFontString'then return function(self)local c=object('FontString',nil,self);all[#all+1]=c;return c end end
   if k=='CreateTexture'then return function(self)return object('Texture',nil,self)end end
   if k=='GetThumbTexture'then return function(self)return object('Texture',nil,self)end end
   return function()end
  end})
  return o
 end
 UIParent=object('Frame');UISpecialFrames={}
 CreateFrame=function(kind,name,parent,template)
  if not native and (kind=='DropdownButton' or nativeTemplates[template]) then error('Unknown template '..tostring(template))end
  local o=object(kind,template,parent);o.name=name;o.TitleText=object('FontString')
  if template=='SearchBoxTemplate' then o.Instructions=object('FontString')end
  if template=='UICheckButtonTemplate' then o.Text=object('FontString')end
  all[#all+1]=o;return o
 end
 if native then
  PanelTemplates_SetNumTabs=function(_,n)calls.numTabs=n end
  PanelTemplates_SetTab=function(_,id)calls.setTab=id end
 else PanelTemplates_SetNumTabs=nil;PanelTemplates_SetTab=nil end
 local menus={}
 MenuUtil={CreateContextMenu=function(owner,generator)local root={radios={}};function root:CreateRadio(label,selected,set)self.radios[#self.radios+1]={label=label,selected=selected,set=set}end;function root:SetScrollMode()end;generator(owner,root);menus[#menus+1]=root end}
 C_Spell={IsRangedAutoAttackSpell=function(id)return id==75 or id>=1000 end,GetSpellName=function(id)return ({[75]='Auto Shot',[3044]='Arcane Shot',[2973]='Raptor Strike'})[id] end}
 for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','UI/ViewModel','UI/Widgets','UI/Window'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
 ns.capabilities={damage=true,spells=true};ns.recorder={paused=false};ns.TransferView={Show=function()end}
 local PROFILE='16:30:0;17:empty;18:20:0'
 local db=ns.Storage.Open({},'p');ns.store=db;local c=db:Character();c.class='HUNTER';c.name='Tester'
 c.profiles[PROFILE]='|cff1eff00|Hitem:30:0|h[Staff]|h|r / |cff1eff00|Hitem:20:0|h[Bow]|h|r'
 local many={{spellID=75,origin='player',damage={value=900}},{spellID=2973,origin='player',damage={value=100}}}
 for id=1000,1039 do many[#many+1]={spellID=id,origin='player',damage={value=10}}end
 local total=0;for _,s in ipairs(many)do total=total+s.damage.value end
 for i=1,5 do db:UpsertContribution({receiptID='f'..i,profile=PROFILE,mode='pve',damage=total,seconds=10,context={targetName='Boar'},spells=many})end
 db.saved.settings.mode='all'

 -- opening a drop-down menu: native frames carry a menu generator, the fallback opens a context menu
 local function open(dd)
  local root={radios={}}
  function root:CreateRadio(label,selected,set)self.radios[#self.radios+1]={label=label,selected=selected,set=set}end
  function root:SetScrollMode()end
  if dd.native then dd.frame.menuGenerator(nil,root)else dd.frame.scripts.OnClick(dd.frame);root=menus[#menus]end
  return root
 end
 local function typeInto(box,text)box:SetText(text);local fn=box.hooks.OnTextChanged or box.scripts.OnTextChanged;fn(box)end
 local function click(button)button.scripts.OnClick(button)end

 ns.Window.Show('Overview')
 local W=ns.Window
 local mode=native and 'native' or 'fallback'
 assert(W.frame and W.frame:IsShown(),mode..': window shown')
 assert(UISpecialFrames[1]=='TitanApproxDPSWindow','closes with Escape')

 -- native controls are really used when the client has them
 assert(W.tabs.native==native,mode..': tab kind')
 if native then
  assert(calls.numTabs==6 and calls.setTab==1,'panel tabs registered with PanelTemplates')
  assert(#rawget(W.frame,'Tabs')==6 and rawget(W.frame,'Tabs')[1]==W.tabButtons.Overview,'PanelTemplates finds the tabs through frame.Tabs')
  for _,tab in ipairs({'Overview','Weapons','Spells','Compare','History','Data'})do
   local b=W.tabButtons[tab];assert(b and b.template=='PanelTabButtonTemplate' and b.id,'native tab '..tab)
  end
  for _,key in ipairs({'scope','category','period','compareA','compareB'})do
   local dd=W.dropdowns[key];assert(dd.native and dd.frame.template=='WowStyle1DropdownTemplate' and dd.frame.kind=='DropdownButton','native drop-down '..key)
  end
  assert(W.search.template=='SearchBoxTemplate' and W.search.Instructions.text:find('Weapons',1,true),'native search box')
  assert(W.hiddenBox.native and W.hiddenBox.frame.template=='UICheckButtonTemplate' and W.hiddenBox.frame.Text.text=='Hidden weapons','native check box')
  for _,o in ipairs(all)do
   if o.kind=='Button' and rawget(o,'text') and (o.template=='UIPanelButtonTemplate') then
    local t=rawget(o,'text');assert(t~='Overview' and t~='Spells' and not t:find('Scope',1,true) and not t:find('Category',1,true),'no button imitates a tab or combo box')
   end
  end
 else
  for _,tab in ipairs({'Overview','Weapons','Spells','Compare','History','Data'})do assert(W.tabButtons[tab].template=='UIPanelButtonTemplate','fallback tab button')end
  assert(not W.dropdowns.scope.native and W.dropdowns.scope.frame.text=='Scope: All fights')
 end
 assert(W.tabButtons.Overview and W.tabButtons.Weapons)
 if not native then assert(not W.tabButtons.Overview.enabled and W.tabButtons.Weapons.enabled,'selected tab is disabled in fallback')end

 -- no pagination anywhere
 local labels={};for _,o in ipairs(all)do if type(rawget(o,'text'))=='string' then labels[#labels+1]=rawget(o,'text') end end
 local joined=table.concat(labels,'|')
 assert(not joined:find('Previous',1,true) and not joined:find('Next',1,true) and not joined:find('Page ',1,true),'no pagination')

 -- header uses the primary font and protected-value colors
 assert(W.lifetime.font=='TitanApproxDPSPrimary' and W.lifetime.text:find('cffFFE680',1,true))
 assert(W.bestFight.text:find('cffFF8000',1,true),'record color')
 assert(W.hint.font=='TitanApproxDPSHint' and #W.hint.text>20,'tips in the hint font')

 -- every list has a scroll bar; the detail list is virtualized and scrolls over all spells
 for name,list in pairs(W.lists)do assert(list.slider and list.slider.kind=='Slider',name..' list has a scroll bar')end
 local main,detail=W.lists.main,W.lists.detail
 assert(#main.rows==2 and main.pool[1].cells[1].text:find('Bow',1,true),'bow group is listed first')
 assert(#detail.rows==41 and detail.visible<41 and detail.slider.max==41-detail.visible,'detail needs scrolling over all spells')
 local first=detail.pool[1].cells[1].text
 detail.frame.scripts.OnMouseWheel(detail.frame,-1);assert(detail.offset==3 and detail.pool[1].cells[1].text~=first,'wheel scrolls')
 detail.slider.scripts.OnValueChanged(detail.slider,detail.slider.max);assert(detail.offset==detail.slider.max,'scroll bar drags')
 detail.frame.scripts.OnMouseWheel(detail.frame,-50);assert(detail.offset==detail.slider.max)
 detail.frame.scripts.OnMouseWheel(detail.frame,50);assert(detail.offset==0)

 -- tabs
 click(W.tabButtons.Spells)
 assert(W.query.tab=='Spells' and main.columns[1].key=='spell' and not detail.frame:IsShown() and #main.rows==42,'spells tab')
 if native then assert(calls.setTab==3,'PanelTemplates_SetTab follows the selected tab')end
 -- search
 typeInto(W.search,'arcane');assert(W.query.search=='arcane' and #main.rows==0 and main.empty.shown,'empty state')
 typeInto(W.search,'raptor');assert(#main.rows==1 and not main.empty.shown)
 typeInto(W.search,'');assert(#main.rows==42)
 -- sorting
 click(main.headers[1]);local asc=main.pool[1].cells[1].text
 click(main.headers[1]);assert(W.query.sortDesc==true and main.pool[1].cells[1].text~=asc and main.headers[1].label.text:find('desc',1,true))

 -- drop-downs
 local menu=open(W.dropdowns.category);assert(#menu.radios==6 and menu.radios[1].selected()==true)
 menu.radios[3].set();assert(W.query.category=='ranged')
 if native then assert((rawget(W.dropdowns.category.frame,'generated') or 0)>=1,'native menu regenerated to show the new value')
 else assert(W.dropdowns.category.frame.text=='Category: Ranged')end
 menu=open(W.dropdowns.scope);menu.radios[3].set();assert(W.query.scope=='pvp' and db.saved.settings.mode=='pvp','scope shared with Titan tooltip')
 open(W.dropdowns.scope).radios[1].set()
 W.query.category='all';W.Refresh()
 if not native then
  local saved=MenuUtil;MenuUtil=nil
  click(W.dropdowns.period.frame);assert(W.query.period=='lifetime','fallback cycles without MenuUtil')
  MenuUtil=saved;open(W.dropdowns.period).radios[1].set();assert(W.query.period=='period')
 end
 -- hidden weapons toggle
 if native then W.hiddenBox.frame:SetChecked(true);click(W.hiddenBox.frame);assert(W.query.showHidden==true)
 else click(W.hiddenBox.frame);assert(W.query.showHidden==true)end
 if native then W.hiddenBox.frame:SetChecked(false);click(W.hiddenBox.frame)else click(W.hiddenBox.frame)end
 assert(W.query.showHidden==false)

 -- compare tab: two selectors, switching weapons
 click(W.tabButtons.Compare)
 assert(W.dropdowns.compareA.frame:IsShown() and W.dropdowns.compareB.frame:IsShown(),'selectors visible')
 local options=open(W.dropdowns.compareA);assert(#options.radios==2)
 options.radios[2].set();assert(W.query.compareA==W.result.compare.options[2].key)
 click(W.tabButtons.History);assert(not W.dropdowns.compareA.frame:IsShown(),'selectors hidden elsewhere')
 assert(main.pool[1].cells[1].text:find('Boar',1,true),'history rows')
 click(W.tabButtons.Data);assert(#main.rows>=8)

 -- toggling and unknown tab names
 W.Toggle();assert(not W.frame:IsShown());W.Toggle();assert(W.frame:IsShown())
 W.Show('Pets');assert(W.query.tab=='Overview')
 print('PASS window ('..mode..' controls): tabs, drop-downs, search, check box, scrolling lists with scroll bars, no pagination')
end
run(true)
run(false)

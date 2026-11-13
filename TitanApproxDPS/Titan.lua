local _,ns=...
local T={};ns.Titan=T
local S=ns.Style
local colors=S.colors
local function number(v)return ns.DamageNumber(v)end
local function colored(value,color)return S.Color(value,color)end
local function metric(value,color)
 return colored(value,value=='Unavailable' and colors.unavailable or color)
end
local function pair(left,leftColor,right,rightColor)
 return metric(left,leftColor)..colored(' / ',colors.separator)..metric(right,rightColor)
end
local spellName=ns.SpellName
local function scopeName(mode)return ({all='All fights',pve='PvE',pvp='PvP',mixed='Mixed PvE/PvP',unknown='Combat type not verified'})[mode] or mode end
local function separator(tip)
 tip:AddLine(' ');S.Style(tip,'hint')
 local name=tip.GetName and tip:GetName();local line=name and _G[name..'TextLeft'..tip:NumLines()]
 if line then
  local rule=tip.rules[tip.ruleCount+1]
  if not rule then rule=tip:CreateTexture(nil,'ARTWORK');rule:SetColorTexture(.55,.55,.55,.7);rule:SetHeight(1);tip.rules[#tip.rules+1]=rule end
  tip.ruleCount=tip.ruleCount+1;rule:ClearAllPoints();rule:SetPoint('LEFT',line,'LEFT',0,-4);rule:SetPoint('RIGHT',tip,'RIGHT',-12,0);rule:Show()
 end
end
-- Row helpers: each line gets a color per value type and one of three text levels.
local function title(tip,text)
 local r,g,b=S.rgb(colors.title);tip:AddLine(text,r,g,b);S.Style(tip,'title')
end
local function hint(tip,text)
 local r,g,b=S.rgb(colors.hint);tip:AddLine(text,r,g,b,true);S.Style(tip,'hint')
end
local function row(tip,label,value,level,labelColor)
 local r,g,b=S.rgb(labelColor or colors.label)
 tip:AddDoubleLine(label,value,r,g,b,1,1,1);S.Style(tip,'body',level or 'body')
end
local MAX_SPELLS=3
function T.Render(tip)
 local c=ns.store:Character();if not c then return end
 local mode=ns.store.saved.settings.mode;local report=ns.Reports.Build(ns.store,mode)
 title(tip,'Titan Approx DPS '..ns.version)
 row(tip,'Character lifetime',metric(number(report.characterDamage),colors.lifetime),'primary',colors.title)
 local best=c.records and c.records.character and c.records.character.fightDamage
 if best then row(tip,'Best fight (protected)',metric(number(best.value),colors.record))end
 hint(tip,'Scope: '..scopeName(mode)..' | Your recorded damage')
 if report.preservedDamage>0 then hint(tip,'Includes '..number(report.preservedDamage)..' protected damage from earlier history.')end
 for _,g in ipairs(report.groups)do
  separator(tip)
  local kind=g.kind or 'other'
  local rr,rg,rb=1,1,1
  tip:AddDoubleLine(g.name,colored(ns.Categories and ns.Categories.Label(kind) or kind,colors.kind[kind] or colors.kind.other),rr,rg,rb,1,1,1);S.Style(tip,'title','hint')
  local st=g.stats and g.stats.period
  if st and st.n>0 then
   local value=metric(string.format('%.1f',st.typical),colors.dps)
   row(tip,'Typical DPS',value,'primary',colors.title)
   local spread=st.spread and (' | +/-'..string.format('%.0f%%',st.spread*100)) or ''
   hint(tip,st.n..(st.n==1 and ' fight, confidence ' or ' fights, confidence ')..colored(st.confidence,colors.confidence[st.confidence] or colors.unavailable)..spread)
   if st.recentMedian then row(tip,'Recent DPS (last '..st.recentCount..')',metric(string.format('%.1f',st.recentMedian),colors.dps))end
   local life=g.stats.lifetime
   if life.n~=st.n and life.typical then row(tip,'Typical DPS, all periods ('..life.n..' fights)',metric(string.format('%.1f',life.typical),colors.dps))end
  else
   row(tip,'Typical DPS',metric('Unavailable',colors.dps),'primary',colors.title)
   hint(tip,'Needs fights of at least 10 seconds.')
  end
  if g.records and (g.records.fightDamage or g.records.fightDPS) then
   local bestFight=g.records.fightDamage and number(g.records.fightDamage.value) or 'Unavailable'
   local bestDps=g.records.fightDPS and string.format('%.1f',g.records.fightDPS.value) or 'Unavailable'
   row(tip,'Best fight / Best DPS (protected)',pair(bestFight,colors.record,bestDps,colors.record))
  end
  row(tip,g.slot and 'Weapon lifetime' or 'Lifetime damage in this category',metric(number(g.lifetimeDamage),colors.lifetime))
  if g.lifetimeDamage~=g.damage then row(tip,'Report period damage',metric(number(g.damage),colors.damage))end
  row(tip,'Auto-attacks / abilities',pair(number(g.autoDamage),colors.damage,number(g.abilityDamage),colors.ability))
  for i,spell in ipairs(g.spells)do
   if i>MAX_SPELLS then break end
   local share=spell.percent and string.format('%.1f%%',spell.percent) or 'Unavailable'
   row(tip,spellName(spell.spellID),pair(number(spell.damage),colors.damage,share,colors.percent))
  end
  if #g.spells>MAX_SPELLS then hint(tip,'+'..(#g.spells-MAX_SPELLS)..' more spells: right click > Weapon results lists all of them.')end
  if #g.spells==0 then hint(tip,'No readable spell breakdown for this damage')end
  if g.unattributed>0 then row(tip,'Damage without spell details',metric(number(g.unattributed),colors.damage))end
  if g.overlap then local wr,wg,wb=S.rgb(colors.warning);tip:AddLine('Native spell breakdown is inconsistent; totals kept without weapon assignment.',wr,wg,wb,true);S.Style(tip,'hint')end
 end
 if #report.groups==0 then hint(tip,c.reportGeneration and next(c.reportRows or {})==nil and 'Fresh weapon reports: waiting for a completed fight.' or 'No visible results in this scope. Right click to change filters.')end
 separator(tip)
 hint(tip,'Percentages use the damage total of each group. Typical DPS counts fights of 10 seconds or more.')
 hint(tip,'Right click: settings, all spells, filters and fresh reports.')
end
function T.Show(owner)
 if not ns.store then return end
 if not T.tooltip then
  T.tooltip=CreateFrame('GameTooltip','TitanApproxDPSSummary',UIParent,'GameTooltipTemplate');T.tooltip.rules={};T.tooltip.ruleCount=0
 end
 local tip=T.tooltip;T.owner=owner
 for _,r in ipairs(tip.rules)do r:Hide()end;tip.ruleCount=0
 tip:SetOwner(owner or UIParent,'ANCHOR_NONE');tip:ClearAllPoints()
 local bottom=owner and owner.GetBottom and owner:GetBottom();local height=UIParent:GetHeight()
 if type(bottom)=='number' and bottom<height/2 then tip:SetPoint('BOTTOMLEFT',owner,'TOPLEFT',0,4)else tip:SetPoint('TOPLEFT',owner or UIParent,'BOTTOMLEFT',0,-4)end
 tip:ClearLines();T.Render(tip);tip:Show()
end
function T.Hide()T.owner=nil;if T.tooltip then T.tooltip:Hide()end end
function T.Refresh()
 if not ns.store then return end
 local c=ns.store:Character();if T.broker and c then T.broker.text=number(c.totalDamage)..' lifetime'end
 if T.owner then T.Show(T.owner)end
end
function T.Menu(owner)
 T.Hide()
 if not MenuUtil or not MenuUtil.CreateContextMenu then ns.Window.Show('Data');return end
 MenuUtil.CreateContextMenu(owner or UIParent,function(_,root)
  root:CreateTitle('Titan Approx DPS '..ns.version)
  root:CreateTitle('Character lifetime: '..number(ns.store:Character().totalDamage))
  local others={};for key,other in pairs(ns.store.saved.characters)do if key~=ns.store.id then others[#others+1]=other end end
  if #others>0 then local characters=root:CreateButton('Other character lifetime totals');for _,other in ipairs(others)do characters:CreateTitle((other.name or 'Recorded character')..': '..number(other.totalDamage))end end
  local results=root:CreateButton('Weapon results');if results.SetScrollMode then results:SetScrollMode(350)end
  local report=ns.Reports.Build(ns.store,ns.store.saved.settings.mode)
  for _,g in ipairs(report.groups)do
   local group=g;local entry=results:CreateButton(group.name);if entry.SetScrollMode then entry:SetScrollMode(350)end
   if group.lifetimeDamage~=group.damage then entry:CreateTitle((group.slot and 'Weapon lifetime (all report periods): ' or 'All-time category damage: ')..number(group.lifetimeDamage))end
   entry:CreateTitle('Report damage: '..number(group.damage))
   for _,s in ipairs(group.spells)do entry:CreateTitle(spellName(s.spellID)..': '..number(s.damage)..' ('..(s.percent and string.format('%.1f%%',s.percent) or 'Unavailable')..')')end
  end
  local rules=root:CreateButton('Ability rules');if rules.SetScrollMode then rules:SetScrollMode(350)end
  local class=ns.store:Character().class;local list=ns.SpellRules.List(class)
  rules:CreateTitle('Recorded class: '..(class or 'Not verified'))
  rules:CreateTitle('Weapon totals include associated abilities.')
  rules:CreateTitle('Unlisted spell IDs stay unresolved.')
  rules:CreateTitle('Dual-wield swings require hand evidence.')
  for _,rule in ipairs(list)do
   local entry=rules:CreateButton(rule.name..': '..ns.SpellRules.TargetLabel(rule)..' ('..#rule.ids..' IDs)')
   if entry.SetScrollMode then entry:SetScrollMode(350)end
   entry:CreateTitle('Supported spell IDs: '..table.concat(rule.ids,', '))
   entry:CreateTitle('Requires a verified player-origin record.')
  end
  if #list==0 then rules:CreateTitle('No class-specific ability rules for this class.')end
  local filters=root:CreateButton('Report scope')
  for _,value in ipairs({'all','pve','pvp','mixed','unknown'})do local mode=value
   filters:CreateRadio(scopeName(mode),function()return ns.store.saved.settings.mode==mode end,function()ns.store.saved.settings.mode=mode;T.Refresh()end)
  end
  local visibility=root:CreateButton('Visible weapons');if visibility.SetScrollMode then visibility:SetScrollMode(350)end
  visibility:CreateTitle('Hiding preserves weapon and character lifetime data.')
  local c=ns.store:Character();local keys={};local labels={};for _,g in ipairs(ns.Reports.Build(ns.store,'all',nil,true).groups)do keys[#keys+1]=g.profile;labels[g.profile]=g.name end;table.sort(keys)
  for _,key in ipairs(keys)do local profile=key
   visibility:CreateCheckbox(labels[profile],function()return not(c.reportHidden and c.reportHidden[profile])end,function()ns.Reports.SetHidden(ns.store,profile,not(c.reportHidden and c.reportHidden[profile]));T.Refresh()end)
  end
  visibility:CreateButton('Show all weapons',function()for key in pairs(c.reportHidden or {})do ns.Reports.SetHidden(ns.store,key,false)end;T.Refresh()end)
  local reset=root:CreateButton('Start fresh weapon reports')
  reset:CreateTitle('Reset current weapon/spell reports only.')
  reset:CreateTitle('Character and weapon lifetime records are kept.')
  reset:CreateButton('Confirm fresh reports',function()if ns.ResetWeaponReports then ns.ResetWeaponReports()end end)
  root:CreateButton('Reset minimap position',function()ns.Minimap.ResetPosition()end)
  local fights=root:CreateButton('Recent test fights');if fights.SetScrollMode then fights:SetScrollMode(350)end
  local fightCount=0
  for i=#c.history,math.max(1,#c.history-19),-1 do local receipt=c.receipts[c.history[i]]
   if receipt and (receipt.reportGeneration or 0)==(c.reportGeneration or 0)then
    fightCount=fightCount+1;local r=receipt;local context=r.context or {};local entry=fights:CreateButton((context.targetName or 'Target not recorded')..' - '..number(r.damage)..' damage');if entry.SetScrollMode then entry:SetScrollMode(350)end
    entry:CreateTitle('Native session: '..tostring(r.nativeSessionID or 'Not recorded'))
    entry:CreateTitle('Source: local player only; party totals excluded')
    entry:CreateTitle('Target at combat start: '..(context.targetName or 'Not recorded'))
    entry:CreateTitle('Target changes: '..tostring(context.targetChanges or 'Not recorded'))
    entry:CreateTitle('Grouped: '..(context.grouped==true and 'Yes' or context.grouped==false and 'No' or 'Not recorded'))
    for _,spell in ipairs(r.spells)do entry:CreateTitle(spellName(spell.spellID)..' [spell '..spell.spellID..']: '..number(spell.damage.value)..' ('..(spell.origin or 'source not recorded')..')')end
   end
  end
  if fightCount==0 then fights:CreateTitle('No completed fights in this report period.')end
  root:CreateCheckbox('Record completed fights' ,function()return not ns.recorder.paused end,function()ns.recorder:Pause(not ns.recorder.paused);if not ns.recorder.paused and ns.Rebaseline then ns.Rebaseline()end end)
  root:CreateCheckbox('Show minimap launcher',function()return ns.store.saved.settings.minimap end,function()local s=ns.store.saved.settings;s.minimap=not s.minimap;ns.Minimap.button:SetShown(s.minimap)end)
  root:CreateButton('Export statistics',function()ns.TransferView.Show(false)end)
  root:CreateButton('Import statistics',function()ns.TransferView.Show(true)end)
  root:CreateButton('Detailed reports',function()ns.Window.Show('Overview')end)
  root:CreateButton('Diagnostics',function()ns.Window.Show('Data')end)
 end)
end
function T.Initialize()
 local ldb=LibStub and LibStub:GetLibrary('LibDataBroker-1.1',true);if not ldb then return end
 T.broker=ldb:NewDataObject('TitanApproxDPS',{type='data source',label='Approx DPS',text='Lifetime',icon='Interface\\Icons\\Ability_Warrior_Charge',
 OnEnter=T.Show,OnLeave=T.Hide,OnClick=function(owner,button)if button=='RightButton'then T.Menu(owner)else T.Hide();ns.Window.Toggle()end end})
 T.Refresh()
end

local _,ns=...
-- Adds a rough comparison to weapon item tooltips. Outside combat only.
local H={}
ns.TooltipHook=H
local S=ns.Style
local colors=S.colors
local function color(text,hex)return S.Color(text,hex)end
local function signed(value,fmt)
 local text=string.format(fmt or '%.1f',math.abs(value))
 return (value>=0 and '+' or '-')..text
end
local function tone(value)return value>=0 and colors.good or colors.bad end
local function itemVariant(link)
 local value=link:match('item:([%d:%-]+)')
 if not value or not tonumber(value:match('^(%d+)')) then return nil end
 return ns.WeaponAttribution.Variant(value)
end

local function makeUI(tip)
 local ui={}
 function ui.row(label,value,labelColor)
  local r,g,b=S.rgb(labelColor or colors.label)
  tip:AddDoubleLine(label,value,r,g,b,1,1,1);S.Style(tip,'body','body',true)
 end
 function ui.hint(text)
  local r,g,b=S.rgb(colors.hint);tip:AddLine(text,r,g,b,true);S.Style(tip,'hint','hint',true)
 end
 function ui.percent(label,percent)
  local r,g,b=S.rgb(colors.title)
  tip:AddDoubleLine(label,color(signed(percent)..'%',tone(percent)),r,g,b,1,1,1);S.Style(tip,'body','primary',true)
 end
 return ui
end

-- Derived effects of the stat change (attack power, health, mana, crit points).
local function derivedRows(ui,d,api)
 if not d then return end
 local function line(label,value,fmt)ui.row(label,color(signed(value,fmt),tone(value)))end
 if d.meleeAP then line('Melee attack power',d.meleeAP,'%.0f')end
 if d.rangedAP then line('Ranged attack power',d.rangedAP,'%.0f')end
 if d.spellPower then line('Spell power',d.spellPower,'%.0f')end
 if d.hp then line('Max health (base)',d.hp,'%.0f')end
 if d.mana then line('Max mana (base)',d.mana,'%.0f')end
 if d.physCrit then line('Physical crit chance (points)',d.physCrit,'%.2f')end
 if d.spellCrit then line('Spell crit chance (points)',d.spellCrit,'%.2f')end
 for _,note in ipairs(d.notes)do ui.hint(note)end
 if #d.unmodelled>0 then
  local names={};for i,key in ipairs(d.unmodelled)do names[i]=ns.Compare.Label(key,api)end
  ui.hint('Effect not modelled: '..table.concat(names,', ')..'.')
 end
end

-- Estimate lines shared by weapon and gear tooltips.
local function spellRows(ui,estimate)
 if estimate.spell then
  local sp=estimate.spell
  ui.percent('Estimated change, your spell damage',sp.percent)
  ui.row('Calibrated on '..sp.fights..' fights, confidence '..color(sp.confidence,colors.confidence[sp.confidence] or colors.unavailable),
   color(signed(sp.deltaDps)..' DPS',tone(sp.deltaDps))..color(' of ',colors.separator)..color(string.format('%.1f',sp.meanDps),colors.dps))
  ui.hint(string.format('Straight-line fit of your spell damage on spell power (fit %.2f). Other stats are not included.',sp.r2))
 elseif estimate.spellReason and not estimate.spellReason:find('no spell power',1,true) then
  ui.hint(estimate.spellReason)
 end
end

local function currentCharacter(store)
 return store and store.Character and store:Character()
end
local function pickGroup(report,slot,variant)
 local group
 for _,g in ipairs(report.groups)do
  if g.slot==slot and g.profile=='slot:'..slot..':'..variant and (not group or g.damage>group.damage) then group=g end
 end
 return group
end

-- Returns the Compare result and the equipped group, or nil when nothing applies.
function H.Evaluate(link,api,store)
 if type(link)~='string' then return nil end
 if type(api.InCombatLockdown)=='function' and api.InCombatLockdown() then return nil end
 local info=api.C_Item and api.C_Item.GetItemInfoInstant
 if type(info)~='function' then return nil end
 local _,_,_,equipLoc,_,classID=info(link)
 if classID~=2 then return nil end
 local slot=ns.Compare.SlotFor(equipLoc);if not slot then return nil end
 local equipped=api.GetInventoryItemLink and api.GetInventoryItemLink('player',slot)
 if type(equipped)~='string' then return nil end
 local hoveredVariant,equippedVariant=itemVariant(link),itemVariant(equipped)
 if not hoveredVariant or not equippedVariant or hoveredVariant==equippedVariant then return nil end
 local newStats=ns.Compare.ItemStats(link,api);local oldStats=ns.Compare.ItemStats(equipped,api)
 local group
 if store and ns.Reports then group=pickGroup(ns.Reports.Build(store,'all',api),slot,equippedVariant)end
 local result=ns.Compare.Compare(newStats,oldStats,group)
 if not result then return nil end
 local character=currentCharacter(store)
 if character and ns.Estimator then
  local ok,estimate=pcall(ns.Estimator.ForItem,character,group,newStats,oldStats)
  if ok then result.estimate=estimate end
 end
 if character and ns.ItemEffects then
  local ok,derived=pcall(function()return ns.ItemEffects.Derive(character.class,newStats,oldStats,ns.ItemEffects.Context(api,character.class))end)
  if ok then result.derived=derived end
 end
 return result,group
end

function H.Render(tip,link,api,store)
 api=api or _G
 local ok,result,group=pcall(H.Evaluate,link,api,store or ns.store)
 if not ok then return false end
 if not result then return H.RenderGear(tip,link,api,store) end
 if tip.HookScript and not tip.tadpsHooked then tip:HookScript('OnTooltipCleared',S.Restore);tip.tadpsHooked=true end
 local ui=makeUI(tip);local row,hint=ui.row,ui.hint
 tip:AddLine(' ');S.Style(tip,'hint','hint',true)
 local tr,tg,tb=S.rgb(colors.title)
 tip:AddLine('Titan Approx DPS: rough comparison with equipped',tr,tg,tb);S.Style(tip,'body','body',true)
 local d=result.weaponDps
 if d.new and d.old then
  row('Weapon DPS (this / equipped)',color(string.format('%.1f',d.new),colors.dps)..color(' / ',colors.separator)..color(string.format('%.1f',d.old),colors.dps))
  if d.percent then
   local r,g,b=S.rgb(colors.title)
   tip:AddDoubleLine('Weapon DPS change',color(signed(d.percent)..'%',tone(d.percent)),r,g,b,1,1,1);S.Style(tip,'body','primary',true)
  end
 end
 local estimate=result.estimate or {}
 local percentRow=ui.percent
 if estimate.auto then
  local a=estimate.auto
  percentRow('Estimated change, auto-attacks of the equipped weapon',a.percent)
  row('Calibrated on '..a.fights..' fights, confidence '..color(a.confidence,colors.confidence[a.confidence] or colors.unavailable),
   color(signed(a.deltaDps)..' DPS',tone(a.deltaDps))..color(' of ',colors.separator)..color(string.format('%.1f',a.groupTypical),colors.dps))
  hint(string.format('Your fights show auto-attacks reach %.0f%% of weapon DPS plus attack power / 14. Abilities, procs and enchants are not included.',a.k*100))
 elseif result.rough then
  local r=result.rough
  row('Rough effect on your auto-attack damage',color(signed(r.percent)..'%',tone(r.percent)),colors.title)
  row('Your typical DPS ('..r.fights..(r.fights==1 and ' fight' or ' fights')..', '..color(r.confidence,colors.confidence[r.confidence] or colors.unavailable)..')',color(string.format('%.1f',group.stats.period.typical),colors.dps)..color(' > about ',colors.separator)..color(string.format('%.1f',r.typical),colors.dps))
  hint(string.format('Auto-attacks were %.0f%% of your recorded damage with the equipped weapon. Abilities and stat scaling are not included.',r.autoShare*100))
  if estimate.autoReason then hint(estimate.autoReason)end
 else
  hint('No fight data for the equipped weapon yet, so only the item values are compared.')
  if estimate.autoReason then hint(estimate.autoReason)end
 end
 spellRows(ui,estimate)
 for i,s in ipairs(result.stats)do
  if i>8 then break end
  row(ns.Compare.Label(s.key,api),color(signed(s.delta,'%d'),tone(s.delta)))
 end
 derivedRows(ui,result.derived,api)
 return true
end

-- Non-weapon gear: one entry per slot the item could take, each with the derived effects and
-- the calibrated damage estimate. Returns nil when nothing applies.
function H.EvaluateGear(link,api,store)
 if type(link)~='string' or not ns.ItemEffects then return nil end
 if type(api.InCombatLockdown)=='function' and api.InCombatLockdown() then return nil end
 local info=api.C_Item and api.C_Item.GetItemInfoInstant
 if type(info)~='function' then return nil end
 local _,_,_,equipLoc,_,classID=info(link)
 if classID~=4 then return nil end
 local slots=ns.Compare.GearSlots(equipLoc);if not slots then return nil end
 local character=currentCharacter(store)
 if not character or not character.class then return nil end
 local newStats=ns.Compare.ItemStats(link,api);if not newStats then return nil end
 local variant=itemVariant(link)
 local ctx=ns.ItemEffects.Context(api,character.class)
 local weapons
 local function weapon(slot,kind,report)
  local equipped=api.GetInventoryItemLink and api.GetInventoryItemLink('player',slot)
  if type(equipped)~='string' then return end
  local v=itemVariant(equipped);local stats=ns.Compare.ItemStats(equipped,api)
  if not v or not stats then return end
  local group=pickGroup(report,slot,v)
  if group and group.kind==kind then weapons[kind]={group=group,stats=stats}end
 end
 if ns.Reports and ns.Estimator then
  weapons={}
  local report=ns.Reports.Build(store,'all',api)
  weapon(16,'melee',report);weapon(18,'ranged',report)
 end
 local entries={}
 for _,slot in ipairs(slots)do
  local equipped=api.GetInventoryItemLink and api.GetInventoryItemLink('player',slot)
  local oldStats,skip={},false
  if type(equipped)=='string' then
   local equippedVariant=itemVariant(equipped)
   oldStats=ns.Compare.ItemStats(equipped,api)
   if not oldStats or not variant or not equippedVariant or variant==equippedVariant then skip=true end
  end
  if not skip then
   local derived=ns.ItemEffects.Derive(character.class,newStats,oldStats,ctx)
   if derived then
    local entry={slot=slot,derived=derived,stats=ns.Compare.Compare(newStats,oldStats,nil).stats,empty=type(equipped)~='string'}
    if weapons then
     local ok,estimate=pcall(ns.Estimator.ForGear,character,derived,weapons,newStats,oldStats)
     if ok then entry.estimate=estimate end
    end
    entries[#entries+1]=entry
   end
  end
 end
 if #entries==0 then return nil end
 return entries
end

function H.RenderGear(tip,link,api,store)
 api=api or _G
 local ok,entries=pcall(H.EvaluateGear,link,api,store or ns.store)
 if not ok or not entries then return false end
 if tip.HookScript and not tip.tadpsHooked then tip:HookScript('OnTooltipCleared',S.Restore);tip.tadpsHooked=true end
 local ui=makeUI(tip)
 local tr,tg,tb=S.rgb(colors.title)
 for _,entry in ipairs(entries)do
  local d=entry.derived;local estimate=entry.estimate or {}
  tip:AddLine(' ');S.Style(tip,'hint','hint',true)
  tip:AddLine('Titan Approx DPS: effect of this item, '..ns.Compare.SlotName(entry.slot)..(entry.empty and ' (empty slot)' or ' (vs equipped)'),tr,tg,tb);S.Style(tip,'body','body',true)
  for i,s in ipairs(entry.stats)do
   if i>8 then break end
   ui.row(ns.Compare.Label(s.key,api),color(signed(s.delta,'%d'),tone(s.delta)))
  end
  derivedRows(ui,d,api)
  local affectsDamage=d.meleeAP or d.rangedAP or d.spellPower or d.physCrit or d.spellCrit
  if not affectsDamage then
   ui.row('Damage',color('no change from these stats',colors.label),colors.title)
  else
   for _,a in ipairs(estimate.autos or {})do
    ui.percent('Estimated change, your '..a.kind..' auto-attacks',a.percent)
    ui.row('Calibrated on '..a.fights..' fights, confidence '..color(a.confidence,colors.confidence[a.confidence] or colors.unavailable),
     color(signed(a.deltaDps)..' DPS',tone(a.deltaDps))..color(' of ',colors.separator)..color(string.format('%.1f',a.groupTypical),colors.dps))
   end
   for _,reason in ipairs(estimate.autoReasons or {})do ui.hint(reason)end
   spellRows(ui,estimate)
   if d.physCrit or d.spellCrit then ui.hint('Crit change is shown but not included in the estimate.')end
   if not estimate.autos and not estimate.spell and not d.meleeAP and not d.rangedAP and not d.spellPower then
    ui.hint('The damage effect of crit alone is not estimated.')
   end
  end
 end
 return true
end

function H.Attach(api)
 api=api or _G
 local processor=api.TooltipDataProcessor
 if not processor or type(processor.AddTooltipPostCall)~='function' or not api.Enum or not api.Enum.TooltipDataType or not api.Enum.TooltipDataType.Item then return false end
 processor.AddTooltipPostCall(api.Enum.TooltipDataType.Item,function(tip,data)
  if tip~=api.GameTooltip and tip~=api.ItemRefTooltip then return end
  local link=data and data.hyperlink
  if not link and tip.GetItem then local _,l=tip:GetItem();link=l end
  H.Render(tip,link,api,ns.store)
 end)
 return true
end

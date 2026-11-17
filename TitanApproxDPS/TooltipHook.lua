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
 if store and ns.Reports then
  for _,g in ipairs(ns.Reports.Build(store,'all',api).groups)do
   if g.slot==slot and g.profile=='slot:'..slot..':'..equippedVariant and (not group or g.damage>group.damage) then group=g end
  end
 end
 local result=ns.Compare.Compare(newStats,oldStats,group)
 if not result then return nil end
 local character=store and store.Character and store:Character()
 if character and ns.Estimator then
  local ok,estimate=pcall(ns.Estimator.ForItem,character,group,newStats,oldStats)
  if ok then result.estimate=estimate end
 end
 return result,group
end

function H.Render(tip,link,api,store)
 api=api or _G
 local ok,result,group=pcall(H.Evaluate,link,api,store or ns.store)
 if not ok or not result then return false end
 if tip.HookScript and not tip.tadpsHooked then tip:HookScript('OnTooltipCleared',S.Restore);tip.tadpsHooked=true end
 local function row(label,value,labelColor)
  local r,g,b=S.rgb(labelColor or colors.label)
  tip:AddDoubleLine(label,value,r,g,b,1,1,1);S.Style(tip,'body','body',true)
 end
 local function hint(text)
  local r,g,b=S.rgb(colors.hint);tip:AddLine(text,r,g,b,true);S.Style(tip,'hint','hint',true)
 end
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
 local function percentRow(label,percent)
  local r,g,b=S.rgb(colors.title)
  tip:AddDoubleLine(label,color(signed(percent)..'%',tone(percent)),r,g,b,1,1,1);S.Style(tip,'body','primary',true)
 end
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
 if estimate.spell then
  local sp=estimate.spell
  percentRow('Estimated change, your spell damage',sp.percent)
  row('Calibrated on '..sp.fights..' fights, confidence '..color(sp.confidence,colors.confidence[sp.confidence] or colors.unavailable),
   color(signed(sp.deltaDps)..' DPS',tone(sp.deltaDps))..color(' of ',colors.separator)..color(string.format('%.1f',sp.meanDps),colors.dps))
  hint(string.format('Straight-line fit of your spell damage on spell power (fit %.2f). Other stats are not included.',sp.r2))
 elseif estimate.spellReason and not estimate.spellReason:find('no spell power',1,true) then
  hint(estimate.spellReason)
 end
 for i,s in ipairs(result.stats)do
  if i>8 then break end
  row(ns.Compare.Label(s.key,api),color(signed(s.delta,'%d'),tone(s.delta)))
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

local _,ns=...
-- Adds a rough comparison to weapon item tooltips. Outside combat only.
local H={}
ns.TooltipHook=H
local GOOD,BAD,HINT,GOLD='7FD694','FF6B6B','B8B8B8','FFD76A'
local function color(text,hex)return '|cff'..hex..text..'|r' end
local function signed(value,fmt)
 local text=string.format(fmt or '%.1f',math.abs(value))
 return (value>=0 and '+' or '-')..text
end
local function tone(value)return value>=0 and GOOD or BAD end
local function itemID(link)return tonumber(tostring(link):match('item:(%d+)'))end

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
 local hoveredID,equippedID=itemID(link),itemID(equipped)
 if not hoveredID or hoveredID==equippedID then return nil end
 local newStats=ns.Compare.ItemStats(link,api);local oldStats=ns.Compare.ItemStats(equipped,api)
 local group
 if store and ns.Reports then
  for _,g in ipairs(ns.Reports.Build(store,'all',api).groups)do
   if g.slot==slot and g.profile:find('^slot:'..slot..':'..equippedID..':') and (not group or g.damage>group.damage) then group=g end
  end
 end
 local result=ns.Compare.Compare(newStats,oldStats,group)
 if not result then return nil end
 return result,group
end

function H.Render(tip,link,api,store)
 api=api or _G
 local ok,result,group=pcall(H.Evaluate,link,api,store or ns.store)
 if not ok or not result then return false end
 tip:AddLine(' ')
 tip:AddLine('Titan Approx DPS: rough comparison with equipped',1,.82,.2)
 local d=result.weaponDps
 if d.new and d.old then
  tip:AddDoubleLine('Weapon DPS (this / equipped)',string.format('%.1f / %.1f',d.new,d.old),1,1,1,1,1,1)
  if d.percent then tip:AddDoubleLine('Weapon DPS change',color(signed(d.percent)..'%',tone(d.percent)),1,1,1,1,1,1)end
 end
 if result.rough then
  local r=result.rough
  tip:AddDoubleLine('Rough effect on your auto-attack damage',color(signed(r.percent)..'%',tone(r.percent)),1,1,1,1,1,1)
  tip:AddDoubleLine('Your typical DPS ('..r.fights..(r.fights==1 and ' fight' or ' fights')..', '..r.confidence..')',string.format('%.1f > about %.1f',group.stats.period.typical,r.typical),.8,.8,.8,1,1,1)
  tip:AddLine(string.format('Auto-attacks were %.0f%% of your recorded damage with the equipped weapon. Abilities and stat scaling are not included.',r.autoShare*100),.72,.72,.72,true)
 else
  tip:AddLine('No fight data for the equipped weapon yet, so only the item values are compared.',.72,.72,.72,true)
 end
 for i,s in ipairs(result.stats)do
  if i>8 then break end
  tip:AddDoubleLine(ns.Compare.Label(s.key,api),color(signed(s.delta,'%d'),tone(s.delta)),.8,.8,.8,1,1,1)
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

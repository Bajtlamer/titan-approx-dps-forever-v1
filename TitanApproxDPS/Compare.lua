local _,ns=...
-- Rough comparison of a weapon against the equipped one in the same slot. This is
-- deliberately simple: it compares weapon DPS and stats, and applies the weapon DPS
-- change only to the observed share of damage that came from auto-attacks. It is not
-- a measured result and ignores abilities and stat scaling.
local C={};ns.Compare=C
local DPS_KEYS={'ITEM_MOD_DAMAGE_PER_SECOND_SHORT','ITEM_MOD_DAMAGE_PER_SECOND'}
local slots={INVTYPE_2HWEAPON=16,INVTYPE_WEAPON=16,INVTYPE_WEAPONMAINHAND=16,INVTYPE_WEAPONOFFHAND=17,INVTYPE_RANGED=18,INVTYPE_RANGEDRIGHT=18,INVTYPE_THROWN=18}
function C.SlotFor(equipLoc)return equipLoc and slots[equipLoc]or nil end
function C.ItemStats(link,api)
 api=api or _G
 local fn=(api.C_Item and api.C_Item.GetItemStats) or api.GetItemStats
 if type(fn)~='function' then return nil end
 local ok,stats=pcall(fn,link)
 if ok and type(stats)=='table' and ns.Capabilities.IsPublic(stats,api) then return stats end
end
local function dps(stats)
 for _,key in ipairs(DPS_KEYS)do if ns.Number(stats[key]) then return stats[key],key end end
end
C.WeaponDps=function(stats)return (dps(stats))end
local fallback={ITEM_MOD_STRENGTH_SHORT='Strength',ITEM_MOD_AGILITY_SHORT='Agility',ITEM_MOD_STAMINA_SHORT='Stamina',ITEM_MOD_INTELLECT_SHORT='Intellect',ITEM_MOD_SPIRIT_SHORT='Spirit',ITEM_MOD_ATTACK_POWER_SHORT='Attack Power',ITEM_MOD_SPELL_POWER_SHORT='Spell Power'}
function C.Label(key,api)
 api=api or _G
 local text=api[key]
 if type(text)=='string' and text~='' then return text end
 if fallback[key] then return fallback[key]end
 local readable=key:gsub('^ITEM_MOD_',''):gsub('_SHORT$',''):gsub('_',' ')
 return readable:lower()
end
-- group: Reports group of the equipped weapon (damage, autoDamage, stats.period) or nil.
function C.Compare(newStats,oldStats,group)
 if type(newStats)~='table' or type(oldStats)~='table' then return nil end
 local newDps=dps(newStats);local oldDps,dpsKey=dps(oldStats)
 local result={weaponDps={new=newDps,old=oldDps},stats={}}
 if newDps and oldDps and oldDps>0 then result.weaponDps.percent=100*(newDps/oldDps-1)end
 local keys={};for key in pairs(newStats)do keys[key]=true end;for key in pairs(oldStats)do keys[key]=true end
 local ordered={};for key in pairs(keys)do if key:find('^ITEM_MOD_') and not key:find('DAMAGE_PER_SECOND') then ordered[#ordered+1]=key end end
 table.sort(ordered)
 for _,key in ipairs(ordered)do
  local delta=(ns.Number(newStats[key]) and newStats[key] or 0)-(ns.Number(oldStats[key]) and oldStats[key] or 0)
  if delta~=0 then result.stats[#result.stats+1]={key=key,delta=delta}end
 end
 local period=group and group.stats and group.stats.period
 if result.weaponDps.percent and group and group.damage and group.damage>0 and period and period.n>0 and period.typical then
  local share=(group.autoDamage or 0)/group.damage
  local fraction=share*result.weaponDps.percent/100
  result.rough={autoShare=share,percent=100*fraction,typical=period.typical*(1+fraction),fights=period.n,confidence=period.confidence}
 end
 return result
end

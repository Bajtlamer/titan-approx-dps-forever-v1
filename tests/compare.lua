local ns={}
for _,f in ipairs({'Namespace','Capabilities','Compare'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local C=ns.Compare
local function near(a,b)return math.abs(a-b)<1e-6 end
-- equip locations map to the compared slot
assert(C.SlotFor('INVTYPE_2HWEAPON')==16 and C.SlotFor('INVTYPE_WEAPON')==16 and C.SlotFor('INVTYPE_WEAPONMAINHAND')==16)
assert(C.SlotFor('INVTYPE_WEAPONOFFHAND')==17 and C.SlotFor('INVTYPE_RANGED')==18 and C.SlotFor('INVTYPE_RANGEDRIGHT')==18 and C.SlotFor('INVTYPE_THROWN')==18)
assert(C.SlotFor('INVTYPE_HEAD')==nil and C.SlotFor(nil)==nil and C.SlotFor('INVTYPE_SHIELD')==nil)

local DPS='ITEM_MOD_DAMAGE_PER_SECOND_SHORT'
local new={[DPS]=20,ITEM_MOD_AGILITY_SHORT=10,ITEM_MOD_STAMINA_SHORT=5}
local old={[DPS]=16,ITEM_MOD_AGILITY_SHORT=4,ITEM_MOD_STRENGTH_SHORT=3}
local group={damage=1000,autoDamage=600,stats={period={n=12,typical=40,confidence='medium'}}}
local r=C.Compare(new,old,group)
assert(near(r.weaponDps.new,20) and near(r.weaponDps.old,16) and near(r.weaponDps.percent,25),'weapon dps')
-- stat deltas, zero changes omitted, sorted by key
local seen={};for _,d in ipairs(r.stats)do seen[d.key]=d.delta end
assert(seen.ITEM_MOD_AGILITY_SHORT==6 and seen.ITEM_MOD_STAMINA_SHORT==5 and seen.ITEM_MOD_STRENGTH_SHORT==-3 and seen[DPS]==nil,'stat deltas')
-- rough estimate: only the auto-attack share of observed damage follows weapon DPS
assert(near(r.rough.autoShare,0.6) and near(r.rough.percent,15) and near(r.rough.typical,46) and r.rough.fights==12,'rough estimate')
-- without personal data there is no rough estimate, but stats still compare
local r2=C.Compare(new,old,nil);assert(r2.rough==nil and r2.weaponDps.percent==25)
assert(C.Compare(new,old,{damage=0,autoDamage=0}).rough==nil)
assert(C.Compare(new,old,{damage=1000,autoDamage=600}).rough==nil,'needs statistics')
-- equipped item with no known DPS cannot give a percentage
local r3=C.Compare(new,{},group);assert(r3.weaponDps.percent==nil and r3.rough==nil)
-- nothing readable at all
assert(C.Compare(nil,old,group)==nil and C.Compare(new,nil,group)==nil)
-- item stats reading is guarded
local api={C_Item={GetItemStats=function(link)return {ITEM_MOD_AGILITY_SHORT=3}end}}
assert(C.ItemStats('item:1',api).ITEM_MOD_AGILITY_SHORT==3)
assert(C.ItemStats('item:1',{})==nil)
assert(C.ItemStats('item:1',{C_Item={GetItemStats=function()error('x')end}})==nil)
-- labels never show raw keys when no localized string exists
assert(C.Label('ITEM_MOD_AGILITY_SHORT',{})=='Agility' and C.Label('ITEM_MOD_AGILITY_SHORT',{ITEM_MOD_AGILITY_SHORT='Hbitnost'})=='Hbitnost')
print('PASS weapon comparison: slot mapping, DPS and stat deltas, rough auto-attack estimate, guarded item APIs')

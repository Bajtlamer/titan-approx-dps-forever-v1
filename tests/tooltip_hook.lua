local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Compare','ItemEffects','TooltipHook'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local EQUIPPED='|cff1eff00|Hitem:20:0|h[Old Bow]|h|r'
local HOVER='|cff0070dd|Hitem:99:0|h[New Bow]|h|r'
local stats={['item:20:0']={ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10,ITEM_MOD_AGILITY_SHORT=2},['|cff0070dd|Hitem:99:0|h[New Bow]|h|r']={ITEM_MOD_DAMAGE_PER_SECOND_SHORT=15,ITEM_MOD_AGILITY_SHORT=5,ITEM_MOD_STAMINA_SHORT=3}}
local combat=false
local api={
 InCombatLockdown=function()return combat end,
 GetInventoryItemLink=function(_,slot)return slot==18 and EQUIPPED or nil end,
 C_Item={
  GetItemInfoInstant=function(v)local id=type(v)=='number' and v or tonumber(tostring(v):match('item:(%d+)'));return id,nil,nil,'INVTYPE_RANGEDRIGHT',nil,2,2 end,
  GetItemStats=function(link)return link==EQUIPPED and stats['item:20:0'] or stats[link] end,
 },
}
setmetatable(api,{__index=_G})
local db=ns.Storage.Open({},'p');db:Character().class='HUNTER'
-- no fights yet: stats compare, no rough estimate
local function render(link)
 local lines={};local tip={}
 function tip:AddLine(t)lines[#lines+1]=t end
 function tip:AddDoubleLine(a,b)lines[#lines+1]=a..' | '..b end
 local shown=ns.TooltipHook.Render(tip,link,api,db)
 local text=table.concat(lines,'\n'):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
 return shown,text
end
local shown,text=render(HOVER)
assert(shown and text:find('+50.0%',1,true) and text:find('15.0 / 10.0',1,true),'weapon DPS comparison missing: '..text)
assert(text:find('No fight data',1,true),'missing-data hint')
assert(text:find('+3',1,true) and text:find('Agility',1,true) and text:find('Stamina',1,true),'stat deltas')
-- with fights: rough estimate from the auto-attack share
for i=1,4 do db:UpsertContribution({receiptID='f'..i,profile='16:empty;17:empty;18:20:0',mode='pve',damage=1000,seconds=10,spells={{spellID=75,origin='player',damage={value=800}},{spellID=3044,origin='player',damage={value=200}}}})end
shown,text=render(HOVER)
assert(text:find('Rough effect',1,true),'rough estimate missing: '..text)
assert(text:find('+40.0%',1,true),'80 percent share of +50 percent DPS is +40: '..text)
assert(not text:find('No fight data',1,true))
-- the equipped weapon itself and non-weapons get nothing
assert(not render(EQUIPPED),'equipped item must not be compared with itself')
-- Random-bonus axes share a base ID but still need their own comparisons/history.
local oldEquipped=EQUIPPED
api.GetInventoryItemLink=function(_,slot)return slot==16 and EQUIPPED or nil end
api.C_Item.GetItemInfoInstant=function()return 4568,nil,nil,'INVTYPE_WEAPON',nil,2,0 end
EQUIPPED='|cnIQ2:|Hitem:4568::::::::17:1485::1:1:12759:1:28:5240:::::|h[Grunt Axe of Holy Wrath]|h|r'
local gorilla='|cnIQ2:|Hitem:4568::::::::18:1485::1:1:12760:1:28:5240:::::|h[Grunt Axe of the Gorilla]|h|r'
local sameVariant='|cnIQ2:|Hitem:4568:::::::123:18:1485::1:1:12759:1:28:5240:::::|h[Grunt Axe of Holy Wrath]|h|r'
stats[gorilla]={ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10,ITEM_MOD_STRENGTH_SHORT=3,ITEM_MOD_INTELLECT_SHORT=3}
shown,text=render(gorilla)
assert(shown and text:find('Strength',1,true) and text:find('+3',1,true),'same-base bonus variant comparison missing: '..text)
assert(not render(sameVariant),'incidental unique ID and level differences must not compare identical variants')
local build=ns.Reports.Build
local right={slot=16,profile='slot:16:4568:0:bonus=12759',damage=100}
local wrong={slot=16,profile='slot:16:4568:0:bonus=12760',damage=1000}
ns.Reports.Build=function()return {groups={wrong,right}}end
local result,group=ns.TooltipHook.Evaluate(gorilla,api,db)
assert(result and group==right,'comparison used fight history from a different bonus variant')
-- Classic suffix fields must also distinguish variants.
local suffix='|cff1eff00|Hitem:4568:0:0:0:0:0:-69:123|h[Grunt Axe of the Gorilla]|h|r'
stats[suffix]=stats[gorilla]
EQUIPPED='|cff1eff00|Hitem:4568:0:0:0:0:0:-19:456|h[Grunt Axe of Holy Wrath]|h|r'
assert(render(suffix),'same-base suffix variant comparison missing')
ns.Reports.Build=build
EQUIPPED=oldEquipped
api.GetInventoryItemLink=function(_,slot)return slot==18 and EQUIPPED or nil end
api.C_Item.GetItemInfoInstant=function()return 5,nil,nil,'INVTYPE_HEAD',nil,4,1 end
shown,text=render(HOVER)
assert(shown and text:find('empty slot',1,true) and not text:find('Weapon DPS',1,true),'armor goes through the gear comparison, not the weapon one: '..text)
-- never during combat, never raising errors
api.C_Item.GetItemInfoInstant=function(v)return 99,nil,nil,'INVTYPE_RANGEDRIGHT',nil,2,2 end
combat=true;assert(not render(HOVER),'combat');combat=false
api.C_Item.GetItemStats=function()error('boom')end
assert(not render(HOVER),'unreadable stats')
-- attaches through the tooltip data processor only when it exists
local registered
local fake={TooltipDataProcessor={AddTooltipPostCall=function(kind,fn)registered={kind=kind,fn=fn}end},Enum={TooltipDataType={Item=3}},GameTooltip={},ItemRefTooltip={}}
assert(ns.TooltipHook.Attach(fake) and registered and registered.kind==3)
assert(ns.TooltipHook.Attach({})==false)
print('PASS item tooltip comparison: DPS delta, stats, rough estimate, guards, optional attachment')

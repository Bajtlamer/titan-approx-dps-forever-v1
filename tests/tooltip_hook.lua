local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Compare','TooltipHook'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
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
api.C_Item.GetItemInfoInstant=function()return 5,nil,nil,'INVTYPE_HEAD',nil,4,1 end
assert(not render(HOVER),'armor must not be compared')
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

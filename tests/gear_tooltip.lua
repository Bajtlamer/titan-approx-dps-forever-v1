local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Compare','ItemEffects','Estimator','TooltipHook'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local DPS='ITEM_MOD_DAMAGE_PER_SECOND_SHORT'
local combat=false
local equipped={} -- slot -> link
local stats={}
local equipLoc,classID='INVTYPE_FEET',4
local api={
 InCombatLockdown=function()return combat end,
 GetInventoryItemLink=function(_,slot)return equipped[slot]end,
 UnitLevel=function()return 60 end,
 UnitStat=function(_,i)return 0,(i==3 and 100 or 100)end,
 C_Item={GetItemInfoInstant=function()return 1,nil,nil,equipLoc,nil,classID,1 end,GetItemStats=function(link)return stats[link]end},
}
setmetatable(api,{__index=_G})
local function link(id)return '|cff1eff00|Hitem:'..id..':0|h[Item '..id..']|h|r' end
local function render(l,db)
 local lines={};local tip={}
 function tip:AddLine(t)lines[#lines+1]=t end
 function tip:AddDoubleLine(a,b)lines[#lines+1]=a..' | '..b end
 local shown=ns.TooltipHook.Render(tip,l,api,db)
 return shown,(table.concat(lines,'\n'):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''))
end
local n=0
local function has(text,needle)n=n+1;assert(text:find(needle,1,true),'missing "'..needle..'" in:\n'..text)end
local function lacks(text,needle)n=n+1;assert(not text:find(needle,1,true),'unexpected "'..needle..'" in:\n'..text)end

-- Hunter boots: +2 Agility over the worn pair gives attack power and crit, no spell damage.
local db=ns.Storage.Open({},'p');db:Character().class='HUNTER'
local boots,old=link(10),link(11)
equipped[8]=old
stats[boots]={ITEM_MOD_AGILITY_SHORT=7};stats[old]={ITEM_MOD_AGILITY_SHORT=5}
local shown,text=render(boots,db)
assert(shown);n=n+1
has(text,'Feet');has(text,'vs equipped');has(text,'Agility');has(text,'+2')
has(text,'Melee attack power');has(text,'Ranged attack power');has(text,'+4');has(text,'Physical crit chance')
lacks(text,'Spell power')
has(text,'No fight data for the equipped melee weapon')

-- Stamina gloves: health only, damage unchanged.
equipLoc='INVTYPE_HAND';equipped[10]=nil
local gloves=link(12);stats[gloves]={ITEM_MOD_STAMINA_SHORT=6}
shown,text=render(gloves,db)
assert(shown);n=n+1
has(text,'empty slot');has(text,'Max health (base)');has(text,'+60');has(text,'no change from these stats')
lacks(text,'attack power');lacks(text,'Estimated change')

-- Caster: Intellect gives mana and spell crit, never damage; Spirit is not modelled.
db:Character().class='MAGE'
local hat=link(13);equipLoc='INVTYPE_HEAD';stats[hat]={ITEM_MOD_INTELLECT_SHORT=6,ITEM_MOD_SPIRIT_SHORT=3}
shown,text=render(hat,db)
assert(shown);n=n+1
has(text,'Max mana (base)');has(text,'+90');has(text,'Spell crit chance');has(text,'not spell damage');has(text,'Effect not modelled: Spirit')
lacks(text,'Spell power |')

-- Rings are compared with both worn rings, each block labelled with its slot.
db:Character().class='WARRIOR'
equipLoc='INVTYPE_FINGER';equipped[11]=link(20);equipped[12]=link(21)
stats[equipped[11]]={ITEM_MOD_STRENGTH_SHORT=1};stats[equipped[12]]={ITEM_MOD_STRENGTH_SHORT=4}
local ring=link(22);stats[ring]={ITEM_MOD_STRENGTH_SHORT=3}
shown,text=render(ring,db)
assert(shown);n=n+1
has(text,'Ring 1');has(text,'Ring 2');has(text,'+4');has(text,'-2')
-- the same ring is skipped for the slot where it is already worn
equipped[11]=ring
shown,text=render(ring,db)
assert(shown);n=n+1
lacks(text,'Ring 1');has(text,'Ring 2')
equipped[12]=ring
n=n+1;assert(not render(ring,db),'item worn in every slot gets no comparison')

-- With enough fights the attack power change becomes a calibrated damage estimate.
db:Character().class='WARRIOR'
equipLoc='INVTYPE_CLOAK';equipped[15]=nil
local cloak=link(30);stats[cloak]={ITEM_MOD_STRENGTH_SHORT=7}
local weaponLink=link(40);equipped[16]=weaponLink;stats[weaponLink]={[DPS]=10}
local samples={}
for i=1,30 do local ap=100+i*10;local auto=0.8*(10+ap/14);samples[#samples+1]={dps=auto+5,autoDps=auto,seconds=20,build={attackPower=ap}}end
local realBuild,realSamples=ns.Reports.Build,ns.Stats.FightSamples
ns.Reports.Build=function()return {groups={{slot=16,kind='melee',profile='slot:16:40:0',damage=100}}}end
ns.Stats.FightSamples=function()return samples end
api.C_Item.GetItemInfoInstant=function(v)return 1,nil,nil,equipLoc,nil,classID,1 end
local origItemInstant=api.C_Item.GetItemInfoInstant
shown,text=render(cloak,db)
assert(shown);n=n+1
has(text,'Melee attack power');has(text,'+14');has(text,'Estimated change, your melee auto-attacks');has(text,'Calibrated on 30 fights')
-- weapons keep their own comparison and gain the derived rows
ns.Reports.Build,ns.Stats.FightSamples=realBuild,realSamples

-- Never in combat, never on errors, never for non-armor.
combat=true;n=n+1;assert(not render(cloak,db),'combat');combat=false
classID=2;n=n+1;assert(not render(cloak,db),'weapon class is not gear');classID=4
equipLoc='INVTYPE_BODY';n=n+1;assert(not render(cloak,db),'shirt is not compared');equipLoc='INVTYPE_CLOAK'
api.C_Item.GetItemStats=function()error('boom')end
n=n+1;assert(not render(cloak,db),'unreadable stats')
print('PASS '..n..' gear tooltip assertions')

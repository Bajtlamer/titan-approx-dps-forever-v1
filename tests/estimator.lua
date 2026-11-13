local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Json','BuildSnapshot','Transfer','Compare','Estimator','TooltipHook'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local E=ns.Estimator
local function near(a,b,eps)return math.abs(a-b)<(eps or 1e-6)end
local DPS='ITEM_MOD_DAMAGE_PER_SECOND_SHORT'

-- synthetic melee data: autoDps = k * (weaponDps + AP/14) with k = 0.8, weapon DPS 10
local function meleeSamples(n,withBuild)
 local out={}
 for i=1,n do
  local ap=100+i*10
  local auto=0.8*(10+ap/14)
  out[#out+1]={dps=auto+5,autoDps=auto,seconds=20,build=withBuild~=false and {attackPower=ap,rangedAttackPower=999} or nil}
 end
 return out
end
local old={[DPS]=10}
local upgrade={[DPS]=15}

local r=assert(E.AutoAttack(meleeSamples(30),'melee','WARRIOR',upgrade,old))
assert(near(r.k,0.8) and r.fights==30,'calibration recovers k')
assert(near(r.deltaDps,4.0),'delta DPS is k times the weapon DPS difference, got '..r.deltaDps)
local mean=0;for _,s in ipairs(meleeSamples(30))do mean=mean+s.dps end;mean=mean/30
assert(near(r.groupTypical,mean) and near(r.percent,100*4/mean),'percent of the group DPS')
assert(r.confidence=='high','30 consistent fights give high confidence')
-- direction
assert(E.AutoAttack(meleeSamples(30),'melee','WARRIOR',old,old).percent==0,'equal items give zero')
assert(E.AutoAttack(meleeSamples(30),'melee','WARRIOR',{[DPS]=7},old).percent<0,'downgrade is negative')
-- not enough fights, or fights without a build, are not used
local none,why=E.AutoAttack(meleeSamples(19),'melee','WARRIOR',upgrade,old);assert(none==nil and why:find('20',1,true),'needs 20 fights: '..tostring(why))
none,why=E.AutoAttack(meleeSamples(40,false),'melee','WARRIOR',upgrade,old);assert(none==nil and why:find('0 of',1,true) or why:find('build',1,true),'fights without build do not count: '..tostring(why))
local mixed=meleeSamples(15);for _,s in ipairs(meleeSamples(15,false))do mixed[#mixed+1]=s end
assert(E.AutoAttack(mixed,'melee','WARRIOR',upgrade,old)==nil,'only fights with a build count')
-- missing weapon DPS on either item
none,why=E.AutoAttack(meleeSamples(30),'melee','WARRIOR',{},old);assert(none==nil and why:find('weapon DPS',1,true))
none,why=E.AutoAttack(meleeSamples(30),'melee','WARRIOR',upgrade,{});assert(none==nil and why:find('weapon DPS',1,true))
-- attack power on the item and strength convert to extra damage
r=E.AutoAttack(meleeSamples(30),'melee','WARRIOR',{[DPS]=10,ITEM_MOD_ATTACK_POWER_SHORT=14},old);assert(near(r.deltaDps,0.8),'14 attack power is one weapon DPS')
r=E.AutoAttack(meleeSamples(30),'melee','WARRIOR',{[DPS]=10,ITEM_MOD_STRENGTH_SHORT=7},old);assert(near(r.deltaDps,0.8),'7 strength is 14 attack power for a warrior')
r=E.AutoAttack(meleeSamples(30),'melee','MAGE',{[DPS]=10,ITEM_MOD_STRENGTH_SHORT=7},old);assert(near(r.deltaDps,0),'no conversion known for a class without one')
-- ranged uses ranged attack power, never melee attack power
local ranged={}
for i=1,30 do local rap=200+i*5;local auto=0.9*(12+rap/14);ranged[#ranged+1]={dps=auto,autoDps=auto,seconds=20,build={attackPower=1,rangedAttackPower=rap}}end
r=assert(E.AutoAttack(ranged,'ranged','HUNTER',{[DPS]=16},{[DPS]=12}));assert(near(r.k,0.9) and near(r.deltaDps,0.9*4),'ranged calibration')
r=E.AutoAttack(ranged,'ranged','HUNTER',{[DPS]=12,ITEM_MOD_RANGED_ATTACK_POWER_SHORT=14,ITEM_MOD_ATTACK_POWER_SHORT=70},{[DPS]=12});assert(near(r.deltaDps,0.9),'only ranged attack power counts for ranged')
r=E.AutoAttack(ranged,'ranged','HUNTER',{[DPS]=12,ITEM_MOD_AGILITY_SHORT=7},{[DPS]=12});assert(near(r.deltaDps,0.9),'7 agility is 14 ranged attack power for a hunter')
-- noisy fights lower the confidence
local noisy={};for i=1,30 do local auto=(i%2==0 and 2 or 22);noisy[#noisy+1]={dps=auto,autoDps=auto,seconds=20,build={attackPower=100}}end
assert(E.AutoAttack(noisy,'melee','WARRIOR',upgrade,old).confidence=='medium','noisy fights are never high')
-- never invents numbers from empty or degenerate data
assert(E.AutoAttack({},'melee','WARRIOR',upgrade,old)==nil)
assert(E.AutoAttack({{dps=0,autoDps=0,seconds=20,build={attackPower=100}}},'melee','WARRIOR',upgrade,old)==nil)

-- spells: least squares of group DPS on spell power
local function spellSamples(n,slope,intercept,spread,noise)
 local out={}
 for i=1,n do local sp=100+(i-1)*(spread or 10);out[#out+1]={dps=intercept+slope*sp+(noise and noise(i) or 0),seconds=20,build={spellPower=sp}}end
 return out
end
local s=assert(E.Spell(spellSamples(30,0.5,2),{ITEM_MOD_SPELL_POWER_SHORT=40},{ITEM_MOD_SPELL_POWER_SHORT=20}))
assert(near(s.slope,0.5) and near(s.deltaDps,10) and s.fights==30 and near(s.r2,1),'slope and delta recovered')
local meanDps=0;for _,x in ipairs(spellSamples(30,0.5,2))do meanDps=meanDps+x.dps end;meanDps=meanDps/30
assert(near(s.percent,100*10/meanDps),'percent of the spell group DPS')
assert(s.confidence=='high')
-- classic key name for spell damage works too
assert(E.Spell(spellSamples(30,0.5,2),{ITEM_MOD_SPELL_DAMAGE_DONE_SHORT=30},{})~=nil)
-- unavailable cases give a reason
local x;x,why=E.Spell(spellSamples(19,0.5,2),{ITEM_MOD_SPELL_POWER_SHORT=40},{});assert(x==nil and why:find('20',1,true))
x,why=E.Spell(spellSamples(30,0.5,2),{ITEM_MOD_SPELL_POWER_SHORT=40},{ITEM_MOD_SPELL_POWER_SHORT=40});assert(x==nil and why:find('no spell power',1,true),why)
x,why=E.Spell(spellSamples(30,0.5,2,0),{ITEM_MOD_SPELL_POWER_SHORT=40},{});assert(x==nil and why:find('barely',1,true),'constant spell power cannot be calibrated: '..tostring(why))
x,why=E.Spell(spellSamples(30,-0.5,500),{ITEM_MOD_SPELL_POWER_SHORT=40},{});assert(x==nil and why:find('positive',1,true),'a negative relation is not trusted: '..tostring(why))
-- weak fit gives low confidence
local jitter=function(i)return ((i*37)%11-5)*30 end
local weak=assert(E.Spell(spellSamples(30,0.5,100,10,jitter),{ITEM_MOD_SPELL_POWER_SHORT=40},{}));assert(weak.confidence=='low' and weak.r2<0.5,'weak fit is low confidence, r2='..weak.r2)

-- integration: stored fights with build snapshots, the real tooltip text
C_Spell={IsRangedAutoAttackSpell=function()return false end,GetSpellName=function(id)return 'Spell '..id end}
local PROFILE='16:30:0;17:empty;18:empty'
local db=ns.Storage.Open({},'p');ns.store=db;local c=db:Character();c.class='HUNTER'
c.profiles[PROFILE]='|cff1eff00|Hitem:30:0|h[Old Axe]|h|r'
for i=1,25 do
 local ap=100+i*10;local seconds=20
 -- integer damage like the real meter: float sums of the spell parts must equal the total
 local autoDamage=math.floor(0.8*(10+ap/14)*seconds+.5)
 db:UpsertContribution({receiptID='f'..i,profile=PROFILE,mode='pve',damage=autoDamage+100,seconds=seconds,context={targetName='Boar'},
  build={attackPower=ap,source='combat start',bucket='x'},
  spells={{spellID=6603,origin='player',damage={value=autoDamage}},{spellID=2973,origin='player',damage={value=100}}}})
end
local key='slot:16:30:0'
local fights=ns.Stats.FightSamples(c,key)
assert(#fights==25 and fights[1].build.attackPower==110 and near(fights[1].autoDps,0.8*(10+110/14),0.05),'fight samples carry auto DPS and build')
local EQUIPPED='|cff1eff00|Hitem:30:0|h[Old Axe]|h|r';local HOVER='|cff0070dd|Hitem:99:0|h[New Axe]|h|r'
local stats={[EQUIPPED]={[DPS]=10},[HOVER]={[DPS]=15}}
local api={InCombatLockdown=function()return false end,GetInventoryItemLink=function(_,slot)return slot==16 and EQUIPPED or nil end,
 C_Item={GetItemInfoInstant=function(v)local id=type(v)=='number' and v or tonumber(tostring(v):match('item:(%d+)'));return id,nil,nil,'INVTYPE_WEAPONMAINHAND',nil,2,1 end,GetItemStats=function(link)return stats[link]end}}
setmetatable(api,{__index=_G})
local function render(link)
 local lines={};local tip={}
 function tip:AddLine(t)lines[#lines+1]=t end
 function tip:AddDoubleLine(a,b)lines[#lines+1]=a..' | '..b end
 local shown=ns.TooltipHook.Render(tip,link,api,db)
 return shown,(table.concat(lines,'\n'):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''))
end
local shown,text=render(HOVER)
local typical=0;for _,f in ipairs(fights)do typical=typical+f.dps end;typical=typical/#fights
local kSum=0;for _,f in ipairs(fights)do kSum=kSum+f.autoDps/(10+f.build.attackPower/14)end
local expected=string.format('%+.1f%%',100*(kSum/#fights)*5/typical)
assert(shown and text:find('Estimated change',1,true) and text:find(expected,1,true),'calibrated estimate '..expected..' missing: '..text)
assert(text:find('Calibrated on 25 fights',1,true),'fight count and calibration are shown')
assert(not text:find('Rough effect',1,true),'the calibrated estimate replaces the rough one')
-- the same item, fewer fights: falls back to the rough comparison with the reason
for i=1,10 do c.receipts['f'..i].build=nil end
shown,text=render(HOVER)
assert(text:find('Rough effect',1,true) and text:find('needs 20',1,true) or text:find('20 fights',1,true),'fallback explains the 20 fight minimum: '..text)
assert(not text:find('Estimated change',1,true))
print('PASS estimator: calibrated auto-attack and spell estimates, guards, confidence, tooltip integration')

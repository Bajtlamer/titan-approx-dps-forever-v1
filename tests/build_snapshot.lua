local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Json','Transfer','BuildSnapshot','Meter','Sessions'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local B=ns.BuildSnapshot
local function near(a,b)return math.abs(a-b)<1e-9 end

local function fullApi()
 return {
  UnitLevel=function()return 20 end,
  UnitStat=function(_,i)local base={10,20,30,40,50};return base[i],base[i]+5,0,0 end,
  UnitAttackPower=function()return 100,20,-10 end,
  UnitRangedAttackPower=function()return 200,5,0 end,
  GetSpellBonusDamage=function(school)return school==4 and 80 or 10 end,
  GetCritChance=function()return 5.26 end,
  GetRangedCritChance=function()return 6.04 end,
  GetSpellCritChance=function(school)return school==4 and 3.17 or 1 end,
  UnitAttackSpeed=function()return 2.6,1.4 end,
  UnitRangedDamage=function()return 2.8 end,
 }
end

-- a full snapshot, rounded to a sensible precision
local s=B.Take(fullApi(),'combat start')
assert(s.level==20 and s.source=='combat start')
assert(s.strength==15 and s.agility==25 and s.stamina==35 and s.intellect==45 and s.spirit==55,'effective primary stats')
assert(s.attackPower==110 and s.rangedAttackPower==205,'attack power is base plus buffs')
assert(s.spellPower==80,'highest school spell power')
assert(near(s.meleeCrit,5.3) and near(s.rangedCrit,6.0) and near(s.spellCrit,3.2),'crit rounded to one decimal')
assert(near(s.mainHandSpeed,2.6) and near(s.offHandSpeed,1.4) and near(s.rangedSpeed,2.8),'speeds')
assert(s.bucket=='ap200-sp50','build bucket from attack power and spell power bands, got '..tostring(s.bucket))
assert(B.Validate(s))

-- unreadable values are missing, never zero
local partial=fullApi()
partial.UnitStat=function()error('restricted')end
partial.UnitAttackPower=function()return nil end
partial.GetCritChance=function()return 0/0 end
partial.GetRangedCritChance=function()return -1 end
partial.issecretvalue=function(v)return v==80 end -- spell power is a secret value
partial.UnitAttackSpeed=function()return 'x' end
local p=B.Take(partial,'combat start')
assert(p.strength==nil and p.agility==nil and p.attackPower==nil and p.meleeCrit==nil and p.rangedCrit==nil and p.mainHandSpeed==nil,'unreadable fields are absent')
assert(p.spellPower==10,'secret school value skipped, next readable school used')
assert(p.level==20 and p.rangedAttackPower==205,'readable fields survive')
-- a genuinely readable zero is a real value
local zero=fullApi();zero.GetSpellBonusDamage=function()return 0 end
assert(B.Take(zero,'combat start').spellPower==0)
-- nothing readable at all: no snapshot
assert(B.Take({},'combat start')==nil)
assert(B.Take({UnitLevel=function()error('x')end},'combat start')==nil)
-- bucket without power values
assert(B.Bucket({level=5})=='unknown')
assert(B.Bucket({attackPower=99})=='ap0-sp0' and B.Bucket({attackPower=100})=='ap100-sp0' and B.Bucket({spellPower=49})=='ap0-sp0' and B.Bucket({spellPower=50})=='ap0-sp50')

-- validation
assert(B.Validate({level=1}) and not B.Validate({level=-1}) and not B.Validate({strength='x'}) and not B.Validate({unknownKey=1}) and not B.Validate('bad') and not B.Validate({source=5}))

-- capture: once per combat, stored on every receipt of that combat
local combat=false;local power=100
local api=fullApi()
local realAttack=api.UnitAttackPower
api.UnitAttackPower=function()if combat and api.restrictInCombat then return nil end;return power,0,0 end
api.UnitName=function()return 'Boar'end;api.UnitIsPlayer=function()return false end;api.IsInGroup=function()return false end
api.Enum={DamageMeterType={DamageDone=0}}
local reads=0
local meter={api=api,capabilities={damage=true},ReadSession=function()return {totalDamage={value=10},duration={value=20},nativeDPS={value=5},spells={},combatMode='unknown'}end}
local db=ns.Storage.Open({},'p')
local rec=ns.Sessions.New(db,meter,{Snapshot=function()return {id='weapon',complete=true}end},function()return 0 end)
local countingStat=api.UnitStat;api.UnitStat=function(...)reads=reads+1;return countingStat(...)end
combat=true;rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,2)
assert(reads==5,'stats read once per combat start, not per session update, got '..reads)
combat=false;rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(0);rec:Tick(1)
local c=db:Character()
local first=c.receipts[c.history[1]];local second=c.receipts[c.history[2]]
assert(first.build and first.build.attackPower==100 and first.build.source=='combat start' and second.build.attackPower==100,'both sessions of the combat carry the build')
assert(first.build.bucket=='ap200-sp50')
-- a later fight with different gear records its own build
power=300;combat=true;rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,3);combat=false;rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(2);rec:Tick(3)
assert(c.receipts[c.history[3]].build.attackPower==300 and first.build.attackPower==100,'builds are per fight')
-- when combat start reads nothing, the last out-of-combat reading is used and labelled
api.restrictInCombat=true
api.UnitLevel=function()if combat then return nil end;return 20 end
api.UnitStat=function(_,i)if combat then return nil end;return 7,7 end
api.UnitRangedAttackPower=function()if combat then return nil end;return 11,0,0 end
api.GetSpellBonusDamage=function()if combat then return nil end;return 4 end
api.GetCritChance=function()if combat then return nil end;return 2 end
api.GetRangedCritChance=function()if combat then return nil end;return 2 end
api.GetSpellCritChance=function()if combat then return nil end;return 2 end
api.UnitAttackSpeed=function()if combat then return nil end;return 2,2 end
api.UnitRangedDamage=function()if combat then return nil end;return 2 end
combat=false;rec:Handle('PLAYER_REGEN_ENABLED')
power=0;combat=true;rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,4);combat=false;rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(4);rec:Tick(5)
local fallback=c.receipts[c.history[4]];assert(fallback.build and fallback.build.source=='out of combat' and fallback.build.strength==7,'falls back to the out-of-combat reading')
-- no readings at all: receipt without a build, nothing invented
local blank=ns.Storage.Open({},'q');local rec2=ns.Sessions.New(blank,{api={Enum=api.Enum,UnitName=api.UnitName,UnitIsPlayer=api.UnitIsPlayer,IsInGroup=api.IsInGroup},capabilities={damage=true},ReadSession=meter.ReadSession},{Snapshot=function()return {id='w',complete=true}end},function()return 0 end)
rec2:Handle('PLAYER_REGEN_DISABLED');rec2:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);rec2:Handle('PLAYER_REGEN_ENABLED');rec2:Tick(0)
assert(blank:Character().receipts[blank:Character().history[1]].build==nil,'no build invented')

-- persistence and transfer
local saved=ns.Storage.Open({schema=1,characters={p=ns.Copy(c)}},'p');assert(not saved.readonly,'build survives a reload')
local snapshot=ns.Transfer.Export(db);local target=ns.Storage.Open({},'p')
local preview=assert(ns.Transfer.Stage(snapshot,target));assert(ns.Transfer.Apply(preview,target))
local imported=target:Character();assert(imported.receipts[imported.history[1]].build.attackPower==100,'build imported')
local doc=ns.Json.Decode(snapshot);local id=next(doc.data.receipts);doc.data.receipts[id].build={strength=-5}
assert(not ns.Transfer.Stage(ns.Json.Encode(doc),ns.Storage.Open({},'p')),'malformed imported build rejected')
local bad=ns.Copy(c);bad.receipts[bad.history[1]].build={attackPower='x'}
assert(ns.Storage.Open({schema=1,characters={p=bad}},'p').readonly,'malformed stored build rejected')

-- the combat log is never touched
for _,file in ipairs({'BuildSnapshot','Sessions','Core','Meter'})do
 local handle=assert(io.open('TitanApproxDPS/'..file..'.lua'));local text=handle:read('*a');handle:close()
 assert(not text:find('COMBAT_LOG',1,true),file..' references the combat log')
end
local handle=assert(io.open('TitanApproxDPS/BuildSnapshot.lua'));local source=handle:read('*a');handle:close()
assert(not source:find('RegisterEvent',1,true),'snapshot registers no events')
print('PASS build snapshot: readable fields only, once per combat, fallback, validation, transfer, no combat log')

local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Json','BuildSnapshot','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local PROFILE='16:empty;17:empty;18:20:0'
local KEY='slot:18:20:0'
local function newStore()
 local db=ns.Storage.Open({},'p');db:Character().class='HUNTER';return db
end
local function fight(db,id,damage,seconds,spell)
 db:UpsertContribution({receiptID=id,profile=PROFILE,mode='pve',damage=damage,seconds=seconds,at=100,spells={{spellID=spell or 75,origin='player',damage={value=damage}}}})
end
local function rec(db)return db:Character().records end

-- first fight sets every record
local db=newStore();fight(db,'a',100,10)
assert(rec(db).character.fightDamage.value==100 and rec(db).character.fightDPS.value==10,'character records')
local w=rec(db).weapons[KEY];assert(w,'weapon record missing');assert(w.fightDamage.value==100 and w.fightDPS.value==10 and w.fightDPS.seconds==10 and w.fightDamage.receiptID=='a','weapon records')
assert(w.spells[75].value==100,'spell record')

-- a weaker fight never lowers a record
fight(db,'b',50,10);w=rec(db).weapons[KEY];assert(w.fightDamage.value==100 and w.fightDPS.value==10 and w.spells[75].value==100,'lowered by weaker fight')
-- a stronger fight replaces it and carries its receipt
fight(db,'c',200,10);w=rec(db).weapons[KEY];assert(w.fightDamage.value==200 and w.fightDPS.value==20 and w.fightDamage.receiptID=='c' and w.spells[75].value==200,'not raised')
-- fights under 10 seconds can raise damage records but never DPS records
fight(db,'d',1000,5);w=rec(db).weapons[KEY];assert(w.fightDamage.value==1000 and w.fightDPS.value==20,'short fight DPS rule')
assert(rec(db).character.fightDPS.value==20,'character short fight DPS rule')
-- unknown duration never produces DPS
fight(db,'e',5000,nil);assert(rec(db).weapons[KEY].fightDPS.value==20 and rec(db).weapons[KEY].fightDamage.value==5000,'unknown duration')
-- a later native revision that corrects a fight downward keeps the higher record
fight(db,'e',10,10);assert(rec(db).weapons[KEY].fightDamage.value==5000,'revision lowered record')

-- report period reset, hiding and meter reset never touch records
local before=ns.Json.Encode(rec(db))
db:ResetReports(1);ns.Reports.SetHidden(db,KEY,true);db:Character().epoch=db:Character().epoch+1
assert(ns.Json.Encode(rec(db))==before,'reset or hide changed records')
assert(rec(db).weapons[KEY].fightDamage.value==5000)

-- the module exposes nothing that clears or lowers records
for name in pairs(ns.Records)do assert(not name:lower():find('reset') and not name:lower():find('clear') and not name:lower():find('delete') and not name:lower():find('lower'),'unsafe API '..name)end

-- backfill from retained receipts is idempotent and reproduces the records
local source=newStore();fight(source,'a',100,10);fight(source,'b',300,10);fight(source,'c',40,4)
local expected=ns.Json.Encode(rec(source))
local c=source:Character();c.records=nil;c.recordsBackfilled=nil
source:BackfillRecords();assert(ns.Json.Encode(rec(source))==expected,'backfill mismatch')
source:BackfillRecords();assert(ns.Json.Encode(rec(source))==expected,'backfill not idempotent')
assert(source:Character().recordsBackfilled==1)

-- merge is field-wise max
local merged=ns.Records.Merge({character={fightDamage={value=5}},weapons={}},{character={fightDamage={value=9},fightDPS={value=2}},weapons={}})
assert(merged.character.fightDamage.value==9 and merged.character.fightDPS.value==2,'merge max')
assert(ns.Records.Merge(nil,nil).character,'merge of nothing')

-- validation
assert(ns.Records.Validate(rec(db)))
assert(not ns.Records.Validate({character={fightDamage={value=-1}},weapons={}}),'negative')
assert(not ns.Records.Validate({character={fightDamage={value=0/0}},weapons={}}),'nan')
assert(not ns.Records.Validate({character={},weapons={x='bad'}}),'weapon type')
assert(not ns.Records.Validate('bad'),'type')
local damaged=ns.Storage.Open({schema=1,characters={p=(function()local d=newStore();fight(d,'a',1,1);local x=ns.Copy(d:Character());x.records={character={fightDamage={value=-5}},weapons={}};return x end)()}},'p')
assert(damaged.readonly,'malformed records must not be accepted silently')

-- transfer: export, import and merge
local high=newStore();fight(high,'big',500,10)
local low=newStore();for i=1,5 do fight(low,'s'..i,100,10)end
local snapshot=ns.Transfer.Export(low)
local preview=assert(ns.Transfer.Stage(snapshot,high));assert(ns.Transfer.Apply(preview,high))
assert(rec(high).weapons[KEY].fightDamage.value==500 and rec(high).character.fightDamage.value==500,'import lowered records')
assert(rec(high).weapons[KEY].spells[75].value==500,'spell record lost on import')

local low2=newStore();fight(low2,'x',100,10)
local high2=newStore();fight(high2,'y',700,10)
local p2=assert(ns.Transfer.Stage(ns.Transfer.Export(high2),low2));assert(ns.Transfer.Apply(p2,low2))
assert(rec(low2).weapons[KEY].fightDamage.value==700 and type(next(rec(low2).weapons[KEY].spells))=='number','import did not raise records or normalize spell keys')

-- imported records that are malformed are rejected
local doc=ns.Json.Decode(ns.Transfer.Export(high2));doc.data.records.character.fightDamage.value=-1
assert(not ns.Transfer.Stage(ns.Json.Encode(doc),low2),'malformed imported records accepted')

print('PASS protected records: max-only, short-fight DPS rule, reset/import safe, backfill, validation')

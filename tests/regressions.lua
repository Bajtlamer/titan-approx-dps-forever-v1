local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Meter','Equipment','Metrics','Sessions','Methods','Comparisons','Records','Json','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local db=ns.Storage.Open({},'p');local methods=ns.Methods.New(db)
local one=methods:Define('one','');local two=methods:Define('two','');assert(one.methodID~=two.methodID,'method IDs collide')
local j=ns.Json;local text=j.Encode({name='a\nb',n=42,items={1,2}});local v=assert(j.Decode(text));assert(v.name=='a\nb' and v.items[2]==2)
assert(not j.Decode('{"a":1,"a":2}'));assert(not j.Decode('{"x":1e999}'));assert(not j.Decode('return os.execute("bad")'))
local r={receiptID='a',profile='sword',mode='pve',damage=100,seconds=10,spells={{spellID=42,damage={value=100}}}}
db:UpsertContribution(r);r.spells={{spellID=43,damage={value=100}}};db:UpsertContribution(r);assert(db:Character().rows['sword/pve/'].spells[43],'equal-damage revision ignored')
local encoded=ns.Transfer.Export(db);local preview=assert(ns.Transfer.Stage(encoded,db));local before=db:Character().totalDamage
assert(ns.Transfer.Apply(preview,db));assert(db:Character().totalDamage==before);assert(ns.Transfer.Apply(assert(ns.Transfer.Stage(encoded,db)),db));assert(db:Character().totalDamage==before)
assert(not ns.Transfer.Stage('{"schema":99}',db));print('PASS regression and migration scenarios')
assert(not j.Decode('1.'));assert(not j.Decode('1.e2'));assert(not j.Decode('01'));assert(not j.Decode('1e+'))
local fake=ns.Meter.New({Enum={DamageMeterType={DamageDone=0}},C_DamageMeter={GetCombatSessionFromID=function()return {durationSeconds=10,combatSources={{isLocalPlayer=true,totalAmount=10,sourceGUID='p'}}}end,GetCombatSessionSourceFromID=function()error('Unavailable')end}}, {damage=true,spells=true})
assert(fake:ReadSession(3),'Optional spell read must not discard total')
print('PASS JSON grammar and optional source failure')
local exported=assert(ns.Json.Decode(ns.Transfer.Export(db)))
for _,row in pairs(exported.data.rows)do for _,s in pairs(row.spells)do s.origins={player={damage=999999,timedDamage=999999}} end end
-- Derived rows are rebuilt on import, so poisoning only those must not survive staging.
local candidate=assert(ns.Transfer.Stage(ns.Json.Encode(exported),db));for _,row in pairs(candidate.data.rows)do for _,s in pairs(row.spells)do assert(not s.origins or not s.origins.player or s.origins.player.damage~=999999)end end
print('PASS derived attribution cannot be injected through exported row cache')
local corrupt=assert(ns.Json.Decode(ns.Transfer.Export(db)));corrupt.data.baseRows={base={profile='p',mode='pve',damage=10,seconds=5,timedDamage=10,sessions=1,spells={['75']={damage=10,timedDamage=10,origins={player={damage=100,timedDamage=100}}}}}};corrupt.data.baseDamage=10;corrupt.data.baseSeconds=5;corrupt.data.totalDamage=corrupt.data.totalDamage+10;corrupt.data.totalSeconds=corrupt.data.totalSeconds+5
assert(not ns.Transfer.Stage(ns.Json.Encode(corrupt),db),'inconsistent actor-origin sums accepted')
print('PASS invalid actor-origin sums rejected before restore')
local druidTarget=ns.Storage.Open({},'druid');druidTarget:Character().class='DRUID';druidTarget:Character().name='Destination';druidTarget:Rebuild()
db:Character().class='HUNTER';db:Character().name='Source'
assert(not ns.Transfer.Stage(ns.Transfer.Export(db),druidTarget),'cross-class restore accepted')
db:Character().class='DRUID'
local identityPreview=assert(ns.Transfer.Stage(ns.Transfer.Export(db),druidTarget));assert(ns.Transfer.Apply(identityPreview,druidTarget))
assert(druidTarget:Character().class=='DRUID' and druidTarget:Character().name=='Destination','import overwrote live identity and weapon classification context')
print('PASS destination class and name remain authoritative after restore')
local legacySource=ns.Storage.Open({},'legacy');legacySource:UpsertContribution({receiptID='legacy',profile='16:10:0;17:empty;18:empty',mode='pve',damage=5,seconds=1,spells={{spellID=6603,origin='player',damage={value=5}}}})
local hunterTarget=ns.Storage.Open({},'hunter');hunterTarget:Character().class='HUNTER';hunterTarget:Rebuild()
local legacyPreview=assert(ns.Transfer.Stage(ns.Transfer.Export(legacySource),hunterTarget));assert(legacyPreview.data.receipts.legacy.spells[1].origin=='unknown','missing source class acquired melee certainty')
print('PASS imports without class evidence cannot create melee-source certainty')

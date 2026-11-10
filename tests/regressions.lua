local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Meter','Equipment','Metrics','Sessions','Methods','Comparisons','Json','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
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

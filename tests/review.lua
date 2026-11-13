local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Meter','Equipment','Sessions','Methods','Records','Categories','Stats','Json','BuildSnapshot','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
assert(ns.Storage.Open({schema=1,characters={p={}}},'p').readonly,'corrupt saved data must be preserved read-only')
local db=ns.Storage.Open({},'p');db:Character();db:Rebuild();local doc=assert(ns.Json.Decode(ns.Transfer.Export(db)));doc.data.selectedMethod={};assert(not ns.Transfer.Stage(ns.Json.Encode(doc),db),'invalid method accepted')
local n=100
local meter={capabilities={damage=true},api={Enum={DamageMeterType={DamageDone=0}}},ReadSession=function()return {totalDamage={value=n},duration={value=10},nativeDPS={value=10},spells={},combatMode='unknown'}end}
local r=ns.Sessions.New(db,meter,{Snapshot=function()return {id='w',complete=true}end},function()return 0 end)
r:Handle('PLAYER_REGEN_DISABLED');r:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);r:Handle('PLAYER_REGEN_ENABLED')
for t=0,100,10 do r:Tick(t)end
r:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,99);r:Tick(200);assert(db:Character().totalDamage==100,'stale equipment admitted unrelated session')
n=200;r:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);r:Tick(300);assert(db:Character().totalDamage==200,'late revision ignored')
local d=ns.Storage.Open({},'d');d:UpsertContribution({receiptID='1',profile='w',mode='pve',damage=100,seconds=10,spells={}});d:UpsertContribution({receiptID='2',profile='w',mode='pve',damage=900,spells={}})
local pool;for _,row in pairs(d:Character().rows)do pool=row end
assert(pool.damage==1000 and pool.timedDamage==100 and pool.seconds==10,'untimed damage must stay out of the timed DPS pool')
print('PASS five independent review regressions')

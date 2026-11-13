local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Meter','Equipment','Sessions','Methods'}) do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('TitanApproxDPS',ns) end
local n=0
local function eq(a,b) n=n+1;assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local cap=ns.Capabilities
local secret={}; local api={issecretvalue=function(v)return v==secret end}
eq(cap.IsPublic(secret,api),false)
eq(cap.Probe({}).damage,false)
local calls=0
api.Enum={DamageMeterType={DamageDone=0},DamageMeterSessionType={Current=1}}
api.C_DamageMeter={GetCombatSessionFromID=function() calls=calls+1;return {durationSeconds=10,combatSources={{isLocalPlayer=true,totalAmount=100,amountPerSecond=10,sourceGUID='p'}}}end,GetCombatSessionSourceFromID=function()return {combatSpells={{spellID=42,totalAmount=100,amountPerSecond=10}},maxAmount=100}end}
local meter=ns.Meter.New(api,cap.Probe(api))
local snapshot=assert(meter:ReadSession(1));eq(snapshot.totalDamage.value,100);eq(snapshot.spells[1].spellID,42);eq(snapshot.maxHit,nil)
api.InCombatLockdown=function()return true end
eq(meter:ReadSession(1),nil);eq(calls,1)
api.InCombatLockdown=function()return false end
local db=ns.Storage.Open({},'player'); local eqp={Snapshot=function()return {id='weapon',complete=true}end}
local rec=ns.Sessions.New(db,meter,eqp,function()return 100 end)
rec:Baseline({{sessionID=1}});rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,2)
eq(calls,1);rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(100);eq(db:Character().totalDamage,100)
rec:Tick(102);eq(db:Character().totalDamage,100)
local c=db:Character();eq(c.modes.unknown,100);eq(c.modes.pve,0)
local methods=ns.Methods.New(db);local ref=methods:Define('Ranged','');methods:Select(ref);eq(methods:Snapshot().version,1)
local ref2=methods:Define('Ranged revised','',ref.methodID);eq(ref2.version,2);eq(ref.version,1)
local rowCount=0;for _,row in pairs(db:Character().rows)do rowCount=rowCount+1;eq(row.damage,100)end;eq(rowCount,1)
local badapi={Enum=api.Enum,C_DamageMeter={GetCombatSessionFromID=function()return {durationSeconds=10,combatSources={{isLocalPlayer=true,totalAmount=secret}}}end},issecretvalue=api.issecretvalue}
eq(ns.Meter.New(badapi,cap.Probe(badapi)):ReadSession(2),nil)
print('PASS '..n..' domain assertions')

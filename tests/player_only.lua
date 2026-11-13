local ns={};for _,f in ipairs({'Namespace','Capabilities','Meter'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local requested
local api={UnitGUID=function()return 'self'end,Enum={DamageMeterType={DamageDone=0}},C_DamageMeter={GetCombatSessionFromID=function()return {durationSeconds=10,totalAmount=9999,combatSources={{isLocalPlayer=false,sourceGUID='friend',totalAmount=9000},{isLocalPlayer=true,sourceGUID='self',totalAmount=100}}}end,GetCombatSessionSourceFromID=function(_,_,guid)requested=guid;return {combatSpells={{spellID=75,totalAmount=100,creatureName=''}}}end}}
local m=ns.Meter.New(api,ns.Capabilities.Probe(api));local s=assert(m:ReadSession(1));assert(s.totalDamage.value==100 and requested=='self')
api.C_DamageMeter.GetCombatSessionFromID=function()return {combatSources={{isLocalPlayer=true,sourceGUID='friend',totalAmount=9000}}}end
assert(not m:ReadSession(2),'mismatched player source accepted')
print('PASS group totals excluded and local source GUID verified')

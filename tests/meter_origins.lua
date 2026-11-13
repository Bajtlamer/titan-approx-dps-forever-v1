local ns={};for _,f in ipairs({'Namespace','Capabilities','Meter'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local secret={};local api={Enum={DamageMeterType={DamageDone=0}},issecretvalue=function(v)return v==secret end}
api.C_DamageMeter={GetCombatSessionFromID=function()return {durationSeconds=10,combatSources={{isLocalPlayer=true,sourceGUID='p',totalAmount=100}}}end,
GetCombatSessionSourceFromID=function()return {combatSpells={{spellID=6603,totalAmount=30,creatureName=''},{spellID=6603,totalAmount=50,creatureName='Cat'},{spellID=75,totalAmount=20,creatureName=secret}}}end}
local result=assert(ns.Meter.New(api,ns.Capabilities.Probe(api)):ReadSession(1))
assert(#result.spells==3);assert(result.spells[1].origin=='player');assert(result.spells[2].origin=='summon');assert(result.spells[3].origin=='unknown');assert(result.totalDamage.value==100)
for _,s in ipairs(result.spells)do assert(s.creatureName==nil,'private pet name persisted')end
print('PASS guarded native actor markers and source-name exclusion')

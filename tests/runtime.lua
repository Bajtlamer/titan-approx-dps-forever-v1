local ns={};local frames={};local now=0;local combat=false;local reads=0;local tick
local function object()
 local o={shown=true,scripts={}}
 return setmetatable(o,{__index=function(_,k)
  if k=='CreateTexture' or k=='CreateFontString' or k=='GetNormalTexture' then return function()return object()end end
  if k=='SetScript'then return function(self,n,f)self.scripts[n]=f end end
  if k=='IsShown'then return function(self)return self.shown end end
  if k=='Show' or k=='Hide'then return function(self)self.shown=k=='Show' end end
  if k=='GetWidth' or k=='GetHeight'then return function()return 140 end end
  return function()end
 end})
end
UIParent=object();Minimap=object();UISpecialFrames={};SlashCmdList={}
CreateFrame=function()local o=object();o.TitleText=object();frames[#frames+1]=o;return o end
UnitGUID=function()return 'p'end
GetTime=function()return now end
InCombatLockdown=function()return combat end
GetInventoryItemID=function(_,slot)return slot==16 and 100 or nil end
GetInventoryItemLink=function(_,slot)return slot==16 and '|Hitem:100:0|h[Sword]|h' or nil end
Enum={DamageMeterType={DamageDone=0},DamageMeterSessionType={Current=1}}
C_DamageMeter={GetAvailableCombatSessions=function()return {}end,GetCombatSessionFromID=function()reads=reads+1;return {durationSeconds=10,combatSources={{isLocalPlayer=true,sourceGUID='p',totalAmount=200,amountPerSecond=20}}}end}
C_Timer={NewTicker=function(_,f)tick=f;return {Cancel=function()tick=nil end}end}
for line in io.lines('TitanApproxDPS/TitanApproxDPS.toc')do if line:match('%.lua$')then assert(loadfile('TitanApproxDPS/'..line))('TitanApproxDPS',ns)end end
local event=frames[1].scripts.OnEvent
event(nil,'PLAYER_LOGIN');combat=true;event(nil,'PLAYER_REGEN_DISABLED');event(nil,'DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);tick();assert(reads==0)
combat=false;event(nil,'PLAYER_REGEN_ENABLED');now=1;tick();assert(ns.store:Character().totalDamage==200)
SlashCmdList.TITANAPPROXDPS('window');assert(ns.Window.frame:IsShown())
print('PASS simulated login, event capture, combat deferral and results window')
local life=ns.store:Character().totalDamage;combat=true;ns.ResetWeaponReports();assert(ns.store:Character().totalDamage==life and next(ns.store:Character().reportRows)~=nil)
combat=false;ns.ResetWeaponReports();assert(ns.store:Character().totalDamage==life and next(ns.store:Character().reportRows)==nil)
print('PASS live reset routing refuses combat and preserves lifetime outside combat')

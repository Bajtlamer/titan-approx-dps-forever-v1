local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Meter','Sessions'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local target='Forest Spider';local api={UnitName=function()return target end,UnitIsPlayer=function()return false end,IsInGroup=function()return true end,Enum={DamageMeterType={DamageDone=0}}}
local meter={api=api,capabilities={damage=true},ReadSession=function()return {totalDamage={value=10},duration={value=2},nativeDPS={value=5},spells={},combatMode='unknown'}end}
local db=ns.Storage.Open({},'p');local rec=ns.Sessions.New(db,meter,{Snapshot=function()return {id='weapon',complete=true}end},function()return 0 end)
rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,0);rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,1);rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(0);rec:Tick(1)
assert(db:Character().totalDamage==10 and #db:Character().history==1,'zero/overall or repeated updates double counted')
local first=db:Character().receipts[db:Character().history[1]];assert(first.nativeSessionID==1 and first.context.targetName=='Forest Spider' and first.context.grouped==true)
target='Owl';rec:Handle('PLAYER_REGEN_DISABLED');rec:Handle('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,2);rec:Handle('PLAYER_TARGET_CHANGED');rec:Handle('PLAYER_REGEN_ENABLED');rec:Tick(2)
assert(db:Character().totalDamage==20);local second=db:Character().receipts[db:Character().history[2]];assert(second.context.targetName=='Owl' and second.context.targetChanges==1);assert(first.context.targetName=='Forest Spider')
print('PASS individual session evidence, target labels, target changes and no repeated/overall accumulation')

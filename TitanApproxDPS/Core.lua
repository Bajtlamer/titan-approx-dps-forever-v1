local _,ns=...
function ns.Print(message) print('Titan Approx DPS: '..tostring(message))end
local events=CreateFrame('Frame')
local function available()
 local api=C_DamageMeter
 if api and api.GetAvailableCombatSessions then local ok,rows=pcall(api.GetAvailableCombatSessions);if ok and ns.Capabilities.IsPublic(rows) and type(rows)=='table' then return rows end end
 return {}
end
function ns.Rebaseline()
 ns.recorder=ns.Sessions.New(ns.store,ns.Meter.New(_G,ns.capabilities),ns.Equipment.New(_G),GetTime)
 ns.recorder:Baseline(available());ns.recorder.changed=function()ns.Window.Refresh()end
end
local function initialize()
 local id=UnitGUID('player');if not ns.Capabilities.IsPublic(id) or type(id)~='string' then ns.Print('Public character identity unavailable; recording disabled.');return end
 TitanApproxDPSDB=type(TitanApproxDPSDB)=='table' and TitanApproxDPSDB or {}
 ns.store=ns.Storage.Open(TitanApproxDPSDB,id);if ns.store.readonly then ns.Print('Future database schema preserved; recording disabled.');return end
 ns.store:Character();local valid=pcall(ns.store.Rebuild,ns.store);if not valid then ns.store.readonly=true;ns.Print('Malformed statistics preserved; recording disabled.');return end;ns.capabilities=ns.Capabilities.Probe(_G);ns.Rebaseline();ns.Titan.Initialize();ns.Minimap.Initialize()
 SLASH_TITANAPPROXDPS1='/tadps'
 SlashCmdList.TITANAPPROXDPS=function(input)
  local cmd,arg=input:match('^(%S*)%s*(.-)$')
  if cmd=='pause' or cmd=='resume' then ns.recorder:Pause(cmd=='pause');if cmd=='resume' then ns.recorder:Baseline(available())end;ns.Print(cmd)
  elseif cmd=='export' or cmd=='import' then ns.TransferView.Show(cmd=='import')
  elseif cmd=='method' then if InCombatLockdown()then ns.Print('Choose methods outside combat.');return end;local m=ns.Methods.New(ns.store);local ok,ref=pcall(m.Define,m,arg,'');if ok then m:Select(ref);ns.Print('Next fight method: '..arg)else ns.Print(ref)end
  elseif cmd=='minimap' then local s=ns.store.saved.settings;s.minimap=not s.minimap;ns.Minimap.button:SetShown(s.minimap)
  else ns.Window.Show(cmd=='status' and 'Data' or cmd=='compare' and 'Compare' or nil)end
 end
end
for _,event in ipairs({'PLAYER_LOGIN','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','PLAYER_EQUIPMENT_CHANGED','DAMAGE_METER_COMBAT_SESSION_UPDATED','DAMAGE_METER_CURRENT_SESSION_UPDATED','DAMAGE_METER_RESET'})do pcall(events.RegisterEvent,events,event)end
local ticker
local function schedule()
 if ticker then return end
 ticker=C_Timer.NewTicker(.5,function()
  if ns.recorder then ns.recorder:Tick(GetTime());if next(ns.recorder.pending)==nil then ticker:Cancel();ticker=nil end end
 end)
end
events:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_LOGIN' then initialize();return end
 if ns.recorder then ns.recorder:Handle(event,...);if event=='PLAYER_REGEN_ENABLED' or event=='DAMAGE_METER_COMBAT_SESSION_UPDATED' then schedule()end end
end)

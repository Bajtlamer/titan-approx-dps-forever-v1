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
 ns.recorder:Baseline(available());ns.recorder.changed=function()ns.Titan.Refresh();ns.Window.Refresh()end
end
function ns.ResetWeaponReports()
 if InCombatLockdown()then ns.Print('Finish combat before starting fresh weapon reports.');return end
 ns.store:ResetReports(time and time() or nil);ns.Rebaseline();ns.Titan.Refresh();ns.Window.Refresh()
 ns.Print('Fresh weapon reports started. Character and weapon lifetime records preserved.')
end
local function initialize()
 local id=UnitGUID('player');if not ns.Capabilities.IsPublic(id) or type(id)~='string' then ns.Print('Public character identity unavailable; recording disabled.');return end
 TitanApproxDPSDB=type(TitanApproxDPSDB)=='table' and TitanApproxDPSDB or {}
 ns.store=ns.Storage.Open(TitanApproxDPSDB,id);if ns.store.readonly then ns.Print('Future database schema preserved; recording disabled.');return end
 local character=ns.store:Character();if UnitClass then local _,class=UnitClass('player');if ns.Capabilities.IsPublic(class) and type(class)=='string' then character.class=class end end;if UnitName then local name=UnitName('player');if ns.Capabilities.IsPublic(name) and type(name)=='string'then character.name=name end end;local valid=pcall(ns.store.Rebuild,ns.store);if not valid then ns.store.readonly=true;ns.Print('Malformed statistics preserved; recording disabled.');return end;ns.capabilities=ns.Capabilities.Probe(_G);if character.reportGeneration==nil then ns.store:ResetReports(time and time() or nil)end;ns.Rebaseline();ns.Titan.Initialize();ns.Minimap.Initialize()
 SLASH_TITANAPPROXDPS1='/tadps'
 SlashCmdList.TITANAPPROXDPS=function(input)
  local cmd,arg=input:match('^(%S*)%s*(.-)$')
  if cmd=='pause' or cmd=='resume' then ns.recorder:Pause(cmd=='pause');if cmd=='resume' then ns.recorder:Baseline(available())end;ns.Print(cmd)
  elseif cmd=='export' or cmd=='import' then ns.TransferView.Show(cmd=='import')
  elseif cmd=='method' then if InCombatLockdown()then ns.Print('Choose methods outside combat.');return end;local m=ns.Methods.New(ns.store);local ok,ref=pcall(m.Define,m,arg,'');if ok then m:Select(ref);ns.Print('Next fight method: '..arg)else ns.Print(ref)end
  elseif cmd=='minimap' then local s=ns.store.saved.settings;s.minimap=not s.minimap;ns.Minimap.button:SetShown(s.minimap)
  elseif cmd=='window' or cmd=='compare' or cmd=='status' then ns.Window.Show(cmd=='status' and 'Data' or cmd=='compare' and 'Compare' or 'Overview')
  else ns.Titan.Show(ns.Minimap.button)end
 end
end
for _,event in ipairs({'PLAYER_LOGIN','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','PLAYER_EQUIPMENT_CHANGED','PLAYER_TARGET_CHANGED','GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','DAMAGE_METER_COMBAT_SESSION_UPDATED','DAMAGE_METER_CURRENT_SESSION_UPDATED','DAMAGE_METER_RESET'})do pcall(events.RegisterEvent,events,event)end
local ticker
local function schedule()
 if ticker then return end
 ticker=C_Timer.NewTicker(.5,function()
  if ns.recorder then ns.recorder:Tick(GetTime());if next(ns.recorder.pending)==nil then ticker:Cancel();ticker=nil end end
 end)
end
events:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_LOGIN' then initialize();return end
 if ns.recorder then if event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT' then ns.Titan.Refresh();return end;ns.recorder:Handle(event,...);if event=='PLAYER_REGEN_ENABLED' or event=='DAMAGE_METER_COMBAT_SESSION_UPDATED' then schedule()end end
end)

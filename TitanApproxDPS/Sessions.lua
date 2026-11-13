local _,ns=...
local S={};S.__index=S;ns.Sessions=S
function S.New(store,meter,equipment,clock)
 local self=setmetatable({store=store,meter=meter,equipment=equipment,clock=clock,pending={},tracked={},seen={},combat=false,paused=store.saved.settings and not store.saved.settings.recording},S)
 self.idleBuild=ns.BuildSnapshot and ns.BuildSnapshot.Take(meter.api,'out of combat')
 return self
end
function S:Baseline(rows)
 for _,r in ipairs(rows or {})do if ns.Capabilities.IsPublic(r,self.meter.api) and ns.Capabilities.IsPublic(r.sessionID,self.meter.api) and type(r.sessionID)=='number' then self.seen[r.sessionID]=true end end
end
function S:Handle(event,kind,id)
 local c=self.store:Character();if not c then return end
 if event=='PLAYER_REGEN_DISABLED' then self.context=self:Context();self.combat=true;self.initial=self.equipment:Snapshot();self.mixed=false;self.method=ns.Copy(c.selectedMethod)
  -- Offensive stats are read once per combat. If nothing is readable at combat start, the last out-of-combat reading is used and labelled as such.
  self.build=ns.BuildSnapshot and (ns.BuildSnapshot.Take(self.meter.api,'combat start') or ns.Copy(self.idleBuild)) or nil
 elseif event=='PLAYER_TARGET_CHANGED' and self.combat then self.context.targetChanges=self.context.targetChanges+1
 elseif event=='PLAYER_EQUIPMENT_CHANGED' and self.combat then self.mixed=true
 elseif event=='PLAYER_REGEN_ENABLED' then self.combat=false;if ns.BuildSnapshot then self.idleBuild=ns.BuildSnapshot.Take(self.meter.api,'out of combat') or self.idleBuild end;for _,p in pairs(self.pending)do if not p.finished then p.mixed=self.mixed;p.finished=true end end
 elseif event=='DAMAGE_METER_RESET' then self.pending={};self.tracked={};self.seen={};c.epoch=c.epoch+1;self.initial=nil
 elseif event=='DAMAGE_METER_COMBAT_SESSION_UPDATED' and self.meter.capabilities.damage and ns.Capabilities.IsPublic(kind,self.meter.api) and ns.Capabilities.IsPublic(id,self.meter.api) and kind==self.meter.api.Enum.DamageMeterType.DamageDone and type(id)=='number' and id>0 and not self.paused then
  local p=self.pending[id]
  if not p and self.tracked[id] then p=self.tracked[id];p.tries=0;p.at=self.clock();self.pending[id]=p end
  if not p and not self.seen[id] then
   local count=0;for _ in pairs(self.pending)do count=count+1 end
   if count>=32 then self.gap='Pending session limit reached';return end
   c.sequence=c.sequence+1
   p={receiptID=c.epoch..':'..c.sequence,build=self.build,profile=self.initial,method=ns.Copy(self.method),at=self.clock(),tries=0,eligible=self.combat and self.initial~=nil,mixed=self.mixed,context=self.context};self.pending[id]=p;self.tracked[id]=p;self.seen[id]=true
  end
 end
end
function S:Pause(value)
 self.paused=value;self.store.saved.settings.recording=not value
 if value then for _,p in pairs(self.pending)do if self.combat then p.eligible=false end end end
 self.initial=nil
end
function S:Tick(now)
 if self.combat or self.paused or self.store.readonly then return end
 for id,p in pairs(self.pending)do if now>=p.at then
  if not p.eligible then self.pending[id]=nil;self.gap='Session start not fully observed'
  else
   local r,reason=self.meter:ReadSession(id)
   if r then
    local e=p.profile;local c=self.store:Character();local profile=(not p.mixed and e and e.complete) and e.id or 'Mixed or incomplete equipment'
    c.profiles[profile]=e and e.name or profile
    local changed=self.store:UpsertContribution({receiptID=p.receiptID,profile=profile,mode=r.combatMode,damage=r.totalDamage.value,seconds=r.duration.value,spells=r.spells,method=p.method and (p.method.methodID..':'..p.method.version),nativeDPS=r.nativeDPS.value,at=now,reason=r.combatModeReason,nativeSessionID=id,context=ns.Copy(p.context),build=ns.Copy(p.build)})
    if changed and self.changed then self.changed()end
    p.tries=p.tries+1;p.at=now+({0.5,1,2,5,10})[math.min(p.tries,5)]
    if p.tries>=5 then self.pending[id]=nil end
   else p.tries=p.tries+1;p.at=now+({0.5,1,2,5,10})[math.min(p.tries,5)];self.gap=reason end
  end
 end end
end

function S:Context()
 local api=self.meter.api;local context={targetChanges=0,targetName='Target not recorded'}
 local function read(fn,...)
  if type(fn)~='function'then return nil end
  local ok,value=pcall(fn,...);if ok and ns.Capabilities.IsPublic(value,api)then return value end
 end
 local player=read(api.UnitIsPlayer,'target');local name=read(api.UnitName,'target')
 if player==false and type(name)=='string'then context.targetName=name;context.targetKind='npc'
 elseif player==true then context.targetName='Player target';context.targetKind='player'end
 local grouped=read(api.IsInGroup);if type(grouped)=='boolean'then context.grouped=grouped end
 return context
end

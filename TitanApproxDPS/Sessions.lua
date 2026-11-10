local _,ns=...
local S={};S.__index=S;ns.Sessions=S
function S.New(store,meter,equipment,clock)
 return setmetatable({store=store,meter=meter,equipment=equipment,clock=clock,pending={},tracked={},seen={},combat=false,paused=store.saved.settings and not store.saved.settings.recording},S)
end
function S:Baseline(rows)
 for _,r in ipairs(rows or {})do if ns.Capabilities.IsPublic(r,self.meter.api) and ns.Capabilities.IsPublic(r.sessionID,self.meter.api) and type(r.sessionID)=='number' then self.seen[r.sessionID]=true end end
end
function S:Handle(event,kind,id)
 local c=self.store:Character();if not c then return end
 if event=='PLAYER_REGEN_DISABLED' then self.combat=true;self.initial=self.equipment:Snapshot();self.mixed=false;self.method=ns.Copy(c.selectedMethod)
 elseif event=='PLAYER_EQUIPMENT_CHANGED' and self.combat then self.mixed=true
 elseif event=='PLAYER_REGEN_ENABLED' then self.combat=false;for _,p in pairs(self.pending)do if not p.finished then p.mixed=self.mixed;p.finished=true end end
 elseif event=='DAMAGE_METER_RESET' then self.pending={};self.tracked={};self.seen={};c.epoch=c.epoch+1;self.initial=nil
 elseif event=='DAMAGE_METER_COMBAT_SESSION_UPDATED' and self.meter.capabilities.damage and ns.Capabilities.IsPublic(kind,self.meter.api) and ns.Capabilities.IsPublic(id,self.meter.api) and kind==self.meter.api.Enum.DamageMeterType.DamageDone and type(id)=='number' and not self.paused then
  local p=self.pending[id]
  if not p and self.tracked[id] then p=self.tracked[id];p.tries=0;p.at=self.clock();self.pending[id]=p end
  if not p and not self.seen[id] then
   local count=0;for _ in pairs(self.pending)do count=count+1 end
   if count>=32 then self.gap='Pending session limit reached';return end
   c.sequence=c.sequence+1
   p={receiptID=c.epoch..':'..c.sequence,profile=self.initial,method=ns.Copy(self.method),at=self.clock(),tries=0,eligible=self.combat and self.initial~=nil,mixed=self.mixed};self.pending[id]=p;self.tracked[id]=p;self.seen[id]=true
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
    local changed=self.store:UpsertContribution({receiptID=p.receiptID,profile=profile,mode=r.combatMode,damage=r.totalDamage.value,seconds=r.duration.value,spells=r.spells,method=p.method and (p.method.methodID..':'..p.method.version),nativeDPS=r.nativeDPS.value,at=now,reason=r.combatModeReason})
    if changed and self.changed then self.changed()end
    p.tries=p.tries+1;p.at=now+({0.5,1,2,5,10})[math.min(p.tries,5)]
    if p.tries>=5 then self.pending[id]=nil end
   else p.tries=p.tries+1;p.at=now+({0.5,1,2,5,10})[math.min(p.tries,5)];self.gap=reason end
  end
 end end
end

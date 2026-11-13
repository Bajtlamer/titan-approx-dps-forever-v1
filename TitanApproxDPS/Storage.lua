local _,ns=...
local S={};S.__index=S;ns.Storage=S
function S.Open(saved,id)
 saved=type(saved)=='table' and saved or {}
 local readonly=saved.schema~=nil and saved.schema~=1
 if saved.schema==1 then
  local ok=pcall(function()
   assert(type(saved.characters)=='table')
   for _,c in pairs(saved.characters)do
    assert(type(c)=='table');assert(c.reportGeneration==nil or (ns.Number(c.reportGeneration) and c.reportGeneration%1==0));assert(c.reportBaseRows==nil or type(c.reportBaseRows)=='table');assert(c.preservedLifetimeDamage==nil or ns.Number(c.preservedLifetimeDamage));assert(c.reportHidden==nil or type(c.reportHidden)=='table')
    for _,k in ipairs({'receipts','order','history','baseRows','methods','profiles'})do assert(type(c[k])=='table')end
    for _,k in ipairs({'baseDamage','baseSeconds','totalDamage','sequence','epoch','revision'})do assert(ns.Number(c[k]))end
    for _,row in pairs(c.baseRows)do if type(row)=='table' and type(row.spells)=='table'then for _,s in pairs(row.spells)do assert(type(s)=='table' and ns.ValidOrigins(s.origins,s.damage,s.timedDamage))end end end
    for _,r in pairs(c.receipts)do assert(type(r)=='table' and ns.Number(r.damage) and type(r.spells)=='table' and type(r.profile)=='string' and ({pve=true,pvp=true,mixed=true,unknown=true})[r.mode]);for _,spell in ipairs(r.spells)do assert(type(spell)=='table' and type(spell.damage)=='table' and ns.Number(spell.damage.value))end end
   end
  end)
  if not ok then readonly=true end
 end
 if not readonly then saved.schema=1;saved.characters=saved.characters or {};saved.settings=ns.Settings.Normalize(saved.settings) end
 return setmetatable({saved=saved,id=id,readonly=readonly},S)
end
function S:Character()
 if self.readonly then return nil end
 local c=self.saved.characters[self.id]
 if not c then c={receipts={},order={},history={},baseDamage=0,baseSeconds=0,baseRows={},totalDamage=0,modes={pve=0,pvp=0,mixed=0,unknown=0},methods={},profiles={},sequence=0,epoch=1,revision=0};self.saved.characters[self.id]=c end
 return c
end
local function add(rows,r)
 local key=r.profile..'/'..r.mode..'/'..(r.method or '')
 local a=rows[key] or {profile=r.profile,mode=r.mode,method=r.method,damage=0,timedDamage=0,seconds=0,sessions=0,spells={}};rows[key]=a
 a.damage=a.damage+r.damage;if r.seconds and r.seconds>0 then a.timedDamage=(a.timedDamage or 0)+r.damage end;a.seconds=a.seconds+(r.seconds or 0);a.sessions=a.sessions+1
 for _,s in ipairs(r.spells or {})do local x=a.spells[s.spellID] or {damage=0,timedDamage=0};a.spells[s.spellID]=x;local origin=({player=true,summon=true,unknown=true})[s.origin] and s.origin or 'unknown'
 x.origins=x.origins or {unknown={damage=x.damage,timedDamage=x.timedDamage or 0}}
 local part=x.origins[origin] or {damage=0,timedDamage=0};x.origins[origin]=part;part.damage=part.damage+s.damage.value;if r.seconds and r.seconds>0 then part.timedDamage=part.timedDamage+s.damage.value end
 x.damage=x.damage+s.damage.value;if r.seconds and r.seconds>0 then x.timedDamage=(x.timedDamage or 0)+s.damage.value end end
end
function S:Rebuild()
 local c=self:Character();if not c then return end
 c.rows=ns.Copy(c.baseRows);c.totalDamage=c.baseDamage+(c.preservedLifetimeDamage or 0);c.totalSeconds=c.baseSeconds;c.modes={pve=0,pvp=0,mixed=0,unknown=0}
 for _,r in pairs(c.receipts)do c.totalDamage=c.totalDamage+r.damage;c.totalSeconds=c.totalSeconds+(r.seconds or 0);add(c.rows,r)end
 for _,row in pairs(c.rows)do c.modes[row.mode]=c.modes[row.mode]+row.damage end
 if c.reportGeneration and c.reportGeneration>0 then
  c.reportRows=ns.Copy(c.reportBaseRows or {})
  for _,r in pairs(c.receipts)do if r.reportGeneration==c.reportGeneration then add(c.reportRows,r)end end
 else c.reportRows=c.rows end
end
function S:UpsertContribution(r)
 local c=self:Character();if not c then return false end
 local old=c.receipts[r.receiptID]
 if old then
  -- Rebuild even when damage is equal: spell breakdowns may have changed.
 else c.order[#c.order+1]=r.receiptID end
 r=ns.Copy(r);r.reportGeneration=old and (old.reportGeneration or 0) or (c.reportGeneration or 0)
 c.receipts[r.receiptID]=ns.Copy(r);c.revision=c.revision+1
 if not old then c.history[#c.history+1]=r.receiptID end
 while #c.history>200 do table.remove(c.history,1)end
 while #c.order>2048 do local k=table.remove(c.order,1);local prior=c.receipts[k];c.baseDamage=c.baseDamage+prior.damage;c.baseSeconds=c.baseSeconds+(prior.seconds or 0);add(c.baseRows,prior);if c.reportGeneration and prior.reportGeneration==c.reportGeneration then c.reportBaseRows=c.reportBaseRows or {};add(c.reportBaseRows,prior)end;c.receipts[k]=nil end
 self:Rebuild();return true
end

function S:ResetReports(at)
 local c=self:Character();if not c then return false end
 c.reportGeneration=(c.reportGeneration or 0)+1;c.reportBaseRows={};c.reportStartedAt=at;c.revision=c.revision+1
 self:Rebuild();return true
end

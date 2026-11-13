local _,ns=...
-- Protected best-fight records. Values only ever grow: there is intentionally no
-- function that clears, lowers or deletes a record. Merge keeps the larger value.
local R={};ns.Records=R

local MIN_DPS_SECONDS=10
R.MinDpsSeconds=MIN_DPS_SECONDS

local function newRecords()
 return {character={},weapons={}}
end

local function entryOk(e,isSpell)
 if type(e)~='table' or not ns.Number(e.value) then return false end
 if e.seconds~=nil and not ns.Number(e.seconds) then return false end
 if e.at~=nil and not ns.Number(e.at) then return false end
 if e.receiptID~=nil and type(e.receiptID)~='string' then return false end
 return true
end

function R.Validate(rec)
 if type(rec)~='table' then return false end
 if rec.character~=nil then
  if type(rec.character)~='table' then return false end
  for _,k in ipairs({'fightDamage','fightDPS'})do
   if rec.character[k]~=nil and not entryOk(rec.character[k])then return false end
  end
 end
 if rec.weapons~=nil then
  if type(rec.weapons)~='table' then return false end
  for key,w in pairs(rec.weapons)do
   if type(key)~='string' or type(w)~='table' then return false end
   if w.name~=nil and type(w.name)~='string' then return false end
   for _,k in ipairs({'fightDamage','fightDPS'})do
    if w[k]~=nil and not entryOk(w[k])then return false end
   end
   if w.spells~=nil then
    if type(w.spells)~='table' then return false end
    for id,s in pairs(w.spells)do
     if not tonumber(id) or not entryOk(s)then return false end
    end
   end
  end
 end
 return true
end

-- JSON restores numeric object keys as strings; spell IDs are numbers in storage.
function R.Normalize(rec)
 if type(rec)~='table' then return rec end
 for _,w in pairs(rec.weapons or {})do
  if type(w.spells)=='table' then
   local fixed={};for id,s in pairs(w.spells)do fixed[tonumber(id)]=s end;w.spells=fixed
  end
 end
 return rec
end

local function take(current,candidate)
 if not current or candidate.value>current.value then return ns.Copy(candidate) end
 return current
end

local function raise(holder,field,value,seconds,at,receiptID)
 if not ns.Number(value) or value<=0 then return end
 holder[field]=take(holder[field],{value=value,seconds=seconds,at=at,receiptID=receiptID})
end

-- Observe one stored receipt. parts is the WeaponAttribution.Split result for it.
function R.Observe(character,receipt,parts)
 character.records=character.records or newRecords()
 local rec=character.records
 rec.character=rec.character or {};rec.weapons=rec.weapons or {}
 local seconds=ns.Number(receipt.seconds) and receipt.seconds or nil
 local at=ns.Number(receipt.at) and receipt.at or nil
 local id=receipt.receiptID
 local function observe(holder,damage,spells)
  raise(holder,'fightDamage',damage,seconds,at,id)
  if seconds and seconds>=MIN_DPS_SECONDS then raise(holder,'fightDPS',damage/seconds,seconds,at,id)end
  if spells then
   holder.spells=holder.spells or {}
   for spellID,s in pairs(spells)do
    if ns.Number(s.damage) and s.damage>0 then holder.spells[spellID]=take(holder.spells[spellID],{value=s.damage,at=at})end
   end
  end
 end
 observe(rec.character,receipt.damage)
 for key,p in pairs(parts or {})do
  if p.damage>0 then
   local w=rec.weapons[key] or {};rec.weapons[key]=w
   w.name=p.name
   observe(w,p.damage,p.spells)
  end
 end
end

local function mergeEntries(a,b)
 local out={}
 for k,e in pairs(a or {})do out[k]=ns.Copy(e)end
 for k,e in pairs(b or {})do out[k]=take(out[k],e)end
 return out
end

-- Field-wise maximum of two record sets. Neither input is modified.
function R.Merge(a,b)
 a=type(a)=='table' and a or {};b=type(b)=='table' and b or {}
 local out=newRecords()
 out.character=mergeEntries(a.character,b.character)
 for _,source in ipairs({a,b})do
  for key,w in pairs(source.weapons or {})do
   local t=out.weapons[key] or {};out.weapons[key]=t
   if w.name then t.name=w.name end
   for _,k in ipairs({'fightDamage','fightDPS'})do
    if w[k] then t[k]=take(t[k],w[k])end
   end
   if w.spells then t.spells=mergeEntries(t.spells,w.spells)end
  end
 end
 return out
end

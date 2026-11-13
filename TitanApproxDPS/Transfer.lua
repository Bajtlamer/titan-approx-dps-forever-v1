local _,ns=...
local T={};ns.Transfer=T
function T.Export(store)
 assert(not store.readonly,'Future database schema')
 return ns.Json.Encode({format='TitanApproxDPS-statistics',schema=1,character=store.id,data=store:Character()})
end
local function validate(c)
 assert(type(c)=='table','Missing character');
 if c.reportGeneration~=nil then assert(ns.Number(c.reportGeneration) and c.reportGeneration%1==0,'Invalid report period')end
 if c.reportStartedAt~=nil then assert(ns.Number(c.reportStartedAt),'Invalid report start')end
assert(c.class==nil or (type(c.class)=='string' and c.class:match('^[A-Z]+$')),'Invalid class');assert(c.preservedLifetimeDamage==nil or ns.Number(c.preservedLifetimeDamage),'Invalid protected lifetime');if c.reportHidden~=nil then assert(type(c.reportHidden)=='table','Invalid report settings');for k,v in pairs(c.reportHidden)do assert(type(k)=='string' and type(v)=='boolean','Invalid hidden profile')end end
 assert(c.records==nil or ns.Records.Validate(c.records),'Invalid records')
 for _,field in ipairs({'baseDamage','baseSeconds','totalDamage','totalSeconds','sequence','epoch','revision'})do assert(ns.Number(c[field]),'Invalid '..field)end
 for _,field in ipairs({'receipts','order','history','baseRows','methods','profiles'})do assert(type(c[field])=='table','Missing '..field)end
 local modes={pve=true,pvp=true,mixed=true,unknown=true}
 local function row(r)
  assert(type(r)=='table' and type(r.profile)=='string' and modes[r.mode],'Invalid profile/mode')
  assert(ns.Number(r.damage) and (r.seconds==nil or ns.Number(r.seconds)),'Invalid damage/duration')
 end
 assert(#c.order<=2048 and #c.history<=200,'Retention limit')
 local seen={}
 for _,id in ipairs(c.order)do assert(type(id)=='string' and not seen[id] and c.receipts[id],'Receipt reference');seen[id]=true end
 for id,r in pairs(c.receipts)do if r.reportGeneration~=nil then assert(ns.Number(r.reportGeneration) and r.reportGeneration%1==0,'Invalid receipt report period')end;if r.nativeSessionID~=nil then assert(ns.Number(r.nativeSessionID) and r.nativeSessionID>0 and r.nativeSessionID%1==0,'Invalid native session')end;if r.context~=nil then assert(type(r.context)=='table','Invalid encounter context');assert(type(r.context.targetName)=='string' and #r.context.targetName<=256,'Invalid target label');assert(ns.Number(r.context.targetChanges),'Invalid target changes');assert(r.context.grouped==nil or type(r.context.grouped)=='boolean','Invalid group context')end;assert(seen[id] and id==r.receiptID,'Orphan receipt');row(r);assert(type(r.spells)=='table','Missing spells');for _,s in ipairs(r.spells)do assert(ns.Number(s.spellID) and s.spellID>0 and type(s.damage)=='table' and ns.Number(s.damage.value),'Invalid spell');assert(s.origin==nil or ({player=true,summon=true,unknown=true})[s.origin],'Invalid spell actor')end end
 for _,id in ipairs(c.history)do assert(seen[id],'History reference')end
 for _,r in pairs(c.baseRows)do row(r);assert(ns.Number(r.sessions) and type(r.spells)=='table','Invalid base row');for id,s in pairs(r.spells)do assert(tonumber(id) and type(s)=='table' and ns.Number(s.damage),'Invalid base spell');assert(ns.ValidOrigins(s.origins,s.damage,s.timedDamage),'Invalid actor-origin totals')end end
 if c.reportBaseRows~=nil then
  assert(type(c.reportBaseRows)=='table','Invalid report base')
  for _,r in pairs(c.reportBaseRows)do row(r);assert(ns.Number(r.seconds) and ns.Number(r.sessions) and ns.Number(r.timedDamage) and r.timedDamage<=r.damage and type(r.spells)=='table','Invalid report row');for id,s in pairs(r.spells)do assert(tonumber(id) and type(s)=='table' and ns.Number(s.damage) and ns.ValidOrigins(s.origins,s.damage,s.timedDamage),'Invalid report spell')end end
 end
 for id,versions in pairs(c.methods)do assert(type(id)=='string' and type(versions)=='table','Invalid methods');for _,m in ipairs(versions)do assert(type(m.name)=='string' and #m.name<=128 and type(m.description)=='string','Invalid method')end end
 if c.methodSequence~=nil then assert(ns.Number(c.methodSequence) and c.methodSequence%1==0,'Invalid method sequence')end
 local function method(ref)
  assert(type(ref)=='table' and type(ref.methodID)=='string' and ns.Number(ref.version) and ref.version%1==0 and c.methods[ref.methodID] and c.methods[ref.methodID][ref.version],'Invalid method reference')
 end
 if c.selectedMethod~=nil then method(c.selectedMethod)end
 for _,r in pairs(c.receipts)do if r.method then local id,ver=r.method:match('^(.-):(%d+)$');method({methodID=id,version=tonumber(ver)})end end
 local baseDamage,baseSeconds=0,0
 for _,r in pairs(c.baseRows)do baseDamage=baseDamage+r.damage;baseSeconds=baseSeconds+r.seconds;assert(ns.Number(r.timedDamage) and r.timedDamage<=r.damage,'Invalid timed pool')end
 assert(baseDamage==c.baseDamage and baseSeconds==c.baseSeconds,'Inconsistent historical base')
 for id,label in pairs(c.profiles)do assert(type(id)=='string' and type(label)=='string','Invalid profile label')end
end
function T.Stage(text,store)
 local doc,err=ns.Json.Decode(text);if not doc then return nil,err end
 local ok,result=pcall(function()
  assert(doc.format=='TitanApproxDPS-statistics' and doc.schema==1,'Unsupported transfer format');validate(doc.data)
  local destination=store:Character()
  assert(not(doc.data.class and destination.class and doc.data.class~=destination.class),'Cannot restore statistics from a different character class')
  local copy=ns.Copy(doc.data)
  if not(copy.class and destination.class and copy.class==destination.class)then
   for _,receipt in pairs(copy.receipts)do for _,spell in ipairs(receipt.spells)do if spell.origin=='player'then spell.origin='unknown'end end end
   for _,rows in ipairs({copy.baseRows,copy.reportBaseRows or {}})do for _,row in pairs(rows)do for _,spell in pairs(row.spells)do
    local origins=spell.origins
    if origins and origins.player then local old=origins.player;local unknown=origins.unknown or {damage=0,timedDamage=0};origins.unknown=unknown;unknown.damage=unknown.damage+old.damage;unknown.timedDamage=unknown.timedDamage+old.timedDamage;origins.player=nil end
   end end end
  end
  ns.Records.Normalize(copy.records)
 -- JSON object spell keys are normalized on restore.
  for _,rows in ipairs({copy.baseRows,copy.reportBaseRows or {}})do for _,r in pairs(rows)do local s={};for id,v in pairs(r.spells)do s[tonumber(id)]=v end;r.spells=s end end
  local temporary=ns.Storage.Open({schema=1,characters={[store.id]=copy}},store.id);temporary:Rebuild()
  assert(copy.totalDamage==doc.data.totalDamage,'Inconsistent total')
  if ns.Reports and ns.Reports.WeaponLifetime then
   local before=ns.Reports.WeaponLifetime(store);local after=ns.Reports.WeaponLifetime(temporary)
   for id,damage in pairs(before)do assert((after[id] or 0)>=damage,'Restore would reduce weapon lifetime history; use a complete newer backup')end
  end
  return {data=copy,revision=store:Character().revision,source=doc.character}
 end)
 if not ok then return nil,'Import rejected: '..tostring(result)end
 return result
end
function T.Apply(preview,store)
 if store.readonly or store:Character().revision~=preview.revision then return nil,'Destination changed; preview again' end
 local previous=ns.Copy(store:Character());store.saved.preImportBackup=previous
 local restored=ns.Copy(preview.data)
 restored.class=previous.class;restored.name=previous.name
 -- Records are protected: an import can only raise them.
 restored.records=ns.Records.Merge(previous.records,restored.records);restored.recordsBackfilled=nil
 restored.preservedLifetimeDamage=(restored.preservedLifetimeDamage or 0)+math.max(0,previous.totalDamage-restored.totalDamage)
 store.saved.characters[store.id]=restored;store:Rebuild()
 store:BackfillRecords()
 store:Character().epoch=store:Character().epoch+1;store:Character().revision=store:Character().revision+1;return true
end

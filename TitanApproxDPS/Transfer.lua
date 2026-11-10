local _,ns=...
local T={};ns.Transfer=T
function T.Export(store)
 assert(not store.readonly,'Future database schema')
 return ns.Json.Encode({format='TitanApproxDPS-statistics',schema=1,character=store.id,data=store:Character()})
end
local function validate(c)
 assert(type(c)=='table','Missing character')
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
 for id,r in pairs(c.receipts)do assert(seen[id] and id==r.receiptID,'Orphan receipt');row(r);assert(type(r.spells)=='table','Missing spells');for _,s in ipairs(r.spells)do assert(ns.Number(s.spellID) and s.spellID>0 and type(s.damage)=='table' and ns.Number(s.damage.value),'Invalid spell')end end
 for _,id in ipairs(c.history)do assert(seen[id],'History reference')end
 for _,r in pairs(c.baseRows)do row(r);assert(ns.Number(r.sessions) and type(r.spells)=='table','Invalid base row');for id,s in pairs(r.spells)do assert(tonumber(id) and type(s)=='table' and ns.Number(s.damage),'Invalid base spell')end end
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
  local copy=ns.Copy(doc.data)
  -- JSON object spell keys are normalized on restore.
  for _,r in pairs(copy.baseRows)do local s={};for id,v in pairs(r.spells)do s[tonumber(id)]=v end;r.spells=s end
  local temporary=ns.Storage.Open({schema=1,characters={[store.id]=copy}},store.id);temporary:Rebuild()
  assert(copy.totalDamage==doc.data.totalDamage,'Inconsistent total')
  return {data=copy,revision=store:Character().revision,source=doc.character}
 end)
 if not ok then return nil,'Import rejected: '..tostring(result)end
 return result
end
function T.Apply(preview,store)
 if store.readonly or store:Character().revision~=preview.revision then return nil,'Destination changed; preview again' end
 store.saved.preImportBackup=ns.Copy(store:Character());store.saved.characters[store.id]=ns.Copy(preview.data)
 store:Character().epoch=store:Character().epoch+1;store:Character().revision=store:Character().revision+1;return true
end

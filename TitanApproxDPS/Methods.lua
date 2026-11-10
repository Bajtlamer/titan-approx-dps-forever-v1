local _,ns=...
ns.Methods={}
function ns.Methods.New(store)
 local m={}
 function m:Define(name,description,id)
  assert(type(name)=='string' and #name>0 and #name<=128,'Method name must have 1-128 bytes')
  local c=assert(store:Character());if not id then c.methodSequence=(c.methodSequence or 0)+1;id='method-'..c.methodSequence end
  if not c.methods[id]then c.methods[id]={}end
  local v=#c.methods[id]+1;c.methods[id][v]={name=name,description=description or ''};return {methodID=id,version=v}
 end
 function m:Select(ref)store:Character().selectedMethod=ns.Copy(ref)end
 function m:Snapshot()return ns.Copy(store:Character().selectedMethod)end
 return m
end

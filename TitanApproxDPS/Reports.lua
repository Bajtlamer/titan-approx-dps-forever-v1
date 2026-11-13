local _,ns=...
local R={};ns.Reports=R
function R.SetHidden(store,profile,hidden)
 local c=store:Character();if not c then return end
 c.reportHidden=c.reportHidden or {};c.reportHidden[profile]=hidden and true or nil;c.revision=c.revision+1
end
function R.Build(store,mode,api,includeHidden,useLifetime)
 api=api or _G
 local c=store:Character();local out={groups={},characterDamage=c and c.totalDamage or 0,mode=mode,preservedDamage=c and c.preservedLifetimeDamage or 0}
 if not c then return out end
 local collected=ns.Stats and ns.Stats.Collect(c)
 local groups={};local parsed={}
 local lifetime={}
 for _,r in pairs(c.rows or {})do for id,part in pairs(ns.WeaponAttribution.Split(r,c,api))do lifetime[id]=(lifetime[id] or 0)+part.damage end end
 for key,r in pairs(useLifetime and c.rows or c.reportRows or c.rows or {})do
  local parts,slots=ns.WeaponAttribution.Split(r,c,api);parsed[key]={parts=parts,slots=slots,row=r}
  for id,p in pairs(parts)do
   local g=groups[id]
   if not g then g={profile=id,name=p.name,slot=p.slot,category=p.category,damage=0,lifetimeDamage=0,seconds=0,timedDamage=0,sessions=0,autoDamage=0,abilityDamage=0,spellMap={},spells={}};groups[id]=g end
   g.lifetimeDamage=lifetime[id] or 0;g.overlap=g.overlap or p.overlap
   if mode=='all' or mode==r.mode then
    g.damage=g.damage+p.damage;g.timedDamage=g.timedDamage+p.timedDamage;g.autoDamage=g.autoDamage+p.autoDamage;g.abilityDamage=g.abilityDamage+p.abilityDamage
    for spell,s in pairs(p.spells)do g.spellMap[spell]=(g.spellMap[spell] or 0)+s.damage end
   end
  end
 end
 for id,g in pairs(groups)do
  -- Include every eligible interval with this weapon equipped, including zero assigned attacks.
  for _,data in pairs(parsed)do local r=data.row
   if mode=='all' or mode==r.mode then
    local slot=g.slot and data.slots[g.slot]
    local eligible=slot and id==('slot:'..slot.slot..':'..slot.variant) or (not g.slot and data.parts[id])
    if eligible then g.seconds=g.seconds+r.seconds;g.sessions=g.sessions+r.sessions end
   end
  end
  if g.sessions>0 and (includeHidden or not(c.reportHidden and c.reportHidden[id]))then
   local sum=0
   for spell,damage in pairs(g.spellMap)do g.spells[#g.spells+1]={spellID=spell,damage=damage,percent=g.damage>0 and 100*damage/g.damage or nil};sum=sum+damage end
   if ns.Categories then g.kind=ns.Categories.Of(g)end
   if collected then g.stats={period=ns.Stats.ForGroup(collected,id,mode,'period'),lifetime=ns.Stats.ForGroup(collected,id,mode,'lifetime')}end
   g.records=c.records and c.records.weapons and c.records.weapons[id] or nil
   g.unattributed=math.max(0,g.damage-sum);g.dps=g.seconds>0 and g.timedDamage/g.seconds or nil
   table.sort(g.spells,function(a,b)if a.damage==b.damage then return a.spellID<b.spellID end;return a.damage>b.damage end)
   out.groups[#out.groups+1]=g
  end
 end
 table.sort(out.groups,function(a,b)if a.damage==b.damage then return a.profile<b.profile end;return a.damage>b.damage end)
 return out
end
function R.WeaponLifetime(store)
 local c=store:Character();local totals={}
 for _,row in pairs(c and c.rows or {})do for id,part in pairs(ns.WeaponAttribution.Split(row,c,_G))do if part.slot then totals[id]=(totals[id] or 0)+part.damage end end end
 return totals
end

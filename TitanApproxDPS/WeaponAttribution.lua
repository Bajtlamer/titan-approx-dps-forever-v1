local _,ns=...
local A={};ns.WeaponAttribution=A
local labels={[16]='Main hand',[17]='Off hand',[18]='Ranged'}
function A.Variant(value)
 local fields={};for part in (value..':'):gmatch('(.-):')do fields[#fields+1]=part end
 local out={fields[1] or '',fields[2] and fields[2]~='' and fields[2] or '0'};local last=2
 for i=3,7 do if fields[i] and fields[i]~='' and fields[i]~='0' then last=i end end
 for i=3,last do out[i]=fields[i]~='' and fields[i] or '0';out[i]=out[i] or '0'end
 local n=tonumber(fields[13]);if n and n>0 and n<=128 then local bonus={};for i=14,13+n do if not tonumber(fields[i])then return value end;bonus[#bonus+1]=fields[i]end;table.sort(bonus);out[#out+1]='bonus='..table.concat(bonus,',')end
 return table.concat(out,':')
end
function A.Slots(profile,name,api)
 local slots={}
 for slot,value in profile:gmatch('(%d+):([^;]+)')do
  slot=tonumber(slot)
  if labels[slot] then
   local id=tonumber(value:match('^(%d+)'));if id and id<=0 then id=nil end
   local s={slot=slot,id=id,variant=id and A.Variant(value) or value,empty=value=='empty',name=id and ('Item '..id) or 'Unknown'};slots[slot]=s
   if id and type(name)=='string' then
    for link,item in name:gmatch('(|c[^|]+|Hitem:([^|]+)|h.-|h|r)')do if tonumber(item:match('^(%d+)'))==id then s.name=link;s.savedName=true;break end end
   end
   local get=api.C_Item and api.C_Item.GetItemInfo
   if id and not s.savedName and type(get)=='function' then
    local ok,title,link,quality=pcall(get,'item:'..value)
    if ok and ns.Capabilities.IsPublic(link,api) and type(link)=='string'then s.name=link
    elseif ok and ns.Capabilities.IsPublic(title,api) and type(title)=='string'then s.name=title
    elseif s.name=='Item '..id and api.C_Item.RequestLoadItemDataByID then A.requested=A.requested or {};if not A.requested[id]then A.requested[id]=true;pcall(api.C_Item.RequestLoadItemDataByID,id)end end
   end
   local info=api.C_Item and api.C_Item.GetItemInfoInstant
   if id and type(info)=='function' then
    local ok,_,_,_,loc,_,class=pcall(info,id)
    if ok and ns.Capabilities.IsPublic(class,api) and ns.Capabilities.IsPublic(loc,api) then s.weapon=class==2;s.nonweapon=type(class)=='number' and class~=2;s.equipLoc=type(loc)=='string' and loc or nil end
   end
  end
 end
 return slots
end
local function autoKind(id,api)
 if id==6603 then return 'melee' end
 if id==75 then return 'ranged' end -- Auto Shot, confirmed by the local Forever Hunter reference.
 local fn=api.C_Spell and api.C_Spell.IsRangedAutoAttackSpell
 if type(fn)=='function' then local ok,v=pcall(fn,id);if ok and ns.Capabilities.IsPublic(v,api) and v==true then return 'ranged' end end
end
function A.Split(row,character,api)
 api=api or _G
 local slots=A.Slots(row.profile,character.profiles[row.profile],api);local parts={};local sum=0
 for _,spell in pairs(row.spells)do sum=sum+spell.damage end
 local overlap=sum>row.damage
 local function target(id,origin)
  if overlap then return nil,'unclassified' end
  if origin=='summon' then return nil,'summon' end
  local rule=origin=='player' and ns.SpellRules.Lookup(character.class,id)
  if rule then
   if not rule.slot then return nil,rule.kind end
   local item=slots[rule.slot]
   if item and item.id and not item.nonweapon then return item end
   return nil,'missing_weapon'
  end
  local kind=autoKind(id,api)
  if kind=='ranged' then
   local ranged=slots[18]
   -- Fixed Auto Shot identity retains legacy attribution; other predicate-only IDs
   -- need actor evidence, especially when adding caster/wand coverage.
   if ranged and ranged.id and not ranged.nonweapon and (id==75 or origin=='player') then return ranged end
   return nil,'unclassified'
  end
  if kind=='melee' then
   local main,off=slots[16],slots[17]
   -- Missing historical actor evidence can include pet swings. Never assign those to a weapon.
   if origin=='player' and character.class and character.class~='DRUID' and main and main.id and main.weapon~=false and off and (off.empty or off.nonweapon) then return main end
   return nil,'ambiguous_melee'
  end
  return nil,'unclassified'
 end
 local names={unclassified='Your spells: weapon not identified',ambiguous_melee='Your melee: hand or source not recorded',summon='Your pet / summon: separate damage',spell='Your abilities: no specific weapon',form='Your form abilities: separate damage',shield='Your shield abilities: separate damage',missing_weapon='Your abilities: required weapon not recorded'}
 local function add(id,damage,timed,origin)
  if damage==0 then return end -- Empty origin buckets are not attacks or report groups.
  local item,category=target(id,origin);local key=item and ('slot:'..item.slot..':'..item.variant) or category
  local p=parts[key]
  if not p then p={profile=key,slot=item and item.slot,category=category,name=item and (labels[item.slot]..': '..item.name) or names[category],damage=0,timedDamage=0,autoDamage=0,abilityDamage=0,spells={},overlap=overlap};parts[key]=p end
  p.damage=p.damage+damage;p.timedDamage=p.timedDamage+timed
  if autoKind(id,api)then p.autoDamage=p.autoDamage+damage else p.abilityDamage=p.abilityDamage+damage end
  if id>0 then local s=p.spells[id] or {damage=0};p.spells[id]=s;s.damage=s.damage+damage end
 end
 if overlap then add(0,row.damage,row.timedDamage or 0,'unknown')
 else
  for id,spell in pairs(row.spells)do
   id=tonumber(id)
   if spell.origins then
    for origin,s in pairs(spell.origins)do add(id,s.damage,s.timedDamage or 0,origin)end
   else add(id,spell.damage,spell.timedDamage or 0,'unknown')end
  end
  local missing=row.damage-sum;if missing>0 then add(0,missing,math.max(0,(row.timedDamage or 0)-(function()local n=0;for _,s in pairs(row.spells)do n=n+(s.timedDamage or 0)end;return n end)()),'unknown')end
 end
 return parts,slots
end

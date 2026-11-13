local _,ns=...
ns.version='0.1.16-alpha'
function ns.Copy(t)
 if type(t)~='table' then return t end
 local r={};for k,v in pairs(t)do r[k]=ns.Copy(v)end;return r
end
function ns.Number(v) return type(v)=='number' and v==v and v>=0 and v<math.huge end
function ns.DamageNumber(v)
 if not ns.Number(v) then return 'Unavailable' end
 local digits=string.format('%.0f',v):reverse()
 digits=digits:gsub('(%d%d%d)','%1.')
 digits=digits:reverse():gsub('^%.','')
 return digits
end
function ns.SpellName(id)
 local ok,name=pcall(function()return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)end)
 return ok and ns.Capabilities.IsPublic(name) and type(name)=='string' and name or ('Spell '..id)
end
function ns.Available(v)return {state='available',value=v}end
function ns.Missing(reason)return {state='unavailable',reason=reason}end
function ns.ValidOrigins(origins,damage,timed)
 if origins==nil then return true end
 if type(origins)~='table' then return false end
 local total,seconds=0,0
 for key,part in pairs(origins)do
  if not ({player=true,summon=true,unknown=true})[key] or type(part)~='table' or not ns.Number(part.damage) or not ns.Number(part.timedDamage) or part.timedDamage>part.damage then return false end
  total=total+part.damage;seconds=seconds+part.timedDamage
 end
 return total==damage and seconds==(timed or 0)
end

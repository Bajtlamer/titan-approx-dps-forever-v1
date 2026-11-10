local _,ns=...
local C={};ns.Capabilities=C
function C.IsPublic(value,api)
 local check=(api or _G).issecretvalue
 if not check then return true end
 local ok,secret=pcall(check,value);return ok and not secret
end
function C.Probe(api)
 local m=api.C_DamageMeter;local e=api.Enum
 return {damage=type(m)=='table' and type(m.GetCombatSessionFromID)=='function' and type(e)=='table' and type(e.DamageMeterType)=='table' and type(e.DamageMeterType.DamageDone)=='number' or false,
 spells=type(m)=='table' and type(m.GetCombatSessionSourceFromID)=='function' or false,
 crits=false,misses=false,weaponHits=false,petSplit=false,recipientClassification=false}
end

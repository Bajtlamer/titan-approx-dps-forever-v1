local _,ns=...
local M={};M.__index=M;ns.Meter=M
function M.New(api,capabilities)return setmetatable({api=api,capabilities=capabilities},M)end
function M:ReadSession(id)
 local a=self.api
 if not self.capabilities.damage then return nil,'Native meter API or damage enum unavailable' end
 if a.InCombatLockdown and a.InCombatLockdown() then return nil,'Combat still active' end
 local public=function(v)return ns.Capabilities.IsPublic(v,a)end
 local function number(v)return public(v) and ns.Number(v)end
 local ok,result=pcall(function()
  local kind=a.Enum.DamageMeterType.DamageDone
  local session=a.C_DamageMeter.GetCombatSessionFromID(id,kind)
  if not public(session) or type(session)~='table' or not public(session.combatSources) or type(session.combatSources)~='table' then error('Session restricted or absent')end
  local player
  for _,s in ipairs(session.combatSources)do
   if public(s) and type(s)=='table' and public(s.isLocalPlayer) and s.isLocalPlayer==true then player=s;break end
  end
  if not player or not number(player.totalAmount) then error('Local player total unavailable')end
  local r={nativeRef=id,completed=true,totalDamage=ns.Available(player.totalAmount),duration=number(session.durationSeconds) and ns.Available(session.durationSeconds) or ns.Missing('Duration unavailable'),nativeDPS=number(player.amountPerSecond) and ns.Available(player.amountPerSecond) or ns.Missing('DPS unavailable'),spells={},combatMode='unknown',combatModeReason='Complete outgoing recipient classification is not exposed by this adapter',ownerPetMode='unknown',coverage={complete=true},crits=ns.Missing('Native summaries expose no crit counts'),misses=ns.Missing('Native summaries expose no attack outcomes')}
  r.spellState='unavailable'
  if self.capabilities.spells and public(player.sourceGUID) and type(player.sourceGUID)=='string' then
   local sourceOK,source=pcall(a.C_DamageMeter.GetCombatSessionSourceFromID,id,kind,player.sourceGUID,nil)
   if sourceOK and public(source) and type(source)=='table' and public(source.combatSpells) and type(source.combatSpells)=='table' then
    r.spellState='available'
    for _,s in ipairs(source.combatSpells)do
     if public(s) and type(s)=='table' and number(s.spellID) and s.spellID>0 and number(s.totalAmount) then r.spells[#r.spells+1]={spellID=s.spellID,damage=ns.Available(s.totalAmount)} else r.spellState='partial' end
    end
   end
  end
  return r
 end)
 if not ok then return nil,'Session data unavailable or restricted; waiting for readable snapshot' end
 return result
end

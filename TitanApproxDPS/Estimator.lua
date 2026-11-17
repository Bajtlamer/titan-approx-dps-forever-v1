local _,ns=...
-- Calibrated estimate of what a different weapon would change, from the player's own
-- recorded fights. It is an estimate, not a measurement, and only models what the data
-- can support:
--  * melee and ranged auto-attacks: damage per second follows (weapon DPS + attack power / 14)
--    times an efficiency factor k calibrated from your fights (hits, misses, crits, uptime);
--  * spells: a straight line of the spell group's DPS on spell power, fitted to your fights.
-- Abilities, procs and enchants are not modelled. Nothing is produced below 20 fights
-- that carry a build snapshot, and degenerate data yields a reason instead of a number.
local E={};ns.Estimator=E
E.MinFights=20

-- Classic attack power per point of a primary stat. A class or kind not listed gets none.
local AP_PER_STAT={
 WARRIOR={melee={strength=2}},PALADIN={melee={strength=2}},SHAMAN={melee={strength=2}},
 ROGUE={melee={strength=1,agility=1}},HUNTER={melee={strength=1,agility=1},ranged={agility=2}},
}
local STAT_KEYS={strength='ITEM_MOD_STRENGTH_SHORT',agility='ITEM_MOD_AGILITY_SHORT'}
local SPELL_KEYS={'ITEM_MOD_SPELL_POWER_SHORT','ITEM_MOD_SPELL_DAMAGE_DONE_SHORT'}

local function stat(stats,key)local v=stats and stats[key];return ns.Number(v) and v or 0 end

-- Extra attack power the new item gives compared with the old one, for melee or ranged.
function E.PowerDelta(newStats,oldStats,class,kind)
 local direct=kind=='ranged' and 'ITEM_MOD_RANGED_ATTACK_POWER_SHORT' or 'ITEM_MOD_ATTACK_POWER_SHORT'
 local delta=stat(newStats,direct)-stat(oldStats,direct)
 local rates=AP_PER_STAT[class] and AP_PER_STAT[class][kind]
 if rates then
  for name,rate in pairs(rates)do delta=delta+rate*(stat(newStats,STAT_KEYS[name])-stat(oldStats,STAT_KEYS[name]))end
 end
 return delta
end

local function autoConfidence(summary)
 if summary.n<30 then return 'low' end
 if summary.spread and summary.spread<0.10 then return 'high' end
 return 'medium'
end

-- Calibrates the efficiency factor k from fights of the equipped weapon: auto DPS divided by
-- (weapon DPS + attack power / 14). Returns summary,groupTypical,usable or nil,reason.
local function calibrate(samples,kind,wOld)
 local k=ns.Stats.New();local total,weight=0,0;local usable=0
 for _,s in ipairs(samples)do
  local b=s.build
  local ap=b and (kind=='ranged' and b.rangedAttackPower or b.attackPower)
  if ap and s.autoDps and s.autoDps>0 and s.seconds and s.seconds>0 then
   ns.Stats.Add(k,s.autoDps/(wOld+ap/14),s.seconds)
   total=total+s.dps*s.seconds;weight=weight+s.seconds;usable=usable+1
  end
 end
 if usable<E.MinFights then
  return nil,string.format('A calibrated estimate needs %d fights with a build snapshot (%d of %d fights have one).',E.MinFights,usable,#samples)
 end
 local summary=ns.Stats.Summary(k)
 local groupTypical=total/weight
 if not summary.typical or summary.typical<=0 or groupTypical<=0 then return nil,'No usable damage was recorded for this weapon.' end
 return summary,groupTypical,usable
end

local function autoResult(summary,groupTypical,usable,delta)
 return {kind='auto',k=summary.typical,deltaDps=delta,groupTypical=groupTypical,percent=100*delta/groupTypical,
  fights=usable,confidence=autoConfidence(summary),spread=summary.spread}
end

-- samples: fights of the equipped weapon's group: {dps,autoDps,seconds,build}.
function E.AutoAttack(samples,kind,class,newStats,oldStats)
 local wNew=newStats and ns.Compare.WeaponDps(newStats)
 local wOld=oldStats and ns.Compare.WeaponDps(oldStats)
 if not (wNew and wOld and wOld>0) then return nil,'Item stats do not include weapon DPS for one of the items.' end
 local summary,groupTypical,usable=calibrate(samples,kind,wOld)
 if not summary then return nil,groupTypical end
 local delta=summary.typical*((wNew-wOld)+E.PowerDelta(newStats,oldStats,class,kind)/14)
 return autoResult(summary,groupTypical,usable,delta)
end

-- Attack power change from gear that is not a weapon: the equipped weapon stays, only
-- deltaPower (attack power) changes. weaponStats are the equipped weapon's item stats.
function E.AutoPower(samples,kind,weaponStats,deltaPower)
 local wOld=weaponStats and ns.Compare.WeaponDps(weaponStats)
 if not (wOld and wOld>0) then return nil,'Item stats do not include weapon DPS for the equipped weapon.' end
 local summary,groupTypical,usable=calibrate(samples,kind,wOld)
 if not summary then return nil,groupTypical end
 return autoResult(summary,groupTypical,usable,summary.typical*deltaPower/14)
end

local function spellPower(stats)
 for _,key in ipairs(SPELL_KEYS)do if ns.Number(stats[key])then return stats[key]end end
 return 0
end

function E.Spell(samples,newStats,oldStats)
 if not newStats or not oldStats then return nil,'Item stats are unavailable.' end
 local d=spellPower(newStats)-spellPower(oldStats)
 if d==0 then return nil,'The two weapons give no spell power difference.' end
 local xs,ys={},{}
 for _,s in ipairs(samples)do
  if s.build and s.build.spellPower and s.dps and s.dps>0 then xs[#xs+1]=s.build.spellPower;ys[#ys+1]=s.dps end
 end
 local n=#xs
 if n<E.MinFights then
  return nil,string.format('A calibrated estimate needs %d fights with a build snapshot (%d so far).',E.MinFights,n)
 end
 local mx,my,lo,hi=0,0,xs[1],xs[1]
 for i=1,n do mx=mx+xs[i];my=my+ys[i];if xs[i]<lo then lo=xs[i]end;if xs[i]>hi then hi=xs[i]end end
 mx=mx/n;my=my/n
 if hi-lo<math.max(5,0.03*mx) then return nil,'Spell power barely changed across your fights, so its effect cannot be measured.' end
 local sxx,sxy,syy=0,0,0
 for i=1,n do local dx,dy=xs[i]-mx,ys[i]-my;sxx=sxx+dx*dx;sxy=sxy+dx*dy;syy=syy+dy*dy end
 local slope=sxy/sxx
 if slope<=0 then return nil,'Your data shows no positive relation between spell power and damage.' end
 local r2=syy>0 and (sxy*sxy)/(sxx*syy) or 0
 local confidence=(n>=30 and r2>=0.7) and 'high' or (r2>=0.3 and 'medium' or 'low')
 local delta=slope*d
 return {kind='spell',slope=slope,deltaDps=delta,meanDps=my,percent=100*delta/my,fights=n,r2=r2,confidence=confidence}
end

-- Everything the item tooltip needs. group is the equipped weapon's report group.
function E.ForItem(c,group,newStats,oldStats)
 local out={}
 if group and (group.kind=='melee' or group.kind=='ranged') then
  out.auto,out.autoReason=E.AutoAttack(ns.Stats.FightSamples(c,group.profile),group.kind,c.class,newStats,oldStats)
 end
 out.spell,out.spellReason=E.Spell(ns.Stats.FightSamples(c,'spell'),newStats,oldStats)
 return out
end

-- Gear that is not a weapon. derived: ItemEffects.Derive result. weapons: {melee=,ranged=}
-- each {group=report group,stats=item stats of the equipped weapon} or nil.
function E.ForGear(c,derived,weapons,newStats,oldStats)
 local out={autos={},autoReasons={}}
 for _,kind in ipairs({'melee','ranged'})do
  local delta=kind=='ranged' and derived.rangedAP or derived.meleeAP
  if delta and delta~=0 then
   local w=weapons and weapons[kind]
   if w and w.group and w.group.kind==kind and w.stats then
    local a,reason=E.AutoPower(ns.Stats.FightSamples(c,w.group.profile),kind,w.stats,delta)
    if a then a.kind=kind;out.autos[#out.autos+1]=a else out.autoReasons[#out.autoReasons+1]=reason end
   else
    out.autoReasons[#out.autoReasons+1]='No fight data for the equipped '..kind..' weapon yet, so '..kind..' attack power cannot be turned into damage.'
   end
  end
 end
 if derived.spellPower and derived.spellPower~=0 then
  out.spell,out.spellReason=E.Spell(ns.Stats.FightSamples(c,'spell'),newStats,oldStats)
 end
 return out
end

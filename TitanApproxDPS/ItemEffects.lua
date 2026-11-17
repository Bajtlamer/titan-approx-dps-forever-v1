local _,ns=...
-- What a change of gear does to the character's derived values, by class. Only
-- conversions that are written down in ref-item-stat-effects.md are applied; every other
-- stat is listed as not modelled instead of being guessed. Crit conversion is known for
-- level 60 only. Pure functions, no events, no combat-log data.
local F={};ns.ItemEffects=F
F.CritLevel=60
local FREE_POINTS,HP_PER=20,10
local MANA_PER=15

-- meleeStr/meleeAgi/rangedAgi: attack power per point. catAgi: melee AP per Agility in Cat Form only.
-- agiPerCrit/intPerCrit: points of the stat per +1 crit point at level 60. mana: has a mana pool.
local RULES={
 WARRIOR={meleeStr=2,rangedAgi=2,agiPerCrit=20},
 PALADIN={meleeStr=2,agiPerCrit=19.8,intPerCrit=59.9,mana=true},
 HUNTER={meleeStr=1,meleeAgi=1,rangedAgi=2,agiPerCrit=52.9,intPerCrit=60.6,mana=true},
 ROGUE={meleeStr=1,meleeAgi=1,rangedAgi=2,agiPerCrit=29},
 SHAMAN={meleeStr=2,agiPerCrit=19.7,intPerCrit=59.2,mana=true},
 DRUID={meleeStr=2,catAgi=1,agiPerCrit=20,intPerCrit=59.9,mana=true},
 MAGE={meleeStr=1,agiPerCrit=19.5,intPerCrit=59.5,mana=true},
 PRIEST={meleeStr=1,agiPerCrit=20,intPerCrit=59.5,mana=true},
 WARLOCK={meleeStr=1,agiPerCrit=20,intPerCrit=60.6,mana=true},
}
local STR,AGI,STA,INT='ITEM_MOD_STRENGTH_SHORT','ITEM_MOD_AGILITY_SHORT','ITEM_MOD_STAMINA_SHORT','ITEM_MOD_INTELLECT_SHORT'
local MELEE_AP,RANGED_AP='ITEM_MOD_ATTACK_POWER_SHORT','ITEM_MOD_RANGED_ATTACK_POWER_SHORT'
local SPELL_KEYS={'ITEM_MOD_SPELL_POWER_SHORT','ITEM_MOD_SPELL_DAMAGE_DONE_SHORT'}
local HANDLED={[STR]=true,[AGI]=true,[STA]=true,[INT]=true,[MELEE_AP]=true,[RANGED_AP]=true,
 ITEM_MOD_SPELL_POWER_SHORT=true,ITEM_MOD_SPELL_DAMAGE_DONE_SHORT=true}

local function stat(stats,key)local v=stats[key];return ns.Number(v) and v or 0 end
local function spellPower(stats)
 for _,key in ipairs(SPELL_KEYS)do if ns.Number(stats[key])then return stats[key]end end
 return 0
end
local function pool(total,delta,free,per)
 local function value(t)t=math.max(t,0);return math.min(t,free)+per*math.max(t-free,0)end
 return value(total+delta)-value(total)
end

-- newStats/oldStats: GetItemStats tables. ctx: {level,stamina,intellect,form} (any may be nil).
-- Returns nil for an unknown class or unreadable stats. A field is nil when the item does not
-- change it or when the data to compute it is missing, never a guessed zero.
function F.Derive(class,newStats,oldStats,ctx)
 local rule=RULES[class]
 if not rule or type(newStats)~='table' or type(oldStats)~='table' then return nil end
 ctx=ctx or {}
 local function delta(key)return stat(newStats,key)-stat(oldStats,key)end
 local out={notes={},unmodelled={}}
 local function set(key,v)if v~=nil and v~=0 then out[key]=v end end
 local dStr,dAgi,dSta,dInt=delta(STR),delta(AGI),delta(STA),delta(INT)
 local agiMelee=rule.meleeAgi
 if rule.catAgi then
  if ctx.form=='cat' then agiMelee=rule.catAgi
  elseif dAgi~=0 then out.notes[#out.notes+1]='Agility gives melee attack power only in Cat Form'..(ctx.form and ' (current form is not Cat Form).' or ' (current form unknown).')end
 end
 set('meleeAP',delta(MELEE_AP)+(rule.meleeStr or 0)*dStr+(agiMelee or 0)*dAgi)
 set('rangedAP',delta(RANGED_AP)+(rule.rangedAgi or 0)*dAgi)
 set('spellPower',spellPower(newStats)-spellPower(oldStats))
 if dSta~=0 and ns.Number(ctx.stamina)then set('hp',pool(ctx.stamina,dSta,FREE_POINTS,HP_PER))end
 if dInt~=0 and rule.mana and ns.Number(ctx.intellect)then set('mana',pool(ctx.intellect,dInt,FREE_POINTS,MANA_PER))end
 local critChange=(dAgi~=0 and rule.agiPerCrit)or(dInt~=0 and rule.intPerCrit)
 if critChange then
  if ctx.level==F.CritLevel then
   if dAgi~=0 then set('physCrit',dAgi/rule.agiPerCrit)end
   if dInt~=0 and rule.intPerCrit then set('spellCrit',dInt/rule.intPerCrit)end
  else
   out.notes[#out.notes+1]='Crit conversion is known for level 60 only.'
  end
 end
 if dInt~=0 then out.notes[#out.notes+1]='Intellect adds mana and spell crit, not spell damage.'end
 for key,value in pairs(newStats)do
  if type(key)=='string' and key:find('^ITEM_MOD_') and not key:find('DAMAGE_PER_SECOND') and not HANDLED[key] and delta(key)~=0 then out.unmodelled[#out.unmodelled+1]=key end
 end
 for key in pairs(oldStats)do
  if type(key)=='string' and key:find('^ITEM_MOD_') and not key:find('DAMAGE_PER_SECOND') and not HANDLED[key] and newStats[key]==nil and delta(key)~=0 then out.unmodelled[#out.unmodelled+1]=key end
 end
 table.sort(out.unmodelled)
 return out
end

local function read(api,fn,...)
 if type(fn)~='function' then return nil end
 local ok,a,b=pcall(fn,...)
 if ok and ns.Capabilities.IsPublic(a,api) and ns.Capabilities.IsPublic(b,api) then return a,b end
end
local function finite(v)return ns.Number(v) and v>=0 end

-- Reads the character values Derive needs. Unreadable values stay nil.
function F.Context(api,class)
 api=api or _G
 local ctx={}
 local level=read(api,api.UnitLevel,'player');if finite(level)then ctx.level=level end
 local _,stamina=read(api,api.UnitStat,'player',3);if finite(stamina)then ctx.stamina=stamina end
 local _,intellect=read(api,api.UnitStat,'player',4);if finite(intellect)then ctx.intellect=intellect end
 if class=='DRUID' then
  local form=read(api,api.GetShapeshiftFormID)
  if type(form)=='number' then ctx.form=form==1 and 'cat' or 'other' end
 end
 return ctx
end

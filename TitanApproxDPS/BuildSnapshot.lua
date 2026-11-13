local _,ns=...
-- Snapshot of the character's offensive stats, taken when combat starts and stored on
-- every fight of that combat. It only reads public values through guarded calls, never
-- registers an event, and leaves any value it cannot read out: a missing field is never
-- stored as zero. A readable zero is a real value and is kept.
local B={};ns.BuildSnapshot=B

local numericKeys={level=true,strength=true,agility=true,stamina=true,intellect=true,spirit=true,attackPower=true,rangedAttackPower=true,
 spellPower=true,meleeCrit=true,rangedCrit=true,spellCrit=true,mainHandSpeed=true,offHandSpeed=true,rangedSpeed=true}
local stringKeys={bucket=true,source=true}
local SCHOOLS={2,3,4,5,6,7} -- holy, fire, nature, frost, shadow, arcane

local function finite(v)return type(v)=='number' and v==v and v>-math.huge and v<math.huge end
local function round(v,places)local m=10^places;return math.floor(v*m+.5)/m end

local function pack(...)return select('#',...),{...}end
-- Calls fn and returns its results that are public numbers; unreadable ones become nil.
local function call(api,fn,...)
 if type(fn)~='function' then return end
 local count,packed=pack(pcall(fn,...))
 if not packed[1] then return end
 local out={}
 for i=2,count do
  local v=packed[i]
  if ns.Capabilities.IsPublic(v,api) and finite(v) then out[i-1]=v end
 end
 return out
end
local function one(api,fn,...)local r=call(api,fn,...);return r and r[1] end

function B.Bucket(build)
 local ap=math.max(build.attackPower or -1,build.rangedAttackPower or -1)
 local sp=build.spellPower
 if ap<0 and sp==nil then return 'unknown' end
 return string.format('ap%d-sp%d',math.floor(math.max(ap,0)/100)*100,math.floor((sp or 0)/50)*50)
end

function B.Take(api,source)
 api=api or _G
 local s={}
 local function put(key,v,places)
  if v~=nil and v>=0 then s[key]=places and round(v,places) or math.floor(v+.5)end
 end
 put('level',one(api,api.UnitLevel,'player'))
 for i,key in ipairs({'strength','agility','stamina','intellect','spirit'})do
  local r=call(api,api.UnitStat,'player',i)
  put(key,r and r[2])
 end
 local function power(fn)
  local r=call(api,fn,'player')
  if r and r[1] and r[2] and r[3] then return r[1]+r[2]+r[3] end
 end
 put('attackPower',power(api.UnitAttackPower))
 put('rangedAttackPower',power(api.UnitRangedAttackPower))
 local best
 for _,school in ipairs(SCHOOLS)do
  local v=one(api,api.GetSpellBonusDamage,school);if v and (not best or v>best)then best=v end
 end
 put('spellPower',best)
 put('meleeCrit',one(api,api.GetCritChance),1)
 put('rangedCrit',one(api,api.GetRangedCritChance),1)
 local crit
 for _,school in ipairs(SCHOOLS)do
  local v=one(api,api.GetSpellCritChance,school);if v and (not crit or v>crit)then crit=v end
 end
 put('spellCrit',crit,1)
 local speeds=call(api,api.UnitAttackSpeed,'player')
 if speeds then put('mainHandSpeed',speeds[1],2);put('offHandSpeed',speeds[2],2)end
 put('rangedSpeed',one(api,api.UnitRangedDamage,'player'),2)
 if next(s)==nil then return nil end
 s.bucket=B.Bucket(s);s.source=source
 return s
end

function B.Validate(build)
 if type(build)~='table' then return false end
 for key,value in pairs(build)do
  if numericKeys[key] then if not ns.Number(value)then return false end
  elseif stringKeys[key] then if type(value)~='string' or #value>32 then return false end
  else return false end
 end
 return true
end

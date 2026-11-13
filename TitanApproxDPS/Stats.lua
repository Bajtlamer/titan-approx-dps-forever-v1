local _,ns=...
-- Running statistics per weapon group and combat mode. Samples are one DPS value per
-- fight (damage assigned to the group divided by fight seconds, fights of at least
-- ten seconds). Samples are derived from stored receipts, so native session
-- revisions replace their sample instead of adding another one. Receipts retired
-- from the retained window are folded into c.baseStats, a weighted summary.
local S={};ns.Stats=S
local MIN_SECONDS=10
local RECENT=20
local MODES={pve=true,pvp=true,mixed=true,unknown=true}

function S.New()return {n=0,mean=0,s=0,weight=0}end
-- Weighted Welford update, weight is fight seconds.
function S.Add(stat,dps,seconds)
 stat.n=stat.n+1;stat.weight=stat.weight+seconds
 local delta=dps-stat.mean
 stat.mean=stat.mean+delta*(seconds/stat.weight)
 stat.s=stat.s+seconds*delta*(dps-stat.mean)
end
function S.Merge(a,b)
 local out=S.New();out.n=a.n+b.n;out.weight=a.weight+b.weight
 if out.weight>0 then
  local delta=b.mean-a.mean
  out.mean=a.mean+delta*(b.weight/out.weight)
  out.s=a.s+b.s+delta*delta*a.weight*b.weight/out.weight
 end
 return out
end
local function median(values)
 if not values or #values==0 then return nil end
 local copy={};for i,v in ipairs(values)do copy[i]=v end;table.sort(copy)
 local n=#copy
 return n%2==1 and copy[(n+1)/2] or (copy[n/2]+copy[n/2+1])/2
end
-- confidence: none (no fights), low (<10), medium (<30 or noisy), high (30+ and tight)
function S.Summary(stat,recent)
 local out={n=stat.n,confidence='none'}
 if stat.n>0 then
  out.typical=stat.mean
  if stat.n>=2 and stat.weight>0 and stat.mean>0 then out.spread=math.sqrt((stat.s/stat.weight)/stat.n)/stat.mean end
  out.confidence=stat.n<10 and 'low' or (stat.n<30 and 'medium') or (out.spread and out.spread<0.10 and 'high') or 'medium'
 end
 out.recentMedian=median(recent);out.recentCount=recent and #recent or 0
 return out
end

local caches=setmetatable({},{__mode='k'})
-- One-fight samples for a receipt, cached by a signature of everything that matters.
local function samples(c,receipt)
 local cache=caches[c];if not cache then cache={};caches[c]=cache end
 local seconds=receipt.seconds
 local sig=table.concat({receipt.damage,seconds or 'x',#receipt.spells,c.class or '',c.profiles[receipt.profile] or '',receipt.profile},'/')
 local hit=cache[receipt.receiptID]
 if hit and hit.sig==sig then return hit.list end
 local list={}
 if ns.Number(seconds) and seconds>=MIN_SECONDS and ns.Storage.RowFor and ns.WeaponAttribution then
  local ok,parts=pcall(ns.WeaponAttribution.Split,ns.Storage.RowFor(receipt),c,_G)
  if ok then
   for key,p in pairs(parts)do
    if p.damage>0 then list[#list+1]={key=key,kind=ns.Categories.Of(p),dps=p.damage/seconds,autoDps=(p.autoDamage or 0)/seconds,seconds=seconds}end
   end
  end
 end
 cache[receipt.receiptID]={sig=sig,list=list}
 return list
end

-- Fold a receipt that leaves the retained window into the permanent summary.
function S.Retire(c,receipt)
 c.baseStats=c.baseStats or {}
 for _,sample in ipairs(samples(c,receipt))do
  local byMode=c.baseStats[sample.key] or {};c.baseStats[sample.key]=byMode
  local stat=byMode[receipt.mode] or S.New();byMode[receipt.mode]=stat
  S.Add(stat,sample.dps,sample.seconds)
 end
end

function S.ValidateBase(base)
 if base==nil then return true end
 if type(base)~='table' then return false end
 for key,byMode in pairs(base)do
  if type(key)~='string' or type(byMode)~='table' then return false end
  for mode,stat in pairs(byMode)do
   if not MODES[mode] or type(stat)~='table' then return false end
   for _,field in ipairs({'n','mean','s','weight'})do if not ns.Number(stat[field])then return false end end
   if stat.n%1~=0 then return false end
  end
 end
 return true
end

-- Build per-group, per-mode statistics from the permanent summary plus retained receipts.
function S.Collect(c)
 local generation=c.reportGeneration or 0
 local out={}
 local function slot(key,mode)
  local entry=out[key];if not entry then entry={modes={}};out[key]=entry end
  local m=entry.modes[mode];if not m then m={lifetime=S.New(),period=S.New(),recent={}};entry.modes[mode]=m end
  return m
 end
 for key,byMode in pairs(c.baseStats or {})do
  for mode,stat in pairs(byMode)do
   local m=slot(key,mode);m.lifetime=S.Merge(m.lifetime,stat)
   if generation==0 then m.period=S.Merge(m.period,stat)end
  end
 end
 for index,id in ipairs(c.order or {})do
  local receipt=c.receipts[id]
  if receipt then
   local inPeriod=generation==0 or (receipt.reportGeneration or 0)==generation
   for _,sample in ipairs(samples(c,receipt))do
    local m=slot(sample.key,receipt.mode)
    S.Add(m.lifetime,sample.dps,sample.seconds)
    if inPeriod then S.Add(m.period,sample.dps,sample.seconds)end
    m.recent[#m.recent+1]={i=index,dps=sample.dps,period=inPeriod}
   end
  end
 end
 return out
end

-- scope is 'lifetime' (never reset) or 'period' (current report period).
function S.ForGroup(collected,key,mode,scope)
 local entry=collected and collected[key]
 local merged=S.New();local recent={}
 if entry then
  for m,data in pairs(entry.modes)do
   if mode=='all' or mode==m then
    merged=S.Merge(merged,data[scope])
    for _,r in ipairs(data.recent)do if scope=='lifetime' or r.period then recent[#recent+1]=r end end
   end
  end
 end
 table.sort(recent,function(a,b)return a.i<b.i end)
 local values={};for i=math.max(1,#recent-RECENT+1),#recent do values[#values+1]=recent[i].dps end
 return S.Summary(merged,values)
end

-- One entry per retained fight of a group, with the build snapshot of that fight, for the estimator.
function S.FightSamples(c,key,mode)
 local out={}
 for index,id in ipairs(c.order or {})do
  local receipt=c.receipts[id]
  if receipt and (not mode or mode=='all' or receipt.mode==mode)then
   for _,sample in ipairs(samples(c,receipt))do
    if sample.key==key then out[#out+1]={index=index,dps=sample.dps,autoDps=sample.autoDps,seconds=sample.seconds,build=receipt.build,mode=receipt.mode}end
   end
  end
 end
 return out
end

local _,ns=...
-- Pure view model for the results window. It turns stored statistics and a query
-- (tab, filters, search text, sort) into columns and rows. It contains all filtering,
-- searching and sorting so the frame code only renders. There is no paging: every
-- list returns all of its rows and the window scrolls them.
local VM={};ns.ViewModel=VM

VM.Tabs={'Overview','Weapons','Spells','Compare','History','Data'}
VM.Scopes={'all','pve','pvp','mixed','unknown'}
VM.CategoryChoices={'all','melee','ranged','spell','pet','other'}
VM.Periods={'period','lifetime'}
VM.ScopeLabels={all='All fights',pve='PvE',pvp='PvP',mixed='Mixed PvE/PvP',unknown='Combat type not verified'}
VM.PeriodLabels={period='Report period',lifetime='All periods'}
function VM.CategoryLabel(key)return key=='all' and 'All categories' or ns.Categories.Label(key)end

function VM.NewQuery()
 return {tab='Overview',scope='all',category='all',period='period',search='',sortKey=nil,sortDesc=true,showHidden=false,
  selected=nil,compareA=nil,compareB=nil}
end

local function plain(text)return (tostring(text or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|H.-|h(.-)|h','%1'))end
local function whole(v)return v and ns.DamageNumber(v) or 'Unavailable'end
local function one(v)return v and string.format('%.1f',v) or 'Unavailable'end
-- A cell: text, color kind (a Style color name) and a value used for sorting.
local function cell(text,kind,sort)return {text=text,kind=kind,sort=sort}end
local function unavailable()return cell('Unavailable','unavailable',nil)end

local function matches(query,...)
 local needle=(query.search or ''):lower():gsub('^%s+',''):gsub('%s+$','')
 if needle=='' then return true end
 for _,text in ipairs({...})do if plain(text):lower():find(needle,1,true)then return true end end
 return false
end

local function sortRows(rows,query,default,columns)
 local key=query.sortKey or default
 local index
 for i,col in ipairs(columns)do if col.key==key then index=i end end
 if not index then return nil end
 local desc=query.sortDesc
 table.sort(rows,function(a,b)
  local x,y=a.cells[index].sort,b.cells[index].sort
  if x==nil and y~=nil then return false end
  if y==nil and x~=nil then return true end
  if x~=y and x~=nil then if desc then return x>y end;return x<y end
  return a.order<b.order
 end)
 return key
end

local function emptyMessage(query,what)
 local needle=(query.search or ''):gsub('^%s+',''):gsub('%s+$','')
 if needle~='' then return 'No '..what..' match "'..needle..'". Clear the search or change the filters.' end
 return 'No '..what..' in this view. Change the scope, category or period filter.'
end

local function groups(store,query,filterCategory)
 local list=ns.Reports.Build(store,query.scope,nil,query.showHidden,query.period=='lifetime').groups
 local out={}
 for _,g in ipairs(list)do
  if not filterCategory or query.category=='all' or g.kind==query.category then out[#out+1]=g end
 end
 return out
end

local function statsOf(g,query)return g.stats and g.stats[query.period] or nil end
local function groupSearchTexts(g)
 local texts={g.name,ns.Categories.Label(g.kind or 'other')}
 for _,spell in ipairs(g.spells)do texts[#texts+1]=ns.SpellName(spell.spellID)end
 return texts
end

local overviewColumns={
 {key='name',label='Weapon or group',width=300,align='left'},
 {key='kind',label='Category',width=80,align='left'},
 {key='typical',label='Typical DPS',width=100,align='right'},
 {key='bestDps',label='Best DPS',width=90,align='right'},
 {key='bestFight',label='Best fight',width=100,align='right'},
 {key='lifetime',label='Lifetime',width=130,align='right'},
}
local weaponColumns={
 {key='name',label='Weapon or group',width=250,align='left'},
 {key='kind',label='Category',width=70,align='left'},
 {key='typical',label='Typical',width=70,align='right'},
 {key='recent',label='Recent',width=65,align='right'},
 {key='confidence',label='Confidence',width=80,align='left'},
 {key='fights',label='Fights',width=50,align='right'},
 {key='damage',label='Damage',width=90,align='right'},
 {key='auto',label='Auto',width=80,align='right'},
 {key='abilities',label='Abilities',width=80,align='right'},
 {key='bestDps',label='Best DPS',width=70,align='right'},
 {key='bestFight',label='Best fight',width=80,align='right'},
}
local detailColumns={
 {key='spell',label='Spell',width=300,align='left'},
 {key='damage',label='Damage',width=120,align='right'},
 {key='share',label='Share',width=80,align='right'},
 {key='bestFight',label='Best in one fight',width=140,align='right'},
}

local function groupRow(g,query,order,wide)
 local stats=statsOf(g,query)
 local typical=stats and stats.typical
 local damage=query.period=='lifetime' and g.lifetimeDamage or g.damage
 local rec=g.records or {}
 local bestDps=rec.fightDPS and rec.fightDPS.value
 local bestFight=rec.fightDamage and rec.fightDamage.value
 local kindLabel=ns.Categories.Label(g.kind or 'other')
 local cells
 if wide then
  cells={
   cell(g.name,'label',plain(g.name):lower()),cell(kindLabel,'kind:'..(g.kind or 'other'),kindLabel:lower()),
   typical and cell(one(typical),'dps',typical) or unavailable(),
   stats and stats.recentMedian and cell(one(stats.recentMedian),'dps',stats.recentMedian) or unavailable(),
   cell(stats and stats.confidence or 'none','confidence:'..(stats and stats.confidence or 'none'),stats and stats.n or 0),
   cell(tostring(stats and stats.n or 0),'label',stats and stats.n or 0),
   cell(whole(damage),'damage',damage),cell(whole(g.autoDamage),'damage',g.autoDamage),cell(whole(g.abilityDamage),'ability',g.abilityDamage),
   bestDps and cell(one(bestDps),'record',bestDps) or unavailable(),
   bestFight and cell(whole(bestFight),'record',bestFight) or unavailable(),
  }
 else
  cells={
   cell(g.name,'label',plain(g.name):lower()),cell(kindLabel,'kind:'..(g.kind or 'other'),kindLabel:lower()),
   typical and cell(one(typical),'dps',typical) or unavailable(),
   bestDps and cell(one(bestDps),'record',bestDps) or unavailable(),
   bestFight and cell(whole(bestFight),'record',bestFight) or unavailable(),
   cell(whole(g.lifetimeDamage),'lifetime',g.lifetimeDamage),
  }
 end
 return {key=g.profile,cells=cells,order=order}
end

local function detailFor(g,query)
 local rows={}
 local recordSpells=g.records and g.records.spells or {}
 for i,spell in ipairs(g.spells)do
  local best=recordSpells[spell.spellID]
  rows[#rows+1]={key='spell:'..spell.spellID,order=i,cells={
   cell(ns.SpellName(spell.spellID),'label',ns.SpellName(spell.spellID):lower()),
   cell(whole(spell.damage),'damage',spell.damage),
   spell.percent and cell(string.format('%.1f%%',spell.percent),'percent',spell.percent) or unavailable(),
   best and cell(whole(best.value),'record',best.value) or unavailable(),
  }}
 end
 if g.unattributed and g.unattributed>0 then
  rows[#rows+1]={key='unattributed',order=#rows+1,cells={cell('Damage without spell details','hint',nil),cell(whole(g.unattributed),'damage',g.unattributed),unavailable(),unavailable()}}
 end
 return {title=g.name,columns=detailColumns,rows=rows}
end

local function header(store,list)
 local c=store:Character()
 local best=c.records and c.records.character or {}
 return {lifetime=c.totalDamage,name=c.name,class=c.class,groupCount=#list,
  bestFight=best.fightDamage and best.fightDamage.value,bestDps=best.fightDPS and best.fightDPS.value}
end

-- One readable line for a build snapshot; only fields that were readable are mentioned.
local function describeBuild(b)
 local parts={}
 local function add(text)parts[#parts+1]=text end
 if b.level then add('Level '..b.level)end
 local stats={}
 for _,pair in ipairs({{'strength','Str'},{'agility','Agi'},{'stamina','Sta'},{'intellect','Int'},{'spirit','Spi'}})do
  if b[pair[1]] then stats[#stats+1]=pair[2]..' '..b[pair[1]]end
 end
 if #stats>0 then add(table.concat(stats,' '))end
 if b.attackPower then add('Attack power '..b.attackPower)end
 if b.rangedAttackPower then add('Ranged attack power '..b.rangedAttackPower)end
 if b.spellPower then add('Spell power '..b.spellPower)end
 local crit={}
 if b.meleeCrit then crit[#crit+1]='melee '..string.format('%.1f%%',b.meleeCrit)end
 if b.rangedCrit then crit[#crit+1]='ranged '..string.format('%.1f%%',b.rangedCrit)end
 if b.spellCrit then crit[#crit+1]='spell '..string.format('%.1f%%',b.spellCrit)end
 if #crit>0 then add('Crit '..table.concat(crit,' '))end
 local speed={}
 for _,pair in ipairs({{'mainHandSpeed','main'},{'offHandSpeed','off'},{'rangedSpeed','ranged'}})do
  if b[pair[1]] then speed[#speed+1]=pair[2]..' '..string.format('%.2f',b[pair[1]])end
 end
 if #speed>0 then add('Speed '..table.concat(speed,' '))end
 if b.source then add('read '..b.source)end
 return table.concat(parts,' | ')
end

local hints={
 Overview='Typical DPS is a duration-weighted average of fights of at least 10 seconds and gets more accurate with use. Best values and lifetime damage are protected and cannot be reset.',
 Weapons='Select a weapon to list every spell it is credited with. Confidence grows with the number of fights. Damage follows the selected period.',
 Spells='Spells combined across the weapons in the current filter. Best in one fight is a protected record.',
 Compare='Compares observed results of two weapons. Differences are not caused by the weapon alone: gear, level and targets also change them.',
 History='Completed fights, newest first. Select a column heading to sort.',
 Data='Capture state and notes about what the addon can and cannot know.',
}

local function buildGroupsTab(store,query,wide)
 local list=groups(store,query,true)
 local columns=wide and weaponColumns or overviewColumns
 local rows={}
 for i,g in ipairs(list)do
  if matches(query,unpack(groupSearchTexts(g)))then rows[#rows+1]=groupRow(g,query,i,wide)end
 end
 local sortKey=sortRows(rows,query,'lifetime',columns)
 local result={columns=columns,rows=rows,header=header(store,list),sortKey=sortKey,sortDesc=query.sortDesc}
 if #rows==0 then result.empty=emptyMessage(query,'weapons or groups')return result end
 local selected;for _,r in ipairs(rows)do if r.key==query.selected then selected=r.key end end
 selected=selected or rows[1].key;result.selected=selected
 for _,g in ipairs(list)do if g.profile==selected then result.detail=detailFor(g,query)end end
 return result
end

local function buildSpells(store,query)
 local list=groups(store,query,true)
 local total=0;local byId={}
 for _,g in ipairs(list)do
  for _,spell in ipairs(g.spells)do
   local a=byId[spell.spellID] or {id=spell.spellID,damage=0,groups=0,best=nil};byId[spell.spellID]=a
   a.damage=a.damage+spell.damage;a.groups=a.groups+1;total=total+spell.damage
   local best=g.records and g.records.spells and g.records.spells[spell.spellID]
   if best and (not a.best or best.value>a.best)then a.best=best.value end
  end
 end
 local columns={
  {key='spell',label='Spell',width=330,align='left'},{key='damage',label='Damage',width=130,align='right'},
  {key='share',label='Share',width=90,align='right'},{key='groups',label='In groups',width=90,align='right'},
  {key='bestFight',label='Best in one fight',width=150,align='right'},
 }
 local rows={};local order=0
 for id,a in pairs(byId)do
  local name=ns.SpellName(id)
  if matches(query,name)then
   order=order+1
   local share=total>0 and 100*a.damage/total or nil
   rows[#rows+1]={key='spell:'..id,order=order,cells={
    cell(name,'label',name:lower()),cell(whole(a.damage),'damage',a.damage),
    share and cell(string.format('%.1f%%',share),'percent',share) or unavailable(),
    cell(tostring(a.groups),'label',a.groups),a.best and cell(whole(a.best),'record',a.best) or unavailable(),
   }}
  end
 end
 table.sort(rows,function(a,b)return a.cells[1].text<b.cells[1].text end)
 for i,r in ipairs(rows)do r.order=i end
 local sortKey=sortRows(rows,query,'damage',columns)
 local result={columns=columns,rows=rows,header=header(store,list),sortKey=sortKey,sortDesc=query.sortDesc}
 if #rows==0 then result.empty=emptyMessage(query,'spells')end
 return result
end

local function buildHistory(store,query)
 local c=store:Character()
 local columns={
  {key='target',label='Target at combat start',width=300,align='left'},{key='mode',label='Combat type',width=100,align='left'},
  {key='damage',label='Damage',width=110,align='right'},{key='seconds',label='Seconds',width=80,align='right'},
  {key='dps',label='DPS',width=90,align='right'},{key='grouped',label='Grouped',width=70,align='left'},
  {key='session',label='Native session',width=110,align='right'},
  {key='build',label='Build bucket',width=110,align='left'},
 }
 local rows={}
 for i=#c.history,1,-1 do
  local r=c.receipts[c.history[i]]
  local inPeriod=query.period=='lifetime' or (r and (r.reportGeneration or 0)==(c.reportGeneration or 0))
  if r and inPeriod and (query.scope=='all' or r.mode==query.scope)then
   local context=r.context or {}
   local target=context.targetName or 'Target not recorded'
   if matches(query,target,r.mode)then
    local dps=ns.Number(r.seconds) and r.seconds>0 and r.damage/r.seconds or nil
    rows[#rows+1]={key=r.receiptID,order=#c.history-i+1,cells={
     cell(target,'label',target:lower()),cell(r.mode,'label',r.mode),cell(whole(r.damage),'damage',r.damage),
     ns.Number(r.seconds) and cell(string.format('%.1f',r.seconds),'label',r.seconds) or unavailable(),
     dps and cell(one(dps),'dps',dps) or unavailable(),
     cell(context.grouped==true and 'Yes' or context.grouped==false and 'No' or 'Not recorded','label',nil),
     r.nativeSessionID and cell(tostring(r.nativeSessionID),'label',r.nativeSessionID) or unavailable(),
     r.build and r.build.bucket and cell(r.build.bucket,'label',r.build.bucket) or unavailable(),
    }}
   end
  end
 end
 local sortKey=sortRows(rows,query,nil,columns)
 local result={columns=columns,rows=rows,header=header(store,{}),sortKey=sortKey,sortDesc=query.sortDesc}
 if #rows==0 then result.empty=emptyMessage(query,'fights')end
 return result
end

local function buildData(store,query,env)
 env=env or {}
 local c=store:Character()
 local columns={{key='item',label='Item',width=260,align='left'},{key='value',label='Value',width=640,align='left'}}
 local withBuild,latest=0,nil
 for i=#c.history,1,-1 do
  local r=c.receipts[c.history[i]]
  if r and r.build then withBuild=withBuild+1;latest=latest or r.build end
 end
 local entries={
  {'Recording',env.recording and 'Enabled' or 'Paused',env.recording and 'good' or 'warning'},
  {'Native damage meter',env.meter and 'Available' or 'Unavailable',env.meter and 'good' or 'bad'},
  {'Native spell breakdown',env.spells and 'Available' or 'Unavailable',env.spells and 'good' or 'bad'},
  {'Capture note',env.gap or 'No reported gap','label'},
  {'Character lifetime damage',whole(c.totalDamage),'lifetime'},
  {'Protected best fight',c.records and c.records.character and c.records.character.fightDamage and whole(c.records.character.fightDamage.value) or 'Unavailable','record'},
  {'Stored fights',tostring(#c.history),'label'},
  {'Fights with a build snapshot',withBuild..' of '..#c.history..' stored fights',withBuild>0 and 'label' or 'unavailable'},
  {'Calibrated item estimates','Need 20 fights with a build snapshot for the equipped weapon. Spell estimates also need spell power to vary across those fights.','hint'},
  {'Latest build snapshot',latest and describeBuild(latest) or 'None yet: stats are read when a fight starts.',latest and 'label' or 'unavailable'},
  {'Critical hits, single hit maxima, misses','Unavailable: the native damage meter provides fight summaries only.','unavailable'},
  {'PvE / PvP classification','Not verified until complete recipient evidence is available.','unavailable'},
  {'Maximum meaning','Best values are the best total, best DPS and best spell in one fight, not a single hit.','hint'},
  {'Controls',env.controls or 'Not reported','label'},
 }
 local rows={}
 for _,e in ipairs(entries)do
  if matches(query,e[1],e[2])then rows[#rows+1]={key=e[1],order=#rows+1,cells={cell(e[1],'label',e[1]:lower()),cell(e[2],e[3],nil)}}end
 end
 local result={columns=columns,rows=rows,header=header(store,{})}
 if #rows==0 then result.empty=emptyMessage(query,'items')end
 return result
end

local compareColumns={
 {key='metric',label='Metric',width=250,align='left'},{key='a',label='First weapon',width=250,align='right'},
 {key='b',label='Second weapon',width=250,align='right'},{key='diff',label='Second vs first',width=150,align='right'},
}
local function buildCompare(store,query)
 local list=groups(store,{scope=query.scope,period=query.period,showHidden=query.showHidden,category='all'},false)
 local options={};local byKey={}
 for _,g in ipairs(list)do options[#options+1]={key=g.profile,label=plain(g.name)};byKey[g.profile]=g end
 local a=byKey[query.compareA] and query.compareA or (options[1] and options[1].key)
 local b=byKey[query.compareB] and query.compareB or nil
 if not b then for _,o in ipairs(options)do if o.key~=a then b=o.key;break end end end
 local ga,gb=byKey[a],byKey[b]
 local metrics={
  {'Typical DPS','dps',function(g)local s=statsOf(g,query);return s and s.typical end,one},
  {'Recent DPS','dps',function(g)local s=statsOf(g,query);return s and s.recentMedian end,one},
  {'Best DPS in one fight','record',function(g)return g.records and g.records.fightDPS and g.records.fightDPS.value end,one},
  {'Best fight','record',function(g)return g.records and g.records.fightDamage and g.records.fightDamage.value end,whole},
  {'Lifetime damage','lifetime',function(g)return g.lifetimeDamage end,whole},
  {'Fights counted','label',function(g)local s=statsOf(g,query);return s and s.n end,function(v)return tostring(v)end},
 }
 local rows={}
 for i,m in ipairs(metrics)do
  local va=ga and m[3](ga);local vb=gb and m[3](gb)
  local diff
  if va and vb and va>0 then
   local pct=100*(vb/va-1)
   diff=cell((pct>=0 and '+' or '-')..string.format('%.1f%%',math.abs(pct)),pct>=0 and 'good' or 'bad',pct)
  else diff=unavailable() end
  rows[#rows+1]={key=m[1],order=i,cells={cell(m[1],'label',nil),va and cell(m[4](va),m[2],va) or unavailable(),vb and cell(m[4](vb),m[2],vb) or unavailable(),diff}}
 end
 local result={columns=compareColumns,rows=rows,header=header(store,list),compare={options=options,a=a,b=b}}
 if #options<2 then result.empty='Two weapons or groups with recorded fights are needed to compare. Use a weapon for a while, then change it.' end
 return result
end

function VM.Build(store,query,env)
 local result
 local tab=query.tab
 if tab=='Weapons' then result=buildGroupsTab(store,query,true)
 elseif tab=='Spells' then result=buildSpells(store,query)
 elseif tab=='Compare' then result=buildCompare(store,query)
 elseif tab=='History' then result=buildHistory(store,query)
 elseif tab=='Data' then result=buildData(store,query,env)
 else result=buildGroupsTab(store,query,false)end
 result.hint=hints[tab] or hints.Overview
 result.tab=tab
 return result
end

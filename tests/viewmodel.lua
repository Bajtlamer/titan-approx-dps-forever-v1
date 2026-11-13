local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','UI/ViewModel'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local VM=ns.ViewModel
local names={[75]='Auto Shot',[3044]='Arcane Shot',[2973]='Raptor Strike',[6603]='Attack'}
C_Spell={IsRangedAutoAttackSpell=function(id)return id==75 or id>=1000 end,GetSpellName=function(id)return names[id]end}
local PROFILE='16:30:0;17:empty;18:20:0'
local db=ns.Storage.Open({},'p');local c=db:Character();c.class='HUNTER';c.name='Tester'
c.profiles[PROFILE]='|cff1eff00|Hitem:30:0|h[Staff]|h|r / |cff1eff00|Hitem:20:0|h[Bow]|h|r'
local function fight(id,seconds,mode,target,spells)
 local total=0;for _,s in ipairs(spells)do total=total+s.damage.value end
 db:UpsertContribution({receiptID=id,profile=PROFILE,mode=mode or 'pve',damage=total,seconds=seconds,at=1,context={targetName=target or 'Boar',targetChanges=0,grouped=false},spells=spells})
end
local function sp(id,value,origin)return {spellID=id,origin=origin or 'player',damage={value=value}}end
for i=1,12 do fight('a'..i,10,'pve','Boar',{sp(75,600),sp(3044,200),sp(2973,100),sp(1,50,'summon')})end
fight('pvp1',20,'pvp','Player',{sp(75,100)})
db.saved.settings.mode='all'
local env={recording=true,meter=true,spells=true,gap=nil}
local function build(patch)local q=VM.NewQuery();for k,v in pairs(patch or {})do q[k]=v end;return VM.Build(db,q,env),q end
local function keys(rows)local out={};for _,r in ipairs(rows)do out[#out+1]=r.cells[1].text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')end;return out end

-- overview lists weapon groups, largest lifetime first, with a color kind per cell
local v=build();assert(#v.rows==3,'three groups, got '..#v.rows)
assert(v.header.lifetime==db:Character().totalDamage and v.header.name=='Tester')
assert(v.columns[1].key=='name' and v.rows[1].cells[1].text:find('Bow',1,true),'ranged group first')
for _,col in ipairs(v.columns)do assert(col.key and col.label and col.width,'column shape')end
for _,r in ipairs(v.rows)do assert(#r.cells==#v.columns,'cell count');assert(r.key)end
assert(v.hint and #v.hint>0)

-- category filter
v=build({category='melee'});assert(#v.rows==1 and v.rows[1].cells[1].text:find('Staff',1,true))
v=build({category='pet'});assert(#v.rows==1)
v=build({category='spell'});assert(#v.rows==0 and v.empty,'empty state has a message')

-- search matches weapon names, category names and spell names; no pagination fields
v=build({search='raptor'});assert(#v.rows==1 and v.rows[1].cells[1].text:find('Staff',1,true),'search by spell')
v=build({search='BOW'});assert(#v.rows==1,'case insensitive weapon search')
v=build({search='ranged'});assert(#v.rows==1,'search by category')
v=build({search='zzz'});assert(#v.rows==0 and v.empty:find('zzz',1,true),'empty search message names the query')
assert(v.page==nil and v.pages==nil and v.nextPage==nil)

-- sorting both directions, stable on ties
v=build({sortKey='typical',sortDesc=true});local desc=keys(v.rows)
v=build({sortKey='typical',sortDesc=false});local asc=keys(v.rows)
assert(desc[1]==asc[#asc] and desc[#desc]==asc[1],'sort reverses')
v=build({sortKey='name',sortDesc=false});local names2=keys(v.rows);local sorted={};for i,n in ipairs(names2)do sorted[i]=n:lower()end;table.sort(sorted);for i=1,#sorted do assert(sorted[i]==names2[i]:lower(),'name sort')end

-- weapons tab has more columns than overview
local w=build({tab='Weapons'});assert(#w.columns>#build().columns)

-- detail pane shows every spell of the selected group (no truncation)
local many={};for id=1000,1039 do many[#many+1]=sp(id,10)end
fight('wide',10,'pve','Boar',many)
v=build({tab='Weapons',selected=nil});assert(v.selected,'a selection is always chosen')
local bowDetail
for _,r in ipairs(v.rows)do if r.cells[1].text:find('Bow',1,true)then v=build({tab='Weapons',selected=r.key});bowDetail=v.detail end end
assert(bowDetail and #bowDetail.rows>=42,'all spells listed, got '..tostring(bowDetail and #bowDetail.rows))
assert(bowDetail.columns[1].key=='spell')
-- an unknown selection falls back to the first row
v=build({selected='missing'});assert(v.selected==v.rows[1].key)

-- spells tab aggregates across groups and shares add up
local s=build({tab='Spells'});assert(#s.rows>=4)
local share=0;for _,r in ipairs(s.rows)do share=share+(r.cells[3].sort or 0)end;assert(math.abs(share-100)<0.001,'shares sum to 100, got '..share)
s=build({tab='Spells',search='arcane'});assert(#s.rows==1 and s.rows[1].cells[1].text=='Arcane Shot')
s=build({tab='Spells',category='melee'});for _,r in ipairs(s.rows)do assert(r.cells[1].text~='Auto Shot','category limits spells')end

-- history: newest first, scope and search
local h=build({tab='History'});assert(#h.rows>=14);assert(h.rows[1].cells[1].text=='Boar','newest fight is the wide one')
h=build({tab='History',scope='pvp'});assert(#h.rows==1 and h.rows[1].cells[1].text=='Player')
h=build({tab='History',search='player'});assert(#h.rows==1)

-- data tab explains capture state
local d=build({tab='Data'});local txt={};for _,r in ipairs(d.rows)do txt[#txt+1]=r.cells[1].text end
assert(table.concat(txt,'|'):find('Recording',1,true))
d=build({tab='Data',search='recording'});assert(#d.rows==1)

-- compare: defaults to the two largest groups, explicit choice, signed difference with color kind
local cmp=build({tab='Compare'});assert(cmp.compare and #cmp.compare.options==3 and cmp.compare.a and cmp.compare.b and cmp.compare.a~=cmp.compare.b)
assert(#cmp.rows>=6 and cmp.columns[1].key=='metric')
local diffCell;for _,r in ipairs(cmp.rows)do if r.cells[1].text=='Typical DPS' then diffCell=r.cells[4]end end
assert(diffCell and (diffCell.text:find('^[+-]') or diffCell.text=='Unavailable'),'signed difference')
local swapped=build({tab='Compare',compareA=cmp.compare.b,compareB=cmp.compare.a})
local swappedCell;for _,r in ipairs(swapped.rows)do if r.cells[1].text=='Typical DPS' then swappedCell=r.cells[4]end end
if diffCell.sort and swappedCell.sort then assert(diffCell.sort*swappedCell.sort<=0,'swapping flips the sign')end
local one=build({tab='Compare',category='all',scope='pvp'});assert(one.compare.b==nil or one.compare.a~=one.compare.b)

-- period: after a fresh report start the period view is empty while all periods keep everything
local before=#build().rows
db:ResetReports(5)
assert(#build({period='period'}).rows==0,'fresh period is empty')
assert(#build({period='lifetime'}).rows==before,'all periods unchanged')
-- hidden weapons are excluded unless asked for
ns.Reports.SetHidden(db,build({period='lifetime'}).rows[1].key,true)
assert(#build({period='lifetime'}).rows==before-1 and #build({period='lifetime',showHidden=true}).rows==before)
print('PASS window view model: filters, search, sort, detail without truncation, spells, history, data, compare, periods')

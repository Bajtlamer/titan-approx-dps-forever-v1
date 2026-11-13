local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Reports'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local api={C_Item={GetItemInfoInstant=function(id)return id,'','',id==30 and 'INVTYPE_SHIELD' or 'INVTYPE_WEAPON',nil,id==30 and 4 or 2 end},C_Spell={IsRangedAutoAttackSpell=function(id)return id==75 end}}
local db=ns.Storage.Open({},'p');local c=db:Character();c.class='HUNTER'
local set='16:10:0;17:empty;18:20:0';c.profiles[set]='|cff1eff00|Hitem:10:0|h[Staff]|h|r / |cff1eff00|Hitem:20:0|h[Bow]|h|r'
local function record(id,total,spells,profile,seconds)db:UpsertContribution({receiptID=id,profile=profile or set,mode='pve',damage=total,seconds=seconds or 10,spells=spells})end
record('1',100,{{spellID=6603,origin='player',damage={value=30}},{spellID=75,damage={value=50}},{spellID=1978,damage={value=20}}})
local report=ns.Reports.Build(db,'all',api);local groups={};local sum=0
for _,g in ipairs(report.groups)do groups[g.category or g.slot]=g;sum=sum+g.damage end
assert(sum==100 and c.totalDamage==100)
assert(groups[16].damage==30 and groups[18].damage==50 and groups.unclassified.damage==20)
assert(groups[16].name:find('Staff',1,true) and not groups[16].name:find('Bow',1,true));assert(groups[18].autoDamage==50 and groups[18].abilityDamage==0)
record('2',20,{{spellID=1978,damage={value=20}}})
report=ns.Reports.Build(db,'all',api);for _,g in ipairs(report.groups)do if g.slot==18 then assert(g.seconds==20 and g.dps==2.5,'inactive eligible fight missing from denominator')end end
local dual='16:10:0;17:11:0;18:empty';c.profiles[dual]='Daggers';record('3',40,{{spellID=6603,origin='player',damage={value=40}}},dual)
report=ns.Reports.Build(db,'all',api);local unresolved=false;for _,g in ipairs(report.groups)do if g.category=='ambiguous_melee' then assert(g.damage==40);unresolved=true end end;assert(unresolved)
local shield='16:10:0;17:30:0;18:empty';record('4',10,{{spellID=6603,origin='player',damage={value=10}}},shield)
report=ns.Reports.Build(db,'all',api);for _,g in ipairs(report.groups)do assert(g.slot~=17);if g.slot==16 then assert(g.damage==40)end end
local before=c.totalDamage;ns.Reports.SetHidden(db,'slot:18:20:0',true);report=ns.Reports.Build(db,'all',api);for _,g in ipairs(report.groups)do assert(g.slot~=18)end;assert(c.totalDamage==before)
print('PASS weapon slots, independent names, auto/ability separation, conservative dual wield, shield exclusion and duration pools')
record('pet',50,{{spellID=6603,origin='summon',damage={value=50}}})
report=ns.Reports.Build(db,'all',api);local pet=false;for _,g in ipairs(report.groups)do if g.category=='summon' then assert(g.damage==50);pet=true end end;assert(pet)
local unknown='16:10:0;17:empty;18:empty';record('legacy',12,{{spellID=6603,damage={value=12}}},unknown)
report=ns.Reports.Build(db,'all',api);for _,g in ipairs(report.groups)do if g.slot==16 then assert(g.damage==40,'legacy pet-ambiguous swing assigned')end end
local druid=ns.Storage.Open({},'d');druid:Character().class='DRUID';druid:UpsertContribution({receiptID='1',profile=unknown,mode='pve',damage=30,seconds=10,spells={{spellID=6603,origin='player',damage={value=30}}}})
report=ns.Reports.Build(druid,'all',api);assert(#report.groups==1 and report.groups[1].category=='ambiguous_melee')
local source=db:Character().rows;for _,row in pairs(source)do for _,s in pairs(row.spells)do if s.origins then local sum=0;for _,part in pairs(s.origins)do sum=sum+part.damage end;assert(sum==s.damage)end end end
print('PASS summon, legacy-source and shapeshift exclusions with conserved actor rollups')

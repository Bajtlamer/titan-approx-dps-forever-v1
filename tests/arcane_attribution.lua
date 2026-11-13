local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Reports'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local profile='16:4566:0;17:empty;18:3036:0'
local api={C_Item={GetItemInfoInstant=function(id)return id,'','','INVTYPE_RANGED',nil,2 end}}
local function fight(class,spells,gear)
 local db=ns.Storage.Open({},'p');local c=db:Character();c.class=class;db:ResetReports()
 local total=0;for _,s in ipairs(spells)do total=total+s.damage.value end
 db:UpsertContribution({receiptID='one',profile=gear or profile,mode='unknown',damage=total,seconds=3,spells=spells})
 local report=ns.Reports.Build(db,'all',api);local groups={};local sum=0
 for _,g in ipairs(report.groups)do groups[g.slot or g.category]=g;sum=sum+g.damage end
 assert(sum==total and c.totalDamage==total,'classification changed damage totals')
 return groups,db
end
local groups,db=fight('HUNTER',{{spellID=14281,origin='player',damage={value=53}},{spellID=75,origin='player',damage={value=39}},{spellID=6603,origin='summon',damage={value=19}}})
assert(groups[18] and groups[18].damage==92,'Arcane Shot was not grouped with ranged weapon')
assert(groups[18].autoDamage==39 and groups[18].abilityDamage==53,'ability counted as auto attack')
assert(#groups[18].spells==2 and math.abs(groups[18].spells[1].percent-100*53/92)<0.001)
assert(groups.summon.damage==19 and not groups.ambiguous_melee,'zero origin bucket created empty melee group')
local lifetime=db:Character().totalDamage;local weaponLifetime=ns.Reports.WeaponLifetime(db)['slot:18:3036:0']
db:ResetReports();assert(db:Character().totalDamage==lifetime and ns.Reports.WeaponLifetime(db)['slot:18:3036:0']==weaponLifetime)
for _,id in ipairs({3044,14281,14282,14283,14284,14285,14286,14287})do
 local g=fight('HUNTER',{{spellID=id,origin='player',damage={value=10}}});assert(g[18] and g[18].abilityDamage==10,'Arcane Shot rank not assigned: '..id)
end
for _,class in ipairs({'MAGE',false})do local g=fight(class or nil,{{spellID=14281,origin='player',damage={value=10}}});assert(not g[18] and g.unclassified.damage==10,'class uncertainty assigned to bow')end
for _,origin in ipairs({'unknown','summon'})do local g=fight('HUNTER',{{spellID=14281,origin=origin,damage={value=10}}});assert(not g[18],'non-player Arcane Shot assigned to bow')end
local g=fight('HUNTER',{{spellID=14281,origin='player',damage={value=10}}},'16:4566:0;17:empty;18:empty');assert(not g[18] and g.missing_weapon.damage==10,'missing bow assigned')
g=fight('HUNTER',{{spellID=900001,origin='player',damage={value=10}}});assert(g.unclassified.damage==10,'unmapped spell guessed')
g=fight('HUNTER',{{spellID=6603,origin='unknown',damage={value=10}}});assert(g.ambiguous_melee.damage==10,'real unknown damage hidden')
local nonweapon={C_Item={GetItemInfoInstant=function(id)return id,'','','INVTYPE_SHIELD',nil,4 end}}
local _,weaponDB=fight('HUNTER',{{spellID=14281,origin='player',damage={value=10}}})
local report=ns.Reports.Build(weaponDB,'all',nonweapon)
for _,part in ipairs(report.groups)do assert(not part.slot,'known nonweapon used for ability attribution')end
print('PASS Arcane Shot ranks, player/class/weapon guards, 111-damage conservation, zero buckets and lifetime retention')

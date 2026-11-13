local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Reports','Records','Categories','Stats','Json','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local profile='16:10:0;17:11:0;18:20:0'
local api={C_Item={GetItemInfoInstant=function(id)return id,'','','INVTYPE_WEAPON',nil,2 end}}
local function report(class,id,origin,gear,customAPI)
 local db=ns.Storage.Open({},'p');db:Character().class=class;db:ResetReports()
 db:UpsertContribution({receiptID='one',profile=gear or profile,mode='pve',damage=30,seconds=3,spells={{spellID=id,origin=origin or 'player',damage={value=30}}}})
 local r=ns.Reports.Build(db,'all',customAPI or api);local n=0;for _,g in ipairs(r.groups)do n=n+g.damage end
 assert(n==30 and db:Character().totalDamage==30,'rule changed total damage')
 return r.groups[1],db,r
end
-- A known main-hand ability remains identifiable even when ordinary swings are ambiguous.
local g=report('ROGUE',11294);assert(g.slot==16 and g.abilityDamage==30,'Sinister Strike not assigned to main hand during dual wield')
local cases={
 {'WARRIOR',21553,16},{'WARRIOR',11567,16},{'WARRIOR',20569,16},{'WARRIOR',11585,16},{'WARRIOR',11605,16},
 {'ROGUE',11281,16},{'ROGUE',11269,16},{'ROGUE',16511,16},
 {'HUNTER',14281,18},{'HUNTER',20904,18},{'HUNTER',2643,18},{'HUNTER',13549,18},{'HUNTER',14260,16},
 {'PALADIN',678,16},{'PALADIN',879,'spell'},{'PALADIN',1280345,'spell'},
 {'SHAMAN',17364,16},{'SHAMAN',403,'spell'},{'SHAMAN',8042,'spell'},
 {'DRUID',5176,'spell'},{'DRUID',9850,'form'},{'DRUID',5221,'form'},
 {'MAGE',133,'spell'},{'MAGE',116,'spell'},
 {'PRIEST',585,'spell'},{'PRIEST',589,'spell'},
 {'WARLOCK',686,'spell'},{'WARLOCK',172,'spell'},{'WARLOCK',348,'spell'},
 {'WARRIOR',23925,'shield'},{'ROGUE',11300,'spell'},
}
local seen={}
for _,v in ipairs(cases)do
 local class,id,target=v[1],v[2],v[3];seen[class]=true
 local part,db=report(class,id)
 assert((part.slot or part.category)==target,'wrong target for '..class..' spell '..id)
 assert(part.autoDamage==0 and part.abilityDamage==30,'ability mistaken for auto attack')
 local total=db:Character().totalDamage;local weapons=ns.Reports.WeaponLifetime(db)
 db:ResetReports();assert(db:Character().totalDamage==total and #ns.Reports.Build(db,'all',api).groups==0)
 for k,n in pairs(weapons)do assert(ns.Reports.WeaponLifetime(db)[k]==n,'reset deleted weapon lifetime')end
 -- Every rule needs player-origin evidence, including nonweapon classifications.
 for _,origin in ipairs({'unknown','summon'})do local other=report(class,id,origin);assert(not other.slot,'non-player damage assigned to weapon');assert(other.category==(origin=='summon' and 'summon' or 'unclassified'))end
 local other=report('UNSUPPORTED',id);assert(not other.slot and other.category=='unclassified','cross-class rule applied')
 if type(target)=='number'then
  local missing=report(class,id,'player','16:empty;17:11:0;18:empty');assert(not missing.slot and missing.category=='missing_weapon','missing weapon guessed')
  local blocked=report(class,id,'player',nil,{C_Item={GetItemInfoInstant=function(n)return n,'','','INVTYPE_SHIELD',nil,4 end}})
  assert(not blocked.slot and blocked.category=='missing_weapon','shield/relic counted as weapon')
 end
end
local classes=0;for _ in pairs(seen)do classes=classes+1 end;assert(classes==9)
g=report('ROGUE',6603);assert(g.category=='ambiguous_melee','dual-wield auto swings split without evidence')
g=report('DRUID',6603);assert(g.category=='ambiguous_melee','Druid form ambiguity credited to held item')
g=report('MAGE',900001);assert(g.category=='unclassified','unlisted spell guessed')
-- A wand/ranged auto recognised by the native predicate works for caster classes as well.
for _,class in ipairs({'MAGE','PRIEST','WARLOCK'})do
 local auto=report(class,5019,'player',nil,{C_Spell={IsRangedAutoAttackSpell=function(id)return id==5019 end}})
 assert(auto.slot==18 and auto.autoDamage==30,'native ranged auto excluded for caster')
end
assert(ns.SpellRules and ns.SpellRules.Lookup('ROGUE',11294),'class registry missing')
for class in pairs(seen)do assert(#ns.SpellRules.List(class)>0,'no visible rule coverage for '..class)end
local familyCount,idCount=0,0
for class,list in pairs(ns.SpellRules.classes)do
 for _,rule in ipairs(list)do
  familyCount=familyCount+1;assert(rule.source and rule.name and rule.kind)
  for _,id in ipairs(rule.ids)do idCount=idCount+1;assert(ns.SpellRules.Lookup(class,id)==rule,'duplicate/unreachable rule')
   local part=report(class,id);assert((part.slot or part.category)==(rule.slot or rule.kind),'rank target differs from rule')
  end
 end
end
print('PASS all nine classes, '..familyCount..' families / '..idCount..' IDs, guards, dual-wield ambiguity and lifetime retention')
local native={C_Spell={IsRangedAutoAttackSpell=function(id)return id==5019 end}}
local unknown=report('MAGE',5019,'unknown',nil,native)
assert(not unknown.slot,'native predicate assigned a ranged auto with unknown actor')
local blocked=report('HUNTER',75,'player',nil,{C_Item={GetItemInfoInstant=function(n)return n,'','','INVTYPE_RELIC',nil,4 end}})
assert(not blocked.slot,'known nonweapon ranged item received auto-attack damage')
local legacy=report('HUNTER',75,'unknown');assert(legacy.slot==18,'existing fixed Auto Shot identity lost its lifetime attribution')
print('PASS native ranged-auto actor/nonweapon guards and fixed Auto Shot legacy retention')
local _,classified=report('ROGUE',11294,'player')
local _,lessClassified=report('ROGUE',11294,'unknown')
assert(not ns.Transfer.Stage(ns.Transfer.Export(lessClassified),classified),'less-classified backup erased Rogue weapon lifetime')
local preview=assert(ns.Transfer.Stage(ns.Transfer.Export(classified),classified))
assert(ns.Transfer.Apply(preview,classified))
assert(classified:Character().totalDamage==30 and ns.Reports.WeaponLifetime(classified)['slot:16:10:0']==30,'same-class restore changed lifetime')
assert(ns.SpellRules.Lookup(nil,nil)==nil)
print('PASS class-rule restore preserves certainty and weapon lifetime')

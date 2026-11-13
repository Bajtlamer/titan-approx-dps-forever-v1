local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local C=ns.Categories
assert(C.Of({slot=16})=='melee' and C.Of({slot=17})=='melee' and C.Of({slot=18})=='ranged')
assert(C.Of({category='summon'})=='pet' and C.Of({category='form'})=='melee' and C.Of({category='shield'})=='melee' and C.Of({category='ambiguous_melee'})=='melee')
assert(C.Of({category='spell'})=='spell' and C.Of({category='unclassified'})=='other' and C.Of({category='missing_weapon'})=='other' and C.Of({})=='other')
assert(C.Label('melee')=='Melee' and C.Label('ranged')=='Ranged' and C.Label('spell')=='Spells' and C.Label('pet')=='Pet' and C.Label('other')=='Other')

local function kinds(class,profile,spells)
 local db=ns.Storage.Open({},'p');db:Character().class=class
 local list={};local total=0
 for _,s in ipairs(spells)do list[#list+1]={spellID=s[1],origin=s[3] or 'player',damage={value=s[2]}};total=total+s[2]end
 db:UpsertContribution({receiptID='1',profile=profile,mode='pve',damage=total,seconds=20,spells=list})
 local out={};for _,g in ipairs(ns.Reports.Build(db,'all').groups)do out[#out+1]=g.kind end;table.sort(out);return table.concat(out,','),db
end
local bowAndStaff='16:30:0;17:empty;18:20:0'
-- hunter: ranged and melee never share a group
assert(kinds('HUNTER',bowAndStaff,{{3044,100},{2973,50},{75,200}})=='melee,ranged','hunter melee/ranged split')
-- rogue: main hand specials are melee, Eviscerate is a non-weapon ability
assert(kinds('ROGUE','16:30:0;17:31:0;18:empty',{{1759,100},{6762,40}})=='melee,spell','rogue')
-- mage: spells are never credited to the staff
assert(kinds('MAGE','16:30:0;17:empty;18:empty',{{133,100},{116,60}})=='spell','mage spells only')
-- priest wand slot stays ranged only for recognised ranged auto attacks, spells stay spells
assert(kinds('PRIEST','16:30:0;17:empty;18:20:0',{{585,100}})=='spell','priest')
-- warrior shield ability and weapon ability
assert(kinds('WARRIOR','16:30:0;17:empty;18:empty',{{23925,10},{11605,50}})=='melee,melee','warrior shield and weapon are melee')
-- druid form attacks are melee, balance spells are spells
assert(kinds('DRUID','16:30:0;17:empty;18:empty',{{9850,10},{5176,50}})=='melee,spell','druid')
-- shaman and paladin
assert(kinds('SHAMAN','16:30:0;17:empty;18:empty',{{17364,20},{403,70}})=='melee,spell','shaman')
assert(kinds('PALADIN','16:30:0;17:empty;18:empty',{{679,20},{879,70}})=='melee,spell','paladin')
-- warlock spells and a summon
assert(kinds('WARLOCK','16:30:0;17:empty;18:empty',{{686,100},{3110,40,'summon'}})=='pet,spell','warlock pet')
print('PASS categories: melee, ranged, spell and pet are separate for all nine classes')

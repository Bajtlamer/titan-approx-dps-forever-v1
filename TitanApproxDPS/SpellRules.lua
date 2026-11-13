local _,ns=...
local R={classes={}};ns.SpellRules=R
-- Exact IDs and attack mechanics are corroborated by the Forever simulator.
-- Reference inventory: ref-class-weapon-rules.md. No localized-name guessing.
local function family(class,name,kind,ids,path,slot)
 local rule={name=name,kind=kind,slot=slot,ids=ids,source='https://github.com/gunba/wow-forever-sim/blob/forever/sim/'..path..'.go'}
 local list=R.classes[class] or {};R.classes[class]=list;list[#list+1]=rule
end
family('WARRIOR','Heroic Strike','weapon',{11567,25286},'warrior/heroic_strike_cleave',16)
family('WARRIOR','Cleave','weapon',{20569},'warrior/heroic_strike_cleave',16)
family('WARRIOR','Mortal Strike','weapon',{21553},'warrior/mortal_strike',16)
family('WARRIOR','Overpower','weapon',{11585},'warrior/overpower',16)
family('WARRIOR','Slam','weapon',{11605},'warrior/slam',16)
family('WARRIOR','Shield Slam','shield',{23925},'warrior/shield_slam')
family('ROGUE','Sinister Strike','weapon',{1759,8621,11293,11294},'rogue/sinister_strike',16)
family('ROGUE','Backstab','weapon',{2590,8721,11279,11281,25300},'rogue/backstab',16)
family('ROGUE','Ambush','weapon',{8676,8725,11268,11269},'rogue/ambush',16)
family('ROGUE','Hemorrhage','weapon',{16511},'rogue/hemorrhage',16)
family('ROGUE','Eviscerate','spell',{6762,8624,11299,11300,31016},'rogue/eviscerate')
family('HUNTER','Arcane Shot','weapon',{3044,14281,14282,14283,14284,14285,14286,14287},'hunter/arcane_shot',18)
family('HUNTER','Aimed Shot','weapon',{19434,20900,20901,20902,20903,20904},'hunter/aimed_shot',18)
family('HUNTER','Multi-Shot','weapon',{2643},'hunter/multi_shot',18)
family('HUNTER','Serpent Sting','weapon',{1978,13549,13550,13551,13552,13553,13554,13555,25295},'hunter/serpent_sting',18)
family('HUNTER','Raptor Strike','weapon',{2973,14260,14261,14262,14263,14264,14265,14266},'hunter/raptor_strike',16)
family('PALADIN','Holy Strike','weapon',{679,678,1866,680,2495,5569,10332,10333},'paladin/holy_strike',16)
family('PALADIN','Exorcism','spell',{879,5614,5615,10312,10313,10314},'paladin/exorcism')
family('PALADIN','Consecration','spell',{26573,20116,20922,20923,20924,1280345,1280346,1280347,1280348,1280349},'paladin/consecration')
family('SHAMAN','Stormstrike','weapon',{17364},'shaman/stormstrike',16)
family('SHAMAN','Lightning Bolt','spell',{403,529,548,915,943,6041,10391,10392,15207,15208},'shaman/lightning_bolt')
family('SHAMAN','Lightning Bolt Overload','spell',{408439,408440,408441,408442,408443,408472,408473,408474,408475,408477},'shaman/lightning_bolt')
family('SHAMAN','Earth Shock','spell',{8042,8044,8045,8046,10412,10413,10414},'shaman/earth_shock')
family('DRUID','Wrath','spell',{5176,5177,5178,5179,5180,6780,8905,9912},'druid/wrath')
family('DRUID','Claw','form',{9850},'druid/claw')
family('DRUID','Shred','form',{5221,8992,9829,9830},'druid/shred')
family('MAGE','Fireball','spell',{133,143,145,3140,8400,8401,8402,10148,10149,10150,10151,25306},'mage/fireball')
family('MAGE','Frostbolt','spell',{116,205,837,7322,8406,8407,8408,10179,10180,10181,25304},'mage/frostbolt')
family('PRIEST','Smite','spell',{585,591,598,984,1004,6060,10933,10934},'priest/smite')
family('PRIEST','Shadow Word: Pain','spell',{589,594,970,992,2767,10892,10893,10894},'priest/shadow_word_pain')
family('WARLOCK','Shadow Bolt','spell',{686,695,705,1088,1106,7641,11659,11660,11661,25307},'warlock/shadowbolt')
family('WARLOCK','Corruption','spell',{172,6222,6223,7648,11671,11672,25311},'warlock/corruption')
family('WARLOCK','Immolate','spell',{348,707,1094,2941,11665,11667,11668,25309},'warlock/immolate')
local index={}
for class,list in pairs(R.classes)do
 index[class]={}
 for _,rule in ipairs(list)do for _,id in ipairs(rule.ids)do assert(not index[class][id],'Duplicate spell rule');index[class][id]=rule end end
end
function R.Lookup(class,id)return index[class] and index[class][id]end
function R.List(class)return R.classes[class] or {}end
function R.TargetLabel(rule)
 return rule.slot and ({[16]='Main hand',[17]='Off hand',[18]='Ranged'})[rule.slot] or ({spell='No specific weapon',form='Form ability',shield='Shield ability'})[rule.kind]
end

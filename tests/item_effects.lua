local ns={}
for _,f in ipairs({'Namespace','Capabilities','ItemEffects'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local F=ns.ItemEffects
local n=0
local function eq(a,b)n=n+1;assert(a==b,tostring(a)..' ~= '..tostring(b))end
local function near(a,b)n=n+1;assert(a and math.abs(a-b)<1e-6,tostring(a)..' ~~ '..tostring(b))end
local S,A,ST,I='ITEM_MOD_STRENGTH_SHORT','ITEM_MOD_AGILITY_SHORT','ITEM_MOD_STAMINA_SHORT','ITEM_MOD_INTELLECT_SHORT'
local boots={[A]=2}
local ctx60={level=60,stamina=100,intellect=100}

-- Hunter: Agility gives 1 melee AP, 2 ranged AP and physical crit; no direct damage from Intellect.
local d=F.Derive('HUNTER',boots,{},ctx60)
eq(d.meleeAP,2);eq(d.rangedAP,4);near(d.physCrit,2/52.9);eq(d.spellPower,nil);eq(d.hp,nil)
-- Rogue and warrior differ from the hunter.
d=F.Derive('ROGUE',boots,{},ctx60);eq(d.meleeAP,2);eq(d.rangedAP,4);near(d.physCrit,2/29)
d=F.Derive('WARRIOR',{[S]=3,[A]=2},{},ctx60);eq(d.meleeAP,6);eq(d.rangedAP,4);near(d.physCrit,2/20)
-- Casters get no attack power from Agility; Strength gives 1 melee AP.
d=F.Derive('MAGE',{[A]=5,[S]=2},{},ctx60);eq(d.meleeAP,2);eq(d.rangedAP,nil);near(d.physCrit,5/19.5)
-- Intellect: spell crit and mana, never spell power.
d=F.Derive('MAGE',{[I]=10},{},ctx60);near(d.spellCrit,10/59.5);eq(d.mana,150);eq(d.spellPower,nil)
d=F.Derive('WARRIOR',{[I]=10},{},ctx60);eq(d.spellCrit,nil);eq(d.mana,nil)
d=F.Derive('ROGUE',{[I]=10},{},ctx60);eq(d.mana,nil)
-- Stamina: first 20 points give 1 HP, the rest 10 HP, measured at the current total.
d=F.Derive('WARRIOR',{[ST]=5},{},ctx60);eq(d.hp,50)
d=F.Derive('WARRIOR',{[ST]=5},{},{level=60,stamina=18});eq(d.hp,2*1+3*10)
d=F.Derive('WARRIOR',{[ST]=5},{},{level=60});eq(d.hp,nil)
d=F.Derive('WARRIOR',{},{[ST]=5},ctx60);eq(d.hp,-50)
-- Mana threshold: first 20 Intellect give 1 mana, then 15.
d=F.Derive('MAGE',{[I]=4},{},{level=60,intellect=18});eq(d.mana,2*1+2*15)
-- A pure Stamina item changes health only, with no damage effect.
d=F.Derive('WARRIOR',{[ST]=7},{},ctx60)
eq(d.meleeAP,nil);eq(d.rangedAP,nil);eq(d.spellPower,nil);eq(d.physCrit,nil);eq(d.hp,70)
-- Direct power stats pass through; the old item is subtracted.
d=F.Derive('MAGE',{ITEM_MOD_SPELL_POWER_SHORT=20,ITEM_MOD_ATTACK_POWER_SHORT=10},{ITEM_MOD_SPELL_POWER_SHORT=8},ctx60)
eq(d.spellPower,12);eq(d.meleeAP,10)
d=F.Derive('HUNTER',{ITEM_MOD_RANGED_ATTACK_POWER_SHORT=12},{},ctx60);eq(d.rangedAP,12);eq(d.meleeAP,nil)
-- Crit conversion is only known for level 60.
d=F.Derive('HUNTER',boots,{},{level=50});eq(d.physCrit,nil);eq(d.rangedAP,4)
local found=false;for _,t in ipairs(d.notes)do if t:find('level 60',1,true)then found=true end end;assert(found,'level note');n=n+1
d=F.Derive('HUNTER',boots,{},{});eq(d.physCrit,nil)
-- Druid Agility becomes melee AP only in Cat Form; other forms and unknown forms keep a note.
d=F.Derive('DRUID',boots,{},{level=60,form='cat'});eq(d.meleeAP,2)
d=F.Derive('DRUID',boots,{},{level=60,form='bear'});eq(d.meleeAP,nil)
found=false;for _,t in ipairs(d.notes)do if t:find('Cat Form',1,true)then found=true end end;assert(found,'cat note');n=n+1
d=F.Derive('DRUID',{[S]=2},{},{level=60,form='bear'});eq(d.meleeAP,4)
-- Intellect note for casters; Spirit and ratings are listed as not modelled, never converted.
d=F.Derive('PRIEST',{[I]=3,ITEM_MOD_SPIRIT_SHORT=4,ITEM_MOD_HIT_RATING_SHORT=1},{},ctx60)
eq(#d.unmodelled,2);eq(d.unmodelled[1],'ITEM_MOD_HIT_RATING_SHORT');eq(d.unmodelled[2],'ITEM_MOD_SPIRIT_SHORT')
found=false;for _,t in ipairs(d.notes)do if t:find('not spell damage',1,true)then found=true end end;assert(found,'intellect note');n=n+1
-- Unknown class or unreadable stats yield nothing rather than a guess.
eq(F.Derive('NOPE',boots,{},ctx60),nil);eq(F.Derive('HUNTER',nil,{},ctx60),nil)

-- Context reads only public values and tolerates missing API.
local secret={}
local api={UnitLevel=function()return 60 end,UnitStat=function(_,i)return 0,(i==3 and 80 or (i==4 and secret or 30))end,
 GetShapeshiftFormID=function()return 1 end,issecretvalue=function(v)return v==secret end}
local c=F.Context(api,'DRUID')
eq(c.level,60);eq(c.stamina,80);eq(c.intellect,nil);eq(c.form,'cat')
c=F.Context({},'DRUID');eq(c.level,nil);eq(c.stamina,nil);eq(c.form,nil)
api.UnitLevel=function()error('boom')end;eq(F.Context(api,'DRUID').level,nil)
print('PASS '..n..' item effect assertions')

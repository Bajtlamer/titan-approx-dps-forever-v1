local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','Comparisons','SpellRules','WeaponAttribution','Reports','Records','Categories','Stats','Json','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local db=ns.Storage.Open({},'p')
local function add(id,mode,damage,spell,method)db:UpsertContribution({receiptID=id,profile='bow',mode=mode,damage=damage,seconds=10,method=method,spells={{spellID=spell,damage={value=damage}}}})end
add('1','pve',60,1);add('2','pve',40,2,'test:1');add('3','pvp',100,1)
local r=ns.Reports.Build(db,'pve');assert(#r.groups==1 and r.groups[1].damage==100);assert(r.groups[1].lifetimeDamage==200);assert(r.groups[1].spells[1].percent==60);assert(r.characterDamage==200)
ns.Reports.SetHidden(db,'unclassified',true);assert(#ns.Reports.Build(db,'all').groups==0);assert(db:Character().totalDamage==200)
ns.Reports.SetHidden(db,'unclassified',false);assert(#ns.Reports.Build(db,'all').groups==1)
assert(#r.groups[1].spells==2)
local small=ns.Storage.Open({},'p');small:UpsertContribution({receiptID='old',profile='other',mode='unknown',damage=10,seconds=10,spells={}})
local snapshot=ns.Transfer.Export(small);local preview=assert(ns.Transfer.Stage(snapshot,db));assert(ns.Transfer.Apply(preview,db));assert(db:Character().totalDamage==200,'import deleted lifetime')
db:UpsertContribution({receiptID='new',profile='other',mode='unknown',damage=5,seconds=1,spells={}});assert(db:Character().totalDamage==205,'protected lifetime swallowed new damage')
print('PASS grouped spell shares, pagination, reversible hiding and lifetime import protection')

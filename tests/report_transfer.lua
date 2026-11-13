local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Reports','Records','Categories','Stats','Json','BuildSnapshot','Transfer'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local source=ns.Storage.Open({},'p');local c=source:Character();c.baseDamage=100;c.baseSeconds=10;c.reportGeneration=1
c.baseRows.base={profile='16:10:0;17:empty;18:empty',mode='pve',damage=100,seconds=10,timedDamage=100,sessions=1,spells={[6603]={damage=100,timedDamage=100,origins={player={damage=100,timedDamage=100}}}}};c.reportBaseRows=ns.Copy(c.baseRows);source:Rebuild()
local dest=ns.Storage.Open({},'q');dest:Character().class='WARRIOR';dest:Rebuild()
assert(ns.Transfer.Apply(assert(ns.Transfer.Stage(ns.Transfer.Export(source),dest)),dest))
for _,g in ipairs(ns.Reports.Build(dest,'all').groups)do assert(g.slot~=16,'report archive retained certainty stripped from lifetime history')end
local large=ns.Storage.Open({},'p');large:Character().class='HUNTER';large:ResetReports()
for i=1,2050 do large:UpsertContribution({receiptID='r'..i,profile='16:empty;17:empty;18:10:0',mode='pve',damage=1,seconds=1,spells={{spellID=75,damage={value=1}}}})end
local target=ns.Storage.Open({},'p');target:Character().class='HUNTER';target:Rebuild();assert(ns.Transfer.Apply(assert(ns.Transfer.Stage(ns.Transfer.Export(large),target)),target))
target:UpsertContribution({receiptID='new',profile='16:empty;17:empty;18:10:0',mode='pve',damage=1,seconds=1,spells={{spellID=75,damage={value=1}}}})
assert(ns.Json.Decode(ns.Transfer.Export(target)),'restored report compaction introduced duplicate JSON spell keys')
print('PASS report archive actor sanitization and numeric spell-key normalization across restore/compaction')

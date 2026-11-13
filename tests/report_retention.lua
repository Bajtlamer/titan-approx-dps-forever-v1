local ns={};for _,f in ipairs({'Namespace','Settings','Storage'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
local db=ns.Storage.Open({},'p');db:ResetReports()
for i=1,2050 do db:UpsertContribution({receiptID='r'..i,profile='bow',mode='pve',damage=1,seconds=1,spells={{spellID=75,damage={value=1}}}})end
local c=db:Character();local damage=0;for _,row in pairs(c.reportRows)do damage=damage+row.damage end
assert(damage==2050 and c.totalDamage==2050 and c.baseDamage==2 and #c.history==200)
db:ResetReports();assert(next(c.reportRows)==nil and c.totalDamage==2050)
db:UpsertContribution({receiptID='new',profile='bow',mode='pve',damage=2,seconds=1,spells={}})
damage=0;for _,row in pairs(c.reportRows)do damage=damage+row.damage end;assert(damage==2 and c.totalDamage==2052)
print('PASS fresh report periods and both lifetime storage pools across receipt retirement')

local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Titan'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
ns.store=ns.Storage.Open({},'p');ns.store:UpsertContribution({receiptID='1',profile='16:empty;17:empty;18:20:0',mode='pve',damage=100,seconds=10,spells={{spellID=1,origin='player',damage={value=60}},{spellID=2,origin='player',damage={value=40}}}})
ns.store:Character().profiles['16:empty;17:empty;18:20:0']='|cff1eff00|Hitem:20:0|h[Green Bow]|h|r';ns.store.saved.settings.mode='all'
C_Spell={IsRangedAutoAttackSpell=function()return true end}
do local c=ns.store:Character();c.records=nil;c.recordsBackfilled=nil;ns.store:BackfillRecords()end
local lines={};local tip={rules={},ruleCount=0}
function tip:AddLine(s)lines[#lines+1]=s end
function tip:AddDoubleLine(a,b)lines[#lines+1]=a..' '..b end
ns.Titan.Render(tip);local rawText=table.concat(lines,'\n');local text=rawText:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','');assert(text:find('Green Bow',1,true));assert(text:find('60 / 60.0%',1,true));assert(text:find('40 / 40.0%',1,true));assert(text:find('Character lifetime 100',1,true));assert(text:find('Typical DPS 10.0',1,true) and text:find('1 fight, confidence low',1,true),'typical DPS line missing');assert(text:find('Best fight / Best DPS (protected) 100 / 10.0',1,true),'protected record line missing');
local actions={};local node={}
function node:CreateTitle()return self end
function node:CreateButton(label,cb)if cb then actions[label]=cb end;return self end
function node:CreateRadio(label,checked,cb)actions[label]=cb;return self end
function node:CreateCheckbox(label,checked,cb)actions[label]=cb;return self end
MenuUtil={CreateContextMenu=function(_,f)f(nil,node)end};ns.recorder={paused=false};ns.Minimap={};ns.Titan.Menu({})
actions['Ranged: |cff1eff00|Hitem:20:0|h[Green Bow]|h|r']();assert(ns.store:Character().reportHidden['slot:18:20:0']);assert(ns.store:Character().totalDamage==100)
actions['Show all weapons']();assert(not ns.store:Character().reportHidden['slot:18:20:0'])
assert(not actions['Reset lifetime'] and not actions['Delete character'])
for i=1,70 do ns.store:UpsertContribution({receiptID='s'..i,profile='16:empty;17:empty;18:20:0',mode='pve',damage=1,seconds=1,spells={{spellID=100+i,origin='player',damage={value=1}}}})end
local listed={};local titleNode={}
function titleNode:CreateTitle(label)listed[#listed+1]=label;return self end
function titleNode:CreateButton(label,cb)if cb then actions[label]=cb end;return self end
function titleNode:CreateRadio(label,checked,cb)actions[label]=cb;return self end
function titleNode:CreateCheckbox(label,checked,cb)actions[label]=cb;return self end
MenuUtil={CreateContextMenu=function(_,f)f(nil,titleNode)end};ns.Titan.Menu({})
local spellRows=0;for _,label in ipairs(listed)do if label:match('^Spell %d+: ') then spellRows=spellRows+1 end end
assert(spellRows==72,'right click menu must list every spell, got '..spellRows)
assert(ns.Titan.BindWheel==nil and ns.Titan.page==nil,'no paging state')
MenuUtil={CreateContextMenu=function(_,f)f(nil,node)end}
print('PASS Titan menu lists all 72 spells without paging')
local lifetime=ns.store:Character().totalDamage
ns.ResetWeaponReports=function()ns.store:ResetReports()end
assert(actions['Confirm fresh reports'] and not actions['Reset lifetime'])
actions['Confirm fresh reports']();assert(ns.store:Character().totalDamage==lifetime and #ns.Reports.Build(ns.store,'all').groups==0)
print('PASS confirmed menu reset preserves lifetime and clears only report period')
local titles,buttons={},{}
function node:CreateTitle(label)titles[label]=true;return self end
function node:CreateButton(label,cb)buttons[label]=true;if cb then actions[label]=cb end;return self end
ns.store:Character().class='HUNTER';ns.Titan.Menu({})
assert(buttons['Ability rules'] and buttons['Arcane Shot: Ranged (8 IDs)'],'class rule coverage missing from menu')
assert(titles['Unlisted spell IDs stay unresolved.'],'partial coverage not explained')
assert(titles['Weapon totals include associated abilities.'],'weapon association meaning missing')
print('PASS current-class rule coverage and attribution explanation in native menu')

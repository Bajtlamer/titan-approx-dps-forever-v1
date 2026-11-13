local ns={};for _,f in ipairs({'Namespace','Capabilities','Settings','Storage','SpellRules','WeaponAttribution','Records','Reports','Titan'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
ns.store=ns.Storage.Open({},'p');ns.store:UpsertContribution({receiptID='1',profile='16:empty;17:empty;18:20:0',mode='pve',damage=100,seconds=10,spells={{spellID=1,origin='player',damage={value=60}},{spellID=2,origin='player',damage={value=40}}}})
ns.store:Character().profiles['16:empty;17:empty;18:20:0']='|cff1eff00|Hitem:20:0|h[Green Bow]|h|r';ns.store.saved.settings.mode='all'
C_Spell={IsRangedAutoAttackSpell=function()return true end}
do local c=ns.store:Character();c.records=nil;c.recordsBackfilled=nil;ns.store:BackfillRecords()end
local lines={};local tip={rules={},ruleCount=0}
function tip:AddLine(s)lines[#lines+1]=s end
function tip:AddDoubleLine(a,b)lines[#lines+1]=a..' '..b end
ns.Titan.Render(tip);local rawText=table.concat(lines,'\n');local text=rawText:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','');assert(text:find('Green Bow',1,true));assert(text:find('60 / 60.0%',1,true));assert(text:find('40 / 40.0%',1,true));assert(text:find('Character lifetime 100',1,true));assert(text:find('Best fight / Best DPS (protected) 100 / 10.0',1,true),'protected record line missing');assert(not text:find('Weapon lifetime (all report periods) 100',1,true),'equal summaries repeated')
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
local report=ns.Reports.Build(ns.store,'all');local pages=ns.Reports.Pages(report);local count=0;for _,page in ipairs(pages)do for _,part in ipairs(page.groups)do count=count+#part.spells end end;assert(count==72 and #pages>1)
print('PASS Titan rendering, rarity links, shares, menu hiding and all-spell pagination')
local nativeOwner={}
function nativeOwner:EnableMouseWheel(v)self.wheel=v end
function nativeOwner:HookScript(event,fn)self.callback=fn;self.hooks=(self.hooks or 0)+1 end
ns.Titan.BindWheel(nativeOwner);ns.Titan.BindWheel(nativeOwner);assert(nativeOwner.wheel and nativeOwner.hooks==1)
local show=ns.Titan.Show;local called=false;ns.Titan.Show=function(owner)assert(owner==nativeOwner);called=true end
ns.Titan.page=1;nativeOwner.callback(nativeOwner,-1);assert(called and ns.Titan.page==2);ns.Titan.Show=show
print('PASS actual owner-frame wheel dispatch independent of LDB forwarding')
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

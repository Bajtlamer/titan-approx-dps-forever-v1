local ns={}
for _,f in ipairs({'Namespace','Capabilities','Settings','Style','Storage','SpellRules','WeaponAttribution','Records','Categories','Stats','Reports','Titan'})do assert(loadfile('TitanApproxDPS/'..f..'.lua'))('x',ns)end
C_Spell={IsRangedAutoAttackSpell=function()return true end}
local db=ns.Storage.Open({},'p');ns.store=db;db:Character().class='HUNTER'
local PROFILE='16:empty;17:empty;18:20:0'
db:Character().profiles[PROFILE]='|cff1eff00|Hitem:20:0|h[Green Bow]|h|r'
for i=1,2 do
 local spells={};local total=0
 for id=1,5 do spells[#spells+1]={spellID=id,origin='player',damage={value=100*id}};total=total+100*id end
 db:UpsertContribution({receiptID='f'..i,profile=PROFILE,mode='pve',damage=total,seconds=10,spells=spells})
end
db.saved.settings.mode='all'

-- a tooltip stub with real-looking font strings so level assignment can be inspected
local lines={}
local tip={}
function tip:GetName()return 'TT'end
function tip:NumLines()return #lines end
local function newLine(left,right,lr,lg,lb)
 local n=#lines+1
 local entry={left=left,right=right,rgb={lr,lg,lb}}
 lines[n]=entry
 local function fs(side)return {SetFontObject=function(_,font)entry[side]=font end}end
 _G['TTTextLeft'..n]=fs('leftFont');_G['TTTextRight'..n]=fs('rightFont')
end
function tip:AddLine(text,r,g,b)newLine(text,nil,r,g,b)end
function tip:AddDoubleLine(left,right,r,g,b)newLine(left,right,r,g,b)end
tip.rules={};tip.ruleCount=0
function tip:CreateTexture()return setmetatable({},{__index=function()return function()end end})end
ns.Titan.Render(tip)
local function strip(s)return (s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')end
local function find(text)for _,l in ipairs(lines)do if strip(l.left):find(text,1,true) then return l end end end
local all={};for _,l in ipairs(lines)do all[#all+1]=strip(l.left)..' '..strip(l.right)end;local text=table.concat(all,'\n')

-- no paging anywhere
assert(not text:find('Page ',1,true) and not text:find('Wheel',1,true),'paging text remains')
assert(ns.Titan.page==nil and ns.Titan.BindWheel==nil,'paging state remains')
-- every line was given a text level
for i,l in ipairs(lines)do
 if strip(l.left)~=' ' then assert(l.leftFont,'line '..i..' has no font: '..strip(l.left))end
end
-- hierarchy: key values large, rows normal, tips small
local life=find('Character lifetime');assert(life and life.rightFont=='TitanApproxDPSPrimary' and life.right:find('cffFFE680',1,true),'lifetime must be primary and lifetime colored')
local typical=find('Typical DPS');assert(typical and typical.rightFont=='TitanApproxDPSPrimary' and typical.right:find('cffFFB84D',1,true),'typical DPS primary and dps colored')
local confidence=find('2 fights');assert(confidence and confidence.leftFont=='TitanApproxDPSHint','confidence is a small hint')
assert(find('Scope:').leftFont=='TitanApproxDPSHint' and find('Right click').leftFont=='TitanApproxDPSHint','tips small')
local recent=find('Recent DPS');assert(recent and recent.leftFont=='GameTooltipText' and recent.right:find('cffFFB84D',1,true),'rows are body text')
-- value types have their own colors
local best=find('Best fight');assert(best and best.right:find('cffFF8000',1,true),'records use the record color')
local weaponLifetime=find('Weapon lifetime');assert(weaponLifetime and weaponLifetime.right:find('cffFFE680',1,true))
local auto=find('Auto-attacks');assert(auto and auto.right:find('cff74D5FF',1,true) and auto.right:find('cffF3A5CE',1,true),'damage and ability colors')
local heading=find('Green Bow');assert(heading and heading.right:find('cffABD473',1,true) and strip(heading.right)=='Ranged','category tag in its class color')
assert(heading.left:find('|cff1eff00',1,true),'item quality color from the link is kept')
-- all spells stay reachable: top three inline, the rest pointed to the menu
local spellLines=0;for _,l in ipairs(lines)do if strip(l.left):match('^Spell %d$') then spellLines=spellLines+1 end end
assert(spellLines==3,'inline spells limited to three, got '..spellLines)
local more=find('2 more spells');assert(more and more.leftFont=='TitanApproxDPSHint' and strip(more.left):find('Weapon results',1,true),'overflow hint')
-- the tooltip contains no emoji or em dashes
assert(not text:find('\226\128\148'),'em dash')
-- distinct color per value type
local seen={};for _,key in ipairs({'damage','ability','dps','percent','lifetime','record','good','bad','title','unavailable'})do local hex=ns.Style.colors[key];assert(not seen[hex],'duplicate color '..key);seen[hex]=key end
-- restoring styled shared-tooltip lines returns them to the Blizzard body font
local shared={lines={}};function shared:GetName()return 'ST'end;function shared:NumLines()return 2 end
local fonts={};for n=1,2 do for _,side in ipairs({'Left','Right'})do _G['ST'..'Text'..side..n]={SetFontObject=function(_,f)fonts[side..n]=f end}end end
ns.Style.Style(shared,'hint','hint',true);assert(fonts.Left2=='TitanApproxDPSHint')
ns.Style.Restore(shared);assert(fonts.Left2=='GameTooltipText' and fonts.Right2=='GameTooltipText' and shared.tadpsStyled==nil)
print('PASS Titan tooltip: no paging, three text levels, per-type colors, class-colored categories, spill-over to menu')

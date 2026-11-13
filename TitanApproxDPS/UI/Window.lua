local _,ns=...
local W={tab='Overview',page=1};ns.Window=W
local tabs={'Overview','Weapons','Spells','Pets','Compare','History','Data'}
local function button(parent,label,x,y,width,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(width,24);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',fn);return b
end
local function amount(v)return v and string.format('%.1f',v) or 'Unavailable' end
local function damageAmount(v)return ns.DamageNumber(v) end
function W.Refresh()
 if not W.frame or not W.frame:IsShown() or not ns.store then return end
 local c=ns.store:Character();if not c then W.text:SetText('Unsupported future database schema. Recording disabled.');return end
 local mode=ns.store.saved.settings.mode
 local lines={'Mode: '..mode..' | Completed fights only','Lifetime recorded damage: '..damageAmount(c.totalDamage),''}
 local rows=ns.Comparisons.Rows(ns.store,{combatMode=mode})
 if W.tab=='Pets' then lines[#lines+1]='Pet ownership and owner inclusion require live verification. Separate pet totals are unavailable.'
 elseif W.tab=='Data' then
  lines[#lines+1]='Recording: '..(ns.recorder.paused and 'Paused' or 'Enabled')
  lines[#lines+1]='Native meter: '..tostring(ns.capabilities.damage)..' | Spell API: '..tostring(ns.capabilities.spells)
  lines[#lines+1]='Crits, hit maxima and miss counts: unavailable from native summaries.'
  lines[#lines+1]='PvE/PvP classification: unknown until complete recipient evidence is validated.'
  lines[#lines+1]='Capture note: '..(ns.recorder.gap or 'No reported gap')
  lines[#lines+1]='Commands: /tadps pause, resume, export, import, method NAME'
 elseif W.tab=='History' then
  for i=#c.history,math.max(1,#c.history-19),-1 do local r=c.receipts[c.history[i]];if r then lines[#lines+1]=r.receiptID..' | '..r.mode..' | '..damageAmount(r.damage)..' damage | '..amount(r.seconds)..' seconds' end end
 elseif W.tab=='Spells' then
  local sums={};local timed={};local seconds=0
  for _,r in ipairs(rows)do seconds=seconds+r.seconds;for id,s in pairs(r.spells)do sums[id]=(sums[id] or 0)+s.damage;timed[id]=(timed[id] or 0)+(s.timedDamage or 0) end end
  local ids={};for id in pairs(sums)do ids[#ids+1]=id end;table.sort(ids,function(a,b)return sums[a]>sums[b]end)
  for _,id in ipairs(ids)do local name=C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or ('Spell '..id);lines[#lines+1]=name..' | damage '..damageAmount(sums[id])..' | per combat second '..amount(seconds>0 and timed[id]/seconds or nil)end
 elseif W.tab=='Compare' then
  lines[#lines+1]='Equipment-context comparison of the first two recorded sets:'
  if #rows>=2 then
   for i=1,2 do local r=rows[i];lines[#lines+1]=(c.profiles[r.profile] or r.profile)..' | '..amount(r.dps)..' damage/combat second | '..r.sessions..' sessions' end
   lines[#lines+1]='Observed difference: '..amount(rows[1].dps and rows[2].dps and rows[1].dps-rows[2].dps)
  else lines[#lines+1]='Record at least two loadouts for comparison.' end
  lines[#lines+1]='Pure-mode ranking requires 10 complete sessions, 120 seconds and verified mode.'
 else
  local groups=ns.Reports.Build(ns.store,mode).groups
  local start=(W.page-1)*8+1
  for i=start,math.min(#groups,start+7)do local g=groups[i]
   lines[#lines+1]=g.name..'\nClassified lifetime '..damageAmount(g.lifetimeDamage)..' | selected damage '..damageAmount(g.damage)..' | combat DPS '..amount(g.dps)
   lines[#lines+1]='Auto-attacks '..damageAmount(g.autoDamage)..' | abilities '..damageAmount(g.abilityDamage)
   for _,spell in ipairs(g.spells)do lines[#lines+1]='Spell '..spell.spellID..': '..damageAmount(spell.damage)..' ('..(spell.percent and string.format('%.1f%%',spell.percent) or 'Unavailable')..')'end
   lines[#lines+1]=''
  end
  if #groups==0 then lines[#lines+1]='No visible classified results in this mode.'end
  lines[#lines+1]='Page '..W.page
 end
 W.text:SetText(table.concat(lines,'\n'))
end
function W.Show(tab)
 if not W.frame then
  local f=CreateFrame('Frame','TitanApproxDPSWindow',UIParent,'BasicFrameTemplateWithInset');W.frame=f
  f:SetSize(940,650);f:SetPoint('CENTER');f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',f.StartMoving);f:SetScript('OnDragStop',f.StopMovingOrSizing);f.TitleText:SetText('Titan Approx DPS '..ns.version)
  if UISpecialFrames then table.insert(UISpecialFrames,'TitanApproxDPSWindow')end
  for i,name in ipairs(tabs)do button(f,name,12+(i-1)*130,-35,124,function()W.tab=name;W.page=1;W.Refresh()end)end
  for i,mode in ipairs({'pve','pvp','mixed','unknown'})do button(f,mode,12+(i-1)*110,-68,104,function()ns.store.saved.settings.mode=mode;W.page=1;W.Refresh()end)end
  button(f,'Previous',470,-68,100,function()W.page=math.max(1,W.page-1);W.Refresh()end)
  button(f,'Next',580,-68,100,function()W.page=W.page+1;W.Refresh()end)
  button(f,'Export',690,-68,100,function()ns.TransferView.Show(false)end)
  button(f,'Import',800,-68,100,function()ns.TransferView.Show(true)end)
  local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',16,-110);scroll:SetSize(880,510)
  local child=CreateFrame('Frame',nil,scroll);child:SetSize(860,1800);scroll:SetScrollChild(child)
  W.text=child:CreateFontString(nil,'OVERLAY','GameFontHighlight');W.text:SetPoint('TOPLEFT');W.text:SetWidth(850);W.text:SetJustifyH('LEFT');W.text:SetSpacing(5)
 end
 W.tab=tab or W.tab;W.frame:Show();W.Refresh()
end

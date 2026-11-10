local _,ns=...
ns.Titan={}
function ns.Titan.Initialize()
 local ldb=LibStub and LibStub:GetLibrary('LibDataBroker-1.1',true);if not ldb then return end
 ns.Titan.broker=ldb:NewDataObject('TitanApproxDPS',{type='data source',label='Approx DPS',text='Completed fights',icon='Interface\\Icons\\Ability_Warrior_Charge',OnClick=function(_,button)ns.Window.Show(button=='RightButton' and 'Data' or 'Overview')end,OnTooltipShow=function(tip)
  tip:AddLine('Titan Approx DPS - completed fights');local c=ns.store:Character();if not c then return end
  local rows=ns.Comparisons.Rows(ns.store,{combatMode=ns.store.saved.settings.mode})
  for i=1,math.min(12,#rows)do local r=rows[i];tip:AddLine('____________________________');tip:AddLine(c.profiles[r.profile] or r.profile);tip:AddLine(string.format('Damage %.0f | per combat second %s',r.damage,r.dps and string.format('%.1f',r.dps) or 'Unavailable'))end
  tip:AddLine('Open results for all profiles and modes.')
 end})
end

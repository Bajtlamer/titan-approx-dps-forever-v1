local _,ns=...
local M={};ns.Minimap=M
function M.Position()
 local s=ns.store.saved.settings;local a=math.rad(s.angle);local b=M.button
 b:ClearAllPoints();b:SetPoint('CENTER',Minimap,'CENTER',math.cos(a)*(Minimap:GetWidth()/2+22),math.sin(a)*(Minimap:GetHeight()/2+22))
end
function M.ResetPosition()ns.store.saved.settings.angle=155;M.Position()end
function M.Initialize()
 local s=ns.store.saved.settings
 if not s.minimapLayoutVersion or s.minimapLayoutVersion<1 then if s.angle==220 then s.angle=155 end;s.minimapLayoutVersion=1 end
 local b=CreateFrame('Button','TitanApproxDPSMinimapButton',UIParent);M.button=b;b:SetSize(32,32);b:SetFrameStrata('MEDIUM')
 local background=b:CreateTexture(nil,'BACKGROUND');background:SetTexture('Interface\\Minimap\\UI-Minimap-Background');background:SetSize(24,24);background:SetPoint('CENTER')
 local icon=b:CreateTexture(nil,'ARTWORK');M.icon=icon;icon:SetTexture('Interface\\Icons\\Ability_Warrior_Charge');icon:SetSize(20,20);icon:SetPoint('CENTER');icon:SetTexCoord(.08,.92,.08,.92)
 if b.CreateMaskTexture then local mask=b:CreateMaskTexture();if mask then mask:SetTexture('Interface\\CHARACTERFRAME\\TempPortraitAlphaMask');mask:SetAllPoints(icon);icon:AddMaskTexture(mask)end end
 local border=b:CreateTexture(nil,'OVERLAY');border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder');border:SetSize(54,54);border:SetPoint('TOPLEFT')
 b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton')
 b:SetScript('OnClick',function(_,button)if button=='RightButton'then ns.Titan.Menu(b)else ns.Titan.Hide();ns.Window.Toggle()end end)
 b:SetScript('OnEnter',function()ns.Titan.Show(b)end);b:SetScript('OnLeave',ns.Titan.Hide)
 b:SetScript('OnDragStart',function()b:SetScript('OnUpdate',function()local x,y=GetCursorPosition();local scale=Minimap:GetEffectiveScale();local cx,cy=Minimap:GetCenter();s.angle=(math.deg(math.atan2(y/scale-cy,x/scale-cx))+360)%360;M.Position()end)end)
 b:SetScript('OnDragStop',function()b:SetScript('OnUpdate',nil);M.Position()end);M.Position();b:SetShown(s.minimap)
end

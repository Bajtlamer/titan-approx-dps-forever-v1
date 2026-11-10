local _,ns=...
ns.Minimap={}
function ns.Minimap.Initialize()
 local s=ns.store.saved.settings
 local b=CreateFrame('Button','TitanApproxDPSMinimapButton',Minimap);ns.Minimap.button=b;b:SetSize(32,32);b:SetFrameStrata('MEDIUM');b:SetNormalTexture('Interface\\Icons\\Ability_Warrior_Charge');b:GetNormalTexture():SetTexCoord(.08,.92,.08,.92)
 local border=b:CreateTexture(nil,'OVERLAY');border:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder');border:SetSize(54,54);border:SetPoint('TOPLEFT')
 local function position()local a=math.rad(s.angle);b:ClearAllPoints();b:SetPoint('CENTER',Minimap,'CENTER',math.cos(a)*(Minimap:GetWidth()/2+8),math.sin(a)*(Minimap:GetHeight()/2+8))end
 b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton');b:SetScript('OnClick',function(_,button)ns.Window.Show(button=='RightButton' and 'Data' or 'Overview')end)
 b:SetScript('OnDragStart',function()b:SetScript('OnUpdate',function()local x,y=GetCursorPosition();local scale=Minimap:GetEffectiveScale();local cx,cy=Minimap:GetCenter();s.angle=(math.deg(math.atan2(y/scale-cy,x/scale-cx))+360)%360;position()end)end)
 b:SetScript('OnDragStop',function()b:SetScript('OnUpdate',nil);position()end);position();b:SetShown(s.minimap)
end

local ns={};local created={}
local function object()
 return setmetatable({scripts={}}, {__index=function(_,k)
  if k=='CreateTexture' or k=='CreateMaskTexture'then return function()local r=object();created[#created+1]=r;return r end end
  if k=='SetSize'then return function(s,w,h)s.width=w;s.height=h end end
  if k=='SetScript'then return function(s,key,fn)s.scripts[key]=fn end end
  if k=='SetPoint'then return function(s,...)s.point={...}end end
  if k=='GetWidth' or k=='GetHeight'then return function()return 140 end end
  return function()end
 end})
end
CreateFrame=function()return object()end;Minimap=object();UIParent=object();ns.store={saved={settings={angle=220,minimap=true}}};ns.Titan={Show=function()end,Hide=function()end}
assert(loadfile('TitanApproxDPS/Minimap.lua'))('x',ns);ns.Minimap.Initialize()
assert(ns.Minimap.icon and ns.Minimap.icon.width==20,'full-size square icon remains');assert(ns.store.saved.settings.angle~=220,'old default overlaps minimap controls');assert(ns.Minimap.ResetPosition)
ns.store.saved.settings.angle=20;ns.Minimap.ResetPosition();assert(ns.store.saved.settings.angle==155)
print('PASS compact masked minimap icon and resettable separated position')

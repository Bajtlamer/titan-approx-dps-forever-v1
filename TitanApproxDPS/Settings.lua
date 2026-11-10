local _,ns=...
ns.Settings={}
function ns.Settings.Normalize(t)
 t=type(t)=='table' and t or {}
 return {recording=t.recording~=false,minimap=t.minimap~=false,angle=ns.Number(t.angle) and t.angle or 220,mode=({pve=true,pvp=true,mixed=true,unknown=true})[t.mode] and t.mode or 'unknown'}
end

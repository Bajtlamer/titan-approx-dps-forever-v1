local _,ns=...
ns.Settings={}
function ns.Settings.Normalize(t)
 t=type(t)=='table' and t or {}
 return {recording=t.recording~=false,minimap=t.minimap~=false,angle=ns.Number(t.angle) and t.angle or 155,minimapLayoutVersion=t.minimapLayoutVersion or 0,mode=({all=true,pve=true,pvp=true,mixed=true,unknown=true})[t.mode] and t.mode or 'all'}
end

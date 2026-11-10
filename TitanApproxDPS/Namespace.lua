local _,ns=...
ns.version='0.1.0-alpha'
function ns.Copy(t)
 if type(t)~='table' then return t end
 local r={};for k,v in pairs(t)do r[k]=ns.Copy(v)end;return r
end
function ns.Number(v) return type(v)=='number' and v==v and v>=0 and v<math.huge end
function ns.Available(v)return {state='available',value=v}end
function ns.Missing(reason)return {state='unavailable',reason=reason}end

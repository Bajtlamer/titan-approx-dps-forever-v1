local _,ns=...
ns.Comparisons={}
function ns.Comparisons.Rows(store,q)
 local rows={};local c=store:Character();if not c then return rows end
 for _,r in pairs(c.rows or {})do if r.mode==q.combatMode then local x=ns.Copy(r);x.dps=r.seconds>0 and (r.timedDamage or 0)/r.seconds or nil;x.eligible=r.sessions>=10 and r.seconds>=120 and (r.mode=='pve' or r.mode=='pvp');rows[#rows+1]=x end end
 table.sort(rows,function(a,b)if a.damage==b.damage then return a.profile<b.profile end;return a.damage>b.damage end);return rows
end

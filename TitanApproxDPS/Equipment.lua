local _,ns=...
ns.Equipment={}
function ns.Equipment.New(api)
 return {Snapshot=function()
  local slots={};local names={};local complete=true
  for _,slot in ipairs({16,17,18})do
   local ok,id=pcall(api.GetInventoryItemID,'player',slot)
   if not ok or not ns.Capabilities.IsPublic(id,api) then complete=false;slots[#slots+1]=slot..':unknown'
   elseif id==nil then slots[#slots+1]=slot..':empty'
   elseif ns.Number(id) then
    local linkOK,link=pcall(api.GetInventoryItemLink,'player',slot)
    if linkOK and ns.Capabilities.IsPublic(link,api) and type(link)=='string' then slots[#slots+1]=slot..':'..(link:match('item:([^|]+)') or id);names[#names+1]=link else slots[#slots+1]=slot..':'..id;names[#names+1]='Item '..id;complete=false end
   else complete=false;slots[#slots+1]=slot..':unknown' end
  end
  return {id=table.concat(slots,';'),name=#names>0 and table.concat(names,' / ') or 'Unarmed / unreadable equipment',complete=complete}
 end}
end

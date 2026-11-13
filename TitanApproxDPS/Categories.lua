local _,ns=...
-- Damage categories shown separately everywhere: melee, ranged, spell, pet, other.
local C={};ns.Categories=C
local byCategory={summon='pet',form='melee',shield='melee',ambiguous_melee='melee',spell='spell'}
local labels={melee='Melee',ranged='Ranged',spell='Spells',pet='Pet',other='Other'}
C.Order={'melee','ranged','spell','pet','other'}
-- part is a WeaponAttribution.Split group: either a weapon slot or a named category.
function C.Of(part)
 if part.slot==16 or part.slot==17 then return 'melee' end
 if part.slot==18 then return 'ranged' end
 return byCategory[part.category] or 'other'
end
function C.Label(kind)return labels[kind] or labels.other end

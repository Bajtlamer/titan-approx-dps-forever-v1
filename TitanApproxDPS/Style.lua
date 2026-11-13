local _,ns=...
-- Shared colors and three text levels. Colors follow Blizzard conventions where one
-- exists: gold for titles, white for labels, item quality colors for items (taken from
-- item links), green for gains, red for losses, grey for unavailable data, class colors
-- for damage categories. Every type of value has its own color.
local S={};ns.Style=S
S.colors={
 title='FFD100',      -- Blizzard normal (gold): titles and key metric labels
 label='E6E6E6',      -- row labels
 hint='B8B8B8',       -- tips and explanations (small, light)
 unavailable='9D9D9D',-- Blizzard poor (grey)
 separator='808080',
 damage='74D5FF',
 ability='F3A5CE',
 dps='FFB84D',
 percent='7FD694',
 lifetime='FFE680',
 record='FF8000',     -- Blizzard legendary orange: protected best values
 good='1EFF00',       -- Blizzard uncommon green
 bad='FF4040',
 warning='CC9944',
 confidence={high='1EFF00',medium='FFD100',low='9D9D9D',none='9D9D9D'},
 kind={melee='C79C6E',ranged='ABD473',spell='9482C9',pet='00FF96',other='9D9D9D'}, -- class colors
}
function S.rgb(hex)
 return tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255
end
function S.Color(text,hex)return '|cff'..hex..text..'|r' end

-- Text levels. Primary: key values, large. Body: ordinary rows. Hint: tips, small and light.
local levels={primary='TitanApproxDPSPrimary',body='GameTooltipText',hint='TitanApproxDPSHint',title='GameTooltipHeaderText'}
local created
local function ensureFonts()
 if created or type(_G.CreateFont)~='function' then return end
 created=true
 local source=_G.GameTooltipText
 local path,_,flags
 if source and source.GetFont then path,_,flags=source:GetFont()end
 if not path then return end
 local primary=_G.CreateFont(levels.primary);primary:SetFont(path,18,flags or '')
 local hint=_G.CreateFont(levels.hint);hint:SetFont(path,10,flags or '')
end
function S.Font(level)ensureFonts();return levels[level] or levels.body end

-- Apply a text level to the last added tooltip line. Safe on any tooltip stub.
function S.Style(tip,level,rightLevel,track)
 local name=tip.GetName and tip:GetName();local n=tip.NumLines and tip:NumLines()
 if not name or not n then return end
 local left,right=_G[name..'TextLeft'..n],_G[name..'TextRight'..n]
 if left and left.SetFontObject then left:SetFontObject(S.Font(level))end
 if right and right.SetFontObject then right:SetFontObject(S.Font(rightLevel or level))end
 if track then tip.tadpsStyled=tip.tadpsStyled or {};tip.tadpsStyled[#tip.tadpsStyled+1]=n end
end
-- Restore lines styled on a shared tooltip so Blizzard text is never left in small type.
function S.Restore(tip)
 local name=tip.GetName and tip:GetName()
 if name and tip.tadpsStyled then
  for _,n in ipairs(tip.tadpsStyled)do
   for _,side in ipairs({'TextLeft','TextRight'})do local f=_G[name..side..n];if f and f.SetFontObject then f:SetFontObject(levels.body)end end
  end
 end
 tip.tadpsStyled=nil
end

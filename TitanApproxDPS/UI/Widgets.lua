local _,ns=...
-- Frame helpers for the results window: buttons, menu-driven drop-downs, a search
-- box and a scrollable list with its own scroll bar. Only core frame types are used,
-- so nothing depends on a particular Blizzard template beyond the ones the addon
-- already uses (UIPanelButtonTemplate).
local Wd={};ns.Widgets=Wd
local S=ns.Style

function Wd.Button(parent,label,width,height,onClick)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
 b:SetSize(width,height or 24);b:SetText(label);b:SetScript('OnClick',onClick)
 return b
end

function Wd.Text(parent,level,hex,justify)
 local fs=parent:CreateFontString(nil,'OVERLAY')
 fs:SetFontObject(S.Font(level or 'body'))
 if hex then local r,g,b=S.rgb(hex);fs:SetTextColor(r,g,b)end
 fs:SetJustifyH(justify or 'LEFT')
 return fs
end

-- Drop-down: a button that opens the native context menu with one radio per option.
-- Without MenuUtil it cycles through the options on click.
function Wd.Dropdown(parent,width,prefix,getOptions,onSelect)
 local dd={prefix=prefix}
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');dd.button=b
 b:SetSize(width,24)
 function dd:SetValue(label)self.value=label;b:SetText(prefix..': '..tostring(label))end
 b:SetScript('OnClick',function(self)
  local options,current=getOptions()
  if MenuUtil and MenuUtil.CreateContextMenu then
   MenuUtil.CreateContextMenu(self,function(_,root)
    if root.SetScrollMode then root:SetScrollMode(350)end
    for _,o in ipairs(options)do
     local key=o.key
     root:CreateRadio(o.label,function()return key==current end,function()onSelect(key)end)
    end
   end)
  else
   local index=0;for i,o in ipairs(options)do if o.key==current then index=i end end
   local nextOption=options[(index % #options)+1];if nextOption then onSelect(nextOption.key)end
  end
 end)
 return dd
end

function Wd.SearchBox(parent,width,placeholder,onChange)
 local ok,e=pcall(CreateFrame,'EditBox',nil,parent,'InputBoxTemplate')
 if not ok or not e then e=CreateFrame('EditBox',nil,parent)end
 e:SetSize(width,22);e:SetAutoFocus(false);e:SetFontObject(S.Font('body'));e:SetMaxLetters(60)
 local hint=Wd.Text(e,'hint',S.colors.hint);hint:SetPoint('LEFT',e,'LEFT',6,0);hint:SetText(placeholder)
 local function refreshHint()if e:GetText()=='' then hint:Show()else hint:Hide()end end
 e:SetScript('OnTextChanged',function(self)refreshHint();onChange(self:GetText())end)
 e:SetScript('OnEscapePressed',function(self)self:SetText('');self:ClearFocus()end)
 e:SetScript('OnEnterPressed',function(self)self:ClearFocus()end)
 return e
end

local HEADER=22
-- Scrollable, virtualized list. Rows are pooled buttons, the scroll bar is a Slider.
function Wd.List(parent,options)
 options=options or {}
 local list={rowHeight=options.rowHeight or 20,offset=0,pool={},headers={},columns={},rows={},visible=0,widths={}}
 local f=CreateFrame('Frame',nil,parent);list.frame=f
 if f.SetClipsChildren then f:SetClipsChildren(true)end
 local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(0,0,0,.3)
 list.empty=Wd.Text(f,'hint',S.colors.hint,'CENTER');list.empty:SetPoint('CENTER',f,'CENTER',0,0);list.empty:SetWidth(520);list.empty:Hide()
 local slider=CreateFrame('Slider',nil,f);list.slider=slider
 slider:SetOrientation('VERTICAL');slider:SetWidth(12);slider:SetMinMaxValues(0,0);slider:SetValueStep(1)
 if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true)end
 local track=slider:CreateTexture(nil,'BACKGROUND');track:SetAllPoints();track:SetColorTexture(1,1,1,.08)
 local thumb=slider:CreateTexture(nil,'OVERLAY');thumb:SetColorTexture(.85,.85,.85,.55);thumb:SetSize(12,36);slider:SetThumbTexture(thumb)

 local function color(cell)
  local text=cell.text
  if text:find('|c',1,true)then return text end
  return S.Color(text,S.CellColor(cell.kind))
 end
 local function render()
  for i,row in ipairs(list.pool)do
   local data=list.rows[list.offset+i]
   if i<=list.visible and data then
    row.data=data;row:Show()
    for c,col in ipairs(list.columns)do
     local fs=row.cells[c]
     if not fs then
      fs=Wd.Text(row,'body');fs:SetWordWrap(false);row.cells[c]=fs
     end
     local x=list.widths[c].x
     fs:ClearAllPoints();fs:SetPoint('LEFT',row,'LEFT',x,0);fs:SetWidth(list.widths[c].w-6);fs:SetJustifyH(col.align=='right' and 'RIGHT' or 'LEFT')
     local cell=data.cells[c];fs:SetText(cell and color(cell) or '');fs:Show()
    end
    for c=#list.columns+1,#row.cells do row.cells[c]:Hide()end
    if data.key==list.selected then row.selected:Show()else row.selected:Hide()end
   else row.data=nil;row:Hide()end
  end
 end
 list.Render=render
 local function ensureRows()
  for i=#list.pool+1,list.visible do
   local row=CreateFrame('Button',nil,f);row:SetHeight(list.rowHeight);row.cells={}
   row:SetPoint('TOPLEFT',f,'TOPLEFT',0,-HEADER-(i-1)*list.rowHeight);row:SetPoint('RIGHT',f,'RIGHT',-14,0)
   row:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
   local sel=row:CreateTexture(nil,'BACKGROUND');sel:SetAllPoints();sel:SetColorTexture(.25,.45,.7,.35);sel:Hide();row.selected=sel
   row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',function(_,delta)list:Scroll(-delta*3)end)
   row:SetScript('OnClick',function(self)if self.data and list.onSelect then list.onSelect(self.data.key)end end)
   list.pool[i]=row
  end
 end
 local function updateRange()
  local max=math.max(0,#list.rows-list.visible)
  if list.offset>max then list.offset=max end
  list.updating=true;slider:SetMinMaxValues(0,max);slider:SetValue(list.offset);list.updating=false
  if max>0 then slider:Show()else slider:Hide()end
 end
 function list:Scroll(amount)
  local max=math.max(0,#self.rows-self.visible)
  self.offset=math.max(0,math.min(max,self.offset+amount))
  self.updating=true;slider:SetValue(self.offset);self.updating=false
  render()
 end
 slider:SetScript('OnValueChanged',function(_,value)
  if list.updating then return end
  list.offset=math.floor(value+.5);render()
 end)
 f:EnableMouseWheel(true);f:SetScript('OnMouseWheel',function(_,delta)list:Scroll(-delta*3)end)

 function list:SetBox(x,y,width,height)
  f:ClearAllPoints();f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);f:SetSize(width,height)
  slider:ClearAllPoints();slider:SetPoint('TOPRIGHT',f,'TOPRIGHT',-1,-HEADER);slider:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-1,2)
  self.width=width;self.visible=math.max(1,math.floor((height-HEADER)/self.rowHeight))
  ensureRows();updateRange();self:Layout();render()
 end
 -- Columns fill the available width in proportion to their nominal widths.
 function list:Layout()
  local total=0;for _,col in ipairs(self.columns)do total=total+col.width end
  local available=(self.width or 600)-18
  local x=4;self.widths={}
  for i,col in ipairs(self.columns)do
   local w=total>0 and col.width*available/total or col.width
   self.widths[i]={x=x,w=w};x=x+w
   local h=self.headers[i]
   if not h then
    h=CreateFrame('Button',nil,f);h:SetHeight(HEADER);h.label=Wd.Text(h,'body',S.colors.title);h.label:SetAllPoints()
    h:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight')
    h.index=i;self.headers[i]=h
    h:SetScript('OnClick',function(self2)local col2=list.columns[self2.index];if col2 and list.onSort then list.onSort(col2.key)end end)
   end
   h:ClearAllPoints();h:SetPoint('TOPLEFT',f,'TOPLEFT',self.widths[i].x,0);h:SetWidth(w);h:Show()
   h.label:SetJustifyH(col.align=='right' and 'RIGHT' or 'LEFT')
   local active=self.sortKey==col.key
   h.label:SetText(S.Color(col.label..(active and (self.sortDesc and ' (desc)' or ' (asc)') or ''),active and S.colors.title or S.colors.label))
  end
  for i=#self.columns+1,#self.headers do self.headers[i]:Hide()end
 end
 function list:SetData(columns,rows,selected,sortKey,sortDesc,emptyText)
  self.columns=columns;self.rows=rows;self.selected=selected;self.sortKey=sortKey;self.sortDesc=sortDesc
  if emptyText and #rows==0 then self.empty:SetText(emptyText);self.empty:Show()else self.empty:Hide()end
  updateRange();self:Layout();render()
 end
 return list
end

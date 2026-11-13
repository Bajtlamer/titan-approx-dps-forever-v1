local _,ns=...
ns.TransferView={}
function ns.TransferView.Show(import)
 if InCombatLockdown()then ns.Print('Transfer is available outside combat.');return end
 local v=ns.TransferView
 if not v.frame then
  local f=CreateFrame('Frame','TitanApproxDPSTransfer',UIParent,'BasicFrameTemplateWithInset');v.frame=f;f:SetSize(800,560);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f.TitleText:SetText('Statistics transfer');if UISpecialFrames then table.insert(UISpecialFrames,'TitanApproxDPSTransfer')end
  local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',15,-65);scroll:SetSize(745,410)
  local e=CreateFrame('EditBox',nil,scroll);v.editor=e;e:SetMultiLine(true);e:SetFontObject('ChatFontNormal');e:SetWidth(720);e:SetHeight(2000);e:SetAutoFocus(false);e:SetMaxLetters(16000);scroll:SetScrollChild(e)
  v.status=f:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');v.status:SetPoint('TOPLEFT',15,-35);v.status:SetWidth(760);v.status:SetJustifyH('LEFT')
  local b=CreateFrame('Button',nil,f,'UIPanelButtonTemplate');b:SetSize(220,25);b:SetPoint('BOTTOMLEFT',15,20);b:SetText('Validate / confirm restore')
  b:SetScript('OnClick',function()
   if not v.import or InCombatLockdown()then return end
   if not v.preview then local p,err=ns.Transfer.Stage(e:GetText(),ns.store);v.preview=p;v.status:SetText(p and ('Restore from '..tostring(p.source)..' to this character. Click again to restore reports. Character lifetime cannot decrease; a backup is retained.') or err)
   else local ok,err=ns.Transfer.Apply(v.preview,ns.store);v.preview=nil;if ok then ns.Rebaseline();ns.Window.Refresh();ns.Titan.Refresh();v.status:SetText('Restored. Previous statistics retained as backup.')else v.status:SetText(err)end end
  end)
  e:SetScript('OnTextChanged',function()v.preview=nil end)
 end
 v.import=import;v.preview=nil;v.frame:Show()
 if import then v.editor:SetText('');v.status:SetText('Paste migration JSON. Validate first, then confirm replacement. No data is executed.')
 else
  local ok,text=pcall(ns.Transfer.Export,ns.store)
  if not ok or #text>15000 then v.editor:SetText('');v.status:SetText('Snapshot exceeds this alpha copy limit or is unsupported. SavedVariables remain intact; multipart transfer is pending.')
  else v.editor:SetText(text);v.editor:SetFocus();v.editor:HighlightText();v.status:SetText('Copy JSON with Ctrl+C / Cmd+C. Includes character identity. This is a frozen snapshot.')end
 end
end

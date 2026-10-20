--!strict
-- Logical availability belongs to the caller; minimization only changes presentation.
local Gui=game:GetService('GuiService')
local Panels={}

function Panels.attach(screen,panel,surface,key,title,mode)
 local open,minimized=false,false
 local previousFocus=nil
 local connections={}
 local minimize=Instance.new('TextButton')
 minimize.Name,minimize.Text='MinimizePanel','−'
 minimize.Position,minimize.Size=UDim2.new(1,-48,0,0),UDim2.fromOffset(44,44)
 minimize.BackgroundColor3,minimize.TextColor3=Color3.fromRGB(54,66,68),Color3.fromRGB(246,240,223)
 minimize.Font,minimize.TextSize,minimize.BorderSizePixel=Enum.Font.GothamBold,24,0
 minimize.ZIndex,minimize.Parent=panel.ZIndex+5,panel
 local restore=minimize:Clone()
 restore.Name,restore.Text,restore.TextSize='Restore'..key,'Open '..title,12
 restore.ZIndex,restore.Visible,restore.Parent=80,false,screen
 local controller={button=minimize,restoreButton=restore}
 local function focusable(button)
  if not button or not button:IsA('GuiButton')or not button.Parent or not button.Active or not button.Selectable then return false end
  local current=button
  while current and current~=screen do
   if current:IsA('GuiObject')and not current.Visible then return false end
   current=current.Parent
  end
  return current==screen
 end
 function controller:ownsSelection()
  local selected=Gui.SelectedObject
  return selected~=nil and (selected==restore or selected:IsDescendantOf(surface))
 end
 local function layout()
  if mode=='selector'then
   restore.AnchorPoint,restore.Position=Vector2.new(.5,0),UDim2.new(.5,0,0,16)
   restore.Size=UDim2.fromOffset(180,44)
  elseif mode=='context'then
   local hud=screen:FindFirstChild('SettlementHUD')
   local gap=if screen.AbsoluteSize.X<500 and screen.AbsoluteSize.Y<500 then 1 else 8
   local y=if hud then hud.AbsolutePosition.Y-screen.AbsolutePosition.Y+hud.AbsoluteSize.Y+gap else 16
   restore.AnchorPoint,restore.Position=Vector2.zero,UDim2.fromOffset(16,y)
   restore.Size=UDim2.fromOffset(if screen.AbsoluteSize.X<500 then 96 else 160,44)
  else
   restore.AnchorPoint,restore.Position=surface.AnchorPoint,surface.Position
   restore.Size=UDim2.fromOffset(math.min(180,math.max(44,surface.AbsoluteSize.X)),44)
  end
 end
 local function render()
  surface:SetAttribute('PanelOpen',open)
  surface:SetAttribute('PanelMinimized',minimized)
  surface.Visible=open and not minimized
  restore.Visible=open and minimized
  layout()
 end
 function controller:isOpen()return open end
 function controller:setVisible(value)
  if not value and self:ownsSelection()then Gui.SelectedObject=nil end
  open=value==true;render()
 end
 function controller:minimize()
  if not open then return end
  local selected=Gui.SelectedObject
  local hadFocus=selected~=nil and selected:IsDescendantOf(surface)
  if hadFocus then previousFocus=selected end
  minimized=true;render()
  if hadFocus then Gui.SelectedObject=restore end
 end
 function controller:restore()
  local hadFocus=Gui.SelectedObject==restore
  minimized=false;render()
  if open and hadFocus then Gui.SelectedObject=if focusable(previousFocus)then previousFocus else minimize end
 end
 table.insert(connections,minimize.Activated:Connect(function()controller:minimize()end))
 table.insert(connections,restore.Activated:Connect(function()controller:restore()end))
 for _,name in {'AbsoluteSize','Position','AnchorPoint'}do
  table.insert(connections,surface:GetPropertyChangedSignal(name):Connect(layout))
 end
 table.insert(connections,screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout))
 local hud=screen:FindFirstChild('SettlementHUD')
 if mode=='context'and hud then
  table.insert(connections,hud:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout))
 end
 surface.Destroying:Connect(function()
  if controller:ownsSelection()then Gui.SelectedObject=nil end
  for _,connection in connections do connection:Disconnect()end
  restore:Destroy()
 end)
 render()
 return controller
end

function Panels.available(surface)
 local logical=surface:GetAttribute('PanelOpen')
 return if logical==nil then surface.Visible else logical==true
end
return Panels

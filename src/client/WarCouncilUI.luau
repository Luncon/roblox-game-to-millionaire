--!strict
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Gui=game:GetService('GuiService')
local Config=require(Replicated.Shared.FormationConfig)
local Panels=require(script.Parent.PanelVisibility)
local UI={}
function UI.start(screen)
 local player=Players.LocalPlayer
 local overlay=Instance.new('Frame');overlay.Name='CouncilOverlay';overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.new(0,0,0);overlay.BackgroundTransparency=.35;overlay.Active=true
 overlay.Visible=false;overlay.ZIndex=20;overlay.Parent=screen
 local panel=Instance.new('Frame');panel.Name='WarCouncil';panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-32,0,286)
 panel.BackgroundColor3=Color3.fromRGB(34,41,40);panel.ZIndex=21;panel.Parent=overlay
 local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(420,286);limit.Parent=panel
 local function text(name,y,height,size)
  local t=Instance.new('TextLabel');t.Name=name;t.Position=UDim2.fromOffset(16,y)
  t.Size=UDim2.new(1,-32,0,height);t.BackgroundTransparency=1;t.TextWrapped=true
  t.Font=Enum.Font.GothamBold;t.TextSize=size;t.TextColor3=Color3.fromRGB(255,239,191)
  t.ZIndex=22;t.Parent=panel;return t
 end
 local heading=text('Heading',12,28,20);heading.Text='WAR COUNCIL';heading.Size=UDim2.new(1,-88,0,28)
 local description=text('FormationDescription',48,100,14)
 local status=text('SelectionStatus',150,32,12)
 local function button(name,label,y,color)
  local b=Instance.new('TextButton');b.Name=name;b.Text=label;b.Position=UDim2.fromOffset(16,y)
  b.Size=UDim2.new(1,-32,0,40);b.BackgroundColor3=color;b.TextColor3=Color3.fromRGB(255,247,224)
  b.Font=Enum.Font.GothamBold;b.TextSize=14;b.ZIndex=22;b.Parent=panel;return b
 end
 local select=button('SelectShieldwall','Select Spartan Shieldwall',188,Color3.fromRGB(113,91,44))
 local close=button('CloseCouncil','Close',234,Color3.fromRGB(80,98,77))
 local visibility=Panels.attach(screen,panel,overlay,'Council','council','context')
 local map,previousFocus,remote,busy=nil,nil,nil,false
 local function hide()
  local focused=visibility:ownsSelection()
  visibility:setVisible(false);map=nil
  if focused then Gui.SelectedObject=previousFocus end
 end
 close.Activated:Connect(hide)
 local function render()
  local definition=Config.forCivilization(player:GetAttribute('CivilizationId'))
  local unlocked=player:GetAttribute('FormationLevel')==1
  local chosen=definition and player:GetAttribute('SelectedFormation')==definition.id
  description.Text=if definition then string.upper(definition.name)..'\n'..definition.description..'\nGather all five in camp, then March Formation.'
   else 'No formations available for this civilization yet.\nYour War Council is ready for future formations.'
  select.Visible=definition~=nil
  select.Active=definition~=nil and unlocked and not busy;select.Selectable=select.Active
  select.Text=if busy then 'Selecting…' elseif chosen then definition.name..' Selected' elseif unlocked and definition then 'Select '..definition.name else 'Unlock formation at the council pad'
  status.Text=if chosen then 'Selected · Advance abandons the formation.' elseif unlocked then 'Choose a formation before marching.' else 'Formation training is not purchased.'
 end
 select.Activated:Connect(function()
  if busy or not remote or not select.Active then return end
  busy=true;render()
  local definition=Config.forCivilization(player:GetAttribute('CivilizationId'))
  local ok,result=pcall(function()return remote:InvokeServer('formation',definition.id)end)
  busy=false;render()
  if not ok or not result.ok then status.Text='Selection unavailable. Stay near your map table.'else status.Text='Selected. Gather your army in the training camp.'end
 end)
 for _,name in {'CivilizationId','FormationLevel','SelectedFormation'}do player:GetAttributeChangedSignal(name):Connect(function()
  if name=='CivilizationId' then hide()end;render()
 end)end
 game:GetService('RunService').Heartbeat:Connect(function()
  if not visibility:isOpen()then return end
  local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
  if not Panels.available(screen.SettlementHUD) or not map or not map:IsDescendantOf(workspace) or not root or not hum or hum.Health<=0 or (root.Position-map.Position).Magnitude>14 then hide()end
 end)
 task.spawn(function()
  local folder=Replicated:WaitForChild('ArmyRemotes',15);if not folder then return end
  remote=folder:WaitForChild('Request',15)
  folder:WaitForChild('CouncilOpened').OnClientEvent:Connect(function(data)
   if data.civilizationId~=player:GetAttribute('CivilizationId')or not Panels.available(screen.SettlementHUD)then return end
   map=data.map;previousFocus=Gui.SelectedObject;render();visibility:restore();visibility:setVisible(true)
   if game:GetService('UserInputService').GamepadEnabled then Gui.SelectedObject=if select.Active then select else close end
  end)
 end)
 render()
end
return UI

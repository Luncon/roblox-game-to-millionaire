--!strict
local Players=game:GetService('Players')
local Replicated=game:GetService('ReplicatedStorage')
local Gui=game:GetService('GuiService')
local Recruitment=require(Replicated.Shared.ArmyRecruitment)
local Panels=require(script.Parent.PanelVisibility)
local UI={}

function UI.start(screen)
 local player=Players.LocalPlayer
 local overlay=Instance.new('Frame');overlay.Name='RecruitmentOverlay';overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.new(0,0,0);overlay.BackgroundTransparency=.3;overlay.Active=true
 overlay.Visible=false;overlay.ZIndex=30;overlay.Parent=screen
 local panel=Instance.new('Frame');panel.Name='BarracksRecruitment';panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-32,1,-32)
 panel.BackgroundColor3=Color3.fromRGB(34,41,40);panel.ZIndex=31;panel.Parent=overlay
 local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(460,430);limit.Parent=panel
 local function label(parent,name,text,y,height,size)
  local t=Instance.new('TextLabel');t.Name,t.Text=name,text;t.Position=UDim2.fromOffset(16,y)
  t.Size=UDim2.new(1,-32,0,height);t.BackgroundTransparency=1;t.TextWrapped=true
  t.TextXAlignment=Enum.TextXAlignment.Left;t.Font=Enum.Font.GothamBold;t.TextSize=size or 14
  t.TextColor3=Color3.fromRGB(255,239,191);t.ZIndex=33;t.Parent=parent;return t
 end
 local heading=label(panel,'Heading','BARRACKS · RECRUITMENT',10,32,14);heading.Size=UDim2.new(1,-132,0,32)
 local body=Instance.new('ScrollingFrame');body.Name='Composition';body.Position=UDim2.fromOffset(0,52)
 body.Size=UDim2.new(1,0,1,-114);body.CanvasSize=UDim2.fromOffset(0,300)
 body.BackgroundTransparency=1;body.BorderSizePixel=0;body.ScrollBarThickness=5;body.ZIndex=32;body.Parent=panel
 local capacity=label(body,'Capacity','',0,32,13)
 local rows={};local draft={melee=0,ranged=0,medic=0}
 local remote,board,previousFocus,busy=nil,nil,nil,false
 local function state()
  return {barracksLevel=player:GetAttribute('BarracksUpgradeLevel') or 1,
   armyCampLevel=player:GetAttribute('ArmyCampLevel') or 0,hospitalLevel=player:GetAttribute('HospitalLevel') or 0,
   extraTroopClass=player:GetAttribute('ExtraTroopClass') or 'warrior',recruitMelee=player:GetAttribute('RecruitMelee'),
   recruitRanged=player:GetAttribute('RecruitRanged'),recruitMedic=player:GetAttribute('RecruitMedic')}
 end
 local function button(parent,name,text,position,size)
  local b=Instance.new('TextButton');b.Name,b.Text,b.Position,b.Size=name,text,position,size
  b.BackgroundColor3=Color3.fromRGB(80,98,77);b.TextColor3=Color3.fromRGB(255,247,224)
  b.Font,b.TextSize,b.ZIndex,b.Parent=Enum.Font.GothamBold,16,33,parent;return b
 end
 local apply=button(panel,'ApplyComposition','Save Composition',UDim2.new(0,16,1,-54),UDim2.new(1,-32,0,44))
 local close=button(panel,'CloseRecruitment','X',UDim2.new(1,-52,0,8),UDim2.fromOffset(40,40))
 local visibility=Panels.attach(screen,panel,overlay,'Recruitment','Barracks','context')
 visibility.button.Position=UDim2.new(1,-100,0,8)
 local feedback=label(body,'RecruitmentFeedback','Changes apply to future spawns. Living troops keep their class and health.',222,48,12)
 local living=label(body,'LivingComposition','',274,26,12)
 local function render()
  local s=state();local cap=Recruitment.capacity(s)
  local writable=player:GetAttribute('ProgressStatus')=='ready' or player:GetAttribute('ProgressStatus')=='saving'
  capacity.Text=string.format('Fighters: %d / %d selected · Medic: %d / %d',draft.melee+draft.ranged,cap,draft.medic,s.hospitalLevel)
  for key,row in rows do
   row.value.Text=tostring(draft[key])
   for direction,b in row.buttons do
    local candidate=table.clone(draft);candidate[key]+=direction
    b.Active=not busy and writable and Recruitment.valid(s,candidate);b.Selectable=b.Active
    b.BackgroundTransparency=if b.Active then 0 else .65
   end
   row.title.Text=if key=='ranged' and s.barracksLevel<4 then 'Ranged · Barracks IV' elseif key=='medic' and s.hospitalLevel==0 then 'Medic · Build Hospital' else ({melee='Melee',ranged='Ranged',medic='Medic'})[key]
  end
  apply.Active=not busy and writable and Recruitment.valid(s,draft);apply.Selectable=apply.Active
  apply.Text=if busy then 'Saving…' else 'Save Composition'
  living.Text=string.format('Living now: %d melee · %d ranged · %d medic',player:GetAttribute('WarriorCount') or 0,player:GetAttribute('RangedCount') or 0,player:GetAttribute('MedicCount') or 0)
 end
 for index,key in {'melee','ranged','medic'}do
  local y=34+(index-1)*62
  local title=label(body,key..'Title','',y,44,14);title.Size=UDim2.new(1,-186,0,44)
  local minus=button(body,key..'Minus','−',UDim2.new(1,-164,0,y),UDim2.fromOffset(44,44))
  local value=label(body,key..'Count','0',y,44,18);value.Position=UDim2.new(1,-114,0,y);value.Size=UDim2.fromOffset(42,44);value.TextXAlignment=Enum.TextXAlignment.Center
  local plus=button(body,key..'Plus','+',UDim2.new(1,-64,0,y),UDim2.fromOffset(44,44))
  rows[key]={title=title,value=value,buttons={[-1]=minus,[1]=plus}}
  for direction,b in rows[key].buttons do b.Activated:Connect(function()
   if busy or not b.Active then return end
   draft[key]+=direction;feedback.Text='Changes apply to future spawns. Living troops keep their class and health.';render()
  end)end
 end
 local function hide()
  local focused=visibility:ownsSelection()
  visibility:setVisible(false);board=nil
  if focused then Gui.SelectedObject=previousFocus end
 end
 close.Activated:Connect(hide)
 apply.Activated:Connect(function()
  if busy or not remote or not apply.Active then return end
  busy=true;render()
  local ok,result=pcall(function()return remote:InvokeServer('composition',table.clone(draft))end)
  busy=false;render()
  feedback.Text=if ok and result.ok then 'Composition saved. Changes apply to future spawns; current troops stay as they are.'
   elseif ok and result.reason=='rate_limited' then 'Wait a moment, then save again.' else 'Unable to save. Stay near your Barracks and check your unlocked capacity.'
 end)
 for _,attribute in {'BarracksUpgradeLevel','ArmyCampLevel','HospitalLevel','RecruitMelee','RecruitRanged','RecruitMedic','WarriorCount','RangedCount','MedicCount','ProgressStatus'}do
  player:GetAttributeChangedSignal(attribute):Connect(render)
 end
 player:GetAttributeChangedSignal('CivilizationId'):Connect(hide)
 game:GetService('RunService').Heartbeat:Connect(function()
  if not visibility:isOpen()then return end
  local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
  if not Panels.available(screen.SettlementHUD) or not board or not board:IsDescendantOf(workspace) or not root or not hum or hum.Health<=0 or (root.Position-board.Position).Magnitude>14 then hide()end
 end)
 task.spawn(function()
  local folder=Replicated:WaitForChild('ArmyRemotes',15);if not folder then return end
  remote=folder:WaitForChild('Request',15)
  folder:WaitForChild('RecruitmentOpened').OnClientEvent:Connect(function(data)
   if data.civilizationId~=player:GetAttribute('CivilizationId')or not Panels.available(screen.SettlementHUD)then return end
   board=data.board;draft=Recruitment.counts(state());previousFocus=Gui.SelectedObject
   feedback.Text='Changes apply to future spawns. Living troops keep their class and health.'
   render();visibility:restore();visibility:setVisible(true)
   if game:GetService('UserInputService').GamepadEnabled then Gui.SelectedObject=apply end
  end)
 end)
 render()
end
return UI

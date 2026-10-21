-- Run from Studio's Client tool context to retain native keyboard focus.
return function()
local Replicated=game.ReplicatedStorage
local ok,result=pcall(function()
 local player=game.Players.LocalPlayer
 -- Initialize the standard controls in the Studio tool's execution context;
 -- virtual key events otherwise have no movement binding in that context.
 require(player.PlayerScripts:WaitForChild('PlayerModule')):GetControls()
 local screen=player.PlayerGui:WaitForChild('MiniaturePreviewUI',10)
 assert(screen,'Prototype UI missing')
 local input=game.UserInputService:CreateVirtualInput()
 local function clickPoint(p)
  input:SendMousePosition(p);task.wait(.1);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,true,0)
  task.wait(.06);input:SendMouseButton(p,Enum.UserInputType.MouseButton1,false,0);task.wait(.2)
 end
 local function click(button)clickPoint(button.AbsolutePosition+button.AbsoluteSize/2+game.GuiService:GetGuiInset())end
 local function waitFor(f,label)
  local deadline=os.clock()+15;repeat if f()then return end;task.wait(.05)until os.clock()>deadline;error(label)
 end
 click(screen.PreviewControls.Overview);task.wait(.3)
 assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable and screen:GetAttribute('CameraMode')=='Overview')
 local scene=workspace.MiniaturePreview
 for _,id in {'house','farm','barracks'}do
  local point,shown=workspace.CurrentCamera:WorldToViewportPoint(scene.Buildings[id].SelectTarget.Position)
  assert(shown,'Building is outside overview')
  clickPoint(Vector2.new(point.X,point.Y))
  waitFor(function()return screen:GetAttribute('InspectedBuilding')==id end,'Native building click failed: '..id)
  assert(screen.BuildingInformation.Visible and screen.BuildingInformation.Description.TextFits)
 end
 local beforeZoom=(workspace.CurrentCamera.CFrame.Position-workspace.CurrentCamera.Focus.Position).Magnitude
 input:SendPointerAction(workspace.CurrentCamera.ViewportSize*.5,{Wheel=2});task.wait(.2)
 assert((workspace.CurrentCamera.CFrame.Position-workspace.CurrentCamera.Focus.Position).Magnitude<beforeZoom,'Overview wheel zoom failed')
 click(screen.BuildingInformation.MinimizePanel)
 assert(not screen.BuildingInformation.Visible and screen.RestoreBuilding.Visible)
 click(screen.RestoreBuilding);click(screen.BuildingInformation.Close)
 assert(not screen.BuildingInformation.Visible)
 click(screen.PreviewControls.Walk);task.wait(.3)
 assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom)
 local old=player.Character
 local root=old.HumanoidRootPart
 old:PivotTo(CFrame.new(-9,4,-.5))
 workspace.CurrentCamera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,7,15),root.Position+Vector3.new(0,0,-4))
 task.wait(.3)
 clickPoint(workspace.CurrentCamera.ViewportSize*.5)
 local began=root.Position
 input:SendKey(true,Enum.KeyCode.W,false);task.wait(1);input:SendKey(false,Enum.KeyCode.W,false);task.wait(.2)
 assert((root.Position-began).Magnitude>5,'Commander movement was blocked: '..tostring(root.Position-began)..' '..tostring(old.Humanoid.MoveDirection))
 old:PivotTo(CFrame.new(8,4,-1))
 workspace.CurrentCamera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,3,2),scene.Buildings.farm.SelectTarget.Position)
 task.wait(.4)
 input:SendKey(true,Enum.KeyCode.E,false);task.wait(.1);input:SendKey(false,Enum.KeyCode.E,false)
 waitFor(function()return screen:GetAttribute('InspectedBuilding')=='farm'end,'Farm E prompt failed')
 click(screen.BuildingInformation.Close)
 click(screen.PreviewControls.Overview)
 Replicated.MiniatureTestControl:FireServer('respawn')
 waitFor(function()return player.Character and player.Character~=old and player.Character:FindFirstChild('HumanoidRootPart')end,'Respawn failed')
 waitFor(function()return screen:GetAttribute('CameraMode')=='Walk'and workspace.CurrentCamera.CameraSubject==player.Character.Humanoid end,'Camera did not recover after respawn')
 assert(player.Character:GetScale()==1 and not player.Backpack:FindFirstChildOfClass('Tool'))
 local cases=0
 local gui=Instance.new('ScreenGui');gui.Parent=player.PlayerGui
 local function inside(a,b)
  local p,s=a.AbsolutePosition,a.AbsoluteSize;local q,t=b.AbsolutePosition,b.AbsoluteSize
  return p.X>=q.X and p.Y>=q.Y and p.X+s.X<=q.X+t.X+1 and p.Y+s.Y<=q.Y+t.Y+1
 end
 for _,size in {Vector2.new(320,360),Vector2.new(320,568),Vector2.new(640,360),Vector2.new(1024,768)}do
  local shell=Instance.new('Frame');shell.Size=UDim2.fromOffset(size.X,size.Y);shell.Parent=gui
  local ui=require(player.PlayerScripts.Miniature.UI).mount(shell,{walk=function()end,overview=function()end})
  ui.inspect(scene.Buildings.barracks);task.wait(.2)
  for _,panel in {shell.PreviewControls,shell.BuildingInformation}do
   assert(inside(panel,shell),'Panel outside viewport')
   for _,v in panel:GetChildren()do if v:IsA('TextLabel')or v:IsA('TextButton')then assert(inside(v,panel)and v.TextFits,'Clipped text/control: '..v.Name..' '..tostring(size))end end
  end
  shell:Destroy();cases+=1
 end
 gui:Destroy()
 return {ok=true,worldClicks=3,prompt=true,cameraRespawn=true,layouts=cases}
end)
Replicated:SetAttribute('MiniatureInputResult',game.HttpService:JSONEncode({ok=ok,result=result}))
if not ok then warn(result)end
assert(ok,result)
return result
end

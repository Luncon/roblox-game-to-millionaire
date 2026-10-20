-- Native E + UI mouse activation. Does not invoke production remotes directly.
return function()
 local player=game.Players.LocalPlayer
 local definition=assert(require(game.ReplicatedStorage.Shared.FormationConfig).forCivilization(player:GetAttribute('CivilizationId')))
 local screen=player.PlayerGui:WaitForChild('CivilizationSelection',10)
 local overlay=screen:WaitForChild('CouncilOverlay',10)
 local input=game:GetService('UserInputService'):CreateVirtualInput()
 local function waitFor(fn,label)
  local deadline=os.clock()+10;repeat if fn()then return end;task.wait(.03)until os.clock()>deadline;error('Timed out: '..label)
 end
 local camera=workspace.CurrentCamera;local original={frame=camera.CFrame,kind=camera.CameraType}
 local plot=workspace.CivilizationPrototype.Plots['Plot'..player:GetAttribute('PlotId')]
 local map=plot.Infrastructure.WarCouncil.MapTable
 local root=player.Character.HumanoidRootPart
 local shown=false;local connection=game.ProximityPromptService.PromptShown:Connect(function(p)if p.Parent==map then shown=true end end)
 local ok,result=pcall(function()
  camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,2,0),map.Position)
  -- Prompt may already be visible when this observer subscribes.
  task.wait(.4)
  input:SendKey(true,Enum.KeyCode.E,false);task.wait(.1);input:SendKey(false,Enum.KeyCode.E,false)
  waitFor(function()return overlay.Visible end,'physical council prompt')
  local panel=overlay.WarCouncil;local select=panel.SelectShieldwall
  assert(select.Active and select.Visible and select.Selectable)
  assert(panel.FormationDescription.Text:find(if definition.volley then '1 guard, 3 archers' else '3 shieldmen',1,true))
  local function click(button)
   local inset=game.GuiService:GetGuiInset()
   local point=button.AbsolutePosition+button.AbsoluteSize/2+(if screen.IgnoreGuiInset then Vector2.zero else inset)
   input:SendMousePosition(point);input:SendMouseButton(point,Enum.UserInputType.MouseButton1,true,0)
   task.wait(.08);input:SendMouseButton(point,Enum.UserInputType.MouseButton1,false,0)
  end
  click(select)
  waitFor(function()return player:GetAttribute('SelectedFormation')==definition.id end,'saved formation selection')
  click(panel.CloseCouncil);waitFor(function()return not overlay.Visible end,'council close')
  return {ok=true,shown=shown,selected=player:GetAttribute('SelectedFormation'),viewport={camera.ViewportSize.X,camera.ViewportSize.Y}}
 end)
 connection:Disconnect();camera.CameraType=original.kind;camera.CFrame=original.frame
 assert(ok,result);return result
end

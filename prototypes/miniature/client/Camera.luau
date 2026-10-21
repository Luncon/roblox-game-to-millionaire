--!strict
local player=game.Players.LocalPlayer
local Camera={}
function Camera.start(scene,screen)
 local overview=false;local zoom=1;local pinchStart=1
 local controller={}
 function controller.walk(character)
  overview=false;screen:SetAttribute('CameraMode','Walk')
  local character=character or player.Character
  local humanoid=character and character:FindFirstChildOfClass('Humanoid')
  local camera=workspace.CurrentCamera
  if camera and humanoid then camera.CameraSubject=humanoid;camera.CameraType=Enum.CameraType.Custom end
 end
 function controller.overview()
  overview=true;screen:SetAttribute('CameraMode','Overview')
 end
 game.UserInputService.PointerAction:Connect(function(wheel,_,pinch,processed)
  if overview and not processed then zoom=math.clamp(zoom-wheel*.1-pinch*.1,.4,2)end
 end)
 game.UserInputService.TouchPinch:Connect(function(_,scale,_,state,processed)
  if state==Enum.UserInputState.Begin then pinchStart=zoom end
  if overview and not processed and scale>0 then zoom=math.clamp(pinchStart/scale,.4,2)end
 end)
 player.CameraMaxZoomDistance=80;player.CameraMinZoomDistance=3
 player.CharacterAdded:Connect(function(character)
  character:WaitForChild('Humanoid',10);controller.walk(character)
 end)
 game.RunService.RenderStepped:Connect(function()
  if not overview then return end
  local camera=workspace.CurrentCamera;local size=camera.ViewportSize
  local distance=32/math.tan(math.rad(camera.FieldOfView/2))*math.max(1,size.Y/math.max(size.X,1))*zoom
  local target=scene.Plot.Position
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(target+Vector3.new(.65,.9,.95)*distance,target)
  camera.Focus=CFrame.new(target)
 end)
 controller.walk()
 return controller
end
return Camera

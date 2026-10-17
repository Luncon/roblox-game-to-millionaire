-- Real client observations of replicated support poses, flights and health.
return function(options)
 assert(game:GetService("RunService"):IsStudio())
 local world=workspace:WaitForChild("CivilizationPrototype",15)
 local camera=workspace.CurrentCamera
 local previousType,previousFrame=camera.CameraType,camera.CFrame
 local records,connections={},{}
 local heals,flights,armMotion=0,false,0
 local ok,result=pcall(function()
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(options.focus+Vector3.new(10,16,30),options.focus)
  local deadline=os.clock()+7
  while os.clock()<deadline do
   flights=flights or #world.MedicalBandages:GetChildren()>0
   for _,rig in world.Troops:GetChildren()do
    local hum=rig:FindFirstChildOfClass("Humanoid")
    if hum and not records[rig]then
     local record={health=hum.Health,arm=nil};records[rig]=record
     table.insert(connections,hum.HealthChanged:Connect(function(value)
      if value>record.health then heals+=1 end;record.health=value
     end))
    end
    if rig:GetAttribute("WarriorClass")=="medic" and records[rig]then
     local point=rig.HumanoidRootPart.CFrame:PointToObjectSpace(rig["Right Arm"].Position)
     local record=records[rig]
     if record.arm then armMotion=math.max(armMotion,(point-record.arm).Magnitude)else record.arm=point end
    end
   end
   game:GetService("RunService").RenderStepped:Wait()
  end
  local medics=0;for rig in records do if rig:GetAttribute("WarriorClass")=="medic"then medics+=1 end end
  assert(medics==2 and flights and heals>=2 and armMotion>.15,"Client missed replicated bandages, healing or throw poses")
  return {ok=true,medics=medics,flightsSeen=flights,healEvents=heals,armMotion=armMotion}
 end)
 for _,connection in connections do connection:Disconnect()end
 camera.CameraType,camera.CFrame=previousType,previousFrame
 assert(ok,result);return result
end

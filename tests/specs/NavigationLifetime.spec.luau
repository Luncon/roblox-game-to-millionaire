-- Native Humanoid plus a deliberately deferred pathfinder; no timing race needed.
return function()
 local Game=game.ServerScriptService.Game
 local module=assert(Game:FindFirstChild('NavigationLifetimeNavigator'),'Generate the test project before running navigation fixtures'):Clone()
 module.Name='NavigationLifetimeFixture';module.Parent=Game
 local floor=Instance.new('Part');floor.Size=Vector3.new(100,1,100);floor.CFrame=CFrame.new(2600,96.5,2600);floor.Anchored=true;floor.Parent=workspace
 local rig=require(Game.WarriorRig).createNeutral(CFrame.new(2600,100,2600),'warrior');rig.Parent=workspace
 rig.HumanoidRootPart:SetNetworkOwner(nil)
 local nav=require(module).new(rig,function()return true end)
 local ok,result=pcall(function()
  local deadline=os.clock()+5
  repeat task.wait(.03)until rig.Humanoid.FloorMaterial~=Enum.Material.Air or os.clock()>deadline
  assert(rig.Humanoid.FloorMaterial~=Enum.Material.Air)
  local position=rig.HumanoidRootPart.Position
  nav:setGoal(position+Vector3.new(30,0,0));nav:step(os.clock())
  deadline=os.clock()+3
  repeat task.wait()until module:GetAttribute('Started')or os.clock()>deadline
  assert(module:GetAttribute('Started'),'Deferred path did not start')
  nav:setGoal(position-Vector3.new(30,0,0));module.Release:Fire();task.wait(.05)
  nav:step(os.clock())
  assert(rig.Humanoid.WalkToPoint.X<=position.X+1,'A superseded path moved toward the old destination')
  assert(module:GetAttribute('Discarded'),'Superseded pending path was not discarded')
  nav:destroy();module:SetAttribute('Started',nil);module:SetAttribute('Discarded',nil)
  nav=require(module).new(rig,function()return true end)
  position=rig.HumanoidRootPart.Position
  nav:setGoal(position+Vector3.new(30,0,0));nav:step(os.clock())
  repeat task.wait()until module:GetAttribute('Started')
  nav:setGoal(position+Vector3.new(32,0,0));module.Release:Fire();task.wait(.05);nav:step(os.clock())
  assert(not module:GetAttribute('Discarded') and rig.Humanoid.WalkToPoint.X>position.X+25,'Small goal jitter discarded a usable route')
  nav:destroy();module:SetAttribute('Started',nil);module:SetAttribute('Discarded',nil)
  nav=require(module).new(rig,function()return true end)
  position=rig.HumanoidRootPart.Position
  nav:setGoal(position+Vector3.new(30,0,0));nav:step(os.clock())
  repeat task.wait()until module:GetAttribute('Started')
  rig:PivotTo(rig:GetPivot()+Vector3.new(25,0,0));module.Release:Fire();task.wait(.05)
  assert(module:GetAttribute('Discarded'),'A delayed path from before displacement was accepted')
  return 3
 end)
 nav:destroy();rig:Destroy();floor:Destroy();module:Destroy();assert(ok,result);return result
end

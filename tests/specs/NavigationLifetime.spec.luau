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
  local function leg(offset,jump,middle)
   nav:destroy();module:SetAttribute('Started',nil);module:SetAttribute('Discarded',nil)
   position=rig.HumanoidRootPart.Position
   module:SetAttribute('Middle',if middle then position+Vector3.new(3.3,0,0)else nil)
   module:SetAttribute('Jump',jump)
   nav=require(module).new(rig,function()return true end)
   nav:setGoal(position+offset);nav:step(os.clock())
   local untilStarted=os.clock()+3
   repeat task.wait()until module:GetAttribute('Started')or os.clock()>untilStarted
   assert(module:GetAttribute('Started'),'Waypoint fixture did not start')
   module.Release:Fire();task.wait(.05);nav:step(os.clock())
   return rig.Humanoid.WalkToPoint-position
  end
  local straight=leg(Vector3.new(20,0,0),false,true)
  assert(straight.X>10,'Straight route stopped at an intermediate waypoint instead of anticipating the next think')
  local corner=leg(Vector3.new(3.3,0,20),false,true)
  assert(math.abs(corner.X-3.3)<.1 and math.abs(corner.Z)<.1,'Waypoint lookahead cut a corner')
  local jump=leg(Vector3.new(20,0,0),true,true)
  assert(math.abs(jump.X-3.3)<.1,'Waypoint lookahead skipped a jump approach')
  local final=leg(Vector3.new(3.3,0,0),false,false)
  assert(math.abs(final.X-3.3)<.1,'Waypoint lookahead stopped short of the final goal')
  leg(Vector3.new(20,0,0),false,false)
  nav:setGoal(position-Vector3.new(20,0,0));nav:step(os.clock())
  assert(rig.Humanoid.WalkToPoint.X<=rig.HumanoidRootPart.Position.X+1,'Changed destination kept steering along the installed old route')
  leg(Vector3.new(20,0,0),false,false)
  nav:setGoal(position+Vector3.new(22,0,0));nav:step(os.clock())
  assert(rig.Humanoid.WalkToPoint.X>position.X+15,'Small goal jitter erased the installed usable route')
  leg(Vector3.new(20,0,0),false,false)
  nav:setGoal(position+Vector3.new(40,0,0));nav:step(os.clock())
  assert(rig.Humanoid.WalkToPoint.X>position.X+15,'Forward target movement erased useful route progress')
  nav:destroy();module:SetAttribute('Started',nil);module:SetAttribute('Middle',nil);module:SetAttribute('IncludeStart',true)
  position=rig.HumanoidRootPart.Position
  nav=require(module).new(rig,function()return true end)
  nav:setGoal(position+Vector3.new(30,0,0));nav:step(os.clock())
  repeat task.wait()until module:GetAttribute('Started')
  rig:PivotTo(rig:GetPivot()+Vector3.new(8,0,0));module.Release:Fire();task.wait(.05);nav:step(os.clock())
  assert(rig.Humanoid.WalkToPoint.X>rig.HumanoidRootPart.Position.X,'Delayed replacement route retraced its already-passed start')
  return 11
 end)
 nav:destroy();rig:Destroy();floor:Destroy();module:Destroy();assert(ok,result);return result
end

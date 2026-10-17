-- Real server-owned walkers and production combat/army services. Fake profiles only.
return function(context,player,round)
 assert(context.store.isFakeProfileStore)
 local service=context.service
 local Game=game.ServerScriptService.Game
 local Rig,Map,Navigator=require(Game.WarriorRig),require(Game.BattlefieldMap),require(Game.WarriorNavigator)
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local Rules=require(Game.CombatRules)
 local cases,evidence,cleanup=0,{},{}
 local function flat(a,b)local d=a-b;return Vector3.new(d.X,0,d.Z).Magnitude end
 local function waitFor(fn,label,timeout)
  local deadline=os.clock()+(timeout or 15)
  repeat if fn()then return end;task.wait(.03)until os.clock()>deadline
  error('Timed out: '..label)
 end
 local function test(name,fn)
  game:SetAttribute('TacticalCombatVerificationPhase',name);fn();cases+=1
  game:SetAttribute('TroopMovementEvidence',game.HttpService:JSONEncode(evidence));print('PASS: '..name)
 end
 local function command(value)task.wait(.35);assert(service.command(player,'order',value).ok)end
 local folder=Instance.new('Folder');folder.Name='MovementCrowdFixture';folder.Parent=workspace
 table.insert(cleanup,function()folder:Destroy()end)
 local extraEnemy
 local ok,result=pcall(function()
  local world=Map.build(folder)
  world.model:PivotTo(CFrame.new(3200,0,-2600)*world.model:GetPivot())
  task.wait(2)
  local function walker(name,point)
   local r=Rig.createNeutral(CFrame.new(point),'warrior');r.Name=name;r:SetAttribute('ArmySlot',name)
   r.Parent=world.model.Troops
   for _,p in r:GetDescendants()do if p:IsA('BasePart')then p.CollisionGroup='CivilizationWarriors' end end
   r.HumanoidRootPart:SetNetworkOwner(nil)
   local nav=Navigator.new(r,function()return r.Parent~=nil and r.Humanoid.Health>0 end,world)
   return {rig=r,nav=nav}
  end
  local function walkGroup(group,seconds)
   local failed
   local elapsed=0
   local overlaps={};local worst=0;local began=os.clock()
   local last={};for _,a in group do last[a]=a.rig.HumanoidRootPart.Position end
   local connection=game.RunService.Heartbeat:Connect(function(dt)
    local success,message=pcall(function()
     elapsed+=dt
     local think=elapsed>=.2
     if think then elapsed=0 end
     for _,a in group do
      if think then a.nav:step(os.clock())end
      local p=a.rig.HumanoidRootPart.Position
      assert(flat(p,last[a])<8+dt*45,'Crowd avoidance teleported a root')
      if a.dry then assert(require(Game.WaterNavigation).allowsDirect(world.model,p,p),'Crowd detour entered river water')end
      if a.rig:GetAttribute('NavigationStatus')=='Yielding to troops' then assert(not a.rig.Humanoid.Jump,'Intentional yielding triggered a jump')end
      last[a]=p;Rig.animate(a.rig,os.clock(),a.rig.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5)
     end
     if os.clock()-began>2 then for i,a in group do for j=i+1,#group do
      local key=i..':'..j
      overlaps[key]=if flat(a.rig.HumanoidRootPart.Position,group[j].rig.HumanoidRootPart.Position)<2 then (overlaps[key] or 0)+dt else 0
      worst=math.max(worst,overlaps[key])
     end end end
    end)
    if not success then failed=tostring(message)end
   end)
   local finished,message=pcall(function()
    waitFor(function()
     assert(not failed,failed)
     for _,a in group do if flat(a.rig.HumanoidRootPart.Position,a.goal)>2.4 then return false end end
     return true
    end,'all crowd walkers reach their destinations',seconds)
   end)
   connection:Disconnect()
   for _,a in group do a.nav:destroy()end
   assert(finished,message)
   assert(worst<.8,'Traffic left sustained body overlap')
  end
  test('four opposing walkers pass on a bridge without water shortcuts or stuck jumps',function()
   local deck
   for _,b in world.model.Landscape.Waterways:GetChildren()do if b:GetAttribute('PlotId')==1 then deck=b.BridgeDeck end end
   local group={};local length=deck.Size.Z/2+24
   for id=1,4 do
    local sign=if id<=2 then 1 else -1
    local x=if id%2==1 then -3 else 3
    local a=walker('bridge-'..id,deck.CFrame:PointToWorldSpace(Vector3.new(x,4,sign*length)))
    a.goal=deck.CFrame:PointToWorldSpace(Vector3.new(x,4,-sign*length))
    a.dry=true
    a.nav:setGoal(a.goal);table.insert(group,a)
   end
   local started=os.clock();walkGroup(group,40)
   evidence.bridgeSeconds=os.clock()-started
   for _,a in group do assert(a.rig.Humanoid.Health==a.rig.Humanoid.MaxHealth);a.rig:Destroy()end
  end)
  test('coincident walkers separate by walking and reach independent goals',function()
   local start=world.model.Ground.CFrame:PointToWorldSpace(Vector3.new(-100,4,0))
   local group={}
   for id=1,3 do
    local a=walker('overlap-'..id,start)
    local angle=id*math.pi*2/3
    a.goal=start+Vector3.new(math.cos(angle),0,math.sin(angle))*18
    a.nav:setGoal(a.goal);table.insert(group,a)
   end
   walkGroup(group,18)
   for i,a in group do for j=i+1,#group do assert(flat(a.rig.HumanoidRootPart.Position,group[j].rig.HumanoidRootPart.Position)>3)end end
   for _,a in group do a.rig:Destroy()end
  end)
  world.model:Destroy()
  -- Configure one real owner and preserve profile authority through native input.
  round('civilizationInput',{action='choose',civilization='britain'},30)
  local state=require(Game.ProfileData).defaultState()
  state.level,state.weaponLevel,state.armorLevel=50,1,50
  state.barracksLevel,state.trainingLevel,state.armyCampLevel,state.hospitalLevel=6,1,1,1
  assert(service.profiles:set(player.UserId,'sparta',state))
  round('civilizationInput',{action='choose',civilization='sparta'},30)
  command('hold');service.neutralOpponents:destroy()
  local function army()return assert(service.army:get(player.UserId))end
  local arena=service.world.model.Battlefield
  local function point(x,z)
   local p=arena.Position+Vector3.new(x,0,z)
   local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include
   filter.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
   local hit=assert(workspace:Raycast(p+Vector3.new(0,60,0),Vector3.new(0,-120,0),filter))
   return Vector3.new(p.X,hit.Position.Y+3,p.Z)
  end
  local function park(selected,positions)
   command('hold')
   for id,s in army().slots do
    local r=s.rig;assert(r)
    r.HumanoidRootPart.Anchored=true
    r.Humanoid.MaxHealth=1000;r.Humanoid.Health=1000
    local p=positions and positions[id] or {350,100}
    r:PivotTo(CFrame.new(point(p[1],p[2])))
    if selected[id]then r.HumanoidRootPart.Anchored=false;r.HumanoidRootPart:SetNetworkOwner(nil)end
   end
  end
  local function target(kind,x,z)
   local f=Instance.new('Folder');f.Name='NeutralOpponents';f.Parent=service.world.model
   local r=Rig.createNeutral(CFrame.new(point(x,z)),kind);r.Parent=f
   r.Humanoid.MaxHealth=1000;r.Humanoid.Health=1000
   assert(service.combat:registerNeutral(r,kind))
   return r,f
  end
  test('idle shuffles remain near the rally and Hold fixes root positions',function()
   park({warrior=true},{warrior={0,12}})
   local r=army().slots.warrior.rig
   command('advance');local origin=r.HumanoidRootPart.Position
   local moved=0;local last=origin
   local began=os.clock()
   repeat task.wait(.1);local p=r.HumanoidRootPart.Position;moved+=flat(p,last);last=p;assert(flat(p,origin)<6)until os.clock()-began>10
   assert(moved>1,'Idle troop never shuffled')
   command('hold');task.wait(.5);local held=r.HumanoidRootPart.Position;task.wait(1)
   assert(flat(held,r.HumanoidRootPart.Position)<.3)
   evidence.idleDistance=moved
  end)
  test('unanchored melee duel uses recovery footwork and continues damaging both opponents',function()
   park({warrior=true},{warrior={-4,-60}})
   local config={enabled=true,respawnDelay=10,slots={{id='duelist',kind='warrior',offset=Vector3.new(0,0,-60)}}}
   extraEnemy=require(Game.NeutralOpponentService).start(service.world,service.combat,config,service.encounters)
   local foe=extraEnemy:get().duelist.rig;foe.Humanoid.MaxHealth=1000;foe.Humanoid.Health=1000
   local r=army().slots.warrior.rig
   command('advance');local moving=0;local began=os.clock()
   repeat
    task.wait(.05)
    if r:GetAttribute('CombatPhase')=='recovery' and r.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5 then moving+=1 end
    assert(not r.HumanoidRootPart.Anchored and not foe.HumanoidRootPart.Anchored)
   until os.clock()-began>9
   assert(moving>3 and r.Humanoid.Health<1000 and foe.Humanoid.Health<1000,'Duel footwork prevented normal strikes')
   evidence.duel={movingRecoverySamples=moving,ownHealth=r.Humanoid.Health,enemyHealth=foe.Humanoid.Health}
   extraEnemy:destroy();extraEnemy=nil;command('hold')
  end)
  test('ranged troop strafes between real shots while retaining its target',function()
   park({ranged=true},{ranged={0,-60}})
   local foe,f=target('warrior',28,-60);foe.HumanoidRootPart.Anchored=true
   local r=army().slots.ranged.rig;local start=r.HumanoidRootPart.Position
   command('advance');local moving=0;local began=os.clock()
   repeat task.wait(.05)
    if r:GetAttribute('CombatPhase')=='recovery' and r.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5 then moving+=1 end
   until os.clock()-began>10
   assert(moving>3 and foe.Humanoid.Health<980,'Strafing starved projectile attacks')
   evidence.ranged={movingRecoverySamples=moving,enemyHealth=foe.Humanoid.Health,travel=flat(start,r.HumanoidRootPart.Position)}
   service.combat:unregister(foe);f:Destroy();command('hold')
  end)
  test('four troops regroup through separate entrances and share the camp without sustained overlap',function()
   local claim=service.registry:get(player.UserId)
   local frame=service.world.model.Plots['Plot'..claim.plotId].Foundation.CFrame
   command('hold')
   for id in army().slots do
    local path=game.PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
    path:ComputeAsync(frame:PointToWorldSpace(Camp.center+Vector3.new(48,3,0)),frame:PointToWorldSpace(Camp.entryPoint(Camp.arrivalIndex(id))))
    local status=path.Status;path:Destroy()
    assert(status==Enum.PathStatus.Success,'Camp arrival has no native path: '..id)
   end
   local i=0
   for _,s in army().slots do i+=1;s.rig.HumanoidRootPart.Anchored=true;s.rig:PivotTo(frame*CFrame.new(Camp.center+Vector3.new(55,3,-12+i*6)));s.rig.HumanoidRootPart.Anchored=false end
   command('regroup')
   waitFor(function()
    for _,s in army().slots do if not Camp.contains(frame:PointToObjectSpace(s.rig.HumanoidRootPart.Position),2)then return false end end
    return true
   end,'all four camp arrivals',30)
   local overlap={}
   local worst=0;local began=os.clock();local last=began
   repeat
    task.wait(.05);local now=os.clock();local list={}
    for _,s in army().slots do table.insert(list,s.rig);assert(Camp.contains(frame:PointToObjectSpace(s.rig.HumanoidRootPart.Position),1))end
    for a=1,#list do for b=a+1,#list do
     local key=a..':'..b
     overlap[key]=if flat(list[a].HumanoidRootPart.Position,list[b].HumanoidRootPart.Position)<2 then (overlap[key] or 0)+now-last else 0
     worst=math.max(worst,overlap[key])
    end end
    last=now
   until os.clock()-began>10
   assert(worst<1,'Camp bodies stayed overlapped')
   evidence.camp={troops=4,longestOverlap=worst}
  end)
  return {ok=true,cases=cases,evidence=evidence}
 end)
 if extraEnemy then extraEnemy:destroy()end
 for _,fn in cleanup do fn()end
 assert(ok,result)
 return result
end

-- Native movement and sweeps, production services, fake profiles only.
return function(context,player,round)
 assert(context.store.isFakeProfileStore and game:GetService("RunService"):IsStudio())
 local service=context.service
 local Data=require(game.ServerScriptService.Game.ProfileData)
 local Rig=require(game.ServerScriptService.Game.WarriorRig)
 local Route=require(game.ServerScriptService.Game.MedicalRoute)
 local CombatRules=require(game.ServerScriptService.Game.CombatRules)
 local extras,anchored={},{}
 local evidence,cases={},0
 local function waitFor(fn,label,seconds)
  local deadline=os.clock()+(seconds or 10)
  repeat if fn()then return end;task.wait(.02)until os.clock()>deadline
  error("Timed out: "..label)
 end
 local function choose(id)
  if player:GetAttribute("CivilizationId")==id then return end
  round("civilizationInput",{action="choose",civilization=id},30)
  waitFor(function()return player:GetAttribute("CivilizationId")==id end,"choose "..id)
  task.wait(.4)
 end
 local function order(value)
  task.wait(.35);assert(service.command(player,"order",value).ok)
 end
 local function army()return assert(service.army:get(player.UserId))end
 local function floorPoint(p)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
  local hit=assert(workspace:Raycast(p+Vector3.new(0,40,0),Vector3.new(0,-100,0),params))
  return Vector3.new(p.X,hit.Position.Y+3,p.Z)
 end
 local function freeze(rig,p)
  if anchored[rig]==nil then anchored[rig]=rig.HumanoidRootPart.Anchored end
  rig.HumanoidRootPart.Anchored=true;rig:PivotTo(CFrame.new(floorPoint(p)))
  rig.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 end
 local function test(name,fn)
  game:SetAttribute("MedicalSupportVerificationPhase",name);fn();cases+=1;print("PASS: "..name)
 end
 local ok,result=pcall(function()
  choose("britain")
  local s=Data.defaultState()
  s.level,s.weaponLevel,s.armorLevel,s.trainingLevel,s.barracksLevel,s.armyCampLevel,s.hospitalLevel=50,50,50,1,6,1,1
  s.skillLevel=1
  assert(service.profiles:set(player.UserId,"sparta",s));choose("sparta");order("hold")
  service.neutralOpponents:destroy()
  local folder=Instance.new("Folder");folder.Name="NeutralOpponents";folder.Parent=service.world.model;table.insert(extras,folder)
  local center=service.world.model.Battlefield.Position
  test("native three-stud bandage near miss heals exactly one closest owned launch life",function()
   local slots=army().slots
   local m,p,near,far=slots.medic.rig,slots.warrior.rig,slots.ranged.rig,slots.camp.rig
   freeze(m,center);freeze(p,center+Vector3.new(24,0,0))
   freeze(near,center+Vector3.new(24,0,2));freeze(far,center+Vector3.new(24,0,5))
   m.Humanoid.Health=m.Humanoid.MaxHealth;p.Humanoid.Health=20
   near.Humanoid.Health,far.Humanoid.Health=60,60
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"native proximity launch",5)
   local ready=m:GetAttribute("BandageReadyAt")
   freeze(p,center+Vector3.new(24,0,12))
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()==0 end,"near miss consumed",2)
   assert(near.Humanoid.Health==72 and far.Humanoid.Health==60 and p.Humanoid.Health==20,"Native proximity recipient incorrect")
   assert(m:GetAttribute("BandageReadyAt")==ready)
   evidence.proximity={radius=3,nearestHealth=72,fartherHealth=60,originalHealth=20,oneRecipient=true}
  end)
  test("critical native fighter retreats heals and resumes without resetting skill cooldown",function()
   order("hold")
   local slots=army().slots;local m,p=slots.medic.rig,slots.warrior.rig
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center+Vector3.new(0,0,65));freeze(p,center)
   freeze(slots.ranged.rig,center+Vector3.new(-70,0,0));freeze(slots.camp.rig,center+Vector3.new(-60,0,0))
   p.HumanoidRootPart.Anchored=false
   order("advance")
   assert(service.combat.skills:activate(p,"advance",false).ok,"Native skill setup failed")
   local cooldown=p:GetAttribute("WeaponSkillReadyAt")
   assert(cooldown>workspace:GetServerTimeNow())
   p.Humanoid.Health=20
   waitFor(function()return p:GetAttribute("WarriorState")=="Seeking medic" end,"critical retreat selected",3)
   local initial=(p.HumanoidRootPart.Position-m.HumanoidRootPart.Position).Magnitude
   waitFor(function()return (p.HumanoidRootPart.Position-m.HumanoidRootPart.Position).Magnitude<=22 end,"actual fighter reaches medic",12)
   assert(p:GetAttribute("CombatPhase")=="idle" and p:GetAttribute("WeaponSkillActive")==nil)
   waitFor(function()return p.Humanoid.Health>=p.Humanoid.MaxHealth*.6 end,"critical fighter recovers sixty percent",25)
   waitFor(function()return p:GetAttribute("WarriorState")~="Seeking medic" and p:GetAttribute("WarriorState")~="Recovering" end,"fighter resumes Advance",3)
   assert(math.abs(p:GetAttribute("WeaponSkillReadyAt")-cooldown)<.05)
   evidence.recovery={initialDistance=initial,health=p.Humanoid.Health,maxHealth=p.Humanoid.MaxHealth,
    state=p:GetAttribute("WarriorState"),cooldownPreserved=true}
   order("hold")
   p.Humanoid.Health=20;local held=p.HumanoidRootPart.Position;task.wait(.5)
   assert((held-p.HumanoidRootPart.Position).Magnitude<1 and p:GetAttribute("WarriorState")~="Seeking medic")
  end)
  test("critical ranged recovery cancels an actual pending shot without damaging its target",function()
   order("hold")
   local slots=army().slots;local m,p=slots.medic.rig,slots.ranged.rig
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center+Vector3.new(0,0,65));freeze(p,center)
   freeze(slots.warrior.rig,center+Vector3.new(-70,0,0));freeze(slots.camp.rig,center+Vector3.new(-60,0,0))
   local target=Rig.createNeutral(CFrame.new(floorPoint(center+Vector3.new(0,0,-40))),"warrior")
   target.Parent=folder;freeze(target,target.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(target,"warrior"));table.insert(extras,target)
   local health=target.Humanoid.Health
   waitFor(function()return #service.world.model.TroopProjectiles:GetChildren()>0 end,"actual ranged shot launch",5)
   p.Humanoid.Health=20;p.HumanoidRootPart.Anchored=false
   assert(service.command(player,"order","advance").ok)
   waitFor(function()return p:GetAttribute("WarriorState")=="Seeking medic" end,"ranged recovery entry",2)
   assert(#service.world.model.TroopProjectiles:GetChildren()==0)
   task.wait(.5);assert(target.Humanoid.Health==health and p:GetAttribute("CombatPhase")=="idle")
   evidence.ranged={pendingShotCancelled=true,targetHealth=health,retreating=true}
   service.combat:unregister(target);target:Destroy();p.Humanoid.Health=p.Humanoid.MaxHealth
  end)
  test("isolated native medic keeps retreating outside the arena and rejoins actual replacements",function()
   order("hold")
   local slots=army().slots;local m=slots.medic.rig
   local claim=service.registry:get(player.UserId)
   local foundation=service.world.model.Plots["Plot"..claim.plotId].Foundation
   local spawn=service.world:getBarracksSpawn(claim.plotId,"warrior","warrior").Position
   local homeward=Vector3.new(spawn.X-center.X,0,spawn.Z-center.Z).Unit
   freeze(m,center+homeward*220);m.HumanoidRootPart.Anchored=false;m.Humanoid.Health=m.Humanoid.MaxHealth
   local threat=Rig.createNeutral(CFrame.new(floorPoint(m.HumanoidRootPart.Position-homeward*8)),"warrior")
   threat.Parent=folder;freeze(threat,threat.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(threat,"warrior"));table.insert(extras,threat)
   for id,slot in slots do if id~="medic" then slot.rig.Humanoid.Health=0 end end
   waitFor(function()return not army().slots.warrior.rig and not army().slots.ranged.rig and not army().slots.camp.rig end,"all fighters await respawn")
   local start=m.HumanoidRootPart.Position
   order("advance")
   task.wait(5)
   local moved=(m.HumanoidRootPart.Position-start):Dot(homeward)
   assert(moved>35 and m:GetAttribute("WarriorState")=="Withdrawing to reinforcements","Medic stopped at old retreat bound")
   waitFor(function()return not CombatRules.containsArena(service.world.model.Battlefield,m.HumanoidRootPart.Position)end,"medic exits arena toward barracks",12)
   assert(Route.contains(foundation,center,m.HumanoidRootPart.Position),"Medic left its own approach corridor")
   waitFor(function()return army().slots.warrior.rig and army().slots.ranged.rig and army().slots.camp.rig end,"actual fresh fighter respawns",15)
   waitFor(function()
    local medic=m.HumanoidRootPart.Position
    for id,slot in army().slots do if id~="medic" and (slot.rig.HumanoidRootPart.Position-medic).Magnitude<=36 then
     return m:GetAttribute("WarriorState")~="Withdrawing to reinforcements"
    end end
    return false
   end,"withdrawal rejoins fresh troops",35)
   assert(army().slots.medic.rig==m)
   evidence.withdrawal={movementAfterFiveSeconds=moved,leftArena=true,ownCorridor=true,rejoinedFreshTroops=true}
   service.combat:unregister(threat);threat:Destroy();order("hold")
  end)
  test("medical homeward corridors remain bounded for all rotated plots",function()
   for _,plot in service.world.model.Plots:GetChildren()do
    local f=plot.Foundation;local frame=f.CFrame
    assert(Route.contains(f,center,frame:PointToWorldSpace(Vector3.new(0,3,146))))
    assert(not Route.contains(f,center,frame:PointToWorldSpace(Vector3.new(300,3,0))))
    assert(not Route.contains(f,center,frame:PointToWorldSpace(Vector3.new(0,3,200))))
   end
  end)
  return {ok=true,cases=cases,evidence=evidence}
 end)
 for _,item in extras do if item.Parent then if item:IsA("Model")then service.combat:unregister(item)end;item:Destroy()end end
 for rig,value in anchored do if rig.Parent then rig.HumanoidRootPart.Anchored=value end end
 assert(ok,result)
 return result
end

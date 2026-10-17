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
  test("critical native fighter closes a healing gap and releases support at forty percent",function()
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
   waitFor(function()return (p.HumanoidRootPart.Position-m.HumanoidRootPart.Position).Magnitude<=45 end,"actual fighter reaches healing range",12)
   assert(p:GetAttribute("CombatPhase")=="idle" and p:GetAttribute("WeaponSkillActive")==nil)
   waitFor(function()return p.Humanoid.Health>=p.Humanoid.MaxHealth*.4 end,"critical fighter recovers forty percent",25)
   waitFor(function()return not p:GetAttribute("MedicalSupportActive") end,"fighter resumes Advance",3)
   assert(math.abs(p:GetAttribute("WeaponSkillReadyAt")-cooldown)<.05)
   evidence.recovery={initialDistance=initial,health=p.Humanoid.Health,maxHealth=p.Humanoid.MaxHealth,
    state=p:GetAttribute("WarriorState"),cooldownPreserved=true}
   order("hold")
   p.Humanoid.Health=20;local held=p.HumanoidRootPart.Position;task.wait(.5)
   assert((held-p.HumanoidRootPart.Position).Magnitude<1 and p:GetAttribute("WarriorState")~="Seeking medic")
  end)
  test("critical melee fights inside healing range and resumes outside pursuit at forty percent",function()
   order("hold")
   local slots=army().slots;local m,p=slots.medic.rig,slots.warrior.rig
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center);freeze(p,center+Vector3.new(40,0,0));p.HumanoidRootPart.Anchored=false
   freeze(slots.ranged.rig,center+Vector3.new(-70,0,0));freeze(slots.camp.rig,center+Vector3.new(-60,0,0))
   local target=Rig.createNeutral(CFrame.new(floorPoint(center+Vector3.new(44,0,0))),"warrior")
   target.Parent=folder;freeze(target,target.HumanoidRootPart.Position);target.Humanoid.MaxHealth=1000;target.Humanoid.Health=1000
   assert(service.combat:registerNeutral(target,"warrior"));table.insert(extras,target)
   order("advance");p.Humanoid.Health=20
   waitFor(function()return p:GetAttribute("MedicalSupportActive") end,"critical support entry",2)
   local before=target.Humanoid.Health
   waitFor(function()return target.Humanoid.Health<before end,"new melee strike while already critical",3)
   assert(p:GetAttribute("MedicalSupportActive") and p.Humanoid.Health<p.Humanoid.MaxHealth*.4)
   freeze(target,center+Vector3.new(70,0,0))
   local furthest=0
   waitFor(function()
    if p:GetAttribute("MedicalSupportActive") then
     furthest=math.max(furthest,(p.HumanoidRootPart.Position-m.HumanoidRootPart.Position).Magnitude)
    end
    return p.Humanoid.Health>=p.Humanoid.MaxHealth*.4 and not p:GetAttribute("MedicalSupportActive")
   end,"forty percent releases pursuit",12)
   assert(furthest<=46,"Critical pursuit left medic range")
   waitFor(function()return (p.HumanoidRootPart.Position-m.HumanoidRootPart.Position).Magnitude>50 end,"healed fighter may leave medic radius",6)
   evidence.combatRange={damageWhileCritical=true,maxCriticalDistance=furthest,releasedAt=p.Humanoid.Health,canLeaveAfterRecovery=true}
   service.combat:unregister(target);target:Destroy()
  end)
  test("critical ranged support retains an actual pending shot and can keep firing",function()
   order("hold")
   local slots=army().slots;local m,p=slots.medic.rig,slots.ranged.rig
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center+Vector3.new(0,0,30));freeze(p,center)
   freeze(slots.warrior.rig,center+Vector3.new(-70,0,0));freeze(slots.camp.rig,center+Vector3.new(-60,0,0))
   local target=Rig.createNeutral(CFrame.new(floorPoint(center+Vector3.new(0,0,-40))),"warrior")
   target.Parent=folder;freeze(target,target.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(target,"warrior"));table.insert(extras,target)
   local health=target.Humanoid.Health
   waitFor(function()return #service.world.model.TroopProjectiles:GetChildren()>0 end,"actual ranged shot launch",5)
   local firstRelease=p:GetAttribute("LastAttackAt")
   assert(firstRelease)
   p.Humanoid.Health=20;p.HumanoidRootPart.Anchored=false
   assert(service.command(player,"order","advance").ok)
   waitFor(function()return target.Humanoid.Health<health end,"pending critical shot contacts",2)
   local first=target.Humanoid.Health
   -- Firing and impact have separate two-second cadences. Moving closer can
   -- make the next impact arrive inside the prior damage cooldown.
   waitFor(function()return (p:GetAttribute("LastAttackAt") or 0)>firstRelease end,"critical ranged releases another shot",4)
   assert(p:GetAttribute("MedicalSupportActive"),"Archer only resumed after critical support ended")
   waitFor(function()return target.Humanoid.Health<first end,"later valid ranged impact",6)
   evidence.ranged={pendingShotRetained=true,continuedFiring=true,targetHealth=target.Humanoid.Health}
   service.combat:unregister(target);target:Destroy();p.Humanoid.Health=p.Humanoid.MaxHealth
  end)
  test("medic advances directly then supports the troop average while healing independently",function()
   order("hold")
   local slots=army().slots;local m=slots.medic.rig
   local claim=service.registry:get(player.UserId)
   local spawn=service.world:getBarracksSpawn(claim.plotId,"warrior","warrior").Position
   local back=Vector3.new(spawn.X-center.X,0,spawn.Z-center.Z).Unit
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center+back*360);m.HumanoidRootPart.Anchored=false
   freeze(slots.warrior.rig,center+back*380);freeze(slots.camp.rig,center+back*540);freeze(slots.ranged.rig,center+back*580)
   waitFor(function()return workspace:GetServerTimeNow()>=(m:GetAttribute("BandageReadyAt") or 0)
    and #service.world.model.MedicalBandages:GetChildren()==0 end,"medic ready for moving cast",4)
   order("advance");slots.warrior.rig.Humanoid.Health=20;local castAfter=workspace:GetServerTimeNow();task.wait(1)
   local moving,backsteps=0,0;local previous=m.HumanoidRootPart.Position;local began=previous
   for _=1,30 do
    task.wait(.1);local root=m.HumanoidRootPart
    if root.AssemblyLinearVelocity.Magnitude>5 then moving+=1 end
    if (root.Position-previous):Dot(back)>.3 then backsteps+=1 end
    assert(m:GetAttribute("WarriorState")=="Advancing to battlefield")
    previous=root.Position
   end
   assert((began-m.HumanoidRootPart.Position):Dot(back)>24 and moving>=24 and backsteps==0,"Deployment hesitated or followed rear troops")
   assert(slots.warrior.rig.Humanoid.Health>=32 and m:GetAttribute("BandageThrownAt")>=castAfter,"Medic did not heal while advancing")
   waitFor(function()return CombatRules.containsArena(service.world.model.Battlefield,m.HumanoidRootPart.Position)end,"actual battlefield arrival",15)
   freeze(m,center+back*180);m.HumanoidRootPart.Anchored=false
   freeze(slots.warrior.rig,center+back*20);freeze(slots.camp.rig,center+back*60);freeze(slots.ranged.rig,center+back*100)
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   local mean=(slots.warrior.rig.HumanoidRootPart.Position+slots.camp.rig.HumanoidRootPart.Position+slots.ranged.rig.HumanoidRootPart.Position)/3
   waitFor(function()return (m.HumanoidRootPart.Position-mean).Magnitude<=12 end,"actual support at troop average",15)
   local averageDistance=(m.HumanoidRootPart.Position-mean).Magnitude
   local patient=slots.ranged.rig;patient.Humanoid.Health=20
   local start=m.HumanoidRootPart.Position
   waitFor(function()return patient.Humanoid.Health>=32 end,"heal patient behind without chasing it",5)
   assert((m.HumanoidRootPart.Position-start):Dot(back)<2)
   evidence.centroid={movingSamples=moving,samples=30,backsteps=backsteps,averageDistance=averageDistance,patientHealth=patient.Humanoid.Health,healedWhileAdvancing=true}
   order("hold")
  end)
  test("deaths and actual rearward replacements keep the medic on the battlefield",function()
   order("hold")
   local slots=army().slots;local m=slots.medic.rig
   local claim=service.registry:get(player.UserId)
   local spawn=service.world:getBarracksSpawn(claim.plotId,"warrior","warrior").Position
   local back=Vector3.new(spawn.X-center.X,0,spawn.Z-center.Z).Unit
   freeze(m,center+back*10);m.HumanoidRootPart.Anchored=false
   for id,slot in slots do if id~="medic" then slot.rig.Humanoid.Health=0 end end
   waitFor(function()return not army().slots.warrior.rig and not army().slots.ranged.rig and not army().slots.camp.rig end,"all fighters await replacement")
   order("advance")
   local start=m.HumanoidRootPart.Position;local worst=0
   waitFor(function()
    worst=math.max(worst,(m.HumanoidRootPart.Position-start):Dot(back))
    return army().slots.warrior.rig and army().slots.ranged.rig and army().slots.camp.rig
   end,"actual rearward replacements",16)
   task.wait(2)
   worst=math.max(worst,(m.HumanoidRootPart.Position-start):Dot(back))
   assert(worst<2 and (m.HumanoidRootPart.Position-center).Magnitude<25 and army().slots.medic.rig==m,"Medic returned toward replacements")
   evidence.respawns={maxBacktrack=worst,stayedOnBattlefield=true,sameMedicLife=true}
   order("hold")
  end)
  test("only a real enemy authorizes continued backward avoidance beyond three seconds",function()
   order("hold")
   local slots=army().slots;local m=slots.medic.rig
   local claim=service.registry:get(player.UserId)
   local spawn=service.world:getBarracksSpawn(claim.plotId,"warrior","warrior").Position
   local back=Vector3.new(spawn.X-center.X,0,spawn.Z-center.Z).Unit
   freeze(m,center+back*20);m.HumanoidRootPart.Anchored=false
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   local threat=Rig.createNeutral(CFrame.new(floorPoint(m.HumanoidRootPart.Position-back*8)),"warrior")
   threat.Parent=folder;freeze(threat,threat.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(threat,"warrior"));table.insert(extras,threat)
   order("advance")
   local start=m.HumanoidRootPart.Position;local afterThree
   local began=os.clock()
   repeat
    freeze(threat,m.HumanoidRootPart.Position-back*8)
    if os.clock()-began>=3 and not afterThree then afterThree=m.HumanoidRootPart.Position end
    task.wait(.05)
   until os.clock()-began>=4.5
   local movement=(m.HumanoidRootPart.Position-start):Dot(back)
   local late=(m.HumanoidRootPart.Position-afterThree):Dot(back)
   assert(movement>24 and late>8 and m:GetAttribute("WarriorState")=="Avoiding enemies","Avoidance stopped at the old timeout")
   service.combat:unregister(threat);threat:Destroy()
   waitFor(function()return m:GetAttribute("WarriorState")~="Avoiding enemies" end,"next plan clears enemy avoidance",2)
   local cleared=m.HumanoidRootPart.Position;task.wait(1)
   assert((m.HumanoidRootPart.Position-cleared):Dot(back)<1,"Medic kept retreating after enemy disappeared")
   evidence.avoidance={movement=movement,afterThreeSeconds=late,stoppedWhenThreatCleared=true}
   order("hold")
  end)
  test("medic resumes after danger clears without waiting for outside replacements",function()
   order("hold")
   local slots=army().slots;local m=slots.medic.rig
   local claim=service.registry:get(player.UserId)
   local spawn=service.world:getBarracksSpawn(claim.plotId,"warrior","warrior").Position
   local back=Vector3.new(spawn.X-center.X,0,spawn.Z-center.Z).Unit
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   freeze(m,center+back*180);m.HumanoidRootPart.Anchored=false
   freeze(slots.warrior.rig,center+back*330)
   freeze(slots.ranged.rig,center+back*400);freeze(slots.camp.rig,center+back*510)
   local threat=Rig.createNeutral(CFrame.new(floorPoint(m.HumanoidRootPart.Position-back*8)),"warrior")
   threat.Parent=folder;freeze(threat,threat.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(threat,"warrior"));table.insert(extras,threat)
   local start=m.HumanoidRootPart.Position
   order("advance")
   waitFor(function()return (m.HumanoidRootPart.Position-start):Dot(back)>5 end,"actual enemy escape",5)
   service.combat:unregister(threat);threat:Destroy()
   waitFor(function()return m:GetAttribute("WarriorState")~="Avoiding enemies" end,"cleared threat plan",2)
   local cleared=m.HumanoidRootPart.Position
   waitFor(function()return (cleared-m.HumanoidRootPart.Position):Dot(back)>18 end,"Advance with every fighter still outside",6)
   local resumed=(cleared-m.HumanoidRootPart.Position):Dot(back)
   for id,slot in slots do if id~="medic" then
    assert(not CombatRules.containsArena(service.world.model.Battlefield,slot.rig.HumanoidRootPart.Position))
   end end
   -- Two fighters arrive; one replacement remains far outside the field.
   order("hold")
   freeze(m,center+back*180);m.HumanoidRootPart.Anchored=false
   freeze(slots.warrior.rig,center+back*80);freeze(slots.ranged.rig,center+back*100)
   local partial=m.HumanoidRootPart.Position
   order("advance")
   waitFor(function()return (partial-m.HumanoidRootPart.Position):Dot(back)>18 end,"support while one replacement remains outside",6)
   assert(not CombatRules.containsArena(service.world.model.Battlefield,slots.camp.rig.HumanoidRootPart.Position))
   evidence.fieldArrivals={advanceAfterEscape=resumed,advanceWithOneOutside=(partial-m.HumanoidRootPart.Position):Dot(back),sameMedicLife=army().slots.medic.rig==m}
   order("hold")
  end)
  test("a chased medic bends toward wounded allies and keeps throwing bandages",function()
   order("hold")
   local slots=army().slots;local m,p=slots.medic.rig,slots.warrior.rig
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   local origin=center+Vector3.new(-100,0,-80)
   freeze(m,origin);m.HumanoidRootPart.Anchored=false
   freeze(p,origin+Vector3.new(35,0,0))
   freeze(slots.ranged.rig,center+Vector3.new(0,0,350))
   freeze(slots.camp.rig,center+Vector3.new(0,0,400))
   local threat=Rig.createNeutral(CFrame.new(floorPoint(origin+Vector3.new(0,0,-8))),"warrior")
   threat.Parent=folder;freeze(threat,threat.HumanoidRootPart.Position)
   assert(service.combat:registerNeutral(threat,"warrior"));table.insert(extras,threat)
   waitFor(function()return workspace:GetServerTimeNow()>=(m:GetAttribute("BandageReadyAt") or 0)
    and #service.world.model.MedicalBandages:GetChildren()==0 end,"ready bandage for pursuit",4)
   local start=m.HumanoidRootPart.Position
   order("advance")
   p.Humanoid.Health=40
   local began=os.clock();local minimumGap=math.huge
   repeat
    -- A moving hostile keeps the medic in avoidance throughout the observation.
    minimumGap=math.min(minimumGap,(m.HumanoidRootPart.Position-threat.HumanoidRootPart.Position).Magnitude)
    freeze(threat,m.HumanoidRootPart.Position+Vector3.new(0,0,-8))
    task.wait(.05)
   until os.clock()-began>=1.8
   local movement=m.HumanoidRootPart.Position-start
   assert(movement.X>6 and movement.Z>6,"Medic did not bend its escape toward the wounded ally")
   assert(m:GetAttribute("WarriorState")=="Avoiding enemies" and minimumGap>=7)
   waitFor(function()return p.Humanoid.Health>=52 end,"bandage heals during enemy pursuit",2)
   evidence.patientEscape={towardPatient=movement.X,awayFromEnemy=movement.Z,patientHealth=p.Humanoid.Health,minimumGap=minimumGap}
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

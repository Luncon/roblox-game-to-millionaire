-- Production services, one real client, injected fake profiles. Never real storage.
return function(context,player,round)
 assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
 local service=context.service
 local Game=game.ServerScriptService.Game
 local Data=require(Game.ProfileData)
 local Rig=require(Game.WarriorRig)
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local cases,evidence=0,{}
 local extras,anchored={},{}
 local function waitFor(predicate,label,seconds)
  local deadline=os.clock()+(seconds or 10)
  repeat if predicate()then return end;task.wait(.02)until os.clock()>deadline
  error("Timed out: "..label)
 end
 local function test(name,fn)
  game:SetAttribute("MedicalSupportVerificationPhase",name);fn();cases+=1;print("PASS: "..name)
 end
 local function choose(id)
  if player:GetAttribute("CivilizationId")==id then return end
  round("civilizationInput",{action="choose",civilization=id},30)
  waitFor(function()return player:GetAttribute("CivilizationId")==id end,"choose "..id)
  task.wait(.4)
 end
 local function state(hospital)
  local s=Data.defaultState()
  s.level,s.weaponLevel,s.armorLevel,s.trainingLevel,s.barracksLevel,s.armyCampLevel,s.coins=50,50,50,1,5,1,1000
  s.hospitalLevel=hospital or 0
  return s
 end
 local function army()return assert(service.army:get(player.UserId))end
 local function order(value)
  task.wait(.35);assert(service.command(player,"order",value).ok)
 end
 local function freeze(rig,position)
  local root=rig.HumanoidRootPart
  if anchored[rig]==nil then anchored[rig]=root.Anchored end
  root.Anchored=true;rig:PivotTo(CFrame.new(position));root.AssemblyLinearVelocity=Vector3.zero
 end
 local function floorPoint(x,z)
  local arena=service.world.model.Battlefield
  local p=arena.Position+Vector3.new(x,0,z)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
  local hit=assert(workspace:Raycast(p+Vector3.new(0,40,0),Vector3.new(0,-100,0),params))
  return Vector3.new(p.X,hit.Position.Y+3,p.Z)
 end
 local neutral
 local function dummy(point)
  local rig=Rig.createNeutral(CFrame.new(point),"warrior");rig.Parent=neutral
  freeze(rig,point);rig.Humanoid.MaxHealth,rig.Humanoid.Health=1000,1000
  assert(service.combat:registerNeutral(rig,"warrior"));table.insert(extras,rig);return rig
 end
 local function clearExtras()
  for _,item in extras do if item:IsA("Model")then service.combat:unregister(item)end;item:Destroy()end
  table.clear(extras)
 end
 local ok,result=pcall(function()
  choose("britain");assert(service.profiles:set(player.UserId,"sparta",state()))
  choose("sparta");order("hold")
  service.neutralOpponents:destroy()
  neutral=Instance.new("Folder");neutral.Name="NeutralOpponents";neutral.Parent=service.world.model
  test("hospital physical purchase preserves fighters and pending deadline and charges once",function()
   local claim=service.registry:get(player.UserId)
   local plot=service.world.model.Plots["Plot"..claim.plotId]
   local before=army();local warrior,camp=before.slots.warrior.rig,before.slots.camp.rig
   freeze(warrior,warrior.HumanoidRootPart.Position);warrior.Humanoid.Health=60
   before.slots.ranged.rig.Humanoid.Health=0
   waitFor(function()return army().slots.ranged.rig==nil end,"pending ranged")
   local deadline=army().slots.ranged.respawnAt
   local pad=assert(plot.Controls:FindFirstChild("HospitalButton"))
   player.Character:PivotTo(pad.CFrame*CFrame.new(-30,4,0))
   assert(not service.buttons:activate(player,claim.plotId,"hospital").ok,"Distant hospital purchase accepted")
   assert(not service.buttons:activate(player,claim.plotId%8+1,"hospital").ok,"Foreign hospital purchase accepted")
   player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round("developmentInput",{kind="pad",action="hospital"},30)
   waitFor(function()return army().slots.medic and army().slots.medic.rig end,"hospital medic")
   assert(service.economy:get(player.UserId).coins==800 and player:GetAttribute("HospitalLevel")==1)
   assert(army().slots.warrior.rig==warrior and warrior.Humanoid.Health==60 and army().slots.camp.rig==camp)
   assert(army().slots.ranged.respawnAt==deadline and not plot.Controls:FindFirstChild("HospitalButton"))
   assert(not service.buttons:activate(player,claim.plotId,"hospital").ok)
   evidence.purchase={coins=800,pendingRangedAt=deadline,warriorHealth=60}
   waitFor(function()return army().slots.ranged.rig~=nil end,"existing ranged deadline",16)
   assert(player:GetAttribute("ArmyCount")==4 and player:GetAttribute("WarriorCount")==2 and player:GetAttribute("RangedCount")==1 and player:GetAttribute("MedicCount")==1)
  end)
  test("stationary Hold fighters attack while the medic visibly throws and heals",function()
   local slots=army().slots
   freeze(slots.medic.rig,floorPoint(0,0));freeze(slots.warrior.rig,floorPoint(12,0))
   freeze(slots.camp.rig,floorPoint(-30,0));freeze(slots.ranged.rig,floorPoint(-40,0))
   slots.warrior.rig.Humanoid.Health=50
   local enemy=dummy(floorPoint(12,-4));local enemyHealth=enemy.Humanoid.Health
   local coins=service.economy:get(player.UserId).coins
   local held=slots.medic.rig.HumanoidRootPart.Position
   local seen=false
   waitFor(function()
    if #service.world.model.MedicalBandages:GetChildren()>0 then seen=true end
    return seen and slots.warrior.rig.Humanoid.Health>=62 and enemy.Humanoid.Health<enemyHealth
   end,"Hold attack plus visible bandage healing",8)
   assert((held-slots.medic.rig.HumanoidRootPart.Position).Magnitude<.05)
   assert(not service.combat:hit(slots.medic.rig,enemy).ok and not service.combat.skills:activate(slots.medic.rig,"advance",true).ok)
   local projectiles=require(Game.TroopProjectile).new(service.world,service.combat)
   assert(not projectiles:fire(slots.medic.rig,enemy,"arrow"));projectiles:destroy()
   assert(service.economy:get(player.UserId).coins==coins)
   evidence.hold={visibleBandage=seen,health=slots.warrior.rig.Humanoid.Health,enemyHealth=enemy.Humanoid.Health,medicMovement=(held-slots.medic.rig.HumanoidRootPart.Position).Magnitude}
   clearExtras()
  end)
  test("native moving patients and mid-flight obstacles produce misses without a cooldown refund",function()
   local slots=army().slots;local patient=slots.warrior.rig;local medic=slots.medic.rig
   patient.Humanoid.Health=40
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"moving-target bandage launch",5)
   local ready=medic:GetAttribute("BandageReadyAt")
   freeze(patient,floorPoint(12,12))
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()==0 end,"miss expiry",2)
   assert(patient.Humanoid.Health==40 and medic:GetAttribute("BandageReadyAt")==ready)
   freeze(patient,floorPoint(12,0))
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"obstructed flight launch",5)
   local wall=Instance.new("Part");wall.Name="MedicalMidFlightFixture";wall.Size=Vector3.new(1,12,12)
   wall.Anchored=true;wall.Position=floorPoint(6,0)+Vector3.new(0,2,0);wall.Parent=service.world.model;table.insert(extras,wall)
   ready=medic:GetAttribute("BandageReadyAt")
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()==0 end,"native swept obstacle",2)
   assert(patient.Humanoid.Health==40 and medic:GetAttribute("BandageReadyAt")==ready)
   clearExtras();evidence.misses={movingPatientHealth=40,blockedPatientHealth=40,cooldownRetained=true}
  end)
  test("native obstruction blocks bandages and cooldown is retained on Regroup",function()
   local slots=army().slots
   slots.warrior.rig.Humanoid.Health=40
   local wall=Instance.new("Part");wall.Name="MedicalObstructionFixture";wall.Size=Vector3.new(1,12,12)
   wall.Anchored=true;wall.Position=floorPoint(6,0)+Vector3.new(0,2,0);wall.Parent=service.world.model;table.insert(extras,wall)
   local before=slots.warrior.rig.Humanoid.Health
   task.wait(3.5);assert(slots.warrior.rig.Humanoid.Health==before)
   clearExtras()
   waitFor(function()return #service.world.model.MedicalBandages:GetChildren()>0 end,"new bandage launch",5)
   local ready=slots.medic.rig:GetAttribute("BandageReadyAt")
   -- Immediate server command at an observed launch, avoiding the helper's delay.
   assert(service.command(player,"order","regroup").ok)
   assert(#service.world.model.MedicalBandages:GetChildren()==0 and slots.medic.rig:GetAttribute("BandageReadyAt")==ready)
   evidence.cancel={readyAt=ready,flightsAfterRegroup=0}
  end)
  test("owned yard recovers all four troops to MaxHealth without a live medic requirement",function()
   local claim=service.registry:get(player.UserId)
   local frame=service.world.model.Plots["Plot"..claim.plotId].Foundation.CFrame
   for id,slot in army().slots do
    freeze(slot.rig,frame:PointToWorldSpace(Camp.point(Camp.arrivalIndex(id))))
    slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth-10
   end
   task.wait(1);for _,slot in army().slots do assert(slot.rig.Humanoid.Health==slot.rig.Humanoid.MaxHealth-10)end
   waitFor(function()for _,slot in army().slots do if slot.rig.Humanoid.Health<slot.rig.Humanoid.MaxHealth then return false end end;return true end,"four full-health recoveries",6)
   local medic=army().slots.medic.rig
   medic.Humanoid.Health=0
   waitFor(function()return army().slots.medic.rig==nil end,"medic death")
   local deadline=army().slots.medic.respawnAt
   assert(deadline-workspace:GetServerTimeNow()>14.5 and player:GetAttribute("MedicCount")==0 and player:GetAttribute("ArmyCount")==3)
   local fighter=army().slots.warrior.rig;fighter.Humanoid.Health=50
   waitFor(function()return fighter.Humanoid.Health>=55 end,"yard healing without medic",5)
   freeze(fighter,frame:PointToWorldSpace(Camp.center+Vector3.new(20,2.15,0)))
   local hp=fighter.Humanoid.Health;task.wait(1.5);assert(fighter.Humanoid.Health==hp)
   assert(army().slots.medic.respawnAt==deadline)
   local plot=service.world.model.Plots["Plot"..claim.plotId]
   local pad=assert(plot.Controls:FindFirstChild("Barracks6Button"))
   player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round("developmentInput",{kind="pad",action="barracks6"},30)
   assert(service.economy:get(player.UserId).barracksLevel==6 and service.economy:get(player.UserId).coins==500)
   assert(army().slots.medic.respawnAt==deadline and army().slots.warrior.rig==fighter)
   waitFor(function()return army().slots.medic.rig~=nil end,"independent fifteen-second medic",16)
   assert(army().slots.medic.rig~=medic and army().slots.warrior.rig==fighter and army().order=="regroup")
   evidence.recovery={medicDeadline=deadline,healingWithoutMedic=true,outsideHealth=hp}
  end)
  test("hospital ownership restores through civilization switches without stale rigs",function()
   local old=army().slots.medic.rig
   choose("britain");local other=service.army:get(player.UserId);assert(not old.Parent and (not other or not other.slots.medic))
   choose("sparta");assert(service.economy:get(player.UserId).hospitalLevel==1 and army().slots.medic.rig~=old)
   evidence.switch={hospitalRestored=true,oldRigDestroyed=true}
  end)
  test("native hospital deployment reaches the backline and retreats from a close threat",function()
   local slots=army().slots
   for id,slot in slots do if id~="medic" then freeze(slot.rig,floorPoint(if id=="warrior" then 8 elseif id=="ranged" then -8 else 0,0))end end
   local medic=slots.medic.rig;medic.HumanoidRootPart.Anchored=false
   order("advance")
   waitFor(function()return (medic.HumanoidRootPart.Position-floorPoint(0,12)).Magnitude<22 end,"hospital to battlefield backline",90)
   local start=medic.HumanoidRootPart.Position
   local opponent=dummy(start+Vector3.new(0,0,-8))
   waitFor(function()return medic:GetAttribute("WarriorState")=="Avoiding enemies" end,"threat-first retreat",5)
   waitFor(function()return (medic.HumanoidRootPart.Position-start).Magnitude>3 end,"visible native retreat",5)
   task.wait(3)
   local displacement=(medic.HumanoidRootPart.Position-start).Magnitude
   assert(displacement<=19,"Medic escaped beyond its retreat bound")
   evidence.advance={deploymentReached=true,retreatDisplacement=displacement}
   clearExtras()
   for _,slot in slots do slot.rig.HumanoidRootPart.Anchored=false;slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth-10 end
   order("regroup")
   local claim=service.registry:get(player.UserId);local frame=service.world.model.Plots["Plot"..claim.plotId].Foundation.CFrame
   waitFor(function()for _,slot in army().slots do if not Camp.contains(frame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position),1)then return false end end;return true end,"four actual camp arrivals",90)
   waitFor(function()for _,slot in army().slots do if slot.rig.Humanoid.Health<slot.rig.Humanoid.MaxHealth then return false end end;return true end,"walking army full recovery",8)
   evidence.advance.fourCampArrivals=true
  end)
  test("early hospital without Army Camp can deploy reach the army and return to its yard",function()
   choose("britain")
   local s=state(1);s.level,s.weaponLevel,s.armorLevel,s.barracksLevel,s.armyCampLevel=10,10,10,4,0
   assert(service.profiles:set(player.UserId,"maurya",s));choose("maurya")
   local slots=army().slots;assert(not slots.camp and slots.medic and player:GetAttribute("TroopCapacity")==3)
   order("hold")
   freeze(slots.warrior.rig,floorPoint(8,0));freeze(slots.ranged.rig,floorPoint(-8,0))
   order("advance")
   local medic=slots.medic.rig
   waitFor(function()return (medic.HumanoidRootPart.Position-floorPoint(0,12)).Magnitude<22 end,"early hospital deployment",90)
   for _,slot in slots do slot.rig.HumanoidRootPart.Anchored=false end
   order("regroup")
   local claim=service.registry:get(player.UserId);local frame=service.world.model.Plots["Plot"..claim.plotId].Foundation.CFrame
   waitFor(function()return Camp.contains(frame:PointToObjectSpace(medic.HumanoidRootPart.Position),1)end,"early medic return to yard",90)
   evidence.early={armyCampRequired=false,deployed=true,returned=true}
  end)
  test("a wall-blocked critical patient does not prevent a visible native bandage hit",function()
   choose("sparta");order("hold")
   local slots=army().slots
   freeze(slots.medic.rig,floorPoint(0,0));freeze(slots.warrior.rig,floorPoint(12,0))
   freeze(slots.ranged.rig,floorPoint(0,14));freeze(slots.camp.rig,floorPoint(-30,0))
   for _,slot in slots do slot.rig.Humanoid.Health=slot.rig.Humanoid.MaxHealth end
   local wall=Instance.new("Part");wall.Name="MedicalPatientVisibilityFixture";wall.Size=Vector3.new(1,12,6)
   wall.Anchored=true;wall.Position=floorPoint(6,0)+Vector3.new(0,2,0);wall.Parent=service.world.model;table.insert(extras,wall)
   slots.warrior.rig.Humanoid.Health=10;slots.ranged.rig.Humanoid.Health=40
   waitFor(function()return slots.ranged.rig.Humanoid.Health>=52 end,"visible lower-priority patient",6)
   assert(slots.warrior.rig.Humanoid.Health==10)
   evidence.visiblePatient={blockedHealth=10,visibleHealth=slots.ranged.rig.Humanoid.Health}
   clearExtras()
  end)
  test("sustained native combat measures healing and natural independent medic replacement",function()
   neutral=nil
   evidence.combat=require(game.ServerStorage.RuntimeTests.MedicalCombat)(context,player,{
    choose=choose,order=order,freeze=freeze,floorPoint=floorPoint,waitFor=waitFor,
    inspectHUD=function()return round("medicalHUD",{},10)end,
   })
  end)
  test("native four-slot hospital presentation fits the current viewport",function()
   evidence.hud=round("medicalHUD",{},10)
  end)
  test("Advance seeks the wounded front and keeps healing through an actual fighter replacement",function()
   order("hold")
   local slots=army().slots
   local medic,patient,oldRanged=slots.medic.rig,slots.warrior.rig,slots.ranged.rig
   freeze(medic,floorPoint(0,90));medic.HumanoidRootPart.Anchored=false
   freeze(patient,floorPoint(0,0));freeze(slots.camp.rig,floorPoint(12,0))
   patient.Humanoid.Health=20
   oldRanged.Humanoid.Health=0
   waitFor(function()return army().slots.ranged.rig==nil end,"ranged replacement wait")
   local deadline=army().slots.ranged.respawnAt
   order("advance")
   waitFor(function()return patient.Humanoid.Health>=32 end,"unanchored medic approaches and heals wounded front",12)
   local approached=(medic.HumanoidRootPart.Position-patient.HumanoidRootPart.Position).Magnitude
   assert(approached<=45 and army().slots.medic.rig==medic)
   waitFor(function()return army().slots.ranged.rig~=nil end,"actual distant ranged replacement",15)
   local replacement=army().slots.ranged.rig
   assert(replacement~=oldRanged and workspace:GetServerTimeNow()>=deadline)
   local replacementDistance=(replacement.HumanoidRootPart.Position-patient.HumanoidRootPart.Position).Magnitude
   assert(replacementDistance>150,"Replacement was not still far behind the front")
   patient.Humanoid.Health=20
   local furthest=0
   waitFor(function()
    furthest=math.max(furthest,(medic.HumanoidRootPart.Position-patient.HumanoidRootPart.Position).Magnitude)
    return patient.Humanoid.Health>=32
   end,"healing continues after healthy replacement",5)
   assert(furthest<=47 and army().slots.medic.rig==medic)
   neutral=Instance.new("Folder");neutral.Name="NeutralOpponents";neutral.Parent=service.world.model
   local start=medic.HumanoidRootPart.Position
   local enemy=dummy(start+Vector3.new(0,0,-8))
   waitFor(function()return medic:GetAttribute("WarriorState")=="Avoiding enemies" end,"wounded patient does not override threat avoidance",3)
   waitFor(function()return (medic.HumanoidRootPart.Position-enemy.HumanoidRootPart.Position).Magnitude>10 end,"actual threat-first retreat movement",3)
   evidence.seeking={approachedDistance=approached,replacementDistance=replacementDistance,
    furthestAfterRespawn=furthest,patientHealth=patient.Humanoid.Health,threatRetreat=true}
   clearExtras();order("hold")
  end)
  return {ok=true,cases=cases,evidence=evidence,message="Fake-store solo native medical checks; two-owner, live storage and manual movement/animation acceptance are separate."}
 end)
 clearExtras()
 for rig,value in anchored do if rig.Parent and rig:FindFirstChild("HumanoidRootPart")then rig.HumanoidRootPart.Anchored=value end end
 if neutral then neutral:Destroy()end
 assert(ok,result)
 return result
end

-- Native production services and input; all profiles use the injected fake store.
return function(context,player,round,combatOnly)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service;local G=game.ServerScriptService.Game;local S=game.ReplicatedStorage.Shared
 local Data=require(G.ProfileData);local F=require(G.ArmyFormation);local Camp=require(S.TrainingCampConfig)
 local Rack=require(G.ShieldRack);local Topography=require(G.Topography)
 local cases,evidence=0,{}
 local function test(name,fn,preparation)
  if combatOnly and preparation then return end
  game.ReplicatedStorage:SetAttribute('FormationVerificationPhase',name)
  fn();cases+=1;print('PASS: '..name)
  game.ReplicatedStorage:SetAttribute('VikingEvidence',game.HttpService:JSONEncode(evidence))
 end
 local function waitFor(fn,label,seconds)
  local deadline=os.clock()+(seconds or 10)
  repeat if fn()then return end;task.wait(.03)until os.clock()>deadline
  error('Timed out: '..label)
 end
 local function choose(id)round('civilizationInput',{action='choose',civilization=id},30)end
 local function army()return assert(service.army:get(player.UserId))end
 local function order(value)task.wait(.35);assert(service.command(player,'order',value).ok)end
 local function plot()return service.world.model.Plots['Plot'..service.registry:get(player.UserId).plotId]end
 local function ground(p)
  local base=service.world.model.Ground;local v=base.CFrame:PointToObjectSpace(p)
  return base.CFrame:PointToWorldSpace(Vector3.new(v.X,.95+Topography.sampleHeight(v.X,v.Z)+3,v.Z))
 end
 local function muster()
  order('regroup');local frame=plot().Foundation.CFrame
  for id,slot in army().slots do
   assert(slot.rig)
   if slot.rig:GetAttribute('AwaitingShieldSupply')then
    local rack=plot().Infrastructure.ShieldRack;slot.rig:PivotTo(CFrame.new(Rack.goal(rack,id)))
    assert(Rack.collect(slot.rig,rack,id,'regroup',service.economy:get(player.UserId),true))
   end
   slot.rig:PivotTo(frame*CFrame.new(Camp.point(Camp.arrivalIndex(id))))
  end
  task.wait(.5)
 end
 local function march()
  task.wait(.35);local result=service.command(player,'march');assert(result.ok,tostring(result.reason));return army().formation
 end
 local function battlefield()
  muster();local g=march();g.anchor=ground(service.world.model.Battlefield.Position+Vector3.new(0,0,100));g.phase='marching'
  g.destination=g.anchor+g.heading*80
  for id,p in F.goals(g,ground)do army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))end
  task.wait(.4);assert(army().formation==g);return g
 end
 local function enemy(point)
  local folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model
  local civ;for _,v in require(S.Civilizations)do if v.id=='britain'then civ=v end end
  local rig=require(G.WarriorRig).create(civ,CFrame.new(ground(point)),0,0,nil,'warrior')
  rig.HumanoidRootPart.Anchored=true;rig.Humanoid.MaxHealth=10000;rig.Humanoid.Health=10000;rig.Parent=folder
  assert(service.combat:registerNeutral(rig,'warrior'));return rig,folder
 end
 choose('britain')
 local s=Data.defaultState();s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,20,15,6
 s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel,s.skillLevel=1,1,1,1,1
 if combatOnly then
  s.armyCampLevel,s.shieldLevel,s.warCouncilLevel,s.formationLevel=2,1,1,1;s.selectedFormation='viking-shield-wedge'
 end
 assert(service.profiles:set(player.UserId,'vikings',s));choose('vikings');order('hold');service.neutralOpponents:destroy()
 test('Viking physical purchases and council selection enforce ownership proximity and authority',function()
  for _,item in {{'shield','ShieldButton'},{'armyCamp','ArmyCampButton'},{'warCouncil','WarCouncilButton'},{'formation','FormationButton'}}do
   local pad=assert(plot().Controls:FindFirstChild(item[2]));player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round('developmentInput',{kind='pad',action=item[1]},30)
  end
  assert(service.economy:get(player.UserId).coins==2150 and player.Character:GetAttribute('ShieldCharges')==2)
  player.Character:PivotTo(plot().Foundation.CFrame*CFrame.new(0,3,0))
  assert(not service.command(player,'formation','viking-shield-wedge').ok)
  player.Character:PivotTo(plot().Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.5)
  local canMutate=service.economy.canMutate;service.economy.canMutate=function()return false end
  assert(not service.command(player,'formation','viking-shield-wedge').ok);service.economy.canMutate=canMutate
  assert(not service.command(player,'formation','roman-shield-guard').ok)
  round('formationInput',{},20)
  assert(service.profiles:get(player.UserId,'vikings').selectedFormation=='viking-shield-wedge')
  evidence.unlock={coins=2150,selected='viking-shield-wedge',rack=plot().Infrastructure.ShieldRack~=nil}
 end,true)
 test('fresh Viking shieldman walks to the rack before joining the Training Yard',function()
  local old=army().slots.camp.rig;old.Humanoid.Health=0
  waitFor(function()return army().slots.camp.rig and army().slots.camp.rig~=old end,'fresh Viking life',17)
  local r=army().slots.camp.rig;assert(r:GetAttribute('ShieldCharges')==0 and r:GetAttribute('AwaitingShieldSupply'))
  local start=r.HumanoidRootPart.Position;order('regroup')
  waitFor(function()return r:GetAttribute('ShieldCharges')==2 end,'fresh physical Viking pickup',20)
  assert(army().slots.camp.rig==r and not r.HumanoidRootPart.Anchored and r:GetAttribute('ShieldRestockedAt'))
  waitFor(function()return Camp.contains(plot().Foundation.CFrame:PointToObjectSpace(r.HumanoidRootPart.Position),1.5)end,'Viking return to camp',20)
  evidence.supply={sameLife=true,walked=(r.HumanoidRootPart.Position-start).Magnitude,charges=2}
 end,true)
 test('Viking road assembly and unanchored wedge march release at center at the shared pace',function()
  muster();round('developmentInput',{kind='command',button='MarchFormation'},20);local g=army().formation
  waitFor(function()return g.phase=='marching'end,'pointed road assembly',90)
  local began=os.clock();local start=g.anchor;local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  repeat
   task.wait(.05)
   for id,slot in army().slots do assert(slot.rig==lives[id] and not slot.rig.HumanoidRootPart.Anchored)end
  until army().order=='advance' or os.clock()-began>115
  local seconds=os.clock()-began;local distance=(g.anchor-start).Magnitude
  assert(army().order=='advance' and not army().formation and distance>100 and distance/seconds>4 and distance/seconds<=6.5,'Wedge march stalled')
  evidence.march={seconds=seconds,distance=distance,pace=distance/seconds}
 end,true)
 test('visible Viking frontline contact releases stalled cohesion into attacks axe skills and healing',function()
  local g=battlefield();local r=army().slots.warrior.rig;local start=r.HumanoidRootPart.Position
  local patient=army().slots.camp.rig;patient.Humanoid.Health=patient.Humanoid.MaxHealth-30;local hp=patient.Humanoid.Health
  local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  -- A slightly lagging medic prevents coherent anchor motion, but cannot block contact release.
  local medic=lives.medic;medic:PivotTo(CFrame.new(medic.HumanoidRootPart.Position-g.heading*7))
  local foe,folder=enemy(start+g.heading*4);local skillSeen=false
  waitFor(function()return army().order=='advance' and not army().formation end,'Viking melee contact release',3)
  for id,slot in army().slots do assert(slot.rig==lives[id] and slot.rig:GetAttribute('FormationActive')~=true)end
  assert(r:GetAttribute('ShieldCharges')==2)
  waitFor(function()
   skillSeen=skillSeen or r:GetAttribute('WeaponSkillActive')=='axe'
   return foe.Humanoid.Health<10000 and patient.Humanoid.Health>hp and skillSeen
  end,'ordinary Viking combat and support',9)
  local ready=r:GetAttribute('WeaponSkillReadyAt');assert(ready>workspace:GetServerTimeNow())
  evidence.contact={released=true,enemyHealth=foe.Humanoid.Health,patientHealth=patient.Humanoid.Health,axeSkill=true}
  folder:Destroy()
  waitFor(function()return r:GetAttribute('WeaponSkillActive')==nil and r.Humanoid.WalkSpeed==require(S.WarriorConfig).walkSpeed end,'normal movement after Viking skill',4)
  assert(r:GetAttribute('WeaponSkillReadyAt')==ready,'Contact release reset the skill deadline')
 end)
 test('occluded Viking melee proximity retains formation until sight clears',function()
  local g=battlefield();local r=army().slots.warrior.rig;local start=r.HumanoidRootPart.Position
  local medic=army().slots.medic.rig;medic:PivotTo(CFrame.new(medic.HumanoidRootPart.Position-g.heading*18))
  local foe,folder=enemy(start+g.heading*4)
  local wall=Instance.new('Part');wall.Size=Vector3.new(20,16,1);wall.Anchored=true;wall.CanCollide=false
  wall.CFrame=CFrame.lookAt((start+foe.HumanoidRootPart.Position)/2,foe.HumanoidRootPart.Position);wall.Parent=folder
  task.wait(.4);assert(army().formation==g,'Occluded enemy broke the wedge')
  wall:Destroy();waitFor(function()return army().order=='advance' and not army().formation end,'clear melee sight releases',3)
  evidence.occlusion={retained=true,releasedWhenClear=true};folder:Destroy()
 end)
 test('Viking Hold attacks heals and survives contact while Advance and Regroup cancel formation',function()
  local g=battlefield();order('hold');local r=army().slots.warrior.rig;local start=r.HumanoidRootPart.Position
  r.Humanoid.Health=r.Humanoid.MaxHealth-30;local hp=r.Humanoid.Health
  local foe,folder=enemy(start+g.heading*4)
  waitFor(function()return foe.Humanoid.Health<10000 and r.Humanoid.Health>hp end,'held Viking attacks and healing',8)
  assert(army().formation==g and army().order=='hold' and (r.HumanoidRootPart.Position-start).Magnitude<1.5)
  folder:Destroy();order('advance');assert(not army().formation and army().order=='advance')
  muster();march();order('regroup');assert(not army().formation and army().order=='regroup')
  evidence.orders={holdStationary=true,advanceCancels=true,regroupCancels=true}
 end)
 test('Viking frontline casualty releases Advance and preserves independent respawn deadlines',function()
  local g=battlefield();local old=army().slots.camp.rig;old.Humanoid.Health=0
  waitFor(function()return not army().formation and army().order=='advance'end,'Viking casualty release',3)
  local deadline=army().slots.camp.respawnAt;assert(deadline>workspace:GetServerTimeNow())
  waitFor(function()return army().slots.camp.rig and army().slots.camp.rig~=old end,'Viking casualty replacement',17)
  assert(army().slots.camp.rig:GetAttribute('FormationActive')~=true)
  battlefield();order('hold');local r=army().slots.warrior.rig;local start=r.HumanoidRootPart.Position
  army().slots.reinforcement.rig.Humanoid.Health=0
  waitFor(function()return not army().formation end,'held Viking casualty release',3);task.wait(.5)
  assert(army().order=='hold' and (r.HumanoidRootPart.Position-start).Magnitude<1.5)
  evidence.casualty={deadline=deadline,replacementJoined=false,explicitHoldPreserved=true}
 end)
 return {ok=true,cases=cases,evidence=evidence}
end

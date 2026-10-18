-- Production services and native physics/input with explicitly injected fake profiles.
return function(context,player,round,resupplyOnly)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service;local G=game.ServerScriptService.Game;local S=game.ReplicatedStorage.Shared
 local Data=require(G.ProfileData);local F=require(G.ArmyFormation);local Camp=require(S.TrainingCampConfig)
 local Config=require(S.FormationConfig);local Rack=require(G.ShieldRack);local Topography=require(G.Topography)
 local count,evidence=0,{}
 local function test(name,fn,supply)
  if resupplyOnly and not supply then return end
  game.ReplicatedStorage:SetAttribute('FormationVerificationPhase',name)
  fn();count+=1;print('PASS: '..name)
  game.ReplicatedStorage:SetAttribute('PersianEvidence',game.HttpService:JSONEncode(evidence))
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
 local function state(unlocked,id)
  local s=Data.defaultState();s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,20,15,6
  s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel,s.skillLevel=1,1,1,1,1
  if unlocked then s.armyCampLevel=2;s.shieldLevel=1;s.warCouncilLevel=1;s.formationLevel=1;s.selectedFormation=Config.forCivilization(id).id end
  return s
 end
 local function seed(id,unlocked)
  if player:GetAttribute('CivilizationId')==id then choose('britain')end
  assert(service.profiles:set(player.UserId,id,state(unlocked,id)));choose(id);order('hold')
 end
 local function muster()
  order('regroup');local frame=plot().Foundation.CFrame
  for id,slot in army().slots do assert(slot.rig);slot.rig:PivotTo(frame*CFrame.new(Camp.point(Camp.arrivalIndex(id))))end
  task.wait(.5)
 end
 local function march()task.wait(.35);local result=service.command(player,'march');assert(result.ok,tostring(result.reason));return army().formation end
 local function deployed()
  muster();local g=march();g.anchor=ground(service.world.model.Battlefield.Position+Vector3.new(0,0,100));g.phase='screening'
  for id,p in F.goals(g,ground)do army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))end
  task.wait(.5);assert(player:GetAttribute('FormationPhase')=='screening');return g
 end
 local function enemy(point)
  local folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model
  local civ;for _,v in require(S.Civilizations)do if v.id=='britain'then civ=v end end
  local r=require(G.WarriorRig).create(civ,CFrame.new(ground(point)),0,0,nil,'warrior')
  r.HumanoidRootPart.Anchored=true;r.Humanoid.MaxHealth=10000;r.Humanoid.Health=10000;r.Parent=folder
  assert(service.combat:registerNeutral(r,'warrior'))
  return r,folder
 end
 local function destroy(r,folder)service.combat:unregister(r);folder:Destroy()end
 local function spend(r)
  local shield=require(G.ShieldCombat)
  while (r:GetAttribute('ShieldCharges') or 0)>0 do
   assert(shield.block({rig=r,position=r.HumanoidRootPart.Position,root=r.HumanoidRootPart},r.HumanoidRootPart.Position+r.HumanoidRootPart.CFrame.LookVector*4))
  end
 end
 seed('persia',resupplyOnly==true);service.neutralOpponents:destroy()
 test('Persian physical shield council and screen purchases preserve faction ownership',function()
  for _,item in {{'shield','ShieldButton'},{'armyCamp','ArmyCampButton'},{'warCouncil','WarCouncilButton'},{'formation','FormationButton'}}do
   local pad=assert(plot().Controls:FindFirstChild(item[2]));player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round('developmentInput',{kind='pad',action=item[1]},30)
   if item[1]=='shield'then assert(plot().Infrastructure:FindFirstChild('ShieldRack'))end
  end
  assert(service.economy:get(player.UserId).coins==2150 and player.Character:GetAttribute('ShieldCharges')==2)
  assert(not service.command(player,'formation','roman-shield-guard').ok)
  player.Character:PivotTo(plot().Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.5)
  round('formationInput',{},20)
  assert(service.profiles:get(player.UserId,'persia').selectedFormation=='persian-archer-screen')
  evidence.purchases={coins=2150,selected='persian-archer-screen',rack=true}
 end)
 test('Persian unanchored road assembly walks a straight screen and stops at actual bow range before center',function()
  muster();round('developmentInput',{kind='command',button='MarchFormation'},20)
  local g=army().formation
  waitFor(function()return g.phase=='marching'end,'straight road assembly',90)
  local starts={};local lives={};for id,slot in army().slots do starts[id]=slot.rig.HumanoidRootPart.Position;lives[id]=slot.rig end
  local r,folder=enemy(service.world.model.Battlefield.Position+Vector3.new(0,0,160))
  local anchor=g.anchor;local began=os.clock();local last=table.clone(starts);local previous=began
  repeat
   task.wait(.05);local now=os.clock();local dt=now-previous;previous=now
   for id,slot in army().slots do
    assert(slot.rig==lives[id] and not slot.rig.HumanoidRootPart.Anchored)
    local p=slot.rig.HumanoidRootPart.Position
    assert((p-last[id]).Magnitude<math.max(4,dt*30),'Screen teleported');last[id]=p
   end
  until g.phase=='screening' or os.clock()-began>85
  assert(g.phase=='screening' and army().formation==g and (g.anchor-g.destination).Magnitude>100,'Screen did not deploy early')
  local bow=lives.ranged;local range=(bow.HumanoidRootPart.Position-r.HumanoidRootPart.Position).Magnitude
  assert(range<=40.5 and range>35,'Unexpected deployment range: '..range)
  local released=bow:GetAttribute('LastAttackAt') or 0
  waitFor(function()return (bow:GetAttribute('LastAttackAt')or 0)>released and r.Humanoid.Health<10000 end,'ordinary arrow release and damage',9)
  assert(bow:GetAttribute('WeaponSkillActive')==nil)
  local front=lives.warrior;front.Humanoid.Health=front.Humanoid.MaxHealth-20;local hp=front.Humanoid.Health
  waitFor(function()return front.Humanoid.Health>hp end,'deployed medic healing',6)
  local frozen=g.anchor;r:PivotTo(CFrame.new(r.HumanoidRootPart.Position+g.heading*100));task.wait(1)
  destroy(r,folder);task.wait(1)
  assert(g.phase=='screening' and (g.anchor-frozen).Magnitude<.01,'Target loss resumed marching')
  evidence.march={seconds=os.clock()-began,distance=(g.anchor-anchor).Magnitude,bowRange=range,latched=true,arrowDamage=true}
 end)
 test('deployed Persian guard physically engages locally and returns after a retreat without chasing',function()
  local g=army().formation;local r=army().slots.camp.rig;local center=F.goals(g,ground).camp
  local right=Vector3.new(-g.heading.Z,0,g.heading.X);local foe,folder=enemy(center-right*8)
  local before=r:GetAttribute('LastContactAt')or 0;local skillBefore=r:GetAttribute('WeaponSkillStartedAt')or 0
  local maxDistance,moved,skill=0,0,false;local deadline=os.clock()+10
  repeat
   task.wait(.03);local d=(r.HumanoidRootPart.Position-center).Magnitude;maxDistance=math.max(maxDistance,d);moved=math.max(moved,d)
   skill=skill or (r:GetAttribute('WeaponSkillStartedAt')or 0)>skillBefore
  until (r:GetAttribute('LastContactAt')or 0)>before or os.clock()>deadline
  assert((r:GetAttribute('LastContactAt')or 0)>before and moved>1 and maxDistance<=7,'Guard failed bounded engagement')
  assert(skill,'Persian guard did not use its stationary spear skill')
  foe:PivotTo(CFrame.new(ground(center-right*35)))
  waitFor(function()maxDistance=math.max(maxDistance,(r.HumanoidRootPart.Position-center).Magnitude);return (r.HumanoidRootPart.Position-center).Magnitude<2.5 end,'guard returns to slot',6)
  assert(maxDistance<=7 and army().formation==g and g.phase=='screening')
  evidence.guard={maxDistance=maxDistance,engaged=true,returned=true,stationarySkill=skill};destroy(foe,folder)
 end)
 test('occluded bow opportunities keep marching until visibility opens',function()
  muster();local g=march();g.anchor=ground(service.world.model.Battlefield.Position+Vector3.new(0,0,130));g.phase='marching'
  for id,p in F.goals(g,ground)do army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))end
  local bow=army().slots.ranged.rig;local r,folder=enemy(bow.HumanoidRootPart.Position+g.heading*35)
  local wall=Instance.new('Part');wall.Size=Vector3.new(30,12,1);wall.Anchored=true;wall.CanCollide=false
  wall.CFrame=CFrame.lookAt((bow.HumanoidRootPart.Position+r.HumanoidRootPart.Position)/2,r.HumanoidRootPart.Position);wall.Parent=folder
  task.wait(.5);assert(g.phase=='marching','Occluded foe deployed the screen')
  wall:Destroy();waitFor(function()return g.phase=='screening'end,'clear sight deploys',4)
  destroy(r,folder)
 end)
 test('empty final destination deploys instead of releasing the Persian formation',function()
  muster();local g=march();g.anchor=g.destination;g.phase='marching'
  for id,p in F.goals(g,ground)do army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))end
  waitFor(function()return g.phase=='screening'end,'empty center deployment',4)
  assert(army().order=='formation' and player:GetAttribute('FormationPhase')=='screening')
 end)
 test('Persian Hold preserves attacks healing and positions and explicit orders discard screening',function()
  local g=deployed();round('developmentInput',{kind='command',button='Hold'},20)
  local saved={};for id,slot in army().slots do saved[id]=slot.rig.HumanoidRootPart.Position end
  local front=army().slots.warrior.rig;front.Humanoid.Health=front.Humanoid.MaxHealth-25;local hp=front.Humanoid.Health
  local r,folder=enemy(front.HumanoidRootPart.Position+g.heading*4)
  waitFor(function()return r.Humanoid.Health<10000 and front.Humanoid.Health>hp end,'held screen contact and heal',7)
  for id,slot in army().slots do assert((slot.rig.HumanoidRootPart.Position-saved[id]).Magnitude<1.5)end
  destroy(r,folder);order('advance');assert(not army().formation and army().order=='advance')
  deployed();order('regroup');assert(not army().formation and army().order=='regroup')
 end)
 test('Persian support replacement stays outside captured screen and frontline loss releases Advance',function()
  local g=deployed();local old=army().slots.ranged.rig;old.Humanoid.Health=0
  waitFor(function()return not army().slots.ranged.rig end,'support death',3)
  assert(army().formation==g and g.phase=='screening' and not g.members.ranged)
  waitFor(function()return army().slots.ranged.rig end,'support replacement',17)
  assert(army().slots.ranged.rig~=old and army().slots.ranged.rig:GetAttribute('FormationActive')~=true)
  army().slots.camp.rig.Humanoid.Health=0
  waitFor(function()return army().order=='advance' and not army().formation end,'broken screen releases Advance',3)
  waitFor(function()return army().slots.camp.rig end,'front replacement',17)
 end)
 test('recalled spent shields physically visit supplies before camp in Sparta Rome and Persia',function()
  local records={}
  for _,id in {'sparta','rome','persia'}do
   seed(id,true);local frame=plot().Foundation.CFrame;local rack=assert(plot().Infrastructure.ShieldRack)
   local slots=army().slots;local warrior=slots.warrior.rig;local partial=slots.camp.rig
   spend(warrior);assert(require(G.ShieldCombat).block({rig=partial,position=partial.HumanoidRootPart.Position,root=partial.HumanoidRootPart},partial.HumanoidRootPart.Position+partial.HumanoidRootPart.CFrame.LookVector*4))
   warrior.Humanoid.Health=57;local cooldown=workspace:GetServerTimeNow()+60;warrior:SetAttribute('WeaponSkillReadyAt',cooldown)
   local tool=warrior:FindFirstChildOfClass('Tool');local start=ground(frame:PointToWorldSpace(Vector3.new(-118,3,-55)))
   warrior:PivotTo(CFrame.new(start));local point=Rack.goal(rack,'warrior')
   assert((start-point).Magnitude>20)
   round('developmentInput',{kind='command',button='Regroup'},20)
   waitFor(function()
    assert(army().slots.warrior.rig==warrior and not warrior.HumanoidRootPart.Anchored)
    if warrior:GetAttribute('ShieldCharges')==2 then assert((warrior.HumanoidRootPart.Position-point).Magnitude<3);return true end
    return false
   end,'actual '..id..' pickup trip',20)
   assert(warrior.Humanoid.Health==57 and warrior:GetAttribute('WeaponSkillReadyAt')==cooldown and warrior:FindFirstChildOfClass('Tool')==tool)
   local shields=0;for _,item in warrior:GetDescendants()do if item:GetAttribute('CombatShield')==true then shields+=1 end end;assert(shields==1)
   waitFor(function()return Camp.contains(frame:PointToObjectSpace(warrior.HumanoidRootPart.Position),1.5)end,'resupplied '..id..' camp return',20)
   assert(partial:GetAttribute('ShieldCharges')==1 and partial:GetAttribute('ShieldRestockedAt')==nil)
   records[id]={walked=(warrior.HumanoidRootPart.Position-start).Magnitude,charges=2,sameLife=true,healthAtPickup=57}
  end
  evidence.resupply=records
 end,true)
 test('three depleted shieldmen share the rack and return to camp without duplicate shields',function()
  order('hold');local frame=plot().Foundation.CFrame;local lives={}
  for index,id in {'warrior','camp','reinforcement'}do
   local r=army().slots[id].rig;lives[id]=r;spend(r)
   r:PivotTo(CFrame.new(ground(frame:PointToWorldSpace(Vector3.new(-118+index*6,3,-55)))))
  end
  order('regroup')
  waitFor(function()
   for id,r in lives do if r:GetAttribute('ShieldCharges')~=2 then return false end;assert(army().slots[id].rig==r)end
   return true
  end,'three simultaneous resupply walks',25)
  waitFor(function()
   for _,r in lives do if not Camp.contains(frame:PointToObjectSpace(r.HumanoidRootPart.Position),1.5)then return false end end
   return true
  end,'three resupplied camp arrivals',25)
  for _,r in lives do local shields=0;for _,item in r:GetDescendants()do if item:GetAttribute('CombatShield')==true then shields+=1 end end;assert(shields==1)end
  evidence.concurrentSupply={troops=3,sameLives=true,oneShieldEach=true}
 end,true)
 test('Hold Advance and lost write authority interrupt distant shield pickup',function()
  local warrior=army().slots.warrior.rig;spend(warrior)
  local frame=plot().Foundation.CFrame;local start=ground(frame:PointToWorldSpace(Vector3.new(-105,3,-70)))
  for _,command in {'hold','advance'}do
   order('hold');warrior:PivotTo(CFrame.new(start));order('regroup')
   waitFor(function()return warrior:GetAttribute('WarriorState')=='Collecting shield'end,'pickup route started',3)
   order(command);task.wait(.6);assert(warrior:GetAttribute('ShieldCharges')==0,'Cancelled route granted shield')
  end
  order('hold');warrior:PivotTo(CFrame.new(start));order('regroup')
  local canMutate=service.economy.canMutate;service.economy.canMutate=function()return false end
  task.wait(.6);assert(warrior:GetAttribute('ShieldCharges')==0)
  local paused=warrior.HumanoidRootPart.Position
  service.economy.canMutate=canMutate
  waitFor(function()return (warrior.HumanoidRootPart.Position-paused).Magnitude>1 end,'pickup resumes after writable authority returns',4)
  order('hold')
 end,true)
 return {ok=true,cases=count,evidence=evidence}
end

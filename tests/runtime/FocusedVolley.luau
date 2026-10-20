-- Native production services/input with explicitly injected fake profiles only.
return function(context,player,round,combatOnly)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service;local G=game.ServerScriptService.Game;local S=game.ReplicatedStorage.Shared
 local Data=require(G.ProfileData);local F=require(G.ArmyFormation);local Camp=require(S.TrainingCampConfig)
 local Topography=require(G.Topography)
 local cases,evidence=0,{}
 local function test(name,fn,preparation)
  if combatOnly and preparation then return end
  game.ReplicatedStorage:SetAttribute('FormationVerificationPhase',name)
  fn();cases+=1;print('PASS: '..name)
  game.ReplicatedStorage:SetAttribute('SenecaEvidence',game.HttpService:JSONEncode(evidence))
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
   assert(slot.rig);slot.rig:PivotTo(frame*CFrame.new(Camp.point(Camp.arrivalIndex(id))))
  end
  task.wait(.5)
 end
 local function march()
  task.wait(.35);local result=service.command(player,'march');assert(result.ok,tostring(result.reason));return army().formation
 end
 local function battlefield()
  muster();local g=march();g.anchor=ground(service.world.model.Battlefield.Position+Vector3.new(0,0,100));g.phase='screening'
  g.destination=g.anchor+g.heading*80
  for id,p in F.goals(g,ground)do army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))end
  task.wait(.4);assert(army().formation==g);return g
 end
 local function enemy(point)
  local folder=service.world.model:FindFirstChild('NeutralOpponents')
  if not folder then folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model end
  local civ;for _,v in require(S.Civilizations)do if v.id=='britain'then civ=v end end
  local rig=require(G.WarriorRig).create(civ,CFrame.new(ground(point)),0,0,nil,'warrior')
  rig.HumanoidRootPart.Anchored=true;rig.Humanoid.MaxHealth=10000;rig.Humanoid.Health=10000;rig.Parent=folder
  assert(service.combat:registerNeutral(rig,'warrior'));return rig,folder
 end
 local function noShields()
  assert(not plot().Controls:FindFirstChild('ShieldButton') and not plot().Infrastructure:FindFirstChild('ShieldRack'))
  local rigs={player.Character};for _,slot in army().slots do if slot.rig then table.insert(rigs,slot.rig)end end
  for _,rig in rigs do
   assert((rig:GetAttribute('ShieldCharges')or 0)==0 and not rig:GetAttribute('AwaitingShieldSupply'))
   for _,item in rig:GetDescendants()do assert(item:GetAttribute('CombatShield')~=true)end
  end
 end
 choose('britain')
 local s=Data.defaultState();s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,20,1,6
 s.trainingLevel,s.armyCampLevel,s.hospitalLevel=1,1,1
 if combatOnly then
  s.armyCampLevel,s.warCouncilLevel,s.formationLevel=2,1,1;s.selectedFormation='seneca-focused-volley'
  s.recruitMelee,s.recruitRanged,s.recruitMedic=1,3,1
 end
 assert(service.profiles:set(player.UserId,'seneca',s));choose('seneca');order('hold');service.neutralOpponents:destroy()
 test('Seneca native purchases council and Barracks recruit shieldless one three one',function()
  for _,item in {{'armyCamp','ArmyCampButton'},{'warCouncil','WarCouncilButton'},{'formation','FormationButton'}}do
   local pad=assert(plot().Controls:FindFirstChild(item[2]));player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round('developmentInput',{kind='pad',action=item[1]},30)
  end
  assert(service.economy:get(player.UserId).coins==2300)
  player.Character:PivotTo(plot().Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.5)
  round('formationInput',{},20)
  assert(service.profiles:get(player.UserId,'seneca').selectedFormation=='seneca-focused-volley')
  local board=plot().Settlement.Barracks.RecruitmentBoard
  player.Character:PivotTo(board.CFrame*CFrame.new(0,-1,-3));task.wait(.2)
  local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  evidence.recruitment=round('recruitmentInput',{melee=1},25)
  for id,slot in army().slots do assert(slot.rig==lives[id])end
  lives.camp.Humanoid.Health=0;lives.reinforcement.Humanoid.Health=0
  waitFor(function()return army().slots.camp.rig and army().slots.camp.rig~=lives.camp
   and army().slots.reinforcement.rig and army().slots.reinforcement.rig~=lives.reinforcement end,'three ranged lives',17)
  for _,id in {'camp','reinforcement','ranged'}do assert(army().slots[id].kind=='ranged')end
  noShields();evidence.unlock={coins=2300,armor=1,shieldless=true}
 end,true)
 test('Seneca crescent assembles and walks unanchored at six studs then deploys on a clear shot',function()
  muster();round('developmentInput',{kind='command',button='MarchFormation'},20);local g=army().formation
  waitFor(function()return g.phase=='marching'end,'crescent road assembly',90)
  local foe,folder=enemy(service.world.model.Battlefield.Position+Vector3.new(0,0,160))
  local start=g.anchor;local began=os.clock();local lives={};local last={}
  for id,slot in army().slots do lives[id]=slot.rig;last[id]=slot.rig.HumanoidRootPart.Position end
  local previous=began;local budget=(start-foe.HumanoidRootPart.Position).Magnitude/6+25
  repeat
   task.wait(.05);local now=os.clock();local dt=now-previous;previous=now
   for id,slot in army().slots do
    assert(slot.rig==lives[id] and not slot.rig.HumanoidRootPart.Anchored)
    local p=slot.rig.HumanoidRootPart.Position;assert((p-last[id]).Magnitude<math.max(4,dt*30),'Crescent teleported');last[id]=p
   end
  until g.phase=='screening' or os.clock()-began>budget
  assert(army().formation==g and g.phase=='screening','Crescent march stalled')
  local nearest=math.huge
  for _,id in {'camp','reinforcement','ranged'}do nearest=math.min(nearest,(lives[id].HumanoidRootPart.Position-foe.HumanoidRootPart.Position).Magnitude)end
  assert(nearest<=40.5 and (g.anchor-g.destination).Magnitude>80,'Did not deploy on the ranged opportunity')
  local pace=(g.anchor-start).Magnitude/(os.clock()-began);assert(pace>4 and pace<=6.5)
  waitFor(function()return foe.Humanoid.Health<10000 end,'actual deployed arrow damage',8)
  local frozen=g.anchor;folder:Destroy();task.wait(.7);assert((g.anchor-frozen).Magnitude<.01)
  evidence.march={pace=pace,range=nearest,latched=true}
 end,true)
 test('three Seneca archers focus live targets with staggered ordinary arrows and retarget after death',function()
  local g=battlefield();local right=Vector3.new(-g.heading.Z,0,g.heading.X)
  local a,fa=enemy(g.anchor+g.heading*29-right*8);local b,fb=enemy(g.anchor+g.heading*33+right*8)
  local shots={};local last={};local seen={};local deadline=os.clock()+10
  repeat
   task.wait(.03)
   for _,id in {'camp','reinforcement','ranged'}do
    local rig=army().slots[id].rig;local at=rig:GetAttribute('AttackStartedAt')
    if at and at~=last[id]then last[id]=at;table.insert(shots,{id=id,at=at});seen[id]=true end
    assert(rig:GetAttribute('WeaponSkillActive')==nil)
   end
  until seen.camp and seen.reinforcement and seen.ranged and a.Humanoid.Health<10000 or os.clock()>deadline
  assert(seen.camp and seen.reinforcement and seen.ranged and a.Humanoid.Health<10000,'Archers did not all fire')
  table.sort(shots,function(x,y)return x.at<y.at end)
  for i=2,#shots do assert(shots[i].at-shots[i-1].at>=.44,'Volley starts overlapped')end
  assert(g.focus and g.focus.rig==a,'Shared target was not retained')
  a.Humanoid.Health=0
  waitFor(function()return g.focus and g.focus.rig==b and b.Humanoid.Health<10000 end,'retarget surviving enemy',8)
  evidence.focus={shots=shots,firstHealth=a.Humanoid.Health,nextHealth=b.Humanoid.Health};fa:Destroy();fb:Destroy()
 end)
 test('Seneca blocked sight prevents volley damage and clearing sight reacquires',function()
  local g=battlefield();local foe,folder=enemy(g.anchor+g.heading*33)
  local wall=Instance.new('Part');wall.Size=Vector3.new(45,16,1);wall.Anchored=true;wall.CanCollide=false
  wall.CFrame=CFrame.lookAt(g.anchor+g.heading*18,g.anchor+g.heading*30);wall.Parent=folder
  task.wait(1);local hp=foe.Humanoid.Health;task.wait(1)
  assert(not g.focus and foe.Humanoid.Health==hp,'Blocked focus fired through geometry')
  wall:Destroy();waitFor(function()return g.focus and g.focus.rig==foe and foe.Humanoid.Health<hp end,'clear sight focus',8)
  evidence.occlusion=true;folder:Destroy()
 end)
 test('Seneca guard intercepts while archers evade within their captured local bounds',function()
  local g=battlefield();local goals=F.goals(g,ground);local bow=army().slots.camp.rig;local guard=army().slots.warrior.rig
  local foe,folder=enemy(goals.camp+g.heading*8);local maxBow,maxGuard,moved=0,0,0;local before=bow.HumanoidRootPart.Position
  local contact=guard:GetAttribute('LastContactAt')or 0;local deadline=os.clock()+8
  repeat
   task.wait(.03);maxBow=math.max(maxBow,(bow.HumanoidRootPart.Position-goals.camp).Magnitude)
   maxGuard=math.max(maxGuard,(guard.HumanoidRootPart.Position-goals.warrior).Magnitude)
   moved=math.max(moved,(bow.HumanoidRootPart.Position-before).Magnitude)
  until (guard:GetAttribute('LastContactAt')or 0)>contact and moved>1 or os.clock()>deadline
  assert(moved>1 and maxBow<=8.6 and maxGuard<=14.6,'Unbounded or missing defensive movement')
  assert((guard:GetAttribute('LastContactAt')or 0)>contact,'Guard failed to intercept')
  foe:PivotTo(CFrame.new(foe.HumanoidRootPart.Position+g.heading*100))
  waitFor(function()return (guard.HumanoidRootPart.Position-goals.warrior).Magnitude<2.5 end,'guard returns',8)
  evidence.defense={archer=maxBow,guard=maxGuard,moved=moved};folder:Destroy()
 end)
 test('Seneca Hold keeps attacks healing and positions while Advance and Regroup cancel',function()
  local g=battlefield();order('hold');local saved={};for id,slot in army().slots do saved[id]=slot.rig.HumanoidRootPart.Position end
  local guard=army().slots.warrior.rig;guard.Humanoid.Health=guard.Humanoid.MaxHealth-25;local hp=guard.Humanoid.Health
  local foe,folder=enemy(guard.HumanoidRootPart.Position+g.heading*4)
  waitFor(function()return foe.Humanoid.Health<10000 and guard.Humanoid.Health>hp end,'held volley attacks and heals',8)
  for id,slot in army().slots do assert((slot.rig.HumanoidRootPart.Position-saved[id]).Magnitude<1.5)end
  assert(army().formation==g);folder:Destroy();order('advance');assert(not army().formation and army().order=='advance')
  battlefield();order('regroup');assert(not army().formation and army().order=='regroup');noShields()
  evidence.orders={hold=true,advance=true,regroup=true}
 end)
 test('Seneca casualties retain captured archers but never adopt replacements',function()
  local g=battlefield();local old=army().slots.camp.rig;old.Humanoid.Health=0
  waitFor(function()return not g.members.camp end,'captured archer removed',3)
  assert(army().formation==g)
  waitFor(function()return army().slots.camp.rig and army().slots.camp.rig~=old end,'fresh archer life',17)
  assert(army().slots.camp.rig:GetAttribute('FormationActive')~=true and not g.members.camp)
  army().slots.reinforcement.rig.Humanoid.Health=0;army().slots.ranged.rig.Humanoid.Health=0
  waitFor(function()return not army().formation and army().order=='advance'end,'all captured archers lost',3)
  waitFor(function()return army().slots.reinforcement.rig and army().slots.ranged.rig end,'ranged replacements',17)
  battlefield();order('hold');army().slots.warrior.rig.Humanoid.Health=0
  waitFor(function()return not army().formation end,'guard casualty',3);assert(army().order=='hold')
  waitFor(function()return army().slots.warrior.rig end,'guard replacement',17)
  evidence.casualty={replacementJoined=false,archerLossReleased=true,heldGuardLossPreserved=true}
 end)
 test('Seneca write authority loss cancels volley and saved selection survives civilization switches',function()
  battlefield();local canMutate=service.economy.canMutate;service.economy.canMutate=function()return false end
  waitFor(function()return not army().formation end,'lost write authority cancels',3)
  assert(army().order=='hold');service.economy.canMutate=canMutate
  choose('britain');choose('seneca');order('hold')
  local state=service.economy:get(player.UserId);assert(state.selectedFormation=='seneca-focused-volley' and state.recruitRanged==3)
  noShields();evidence.authority={cancelled=true,selectionRestored=true,shieldless=true}
 end)
 return {ok=true,cases=cases,evidence=evidence}
end

-- Native production services with injected fake storage only.
return function(context,player,round)
 assert(context.store.isFakeProfileStore)
 local service=context.service;local G=game.ServerScriptService.Game
 local Data=require(G.ProfileData);local Rack=require(G.ShieldRack)
 local n,evidence=0,{}
 local function test(name,fn)
  game.ReplicatedStorage:SetAttribute('FormationVerificationPhase',name)
  fn();n+=1;print('PASS: '..name)
  game.ReplicatedStorage:SetAttribute('RecruitmentEvidence',game.HttpService:JSONEncode(evidence))
 end
 local function waitFor(fn,label,seconds)
  local untilAt=os.clock()+(seconds or 15)
  repeat if fn()then return end;task.wait(.03)until os.clock()>untilAt
  error('Timed out: '..label)
 end
 local function army()return assert(service.army:get(player.UserId))end
 local function command(action,value)
  task.wait(.42);return service.command(player,action,value)
 end
 local state=Data.defaultState();state.coins,state.level,state.weaponLevel,state.armorLevel,state.barracksLevel=3000,20,20,15,6
 state.trainingLevel,state.armyCampLevel,state.hospitalLevel,state.armorerLevel,state.shieldLevel=1,2,1,1,1
 state.warCouncilLevel,state.formationLevel,state.selectedFormation=1,1,'roman-shield-guard'
 assert(service.profiles:set(player.UserId,'rome',state))
 round('civilizationInput',{action='choose',civilization='rome'},30)
 service.neutralOpponents:destroy();assert(command('order','hold').ok)
 local claim=service.registry:get(player.UserId);local plot=service.world.model.Plots['Plot'..claim.plotId]
 local board=plot.Settlement.Barracks.RecruitmentBoard;local rack=plot.Infrastructure.ShieldRack
 local function nearBoard()player.Character:PivotTo(board.CFrame*CFrame.new(0,-1,-3));task.wait(.2)end
 test('fresh shieldmen spawn bare at relocated Barracks and Hold pauses supply travel',function()
  local before={}
  for id,slot in army().slots do if slot.kind=='warrior'then
   local rig=assert(slot.rig);assert(rig:GetAttribute('AwaitingShieldSupply') and rig:GetAttribute('ShieldCharges')==0)
   before[id]=rig.HumanoidRootPart.Position
   assert((rig.HumanoidRootPart.Position-service.world:getBarracksSpawn(claim.plotId,slot.kind,id).Position).Magnitude<4)
  end end
  task.wait(.6)
  for id,p in before do assert((army().slots[id].rig.HumanoidRootPart.Position-p).Magnitude<1)end
  evidence.bareSpawn=true
 end)
 test('fresh shieldmen walk to supplies and collect only at assigned pickups',function()
  local starts={};local lives={}
  for id,slot in army().slots do if slot.kind=='warrior'then starts[id]=slot.rig.HumanoidRootPart.Position;lives[id]=slot.rig end end
  assert(command('order','regroup').ok)
  local collected={};local deadline=os.clock()+25
  repeat
   for id,rig in lives do
    assert(army().slots[id].rig==rig)
    if rig:GetAttribute('ShieldCharges')==2 and not collected[id]then
     assert((rig.HumanoidRootPart.Position-Rack.goal(rack,id)).Magnitude<4,'Shield granted far from supplies')
     assert((rig.HumanoidRootPart.Position-starts[id]).Magnitude>5)
     collected[id]=true
    end
   end
   local done=true;for id in lives do if not collected[id]then done=false end end
   if done then break end;task.wait(.03)
  until os.clock()>deadline
  for id in lives do assert(collected[id],'No physical shield pickup: '..id)end
  evidence.walkedPickups=3
 end)
 test('Barracks request rejects distant foreign dead invalid and unwritable owners',function()
  assert(command('composition',{melee=0,ranged=0,medic=0}).reason=='barracks_too_far')
  nearBoard();assert(not command('composition',{melee=4,ranged=1,medic=1}).ok)
  plot:SetAttribute('OwnerId',player.UserId+1);assert(not command('composition',{melee=0,ranged=0,medic=0}).ok);plot:SetAttribute('OwnerId',player.UserId)
  assert(not command('class','ranged').ok,'Removed global class remote remains writable')
  evidence.authority=true
 end)
 test('native Barracks prompt count buttons save two melee two ranged without changing living troops',function()
  assert(command('order','hold').ok);nearBoard()
  local lives={};for id,slot in army().slots do lives[id]={rig=slot.rig,kind=slot.kind,health=slot.rig.Humanoid.Health}end
  evidence.input=round('recruitmentInput',{},25)
  for id,old in lives do local slot=army().slots[id];assert(slot.rig==old.rig and slot.kind==old.kind and slot.rig.Humanoid.Health==old.health)end
  assert(service.economy:get(player.UserId).recruitRanged==2)
 end)
 test('disabled and reenabled recruits preserve health cooldowns and pending deadlines',function()
  nearBoard();assert(command('composition',{melee=0,ranged=0,medic=0}).ok)
  local original=army().slots.warrior.rig;original.Humanoid.Health=57;original:SetAttribute('WeaponSkillReadyAt',12345)
  assert(army().slots.warrior.rig==original and original.Humanoid.Health==57)
  for _,slot in army().slots do slot.rig.Humanoid.Health=0 end
  waitFor(function()return player:GetAttribute('ArmyCount')==0 end,'disabled troop deaths',3)
  local deadlines={};for id,slot in army().slots do deadlines[id]=slot.respawnAt end
  task.wait(1);assert(player:GetAttribute('ArmyCount')==0)
  assert(command('composition',{melee=4,ranged=0,medic=1}).ok)
  for id,slot in army().slots do assert(not slot.rig and slot.respawnAt==deadlines[id])end
  waitFor(function()return player:GetAttribute('ArmyCount')==5 end,'recruits after preserved deadlines',17)
  for id,slot in army().slots do if id~='medic'then assert(slot.kind=='warrior' and slot.rig:GetAttribute('ShieldCharges')==0)end end
  evidence.deadlinesPreserved=true
 end)
 test('all four selected melee physically collect shields including the old ranged slot',function()
  assert(command('order','regroup').ok)
  waitFor(function()
   for id,slot in army().slots do if id~='medic' and slot.rig:GetAttribute('ShieldCharges')~=2 then return false end end
   return true
  end,'four physical supply pickups',25)
  for id,slot in army().slots do if id~='medic'then assert(not slot.rig:GetAttribute('AwaitingShieldSupply'))end end
  evidence.fourShieldmen=true
 end)
 return {cases=n,evidence=evidence}
end

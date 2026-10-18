-- Actual production army and native input; this place never opens player storage.
return function(context,player,round)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service
 local Data=require(game.ServerScriptService.Game.ProfileData)
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local cases,evidence=0,{}
 local function test(name,fn)
  game:SetAttribute('FormationVerificationPhase',name);fn();cases+=1
  game:SetAttribute('FormationEvidence',game.HttpService:JSONEncode(evidence));print('PASS: '..name)
 end
 local function waitFor(fn,label,seconds)
  local deadline=os.clock()+(seconds or 15)
  repeat if fn()then return end;task.wait(.03)until os.clock()>deadline
  error('Timed out: '..label)
 end
 local function choose(id)round('civilizationInput',{action='choose',civilization=id},30)end
 local function order(value)task.wait(.35);assert(service.command(player,'order',value).ok)end
 local function army()return assert(service.army:get(player.UserId))end
 local s=Data.defaultState()
 s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,5,15,6
 s.trainingLevel,s.armyCampLevel,s.hospitalLevel,s.armorerLevel=1,1,1,1
 choose('britain');assert(service.profiles:set(player.UserId,'sparta',s));choose('sparta');order('hold')
 service.neutralOpponents:destroy()
 test('Army Camp II native purchase adds one melee and preserves existing lives and deadlines',function()
  local claim=service.registry:get(player.UserId)
  local plot=service.world.model.Plots['Plot'..claim.plotId]
  local old=army();local warrior,camp,medic=old.slots.warrior.rig,old.slots.camp.rig,old.slots.medic.rig
  warrior.Humanoid.Health=60;old.slots.ranged.rig.Humanoid.Health=0
  waitFor(function()return not army().slots.ranged.rig end,'pending ranged replacement')
  local deadline=army().slots.ranged.respawnAt
  local pad=assert(plot.Controls:FindFirstChild('ArmyCampButton'))
  player.Character:PivotTo(pad.CFrame*CFrame.new(-30,4,0))
  assert(not service.buttons:activate(player,claim.plotId,'armyCamp').ok)
  player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
  round('developmentInput',{kind='pad',action='armyCamp'},30)
  waitFor(function()return army().slots.reinforcement and army().slots.reinforcement.rig end,'new melee')
  local actual=army()
  assert(service.economy:get(player.UserId).coins==2750 and player:GetAttribute('TroopCapacity')==5)
  assert(actual.slots.warrior.rig==warrior and warrior.Humanoid.Health==60 and actual.slots.camp.rig==camp and actual.slots.medic.rig==medic)
  assert(actual.slots.ranged.respawnAt==deadline and not plot.Controls:FindFirstChild('ArmyCampButton'))
  assert(actual.slots.reinforcement.kind=='warrior' and not actual.slots.reinforcement.rig.HumanoidRootPart.Anchored)
  evidence.campPurchase={coins=2750,preservedDeadline=deadline,preservedHealth=warrior.Humanoid.Health}
  waitFor(function()return army().slots.ranged.rig~=nil end,'original ranged respawn deadline',16)
 end)
 test('all five unanchored troops regroup and share the training camp',function()
  order('regroup')
  local claim=service.registry:get(player.UserId);local frame=service.world.model.Plots['Plot'..claim.plotId].Foundation.CFrame
  local started=os.clock()
  waitFor(function()
   for _,slot in army().slots do
    if not slot.rig or not Camp.contains(frame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position),2)then return false end
   end
   return true
  end,'five actual camp arrivals',90)
  local worst=0;local overlaps={};local now=os.clock();local began=now
  repeat
   task.wait(.05);local after=os.clock();local rigs={}
   for _,slot in army().slots do table.insert(rigs,slot.rig);assert(not slot.rig.HumanoidRootPart.Anchored)end
   for a=1,#rigs do for b=a+1,#rigs do
    local delta=rigs[a].HumanoidRootPart.Position-rigs[b].HumanoidRootPart.Position
    local key=a..':'..b
    overlaps[key]=if Vector3.new(delta.X,0,delta.Z).Magnitude<2 then (overlaps[key] or 0)+after-now else 0
    worst=math.max(worst,overlaps[key])
   end end
   now=after
  until now-began>8
  assert(worst<1,'Five-body camp left sustained overlap')
  evidence.camp={troops=5,seconds=os.clock()-started,longestOverlap=worst}
 end)
 return {ok=true,cases=cases,evidence=evidence}
end

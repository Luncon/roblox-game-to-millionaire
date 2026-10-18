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
 test('native shield council and formation purchases and physical map selection',function()
  local claim=service.registry:get(player.UserId)
  local plot=service.world.model.Plots['Plot'..claim.plotId]
  for _,item in {{'shield','ShieldButton'},{'warCouncil','WarCouncilButton'},{'formation','FormationButton'}}do
   local pad=assert(plot.Controls:FindFirstChild(item[2]),item[2]..' missing')
   player.Character:PivotTo(pad.CFrame*CFrame.new(-10,3,0))
   round('developmentInput',{kind='pad',action=item[1]},30)
  end
  assert(service.economy:get(player.UserId).coins==2150)
  assert(player.Character:GetAttribute('ShieldCharges')==2)
  for _,slot in army().slots do assert(slot.rig:GetAttribute('ShieldCharges')==(if slot.kind=='warrior' then 2 else 0))end
  player.Character:PivotTo(plot.Foundation.CFrame*CFrame.new(-100,4,40))
  task.wait(.35);assert(not service.command(player,'formation','spartan-shieldwall').ok)
  assert(service.economy:get(player.UserId).selectedFormation=='none')
  player.Character:PivotTo(plot.Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.5)
  evidence.selection=round('formationInput',{},20)
  assert(service.profiles:get(player.UserId,'sparta').selectedFormation=='spartan-shieldwall')
 end)
 test('incomplete camp rejects marching and actual HUD assembles all five on the road',function()
  local claim=service.registry:get(player.UserId);local frame=service.world.model.Plots['Plot'..claim.plotId].Foundation.CFrame
  local medic=army().slots.medic.rig;local original=medic:GetPivot()
  medic:PivotTo(frame*CFrame.new(-100,4,-12));task.wait(.35)
  local invalid=service.command(player,'march');assert(not invalid.ok and invalid.reason=='formation_outside_camp')
  medic:PivotTo(original);order('regroup')
  waitFor(function()for _,slot in army().slots do if not Camp.contains(frame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position),1)then return false end end;return true end,'all five fresh muster',20)
  round('developmentInput',{kind='command',button='MarchFormation'},20)
  assert(army().order=='formation')
  waitFor(function()return player:GetAttribute('FormationPhase')=='marching' end,'actual road assembly',90)
  local positions={};for id,slot in army().slots do positions[id]=frame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position)end
  assert(positions.warrior.Z<positions.camp.Z and positions.warrior.Z<positions.reinforcement.Z)
  assert(positions.ranged.Z>positions.warrior.Z+6 and positions.medic.Z>positions.warrior.Z+6)
  evidence.road={positions={}};for id,p in positions do evidence.road.positions[id]={p.X,p.Y,p.Z}end
 end)
 test('all five formation members physically march with cohesion to the battlefield',function()
  local starts={};local lives={};local last={};local began=os.clock()
  for id,slot in army().slots do starts[id]=slot.rig.HumanoidRootPart.Position;last[id]=starts[id];lives[id]=slot.rig end
  local furthest=0;local slowest=0;local spread=0;local previous=os.clock()
  repeat
   task.wait(.05);local now=os.clock();local dt=now-previous;previous=now
   slowest=math.huge
   for id,slot in army().slots do
    local r=slot.rig;assert(r==lives[id] and not r.HumanoidRootPart.Anchored)
    local p=r.HumanoidRootPart.Position
    assert((p-last[id]).Magnitude<math.max(4,dt*30),'Formation teleported')
    furthest=math.max(furthest,(p-starts[id]).Magnitude);slowest=math.min(slowest,(p-starts[id]).Magnitude);last[id]=p
    for _,other in army().slots do spread=math.max(spread,(p-other.rig.HumanoidRootPart.Position).Magnitude)end
   end
  until player:GetAttribute('FormationPhase')=='deployed' or os.clock()-began>110
  assert(player:GetAttribute('FormationPhase')=='deployed' and slowest>24,'All five did not reach deployment')
  assert(spread<23,'Formation lost cohesion: '..spread)
  local Rules=require(game.ServerScriptService.Game.CombatRules)
  for id,slot in army().slots do assert(slot.rig==lives[id] and Rules.containsArena(service.world.model.Battlefield,slot.rig.HumanoidRootPart.Position))end
  evidence.march={seconds=os.clock()-began,distance=furthest,slowest=slowest,maxSpread=spread}
 end)
 test('formed medic physically avoids an enemy while continuing bandage healing',function()
  local medic=army().slots.medic.rig;local target=army().slots.warrior.rig
  local start=medic.HumanoidRootPart.Position;target.Humanoid.Health=target.Humanoid.MaxHealth-30
  local healed=target:GetAttribute('LastHealAt') or 0
  local folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model
  local civ;for _,c in require(game.ReplicatedStorage.Shared.Civilizations)do if c.id=='britain'then civ=c end end
  local enemy=require(game.ServerScriptService.Game.WarriorRig).create(civ,CFrame.new(start+Vector3.new(7,0,0)),0,0,nil,'warrior')
  enemy.HumanoidRootPart.Anchored=true;enemy.Humanoid.MaxHealth=1000;enemy.Humanoid.Health=1000;enemy.Parent=folder
  assert(service.combat:registerNeutral(enemy,'warrior'))
  waitFor(function()return (medic.HumanoidRootPart.Position-start).Magnitude>3 and (target:GetAttribute('LastHealAt') or 0)>healed end,'formed medic avoidance and healing',8)
  assert(medic:GetAttribute('FormationAvoiding')==true and medic.Humanoid.Health>0)
  evidence.avoidance={distance=(medic.HumanoidRootPart.Position-start).Magnitude,patientHealth=target.Humanoid.Health}
  enemy:Destroy();folder:Destroy()
  waitFor(function()return (medic.HumanoidRootPart.Position-start).Magnitude<4.5 end,'medic returns to formation slot',12)
 end)
 test('formed Hold attacks and heals without moving and Advance abandons held formation',function()
  round('developmentInput',{kind='command',button='Hold'},20)
  assert(player:GetAttribute('FormationPhase')=='holding')
  local saved={};for id,slot in army().slots do saved[id]=slot.rig.HumanoidRootPart.Position end
  local target=army().slots.warrior.rig;target.Humanoid.Health=target.Humanoid.MaxHealth-35
  local before=target.Humanoid.Health
  local folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model
  local civ;for _,c in require(game.ReplicatedStorage.Shared.Civilizations)do if c.id=='britain'then civ=c end end
  local p=target.HumanoidRootPart.Position+Vector3.new(0,0,-4)
  local enemy=require(game.ServerScriptService.Game.WarriorRig).create(civ,CFrame.new(p),0,0,nil,'warrior')
  enemy.HumanoidRootPart.Anchored=true;enemy.Humanoid.MaxHealth=1000;enemy.Humanoid.Health=1000;enemy.Parent=folder
  assert(service.combat:registerNeutral(enemy,'warrior'))
  waitFor(function()return enemy.Humanoid.Health<1000 and target.Humanoid.Health>before end,'formed stationary attack and bandage',8)
  for id,slot in army().slots do assert((slot.rig.HumanoidRootPart.Position-saved[id]).Magnitude<1.5,'Hold moved a formed troop')end
  evidence.hold={enemyHealth=enemy.Humanoid.Health,patientHealth=target.Humanoid.Health}
  enemy:Destroy();folder:Destroy()
  local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  round('developmentInput',{kind='command',button='Advance'},20)
  assert(player:GetAttribute('FormationPhase')==nil and army().order=='advance')
  assert(service.economy:get(player.UserId).selectedFormation=='spartan-shieldwall')
  for id,slot in army().slots do assert(slot.rig==lives[id] and slot.rig:GetAttribute('FormationActive')~=true)end
 end)
 local function freshMuster()
  -- Trusted fixture placement between observations; deployment itself is walked.
  order('regroup');local claim=service.registry:get(player.UserId)
  local frame=service.world.model.Plots['Plot'..claim.plotId].Foundation.CFrame
  for id,slot in army().slots do assert(slot.rig);slot.rig:PivotTo(frame*CFrame.new(Camp.point(Camp.arrivalIndex(id))))end
  task.wait(.5)
 end
 local function march()
  task.wait(.35);local r=service.command(player,'march');assert(r.ok,tostring(r.reason))
 end
 test('Advance during assembly and Regroup immediately discard formation control',function()
  freshMuster();march();assert(player:GetAttribute('FormationPhase')=='assembling')
  order('advance');assert(player:GetAttribute('FormationPhase')==nil and army().order=='advance')
  for _,slot in army().slots do assert(slot.rig:GetAttribute('FormationActive')~=true)end
  freshMuster();march();order('regroup')
  assert(player:GetAttribute('FormationPhase')==nil and army().order=='regroup')
  for _,slot in army().slots do assert(slot.rig:GetAttribute('FormationActive')~=true and slot.rig:GetAttribute('WeaponSkillActive')==nil)end
 end)
 test('member death holds survivors and its replacement never joins the old formation',function()
  freshMuster();march();local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  lives.medic.Humanoid.Health=0
  waitFor(function()return army().order=='hold' and player:GetAttribute('FormationPhase')==nil end,'casualty cancellation',3)
  local deadline=army().slots.medic.respawnAt;assert(deadline>workspace:GetServerTimeNow())
  waitFor(function()return army().slots.medic.rig~=nil end,'independent medic replacement',17)
  assert(army().slots.medic.rig~=lives.medic and army().slots.medic.rig:GetAttribute('FormationActive')~=true)
  for id,r in lives do if id~='medic'then assert(army().slots[id].rig==r and r:GetAttribute('FormationActive')~=true)end end
  task.wait(.35);assert(not service.command(player,'march').ok,'Replacement outside camp rejoined stale formation')
  evidence.casualty={deadline=deadline,replacementJoined=false}
 end)
 test('lost write authority and civilization switching clear live formation state',function()
  freshMuster();march()
  local canMutate=service.economy.canMutate
  service.economy.canMutate=function()return false end
  waitFor(function()return army().order=='hold' and player:GetAttribute('FormationPhase')==nil end,'lost-authority cancellation',3)
  task.wait(.35);assert(not service.command(player,'march').ok)
  service.economy.canMutate=canMutate
  freshMuster();march();order('hold');assert(player:GetAttribute('FormationPhase')=='holding')
  choose('britain')
  assert(player:GetAttribute('FormationPhase')==nil and player:GetAttribute('ArmyOrder')=='advance')
  assert(service.profiles:get(player.UserId,'sparta').selectedFormation=='spartan-shieldwall')
  choose('sparta');assert(service.economy:get(player.UserId).selectedFormation=='spartan-shieldwall')
 end)
 return {ok=true,cases=cases,evidence=evidence}
end

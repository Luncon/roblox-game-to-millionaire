-- Actual production army and native input; this place never opens player storage.
return function(context,player,round,onlyRoman)
 assert(context.store.isFakeProfileStore and game.RunService:IsStudio())
 local service=context.service
 local Data=require(game.ServerScriptService.Game.ProfileData)
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local cases,evidence=0,{}
 local function test(name,fn)
  if onlyRoman and name:sub(1,5)~='Roman' then return end
  game:SetAttribute('FormationVerificationPhase',name);game.ReplicatedStorage:SetAttribute('FormationVerificationPhase',name)
  fn();cases+=1
  local encoded=game.HttpService:JSONEncode(evidence)
  game:SetAttribute('FormationEvidence',encoded);game.ReplicatedStorage:SetAttribute('FormationEvidence',encoded);print('PASS: '..name)
 end
 local function waitFor(fn,label,seconds)
  local deadline=os.clock()+(seconds or 15)
  repeat if fn()then return end;task.wait(.03)until os.clock()>deadline
  error('Timed out: '..label)
 end
 local function choose(id)round('civilizationInput',{action='choose',civilization=id},30)end
 local function order(value)task.wait(.35);assert(service.command(player,'order',value).ok)end
 local function army()return assert(service.army:get(player.UserId))end
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
 local function battlefieldFormation()
  freshMuster();march()
  -- Trusted placement isolates formed battlefield combat; the earlier case walks the whole route.
  local g=army().formation;local ground=service.world.model.Ground
  local Topography=require(game.ServerScriptService.Game.Topography)
  local function grounded(p)
   local v=ground.CFrame:PointToObjectSpace(p)
   return ground.CFrame:PointToWorldSpace(Vector3.new(v.X,.95+Topography.sampleHeight(v.X,v.Z)+3,v.Z))
  end
  g.anchor=grounded(g.destination-g.heading*35);g.destination=g.anchor+g.heading*180;g.phase='marching'
  for id,p in require(game.ServerScriptService.Game.ArmyFormation).goals(g,grounded)do
   army().slots[id].rig:PivotTo(CFrame.lookAt(p,p+g.heading))
  end
  task.wait(.4);assert(player:GetAttribute('FormationPhase')=='marching')
  return g
 end
 local function enemyAt(point)
  local folder=Instance.new('Folder');folder.Name='NeutralOpponents';folder.Parent=service.world.model
  local civ;for _,c in require(game.ReplicatedStorage.Shared.Civilizations)do if c.id=='britain'then civ=c end end
  local enemy=require(game.ServerScriptService.Game.WarriorRig).create(civ,CFrame.new(point),0,0,nil,'warrior')
  enemy.HumanoidRootPart.Anchored=true;enemy.Humanoid.MaxHealth=1000;enemy.Humanoid.Health=1000;enemy.Parent=folder
  assert(service.combat:registerNeutral(enemy,'warrior'))
  return enemy,folder
 end
 local s=Data.defaultState()
 s.coins,s.level,s.weaponLevel,s.armorLevel,s.barracksLevel=3000,20,5,15,6
 s.trainingLevel,s.armyCampLevel,s.hospitalLevel,s.armorerLevel=1,1,1,1
 local spartan=s
 if onlyRoman then
  -- Focused reruns preserve the separately verified Spartan selection/isolation baseline.
  spartan=table.clone(s);spartan.armyCampLevel=2;spartan.shieldLevel=1;spartan.warCouncilLevel=1
  spartan.formationLevel=1;spartan.selectedFormation='spartan-shieldwall'
 end
 choose('britain');assert(service.profiles:set(player.UserId,'sparta',spartan));choose('sparta');order('hold')
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
 test('all five march with cohesion and automatically Advance at the center destination',function()
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
  until army().order=='advance' or os.clock()-began>110
  assert(army().order=='advance' and player:GetAttribute('FormationPhase')==nil and slowest>24,'Arrival did not release all five to Advance')
  for _,slot in army().slots do assert(slot.rig:GetAttribute('FormationActive')~=true)end
  assert(spread<23,'Formation lost cohesion: '..spread)
  local Rules=require(game.ServerScriptService.Game.CombatRules)
  for id,slot in army().slots do assert(slot.rig==lives[id] and Rules.containsArena(service.world.model.Battlefield,slot.rig.HumanoidRootPart.Position))end
  evidence.march={seconds=os.clock()-began,distance=furthest,slowest=slowest,maxSpread=spread}
 end)
 test('formed medic physically avoids an enemy while continuing bandage healing',function()
  battlefieldFormation()
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
 test('Advance during assembly and Regroup immediately discard formation control',function()
  freshMuster();march();assert(player:GetAttribute('FormationPhase')=='assembling')
  order('advance');assert(player:GetAttribute('FormationPhase')==nil and army().order=='advance')
  for _,slot in army().slots do assert(slot.rig:GetAttribute('FormationActive')~=true)end
  freshMuster();march();order('regroup')
  assert(player:GetAttribute('FormationPhase')==nil and army().order=='regroup')
  for _,slot in army().slots do assert(slot.rig:GetAttribute('FormationActive')~=true and slot.rig:GetAttribute('WeaponSkillActive')==nil)end
 end)
 test('support casualties retain the march and replacement supports never rejoin captured slots',function()
  local g=battlefieldFormation();local front=army().slots.warrior.rig
  army().slots.medic.rig.Humanoid.Health=0;army().slots.ranged.rig.Humanoid.Health=0
  waitFor(function()return not army().slots.medic.rig and not army().slots.ranged.rig end,'support deaths',3)
  task.wait(.5);assert(army().formation==g and army().order=='formation' and g.phase=='marching')
  assert(not g.members.medic and not g.members.ranged and front:GetAttribute('FormationActive'))
  waitFor(function()return army().slots.medic.rig and army().slots.ranged.rig end,'independent support replacements',17)
  assert(army().formation==g and not g.members.medic and not g.members.ranged)
  for _,id in {'medic','ranged'}do assert(army().slots[id].rig:GetAttribute('FormationActive')~=true)end
  evidence.supportLoss={phase=g.phase,replacementsJoined=false}
 end)
 test('formed spear skill strikes without dashing and ranged troops keep ordinary throws',function()
  local g=battlefieldFormation();local original=service.economy:get(player.UserId)
  local trained=table.clone(original);trained.weaponLevel=20;trained.skillLevel=1
  assert(service.economy:replace(player.UserId,trained))
  local front=army().slots.warrior.rig;local start=front.HumanoidRootPart.Position
  local ranged=army().slots.ranged.rig
  local previousShot=(service.encounters:get(ranged) or {}).lastAttackAt or 0
  local right=Vector3.new(-g.heading.Z,0,g.heading.X)
  -- Put the foe in the gap visible to both the center spear and ranged support.
  local enemy,folder=enemyAt(start+g.heading*3-right*2.8)
  local began=front:GetAttribute('WeaponSkillStartedAt') or 0
  local shoulder=assert(front.Torso:FindFirstChild('Right Shoulder'));local shoulderStart=shoulder.C0
  local worst,seen,posed=0,false,false;local deadline=os.clock()+4
  repeat
   task.wait(.01);worst=math.max(worst,(front.HumanoidRootPart.Position-start).Magnitude)
   if (front:GetAttribute('WeaponSkillStartedAt') or 0)>began then
    seen=true
    posed=posed or (front:GetAttribute('WeaponSkillActive')=='spear' and shoulder.C0~=shoulderStart)
   end
   assert(ranged:GetAttribute('WeaponSkillActive')==nil,'Formed ranged troop activated a skill')
  until (seen and front:GetAttribute('WeaponSkillActive')==nil) or os.clock()>deadline
  assert(seen and posed and enemy.Humanoid.Health<1000 and worst<1.5,'Stationary formation thrust failed')
  assert(army().formation==g and g.phase=='marching' and front:GetAttribute('ShieldCharges')==2)
  assert((front:GetAttribute('WeaponSkillReadyAt') or 0)>workspace:GetServerTimeNow()+3)
  waitFor(function()local plan=service.encounters:get(ranged);return plan and (plan.lastAttackAt or 0)>previousShot end,'ordinary ranged throw',12)
  assert(service.combat:hit(enemy,front).blocked==true);task.wait(1.05)
  assert(service.combat:hit(enemy,front).blocked==true)
  assert(front:GetAttribute('ShieldCharges')==0 and army().formation==g,'Shield break dissolved the line')
  evidence.thrust={rootDisplacement=worst,enemyHealth=enemy.Humanoid.Health,formationRetained=true}
  enemy:Destroy();folder:Destroy();assert(service.economy:replace(player.UserId,original))
 end)
 test('frontline casualty resumes pursuit and healing while replacements stay outside the old formation',function()
  local g=battlefieldFormation();local lives={};for id,slot in army().slots do lives[id]=slot.rig end
  local target=lives.warrior;local start=target.HumanoidRootPart.Position
  target.Humanoid.Health=target.Humanoid.MaxHealth-35;local before=target.Humanoid.Health
  local enemy,folder=enemyAt(start+g.heading*20)
  lives.camp.Humanoid.Health=0
  waitFor(function()return army().order=='advance' and player:GetAttribute('FormationPhase')==nil end,'frontline casualty release',3)
  local deadline=army().slots.camp.respawnAt;assert(deadline>workspace:GetServerTimeNow())
  waitFor(function()return (target.HumanoidRootPart.Position-start).Magnitude>3 and enemy.Humanoid.Health<1000 and target.Humanoid.Health>before end,'ordinary pursuit attacks and medic healing',10)
  waitFor(function()return army().slots.camp.rig~=nil end,'independent frontline replacement',17)
  assert(army().slots.camp.rig~=lives.camp and army().slots.camp.rig:GetAttribute('FormationActive')~=true)
  for id,r in lives do if id~='camp'then assert(army().slots[id].rig==r and r:GetAttribute('FormationActive')~=true)end end
  task.wait(.35);assert(not service.command(player,'march').ok,'Replacement outside camp rejoined stale formation')
  assert(service.economy:get(player.UserId).selectedFormation=='spartan-shieldwall')
  evidence.casualty={deadline=deadline,replacementJoined=false,pursuit=(target.HumanoidRootPart.Position-start).Magnitude,patientHealth=target.Humanoid.Health}
  enemy:Destroy();folder:Destroy()
 end)
 test('explicit Hold survives a frontline casualty',function()
  battlefieldFormation();order('hold');local start=army().slots.warrior.rig.HumanoidRootPart.Position
  army().slots.reinforcement.rig.Humanoid.Health=0
  waitFor(function()return army().formation==nil end,'held frontline casualty',3)
  task.wait(.6);assert(army().order=='hold' and (army().slots.warrior.rig.HumanoidRootPart.Position-start).Magnitude<1.5)
  waitFor(function()return army().slots.reinforcement.rig~=nil end,'held replacement',17)
 end)
 test('extended melee and ranged sight acquire enemies before walking inside the old detection range',function()
  local locks={}
  for _,entry in {{'warrior',50},{'ranged',85}}do
   local g=battlefieldFormation();order('hold')
   local id,distance=entry[1],entry[2];local rig=army().slots[id].rig
   local start=rig.HumanoidRootPart.Position
   local enemy,folder=enemyAt(start+g.heading*distance)
   order('advance')
   waitFor(function()local plan=service.encounters:get(rig);return plan and plan.target==enemy end,'extended '..id..' acquisition',3)
   local moved=(rig.HumanoidRootPart.Position-start).Magnitude
   assert(moved<4,'Troop walked into its old detection range before acquiring')
   assert(enemy.Humanoid.Health==1000,'Sight increase extended attack damage reach')
   waitFor(function()return (rig.HumanoidRootPart.Position-start).Magnitude>3 end,'extended '..id..' pursuit',4)
   locks[id]={distance=distance,movementBeforeLock=moved}
   enemy:Destroy();folder:Destroy()
  end
  evidence.sight=locks
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
 test('Roman physical testing coins and faction unlocks remain owner proximity and write guarded',function()
  local roman=table.clone(s);roman.coins=0;roman.weaponLevel=20;roman.skillLevel=1
  assert(service.profiles:set(player.UserId,'rome',roman));choose('rome');order('hold')
  local claim=service.registry:get(player.UserId);local plot=service.world.model.Plots['Plot'..claim.plotId]
  local pad=assert(plot.Controls:FindFirstChild('TestCoinButton'))
  assert(not pad.CanTouch and pad:FindFirstChildOfClass('SurfaceGui').TextLabel.Text:find('1,000',1,true))
  local foreign=claim.plotId%service.world.plotCount+1
  assert(not service.buttons:activate(player,foreign,'testCoins').ok)
  player.Character:PivotTo(pad.CFrame*CFrame.new(-40,4,0))
  assert(not service.buttons:activate(player,claim.plotId,'testCoins').ok)
  local canMutate=service.economy.canMutate;service.economy.canMutate=function()return false end
  -- The left approach is inside the Army Camp; start on the clear hall side.
  player.Character:PivotTo(pad.CFrame*CFrame.new(10,3,0))
  assert(not service.buttons:activate(player,claim.plotId,'testCoins').ok and service.economy:get(player.UserId).coins==0)
  service.economy.canMutate=canMutate
  round('developmentInput',{kind='pad',action='testCoins'},30)
  assert(service.economy:get(player.UserId).coins==1000)
  for _,item in {{'shield','ShieldButton'},{'armyCamp','ArmyCampButton'},{'warCouncil','WarCouncilButton'},{'formation','FormationButton'}}do
   local purchase=assert(plot.Controls:FindFirstChild(item[2]))
   player.Character:PivotTo(purchase.CFrame*CFrame.new(-10,3,0))
   round('developmentInput',{kind='pad',action=item[1]},30)
  end
  assert(service.economy:get(player.UserId).coins==150 and player.Character:GetAttribute('ShieldCharges')==2)
  assert(not service.command(player,'formation','spartan-shieldwall').ok)
  player.Character:PivotTo(plot.Foundation.CFrame*CFrame.new(-148,3,35));task.wait(.5)
  round('formationInput',{},20)
  assert(service.profiles:get(player.UserId,'rome').selectedFormation=='roman-shield-guard')
  assert(service.profiles:get(player.UserId,'sparta').selectedFormation=='spartan-shieldwall')
  evidence.romanPurchases={testingGrant=1000,coins=150,selected='roman-shield-guard'}
 end)
 test('Roman five-body road assembly and compact guard march retain six-stud pace and release at center',function()
  freshMuster();march()
  waitFor(function()return player:GetAttribute('FormationPhase')=='marching' end,'Roman road assembly',90)
  local g=army().formation;local began=os.clock();local anchor=g.anchor;local starts={};local maxSpread=0
  for id,slot in army().slots do starts[id]=slot.rig.HumanoidRootPart.Position end
  repeat
   task.wait(.05)
   for _,slot in army().slots do
    assert(slot.rig and not slot.rig.HumanoidRootPart.Anchored)
    for _,other in army().slots do maxSpread=math.max(maxSpread,(slot.rig.HumanoidRootPart.Position-other.rig.HumanoidRootPart.Position).Magnitude)end
   end
  until army().order=='advance' or os.clock()-began>115
  assert(army().order=='advance' and not army().formation and maxSpread<23,'Roman march failed')
  local seconds=os.clock()-began;local distance=(g.anchor-anchor).Magnitude
  assert(distance/seconds<=6.5 and distance/seconds>4,'Roman marching pace diverged: '..distance/seconds)
  for id,slot in army().slots do assert((slot.rig.HumanoidRootPart.Position-starts[id]).Magnitude>24)end
  evidence.romanMarch={seconds=seconds,distance=distance,maxSpread=maxSpread}
 end)
 test('Roman flank shields face outward and stationary Double Slash leaves formation intact',function()
  local g=battlefieldFormation();local front=army().slots.warrior.rig;local ranged=army().slots.ranged.rig
  local right=Vector3.new(-g.heading.Z,0,g.heading.X)
  for _,entry in {{'camp',-1},{'reinforcement',1}}do
   local r=army().slots[entry[1]].rig
   assert(r.HumanoidRootPart.CFrame.LookVector:Dot(right)*entry[2]>.5,'Roman flank shield did not face outward')
   local shields=0;for _,item in r:GetDescendants()do if item:GetAttribute('CombatShield')==true then shields+=1 end end
   assert(r:GetAttribute('ShieldCharges')==2 and shields==1,'Roman melee shield visual missing')
  end
  local start=front.HumanoidRootPart.Position;local enemy,folder=enemyAt(start+g.heading*3-right*2.8)
  local began=front:GetAttribute('WeaponSkillStartedAt') or 0;local seen=false;local moved=0;local deadline=os.clock()+5
  repeat
   task.wait(.01);moved=math.max(moved,(front.HumanoidRootPart.Position-start).Magnitude)
   seen=seen or (front:GetAttribute('WeaponSkillStartedAt') or 0)>began
   assert(ranged:GetAttribute('WeaponSkillActive')==nil,'Roman ranged used a skill')
  until (seen and front:GetAttribute('WeaponSkillActive')==nil) or os.clock()>deadline
  assert(seen and enemy.Humanoid.Health<1000 and moved<1.5 and army().formation==g,'Roman stationary slash failed')
  assert((front:GetAttribute('WeaponSkillReadyAt') or 0)>workspace:GetServerTimeNow()+4)
  enemy:Destroy();folder:Destroy()
  army().slots.camp.rig.Humanoid.Health=0
  waitFor(function()return army().order=='advance' and not army().formation end,'Roman frontline casualty',3)
  evidence.romanCombat={stationaryDisplacement=moved,frontlineReleased=true}
 end)
 return {ok=true,cases=cases,evidence=evidence}
end

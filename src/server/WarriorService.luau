--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.WarriorConfig)
local Ranged = require(Shared.RangedConfig)
local Tracks = require(Shared.UpgradeTracks)
local CombatRules = require(script.Parent.CombatRules)
local CombatService = require(script.Parent.CombatService)
local WarriorRig = require(script.Parent.WarriorRig)
local WarriorNavigator = require(script.Parent.WarriorNavigator)
local ArmyRest = require(script.Parent.ArmyRest)
local TrainingCamp = require(Shared.TrainingCampConfig)
local TroopProjectile = require(script.Parent.TroopProjectile)
local Encounter = require(script.Parent.CombatEncounter)
local Motion = require(script.Parent.EncounterMotion)
local MedicalConfig=require(Shared.MedicalConfig)
local MedicalService=require(script.Parent.MedicalService)
local MedicPlanner=require(script.Parent.MedicPlanner)
local MedicalRetreat=require(script.Parent.MedicalRetreat)
local MedicalRoute=require(script.Parent.MedicalRoute)
local Topography=require(script.Parent.Topography)
local ShieldRack=require(script.Parent.ShieldRack)
local Formation=require(script.Parent.ArmyFormation)
local FormationConfig=require(Shared.FormationConfig)
local WarriorService = {}
local COLLISION_GROUP = "CivilizationWarriors"
local ORDERS = {advance=true,hold=true,regroup=true}

-- Slot identity survives a class choice; camp.kind is resolved at its next spawn.
function WarriorService.slotDefinitions(state)
	local slots = {{id="warrior",kind="warrior"}}
	if Tracks.barracks[state.barracksLevel or 1].capacity >= 2 then
		table.insert(slots,{id="ranged",kind="ranged"})
	end
	if (state.armyCampLevel or 0) >= 1 then
		table.insert(slots,{id="camp",kind=if state.extraTroopClass=="ranged" then "ranged" else "warrior"})
	end
	if state.armyCampLevel==2 then table.insert(slots,{id="reinforcement",kind="warrior"}) end
	if state.hospitalLevel==1 then table.insert(slots,{id="medic",kind="medic"}) end
	return slots
end

function WarriorService.start(world, registry, economy, catalog, sharedCombat, sharedEncounter)
	local controller = {}
	local owners, rigSlots, playerRigs = {}, {}, {}
	local alive = true
	local arena = world.model:FindFirstChild("Battlefield") :: BasePart
	local troops = world.model:FindFirstChild("Troops")
	assert(troops and troops:IsA("Folder"), "Map must provide a Troops folder")
	local combat = sharedCombat or CombatService.new(world, registry, economy)
	local encounters=sharedEncounter or Encounter.new(world,combat)
	local medicine=MedicalService.new(world,combat,economy,function(rig)
  local slot=rigSlots[rig]
  local owner=if slot then owners[rig:GetAttribute("OwnerId")] else nil
  return alive and slot~=nil and slot.rig==rig and slot.kind=="medic" and owner~=nil and owner.order~="regroup"
 end)
 local projectiles = TroopProjectile.new(world, combat, function(rig)
		return alive and rigSlots[rig] ~= nil
	end)
	if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then PhysicsService:RegisterCollisionGroup(COLLISION_GROUP) end
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

	local function eligible(player: Player)
		local claim, state = registry:get(player.UserId), economy:get(player.UserId)
		if not alive or not world.model:IsDescendantOf(workspace) or troops.Parent ~= world.model
			or player.Parent ~= Players or not claim or not state or not economy:canMutate(player.UserId) or state.level < Config.unlockLevel then return nil end
		return claim, state
	end
	local function tier(state)
		return Tracks.barracks[state.barracksLevel or 1]
	end
	local function publish(owner)
		local state = economy:get(owner.player.UserId)
		if not state then return end
		local warrior, ranged, camp = owner.slots.warrior, owner.slots.ranged, owner.slots.camp
		local meleeCount, rangedCount, medicCount = 0, 0, 0
		for _, slot in owner.slots do
			if slot.rig then
				if slot.kind=="medic" then medicCount+=1 elseif slot.kind=="ranged" then rangedCount+=1 else meleeCount+=1 end
			end
		end
		owner.player:SetAttribute("BarracksLevel", state.barracksLevel or 1)
		owner.player:SetAttribute("WarriorCount", meleeCount)
		owner.player:SetAttribute("RangedCount", rangedCount)
		owner.player:SetAttribute("ArmyCount", meleeCount + rangedCount + medicCount)
		owner.player:SetAttribute("MedicCount",medicCount)
  owner.player:SetAttribute("MedicRespawnAt",if owner.slots.medic then owner.slots.medic.respawnAt else 0)
  owner.player:SetAttribute("HospitalLevel",state.hospitalLevel or 0)
  owner.player:SetAttribute("TroopCapacity", #WarriorService.slotDefinitions(state))
		owner.player:SetAttribute("ArmyRespawnDelay", tier(state).respawnDelay)
		owner.player:SetAttribute("WarriorRespawnAt", if warrior then warrior.respawnAt else 0)
		owner.player:SetAttribute("RangedRespawnAt", if ranged then ranged.respawnAt else 0)
		owner.player:SetAttribute("CampCount", if camp and camp.rig then 1 else 0)
		owner.player:SetAttribute("CampRespawnAt", if camp then camp.respawnAt else 0)
		local reinforcement=owner.slots.reinforcement
		owner.player:SetAttribute("ReinforcementCount",if reinforcement and reinforcement.rig then 1 else 0)
		owner.player:SetAttribute("ReinforcementRespawnAt",if reinforcement then reinforcement.respawnAt else 0)
		owner.player:SetAttribute("CampClass", if camp then camp.kind else nil)
		owner.player:SetAttribute("ExtraTroopClass", state.extraTroopClass or "warrior")
		owner.player:SetAttribute("ArmyOrder", owner.order)
	end
	local function clearAttributes(player: Player)
		for _, name in {"BarracksLevel", "WarriorCount", "RangedCount", "ArmyCount", "TroopCapacity", "ArmyRespawnDelay", "WarriorRespawnAt", "RangedRespawnAt", "CampCount", "CampRespawnAt", "MedicCount", "MedicRespawnAt", "ReinforcementCount", "ReinforcementRespawnAt"} do
			player:SetAttribute(name, 0)
		end
		player:SetAttribute("CampClass",nil)
		player:SetAttribute("ExtraTroopClass","warrior")
		player:SetAttribute("ArmyOrder","advance")
		player:SetAttribute("FormationPhase",nil)
	end
	local function disconnect(slot)
		if slot.deathConnection then slot.deathConnection:Disconnect(); slot.deathConnection = nil end
		if slot.destroyConnection then slot.destroyConnection:Disconnect(); slot.destroyConnection = nil end
		if slot.navigator then slot.navigator:destroy(); slot.navigator = nil end
		slot.target = nil
		slot.resupplyGoal=nil
		slot.rest,slot.restGoal,slot.restFrame,slot.restDirect=nil,nil,nil,nil
		slot.medicalRecovery=nil
		if slot.rig then
			medicine:forget(slot.rig)
			projectiles:cancel(slot.rig)
			encounters:forget(slot.rig)
			combat:unregister(slot.rig)
			rigSlots[slot.rig] = nil
		end
	end
	local function disposeSlot(slot)
		disconnect(slot)
		if slot.rig then slot.rig:Destroy(); slot.rig = nil end
		for corpse in slot.corpses do corpse:Destroy() end
		table.clear(slot.corpses)
	end
	local function current(owner, slot): boolean
		return alive and owners[owner.player.UserId] == owner and owner.slots[slot.id] == slot
	end
	local function formationActors(owner)
		local result={}
		for id,slot in owner.slots do if slot.rig then
			local actor=combat:actor(slot.rig)
			if actor then
				actor.phase=slot.rig:GetAttribute("CombatPhase") or "idle"
				actor.avoiding=slot.rig:GetAttribute("FormationAvoiding")==true
				result[id]=actor
			end
		end end
		return result
	end
	local function clearFormation(owner,hold)
		if not owner.formation then return end
		owner.formation=nil
		owner.player:SetAttribute("FormationPhase",nil)
		for _,slot in owner.slots do
			if slot.rig then
				slot.rig:SetAttribute("FormationActive",false);slot.rig:SetAttribute("FormationAvoiding",nil)
				if hold then
					local root=slot.rig:FindFirstChild("HumanoidRootPart")
					slot.holdPosition=if root then root.Position else nil
					encounters:cancel(slot.rig);projectiles:cancel(slot.rig)
					if slot.rig:FindFirstChildOfClass("Humanoid") then Motion.clear(slot.rig)end
					if slot.navigator then slot.navigator:stop()end
				end
			end
		end
		if hold then owner.order="hold" end
	end
	local function releaseFormation(owner)
		local order=if owner.order=="hold" then "hold" else "advance"
		clearFormation(owner,true)
		owner.order=order
		if order=="advance" then
			for _,slot in owner.slots do
				slot.holdPosition,slot.target,slot.medicalRecovery=nil,nil,nil
				if slot.rig then
					local humanoid=slot.rig:FindFirstChildOfClass("Humanoid")
					if humanoid then humanoid.WalkSpeed=Config.walkSpeed end
					slot.rig:SetAttribute("WarriorState","Marching")
				end
			end
		end
	end
	function controller:cancelFormation(player)
		local owner=owners[player.UserId]
		if owner then clearFormation(owner,true);publish(owner)end
	end
	function controller:march(player)
		local claim,state=eligible(player)
		if not claim then return {ok=false,reason="profile_unavailable"}end
		local owner=owners[player.UserId]
		if not owner or owner.civilizationId~=claim.civilizationId or owner.plotId~=claim.plotId then return {ok=false,reason="not_ready"}end
		local frame=world.model.Plots["Plot"..claim.plotId].Foundation.CFrame
		local actors=formationActors(owner)
		local ready,reason=Formation.ready(state,claim.civilizationId,frame,actors)
		if not ready then return {ok=false,reason=reason}end
		-- Reuse the complete living-owner/authority/order guard before capturing lives.
		local accepted=self:command(player,"hold")
		if not accepted.ok then return accepted end
		local anchor=frame:PointToWorldSpace(Vector3.new(0,3,-world.model.Plots["Plot"..claim.plotId].Foundation.Size.Z/2-24))
		local forward=arena.Position-frame.Position;forward=Vector3.new(forward.X,0,forward.Z).Unit
		local destination=arena.Position-forward*16
		owner.formation=Formation.new(anchor,destination,actors,FormationConfig.forCivilization(claim.civilizationId))
		owner.formation.lastAt=os.clock();owner.order="formation"
		owner.player:SetAttribute("FormationPhase","assembling")
		for _,slot in owner.slots do if slot.rig then slot.rig:SetAttribute("FormationActive",true)end end
		publish(owner);return {ok=true,order="formation"}
	end

	local spawnSlot
	local function fallen(owner, slot, rig: Model)
		if not current(owner, slot) or slot.rig ~= rig then return end
		local group=owner.formation
		if group and group.members[slot.id] then
			if slot.kind=="warrior" then releaseFormation(owner) else
				group.members[slot.id]=nil
				rig:SetAttribute("FormationActive",false);rig:SetAttribute("FormationAvoiding",nil)
			end
		end
		local state = economy:get(owner.player.UserId)
		local delay = if slot.id=="medic" then MedicalConfig.respawnDelay elseif state then tier(state).respawnDelay else Config.respawnDelay
		disconnect(slot)
		slot.rig = nil
		slot.respawnAt = workspace:GetServerTimeNow() + delay
		slot.corpses[rig] = true
		rig:SetAttribute("WarriorState", "Fallen")
		local flash=rig:FindFirstChild("CombatHitFlash");if flash then flash.Enabled=false end
		publish(owner)
		task.delay(Config.corpseLifetime, function()
			slot.corpses[rig] = nil
			if rig.Parent then rig:Destroy() end
		end)
		local function replaceWhenReady()
			if not current(owner, slot) or slot.rig or not eligible(owner.player) then return end
			local remaining = slot.respawnAt - workspace:GetServerTimeNow()
			if remaining > 0 then task.delay(remaining, replaceWhenReady); return end
			spawnSlot(owner, slot)
		end
		task.delay(delay, replaceWhenReady)
	end
	spawnSlot = function(owner, slot)
		local claim, state = eligible(owner.player)
		if not claim or not current(owner, slot) or slot.rig then return end
		local definition=nil
		for _, candidate in WarriorService.slotDefinitions(state) do if candidate.id==slot.id then definition=candidate;break end end
		if not definition then return end
		slot.kind=definition.kind
		local rig = WarriorRig.create(catalog[claim.civilizationId], world:getBarracksSpawn(claim.plotId, slot.kind, slot.id),
			owner.player.UserId, claim.plotId, state, slot.kind)
		slot.rig, slot.respawnAt, slot.nextAttack, slot.attackUntil = rig, 0, 0, 0
		rig.Parent = troops
		rigSlots[rig] = slot
		local humanoid = rig:FindFirstChildOfClass("Humanoid") :: Humanoid
		local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
		for _, item in rig:GetDescendants() do
			if item:IsA("BasePart") then item.CollisionGroup = COLLISION_GROUP end
		end
		root:SetNetworkOwner(nil)
		humanoid.WalkSpeed = Config.walkSpeed
		combat:register(rig, owner.player.UserId, slot.kind)
		slot.navigator = WarriorNavigator.new(rig, function() return current(owner, slot) and slot.rig == rig end,world)
		slot.holdPosition=if owner.order=="hold" then root.Position else nil
		if owner.order=="hold" then slot.navigator:stop() end
		slot.deathConnection = humanoid.Died:Connect(function() fallen(owner, slot, rig) end)
		slot.destroyConnection = rig.Destroying:Connect(function() fallen(owner, slot, rig) end)
		rig:SetAttribute("ArmySlot",slot.id)
		combat.skills:refresh(rig)
		rig:SetAttribute("WarriorState", if owner.order=="hold" then "Holding" elseif owner.order=="regroup" then "Regrouping" else "Marching")
		publish(owner)
	end
	function controller:refresh(player: Player)
		local claim, state = eligible(player)
		if not claim then
			if owners[player.UserId] then self:release(player.UserId) end
			clearAttributes(player)
			return
		end
		local owner = owners[player.UserId]
		if owner and (owner.player~=player or owner.civilizationId~=claim.civilizationId or owner.plotId~=claim.plotId) then
			self:release(player.UserId)
			owner=nil
		end
		if not owner then
			owner = {player=player,civilizationId=claim.civilizationId,plotId=claim.plotId,slots={},order="advance",lastCommandAt=-math.huge}
			owners[player.UserId] = owner
		end
		world:setBarracksLevel(claim.plotId, state.barracksLevel or 1)
		local available={}
		for _, definition in WarriorService.slotDefinitions(state) do
			available[definition.id]=true
			local slot = owner.slots[definition.id]
			if not slot then
				slot = {id=definition.id,kind=definition.kind,rig=nil,respawnAt=0,corpses={},nextAttack=0,attackUntil=0}
				owner.slots[definition.id] = slot
				spawnSlot(owner, slot)
			elseif slot.rig then
				local humanoid = slot.rig:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					WarriorRig.update(slot.rig, catalog[claim.civilizationId], state)
					combat.skills:refresh(slot.rig)
				else fallen(owner, slot, slot.rig) end
			end
		end
		for id, slot in owner.slots do
			if not available[id] then disposeSlot(slot);owner.slots[id]=nil end
		end
		-- Each slot keeps its original pending deadline through all purchases.
		publish(owner)
	end
	function controller:refreshSkills(player: Player)
		local owner=owners[player.UserId]
		if not owner then return end
		for _,slot in owner.slots do if slot.rig then combat.skills:refresh(slot.rig) end end
	end
	function controller:get(ownerId: number)
		local owner = owners[ownerId]
		if not owner then return nil end
		local slots = {}
		for id, slot in owner.slots do slots[id] = {rig=slot.rig,respawnAt=slot.respawnAt,kind=slot.kind,holdPosition=slot.holdPosition} end
		return {rig=slots.warrior.rig,respawnAt=slots.warrior.respawnAt,slots=slots,order=owner.order}
	end
	function controller:command(player: Player, order: unknown)
		if type(order)~="string" or not ORDERS[order] then return {ok=false,reason="invalid"} end
		if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then
			return {ok=false,reason="invalid"}
		end
		local claim,state=eligible(player)
		if not claim then return {ok=false,reason="not_claimed"} end
		if type(economy.canMutate)~="function" or not economy:canMutate(player.UserId) then
			return {ok=false,reason="profile_unavailable"}
		end
		if state.trainingLevel~=1 then return {ok=false,reason="training_locked"} end
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not character or not character:IsDescendantOf(workspace) or not humanoid or humanoid.Health<=0
			or not root or not root:IsA("BasePart") then return {ok=false,reason="not_alive"} end
		local owner=owners[player.UserId]
		if not owner or owner.player~=player or owner.civilizationId~=claim.civilizationId or owner.plotId~=claim.plotId then
			return {ok=false,reason="not_ready"}
		end
		local now=os.clock()
		if now-owner.lastCommandAt<.3 then return {ok=false,reason="rate_limited"} end
		owner.lastCommandAt=now
		if owner.order~=order or owner.formation then
			if owner.formation and order=="hold" then
				owner.formation.phase="holding";owner.player:SetAttribute("FormationPhase","holding")
			else clearFormation(owner,false)end
			owner.order=order
			for _, slot in owner.slots do
				slot.target=nil
				slot.resupplyGoal=nil
				slot.rest,slot.restGoal,slot.restFrame,slot.restDirect=nil,nil,nil,nil
				slot.medicalRecovery=nil
				if slot.navigator then slot.navigator:stop() end
				local rig=slot.rig
				local troopRoot=rig and rig:FindFirstChild("HumanoidRootPart")
				slot.holdPosition=if order=="hold" and troopRoot then troopRoot.Position else nil
				if rig then
     rig:SetAttribute("MedicalSupportActive",false)
					encounters:cancel(rig)
					Motion.clear(rig)
					rig.Humanoid.WalkSpeed=Config.walkSpeed
					rig:SetAttribute("RestPhase",nil)
					if order=="regroup" then projectiles:cancel(rig);medicine:cancel(rig) end
					rig:SetAttribute("WarriorState",if order=="hold" then "Holding" elseif order=="regroup" then "Regrouping" else "Marching")
				end
			end
		end
		publish(owner)
		return {ok=true,order=owner.order}
	end
	function controller:release(ownerId: number)
		local owner = owners[ownerId]
		if not owner then return end
		owners[ownerId] = nil
		for _, slot in owner.slots do disposeSlot(slot) end
		clearAttributes(owner.player)
	end
	local function syncFallbackPlayers()
		if sharedCombat then return end
		local connected = {}
		for _, player in Players:GetPlayers() do
			local rig = if registry:get(player.UserId) then player.Character else nil
			connected[player.UserId] = true
			local previous = playerRigs[player.UserId]
			if previous ~= rig then
				if previous then combat:unregister(previous) end
				playerRigs[player.UserId] = nil
			end
			if rig and playerRigs[player.UserId] == nil then
				combat:register(rig, player.UserId, "player")
				if combat:actor(rig) then playerRigs[player.UserId] = rig end
			end
		end
		for ownerId, rig in playerRigs do
			if not connected[ownerId] then combat:unregister(rig); playerRigs[ownerId] = nil end
		end
	end
	local function think(now: number)
		syncFallbackPlayers()
		local actors = combat:actors() -- Owned armies, players and neutral test opponents.
		for ownerId, owner in owners do
			local formationGoals=nil
			if owner.formation then
				local group=owner.formation
				if not eligible(owner.player) then clearFormation(owner,true);publish(owner)else
					local ground=world.model.Ground
					local function grounded(p)
						local localPoint=ground.CFrame:PointToObjectSpace(p)
						return ground.CFrame:PointToWorldSpace(Vector3.new(localPoint.X,.95+Topography.sampleHeight(localPoint.X,localPoint.Z)+3,localPoint.Z))
					end
					local snapshot=formationActors(owner)
					local phase=group.phase
					local hasShot=phase=="marching" and Formation.firingOpportunity(group,snapshot.ranged,actors,function(archer,target)
						return combat:canAct(archer.rig) and CombatRules.canDamage(archer,target,arena,Ranged.range) and combat:visible(archer,target)
					end)
					if phase=="holding" then
						-- Validate captured lives even while Hold freezes formation movement.
						formationGoals=Formation.step(group,snapshot,0,function()return false end,grounded)
					else formationGoals=Formation.step(group,snapshot,now-group.lastAt,function(id,p)
						return owner.slots[id].navigator:canWalkFormation(p)
					end,grounded,hasShot)end
					group.lastAt=now
					if not formationGoals then releaseFormation(owner);publish(owner)
					else owner.player:SetAttribute("FormationPhase",group.phase)end
				end
			end
			for _, slot in owner.slots do
				local rig = slot.rig
				if not rig then continue end
				local attacker = combat:actor(rig)
				if not attacker then fallen(owner, slot, rig); continue end
    local frame=world.model.Plots["Plot"..owner.plotId].Foundation.CFrame
    medicine:recover(rig,frame)
    if not combat:canAct(rig) then
     medicine:cancel(rig);slot.navigator:stop()
     slot.resupplyGoal=nil
     slot.medicalRecovery=nil
     rig:SetAttribute("MedicalSupportActive",false)
     continue
    end
				if owner.order=="regroup" then
					local state=economy:get(ownerId)
					if ShieldRack.needs(rig,state)then
						local infrastructure=world.model.Plots["Plot"..owner.plotId]:FindFirstChild("Infrastructure")
						local rack=infrastructure and infrastructure:FindFirstChild("ShieldRack")
						local goal=ShieldRack.goal(rack,slot.id)
						if goal then
							if not ShieldRack.collect(rig,rack,slot.id,owner.order,state,economy:canMutate(ownerId))then
								attacker.humanoid.WalkSpeed=Config.walkSpeed
								if slot.resupplyGoal~=goal then slot.navigator:setGoal(goal);slot.resupplyGoal=goal end
								slot.navigator:step(now);rig:SetAttribute("WarriorState","Collecting shield")
								rig:SetAttribute("RestPhase","resupplying");continue
							end
							slot.rest,slot.restGoal,slot.restFrame,slot.restDirect=nil,nil,nil,nil
							slot.navigator:stop()
						end
					end
					slot.resupplyGoal=nil
					slot.rest=slot.rest or ArmyRest.new(slot.id)
					local frame=world.model.Plots["Plot"..owner.plotId].Foundation.CFrame
					local position=frame:PointToObjectSpace(attacker.position)
					local goal,speed,arrived,entering=ArmyRest.step(slot.rest,position,now)
					local direct=goal~=nil and (entering==true or TrainingCamp.contains(position,2))
					attacker.humanoid.WalkSpeed=speed
					if goal~=slot.restGoal or frame~=slot.restFrame or direct~=slot.restDirect then
						if not goal then slot.navigator:stop()
						elseif not direct then slot.navigator:setGoal(frame:PointToWorldSpace(goal)) end
						slot.restGoal=goal
						slot.restFrame=frame
						slot.restDirect=direct
					end
					if goal then
						if direct then slot.navigator:walkDirect(frame:PointToWorldSpace(goal)) else slot.navigator:step(now) end
					end
					rig:SetAttribute("WarriorState",if arrived then "Regrouped" else "Regrouping")
					rig:SetAttribute("RestPhase",slot.rest.phase)
					continue
				end
				local claim=registry:get(ownerId)
    local function safe(point,escaping,returning)
     local ground=world.model.Ground
     local localPoint=ground.CFrame:PointToObjectSpace(point)
     local p=ground.CFrame:PointToWorldSpace(Vector3.new(localPoint.X,.95+Topography.sampleHeight(localPoint.X,localPoint.Z)+3,localPoint.Z))
     local foundation=world.model.Plots["Plot"..owner.plotId].Foundation
     if not CombatRules.containsArena(arena,p) and not (returning and MedicalRoute.contains(foundation,arena.Position,p)) then return nil end
     for _,other in actors do
      if other.rig~=rig and math.abs(other.position.Y-p.Y)<4 and (other.position-p).Magnitude<3 then return nil end
     end
     local delta=p-attacker.position
     if delta.Magnitude>.01 and delta.Magnitude<=18 then
      local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude
      local excluded={rig,troops}
      local neutrals=world.model:FindFirstChild("NeutralOpponents")
      if neutrals then table.insert(excluded,neutrals) end
      filter.FilterDescendantsInstances=excluded;filter.RespectCanCollide=true
      if workspace:Blockcast(CFrame.new(attacker.position+Vector3.new(0,.5,0)),Vector3.new(1.6,3.6,1.6),delta,filter) then return nil end
     end
     return p
    end
    local formed=formationGoals and formationGoals[slot.id]~=nil
    local ordinaryOrder=if owner.order=="formation" then "advance" else owner.order
    if slot.kind=="medic" then
     local forward=arena.Position-frame.Position
     forward=Vector3.new(forward.X,0,forward.Z).Unit
     local plan=MedicPlanner.step(attacker,actors,ordinaryOrder,arena.Position,forward,
      CombatRules.containsArena(arena,attacker.position),safe,function(point)return CombatRules.containsArena(arena,point)end)
     if formed then
      rig:SetAttribute("FormationAvoiding",plan.avoiding==true)
      if not plan.avoiding then
       plan.goal=if owner.order=="hold" then nil else formationGoals[slot.id]
       plan.phase,plan.state,plan.formation,plan.direct,plan.speed="idle","Formation",true,false,FormationConfig.pace
       plan.allowsDetour=nil
       if owner.formation.phase~="assembling" then plan.facing=attacker.position+Formation.facing(owner.formation,slot.id)*10 end
      end
     end
     Motion.apply(rig,slot.navigator,world,plan,now)
     if medicine:throw(rig,actors) and not plan.goal then
      local target=rig:GetAttribute("BandageTargetPosition")
      local point=Vector3.new(target.X,attacker.position.Y,target.Z)
      if (point-attacker.position).Magnitude>.01 then attacker.root.CFrame=CFrame.lookAt(attacker.position,point) end
     end
     continue
    end
    slot.medicalRecovery=slot.medicalRecovery or {}
    local recoveryPlan=if formed then nil else MedicalRetreat.step(slot.medicalRecovery,attacker,actors,ordinaryOrder,economy:get(ownerId),safe,
     function(from,patient)return combat:visible(from,patient)end)
    rig:SetAttribute("MedicalSupportActive",recoveryPlan~=nil)
    local angle=(claim.plotId-1)*math.pi*2/world.plotCount
				local radius=if slot.id=="reinforcement" then 42 elseif slot.id=="camp" then 32 elseif slot.kind=="ranged" then 22 else 12
				local home=arena.Position+Vector3.new(math.sin(angle)*radius,4,math.cos(angle)*radius)
				local guarding=formed and owner.order~="hold" and owner.formation.phase=="screening" and slot.kind=="warrior"
				local guard=if guarding then {center=formationGoals[slot.id],radius=owner.formation.definition.guardRadius} else nil
				local plan=encounters:step(rig,{order=if guarding then "advance" elseif formed then "hold" else ordinaryOrder,
					formation=formed,guard=guard,homeGoal=if guard then guard.center else home,actors=actors,support=recoveryPlan,
					cancelShots=function() projectiles:cancel(rig) end,
					fire=function(target)
						local variant=Ranged.variants[rig:GetAttribute("CivilizationId")]
						return projectiles:fire(rig,target,variant.projectileKind)
					end},now)
				if guarding then
					plan.speed=FormationConfig.pace
					if not plan.facing then plan.facing=attacker.position+owner.formation.heading*10 end
				elseif formed and owner.order~="hold" then
					plan.goal,plan.formation,plan.direct,plan.speed=formationGoals[slot.id],true,false,FormationConfig.pace
					local anchorGoal=plan.goal
					if owner.formation.phase~="assembling" and (not plan.facing
						or (plan.phase=="idle" and owner.formation.definition.facingAngles[slot.id]~=nil)) then
						plan.facing=attacker.position+Formation.facing(owner.formation,slot.id)*10
					end
					plan.allowsDetour=if owner.formation.phase=="assembling" then nil else function(p)return (p-anchorGoal).Magnitude<=FormationConfig.cohesionTolerance end
				end
				slot.target=plan.target
				Motion.apply(rig,slot.navigator,world,plan,now)
			end
		end
	end
	local elapsed = 0
	local heartbeat: RBXScriptConnection
	function controller:destroy()
		if not alive then return end
		alive = false
		if heartbeat then heartbeat:Disconnect() end
		local ids = {}
		for ownerId in owners do table.insert(ids, ownerId) end
		for _, ownerId in ids do self:release(ownerId) end
		medicine:destroy()
		projectiles:destroy()
		if not sharedEncounter then encounters:destroy() end
		if not sharedCombat then combat:destroy() end
		troops:Destroy()
	end
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not world.model:IsDescendantOf(workspace) then controller:destroy(); return end
		local now = os.clock()
		local finishedSkill=combat.skills:step()
		medicine:step()
		projectiles:step(dt)
		elapsed += dt
		if finishedSkill or elapsed >= Config.thinkInterval then elapsed = 0; think(now) end
		for _, owner in owners do
			for _, slot in owner.slots do
				if slot.rig then
					local root = slot.rig:FindFirstChild("HumanoidRootPart")
					if slot.rig.Humanoid.Health>0 then
						if owner.order~="regroup" and slot.kind~="medic" then Motion.publish(slot.rig,encounters:advance(slot.rig,now)) end
						WarriorRig.animate(slot.rig,now,root and root.AssemblyLinearVelocity.Magnitude>.5)
					end
				end
			end
		end
	end)
	return controller
end

return WarriorService

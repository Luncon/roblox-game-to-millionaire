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
local WarriorService = {}
local COLLISION_GROUP = "CivilizationWarriors"
local ORDERS = {advance=true,hold=true,regroup=true}

-- Slot identity survives a class choice; camp.kind is resolved at its next spawn.
function WarriorService.slotDefinitions(state)
	local slots = {{id="warrior",kind="warrior"}}
	if Tracks.barracks[state.barracksLevel or 1].capacity >= 2 then
		table.insert(slots,{id="ranged",kind="ranged"})
	end
	if state.armyCampLevel == 1 then
		table.insert(slots,{id="camp",kind=if state.extraTroopClass=="ranged" then "ranged" else "warrior"})
	end
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
	local projectiles = TroopProjectile.new(world, combat, function(rig)
		return alive and rigSlots[rig] ~= nil
	end)
	if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then PhysicsService:RegisterCollisionGroup(COLLISION_GROUP) end
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

	local function eligible(player: Player)
		local claim, state = registry:get(player.UserId), economy:get(player.UserId)
		if not alive or not world.model:IsDescendantOf(workspace) or troops.Parent ~= world.model
			or player.Parent ~= Players or not claim or not state or state.level < Config.unlockLevel then return nil end
		return claim, state
	end
	local function tier(state)
		return Tracks.barracks[state.barracksLevel or 1]
	end
	local function publish(owner)
		local state = economy:get(owner.player.UserId)
		if not state then return end
		local warrior, ranged, camp = owner.slots.warrior, owner.slots.ranged, owner.slots.camp
		local meleeCount, rangedCount = 0, 0
		for _, slot in owner.slots do
			if slot.rig then
				if slot.kind=="ranged" then rangedCount+=1 else meleeCount+=1 end
			end
		end
		owner.player:SetAttribute("BarracksLevel", state.barracksLevel or 1)
		owner.player:SetAttribute("WarriorCount", meleeCount)
		owner.player:SetAttribute("RangedCount", rangedCount)
		owner.player:SetAttribute("ArmyCount", meleeCount + rangedCount)
		owner.player:SetAttribute("TroopCapacity", #WarriorService.slotDefinitions(state))
		owner.player:SetAttribute("ArmyRespawnDelay", tier(state).respawnDelay)
		owner.player:SetAttribute("WarriorRespawnAt", if warrior then warrior.respawnAt else 0)
		owner.player:SetAttribute("RangedRespawnAt", if ranged then ranged.respawnAt else 0)
		owner.player:SetAttribute("CampCount", if camp and camp.rig then 1 else 0)
		owner.player:SetAttribute("CampRespawnAt", if camp then camp.respawnAt else 0)
		owner.player:SetAttribute("CampClass", if camp then camp.kind else nil)
		owner.player:SetAttribute("ExtraTroopClass", state.extraTroopClass or "warrior")
		owner.player:SetAttribute("ArmyOrder", owner.order)
	end
	local function clearAttributes(player: Player)
		for _, name in {"BarracksLevel", "WarriorCount", "RangedCount", "ArmyCount", "TroopCapacity", "ArmyRespawnDelay", "WarriorRespawnAt", "RangedRespawnAt", "CampCount", "CampRespawnAt"} do
			player:SetAttribute(name, 0)
		end
		player:SetAttribute("CampClass",nil)
		player:SetAttribute("ExtraTroopClass","warrior")
		player:SetAttribute("ArmyOrder","advance")
	end
	local function disconnect(slot)
		if slot.deathConnection then slot.deathConnection:Disconnect(); slot.deathConnection = nil end
		if slot.destroyConnection then slot.destroyConnection:Disconnect(); slot.destroyConnection = nil end
		if slot.navigator then slot.navigator:destroy(); slot.navigator = nil end
		slot.target = nil
		slot.rest,slot.restGoal,slot.restFrame,slot.restDirect=nil,nil,nil,nil
		if slot.rig then
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

	local spawnSlot
	local function fallen(owner, slot, rig: Model)
		if not current(owner, slot) or slot.rig ~= rig then return end
		local state = economy:get(owner.player.UserId)
		local delay = if state then tier(state).respawnDelay else Config.respawnDelay
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
		slot.navigator = WarriorNavigator.new(rig, function() return current(owner, slot) and slot.rig == rig end)
		slot.holdPosition=if owner.order=="hold" then root.Position else nil
		if owner.order=="hold" then slot.navigator:stop() end
		slot.deathConnection = humanoid.Died:Connect(function() fallen(owner, slot, rig) end)
		slot.destroyConnection = rig.Destroying:Connect(function() fallen(owner, slot, rig) end)
		rig:SetAttribute("ArmySlot",slot.id)
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
				if humanoid and humanoid.Health > 0 then WarriorRig.update(slot.rig, catalog[claim.civilizationId], state)
				else fallen(owner, slot, slot.rig) end
			end
		end
		for id, slot in owner.slots do
			if not available[id] then disposeSlot(slot);owner.slots[id]=nil end
		end
		-- Each slot keeps its original pending deadline through all purchases.
		publish(owner)
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
		if owner.order~=order then
			owner.order=order
			for _, slot in owner.slots do
				slot.target=nil
				slot.rest,slot.restGoal,slot.restFrame,slot.restDirect=nil,nil,nil,nil
				if slot.navigator then slot.navigator:stop() end
				local rig=slot.rig
				local troopRoot=rig and rig:FindFirstChild("HumanoidRootPart")
				slot.holdPosition=if order=="hold" and troopRoot then troopRoot.Position else nil
				if rig then
					encounters:cancel(rig)
					Motion.clear(rig)
					rig.Humanoid.WalkSpeed=Config.walkSpeed
					rig:SetAttribute("RestPhase",nil)
					if order=="regroup" then projectiles:cancel(rig) end
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
			for _, slot in owner.slots do
				local rig = slot.rig
				if not rig then continue end
				local attacker = combat:actor(rig)
				if not attacker then fallen(owner, slot, rig); continue end
				if owner.order=="regroup" then
					slot.rest=slot.rest or ArmyRest.new(slot.id)
					local frame=world.model.Plots["Plot"..owner.plotId].Foundation.CFrame
					local position=frame:PointToObjectSpace(attacker.position)
					local goal,speed,arrived=ArmyRest.step(slot.rest,position,now)
					local direct=goal~=nil and TrainingCamp.contains(position,2)
					attacker.humanoid.WalkSpeed=speed
					if goal~=slot.restGoal or frame~=slot.restFrame or direct~=slot.restDirect then
						if not goal then slot.navigator:stop()
						elseif direct then slot.navigator:walkDirect(frame:PointToWorldSpace(goal))
						else slot.navigator:setGoal(frame:PointToWorldSpace(goal)) end
						slot.restGoal=goal
						slot.restFrame=frame
						slot.restDirect=direct
					end
					if goal and not direct then slot.navigator:step(now) end
					rig:SetAttribute("WarriorState",if arrived then "Regrouped" else "Regrouping")
					rig:SetAttribute("RestPhase",slot.rest.phase)
					continue
				end
				local claim=registry:get(ownerId)
				local angle=(claim.plotId-1)*math.pi*2/world.plotCount
				local radius=if slot.id=="camp" then 32 elseif slot.kind=="ranged" then 22 else 12
				local home=arena.Position+Vector3.new(math.sin(angle)*radius,4,math.cos(angle)*radius)
				local plan=encounters:step(rig,{order=owner.order,homeGoal=home,actors=actors,
					fire=function(target)
						local variant=Ranged.variants[rig:GetAttribute("CivilizationId")]
						return projectiles:fire(rig,target,variant.projectileKind)
					end},now)
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
		projectiles:destroy()
		if not sharedEncounter then encounters:destroy() end
		if not sharedCombat then combat:destroy() end
		troops:Destroy()
	end
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not world.model:IsDescendantOf(workspace) then controller:destroy(); return end
		local now = os.clock()
		projectiles:step(dt)
		elapsed += dt
		if elapsed >= Config.thinkInterval then elapsed = 0; think(now) end
		for _, owner in owners do
			for _, slot in owner.slots do
				if slot.rig then
					local root = slot.rig:FindFirstChild("HumanoidRootPart")
					if slot.rig.Humanoid.Health>0 then
						if owner.order~="regroup" then Motion.publish(slot.rig,encounters:advance(slot.rig,now)) end
						WarriorRig.animate(slot.rig,now,root and root.AssemblyLinearVelocity.Magnitude>.5)
					end
				end
			end
		end
	end)
	return controller
end

return WarriorService

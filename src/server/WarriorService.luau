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
local TroopProjectile = require(script.Parent.TroopProjectile)
local WarriorService = {}
local COLLISION_GROUP = "CivilizationWarriors"

function WarriorService.start(world, registry, economy, catalog, sharedCombat)
	local controller = {}
	local owners, rigSlots, playerRigs = {}, {}, {}
	local alive = true
	local arena = world.model:FindFirstChild("Battlefield") :: BasePart
	local troops = world.model:FindFirstChild("Troops")
	assert(troops and troops:IsA("Folder"), "Map must provide a Troops folder")
	local combat = sharedCombat or CombatService.new(world, registry, economy)
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
		local warrior, ranged = owner.slots.warrior, owner.slots.ranged
		local meleeCount = if warrior and warrior.rig then 1 else 0
		local rangedCount = if ranged and ranged.rig then 1 else 0
		owner.player:SetAttribute("BarracksLevel", state.barracksLevel or 1)
		owner.player:SetAttribute("WarriorCount", meleeCount)
		owner.player:SetAttribute("RangedCount", rangedCount)
		owner.player:SetAttribute("ArmyCount", meleeCount + rangedCount)
		owner.player:SetAttribute("TroopCapacity", tier(state).capacity)
		owner.player:SetAttribute("ArmyRespawnDelay", tier(state).respawnDelay)
		owner.player:SetAttribute("WarriorRespawnAt", warrior.respawnAt)
		owner.player:SetAttribute("RangedRespawnAt", if ranged then ranged.respawnAt else 0)
	end
	local function clearAttributes(player: Player)
		for _, name in {"BarracksLevel", "WarriorCount", "RangedCount", "ArmyCount", "TroopCapacity", "ArmyRespawnDelay", "WarriorRespawnAt", "RangedRespawnAt"} do
			player:SetAttribute(name, 0)
		end
	end
	local function disconnect(slot)
		if slot.deathConnection then slot.deathConnection:Disconnect(); slot.deathConnection = nil end
		if slot.destroyConnection then slot.destroyConnection:Disconnect(); slot.destroyConnection = nil end
		if slot.navigator then slot.navigator:destroy(); slot.navigator = nil end
		slot.target = nil
		if slot.rig then
			projectiles:cancel(slot.rig)
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
		return alive and owners[owner.player.UserId] == owner and owner.slots[slot.kind] == slot
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
		if not claim or not current(owner, slot) or slot.rig or (slot.kind == "ranged" and tier(state).capacity < 2) then return end
		local rig = WarriorRig.create(catalog[claim.civilizationId], world:getBarracksSpawn(claim.plotId, slot.kind),
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
		slot.deathConnection = humanoid.Died:Connect(function() fallen(owner, slot, rig) end)
		slot.destroyConnection = rig.Destroying:Connect(function() fallen(owner, slot, rig) end)
		rig:SetAttribute("WarriorState", "Marching")
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
		if not owner then owner = {player = player, slots = {}}; owners[player.UserId] = owner end
		world:setBarracksLevel(claim.plotId, state.barracksLevel or 1)
		for _, kind in {"warrior", "ranged"} do
			if kind == "ranged" and tier(state).capacity < 2 then continue end
			local slot = owner.slots[kind]
			if not slot then
				slot = {kind = kind, rig = nil, respawnAt = 0, corpses = {}, nextAttack = 0, attackUntil = 0}
				owner.slots[kind] = slot
				spawnSlot(owner, slot)
			elseif slot.rig then
				local humanoid = slot.rig:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then WarriorRig.update(slot.rig, catalog[claim.civilizationId], state)
				else fallen(owner, slot, slot.rig) end
			end
		end
		-- Each slot keeps its original pending deadline through all purchases.
		publish(owner)
	end
	function controller:get(ownerId: number)
		local owner = owners[ownerId]
		if not owner then return nil end
		local slots = {}
		for kind, slot in owner.slots do slots[kind] = {rig = slot.rig, respawnAt = slot.respawnAt} end
		return {rig = slots.warrior.rig, respawnAt = slots.warrior.respawnAt, slots = slots}
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
	local function visible(attacker, target): boolean
		local filter = RaycastParams.new()
		filter.FilterType = Enum.RaycastFilterType.Exclude
		filter.FilterDescendantsInstances = {attacker.rig}
		local hit = workspace:Raycast(attacker.position + Vector3.new(0, 1, 0), target.position - attacker.position, filter)
		return hit == nil or hit.Instance:IsDescendantOf(target.rig)
	end
	local function think(now: number)
		syncFallbackPlayers()
		local actors = combat:actors() -- At most sixteen troops plus eight players.
		for ownerId, owner in owners do
			for _, slot in owner.slots do
				local rig = slot.rig
				if not rig then continue end
				local attacker = combat:actor(rig)
				if not attacker then fallen(owner, slot, rig); continue end
				local nearest = nil
				local distance = if slot.kind == "ranged" then Ranged.aggroRange else Config.aggroRange
				if CombatRules.containsArena(arena, attacker.position) then
					for _, candidate in actors do
						local separation = (candidate.position - attacker.position).Magnitude
						if candidate.ownerId ~= ownerId and separation <= distance and CombatRules.containsArena(arena, candidate.position) then
							nearest, distance = candidate, separation
						end
					end
				end
				local target = if nearest then nearest.rig else nil
				if slot.target ~= target then slot.navigator:stop(); slot.target = target end
				if nearest then
					rig:SetAttribute("WarriorState", "Fighting")
					slot.navigator:setGoal(nearest.position)
					local range = if slot.kind == "ranged" then Ranged.range else Config.attackRange
					if distance <= range and visible(attacker, nearest) then
						slot.navigator:stop()
						local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
						local facing = Vector3.new(nearest.position.X, root.Position.Y, nearest.position.Z)
						if (facing - root.Position).Magnitude > .01 then root.CFrame = CFrame.lookAt(root.Position, facing) end
						if now >= slot.nextAttack then
							if slot.kind == "ranged" then
								local variant = Ranged.variants[rig:GetAttribute("CivilizationId")]
								if projectiles:fire(rig, nearest.rig, variant.projectileKind) then
									slot.nextAttack, slot.attackUntil = now + Ranged.attackCooldown, now + .35
									rig:SetAttribute("LastAttackAt", workspace:GetServerTimeNow())
								end
							else
								local result = combat:hit(rig, nearest.rig)
								if result.ok then slot.nextAttack, slot.attackUntil = now + Config.attackCooldown, now + .35 end
							end
						end
					end
				else
					local claim = registry:get(ownerId)
					local angle = (claim.plotId - 1) * math.pi * 2 / world.plotCount
					local radius = if slot.kind == "ranged" then 22 else 12
					slot.navigator:setGoal(arena.Position + Vector3.new(math.sin(angle) * radius, 4, math.cos(angle) * radius))
					rig:SetAttribute("WarriorState", if CombatRules.containsArena(arena, attacker.position) then "Guarding" else "Marching")
				end
				slot.navigator:step(now)
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
					WarriorRig.animate(slot.rig, now, root and root.AssemblyLinearVelocity.Magnitude > .5, now < slot.attackUntil)
				end
			end
		end
	end)
	return controller
end

return WarriorService

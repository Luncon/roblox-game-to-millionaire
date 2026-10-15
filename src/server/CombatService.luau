--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Tracks = require(Shared.UpgradeTracks)
local Warrior = require(Shared.WarriorConfig)
local Ranged = require(Shared.RangedConfig)
local Rules = require(script.Parent.CombatRules)
local CombatService = {}

function CombatService.new(world, registry, economy, publishEconomy)
	local controller = {}
	local records, nextAttack = {}, {}
	local rewarded = setmetatable({}, {__mode="k"})
	local active = true
	local arena = world.model.Battlefield
	function controller:unregister(rig)
		local record = records[rig]
		if record and record.connection then record.connection:Disconnect() end
		records[rig], nextAttack[rig] = nil, nil
	end
	function controller:register(rig, ownerId, kind)
		if not active or typeof(rig) ~= "Instance" or not rig:IsA("Model") then return false end
		if kind ~= "player" and kind ~= "warrior" and kind ~= "ranged" then return false end
		local claim = registry:get(ownerId)
		if not claim then return false end
		local existing = records[rig]
		if existing and existing.ownerId == ownerId and existing.kind == kind
			and existing.civilizationId == claim.civilizationId and existing.plotId == claim.plotId then return true end
		self:unregister(rig)
		local record = {ownerId=ownerId,kind=kind,civilizationId=claim.civilizationId,plotId=claim.plotId}
		records[rig] = record
		record.connection = rig.Destroying:Connect(function() self:unregister(rig) end)
		return true
	end
	function controller:actor(rig)
		if not active or not world.model:IsDescendantOf(workspace) then return nil end
		local record = records[rig]
		if not record or not rig:IsDescendantOf(workspace) then return nil end
		local owner = Players:GetPlayerByUserId(record.ownerId)
		local claim = registry:get(record.ownerId)
		if not owner or owner.Parent ~= Players or not claim or not economy:get(record.ownerId)
			or claim.civilizationId ~= record.civilizationId or claim.plotId ~= record.plotId then return nil end
		if record.kind == "player" then
			if owner.Character ~= rig then return nil end
		elseif not rig:IsDescendantOf(world.model.Troops) or rig:GetAttribute("OwnerId") ~= record.ownerId
			or rig:GetAttribute("CivilizationId") ~= claim.civilizationId
			or rig:GetAttribute("WarriorClass") ~= record.kind then return nil end
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local root = rig:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
		return {ownerId=record.ownerId,kind=record.kind,civilizationId=record.civilizationId,plotId=record.plotId,
			position=root.Position,alive=true,claimed=true,rig=rig,humanoid=humanoid,root=root,player=owner}
	end
	function controller:actors()
		local actors = {}
		for rig in records do
			local actor = self:actor(rig)
			if actor then table.insert(actors,actor) end
		end
		return actors
	end
	function controller:visible(attacker, target)
		local filter = RaycastParams.new()
		filter.FilterType = Enum.RaycastFilterType.Exclude
		filter.FilterDescendantsInstances = {attacker.rig}
		local origin = attacker.position+Vector3.new(0,1,0)
		local destination = target.position+Vector3.new(0,1,0)
		local hit = workspace:Raycast(origin,destination-origin,filter)
		return hit == nil or hit.Instance:IsDescendantOf(target.rig)
	end
	function controller:hit(attackerRig, targetRig)
		local attacker, target = self:actor(attackerRig), self:actor(targetRig)
		if not attacker or not target then return {ok=false,reason="invalid_actor"} end
		local ranged = attacker.kind == "ranged"
		local reach = if ranged then Ranged.range else Warrior.attackRange
		if not Rules.canDamage(attacker,target,arena,reach) or not self:visible(attacker,target) then
			return {ok=false,reason="protected_or_blocked"}
		end
		local state = economy:get(attacker.ownerId)
		if attacker.kind == "player" then
			local tool = attackerRig:FindFirstChildOfClass("Tool")
			if not tool or tool:GetAttribute("GeneratedBy") ~= "CivilizationEquipment"
				or tool:GetAttribute("CivilizationId") ~= attacker.civilizationId
				or tool:GetAttribute("WeaponLevel") ~= state.weaponLevel then return {ok=false,reason="not_equipped"} end
		end
		local time = os.clock()
		if time < (nextAttack[attackerRig] or 0) then return {ok=false,reason="cooldown"} end
		local damage = Tracks.weapon[state.weaponLevel].damage
		if ranged then damage = math.max(1,damage*Ranged.damageMultiplier) end
		nextAttack[attackerRig] = time + (if ranged then Ranged.attackCooldown else Warrior.attackCooldown)
		local humanoid = target.humanoid
		local before = humanoid.Health
		humanoid:TakeDamage(damage)
		local after = humanoid.Health
		if after >= before then return {ok=false,reason="blocked_damage"} end
		local killed = before > 0 and after <= 0
		local reward
		if killed and not rewarded[humanoid] then
			-- Consume this life before publication; Died may already have released
			-- the victim's troop slot. Its validated lethal transition is sufficient.
			rewarded[humanoid] = true
			local current = registry:get(attacker.ownerId)
			if attacker.player.Parent == Players and current and current.civilizationId == attacker.civilizationId
				and current.plotId == attacker.plotId then
				reward = economy:rewardKill(attacker.ownerId)
				if reward.ok and publishEconomy then publishEconomy(attacker.player,reward,"kill") end
			end
		end
		return {ok=true,damage=before-after,killed=killed,reward=reward}
	end
	function controller:destroy()
		active = false
		local rigs = {}
		for rig in records do table.insert(rigs,rig) end
		for _, rig in rigs do self:unregister(rig) end
		table.clear(rewarded)
	end
	return controller
end

return CombatService

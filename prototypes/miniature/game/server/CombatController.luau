--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Battle = require(script.Parent.Battle)
local OutpostWorld = require(script.Parent.OutpostWorld)
local OriginalBehavior = require(script.Parent.OriginalBehavior)
local State = require(script.Parent.State)
local ArmyGroups = require(ReplicatedStorage.MiniatureGame.ArmyGroups)
local Controller = {}

function Controller.start(world)
	local visuals = OutpostWorld.create(world)
	local behavior = OriginalBehavior.new()
	local owners = {}
	local contexts, orders = {}, {}
	local filter = RaycastParams.new()
	filter.FilterType = Enum.RaycastFilterType.Exclude
	local battle = Battle.new(visuals.definitions, {
		behavior = behavior,
		visible = function(attacker, target)
			local excluded = { world.scene }
			for _, player in Players:GetPlayers() do
				if player.Character then
					table.insert(excluded, player.Character)
				end
			end
			filter.FilterDescendantsInstances = excluded
			local origin = Vector3.new(attacker.x, 1.3, attacker.z)
			return Workspace:Raycast(origin, Vector3.new(target.x, 1.3, target.z) - origin, filter) == nil
		end,
	})
	for _, plot in world.plots do
		plot.model:SetAttribute("CombatManaged", true)
	end
	local controller = { battle = battle }

	function controller:remove(userId: number)
		local team = owners[userId]
		if team then
			battle:removeArmy(team)
			owners[userId] = nil
		end
		contexts[userId], orders[userId] = nil, nil
	end

	function controller:sync(userId: number, view, now: number)
		if not view.writable or not view.claim or not view.state then
			self:remove(userId)
			return
		end
		local claim, state = view.claim, view.state
		local team = tostring(userId) .. ":" .. claim.civilizationId .. ":" .. tostring(claim.plotId)
		if owners[userId] and owners[userId] ~= team then
			self:remove(userId)
		end
		owners[userId] = team
		local known = ArmyGroups.members(state, 1) or {}
		local military = {}
		for _, id in known do
			military[id] = true
		end
		local targets = orders[userId] or {}
		for id, target in targets do
			if not military[id] or not battle.outposts[target] then
				targets[id] = nil
			end
		end
		orders[userId] = targets
		contexts[userId] = { state = state, known = known }
		local slots = {}
		local plot = world.plots[claim.plotId]
		local groups = State.troopGroups(state)
		for _, building in state.buildings do
			local group = groups[building.id]
			if group then
				for index = 1, group.count do
					local offset = if group.count == 1 then 0 else (index - 1.5) * 3.8
					local frame = plot.frame
						* CFrame.new(building.x, 0, building.z)
						* CFrame.Angles(0, math.rad(building.rotation), 0)
						* CFrame.new(offset, 0, 1.5)
					table.insert(slots, {
						id = "army:" .. team .. ":" .. building.id .. ":" .. tostring(index),
						role = group.role,
						buildingId = building.id,
						index = index,
						x = frame.Position.X,
						z = frame.Position.Z,
					})
				end
			end
		end
		local result = battle:syncArmy(
			team,
			claim.civilizationId,
			claim.plotId,
			slots,
			now,
			state.militaryResearch.completed,
			{ buildingTargets = targets, knownMilitaryBuildingIds = known }
		)
		assert(result.ok, "Invalid server-generated army: " .. tostring(result.reason))
	end

	function controller:position(outpostId)
		local outpost = battle.outposts[outpostId]
		return if outpost then Vector3.new(outpost.x, 0.4, outpost.z) else nil
	end

	function controller:validateOrder(userId: number, args)
		if type(args) ~= "table" or type(args.outpostId) ~= "string" then
			return { ok = false, reason = "invalid_outpost" }
		end
		for key in args do
			if key ~= "outpostId" and key ~= "armyId" then
				return { ok = false, reason = "invalid_outpost" }
			end
		end
		if not self:position(args.outpostId) or not owners[userId] then
			return { ok = false, reason = "invalid_outpost" }
		end
		local context = contexts[userId]
		local armyId = if args.armyId == nil then 1 else args.armyId
		if not context or type(armyId) ~= "number" or armyId % 1 ~= 0 or armyId < 1 or armyId > 4 then
			return { ok = false, reason = "invalid_army_group" }
		end
		local members = ArmyGroups.members(context.state, armyId)
		if not members then
			return { ok = false, reason = "army_locked" }
		end
		if armyId ~= 1 and #members == 0 then
			return { ok = false, reason = "empty_army" }
		end
		return { ok = true, outpostId = args.outpostId, armyId = armyId }
	end

	function controller:command(userId: number, outpostId: string, armyId: number?)
		local team = owners[userId]
		local context = contexts[userId]
		if not team or not context then
			return { ok = false, reason = "no_army" }
		end
		local selected = armyId or 1
		local members = ArmyGroups.members(context.state, selected)
		if not members then
			return { ok = false, reason = "army_locked" }
		end
		if selected ~= 1 and #members == 0 then
			return { ok = false, reason = "empty_army" }
		end
		local result = battle:command(team, outpostId, if selected == 1 then nil else members)
		if result.ok then
			if selected == 1 then
				orders[userId] = {}
			else
				for _, id in members do
					orders[userId][id] = outpostId
				end
			end
		end
		return result
	end

	function controller:snapshot(userId: number)
		local outposts = {}
		for id, outpost in battle.outposts do
			outposts[id] = {
				id = id,
				position = Vector3.new(outpost.x, 0.4, outpost.z),
				lineId = outpost.lineId,
				ownerTeam = outpost.ownerTeam,
				ownerCivilizationId = outpost.ownerCivilizationId,
				progress = outpost.progress,
				status = outpost.status,
				captureTeam = outpost.captureTeam,
			}
		end
		local team = owners[userId]
		local army = if team then battle.armies[team] else nil
		local alive = { melee = 0, ranged = 0, medic = 0, mounted = 0 }
		local capacityUsed = 0
		local aliveByBuilding = {}
		for _, actor in battle.actors do
			if actor.team == team then
				capacityUsed += if actor.role == "mounted" then 2 else 1
			end
			if actor.team == team and actor.alive then
				alive[actor.role] += 1
				aliveByBuilding[actor.buildingId] = (aliveByBuilding[actor.buildingId] or 0) + 1
			end
		end
		local cards = {}
		local context = contexts[userId]
		if context then
			local allocated = State.troopGroups(context.state)
			for armyId = 1, 4 do
				local members = ArmyGroups.members(context.state, armyId) or {}
				local count, living, used, waiting = 0, 0, 0, 0
				local targetId, seenTarget, mixed = nil, false, false
				for _, id in members do
					local allocation = allocated[id]
					if allocation then
						count += allocation.count
						used += allocation.count * (if allocation.role == "mounted" then 2 else 1)
					else
						waiting += 1
					end
					living += aliveByBuilding[id] or 0
					local target = (orders[userId] and orders[userId][id]) or (army and army.targetId)
					if seenTarget and target ~= targetId then
						mixed = true
					end
					if not seenTarget then
						targetId, seenTarget = target, true
					end
				end
				table.insert(cards, {
					armyId = armyId,
					buildingIds = members,
					count = count,
					alive = living,
					capacityUsed = used,
					waitingBuildings = waiting,
					targetId = if mixed then nil else targetId,
					mixedTargets = mixed,
				})
			end
		end
		return outposts,
			{
				targetId = army and army.targetId,
				manual = army and army.manual == true,
				alive = alive,
				capacityUsed = capacityUsed,
			},
			cards
	end

	function controller:step(dt: number, now: number)
		battle:step(dt, now)
		visuals:update(battle, now)
		visuals:syncActors(battle, now)
	end

	function controller:destroy()
		table.clear(owners)
		table.clear(contexts)
		table.clear(orders)
		behavior:destroy()
		visuals:destroy()
		ReplicatedStorage:SetAttribute("MiniatureCombatReady", false)
	end

	controller:step(0, os.clock())
	ReplicatedStorage:SetAttribute("MiniatureCombatReady", true)
	return controller
end

return Controller

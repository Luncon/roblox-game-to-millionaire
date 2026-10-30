--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Battle = require(script.Parent.Battle)
local OutpostWorld = require(script.Parent.OutpostWorld)
local OriginalBehavior = require(script.Parent.OriginalBehavior)
local State = require(script.Parent.State)
local Controller = {}

function Controller.start(world)
	local visuals = OutpostWorld.create(world)
	local behavior = OriginalBehavior.new()
	local owners = {}
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
		local result = battle:syncArmy(team, claim.civilizationId, claim.plotId, slots, now)
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
			if key ~= "outpostId" then
				return { ok = false, reason = "invalid_outpost" }
			end
		end
		if not self:position(args.outpostId) or not owners[userId] then
			return { ok = false, reason = "invalid_outpost" }
		end
		return { ok = true, outpostId = args.outpostId }
	end

	function controller:command(userId: number, outpostId: string)
		local team = owners[userId]
		return if team then battle:command(team, outpostId) else { ok = false, reason = "no_army" }
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
		for _, actor in battle.actors do
			if actor.team == team then
				capacityUsed += if actor.role == "mounted" then 2 else 1
			end
			if actor.team == team and actor.alive then
				alive[actor.role] += 1
			end
		end
		return outposts,
			{
				targetId = army and army.targetId,
				manual = army and army.manual == true,
				alive = alive,
				capacityUsed = capacityUsed,
			}
	end

	function controller:step(dt: number, now: number)
		battle:step(dt, now)
		visuals:update(battle, now)
		visuals:syncActors(battle, now)
	end

	function controller:destroy()
		table.clear(owners)
		behavior:destroy()
		visuals:destroy()
		ReplicatedStorage:SetAttribute("MiniatureCombatReady", false)
	end

	controller:step(0, os.clock())
	ReplicatedStorage:SetAttribute("MiniatureCombatReady", true)
	return controller
end

return Controller

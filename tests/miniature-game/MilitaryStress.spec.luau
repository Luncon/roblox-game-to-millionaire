--!strict
-- Deterministic stress with real battle/research/group modules and explicit engine doubles.
-- This suite never opens Studio, accesses a real store, or certifies native rendering.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Server = game:GetService("ServerScriptService").Sandbox
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)
local State = require(Server.State)
local Groups = require(Shared.ArmyGroups)
local Research = require(Shared.MilitaryResearch)
local ResearchClock = require(Server.MilitaryResearch)
local Civilizations = require(Shared.Civilizations)
local Codec = require(Shared.PoseCodec)
local Interpolation = require(Shared.PoseInterpolation)
local function allResearch()
	local result = {}
	for _, id in Research.order do
		result[id] = true
	end
	return result
end
local function slot(id, role, x, z, buildingId, index)
	return {
		id = id,
		role = role,
		x = x or -80,
		z = z or 0,
		buildingId = buildingId or "building:" .. id,
		index = index or 1,
	}
end
local function actorFor(battle, team, slotId)
	for _, actor in battle.actors do
		if actor.team == team and actor.slotId == slotId then
			return actor
		end
	end
	error("Stress fixture actor missing")
end
local function rigFactory(actor)
	local attributes = { ArmySlot = actor.id }
	local rig = { Name = actor.id }
	function rig:GetAttribute(name)
		return attributes[name]
	end
	function rig:SetAttribute(name, value)
		attributes[name] = value
	end
	function rig:Destroy()
		self.destroyed = true
	end
	return rig
end
local function make(original, definitions)
	local behavior = if original then Original.new({ rigFactory = rigFactory }) else nil
	local battle = Battle.new(
		definitions or { { id = "post", x = 0, z = 0, radius = 22, lineId = "lane" } },
		{ behavior = behavior }
	)
	return battle, behavior
end
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function completed(ids)
	local result = {}
	local function add(id)
		if result[id] then
			return
		end
		local parent = Research.nodes[id].predecessor
		if parent then
			add(parent)
		end
		result[id] = true
	end
	for _, id in ids do
		add(id)
	end
	return result
end
local function settlement(civ, progress)
	local state = State.new(civ, 0)
	state.militaryResearch.completed = table.clone(progress)
	local kinds = {
		"mount",
		"training",
		"ranged",
		"healer",
		"training",
		"mount",
		"ranged",
		"healer",
		"training",
		"ranged",
		"healer",
		"mount",
		"healer",
	}
	local columns = { -32, -20, -8, 8, 20, 32 }
	for i, kind in kinds do
		table.insert(state.buildings, {
			id = "b" .. (i + 3),
			kind = kind,
			x = if i == 13 then 32 else columns[(i - 1) % 6 + 1],
			z = if i == 13 then -12 else if i <= 6 then -24 else 24,
			rotation = 0,
			output = 0,
		})
	end
	state.nextBuildingId = 17
	return state
end
local function stateSlots(state)
	local result = {}
	local groups = State.troopGroups(state)
	for _, building in state.buildings do
		local group = groups[building.id]
		if group then
			for i = 1, group.count do
				table.insert(
					result,
					slot(building.id .. ":" .. i, group.role, -80 + building.x * 0.1, building.z * 0.1, building.id, i)
				)
			end
		end
	end
	return result
end
local function unchanged(battle, callback)
	local army = battle.armies.owner
	local actors, targets = {}, table.clone(army.buildingTargets)
	local default, capacity, profiles = army.targetId, army.capacity, army.profiles
	for id, actor in battle.actors do
		actors[id] = table.clone(actor)
	end
	assert(not callback().ok, "Malformed command/sync unexpectedly accepted")
	assert(
		army.targetId == default and army.capacity == capacity and army.profiles == profiles,
		"Refusal changed army metadata"
	)
	for id, target in targets do
		assert(army.buildingTargets[id] == target, "Refusal changed target")
	end
	for id, target in army.buildingTargets do
		assert(targets[id] == target, "Refusal added target")
	end
	for id, previous in actors do
		local actor = battle.actors[id]
		assert(actor, "Refusal deleted actor")
		for key, value in previous do
			assert(actor[key] == value, "Refusal mutated actor " .. key)
		end
		for key, value in actor do
			assert(previous[key] == value, "Refusal added actor field " .. key)
		end
	end
	for id in battle.actors do
		assert(actors[id], "Refusal spawned actor")
	end
end
local function run(): number
	local count, began = 0, os.clock()
	local function check(name, callback)
		callback()
		count += 1
		print("PASS military stress: " .. name)
	end
	check("all thirteen civilizations spawn every role at full baseline and fully researched health", function()
		local fullProgress = allResearch()
		assert(Research.validateCompleted(fullProgress), "Stress research fixture has broken prerequisites")
		for _, civilization in Civilizations do
			for _, progress in { {}, fullProgress } do
				for _, role in { "melee", "ranged", "medic", "mounted" } do
					local battle = make(false)
					local expected = Research.profile(role, civilization.id, progress)
					assert(
						battle:syncArmy("owner", civilization.id, "lane", { slot("one", role) }, 0, progress).ok,
						"Valid researched role rejected"
					)
					local actor = actorFor(battle, "owner", "one")
					assert(
						actor.health == actor.maxHealth and actor.maxHealth == expected.health,
						civilization.id .. " " .. role .. " fresh researched troop spawned with missing health"
					)
					assert(
						actor.profile.damage == expected.damage
							and actor.profile.speed == expected.speed
							and actor.profile.reach == expected.reach,
						"Resolved role stats differ from shared immutable profile"
					)
					assert(table.isfrozen(actor.profile), "Actor profile can be mutated across armies")
				end
			end
		end
	end)
	check("all thirteen legal settlements allocate whole queued groups at every weighted capacity", function()
		local expectations = {
			{ capacity = 10, ids = {}, indices = { 1, 2, 3, 4, 5, 8 } },
			{ capacity = 12, ids = { "army_size_1" }, indices = { 1, 2, 3, 4, 5, 6, 8 } },
			{ capacity = 15, ids = { "army_size_2" }, indices = { 1, 2, 3, 4, 5, 6, 7, 8, 11 } },
			{ capacity = 20, ids = { "army_size_3" }, indices = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13 } },
		}
		for _, civ in Civilizations do
			for _, expectation in expectations do
				local state = settlement(civ.id, completed(expectation.ids))
				assert(State.validate(state, civ.id), "Stress settlement is not a valid saved settlement")
				assert(
					State.troopCapacityUsed(state) == expectation.capacity,
					"Weighted allocation did not fill expected cap"
				)
				local groups, expected = State.troopGroups(state), {}
				for _, index in expectation.indices do
					expected["b" .. (index + 3)] = true
				end
				for _, building in state.buildings do
					assert(
						(groups[building.id] ~= nil) == (expected[building.id] == true),
						"Whole-group queue order changed"
					)
				end
				assert(#Groups.members(state, 1) == 13, "Army 1 lost waiting structures")
				local battle = make(false)
				assert(
					battle:syncArmy("owner", civ.id, "lane", stateSlots(state), 0, state.militaryResearch.completed).ok,
					"Actual allocated slots rejected"
				)
				assert(battle.armies.owner.capacity == expectation.capacity, "Battle/state capacities disagree")
			end
		end
	end)
	check("waiting preset targets backfill then reclaim and Army 1 reset preserve unrelated lives", function()
		local progress = completed({ "army_control" })
		local state = settlement("sparta", progress)
		assert(
			Groups.configure(state, { armyId = 2, buildingIds = { "b9" } }).ok,
			"Waiting mount could not join preset"
		)
		local battle = make(false, {
			{ id = "post", x = 0, z = 0, radius = 22, lineId = "lane" },
			{ id = "other", x = 100, z = 0, radius = 22, lineId = "other" },
		})
		local function sync(targets, now)
			return battle:syncArmy(
				"owner",
				"sparta",
				"lane",
				stateSlots(state),
				now,
				state.militaryResearch.completed,
				{ knownMilitaryBuildingIds = Groups.members(state, 1), buildingTargets = targets }
			)
		end
		assert(
			sync({}, 0).ok and battle:command("owner", "other", Groups.members(state, 2)).ok,
			"Waiting group command rejected"
		)
		local old = actorFor(battle, "owner", "b5:1")
		old.health, old.nextAttack = 41, 19
		local life = old.life
		state.militaryResearch.completed.army_size_1 = true
		assert(sync({ b9 = "other" }, 1).ok, "New capacity rejected")
		local replacement = actorFor(battle, "owner", "b9:1")
		assert(
			replacement.targetOutpostId == "other" and old.targetOutpostId == "post",
			"Queued order redirected wrong group"
		)
		assert(old.life == life and old.health == 41 and old.nextAttack == 19, "Capacity update reset unrelated life")
		for i, building in state.buildings do
			if building.id == "b9" then
				table.remove(state.buildings, i)
				break
			end
		end
		assert(Groups.reconcile(state) and #Groups.members(state, 2) == 0, "Reclaim did not reconcile preset")
		assert(sync({ b9 = "other" }, 2).ok and not battle.actors[replacement.id], "Reclaimed troop survived")
		assert(
			next(battle.armies.owner.buildingTargets) == nil and old.life == life and old.health == 41,
			"Reclaim changed unrelated life/orders"
		)
		assert(
			battle:command("owner", "other", { "b5" }).ok and battle:command("owner", "post").ok,
			"Army reset failed"
		)
		assert(next(battle.armies.owner.buildingTargets) == nil, "Army 1 retained selective orders")
		for _, actor in battle.actors do
			if actor.team == "owner" then
				assert(actor.targetOutpostId == "post", "Army 1 omitted a group")
			end
		end
	end)
	check("malformed slots targets and memberships cannot partially mutate a live army", function()
		local battle = make(false)
		local one = slot("one", "melee")
		assert(battle:syncArmy("owner", "sparta", "lane", { one }, 0).ok, "Initial army rejected")
		local a = actorFor(battle, "owner", "one")
		a.health, a.nextAttack, a.contactAt = 43, 17, 18
		for _, invalid in { { [2] = one }, { one, one }, { [1] = one, extra = one } } do
			unchanged(battle, function()
				return battle:syncArmy("owner", "sparta", "lane", invalid, 1)
			end)
		end
		for _, change in
			{
				{ role = "enemy" },
				{ role = "ranged" },
				{ x = 0 / 0 },
				{ z = math.huge },
				{ x = 1000001 },
				{ index = 0 },
				{ index = 0 / 0 },
				{ buildingId = "foreign" },
			}
		do
			local invalid = table.clone(one)
			for key, value in change do
				invalid[key] = value
			end
			unchanged(battle, function()
				return battle:syncArmy("owner", "sparta", "lane", { invalid }, 1)
			end)
		end
		for _, options in
			{
				{ buildingTargets = {}, knownMilitaryBuildingIds = {} },
				{ buildingTargets = { [one.buildingId] = "missing" }, knownMilitaryBuildingIds = { one.buildingId } },
				{ buildingTargets = {}, knownMilitaryBuildingIds = { [2] = one.buildingId } },
				{ buildingTargets = {}, knownMilitaryBuildingIds = { one.buildingId, one.buildingId } },
			}
		do
			unchanged(battle, function()
				return battle:syncArmy("owner", "sparta", "lane", { one }, 1, {}, options)
			end)
		end
		for _, ids in
			{
				{},
				{ "foreign" },
				{ one.buildingId, one.buildingId },
				{ [2] = one.buildingId },
				{ [1] = one.buildingId, extra = one.buildingId },
			}
		do
			unchanged(battle, function()
				return battle:command("owner", "post", ids)
			end)
		end
		unchanged(battle, function()
			return battle:command("owner", "missing")
		end)
		local injected = table.clone(one)
		injected.health, injected.damage, injected.team, injected.profile = 1e9, 1e9, "foreign", { health = 1e9 }
		assert(
			battle:syncArmy("owner", "sparta", "lane", { injected }, 1).ok,
			"Inert extra slot metadata unexpectedly rejected"
		)
		assert(
			a.health == 43 and a.maxHealth == 160 and a.profile.damage == 30 and a.team == "owner" and a.contactAt == 18,
			"Slot metadata overrode authority"
		)
	end)
	check("eight full twenty-actor armies survive a bounded original-behavior combat soak", function()
		local definitions = {}
		for i = 1, 8 do
			table.insert(definitions, { id = "post" .. i, x = (i - 1) * 150, z = 0, radius = 22, lineId = i })
		end
		local battle, behavior = make(true, definitions)
		local progress, armies = allResearch(), {}
		for i = 1, 8 do
			local slots = {}
			for j = 1, 20 do
				local role = if j <= 8 then "melee" else if j <= 16 then "ranged" else "medic"
				table.insert(
					slots,
					slot("slot" .. j, role, (i - 1) * 150 - 32 - (j % 4) * 2, (math.floor((j - 1) / 4) - 2) * 2)
				)
			end
			local team = "team" .. i
			assert(battle:syncArmy(team, Civilizations[i].id, i, slots, 0, progress).ok, "Twenty actor army rejected")
			local wounded = actorFor(battle, team, "slot1")
			wounded.health = wounded.maxHealth / 2
			table.insert(armies, { team = team, slots = slots, civ = Civilizations[i].id })
		end
		local counts, peakActors, peakEvents = {}, 0, 0
		for step = 1, 600 do
			local previousEvents = battle.events
			assert(battle:step(0.05, step * 0.05).ok, "Bounded combat step failed")
			assert(battle.events ~= previousEvents, "Events accumulate between steps")
			local actors = 0
			for _, actor in battle.actors do
				actors += 1
				assert(finite(actor.x) and finite(actor.z) and finite(actor.health), "Combat produced nonfinite actor")
				assert(
					actor.health >= 0 and actor.health <= actor.maxHealth and actor.profile.speed <= 12,
					"Combat violated role bounds"
				)
			end
			peakActors, peakEvents = math.max(peakActors, actors), math.max(peakEvents, #battle.events)
			assert(actors <= 184 and #battle.events <= 184 * 8, "Soak exceeds fixed actor/event bound")
			for _, event in battle.events do
				counts[event.kind] = (counts[event.kind] or 0) + 1
			end
			if step % 20 == 0 then
				for _, army in armies do
					local actor = actorFor(battle, army.team, "slot1")
					local life, health, deadline, attack = actor.life, actor.health, actor.respawnAt, actor.nextAttack
					assert(
						battle:syncArmy(
							army.team,
							army.civ,
							tonumber(string.sub(army.team, 5)),
							army.slots,
							step * 0.05,
							progress
						).ok,
						"Stable army sync failed"
					)
					assert(
						actor.life == life
							and actor.health == health
							and actor.respawnAt == deadline
							and actor.nextAttack == attack,
						"Stable sync reset combat continuity"
					)
				end
			end
		end
		assert(
			(counts.shot or 0) > 0 and (counts.hit or 0) > 0 and (counts.death or 0) > 0 and (counts.bandage or 0) > 0,
			"Soak failed to exercise actual offensive and medical behavior"
		)
		assert(
			behavior.metrics.encounterAdvances > 0
				and behavior.metrics.crowdPlans > 0
				and behavior.metrics.bandageThrows > 0,
			"Original combat adapter was bypassed"
		)
		print(
			string.format(
				"Military soak: 8 armies, 160 owned actors, 600 steps/30 simulated seconds; peak actors=%d events=%d shots=%d hits=%d deaths=%d bandages=%d",
				peakActors,
				peakEvents,
				counts.shot or 0,
				counts.hit or 0,
				counts.death or 0,
				counts.bandage or 0
			)
		)
		behavior:destroy()
	end)
	check("all civilizations and role profiles move within bounds and round-trip bounded pose histories", function()
		local packets = 0
		for _, civ in Civilizations do
			for _, progress in { {}, allResearch() } do
				for _, role in { "melee", "ranged", "medic", "mounted" } do
					local battle, behavior = make(true)
					assert(
						battle:syncArmy("owner", civ.id, "lane", { slot("one", role) }, 0, progress).ok,
						"Role motion sync failed"
					)
					local a, history = actorFor(battle, "owner", "one"), Interpolation.new(8)
					local startX, startZ = a.x, a.z
					for step = 1, 12 do
						local x, z = a.x, a.z
						assert(battle:step(0.05, step * 0.05).ok, "Role motion step failed")
						local distance = math.sqrt((a.x - x) ^ 2 + (a.z - z) ^ 2)
						assert(
							finite(distance) and distance <= a.profile.speed * 0.05 + 0.0001,
							"Original movement exceeds researched speed"
						)
						local joints = {}
						-- Synthetic joint transforms test transport bounds; native fixtures certify authored anatomy.
						for _, name in Interpolation.jointNames do
							joints[name] = CFrame.new()
						end
						local packet = Codec.encode({
							time = step * 0.05,
							life = a.life,
							ground = 0,
							root = CFrame.new(a.x, 0.005, a.z),
							joints = joints,
							speed = if role == "mounted" then a.profile.speed else nil,
						})
						local decoded = Codec.decode(packet)
						assert(
							#packet <= 2048
								and decoded
								and decoded.life == a.life
								and (decoded.root.Position - Vector3.new(a.x, 0.005, a.z)).Magnitude < 0.0001,
							"Pose transport loses authoritative position/life"
						)
						assert(
							Interpolation.push(history, decoded) and #history.samples <= 8,
							"Pose history grows without bound"
						)
						packets += 1
					end
					assert((a.x - startX) ^ 2 + (a.z - startZ) ^ 2 > 0.01, "Actual original role never moved")
					local last = history.samples[#history.samples]
					assert(
						Interpolation.sample(history, 100).root == last.root,
						"Pose history extrapolates indefinitely"
					)
					assert(not Interpolation.push(history, history.samples[1]), "Stale pose accepted")
					behavior:destroy()
				end
			end
		end
		assert(packets == 1248, "Role/codec matrix omitted combinations")
	end)
	check("paid research completes through actual casualties without resetting pending replacement clocks", function()
		for _, role in { "melee", "ranged", "medic", "mounted" } do
			local battle = make(false)
			local slots = { slot("victim", role, 0, 0) }
			local progress = { completed = completed({ "army_training" }) }
			local state = { coins = 1000000, militaryResearch = progress }
			assert(ResearchClock.start(state, "field_bandages").ok, "Paid research could not start")
			assert(
				battle:syncArmy("owner", "sparta", "lane", slots, 0, progress.completed).ok,
				"Research victim sync failed"
			)
			local victim = actorFor(battle, "owner", "victim")
			victim.health = 1 -- Declared wounded fixture; all death/replacement transitions below are real Battle transitions.
			local observedDeath, observedReplacement, finished = false, false, false
			local previousLife = victim.life
			for step = 1, 1201 do
				local now = step * 0.05
				assert(battle:step(0.05, now).ok, "Research combat step rejected")
				if not victim.alive then
					observedDeath = true
				end
				if victim.life ~= previousLife then
					observedReplacement = true
				end
				local result = ResearchClock.step(state, 0.05, true)
				if result.completed then
					local life, hp, deadline, attack, contact =
						victim.life, victim.health, victim.respawnAt, victim.nextAttack, victim.contactAt
					assert(
						battle:syncArmy("owner", "sparta", "lane", slots, now, progress.completed).ok,
						"Research completion sync rejected"
					)
					assert(
						victim.life == life
							and victim.health == hp
							and victim.respawnAt == deadline
							and victim.nextAttack == attack
							and victim.contactAt == contact,
						"Research completion reset casualty continuity"
					)
					assert(
						victim.maxHealth == Research.profile(role, "sparta", progress.completed).health,
						"New max health not applied"
					)
					finished = true
				end
			end
			assert(
				observedDeath and observedReplacement and finished and state.coins == 990000,
				"Research casualty matrix missed real death/replacement or charged again"
			)
			assert(
				battle:syncArmy(
					"owner",
					"sparta",
					"lane",
					{ slots[1], slot("fresh", role, -80, 0) },
					61,
					progress.completed
				).ok,
				"New researched replacement rejected"
			)
			local fresh = actorFor(battle, "owner", "fresh")
			assert(fresh.health == fresh.maxHealth, "Fresh researched life is wounded")
		end
	end)
	print(string.format("Military stress duration: %.3fs", os.clock() - began))
	return count
end
return run

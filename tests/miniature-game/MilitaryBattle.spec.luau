--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Server = game:GetService("ServerScriptService").Sandbox
local Rules = require(Shared.MilitaryResearch)
local Config = require(Shared.BattleConfig)
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS military battle: " .. name)
	end
	local function near(a, b)
		return math.abs(a - b) < 0.0001
	end
	local function completed(ids)
		local result = {}
		local function add(id)
			if result[id] then
				return
			end
			local parent = Rules.nodes[id].predecessor
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
	local all = completed(Rules.order)
	local function rigFactory(actor)
		local attrs = {}
		local rig = { Name = actor.id }
		function rig:GetAttribute(key)
			return attrs[key]
		end
		function rig:SetAttribute(key, value)
			attrs[key] = value
		end
		function rig:Destroy()
			self.destroyed = true
		end
		return rig
	end
	local function make(original)
		local behavior = if original then Original.new({ rigFactory = rigFactory }) else nil
		local definitions = {
			{ id = "post", x = 0, z = 0, radius = 22, lineId = "line" },
			{ id = "other", x = 80, z = 0, radius = 22, lineId = "rival" },
		}
		local battle = Battle.new(definitions, { behavior = behavior })
		for _, a in battle.actors do
			a.health, a.alive, a.respawnAt = 0, false, 10000
		end
		return battle, behavior
	end
	local function slot(id, role, x, z)
		return { id = id, role = role, buildingId = "b-" .. id, index = 1, x = x or 0, z = z or 0 }
	end
	local function actor(battle, team, id)
		for _, a in battle.actors do
			if a.team == team and a.slotId == id then
				return a
			end
		end
		error("Military battle actor missing")
	end
	local function advance(battle, seconds, start, before)
		local now, events = start or 0, {}
		while seconds > 0.000001 do
			local dt = math.min(0.05, seconds)
			if before then
				before()
			end
			now += dt
			assert(battle:step(dt, now).ok, "Military battle clock rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			seconds -= dt
		end
		return now, events
	end
	check("additive profiles separate foot and mounted classes including species speed and medic coverage", function()
		local foot = Rules.profile("melee", "sparta", all)
		local mount = Rules.profile("mounted", "sparta", all)
		local medic = Rules.profile("medic", "sparta", all)
		assert(near(foot.health, 224) and near(foot.damage, 42) and near(foot.speed, 8.1), "Foot modifiers incorrect")
		assert(
			near(mount.health, 420) and near(mount.damage, 67.2) and near(mount.speed, 11.7),
			"Mounted modifiers doubled with foot bonuses"
		)
		assert(near(Rules.profile("mounted", "maurya", all).speed, 7.15), "Species baseline lost during research")
		assert(
			near(medic.health, 140) and near(medic.healRange, 9.45) and medic.heal == 12 and medic.damage == 0,
			"Medic coverage or nonoffensive role changed"
		)
		assert(
			Config.player.melee.health == 160 and Config.player.mounted.speed == 9 and table.isfrozen(mount),
			"Research mutated baseline profiles"
		)
	end)
	check("living research updates max health without healing cancelling contact or resetting clocks", function()
		local battle = make(false)
		local slots = { slot("one", "melee") }
		battle:syncArmy("A", "sparta", "line", slots, 0)
		local a = actor(battle, "A", "one")
		a.health, a.nextAttack, a.nextHeal, a.recoveryUntil, a.phase, a.contactAt = 80, 11, 12, 13, "windup", 14
		local life = a.life
		assert(battle:syncArmy("A", "sparta", "line", slots, 1, all).ok, "Research sync rejected")
		assert(a.life == life and a.health == 80 and near(a.maxHealth, 224), "Research healed or replaced current life")
		local profile = a.profile
		battle:syncArmy("A", "sparta", "line", slots, 1, table.clone(all))
		assert(a.profile == profile, "Unchanged research regenerated profiles on every controller sync")
		assert(
			a.nextAttack == 11
				and a.nextHeal == 12
				and a.recoveryUntil == 13
				and a.contactAt == 14
				and a.phase == "windup",
			"Research reset pending actions"
		)
		a.alive, a.health, a.respawnAt = false, 0, 10
		battle:syncArmy("A", "sparta", "line", slots, 2, all)
		assert(a.respawnAt == 10 and not a.alive and a.life == life, "Research reset pending replacement")
		advance(battle, 9.95)
		assert(not a.alive, "Research replacement arrived early")
		advance(battle, 0.05, 9.95)
		assert(a.alive and a.life ~= life and near(a.health, 224), "Fresh life did not receive researched health")
	end)
	check("weighted army capacity is derived per army and malformed research cannot partially replace it", function()
		local battle = make(false)
		local slots = {}
		for i = 1, 6 do
			table.insert(slots, slot("m" .. i, "mounted"))
		end
		assert(not battle:syncArmy("B", "rome", "line", slots, 0).ok, "Unresearched army exceeded ten")
		assert(
			battle:syncArmy("A", "sparta", "line", slots, 0, completed({ "army_size_1" })).ok,
			"Capacity twelve rejected six mounted"
		)
		assert(battle.armies.A.capacity == 12 and Config.troopCap == 10, "Army capacity changed a global constant")
		local old = actor(battle, "A", "m1")
		assert(
			not battle:syncArmy("A", "sparta", "line", {}, 1, { army_size_3 = true }).ok
				and battle.actors[old.id] == old,
			"Invalid research cleared existing army"
		)
		assert(
			not battle:syncArmy("A", "sparta", "line", slots, 1, {}).ok and old.alive,
			"Oversubscribed downgrade partially mutated army"
		)
	end)
	check("selective orders preserve unrelated troops and waiting structures receive their stored target", function()
		local battle = make(false)
		local one = slot("one", "melee")
		local options = { knownMilitaryBuildingIds = { "b-one", "b-wait" }, buildingTargets = {} }
		battle:syncArmy("A", "sparta", "line", { one }, 0, {}, options)
		assert(battle:command("A", "other", { "b-wait" }).ok, "Known waiting structure could not receive order")
		assert(actor(battle, "A", "one").targetOutpostId == "post", "Selective order redirected unrelated group")
		local two = slot("wait", "mounted")
		battle:syncArmy("A", "sparta", "line", { one, two }, 1)
		assert(actor(battle, "A", "wait").targetOutpostId == "other", "Waiting structure lost order upon allocation")
		assert(
			not battle:command("A", "post", { "foreign" }).ok and actor(battle, "A", "wait").targetOutpostId == "other",
			"Invalid group mutated orders"
		)
		assert(
			battle:command("A", "post").ok and next(battle.armies.A.buildingTargets) == nil,
			"Army one did not clear overrides"
		)
		assert(actor(battle, "A", "wait").targetOutpostId == "post", "Army one did not redirect every group")
		battle:syncArmy(
			"A",
			"sparta",
			"line",
			{ one },
			2,
			{},
			{ knownMilitaryBuildingIds = { "b-one" }, buildingTargets = { ["b-wait"] = "other" } }
		)
		assert(next(battle.armies.A.buildingTargets) == nil, "Reclaimed override survived canonical known list")
	end)
	check(
		"original melee contact uses researched effective reach without doubling the old one point two five baseline",
		function()
			for _, role in { "melee", "mounted" } do
				local battle, behavior = make(true)
				battle:syncArmy("A", "sparta", "line", { slot("one", role) }, 0, all)
				battle:syncArmy("B", "rome", "line", { slot("foe", "medic", 1.5) }, 0)
				local a, b = actor(battle, "A", "one"), actor(battle, "B", "foe")
				local _, events = advance(battle, 0.35, 0, function()
					b.x, b.z = a.x + 1.5, a.z
				end)
				local hit = false
				for _, event in events do
					if event.kind == "hit" and event.actorId == a.id then
						hit = true
						assert(event.targetX - event.x > 1.25, "Contact test did not exercise extended original reach")
					end
				end
				assert(hit and behavior.metrics.encounterAdvances > 0, "Original contact ignored research reach")
				behavior:destroy()
			end
			local battle, behavior = make(true)
			battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
			battle:syncArmy("B", "rome", "line", { slot("foe", "medic", 1.5) }, 0)
			advance(battle, 0.05)
			assert(
				actor(battle, "A", "one").combatPhase ~= "windup",
				"Unresearched original melee reach silently doubled"
			)
			behavior:destroy()
		end
	)
	check("original ranged planner releases beyond the old ten-stud limit with delayed validated damage", function()
		local battle, behavior = make(true)
		battle:syncArmy("A", "sparta", "line", { slot("bow", "ranged") }, 0, all)
		battle:syncArmy("B", "rome", "line", { slot("foe", "medic", 11.2) }, 0)
		local a, b = actor(battle, "A", "bow"), actor(battle, "B", "foe")
		local _, events = advance(battle, 1, 0, function()
			b.x, b.z = 11.2, 0
		end)
		local shot, hit
		for _, event in events do
			if event.actorId == a.id and event.kind == "shot" then
				shot = event
			end
			if event.actorId == a.id and event.kind == "hit" then
				hit = event
			end
		end
		assert(
			shot and hit and shot.targetX - shot.x > 10 and hit.time > shot.time,
			"Research ranged planner/release/contact still clamped to old range"
		)
		behavior:destroy()
	end)
	check("original medical service heals across researched foot coverage beyond seven studs", function()
		local battle, behavior = make(true)
		battle:syncArmy(
			"A",
			"sparta",
			"line",
			{ slot("patient", "melee", -4.4, -3), slot("medic", "medic", -12.7, -3) },
			0,
			all
		)
		local patient = actor(battle, "A", "patient")
		patient.health = 100
		local _, events = advance(battle, 1.5)
		local bandage
		for _, event in events do
			if event.kind == "bandage" then
				bandage = event
				break
			end
		end
		assert(
			bandage and math.sqrt((bandage.targetX - bandage.x) ^ 2 + (bandage.targetZ - bandage.z) ^ 2) > 7,
			"Medical launch did not use researched coverage"
		)
		assert(
			patient.health > 100 and behavior.metrics.bandageThrows > 0,
			"Original medical contact ignored researched range"
		)
		behavior:destroy()
	end)
	check("research completed during a ranged flight does not extend that already launched projectile", function()
		local battle, behavior = make(true)
		local slots = { slot("bow", "ranged") }
		battle:syncArmy("A", "sparta", "line", slots, 0)
		battle:syncArmy("B", "rome", "line", { slot("foe", "medic", 8) }, 0)
		local foe = actor(battle, "B", "foe")
		advance(battle, 0.4, 0, function()
			foe.x, foe.z = 8, 0
		end)
		assert(behavior.metrics.projectileReleases == 1, "Flight fixture did not release initial shot")
		battle:syncArmy("A", "sparta", "line", slots, 0.4, all)
		advance(battle, 0.8, 0.4, function()
			foe.x, foe.z = 11, 0
		end)
		assert(
			behavior.metrics.projectileHits == 0 and foe.health == 100,
			"Research extended an in-flight projectile's launch reach"
		)
		behavior:destroy()
	end)
	return count
end
return run

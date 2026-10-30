--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.BattleConfig)
local Tuning = require(game:GetService("ReplicatedStorage").Shared.TacticalCombatConfig)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature original behavior: " .. name)
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
	local function make(visible)
		local behavior = Original.new({ rigFactory = rigFactory })
		local battle = Battle.new(
			{ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } },
			{ behavior = behavior, visible = visible }
		)
		for _, actor in battle.actors do
			actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 1000000
		end
		return battle, behavior
	end
	local function slot(id, role, x, z)
		return { id = id, role = role, buildingId = "b-" .. id, index = 1, x = x or 0, z = z or 0 }
	end
	local function actorFor(battle, team, id)
		for _, actor in battle.actors do
			if actor.team == team and actor.slotId == id then
				return actor
			end
		end
		error("Original behavior fixture actor missing")
	end
	local function advance(battle, seconds, start)
		local now, remaining, events = start or 0, seconds, {}
		while remaining > 0.0000001 do
			local dt = math.min(0.05, remaining)
			now += dt
			assert(battle:step(dt, now).ok, "Original behavior step rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			remaining -= dt
		end
		return now, events
	end
	check("unchanged original encounter owns windup contact recovery and one-hit cadence", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "melee", 1) }, 0)
		advance(battle, 0.05)
		local actor = actorFor(battle, "A", "one")
		assert(
			actor.combatPhase == "windup" and actor.phaseDuration == Tuning.phases.warrior.windup,
			"Original windup metadata not reused"
		)
		advance(battle, 0.14, 0.05)
		assert(actorFor(battle, "B", "one").health == 160, "Original windup hit early")
		advance(battle, 0.11, 0.19)
		assert(actorFor(battle, "B", "one").health == 130, "Original contact did not apply one battle-owned hit")
		assert(
			actor.combatPhase == "contact" and actor.phaseDuration == Tuning.phases.warrior.contact,
			"Original contact metadata missing"
		)
		advance(battle, 0.45, 0.3)
		assert(actorFor(battle, "B", "one").health == 130, "Original contact repeated during recovery")
		assert(
			behavior.metrics.encounterPlans > 0 and behavior.metrics.encounterAdvances > 0,
			"Original encounter was not invoked"
		)
		behavior:destroy()
	end)
	check("original crowd movement preserves owned pace and the slight neutral movement disadvantage", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee", -80), slot("two", "ranged", -80, 2) }, 0)
		local first = actorFor(battle, "A", "one")
		advance(battle, 1)
		local traveled = math.sqrt((first.x + 80) ^ 2 + first.z ^ 2)
		assert(traveled > 4.5 and traveled <= 6.0001, "Original marching speed failed the requested six-stud cap")
		assert(behavior.metrics.crowdPlans > 0, "Original CrowdMovement was not used")
		assert(
			math.abs(Config.neutral.melee.speed - 5.7) < 0.0001 and math.abs(Config.neutral.ranged.speed - 5.7) < 0.0001,
			"Neutral speed differs from ninety-five percent of owned pace"
		)
		behavior:destroy()
	end)
	check("original ranged release uses a finite projectile and the halved ten-stud range", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("one", "ranged") }, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "medic", 8) }, 0)
		local _, events = advance(battle, 1.5)
		local shot, hit
		for _, event in events do
			if event.team == "A" and event.kind == "shot" then
				shot = shot or event
				assert(
					math.sqrt((event.x - event.targetX) ^ 2 + (event.z - event.targetZ) ^ 2) <= 10.0001,
					"Ranged fired beyond the requested hard cap"
				)
			elseif event.team == "A" and event.kind == "hit" then
				hit = hit or event
			end
		end
		assert(shot and hit and hit.time > shot.time, "Ranged damage bypassed finite projectile flight")
		assert(
			behavior.metrics.projectileReleases > 0 and behavior.metrics.projectileHits > 0,
			"Original release callback or projectile validation unused"
		)
		assert(Config.player.ranged.reach == 10 and Config.neutral.ranged.reach == 10, "Halved ranged limits changed")
		behavior:destroy()
	end)
	check(
		"original medical planner and bandage service retain twelve-HP three-second cadence under seven-stud reach",
		function()
			local battle, behavior = make()
			battle:syncArmy("A", "sparta", "line", { slot("fighter", "melee", 6), slot("medic", "medic") }, 0)
			local patient = actorFor(battle, "A", "fighter")
			patient.health = 50
			local _, events = advance(battle, 2)
			assert(patient.health == 62, "Original medical bandage amount or owner cooldown changed")
			assert(
				behavior.metrics.medicPlans > 0 and behavior.metrics.bandageThrows == 1,
				"Original medic planner/service were not reused"
			)
			assert(
				actorFor(battle, "A", "medic").bandageThrownAt ~= nil and Config.player.medic.healRange == 7,
				"Original bandage metadata or hard range missing"
			)
			assert(behavior.metrics.recoveryPlans > 0, "Original MedicalRetreat was not consulted for fighters")
			local launched, healed
			for _, event in events do
				if event.kind == "bandage" then
					launched = event
				elseif event.kind == "heal" then
					healed = event
				end
			end
			assert(
				launched
					and healed
					and launched.targetId == patient.id
					and launched.targetLife == patient.life
					and launched.time < healed.time,
				"Original bandage lacked a life-tagged visual launch before authoritative healing"
			)
			behavior:destroy()
		end
	)
	check("original pending contacts cannot redirect onto a replacement life and repeated sync never heals", function()
		local battle, behavior = make()
		local slots = { slot("one", "melee") }
		battle:syncArmy("A", "sparta", "line", slots, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "melee", 1) }, 0)
		advance(battle, 0.05)
		local first = actorFor(battle, "A", "one")
		first.health = 73
		battle:syncArmy("A", "sparta", "line", slots, 0.05)
		assert(first.health == 73, "Sync reset original actor health")
		local old = actorFor(battle, "B", "one").life
		battle:removeArmy("B")
		battle:syncArmy("B", "rome", "line", { slot("one", "melee", 1) }, 0.05)
		advance(battle, 0.25, 0.05)
		local target = actorFor(battle, "B", "one")
		assert(target.life ~= old and target.health == target.maxHealth, "Old original contact hit a replacement life")
		behavior:destroy()
	end)
	check("original behavior remains outpost-only and capture still requires twenty clear seconds", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("one", "medic") }, 0)
		advance(battle, 19.95)
		assert(battle.outposts.post.ownerTeam == nil, "Original adapter bypassed twenty-second capture")
		advance(battle, 0.05, 19.95)
		assert(battle.outposts.post.ownerTeam == "A", "Original movement prevented valid occupation")
		behavior:destroy()
	end)
	check("numeric original releases cannot hit through new obstructions or a replacement life", function()
		for _, replace in { false, true } do
			local clear = true
			local battle, behavior = make(function()
				return clear
			end)
			battle:syncArmy("A", "sparta", "line", { slot("one", "ranged") }, 0)
			battle:syncArmy("B", "rome", "line", { slot("one", "medic", 8) }, 0)
			local now, shotAt = 0, nil
			while now < 1 and shotAt == nil do
				now = advance(battle, 0.05, now)
				for _, event in battle.events do
					if event.kind == "shot" and event.team == "A" then
						shotAt = now
					end
				end
			end
			assert(shotAt ~= nil, "Projectile interruption fixture never released")
			local victim = actorFor(battle, "B", "one")
			assert(victim.health == victim.maxHealth, "Projectile arrived without travel time")
			if replace then
				local life = victim.life
				battle:removeArmy("B")
				battle:syncArmy("B", "rome", "line", { slot("one", "medic", 8) }, now)
				victim = actorFor(battle, "B", "one")
				assert(victim.life ~= life, "Projectile fixture reused target life")
			else
				clear = false
			end
			advance(battle, 0.7, now)
			assert(victim.health == victim.maxHealth, "Old projectile hit an obstructed or replaced target")
			behavior:destroy()
		end
	end)
	check("seven-stud medical reach rejects out-of-range patients until a valid bandage can be thrown", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("fighter", "melee", 8), slot("medic", "medic") }, 0)
		local patient, medic = actorFor(battle, "A", "fighter"), actorFor(battle, "A", "medic")
		patient.health = 50
		local now = 0
		-- Pin the test positions outside seven studs before each slice. Both
		-- original movement plans may advance, but cannot close the gap in .05s.
		for _ = 1, 20 do
			patient.x, patient.z, medic.x, medic.z = 8, 0, 0, 0
			now = advance(battle, 0.05, now)
		end
		assert(
			patient.health == 50 and behavior.metrics.bandageThrows == 0,
			"Medical service silently kept the old larger reach"
		)
		patient.x, patient.z = 6, 0
		advance(battle, 1, now)
		assert(patient.health == 62 and behavior.metrics.bandageThrows == 1, "In-range original medical flight failed")
		behavior:destroy()
	end)
	check("a legitimate nine-troop original army captures near-equal neutral defenders", function()
		local behavior = Original.new({ rigFactory = rigFactory })
		local battle = Battle.new(
			{ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } },
			{ behavior = behavior }
		)
		battle:syncArmy("A", "sparta", "line", {
			slot("one", "melee", -20, -1),
			slot("two", "melee", -20, 1),
			slot("bow-one", "ranged", -24, -1),
			slot("bow-two", "ranged", -24, 1),
			slot("third", "melee", -20, -3),
			slot("fourth", "melee", -20, 3),
			slot("bow-third", "ranged", -24, -3),
			slot("bow-fourth", "ranged", -24, 3),
			slot("medic", "medic", -27, 0),
		}, 0)
		advance(battle, 120)
		assert(battle.outposts.post.ownerTeam == "A", "Original tactics could not complete the initial outpost battle")
		local total = 0
		for _, actor in battle.actors do
			if actor.team == "A" then
				total += 1
			end
		end
		assert(total == 9, "Original adapter created extra combat slots")
		behavior:destroy()
	end)
	check("sandbox range wrappers preserve immutable original configuration values", function()
		local replicated = game:GetService("ReplicatedStorage")
		local originalRanged = require(replicated.OriginalArmyConfig.RangedConfig)
		local originalMedical = require(replicated.OriginalArmyConfig.MedicalConfig)
		local sandboxRanged = require(replicated.Shared.RangedConfig)
		local sandboxMedical = require(replicated.Shared.MedicalConfig)
		assert(
			originalRanged.range == 45 and originalMedical.range == 45 and originalMedical.recoveryDistance == 40,
			"Sandbox mutated original configuration"
		)
		assert(
			sandboxRanged.range == 40 and sandboxMedical.range == 28 and sandboxMedical.recoveryDistance == 24,
			"Sandbox range wrapper limits differ from requested quarter-scale caps"
		)
		assert(
			originalRanged ~= sandboxRanged and originalMedical ~= sandboxMedical,
			"Sandbox reused original configuration tables for overrides"
		)
		assert(
			table.isfrozen(originalRanged)
				and table.isfrozen(originalMedical)
				and table.isfrozen(sandboxRanged)
				and table.isfrozen(sandboxMedical),
			"Original or sandbox configuration became mutable"
		)
	end)
	return count
end

return run

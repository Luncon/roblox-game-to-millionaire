--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)
local Stats = require(Shared.BattleConfig)
local Warrior = require(game:GetService("ReplicatedStorage").Shared.WarriorConfig)
local Tuning = require(game:GetService("ReplicatedStorage").Shared.TacticalCombatConfig)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature mounted original: " .. name)
	end
	local function make(neutrals)
		local identities = {}
		local behavior = Original.new({
			rigFactory = function(actor)
				local attributes = {}
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
				identities[actor.id] = rig
				return rig
			end,
		})
		local battle = Battle.new(
			{ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } },
			{ behavior = behavior }
		)
		if not neutrals then
			for _, actor in battle.actors do
				actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 1000000
			end
		end
		return battle, behavior, identities
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
		error("Mounted actor not registered")
	end
	local function advance(battle, seconds, start)
		local now, events = start or 0, {}
		while seconds > 0.000001 do
			local dt = math.min(0.05, seconds)
			now += dt
			assert(battle:step(dt, now).ok, "Mounted fixture time rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			seconds -= dt
		end
		return now, events
	end
	check(
		"mounted maps to exact original warrior phases while its numeric identity and stronger hit remain mounted",
		function()
			local battle, behavior, identities = make()
			assert(battle:syncArmy("A", "sparta", "line", { slot("rider", "mounted") }, 0).ok, "Mounted sync failed")
			assert(battle:syncArmy("B", "rome", "line", { slot("foe", "melee", 1) }, 0).ok, "Target sync failed")
			local _, windupEvents = advance(battle, 0.05)
			local rider, foe = actorFor(battle, "A", "rider"), actorFor(battle, "B", "foe")
			local attackCues = 0
			for _, event in windupEvents do
				if event.kind == "attack" and event.actorId == rider.id then
					attackCues += 1
					assert(
						event.actorLife == rider.life and event.targetId == foe.id,
						"Mounted attack cue lost its current life or target"
					)
				end
			end
			assert(attackCues == 1, "Mounted original windup must emit exactly one attack cue")
			assert(
				rider.role == "mounted" and identities[rider.id]:GetAttribute("WarriorClass") == "warrior",
				"Mounted changed identity or bypassed original warrior proxy"
			)
			assert(
				rider.combatPhase == "windup" and rider.phaseDuration == Tuning.phases.warrior.windup,
				"Mounted invented an attack phase"
			)
			local _, ongoingWindup = advance(battle, 0.14, 0.05)
			for _, event in ongoingWindup do
				assert(
					event.kind ~= "attack" or event.actorId ~= rider.id,
					"Mounted attack cue repeated within the same windup"
				)
			end
			assert(foe.health == 160, "Mounted hit before original windup")
			local _, events = advance(battle, 0.91, 0.19)
			local hits = 0
			for _, event in events do
				if event.kind == "hit" and event.actorId == rider.id then
					hits += 1
					assert(event.amount == 48, "Mounted did not apply server profile damage")
				end
			end
			assert(
				hits == 1 and foe.health == 112 and rider.maxHealth == 300,
				"Mounted original contact repeated or used foot stats"
			)
			assert(
				Stats.player.mounted.reach == Stats.player.melee.reach
					and Stats.player.mounted.cooldown == Stats.player.melee.cooldown
					and Stats.player.mounted.windup == Stats.player.melee.windup,
				"Mounted introduced independent reach/cadence"
			)
			assert(
				Warrior.attackRange == 5 and Warrior.attackCooldown == 1,
				"Mounted mutated original warrior configuration"
			)
			assert(
				behavior.metrics.encounterPlans > 0 and behavior.metrics.encounterAdvances > 0,
				"Mounted bypassed original encounter"
			)
			behavior:destroy()
		end
	)
	check("original mounted march travels nine studs per second without gaining attack reach", function()
		local battle, behavior = make()
		battle:syncArmy("A", "sparta", "line", { slot("rider", "mounted", -60) }, 0)
		local rider = actorFor(battle, "A", "rider")
		advance(battle, 1)
		local distance = math.sqrt((rider.x + 60) ^ 2 + rider.z ^ 2)
		assert(
			math.abs(distance - 9) < 0.0001 and behavior.metrics.crowdPlans > 0,
			"Mounted movement did not use original crowd at requested speed"
		)
		behavior:destroy()
	end)
	check(
		"mounted current life receives original medic bandages and sync preserves health and pending respawn",
		function()
			local battle, behavior = make()
			local slots = { slot("rider", "mounted", -4.4, -3), slot("medic", "medic", -4.4, 1) }
			battle:syncArmy("A", "sparta", "line", slots, 0)
			local rider = actorFor(battle, "A", "rider")
			rider.health = 200
			advance(battle, 2)
			assert(
				rider.health == 212 and behavior.metrics.bandageThrows == 1,
				"Mounted not treated as original friendly warrior patient"
			)
			local life = rider.life
			battle:syncArmy("A", "sparta", "line", slots, 2)
			assert(rider.health == 212 and rider.life == life, "Same mounted slot sync refilled life or health")
			rider.health, rider.alive, rider.phase, rider.respawnAt = 0, false, "dead", 12
			battle:syncArmy("A", "sparta", "line", slots, 3)
			assert(
				rider.respawnAt == 12 and rider.life == life and rider.health == 0,
				"Mounted sync reset pending deadline"
			)
			advance(battle, 9.9, 2)
			assert(not rider.alive, "Mounted respawned before existing deadline")
			advance(battle, 0.1, 11.9)
			assert(
				rider.alive and rider.life ~= life and rider.health == 300,
				"Mounted current life did not respawn through ordinary lifecycle"
			)
			behavior:destroy()
		end
	)
	check(
		"mixed capacity-nine mounted army captures through unchanged original combat and twenty clear seconds",
		function()
			local battle, behavior = make(true)
			local slots = {
				slot("rider1", "mounted", -20, -3),
				slot("rider2", "mounted", -20, 3),
				slot("foot1", "melee", -22, -1),
				slot("foot2", "melee", -22, 1),
				slot("bow1", "ranged", -24, -2),
				slot("bow2", "ranged", -24, 2),
				slot("medic", "medic", -26),
			}
			assert(battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Mixed mounted weighted army rejected")
			advance(battle, 120)
			assert(battle.outposts.post.ownerTeam == "A", "Mixed mounted original army never completed capture")
			local countActors, used = 0, 0
			for _, actor in battle.actors do
				if actor.team == "A" then
					countActors += 1
					used += if actor.role == "mounted" then 2 else 1
				end
			end
			assert(
				countActors == 7 and used == 9 and behavior.metrics.encounterAdvances > 0,
				"Mounted capture grew military capacity or bypassed original behavior"
			)
			behavior:destroy()
		end
	)
	return count
end
return run

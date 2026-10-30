--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)
local Stats = require(Shared.BattleConfig)
local Settings = require(Shared.Config)
local Warrior = require(game:GetService("ReplicatedStorage").Shared.WarriorConfig)
local Ranged = require(game:GetService("ReplicatedStorage").Shared.RangedConfig)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature neutral balance: " .. name)
	end
	local function near(first, second)
		return math.abs(first - second) < 0.0001
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
	local function make(role)
		local behavior = Original.new({ rigFactory = rigFactory })
		local battle = Battle.new(
			{ { id = "post", x = 0, z = 0, radius = 80, lineId = "line" } },
			{ behavior = behavior }
		)
		local selected
		for _, actor in battle.actors do
			if actor.role == role and selected == nil then
				selected = actor
			else
				actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 1000000
			end
		end
		assert(selected, "Neutral balance fixture role missing")
		selected.x, selected.z, selected.homeX, selected.homeZ = 0, 0, 0, 0
		return battle, behavior, selected
	end
	local function slot(role, x, z)
		return { id = "player", role = role, buildingId = "b-player", index = 1, x = x, z = z or 0 }
	end
	local function player(battle)
		for _, actor in battle.actors do
			if actor.team == "A" then
				return actor
			end
		end
		error("Balance fixture player missing")
	end
	local function advance(battle, seconds, start)
		local now, remaining, events = start or 0, seconds, {}
		while remaining > 0.0000001 do
			local dt = math.min(0.05, remaining)
			now += dt
			assert(battle:step(dt, now).ok, "Balance fixture time rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			remaining -= dt
		end
		return now, events
	end
	check("neutral role profiles differ only by five percent health damage and movement", function()
		for role, owned in Stats.player do
			local neutral = Stats.neutral[role]
			for field, value in owned do
				local expected = if field == "health"
						or field == "damage"
						or field == "speed"
					then value * 0.95
					else value
				assert(
					near(neutral[field], expected),
					"Neutral has an extra role disadvantage: " .. role .. "." .. field
				)
			end
		end
		assert(
			near(Settings.neutralTroopSpeed, Settings.playerTroopSpeed * 0.95)
				and Settings.neutralRangedReach == Settings.rangedReach,
			"Public balance settings drifted from actual profiles"
		)
	end)
	check("injected original melee applies ninety-five percent damage with the same contact cadence", function()
		local battle, behavior, neutral = make("melee")
		battle:syncArmy("A", "sparta", "line", { slot("melee", 1) }, 0)
		local owned = player(battle)
		assert(near(neutral.maxHealth, owned.maxHealth * 0.95), "Original adapter received old weak neutral health")
		local _, events = advance(battle, 2.6)
		local neutralHits, ownedHits = {}, {}
		for _, event in events do
			if event.kind == "hit" then
				if event.actorId == neutral.id then
					table.insert(neutralHits, event)
					assert(
						near(event.amount, Stats.player.melee.damage * 0.95),
						"Original neutral melee damage ratio changed"
					)
				elseif event.actorId == owned.id then
					table.insert(ownedHits, event)
				end
			end
		end
		assert(
			#neutralHits >= 2 and #neutralHits == #ownedHits,
			"Original adapter retained an extra neutral cadence penalty"
		)
		for index = 2, #neutralHits do
			assert(
				near(
					neutralHits[index].time - neutralHits[index - 1].time,
					ownedHits[index].time - ownedHits[index - 1].time
				),
				"Original melee cadences diverged"
			)
			assert(
				neutralHits[index].time - neutralHits[index - 1].time >= Warrior.attackCooldown - 0.0001,
				"Neutral bypassed original contact cooldown"
			)
		end
		behavior:destroy()
	end)
	check("injected original ranged uses equal reach release cadence and five-percent-lower impact", function()
		local battle, behavior, neutral = make("ranged")
		battle:syncArmy("A", "sparta", "line", { slot("ranged", 8) }, 0)
		local owned = player(battle)
		local _, events = advance(battle, 4.8)
		local neutralShots, ownedShots = {}, {}
		local impacted = false
		for _, event in events do
			if event.kind == "shot" then
				if event.actorId == neutral.id then
					table.insert(neutralShots, event)
				elseif event.actorId == owned.id then
					table.insert(ownedShots, event)
				end
			elseif event.kind == "hit" and event.actorId == neutral.id then
				impacted = true
				assert(
					near(event.amount, Stats.player.ranged.damage * 0.95),
					"Original neutral projectile damage not ninety-five percent"
				)
			end
		end
		assert(
			impacted and #neutralShots >= 2 and #neutralShots == #ownedShots,
			"Original ranged release path kept a neutral handicap"
		)
		assert(Stats.neutral.ranged.reach == Stats.player.ranged.reach, "Neutral ranged reach differs")
		assert(
			near(neutralShots[2].time - neutralShots[1].time, ownedShots[2].time - ownedShots[1].time)
				and neutralShots[2].time - neutralShots[1].time >= Ranged.attackCooldown - 0.0001,
			"Original ranged cadences diverged"
		)
		assert(behavior.metrics.projectileHits > 0, "Balance test bypassed the actual original projectile bridge")
		behavior:destroy()
	end)
	check("injected original movement carries neutral troops at ninety-five percent player pace", function()
		local battle, behavior, neutral = make("melee")
		neutral.x = -50
		battle:syncArmy("A", "sparta", "line", { slot("melee", 50) }, 0)
		local owned = player(battle)
		advance(battle, 1)
		local neutralDistance = math.sqrt((neutral.x + 50) ^ 2 + neutral.z ^ 2)
		local ownedDistance = math.sqrt((owned.x - 50) ^ 2 + owned.z ^ 2)
		assert(
			near(ownedDistance, 6) and near(neutralDistance, 5.7) and near(neutralDistance / ownedDistance, 0.95),
			"Original movement bridge applied another neutral slowdown"
		)
		assert(behavior.metrics.crowdPlans > 0, "Balance movement bypassed original crowd steering")
		behavior:destroy()
	end)
	return count
end

return run

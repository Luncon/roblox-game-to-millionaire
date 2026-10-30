--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Server = game:GetService("ServerScriptService").Sandbox
local Mounts = require(Shared.MountConfig)
local Stats = require(Shared.BattleConfig)
local Battle = require(Server.Battle)
local Original = require(Server.OriginalBehavior)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature mounted species: " .. name)
	end
	local function near(a, b): boolean
		return math.abs(a - b) < 0.0001
	end
	local function rigFactory(actor)
		local attributes = {}
		local rig = { Name = actor.id }
		function rig:SetAttribute(key, value)
			attributes[key] = value
		end
		function rig:GetAttribute(key)
			return attributes[key]
		end
		function rig:Destroy()
			self.destroyed = true
		end
		return rig
	end
	local function make(useOriginal)
		local behavior = if useOriginal then Original.new({ rigFactory = rigFactory }) else nil
		local battle = Battle.new(
			{ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } },
			{ behavior = behavior }
		)
		for _, actor in battle.actors do
			actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 1000000
		end
		return battle, behavior
	end
	local function slots(role)
		return { { id = "one", role = role, buildingId = "b4", index = 1, x = -60, z = 0 } }
	end
	local function owned(battle)
		for _, actor in battle.actors do
			if actor.team == "A" then
				return actor
			end
		end
		error("Species fixture actor missing")
	end
	local function advance(battle, seconds, start)
		local now = start or 0
		while seconds > 0.000001 do
			local dt = math.min(0.05, seconds)
			now += dt
			assert(battle:step(dt, now).ok, "Species fixture time rejected")
			seconds -= dt
		end
		return now
	end
	check("configured elephant and camel pace and elk bear proportions are immutable", function()
		for civilization, definition in Mounts.definitions do
			local expected = if civilization == "maurya" or civilization == "ottomans" then 5.5 else 9
			assert(definition.speed == expected, "Wrong configured species pace: " .. civilization)
			assert(table.isfrozen(definition), "Species configuration became mutable")
		end
		assert(
			Mounts.get("seneca").bodyLength == 2.9 and Mounts.get("vikings").bodyLength == 3.25,
			"Chosen elk/bear lengths missing"
		)
	end)
	check("shared profile lookup preserves foot fallbacks and only changes mounted speed by civilization", function()
		for _, civilization in { "maurya", "ottomans", "sparta", "unknown" } do
			for _, role in { "melee", "ranged", "medic" } do
				assert(
					Stats.getProfile(role, civilization) == Stats.player[role],
					"Species lookup cloned or changed ordinary troop profile"
				)
				assert(
					Stats.getProfile(role, civilization, true) == Stats.neutral[role],
					"Species lookup changed neutral foot profile"
				)
			end
		end
		for civilization, definition in Mounts.definitions do
			local profile = Stats.getProfile("mounted", civilization)
			local neutral = Stats.getProfile("mounted", civilization, true)
			assert(
				profile.speed == definition.speed and table.isfrozen(profile) and table.isfrozen(neutral),
				"Species profile not frozen or coherent"
			)
			for field, baseline in Stats.player.mounted do
				if field ~= "speed" then
					assert(profile[field] == baseline, "Species speed changed mounted " .. field)
				end
				local expected = profile[field]
					* (if field == "speed" or field == "health" or field == "damage" then 0.95 else 1)
				assert(near(neutral[field], expected), "Species neutral ratio changed: " .. field)
			end
		end
		assert(
			Stats.getProfile("mounted", "unknown") == Stats.player.mounted and Stats.player.mounted.speed == 9,
			"Fallback or global mounted profile mutated"
		)
	end)
	check("pure Battle kernel applies species pace without changing baseline combat stats", function()
		for _, civilization in { "maurya", "ottomans", "sparta" } do
			local battle = make(false)
			assert(battle:syncArmy("A", civilization, "line", slots("mounted"), 0).ok, "Species army rejected")
			local rider = owned(battle)
			advance(battle, 1)
			local traveled = math.sqrt((rider.x + 60) ^ 2 + rider.z ^ 2)
			assert(near(traveled, Mounts.get(civilization).speed), "Kernel ignored species speed: " .. civilization)
			assert(rider.maxHealth == 300 and rider.health == 300, "Species changed mounted health")
		end
	end)
	check("actual original adapter marches slow species at five point five and ordinary troops at six", function()
		for _, case in
			{
				{ "maurya", "mounted", 5.5 },
				{ "ottomans", "mounted", 5.5 },
				{ "sparta", "mounted", 9 },
				{ "maurya", "melee", 6 },
				{ "ottomans", "ranged", 6 },
			}
		do
			local battle, behavior = make(true)
			battle:syncArmy("A", case[1], "line", slots(case[2]), 0)
			local actor = owned(battle)
			advance(battle, 1)
			local traveled = math.sqrt((actor.x + 60) ^ 2 + actor.z ^ 2)
			assert(
				near(traveled, case[3]) and behavior.metrics.crowdPlans > 0,
				"Original adapter ignored shared species profile: " .. case[1] .. "/" .. case[2]
			)
			behavior:destroy()
		end
	end)
	check("slow species synchronization preserves wounded lives and existing respawn deadlines", function()
		for _, civilization in { "maurya", "ottomans" } do
			local battle, behavior = make(true)
			local armySlots = slots("mounted")
			battle:syncArmy("A", civilization, "line", armySlots, 0)
			local actor = owned(battle)
			advance(battle, 1)
			actor.health = 271
			local life, x, z = actor.life, actor.x, actor.z
			battle:syncArmy("A", civilization, "line", armySlots, 1)
			assert(
				actor.life == life and actor.health == 271 and actor.x == x and actor.z == z,
				"Species sync reset living state"
			)
			actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 11
			battle:syncArmy("A", civilization, "line", armySlots, 1.1)
			assert(actor.respawnAt == 11 and actor.life == life, "Species sync reset pending deadline")
			advance(battle, 9.95, 1)
			assert(not actor.alive and actor.life == life, "Species respawned early")
			advance(battle, 0.05, 10.95)
			assert(
				actor.alive and actor.life ~= life and actor.health == 300,
				"Species replacement did not retain ordinary life semantics"
			)
			behavior:destroy()
		end
	end)
	return count
end
return run

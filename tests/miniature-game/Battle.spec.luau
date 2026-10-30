--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Battle = require(Server.Battle)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.BattleConfig)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature battle: " .. name)
	end
	local function make(options)
		return Battle.new({ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } }, options)
	end
	local function slot(id, role, x, z)
		return { id = id, role = role, buildingId = "building-" .. id, index = 1, x = x or 0, z = z or 0 }
	end
	local function actorFor(battle, team, id)
		for _, actor in battle.actors do
			if actor.team == team and actor.slotId == id then
				return actor
			end
		end
		error("Test army actor missing")
	end
	local function clearNeutral(battle, respawnAt)
		-- Isolate capture timing; real combat and natural deaths are tested below.
		for _, actor in battle.actors do
			if actor.team == "neutral:post" then
				actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", respawnAt or 1000000
			end
		end
	end
	local function advance(battle, seconds, start)
		local now, remaining, events = start or 0, seconds, {}
		while remaining > 0.0000001 do
			local dt = math.min(0.05, remaining)
			now += dt
			assert(battle:step(dt, now).ok, "Valid battle time was rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			remaining -= dt
		end
		return now, events
	end
	check("outposts begin with exactly two neutral melee and one ranged defender", function()
		local battle = make()
		local melee, ranged = 0, 0
		for _, actor in battle.actors do
			assert(
				actor.team == "neutral:post" and actor.alive and actor.health == actor.maxHealth,
				"Neutral initial life invalid"
			)
			if actor.role == "melee" then
				melee += 1
			elseif actor.role == "ranged" then
				ranged += 1
			end
		end
		assert(melee == 2 and ranged == 1 and battle.outposts.post.ownerTeam == nil, "Wrong neutral defense")
		assert(battle:step(0, 0).ok and #battle.events == 0, "Initial visual step was not a no-op")
	end)
	check("stable army sync preserves health life pending contacts and dead-slot respawn deadlines", function()
		local battle = make()
		local slots = { slot("one", "melee", -60), slot("two", "ranged", -60, 2) }
		assert(battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Army sync failed")
		local first, second = actorFor(battle, "A", "one"), actorFor(battle, "A", "two")
		first.health, first.phase, first.contactAt = 73, "windup", 3
		second.health, second.alive, second.phase, second.respawnAt = 0, false, "dead", 10
		local firstLife, secondLife = first.life, second.life
		slots[1].x = -80
		assert(battle:syncArmy("A", "sparta", "line", slots, 2).ok, "Repeat sync failed")
		assert(
			first.health == 73 and first.life == firstLife and first.contactAt == 3 and first.x == -60,
			"Sync healed teleported or reset a living slot"
		)
		assert(
			second.respawnAt == 10 and second.life == secondLife and not second.alive,
			"Sync reset a pending respawn"
		)
		battle:step(0.1, 10)
		assert(
			second.alive and second.life ~= secondLife and second.health == second.maxHealth,
			"Current slot did not respawn"
		)
	end)
	check("army sync enforces ten total roles and rejects civilian or changed-slot identities atomically", function()
		local battle = make()
		local slots = {}
		for index = 1, 10 do
			table.insert(slots, slot(tostring(index), if index == 10 then "medic" else "melee", -80, index))
		end
		assert(battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Ten total troops rejected")
		table.insert(slots, slot("extra", "medic"))
		assert(not battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Eleventh troop accepted")
		assert(actorFor(battle, "A", "1").health > 0, "Failed sync removed prior army")
		assert(
			not battle:syncArmy("A", "sparta", "line", { slot("1", "civilian") }, 0).ok,
			"Civilian became a combat target"
		)
		assert(
			not battle:syncArmy("A", "sparta", "line", { slot("1", "ranged") }, 0).ok,
			"Stable slot changed combat identity"
		)
	end)
	check("empty armies retain explicit commands for later slots and main plots cannot be command targets", function()
		local battle = make()
		assert(
			battle:syncArmy("A", "sparta", "line", {}, 0).ok and battle:command("A", "post").ok,
			"Empty-army command failed"
		)
		assert(not battle:command("A", "home-plot").ok, "Main plot accepted as capturable target")
		assert(battle:syncArmy("A", "sparta", "line", { slot("one", "melee", -60) }, 0).ok, "Later troop sync failed")
		assert(battle.armies.A.manual and battle.armies.A.targetId == "post", "Sync discarded explicit order")
		advance(battle, 1)
		assert(actorFor(battle, "A", "one").x > -60, "Later troop did not follow the order")
	end)
	check("capture requires exactly twenty clear occupied seconds and cancels neutral respawns", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		local now = advance(battle, 19.95)
		assert(
			battle.outposts.post.ownerTeam == nil and battle.outposts.post.progress < 20,
			"Capture completed before twenty seconds"
		)
		advance(battle, 0.05, now)
		assert(
			battle.outposts.post.ownerTeam == "A" and battle.outposts.post.ownerCivilizationId == "sparta",
			"Twenty seconds did not capture"
		)
		advance(battle, 20, 20)
		for _, actor in battle.actors do
			assert(actor.team ~= "neutral:post", "Captured outpost respawned neutral or free allied defenders")
		end
	end)
	check("a neutral respawn pauses capture and an absent occupying force resets progress", function()
		local battle = make()
		clearNeutral(battle, 2)
		battle:syncArmy("A", "sparta", "line", { slot("medic", "medic") }, 0)
		local now = advance(battle, 3)
		local progress = battle.outposts.post.progress
		assert(
			progress > 1.8 and progress < 2.01 and battle.outposts.post.status == "defended",
			"Live respawn did not pause capture"
		)
		battle:syncArmy("A", "sparta", "line", {}, now)
		advance(battle, 0.1, now)
		assert(
			battle.outposts.post.progress == 0 and battle.outposts.post.captureTeam == nil,
			"Absent force kept capture progress"
		)
	end)
	check("rival occupation contests and pauses existing progress without granting either team", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("medic", "medic") }, 0)
		local now = advance(battle, 5)
		battle:syncArmy("B", "rome", "line", { slot("medic", "medic", 1) }, now)
		advance(battle, 3, now)
		assert(
			battle.outposts.post.status == "contested" and math.abs(battle.outposts.post.progress - 5) < 0.00001,
			"Contest advanced or reset present force"
		)
		battle:removeArmy("B")
		advance(battle, 15, 8)
		assert(battle.outposts.post.ownerTeam == "A", "Clear occupation did not resume after contest")
	end)
	check("a mixed player force can defeat near-equal neutral defenders and capture through respawns", function()
		local battle = make()
		battle:syncArmy("A", "sparta", "line", {
			slot("one", "melee", -20, -1),
			slot("two", "melee", -20, 1),
			slot("bow-one", "ranged", -24, -1),
			slot("bow-two", "ranged", -24, 1),
			slot("medic", "medic", -27, 0),
		}, 0)
		local _, events = advance(battle, 90)
		local hit, death = false, false
		for _, event in events do
			if event.kind == "hit" then
				hit = true
			elseif event.kind == "death" then
				death = true
			end
		end
		assert(
			hit and death and battle.outposts.post.ownerTeam == "A",
			"Mixed force could not overcome near-equal neutral respawns"
		)
	end)
	check("melee contacts and ranged shots recheck visibility and cannot hit a replacement life", function()
		local visible = true
		local battle = make({
			visible = function()
				return visible
			end,
		})
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "ranged", 1) }, 0)
		local now = advance(battle, 0.05)
		local first, second = actorFor(battle, "A", "one"), actorFor(battle, "B", "one")
		assert(first.phase == "windup" and second.phase == "windup", "Attacks did not plant windups")
		visible = false
		advance(battle, 0.5, now)
		assert(
			first.health == first.maxHealth and second.health == second.maxHealth,
			"Obstructed contact or shot damaged"
		)
		visible = true
		advance(battle, 1, 0.55)
		local oldLife = second.life
		battle:removeArmy("B")
		battle:syncArmy("B", "rome", "line", { slot("one", "ranged", 1) }, 1.55)
		second = actorFor(battle, "B", "one")
		assert(second.life ~= oldLife, "Replacement reused a stale life identity")
		local _, events = advance(battle, 0.25, 1.55)
		for _, event in events do
			assert(
				not (event.kind == "hit" and event.actorId == first.id and event.targetLife == oldLife),
				"Pending contact struck a replaced life"
			)
		end
	end)
	check("combat never targets players civilians or nearby armies traveling through home territory", function()
		local battle = Battle.new({ { id = "far", x = 1000, z = 0, radius = 22, lineId = "line" } })
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee", -100) }, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "ranged", -100, 1) }, 0)
		local _, events = advance(battle, 2)
		for _, event in events do
			assert(
				event.kind ~= "hit" and event.kind ~= "attack" and event.kind ~= "shot",
				"Home/transit combat occurred"
			)
		end
		for _, actor in battle.actors do
			assert(actor.health == actor.maxHealth, "Protected home actor took damage")
		end
	end)
	check("medics heal living allies in the battle vicinity without attacking enemies or reviving", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("fighter", "melee"), slot("medic", "medic", 1) }, 0)
		local fighter = actorFor(battle, "A", "fighter")
		fighter.health = 50
		local _, events = advance(battle, 2)
		assert(fighter.health > 50 and fighter.health <= fighter.maxHealth, "Medic did not heal a wounded ally")
		local medic = actorFor(battle, "A", "medic")
		for _, event in events do
			assert(
				not ((event.kind == "attack" or event.kind == "shot") and event.actorId == medic.id),
				"Medic performed an offensive action"
			)
		end
		fighter.health, fighter.alive, fighter.phase, fighter.respawnAt = 0, false, "dead", 1000
		advance(battle, 2, 2)
		assert(not fighter.alive and fighter.health == 0, "Medic revived a dead actor")
	end)
	check("hostile armies can eliminate defenders and recapture without creating extra garrison capacity", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		advance(battle, 20)
		assert(battle.outposts.post.ownerTeam == "A", "First capture setup failed")
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee", -1000) }, 20)
		local slots = {}
		for index = 1, 4 do
			table.insert(slots, slot(tostring(index), "melee", 1, index * 0.2))
		end
		battle:syncArmy("B", "rome", "line", slots, 20)
		local _, events = advance(battle, 35, 20)
		local pvp = false
		for _, event in events do
			if event.kind == "hit" and event.team == "B" then
				pvp = true
			end
		end
		assert(
			pvp and battle.outposts.post.ownerTeam == "B" and battle.outposts.post.ownerCivilizationId == "rome",
			"Rival army did not recapture"
		)
		local total = 0
		for _, actor in battle.actors do
			if actor.team == "B" then
				total += 1
			end
			assert(actor.team ~= "neutral:post", "Captured point produced neutral defenders")
		end
		assert(total == 4, "Capture granted an extra owner garrison")
	end)
	check(
		"automatic armies advance along the outpost chain while explicit overrides guard their chosen post",
		function()
			local battle = Battle.new({
				{ id = "first", x = 0, z = 0, radius = 22, lineId = "line", nextId = "second" },
				{ id = "second", x = 80, z = 0, radius = 22, lineId = "future" },
			})
			for _, actor in battle.actors do
				actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 1000000
			end
			battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
			advance(battle, 20)
			assert(
				battle.armies.A.targetId == "second" and not battle.armies.A.manual,
				"Automatic army did not advance"
			)
			assert(battle:command("A", "first").ok, "Explicit return command failed")
			advance(battle, 1, 20)
			assert(
				battle.armies.A.targetId == "first" and battle.armies.A.manual,
				"Automatic targeting overrode explicit command"
			)
		end
	)
	check("lost army authority cancels actors capture and ownership then restores original neutral defense", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		advance(battle, 20)
		battle:removeArmy("A")
		assert(
			battle.armies.A == nil and battle.outposts.post.ownerTeam == nil and battle.outposts.post.progress == 0,
			"Removed authority retained ownership"
		)
		local total = 0
		for _, actor in battle.actors do
			total += 1
			assert(actor.team == "neutral:post" and actor.alive, "Old army or dead garrison survived removal")
		end
		assert(total == 3, "Neutral defense was not restored exactly once")
		battle:removeArmy("A")
		local again = 0
		for _ in battle.actors do
			again += 1
		end
		assert(
			again == 3 and not battle:command("A", "post").ok,
			"Repeated removal duplicated guards or retained command authority"
		)
	end)
	check("malformed time and long stalls cannot grant offline capture or repeat contacts", function()
		local battle = make()
		clearNeutral(battle)
		battle:syncArmy("A", "sparta", "line", { slot("one", "melee") }, 0)
		for _, dt in { -1, 0 / 0, math.huge } do
			assert(not battle:step(dt, 1).ok, "Malformed battle time accepted")
		end
		assert(
			battle:step(100, 100).ok
				and battle.outposts.post.progress <= Config.maxDelta
				and battle.outposts.post.ownerTeam == nil,
			"Stall granted twenty offline seconds"
		)
		assert(not battle:step(0.1, 99).ok, "Backwards battle time accepted")
	end)
	check(
		"multiple buildings receive distinct arrival slots and moving allies separate without moving planted windups",
		function()
			local battle = make()
			clearNeutral(battle)
			local slots = {}
			for index = 1, 9 do
				table.insert(
					slots,
					slot(tostring(index), if index == 9 then "medic" elseif index > 6 then "ranged" else "melee", -50)
				)
			end
			battle:syncArmy("A", "sparta", "line", slots, 0)
			advance(battle, 8)
			local positions, formation = {}, {}
			for _, actor in battle.actors do
				if actor.team == "A" then
					assert(
						actor.formationIndex ~= nil and not formation[actor.formationIndex],
						"Building-local indices stacked arrival slots"
					)
					formation[actor.formationIndex] = true
					for _, other in positions do
						assert(
							math.sqrt((actor.x - other.x) ^ 2 + (actor.z - other.z) ^ 2) > 0.5,
							"Idle troops stacked at the destination"
						)
					end
					table.insert(positions, actor)
				end
			end
			local duel = make()
			clearNeutral(duel)
			duel:syncArmy("A", "sparta", "line", { slot("one", "melee"), slot("moving", "melee", -5) }, 0)
			duel:syncArmy("B", "rome", "line", { slot("one", "medic", 1) }, 0)
			advance(duel, 0.05)
			local planted = actorFor(duel, "A", "one")
			local x, z = planted.x, planted.z
			assert(planted.phase == "windup", "Planted-windup fixture failed")
			advance(duel, 0.1, 0.05)
			assert(planted.x == x and planted.z == z, "Soft separation moved a planted attack")
		end
	)
	check("one planted contact applies damage once and cannot hit a newly replaced target life", function()
		local battle = make()
		clearNeutral(battle)
		local slots = { slot("one", "melee") }
		battle:syncArmy("A", "sparta", "line", slots, 0)
		battle:syncArmy("B", "rome", "line", { slot("one", "medic", 1) }, 0)
		advance(battle, 0.05)
		for _ = 1, 20 do
			battle:syncArmy("A", "sparta", "line", slots, 0.05)
		end
		local _, events = advance(battle, 0.5, 0.05)
		local hits = 0
		for _, event in events do
			if event.kind == "hit" and event.team == "A" then
				hits += 1
			end
		end
		assert(
			hits == 1 and actorFor(battle, "B", "one").health == Config.player.medic.health - Config.player.melee.damage,
			"Contact or repeated sync duplicated damage"
		)
		local replacement = make()
		clearNeutral(replacement)
		replacement:syncArmy("A", "sparta", "line", slots, 0)
		replacement:syncArmy("B", "rome", "line", { slot("one", "medic", 1) }, 0)
		advance(replacement, 0.05)
		local oldLife = actorFor(replacement, "B", "one").life
		replacement:removeArmy("B")
		replacement:syncArmy("B", "rome", "line", { slot("one", "medic", 1) }, 0.05)
		advance(replacement, 0.3, 0.05)
		local target = actorFor(replacement, "B", "one")
		assert(
			target.life ~= oldLife and target.health == target.maxHealth,
			"Old pending contact damaged a replacement life"
		)
	end)
	return count
end

return run

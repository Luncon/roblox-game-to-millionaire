--!strict
-- Native SERVER fixture only: isolated virtual battles and fresh actual rigs.
-- Full research, positions and wounds are declared fixture data, never sessions.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local Storage = game:GetService("ServerStorage")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong native military boundary"
	)
	local Server = game:GetService("ServerScriptService").Sandbox
	local Shared = Replicated.MiniatureGame
	local Battle = require(Server.Battle)
	local Original = require(Server.OriginalBehavior)
	local Troops = require(Server.OriginalTroops)
	local Mounted = require(Server.MountedTroops)
	local Rules = require(Shared.MilitaryResearch)
	local Civilizations = require(Shared.Civilizations)
	local Codec = require(Shared.PoseCodec)
	local Kinematics = require(Shared.RigKinematics)
	local fingerprintModule = Storage:FindFirstChild("TemplateFingerprint")
	local fingerprint = if fingerprintModule then require(fingerprintModule) else nil
	local before = if fingerprint then fingerprint() else nil
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "NativeMilitaryMatrixClones", Storage
	local began = os.clock()
	local report = {
		civilizations = #Civilizations,
		cases = 0,
		passed = 0,
		failed = 0,
		poses = 0,
		poseParts = 0,
		nativeInstanceIdentities = true,
		tableRigFactoryInjected = false,
		runtimeSessionMutation = false,
		virtualSimulationClocks = true,
		completedNodesFixture = #Rules.order,
		rows = {},
	}
	local all = {}
	for _, id in Rules.order do
		all[id] = true
	end
	assert(Rules.validateCompleted(all), "Catalog completion fixture invalid")
	local function near(a: number, b: number): boolean
		return math.abs(a - b) < 0.002
	end
	local function slot(id, role, x, z)
		return { id = id, role = role, buildingId = "matrix-" .. id, index = 1, x = x or 0, z = z or 0 }
	end
	local function owned(battle, team, id)
		for _, actor in battle.actors do
			if actor.team == team and actor.slotId == id then
				return actor
			end
		end
		error("Native matrix actor missing")
	end
	local function make()
		-- No rigFactory or engine doubles: the adapter creates actual Model identities.
		local behavior = Original.new()
		local definitions = { { id = "matrix-post", x = 0, z = 0, radius = 22, lineId = "matrix-line" } }
		local battle = Battle.new(definitions, { behavior = behavior })
		for _, actor in battle.actors do
			actor.health, actor.alive, actor.respawnAt = 0, false, 1000000
		end
		return battle, behavior
	end
	local function advance(battle, seconds, start, beforeStep)
		local now, events = start or 0, {}
		while seconds > 0.000001 do
			local dt = math.min(0.05, seconds)
			if beforeStep then
				beforeStep()
			end
			now += dt
			assert(battle:step(dt, now).ok, "Native matrix time rejected")
			for _, event in battle.events do
				table.insert(events, event)
			end
			seconds -= dt
		end
		return now, events
	end
	for _, civilization in Civilizations do
		for _, role in { "melee", "ranged", "medic", "mounted" } do
			Replicated:SetAttribute("MiniatureMilitaryMatrixProgress", civilization.id .. "/" .. role)
			local row = { civilizationId = civilization.id, role = role }
			local caseBegan = os.clock()
			local behaviors = {}
			local ok, failure = pcall(function()
				assert(os.clock() - began < 60, "Native matrix exceeded sixty-second budget")
				local profile = Rules.profile(role, civilization.id, all)
				local battle, behavior = make()
				table.insert(behaviors, behavior)
				local slots = { slot("unit", role, -60, 0) }
				assert(battle:syncArmy("A", civilization.id, "matrix-line", slots, 0).ok, "Native baseline sync failed")
				local actor = owned(battle, "A", "unit")
				actor.health = actor.maxHealth - 17
				local hp, life = actor.health, actor.life
				actor.nextAttack, actor.nextHeal, actor.recoveryUntil = 5, 6, 7
				assert(
					battle:syncArmy("A", civilization.id, "matrix-line", slots, 0, all).ok,
					"Native upgraded sync failed"
				)
				assert(
					actor.health == hp and actor.life == life and near(actor.maxHealth, profile.health),
					"Native research healed or replaced life"
				)
				assert(
					actor.nextAttack == 5 and actor.nextHeal == 6 and actor.recoveryUntil == 7,
					"Native research reset pending clocks"
				)
				advance(battle, 1)
				local distance = math.sqrt((actor.x + 60) ^ 2 + actor.z ^ 2)
				assert(
					near(distance, profile.speed) and behavior.metrics.crowdPlans > 0,
					"Native original movement ignored researched species speed"
				)
				actor.health, actor.alive, actor.phase, actor.respawnAt = 0, false, "dead", 2
				battle:syncArmy("A", civilization.id, "matrix-line", slots, 1, all)
				assert(actor.respawnAt == 2 and actor.life == life, "Native pending respawn deadline changed")
				advance(battle, 0.95, 1)
				assert(not actor.alive, "Native research replacement arrived early")
				advance(battle, 0.05, 1.95)
				assert(
					actor.alive and actor.life ~= life and near(actor.health, profile.health),
					"Native replacement lost researched maximum"
				)
				row.speed, row.marchDistance, row.maximumHealth, row.damage =
					profile.speed, distance, profile.health, profile.damage
				row.woundedLifePreserved, row.respawnDeadlinePreserved = true, true

				local combat, tactics = make()
				table.insert(behaviors, tactics)
				if role == "medic" then
					local actors = { slot("patient", "melee", -4.4, -3), slot("medic", "medic", -12.7, -3) }
					combat:syncArmy("A", civilization.id, "matrix-line", actors, 0, all)
					local patient = owned(combat, "A", "patient")
					patient.health = 100
					local _, events = advance(combat, 1.5)
					local launch
					for _, event in events do
						if event.kind == "bandage" then
							launch = event
							break
						end
					end
					assert(
						launch and patient.health > 100 and tactics.metrics.bandageThrows > 0,
						"Native researched medical service did not heal"
					)
					local range = math.sqrt((launch.targetX - launch.x) ^ 2 + (launch.targetZ - launch.z) ^ 2)
					assert(
						range > 7 and range <= profile.healRange + 0.01,
						"Native bandage did not exercise extended research coverage"
					)
					row.extendedDistance, row.healed = range, patient.health - 100
				else
					local range = if role == "ranged" then 11.2 else 1.5
					combat:syncArmy("A", civilization.id, "matrix-line", { slot("attacker", role) }, 0, all)
					combat:syncArmy("B", "rome", "matrix-line", { slot("target", "medic", range) }, 0)
					local attacker, target = owned(combat, "A", "attacker"), owned(combat, "B", "target")
					local _, events = advance(combat, if role == "ranged" then 1 else 0.35, 0, function()
						target.x, target.z = attacker.x + range, attacker.z
					end)
					local hit, shot
					for _, event in events do
						if event.actorId == attacker.id and event.kind == "hit" then
							hit = event
						end
						if event.actorId == attacker.id and event.kind == "shot" then
							shot = event
						end
					end
					assert(
						hit and tactics.metrics.encounterAdvances > 0 and near(hit.amount, profile.damage),
						"Native original researched contact failed"
					)
					local actual = math.sqrt((hit.targetX - hit.x) ^ 2 + (hit.targetZ - hit.z) ^ 2)
					if role == "ranged" then
						assert(
							shot and hit.time > shot.time and actual > 10 and tactics.metrics.projectileHits > 0,
							"Native researched projectile skipped extended delayed contact"
						)
						row.shotTime, row.hitTime = shot.time, hit.time
					else
						assert(
							actual > 1.25 and actual <= 1.25 * (profile.reach / 2.5) + 0.01,
							"Native melee reach doubled or ignored research"
						)
					end
					row.extendedDistance, row.hitDamage = actual, hit.amount
				end

				local rig = if role == "mounted"
					then Mounted.create(civilization.id)
					else Troops.create(civilization.id, role)
				rig.Name, rig.Parent = civilization.id .. "_" .. role, folder
				rig:SetAttribute("Life", actor.life)
				local parts = {}
				for _, part in rig:GetDescendants() do
					if part:IsA("BasePart") then
						table.insert(parts, part)
						part:SetAttribute("NativeMilitaryMatrixPart", #parts)
					end
				end
				local pose = table.clone(actor)
				pose.x, pose.z, pose.phase, pose.combatPhase, pose.moving = 2200, 2200, "moving", "idle", true
				pose.headingX, pose.headingZ = 1, 0
				Troops.pose(rig, pose, 10, 2)
				pose.x += profile.speed * 0.1
				Troops.pose(rig, pose, 10.1, 2)
				local packet = Codec.decode(rig:GetAttribute("PoseSnapshot"))
				assert(packet and packet.life == actor.life, "Native researched pose packet invalid")
				if role == "mounted" then
					assert(
						packet.speed and near(packet.speed, profile.speed),
						"Native mounted pose packet truncated researched speed"
					)
				else
					assert(packet.speed == nil, "Foot packet gained mounted gait metadata")
				end
				local clone = rig:Clone()
				clone.Name, clone.Parent = rig.Name .. "_decoded", folder
				local solver = Kinematics.new(clone)
				assert(solver, "Native researched clone joint graph invalid")
				Kinematics.apply(solver, packet, { folder })
				local maxPosition, maxBasis, cloned = 0, 0, 0
				for _, part in clone:GetDescendants() do
					if part:IsA("BasePart") then
						local source = parts[part:GetAttribute("NativeMilitaryMatrixPart")]
						assert(
							source and part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
							"Native clone changed identity or gameplay physics"
						)
						maxPosition = math.max(maxPosition, (source.Position - part.Position).Magnitude)
						maxBasis = math.max(
							maxBasis,
							(source.CFrame.LookVector - part.CFrame.LookVector).Magnitude,
							(source.CFrame.UpVector - part.CFrame.UpVector).Magnitude
						)
						cloned += 1
					end
				end
				assert(
					cloned == #parts and maxPosition < 0.02 and maxBasis < 0.01,
					"Native researched pose reconstruction drifted"
				)
				row.poseParts, row.posePositionError, row.poseBasisError, row.packetSpeed =
					#parts, maxPosition, maxBasis, packet.speed
				row.groundHeight, row.soleY =
					rig:GetAttribute("OriginalGroundHeight"), rig:GetAttribute("OriginalSoleY")
				assert(math.abs(row.soleY - 2.005) < 0.01, "Native researched pose lost grounded feet")
				report.poses += 1
				report.poseParts += #parts
			end)
			for _, behavior in behaviors do
				behavior:destroy()
			end
			folder:ClearAllChildren()
			row.ok, row.elapsedSeconds = ok, os.clock() - caseBegan
			if not ok then
				row.error = tostring(failure)
				report.failed += 1
			else
				report.passed += 1
			end
			report.cases += 1
			table.insert(report.rows, row)
			task.wait()
		end
	end
	local unchanged = not fingerprint or fingerprint() == before
	folder:Destroy()
	report.sourceTemplatesUnchanged, report.elapsedSeconds = unchanged, os.clock() - began
	local ok = report.failed == 0 and report.cases == 52 and unchanged
	Replicated:SetAttribute("MiniatureMilitaryMatrixResult", Http:JSONEncode({ ok = ok, result = report }))
	assert(ok, "Native researched military matrix failed; read MiniatureMilitaryMatrixResult")
	return report
end
return run

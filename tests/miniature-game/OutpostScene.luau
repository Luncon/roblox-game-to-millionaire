--!strict
-- Server-only native adapter fixture. Rival armies and time are simulated;
-- this is not a live player, datastore, client-input or multiplayer test.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").Sandbox
	local Workspace = game:GetService("Workspace")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong outpost native boundary"
	)
	local Battle = require(Server.Battle)
	local OutpostWorld = require(Server.OutpostWorld)
	local Config = require(Replicated.MiniatureGame.Config)
	local Civilizations = require(Replicated.MiniatureGame.Civilizations)
	local fingerprint = require(game:GetService("ServerStorage").TemplateFingerprint)
	local original = fingerprint()
	local sourceParts, sourceModels = {}, {}
	for _, culture in Replicated.MiniatureGame.Previews:GetChildren() do
		for _, model in culture.Actors:GetChildren() do
			sourceModels[model] =
				{ scale = model:GetScale(), pivot = model:GetPivot(), combat = model:GetAttribute("CombatActor") }
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") then
					sourceParts[item] = {
						frame = item.CFrame,
						size = item.Size,
						color = item.Color,
						anchored = item.Anchored,
						collide = item.CanCollide,
						touch = item.CanTouch,
						query = item.CanQuery,
					}
				end
			end
		end
	end
	local scene = Instance.new("Model")
	scene.Name = "MiniatureOutpostSceneFixture"
	local world = { scene = scene, plots = {} }
	for index = 1, 8 do
		local angle = (index - 1) * math.pi / 4
		table.insert(world.plots, {
			frame = CFrame.new(math.sin(angle) * Config.plotRadius, 0, math.cos(angle) * Config.plotRadius)
				* CFrame.Angles(0, angle, 0),
		})
	end
	scene.Parent = Workspace
	local visuals
	local evidence =
		{ simulatedRivalTeams = true, fakeClock = true, livePlayerMutation = false, actualMultiplayer = false }
	local ok, result = pcall(function()
		visuals = OutpostWorld.create(world)
		assert(#visuals.definitions == 8 and #scene.Outposts:GetChildren() == 8, "Wrong outpost manifest")
		for _, definition in visuals.definitions do
			assert(
				math.abs(Vector3.new(definition.x, 0, definition.z).Magnitude - 290) < 0.01 and definition.radius == 22,
				"Wrong radial outpost position"
			)
			assert(
				math.abs(definition.x) + 23 < Config.worldSize / 2
					and math.abs(definition.z) + 23 < Config.worldSize / 2,
				"Outpost left ground bounds"
			)
			for _, plot in world.plots do
				local point = plot.frame:PointToObjectSpace(Vector3.new(definition.x, 0, definition.z))
				local dx, dz =
					math.max(0, math.abs(point.X) - Config.expansionWidth / 2),
					math.max(0, math.abs(point.Z) - Config.expansionDepth / 2)
				assert(math.sqrt(dx * dx + dz * dz) > definition.radius + 1, "Outpost entered a future protected plot")
			end
			local model = visuals.models[definition.id]
			local prompt = model.Target.TargetOutpost
			assert(
				model:GetAttribute("OutpostId") == definition.id
					and prompt:GetAttribute("OutpostId") == definition.id
					and prompt:GetAttribute("ArmyTarget"),
				"Missing army-target identity"
			)
			assert(
				prompt.KeyboardKeyCode == Enum.KeyCode.E and prompt.MaxActivationDistance == 12,
				"Wrong outpost interaction"
			)
			for _, item in model:GetDescendants() do
				assert(not item:IsA("LuaSourceContainer"), "Executable outpost scenery")
				if item:IsA("BasePart") then
					assert(
						item.Anchored
							and not item.CanCollide
							and not item.CanTouch
							and (
								not item.CanQuery
								or (item.Name == "CampFooting" and item:GetAttribute("OriginalTroopSupport") == true)
							),
						"Outpost scenery blocks commander"
					)
				end
			end
		end
		local battle = Battle.new(visuals.definitions)
		local now = 0
		visuals:update(battle, now)
		visuals:syncActors(battle, now)
		for _, definition in visuals.definitions do
			local counts = { melee = 0, ranged = 0 }
			for _, actor in battle.actors do
				if actor.team == "neutral:" .. definition.id and actor.alive then
					counts[actor.role] += 1
				end
			end
			assert(
				counts.melee == 2
					and counts.ranged == 1
					and visuals.models[definition.id]:GetAttribute("NeutralDefenders") == 3,
				"Initial neutral defense differs"
			)
		end
		assert(#scene.BattleActors:GetChildren() == 24, "Initial neutral actor visuals missing")
		for _, model in scene.BattleActors:GetChildren() do
			assert(
				model:GetAttribute("CombatActor")
					and model:GetAttribute("NeutralDefense")
					and model:GetAttribute("CivilizationId") == "neutral"
					and model:GetAttribute("SourceCivilizationId") == "neutral"
					and model:GetAttribute("OriginalArmyVisual") == true,
				"Neutral appearance presented as historical faction"
			)
			assert(math.abs(model:GetScale() - 0.25) < 0.001, "Neutral actor scale/behavior differs")
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and not humanoid.EvaluateStateMachine and not humanoid.AutoRotate and humanoid.WalkSpeed == 0,
				"Original neutral clothing Humanoid can move"
			)
			assert(model:FindFirstChild("NeutralWeapon"), "Original neutral weapon missing")
			assert(
				model:GetAttribute("OriginalAnimationStyle")
					== (if model:GetAttribute("Role") == "ranged" then "bow" else "slash"),
				"Original neutral attack family changed"
			)
			for _, item in model:GetDescendants() do
				assert(
					not item:IsA("LuaSourceContainer") and not item:IsA("TouchTransmitter"),
					"Actor imported behavior"
				)
				if item:IsA("Tool") then
					assert(
						not item.Enabled and not item.CanBeDropped and item:GetAttribute("VisualOnly"),
						"Original weapon remains interactive"
					)
				end
				if item:IsA("BasePart") then
					assert(
						item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
						"Actor enters native collision/query"
					)
				end
			end
		end
		-- Controlled visual views prove life replacement without mutating Battle.
		local id, sample = next(battle.actors)
		local oldModel = scene.BattleActors[id]
		visuals:syncActors(battle, now)
		assert(scene.BattleActors[id] == oldModel, "Unchanged battle rebuilt actor")
		local view = table.clone(battle)
		view.actors = table.clone(battle.actors)
		local changed = table.clone(sample)
		changed.alive = false
		view.actors[id] = changed
		visuals:syncActors(view, now)
		assert(not scene.BattleActors:FindFirstChild(id), "Dead actor visual remained")
		changed = table.clone(sample)
		changed.life += 10000
		view.actors[id] = changed
		visuals:syncActors(view, now)
		assert(
			scene.BattleActors[id] ~= oldModel and scene.BattleActors[id]:GetAttribute("Life") == changed.life,
			"New actor life reused old visual"
		)
		visuals:syncActors(battle, now)
		view = table.clone(battle)
		view.events = {
			{
				kind = "shot",
				actorId = id,
				actorLife = sample.life,
				x = sample.x,
				z = sample.z,
				targetX = sample.x + 10,
				targetZ = sample.z,
				time = now,
			},
		}
		visuals:syncActors(view, now)
		local projectile = scene.BattleEffects:FindFirstChild("Projectile_arrow")
		assert(
			projectile
				and projectile:GetAttribute("VisualOnly") == true
				and projectile:GetAttribute("VisualProjectile") == true
				and projectile:GetAttribute("ProjectileKind") == "arrow"
				and projectile:GetAttribute("OriginalProjectileScale") == 0.25,
			"Neutral shot has no original inert arrow visual"
		)
		for _, part in projectile:GetDescendants() do
			if part:IsA("BasePart") then
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Projectile entered native physics"
				)
			end
		end
		local began = projectile:GetPivot().Position
		visuals:syncActors(view, now + 0.1)
		assert((projectile:GetPivot().Position - began).Magnitude > 1, "Original projectile did not travel")
		visuals:syncActors(view, now + 1)
		assert(#scene.BattleEffects:GetChildren() == 0, "Projectile TTL leaked")
		now = 1
		local post = battle.outposts[visuals.definitions[1].id]
		local function slots()
			local armySlots = {}
			for index = 1, 10 do
				table.insert(armySlots, {
					id = "fixture-slot-" .. index,
					role = if index > 8 then "ranged" else "melee",
					buildingId = "fixture-building-" .. index,
					index = index,
					x = post.x + (index % 5 - 2) * 2,
					z = post.z + 8 + math.floor((index - 1) / 5) * 2,
				})
			end
			return armySlots
		end
		assert(
			battle:syncArmy("native-fixture-alpha", "sparta", post.lineId, slots(), now).ok,
			"First simulated army rejected"
		)
		local eventCounts = { shot = 0, hit = 0, death = 0, capture = 0 }
		local function capture(team, seconds)
			local stop = now + seconds
			local captureStart
			local ticks = 0
			while post.ownerTeam ~= team and now < stop do
				now += 0.1
				ticks += 1
				assert(battle:step(0.1, now).ok, "Fake clock rejected")
				for _, event in battle.events do
					if eventCounts[event.kind] ~= nil then
						eventCounts[event.kind] += 1
					end
				end
				if post.captureTeam == team and post.progress > 0 and not captureStart then
					captureStart = now - post.progress
				end
				if ticks % 10 == 0 or #battle.events > 0 or post.ownerTeam == team then
					visuals:update(battle, now)
					visuals:syncActors(battle, now)
					local model = visuals.models[post.id]
					assert(
						model:GetAttribute("CaptureStatus") == post.status
							and math.abs(model:GetAttribute("CaptureProgress") - post.progress) < 0.001,
						"Capture state not rendered"
					)
					assert(
						math.abs(model.Target.CaptureDisplay.CaptureBar.Fill.Size.X.Scale - post.progress / 20) < 0.0001,
						"Capture bar differs from clock"
					)
				end
			end
			assert(
				post.ownerTeam == team and captureStart and now - captureStart >= 19.9,
				"Capture did not require twenty clear seconds"
			)
		end
		capture("native-fixture-alpha", 60)
		assert(
			eventCounts.shot > 0 and eventCounts.hit > 0 and eventCounts.death >= 3,
			"Natural combat did not precede capture"
		)
		local model = visuals.models[post.id]
		assert(
			model.Flag:GetAttribute("OwnerCivilizationId") == "sparta"
				and model:GetAttribute("OwnerCivilizationId") == "sparta",
			"First capture flag missing"
		)
		local firstColor = model.Flag.Color
		for _, actor in battle.actors do
			assert(actor.garrisonId ~= post.id, "Captured neutral defender/respawn remained")
		end
		assert(
			battle:syncArmy("native-fixture-alpha", "sparta", post.lineId, {}, now).ok,
			"Removing first army slots rejected"
		)
		assert(post.ownerTeam == "native-fixture-alpha", "Empty army released owned outpost")
		assert(
			battle:syncArmy("native-fixture-bravo", "rome", post.lineId, slots(), now).ok,
			"Second simulated army rejected"
		)
		capture("native-fixture-bravo", 45)
		assert(
			model.Flag:GetAttribute("OwnerCivilizationId") == "rome" and model.Flag.Color ~= firstColor,
			"Recapture did not change culture flag"
		)
		local romanColor
		for _, culture in Civilizations do
			if culture.id == "rome" then
				romanColor = culture.color
			end
		end
		assert(
			model.Flag.Color == romanColor
				and string.find(model.Target.CaptureDisplay.CaptureLabel.Text, "Rome", 1, true),
			"Recapture label/color differs from culture"
		)
		assert(scene.BattleEffects:GetAttribute("ActiveEffects") <= 96, "Effects exceeded bounded capacity")
		evidence.outposts, evidence.initialNeutralActors, evidence.nativeLifeSync, evidence.projectileTravelTTL =
			8, 24, true, true
		evidence.captureSeconds, evidence.firstOwner, evidence.recapturedOwner = 20, "sparta", "rome"
		evidence.events = eventCounts
		evidence.fakeSeconds = now
		return evidence
	end)
	if visuals then
		visuals:destroy()
		visuals:destroy()
	end
	assert(
		not scene:FindFirstChild("Outposts")
			and not scene:FindFirstChild("BattleActors")
			and not scene:FindFirstChild("BattleEffects"),
		"Outpost adapter cleanup left folders"
	)
	scene:Destroy()
	for model, saved in sourceModels do
		assert(
			model:GetScale() == saved.scale
				and model:GetPivot() == saved.pivot
				and model:GetAttribute("CombatActor") == saved.combat,
			"Source actor model mutated"
		)
	end
	for item, saved in sourceParts do
		assert(
			item.CFrame == saved.frame
				and item.Size == saved.size
				and item.Color == saved.color
				and item.Anchored == saved.anchored
				and item.CanCollide == saved.collide
				and item.CanTouch == saved.touch
				and item.CanQuery == saved.query,
			"Source actor part mutated"
		)
	end
	assert(fingerprint() == original, "Original source templates changed")
	Replicated:SetAttribute(
		"MiniatureOutpostSceneResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = if ok then result else tostring(result) })
	)
	assert(ok, result)
	return result
end
return run

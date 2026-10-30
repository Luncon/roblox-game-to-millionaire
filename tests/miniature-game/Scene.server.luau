--!strict
-- Run only in the injected-fake-store test place. Select Sparta before the timeout.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
local State = require(game.ServerScriptService.Sandbox.State)
local Workforce = require(game.ServerScriptService.Sandbox.Workforce)

local function footprint(model, definition, boundsPivot)
	local pivot = boundsPivot or model:GetPivot()
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable art: " .. item:GetFullName())
		if item:IsA("BasePart") then
			assert(item.Anchored and not item.CanCollide and not item.CanTouch, "Art can block the commander")
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(
							math.abs(corner.X) <= definition.width / 2 + 0.01,
							"Art exceeds footprint width: " .. model.Name
						)
						assert(
							math.abs(corner.Z) <= definition.depth / 2 + 0.01,
							"Art exceeds footprint depth: " .. model.Name
						)
					end
				end
			end
		end
	end
end

local function automaticTroopChecks(userId)
	local World = require(game.ServerScriptService.Sandbox.World)
	local model = Instance.new("Model")
	local buildings, actors = Instance.new("Folder"), Instance.new("Folder")
	buildings.Name, buildings.Parent, actors.Name, actors.Parent = "Buildings", model, "Actors", model
	local plot = { model = model, buildings = buildings, actors = actors, frame = CFrame.identity }
	local passed, message = pcall(function()
		local state = State.new("sparta", 0)
		state.buildings[1].x, state.buildings[1].z, state.buildings[1].rotation = -6, -10, 90
		state.buildings[2].x, state.buildings[2].z = -16, 6
		state.buildings[3].x, state.buildings[3].z = 6, -10
		for _, site in
			{
				{ id = "b4", kind = "training", x = -14, z = -10, rotation = 90, output = 0 },
				{ id = "b5", kind = "ranged", x = 14, z = -10, rotation = 90, output = 0 },
				{ id = "b6", kind = "healer", x = 16, z = 12, rotation = 0, output = 0 },
				{ id = "b7", kind = "training", x = -6, z = 8, rotation = 90, output = 0 },
			}
		do
			table.insert(state.buildings, site)
		end
		state.nextBuildingId = 8
		Workforce.reconcile(state)
		assert(
			not state.hallUpgraded and not next(state.research.completed),
			"Automatic troop fixture invented unlocks"
		)
		assert(State.validate(state, "sparta"), "Automatic troop fixture is not a legal settlement")
		World.render(plot, state, userId)
		local original, counts = {}, { melee = 0, ranged = 0, medic = 0 }
		for _, actor in actors:GetChildren() do
			original[actor.Name] = actor
			if actor:GetAttribute("PresentationRole") == "roster" then
				local role, id = actor:GetAttribute("RosterRole"), actor:GetAttribute("BuildingId")
				counts[role] += 1
				assert(
					actor:GetAttribute("AutomaticTroop")
						and actor:GetAttribute("PresentationOnly")
						and actor:GetAttribute("OwnerId") == userId,
					"Automatic actor ownership missing"
				)
				assert(
					actor.Name == "Troop_" .. id .. "_" .. actor:GetAttribute("RoleIndex"),
					"Unstable per-building actor ID"
				)
				local site = buildings[id]
				assert(
					site:GetAttribute("Kind")
						== (if role == "melee" then "training" elseif role == "ranged" then "ranged" else "healer"),
					"Automatic actor uses wrong building"
				)
				assert(math.abs(actor:GetScale() - 0.25) < 0.001, "Automatic actor scale differs")
				footprint(actor, Catalog.buildings[site:GetAttribute("Kind")], site:GetPivot())
				assert(
					not actor:FindFirstChildOfClass("Humanoid") and not actor:FindFirstChildOfClass("Tool"),
					"Automatic actor imports behavior"
				)
				for _, item in actor:GetDescendants() do
					if item:IsA("BasePart") then
						assert(not item.CanQuery, "Automatic actor intercepts selection")
					end
				end
				local colors = actor:FindFirstChildOfClass("BodyColors")
				assert(
					colors and colors.HeadColor3 == actor.Head.Color and colors.TorsoColor3 == actor.Torso.Color,
					"Actor palette differs"
				)
				assert(actor.Head.face.Texture == "rbxassetid://10526794", "Actor face differs")
			end
		end
		assert(
			counts.melee == 4 and counts.ranged == 2 and counts.medic == 1 and #actors:GetChildren() == 11,
			"Per-building troop counts or civilian independence differ"
		)
		assert(counts.melee + counts.ranged + counts.medic <= 10, "Automatic army exceeded total troop cap")
		World.update(plot, state, os.clock())
		for name, actor in original do
			assert(actors:FindFirstChild(name) == actor, "Unrelated update rebuilt an actor")
		end
		-- A turned medic post must reposition its existing life without replacing it.
		state.buildings[6].rotation = 90
		World.update(plot, state, os.clock())
		assert(actors.Troop_b6_1 == original.Troop_b6_1, "Relocation replaced an automatic actor")
		footprint(actors.Troop_b6_1, Catalog.buildings.healer, buildings.b6:GetPivot())
		table.remove(state.buildings, 4)
		World.update(plot, state, os.clock())
		assert(
			#actors:GetChildren() == 9
				and not actors:FindFirstChild("Troop_b4_1")
				and not actors:FindFirstChild("Troop_b4_2"),
			"Removed barracks retained its actors"
		)
		for name, actor in original do
			if actor:GetAttribute("BuildingId") ~= "b4" then
				assert(actors:FindFirstChild(name) == actor, "Removing one barracks removed another building's actor")
			end
		end
		table.insert(state.buildings, { id = "b8", kind = "training", x = -14, z = -10, rotation = 90, output = 0 })
		state.nextBuildingId = 9
		World.update(plot, state, os.clock())
		assert(
			#actors:GetChildren() == 11 and actors:FindFirstChild("Troop_b8_1") and actors:FindFirstChild("Troop_b8_2"),
			"Replacement did not get exactly its own two actors"
		)
		assert(
			actors.Troop_b7_1 == original.Troop_b7_1
				and actors.Troop_b5_1 == original.Troop_b5_1
				and actors.Troop_b6_1 == original.Troop_b6_1,
			"Replacement reset unrelated actors"
		)
		-- Six legal two-person sites offer twelve places; only ten actors may exist.
		local capped = State.new("sparta", 0)
		capped.buildings = {
			{ id = "b1", kind = "civic", x = -6, z = -10, rotation = 90, output = 0 },
			{ id = "b2", kind = "house", x = -16, z = 6, rotation = 0, output = 0 },
		}
		for index, point in { { -14, -10 }, { 6, -10 }, { 14, -10 }, { -6, 8 }, { 6, 8 }, { 14, 8 } } do
			table.insert(
				capped.buildings,
				{ id = "b" .. (index + 2), kind = "training", x = point[1], z = point[2], rotation = 90, output = 0 }
			)
		end
		capped.nextBuildingId = 9
		Workforce.reconcile(capped)
		assert(State.validate(capped, "sparta"), "Troop cap fixture is not a legal settlement")
		World.render(plot, capped, userId)
		local cappedOriginal = {}
		local function troopCount()
			local total = 0
			for _, actor in actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "roster" then
					total += 1
				end
			end
			assert(total <= 10, "Automatic army exceeded ten troops")
			return total
		end
		assert(troopCount() == 10 and not actors:FindFirstChild("Troop_b8_1"), "Waiting barracks bypassed troop cap")
		for _, actor in actors:GetChildren() do
			cappedOriginal[actor.Name] = actor
		end
		table.remove(capped.buildings, 3)
		World.update(plot, capped, os.clock())
		assert(
			troopCount() == 10 and actors:FindFirstChild("Troop_b8_1") and actors:FindFirstChild("Troop_b8_2"),
			"Waiting barracks did not backfill free troop places"
		)
		assert(
			not actors:FindFirstChild("Troop_b3_1") and not actors:FindFirstChild("Troop_b3_2"),
			"Removed capped group retained actors"
		)
		for name, actor in cappedOriginal do
			if actor:GetAttribute("BuildingId") ~= "b3" then
				assert(actors:FindFirstChild(name) == actor, "Troop cap backfill rebuilt an unrelated actor")
			end
		end
		state.civilizationId = "unknown"
		World.render(plot, state, userId)
		assert(
			not model:GetAttribute("ArtReady") and #actors:GetChildren() == 0 and #buildings:GetChildren() == 0,
			"Unknown culture received fallback art"
		)
	end)
	World.clear(plot)
	model:Destroy()
	assert(passed, tostring(message))
	return {
		melee = 4,
		ranged = 2,
		medic = 1,
		perBuildingCleanup = true,
		retainedUnrelatedActors = true,
		troopCap = 10,
		cappedBackfill = true,
	}
end

local function geometrySignature(model)
	local entries = {}
	local pivot = model:GetPivot()
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			local values = { item.Size.X, item.Size.Y, item.Size.Z, pivot:ToObjectSpace(item.CFrame):GetComponents() }
			local row = { item.ClassName }
			for _, value in values do
				table.insert(row, tostring(math.round(value * 1000)))
			end
			table.insert(entries, table.concat(row, ","))
		end
	end
	table.sort(entries)
	return table.concat(entries, ";")
end
local function rangeChecks(previews)
	local signatures, count = {}, 0
	for _, culture in previews:GetChildren() do
		local range = culture:FindFirstChild("ranged")
		assert(
			range and range:GetAttribute("Kind") == "ranged" and range:GetAttribute("CivilizationId") == culture.Name,
			"Missing culture-specific archery range"
		)
		assert(
			range:FindFirstChild("WovenRangeTarget") and range:GetAttribute("GameInterpretation"),
			"Range role or evidence qualification missing"
		)
		footprint(range, Catalog.buildings.ranged)
		local signature = geometrySignature(range)
		assert(not signatures[signature], "Two cultures share recolored range geometry: " .. culture.Name)
		assert(signature ~= geometrySignature(culture.training), "Range reuses the melee barracks shape")
		signatures[signature] = culture.Name
		count += 1
	end
	assert(count == 13, "Incomplete range manifest")
	return count
end

local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Native scene fixture requires Studio")
	local scene = workspace:WaitForChild("MiniatureSandbox", 15)
	assert(scene, "Missing sandbox")
	assert(scene.Ground.Size == Vector3.new(1200, 1, 1200), "Wrong world size")
	assert(#scene.Plots:GetChildren() == 8, "Wrong plot count")
	for _, site in scene.Plots:GetChildren() do
		local point = site.Plot.Position
		assert(site.Plot.Size == Vector3.new(80, 0.4, 64), "Starting build area did not expand")
		assert(math.abs(Vector3.new(point.X, 0, point.Z).Magnitude - 400) < 0.01, "Plot spacing did not expand")
		assert(site.ExpansionReserve.Size == Vector3.new(160, 0.02, 128), "Future plot reserve differs")
		assert(
			not site.ExpansionReserve.CanCollide and not site.ExpansionReserve.CanQuery,
			"Future reserve affects current play"
		)
	end
	local deadline = os.clock() + 60
	local plot
	repeat
		for _, candidate in scene.Plots:GetChildren() do
			if candidate:GetAttribute("CivilizationId") == "sparta" and candidate:GetAttribute("ArtReady") then
				plot = candidate
				break
			end
		end
		if not plot then
			task.wait(0.1)
		end
	until plot or os.clock() >= deadline
	assert(plot, "Select Sparta in the isolated fake-store test before running scene checks")
	assert(plot.Plot.Size == Vector3.new(80, 0.4, 64), "Wrong miniature plot size")
	assert(math.abs(plot.Plot.Position.Y + plot.Plot.Size.Y / 2 - 0.4) < 0.001, "Wrong plot ground height")
	assert(plot.CrossLane.Size.Z == 4 and plot.MainLane.Size.X == 4, "Commander lanes narrowed")
	local player = Players:GetPlayerByUserId(plot:GetAttribute("OwnerId"))
	assert(player, "Missing commander")
	deadline = os.clock() + 15
	repeat
		task.wait(0.1)
	until player.Character and player.Character:FindFirstChild("HumanoidRootPart") or os.clock() > deadline
	local character = player.Character
	assert(character and math.abs(character:GetScale() - 1) < 0.001, "Commander was miniaturized")
	assert(character.Humanoid.Health > 0, "Commander is not alive")
	assert(character.Humanoid.WalkSpeed == 32, "Commander walking speed was not doubled")
	assert(
		not player.Backpack:FindFirstChildOfClass("Tool") and not character:FindFirstChildOfClass("Tool"),
		"Commander is armed"
	)
	assert(State.housing(State.new("sparta", 0)) == 4, "Starter house does not provide four worker places")
	local originals = {}
	for _, id in { "b1", "b2", "b3" } do
		local building = plot.Buildings:FindFirstChild(id)
		assert(building, "Missing starter building: " .. id)
		originals[id] = building
		assert(math.abs(building:GetScale() - 0.25) < 0.001, "Wrong building scale")
		assert(
			building:GetAttribute("BuildingId") == id and building:GetAttribute("OwnerId") == player.UserId,
			"Unselectable ownership"
		)
		assert(
			building.SelectTarget.CanQuery
				and building.SelectTarget.ClickDetector
				and building.SelectTarget:FindFirstChildOfClass("ProximityPrompt"),
			"Missing query/interaction target"
		)
		if id == "b3" then
			local prompt = building.SelectTarget.CollectPrompt
			assert(
				prompt.ActionText == "Collect all"
					and prompt.KeyboardKeyCode == Enum.KeyCode.E
					and prompt:GetAttribute("CollectAll"),
				"Producer does not offer direct E collection"
			)
		end
		footprint(building, Catalog.buildings[building:GetAttribute("Kind")])
	end
	local previews = ReplicatedStorage.MiniatureGame:WaitForChild("Previews", 5)
	assert(previews and previews:FindFirstChild("sparta"), "Missing actual model thumbnails")
	local previewCount = 0
	for kind, definition in Catalog.buildings do
		local model = previews.sparta:FindFirstChild(kind)
		assert(model and math.abs(model:GetScale() - 0.25) < 0.001, "Missing miniature preview: " .. kind)
		assert(
			not model:FindFirstChildWhichIsA("ClickDetector", true)
				and not model:FindFirstChildWhichIsA("ProximityPrompt", true),
			"Preview can interact"
		)
		footprint(model, definition)
		previewCount += 1
	end
	local workers, assigned = {}, {}
	for _, actor in plot.Actors:GetChildren() do
		if actor:GetAttribute("PresentationRole") == "worker" then
			assert(math.abs(actor:GetScale() - 0.25) < 0.001, "Wrong worker scale")
			local humanoid = actor:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and not humanoid.EvaluateStateMachine and not humanoid.AutoRotate and humanoid.WalkSpeed == 0,
				"Worker Humanoid is active"
			)
			for _, item in actor:GetDescendants() do
				assert(not item:IsA("LuaSourceContainer"), "Worker imported a script")
				if item:IsA("BasePart") then
					assert(
						item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
						"Worker affects collision/query: " .. item:GetFullName()
					)
					assert(
						not PhysicsService:CollisionGroupsAreCollidable(item.CollisionGroup, "Default"),
						"Worker blocks commander group"
					)
				end
			end
			workers[actor] = actor:GetPivot().Position
			if actor:GetAttribute("BuildingId") then
				assert(actor:GetAttribute("BuildingId") == "b3", "Starter civilian assigned outside farm")
				assigned[actor] = true
			end
		end
	end
	local count = 0
	for _ in workers do
		count += 1
	end
	assert(count == 4, "Starter house must show four automatic civilians")
	local assignedCount = 0
	for _ in assigned do
		assignedCount += 1
	end
	assert(assignedCount == 2, "Starter farm must assign exactly two civilians, leaving two idle")
	local moved = {}
	for _ = 1, 140 do
		task.wait(0.1)
		for actor, initial in workers do
			for _, item in actor:GetDescendants() do
				if item:IsA("BasePart") then
					assert(
						item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
						"Worker lost passive flags during animation: " .. item:GetFullName()
					)
				end
			end
			local point = actor:GetPivot().Position
			if (point - initial).Magnitude > 0.6 then
				moved[actor] = true
			end
			local localPoint = plot.Plot.CFrame:PointToObjectSpace(point)
			assert(math.abs(localPoint.X) < 20 and math.abs(localPoint.Z) < 16, "Worker left plot")
			assert(point.Y > 0.4 and point.Y < 4, "Worker left ground band")
		end
	end
	for actor in workers do
		if assigned[actor] then
			assert(moved[actor], "Assigned worker never tended: " .. actor.Name)
		else
			assert(not actor:GetAttribute("BuildingId"), "Idle civilian acquired an unverified job")
		end
	end
	for id, building in originals do
		assert(plot.Buildings:FindFirstChild(id) == building, "Periodic update rebuilt building")
	end
	local troops = automaticTroopChecks(player.UserId)
	local ranges = rangeChecks(previews)
	local fingerprint = require(ServerStorage:WaitForChild("TemplateFingerprint", 5))
	assert(
		ReplicatedStorage:GetAttribute("OriginalSandboxTemplates") == fingerprint(),
		"Source templates changed or Edit baseline was not recorded"
	)
	return {
		workers = count,
		assigned = assignedCount,
		idle = count - assignedCount,
		previews = previewCount,
		observedSeconds = 14,
		housing = 4,
		troops = troops,
		ranges = ranges,
	}
end)
ReplicatedStorage:SetAttribute(
	"MiniatureGameSceneResult",
	game:GetService("HttpService"):JSONEncode({ ok = ok, result = result })
)
assert(ok, tostring(result))

--!strict
-- Native server factory checks; temporary scenery only, no profiles or live armies.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong mount structure fixture boundary"
	)
	local Shared = Replicated.MiniatureGame
	local Civilizations = require(Shared.Civilizations)
	local MountConfig = require(Shared.MountConfig)
	local Presentation = require(Shared.Presentation)
	local Structures = require(game:GetService("ServerScriptService").Sandbox.MountStructures)
	local fingerprint = require(ServerStorage.TemplateFingerprint)
	local before = fingerprint()
	local cues = {
		sparta = "LionRestingStone",
		britain = "StableBrickWing",
		seneca = "ForkedBrowseRack",
		mongols = "SmallFeltTackGerWall",
		vikings = "BearExerciseLog",
		persia = "LeopardRestPerch",
		japan = "TigerClimbingBeam",
		maurya = "ElephantWallow",
		spain = "ToroOctagonalWarPenStake",
		egypt = "CrocodileWarPool",
		rome = "RomanWolfRunArchPier",
		ottomans = "CamelCourtArcadePier",
		ming = "RhinoWallow",
	}
	local clones, signatures, rows = {}, {}, {}
	local ok, failure = pcall(function()
		for _, civilization in Civilizations do
			local definition = MountConfig.get(civilization.id)
			local model = Structures.create(civilization.id)
			table.insert(clones, model)
			assert(
				model.Parent == nil
					and math.abs(model:GetScale() - 0.25) < 0.001
					and model:GetPivot() == CFrame.identity,
				"Mount factory changed scale or spawn pivot"
			)
			assert(
				model:GetAttribute("CivilizationId") == civilization.id
					and model:GetAttribute("Kind") == "mount"
					and model:GetAttribute("MountStructure") == true,
				"Mount structure identity differs"
			)
			assert(
				model:GetAttribute("MountAnimal") == definition.animal
					and model:GetAttribute("DisplayName") == definition.structureName
					and Presentation.buildingName(civilization.id, "mount") == definition.structureName,
				"Mount art and shop naming disagree"
			)
			assert(
				model:GetAttribute("GameInterpretation") == true
					and type(model:GetAttribute("EvidenceCard")) == "string",
				"Fantasy facility lost reference boundary"
			)
			assert(model:FindFirstChild(cues[civilization.id], true), "Animal facility silhouette cue missing")
			local footing = model:FindFirstChild("MountFacilityFooting")
			assert(
				footing
					and footing:IsA("BasePart")
					and math.abs(footing.Size.X - 12) < 0.001
					and math.abs(footing.Size.Z - 10) < 0.001,
				"Mount structure footprint differs from placement"
			)
			local _, size = model:GetBoundingBox()
			assert(size.X <= 12.01 and size.Z <= 10.01, "Mount art overhangs its reserved footprint")
			local geometry, count = {}, 0
			for _, object in model:GetDescendants() do
				assert(
					not object:IsA("LuaSourceContainer")
						and not object:IsA("Humanoid")
						and not object:IsA("Tool")
						and not object:IsA("ProximityPrompt")
						and not object:IsA("ClickDetector"),
					"Mount scenery imported behavior or animals"
				)
				if object:IsA("BasePart") then
					count += 1
					assert(
						object.Anchored
							and not object.CanCollide
							and not object.CanTouch
							and (
								not object.CanQuery
								or (object == footing and object:GetAttribute("OriginalTroopSupport") == true)
							),
						"Mount scenery blocks commander"
					)
					local values = { object.Size.X, object.Size.Y, object.Size.Z, object.CFrame:GetComponents() }
					local formatted = {}
					for _, value in values do
						table.insert(formatted, string.format("%.4f", value))
					end
					table.insert(geometry, table.concat(formatted, ","))
				end
			end
			assert(count >= 15 and count <= 120, "Mount facility geometry budget differs")
			table.sort(geometry)
			local signature = table.concat(geometry, "|")
			assert(not signatures[signature], "Civilizations share only recolored mount geometry")
			signatures[signature] = true
			local preview = Shared:FindFirstChild("Previews")
			local culture = preview and preview:FindFirstChild(civilization.id)
			if culture then
				local registered = culture:FindFirstChild("mount")
				assert(
					registered and registered:GetAttribute("MountAnimal") == definition.animal,
					"Shop mount preview not registered for civilization"
				)
			end
			table.insert(rows, {
				civilizationId = civilization.id,
				animal = definition.animal,
				name = definition.structureName,
				parts = count,
				width = size.X,
				depth = size.Z,
			})
		end
		-- Exercise the legacy World population path through the same role metadata
		-- consumed by ordinary roster inspectors, without touching a claimed plot.
		local World = require(game:GetService("ServerScriptService").Sandbox.World)
		local State = require(game:GetService("ServerScriptService").Sandbox.State)
		local container = Instance.new("Model")
		table.insert(clones, container)
		local buildings, actors = Instance.new("Folder"), Instance.new("Folder")
		buildings.Name, buildings.Parent, actors.Name, actors.Parent = "Buildings", container, "Actors", container
		local plot = { model = container, buildings = buildings, actors = actors, frame = CFrame.identity }
		local state = State.new("sparta", 0)
		table.insert(state.buildings, { id = "b4", kind = "mount", x = 26, z = -8, rotation = 0, output = 0 })
		state.nextBuildingId = 5
		assert(State.validate(state, "sparta"), "Passive mounted population fixture invalid")
		World.render(plot, state, 0)
		local mounted, count = nil, 0
		for _, actor in actors:GetChildren() do
			if actor:GetAttribute("PresentationRole") == "roster" then
				assert(
					actor:GetAttribute("RosterRole") == "mounted"
						and actor:GetAttribute("MountedVisual") == true
						and actor:GetAttribute("BuildingId") == "b4",
					"Passive roster consumer cannot identify mounted group"
				)
				mounted, count = actor, count + 1
			end
		end
		assert(count == 1 and mounted, "Passive population did not render exactly one mounted troop")
		World.update(plot, state, 1)
		assert(actors:FindFirstChild(mounted.Name) == mounted, "Passive mounted refresh rebuilt the living visual")
		table.remove(state.buildings, #state.buildings)
		World.update(plot, state, 2)
		assert(mounted.Parent == nil, "Removed mount facility retained its passive roster actor")
		World.clear(plot)
		assert(#rows == 13, "Mount facility civilization coverage incomplete")
	end)
	for _, model in clones do
		model:Destroy()
	end
	assert(fingerprint() == before, "Mount factory mutated original templates")
	local result = { civilizations = #rows, models = rows, sourceTemplatesImmutable = true, liveArmyMutation = false }
	Replicated:SetAttribute(
		"MiniatureMountStructuresResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = if ok then result else tostring(failure) })
	)
	assert(ok, failure)
	return result
end
return run

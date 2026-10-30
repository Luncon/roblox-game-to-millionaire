--!strict
-- Map only into the injected-fake-store Studio test place. No live profile access.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.PersianKit)
local SpartanKit = require(game.ServerScriptService.Sandbox.SpartanKit)

local function inert(model)
	assert(not model:FindFirstChildWhichIsA("Humanoid", true), "Presentation has a Humanoid")
	assert(not model:FindFirstChildWhichIsA("Tool", true), "Presentation has a Tool")
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Persian art")
		if item:IsA("BasePart") then
			assert(
				item.Anchored
					and not item.CanCollide
					and not item.CanTouch
					and (
						not item.CanQuery
						or (
							model:GetAttribute("MountStructure") == true
							and item.Name == "MountFacilityFooting"
							and item:GetAttribute("OriginalTroopSupport") == true
						)
					),
				"Active Persian art"
			)
		end
	end
end

local function footprint(model, definition)
	local pivot = model:GetPivot()
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(math.abs(corner.X) <= definition.width / 2 + 0.01, "Persian footprint width exceeded")
						assert(math.abs(corner.Z) <= definition.depth / 2 + 0.01, "Persian footprint depth exceeded")
					end
				end
			end
		end
	end
end

local temporary = Instance.new("Folder")
temporary.Name = "PersianKitVerification"
local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Persian scene fixture requires Studio")
	local deadline = os.clock() + 15
	while ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == nil and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong test boundary"
	)
	local total, parts = 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Persian catalog role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("persia") else Kit.create(kind))
		model.Parent = temporary
		assert(model:GetAttribute("CivilizationId") == "persia", "Wrong civilization")
		assert(
			model:GetAttribute("Kind") == kind
				and model:GetAttribute("EvidenceCard") == "docs/notes/Persian Sandbox Art.md",
			"Missing evidence metadata"
		)
		assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Persian scale")
		assert(
			not model:FindFirstChild("TerracottaRoof", true) and not model:FindFirstChild("RoundedCoverTiles", true),
			"Spartan roof substituted"
		)
		assert(
			not model:FindFirstChild("Dome", true) and not model:FindFirstChild("Minaret", true),
			"Later architecture substituted"
		)
		if kind ~= "civic" then
			assert(not model:FindFirstChild("BullCapitalBody", true), "Royal capitals on ordinary building")
		end
		inert(model)
		for _, rotation in { 0, 90, 180, 270 } do
			model:PivotTo(CFrame.new(13, 2, -7) * CFrame.Angles(0, math.rad(rotation), 0))
			footprint(model, definition)
		end
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
			end
		end
		total += 1
	end
	assert(total == 11 and parts < 700, "Incomplete or excessive Persian kit")
	local house = Kit.create("house")
	house.Parent = temporary
	local spartan = SpartanKit.create("house")
	spartan.Parent = temporary
	assert(
		house:FindFirstChild("EarthRoof", true) and house:FindFirstChild("ExposedRoofBeam", true),
		"Missing flat timber/earth roof"
	)
	assert(
		spartan:FindFirstChild("TerracottaRoof", true) and not spartan:FindFirstChild("EarthRoof", true),
		"Domestic geometry is not distinct"
	)
	assert(
		temporary.civic:FindFirstChild("BullCapitalBody", true) and temporary.civic:FindFirstChild("TerraceStep", true),
		"Civic terrace vocabulary missing"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("RosterRole") == role,
			"Wrong Persian actor metadata"
		)
		assert(
			actor:GetAttribute("CivilizationId") == "persia" and math.abs(actor:GetScale() - 0.25) < 0.001,
			"Wrong actor civilization/scale"
		)
		assert(
			actor:FindFirstChild("SleevedRobe") and actor:FindFirstChild("SoftCap"),
			"Persian clothing silhouette missing"
		)
		assert(actor.Head.face.Texture == "rbxassetid://10526794", "Wrong presentation face")
		local colors = actor:FindFirstChildOfClass("BodyColors")
		assert(
			colors and colors.HeadColor3 == actor.Head.Color and colors.TorsoColor3 == actor.Torso.Color,
			"Inconsistent actor skin palette"
		)
		if role == "melee" then
			assert(
				actor:FindFirstChild("SpearShaft") and actor:FindFirstChild("WickerShield"),
				"Frontline props missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("BowLimb") and actor:FindFirstChild("BowString") and actor:FindFirstChild("Quiver"),
				"Archer props missing"
			)
		else
			assert(
				actor:FindFirstChild("FoldedBandage") and not actor:FindFirstChild("SpearShaft"),
				"Support props missing"
			)
		end
		inert(actor)
		footprint(actor, { width = 2, depth = 2 })
	end
	assert(not Kit.available("unknown"), "Unknown role advertised")
	return { buildings = total, actors = 3, parts = parts }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("PersiaScenePassed", ok)
ReplicatedStorage:SetAttribute("PersiaSceneResult", if ok then "10 buildings / 3 inert roles" else tostring(result))
assert(ok, tostring(result))
print("PASS miniature Persian native kit", result)

--!strict
-- Map only into the injected-fake-store Studio test place; never accesses live storage.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.OttomanKit)
local SpartanKit = require(game.ServerScriptService.Sandbox.SpartanKit)
local temporary = Instance.new("Folder")
temporary.Name = "OttomanKitVerification"
local function inert(model)
	assert(not model:FindFirstChildWhichIsA("Humanoid", true), "Ottoman art has a Humanoid")
	assert(not model:FindFirstChildWhichIsA("Tool", true), "Ottoman art has a Tool")
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Ottoman art")
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
				"Active Ottoman art"
			)
		end
	end
end
local function footprint(model, width, depth)
	local pivot = model:GetPivot()
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = pivot:PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(
							math.abs(corner.X) <= width / 2 + 0.01,
							"Ottoman footprint width exceeded: " .. model.Name
						)
						assert(
							math.abs(corner.Z) <= depth / 2 + 0.01,
							"Ottoman footprint depth exceeded: " .. model.Name
						)
					end
				end
			end
		end
	end
end
local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Ottoman native fixture requires Studio")
	local deadline = os.clock() + 15
	while ReplicatedStorage:GetAttribute("MiniatureSandboxReady") ~= true and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxReady") == true
			and ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong test boundary"
	)
	local buildings, parts, rotations = 0, 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Ottoman role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("ottomans") else Kit.create(kind))
		model.Parent = temporary
		assert(
			model:GetAttribute("CivilizationId") == "ottomans" and model:GetAttribute("Kind") == kind,
			"Wrong Ottoman identity"
		)
		assert(model:GetAttribute("EvidenceCard") == "docs/notes/Ottoman Sandbox Art.md", "Missing evidence card")
		assert(model:GetAttribute("HistoricalPeriod") == "Ottoman Empire · 1520–1566 CE", "Wrong period metadata")
		assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Ottoman scale")
		inert(model)
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
				assert(not string.find(item.Name, "Pylon", 1, true), "Egyptian pylon substituted")
				assert(not string.find(item.Name, "TerracottaRoof", 1, true), "Greek roof substituted")
				assert(not string.find(item.Name, "Column", 1, true), "Classical colonnade substituted")
				assert(not string.find(item.Name, "Minaret", 1, true), "Warehouse minaret substituted")
				local domeName = string.find(item.Name, "Dome", 1, true)
					and not string.find(item.Name, "Domestic", 1, true)
				assert(not domeName, "Universal domed architecture substituted")
				if item:IsA("Part") and item.Shape == Enum.PartType.Ball then
					assert(item.Name == "PlainClayJar", "Architectural dome substituted for a modest roof")
				end
			end
		end
		for _, rotation in { 0, 90, 180, 270 } do
			model:PivotTo(CFrame.new(-17, 3, 11) * CFrame.Angles(0, math.rad(rotation), 0))
			footprint(model, definition.width, definition.depth)
			rotations += 1
		end
		buildings += 1
	end
	assert(buildings == 11 and parts < 700, "Incomplete or excessive Ottoman kit")
	assert(
		temporary.house:FindFirstChild("TimberPlasterRoom") and temporary.house:FindFirstChild("HippedTileRoofFacet"),
		"Modest timber/plaster hipped house missing"
	)
	assert(
		temporary.civic:FindFirstChild("HanEntryVoussoir") and temporary.civic:FindFirstChild("HanBrickCourse"),
		"Selective civic han masonry missing"
	)
	assert(
		temporary.storehouse:FindFirstChild("SecureStoreDoubleDoor")
			and temporary.storehouse:FindFirstChild("GoodsChest"),
		"Storage role missing"
	)
	assert(
		temporary.workshop:FindFirstChild("BrickFiringChamber")
			and temporary.workshop:FindFirstChild("GlazedDishAbstraction"),
		"Potter craft role missing"
	)
	assert(
		temporary.farm:FindFirstChild("GrainEar") and temporary.material:FindFirstChild("PreparedClayStock"),
		"Production roles missing"
	)
	assert(
		temporary.timber:FindFirstChild("CarpenterBench") and temporary.training:FindFirstChild("WovenArcheryTarget"),
		"Woodworking/training roles missing"
	)
	assert(temporary.healer:FindFirstChild("LinenCouch"), "Treatment role missing")
	local spartan = SpartanKit.create("house")
	spartan.Parent = temporary
	assert(
		spartan:FindFirstChild("TerracottaRoof") and not spartan:FindFirstChild("HippedTileRoofFacet"),
		"Spartan/Ottoman roof construction not distinct"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		assert(
			actor:GetAttribute("CivilizationId") == "ottomans" and actor:GetAttribute("RosterRole") == role,
			"Wrong actor identity"
		)
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("PresentationRole") == "roster",
			"Wrong actor authority"
		)
		assert(math.abs(actor:GetScale() - 0.25) < 0.001, "Wrong actor scale")
		assert(
			actor:FindFirstChild("PlainSleevedCoat") and actor.Head.face.Texture == "rbxassetid://10526794",
			"Clothing or established face missing"
		)
		local bodyColors = actor:FindFirstChildOfClass("BodyColors")
		assert(
			bodyColors and bodyColors.HeadColor3 == actor.Head.Color and bodyColors.TorsoColor3 == actor.Torso.Color,
			"Actor palette inconsistent"
		)
		if role == "melee" then
			assert(
				actor:FindFirstChild("SaberGrip") and actor:FindFirstChild("CurvedSaberBlade"),
				"Infantry silhouette missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("RecurvedBowLimb")
					and actor:FindFirstChild("BowString")
					and actor:FindFirstChild("ArrowQuiver"),
				"Archer silhouette missing"
			)
		else
			assert(
				actor:FindFirstChild("FoldedBandage")
					and not actor:FindFirstChild("SaberGrip")
					and not actor:FindFirstChild("RecurvedBowLimb"),
				"Unarmed support silhouette missing"
			)
		end
		assert(
			not actor:FindFirstChildOfClass("VehicleSeat") and not actor:FindFirstChild("Horse"),
			"Mounted gameplay introduced"
		)
		inert(actor)
		footprint(actor, 2, 2)
	end
	assert(not Kit.available("unknown"), "Unknown Ottoman role advertised")
	return { buildings = buildings, actors = 3, parts = parts, cardinalFootprints = rotations }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("OttomanScenePassed", ok)
ReplicatedStorage:SetAttribute(
	"OttomanSceneResult",
	if ok then game:GetService("HttpService"):JSONEncode(result) else tostring(result)
)
assert(ok, tostring(result))
print("PASS miniature Ottoman native kit", result)

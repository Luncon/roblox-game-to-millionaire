--!strict
-- Map only into the injected-fake-store Studio test place; never accesses live storage.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.VikingKit)
local SpartanKit = require(game.ServerScriptService.Sandbox.SpartanKit)
local temporary = Instance.new("Folder")
temporary.Name = "VikingKitVerification"
local function inert(model)
	assert(not model:FindFirstChildWhichIsA("Humanoid", true), "Viking art has a Humanoid")
	assert(not model:FindFirstChildWhichIsA("Tool", true), "Viking art has a Tool")
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Viking art")
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
				"Active Viking art"
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
							"Viking footprint width exceeded: " .. model.Name
						)
						assert(
							math.abs(corner.Z) <= depth / 2 + 0.01,
							"Viking footprint depth exceeded: " .. model.Name
						)
					end
				end
			end
		end
	end
end
local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Viking native fixture requires Studio")
	local deadline = os.clock() + 15
	while ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == nil and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong test boundary"
	)
	local buildings, parts, rotations = 0, 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Viking role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("vikings") else Kit.create(kind))
		model.Parent = temporary
		assert(
			model:GetAttribute("CivilizationId") == "vikings" and model:GetAttribute("Kind") == kind,
			"Wrong Viking identity"
		)
		assert(model:GetAttribute("EvidenceCard") == "docs/notes/Viking Sandbox Art.md", "Missing evidence card")
		assert(
			model:GetAttribute("HistoricalPeriod") == "Southern Scandinavia · 900–1050 CE",
			"Wrong period metadata"
		)
		assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Viking scale")
		inert(model)
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
				assert(not string.find(item.Name, "Pylon", 1, true), "Egyptian pylon substituted")
				assert(not string.find(item.Name, "TerracottaRoof", 1, true), "Greek roof substituted")
				assert(not string.find(item.Name, "Column", 1, true), "Classical colonnade substituted")
				assert(not string.find(item.Name, "Chimney", 1, true), "Unverified later chimney substituted")
			end
		end
		for _, rotation in { 0, 90, 180, 270 } do
			model:PivotTo(CFrame.new(-17, 3, 11) * CFrame.Angles(0, math.rad(rotation), 0))
			footprint(model, definition.width, definition.depth)
			rotations += 1
		end
		buildings += 1
	end
	assert(buildings == 11 and parts < 500, "Incomplete or excessive Viking kit")
	assert(
		temporary.house:FindFirstChild("CurvedTimberLongwall") and temporary.house:FindFirstChild("ThatchRoofSection"),
		"Curved timber/thatched house missing"
	)
	assert(
		temporary.civic:FindFirstChild("SlopingRoofSupport") and temporary.civic:FindFirstChild("ExchangeBoardCounter"),
		"Hall and exchange role missing"
	)
	assert(
		temporary.storehouse:FindFirstChild("RaisedStoreFloor")
			and temporary.storehouse:FindFirstChild("GrainStorageChest"),
		"Storage role missing"
	)
	assert(
		temporary.workshop:FindFirstChild("PotterWorkingBoard")
			and temporary.workshop:FindFirstChild("PotteryFiringBed"),
		"Potter craft role missing"
	)
	assert(
		temporary.material:FindFirstChild("ClayGatheringBed") and temporary.farm:FindFirstChild("CerealEar"),
		"Gathering/farm role missing"
	)
	assert(
		temporary.training:FindFirstChild("RoundPracticeShield") and temporary.healer:FindFirstChild("LinenCouchCover"),
		"Practice/treatment role missing"
	)
	local spartan = SpartanKit.create("house")
	spartan.Parent = temporary
	assert(
		spartan:FindFirstChild("TerracottaRoof") and not spartan:FindFirstChild("CurvedTimberLongwall"),
		"Spartan/Viking houses not distinct"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		assert(
			actor:GetAttribute("CivilizationId") == "vikings" and actor:GetAttribute("RosterRole") == role,
			"Wrong actor identity"
		)
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("PresentationRole") == "roster",
			"Wrong actor authority"
		)
		assert(math.abs(actor:GetScale() - 0.25) < 0.001, "Wrong actor scale")
		assert(
			actor:FindFirstChild("WoolTunic") and actor.Head.face.Texture == "rbxassetid://10526794",
			"Clothing or established face missing"
		)
		local bodyColors = actor:FindFirstChildOfClass("BodyColors")
		assert(
			bodyColors and bodyColors.HeadColor3 == actor.Head.Color and bodyColors.TorsoColor3 == actor.Torso.Color,
			"Actor palette inconsistent"
		)
		if role == "melee" then
			assert(
				actor:FindFirstChild("AxeHaft") and actor:FindFirstChild("RoundWoodShield"),
				"Infantry silhouette missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("SelfBowLimb")
					and actor:FindFirstChild("BowString")
					and actor:FindFirstChild("ArrowQuiver"),
				"Archer silhouette missing"
			)
		else
			assert(
				actor:FindFirstChild("FoldedBandage")
					and not actor:FindFirstChild("AxeHaft")
					and not actor:FindFirstChild("SelfBowLimb"),
				"Unarmed support silhouette missing"
			)
		end
		for _, item in actor:GetDescendants() do
			assert(not string.find(item.Name, "Horn", 1, true), "Horned helmet substituted")
		end
		inert(actor)
		footprint(actor, 2, 2)
	end
	assert(not Kit.available("unknown"), "Unknown Viking role advertised")
	return { buildings = buildings, actors = 3, parts = parts, cardinalFootprints = rotations }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("VikingScenePassed", ok)
ReplicatedStorage:SetAttribute(
	"VikingSceneResult",
	if ok then game:GetService("HttpService"):JSONEncode(result) else tostring(result)
)
assert(ok, tostring(result))
print("PASS miniature Viking native kit", result)

--!strict
-- Separate injected-fake-store Studio fixture. No player state is mutated.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.SenecaKit)
local temporary = Instance.new("Folder")
temporary.Name = "SenecaKitVerification"

local function checkModel(model, definition)
	assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Seneca scale")
	assert(model:GetAttribute("CivilizationId") == "seneca", "Wrong civilization")
	assert(
		not model:FindFirstChildWhichIsA("Humanoid", true) and not model:FindFirstChildWhichIsA("Tool", true),
		"Active Seneca presentation"
	)
	local parts = 0
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Seneca art")
		if item:IsA("BasePart") then
			parts += 1
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
				"Seneca art blocks interactions"
			)
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = model:GetPivot():PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(math.abs(corner.X) <= definition.width / 2 + 0.01, "Seneca art exceeds width")
						assert(math.abs(corner.Z) <= definition.depth / 2 + 0.01, "Seneca art exceeds depth")
					end
				end
			end
		end
	end
	return parts
end

local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Seneca scene fixture requires Studio")
	local deadline = os.clock() + 15
	while ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == nil and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong verification boundary"
	)
	local count, parts = 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Seneca role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("seneca") else Kit.create(kind))
		model.Parent = temporary
		assert(
			model:GetAttribute("Kind") == kind
				and model:GetAttribute("EvidenceCard") == "docs/notes/Seneca Sandbox Art.md",
			"Missing Seneca metadata"
		)
		parts += checkModel(model, definition)
		for _, rotation in { 90, 180, 270 } do
			model:PivotTo(CFrame.new(-23, 4, 19) * CFrame.Angles(0, math.rad(rotation), 0))
			checkModel(model, definition)
		end
		assert(
			not model:FindFirstChild("TerracottaRoof", true) and not model:FindFirstChild("DragonGable", true),
			"Foreign roof form used"
		)
		assert(
			not model:FindFirstChild("TotemPole", true) and not model:FindFirstChild("Tipi", true),
			"Unreviewed pan-Indigenous substitution"
		)
		count += 1
	end
	assert(count == 11 and parts < 700, "Incomplete or excessive Seneca catalog")
	local house = temporary.house
	assert(
		house:FindFirstChild("BarkArchPanel", true) and house:FindFirstChild("BarkFiberLashing", true),
		"Bark barrel structure missing"
	)
	assert(
		house:FindFirstChild("SmokeOpeningRim", true) and house:FindFirstChild("InteriorPlatform", true),
		"Longhouse structure missing"
	)
	assert(
		temporary.farm:FindFirstChild("CornEar", true)
			and temporary.farm:FindFirstChild("BeanVine", true)
			and temporary.farm:FindFirstChild("Squash", true),
		"Three Sisters incomplete"
	)
	assert(
		temporary.storehouse:FindFirstChild("RaisedStoragePlatform", true)
			and temporary.storehouse:FindFirstChild("HangingCorn", true),
		"Food storage silhouette missing"
	)
	assert(
		temporary.workshop:FindFirstChild("OpenFiringBed", true)
			and not temporary.workshop:FindFirstChild("PotteryKiln", true),
		"Foreign kiln copied"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		checkModel(actor, { width = 2, depth = 2 })
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("RosterRole") == role,
			"Wrong passive role"
		)
		assert(
			actor:FindFirstChild("PlainUpperGarment")
				and actor:FindFirstChild("Left Legging")
				and actor:FindFirstChild("Right Moccasin"),
			"Everyday clothing silhouette missing"
		)
		assert(
			not actor:FindFirstChild("WarBonnet") and not actor:FindFirstChild("ClanEmblem"),
			"Unverified regalia added"
		)
		local palette = actor:FindFirstChildOfClass("BodyColors")
		assert(
			palette and palette.HeadColor3 == actor.Head.Color and palette.TorsoColor3 == actor.Torso.Color,
			"Inconsistent skin palette"
		)
		assert(actor.Head.face.Texture == "rbxassetid://10526794", "Wrong project face")
		if role == "melee" then
			assert(
				actor:FindFirstChild("WoodenClubHandle") and actor:FindFirstChild("PlainClubHead"),
				"Frontline props missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("BowLimb")
					and actor:FindFirstChild("BowString")
					and actor:FindFirstChild("ArrowCase"),
				"Archer props missing"
			)
		else
			assert(
				actor:FindFirstChild("PlainSupplyBag")
					and actor:FindFirstChild("FoldedCloth")
					and not actor:FindFirstChild("WoodenClubHandle"),
				"Support props missing"
			)
		end
	end
	return { buildings = count, actors = 3, buildingParts = parts }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("SenecaScenePassed", ok)
ReplicatedStorage:SetAttribute("SenecaSceneResult", if ok then "10 buildings / 3 inert roles" else tostring(result))
assert(ok, tostring(result))
print("PASS miniature Seneca native kit", result)

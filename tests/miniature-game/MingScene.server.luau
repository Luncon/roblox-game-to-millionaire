--!strict
-- Run only in the separately mapped injected-fake-store Studio test place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.MingKit)
local temporary = Instance.new("Folder")
temporary.Name = "MingKitVerification"

local function check(model, definition)
	assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Ming scale")
	assert(model:GetAttribute("CivilizationId") == "ming", "Wrong Ming civilization")
	assert(
		not model:FindFirstChildWhichIsA("Humanoid", true) and not model:FindFirstChildWhichIsA("Tool", true),
		"Ming presentation has active actor objects"
	)
	local count = 0
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Ming art")
		if item:IsA("BasePart") then
			count += 1
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
				"Active Ming geometry"
			)
			if item.Name == "GreyTileSlope" or item.Name == "TileCourse" or item.Name == "PlainTileRidge" then
				assert(item.Color == Color3.fromRGB(77, 85, 84), "Universal imperial yellow roof substituted")
			end
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = model:GetPivot():PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(math.abs(corner.X) <= definition.width / 2 + 0.01, "Ming footprint width exceeded")
						assert(math.abs(corner.Z) <= definition.depth / 2 + 0.01, "Ming footprint depth exceeded")
					end
				end
			end
		end
	end
	return count
end

local ok, result = pcall(function()
	local deadline = os.clock() + 15
	while ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == nil and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(game:GetService("RunService"):IsStudio(), "Ming scene fixture requires Studio")
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong verification boundary"
	)
	local roles, parts = 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Ming catalog role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("ming") else Kit.create(kind))
		model.Parent = temporary
		assert(
			model:GetAttribute("Kind") == kind
				and model:GetAttribute("EvidenceCard") == "docs/notes/Ming Sandbox Art.md",
			"Missing Ming metadata"
		)
		parts += check(model, definition)
		for _, rotation in { 90, 180, 270 } do
			model:PivotTo(CFrame.new(17, 3, -29) * CFrame.Angles(0, math.rad(rotation), 0))
			check(model, definition)
		end
		assert(
			not model:FindFirstChild("CastleTier", true)
				and not model:FindFirstChild("ToriiGate", true)
				and not model:FindFirstChild("Shachihoko", true),
			"Japanese castle/shrine vocabulary substituted"
		)
		if kind ~= "civic" then
			assert(
				not model:FindFirstChild("BracketBlock", true),
				"Monumental bracketing applied to every ordinary role"
			)
		end
		roles += 1
	end
	assert(roles == 11 and parts < 700, "Incomplete or excessive Ming kit")
	assert(
		temporary.house:FindFirstChild("SkywellCourt", true) and temporary.house:FindFirstChild("CourtDrain", true),
		"Domestic skywell missing"
	)
	assert(
		temporary.house:FindFirstChild("SteppedFirewall", true)
			and temporary.house:FindFirstChild("GreyFirewallCap", true),
		"Stepped enclosing walls missing"
	)
	assert(
		temporary.civic:FindFirstChild("PublicCourtyard", true) and temporary.civic:FindFirstChild("CivicColumn", true),
		"Selective civic structure missing"
	)
	assert(
		temporary.workshop:FindFirstChild("GourdKilnChamber", true)
			and temporary.workshop:FindFirstChild("CeramicDryingBench", true),
		"Kiln/workshop silhouette missing"
	)
	assert(
		temporary.timber:FindFirstChild("JoineryBench", true) and temporary.farm:FindFirstChild("PaddyBank", true),
		"Production roles lack distinct structure"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		check(actor, { width = 2, depth = 2 })
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("RosterRole") == role,
			"Wrong Ming passive role"
		)
		assert(
			actor:FindFirstChild("PlainRobe")
				and actor:FindFirstChild("Left Trouser")
				and actor:FindFirstChild("Right Shoe"),
			"Plain Ming clothing missing"
		)
		local palette = actor:FindFirstChildOfClass("BodyColors")
		assert(
			palette and palette.HeadColor3 == actor.Head.Color and palette.TorsoColor3 == actor.Torso.Color,
			"Inconsistent skin palette"
		)
		assert(actor.Head.face.Texture == "rbxassetid://10526794", "Wrong project face")
		if role == "melee" then
			assert(actor:FindFirstChild("SpearShaft") and actor:FindFirstChild("ArmorPlate"), "Spear candidate missing")
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("BowLimb")
					and actor:FindFirstChild("BowString")
					and actor:FindFirstChild("PlainQuiver"),
				"Bow candidate missing"
			)
		else
			assert(
				actor:FindFirstChild("CareSatchel")
					and actor:FindFirstChild("FoldedBandage")
					and not actor:FindFirstChild("SpearShaft"),
				"Support candidate missing"
			)
		end
		assert(
			not actor:FindFirstChild("Matchlock") and not actor:FindFirstChild("Cannon"),
			"Unimplemented powder role advertised"
		)
	end
	return { buildings = roles, actors = 3, buildingParts = parts }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("MingScenePassed", ok)
ReplicatedStorage:SetAttribute("MingSceneResult", if ok then "10 buildings / 3 inert roles" else tostring(result))
assert(ok, tostring(result))
print("PASS miniature Ming native kit", result)

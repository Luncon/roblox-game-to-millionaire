--!strict
-- Temporary original models only; no player state or live storage access.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local Kit = require(game.ServerScriptService.Sandbox.SpanishKit)
local temporary = Instance.new("Folder")
temporary.Name = "SpanishKitVerification"

local function check(model, definition)
	assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong Spanish scale")
	assert(model:GetAttribute("CivilizationId") == "spain", "Wrong civilization")
	assert(
		not model:FindFirstChildWhichIsA("Humanoid", true) and not model:FindFirstChildWhichIsA("Tool", true),
		"Active Spanish actor objects"
	)
	local count = 0
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Executable Spanish art")
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
				"Spanish art blocks interaction"
			)
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local corner = model:GetPivot():PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(math.abs(corner.X) <= definition.width / 2 + 0.01, "Spanish footprint width exceeded")
						assert(math.abs(corner.Z) <= definition.depth / 2 + 0.01, "Spanish footprint depth exceeded")
					end
				end
			end
		end
	end
	return count
end

local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "Spanish scene fixture requires Studio")
	local deadline = os.clock() + 15
	repeat
		if ReplicatedStorage:GetAttribute("MiniatureSandboxReady") then
			break
		end
		task.wait(0.05)
	until os.clock() >= deadline
	assert(ReplicatedStorage:GetAttribute("MiniatureSandboxReady"), "Sandbox did not become ready in 15 seconds")
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong verification boundary"
	)
	local roles, parts = 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or Kit.available(kind)), "Missing Spanish role: " .. kind)
		local model = (if kind == "mount" then MountStructures.create("spain") else Kit.create(kind))
		model.Parent = temporary
		assert(
			model:GetAttribute("Kind") == kind
				and model:GetAttribute("EvidenceCard") == "docs/notes/Spanish Sandbox Art.md",
			"Missing evidence metadata"
		)
		parts += check(model, definition)
		for _, rotation in { 90, 180, 270 } do
			model:PivotTo(CFrame.new(31, 3, -17) * CFrame.Angles(0, math.rad(rotation), 0))
			check(model, definition)
		end
		assert(
			not model:FindFirstChild("MissionBellGable", true) and not model:FindFirstChild("BaroqueScroll", true),
			"Later mission/Baroque forms substituted"
		)
		assert(
			not model:FindFirstChild("Minaret", true) and not model:FindFirstChild("Dome", true),
			"Foreign universal roof substituted"
		)
		if kind ~= "civic" then
			assert(not model:FindFirstChild("StoneArcadePier", true), "Civic arcade applied to every role")
		end
		roles += 1
	end
	assert(roles == 11 and parts < 700, "Incomplete or excessive Spanish kit")
	assert(
		temporary.house:FindFirstChild("TimberPatioPost", true)
			and temporary.house:FindFirstChild("UpperTimberGallery", true),
		"Domestic timber patio missing"
	)
	assert(
		temporary.house:FindFirstChild("PatioPaving", true)
			and not temporary.house:FindFirstChild("StoneArcadePier", true),
		"Domestic patio replaced by civic arcade"
	)
	assert(
		temporary.civic:FindFirstChild("ArcadeVoussoir", true)
			and temporary.civic:FindFirstChild("UpperMarketGallery", true),
		"Selective market loggia missing"
	)
	assert(
		temporary.workshop:FindFirstChild("KilnCombustionChamber", true)
			and temporary.timber:FindFirstChild("CarpenterBench", true),
		"Work roles lack distinct props"
	)
	for _, role in { "melee", "ranged", "medic" } do
		local actor = Kit.createActor(role)
		actor.Parent = temporary
		check(actor, { width = 2, depth = 2 })
		assert(
			actor:GetAttribute("PresentationOnly") and actor:GetAttribute("RosterRole") == role,
			"Wrong Spanish passive role"
		)
		assert(
			actor:FindFirstChild("PlainDoublet")
				and actor:FindFirstChild("PlainBreeches")
				and actor:FindFirstChild("Left Hose"),
			"Period clothing silhouette missing"
		)
		local palette = actor:FindFirstChildOfClass("BodyColors")
		assert(
			palette and palette.HeadColor3 == actor.Head.Color and palette.TorsoColor3 == actor.Torso.Color,
			"Inconsistent skin palette"
		)
		assert(actor.Head.face.Texture == "rbxassetid://10526794", "Wrong project face")
		if role == "melee" then
			assert(
				actor:FindFirstChild("PikeShaft") and actor:FindFirstChild("MorionComb"),
				"Pikeman candidate missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("CrossbowStock")
					and actor:FindFirstChild("CrossbowLimb")
					and actor:FindFirstChild("CrossbowString"),
				"Crossbow candidate missing"
			)
		else
			assert(
				actor:FindFirstChild("CareSatchel")
					and actor:FindFirstChild("FoldedBandage")
					and not actor:FindFirstChild("PikeShaft"),
				"Support candidate missing"
			)
		end
		assert(
			not actor:FindFirstChild("Musket") and not actor:FindFirstChild("Cannon"),
			"Unimplemented powder role advertised"
		)
	end
	return { buildings = roles, actors = 3, buildingParts = parts }
end)
temporary:Destroy()
ReplicatedStorage:SetAttribute("SpainScenePassed", ok)
ReplicatedStorage:SetAttribute("SpainSceneResult", if ok then "10 buildings / 3 inert roles" else tostring(result))
assert(ok, tostring(result))
print("PASS miniature Spanish native kit", result)

--!strict
-- Native geometry checks; does not select a civilization or mutate player state.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
-- Shared mount facilities extend each catalog without changing the original kit factories.
local MountStructures = require(game.ServerScriptService.Sandbox.MountStructures)
local BritishKit = require(game.ServerScriptService.Sandbox.BritishKit)
local SpartanKit = require(game.ServerScriptService.Sandbox.SpartanKit)
local RomanKit = require(game.ServerScriptService.Sandbox.RomanKit)
local created = {}

local function keep(model)
	table.insert(created, model)
	return model
end

local function inspect(model, width, depth)
	assert(model.Parent == nil, "Kit factory parents its output")
	assert(math.abs(model:GetScale() - 0.25) < 0.001, "Wrong British scale")
	assert(model:GetAttribute("CivilizationId") == "britain", "Wrong British identity")
	assert(model:GetAttribute("EvidenceCard") == "docs/notes/British Sandbox Art.md", "Missing British evidence")
	local count = 0
	for _, item in model:GetDescendants() do
		assert(
			not item:IsA("LuaSourceContainer") and not item:IsA("Tool") and not item:IsA("Humanoid"),
			"Kit includes behavior"
		)
		assert(not item:IsA("ProximityPrompt") and not item:IsA("ClickDetector"), "Factory art includes interactions")
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
				"British part is active: " .. item.Name
			)
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local point = model:GetPivot():PointToObjectSpace(
							item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2)
						)
						assert(
							math.abs(point.X) <= width / 2 + 0.01 and math.abs(point.Z) <= depth / 2 + 0.01,
							"British art exceeds footprint: " .. model.Name .. "." .. item.Name
						)
						assert(point.Y >= -0.01, "British art penetrates foundation: " .. item.Name)
					end
				end
			end
		end
	end
	assert(count > 0, "Empty British model")
	return count
end

-- Ignore names, colours and materials: recolouring/renaming Spartan art cannot pass.
local function shapeSignature(model)
	local rows = {}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			local values =
				{ item.Size.X, item.Size.Y, item.Size.Z, model:GetPivot():ToObjectSpace(item.CFrame):GetComponents() }
			for index, value in values do
				local rounded = math.round(value * 1000) / 1000
				values[index] = string.format("%.3f", if rounded == 0 then 0 else rounded)
			end
			table.insert(rows, table.concat(values, ","))
		end
	end
	table.sort(rows)
	return table.concat(rows, ";")
end

local function capturePose(model)
	local pose = {}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			pose[item] = { size = item.Size, frame = model:GetPivot():ToObjectSpace(item.CFrame) }
		end
	end
	return pose
end

local maximumDrift = 0
local function assertPose(model, pose)
	for item, original in pose do
		assert(item:IsDescendantOf(model), "British relocation removed a part")
		local frame = model:GetPivot():ToObjectSpace(item.CFrame)
		local drift = (frame.Position - original.frame.Position).Magnitude
		maximumDrift = math.max(maximumDrift, drift)
		assert((item.Size - original.size).Magnitude < 0.0001, "British relocation resized: " .. item.Name)
		assert(drift < 0.001, "British relocation displaced: " .. item.Name)
		assert(
			(frame.RightVector - original.frame.RightVector).Magnitude < 0.0001
				and (frame.UpVector - original.frame.UpVector).Magnitude < 0.0001,
			"British relocation changed alignment: " .. item.Name
		)
	end
end

local ok, result = pcall(function()
	assert(game:GetService("RunService"):IsStudio(), "British scene fixture requires Studio")
	local deadline = os.clock() + 15
	repeat
		task.wait(0.1)
	until ReplicatedStorage:GetAttribute("MiniatureSandboxReady") or os.clock() >= deadline
	assert(
		ReplicatedStorage:GetAttribute("MiniatureSandboxReady")
			and ReplicatedStorage:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"British fixture requires the ready fake-store boundary"
	)
	local fingerprint = require(ServerStorage:WaitForChild("TemplateFingerprint", 10))
	local before = fingerprint()
	assert(
		before == ReplicatedStorage:GetAttribute("OriginalSandboxTemplates"),
		"Record original templates in Edit before Play"
	)
	local kinds, parts = 0, 0
	for kind, definition in Catalog.buildings do
		assert((kind == "mount" or BritishKit.available(kind)), "British manifest missing role: " .. kind)
		local british = keep((if kind == "mount" then MountStructures.create("britain") else BritishKit.create(kind)))
		local spartan = keep((if kind == "mount" then MountStructures.create("sparta") else SpartanKit.create(kind)))
		local roman = keep((if kind == "mount" then MountStructures.create("rome") else RomanKit.create(kind)))
		parts += inspect(british, definition.width, definition.depth)
		assert(shapeSignature(british) ~= shapeSignature(spartan), "British role is a Spartan recolour: " .. kind)
		assert(shapeSignature(british) ~= shapeSignature(roman), "British role is a Roman recolour: " .. kind)
		local pose = capturePose(british)
		for _, rotation in { 0, 90, 180, 270 } do
			british:PivotTo(CFrame.new(29, 5, -19) * CFrame.Angles(0, math.rad(rotation), 0))
			inspect(british, definition.width, definition.depth)
			assertPose(british, pose)
		end
		kinds += 1
	end
	assert(kinds == 11 and not BritishKit.available("unknown"), "British manifest differs from catalog")
	assert(not pcall(BritishKit.create, "unknown"), "Missing British art silently falls back")
	for _, role in { "melee", "ranged", "medic" } do
		local actor = keep(BritishKit.createActor(role))
		inspect(actor, 2, 2)
		assert(
			actor:GetAttribute("RosterRole") == role and actor:GetAttribute("PresentationOnly"),
			"British role data missing"
		)
		assert(actor:GetAttribute("PresentationRole") == "roster", "British actor enters workforce")
		assert(actor.Head.face.Texture == "rbxassetid://10526794", "Wrong British NPC face")
		local colors = actor:FindFirstChildOfClass("BodyColors")
		assert(
			colors and colors.HeadColor3 == actor.Head.Color and colors.TorsoColor3 == actor.Torso.Color,
			"British skin palette differs"
		)
		if role == "melee" then
			assert(
				actor:FindFirstChild("MusketBarrel")
					and actor:FindFirstChild("SocketBayonet")
					and actor:FindFirstChild("FlintlockStock"),
				"British infantry props missing"
			)
		elseif role == "ranged" then
			assert(
				actor:FindFirstChild("RifleBarrel")
					and actor:FindFirstChild("FlintlockPlate")
					and actor:FindFirstChild("CartridgeBox"),
				"British missile props missing"
			)
		else
			assert(
				actor:FindFirstChild("MedicalCase") and actor:FindFirstChild("RolledLinen"),
				"British support props missing"
			)
		end
		local pose = capturePose(actor)
		for _, rotation in { 0, 90, 180, 270 } do
			actor:PivotTo(CFrame.new(-15, 0.9, 8) * CFrame.Angles(0, math.rad(rotation), 0))
			inspect(actor, 2, 2)
			assertPose(actor, pose)
		end
	end
	assert(fingerprint() == before, "British factories mutated source templates")
	return {
		geometry = true,
		buildings = kinds,
		buildingParts = parts,
		actorRoles = 3,
		cardinalRotations = 4,
		sourceImmutable = true,
		maximumLocalDrift = maximumDrift,
		integratedGameplay = false,
		visualReview = "separate Studio screenshots and walk-through required",
	}
end)
for _, model in created do
	model:Destroy()
end
ReplicatedStorage:SetAttribute(
	"MiniatureBritainSceneResult",
	game:GetService("HttpService"):JSONEncode({ ok = ok, result = result })
)
assert(ok, tostring(result))

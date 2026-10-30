--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local MauryanKit = {}
local palette = {
	earth = Color3.fromRGB(166, 128, 81),
	plaster = Color3.fromRGB(205, 178, 130),
	timber = Color3.fromRGB(111, 75, 40),
	reed = Color3.fromRGB(175, 148, 84),
	stone = Color3.fromRGB(192, 169, 129),
	clay = Color3.fromRGB(133, 85, 52),
	dark = Color3.fromRGB(47, 41, 30),
	cloth = Color3.fromRGB(222, 207, 163),
}

local function part(model, name, size, point, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(point)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end

local function cylinder(model, name, diameter, height, point, color, material)
	local object = part(model, name, Vector3.new(height, diameter, diameter), point, color, material)
	object.Shape = Enum.PartType.Cylinder
	object.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	return object
end

-- Exposed beams plus a shallow bowed cover are an expressly interpretive roof.
-- No surviving Kumrahar domestic superstructure establishes this exact profile.
local function roof(model, frame, width, depth, eaves, rise)
	local half, divisions = width / 2 - 0.8, 10
	local step = half * 2 / divisions
	for index = 0, divisions - 1 do
		local x = -half + (index + 0.5) * step
		local y = eaves + rise * (1 - (x / half) ^ 2)
		local angle = math.atan(-2 * rise * x / half ^ 2)
		local cover = part(
			model,
			"BowedReedRoof",
			Vector3.new(step / math.cos(angle), 0.6, depth),
			Vector3.zero,
			palette.reed,
			Enum.Material.LeafyGrass
		)
		cover.CFrame = frame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, angle)
		if index % 3 == 0 then
			local tie = part(
				model,
				"RoofBinding",
				Vector3.new(0.15, 0.18, depth - 0.2),
				Vector3.zero,
				palette.timber,
				Enum.Material.Wood
			)
			tie.CFrame = cover.CFrame * CFrame.new(0, 0.4, 0)
		end
	end
	for _, z in { -depth / 2 + 0.4, depth / 2 - 0.4 } do
		local beam = part(
			model,
			"ExposedRoofBeam",
			Vector3.new(width - 1, 0.65, 0.65),
			Vector3.zero,
			palette.timber,
			Enum.Material.Wood
		)
		beam.CFrame = frame * CFrame.new(0, eaves - 0.5, z)
	end
end

local function post(model, x, z, height, bottom)
	return cylinder(
		model,
		"TimberPost",
		0.8,
		height,
		Vector3.new(x, bottom + height / 2, z),
		palette.timber,
		Enum.Material.Wood
	)
end

local function bowl(model, x, z, size, bottom)
	cylinder(model, "BlackSlippedBowl", size, size * 0.45, Vector3.new(x, bottom + size * 0.225, z), palette.dark)
	cylinder(
		model,
		"BowlInterior",
		size * 0.8,
		0.08,
		Vector3.new(x, bottom + size * 0.46, z),
		Color3.fromRGB(27, 28, 24)
	)
end

local builders = {}

function builders.civic(model, width, depth)
	part(
		model,
		"TimberHallPlatform",
		Vector3.new(width - 3, 1, depth - 3),
		Vector3.new(0, 1.5, 0),
		palette.timber,
		Enum.Material.WoodPlanks
	)
	for _, x in { -width * 0.32, 0, width * 0.32 } do
		for _, z in { -depth * 0.3, 0, depth * 0.3 } do
			cylinder(
				model,
				"PlainSandstonePillar",
				1.5,
				10,
				Vector3.new(x, 7, z),
				palette.stone,
				Enum.Material.Sandstone
			)
		end
		part(
			model,
			"HallArchitrave",
			Vector3.new(1.2, 1, depth - 4),
			Vector3.new(x, 12.5, 0),
			palette.timber,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.identity, width - 2, depth - 2, 13.2, 2.5)
	part(
		model,
		"ExchangeMat",
		Vector3.new(11, 0.12, 5),
		Vector3.new(0, 2.1, depth * 0.28),
		palette.cloth,
		Enum.Material.Fabric
	)
	part(
		model,
		"LowTradeTable",
		Vector3.new(8, 2, 2.8),
		Vector3.new(0, 3, depth * 0.28),
		palette.timber,
		Enum.Material.Wood
	)
	bowl(model, -2, depth * 0.28, 1.5, 4)
end

function builders.house(model, width, depth)
	-- Two unequal earthen compartments and a narrow veranda, rather than a temple.
	part(
		model,
		"EarthenRoom",
		Vector3.new(width * 0.45, 8, depth - 4),
		Vector3.new(-width * 0.22, 5, 0),
		palette.plaster,
		Enum.Material.Plaster
	)
	part(
		model,
		"SmallSideRoom",
		Vector3.new(width * 0.31, 5.8, depth * 0.44),
		Vector3.new(width * 0.24, 3.9, -depth * 0.23),
		palette.earth,
		Enum.Material.Ground
	)
	part(
		model,
		"ReedDoorScreen",
		Vector3.new(3, 5, 0.2),
		Vector3.new(-width * 0.22, 3.5, (depth - 4) / 2 + 0.12),
		palette.timber,
		Enum.Material.Wood
	)
	roof(model, CFrame.new(-width * 0.22, 0, 0), width * 0.52, depth - 2, 9.2, 2)
	roof(model, CFrame.new(width * 0.24, 0, -depth * 0.23), width * 0.39, depth * 0.52, 7, 1.2)
	for _, z in { depth * 0.05, depth * 0.34 } do
		post(model, width * 0.34, z, 5.8, 1)
	end
	part(
		model,
		"VerandaMat",
		Vector3.new(width * 0.29, 0.16, depth * 0.4),
		Vector3.new(width * 0.23, 1.1, depth * 0.23),
		palette.cloth,
		Enum.Material.Fabric
	)
	bowl(model, width * 0.23, depth * 0.3, 2.1, 1.2)
end

function builders.farm(model, width, depth)
	part(
		model,
		"CultivationSoil",
		Vector3.new(width - 2, 0.7, depth - 2),
		Vector3.new(0, 1.25, 0),
		palette.earth,
		Enum.Material.Ground
	)
	for _, x in { -width * 0.25, width * 0.25 } do
		part(
			model,
			"FieldBerm",
			Vector3.new(0.8, 0.4, depth - 3),
			Vector3.new(x, 1.85, 0),
			palette.clay,
			Enum.Material.Ground
		)
	end
	for row = -2, 2 do
		for column = -3, 3 do
			local point = Vector3.new(column * 3.4, 2.6, row * 4.5)
			part(model, "GrainStem", Vector3.new(0.2, 2, 0.2), point, Color3.fromRGB(139, 151, 63))
			local ear = part(
				model,
				"DroopingGrainEar",
				Vector3.new(1, 0.35, 0.35),
				point + Vector3.new(0.25, 1, 0),
				Color3.fromRGB(203, 181, 87)
			)
			ear.CFrame *= CFrame.Angles(0, 0, -0.25)
		end
	end
	cylinder(
		model,
		"GrainBasket",
		3.3,
		2,
		Vector3.new(width * 0.37, 2.6, depth * 0.34),
		palette.reed,
		Enum.Material.Wood
	)
end

function builders.timber(model, width, depth)
	for _, x in { -width * 0.32, width * 0.32 } do
		post(model, x, -depth * 0.28, 6, 1)
		post(model, x, depth * 0.28, 6, 1)
	end
	roof(model, CFrame.identity, width - 3, depth - 3, 7.5, 1.4)
	for layer = 0, 2 do
		for _, x in { -width * 0.22, width * 0.22 } do
			local pole = part(
				model,
				"SeasoningTimberPole",
				Vector3.new(depth * 0.65, 1.6, 1.6),
				Vector3.new(x, 1.8 + layer * 1.45, 0),
				palette.timber,
				Enum.Material.Wood
			)
			pole.Shape = Enum.PartType.Cylinder
			pole.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		end
	end
	part(model, "HewingBlock", Vector3.new(4, 2, 4), Vector3.new(0, 2, depth * 0.3), palette.timber, Enum.Material.Wood)
	part(
		model,
		"AdzeHead",
		Vector3.new(1.7, 0.3, 0.65),
		Vector3.new(0, 3.3, depth * 0.3),
		palette.dark,
		Enum.Material.Metal
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayMixingBed",
		Vector3.new(width * 0.55, 0.8, depth - 5),
		Vector3.new(-width * 0.16, 1.4, 0),
		palette.clay,
		Enum.Material.Mud
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"MixingBedKerb",
			Vector3.new(width * 0.58, 0.7, 0.6),
			Vector3.new(-width * 0.16, 1.9, side * (depth / 2 - 2)),
			palette.earth,
			Enum.Material.Ground
		)
	end
	for row = -1, 1 do
		cylinder(
			model,
			"PreparedClayBall",
			2.3,
			0.8,
			Vector3.new(width * 0.32, 1.6, row * 4),
			palette.clay,
			Enum.Material.Ground
		)
	end
	part(
		model,
		"ClayPaddlingBoard",
		Vector3.new(3.2, 0.2, 5),
		Vector3.new(width * 0.31, 1.15, depth * 0.32),
		palette.timber,
		Enum.Material.Wood
	)
end

function builders.workshop(model, width, depth)
	part(
		model,
		"LowFiringClamp",
		Vector3.new(9, 2.8, depth * 0.58),
		Vector3.new(-width * 0.27, 2.4, -1),
		palette.clay,
		Enum.Material.Ground
	)
	part(
		model,
		"FiringClampVent",
		Vector3.new(2, 1.3, 0.16),
		Vector3.new(-width * 0.27, 1.9, -1 + depth * 0.29 + 0.12),
		palette.dark
	)
	for _, x in { 1.5, width * 0.37 } do
		post(model, x, -depth * 0.32, 6, 1)
		post(model, x, depth * 0.32, 6, 1)
	end
	roof(model, CFrame.new(width * 0.2, 0, 0), width * 0.48, depth - 3, 7.4, 1.3)
	cylinder(model, "PotteryWheelStand", 1.1, 1.8, Vector3.new(width * 0.2, 1.9, 1), palette.timber, Enum.Material.Wood)
	cylinder(model, "PotteryWheel", 3.6, 0.25, Vector3.new(width * 0.2, 2.9, 1), palette.stone, Enum.Material.Sandstone)
	bowl(model, width * 0.2, 1, 2, 3.1)
	for _, z in { -5, 5 } do
		bowl(model, width * 0.35, z, 2.2, 1)
	end
end

function builders.storehouse(model, width, depth)
	for _, side in { -1, 1 } do
		part(
			model,
			"StoreCompoundWall",
			Vector3.new(1.3, 4, depth - 2),
			Vector3.new(side * (width / 2 - 1), 3, 0),
			palette.earth,
			Enum.Material.Ground
		)
	end
	part(
		model,
		"StoreRearWall",
		Vector3.new(width - 2, 4, 1.3),
		Vector3.new(0, 3, -depth / 2 + 1),
		palette.earth,
		Enum.Material.Ground
	)
	for _, x in { -width * 0.25, 0, width * 0.25 } do
		cylinder(model, "EarthenStorageBin", 5, 5, Vector3.new(x, 3.5, -2), palette.plaster, Enum.Material.Plaster)
		cylinder(model, "BinNeck", 2.8, 0.6, Vector3.new(x, 6.3, -2), palette.reed, Enum.Material.Wood)
		post(model, x, depth * 0.29, 7, 1)
		post(model, x, -depth * 0.29, 7, 1)
	end
	roof(model, CFrame.identity, width - 3, depth - 3, 8.4, 1.7)
end

function builders.training(model, width, depth)
	part(
		model,
		"EarthenExerciseGround",
		Vector3.new(width - 2, 0.2, depth - 2),
		Vector3.new(0, 1.1, 0),
		Color3.fromRGB(174, 147, 98),
		Enum.Material.Ground
	)
	for _, x in { -width * 0.35, width * 0.35 } do
		post(model, x, -depth * 0.3, 7, 1)
		post(model, x, -depth * 0.06, 7, 1)
	end
	roof(model, CFrame.new(0, 0, -depth * 0.2), width - 3, depth * 0.36, 8.3, 1.5)
	for _, x in { -12, -4, 4, 12 } do
		post(model, x, -depth * 0.13, 3.2, 1)
		part(
			model,
			"WovenPracticePanel",
			Vector3.new(2.7, 3.5, 0.4),
			Vector3.new(x, 3.1, -depth * 0.13),
			palette.reed,
			Enum.Material.Wood
		)
	end
	part(model, "PracticeLine", Vector3.new(width - 5, 0.08, 0.3), Vector3.new(0, 1.24, 5), palette.cloth)
end

function builders.healer(model, width, depth)
	part(
		model,
		"TreatmentPlatform",
		Vector3.new(width - 2, 1, depth - 2),
		Vector3.new(0, 1.5, 0),
		palette.timber,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"EarthenTreatmentScreen",
		Vector3.new(width - 4, 4, 1.2),
		Vector3.new(0, 4, -depth * 0.32),
		palette.earth,
		Enum.Material.Ground
	)
	for _, x in { -width * 0.32, width * 0.32 } do
		post(model, x, -depth * 0.28, 6, 2)
		post(model, x, depth * 0.28, 6, 2)
	end
	roof(model, CFrame.identity, width - 2, depth - 2, 8.5, 1.5)
	part(
		model,
		"WovenTreatmentCot",
		Vector3.new(4, 1, 7),
		Vector3.new(-width * 0.23, 2.5, -1),
		palette.cloth,
		Enum.Material.Fabric
	)
	cylinder(
		model,
		"PreparationMortar",
		2.5,
		1.6,
		Vector3.new(width * 0.23, 2.8, -2),
		palette.stone,
		Enum.Material.Sandstone
	)
	part(
		model,
		"Pestle",
		Vector3.new(0.6, 2.5, 0.6),
		Vector3.new(width * 0.23, 4.3, -2),
		palette.stone,
		Enum.Material.Sandstone
	)
	bowl(model, width * 0.23, 4, 2.2, 2)
end

function MauryanKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function MauryanKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("maurya")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Mauryan building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"EarthenFoundation",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		palette.earth,
		Enum.Material.Ground
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "maurya")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	if model:FindFirstChild("BowedReedRoof") then
		model:SetAttribute("RoofInterpretation", true)
	end
	model:SetAttribute("EvidenceCard", "docs/notes/Mauryan Sandbox Art.md")
	return model
end

local function rod(model, name, a, b, thickness, color)
	local object =
		part(model, name, Vector3.new(thickness, (b - a).Magnitude, thickness), (a + b) / 2, color, Enum.Material.Wood)
	object.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0)
	return object
end

function MauryanKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Mauryan presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(137, 91, 59)
	local cloth = if role == "medic" then palette.cloth else Color3.fromRGB(209, 187, 134)
	local colors = Instance.new("BodyColors")
	colors.HeadColor3, colors.TorsoColor3 = skin, skin
	colors.LeftArmColor3, colors.RightArmColor3 = skin, skin
	colors.LeftLegColor3, colors.RightLegColor3 = skin, skin
	colors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "WrappedUpperCloth", Vector3.new(1.98, 1.8, 1.06), Vector3.new(0, 3.05, 0), cloth, Enum.Material.Fabric)
	part(model, "LongWrappedCloth", Vector3.new(2.05, 1.9, 1.13), Vector3.new(0, 1.9, 0), cloth, Enum.Material.Fabric)
	part(
		model,
		"FoldedClothEdge",
		Vector3.new(0.28, 1.9, 0.16),
		Vector3.new(0.5, 1.9, -0.63),
		palette.reed,
		Enum.Material.Fabric
	)
	for _, side in { -1, 1 } do
		local label = if side < 0 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			"PlainSandal",
			Vector3.new(0.85, 0.25, 1.05),
			Vector3.new(side * 0.5, 0.125, -0.08),
			palette.timber,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	for layer = 0, 2 do
		cylinder(
			model,
			"WrappedHeadCloth",
			1.65 - layer * 0.14,
			0.24,
			Vector3.new(0, 5.3 + layer * 0.19, 0.05),
			cloth,
			Enum.Material.Fabric
		)
	end
	if role == "melee" then
		rod(model, "SpearShaft", Vector3.new(1.55, 0.15, -0.3), Vector3.new(1.55, 6.8, -0.3), 0.14, palette.timber)
		part(
			model,
			"SpearHead",
			Vector3.new(0.28, 0.8, 0.14),
			Vector3.new(1.55, 7.1, -0.3),
			palette.dark,
			Enum.Material.Metal
		)
		local shield = part(
			model,
			"LongHideShield",
			Vector3.new(1.5, 3.9, 0.25),
			Vector3.new(-1.45, 2.6, -0.75),
			Color3.fromRGB(120, 85, 48),
			Enum.Material.Leather
		)
		shield.Shape = Enum.PartType.Ball
		part(
			model,
			"ShieldSpine",
			Vector3.new(0.18, 3.3, 0.2),
			Vector3.new(-1.45, 2.6, -0.93),
			palette.timber,
			Enum.Material.Wood
		)
	elseif role == "ranged" then
		local points = {
			Vector3.new(-1.3, 0.4, -0.5),
			Vector3.new(-1.65, 1.5, -0.5),
			Vector3.new(-1.8, 3, -0.5),
			Vector3.new(-1.65, 4.6, -0.5),
			Vector3.new(-1.3, 5.8, -0.5),
		}
		for index = 1, #points - 1 do
			rod(model, "LongbowLimb", points[index], points[index + 1], 0.14, palette.timber)
		end
		rod(model, "LongbowString", points[1], points[#points], 0.04, palette.cloth)
		part(
			model,
			"ArrowBundleCase",
			Vector3.new(0.7, 2.8, 0.5),
			Vector3.new(0.65, 3.4, 0.8),
			palette.timber,
			Enum.Material.Wood
		)
		for index = 0, 2 do
			rod(
				model,
				"LongArrow",
				Vector3.new(0.45 + index * 0.2, 3.1, 0.8),
				Vector3.new(0.45 + index * 0.2, 5.6, 0.8),
				0.07,
				palette.reed
			)
		end
	else
		part(
			model,
			"HealerPreparationPouch",
			Vector3.new(0.9, 1, 0.55),
			Vector3.new(-1.2, 2.2, -0.2),
			palette.reed,
			Enum.Material.Fabric
		)
		cylinder(
			model,
			"PreparationBowl",
			0.9,
			0.35,
			Vector3.new(1.35, 2.15, -0.2),
			palette.stone,
			Enum.Material.Sandstone
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "maurya")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Mauryan Sandbox Art.md")
	return model
end

return MauryanKit

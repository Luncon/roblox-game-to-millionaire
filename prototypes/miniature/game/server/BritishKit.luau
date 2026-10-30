--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local BritishKit = {}
local palette = {
	brick = Color3.fromRGB(157, 98, 73),
	slate = Color3.fromRGB(83, 96, 103),
	stone = Color3.fromRGB(186, 180, 158),
	trim = Color3.fromRGB(225, 220, 198),
	wood = Color3.fromRGB(109, 81, 52),
	dark = Color3.fromRGB(44, 50, 47),
	glass = Color3.fromRGB(134, 154, 151),
	soil = Color3.fromRGB(110, 89, 58),
	clay = Color3.fromRGB(144, 99, 66),
	grain = Color3.fromRGB(199, 178, 99),
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

local function roof(model, frame, width, depth, eaves, rise)
	local half = width / 2 - 0.5
	local angle = math.atan(rise / half)
	for _, side in { -1, 1 } do
		local slab = part(
			model,
			"SlateRoofSlope",
			Vector3.new(half / math.cos(angle), 0.65, depth),
			Vector3.zero,
			palette.slate,
			Enum.Material.Slate
		)
		slab.CFrame = frame * CFrame.new(side * half / 2, eaves + rise / 2, 0) * CFrame.Angles(0, 0, -side * angle)
	end
	local ridge =
		part(model, "SlateRidge", Vector3.new(0.7, 0.6, depth), Vector3.zero, palette.slate, Enum.Material.Slate)
	ridge.CFrame = frame * CFrame.new(0, eaves + rise, 0)
end

local function window(model, x, y, z, width, height)
	part(
		model,
		"SashWindowGlass",
		Vector3.new(width, height, 0.2),
		Vector3.new(x, y, z),
		palette.glass,
		Enum.Material.Glass
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"SashSideFrame",
			Vector3.new(0.2, height + 0.3, 0.3),
			Vector3.new(x + side * width / 2, y, z + 0.1),
			palette.trim
		)
		part(
			model,
			"SashHeadSill",
			Vector3.new(width + 0.4, 0.2, 0.3),
			Vector3.new(x, y + side * height / 2, z + 0.1),
			palette.trim
		)
	end
	part(model, "SashMeetingRail", Vector3.new(width, 0.15, 0.25), Vector3.new(x, y, z + 0.18), palette.trim)
	part(model, "SashGlazingBar", Vector3.new(0.12, height, 0.25), Vector3.new(x, y, z + 0.18), palette.trim)
end

local function brickBlock(model, name, width, depth, height, x, z, bottom)
	return part(
		model,
		name,
		Vector3.new(width, height, depth),
		Vector3.new(x, bottom + height / 2, z),
		palette.brick,
		Enum.Material.Brick
	)
end

local function chimney(model, x, z, bottom, height)
	brickBlock(model, "BrickChimney", 2, 2, height, x, z, bottom)
	for _, dx in { -0.5, 0.5 } do
		cylinder(
			model,
			"ChimneyPot",
			0.65,
			0.8,
			Vector3.new(x + dx, bottom + height + 0.4, z),
			palette.clay,
			Enum.Material.Brick
		)
	end
end

local function crate(model, x, z, width, height, bottom)
	part(
		model,
		"TimberCrate",
		Vector3.new(width, height, width),
		Vector3.new(x, bottom + height / 2, z),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"CrateBracing",
		Vector3.new(width + 0.1, 0.2, 0.15),
		Vector3.new(x, bottom + height * 0.65, z + width / 2 + 0.1),
		palette.dark
	)
end

local builders = {}

function builders.civic(model, width, depth)
	brickBlock(model, "MarketAssemblyRange", width - 8, 12, 15, 0, -6, 1)
	roof(model, CFrame.new(0, 0, -6), width - 4, 16, 16.3, 3.5)
	for _, x in { -12, -4, 4, 12 } do
		part(
			model,
			"MarketSquarePier",
			Vector3.new(1.3, 7, 1.3),
			Vector3.new(x, 4.5, 7),
			palette.stone,
			Enum.Material.Limestone
		)
		window(model, x, 11.5, 10.15, 2.4, 3.1)
	end
	part(
		model,
		"MarketEntablature",
		Vector3.new(width - 6, 1, 4),
		Vector3.new(0, 8.5, 7),
		palette.trim,
		Enum.Material.Limestone
	)
	brickBlock(model, "UpperMarketChamber", width - 6, 6, 6, 0, 7, 9)
	roof(model, CFrame.new(0, 0, 7), width - 4, 8, 15.2, 2)
	part(model, "ClockFace", Vector3.new(2.8, 2.8, 0.18), Vector3.new(0, 12.5, 10.2), palette.trim)
	part(model, "ClockHourHand", Vector3.new(0.15, 0.85, 0.12), Vector3.new(0, 12.8, 10.35), palette.dark)
	part(model, "ClockMinuteHand", Vector3.new(0.95, 0.15, 0.12), Vector3.new(0.35, 12.5, 10.35), palette.dark)
	for _, x in { -7, 7 } do
		part(
			model,
			"MarketStallCounter",
			Vector3.new(9, 2.5, 3),
			Vector3.new(x, 2.25, depth * 0.4),
			palette.wood,
			Enum.Material.WoodPlanks
		)
		crate(model, x + 1.5, depth * 0.4, 1.8, 1.5, 3.5)
	end
end

function builders.house(model, width, depth)
	brickBlock(model, "PairedWorkerTerrace", width - 2, depth - 6, 14, 0, -2, 1)
	part(
		model,
		"TerraceStringCourse",
		Vector3.new(width - 1.8, 0.35, 0.3),
		Vector3.new(0, 8.3, depth / 2 - 4.85),
		palette.stone,
		Enum.Material.Limestone
	)
	for _, x in { -7.5, 7.5 } do
		window(model, x, 4.8, depth / 2 - 4.85, 2.7, 3.8)
	end
	for _, x in { -7.5, -2.5, 2.5, 7.5 } do
		window(model, x, 11.3, depth / 2 - 4.85, 2.7, 3.8)
	end
	for _, x in { -2.5, 2.5 } do
		part(
			model,
			"WorkerFrontDoor",
			Vector3.new(2.7, 5, 0.25),
			Vector3.new(x, 3.5, depth / 2 - 4.7),
			palette.dark,
			Enum.Material.Wood
		)
		part(
			model,
			"DoorLintel",
			Vector3.new(3.2, 0.4, 0.35),
			Vector3.new(x, 6.25, depth / 2 - 4.6),
			palette.stone,
			Enum.Material.Limestone
		)
	end
	roof(model, CFrame.new(0, 0, -2), width - 0.5, depth - 4, 15.3, 3.7)
	chimney(model, -8, -4, 14, 6)
	chimney(model, 8, -4, 14, 6)
end

function builders.farm(model, width, depth)
	part(
		model,
		"ArableSoil",
		Vector3.new(width - 2, 0.7, depth - 2),
		Vector3.new(0, 1.25, 0),
		palette.soil,
		Enum.Material.Ground
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"FieldHedge",
			Vector3.new(0.8, 1.5, depth - 2),
			Vector3.new(side * (width / 2 - 1), 2.35, 0),
			Color3.fromRGB(92, 116, 65),
			Enum.Material.LeafyGrass
		)
	end
	for column = -1, 2 do
		for row = -2, 2 do
			local point = Vector3.new(column * 4.2, 3, row * 4.6)
			part(model, "CornStalk", Vector3.new(0.22, 2.5, 0.22), point, palette.grain)
			part(model, "CornEar", Vector3.new(0.6, 1.2, 0.6), point + Vector3.new(0, 1.3, 0), palette.grain)
		end
	end
	part(
		model,
		"WeatherboardFieldShed",
		Vector3.new(6, 4.5, 8),
		Vector3.new(-width * 0.32, 3.85, -depth * 0.28),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	roof(model, CFrame.new(-width * 0.32, 0, -depth * 0.28), 8, 10, 6.3, 1.8)
end

function builders.timber(model, width, depth)
	part(model, "SawPitShadow", Vector3.new(width * 0.55, 0.1, depth * 0.45), Vector3.new(0, 1.08, 0), palette.dark)
	for _, side in { -1, 1 } do
		part(
			model,
			"SawPitTimberEdge",
			Vector3.new(width * 0.6, 0.8, 0.7),
			Vector3.new(0, 1.5, side * depth * 0.25),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"SawPitCrossBeam",
			Vector3.new(1, 1, depth * 0.6),
			Vector3.new(side * width * 0.22, 2, 0),
			palette.wood,
			Enum.Material.Wood
		)
	end
	for layer = 0, 2 do
		part(
			model,
			"MerchantPlankStack",
			Vector3.new(width - 5, 0.65, 3),
			Vector3.new(0, 1.4 + layer * 0.8, -depth * 0.36),
			palette.wood,
			Enum.Material.WoodPlanks
		)
	end
	crate(model, width * 0.3, depth * 0.32, 3.5, 3, 1)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayWinningBed",
		Vector3.new(width - 4, 0.6, depth - 4),
		Vector3.new(0, 1.3, 0),
		palette.clay,
		Enum.Material.Mud
	)
	for step = 0, 1 do
		part(
			model,
			"ClayPitBank",
			Vector3.new(width - 5, 1 + step, 2),
			Vector3.new(0, 1.5 + step * 0.5, -depth / 2 + 2 + step * 2),
			palette.soil,
			Enum.Material.Ground
		)
	end
	part(
		model,
		"BarrowTray",
		Vector3.new(4, 1, 5),
		Vector3.new(width * 0.25, 3, depth * 0.15),
		palette.wood,
		Enum.Material.Wood
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"BarrowHandle",
			Vector3.new(0.35, 0.35, 7),
			Vector3.new(width * 0.25 + side * 1.4, 2.6, depth * 0.2),
			palette.wood,
			Enum.Material.Wood
		)
	end
	local wheel = part(
		model,
		"BarrowWheel",
		Vector3.new(0.6, 2.6, 2.6),
		Vector3.new(width * 0.25, 2.3, depth * 0.15 - 2),
		palette.dark,
		Enum.Material.Wood
	)
	wheel.Shape = Enum.PartType.Cylinder
end

function builders.workshop(model, width, depth)
	cylinder(
		model,
		"SmallBottleKilnBase",
		7,
		4.5,
		Vector3.new(-width * 0.28, 3.25, 0),
		palette.brick,
		Enum.Material.Brick
	)
	for tier = 0, 4 do
		cylinder(
			model,
			"BottleKilnShoulder",
			7 - tier,
			0.9,
			Vector3.new(-width * 0.28, 5.95 + tier * 0.8, 0),
			palette.brick,
			Enum.Material.Brick
		)
	end
	cylinder(model, "BottleKilnNeck", 2.5, 2.3, Vector3.new(-width * 0.28, 10.5, 0), palette.brick, Enum.Material.Brick)
	part(model, "KilnFireMouth", Vector3.new(2, 1.8, 0.2), Vector3.new(-width * 0.28, 2, 3.6), palette.dark)
	brickBlock(model, "PotterWorkroom", width * 0.44, depth * 0.72, 7, width * 0.22, -1, 1)
	roof(model, CFrame.new(width * 0.22, 0, -1), width * 0.49, depth * 0.82, 8.2, 2.2)
	window(model, width * 0.22, 4.8, depth * 0.36 - 0.8, 3, 3)
	part(
		model,
		"PotteryBench",
		Vector3.new(width * 0.38, 2, 3),
		Vector3.new(width * 0.22, 2, depth * 0.34),
		palette.wood,
		Enum.Material.Wood
	)
	cylinder(model, "EarthenwareBowl", 2, 0.9, Vector3.new(width * 0.22, 3.5, depth * 0.34), palette.trim)
end

function builders.storehouse(model, width, depth)
	brickBlock(model, "CommercialWarehouse", width - 6, depth - 7, 12, 0, 0, 1)
	for _, x in { -width * 0.28, width * 0.28 } do
		window(model, x, 8.7, (depth - 7) / 2 + 0.15, 2, 3)
	end
	part(
		model,
		"GroundLoadingDoor",
		Vector3.new(5, 6, 0.25),
		Vector3.new(0, 4, (depth - 7) / 2 + 0.2),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"UpperLoadingDoor",
		Vector3.new(4.5, 4, 0.25),
		Vector3.new(0, 10, (depth - 7) / 2 + 0.2),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"WarehouseHoistBeam",
		Vector3.new(0.7, 0.8, 4),
		Vector3.new(0, 12.6, depth * 0.37),
		palette.wood,
		Enum.Material.Wood
	)
	roof(model, CFrame.identity, width - 3, depth - 3, 13.2, 3.1)
	crate(model, width * 0.28, depth * 0.38, 3, 2.4, 1)
end

function builders.training(model, width, depth)
	part(
		model,
		"ParadeGround",
		Vector3.new(width - 2, 0.2, depth - 2),
		Vector3.new(0, 1.1, 0),
		palette.stone,
		Enum.Material.Pebble
	)
	brickBlock(model, "RegimentalBarrackRange", width - 4, 8, 10, 0, -depth * 0.3, 1)
	roof(model, CFrame.new(0, 0, -depth * 0.3), width - 2, 10, 11.2, 2.5)
	for _, x in { -12, -4, 4, 12 } do
		window(model, x, 6.3, -depth * 0.3 + 4.2, 2.6, 3.5)
	end
	part(
		model,
		"BarrackEntry",
		Vector3.new(3, 5, 0.25),
		Vector3.new(0, 3.5, -depth * 0.3 + 4.25),
		palette.dark,
		Enum.Material.Wood
	)
	for _, x in { -width * 0.38, width * 0.38 } do
		part(
			model,
			"PlainSentryBox",
			Vector3.new(3, 5, 3),
			Vector3.new(x, 3.5, depth * 0.28),
			palette.wood,
			Enum.Material.WoodPlanks
		)
		roof(model, CFrame.new(x, 0, depth * 0.28), 4, 4, 6.2, 1.2)
	end
end

function builders.healer(model, width, depth)
	part(
		model,
		"InfirmaryFloor",
		Vector3.new(width - 2, 1, depth - 2),
		Vector3.new(0, 1.5, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	brickBlock(model, "InfirmaryRearRange", width - 4, 8, 7, 0, -6, 2)
	roof(model, CFrame.new(0, 0, -6), width - 2, 12, 9.2, 2.2)
	for _, x in { -5, 5 } do
		window(model, x, 5.8, -1.8, 2.6, 3.8)
	end
	part(model, "InfirmaryDoor", Vector3.new(3, 5, 0.25), Vector3.new(0, 4.5, -1.75), palette.dark, Enum.Material.Wood)
	part(
		model,
		"LinenTreatmentBench",
		Vector3.new(3.2, 1.2, 6),
		Vector3.new(-width * 0.25, 2.6, 4),
		palette.trim,
		Enum.Material.Fabric
	)
	part(
		model,
		"DispensaryTable",
		Vector3.new(4, 1.7, 3),
		Vector3.new(width * 0.25, 2.85, 4),
		palette.wood,
		Enum.Material.Wood
	)
	cylinder(model, "DispensaryBasin", 2, 0.7, Vector3.new(width * 0.25, 4.05, 4), palette.trim)
end

function BritishKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function BritishKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("britain")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing British building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"GeorgianFooting",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "britain")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/British Sandbox Art.md")
	return model
end

function BritishKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing British presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(235, 198, 172)
	local coat = if role == "melee"
		then Color3.fromRGB(169, 54, 44)
		elseif role == "ranged" then Color3.fromRGB(61, 83, 56)
		else Color3.fromRGB(57, 69, 84)
	local colors = Instance.new("BodyColors")
	colors.HeadColor3, colors.TorsoColor3 = skin, skin
	colors.LeftArmColor3, colors.RightArmColor3 = skin, skin
	colors.LeftLegColor3, colors.RightLegColor3 = skin, skin
	colors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "GeorgianCoat", Vector3.new(1.98, 2.05, 1.07), Vector3.new(0, 3.05, 0), coat, Enum.Material.Fabric)
	part(model, "CoatTails", Vector3.new(2.05, 1, 0.55), Vector3.new(0, 1.95, 0.35), coat, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local label = if side < 0 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(
			model,
			"CoatSleeve",
			Vector3.new(0.86, 1.65, 0.92),
			Vector3.new(side * 1.35, 3.25, 0),
			coat,
			Enum.Material.Fabric
		)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			"Trousers",
			Vector3.new(0.87, 1.8, 0.92),
			Vector3.new(side * 0.5, 1.1, 0),
			palette.trim,
			Enum.Material.Fabric
		)
		part(
			model,
			"BlackShoes",
			Vector3.new(0.9, 0.35, 1.1),
			Vector3.new(side * 0.5, 0.175, -0.1),
			palette.dark,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	if role == "medic" then
		part(
			model,
			"AssistantBicornBrim",
			Vector3.new(2.2, 0.2, 1.35),
			Vector3.new(0, 5.35, 0),
			palette.dark,
			Enum.Material.Fabric
		)
		part(
			model,
			"AssistantBicornCrown",
			Vector3.new(1.8, 0.65, 0.5),
			Vector3.new(0, 5.6, 0),
			palette.dark,
			Enum.Material.Fabric
		)
		part(
			model,
			"MedicalCase",
			Vector3.new(1.1, 1.2, 0.65),
			Vector3.new(-1.2, 2.05, -0.1),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"RolledLinen",
			Vector3.new(0.8, 0.3, 0.65),
			Vector3.new(1.35, 2.15, -0.15),
			palette.trim,
			Enum.Material.Fabric
		)
	else
		cylinder(model, "PlainShako", 1.5, 1.15, Vector3.new(0, 5.8, 0.05), palette.dark, Enum.Material.Leather)
		part(model, "ShakoPeak", Vector3.new(1.55, 0.14, 0.7), Vector3.new(0, 5.28, -0.65), palette.dark)
		for _, side in { -1, 1 } do
			local belt = part(
				model,
				"CrossBelt",
				Vector3.new(0.22, 2.2, 0.14),
				Vector3.new(0, 3.1, -0.62),
				if role == "melee" then palette.trim else palette.dark,
				Enum.Material.Leather
			)
			belt.CFrame *= CFrame.Angles(0, 0, side * 0.55)
		end
		part(
			model,
			"CartridgeBox",
			Vector3.new(0.95, 0.7, 0.45),
			Vector3.new(0.85, 2.25, 0.7),
			palette.dark,
			Enum.Material.Leather
		)
		local barrelHeight = if role == "melee" then 4.3 else 3.2
		cylinder(
			model,
			if role == "melee" then "MusketBarrel" else "RifleBarrel",
			0.16,
			barrelHeight,
			Vector3.new(1.5, 2.25 + barrelHeight / 2, -0.35),
			Color3.fromRGB(153, 153, 142),
			Enum.Material.Metal
		)
		part(
			model,
			"FlintlockStock",
			Vector3.new(0.3, 2.6, 0.4),
			Vector3.new(1.5, 1.65, -0.25),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"FlintlockPlate",
			Vector3.new(0.22, 0.4, 0.32),
			Vector3.new(1.7, 2.3, -0.3),
			Color3.fromRGB(145, 145, 132),
			Enum.Material.Metal
		)
		if role == "melee" then
			part(
				model,
				"SocketBayonet",
				Vector3.new(0.1, 1.4, 0.1),
				Vector3.new(1.61, 7, -0.35),
				Color3.fromRGB(168, 170, 158),
				Enum.Material.Metal
			)
		end
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "britain")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/British Sandbox Art.md")
	return model
end

return BritishKit

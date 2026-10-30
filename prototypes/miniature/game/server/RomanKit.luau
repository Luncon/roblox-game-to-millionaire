--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local RomanKit = {}
local palette = {
	brick = Color3.fromRGB(161, 100, 73),
	stone = Color3.fromRGB(183, 174, 151),
	plaster = Color3.fromRGB(224, 212, 184),
	tile = Color3.fromRGB(169, 81, 53),
	wood = Color3.fromRGB(105, 77, 49),
	dark = Color3.fromRGB(49, 47, 41),
	clay = Color3.fromRGB(137, 92, 67),
	greyware = Color3.fromRGB(102, 107, 100),
}

local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end

local function cylinder(model, name, diameter, height, position, color, material)
	local object = part(model, name, Vector3.new(height, diameter, diameter), position, color, material)
	object.Shape = Enum.PartType.Cylinder
	object.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	return object
end

local function roof(model, frame, width, depth, eaves, rise)
	local half = depth / 2 - 0.5
	local angle = math.atan(rise / half)
	for _, side in { -1, 1 } do
		local slab = part(
			model,
			"TegulaRoof",
			Vector3.new(width, 0.65, half / math.cos(angle)),
			Vector3.zero,
			palette.tile,
			Enum.Material.ClayRoofTiles
		)
		slab.CFrame = frame * CFrame.new(0, eaves + rise / 2, side * half / 2) * CFrame.Angles(side * angle, 0, 0)
		for row = 1, 3 do
			local seam = part(
				model,
				"TileCourses",
				Vector3.new(width - 0.4, 0.14, 0.22),
				Vector3.zero,
				palette.tile,
				Enum.Material.ClayRoofTiles
			)
			seam.CFrame = slab.CFrame * CFrame.new(0, 0.4, (row - 2) * half / 3)
		end
	end
	local ridge = part(
		model,
		"ImbrexRidge",
		Vector3.new(width, 0.6, 0.8),
		Vector3.zero,
		palette.tile,
		Enum.Material.ClayRoofTiles
	)
	ridge.CFrame = frame * CFrame.new(0, eaves + rise, 0)
end

local function block(model, name, width, depth, height, x, z, bottom)
	return part(
		model,
		name,
		Vector3.new(width, height, depth),
		Vector3.new(x, bottom + height / 2, z),
		palette.brick,
		Enum.Material.Brick
	)
end

local function arch(model, x, z, span, spring, thickness, depth)
	local radius = span / 2
	for _, side in { -1, 1 } do
		part(
			model,
			"ArcadePier",
			Vector3.new(thickness, spring - 1, depth),
			Vector3.new(x + side * (radius + thickness / 2), (spring + 1) / 2, z),
			palette.brick,
			Enum.Material.Brick
		)
	end
	for index = 0, 8 do
		local angle = (index + 0.5) * math.pi / 9
		local voussoir = part(
			model,
			"ArchVoussoir",
			Vector3.new(radius * math.pi / 9 * 0.98, thickness, depth),
			Vector3.new(x + radius * math.cos(angle), spring + radius * math.sin(angle), z),
			palette.brick,
			Enum.Material.Brick
		)
		voussoir.CFrame *= CFrame.Angles(0, 0, angle + math.pi / 2)
	end
end

local function vessel(model, x, z, scale, bottom)
	local jar = part(
		model,
		"GreywareVessel",
		Vector3.new(2, 2.8, 2) * scale,
		Vector3.new(x, bottom + 1.4 * scale, z),
		palette.greyware,
		Enum.Material.SmoothPlastic
	)
	jar.Shape = Enum.PartType.Ball
	cylinder(model, "VesselRim", 1.1 * scale, 0.25 * scale, Vector3.new(x, bottom + 2.75 * scale, z), palette.dark)
end

local builders = {}

function builders.house(model, width, depth)
	-- A compressed brick courtyard residence; lower side wings and a taller rear.
	block(model, "TwoLevelRearWing", width - 2, 6, 15, 0, -depth / 2 + 4, 1)
	roof(model, CFrame.new(0, 0, -depth / 2 + 4), width - 1, 7.5, 16.2, 1.7)
	for _, side in { -1, 1 } do
		block(model, "CourtSideRoom", 5, depth - 11, 8, side * (width / 2 - 3.5), 2.5, 1)
		roof(
			model,
			CFrame.new(side * (width / 2 - 3.5), 0, 2.5) * CFrame.Angles(0, math.pi / 2, 0),
			depth - 10,
			6.5,
			9.2,
			1.2
		)
		part(
			model,
			"UpperShutter",
			Vector3.new(3, 3, 0.2),
			Vector3.new(side * width * 0.23, 12, -depth / 2 + 7.1),
			palette.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"CourtMosaicBorder",
		Vector3.new(width - 12, 0.12, depth - 10),
		Vector3.new(0, 1.1, 2),
		palette.plaster,
		Enum.Material.Marble
	)
	part(model, "CourtDrain", Vector3.new(3, 0.15, 3), Vector3.new(0, 1.2, 1), palette.stone, Enum.Material.Pebble)
	arch(model, 0, depth / 2 - 2, 7, 4.5, 0.9, 1)
end

function builders.civic(model, width, depth)
	part(
		model,
		"PrincipiaCourt",
		Vector3.new(width - 3, 0.2, depth - 3),
		Vector3.new(0, 1.1, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	block(model, "AdministrativeRange", width - 4, 8, 11, 0, -depth / 2 + 6, 1)
	roof(model, CFrame.new(0, 0, -depth / 2 + 6), width - 2, 10, 12.1, 2.2)
	for _, x in { -10, 0, 10 } do
		arch(model, x, depth * 0.25, 7.5, 6, 1.2, 2)
	end
	roof(model, CFrame.new(0, 0, depth * 0.25), width - 4, 5, 10.8, 0.8)
	for _, side in { -1, 1 } do
		block(model, "CivicSideWall", 1.5, depth * 0.45, 4, side * (width / 2 - 2), 0, 1)
	end
	part(
		model,
		"ExchangeCounter",
		Vector3.new(12, 3.2, 2.5),
		Vector3.new(0, 2.6, depth * 0.41),
		palette.stone,
		Enum.Material.Limestone
	)
	part(
		model,
		"WritingTablets",
		Vector3.new(3, 0.2, 1.6),
		Vector3.new(-3, 4.3, depth * 0.41),
		palette.wood,
		Enum.Material.Wood
	)
	vessel(model, 4, depth * 0.4, 0.6, 4.2)
end

function builders.farm(model, width, depth)
	part(
		model,
		"CultivationSoil",
		Vector3.new(width - 2, 0.7, depth - 2),
		Vector3.new(0, 1.25, 0),
		palette.clay,
		Enum.Material.Ground
	)
	for bed = -1, 1 do
		part(
			model,
			"LongCultivationStrip",
			Vector3.new(7, 0.12, depth * 0.66),
			Vector3.new(bed * 9, 1.66, -2),
			Color3.fromRGB(105, 83, 50),
			Enum.Material.Ground
		)
		for row = -3, 3 do
			for _, side in { -1, 1 } do
				local position = Vector3.new(bed * 9 + side * 1.6, 3, row * 2.7 - 2)
				part(model, "SpeltStalk", Vector3.new(0.22, 2.5, 0.22), position, Color3.fromRGB(188, 162, 83))
				part(
					model,
					"SpeltEar",
					Vector3.new(0.55, 1.3, 0.55),
					position + Vector3.new(0, 1.35, 0),
					Color3.fromRGB(212, 188, 106)
				)
			end
		end
	end
	cylinder(model, "ThreshingPad", 5, 0.18, Vector3.new(0, 1.78, depth * 0.38), palette.stone, Enum.Material.Pebble)
	part(
		model,
		"GrainMeasure",
		Vector3.new(2, 2, 2),
		Vector3.new(width * 0.35, 2.7, depth * 0.37),
		palette.wood,
		Enum.Material.Wood
	)
end

function builders.timber(model, width, depth)
	for layer = 0, 2 do
		part(
			model,
			"SawnPlankStack",
			Vector3.new(width - 6, 1.2, 4.5),
			Vector3.new(0, 1.6 + layer * 1.3, -depth * 0.3),
			palette.wood,
			Enum.Material.WoodPlanks
		)
	end
	for _, x in { -width * 0.27, width * 0.27 } do
		for _, z in { -2, 3 } do
			local leg = part(
				model,
				"SawTrestleLeg",
				Vector3.new(1, 5, 1),
				Vector3.new(x, 3.4, z),
				palette.wood,
				Enum.Material.Wood
			)
			leg.CFrame *= CFrame.Angles(if z < 0 then -0.18 else 0.18, 0, 0)
		end
	end
	part(
		model,
		"SawBenchBeam",
		Vector3.new(width - 5, 1.1, 5),
		Vector3.new(0, 6.1, 0.5),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"FrameSawBlade",
		Vector3.new(0.15, 5, 0.7),
		Vector3.new(0, 5, 2),
		Color3.fromRGB(150, 151, 140),
		Enum.Material.Metal
	)
	for _, x in { -3, 3 } do
		part(model, "SawFrame", Vector3.new(0.45, 5.8, 0.45), Vector3.new(x, 5, 2), palette.wood, Enum.Material.Wood)
	end
	part(
		model,
		"SawFrameCrossbar",
		Vector3.new(6.5, 0.5, 0.5),
		Vector3.new(0, 7.5, 2),
		palette.wood,
		Enum.Material.Wood
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClaySettlingTrough",
		Vector3.new(8, 1.4, depth - 6),
		Vector3.new(-width * 0.28, 1.7, 0),
		palette.brick,
		Enum.Material.Brick
	)
	part(
		model,
		"WetClay",
		Vector3.new(6, 0.12, depth - 8),
		Vector3.new(-width * 0.28, 2.46, 0),
		palette.clay,
		Enum.Material.Mud
	)
	part(
		model,
		"ClayWorkingSlab",
		Vector3.new(width * 0.48, 1, 9),
		Vector3.new(width * 0.19, 1.5, -depth * 0.22),
		palette.stone,
		Enum.Material.Limestone
	)
	for row = -1, 1 do
		for column = -1, 1 do
			part(
				model,
				"DryingClayLump",
				Vector3.new(2.8, 0.7, 1.7),
				Vector3.new(width * 0.19 + column * 4, 2.4, -depth * 0.22 + row * 2.4),
				palette.clay,
				Enum.Material.Ground
			)
		end
	end
	vessel(model, width * 0.18, depth * 0.28, 0.9, 1)
	vessel(model, width * 0.35, depth * 0.28, 0.65, 1)
end

function builders.workshop(model, width, depth)
	cylinder(model, "UpdraughtKiln", 7, 5, Vector3.new(-width * 0.28, 3.5, -2), palette.brick, Enum.Material.Brick)
	local dome = part(
		model,
		"KilnDome",
		Vector3.new(7, 4, 7),
		Vector3.new(-width * 0.28, 6, -2),
		palette.clay,
		Enum.Material.Ground
	)
	dome.Shape = Enum.PartType.Ball
	cylinder(model, "KilnTopFlue", 1.2, 0.3, Vector3.new(-width * 0.28, 8, -2), palette.dark)
	part(
		model,
		"KilnFireChannel",
		Vector3.new(3, 2, 6),
		Vector3.new(-width * 0.28, 2, 2.5),
		palette.brick,
		Enum.Material.Brick
	)
	part(model, "FireChannelMouth", Vector3.new(1.8, 1.3, 0.2), Vector3.new(-width * 0.28, 1.85, 5.6), palette.dark)
	block(model, "PotteryShedRear", width * 0.45, 1.5, 6, width * 0.2, -depth * 0.32, 1)
	for _, x in { 1, width * 0.4 } do
		part(
			model,
			"PotteryShedPost",
			Vector3.new(0.7, 6, 0.7),
			Vector3.new(x, 4, depth * 0.27),
			palette.wood,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.new(width * 0.2, 0, 0), width * 0.48, depth * 0.76, 7.2, 1.2)
	cylinder(model, "ThrowingWheelStand", 1.2, 2, Vector3.new(width * 0.2, 2, 2), palette.wood, Enum.Material.Wood)
	cylinder(model, "PottersWheel", 3.5, 0.35, Vector3.new(width * 0.2, 3.2, 2), palette.stone, Enum.Material.Limestone)
	vessel(model, width * 0.2, 2, 0.6, 3.4)
	vessel(model, width * 0.34, depth * 0.3, 0.8, 1)
end

function builders.storehouse(model, width, depth)
	for _, x in { -width * 0.25, width * 0.25 } do
		for _, z in { -depth * 0.28, depth * 0.28 } do
			part(
				model,
				"HorreumPila",
				Vector3.new(3, 2.5, 3),
				Vector3.new(x, 2.25, z),
				palette.stone,
				Enum.Material.Limestone
			)
		end
	end
	part(
		model,
		"RaisedHorreumFloor",
		Vector3.new(width - 4, 1, depth - 4),
		Vector3.new(0, 3.5, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	block(model, "HorreumBlock", width - 7, depth - 7, 7, 0, 0, 4)
	for _, side in { -1, 1 } do
		for _, z in { -depth * 0.29, 0, depth * 0.29 } do
			part(
				model,
				"HorreumButtress",
				Vector3.new(2.5, 8, 1.5),
				Vector3.new(side * (width / 2 - 3), 5, z),
				palette.stone,
				Enum.Material.Limestone
			)
			part(
				model,
				"VentilationSlot",
				Vector3.new(0.12, 1.2, 1.3),
				Vector3.new(side * (width / 2 - 3.45), 5.2, z + 2),
				palette.dark
			)
		end
	end
	roof(model, CFrame.Angles(0, math.pi / 2, 0), depth - 2, width - 2, 11.6, 3)
	part(
		model,
		"HorreumDoor",
		Vector3.new(5, 5, 0.2),
		Vector3.new(0, 6.5, (depth - 7) / 2 + 0.12),
		palette.wood,
		Enum.Material.WoodPlanks
	)
	for step = 1, 3 do
		part(
			model,
			"LoadingStep",
			Vector3.new(5.5, step, 1),
			Vector3.new(0, 1 + step / 2, depth / 2 - step),
			palette.stone,
			Enum.Material.Limestone
		)
	end
end

function builders.training(model, width, depth)
	part(
		model,
		"BarrackDrillCourt",
		Vector3.new(width - 3, 0.2, depth - 3),
		Vector3.new(0, 1.1, 0),
		Color3.fromRGB(183, 168, 132),
		Enum.Material.Sand
	)
	block(model, "CellularBarrackRange", width - 4, 7, 7.5, 0, -depth / 2 + 6, 1)
	roof(model, CFrame.new(0, 0, -depth / 2 + 6), width - 2, 9, 8.8, 1.8)
	for _, x in { -12, -4, 4, 12 } do
		part(
			model,
			"BarrackDoor",
			Vector3.new(3, 5, 0.2),
			Vector3.new(x, 3.5, -depth / 2 + 9.6),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"CourtTrainingPost",
			Vector3.new(0.7, 5, 0.7),
			Vector3.new(x, 3.5, -3),
			palette.wood,
			Enum.Material.Wood
		)
	end
end

function builders.healer(model, width, depth)
	part(
		model,
		"TreatmentFloor",
		Vector3.new(width - 2, 1, depth - 2),
		Vector3.new(0, 1.5, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	block(model, "TreatmentRearRange", width - 4, 6, 7, 0, -depth / 2 + 4, 2)
	roof(model, CFrame.new(0, 0, -depth / 2 + 4), width - 2, 8, 9.3, 1.3)
	for _, side in { -1, 1 } do
		block(model, "TreatmentSideWall", 1.2, depth * 0.48, 5, side * (width / 2 - 2), 1, 2)
		part(
			model,
			"TreatmentBench",
			Vector3.new(3, 1.3, 7),
			Vector3.new(side * width * 0.28, 2.65, -0.5),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"LinenCouch",
			Vector3.new(2.8, 0.3, 6),
			Vector3.new(side * width * 0.28, 3.45, -0.5),
			palette.plaster,
			Enum.Material.Fabric
		)
	end
	arch(model, 0, depth / 2 - 4, 7, 5, 1, 1)
	cylinder(
		model,
		"TreatmentBasin",
		2.4,
		0.8,
		Vector3.new(-width * 0.28, 3.8, depth * 0.3),
		palette.stone,
		Enum.Material.Limestone
	)
end

function RomanKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function RomanKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("rome")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Roman building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"RomanFoundation",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		palette.stone,
		Enum.Material.Limestone
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "rome")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Roman Sandbox Art.md")
	return model
end

local function rod(model, name, a, b, thickness, color, material)
	local object = part(model, name, Vector3.new(thickness, (b - a).Magnitude, thickness), (a + b) / 2, color, material)
	object.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0)
	return object
end

function RomanKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Roman presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(199, 157, 115)
	local iron = Color3.fromRGB(153, 156, 149)
	local tunic = if role == "melee"
		then Color3.fromRGB(155, 55, 43)
		elseif role == "ranged" then Color3.fromRGB(125, 137, 98)
		else palette.plaster
	local colors = Instance.new("BodyColors")
	colors.HeadColor3, colors.TorsoColor3 = skin, skin
	colors.LeftArmColor3, colors.RightArmColor3 = skin, skin
	colors.LeftLegColor3, colors.RightLegColor3 = skin, skin
	colors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "RomanTunic", Vector3.new(1.98, 2.05, 1.07), Vector3.new(0, 3.05, 0), tunic, Enum.Material.Fabric)
	part(
		model,
		"TunicSkirt",
		Vector3.new(2.08, if role == "ranged" then 1.5 else 1, 1.15),
		Vector3.new(0, 2.05, 0),
		tunic,
		Enum.Material.Fabric
	)
	part(
		model,
		"MilitaryBelt",
		Vector3.new(2.1, 0.2, 1.2),
		Vector3.new(0, 2.65, 0),
		palette.wood,
		Enum.Material.Leather
	)
	for _, side in { -1, 1 } do
		local label = if side < 0 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			"CaligaSole",
			Vector3.new(0.88, 0.25, 1.1),
			Vector3.new(side * 0.5, 0.125, -0.1),
			palette.wood,
			Enum.Material.Leather
		)
		for band = 1, 2 do
			part(
				model,
				"SandalStrapping",
				Vector3.new(0.88, 0.14, 0.65),
				Vector3.new(side * 0.5, 0.3 + band * 0.14, 0),
				palette.wood,
				Enum.Material.Leather
			)
		end
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	if role == "melee" then
		for band = 0, 4 do
			part(
				model,
				"SegmentataBand",
				Vector3.new(2.12, 0.27, 1.2),
				Vector3.new(0, 2.9 + band * 0.29, 0),
				iron,
				Enum.Material.Metal
			)
		end
		for _, side in { -1, 1 } do
			part(
				model,
				"SegmentataShoulder",
				Vector3.new(0.8, 0.25, 1.25),
				Vector3.new(side * 1.1, 4.05, 0),
				iron,
				Enum.Material.Metal
			)
			part(
				model,
				"HelmetCheekPlate",
				Vector3.new(0.2, 0.65, 0.7),
				Vector3.new(side * 0.65, 4.65, -0.25),
				iron,
				Enum.Material.Metal
			)
		end
		local helmet = part(
			model,
			"ImperialHelmet",
			Vector3.new(1.65, 0.9, 1.6),
			Vector3.new(0, 5.3, 0.1),
			iron,
			Enum.Material.Metal
		)
		helmet.Shape = Enum.PartType.Ball
		part(
			model,
			"HelmetNeckGuard",
			Vector3.new(1.9, 0.18, 0.7),
			Vector3.new(0, 4.9, 0.75),
			iron,
			Enum.Material.Metal
		)
		part(
			model,
			"HelmetBrowGuard",
			Vector3.new(1.7, 0.2, 0.4),
			Vector3.new(0, 5.1, -0.65),
			iron,
			Enum.Material.Metal
		)
		for index = -1, 1 do
			local angle = index * 0.5
			local shield = part(
				model,
				"ScutumPanel",
				Vector3.new(0.9, 3.2, 0.16),
				Vector3.new(-1.4 + math.sin(angle) * 1.6, 2.8, -0.6 - math.cos(angle) * 0.45),
				tunic,
				Enum.Material.Wood
			)
			shield.CFrame *= CFrame.Angles(0, -angle, 0)
		end
		local boss = part(
			model,
			"ScutumBoss",
			Vector3.new(0.7, 0.7, 0.35),
			Vector3.new(-1.4, 2.8, -1.2),
			iron,
			Enum.Material.Metal
		)
		boss.Shape = Enum.PartType.Ball
		part(
			model,
			"GladiusBlade",
			Vector3.new(0.3, 2.1, 0.12),
			Vector3.new(1.4, 1.55, -0.25),
			iron,
			Enum.Material.Metal
		)
		part(
			model,
			"GladiusGuard",
			Vector3.new(0.65, 0.18, 0.3),
			Vector3.new(1.4, 2.65, -0.25),
			palette.wood,
			Enum.Material.Wood
		)
		part(model, "GladiusGrip", Vector3.new(0.22, 0.6, 0.22), Vector3.new(1.4, 3, -0.25), palette.plaster)
	elseif role == "ranged" then
		for layer = 0, 5 do
			cylinder(
				model,
				"ConicalArcherHelmet",
				1.6 - layer * 0.25,
				0.15,
				Vector3.new(0, 5.3 + layer * 0.13, 0.05),
				iron,
				Enum.Material.Metal
			)
		end
		part(
			model,
			"ArcherQuiver",
			Vector3.new(0.7, 2, 0.55),
			Vector3.new(0.6, 3.4, 0.85),
			palette.wood,
			Enum.Material.Leather
		)
		for arrow = 0, 2 do
			part(
				model,
				"QuiverArrow",
				Vector3.new(0.08, 1.7, 0.08),
				Vector3.new(0.4 + arrow * 0.2, 4.5, 0.85),
				palette.wood,
				Enum.Material.Wood
			)
		end
		local points = {
			Vector3.new(-1.55, 1, -0.45),
			Vector3.new(-1.95, 1.6, -0.45),
			Vector3.new(-1.65, 2.45, -0.45),
			Vector3.new(-1.85, 3.2, -0.45),
			Vector3.new(-1.65, 4.05, -0.45),
			Vector3.new(-1.95, 4.8, -0.45),
			Vector3.new(-1.55, 5.4, -0.45),
		}
		for index = 1, #points - 1 do
			rod(model, "RecurveBowLimb", points[index], points[index + 1], 0.13, palette.wood, Enum.Material.Wood)
		end
		rod(model, "Bowstring", points[1], points[#points], 0.045, palette.plaster, Enum.Material.Fabric)
	else
		part(
			model,
			"MedicalCase",
			Vector3.new(1.1, 1.1, 0.6),
			Vector3.new(-1.25, 2.25, -0.15),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"RolledLinen",
			Vector3.new(0.85, 0.3, 0.65),
			Vector3.new(1.35, 2.2, -0.2),
			Color3.fromRGB(237, 228, 207),
			Enum.Material.Fabric
		)
		part(model, "Hair", Vector3.new(1.45, 0.35, 1.35), Vector3.new(0, 5.3, 0.1), palette.dark)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "rome")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Roman Sandbox Art.md")
	return model
end

return RomanKit

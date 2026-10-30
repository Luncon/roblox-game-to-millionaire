--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local SpanishKit = {}
local colors = {
	plaster = Color3.fromRGB(219, 202, 170),
	brick = Color3.fromRGB(158, 102, 72),
	tile = Color3.fromRGB(164, 84, 52),
	stone = Color3.fromRGB(168, 155, 129),
	wood = Color3.fromRGB(102, 70, 43),
	earth = Color3.fromRGB(123, 94, 55),
	clay = Color3.fromRGB(157, 112, 77),
	shadow = Color3.fromRGB(48, 45, 39),
	linen = Color3.fromRGB(225, 214, 185),
	blue = Color3.fromRGB(81, 110, 137),
}

local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end

local function tileRoof(model, width, depth, x, z, top)
	local half, angle = width / 2 - 0.3, math.rad(22)
	local rise = math.tan(angle) * half
	for _, side in { -1, 1 } do
		local roof = part(
			model,
			"ClayTileRoof",
			Vector3.new(half / math.cos(angle), 0.6, depth),
			Vector3.new(x + side * half / 2, top + rise / 2, z),
			colors.tile,
			Enum.Material.Slate
		)
		roof.CFrame *= CFrame.Angles(0, 0, -side * angle)
	end
	part(
		model,
		"PlainRoofRidge",
		Vector3.new(0.7, 0.5, depth),
		Vector3.new(x, top + rise + 0.2, z),
		colors.tile,
		Enum.Material.Slate
	)
end

local function room(model, width, depth, x, z, height)
	part(
		model,
		"PlasterBrickRoom",
		Vector3.new(width - 1.2, height, depth - 1.2),
		Vector3.new(x, 1 + height / 2, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"BrickCornerPier",
			Vector3.new(0.8, height, 0.7),
			Vector3.new(x + side * (width / 2 - 0.8), 1 + height / 2, z + (depth - 1.2) / 2),
			colors.brick,
			Enum.Material.Brick
		)
	end
	part(
		model,
		"PlainTimberDoor",
		Vector3.new(2.5, height * 0.7, 0.15),
		Vector3.new(x, 1 + height * 0.35, z + (depth - 1.2) / 2 + 0.1),
		colors.wood,
		Enum.Material.Wood
	)
	tileRoof(model, width, depth, x, z, height + 1)
end

local function vessel(model, x, z, scale, floor)
	local bottom = floor or 1
	local jar = part(
		model,
		"PlainEarthenJar",
		Vector3.new(2.2, 2.8, 2.2) * scale,
		Vector3.new(x, bottom + 1.4 * scale, z),
		colors.clay,
		Enum.Material.CeramicTiles
	)
	jar.Shape = Enum.PartType.Ball
	local lip = part(
		model,
		"JarLip",
		Vector3.new(0.5, 1.2, 1.2) * scale,
		Vector3.new(x, bottom + 2.7 * scale, z),
		colors.blue,
		Enum.Material.CeramicTiles
	)
	lip.Shape = Enum.PartType.Cylinder
	lip.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

local function arcade(model, width, z)
	for _, x in { -width * 0.375, -width * 0.125, width * 0.125, width * 0.375 } do
		part(
			model,
			"StoneArcadePier",
			Vector3.new(1.2, 5, 1.6),
			Vector3.new(x, 3.5, z),
			colors.stone,
			Enum.Material.Limestone
		)
	end
	local radius = width * 0.11
	for _, x in { -width * 0.25, 0, width * 0.25 } do
		for segment = 1, 9 do
			local angle = (segment - 0.5) * math.pi / 9
			local voussoir = part(
				model,
				"ArcadeVoussoir",
				Vector3.new(2 * radius * math.sin(math.pi / 18) + 0.08, 0.8, 1.6),
				Vector3.new(x + math.cos(angle) * radius, 6 + math.sin(angle) * radius, z),
				colors.stone,
				Enum.Material.Limestone
			)
			voussoir.CFrame *= CFrame.Angles(0, 0, angle + math.pi / 2)
		end
	end
end

local builders = {}
function builders.house(model, width, depth)
	room(model, width * 0.79, depth * 0.34, 0, -depth * 0.27, 10)
	part(
		model,
		"PatioPaving",
		Vector3.new(width * 0.73, 0.15, depth * 0.43),
		Vector3.new(0, 1.1, depth * 0.16),
		colors.stone,
		Enum.Material.Pavement
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"TimberPatioPost",
			Vector3.new(0.6, 7, 0.6),
			Vector3.new(side * width * 0.32, 4.5, depth * 0.26),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"PatioSideWall",
			Vector3.new(0.7, 3, depth * 0.43),
			Vector3.new(side * width * 0.41, 2.5, depth * 0.16),
			colors.plaster,
			Enum.Material.Plaster
		)
	end
	part(
		model,
		"UpperTimberGallery",
		Vector3.new(width * 0.7, 0.6, depth * 0.2),
		Vector3.new(0, 7.6, depth * 0.17),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"GalleryRail",
		Vector3.new(width * 0.7, 0.3, 0.3),
		Vector3.new(0, 9.1, depth * 0.27),
		colors.wood,
		Enum.Material.Wood
	)
	for index = -3, 3 do
		part(
			model,
			"GalleryBaluster",
			Vector3.new(0.2, 1.4, 0.2),
			Vector3.new(index * width * 0.1, 8.4, depth * 0.27),
			colors.wood,
			Enum.Material.Wood
		)
	end
	vessel(model, width * 0.25, depth * 0.22, 0.7)
end

function builders.civic(model, width, depth)
	room(model, width * 0.82, depth * 0.34, 0, -depth * 0.25, 13)
	part(
		model,
		"MarketForecourt",
		Vector3.new(width * 0.84, 0.2, depth * 0.43),
		Vector3.new(0, 1.1, depth * 0.19),
		colors.stone,
		Enum.Material.Pavement
	)
	arcade(model, width, depth * 0.23)
	local springTop = 6 + width * 0.11
	part(
		model,
		"UpperMarketGallery",
		Vector3.new(width * 0.82, 3.2, depth * 0.2),
		Vector3.new(0, springTop + 1.6, depth * 0.16),
		colors.brick,
		Enum.Material.Brick
	)
	for _, x in { -width * 0.25, 0, width * 0.25 } do
		part(
			model,
			"GalleryWindow",
			Vector3.new(2, 1.6, 0.15),
			Vector3.new(x, springTop + 1.7, depth * 0.26 + 0.1),
			colors.shadow
		)
	end
	tileRoof(model, width * 0.88, depth * 0.3, 0, depth * 0.16, springTop + 3.3)
	part(
		model,
		"MarketCounter",
		Vector3.new(9, 2.3, 2.5),
		Vector3.new(0, 2.15, depth * 0.26),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	vessel(model, -width * 0.28, depth * 0.12, 0.8)
end

function builders.farm(model, width, depth)
	part(
		model,
		"DryGrainField",
		Vector3.new(width - 3, 0.4, depth - 3),
		Vector3.new(0, 1.2, 0),
		colors.earth,
		Enum.Material.Ground
	)
	for row = -2, 2 do
		part(
			model,
			"FieldFurrow",
			Vector3.new(width * 0.82, 0.25, 0.6),
			Vector3.new(0, 1.5, row * depth * 0.15),
			colors.clay,
			Enum.Material.Ground
		)
		for column = -3, 3 do
			part(
				model,
				"GrainStem",
				Vector3.new(0.22, 2.5, 0.22),
				Vector3.new(column * width * 0.11, 2.8, row * depth * 0.15),
				Color3.fromRGB(192, 165, 87),
				Enum.Material.Grass
			)
			part(
				model,
				"GrainHead",
				Vector3.new(0.55, 0.9, 0.5),
				Vector3.new(column * width * 0.11, 4.2, row * depth * 0.15),
				Color3.fromRGB(219, 187, 105),
				Enum.Material.Grass
			)
		end
	end
	vessel(model, width * 0.36, depth * 0.35, 0.75)
end

function builders.timber(model, width, depth)
	for _, side in { -1, 1 } do
		part(
			model,
			"CarpenterShedPost",
			Vector3.new(0.8, 7, 0.8),
			Vector3.new(side * width * 0.31, 4.5, -depth * 0.17),
			colors.wood,
			Enum.Material.Wood
		)
	end
	local shed = part(
		model,
		"LeanTileShed",
		Vector3.new(width * 0.78, 0.6, depth * 0.56),
		Vector3.new(0, 8, -depth * 0.15),
		colors.tile,
		Enum.Material.Slate
	)
	shed.CFrame *= CFrame.Angles(math.rad(10), 0, 0)
	for row = 0, 2 do
		part(
			model,
			"SquaredTimberStock",
			Vector3.new(width * 0.63, 1, 2.4),
			Vector3.new(0, 1.8 + row * 1.05, -depth * 0.2),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"CarpenterBench",
		Vector3.new(width * 0.63, 2.2, depth * 0.21),
		Vector3.new(0, 2.1, depth * 0.27),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"HandPlaneBlock",
		Vector3.new(2.5, 0.6, 0.9),
		Vector3.new(1.5, 3.5, depth * 0.27),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayTreadingBed",
		Vector3.new(width * 0.6, 0.5, depth * 0.65),
		Vector3.new(-width * 0.12, 1.25, 0),
		colors.clay,
		Enum.Material.Mud
	)
	part(
		model,
		"SettlingTrough",
		Vector3.new(width * 0.25, 1, depth * 0.3),
		Vector3.new(width * 0.29, 1.5, -depth * 0.18),
		colors.brick,
		Enum.Material.Brick
	)
	for index = 0, 2 do
		part(
			model,
			"PreparedClay",
			Vector3.new(2.1, 1, 1.9),
			Vector3.new(width * 0.27, 1.6, depth * 0.05 + index * 2.2),
			colors.clay,
			Enum.Material.Mud
		)
	end
end

function builders.workshop(model, width, depth)
	room(model, width * 0.43, depth * 0.63, -width * 0.24, -depth * 0.1, 7)
	local chamber = part(
		model,
		"KilnCombustionChamber",
		Vector3.new(4.4, 6, 6),
		Vector3.new(width * 0.23, 3.2, -depth * 0.19),
		colors.brick,
		Enum.Material.Brick
	)
	chamber.Shape = Enum.PartType.Cylinder
	chamber.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	part(
		model,
		"KilnFirebox",
		Vector3.new(2.3, 1.8, 0.15),
		Vector3.new(width * 0.23, 2, -depth * 0.19 + 3.3),
		colors.shadow
	)
	part(
		model,
		"KilnChimney",
		Vector3.new(1.7, 2.4, 1.7),
		Vector3.new(width * 0.23, 6.3, -depth * 0.25),
		colors.brick,
		Enum.Material.Brick
	)
	part(
		model,
		"PotterDryingBench",
		Vector3.new(width * 0.66, 2.2, 2.6),
		Vector3.new(0, 2.1, depth * 0.29),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -width * 0.22, 0, width * 0.22 } do
		vessel(model, x, depth * 0.29, 0.7, 3.2)
	end
end

function builders.storehouse(model, width, depth)
	room(model, width * 0.78, depth * 0.72, 0, 0, 11)
	part(
		model,
		"StoneDampCourse",
		Vector3.new(width * 0.8, 1.2, depth * 0.75),
		Vector3.new(0, 1.6, 0),
		colors.stone,
		Enum.Material.Limestone
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"GranaryVent",
			Vector3.new(0.15, 0.8, depth * 0.2),
			Vector3.new(side * width * 0.375, 8, 0),
			colors.shadow
		)
	end
	part(
		model,
		"BracedStoreDoor",
		Vector3.new(3, 0.6, 0.3),
		Vector3.new(0, 4.2, depth * 0.36 - 0.35),
		colors.wood,
		Enum.Material.Wood
	)
	for _, x in { -width * 0.25, width * 0.25 } do
		local sack = part(
			model,
			"GrainSack",
			Vector3.new(2.7, 3, 2.2),
			Vector3.new(x, 2.5, depth * 0.33),
			Color3.fromRGB(176, 155, 111),
			Enum.Material.Fabric
		)
		sack.Shape = Enum.PartType.Ball
	end
end

function builders.training(model, width, depth)
	part(
		model,
		"DrillYard",
		Vector3.new(width - 3, 0.15, depth - 3),
		Vector3.new(0, 1.1, 0),
		colors.earth,
		Enum.Material.Ground
	)
	room(model, width * 0.34, depth * 0.3, -width * 0.27, -depth * 0.29, 7)
	for index = 0, 2 do
		part(
			model,
			"CrossbowButt",
			Vector3.new(2.6, 3.5, 0.8),
			Vector3.new(index * width * 0.17, 3.5, -depth * 0.25),
			Color3.fromRGB(179, 155, 103),
			Enum.Material.Fabric
		)
	end
	part(
		model,
		"PikeRack",
		Vector3.new(width * 0.64, 2.5, 1),
		Vector3.new(0, 2.25, depth * 0.27),
		colors.wood,
		Enum.Material.Wood
	)
	for index = -2, 2 do
		part(
			model,
			"PracticePike",
			Vector3.new(0.17, 8.5, 0.17),
			Vector3.new(index * 2, 5.3, depth * 0.27),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

function builders.healer(model, width, depth)
	room(model, width * 0.72, depth * 0.35, 0, -depth * 0.27, 7)
	part(
		model,
		"CarePatio",
		Vector3.new(width * 0.7, 0.18, depth * 0.36),
		Vector3.new(0, 1.15, depth * 0.2),
		colors.stone,
		Enum.Material.Pavement
	)
	part(
		model,
		"PlainTreatmentChair",
		Vector3.new(3, 2.1, 3),
		Vector3.new(-width * 0.18, 2.05, depth * 0.15),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"ChairBack",
		Vector3.new(3, 3.8, 0.5),
		Vector3.new(-width * 0.18, 4.2, depth * 0.15 + 1.3),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"SupplyTable",
		Vector3.new(3, 2.3, 2.5),
		Vector3.new(width * 0.22, 2.15, depth * 0.17),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	vessel(model, width * 0.22, depth * 0.17, 0.6, 3.3)
end

function SpanishKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function SpanishKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("spain")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Spanish building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"StoneEarthFooting",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.stone,
		Enum.Material.Limestone
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "spain")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Spanish Sandbox Art.md")
	return model
end

function SpanishKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Spanish presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(202, 160, 123)
	local cloth = if role == "medic"
		then colors.linen
		elseif role == "ranged" then colors.blue
		else Color3.fromRGB(147, 74, 57)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.8, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "PlainDoublet", Vector3.new(1.95, 2.05, 1.1), Vector3.new(0, 3.1, 0), cloth, Enum.Material.Fabric)
	part(model, "PlainBreeches", Vector3.new(1.85, 1.1, 1.15), Vector3.new(0, 1.9, 0), cloth, Enum.Material.Fabric)
	part(model, "LeatherBelt", Vector3.new(2.05, 0.22, 1.2), Vector3.new(0, 2.7, 0), colors.wood, Enum.Material.Leather)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.3, 3.1, 0), skin)
		part(
			model,
			label .. " Sleeve",
			Vector3.new(0.85, 1.5, 0.9),
			Vector3.new(side * 1.3, 3.25, 0),
			cloth,
			Enum.Material.Fabric
		)
		part(model, label .. " Leg", Vector3.new(0.75, 1.8, 0.8), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Hose",
			Vector3.new(0.8, 1.5, 0.86),
			Vector3.new(side * 0.5, 1, 0),
			colors.shadow,
			Enum.Material.Fabric
		)
		part(
			model,
			label .. " Shoe",
			Vector3.new(0.85, 0.3, 1.1),
			Vector3.new(side * 0.5, 0.2, -0.1),
			colors.wood,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	if role == "melee" then
		local crown = part(
			model,
			"MorionCrown",
			Vector3.new(1.55, 0.85, 1.5),
			Vector3.new(0, 5.25, 0.05),
			colors.stone,
			Enum.Material.Metal
		)
		crown.Shape = Enum.PartType.Ball
		part(model, "MorionBrim", Vector3.new(1.95, 0.16, 1.9), Vector3.new(0, 5, 0), colors.stone, Enum.Material.Metal)
		part(
			model,
			"MorionComb",
			Vector3.new(0.18, 0.65, 1.4),
			Vector3.new(0, 5.8, 0.05),
			colors.stone,
			Enum.Material.Metal
		)
		part(
			model,
			"PlainCuirass",
			Vector3.new(2, 1.65, 1.2),
			Vector3.new(0, 3.2, -0.02),
			colors.stone,
			Enum.Material.Metal
		)
		part(
			model,
			"PikeShaft",
			Vector3.new(0.15, 10, 0.15),
			Vector3.new(1.5, 5.3, -0.25),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"PikeHead",
			Vector3.new(0.28, 0.75, 0.16),
			Vector3.new(1.5, 10.6, -0.25),
			colors.stone,
			Enum.Material.Metal
		)
	else
		part(
			model,
			"PlainClothCap",
			Vector3.new(1.5, 0.55, 1.4),
			Vector3.new(0, 5.25, 0.05),
			colors.shadow,
			Enum.Material.Fabric
		)
		if role == "ranged" then
			part(
				model,
				"CrossbowStock",
				Vector3.new(0.28, 0.3, 2.5),
				Vector3.new(1.3, 2.8, -0.65),
				colors.wood,
				Enum.Material.Wood
			)
			for _, side in { -1, 1 } do
				local limb = part(
					model,
					"CrossbowLimb",
					Vector3.new(1.15, 0.12, 0.16),
					Vector3.new(1.3 + side * 0.5, 2.8, -1.7),
					colors.stone,
					Enum.Material.Metal
				)
				limb.CFrame *= CFrame.Angles(0, side * 0.15, 0)
			end
			part(
				model,
				"CrossbowString",
				Vector3.new(1.95, 0.035, 0.035),
				Vector3.new(1.3, 2.8, -1.5),
				colors.linen,
				Enum.Material.Fabric
			)
			part(
				model,
				"BoltCase",
				Vector3.new(0.65, 1.2, 0.5),
				Vector3.new(-1, 2.3, -0.2),
				colors.wood,
				Enum.Material.Leather
			)
		else
			part(
				model,
				"CareSatchel",
				Vector3.new(0.85, 1.1, 0.5),
				Vector3.new(-1.1, 2.4, -0.25),
				colors.wood,
				Enum.Material.Leather
			)
			part(
				model,
				"FoldedBandage",
				Vector3.new(0.85, 0.25, 0.75),
				Vector3.new(1.3, 2.2, -0.25),
				colors.linen,
				Enum.Material.Fabric
			)
		end
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "spain")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Spanish Sandbox Art.md")
	return model
end

return SpanishKit

--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local SpartanKit = {}

local colors = {
	plaster = Color3.fromRGB(218, 206, 176),
	stone = Color3.fromRGB(177, 164, 137),
	tile = Color3.fromRGB(151, 68, 44),
	wood = Color3.fromRGB(109, 77, 47),
	shadow = Color3.fromRGB(49, 58, 51),
	soil = Color3.fromRGB(112, 81, 48),
	grain = Color3.fromRGB(220, 184, 79),
	cloth = Color3.fromRGB(173, 142, 91),
}

local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = CFrame.new(position)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end

local function roof(model, width, depth, wallTop, centerZ)
	local angle = math.rad(22)
	local half = width / 2 - 0.4
	local rise = math.tan(angle) * half
	for _, side in { -1, 1 } do
		local slab = part(
			model,
			"TerracottaRoof",
			Vector3.new(half / math.cos(angle), 0.7, depth),
			Vector3.new(side * half / 2, wallTop + rise / 2, centerZ),
			colors.tile,
			Enum.Material.Slate
		)
		slab.CFrame *= CFrame.Angles(0, 0, -side * angle)
		-- Rounded seams evoke Laconian cover tiles; the underlying pans remain simplified.
		local seams = math.max(2, math.floor(depth / 3))
		for index = 1, seams do
			local cover = part(
				model,
				"RoundedCoverTiles",
				Vector3.new(half / math.cos(angle), 0.65, 0.65),
				Vector3.new(
					side * half / 2,
					wallTop + rise / 2 + 0.4,
					centerZ - depth / 2 + index * depth / (seams + 1)
				),
				colors.tile,
				Enum.Material.Slate
			)
			cover.Shape = Enum.PartType.Cylinder
			cover.CFrame *= CFrame.Angles(0, 0, -side * angle)
		end
	end
	part(
		model,
		"RidgeTiles",
		Vector3.new(0.9, 0.7, depth),
		Vector3.new(0, wallTop + rise, centerZ),
		colors.tile,
		Enum.Material.Slate
	)
end

local function room(model, width, depth, centerZ, height)
	part(
		model,
		"PlasteredRoom",
		Vector3.new(width - 3, height, depth - 3),
		Vector3.new(0, 1 + height / 2, centerZ),
		colors.plaster,
		Enum.Material.Plaster
	)
	part(
		model,
		"TimberDoor",
		Vector3.new(3, height * 0.7, 0.2),
		Vector3.new(0, 1 + height * 0.35, centerZ + (depth - 3) / 2 + 0.12),
		colors.wood,
		Enum.Material.Wood
	)
	roof(model, width, depth, height + 1, centerZ)
end

local function jar(model, x, z, scale)
	local vessel = part(
		model,
		"ClayVessel",
		Vector3.new(2.2, 3.2, 2.2) * scale,
		Vector3.new(x, 1 + 1.6 * scale, z),
		colors.tile,
		Enum.Material.CeramicTiles
	)
	vessel.Shape = Enum.PartType.Ball
	local lip = part(
		model,
		"VesselMouth",
		Vector3.new(0.4, 1.2, 1.2) * scale,
		Vector3.new(x, 1 + 3.1 * scale, z),
		colors.shadow,
		Enum.Material.SmoothPlastic
	)
	lip.Shape = Enum.PartType.Cylinder
	lip.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

local builders = {}

function builders.house(model, width, depth)
	room(model, width - 2, depth * 0.58, -depth * 0.18, 10)
	for _, side in { -1, 1 } do
		part(
			model,
			"CourtyardWall",
			Vector3.new(1.2, 3.2, depth * 0.37),
			Vector3.new(side * (width / 2 - 1.8), 2.6, depth * 0.28),
			colors.plaster,
			Enum.Material.Plaster
		)
	end
	part(
		model,
		"CourtPaving",
		Vector3.new(width - 4, 0.15, depth * 0.3),
		Vector3.new(0, 1.1, depth * 0.3),
		colors.stone,
		Enum.Material.Pebble
	)
	jar(model, width * 0.3, depth * 0.3, 0.8)
end

function builders.civic(model, width, depth)
	room(model, width - 2, depth * 0.36, -depth * 0.28, 12)
	for _, side in { -1, 1 } do
		part(
			model,
			"CouncilWing",
			Vector3.new(5, 8, depth * 0.4),
			Vector3.new(side * (width / 2 - 3.5), 5, depth * 0.13),
			colors.plaster,
			Enum.Material.Plaster
		)
		for _, z in { depth * 0.06, depth * 0.3 } do
			part(
				model,
				"TimberPorticoPost",
				Vector3.new(1.2, 8.5, 1.2),
				Vector3.new(side * (width / 2 - 8), 5.25, z),
				colors.wood,
				Enum.Material.Wood
			)
		end
		part(
			model,
			"PorticoLintel",
			Vector3.new(5.5, 1, depth * 0.35),
			Vector3.new(side * (width / 2 - 6), 9.8, depth * 0.17),
			colors.stone,
			Enum.Material.Limestone
		)
	end
	part(
		model,
		"TradeCounter",
		Vector3.new(10, 3, 3),
		Vector3.new(0, 2.5, depth * 0.32),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"TradeCanopy",
		Vector3.new(13, 0.5, 6),
		Vector3.new(0, 8.5, depth * 0.32),
		colors.cloth,
		Enum.Material.Fabric
	)
	for _, x in { -5, 5 } do
		part(
			model,
			"CanopyPost",
			Vector3.new(0.65, 7.5, 0.65),
			Vector3.new(x, 4.75, depth * 0.38),
			colors.wood,
			Enum.Material.Wood
		)
	end
	jar(model, -8, depth * 0.29, 0.8)
end

function builders.farm(model, width, depth)
	part(
		model,
		"GrainSoil",
		Vector3.new(width - 2, 0.7, depth - 2),
		Vector3.new(0, 1.25, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for row = -2, 2 do
		for column = -4, 4 do
			local position = Vector3.new(column * (width - 5) / 9, 1.7, row * (depth - 5) / 6)
			part(model, "GrainStalk", Vector3.new(0.28, 2.6, 0.28), position + Vector3.new(0, 1.3, 0), colors.grain)
			part(model, "GrainHead", Vector3.new(0.7, 1, 0.7), position + Vector3.new(0, 2.6, 0), colors.grain)
		end
	end
	for _, side in { -1, 1 } do
		part(
			model,
			"FieldMargin",
			Vector3.new(0.5, 1.8, depth - 1),
			Vector3.new(side * (width / 2 - 0.5), 1.9, 0),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

function builders.timber(model, width, depth)
	for row = 0, 2 do
		for column = -1, 1 do
			local log = part(
				model,
				"StackedTimber",
				Vector3.new(width * 0.72, 2.2, 2.2),
				Vector3.new(0, 2.2 + row * 1.9, column * 2.3 - 4),
				colors.wood,
				Enum.Material.Wood
			)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	part(
		model,
		"CarpenterBench",
		Vector3.new(width * 0.65, 3, 3),
		Vector3.new(0, 2.5, depth * 0.27),
		colors.wood,
		Enum.Material.WoodPlanks
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayBed",
		Vector3.new(width - 3, 0.6, depth - 3),
		Vector3.new(0, 1.2, 0),
		Color3.fromRGB(153, 91, 62),
		Enum.Material.Mud
	)
	for _, x in { -width * 0.3, width * 0.3 } do
		part(
			model,
			"ClayBank",
			Vector3.new(4, 2, depth * 0.65),
			Vector3.new(x, 2, -1),
			colors.soil,
			Enum.Material.Ground
		)
	end
	jar(model, -width * 0.23, depth * 0.29, 0.8)
	jar(model, width * 0.23, depth * 0.29, 0.8)
end

function builders.workshop(model, width, depth)
	room(model, width * 0.66, depth * 0.62, -depth * 0.17, 8)
	local kiln = part(
		model,
		"PotteryKiln",
		Vector3.new(6.5, 5.5, 6.5),
		Vector3.new(width * 0.32, 3.75, -depth * 0.1),
		colors.tile,
		Enum.Material.Brick
	)
	kiln.Shape = Enum.PartType.Ball
	part(
		model,
		"KilnOpening",
		Vector3.new(2, 2.2, 0.2),
		Vector3.new(width * 0.32, 2.2, -depth * 0.1 + 3.2),
		colors.shadow
	)
	part(
		model,
		"PotteryBench",
		Vector3.new(width * 0.65, 2.5, 3),
		Vector3.new(-1, 2.25, depth * 0.3),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -6, 0, 6 } do
		jar(model, x, depth * 0.3, 0.55)
	end
end

function builders.storehouse(model, width, depth)
	part(
		model,
		"RaisedStoreFloor",
		Vector3.new(width - 2, 2, depth - 2),
		Vector3.new(0, 2, 0),
		colors.stone,
		Enum.Material.Limestone
	)
	room(model, width - 2, depth - 2, 0, 11)
	for _, x in { -width * 0.25, width * 0.25 } do
		jar(model, x, depth * 0.29, 1)
	end
	part(
		model,
		"StoreDoorBracing",
		Vector3.new(5, 0.7, 0.35),
		Vector3.new(0, 5, (depth - 5) / 2 + 0.3),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.training(model, width, depth)
	part(
		model,
		"DrillCourt",
		Vector3.new(width - 2, 0.2, depth - 2),
		Vector3.new(0, 1.1, 0),
		Color3.fromRGB(181, 154, 108),
		Enum.Material.Sand
	)
	for _, x in { -width * 0.3, 0, width * 0.3 } do
		part(
			model,
			"PracticePost",
			Vector3.new(1, 7, 1),
			Vector3.new(x, 4.5, -depth * 0.25),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"PracticeCrossbar",
			Vector3.new(4, 0.7, 0.7),
			Vector3.new(x, 5, -depth * 0.25),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"EquipmentRack",
		Vector3.new(width * 0.6, 4, 1),
		Vector3.new(0, 3, depth * 0.31),
		colors.wood,
		Enum.Material.WoodPlanks
	)
end

function builders.healer(model, width, depth)
	part(
		model,
		"TreatmentPlatform",
		Vector3.new(width - 3, 1, depth - 3),
		Vector3.new(0, 1.5, 0),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -width * 0.32, width * 0.32 } do
		for _, z in { -depth * 0.32, depth * 0.32 } do
			part(
				model,
				"TreatmentPost",
				Vector3.new(0.8, 7, 0.8),
				Vector3.new(x, 4.5, z),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"LinenShade",
		Vector3.new(width - 2, 0.45, depth - 2),
		Vector3.new(0, 8.2, 0),
		Color3.fromRGB(226, 214, 182),
		Enum.Material.Fabric
	)
	part(
		model,
		"TreatmentCouch",
		Vector3.new(4, 1, depth * 0.52),
		Vector3.new(0, 2.5, -1),
		colors.cloth,
		Enum.Material.Fabric
	)
	jar(model, width * 0.26, depth * 0.2, 0.7)
end

function SpartanKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function SpartanKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("sparta")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Spartan building art: " .. kind)
	local model = Instance.new("Model")
	model.Name = kind
	model.WorldPivot = CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"Foundation",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.stone,
		Enum.Material.Limestone
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "sparta")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Spartan Sandbox Art.md")
	return model
end

-- Original passive figures: no imported rigs, Humanoids, tools or gameplay stats.
function SpartanKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Spartan presentation role")
	local model = Instance.new("Model")
	model.Name = role
	model.WorldPivot = CFrame.identity
	-- Match the existing Spartan NPC art default, not a historical population claim.
	local skin = Color3.fromRGB(196, 151, 112)
	local bronze = Color3.fromRGB(164, 128, 66)
	local tunic = if role == "melee"
		then Color3.fromRGB(155, 61, 48)
		elseif role == "ranged" then Color3.fromRGB(153, 127, 84)
		else Color3.fromRGB(226, 214, 182)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "TunicBody", Vector3.new(1.95, 2.02, 1.04), Vector3.new(0, 3.1, 0), tunic, Enum.Material.Fabric)
	part(model, "TunicHem", Vector3.new(2.05, 1, 1.15), Vector3.new(0, 2.2, 0), tunic, Enum.Material.Fabric)
	part(model, "TunicBelt", Vector3.new(2.05, 0.22, 1.15), Vector3.new(0, 2.7, 0), colors.wood, Enum.Material.Leather)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Sandal",
			Vector3.new(0.85, 0.25, 1.05),
			Vector3.new(side * 0.5, 0.125, -0.08),
			colors.wood,
			Enum.Material.Leather
		)
		part(
			model,
			label .. " SandalStrap",
			Vector3.new(0.88, 0.2, 0.55),
			Vector3.new(side * 0.5, 0.39, -0.05),
			colors.wood,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face = "face", "rbxassetid://10526794", Enum.NormalId.Front
	face.Parent = head
	if role == "melee" then
		part(model, "BronzeCuirass", Vector3.new(2.04, 1.7, 1.12), Vector3.new(0, 3.2, 0), bronze, Enum.Material.Metal)
		local helmet = part(
			model,
			"HelmetCrown",
			Vector3.new(1.65, 0.95, 1.55),
			Vector3.new(0, 5.25, 0.05),
			bronze,
			Enum.Material.Metal
		)
		helmet.Shape = Enum.PartType.Ball
		part(
			model,
			"HelmetBrow",
			Vector3.new(1.55, 0.22, 0.3),
			Vector3.new(0, 5.12, -0.62),
			bronze,
			Enum.Material.Metal
		)
		part(
			model,
			"HelmetNoseGuard",
			Vector3.new(0.14, 0.6, 0.2),
			Vector3.new(0, 4.72, -0.72),
			bronze,
			Enum.Material.Metal
		)
		for _, side in { -1, 1 } do
			part(
				model,
				"HelmetCheek",
				Vector3.new(0.28, 0.65, 0.6),
				Vector3.new(side * 0.65, 4.6, -0.35),
				bronze,
				Enum.Material.Metal
			)
			part(
				model,
				"BronzeGreave",
				Vector3.new(0.84, 1.1, 0.15),
				Vector3.new(side * 0.5, 1, -0.45),
				bronze,
				Enum.Material.Metal
			)
		end
		local shield = part(
			model,
			"RoundShield",
			Vector3.new(0.3, 2.9, 2.9),
			Vector3.new(-1.5, 3.05, -0.8),
			bronze,
			Enum.Material.Metal
		)
		shield.Shape = Enum.PartType.Cylinder
		shield.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		local boss = part(model, "ShieldFace", Vector3.new(2.3, 2.3, 0.18), Vector3.new(-1.5, 3.05, -0.99), tunic)
		boss.Shape = Enum.PartType.Ball
		local spear = part(
			model,
			"SpearShaft",
			Vector3.new(7.2, 0.14, 0.14),
			Vector3.new(1.55, 3.7, -0.3),
			colors.wood,
			Enum.Material.Wood
		)
		spear.Shape = Enum.PartType.Cylinder
		spear.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		local tip = part(
			model,
			"SpearPoint",
			Vector3.new(0.34, 0.8, 0.14),
			Vector3.new(1.55, 7.5, -0.3),
			Color3.fromRGB(142, 142, 130),
			Enum.Material.Metal
		)
		local pointMesh = Instance.new("SpecialMesh")
		pointMesh.MeshType = Enum.MeshType.Sphere
		pointMesh.Parent = tip
	elseif role == "ranged" then
		part(model, "Hair", Vector3.new(1.45, 0.4, 1.35), Vector3.new(0, 5.28, 0.08), colors.shadow)
		part(
			model,
			"SlingStonePouch",
			Vector3.new(0.75, 0.9, 0.45),
			Vector3.new(-1.05, 2.45, -0.1),
			colors.wood,
			Enum.Material.Leather
		)
		-- Two loose cords and a pouch, rather than a modern forked slingshot.
		for _, side in { -1, 1 } do
			local cord = part(
				model,
				"HandSlingCord",
				Vector3.new(0.06, 1.7, 0.06),
				Vector3.new(1.35 + side * 0.22, 1.75, -0.35),
				colors.cloth,
				Enum.Material.Fabric
			)
			cord.CFrame *= CFrame.Angles(0, 0, side * 0.22)
		end
		part(
			model,
			"HandSlingPouch",
			Vector3.new(0.6, 0.22, 0.3),
			Vector3.new(1.35, 0.9, -0.35),
			colors.wood,
			Enum.Material.Leather
		)
	else
		part(model, "Hair", Vector3.new(1.45, 0.4, 1.35), Vector3.new(0, 5.28, 0.08), colors.shadow)
		part(
			model,
			"LinenSatchel",
			Vector3.new(0.9, 1.1, 0.5),
			Vector3.new(-1.1, 2.5, -0.25),
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"FoldedBandage",
			Vector3.new(0.8, 0.28, 0.7),
			Vector3.new(1.35, 2.2, -0.2),
			Color3.fromRGB(235, 225, 203),
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "sparta")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Spartan Sandbox Art.md")
	return model
end

return SpartanKit

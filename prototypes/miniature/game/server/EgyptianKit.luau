--!strict
-- Original New Kingdom-inspired native art. See the evidence card for period limits.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local EgyptianKit = {}
local colors = {
	mud = Color3.fromRGB(166, 125, 79),
	plaster = Color3.fromRGB(223, 204, 159),
	sandstone = Color3.fromRGB(198, 171, 120),
	wood = Color3.fromRGB(110, 75, 44),
	reed = Color3.fromRGB(188, 164, 104),
	linen = Color3.fromRGB(234, 225, 198),
	clay = Color3.fromRGB(172, 91, 52),
	soil = Color3.fromRGB(94, 73, 49),
	shadow = Color3.fromRGB(55, 47, 35),
	grain = Color3.fromRGB(211, 182, 82),
	blue = Color3.fromRGB(61, 114, 126),
}
local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	return object
end
local function cylinder(model, name, diameter, height, position, color, material)
	local object = part(model, name, Vector3.new(height, diameter, diameter), position, color, material)
	object.Shape = Enum.PartType.Cylinder
	object.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	return object
end
local function jar(model, x, z, scale)
	local body = part(
		model,
		"StorageJar",
		Vector3.new(2.5, 3.2, 2.5) * scale,
		Vector3.new(x, 1 + 1.6 * scale, z),
		colors.clay,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball
	cylinder(model, "JarNeck", 1.2 * scale, 0.7 * scale, Vector3.new(x, 1 + 3.1 * scale, z), colors.clay)
	cylinder(model, "JarMouth", 0.85 * scale, 0.12 * scale, Vector3.new(x, 1 + 3.5 * scale, z), colors.shadow)
end
local function flatRoom(model, name, x, z, width, depth, height)
	part(
		model,
		name .. "Mudbrick",
		Vector3.new(width, height, depth),
		Vector3.new(x, 1 + height / 2, z),
		colors.mud,
		Enum.Material.Sandstone
	)
	part(
		model,
		name .. "FlatRoof",
		Vector3.new(width + 0.6, 0.6, depth + 0.6),
		Vector3.new(x, height + 1.3, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	for _, side in { -1, 1 } do
		part(
			model,
			name .. "RoofParapet",
			Vector3.new(0.6, 1.1, depth + 0.6),
			Vector3.new(x + side * width / 2, height + 2.1, z),
			colors.plaster,
			Enum.Material.Plaster
		)
	end
	part(
		model,
		name .. "RearParapet",
		Vector3.new(width, 1.1, 0.6),
		Vector3.new(x, height + 2.1, z - depth / 2),
		colors.plaster,
		Enum.Material.Plaster
	)
	part(
		model,
		name .. "Doorway",
		Vector3.new(2.7, height * 0.72, 0.16),
		Vector3.new(x, 1 + height * 0.36, z + depth / 2 + 0.09),
		colors.shadow
	)
	part(
		model,
		name .. "DoorLintel",
		Vector3.new(3.3, 0.65, 0.45),
		Vector3.new(x, 1.4 + height * 0.72, z + depth / 2 + 0.12),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		name .. "HighVent",
		Vector3.new(1.6, 0.75, 0.18),
		Vector3.new(x - width * 0.28, height + 0.05, z + depth / 2 + 0.1),
		colors.shadow
	)
end
local function shade(model, x, z, width, depth, height)
	for _, side in { -1, 1 } do
		for _, endSign in { -1, 1 } do
			part(
				model,
				"ShadeTimberPost",
				Vector3.new(0.6, height, 0.6),
				Vector3.new(x + side * (width / 2 - 0.5), 1 + height / 2, z + endSign * (depth / 2 - 0.5)),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"ReedShade",
		Vector3.new(width, 0.45, depth),
		Vector3.new(x, height + 1, z),
		colors.reed,
		Enum.Material.Fabric
	)
	for index = -2, 2 do
		part(
			model,
			"ShadeReedBinding",
			Vector3.new(0.13, 0.12, depth),
			Vector3.new(x + index * width / 6, height + 1.3, z),
			colors.wood
		)
	end
end
local builders = {}
function builders.house(model, width, depth)
	flatRoom(model, "House", -1, -depth * 0.17, width - 6, depth * 0.46, 8.5)
	for step = 1, 9 do
		local height = step * 0.95
		part(
			model,
			"RoofAccessStep",
			Vector3.new(2.6, height, 1.1),
			Vector3.new(width * 0.35, 1 + height / 2, depth * 0.4 - step * 1.05),
			colors.mud,
			Enum.Material.Sandstone
		)
	end
	part(
		model,
		"LowCourtWall",
		Vector3.new(width - 4, 2.5, 0.8),
		Vector3.new(0, 2.25, depth * 0.43),
		colors.mud,
		Enum.Material.Sandstone
	)
	jar(model, -width * 0.29, depth * 0.25, 0.7)
	part(
		model,
		"WovenCourtMat",
		Vector3.new(5, 0.15, 4),
		Vector3.new(-1, 1.15, depth * 0.26),
		colors.reed,
		Enum.Material.Fabric
	)
end
function builders.civic(model, width, depth)
	flatRoom(model, "CouncilOffice", 0, -depth * 0.28, width * 0.58, depth * 0.27, 10)
	for _, side in { -1, 1 } do
		-- Stepped batter is an intentionally coarse native-geometry pylon abstraction.
		for tier = 1, 3 do
			part(
				model,
				"CivicPylonBatter",
				Vector3.new(12 - tier, 4.3, 5.5 - tier * 0.3),
				Vector3.new(side * 8, 1 + (tier - 0.5) * 4.3, depth * 0.3),
				colors.sandstone,
				Enum.Material.Sandstone
			)
		end
		part(
			model,
			"PylonCavettoAbstraction",
			Vector3.new(10.6, 0.8, 5.6),
			Vector3.new(side * 8, 14.2, depth * 0.3),
			colors.plaster,
			Enum.Material.Sandstone
		)
		part(
			model,
			"LowPrecinctWall",
			Vector3.new(0.9, 3, depth * 0.5),
			Vector3.new(side * width * 0.43, 2.5, -depth * 0.03),
			colors.mud,
			Enum.Material.Sandstone
		)
	end
	part(
		model,
		"PylonDoorLintel",
		Vector3.new(6, 1.8, 3),
		Vector3.new(0, 11.4, depth * 0.3),
		colors.sandstone,
		Enum.Material.Sandstone
	)
	part(model, "ExchangeCounter", Vector3.new(10, 2.8, 2.5), Vector3.new(0, 2.4, 1.5), colors.wood, Enum.Material.Wood)
	shade(model, 0, 1.5, 12, 5, 7)
	jar(model, -7, 1, 0.8)
end
function builders.farm(model, width, depth)
	part(
		model,
		"NileSiltBed",
		Vector3.new(width - 6, 0.55, depth - 5),
		Vector3.new(1, 1.25, 0),
		colors.soil,
		Enum.Material.Ground
	)
	part(
		model,
		"IrrigationChannel",
		Vector3.new(1.8, 0.16, depth - 3),
		Vector3.new(-width * 0.42, 1.15, 0),
		colors.blue,
		Enum.Material.Glass
	)
	for row = -2, 2 do
		for column = -3, 3 do
			local x, z = 1 + column * (width - 10) / 7, row * (depth - 8) / 6
			part(model, "GrainStalk", Vector3.new(0.25, 2.3, 0.25), Vector3.new(x, 2.65, z), colors.grain)
			local head = part(model, "GrainEar", Vector3.new(0.6, 0.9, 0.5), Vector3.new(x, 3.8, z), colors.grain)
			head.Shape = Enum.PartType.Ball
		end
	end
	part(
		model,
		"HarvestBasket",
		Vector3.new(3.6, 1.4, 2.6),
		Vector3.new(width * 0.32, 1.7, depth * 0.38),
		colors.reed,
		Enum.Material.Fabric
	)
end
function builders.timber(model, width, depth)
	part(
		model,
		"SupplyCourtRearWall",
		Vector3.new(width - 3, 3.2, 0.8),
		Vector3.new(0, 2.6, -depth * 0.43),
		colors.mud,
		Enum.Material.Sandstone
	)
	shade(model, -width * 0.22, -depth * 0.15, 13, 9, 7)
	part(
		model,
		"CarpenterBench",
		Vector3.new(9, 0.7, 3),
		Vector3.new(-width * 0.22, 3.7, -depth * 0.1),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -10, -4 } do
		part(
			model,
			"BenchTrestle",
			Vector3.new(1, 2.5, 2.4),
			Vector3.new(x, 2.25, -depth * 0.1),
			colors.wood,
			Enum.Material.Wood
		)
	end
	for level = 0, 1 do
		for index = -1, 1 do
			local log = part(
				model,
				"SupplyLog",
				Vector3.new(10, 1.5, 1.5),
				Vector3.new(width * 0.23, 1.8 + level * 1.4, index * 2),
				colors.wood,
				Enum.Material.Wood
			)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	part(
		model,
		"SawnPlank",
		Vector3.new(11, 0.35, 1.7),
		Vector3.new(-2, 1.4, depth * 0.32),
		colors.reed,
		Enum.Material.WoodPlanks
	)
end
function builders.material(model, _width, depth)
	part(model, "WetClayBasin", Vector3.new(15, 0.5, 12), Vector3.new(-5, 1.1, -1), colors.clay, Enum.Material.Mud)
	for _, x in { -13, 3 } do
		part(model, "BasinMudBank", Vector3.new(1, 1, 13), Vector3.new(x, 1.5, -1), colors.mud, Enum.Material.Ground)
	end
	for row = -1, 1 do
		for column = 0, 2 do
			part(
				model,
				"DryingMudbrick",
				Vector3.new(2.4, 0.8, 1.6),
				Vector3.new(6 + column * 2.8, 1.4, row * 2.3),
				colors.mud,
				Enum.Material.Sandstone
			)
		end
	end
	part(
		model,
		"BrickMould",
		Vector3.new(3.2, 0.4, 2),
		Vector3.new(-5, 1.5, depth * 0.35),
		colors.wood,
		Enum.Material.Wood
	)
	jar(model, -11, depth * 0.3, 0.7)
end
function builders.workshop(model, _width, _depth)
	flatRoom(model, "PotterWorkroom", -8, -3, 12, 12, 7)
	cylinder(model, "KilnFiringChamber", 6.5, 6, Vector3.new(7, 4, -3), colors.clay, Enum.Material.Sandstone)
	local dome = part(
		model,
		"KilnDomeAbstraction",
		Vector3.new(6.5, 3.2, 6.5),
		Vector3.new(7, 7, -3),
		colors.clay,
		Enum.Material.Sandstone
	)
	dome.Shape = Enum.PartType.Ball
	part(model, "KilnFireHole", Vector3.new(2, 1.6, 0.2), Vector3.new(7, 2, 0.3), colors.shadow)
	cylinder(model, "PotterWheel", 3.5, 0.45, Vector3.new(1, 2, 6), colors.wood, Enum.Material.Wood)
	cylinder(model, "WheelSupport", 1.4, 0.9, Vector3.new(1, 1.45, 6), colors.mud)
	for _, x in { -9, -5, 7 } do
		jar(model, x, 6.8, 0.65)
	end
end
function builders.storehouse(model, width, depth)
	part(
		model,
		"GranaryCourtRearWall",
		Vector3.new(width - 3, 4, 1),
		Vector3.new(0, 3, -depth * 0.43),
		colors.mud,
		Enum.Material.Sandstone
	)
	for _, x in { -7, 7 } do
		cylinder(model, "GrainBin", 7.2, 8, Vector3.new(x, 5, -2), colors.mud, Enum.Material.Sandstone)
		local top = part(
			model,
			"BinDomeAbstraction",
			Vector3.new(7.2, 4.5, 7.2),
			Vector3.new(x, 9, -2),
			colors.plaster,
			Enum.Material.Plaster
		)
		top.Shape = Enum.PartType.Ball
		cylinder(model, "BinFillingMouth", 1.7, 0.2, Vector3.new(x, 11.3, -2), colors.shadow)
		part(
			model,
			"GrainDrawHatch",
			Vector3.new(1.6, 1.6, 0.2),
			Vector3.new(x, 1.9, 1.7),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"GrainAccountingTable",
		Vector3.new(6, 2.2, 2.5),
		Vector3.new(0, 2.1, depth * 0.32),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"PapyrusTally",
		Vector3.new(2.2, 0.12, 1.4),
		Vector3.new(0, 3.3, depth * 0.32),
		colors.linen,
		Enum.Material.Fabric
	)
	jar(model, 11, depth * 0.3, 0.65)
end
function builders.training(model, width, depth)
	part(
		model,
		"DrillSand",
		Vector3.new(width - 4, 0.2, depth - 4),
		Vector3.new(0, 1.1, 0),
		colors.sandstone,
		Enum.Material.Sand
	)
	shade(model, 0, -depth * 0.31, width * 0.55, 7, 7)
	for _, x in { -8, 0, 8 } do
		part(
			model,
			"PracticeScreenPost",
			Vector3.new(0.6, 6, 0.6),
			Vector3.new(x, 4, 3),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"WovenPracticeScreen",
			Vector3.new(3, 3.2, 0.4),
			Vector3.new(x, 4.6, 3),
			colors.reed,
			Enum.Material.Fabric
		)
	end
	part(
		model,
		"WeaponRackBeam",
		Vector3.new(11, 0.6, 0.7),
		Vector3.new(-width * 0.23, 4.7, depth * 0.34),
		colors.wood,
		Enum.Material.Wood
	)
	for _, x in { -14, -5 } do
		part(
			model,
			"WeaponRackUpright",
			Vector3.new(0.6, 4.5, 0.6),
			Vector3.new(x, 3.25, depth * 0.34),
			colors.wood,
			Enum.Material.Wood
		)
	end
end
function builders.healer(model, width, depth)
	flatRoom(model, "TreatmentRoom", 0, -depth * 0.25, width * 0.62, depth * 0.3, 6.5)
	shade(model, 0, depth * 0.2, 13, 9, 6)
	part(
		model,
		"TreatmentCouchFrame",
		Vector3.new(4.8, 1.3, 6.6),
		Vector3.new(-1.8, 1.65, 4.5),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"LinenCouch",
		Vector3.new(4.6, 0.35, 6.3),
		Vector3.new(-1.8, 2.5, 4.5),
		colors.linen,
		Enum.Material.Fabric
	)
	part(
		model,
		"FoldedTreatmentLinen",
		Vector3.new(2, 0.4, 1.7),
		Vector3.new(-1.8, 2.9, 3),
		colors.linen,
		Enum.Material.Fabric
	)
	jar(model, 5, 6, 0.65)
end
function EgyptianKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end
function EgyptianKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("egypt")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Egyptian building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"MudbrickFooting",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.mud,
		Enum.Material.Sandstone
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "egypt")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Egyptian Sandbox Art.md")
	model:SetAttribute("HistoricalPeriod", "New Kingdom · 1300–1200 BCE")
	return model
end
function EgyptianKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Egyptian presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	-- Match the existing Egyptian NPC art default; not a population-wide skin claim.
	local skin = Color3.fromRGB(158, 106, 65)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Sandal",
			Vector3.new(0.85, 0.2, 1),
			Vector3.new(side * 0.5, 0.1, -0.05),
			colors.wood,
			Enum.Material.Leather
		)
	end
	part(model, "LinenKilt", Vector3.new(2.1, 1.35, 1.2), Vector3.new(0, 2.15, 0), colors.linen, Enum.Material.Fabric)
	part(
		model,
		"KiltWaistband",
		Vector3.new(2.12, 0.2, 1.22),
		Vector3.new(0, 2.8, 0),
		colors.linen,
		Enum.Material.Fabric
	)
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	part(model, "ShortHair", Vector3.new(1.43, 0.32, 1.35), Vector3.new(0, 5.26, 0.05), colors.shadow)
	if role == "melee" then
		part(
			model,
			"AxeHaft",
			Vector3.new(0.16, 3.6, 0.16),
			Vector3.new(1.45, 2.8, -0.3),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"CopperAlloyAxeBlade",
			Vector3.new(1.1, 0.75, 0.16),
			Vector3.new(1.85, 4.2, -0.3),
			Color3.fromRGB(162, 124, 64),
			Enum.Material.Metal
		)
		part(
			model,
			"HideShieldBody",
			Vector3.new(1.65, 2.2, 0.25),
			Vector3.new(-1.45, 2.9, -0.65),
			colors.wood,
			Enum.Material.Leather
		)
		local top = part(
			model,
			"HideShieldRoundedTop",
			Vector3.new(1.65, 1, 0.25),
			Vector3.new(-1.45, 4, -0.65),
			colors.wood,
			Enum.Material.Leather
		)
		top.Shape = Enum.PartType.Ball
	elseif role == "ranged" then
		for _, side in { -1, 1 } do
			local limb = part(
				model,
				"BowLimb",
				Vector3.new(0.13, 1.7, 0.15),
				Vector3.new(1.4, 3 + side * 0.72, -0.4),
				colors.wood,
				Enum.Material.Wood
			)
			limb.CFrame *= CFrame.Angles(0, 0, side * 0.28)
		end
		part(
			model,
			"BowString",
			Vector3.new(0.035, 3.1, 0.035),
			Vector3.new(1.63, 3, -0.4),
			colors.linen,
			Enum.Material.Fabric
		)
		part(
			model,
			"LeatherQuiver",
			Vector3.new(0.65, 2, 0.6),
			Vector3.new(-1, 3.2, 0.65),
			colors.wood,
			Enum.Material.Leather
		)
		for index = 0, 2 do
			part(
				model,
				"ArrowShaft",
				Vector3.new(0.06, 1.2, 0.06),
				Vector3.new(-1.18 + index * 0.18, 4.2, 0.65),
				colors.reed,
				Enum.Material.Wood
			)
		end
	else
		part(
			model,
			"LinenTunic",
			Vector3.new(1.95, 2.1, 1.05),
			Vector3.new(0, 3.05, 0),
			colors.linen,
			Enum.Material.Fabric
		)
		part(
			model,
			"SupportSash",
			Vector3.new(1.98, 0.22, 1.08),
			Vector3.new(0, 2.6, 0),
			colors.blue,
			Enum.Material.Fabric
		)
		part(
			model,
			"LinenSatchel",
			Vector3.new(0.9, 1, 0.5),
			Vector3.new(-1.1, 2.25, -0.3),
			colors.reed,
			Enum.Material.Fabric
		)
		part(
			model,
			"FoldedBandage",
			Vector3.new(0.8, 0.3, 0.7),
			Vector3.new(1.35, 2.1, -0.25),
			colors.linen,
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "egypt")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Egyptian Sandbox Art.md")
	return model
end
return EgyptianKit

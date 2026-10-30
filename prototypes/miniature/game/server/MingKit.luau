--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local MingKit = {}
local colors = {
	plaster = Color3.fromRGB(219, 216, 200),
	brick = Color3.fromRGB(132, 134, 128),
	tile = Color3.fromRGB(77, 85, 84),
	wood = Color3.fromRGB(112, 77, 47),
	red = Color3.fromRGB(138, 65, 49),
	earth = Color3.fromRGB(124, 104, 69),
	clay = Color3.fromRGB(166, 124, 93),
	shadow = Color3.fromRGB(47, 49, 43),
	ceramic = Color3.fromRGB(226, 228, 214),
	blue = Color3.fromRGB(76, 108, 137),
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

local function tiledRoof(model, width, depth, x, z, top, civic)
	local half, angle = width / 2 - 0.2, math.rad(19)
	local rise = math.tan(angle) * half
	for _, side in { -1, 1 } do
		local slope = part(
			model,
			"GreyTileSlope",
			Vector3.new(half / math.cos(angle), 0.5, depth),
			Vector3.new(x + side * half / 2, top + rise / 2, z),
			colors.tile,
			Enum.Material.Slate
		)
		slope.CFrame *= CFrame.Angles(0, 0, -side * angle)
		for course = 1, 4 do
			local along = (course - 0.5) / 4
			local tile = part(
				model,
				"TileCourse",
				Vector3.new(half / math.cos(angle) * 0.27, 0.15, depth),
				Vector3.new(x + side * along * half, top + (1 - along) * rise + 0.3, z),
				colors.tile,
				Enum.Material.Slate
			)
			tile.CFrame *= CFrame.Angles(0, 0, -side * angle)
		end
		if civic then
			local eave = part(
				model,
				"RestrainedEave",
				Vector3.new(1.7, 0.4, depth),
				Vector3.new(x + side * (half - 0.25), top + 0.1, z),
				colors.tile,
				Enum.Material.Slate
			)
			eave.CFrame *= CFrame.Angles(0, 0, side * math.rad(9))
		end
	end
	part(
		model,
		"PlainTileRidge",
		Vector3.new(0.6, 0.55, depth),
		Vector3.new(x, top + rise + 0.2, z),
		colors.tile,
		Enum.Material.Slate
	)
end

local function room(model, width, depth, x, z, height, civic)
	part(
		model,
		"BrickTimberRoom",
		Vector3.new(width - 1.5, height, depth - 1.2),
		Vector3.new(x, 1 + height / 2, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	local front = z + (depth - 1.2) / 2 + 0.08
	for _, side in { -1, 1 } do
		part(
			model,
			"TimberBayPost",
			Vector3.new(0.65, height, 0.6),
			Vector3.new(x + side * width * 0.32, 1 + height / 2, front),
			if civic then colors.red else colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"TimberDoor",
		Vector3.new(2.5, height * 0.72, 0.2),
		Vector3.new(x, 1 + height * 0.36, front),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"BayLintel",
		Vector3.new(width * 0.75, 0.7, 0.65),
		Vector3.new(x, height + 0.7, front),
		if civic then colors.red else colors.wood,
		Enum.Material.Wood
	)
	tiledRoof(model, width, depth, x, z, height + 1, civic)
end

local function firewall(model, x, z, length, height)
	part(
		model,
		"SteppedFirewall",
		Vector3.new(0.9, height, length),
		Vector3.new(x, 1 + height / 2, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	for step = -1, 1 do
		local raised = if step == 0 then 2.4 else 1.2
		part(
			model,
			"FirewallStep",
			Vector3.new(0.95, raised, length / 3),
			Vector3.new(x, 1 + height + raised / 2, z + step * length / 3),
			colors.plaster,
			Enum.Material.Plaster
		)
		part(
			model,
			"GreyFirewallCap",
			Vector3.new(1.2, 0.4, length / 3 + 0.12),
			Vector3.new(x, 1 + height + raised + 0.2, z + step * length / 3),
			colors.tile,
			Enum.Material.Slate
		)
	end
end

local function jar(model, x, z, scale, floor)
	local base = floor or 1
	local vessel = part(
		model,
		"PlainCeramicJar",
		Vector3.new(2.2, 2.5, 2.2) * scale,
		Vector3.new(x, base + 1.25 * scale, z),
		colors.ceramic,
		Enum.Material.CeramicTiles
	)
	vessel.Shape = Enum.PartType.Ball
	local lip = part(
		model,
		"JarRim",
		Vector3.new(0.45, 1.2, 1.2) * scale,
		Vector3.new(x, base + 2.35 * scale, z),
		colors.blue,
		Enum.Material.CeramicTiles
	)
	lip.Shape = Enum.PartType.Cylinder
	lip.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

local builders = {}
function builders.house(model, width, depth)
	room(model, width * 0.76, depth * 0.34, 0, -depth * 0.25, 9, false)
	for _, side in { -1, 1 } do
		room(model, width * 0.24, depth * 0.39, side * width * 0.29, depth * 0.1, 7, false)
		firewall(model, side * width * 0.42, -depth * 0.06, depth * 0.78, 10)
	end
	part(
		model,
		"SkywellCourt",
		Vector3.new(width * 0.3, 0.2, depth * 0.38),
		Vector3.new(0, 1.15, depth * 0.1),
		colors.brick,
		Enum.Material.Pavement
	)
	part(
		model,
		"CourtDrain",
		Vector3.new(0.35, 0.12, depth * 0.35),
		Vector3.new(0, 1.3, depth * 0.1),
		colors.shadow,
		Enum.Material.Slate
	)
end

function builders.civic(model, width, depth)
	room(model, width * 0.76, depth * 0.39, 0, -depth * 0.23, 12, true)
	part(
		model,
		"PublicCourtyard",
		Vector3.new(width * 0.72, 0.25, depth * 0.35),
		Vector3.new(0, 1.15, depth * 0.21),
		colors.brick,
		Enum.Material.Pavement
	)
	for _, side in { -1, 1 } do
		firewall(model, side * width * 0.43, -depth * 0.08, depth * 0.74, 13)
		for _, x in { side * width * 0.13, side * width * 0.28 } do
			part(
				model,
				"CivicColumn",
				Vector3.new(0.8, 8, 0.8),
				Vector3.new(x, 5, depth * 0.025),
				colors.red,
				Enum.Material.Wood
			)
			part(
				model,
				"BracketBlock",
				Vector3.new(1.6, 0.55, 1.1),
				Vector3.new(x, 9, depth * 0.025),
				colors.wood,
				Enum.Material.Wood
			)
			part(
				model,
				"BracketArm",
				Vector3.new(2.3, 0.45, 0.7),
				Vector3.new(x, 9.5, depth * 0.025),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"OpenFrontBeam",
		Vector3.new(width * 0.68, 0.7, 1),
		Vector3.new(0, 10, depth * 0.025),
		colors.red,
		Enum.Material.Wood
	)
	tiledRoof(model, width * 0.68, depth * 0.25, 0, depth * 0.01, 10.2, true)
	part(
		model,
		"MarketCounter",
		Vector3.new(10, 2.2, 2.5),
		Vector3.new(0, 2.1, depth * 0.29),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	jar(model, -width * 0.26, depth * 0.25, 0.8)
end

function builders.farm(model, width, depth)
	part(
		model,
		"PaddyEarth",
		Vector3.new(width - 3, 0.45, depth - 3),
		Vector3.new(0, 1.2, 0),
		colors.earth,
		Enum.Material.Ground
	)
	part(
		model,
		"ShallowFieldWater",
		Vector3.new(width - 4, 0.15, depth - 4),
		Vector3.new(0, 1.5, 0),
		Color3.fromRGB(113, 132, 119),
		Enum.Material.Slate
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"PaddyBank",
			Vector3.new(0.8, 0.75, depth - 2),
			Vector3.new(side * (width / 2 - 0.9), 1.6, 0),
			colors.earth,
			Enum.Material.Ground
		)
	end
	for row = -2, 2 do
		for column = -3, 3 do
			local stem = part(
				model,
				"RiceClump",
				Vector3.new(0.35, 2.8, 0.35),
				Vector3.new(column * width * 0.11, 2.9, row * depth * 0.15),
				Color3.fromRGB(137, 150, 73),
				Enum.Material.Grass
			)
			stem.CFrame *= CFrame.Angles(0, 0, if column % 2 == 0 then 0.12 else -0.12)
		end
	end
end

function builders.timber(model, width, depth)
	for _, x in { -width * 0.3, width * 0.3 } do
		part(
			model,
			"TimberShedPost",
			Vector3.new(0.8, 7, 0.8),
			Vector3.new(x, 4.5, -depth * 0.1),
			colors.wood,
			Enum.Material.Wood
		)
	end
	tiledRoof(model, width * 0.78, depth * 0.5, 0, -depth * 0.18, 8, false)
	for row = 0, 2 do
		part(
			model,
			"SquaredBeamStock",
			Vector3.new(width * 0.66, 1.1, 2),
			Vector3.new(0, 1.8 + row * 1.15, -depth * 0.17),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"JoineryBench",
		Vector3.new(width * 0.65, 2.2, depth * 0.2),
		Vector3.new(0, 2.1, depth * 0.28),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"UnfinishedFrame",
		Vector3.new(width * 0.48, 0.7, 0.7),
		Vector3.new(0, 3.7, depth * 0.28),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClaySettlingBed",
		Vector3.new(width * 0.62, 0.5, depth * 0.66),
		Vector3.new(-width * 0.12, 1.3, 0),
		colors.clay,
		Enum.Material.Mud
	)
	for _, z in { -depth * 0.2, depth * 0.2 } do
		part(
			model,
			"SettlingPartition",
			Vector3.new(width * 0.65, 0.8, 0.6),
			Vector3.new(-width * 0.12, 1.7, z),
			colors.brick,
			Enum.Material.Brick
		)
	end
	for index = 0, 2 do
		part(
			model,
			"PreparedClayBlock",
			Vector3.new(2.3, 1.1, 2.3),
			Vector3.new(width * 0.3, 1.6, -depth * 0.23 + index * depth * 0.22),
			colors.clay,
			Enum.Material.Mud
		)
	end
end

function builders.workshop(model, width, depth)
	room(model, width * 0.44, depth * 0.62, -width * 0.23, -depth * 0.09, 7, false)
	local chamber = part(
		model,
		"GourdKilnChamber",
		Vector3.new(6.2, 4.2, 7),
		Vector3.new(width * 0.24, 3.1, -depth * 0.17),
		Color3.fromRGB(153, 103, 77),
		Enum.Material.Brick
	)
	chamber.Shape = Enum.PartType.Ball
	part(model, "KilnFirebox", Vector3.new(2, 1.8, 2.3), Vector3.new(width * 0.24, 1.9, depth * 0.01), colors.shadow)
	part(
		model,
		"ShortKilnFlue",
		Vector3.new(1.6, 2, 1.6),
		Vector3.new(width * 0.24, 4.8, -depth * 0.28),
		colors.brick,
		Enum.Material.Brick
	)
	part(
		model,
		"CeramicDryingBench",
		Vector3.new(width * 0.65, 2.1, 2.5),
		Vector3.new(0, 2.05, depth * 0.3),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -width * 0.22, 0, width * 0.22 } do
		jar(model, x, depth * 0.3, 0.65, 3.1)
	end
end

function builders.storehouse(model, width, depth)
	part(
		model,
		"RaisedBrickPlinth",
		Vector3.new(width * 0.82, 1.1, depth * 0.8),
		Vector3.new(0, 1.55, 0),
		colors.brick,
		Enum.Material.Brick
	)
	room(model, width * 0.78, depth * 0.72, 0, 0, 10, false)
	for _, side in { -1, 1 } do
		part(
			model,
			"VentilationSlit",
			Vector3.new(0.16, 1, depth * 0.18),
			Vector3.new(side * width * 0.37, 8, -depth * 0.1),
			colors.shadow
		)
	end
	part(
		model,
		"StoreDoorBar",
		Vector3.new(3.2, 0.45, 0.35),
		Vector3.new(0, 4, depth * 0.36 - 0.3),
		colors.wood,
		Enum.Material.Wood
	)
	for _, x in { -width * 0.22, width * 0.22 } do
		part(
			model,
			"GrainBin",
			Vector3.new(3.1, 2.8, 2.7),
			Vector3.new(x, 2.4, depth * 0.35),
			Color3.fromRGB(169, 147, 99),
			Enum.Material.Wood
		)
	end
end

function builders.training(model, width, depth)
	part(
		model,
		"DrillCourt",
		Vector3.new(width - 3, 0.15, depth - 3),
		Vector3.new(0, 1.1, 0),
		colors.earth,
		Enum.Material.Ground
	)
	room(model, width * 0.36, depth * 0.28, -width * 0.26, -depth * 0.3, 7, false)
	for index = 0, 2 do
		local target = part(
			model,
			"ArcheryTarget",
			Vector3.new(0.5, 3, 3),
			Vector3.new(index * width * 0.16, 4, -depth * 0.26),
			Color3.fromRGB(184, 169, 127),
			Enum.Material.Fabric
		)
		target.Shape = Enum.PartType.Cylinder
		target.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		part(
			model,
			"TargetStand",
			Vector3.new(0.6, 3, 0.6),
			Vector3.new(index * width * 0.16, 2.5, -depth * 0.26),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"SpearRest",
		Vector3.new(width * 0.64, 2.3, 0.8),
		Vector3.new(0, 2.15, depth * 0.29),
		colors.wood,
		Enum.Material.Wood
	)
	for index = -2, 2 do
		part(
			model,
			"PracticeSpear",
			Vector3.new(0.18, 6, 0.18),
			Vector3.new(index * 2, 4, depth * 0.29),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

function builders.healer(model, width, depth)
	room(model, width * 0.7, depth * 0.32, 0, -depth * 0.27, 7, false)
	part(
		model,
		"CareCourtyard",
		Vector3.new(width * 0.74, 0.2, depth * 0.38),
		Vector3.new(0, 1.15, depth * 0.18),
		colors.brick,
		Enum.Material.Pavement
	)
	part(
		model,
		"TreatmentBench",
		Vector3.new(width * 0.29, 0.7, depth * 0.32),
		Vector3.new(-width * 0.17, 1.8, depth * 0.16),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"PlainLinen",
		Vector3.new(2, 0.4, 2.5),
		Vector3.new(-width * 0.17, 2.35, depth * 0.16),
		colors.plaster,
		Enum.Material.Fabric
	)
	jar(model, width * 0.23, depth * 0.17, 0.75)
end

function MingKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function MingKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("ming")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Ming building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"PavedFooting",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.brick,
		Enum.Material.Pavement
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "ming")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Ming Sandbox Art.md")
	return model
end

function MingKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Ming presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(203, 163, 120)
	local cloth = if role == "melee" then colors.red elseif role == "ranged" then colors.blue else colors.plaster
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.8, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "PlainRobe", Vector3.new(1.95, 2.05, 1.1), Vector3.new(0, 3.1, 0), cloth, Enum.Material.Fabric)
	part(model, "RobeSkirt", Vector3.new(2, 1.3, 1.2), Vector3.new(0, 1.9, 0), cloth, Enum.Material.Fabric)
	part(model, "ClothBelt", Vector3.new(2.05, 0.23, 1.2), Vector3.new(0, 2.8, 0), colors.wood, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.3, 3.1, 0), skin)
		part(
			model,
			label .. " Sleeve",
			Vector3.new(0.85, 1.45, 0.9),
			Vector3.new(side * 1.3, 3.3, 0),
			cloth,
			Enum.Material.Fabric
		)
		part(model, label .. " Leg", Vector3.new(0.75, 1.8, 0.8), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Trouser",
			Vector3.new(0.8, 1.6, 0.86),
			Vector3.new(side * 0.5, 1.1, 0),
			colors.shadow,
			Enum.Material.Fabric
		)
		part(
			model,
			label .. " Shoe",
			Vector3.new(0.85, 0.3, 1.1),
			Vector3.new(side * 0.5, 0.2, -0.1),
			colors.shadow,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	if role == "melee" then
		local helmet = part(
			model,
			"PlainIronHelmet",
			Vector3.new(1.6, 0.85, 1.5),
			Vector3.new(0, 5.25, 0.05),
			colors.brick,
			Enum.Material.Metal
		)
		helmet.Shape = Enum.PartType.Ball
		for row = 0, 2 do
			for column = -1, 1 do
				part(
					model,
					"ArmorPlate",
					Vector3.new(0.6, 0.48, 0.16),
					Vector3.new(column * 0.62, 2.8 + row * 0.5, -0.65),
					colors.brick,
					Enum.Material.Metal
				)
			end
		end
		part(
			model,
			"SpearShaft",
			Vector3.new(0.15, 6.3, 0.15),
			Vector3.new(1.5, 3.8, -0.25),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"SpearPoint",
			Vector3.new(0.3, 0.8, 0.16),
			Vector3.new(1.5, 7.2, -0.25),
			colors.brick,
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
			for _, side in { -1, 1 } do
				local limb = part(
					model,
					"BowLimb",
					Vector3.new(0.13, 1.7, 0.17),
					Vector3.new(1.4, 3 + side * 0.75, -0.4),
					colors.wood,
					Enum.Material.Wood
				)
				limb.CFrame *= CFrame.Angles(0, 0, side * 0.3)
			end
			part(
				model,
				"BowString",
				Vector3.new(0.035, 3.1, 0.035),
				Vector3.new(1.65, 3, -0.4),
				colors.plaster,
				Enum.Material.Fabric
			)
			part(
				model,
				"PlainQuiver",
				Vector3.new(0.65, 2, 0.6),
				Vector3.new(-0.9, 3.2, 0.65),
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
				colors.plaster,
				Enum.Material.Fabric
			)
		end
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "ming")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Ming Sandbox Art.md")
	return model
end

return MingKit

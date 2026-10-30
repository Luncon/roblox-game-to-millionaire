--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local PersianKit = {}

local colors = {
	earth = Color3.fromRGB(174, 137, 94),
	plaster = Color3.fromRGB(210, 185, 143),
	roof = Color3.fromRGB(161, 137, 102),
	stone = Color3.fromRGB(143, 139, 126),
	wood = Color3.fromRGB(105, 76, 47),
	clay = Color3.fromRGB(153, 104, 68),
	shadow = Color3.fromRGB(54, 46, 40),
	grain = Color3.fromRGB(209, 172, 77),
	cloth = Color3.fromRGB(207, 190, 151),
	glaze = Color3.fromRGB(58, 116, 133),
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

local function flatRoom(model, width, depth, x, z, height, floor)
	local bottom = floor or 1
	part(
		model,
		"MudbrickRoom",
		Vector3.new(width, height, depth),
		Vector3.new(x, bottom + height / 2, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	local top = bottom + height
	for index = -1, 1 do
		part(
			model,
			"ExposedRoofBeam",
			Vector3.new(0.65, 0.7, depth + 0.8),
			Vector3.new(x + index * width * 0.28, top + 0.25, z),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"EarthRoof",
		Vector3.new(width + 0.6, 0.7, depth + 0.6),
		Vector3.new(x, top + 0.75, z),
		colors.roof,
		Enum.Material.Ground
	)
	part(
		model,
		"RecessedDoor",
		Vector3.new(2.5, height * 0.7, 0.16),
		Vector3.new(x, bottom + height * 0.35, z + depth / 2 + 0.09),
		colors.shadow
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"TimberDoorJamb",
			Vector3.new(0.4, height * 0.72, 0.4),
			Vector3.new(x + side * 1.45, bottom + height * 0.36, z + depth / 2 + 0.1),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"DoorLintel",
		Vector3.new(3.3, 0.55, 0.45),
		Vector3.new(x, bottom + height * 0.73, z + depth / 2 + 0.1),
		colors.wood,
		Enum.Material.Wood
	)
end

local function vessel(model, x, z, scale, floor)
	local bottom = floor or 1
	local body = part(
		model,
		"StorageJar",
		Vector3.new(2.1, 2.8, 2.1) * scale,
		Vector3.new(x, bottom + 1.4 * scale, z),
		colors.clay,
		Enum.Material.CeramicTiles
	)
	body.Shape = Enum.PartType.Ball
	local neck = part(
		model,
		"JarNeck",
		Vector3.new(0.8, 1.3, 1.3) * scale,
		Vector3.new(x, bottom + 2.65 * scale, z),
		colors.clay,
		Enum.Material.CeramicTiles
	)
	neck.Shape = Enum.PartType.Cylinder
	neck.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

local function shade(model, width, depth, x, z, height)
	for _, side in { -1, 1 } do
		part(
			model,
			"ShadePost",
			Vector3.new(0.65, height, 0.65),
			Vector3.new(x + side * (width / 2 - 0.5), 1 + height / 2, z + depth / 2 - 0.5),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"ReedShade",
		Vector3.new(width, 0.45, depth),
		Vector3.new(x, height + 1, z),
		colors.cloth,
		Enum.Material.Fabric
	)
	for index = -2, 2 do
		part(
			model,
			"ShadeLath",
			Vector3.new(0.2, 0.2, depth),
			Vector3.new(x + index * width / 5, height + 1.3, z),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

local builders = {}

function builders.house(model, width, depth)
	flatRoom(model, width - 3, depth * 0.28, 0, -depth * 0.3, 8)
	flatRoom(model, width * 0.25, depth * 0.45, -width * 0.29, depth * 0.1, 7.5)
	part(
		model,
		"PrivateCourt",
		Vector3.new(width * 0.55, 0.15, depth * 0.48),
		Vector3.new(width * 0.12, 1.1, depth * 0.16),
		colors.earth,
		Enum.Material.Ground
	)
	part(
		model,
		"CourtBoundary",
		Vector3.new(width * 0.62, 2, 0.8),
		Vector3.new(width * 0.1, 2, depth * 0.41),
		colors.earth,
		Enum.Material.Plaster
	)
	vessel(model, width * 0.3, depth * 0.23, 0.8)
end

function builders.civic(model, width, depth)
	part(
		model,
		"StoneTerrace",
		Vector3.new(width - 3, 3, depth * 0.78),
		Vector3.new(0, 2.5, -1),
		colors.stone,
		Enum.Material.Limestone
	)
	for step = 1, 3 do
		part(
			model,
			"TerraceStep",
			Vector3.new(width * 0.42, 4 - step, 1.25),
			Vector3.new(0, (4 - step) / 2 + 1, depth * 0.36 + (step - 1) * 1.25),
			colors.stone,
			Enum.Material.Limestone
		)
	end
	flatRoom(model, width * 0.74, depth * 0.28, 0, -depth * 0.26, 10, 4)
	for _, x in { -width * 0.29, -width * 0.095, width * 0.095, width * 0.29 } do
		local column = part(
			model,
			"SlenderHallColumn",
			Vector3.new(10, 1.05, 1.05),
			Vector3.new(x, 9, depth * 0.08),
			colors.stone,
			Enum.Material.Limestone
		)
		column.Shape = Enum.PartType.Cylinder
		column.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		part(
			model,
			"ColumnBase",
			Vector3.new(2, 0.6, 2),
			Vector3.new(x, 4.3, depth * 0.08),
			colors.stone,
			Enum.Material.Limestone
		)
		part(
			model,
			"BullCapitalBody",
			Vector3.new(2.8, 0.8, 1.2),
			Vector3.new(x, 14.4, depth * 0.08),
			colors.stone,
			Enum.Material.Limestone
		)
		for _, side in { -1, 1 } do
			local head = part(
				model,
				"PairedBullHead",
				Vector3.new(0.8, 0.85, 1),
				Vector3.new(x + side * 1.15, 14.9, depth * 0.08),
				colors.stone,
				Enum.Material.Limestone
			)
			head.Shape = Enum.PartType.Ball
			part(
				model,
				"BullHorn",
				Vector3.new(0.16, 0.65, 0.16),
				Vector3.new(x + side * 1.15, 15.45, depth * 0.08 - 0.3),
				colors.stone,
				Enum.Material.Limestone
			)
		end
	end
	part(
		model,
		"AudienceHallBeam",
		Vector3.new(width * 0.77, 0.65, 1.4),
		Vector3.new(0, 15.5, depth * 0.08),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"AudienceRoof",
		Vector3.new(width * 0.8, 0.8, depth * 0.3),
		Vector3.new(0, 16.2, depth * 0.05),
		colors.roof,
		Enum.Material.Ground
	)
	for index = -3, 3 do
		part(
			model,
			"RoyalGlazeAccent",
			Vector3.new(1.4, 1.15, 0.15),
			Vector3.new(index * 3, 2.8, depth * 0.39 - 0.9),
			if index % 2 == 0 then colors.glaze else colors.grain,
			Enum.Material.CeramicTiles
		)
	end
	part(
		model,
		"TradeTable",
		Vector3.new(7, 2.1, 2.4),
		Vector3.new(-width * 0.3, 5.05, depth * 0.24),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	vessel(model, width * 0.3, depth * 0.27, 0.9, 4)
end

function builders.farm(model, width, depth)
	part(
		model,
		"IrrigatedEarth",
		Vector3.new(width - 3, 0.5, depth - 3),
		Vector3.new(0, 1.25, 0),
		colors.earth,
		Enum.Material.Ground
	)
	part(
		model,
		"FieldChannel",
		Vector3.new(0.8, 0.2, depth - 4),
		Vector3.new(0, 1.5, 0),
		Color3.fromRGB(91, 111, 104),
		Enum.Material.Slate
	)
	for _, side in { -1, 1 } do
		for row = -2, 2 do
			part(
				model,
				"RaisedFurrow",
				Vector3.new(width * 0.4, 0.4, 0.8),
				Vector3.new(side * width * 0.24, 1.7, row * depth * 0.15),
				colors.clay,
				Enum.Material.Ground
			)
			for column = 1, 3 do
				part(
					model,
					"CerealClump",
					Vector3.new(0.7, 2.5, 0.7),
					Vector3.new(side * (2 + column * width * 0.1), 2.9, row * depth * 0.15),
					colors.grain,
					Enum.Material.Grass
				)
			end
		end
	end
end

function builders.timber(model, width, depth)
	shade(model, width * 0.43, depth * 0.7, -width * 0.23, -depth * 0.05, 7)
	for row = 0, 2 do
		for column = -1, 1 do
			local log = part(
				model,
				"BeamStock",
				Vector3.new(width * 0.4, 1.5, 1.5),
				Vector3.new(width * 0.23, 1.8 + row * 1.4, column * 1.6 - depth * 0.1),
				colors.wood,
				Enum.Material.Wood
			)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	part(
		model,
		"AdzeBench",
		Vector3.new(width * 0.35, 2.2, depth * 0.25),
		Vector3.new(-width * 0.23, 2.1, 0),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"SquaredTimber",
		Vector3.new(width * 0.36, 0.7, 0.7),
		Vector3.new(-width * 0.23, 3.6, 0),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayExtractionBed",
		Vector3.new(width * 0.55, 0.6, depth * 0.75),
		Vector3.new(-width * 0.17, 1.3, 0),
		colors.clay,
		Enum.Material.Mud
	)
	part(
		model,
		"MixingTrough",
		Vector3.new(width * 0.3, 1.1, depth * 0.22),
		Vector3.new(width * 0.28, 1.55, -depth * 0.25),
		colors.earth,
		Enum.Material.Ground
	)
	for row = 0, 2 do
		for column = 0, 2 do
			part(
				model,
				"DryingMudbrick",
				Vector3.new(2, 0.7, 1.2),
				Vector3.new(width * 0.16 + column * 2.3, 1.35, depth * 0.03 + row * 2),
				colors.earth,
				Enum.Material.Ground
			)
		end
	end
end

function builders.workshop(model, width, depth)
	flatRoom(model, width * 0.4, depth * 0.6, -width * 0.25, -depth * 0.12, 7)
	part(
		model,
		"RectangularFiringChamber",
		Vector3.new(5, 4.5, 5),
		Vector3.new(width * 0.24, 3.25, -depth * 0.2),
		colors.clay,
		Enum.Material.Brick
	)
	part(
		model,
		"KilnFirebox",
		Vector3.new(2.2, 1.7, 0.16),
		Vector3.new(width * 0.24, 2.2, -depth * 0.2 + 2.6),
		colors.shadow
	)
	part(
		model,
		"PotteryDryingShelf",
		Vector3.new(width * 0.65, 2.1, 2.3),
		Vector3.new(0, 2.05, depth * 0.28),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -width * 0.23, 0, width * 0.23 } do
		vessel(model, x, depth * 0.28, 0.65, 3.1)
	end
end

function builders.storehouse(model, width, depth)
	flatRoom(model, width * 0.78, depth * 0.7, 0, -depth * 0.05, 11)
	for _, side in { -1, 1 } do
		for _, z in { -depth * 0.23, depth * 0.15 } do
			part(
				model,
				"StoreButtress",
				Vector3.new(1.4, 9.5, 2),
				Vector3.new(side * width * 0.405, 5.75, z),
				colors.earth,
				Enum.Material.Plaster
			)
		end
	end
	part(
		model,
		"StoreDoorBar",
		Vector3.new(3.5, 0.5, 0.4),
		Vector3.new(0, 4.2, depth * 0.3 + 0.2),
		colors.wood,
		Enum.Material.Wood
	)
	for _, x in { -width * 0.27, width * 0.27 } do
		vessel(model, x, depth * 0.35, 0.8)
	end
end

function builders.training(model, width, depth)
	part(
		model,
		"PracticeCourt",
		Vector3.new(width - 3, 0.2, depth - 3),
		Vector3.new(0, 1.1, 0),
		colors.earth,
		Enum.Material.Ground
	)
	flatRoom(model, width * 0.3, depth * 0.32, -width * 0.29, -depth * 0.28, 6)
	for index = 0, 2 do
		local target = part(
			model,
			"ReedArcheryTarget",
			Vector3.new(0.5, 3, 3),
			Vector3.new(index * width * 0.18, 4, -depth * 0.28),
			colors.cloth,
			Enum.Material.Fabric
		)
		target.Shape = Enum.PartType.Cylinder
		target.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		part(
			model,
			"TargetStand",
			Vector3.new(0.5, 3, 0.5),
			Vector3.new(index * width * 0.18, 2.5, -depth * 0.28),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"SpearRack",
		Vector3.new(width * 0.6, 2.3, 1),
		Vector3.new(0, 2.15, depth * 0.3),
		colors.wood,
		Enum.Material.Wood
	)
	for index = -2, 2 do
		part(
			model,
			"PracticeSpear",
			Vector3.new(0.2, 6, 0.2),
			Vector3.new(index * 2, 4, depth * 0.3),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

function builders.healer(model, width, depth)
	flatRoom(model, width * 0.75, depth * 0.25, 0, -depth * 0.3, 6)
	shade(model, width * 0.75, depth * 0.48, 0, depth * 0.12, 6)
	part(
		model,
		"TreatmentMat",
		Vector3.new(width * 0.32, 0.3, depth * 0.4),
		Vector3.new(-width * 0.12, 1.4, depth * 0.12),
		colors.cloth,
		Enum.Material.Fabric
	)
	part(
		model,
		"FoldedLinen",
		Vector3.new(2, 0.6, 2),
		Vector3.new(-width * 0.12, 1.8, depth * 0.08),
		Color3.fromRGB(231, 218, 186),
		Enum.Material.Fabric
	)
	vessel(model, width * 0.23, depth * 0.17, 0.7)
end

function PersianKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function PersianKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("persia")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Persian building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"EarthPlatform",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.earth,
		Enum.Material.Ground
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "persia")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Persian Sandbox Art.md")
	return model
end

-- Original resting figures, deliberately outside combat/healing registration.
function PersianKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Persian presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(190, 145, 105)
	local cloth = if role == "melee"
		then Color3.fromRGB(140, 77, 70)
		elseif role == "ranged" then colors.glaze
		else colors.cloth
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.8, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "SleevedRobe", Vector3.new(1.95, 2.05, 1.1), Vector3.new(0, 3.1, 0), cloth, Enum.Material.Fabric)
	part(model, "LongRobeHem", Vector3.new(2.1, 1.55, 1.2), Vector3.new(0, 1.7, 0), cloth, Enum.Material.Fabric)
	part(model, "RobeSash", Vector3.new(2.1, 0.25, 1.2), Vector3.new(0, 2.8, 0), colors.grain, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.3, 3.1, 0), skin)
		part(
			model,
			label .. " Sleeve",
			Vector3.new(0.85, 1.55, 0.9),
			Vector3.new(side * 1.3, 3.3, 0),
			cloth,
			Enum.Material.Fabric
		)
		part(model, label .. " Leg", Vector3.new(0.75, 1.8, 0.8), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Shoe",
			Vector3.new(0.8, 0.45, 1.1),
			Vector3.new(side * 0.5, 0.3, -0.1),
			colors.wood,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	part(model, "SoftCap", Vector3.new(1.55, 0.7, 1.5), Vector3.new(0, 5.3, 0.1), cloth, Enum.Material.Fabric)
	part(model, "Beard", Vector3.new(1, 0.55, 0.25), Vector3.new(0, 4.35, -0.66), colors.shadow)
	if role == "melee" then
		part(
			model,
			"WickerShield",
			Vector3.new(1.8, 3, 0.22),
			Vector3.new(-1.5, 2.8, -0.65),
			colors.cloth,
			Enum.Material.Wood
		)
		for row = -3, 3 do
			part(
				model,
				"ShieldWeave",
				Vector3.new(1.85, 0.07, 0.08),
				Vector3.new(-1.5, 2.8 + row * 0.35, -0.82),
				colors.wood,
				Enum.Material.Wood
			)
		end
		part(
			model,
			"SpearShaft",
			Vector3.new(0.15, 6.8, 0.15),
			Vector3.new(1.55, 4, -0.3),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"SpearPoint",
			Vector3.new(0.28, 0.7, 0.2),
			Vector3.new(1.55, 7.65, -0.3),
			colors.stone,
			Enum.Material.Metal
		)
	elseif role == "ranged" then
		for _, side in { -1, 1 } do
			local limb = part(
				model,
				"BowLimb",
				Vector3.new(0.13, 1.7, 0.16),
				Vector3.new(1.45, 3 + side * 0.75, -0.48),
				colors.wood,
				Enum.Material.Wood
			)
			limb.CFrame *= CFrame.Angles(0, 0, side * 0.3)
		end
		part(
			model,
			"BowString",
			Vector3.new(0.035, 3.1, 0.035),
			Vector3.new(1.68, 3, -0.48),
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"Quiver",
			Vector3.new(0.65, 2.1, 0.6),
			Vector3.new(-1, 3.2, 0.65),
			colors.wood,
			Enum.Material.Leather
		)
		for index = 0, 2 do
			part(
				model,
				"ArrowShaft",
				Vector3.new(0.06, 1.3, 0.06),
				Vector3.new(-1.18 + index * 0.18, 4.3, 0.65),
				colors.wood,
				Enum.Material.Wood
			)
		end
	else
		part(
			model,
			"LinenSatchel",
			Vector3.new(0.85, 1.1, 0.5),
			Vector3.new(-1.1, 2.3, -0.35),
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"FoldedBandage",
			Vector3.new(0.8, 0.3, 0.7),
			Vector3.new(1.3, 2.1, -0.25),
			Color3.fromRGB(231, 218, 186),
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "persia")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Persian Sandbox Art.md")
	return model
end

return PersianKit

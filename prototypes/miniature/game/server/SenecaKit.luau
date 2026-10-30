--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local SenecaKit = {}
local colors = {
	bark = Color3.fromRGB(128, 108, 83),
	barkLight = Color3.fromRGB(147, 125, 96),
	wood = Color3.fromRGB(128, 92, 55),
	lash = Color3.fromRGB(192, 169, 119),
	earth = Color3.fromRGB(103, 82, 55),
	clay = Color3.fromRGB(139, 100, 75),
	leaf = Color3.fromRGB(91, 120, 58),
	corn = Color3.fromRGB(218, 205, 145),
	shadow = Color3.fromRGB(49, 43, 34),
	hide = Color3.fromRGB(185, 154, 112),
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

local function bowl(model, x, z, scale, floor)
	local bottom = floor or 1
	local vessel = part(
		model,
		"PlainVessel",
		Vector3.new(2.7, 1.6, 2.7) * scale,
		Vector3.new(x, bottom + 0.8 * scale, z),
		colors.clay,
		Enum.Material.CeramicTiles
	)
	vessel.Shape = Enum.PartType.Ball
	local mouth = part(
		model,
		"VesselMouth",
		Vector3.new(0.15, 1.9, 1.9) * scale,
		Vector3.new(x, bottom + 1.45 * scale, z),
		colors.shadow
	)
	mouth.Shape = Enum.PartType.Cylinder
	mouth.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

local function barkHall(model, width, length, x, z, rotation)
	local hall = Instance.new("Model")
	hall.Name, hall.WorldPivot, hall.Parent = "BarkHall", CFrame.identity, model
	local height, rise = 5.5, width * 0.48
	for _, side in { -1, 1 } do
		for index = 0, 5 do
			local at = -length / 2 + (index + 0.5) * length / 6
			part(
				hall,
				"ElmBarkWall",
				Vector3.new(0.55, height, length / 6 - 0.06),
				Vector3.new(side * width / 2, 1 + height / 2, at),
				if index % 2 == 0 then colors.bark else colors.barkLight,
				Enum.Material.Wood
			)
			part(
				hall,
				"FramePost",
				Vector3.new(0.45, height + 0.4, 0.45),
				Vector3.new(side * (width / 2 + 0.34), 1 + height / 2, at),
				colors.wood,
				Enum.Material.Wood
			)
			part(
				hall,
				"BarkFiberLashing",
				Vector3.new(0.62, 0.16, 0.62),
				Vector3.new(side * (width / 2 + 0.34), height - 0.5, at),
				colors.lash,
				Enum.Material.Fabric
			)
		end
		part(
			hall,
			"InteriorPlatform",
			Vector3.new(width * 0.22, 0.6, length * 0.85),
			Vector3.new(side * width * 0.32, 2.1, 0),
			colors.wood,
			Enum.Material.Wood
		)
	end
	-- Twelve short chords describe a barrel-shaped bark shell, not a Norse gable.
	for index = 1, 12 do
		local first, second = (index - 1) * math.pi / 12, index * math.pi / 12
		local a = Vector3.new(math.cos(first) * width / 2, 1 + height + math.sin(first) * rise, 0)
		local b = Vector3.new(math.cos(second) * width / 2, 1 + height + math.sin(second) * rise, 0)
		local midpoint = (a + b) / 2
		local chord = (b - a).Magnitude
		local angle = math.atan2(b.Y - a.Y, b.X - a.X)
		local sections = if index == 6 or index == 7 then { -1, 1 } else { 0 }
		for _, section in sections do
			local panelDepth = if section == 0 then length else length * 0.42
			local at = if section == 0 then 0 else section * length * 0.29
			local panel = part(
				hall,
				"BarkArchPanel",
				Vector3.new(chord + 0.08, 0.42, panelDepth),
				midpoint + Vector3.new(0, 0, at),
				if index % 2 == 0 then colors.bark else colors.barkLight,
				Enum.Material.Wood
			)
			panel.CFrame *= CFrame.Angles(0, 0, angle)
		end
	end
	for _, endSide in { -1, 1 } do
		for _, side in { -1, 1 } do
			part(
				hall,
				"BarkEndPanel",
				Vector3.new(width * 0.32, height, 0.6),
				Vector3.new(side * width * 0.34, 1 + height / 2, endSide * length / 2),
				colors.bark,
				Enum.Material.Wood
			)
		end
		part(
			hall,
			"DoorLintel",
			Vector3.new(width * 0.34, 0.55, 0.7),
			Vector3.new(0, height + 0.7, endSide * length / 2),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		hall,
		"SmokeOpeningRim",
		Vector3.new(width * 0.19, 0.2, 0.35),
		Vector3.new(0, 1 + height + rise, length * 0.08),
		colors.wood,
		Enum.Material.Wood
	)
	hall:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rotation or 0), 0))
end

local function workShade(model, width, depth, x, z)
	for _, side in { -1, 1 } do
		part(
			model,
			"ShelterPost",
			Vector3.new(0.55, 6, 0.55),
			Vector3.new(x + side * (width / 2 - 0.4), 4, z),
			colors.wood,
			Enum.Material.Wood
		)
	end
	local roof = part(
		model,
		"BarkWorkShade",
		Vector3.new(width, 0.5, depth),
		Vector3.new(x, 7, z),
		colors.bark,
		Enum.Material.Wood
	)
	roof.CFrame *= CFrame.Angles(math.rad(7), 0, 0)
end

local builders = {}
function builders.house(model, width, depth)
	barkHall(model, width * 0.54, depth * 0.82, 0, 0, 0)
	part(
		model,
		"WoodenEntryTray",
		Vector3.new(3, 0.5, 2),
		Vector3.new(width * 0.35, 1.3, depth * 0.24),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.civic(model, width, depth)
	barkHall(model, depth * 0.48, width * 0.82, 0, -depth * 0.12, 90)
	part(
		model,
		"MeetingClearing",
		Vector3.new(width * 0.75, 0.12, depth * 0.24),
		Vector3.new(0, 1.1, depth * 0.31),
		colors.earth,
		Enum.Material.Ground
	)
	for _, side in { -1, 1 } do
		local seat = part(
			model,
			"MeetingLog",
			Vector3.new(7, 1.1, 1.1),
			Vector3.new(side * width * 0.24, 1.7, depth * 0.29),
			colors.wood,
			Enum.Material.Wood
		)
		seat.Shape = Enum.PartType.Cylinder
	end
	part(
		model,
		"TradeMat",
		Vector3.new(6, 0.2, 3),
		Vector3.new(0, 1.2, depth * 0.29),
		colors.lash,
		Enum.Material.Fabric
	)
	bowl(model, 0, depth * 0.29, 0.65, 1.3)
end

function builders.farm(model, width, depth)
	for row = -1, 1 do
		for column = -2, 2 do
			local x, z = column * width * 0.16, row * depth * 0.26
			local mound = part(
				model,
				"PlantingMound",
				Vector3.new(4, 0.8, 4),
				Vector3.new(x, 1.4, z),
				colors.earth,
				Enum.Material.Ground
			)
			mound.Shape = Enum.PartType.Ball
			part(
				model,
				"CornStalk",
				Vector3.new(0.25, 4, 0.25),
				Vector3.new(x, 3.5, z),
				colors.leaf,
				Enum.Material.Grass
			)
			for _, side in { -1, 1 } do
				local leaf = part(
					model,
					"CornLeaf",
					Vector3.new(2, 0.18, 0.5),
					Vector3.new(x + side * 0.7, 3.5, z),
					colors.leaf,
					Enum.Material.Grass
				)
				leaf.CFrame *= CFrame.Angles(0, 0, side * 0.35)
			end
			part(
				model,
				"CornEar",
				Vector3.new(0.6, 1.25, 0.6),
				Vector3.new(x + 0.4, 4.2, z),
				colors.corn,
				Enum.Material.Grass
			)
			part(
				model,
				"BeanVine",
				Vector3.new(0.15, 2.7, 0.15),
				Vector3.new(x - 0.4, 2.8, z + 0.3),
				Color3.fromRGB(72, 106, 53),
				Enum.Material.Grass
			)
			local squash = part(
				model,
				"Squash",
				Vector3.new(1.5, 0.85, 1.4),
				Vector3.new(x + 1.2, 1.9, z + 0.7),
				Color3.fromRGB(173, 151, 65),
				Enum.Material.Grass
			)
			squash.Shape = Enum.PartType.Ball
		end
	end
end

function builders.timber(model, width, depth)
	for column = -1, 1 do
		local stock = part(
			model,
			"SaplingStock",
			Vector3.new(width * 0.7, 0.8, 0.8),
			Vector3.new(0, 1.7, column * 1.4 - depth * 0.22),
			colors.wood,
			Enum.Material.Wood
		)
		stock.Shape = Enum.PartType.Cylinder
	end
	part(
		model,
		"PoleWorkingSupport",
		Vector3.new(width * 0.58, 1.5, 2.2),
		Vector3.new(0, 1.75, depth * 0.15),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"UnfinishedWoodenTray",
		Vector3.new(7, 0.8, 2.6),
		Vector3.new(0, 2.9, depth * 0.15),
		colors.barkLight,
		Enum.Material.Wood
	)
	part(
		model,
		"StoneAdzeHandle",
		Vector3.new(3, 0.25, 0.25),
		Vector3.new(width * 0.2, 2.9, depth * 0.15),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"StoneAdzeHead",
		Vector3.new(0.8, 0.6, 1.3),
		Vector3.new(width * 0.2 + 1.3, 3.1, depth * 0.15),
		Color3.fromRGB(103, 106, 100),
		Enum.Material.Slate
	)
	workShade(model, width * 0.75, depth * 0.58, 0, 0)
end

function builders.material(model, width, depth)
	part(
		model,
		"ClayGatheringBed",
		Vector3.new(width * 0.55, 0.3, depth * 0.7),
		Vector3.new(-width * 0.15, 1.15, 0),
		colors.clay,
		Enum.Material.Mud
	)
	part(
		model,
		"ClayWorkingMat",
		Vector3.new(width * 0.27, 0.2, depth * 0.55),
		Vector3.new(width * 0.28, 1.2, 0),
		colors.lash,
		Enum.Material.Fabric
	)
	for index = -1, 1 do
		local clay = part(
			model,
			"ClayPortion",
			Vector3.new(1.5, 1.1, 1.4),
			Vector3.new(width * 0.28, 1.85, index * 3),
			colors.clay,
			Enum.Material.Mud
		)
		clay.Shape = Enum.PartType.Ball
	end
end

function builders.workshop(model, width, depth)
	workShade(model, width * 0.46, depth * 0.7, -width * 0.23, -depth * 0.02)
	part(
		model,
		"PotShapingMat",
		Vector3.new(width * 0.4, 0.2, depth * 0.5),
		Vector3.new(-width * 0.23, 1.2, 0),
		colors.lash,
		Enum.Material.Fabric
	)
	part(
		model,
		"OpenFiringBed",
		Vector3.new(width * 0.28, 0.2, depth * 0.3),
		Vector3.new(width * 0.23, 1.2, -depth * 0.18),
		colors.shadow,
		Enum.Material.Ground
	)
	for index = -1, 1 do
		part(
			model,
			"FiringWood",
			Vector3.new(0.65, 0.5, 5),
			Vector3.new(width * 0.23 + index * 1.2, 1.5, -depth * 0.18),
			colors.wood,
			Enum.Material.Wood
		)
		bowl(model, -width * 0.23 + index * 3, depth * 0.12, 0.7, 1.3)
	end
	part(
		model,
		"DryingStone",
		Vector3.new(7, 0.5, 3),
		Vector3.new(width * 0.21, 1.3, depth * 0.28),
		Color3.fromRGB(117, 117, 108),
		Enum.Material.Slate
	)
	bowl(model, width * 0.21, depth * 0.28, 0.8, 1.55)
end

function builders.storehouse(model, width, depth)
	-- A compact elevated bark store abstracts the museum's c.1600 storage scene.
	for _, x in { -width * 0.29, width * 0.29 } do
		for _, z in { -depth * 0.25, depth * 0.25 } do
			part(
				model,
				"GranarySupport",
				Vector3.new(0.8, 4, 0.8),
				Vector3.new(x, 3, z),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"RaisedStoragePlatform",
		Vector3.new(width * 0.75, 0.7, depth * 0.7),
		Vector3.new(0, 5, 0),
		colors.wood,
		Enum.Material.Wood
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"BarkStorageWall",
			Vector3.new(0.5, 5, depth * 0.62),
			Vector3.new(side * width * 0.33, 7.8, 0),
			colors.bark,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"BarkStorageBack",
		Vector3.new(width * 0.65, 5, 0.5),
		Vector3.new(0, 7.8, -depth * 0.3),
		colors.bark,
		Enum.Material.Wood
	)
	part(
		model,
		"BarkStorageRoof",
		Vector3.new(width * 0.76, 0.6, depth * 0.73),
		Vector3.new(0, 10.6, 0),
		colors.barkLight,
		Enum.Material.Wood
	)
	for column = -2, 2 do
		part(
			model,
			"HangingCorn",
			Vector3.new(0.65, 2, 0.65),
			Vector3.new(column * 2, 7.5, depth * 0.22),
			colors.corn,
			Enum.Material.Grass
		)
	end
	for _, side in { -1, 1 } do
		part(
			model,
			"StorageLadderRail",
			Vector3.new(0.4, 4, 0.4),
			Vector3.new(side * 1.4, 3, depth * 0.36),
			colors.wood,
			Enum.Material.Wood
		)
	end
	for step = 1, 4 do
		part(
			model,
			"StorageLadderRung",
			Vector3.new(3, 0.3, 0.3),
			Vector3.new(0, 1 + step * 0.8, depth * 0.36),
			colors.wood,
			Enum.Material.Wood
		)
	end
end

function builders.training(model, width, depth)
	part(
		model,
		"PracticeClearing",
		Vector3.new(width - 3, 0.1, depth - 3),
		Vector3.new(0, 1.1, 0),
		colors.earth,
		Enum.Material.Ground
	)
	workShade(model, width * 0.3, depth * 0.4, -width * 0.29, -depth * 0.24)
	for index = 0, 2 do
		part(
			model,
			"PracticeMarker",
			Vector3.new(2.5, 4, 0.6),
			Vector3.new(index * width * 0.16, 3, -depth * 0.22),
			colors.barkLight,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"BowRest",
		Vector3.new(width * 0.5, 2, 0.8),
		Vector3.new(0, 2, depth * 0.28),
		colors.wood,
		Enum.Material.Wood
	)
end

function builders.healer(model, width, depth)
	barkHall(model, width * 0.42, depth * 0.63, -width * 0.22, -depth * 0.05, 0)
	part(
		model,
		"RestingMat",
		Vector3.new(width * 0.3, 0.25, depth * 0.45),
		Vector3.new(width * 0.23, 1.3, 0),
		colors.lash,
		Enum.Material.Fabric
	)
	part(
		model,
		"PlainSupplyBundle",
		Vector3.new(2.2, 1, 2.2),
		Vector3.new(width * 0.23, 1.9, depth * 0.25),
		colors.hide,
		Enum.Material.Leather
	)
	bowl(model, width * 0.23, -depth * 0.18, 0.75)
end

function SenecaKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function SenecaKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("seneca")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Seneca building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"ClearedEarth",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		colors.earth,
		Enum.Material.Ground
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "seneca")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Seneca Sandbox Art.md")
	return model
end

function SenecaKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Seneca presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(176, 123, 88)
	local cloth = if role == "medic" then Color3.fromRGB(183, 172, 144) else colors.hide
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.8, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "PlainUpperGarment", Vector3.new(1.95, 2.05, 1.1), Vector3.new(0, 3.1, 0), cloth, Enum.Material.Leather)
	part(model, "PlainWaistWrap", Vector3.new(1.2, 1.35, 1.15), Vector3.new(0, 1.95, 0), cloth, Enum.Material.Leather)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.3, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.75, 1.8, 0.8), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Legging",
			Vector3.new(0.8, 1.6, 0.86),
			Vector3.new(side * 0.5, 1.1, 0),
			cloth,
			Enum.Material.Leather
		)
		part(
			model,
			label .. " Moccasin",
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
	part(model, "PlainHair", Vector3.new(1.45, 0.45, 1.35), Vector3.new(0, 5.25, 0.08), colors.shadow)
	part(model, "TiedHair", Vector3.new(0.4, 1.2, 0.4), Vector3.new(0, 4.5, 0.75), colors.shadow)
	if role == "melee" then
		part(
			model,
			"WoodenClubHandle",
			Vector3.new(0.2, 2.5, 0.2),
			Vector3.new(1.45, 2.8, -0.25),
			colors.wood,
			Enum.Material.Wood
		)
		local club = part(
			model,
			"PlainClubHead",
			Vector3.new(0.8, 0.85, 0.75),
			Vector3.new(1.45, 4.1, -0.25),
			colors.wood,
			Enum.Material.Wood
		)
		club.Shape = Enum.PartType.Ball
	elseif role == "ranged" then
		for _, side in { -1, 1 } do
			local limb = part(
				model,
				"BowLimb",
				Vector3.new(0.12, 1.65, 0.16),
				Vector3.new(1.4, 3 + side * 0.73, -0.4),
				colors.wood,
				Enum.Material.Wood
			)
			limb.CFrame *= CFrame.Angles(0, 0, side * 0.25)
		end
		part(
			model,
			"BowString",
			Vector3.new(0.035, 3.1, 0.035),
			Vector3.new(1.6, 3, -0.4),
			colors.lash,
			Enum.Material.Fabric
		)
		part(
			model,
			"ArrowCase",
			Vector3.new(0.6, 1.8, 0.6),
			Vector3.new(-0.85, 3.1, 0.65),
			colors.hide,
			Enum.Material.Leather
		)
	else
		part(
			model,
			"PlainSupplyBag",
			Vector3.new(0.8, 1, 0.5),
			Vector3.new(-1.1, 2.5, -0.25),
			colors.hide,
			Enum.Material.Leather
		)
		part(
			model,
			"FoldedCloth",
			Vector3.new(0.8, 0.25, 0.7),
			Vector3.new(1.3, 2.2, -0.25),
			colors.lash,
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "seneca")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Seneca Sandbox Art.md")
	return model
end

return SenecaKit

--!strict
-- Original 1206–1260-inspired mobile/settled imperial vocabulary; evidence limits in note.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local MongolKit = {}
local colors = {
	felt = Color3.fromRGB(218, 209, 181),
	roof = Color3.fromRGB(199, 189, 159),
	wood = Color3.fromRGB(115, 80, 47),
	rope = Color3.fromRGB(87, 65, 43),
	earth = Color3.fromRGB(153, 130, 89),
	soil = Color3.fromRGB(99, 77, 45),
	clay = Color3.fromRGB(160, 103, 64),
	grain = Color3.fromRGB(194, 169, 76),
	shadow = Color3.fromRGB(44, 44, 36),
	iron = Color3.fromRGB(113, 116, 105),
}
local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	return object
end
local function disc(model, name, radius, height, position, color, material)
	local object = part(model, name, Vector3.new(height, radius * 2, radius * 2), position, color, material)
	object.Shape = Enum.PartType.Cylinder
	object.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	return object
end
local function ropeRing(model, x, z, radius, y, name, skipDoor)
	for index = 0, 11 do
		if skipDoor and index == 0 then
			continue
		end
		local angle = index * math.pi / 6
		local segment = part(
			model,
			name,
			Vector3.new(2 * radius * math.tan(math.pi / 12), 0.16, 0.16),
			Vector3.new(x + radius * math.sin(angle), y, z + radius * math.cos(angle)),
			colors.rope,
			Enum.Material.Fabric
		)
		segment.CFrame *= CFrame.Angles(0, angle, 0)
	end
end
local function ger(model, x, z, radius, wallHeight, rise)
	disc(model, "GerGroundMat", radius, 0.3, Vector3.new(x, 1.15, z), colors.roof, Enum.Material.Fabric)
	local crownRadius = radius * 0.16
	local pitch = math.atan(rise / (radius - crownRadius))
	for index = 0, 11 do
		local angle = index * math.pi / 6
		if index ~= 0 then
			local wall = part(
				model,
				"FeltWallPanel",
				Vector3.new(2 * radius * math.tan(math.pi / 12), wallHeight, 0.4),
				Vector3.new(x + radius * math.sin(angle), 1.3 + wallHeight / 2, z + radius * math.cos(angle)),
				colors.felt,
				Enum.Material.Fabric
			)
			wall.CFrame *= CFrame.Angles(0, angle, 0)
		end
		for tier = 1, 3 do
			local radialDepth = (radius - crownRadius) / 3
			local outer = crownRadius + tier * radialDepth
			local r = outer - radialDepth / 2
			local y = 1.3 + wallHeight + rise * (radius - r) / (radius - crownRadius)
			local roof = part(
				model,
				"FeltRoofPanel",
				Vector3.new(2 * outer * math.tan(math.pi / 12) + 0.12, 0.2, radialDepth / math.cos(pitch) + 0.1),
				Vector3.new(x + r * math.sin(angle), y, z + r * math.cos(angle)),
				colors.roof,
				Enum.Material.Fabric
			)
			roof.CFrame *= CFrame.Angles(0, angle, 0) * CFrame.Angles(pitch, 0, 0)
		end
	end
	ropeRing(model, x, z, radius + 0.28, 1.3 + wallHeight * 0.3, "WallRopeBand", true)
	ropeRing(model, x, z, radius + 0.28, 1.3 + wallHeight * 0.78, "WallRopeBand", true)
	ropeRing(model, x, z, crownRadius, 1.3 + wallHeight + rise, "TimberRoofCrown", false)
	disc(model, "RoofOpeningCue", crownRadius * 0.85, 0.12, Vector3.new(x, 1.28 + wallHeight + rise, z), colors.shadow)
	part(
		model,
		"PlainFeltDoor",
		Vector3.new(3.4, wallHeight * 0.9, 0.3),
		Vector3.new(x, 1.3 + wallHeight * 0.45, z + radius + 0.1),
		colors.wood,
		Enum.Material.Wood
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"DoorFramePost",
			Vector3.new(0.45, wallHeight, 0.55),
			Vector3.new(x + side * 1.9, 1.3 + wallHeight / 2, z + radius),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"DoorFrameLintel",
		Vector3.new(4.2, 0.5, 0.65),
		Vector3.new(x, wallHeight + 1.4, z + radius),
		colors.wood,
		Enum.Material.Wood
	)
end
local function awning(model, x, z, width, depth, height)
	for _, side in { -1, 1 } do
		for _, endSign in { -1, 1 } do
			part(
				model,
				"AwningTimberPost",
				Vector3.new(0.5, height, 0.5),
				Vector3.new(x + side * (width / 2 - 0.5), 1 + height / 2, z + endSign * (depth / 2 - 0.5)),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"UnpaintedFeltAwning",
		Vector3.new(width, 0.3, depth),
		Vector3.new(x, height + 1, z),
		colors.roof,
		Enum.Material.Fabric
	)
end
local function coffer(model, x, z, width)
	part(
		model,
		"SupplyCoffer",
		Vector3.new(width, 2.6, 2.7),
		Vector3.new(x, 2.3, z),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"CofferFeltCover",
		Vector3.new(width + 0.15, 0.4, 2.9),
		Vector3.new(x, 3.8, z),
		colors.shadow,
		Enum.Material.Fabric
	)
end
local function pot(model, x, z, scale)
	local vessel = part(
		model,
		"PlainCraftVessel",
		Vector3.new(2.5, 3, 2.5) * scale,
		Vector3.new(x, 1 + 1.5 * scale, z),
		colors.clay
	)
	vessel.Shape = Enum.PartType.Ball
	disc(model, "VesselMouth", 0.6 * scale, 0.13 * scale, Vector3.new(x, 1 + 2.9 * scale, z), colors.shadow)
end
local builders = {}
function builders.house(model, width, depth)
	ger(model, 0, -1.2, math.min(width, depth) * 0.36, 5, 3.2)
	coffer(model, -width * 0.28, depth * 0.35, 3.5)
end
function builders.civic(model, width, depth)
	ger(model, 0, -3, math.min(width, depth) * 0.34, 6.7, 4.3)
	awning(model, 0, depth * 0.34, 14, 5, 6)
	part(
		model,
		"CouncilTradeBoard",
		Vector3.new(10, 2.5, 2.6),
		Vector3.new(0, 2.25, depth * 0.34),
		colors.wood,
		Enum.Material.Wood
	)
	coffer(model, width * 0.31, depth * 0.29, 4)
end
function builders.farm(model, width, depth)
	part(
		model,
		"ImperialSettlementCropBed",
		Vector3.new(width - 5, 0.4, depth - 5),
		Vector3.new(1, 1.2, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for row = -2, 2 do
		for column = -3, 3 do
			local x, z = 1 + column * (width - 8) / 8, row * (depth - 8) / 6
			part(model, "CerealStalk", Vector3.new(0.25, 2.2, 0.25), Vector3.new(x, 2.5, z), colors.grain)
			local ear =
				part(model, "MilletGrainHead", Vector3.new(0.75, 0.8, 0.65), Vector3.new(x, 3.6, z), colors.grain)
			ear.Shape = Enum.PartType.Ball
		end
	end
	part(
		model,
		"CultivationWaterChannel",
		Vector3.new(1.3, 0.15, depth - 4),
		Vector3.new(-width * 0.43, 1.15, 0),
		Color3.fromRGB(79, 112, 109),
		Enum.Material.Glass
	)
	part(
		model,
		"HarvestSack",
		Vector3.new(3, 2, 2.5),
		Vector3.new(width * 0.32, 2, depth * 0.34),
		colors.roof,
		Enum.Material.Fabric
	)
end
function builders.timber(model, width, depth)
	awning(model, -7, -2, 12, 10, 5.5)
	part(model, "FrameWorkingBench", Vector3.new(8, 2.4, 3), Vector3.new(-7, 2.2, -1), colors.wood, Enum.Material.Wood)
	for index = -2, 2 do
		part(
			model,
			"BundledGerRoofPole",
			Vector3.new(11, 0.4, 0.4),
			Vector3.new(width * 0.23, 1.5 + math.abs(index) * 0.25, index * 0.7),
			colors.wood,
			Enum.Material.Wood
		)
	end
	for index = -2, 2 do
		local lattice = part(
			model,
			"StoredLatticeRod",
			Vector3.new(7, 0.22, 0.3),
			Vector3.new(3, 1.5, depth * 0.31 + index * 0.35),
			colors.wood,
			Enum.Material.Wood
		)
		lattice.CFrame *= CFrame.Angles(0, index * 0.15, 0)
	end
end
function builders.material(model, width, depth)
	part(
		model,
		"SettledClayGatheringBed",
		Vector3.new(width * 0.58, 0.45, depth * 0.55),
		Vector3.new(-3, 1.15, -1),
		colors.clay,
		Enum.Material.Mud
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"LowEarthBank",
			Vector3.new(width * 0.64, 1, 1.5),
			Vector3.new(-2, 1.5, side * depth * 0.32),
			colors.earth,
			Enum.Material.Ground
		)
	end
	for row = -1, 1 do
		part(model, "PreparedClayLump", Vector3.new(3, 1.2, 2.5), Vector3.new(width * 0.29, 1.6, row * 3), colors.clay)
	end
	pot(model, -width * 0.32, depth * 0.3, 0.65)
end
function builders.workshop(model, _width, depth)
	-- Settled Karakorum craft context; superstructure is deliberately non-monumental.
	part(
		model,
		"UrbanCraftEarthWall",
		Vector3.new(13, 5.5, 0.8),
		Vector3.new(-7, 3.75, -6),
		colors.earth,
		Enum.Material.Sandstone
	)
	awning(model, -7, -1.5, 13, 9, 5.8)
	part(model, "PotterWorkBoard", Vector3.new(9, 2.4, 3), Vector3.new(-7, 2.2, -1), colors.wood, Enum.Material.Wood)
	disc(model, "PotteryFiringChamber", 3.2, 4.5, Vector3.new(7, 3.25, -2), colors.clay, Enum.Material.Sandstone)
	local cap = part(
		model,
		"KilnCapAbstraction",
		Vector3.new(6.4, 2.5, 6.4),
		Vector3.new(7, 5.4, -2),
		colors.clay,
		Enum.Material.Sandstone
	)
	cap.Shape = Enum.PartType.Ball
	part(model, "KilnFireHole", Vector3.new(1.7, 1.5, 0.2), Vector3.new(7, 2, 1.3), colors.shadow)
	for _, x in { -10, -6, 4, 9 } do
		pot(model, x, depth * 0.3, 0.65)
	end
end
function builders.storehouse(model, width, depth)
	ger(model, 0, -2, math.min(width, depth) * 0.3, 4.5, 2.4)
	for _, x in { -7, 0, 7 } do
		coffer(model, x, depth * 0.34, 4)
	end
	for _, x in { -10, 10 } do
		local roll = part(
			model,
			"RolledSupplyFelt",
			Vector3.new(4, 1.7, 1.7),
			Vector3.new(x, 1.85, -3),
			colors.roof,
			Enum.Material.Fabric
		)
		roll.Shape = Enum.PartType.Cylinder
	end
end
function builders.training(model, width, depth)
	part(
		model,
		"OpenPracticeEarth",
		Vector3.new(width - 4, 0.2, depth - 4),
		Vector3.new(0, 1.1, 0),
		colors.earth,
		Enum.Material.Ground
	)
	for _, x in { -10, 0, 10 } do
		part(model, "TargetSupport", Vector3.new(0.6, 5, 0.6), Vector3.new(x, 3.5, -5), colors.wood, Enum.Material.Wood)
		part(
			model,
			"WovenPracticeTarget",
			Vector3.new(3.4, 3.4, 0.35),
			Vector3.new(x, 4.4, -5.4),
			colors.roof,
			Enum.Material.Fabric
		)
	end
	awning(model, 0, depth * 0.31, 15, 7, 4.7)
	part(
		model,
		"PracticeWeaponRack",
		Vector3.new(12, 2.7, 1.5),
		Vector3.new(0, 2.35, depth * 0.31),
		colors.wood,
		Enum.Material.Wood
	)
end
function builders.healer(model, width, depth)
	ger(model, 0, -2.2, math.min(width, depth) * 0.3, 4, 2.8)
	part(
		model,
		"TreatmentLowFrame",
		Vector3.new(5, 1.2, 6),
		Vector3.new(-2, 1.6, depth * 0.28),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"TreatmentFeltBedding",
		Vector3.new(4.8, 0.35, 5.8),
		Vector3.new(-2, 2.4, depth * 0.28),
		colors.roof,
		Enum.Material.Fabric
	)
	part(
		model,
		"FoldedTreatmentLinen",
		Vector3.new(1.8, 0.3, 1.5),
		Vector3.new(-2, 2.72, depth * 0.24),
		colors.felt,
		Enum.Material.Fabric
	)
	pot(model, width * 0.3, depth * 0.32, 0.6)
end
function MongolKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end
function MongolKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("mongols")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Mongol building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"EarthFooting",
		Vector3.new(width, 0.8, depth),
		Vector3.new(0, 0.4, 0),
		colors.earth,
		Enum.Material.Ground
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "mongols")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("HistoricalPeriod", "Mongol Empire · 1206–1260 CE")
	model:SetAttribute("EvidenceCard", "docs/notes/Mongol Sandbox Art.md")
	return model
end
function MongolKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Mongol presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(204, 164, 122)
	local coat = if role == "melee"
		then Color3.fromRGB(115, 84, 60)
		elseif role == "ranged" then Color3.fromRGB(142, 118, 78)
		else Color3.fromRGB(183, 171, 140)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "WrappedCoat", Vector3.new(1.98, 2.05, 1.06), Vector3.new(0, 3.1, 0), coat, Enum.Material.Fabric)
	part(model, "CoatHem", Vector3.new(2.1, 1.4, 1.2), Vector3.new(0, 2, 0), coat, Enum.Material.Fabric)
	local edge = part(
		model,
		"OverlappingCoatEdge",
		Vector3.new(0.13, 1.6, 0.08),
		Vector3.new(0.2, 3.5, -0.57),
		colors.rope,
		Enum.Material.Fabric
	)
	edge.CFrame *= CFrame.Angles(0, 0, -0.4)
	part(model, "ClothSash", Vector3.new(2.12, 0.24, 1.23), Vector3.new(0, 2.65, 0), colors.rope, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Sleeve",
			Vector3.new(0.84, 1.5, 0.9),
			Vector3.new(side * 1.35, 3.3, 0),
			coat,
			Enum.Material.Fabric
		)
		part(
			model,
			label .. " Trousers",
			Vector3.new(0.84, 1.8, 0.9),
			Vector3.new(side * 0.5, 1.1, 0),
			colors.wood,
			Enum.Material.Fabric
		)
		part(
			model,
			label .. " Boot",
			Vector3.new(0.9, 0.7, 1.1),
			Vector3.new(side * 0.5, 0.35, -0.08),
			colors.rope,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	local cap = part(
		model,
		"PlainFeltCap",
		Vector3.new(1.6, 0.65, 1.45),
		Vector3.new(0, 5.3, 0),
		colors.rope,
		Enum.Material.Fabric
	)
	cap.Shape = Enum.PartType.Ball
	if role == "melee" then
		part(
			model,
			"BladeGrip",
			Vector3.new(0.18, 0.75, 0.18),
			Vector3.new(1.45, 3.1, -0.3),
			colors.wood,
			Enum.Material.Leather
		)
		part(
			model,
			"BladeGuard",
			Vector3.new(0.8, 0.14, 0.2),
			Vector3.new(1.45, 3.5, -0.3),
			colors.iron,
			Enum.Material.Metal
		)
		part(
			model,
			"SlightlyCurvedBlade",
			Vector3.new(0.23, 2.3, 0.12),
			Vector3.new(1.48, 4.7, -0.3),
			colors.iron,
			Enum.Material.Metal
		)
		local tip = part(
			model,
			"BladeTipAbstraction",
			Vector3.new(0.2, 0.7, 0.12),
			Vector3.new(1.63, 6.15, -0.3),
			colors.iron,
			Enum.Material.Metal
		)
		tip.CFrame *= CFrame.Angles(0, 0, -0.2)
	elseif role == "ranged" then
		for _, side in { -1, 1 } do
			local limb = part(
				model,
				"RecurvedBowLimb",
				Vector3.new(0.13, 1.5, 0.15),
				Vector3.new(1.4, 3 + side * 0.65, -0.4),
				colors.wood,
				Enum.Material.Wood
			)
			limb.CFrame *= CFrame.Angles(0, 0, side * 0.4)
			local tip = part(
				model,
				"BowTip",
				Vector3.new(0.12, 0.6, 0.14),
				Vector3.new(1.35, 3 + side * 1.55, -0.4),
				colors.wood,
				Enum.Material.Wood
			)
			tip.CFrame *= CFrame.Angles(0, 0, -side * 0.45)
		end
		part(
			model,
			"BowString",
			Vector3.new(0.035, 3.55, 0.035),
			Vector3.new(1.58, 3, -0.4),
			colors.felt,
			Enum.Material.Fabric
		)
		part(
			model,
			"ArrowQuiver",
			Vector3.new(0.7, 2, 0.6),
			Vector3.new(-1, 3.1, 0.65),
			colors.rope,
			Enum.Material.Leather
		)
		for index = 0, 2 do
			part(
				model,
				"ArrowShaft",
				Vector3.new(0.06, 1.2, 0.06),
				Vector3.new(-1.18 + index * 0.18, 4.1, 0.65),
				colors.wood,
				Enum.Material.Wood
			)
		end
	else
		part(
			model,
			"LinenSatchel",
			Vector3.new(0.9, 1.1, 0.5),
			Vector3.new(-1.1, 2.3, -0.3),
			colors.felt,
			Enum.Material.Fabric
		)
		part(
			model,
			"FoldedBandage",
			Vector3.new(0.8, 0.3, 0.7),
			Vector3.new(1.35, 2.1, -0.25),
			colors.felt,
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "mongols")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Mongol Sandbox Art.md")
	return model
end
return MongolKit

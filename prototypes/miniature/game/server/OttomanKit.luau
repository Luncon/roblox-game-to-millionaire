--!strict
-- Original Süleyman-era commercial/domestic candidates; see evidence gaps in note.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local OttomanKit = {}
local colors = {
	plaster = Color3.fromRGB(221, 211, 183),
	stone = Color3.fromRGB(177, 171, 150),
	brick = Color3.fromRGB(151, 91, 65),
	tile = Color3.fromRGB(140, 73, 48),
	wood = Color3.fromRGB(103, 74, 46),
	clay = Color3.fromRGB(166, 107, 63),
	soil = Color3.fromRGB(99, 78, 48),
	grain = Color3.fromRGB(210, 181, 83),
	cloth = Color3.fromRGB(191, 179, 138),
	blue = Color3.fromRGB(54, 102, 124),
	shadow = Color3.fromRGB(49, 49, 39),
}
local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	return object
end
local function roofTriangle(model, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Cross(ac).Magnitude < 0.0001 then
		return
	end
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		c, a = a, c
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal = ac:Cross(ab).Unit
	local along = bc.Unit
	local up = along:Cross(normal).Unit
	local height = math.abs(ab:Dot(up))
	for _, side in { { b, normal, along, math.abs(ab:Dot(along)) }, { c, -normal, -along, math.abs(ac:Dot(along)) } } do
		if side[4] < 0.001 then
			continue
		end
		local wedge = Instance.new("WedgePart")
		wedge.Name, wedge.Size = "HippedTileRoofFacet", Vector3.new(0.18, height, side[4])
		wedge.CFrame = CFrame.fromMatrix((a + side[1]) / 2, side[2], up, side[3])
		wedge.Anchored, wedge.CanCollide, wedge.CanTouch, wedge.CanQuery = true, false, false, false
		wedge.TopSurface, wedge.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		wedge.Color, wedge.Material, wedge.Parent = colors.tile, Enum.Material.ClayRoofTiles, model
	end
end
local function hippedRoof(model, x, z, width, depth, wallTop)
	local long, short = math.max(width, depth), math.min(width, depth)
	local frame = CFrame.new(x, 0, z) * CFrame.Angles(0, if depth > width then math.pi / 2 else 0, 0)
	local rise, ridge = short * 0.28, (long - short) / 2
	local function point(px, py, pz)
		return frame:PointToWorldSpace(Vector3.new(px, py, pz))
	end
	local fl, fr = point(-long / 2, wallTop, short / 2), point(long / 2, wallTop, short / 2)
	local bl, br = point(-long / 2, wallTop, -short / 2), point(long / 2, wallTop, -short / 2)
	local left, right = point(-ridge, wallTop + rise, 0), point(ridge, wallTop + rise, 0)
	for _, triangle in
		{
			{ fl, fr, right },
			{ fl, right, left },
			{ bl, left, right },
			{ bl, right, br },
			{ fl, left, bl },
			{ fr, br, right },
		}
	do
		roofTriangle(model, triangle[1], triangle[2], triangle[3])
	end
end
local function room(model, x, z, width, depth, height)
	part(
		model,
		"StoneDomesticPlinth",
		Vector3.new(width, 1.4, depth),
		Vector3.new(x, 1.7, z),
		colors.stone,
		Enum.Material.Slate
	)
	part(
		model,
		"TimberPlasterRoom",
		Vector3.new(width, height, depth),
		Vector3.new(x, 2.4 + height / 2, z),
		colors.plaster,
		Enum.Material.Plaster
	)
	for _, side in { -1, 1 } do
		for _, endSign in { -1, 1 } do
			part(
				model,
				"PlainTimberFramePost",
				Vector3.new(0.55, height, 0.55),
				Vector3.new(x + side * (width / 2 - 0.2), 2.4 + height / 2, z + endSign * (depth / 2 - 0.2)),
				colors.wood,
				Enum.Material.Wood
			)
		end
		part(
			model,
			"DomesticTimberShutter",
			Vector3.new(2.2, 2.3, 0.2),
			Vector3.new(x + side * width * 0.27, 2.4 + height * 0.62, z + depth / 2 + 0.12),
			colors.wood,
			Enum.Material.WoodPlanks
		)
	end
	part(
		model,
		"PlainTimberDoor",
		Vector3.new(2.6, height * 0.75, 0.22),
		Vector3.new(x, 2.4 + height * 0.375, z + depth / 2 + 0.14),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"EavesTimberBeam",
		Vector3.new(width + 0.5, 0.4, depth + 0.5),
		Vector3.new(x, height + 2.6, z),
		colors.wood,
		Enum.Material.Wood
	)
	hippedRoof(model, x, z, width + 1.2, depth + 1.2, height + 2.8)
end
local function arch(model, x, z, width, baseY)
	local radius = width / 2
	for index = 0, 6 do
		local angle = index * math.pi / 6
		local block = part(
			model,
			"HanEntryVoussoir",
			Vector3.new(1.5, 1, 1.7),
			Vector3.new(x + math.cos(angle) * radius, baseY + math.sin(angle) * radius, z),
			colors.stone,
			Enum.Material.Limestone
		)
		block.CFrame *= CFrame.Angles(0, 0, angle + math.pi / 2)
	end
	for _, side in { -1, 1 } do
		part(
			model,
			"HanEntryPier",
			Vector3.new(1.2, baseY - 1, 1.8),
			Vector3.new(x + side * radius, (baseY + 1) / 2, z),
			colors.stone,
			Enum.Material.Limestone
		)
	end
end
local function shade(model, x, z, width, depth, height)
	for _, side in { -1, 1 } do
		part(
			model,
			"ShopAwningPost",
			Vector3.new(0.55, height, 0.55),
			Vector3.new(x + side * (width / 2 - 0.5), 1 + height / 2, z + depth / 2 - 0.4),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"PlainShopAwning",
		Vector3.new(width, 0.35, depth),
		Vector3.new(x, height + 1, z),
		colors.cloth,
		Enum.Material.Fabric
	)
end
local function vessel(model, x, z, scale)
	local jar = part(
		model,
		"PlainClayJar",
		Vector3.new(2.3, 3.1, 2.3) * scale,
		Vector3.new(x, 1 + 1.55 * scale, z),
		colors.clay
	)
	jar.Shape = Enum.PartType.Ball
	local mouth =
		part(model, "JarMouth", Vector3.new(0.13, 1.1, 1.1) * scale, Vector3.new(x, 1 + 2.95 * scale, z), colors.shadow)
	mouth.Shape = Enum.PartType.Cylinder
	mouth.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end
local builders = {}
function builders.house(model, width, depth)
	room(model, 0, -depth * 0.15, width - 6, depth * 0.49, 7)
	for _, side in { -1, 1 } do
		part(
			model,
			"DomesticCourtWall",
			Vector3.new(0.8, 3.3, depth * 0.32),
			Vector3.new(side * width * 0.41, 2.65, depth * 0.29),
			colors.stone,
			Enum.Material.Slate
		)
	end
	vessel(model, -width * 0.28, depth * 0.31, 0.7)
end
function builders.civic(model, width, depth)
	room(model, 0, -depth * 0.29, width * 0.7, depth * 0.24, 9)
	for _, side in { -1, 1 } do
		part(
			model,
			"HanMasonryWing",
			Vector3.new(5, 7, depth * 0.5),
			Vector3.new(side * width * 0.4, 4.5, -1),
			colors.stone,
			Enum.Material.Limestone
		)
		for band = 1, 3 do
			part(
				model,
				"HanBrickCourse",
				Vector3.new(5.1, 0.45, depth * 0.5 + 0.1),
				Vector3.new(side * width * 0.4, 1 + band * 2, -1),
				colors.brick,
				Enum.Material.Brick
			)
		end
		hippedRoof(model, side * width * 0.4, -1, 5.8, depth * 0.5 + 0.8, 8.3)
	end
	arch(model, 0, depth * 0.35, 6.4, 5.7)
	shade(model, 0, 2, 12, 5, 6)
	part(
		model,
		"HanExchangeCounter",
		Vector3.new(10, 2.4, 2.5),
		Vector3.new(0, 2.2, 2),
		colors.wood,
		Enum.Material.Wood
	)
end
function builders.farm(model, width, depth)
	part(
		model,
		"CerealFieldSoil",
		Vector3.new(width - 5, 0.45, depth - 5),
		Vector3.new(0, 1.2, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"LowFieldStoneBorder",
			Vector3.new(width - 3, 1, 0.8),
			Vector3.new(0, 1.5, side * depth * 0.44),
			colors.stone,
			Enum.Material.Slate
		)
	end
	for row = -2, 2 do
		for column = -3, 3 do
			local x, z = column * (width - 8) / 8, row * (depth - 8) / 6
			part(model, "GrainStalk", Vector3.new(0.25, 2.2, 0.25), Vector3.new(x, 2.5, z), colors.grain)
			part(model, "GrainEar", Vector3.new(0.55, 0.9, 0.45), Vector3.new(x, 3.6, z), colors.grain)
		end
	end
	part(
		model,
		"HarvestSack",
		Vector3.new(3.2, 2.2, 2.8),
		Vector3.new(width * 0.32, 2.1, depth * 0.3),
		colors.cloth,
		Enum.Material.Fabric
	)
end
function builders.timber(model, width, depth)
	shade(model, -7, -2, 12, 10, 6)
	part(model, "CarpenterBench", Vector3.new(8, 2.6, 3), Vector3.new(-7, 2.3, -1), colors.wood, Enum.Material.Wood)
	for tier = 0, 1 do
		for row = -1, 1 do
			local log = part(
				model,
				"SupplyTimber",
				Vector3.new(11, 1.7, 1.7),
				Vector3.new(width * 0.23, 1.85 + tier * 1.6, row * 2.1),
				colors.wood,
				Enum.Material.Wood
			)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	part(
		model,
		"PreparedPlank",
		Vector3.new(12, 0.4, 2.2),
		Vector3.new(-2, 1.35, depth * 0.33),
		colors.wood,
		Enum.Material.WoodPlanks
	)
end
function builders.material(model, width, depth)
	part(
		model,
		"WetPotteryClayBed",
		Vector3.new(width * 0.6, 0.4, depth * 0.58),
		Vector3.new(-3, 1.15, -1),
		colors.clay,
		Enum.Material.Mud
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"ClayWorkBank",
			Vector3.new(width * 0.66, 1, 1.5),
			Vector3.new(-2, 1.5, side * depth * 0.34),
			colors.soil,
			Enum.Material.Ground
		)
	end
	for row = -1, 1 do
		part(model, "PreparedClayStock", Vector3.new(3, 1.1, 2.5), Vector3.new(width * 0.3, 1.55, row * 3), colors.clay)
	end
	vessel(model, -width * 0.32, depth * 0.3, 0.7)
end
function builders.workshop(model, _width, depth)
	room(model, -7, -3, 12, 11, 6)
	local kiln = part(
		model,
		"BrickFiringChamber",
		Vector3.new(5, 6.3, 6.3),
		Vector3.new(7, 3.5, -2),
		colors.brick,
		Enum.Material.Brick
	)
	kiln.Shape = Enum.PartType.Cylinder
	kiln.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	part(model, "KilnFireHole", Vector3.new(1.8, 1.4, 0.2), Vector3.new(7, 1.9, 1.3), colors.shadow)
	part(
		model,
		"CeramicWorkingBoard",
		Vector3.new(10, 2.2, 3),
		Vector3.new(-5, 2.1, depth * 0.29),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		model,
		"CeramicDisplayBoard",
		Vector3.new(8, 2.2, 3),
		Vector3.new(6.5, 2.1, depth * 0.29),
		colors.wood,
		Enum.Material.Wood
	)
	for _, x in { -8, -4, 4, 9 } do
		local dish = part(
			model,
			"GlazedDishAbstraction",
			Vector3.new(0.25, 2.5, 2.5),
			Vector3.new(x, 3.4, depth * 0.29),
			Color3.fromRGB(229, 229, 207),
			Enum.Material.CeramicTiles
		)
		dish.Shape = Enum.PartType.Cylinder
		dish.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		local center = part(
			model,
			"PlainBlueDishCenter",
			Vector3.new(0.12, 1.1, 1.1),
			Vector3.new(x, 3.6, depth * 0.29),
			colors.blue
		)
		center.Shape = Enum.PartType.Cylinder
		center.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
end
function builders.storehouse(model, width, depth)
	room(model, 0, -2, width * 0.73, depth * 0.58, 7.5)
	part(
		model,
		"SecureStoreDoubleDoor",
		Vector3.new(4.5, 5, 0.3),
		Vector3.new(0, 4.9, depth * 0.29 - 1.7),
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -7, 7 } do
		part(
			model,
			"GoodsChest",
			Vector3.new(4.2, 2.6, 3),
			Vector3.new(x, 2.3, depth * 0.34),
			colors.wood,
			Enum.Material.Wood
		)
	end
end
function builders.training(model, width, depth)
	part(
		model,
		"ArcheryPracticeEarth",
		Vector3.new(width - 4, 0.2, depth - 4),
		Vector3.new(0, 1.1, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"LowPracticeBoundary",
			Vector3.new(0.8, 2.6, depth - 3),
			Vector3.new(side * width * 0.46, 2.3, 0),
			colors.stone,
			Enum.Material.Slate
		)
	end
	for _, x in { -10, 0, 10 } do
		part(
			model,
			"PracticeTargetPost",
			Vector3.new(0.6, 5, 0.6),
			Vector3.new(x, 3.5, -5),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"WovenArcheryTarget",
			Vector3.new(3.3, 3.3, 0.35),
			Vector3.new(x, 4.4, -5.4),
			colors.cloth,
			Enum.Material.Fabric
		)
	end
	shade(model, 0, depth * 0.3, 15, 7, 4.8)
end
function builders.healer(model, width, depth)
	room(model, 0, -depth * 0.25, width * 0.62, depth * 0.31, 5.5)
	shade(model, 0, depth * 0.23, 13, 9, 5.8)
	part(
		model,
		"TreatmentWoodFrame",
		Vector3.new(5, 1.3, 6),
		Vector3.new(-2, 1.65, 5.5),
		colors.wood,
		Enum.Material.Wood
	)
	part(model, "LinenCouch", Vector3.new(4.8, 0.3, 5.8), Vector3.new(-2, 2.5, 5.5), colors.cloth, Enum.Material.Fabric)
	part(
		model,
		"FoldedTreatmentLinen",
		Vector3.new(1.8, 0.35, 1.6),
		Vector3.new(-2, 2.8, 4.7),
		Color3.fromRGB(231, 224, 203),
		Enum.Material.Fabric
	)
	vessel(model, 6, 6, 0.65)
end
function OttomanKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end
function OttomanKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("ottomans")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Ottoman building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"PlainStoneFooting",
		Vector3.new(width, 0.8, depth),
		Vector3.new(0, 0.4, 0),
		colors.stone,
		Enum.Material.Slate
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "ottomans")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("HistoricalPeriod", "Ottoman Empire · 1520–1566 CE")
	model:SetAttribute("EvidenceCard", "docs/notes/Ottoman Sandbox Art.md")
	return model
end
function OttomanKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Ottoman presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(194, 148, 104)
	local robe = if role == "melee"
		then Color3.fromRGB(139, 69, 49)
		elseif role == "ranged" then Color3.fromRGB(103, 114, 79)
		else Color3.fromRGB(196, 185, 151)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "PlainSleevedCoat", Vector3.new(1.98, 2.05, 1.06), Vector3.new(0, 3.1, 0), robe, Enum.Material.Fabric)
	part(model, "CoatHem", Vector3.new(2.1, 1.45, 1.2), Vector3.new(0, 2, 0), robe, Enum.Material.Fabric)
	part(
		model,
		"PlainClothSash",
		Vector3.new(2.12, 0.24, 1.23),
		Vector3.new(0, 2.65, 0),
		colors.cloth,
		Enum.Material.Fabric
	)
	for _, side in { -1, 1 } do
		local label = if side == -1 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			label .. " Sleeve",
			Vector3.new(0.84, 1.5, 0.9),
			Vector3.new(side * 1.35, 3.3, 0),
			robe,
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
			label .. " Shoe",
			Vector3.new(0.9, 0.5, 1.1),
			Vector3.new(side * 0.5, 0.25, -0.08),
			colors.shadow,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	for tier = 0, 2 do
		local wrap = part(
			model,
			"WrappedClothHeadwear",
			Vector3.new(0.3, 1.65 - tier * 0.15, 1.65 - tier * 0.15),
			Vector3.new(0, 5.17 + tier * 0.2, 0),
			colors.cloth,
			Enum.Material.Fabric
		)
		wrap.Shape = Enum.PartType.Cylinder
		wrap.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
	if role == "melee" then
		part(
			model,
			"SaberGrip",
			Vector3.new(0.18, 0.75, 0.18),
			Vector3.new(1.45, 3.1, -0.3),
			colors.wood,
			Enum.Material.Leather
		)
		part(
			model,
			"SaberGuard",
			Vector3.new(0.85, 0.14, 0.2),
			Vector3.new(1.45, 3.5, -0.3),
			colors.stone,
			Enum.Material.Metal
		)
		part(
			model,
			"CurvedSaberBlade",
			Vector3.new(0.24, 2.3, 0.13),
			Vector3.new(1.48, 4.7, -0.3),
			colors.stone,
			Enum.Material.Metal
		)
		local tip = part(
			model,
			"SaberTip",
			Vector3.new(0.26, 0.8, 0.13),
			Vector3.new(1.7, 6.15, -0.3),
			colors.stone,
			Enum.Material.Metal
		)
		tip.CFrame *= CFrame.Angles(0, 0, -0.32)
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
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"ArrowQuiver",
			Vector3.new(0.7, 2, 0.6),
			Vector3.new(-1, 3.1, 0.65),
			colors.wood,
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
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"FoldedBandage",
			Vector3.new(0.8, 0.3, 0.7),
			Vector3.new(1.35, 2.1, -0.25),
			Color3.fromRGB(231, 224, 203),
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "ottomans")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Ottoman Sandbox Art.md")
	return model
end
return OttomanKit

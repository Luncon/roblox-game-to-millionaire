--!strict
-- Original practice-site interpretations using each kit's documented material family.
-- These are not excavated barracks plans; no firing, combat or source assets are imported.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = {}
local wood = Color3.fromRGB(116, 81, 48)
local earth = Color3.fromRGB(133, 111, 75)
local straw = Color3.fromRGB(191, 171, 111)
local plaster = Color3.fromRGB(218, 204, 176)
local tile = Color3.fromRGB(155, 76, 48)
local grey = Color3.fromRGB(88, 96, 91)
local brick = Color3.fromRGB(159, 101, 73)
local cards = {
	sparta = "Spartan",
	rome = "Roman",
	persia = "Persian",
	egypt = "Egyptian",
	maurya = "Mauryan",
	seneca = "Seneca",
	vikings = "Viking",
	mongols = "Mongol",
	japan = "Japanese",
	ming = "Ming",
	ottomans = "Ottoman",
	spain = "Spanish",
	britain = "British",
}
local periods = {
	egypt = "New Kingdom · 1300–1200 BCE",
	vikings = "Southern Scandinavia · 900–1050 CE",
	mongols = "Mongol Empire · 1206–1260 CE",
	ottomans = "Ottoman Empire · 1520–1566 CE",
}
local function part(model, name, size, point, color, material, rotation)
	local object = Instance.new("Part")
	object.Name, object.Size = name, size
	object.CFrame = CFrame.new(point) * (rotation or CFrame.identity)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.Wood
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end
local function posts(model, width, z, height, name)
	for _, x in { -width / 2, width / 2 } do
		part(model, name or "ShelterPost", Vector3.new(0.55, height, 0.55), Vector3.new(x, 1 + height / 2, z), wood)
	end
end
local function gable(model, name, width, depth, z, eaves, rise, color, material)
	local half, angle = width / 2, math.atan(rise / (width / 2))
	for _, side in { -1, 1 } do
		part(
			model,
			name,
			Vector3.new(half / math.cos(angle), 0.35, depth),
			Vector3.new(side * half / 2, eaves + rise / 2, z),
			color,
			material,
			CFrame.Angles(0, 0, -side * angle)
		)
	end
end
local function triangle(model, a, b, c, color)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		c, a = a, c
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal).Unit
	local height = math.abs(ab:Dot(up))
	for _, side in { { b, normal, along, math.abs(ab:Dot(along)) }, { c, -normal, -along, math.abs(ac:Dot(along)) } } do
		if side[4] < 0.001 then
			continue
		end
		local wedge = Instance.new("WedgePart")
		wedge.Name, wedge.Size = "HippedRangeRoofFacet", Vector3.new(0.14, height, side[4])
		wedge.CFrame = CFrame.fromMatrix((a + side[1]) / 2, side[2], up, side[3])
		wedge.Anchored, wedge.CanCollide, wedge.CanTouch, wedge.CanQuery = true, false, false, false
		wedge.Color, wedge.Material, wedge.Parent = color, Enum.Material.ClayRoofTiles, model
	end
end
local function hip(model, width, depth, z, top, rise, color)
	local fl, fr = Vector3.new(-width / 2, top, z + depth / 2), Vector3.new(width / 2, top, z + depth / 2)
	local bl, br = Vector3.new(-width / 2, top, z - depth / 2), Vector3.new(width / 2, top, z - depth / 2)
	local left, right =
		Vector3.new(-(width - depth) / 2, top + rise, z), Vector3.new((width - depth) / 2, top + rise, z)
	for _, t in
		{
			{ fl, fr, right },
			{ fl, right, left },
			{ bl, left, right },
			{ bl, right, br },
			{ fl, left, bl },
			{
				fr,
				br,
				right,
			},
		}
	do
		triangle(model, t[1], t[2], t[3], color)
	end
end
local designs = {}
function designs.sparta(model)
	part(
		model,
		"LaconianLowRearWall",
		Vector3.new(24, 3, 0.8),
		Vector3.new(0, 2.5, -13),
		plaster,
		Enum.Material.Plaster
	)
	posts(model, 22, -9, 5)
	gable(model, "LaconianTileRangeShade", 25, 7, -11, 6, 3, tile, Enum.Material.ClayRoofTiles)
	part(model, "SlingStoneTray", Vector3.new(4, 0.6, 2), Vector3.new(-8, 1.3, 7), earth, Enum.Material.Limestone)
end
function designs.rome(model)
	part(model, "BrickTargetStore", Vector3.new(27, 5, 3), Vector3.new(0, 3.5, -12), brick, Enum.Material.Brick)
	for _, x in { -11, 0, 11 } do
		part(model, "RomanPier", Vector3.new(0.9, 5, 1), Vector3.new(x, 3.5, -8), plaster, Enum.Material.Limestone)
	end
	gable(model, "RomanRangeTegula", 29, 7, -11, 6.2, 2, tile, Enum.Material.ClayRoofTiles)
end
function designs.persia(model)
	part(
		model,
		"EarthRangeBackstop",
		Vector3.new(26, 5.2, 1.5),
		Vector3.new(0, 3.6, -13),
		Color3.fromRGB(184, 150, 106),
		Enum.Material.Sandstone
	)
	posts(model, 23, -9, 5)
	for x = -10, 10, 5 do
		part(model, "ExposedFlatRoofBeam", Vector3.new(0.6, 0.6, 7), Vector3.new(x, 6.1, -11), wood)
	end
	part(model, "EarthRoofRangeSlab", Vector3.new(25, 0.4, 7), Vector3.new(0, 6.6, -11), earth, Enum.Material.Ground)
end
function designs.egypt(model)
	part(
		model,
		"MudbrickRangeScreen",
		Vector3.new(30, 4, 1.2),
		Vector3.new(0, 3, -13),
		Color3.fromRGB(175, 139, 89),
		Enum.Material.Sandstone
	)
	posts(model, 18, -8, 5, "ReedShadePost")
	part(
		model,
		"LinenRangeAwning",
		Vector3.new(21, 0.25, 7),
		Vector3.new(0, 6, -11),
		Color3.fromRGB(232, 220, 186),
		Enum.Material.Fabric,
		CFrame.Angles(math.rad(-8), 0, 0)
	)
	for _, x in { -14, 14 } do
		part(
			model,
			"MudbrickScreenButtress",
			Vector3.new(2, 3, 3),
			Vector3.new(x, 2.5, -12),
			earth,
			Enum.Material.Sandstone
		)
	end
end
function designs.maurya(model)
	posts(model, 22, -9, 5, "TimberRangeSupport")
	posts(model, 22, -13, 5, "RearTimberRangeSupport")
	for index = 0, 9 do
		local x = -11.25 + index * 2.5
		local y = 6 + 2.8 * (1 - (x / 12.5) ^ 2)
		part(
			model,
			"BowedReedRangeCover",
			Vector3.new(2.7, 0.35, 7),
			Vector3.new(x, y, -11),
			straw,
			Enum.Material.Grass,
			CFrame.Angles(0, 0, math.atan(-5.6 * x / 12.5 ^ 2))
		)
	end
	part(model, "EarthenEquipmentBench", Vector3.new(15, 1.2, 2), Vector3.new(0, 1.6, -12), earth, Enum.Material.Ground)
end
function designs.seneca(model)
	local bark = Color3.fromRGB(132, 111, 83)
	for index = 0, 8 do
		local angle = index * math.pi / 8
		local x, y = math.cos(angle) * 10, 3 + math.sin(angle) * 7
		part(
			model,
			"BentSaplingRangeCover",
			Vector3.new(3.8, 0.4, 6),
			Vector3.new(x, y, -11),
			bark,
			Enum.Material.WoodPlanks,
			CFrame.Angles(0, 0, angle - math.pi / 2)
		)
		part(
			model,
			"BarkFiberLashing",
			Vector3.new(3.9, 0.18, 0.18),
			Vector3.new(x, y + 0.25, -9),
			straw,
			Enum.Material.Fabric,
			CFrame.Angles(0, 0, angle - math.pi / 2)
		)
	end
	for _, x in { -15, 15 } do
		part(model, "ClearingBoundaryLog", Vector3.new(1, 1, 21), Vector3.new(x, 1.1, 1), wood)
	end
end
function designs.vikings(model)
	for index = -2, 2 do
		local x = index * 4.4
		local halfDepth = 3.6 - 0.3 * math.abs(index)
		local angle = math.rad(32)
		for _, side in { -1, 1 } do
			part(
				model,
				"SegmentedThatchRangeRoof",
				Vector3.new(4.7, 0.45, halfDepth / math.cos(angle)),
				Vector3.new(x, 5.2 + halfDepth * math.tan(angle) / 2, -11 + side * halfDepth / 2),
				Color3.fromRGB(154, 135, 86),
				Enum.Material.Grass,
				CFrame.Angles(side * angle, 0, 0)
			)
		end
	end
	posts(model, 20, -10, 4.4, "SlopedHallRangeSupport")
	for _, side in { -1, 1 } do
		part(
			model,
			"CurvedTimberWindbreak",
			Vector3.new(0.8, 3.5, 6),
			Vector3.new(side * 9.5, 2.75, -11),
			wood,
			Enum.Material.WoodPlanks,
			CFrame.Angles(0, side * math.rad(12), 0)
		)
	end
end
function designs.mongols(model)
	local felt = Color3.fromRGB(216, 206, 174)
	for index = 0, 9 do
		local angle = index * math.pi * 2 / 10
		part(
			model,
			"FeltRangeWindbreak",
			Vector3.new(3.8, 3.5, 0.4),
			Vector3.new(math.sin(angle) * 5.8, 2.75, -9 + math.cos(angle) * 5.8),
			felt,
			Enum.Material.Fabric,
			CFrame.Angles(0, angle, 0)
		)
		part(
			model,
			"LowFeltRangeCover",
			Vector3.new(3.8, 0.25, 4.4),
			Vector3.new(math.sin(angle) * 3.1, 5.4, -9 + math.cos(angle) * 3.1),
			felt,
			Enum.Material.Fabric,
			CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(18), 0, 0)
		)
	end
	part(model, "FeltCoverCrown", Vector3.new(3, 0.4, 3), Vector3.new(0, 6, -9), wood)
	posts(model, 27, -4, 2, "PortableRangeRopePost")
end
function designs.japan(model)
	part(
		model,
		"TimberBoardRangeRear",
		Vector3.new(24, 4.5, 0.5),
		Vector3.new(0, 3.25, -13),
		wood,
		Enum.Material.WoodPlanks
	)
	posts(model, 21, -8.5, 5.2)
	gable(model, "TownShingleRangeRoof", 27, 6.5, -11, 6.2, 2.6, grey, Enum.Material.WoodPlanks)
	part(
		model,
		"WhiteRangeSidePanel",
		Vector3.new(0.55, 4, 5),
		Vector3.new(-10.5, 3, -10.8),
		plaster,
		Enum.Material.Plaster
	)
	part(
		model,
		"RaisedTimberShootingLine",
		Vector3.new(24, 0.4, 3),
		Vector3.new(0, 1.2, 7),
		wood,
		Enum.Material.WoodPlanks
	)
end
function designs.ming(model)
	part(model, "GreyBrickRangeRear", Vector3.new(27, 4, 0.8), Vector3.new(0, 3, -13), grey, Enum.Material.Brick)
	posts(model, 23, -8, 5)
	hip(model, 28, 7, -11, 6, 2.5, Color3.fromRGB(76, 84, 82))
	for _, x in { -14, 14 } do
		part(
			model,
			"SteppedRangeScreen",
			Vector3.new(1.2, 3, 5),
			Vector3.new(x, 2.5, -10),
			plaster,
			Enum.Material.Plaster
		)
		part(
			model,
			"SteppedRangeScreenCoping",
			Vector3.new(1.5, 0.5, 3),
			Vector3.new(x, 4.25, -11),
			grey,
			Enum.Material.Slate
		)
	end
end
function designs.ottomans(model)
	part(model, "StoneRangeStoreBay", Vector3.new(19, 4.2, 3), Vector3.new(0, 3.1, -12), plaster, Enum.Material.Plaster)
	for _, x in { -8, 8 } do
		part(
			model,
			"MasonryRangePier",
			Vector3.new(1, 5, 1),
			Vector3.new(x, 3.5, -8),
			Color3.fromRGB(175, 167, 145),
			Enum.Material.Limestone
		)
	end
	hip(model, 23, 8, -11, 6, 2, tile)
	part(model, "RangeSideSeat", Vector3.new(3, 1.5, 8), Vector3.new(-14, 1.75, -5), wood, Enum.Material.WoodPlanks)
end
function designs.spain(model)
	part(model, "BrickRangeSideBay", Vector3.new(5, 4.5, 6), Vector3.new(10, 3.25, -11), brick, Enum.Material.Brick)
	posts(model, 24, -8.5, 4.5, "PatioRangePost")
	part(
		model,
		"TileRangeLeanRoof",
		Vector3.new(28, 0.45, 7),
		Vector3.new(0, 6.1, -11),
		tile,
		Enum.Material.ClayRoofTiles,
		CFrame.Angles(math.rad(-12), 0, 0)
	)
	part(model, "CrossbowRestBench", Vector3.new(12, 1.6, 2), Vector3.new(0, 1.8, 7), wood, Enum.Material.WoodPlanks)
end
function designs.britain(model)
	part(model, "BrickRangeBackstop", Vector3.new(31, 5, 1), Vector3.new(0, 3.5, -13), brick, Enum.Material.Brick)
	part(model, "BrickEquipmentBay", Vector3.new(9, 4.2, 5), Vector3.new(9, 3.1, -10), brick, Enum.Material.Brick)
	part(
		model,
		"SlateRangeLeanRoof",
		Vector3.new(13, 0.4, 6),
		Vector3.new(8, 5.8, -10.5),
		Color3.fromRGB(84, 96, 104),
		Enum.Material.Slate,
		CFrame.Angles(math.rad(-15), 0, 0)
	)
	part(
		model,
		"TimberEquipmentDoor",
		Vector3.new(3, 3.5, 0.4),
		Vector3.new(9, 2.75, -7.3),
		wood,
		Enum.Material.WoodPlanks
	)
	for _, x in { -13, -6, 1 } do
		part(model, "RegimentalShootingPeg", Vector3.new(0.5, 1.3, 0.5), Vector3.new(x, 1.65, 8), wood)
	end
end
function ArcheryRanges.create(civilizationId: string): Model
	assert(designs[civilizationId], "Unknown archery range civilization: " .. civilizationId)
	local definition = Catalog.buildings.ranged
	assert(definition, "Archery range is missing from catalog")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = "ranged", CFrame.identity
	part(
		model,
		"RangeEarthFooting",
		Vector3.new(definition.width / Config.scale, 1, definition.depth / Config.scale),
		Vector3.new(0, 0.5, 0),
		earth,
		Enum.Material.Ground
	)
	designs[civilizationId](model)
	for _, x in { -10, 0, 10 } do
		local target = part(
			model,
			"WovenRangeTarget",
			Vector3.new(4.4, 4.4, 0.6),
			Vector3.new(x, 4, -1),
			straw,
			Enum.Material.Fabric
		)
		-- Plain practice targets and shooting lines are declared readability inventions.
		target:SetAttribute("PracticeProp", true)
		part(model, "TargetSupport", Vector3.new(0.5, 3, 0.6), Vector3.new(x, 2.5, -1), wood)
	end
	part(model, "ShootingLine", Vector3.new(27, 0.12, 0.35), Vector3.new(0, 1.1, 5), straw, Enum.Material.Fabric)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", civilizationId)
	model:SetAttribute("Kind", "ranged")
	model:SetAttribute("DisplayName", "Archery Range")
	model:SetAttribute("EvidenceCard", "docs/notes/" .. cards[civilizationId] .. " Sandbox Art.md")
	model:SetAttribute(
		"EvidenceScope",
		"Original practice-site interpretation; exact institution and target plan unverified"
	)
	model:SetAttribute("GameInterpretation", true)
	if periods[civilizationId] then
		model:SetAttribute("HistoricalPeriod", periods[civilizationId])
	end
	return model
end
return ArcheryRanges

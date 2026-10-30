--!strict
-- Fantasy animal facilities interpreted through the existing civilization kits.
-- Native scenery only: no animals, scripts, physics or combat authority live here.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Config = require(Shared.Config)
local MountConfig = require(Shared.MountConfig)
local MountStructures = {}
local wood, darkWood = Color3.fromRGB(121, 83, 48), Color3.fromRGB(73, 51, 33)
local stone, plaster = Color3.fromRGB(177, 166, 143), Color3.fromRGB(220, 207, 177)
local clay, earth = Color3.fromRGB(156, 76, 48), Color3.fromRGB(145, 123, 85)
local straw, iron = Color3.fromRGB(192, 169, 105), Color3.fromRGB(78, 84, 80)
local cards = {
	sparta = "Spartan",
	britain = "British",
	seneca = "Seneca",
	mongols = "Mongol",
	vikings = "Viking",
	persia = "Persian",
	japan = "Japanese",
	maurya = "Mauryan",
	spain = "Spanish",
	egypt = "Egyptian",
	rome = "Roman",
	ottomans = "Ottoman",
	ming = "Ming",
}
local function part(model, name, size, x, y, z, color, material, rotation)
	local object = Instance.new("Part")
	object.Name, object.Size = name, size
	object.CFrame = CFrame.new(x, y, z) * (rotation or CFrame.identity)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.Wood
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	return object
end
local function diagonal(model, name, a, b, thickness, color)
	local object = part(model, name, Vector3.new(thickness, thickness, (b - a).Magnitude), 0, 0, 0, color or wood)
	object.CFrame = CFrame.lookAt((a + b) / 2, b)
	return object
end
local function roof(model, name, x, z, width, depth, eaves, rise, color, material)
	local pitch = math.atan(rise / (width / 2))
	for _, side in { -1, 1 } do
		part(
			model,
			name,
			Vector3.new(width / 2 / math.cos(pitch), 0.55, depth),
			x + side * width / 4,
			eaves + rise / 2,
			z,
			color,
			material or Enum.Material.ClayRoofTiles,
			CFrame.Angles(0, 0, -side * pitch)
		)
	end
end
local function post(model, name, x, z, height, color, thickness)
	part(model, name, Vector3.new(thickness or 0.8, height, thickness or 0.8), x, 1 + height / 2, z, color or wood)
end
local function rail(model, name, x, z, width, depth, height, color, solid)
	for _, side in { -1, 1 } do
		if solid then
			part(model, name, Vector3.new(width, height, 0.8), x, 1 + height / 2, z + side * depth / 2, color or wood)
			part(model, name, Vector3.new(0.8, height, depth), x + side * width / 2, 1 + height / 2, z, color or wood)
		else
			for _, y in { height * 0.4, height * 0.85 } do
				part(model, name, Vector3.new(width, 0.45, 0.45), x, 1 + y, z + side * depth / 2, color or wood)
				part(model, name, Vector3.new(0.45, 0.45, depth), x + side * width / 2, 1 + y, z, color or wood)
			end
		end
		for _, endSign in { -1, 1 } do
			post(model, name .. "Post", x + side * width / 2, z + endSign * depth / 2, height + 0.4, color)
		end
	end
end
local function trough(model, name, x, z, width, height)
	part(model, name .. "Base", Vector3.new(width, 0.5, 2.8), x, 1.25, z, darkWood)
	for _, side in { -1, 1 } do
		part(model, name .. "Rim", Vector3.new(width, height, 0.35), x, 1.5 + height / 2, z + side * 1.35, wood)
	end
	part(model, name .. "Feed", Vector3.new(width - 0.5, 0.2, 2.2), x, 1.65, z, straw, Enum.Material.Grass)
end
local function flatShelter(model, name, x, z, width, depth, height, color)
	for _, side in { -1, 1 } do
		for _, endSign in { -1, 1 } do
			post(model, name .. "Post", x + side * (width / 2 - 0.7), z + endSign * (depth / 2 - 0.7), height, wood)
		end
	end
	part(
		model,
		name .. "Roof",
		Vector3.new(width, 0.7, depth),
		x,
		height + 1.35,
		z,
		color or plaster,
		Enum.Material.Ground
	)
end
local function arch(model, name, x, z, width, height, color)
	for _, side in { -1, 1 } do
		part(
			model,
			name .. "Pier",
			Vector3.new(1.4, height / 2, 1.5),
			x + side * width / 2,
			1 + height / 4,
			z,
			color,
			Enum.Material.Brick
		)
	end
	for index = 0, 5 do
		local angle = math.pi * index / 5
		part(
			model,
			name .. "ArchStone",
			Vector3.new(width * 0.32, 1.3, 1.5),
			x + math.cos(angle) * width / 2,
			1 + height / 2 + math.sin(angle) * height / 2,
			z,
			color,
			Enum.Material.Brick,
			CFrame.Angles(0, 0, angle - math.pi / 2)
		)
	end
end
local function ovalFence(model, name, x, z, rx, rz, height, color, segments)
	for index = 0, (segments or 12) - 1 do
		local a = index * 2 * math.pi / (segments or 12)
		local b = (index + 1) * 2 * math.pi / (segments or 12)
		post(model, name .. "Stake", x + math.cos(a) * rx, z + math.sin(a) * rz, height, color, 0.65)
		for _, y in { 1 + height * 0.4, 1 + height * 0.85 } do
			diagonal(
				model,
				name .. "Rail",
				Vector3.new(x + math.cos(a) * rx, y, z + math.sin(a) * rz),
				Vector3.new(x + math.cos(b) * rx, y, z + math.sin(b) * rz),
				0.35,
				color
			)
		end
	end
end
local designs = {}
function designs.sparta(model)
	part(model, "LimestoneDenRear", Vector3.new(38, 6, 1.2), 0, 4, -14, stone, Enum.Material.Limestone)
	part(model, "LimestoneDenSide", Vector3.new(1.2, 6, 18), -18.4, 4, -5, stone, Enum.Material.Limestone)
	for _, x in { -13, 0, 13 } do
		post(model, "DenTimberPier", x, -3, 7, wood, 1.2)
	end
	roof(model, "LionDenTerracottaRoof", 0, -9, 40, 15, 8, 4, clay)
	for _, x in { -12, 12 } do
		rail(model, "BronzeBarLionRun", x, 7, 18, 12, 5, iron, false)
	end
	part(model, "LionRestingStone", Vector3.new(8, 1.4, 5), 0, 1.7, 8, stone, Enum.Material.Limestone)
	trough(model, "LionWaterTrough", 0, -1, 6, 1)
end
function designs.britain(model)
	local brick = Color3.fromRGB(145, 66, 47)
	for _, x in { -15, 15 } do
		part(model, "StableBrickWing", Vector3.new(11, 9, 31), x, 5.5, -1, brick, Enum.Material.Brick)
		roof(model, "CavalrySlateRoof", x, -1, 13, 33, 10, 4, Color3.fromRGB(79, 87, 91), Enum.Material.Slate)
		for _, z in { -11, -1, 9 } do
			part(model, "StableDoor", Vector3.new(0.3, 6.6, 5), x + (if x < 0 then 5.6 else -5.6), 4.3, z, darkWood)
			part(
				model,
				"WhiteDoorLintel",
				Vector3.new(0.5, 0.7, 5.8),
				x + (if x < 0 then 5.8 else -5.8),
				7.9,
				z,
				plaster
			)
		end
	end
	for _, z in { -10, 8 } do
		post(model, "CavalryHitchPost", -5, z, 3.5, wood)
		post(model, "CavalryHitchPost", 5, z, 3.5, wood)
		part(model, "HitchingRail", Vector3.new(10, 0.6, 0.6), 0, 3.6, z, wood)
	end
	trough(model, "HorseOatManger", 0, -15, 9, 1.1)
end
function designs.seneca(model)
	local bark = Color3.fromRGB(114, 94, 67)
	for index = 0, 8 do
		local angle = math.pi * index / 8
		part(
			model,
			"BarkLodgeArchPanel",
			Vector3.new(4.8, 0.6, 11),
			-12 + math.cos(angle) * 8,
			3.5 + math.sin(angle) * 8,
			-9,
			bark,
			Enum.Material.Wood,
			CFrame.Angles(0, 0, angle - math.pi / 2)
		)
	end
	part(model, "BarkEndWall", Vector3.new(15, 5, 0.6), -12, 3.5, -14.7, bark)
	ovalFence(model, "ElkWoodlandEnclosure", 6, 3, 14, 12, 4, wood, 10)
	for _, x in { -4, 3, 10 } do
		diagonal(model, "ForkedBrowseRack", Vector3.new(x, 1, 9), Vector3.new(x - 2, 6, 9), 0.5, wood)
		diagonal(model, "BrowseRackFork", Vector3.new(x, 3.8, 9), Vector3.new(x + 2, 6.4, 9), 0.45, wood)
		part(
			model,
			"LeafBrowseBundle",
			Vector3.new(2.7, 2, 1.8),
			x,
			5,
			9,
			Color3.fromRGB(91, 112, 58),
			Enum.Material.Grass
		)
	end
end
function designs.mongols(model)
	ovalFence(model, "SteppeCorral", -5, 2, 15, 13, 3.7, wood, 10)
	local felt = Color3.fromRGB(218, 209, 181)
	for index = 0, 9 do
		local angle = index * math.pi / 5
		part(
			model,
			"SmallFeltTackGerWall",
			Vector3.new(4.6, 5, 0.5),
			15 + math.cos(angle) * 6.5,
			3.5,
			-10 + math.sin(angle) * 6.5,
			felt,
			Enum.Material.Fabric,
			CFrame.Angles(0, -angle + math.pi / 2, 0)
		)
		diagonal(
			model,
			"TackGerRoofRib",
			Vector3.new(15 + math.cos(angle) * 7, 6, -10 + math.sin(angle) * 7),
			Vector3.new(15, 10, -10),
			0.8,
			felt
		)
	end
	for _, x in { -12, -4, 4 } do
		post(model, "HorseTetherStake", x, 14, 2.5, wood)
	end
	part(model, "TravelTackChest", Vector3.new(5, 2.2, 3), 15, 2.1, 2, darkWood)
	trough(model, "SteppeFeedRack", -4, -10, 10, 1)
end
function designs.vikings(model)
	for _, side in { -1, 1 } do
		for index = 0, 5 do
			local z = -13 + index * 4
			local x = side * (10 + 2 * math.sin(index * math.pi / 5))
			part(model, "CurvedBearHallPlanks", Vector3.new(0.8, 7, 4.3), x, 4.5, z, darkWood, Enum.Material.WoodPlanks)
		end
	end
	roof(model, "BearHallTurfRoof", 0, -3, 29, 31, 8.5, 7, Color3.fromRGB(97, 108, 60), Enum.Material.Grass)
	for _, side in { -1, 1 } do
		post(model, "HeavyBearGatePost", side * 7, 14, 7, wood, 1.6)
	end
	for _, y in { 3, 5 } do
		part(model, "BearGateCrossbar", Vector3.new(15, 1.1, 1.2), 0, y, 14, wood)
	end
	diagonal(model, "BearExerciseLog", Vector3.new(15, 2, -8), Vector3.new(18, 4, 8), 2.2, wood)
	part(model, "BearSleepingStone", Vector3.new(8, 1.2, 6), 0, 1.6, -10, stone, Enum.Material.Rock)
end
function designs.persia(model)
	local mud = Color3.fromRGB(177, 145, 100)
	for _, x in { -20, 20 } do
		part(model, "GardenMudbrickWall", Vector3.new(1.3, 7, 33), x, 4.5, -1, mud, Enum.Material.Ground)
	end
	part(model, "GardenRearWall", Vector3.new(40, 7, 1.3), 0, 4.5, -17, mud, Enum.Material.Ground)
	for _, x in { -16, -5, 6, 17 } do
		part(model, "GardenButtress", Vector3.new(2, 8, 2), x, 5, -16, mud, Enum.Material.Ground)
	end
	flatShelter(model, "LeopardShadeTerrace", 0, -10, 29, 12, 9, mud)
	for _, x in { -12, 12 } do
		rail(model, "LeopardClimbingBay", x, 7, 14, 13, 6, iron, false)
		post(model, "LeopardPerchPost", x, 6, 5, wood, 1.5)
		part(model, "LeopardRestPerch", Vector3.new(6, 0.8, 4), x, 6.4, 6, wood)
	end
	part(
		model,
		"GardenWaterChannel",
		Vector3.new(2, 0.2, 27),
		0,
		1.12,
		0,
		Color3.fromRGB(75, 136, 143),
		Enum.Material.Glass
	)
end
function designs.japan(model)
	local white = Color3.fromRGB(226, 219, 196)
	for _, side in { -1, 1 } do
		part(model, "TigerCompoundPlasterWall", Vector3.new(1, 6, 31), side * 20, 4, -1, white, Enum.Material.Plaster)
		post(model, "DojoGatePost", side * 9, 14, 8, darkWood, 1.2)
	end
	part(model, "DojoGateLintel", Vector3.new(22, 1.3, 2), 0, 9.5, 14, darkWood)
	roof(model, "DojoGateTileRoof", 0, 14, 25, 7, 10, 3, iron)
	for _, x in { -14, 0, 14 } do
		post(model, "DojoRearTimber", x, -11, 9, darkWood)
	end
	roof(model, "TigerDojoMainRoof", 0, -10, 37, 15, 10, 5, iron)
	rail(model, "TigerTimberRun", 0, 2, 31, 15, 5, wood, false)
	diagonal(model, "TigerClimbingBeam", Vector3.new(-9, 2, -1), Vector3.new(9, 5, 5), 1.4, wood)
	part(model, "TigerBanner", Vector3.new(0.25, 6, 3), -16, 8, 12, Color3.fromRGB(155, 51, 47), Enum.Material.Fabric)
end
function designs.maurya(model)
	for _, x in { -16, 0, 16 } do
		post(model, "ElephantCanopyPillar", x, -10, 13, wood, 1.7)
		part(model, "ElephantStonePillarFoot", Vector3.new(3, 1.4, 3), x, 1.7, -10, stone, Enum.Material.Sandstone)
	end
	roof(model, "ElephantThatchCanopy", 0, -8, 43, 18, 14, 5, straw, Enum.Material.Grass)
	for _, x in { -20, 20 } do
		post(model, "ElephantEntryPost", x, 10, 10, wood, 2)
	end
	for _, side in { -1, 1 } do
		part(model, "ElephantHeavySideRail", Vector3.new(1.5, 1.5, 29), side * 20, 5, 0, wood)
	end
	part(model, "ElephantWallow", Vector3.new(20, 0.2, 13), 0, 1.12, 7, Color3.fromRGB(111, 96, 64), Enum.Material.Mud)
	trough(model, "ElephantRaisedFeedingRack", 0, -12, 13, 2.5)
	part(model, "MahoutTimberPlatform", Vector3.new(7, 1, 6), 15, 5, 7, wood)
end
function designs.spain(model)
	local white = Color3.fromRGB(224, 207, 174)
	part(model, "StablePlasterWing", Vector3.new(13, 7, 29), -15, 4.5, -2, white, Enum.Material.Plaster)
	roof(model, "ToroStableTileRoof", -15, -2, 16, 32, 8, 4, clay)
	ovalFence(model, "ToroOctagonalWarPen", 6, 1, 14, 14, 5, darkWood, 8)
	for _, z in { -10, 1, 12 } do
		part(model, "IronBullGateRail", Vector3.new(1, 0.8, 8), -7, 3.7, z, iron, Enum.Material.Metal)
	end
	for _, x in { 2, 10 } do
		post(model, "BullRubbingPost", x, 3, 4, wood, 1.6)
	end
	trough(model, "BullFeedTrough", 6, -10, 8, 1.2)
end
function designs.egypt(model)
	local mud = Color3.fromRGB(181, 143, 94)
	for _, side in { -1, 1 } do
		part(model, "NilePoolMudbrickBank", Vector3.new(3, 3, 31), side * 19, 2.5, 0, mud, Enum.Material.Ground)
	end
	part(model, "NilePoolRearBank", Vector3.new(38, 3, 3), 0, 2.5, -15, mud, Enum.Material.Ground)
	part(
		model,
		"CrocodileWarPool",
		Vector3.new(31, 0.3, 23),
		0,
		1.2,
		-1,
		Color3.fromRGB(65, 137, 145),
		Enum.Material.Glass
	)
	for index = 0, 3 do
		part(
			model,
			"CrocodileBaskingSteps",
			Vector3.new(25, 0.6, 2),
			0,
			1.3 + index * 0.45,
			13 - index * 2,
			mud,
			Enum.Material.Sandstone
		)
	end
	flatShelter(model, "ReedPoolShade", 0, -12, 32, 10, 7, straw)
	for _, x in { -15, 15 } do
		part(model, "PoolReedScreen", Vector3.new(0.7, 4, 13), x, 3, 0, straw, Enum.Material.Grass)
		part(model, "TurquoiseGateBand", Vector3.new(3.1, 0.6, 3.1), x, 4.3, 14, Color3.fromRGB(55, 148, 153))
	end
end
function designs.rome(model)
	local brick = Color3.fromRGB(166, 108, 76)
	part(model, "WolfDenRearBrickWall", Vector3.new(40, 8, 1.4), 0, 5, -15, brick, Enum.Material.Brick)
	roof(model, "WolfDenTerracottaRoof", 0, -10, 42, 15, 9, 4, clay)
	for _, x in { -13, 0, 13 } do
		arch(model, "RomanWolfRunArch", x, -3, 9, 7, brick)
		part(model, "WolfSleepingPlatform", Vector3.new(8, 0.8, 7), x, 1.4, -10, stone, Enum.Material.Limestone)
	end
	rail(model, "WolfExerciseCourt", 0, 7, 38, 14, 4, iron, false)
	part(model, "WolfRaisedLookout", Vector3.new(7, 1.3, 5), 0, 1.65, 7, stone, Enum.Material.Limestone)
end
function designs.ottomans(model)
	local pale = Color3.fromRGB(188, 174, 146)
	part(model, "CamelCourtRearMasonry", Vector3.new(40, 8, 1.3), 0, 5, -15, pale, Enum.Material.Limestone)
	for _, x in { -13, 0, 13 } do
		arch(model, "CamelCourtArcade", x, -5, 10, 8, pale)
	end
	roof(model, "CamelCourtLowTileRoof", 0, -11, 42, 15, 10, 3.5, clay)
	for _, side in { -1, 1 } do
		part(model, "CamelCourtSideWall", Vector3.new(1, 5, 27), side * 20, 3.5, 0, pale, Enum.Material.Limestone)
		post(model, "TallCamelTetherPost", side * 12, 9, 5, wood, 1)
	end
	part(
		model,
		"CamelKneelingMat",
		Vector3.new(19, 0.2, 11),
		0,
		1.15,
		5,
		Color3.fromRGB(97, 126, 95),
		Enum.Material.Fabric
	)
	trough(model, "CamelRaisedManger", 0, -11, 11, 2)
end
function designs.ming(model)
	local red = Color3.fromRGB(153, 51, 39)
	for _, x in { -17, 0, 17 } do
		for _, z in { -13, -3 } do
			post(model, "RhinoPavilionRedPillar", x, z, 11, red, 1.2)
		end
	end
	roof(model, "RhinoPavilionGreyRoof", 0, -8, 44, 20, 12, 5, iron, Enum.Material.Slate)
	for _, side in { -1, 1 } do
		part(
			model,
			"UpturnedPavilionEave",
			Vector3.new(5, 0.65, 20),
			side * 21,
			13,
			-8,
			iron,
			Enum.Material.Slate,
			CFrame.Angles(0, 0, side * 0.25)
		)
		part(model, "RhinoWhiteCourtWall", Vector3.new(1.2, 5, 28), side * 21, 3.5, 2, plaster, Enum.Material.Plaster)
	end
	part(model, "RhinoWallow", Vector3.new(23, 0.2, 13), 0, 1.12, 7, Color3.fromRGB(103, 94, 70), Enum.Material.Mud)
	for _, x in { -8, 8 } do
		post(model, "RhinoRubbingTimber", x, 8, 4.5, darkWood, 2)
	end
	part(model, "HeavyRhinoGateBeam", Vector3.new(36, 1.4, 1.4), 0, 5.6, 16, red)
end
function MountStructures.create(civilizationId: string): Model
	local design = designs[civilizationId]
	assert(design, "Unknown mounted structure civilization")
	local mount = MountConfig.get(civilizationId)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = "mount", CFrame.identity
	local footing = part(model, "MountFacilityFooting", Vector3.new(48, 1, 40), 0, 0.5, 0, earth, Enum.Material.Ground)
	footing.CanQuery = true
	footing:SetAttribute("OriginalTroopSupport", true)
	design(model)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", civilizationId)
	model:SetAttribute("Kind", "mount")
	model:SetAttribute("MountStructure", true)
	model:SetAttribute("MountAnimal", mount.animal)
	model:SetAttribute("DisplayName", mount.structureName)
	model:SetAttribute("EvidenceCard", "docs/notes/" .. cards[civilizationId] .. " Sandbox Art.md")
	model:SetAttribute(
		"EvidenceScope",
		"Original fantasy animal facility; architecture follows existing civilization kit references, not an excavated animal institution"
	)
	local periods = {
		egypt = "New Kingdom · 1300–1200 BCE",
		mongols = "Mongol Empire · 1206–1260 CE",
		vikings = "Southern Scandinavia · 900–1050 CE",
		ottomans = "Ottoman Empire · 1520–1566 CE",
	}
	if periods[civilizationId] then
		model:SetAttribute("HistoricalPeriod", periods[civilizationId])
	end
	model:SetAttribute("GameInterpretation", true)
	return model
end
return table.freeze(MountStructures)

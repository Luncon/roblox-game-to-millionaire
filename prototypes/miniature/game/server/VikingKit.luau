--!strict
-- Denmark / southern Scandinavian Viking-Age vocabulary; original game geometry.
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local VikingKit = {}
local colors = {
	wood = Color3.fromRGB(105, 73, 45),
	plank = Color3.fromRGB(137, 103, 66),
	thatch = Color3.fromRGB(152, 134, 83),
	daub = Color3.fromRGB(171, 159, 126),
	stone = Color3.fromRGB(112, 113, 99),
	soil = Color3.fromRGB(91, 73, 48),
	clay = Color3.fromRGB(132, 93, 64),
	grain = Color3.fromRGB(185, 161, 77),
	cloth = Color3.fromRGB(197, 188, 157),
	iron = Color3.fromRGB(94, 98, 94),
	shadow = Color3.fromRGB(42, 41, 34),
}
local function part(model, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(position)
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, model
	return object
end
local function roof(model, xCenter, zCenter, length, depth, wallTop)
	local angle = math.rad(34)
	for section = -2, 2 do
		local x = section * length / 5
		local half = depth / 2 * (0.82 + 0.18 * math.cos(math.pi * x / length)) + 0.45
		local rise = half * math.tan(angle)
		for _, side in { -1, 1 } do
			local slab = part(
				model,
				"ThatchRoofSection",
				Vector3.new(length / 5 + 0.16, 0.8, half / math.cos(angle)),
				Vector3.new(xCenter + x, wallTop + rise / 2, zCenter + side * half / 2),
				colors.thatch,
				Enum.Material.Grass
			)
			slab.CFrame *= CFrame.Angles(side * angle, 0, 0)
		end
		part(
			model,
			"ThatchedRidgeBinding",
			Vector3.new(length / 5 + 0.2, 0.5, 0.65),
			Vector3.new(xCenter + x, wallTop + rise, zCenter),
			colors.wood,
			Enum.Material.Wood
		)
	end
end
local function longhall(model, xCenter, zCenter, length, depth, height)
	part(
		model,
		"HallPlankFloor",
		Vector3.new(length, 0.5, depth),
		Vector3.new(xCenter, 1.25, zCenter),
		colors.plank,
		Enum.Material.WoodPlanks
	)
	for index = -4, 4 do
		local x = index * length / 9
		local half = depth / 2 * (0.8 + 0.2 * math.cos(math.pi * x / length))
		local slope = -depth * 0.1 * math.pi / length * math.sin(math.pi * x / length)
		for _, side in { -1, 1 } do
			local wall = part(
				model,
				"CurvedTimberLongwall",
				Vector3.new(length / 9 + 0.15, height, 0.65),
				Vector3.new(xCenter + x, 1.5 + height / 2, zCenter + side * half),
				colors.plank,
				Enum.Material.WoodPlanks
			)
			wall.CFrame *= CFrame.Angles(0, -side * math.atan(slope), 0)
			part(
				model,
				"WallUpright",
				Vector3.new(0.5, height + 0.4, 0.7),
				Vector3.new(xCenter + x, 1.6 + height / 2, zCenter + side * half),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
	for _, side in { -1, 1 } do
		part(
			model,
			"StraightGableEnd",
			Vector3.new(0.7, height, depth * 0.8),
			Vector3.new(xCenter + side * length / 2, 1.5 + height / 2, zCenter),
			colors.plank,
			Enum.Material.WoodPlanks
		)
		for _, index in { -1, 0, 1 } do
			local x = index * length / 3
			local half = depth / 2 * (0.8 + 0.2 * math.cos(math.pi * x / length))
			local support = part(
				model,
				"SlopingRoofSupport",
				Vector3.new(0.65, height + 0.9, 0.65),
				Vector3.new(xCenter + x, 1.4 + height / 2, zCenter + side * (half + 0.7)),
				colors.wood,
				Enum.Material.Wood
			)
			support.CFrame *= CFrame.Angles(-side * 0.17, 0, 0)
		end
	end
	part(
		model,
		"LongwallDoor",
		Vector3.new(2.7, height * 0.76, 0.18),
		Vector3.new(xCenter, 1.5 + height * 0.38, zCenter + depth / 2 + 0.36),
		colors.shadow
	)
	roof(model, xCenter, zCenter, length + 0.6, depth + 0.2, height + 1.7)
	part(
		model,
		"RoofSmokeOpeningCue",
		Vector3.new(2.8, 0.12, 1.25),
		Vector3.new(xCenter, height + 1.85 + ((depth + 0.2) / 2 + 0.45) * math.tan(math.rad(34)), zCenter),
		colors.shadow
	)
end
local function shed(model, x, z, length, depth, height)
	part(
		model,
		"CraftDaubRearWall",
		Vector3.new(length, height, 0.65),
		Vector3.new(x, 1 + height / 2, z - depth / 2),
		colors.daub,
		Enum.Material.Plaster
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"ShedTimberPost",
			Vector3.new(0.7, height, 0.7),
			Vector3.new(x + side * (length / 2 - 0.5), 1 + height / 2, z + depth / 2 - 0.5),
			colors.wood,
			Enum.Material.Wood
		)
	end
	roof(model, x, z, length, depth, height + 1)
end
local function pot(model, x, z, scale)
	local vessel = part(
		model,
		"HandFormedClayPot",
		Vector3.new(2.4, 2.5, 2.4) * scale,
		Vector3.new(x, 1 + 1.25 * scale, z),
		colors.clay
	)
	vessel.Shape = Enum.PartType.Ball
	local rim = part(
		model,
		"PotMouth",
		Vector3.new(0.15, 1.25, 1.25) * scale,
		Vector3.new(x, 1 + 2.45 * scale, z),
		colors.shadow
	)
	rim.Shape = Enum.PartType.Cylinder
	rim.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end
local function fence(model, width, depth, zOffset)
	for _, side in { -1, 1 } do
		part(
			model,
			"LowTimberYardFence",
			Vector3.new(0.6, 2.3, depth),
			Vector3.new(side * (width / 2 - 1), 2.15, zOffset),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"FenceRearRail",
			Vector3.new(width / 2 - 2, 0.45, 0.5),
			Vector3.new(side * width / 4, 2.6, zOffset - depth / 2),
			colors.plank,
			Enum.Material.Wood
		)
	end
end
local builders = {}
function builders.house(model, width, depth)
	longhall(model, 0, -depth * 0.13, width * 0.78, depth * 0.46, 6.2)
	part(
		model,
		"DomesticWoodChest",
		Vector3.new(4.5, 2.2, 2.6),
		Vector3.new(-width * 0.28, 2.1, depth * 0.32),
		colors.plank,
		Enum.Material.WoodPlanks
	)
	pot(model, width * 0.28, depth * 0.31, 0.7)
end
function builders.civic(model, width, depth)
	longhall(model, 0, -depth * 0.16, width * 0.84, depth * 0.45, 8)
	part(
		model,
		"HallEntranceWalk",
		Vector3.new(5, 0.35, 7),
		Vector3.new(0, 1.2, depth * 0.22),
		colors.plank,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"ExchangeBoardCounter",
		Vector3.new(12, 2.5, 3),
		Vector3.new(0, 2.25, depth * 0.35),
		colors.plank,
		Enum.Material.Wood
	)
	for _, x in { -7.5, 7.5 } do
		part(
			model,
			"TradingBoothPost",
			Vector3.new(0.65, 5.7, 0.65),
			Vector3.new(x, 3.85, depth * 0.35),
			colors.wood,
			Enum.Material.Wood
		)
	end
	part(
		model,
		"TradingBoothCloth",
		Vector3.new(16, 0.35, 5),
		Vector3.new(0, 6.7, depth * 0.35),
		colors.cloth,
		Enum.Material.Fabric
	)
end
function builders.farm(model, width, depth)
	fence(model, width - 1, depth - 3, 0)
	part(
		model,
		"CultivatedGrainBed",
		Vector3.new(width - 6, 0.4, depth - 6),
		Vector3.new(0, 1.2, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for row = -2, 2 do
		for column = -3, 3 do
			local x, z = column * (width - 8) / 8, row * (depth - 8) / 6
			part(model, "CerealStalk", Vector3.new(0.25, 2.1, 0.25), Vector3.new(x, 2.4, z), colors.grain)
			part(model, "CerealEar", Vector3.new(0.55, 0.75, 0.5), Vector3.new(x, 3.5, z), colors.grain)
		end
	end
	part(
		model,
		"HarvestBundle",
		Vector3.new(3.2, 2.2, 2.5),
		Vector3.new(width * 0.32, 2.1, depth * 0.33),
		colors.thatch,
		Enum.Material.Grass
	)
end
function builders.timber(model, width, depth)
	shed(model, -7, -3, 12, 9, 5)
	part(model, "CarvingBench", Vector3.new(8, 2.5, 3), Vector3.new(-7, 2.25, -1), colors.plank, Enum.Material.Wood)
	for tier = 0, 1 do
		for row = -1, 1 do
			local log = part(
				model,
				"FelledTimber",
				Vector3.new(11, 1.7, 1.7),
				Vector3.new(width * 0.23, 1.85 + tier * 1.6, row * 2.2),
				colors.wood,
				Enum.Material.Wood
			)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	local block = part(
		model,
		"AxeChoppingBlock",
		Vector3.new(3.5, 2, 3.5),
		Vector3.new(-7, 2, depth * 0.34),
		colors.plank,
		Enum.Material.Wood
	)
	block.Shape = Enum.PartType.Cylinder
	block.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end
function builders.material(model, width, depth)
	part(
		model,
		"ClayGatheringBed",
		Vector3.new(width * 0.6, 0.45, depth * 0.55),
		Vector3.new(-2, 1.15, -1),
		colors.clay,
		Enum.Material.Mud
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"EarthBank",
			Vector3.new(width * 0.7, 1.1, 1.8),
			Vector3.new(-1, 1.55, side * depth * 0.32),
			colors.soil,
			Enum.Material.Ground
		)
	end
	part(
		model,
		"GatheringBasket",
		Vector3.new(3.6, 1.8, 3),
		Vector3.new(width * 0.32, 1.9, depth * 0.25),
		colors.thatch,
		Enum.Material.Fabric
	)
	pot(model, -width * 0.31, depth * 0.32, 0.65)
end
function builders.workshop(model, _width, depth)
	shed(model, -7, -2, 12, 10, 5.5)
	part(
		model,
		"PotterWorkingBoard",
		Vector3.new(8, 2, 3),
		Vector3.new(-7, 2, 0),
		colors.plank,
		Enum.Material.WoodPlanks
	)
	local hearth = part(
		model,
		"PotteryFiringBed",
		Vector3.new(7, 0.4, 7),
		Vector3.new(7, 1.2, -2),
		colors.shadow,
		Enum.Material.Slate
	)
	hearth.Shape = Enum.PartType.Cylinder
	hearth.Size = Vector3.new(0.4, 7, 7)
	hearth.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	for index = 0, 5 do
		local angle = index * math.pi / 3
		part(
			model,
			"LowFiringStone",
			Vector3.new(1.3, 1, 1.2),
			Vector3.new(7 + math.cos(angle) * 3, 1.5, -2 + math.sin(angle) * 3),
			colors.stone,
			Enum.Material.Slate
		)
	end
	for _, x in { -10, -6, 5, 9 } do
		pot(model, x, depth * 0.3, 0.75)
	end
end
function builders.storehouse(model, width, depth)
	for _, x in { -8, 8 } do
		for _, z in { -6, 3 } do
			part(
				model,
				"LowStorageFooting",
				Vector3.new(2.5, 1.4, 2.5),
				Vector3.new(x, 1.7, z),
				colors.stone,
				Enum.Material.Slate
			)
		end
	end
	part(
		model,
		"RaisedStoreFloor",
		Vector3.new(width * 0.7, 0.65, depth * 0.54),
		Vector3.new(0, 2.5, -2),
		colors.plank,
		Enum.Material.WoodPlanks
	)
	shed(model, 0, -2, width * 0.72, depth * 0.56, 7)
	for _, x in { -7, 0, 7 } do
		part(
			model,
			"GrainStorageChest",
			Vector3.new(4, 2.6, 3.5),
			Vector3.new(x, 4.1, -2),
			colors.wood,
			Enum.Material.WoodPlanks
		)
	end
end
function builders.training(model, width, depth)
	fence(model, width - 1, depth - 3, 0)
	part(
		model,
		"PracticeEarth",
		Vector3.new(width - 5, 0.2, depth - 5),
		Vector3.new(0, 1.1, 0),
		colors.soil,
		Enum.Material.Ground
	)
	for _, x in { -10, 0, 10 } do
		part(
			model,
			"ShieldPracticePost",
			Vector3.new(0.7, 5, 0.7),
			Vector3.new(x, 3.5, -3),
			colors.wood,
			Enum.Material.Wood
		)
		local shield = part(
			model,
			"RoundPracticeShield",
			Vector3.new(0.25, 3.8, 3.8),
			Vector3.new(x, 4.4, -3.5),
			colors.plank,
			Enum.Material.WoodPlanks
		)
		shield.Shape = Enum.PartType.Cylinder
		shield.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
	end
	shed(model, 0, depth * 0.3, 15, 7, 4)
end
function builders.healer(model, width, depth)
	longhall(model, 0, -depth * 0.2, width * 0.7, depth * 0.4, 5)
	part(
		model,
		"TreatmentBench",
		Vector3.new(5, 1.6, 6),
		Vector3.new(-2, 1.8, depth * 0.26),
		colors.plank,
		Enum.Material.Wood
	)
	part(
		model,
		"LinenCouchCover",
		Vector3.new(4.8, 0.25, 5.8),
		Vector3.new(-2, 2.75, depth * 0.26),
		colors.cloth,
		Enum.Material.Fabric
	)
	part(
		model,
		"FoldedTreatmentCloth",
		Vector3.new(1.8, 0.4, 1.6),
		Vector3.new(-2, 3, depth * 0.2),
		colors.cloth,
		Enum.Material.Fabric
	)
	pot(model, width * 0.3, depth * 0.3, 0.65)
end
function VikingKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end
function VikingKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("vikings")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Viking building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"EarthFooting",
		Vector3.new(width, 0.8, depth),
		Vector3.new(0, 0.4, 0),
		colors.soil,
		Enum.Material.Ground
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "vikings")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("HistoricalPeriod", "Southern Scandinavia · 900–1050 CE")
	model:SetAttribute("EvidenceCard", "docs/notes/Viking Sandbox Art.md")
	return model
end
function VikingKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Viking presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin = Color3.fromRGB(240, 210, 190)
	local wool = if role == "melee"
		then Color3.fromRGB(122, 78, 52)
		elseif role == "ranged" then Color3.fromRGB(107, 112, 76)
		else Color3.fromRGB(163, 150, 112)
	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor3, bodyColors.TorsoColor3 = skin, skin
	bodyColors.LeftArmColor3, bodyColors.RightArmColor3 = skin, skin
	bodyColors.LeftLegColor3, bodyColors.RightLegColor3 = skin, skin
	bodyColors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "WoolTunic", Vector3.new(1.97, 2.05, 1.06), Vector3.new(0, 3.1, 0), wool, Enum.Material.Fabric)
	part(model, "TunicSkirt", Vector3.new(2.1, 1.15, 1.2), Vector3.new(0, 2.1, 0), wool, Enum.Material.Fabric)
	part(
		model,
		"LeatherBelt",
		Vector3.new(2.12, 0.18, 1.22),
		Vector3.new(0, 2.65, 0),
		colors.wood,
		Enum.Material.Leather
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
			wool,
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
			Vector3.new(0.9, 0.65, 1.1),
			Vector3.new(side * 0.5, 0.325, -0.08),
			colors.shadow,
			Enum.Material.Leather
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	part(model, "KeptHair", Vector3.new(1.45, 0.5, 1.35), Vector3.new(0, 5.22, 0.05), colors.wood)
	if role == "melee" then
		local helmet = part(
			model,
			"PlainIronHelmet",
			Vector3.new(1.65, 0.8, 1.5),
			Vector3.new(0, 5.3, 0),
			colors.iron,
			Enum.Material.Metal
		)
		helmet.Shape = Enum.PartType.Ball
		part(
			model,
			"HelmetNoseGuard",
			Vector3.new(0.13, 0.7, 0.18),
			Vector3.new(0, 4.92, -0.78),
			colors.iron,
			Enum.Material.Metal
		)
		part(
			model,
			"AxeHaft",
			Vector3.new(0.16, 3.7, 0.16),
			Vector3.new(1.5, 2.8, -0.35),
			colors.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"IronAxeBlade",
			Vector3.new(1, 0.7, 0.2),
			Vector3.new(1.88, 4.2, -0.35),
			colors.iron,
			Enum.Material.Metal
		)
		part(
			model,
			"AxeBeard",
			Vector3.new(0.5, 0.45, 0.2),
			Vector3.new(2.13, 3.85, -0.35),
			colors.iron,
			Enum.Material.Metal
		)
		local shield = part(
			model,
			"RoundWoodShield",
			Vector3.new(0.22, 2.9, 2.9),
			Vector3.new(-1.45, 3, -0.7),
			colors.plank,
			Enum.Material.WoodPlanks
		)
		shield.Shape = Enum.PartType.Cylinder
		shield.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
		local boss = part(
			model,
			"IronShieldBoss",
			Vector3.new(0.7, 0.7, 0.3),
			Vector3.new(-1.45, 3, -0.9),
			colors.iron,
			Enum.Material.Metal
		)
		boss.Shape = Enum.PartType.Ball
	elseif role == "ranged" then
		for _, side in { -1, 1 } do
			local limb = part(
				model,
				"SelfBowLimb",
				Vector3.new(0.12, 2, 0.15),
				Vector3.new(1.48, 3 + side * 0.85, -0.4),
				colors.wood,
				Enum.Material.Wood
			)
			limb.CFrame *= CFrame.Angles(0, 0, side * 0.22)
		end
		part(
			model,
			"BowString",
			Vector3.new(0.035, 3.8, 0.035),
			Vector3.new(1.68, 3, -0.4),
			colors.cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"ArrowQuiver",
			Vector3.new(0.65, 2.1, 0.6),
			Vector3.new(-1, 3.2, 0.65),
			colors.wood,
			Enum.Material.Leather
		)
		for index = 0, 2 do
			part(
				model,
				"ArrowShaft",
				Vector3.new(0.06, 1.25, 0.06),
				Vector3.new(-1.18 + index * 0.18, 4.25, 0.65),
				colors.plank,
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
			colors.cloth,
			Enum.Material.Fabric
		)
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "vikings")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Viking Sandbox Art.md")
	return model
end
return VikingKit

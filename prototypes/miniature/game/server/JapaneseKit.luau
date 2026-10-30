--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local ArcheryRanges = require(script.Parent.ArcheryRanges)
local JapaneseKit = {}
local palette = {
	wood = Color3.fromRGB(99, 75, 51),
	board = Color3.fromRGB(140, 113, 77),
	plaster = Color3.fromRGB(219, 212, 189),
	shingle = Color3.fromRGB(103, 105, 94),
	tile = Color3.fromRGB(65, 73, 72),
	stone = Color3.fromRGB(137, 141, 123),
	soil = Color3.fromRGB(115, 92, 60),
	dark = Color3.fromRGB(40, 43, 37),
	clay = Color3.fromRGB(153, 112, 73),
	straw = Color3.fromRGB(184, 164, 98),
}

local function part(model, name, size, point, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, CFrame.new(point)
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.Color, object.Material = color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = model
	return object
end

local function cylinder(model, name, diameter, height, point, color, material)
	local object = part(model, name, Vector3.new(height, diameter, diameter), point, color, material)
	object.Shape = Enum.PartType.Cylinder
	object.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	return object
end

local function roof(model, frame, width, depth, eaves, rise, tiled)
	local half = width / 2 - 0.6
	local angle = math.atan(rise / half)
	local color = if tiled then palette.tile else palette.shingle
	local material = if tiled then Enum.Material.ClayRoofTiles else Enum.Material.WoodPlanks
	for _, side in { -1, 1 } do
		local slope = part(
			model,
			if tiled then "KeepTileSlope" else "SplitPanelShingles",
			Vector3.new(half / math.cos(angle), 0.55, depth),
			Vector3.zero,
			color,
			material
		)
		slope.CFrame = frame * CFrame.new(side * half / 2, eaves + rise / 2, 0) * CFrame.Angles(0, 0, -side * angle)
		if not tiled then
			local retainer = part(
				model,
				"RoofRetainingPole",
				Vector3.new(0.2, 0.2, depth - 1),
				Vector3.zero,
				palette.wood,
				Enum.Material.Wood
			)
			retainer.CFrame = frame * CFrame.new(side * half * 0.6, eaves + rise * 0.4 + 0.45, 0)
			for _, z in { -depth * 0.28, 0, depth * 0.28 } do
				local weight = part(
					model,
					"RoofRetainingStone",
					Vector3.new(1.5, 0.6, 1),
					Vector3.zero,
					palette.stone,
					Enum.Material.Rock
				)
				weight.CFrame = frame * CFrame.new(side * half * 0.6, eaves + rise * 0.4 + 0.7, z)
			end
		end
	end
	local ridge = part(
		model,
		if tiled then "KeepTileRidge" else "TimberRidge",
		Vector3.new(0.7, 0.7, depth),
		Vector3.zero,
		color,
		material
	)
	ridge.CFrame = frame * CFrame.new(0, eaves + rise, 0)
end

local function framedRoom(model, x, z, width, depth, bottom, height)
	part(
		model,
		"MudPlasterRoom",
		Vector3.new(width, height, depth),
		Vector3.new(x, bottom + height / 2, z),
		palette.plaster,
		Enum.Material.Plaster
	)
	for _, side in { -1, 1 } do
		for _, endZ in { -1, 1 } do
			part(
				model,
				"SquareTimberPost",
				Vector3.new(0.75, height + 0.3, 0.75),
				Vector3.new(x + side * (width / 2 - 0.2), bottom + height / 2, z + endZ * (depth / 2 - 0.2)),
				palette.wood,
				Enum.Material.Wood
			)
		end
		part(
			model,
			"HorizontalFrameRail",
			Vector3.new(width, 0.55, 0.3),
			Vector3.new(x, bottom + height * 0.55, z + side * (depth / 2 + 0.1)),
			palette.wood,
			Enum.Material.Wood
		)
	end
end

local function door(model, x, z, bottom, width, height)
	part(
		model,
		"SlidingTimberDoor",
		Vector3.new(width, height, 0.2),
		Vector3.new(x, bottom + height / 2, z),
		palette.dark,
		Enum.Material.Wood
	)
	for index = -2, 2 do
		part(
			model,
			"DoorLattice",
			Vector3.new(0.12, height, 0.18),
			Vector3.new(x + index * width / 5, bottom + height / 2, z + 0.15),
			palette.board,
			Enum.Material.Wood
		)
	end
end

local function jar(model, x, z, size, bottom)
	local object = part(
		model,
		"EchizenStorageJar",
		Vector3.new(size, size * 1.3, size),
		Vector3.new(x, bottom + size * 0.65, z),
		palette.clay,
		Enum.Material.SmoothPlastic
	)
	object.Shape = Enum.PartType.Ball
	cylinder(model, "JarMouth", size * 0.55, 0.2, Vector3.new(x, bottom + size * 1.27, z), palette.dark)
end

local builders = {}

function builders.civic(model, width, depth)
	for tier = 0, 2 do
		part(
			model,
			"SteppedStoneBase",
			Vector3.new(width * 0.65 - tier * 2, 1.4, 22 - tier * 2),
			Vector3.new(0, 1.7 + tier * 1.3, -3),
			palette.stone,
			Enum.Material.Rock
		)
	end
	part(
		model,
		"KeepLowerStorey",
		Vector3.new(20, 9, 16),
		Vector3.new(0, 9.5, -3),
		palette.dark,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"KeepPlasterBand",
		Vector3.new(20.1, 2, 16.1),
		Vector3.new(0, 12.5, -3),
		palette.plaster,
		Enum.Material.Plaster
	)
	roof(model, CFrame.new(0, 0, -3), 26, 22, 14.2, 3.2, true)
	part(
		model,
		"KeepUpperStorey",
		Vector3.new(12, 7, 10),
		Vector3.new(0, 17.5, -3),
		palette.plaster,
		Enum.Material.Plaster
	)
	roof(model, CFrame.new(0, 0, -3), 16, 14, 21.3, 2.6, true)
	for _, x in { -5, 0, 5 } do
		part(model, "KeepLowerWindow", Vector3.new(1.5, 2.6, 0.18), Vector3.new(x, 10, 5.1), palette.dark)
	end
	for _, x in { -3, 3 } do
		part(model, "KeepUpperWindow", Vector3.new(1.4, 2.5, 0.18), Vector3.new(x, 18, 2.1), palette.dark)
	end
	part(
		model,
		"MarketCounter",
		Vector3.new(13, 2.5, 3),
		Vector3.new(0, 2.25, depth * 0.38),
		palette.board,
		Enum.Material.Wood
	)
	for _, x in { -7, 7 } do
		part(
			model,
			"MarketAwningPost",
			Vector3.new(0.6, 5, 0.6),
			Vector3.new(x, 3.5, depth * 0.38),
			palette.wood,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.new(0, 0, depth * 0.38), 16, 5, 6.2, 1, false)
	jar(model, -3, depth * 0.38, 1.4, 3.6)
end

function builders.house(model, width, depth)
	part(
		model,
		"RaisedHouseFloor",
		Vector3.new(16, 1, 20),
		Vector3.new(-2, 1.5, 0),
		palette.board,
		Enum.Material.WoodPlanks
	)
	framedRoom(model, -2, 0, 15, 19, 2, 7)
	door(model, -2, 9.65, 2, 5, 5)
	roof(model, CFrame.new(-2, 0, 0), 19, 23, 9.2, 4.2, false)
	for _, z in { -10, 10 } do
		part(
			model,
			"GableRidgePost",
			Vector3.new(0.65, 11.4, 0.65),
			Vector3.new(-2, 7.7, z),
			palette.wood,
			Enum.Material.Wood
		)
	end
	cylinder(model, "BentwoodTub", 2.7, 2.3, Vector3.new(width * 0.34, 2.15, -5), palette.board, Enum.Material.Wood)
	part(
		model,
		"StreetBench",
		Vector3.new(10, 1.5, 1.5),
		Vector3.new(-2, 1.75, depth / 2 - 1),
		palette.board,
		Enum.Material.Wood
	)
end

function builders.farm(model, width, depth)
	part(
		model,
		"PaddySoil",
		Vector3.new(width - 2, 0.7, depth - 2),
		Vector3.new(0, 1.25, 0),
		palette.soil,
		Enum.Material.Ground
	)
	for _, x in { -7, 7 } do
		for _, z in { -7, 7 } do
			local water = part(
				model,
				"ShallowPaddyWater",
				Vector3.new(12, 0.12, 12),
				Vector3.new(x, 1.65, z),
				Color3.fromRGB(117, 138, 119),
				Enum.Material.Glass
			)
			water.Transparency = 0.25
			for _, dx in { -3, 3 } do
				for _, dz in { -3, 3 } do
					for blade = -1, 1 do
						local stalk = part(
							model,
							"RiceClump",
							Vector3.new(0.18, 2.5, 0.25),
							Vector3.new(x + dx + blade * 0.3, 2.9, z + dz),
							Color3.fromRGB(126, 151, 68)
						)
						stalk.CFrame *= CFrame.Angles(0, 0, blade * 0.18)
					end
				end
			end
		end
	end
	for _, x in { -14, 0, 14 } do
		part(
			model,
			"PaddyBerm",
			Vector3.new(0.7, 0.5, depth - 3),
			Vector3.new(x, 1.9, 0),
			palette.soil,
			Enum.Material.Ground
		)
	end
end

function builders.timber(model, width, depth)
	for layer = 0, 2 do
		part(
			model,
			"SplitRoofPanelStack",
			Vector3.new(width * 0.68, 0.65, 5),
			Vector3.new(0, 1.35 + layer * 0.8, -depth * 0.28),
			palette.board,
			Enum.Material.WoodPlanks
		)
	end
	for _, x in { -width * 0.25, width * 0.25 } do
		part(model, "WoodworkingStool", Vector3.new(2, 3, 5), Vector3.new(x, 2.5, 1), palette.wood, Enum.Material.Wood)
	end
	part(
		model,
		"SplittingBeam",
		Vector3.new(width * 0.7, 1.2, 2),
		Vector3.new(0, 4.6, 1),
		palette.board,
		Enum.Material.Wood
	)
	part(model, "WoodPlane", Vector3.new(3, 0.9, 1.2), Vector3.new(1, 5.65, 1), palette.wood, Enum.Material.Wood)
	cylinder(model, "BentwoodSupplyTub", 3.5, 2, Vector3.new(0, 2, depth * 0.31), palette.board, Enum.Material.Wood)
end

function builders.material(model, width, depth)
	part(
		model,
		"HillsideClayBed",
		Vector3.new(width * 0.65, 0.7, depth - 4),
		Vector3.new(-width * 0.09, 1.35, 0),
		palette.clay,
		Enum.Material.Ground
	)
	part(
		model,
		"ClayWeatheringBank",
		Vector3.new(width - 3, 2, 4),
		Vector3.new(0, 2, -depth * 0.32),
		palette.soil,
		Enum.Material.Ground
	)
	for row = -1, 1 do
		part(
			model,
			"PreparedPotteryClay",
			Vector3.new(3, 1.1, 3),
			Vector3.new(width * 0.3, 1.55, row * 4),
			palette.clay,
			Enum.Material.Ground
		)
	end
	cylinder(
		model,
		"ClaySoakingTub",
		4,
		2.3,
		Vector3.new(-width * 0.22, 2.15, depth * 0.28),
		palette.board,
		Enum.Material.Wood
	)
end

function builders.workshop(model, width, depth)
	part(
		model,
		"KilnEarthMound",
		Vector3.new(11, 3, depth - 4),
		Vector3.new(-width * 0.27, 2.5, 0),
		palette.soil,
		Enum.Material.Ground
	)
	local tunnel = part(
		model,
		"SingleChamberTunnelKiln",
		Vector3.new(depth * 0.65, 6, 6),
		Vector3.new(-width * 0.27, 4.6, 0),
		palette.clay,
		Enum.Material.Ground
	)
	tunnel.Shape = Enum.PartType.Cylinder
	tunnel.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
	local mouth = part(
		model,
		"TunnelFireMouth",
		Vector3.new(0.18, 3, 3),
		Vector3.new(-width * 0.27, 3.4, depth * 0.325 + 0.1),
		palette.dark
	)
	mouth.Shape = Enum.PartType.Cylinder
	mouth.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
	framedRoom(model, width * 0.23, -2, width * 0.35, depth * 0.6, 1, 6)
	roof(model, CFrame.new(width * 0.23, 0, -2), width * 0.43, depth * 0.7, 7.2, 2.5, false)
	part(
		model,
		"PotteryWorkBench",
		Vector3.new(width * 0.35, 2, 3),
		Vector3.new(width * 0.23, 2, depth * 0.29),
		palette.board,
		Enum.Material.Wood
	)
	jar(model, width * 0.23, depth * 0.29, 2.4, 3.1)
end

function builders.storehouse(model, width, depth)
	for _, x in { -width * 0.31, width * 0.31 } do
		for _, z in { -depth * 0.28, depth * 0.28 } do
			part(
				model,
				"GranaryLeg",
				Vector3.new(1.5, 2.5, 1.5),
				Vector3.new(x, 2.25, z),
				palette.wood,
				Enum.Material.Wood
			)
		end
	end
	part(
		model,
		"RaisedGranaryFloor",
		Vector3.new(width - 5, 1, depth - 5),
		Vector3.new(0, 3.5, 0),
		palette.board,
		Enum.Material.WoodPlanks
	)
	part(
		model,
		"PlankStoreBlock",
		Vector3.new(width - 7, 7, depth - 7),
		Vector3.new(0, 7.5, 0),
		palette.board,
		Enum.Material.WoodPlanks
	)
	for _, x in { -8, 0, 8 } do
		part(
			model,
			"StoreFrontBatten",
			Vector3.new(0.35, 7, 0.25),
			Vector3.new(x, 7.5, (depth - 7) / 2 + 0.15),
			palette.wood,
			Enum.Material.Wood
		)
	end
	door(model, 0, (depth - 7) / 2 + 0.3, 4, 4, 5)
	roof(model, CFrame.identity, width - 2, depth - 2, 11.2, 3.5, false)
	part(
		model,
		"StoreLoadingStep",
		Vector3.new(5, 1.5, 2),
		Vector3.new(0, 1.75, depth * 0.42),
		palette.board,
		Enum.Material.Wood
	)
end

function builders.training(model, width, depth)
	part(
		model,
		"PracticeCourt",
		Vector3.new(width - 2, 0.2, depth - 2),
		Vector3.new(0, 1.1, 0),
		palette.soil,
		Enum.Material.Ground
	)
	for _, side in { -1, 1 } do
		part(
			model,
			"PracticePaling",
			Vector3.new(0.7, 4, depth - 4),
			Vector3.new(side * (width / 2 - 1), 3, 0),
			palette.board,
			Enum.Material.WoodPlanks
		)
	end
	for _, x in { -12, -4, 4, 12 } do
		local height = 7.2 + 2 * (1 - math.abs(x) / ((width - 4) / 2 - 0.6)) - 1.2
		part(
			model,
			"PracticeRackPost",
			Vector3.new(0.65, height, 0.65),
			Vector3.new(x, 1 + height / 2, -depth * 0.3),
			palette.wood,
			Enum.Material.Wood
		)
		part(
			model,
			"WovenPracticeTarget",
			Vector3.new(3, 3.7, 0.7),
			Vector3.new(x, 3.2, -2.5),
			palette.straw,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.new(0, 0, -depth * 0.3), width - 4, 7, 7.2, 2, false)
	for _, x in { -4, 4 } do
		part(
			model,
			"PracticeGatePost",
			Vector3.new(0.7, 5.8, 0.7),
			Vector3.new(x, 3.9, depth * 0.35),
			palette.wood,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.new(0, 0, depth * 0.35), 12, 5, 6.2, 2, false)
end

function builders.healer(model, width, depth)
	part(
		model,
		"TreatmentFloor",
		Vector3.new(width - 2, 1, depth - 2),
		Vector3.new(0, 1.5, 0),
		palette.board,
		Enum.Material.WoodPlanks
	)
	framedRoom(model, 0, -6, width - 5, 8, 2, 6)
	roof(model, CFrame.new(0, 0, -6), width - 2, 12, 8.2, 2.7, false)
	for _, x in { -8, 8 } do
		part(
			model,
			"TreatmentVerandaPost",
			Vector3.new(0.7, 5.5, 0.7),
			Vector3.new(x, 4.75, 8),
			palette.wood,
			Enum.Material.Wood
		)
	end
	roof(model, CFrame.new(0, 0, 4), width - 3, 12, 7.6, 1.2, false)
	part(model, "PreparationTable", Vector3.new(6, 1.5, 3), Vector3.new(-5, 2.75, 3), palette.board, Enum.Material.Wood)
	cylinder(model, "MedicineMortar", 2.4, 1.3, Vector3.new(-5, 4.15, 3), palette.stone, Enum.Material.Rock)
	part(model, "MedicalBook", Vector3.new(2.7, 0.25, 2), Vector3.new(5, 2.2, 4), palette.board, Enum.Material.Wood)
end

function JapaneseKit.available(kind: string): boolean
	return kind == "ranged" or builders[kind] ~= nil
end

function JapaneseKit.create(kind: string): Model
	if kind == "ranged" then
		return ArcheryRanges.create("japan")
	end
	local definition = Catalog.buildings[kind]
	assert(definition and builders[kind], "Missing Japanese building art: " .. kind)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = kind, CFrame.identity
	local width, depth = definition.width / Config.scale, definition.depth / Config.scale
	part(
		model,
		"StoneAndEarthFooting",
		Vector3.new(width, 1, depth),
		Vector3.new(0, 0.5, 0),
		palette.stone,
		Enum.Material.Pebble
	)
	builders[kind](model, width, depth)
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "japan")
	model:SetAttribute("Kind", kind)
	model:SetAttribute("DisplayName", definition.name)
	model:SetAttribute("EvidenceCard", "docs/notes/Japanese Sandbox Art.md")
	return model
end

local function rod(model, name, a, b, thickness, color)
	local object =
		part(model, name, Vector3.new(thickness, (b - a).Magnitude, thickness), (a + b) / 2, color, Enum.Material.Wood)
	object.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0)
	return object
end

function JapaneseKit.createActor(role: string): Model
	assert(role == "melee" or role == "ranged" or role == "medic", "Missing Japanese presentation role")
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = role, CFrame.identity
	local skin, lacquer = Color3.fromRGB(222, 185, 143), Color3.fromRGB(58, 60, 48)
	local cloth = if role == "medic" then palette.plaster else Color3.fromRGB(105, 118, 109)
	local colors = Instance.new("BodyColors")
	colors.HeadColor3, colors.TorsoColor3 = skin, skin
	colors.LeftArmColor3, colors.RightArmColor3 = skin, skin
	colors.LeftLegColor3, colors.RightLegColor3 = skin, skin
	colors.Parent = model
	part(model, "Torso", Vector3.new(1.9, 2, 1), Vector3.new(0, 3.1, 0), skin)
	part(model, "KosodeBody", Vector3.new(1.98, 2.05, 1.08), Vector3.new(0, 3.05, 0), cloth, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local label = if side < 0 then "Left" else "Right"
		part(model, label .. " Arm", Vector3.new(0.8, 1.9, 0.85), Vector3.new(side * 1.35, 3.1, 0), skin)
		part(
			model,
			"Sleeve",
			Vector3.new(0.86, 1.2, 0.92),
			Vector3.new(side * 1.35, 3.45, 0),
			cloth,
			Enum.Material.Fabric
		)
		part(model, label .. " Leg", Vector3.new(0.8, 1.8, 0.85), Vector3.new(side * 0.5, 1.1, 0), skin)
		part(
			model,
			"LooseTrouserLeg",
			Vector3.new(0.9, 1.55, 0.95),
			Vector3.new(side * 0.5, 1.35, 0),
			cloth,
			Enum.Material.Fabric
		)
		part(
			model,
			"StrawSandal",
			Vector3.new(0.9, 0.25, 1.05),
			Vector3.new(side * 0.5, 0.125, -0.08),
			palette.straw,
			Enum.Material.Wood
		)
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.3, 1.3), Vector3.new(0, 4.75, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Parent = Enum.MeshType.Head, head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxassetid://10526794", Enum.NormalId.Front, head
	if role ~= "medic" then
		part(model, "LacqueredDo", Vector3.new(2.12, 1.7, 1.2), Vector3.new(0, 3.15, 0), lacquer)
		for band = 0, 3 do
			part(
				model,
				"ArmourLacing",
				Vector3.new(2.16, 0.1, 0.1),
				Vector3.new(0, 2.6 + band * 0.36, -0.65),
				Color3.fromRGB(145, 94, 62),
				Enum.Material.Fabric
			)
		end
		local helmet = part(model, "PlainKabuto", Vector3.new(1.65, 0.9, 1.6), Vector3.new(0, 5.3, 0.1), lacquer)
		helmet.Shape = Enum.PartType.Ball
		for band = 0, 2 do
			part(
				model,
				"ShikoroLame",
				Vector3.new(1.8 + band * 0.15, 0.25, 0.65),
				Vector3.new(0, 4.95 - band * 0.2, 0.65),
				lacquer
			)
		end
	else
		part(model, "Hair", Vector3.new(1.45, 0.4, 1.35), Vector3.new(0, 5.28, 0.1), palette.dark)
		part(
			model,
			"MedicineSatchel",
			Vector3.new(1, 1.1, 0.6),
			Vector3.new(-1.2, 2.2, -0.15),
			palette.board,
			Enum.Material.Wood
		)
		cylinder(model, "PreparationBowl", 0.85, 0.3, Vector3.new(1.35, 2.15, -0.2), palette.stone, Enum.Material.Rock)
	end
	if role == "melee" then
		rod(model, "YariShaft", Vector3.new(1.5, 0.1, -0.3), Vector3.new(1.5, 6.9, -0.3), 0.15, palette.wood)
		part(
			model,
			"YariCentralBlade",
			Vector3.new(0.2, 1, 0.15),
			Vector3.new(1.5, 7.3, -0.3),
			Color3.fromRGB(167, 171, 160),
			Enum.Material.Metal
		)
		part(
			model,
			"YariSideBlades",
			Vector3.new(0.95, 0.16, 0.15),
			Vector3.new(1.5, 6.95, -0.3),
			Color3.fromRGB(167, 171, 160),
			Enum.Material.Metal
		)
	elseif role == "ranged" then
		local points = {
			Vector3.new(-1.4, 0.15, -0.5),
			Vector3.new(-1.95, 1.1, -0.5),
			Vector3.new(-1.65, 2.2, -0.5),
			Vector3.new(-1.85, 4.3, -0.5),
			Vector3.new(-2, 6.2, -0.5),
			Vector3.new(-1.3, 7.2, -0.5),
		}
		for index = 1, #points - 1 do
			rod(model, "AsymmetricYumiLimb", points[index], points[index + 1], 0.13, palette.board)
		end
		rod(model, "YumiString", points[1], points[#points], 0.04, palette.straw)
		part(
			model,
			"ArrowCase",
			Vector3.new(0.7, 2.7, 0.55),
			Vector3.new(0.55, 3.6, 0.85),
			palette.wood,
			Enum.Material.Wood
		)
		for index = 0, 2 do
			rod(
				model,
				"LongArrow",
				Vector3.new(0.35 + index * 0.2, 3.4, 0.85),
				Vector3.new(0.35 + index * 0.2, 5.8, 0.85),
				0.07,
				palette.board
			)
		end
	end
	model:ScaleTo(Config.scale)
	model:SetAttribute("CivilizationId", "japan")
	model:SetAttribute("PresentationRole", "roster")
	model:SetAttribute("RosterRole", role)
	model:SetAttribute("PresentationOnly", true)
	model:SetAttribute("EvidenceCard", "docs/notes/Japanese Sandbox Art.md")
	return model
end

return JapaneseKit

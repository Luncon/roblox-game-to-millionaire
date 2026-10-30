--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local RagdollConfig = require(Shared.RagdollConfig)
local Presentation = require(Shared.Presentation)
local State = require(script.Parent.State)
local SpartanKit = require(script.Parent.SpartanKit)
local PersianKit = require(script.Parent.PersianKit)
local RomanKit = require(script.Parent.RomanKit)
local EgyptianKit = require(script.Parent.EgyptianKit)
local MauryanKit = require(script.Parent.MauryanKit)
local VikingKit = require(script.Parent.VikingKit)
local SenecaKit = require(script.Parent.SenecaKit)
local MongolKit = require(script.Parent.MongolKit)
local MingKit = require(script.Parent.MingKit)
local JapaneseKit = require(script.Parent.JapaneseKit)
local OttomanKit = require(script.Parent.OttomanKit)
local SpanishKit = require(script.Parent.SpanishKit)
local BritishKit = require(script.Parent.BritishKit)
local Workers = require(script.Parent.Workers)
local MountedTroops = require(script.Parent.MountedTroops)
local MountStructures = require(script.Parent.MountStructures)
local World = {}
local buyShopPosition = Vector3.new(-14, 1.5, 0)
local sellShopPosition = Vector3.new(14, 1.5, 0)
local buyShopArrival = CFrame.new(-14, 3.5, 5)
local sellShopArrival = CFrame.new(14, 3.5, 5)
World.buyShopPosition, World.sellShopPosition = buyShopPosition, sellShopPosition
World.buyShopArrival, World.sellShopArrival = buyShopArrival, sellShopArrival
local kits = {
	sparta = SpartanKit,
	persia = PersianKit,
	rome = RomanKit,
	egypt = EgyptianKit,
	maurya = MauryanKit,
	vikings = VikingKit,
	seneca = SenecaKit,
	mongols = MongolKit,
	ming = MingKit,
	japan = JapaneseKit,
	ottomans = OttomanKit,
	spain = SpanishKit,
	britain = BritishKit,
}

local function part(parent, name, size, frame, color, material, solid)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = frame
	object.Color = color
	object.Material = material
	object.Anchored = true
	object.CanCollide = solid == true
	object.CanTouch = false
	object.CanQuery = solid == true
	if solid == true and (name == "Ground" or name == "Plot") then
		object.CollisionGroup = RagdollConfig.groundCollisionGroup
	end
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

function World.supports(civilizationId: string): boolean
	return kits[civilizationId] ~= nil
end

function World.availableKits()
	local available = {}
	for civilizationId in kits do
		available[civilizationId] = true
	end
	return available
end

local function buildingModel(civilizationId, kind)
	return if kind == "mount" then MountStructures.create(civilizationId) else kits[civilizationId].create(kind)
end

function World.installPreviews()
	local previous = Shared:FindFirstChild("Previews")
	if previous then
		return previous
	end
	local previews = Instance.new("Folder")
	previews.Name = "Previews"
	previews.Parent = Shared
	for civilizationId, kit in kits do
		local folder = Instance.new("Folder")
		folder.Name = civilizationId
		for kind in Catalog.buildings do
			buildingModel(civilizationId, kind).Parent = folder
		end
		local actors = Instance.new("Folder")
		actors.Name, actors.Parent = "Actors", folder
		for _, role in { "melee", "ranged", "medic" } do
			local actor = kit.createActor(role)
			actor.Name, actor.Parent = role, actors
		end
		folder.Parent = previews
		task.wait()
	end
	return previews
end

function World.clear(plot)
	Workers.clear(plot)
	plot.buildings:ClearAllChildren()
	plot.model:SetAttribute("ArtReady", false)
	plot.model:SetAttribute("OwnerId", nil)
	plot.model:SetAttribute("CivilizationId", nil)
	plot.model:SetAttribute("ArtStatus", "Unclaimed miniature plot")
end

local function createBuilding(plot, building, userId, civilizationId)
	local model = buildingModel(civilizationId, building.kind)
	model.Name = building.id
	model:SetAttribute("BuildingId", building.id)
	model:SetAttribute("OwnerId", userId)
	model:SetAttribute("DisplayName", Presentation.buildingName(civilizationId, building.kind))
	model:PivotTo(
		plot.frame * CFrame.new(building.x, 0.4, building.z) * CFrame.Angles(0, math.rad(building.rotation), 0)
	)
	model.Parent = plot.buildings
	local definition = Catalog.buildings[building.kind]
	local height = math.max(2.5, model:GetExtentsSize().Y)
	local target = part(
		model,
		"SelectTarget",
		Vector3.new(definition.width, height, definition.depth),
		model:GetPivot() * CFrame.new(0, height / 2, 0),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		false
	)
	target.Transparency = 1
	target.CanQuery = true
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = Config.placementRange
	detector.Parent = target
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = if definition.output then "CollectPrompt" else "ReclaimPrompt"
	prompt.ActionText = if definition.output then "Collect all" else "Return to inventory"
	prompt.Enabled = definition.output ~= nil
	prompt:SetAttribute("ReclaimBuilding", definition.output == nil)
	prompt:SetAttribute("CollectAll", definition.output ~= nil)
	prompt.ObjectText = Presentation.buildingName(civilizationId, building.kind)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.interactionRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = target
	return model
end

local function createShop(scene, buying)
	local position = if buying then buyShopPosition else sellShopPosition
	local frame = CFrame.new(position.X, 0, position.Z)
	local identity = if buying then "SharedBuyShop" else "SharedSellShop"
	local title = if buying then "Building market" else "Goods market"
	local model = Instance.new("Model")
	model.Name = identity
	model:SetAttribute(identity, true)
	model:SetAttribute("DisplayName", title)
	model.Parent = scene
	local stone = Color3.fromRGB(181, 168, 140)
	local wood = Color3.fromRGB(114, 78, 48)
	part(
		model,
		"MarketFooting",
		Vector3.new(12, 0.2, 10),
		frame * CFrame.new(0, 0.1, -1),
		stone,
		Enum.Material.Limestone,
		true
	)
	part(
		model,
		"TimberCounter",
		Vector3.new(8, 0.4, 2.5),
		frame * CFrame.new(0, 2.2, -2),
		wood,
		Enum.Material.WoodPlanks,
		false
	)
	for _, x in { -3.6, 3.6 } do
		for _, z in { -3, -1 } do
			part(
				model,
				"CounterLeg",
				Vector3.new(0.45, 2, 0.45),
				frame * CFrame.new(x, 1.1, z),
				wood,
				Enum.Material.Wood,
				false
			)
		end
		part(
			model,
			"CanopyPost",
			Vector3.new(0.35, 5.6, 0.35),
			frame * CFrame.new(x, 3, -3.3),
			wood,
			Enum.Material.Wood,
			false
		)
	end
	part(
		model,
		"CanopyBeam",
		Vector3.new(8.4, 0.3, 0.35),
		frame * CFrame.new(0, 5.7, -3.3),
		wood,
		Enum.Material.Wood,
		false
	)
	part(
		model,
		"PlainCanvasShade",
		Vector3.new(9, 0.12, 4.5),
		frame * CFrame.new(0, 5.8, -1.9) * CFrame.Angles(math.rad(-8), 0, 0),
		Color3.fromRGB(220, 206, 173),
		Enum.Material.Fabric,
		false
	)
	for _, x in { -2.3, 2.3 } do
		part(
			model,
			"TradeCrate",
			Vector3.new(1.5, 1.2, 1.3),
			frame * CFrame.new(x, 2.95, -2),
			wood,
			Enum.Material.WoodPlanks,
			false
		)
	end
	local target =
		part(model, "ShopTarget", Vector3.new(2, 2, 2), CFrame.new(position), stone, Enum.Material.SmoothPlastic, false)
	target.Transparency = 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = if buying then "BuyShopPrompt" else "SellShopPrompt"
	prompt:SetAttribute(identity, true)
	prompt.ActionText = if buying then "Buy buildings" else "Sell goods"
	prompt.ObjectText = title
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.interactionRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = target
	local label = Instance.new("BillboardGui")
	label.Name = "MarketSign"
	label.Size = UDim2.fromOffset(160, 40)
	label.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
	label.AlwaysOnTop = true
	label.Parent = target
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = title
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 18
	text.TextColor3 = Color3.fromRGB(255, 246, 219)
	text.TextStrokeTransparency = 0.3
	text.Parent = label
	return model
end

local function syncTroops(plot, state, userId)
	if plot.model:GetAttribute("CombatManaged") then
		return
	end
	local retained = {}
	local groups = State.troopGroups(state)
	for _, building in state.buildings do
		local group = groups[building.id]
		if group then
			local role, count = group.role, group.count
			for index = 1, count do
				local id = "Troop_" .. building.id .. "_" .. index
				retained[id] = true
				local actor = plot.actors:FindFirstChild(id)
				if not actor then
					actor = if role == "mounted"
						then MountedTroops.create(state.civilizationId)
						else kits[state.civilizationId].createActor(role)
					actor:SetAttribute("PresentationRole", "roster")
					actor:SetAttribute("RosterRole", role)
					actor.Name = id
					actor:SetAttribute("OwnerId", userId)
					actor:SetAttribute("BuildingId", building.id)
					actor:SetAttribute("AutomaticTroop", true)
					actor:SetAttribute("RoleIndex", index)
					actor.Parent = plot.actors
				end
				local x = if count == 1 then 0 else (index - 1.5) * 3.8
				local frame = plot.frame
					* CFrame.new(building.x, if role == "medic" then 0.9 else 0.7, building.z)
					* CFrame.Angles(0, math.rad(building.rotation), 0)
					* CFrame.new(x, 0, 1.5)
					* CFrame.Angles(0, math.pi, 0)
				if role == "mounted" then
					MountedTroops.pose(actor, {
						x = frame.X,
						z = frame.Z,
						headingX = frame.LookVector.X,
						headingZ = frame.LookVector.Z,
						phase = "idle",
					}, Workspace:GetServerTimeNow())
				else
					actor:PivotTo(frame)
				end
			end
		end
	end
	for _, actor in plot.actors:GetChildren() do
		if actor:GetAttribute("PresentationRole") == "roster" and not retained[actor.Name] then
			actor:Destroy()
		end
	end
end

function World.render(plot, state, userId)
	World.clear(plot)
	plot.model:SetAttribute("OwnerId", userId)
	plot.model:SetAttribute("CivilizationId", state.civilizationId)
	if not World.supports(state.civilizationId) then
		plot.model:SetAttribute("ArtStatus", "This civilization's miniature art kit is not available yet")
		return
	end
	for _, building in state.buildings do
		createBuilding(plot, building, userId, state.civilizationId)
	end
	plot.model:SetAttribute("ArtReady", true)
	plot.model:SetAttribute("ArtStatus", state.civilizationId .. " miniature kit")
	Workers.sync(plot, state, userId)
	World.update(plot, state, os.clock())
end

function World.update(plot, state, now: number)
	if not World.supports(state.civilizationId) then
		return
	end
	local retained = {}
	local userId = plot.model:GetAttribute("OwnerId")
	for _, building in state.buildings do
		retained[building.id] = true
		local model = plot.buildings:FindFirstChild(building.id)
			or createBuilding(plot, building, userId, state.civilizationId)
		model:PivotTo(
			plot.frame * CFrame.new(building.x, 0.4, building.z) * CFrame.Angles(0, math.rad(building.rotation), 0)
		)
		model:SetAttribute("Output", building.output)
		model:SetAttribute("HallUpgraded", building.kind == "civic" and state.hallUpgraded)
	end
	for _, model in plot.buildings:GetChildren() do
		if not retained[model.Name] then
			model:Destroy()
		end
	end
	Workers.sync(plot, state, userId)
	Workers.animate(plot, now)
	syncTroops(plot, state, userId)
end

function World.create()
	assert(not Workspace:FindFirstChild("MiniatureSandbox"), "Sandbox scene is already running")
	for _, name in
		{ RagdollConfig.corpseCollisionGroup, RagdollConfig.groundCollisionGroup, RagdollConfig.supportCollisionGroup }
	do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(RagdollConfig.corpseCollisionGroup, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(
		RagdollConfig.corpseCollisionGroup,
		RagdollConfig.corpseCollisionGroup,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		RagdollConfig.corpseCollisionGroup,
		RagdollConfig.groundCollisionGroup,
		true
	)
	PhysicsService:CollisionGroupSetCollidable(RagdollConfig.groundCollisionGroup, "Default", true)
	PhysicsService:CollisionGroupSetCollidable(RagdollConfig.supportCollisionGroup, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(
		RagdollConfig.supportCollisionGroup,
		RagdollConfig.supportCollisionGroup,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		RagdollConfig.supportCollisionGroup,
		RagdollConfig.groundCollisionGroup,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		RagdollConfig.supportCollisionGroup,
		RagdollConfig.corpseCollisionGroup,
		true
	)
	local scene = Instance.new("Model")
	scene.Name = "MiniatureSandbox"
	scene:SetAttribute("Scale", Config.scale)
	scene:SetAttribute("WorldSize", Config.worldSize)
	scene:SetAttribute("PlotRadius", Config.plotRadius)
	part(
		scene,
		"Ground",
		Vector3.new(Config.worldSize, 1, Config.worldSize),
		CFrame.new(0, -0.5, 0),
		Color3.fromRGB(107, 133, 88),
		Enum.Material.Grass,
		true
	)
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plots"
	plotFolder.Parent = scene
	local plots = {}
	for index = 1, Config.plotCount do
		local angle = (index - 1) * math.pi * 2 / Config.plotCount
		local frame = CFrame.new(math.sin(angle) * Config.plotRadius, 0, math.cos(angle) * Config.plotRadius)
			* CFrame.Angles(0, angle, 0)
		local model = Instance.new("Model")
		model.Name = "Plot" .. index
		model:SetAttribute("PlotId", index)
		model:SetAttribute("ExpansionWidth", Config.expansionWidth)
		model:SetAttribute("ExpansionDepth", Config.expansionDepth)
		model:SetAttribute("ArtReady", false)
		model.Parent = plotFolder
		local reserve = part(
			model,
			"ExpansionReserve",
			Vector3.new(Config.expansionWidth, 0.02, Config.expansionDepth),
			frame * CFrame.new(0, 0.02, 0),
			Color3.fromRGB(142, 153, 105),
			Enum.Material.Grass,
			false
		)
		reserve.Transparency = 1
		part(
			model,
			"Plot",
			Vector3.new(Config.plotWidth, 0.4, Config.plotDepth),
			frame * CFrame.new(0, 0.2, 0),
			Color3.fromRGB(142, 153, 105),
			Enum.Material.Grass,
			true
		)
		part(
			model,
			"CrossLane",
			Vector3.new(Config.plotWidth, 0.04, 4),
			frame * CFrame.new(0, 0.42, 0),
			Color3.fromRGB(188, 170, 132),
			Enum.Material.Pebble,
			false
		)
		part(
			model,
			"MainLane",
			Vector3.new(4, 0.04, Config.plotDepth),
			frame * CFrame.new(0, 0.42, 0),
			Color3.fromRGB(188, 170, 132),
			Enum.Material.Pebble,
			false
		)
		for _, side in { -1, 1 } do
			part(
				model,
				"PlotEdge",
				Vector3.new(Config.plotWidth, 0.12, 0.2),
				frame * CFrame.new(0, 0.46, side * Config.plotDepth / 2),
				Color3.fromRGB(213, 199, 160),
				Enum.Material.Limestone,
				false
			)
			part(
				model,
				"PlotEdge",
				Vector3.new(0.2, 0.12, Config.plotDepth),
				frame * CFrame.new(side * Config.plotWidth / 2, 0.46, 0),
				Color3.fromRGB(213, 199, 160),
				Enum.Material.Limestone,
				false
			)
		end
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "CommanderSpawn"
		spawn.Size = Vector3.new(6, 0.2, 6)
		spawn.CFrame = frame * CFrame.new(0, 0.1, 23)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.CanTouch = false
		spawn.CanQuery = false
		spawn.Transparency = 1
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Parent = model
		local buildings = Instance.new("Folder")
		buildings.Name = "Buildings"
		buildings.Parent = model
		local actors = Instance.new("Folder")
		actors.Name = "Actors"
		actors.Parent = model
		plots[index] = { model = model, frame = frame, spawn = spawn, buildings = buildings, actors = actors }
	end
	createShop(scene, true)
	createShop(scene, false)
	scene.Parent = Workspace
	local elapsed = 0
	local connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 / 20 then
			return
		end
		elapsed = 0
		for _, plot in plots do
			Workers.animate(plot, os.clock())
		end
	end)
	scene.Destroying:Once(function()
		connection:Disconnect()
		for _, plot in plots do
			plot.workerState = nil
		end
	end)
	return {
		scene = scene,
		plots = plots,
		buyShopPosition = buyShopPosition,
		sellShopPosition = sellShopPosition,
		buyShopArrival = buyShopArrival,
		sellShopArrival = sellShopArrival,
	}
end

return World

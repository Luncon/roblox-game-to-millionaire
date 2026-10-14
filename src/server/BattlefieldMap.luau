--!strict

local BattlefieldMap = {}
local SettlementBuilder = require(script.Parent.SettlementBuilder)
local Progression = require(game:GetService("ReplicatedStorage").Shared.SettlementProgression)
local PadCatalog = require(game:GetService("ReplicatedStorage").Shared.PadCatalog)
local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local PLOT_COUNT = 8
local PLOT_RADIUS = 160
local NEUTRAL = Color3.fromRGB(103, 119, 104)
local STONE = Color3.fromRGB(181, 174, 153)

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3): Part
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = frame
	object.Color = color
	object.Material = Enum.Material.SmoothPlastic
	object.Anchored = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function sign(parent: Instance, name: string, frame: CFrame, size: Vector3, text: string): Part
	local board = part(parent, name, size, frame, Color3.fromRGB(32, 39, 41))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(600, 240)
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(247, 239, 216)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.Parent = surface
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = label
	return board
end

local function unclaimedMarker(plot: Instance, frame: CFrame, plotId: number)
	local marker = sign(plot, "Sign", frame*CFrame.new(0,1.4,-28), Vector3.new(10,.4,3), string.format("PLOT %02d\nUNCLAIMED",plotId))
	marker.CanCollide, marker.CanTouch, marker.CanQuery = false, false, false
	local surface = marker:FindFirstChildOfClass("SurfaceGui") :: SurfaceGui
	surface.Face = Enum.NormalId.Top
end

local function createPad(controls: Folder, frame: CFrame, definition, plotId: number)
	local pad = part(controls, definition.name, Vector3.new(8,1,6), frame*CFrame.new(definition.x,2,definition.z), Color3.fromRGB(110,76,64))
	pad:SetAttribute("Action",definition.action)
	pad:SetAttribute("GeneratedBy","CivilizationTycoonPad")
	pad:SetAttribute("PlotId",plotId)
	pad.CanTouch = definition.action ~= "earn"
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 0
	detector.Parent = pad
	local prompt = Instance.new("ProximityPrompt")
	prompt.Enabled = false
	prompt.ActionText = string.upper(definition.track)
	prompt.ObjectText = "Claim this civilization first"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = pad
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Top
	surface.CanvasSize = Vector2.new(480,240)
	surface.Parent = pad
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(255,248,225)
	label.Text = string.upper(definition.track).."\nCLAIM YOUR PLOT"
	label.Parent = surface
	return pad
end

function BattlefieldMap.build(parent: Instance)
	assert(not parent:FindFirstChild("CivilizationPrototype"), "Prototype map already exists in this container")
	local model = Instance.new("Model")
	model.Name = "CivilizationPrototype"
	model:SetAttribute("GeneratedBy", "CivilizationBattlefield")
	local ground = part(model, "Ground", Vector3.new(640, 2, 640), CFrame.new(0, -1, 0), Color3.fromRGB(82, 105, 76))
	ground.Material = Enum.Material.Grass
	local field = part(model, "Battlefield", Vector3.new(2, 150, 150), CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(116, 109, 90))
	field.Shape = Enum.PartType.Cylinder
	field.Material = Enum.Material.Ground
	part(model, "FieldMarker", Vector3.new(12, .4, 12), CFrame.new(0, 2.2, 0), Color3.fromRGB(205, 169, 85))

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = model
	local troops = Instance.new("Folder")
	troops.Name, troops.Parent = "Troops", model
	for plotId = 1, PLOT_COUNT do
		local angle = (plotId - 1) * math.pi * 2 / PLOT_COUNT
		local position = Vector3.new(math.sin(angle) * PLOT_RADIUS, 1, math.cos(angle) * PLOT_RADIUS)
		local frame = CFrame.lookAt(position, Vector3.new(0, 1, 0))
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. plotId
		plot:SetAttribute("PlotId", plotId)
		plot.Parent = plots
		local foundation = part(plot, "Foundation", Vector3.new(60, 2, 60), frame, STONE)
		foundation.Material = Enum.Material.Cobblestone
		part(plot, "Banner", Vector3.new(60, .5, 3), frame * CFrame.new(0, 1.3, -28), NEUTRAL)
		unclaimedMarker(plot, frame, plotId)
		local settlement = Instance.new("Folder")
		settlement.Name = "Settlement"
		settlement.Parent = plot
		local controls = Instance.new("Folder")
		controls.Name = "Controls"
		controls.Parent = plot
		for _, definition in PadCatalog.definitions do
			if definition.stage == 1 then createPad(controls, frame, definition, plotId) end
		end
		local roadPosition = Vector3.new(math.sin(angle) * 103, .2, math.cos(angle) * 103)
		part(model, "Path" .. plotId, Vector3.new(14, .4, 60), CFrame.lookAt(roadPosition, Vector3.new(0, .2, 0)), Color3.fromRGB(155, 147, 117))
	end

	local entry = Instance.new("SpawnLocation")
	entry.Name = "EntrySpawn"
	entry.Size = Vector3.new(30, 1, 30)
	entry.CFrame = CFrame.new(0, 2, 250)
	entry.Anchored = true
	entry.Neutral = true
	entry.Duration = 0
	entry.Color = Color3.fromRGB(205, 169, 85)
	entry.Material = Enum.Material.Slate
	entry.Parent = model
	sign(model, "Welcome", CFrame.new(0, 10, 265), Vector3.new(35, 10, 1), "CLASH OF CIVILIZATIONS\nChoose your civilization\nSession-only prototype")
	model.Parent = parent

	local world = { model = model, entry = entry, plotCount = PLOT_COUNT }
	function world:getSpawn(plotId: number?): CFrame
		local plot = if plotId then plots:FindFirstChild("Plot" .. plotId) else nil
		local foundation = if plot then plot:FindFirstChild("Foundation") else nil
		if foundation and foundation:IsA("BasePart") then
			return foundation.CFrame * CFrame.new(0, 7, 17)
		end
		return entry.CFrame * CFrame.new(0, 5, 0)
	end

	function world:getBarracksSpawn(plotId: number, kind: string?): CFrame
		local plot = plots:FindFirstChild("Plot" .. plotId)
		assert(plot, "Unknown barracks plot")
		return (plot.Foundation :: BasePart).CFrame * CFrame.new(if kind == "ranged" then -28 else -24, 5, -11)
	end


	function world:syncControls(plotId: number, state)
		local plot = plots:FindFirstChild("Plot" .. plotId) :: Model
		local foundation = plot:FindFirstChild("Foundation") :: BasePart
		local controls = plot:FindFirstChild("Controls") :: Folder
		local stage = if state then state.level else 1
		for _, definition in PadCatalog.definitions do
			local current = if state and definition.tier then state[PadCatalog.fields[definition.track]] or 1 else 1
			local visible = stage >= definition.stage and (not definition.tier or definition.tier > current)
			local existing = controls:FindFirstChild(definition.name)
			if visible and not existing then
				createPad(controls, foundation.CFrame, definition, plotId)
			elseif not visible and existing and existing:GetAttribute("GeneratedBy") == "CivilizationTycoonPad" then
				existing:Destroy()
			end
		end
	end

	function world:setBarracksLevel(plotId: number, level: number)
		local plot = plots:FindFirstChild("Plot" .. plotId) :: Model
		local barracks = plot.Settlement:FindFirstChild("Barracks")
		if not barracks then return end
		local tier = Tracks.barracks[level]
		barracks:SetAttribute("BarracksLevel",level)
		local label = barracks.BarracksSign:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
		label.Text = string.format("BARRACKS %s · %d TROOP%s\n%gs REINFORCEMENTS",tier.name,tier.capacity,if tier.capacity > 1 then "S" else "",tier.respawnDelay)
	end

	function world:setOwner(plotId: number, civilization, ownerId: number?, ownerName: string?, level: number?)
		local plot = plots:FindFirstChild("Plot" .. plotId)
		assert(plot, "Unknown settlement plot")
		local stage = level or 1
		assert(Progression[stage], "Unknown settlement level")
		local foundation = plot:FindFirstChild("Foundation") :: Part
		-- A plot may have moved or rotated since construction. Its current
		-- foundation anchors both the rebuilt settlement and its spawn point.
		local frame = foundation.CFrame
		local settlement = plot:FindFirstChild("Settlement") :: Folder
		settlement:ClearAllChildren()
		plot:SetAttribute("OwnerId", ownerId)
		plot:SetAttribute("CivilizationId", if civilization then civilization.id else nil)
		plot:SetAttribute("SettlementLevel", if civilization then stage else nil)
		local size = if civilization then Progression[stage].size else Progression[1].size
		foundation.Size = Vector3.new(size, 2, size)
		local banner = plot:FindFirstChild("Banner") :: Part
		banner.Color = if civilization then civilization.color else NEUTRAL
		local marker = plot:FindFirstChild("Sign")
		if not civilization then
			self:syncControls(plotId, nil)
			settlement:SetAttribute("Architecture", nil)
			if not marker then unclaimedMarker(plot, frame, plotId) end
			return
		end
		if marker then marker:Destroy() end
		SettlementBuilder.build(settlement, frame, civilization, stage, {ownerName=ownerName or "Commander", plotId=plotId})
	end

	return world
end

return BattlefieldMap

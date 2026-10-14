--!strict

local BattlefieldMap = {}
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
	local frames: { [number]: CFrame } = {}
	for plotId = 1, PLOT_COUNT do
		local angle = (plotId - 1) * math.pi * 2 / PLOT_COUNT
		local position = Vector3.new(math.sin(angle) * PLOT_RADIUS, 1, math.cos(angle) * PLOT_RADIUS)
		local frame = CFrame.lookAt(position, Vector3.new(0, 1, 0))
		frames[plotId] = frame
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. plotId
		plot:SetAttribute("PlotId", plotId)
		plot.Parent = plots
		local foundation = part(plot, "Foundation", Vector3.new(60, 2, 60), frame, STONE)
		foundation.Material = Enum.Material.Cobblestone
		part(plot, "Banner", Vector3.new(60, .5, 3), frame * CFrame.new(0, 1.3, -28), NEUTRAL)
		sign(plot, "Sign", frame * CFrame.new(0, 8, -27), Vector3.new(24, 7, 1), string.format("PLOT %02d\nUNCLAIMED", plotId))
		local settlement = Instance.new("Folder")
		settlement.Name = "Settlement"
		settlement.Parent = plot
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
		if plotId and frames[plotId] then
			return frames[plotId] * CFrame.new(0, 7, 17)
		end
		return CFrame.lookAt(entry.Position + Vector3.new(0, 5, 0), Vector3.new(0, 7, 0))
	end

	function world:setOwner(plotId: number, civilization, ownerId: number?, ownerName: string?)
		local plot = plots:FindFirstChild("Plot" .. plotId)
		assert(plot, "Unknown settlement plot")
		local frame = frames[plotId]
		local settlement = plot:FindFirstChild("Settlement") :: Folder
		settlement:ClearAllChildren()
		plot:SetAttribute("OwnerId", ownerId)
		plot:SetAttribute("CivilizationId", if civilization then civilization.id else nil)
		local banner = plot:FindFirstChild("Banner") :: Part
		banner.Color = if civilization then civilization.color else NEUTRAL
		local board = plot:FindFirstChild("Sign") :: Part
		local surface = board:FindFirstChildOfClass("SurfaceGui") :: SurfaceGui
		local label = surface:FindFirstChildOfClass("TextLabel") :: TextLabel
		if not civilization then
			label.Text = string.format("PLOT %02d\nUNCLAIMED", plotId)
			return
		end
		label.Text = string.format("PLOT %02d · %s\n%s", plotId, civilization.name, ownerName or "Commander")
		local hall = part(settlement, "Hall", Vector3.new(22, 10, 16), frame * CFrame.new(0, 6, -6), Color3.fromRGB(222, 213, 187))
		hall.Material = if civilization.id == "sparta" then Enum.Material.Sandstone else Enum.Material.Brick
		part(settlement, "Roof", Vector3.new(26, 2, 20), frame * CFrame.new(0, 12, -6), civilization.color)
		for _, x in { -9, -3, 3, 9 } do
			part(settlement, "Pillar", Vector3.new(2, 9, 2), frame * CFrame.new(x, 5.5, 4), STONE)
		end
		part(settlement, "Camp", Vector3.new(10, 5, 10), frame * CFrame.new(-18, 3.5, 16), civilization.color)
	end

	return world
end

return BattlefieldMap

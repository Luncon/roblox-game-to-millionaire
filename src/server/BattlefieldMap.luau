--!strict

local BattlefieldMap = {}
local SettlementBuilder = require(script.Parent.SettlementBuilder)
local Progression = require(game:GetService("ReplicatedStorage").Shared.SettlementProgression)
local PadCatalog = require(game:GetService("ReplicatedStorage").Shared.PadCatalog)
local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local Layout = require(game:GetService("ReplicatedStorage").Shared.WorldConfig)
local Landscape = require(script.Parent.WorldLandscape)
local Development = require(game:GetService("ReplicatedStorage").Shared.SettlementDevelopment)
local Infrastructure = require(script.Parent.SettlementInfrastructure)
local Sites = require(game:GetService("ReplicatedStorage").Shared.SettlementSites)
local Camp = require(game:GetService("ReplicatedStorage").Shared.TrainingCampConfig)
local Topography = require(script.Parent.Topography)
local PLOT_COUNT = Layout.plotCount
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
	local pad = part(controls, definition.name, Vector3.new(8,1,6), frame*CFrame.new(definition.x,definition.y or 2,definition.z), Color3.fromRGB(110,76,64))
	local plot=controls.Parent
	local foundation=plot.Foundation
	local inside=math.abs(definition.x)+pad.Size.X/2<=foundation.Size.X/2+.001
		and math.abs(definition.z)+pad.Size.Z/2<=foundation.Size.Z/2+.001
	local surfaceY=foundation.Size.Y/2
	if not inside then
		-- The map is not parented to Workspace during its first construction.
		-- Sample the same local triangles that build native exterior collision.
		local ground=plot.Parent.Parent.Ground
		local point=ground.CFrame:PointToObjectSpace(pad.Position)
		local surface=ground.CFrame:PointToWorldSpace(Vector3.new(point.X,.95+Topography.sampleHeight(point.X,point.Z),point.Z))
		surfaceY=frame:PointToObjectSpace(surface).Y
	end
	local bottom=(definition.y or 2)-pad.Size.Y/2
	local gap=bottom-surfaceY
	if gap>.001 then
		local support=part(pad,"PadSupport",Vector3.new(pad.Size.X,gap,pad.Size.Z),
			frame*CFrame.new(definition.x,surfaceY+gap/2,definition.z),STONE)
		support.Material=Enum.Material.Slate
		support.CanTouch=false
	end
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
	model:SetAttribute("MaximumSettlementSize",Layout.maxPlotSize)
	model:SetAttribute("PlotRadius",Layout.plotRadius)
	model:SetAttribute("ArenaRadius",Layout.arenaRadius)
	-- Keep the generated grass just above a default Baseplate without editing it.
	local ground = part(model, "Ground", Vector3.new(Layout.groundSize, 2, Layout.groundSize), CFrame.new(0, -.95, 0), Color3.fromRGB(82, 105, 76))
	ground.Material = Enum.Material.Grass
	local field = part(model, "Battlefield", Vector3.new(2, Layout.arenaRadius*2, Layout.arenaRadius*2), CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(116, 109, 90))
	field.Shape = Enum.PartType.Cylinder
	field.Material = Enum.Material.Ground
	field.Transparency,field.CanCollide,field.CanTouch,field.CanQuery=1,false,false,false
	part(model, "FieldMarker", Vector3.new(12, .3, 12), CFrame.new(0, .3, 0), Color3.fromRGB(205, 169, 85))
	Landscape.build(model)

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = model
	local troops = Instance.new("Folder")
	troops.Name, troops.Parent = "Troops", model
	for plotId = 1, PLOT_COUNT do
		local frame = Layout.plotFrame(plotId)
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
		local direction=Vector3.new(frame.Position.X,0,frame.Position.Z).Unit
		local inner=20
		local outer=Layout.plotRadius-Progression[1].size/2+5
		local roadPosition=direction*((inner+outer)/2)+Vector3.new(0,.25,0)
		local road=part(model, "Path" .. plotId, Vector3.new(Layout.laneWidth,.4,outer-inner), CFrame.lookAt(roadPosition,Vector3.new(0,.25,0)), Color3.fromRGB(155, 147, 117))
		road.Material=Enum.Material.Ground
		road:SetAttribute("PlotId",plotId)
		road:SetAttribute("ClearRouteWidth",Layout.laneWidth)
	end

	local entry = Instance.new("SpawnLocation")
	entry.Name = "EntrySpawn"
	entry.Size = Vector3.new(30, 1, 30)
	entry.CFrame = CFrame.new(0, 2, Layout.groundSize/2-35)
	entry.Anchored = true
	entry.Neutral = true
	entry.Duration = 0
	entry.Color = Color3.fromRGB(205, 169, 85)
	entry.Material = Enum.Material.Slate
	entry.Parent = model
	sign(model, "Welcome", entry.CFrame*CFrame.new(0,8,15), Vector3.new(35,10,1), "CLASH OF CIVILIZATIONS\nChoose your civilization\nYour civilizations grow with you")
	model.Parent = parent

	local world = { model = model, entry = entry, plotCount = PLOT_COUNT }
	local plotCivilizations = {}
	function world:getSpawn(plotId: number?): CFrame
		local plot = if plotId then plots:FindFirstChild("Plot" .. plotId) else nil
		local foundation = if plot then plot:FindFirstChild("Foundation") else nil
		if foundation and foundation:IsA("BasePart") then
			return foundation.CFrame * CFrame.new(0, 7, 17)
		end
		return entry.CFrame * CFrame.new(0, 5, 0)
	end

	function world:getBarracksSpawn(plotId: number, kind: string?, slotId: string?): CFrame
		local plot = plots:FindFirstChild("Plot" .. plotId)
		assert(plot, "Unknown barracks plot")
		return (plot.Foundation :: BasePart).CFrame * (if slotId=="medic" then CFrame.new(Sites.hospitalSpawn) elseif slotId=="reinforcement" then CFrame.new(-44,5,-16) elseif slotId=="camp" then CFrame.new(-36,5,-16)
			else CFrame.new(if kind == "ranged" then -28 else -24, 5, -11))
	end

	function world:getArmyRally(plotId: number,slotId: string?): CFrame
		local plot=plots:FindFirstChild("Plot"..plotId)
		return plot.Foundation.CFrame*CFrame.new(Camp.point(Camp.arrivalIndex(slotId)))
	end

	function world:getTrainingPoint(plotId: number,index: number): CFrame
		return plots["Plot"..plotId].Foundation.CFrame*CFrame.new(Camp.point(index))
	end

	function world:syncInfrastructure(plotId: number,state,civilization)
		local plot=plots:FindFirstChild("Plot"..plotId)
		Infrastructure.sync(plot,plot.Foundation.CFrame,civilization or plotCivilizations[plotId],state)
		Infrastructure.status(plot,plot.Foundation.CFrame,state)
	end

	function world:syncControls(plotId: number, state)
		local plot = plots:FindFirstChild("Plot" .. plotId) :: Model
		local foundation = plot:FindFirstChild("Foundation") :: BasePart
		local controls = plot:FindFirstChild("Controls") :: Folder
		for _, definition in PadCatalog.definitions do
			local visible=false
			if definition.action=="earn" then visible=true
			elseif not state then visible=definition.stage==1
			elseif definition.action=="collectFarm" then visible=(state.farmLevel or 0)>0
			else
				local offer=Development.offer(state,definition.track,plot:GetAttribute("CivilizationId"))
				visible=offer and offer.available and state.level>=definition.stage
					and (if definition.repeatFrom then offer.current>=definition.repeatFrom elseif definition.tier then offer.nextLevel==definition.tier else true)
			end
			local existing = controls:FindFirstChild(definition.name)
			if visible and not existing then
				createPad(controls, foundation.CFrame, definition, plotId)
			elseif not visible and existing and existing:GetAttribute("GeneratedBy") == "CivilizationTycoonPad" then
				existing:Destroy()
			end
		end
		self:syncInfrastructure(plotId,state)
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
		plotCivilizations[plotId]=civilization
		assert(Progression[stage], "Unknown settlement level")
		local foundation = plot:FindFirstChild("Foundation") :: Part
		-- A plot may have moved or rotated since construction. Its current
		-- foundation anchors both the rebuilt settlement and its spawn point.
		local frame = foundation.CFrame
		local settlement = plot:FindFirstChild("Settlement") :: Folder
		plot:SetAttribute("OwnerId", ownerId)
		plot:SetAttribute("CivilizationId", if civilization then civilization.id else nil)
		plot:SetAttribute("SettlementLevel", if civilization then stage else nil)
		local size = if civilization then Progression[stage].size else Progression[1].size
		foundation.Size = Vector3.new(size, 2, size)
		local banner = plot:FindFirstChild("Banner") :: Part
		banner.Color = if civilization then civilization.color else NEUTRAL
		local marker = plot:FindFirstChild("Sign")
		if not civilization then
			settlement:ClearAllChildren()
			self:syncInfrastructure(plotId,nil)
			self:syncControls(plotId, nil)
			settlement:SetAttribute("Architecture", nil)
			for _,attribute in {"BuiltLevel","GrowthFeatureCount","BuildFrame","BuildOwnerName","BuildPlotId"} do settlement:SetAttribute(attribute,nil) end
			if not marker then unclaimedMarker(plot, frame, plotId) end
			return
		end
		if marker then marker:Destroy() end
		SettlementBuilder.build(settlement, frame, civilization, stage, {ownerName=ownerName or "Commander", plotId=plotId})
	end

	return world
end

return BattlefieldMap

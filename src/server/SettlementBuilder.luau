--!strict

local SettlementBuilder = {}
local Districts = require(script.Parent.SettlementDistricts)
local STONE = Color3.fromRGB(214, 200, 166)
local TIMBER = Color3.fromRGB(119, 85, 55)

local Progression = require(game:GetService("ReplicatedStorage").Shared.SettlementProgression)
local IDENTITY_STYLES = {
	sparta={host="InnerHall",court="Entablature",style="Spartan stone inscription",font=Enum.Font.Garamond,ink=Color3.fromRGB(74,39,32),back=Color3.fromRGB(219,205,170),trim=Color3.fromRGB(166,116,55)},
	britain={host="BrickManor",style="Georgian regiment plaque",font=Enum.Font.Garamond,ink=Color3.fromRGB(244,224,182),back=Color3.fromRGB(61,76,83),trim=Color3.fromRGB(188,145,65),highCourt=true},
	seneca={host="BarkLonghouse",style="Longhouse carved timber",font=Enum.Font.GothamBold,ink=Color3.fromRGB(244,221,177),back=Color3.fromRGB(80,58,42),trim=Color3.fromRGB(172,126,77),sidePlate=true},
	mongols={host="Yurt",style="Steppe woven standard",font=Enum.Font.GothamBold,ink=Color3.fromRGB(244,221,169),back=Color3.fromRGB(70,101,118),trim=Color3.fromRGB(202,162,82),rotated=true},
	vikings={host="TimberLonghall",style="Norse timber carving",font=Enum.Font.Garamond,ink=Color3.fromRGB(228,206,153),back=Color3.fromRGB(64,75,68),trim=Color3.fromRGB(138,159,143),sidePlate=true},
	persia={host="InnerHall",court="Entablature",style="Achaemenid glazed frieze",font=Enum.Font.Garamond,ink=Color3.fromRGB(248,220,142),back=Color3.fromRGB(44,89,112),trim=Color3.fromRGB(208,161,53)},
	japan={host="TowerTier",style="Sengoku lacquer panel",font=Enum.Font.GothamBold,ink=Color3.fromRGB(245,226,182),back=Color3.fromRGB(83,36,33),trim=Color3.fromRGB(175,131,69)},
	maurya={host="StupaBase",style="Mauryan sandstone inscription",font=Enum.Font.Garamond,ink=Color3.fromRGB(85,53,35),back=Color3.fromRGB(223,198,151),trim=Color3.fromRGB(180,111,45),courtWidth=.6},
	spain={host="ColonialHall",style="Spanish plaster cartouche",font=Enum.Font.Garamond,ink=Color3.fromRGB(88,48,38),back=Color3.fromRGB(238,223,189),trim=Color3.fromRGB(174,127,58),highCourt=true,rounded=true},
	egypt={host="Temple",style="New Kingdom temple frieze",font=Enum.Font.GothamBold,ink=Color3.fromRGB(240,209,121),back=Color3.fromRGB(38,81,117),trim=Color3.fromRGB(186,146,57),courtWidth=.4},
	rome={host="InnerHall",court="Entablature",style="Roman civic inscription",font=Enum.Font.Garamond,ink=Color3.fromRGB(88,43,36),back=Color3.fromRGB(226,216,190),trim=Color3.fromRGB(165,129,63)},
	ottomans={host="DomedHall",style="Ottoman tile panel",font=Enum.Font.Garamond,ink=Color3.fromRGB(244,225,178),back=Color3.fromRGB(37,94,91),trim=Color3.fromRGB(185,146,68),rounded=true},
	ming={host="TowerTier",style="Ming lacquer signboard",font=Enum.Font.GothamBold,ink=Color3.fromRGB(245,211,118),back=Color3.fromRGB(104,39,34),trim=Color3.fromRGB(201,157,55)},
}

local function identity(parent: Folder, civilization, level: number, metadata)
	local style = IDENTITY_STYLES[civilization.id]
	local ownerName = if metadata and metadata.ownerName then metadata.ownerName else "Commander"
	local plotId = if metadata and metadata.plotId then metadata.plotId else 0
	for _, courtyard in {false, true} do
		local guiName = if courtyard then "CourtyardNameplate" else "CivilizationNameplate"
		local previous = parent:FindFirstChild(guiName, true)
		if previous and previous:GetAttribute("GeneratedBy") == "CivilizationSettlementIdentity" then previous:Destroy() end
		local grand = if not courtyard then parent:FindFirstChild("GrandIdentityHost") else nil
		local host = (grand or parent:FindFirstChild(if courtyard then style.court or style.host else style.host)) :: BasePart
		assert(host, "Civilization identity facade is missing")
		local surface = Instance.new("SurfaceGui")
		surface.Name = if courtyard then "CourtyardNameplate" else "CivilizationNameplate"
		surface.Face = if courtyard then Enum.NormalId.Back else Enum.NormalId.Front
		surface.CanvasSize = Vector2.new(host.Size.X*32, host.Size.Y*32)
		surface.LightInfluence = .3
		surface:SetAttribute("GeneratedBy", "CivilizationSettlementIdentity")
		surface:SetAttribute("CivilizationId", civilization.id)
		surface:SetAttribute("OwnerName", ownerName)
		surface:SetAttribute("PlotId", plotId)
		surface:SetAttribute("SettlementLevel", level)
		surface:SetAttribute("Style", style.style)
		surface.Parent = host
		local label = Instance.new("TextLabel")
		label.Name = "TextLabel"
		label.AnchorPoint = Vector2.new(.5,.5)
		local height = math.min(host.Size.Y*.7, if courtyard then 3 else 3.8)
		label.Size = UDim2.fromScale(if courtyard then style.courtWidth or .88 else .88, height/host.Size.Y)
		label.Position = UDim2.fromScale(.5, if host.Size.Y < 3 then .5 else .32)
		if style.sidePlate and not grand then
			-- The longhouse's central end post projects beyond this facade.
			-- Keep the carved panel wholly inside the adjacent wall bay.
			label.Size = UDim2.fromScale(.36, height/host.Size.Y)
			label.Position = UDim2.fromScale(.25,.32)
		end
		if courtyard and style.highCourt then
			label.Size = UDim2.fromScale(.86,.16)
			label.Position = UDim2.fromScale(.5,.09)
		end
		if style.rotated and not grand then
			-- The yurt cylinder's local X axis is vertical after its model rotation.
			label.Size = UDim2.fromOffset(16*32,3.6*32)
			label.Position = UDim2.fromScale(.5,.5)
			label.Rotation = if courtyard then 90 else -90
		end
		if grand then label.Position = UDim2.fromScale(.5,.5) end
		label.BackgroundColor3 = style.back
		label.BackgroundTransparency = .12
		label.BorderSizePixel = 0
		label.Font = style.font
		label.TextColor3 = style.ink
		label.TextScaled, label.TextWrapped = true, true
		label.Text = if courtyard then civilization.name.."\n"..ownerName
			else string.format("%s\n%s\n%s · Plot %02d",civilization.name,ownerName,Progression[level].name,plotId)
		label.Parent = surface
		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.Color, outline.Thickness = style.trim, 2
		outline.Parent = label
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft, padding.PaddingRight = UDim.new(0,8), UDim.new(0,8)
		padding.Parent = label
		if style.rounded then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(.12,0)
			corner.Parent = label
		end
	end
end

local function block(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?): Part
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = frame
	object.Color = color
	object.Material = material or Enum.Material.Sandstone
	object.Anchored = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function pitchedRoof(parent: Instance, frame: CFrame, width: number, depth: number, color: Color3)
	for _, side in {-1, 1} do
		block(parent, "RoofSlope", Vector3.new(width / 2 + 2, 1.5, depth + 3),
			frame * CFrame.new(side * width / 4, 0, 0) * CFrame.Angles(0, 0, side * -.4), color, Enum.Material.WoodPlanks)
	end
end

local function starter(parent: Folder, frame: CFrame, civilization)
	local id = civilization.id
	local color = civilization.color
	-- Reserve the front courtyard for unchanged, reachable tycoon controls.
	local hall = frame * CFrame.new(0, 0, -7)
	local function piece(name: string, size: Vector3, position: Vector3, tint: Color3?, material: Enum.Material?)
		return block(parent, name, size, hall * CFrame.new(position), tint or STONE, material)
	end
	if id == "mongols" then
		local tent = piece("Yurt", Vector3.new(9, 22, 22), Vector3.new(0, 5.5, 0), Color3.fromRGB(230, 217, 182), Enum.Material.Fabric)
		tent.Shape = Enum.PartType.Cylinder
		tent.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		piece("YurtRoof", Vector3.new(24, 2, 24), Vector3.new(0, 11, 0), color, Enum.Material.Fabric)
		piece("RoofVent", Vector3.new(5, 2, 5), Vector3.new(0, 13, 0), TIMBER)
	elseif id == "seneca" or id == "vikings" then
		local length = if id == "seneca" then 32 else 26
		piece(if id == "seneca" then "BarkLonghouse" else "TimberLonghall", Vector3.new(18, 9, length), Vector3.new(0, 5.5, 0), TIMBER, Enum.Material.WoodPlanks)
		pitchedRoof(parent, hall * CFrame.new(0, 12, 0), 20, length, if id == "seneca" then TIMBER else color)
		for _, z in {-length / 2, length / 2} do
			piece("EndPost", Vector3.new(2, if id == "vikings" then 16 else 12, 2), Vector3.new(0, 7, z), color, Enum.Material.Wood)
		end
	elseif id == "japan" or id == "ming" then
		local tiers = if id == "japan" then 3 else 2
		for tier = 1, tiers do
			local width = 27 - tier * 5
			piece("TowerTier", Vector3.new(width, 5, width), Vector3.new(0, 1 + tier * 5, 0), if id == "japan" then STONE else color)
			piece("OverhangingRoof", Vector3.new(width + 7, 1.5, width + 7), Vector3.new(0, 4 + tier * 5, 0), if id == "japan" then color else Color3.fromRGB(219, 175, 65))
		end
		piece("GateBeam", Vector3.new(30, 2, 2), Vector3.new(0, 10, 16), color, Enum.Material.Wood)
		for _, x in {-12, 12} do piece("GatePost", Vector3.new(2, 10, 2), Vector3.new(x, 5, 16), color, Enum.Material.Wood) end
	elseif id == "egypt" then
		piece("Temple", Vector3.new(24, 9, 18), Vector3.new(0, 5.5, 0))
		for _, x in {-9, 9} do
			piece("Pylon", Vector3.new(7, 17, 5), Vector3.new(x, 9.5, 11))
			piece("PylonBand", Vector3.new(7.5, 2, 5.5), Vector3.new(x, 16, 11), color)
		end
		piece("Obelisk", Vector3.new(3, 21, 3), Vector3.new(20, 11.5, 0), color)
	elseif id == "maurya" or id == "ottomans" then
		piece(if id == "maurya" then "StupaBase" else "DomedHall", Vector3.new(24, 7, 22), Vector3.new(0, 4.5, 0))
		local dome = piece("Dome", Vector3.new(22, 14, 22), Vector3.new(0, 9, 0), color)
		dome.Shape = Enum.PartType.Ball
		piece("Finial", Vector3.new(2, 6, 2), Vector3.new(0, 18, 0), STONE)
		if id == "ottomans" then
			for _, x in {-17, 17} do
				piece("Minaret", Vector3.new(3, 24, 3), Vector3.new(x, 13, -4))
				piece("MinaretCap", Vector3.new(5, 2, 5), Vector3.new(x, 25, -4), color)
			end
		else
			piece("ToranaBeam", Vector3.new(26, 2, 3), Vector3.new(0, 12, 15), color)
			for _, x in {-10, 10} do piece("ToranaPost", Vector3.new(3, 12, 3), Vector3.new(x, 6, 15)) end
		end
	elseif id == "britain" or id == "spain" then
		piece(if id == "britain" then "BrickManor" else "ColonialHall", Vector3.new(24, 11, 18), Vector3.new(0, 6.5, 0),
			if id == "britain" then Color3.fromRGB(159, 91, 72) else STONE, if id == "britain" then Enum.Material.Brick else Enum.Material.Sandstone)
		pitchedRoof(parent, hall * CFrame.new(0, 14, 0), 26, 20, color)
		if id == "britain" then piece("Chimney", Vector3.new(3, 8, 3), Vector3.new(7, 15, -4), STONE, Enum.Material.Brick)
		else
			piece("BellTower", Vector3.new(6, 20, 6), Vector3.new(14, 11, -3))
			piece("BellTowerCap", Vector3.new(8, 2, 8), Vector3.new(14, 22, -3), color)
		end
		for _, x in {-7, 7} do piece("Window", Vector3.new(4, 4, .5), Vector3.new(x, 8, 9.3), Color3.fromRGB(102, 159, 170), Enum.Material.Glass) end
	else -- Spartan temple, Persian terrace, or Roman civic hall
		local width = if id == "persia" then 30 else 24
		piece(if id == "persia" then "PalaceTerrace" else "Hall", Vector3.new(width + 6, 2, 23), Vector3.new(0, 2, 0))
		piece("InnerHall", Vector3.new(width - 6, 9, 14), Vector3.new(0, 7.5, -2))
		piece("Entablature", Vector3.new(width + 4, 2, 22), Vector3.new(0, 13, 0), color)
		for _, x in {-width / 2 + 2, -4, 4, width / 2 - 2} do
			piece("Column", Vector3.new(2, 10, 2), Vector3.new(x, 8, 9))
			if id == "rome" then piece("ArchHeader", Vector3.new(5, 2, 3), Vector3.new(x, 11, 9), color) end
		end
		if id == "persia" then
			piece("UpperTerrace", Vector3.new(22, 2, 14), Vector3.new(0, 16, -3), STONE)
			for _, x in {-13, 13} do piece("Gateway", Vector3.new(3, 17, 5), Vector3.new(x, 9.5, 12), color) end
		elseif id == "sparta" then pitchedRoof(parent, hall * CFrame.new(0, 16, 0), 28, 24, color) end
	end

	block(parent, "Camp", Vector3.new(9,5,8), frame*CFrame.new(-24,3.5,0), civilization.color, Enum.Material.Fabric)
end

local function addBarracks(parent: Folder, frame: CFrame, civilization)
	local id, color = civilization.id, civilization.color
	-- The original tent becomes the entrance awning rather than an obstacle.
	local camp = parent:FindFirstChild("Camp") :: Part
	camp.Size, camp.CFrame = Vector3.new(10,.4,3), frame*CFrame.new(-24,9.2,-8)
	camp.CanCollide, camp.CanTouch, camp.CanQuery = false, false, false
	local barracks = Instance.new("Model")
	barracks.Name = "Barracks"
	barracks:SetAttribute("CivilizationId", id)
	barracks:SetAttribute("BarracksLevel", 1)
	barracks.Parent = parent
	local origin = frame * CFrame.new(-24,0,0)
	local timber = id == "seneca" or id == "vikings" or id == "mongols"
	local material = if timber then Enum.Material.WoodPlanks else Enum.Material.Sandstone
	local wall = if timber then TIMBER else STONE
	block(barracks,"Floor",Vector3.new(10,.4,14),origin*CFrame.new(0,1.2,0),wall,material)
	for _, side in {-1,1} do
		block(barracks,"SideWall",Vector3.new(1,7,14),origin*CFrame.new(side*4.5,4.8,0),wall,material)
		block(barracks,"DoorPost",Vector3.new(2.5,7,1),origin*CFrame.new(side*3.75,4.8,-6.5),wall,material)
	end
	block(barracks,"BarracksBack",Vector3.new(10,7,1),origin*CFrame.new(0,4.8,6.5),wall,material)
	block(barracks,"DoorBeam",Vector3.new(10,1.2,1),origin*CFrame.new(0,8,-6.5),color)
	block(barracks,"Roof",Vector3.new(12,1.2,16),origin*CFrame.new(0,9,0),color,
		if timber then Enum.Material.WoodPlanks else Enum.Material.Slate)
	if id == "japan" or id == "ming" then
		block(barracks,"RoofTier",Vector3.new(9,1,12),origin*CFrame.new(0,10,0),color)
	elseif id == "egypt" or id == "sparta" or id == "rome" or id == "persia" then
		for _, side in {-1,1} do block(barracks,"EntrancePillar",Vector3.new(.8,8,.8),origin*CFrame.new(side*4,5,-7.5),color) end
	end
	local board = block(barracks,"BarracksSign",Vector3.new(8,1.5,.25),origin*CFrame.new(0,9,-8.2),Color3.fromRGB(32,39,41))
	local surface = Instance.new("SurfaceGui")
	surface.Face, surface.CanvasSize, surface.Parent = Enum.NormalId.Front, Vector2.new(600,110), board
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1,1), 1
	label.Font, label.TextScaled = Enum.Font.GothamBold, true
	label.TextColor3 = Color3.fromRGB(247,239,216)
	label.Text, label.Parent = "BARRACKS I · 1 WARRIOR", surface
end

function SettlementBuilder.build(parent: Folder, frame: CFrame, civilization, level: number, metadata: {ownerName: string?, plotId: number?}?)
	assert(Progression[level], "Unknown settlement level")
	local ownerName = if metadata then metadata.ownerName else nil
	local plotId = if metadata then metadata.plotId else nil
	local previousLevel = parent:GetAttribute("BuiltLevel")
	local core = parent:FindFirstChild(IDENTITY_STYLES[civilization.id].host)
	-- Instance attributes survive Lua wrapper collection while the engine-owned
	-- Folder is alive; a weak-key cache could forget a build between upgrades.
	local reuse = typeof(previousLevel)=="number" and parent:GetAttribute("Architecture")==civilization.id
		and parent:GetAttribute("BuildFrame")==frame and parent:GetAttribute("BuildOwnerName")==ownerName
		and parent:GetAttribute("BuildPlotId")==plotId and (level==previousLevel or level==previousLevel+1)
		and core~=nil and core:IsA("BasePart")
	local from = if reuse then (previousLevel :: number)+1 else 2
	if not reuse then
		parent:ClearAllChildren()
		starter(parent,frame,civilization)
	end
	for unlocked = from,level do
		if unlocked == 2 then addBarracks(parent,frame,civilization) end
		Districts.add(parent,frame,civilization,unlocked)
	end
	Districts.perimeter(parent,frame,civilization,level)
	parent:SetAttribute("Architecture",civilization.id)
	parent:SetAttribute("BuiltLevel",level)
	parent:SetAttribute("GrowthFeatureCount",level-1)
	identity(parent,civilization,level,metadata)
	parent:SetAttribute("BuildFrame",frame)
	parent:SetAttribute("BuildOwnerName",ownerName)
	parent:SetAttribute("BuildPlotId",plotId)
end

return SettlementBuilder

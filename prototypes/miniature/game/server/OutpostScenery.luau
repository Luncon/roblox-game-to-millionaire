--!strict
-- Shared neutral camp art. No capture, collision, query, economy or NPC logic.
-- Descriptors use full-size craft units; create scales the complete model to .25.
local Scenery = { scale = 0.25, captureRadius = 22, captureClearRadius = 4, corridorHalfWidth = 5 }
export type Piece = {
	name: string,
	category: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	rx: number,
	ry: number,
	rz: number,
	color: string,
	material: string,
	form: string,
	anchored: boolean,
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
}
local palette = {
	stone = { 139, 139, 121 },
	stoneCap = { 168, 163, 141 },
	wood = { 101, 77, 49 },
	timber = { 126, 98, 62 },
	cloth = { 185, 170, 130 },
	clothDark = { 162, 152, 119 },
	cord = { 74, 65, 47 },
	clay = { 157, 115, 78 },
}

function Scenery.plan(index: number): { Piece }
	assert(index >= 1 and index % 1 == 0 and index < math.huge, "Invalid outpost scenery index")
	local pieces = {}
	local function add(category, name, x, y, z, sx, sy, sz, color, material, rx, ry, rz, form)
		table.insert(pieces, {
			name = name,
			category = category,
			x = x,
			y = y,
			z = z,
			sx = sx,
			sy = sy,
			sz = sz,
			rx = rx or 0,
			ry = ry or 0,
			rz = rz or 0,
			color = color or "stone",
			material = material or "Slate",
			form = form or "block",
			anchored = true,
			canCollide = false,
			canTouch = false,
			canQuery = false,
		})
	end
	local roof = if index % 3 == 0 then "clothDark" else "cloth"
	-- Eight partial wall runs leave broad open gates on all four axes. Rough
	-- stone bases, timber uprights and rails read as one maintained perimeter.
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			add("Wall", "StoneFacing", sx * 68, 2.6, sz * 42, 2.4, 5.2, 20, "stone", "Slate")
			add("Wall", "StoneCoping", sx * 68, 5.9, sz * 42, 3, 1.4, 20.6, "stoneCap", "Slate")
			add("Wall", "StoneFacing", sx * 42, 2.6, sz * 68, 20, 5.2, 2.4, "stone", "Slate")
			add("Wall", "StoneCoping", sx * 42, 5.9, sz * 68, 20.6, 1.4, 3, "stoneCap", "Slate")
			for _, position in { 34, 42, 50 } do
				local height = if (position + index) % 3 == 0 then 9 else 8.5
				add("Wall", "PalisadeUpright", sx * 68, height / 2, sz * position, 1.2, height, 1.2, "timber", "Wood")
				add("Wall", "PalisadeUpright", sx * position, height / 2, sz * 68, 1.2, height, 1.2, "timber", "Wood")
			end
			add("Wall", "TimberRail", sx * 67, 6.9, sz * 42, 0.8, 0.8, 18, "wood", "Wood")
			add("Wall", "TimberRail", sx * 42, 6.9, sz * 67, 18, 0.8, 0.8, "wood", "Wood")
		end
	end
	-- Two open watchposts flank opposite corners. Their roofed platforms and
	-- ladders are static silhouettes; there is no climb, weapon or spawn script.
	for _, sign in { -1, 1 } do
		local x, z = sign * 50, sign * 50
		add("Watchpost", "WatchDeck", x, 11.2, z, 12, 0.8, 12, "wood", "WoodPlanks")
		for _, dx in { -4.3, 4.3 } do
			for _, dz in { -4.3, 4.3 } do
				add("Watchpost", "WatchLeg", x + dx, 8.9, z + dz, 1.2, 17.8, 1.2, "wood", "Wood")
			end
		end
		add("Watchpost", "WatchRail", x, 13.6, z + 5.3, 12, 0.8, 0.8, "timber", "Wood")
		add("Watchpost", "WatchRail", x + 5.3, 13.6, z, 0.8, 0.8, 12, "timber", "Wood")
		for _, side in { -1, 1 } do
			add("Watchpost", "WatchRoof", x + side * 3.3, 18.1, z, 7.4, 0.7, 14, roof, "Fabric", 0, 0, -side * 0.18)
			add("Watchpost", "LadderRail", x + side * 1.6, 6.8, z - 7, 0.55, 13.4, 0.55, "timber", "Wood", 0.1)
		end
		for _, y in { 2.5, 5, 7.5, 10 } do
			add("Watchpost", "LadderRung", x, y, z - 7 + (y - 6.8) * math.tan(0.1), 3.2, 0.45, 0.55, "timber", "Wood")
		end
	end
	-- Opposite guard huts face the central yard. Open doorways, varied roof forms
	-- and stone plinths distinguish enclosed lodging from the raised watchposts.
	for _, sign in { -1, 1 } do
		local x, z = sign * 40, -sign * 40
		local facing = sign
		add("GuardHut", "HutPlinth", x, 0.5, z, 16, 1, 14, "stoneCap", "Slate")
		add("GuardHut", "HutBack", x, 4.5, z - facing * 6.5, 16, 7, 0.9, "stone", "Slate")
		for _, side in { -1, 1 } do
			add("GuardHut", "HutSide", x + side * 7.5, 4.5, z, 1, 7, 13, "stone", "Slate")
			add("GuardHut", "DoorJamb", x + side * 5.5, 4.5, z + facing * 6.5, 4, 7, 1, "timber", "WoodPlanks")
			add("GuardHut", "HutRoofSlope", x + side * 4, 8.8, z, 8.6, 0.75, 16, roof, "Fabric", 0, 0, -side * 0.24)
		end
		add("GuardHut", "DoorLintel", x, 7.5, z + facing * 6.5, 12, 1, 1.2, "wood", "Wood")
		add("GuardHut", "RoofRidge", x, 9.9, z, 0.7, 0.7, 16, "timber", "Wood")
	end
	-- Food/tool stores are ordinary camp props, never fake shops or upgrades.
	for _, sign in { -1, 1 } do
		add("Stores", "SupplyPallet", sign * 34, 0.45, sign * 56, 19, 0.9, 9, "wood", "WoodPlanks")
		for position = 1, 3 do
			local x, z = sign * (22 + position * 6), sign * 56
			add("Stores", "SupplyCrate", x, 3, z, 5, 5.1, 5, "timber", "WoodPlanks")
			for _, side in { -1, 1 } do
				add("Stores", "CrateStrap", x + side * 1.65, 3, z, 0.45, 5.3, 5.3, "cord", "Wood")
			end
		end
		local bx, bz = sign * 29, sign * 43
		add("Stores", "WaterBarrel", bx, 2.6, bz, 5.2, 3.7, 3.7, "timber", "Wood", 0, 0, math.pi / 2, "cylinder")
		for _, y in { 0.8, 4.4 } do
			add("Stores", "BarrelHoop", bx, y, bz, 0.45, 4, 4, "cord", "Metal", 0, 0, math.pi / 2, "cylinder")
		end
		local rx, rz = -sign * 56, sign * 28
		for _, side in { -1, 1 } do
			add("Stores", "RackLeg", rx + side * 2.5, 2.5, rz, 0.75, 5, 0.75, "timber", "Wood")
		end
		add("Stores", "ToolRack", rx, 4.8, rz, 7, 0.8, 1, "wood", "Wood")
		local px, pz = sign * 28, sign * 28
		add("Stores", "ClayJar", px, 2, pz, 4, 2.8, 2.8, "clay", "SmoothPlastic", 0, 0, math.pi / 2, "cylinder")
		add("Stores", "JarLid", px, 4.15, pz, 0.5, 3, 3, "stoneCap", "Slate", 0, 0, math.pi / 2, "cylinder")
	end
	return pieces
end

function Scenery.create(parent: Instance, frame: CFrame, index: number): Model
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = "OutpostScenery", CFrame.identity
	model:SetAttribute("VisualOnly", true)
	model:SetAttribute("OutpostScenery", true)
	model:SetAttribute("SceneryIndex", index)
	model:SetAttribute("CaptureRadius", Scenery.captureRadius)
	model:SetAttribute("CorridorHalfWidth", Scenery.corridorHalfWidth)
	model:SetAttribute("CaptureClearRadius", Scenery.captureClearRadius)
	for number, piece in Scenery.plan(index) do
		local part = Instance.new("Part")
		part.Name = piece.name .. number
		part.Size = Vector3.new(piece.sx, piece.sy, piece.sz)
		part.CFrame = CFrame.new(piece.x, piece.y, piece.z) * CFrame.Angles(piece.rx, piece.ry, piece.rz)
		local color = palette[piece.color]
		part.Color = Color3.fromRGB(color[1], color[2], color[3])
		part.Material = Enum.Material[piece.material]
		if piece.form == "cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery =
			piece.anchored, piece.canCollide, piece.canTouch, piece.canQuery
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part:SetAttribute("SceneryCategory", piece.category)
		part:SetAttribute("VisualOnly", true)
		part.Parent = model
	end
	model:ScaleTo(Scenery.scale)
	model:PivotTo(frame)
	model.Parent = parent
	return model
end

return table.freeze(Scenery)

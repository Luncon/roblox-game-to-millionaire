--!strict
-- Every animal is a fresh user-asset clone. Imported scripts and physics never run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MountConfig = require(ReplicatedStorage.MiniatureGame.MountConfig)
local Civilizations = require(ReplicatedStorage.MiniatureGame.Civilizations)
local OriginalTroops = require(script.Parent.OriginalTroops)
local MountedTroops = {}
type Parts = { BasePart }
type Groups = { [string]: Parts }
local legNames = {
	elephant = { "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
	horse = { "FrontLeft", "FrontRight", "BackLeft", "BackRight" },
	elk = { "Left  shoulder", "Right shoulder", "Left hip", "Right hip" },
	bear = { "FrontLeftLeg", "FrontRightLeg", "BackLeftLeg", "BackRightLeg" },
	bull = { "Upperfrontleft", "UpperFrontRight", "Upperbackleft", "Upperbackright" },
	wolf = { "LeftShoulder", "RightShoulder", "LeftThigh", "RightThigh" },
	camel = { "Cube.013", "Cube", "Cube.017", "Cube.020" },
	rhino = { "FrontLeft", "FrontRight", "BackLeft", "BackRight" },
	lion = { "Left Leg", "Right Leg", "Left Hindleg", "Right HIndleg" },
}
local groupNames = { "frontLeft", "frontRight", "backLeft", "backRight" }
local function corners(part: BasePart): { Vector3 }
	local result = {}
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				table.insert(result, part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
			end
		end
	end
	return result
end
local function bounds(parts: Parts): (Vector3, Vector3)
	local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, part in parts do
		for _, point in corners(part) do
			low = Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z))
			high = Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z))
		end
	end
	return low, high
end
local function largest(parts: Parts): BasePart
	local result = parts[1]
	assert(result, "Animal anatomy has no visible geometry")
	for _, part in parts do
		if part.Size.X * part.Size.Y * part.Size.Z > result.Size.X * result.Size.Y * result.Size.Z then
			result = part
		end
	end
	return result
end
local function named(parts: Parts, name: string): BasePart?
	for _, part in parts do
		if part.Name == name then
			return part
		end
	end
	return nil
end
local function passive(part: BasePart)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	part:SetAttribute("MountGeometry", true)
end
local function sanitize(animal: Model): (Parts, { [BasePart]: BasePart })
	local parents: { [BasePart]: BasePart } = {}
	local parts = {}
	for _, object in animal:GetDescendants() do
		if object:IsA("JointInstance") or object:IsA("WeldConstraint") then
			local first, second = object.Part0, object.Part1
			if first and second and first ~= second and not parents[second] then
				parents[second] = first
			end
		end
	end
	-- Some imports parent visible pieces beneath invisible controller parts.
	for _, object in animal:GetDescendants() do
		if
			object:IsA("BasePart")
			and object.Transparency < 1
			and not object:IsA("Seat")
			and not object:IsA("VehicleSeat")
		then
			object.Parent = animal
		end
	end
	for _, object in animal:GetDescendants() do
		if object:IsA("BasePart") then
			if object.Transparency >= 1 or object:IsA("Seat") or object:IsA("VehicleSeat") then
				object:Destroy()
			else
				passive(object)
				table.insert(parts, object)
			end
		elseif
			object:IsA("LuaSourceContainer")
			or object:IsA("JointInstance")
			or object:IsA("Constraint")
			or object:IsA("Humanoid")
			or object:IsA("AnimationController")
			or object:IsA("Animator")
			or object:IsA("BodyMover")
			or object:IsA("Tool")
			or object:IsA("RemoteEvent")
			or object:IsA("RemoteFunction")
			or object:IsA("ProximityPrompt")
			or object:IsA("ClickDetector")
			or object:IsA("BillboardGui")
		then
			object:Destroy()
		end
	end
	return parts, parents
end
local function motor(
	parent: BasePart,
	child: BasePart,
	pivot: Vector3,
	kind: string?,
	phase: number?,
	amplitude: number?
): Motor6D
	local joint = Instance.new("Motor6D")
	joint.Name = "MountLink_" .. child.Name
	joint.Part0, joint.Part1 = parent, child
	local frame = CFrame.new(pivot)
	joint.C0, joint.C1 = parent.CFrame:ToObjectSpace(frame), child.CFrame:ToObjectSpace(frame)
	joint.Enabled = false
	if kind then
		joint:SetAttribute("MountJoint", true)
		joint:SetAttribute("MountRestC0", joint.C0)
		joint:SetAttribute("MountJointKind", kind)
		joint:SetAttribute("MountGaitPhase", phase or 0)
		joint:SetAttribute("MountGaitAmplitude", amplitude or 0)
	end
	joint.Parent = parent
	return joint
end
local function anatomy(
	parts: Parts,
	originalParents: { [BasePart]: BasePart },
	template: string,
	body: BasePart
): ({ [BasePart]: BasePart }, Groups, { [BasePart]: string })
	local parents: { [BasePart]: BasePart } = {}
	local groups: Groups = { frontLeft = {}, frontRight = {}, backLeft = {}, backRight = {} }
	local roots: { [BasePart]: string } = {}
	local present: { [BasePart]: boolean } = {}
	for _, part in parts do
		present[part] = true
	end
	for part, parent in originalParents do
		if present[part] and present[parent] and part ~= body then
			parents[part] = parent
		end
	end
	local names = legNames[template]
	if names then
		for index, name in names do
			local root = named(parts, name)
			assert(root, "User animal is missing an expected limb")
			roots[root] = groupNames[index]
		end
	end
	if template == "tiger" or template == "crocodile" then
		local low, high = bounds({ body })
		local width, length = high.X - low.X, high.Z - low.Z
		local limbParts: { [BasePart]: boolean } = {}
		for _, part in parts do
			local point = part.Position - body.Position
			if
				part.Name ~= "LeopardSpot"
				and math.abs(point.X) > width * 0.22
				and math.abs(point.Z) < length * 0.65
				and (template ~= "crocodile" or point.Y < -(high.Y - low.Y) * 0.08)
			then
				local side = if point.X < 0 then "Left" else "Right"
				local group = (if point.Z < 0 then "front" else "back") .. side
				table.insert(groups[group], part)
				limbParts[part] = true
			end
		end
		for group, members in groups do
			assert(#members > 0, "User animal has no visible limb quadrant")
			local root = largest(members)
			for _, member in members do
				if member.Position.Y > root.Position.Y and member.Size.Magnitude > root.Size.Magnitude * 0.55 then
					root = member
				end
			end
			roots[root], parents[root] = group, body
			for _, member in members do
				if member ~= root then
					parents[member] = root
				end
			end
		end
		for _, kind in { "head", "tail" } do
			local members = {}
			for _, part in parts do
				local distance = part.Position.Z - body.Position.Z
				if
					not limbParts[part]
					and (if kind == "head" then distance < -length * 0.5 else distance > length * 0.5)
				then
					table.insert(members, part)
				end
			end
			if #members > 0 then
				local root = largest(members)
				root:SetAttribute("MountAnatomyKind", kind)
				parents[root] = body
				for _, member in members do
					if member ~= root then
						parents[member] = root
					end
				end
			end
		end
	end
	local head = named(parts, "Head") or named(parts, "head") or named(parts, "Lion Head")
	local neck = named(parts, "Neck")
	local tail = named(parts, "TailBase") or named(parts, "Tail1") or named(parts, "Tail 1")
	for _, part in parts do
		if part ~= body and not parents[part] then
			local name = string.lower(part.Name)
			if
				head
				and part ~= head
				and (name:find("eye") or name:find("horn") or name:find("ear") or name:find("headmane"))
			then
				parents[part] = head
			elseif tail and part ~= tail and name:find("tail") then
				parents[part] = tail
			elseif part == head and neck then
				parents[part] = neck
			else
				parents[part] = body
			end
		end
	end
	-- Imported links can point through removed invisible proxies or contain loops.
	-- Every retained part gets exactly one path to the visible body.
	for _, part in parts do
		if part == body then
			continue
		end
		local seen, cursor = {}, part
		while cursor ~= body do
			if seen[cursor] or not parents[cursor] then
				parents[part] = body
				break
			end
			seen[cursor] = true
			cursor = parents[cursor]
		end
	end
	if names then
		for _, part in parts do
			local cursor, visited = part, {}
			while cursor ~= body and not visited[cursor] do
				visited[cursor] = true
				local group = roots[cursor]
				if group then
					table.insert(groups[group], part)
					break
				end
				cursor = parents[cursor] or body
			end
		end
	end
	return parents, groups, roots
end
local function decorate(rider: Model, body: BasePart, color: Color3)
	local saddle = Instance.new("Part")
	saddle.Name, saddle.Size, saddle.CFrame = "RiderSaddle", Vector3.new(0.78, 0.1, 0.76), CFrame.new(0, -0.34, 0)
	saddle.Color, saddle.Material = Color3.fromRGB(83, 51, 34), Enum.Material.Fabric
	passive(saddle)
	saddle.Parent = rider:FindFirstChild("MountAnimal")
	motor(body, saddle, saddle.Position)
	local blanket = saddle:Clone()
	blanket.Name, blanket.Size, blanket.CFrame, blanket.Color =
		"CivilizationSaddlecloth", Vector3.new(0.94, 0.055, 0.9), saddle.CFrame * CFrame.new(0, -0.065, 0), color
	for _, child in blanket:GetChildren() do
		if child:IsA("JointInstance") then
			child:Destroy()
		end
	end
	blanket.Parent = saddle.Parent
	motor(body, blanket, blanket.Position)
end
local function leopardPattern(animal: Model, parts: Parts, body: BasePart)
	local low, high = bounds({ body })
	local gold = Color3.fromRGB(192, 147, 66)
	for _, part in parts do
		if
			(part.Color.R > 0.8 and part.Color.G < 0.8)
			or (part.Color.R < 0.2 and part.Position.Z > low.Z - (high.Z - low.Z) * 0.15)
		then
			part.Color = gold
		end
	end
	for _, side in { -1, 1 } do
		for row = 1, 2 do
			for column = 1, 6 do
				local spot = Instance.new("Part")
				spot.Name, spot.Shape = "LeopardSpot", Enum.PartType.Cylinder
				spot.Size = Vector3.new(0.016, 0.065, 0.08)
				spot.Color, spot.Material = Color3.fromRGB(57, 38, 25), Enum.Material.SmoothPlastic
				spot.CFrame = CFrame.new(
					(if side < 0 then low.X else high.X) + side * 0.035,
					low.Y + (high.Y - low.Y) * (0.26 + row * 0.22),
					low.Z + (high.Z - low.Z) * (column / 7 + (row % 2) * 0.025)
				)
				passive(spot)
				spot.Parent = animal
				table.insert(parts, spot)
			end
		end
	end
	animal:SetAttribute("DerivedFromTigerTemplate", true)
end
local function featurePart(
	animal: Model,
	parts: Parts,
	parents: { [BasePart]: BasePart },
	parent: BasePart,
	name: string,
	size: Vector3,
	point: Vector3,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, CFrame.new(point)
	part.Color, part.Material = color, Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	passive(part)
	part.Parent = animal
	parents[part] = parent
	table.insert(parts, part)
	return part
end
local function blockBullLegs(animal: Model, parts: Parts, parents: { [BasePart]: BasePart }, body: BasePart)
	local points = {}
	for _, name in legNames.bull do
		local part = named(parts, name)
		assert(part, "Bull is missing an original limb root")
		table.insert(points, part.Position)
	end
	for index = #parts, 1, -1 do
		local part = parts[index]
		local name = string.lower(part.Name)
		if
			name:find("^upperfront")
			or name:find("^upperback")
			or name:find("^loverfoot")
			or name:find("^loverleg")
			or name:find("^lover leg")
		then
			table.remove(parts, index)
			part:Destroy()
		end
	end
	local low, high = bounds({ body })
	local height, width, depth = (high.Y - low.Y) * 0.62, (high.X - low.X) * 0.45, (high.Z - low.Z) * 0.22
	local top = low.Y + (high.Y - low.Y) * 0.18
	for index, name in legNames.bull do
		local point = points[index]
		local leg = featurePart(
			animal,
			parts,
			parents,
			body,
			name,
			Vector3.new(width, height, depth),
			Vector3.new(point.X, top - height / 2, point.Z),
			body.Color
		)
		leg:SetAttribute("BlockMountLeg", true)
		local hoof = featurePart(
			animal,
			parts,
			parents,
			leg,
			"BlockHoof_" .. groupNames[index],
			Vector3.new(width * 1.05, height * 0.18, depth * 1.05),
			Vector3.new(point.X, top - height * 1.04, point.Z),
			Color3.fromRGB(68, 61, 55)
		)
		hoof:SetAttribute("BlockMountHoof", true)
	end
end
local function animalFace(
	animal: Model,
	parts: Parts,
	parents: { [BasePart]: BasePart },
	template: string,
	head: BasePart
)
	local surfaces = { head }
	local oldEye = named(parts, "Eye")
	if oldEye then
		table.insert(surfaces, oldEye)
	end
	local low, high = bounds(surfaces)
	local width, height, depth = high.X - low.X, high.Y - low.Y, high.Z - low.Z
	local diameter = width * (if template == "wolf" then 0.15 else 0.09)
	for _, side in { -1, 1 } do
		local eye = featurePart(
			animal,
			parts,
			parents,
			head,
			if side < 0 then "MountEyeLeft" else "MountEyeRight",
			Vector3.new(width * 0.025, diameter, diameter),
			Vector3.new(
				(if side < 0 then low.X else high.X) + side * width * 0.016,
				low.Y + height * 0.64,
				low.Z + depth * 0.34
			),
			Color3.fromRGB(10, 10, 10)
		)
		eye:SetAttribute("MountFaceFeature", "eye")
	end
	if template == "rhino" then
		local snout = featurePart(
			animal,
			parts,
			parents,
			head,
			"RhinoBlockSnout",
			Vector3.new(width * 0.9, height * 0.48, depth * 0.5),
			Vector3.new((low.X + high.X) / 2, low.Y + height * 0.35, low.Z + depth * 0.02),
			head.Color
		)
		snout:SetAttribute("MountFaceFeature", "snout")
		for _, side in { -1, 1 } do
			local nostril = featurePart(
				animal,
				parts,
				parents,
				head,
				if side < 0 then "RhinoNostrilLeft" else "RhinoNostrilRight",
				Vector3.new(width * 0.09, height * 0.09, depth * 0.025),
				snout.Position + Vector3.new(side * snout.Size.X * 0.28, snout.Size.Y * 0.08, -snout.Size.Z / 2),
				Color3.fromRGB(20, 20, 19)
			)
			nostril:SetAttribute("MountFaceFeature", "nostril")
		end
	end
end
function MountedTroops.create(civilizationId: string): Model
	local definition = MountConfig.get(civilizationId)
	local bank = ServerStorage:FindFirstChild("MountTemplates")
	local source = bank and bank:FindFirstChild(definition.template)
	assert(source and source:IsA("Model"), "User animal template is unavailable")
	local animal = source:Clone()
	animal.Name = "MountAnimal"
	local parts, originalParents = sanitize(animal)
	local torsoParts = {}
	for _, part in parts do
		local name = string.lower(part.Name)
		if name:find("torso") or name == "boday" then
			table.insert(torsoParts, part)
		end
	end
	local body = largest(if #torsoParts > 0 then torsoParts else parts)
	local head = named(parts, "Head") or named(parts, "head") or named(parts, "Lion Head")
	local direction = if definition.template == "tiger"
		then Vector3.xAxis
		elseif definition.template == "crocodile" then -Vector3.zAxis
		elseif head then Vector3.new(head.Position.X - body.Position.X, 0, head.Position.Z - body.Position.Z)
		else Vector3.new(0, 0, -1)
	assert(direction.Magnitude > 0.01, "User animal has no horizontal facing")
	local normalization = CFrame.lookAt(body.Position, body.Position + direction.Unit)
	for _, part in parts do
		part.CFrame = normalization:ToObjectSpace(part.CFrame)
	end
	if definition.template == "bull" then
		blockBullLegs(animal, parts, originalParents, body)
	elseif definition.template == "wolf" or definition.template == "rhino" then
		assert(head, "Animal facial details need the original head")
		animalFace(animal, parts, originalParents, definition.template, head)
	end
	animal.WorldPivot = CFrame.identity
	local low, high = bounds(parts)
	local ratio = definition.bodyLength / (high.Z - low.Z)
	animal:ScaleTo(animal:GetScale() * ratio)
	local bodyLow, bodyHigh = bounds(if #torsoParts > 0 then torsoParts else { body })
	local authoredSaddle = named(parts, "Crouch") or named(parts, "SaddlePart")
	local seat = Vector3.new(0, bodyHigh.Y, 0)
	if definition.template == "lion" then
		-- The imported union is pitched around empty corners above the actual back.
		seat = Vector3.new(0, bodyHigh.Y - (bodyHigh.Y - bodyLow.Y) * 0.2, 0)
	end
	if authoredSaddle then
		local bottom, top = bounds({ authoredSaddle })
		-- The elephant howdah union includes its tall chair back. Its AABB top
		-- is not the sitting surface; seat the rider inside the central platform.
		local seatY = if definition.template == "elephant"
			then authoredSaddle.Position.Y + (top.Y - bottom.Y) * 0.1
			else top.Y
		seat = Vector3.new(authoredSaddle.Position.X, seatY, authoredSaddle.Position.Z)
	end
	for _, part in parts do
		part.CFrame -= seat + Vector3.new(0, 0.39, 0)
	end
	if definition.animal == "leopard" then
		leopardPattern(animal, parts, body)
	end
	local parents, groups, roots = anatomy(parts, originalParents, definition.template, body)
	local rider = OriginalTroops.create(civilizationId, "melee")
	rider:SetAttribute("MountedVisual", true)
	rider:SetAttribute("MountAnimal", definition.animal)
	rider:SetAttribute("MountTemplate", definition.template)
	rider:SetAttribute("MountStrideType", definition.strideType)
	rider:SetAttribute("MountBodyLength", definition.bodyLength)
	rider:SetAttribute("OriginalDisplayName", definition.animal:gsub("^%l", string.upper) .. " Rider")
	local root = rider:FindFirstChild("HumanoidRootPart")
	assert(root and root:IsA("BasePart"), "Original mounted rider root missing")
	animal.Parent = rider
	motor(root, body, body.Position, "body", 0, 0)
	local coreLow, coreHigh = bounds({ body })
	for _, part in parts do
		if part == body then
			continue
		end
		local parent = parents[part] or body
		local group = roots[part]
		local name, kind = string.lower(part.Name), nil
		local phase, amplitude = 0, 0
		local pivot = (parent.Position + part.Position) / 2
		if group then
			kind, amplitude =
				"leg",
				if definition.strideType == "reptile"
					then 0.58
					elseif definition.strideType == "heavy" then 0.25
					else 0.42
			phase = if definition.strideType == "camel"
				then (if group:find("Left") then 0 else math.pi)
				elseif definition.strideType == "heavy" then (if group == "frontLeft"
					then 0
					elseif group == "frontRight" then math.pi
					elseif group == "backLeft" then math.pi / 2
					else math.pi * 1.5)
				else (if group == "frontLeft" or group == "backRight" then 0 else math.pi)
			pivot = Vector3.new(
				part.Position.X,
				math.max(parent.Position.Y - parent.Size.Y * 0.2, part.Position.Y),
				part.Position.Z
			)
			if definition.template == "crocodile" then
				local side = if group:find("Left") then -1 else 1
				pivot = Vector3.new(
					body.Position.X + side * (coreHigh.X - coreLow.X) * 0.25,
					body.Position.Y - (coreHigh.Y - coreLow.Y) * 0.2,
					part.Position.Z
				)
			end
		elseif name:find("tail") or name == "tuff" or part:GetAttribute("MountAnatomyKind") == "tail" then
			kind, amplitude = "tail", 0.025
		elseif part == head or name == "neck" or part:GetAttribute("MountAnatomyKind") == "head" then
			kind, amplitude = "head", 0.025
		elseif name:find("lower") or name:find("knee") or name:find("loverleg") or name:find("lover leg") then
			kind, amplitude = "knee", 0.12
		end
		local joint = motor(parent, part, pivot, kind, phase, amplitude)
		if group then
			joint:SetAttribute("MountLimbSide", if group:find("Left") then -1 else 1)
		end
	end
	for group, members in groups do
		assert(#members > 0, "Mounted animal is missing a ground-contact limb")
		local foot, lowest = members[1], math.huge
		for _, member in members do
			local bottom = bounds({ member })
			if bottom.Y < lowest then
				lowest, foot = bottom.Y, member
			end
		end
		foot:SetAttribute("MountGroundContact", true)
		foot:SetAttribute("MountLimb", group)
	end
	local color = Color3.fromRGB(158, 42, 40)
	for _, civilization in Civilizations do
		if civilization.id == civilizationId then
			color = civilization.color
			break
		end
	end
	decorate(rider, body, color)
	OriginalTroops.attachMount(rider)
	return rider
end
function MountedTroops.pose(rig: Model, actor: OriginalTroops.PoseState, now: number, groundHeight: number?): ()
	OriginalTroops.pose(rig, actor, now, groundHeight)
end
return table.freeze(MountedTroops)

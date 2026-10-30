--!strict
-- Client visuals solve the same original joints without relying on replication order.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Interpolation = require(script.Parent.PoseInterpolation)
local MountKinematics = require(script.Parent.MountKinematics)
local Kinematics = {}
type Edge = { first: BasePart, second: BasePart, joint: JointInstance?, offset: CFrame? }
type Link = { parent: BasePart, child: BasePart, joint: JointInstance?, offset: CFrame?, reverse: boolean }
export type Rig = {
	model: Model,
	root: BasePart,
	parts: { BasePart },
	feet: { BasePart },
	joints: { [string]: Motor6D },
	links: { Link },
	mount: MountKinematics.Rig?,
}
function Kinematics.isAppearance(object: Instance): boolean
	return object:IsA("BasePart")
		or object:IsA("BodyColors")
		or object:IsA("DataModelMesh")
		or object:IsA("Clothing")
		or object:IsA("ShirtGraphic")
		or object:IsA("Decal")
		or object:IsA("Texture")
		or object:IsA("SurfaceAppearance")
end
function Kinematics.new(model: Model): Rig?
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local parts, feet, joints, graph = {}, {}, {}, {}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(parts, item)
			graph[item] = {}
			if
				(model:GetAttribute("MountedVisual") == true and item:GetAttribute("MountGroundContact") == true)
				or (
					model:GetAttribute("MountedVisual") ~= true
					and (item.Name == "Left Leg" or item.Name == "Right Leg")
				)
			then
				table.insert(feet, item)
			end
		elseif
			item:IsA("Motor6D")
			and item.Parent
			and (item.Parent.Name == "Torso" or item.Parent.Name == "HumanoidRootPart")
		then
			for _, name in Interpolation.jointNames do
				if item.Name == name then
					joints[name] = item
				end
			end
		end
	end
	if
		(model:GetAttribute("MountedVisual") == true and #feet < 4)
		or (model:GetAttribute("MountedVisual") ~= true and #feet ~= 2)
	then
		return nil
	end
	for _, name in Interpolation.jointNames do
		if not joints[name] then
			return nil
		end
	end
	local function add(first: BasePart, second: BasePart, joint: JointInstance?, offset: CFrame?)
		if not graph[first] or not graph[second] then
			return
		end
		local edge: Edge = { first = first, second = second, joint = joint, offset = offset }
		table.insert(graph[first], edge)
		table.insert(graph[second], edge)
	end
	for _, item in model:GetDescendants() do
		if item:IsA("JointInstance") then
			if item.Part0 and item.Part1 then
				add(item.Part0, item.Part1, item, nil)
			end
			item.Enabled = false
			if item:IsA("Motor6D") then
				item.Transform = CFrame.identity
			end
		elseif item:IsA("WeldConstraint") then
			local offset = item:GetAttribute("MiniatureWeldOffset")
			if typeof(offset) ~= "CFrame" then
				return nil
			end
			if item.Part0 and item.Part1 then
				add(item.Part0, item.Part1, nil, offset)
			end
			item.Enabled = false
		end
	end
	local links, pending, visited = {}, { root }, { [root] = true }
	local cursor = 1
	while cursor <= #pending do
		local parent = pending[cursor]
		cursor += 1
		for _, edge in graph[parent] do
			local reverse = edge.second == parent
			local child = if reverse then edge.first else edge.second
			if visited[child] then
				continue
			end
			visited[child] = true
			table.insert(pending, child)
			table.insert(
				links,
				{ parent = parent, child = child, joint = edge.joint, offset = edge.offset, reverse = reverse }
			)
		end
	end
	if #pending ~= #parts then
		return nil
	end
	local mount = MountKinematics.new(model)
	if model:GetAttribute("MountedVisual") == true and not mount then
		return nil
	end
	return { model = model, root = root, parts = parts, feet = feet, joints = joints, links = links, mount = mount }
end
local function sole(foot: BasePart): Vector3
	local lowest = Vector3.new(0, math.huge, 0)
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local point = foot.CFrame:PointToWorldSpace(foot.Size * Vector3.new(x, y, z) / 2)
				if point.Y < lowest.Y then
					lowest = point
				end
			end
		end
	end
	return lowest
end
local function ground(x: number, z: number, ignored: { Instance }, fallback: number): number
	local filter = RaycastParams.new()
	filter.FilterType, filter.RespectCanCollide = Enum.RaycastFilterType.Exclude, false
	local exclusions = table.clone(ignored)
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclusions, player.Character)
		end
	end
	for _ = 1, 12 do
		filter.FilterDescendantsInstances = exclusions
		local hit = Workspace:Raycast(Vector3.new(x, 32, z), Vector3.new(0, -96, 0), filter)
		if not hit then
			return fallback
		end
		local surface, ancestor = hit.Instance, hit.Instance.Parent
		local character
		while ancestor and ancestor ~= Workspace do
			if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
				character = ancestor
				break
			end
			ancestor = ancestor.Parent
		end
		if character then
			table.insert(exclusions, character)
		elseif
			surface:IsA("Terrain")
			or surface:IsA("BasePart")
				and (surface.CanCollide or surface:GetAttribute("OriginalTroopSupport") == true)
		then
			return hit.Position.Y
		else
			table.insert(exclusions, surface)
		end
	end
	return fallback
end
function Kinematics.apply(rig: Rig, snapshot: Interpolation.Snapshot, ignored: { Instance }?): ()
	for _, name in Interpolation.jointNames do
		rig.joints[name].C0 = snapshot.joints[name]
	end
	rig.root.CFrame = snapshot.root
	if rig.mount then
		MountKinematics.apply(rig.mount, snapshot.time, snapshot.speed or 0)
	end
	for _, link in rig.links do
		local relative
		if link.joint then
			relative = if link.reverse
				then link.joint.C1 * link.joint.C0:Inverse()
				else link.joint.C0 * link.joint.C1:Inverse()
		else
			local offset = link.offset or CFrame.identity
			relative = if link.reverse then offset:Inverse() else offset
		end
		link.child.CFrame = link.parent.CFrame * relative
	end
	local exclusions = ignored or { rig.model }
	local lift = -math.huge
	for _, foot in rig.feet do
		local point = sole(foot)
		local height = ground(point.X, point.Z, exclusions, snapshot.ground)
		lift = math.max(lift, height + 0.005 - point.Y)
	end
	local delta = Vector3.new(0, lift, 0)
	for _, object in rig.parts do
		object.CFrame += delta
	end
end
return table.freeze(Kinematics)

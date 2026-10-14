--!strict

local ServerStorage = game:GetService("ServerStorage")
local NPCModelTemplates = {}
local warned: { [string]: boolean } = {}
local BODY_NAMES = {"HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
local PAIRS = {
	{"HumanoidRootPart", "Torso", "RootJoint"}, {"Torso", "Head", "Neck"},
	{"Torso", "Right Arm", "Right Shoulder"}, {"Torso", "Left Arm", "Left Shoulder"},
	{"Torso", "Right Leg", "Right Hip"}, {"Torso", "Left Leg", "Left Hip"},
}

local function isJoint(object: Instance): boolean
	return object:IsA("JointInstance") or object:IsA("WeldConstraint")
end
local function internalJoint(object, rig: Model): boolean
	return object.Part0 ~= nil and object.Part1 ~= nil and object.Part0 ~= object.Part1
		and object.Part0:IsDescendantOf(rig) and object.Part1:IsDescendantOf(rig)
end
local function pairMatches(joint, first: BasePart, second: BasePart): boolean
	return (joint.Part0 == first and joint.Part1 == second) or (joint.Part0 == second and joint.Part1 == first)
end

function NPCModelTemplates.prepare(template: Model): Model?
	if typeof(template) ~= "Instance" or not template:IsA("Model") then return nil end
	local ok, rig = pcall(function() return template:Clone() end)
	if not ok or not rig then return nil end
	-- Work exclusively on an unparented clone, before imported code can execute.
	for _, object in rig:GetDescendants() do
		if object:IsA("LuaSourceContainer") or object:IsA("Tool") or object:IsA("ForceField")
			or object:IsA("BodyMover") or (object:IsA("Constraint") and not object:IsA("WeldConstraint")) then
			object:Destroy()
		elseif isJoint(object) and not internalJoint(object, rig) then
			object:Destroy()
		elseif object:IsA("ObjectValue") and object.Value and object.Value ~= rig and not object.Value:IsDescendantOf(rig) then
			object.Value = nil
		end
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local body = {}
	for _, name in BODY_NAMES do
		local part = rig:FindFirstChild(name)
		if not part or not part:IsA("BasePart") then rig:Destroy(); return nil end
		body[name] = part
	end
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then rig:Destroy(); return nil end

	-- Some supplied R6 models use body Welds. Convert only established body
	-- connections, preserving their pose and removing competing constraints.
	local joints = {}
	local bodyMotors = {}
	for _, object in rig:GetDescendants() do
		if isJoint(object) then table.insert(joints, object) end
	end
	for _, definition in PAIRS do
		local first, second = body[definition[1]], body[definition[2]]
		local matching, motor = {}, nil
		for _, object in joints do
			if object.Parent and pairMatches(object, first, second) then
				table.insert(matching, object)
				if object:IsA("Motor6D") and not motor then motor = object end
			end
		end
		if #matching == 0 then rig:Destroy(); return nil end
		if not motor then
			local existing = matching[1]
			motor = Instance.new("Motor6D")
			motor.Part0, motor.Part1 = first, second
			if existing:IsA("JointInstance") then
				if existing.Part0 == first then motor.C0, motor.C1 = existing.C0, existing.C1
				else motor.C0, motor.C1 = existing.C1, existing.C0 end
			else
				motor.C0, motor.C1 = first.CFrame:ToObjectSpace(second.CFrame), CFrame.identity
			end
		elseif motor.Part0 ~= first then
			motor.Part0, motor.Part1 = first, second
			motor.C0, motor.C1 = motor.C1, motor.C0
		end
		for _, object in matching do if object ~= motor then object:Destroy() end end
		motor.Name = definition[3]
		motor.Parent = first
		bodyMotors[motor] = true
	end

	local graph, parts = {}, {}
	local bodySet = {}
	for _, part in body do bodySet[part] = true end
	for _, object in rig:GetDescendants() do
		if object:IsA("BasePart") then
			table.insert(parts, object)
			graph[object] = {}
			object.Anchored = false
			object.CanCollide = object == body.Torso
			object.CanTouch = false
			object.CanQuery = bodySet[object] == true
			object.Massless = object ~= body.HumanoidRootPart
			if object == body.HumanoidRootPart then object.RootPriority = 127; object.Transparency = 1 end
		elseif object:IsA("Humanoid") and object ~= humanoid then
			object:Destroy()
		end
	end
	for _, object in rig:GetDescendants() do
		if isJoint(object) then
			if not internalJoint(object, rig) then object:Destroy(); continue end
			if bodySet[object.Part0] and bodySet[object.Part1] and not bodyMotors[object] then
				object:Destroy()
				continue
			end
			object.Enabled = true
			table.insert(graph[object.Part0], object.Part1)
			table.insert(graph[object.Part1], object.Part0)
			if object:IsA("Motor6D") then object:SetAttribute("RestC0", object.C0) end
		end
	end
	local connected = {}
	local function visit(start: BasePart)
		local pending = {start}
		while #pending > 0 do
			local part = table.remove(pending) :: BasePart
			if connected[part] then continue end
			connected[part] = true
			for _, neighbor in graph[part] do table.insert(pending, neighbor) end
		end
	end
	visit(body.HumanoidRootPart)
	for _, part in parts do
		if connected[part] then continue end
		local nearest, distance = nil, math.huge
		for _, target in body do
			local separation = (part.Position - target.Position).Magnitude
			if separation < distance then nearest, distance = target, separation end
		end
		local weld = Instance.new("WeldConstraint")
		weld.Name = "TemplateCosmeticWeld"
		weld.Part0, weld.Part1 = nearest, part
		weld.Parent = part
		visit(part)
	end
	humanoid.MaxHealth, humanoid.Health = 100, 100
	humanoid.BreakJointsOnDeath, humanoid.RequiresNeck = false, true
	humanoid.PlatformStand, humanoid.Sit, humanoid.AutoRotate = false, false, true
	rig.PrimaryPart = body.HumanoidRootPart
	-- Imported character bookkeeping must not suppress our authoritative gear.
	for _, attribute in {"EquipmentCivilization", "EquippedWeaponLevel", "EquippedArmorLevel", "EquipmentBaseHealth"} do
		rig:SetAttribute(attribute, nil)
	end
	return rig
end

function NPCModelTemplates.clone(civilizationId: string): Model?
	local templates = ServerStorage:FindFirstChild("NPCTemplates")
	local source = if templates then templates:FindFirstChild(civilizationId) else nil
	if not source then return nil end
	local rig = if source:IsA("Model") then NPCModelTemplates.prepare(source) else nil
	if not rig and not warned[civilizationId] then
		warned[civilizationId] = true
		warn("Unsupported NPC template for " .. civilizationId .. "; using procedural warrior")
	end
	if rig then
		rig:SetAttribute("CustomMeleeModel", true)
		rig:SetAttribute("TemplateCivilizationId", civilizationId)
	end
	return rig
end

return NPCModelTemplates

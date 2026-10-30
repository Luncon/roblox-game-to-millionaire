--!strict
-- The production rig builder/pose functions operate only on fresh visual clones.
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Civilizations = require(ReplicatedStorage.MiniatureGame.Civilizations)
local PoseCodec = require(ReplicatedStorage.MiniatureGame.PoseCodec)
local RigKinematics = require(ReplicatedStorage.MiniatureGame.RigKinematics)
local MountKinematics = require(ReplicatedStorage.MiniatureGame.MountKinematics)
local WarriorRig = require(ServerStorage.OriginalArmy.WarriorRig)
local OriginalTroops = {}
export type Role = "melee" | "ranged" | "medic"
export type PoseState = {
	x: number,
	z: number,
	headingX: number,
	headingZ: number,
	phase: string,
	combatPhase: string?,
	phaseStartedAt: number?,
	phaseDuration: number?,
	moving: boolean?,
	lastHitAt: number?,
	lastHealAt: number?,
	bandageThrownAt: number?,
	targetId: string?,
}
type Link = { parent: BasePart, child: BasePart, joint: JointInstance?, offset: CFrame?, reverse: boolean }
type Edge = { first: BasePart, second: BasePart, joint: JointInstance?, offset: CFrame? }
type RigRecord = {
	root: BasePart,
	humanoid: Humanoid,
	parts: { BasePart },
	links: { Link },
	feet: { BasePart },
	animated: { [Motor6D]: CFrame },
	scale: number,
	phase: string?,
	began: number,
	lastPosition: Vector3?,
	lastTime: number?,
	velocity: Vector3,
	mount: MountKinematics.Rig?,
}
local records: { [Model]: RigRecord? } = {}
local civilizations = {}
for _, civilization in Civilizations do
	civilizations[civilization.id] = civilization
end
local scale, clearance = 0.25, 0.005
local collisionGroup = "MiniatureOriginalTroops"
local animatedNames = {
	RootJoint = true,
	Neck = true,
	["Right Shoulder"] = true,
	["Left Shoulder"] = true,
	["Right Hip"] = true,
	["Left Hip"] = true,
}
local function scaledFrame(frame: CFrame, ratio: number): CFrame
	return CFrame.new(frame.Position * ratio) * (frame - frame.Position)
end
local function passive(record: RigRecord)
	local humanoid = record.humanoid
	humanoid.EvaluateStateMachine, humanoid.AutoRotate, humanoid.PlatformStand = false, false, true
	humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = 0, 0, 0
	humanoid.RequiresNeck, humanoid.BreakJointsOnDeath = false, false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, object in record.parts do
		object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		object.AssemblyLinearVelocity, object.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		object.CollisionGroup = collisionGroup
	end
end
local function buildRecord(rig: Model, animated: { [Motor6D]: CFrame }): RigRecord
	local root = rig:FindFirstChild("HumanoidRootPart")
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	assert(root and root:IsA("BasePart") and humanoid, "Original troop rig is incomplete")
	local parts, feet, graph = {}, {}, {}
	for _, item in rig:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(parts, item)
			graph[item] = {}
			if
				(rig:GetAttribute("MountedVisual") == true and item:GetAttribute("MountGroundContact") == true)
				or (rig:GetAttribute("MountedVisual") ~= true and (item.Name == "Right Leg" or item.Name == "Left Leg"))
			then
				table.insert(feet, item)
			end
		end
	end
	assert(
		if rig:GetAttribute("MountedVisual") == true then #feet >= 4 else #feet == 2,
		"Original troop needs its anatomical ground contacts"
	)
	local function edge(first: BasePart, second: BasePart, joint: JointInstance?, offset: CFrame?)
		if not graph[first] or not graph[second] then
			return
		end
		local connection: Edge = { first = first, second = second, joint = joint, offset = offset }
		table.insert(graph[first], connection)
		table.insert(graph[second], connection)
	end
	for _, item in rig:GetDescendants() do
		if item:IsA("JointInstance") then
			local first, second = item.Part0, item.Part1
			if first and second then
				edge(first, second, item, nil)
			end
			-- Physics cannot re-solve or rewrite the manually posed clone.
			item.Enabled = false
			if item:IsA("Motor6D") then
				item.Transform = CFrame.identity
			end
		elseif item:IsA("WeldConstraint") then
			local first, second = item.Part0, item.Part1
			if first and second then
				local offset = first.CFrame:ToObjectSpace(second.CFrame)
				item:SetAttribute("MiniatureWeldOffset", offset)
				edge(first, second, nil, offset)
			end
			item.Enabled = false
		end
	end
	local links, visited, pending = {}, { [root] = true }, { root }
	local cursor = 1
	while cursor <= #pending do
		local parent = pending[cursor]
		cursor += 1
		for _, connection in graph[parent] do
			local reverse = connection.second == parent
			local child = if reverse then connection.first else connection.second
			if visited[child] then
				continue
			end
			visited[child] = true
			table.insert(pending, child)
			table.insert(links, {
				parent = parent,
				child = child,
				joint = connection.joint,
				offset = connection.offset,
				reverse = reverse,
			})
		end
	end
	assert(#pending == #parts, "Original troop has disconnected cosmetic geometry")
	local record: RigRecord = {
		root = root,
		humanoid = humanoid,
		parts = parts,
		links = links,
		feet = feet,
		animated = animated,
		scale = scale,
		phase = nil,
		began = 0,
		lastPosition = nil,
		lastTime = nil,
		velocity = Vector3.zero,
		mount = MountKinematics.new(rig),
	}
	passive(record)
	return record
end
local function stampReadiness(rig: Model, record: RigRecord)
	rig:SetAttribute("PosePartCount", #record.parts)
	local visualCount = 0
	for _, object in rig:GetDescendants() do
		if RigKinematics.isAppearance(object) then
			visualCount += 1
		end
	end
	rig:SetAttribute("PoseVisualCount", visualCount)
end
-- Called only after a fresh original rider receives its sanitized, connected animal.
function OriginalTroops.attachMount(rig: Model): ()
	local previous = records[rig]
	assert(previous and rig:GetAttribute("MountedVisual") == true, "Mounted geometry requires an original rider")
	local record = buildRecord(rig, previous.animated)
	assert(record.mount, "Mounted geometry has no complete anatomical gait joints")
	records[rig] = record
	stampReadiness(rig, record)
end
function OriginalTroops.create(civilizationId: string, role: Role, isNeutral: boolean?): Model
	local civilization = civilizations[civilizationId]
	assert(civilization or isNeutral == true, "Unknown original troop civilization")
	assert(role == "melee" or role == "ranged" or role == "medic", "Unknown original troop role")
	assert(not isNeutral or role ~= "medic", "Original neutral roster has no medic")
	if not PhysicsService:IsCollisionGroupRegistered(collisionGroup) then
		PhysicsService:RegisterCollisionGroup(collisionGroup)
	end
	PhysicsService:CollisionGroupSetCollidable(collisionGroup, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(collisionGroup, collisionGroup, false)
	local kind = if role == "melee" then "warrior" else role
	local rig = if isNeutral
		then WarriorRig.createNeutral(CFrame.identity, kind)
		else WarriorRig.create(
			civilization,
			CFrame.identity,
			0,
			0,
			{ weaponLevel = 1, armorLevel = 1, skillLevel = 0, shieldLevel = 0 },
			kind
		)
	local animated: { [Motor6D]: CFrame } = {}
	for _, object in rig:GetDescendants() do
		if
			object:IsA("LuaSourceContainer")
			or object:IsA("Animator")
			or object:IsA("AnimationController")
			or object:IsA("BodyMover")
			or object:IsA("ForceField")
		then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		elseif
			object:IsA("Motor6D")
			and animatedNames[object.Name]
			and object.Parent
			and (object.Parent.Name == "Torso" or object.Parent.Name == "HumanoidRootPart")
		then
			local rest = object:GetAttribute("RestC0")
			animated[object] = if typeof(rest) == "CFrame" then rest else object.C0
		elseif object:IsA("Tool") then
			object.Enabled, object.CanBeDropped, object.RequiresHandle = false, false, false
			object:SetAttribute("VisualOnly", true)
		end
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "Original troop has no clothing Humanoid")
	humanoid.EvaluateStateMachine, humanoid.AutoRotate, humanoid.PlatformStand = false, false, true
	rig:ScaleTo(rig:GetScale() * scale)
	for motor, rest in animated do
		motor:SetAttribute("RestC0", rest)
	end
	local record = buildRecord(rig, animated)
	records[rig] = record
	rig.Destroying:Once(function()
		records[rig] = nil
	end)
	rig:SetAttribute("OriginalArmyVisual", true)
	stampReadiness(rig, record)
	rig:SetAttribute("OriginalDisplayName", rig.Name)
	rig:SetAttribute("OriginalRigScale", scale)
	rig:SetAttribute("OriginalAnimationStyle", WarriorRig.combatStyle(rig))
	rig:SetAttribute("SourceCivilizationId", if isNeutral then "neutral" else civilizationId)
	rig:SetAttribute("CivilizationId", if isNeutral then "neutral" else civilizationId)
	rig:SetAttribute("NeutralDefense", isNeutral == true)
	rig:SetAttribute("CombatActor", true)
	rig:SetAttribute("VisualOnly", true)
	return rig
end
local function supportHeight(x: number, z: number, rig: Model): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = false
	local ignored: { Instance } = { rig }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignored, player.Character)
		end
	end
	local scene = Workspace:FindFirstChild("MiniatureSandbox")
	local actors = scene and scene:FindFirstChild("BattleActors")
	if actors then
		table.insert(ignored, actors)
	end
	for _ = 1, 12 do
		params.FilterDescendantsInstances = ignored
		local hit = Workspace:Raycast(Vector3.new(x, 32, z), Vector3.new(0, -96, 0), params)
		if not hit then
			return 0
		end
		local surface = hit.Instance
		local ancestor = surface.Parent
		local character: Model? = nil
		while ancestor and ancestor ~= Workspace do
			if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
				character = ancestor
				break
			end
			ancestor = ancestor.Parent
		end
		if character then
			table.insert(ignored, character)
			continue
		end
		if
			surface:IsA("Terrain")
			or (
				surface:IsA("BasePart") and (surface.CanCollide or surface:GetAttribute("OriginalTroopSupport") == true)
			)
		then
			return hit.Position.Y
		end
		table.insert(ignored, surface)
	end
	return 0
end
local function solePoint(foot: BasePart): Vector3
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
function OriginalTroops.pose(rig: Model, actor: PoseState, now: number, groundHeight: number?): ()
	local record = records[rig]
	assert(record, "Original troop pose requires an adapter-created rig")
	passive(record)
	local phase = actor.combatPhase or actor.phase
	if phase ~= "windup" and phase ~= "contact" and phase ~= "recovery" then
		phase = "idle"
	end
	if record.phase ~= phase then
		record.phase, record.began = phase, actor.phaseStartedAt or now
	end
	if actor.phaseStartedAt then
		record.began = actor.phaseStartedAt
	end
	local serverNow = Workspace:GetServerTimeNow()
	rig:SetAttribute("CombatPhase", phase)
	rig:SetAttribute("CombatPhaseStartedAt", serverNow - (now - record.began))
	rig:SetAttribute("CombatPhaseDuration", actor.phaseDuration or 0.35)
	local moving = actor.moving == true or actor.phase == "moving"
	rig:SetAttribute(
		"WarriorState",
		if phase ~= "idle" then "Fighting" elseif moving then "Advancing" elseif actor.targetId then "Waiting" else "Idle"
	)
	rig:SetAttribute("LastHitAt", if actor.lastHitAt then serverNow - (now - actor.lastHitAt) else nil)
	rig:SetAttribute("LastHealAt", if actor.lastHealAt then serverNow - (now - actor.lastHealAt) else nil)
	rig:SetAttribute(
		"BandageThrownAt",
		if actor.bandageThrownAt then serverNow - (now - actor.bandageThrownAt) else nil
	)

	if actor.phase == "heal" and not actor.bandageThrownAt then
		rig:SetAttribute("BandageThrownAt", serverNow - (now - (actor.phaseStartedAt or record.began)))
	end
	local rootPoint = Vector3.new(actor.x, 0, actor.z)
	local direction = Vector3.new(actor.headingX, 0, actor.headingZ)
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, 1)
	end
	if record.lastPosition and record.lastTime and now > record.lastTime then
		record.velocity = (rootPoint - record.lastPosition) / (now - record.lastTime)
	end
	record.root.CFrame = CFrame.lookAt(rootPoint, rootPoint + direction)
	-- The original gait samples local velocity for strafing. Supply only that
	-- instantaneous input; every part remains anchored and velocity is reset.
	record.root.AssemblyLinearVelocity = record.velocity
	WarriorRig.animate(rig, now, moving and not record.mount, phase == "contact")
	record.root.AssemblyLinearVelocity = Vector3.zero
	record.lastPosition, record.lastTime = rootPoint, now
	for motor in record.animated do
		motor.C0 = scaledFrame(motor.C0, record.scale)
		if record.mount and (motor.Name == "Right Hip" or motor.Name == "Left Hip") then
			local rest = scaledFrame(record.animated[motor], record.scale)
			local side = if motor.Name == "Right Hip" then 1 else -1
			motor.C0 = CFrame.new(rest.Position) * CFrame.Angles(math.rad(65), 0, side * math.rad(16)) * rest.Rotation
		end
		motor.Transform = CFrame.identity
	end
	local mountSpeed = if record.mount
		then (if moving then math.clamp(record.velocity.Magnitude, 0, 32) else 0)
		else nil
	if record.mount then
		MountKinematics.apply(record.mount, serverNow, mountSpeed or 0)
	end
	for _, link in record.links do
		local relative
		if link.joint then
			local joint = link.joint
			relative = if link.reverse then joint.C1 * joint.C0:Inverse() else joint.C0 * joint.C1:Inverse()
		else
			local offset = link.offset or CFrame.identity
			relative = if link.reverse then offset:Inverse() else offset
		end
		link.child.CFrame = link.parent.CFrame * relative
	end
	local lift = -math.huge
	local targetGround = groundHeight or 0
	for _, foot in record.feet do
		local point = solePoint(foot)
		local height = if groundHeight ~= nil then groundHeight else supportHeight(point.X, point.Z, rig)
		local candidate = height - point.Y + clearance
		if candidate > lift then
			lift, targetGround = candidate, height
		end
	end
	local delta = Vector3.new(0, lift, 0)
	for _, object in record.parts do
		object.CFrame += delta
	end
	local lowest = math.huge
	for _, foot in record.feet do
		lowest = math.min(lowest, solePoint(foot).Y)
	end
	rig:SetAttribute("OriginalGroundHeight", targetGround)
	rig:SetAttribute("OriginalSoleY", lowest)
	rig:SetAttribute("OriginalPosePhase", phase)
	local joints = {}
	for motor in record.animated do
		joints[motor.Name] = motor.C0
	end
	local life = rig:GetAttribute("Life")
	rig:SetAttribute(
		"PoseSnapshot",
		PoseCodec.encode({
			time = serverNow,
			life = if typeof(life) == "number" then life else 0,
			root = record.root.CFrame,
			joints = joints,
			ground = targetGround,
			speed = mountSpeed,
		})
	)
end
return table.freeze(OriginalTroops)

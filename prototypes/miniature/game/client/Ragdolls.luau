--!strict
-- Local cosmetic physics only. Server death metadata is consumed by TroopRenderer.
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Config = require(Replicated.MiniatureGame.RagdollConfig)
local Ragdolls = {}
export type Notice = { actorId: string, life: number, time: number }
export type Controller = {
	folder: Folder,
	spawn: (Model, Notice, Vector3?) -> Model?,
	clear: () -> (),
	destroy: () -> (),
}
type Support = { model: Part, references: number }
type Entry = { model: Model, born: number, parts: number, supports: { BasePart }, fading: boolean }
local bodyNames =
	{ Head = true, Torso = true, ["Right Arm"] = true, ["Left Arm"] = true, ["Right Leg"] = true, ["Left Leg"] = true }
local articulation =
	{ Neck = true, ["Right Shoulder"] = true, ["Left Shoulder"] = true, ["Right Hip"] = true, ["Left Hip"] = true }
local function weld(parent: Instance, first: BasePart, second: BasePart)
	local joint = Instance.new("WeldConstraint")
	joint.Name, joint.Part0, joint.Part1, joint.Parent = "CorpseRigid", first, second, parent
end
local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end
function Ragdolls.start(suffix: string?): Controller
	local folder = Instance.new("Folder")
	folder.Name = "MiniatureRagdolls" .. (suffix or "")
	folder.Parent = Workspace
	local supportFolder = Instance.new("Folder")
	supportFolder.Name, supportFolder.Parent = "Supports", folder
	local entries: { Entry } = {}
	local supports: { [BasePart]: Support } = {}
	local partCount, supportCount, spawned, evicted = 0, 0, 0, 0
	local stopped = false
	local seen, seenOrder = {}, {}
	local function metrics()
		folder:SetAttribute("ActiveCorpses", #entries)
		folder:SetAttribute("ActiveParts", partCount + supportCount)
		folder:SetAttribute("ActiveSupports", supportCount)
		folder:SetAttribute("Spawned", spawned)
		folder:SetAttribute("Evicted", evicted)
	end
	local function remove(index: number)
		local entry = table.remove(entries, index)
		partCount -= entry.parts
		for _, source in entry.supports do
			local support = supports[source]
			if support then
				support.references -= 1
				if support.references == 0 then
					support.model:Destroy()
					supports[source] = nil
					supportCount -= 1
				end
			end
		end
		entry.model:Destroy()
		metrics()
	end
	local function supportFor(model: Model, root: BasePart): { BasePart }
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances, params.MaxParts =
			Enum.RaycastFilterType.Exclude, { folder, model }, 64
		params.CollisionGroup = "Default"
		local used = {}
		for _, source in Workspace:GetPartBoundsInBox(CFrame.new(root.Position), Vector3.new(14, 12, 14), params) do
			if source:GetAttribute("OriginalTroopSupport") ~= true or source.CanCollide then
				continue
			end
			local support = supports[source]
			if not support and supportCount < Config.maxSupports and partCount + supportCount < Config.maxParts then
				local proxy = Instance.new("Part")
				proxy.Name, proxy.Size, proxy.CFrame = "CorpseSupport", source.Size, source.CFrame
				if source:IsA("Part") then
					proxy.Shape = source.Shape
				end
				proxy.Anchored, proxy.CanCollide, proxy.CanTouch, proxy.CanQuery = true, true, false, false
				proxy.Transparency, proxy.CollisionGroup = 1, Config.supportCollisionGroup
				proxy:SetAttribute("CorpseSupport", true)
				proxy.Parent = supportFolder
				support = { model = proxy, references = 0 }
				supports[source] = support
				supportCount += 1
			end
			if support then
				support.references += 1
				table.insert(used, source)
			end
		end
		return used
	end
	local function spawn(model: Model, notice: Notice, inheritedVelocity: Vector3?): Model?
		if stopped then
			model:Destroy()
			return nil
		end
		local key = notice.actorId .. ":" .. notice.life
		if seen[key] then
			model:Destroy()
			return nil
		end
		local parts, joints, collisionParts = {}, {}, {}
		local root = model:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			model:Destroy()
			return nil
		end
		local sockets = 0
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				table.insert(parts, item)
				if item.Parent == model and bodyNames[item.Name] then
					collisionParts[item] = if item.Name == "Torso" then 0 else 4
				end
			elseif item:IsA("JointInstance") or item:IsA("WeldConstraint") then
				table.insert(joints, item)
			end
		end
		if #parts > Config.maxPartsPerCorpse then
			model:Destroy()
			return nil
		end
		local connections = Instance.new("Folder")
		connections.Name, connections.Parent = "CorpsePhysics", model
		for _, joint in joints do
			local first, second = joint.Part0, joint.Part1
			joint.Enabled = false
			if not first or not second or not first:IsDescendantOf(model) or not second:IsDescendantOf(model) then
				continue
			end
			if joint:IsA("Motor6D") and joint:GetAttribute("MountJointKind") == "body" then
				collisionParts[second] = 1
			end
			local anatomical = joint:IsA("Motor6D")
				and (
					articulation[joint.Name] == true
					or (joint:GetAttribute("MountJoint") == true and joint:GetAttribute("MountJointKind") ~= "body")
				)
			if anatomical and joint:IsA("Motor6D") and sockets < Config.maxSockets then
				local frame = first.CFrame * joint.C0
				local a, b = Instance.new("Attachment"), Instance.new("Attachment")
				a.Name, b.Name = "CorpseAnchor0", "CorpseAnchor1"
				a.CFrame, b.CFrame = first.CFrame:ToObjectSpace(frame), second.CFrame:ToObjectSpace(frame)
				a.Parent, b.Parent = first, second
				local socket = Instance.new("BallSocketConstraint")
				socket.Name, socket.Attachment0, socket.Attachment1 = "CorpseSocket", a, b
				socket.LimitsEnabled, socket.TwistLimitsEnabled = true, true
				socket.UpperAngle = if joint.Name == "Neck" then 35 else 65
				socket.TwistLowerAngle, socket.TwistUpperAngle = -35, 35
				socket.MaxFrictionTorque, socket.Restitution, socket.Parent = 0.08, 0, connections
				collisionParts[second] = math.min(
					collisionParts[second] or 10,
					if joint:GetAttribute("MountJointKind") == "leg"
						then 2
						elseif joint:GetAttribute("MountJointKind") == "knee" then 3
						else 5
				)
				sockets += 1
			else
				weld(connections, first, second)
			end
		end
		local colliders, ordered = {}, {}
		for part in collisionParts do
			table.insert(ordered, part)
		end
		table.sort(ordered, function(a, b)
			return if collisionParts[a] == collisionParts[b]
				then a:GetFullName() < b:GetFullName()
				else collisionParts[a] < collisionParts[b]
		end)
		for _, part in ordered do
			if #colliders >= Config.maxColliders then
				break
			end
			local proxy = Instance.new("Part")
			proxy.Name, proxy.CFrame = "CorpseCollider", part.CFrame
			proxy.Size = Vector3.new(
				math.clamp(part.Size.X * 0.75, 0.12, 1.8),
				math.clamp(part.Size.Y * 0.75, 0.12, 1.8),
				math.clamp(part.Size.Z * 0.75, 0.12, 1.8)
			)
			proxy.Transparency, proxy.CanCollide, proxy.CanTouch, proxy.CanQuery = 1, true, false, false
			proxy.CollisionGroup = Config.corpseCollisionGroup
			proxy.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.7, 0, 1, 1)
			proxy:SetAttribute("CorpseCollider", true)
			proxy.Parent = connections
			weld(connections, part, proxy)
			table.insert(colliders, proxy)
		end
		local cost = #parts + #colliders
		if cost > Config.maxParts then
			model:Destroy()
			return nil
		end
		while
			#entries > 0
			and (
				#entries >= Config.maxCorpses
				or partCount + supportCount + cost + Config.maxSupports > Config.maxParts
			)
		do
			evicted += 1
			remove(1)
		end
		for _, part in parts do
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless =
				false, false, false, false, true
			part.CollisionGroup = Config.corpseCollisionGroup
		end
		for _, object in model:GetDescendants() do
			if
				object:IsA("LuaSourceContainer")
				or object:IsA("Animator")
				or object:IsA("BillboardGui")
				or object:IsA("Highlight")
			then
				object:Destroy()
			elseif object:IsA("Humanoid") then
				object.EvaluateStateMachine, object.AutoRotate, object.PlatformStand, object.BreakJointsOnDeath, object.RequiresNeck =
					false, false, true, false, false
				object.WalkSpeed, object.JumpPower, object.JumpHeight = 0, 0, 0
			elseif object:IsA("Tool") then
				object.Enabled, object.CanBeDropped = false, false
			end
		end
		model.Name = notice.actorId .. ":corpse:" .. notice.life
		model:SetAttribute("CorpseVisual", true)
		model:SetAttribute("ClientTroopVisual", nil)
		model:SetAttribute("CombatActor", false)
		model:SetAttribute("Alive", false)
		model:SetAttribute("ActorId", notice.actorId)
		model:SetAttribute("Life", notice.life)
		model:SetAttribute("CorpseSockets", sockets)
		model:SetAttribute("CorpseColliders", #colliders)
		model.Parent = folder
		local velocity = inheritedVelocity or Vector3.zero
		if not finite(velocity.X) or not finite(velocity.Y) or not finite(velocity.Z) then
			velocity = Vector3.zero
		end
		if velocity.Magnitude > 12 then
			velocity = velocity.Unit * 12
		end
		for _, proxy in colliders do
			proxy.AssemblyLinearVelocity = velocity
		end
		local torso = model:FindFirstChild("Torso")
		if torso and torso:IsA("BasePart") then
			torso:ApplyImpulse((root.CFrame.RightVector * 0.8 + Vector3.new(0, 0.15, 0)) * torso.AssemblyMass)
		end
		partCount += cost
		local used = supportFor(model, root)
		table.insert(entries, { model = model, born = os.clock(), parts = cost, supports = used, fading = false })
		seen[key] = true
		table.insert(seenOrder, key)
		while #seenOrder > Config.maxCorpses * 4 do
			seen[table.remove(seenOrder, 1)] = nil
		end
		spawned += 1
		metrics()
		return model
	end
	local elapsed = 0
	local heartbeat = Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		for index = #entries, 1, -1 do
			local entry = entries[index]
			local age = os.clock() - entry.born
			if age >= Config.lifetimeSeconds or entry.model.Parent ~= folder then
				remove(index)
			elseif age >= Config.lifetimeSeconds - Config.fadeSeconds and not entry.fading then
				entry.fading = true
				for _, item in entry.model:GetDescendants() do
					if item:IsA("BasePart") or item:IsA("Decal") then
						TweenService:Create(item, TweenInfo.new(Config.fadeSeconds), { Transparency = 1 }):Play()
					end
				end
			end
		end
	end)
	local function clear()
		while #entries > 0 do
			remove(#entries)
		end
		table.clear(seen)
		table.clear(seenOrder)
	end
	local function destroy()
		if stopped then
			return
		end
		stopped = true
		heartbeat:Disconnect()
		while #entries > 0 do
			remove(#entries)
		end
		folder:Destroy()
	end
	metrics()
	return { folder = folder, spawn = spawn, clear = clear, destroy = destroy }
end
return table.freeze(Ragdolls)

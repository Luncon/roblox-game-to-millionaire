--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.WarriorConfig)
local Tracks = require(ReplicatedStorage.Shared.UpgradeTracks)
local Ranged = require(ReplicatedStorage.Shared.RangedConfig)
local Equipment = require(script.Parent.Equipment)
local NPCModelTemplates = require(script.Parent.NPCModelTemplates)
local WarriorRig = {}

local function body(model: Model, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position, part.Color = name, size, position, color
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.CanCollide = name == "Torso"
	part.CanTouch = false
	part.Massless = name ~= "HumanoidRootPart"
	part.Parent = model
	return part
end

local function joint(parent: BasePart, name: string, child: BasePart, c0: CFrame, c1: CFrame)
	local motor = Instance.new("Motor6D")
	motor.Name, motor.Part0, motor.Part1 = name, parent, child
	motor.C0, motor.C1 = c0, c1
	motor:SetAttribute("RestC0", c0)
	motor.Parent = parent
end

function WarriorRig.update(rig: Model, civilization, state)
	if not Equipment.applyWarrior(rig, civilization, state) then return end
	local weaponLevel, armorLevel = state.weaponLevel or 1, state.armorLevel or 1
	rig:SetAttribute("WeaponLevel", weaponLevel)
	rig:SetAttribute("ArmorLevel", armorLevel)
	local kind = rig:GetAttribute("WarriorClass") or "warrior"
	local damage = Tracks.weapon[weaponLevel].damage
	if kind == "ranged" then damage = math.max(1,math.floor(damage*Ranged.damageMultiplier)) end
	rig:SetAttribute("WarriorDamage", damage)
	for _, child in rig:GetChildren() do
		if child:IsA("Tool") then child:SetAttribute("WarriorClass", kind) end
	end
end

function WarriorRig.create(civilization, spawnFrame: CFrame, ownerId: number, plotId: number, state: any?, kind: string?): Model
	local troopClass = kind or "warrior"
	assert(troopClass == "warrior" or troopClass == "ranged","Unknown troop class")
	local variant = (if troopClass == "ranged" then Ranged else Config).variants[civilization.id]
	assert(variant, "Unknown warrior civilization")
	local custom = if troopClass == "warrior" then NPCModelTemplates.clone(civilization.id) else nil
	local rig = custom or Instance.new("Model")
	rig.Name = variant.name
	rig:SetAttribute("OwnerId", ownerId)
	rig:SetAttribute("CivilizationId", civilization.id)
	rig:SetAttribute("PlotId", plotId)
	rig:SetAttribute("WarriorClass", troopClass)
	if not custom then
		local skin = Color3.fromRGB(189,153,116)
		local root = body(rig,"HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero,civilization.color)
		root.Transparency, root.RootPriority = 1, 127
		local torso = body(rig,"Torso",Vector3.new(2,2,1),Vector3.zero,civilization.color)
		local head = body(rig,"Head",Vector3.new(2,1,1),Vector3.new(0,1.5,0),skin)
		local rightArm = body(rig,"Right Arm",Vector3.new(1,2,1),Vector3.new(1.5,0,0),skin)
		local leftArm = body(rig,"Left Arm",Vector3.new(1,2,1),Vector3.new(-1.5,0,0),skin)
		local rightLeg = body(rig,"Right Leg",Vector3.new(1,2,1),Vector3.new(.5,-2,0),Color3.fromRGB(62,65,64))
		local leftLeg = body(rig,"Left Leg",Vector3.new(1,2,1),Vector3.new(-.5,-2,0),rightLeg.Color)
		joint(root,"RootJoint",torso,CFrame.identity,CFrame.identity)
		joint(torso,"Neck",head,CFrame.new(0,1,0),CFrame.new(0,-.5,0))
		joint(torso,"Right Shoulder",rightArm,CFrame.new(1,.5,0),CFrame.new(-.5,.5,0))
		joint(torso,"Left Shoulder",leftArm,CFrame.new(-1,.5,0),CFrame.new(.5,.5,0))
		joint(torso,"Right Hip",rightLeg,CFrame.new(.5,-1,0),CFrame.new(0,1,0))
		joint(torso,"Left Hip",leftLeg,CFrame.new(-.5,-1,0),CFrame.new(0,1,0))
	end
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = rig:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid")
	humanoid.MaxHealth, humanoid.Health = 100, 100
	humanoid.WalkSpeed, humanoid.HipHeight = Config.walkSpeed, 0
	humanoid.DisplayName = variant.name
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance, humanoid.HealthDisplayDistance = 70, 70
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = rig
	rig.PrimaryPart = root
	rig:PivotTo(spawnFrame)
	WarriorRig.update(rig, civilization, state or {weaponLevel=1,armorLevel=1})
	return rig
end

function WarriorRig.animate(rig: Model, now: number, moving: boolean, attacking: boolean?)
	local torso = rig:FindFirstChild("Torso")
	if not torso then return end
	local swing = if moving then math.sin(now*9)*.55 else 0
	for _, name in {"Right Hip", "Left Hip", "Right Shoulder", "Left Shoulder"} do
		local motor = torso:FindFirstChild(name)
		if motor and motor:IsA("Motor6D") then
			local angle = if name == "Right Hip" or name == "Left Shoulder" then swing else -swing
			if name == "Right Shoulder" then angle = if attacking then -1.4 + math.sin(now*20)*.7 else -.35 - swing*.3 end
			-- C0 replicates procedural poses to observers; Transform does not.
			-- Imported R6 joints can have rotated local axes. Swing in the
			-- torso's frame while preserving the imported rest orientation.
			local rest = motor:GetAttribute("RestC0")
			motor.C0 = CFrame.new(rest.Position) * CFrame.Angles(angle,0,0) * (rest - rest.Position)
		end
	end
end

return WarriorRig

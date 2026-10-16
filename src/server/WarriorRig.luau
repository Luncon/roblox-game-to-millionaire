--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.WarriorConfig)
local Tracks = require(ReplicatedStorage.Shared.UpgradeTracks)
local Ranged = require(ReplicatedStorage.Shared.RangedConfig)
local Equipment = require(script.Parent.Equipment)
local NPCModelTemplates = require(script.Parent.NPCModelTemplates)
local TroopAppearance = require(script.Parent.TroopAppearance)
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

local function proceduralBody(rig: Model, skin: Color3, color: Color3)
	local root = body(rig,"HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero,color)
	root.Transparency, root.RootPriority = 1, 127
	local torso = body(rig,"Torso",Vector3.new(2,2,1),Vector3.zero,color)
	local head = body(rig,"Head",Vector3.new(2,1,1),Vector3.new(0,1.5,0),skin)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25,1.25,1.25)
	headMesh.Parent = head
	local face = Instance.new("Decal")
	face.Name, face.Face, face.Texture = "face", Enum.NormalId.Front, TroopAppearance.faceTexture
	face.Parent = head
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

function WarriorRig.update(rig: Model, civilization, state)
	if not Equipment.applyWarrior(rig, civilization, state) then return end
	TroopAppearance.apply(rig, civilization.id)
	local weaponLevel, armorLevel = state.weaponLevel or 1, state.armorLevel or 1
	rig:SetAttribute("WeaponLevel", weaponLevel)
	rig:SetAttribute("ArmorLevel", armorLevel)
	local kind = rig:GetAttribute("WarriorClass") or "warrior"
	local damage = Tracks.weapon[weaponLevel].damage
	if kind == "ranged" then damage = math.max(1,damage*Ranged.damageMultiplier) end
	rig:SetAttribute("WarriorDamage", damage)
	for _, child in rig:GetChildren() do
		if child:IsA("Tool") then child:SetAttribute("WarriorClass", kind) end
	end
	-- Rebuilding welded equipment can reset the mechanism to automatic ownership.
	-- Unparented spawns receive their first server assignment from WarriorService.
	local root=rig:FindFirstChild("HumanoidRootPart")
	if rig:IsDescendantOf(workspace) and root and root:IsA("BasePart")
		and not root.Anchored and root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(nil)
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
	if not custom then proceduralBody(rig,TroopAppearance.skinColors[civilization.id],civilization.color) end
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

function WarriorRig.createNeutral(spawnFrame: CFrame, kind: string): Model
	assert(kind=="warrior" or kind=="ranged","Unknown neutral troop class")
	local rig=Instance.new("Model")
	rig.Name=if kind=="ranged" then "Neutral Archer" else "Neutral Warrior"
	rig:SetAttribute("WarriorClass",kind)
	proceduralBody(rig,Color3.fromRGB(198,166,136),Color3.fromRGB(110,112,119))
	local root=rig.HumanoidRootPart
	local humanoid=Instance.new("Humanoid")
	humanoid.MaxHealth,humanoid.Health,humanoid.WalkSpeed=100,100,Config.walkSpeed
	humanoid.DisplayName=rig.Name
	humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.NameDisplayDistance,humanoid.HealthDisplayDistance=70,70
	humanoid.BreakJointsOnDeath=false
	humanoid.Parent=rig
	rig.PrimaryPart=root
	local weapon=Instance.new("Model")
	weapon.Name,weapon.Parent="NeutralWeapon",rig
	local arm=rig["Right Arm"]
	local function piece(name: string,size: Vector3,offset: CFrame,color: Color3)
		local part=body(weapon,name,size,Vector3.zero,color)
		part.CanCollide,part.CanTouch,part.CanQuery=false,false,false
		part.CFrame=arm.CFrame*offset
		local weld=Instance.new("WeldConstraint")
		weld.Part0,weld.Part1,weld.Parent=arm,part,part
	end
	if kind=="ranged" then
		local wood=Color3.fromRGB(109,76,46)
		piece("Bow",Vector3.new(.18,2.6,.18),CFrame.new(0,-.7,-.65),wood)
		piece("UpperLimb",Vector3.new(.18,.9,.18),CFrame.new(0,.85,-.45)*CFrame.Angles(.5,0,0),wood)
		piece("LowerLimb",Vector3.new(.18,.9,.18),CFrame.new(0,-2.25,-.45)*CFrame.Angles(-.5,0,0),wood)
		piece("String",Vector3.new(.04,3.2,.04),CFrame.new(0,-.7,-.15),Color3.fromRGB(216,209,177))
	else
		piece("Grip",Vector3.new(.25,.8,.25),CFrame.new(0,-1,-.6),Color3.fromRGB(90,65,45))
		piece("Guard",Vector3.new(1,.15,.25),CFrame.new(0,-1,-1),Color3.fromRGB(145,148,154))
		piece("Blade",Vector3.new(.3,.12,2.6),CFrame.new(0,-1,-2.3),Color3.fromRGB(192,197,206))
	end
	rig:PivotTo(spawnFrame)
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

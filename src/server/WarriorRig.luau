--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.WarriorConfig)
local Tracks = require(ReplicatedStorage.Shared.UpgradeTracks)
local Ranged = require(ReplicatedStorage.Shared.RangedConfig)
local Equipment = require(script.Parent.Equipment)
local NPCModelTemplates = require(script.Parent.NPCModelTemplates)
local TroopAppearance = require(script.Parent.TroopAppearance)
local SkillPose = require(ReplicatedStorage.Shared.WeaponSkillPose)
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
	if kind=="ranged" then
		local basis="procedural"
		for _,tool in rig:GetChildren()do if tool:IsA("Tool")then
			for _,visual in tool:GetChildren()do
				if visual:IsA("Model") and visual:GetAttribute("TemplateId")=="bow" then basis="imported" end
			end
		end end
		rig:SetAttribute("CombatBowBasis",basis)
	end
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
	rig:SetAttribute("CombatBowBasis","neutral")
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

local attacks={
	-- Equipment's NPC grip already points spear/barrel axes forward at rest.
	thrust={ready=Vector3.new(.12,0,0),windup=Vector3.new(.25,-.12,.06),strike=Vector3.new(0,0,0)},
	slash={ready=Vector3.new(.25,0,.1),windup=Vector3.new(1.15,-.9,.2),strike=Vector3.new(.1,.85,-.3)},
	chop={ready=Vector3.new(.3,0,.1),windup=Vector3.new(2.7,0,.15),strike=Vector3.new(.1,0,-.12)},
	firearm={ready=Vector3.new(.2,0,.05),windup=Vector3.new(0,0,0),strike=Vector3.new(.04,0,0)},
	throw={ready=Vector3.new(.3,0,0),windup=Vector3.new(2.5,-.3,.2),strike=Vector3.new(.1,.2,0)},
}
local bows={
	imported={ready=Vector3.new(0,math.pi,math.pi/2),windup=Vector3.new(.08,math.pi-.1,math.pi/2),strike=Vector3.new(0,math.pi,math.pi/2)},
	neutral={ready=Vector3.zero,windup=Vector3.new(.08,-.1,0),strike=Vector3.zero},
	procedural={ready=Vector3.new(math.pi/2,0,0),windup=Vector3.new(math.pi/2,-.1,0),strike=Vector3.new(math.pi/2,0,0)},
}

function WarriorRig.combatStyle(rig): string
	local ranged=rig:GetAttribute("WarriorClass")=="ranged"
	local civilization=rig:GetAttribute("CivilizationId")
	local variant=(if ranged then Ranged else Config).variants[civilization]
	local kind=if variant then variant.weaponKind else if ranged then "bow" else "sword"
	if ranged then
		if kind=="bow" then return "bow" end
		if kind=="musket" or kind=="crossbow" then return "firearm" end
		return "throw"
	end
	return if kind=="spear" or kind=="rapier" then "thrust" elseif kind=="axe" then "chop" else "slash"
end

local function poseJoint(motor,angles,offset)
	if not motor or not motor:IsA("Motor6D") then return end
	local rest=motor:GetAttribute("RestC0")
	if not rest then rest=motor.C0;motor:SetAttribute("RestC0",rest)end
	-- Apply in the parent body's axes, retaining imported joint rest rotations.
	motor.C0=CFrame.new(rest.Position+(offset or Vector3.zero))*CFrame.Angles(angles.X,angles.Y,angles.Z)*(rest-rest.Position)
end

function WarriorRig.animate(rig: Model, now: number, moving: boolean, attacking: boolean?)
	local torso=rig:FindFirstChild("Torso")
	if not torso then return end
	local serverNow=workspace:GetServerTimeNow()
	local phase=rig:GetAttribute("CombatPhase") or (if attacking then "contact" else "idle")
	local duration=rig:GetAttribute("CombatPhaseDuration") or .35
	local began=rig:GetAttribute("CombatPhaseStartedAt") or serverNow-duration*.5
	local progress=math.clamp((serverNow-began)/math.max(.01,duration),0,1)
	local alpha=progress*progress*(3-2*progress)
	local style=WarriorRig.combatStyle(rig)
	local bowBasis=rig:GetAttribute("CombatBowBasis") or "neutral"
	local poses=if style=="bow" then bows[bowBasis] or bows.neutral else attacks[style]
	local right=poses.ready
	local offset=Vector3.zero
	local left=Vector3.new(.35,0,-.1)
	local leftOffset=Vector3.zero
	local twist=0
	local engaged=rig:GetAttribute("WarriorState")=="Fighting" or rig:GetAttribute("WarriorState")=="Waiting" or phase~="idle"
	local gait=if moving then math.sin(now*9)*.55 else 0
	if phase=="windup" then
		-- Anticipate, then complete the fast stroke exactly at contact start.
		local prepare=math.clamp(progress/.65,0,1)
		local stroke=math.clamp((progress-.65)/.35,0,1)
		prepare=prepare*prepare*(3-2*prepare);stroke=stroke*stroke*(3-2*stroke)
		right=poses.ready:Lerp(poses.windup,prepare):Lerp(poses.strike,stroke)
		twist=-.25*prepare+.5*stroke
		if style=="thrust" then offset=(Vector3.new(0,.05,.3)*prepare):Lerp(Vector3.new(0,0,-.75),stroke)end
	elseif phase=="contact" then
		right=poses.strike+Vector3.new(-.08,.08,0)*alpha;twist=.25
		if style=="thrust" then offset=Vector3.new(0,0,-.75)end
	elseif phase=="recovery" then
		right=poses.strike:Lerp(poses.ready,alpha);twist=.25*(1-alpha)
		if style=="thrust" then offset=Vector3.new(0,0,-.75)*(1-alpha)end
	elseif moving then right=Vector3.new(.35-gait*.3,0,0)end
	if style=="bow" then
		offset+=if bowBasis=="imported" then Vector3.new(.4,.15,-1) else Vector3.new(0,.5,-.4)
		if phase~="idle" then left=Vector3.new(.9,-.3,-.4);leftOffset=Vector3.new(.6,.1,-.15)end
	elseif style=="firearm" and phase~="idle" then
		offset+=Vector3.new(0,.3,-.2)
		left=Vector3.new(.9,0,1.1);leftOffset=Vector3.new(.4,0,-.35)
	elseif not engaged then left=Vector3.new(gait,0,0)end
	local hitAt=rig:GetAttribute("LastHitAt")
	local hit=hitAt and serverNow-hitAt>=0 and serverNow-hitAt<.18
	local flash=rig:FindFirstChild("CombatHitFlash")
	if hit and not flash then
		flash=Instance.new("Highlight");flash.Name="CombatHitFlash"
		flash.FillColor=Color3.fromRGB(255,197,130);flash.FillTransparency=.55
		flash.OutlineTransparency=1;flash.DepthMode=Enum.HighlightDepthMode.Occluded
		flash.Adornee=rig;flash.Parent=rig
	end
	if flash then flash.Enabled=hit==true end
	local family=rig:GetAttribute("WeaponSkillActive")
	local skillStarted=rig:GetAttribute("WeaponSkillStartedAt")
	local lean=0
	local rightHip,leftHip=Vector3.new(gait,0,0),Vector3.new(-gait,0,0)
	local neck=Vector3.new(if hit then -.1 else 0,0,0)
	if family and skillStarted then
		local skill=SkillPose.sample(family,serverNow-skillStarted)
		right,left,offset,twist,lean=skill.right,skill.left,skill.offset,skill.twist,skill.lean
		if family=="spear" then
			rightHip,leftHip,neck=skill.rightHip,skill.leftHip,skill.neck
		end
		leftOffset=Vector3.zero
	end
	poseJoint(torso:FindFirstChild("Right Shoulder"),right,offset)
	poseJoint(torso:FindFirstChild("Left Shoulder"),left,leftOffset)
	poseJoint(torso:FindFirstChild("Right Hip"),rightHip)
	poseJoint(torso:FindFirstChild("Left Hip"),leftHip)
	local root=rig:FindFirstChild("HumanoidRootPart")
	poseJoint(root and root:FindFirstChild("RootJoint"),Vector3.new((if hit and family~="spear" then .12 else 0)+lean,if phase~="idle" or family then twist else 0,0))
	poseJoint(torso:FindFirstChild("Neck"),neck)
end

return WarriorRig

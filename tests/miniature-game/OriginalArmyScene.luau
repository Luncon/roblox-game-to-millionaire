--!strict
-- Server-only native clone/pose checks. Never touches live armies or source assets.
local Replicated = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local bodyNames = { "HumanoidRootPart", "Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }
local customMelee = { sparta = true, britain = true, seneca = true, japan = true, maurya = true }
local function frameNear(actual: CFrame, expected: CFrame): boolean
	-- Imported mesh attachment rotations have tiny nonunit basis error. Inverting
	-- that matrix and calling ToAxisAngle invents a ~.003rad drift at equality.
	-- Compare position and each preserved basis directly instead.
	return (actual.Position - expected.Position).Magnitude < 0.002
		and (actual.RightVector - expected.RightVector).Magnitude < 0.002
		and (actual.UpVector - expected.UpVector).Magnitude < 0.002
		and (actual.LookVector - expected.LookVector).Magnitude < 0.002
end
local function different(actual: CFrame, expected: CFrame): boolean
	local delta = expected:ToObjectSpace(actual)
	local _, angle = delta:ToAxisAngle()
	return delta.Position.Magnitude > 0.01 or math.abs(angle) > 0.01
end
local function motor(rig: Model, name: string): Motor6D
	local found = rig:FindFirstChild(name, true)
	assert(found and found:IsA("Motor6D"), "Missing original pose joint")
	return found
end
local function soleY(rig: Model): number
	local lowest = math.huge
	for _, name in { "Left Leg", "Right Leg" } do
		local leg = rig:FindFirstChild(name)
		assert(leg and leg:IsA("BasePart"), "Missing original R6 foot")
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					lowest = math.min(lowest, leg.CFrame:PointToWorldSpace(leg.Size * Vector3.new(x, y, z) / 2).Y)
				end
			end
		end
	end
	return lowest
end
-- Exact source snapshots include attributes, garments, geometry and grips; no Source access.
local function sourceSnapshot(): string
	local rows = {}
	local function serialize(value): string
		if typeof(value) == "CFrame" then
			local values = { value:GetComponents() }
			for index, number in values do
				values[index] = string.format("%.17g", number)
			end
			return table.concat(values, ",")
		elseif typeof(value) == "Vector3" then
			return string.format("%.17g,%.17g,%.17g", value.X, value.Y, value.Z)
		end
		return tostring(value)
	end
	for _, name in { "NPCTemplates", "EquipmentTemplates", "OutfitTemplates" } do
		local folder = ServerStorage:FindFirstChild(name)
		assert(folder, "Original template folder is not mapped")
		for _, item in folder:GetDescendants() do
			local properties = { item:GetFullName(), item.ClassName }
			for attribute, value in item:GetAttributes() do
				table.insert(properties, attribute .. "=" .. serialize(value))
			end
			if item:IsA("BasePart") then
				for _, value in
					{
						item.CFrame,
						item.Size,
						item.Color,
						item.Material,
						item.Anchored,
						item.CanCollide,
						item.CanTouch,
						item.CanQuery,
						item.Transparency,
					}
				do
					table.insert(properties, serialize(value))
				end
			elseif item:IsA("Model") then
				table.insert(properties, serialize(item:GetScale()))
			elseif item:IsA("JointInstance") then
				table.insert(properties, serialize(item.C0))
				table.insert(properties, serialize(item.C1))
				table.insert(properties, if item.Part0 then item.Part0:GetFullName() else "nil")
				table.insert(properties, if item.Part1 then item.Part1:GetFullName() else "nil")
			elseif item:IsA("SpecialMesh") then
				for _, value in { item.MeshId, item.TextureId, item.Scale, item.Offset, item.MeshType } do
					table.insert(properties, serialize(value))
				end
			elseif item:IsA("Shirt") then
				table.insert(properties, item.ShirtTemplate)
			elseif item:IsA("Pants") then
				table.insert(properties, item.PantsTemplate)
			elseif item:IsA("ShirtGraphic") then
				table.insert(properties, item.Graphic)
			elseif item:IsA("Tool") then
				table.insert(properties, serialize(item.Grip))
			end
			-- Attribute enumeration order is unspecified.
			table.sort(properties)
			table.insert(rows, table.concat(properties, "|"))
		end
	end
	table.sort(rows)
	return table.concat(rows, "\n")
end
local function inert(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	assert(
		humanoid and not humanoid.EvaluateStateMachine and not humanoid.AutoRotate and humanoid.WalkSpeed == 0,
		"Original clothing Humanoid can move"
	)
	for _, item in rig:GetDescendants() do
		assert(
			not item:IsA("LuaSourceContainer") and not item:IsA("BodyMover") and not item:IsA("Animator"),
			"Original clone imported gameplay"
		)
		if item:IsA("BasePart") then
			assert(
				item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
				"Original clone enters native collision"
			)
		elseif item:IsA("Tool") then
			assert(
				not item.Enabled and not item.CanBeDropped and item:GetAttribute("VisualOnly"),
				"Original weapon is interactive"
			)
		elseif item:IsA("TouchTransmitter") then
			error("Original weapon retains pickup touch")
		end
	end
end
local function compareAppearance(rig: Model, baseline: Model)
	for _, name in bodyNames do
		local actual, expected = rig:FindFirstChild(name), baseline:FindFirstChild(name)
		assert(
			actual and actual:IsA("BasePart") and expected and expected:IsA("BasePart"),
			"Original body part missing"
		)
		assert(
			(actual.Size - expected.Size).Magnitude < 0.002 and actual.Color == expected.Color,
			"Original body proportions or colors changed"
		)
		local mesh, sourceMesh =
			actual:FindFirstChildOfClass("SpecialMesh"), expected:FindFirstChildOfClass("SpecialMesh")
		assert((mesh == nil) == (sourceMesh == nil), "Original body mesh missing")
		if mesh and sourceMesh then
			assert(
				mesh.MeshId == sourceMesh.MeshId
					and mesh.TextureId == sourceMesh.TextureId
					and (mesh.Scale - sourceMesh.Scale).Magnitude < 0.002
					and (mesh.Offset - sourceMesh.Offset).Magnitude < 0.002,
				"Original body mesh proportions changed"
			)
		end
	end
	for _, definition in { { "Shirt", "ShirtTemplate" }, { "Pants", "PantsTemplate" }, { "ShirtGraphic", "Graphic" } } do
		local garment, source = rig:FindFirstChildOfClass(definition[1]), baseline:FindFirstChildOfClass(definition[1])
		assert((garment == nil) == (source == nil), "Original outfit garment missing")
		if garment and source then
			assert(garment[definition[2]] == source[definition[2]], "Original outfit template replaced")
		end
	end
	-- Include imported hats, armor and weapon geometry, beyond the seven body parts.
	local function cosmetics(model: Model)
		local rows = {}
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local key = part:GetFullName():sub(#model:GetFullName() + 2)
				rows[key] = {
					size = part.Size,
					color = part.Color,
					class = part.ClassName,
					meshId = if part:IsA("MeshPart") then part.MeshId else nil,
					textureId = if part:IsA("MeshPart") then part.TextureID else nil,
				}
			end
		end
		return rows
	end
	local actual, expected = cosmetics(rig), cosmetics(baseline)
	local firstCount, secondCount = 0, 0
	for key, saved in expected do
		secondCount += 1
		local value = actual[key]
		assert(
			value
				and value.class == saved.class
				and value.meshId == saved.meshId
				and value.textureId == saved.textureId
				and value.color == saved.color
				and (value.size - saved.size).Magnitude < 0.002,
			"Original cosmetic geometry missing"
		)
	end
	for _ in actual do
		firstCount += 1
	end
	assert(firstCount == secondCount, "Original geometry count changed")
end
local function run()
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong original army fixture boundary"
	)
	local deadline = os.clock() + 15
	while not Replicated:GetAttribute("MiniatureSandboxReady") and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(Replicated:GetAttribute("MiniatureSandboxReady"), "Miniature sandbox was not ready")
	local OriginalTroops = require(game:GetService("ServerScriptService").Sandbox.OriginalTroops)
	local WarriorRig = require(ServerStorage.OriginalArmy.WarriorRig)
	local Civilizations = require(Replicated.MiniatureGame.Civilizations)
	local BattleConfig = require(Replicated.MiniatureGame.BattleConfig)
	local PoseCodec = require(Replicated.MiniatureGame.PoseCodec)
	local RigKinematics = require(Replicated.MiniatureGame.RigKinematics)
	local before = sourceSnapshot()
	local clones: { Model } = {}
	local supports: { Instance } = {}
	local evidence = {
		civilizations = #Civilizations,
		roles = 0,
		customMelee = 0,
		neutralRoles = 0,
		groundedPoses = 0,
		clientSolverPoses = 0,
		styles = {},
		sourceTemplatesImmutable = false,
		liveArmyMutation = false,
		scale = 0.25,
	}
	local function remember(rig: Model): Model
		table.insert(clones, rig)
		return rig
	end
	local function exercise(civilization, role: "melee" | "ranged" | "medic", neutral: boolean)
		local kind = if role == "melee" then "warrior" else role
		local baseline = remember(
			if neutral
				then WarriorRig.createNeutral(CFrame.identity, kind)
				else WarriorRig.create(
					civilization,
					CFrame.identity,
					0,
					0,
					{ weaponLevel = 1, armorLevel = 1, skillLevel = 0, shieldLevel = 0 },
					kind
				)
		)
		local rests = {}
		for _, joint in baseline:GetDescendants() do
			if joint:IsA("Motor6D") then
				rests[joint.Name] = joint:GetAttribute("RestC0")
			end
		end
		baseline:ScaleTo(baseline:GetScale() * 0.25)
		local rig = remember(OriginalTroops.create(civilization.id, role, neutral))
		assert(
			rig:GetAttribute("OriginalArmyVisual")
				and math.abs(rig:GetScale() - baseline:GetScale()) < 0.001
				and rig:GetAttribute("OriginalRigScale") == 0.25,
			"Original rig scale differs"
		)
		assert(
			rig:GetAttribute("SourceCivilizationId") == (if neutral then "neutral" else civilization.id)
				and rig:GetAttribute("WarriorClass") == kind,
			"Original rig identity differs"
		)
		inert(rig)
		compareAppearance(rig, baseline)
		if not neutral then
			local expectedCustom = role == "melee" and customMelee[civilization.id] == true
			assert(
				(rig:GetAttribute("CustomMeleeModel") == true) == expectedCustom,
				"Custom melee model silently replaced"
			)
			if expectedCustom then
				assert(rig:GetAttribute("TemplateCivilizationId") == civilization.id, "Custom melee source changed")
				evidence.customMelee += 1
			else
				assert(
					rig:GetAttribute("OutfitCivilizationId") == civilization.id,
					"Civilization original outfit not applied"
				)
			end
		end
		local style = WarriorRig.combatStyle(baseline)
		assert(rig:GetAttribute("OriginalAnimationStyle") == style, "Original weapon animation family changed")
		evidence.styles[style] = (evidence.styles[style] or 0) + 1
		local tool, sourceTool = rig:FindFirstChildOfClass("Tool"), baseline:FindFirstChildOfClass("Tool")
		assert((tool == nil) == (sourceTool == nil), "Original weapon role removed")
		local toolGrip = tool and tool.Grip
		if tool and sourceTool then
			assert(
				tool.Name == sourceTool.Name
					and tool:GetAttribute("WeaponKind") == sourceTool:GetAttribute("WeaponKind")
					and frameNear(tool.Grip, sourceTool.Grip),
				"Original weapon grip or identity changed"
			)
		end
		local attachments = {}
		for _, item in rig:GetDescendants() do
			if item:IsA("WeldConstraint") and item.Part0 and item.Part1 then
				table.insert(attachments, {
					joint = item,
					first = item.Part0,
					second = item.Part1,
					offset = item.Part0.CFrame:ToObjectSpace(item.Part1.CFrame),
				})
			end
		end
		local rendered = remember(rig:Clone())
		local kinematics = RigKinematics.new(rendered)
		assert(kinematics, "Original client rig graph was incomplete")
		local rightShoulder, rightHip = motor(rig, "Right Shoulder"), motor(rig, "Right Hip")
		local function pose(phase: string, now: number, ground: number, moving: boolean?, age: number?)
			OriginalTroops.pose(rig, {
				x = 1200,
				z = 1200,
				headingX = 0.6,
				headingZ = -0.8,
				phase = phase,
				moving = moving,
				phaseStartedAt = now - (age or 0.1),
				phaseDuration = 0.4,
			}, now, ground)
			assert(math.abs(soleY(rig) - ground - 0.005) < 0.002, "Original leg soles hover or penetrate ground")
			assert(
				math.abs(rig:GetAttribute("OriginalSoleY") - soleY(rig)) < 0.002,
				"Grounding evidence differs from actual feet"
			)
			for name, rest in rests do
				assert(motor(rig, name):GetAttribute("RestC0") == rest, "Original pose rest baseline mutated")
			end
			for _, attachment in attachments do
				local actual = attachment.first.CFrame:ToObjectSpace(attachment.second.CFrame)
				if not frameNear(actual, attachment.offset) then
					error(
						`Original attachment changed: {civilization.id}/{role}/{phase} ground={ground} joint={attachment.joint:GetFullName()} positionDrift={(
							actual.Position - attachment.offset.Position
						).Magnitude}`
					)
				end
			end
			local decoded = PoseCodec.decode(rig:GetAttribute("PoseSnapshot"))
			assert(decoded, "Original pose packet did not decode")
			RigKinematics.apply(kinematics, decoded, { rendered, rig })
			for _, name in bodyNames do
				local sourcePart, renderedPart = rig:FindFirstChild(name), rendered:FindFirstChild(name)
				assert(
					sourcePart
						and sourcePart:IsA("BasePart")
						and renderedPart
						and renderedPart:IsA("BasePart")
						and frameNear(renderedPart.CFrame, sourcePart.CFrame),
					"Client solver changed original rig body pose"
				)
			end
			assert(math.abs(soleY(rendered) - ground - 0.005) < 0.002, "Client solver feet left original ground")
			for _, attachment in rendered:GetDescendants() do
				if attachment:IsA("WeldConstraint") and attachment.Part0 and attachment.Part1 then
					local offset = attachment:GetAttribute("MiniatureWeldOffset")
					assert(
						typeof(offset) == "CFrame"
							and frameNear(attachment.Part0.CFrame:ToObjectSpace(attachment.Part1.CFrame), offset),
						"Client solver detached original cosmetic or weapon grip"
					)
				end
			end
			for _, name in { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" } do
				assert(
					frameNear(motor(rendered, name).C0, decoded.joints[name]),
					"Client solver joint differs from original packet"
				)
			end
			inert(rig)
			inert(rendered)
			evidence.clientSolverPoses += 1
			evidence.groundedPoses += 1
		end
		for _, ground in { 0, 0.4 } do
			pose("idle", 10, ground)
			local idle = rightShoulder.C0
			pose("moving", 0.15, ground, true)
			local firstStep = rightHip.C0
			pose("moving", 0.5, ground, true)
			assert(different(rightHip.C0, firstStep), "Original walking pose did not animate legs")
			pose("windup", 10, ground, false, 0.16)
			local windup = rightShoulder.C0
			pose("contact", 10, ground, false, 0.1)
			assert(different(rightShoulder.C0, windup), "Original attack windup/contact pose did not change")
			pose("recovery", 10, ground, false, 0.2)
			if role == "medic" then
				pose("heal", 10, ground, false, 0.1)
				assert(
					different(rightShoulder.C0, idle) and rig:GetAttribute("BandageThrownAt"),
					"Original medic bandage pose missing"
				)
			end
		end
		assert(
			not tool or (tool.Parent == rig and tool.Grip == toolGrip),
			"Animation rebuilt or rotated original weapon grip"
		)
		if neutral then
			evidence.neutralRoles += 1
		else
			evidence.roles += 1
		end
		rendered:Destroy()
		rig:Destroy()
		baseline:Destroy()
	end
	local ok, failure = pcall(function()
		for _, role in { "melee", "ranged", "medic" } do
			local owned, neutral = BattleConfig.player[role], BattleConfig.neutral[role]
			assert(
				owned.speed == 6 and math.abs(neutral.speed - owned.speed * 0.95) < 0.000001,
				"Original march speed ratio changed"
			)
			assert(
				math.abs(neutral.health - owned.health * 0.95) < 0.000001
					and math.abs(neutral.damage - owned.damage * 0.95) < 0.000001,
				"Neutral health or damage ratio changed"
			)
			assert(
				neutral.reach == owned.reach
					and neutral.cooldown == owned.cooldown
					and neutral.windup == owned.windup
					and neutral.recovery == owned.recovery,
				"Neutral reach or attack cadence differs"
			)
		end
		assert(
			BattleConfig.player.ranged.reach == 10
				and BattleConfig.neutral.ranged.reach == 10
				and BattleConfig.player.medic.healRange == 7,
			"Miniature ranged or healing distances doubled"
		)
		for _, civilization in Civilizations do
			for _, role in { "melee", "ranged", "medic" } do
				exercise(civilization, role, false)
			end
		end
		exercise(Civilizations[1], "melee", true)
		exercise(Civilizations[1], "ranged", true)
		-- Real raycasts, isolated beyond the playable map; no live actors are moved.
		local support = Instance.new("Part")
		table.insert(supports, support)
		support.Name, support.Size, support.CFrame =
			"OriginalArmyFixtureSupport", Vector3.new(20, 0.4, 20), CFrame.new(1200, 0.2, 1200)
		support.Anchored, support.CanCollide, support.CanTouch, support.CanQuery = true, false, false, true
		support:SetAttribute("OriginalTroopSupport", true)
		support.Parent = Workspace
		local avatar = Instance.new("Model")
		table.insert(supports, avatar)
		avatar.Name = "OriginalArmyFixtureAvatar"
		local humanoid = Instance.new("Humanoid")
		humanoid.EvaluateStateMachine, humanoid.AutoRotate = false, false
		humanoid.Parent = avatar
		local head = Instance.new("Part")
		head.Name, head.Size, head.CFrame = "Head", Vector3.new(10, 2, 10), CFrame.new(1200, 5, 1200)
		head.Anchored, head.CanCollide, head.CanTouch, head.CanQuery = true, false, false, true
		head:SetAttribute("OriginalTroopSupport", true)
		head.Parent = avatar
		avatar.Parent = Workspace
		local sample = remember(OriginalTroops.create("sparta", "melee"))
		for _, phase in { "idle", "moving", "windup", "contact" } do
			OriginalTroops.pose(sample, {
				x = 1200,
				z = 1200,
				headingX = 0,
				headingZ = 1,
				phase = phase,
				phaseStartedAt = 9.9,
				phaseDuration = 0.4,
			}, 10)
			assert(math.abs(soleY(sample) - 0.405) < 0.002, "Ground raycast ignored support or stood on a character")
		end
		evidence.raycastSupportAndHumanoidExclusion = true
		assert(
			evidence.civilizations == 13 and evidence.roles == 39 and evidence.customMelee == 5,
			"Original army coverage incomplete"
		)
	end)
	for _, rig in clones do
		rig:Destroy()
	end
	for _, support in supports do
		support:Destroy()
	end
	assert(before == sourceSnapshot(), "Original source templates mutated")
	evidence.sourceTemplatesImmutable = true
	evidence.ownedSpeed, evidence.neutralSpeed = 6, 5.7
	evidence.neutralStatRatio = 0.95
	evidence.ownedRangedReach, evidence.neutralRangedReach, evidence.medicHealRange = 10, 10, 7
	Replicated:SetAttribute(
		"MiniatureOriginalArmySceneResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = if ok then evidence else tostring(failure) })
	)
	assert(ok, failure)
	return evidence
end
return run

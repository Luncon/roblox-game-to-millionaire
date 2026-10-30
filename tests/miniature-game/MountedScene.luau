--!strict
-- Native server geometry/kinematics fixture; all riders are isolated fresh clones.
local Replicated = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local function frameNear(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.003
		and (a.RightVector - b.RightVector).Magnitude < 0.002
		and (a.UpVector - b.UpVector).Magnitude < 0.002
		and (a.LookVector - b.LookVector).Magnitude < 0.002
end
local function lowY(part: BasePart): number
	local lowest = math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				lowest = math.min(lowest, part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2).Y)
			end
		end
	end
	return lowest
end
local function mountFingerprint(bank: Instance): string
	local lines = {}
	for _, object in bank:GetDescendants() do
		local values = { object:GetFullName(), object.ClassName }
		if object:IsA("BasePart") then
			table.insert(values, tostring(object.CFrame))
			table.insert(values, tostring(object.Size))
			table.insert(values, tostring(object.Color))
			table.insert(values, tostring(object.Transparency))
		elseif object:IsA("DataModelMesh") then
			table.insert(values, tostring(object.Scale))
		elseif object:IsA("JointInstance") then
			table.insert(values, tostring(object.C0))
			table.insert(values, tostring(object.C1))
		end
		for key, value in object:GetAttributes() do
			table.insert(values, key .. "=" .. tostring(value))
		end
		table.sort(values)
		table.insert(lines, table.concat(values, "|"))
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end
local function riderAppearance(rig: Model): string
	local rows = {}
	local animal = rig:FindFirstChild("MountAnimal")
	for _, object in rig:GetDescendants() do
		if animal and (object == animal or object:IsDescendantOf(animal)) then
			continue
		end
		local row = object.ClassName .. ":" .. object.Name
		if object:IsA("BasePart") then
			row ..= ":" .. tostring(object.Size) .. ":" .. tostring(object.Color)
		elseif object:IsA("Shirt") then
			row ..= ":" .. object.ShirtTemplate
		elseif object:IsA("Pants") then
			row ..= ":" .. object.PantsTemplate
		elseif object:IsA("Decal") then
			row ..= ":" .. object.Texture
		elseif object:IsA("SpecialMesh") then
			row ..= ":" .. object.MeshId .. ":" .. object.TextureId .. ":" .. tostring(object.Scale)
		elseif object:IsA("Tool") then
			row ..= ":" .. tostring(object.Grip)
		end
		if not object:IsA("JointInstance") and not object:IsA("WeldConstraint") then
			table.insert(rows, row)
		end
	end
	table.sort(rows)
	return table.concat(rows, "\n")
end
local function run()
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong mounted native boundary"
	)
	local Server = game:GetService("ServerScriptService").Sandbox
	local Mounted = require(Server.MountedTroops)
	local Original = require(Server.OriginalTroops)
	local Shared = Replicated.MiniatureGame
	local Config = require(Shared.MountConfig)
	local Codec = require(Shared.PoseCodec)
	local Kinematics = require(Shared.RigKinematics)
	local fingerprint = require(ServerStorage.TemplateFingerprint)
	local bank = ServerStorage:FindFirstChild("MountTemplates")
	assert(bank and #bank:GetChildren() == 11, "Expected all eleven imported animal templates")
	local animalsBefore, originalsBefore = mountFingerprint(bank), fingerprint()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "NativeMountedGeometryFixture", ServerStorage
	local evidence =
		{ civilizations = 0, groundPoses = 0, clientPoses = 0, parts = 0, originalRiders = 0, anatomyJoints = 0 }
	local ok, failure = pcall(function()
		for civilizationId, definition in Config.definitions do
			local rig = Mounted.create(civilizationId)
			rig.Name, rig.Parent = civilizationId, folder
			rig:SetAttribute("Life", 1)
			local baseline = Original.create(civilizationId, "melee")
			baseline.Parent = folder
			assert(
				riderAppearance(rig) == riderAppearance(baseline),
				civilizationId .. " mounted rider lost original outfit, face, gear or proportions"
			)
			baseline:Destroy()
			evidence.originalRiders += 1
			assert(
				rig:GetAttribute("MountedVisual") == true
					and rig:GetAttribute("MountAnimal") == definition.animal
					and rig:GetAttribute("MountTemplate") == definition.template,
				"Mounted animal identity differs from culture mapping"
			)
			local animal = rig:FindFirstChild("MountAnimal")
			assert(animal and animal:IsA("Model"), "Mounted troop has no original animal")
			if definition.template == "elephant" then
				local chair, saddle = animal:FindFirstChild("Crouch", true), animal:FindFirstChild("RiderSaddle")
				assert(
					chair and chair:IsA("BasePart") and saddle and saddle:IsA("BasePart"),
					"Elephant howdah seat is missing"
				)
				local gap = saddle.Position.Y - chair.Position.Y
				assert(gap >= 0 and gap < 0.35, "Elephant rider is floating above the howdah chair back")
			end
			if definition.template == "lion" then
				local back, saddle = animal:FindFirstChild("Torso"), animal:FindFirstChild("RiderSaddle")
				assert(
					back and back:IsA("BasePart") and saddle and saddle:IsA("BasePart"),
					"Lion back/saddle is missing"
				)
				local gap = saddle.Position.Y - back.Position.Y
				assert(gap > 0 and gap < 0.55, "Lion rider floats above the visible back")
				evidence.lionSeated = true
			end
			local eyes, blockLegs, blockHooves, snouts, nostrils = 0, 0, 0, 0, 0
			for _, object in animal:GetDescendants() do
				if not object:IsA("BasePart") then
					continue
				end
				local feature = object:GetAttribute("MountFaceFeature")
				if feature == "eye" then
					assert(
						object.Transparency == 0
							and object.Color.R < 0.08
							and object.Color.G < 0.08
							and object.Color.B < 0.08,
						"Mount eye is not visibly black"
					)
					eyes += 1
				elseif feature == "snout" then
					assert(object.Size.X > object.Size.Z * 1.2, "Rhino muzzle is not a broad block-shaped snout")
					snouts += 1
				elseif feature == "nostril" then
					nostrils += 1
				end
				if object:GetAttribute("BlockMountLeg") == true then
					assert(
						object:IsA("Part") and object.Size.Y / math.min(object.Size.X, object.Size.Z) <= 2.2,
						"Bull leg remains slender or rounded"
					)
					blockLegs += 1
				elseif object:GetAttribute("BlockMountHoof") == true then
					assert(object:IsA("Part") and object.Shape == Enum.PartType.Block, "Bull hoof is not block shaped")
					blockHooves += 1
				end
			end
			if definition.template == "wolf" or definition.template == "rhino" then
				assert(eyes == 2, "Wolf/rhino is missing its pair of black eyes")
			end
			if definition.template == "bull" then
				assert(blockLegs == 4 and blockHooves == 4, "Bull needs four short block legs and four block hooves")
				evidence.bullBlockLegs = blockLegs
			elseif definition.template == "rhino" then
				assert(snouts == 1 and nostrils == 2, "Rhino muzzle/nostrils are missing")
				evidence.rhinoFace = true
			elseif definition.template == "wolf" then
				evidence.wolfEyes = eyes
			end
			local partCount, contacts, joints, humanoids = 0, {}, 0, 0
			local animalLow, animalHigh = math.huge, -math.huge
			for _, object in rig:GetDescendants() do
				assert(
					not object:IsA("LuaSourceContainer")
						and not object:IsA("Animator")
						and not object:IsA("BodyMover")
						and not object:IsA("Seat")
						and not object:IsA("VehicleSeat")
						and not object:IsA("RemoteEvent")
						and not object:IsA("RemoteFunction"),
					"Imported executable/controller survived sanitizing"
				)
				if object:IsA("BasePart") then
					partCount += 1
					object:SetAttribute("MountedFixturePart", partCount)
					assert(
						object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery,
						"Mounted geometry affects physics/query"
					)
					if object:GetAttribute("MountGroundContact") == true then
						assert(
							object:IsDescendantOf(animal) and object.Transparency < 1,
							"Mounted contact uses invisible or human proxy"
						)
						table.insert(contacts, object)
					end
					if object:IsDescendantOf(animal) then
						for _, x in { -1, 1 } do
							for _, y in { -1, 1 } do
								for _, z in { -1, 1 } do
									local point =
										object.CFrame:PointToWorldSpace(object.Size * Vector3.new(x, y, z) / 2)
									animalLow, animalHigh = math.min(animalLow, point.Z), math.max(animalHigh, point.Z)
								end
							end
						end
					end
				elseif object:IsA("Humanoid") then
					humanoids += 1
					assert(
						not object.EvaluateStateMachine and not object.AutoRotate and object.WalkSpeed == 0,
						"Mounted Humanoid is active"
					)
				elseif object:IsA("Tool") then
					assert(not object.Enabled and not object.CanBeDropped, "Mounted weapon can activate/drop")
				elseif object:IsA("Motor6D") and object:GetAttribute("MountJoint") == true then
					joints += 1
				end
			end
			assert(
				humanoids == 1 and #contacts == 4 and joints >= 5 and partCount < 320,
				"Mounted anatomy/part budget invalid"
			)
			assert(
				math.abs(animalHigh - animalLow - definition.bodyLength) < 0.06,
				civilizationId .. " animal exceeded normalized overall size"
			)
			evidence.parts += partCount
			evidence.anatomyJoints += joints
			local time = 100
			for _, height in { 0, 0.4 } do
				for index, phase in { "idle", "moving", "windup", "contact", "recovery", "moving" } do
					time += 0.1
					Mounted.pose(rig, {
						x = 820 + index * 0.9,
						z = 820,
						headingX = 0,
						headingZ = -1,
						phase = phase,
						moving = phase == "moving",
						phaseStartedAt = time - 0.04,
						phaseDuration = 0.35,
					}, time, height)
					local lowest = math.huge
					for _, contact in contacts do
						lowest = math.min(lowest, lowY(contact))
					end
					assert(math.abs(lowest - height - 0.005) < 0.003, civilizationId .. " hoof/paw grounding changed")
					local packet = Codec.decode(rig:GetAttribute("PoseSnapshot"))
					assert(packet and packet.life == 1 and packet.speed ~= nil, "Mounted atomic pose metadata missing")
					local copy = rig:Clone()
					copy.Parent = folder
					local kin = Kinematics.new(copy)
					assert(kin and kin.mount, "Mounted client graph is incomplete")
					Kinematics.apply(kin, packet, { folder })
					local sourceParts = {}
					for _, object in rig:GetDescendants() do
						if object:IsA("BasePart") then
							sourceParts[object:GetAttribute("MountedFixturePart")] = object
						end
					end
					for _, object in copy:GetDescendants() do
						if object:IsA("BasePart") then
							local sourcePart = sourceParts[object:GetAttribute("MountedFixturePart")]
							assert(
								sourcePart and frameNear(object.CFrame, sourcePart.CFrame),
								civilizationId .. " source/client mounted pose diverged at " .. object.Name
							)
						end
					end
					copy:Destroy()
					evidence.groundPoses += 1
				end
			end
			-- Actual local FK samples between server packet times, without moving authority.
			local copy = rig:Clone()
			copy.Parent = folder
			local kin = Kinematics.new(copy)
			assert(kin and kin.mount, "Mounted interpolation test graph unavailable")
			local packet = Codec.decode(rig:GetAttribute("PoseSnapshot"))
			assert(packet, "Mounted source packet unavailable")
			packet.speed = 9
			local gaitJoint
			for _, joint in kin.mount.joints do
				if joint.kind == "leg" then
					gaitJoint = joint.motor
					break
				end
			end
			assert(gaitJoint, "Mounted animal has no articulated gait limb")
			local previous, changed = nil, 0
			for _ = 1, 18 do
				packet.time += 1 / 60
				Kinematics.apply(kin, packet, { folder })
				local pose = gaitJoint.C0
				if previous and not frameNear(pose, previous) then
					changed += 1
				end
				previous = pose
				local lowest = math.huge
				for _, contact in kin.feet do
					lowest = math.min(lowest, lowY(contact))
				end
				assert(
					math.abs(lowest - packet.ground - 0.005) < 0.003,
					"Local mount gait lifted/embedded all ground contacts"
				)
				evidence.clientPoses += 1
			end
			assert(changed >= 8, civilizationId .. " animal gait still depends on server packet cadence")
			if definition.template == "crocodile" then
				local trajectories = {}
				for _, foot in kin.feet do
					trajectories[foot] = { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge }
				end
				for _ = 1, 60 do
					packet.time += 1 / 60
					Kinematics.apply(kin, packet, { folder })
					for foot, track in trajectories do
						track.minX, track.maxX =
							math.min(track.minX, foot.Position.X), math.max(track.maxX, foot.Position.X)
						track.minZ, track.maxZ =
							math.min(track.minZ, foot.Position.Z), math.max(track.maxZ, foot.Position.Z)
					end
					evidence.clientPoses += 1
				end
				local minimumSweep = math.huge
				for _, track in trajectories do
					local sweep = Vector2.new(track.maxX - track.minX, track.maxZ - track.minZ).Magnitude
					assert(sweep >= 0.12, "Crocodile foot changes pose without a visible horizontal sweep")
					minimumSweep = math.min(minimumSweep, sweep)
				end
				packet.speed = 0
				Kinematics.apply(kin, packet, { folder })
				local resting = {}
				for _, foot in kin.feet do
					resting[foot] = foot.Position
				end
				packet.time += 0.2
				Kinematics.apply(kin, packet, { folder })
				for foot, point in resting do
					assert(
						Vector2.new(foot.Position.X - point.X, foot.Position.Z - point.Z).Magnitude < 0.003,
						"Stationary crocodile continues its walking cycle"
					)
				end
				evidence.crocodileMinimumFootSweep, evidence.crocodileResting = minimumSweep, true
			end
			copy:Destroy()
			rig:Destroy()
			evidence.civilizations += 1
			task.wait()
		end
		assert(
			mountFingerprint(bank) == animalsBefore and fingerprint() == originalsBefore,
			"Mounted factory mutated imported/original source assets"
		)
	end)
	folder:Destroy()
	Replicated:SetAttribute(
		"MiniatureMountedSceneResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = if ok then evidence else tostring(failure) })
	)
	assert(ok, failure)
	return evidence
end
return run

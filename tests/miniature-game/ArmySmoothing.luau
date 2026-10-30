--!strict
-- Client renderer regression. Isolated clone packets exercise presentation only;
-- movement evidence observes the real army driven separately by native shop/E input.
-- Never loads PlayerModule or changes authoritative actor/profile state.
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Http = game:GetService("HttpService")
type Options = { timeout: number?, observeSeconds: number?, isolatedOnly: boolean? }
local function nearFrame(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.002
		and (a.RightVector - b.RightVector).Magnitude < 0.002
		and (a.UpVector - b.UpVector).Magnitude < 0.002
		and (a.LookVector - b.LookVector).Magnitude < 0.002
end
local function planar(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end
local function root(model: Model): BasePart
	local part = model:FindFirstChild("HumanoidRootPart")
	assert(part and part:IsA("BasePart"), "Smoothed actor root missing")
	return part
end
local function visualFor(id: string, life: number?): Model?
	for _, folder in Workspace:GetChildren() do
		if folder.Name:match("^MiniatureClientActors") then
			for _, model in folder:GetChildren() do
				if
					model:IsA("Model")
					and model:GetAttribute("ClientTroopVisual") == true
					and model:GetAttribute("ActorId") == id
					and (life == nil or model:GetAttribute("Life") == life)
				then
					return model
				end
			end
		end
	end
	return nil
end
local function soles(model: Model): number
	local y = math.huge
	for _, name in { "Left Leg", "Right Leg" } do
		local leg = model:FindFirstChild(name)
		assert(leg and leg:IsA("BasePart"), "Smoothed actor foot missing")
		for _, x in { -1, 1 } do
			for _, vertical in { -1, 1 } do
				for _, z in { -1, 1 } do
					y = math.min(y, leg.CFrame:PointToWorldSpace(leg.Size * Vector3.new(x, vertical, z) / 2).Y)
				end
			end
		end
	end
	return y
end
local function run(options: Options?)
	options = options or {}
	assert(
		Run:IsStudio() and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong smoothing native boundary"
	)
	local player = Players.LocalPlayer
	local shared = Replicated:WaitForChild("MiniatureGame", 15)
	local scene = Workspace:WaitForChild("MiniatureSandbox", 15)
	assert(shared and scene, "Smoothing scene unavailable")
	local sources = scene:WaitForChild("BattleActors", 15)
	assert(sources, "Authoritative actor sources unavailable")
	local Codec = require(shared.PoseCodec)
	local Renderer = require(player.PlayerScripts.MiniatureGame.TroopRenderer)
	local deadline = os.clock() + (options.timeout or 180)
	local evidence =
		{ nativeClient = true, authoritativeMutation = false, controllerModuleLoaded = false, sourceRateProof = false }
	local temporary: { Instance } = {}
	local controller
	local function waitFor(predicate, label: string, seconds: number?)
		local stop = math.min(deadline, os.clock() + (seconds or 10))
		repeat
			if predicate() then
				return
			end
			Run.RenderStepped:Wait()
		until os.clock() >= stop
		error(label)
	end
	local ok, failure = pcall(function()
		Replicated:SetAttribute("MiniatureArmySmoothingProgress", "isolated original source lifecycle")
		local template
		waitFor(function()
			for _, model in sources:GetChildren() do
				if
					model:IsA("Model")
					and model:GetAttribute("OriginalArmyVisual")
					and model:GetAttribute("NeutralDefense") == true
					and Codec.decode(model:GetAttribute("PoseSnapshot"))
				then
					template = model
					return true
				end
			end
			return false
		end, "No original source pose available", 20)
		local holder = Instance.new("Folder")
		table.insert(temporary, holder)
		holder.Name, holder.Parent = "NativeSmoothingSources", Workspace
		local source = template:Clone()
		local id = "native-smoothing-" .. Http:GenerateGUID(false)
		source.Name = id
		source:SetAttribute("ActorId", id)
		local seed = Codec.decode(source:GetAttribute("PoseSnapshot"))
		assert(seed, "Cloned original pose missing")
		seed.time, seed.life = Workspace:GetServerTimeNow() - 0.3, seed.life + 100000
		-- Ground metadata belongs to its original location. Use a known isolated
		-- support so the endpoint shift cannot cross an outpost footing edge.
		local support = Instance.new("Part")
		table.insert(temporary, support)
		support.Name, support.Size, support.CFrame =
			"NativeSmoothingSupport", Vector3.new(20, 0.4, 20), CFrame.new(550, 0.2, 550)
		support.Anchored, support.CanCollide, support.CanTouch, support.CanQuery = true, false, false, true
		support:SetAttribute("OriginalTroopSupport", true)
		support.Parent = Workspace
		seed.root = CFrame.new(550, seed.root.Y + 0.4 - seed.ground, 550) * (seed.root - seed.root.Position)
		seed.ground = 0.4
		local initialRoot = seed.root
		source:SetAttribute("Life", seed.life)
		source:SetAttribute("PoseSnapshot", Codec.encode(seed))
		local originals, attachments = {}, {}
		local originalDecals = {}
		for _, item in source:GetDescendants() do
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = 0
				originals[item] = {
					frame = item.CFrame,
					size = item.Size,
					color = item.Color,
					transparency = item.LocalTransparencyModifier,
				}
			elseif item:IsA("Decal") then
				item.LocalTransparencyModifier = 0.35
				originalDecals[item] = {
					localTransparency = item.LocalTransparencyModifier,
					transparency = item.Transparency,
					texture = item.Texture,
					face = item.Face,
				}
			elseif item:IsA("WeldConstraint") and item.Part0 and item.Part1 then
				table.insert(attachments, {
					first = item.Part0.Name,
					second = item.Part1.Name,
					offset = item.Part0.CFrame:ToObjectSpace(item.Part1.CFrame),
				})
			end
		end
		local health = source:FindFirstChild("HealthDisplay", true)
		assert(health and health:IsA("BillboardGui"), "Original source health display missing")
		health.Adornee = source:FindFirstChild("Head")
		local adornee, enabled = health.Adornee, health.Enabled
		local weapon = source:FindFirstChild("NeutralWeapon")
		local delayedPart = weapon and weapon:FindFirstChildWhichIsA("BasePart", true)
		assert(delayedPart and delayedPart.Parent, "Original neutral fixture cosmetic part missing")
		local delayedParent = delayedPart.Parent
		table.insert(temporary, delayedPart)
		delayedPart.Parent = nil
		local sourceHead = source:FindFirstChild("Head")
		local delayedMesh = sourceHead and sourceHead:FindFirstChildOfClass("SpecialMesh")
		assert(delayedMesh and delayedMesh.Parent, "Original neutral head mesh missing")
		local meshParent = delayedMesh.Parent
		table.insert(temporary, delayedMesh)
		delayedMesh.Parent = nil
		source.Parent = holder
		local screen = Instance.new("ScreenGui")
		table.insert(temporary, screen)
		screen.Name, screen.ResetOnSpawn, screen.Parent = "NativeSmoothingOwner", false, player.PlayerGui
		controller = Renderer.start(screen, { sourceFolder = holder, interpolationDelay = 0 })
		local function feed(packet)
			packet.time += 0.02
			source:SetAttribute("PoseSnapshot", Codec.encode(packet))
			task.wait(0.05)
		end
		task.wait(0.25)
		feed(seed)
		feed(seed)
		assert(visualFor(id) == nil, "Renderer mounted incomplete original cosmetic geometry")
		for part in originals do
			assert(part.LocalTransparencyModifier == 0, "Renderer hid an original source before clone readiness")
		end
		delayedPart.Parent = delayedParent
		feed(seed)
		feed(seed)
		assert(visualFor(id) == nil, "Renderer mounted all body parts before original head mesh arrived")
		delayedMesh.Parent = meshParent
		local function feedUntilMounted(packet, predicate, label: string)
			local stop, sent = math.min(deadline, os.clock() + 10), 0
			repeat
				feed(packet)
				sent += 1
				if sent >= 2 and predicate() then
					return
				end
			until os.clock() >= stop
			error(label)
		end
		feedUntilMounted(seed, function()
			return visualFor(id, seed.life) ~= nil
		end, "Two-packet original visual did not mount")
		local first = visualFor(id, seed.life)
		assert(first, "Mounted visual vanished")
		assert(
			not first:FindFirstChild("HealthDisplay", true)
				and health.Adornee == first:FindFirstChild("Head")
				and health.Enabled == enabled,
			"Health display duplicated or failed to follow smoothed head"
		)
		for part in originals do
			assert(part.LocalTransparencyModifier == 1, "Authoritative source remains visibly duplicated")
		end
		assert(next(originalDecals) ~= nil, "Original face decal regression has no face")
		for decal in originalDecals do
			assert(decal.LocalTransparencyModifier == 1, "Hidden source face remains visible ahead of its troop")
		end
		local visibleHead = first:FindFirstChild("Head")
		local visibleFace = visibleHead and visibleHead:FindFirstChildWhichIsA("Decal")
		assert(
			visibleFace and visibleFace.LocalTransparencyModifier == 0 and visibleFace.Parent == visibleHead,
			"Smoothed face is hidden or detached from its head"
		)
		-- Replicated decals/textures arriving after mounting must also stay hidden.
		for _, className in { "Decal", "Texture" } do
			local late = if className == "Decal" then Instance.new("Decal") else Instance.new("Texture")
			late.LocalTransparencyModifier = 0.2
			late.Parent = sourceHead
			Run.PreRender:Wait()
			assert(late.LocalTransparencyModifier == 1, "Late source face or texture escaped hiding")
			late:Destroy()
		end
		local firstTool = first:FindFirstChildOfClass("Tool")
		local grip = firstTool and firstTool.Grip
		local nextPose = table.clone(seed)
		nextPose.time, nextPose.root = seed.time + 0.1, seed.root + Vector3.new(0.6, 0, 0)
		source:SetAttribute("PoseSnapshot", Codec.encode(nextPose))
		waitFor(function()
			return math.abs((first:GetAttribute("SourcePoseTime") or 0) - nextPose.time) < 0.000002
		end, "New pose packet did not reach visual")
		waitFor(function()
			return (planar(root(first).Position - nextPose.root.Position)).Magnitude < 0.003
		end, "Visual did not reach authoritative endpoint")
		local stale = table.clone(seed)
		stale.time, stale.root = seed.time + 0.05, initialRoot + Vector3.new(100, 0, 0)
		source:SetAttribute("PoseSnapshot", Codec.encode(stale))
		for _ = 1, 3 do
			Run.RenderStepped:Wait()
		end
		assert(
			math.abs((first:GetAttribute("SourcePoseTime") or 0) - nextPose.time) < 0.000002
				and planar(root(first).Position - nextPose.root.Position).Magnitude < 0.003,
			"Out of order native pose rolled the visual back"
		)
		for _, attachment in attachments do
			local firstPart, secondPart =
				first:FindFirstChild(attachment.first, true), first:FindFirstChild(attachment.second, true)
			assert(
				firstPart
					and firstPart:IsA("BasePart")
					and secondPart
					and secondPart:IsA("BasePart")
					and nearFrame(firstPart.CFrame:ToObjectSpace(secondPart.CFrame), attachment.offset),
				"Smoothing detached original equipment geometry"
			)
		end
		assert(
			not firstTool or (firstTool.Parent == first and firstTool.Grip == grip),
			"Smoothing rebuilt or rotated original tool grip"
		)
		local actualSole = soles(first)
		if math.abs(actualSole - nextPose.ground - 0.005) >= 0.02 then
			error(
				`Smoothed original feet left isolated support: actual={actualSole} expected={nextPose.ground + 0.005}`
			)
		end
		-- A new life replaces the complete cloned rig; old delayed packets cannot return.
		local fresh = table.clone(nextPose)
		fresh.life, fresh.time = seed.life + 1, nextPose.time + 0.1
		source:SetAttribute("Life", fresh.life)
		source:SetAttribute("PoseSnapshot", Codec.encode(fresh))
		feedUntilMounted(fresh, function()
			return visualFor(id, fresh.life) ~= nil and first.Parent == nil
		end, "Two-packet new life reused previous visual")
		local current = visualFor(id, fresh.life)
		assert(
			current and health.Adornee == current:FindFirstChild("Head"),
			"Fresh life health display targeted old rig"
		)
		source:SetAttribute("PoseSnapshot", Codec.encode(nextPose))
		for _ = 1, 3 do
			Run.RenderStepped:Wait()
		end
		assert(
			visualFor(id, fresh.life) == current and visualFor(id, seed.life) == nil,
			"Stale native life resurrected a visual"
		)
		source.Parent = nil
		waitFor(function()
			return visualFor(id) == nil
		end, "Removed source left a client rig")
		assert(
			health.Adornee == adornee and health.Enabled == enabled,
			"Source removal did not restore its health display"
		)
		for part, saved in originals do
			assert(
				part.LocalTransparencyModifier == saved.transparency,
				"Source removal did not restore original visibility"
			)
		end
		source:SetAttribute("PoseSnapshot", Codec.encode(fresh))
		source.Parent = holder
		feedUntilMounted(fresh, function()
			return visualFor(id, fresh.life) ~= nil
		end, "Two-packet reappearing current source did not remount")
		controller.destroy()
		controller.destroy()
		assert(
			visualFor(id) == nil and health.Adornee == adornee and health.Enabled == enabled,
			"Renderer cleanup left rig or retargeted health display"
		)
		for part, saved in originals do
			assert(
				part.LocalTransparencyModifier == saved.transparency
					and part.CFrame == saved.frame
					and part.Size == saved.size
					and part.Color == saved.color,
				"Renderer changed original source or failed to restore visibility"
			)
		end
		for decal, saved in originalDecals do
			assert(
				decal.LocalTransparencyModifier == saved.localTransparency
					and decal.Transparency == saved.transparency
					and decal.Texture == saved.texture
					and decal.Face == saved.face,
				"Renderer failed to restore an original face or changed its appearance"
			)
		end
		evidence.isolated = {
			sourceDecalsHidden = true,
			visibleFaceOnSmoothedHead = true,
			lateDecalsAndTexturesHidden = true,
			originalDecalsRestored = true,
			originalSourceRestored = true,
			healthDisplayUnique = true,
			staleTimestampRejected = true,
			freshLifeReplaced = true,
			staleLifeRejected = true,
			grounded = true,
			gripPreserved = true,
			idempotentCleanup = true,
			sourceRemovalCleanup = true,
			geometryReadiness = true,
		}
		if options.isolatedOnly then
			return
		end
		Replicated:SetAttribute(
			"MiniatureArmySmoothingProgress",
			"observe real owned army between authoritative packets"
		)
		local candidate, sourceId, life
		waitFor(function()
			for _, model in sources:GetChildren() do
				if
					model:IsA("Model")
					and model:GetAttribute("NeutralDefense") ~= true
					and tostring(model:GetAttribute("Team")):sub(1, #tostring(player.UserId) + 1)
						== tostring(player.UserId) .. ":"
				then
					local packet = Codec.decode(model:GetAttribute("PoseSnapshot"))
					local clone = packet and visualFor(model:GetAttribute("ActorId") or model.Name, packet.life)
					if clone and model:GetAttribute("Phase") == "moving" then
						candidate, sourceId, life = model, model:GetAttribute("ActorId") or model.Name, packet.life
						return true
					end
				end
			end
			return false
		end, "No real owned marching army reached smoothing observer", options.timeout or 180)
		local began, last = os.clock(), nil
		local measured = {
			frames = 0,
			sourceUpdates = 0,
			intermediateSteps = 0,
			intermediateAllFrames = 0,
			frameDurationTotal = 0,
			frameDurationMin = math.huge,
			frameDurationMax = 0,
			localDistance = 0,
			sourceDistance = 0,
			maximumLocalStep = 0,
			maximumSourceStep = 0,
			skippedSlowFrames = 0,
		}
		evidence.movement = measured
		while os.clock() - began < (options.observeSeconds or 3) do
			local dt = Run.RenderStepped:Wait()
			local packet = Codec.decode(candidate:GetAttribute("PoseSnapshot"))
			local clone = packet and visualFor(sourceId, life)
			assert(
				candidate.Parent and packet and packet.life == life and clone,
				"Observed marching life changed during bounded measurement"
			)
			local point = planar(root(clone).Position)
			local sourcePoint = planar(packet.root.Position)
			if last then
				local movement = (point - last.point).Magnitude
				measured.localDistance += movement
				if packet.time ~= last.time then
					local sourceStep = (sourcePoint - last.source).Magnitude
					measured.sourceUpdates += 1
					measured.sourceDistance += sourceStep
					measured.maximumSourceStep = math.max(measured.maximumSourceStep, sourceStep)
				elseif movement > 0.001 then
					measured.intermediateAllFrames += 1
					if dt <= 0.05 then
						measured.intermediateSteps += 1
					end
				end
				if dt <= 0.05 then
					measured.maximumLocalStep = math.max(measured.maximumLocalStep, movement)
				else
					measured.skippedSlowFrames += 1
				end
			end
			measured.frameDurationTotal += dt
			measured.frameDurationMin = math.min(measured.frameDurationMin, dt)
			measured.frameDurationMax = math.max(measured.frameDurationMax, dt)
			measured.frames += 1
			last = { point = point, source = sourcePoint, time = packet.time }
		end
		measured.frameDurationAverage = measured.frameDurationTotal / measured.frames
		measured.framesPerSecond = measured.frames / measured.frameDurationTotal
		measured.sourceUpdatesPerSecond = measured.sourceUpdates / measured.frameDurationTotal
		assert(measured.localDistance > 5 and measured.sourceDistance > 5, "Measured actor did not actually march")
		assert(
			measured.sourceUpdates >= 5 and measured.intermediateSteps >= 12,
			"Local rig only moved on authoritative updates"
		)
		assert(
			measured.maximumLocalStep < measured.maximumSourceStep * 0.8,
			"Local movement retained the server update jumps"
		)
		evidence.movement, evidence.sourceRateProof = measured, true
	end)
	if controller then
		pcall(function()
			controller.destroy()
		end)
	end
	for _, instance in temporary do
		instance:Destroy()
	end
	Replicated:SetAttribute(
		"MiniatureArmySmoothingResult",
		Http:JSONEncode({
			ok = ok,
			result = if ok then evidence else tostring(failure),
			evidence = if not ok then evidence else nil,
		})
	)
	assert(ok, failure)
	return evidence
end
return run

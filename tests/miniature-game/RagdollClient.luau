--!strict
-- Client-only clone physics. Never edits a live Battle actor, health or commander input.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong client ragdoll fixture boundary"
	)
	local templates = Replicated:WaitForChild("NativeRagdollTemplates", 15)
	assert(templates, "Run NativeRagdollSources first")
	local Codec = require(Replicated.MiniatureGame.PoseCodec)
	local Config = require(Replicated.MiniatureGame.RagdollConfig)
	local Renderer = require(Players.LocalPlayer.PlayerScripts.MiniatureGame.TroopRenderer)
	local managerModule = require(Players.LocalPlayer.PlayerScripts.MiniatureGame.Ragdolls)
	local scene = Instance.new("Folder")
	scene.Name = "RagdollClientFixture"
	scene.Parent = Workspace
	local pad = Instance.new("Part")
	pad.Name, pad.Size, pad.CFrame = "NativeCorpseSupport", Vector3.new(20, 0.4, 20), CFrame.new(550, 0.2, 550)
	pad.Anchored, pad.CanCollide, pad.CanTouch, pad.CanQuery = true, false, false, true
	pad.Transparency = 1
	pad:SetAttribute("OriginalTroopSupport", true)
	pad.Parent = scene
	local sources = Instance.new("Folder")
	sources.Name, sources.Parent = "NativeDeathSources", scene
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.Parent = "NativeRagdollOwner", Players.LocalPlayer.PlayerGui
	local settings = { sourceFolder = sources, interpolationDelay = 0.05 }
	local renderer = Renderer.start(screen, settings)
	local corpseFolder = Workspace:WaitForChild("MiniatureRagdolls_" .. sources.Name, 10)
	assert(corpseFolder, "Corpse folder missing")
	local budgetManager
	local evidence = { isolatedTemplates = true, authorityMutation = false, roles = {}, reclaimNoCorpse = false }
	local function waitFor(predicate, label, seconds)
		local stop = os.clock() + (seconds or 10)
		repeat
			if predicate() then
				return
			end
			task.wait(0.03)
		until os.clock() >= stop
		error(label)
	end
	local function mount(role, life)
		local source = templates[role]:Clone()
		source.Name = "fixture-" .. role .. life
		source:SetAttribute("ActorId", source.Name)
		source:SetAttribute("Life", life)
		source:SetAttribute("Alive", true)
		source:SetAttribute("DeathNotice", nil)
		local packet = Codec.decode(source:GetAttribute("PoseSnapshot"))
		assert(packet, "Native pose missing")
		packet.life, packet.time = life, Workspace:GetServerTimeNow() - 0.3
		packet.root = CFrame.new(550, packet.root.Y, 550) * (packet.root - packet.root.Position)
		packet.ground = 0.4
		source:SetAttribute("PoseSnapshot", Codec.encode(packet))
		source.Parent = sources
		for _ = 1, 3 do
			packet.time += 0.03
			source:SetAttribute("PoseSnapshot", Codec.encode(packet))
			task.wait(0.05)
		end
		waitFor(function()
			return renderer.folder:FindFirstChild(source.Name) ~= nil
		end, "Original corpse subject not mounted")
		return source, renderer.folder[source.Name], packet
	end
	local function corpseFor(id, life)
		for _, corpse in corpseFolder:GetChildren() do
			if corpse:IsA("Model") and corpse:GetAttribute("ActorId") == id and corpse:GetAttribute("Life") == life then
				return corpse
			end
		end
		return nil
	end
	local ok, failure = pcall(function()
		local living, visual = mount("melee", 6000)
		local before = corpseFolder:GetAttribute("Spawned")
		living:Destroy()
		task.wait(0.1)
		assert(
			visual.Parent == nil and corpseFolder:GetAttribute("Spawned") == before,
			"Reclamation/removal created a corpse"
		)
		evidence.reclaimNoCorpse = true
		local active = {}
		for index, role in { "melee", "ranged", "medic", "mounted", "crocodile" } do
			local source, drawn, packet = mount(role, 6100 + index)
			local notice = { actorId = source.Name, life = 6100 + index, time = Workspace:GetServerTimeNow() }
			source:SetAttribute(
				"DeathNotice",
				Http:JSONEncode({ actorId = source.Name, life = notice.life - 1, time = notice.time })
			)
			source:SetAttribute("Alive", false)
			task.wait(0.05)
			assert(corpseFor(source.Name, notice.life) == nil, "Stale-life notice produced a corpse")
			-- The live clone is still anchored; capture before the first physics step.
			local initialTorso = drawn.Torso.CFrame
			local initialArm = drawn.Torso.CFrame:ToObjectSpace(drawn["Right Arm"].CFrame)
			local animalLegs = {}
			for _, joint in drawn:GetDescendants() do
				if
					joint:IsA("Motor6D")
					and joint:GetAttribute("MountJoint") == true
					and joint:GetAttribute("MountJointKind") == "leg"
					and joint.Part0
					and joint.Part1
				then
					table.insert(animalLegs, {
						first = joint.Part0,
						second = joint.Part1,
						initial = joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame),
					})
				end
			end
			source:SetAttribute("DeathNotice", Http:JSONEncode(notice))
			waitFor(function()
				return corpseFor(source.Name, notice.life) ~= nil
			end, "Confirmed combat death did not produce physics")
			local corpse = corpseFor(source.Name, notice.life)
			assert(
				corpse == drawn
					and corpse:GetAttribute("CorpseSockets") >= 5
					and corpse:GetAttribute("CorpseColliders") <= Config.maxColliders,
				"Death was replaced with a pose or unbounded collider rig"
			)
			local humanoid = corpse:FindFirstChildOfClass("Humanoid")
			assert(
				humanoid and not humanoid.EvaluateStateMachine and humanoid.WalkSpeed == 0,
				"Corpse clothing Humanoid became active"
			)
			local count = corpseFolder:GetAttribute("Spawned")
			local repeated = table.clone(notice)
			repeated.time += 0.01
			source:SetAttribute("DeathNotice", Http:JSONEncode(repeated))
			task.wait(0.04)
			assert(corpseFolder:GetAttribute("Spawned") == count, "Duplicate notice created a second corpse")
			local joints = 0
			for _, object in corpse:GetDescendants() do
				if object:IsA("BallSocketConstraint") then
					assert(
						object.Enabled and object.Attachment0 and object.Attachment1,
						"Ragdoll lacks physical attachments"
					)
					joints += 1
				elseif object:IsA("BasePart") then
					assert(not object.Anchored and not object.CanTouch, "Corpse remains anchored or touch-active")
				end
			end
			assert(joints >= 5, "No physical articulation")
			local rigid = {}
			for _, joint in corpse:GetDescendants() do
				if joint:IsA("WeldConstraint") and joint.Name == "CorpseRigid" and joint.Part0 and joint.Part1 then
					table.insert(rigid, {
						first = joint.Part0,
						second = joint.Part1,
						offset = joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame),
					})
				end
			end
			table.insert(active, {
				model = corpse,
				torso = corpse.Torso,
				initial = initialTorso,
				arm = corpse["Right Arm"],
				initialArm = initialArm,
				rigid = rigid,
				animalLegs = animalLegs,
				role = role,
			})
			if index == 1 then
				source:SetAttribute("Life", notice.life + 1)
				source:SetAttribute("Alive", true)
				packet.life, packet.time = notice.life + 1, Workspace:GetServerTimeNow() - 0.2
				for _ = 1, 3 do
					packet.time += 0.03
					source:SetAttribute("PoseSnapshot", Codec.encode(packet))
					task.wait(0.05)
				end
				waitFor(function()
					return renderer.folder:FindFirstChild(source.Name) ~= nil
				end, "Replacement life failed to mount beside old corpse")
				local replacement = renderer.folder[source.Name]
				assert(
					replacement ~= corpse
						and replacement:GetAttribute("Life") == notice.life + 1
						and corpseFor(source.Name, notice.life + 1) == nil,
					"Old death marker ragdolled replacement life"
				)
				evidence.replacementLifeIndependent = true
			end
			source:Destroy()
		end
		task.wait(1)
		for _, entry in active do
			local difference = entry.initial:ToObjectSpace(entry.torso.CFrame)
			local _, angle = difference:ToAxisAngle()
			local armDelta = entry.initialArm:ToObjectSpace(entry.torso.CFrame:ToObjectSpace(entry.arm.CFrame))
			local _, armAngle = armDelta:ToAxisAngle()
			local sample = {
				role = entry.role,
				sockets = entry.model:GetAttribute("CorpseSockets"),
				colliders = entry.model:GetAttribute("CorpseColliders"),
				movement = difference.Position.Magnitude,
				rotation = angle,
				limbRotation = armAngle,
				limbDisplacement = armDelta.Position.Magnitude,
				torsoY = entry.torso.Position.Y,
				linearSpeed = entry.torso.AssemblyLinearVelocity.Magnitude,
				angularSpeed = entry.torso.AssemblyAngularVelocity.Magnitude,
			}
			table.insert(evidence.roles, sample)
			if entry.model:GetAttribute("MountAnimal") == "crocodile" then
				-- A flat crocodile already rests its belly on the ground. Its four
				-- real hip articulations establish physical collapse without forcing
				-- an unnatural whole-body flip merely to satisfy a fall-distance test.
				sample.animalLegs = {}
				assert(#entry.animalLegs == 4, "Crocodile corpse lost its four physical legs")
				for _, leg in entry.animalLegs do
					local delta = leg.initial:ToObjectSpace(leg.first.CFrame:ToObjectSpace(leg.second.CFrame))
					local _, legAngle = delta:ToAxisAngle()
					table.insert(sample.animalLegs, { rotation = legAngle, movement = delta.Position.Magnitude })
					assert(math.abs(legAngle) > 0.1, "Flat crocodile leg did not physically articulate")
				end
			else
				assert(
					difference.Position.Magnitude > 0.03 or math.abs(angle) > 0.1,
					"Physics did not actually settle/articulate"
				)
			end
			assert(
				armDelta.Position.Magnitude > 0.02 or math.abs(armAngle) > 0.1,
				"Corpse moved rigidly without limb articulation"
			)
			for _, rigid in entry.rigid do
				local actual = rigid.first.CFrame:ToObjectSpace(rigid.second.CFrame)
				assert(
					(actual.Position - rigid.offset.Position).Magnitude < 0.01
						and (actual.LookVector - rigid.offset.LookVector).Magnitude < 0.01,
					"Physical corpse detached gear or animal furniture"
				)
			end
			assert(
				entry.torso.Position.Y > 0.25 and entry.torso.Position.Y < 4,
				"Corpse fell through support or exploded upward"
			)
		end
		assert(corpseFolder:GetAttribute("ActiveSupports") == 1, "Nearby support clones not shared/bounded")
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { corpseFolder }
		params.CollisionGroup = "Default"
		assert(
			Workspace:Raycast(Vector3.new(550, 8, 550), Vector3.new(0, -12, 0), params) == nil,
			"Corpse or its support intercepted default queries"
		)
		local first = active[1].model
		waitFor(function()
			return first.Parent ~= nil and active[1].torso.Transparency > 0.1
		end, "Corpse did not fade", Config.lifetimeSeconds)
		waitFor(function()
			return corpseFolder:GetAttribute("ActiveCorpses") == 0 and corpseFolder:GetAttribute("ActiveSupports") == 0
		end, "Corpse TTL leaked physics or support", Config.lifetimeSeconds + 1)
		evidence.fadeAndTTL = true
		local manager = managerModule.start("_NativeBudget")
		budgetManager = manager
		local oldest, maxModels, maxParts = nil, 0, 0
		for index = 1, Config.maxCorpses + 2 do
			local corpse = manager.spawn(
				templates.melee:Clone(),
				{ actorId = "small-budget-" .. index, life = index, time = Workspace:GetServerTimeNow() }
			)
			oldest = oldest or corpse
			maxModels = math.max(maxModels, manager.folder:GetAttribute("ActiveCorpses"))
			maxParts = math.max(maxParts, manager.folder:GetAttribute("ActiveParts"))
			task.wait()
		end
		assert(
			manager.folder:GetAttribute("ActiveCorpses") == Config.maxCorpses
				and maxParts < Config.maxParts
				and oldest.Parent == nil,
			"Small R6 corpses did not independently exercise model cap"
		)
		evidence.modelBudget =
			{ maximumModels = maxModels, maximumParts = maxParts, evictions = manager.folder:GetAttribute("Evicted") }
		manager.clear()
		oldest, maxModels, maxParts = nil, 0, 0
		local previousEvictions = manager.folder:GetAttribute("Evicted")
		for index = 1, Config.maxCorpses + 2 do
			local corpse = manager.spawn(
				templates.crocodile:Clone(),
				{ actorId = "large-budget-" .. index, life = index, time = Workspace:GetServerTimeNow() }
			)
			oldest = oldest or corpse
			maxModels = math.max(maxModels, manager.folder:GetAttribute("ActiveCorpses"))
			maxParts = math.max(maxParts, manager.folder:GetAttribute("ActiveParts"))
			task.wait()
		end
		assert(
			manager.folder:GetAttribute("ActiveCorpses") < Config.maxCorpses
				and maxParts <= Config.maxParts
				and oldest.Parent == nil,
			"Large crocodiles did not independently exercise part cap"
		)
		evidence.partBudget = {
			maximumModels = maxModels,
			maximumParts = maxParts,
			evictions = manager.folder:GetAttribute("Evicted") - previousEvictions,
		}
		manager.clear()
		for index = 1, Config.maxSupports + 1 do
			local marker = pad:Clone()
			marker.Name = "BudgetSupport" .. index
			marker.Parent = scene
		end
		local supportSubject = templates.melee:Clone()
		supportSubject:PivotTo(supportSubject:GetPivot() + Vector3.new(550, 0, 550))
		manager.spawn(supportSubject, { actorId = "support-budget", life = 1, time = Workspace:GetServerTimeNow() })
		assert(
			manager.folder:GetAttribute("ActiveSupports") == Config.maxSupports,
			"Query-only support clone cap not exercised"
		)
		evidence.supportBudget = { maximumSupports = manager.folder:GetAttribute("ActiveSupports") }
		manager.clear()
		assert(manager.folder:GetAttribute("ActiveSupports") == 0, "Support budget cleanup leaked")
		manager.destroy()
		manager.destroy()
		assert(manager.folder.Parent == nil, "Budget manager cleanup leaked")
		evidence.budgetAndCleanup = true
		local retired = mount("melee", 6500)
		retired:SetAttribute("Alive", false)
		retired:SetAttribute(
			"DeathNotice",
			Http:JSONEncode({ actorId = retired.Name, life = 6500, time = Workspace:GetServerTimeNow() })
		)
		waitFor(function()
			return corpseFolder:GetAttribute("ActiveCorpses") == 1
		end, "Replacement cleanup subject did not ragdoll")
		local nextSources = Instance.new("Folder")
		nextSources.Name, nextSources.Parent = "NativeReplacementSources", scene
		settings.sourceFolder = nextSources
		sources:Destroy()
		waitFor(function()
			return corpseFolder:GetAttribute("ActiveCorpses") == 0 and corpseFolder:GetAttribute("ActiveSupports") == 0
		end, "Synchronous nonnil source-folder replacement leaked old corpses/supports", 1.2)
		evidence.folderReplacementCleanup = true
	end)
	if budgetManager then
		budgetManager.destroy()
	end
	renderer.destroy()
	renderer.destroy()
	screen:Destroy()
	scene:Destroy()
	assert(corpseFolder.Parent == nil, "Renderer teardown leaked corpse folder")
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if not ok then evidence else nil }
	Replicated:SetAttribute("MiniatureRagdollClientResult", Http:JSONEncode(result))
	assert(ok, failure)
	return result
end
return run

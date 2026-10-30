--!strict
-- Acquires one mounted life through normal shop controls, then observes combat.
-- No damage, actor relocation, profile edits or replacement-time injection.
return function()
	local Replicated = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local Http = game:GetService("HttpService")
	assert(game:GetService("RunService"):IsStudio(), "Mounted death flow is Studio-only")
	assert(Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong fixture store")
	local Config = require(Replicated.MiniatureGame.RagdollConfig)
	local evidence = { authoritativeMutation = false, normalPurchase = true, localRelocation = false }
	local connections = {}
	local function waitFor(predicate, message, seconds)
		local deadline = os.clock() + (seconds or 15)
		repeat
			if predicate() then
				return
			end
			task.wait(0.03)
		until os.clock() > deadline
		error(message)
	end
	local ok, failure = pcall(function()
		local purchase = require(Replicated.NativeMountedFlow)()
		evidence.purchase = purchase
		local placement = purchase.placement
		local actors = Workspace.MiniatureSandbox.BattleActors
		local source = actors:FindFirstChild(placement.actorId)
		assert(source and source:GetAttribute("Life") == placement.life, "Purchased mounted life is missing")
		local notice
		table.insert(
			connections,
			source:GetAttributeChangedSignal("DeathNotice"):Connect(function()
				notice = source:GetAttribute("DeathNotice")
			end)
		)
		local started = os.clock()
		local corpses = Workspace:WaitForChild("MiniatureRagdolls", 10)
		assert(corpses, "Real renderer has no corpse controller")
		local corpse
		local function findCorpse()
			for _, item in corpses:GetChildren() do
				if
					item:IsA("Model")
					and item:GetAttribute("ActorId") == placement.actorId
					and item:GetAttribute("Life") == placement.life
				then
					corpse = item
					return true
				end
			end
			return false
		end
		waitFor(findCorpse, "Normally purchased mounted life never produced a combat-death corpse", 180)
		assert(notice, "Ragdoll appeared without an observed server death notice")
		local decoded = Http:JSONDecode(notice)
		assert(
			decoded.actorId == placement.actorId and decoded.life == placement.life,
			"Death notice identifies a different life"
		)
		assert(
			corpse:GetAttribute("CorpseVisual") == true
				and corpse:GetAttribute("Alive") == false
				and corpse:GetAttribute("CombatActor") == false,
			"Corpse retained combat identity"
		)
		assert(corpse:FindFirstChild("MountAnimal"), "Mounted ragdoll lost its animal")
		local sockets, colliders, dynamic = 0, 0, 0
		local initial = {}
		for _, part in corpse:GetDescendants() do
			assert(not part:IsA("LuaSourceContainer"), "Corpse contains executable behavior")
			if part:IsA("BallSocketConstraint") then
				sockets += 1
			elseif part:IsA("BasePart") then
				assert(not part.CanTouch and not part.Anchored, "Corpse retained anchored/touching geometry")
				if part:GetAttribute("CorpseCollider") then
					colliders += 1
					assert(part.CollisionGroup == Config.corpseCollisionGroup, "Wrong corpse collision group")
				else
					assert(not part.CanCollide and not part.CanQuery, "Visible corpse intercepts gameplay")
				end
				initial[part] = part.CFrame
				dynamic += 1
			end
		end
		assert(sockets >= 9 and sockets <= Config.maxSockets, "Mounted anatomy/rider did not articulate")
		assert(colliders > 0 and colliders <= Config.maxColliders, "Mounted corpse collider budget differs")
		task.wait(0.75)
		local moved, rotated = 0, 0
		for part, frame in initial do
			assert(part.Parent, "Corpse expired before physical settling sample")
			if (part.Position - frame.Position).Magnitude > 0.03 then
				moved += 1
			end
			local _, angle = frame:ToObjectSpace(part.CFrame):ToAxisAngle()
			if math.abs(angle) > 0.03 then
				rotated += 1
			end
		end
		assert(moved > 0 and rotated > 0, "Mounted death remained a static pose instead of physical collapse")
		waitFor(function()
			return source.Parent == nil
		end, "Retiring dead source was not cleaned up", 2)
		evidence.death = {
			actorId = placement.actorId,
			life = placement.life,
			notice = decoded,
			combatSeconds = os.clock() - started,
			sockets = sockets,
			colliders = colliders,
			physicalParts = dynamic,
			movedParts = moved,
			rotatedParts = rotated,
		}
		waitFor(function()
			return corpse.Parent == nil
		end, "Mounted corpse exceeded its fixed lifetime", Config.lifetimeSeconds + 2)
		local replacement
		waitFor(function()
			local nextLife = actors:FindFirstChild(placement.actorId)
			if nextLife and nextLife:GetAttribute("Life") ~= placement.life then
				replacement = nextLife
				return true
			end
			return false
		end, "Building-owned mounted replacement never arrived", 15)
		assert(
			replacement:GetAttribute("Health") == 300 and replacement:GetAttribute("Alive") == true,
			"Replacement mounted health differs"
		)
		waitFor(function()
			local folder = Workspace:FindFirstChild("MiniatureClientActors")
			local clone = folder and folder:FindFirstChild(placement.actorId)
			return clone and clone:GetAttribute("Life") == replacement:GetAttribute("Life")
		end, "Replacement clone failed after old corpse cleanup")
		local hud = Players.LocalPlayer.PlayerGui.MiniatureSandboxHUD
		assert(hud.SettlementHUD.Resources.Text:find("Army 2/10", 1, true), "Death changed weighted army allocation")
		evidence.replacement = {
			life = replacement:GetAttribute("Life"),
			health = replacement:GetAttribute("Health"),
			oldSourceRemoved = source.Parent == nil,
			oldCorpseRemoved = corpse.Parent == nil,
			weightedCapacity = 2,
		}
	end)
	for _, connection in connections do
		connection:Disconnect()
	end
	Replicated:SetAttribute(
		"MiniatureMountedDeathFlowResult",
		Http:JSONEncode({
			ok = ok,
			result = if ok then evidence else tostring(failure),
			evidence = if not ok then evidence else nil,
		})
	)
	assert(ok, failure)
	return evidence
end

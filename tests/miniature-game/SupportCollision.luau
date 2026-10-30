--!strict
-- Physical and query checks for sandbox-only corpse support collision groups.
return function()
	local Physics = game:GetService("PhysicsService")
	local Replicated = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	assert(game:GetService("RunService"):IsStudio(), "Support collision check is Studio-only")
	assert(Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong fixture storage")
	local Config = require(Replicated.MiniatureGame.RagdollConfig)
	local scene = Workspace:FindFirstChild("MiniatureSandbox")
	assert(scene and scene.Ground.CollisionGroup == Config.groundCollisionGroup, "Sandbox ground group missing")
	for _, plot in scene.Plots:GetChildren() do
		assert(plot.Plot.CollisionGroup == Config.groundCollisionGroup, "Plot support collision group differs")
	end
	local function collides(a, b)
		return Physics:CollisionGroupsAreCollidable(a, b)
	end
	assert(collides("Default", Config.groundCollisionGroup), "Commander no longer collides with ground")
	assert(collides(Config.corpseCollisionGroup, Config.groundCollisionGroup), "Corpse cannot land on ground")
	assert(collides(Config.corpseCollisionGroup, Config.supportCollisionGroup), "Corpse cannot land on art support")
	assert(not collides(Config.corpseCollisionGroup, "Default"), "Corpse can block commanders")
	assert(not collides(Config.corpseCollisionGroup, Config.corpseCollisionGroup), "Corpses can collide together")
	assert(not collides(Config.supportCollisionGroup, "Default"), "Cosmetic support can block commanders")
	assert(not collides(Config.supportCollisionGroup, Config.supportCollisionGroup), "Cosmetic supports collide")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "NativeSupportCollisionFixture", Workspace
	local function part(name, position, size, group, anchored)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.CollisionGroup = name, size, position, group
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = anchored, true, false, false
		p.Parent = folder
		return p
	end
	local result
	local ok, failure = pcall(function()
		local point = Vector3.new(520, 0, -520)
		local ground =
			part("Ground", point - Vector3.yAxis * 0.5, Vector3.new(16, 1, 16), Config.groundCollisionGroup, true)
		ground.CanQuery = true
		local corpse = part("CorpseProxy", point + Vector3.yAxis * 4, Vector3.one, Config.corpseCollisionGroup, true)
		local support = part("ArtSupport", point + Vector3.yAxis * 6, Vector3.one, Config.supportCollisionGroup, true)
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances, params.CollisionGroup =
			Enum.RaycastFilterType.Include, { folder }, "Default"
		params.RespectCanCollide = false
		local ray = Workspace:Raycast(point + Vector3.yAxis * 10, -Vector3.yAxis * 20, params)
		assert(ray and ray.Instance == ground, "Default gameplay ray hit cosmetic proxy/support")
		local overlap = OverlapParams.new()
		overlap.FilterType, overlap.FilterDescendantsInstances, overlap.CollisionGroup =
			Enum.RaycastFilterType.Include, { folder }, "Default"
		overlap.RespectCanCollide = false
		local found =
			Workspace:GetPartBoundsInBox(CFrame.new(point + Vector3.yAxis * 3), Vector3.new(10, 10, 10), overlap)
		assert(#found == 1 and found[1] == ground, "Default overlap included cosmetic physics")
		local commander = part("CommanderProxy", point + Vector3.xAxis * 5, Vector3.one, "Default", true)
		assert(
			not commander:CanCollideWith(corpse) and not commander:CanCollideWith(support),
			"Corpse/support blocks default character"
		)
		corpse:Destroy()
		support:Destroy()
		local ordinary = part("DefaultFaller", point + Vector3.new(-2, 4, 0), Vector3.one * 0.5, "Default", false)
		local body =
			part("CorpseFaller", point + Vector3.new(2, 4, 0), Vector3.one * 0.5, Config.corpseCollisionGroup, false)
		ordinary:SetNetworkOwner(nil)
		body:SetNetworkOwner(nil)
		task.wait(2)
		assert(math.abs(ordinary.Position.Y - 0.25) < 0.2, "Default physics no longer lands on sandbox ground")
		assert(math.abs(body.Position.Y - 0.25) < 0.2, "Corpse physics did not land on sandbox ground")
		result = {
			plots = #scene.Plots:GetChildren(),
			rayAndOverlapExcluded = true,
			commanderUnblocked = true,
			defaultGroundHeight = ordinary.Position.Y,
			corpseGroundHeight = body.Position.Y,
		}
	end)
	folder:Destroy()
	assert(ok, failure)
	Replicated:SetAttribute("MiniatureSupportCollisionResult", game:GetService("HttpService"):JSONEncode(result))
	return result
end

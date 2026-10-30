--!strict
-- Native server transport/factory boundary; temporary simulation and visual templates only.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong ragdoll source fixture boundary"
	)
	local Server = game:GetService("ServerScriptService").Sandbox
	local Original = require(Server.OriginalTroops)
	local Mounted = require(Server.MountedTroops)
	local Config = require(Replicated.MiniatureGame.RagdollConfig)
	local fingerprint = require(ServerStorage.TemplateFingerprint)
	local before = fingerprint()
	local templates = Instance.new("Folder")
	templates.Name = "NativeRagdollTemplates"
	local old = Replicated:FindFirstChild(templates.Name)
	if old then
		old:Destroy()
	end
	for index, role in { "melee", "ranged", "medic", "mounted" } do
		local model = if role == "mounted" then Mounted.create("sparta") else Original.create("sparta", role)
		model.Name = role
		model:SetAttribute("ActorId", "native-" .. role)
		model:SetAttribute("Life", index + 5000)
		model:SetAttribute("Alive", true)
		Original.pose(model, { x = 0, z = 0, headingX = 0, headingZ = 1, phase = "idle" }, 1, 0.4)
		model.Parent = templates
	end
	local crocodile = Mounted.create("egypt")
	crocodile.Name = "crocodile"
	crocodile:SetAttribute("ActorId", "native-crocodile")
	crocodile:SetAttribute("Life", 5005)
	crocodile:SetAttribute("Alive", true)
	Original.pose(crocodile, { x = 0, z = 0, headingX = 0, headingZ = 1, phase = "idle" }, 1, 0.4)
	crocodile.Parent = templates
	templates.Parent = Replicated
	local World = require(Server.OutpostWorld)
	local Battle = require(Server.Battle)
	local model = Instance.new("Model")
	local world = { scene = model, plots = {} }
	for index = 1, 8 do
		table.insert(world.plots, { frame = CFrame.new(index * 80, 0, 0) })
	end
	local controller = World.create(world)
	local battle = Battle.new(controller.definitions)
	controller:syncActors(battle, 0)
	local id, actor = next(battle.actors)
	local source = model.BattleActors[id]
	local deadline = actor.respawnAt
	local clone = table.clone(battle)
	clone.actors = table.clone(battle.actors)
	local dead = table.clone(actor)
	dead.health, dead.alive, dead.phase, dead.respawnAt = 0, false, "dead", 8
	clone.actors[id] = dead
	clone.events = { { kind = "death", actorId = id, actorLife = actor.life, time = 1 } }
	controller:syncActors(clone, 1)
	local notice = game:GetService("HttpService"):JSONDecode(source:GetAttribute("DeathNotice"))
	assert(
		source.Parent and source:GetAttribute("Alive") == false and notice.actorId == id and notice.life == actor.life,
		"Exact-life death was not retained and marked"
	)
	assert(
		actor.alive and actor.health == actor.maxHealth and actor.respawnAt == deadline and dead.respawnAt == 8,
		"Visual transport mutated actor health or respawn clock"
	)
	task.wait(Config.sourceRetireSeconds + 0.1)
	assert(source.Parent == nil, "Retiring death source outlived its bound")
	controller:syncActors(battle, 2)
	local captured = model.BattleActors[id]
	local captureView = table.clone(battle)
	captureView.actors = table.clone(battle.actors)
	captureView.actors[id] = nil
	captureView.events = { { kind = "death", actorId = id, actorLife = actor.life, time = 2 } }
	controller:syncActors(captureView, 2)
	local captureNotice = game:GetService("HttpService"):JSONDecode(captured:GetAttribute("DeathNotice"))
	assert(
		captured.Parent and captureNotice.life == actor.life,
		"Capture-removed actor lost its exact-life death visual"
	)
	task.wait(Config.sourceRetireSeconds + 0.1)
	assert(captured.Parent == nil, "Capture-removed death source exceeded retirement bound")
	controller:syncActors(battle, 2)
	local reclaimed = model.BattleActors[id]
	local removed = table.clone(battle)
	removed.actors = table.clone(battle.actors)
	removed.actors[id] = nil
	removed.events = {}
	controller:syncActors(removed, 2)
	assert(
		reclaimed.Parent == nil and reclaimed:GetAttribute("DeathNotice") == nil,
		"Ordinary removal produced death metadata"
	)
	controller:syncActors(battle, 3)
	local stale = model.BattleActors[id]
	local wrong = table.clone(clone)
	wrong.events = { { kind = "death", actorId = id, actorLife = actor.life - 1, time = 3 } }
	controller:syncActors(wrong, 3)
	assert(
		stale.Parent == nil and stale:GetAttribute("DeathNotice") == nil,
		"Stale death event marked another actor life"
	)
	controller:destroy()
	model:Destroy()
	assert(fingerprint() == before, "Ragdoll templates mutated original sources")
	local result = {
		templates = 5,
		exactLifeDeath = true,
		captureRemovedActorDeath = true,
		boundedRetirement = true,
		ordinaryRemovalNotDeath = true,
		staleLifeRejected = true,
		authorityAndRespawnUnchanged = true,
		originalSourcesImmutable = true,
	}
	Replicated:SetAttribute(
		"MiniatureRagdollSourcesResult",
		game:GetService("HttpService"):JSONEncode({ ok = true, result = result })
	)
	return result
end
return run

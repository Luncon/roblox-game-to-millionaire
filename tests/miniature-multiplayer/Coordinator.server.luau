--!strict
-- Real connected clients send normal guarded requests; this script observes, never injects gameplay state.
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Storage = game:GetService("ServerStorage")
local Testing = game:GetService("StudioTestService")
local State = require(game:GetService("ServerScriptService").Sandbox.State)
assert(game:GetService("RunService"):IsStudio(), "Three-player coordinator is Studio-only")
local started, phase, finished = os.clock(), "startup", false
local visibleRun = false
local evidence = {
	method = "Three real Studio clients; scripted ordinary RemoteEvents and Humanoid movement; Coin-only fake profiles",
	phases = {},
	players = {},
	outposts = {},
	reports = {},
	observations = { contested = false, defended = false, paused = false },
	actorLifeChanges = 0,
}
local control = Instance.new("Folder")
control.Name = "MiniatureThreePlayerTest"
local command, report = Instance.new("RemoteEvent"), Instance.new("RemoteEvent")
command.Name, report.Name = "Command", "Report"
command.Parent, report.Parent = control, control
local resultValue = Instance.new("StringValue")
resultValue.Name, resultValue.Parent = "Result", control
local responses, connections = {}, {}
local deadline = started + 600
local Context = require(Storage:WaitForChild("ThreePlayerContext"))
local assigned, claims, history, lives = {}, {}, {}, {}
local function stage(name)
	phase = name
	control:SetAttribute("Phase", name)
	game:SetAttribute("MiniatureThreePlayerPhase", name)
	table.insert(evidence.phases, { phase = name, elapsed = os.clock() - started })
	print("Three-player: " .. name)
end
local function endTest(result)
	if finished then
		return
	end
	finished = true
	result.elapsed, result.phase, result.evidence = os.clock() - started, phase, evidence
	control:SetAttribute("EndTest", true)
	command:FireAllClients({ name = "stop" })
	for _, connection in connections do
		connection:Disconnect()
	end
	local encoded = Http:JSONEncode(result)
	resultValue.Value = encoded
	game:SetAttribute("MiniatureThreePlayerResult", encoded)
	print("MiniatureThreePlayerResult " .. encoded)
	task.wait(0.2)
	if visibleRun then
		print("Three-player visible run finished; bots stopped and Studio world remains open")
	else
		Testing:EndTest(result)
	end
end
local function view(player)
	return Context.sessions:snapshot(player.UserId)
end
local function sample()
	if Context.error then
		error("Bootstrap failed: " .. Context.error)
	end
	if not Context.scene then
		return
	end
	local posts = Context.scene:FindFirstChild("Outposts")
	if posts then
		for _, post in posts:GetChildren() do
			local id = post:GetAttribute("OutpostId")
			if type(id) ~= "string" then
				continue
			end
			local status, progress = post:GetAttribute("CaptureStatus"), post:GetAttribute("CaptureProgress") or 0
			local owner, capture = post:GetAttribute("OwnerCivilizationId"), post:GetAttribute("CaptureTeam")
			local previous = history[id]
			local record = evidence.outposts[id]
			if not record then
				record = { transitions = {}, maxProgress = 0 }
				evidence.outposts[id] = record
			end
			record.maxProgress = math.max(record.maxProgress, progress)
			if not previous or previous.status ~= status or previous.owner ~= owner or previous.capture ~= capture then
				if #record.transitions < 200 then
					table.insert(record.transitions, {
						elapsed = os.clock() - started,
						status = status,
						progress = progress,
						owner = owner,
						captureTeam = capture,
						defenders = post:GetAttribute("NeutralDefenders"),
					})
				end
			end
			if status == "contested" then
				evidence.observations.contested = true
			end
			if status == "defended" then
				evidence.observations.defended = true
			end
			if
				previous
				and (status == "defended" or status == "contested")
				and previous.status == status
				and previous.capture == capture
				and math.abs(previous.progress - progress) < 0.0001
			then
				evidence.observations.paused = true
			end
			history[id] = { status = status, progress = progress, owner = owner, capture = capture }
		end
	end
	local actors = Context.scene:FindFirstChild("BattleActors")
	if actors then
		for _, actor in actors:GetChildren() do
			local id, life = actor:GetAttribute("ActorId"), actor:GetAttribute("Life")
			if type(id) == "string" and type(life) == "number" then
				if lives[id] and lives[id] ~= life then
					evidence.actorLifeChanges += 1
				end
				lives[id] = life
			end
		end
	end
	for index, player in assigned do
		assert(player.Parent == Players, "A real test client disconnected")
		if claims[index] then
			local snapshot = view(player)
			assert(
				snapshot.writable
					and snapshot.claim
					and snapshot.claim.plotId == claims[index].plotId
					and snapshot.claim.civilizationId == claims[index].civilizationId,
				"Combat changed a home plot claim or lost write authority"
			)
		end
	end
end
local function waitFor(predicate, description, seconds)
	local untilTime = math.min(deadline, os.clock() + seconds)
	repeat
		for _, response in responses do
			if response.failed then
				error("Client failed: " .. tostring(response.failed.error))
			end
		end
		sample()
		if predicate() then
			return
		end
		task.wait(0.2)
	until os.clock() >= untilTime
	error("Timed out: " .. description)
end
local function postFor(index)
	return Context.scene.Outposts:FindFirstChild("outpost_" .. claims[index].plotId)
end
local function owned(index, civilization)
	local post = postFor(index)
	if not post or post:GetAttribute("OwnerCivilizationId") ~= civilization then
		return false
	end
	local flag = post:FindFirstChild("Flag", true)
	return flag ~= nil and flag:GetAttribute("OwnerCivilizationId") == civilization
end
local function send(index, payload)
	command:FireClient(assigned[index], payload)
end
table.insert(
	connections,
	report.OnServerEvent:Connect(function(player, payload)
		if finished or type(payload) ~= "table" or type(payload.name) ~= "string" then
			return
		end
		local index = player:GetAttribute("ThreePlayerIndex")
		if
			type(index) ~= "number"
			or assigned[index] ~= player
			or payload.index ~= index
			or payload.userId ~= player.UserId
		then
			return
		end
		if
			payload.name ~= "ready"
			and payload.name ~= "prepared"
			and payload.name ~= "reduced"
			and payload.name ~= "ordered"
			and payload.name ~= "failed"
		then
			return
		end
		responses[index] = responses[index] or {}
		responses[index][payload.name] = payload
		if #evidence.reports < 60 then
			table.insert(evidence.reports, payload)
		end
	end)
)
control.Parent = Replicated
task.delay(600, function()
	if not finished then
		endTest({ ok = false, message = "Hard watchdog timeout" })
	end
end)
local ok, message = pcall(function()
	local args
	waitFor(function()
		-- Explicitly marked verification place only; ordinary projects do not map this coordinator.
		if game:GetAttribute("MiniatureThreePlayerVisible") == true or script:GetAttribute("VisibleRun") == true then
			visibleRun = true
			args = { suite = "miniature-three-player", timeout = 600 }
			return true
		end
		args = Testing:GetTestArgs()
		return type(args) == "table"
	end, "multiplayer test arguments", 30)
	assert(args.suite == "miniature-three-player", "Wrong multiplayer test suite")
	evidence.launchMode = if visibleRun
		then "Visible Studio Server & Clients"
		else "StudioTestService ExecuteMultiplayerTestAsync"
	control:SetAttribute("VisibleRun", visibleRun)
	deadline = started + math.clamp(tonumber(args.timeout) or 560, 480, 600)
	waitFor(function()
		return Context.sessions ~= nil and #Players:GetPlayers() == 3
	end, "Runtime and exactly three connected clients", 60)
	local ordered = Players:GetPlayers()
	table.sort(ordered, function(a, b)
		return a.UserId < b.UserId
	end)
	for i, player in ordered do
		assigned[i] = player
		player:SetAttribute("ThreePlayerIndex", i)
	end
	stage("three clients ready")
	waitFor(function()
		return responses[1]
			and responses[1].ready
			and responses[2]
			and responses[2].ready
			and responses[3]
			and responses[3].ready
	end, "three ready client controllers", 60)
	assert(Context.store.isFakeProfileStore, "Real storage is forbidden")
	for _, player in assigned do
		local record = Context.store:read("miniature-development:" .. player.UserId)
		local cultures = 0
		assert(record and record.civilizations, "Coin-only profile was not seeded")
		for _, state in record.civilizations do
			cultures += 1
			assert(
				state.coins == 20000
					and next(state.militaryResearch.completed) == nil
					and state.militaryResearch.project == nil,
				"Fixture seeded military progression"
			)
			for _, amount in state.goods do
				assert(amount == 0, "Fixture seeded goods")
			end
			for _, amount in State.troops(state) do
				assert(amount == 0, "Fixture seeded an army")
			end
		end
		assert(cultures == 13, "Fixture omitted civilization profiles")
	end
	evidence.seed = {
		connectedPlayers = #Players:GetPlayers(),
		civilizationsPerPlayer = 13,
		coinsPerCivilization = 20000,
		goods = 0,
		completedResearch = 0,
		troops = 0,
	}
	evidence.neutralGarrisons = {}
	for _, post in Context.scene.Outposts:GetChildren() do
		local id = post:GetAttribute("OutpostId")
		local roles = { melee = 0, ranged = 0, medic = 0, mounted = 0 }
		for _, actor in Context.scene.BattleActors:GetChildren() do
			if actor:GetAttribute("Team") == "neutral:" .. id and (actor:GetAttribute("Health") or 0) > 0 then
				local role = actor:GetAttribute("Role")
				assert(roles[role] ~= nil, "Neutral garrison has an unknown role")
				roles[role] += 1
			end
		end
		assert(
			roles.melee == 2 and roles.ranged == 1 and roles.medic == 0 and roles.mounted == 0,
			"Initial real garrison differs from two melee and one ranged"
		)
		evidence.neutralGarrisons[id] = roles
	end
	local cultures = { "sparta", "rome", "egypt" }
	stage("ordinary purchases placements and paid research")
	for i = 1, 3 do
		send(
			i,
			{ name = "prepare", civilizationId = cultures[i], composition = { training = 2, ranged = 2, healer = 1 } }
		)
	end
	waitFor(function()
		return responses[1].prepared and responses[2].prepared and responses[3].prepared
	end, "three independently prepared armies", 120)
	for i, player in assigned do
		local snapshot = view(player)
		assert(
			snapshot.claim and snapshot.claim.civilizationId == cultures[i] and snapshot.writable,
			"Client claimed wrong home"
		)
		claims[i] = table.clone(snapshot.claim)
		local research = snapshot.state.militaryResearch
		assert(
			snapshot.state.coins == 17800
				and (
					research.completed.army_training == true
					or research.project and research.project.id == "army_training"
				),
			"Purchases/research were not independently paid"
		)
		local troops = State.troops(snapshot.state)
		assert(
			troops.melee == 4 and troops.ranged == 4 and troops.medic == 1,
			"Real building troops differ from nine-person muster"
		)
		evidence.players[i] = {
			userId = player.UserId,
			civilizationId = cultures[i],
			plotId = snapshot.claim.plotId,
			coins = snapshot.state.coins,
			stock = snapshot.state.merchant.stock,
			stockCycle = snapshot.state.merchant.cycle,
			troopCounts = troops,
		}
		for j = 1, i - 1 do
			assert(claims[j].plotId ~= claims[i].plotId, "Two real players share a home plot")
		end
	end
	stage("three concurrent neutral outpost captures")
	waitFor(function()
		return owned(1, cultures[1]) and owned(2, cultures[2]) and owned(3, cultures[3])
	end, "all three actual 20-second captures and culture flags", 150)
	evidence.initialCaptures = {}
	for i = 1, 3 do
		evidence.initialCaptures[i] = {
			outpostId = postFor(i).Name,
			owner = postFor(i):GetAttribute("OwnerCivilizationId"),
			neutralDefenders = postFor(i):GetAttribute("NeutralDefenders"),
		}
		assert(postFor(i):GetAttribute("NeutralDefenders") == 0, "Captured neutral garrison remained")
	end
	stage("owner A legitimately returns two buildings to inventory")
	send(1, { name = "reduce", composition = { training = 1, ranged = 1, healer = 1 } })
	waitFor(function()
		return responses[1].reduced ~= nil
	end, "real reclamation to five troops", 60)
	local reduced = State.troops(view(assigned[1]).state)
	assert(
		reduced.melee == 2 and reduced.ranged == 2 and reduced.medic == 1,
		"Owner A did not reduce to five through real building returns"
	)
	local targetA = postFor(1).Name
	stage("two rival real clients converge on owner A")
	send(2, { name = "attack", outpostId = targetA })
	send(3, { name = "attack", outpostId = targetA })
	waitFor(function()
		return responses[2].ordered
			and responses[2].ordered.outpostId == targetA
			and responses[3].ordered
			and responses[3].ordered.outpostId == targetA
	end, "two accepted native client orders", 90)
	waitFor(function()
		if postFor(1):GetAttribute("CaptureStatus") == "contested" then
			return true
		end
		local actors = Context.scene.BattleActors
		local teamC = tostring(assigned[3].UserId) .. ":egypt:" .. claims[3].plotId
		for _, actor in actors:GetChildren() do
			if
				actor:GetAttribute("Team") == teamC
				and (actor:GetAttribute("Health") or 0) > 0
				and actor.PrimaryPart
				and (actor.PrimaryPart.Position - postFor(1):GetPivot().Position).Magnitude < 22
			then
				return true
			end
		end
		return false
	end, "third army actually reaches contested target", 110)
	stage("third client retargets home; Rome must take Spartan outpost")
	responses[3].ordered = nil
	send(3, { name = "attack", outpostId = postFor(3).Name })
	waitFor(function()
		return responses[3].ordered and responses[3].ordered.outpostId == postFor(3).Name
	end, "third real client accepted retarget", 80)
	waitFor(function()
		return owned(1, "rome")
	end, "observed Roman takeover and updated physical flag", 150)
	for i, player in assigned do
		local snapshot = view(player)
		assert(snapshot.state.coins == 17800, "Combat or another player changed private Coins")
		assert(
			snapshot.state.militaryResearch.completed.army_training == true
				and snapshot.state.militaryResearch.project == nil,
			"Independent real-time research did not finish"
		)
		local expectedStock = if snapshot.state.merchant.cycle == evidence.players[i].stockCycle
			then evidence.players[i].stock
			else State.freshStock(snapshot.state)
		for _, kind in { "training", "ranged", "healer" } do
			assert(
				snapshot.state.merchant.stock[kind] == expectedStock[kind],
				"Private stock changed outside its own restock cycle"
			)
		end
		evidence.players[i].finalCoins = snapshot.state.coins
		evidence.players[i].finalResearch = snapshot.state.militaryResearch
		evidence.players[i].finalStock = snapshot.state.merchant.stock
		evidence.players[i].finalStockCycle = snapshot.state.merchant.cycle
	end
	assert(#Players:GetPlayers() == 3, "Three real clients did not remain connected")
	evidence.takeover = {
		outpostId = targetA,
		previousCivilizationId = "sparta",
		ownerCivilizationId = postFor(1):GetAttribute("OwnerCivilizationId"),
		ownerTeam = postFor(1):GetAttribute("OwnerTeam"),
		progress = postFor(1):GetAttribute("CaptureProgress"),
	}
	stage("passed")
end)
endTest({
	ok = ok,
	message = if ok
		then "Three real players captured separate outposts, fought together and Rome took Sparta's outpost without losing home claims"
		else tostring(message),
})

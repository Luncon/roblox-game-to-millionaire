--!strict
-- Three genuine Studio clients, scripted ordinary requests and Humanoid walking.
-- This is not concurrent GUI input, a model-only battle or a state/position grant.
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local stopped, busy, prepared = false, false, false
local connections: { RBXScriptConnection } = {}
local latest, protocol, reportRemote, actions
local index = 0
local phase = "startup"
local attempts = {}
local replies = {}
local sequence, lastRequest = 0, -math.huge
local generation = Http:GenerateGUID(false):sub(1, 12)
local walking = false
local walkGoal: Vector3? = nil
local binding = "MiniatureThreePlayerWalk_" .. generation

local function humanoid()
	local character = player.Character
	local life = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return life, root
end
local function move()
	if stopped or not walkGoal then
		return
	end
	local life, root = humanoid()
	if life and root and life.Health > 0 then
		local delta = walkGoal - root.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		life:Move(if flat.Magnitude > 0.75 then flat.Unit else Vector3.zero, false)
	end
end
local function stopMovement()
	walkGoal = nil
	if walking then
		Run:UnbindFromRenderStep(binding)
		walking = false
	end
	local life = humanoid()
	if life then
		life:Move(Vector3.zero, false)
	end
end
local function cleanup()
	if stopped then
		return
	end
	stopped = true
	stopMovement()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end
local function report(name, fields)
	if stopped or not reportRemote then
		return
	end
	local packet = fields or {}
	packet.name, packet.index, packet.userId = name, index, player.UserId
	packet.inputMode = "Scripted real client requests and Humanoid movement; no GUI input"
	packet.clientTime = os.clock()
	reportRemote:FireServer(packet)
end
local function waitFor(predicate, label, seconds)
	local deadline = os.clock() + (seconds or 20)
	repeat
		if stopped then
			error("Three-player test stopped")
		end
		if predicate() then
			return
		end
		task.wait(0.05)
	until os.clock() >= deadline
	error(label)
end
local function request(action, args)
	phase = action
	local remote = actions:FindFirstChild(action)
	assert(remote and remote:IsA("RemoteEvent"), "Three-player game action unavailable: " .. action)
	for attempt = 1, 5 do
		local spacing = 0.35 - (os.clock() - lastRequest)
		if spacing > 0 then
			task.wait(spacing)
		end
		assert(not stopped and latest and latest.loaded and latest.writable, "Three-player writer not ready")
		sequence += 1
		local id = generation .. ":" .. sequence
		local before = latest
		local intent = {
			requestId = id,
			sessionId = before.sessionId,
			claimEpoch = before.claimEpoch,
			revision = before.revision,
			args = args,
		}
		local _, commanderRoot = humanoid()
		local sentPosition = commanderRoot and commanderRoot.Position
		lastRequest = os.clock()
		remote:FireServer(intent)
		waitFor(function()
			return replies[id] ~= nil
		end, "Three-player missing receipt: " .. action, 12)
		local packet = replies[id]
		replies[id] = nil
		table.insert(attempts, {
			action = action,
			attempt = attempt,
			requestId = id,
			sentAt = lastRequest,
			receivedAt = os.clock(),
			sessionId = intent.sessionId,
			claimEpoch = intent.claimEpoch,
			revision = intent.revision,
			serverTime = packet.snapshot and packet.snapshot.serverTime,
			coinsBefore = before.state and before.state.coins,
			coinsAfter = packet.snapshot and packet.snapshot.state and packet.snapshot.state.coins,
			ok = packet.result.ok,
			reason = packet.result.reason,
			clientPosition = sentPosition and { x = sentPosition.X, y = sentPosition.Y, z = sentPosition.Z },
			plotDistance = sentPosition and before.plotFrame and (sentPosition - before.plotFrame.Position).Magnitude,
		})
		if packet.result.ok then
			return packet
		end
		assert(
			packet.result.reason == "stale_revision" and attempt < 5,
			"Three-player action refused: " .. action .. "/" .. tostring(packet.result.reason)
		)
		-- A refusal includes the fresh authoritative snapshot. New IDs are used
		-- only for explicit stale-revision retries; no unacknowledged resubmits.
		assert(packet.snapshot and packet.snapshot.revision >= intent.revision, "Stale rejection omitted fresh state")
	end
	error("Three-player stale retry exhausted")
end
local function travel(destination)
	local packet = request("travel", { destination = destination })
	assert(packet.result.destination == destination, "Three-player travel destination differs")
	-- The receipt can arrive before the character's physical replication. Wait
	-- for a sustained legitimate arrival before issuing any spatial action.
	local target = if destination == "civilization"
		then latest.plotFrame.Position
		elseif destination == "buy" then latest.buyShopPosition
		else latest.sellShopPosition
	local range = if destination == "civilization" then 60 else 9
	local settledAt
	waitFor(function()
		local life, root = humanoid()
		if life and root and life.Health > 0 and (root.Position - target).Magnitude <= range then
			settledAt = settledAt or os.clock()
			return os.clock() - settledAt >= 0.5
		end
		settledAt = nil
		return false
	end, "Three-player travel character did not physically arrive: " .. destination, 20)
end
local function walkTo(point: Vector3): (number, number)
	local began = os.clock()
	local distance, lastPosition, lastProgress = 0, nil, os.clock()
	walkGoal = point
	if not walking then
		walking = true
		Run:BindToRenderStep(binding, Enum.RenderPriority.Last.Value + 1, move)
	end
	local ok, failure = pcall(function()
		repeat
			assert(not stopped, "Three-player walking stopped")
			local life, root = humanoid()
			assert(life and root and life.Health > 0, "Three-player commander lost its living character")
			local position = root.Position
			if lastPosition then
				local delta = position - lastPosition
				local step = Vector3.new(delta.X, 0, delta.Z).Magnitude
				distance += step
				if step > 0.05 then
					lastProgress = os.clock()
				end
			end
			lastPosition = position
			local delta = point - position
			if Vector3.new(delta.X, 0, delta.Z).Magnitude <= 5 then
				return
			end
			assert(
				os.clock() - began < 60 and os.clock() - lastProgress < 12,
				"Three-player commander stuck at " .. tostring(position) .. " toward " .. tostring(point)
			)
			task.wait(0.1)
		until stopped
	end)
	stopMovement()
	assert(ok, failure)
	return distance, os.clock() - began
end
local function composition(value)
	local result = value or { training = 2, ranged = 2, healer = 1 }
	for _, kind in { "training", "ranged" } do
		assert(result[kind] == 1 or result[kind] == 2, "Unsupported bot troop composition")
	end
	assert(result.healer == 1, "Bot requires one medic building")
	return result
end
local function preparedReport(name, extra)
	local packet = extra or {}
	packet.civilizationId = latest.claim.civilizationId
	packet.plotId = latest.claim.plotId
	for id, post in latest.outposts do
		if post.lineId == latest.claim.plotId then
			packet.outpostId = id
			break
		end
	end
	packet.coins, packet.troops = latest.state.coins, latest.troops
	packet.capacity, packet.capacityUsed = latest.troopCapacity, latest.troopCapacityUsed
	packet.research = latest.state.militaryResearch
	packet.requests = attempts
	report(name, packet)
end
local function prepare(command)
	assert(not prepared, "Bot already prepared")
	local wanted = composition(command.composition)
	local civilizationId = command.civilizationId or ({ "sparta", "rome", "egypt" })[index]
	assert(civilizationId == ({ "sparta", "rome", "egypt" })[index], "Three-player civilization/index mismatch")
	local Placement = require(Replicated.MiniatureGame.Placement)
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	if not latest.claim then
		request("select", { civilizationId = civilizationId })
	end
	assert(
		latest.claim.civilizationId == civilizationId and #latest.state.buildings == 3,
		"Three-player settlement not fresh"
	)
	local sites = {}
	local available =
		{ training = { { 16, -22 }, { 28, -22 } }, ranged = { { 16, 12 }, { 28, 12 } }, healer = { { -28, 12 } } }
	local proposed = table.clone(latest.state.buildings)
	for _, kind in { "training", "ranged", "healer" } do
		for n = 1, wanted[kind] do
			local location = available[kind][n]
			local valid, why = Placement.validate(proposed, kind, location[1], location[2], 0)
			assert(valid, "Three-player proposed site illegal: " .. tostring(why))
			local site = { kind = kind, x = location[1], z = location[2], rotation = 0 }
			table.insert(sites, site)
			table.insert(proposed, { id = "proposed-" .. #sites, kind = kind, x = site.x, z = site.z, rotation = 0 })
		end
	end
	local initialCoins, price = latest.state.coins, 1000
	travel("buy")
	for _, site in sites do
		local beforeCoins, beforePlans = latest.state.coins, latest.state.plans[site.kind]
		local packet = request("buy", { kind = site.kind })
		local cost = Catalog.buildings[site.kind].price
		assert(
			packet.snapshot.state.coins == beforeCoins - cost
				and packet.snapshot.state.plans[site.kind] == beforePlans + 1,
			"Three-player purchase ledger differs"
		)
		price += cost
	end
	travel("civilization")
	for _, site in sites do
		phase = "walk inside placement range"
		walkTo(latest.plotFrame.Position)
		-- Allow the final real Humanoid movement to replicate. The server still
		-- performs its ordinary placement-distance check on every request.
		task.wait(0.5)
		local coins, plans = latest.state.coins, latest.state.plans[site.kind]
		local packet = request("place", site)
		assert(
			packet.snapshot.state.coins == coins and packet.snapshot.state.plans[site.kind] == plans - 1,
			"Three-player placement double charged"
		)
	end
	local research = request("militaryResearch", { id = "army_training" })
	assert(research.snapshot.state.coins == initialCoins - price, "Three-player total buy/research ledger differs")
	assert(
		latest.troops.melee == wanted.training * 2
			and latest.troops.ranged == wanted.ranged * 2
			and latest.troops.medic == 1,
		"Three-player allocated composition differs"
	)
	assert(
		latest.troopCapacity == 10 and latest.troopCapacityUsed == wanted.training * 2 + wanted.ranged * 2 + 1,
		"Three-player army exceeded unchanged capacity"
	)
	prepared = true
	preparedReport("prepared", { composition = wanted })
end
local function reduce(command)
	assert(prepared, "Cannot reduce before paid preparation")
	local wanted = composition(command.composition or { training = 1, ranged = 1, healer = 1 })
	local counts = { training = 0, ranged = 0, healer = 0 }
	for _, building in latest.state.buildings do
		if counts[building.kind] then
			counts[building.kind] += 1
		end
	end
	local remove = {}
	for n = #latest.state.buildings, 1, -1 do
		local building = latest.state.buildings[n]
		if counts[building.kind] and counts[building.kind] > wanted[building.kind] then
			table.insert(remove, table.clone(building))
			counts[building.kind] -= 1
		end
	end
	local coins, removedIds = latest.state.coins, {}
	for _, building in remove do
		phase = "walk to reclaim " .. building.id
		walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(building.x, 0.4, building.z)))
		local plans = latest.state.plans[building.kind]
		request("reclaim", { buildingId = building.id })
		assert(
			latest.state.coins == coins and latest.state.plans[building.kind] == plans + 1,
			"Three-player reclaim lost plan or changed Coins"
		)
		table.insert(removedIds, building.id)
	end
	assert(
		latest.troops.melee == wanted.training * 2
			and latest.troops.ranged == wanted.ranged * 2
			and latest.troops.medic == 1,
		"Reduced army differs from requested composition"
	)
	preparedReport("reduced", { composition = wanted, removedIds = removedIds })
end
local function attack(command)
	assert(prepared and type(command.outpostId) == "string", "Three-player attack requires prepared troops and outpost")
	local post = latest.outposts[command.outpostId]
	assert(post, "Three-player attack names no capturable outpost")
	phase = "walk to " .. command.outpostId
	local distance, seconds = walkTo(post.position + Vector3.new((index - 2) * 2, 0, 3))
	local packet = request("targetOutpost", { outpostId = command.outpostId })
	assert(latest.army.targetId == command.outpostId and latest.army.manual == true, "Three-player army order differs")
	local _, root = humanoid()
	report("ordered", {
		outpostId = command.outpostId,
		distance = root and (root.Position - post.position).Magnitude,
		nativeWalkDistance = distance,
		travelSeconds = seconds,
		requestId = packet.requestId,
		claimEpoch = latest.claimEpoch,
		coins = latest.state.coins,
		requests = attempts,
	})
end

local ok, failure = pcall(function()
	assert(Run:IsStudio(), "Three-player bot is Studio-only")
	waitFor(function()
		return Replicated:GetAttribute("MiniatureThreePlayerFixture") == true
	end, "Missing three-player fixture marker", 60)
	protocol = Replicated:WaitForChild("MiniatureThreePlayerTest", 30)
	assert(protocol, "Three-player protocol not mapped")
	local commandRemote = protocol:WaitForChild("Command", 15)
	reportRemote = protocol:WaitForChild("Report", 15)
	assert(commandRemote and reportRemote, "Three-player protocol remotes missing")
	table.insert(
		connections,
		protocol:GetAttributeChangedSignal("EndTest"):Connect(function()
			if protocol:GetAttribute("EndTest") == true then
				cleanup()
			end
		end)
	)
	table.insert(connections, protocol.Destroying:Connect(cleanup))
	table.insert(connections, script.Destroying:Connect(cleanup))
	table.insert(connections, Run.Heartbeat:Connect(move))
	waitFor(function()
		local value = player:GetAttribute("ThreePlayerIndex")
		if type(value) == "number" and value >= 1 and value <= 3 then
			index = value
			return true
		end
		return false
	end, "Three-player role was not assigned", 30)
	assert(
		player:WaitForChild("PlayerGui"):WaitForChild("MiniatureSandboxHUD", 45),
		"Three-player main HUD unavailable"
	)
	actions = Replicated:WaitForChild("MiniatureActions", 45)
	assert(actions, "Three-player ordinary game remotes unavailable")
	table.insert(
		connections,
		actions.Receipt.OnClientEvent:Connect(function(packet)
			if packet.snapshot then
				latest = packet.snapshot
			end
			if packet.requestId and packet.result then
				replies[packet.requestId] = packet
			end
		end)
	)
	local nextSnapshot = 0
	waitFor(function()
		if os.clock() >= nextSnapshot then
			actions.Snapshot:FireServer()
			nextSnapshot = os.clock() + 1
		end
		return latest
			and latest.loaded
			and latest.writable
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore"
	end, "Three-player writable snapshot unavailable", 45)
	table.insert(
		connections,
		commandRemote.OnClientEvent:Connect(function(command)
			if type(command) ~= "table" then
				return
			end
			if command.name == "stop" then
				cleanup()
				return
			end
			if stopped then
				return
			end
			if busy then
				report("failed", { phase = phase, error = "Overlapping bot command", requests = attempts })
				return
			end
			busy = true
			task.spawn(function()
				local success, message = pcall(function()
					if command.name == "prepare" then
						prepare(command)
					elseif command.name == "reduce" then
						reduce(command)
					elseif command.name == "attack" then
						attack(command)
					else
						error("Unknown three-player bot command")
					end
				end)
				stopMovement()
				busy = false
				if not success and not stopped then
					report("failed", { phase = phase, error = tostring(message), requests = attempts })
				end
			end)
		end)
	)
	phase = "ready"
	report("ready", { sessionId = latest.sessionId, claimEpoch = latest.claimEpoch })
end)
if not ok then
	report("failed", { phase = phase, error = tostring(failure), requests = attempts })
	cleanup()
	warn("Three-player client fixture failed: " .. tostring(failure))
end

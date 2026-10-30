--!strict
-- Adversarial network round trips in a dedicated fake-store session. Malformed
-- intents are intentional; successful travel/purchase remain real server actions.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong remote test boundary"
	)
	local player = Players.LocalPlayer
	local actions = Replicated.MiniatureActions
	local latest, serial = nil, 0
	local prefix = "network:" .. Http:GenerateGUID(false):sub(1, 16) .. ":"
	local responses, evidence = {}, { networkRoundTrips = true, store = "InjectedFakeProfileStore", refusals = {} }
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId then
			responses[packet.requestId] = packet
		end
	end)
	local function waitFor(predicate, label)
		local stop = os.clock() + 8
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() >= stop
		error(label)
	end
	local function envelope(args)
		serial += 1
		return {
			requestId = prefix .. serial,
			sessionId = latest.sessionId,
			claimEpoch = latest.claimEpoch,
			revision = latest.revision,
			args = args,
		}
	end
	local function send(action, payload)
		responses[payload.requestId] = nil
		actions[action]:FireServer(payload)
		waitFor(function()
			return responses[payload.requestId] ~= nil
		end, "Missing native refusal/receipt")
		local packet = responses[payload.requestId]
		task.wait(0.3)
		return packet
	end
	local function copy(value)
		if type(value) ~= "table" then
			return value
		end
		local result = {}
		for key, child in value do
			result[key] = copy(child)
		end
		return result
	end
	local function same(a, b)
		if type(a) ~= type(b) then
			return false
		end
		if type(a) ~= "table" then
			return a == b
		end
		for key, value in a do
			if not same(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	local function protected()
		local state = copy(latest.state)
		-- Farm output and merchant cycle advance normally during network waits.
		for _, building in state.buildings do
			building.output = nil
		end
		state.merchant = nil
		return state
	end
	local ok, failure = pcall(function()
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.state and latest.writable
		end, "No writable owner")
		local coins, plans = latest.state.coins, latest.state.plans.training
		local initial = protected()
		local cases = {
			{ "modern unlock", "militaryResearch", { id = "mech_station" }, "invalid_research" },
			{ "broken prerequisite", "militaryResearch", { id = "elite_training" }, "research_predecessor" },
			{
				"forged price/balance",
				"militaryResearch",
				{ id = "officer_training", price = 0, coins = 1000000000 },
				"invalid_research",
			},
			{ "locked army", "configureArmy", { armyId = 2, buildingIds = {} }, "army_locked" },
			{ "read-only all army", "configureArmy", { armyId = 1, buildingIds = {} }, "army_readonly" },
			{ "nonfinite army", "configureArmy", { armyId = 0 / 0, buildingIds = {} }, "invalid_request" },
			{ "Instance argument", "militaryResearch", { id = Replicated }, "invalid_request" },
			{ "remote outpost", "targetOutpost", { outpostId = "outpost_2", armyId = 1 }, "out_of_range" },
			{ "nonexistent reclaim", "reclaim", { buildingId = "b999999" }, "out_of_range" },
		}
		for _, case in cases do
			local payload = envelope(case[3])
			local packet = send(case[2], payload)
			assert(
				not packet.result.ok and packet.result.reason == case[4],
				case[1] .. " gave " .. tostring(packet.result.reason)
			)
			assert(
				latest.state.coins == coins and latest.state.plans.training == plans,
				"Refused request changed value"
			)
			assert(same(protected(), initial), "Refused request changed protected civilization progress")
			table.insert(evidence.refusals, { name = case[1], reason = packet.result.reason })
		end
		for _, case in { "foreign session", "stale epoch", "stale revision" } do
			local payload = envelope({ id = "officer_training" })
			if case == "foreign session" then
				payload.sessionId = "another-owner-session"
			elseif case == "stale epoch" then
				payload.claimEpoch = latest.claimEpoch - 1
			else
				payload.revision = latest.revision - 1
			end
			local packet = send("militaryResearch", payload)
			assert(not packet.result.ok, "Stale/foreign research accepted")
			assert(latest.state.coins == coins, "Stale request spent Coins")
			assert(same(protected(), initial), "Stale request changed protected civilization progress")
			table.insert(evidence.refusals, { name = case, reason = packet.result.reason })
		end
		local travel = send("travel", envelope({ destination = "buy" }))
		assert(travel.result.ok and travel.result.destination == "buy", "Native shop travel failed")
		local baseRevision = latest.revision
		local payload = envelope({ kind = "training", price = 0, coins = 1000000000, ownerId = -123 })
		local purchase = send("buy", payload)
		assert(
			purchase.result.ok and latest.state.coins == coins - 250 and latest.state.plans.training == plans + 1,
			"Client price or balance overrode server price"
		)
		local paid = protected()
		local replay = send("buy", payload)
		assert(
			replay.result.ok and latest.state.coins == coins - 250 and latest.state.plans.training == plans + 1,
			"Native replay double-charged"
		)
		assert(same(protected(), paid), "Replay changed paid progress")
		payload.args.kind = "mount"
		local reuse = send("buy", payload)
		assert(
			not reuse.result.ok and reuse.result.reason == "request_id_reused" and same(protected(), paid),
			"Reused request ID changed operation or progress"
		)
		evidence.purchase = { charged = 250, plansAdded = 1, replayCharged = 0, previousRevision = baseRevision }
		evidence.coins = latest.state.coins
		local target = latest.buyShopPosition
		assert(
			(player.Character.HumanoidRootPart.Position - target).Magnitude < 12,
			"Commander did not arrive at server buy stall"
		)
	end)
	connection:Disconnect()
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if ok then nil else evidence }
	Replicated:SetAttribute("MiniatureMilitaryRemoteGuardsResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

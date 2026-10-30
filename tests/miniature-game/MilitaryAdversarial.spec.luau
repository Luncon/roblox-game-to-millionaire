--!strict
-- Actual server modules, explicit in-memory stores and deterministic clocks only.
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local State = require(Server.State)
local Actions = require(Server.Actions)
local ActiveTime = require(Server.ActiveTime)
local Sessions = require(Server.Sessions)
local Requests = require(Server.Requests)
local Rules = require(Shared.MilitaryResearch)
local Research = require(Server.MilitaryResearch)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

-- Independent transcription of the supplied reference: row, adopted ID,
-- price, active seconds, prerequisite reference row. No catalog-derived oracle.
local reference = {
	{ 1, "army_training", 1000, 30 },
	{ 2, "officer_training", 25000, 60, 1 },
	{ 3, "elite_training", 2500000, 1800, 2 },
	{ 7, "army_control", 5000, 60, 2 },
	{ 8, "army_slot_2", 25000, 60, 7 },
	{ 9, "army_slot_3", 250000, 60, 8 },
	{ 10, "army_size_1", 50000, 300, 1 },
	{ 11, "army_size_2", 5000000, 1800, 10 },
	{ 12, "army_size_3", 100000000, 43200, 11 },
	{ 15, "scout_training", 100000, 600, 10 },
	{ 16, "night_scouts", 250000, 1800, 15 },
	{ 17, "signal_beacons", 1000000, 3600, 16 },
	{ 18, "mounted_drills", 100000, 300, 2 },
	{ 19, "mounted_weapons", 10000000, 1800, 18 },
	{ 20, "elite_rider_training", 250000000, 14400, 19 },
	{ 21, "rider_conditioning", 250000, 900, 18 },
	{ 22, "forage_logistics", 1000000, 1800, 21 },
	{ 23, "swift_mounts", 10000000, 9000, 22 },
	{ 26, "field_bandages", 10000, 60, 1 },
	{ 27, "field_medicine", 250000, 1800, 26 },
	{ 28, "veteran_resilience", 100000000, 7200, 27 },
	{ 29, "marching_sandals", 50000, 300, 2 },
	{ 30, "campaign_rations", 250000, 1800, 29 },
	{ 31, "forced_march", 50000000, 3600, 30 },
	{ 32, "mounted_armor", 250000, 600, 18 },
	{ 33, "reinforced_barding", 1000000, 1800, 32 },
	{ 34, "masterwork_barding", 500000000, 7200, 33 },
	{ 35, "rider_scouts", 1000000, 1800, 21 },
	{ 36, "rider_signals", 25000000, 3600, 35 },
}

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS military adversarial: " .. name)
	end
	local function same(a, b): boolean
		if type(a) ~= type(b) then
			return false
		end
		if type(a) == "number" and a ~= a then
			return b ~= b
		end
		if type(a) ~= "table" then
			return a == b
		end
		for k, v in a do
			if not same(v, b[k]) then
				return false
			end
		end
		for k in b do
			if a[k] == nil then
				return false
			end
		end
		return true
	end
	local byRow = {}
	for _, row in reference do
		byRow[row[1]] = row
	end
	local function ancestors(parentRow)
		local result = {}
		while parentRow do
			local row = byRow[parentRow]
			result[row[2]] = true
			parentRow = row[5]
		end
		return result
	end
	local function fixture()
		local f = { now = 0, alive = true, enabled = true, commits = 0, lastTick = 0, clocks = {} }
		local store = FakeStore.new()
		local sparta, rome = State.new("sparta", 0), State.new("rome", 0)
		-- Explicit fake-only funding; full buffers isolate research revisions.
		sparta.coins, rome.coins = 100000, 100000
		sparta.buildings[3].output, rome.buildings[3].output = 60, 60
		store:seed("miniature-development:501", { schemaVersion = 1, civilizations = { sparta = sparta, rome = rome } })
		local serial = 0
		local options = {
			store = store,
			clock = function()
				return f.now
			end,
			token = function()
				serial += 1
				return "adversarial-" .. serial
			end,
		}
		local sessions = Sessions.new(options)
		assert(sessions:load(501).ok and sessions:select(501, "sparta").ok, "Adversarial setup failed")
		local function advance(candidate, timers)
			return ActiveTime.step(candidate, timers, f.now, math.max(0, f.now - f.lastTick), f.alive and f.enabled, 0)
		end
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return f.now
			end,
			context = function()
				return { alive = f.alive, inRange = true }
			end,
			handlers = {
				militaryResearch = function(candidate, args)
					local timers = State.copy(f.clocks)
					advance(candidate, timers)
					local result = Actions.apply(candidate, "militaryResearch", args, f.now)
					if f.afterHandler then
						f.afterHandler()
					end
					return result, { clocks = timers, time = f.now }
				end,
			},
			prepareSelection = function(candidate)
				advance(candidate, State.copy(f.clocks))
				return candidate
			end,
			afterCommit = function(_, action, _, timing)
				f.commits += 1
				if action == "select" then
					f.lastTick, f.clocks = f.now, {}
				else
					f.lastTick, f.clocks = timing.time, timing.clocks
				end
			end,
		})
		function f.intent(id, args)
			local view = sessions:snapshot(501)
			return {
				requestId = id,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = args,
			}
		end
		function f.tick()
			local current = sessions:current(501)
			assert(current, "Tick requires current authority")
			local result = advance(current, f.clocks)
			f.lastTick = f.now
			if result.revisionChanged then
				sessions:bump(501)
			end
			return result
		end
		f.sessions, f.gateway, f.store, f.options = sessions, gateway, store, options
		return f
	end

	assert(#reference == 29 and #Rules.order == 29, "Reference transaction coverage incomplete")
	for _, row in reference do
		check("exact reference transaction row " .. row[1] .. " " .. row[2], function()
			local id, price, duration = row[2], row[3], row[4]
			local definition = Rules.nodes[id]
			local parent = if row[5] then byRow[row[5]][2] else nil
			assert(
				definition.referenceRow == row[1]
					and definition.price == price
					and definition.duration == duration
					and definition.predecessor == parent,
				"Reference cost duration or path changed"
			)
			local state = State.new("sparta", 0)
			state.coins = price
			state.militaryResearch.completed = ancestors(row[5])
			if parent then
				state.militaryResearch.completed = {}
				local before = State.copy(state)
				assert(
					Actions.apply(state, "militaryResearch", { id = id }, 0).reason == "research_predecessor"
						and same(before, state),
					"Missing ancestry partially paid"
				)
				state.militaryResearch.completed = ancestors(row[5])
			end
			state.coins = price - 1
			local before = State.copy(state)
			assert(
				Actions.apply(state, "militaryResearch", { id = id }, 0).reason == "insufficient_resources"
					and same(before, state),
				"Unaffordable reference project mutated state"
			)
			state.coins = price
			assert(
				State.validate(state, "sparta") and Actions.apply(state, "militaryResearch", { id = id }, 0).ok,
				"Eligible reference transaction failed"
			)
			assert(
				state.coins == 0 and state.militaryResearch.project.remaining == duration,
				"Price or initial duration wrong"
			)
			before = State.copy(state)
			assert(
				Actions.apply(state, "militaryResearch", { id = id }, 0).reason == "research_busy"
					and same(before, state),
				"Busy reference project charged twice"
			)
			local clocks = {}
			local result = ActiveTime.step(state, clocks, duration - 0.125, duration - 0.125, true, 0)
			assert(
				state.militaryResearch.project.remaining == 0.125 and not result.revisionChanged,
				"Reference timer completed early or revised on partial time"
			)
			ActiveTime.step(state, clocks, 1000000 + duration, 1000000, false, 0)
			assert(state.militaryResearch.project.remaining == 0.125, "Inactive time completed reference tier")
			ActiveTime.step(state, clocks, 1000000 + duration + 0.0625, 0.0625, true, 0)
			assert(
				state.militaryResearch.project.remaining == 0.0625 and not state.militaryResearch.completed[id],
				"Fractional active boundary lost"
			)
			result = ActiveTime.step(state, clocks, 1000000 + duration + 0.125, 0.0625, true, 0)
			assert(
				result.militaryResearch.completed == id
					and result.revisionChanged
					and state.militaryResearch.completed[id]
					and state.militaryResearch.project == nil,
				"Exact reference completion failed"
			)
			before = State.copy(state)
			assert(
				Actions.apply(state, "militaryResearch", { id = id }, 0).reason == "research_complete"
					and same(before, state),
				"Completed reference tier charged again"
			)
			assert(State.validate(state, "sparta"), "Reference project completion produced invalid saved state")
		end)
	end
	check("malformed cyclic deep oversized and client-priced requests cannot throw charge or advance state", function()
		local f = fixture()
		local cyclic = { id = "army_training" }
		cyclic.self = cyclic
		local wide = {}
		for i = 1, 129 do
			wide["k" .. i] = true
		end
		local bytes = {}
		for i = 1, 40 do
			bytes["k" .. i] = string.rep("x", 128)
		end
		local deep = { id = "army_training", extra = { one = { two = { three = true } } } }
		local badArgs = {
			cyclic,
			wide,
			bytes,
			deep,
			{},
			{ id = "mech_station" },
			{ id = math.huge },
			{ id = 0 / 0 },
			{ id = false },
			{ id = "army_training", price = 0 },
			{ id = "army_training", remaining = 0 },
			{ [1] = "army_training" },
			{
				id = function()
					error("Client callback executed")
				end,
			},
		}
		for i, args in badArgs do
			f.now += 0.3
			local before = f.sessions:snapshot(501).state
			local ok, result = pcall(function()
				return f.gateway:handle(501, "militaryResearch", f.intent("malformed-" .. i, args))
			end)
			assert(
				ok and not result.ok and same(before, f.sessions:snapshot(501).state),
				"Malformed payload threw or mutated progress"
			)
		end
		local mutations = {
			function(p)
				p.requestId = ""
			end,
			function(p)
				p.requestId = string.rep("x", 65)
			end,
			function(p)
				p.sessionId = "wrong"
			end,
			function(p)
				p.claimEpoch = -1
			end,
			function(p)
				p.claimEpoch = 0.5
			end,
			function(p)
				p.revision = math.huge
			end,
			function(p)
				p.balance = 1000000
			end,
			function(p)
				p.args = 3
			end,
		}
		for i, mutate in mutations do
			f.now += 0.3
			local p = f.intent("envelope-" .. i, { id = "army_training" })
			mutate(p)
			assert(not f.gateway:handle(501, "militaryResearch", p).ok, "Malformed envelope accepted")
		end
		assert(
			f.commits == 0
				and f.sessions:current(501).coins == 100000
				and f.sessions:current(501).militaryResearch.project == nil,
			"Invalid request changed research or committed timing"
		)
	end)
	check("duplicate competing and mutated receipts preserve one charge and one timing commit", function()
		local f = fixture()
		local request = f.intent("once", { id = "army_training" })
		local result = f.gateway:handle(501, "militaryResearch", request)
		assert(result.ok, "Initial research request failed")
		result.researchId = "corrupted-client-copy"
		assert(
			f.gateway:handle(501, "militaryResearch", request).researchId == "army_training",
			"Client mutated cached receipt"
		)
		local conflict = State.copy(request)
		conflict.requestId = "competing"
		assert(
			f.gateway:handle(501, "militaryResearch", conflict).reason == "stale_revision",
			"Competing stale transaction accepted"
		)
		local reused = State.copy(request)
		reused.args.id = "field_bandages"
		assert(
			f.gateway:handle(501, "militaryResearch", reused).reason == "request_id_reused",
			"Request ID accepted a new project"
		)
		assert(
			f.gateway:handle(501, "militaryResearch", f.intent("busy", { id = "army_training" })).reason
				== "research_busy",
			"Second independent start accepted"
		)
		assert(
			f.sessions:current(501).coins == 99000
				and f.sessions:current(501).militaryResearch.project.remaining == 30
				and f.commits == 1,
			"Replay or refusal changed payment or clocks"
		)
	end)
	check("invalidating a life or crossing the lease deadline rejects even a previously cached purchase", function()
		local f = fixture()
		local request = f.intent("life", { id = "army_training" })
		assert(f.gateway:handle(501, "militaryResearch", request).ok, "Setup request failed")
		f.sessions:invalidate(501)
		assert(
			f.gateway:handle(501, "militaryResearch", request).reason == "stale_session",
			"Old-life receipt bypassed epoch"
		)
		f.alive = false
		assert(
			f.gateway:handle(501, "militaryResearch", f.intent("dead", { id = "army_training" })).reason
				== "owner_not_alive",
			"Dead owner started research"
		)
		f.alive = true
		f.now = 60
		assert(
			f.gateway:handle(501, "militaryResearch", request).reason == "profile_not_writable",
			"Cached receipt bypassed lease expiration"
		)
		assert(f.sessions:snapshot(501).state.coins == 99000 and f.commits == 1, "Lost authority mutated research")
	end)
	check("rate-limited burst cannot restart a project or acquire extra active time", function()
		local f = fixture()
		local accepted, limited = 0, 0
		for i = 1, 40 do
			local result = f.gateway:handle(501, "militaryResearch", f.intent("burst-" .. i, { id = "army_training" }))
			if result.ok then
				accepted += 1
			end
			if result.reason == "rate_limited" then
				limited += 1
			end
		end
		assert(accepted == 1 and limited == 32 and f.commits == 1, "Burst admission or exact-once start changed")
		f.now = 0.25
		assert(
			f.gateway:handle(501, "militaryResearch", f.intent("refilled", { id = "army_training" })).reason
				== "research_busy",
			"Refilled token bypassed active project"
		)
		assert(
			f.sessions:current(501).coins == 99000 and f.sessions:current(501).militaryResearch.project.remaining == 30,
			"Rejected burst committed a candidate timer"
		)
	end)
	check(
		"failed candidate settlement is discarded and the next active endpoint credits elapsed time exactly once",
		function()
			local f = fixture()
			f.gateway:handle(501, "militaryResearch", f.intent("start", { id = "army_training" }))
			f.now = 29
			assert(
				not f.gateway:handle(501, "militaryResearch", f.intent("bad", { id = "modern_future" })).ok,
				"Invalid project accepted"
			)
			assert(
				f.sessions:current(501).militaryResearch.project.remaining == 30 and f.lastTick == 0,
				"Rejected request committed clocks or progress"
			)
			f.tick()
			assert(
				f.sessions:current(501).militaryResearch.project.remaining == 1 and f.lastTick == 29,
				"Endpoint lost elapsed research"
			)
			f.now = 30
			f.tick()
			assert(
				f.sessions:current(501).militaryResearch.completed.army_training
					and f.sessions:current(501).coins == 99000,
				"Endpoint duplicated progress or charge"
			)
		end
	)
	check("commit-time lease recheck discards a paid private candidate after authority expires", function()
		local f = fixture()
		f.afterHandler = function()
			f.now = 60
		end
		local result =
			f.gateway:handle(501, "militaryResearch", f.intent("expiry-during-handler", { id = "army_training" }))
		assert(result.reason == "invalid_result" and f.commits == 0, "Expired candidate committed")
		local state = f.sessions:snapshot(501).state
		assert(
			state.coins == 100000 and state.militaryResearch.project == nil and f.lastTick == 0,
			"Expired private candidate leaked payment or timing"
		)
	end)
	check(
		"civilization switches preserve distinct fractional durations through save release and fresh reacquisition",
		function()
			local f = fixture()
			f.gateway:handle(501, "militaryResearch", f.intent("sparta-start", { id = "army_training" }))
			local old = f.intent("old-sparta", { id = "army_training" })
			f.now = 7.25
			assert(
				f.gateway:handle(501, "select", f.intent("to-rome", { civilizationId = "rome" })).ok,
				"First switch failed"
			)
			assert(
				f.gateway:handle(501, "militaryResearch", old).reason == "stale_session",
				"Old civilization payload accepted"
			)
			assert(
				f.gateway:handle(501, "militaryResearch", f.intent("rome-start", { id = "army_training" })).ok,
				"Independent Roman project failed"
			)
			f.now = 12.5
			assert(
				f.gateway:handle(501, "select", f.intent("to-sparta", { civilizationId = "sparta" })).ok,
				"Return switch failed"
			)
			assert(
				f.sessions:current(501).militaryResearch.project.remaining == 22.75,
				"Returning civilization gained foreign active time"
			)
			f.enabled = false
			f.now = 42.5
			f.tick()
			assert(f.sessions:current(501).militaryResearch.project.remaining == 22.75, "Paused civilization advanced")
			assert(f.sessions:release(501).ok, "Pending research release failed")
			f.now = 100000
			local fresh = Sessions.new(f.options)
			assert(fresh:load(501).ok and fresh:select(501, "sparta").ok, "Fresh writer failed")
			assert(
				fresh:current(501).militaryResearch.project.remaining == 22.75 and fresh:current(501).coins == 99000,
				"Spartan restore changed time or payment"
			)
			assert(
				fresh:select(501, "rome").ok
					and fresh:current(501).militaryResearch.project.remaining == 24.75
					and fresh:current(501).coins == 99000,
				"Roman restore changed independent time or payment"
			)
			assert(fresh:snapshot(501).sessionId ~= old.sessionId, "Reacquired writer reused old session identity")
		end
	)
	check(
		"failed fake save preserves last committed progress and successful replayed retry does not repay research",
		function()
			local f = fixture()
			f.gateway:handle(501, "militaryResearch", f.intent("start", { id = "army_training" }))
			f.now = 5
			f.tick()
			assert(f.sessions:save(501).ok, "First save failed")
			local saved = f.store:read("miniature-development:501")
			f.now = 10
			f.tick()
			f.store:queue({ beforeError = "Injected offline fake storage" })
			local commits = #f.store.commits
			assert(
				f.sessions:save(501).reason == "save_failed" and #f.store.commits == commits,
				"Failed fake write committed"
			)
			assert(same(saved, f.store:read("miniature-development:501")), "Failed save overwrote prior progress")
			assert(
				f.sessions:current(501).militaryResearch.project.remaining == 20,
				"Failed save rolled back in-memory timer"
			)
			f.store:queue({ replay = 5 })
			assert(f.sessions:save(501).ok and f.sessions:release(501).ok, "Replayed retry or release failed")
			f.now = 10000
			local fresh = Sessions.new(f.options)
			assert(fresh:load(501).ok and fresh:select(501, "sparta").ok, "Saved retry did not reacquire")
			assert(
				fresh:current(501).coins == 99000 and fresh:current(501).militaryResearch.project.remaining == 20,
				"Retry replay duplicated payment or progress"
			)
		end
	)
	check("acknowledgement loss after commit preserves paid progress and release retry cannot overwrite it", function()
		local f = fixture()
		f.gateway:handle(501, "militaryResearch", f.intent("start", { id = "army_training" }))
		f.now = 8
		f.tick()
		f.store:queue({ afterError = "Injected lost acknowledgement" })
		assert(f.sessions:release(501).reason == "save_failed", "Fixture did not lose release acknowledgement")
		local committed = f.store:read("miniature-development:501")
		assert(
			committed.lease == nil
				and committed.civilizations.sparta.coins == 99000
				and committed.civilizations.sparta.militaryResearch.project.remaining == 22,
			"Acknowledged failure lost committed research"
		)
		assert(f.sessions:release(501).reason == "authority_lost", "Uncertain release retried with a missing lease")
		assert(same(committed, f.store:read("miniature-development:501")), "Uncertain release overwrote committed data")
		local fresh = Sessions.new(f.options)
		assert(
			fresh:load(501).ok
				and fresh:select(501, "sparta").ok
				and fresh:current(501).militaryResearch.project.remaining == 22,
			"Fresh load discarded an acknowledged-lost commit"
		)
	end)
	check("conflicting lease takeover during a save cannot overwrite the newer owner's research", function()
		local f = fixture()
		f.gateway:handle(501, "militaryResearch", f.intent("start", { id = "army_training" }))
		f.now = 5
		f.tick()
		assert(f.sessions:save(501).ok, "Setup save failed")
		local foreign = f.store:read("miniature-development:501")
		foreign.lease = { token = "other-authority", expiresAt = 999 }
		foreign.civilizations.sparta.coins = 77777
		foreign.civilizations.sparta.militaryResearch.project.remaining = 23
		f.store:queue({
			beforeCommit = function()
				f.store:seed("miniature-development:501", foreign)
			end,
		})
		f.now = 10
		f.tick()
		assert(f.sessions:save(501).reason == "authority_lost", "Lease conflict did not revoke writer")
		assert(same(foreign, f.store:read("miniature-development:501")), "Old writer overwrote conflicting progress")
		assert(
			f.gateway:handle(501, "militaryResearch", f.intent("lost-writer", { id = "army_training" })).reason
				== "profile_not_writable",
			"Lost writer could start another transaction"
		)
	end)
	check("malformed saved military records fail load without replacing original civilization progress", function()
		local corrupt = {
			false,
			{},
			{ completed = { unknown = true } },
			{ completed = { army_training = false } },
			{ completed = { officer_training = true } },
			{ completed = {}, project = { id = "army_training", remaining = 0 } },
			{ completed = {}, project = { id = "army_training", remaining = -1 } },
			{ completed = {}, project = { id = "army_training", remaining = 31 } },
			{ completed = {}, project = { id = "army_training", remaining = 0 / 0 } },
			{ completed = {}, project = { id = "army_training", remaining = math.huge } },
			{ completed = {}, project = { id = "army_training", remaining = 1, paid = false } },
			{ completed = { army_training = true }, project = { id = "army_training", remaining = 1 } },
			{ completed = {}, project = { id = "officer_training", remaining = 30 } },
		}
		for i, bad in corrupt do
			local store = FakeStore.new()
			local state = State.new("sparta", 0)
			state.coins = 12345
			state.militaryResearch = bad
			local record = { schemaVersion = 1, civilizations = { sparta = state } }
			store:seed("miniature-development:502", record)
			local sessions = Sessions.new({
				store = store,
				clock = function()
					return 0
				end,
				token = function()
					return "corrupt-" .. i
				end,
			})
			assert(
				not sessions:load(502).ok and #store.commits == 0 and not sessions:writable(502),
				"Malformed progress became a fresh writable record"
			)
			assert(same(record, store:read("miniature-development:502")), "Rejected corrupt save was overwritten")
		end
	end)
	check("excess completion elapsed never pre-pays active time into the next project", function()
		local state = State.new("sparta", 0)
		state.coins = 100000
		Research.start(state, "army_training")
		ActiveTime.step(state, {}, 10000, 10000, true, 0)
		assert(
			Research.start(state, "officer_training").ok and state.militaryResearch.project.remaining == 60,
			"Excess elapsed banked into new project"
		)
		assert(
			not Research.step(state, 0, true).changed and state.militaryResearch.project.remaining == 60,
			"Zero elapsed advanced a new project"
		)
	end)
	return count
end
return run

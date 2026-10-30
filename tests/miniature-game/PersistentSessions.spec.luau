--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Sessions = require(Server.Sessions)
local State = require(Server.State)
local Actions = require(Server.Actions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

local function fixture(persistent: boolean?)
	local f = { now = 0, serial = 0, beforeTransform = nil }
	f.store = FakeStore.new()
	if persistent then
		f.store.isFakeProfileStore = nil
		f.store.isPersistentProfileStore = true
		f.store.keyPrefix = "player:"
	end
	local update = f.store.UpdateAsync
	function f.store:UpdateAsync(key, transform)
		if f.beforeTransform then
			local callback = f.beforeTransform
			f.beforeTransform = nil
			callback()
		end
		return update(self, key, transform)
	end
	f.options = {
		store = f.store,
		clock = function()
			return f.now
		end,
		token = function()
			f.serial += 1
			return "durable-" .. f.serial
		end,
	}
	f.sessions = Sessions.new(f.options)
	return f
end

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature durable sessions: " .. name)
	end
	check("acquisition timestamps start at the actual storage callback", function()
		local f = fixture()
		f.beforeTransform = function()
			f.now = 30
		end
		assert(f.sessions:load(1).ok, "Delayed acquisition failed")
		assert(f.store:read("miniature-development:1").lease.expiresAt == 90, "Lease used pre-yield timestamp")
	end)
	check("renewal timestamps start at the replayed storage callback", function()
		local f = fixture()
		assert(f.sessions:load(1).ok, "Setup load failed")
		f.now = 10
		f.beforeTransform = function()
			f.now = 30
		end
		assert(f.sessions:save(1).ok, "Delayed renewal failed")
		assert(f.store:read("miniature-development:1").lease.expiresAt == 90, "Renewal used pre-yield timestamp")
	end)
	check("conflicting callback replay recomputes acquisition expiry", function()
		local f = fixture()
		f.store:queue({
			beforeCommit = function()
				f.now = 25
				f.store:seed("miniature-development:1", { schemaVersion = 1, civilizations = {} })
			end,
		})
		assert(f.sessions:load(1).ok and f.store.callbacks == 2, "Conflict did not replay acquisition")
		assert(f.store:read("miniature-development:1").lease.expiresAt == 85, "Replayed callback reused stale expiry")
	end)
	check("observed local expiry is terminal even when a delayed renewal returns", function()
		local f = fixture()
		assert(f.sessions:load(1).ok and f.sessions:select(1, "sparta").ok, "Setup failed")
		f.now = 40
		f.store:queue({
			beforeCommit = function()
				f.now = 61
				assert(not f.sessions:writable(1), "Expired lease remained writable")
			end,
		})
		assert(not f.sessions:save(1).ok, "Delayed response revived lost authority")
		assert(not f.sessions:writable(1) and f.sessions:current(1) == nil, "Terminal expiry revived")
		assert(f.sessions:snapshot(1).profileStatus == "lost", "Lost status missing")
	end)
	check("uncertain acquisition retries reuse the exact token", function()
		local f = fixture()
		f.store:queue({ afterError = "Acquisition committed; response lost" })
		assert(f.sessions:load(1).reason == "load_failed", "Lost acknowledgement fixture failed")
		local token = f.store:read("miniature-development:1").lease.token
		assert(f.sessions:load(1).ok and f.serial == 1, "Retry orphaned its own lease")
		assert(f.sessions:snapshot(1).sessionId == token, "Retry changed acquisition identity")
	end)
	check("cancelled uncertain acquisition clears only its own token without writing defaults", function()
		local f = fixture()
		local state = State.new("sparta", 0)
		state.coins = 7123
		f.store:seed("miniature-development:1", { schemaVersion = 1, civilizations = { sparta = state } })
		f.store:queue({ afterError = "Acquisition acknowledgement lost" })
		assert(not f.sessions:load(1).ok, "Uncertain load activated")
		assert(f.sessions:release(1).ok, "Uncertain acquisition cleanup failed")
		local saved = f.store:read("miniature-development:1")
		assert(saved.lease == nil and saved.civilizations.sparta.coins == 7123, "Cleanup changed saved progress")
	end)
	check("uncertain cleanup is serialized and never clears a successor token", function()
		local f = fixture()
		f.store:queue({ afterError = "Load response lost" })
		assert(not f.sessions:load(1).ok, "Uncertain load activated")
		local foreign = f.store:read("miniature-development:1")
		foreign.lease = { token = "successor", expiresAt = 500 }
		f.store:queue({
			beforeCommit = function()
				assert(f.sessions:release(1).reason == "load_busy", "Concurrent cleanup admitted")
				f.store:seed("miniature-development:1", foreign)
			end,
		})
		local commits = #f.store.commits
		assert(f.sessions:release(1).ok, "Token-only cleanup did not complete")
		assert(
			#f.store.commits == commits and f.store:read("miniature-development:1").lease.token == "successor",
			"Cleanup replaced successor"
		)
	end)
	check("corrupt and unsupported saved records never become writable defaults on retry", function()
		local f = fixture()
		for _, malformed in
			{
				{ schemaVersion = 2, civilizations = {} },
				{ schemaVersion = 1, civilizations = { sparta = false } },
				{ schemaVersion = 1, civilizations = {}, unexpected = true },
			}
		do
			f.store:seed("miniature-development:1", malformed)
			local commits = #f.store.commits
			assert(f.sessions:load(1).reason == "invalid_saved_data", "Malformed load accepted")
			assert(
				f.sessions:load(1).reason == "invalid_saved_data" and #f.store.commits == commits,
				"Retry replaced corrupt record"
			)
			assert(
				not f.sessions:snapshot(1).writable and f.sessions:snapshot(1).profileReason == "invalid_saved_data",
				"Corruption status missing"
			)
			assert(f.sessions:release(1).ok and #f.store.commits == commits, "Corrupt cleanup wrote defaults")
		end
	end)
	check("abandoned in-flight acquisition cannot replace a newer local generation", function()
		local f = fixture()
		f.store:queue({
			beforeCommit = function()
				f.sessions:abandon(1)
				assert(f.sessions:load(1).ok and f.sessions:select(1, "rome").ok, "Replacement load failed")
			end,
		})
		assert(not f.sessions:load(1).ok, "Abandoned acquisition activated")
		local view = f.sessions:snapshot(1)
		assert(
			view.writable and view.claim.civilizationId == "rome" and view.sessionId == "durable-2",
			"Old load cleared replacement"
		)
	end)
	check("late release cannot clear replacement entry or civilization claim", function()
		local f = fixture()
		assert(f.sessions:load(1).ok and f.sessions:select(1, "sparta").ok, "Setup failed")
		f.store:queue({
			beforeCommit = function()
				f.sessions:abandon(1)
				f.now = 61
				assert(f.sessions:load(1).ok and f.sessions:select(1, "rome").ok, "Replacement failed")
			end,
		})
		assert(not f.sessions:release(1).ok, "Stale release claimed success")
		local view = f.sessions:snapshot(1)
		assert(view.writable and view.claim.civilizationId == "rome", "Late release cleared replacement")
	end)
	check("yielding autosave preserves newer memory and final release flushes it", function()
		local f = fixture()
		assert(f.sessions:load(1).ok and f.sessions:select(1, "sparta").ok, "Setup failed")
		f.sessions:current(1).coins = 10
		f.store:queue({
			beforeCommit = function()
				f.sessions:current(1).coins = 20
				assert(f.sessions:save(1).reason == "save_busy", "Concurrent save was admitted")
			end,
		})
		assert(f.sessions:save(1).ok and f.sessions:current(1).coins == 20, "Save replaced newer memory")
		assert(f.store:read("miniature-development:1").civilizations.sparta.coins == 10, "Snapshot was not isolated")
		assert(f.sessions:release(1).ok, "Final save failed")
		assert(
			f.store:read("miniature-development:1").civilizations.sparta.coins == 20,
			"Final save lost newest change"
		)
	end)
	check("persistent identity and key contract cannot write Studio test players", function()
		local f = fixture(true)
		for _, id in { -1, 0, 1.5, math.huge } do
			assert(f.sessions:load(id).reason == "invalid_player", "Persistent adapter accepted invalid identity")
		end
		assert(#f.store.attempts == 0, "Invalid identity reached storage")
		assert(f.sessions:load(123).ok, "Persistent contract rejected")
		assert(f.store:read("player:123") and not f.store:read("miniature-development:123"), "Wrong key namespace")
	end)
	check("status reports failed saves without a false durability timestamp", function()
		local f = fixture()
		assert(f.sessions:load(1).ok, "Setup failed")
		assert(f.sessions:snapshot(1).lastSavedAt == nil, "Acquisition claimed gameplay was saved")
		f.now = 5
		f.store:queue({ beforeError = "Save unavailable" })
		assert(not f.sessions:save(1).ok, "Save fault failed")
		local failed = f.sessions:snapshot(1)
		assert(
			failed.writable and failed.profileReason == "save_failed" and failed.lastSavedAt == nil,
			"Failure hidden"
		)
		f.now = 10
		assert(f.sessions:save(1).ok, "Retry failed")
		local saved = f.sessions:snapshot(1)
		assert(
			saved.profileStatus == "ready" and saved.profileReason == nil and saved.lastSavedAt == 10,
			"Durability status stale"
		)
	end)
	check("all thirteen civilizations roundtrip independent economy research and army presets", function()
		local f = fixture()
		assert(f.sessions:load(1).ok, "Setup failed")
		local expected = {}
		local index = 0
		for id in State.supported do
			index += 1
			assert(f.sessions:select(1, id).ok, "Civilization selection failed")
			local state = f.sessions:current(1)
			state.coins, state.goods.food, state.goods.timber = 3000 + index, index, index * 2
			state.plans.mount, state.plans.training = 3, 1
			assert(
				Actions.apply(state, "place", { kind = "training", x = 20, z = 8, rotation = 0 }, 0).ok,
				"Fixture placement failed"
			)
			state.militaryResearch = {
				completed = { army_training = true, officer_training = true, army_control = true },
				project = { id = "elite_training", remaining = 17.25 + index },
			}
			state.armyGroups.army2 = { "b4" }
			state.merchant.stock.farm = 0
			state.buildings[3].output = 7
			assert(State.validate(state, id), "Roundtrip fixture invalid")
			expected[id] = State.copy(state)
		end
		assert(index == 13 and f.sessions:release(1).ok, "Final release failed")
		f.now = 100000
		local restored = Sessions.new(f.options)
		assert(restored:load(1).ok, "Reacquisition failed")
		for id, before in expected do
			assert(restored:select(1, id).ok, "Restore selection failed")
			local state = restored:current(1)
			assert(
				state.coins == before.coins and state.goods.timber == before.goods.timber and state.plans.mount == 3,
				"Economy reset"
			)
			assert(
				state.merchant.stock.farm == 0 and #state.buildings == 4 and state.buildings[3].output == 7,
				"Buildings or stock reset"
			)
			assert(
				state.militaryResearch.project.remaining == before.militaryResearch.project.remaining
					and state.armyGroups.army2[1] == "b4",
				"Offline time or presets changed"
			)
		end
	end)
	return count
end

return run

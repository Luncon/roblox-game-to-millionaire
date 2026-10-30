--!strict
local Sessions = require(game:GetService("ServerScriptService").Sandbox.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	local function fixture()
		local now, serial = 0, 0
		local store = FakeStore.new()
		local options = {
			store = store,
			clock = function()
				return now
			end,
			token = function()
				serial += 1
				return "session-" .. serial
			end,
		}
		return Sessions.new(options), store, function(value)
			now = value
		end, options
	end
	check("exclusive civilization claims preserve eight owned plots and all thirteen choices", function()
		local sessions = fixture()
		local factions = { "sparta", "rome", "persia", "egypt", "seneca", "mongols", "vikings", "japan", "ming" }
		for userId, faction in factions do
			assert(sessions:load(userId).ok, "Fake load failed")
			local result = sessions:select(userId, faction)
			assert(result.ok == (userId <= 8), "Wrong plot capacity")
		end
		assert(not sessions:select(2, "sparta").ok, "Occupied civilization was claimed")
		assert(not sessions:select(2, "unknown").ok, "Unknown civilization was claimed")
	end)
	check("switches preserve the plot and isolate balances across players and factions", function()
		local sessions = fixture()
		assert(sessions:load(1).ok and sessions:load(2).ok, "Load failed")
		assert(sessions:select(1, "sparta").ok and sessions:select(2, "rome").ok, "Claim failed")
		local plot = sessions:snapshot(1).claim.plotId
		sessions:current(1).coins = 17
		assert(sessions:select(1, "persia").ok, "Switch failed")
		assert(sessions:current(1).coins == 200 and sessions:current(2).coins == 200, "Other state changed")
		assert(sessions:select(1, "sparta").ok, "Return failed")
		assert(sessions:current(1).coins == 17 and sessions:snapshot(1).claim.plotId == plot, "Progress or plot lost")
		local snapshot = sessions:snapshot(1)
		snapshot.state.coins = 900
		assert(sessions:current(1).coins == 17, "Snapshot changed owned progress")
	end)
	check("release and reacquisition restore paid progress without resetting merchant stock", function()
		local sessions, store, _, options = fixture()
		assert(sessions:load(7).ok and sessions:select(7, "sparta").ok, "Setup failed")
		sessions:current(7).coins = 80
		sessions:current(7).merchant.stock.farm = 0
		assert(sessions:release(7).ok, "Release failed")
		local restored = Sessions.new(options)
		assert(restored:load(7).ok and restored:select(7, "sparta").ok, "Reacquisition failed")
		assert(restored:current(7).coins == 80 and restored:current(7).merchant.stock.farm == 0, "Progress reset")
		assert(#store.attempts >= 3, "Store fixture was not exercised")
	end)
	check("load errors and malformed saved state never write fresh defaults", function()
		local sessions, store = fixture()
		store:seed("miniature-development:5", { schemaVersion = 99, coins = 12345 })
		local commits = #store.commits
		assert(not sessions:load(5).ok and not sessions:select(5, "sparta").ok, "Malformed data activated")
		assert(
			#store.commits == commits and store:read("miniature-development:5").coins == 12345,
			"Old data overwritten"
		)
		store:queue({ beforeError = "load outage" })
		assert(not sessions:load(6).ok and store:read("miniature-development:6") == nil, "Failed load created data")
	end)
	check("lease conflicts expiration and takeover block old writers", function()
		local first, _, advance, options = fixture()
		local second = Sessions.new(options)
		assert(first:load(1).ok and first:select(1, "sparta").ok, "Setup failed")
		assert(not second:load(1).ok, "Concurrent profile lease activated")
		advance(61)
		assert(not first:writable(1) and first:current(1) == nil, "Expired lease stayed writable")
		assert(second:load(1).ok, "Expired lease could not be acquired")
		assert(not first:save(1).ok, "Old writer saved over replacement lease")
	end)
	check("transient saves retain authority only inside the known lease", function()
		local sessions, store, advance = fixture()
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Setup failed")
		store:queue({ beforeError = "temporary failure" })
		assert(not sessions:save(1).ok and sessions:writable(1), "Temporary failure discarded a valid lease")
		advance(61)
		assert(not sessions:writable(1), "Failed renewals banked authority")
	end)
	check("Studio multiplayer identities and pending saves cannot bypass closing", function()
		local sessions, store = fixture()
		assert(sessions:load(-1).ok and sessions:select(-1, "sparta").ok, "Studio identity rejected")
		store:queue({
			beforeCommit = function()
				local closing = sessions:release(-1)
				assert(not closing.ok and closing.reason == "save_busy", "Concurrent release was not serialized")
				assert(not sessions:writable(-1), "Closing profile accepted mutations")
			end,
		})
		assert(sessions:save(-1).ok, "Pending save failed")
		assert(sessions:release(-1).ok, "Final release could not retry")
		assert(store:read("miniature-development:-1").lease == nil, "Lease was not released")
	end)
	check("a release during loading cancels authority and removes the acquired lease", function()
		local sessions, store = fixture()
		store:queue({
			beforeCommit = function()
				assert(sessions:load(4).reason == "load_busy", "A second loader was admitted")
				assert(sessions:release(4).reason == "load_busy", "In-flight load was not cancelled")
			end,
		})
		assert(sessions:load(4).reason == "load_cancelled", "Cancelled load activated")
		assert(not sessions:writable(4) and not sessions:snapshot(4).loaded, "Orphan entry remained")
		assert(store:read("miniature-development:4").lease == nil, "Acquired lease was orphaned")
	end)
	check("selection commits the prior settled candidate only after a successful claim", function()
		local sessions = fixture()
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "First setup failed")
		assert(sessions:load(2).ok and sessions:select(2, "rome").ok, "Second setup failed")
		local candidate = sessions:snapshot(1).state
		candidate.goods.food = 4
		assert(not sessions:select(1, "rome", candidate).ok, "Occupied claim accepted")
		assert(sessions:current(1).goods.food == 0, "Failed switch changed old state")
		assert(sessions:select(1, "persia", candidate).ok, "Free claim failed")
		assert(sessions:select(1, "sparta").ok and sessions:current(1).goods.food == 4, "Settled progress was lost")
		candidate = sessions:snapshot(1).state
		candidate.goods.food = 8
		assert(
			sessions:select(1, "sparta", candidate).ok and sessions:current(1).goods.food == 8,
			"Same-civilization migration discarded settled progress"
		)
		local epoch = sessions:snapshot(1).claimEpoch
		sessions:invalidate(1)
		assert(sessions:snapshot(1).claimEpoch == epoch + 1, "Life change retained stale authority")
	end)
	return count
end

return run

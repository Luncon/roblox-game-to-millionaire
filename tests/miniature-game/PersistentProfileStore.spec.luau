--!strict
local Store = require(game:GetService("ServerScriptService").Sandbox.PersistentProfileStore)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS persistent store: " .. name)
	end
	local function fixture(studio, scope)
		local selected, calls = {}, {}
		local backend = {}
		function backend:UpdateAsync(key, transform)
			table.insert(calls, key)
			return transform({ coins = 7 }, {
				GetMetadata = function()
					return { retained = "metadata" }
				end,
			})
		end
		local service = {}
		function service:GetDataStore(name, selectedScope)
			table.insert(selected, { name = name, scope = selectedScope })
			return backend
		end
		return {
			runService = {
				IsStudio = function()
					return studio
				end,
			},
			dataStoreService = service,
			verificationScope = scope,
		},
			selected,
			calls,
			backend
	end
	check("live storage selects only the new miniature namespace", function()
		local options, selected = fixture(false)
		local store = Store.new(options)
		assert(#selected == 1 and selected[1].name == "MiniatureCivilizationProfilesV1", "Wrong profile namespace")
		assert(selected[1].scope == "Live", "Live server used a non-live scope")
		assert(store.isPersistentProfileStore == true and not store.isFakeProfileStore, "Incorrect storage contract")
		assert(
			store.keyPrefix == "player:" and string.find(store.storageLabel, "Live", 1, true),
			"Missing storage identity"
		)
	end)
	check("Studio cannot open Live and requires a unique verification scope", function()
		for _, scope in { false, "Live", "StudioDevelopment", "Verification_", "Verification_bad/scope" } do
			local options, selected = fixture(true, if scope == false then nil else scope)
			assert(not pcall(Store.new, options), "Studio admitted an unsafe persistence scope")
			assert(#selected == 0, "Invalid Studio scope opened a store")
		end
		local options, selected = fixture(true, "Verification_test_20261030")
		local store = Store.new(options)
		assert(selected[1].scope == "Verification_test_20261030", "Verification scope drift")
		assert(string.find(store.storageLabel, "Verification_test_20261030", 1, true), "Incorrect verification label")
		local live, liveSelected = fixture(false, "Verification_test")
		assert(not pcall(Store.new, live) and #liveSelected == 0, "Public server accepted test storage")
	end)
	check("only canonical positive player keys reach the persistent backend", function()
		local options, _, calls = fixture(false)
		local store = Store.new(options)
		for _, key in
			{
				"player:0",
				"player:-1",
				"miniature-development:1",
				"User_1",
				"player:1.5",
				"player:01",
				"player:9007199254740992",
			}
		do
			assert(not pcall(function()
				store:UpdateAsync(key, function(value)
					return value
				end)
			end), "Invalid persistent identity reached the backend")
		end
		assert(#calls == 0, "Rejected identities called persistent storage")
		local value, users, metadata = store:UpdateAsync("player:68716649", function(current)
			return { coins = current.coins + 1 }
		end)
		assert(#calls == 1 and value.coins == 8, "Transform did not reach the correct player key")
		assert(users[1] == 68716649 and #users == 1, "Saved data is not associated with its owner")
		assert(metadata.retained == "metadata", "Update discarded existing key metadata")
	end)
	check("cancellation and uncertain acknowledgements are preserved for the session layer", function()
		local options, _, _, backend = fixture(false)
		local store = Store.new(options)
		assert(store:UpdateAsync("player:1", function()
			return nil
		end) == nil, "Cancelled transform produced a default value")
		function backend:UpdateAsync()
			error("commit acknowledgement unavailable")
		end
		assert(not pcall(function()
			store:UpdateAsync("player:1", function(value)
				return value
			end)
		end), "Adapter swallowed a storage failure")
	end)
	return count
end

return run

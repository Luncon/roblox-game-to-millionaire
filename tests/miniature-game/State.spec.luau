--!strict
local State = require(game:GetService("ServerScriptService").Sandbox.State)
local Sessions = require(game:GetService("ServerScriptService").Sandbox.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("starter state is bounded and housing covers two assigned workers", function()
		local state = State.new("sparta", 0)
		assert(State.validate(state, "sparta"), "Starter validation failed")
		assert(state.coins == 200 and #state.workers == 2 and #state.buildings == 3, "Wrong starter")
		assert(State.housing(state) == 4 and State.inventorySize(state) == 0, "Wrong capacity")
	end)
	check("malformed and unexpected scalar values cannot load as fresh progress", function()
		for _, value in { -1, 0 / 0, math.huge, "200", 1000000001 } do
			local state = State.new("sparta", 0)
			state.coins = value
			assert(not State.validate(state, "sparta"), "Malformed Coins were accepted")
		end
		local state = State.new("sparta", 0)
		state.unreviewed = true
		assert(not State.validate(state, "sparta"), "Unknown field was accepted")
		state = State.new("sparta", 0)
		state.goods.food = -1
		assert(not State.validate(state, "sparta"), "Negative goods were accepted")
	end)
	check("placements assignments and capacity are validated together", function()
		local state = State.new("sparta", 0)
		state.buildings[2].x = state.buildings[1].x
		state.buildings[2].z = state.buildings[1].z
		assert(not State.validate(state, "sparta"), "Overlapping restore was accepted")
		state = State.new("sparta", 0)
		state.workers[1].buildingId = "missing"
		assert(not State.validate(state, "sparta"), "Orphaned worker was accepted")
		state = State.new("sparta", 0)
		state.goods.timber = 201
		assert(not State.validate(state, "sparta"), "Overfull inventory was accepted")
	end)
	check("civilizations and snapshots do not share mutable state", function()
		local first = State.new("sparta", 0)
		local other = State.new("rome", 0)
		local snapshot = State.copy(first)
		snapshot.buildings[1].x = 18
		first.coins = 0
		assert(other.coins == 200 and first.buildings[1].x == -12, "State leaked")
		assert(not State.validate(other, "sparta"), "Faction mismatch was accepted")
	end)
	check("a malformed later building fails validation before geometry is evaluated", function()
		local state = State.new("sparta", 0)
		state.buildings[3].kind = "unknown"
		local ok, valid = pcall(State.validate, state, "sparta")
		assert(ok and not valid, "Malformed peer caused a validator exception")
	end)
	check("sparse workforce and building arrays are rejected rather than counted as phantom entries", function()
		local workers = State.new("sparta", 0)
		table.insert(workers.workers, { id = "w3" })
		workers.nextWorkerId = 4
		workers.workers[2] = nil
		assert(not State.validate(workers, "sparta"), "Sparse workforce accepted")
		local buildings = State.new("sparta", 0)
		table.insert(buildings.buildings, { id = "b4", kind = "timber", x = 8, z = 8, rotation = 0, output = 0 })
		table.insert(buildings.buildings, { id = "b5", kind = "house", x = 16, z = 8, rotation = 0, output = 0 })
		buildings.nextBuildingId = 6
		assert(State.validate(buildings, "sparta"), "Dense building fixture invalid")
		buildings.buildings[4] = nil
		assert(not State.validate(buildings, "sparta"), "Sparse building array accepted")
		for _, field in { "workers", "buildings" } do
			for _, key in { 0, -1, 0.5, math.huge, "1" } do
				local state = State.new("sparta", 0)
				state[field][key] = state[field][1]
				local ok, valid = pcall(State.validate, state, "sparta")
				assert(ok and not valid, "Invalid array key accepted or threw")
			end
		end
	end)
	check("a sparse saved profile fails loading without overwriting existing progress", function()
		local state = State.new("sparta", 0)
		state.coins = 12345
		table.insert(state.workers, { id = "w3" })
		state.nextWorkerId = 4
		state.workers[2] = nil
		local store = FakeStore.new()
		store:seed("miniature-development:55", { schemaVersion = 1, civilizations = { sparta = state } })
		local commits = #store.commits
		local sessions = Sessions.new({
			store = store,
			clock = function()
				return 0
			end,
			token = function()
				return "sparse-load"
			end,
		})
		assert(not sessions:load(55).ok and not sessions:writable(55), "Sparse profile activated")
		assert(
			#store.commits == commits and store:read("miniature-development:55").civilizations.sparta.coins == 12345,
			"Rejected sparse profile was overwritten"
		)
	end)
	return count
end

return run

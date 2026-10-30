--!strict
local State = require(game:GetService("ServerScriptService").Sandbox.State)
local Economy = require(game:GetService("ServerScriptService").Sandbox.Economy)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.Config)
local Actions = require(game:GetService("ServerScriptService").Sandbox.Actions)

-- Legacy-rate scenarios retain their base-time examples, translated to fast sandbox seconds.
local function step(state, clocks, baseSeconds, active)
	return Economy.step(state, clocks, baseSeconds / Config.productionSpeed, active)
end

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("two farmers produce twenty-four goods over six accelerated active seconds", function()
		local state, clocks = State.new("sparta", 0), {}
		step(state, clocks, 0, true)
		step(state, clocks, 9.99, true)
		assert(state.buildings[3].output == 0, "Partial interval paid")
		step(state, clocks, 60, true)
		assert(state.buildings[3].output == 24 and state.coins == 200, "Wrong yield or automatic Coins")
		assert(Economy.collect(state, { buildingId = "b3" }).ok, "Collection failed")
		assert(state.goods.food == 24 and state.coins == 200, "Collection minted currency")
		assert(Economy.sell(state, { good = "food", amount = 24 }).ok, "Sale failed")
		assert(state.goods.food == 0 and state.coins == 248, "Wrong sale value")
	end)
	check("full output and inactive intervals cannot become a later windfall", function()
		local state, clocks = State.new("sparta", 0), {}
		state.buildings[3].output = 60
		step(state, clocks, 1000, true)
		assert(Economy.collect(state, { buildingId = "b3" }).ok, "Collection failed")
		step(state, clocks, 1001, true)
		assert(state.buildings[3].output == 0, "Full time was banked")
		step(state, clocks, 2000, false)
		step(state, clocks, 2009, true)
		assert(state.buildings[3].output == 0, "Inactive time was banked")
		step(state, clocks, 2010, true)
		assert(state.buildings[3].output == 4, "Fresh production did not resume")
	end)
	check("collection is partial and preserves the remainder at full inventory", function()
		local state = State.new("sparta", 0)
		state.goods.timber = 197
		state.buildings[3].output = 10
		local result = Economy.collect(state, { buildingId = "b3" })
		assert(result.ok and result.amount == 3, "Free capacity not respected")
		assert(state.buildings[3].output == 7 and State.inventorySize(state) == 200, "Goods lost")
		assert(not Economy.collect(state, { buildingId = "b3" }).ok, "Overfull collection accepted")
	end)
	check("invalid sales and wallet overflow preserve goods and Coins", function()
		local state = State.new("sparta", 0)
		state.goods.food = 10
		for _, amount in { 0, -1, 11, 0.5, 0 / 0, math.huge, "10" } do
			assert(not Economy.sell(state, { good = "food", amount = amount }).ok, "Invalid sale accepted")
		end
		assert(not Economy.sell(state, { good = "unknown", amount = 1 }).ok, "Unknown good sold")
		state.coins = 999999999
		assert(not Economy.sell(state, { good = "food", amount = 1 }).ok, "Overflow accepted")
		assert(state.goods.food == 10 and state.coins == 999999999, "Rejected sale changed state")
	end)
	check("Sell All atomically prices every carried good and refuses empty inventory or overflow", function()
		local state = State.new("sparta", 0)
		state.goods = { food = 3, timber = 4, material = 5, crafted = 6 }
		state.coins = 999999999
		assert(
			not Economy.sellAll(state).ok and state.goods.crafted == 6 and state.coins == 999999999,
			"Overflow consumed goods"
		)
		state.coins = 200
		local result = Economy.sellAll(state)
		assert(
			result.ok and result.amount == 18 and result.coins == 142 and state.coins == 342,
			"Sell All ledger wrong"
		)
		assert(State.inventorySize(state) == 0, "Sell All left carried goods")
		assert(not Economy.sellAll(state).ok and state.coins == 342, "Empty repeat minted Coins")
	end)
	check("zero-Coin players can recover and a long stall remains bounded", function()
		local state, clocks = State.new("sparta", 0), {}
		state.coins = 0
		step(state, clocks, 0, true)
		step(state, clocks, 100000, true)
		assert(state.buildings[3].output == 24, "Stall processed an unbounded backlog")
		step(state, clocks, 100001, true)
		assert(state.buildings[3].output == 24, "Old backlog remained queued")
		Economy.collect(state, { buildingId = "b3" })
		assert(Economy.sell(state, { good = "food", amount = 10 }).ok and state.coins == 20, "Recovery failed")
	end)
	check("explicit collection transfers ten of twelve and rejects invalid exact amounts atomically", function()
		local state = State.new("sparta", 0)
		state.buildings[3].output = 12
		assert(Economy.collect(state, { buildingId = "b3", amount = 10 }).ok, "Exact collection failed")
		assert(state.goods.food == 10 and state.buildings[3].output == 2, "Exact amount ignored")
		for _, amount in { 0, -1, 3, 0.5, 0 / 0, math.huge, "2" } do
			assert(
				not Economy.collect(state, { buildingId = "b3", amount = amount }).ok,
				"Invalid exact collection accepted"
			)
			assert(state.goods.food == 10 and state.buildings[3].output == 2, "Rejected collection mutated")
		end
		state.goods.timber = 189
		assert(
			not Economy.collect(state, { buildingId = "b3", amount = 2 }).ok,
			"Exact collection overflowed inventory"
		)
	end)
	check("workshop input and output move as complete batches without banking blocked time", function()
		local state, clocks = State.new("sparta", 0), {}
		state.hallUpgraded = true
		state.research.completed.work, state.research.completed.craft = true, true
		table.insert(state.buildings, { id = "b4", kind = "workshop", x = 8, z = 8, rotation = 0, output = 0 })
		state.nextBuildingId = 5
		state.workers[1].buildingId, state.workers[2].buildingId = "b4", "b4"
		state.goods.material = 1
		step(state, clocks, 0, true)
		step(state, clocks, 1000, true)
		assert(state.goods.material == 1 and state.buildings[4].output == 0, "Partial batch consumed input")
		state.goods.material = 4
		step(state, clocks, 1014.99, true)
		assert(state.goods.material == 4, "Blocked backlog survived")
		step(state, clocks, 1015, true)
		assert(state.goods.material == 2 and state.buildings[4].output == 2, "Wrong workshop batch")
		state.buildings[4].output = 59
		step(state, clocks, 1030, true)
		assert(state.goods.material == 2 and state.buildings[4].output == 59, "Partial output batch consumed input")
	end)
	check("research-off automatic services preserve saved toggles without changing inventory or output", function()
		local state = State.new("sparta", 0)
		state.hallUpgraded = true
		for _, id in { "work", "craft", "records", "porters", "trade" } do
			state.research.completed[id] = true
		end
		state.settings.autoCollect, state.settings.autoSell = true, true
		state.settings.reserves.food = 5
		state.goods.material = 8
		state.buildings[3].output = 12
		table.insert(state.buildings, { id = "b4", kind = "workshop", x = 8, z = 8, rotation = 0, output = 0 })
		state.nextBuildingId = 5
		state.workers[1].buildingId, state.workers[2].buildingId = "b4", "b4"
		local result = Economy.automate(state)
		assert(not result.changed and state.buildings[3].output == 12, "Disabled Porters collected")
		assert(state.goods.food == 0 and state.goods.material == 8, "Disabled Trade consumed goods")
		assert(
			state.coins == 200 and state.settings.autoCollect and state.settings.autoSell,
			"Disabled services changed wallet or saved toggles"
		)
		assert(State.validate(state, "sparta"), "Automated state invalid")
	end)
	check("four staffed clay and pottery workers conserve eight inputs at accelerated recipe intervals", function()
		local state, clocks = State.new("sparta", 0), {}
		state.hallUpgraded = true
		state.research.completed.work, state.research.completed.craft = true, true
		table.insert(state.buildings, { id = "b4", kind = "material", x = 8, z = 8, rotation = 0, output = 0 })
		table.insert(state.buildings, { id = "b5", kind = "workshop", x = 16, z = 8, rotation = 0, output = 0 })
		state.nextBuildingId = 6
		state.workers = {
			{ id = "w1", buildingId = "b4" },
			{ id = "w2", buildingId = "b4" },
			{ id = "w3", buildingId = "b5" },
			{ id = "w4", buildingId = "b5" },
		}
		state.nextWorkerId = 5
		step(state, clocks, 0, true)
		for elapsed = 15, 60, 15 do
			step(state, clocks, elapsed, true)
			assert(Economy.collect(state, { buildingId = "b4" }).ok, "Clay could not be collected")
		end
		-- First pottery batch starts only after clay reaches collected inventory.
		step(state, clocks, 75, true)
		assert(state.buildings[5].output == 8 and state.goods.material == 0, "Clay/recipe conservation failed")
		assert(Economy.collect(state, { buildingId = "b5" }).ok, "Pottery collection failed")
		assert(
			Economy.sell(state, { good = "crafted", amount = 8 }).ok and state.coins == 320,
			"Wrong steady-state sale value"
		)
		assert(State.validate(state, "sparta"), "Crafting chain invalid")
	end)
	check("a hundred paid-plan place/unpack cycles keep clocks bounded to current producers", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0, b1 = 0 }
		assert(Actions.apply(state, "buy", { kind = "farm" }, 0).ok, "Farm plan setup failed")
		local function applyResets(result, now)
			if result.resetProduction then
				for id in clocks do
					clocks[id] = now
				end
			elseif result.resetBuildings then
				for _, id in result.resetBuildings do
					clocks[id] = now
				end
			end
			Economy.pruneClocks(state, clocks)
		end
		for iteration = 1, 100 do
			local placed = Actions.apply(state, "place", { kind = "farm", x = 16, z = -8, rotation = 0 }, iteration)
			assert(placed.ok, "Reusable farm plan placement failed")
			applyResets(placed, iteration)
			assert(
				clocks[placed.buildingId] == iteration and clocks.b1 == nil,
				"Pruning kept non-producer or dropped live producer"
			)
			local unpacked = Actions.apply(state, "unpack", { buildingId = placed.buildingId }, iteration)
			assert(unpacked.ok, "Empty unassigned farm unpack failed")
			applyResets(unpacked, iteration)
			local size = 0
			for id in clocks do
				size += 1
				assert(id == "b3", "Removed producer clock retained")
			end
			assert(
				size == 1 and state.plans.farm == 1 and #state.buildings == 3,
				"Transient clocks or plan inventory grew"
			)
		end
		assert(State.validate(state, "sparta"), "Repeated placement state invalid")
	end)
	check("clock pruning preserves relocation progress and removes deleted or non-producer IDs", function()
		local state, clocks = State.new("sparta", 0), { b3 = 4.25, b1 = 3, b2 = 2, foreign = 7 }
		assert(
			Actions.apply(state, "move", { buildingId = "b3", x = 16, z = -8, rotation = 90 }, 5).ok,
			"Relocation failed"
		)
		Economy.pruneClocks(state, clocks)
		assert(
			clocks.b3 == 4.25 and clocks.b1 == nil and clocks.b2 == nil and clocks.foreign == nil,
			"Pruning reset relocation or retained non-producer"
		)
		table.remove(state.buildings, 3)
		Economy.pruneClocks(state, clocks)
		assert(next(clocks) == nil, "Deleted current producer clock retained")
	end)
	return count
end

return run

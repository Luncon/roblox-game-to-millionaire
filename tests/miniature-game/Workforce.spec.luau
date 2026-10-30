--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local State = require(Server.State)
local Workforce = require(Server.Workforce)
local Actions = require(Server.Actions)
local Economy = require(Server.Economy)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("houses supply four free civilians with stable assignments and an eight-person cap", function()
		local state = State.new("sparta", 0)
		assert(Workforce.reconcile(state), "Starter civilians did not arrive")
		assert(#state.workers == 4 and state.coins == 200, "Automatic population charged or used wrong housing")
		assert(state.workers[1].buildingId == "b3" and state.workers[2].buildingId == "b3", "Farm assignments changed")
		assert(state.workers[3].buildingId == nil and not Workforce.reconcile(state), "Idle civilians churned")
		state.plans.timber, state.plans.house = 1, 2
		local timber = Actions.apply(state, "place", { kind = "timber", x = 8, z = 8, rotation = 0 }, 0)
		assert(timber.ok and Workforce.reconcile(state), "New jobs were not filled")
		assert(
			state.workers[3].buildingId == timber.buildingId and state.workers[4].buildingId == timber.buildingId,
			"Wrong free-job order"
		)
		assert(
			Actions.apply(state, "place", { kind = "house", x = -6, z = 8, rotation = 0 }, 0).ok,
			"Second house failed"
		)
		Workforce.reconcile(state)
		assert(#state.workers == 8 and state.coins == 200, "Second house did not supply four civilians")
		assert(
			Actions.apply(state, "place", { kind = "house", x = 16, z = -8, rotation = 0 }, 0).ok,
			"Third house failed"
		)
		Workforce.reconcile(state)
		assert(#state.workers == 8 and State.validate(state, "sparta"), "Population cap failed")
	end)
	check("reclaim collects all output returns one plan and automatically restores jobs after rebuilding", function()
		local state = State.new("sparta", 0)
		Workforce.reconcile(state)
		state.buildings[3].output = 12
		local result = Actions.apply(state, "reclaim", { buildingId = "b3" }, 0)
		assert(result.ok and result.amount == 12 and result.resetProduction, "Starter farm could not be reclaimed")
		assert(
			state.goods.food == 12 and state.plans.farm == 1 and #state.buildings == 2,
			"Reclaim lost output or minted plans"
		)
		assert(
			state.coins == 200 and #state.workers == 4 and State.validate(state, "sparta"),
			"Reclaim changed wallet or invalidated state"
		)
		for _, worker in state.workers do
			assert(worker.buildingId == nil, "Removed job retained")
		end
		assert(
			not Actions.apply(state, "reclaim", { buildingId = "b3" }, 0).ok and state.plans.farm == 1,
			"Reclaim duplicated plan"
		)
		local placed = Actions.apply(state, "place", { kind = "farm", x = 8, z = -8, rotation = 0 }, 0)
		assert(placed.ok and placed.buildingId ~= "b3", "Rebuild reused removed identity")
		Workforce.reconcile(state)
		assert(
			state.workers[1].buildingId == placed.buildingId and state.workers[2].buildingId == placed.buildingId,
			"Rebuild did not restore jobs"
		)
		assert(
			state.plans.farm == 0 and state.goods.food == 12 and State.validate(state, "sparta"),
			"Rebuild changed collected goods"
		)
	end)
	check(
		"reclaim rejects full inventory unsafe plan increments civic and last house without partial transfer",
		function()
			local state = State.new("sparta", 0)
			Workforce.reconcile(state)
			state.goods.timber, state.buildings[3].output = 199, 2
			assert(not Actions.apply(state, "reclaim", { buildingId = "b3" }, 0).ok, "Reclaim overflow accepted")
			assert(
				state.goods.timber == 199
					and state.goods.food == 0
					and state.buildings[3].output == 2
					and state.plans.farm == 0,
				"Rejected reclaim partially transferred"
			)
			state.goods.timber, state.plans.farm = 0, 9007199254740991
			assert(not Actions.apply(state, "reclaim", { buildingId = "b3" }, 0).ok, "Plan overflow accepted")
			state.plans.farm = 0
			for _, id in { "b1", "b2", "foreign" } do
				assert(
					not Actions.apply(state, "reclaim", { buildingId = id }, 0).ok,
					"Protected/foreign reclaim accepted"
				)
			end
			assert(
				#state.buildings == 3 and #state.workers == 4 and state.buildings[3].output == 2,
				"Refusal changed population or buildings"
			)
		end
	)
	check("house reclaim shrinks population prunes removed presets and fills remaining legal jobs", function()
		local state = State.new("sparta", 0)
		state.hallUpgraded, state.research.completed.records = true, true
		state.plans.house, state.plans.timber = 1, 1
		local house = Actions.apply(state, "place", { kind = "house", x = -6, z = 8, rotation = 0 }, 0)
		local timber = Actions.apply(state, "place", { kind = "timber", x = 8, z = 8, rotation = 0 }, 0)
		Workforce.reconcile(state)
		assert(#state.workers == 8, "House setup population wrong")
		Actions.apply(state, "settings", { setting = "savePreset" }, 0)
		local result = Actions.apply(state, "reclaim", { buildingId = house.buildingId }, 0)
		assert(
			result.ok and #state.workers == 4 and state.plans.house == 1,
			"House reclaim failed to shrink population"
		)
		assert(
			state.workers[3].buildingId == timber.buildingId and state.settings.preset.w5 == nil,
			"Legal assignment lost or removed preset retained"
		)
		assert(State.validate(state, "sparta"), "Reclaimed house state invalid")
	end)
	check("fast production uses one-second active raw intervals and never banks inactive time", function()
		local state, clocks = State.new("sparta", 0), {}
		Workforce.reconcile(state)
		Economy.step(state, clocks, 0, true)
		Economy.step(state, clocks, 0.99, true)
		assert(state.buildings[3].output == 0, "Fast partial interval produced")
		Economy.step(state, clocks, 1, true)
		assert(state.buildings[3].output == 4, "Ten-times production speed missing")
		Economy.step(state, clocks, 100, false)
		Economy.step(state, clocks, 100.99, true)
		assert(state.buildings[3].output == 4, "Inactive fast time banked")
		Economy.step(state, clocks, 101, true)
		assert(state.buildings[3].output == 8, "Fresh fast interval missing")
	end)
	check("house removal settles all old workers before shrinking and never banks released jobs", function()
		local state, clocks = State.new("sparta", 0), {}
		state.plans.house, state.plans.farm, state.plans.timber, state.plans.material = 1, 1, 1, 1
		local house = Actions.apply(state, "place", { kind = "house", x = -6, z = 8, rotation = 0 }, 0)
		for _, site in { { "farm", 16, -8 }, { "timber", 8, 8 }, { "material", 16, 8 } } do
			assert(
				Actions.apply(state, "place", { kind = site[1], x = site[2], z = site[3], rotation = 0 }, 0).ok,
				"Producer setup failed"
			)
		end
		Workforce.reconcile(state)
		assert(#state.workers == 8, "Eight-worker setup failed")
		Economy.step(state, clocks, 0, true)
		Economy.step(state, clocks, 1.5, true)
		assert(state.buildings[6].output == 2 and state.buildings[7].output == 2, "Old workforce production was lost")
		assert(Actions.apply(state, "reclaim", { buildingId = house.buildingId }, 0).ok, "House removal failed")
		for id in clocks do
			clocks[id] = 1.5
		end
		Economy.pruneClocks(state, clocks)
		Economy.step(state, clocks, 100, true)
		assert(
			Economy.building(state, "b6").output == 2 and Economy.building(state, "b7").output == 2,
			"Released jobs produced after shrinking"
		)
		assert(#state.workers == 4 and State.validate(state, "sparta"), "Shrunk settlement invalid")
	end)
	check("reclaim preserves storage capacity but releases automatic military buildings", function()
		local state = State.new("sparta", 0)
		state.hallUpgraded = true
		for _, id in { "work", "craft", "store", "muster", "drill", "supply" } do
			state.research.completed[id] = true
		end
		state.plans.storehouse, state.plans.training = 1, 1
		local store = Actions.apply(state, "place", { kind = "storehouse", x = 8, z = 8, rotation = 0 }, 0)
		local training = Actions.apply(state, "place", { kind = "training", x = 16, z = -8, rotation = 90 }, 0)
		assert(store.ok and training.ok, "Dependency structures failed")
		state.goods.food = 201
		assert(
			not Actions.apply(state, "reclaim", { buildingId = store.buildingId }, 0).ok and state.goods.food == 201,
			"Storehouse loss overflowed inventory"
		)
		state.roster.melee = 1
		assert(
			Actions.apply(state, "reclaim", { buildingId = training.buildingId }, 0).ok,
			"Legacy roster blocked automatic military reclaim"
		)
		assert(
			State.troops(state).melee == 0 and state.roster.melee == 1,
			"Derived count retained a removed military building"
		)
	end)
	check("automatic job changes start new producer clocks at commit and travel preserves partial work", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		Workforce.reconcile(state)
		state.plans.timber = 1
		local result = Actions.apply(state, "place", { kind = "timber", x = 8, z = 8, rotation = 0 }, 0)
		assert(result.ok and Workforce.reconcile(state), "Automatic timber jobs did not fill")
		Economy.resetClocks(state, clocks, 0.25)
		assert(clocks[result.buildingId] == 0.25 and clocks.b3 == 0.25, "New producer clock started late")
		Economy.step(state, clocks, 0.75, true)
		assert(Actions.apply(state, "travel", { destination = "sell" }, 0).ok, "Travel destination failed")
		assert(not Workforce.reconcile(state), "Travel changed stable workforce")
		Economy.step(state, clocks, 1.25, true)
		assert(
			Economy.building(state, result.buildingId).output == 2 and state.buildings[3].output == 4,
			"Travel lost a partial interval"
		)
	end)
	return count
end

return run

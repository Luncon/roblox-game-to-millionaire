--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local State = require(Server.State)
local ActiveTime = require(Server.ActiveTime)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("disabled research never resets partial production or completes old projects", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		state.hallUpgraded = true
		state.research.project = { id = "work", remaining = 1.8 }
		local result = ActiveTime.step(state, clocks, 1.8, 1.8, true)
		assert(result.clocks == clocks and not result.research.changed, "Disabled research advanced")
		assert(result.changed and result.revisionChanged, "Whole production did not change revision")
		assert(state.buildings[3].output == 4 and clocks.b3 == 1, "Disabled project reset partial work")
		ActiveTime.step(state, clocks, 1.999, 0.199, true)
		assert(state.buildings[3].output == 4, "Partial interval produced")
		ActiveTime.step(state, clocks, 2, 0.001, true)
		assert(
			state.buildings[3].output == 8 and state.research.project.remaining == 1.8,
			"Production or paused research changed"
		)
	end)
	check("merchant refresh unlocks all types while old research remains paused", function()
		local state, clocks = State.new("sparta", 0), { b3 = 179.9 }
		state.hallUpgraded, state.research.completed.work = true, true
		state.research.project = { id = "craft", remaining = 0.1 }
		state.merchant.stock.workshop = 0
		local result = ActiveTime.step(state, clocks, 180.1, 0.2, true)
		assert(not result.research.changed and state.merchant.cycle == 1, "Boundary advanced disabled research")
		assert(
			state.merchant.stock.workshop == 1 and state.merchant.stock.ranged == 2,
			"Eligible types did not restock"
		)
		ActiveTime.step(state, clocks, 359.9, 179.8, true)
		assert(state.merchant.stock.workshop == 1, "Stock accumulated before the boundary")
		ActiveTime.step(state, clocks, 360, 0.1, true)
		assert(
			state.merchant.stock.workshop == 1 and state.plans.workshop == 0 and state.research.project.remaining == 0.1,
			"Restock granted plans or advanced research"
		)
	end)
	check("fractional active time leaves disabled research and action revisions unchanged", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		state.hallUpgraded = true
		state.research.project = { id = "muster", remaining = 30 }
		local result = ActiveTime.step(state, clocks, 0.25, 0.25, true)
		assert(
			not result.changed and not result.research.changed and not result.revisionChanged,
			"Paused project changed a revision"
		)
		assert(state.research.project.remaining == 30, "Paused project lost remaining time")
	end)
	check("switch and death snapshots retain completed intervals but never bank partial time", function()
		for _, boundary in { "switch", "death" } do
			for _, at in { 0.999, 1.001 } do
				local state, clocks = State.new("sparta", 0), { b3 = 0 }
				ActiveTime.step(state, clocks, at, at, true)
				local saved = State.copy(state)
				local expected = if at >= 1 then 4 else 0
				assert(saved.buildings[3].output == expected, boundary .. " lost a completed interval")
				local restoredClocks = {}
				ActiveTime.step(saved, restoredClocks, 1000, 0, true)
				ActiveTime.step(saved, restoredClocks, 1000.999, 0.999, true)
				assert(saved.buildings[3].output == expected, boundary .. " restored partial or offline time")
				ActiveTime.step(saved, restoredClocks, 1001, 0.001, true)
				assert(saved.buildings[3].output == expected + 4, boundary .. " failed to start a fresh interval")
			end
		end
	end)
	check("inactive settlement pauses production research and automation while restocking privately", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		state.hallUpgraded = true
		state.research.completed.records, state.research.completed.porters, state.research.completed.trade =
			true, true, true
		state.research.project = { id = "muster", remaining = 30 }
		state.settings.autoCollect, state.settings.autoSell = true, true
		state.goods.food, state.buildings[3].output = 10, 60
		state.merchant.stock.farm = 0
		local result = ActiveTime.step(state, clocks, 1000, 1000, false, 180)
		assert(
			result.changed and result.revisionChanged and state.merchant.stock.farm == 2,
			"Inactive merchant did not restock"
		)
		assert(not result.research.changed and state.research.project.remaining == 30, "Inactive research advanced")
		assert(
			state.goods.food == 10 and state.buildings[3].output == 60 and state.coins == 200,
			"Inactive automation ran"
		)
		assert(clocks.b3 == 1000 and state.merchant.cycle == 1, "Wall and monotonic clocks were mixed")
	end)
	check("disabled services leave collection manual and never bank full-output time", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		state.hallUpgraded = true
		state.research.completed.records, state.research.completed.porters = true, true
		state.settings.autoCollect = true
		state.buildings[3].output = 60
		local result = ActiveTime.step(state, clocks, 1000, 1000, true, 0)
		assert(
			not result.changed and state.goods.food == 0 and state.buildings[3].output == 60,
			"Disabled Porter collected"
		)
		assert(clocks.b3 == 1000, "Full time was banked")
		assert(require(Server.Economy).collect(state, { buildingId = "b3" }).ok, "Manual collection failed")
		ActiveTime.step(state, clocks, 1000.999, 0.999, true)
		assert(state.goods.food == 60 and state.buildings[3].output == 0, "Full time became a free batch")
		ActiveTime.step(state, clocks, 1001, 0.001, true)
		assert(state.goods.food == 60 and state.buildings[3].output == 4, "Fresh production did not remain manual")
	end)
	return count
end

return run

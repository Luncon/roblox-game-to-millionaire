--!strict
local State = require(game:GetService("ServerScriptService").Sandbox.State)
local Research = require(game:GetService("ServerScriptService").Sandbox.Research)
local Economy = require(game:GetService("ServerScriptService").Sandbox.Economy)
local Catalog = require(game:GetService("ReplicatedStorage").MiniatureGame.Catalog)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("disabled research refuses every project without charging Coins or creating timers", function()
		local state = State.new("sparta", 0)
		state.coins, state.hallUpgraded = 10000, true
		for id in Catalog.research do
			assert(Research.start(state, id).reason == "research_disabled", "Disabled research started: " .. id)
		end
		assert(state.coins == 10000 and state.research.project == nil, "Disabled research mutated state")
	end)
	check("legacy projects stay paused while completed work no longer modifies production", function()
		local state = State.new("sparta", 0)
		state.hallUpgraded, state.research.completed.work = true, true
		state.research.project = { id = "craft", remaining = 12.5 }
		for _, active in { true, false } do
			for _, elapsed in { 0.25, 60, 10000, -1, 0, 0 / 0, math.huge } do
				assert(not Research.step(state, elapsed, active).changed, "Disabled legacy project advanced")
			end
		end
		assert(
			state.research.project.remaining == 12.5 and state.research.completed.craft == nil,
			"Legacy project changed"
		)
		assert(Economy.interval(state, Catalog.buildings.farm) == 1, "Disabled work bonus affected Farm")
		assert(Economy.interval(state, Catalog.buildings.material) == 1.5, "Disabled work bonus affected Clay")
		assert(Economy.interval(state, Catalog.buildings.workshop) == 1.5, "Recipe interval changed")
		assert(State.validate(state, "sparta"), "Paused legacy project failed validation")
	end)
	check("all nine completed legacy nodes remain valid and malformed research remains rejected", function()
		local state = State.new("sparta", 0)
		state.hallUpgraded = true
		for _, id in { "work", "craft", "store", "muster", "drill", "supply", "records", "porters", "trade" } do
			state.research.completed[id] = true
			assert(State.validate(state, "sparta"), "Legacy node failed validation: " .. id)
		end
		state.research.completed.work = false
		assert(not State.validate(state, "sparta"), "Malformed completed node became a default")
		state = State.new("sparta", 0)
		state.hallUpgraded = true
		for _, remaining in { 0, -1, 30.1, 0 / 0, math.huge, "30" } do
			state.research.project = { id = "work", remaining = remaining }
			assert(not State.validate(state, "sparta"), "Malformed paused project accepted")
		end
		state.research.project = { id = "craft", remaining = 60 }
		assert(not State.validate(state, "sparta"), "Legacy project predecessor ignored")
	end)
	return count
end

return run

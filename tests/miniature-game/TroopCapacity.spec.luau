--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local State = require(Server.State)
local Actions = require(Server.Actions)
local Economy = require(Server.Economy)
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	local function oversubscribed()
		local state = State.new("sparta", 0)
		state.buildings[1].x, state.buildings[1].z, state.buildings[1].rotation = -6, -10, 90
		state.buildings[2].x, state.buildings[2].z = -16, 6
		state.buildings[3].x, state.buildings[3].z = 6, -10
		local ids = {}
		for _, site in
			{
				{ "training", -14, -10, 90 },
				{ "training", -6, 8, 90 },
				{ "ranged", 14, -10, 90 },
				{ "ranged", 6, 8, 90 },
				{ "healer", -16, 12, 0 },
			}
		do
			state.plans[site[1]] = 1
			local result =
				Actions.apply(state, "place", { kind = site[1], x = site[2], z = site[3], rotation = site[4] }, 0)
			assert(result.ok, "Military capacity fixture placement failed")
			table.insert(ids, result.buildingId)
		end
		assert(Actions.apply(state, "reclaim", { buildingId = "b3" }, 0).ok, "Farm site did not free")
		state.plans.training = 1
		local waiting = Actions.apply(state, "place", { kind = "training", x = 6, z = -10, rotation = 90 }, 0)
		state.plans.healer = 1
		local lastMedic = Actions.apply(state, "place", { kind = "healer", x = 16, z = 12, rotation = 0 }, 0)
		assert(waiting.ok and lastMedic.ok and State.validate(state, "sparta"), "Oversubscribed settlement is invalid")
		return state, ids[1], waiting.buildingId, lastMedic.buildingId
	end
	check("the ten-troop cap counts medics and keeps full pairs waiting when a later medic can fit", function()
		assert(Config.troopCap == 10, "Military cap is not ten total troops")
		local state, _, waiting, lastMedic = oversubscribed()
		local groups, counts = State.troopGroups(state), State.troops(state)
		assert(
			counts.melee == 4 and counts.ranged == 4 and counts.medic == 2,
			"Twelve demanded troops exceeded ten or excluded medics"
		)
		assert(groups[waiting] == nil, "Two-person group was split into the ninth/tenth slot")
		assert(
			groups[lastMedic].role == "medic" and groups[lastMedic].count == 1,
			"Later medic did not use the final single slot"
		)
		local total = 0
		for _, group in groups do
			total += group.count
		end
		assert(total == 10 and #state.workers == 4, "Troops consumed civilian capacity")
		groups[lastMedic].count = 99
		assert(
			State.troopGroups(state)[lastMedic].count == 1 and state.roster.medic == 0,
			"Derived groups mutated saved data"
		)
	end)
	check("reclaiming an earlier group backfills a waiting pair without extra cost or production bonuses", function()
		local state, first, waiting, lastMedic = oversubscribed()
		local beforeCoins, beforePlans = state.coins, State.copy(state.plans)
		local beforeRate = Economy.interval(state, Catalog.buildings.farm)
		assert(State.troopGroups(state)[waiting] == nil, "Waiting group spawned early")
		local result = Actions.apply(state, "reclaim", { buildingId = first }, 0)
		assert(
			result.ok and state.plans.training == beforePlans.training + 1,
			"Reclaim did not return exactly its one item"
		)
		local groups, counts = State.troopGroups(state), State.troops(state)
		assert(
			groups[first] == nil and groups[waiting].role == "melee" and groups[waiting].count == 2,
			"Freed capacity did not backfill the waiting pair"
		)
		assert(
			groups[lastMedic].count == 1 and counts.melee + counts.ranged + counts.medic == 10,
			"Backfill exceeded capacity or displaced legal support"
		)
		for kind, amount in beforePlans do
			if kind ~= "training" then
				assert(state.plans[kind] == amount, "Backfill consumed another building item")
			end
		end
		assert(state.coins == beforeCoins and State.inventorySize(state) == 0, "Backfill charged or minted resources")
		assert(
			Economy.interval(state, Catalog.buildings.farm) == beforeRate and #state.workers == 4,
			"Troops changed production rates or civilian capacity"
		)
		assert(State.validate(state, "sparta"), "Backfilled settlement invalid")
	end)
	return count
end

return run

--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local State = require(Server.State)
local Actions = require(Server.Actions)
local Workforce = require(Server.Workforce)
local Sessions = require(Server.Sessions)
local Config = require(Shared.Config)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)
local SAFE_INTEGER = 9007199254740991

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature structure limits: " .. name)
	end
	local function buyHouses(state, amount, startCycle)
		local cycle = startCycle or 0
		for _ = 1, amount do
			if state.merchant.stock.house == 0 then
				cycle += 1
				Actions.restock(state, cycle * Config.restockSeconds)
			end
			assert(
				Actions.apply(state, "buy", { kind = "house" }, cycle * Config.restockSeconds).ok,
				"Held plans still have a count cap"
			)
		end
		return cycle
	end
	local function largeSettlement()
		local state = State.new("sparta", 0)
		state.coins = 50000
		buyHouses(state, 20)
		local ids = {}
		for _, z in { -26, -18, 18, 26 } do
			for _, x in { -34, -26, -18, -10, 10, 18, 26, 34 } do
				if #ids == 20 then
					break
				end
				local result = Actions.apply(state, "place", { kind = "house", x = x, z = z, rotation = 0 }, 0)
				assert(result.ok, "Legal structure placement blocked by a count cap")
				table.insert(ids, result.buildingId)
			end
		end
		Workforce.reconcile(state)
		return state, ids
	end
	check("more than twelve paid structures place legally and survive fake saved roundtrip", function()
		local state = largeSettlement()
		assert(#state.buildings == 23 and State.validate(state, "sparta"), "Large dense settlement invalid")
		assert(state.coins == 48400 and #state.workers == 8, "Uncapped structures changed wallet or civilian cap")
		local store = FakeStore.new()
		store:seed("miniature-development:112", { schemaVersion = 1, civilizations = { sparta = state } })
		local sessions = Sessions.new({
			store = store,
			clock = function()
				return 0
			end,
			token = function()
				return "large-settlement"
			end,
		})
		assert(sessions:load(112).ok and sessions:select(112, "sparta").ok, "Large settlement did not restore")
		assert(
			#sessions:current(112).buildings == 23 and sessions:current(112).nextBuildingId == 24,
			"Restore lost structures or stable IDs"
		)
		assert(sessions:save(112).ok, "Large settlement failed save")
		assert(
			#store:read("miniature-development:112").civilizations.sparta.buildings == 23,
			"Save truncated placed structures"
		)
	end)
	check("more than twelve held plans buy and reclaim exactly once without an aggregate cap", function()
		local state = State.new("sparta", 0)
		state.coins = 50000
		buyHouses(state, 20)
		assert(
			state.plans.house == 20 and state.coins == 48400 and State.validate(state, "sparta"),
			"Large held-plan purchase invalid"
		)
		local farm = state.buildings[3]
		farm.output = 2
		assert(Actions.apply(state, "reclaim", { buildingId = farm.id }, 0).ok, "Existing held plans blocked reclaim")
		assert(
			state.plans.house == 20 and state.plans.farm == 1 and state.goods.food == 2,
			"Reclaim lost held plans or farm output"
		)
		assert(
			not Actions.apply(state, "reclaim", { buildingId = farm.id }, 0).ok and state.plans.farm == 1,
			"Reclaim duplicated returned plan"
		)
		state.plans.timber = SAFE_INTEGER
		assert(State.validate(state, "sparta"), "Independent safe plan amounts were treated as an aggregate cap")
	end)
	check("plan numeric validation rejects noncanonical values and increments never lose exactness", function()
		local state = State.new("sparta", 0)
		for _, value in { -1, 0.5, math.huge, 0 / 0, "13", false, SAFE_INTEGER + 1 } do
			state.plans.house = value
			assert(not State.validate(state, "sparta"), "Malformed plan count accepted")
		end
		state.plans.house, state.coins = SAFE_INTEGER, 50000
		assert(State.validate(state, "sparta"), "Safe integer plan amount rejected")
		assert(not Actions.apply(state, "buy", { kind = "house" }, 0).ok, "Plan increment exceeded exact numeric range")
		assert(
			state.coins == 50000 and state.plans.house == SAFE_INTEGER and state.merchant.stock.house == 2,
			"Overflow buy partially mutated ledger"
		)
		state.plans.farm = SAFE_INTEGER
		state.buildings[3].output = 2
		assert(
			not Actions.apply(state, "reclaim", { buildingId = "b3" }, 0).ok,
			"Reclaim overflow lost a returned plan"
		)
		assert(
			#state.buildings == 3 and state.goods.food == 0 and state.buildings[3].output == 2,
			"Overflow reclaim partially mutated settlement"
		)
	end)
	check("uncapped placed arrays retain dense canonical keys and malformed saves never overwrite", function()
		local state = largeSettlement()
		state.buildings[10] = nil
		assert(not State.validate(state, "sparta"), "Sparse large structure array accepted")
		local store = FakeStore.new()
		store:seed("miniature-development:113", { schemaVersion = 1, civilizations = { sparta = state } })
		local sessions = Sessions.new({
			store = store,
			clock = function()
				return 0
			end,
			token = function()
				return "sparse-large"
			end,
		})
		assert(not sessions:load(113).ok and #store.commits == 0, "Malformed structure save overwrote prior progress")
		for _, key in { 0, -1, 1.5, math.huge, "24" } do
			local broken = State.new("sparta", 0)
			broken.buildings[key] = broken.buildings[1]
			assert(not State.validate(broken, "sparta"), "Noncanonical structure key accepted")
		end
	end)
	check("spatial unique goods stock military and identity guards remain after removing count caps", function()
		local state = largeSettlement()
		state.plans.house = 1
		assert(
			not Actions.apply(state, "place", { kind = "house", x = -34, z = -26, rotation = 0 }, 0).ok,
			"Uncapped structures overlapped"
		)
		assert(
			not Actions.apply(state, "place", { kind = "house", x = 40, z = 26, rotation = 0 }, 0).ok,
			"Uncapped structures left plot"
		)
		assert(
			not Actions.apply(state, "place", { kind = "house", x = 0, z = 26, rotation = 0 }, 0).ok,
			"Uncapped structures blocked reserved lane"
		)
		state.nextBuildingId = 1000000
		assert(
			not Actions.apply(state, "place", { kind = "house", x = 34, z = 26, rotation = 0 }, 0).ok
				and state.plans.house == 1,
			"Stable identity integer exhaustion was removed"
		)
		state.nextBuildingId = 24
		state.plans.storehouse = 2
		assert(not State.validate(state, "sparta"), "Unique storage restriction removed")
		state.plans.storehouse = 0
		state.goods.food = 201
		assert(not State.validate(state, "sparta"), "Goods storage limit removed")
		assert(Config.workerCap == 8 and Config.troopCap == 10, "Structure limit removal changed civilian or army cap")
	end)
	return count
end
return run

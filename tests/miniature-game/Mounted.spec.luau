--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local State = require(Server.State)
local Workforce = require(Server.Workforce)
local Actions = require(Server.Actions)
local Catalog = require(Shared.Catalog)
local Battle = require(Server.Battle)
local Sessions = require(Server.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature mounted: " .. name)
	end
	local function military(kinds)
		local state = State.new("sparta", 0)
		-- All sites are legal in the enlarged starter plot, without changing starter identities.
		for index, kind in kinds do
			table.insert(state.buildings, {
				id = "b" .. tostring(index + 3),
				kind = kind,
				x = ({ -30, -16, 16, 30 })[(index - 1) % 4 + 1],
				z = 18 + math.floor((index - 1) / 4) * -40,
				rotation = 0,
				output = 0,
			})
		end
		state.nextBuildingId = #state.buildings + 1
		Workforce.reconcile(state)
		return state
	end
	check("mounted plans cost five thousand Coins and privately replace two stock each cycle", function()
		local definition = Catalog.buildings.mount
		assert(
			definition and definition.price == 5000 and definition.category == "Military",
			"Mounted catalog unavailable"
		)
		assert(
			definition.width == 12 and definition.depth == 10 and not definition.research,
			"Mounted site or unlock changed"
		)
		local state = State.new("sparta", 0)
		state.coins = 10000
		assert(state.merchant.stock.mount == 2 and state.plans.mount == 0, "Mounted fresh stock missing")
		for _ = 1, 2 do
			assert(Actions.apply(state, "buy", { kind = "mount" }, 0).ok, "Mounted purchase failed")
		end
		assert(
			state.coins == 0 and state.plans.mount == 2 and state.merchant.stock.mount == 0,
			"Mounted purchase ledger wrong"
		)
		assert(not Actions.apply(state, "buy", { kind = "mount" }, 0).ok, "Mounted stock overspent")
		assert(State.upgrade(state, "sparta").merchant.stock.mount == 0, "Restore refilled purchased stock")
		Actions.restock(state, 180)
		assert(
			state.merchant.stock.mount == 2 and state.plans.mount == 2,
			"Mounted merchant accumulated or consumed plans"
		)
	end)
	check("mounted groups consume two capacity and cannot use zero or one free slot", function()
		local state = military({ "training", "ranged", "training", "ranged", "healer", "mount", "healer", "mount" })
		local groups, counts = State.troopGroups(state), State.troops(state)
		assert(groups.b9 == nil and groups.b11 == nil, "Mounted group exceeded weighted capacity")
		assert(
			groups.b10.count == 1 and counts.medic == 2 and counts.mounted == 0,
			"Waiting mount stole the last medic slot"
		)
		assert(State.troopCapacityUsed(state) == 10 and #state.workers == 4, "Weighted usage changed cap or civilians")
		local mounts = military({ "mount", "mount", "mount", "mount", "mount", "mount" })
		local mountedGroups = State.troopGroups(mounts)
		assert(
			State.troops(mounts).mounted == 5 and State.troopCapacityUsed(mounts) == 10,
			"Five riders must fill ten capacity"
		)
		assert(mountedGroups.b4.capacityCost == 2 and mountedGroups.b9 == nil, "Mounted per-group capacity wrong")
	end)
	check("reclaiming an allocated building backfills a waiting rider without costs or worker changes", function()
		local state = military({ "training", "ranged", "training", "ranged", "healer", "mount" })
		assert(State.validate(state, "sparta"), "Mounted reclaim fixture invalid")
		local coins, workers = state.coins, State.copy(state.workers)
		assert(State.troopGroups(state).b9 == nil, "Mounted rider spawned with one free capacity")
		assert(Actions.apply(state, "reclaim", { buildingId = "b4" }, 0).ok, "Allocated group blocked reclaim")
		assert(
			State.troops(state).mounted == 1 and State.troopCapacityUsed(state) == 9,
			"Rider did not backfill weighted vacancy"
		)
		assert(
			state.coins == coins and state.plans.training == 1 and #state.workers == #workers,
			"Backfill charged or changed workers"
		)
		assert(
			Actions.apply(state, "reclaim", { buildingId = "b9" }, 0).ok and state.plans.mount == 1,
			"Mounted reclaim did not return one plan"
		)
		assert(
			State.troops(state).mounted == 0 and State.validate(state, "sparta"),
			"Mounted reclaim retained troops or invalid state"
		)
	end)
	check("old fake records default missing mount fields only and reject corrupt fields", function()
		local legacy = State.new("sparta", 0)
		legacy.plans.mount, legacy.merchant.stock.mount = nil, nil
		local upgraded = State.upgrade(legacy, "sparta")
		assert(
			upgraded and upgraded.plans.mount == 0 and upgraded.merchant.stock.mount == 0,
			"Legacy mount defaults missing"
		)
		assert(legacy.plans.mount == nil and legacy.merchant.stock.mount == nil, "Migration mutated stored record")
		Actions.restock(upgraded, 180)
		assert(upgraded.merchant.stock.mount == 2, "Migrated mounted plans never become available")
		for _, value in { false, "0", -1, 0 / 0, 9007199254740992 } do
			local broken = State.copy(upgraded)
			broken.plans.mount = value
			assert(State.upgrade(broken, "sparta") == nil, "Malformed mount plan silently defaulted")
		end
		local broken = State.copy(upgraded)
		broken.merchant.stock.mount = 3
		assert(State.upgrade(broken, "sparta") == nil, "Mounted stock exceeded two")
	end)
	check("mounted placement and reclaim transfer exactly one paid plan with no worker assignment", function()
		local state = State.new("sparta", 0)
		state.coins = 5000
		assert(Actions.apply(state, "buy", { kind = "mount" }, 0).ok, "Mounted purchase unavailable")
		local result = Actions.apply(state, "place", { kind = "mount", x = -30, z = 18, rotation = 90 }, 0)
		assert(result.ok and state.coins == 0 and state.plans.mount == 0, "Mounted placement double charged")
		assert(
			State.troops(state).mounted == 1 and State.troopCapacityUsed(state) == 2,
			"Mounted building did not supply one weighted rider"
		)
		for _, worker in state.workers do
			assert(worker.buildingId ~= result.buildingId, "Mounted building consumed a civilian job")
		end
		assert(
			Actions.apply(state, "reclaim", { buildingId = result.buildingId }, 0).ok,
			"Mounted building could not reclaim"
		)
		assert(
			not Actions.apply(state, "reclaim", { buildingId = result.buildingId }, 0).ok
				and state.plans.mount == 1
				and state.coins == 0,
			"Duplicate reclaim returned a free plan"
		)
		assert(State.validate(state, "sparta"), "Mounted ledger invalid")
	end)
	check("existing fake profiles load missing mount keys while malformed saves never overwrite progress", function()
		for _, malformed in { false, true } do
			local state = State.new("sparta", 0)
			state.coins = 4321
			state.plans.mount, state.merchant.stock.mount = nil, nil
			if malformed then
				state.plans.mount = "0"
			end
			local store = FakeStore.new()
			store:seed("miniature-development:92", { schemaVersion = 1, civilizations = { sparta = state } })
			local sessions = Sessions.new({
				store = store,
				clock = function()
					return 0
				end,
				token = function()
					return "mounted-load"
				end,
			})
			local loaded = sessions:load(92)
			if malformed then
				assert(not loaded.ok and not sessions:writable(92), "Malformed mounted save became writable")
				assert(
					#store.commits == 0 and store:read("miniature-development:92").civilizations.sparta.coins == 4321,
					"Rejected mounted save overwrote progress"
				)
			else
				assert(loaded.ok and sessions:select(92, "sparta").ok, "Existing pre-mount save failed to restore")
				assert(
					sessions:current(92).coins == 4321 and sessions:current(92).plans.mount == 0,
					"Mount migration changed saved economy"
				)
			end
		end
	end)
	check("battle independently rejects mounted weighted oversubscription atomically", function()
		local battle = Battle.new({ { id = "post", x = 0, z = 0, radius = 22, lineId = "line" } })
		local slots = {}
		for index = 1, 5 do
			table.insert(
				slots,
				{ id = "m" .. index, role = "mounted", buildingId = "b" .. index, index = 1, x = 0, z = 0 }
			)
		end
		assert(battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Five mounted slots rejected")
		table.insert(slots, { id = "extra", role = "medic", buildingId = "extra", index = 1, x = 0, z = 0 })
		assert(not battle:syncArmy("A", "sparta", "line", slots, 0).ok, "Mounted weight bypassed Battle cap")
		local total = 0
		for _, actor in battle.actors do
			if actor.team == "A" then
				total += 1
				assert(actor.role == "mounted", "Failed sync added an actor")
			end
		end
		assert(total == 5, "Rejected mounted sync mutated army")
	end)
	return count
end
return run

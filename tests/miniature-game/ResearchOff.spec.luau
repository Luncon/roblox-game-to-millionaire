--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local State = require(Server.State)
local Economy = require(Server.Economy)
local Actions = require(Server.Actions)
local Research = require(Server.Research)
local ActiveTime = require(Server.ActiveTime)
local Sessions = require(Server.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	check("research-off starter immediately stocks every purchasable building without unlocks", function()
		assert(Config.researchEnabled == false, "Research mode was not disabled")
		local state = State.new("sparta", 0)
		state.coins = 10000
		local types = 0
		for kind, definition in Catalog.buildings do
			if definition.price then
				types += 1
				assert(state.merchant.stock[kind] > 0, "Fresh building locked: " .. kind)
				assert(
					Actions.apply(state, "buy", { kind = kind }, 0).ok,
					"Unresearched building purchase failed: " .. kind
				)
			end
		end
		assert(types == 10 and State.validate(state, "sparta"), "Building catalog or unlocked state invalid")
	end)
	check(
		"repeatable military stock starts at two and replaces without accumulating or refilling on upgrade",
		function()
			local state = State.new("sparta", 0)
			state.coins = 10000
			for _, kind in { "training", "ranged", "healer" } do
				assert(state.merchant.stock[kind] == 2, "Military did not start with two stock: " .. kind)
				for _ = 1, 2 do
					assert(Actions.apply(state, "buy", { kind = kind }, 0).ok, "Second military purchase failed")
				end
				assert(not Actions.apply(state, "buy", { kind = kind }, 0).ok, "Spent military stock refilled")
			end
			assert(state.coins == 8600 and State.validate(state, "sparta"), "Military purchase ledger invalid")
			assert(State.upgrade(state, "sparta").merchant.stock.training == 0, "Restore refilled spent military stock")
			Actions.restock(state, 180)
			assert(
				state.merchant.stock.training == 2 and Actions.apply(state, "buy", { kind = "training" }, 180).ok,
				"Military cycle did not replace stock"
			)
			Actions.restock(state, 360)
			assert(state.merchant.stock.training == 2, "Military stock accumulated leftovers")
		end
	)
	check("disabled research preserves legacy projects and toggles without advancing effects", function()
		local state, clocks = State.new("sparta", 0), { b3 = 0 }
		state.hallUpgraded = true
		for _, id in { "work", "records", "porters", "trade" } do
			state.research.completed[id] = true
		end
		state.research.project = { id = "craft", remaining = 12.5 }
		state.settings.autoCollect, state.settings.autoSell = true, true
		state.goods.food, state.buildings[3].output = 10, 60
		assert(State.validate(state, "sparta"), "Valid legacy research state rejected")
		assert(not Research.start(state, "muster").ok, "Disabled research purchase accepted")
		assert(Economy.interval(state, Catalog.buildings.farm) == 1, "Old raw-production bonus remained active")
		assert(Economy.interval(state, Catalog.buildings.material) == 1.5, "Old material bonus remained active")
		local result = ActiveTime.step(state, clocks, 1, 1, true, 0)
		assert(not result.research.changed and state.research.project.remaining == 12.5, "Disabled project advanced")
		assert(
			state.goods.food == 10 and state.buildings[3].output == 60 and state.coins == 200,
			"Disabled services changed the ledger"
		)
		assert(state.settings.autoCollect and state.settings.autoSell, "Legacy toggle data was destructively cleared")
	end)
	check(
		"military counts derive independently from every placed structure and reclaim removes its contribution",
		function()
			local state = State.new("sparta", 0)
			-- Explicit compact sites keep all six military buildings legal in the starter plot.
			state.buildings[1].x, state.buildings[1].z, state.buildings[1].rotation = -6, -10, 90
			state.buildings[2].x, state.buildings[2].z = -16, 6
			state.buildings[3].x, state.buildings[3].z = 6, -10
			for kind, sites in
				{
					training = { { -14, -10, 90 }, { -6, 8, 90 } },
					ranged = { { 14, -10, 90 }, { 6, 8, 90 } },
					healer = { { -16, 12, 0 }, { 16, 12, 0 } },
				}
			do
				state.plans[kind] = 2
				for _, site in sites do
					assert(
						Actions.apply(state, "place", { kind = kind, x = site[1], z = site[2], rotation = site[3] }, 0).ok,
						"Military setup failed: " .. kind
					)
				end
			end
			local counts = State.troops(state)
			assert(counts.melee == 4 and counts.ranged == 4 and counts.medic == 2, "Military used a global roster cap")
			assert(State.validate(state, "sparta"), "Multiple unresearched military buildings invalid")
			state.roster = { melee = 4, ranged = 4, medic = 1 }
			local removed
			for _, building in state.buildings do
				if building.kind == "training" then
					removed = building.id
					break
				end
			end
			assert(Actions.apply(state, "reclaim", { buildingId = removed }, 0).ok, "Automatic actors blocked reclaim")
			counts = State.troops(state)
			assert(
				counts.melee == 2 and counts.ranged == 4 and counts.medic == 2,
				"Reclaim changed another building's troops"
			)
			assert(State.validate(state, "sparta"), "Legacy roster field gated derived troops")
		end
	)
	check("legacy missing ranged fields migrate once without refilling spent eligible stock", function()
		local state = State.new("sparta", 0)
		state.plans.ranged, state.merchant.stock.ranged = nil, nil
		state.merchant.stock.workshop, state.merchant.stock.storehouse, state.merchant.stock.training, state.merchant.stock.healer =
			0, 0, 0, 0
		state.merchant.stock.farm, state.merchant.stock.timber = 0, 0
		state.coins = 1234
		local upgraded = State.upgrade(state, "sparta")
		assert(
			upgraded and upgraded.plans.ranged == 0 and upgraded.merchant.stock.ranged == 2,
			"Ranged fields did not migrate"
		)
		assert(
			upgraded.merchant.stock.workshop == 1 and upgraded.merchant.stock.training == 2,
			"Old locked stock stayed unavailable"
		)
		assert(
			upgraded.merchant.stock.farm == 0 and upgraded.merchant.stock.timber == 0,
			"Migration refilled spent ordinary stock"
		)
		assert(state.plans.ranged == nil and state.merchant.stock.workshop == 0, "Upgrade mutated the supplied record")
		local spent = State.copy(state)
		spent.hallUpgraded = true
		spent.research.completed.work, spent.research.completed.craft = true, true
		local spentUpgrade = State.upgrade(spent, "sparta")
		assert(
			spentUpgrade and spentUpgrade.merchant.stock.workshop == 0,
			"Migration refilled an already eligible spent workshop"
		)
		upgraded.merchant.stock.workshop, upgraded.merchant.stock.ranged = 0, 0
		local again = State.upgrade(upgraded, "sparta")
		assert(
			again and again.merchant.stock.workshop == 0 and again.merchant.stock.ranged == 0,
			"Repeated upgrade refilled purchased stock"
		)
		local store = FakeStore.new()
		store:seed("miniature-development:81", { schemaVersion = 1, civilizations = { sparta = state } })
		local sessions = Sessions.new({
			store = store,
			clock = function()
				return 0
			end,
			token = function()
				return "legacy-ranged"
			end,
		})
		assert(sessions:load(81).ok and sessions:select(81, "sparta").ok, "Legacy saved state did not load")
		assert(
			sessions:current(81).coins == 1234 and sessions:current(81).merchant.stock.training == 2,
			"Load lost progress or migration stock"
		)
	end)
	check("migration defaults only missing ranged values and never overwrites malformed saves", function()
		local outOfBounds = State.new("sparta", 0)
		outOfBounds.merchant.stock.ranged = 3
		assert(State.upgrade(outOfBounds, "sparta") == nil, "Ranged stock exceeded two-per-cycle bound")
		outOfBounds = State.new("sparta", 0)
		outOfBounds.plans.ranged = 9007199254740992
		assert(State.upgrade(outOfBounds, "sparta") == nil, "Unsafe ranged plan integer accepted")
		local partial = State.new("sparta", 0)
		partial.plans.ranged = nil
		assert(State.upgrade(partial, "sparta").plans.ranged == 0, "Missing ranged plan did not default to zero")
		partial = State.new("sparta", 0)
		partial.merchant.stock.ranged = nil
		assert(
			State.upgrade(partial, "sparta").merchant.stock.ranged == 0,
			"Isolated missing ranged stock did not default to zero"
		)
		for _, value in { false, -1, "0", 0 / 0, math.huge } do
			local state = State.new("sparta", 0)
			state.plans.ranged = value
			assert(State.upgrade(state, "sparta") == nil, "Malformed ranged plan became a default")
			state = State.new("sparta", 0)
			state.merchant.stock.ranged = value
			assert(State.upgrade(state, "sparta") == nil, "Malformed ranged stock became a default")
		end
		local state = State.new("sparta", 0)
		state.plans.ranged, state.merchant.stock.ranged = nil, nil
		state.coins = "broken"
		local store = FakeStore.new()
		store:seed("miniature-development:82", { schemaVersion = 1, civilizations = { sparta = state } })
		local commits = #store.commits
		local sessions = Sessions.new({
			store = store,
			clock = function()
				return 0
			end,
			token = function()
				return "bad-ranged"
			end,
		})
		assert(
			not sessions:load(82).ok and #store.commits == commits,
			"Migration overwrote malformed existing progress"
		)
		assert(
			store:read("miniature-development:82").civilizations.sparta.coins == "broken",
			"Malformed save was replaced"
		)
	end)
	return count
end

return run

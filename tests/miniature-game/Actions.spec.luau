--!strict
local State = require(game:GetService("ServerScriptService").Sandbox.State)
local Actions = require(game:GetService("ServerScriptService").Sandbox.Actions)
local Placement = require(game:GetService("ReplicatedStorage").MiniatureGame.Placement)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.Config)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	local function rich()
		local state = State.new("sparta", 0)
		state.coins = 50000
		state.goods.timber = 100
		return state
	end
	local function equal(first, second): boolean
		if type(first) ~= type(second) then
			return false
		end
		if type(first) ~= "table" then
			return first == second
		end
		for key, child in first do
			if not equal(child, second[key]) then
				return false
			end
		end
		for key in second do
			if first[key] == nil then
				return false
			end
		end
		return true
	end
	local function rejectsWithoutMutation(state, action, args)
		local before = State.copy(state)
		assert(not Actions.apply(state, action, args, 0).ok, "Invalid action accepted: " .. action)
		assert(equal(state, before), "Rejected action mutated state: " .. action)
	end
	check("private purchases deduct one stock and price while placement consumes the plan only", function()
		local state, other = rich(), rich()
		assert(Actions.apply(state, "buy", { kind = "farm" }, 0).ok, "Purchase failed")
		assert(
			state.coins == 49880 and state.plans.farm == 1 and state.merchant.stock.farm == 1,
			"Wrong purchase ledger"
		)
		assert(other.merchant.stock.farm == 2 and other.coins == 50000, "Other merchant changed")
		local placed = Actions.apply(state, "place", { kind = "farm", x = 16, z = -8, rotation = 0 }, 0)
		assert(placed.ok and placed.buildingId == "b4", "Placement failed")
		assert(state.coins == 49880 and state.plans.farm == 0 and #state.buildings == 4, "Placement charged again")
		rejectsWithoutMutation(state, "place", { kind = "farm", x = 8, z = 8, rotation = 0 })
		assert(State.validate(state, "sparta"), "Purchased state is invalid")
	end)
	check("unavailable stock invalid plans and insufficient Coins never partially deduct", function()
		local state = rich()
		rejectsWithoutMutation(state, "buy", { kind = "unknown" })
		rejectsWithoutMutation(state, "buy", { kind = "civic" })
		state.merchant.stock.farm = 0
		rejectsWithoutMutation(state, "buy", { kind = "farm" })
		state.coins = 1
		rejectsWithoutMutation(state, "buy", { kind = "house" })
		state.coins = 50000
		state.hallUpgraded = true
		state.research.completed.work = true
		state.research.completed.craft = true
		Actions.restock(state, 180)
		state.goods.timber, state.coins = 0, 239
		rejectsWithoutMutation(state, "buy", { kind = "workshop" })
		state.plans.house = 9007199254740991
		rejectsWithoutMutation(state, "buy", { kind = "house" })
	end)
	check("larger starting plots allow edge placement and restore without an expansion purchase", function()
		assert(Config.plotWidth == 80 and Config.plotDepth == 64, "Starting plot did not expand")
		for _, x in { -36, 36 } do
			for _, z in { -28, 28 } do
				for _, rotation in { 0, 90, 180, 270 } do
					assert(Placement.validate({}, "farm", x, z, rotation), "New plot corner is unavailable")
				end
			end
		end
		local state = State.new("sparta", 0)
		assert(Actions.apply(state, "buy", { kind = "farm" }, 0).ok, "Starter cannot buy a farm")
		assert(
			Actions.apply(state, "place", { kind = "farm", x = 36, z = 28, rotation = 90 }, 0).ok,
			"Outer farm refused"
		)
		assert(state.coins == 80 and State.validate(State.copy(state), "sparta"), "Outer placement cannot restore")
		state.plans.farm = 1
		for _, point in { { 38, 28 }, { -38, 28 }, { 36, 30 }, { 36, -30 }, { 36, 28 }, { 0, 28 } } do
			rejectsWithoutMutation(state, "place", { kind = "farm", x = point[1], z = point[2], rotation = 0 })
		end
	end)
	check("purchases hall and research use Coins without consuming carried resources", function()
		local state = rich()
		state.goods.timber = 0
		assert(Actions.apply(state, "upgradeHall", {}, 0).ok, "Coin-only council upgrade required Timber")
		for id in require(game:GetService("ReplicatedStorage").MiniatureGame.Catalog).research do
			state.research.completed[id] = true
		end
		Actions.restock(state, 180)
		for _, kind in { "workshop", "storehouse", "training", "healer" } do
			assert(Actions.apply(state, "buy", { kind = kind }, 180).ok, "Coin-only plan required Timber: " .. kind)
		end
		assert(state.goods.timber == 0 and state.goods.material == 0, "Purchase changed inventory")
	end)
	check("restocks replace rather than accumulate and spent stock waits for the next cycle", function()
		local state = rich()
		state.merchant.stock.farm = 0
		assert(not Actions.restock(state, 179), "Stock refreshed early")
		assert(state.merchant.stock.farm == 0, "Stock changed before boundary")
		assert(Actions.restock(state, 180) and state.merchant.stock.farm == 2, "Boundary did not refresh")
		state.merchant.stock.workshop = 0
		state.hallUpgraded = true
		state.research.completed.work = true
		state.research.completed.craft = true
		assert(state.merchant.stock.workshop == 0, "Spent stock refilled outside the merchant cycle")
		assert(Actions.restock(state, 180000) and state.merchant.stock.workshop == 1, "Current-cycle stock missing")
		assert(state.merchant.stock.farm == 2, "Elapsed cycles accumulated stock")
		assert(not Actions.restock(state, 180000), "Same cycle refilled spent stock")
	end)
	check("invalid placement and relocation preserve identity workers output and wallet", function()
		local state = rich()
		state.plans.farm = 1
		for _, args in
			{
				{ kind = "farm", x = 0, z = 8, rotation = 0 },
				{ kind = "farm", x = Config.plotWidth / 2, z = 8, rotation = 0 },
				{ kind = "farm", x = 8, z = -8, rotation = 0 },
				{ kind = "farm", x = 8.5, z = 8, rotation = 0 },
				{ kind = "farm", x = 8, z = 8, rotation = 45 },
				{ kind = "farm", x = 0 / 0, z = 8, rotation = 0 },
			}
		do
			rejectsWithoutMutation(state, "place", args)
		end
		state.buildings[3].output = 7
		assert(Actions.apply(state, "move", { buildingId = "b3", x = 16, z = -8, rotation = 90 }, 0).ok, "Move failed")
		assert(state.buildings[3].id == "b3" and state.buildings[3].output == 7, "Move reset building")
		assert(state.workers[1].buildingId == "b3" and state.coins == 50000, "Move changed ownership/economy")
		assert(State.validate(state, "sparta"), "Moved state invalid")
	end)
	check("unpacking rejects protected occupied nonempty and capacity-dependent buildings", function()
		local state = rich()
		rejectsWithoutMutation(state, "unpack", { buildingId = "b1" })
		rejectsWithoutMutation(state, "unpack", { buildingId = "b3" })
		rejectsWithoutMutation(state, "unpack", { buildingId = "b2" })
		state.plans.farm = 1
		local placed = Actions.apply(state, "place", { kind = "farm", x = 16, z = -8, rotation = 0 }, 0)
		assert(placed.ok, "Setup placement failed")
		state.buildings[4].output = 1
		rejectsWithoutMutation(state, "unpack", { buildingId = "b4" })
		state.buildings[4].output = 0
		local before = state.coins
		assert(Actions.apply(state, "unpack", { buildingId = "b4" }, 0).ok, "Empty farm did not unpack")
		assert(state.plans.farm == 1 and state.coins == before and #state.buildings == 3, "Unpack minted Coins")
	end)
	check("hiring and assignment respect purchased housing worker slots and ownership", function()
		local state = rich()
		assert(Actions.apply(state, "hire", {}, 0).ok and Actions.apply(state, "hire", {}, 0).ok, "Hiring failed")
		assert(#state.workers == 4 and state.coins == 49950, "Wrong hiring price")
		rejectsWithoutMutation(state, "hire", {})
		rejectsWithoutMutation(state, "assign", { workerId = "w3", buildingId = "b3" })
		assert(Actions.apply(state, "assign", { workerId = "w1" }, 0).ok, "Unassignment failed")
		local result = Actions.apply(state, "assign", { workerId = "w3", buildingId = "b3" }, 0)
		assert(result.ok and result.resetProduction, "Assignment clock reset missing")
		rejectsWithoutMutation(state, "assign", { workerId = "foreign", buildingId = "b3" })
		rejectsWithoutMutation(state, "assign", { workerId = "w1", buildingId = "b2" })
		assert(State.validate(state, "sparta"), "Assignments invalid")
	end)
	check("unique plans remain unique across held and placed states", function()
		local state = rich()
		Actions.restock(state, 180)
		assert(Actions.apply(state, "buy", { kind = "storehouse" }, 180).ok, "Storehouse purchase failed")
		Actions.restock(state, 360)
		rejectsWithoutMutation(state, "buy", { kind = "storehouse" })
		assert(state.merchant.stock.storehouse == 0, "Owned unique plan restocked")
	end)
	check("saved assignment presets require research restore owned slots and survive unpack safely", function()
		local state = rich()
		rejectsWithoutMutation(state, "settings", { setting = "savePreset" })
		state.hallUpgraded, state.research.completed.records = true, true
		state.plans.timber = 1
		assert(
			Actions.apply(state, "place", { kind = "timber", x = 8, z = 8, rotation = 0 }, 0).ok,
			"Timber setup failed"
		)
		assert(Actions.apply(state, "assign", { workerId = "w1", buildingId = "b4" }, 0).ok, "Assignment failed")
		assert(Actions.apply(state, "settings", { setting = "savePreset" }, 0).ok, "Preset save failed")
		Actions.apply(state, "assign", { workerId = "w1" }, 0)
		assert(
			Actions.apply(state, "settings", { setting = "applyPreset" }, 0).ok and state.workers[1].buildingId == "b4",
			"Preset restore failed"
		)
		Actions.apply(state, "assign", { workerId = "w1" }, 0)
		assert(Actions.apply(state, "unpack", { buildingId = "b4" }, 0).ok, "Unused preset target did not unpack")
		assert(state.settings.preset.w1 == false, "Unpack left orphan preset")
		assert(
			Actions.apply(state, "settings", { setting = "applyPreset" }, 0).ok and state.workers[1].buildingId == nil,
			"Orphan target returned"
		)
		assert(State.validate(state, "sparta"), "Preset state invalid")
		Actions.apply(state, "hire", {}, 0)
		state.settings.preset = { w1 = "b3", w2 = "b3", w3 = "b3" }
		rejectsWithoutMutation(state, "settings", { setting = "applyPreset" })
		assert(not State.validate(state, "sparta"), "Overcapacity saved preset accepted")
	end)
	check("military presentation rosters require completed research and placed buildings", function()
		local state = rich()
		rejectsWithoutMutation(state, "roster", { melee = 1, ranged = 0, medic = 0 })
		state.hallUpgraded, state.research.completed.muster = true, true
		state.plans.training = 1
		assert(
			Actions.apply(state, "place", { kind = "training", x = 8, z = 8, rotation = 0 }, 0).ok,
			"Training setup failed"
		)
		assert(Actions.apply(state, "roster", { melee = 1, ranged = 1, medic = 0 }, 0).ok, "Muster roster failed")
		rejectsWithoutMutation(state, "roster", { melee = 2, ranged = 1, medic = 0 })
		rejectsWithoutMutation(state, "roster", { melee = 1, ranged = 1, medic = 1 })
		rejectsWithoutMutation(state, "unpack", { buildingId = "b4" })
		state.research.completed.drill, state.research.completed.supply = true, true
		state.plans.healer = 1
		assert(
			Actions.apply(state, "place", { kind = "healer", x = 16, z = 8, rotation = 0 }, 0).ok,
			"Healer setup failed"
		)
		assert(Actions.apply(state, "roster", { melee = 3, ranged = 1, medic = 1 }, 0).ok, "Drill/Supply roster failed")
		assert(State.validate(state, "sparta"), "Military roster state invalid")
		rejectsWithoutMutation(state, "unpack", { buildingId = "b5" })
		assert(Actions.apply(state, "roster", { melee = 0, ranged = 0, medic = 0 }, 0).ok, "Roster clear failed")
		assert(
			Actions.apply(state, "unpack", { buildingId = "b4" }, 0).ok
				and Actions.apply(state, "unpack", { buildingId = "b5" }, 0).ok,
			"Cleared roster blocked unpack"
		)
	end)
	check("worker plan and goods capacity boundaries cannot be bypassed by repeated operations", function()
		local state = rich()
		state.plans.house = 1
		assert(
			Actions.apply(state, "place", { kind = "house", x = -6, z = 8, rotation = 0 }, 0).ok,
			"Second house failed"
		)
		for _ = 1, 6 do
			assert(Actions.apply(state, "hire", {}, 0).ok, "Hiring to eight failed")
		end
		rejectsWithoutMutation(state, "hire", {})
		rejectsWithoutMutation(state, "unpack", { buildingId = "b4" })
		assert(#state.workers == 8 and State.validate(state, "sparta"), "Eight-worker state invalid")
		state.hallUpgraded = true
		state.research.completed.work, state.research.completed.craft, state.research.completed.store = true, true, true
		state.plans.storehouse = 1
		assert(
			Actions.apply(state, "place", { kind = "storehouse", x = 8, z = 8, rotation = 0 }, 0).ok,
			"Storehouse failed"
		)
		state.goods.timber, state.goods.food = 100, 201
		rejectsWithoutMutation(state, "unpack", { buildingId = "b5" })
		state.goods.food = 100
		assert(Actions.apply(state, "unpack", { buildingId = "b5" }, 0).ok, "Empty capacity dependency did not clear")
		assert(State.validate(state, "sparta"), "Capacity restore invalid")
	end)
	check("a geometrically valid thirteenth structure consumes exactly one plan", function()
		local state = rich()
		-- Reuse the original thirteen-site fixture to prove the retired count cap stays absent.
		state.buildings[1].x, state.buildings[1].z, state.buildings[1].rotation = -6, -10, 90
		state.buildings[2].x, state.buildings[2].z = -16, 6
		state.buildings[3].x, state.buildings[3].z = 6, -10
		assert(State.validate(state, "sparta"), "Packed starter fixture is invalid")
		state.plans.house = 12
		local spare
		for z = -12, 12, 2 do
			for x = -16, 16, 2 do
				if Placement.validate(state.buildings, "house", x, z, 0) then
					if #state.buildings < 12 then
						assert(
							Actions.apply(state, "place", { kind = "house", x = x, z = z, rotation = 0 }, 0).ok,
							"Legal site before thirteenth failed"
						)
					else
						spare = { kind = "house", x = x, z = z, rotation = 0 }
						break
					end
				end
			end
			if spare then
				break
			end
		end
		assert(#state.buildings == 12 and spare ~= nil, "Fixture did not reach the prior count boundary")
		local before = state.plans.house
		assert(Actions.apply(state, "place", spare, 0).ok, "Thirteenth legal structure was refused")
		assert(#state.buildings == 13 and state.plans.house == before - 1, "Thirteenth structure used wrong plan count")
		assert(State.validate(state, "sparta"), "Thirteenth legal structure invalidated settlement")
	end)
	return count
end

return run

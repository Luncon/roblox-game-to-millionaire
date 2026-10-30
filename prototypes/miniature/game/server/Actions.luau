--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Placement = require(Shared.Placement)
local State = require(script.Parent.State)
local Economy = require(script.Parent.Economy)
local Research = require(script.Parent.Research)
local MilitaryResearch = require(script.Parent.MilitaryResearch)
local ArmyGroups = require(Shared.ArmyGroups)
local Workforce = require(script.Parent.Workforce)
local Actions = {}

local function fail(reason)
	return { ok = false, reason = reason }
end

function Actions.restock(state, now: number): boolean
	if type(now) ~= "number" or not (now >= 0 and now < math.huge) then
		return false
	end
	local cycle = math.floor(now / Config.restockSeconds)
	if cycle <= state.merchant.cycle then
		return false
	end
	state.merchant = { cycle = cycle, stock = State.freshStock(state) }
	return true
end

local handlers = {}
function handlers.travel(_state, args)
	if args.destination ~= "buy" and args.destination ~= "sell" and args.destination ~= "civilization" then
		return fail("invalid_destination")
	end
	return { ok = true, destination = args.destination }
end

function handlers.buy(state, args)
	local definition = if type(args.kind) == "string" then Catalog.buildings[args.kind] else nil
	if not definition or not definition.price then
		return fail("invalid_plan")
	end
	if Config.researchEnabled and definition.research and not state.research.completed[definition.research] then
		return fail("research_required")
	end
	if state.merchant.stock[args.kind] < 1 then
		return fail("out_of_stock")
	end
	if not State.integer(state.plans[args.kind], Config.maxSafeInteger - 1) then
		return fail("plan_overflow")
	end
	if definition.unique and State.count(state, args.kind) + state.plans[args.kind] > 0 then
		return fail("unique_owned")
	end
	if state.coins < definition.price then
		return fail("insufficient_resources")
	end
	state.coins -= definition.price
	state.plans[args.kind] += 1
	state.merchant.stock[args.kind] -= 1
	return { ok = true, kind = args.kind }
end

function handlers.place(state, args)
	if type(args.kind) ~= "string" or not state.plans[args.kind] or state.plans[args.kind] < 1 then
		return fail("plan_required")
	end
	if state.nextBuildingId >= 1000000 then
		return fail("building_capacity")
	end
	local valid, reason = Placement.validate(state.buildings, args.kind, args.x, args.z, args.rotation)
	if not valid then
		return fail(reason)
	end
	local id = "b" .. state.nextBuildingId
	table.insert(
		state.buildings,
		{ id = id, kind = args.kind, x = args.x, z = args.z, rotation = args.rotation, output = 0 }
	)
	state.nextBuildingId += 1
	state.plans[args.kind] -= 1
	return { ok = true, buildingId = id, resetBuildings = { id } }
end

function handlers.move(state, args)
	local building = Economy.building(state, args.buildingId)
	if not building then
		return fail("invalid_building")
	end
	local valid, reason = Placement.validate(state.buildings, building.kind, args.x, args.z, args.rotation, building.id)
	if not valid then
		return fail(reason)
	end
	building.x, building.z, building.rotation = args.x, args.z, args.rotation
	return { ok = true, buildingId = building.id }
end

function handlers.unpack(state, args)
	local building = Economy.building(state, args.buildingId)
	if not building or building.id == "b1" or building.id == "b3" then
		return fail("protected_building")
	end
	if building.output > 0 then
		return fail("output_not_empty")
	end
	for _, worker in state.workers do
		if worker.buildingId == building.id then
			return fail("workers_assigned")
		end
	end
	if not State.integer(state.plans[building.kind], Config.maxSafeInteger - 1) then
		return fail("plan_overflow")
	end
	if building.kind == "house" and #state.workers > State.housing(state) - 4 then
		return fail("housing_required")
	end
	if building.kind == "storehouse" and State.inventorySize(state) > Config.goodsCapacity then
		return fail("storage_required")
	end
	if building.kind == "training" and state.roster.melee + state.roster.ranged > 0 then
		return fail("roster_present")
	end
	if building.kind == "healer" and state.roster.medic > 0 then
		return fail("roster_present")
	end
	for index, candidate in state.buildings do
		if candidate == building then
			table.remove(state.buildings, index)
			break
		end
	end
	state.plans[building.kind] += 1
	for workerId, target in state.settings.preset do
		if target == building.id then
			state.settings.preset[workerId] = false
		end
	end
	ArmyGroups.reconcile(state)
	return { ok = true, buildingId = building.id, resetProduction = true, resetBuildings = { building.id } }
end

function handlers.reclaim(state, args)
	local building = Economy.building(state, args.buildingId)
	if not building then
		return fail("invalid_building")
	end
	if building.id == "b1" or (building.kind == "house" and State.count(state, "house") == 1) then
		return fail("protected_building")
	end
	if not State.integer(state.plans[building.kind], Config.maxSafeInteger - 1) then
		return fail("plan_overflow")
	end
	local capacity = if building.kind == "storehouse" then Config.goodsCapacity else State.capacity(state)
	if State.inventorySize(state) + building.output > capacity then
		return fail(if building.kind == "storehouse" then "storage_required" else "inventory_full")
	end
	if
		Config.researchEnabled
		and (
			(building.kind == "training" and state.roster.melee + state.roster.ranged > 0)
			or (building.kind == "healer" and state.roster.medic > 0)
		)
	then
		return fail("roster_present")
	end
	local output = Catalog.buildings[building.kind].output
	if output then
		state.goods[output] += building.output
	end
	for index, candidate in state.buildings do
		if candidate == building then
			table.remove(state.buildings, index)
			break
		end
	end
	state.plans[building.kind] += 1
	Workforce.reconcile(state)
	ArmyGroups.reconcile(state)
	return {
		ok = true,
		buildingId = building.id,
		kind = building.kind,
		amount = building.output,
		resetProduction = true,
	}
end

function handlers.hire(state)
	if
		#state.workers >= Config.workerCap
		or #state.workers >= State.housing(state)
		or state.nextWorkerId >= 1000000
	then
		return fail("worker_capacity")
	end
	if state.coins < 25 then
		return fail("insufficient_coins")
	end
	local id = "w" .. state.nextWorkerId
	state.coins -= 25
	state.nextWorkerId += 1
	table.insert(state.workers, { id = id })
	return { ok = true, workerId = id }
end

function handlers.assign(state, args)
	local selected
	for _, worker in state.workers do
		if worker.id == args.workerId then
			selected = worker
			break
		end
	end
	if not selected then
		return fail("invalid_worker")
	end
	if args.buildingId ~= nil then
		local building = Economy.building(state, args.buildingId)
		local slots = if building then Catalog.buildings[building.kind].workers else nil
		if not slots then
			return fail("invalid_producer")
		end
		local occupied = 0
		for _, worker in state.workers do
			if worker ~= selected and worker.buildingId == building.id then
				occupied += 1
			end
		end
		if occupied >= slots then
			return fail("worker_slots_full")
		end
	end
	selected.buildingId = args.buildingId
	return { ok = true, workerId = selected.id, resetProduction = true }
end

function handlers.upgradeHall(state)
	if state.hallUpgraded then
		return fail("hall_complete")
	end
	if state.coins < 160 then
		return fail("insufficient_resources")
	end
	state.coins -= 160
	state.hallUpgraded = true
	return { ok = true }
end

function handlers.research(state, args)
	return Research.start(state, args.id)
end

function handlers.militaryResearch(state, args)
	for key in args do
		if key ~= "id" then
			return fail("invalid_research")
		end
	end
	return MilitaryResearch.start(state, args.id)
end

function handlers.configureArmy(state, args)
	return ArmyGroups.configure(state, args)
end

function handlers.roster(state, args)
	for _, kind in { "melee", "ranged", "medic" } do
		if not State.integer(args[kind], 4) then
			return fail("invalid_roster")
		end
	end
	local fighters = if State.count(state, "training") > 0 and state.research.completed.muster
		then (if state.research.completed.drill then 4 else 2)
		else 0
	local medics = if State.count(state, "healer") > 0 and state.research.completed.supply then 1 else 0
	if args.melee + args.ranged > fighters or args.medic > medics then
		return fail("roster_capacity")
	end
	state.roster = { melee = args.melee, ranged = args.ranged, medic = args.medic }
	return { ok = true }
end

function handlers.settings(state, args)
	local setting = args.setting
	if setting == "autoCollect" or setting == "autoSell" then
		local required = if setting == "autoCollect" then "porters" else "trade"
		if not state.research.completed[required] or type(args.value) ~= "boolean" then
			return fail("settings_locked")
		end
		state.settings[setting] = args.value
	elseif setting == "reserve" then
		if
			not state.research.completed.trade
			or not Catalog.salePrices[args.good]
			or not State.integer(args.value, 400)
		then
			return fail("invalid_reserve")
		end
		state.settings.reserves[args.good] = args.value
	elseif setting == "savePreset" then
		if not state.research.completed.records then
			return fail("settings_locked")
		end
		local preset = {}
		for _, worker in state.workers do
			preset[worker.id] = worker.buildingId or false
		end
		state.settings.preset = preset
	elseif setting == "applyPreset" then
		if not state.research.completed.records then
			return fail("settings_locked")
		end
		local counts = {}
		for _, worker in state.workers do
			local target = state.settings.preset[worker.id]
			if target then
				local building = Economy.building(state, target)
				local slots = if building then Catalog.buildings[building.kind].workers else nil
				counts[target] = (counts[target] or 0) + 1
				if not slots or counts[target] > slots then
					return fail("invalid_preset")
				end
			end
		end
		for _, worker in state.workers do
			worker.buildingId = state.settings.preset[worker.id] or nil
		end
		return { ok = true, resetProduction = true }
	else
		return fail("invalid_setting")
	end
	return { ok = true }
end

handlers.collect = Economy.collect
handlers.sell = Economy.sell
handlers.sellAll = Economy.sellAll

-- The caller settles old production into a private candidate before applying.
-- Failure never mutates that candidate; timing changes are returned for commit.
function Actions.apply(state, action, args, _now)
	local handler = if type(action) == "string" then handlers[action] else nil
	if not handler or type(args) ~= "table" then
		return fail("invalid_action")
	end
	return handler(state, args)
end

function Actions.automate(state): boolean
	return Economy.automate(state).changed
end

return Actions

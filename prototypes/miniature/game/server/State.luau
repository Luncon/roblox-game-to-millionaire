--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Placement = require(Shared.Placement)
local Civilizations = require(Shared.Civilizations)
local State = {}
local supported = {}
for _, civilization in Civilizations do
	supported[civilization.id] = true
end
State.supported = table.freeze(supported)

function State.copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in value do
		result[key] = State.copy(child)
	end
	return result
end

function State.integer(value, maximum): boolean
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end

local function keys(value, allowed): boolean
	if type(value) ~= "table" then
		return false
	end
	for key in value do
		if not allowed[key] then
			return false
		end
	end
	return true
end

local function array(value, maximum): boolean
	if type(value) ~= "table" or (maximum ~= nil and #value > maximum) then
		return false
	end
	local size = #value
	local count = 0
	for key in value do
		if not State.integer(key, size) or key < 1 then
			return false
		end
		count += 1
	end
	return count == size
end

function State.goods(): { [string]: number }
	local result = {}
	for _, id in Catalog.goods do
		result[id] = 0
	end
	return result
end

local function goodsValid(goods, maximum): boolean
	if not keys(goods, Catalog.salePrices) then
		return false
	end
	for _, id in Catalog.goods do
		if not State.integer(goods[id], maximum) then
			return false
		end
	end
	return true
end

function State.inventorySize(state): number
	local count = 0
	for _, id in Catalog.goods do
		count += state.goods[id]
	end
	return count
end

function State.count(state, kind): number
	local count = 0
	for _, building in state.buildings do
		if building.kind == kind then
			count += 1
		end
	end
	return count
end

function State.housing(state): number
	return State.count(state, "house") * 4
end

function State.capacity(state): number
	return if State.count(state, "storehouse") > 0 then 400 else Config.goodsCapacity
end

function State.troopGroups(state)
	local groups, total = {}, 0
	for _, building in state.buildings do
		local role = if building.kind == "training"
			then "melee"
			elseif building.kind == "ranged" then "ranged"
			elseif building.kind == "healer" then "medic"
			elseif building.kind == "mount" then "mounted"
			else nil
		if role then
			local amount = if role == "medic" or role == "mounted" then 1 else 2
			local capacityCost = amount * (if role == "mounted" then 2 else 1)
			if total + capacityCost <= Config.troopCap then
				groups[building.id] = { role = role, count = amount, capacityCost = capacityCost }
				total += capacityCost
			end
		end
	end
	return groups
end

function State.troops(state)
	local counts = { melee = 0, ranged = 0, medic = 0, mounted = 0 }
	for _, group in State.troopGroups(state) do
		counts[group.role] += group.count
	end
	return counts
end

function State.troopCapacityUsed(state): number
	local used = 0
	for _, group in State.troopGroups(state) do
		used += group.capacityCost
	end
	return used
end

function State.stockLimit(kind): number
	return if kind == "farm"
			or kind == "house"
			or kind == "training"
			or kind == "ranged"
			or kind == "healer"
			or kind == "mount"
		then 2
		else 1
end

function State.freshStock(state)
	local stock = {}
	for kind, definition in Catalog.buildings do
		if definition.price then
			local eligible = not Config.researchEnabled
				or not definition.research
				or state.research.completed[definition.research]
			local uniqueOwned = definition.unique and (State.count(state, kind) + state.plans[kind] > 0)
			stock[kind] = if not eligible or uniqueOwned then 0 else State.stockLimit(kind)
		end
	end
	return stock
end

function State.new(civilizationId: string, now: number)
	assert(supported[civilizationId], "Unsupported miniature civilization")
	local plans = {}
	for kind, definition in Catalog.buildings do
		if definition.price then
			plans[kind] = 0
		end
	end
	local state = {
		schemaVersion = 1,
		civilizationId = civilizationId,
		coins = 200,
		goods = State.goods(),
		plans = plans,
		buildings = {
			{ id = "b1", kind = "civic", x = -12, z = -8, rotation = 0, output = 0 },
			{ id = "b2", kind = "house", x = -12, z = 8, rotation = 0, output = 0 },
			{ id = "b3", kind = "farm", x = 8, z = -8, rotation = 0, output = 0 },
		},
		workers = { { id = "w1", buildingId = "b3" }, { id = "w2", buildingId = "b3" } },
		nextBuildingId = 4,
		nextWorkerId = 3,
		hallUpgraded = false,
		research = { completed = {} },
		merchant = { cycle = math.floor(now / Config.restockSeconds), stock = {} },
		settings = { autoCollect = false, autoSell = false, reserves = State.goods(), preset = {} },
		roster = { melee = 0, ranged = 0, medic = 0 },
	}
	state.merchant.stock = State.freshStock(state)
	return state
end

function State.validate(state, civilizationId): boolean
	if
		not supported[civilizationId]
		or not keys(state, {
			schemaVersion = true,
			civilizationId = true,
			coins = true,
			goods = true,
			plans = true,
			buildings = true,
			workers = true,
			nextBuildingId = true,
			nextWorkerId = true,
			hallUpgraded = true,
			research = true,
			merchant = true,
			settings = true,
			roster = true,
		})
		or state.schemaVersion ~= 1
		or state.civilizationId ~= civilizationId
		or not State.integer(state.coins, Config.coinCap)
		or not goodsValid(state.goods, 400)
		or not State.integer(state.nextBuildingId, 1000000)
		or state.nextBuildingId < 4
		or not State.integer(state.nextWorkerId, 1000000)
		or state.nextWorkerId < 3
		or type(state.hallUpgraded) ~= "boolean"
		or not array(state.buildings)
		or not array(state.workers, Config.workerCap)
		or not keys(state.research, { completed = true, project = true })
		or not keys(state.research.completed, Catalog.research)
	then
		return false
	end
	for id, completed in state.research.completed do
		local predecessor = Catalog.research[id].predecessor
		if
			completed ~= true
			or not state.hallUpgraded
			or (predecessor and not state.research.completed[predecessor])
		then
			return false
		end
	end
	local project = state.research.project
	if project ~= nil then
		if
			not keys(project, { id = true, remaining = true })
			or not Catalog.research[project.id]
			or not state.hallUpgraded
			or state.research.completed[project.id]
		then
			return false
		end
		local definition = Catalog.research[project.id]
		if
			type(project.remaining) ~= "number"
			or not (project.remaining > 0 and project.remaining <= definition.duration)
			or (definition.predecessor and not state.research.completed[definition.predecessor])
		then
			return false
		end
	end
	local ids, producers = {}, {}
	for _, building in state.buildings do
		if
			not keys(building, { id = true, kind = true, x = true, z = true, rotation = true, output = true })
			or type(building.id) ~= "string"
			or type(building.kind) ~= "string"
		then
			return false
		end
		local number = tonumber(string.match(building.id, "^b(%d+)$"))
		local definition = Catalog.buildings[building.kind]
		if
			not number
			or number < 1
			or building.id ~= "b" .. number
			or number >= state.nextBuildingId
			or ids[building.id]
			or not definition
			or not State.integer(building.output, Config.outputCapacity)
			or (not definition.output and building.output ~= 0)
			or (Config.researchEnabled and definition.research and not state.research.completed[definition.research])
		then
			return false
		end
		if not Placement.validate({}, building.kind, building.x, building.z, building.rotation, building.id) then
			return false
		end
		ids[building.id] = building
		producers[building.id] = definition.workers
	end
	for _, building in state.buildings do
		if
			not Placement.validate(
				state.buildings,
				building.kind,
				building.x,
				building.z,
				building.rotation,
				building.id
			)
		then
			return false
		end
	end
	if
		not ids.b1
		or ids.b1.kind ~= "civic"
		or State.count(state, "civic") ~= 1
		or State.count(state, "house") < 1
		or #state.workers < 2
		or #state.workers > State.housing(state)
	then
		return false
	end
	local workers, assignments = {}, {}
	for _, worker in state.workers do
		if not keys(worker, { id = true, buildingId = true }) or type(worker.id) ~= "string" then
			return false
		end
		local number = tonumber(string.match(worker.id, "^w(%d+)$"))
		if
			not number
			or number < 1
			or worker.id ~= "w" .. number
			or number >= state.nextWorkerId
			or workers[worker.id]
		then
			return false
		end
		workers[worker.id] = true
		if worker.buildingId ~= nil then
			if not producers[worker.buildingId] then
				return false
			end
			assignments[worker.buildingId] = (assignments[worker.buildingId] or 0) + 1
			if assignments[worker.buildingId] > producers[worker.buildingId] then
				return false
			end
		end
	end
	if
		not keys(state.plans, Catalog.buildings)
		or not keys(state.merchant, { cycle = true, stock = true })
		or not State.integer(state.merchant.cycle, 1000000000)
		or not keys(state.merchant.stock, Catalog.buildings)
	then
		return false
	end
	for kind, definition in Catalog.buildings do
		if definition.price then
			local amount, stock = state.plans[kind], state.merchant.stock[kind]
			if
				not State.integer(amount, Config.maxSafeInteger)
				or not State.integer(stock, State.stockLimit(kind))
				or (Config.researchEnabled and amount > 0 and definition.research and not state.research.completed[definition.research])
				or (Config.researchEnabled and stock > 0 and definition.research and not state.research.completed[definition.research])
				or (definition.unique and State.count(state, kind) + amount > 1)
			then
				return false
			end
		elseif state.plans[kind] ~= nil or state.merchant.stock[kind] ~= nil then
			return false
		end
	end
	if
		State.inventorySize(state) > State.capacity(state)
		or not keys(state.settings, { autoCollect = true, autoSell = true, reserves = true, preset = true })
		or type(state.settings.autoCollect) ~= "boolean"
		or type(state.settings.autoSell) ~= "boolean"
		or not goodsValid(state.settings.reserves, 400)
		or (state.settings.autoCollect and not state.research.completed.porters)
		or (state.settings.autoSell and not state.research.completed.trade)
		or type(state.settings.preset) ~= "table"
		or not keys(state.roster, { melee = true, ranged = true, medic = true })
		or not State.integer(state.roster.melee, 4)
		or not State.integer(state.roster.ranged, 4)
		or not State.integer(state.roster.medic, 1)
	then
		return false
	end
	local presetAssignments = {}
	for workerId, target in state.settings.preset do
		if
			not workers[workerId]
			or (target ~= false and not producers[target])
			or not state.research.completed.records
		then
			return false
		end
		if target then
			presetAssignments[target] = (presetAssignments[target] or 0) + 1
			if presetAssignments[target] > producers[target] then
				return false
			end
		end
	end
	local fighters = if State.count(state, "training") > 0 and state.research.completed.muster
		then (if state.research.completed.drill then 4 else 2)
		else 0
	local medics = if State.count(state, "healer") > 0 and state.research.completed.supply then 1 else 0
	if
		Config.researchEnabled and (state.roster.melee + state.roster.ranged > fighters or state.roster.medic > medics)
	then
		return false
	end
	return true
end

-- Only new catalog keys default when absent. The input is never mutated,
-- and malformed existing fields must pass the full validator before migration.
function State.upgrade(value, civilizationId)
	if type(value) ~= "table" then
		return nil
	end
	local candidate = State.copy(value)
	local plans = candidate.plans
	local stock = if type(candidate.merchant) == "table" then candidate.merchant.stock else nil
	if type(plans) ~= "table" or type(stock) ~= "table" then
		return nil
	end
	if plans.mount == nil then
		plans.mount = 0
	end
	if stock.mount == nil then
		stock.mount = 0
	end
	local legacy = plans.ranged == nil and stock.ranged == nil
	if plans.ranged == nil then
		plans.ranged = 0
	end
	if stock.ranged == nil then
		stock.ranged = 0
	end
	if not State.validate(candidate, civilizationId) then
		return nil
	end
	if legacy and not Config.researchEnabled then
		-- Missing both keys identifies the pre-ranged catalog. Refill only stocks
		-- that were unavailable to this old record, never ordinary spent stock.
		for kind, definition in Catalog.buildings do
			if
				definition.price
				and (kind == "ranged" or (definition.research and not candidate.research.completed[definition.research]))
				and stock[kind] == 0
				and plans[kind] == 0
				and State.count(candidate, kind) == 0
			then
				stock[kind] = State.stockLimit(kind)
			end
		end
	end
	return candidate
end

return State

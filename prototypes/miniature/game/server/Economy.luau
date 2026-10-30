--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local State = require(script.Parent.State)
local Economy = {}

function Economy.pruneClocks(state, clocks)
	local producers = {}
	for _, building in state.buildings do
		local definition = Catalog.buildings[building.kind]
		if definition and definition.output then
			producers[building.id] = true
		end
	end
	for id in clocks do
		if not producers[id] then
			clocks[id] = nil
		end
	end
end

function Economy.resetClocks(state, clocks, now: number)
	Economy.pruneClocks(state, clocks)
	for _, building in state.buildings do
		if Catalog.buildings[building.kind].output then
			clocks[building.id] = now
		end
	end
end

function Economy.building(state, id)
	for _, building in state.buildings do
		if building.id == id then
			return building
		end
	end
	return nil
end

function Economy.workers(state)
	local result = {}
	for _, worker in state.workers do
		if worker.buildingId then
			result[worker.buildingId] = (result[worker.buildingId] or 0) + 1
		end
	end
	return result
end

function Economy.interval(state, definition): number
	return definition.interval
		* (if Config.researchEnabled and state.research.completed.work and not definition.input then 0.9 else 1)
		/ Config.productionSpeed
end

function Economy.blocked(state, building, workers): string?
	local definition = Catalog.buildings[building.kind]
	if workers == 0 then
		return "no_workers"
	end
	if building.output + workers * definition.yield > Config.outputCapacity then
		return "output_full"
	end
	if definition.input and state.goods[definition.input] < workers then
		return "missing_input"
	end
	return nil
end

function Economy.step(state, clocks, now: number, active: boolean): boolean
	local assignments = Economy.workers(state)
	local changed = false
	for _, building in state.buildings do
		local definition = Catalog.buildings[building.kind]
		if definition.output then
			local workers = assignments[building.id] or 0
			local last = clocks[building.id]
			if last == nil or now < last then
				last = now
				clocks[building.id] = now
			end
			if not active or Economy.blocked(state, building, workers) then
				clocks[building.id] = now
			else
				local interval = Economy.interval(state, definition)
				local due = math.floor((now - last) / interval)
				local completed = 0
				for _ = 1, math.min(6, due) do
					if Economy.blocked(state, building, workers) then
						break
					end
					if definition.input then
						state.goods[definition.input] -= workers
					end
					building.output += workers * definition.yield
					completed += 1
					changed = true
				end
				clocks[building.id] = if due > 6 or Economy.blocked(state, building, workers)
					then now
					else last + completed * interval
			end
		end
	end
	return changed
end

function Economy.collect(state, args)
	local building = Economy.building(state, args.buildingId)
	if not building or not Catalog.buildings[building.kind].output then
		return { ok = false, reason = "invalid_producer" }
	end
	local amount = math.min(building.output, State.capacity(state) - State.inventorySize(state))
	if args.amount ~= nil then
		if not State.integer(args.amount, Config.outputCapacity) or args.amount < 1 then
			return { ok = false, reason = "invalid_collection" }
		end
		if args.amount > amount then
			return {
				ok = false,
				reason = if args.amount > building.output then "insufficient_output" else "inventory_full",
			}
		end
		amount = args.amount
	end
	if amount < 1 then
		return { ok = false, reason = if building.output == 0 then "empty_output" else "inventory_full" }
	end
	building.output -= amount
	state.goods[Catalog.buildings[building.kind].output] += amount
	return { ok = true, amount = amount }
end

function Economy.sellAll(state)
	local amount, coins = 0, 0
	for _, good in Catalog.goods do
		amount += state.goods[good]
		coins += state.goods[good] * Catalog.salePrices[good]
	end
	if amount == 0 then
		return { ok = false, reason = "inventory_empty" }
	end
	if state.coins + coins > Config.coinCap then
		return { ok = false, reason = "coin_capacity" }
	end
	for _, good in Catalog.goods do
		state.goods[good] = 0
	end
	state.coins += coins
	return { ok = true, amount = amount, coins = coins }
end

function Economy.sell(state, args)
	local price = if type(args.good) == "string" then Catalog.salePrices[args.good] else nil
	if not price or not State.integer(args.amount, State.capacity(state)) or args.amount < 1 then
		return { ok = false, reason = "invalid_sale" }
	end
	if state.goods[args.good] < args.amount then
		return { ok = false, reason = "insufficient_goods" }
	end
	local total = args.amount * price
	if state.coins + total > Config.coinCap then
		return { ok = false, reason = "coin_cap" }
	end
	state.goods[args.good] -= args.amount
	state.coins += total
	return { ok = true, amount = args.amount, coins = total }
end

-- Reuse the manual ledgers. Reserve one full input batch for each staffed workshop.
function Economy.automate(state)
	if not Config.researchEnabled then
		return { changed = false }
	end
	local changed = false
	if state.settings.autoCollect and state.research.completed.porters then
		for _, building in state.buildings do
			if Catalog.buildings[building.kind].output and Economy.collect(state, { buildingId = building.id }).ok then
				changed = true
			end
		end
	end
	if state.settings.autoSell and state.research.completed.trade then
		local protected = State.copy(state.settings.reserves)
		local inputBatches = State.goods()
		local workers = Economy.workers(state)
		for _, building in state.buildings do
			local input = Catalog.buildings[building.kind].input
			if input then
				inputBatches[input] += workers[building.id] or 0
			end
		end
		for _, good in Catalog.goods do
			protected[good] = math.max(protected[good], inputBatches[good])
			local amount = math.min(
				state.goods[good] - protected[good],
				math.floor((Config.coinCap - state.coins) / Catalog.salePrices[good])
			)
			if amount > 0 and Economy.sell(state, { good = good, amount = amount }).ok then
				changed = true
			end
		end
	end
	return { changed = changed }
end

return Economy

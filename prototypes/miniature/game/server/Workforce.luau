--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local State = require(script.Parent.State)
local Workforce = {}

-- Reconcile a trusted, private settlement candidate after old production settles.
-- Existing civilians and legal jobs stay stable; new jobs fill in building order.
function Workforce.reconcile(state): boolean
	local changed = false
	local population = math.min(State.housing(state), Config.workerCap)
	while #state.workers > population do
		table.remove(state.workers)
		changed = true
	end
	local ids = {}
	for _, worker in state.workers do
		ids[worker.id] = true
	end
	while #state.workers < population do
		local number = state.nextWorkerId
		if number >= 1000000 then
			-- The saved identifier bound is finite; at most eight IDs are occupied.
			number = 1
			while ids["w" .. number] do
				number += 1
			end
		else
			state.nextWorkerId += 1
		end
		local id = "w" .. number
		ids[id] = true
		table.insert(state.workers, { id = id })
		changed = true
	end
	local slots, occupied = {}, {}
	for _, building in state.buildings do
		slots[building.id] = Catalog.buildings[building.kind].workers
	end
	for _, worker in state.workers do
		local target = worker.buildingId
		if target then
			if slots[target] and (occupied[target] or 0) < slots[target] then
				occupied[target] = (occupied[target] or 0) + 1
			else
				worker.buildingId = nil
				changed = true
			end
		end
	end
	for _, worker in state.workers do
		if not worker.buildingId then
			for _, building in state.buildings do
				local capacity = slots[building.id]
				if capacity and (occupied[building.id] or 0) < capacity then
					worker.buildingId = building.id
					occupied[building.id] = (occupied[building.id] or 0) + 1
					changed = true
					break
				end
			end
		end
	end
	for workerId, target in state.settings.preset do
		if not ids[workerId] then
			state.settings.preset[workerId] = nil
			changed = true
		elseif target and not slots[target] then
			state.settings.preset[workerId] = false
			changed = true
		end
	end
	return changed
end

return Workforce

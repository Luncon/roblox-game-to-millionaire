--!strict
-- Saved membership is separate from transient deployment orders and troop lives.
local Catalog = require(script.Parent.Catalog)
local MilitaryResearch = require(script.Parent.MilitaryResearch)
local ArmyGroups = {}
export type Presets = { army2: { string }, army3: { string }, army4: { string } }
export type Building = { id: string, kind: string }
export type State = {
	buildings: { Building },
	armyGroups: Presets,
	militaryResearch: { completed: { [string]: boolean } },
}
export type Result = { ok: boolean, reason: string?, armyId: number? }
local keys = { "army2", "army3", "army4" }
local function dense(value: unknown, maximum: number): boolean
	if type(value) ~= "table" or #value > maximum then
		return false
	end
	local count = 0
	for key in value do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #value then
			return false
		end
		count += 1
	end
	return count == #value
end
local function owned(state: State): { [string]: boolean }
	local result = {}
	for _, building in state.buildings do
		local definition = Catalog.buildings[building.kind]
		if definition and definition.category == "Military" then
			result[building.id] = true
		end
	end
	return result
end
function ArmyGroups.new(): Presets
	return { army2 = {}, army3 = {}, army4 = {} }
end
function ArmyGroups.validate(state: State): boolean
	local presets = state.armyGroups
	if type(presets) ~= "table" then
		return false
	end
	for key in presets do
		if key ~= "army2" and key ~= "army3" and key ~= "army4" then
			return false
		end
	end
	local available = MilitaryResearch.groupSlots(state.militaryResearch.completed)
	local military, used = owned(state), {}
	for index, key in keys do
		local members = presets[key]
		if not dense(members, 128) or (index + 1 > available and #members > 0) then
			return false
		end
		for _, id in members do
			if type(id) ~= "string" or not military[id] or used[id] then
				return false
			end
			used[id] = true
		end
	end
	return true
end
function ArmyGroups.members(state: State, armyId: number): { string }?
	local available = MilitaryResearch.groupSlots(state.militaryResearch.completed)
	if type(armyId) ~= "number" or armyId % 1 ~= 0 or armyId < 1 or armyId > available then
		return nil
	end
	if armyId == 1 then
		local members = {}
		for _, building in state.buildings do
			local definition = Catalog.buildings[building.kind]
			if definition and definition.category == "Military" then
				table.insert(members, building.id)
			end
		end
		return members
	end
	return table.clone(state.armyGroups[keys[armyId - 1]])
end
function ArmyGroups.configure(state: State, args: unknown): Result
	if type(args) ~= "table" then
		return { ok = false, reason = "invalid_army_group" }
	end
	for key in args do
		if key ~= "armyId" and key ~= "buildingIds" then
			return { ok = false, reason = "invalid_army_group" }
		end
	end
	local armyId = args.armyId
	if type(armyId) ~= "number" or armyId % 1 ~= 0 or armyId < 2 or armyId > 4 then
		return { ok = false, reason = "army_readonly" }
	end
	if armyId > MilitaryResearch.groupSlots(state.militaryResearch.completed) then
		return { ok = false, reason = "army_locked" }
	end
	if not dense(args.buildingIds, 128) or not ArmyGroups.validate(state) then
		return { ok = false, reason = "invalid_army_group" }
	end
	local military, selected = owned(state), {}
	local candidate = {}
	for _, id in args.buildingIds do
		if type(id) ~= "string" or not military[id] then
			return { ok = false, reason = "invalid_army_building" }
		end
		if selected[id] then
			return { ok = false, reason = "duplicate_army_building" }
		end
		selected[id] = true
		table.insert(candidate, id)
	end
	for index, key in keys do
		if index + 1 ~= armyId then
			for _, id in state.armyGroups[key] do
				if selected[id] then
					return { ok = false, reason = "building_in_another_army" }
				end
			end
		end
	end
	table.sort(candidate)
	state.armyGroups[keys[armyId - 1]] = candidate
	return { ok = true, armyId = armyId }
end
function ArmyGroups.reconcile(state: State): boolean
	local military, used = owned(state), {}
	local maximum = MilitaryResearch.groupSlots(state.militaryResearch.completed)
	local changed = false
	for index, key in keys do
		local previous, current = state.armyGroups[key], {}
		for _, id in previous do
			if index + 1 <= maximum and military[id] and not used[id] then
				table.insert(current, id)
				used[id] = true
			end
		end
		if #previous ~= #current then
			state.armyGroups[key], changed = current, true
		end
	end
	return changed
end
return table.freeze(ArmyGroups)

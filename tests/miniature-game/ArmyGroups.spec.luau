--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Groups = require(Shared.ArmyGroups)
local function fixture()
	return {
		buildings = {
			{ id = "hall", kind = "civic" },
			{ id = "home", kind = "house" },
			{ id = "spear", kind = "training" },
			{ id = "bow", kind = "ranged" },
			{ id = "healer", kind = "healer" },
			{ id = "waiting-mount", kind = "mount" },
		},
		armyGroups = Groups.new(),
		militaryResearch = { completed = {} },
		coins = 71,
		lives = { spear = { life = 8, health = 42, respawnAt = 19 } },
		orders = { spear = "outpost_4" },
	}
end
local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS army groups: " .. name)
	end
	check("Army 1 derives every owned military building including waiting structures and cannot be edited", function()
		local state = fixture()
		assert(Groups.validate(state), "Fresh locked presets invalid")
		local members = Groups.members(state, 1)
		assert(
			members and #members == 4 and members[4] == "waiting-mount",
			"Army 1 omitted queued or support buildings"
		)
		assert(
			Groups.members(state, 2) == nil
				and Groups.configure(state, { armyId = 1, buildingIds = {} }).reason == "army_readonly",
			"All-army membership became editable"
		)
		assert(#state.armyGroups.army2 == 0 and #Groups.members(state, 1) == 4, "Refusal changed memberships")
	end)
	check("each control tier unlocks exactly one additional custom group", function()
		local state = fixture()
		for index, research in { "army_control", "army_slot_2", "army_slot_3" } do
			assert(
				Groups.configure(state, { armyId = index + 1, buildingIds = {} }).reason == "army_locked",
				"Custom army unlocked early"
			)
			state.militaryResearch.completed[research] = true
			assert(Groups.configure(state, { armyId = index + 1, buildingIds = {} }).ok, "Purchased group still locked")
			assert(Groups.validate(state), "Valid unlocked presets rejected")
		end
	end)
	check("invalid sparse mixed duplicate foreign and civilian selections are atomic refusals", function()
		local state = fixture()
		state.militaryResearch.completed.army_control = true
		assert(Groups.configure(state, { armyId = 2, buildingIds = { "spear" } }).ok, "Initial group failed")
		local previous = state.armyGroups.army2
		local mixed = {}
		mixed[1], mixed.extra = "bow", "spear"
		for _, invalid in
			{
				{ [2] = "bow" },
				mixed,
				{ ["1"] = "bow" },
				{ "bow", "bow" },
				{ "bow", "foreign" },
				{ "home" },
				{ "hall" },
				{ false },
			}
		do
			assert(
				not Groups.configure(state, { armyId = 2, buildingIds = invalid }).ok,
				"Malformed membership accepted"
			)
			assert(
				state.armyGroups.army2 == previous and previous[1] == "spear",
				"Failed edit partially changed saved membership"
			)
		end
		assert(
			not Groups.configure(state, { armyId = 2, buildingIds = {}, civilizationId = "rome" }).ok,
			"Client selected another civilization"
		)
		assert(state.armyGroups.army2 == previous, "Unexpected-field refusal mutated preset")
	end)
	check("custom armies are disjoint while all-army membership remains complete", function()
		local state = fixture()
		state.militaryResearch.completed.army_control, state.militaryResearch.completed.army_slot_2 = true, true
		assert(
			Groups.configure(state, { armyId = 2, buildingIds = { "spear", "healer" } }).ok,
			"Army 2 configuration failed"
		)
		assert(
			Groups.configure(state, { armyId = 3, buildingIds = { "spear" } }).reason == "building_in_another_army",
			"Overlapping custom groups accepted"
		)
		assert(
			Groups.configure(state, { armyId = 3, buildingIds = { "bow", "waiting-mount" } }).ok,
			"Independent group failed"
		)
		assert(#Groups.members(state, 1) == 4 and Groups.validate(state), "Custom grouping changed all-army scope")
	end)
	check("configuration changes only presets and returns independent membership copies", function()
		local state = fixture()
		state.militaryResearch.completed.army_control = true
		local life, orders = state.lives.spear, state.orders
		local requested = { "spear", "bow" }
		assert(Groups.configure(state, { armyId = 2, buildingIds = requested }).ok, "Valid edit failed")
		assert(
			requested[1] == "spear" and requested ~= state.armyGroups.army2,
			"Server rewrote or retained caller array"
		)
		local copy = Groups.members(state, 2)
		copy[1] = "foreign"
		assert(state.armyGroups.army2[1] == "bow", "Read membership leaked mutable preset")
		assert(
			state.coins == 71
				and state.lives.spear == life
				and life.life == 8
				and life.health == 42
				and life.respawnAt == 19
				and state.orders == orders
				and orders.spear == "outpost_4",
			"Preset edit affected economy, life, health, orders or respawn"
		)
	end)
	check("reclamation prunes only the removed structure and reset does not cancel current orders", function()
		local state = fixture()
		state.militaryResearch.completed.army_control = true
		assert(Groups.configure(state, { armyId = 2, buildingIds = { "spear", "healer" } }).ok, "Initial edit failed")
		for index, building in state.buildings do
			if building.id == "spear" then
				table.remove(state.buildings, index)
				break
			end
		end
		assert(
			Groups.reconcile(state) and #state.armyGroups.army2 == 1 and state.armyGroups.army2[1] == "healer",
			"Reclaim removed unrelated membership"
		)
		assert(not Groups.reconcile(state) and Groups.validate(state), "Reconciliation was not stable")
		assert(
			Groups.configure(state, { armyId = 2, buildingIds = {} }).ok and state.orders.spear == "outpost_4",
			"Reset changed transient commands"
		)
	end)
	check("saved presets require complete fixed keys and reject locked or overlapping data", function()
		local state = fixture()
		state.armyGroups = { army2 = {}, army3 = {} }
		assert(not Groups.validate(state), "Partially missing presets silently defaulted")
		state.armyGroups = Groups.new()
		state.armyGroups.extra = {}
		assert(not Groups.validate(state), "Unexpected preset key accepted")
		state.armyGroups = Groups.new()
		state.armyGroups.army2 = { "spear" }
		assert(not Groups.validate(state), "Locked saved group accepted")
		state.militaryResearch.completed.army_control, state.militaryResearch.completed.army_slot_2 = true, true
		state.armyGroups.army3 = { "spear" }
		assert(not Groups.validate(state), "Overlapping saved groups accepted")
		state.armyGroups.army3 = { "foreign" }
		assert(not Groups.validate(state), "Foreign saved structure accepted")
	end)
	check("different civilization/player preset tables never share mutations", function()
		local first, second = fixture(), fixture()
		first.militaryResearch.completed.army_control, second.militaryResearch.completed.army_control = true, true
		assert(Groups.configure(first, { armyId = 2, buildingIds = { "spear" } }).ok, "First civilization edit failed")
		assert(
			#second.armyGroups.army2 == 0 and Groups.configure(second, { armyId = 2, buildingIds = { "bow" } }).ok,
			"Group changes crossed state ownership"
		)
		assert(
			first.armyGroups.army2[1] == "spear" and second.armyGroups.army2[1] == "bow",
			"Independent selections collided"
		)
	end)
	return count
end
return run

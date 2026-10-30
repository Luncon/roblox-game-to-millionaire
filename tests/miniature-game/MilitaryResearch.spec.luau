--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Server = game:GetService("ServerScriptService").Sandbox
local Rules = require(Shared.MilitaryResearch)
local Research = require(Server.MilitaryResearch)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS military research: " .. name)
	end
	check("reference catalog contains twenty-nine ancient nodes with exact prerequisite prices and timers", function()
		assert(#Rules.order == 29, "Wrong military node count")
		local rows = {}
		for _, id in Rules.order do
			local node = Rules.nodes[id]
			assert(node.id == id and not rows[node.referenceRow], "Duplicate research identity or reference row")
			rows[node.referenceRow] = true
			assert(not node.predecessor or Rules.nodes[node.predecessor], "Broken military prerequisite")
			assert(table.isfrozen(node) and table.isfrozen(node.effect), "Research catalog mutable")
		end
		for _, excluded in { 4, 5, 6, 13, 14, 24, 25 } do
			assert(not rows[excluded], "Modern unlock became functional")
		end
		assert(
			Rules.nodes.army_training.price == 1000 and Rules.nodes.army_training.duration == 30,
			"First reference tier drifted"
		)
		assert(
			Rules.nodes.army_size_3.price == 100000000 and Rules.nodes.army_size_3.duration == 43200,
			"Army capacity reference drifted"
		)
		assert(
			Rules.nodes.masterwork_barding.price == 500000000 and Rules.nodes.masterwork_barding.duration == 7200,
			"Mounted health reference drifted"
		)
	end)
	check("project payment is once only and only selected active elapsed time completes it", function()
		local state = { coins = 20000, militaryResearch = Rules.new() }
		assert(Research.start(state, "army_training").ok and state.coins == 19000, "Research payment wrong")
		assert(not Research.start(state, "army_training").ok and state.coins == 19000, "Busy project charged again")
		assert(
			not Research.step(state, 10000, false).changed and state.militaryResearch.project.remaining == 30,
			"Inactive research advanced"
		)
		assert(
			Research.step(state, 29.5, true).changed and state.militaryResearch.project.remaining == 0.5,
			"Active duration lost"
		)
		assert(not state.militaryResearch.completed.army_training, "Research completed early")
		local result = Research.step(state, 0.5, true)
		assert(
			result.completed == "army_training" and state.militaryResearch.project == nil,
			"Exact project completion missing"
		)
		assert(not Research.start(state, "army_training").ok and state.coins == 19000, "Completed project repurchased")
	end)
	check("invalid prerequisites values and unaffordable projects leave state untouched", function()
		local state = { coins = 20000, militaryResearch = Rules.new() }
		for _, id in { "officer_training", "future_mech", "mounted_drills" } do
			assert(
				not Research.start(state, id).ok and state.coins == 20000 and state.militaryResearch.project == nil,
				"Invalid project mutated economy"
			)
		end
		state.coins = 999
		assert(not Research.start(state, "army_training").ok and state.coins == 999, "Unaffordable project charged")
		state.coins = 1000
		Research.start(state, "army_training")
		for _, elapsed in { -1, 0, math.huge, 0 / 0, "30" } do
			assert(
				not Research.step(state, elapsed, true).changed and state.militaryResearch.project.remaining == 30,
				"Malformed elapsed advanced research"
			)
		end
	end)
	check("strict progress rejects unknown fields broken ancestry and malformed projects", function()
		assert(Rules.validate(Rules.new()), "Fresh military progress invalid")
		for _, value in
			{
				{ completed = { officer_training = true } },
				{ completed = { army_training = false } },
				{ completed = { unknown = true } },
				{ completed = {}, unexpected = true },
				{ completed = {}, project = { id = "army_training", remaining = 31 } },
				{ completed = {}, project = { id = "army_training", remaining = 0 } },
				{ completed = {}, project = { id = "army_training", remaining = math.huge } },
				{ completed = {}, project = { id = "officer_training", remaining = 30 } },
				{ completed = { army_training = true }, project = { id = "army_training", remaining = 1 } },
			}
		do
			assert(not Rules.validate(value), "Malformed military progress accepted")
		end
	end)
	check(
		"completed effects add within one role family and lift weighted capacity independently from group count",
		function()
			local completed = {}
			for _, id in Rules.order do
				completed[id] = true
			end
			assert(Rules.validateCompleted(completed), "Complete catalog violates own graph")
			local modifiers = Rules.modifiers(completed)
			assert(
				math.abs(modifiers.foot.damage - 0.4) < 0.0001 and math.abs(modifiers.mounted.damage - 0.4) < 0.0001,
				"Damage bonuses multiplied or lost"
			)
			assert(
				math.abs(modifiers.foot.speed - 0.35) < 0.0001 and math.abs(modifiers.mounted.speed - 0.3) < 0.0001,
				"Speed families doubled"
			)
			assert(
				math.abs(modifiers.foot.range - 0.35) < 0.0001 and math.abs(modifiers.mounted.range - 0.3) < 0.0001,
				"Reach families doubled"
			)
			assert(
				Rules.capacity(completed) == 20 and Rules.groupSlots(completed) == 4,
				"Army size and group count confused"
			)
			assert(
				Rules.capacity({ army_training = true, army_size_1 = true }) == 12
					and Rules.groupSlots({ army_training = true }) == 1,
				"First capacity tier wrong"
			)
		end
	)
	return count
end
return run

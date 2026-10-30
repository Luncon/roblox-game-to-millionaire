--!strict
-- Reference row numbers retain the user's guide; names/effects fit this game.
local BattleConfig = require(script.Parent.BattleConfig)
local Military = {}
export type Scope = "foot" | "mounted" | "army"
export type Stat = "damage" | "health" | "speed" | "range" | "capacity" | "armySlots"
export type Effect = { scope: Scope, stat: Stat, value: number }
export type Node = {
	id: string,
	referenceRow: number,
	name: string,
	price: number,
	duration: number,
	predecessor: string?,
	branch: string,
	effect: Effect,
	x: number,
	y: number,
}
export type Completed = { [string]: boolean }
export type Progress = { completed: Completed, project: { id: string, remaining: number }? }
export type Bonuses = { damage: number, health: number, speed: number, range: number }
local nodes: { [string]: Node } = {}
local order: { string } = {}
local function add(
	id: string,
	row: number,
	name: string,
	price: number,
	duration: number,
	predecessor: string?,
	branch: string,
	scope: Scope,
	stat: Stat,
	value: number,
	x: number,
	y: number
)
	nodes[id] = table.freeze({
		id = id,
		referenceRow = row,
		name = name,
		price = price,
		duration = duration,
		predecessor = predecessor,
		branch = branch,
		effect = table.freeze({ scope = scope, stat = stat, value = value }),
		x = x,
		y = y,
	})
	table.insert(order, id)
end
add("army_training", 1, "Army Training", 1000, 30, nil, "Foot Damage", "foot", "damage", 0.05, 0, 0)
add("officer_training", 2, "Officer Training", 25000, 60, "army_training", "Foot Damage", "foot", "damage", 0.1, 2, 0)
add(
	"elite_training",
	3,
	"Elite Training",
	2500000,
	1800,
	"officer_training",
	"Foot Damage",
	"foot",
	"damage",
	0.25,
	4,
	0
)
add("army_control", 7, "Army Control", 5000, 60, "officer_training", "Army Control", "army", "armySlots", 1, 2, -2)
add("army_slot_2", 8, "Additional Army I", 25000, 60, "army_control", "Army Control", "army", "armySlots", 1, 4, -2)
add("army_slot_3", 9, "Additional Army II", 250000, 60, "army_slot_2", "Army Control", "army", "armySlots", 1, 6, -2)
add("army_size_1", 10, "Army Size I", 50000, 300, "army_training", "Army Capacity", "army", "capacity", 2, 0, -2)
add("army_size_2", 11, "Army Size II", 5000000, 1800, "army_size_1", "Army Capacity", "army", "capacity", 3, 0, -4)
add("army_size_3", 12, "Army Size III", 100000000, 43200, "army_size_2", "Army Capacity", "army", "capacity", 5, 0, -6)
add("scout_training", 15, "Scout Training", 100000, 600, "army_size_1", "Foot Reach", "foot", "range", 0.05, -2, -2)
add("night_scouts", 16, "Night Scouts", 250000, 1800, "scout_training", "Foot Reach", "foot", "range", 0.1, -4, -2)
add("signal_beacons", 17, "Signal Beacons", 1000000, 3600, "night_scouts", "Foot Reach", "foot", "range", 0.2, -6, -2)
add(
	"mounted_drills",
	18,
	"Mounted Drills",
	100000,
	300,
	"officer_training",
	"Mounted Damage",
	"mounted",
	"damage",
	0.05,
	2,
	4
)
add(
	"mounted_weapons",
	19,
	"Mounted Weapons",
	10000000,
	1800,
	"mounted_drills",
	"Mounted Damage",
	"mounted",
	"damage",
	0.1,
	4,
	4
)
add(
	"elite_rider_training",
	20,
	"Elite Rider Training",
	250000000,
	14400,
	"mounted_weapons",
	"Mounted Damage",
	"mounted",
	"damage",
	0.25,
	6,
	4
)
add(
	"rider_conditioning",
	21,
	"Rider Conditioning",
	250000,
	900,
	"mounted_drills",
	"Mounted Speed",
	"mounted",
	"speed",
	0.05,
	2,
	6
)
add(
	"forage_logistics",
	22,
	"Forage Logistics",
	1000000,
	1800,
	"rider_conditioning",
	"Mounted Speed",
	"mounted",
	"speed",
	0.1,
	4,
	6
)
add(
	"swift_mounts",
	23,
	"Swift Mounts",
	10000000,
	9000,
	"forage_logistics",
	"Mounted Speed",
	"mounted",
	"speed",
	0.15,
	6,
	6
)
add("field_bandages", 26, "Field Bandages", 10000, 60, "army_training", "Foot Health", "foot", "health", 0.05, -2, 0)
add("field_medicine", 27, "Field Medicine", 250000, 1800, "field_bandages", "Foot Health", "foot", "health", 0.1, -4, 0)
add(
	"veteran_resilience",
	28,
	"Veteran Resilience",
	100000000,
	7200,
	"field_medicine",
	"Foot Health",
	"foot",
	"health",
	0.25,
	-6,
	0
)
add(
	"marching_sandals",
	29,
	"Marching Sandals",
	50000,
	300,
	"officer_training",
	"Foot Speed",
	"foot",
	"speed",
	0.05,
	2,
	2
)
add(
	"campaign_rations",
	30,
	"Campaign Rations",
	250000,
	1800,
	"marching_sandals",
	"Foot Speed",
	"foot",
	"speed",
	0.1,
	4,
	2
)
add("forced_march", 31, "Forced March", 50000000, 3600, "campaign_rations", "Foot Speed", "foot", "speed", 0.2, 6, 2)
add(
	"mounted_armor",
	32,
	"Mounted Armor",
	250000,
	600,
	"mounted_drills",
	"Mounted Health",
	"mounted",
	"health",
	0.05,
	0,
	4
)
add(
	"reinforced_barding",
	33,
	"Reinforced Barding",
	1000000,
	1800,
	"mounted_armor",
	"Mounted Health",
	"mounted",
	"health",
	0.1,
	-2,
	4
)
add(
	"masterwork_barding",
	34,
	"Masterwork Barding",
	500000000,
	7200,
	"reinforced_barding",
	"Mounted Health",
	"mounted",
	"health",
	0.25,
	-4,
	4
)
add(
	"rider_scouts",
	35,
	"Rider Scouts",
	1000000,
	1800,
	"rider_conditioning",
	"Mounted Reach",
	"mounted",
	"range",
	0.1,
	0,
	6
)
add(
	"rider_signals",
	36,
	"Rider Signals",
	25000000,
	3600,
	"rider_scouts",
	"Mounted Reach",
	"mounted",
	"range",
	0.2,
	-2,
	6
)
Military.nodes, Military.order = table.freeze(nodes), table.freeze(order)

function Military.new(): Progress
	return { completed = {} }
end
function Military.validateCompleted(completed): boolean
	if type(completed) ~= "table" then
		return false
	end
	for id, value in completed do
		local definition = nodes[id]
		if
			not definition
			or value ~= true
			or (definition.predecessor and completed[definition.predecessor] ~= true)
		then
			return false
		end
	end
	return true
end
function Military.validate(progress): boolean
	if type(progress) ~= "table" or not Military.validateCompleted(progress.completed) then
		return false
	end
	for key in progress do
		if key ~= "completed" and key ~= "project" then
			return false
		end
	end
	local project = progress.project
	if project == nil then
		return true
	end
	if type(project) ~= "table" then
		return false
	end
	for key in project do
		if key ~= "id" and key ~= "remaining" then
			return false
		end
	end
	local definition = if type(project.id) == "string" then nodes[project.id] else nil
	return definition ~= nil
		and not progress.completed[project.id]
		and (not definition.predecessor or progress.completed[definition.predecessor] == true)
		and type(project.remaining) == "number"
		and project.remaining > 0
		and project.remaining <= definition.duration
end
function Military.modifiers(completed: Completed): { foot: Bonuses, mounted: Bonuses }
	local bonuses = {
		foot = { damage = 0, health = 0, speed = 0, range = 0 },
		mounted = {
			damage = 0,
			health = 0,
			speed = 0,
			range = 0,
		},
	}
	for _, id in order do
		local effect = nodes[id].effect
		if completed[id] and effect.scope ~= "army" then
			bonuses[effect.scope][effect.stat] += effect.value
		end
	end
	return bonuses
end
function Military.capacity(completed: Completed): number
	local capacity = 10
	for _, id in { "army_size_1", "army_size_2", "army_size_3" } do
		if completed[id] then
			capacity += nodes[id].effect.value
		end
	end
	return capacity
end
function Military.groupSlots(completed: Completed): number
	local slots = 1
	for _, id in { "army_control", "army_slot_2", "army_slot_3" } do
		if completed[id] then
			slots += 1
		end
	end
	return slots
end
function Military.profile(role: string, civilizationId: string, completed: Completed): BattleConfig.RoleStats
	local base = BattleConfig.getProfile(role, civilizationId)
	if next(completed) == nil then
		return base
	end
	local bonus = Military.modifiers(completed)[if role == "mounted" then "mounted" else "foot"]
	local result = table.clone(base)
	result.health *= 1 + bonus.health
	result.damage *= 1 + bonus.damage
	result.speed *= 1 + bonus.speed
	result.reach *= 1 + bonus.range
	if role == "medic" then
		result.healRange *= 1 + bonus.range
	end
	return table.freeze(result)
end
return table.freeze(Military)

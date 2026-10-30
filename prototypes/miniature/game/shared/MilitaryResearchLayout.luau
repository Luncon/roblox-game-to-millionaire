--!strict
-- Presentation only. Research requirements and saved IDs remain in MilitaryResearch.
local Layout = {}
export type Cell = { q: number, r: number }
export type Point = { x: number, y: number }
export type Bounds = {
	minX: number,
	minY: number,
	maxX: number,
	maxY: number,
	width: number,
	height: number,
	offsetX: number,
	offsetY: number,
}
Layout.id = "honeycomb-v1"
Layout.height = 96
Layout.width = math.sqrt(3) / 2 * Layout.height
Layout.rowStep = Layout.height * 0.75

local nodes: { [string]: Cell } = {}
local order: { string } = {}
local function node(id: string, q: number, r: number)
	nodes[id] = table.freeze({ q = q, r = r })
	table.insert(order, id)
end
-- Three immediate left faces start capacity, training and health trunks.
node("army_training", 0, 0)
node("officer_training", -1, 0)
node("elite_training", -2, 0)
node("army_control", -2, 1)
node("army_slot_2", -3, 1)
node("army_slot_3", -4, 1)
node("army_size_1", 0, -1)
node("army_size_2", 0, -2)
node("army_size_3", 0, -3)
node("scout_training", -1, -1)
node("night_scouts", -2, -1)
node("signal_beacons", -3, -1)
node("mounted_drills", -3, 0)
node("mounted_weapons", -4, 0)
node("elite_rider_training", -5, 0)
node("rider_conditioning", -5, 1)
node("forage_logistics", -6, 1)
node("swift_mounts", -7, 1)
node("field_bandages", -1, 1)
node("field_medicine", -2, 2)
node("veteran_resilience", -3, 3)
node("marching_sandals", -2, -2)
node("campaign_rations", -3, -2)
node("forced_march", -4, -2)
node("mounted_armor", -4, -1)
node("reinforced_barding", -5, -1)
node("masterwork_barding", -6, -1)
node("rider_scouts", -5, -2)
node("rider_signals", -6, -2)
Layout.nodes = table.freeze(nodes)
Layout.order = table.freeze(order)

local function frozenCells(coordinates: { { number } }): { Cell }
	local result: { Cell } = {}
	for _, pair in coordinates do
		table.insert(result, table.freeze({ q = pair[1], r = pair[2] }))
	end
	return table.freeze(result)
end
Layout.reservedMilitary = frozenCells({ { -6, 0 }, { -7, 0 }, { -8, 0 }, { -1, -3 }, { -2, -3 }, { -8, 1 }, { -8, 2 } })
Layout.civilian = frozenCells({
	{ 1, -1 },
	{ 1, 0 },
	{ 0, 1 },
	{ 2, -2 },
	{ 2, -1 },
	{ 2, 0 },
	{ 1, 1 },
	{ 0, 2 },
	{ 3, -2 },
	{ 1, 2 },
})

function Layout.point(q: number, r: number): Point
	return { x = Layout.width * (q + r / 2), y = Layout.rowStep * r }
end

function Layout.adjacent(first: Cell, second: Cell): boolean
	local dq, dr = first.q - second.q, first.r - second.r
	return math.abs(dq) + math.abs(dr) + math.abs(dq + dr) == 2
end

-- Coordinates inside a tile's width-by-height box, clockwise from its top tip.
function Layout.vertices(): { Point }
	local width, height = Layout.width, Layout.height
	return {
		{ x = width / 2, y = 0 },
		{ x = width, y = height / 4 },
		{ x = width, y = height * 3 / 4 },
		{ x = width / 2, y = height },
		{ x = 0, y = height * 3 / 4 },
		{ x = 0, y = height / 4 },
	}
end

function Layout.bounds(padding: number?): Bounds
	local margin = if padding == nil then 32 else padding
	assert(margin >= 0 and margin < math.huge, "Finite nonnegative layout padding required")
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	local function include(cell: Cell)
		local point = Layout.point(cell.q, cell.r)
		minX, maxX = math.min(minX, point.x - Layout.width / 2), math.max(maxX, point.x + Layout.width / 2)
		minY, maxY = math.min(minY, point.y - Layout.height / 2), math.max(maxY, point.y + Layout.height / 2)
	end
	for _, cell in Layout.nodes do
		include(cell)
	end
	for _, group in { Layout.reservedMilitary, Layout.civilian } do
		for _, cell in group do
			include(cell)
		end
	end
	return {
		minX = minX,
		minY = minY,
		maxX = maxX,
		maxY = maxY,
		width = maxX - minX + margin * 2,
		height = maxY - minY + margin * 2,
		offsetX = margin - minX,
		offsetY = margin - minY,
	}
end

return table.freeze(Layout)

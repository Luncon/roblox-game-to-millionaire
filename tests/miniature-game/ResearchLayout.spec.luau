--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Military = require(Shared.MilitaryResearch)
local Layout = require(Shared.MilitaryResearchLayout)
local EPSILON = 0.0000001

local function near(a: number, b: number): boolean
	return math.abs(a - b) < EPSILON
end

local function cells()
	local result = {}
	for _, id in Layout.order do
		table.insert(result, Layout.nodes[id])
	end
	for _, group in { Layout.reservedMilitary, Layout.civilian } do
		for _, cell in group do
			table.insert(result, cell)
		end
	end
	return result
end

local function polygon(cell)
	local center = Layout.point(cell.q, cell.r)
	local result = {}
	for _, corner in Layout.vertices() do
		table.insert(
			result,
			{ x = center.x + corner.x - Layout.width / 2, y = center.y + corner.y - Layout.height / 2 }
		)
	end
	return result
end

local function separated(first, second): boolean
	for index, point in first do
		local nextPoint = first[index % #first + 1]
		local nx, ny = -(nextPoint.y - point.y), nextPoint.x - point.x
		local minA, maxA, minB, maxB = math.huge, -math.huge, math.huge, -math.huge
		for _, vertex in first do
			local projection = vertex.x * nx + vertex.y * ny
			minA, maxA = math.min(minA, projection), math.max(maxA, projection)
		end
		for _, vertex in second do
			local projection = vertex.x * nx + vertex.y * ny
			minB, maxB = math.min(minB, projection), math.max(maxB, projection)
		end
		if maxA <= minB + EPSILON or maxB <= minA + EPSILON then
			return true
		end
	end
	return false
end

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS research honeycomb: " .. name)
	end
	check("every existing research ID has one cell and all seventeen future cells stay separate", function()
		assert(#Layout.order == 29 and #Layout.order == #Military.order, "Functional research count changed")
		local occupied, militaryCount = {}, 0
		for _, cell in cells() do
			assert(cell.q % 1 == 0 and cell.r % 1 == 0, "Noninteger axial cell")
			local key = cell.q .. ":" .. cell.r
			assert(not occupied[key], "Two research tiles share a cell")
			occupied[key] = true
		end
		for index, id in Layout.order do
			assert(id == Military.order[index] and Layout.nodes[id], "Catalog order or ID changed")
		end
		for id in Layout.nodes do
			assert(Military.nodes[id], "Invented functional research")
			militaryCount += 1
		end
		assert(
			militaryCount == 29 and #Layout.reservedMilitary == 7 and #Layout.civilian == 10,
			"Reserved count changed"
		)
	end)
	check("Army Training has exactly three left military neighbors and civilians occupy the right", function()
		local root = Layout.nodes.army_training
		assert(root.q == 0 and root.r == 0, "Root moved")
		local expected = { army_size_1 = true, officer_training = true, field_bandages = true }
		local neighbors = 0
		for id, cell in Layout.nodes do
			local point = Layout.point(cell.q, cell.r)
			if id ~= "army_training" then
				assert(point.x < 0, "Functional military tile escaped left half")
			end
			if Layout.adjacent(root, cell) then
				assert(expected[id], "Unexpected military root neighbor")
				neighbors += 1
			end
		end
		assert(neighbors == 3, "Missing one of the three left trunks")
		for _, cell in Layout.reservedMilitary do
			assert(Layout.point(cell.q, cell.r).x < 0, "Military future tile escaped left half")
		end
		for _, cell in Layout.civilian do
			assert(Layout.point(cell.q, cell.r).x > 0, "Civilian future tile escaped right half")
		end
		assert(Layout.nodes.army_size_1.q == 0 and Layout.nodes.army_size_1.r == -1, "Northwest trunk changed")
		assert(Layout.nodes.officer_training.q == -1 and Layout.nodes.officer_training.r == 0, "West trunk changed")
		assert(Layout.nodes.field_bandages.q == -1 and Layout.nodes.field_bandages.r == 1, "Southwest trunk changed")
	end)
	check("all functional tiles and each tier family form an edge-connected cluster", function()
		local seen, queue, cursor = { army_training = true }, { "army_training" }, 1
		while queue[cursor] do
			local first = Layout.nodes[queue[cursor]]
			cursor += 1
			for id, cell in Layout.nodes do
				if not seen[id] and Layout.adjacent(first, cell) then
					seen[id] = true
					table.insert(queue, id)
				end
			end
		end
		assert(#queue == 29, "Functional military island is disconnected")
		for id, entry in Military.nodes do
			local prior = entry.predecessor and Military.nodes[entry.predecessor]
			if prior and prior.branch == entry.branch then
				assert(Layout.adjacent(Layout.nodes[id], Layout.nodes[prior.id]), "Tier family does not share edges")
			end
		end
	end)
	check("regular pointy-top vertices join exact full edges without overlapping interiors", function()
		assert(near(Layout.width, math.sqrt(3) * Layout.height / 2), "Hex aspect ratio is not regular")
		assert(near(Layout.rowStep, Layout.height * 0.75), "Axial row spacing changed")
		local vertices = Layout.vertices()
		assert(
			#vertices == 6 and near(vertices[1].x, Layout.width / 2) and near(vertices[1].y, 0),
			"Hex is not pointy-top"
		)
		for index, first in vertices do
			local second = vertices[index % 6 + 1]
			assert(
				near(math.sqrt((first.x - second.x) ^ 2 + (first.y - second.y) ^ 2), Layout.height / 2),
				"Unequal hex edge"
			)
		end
		local all = cells()
		local edges = 0
		for index, first in all do
			local a = polygon(first)
			for otherIndex = index + 1, #all do
				local second = all[otherIndex]
				local b = polygon(second)
				assert(separated(a, b), "Hex interiors overlap")
				if Layout.adjacent(first, second) then
					local common = 0
					for _, left in a do
						for _, right in b do
							if near(left.x, right.x) and near(left.y, right.y) then
								common += 1
								break
							end
						end
					end
					assert(common == 2, "Adjacent hexagons do not share an exact full edge")
					edges += 1
				end
			end
		end
		assert(edges > 45, "Layout lacks a joined honeycomb")
	end)
	check("canvas bounds include every complete hex and padding remains zoom independent", function()
		local bounds, padded = Layout.bounds(0), Layout.bounds(32)
		assert(
			near(padded.width, bounds.width + 64) and near(padded.height, bounds.height + 64),
			"Padding changed geometry"
		)
		for _, cell in cells() do
			for _, point in polygon(cell) do
				assert(point.x >= bounds.minX - EPSILON and point.x <= bounds.maxX + EPSILON, "Horizontal hex clipping")
				assert(point.y >= bounds.minY - EPSILON and point.y <= bounds.maxY + EPSILON, "Vertical hex clipping")
				assert(
					point.x + padded.offsetX >= 32 - EPSILON and point.x + padded.offsetX <= padded.width - 32 + EPSILON,
					"Horizontal padding clipped"
				)
				assert(
					point.y + padded.offsetY >= 32 - EPSILON
						and point.y + padded.offsetY <= padded.height - 32 + EPSILON,
					"Vertical padding clipped"
				)
			end
		end
		assert(not Layout.adjacent({ q = 0, r = 0 }, { q = 0, r = 0 }), "Cell touches itself")
		assert(not Layout.adjacent({ q = 0, r = 0 }, { q = 1, r = 1 }), "Nonneighbor treated as edge neighbor")
	end)
	check("future cells remain inert and callers cannot change the shared layout", function()
		for _, group in { Layout.reservedMilitary, Layout.civilian } do
			for _, cell in group do
				for key in cell do
					assert(key == "q" or key == "r", "Placeholder gained functional research metadata")
				end
			end
		end
		assert(not pcall(function()
			Layout.nodes.army_training.q = 100
		end), "Shared node coordinates are mutable")
		assert(not pcall(function()
			Layout.civilian[1].q = -100
		end), "Shared placeholder coordinates are mutable")
		local point, vertices, bounds = Layout.point(0, 0), Layout.vertices(), Layout.bounds()
		point.x, vertices[1].y, bounds.width = 5000, 5000, 0
		assert(
			Layout.point(0, 0).x == 0 and Layout.vertices()[1].y == 0 and Layout.bounds().width > 0,
			"Caller changed shared geometry"
		)
		for _, margin in { -1, math.huge, 0 / 0 } do
			assert(not pcall(Layout.bounds, margin), "Invalid canvas padding accepted")
		end
	end)
	return count
end

return run

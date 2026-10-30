--!strict
local Scenery = require(game:GetService("ServerScriptService").Sandbox.OutpostScenery)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature outpost scenery: " .. name)
	end
	check("all eight outposts have bounded developed quarter-scale inert scenery and clear approaches", function()
		for index = 1, 8 do
			local plan = Scenery.plan(index)
			assert(#plan >= 90 and #plan < 140, "Scenery is empty or exceeds the per-outpost part budget")
			local categories = {}
			for _, piece in plan do
				categories[piece.category] = (categories[piece.category] or 0) + 1
				assert(
					piece.anchored and not piece.canCollide and not piece.canTouch and not piece.canQuery,
					"Scenery descriptor can affect combat or grounding"
				)
				local frame = CFrame.new(piece.x, piece.y, piece.z) * CFrame.Angles(piece.rx, piece.ry, piece.rz)
				local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
				for _, x in { -1, 1 } do
					for _, y in { -1, 1 } do
						for _, z in { -1, 1 } do
							local point = frame:PointToWorldSpace(
								Vector3.new(x * piece.sx, y * piece.sy, z * piece.sz) / 2
							) * Scenery.scale
							assert(point.Y >= -0.001, "Scenery sinks below its reference plane")
							assert(
								math.sqrt(point.X ^ 2 + point.Z ^ 2) <= Scenery.captureRadius + 0.001,
								"Scenery exceeds the unchanged capture footprint"
							)
							minX, maxX, minZ, maxZ =
								math.min(minX, point.X),
								math.max(maxX, point.X),
								math.min(minZ, point.Z),
								math.max(maxZ, point.Z)
						end
					end
				end
				local xGap = if minX <= 0 and maxX >= 0 then 0 else math.min(math.abs(minX), math.abs(maxX))
				local zGap = if minZ <= 0 and maxZ >= 0 then 0 else math.min(math.abs(minZ), math.abs(maxZ))
				assert(
					xGap >= Scenery.corridorHalfWidth and zGap >= Scenery.corridorHalfWidth,
					"Scenery blocks a cardinal approach corridor"
				)
				assert(math.sqrt(xGap ^ 2 + zGap ^ 2) > Scenery.captureClearRadius, "Capture center is obstructed")
			end
			assert(
				(categories.Wall or 0) >= 24
					and (categories.Watchpost or 0) >= 16
					and (categories.GuardHut or 0) >= 18
					and (categories.Stores or 0) >= 12,
				"Outpost lacks walls watchposts guard huts or supplies"
			)
		end
	end)
	check("outpost scenery plans are deterministic and independent copies", function()
		local first, second = Scenery.plan(3), Scenery.plan(3)
		assert(#first == #second, "Scenery part counts vary nondeterministically")
		for index, piece in first do
			local other = second[index]
			for key, value in piece do
				assert(other[key] == value, "Scenery generation changed without input changes")
			end
		end
		first[1].x = 100000
		assert(Scenery.plan(3)[1].x ~= 100000, "Mutated scenery plan leaked into future outposts")
	end)
	check("watchpost roofs have continuous post support and ladders have connected rungs", function()
		local plan = Scenery.plan(1)
		local legs, roofs, rails, rungs = {}, {}, {}, {}
		for _, piece in plan do
			if piece.name == "WatchLeg" then
				table.insert(legs, piece)
			elseif piece.name == "WatchRoof" then
				table.insert(roofs, piece)
			elseif piece.name == "LadderRail" then
				table.insert(rails, piece)
			elseif piece.name == "LadderRung" then
				table.insert(rungs, piece)
			end
		end
		local function contains(piece, point)
			local frame = CFrame.new(piece.x, piece.y, piece.z) * CFrame.Angles(piece.rx, piece.ry, piece.rz)
			local localPoint = frame:PointToObjectSpace(point)
			return math.abs(localPoint.X) <= piece.sx / 2 + 0.001
				and math.abs(localPoint.Y) <= piece.sy / 2 + 0.001
				and math.abs(localPoint.Z) <= piece.sz / 2 + 0.001
		end
		for _, leg in legs do
			local supported = false
			for _, roof in roofs do
				if contains(roof, Vector3.new(leg.x, leg.y + leg.sy / 2, leg.z)) then
					supported = true
					break
				end
			end
			assert(supported and math.abs(leg.y - leg.sy / 2) < 0.001, "Watch roof floats above its supporting post")
		end
		assert(#legs == 8 and #rungs == 8, "Both watchpost ladders need four usable rungs")
		for _, rung in rungs do
			for _, side in { -1, 1 } do
				local connected = false
				for _, rail in rails do
					if contains(rail, Vector3.new(rung.x + side * rung.sx / 2, rung.y, rung.z)) then
						connected = true
						break
					end
				end
				assert(connected, "Ladder rung does not meet a supporting rail")
			end
		end
	end)
	return count
end

return run

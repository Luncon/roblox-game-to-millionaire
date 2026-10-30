--!strict
local Config = require(script.Parent.Config)
local Catalog = require(script.Parent.Catalog)
local Placement = {}

local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Placement.bounds(building)
	local definition = Catalog.buildings[building.kind]
	local quarterTurn = building.rotation == 90 or building.rotation == 270
	return if quarterTurn then definition.depth else definition.width,
		if quarterTurn then definition.width else definition.depth
end

function Placement.validate(buildings, kind, x, z, rotation, ignoreId): (boolean, string?)
	if
		not Catalog.buildings[kind]
		or not finite(x)
		or not finite(z)
		or x % Config.grid ~= 0
		or z % Config.grid ~= 0
		or (rotation ~= 0 and rotation ~= 90 and rotation ~= 180 and rotation ~= 270)
	then
		return false, "invalid_placement"
	end
	local width, depth = Placement.bounds({ kind = kind, rotation = rotation })
	if math.abs(x) + width / 2 > Config.plotWidth / 2 or math.abs(z) + depth / 2 > Config.plotDepth / 2 then
		return false, "outside_plot"
	end
	if math.abs(x) < width / 2 + 2 or math.abs(z) < depth / 2 + 2 then
		return false, "reserved_lane"
	end
	for _, existing in buildings do
		if existing.id ~= ignoreId then
			local otherWidth, otherDepth = Placement.bounds(existing)
			if
				math.abs(x - existing.x) < (width + otherWidth) / 2
				and math.abs(z - existing.z) < (depth + otherDepth) / 2
			then
				return false, "overlap"
			end
		end
	end
	return true, nil
end

return Placement

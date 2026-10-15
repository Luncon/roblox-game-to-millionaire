--!strict

local Config = require(script.Parent.ProgressionConfig)
local levels = {}
for level = 1, Config.maxLevel do
	local phase = if level < 10 then "Outpost" elseif level < 20 then "Village"
		elseif level < 30 then "Town" elseif level < 40 then "City"
		elseif level < Config.maxLevel then "Capital" else "Grand Settlement"
	levels[level] = table.freeze({
		name = phase .. " " .. level,
		size = Config.initialSize + Config.sizeIncrement * (level - 1),
		nextCost = if level < Config.maxLevel then Config.settlementInitialCost + Config.settlementCostIncrement * (level - 1) else nil,
	})
end
return table.freeze(levels)

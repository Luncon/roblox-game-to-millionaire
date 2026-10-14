--!strict

local levels = {
	{ name = "Outpost", size = 60, nextCost = 25 },
	{ name = "Village", size = 68, nextCost = 75 },
	{ name = "Town", size = 76, nextCost = 150 },
	{ name = "Citadel", size = 84 },
}
for _, level in levels do table.freeze(level) end
return table.freeze(levels)

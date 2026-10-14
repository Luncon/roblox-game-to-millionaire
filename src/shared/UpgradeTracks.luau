--!strict

local tracks = {
	settlement = require(script.Parent.SettlementProgression),
	weapon = {
		{name="Recruit", nextCost=15, requiredSettlement=2, damage=10},
		{name="Veteran", nextCost=50, requiredSettlement=3, damage=14},
		{name="Elite", nextCost=125, requiredSettlement=4, damage=19},
		{name="Champion", damage=25},
	},
	armor = {
		{name="Recruit", nextCost=15, requiredSettlement=2, health=100},
		{name="Veteran", nextCost=50, requiredSettlement=3, health=115},
		{name="Elite", nextCost=125, requiredSettlement=4, health=135},
		{name="Champion", health=170},
	},
	barracks = {
		{name="I", nextCost=30, requiredSettlement=2, respawnDelay=15, capacity=1},
		{name="II", nextCost=75, requiredSettlement=3, respawnDelay=14.5, capacity=1},
		{name="III", nextCost=150, requiredSettlement=4, respawnDelay=14, capacity=1},
		{name="IV", respawnDelay=13.5, capacity=2},
	},
}
for _, key in {"weapon", "armor", "barracks"} do
	for _, level in tracks[key] do table.freeze(level) end
	table.freeze(tracks[key])
end
return table.freeze(tracks)

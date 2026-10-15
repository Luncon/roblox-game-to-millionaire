--!strict

local Config = require(script.Parent.ProgressionConfig)
local weapon, armor = {}, {}
for level = 1, Config.maxLevel do
	local fraction = (level - 1) / (Config.maxLevel - 1)
	local nextCost = if level < Config.maxLevel then Config.gearInitialCost + Config.gearCostIncrement * (level - 1) else nil
	local required = if level < Config.maxLevel then level + 1 else nil
	weapon[level] = {name="Tier "..level, nextCost=nextCost, requiredSettlement=required,
		damage=Config.weaponMin+(Config.weaponMax-Config.weaponMin)*fraction}
	armor[level] = {name="Tier "..level, nextCost=nextCost, requiredSettlement=required,
		health=Config.armorMin+(Config.armorMax-Config.armorMin)*fraction}
end
local tracks = {
	settlement = require(script.Parent.SettlementProgression),
	weapon = weapon,
	armor = armor,
	barracks = {
		{name="I", nextCost=30, requiredSettlement=2, respawnDelay=15, capacity=1},
		{name="II", nextCost=75, requiredSettlement=3, respawnDelay=14.5, capacity=1},
		{name="III", nextCost=150, requiredSettlement=4, respawnDelay=14, capacity=1},
		{name="IV", nextCost=200, requiredSettlement=8, respawnDelay=13.5, capacity=2},
		{name="V", nextCost=300, requiredSettlement=14, respawnDelay=13, capacity=2},
		{name="VI", respawnDelay=12.5, capacity=2},
	},
}
for _, key in {"weapon", "armor", "barracks"} do
	for _, level in tracks[key] do table.freeze(level) end
	table.freeze(tracks[key])
end
return table.freeze(tracks)

--!strict

-- Raising the cap also requires room in the world and a reviewed combat curve.
return table.freeze({
	coinsPerClick = 50,
	maxLevel = 50,
	initialSize = 60,
	sizeIncrement = 4,
	weaponMin = 10,
	weaponMax = 18,
	armorMin = 100,
	armorMax = 140,
	settlementInitialCost = 25,
	settlementCostIncrement = 10,
	gearInitialCost = 15,
	gearCostIncrement = 3,
})

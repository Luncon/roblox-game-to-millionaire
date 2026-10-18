--!strict

-- Local plot coordinates shared by buildings, controls and terrain reservations.
local Camp = require(script.Parent.TrainingCampConfig)
local Sites = {
	warCouncil = Vector3.new(-148,0,42),
	warCouncilPad = Vector3.new(-148,-.3,26),
	formationPad = Vector3.new(-136,-.3,26),
	shieldPad = Vector3.new(42,2,18),
	hospital = Vector3.new(0,0,146),
	hospitalPad = Vector3.new(24,-.3,140),
	hospitalSpawn = Vector3.new(0,2.15,132),
	hospitalHalfSize = Vector3.new(14,0,12),
	hospitalAccessStart = 56,
	hospitalAccessHalfWidth = 4,
	armory = Vector3.new(24,0,9),
	training = Camp.center,
	armyCamp = Vector3.new(-24,0,25),
	workers = Vector3.new(60,0,-144),
	blacksmith = Vector3.new(-42,0,34),
	armorer = Vector3.new(42,0,34),
	storehouse = Vector3.new(0,0,45),
	fields = {Vector3.new(-60,0,-172),Vector3.new(60,0,-172)},
	fieldSize = Vector3.new(56,.3,40),
}
table.freeze(Sites.fields)
return table.freeze(Sites)

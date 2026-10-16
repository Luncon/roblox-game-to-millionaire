--!strict

-- Local plot coordinates shared by buildings, controls and terrain reservations.
local Camp = require(script.Parent.TrainingCampConfig)
local Sites = {
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

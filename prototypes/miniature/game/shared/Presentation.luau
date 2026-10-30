--!strict
-- Readable role names for the original kits. These do not change recipes or stats.
local Catalog = require(script.Parent.Catalog)
local MountConfig = require(script.Parent.MountConfig)
local Presentation = {}
local order = { "civic", "house", "farm", "timber", "material", "workshop", "storehouse", "training", "healer" }
local names = {
	sparta = {
		"Council Courtyard",
		"Laconian Courtyard House",
		"Grain Field",
		"Timber Yard",
		"Clay Working Area",
		"Potter's Shed",
		"Store Room",
		"Drill Court",
		"Healer Shelter",
	},
	rome = {
		"Civic Arcade",
		"Courtyard House",
		"Grain Field",
		"Timber Work Yard",
		"Clay Drying Yard",
		"Potter's Workshop",
		"Horreum",
		"Barracks Court",
		"Treatment Room",
	},
	persia = {
		"Terrace Council Hall",
		"Earth-Roof Courtyard House",
		"Grain Field",
		"Timber Shade Yard",
		"Clay Drying Court",
		"Ceramic Workshop",
		"Buttressed Store",
		"Spear and Bow Court",
		"Healer Courtyard",
	},
	egypt = {
		"Pylon Council Precinct",
		"Mudbrick Roof House",
		"Grain Plot",
		"Timber Supply Court",
		"Clay Working Court",
		"Potter's Court",
		"Granary Bins",
		"Drill Court",
		"Healer House",
	},
	maurya = {
		"Pillared Council Hall",
		"Timber and Earthen House",
		"Grain Field",
		"Timber Work Yard",
		"Clay Working Area",
		"Pottery Shed",
		"Store Compound",
		"Warrior Court",
		"Healer Shelter",
	},
	seneca = {
		"Council Longhouse",
		"Bark Longhouse",
		"Three Sisters Garden",
		"Woodland Work Yard",
		"Clay Working Area",
		"Pottery Work Shelter",
		"Food Store Shelter",
		"Warrior Practice Clearing",
		"Healer Shelter",
	},
	vikings = {
		"Council Longhall",
		"Household Longhall",
		"Grain Enclosure",
		"Wood Yard",
		"Clay Working Area",
		"Potter's Work Shed",
		"Store Shed",
		"Shield Practice Yard",
		"Healer Hut",
	},
	mongols = {
		"Council Ger",
		"Family Ger",
		"Grain Plot",
		"Timber Supply Yard",
		"Clay Working Area",
		"Settled Potter's Bay",
		"Supply Ger",
		"Warrior Practice Yard",
		"Treatment Ger",
	},
	japan = {
		"Council Keep",
		"Timber Town House",
		"Rice Plot",
		"Timber Craft Yard",
		"Clay Working Yard",
		"Potter's Tunnel Kiln",
		"Raised Store",
		"Training Compound",
		"Treatment House",
	},
	ming = {
		"Council Hall",
		"Skywell Courtyard House",
		"Rice Plot",
		"Timber Work Yard",
		"Clay Working Yard",
		"Ceramic Workshop",
		"Granary Hall",
		"Spear and Bow Yard",
		"Treatment Room",
	},
	ottomans = {
		"Arcaded Council",
		"Timber and Plaster House",
		"Grain Plot",
		"Timber Work Yard",
		"Clay Working Yard",
		"Ceramic Craft Bay",
		"Courtyard Store",
		"Infantry Practice Court",
		"Treatment Room",
	},
	spain = {
		"Civic Courtyard",
		"Patio House",
		"Grain Plot",
		"Timber Work Yard",
		"Clay Working Yard",
		"Ceramic Workshop",
		"Granary",
		"Pike Drill Yard",
		"Infirmary",
	},
	britain = {
		"Assembly House",
		"Worker Cottage",
		"Grain Field",
		"Timber Yard",
		"Clay Yard",
		"Potter's Workshop",
		"Warehouse",
		"Regimental Yard",
		"Infirmary",
	},
}
local roles = {
	sparta = { melee = "Hoplite", ranged = "Slinger", medic = "Healer" },
	rome = { melee = "Legionary", ranged = "Archer", medic = "Medical Attendant" },
	persia = { melee = "Spearman", ranged = "Archer", medic = "Healer" },
	egypt = { melee = "Axeman", ranged = "Archer", medic = "Healer" },
	maurya = { melee = "Spearman", ranged = "Archer", medic = "Medical Attendant" },
	seneca = { melee = "Club Warrior", ranged = "Archer", medic = "Healer" },
	vikings = { melee = "Axe Warrior", ranged = "Archer", medic = "Healer" },
	mongols = { melee = "Dismounted Warrior", ranged = "Archer", medic = "Healer" },
	japan = { melee = "Spear Infantry", ranged = "Archer", medic = "Medical Attendant" },
	ming = { melee = "Spearman", ranged = "Archer", medic = "Medical Attendant" },
	ottomans = { melee = "Infantry", ranged = "Archer", medic = "Medical Attendant" },
	spain = { melee = "Pikeman", ranged = "Missile Infantry", medic = "Medical Attendant" },
	britain = { melee = "Infantry", ranged = "Skirmisher", medic = "Medical Attendant" },
}
local buildings = {}
local rangedNames = {
	sparta = "Slinger Practice Court",
	rome = "Archer Practice Court",
	persia = "Archer Practice Court",
	egypt = "Archer Practice Court",
	maurya = "Archer Practice Yard",
	seneca = "Archery Clearing",
	vikings = "Archer Practice Yard",
	mongols = "Archery Practice Yard",
	japan = "Bow Practice Court",
	ming = "Bow Practice Court",
	ottomans = "Bow Practice Court",
	spain = "Crossbow Practice Yard",
	britain = "Musket Drill Yard",
}
for civilizationId, entries in names do
	local map = {}
	for index, kind in order do
		map[kind] = entries[index]
	end
	map.ranged = rangedNames[civilizationId]
	buildings[civilizationId] = table.freeze(map)
end
for _, entries in roles do
	table.freeze(entries)
end
table.freeze(buildings)
table.freeze(roles)

function Presentation.buildingName(civilizationId: string, kind: string): string
	if kind == "mount" then
		return MountConfig.get(civilizationId).structureName
	end
	local kit = buildings[civilizationId]
	return (kit and kit[kind]) or Catalog.buildings[kind].name
end

function Presentation.roleName(civilizationId: string, role: string): string
	if role == "mounted" then
		local animal = MountConfig.get(civilizationId).animal
		return animal:sub(1, 1):upper() .. animal:sub(2) .. " Rider"
	end
	local kit = roles[civilizationId]
	return (kit and kit[role]) or role
end

return table.freeze(Presentation)

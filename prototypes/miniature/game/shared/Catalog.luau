--!strict
local Catalog = {}
Catalog.goods = { "food", "timber", "material", "crafted" }
Catalog.salePrices = { food = 2, timber = 4, material = 6, crafted = 15 }
Catalog.buildings = {
	civic = { name = "Council Courtyard", category = "Civic", width = 10, depth = 8, unique = true },
	house = { name = "Courtyard House", category = "Homes", price = 80, width = 6, depth = 6, housing = 4 },
	farm = {
		name = "Grain Farm",
		category = "Production",
		price = 120,
		width = 8,
		depth = 8,
		workers = 2,
		output = "food",
		interval = 10,
		yield = 2,
	},
	timber = {
		name = "Timber Yard",
		category = "Production",
		price = 160,
		width = 8,
		depth = 6,
		workers = 2,
		output = "timber",
		interval = 10,
		yield = 1,
	},
	material = {
		name = "Clay Pit",
		category = "Production",
		price = 200,
		width = 8,
		depth = 6,
		workers = 2,
		output = "material",
		interval = 15,
		yield = 1,
	},
	workshop = {
		name = "Potter's Workshop",
		category = "Production",
		price = 240,

		width = 8,
		depth = 6,
		workers = 2,
		output = "crafted",
		input = "material",
		interval = 15,
		yield = 1,
		research = "craft",
	},
	storehouse = {
		name = "Storehouse",
		category = "Production",
		price = 200,

		width = 8,
		depth = 6,
		research = "store",
		unique = true,
	},
	training = {
		name = "Melee Barracks",
		category = "Military",
		price = 250,

		width = 10,
		depth = 8,
		research = "muster",
	},
	ranged = {
		name = "Ranged Barracks",
		category = "Military",
		price = 250,
		width = 10,
		depth = 8,
	},
	mount = {
		name = "Mounted Barracks",
		category = "Military",
		price = 5000,
		width = 12,
		depth = 10,
	},
	healer = {
		name = "Medic Post",
		category = "Military",
		price = 200,

		width = 6,
		depth = 6,
		research = "supply",
	},
}
Catalog.research = {
	work = { name = "Organized Work", branch = "Economy", price = 100, duration = 30 },
	craft = {
		name = "Craft Traditions",
		branch = "Economy",
		price = 180,

		duration = 60,
		predecessor = "work",
	},
	store = { name = "Storekeeping", branch = "Economy", price = 240, duration = 90, predecessor = "craft" },
	muster = { name = "Muster", branch = "Army", price = 100, duration = 30 },
	drill = { name = "Drill Yard", branch = "Army", price = 180, duration = 60, predecessor = "muster" },
	supply = { name = "Supply Organization", branch = "Army", price = 240, duration = 90, predecessor = "drill" },
	records = { name = "Settlement Records", branch = "Civic", price = 100, duration = 30 },
	porters = {
		name = "Porter Service",
		branch = "Civic",
		price = 180,

		duration = 60,
		predecessor = "records",
	},
	trade = { name = "Trade Steward", branch = "Civic", price = 240, duration = 90, predecessor = "porters" },
}
for _, entries in { Catalog.buildings, Catalog.research } do
	for _, entry in entries do
		table.freeze(entry)
	end
	table.freeze(entries)
end
table.freeze(Catalog.goods)
table.freeze(Catalog.salePrices)
return table.freeze(Catalog)

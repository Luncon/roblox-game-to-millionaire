--!strict
export type Definition = {
	animal: string,
	template: string,
	structureName: string,
	bodyLength: number,
	speed: number,
	strideType: string,
}
local definitions: { [string]: Definition } = {
	sparta = {
		animal = "lion",
		template = "lion",
		structureName = "Lion Guard Den",
		bodyLength = 3.5,
		speed = 9,
		strideType = "feline",
	},
	britain = {
		animal = "horse",
		template = "horse",
		structureName = "Royal Cavalry Stables",
		bodyLength = 3.7,
		speed = 9,
		strideType = "horse",
	},
	seneca = {
		animal = "elk",
		template = "elk",
		structureName = "Antler Lodge",
		bodyLength = 2.9,
		speed = 9,
		strideType = "horse",
	},
	mongols = {
		animal = "horse",
		template = "horse",
		structureName = "Steppe Rider Corral",
		bodyLength = 3.3,
		speed = 9,
		strideType = "horse",
	},
	vikings = {
		animal = "bear",
		template = "bear",
		structureName = "Berserker Bear Hall",
		bodyLength = 3.25,
		speed = 9,
		strideType = "heavy",
	},
	persia = {
		animal = "leopard",
		template = "tiger",
		structureName = "Royal Leopard Garden",
		bodyLength = 3.4,
		speed = 9,
		strideType = "feline",
	},
	japan = {
		animal = "tiger",
		template = "tiger",
		structureName = "Tiger Banner Dojo",
		bodyLength = 3.6,
		speed = 9,
		strideType = "feline",
	},
	maurya = {
		animal = "elephant",
		template = "elephant",
		structureName = "Mahout Elephant Yard",
		bodyLength = 4.6,
		speed = 5.5,
		strideType = "heavy",
	},
	spain = {
		animal = "bull",
		template = "bull",
		structureName = "Toro War Pens",
		bodyLength = 3.5,
		speed = 9,
		strideType = "heavy",
	},
	egypt = {
		animal = "crocodile",
		template = "crocodile",
		structureName = "Nile War Pool",
		bodyLength = 4.4,
		speed = 9,
		strideType = "reptile",
	},
	rome = {
		animal = "wolf",
		template = "wolf",
		structureName = "Capitoline Wolf Den",
		bodyLength = 3.4,
		speed = 9,
		strideType = "feline",
	},
	ottomans = {
		animal = "camel",
		template = "camel",
		structureName = "Sultan's Camel Court",
		bodyLength = 3.9,
		speed = 5.5,
		strideType = "camel",
	},
	ming = {
		animal = "rhino",
		template = "rhino",
		structureName = "Ironhide Rhino Pavilion",
		bodyLength = 4,
		speed = 9,
		strideType = "heavy",
	},
}
for _, definition in definitions do
	table.freeze(definition)
end
table.freeze(definitions)
local MountConfig = { definitions = definitions, price = 5000, troopSlots = 2, troopsPerBuilding = 1 }
function MountConfig.get(civilizationId: string): Definition
	local definition = definitions[civilizationId]
	assert(definition, "Unsupported mounted civilization")
	return definition
end
return table.freeze(MountConfig)

--!strict

local Civilizations = {
	{
		id = "sparta",
		name = "Sparta",
		period = "Classical Greece · 500–400 BCE",
		description = "Build your first Spartan settlement.",
		color = Color3.fromRGB(174, 64, 50),
	},
	{
		id = "britain",
		name = "Britain",
		period = "Georgian redcoats · 1750–1815 CE",
		description = "Establish your first British settlement.",
		color = Color3.fromRGB(54, 100, 157),
	},
	{ id = "seneca", name = "Seneca", period = "Haudenosaunee · 1600–1680 CE", color = Color3.fromRGB(135, 91, 177) },
	{ id = "mongols", name = "Mongol Empire", period = "Early empire · 1206–1260 CE", color = Color3.fromRGB(57, 151, 165) },
	{ id = "vikings", name = "Vikings", period = "Scandinavia · 900–1050 CE", color = Color3.fromRGB(77, 128, 136) },
	{ id = "persia", name = "Persia", period = "Achaemenid · 550–450 BCE", color = Color3.fromRGB(161, 87, 154) },
	{ id = "japan", name = "Sengoku Japan", period = "Sengoku/Momoyama · 1550–1600 CE", color = Color3.fromRGB(191, 68, 88) },
	{ id = "maurya", name = "Mauryan India", period = "Mauryan Empire · 320–250 BCE", color = Color3.fromRGB(211, 133, 57) },
	{ id = "spain", name = "Spanish Empire", period = "Spanish Empire · 1500–1600 CE", color = Color3.fromRGB(210, 174, 66) },
	{ id = "egypt", name = "Ancient Egypt", period = "New Kingdom · 1300–1200 BCE", color = Color3.fromRGB(64, 165, 163) },
	{ id = "rome", name = "Imperial Rome", period = "Imperial period · 100–180 CE", color = Color3.fromRGB(167, 69, 108) },
	{ id = "ottomans", name = "Ottoman Empire", period = "Süleyman · 1520–1566 CE", color = Color3.fromRGB(70, 145, 99) },
	{ id = "ming", name = "Ming China", period = "Ming dynasty · 1400–1600 CE", color = Color3.fromRGB(199, 120, 48) },
}

for _, civilization in Civilizations do
	table.freeze(civilization)
end

return table.freeze(Civilizations)

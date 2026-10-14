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
}

for _, civilization in Civilizations do
	table.freeze(civilization)
end

return table.freeze(Civilizations)

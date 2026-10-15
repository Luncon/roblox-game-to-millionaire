return function()
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	assert(#catalog == 13, "Expected all thirteen agreed civilizations")
	local ClaimRegistry = require(game.ServerScriptService.Game.ClaimRegistry)
	local BattlefieldMap = require(game.ServerScriptService.Game.BattlefieldMap)
	local expected = {sparta=true, seneca=true, britain=true, mongols=true, vikings=true,
		persia=true, japan=true, maurya=true, spain=true, egypt=true, rome=true,
		ottomans=true, ming=true}
	local supported = {}
	for _, civ in catalog do
		assert(expected[civ.id] and not supported[civ.id], "Unknown or duplicate civilization")
		assert(type(civ.period) == "string" and typeof(civ.color) == "Color3")
		supported[civ.id] = true
	end
	local registry = ClaimRegistry.new(8, supported)
	for i = 1, 8 do assert(registry:claim(i, catalog[i].id).ok) end
	assert(registry:claim(9, catalog[9].id).reason == "full")
	assert(registry:claim(10, catalog[1].id).reason == "unavailable")
	registry:release(1)
	assert(registry:claim(9, catalog[9].id).ok)
	local parent = Instance.new("Folder")
	parent.Name = "RosterSettlementTest"
	parent.Parent = workspace
	local sentinel = Instance.new("Part")
	sentinel.Parent = parent
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(parent)
		local plot = world.model.Plots.Plot1
		for _, civ in catalog do
			local previousCount = 0
			for level = 1, 50 do
				world:setOwner(1, civ, 101, "RosterTester", level)
				assert(plot:GetAttribute("SettlementLevel") == level)
				assert(plot.Foundation.Size.X == 60 + (level - 1) * 4)
				assert(plot.Settlement:GetAttribute("Architecture") == civ.id)
				assert(plot:GetAttribute("CivilizationId") == civ.id)
				local nameplate=plot.Settlement:FindFirstChild("CivilizationNameplate",true)
				local courtyard=plot.Settlement:FindFirstChild("CourtyardNameplate",true)
				assert(nameplate and courtyard and nameplate.Parent:IsA("BasePart"))
				assert(string.find(nameplate.TextLabel.Text,civ.name,1,true) and string.find(nameplate.TextLabel.Text,"RosterTester",1,true))
				assert(string.find(courtyard.TextLabel.Text,civ.name,1,true))
				assert(plot:FindFirstChild("Sign")==nil,"Owner label added blocking sign geometry")
				local count = #plot.Settlement:GetDescendants()
				assert(count > previousCount, "Upgrade did not add buildings: " .. civ.id)
				previousCount = count
			end
		end
		world:setOwner(1, nil, nil, nil)
		assert(plot.Foundation.Size.X == 60 and plot:GetAttribute("SettlementLevel") == nil)
		assert(#plot.Settlement:GetChildren() == 0 and sentinel.Parent == parent)
		return 15 -- roster, capacity, and one progression check for each theme
	end)
	parent:Destroy()
	assert(ok, result)
	return result
end

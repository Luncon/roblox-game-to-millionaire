return function()
	local module = game:GetService("ServerScriptService").Game:FindFirstChild("BattlefieldMap")
	assert(module, "BattlefieldMap is not implemented yet")
	local BattlefieldMap = require(module)
	local parent = Instance.new("Folder")
	parent.Name = "CivilizationMapTest"
	parent.Parent = workspace
	local sentinel = Instance.new("Part")
	sentinel.Name = "DeveloperGeometry"
	sentinel.Parent = parent
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(parent)
		assert(sentinel.Parent == parent, "Existing developer geometry was removed")
		assert(world.model.Parent == parent)
		assert(#world.model.Plots:GetChildren() == 8, "Expected eight plots")
		assert(world.model.Battlefield:IsA("BasePart"))
		assert(world.model.EntrySpawn:IsA("SpawnLocation"))
		local average = Vector3.zero
		for plotId = 1, 8 do
			local plot = world.model.Plots:FindFirstChild("Plot" .. plotId)
			assert(plot and plot:GetAttribute("PlotId") == plotId)
			local position = plot.Foundation.Position
			average += position
			assert(Vector3.new(position.X, 0, position.Z).Magnitude > 100, "Plot overlaps central field")
			assert(plot:GetAttribute("OwnerId") == nil)
		end
		assert(Vector3.new(average.X, 0, average.Z).Magnitude < .01, "Plots are not centered around field")
		local sparta = { id = "sparta", name = "Sparta", color = Color3.fromRGB(174, 64, 50) }
		world:setOwner(1, sparta, 101, "TestCommander")
		local plot = world.model.Plots.Plot1
		assert(plot:GetAttribute("OwnerId") == 101)
		assert(plot:GetAttribute("CivilizationId") == "sparta")
		local nameplate=plot.Settlement:FindFirstChild("CivilizationNameplate",true)
		assert(nameplate and nameplate:IsA("SurfaceGui"))
		assert(string.find(nameplate.TextLabel.Text, "TestCommander", 1, true))
		assert(plot:FindFirstChild("Sign")==nil,"Claimed settlement retained a freestanding name sign")
		assert(#plot.Settlement:GetChildren() > 0)
		assert((world:getSpawn(1).Position - plot.Foundation.Position).Magnitude < 40)
		world:setOwner(1, nil, nil, nil)
		assert(plot:GetAttribute("OwnerId") == nil and plot:GetAttribute("CivilizationId") == nil)
		assert(string.find(plot.Sign.SurfaceGui.TextLabel.Text, "UNCLAIMED", 1, true))
		assert(#plot.Settlement:GetChildren() == 0)
		assert(sentinel.Parent == parent)
		return 5
	end)
	parent:Destroy()
	assert(ok, result)
	return result
end

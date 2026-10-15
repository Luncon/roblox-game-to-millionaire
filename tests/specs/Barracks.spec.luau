return function()
	local BattlefieldMap = require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local container = Instance.new("Folder")
	container.Name = "BarracksTest"
	container.Parent = workspace
	local count = 0
	local function test(name, callback) callback(); count += 1; print("PASS: " .. name) end
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(container)
		test("barracks unlocks at settlement two for every civilization", function()
			for _, civ in catalog do
				world:setOwner(1,civ,101,"BarracksTester",1)
				assert(world.model.Plots.Plot1.Settlement:FindFirstChild("Barracks") == nil)
				for _,level in {2,4,25,50} do
					world:setOwner(1,civ,101,"BarracksTester",level)
					local barracks = world.model.Plots.Plot1.Settlement:FindFirstChild("Barracks")
					assert(barracks and barracks:IsA("Model"), "Barracks missing for " .. civ.id)
					assert(#barracks:GetDescendants() > 0)
				end
			end
		end)
		test("barracks spawns track current moved and rotated plots", function()
			world.model:PivotTo(CFrame.new(1200,20,-1100)*CFrame.Angles(0,.3,0)*world.model:GetPivot())
			for plotId = 1, 8 do
				world:setOwner(plotId,catalog[1],101,"BarracksTester",50)
				local plot = world.model.Plots["Plot" .. plotId]
				local expected = plot.Foundation.CFrame*CFrame.new(-24,5,-11)
				local actual = world:getBarracksSpawn(plotId)
				assert((actual.Position-expected.Position).Magnitude < .01)
				assert(actual.LookVector:Dot(expected.LookVector) > .9999)
				local overlap = OverlapParams.new()
				overlap.FilterType = Enum.RaycastFilterType.Include
				overlap.FilterDescendantsInstances = {plot.Settlement}
				assert(#workspace:GetPartBoundsInBox(actual,Vector3.new(3,5,3),overlap) == 0,
					"Barracks warrior spawn is obstructed for plot " .. plotId)
			end
		end)
		test("releasing plot removes barracks and keeps owned troops outside rebuilt settlement", function()
			assert(world.model:FindFirstChild("Troops"), "World must provide a separate troop container")
			local sentinel = Instance.new("Model")
			sentinel.Name = "LivingTroopSentinel"
			sentinel.Parent = world.model.Troops
			world:setOwner(1,nil,nil,nil)
			assert(world.model.Plots.Plot1.Settlement:FindFirstChild("Barracks") == nil)
			assert(sentinel.Parent == world.model.Troops)
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

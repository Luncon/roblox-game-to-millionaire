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
				local expected = plot.Foundation.CFrame*CFrame.new(require(game.ReplicatedStorage.Shared.SettlementSites).barracksSpawn)
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
  test("relocated Barracks entrance screen spawns and controls stay clear for all factions and plots",function()
   local Sites=require(game.ReplicatedStorage.Shared.SettlementSites)
   for id=1,8 do for _,civ in catalog do
    world:setOwner(id,civ,100+id,'RecruitmentGeometry',50)
    world:syncControls(id,{level=50,weaponLevel=1,armorLevel=1,barracksLevel=1,trainingLevel=1})
    local plot=world.model.Plots['Plot'..id];local barracks=plot.Settlement.Barracks
    assert(barracks:FindFirstChild('RecruitmentBoard') and not plot.Infrastructure:FindFirstChild('ArmyCamp'))
    local filter=OverlapParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.RespectCanCollide=true
    filter.FilterDescendantsInstances={plot.Settlement,plot.Infrastructure,plot.Controls}
    for z=-65,-53,2 do
     local p=plot.Foundation.CFrame*CFrame.new(Sites.barracks.X,2.15,z)
     assert(#workspace:GetPartBoundsInBox(p,Vector3.new(2,4,1.8),filter)==0,'Barracks entrance blocked: '..civ.id)
    end
    for _,slot in {'warrior','ranged','camp','reinforcement'}do
     local p=world:getBarracksSpawn(id,'warrior',slot)
     assert(#workspace:GetPartBoundsInBox(p,Vector3.new(2,3,2),filter)==0,'Recruit spawn blocked by controls: '..slot)
    end
   end end
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

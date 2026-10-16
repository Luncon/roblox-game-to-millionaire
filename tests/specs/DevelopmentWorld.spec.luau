return function()
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder");container.Name="DevelopmentWorldFixture";container.Parent=workspace
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function state(level,changes)
		local value={coins=1000,level=level,weaponLevel=1,armorLevel=1,barracksLevel=1,
			trainingLevel=0,farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior"}
		for key,item in changes or {} do value[key]=item end
		return value
	end
	local function action(controls,id)
		local found=nil
		for _,pad in controls:GetChildren() do
			if pad:GetAttribute("Action")==id then assert(not found,"Duplicate development pad action: "..id);found=pad end
		end
		return found
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		assert(type(world.syncInfrastructure)=="function","Purchased settlement infrastructure is not implemented")
		local function sync(plotId,civ,value)
			world:setOwner(plotId,civ,100+plotId,"DevelopmentTester",value.level)
			world:syncInfrastructure(plotId,value,civ)
			world:syncControls(plotId,value)
			return world.model.Plots["Plot"..plotId]
		end
		test("purchased buildings appear independently from settlement growth and passive workers are not combat actors",function()
			local plot=sync(1,catalog[1],state(1))
			assert(plot:FindFirstChild("Infrastructure"))
			for _,name in {"Armory","TrainingYard","ArmyCamp","Farmland","WorkerCamp"} do assert(not plot.Infrastructure:FindFirstChild(name)) end
			plot=sync(1,catalog[1],state(2))
			assert(plot.Infrastructure:FindFirstChild("Armory"))
			assert(not plot.Infrastructure:FindFirstChild("TrainingYard"))
			plot=sync(1,catalog[1],state(7,{trainingLevel=1,farmLevel=1,workersLevel=1}))
			for _,name in {"Armory","TrainingYard","Farmland","WorkerCamp"} do
				local building=plot.Infrastructure:FindFirstChild(name)
				assert(building,"Purchased structure missing: "..name)
				local visible=0
				for _,item in building:GetDescendants() do
					if item:IsA("Humanoid")then
						assert(item.Parent:GetAttribute("PassiveWorker")==true and not item.EvaluateStateMachine and item.WalkSpeed==0,
							"Infrastructure contains an active Humanoid")
					end
					if item:IsA("BasePart") then assert(item.Anchored);if item.Transparency<1 then visible+=1 end end
				end
				assert(visible>0,"Purchased infrastructure has no visible geometry")
			end
			assert(not plot.Infrastructure:FindFirstChild("ArmyCamp"))
			plot=sync(1,catalog[1],state(10,{trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,barracksLevel=4}))
			assert(plot.Infrastructure:FindFirstChild("ArmyCamp"))
		end)
		test("only eligible current purchases exist and the settlement-ten checkpoint hides its blocked pad",function()
			local plot=sync(1,catalog[1],state(4))
			assert(action(plot.Controls,"weapon") and action(plot.Controls,"armor") and action(plot.Controls,"barracks2"))
			for _,id in {"weapon3","armor3","weapon4","armor4","barracks3","barracks4","training","farm","workers","armyCamp","collectFarm"} do assert(not action(plot.Controls,id),"Premature physical pad: "..id) end
			local coin=action(plot.Controls,"earn")
			plot=sync(1,catalog[1],state(5,{coins=0}))
			assert(action(plot.Controls,"training"),"Unaffordable but unlocked training site disappeared")
			assert(not action(plot.Controls,"farm") and not action(plot.Controls,"armyCamp"))
			plot=sync(1,catalog[1],state(7,{trainingLevel=1}))
			assert(not action(plot.Controls,"training") and action(plot.Controls,"farm") and not action(plot.Controls,"workers"))
			plot=sync(1,catalog[1],state(7,{trainingLevel=1,farmLevel=1}))
			assert(not action(plot.Controls,"farm") and action(plot.Controls,"workers") and action(plot.Controls,"collectFarm"))
			plot=sync(1,catalog[1],state(9,{trainingLevel=1,farmLevel=1,workersLevel=0,barracksLevel=4}))
			assert(not action(plot.Controls,"upgrade"),"Checkpoint upgrade remained physically available without workers")
			plot=sync(1,catalog[1],state(9,{trainingLevel=1,farmLevel=1,workersLevel=1,barracksLevel=4}))
			assert(action(plot.Controls,"upgrade") and not action(plot.Controls,"armyCamp"))
			plot=sync(1,catalog[1],state(10,{trainingLevel=1,farmLevel=1,workersLevel=1,barracksLevel=4,weaponLevel=10,armorLevel=10}))
			assert(action(plot.Controls,"armyCamp"))
			assert(not action(plot.Controls,"weapon4") and not action(plot.Controls,"armor4"),"Settlement-capped gear still has a physical purchase pad")
			assert(action(plot.Controls,"earn")==coin,"Development progression replaced the single-coin pad")
		end)
		test("all eight moved capital plots retain grounded rural space clear of the final foundation and troop road",function()
			local movement=CFrame.new(2300,20,-1900)*CFrame.Angles(0,.37,0)
			world.model:PivotTo(movement*world.model:GetPivot())
			local terrain=RaycastParams.new();terrain.FilterType=Enum.RaycastFilterType.Include
			terrain.FilterDescendantsInstances={world.model.Ground,world.model.Landscape.TerrainSurface}
			for plotId=1,8 do
				local value=state(50,{trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,barracksLevel=4,weaponLevel=4,armorLevel=4})
				local plot=sync(plotId,catalog[(plotId-1)%#catalog+1],value)
				local farmland=plot.Infrastructure.Farmland
				for _,part in farmland:GetDescendants() do
					if part:IsA("BasePart") then
						for _,x in {-1,1} do for _,z in {-1,1} do
							local point=plot.Foundation.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X/2,0,z*part.Size.Z/2)))
							assert(point.Z< -128,"Farm entered the finished settlement footprint: "..part.Name)
							assert(math.abs(point.X)>14,"Farm blocked the protected central troop approach: "..part.Name)
						end end
					end
				end
				for _,x in {-88,-60,-32,32,60,88} do
					for _,z in {-192,-172,-152} do
						local sample=plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
						local hit=workspace:Raycast(sample+Vector3.new(0,200,0),Vector3.new(0,-400,0),terrain)
						assert(hit and hit.Normal:Dot(Vector3.yAxis)>.999,"Rural reservation is not on flat rendered terrain")
						assert(math.abs(movement:PointToObjectSpace(hit.Position).Y-.15)<.08,"Rural field terrain reservation was lost after moving the map")
					end
				end
				local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.RespectCanCollide=true
				overlap.FilterDescendantsInstances={plot.Settlement,plot.Infrastructure}
				for _,pad in plot.Controls:GetChildren() do
					if pad:IsA("BasePart") then
						assert(#workspace:GetPartBoundsInBox(pad.CFrame*CFrame.new(0,3.5,0),Vector3.new(6,6,4),overlap)==0,
							"Purchased building blocks standing room at "..pad.Name.." plot "..plotId)
					end
				end
			end
		end)
		test("farm reserve ticks preserve pad and structure instances while release removes owned development",function()
			local value=state(10,{trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,barracksLevel=4})
			local plot=sync(1,catalog[1],value)
			local collect=action(plot.Controls,"collectFarm")
			assert(collect)
			local detector=collect:FindFirstChildOfClass("ClickDetector")
			local structures={};for _,item in plot.Infrastructure:GetChildren() do structures[item.Name]=item end
			for _,reserve in {1,2,59,60,0} do
				value.farmCoins=reserve;world:syncInfrastructure(1,value,catalog[1]);world:syncControls(1,value)
				assert(action(plot.Controls,"collectFarm")==collect and collect:FindFirstChildOfClass("ClickDetector")==detector,"Farm tick recreated a pad beneath its contact latch")
				for name,original in structures do assert(plot.Infrastructure:FindFirstChild(name)==original,"Farm tick rebuilt live infrastructure") end
			end
			-- Move an already populated farm, not a fresh build at its destination.
			local farmers={}
			for _,worker in plot.Infrastructure.Farmland:GetChildren() do
				if worker:GetAttribute("PassiveWorker")==true then table.insert(farmers,worker) end
			end
			assert(#farmers==2)
			world.model:PivotTo(CFrame.new(900,17,-650)*CFrame.Angles(0,.61,0)*world.model:GetPivot())
			require(game.ServerScriptService.Game.SettlementInfrastructure).animate(world.model,7)
			for _,worker in farmers do
				local point=plot.Foundation.CFrame:PointToObjectSpace(worker:GetPivot().Position)
				local expected=require(game.ServerScriptService.Game.FarmTenders).sample(1,7-worker:GetAttribute("TendingStartedAt"),worker:GetAttribute("WorkerIndex"))
				assert(math.abs(point.X-expected.X)<.002 and math.abs(point.Z-expected.Z)<.002,
					"Existing farmer snapped to an old world origin after moving its plot: "..tostring(point))
				assert(worker.Parent==plot.Infrastructure.Farmland)
			end
			world:setOwner(1,nil,nil,nil)
			assert(#plot.Infrastructure:GetChildren()==0,"Released claim left its purchased buildings behind")
			for _,id in {"training","farm","workers","armyCamp","collectFarm"} do assert(not action(plot.Controls,id),"Released claim retained a development input") end
		end)
		return cases
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

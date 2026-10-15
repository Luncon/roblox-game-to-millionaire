return function()
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder");container.Name="EconomyExpansionWorldFixture";container.Parent=workspace
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function state(level,changes)
		local value={coins=10000,level=level,weaponLevel=4,armorLevel=4,barracksLevel=4,
			trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,farmCoins=0,extraTroopClass="warrior",
			blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
		for field,item in changes or {} do value[field]=item end
		return value
	end
	local function action(plot,id)
		local found=nil
		for _,pad in plot.Controls:GetChildren() do
			if pad:GetAttribute("Action")==id then assert(not found,"Duplicate expansion action: "..id);found=pad end
		end
		return found
	end
	local function parts(model)
		local count=0
		for _,item in model:GetDescendants() do if item:IsA("BasePart") and item.Transparency<1 then count+=1 end end
		return count
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local function sync(civ,value,plotId)
			plotId=plotId or 1
			world:setOwner(plotId,civ,100+plotId,"ExpansionTester",value.level)
			world:syncInfrastructure(plotId,value,civ);world:syncControls(plotId,value)
			return world.model.Plots["Plot"..plotId]
		end
		test("every civilization visibly advances its economic sites and creates only purchased workshops and storage",function()
			for _,civ in catalog do
				local plot=sync(civ,state(12))
				local firstFarm,firstCamp=plot.Infrastructure.Farmland,plot.Infrastructure.WorkerCamp
				local farmParts,campParts=parts(firstFarm),parts(firstCamp)
				assert(firstFarm:GetAttribute("FarmLevel")==1 and firstCamp:GetAttribute("WorkersLevel")==1,
					"Economic tier metadata is not implemented: "..civ.id)
				for _,name in {"Blacksmith","Armorer","Storehouse"} do assert(not plot.Infrastructure:FindFirstChild(name)) end
				plot=sync(civ,state(12,{farmLevel=2,workersLevel=2}))
				assert(plot.Infrastructure.Farmland~=firstFarm and plot.Infrastructure.WorkerCamp~=firstCamp)
				assert(plot.Infrastructure.Farmland:GetAttribute("FarmLevel")==2 and plot.Infrastructure.Farmland:GetAttribute("WorkerCount")==3)
				assert(plot.Infrastructure.WorkerCamp:GetAttribute("WorkersLevel")==2)
				assert(parts(plot.Infrastructure.Farmland)>farmParts and parts(plot.Infrastructure.WorkerCamp)>campParts,
					"Tier II did not add lasting visible economic geometry: "..civ.id)
				plot=sync(civ,state(13,{farmLevel=2,workersLevel=2,blacksmithLevel=1,armorerLevel=1}))
				for _,name in {"Blacksmith","Armorer"} do assert(parts(plot.Infrastructure:FindFirstChild(name))>0) end
				assert(not plot.Infrastructure:FindFirstChild("Storehouse"))
				plot=sync(civ,state(16,{farmLevel=2,workersLevel=2,blacksmithLevel=1,armorerLevel=1,storehouseLevel=1}))
				assert(parts(plot.Infrastructure.Storehouse)>0)
			end
		end)
		test("only current economic and barracks offers exist with farm purchase and collection separated",function()
			local plot=sync(catalog[1],state(12))
			assert(action(plot,"farm") and action(plot,"workers")==nil and action(plot,"collectFarm"))
			assert((action(plot,"farm").Position-action(plot,"collectFarm").Position).Magnitude>=20,
				"Farm purchase and collection compete for the same interaction position")
			assert(action(plot,"barracks5") and not action(plot,"barracks6"))
			assert(not action(plot,"blacksmith") and not action(plot,"armorer") and not action(plot,"storehouse"))
			plot=sync(catalog[1],state(13,{farmLevel=2}))
			assert(not action(plot,"farm") and action(plot,"workers") and action(plot,"blacksmith") and action(plot,"armorer"))
			plot=sync(catalog[1],state(16,{farmLevel=2,workersLevel=2,barracksLevel=5}))
			assert(action(plot,"barracks6") and action(plot,"storehouse"))
			plot=sync(catalog[1],state(16,{farmLevel=2,workersLevel=2,barracksLevel=6,blacksmithLevel=1,armorerLevel=1,storehouseLevel=1}))
			for _,id in {"farm","workers","blacksmith","armorer","storehouse","barracks5","barracks6"} do assert(not action(plot,id),"Completed expansion retained purchase pad: "..id) end
			assert(action(plot,"collectFarm") and action(plot,"earn"))
		end)
		test("moved settlements preserve expansion pad standing room and farm reserve updates preserve building identity",function()
			world.model:PivotTo(CFrame.new(2100,11,-2300)*CFrame.Angles(0,.43,0)*world.model:GetPivot())
			for index,civ in catalog do
				for _,level in {12,13,16,50} do
					local value=state(level,{farmLevel=2,workersLevel=2,barracksLevel=5,
						blacksmithLevel=if level>=13 then 1 else 0,armorerLevel=if level>=13 then 1 else 0,
						storehouseLevel=if level>=16 then 1 else 0})
					local plot=sync(civ,value,(index-1)%8+1)
					local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.RespectCanCollide=true
					overlap.FilterDescendantsInstances={plot.Settlement,plot.Infrastructure}
					-- Check all available inputs, including unpurchased new sites.
					for _,phase in {"farm","workers","offers","owned"} do
						value.farmLevel=if phase=="farm" then 1 else 2
						value.workersLevel=if phase=="farm" or phase=="workers" then 1 else 2
						if phase~="owned" then
							value.blacksmithLevel,value.armorerLevel,value.storehouseLevel=0,0,0
						else
							value.blacksmithLevel=if level>=13 then 1 else 0;value.armorerLevel=value.blacksmithLevel
							value.storehouseLevel=if level>=16 then 1 else 0
						end
						world:syncInfrastructure((index-1)%8+1,value,civ);world:syncControls((index-1)%8+1,value)
						for _,pad in plot.Controls:GetChildren() do
							assert(#workspace:GetPartBoundsInBox(pad.CFrame*CFrame.new(0,3.5,0),Vector3.new(6,6,4),overlap)==0,
								"Expansion standing room blocked: "..civ.id.." level "..level.." "..pad.Name)
						end
					end
					local originals={};for _,child in plot.Infrastructure:GetChildren() do originals[child.Name]=child end
					local collect=action(plot,"collectFarm")
					for _,reserve in {0,59,60,if level>=16 then 180 else 60} do
						value.farmCoins=reserve;world:syncInfrastructure((index-1)%8+1,value,civ);world:syncControls((index-1)%8+1,value)
						for name,child in originals do assert(plot.Infrastructure:FindFirstChild(name)==child,"Reserve tick rebuilt "..name) end
						assert(action(plot,"collectFarm")==collect)
					end
				end
			end
		end)
		test("purchasing workshops and storage leaves their nearest inner prompt standing positions clear",function()
			local definitions=require(game.ReplicatedStorage.Shared.PadCatalog).byAction
			local sites=require(game.ReplicatedStorage.Shared.SettlementSites)
			for _,civ in catalog do
				for _,level in {13,16,50} do
					local plot=sync(civ,state(level,{farmLevel=2,workersLevel=2,blacksmithLevel=1,armorerLevel=1,
						storehouseLevel=if level>=16 then 1 else 0}))
					local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.RespectCanCollide=true
					overlap.FilterDescendantsInstances={plot.Infrastructure}
					for _,id in {"blacksmith","armorer","storehouse"} do
						if id=="storehouse" and level<16 then continue end
						local definition=definitions[id]
						local padFrame=plot.Foundation.CFrame*CFrame.new(definition.x,definition.y or 2,definition.z)
						local direction=sites[id]-Vector3.new(definition.x,0,definition.z)
						direction=Vector3.new(direction.X,0,direction.Z).Unit
						for _,distance in {7,9.5} do
							local body=padFrame*CFrame.new(direction.X*distance,3.5,direction.Z*distance)
							local hits=workspace:GetPartBoundsInBox(body,Vector3.new(6,6,4),overlap)
							assert(#hits==0,"Purchase encloses its inner prompt user: "..civ.id.." level "..level.." "..id
								.." distance="..distance.." blocker="..(if hits[1] then hits[1]:GetFullName() else "none"))
						end
					end
				end
			end
		end)
		return cases
	end)
	container:Destroy();assert(ok,result);return result
end

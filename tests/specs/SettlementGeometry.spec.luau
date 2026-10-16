-- Independent native geometry regressions; never consult builder geometry helpers.
return function(selectedCase)
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog={};for _,civ in require(game.ReplicatedStorage.Shared.Civilizations)do catalog[civ.id]=civ end
	local container=Instance.new("Folder");container.Name="SettlementGeometryRegression";container.Parent=workspace
	local cases=0;local probe
	local function test(name,fn)
		if selectedCase and selectedCase~=name then return end
		fn();cases+=1;print("PASS: "..name)
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(3300,30,-3100)*CFrame.Angles(0,.43,0)*world.model:GetPivot())
		local plot=world.model.Plots.Plot1
		local function build(id,level)world:setOwner(1,catalog[id],9101,"GeometryTester",level);return plot.Settlement end
		local function queryParts(root)
			local result={}
			for _,part in root:GetDescendants()do if part:IsA("BasePart")then
				part.CanQuery=true;table.insert(result,part)
			end end
			return result
		end
		local function below(part)
			local candidates={plot.Foundation}
			for _,other in queryParts(plot.Settlement)do if other~=part then table.insert(candidates,other)end end
			local up=plot.Foundation.CFrame.UpVector
			local foot=part.Position-up*(part.Size.Y/2)
			local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances=candidates
			local hit=workspace:Raycast(foot+up*.02,-up*6,filter)
			assert(hit,"No native support beneath "..part:GetFullName())
			return (foot-hit.Position):Dot(up)
		end
		test("Sparta pillars and podium meet physical supports",function()
			local settlement=build("sparta",12)
			for _,part in settlement.GrowthFeature_9:GetChildren()do if part:IsA("BasePart")and part.Name=="ProcessionalPillar"then
				assert(below(part)<=.05,"Sparta processional pillar has an unsupported ground gap")
			end end
			local podium=settlement.GrowthFeature_3.FirstDwelling.Podium
			assert(below(podium)<=.05,"Sparta dwelling podium has an unsupported ground gap")
		end)
		test("starter towers have supported first tiers",function()
			for _,id in {"japan","ming"}do
				local settlement=build(id,1);local first
				for _,part in settlement:GetChildren()do if part.Name=="TowerTier"and (not first or part.Position.Y<first.Position.Y)then first=part end end
				assert(first and below(first)<=.05,id.." starter first tier floats above its foundation")
			end
		end)
		test("wide pitched roof covers the actual upper wall corners",function()
			local settlement=build("britain",30)
			local grand=settlement.GrowthFeature_30:FindFirstChildWhichIsA("Model")
			local body=grand.CivicHouse
			for _,x in {-1,1}do for _,z in {-1,1}do
				local point=body.CFrame:PointToWorldSpace(Vector3.new(x*body.Size.X/2,body.Size.Y/2,z*body.Size.Z/2))
				local covered=false
				for _,roof in grand:GetChildren()do if roof.Name=="RoofSlope"then
					local p=roof.CFrame:PointToObjectSpace(point)
					if math.abs(p.X)<=roof.Size.X/2+.02 and math.abs(p.Z)<=roof.Size.Z/2+.02 and p.Y<=roof.Size.Y/2+.05 then covered=true end
				end end
				assert(covered,"Wide civic wall protrudes above the pitched roof exterior")
			end end
		end)
		test("grand longhouse clears its unlock perimeter and ceremonial gate",function()
			for _,id in {"seneca","vikings"}do
				local settlement=build(id,30)
				local grand=settlement.GrowthFeature_30:FindFirstChildWhichIsA("Model")
				local candidates=queryParts(settlement.Perimeter)
				for _,part in queryParts(settlement.GrowthFeature_20)do table.insert(candidates,part)end
				local filter=OverlapParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances=candidates
				probe=Instance.new("Part");probe.Name="OwnedGeometryProbe";probe.Anchored=true;probe.CanCollide=false;probe.CanQuery=false;probe.Transparency=1;probe.Parent=container
				for _,part in grand:GetChildren()do if part:IsA("BasePart")and (part.Name=="TimberHall"or part.Name=="CarvedEndPost"or part.Name=="FoundationFooting")then
					probe.CFrame=part.CFrame;probe.Size=part.Size-Vector3.one*.02
					local overlaps=workspace:GetPartsInPart(probe,filter)
					assert(#overlaps==0,id.." grand "..part.Name.." penetrates "..(overlaps[1]and overlaps[1].Name or "unknown"))
				end end
				probe:Destroy();probe=nil
			end
		end)
		test("visible purchase pads meet foundation or exterior supports",function()
			local definitions=require(game.ReplicatedStorage.Shared.PadCatalog).byAction
			local function checkPads()
				for _,pad in plot.Controls:GetChildren()do if pad:IsA("BasePart")then
					local definition=assert(definitions[pad:GetAttribute("Action")],"Visible control has no catalog action")
					local expected=plot.Foundation.CFrame*CFrame.new(definition.x,definition.y or 2,definition.z)
					assert((pad.Position-expected.Position).Magnitude<.002 and pad.Size==Vector3.new(8,1,6),"Support moved or resized "..pad.Name)
					for _,support in pad:GetDescendants()do if support:IsA("BasePart")then
						assert(not support.CanTouch and support:GetAttribute("Action")==nil,"Pad support became another gameplay input")
						for _,x in {-1,1}do for _,z in {-1,1}do
							local point=pad.CFrame:PointToObjectSpace(support.CFrame:PointToWorldSpace(Vector3.new(x*support.Size.X/2,0,z*support.Size.Z/2)))
							assert(math.abs(point.X)<=pad.Size.X/2+.01 and math.abs(point.Z)<=pad.Size.Z/2+.01,"Pad support widened the input footprint")
						end end
						for _,item in support:GetDescendants()do assert(not item:IsA("ClickDetector")and not item:IsA("ProximityPrompt")and not item:IsA("LuaSourceContainer"),"Pad support imported an input handler")end
					end end
					local candidates={plot.Foundation,world.model.Ground,world.model.Landscape.TerrainSurface}
					for _,part in queryParts(plot.Controls)do if part~=pad then table.insert(candidates,part)end end
					local up=plot.Foundation.CFrame.UpVector
					local bottom=pad.CFrame:PointToWorldSpace(Vector3.new(0,-pad.Size.Y/2,0))
					local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances=candidates
					local hit=workspace:Raycast(bottom+up*.02,-up*6,filter)
					assert(hit and (bottom-hit.Position):Dot(up)<=.05,"Physical pad floats above its actual support: "..pad.Name)
				end end
			end
			world:setOwner(1,nil,nil,nil);checkPads()
			for _,level in {5,7,16,50}do
				build("sparta",level)
				local value={coins=10000,level=level,weaponLevel=1,armorLevel=1,barracksLevel=if level>=10 then 4 else 1,
					trainingLevel=if level>=10 then 1 else 0,farmLevel=if level>=10 then 1 else 0,
					workersLevel=if level>=10 then 1 else 0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior",
					blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
				world:syncControls(1,value);checkPads()
			end
			build("sparta",5)
			local value={coins=10000,level=5,weaponLevel=1,armorLevel=1,barracksLevel=1,trainingLevel=0,
				farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior",
				blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
			world:syncControls(1,value)
			local old=assert(plot.Controls:FindFirstChild("TrainingButton"));local supports={}
			for _,part in old:GetDescendants()do if part:IsA("BasePart")then table.insert(supports,part)end end
			value.trainingLevel=1;world:syncControls(1,value)
			assert(not plot.Controls:FindFirstChild("TrainingButton")and not old:IsDescendantOf(workspace))
			for _,support in supports do assert(not support:IsDescendantOf(workspace),"Hidden pad left a detached support")end
		end)
		return cases
	end)
	if probe then probe:Destroy()end
	container:Destroy();assert(ok,result);return result
end

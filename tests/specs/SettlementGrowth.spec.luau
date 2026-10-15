return function()
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name,container.Parent="FiftyLevelSettlementFixture",workspace
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local plot=world.model.Plots.Plot1
		test("every civilization adds a lasting identifiable feature at each of fifty levels",function()
			for _,civ in catalog do
				local prior={}
				for level=1,50 do
					world:setOwner(1,civ,101,"GrowthTester",level)
					assert(plot.Foundation.Size.X==60+4*(level-1))
					assert(plot.Settlement:GetAttribute("BuiltLevel")==level and plot.Settlement:GetAttribute("GrowthFeatureCount")==level-1)
					for unlocked=2,level do
						local feature=plot.Settlement:FindFirstChild("GrowthFeature_"..unlocked)
						assert(feature and feature:GetAttribute("UnlockLevel")==unlocked and feature:GetAttribute("CivilizationId")==civ.id)
						assert(type(feature:GetAttribute("FeatureId"))=="string" and type(feature:GetAttribute("Theme"))=="string")
						local hasGeometry=false
						for _,part in feature:GetDescendants() do if part:IsA("BasePart") then hasGeometry=true end end
						assert(hasGeometry,"Growth unlock has no visible geometry")
						if prior[unlocked] then assert(feature==prior[unlocked],civ.id.." level "..level.." replaced GrowthFeature_"..unlocked.." during consecutive growth") end
						prior[unlocked]=feature
					end
					if level%10==0 then task.wait() end
				end
			end
		end)
		test("all civilization levels keep structures within their growing footprint and final part budget",function()
			for _,civ in catalog do
				for level=1,50 do
					world:setOwner(1,civ,101,"BoundsTester",level)
					local half=plot.Foundation.Size.X/2
					local parts=0
					for _,part in plot.Settlement:GetDescendants() do
						if not part:IsA("BasePart") then continue end
						parts+=1
						for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
							local corner=plot.Foundation.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(x*part.Size.X/2,y*part.Size.Y/2,z*part.Size.Z/2)))
							assert(math.abs(corner.X)<=half+.05 and math.abs(corner.Z)<=half+.05,civ.id.." level"..level.." out-of-bounds "..part.Name)
						end end end
					end
					assert(parts<=400,civ.id.." exceeds final static settlement budget: "..parts)
					if level%10==0 then task.wait() end
				end
			end
		end)
		test("barracks spawns and permanent arena-facing exit lanes remain unobstructed through growth",function()
			local overlap=OverlapParams.new()
			overlap.FilterType=Enum.RaycastFilterType.Include
			overlap.FilterDescendantsInstances={plot.Settlement}
			for _,civ in catalog do
				for _,level in {2,4,10,25,40,50} do
					world:setOwner(1,civ,101,"ExitTester",level)
					for _,kind in {"warrior","ranged"} do
						assert(#workspace:GetPartBoundsInBox(world:getBarracksSpawn(1,kind),Vector3.new(3,5,3),overlap)==0,civ.id.." blocks "..kind.." spawn at"..level)
					end
					local half=plot.Foundation.Size.X/2
					local length=half+4
					local frame=plot.Foundation.CFrame*CFrame.new(-36,4,-half/2+2)
					local blocked=workspace:GetPartBoundsInBox(frame,Vector3.new(8,5,length),overlap)
					assert(#blocked==0,civ.id.." level"..level.." blocks arena-facing exit: "..(blocked[1] and blocked[1].Name or ""))
				end
			end
		end)
		test("same-level refresh is idempotent and switching or transformed rebuilding clears stale growth",function()
			world:setOwner(1,catalog[1],101,"OldOwner",50)
			local old=plot.Settlement.GrowthFeature_50
			local before=#plot.Settlement:GetDescendants()
			world:setOwner(1,catalog[1],101,"OldOwner",50)
			assert(plot.Settlement.GrowthFeature_50==old and #plot.Settlement:GetDescendants()==before)
			world.model:PivotTo(CFrame.new(2400,20,2400)*CFrame.Angles(0,.6,0)*world.model:GetPivot())
			world:setOwner(1,catalog[2],202,"NewOwner",25)
			assert(not old:IsDescendantOf(workspace) and plot.Settlement:GetAttribute("BuiltLevel")==25)
			assert(plot.Settlement:FindFirstChild("GrowthFeature_26")==nil)
			assert(plot.Settlement:FindFirstChild("CivilizationNameplate",true):GetAttribute("CivilizationId")==catalog[2].id)
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

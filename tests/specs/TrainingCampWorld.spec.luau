return function()
	local Game=game.ServerScriptService.Game
	local Map=require(Game.BattlefieldMap)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder");container.Name="TrainingCampWorldFixture";container.Parent=workspace
	local cases=0
	local function test(name,fn) fn();cases+=1;print("PASS: "..name) end
	local function state(level,training)
		return {coins=0,level=level,weaponLevel=1,armorLevel=1,barracksLevel=4,trainingLevel=training,
			farmLevel=1,workersLevel=1,armyCampLevel=if level>=10 then 1 else 0}
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local function sync(id,civ,level,training)
			world:setOwner(id,civ,100+id,"CampTester",level)
			world:syncControls(id,state(level,training))
			return world.model.Plots["Plot"..id]
		end
		test("training construction is outside the final plot beside its future yard",function()
			for id=1,8 do
				for _,level in {5,20,50} do
					local plot=sync(id,catalog[1],level,0)
					local pad=assert(plot.Controls:FindFirstChild("TrainingButton"))
					local point=plot.Foundation.CFrame:PointToObjectSpace(pad.Position)
					assert(math.abs(point.X)-pad.Size.X/2>128,"Training pad remains inside the main plot")
					assert(pad:FindFirstChildOfClass("ProximityPrompt"))
				end
			end
		end)
		test("all civilization campfires restore from the existing training purchase",function()
			for _,civ in catalog do
				local plot=sync(1,civ,5,1)
				local yard=assert(plot.Infrastructure:FindFirstChild("TrainingYard"))
				assert(yard:FindFirstChild("Campfire") and yard:FindFirstChild("TrainingGround"))
				assert(not yard:FindFirstChild("PracticePost") and not plot.Controls:FindFirstChild("TrainingButton"))
				assert(yard.Campfire:FindFirstChildWhichIsA("Fire",true),"Campfire has no flame")
				for _,part in yard:GetDescendants() do
					if part:IsA("BasePart") then
						local point=plot.Foundation.CFrame:PointToObjectSpace(part.Position)
						assert(point.X+part.Size.Magnitude/2< -128,"Campfire yard entered the final foundation")
					end
				end
			end
		end)
		test("campfire reservations are flat and clear at every plot",function()
			local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
			local Topography=require(Game.Topography)
			for id=1,8 do
				local plot=sync(id,catalog[(id-1)%#catalog+1],50,1)
				for _,offset in {Vector3.zero,Vector3.new(-13,0,-13),Vector3.new(13,0,13),Camp.pad-Camp.center} do
					local point=plot.Foundation.CFrame:PointToWorldSpace(Camp.center+offset)
					assert(Topography.isReserved(point,0,true))
					assert(math.abs(Topography.sampleHeight(point.X,point.Z)-.15)<.001)
				end
				local filter=OverlapParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.RespectCanCollide=true
				filter.FilterDescendantsInstances={plot.Settlement,plot.Infrastructure}
				for x=-136,-36,10 do
					local frame=plot.Foundation.CFrame*CFrame.new(x,4,Camp.center.Z)
					assert(#workspace:GetPartBoundsInBox(frame,Vector3.new(6,5,6),filter)==0,"Blocked camp approach at "..x)
				end
			end
		end)
		test("camp rallies and restored geometry follow moved plots",function()
			local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
			world.model:PivotTo(CFrame.new(2400,17,-2100)*CFrame.Angles(0,.43,0)*world.model:GetPivot())
			for id=1,8 do
				local plot=sync(id,catalog[1],50,1)
				for _,slot in {"warrior","ranged","camp"} do
					local point=plot.Foundation.CFrame:PointToObjectSpace(world:getArmyRally(id,slot).Position)
					local delta=point-Camp.center
					assert(math.abs(delta.X)<=Camp.size.X/2 and math.abs(delta.Z)<=Camp.size.Z/2)
					assert(Vector3.new(delta.X,0,delta.Z).Magnitude>=6)
				end
			end
		end)
		return cases
	end)
	container:Destroy();assert(ok,result);return result
end

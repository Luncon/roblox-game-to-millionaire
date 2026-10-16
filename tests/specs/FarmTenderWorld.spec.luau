return function()
	local Infrastructure=require(game.ServerScriptService.Game.SettlementInfrastructure)
	local Tenders=require(game.ServerScriptService.Game.FarmTenders)
	local civs=require(game.ReplicatedStorage.Shared.Civilizations)
	local root=Instance.new("Model");root.Name="FarmTenderFixture";root.Parent=workspace
	local plots=Instance.new("Folder");plots.Name="Plots";plots.Parent=root
	local plot=Instance.new("Model");plot.Parent=plots
	local foundation=Instance.new("Part");foundation.Name="Foundation";foundation.Anchored=true;foundation.Parent=plot
	local state={level=12,farmLevel=1,workersLevel=0,farmCoins=0}
	local cases=0
	local ok,result=pcall(function()
		for _,civ in civs do
			for _,tiers in {{1,0},{1,1},{2,2}}do
				state.farmLevel,state.workersLevel=tiers[1],tiers[2]
				Infrastructure.sync(plot,foundation.CFrame,civ,state)
				local farm=plot.Infrastructure.Farmland
				assert(farm:GetAttribute("WorkerCount")==1+tiers[2])
				for index=1,1+tiers[2]do
					local farmer=farm["Farmer"..index]
					assert(farmer:FindFirstChild("UpperTorso"),"Farm still uses the procedural farmer")
					assert(farmer:GetAttribute("PassiveWorker") and not farmer.Humanoid.EvaluateStateMachine)
				end
			end
		end
		cases+=1
		local farm=plot.Infrastructure.Farmland
		local farmers={farm.Farmer1,farm.Farmer2,farm.Farmer3}
		local initial=foundation.CFrame:PointToObjectSpace(farmers[1]:GetPivot().Position)
		local now=farmers[1]:GetAttribute("TendingStartedAt")+7
		Infrastructure.animate(root,now)
		local point=foundation.CFrame:ToObjectSpace(farmers[1]:GetPivot())
		assert((point.Position-initial).Magnitude>8,"Farmer did not walk into the crop row")
		for _,reserve in {1,4,59,60,0}do
			state.farmCoins=reserve;Infrastructure.sync(plot,foundation.CFrame,civs[#civs],state)
			assert(plot.Infrastructure.Farmland==farm and farm.Farmer1==farmers[1],"Reserve tick restarted the routine")
		end
		cases+=1
		foundation.CFrame=CFrame.new(900,17,-650)*CFrame.Angles(0,.61,0)
		Infrastructure.animate(root,now)
		local moved=foundation.CFrame:ToObjectSpace(farmers[1]:GetPivot())
		assert((point.Position-moved.Position).Magnitude<.002,"Routine snapped to its original world frame")
		for _,farmer in farmers do
			local sample=Tenders.sample(2,now-farmer:GetAttribute("TendingStartedAt"),farmer:GetAttribute("WorkerIndex"))
			local p=foundation.CFrame:PointToObjectSpace(farmer:GetPivot().Position)
			assert(math.abs(p.X-sample.X)<.002 and math.abs(p.Z-sample.Z)<.002)
		end
		cases+=1
		Infrastructure.sync(plot,foundation.CFrame,civs[1],state)
		assert(farm.Parent==nil and plot.Infrastructure.Farmland~=farm,"Civilization switch retained old workers")
		Infrastructure.sync(plot,foundation.CFrame,nil,nil)
		assert(#plot.Infrastructure:GetChildren()==0)
		Infrastructure.animate(root,now+100)
		cases+=1
		return cases
	end)
	root:Destroy();assert(ok,result);return result
end

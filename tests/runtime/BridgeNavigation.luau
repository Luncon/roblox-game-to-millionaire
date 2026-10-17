-- Actual server-owned Humanoids traverse every generated crossing, with an
-- offset approach that would otherwise take the shorter route through water.
return function()
	assert(game:GetService("RunService"):IsStudio())
	local Game=game.ServerScriptService.Game
	local Map,Rig,Navigator,Water=require(Game.BattlefieldMap),require(Game.WarriorRig),require(Game.WarriorNavigator),require(Game.WaterNavigation)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local folder=Instance.new("Folder");folder.Name="BridgeTraversalFixture";folder.Parent=workspace
	local navigator,rig,connection
	local active,failure=true,nil
	local cases,evidence=0,{}
	local ok,result=pcall(function()
		local world=Map.build(folder)
		local transform=CFrame.new(3200,12,-2600)*CFrame.Angles(0,.3,0)
		world.model:PivotTo(transform*world.model:GetPivot())
		-- Native navigation tiles update asynchronously after this fresh map build.
		task.wait(2)
		local bridges={}
		for _,bridge in world.model.Landscape.Waterways:GetChildren() do
			if bridge:FindFirstChild("BridgeDeck") then table.insert(bridges,bridge) end
		end
		table.sort(bridges,function(a,b)return a:GetAttribute("PlotId")<b:GetAttribute("PlotId")end)
		for index,bridge in bridges do for _,direction in {1,-1} do
			local deck=bridge.BridgeDeck
			local length=deck.Size.Z/2+42
			local start=deck.CFrame:PointToWorldSpace(Vector3.new(24,4,direction*length))
			local goal=deck.CFrame:PointToWorldSpace(Vector3.new(24,4,-direction*length))
			local kind=({"warrior","ranged","medic"})[index]
			assert(Water.allowsDirect(world.model,start,start) and Water.allowsDirect(world.model,goal,goal),"Offset fixture endpoints must be on dry banks")
			game:SetAttribute("BridgeNavigationVerificationPhase","Bridge "..bridge:GetAttribute("PlotId").." "..kind.." direction "..direction)
			rig=Rig.create(catalog[1],CFrame.new(start),-99001,1,nil,kind)
			rig.Parent=world.model.Troops
			rig.HumanoidRootPart:SetNetworkOwner(nil)
			navigator=Navigator.new(rig,function()return active end)
			local crossed=false
			local last=rig.HumanoidRootPart.Position
			connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
				local success,message=pcall(function()
					navigator:step(os.clock())
					local position=rig.HumanoidRootPart.Position
					assert((position-last).Magnitude<8+dt*45,"Bridge traversal teleported")
					last=position
					assert(Water.allowsDirect(world.model,position,position),"Troop entered water at "..tostring(deck.CFrame:PointToObjectSpace(position)).." instead of bridge "..bridge:GetAttribute("PlotId"))
					local localPoint=deck.CFrame:PointToObjectSpace(position)
					if math.abs(localPoint.X)<deck.Size.X/2-2 and math.abs(localPoint.Z)<4 then crossed=true end
					Rig.animate(rig,os.clock(),rig.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5,false)
				end)
				if not success then failure=tostring(message) end
			end)
			task.wait(.5)
			local started=os.clock()
			navigator:setGoal(goal)
			local arrived=false
			repeat
				assert(not failure,failure)
				local delta=rig.HumanoidRootPart.Position-goal
				arrived=Vector3.new(delta.X,0,delta.Z).Magnitude<2.1
				task.wait(.05)
			until arrived or os.clock()-started>25
			assert(arrived,"Troop stuck approaching bridge "..bridge:GetAttribute("PlotId").." direction "..direction..": "..tostring(rig:GetAttribute("NavigationStatus")))
			assert(crossed,"Troop bypassed the intended bridge")
			assert(rig.Humanoid.Health==rig.Humanoid.MaxHealth and rig.HumanoidRootPart:GetNetworkOwner()==nil)
			table.insert(evidence,{plotId=bridge:GetAttribute("PlotId"),direction=direction,class=kind,seconds=os.clock()-started})
			cases+=1
			connection:Disconnect();connection=nil
			navigator:destroy();navigator=nil
			rig:Destroy();rig=nil
		end end
		return {ok=true,cases=cases,evidence=evidence}
	end)
	active=false
	if connection then connection:Disconnect() end
	if navigator then navigator:destroy() end
	folder:Destroy()
	assert(ok,result)
	return result
end

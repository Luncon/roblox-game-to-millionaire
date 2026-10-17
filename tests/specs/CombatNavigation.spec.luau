return function()
	local Navigator=require(game.ServerScriptService.Game.WarriorNavigator)
	local Water=require(game.ServerScriptService.Game.WaterNavigation)
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local folder=Instance.new("Folder");folder.Name="CombatNavigationFixture";folder.Parent=workspace
	local world=Map.build(folder)
	local rig=Rig.createNeutral(CFrame.new(0,4,0),"warrior");rig.Parent=world.model.Troops
	local nav=Navigator.new(rig,function()return true end)
	local ok,result=pcall(function()
		assert(type(nav.walkCombat)=="function","Precise guarded combat steering is missing")
		local arena=world.model.Battlefield
		assert(nav:walkCombat(Vector3.new(5,4,0),world),"Clear close combat step was rejected")
		local wall=Instance.new("Part");wall.Size=Vector3.new(2,12,8);wall.CFrame=CFrame.new(3,5,0);wall.Anchored=true;wall.Parent=world.model
		assert(not nav:walkCombat(Vector3.new(7,4,0),world),"Direct combat movement passed through a wall")
		wall:Destroy()
		assert(not nav:walkCombat(Vector3.new(900,4,0),world),"Combat steering left the arena or accepted a long path")
		nav:stop()
		local river=world.model.Landscape.Waterways.ShallowRiver
		local water
		for _,segment in river:GetChildren() do if segment:GetAttribute("SegmentIndex")==9 then water=segment end end
		assert(water)
		local centre=water.Position+Vector3.new(0,4,0)
		rig:PivotTo(CFrame.new(centre-water.CFrame.RightVector*14))
		assert(not nav:walkCombat(centre-water.CFrame.RightVector*2,world),"Combat steering shortcuts into river water")
		assert(not Water.allowsDirect(world.model,centre-water.CFrame.RightVector*14,centre+water.CFrame.RightVector*14),"A dry destination allowed a shortcut across the river")
		assert(Water.allowsDirect(world.model,centre,centre-water.CFrame.RightVector*16),"A displaced troop cannot escape water")
		local query=RaycastParams.new();query.FilterType=Enum.RaycastFilterType.Include
		query.FilterDescendantsInstances={world.model.Landscape.Waterways.NavigationRegions}
		assert(not workspace:Spherecast(centre-water.CFrame.RightVector*16,.25,water.CFrame.RightVector*32,query),"Water costs block combat or bandage flight height")
		for _,bridge in world.model.Landscape.Waterways:GetChildren() do
			local deck=bridge:FindFirstChild("BridgeDeck")
			if not deck then continue end
			local a=deck.CFrame:PointToWorldSpace(Vector3.new(0,4,8))
			local b=deck.CFrame:PointToWorldSpace(Vector3.new(0,4,-8))
			assert(Water.allowsDirect(world.model,a,b),"Dry bridge rejected as water")
			rig:PivotTo(CFrame.new(a))
			assert(nav:walkCombat(b,world),"Supported combat footwork on a bridge was rejected")
		end
		local transform=CFrame.new(2300,20,-1800)*CFrame.Angles(0,.7,0)
		local dryStart=centre-water.CFrame.RightVector*14
		world.model:PivotTo(transform*world.model:GetPivot())
		assert(not Water.allowsDirect(world.model,transform:PointToWorldSpace(dryStart),transform:PointToWorldSpace(centre)),"Transformed river lost its water guard")
		nav:stop()
		return 14
	end)
	nav:destroy();folder:Destroy();assert(ok,result);return result
end

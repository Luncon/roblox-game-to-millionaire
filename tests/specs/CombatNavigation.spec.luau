return function()
	local Navigator=require(game.ServerScriptService.Game.WarriorNavigator)
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
		return 3
	end)
	nav:destroy();folder:Destroy();assert(ok,result);return result
end

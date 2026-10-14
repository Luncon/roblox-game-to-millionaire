return function()
	local module=game.ServerScriptService.Game:FindFirstChild("TroopProjectile")
	assert(module,"TroopProjectile is not implemented yet")
	local Projectile=require(module)
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local container=Instance.new("Folder")
	container.Name="RejectedProjectileFixture"
	container.Parent=workspace
	local projectile=nil
	local ok,result=pcall(function()
		local world=Map.build(container)
		local combat={}
		function combat:actor() return nil end
		function combat:hit() error("Invalid launch reached damage authority") end
		projectile=Projectile.new(world,combat)
		local shooter,target=Instance.new("Model"),Instance.new("Model")
		shooter.Parent=container
		target.Parent=container
		assert(not projectile:fire(shooter,target),"Unregistered actor launched a projectile")
		assert(projectile:count()==0,"Rejected launch allocated an active shot")
		projectile:step(.5)
		projectile:cancel(shooter)
		assert(projectile:count()==0)
		print("PASS: unregistered ranged launches never allocate shots or reach damage authority")
		return 1
	end)
	if projectile then projectile:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

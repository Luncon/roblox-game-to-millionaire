return function()
	local module=game.ServerScriptService.Game:FindFirstChild("CombatService")
	assert(module,"CombatService is not implemented yet")
	local Combat=require(module)
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local Registry=require(game.ServerScriptService.Game.ClaimRegistry)
	local Economy=require(game.ServerScriptService.Game.Economy)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name="UnregisteredCombatFixture"
	container.Parent=workspace
	local combat=nil
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local registry=Registry.new(8,{sparta=true,britain=true})
		local economy=Economy.new()
		economy:open(989898)
		economy:open(989899)
		registry:claim(989898,"sparta")
		registry:claim(989899,"britain")
		combat=Combat.new(world,registry,economy,function() end)
		local attacker=Rig.create(catalog[1],CFrame.new(0,5,0),989898,1)
		local target=Rig.create(catalog[2],CFrame.new(3,5,0),989899,2)
		attacker.Parent=world.model.Troops
		target.Parent=world.model.Troops
		test("unregistered rigs cannot deal damage or generate currency",function()
			assert(not combat:hit(attacker,target).ok)
			assert(target.Humanoid.Health==100 and economy:get(989898).coins==0)
		end)
		test("disconnected owners cannot become authoritative combat actors",function()
			combat:register(attacker,989898,"warrior")
			combat:register(target,989899,"warrior")
			assert(combat:actor(attacker)==nil and combat:actor(target)==nil)
			assert(not combat:hit(attacker,target).ok)
		end)
		test("environmental death without an accepted final hit cannot award a kill",function()
			target.Humanoid.Health=0
			assert(economy:get(989898).coins==0 and economy:get(989899).coins==0)
		end)
		return count
	end)
	if combat then combat:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

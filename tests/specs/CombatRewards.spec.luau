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
		test("controlled actor fixtures preserve fractional mid and max damage and award one lethal final hit",function()
			-- Deliberately replace ONLY the actor interface boundary. These tables are
			-- not connected Players; the earlier test retains that production guard.
			-- hit(), raycast visibility, rules, Humanoid damage and rewards stay real.
			attacker:Destroy();target:Destroy()
			local actors={}
			combat.actor=function(_,rig)
				local actor=actors[rig]
				return if actor and actor.humanoid.Health>0 then actor else nil
			end
			local function actor(rig,ownerId,kind,civ)
				actors[rig]={rig=rig,ownerId=ownerId,kind=kind,civilizationId=civ,plotId=if ownerId==989898 then 1 else 2,
					position=rig.HumanoidRootPart.Position,alive=true,claimed=true,humanoid=rig.Humanoid,root=rig.HumanoidRootPart,
					player={Parent=game:GetService("Players")}}
			end
			for _,level in {25,50} do for _,kind in {"warrior","ranged"} do
				assert(economy:replace(989898,{coins=0,level=50,weaponLevel=level,armorLevel=1,barracksLevel=1}))
				local source=Rig.create(catalog[1],CFrame.new(0,5,0),989898,1,{weaponLevel=level,armorLevel=1},kind)
				local victim=Rig.create(catalog[2],CFrame.new(3,5,0),989899,2)
				source.Parent,victim.Parent=world.model.Troops,world.model.Troops
				actor(source,989898,kind,"sparta");actor(victim,989899,"warrior","britain")
				local expected=(10+8*(level-1)/49)*(if kind=="ranged" then .8 else 1)
				local first=combat:hit(source,victim)
				assert(first.ok and not first.killed and math.abs(first.damage-expected)<.002)
				assert(math.abs(victim.Humanoid.Health-(100-expected))<.002 and economy:get(989898).coins==0)
				local finisher=Rig.create(catalog[1],CFrame.new(0,5,0),989898,1,{weaponLevel=level,armorLevel=1},kind)
				source:Destroy();finisher.Parent=world.model.Troops;actor(finisher,989898,kind,"sparta")
				victim.Humanoid.Health=expected-.05
				local final=combat:hit(finisher,victim)
				local diagnostic={level=level,kind=kind,expected=expected,final=final,health=victim.Humanoid.Health,
					coins=economy:get(989898).coins,visible=combat:visible(actors[finisher],actors[victim])}
				local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude;filter.FilterDescendantsInstances={finisher}
				local sight=workspace:Raycast(finisher.HumanoidRootPart.Position+Vector3.new(0,1,0),victim.HumanoidRootPart.Position-finisher.HumanoidRootPart.Position,filter)
				diagnostic.raycast=if sight then sight.Instance:GetFullName() else "clear"
				-- TakeDamage can expose fractional overkill below zero immediately;
				-- the authoritative death boundary is nonpositive health.
				assert(final.ok and final.killed and final.reward and final.reward.ok and victim.Humanoid.Health<=0 and economy:get(989898).coins==10,
					"Fractional lethal fixture: "..game:GetService("HttpService"):JSONEncode(diagnostic))
				assert(not combat:hit(finisher,victim).ok and economy:get(989898).coins==10 and economy:get(989899).coins==0)
				finisher:Destroy();victim:Destroy()
			end end
		end)
		return count
	end)
	if combat then combat:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

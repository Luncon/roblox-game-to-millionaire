-- One real client, production services and explicit fake persistence only.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
	local service=context.service
	local Game=game.ServerScriptService.Game
	local Rig=require(Game.WarriorRig)
	local Data=require(Game.ProfileData)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local Skills=require(game.ReplicatedStorage.Shared.WeaponSkillConfig)
	local arena=service.world.model.Battlefield
	local cases,evidence=0,{}
	local function test(name,fn)
		game:SetAttribute("WeaponSkillsVerificationPhase",name);fn();cases+=1;print("PASS: "..name)
	end
	local function waitFor(predicate,label,seconds)
		local deadline=os.clock()+(seconds or 8)
		repeat if predicate()then return end;task.wait(.02)until os.clock()>deadline
		error("Timed out: "..label)
	end
	local function choose(id)
		if player:GetAttribute("CivilizationId")==id then return end
		round("civilizationInput",{action="choose",civilization=id},30)
		waitFor(function()return player.Character:GetAttribute("EquipmentCivilization")==id end,"equipped "..id)
		task.wait(.4)
	end
	local function point(x,z,clearance)
		local p=arena.Position+Vector3.new(x,0,z)
		local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include
		filter.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
		local ground=workspace:Raycast(p+Vector3.new(0,40,0),Vector3.new(0,-100,0),filter)
		assert(ground,"No real ground for skill fixture")
		return Vector3.new(p.X,ground.Position.Y+(clearance or 3),p.Z)
	end
	local function stage(civ,skill,barracks,camp)
		local value=Data.defaultState()
		value.level,value.weaponLevel,value.trainingLevel,value.skillLevel,value.coins=50,50,1,skill,1000
		value.barracksLevel,value.armyCampLevel=barracks or 1,if camp then 1 else 0
		assert(service.profiles:set(player.UserId,civ,value))
	end
	if not service.registry:get(player.UserId)then choose("sparta")end
	-- All mutations here are to the explicitly fake store; never stage player data.
	if player:GetAttribute("CivilizationId")=="britain" then choose("sparta")end
	stage("britain",0,4,true);stage("vikings",2);stage("maurya",2)
	choose("britain")
	assert(service.command(player,"order","hold").ok)
	service.neutralOpponents:destroy()
	local neutral=Instance.new("Folder");neutral.Name="NeutralOpponents";neutral.Parent=service.world.model
	local dummies,extras={},{}
	local function clear()
		for _,rig in dummies do service.combat:unregister(rig);rig:Destroy()end
		table.clear(dummies)
		for _,item in extras do
			if item:IsA("Model")then service.combat:unregister(item)end
			item:Destroy()
		end
		table.clear(extras)
	end
	local function dummy(position)
		local rig=Rig.createNeutral(CFrame.new(position),"warrior")
		rig.Parent=neutral;rig.HumanoidRootPart.Anchored=true
		rig.Humanoid.MaxHealth,rig.Humanoid.Health=1000,1000
		assert(service.combat:registerNeutral(rig,"warrior"));table.insert(dummies,rig)
		return rig
	end
	local function positionPlayer(position)
		local root=player.Character.HumanoidRootPart
		root.Anchored=false
		player.Character:PivotTo(CFrame.lookAt(position,position+Vector3.new(0,0,-1)))
		root.AssemblyLinearVelocity=Vector3.zero
		task.wait(.2)
	end
	local function ready()
		waitFor(function()return workspace:GetServerTimeNow()>=(player.Character:GetAttribute("WeaponSkillReadyAt") or 0)end,"skill cooldown",14)
	end
	local function wall(x,z)
		local part=Instance.new("Part");part.Name="WeaponSkillCollisionFixture"
		part.Anchored=true;part.Size=Vector3.new(6,8,1);part.Position=point(x,z,4)
		part.Parent=service.world.model;table.insert(extras,part)
		return part
	end
	local ok,message=pcall(function()
		test("native camp pad buys sequential tiers without replacing troops or healing them",function()
			local claim=service.registry:get(player.UserId)
			local pad=service.world.model.Plots["Plot"..claim.plotId].Controls.SkillButton
			local owner=service.army:get(player.UserId);local troop=owner.rig
			troop.Humanoid.Health=60
				owner.slots.ranged.rig.Humanoid.Health=0
				waitFor(function()return service.army:get(player.UserId).slots.ranged.rig==nil end,"pending ranged replacement")
				local pending=service.army:get(player.UserId).slots.ranged.respawnAt
				local camp=owner.slots.camp.rig
			local deadline=troop:GetAttribute("WeaponSkillReadyAt")
			for tier=1,2 do
				positionPlayer((pad.CFrame*CFrame.new(-10,3,0)).Position)
				local response=round("developmentInput",{kind="pad",action="skill"},30)
				local observed=service.economy:get(player.UserId)
				assert(observed.skillLevel==tier,"Expected skill tier "..tier..", got "..observed.skillLevel.."; coins="..observed.coins.."; native="..game.HttpService:JSONEncode(response))
				assert(service.army:get(player.UserId).rig==troop and troop.Humanoid.Health<65)
					local after=service.army:get(player.UserId)
					assert(after.slots.ranged.respawnAt==pending and after.slots.ranged.rig==nil,"Skill purchase changed a pending replacement")
					assert(after.slots.camp.rig==camp and player:GetAttribute("TroopCapacity")==3)
				assert((troop:GetAttribute("WeaponSkillReadyAt") or 0)<workspace:GetServerTimeNow()+.1)
			end
			assert(service.economy:get(player.UserId).coins==700)
			assert(pad.Parent and (deadline or 0)<workspace:GetServerTimeNow())
				evidence.purchase={tiers=2,coinsSpent=300,livingPreserved=true,pendingRespawnPreserved=true,campPreserved=true}
		end)
		for _,entry in {{"britain","sword",4},{"vikings","axe",4},{"maurya","spear",8}} do
			test("native R activates "..entry[2].." with real protected damage",function()
				clear();choose(entry[1]);assert(service.command(player,"order","hold").ok)
				local position=point(0,0)
				positionPlayer(position)
				local victim=dummy(point(0,-entry[3],3))
				local before=victim.Humanoid.Health
				local original=player.Character.HumanoidRootPart.Position
				local result=round("skillInput",nil,10);assert(result.accepted,tostring(result.reason))
				local tier=Skills.tiers[2]
				local multiplier=if entry[2]=="sword" then tier.sword+tier.second else tier[entry[2]]
				local dealt=before-victim.Humanoid.Health
				assert(math.abs(dealt-Tracks.weapon[50].damage*multiplier)<.01,"Unexpected "..entry[2].." damage: "..dealt)
				local delta=player.Character.HumanoidRootPart.Position-original
				if entry[2]=="spear"then assert(Vector3.new(delta.X,0,delta.Z).Magnitude>1 and delta.Magnitude<=11)end
				local again=round("skillInput",nil,6);assert(not again.accepted and again.reason=="cooldown")
				assert(math.abs(before-victim.Humanoid.Health-dealt)<.01)
				evidence[entry[2]]={damage=dealt,displacement=delta.Magnitude,cooldown=Skills.families[entry[2]].cooldown}
			end)

		end
		test("actual dash collision stops before a wall without damaging an obscured target",function()
			clear();ready();positionPlayer(point(0,0))
			local victim=dummy(point(0,-8));wall(0,-4)
			local origin=player.Character.HumanoidRootPart.Position
			assert(round("skillInput",nil,10).accepted)
			local delta=player.Character.HumanoidRootPart.Position-origin
			assert(victim.Humanoid.Health==1000 and Vector3.new(delta.X,0,delta.Z).Magnitude<3.5)
			evidence.dashWall={damage=1000-victim.Humanoid.Health,displacement=delta.Magnitude}
		end)
		test("dash remains inside the unchanged arena boundary",function()
			clear();ready();positionPlayer(point(0,-246))
			local origin=player.Character.HumanoidRootPart.Position
			assert(round("skillInput",nil,10).accepted)
			local final=player.Character.HumanoidRootPart.Position
			assert(require(Game.CombatRules).containsArena(arena,final),"Dash escaped the protected combat boundary")
			assert((final-origin).Magnitude<5)
			evidence.dashBoundary={displacement=(final-origin).Magnitude,inside=true}
		end)
		test("player skill activation is rejected outside the battlefield",function()
			clear();positionPlayer(point(0,-260))
			local victim=dummy(point(0,-264))
			local result=round("skillInput",nil,6)
			assert(not result.accepted and result.reason=="protected" and victim.Humanoid.Health==1000)
		end)
		test("an actual target escaping after slash one avoids the second contact",function()
			clear();choose("britain");assert(service.command(player,"order","hold").ok);ready()
			positionPlayer(point(0,0));local victim=dummy(point(0,-4))
			local escaped=false
			local connection=victim.Humanoid.HealthChanged:Connect(function(health)
				if health<1000 and not escaped then escaped=true;victim:PivotTo(CFrame.new(point(0,-25)))end
			end)
			assert(round("skillInput",nil,10).accepted);connection:Disconnect()
			local dealt=1000-victim.Humanoid.Health
			assert(escaped and math.abs(dealt-18*Skills.tiers[2].sword)<.01)
			evidence.comboEscape={damage=dealt,secondMissed=true}
		end)
		test("spin caps actual targets protects friendlies and grants each lethal reward once",function()
			clear();choose("vikings");assert(service.command(player,"order","hold").ok);ready()
			positionPlayer(point(0,0))
			local victims={dummy(point(2,0)),dummy(point(-3,0)),dummy(point(0,-4))}
			for _,rig in victims do rig.Humanoid.Health=1 end
			local overflow=dummy(point(3.4,-3.4));local blocked=dummy(point(0,5.5));wall(0,4)
			local civ;for _,candidate in require(game.ReplicatedStorage.Shared.Civilizations)do if candidate.id=="vikings"then civ=candidate end end
			local claim=service.registry:get(player.UserId)
			local friendly=Rig.create(civ,CFrame.new(point(1,1)),player.UserId,claim.plotId,service.economy:get(player.UserId))
			friendly.Parent=service.world.model.Troops;friendly.HumanoidRootPart.Anchored=true
			assert(service.combat:register(friendly,player.UserId,"warrior"));table.insert(extras,friendly)
			local health=friendly.Humanoid.Health;local coins=service.economy:get(player.UserId).coins
			assert(round("skillInput",nil,10).accepted)
			for _,rig in victims do assert(rig.Humanoid.Health==0)end
			assert(overflow.Humanoid.Health==1000 and blocked.Humanoid.Health==1000 and friendly.Humanoid.Health==health)
			assert(service.economy:get(player.UserId).coins==coins+30)
			assert(not round("skillInput",nil,6).accepted and service.economy:get(player.UserId).coins==coins+30)
			evidence.spinRewards={kills=3,coins=30,overflowProtected=true,friendlyProtected=true,wallProtected=true}
		end)
		test("owned melee troop automatically uses its weapon-family skill",function()
			clear();choose("vikings");positionPlayer(service.world:getSpawn(service.registry:get(player.UserId).plotId).Position)
			local owned=service.army:get(player.UserId).rig
			local position=point(30,0)
			owned:PivotTo(CFrame.lookAt(position,position+Vector3.new(0,0,-1)))
			owned.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
			local victim=dummy(point(30,-4))
			assert(service.command(player,"order","advance").ok)
			waitFor(function()return (owned:GetAttribute("WeaponSkillReadyAt") or 0)>workspace:GetServerTimeNow()+5 end,"automatic axe skill")
			waitFor(function()return victim.Humanoid.Health<1000 end,"automatic skill contact")
			task.wait(.35) -- Respect the army-command cooldown during cleanup.
			assert(service.command(player,"order","hold").ok)
		end)
		for _,entry in {{"sparta","spear"},{"rome","spear"},{"vikings","axe"}}do
			test("ranged "..entry[1].." troop uses its close-range skill with role damage",function()
				clear()
				if player:GetAttribute("CivilizationId")==entry[1]then choose("britain")end
				stage(entry[1],2,4);choose(entry[1]);assert(service.command(player,"order","hold").ok)
				positionPlayer(service.world:getSpawn(service.registry:get(player.UserId).plotId).Position)
				local ranged=service.army:get(player.UserId).slots.ranged.rig
				waitFor(function()return workspace:GetServerTimeNow()>=(ranged:GetAttribute("WeaponSkillReadyAt") or 0)end,"preserved ranged skill cooldown",10)
				task.wait(.35) -- Hold permits ordinary shots; advance before introducing a hostile.
				assert(service.command(player,"order","advance").ok)
				local position=point(30,0)
				ranged:PivotTo(CFrame.lookAt(position,position+Vector3.new(0,0,-1)))
				ranged.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
				local victim=dummy(point(30,-4))
				waitFor(function()return (ranged:GetAttribute("WeaponSkillReadyAt") or 0)>workspace:GetServerTimeNow()+5 end,"ranged automatic skill")
				waitFor(function()return victim.Humanoid.Health<1000 end,"ranged skill contact")
				local expected=18*.8*Skills.tiers[2][entry[2]]
				assert(math.abs(1000-victim.Humanoid.Health-expected)<.01,"Ranged "..entry[1].." damage="..(1000-victim.Humanoid.Health).." expected="..expected)
				waitFor(function()return ranged:GetAttribute("WeaponSkillActive")==nil end,"ranged skill recovery")
				assert(math.abs(1000-victim.Humanoid.Health-expected)<.01,"An ordinary projectile overlapped skill recovery")
				assert(service.command(player,"order","hold").ok)
				evidence["ranged_"..entry[1]]={damage=1000-victim.Humanoid.Health,overlap=false,serverOwned=ranged.HumanoidRootPart:GetNetworkOwner()==nil}
				assert(evidence["ranged_"..entry[1]].serverOwned)
			end)
		end
	end)
	clear();neutral:Destroy()
	assert(ok,message)
	return {ok=true,cases=cases,evidence=evidence,message="One client: native skill pads/R and automatic troop attack against fake profiles"}
end

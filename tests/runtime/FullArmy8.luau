-- Eight real players with fixture-funded profiles; physical purchases are a separate suite.
return function(players)
	local T=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) return math.abs(actual-expected)<.002 end
	local Players = game:GetService("Players")
	assert(#players==8,"Full army test requires eight real Studio players")
	local Game=game.ServerScriptService.Game
	local WarriorService=require(Game.WarriorService)
	local Map=require(Game.BattlefieldMap)
	local Registry=require(Game.ClaimRegistry)
	local Economy=require(Game.Economy)
	local Rules=require(Game.CombatRules)
	local civilizations=require(game.ReplicatedStorage.Shared.Civilizations)
	local supported,catalog,saved={}, {}, {}
	for _,civ in civilizations do supported[civ.id]=true; catalog[civ.id]=civ end
	local known={}
	for _,player in players do
		assert(player.Parent==Players and not known[player.UserId],"Owners must be distinct real players")
		known[player.UserId]=true
		local character=player.Character
		assert(character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid"))
		saved[player]={pivot=character:GetPivot(),anchored=character.HumanoidRootPart.Anchored,
			health=character.Humanoid.Health,attributes={}}
		for _,name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do saved[player].attributes[name]=player:GetAttribute(name) end
	end
	local container=Instance.new("Folder")
	container.Name="FullArmy8Fixture"
	container.Parent=workspace
	local service=nil
	local connections={}
	local cases=0
	local function now() return workspace:GetServerTimeNow() end
	local function test(name,callback) callback(); cases+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(0,0,-1800)*world.model:GetPivot())
		local registry=Registry.new(8,supported)
		local clock=0
		local economy=Economy.new(function() return clock end)
		test("eight isolated profiles own eight distinct civilization plots",function()
			for index,player in players do
				local civ=civilizations[index]
				local claim=registry:claim(player.UserId,civ.id)
				assert(claim.ok and claim.claim.plotId==index)
				economy:open(player.UserId)
				for _=1,55 do assert(economy:earn(player.UserId).ok); clock+=.1 end
				assert(economy:upgrade(player.UserId,1).ok)
				assert(economy:upgrade(player.UserId,1,"weapon").ok)
				assert(economy:upgrade(player.UserId,1,"armor").ok)
				clock+=1
				world:setOwner(index,civ,player.UserId,player.DisplayName,2)
				player.Character.HumanoidRootPart.Anchored=true
				player.Character:PivotTo(world:getSpawn(index))
			end
			assert(registry:claim(-989898,civilizations[9].id).reason=="full")
		end)
		service=WarriorService.start(world,registry,economy,catalog)
		local initial,reached,models,deaths,replacements={}, {}, {}, {}, {}
		local damageEvents=0
		local unexpectedDamage=nil
		local ownerDamaged=false
		local function observe(player,rig)
			if models[rig] then return end
			models[rig]=true
			local ownerId=player.UserId
			if initial[ownerId] and rig~=initial[ownerId] then
				assert(deaths[ownerId] and now()>=deaths[ownerId]+14.9,"Replacement appeared before fifteen seconds")
				assert(near(rig.Humanoid.MaxHealth,T.armor[2].health) and near(rig.Humanoid.Health,T.armor[2].health))
				replacements[ownerId]=true
			end
			assert(near(rig:GetAttribute("WarriorDamage"),T.weapon[2].damage) and rig:GetAttribute("WeaponLevel")==2 and rig:GetAttribute("ArmorLevel")==2)
			local previousHealth=rig.Humanoid.Health
			table.insert(connections,rig.Humanoid.HealthChanged:Connect(function(health)
				if health<previousHealth then
					if math.abs((previousHealth-health)-math.min(T.weapon[2].damage,previousHealth))>.002 then unexpectedDamage=previousHealth-health end
					damageEvents+=1
				end
				previousHealth=health
			end))
			table.insert(connections,rig.Humanoid.Died:Connect(function() deaths[ownerId]=now() end))
		end
		test("all eight barracks deploy one server-owned warrior with inherited gear",function()
			for _,player in players do
				service:refresh(player)
				local rig=service:get(player.UserId).rig
				assert(rig and near(rig.Humanoid.Health,T.armor[2].health) and rig.HumanoidRootPart:GetNetworkOwner()==nil)
				initial[player.UserId]=rig
				observe(player,rig)
				local previousHealth=player.Character.Humanoid.Health
				table.insert(connections,player.Character.Humanoid.HealthChanged:Connect(function(health)
					if health<previousHealth then ownerDamaged=true end
					previousHealth=health
				end))
			end
			assert(#world.model.Troops:GetChildren()==8)
			for _=1,3 do for _,player in players do service:refresh(player); assert(service:get(player.UserId).rig==initial[player.UserId]) end end
		end)
		local function audit()
			local liveCounts={}
			local total=0
			assert(#world.model.Troops:GetChildren()<=16,"Corpses accumulated without a bound")
			for _,rig in world.model.Troops:GetChildren() do
				local ownerId=rig:GetAttribute("OwnerId")
				assert(known[ownerId],"Army contains an unknown owner")
				local humanoid=rig:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health>0 then
					liveCounts[ownerId]=(liveCounts[ownerId] or 0)+1
					total+=1
					assert(liveCounts[ownerId]==1,"Owner has multiple living warriors")
					assert(rig.HumanoidRootPart:GetNetworkOwner()==nil)
				end
			end
			assert(total<=8)
			for _,player in players do
				local entry=service:get(player.UserId)
				if entry and entry.rig then observe(player,entry.rig) end
				local rig=initial[player.UserId]
				local root=rig:FindFirstChild("HumanoidRootPart")
				if root and Rules.containsArena(world.model.Battlefield,root.Position) then reached[player.UserId]=true end
			end
			assert(not ownerDamaged,"An owner outside the arena received damage")
			assert(unexpectedDamage==nil,"Eight-army combat dealt an unexpected damage amount: "..tostring(unexpectedDamage))
		end
		test("every original civilization warrior reaches the arena under eight-owner load",function()
			local deadline=now()+90
			repeat
				audit()
				local count=0
				for _ in reached do count+=1 end
				if count==8 then return end
				task.wait(.1)
			until now()>deadline
			local missing={}
			for _,player in players do
				if not reached[player.UserId] then
					local rig=initial[player.UserId]
					table.insert(missing,tostring(player.UserId)..":"..tostring(rig:GetAttribute("NavigationStatus")))
				end
			end
			error("Original warriors failed to reach arena: "..table.concat(missing,", "))
		end)
		test("eight-owner army performs actual melee damage and death",function()
			local deadline=now()+20
			repeat
				audit()
				if damageEvents>=2 and next(deaths) then return end
				task.wait(.1)
			until now()>deadline
			error("No actual NPC combat death under full-server load")
		end)
		test("natural combat replacement waits fifteen seconds and stays within per-owner cap",function()
			local deadline=now()+20
			repeat
				audit()
				if next(replacements) then return end
				task.wait(.1)
			until now()>deadline
			error("No automatic replacement observed after actual full-server combat death")
		end)
		return {ok=true,cases=cases,owners=8,damageEvents=damageEvents,
			message="Eight real owners with fixture-funded barracks: simultaneous eight units, every civilization's navigation, actual combat/death/15-second replacement, server physics, cap, and outside-owner immunity passed"}
	end)
	for _,connection in connections do connection:Disconnect() end
	if service then service:destroy() end
	container:Destroy()
	for _,player in players do
		local original=saved[player]
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.Anchored=original.anchored
			player.Character:PivotTo(original.pivot)
			local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health>0 then humanoid.Health=math.min(original.health,humanoid.MaxHealth) end
		end
		for _,name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do player:SetAttribute(name,original.attributes[name]) end
	end
	assert(ok,result)
	return result
end

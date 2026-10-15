-- Two real test players; actual pathfinding, server attack loops, and Humanoid damage.
return function(firstPlayer,secondPlayer)
	local Players = game:GetService("Players")
	assert(firstPlayer and secondPlayer and firstPlayer ~= secondPlayer)
	assert(firstPlayer.Parent == Players and secondPlayer.Parent == Players)
	local Game = game.ServerScriptService.Game
	local WarriorService = require(Game.WarriorService)
	local Map = require(Game.BattlefieldMap)
	local Registry = require(Game.ClaimRegistry)
	local Economy = require(Game.Economy)
	local Rules = require(Game.CombatRules)
	local Config = require(game.ReplicatedStorage.Shared.WarriorConfig)
	local civilizations = require(game.ReplicatedStorage.Shared.Civilizations)
	local catalog,supported = {},{}
	for _, civ in civilizations do catalog[civ.id]=civ; supported[civ.id]=true end
	local players = {firstPlayer,secondPlayer}
	local saved = {}
	for _, player in players do
		local character = player.Character
		assert(character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid"))
		saved[player] = {pivot=character:GetPivot(),anchored=character.HumanoidRootPart.Anchored,
			health=character:FindFirstChildOfClass("Humanoid").Health,attributes={}}
		for _, name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do
			saved[player].attributes[name] = player:GetAttribute(name)
		end
	end
	local container = Instance.new("Folder")
	container.Name = "WarriorCombatFixture"
	container.Parent = workspace
	local service = nil
	local connections = {}
	local cases = 0
	local function now() return workspace:GetServerTimeNow() end
	local function waitFor(predicate,description,timeout)
		local deadline = now()+(timeout or 4)
		repeat if predicate() then return end; task.wait(.05) until now()>deadline
		error("Timed out: " .. description)
	end
	local function test(name,callback) callback(); cases+=1; print("PASS: " .. name) end
	local function assertNoDamage(player,duration,message)
		local humanoid = player.Character.Humanoid
		local previous,damage = humanoid.Health,nil
		local connection = humanoid.HealthChanged:Connect(function(health)
			if health<previous then damage=previous-health end
			previous=health
		end)
		task.wait(duration)
		connection:Disconnect()
		assert(damage==nil,message)
	end
	local function placePlayer(player,position)
		local character = player.Character
		character.HumanoidRootPart.Anchored = true
		character:PivotTo(CFrame.new(position))
	end
	local ok,result = pcall(function()
		local world = Map.build(container)
		world.model:PivotTo(CFrame.new(-1400,0,1400)*world.model:GetPivot())
		local registry = Registry.new(8,supported)
		local clock = 0
		local economy = Economy.new(function() return clock end)
		for index,player in players do
			local id = if index==1 then "sparta" else "britain"
			assert(registry:claim(player.UserId,id).ok)
			economy:open(player.UserId)
			local wanted = if index==1 then 2 else 4
			for level,price in {25,35,45} do
				if level>=wanted then break end
				for _=1,price do assert(economy:earn(player.UserId).ok); clock+=.1 end
				assert(economy:upgrade(player.UserId,level).ok)
				clock+=1
			end
			world:setOwner(index,catalog[id],player.UserId,player.DisplayName,wanted)
			placePlayer(player,world:getSpawn(index).Position)
		end
		service = WarriorService.start(world,registry,economy,catalog)
		for _,player in players do service:refresh(player) end
		local rigs = {service:get(firstPlayer.UserId).rig,service:get(secondPlayer.UserId).rig}
		local arena = world.model.Battlefield
		test("warriors physically leave village and citadel to reach the arena",function()
			local reached = {}
			local previous = {rigs[1].HumanoidRootPart.Position,rigs[2].HumanoidRootPart.Position}
			local sampledAt = now()
			local deadline = now()+120
			repeat
				local currentTime = now()
				for index,rig in rigs do
					local root = rig.HumanoidRootPart
					assert(root:GetNetworkOwner()==nil and not root.Anchored)
					assert((root.Position-previous[index]).Magnitude <= math.max(8,(currentTime-sampledAt)*45),
						"Warrior jumped position instead of walking")
					previous[index] = root.Position
					if Rules.containsArena(arena,root.Position) then reached[index]=true end
				end
				if reached[1] and reached[2] then return end
				sampledAt = currentTime
				task.wait(.1)
			until now()>deadline
			error("Navigation failed: village=" .. tostring(reached[1]) .. " citadel=" .. tostring(reached[2])
				.. " villagePos=" .. tostring(rigs[1].HumanoidRootPart.Position)
				.. " citadelPos=" .. tostring(rigs[2].HumanoidRootPart.Position)
				.. " citadelStatus=" .. tostring(rigs[2]:GetAttribute("NavigationStatus")))
		end)
		local drops = {{},{}}
		test("hostile NPCs exchange inherited damage with a one-second cooldown until death",function()
			for index,rig in rigs do
				rig.HumanoidRootPart.Anchored = true
				rig:PivotTo(CFrame.new(arena.Position+Vector3.new(if index==1 then -2 else 2,4,0)))
				local previousHealth = rig.Humanoid.Health
				table.insert(connections,rig.Humanoid.HealthChanged:Connect(function(health)
					if health<previousHealth then table.insert(drops[index],{time=now(),amount=previousHealth-health}) end
					previousHealth = health
				end))
			end
			waitFor(function() return rigs[1].Humanoid.Health<=0 or rigs[2].Humanoid.Health<=0 end,"actual NPC melee death",15)
			for _,events in drops do
				assert(#events>=2,"Both NPCs must actually deal damage")
				for i,event in events do
					assert(event.amount==10,"NPC dealt an unexpected damage amount")
					if i>1 then assert(event.time-events[i-1].time>=Config.attackCooldown-.05,"Cooldown allowed rapid attacks") end
				end
			end
		end)
		local winnerIndex = if rigs[1].Humanoid.Health>0 then 1 else 2
		local loserIndex = if winnerIndex==1 then 2 else 1
		local warrior,owner,enemy = rigs[winnerIndex],players[winnerIndex],players[loserIndex]
		service:release(enemy.UserId) -- Keep its claim, cancel its dead army's replacement during controlled combat checks.
		local origin = arena.Position+Vector3.new(-2,4,0)
		warrior:PivotTo(CFrame.new(origin))
		test("line-of-sight blocker prevents claimed player damage",function()
			placePlayer(enemy,arena.Position+Vector3.new(2,4,0))
			local blocker = Instance.new("Part")
			blocker.Name="CombatSightBlocker"
			blocker.Size=Vector3.new(1,14,8)
			blocker.CFrame=CFrame.new(arena.Position+Vector3.new(0,5,0))
			blocker.Anchored=true
			blocker.CanCollide=false
			blocker.Parent=container
			assertNoDamage(enemy,2.3,"NPC damaged a player through a wall")
			blocker:Destroy()
		end)
		test("claimed hostile player receives actual server melee damage",function()
			local previous,damage=enemy.Character.Humanoid.Health,nil
			local connection=enemy.Character.Humanoid.HealthChanged:Connect(function(health)
				if health<previous then damage=previous-health end
				previous=health
			end)
			table.insert(connections,connection)
			waitFor(function() return damage~=nil end,"claimed hostile player damage",3)
			connection:Disconnect()
			assert(damage==10)
		end)
		test("owner remains immune inside melee reach in the arena",function()
			placePlayer(enemy,world:getSpawn(loserIndex).Position)
			placePlayer(owner,origin+Vector3.new(3,0,0))
			assertNoDamage(owner,2.3,"Owner received friendly damage")
		end)
		test("claimed target outside arena remains immune even within melee reach",function()
			placePlayer(owner,world:getSpawn(winnerIndex).Position)
			warrior:PivotTo(CFrame.new(arena.Position+Vector3.new(arena.Size.Y/2-2,4,0)))
			placePlayer(enemy,arena.Position+Vector3.new(arena.Size.Y/2+1,4,0))
			assert((warrior.HumanoidRootPart.Position-enemy.Character.HumanoidRootPart.Position).Magnitude<5)
			assertNoDamage(enemy,2.3,"Outside player received damage within reach")
			assert(warrior:GetAttribute("WarriorState")=="Guarding","Outside target was still being pursued")
		end)
		test("unclaimed player inside the arena remains immune",function()
			registry:release(enemy.UserId)
			warrior:PivotTo(CFrame.new(origin))
			placePlayer(enemy,origin+Vector3.new(3,0,0))
			assertNoDamage(enemy,2.3,"Unclaimed player received damage")
		end)
		test("actual owner character resets preserve living identity and pending deadline",function()
			owner:LoadCharacterAsync()
			service:refresh(owner)
			assert(service:get(owner.UserId).rig==warrior)
			warrior.Humanoid.Health=0
			waitFor(function() return service:get(owner.UserId).respawnAt>now() end,"reset test death deadline")
			local deadline=service:get(owner.UserId).respawnAt
			owner:LoadCharacterAsync()
			service:refresh(owner)
			assert(service:get(owner.UserId).rig==nil and service:get(owner.UserId).respawnAt==deadline)
		end)
		return {ok=true,cases=cases,message="Actual village/citadel navigation, NPC melee death/cooldown, LOS, claimed-player damage, owner/outside/neutral immunity, and character resets passed"}
	end)
	for _,connection in connections do connection:Disconnect() end
	if service then service:destroy() end
	container:Destroy()
	for _,player in players do
		local original=saved[player]
		local character=player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.Anchored=original.anchored
			character:PivotTo(original.pivot)
			local humanoid=character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health>0 then humanoid.Health=math.min(original.health,humanoid.MaxHealth) end
		end
		for _,name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do player:SetAttribute(name,original.attributes[name]) end
	end
	assert(ok,result)
	return result
end

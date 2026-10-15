-- Three real owners, five actual army slots, no NPC teleports after deployment.
return function(first,second,third)
	local Players,Run=game:GetService("Players"),game:GetService("RunService")
	local owners={first,second,third}
	local Game=game.ServerScriptService.Game
	local Map,Registry,Economy,Service,Rules=require(Game.BattlefieldMap),require(Game.ClaimRegistry),require(Game.Economy),require(Game.WarriorService),require(Game.CombatRules)
	local catalog,known={},{}
	for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do catalog[civ.id]=civ;known[civ.id]=true end
	local attributes={"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"}
	local saved={}
	for _,player in owners do
		assert(player and player.Parent==Players and player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
		local state={pivot=player.Character:GetPivot(),anchored=player.Character.HumanoidRootPart.Anchored,attributes={}}
		for _,name in attributes do state.attributes[name]=player:GetAttribute(name) end
		saved[player]=state
	end
	local container=Instance.new("Folder")
	container.Name,container.Parent="ExpandedArmyMovementFixture",workspace
	local service,heartbeat
	local connections,records={},{}
	local damageEvents,deaths,ownerDamage=0,0,0
	local failure
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function waitFor(predicate,description,seconds)
		local deadline=os.clock()+seconds
		repeat assert(not failure,failure);if predicate() then return end;task.wait(.1) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(2600,0,2600)*world.model:GetPivot())
		local registry,economy=Registry.new(8,known),Economy.new()
		local ids,levels,barracks={"sparta","britain","seneca"},{2,25,50},{1,4,4}
		for index,player in owners do
			assert(registry:claim(player.UserId,ids[index]).ok)
			assert(economy:open(player.UserId,{coins=0,level=levels[index],weaponLevel=levels[index],armorLevel=levels[index],barracksLevel=barracks[index]}))
			world:setOwner(index,catalog[ids[index]],player.UserId,player.DisplayName,levels[index])
			player.Character.HumanoidRootPart.Anchored=true
			player.Character:PivotTo(world:getSpawn(index))
			local previous=player.Character.Humanoid.Health
			table.insert(connections,player.Character.Humanoid.HealthChanged:Connect(function(health) if health<previous then ownerDamage+=1 end;previous=health end))
		end
		local arena=world.model.Battlefield
		service=Service.start(world,registry,economy,catalog)
		test("starter intermediate and finished settlements deploy five server-owned correctly inherited troop slots",function()
			for index,player in owners do
				service:refresh(player)
				local entry=service:get(player.UserId)
				for kind,slot in entry.slots do
					local rig=slot.rig
					assert(rig and rig.HumanoidRootPart:GetNetworkOwner()==nil and not rig.HumanoidRootPart.Anchored)
					local factor=if kind=="ranged" then .8 else 1
					assert(math.abs(rig:GetAttribute("WarriorDamage")-(10+8*(levels[index]-1)/49)*factor)<.002)
					assert(math.abs(rig.Humanoid.MaxHealth-(100+40*(levels[index]-1)/49))<.002)
					local record={rig=rig,ownerId=player.UserId,kind=kind,level=levels[index],started=os.clock(),last=rig.HumanoidRootPart.Position,lastTime=os.clock()}
					table.insert(records,record)
					local health=rig.Humanoid.Health
					table.insert(connections,rig.Humanoid.HealthChanged:Connect(function(value) if value<health then damageEvents+=1 end;health=value end))
					table.insert(connections,rig.Humanoid.Died:Connect(function() deaths+=1 end))
				end
			end
			assert(#records==5)
		end)
		heartbeat=Run.Heartbeat:Connect(function()
			local valid,message=pcall(function()
				for _,record in records do
					local root=record.rig:FindFirstChild("HumanoidRootPart")
					if not root or not root:IsDescendantOf(workspace) or record.rig.Humanoid.Health<=0 then continue end
					local now=os.clock()
					local delta=root.Position-record.last
					assert(Vector3.new(delta.X,0,delta.Z).Magnitude<=8+(now-record.lastTime)*45,"NPC jumped instead of walking")
					assert(root:GetNetworkOwner()==nil)
					record.last,record.lastTime=root.Position,now
					if not record.arrival and Rules.containsArena(arena,root.Position) then record.arrival=now-record.started end
				end
			end)
			if not valid then failure=tostring(message) end
		end)
		test("all five automatic troops physically reach the expanded arena from levels two twenty-five and fifty",function()
			waitFor(function()
				for _,record in records do if not record.arrival then return false end end
				return true
			end,"five measured army arrivals",120)
			for _,record in records do assert(record.arrival>5 and record.arrival<120) end
		end)
		test("arriving hostile armies exchange damage and die while settlement owners remain protected",function()
			waitFor(function() return damageEvents>0 and deaths>0 end,"natural combat after arrival",35)
			assert(ownerDamage==0,"Army damaged a player on its protected settlement")
			for _,player in owners do service:release(player.UserId) end
			assert(#world.model.Troops:GetChildren()==0,"Army release left a living unit or corpse behind")
		end)
		local arrivals={}
		for _,record in records do arrivals[tostring(record.ownerId)..":"..record.kind]={level=record.level,seconds=record.arrival} end
		return {ok=true,cases=cases,arrivalSeconds=arrivals,damageEvents=damageEvents,deaths=deaths,
			message="Three owners and five inherited slots physically traversed the expanded world, entered combat and preserved protected owners"}
	end)
	if heartbeat then heartbeat:Disconnect() end
	for _,connection in connections do connection:Disconnect() end
	if service then service:destroy() end
	container:Destroy()
	for _,player in owners do
		local character=player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then character.HumanoidRootPart.Anchored=saved[player].anchored;character:PivotTo(saved[player].pivot) end
		for _,name in attributes do player:SetAttribute(name,saved[player].attributes[name]) end
	end
	assert(ok,result)
	return result
end

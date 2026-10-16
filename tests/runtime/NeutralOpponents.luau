-- One connected owner, production combat and an explicitly injected fake store.
return function(context,player)
	assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
	local service=context.service
	local Game=game.ServerScriptService.Game
	local Rig=require(Game.WarriorRig)
	local Neutral=require(Game.NeutralOpponentService)
	local Config=require(game.ReplicatedStorage.Shared.NeutralOpponentConfig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local units=service.neutralOpponents
	local cases=0
	local evidence={}
	local function waitFor(predicate,label,timeout)
		local deadline=os.clock()+(timeout or 4)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..label)
	end
	local function test(name,fn)
		game:SetAttribute("NeutralTestPhase",name)
		fn();cases+=1;print("PASS: "..name)
	end
	local function move(rig,position,look)
		rig.HumanoidRootPart.Anchored=true
		rig:PivotTo(if look then CFrame.lookAt(position,look) else CFrame.new(position))
	end
	local function center(x,z)
		return service.world.model.Battlefield.Position+Vector3.new(x,5,z)
	end
	local ok,result=pcall(function()
		waitFor(function()return service.profiles:isWritable(player.UserId) and player.Character end,"writable fake profile")
		test("three generic center opponents exist without claims",function()
			local slots=units:get();local n=0
			for _,slot in slots do
				n+=1;assert(slot.rig and slot.rig.Humanoid.Health==100)
				assert(slot.rig:GetAttribute("OwnerId")==nil and slot.rig:GetAttribute("CivilizationId")==nil)
				assert((slot.rig.HumanoidRootPart.Position-slot.spawnFrame.Position).Magnitude<5)
				assert(slot.rig.HumanoidRootPart:GetNetworkOwner()==nil)
			end
			assert(n==3 and slots.melee1.kind=="warrior" and slots.melee2.kind=="warrior" and slots.ranged.kind=="ranged")
		end)
		test("all thirteen connected civilizations and their troops can damage neutrals",function()
			evidence.civilizations={}
			for _,civ in catalog do
				assert(service.select(player,civ.id,service.registry:get(player.UserId)~=nil).ok)
				task.wait(.35) -- deferred spawn/equipment restore
				local slots=units:get()
				move(slots.melee1.rig,center(0,0));move(slots.melee2.rig,center(80,0));move(slots.ranged.rig,center(-80,0))
				local victim=slots.melee1.rig
				local target=service.combat:actor(victim).position
				move(player.Character,target+Vector3.new(0,0,3),target)
				player.Character.Humanoid.Health=player.Character.Humanoid.MaxHealth
				victim.Humanoid.Health=100
				service.playerCombat:release(player.UserId)
				local hit=service.playerCombat:attack(player)
				assert(hit.ok and hit.damage==10,"Player melee rejected for "..civ.id..": "..tostring(hit.reason))
				local claim=service.registry:get(player.UserId)
				local troop=Rig.create(civ,CFrame.new(target+Vector3.new(3,0,0)),player.UserId,claim.plotId)
				troop.Parent=service.world.model.Troops;troop.HumanoidRootPart.Anchored=true
				assert(service.combat:register(troop,player.UserId,"warrior"))
				local troopHit=service.combat:hit(troop,victim)
				assert(troopHit.ok and troopHit.damage==10,"Troop rejected for "..civ.id)
				troop:Destroy()
				table.insert(evidence.civilizations,civ.id)
			end
		end)
		test("valid neutral final hits award exactly ten coins",function()
			local victim=units:get().melee1.rig
			local before=service.economy:get(player.UserId).coins
			victim.Humanoid.Health=10
			service.playerCombat:release(player.UserId)
			local hit=service.playerCombat:attack(player)
			assert(hit.ok and hit.killed and hit.reward.ok and service.economy:get(player.UserId).coins==before+10)
			assert(not service.combat:hit(player.Character,victim).ok and service.economy:get(player.UserId).coins==before+10)
		end)
		test("staggered deaths preserve independent ten-second deadlines and survivors",function()
			move(player.Character,center(0,180))
			waitFor(function()return units:get().melee1.rig==nil end,"melee death notification")
			local first=units:get().melee1.respawnAt
			assert(first-workspace:GetServerTimeNow()>9)
			local survivor=units:get().melee2.rig
			task.wait(3)
			units:get().ranged.rig.Humanoid.Health=0
			waitFor(function()return units:get().ranged.rig==nil end,"ranged death notification")
			local second=units:get().ranged.respawnAt
			assert(second-first>=2.9)
			assert(service.select(player,"sparta",true).ok)
			task.wait(.35)
			assert(units:get().melee1.respawnAt==first and units:get().ranged.respawnAt==second)
			while workspace:GetServerTimeNow()<first do
				assert(units:get().melee1.rig==nil,"Early melee replacement");task.wait(.05)
			end
			waitFor(function()return units:get().melee1.rig~=nil end,"melee replacement",2)
			local firstObserved=workspace:GetServerTimeNow()
			assert(units:get().ranged.rig==nil and units:get().melee2.rig==survivor)
			waitFor(function()return units:get().ranged.rig~=nil end,"ranged replacement",5)
			local secondObserved=workspace:GetServerTimeNow()
			assert(firstObserved>=first and secondObserved>=second and units:get().melee2.rig==survivor)
			assert(units:get().melee1.rig.Humanoid.Health==100 and units:get().ranged.rig.Humanoid.Health==100)
			assert(#service.world.model.NeutralOpponents:GetChildren()==3,"Duplicate replacement or retained corpse")
			evidence.respawn={meleeDeadline=first,meleeObserved=firstObserved,rangedDeadline=second,rangedObserved=secondObserved}
		end)
		test("native melee pursuit and ranged projectile flight damage a connected owner",function()
			local slots=units:get()
			move(slots.melee1.rig,center(-10,0));move(slots.melee2.rig,center(100,0));move(slots.ranged.rig,center(-100,0))
			local root=slots.melee1.rig.HumanoidRootPart
			move(player.Character,center(0,0))
			player.Character.Humanoid.Health=100
			root.Anchored=false;root:SetNetworkOwner(nil)
			local start=root.Position
			waitFor(function()return player.Character.Humanoid.Health<100 end,"neutral native melee",12)
			assert((root.Position-start).Magnitude>3,"Melee fighter did not walk")
			move(slots.melee1.rig,center(100,30))
			move(slots.ranged.rig,center(0,-25))
			player.Character.Humanoid.Health=100
			local observed=false
			local connection=game:GetService("RunService").Heartbeat:Connect(function()
				for _,folder in service.world.model:GetChildren() do
					if folder.Name=="TroopProjectiles" and #folder:GetChildren()>0 then observed=true end
				end
			end)
			local success,message=pcall(function()waitFor(function()return player.Character.Humanoid.Health<100 end,"neutral arrow impact",5)end)
			connection:Disconnect();assert(success,message)
			assert(observed and player.Character.Humanoid.Health==92,"Ranged flight/damage was not observed")
		end)
		test("disabled opposition creates no fighters",function()
			local world={model=Instance.new("Model")};world.model.Parent=workspace
			local arena=Instance.new("Part");arena.Name="Battlefield";arena.Parent=world.model
			local disabled=Neutral.start(world,service.combat,{enabled=false})
			assert(next(disabled:get())==nil)
			disabled:destroy();world.model:Destroy()
		end)
		test("owner upgrades and orders preserve neutral health and pending timers",function()
			move(player.Character,center(0,180))
			local slots=units:get()
			slots.melee2.rig.Humanoid.Health=0
			waitFor(function()return units:get().melee2.rig==nil end,"second melee death")
			local deadline=units:get().melee2.respawnAt
			local health=slots.melee1.rig.Humanoid.Health
			local state=service.economy:get(player.UserId)
			assert(service.economy:replace(player.UserId,{coins=state.coins,level=10,weaponLevel=2,armorLevel=2,
				barracksLevel=4,trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1}))
			service.army:refresh(player)
			for _,order in {"hold","regroup","advance"} do
				assert(service.command(player,"order",order).ok)
				task.wait(.35)
				assert(units:get().melee1.rig==slots.melee1.rig and slots.melee1.rig.Humanoid.Health==health)
				assert(units:get().melee2.respawnAt==deadline)
			end
			assert(player:GetAttribute("TroopCapacity")==3 and player:GetAttribute("ArmyCount")==3)
			assert(service.economy:replace(player.UserId,state))
			service.army:refresh(player)
		end)
		test("removing a generated world cleans neutral combat resources",function()
			local world={model=Instance.new("Model")}
			for _,name in {"Ground","Battlefield"} do
				local part=service.world.model[name]:Clone()
				part.CFrame=CFrame.new(3200,0,3200)*part.CFrame;part.Parent=world.model
			end
			world.model.Parent=workspace
			local combat=require(Game.CombatService).new(world,service.registry,service.economy)
			local temporary=Neutral.start(world,combat)
			local dead=temporary:get().melee1.rig;dead.Humanoid.Health=0
			world.model.Parent=nil
			task.wait(.3)
			for _,slot in temporary:get() do assert(slot.rig==nil and slot.respawnAt==0) end
			assert(#combat:actors()==0 and #world.model:GetChildren()==2)
			temporary:destroy();combat:destroy();world.model:Destroy()
		end)
		test("destroyed neutral rigs schedule replacement and shutdown cancels pending spawns",function()
			move(player.Character,center(0,180))
			local slots=units:get()
			slots.melee1.rig:Destroy()
			waitFor(function()return units:get().melee1.rig==nil end,"destroy notification")
			units:destroy()
			assert(not service.world.model:FindFirstChild("NeutralOpponents"))
			for _,slot in units:get() do assert(slot.rig==nil and slot.respawnAt==0) end
			task.wait(Config.respawnDelay+.3)
			assert(not service.world.model:FindFirstChild("NeutralOpponents"))
			for _,actor in service.combat:actors() do assert(not actor.neutral) end
		end)
		return {cases=cases,evidence=evidence}
	end)
	if player.Character then player.Character.HumanoidRootPart.Anchored=false end
	assert(ok,result)
	return result
end

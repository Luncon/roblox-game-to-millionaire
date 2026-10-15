-- Real heartbeat flight and segment collisions using the authoritative combat service.
return function(first,second)
	local Players=game:GetService("Players")
	local RunService=game:GetService("RunService")
	assert(first~=second and first.Parent==Players and second.Parent==Players)
	local Game=game.ServerScriptService.Game
	local Map,Registry,Economy,Rig,Combat,Projectile=require(Game.BattlefieldMap),require(Game.ClaimRegistry),require(Game.Economy),require(Game.WarriorRig),require(Game.CombatService),require(Game.TroopProjectile)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name="ActualProjectileFixture"
	container.Parent=workspace
	local combat,projectiles,heartbeat=nil,nil,nil
	local cases=0
	local function test(name,callback) callback(); cases+=1; print("PASS: "..name) end
	local function waitFor(predicate,description,timeout)
		local deadline=os.clock()+(timeout or 3)
		repeat if predicate() then return end; task.wait(.02) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(-1800,0,0)*world.model:GetPivot())
		local registry=Registry.new(8,{sparta=true,britain=true})
		registry:claim(first.UserId,"sparta")
		registry:claim(second.UserId,"britain")
		local economy=Economy.new()
		economy:open(first.UserId); economy:open(second.UserId)
		combat=Combat.new(world,registry,economy)
		projectiles=Projectile.new(world,combat)
		local observedMovement=false
		local shotOrigins={}
		heartbeat=RunService.Heartbeat:Connect(function(dt)
			projectiles:step(dt)
			for _,part in world.model.TroopProjectiles:GetChildren() do
				if shotOrigins[part] and (part.Position-shotOrigins[part]).Magnitude>1 then observedMovement=true end
			end
		end)
		local arena=world.model.Battlefield
		local function position(x,z) return arena.Position+Vector3.new(x,4,z or 0) end
		local function rig(owner,civ,kind,x,z,health)
			local model=Rig.create(civ,CFrame.new(position(x,z)),owner.UserId,if owner==first then 1 else 2,economy:get(owner.UserId),kind)
			model.Parent=world.model.Troops
			model.HumanoidRootPart.Anchored=true
			if health then model.Humanoid.Health=health end
			assert(combat:register(model,owner.UserId,kind))
			return model
		end
		local function setup(shooterX,targetX,targetHealth)
			world.model.Troops:ClearAllChildren()
			observedMovement=false
			local shooter=rig(first,catalog[1],"ranged",shooterX or -20,0)
			local target=rig(second,catalog[2],"warrior",targetX or 20,0,targetHealth)
			return shooter,target
		end
		local function fire(shooter,target)
			assert(projectiles:fire(shooter,target))
			for _,part in world.model.TroopProjectiles:GetChildren() do shotOrigins[part]=part.Position end
		end
		test("visible projectile travels over real frames before damaging an enemy",function()
			local shooter,target=setup()
			local started=os.clock()
			fire(shooter,target)
			assert(projectiles:count()==1 and target.Humanoid.Health==100,"Ranged fire dealt instant damage")
			waitFor(function() return target.Humanoid.Health<100 end,"actual projectile impact")
			assert(target.Humanoid.Health==92 and projectiles:count()==0)
			assert(observedMovement and os.clock()-started>=.3,"Projectile did not show bounded flight time")
		end)
		test("an obstacle appearing during flight absorbs the shot without damage",function()
			local shooter,target=setup()
			fire(shooter,target)
			local wall=Instance.new("Part")
			wall.Size=Vector3.new(1,12,6)
			wall.CFrame=CFrame.new(position(0,0))
			wall.Anchored=true; wall.Parent=container
			waitFor(function() return projectiles:count()==0 end,"projectile wall collision")
			assert(target.Humanoid.Health==100)
			wall:Destroy()
		end)
		test("friendly and unregistered bodies stop shots rather than passing damage through",function()
			for _,registered in {true,false} do
				local shooter,target=setup()
				fire(shooter,target)
				local blocker=rig(first,catalog[1],"warrior",0,0)
				if not registered then combat:unregister(blocker) end
				waitFor(function() return projectiles:count()==0 end,"protected body collision")
				assert(target.Humanoid.Health==100 and blocker.Humanoid.Health==100)
			end
		end)
		test("target crossing the arena boundary before impact cannot receive damage",function()
			local shooter,target=setup(arena.Size.Y/2-35,arena.Size.Y/2-1)
			fire(shooter,target)
			target:PivotTo(CFrame.new(position(arena.Size.Y/2+1,0)))
			local filter=RaycastParams.new()
			filter.FilterType=Enum.RaycastFilterType.Exclude;filter.FilterDescendantsInstances={shooter}
			local intercept=workspace:Raycast(shooter.HumanoidRootPart.Position+Vector3.new(0,1,0),Vector3.new(44,0,0),filter)
			assert(intercept and intercept.Instance:IsDescendantOf(target),"Outside-target fixture does not intercept the fixed projectile path")
			waitFor(function() return projectiles:count()==0 end,"outside-target projectile impact")
			assert(target.Humanoid.Health==100)
		end)
		test("fixed-aim shots miss targets that move aside and expire at maximum travel",function()
			local shooter,target=setup()
			fire(shooter,target)
			target:PivotTo(CFrame.new(position(20,12)))
			waitFor(function() return projectiles:count()==0 end,"nonhoming projectile expiry")
			assert(target.Humanoid.Health==100)
		end)
		test("a lethal projectile awards exactly ten once through shared combat authority",function()
			local original=economy:get(first.UserId)
			local fractional=table.clone(original)
			fractional.level,fractional.weaponLevel=2,2
			assert(economy:replace(first.UserId,fractional))
			local damage=(10+8/49)*.8
			local shooter,target=setup(nil,nil,damage-.05)
			assert(math.abs(shooter:GetAttribute("WarriorDamage")-damage)<.002)
			local before=economy:get(first.UserId).coins
			fire(shooter,target)
			waitFor(function() return target.Humanoid.Health<=0 end,"ranged final hit")
			assert(economy:get(first.UserId).coins==before+10)
			assert(not projectiles:fire(shooter,target))
			assert(projectiles:count()==0 and economy:get(first.UserId).coins==before+10)
			original.coins=before+10
			assert(economy:replace(first.UserId,original))
		end)
		test("projectiles are capped and canceled when shooter authority is removed",function()
			local shooter,target=setup()
			for _=1,32 do assert(projectiles:fire(shooter,target)) end
			assert(projectiles:count()==32 and not projectiles:fire(shooter,target))
			projectiles:cancel(shooter)
			assert(projectiles:count()==0)
			fire(shooter,target)
			combat:unregister(shooter)
			waitFor(function() return projectiles:count()==0 end,"retired-shooter shot cleanup")
			assert(target.Humanoid.Health==100)
		end)
		return {ok=true,cases=cases,message="Real projectile flight, collision, protected bodies, arena impact protection, fixed aim/expiry, final-hit reward, cap and authority cleanup passed"}
	end)
	if heartbeat then heartbeat:Disconnect() end
	if projectiles then projectiles:destroy() end
	if combat then combat:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

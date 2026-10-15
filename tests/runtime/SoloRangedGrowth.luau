-- Engine fixture with SIMULATED owners; this does not verify connected Players.
-- Only the private Combat.actor interface is controlled. Navigation, projectile
-- flight/raycast collision, rules, Humanoid damage and kill accounting stay real.
return function()
	local Run,Players=game:GetService("RunService"),game:GetService("Players")
	assert(Run:IsStudio(),"Solo ranged fixtures are Studio-only")
	local Game=game.ServerScriptService.Game
	local Map,Registry,Economy,Rig=require(Game.BattlefieldMap),require(Game.ClaimRegistry),require(Game.Economy),require(Game.WarriorRig)
	local Combat,Projectile,Navigator,Rules=require(Game.CombatService),require(Game.TroopProjectile),require(Game.WarriorNavigator),require(Game.CombatRules)
	local Ranged=require(game.ReplicatedStorage.Shared.RangedConfig)
	local Topography=require(Game.Topography)
	local catalog={}
	for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do catalog[civ.id]=civ end
	local container=Instance.new("Folder")
	container.Name,container.Parent="SoloSimulatedOwnerRangedFixture",workspace
	local combat,projectiles,heartbeat
	local contexts,actors,origins={},{},{}
	local active,failure=true,nil
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function flat(vector) return Vector3.new(vector.X,0,vector.Z) end
	local function waitFor(predicate,description,timeout)
		local deadline=os.clock()+(timeout or 4)
		repeat assert(not failure,failure);if predicate() then return end;task.wait(.02) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(3600,0,3600)*world.model:GetPivot())
		local arena=world.model.Battlefield
		local radius=math.max(arena.Size.Y,arena.Size.Z)/2
		local registry,economy=Registry.new(8,{sparta=true,britain=true,seneca=true}),Economy.new()
		local ownerIds={-88001,-88002,-88003}
		for index,id in {"sparta","britain","seneca"} do assert(registry:claim(ownerIds[index],id).ok) end
		assert(economy:open(ownerIds[3]))
		combat=Combat.new(world,registry,economy)
		combat.actor=function(_,model)
			local entry=actors[model]
			if not entry or not active or not model:IsDescendantOf(world.model.Troops) then return nil end
			local humanoid,root=model:FindFirstChildOfClass("Humanoid"),model:FindFirstChild("HumanoidRootPart")
			local claim=registry:get(entry.ownerId)
			if not humanoid or humanoid.Health<=0 or not root or not claim or not economy:get(entry.ownerId) then return nil end
			return {rig=model,ownerId=entry.ownerId,kind=entry.kind,civilizationId=claim.civilizationId,plotId=claim.plotId,
				position=root.Position,alive=true,claimed=true,humanoid=humanoid,root=root,player={Parent=Players}}
		end
		local function register(model,ownerId,kind)
			actors[model]={ownerId=ownerId,kind=kind}
			assert(combat:register(model,ownerId,kind))
		end
		projectiles=Projectile.new(world,combat)
		for index,level in {25,50} do
			local id=if index==1 then "sparta" else "britain"
			local ownerId=ownerIds[index]
			local state={coins=0,level=level,weaponLevel=level,armorLevel=level,barracksLevel=4}
			assert(economy:open(ownerId,state))
			world:setOwner(index,catalog[id],ownerId,"SimulatedRangedOwner",level)
			local model=Rig.create(catalog[id],world:getBarracksSpawn(index,"ranged"),ownerId,index,state,"ranged")
			model.Parent=world.model.Troops;model.HumanoidRootPart:SetNetworkOwner(nil)
			register(model,ownerId,"ranged")
			local start=model.HumanoidRootPart.Position
			local direction=flat(start-arena.Position).Unit
			local goal=arena.Position+direction*(radius-20)+Vector3.new(0,4,0)
			local context={rig=model,ownerId=ownerId,civ=id,level=level,start=start,goal=goal,started=os.clock(),last=start,lastTime=os.clock()}
			context.navigator=Navigator.new(model,function() return active and model.Parent~=nil end)
			context.navigator:setGoal(goal)
			table.insert(contexts,context)
		end
		heartbeat=Run.Heartbeat:Connect(function(dt)
			local success,message=pcall(function()
				for _,context in contexts do
					local root=context.rig.HumanoidRootPart
					if not context.arrived then
						context.navigator:step(os.clock())
						local now=os.clock()
						assert(flat(root.Position-context.last).Magnitude<=8+(now-context.lastTime)*45,"Ranged rig jumped instead of walking")
						context.last,context.lastTime=root.Position,now
						if Rules.containsArena(arena,root.Position) and flat(root.Position-context.goal).Magnitude<2 then
							context.arrived=true;context.duration=now-context.started
							context.distance=flat(root.Position-context.start).Magnitude
							context.navigator:stop()
						end
					end
					assert(root:GetNetworkOwner()==nil and not root.Anchored)
					Rig.animate(context.rig,os.clock(),root.AssemblyLinearVelocity.Magnitude>.5,false)
				end
				projectiles:step(dt)
				for _,part in world.model.TroopProjectiles:GetChildren() do
					local observation=origins[part]
					if observation and (part.Position-observation.start).Magnitude>1 then observation.context.observedFlight=true end
				end
			end)
			if not success then failure=tostring(message) end
		end)
		local function target(position)
			local model=Rig.create(catalog.seneca,CFrame.new(position),ownerIds[3],3)
			model.Parent=world.model.Troops;model.HumanoidRootPart.Anchored=true
			register(model,ownerIds[3],"warrior")
			return model
		end
		local function grounded(context,point)
			local root=context.rig.HumanoidRootPart.Position
			local source=world.model.Ground.CFrame:PointToObjectSpace(root)
			local destination=world.model.Ground.CFrame:PointToObjectSpace(point)
			local clearance=root.Y-Topography.sampleHeight(source.X,source.Z)
			return Vector3.new(point.X,Topography.sampleHeight(destination.X,destination.Z)+clearance,point.Z)
		end
		local function fire(context,victim)
			context.observedFlight=false
			local health=victim.Humanoid.Health
			local launched=projectiles:fire(context.rig,victim,Ranged.variants[context.civ].projectileKind)
			if not launched then
				local function vector(value) return {x=value.X,y=value.Y,z=value.Z} end
				local a,b=context.rig.HumanoidRootPart.Position,victim.HumanoidRootPart.Position
				local aLocal,bLocal=world.model.Ground.CFrame:PointToObjectSpace(a),world.model.Ground.CFrame:PointToObjectSpace(b)
				local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude
				filter.FilterDescendantsInstances={context.rig,world.model.TroopProjectiles}
				local hit=workspace:Raycast(a+Vector3.new(0,1,0),b-a,filter)
				local topography=Game:FindFirstChild("Topography")
				local sampled=if topography then require(topography) else nil
				local diagnostic={civilization=context.civ,level=context.level,shooter=vector(a),victim=vector(b),offsetDistance=(b-a).Magnitude,
					shooterInArena=Rules.containsArena(arena,a),victimInArena=Rules.containsArena(arena,b),
					shooterActor=combat:actor(context.rig)~=nil,victimActor=combat:actor(victim)~=nil,projectileCount=projectiles:count(),
					shooterGround=if sampled then sampled.sampleHeight(aLocal.X,aLocal.Z) else nil,
					victimGround=if sampled then sampled.sampleHeight(bLocal.X,bLocal.Z) else nil,
					obstruction=if hit then hit.Instance:GetFullName() else "clear",
					hitPosition=if hit then vector(hit.Position) else nil,
					blockedByVictim=if hit then hit.Instance:IsDescendantOf(victim) else false}
				error("Authorized ranged shot was rejected: "..game:GetService("HttpService"):JSONEncode(diagnostic))
			end
			assert(projectiles:count()==1 and victim.Humanoid.Health==health,"Projectile dealt instant damage")
			for _,part in world.model.TroopProjectiles:GetChildren() do origins[part]={start=part.Position,context=context} end
		end
		test("simulated-owner ranged troops physically walk from level twenty-five and fifty settlements into the expanded arena",function()
			waitFor(function() for _,context in contexts do if not context.arrived then return false end end;return true end,"two actual ranged marches",120)
			for _,context in contexts do
				local minimum=flat(context.start-arena.Position).Magnitude-radius
				assert(minimum>0 and context.distance>=minimum-5 and context.duration>5)
				assert(math.abs(context.rig.Humanoid.MaxHealth-(100+40*(context.level-1)/49))<.002)
			end
		end)
		local blockedEvidence={}
		test("new natural cover rejects blocked ranged launches without damage or kill credit",function()
			for _,context in contexts do
				local root=context.rig.HumanoidRootPart.Position
				local radial=flat(root-arena.Position).Unit
				local tangent=Vector3.new(-radial.Z,0,radial.X)
				local victim=target(grounded(context,root+tangent*35))
				local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Exclude
				filter.FilterDescendantsInstances={context.rig,world.model.TroopProjectiles}
				local hit=workspace:Raycast(root+Vector3.new(0,1,0),victim.HumanoidRootPart.Position-root,filter)
				if hit and not hit.Instance:IsDescendantOf(victim) then
					assert(combat:actor(context.rig) and combat:actor(victim))
					assert(Rules.containsArena(arena,root) and Rules.containsArena(arena,victim.HumanoidRootPart.Position))
					assert((victim.HumanoidRootPart.Position-root).Magnitude<Ranged.range)
					assert(not projectiles:fire(context.rig,victim) and projectiles:count()==0)
					assert(victim.Humanoid.Health==100 and economy:get(context.ownerId).coins==0)
					table.insert(blockedEvidence,{civilization=context.civ,obstruction=hit.Instance:GetFullName()})
				end
				victim:Destroy()
			end
			assert(#blockedEvidence>0,"Natural-cover reproduction found no blocked tangent sightline")
		end)
		test("real projectile frames and impacts preserve fractional level twenty-five and fifty damage",function()
			for _,context in contexts do
				local radial=flat(context.rig.HumanoidRootPart.Position-arena.Position).Unit
				-- Inward stays on the protected dry radial lane. Thirty-six studs
				-- leaves float32 margin while enforcing at least35 actual travel.
				context.victim=target(grounded(context,context.rig.HumanoidRootPart.Position-radial*36))
				assert((context.victim.HumanoidRootPart.Position-context.rig.HumanoidRootPart.Position).Magnitude>=35)
				context.damage=(10+8*(context.level-1)/49)*.8
				assert(math.abs(context.rig:GetAttribute("WarriorDamage")-context.damage)<.002)
				fire(context,context.victim)
				waitFor(function() return context.victim.Humanoid.Health<100 and projectiles:count()==0 end,"fractional projectile impact")
				context.lastImpact=os.clock()
				assert(context.observedFlight and math.abs(context.victim.Humanoid.Health-(100-context.damage))<.002)
				assert(economy:get(context.ownerId).coins==0)
			end
		end)
		test("fractional lethal projectiles credit exactly ten once for each simulated owner",function()
			for _,context in contexts do
				waitFor(function() return os.clock()>=context.lastImpact+Ranged.attackCooldown+.05 end,"real ranged attack cooldown")
				context.victim.Humanoid.Health=context.damage-.05
				fire(context,context.victim)
				waitFor(function() return context.victim.Humanoid.Health<=0 and projectiles:count()==0 end,"projectile final hit")
				assert(context.observedFlight and economy:get(context.ownerId).coins==10)
				assert(not projectiles:fire(context.rig,context.victim) and economy:get(context.ownerId).coins==10)
				context.victim:Destroy()
			end
			assert(economy:get(ownerIds[3]).coins==0)
		end)
		test("nearby outside-arena targets reject projectile launches without damage or credit",function()
			for _,context in contexts do
				local root=context.rig.HumanoidRootPart
				local radial=flat(root.Position-arena.Position).Unit
				local position=arena.Position+radial*(radius+1)
				local victim=target(Vector3.new(position.X,root.Position.Y,position.Z))
				assert(Rules.containsArena(arena,root.Position) and not Rules.containsArena(arena,victim.HumanoidRootPart.Position))
				assert((victim.HumanoidRootPart.Position-root.Position).Magnitude<Ranged.range,"Outside test accidentally exceeds projectile range")
				assert(not projectiles:fire(context.rig,victim) and projectiles:count()==0)
				assert(victim.Humanoid.Health==100 and economy:get(context.ownerId).coins==10)
				victim:Destroy()
			end
		end)
		local arrivals={}
		for _,context in contexts do arrivals[context.civ]={level=context.level,seconds=context.duration,distance=context.distance,damage=context.damage,coins=economy:get(context.ownerId).coins} end
		return {ok=true,cases=cases,simulatedOwners=true,arrivalEvidence=arrivals,blockedSightlines=blockedEvidence,
			message="Simulated-owner engine fixture: real ranged marches, natural-cover rejection, visible fractional projectile impacts, once-only final-hit credits and outside-arena launch protection passed; connected owner identity/networking unverified"}
	end)
	active=false
	if heartbeat then heartbeat:Disconnect() end
	for _,context in contexts do context.navigator:destroy() end
	if projectiles then projectiles:destroy() end
	if combat then combat:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

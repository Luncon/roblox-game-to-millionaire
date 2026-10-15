-- Five imported model assets, real Humanoid/Pathfinding movement; no claim or combat simulation.
return function(options)
	local T=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) return math.abs(actual-expected)<.002 end
	local RunService=game:GetService("RunService")
	local Physics=game:GetService("PhysicsService")
	local Game=game.ServerScriptService.Game
	local Map,Rig,Navigator,Rules=require(Game.BattlefieldMap),require(Game.WarriorRig),require(Game.WarriorNavigator),require(Game.CombatRules)
	local catalog={}
	for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do catalog[civ.id]=civ end
	local ids={"sparta","britain","japan","seneca","maurya"}
	local container=Instance.new("Folder")
	container.Name="ImportedMeleeMovementFixture"
	container.Parent=workspace
	local contexts={}
	local heartbeat=nil
	local active=true
	local asynchronousFailure=nil
	local cases=0
	local function test(name,callback) callback(); cases+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(1800,0,1800)*CFrame.Angles(0,.25,0)*world.model:GetPivot())
		local arena=world.model.Battlefield
		local group="CivilizationWarriors"
		if not Physics:IsCollisionGroupRegistered(group) then Physics:RegisterCollisionGroup(group) end
		Physics:CollisionGroupSetCollidable(group,group,false)
		test("all five imported melee models spawn as server-owned articulated characters",function()
			for plotId,id in ids do
				local levels=(options and options.levels) or {2,25,50,25,50}
				world:setOwner(plotId,catalog[id],-7000-plotId,"ModelMovementTester",levels[plotId])
				local spawn=world:getBarracksSpawn(plotId)
				local rig=Rig.create(catalog[id],spawn,-7000-plotId,plotId,{weaponLevel=1,armorLevel=1})
				assert(rig:GetAttribute("CustomMeleeModel")==true and rig:GetAttribute("TemplateCivilizationId")==id)
				rig.Parent=world.model.Troops
				for _,part in rig:GetDescendants() do if part:IsA("BasePart") then part.CollisionGroup=group end end
				rig.HumanoidRootPart:SetNetworkOwner(nil)
				assert(not rig.HumanoidRootPart.Anchored and rig.HumanoidRootPart:GetNetworkOwner()==nil)
				local context={rig=rig,civ=catalog[id],start=rig.HumanoidRootPart.Position,reached=false,pose=false,started=os.clock()}
				context.navigator=Navigator.new(rig,function() return active and rig.Parent~=nil and rig.Humanoid.Health>0 end)
				local angle=(plotId-1)*math.pi*2/8+.25
				context.navigator:setGoal(arena.Position+Vector3.new(math.sin(angle)*30,4,math.cos(angle)*30))
				table.insert(contexts,context)
			end
		end)
		heartbeat=RunService.Heartbeat:Connect(function()
			local success,message=pcall(function()
				for _,context in contexts do
					local rig=context.rig
					if not context.reached then context.navigator:step(os.clock()) end
					local moving=rig.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5
					Rig.animate(rig,os.clock(),moving,false)
					local hip=rig.Torso:FindFirstChild("Right Hip")
					if moving and hip and hip.C0~=hip:GetAttribute("RestC0") then context.pose=true end
					if Rules.containsArena(arena,rig.HumanoidRootPart.Position) and not context.reached then
						context.reached=true; context.duration=os.clock()-context.started
						context.entryPosition=rig.HumanoidRootPart.Position
						context.navigator:stop()
					end
				end
			end)
			if not success then asynchronousFailure=tostring(message) end
		end)
		test("gear updates keep imported model identity and missing health while locomotion runs",function()
			task.wait(.4)
			for _,context in contexts do
				local rig=context.rig
				rig.Humanoid.Health=70
				Rig.update(rig,context.civ,{weaponLevel=2,armorLevel=2})
				assert(rig:GetAttribute("CustomMeleeModel")==true and near(rig:GetAttribute("WarriorDamage"),T.weapon[2].damage))
				assert(near(rig.Humanoid.MaxHealth,T.armor[2].health) and near(rig.Humanoid.Health,T.armor[2].health-30))
				for _,joint in rig:GetDescendants() do
					assert(not (joint:IsA("Motor6D") and joint.Name=="RightGrip"),"Engine grip reappeared on custom NPC")
					if joint:IsA("Motor6D") and joint:GetAttribute("RestC0") then
						assert((joint.C0.Position-joint:GetAttribute("RestC0").Position).Magnitude<.001,"Pose shifted an imported joint's rest position")
					end
				end
			end
		end)
		test("every imported civilization walks from its walled settlement into the battlefield",function()
			local deadline=os.clock()+120
			repeat
				assert(asynchronousFailure==nil,asynchronousFailure)
				local complete=true
				for _,context in contexts do if not context.reached then complete=false end end
				if complete then
					for _,context in contexts do
						assert(Rules.containsArena(arena,context.entryPosition),"Recorded arrival lies outside the actual arena")
						local startOffset=context.start-arena.Position
						local radius=math.max(arena.Size.Y,arena.Size.Z)/2
						local minimum=Vector3.new(startOffset.X,0,startOffset.Z).Magnitude-radius
						local delta=context.entryPosition-context.start
						context.distance=Vector3.new(delta.X,0,delta.Z).Magnitude
						context.minimumDistance=minimum
						assert(minimum>0 and context.distance>=minimum-5,
							context.civ.id.." entered without covering the spawn-to-arena geometric minimum: actual="..context.distance.." minimum="..minimum)
						assert(context.pose,"Imported model never animated a walking pose")
						assert(near(context.rig.Humanoid.Health,T.armor[2].health-30) and context.rig.HumanoidRootPart:GetNetworkOwner()==nil)
					end
					return
				end
				task.wait(.1)
			until os.clock()>deadline
			local missing={}
			for _,context in contexts do
				if not context.reached then table.insert(missing,context.civ.id..":"..tostring(context.rig:GetAttribute("NavigationStatus"))) end
			end
			error("Imported model failed actual movement: "..table.concat(missing,", "))
		end)
		local durations,distances,minimumDistances={},{},{}
		for _,context in contexts do
			durations[context.civ.id]=context.duration
			distances[context.civ.id]=context.distance
			minimumDistances[context.civ.id]=context.minimumDistance
		end
		return {ok=true,cases=cases,arrivalSeconds=durations,arrivalDistances=distances,minimumDistances=minimumDistances,
			message="Five actual imported melee assets: server physics, live upgraded clothing/health/poses, and physical pathfinding out of citadels into the arena passed"}
	end)
	active=false
	if heartbeat then heartbeat:Disconnect() end
	for _,context in contexts do context.navigator:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

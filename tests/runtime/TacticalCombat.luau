-- Native combatants remain unanchored throughout every movement observation.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
	local service=context.service;assert(service.encounters,"Shared encounters are not integrated")
	local Game=game.ServerScriptService.Game
	local Rules=require(Game.CombatRules)
	local Config=require(game.ReplicatedStorage.Shared.TacticalCombatConfig)
	local cases,evidence,connections=0,{},{}
	local uid=player.UserId
	local function waitFor(predicate,label,timeout)
		local deadline=os.clock()+(timeout or 15)
		repeat if predicate()then return end;task.wait(.025)until os.clock()>deadline
		error("Timed out: "..label)
	end
	local function stage(name)game:SetAttribute("TacticalCombatVerificationPhase",name)end
	local function test(name,fn)stage(name);fn();cases+=1;print("PASS: "..name)end
	local function command(name)return round("developmentInput",{kind="command",button=name},20)end
	local function choose(id)return round("civilizationInput",{action="choose",civilization=id},30)end
	if not service.registry:get(uid)then choose("sparta")end
	local original=service.registry:get(uid).civilizationId
	local fixture=if original=="sparta" then "japan" else "sparta"
	local saved=context.service.profiles:get(uid,fixture)
	local playerRoot=player.Character.HumanoidRootPart
	local originalPlayer={frame=player.Character:GetPivot(),anchored=playerRoot.Anchored}
	local function army()return service.army:get(uid)end
	local function neutral()return service.neutralOpponents:get()end
	local arena=service.world.model.Battlefield
	local function point(x,z)
		local position=arena.Position+Vector3.new(x,0,z or 0)
		local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include
		filter.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
		filter.RespectCanCollide=true
		local hit=workspace:Raycast(position+Vector3.new(0,60,0),Vector3.new(0,-120,0),filter)
		assert(hit,"Fixture point lacks actual collidable ground")
		return Vector3.new(position.X,hit.Position.Y+3,position.Z)
	end
	local function flat(a,b)local d=a-b;return Vector3.new(d.X,0,d.Z).Magnitude end
	local parkedLocations={
		owned_warrior={-160,-100},owned_camp={-160,-80},owned_ranged={-160,-60},
		neutral_melee1={160,100},neutral_melee2={160,80},neutral_ranged={160,60},
	}
	local function liveSlots()
		local result={};local owner=army()
		local function add(id,slot)
			local rig=slot and slot.rig
			if rig and rig.Parent and rig:FindFirstChildOfClass("Humanoid")and rig.Humanoid.Health>0 then result[id]=rig end
		end
		if owner then for _,id in {"warrior","camp","ranged"}do add("owned_"..id,owner.slots[id])end end
		for _,id in {"melee1","melee2","ranged"}do add("neutral_"..id,neutral()[id])end
		return result
	end
	local function rigs()
		local result=liveSlots();local count=0;for _ in result do count+=1 end
		return if count==6 then result else nil
	end
	local function setup(positions)
		-- Stop surviving combatants before waiting for normal reinforcements;
		-- otherwise later deaths can prevent all six slots ever coexisting.
		local staged={}
		local function parkArrivals()
			for id,rig in liveSlots()do if staged[id]~=rig then
				service.encounters:cancel(rig)
				rig.HumanoidRootPart.Anchored=true
				local location=parkedLocations[id]
				rig:PivotTo(CFrame.new(point(location[1],location[2])))
				staged[id]=rig
			end end
		end
		parkArrivals()
		assert(service.command(player,"order","hold").ok)
		waitFor(function()parkArrivals();return rigs()~=nil end,"six live reinforcement slots",20)
		local actors=rigs()
		for id,rig in actors do
			service.encounters:cancel(rig)
			rig.HumanoidRootPart.Anchored=true
			rig.Humanoid.Health=rig.Humanoid.MaxHealth
			local location=positions[id] or parkedLocations[id]
			rig:PivotTo(CFrame.new(point(location[1],location[2])))
		end
		return actors
	end
	local function unanchor(actors,selected)
		for id,rig in actors do if not selected or selected[id]then
			rig.HumanoidRootPart.Anchored=false;rig.HumanoidRootPart:SetNetworkOwner(nil)
		end end
	end
	local ok,result=pcall(function()
		assert(service.profiles:set(uid,fixture,{coins=1000,level=10,weaponLevel=1,armorLevel=1,barracksLevel=4,
			trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,extraTroopClass="warrior"}))
		choose(fixture)
		playerRoot=player.Character.HumanoidRootPart;playerRoot.Anchored=true
		player.Character:PivotTo(service.world:getSpawn(player:GetAttribute("PlotId")))
		test("six production NPCs approach fight and separate with native physics",function()
			local actors=setup({owned_warrior={-12,0},owned_camp={-12,0},owned_ranged={-28,2},
				neutral_melee1={12,0},neutral_melee2={12,4},neutral_ranged={28,2}})
			local records={};local damageEvents,earliest,matchedContacts=0,math.huge,0
			for id,rig in actors do
				records[id]={start=rig.HumanoidRootPart.Position,last=rig.HumanoidRootPart.Position,moved=0,phases={}}
				local previous=rig.Humanoid.Health
				table.insert(connections,rig.Humanoid.HealthChanged:Connect(function(health)
					if health<previous then
						damageEvents+=1
						local now=workspace:GetServerTimeNow()
						-- Several attackers may target the victim. Match a published
						-- accepted attack; another unfinished windup is not its source.
						task.defer(function()
							local matched=false
							for _,source in actors do
								local attack=service.encounters:get(source)
								local began=source:GetAttribute("AttackStartedAt")
								local accepted=source:GetAttribute("LastAttackAt")
								if attack and attack.target==rig and began and accepted and accepted>=began then
									local age=now-began
									if age>=0 then earliest=math.min(earliest,age);matched=true end
								end
							end
							if matched then matchedContacts+=1 end
						end)
					end
					previous=health
				end))
			end
			command("Advance");unanchor(actors)
			local started,last=os.clock(),os.clock()
			local overlap,maxOverlap,minDistance={},0,math.huge
			local function movementEvidence(reason)
				local report={reason=reason,elapsed=os.clock()-started,damageEvents=damageEvents,
					matchedContacts=matchedContacts,minimumSeparation=if minDistance<math.huge then minDistance else nil,
					longestOverlap=maxOverlap,overlap=table.clone(overlap),actors={}}
				local function vector(position)return if position then {position.X,position.Y,position.Z}else nil end
				for id,rig in actors do
					local plan=service.encounters:get(rig)
					local root=rig:FindFirstChild("HumanoidRootPart")
					local humanoid=rig:FindFirstChildOfClass("Humanoid")
					local targetId=nil
					if plan and plan.target then for otherId,other in actors do if other==plan.target then targetId=otherId;break end end end
					report.actors[id]={position=vector(root and root.Position),velocity=vector(root and root.AssemblyLinearVelocity),
						goal=vector(plan and plan.goal),target=targetId,phase=rig:GetAttribute("CombatPhase"),
						state=rig:GetAttribute("WarriorState"),navigation=rig:GetAttribute("NavigationStatus"),
						moved=records[id].moved,health=humanoid and humanoid.Health,anchored=root and root.Anchored}
				end
				game:SetAttribute("TacticalCombatMovementEvidence",game.HttpService:JSONEncode(report))
			end
			while os.clock()-started<12 do
				local now=os.clock();local dt=now-last;last=now
				for id,rig in actors do if rig.Parent and rig.Humanoid.Health>0 then
					local root=rig.HumanoidRootPart;local record=records[id]
					assert(not root.Anchored and root:GetNetworkOwner()==nil)
					assert((root.Position-record.last).Magnitude<math.max(4,dt*40),"Combatant teleported")
					record.last=root.Position;record.moved=math.max(record.moved,flat(root.Position,record.start))
					local phase=rig:GetAttribute("CombatPhase");if phase then record.phases[phase]=true end
					assert(Rules.containsArena(arena,root.Position),"Fighting NPC left the battlefield")
					for otherId,other in actors do if otherId>id and other.Parent and other.Humanoid.Health>0 then
						local separation=flat(root.Position,other.HumanoidRootPart.Position)
						if now-started>1.5 then
							minDistance=math.min(minDistance,separation)
							local key=id..":"..otherId
							overlap[key]=if separation<2 then (overlap[key] or 0)+dt else 0
							maxOverlap=math.max(maxOverlap,overlap[key])
							if overlap[key]>=.8 then movementEvidence("Sustained torso overlap: "..key)end
							assert(overlap[key]<.8,"Sustained torso overlap: "..key)
						end
					end end
				end end
				task.wait(.025)
			end
			local complete,moved=0,0
			for _,record in records do
				if record.phases.windup and record.phases.contact and record.phases.recovery then complete+=1 end
				if record.moved>3 then moved+=1 end
			end
			movementEvidence("Complete observation")
			assert(damageEvents>=4 and complete>=2 and moved>=4,"No genuine moving multi-cycle encounter")
			assert(matchedContacts>0 and earliest<math.huge,"Native damage had no matching published accepted attack")
			assert(earliest>=Config.phases.warrior.windup-.04,"Native damage occurred before visible windup")
			evidence.encounter={seconds=12,damageEvents=damageEvents,completeCycles=complete,movingCombatants=moved,
				minimumRootSeparation=minDistance,longestTorsoOverlap=maxOverlap,earliestObservedContact=earliest,
				matchedContactEvents=matchedContacts}
		end)
		for _,connection in connections do connection:Disconnect()end;table.clear(connections)
		test("moving out of a held melee windup causes a native miss",function()
			local actors=setup({owned_warrior={-4,0},neutral_melee1={0,0}})
			unanchor(actors,{owned_warrior=true,neutral_melee1=true})
			local source,target=actors.owned_warrior,actors.neutral_melee1
			waitFor(function()return source:GetAttribute("CombatPhase")=="windup"end,"held melee windup",5)
			local health=target.Humanoid.Health
			target:PivotTo(CFrame.new(point(20,0)))
			task.wait(.45)
			assert(target.Humanoid.Health==health,"A target escaping native windup was damaged")
			assert(flat(source.HumanoidRootPart.Position,point(-4,0))<1.2,"Hold chased an escaped target")
		end)
		test("ranged escape near the arena edge remains bounded and physically walks",function()
			local radius=math.min(arena.Size.Y,arena.Size.Z)/2
			local actors=setup({owned_ranged={radius-6,0},neutral_melee1={radius-13,0}})
			command("Advance");unanchor(actors,{owned_ranged=true,neutral_melee1=true})
			local source=actors.owned_ranged;local start=source.HumanoidRootPart.Position
			local furthest=0;local finish=os.clock()+3
			while os.clock()<finish do
				local position=source.HumanoidRootPart.Position
				assert(Rules.containsArena(arena,position),"Ranged retreat crossed the arena edge")
				furthest=math.max(furthest,flat(position,start));task.wait(.025)
			end
			assert(furthest>2,"Archer never physically repositioned under close pressure")
			assert(furthest<=Config.retreatLimit+2,"Archer exceeded its bounded retreat")
			evidence.retreat={maximumDisplacement=furthest,seconds=3}
		end)
		test("native Hold fixes position and Regroup stops contacts without changing timers",function()
			local actors=setup({owned_warrior={-8,0},owned_camp={-8,5},owned_ranged={-25,3},
				neutral_melee1={8,0},neutral_melee2={8,5},neutral_ranged={25,3}})
			unanchor(actors);command("Hold")
			local positions={};for id,rig in actors do if string.sub(id,1,6)=="owned_"then positions[id]=rig.HumanoidRootPart.Position end end
			task.wait(1)
			for id,position in positions do assert(flat(actors[id].HumanoidRootPart.Position,position)<1.2,"Hold moved a troop")end
			local slots=army().slots;local deadline=slots.camp.respawnAt
			command("Regroup")
			local contacts={};for id in positions do contacts[id]=actors[id]:GetAttribute("LastAttackAt")end
			task.wait(.65)
			for id in positions do
				assert(actors[id]:GetAttribute("LastAttackAt")==contacts[id],"Regroup permitted another contact")
				assert(actors[id]:GetAttribute("WarriorState")=="Regrouping" or actors[id]:GetAttribute("WarriorState")=="Regrouped")
			end
			assert(army().slots.camp.respawnAt==deadline and player:GetAttribute("TroopCapacity")==3)
			evidence.orders={holdSeconds=1,regroupContactFreeSeconds=.65}
		end)
		return {cases=cases,evidence=evidence,message="Native six-NPC fight, escape miss, bounded edge retreat and commander orders"}
	end)
	for _,connection in connections do connection:Disconnect()end
	local owner=army()
	if owner then for _,slot in owner.slots do if slot.rig then
		slot.rig.HumanoidRootPart.Anchored=false;slot.rig.HumanoidRootPart:SetNetworkOwner(nil)
	end end end
	for _,slot in neutral()do if slot.rig then
		slot.rig.HumanoidRootPart.Anchored=false;slot.rig.HumanoidRootPart:SetNetworkOwner(nil)
	end end
	-- Cleanup is a trusted fixture operation, not another native input check.
	-- A failed client round must not hold restoration open for thirty seconds.
	local cleanupOk,cleanupError=pcall(function()
		local restored=service.select(player,original,true);assert(restored.ok,tostring(restored.reason))
		assert(service.profiles:set(uid,fixture,saved))
	end)
	game:SetAttribute("TacticalCombatCleanupResult",if cleanupOk then "restored"else tostring(cleanupError))
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart")then
		player.Character.HumanoidRootPart.Anchored=originalPlayer.anchored
		player.Character:PivotTo(originalPlayer.frame)
	end
	if ok then assert(cleanupOk,"Tactical fixture restoration failed: "..tostring(cleanupError))end
	assert(ok,result);return result
end

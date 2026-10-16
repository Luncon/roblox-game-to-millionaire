return function(moduleOverride)
	local module=moduleOverride or game.ServerScriptService.Game:FindFirstChild("CombatEncounter")
	assert(module,"NPC windup, contact and recovery coordination is not implemented")
	local Encounter=require(module)
	local Config=require(game.ReplicatedStorage.Shared.TacticalCombatConfig)
	local Rules=require(game.ServerScriptService.Game.CombatRules)
	local cases=0
	local function test(name,fn) fn();cases+=1;print("PASS: "..name) end
	local function fixture(kind)
		local model=Instance.new("Model");model.Name="TimedEncounterFixture"
		local arena=Instance.new("Part");arena.Name="Battlefield";arena.Shape=Enum.PartType.Cylinder
		arena.Size=Vector3.new(2,500,500);arena.CFrame=CFrame.new(0,10000,0)*CFrame.Angles(0,0,math.pi/2)
		arena.Anchored=true;arena.CanCollide=false;arena.CanQuery=false;arena.Parent=model;model.Parent=workspace
		local combat={registered={},hits=0,shots=0,clear=true,writable=true}
		local function create(owner,class,x,z,slot)
			local rig=Instance.new("Model");rig.Name="TimedFixtureRig";rig:SetAttribute("ArmySlot",slot or class)
			local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1)
			root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.Position=Vector3.new(x,10004,z or 0);root.Parent=rig
			local hum=Instance.new("Humanoid");hum.BreakJointsOnDeath=false;hum.Parent=rig;rig.Parent=model
			combat.registered[rig]={rig=rig,root=root,humanoid=hum,ownerId=owner,claimed=true,alive=true,kind=class,position=root.Position}
			return rig
		end
		function combat:actor(rig)
			local actor=self.registered[rig]
			if not actor or not rig.Parent or actor.humanoid.Health<=0 or not actor.claimed then return nil end
			actor.position=actor.root.Position
			return actor
		end
		function combat:actors()
			local list={};for rig in self.registered do local actor=self:actor(rig);if actor then table.insert(list,actor) end end
			return list
		end
		function combat:visible() return self.clear end
		function combat:canAct() return self.writable end
		function combat:hit(source,target)
			self.hits+=1
			local a,b=self:actor(source),self:actor(target)
			if not a or not b or not Rules.canDamage(a,b,arena) or not self.clear then return {ok=false} end
			b.humanoid.Health-=10;return {ok=true}
		end
		local source=create(1,kind or "warrior",-4)
		local target=create(2,"warrior",0)
		local encounter=Encounter.new({model=model},combat)
		local options={order="hold",fire=function() combat.shots+=1;return true end,projectileKind="arrow"}
		return {model=model,arena=arena,combat=combat,encounter=encounter,source=source,target=target,options=options,create=create}
	end
	local function run(fn,kind)
		local f=fixture(kind);local ok,message=pcall(fn,f)
		f.encounter:destroy();f.model:Destroy();assert(ok,message)
	end
	test("melee damage waits for contact and occurs only once in a cycle",function()run(function(f)
		local began=f.encounter:step(f.source,f.options,0)
		assert(began.phase=="windup" and f.combat.hits==0 and began.goal==nil)
		f.encounter:advance(f.source,Config.phases.warrior.windup-.01);assert(f.combat.hits==0)
		f.encounter:advance(f.source,Config.phases.warrior.windup+.001)
		assert(f.combat.hits==1 and f.target.Humanoid.Health==90)
		for _,time in {.25,.3,.5,.9} do f.encounter:advance(f.source,time) end
		assert(f.combat.hits==1,"One attack contacted more than once")
	end)end)
	test("ranged release waits for contact and allocates only one shot",function()run(function(f)
		f.encounter:step(f.source,f.options,0);assert(f.combat.shots==0)
		f.encounter:advance(f.source,Config.phases.ranged.windup-.01);assert(f.combat.shots==0)
		for _,time in {.36,.4,.5,1,1.9} do f.encounter:advance(f.source,time) end
		assert(f.combat.shots==1 and f.combat.hits==0 and f.target.Humanoid.Health==100)
	end,"ranged")end)
	test("range sight death arena and authority changes during windup cannot contact",function()
		local mutations={
			function(f)f.target.HumanoidRootPart.Position+=Vector3.new(20,0,0)end,
			function(f)f.combat.clear=false end,
			function(f)f.target.Humanoid.Health=0 end,
			function(f)f.target.HumanoidRootPart.Position=Vector3.new(251,10004,0)end,
			function(f)f.combat.registered[f.source].claimed=false end,
			function(f)f.combat.registered[f.target].ownerId=1 end,
			function(f)f.combat.writable=false end,
		}
		for _,mutate in mutations do run(function(f)
			f.encounter:step(f.source,f.options,0);mutate(f)
			local health=f.target.Humanoid.Health
			f.encounter:advance(f.source,.21);f.encounter:advance(f.source,.8)
			assert(f.target.Humanoid.Health==health,"Invalid locked target was damaged")
		end) end
	end)
	test("missed attack does not redirect its contact to a replacement target",function()run(function(f)
		f.encounter:step(f.source,f.options,0)
		f.target.HumanoidRootPart.Position+=Vector3.new(20,0,0)
		local replacement=f.create(3,"warrior",0,0,"replacement")
		f.encounter:step(f.source,f.options,.1);f.encounter:advance(f.source,.21)
		assert(f.target.Humanoid.Health==100 and replacement.Humanoid.Health==100)
	end)end)
	test("cancelled windup cannot land and cannot bypass consumed cadence",function()run(function(f)
		f.encounter:step(f.source,f.options,0);f.encounter:cancel(f.source)
		f.encounter:advance(f.source,.21)
		f.encounter:step(f.source,f.options,.22);f.encounter:advance(f.source,.45)
		assert(f.combat.hits==0,"Order changes bypassed the original attack cooldown")
		f.encounter:step(f.source,f.options,1.01);f.encounter:advance(f.source,1.22)
		assert(f.combat.hits==1,"Cancellation permanently disabled future attacks")
	end)end)
	test("advancing an expired animation cannot apply a stale delayed contact",function()run(function(f)
		f.encounter:step(f.source,f.options,0);f.encounter:advance(f.source,5)
		assert(f.combat.hits==0 and f.target.Humanoid.Health==100)
	end)end)
	test("a modest frame skip resolves contact once while the cycle is still active",function()run(function(f)
		f.encounter:step(f.source,f.options,0)
		f.encounter:advance(f.source,.4);f.encounter:advance(f.source,.7)
		assert(f.combat.hits==1 and f.target.Humanoid.Health==90)
	end)end)
	test("ranged responds to nearby melee pressure while retaining its firing target",function()run(function(f)
		f.target.HumanoidRootPart.Position=Vector3.new(11,10004,0) -- Fifteen studs from archer.
		local options={order="advance",fire=f.options.fire}
		f.encounter:step(f.source,options,0)
		f.encounter:advance(f.source,2.01) -- Previous attack completes, no damage on a stale cycle.
		local threat=f.create(3,"warrior",-4,11,"close-pressure")
		local plan=f.encounter:step(f.source,options,2.02)
		assert(plan.target==f.target,"A minor distance difference discarded the retained firing target")
		assert(plan.goal and plan.speed==Config.retreatSpeed,"Archer ignored another melee fighter approaching its flank")
		assert((plan.goal-threat.HumanoidRootPart.Position).Magnitude>11,"Retreat approached the actual close threat")
	end,"ranged")end)
	test("continuous melee pressure cannot renew ranged retreat by changing firing targets",function()run(function(f)
		local options={order="advance",fire=f.options.fire}
		local origin=f.source.HumanoidRootPart.Position
		assert(f.encounter:step(f.source,options,0).goal,"Close melee did not start a retreat")
		f.source.HumanoidRootPart.Position=origin+Vector3.new(0,0,-17)
		f.target.HumanoidRootPart.Position=f.source.HumanoidRootPart.Position+Vector3.new(0,0,5)
		local bounded=f.encounter:step(f.source,options,.5)
		if bounded.goal then assert((bounded.goal-origin).Magnitude<=Config.retreatLimit+.01)end
		f.combat.registered[f.target].ownerId=1
		f.create(3,"warrior",f.source.HumanoidRootPart.Position.X,f.source.HumanoidRootPart.Position.Z+11,"pressure")
		local newTarget=f.create(4,"ranged",f.source.HumanoidRootPart.Position.X+7,f.source.HumanoidRootPart.Position.Z,"new-shot")
		local changed=f.encounter:step(f.source,options,Config.retreatDuration-.01)
		assert(changed.target==newTarget,"Fixture did not change the firing target under continuous pressure")
		local exhausted=f.encounter:step(f.source,options,Config.retreatDuration+.01)
		assert(exhausted.goal==nil,"Target churn renewed a bounded retreat episode")
	end,"ranged")end)
	test("blocked first ranged sidestep selects a physically clear alternative",function()run(function(f)
		local Tactics=require(game.ServerScriptService.Game.CombatTactics)
		f.target.HumanoidRootPart.Position=Vector3.new(20,10004,0)
		local source,target=f.combat:actor(f.source),f.combat:actor(f.target)
		local points=Tactics.rangedPoints(source,target,false)
		local wall=Instance.new("Part");wall.Name="ActualSidestepBlocker";wall.Size=Vector3.new(4,10,.5)
		wall.Anchored=true;wall.CFrame=CFrame.lookAt(source.position:Lerp(points[1],.5),source.position);wall.Parent=f.model
		function f.combat:visible(attacker)
			return (attacker.position-source.position).Magnitude>.01
		end
		local plan=f.encounter:step(f.source,{order="advance",fire=f.options.fire},0)
		assert(plan.goal==points[2],"An obstructed first sidestep prevented use of its clear alternative")
	end,"ranged")end)
	test("melee selects a sighted attack position and waits when every contact is obstructed",function()run(function(f)
		function f.combat:visible(attacker)
			return attacker.position.X>0
		end
		local plan=f.encounter:step(f.source,{order="advance"},0)
		assert(plan.goal and plan.goal.X>0,"Melee retained an attack approach with no target sightline")
		f.encounter:cancel(f.source)
		function f.combat:visible()return false end
		plan=f.encounter:step(f.source,{order="advance"},1)
		assert(plan.state=="Waiting" and plan.phase=="idle","Melee began an attack through obstructing geometry")
	end)end)
	test("shared melee reservations allocate distinct approaches and overflow waits outside reach",function()run(function(f)
		f.source.HumanoidRootPart.Position=Vector3.new(16,10004,0)
		local attackers={f.source}
		for index=2,Config.engagementSlots+1 do
			local angle=(index-1)*math.pi*2/(Config.engagementSlots+1)
			table.insert(attackers,f.create(1,"warrior",math.cos(angle)*16,math.sin(angle)*16,"approach-"..index))
		end
		local goals={}
		for index,rig in attackers do
			local plan=f.encounter:step(rig,{order="advance"},0)
			assert(plan.target==f.target)
			if index<=Config.engagementSlots then
				assert(plan.goal and (plan.goal-f.target.HumanoidRootPart.Position).Magnitude<=5)
				for _,previous in goals do assert((plan.goal-previous).Magnitude>=Config.minimumSeparation-.01)end
				table.insert(goals,plan.goal)
			else
				assert(plan.state=="Waiting" and plan.phase=="idle")
				assert(not plan.goal or (plan.goal-f.target.HumanoidRootPart.Position).Magnitude>5)
			end
		end
		for _,rig in attackers do f.encounter:forget(rig)end
		for _,rig in attackers do f.combat.registered[rig]=nil end
		local newcomer=f.create(1,"warrior",-12,0,"newcomer")
		local released=f.encounter:step(newcomer,{order="advance"},1)
		assert(released.goal and (released.goal-f.target.HumanoidRootPart.Position).Magnitude<=5,
			"Dead or removed troops retained all attack reservations")
	end)end)
	test("simultaneous ranged retreats reserve different physical destinations",function()run(function(f)
		local other=f.create(1,"ranged",-4,0,"second-archer")
		local options={order="advance",fire=f.options.fire}
		local first=f.encounter:step(f.source,options,0)
		local second=f.encounter:step(other,options,0)
		assert(first.goal,"First pressured archer did not plan a retreat")
		assert(not second.goal or (second.goal-first.goal).Magnitude>=Config.minimumSeparation-.01,
			"Two archers reserved the same retreat destination")
	end,"ranged")end)
	test("coincident allies separate locally before pursuing a distant enemy or marching home",function()run(function(f)
		local other=f.create(1,"warrior",-4,0,"coincident-ally")
		f.target.HumanoidRootPart.Position=Vector3.new(30,10004,0)
		local options={order="advance",homeGoal=Vector3.new(80,10004,0)}
		local first=f.encounter:step(f.source,options,0)
		local second=f.encounter:step(other,options,0)
		assert(first.goal and second.goal and first.direct and second.direct,
			"Coincident allies shared a long pursuit route instead of making short escape steps")
		assert((first.goal-second.goal).Magnitude>=Config.minimumSeparation-.01)
		assert(first.phase=="idle" and second.phase=="idle")
		f.encounter:forget(f.source);f.encounter:forget(other)
		f.target.HumanoidRootPart.Position=Vector3.new(100,10004,0)
		local marching=f.encounter:step(f.source,options,1)
		assert(marching.goal and marching.direct and (marching.goal-f.source.HumanoidRootPart.Position).Magnitude<=Config.closeDistance,
			"Idle allies stayed coincident until they acquired an enemy")
		assert(f.encounter:step(f.source,{order="hold"},1.1).goal==nil,"Local separation moved a held troop")
	end)end)
	test("delayed valid contact adjusts the next windup to preserve accepted hit cadence",function()run(function(f)
		local original=f.combat.hit
		function f.combat:hit(source,target)
			assert(self.time>=(self.nextValidHitAt or 0),"Encounter scheduled a contact before authoritative cooldown expiry")
			local result=original(self,source,target)
			if result.ok then self.nextValidHitAt=self.time+1 end
			return result
		end
		f.encounter:step(f.source,f.options,0)
		f.combat.time=.45;f.encounter:advance(f.source,.45)
		assert(f.combat.hits==1)
		assert(f.encounter:step(f.source,f.options,1.01).phase=="idle",
			"A delayed contact caused the following windup to begin before it could legally strike")
		assert(f.encounter:step(f.source,f.options,1.26).phase=="windup")
		f.combat.time=1.47;f.encounter:advance(f.source,1.47)
		assert(f.combat.hits==2 and f.target.Humanoid.Health==80)
	end)end)
	test("ranged personal-space escape obeys the same slower bounded hostile retreat",function()run(function(f)
		local options={order="advance",fire=f.options.fire}
		local origin=f.source.HumanoidRootPart.Position
		f.target.HumanoidRootPart.Position=origin+Vector3.new(2,0,0)
		local escape=f.encounter:step(f.source,options,0)
		assert(escape.goal and escape.speed==Config.retreatSpeed and escape.speed<12,
			"Point-blank personal-space escape gave ranged troops full melee speed")
		f.source.HumanoidRootPart.Position=origin+Vector3.new(0,0,-17)
		f.target.HumanoidRootPart.Position=f.source.HumanoidRootPart.Position+Vector3.new(2,0,0)
		local bounded=f.encounter:step(f.source,options,.5)
		if bounded.goal then assert((bounded.goal-origin).Magnitude<=Config.retreatLimit+.01)end
		local exhausted=f.encounter:step(f.source,options,Config.retreatDuration+.01)
		assert(exhausted.goal==nil,"Repeated point-blank escape bypassed the hostile retreat episode limit")
	end,"ranged")end)
	test("an archer near the arena edge can retreat tangentially when backward steps are outside",function()run(function(f)
		f.source.HumanoidRootPart.Position=Vector3.new(244,10004,0)
		f.target.HumanoidRootPart.Position=Vector3.new(237,10004,0)
		local origin=f.source.HumanoidRootPart.Position
		local options={order="advance",fire=f.options.fire}
		local plan=f.encounter:step(f.source,options,0)
		assert(plan.goal and Rules.containsArena(f.arena,plan.goal),"Edge pressure offered no arena-safe retreat alternative")
		assert(plan.speed==Config.retreatSpeed and (plan.goal-origin).Magnitude<=Config.retreatLimit+.01)
		assert(math.abs(plan.goal.Z)>2,"Archer failed to sidestep when every preferred backward leg left the arena")
		local exhausted=f.encounter:step(f.source,options,Config.retreatDuration+.01)
		assert(exhausted.goal==nil,"Edge movement renewed the bounded retreat episode")
	end,"ranged")end)
	test("normal maximum NPC crowd produces bounded plans and teardown removes all state",function()run(function(f)
		local all={f.source,f.target}
		for index=1,25 do
			local rig=f.create(1+math.floor((index-1)/3),if index%3==0 then "ranged" else "warrior",
				20*math.cos(index),20*math.sin(index),"crowd-"..index)
			if index>22 then local actor=f.combat.registered[rig];actor.ownerId=nil;actor.neutral=true end
			table.insert(all,rig)
		end
		assert(#all==27)
		for _,rig in all do
			local plan=f.encounter:step(rig,{order="advance",fire=f.options.fire},0)
			if plan.goal then
				assert(plan.goal.X==plan.goal.X and plan.goal.Z==plan.goal.Z)
				assert(Rules.containsArena(f.arena,plan.goal),"Crowded approach escaped the arena")
			end
		end
		for _,rig in all do f.encounter:forget(rig);assert(f.encounter:get(rig)==nil)end
		f.encounter:destroy()
		for _,rig in all do assert(f.encounter:advance(rig,.21).phase=="idle")end
		assert(f.combat.hits==0 and f.combat.shots==0)
	end)end)
	test("Hold and teardown do not allocate chase goals or retain actions",function()run(function(f)
		f.target.HumanoidRootPart.Position+=Vector3.new(20,0,0)
		assert(f.encounter:step(f.source,f.options,0).goal==nil)
		f.target.HumanoidRootPart.Position-=Vector3.new(20,0,0)
		f.encounter:step(f.source,f.options,1)
		f.encounter:forget(f.source);f.encounter:advance(f.source,1.21)
		assert(f.combat.hits==0 and f.encounter:get(f.source)==nil)
	end)end)
	return cases
end

--!strict

local Shared=game:GetService("ReplicatedStorage").Shared
local Tuning=require(Shared.TacticalCombatConfig)
local Warrior=require(Shared.WarriorConfig)
local Ranged=require(Shared.RangedConfig)
local Rules=require(script.Parent.CombatRules)
local Tactics=require(script.Parent.CombatTactics)
local Topography=require(script.Parent.Topography)
local CombatEncounter={}

-- One instance coordinates both NPC services. Planning runs at think frequency;
-- advance only updates an existing action and attempts its one locked contact.
function CombatEncounter.new(world,combat)
	local controller={}
	local records={}
	local actorsByRig={}
	local active=true
	local arena=world.model.Battlefield
	local function permitted(rig): boolean
		local actor=combat:actor(rig)
		return actor~=nil and actor.kind~="medic" and (type(combat.canAct)~="function" or combat:canAct(rig))
	end
	local function duration(kind): number
		local phases=Tuning.phases[kind]
		return phases.windup+phases.contact+phases.recovery
	end
	local function pose(record,now,accepted)
		if combat.skills then
			local skillPlan=combat.skills:plan(record.rig)
			if skillPlan then record.snapshot=skillPlan;return table.clone(skillPlan) end
		end
		local action=record.action
		local phase,progress="idle",0
		local phaseStart,phaseDuration=nil,nil
		if action then
			phase,progress=Tactics.attackPhase(action.startedAt,now,action.kind)
			local phases=Tuning.phases[action.kind]
			phaseStart=action.serverAt
			if phase=="contact" then phaseStart+=phases.windup
			elseif phase=="recovery" then phaseStart+=phases.windup+phases.contact end
			phaseDuration=phases[phase]
		end
		local result=table.clone(record.plan or {})
		result.target=record.target
		result.phase,result.phaseProgress=phase,progress
		result.phaseStartedAt,result.phaseDuration=phaseStart,phaseDuration
		result.attackStartedAt=if action then action.serverAt else nil
		result.lastAttackAt,result.lastContactAt=record.lastAttackAt,record.lastContactAt
		result.contactAccepted=accepted==true
		record.snapshot=result
		return table.clone(result)
	end
	function controller:get(rig)
		local record=records[rig]
		return if record and record.snapshot then table.clone(record.snapshot) else nil
	end
	function controller:cancel(rig)
		if combat.skills then combat.skills:cancel(rig) end
		local record=records[rig]
		if not record then return end
		record.action,record.reservation,record.target,record.retreatOrigin,record.retreatStartedAt=nil,nil,nil,nil,nil
		record.plan={goal=nil,state="Holding",direct=false,speed=Warrior.walkSpeed}
		pose(record,record.lastNow or 0,false)
	end
	function controller:forget(rig)
		if combat.skills then combat.skills:cancel(rig) end
		records[rig]=nil;actorsByRig[rig]=nil
	end
	function controller:destroy() active=false;table.clear(records);table.clear(actorsByRig) end

	local function ground(point,attacker): Vector3
		local base=world.model:FindFirstChild("Ground")
		if not base or not base:IsA("BasePart") then return point end
		local p=base.CFrame:PointToObjectSpace(point)
		local a=base.CFrame:PointToObjectSpace(attacker.position)
		local clearance=math.clamp(a.Y-.95-Topography.sampleHeight(a.X,a.Z),2.5,4)
		return base.CFrame:PointToWorldSpace(Vector3.new(p.X,.95+Topography.sampleHeight(p.X,p.Z)+clearance,p.Z))
	end
	local function clearRoute(point,attacker,escaping): boolean
		local delta=point-attacker.position
		if delta.Magnitude<.01 then return true end
		local side=Vector3.new(-delta.Z,0,delta.X)
		if side.Magnitude>.01 then side=side.Unit*.8 end
		local filter=RaycastParams.new()
		filter.FilterType=Enum.RaycastFilterType.Exclude
		local excluded={attacker.rig}
		if escaping then
			for _,other in actorsByRig do
				if Tactics.flatDistance(other.position,attacker.position)<Tuning.minimumSeparation
					and math.abs(other.position.Y-attacker.position.Y)<4 then table.insert(excluded,other.rig) end
			end
		end
		filter.FilterDescendantsInstances=excluded
		for _,offset in {Vector3.zero,side,-side} do
			if workspace:Raycast(attacker.position+Vector3.new(0,.5,0)+offset,delta,filter) then return false end
		end
		return true
	end
	local function free(point,attacker,target,actors,escaping): boolean
		if not Rules.containsArena(arena,point) then return false end
		if Tactics.flatDistance(point,attacker.position)<=Tuning.closeDistance and not clearRoute(point,attacker,escaping) then return false end
		for _,other in actors do
			if other.rig~=attacker.rig and other.rig~=target.rig
				and math.abs(other.position.Y-point.Y)<4
				and Tactics.flatDistance(point,other.position)<Tuning.minimumSeparation then return false end
		end
		for rig,record in records do
			local reservation=record.reservation
			if rig~=attacker.rig and reservation then
				local owner,foe=actorsByRig[rig],actorsByRig[reservation.target]
				if not owner or not foe then record.reservation=nil
				else
					local reserved=reservation.point or foe.position+reservation.offset
					if math.abs(reserved.Y-point.Y)<4 and Tactics.flatDistance(reserved,point)<Tuning.minimumSeparation then return false end
				end
			end
		end
		return true
	end
	local function meleeGoal(record,attacker,target,actors)
		local function attackPoint(point): boolean
			return (point-target.position).Magnitude<=Warrior.attackRange+.0001
				and free(point,attacker,target,actors)
				and combat:visible({rig=attacker.rig,position=point},target)
		end
		local previous=record.reservation
		if previous and previous.target==target.rig and not previous.waiting then
			local point=ground(target.position+previous.offset,attacker)
			if attackPoint(point) then return point,false end
		end
		local chosen,score=nil,math.huge
		local points=Tactics.meleePoints(attacker,target)
		for _,point in points do
			point=ground(point,attacker)
			local distance=Tactics.flatDistance(point,attacker.position)
			if distance<score and attackPoint(point) then chosen,score=point,distance end
		end
		local waiting=false
		if not chosen then
			waiting=true
			for _,point in points do
				point=ground(target.position+(point-target.position)*2,attacker)
				local distance=Tactics.flatDistance(point,attacker.position)
				if distance<score and free(point,attacker,target,actors) then chosen,score=point,distance end
			end
		end
		record.reservation=if chosen then {target=target.rig,offset=chosen-target.position,waiting=waiting} else nil
		return chosen,waiting
	end
	local function moving(attacker): boolean
		local root=attacker.root
		if not root then return false end
		local velocity=root.AssemblyLinearVelocity
		return Vector3.new(velocity.X,0,velocity.Z).Magnitude>1
	end
	function controller:step(rig,options,now)
		if not active then return {phase="idle"} end
		local attacker=combat:actor(rig)
		if not attacker then self:forget(rig);return {phase="idle"} end
		local record=records[rig]
		if not record then record={rig=rig,nextAttackAt=0};records[rig]=record end
		record.lastNow=now
		if record.order~=options.order then self:cancel(rig);record.order=options.order end
		if options.order=="regroup" or not permitted(rig) then self:cancel(rig);return pose(record,now,false) end
		if combat.skills and combat.skills:busy(rig) then return pose(record,now,false) end
		local actors,occupancy={},{}
		actorsByRig={}
		for _,actor in options.actors or combat:actors() do
			if Rules.containsArena(arena,actor.position) then
				table.insert(actors,actor)
				actorsByRig[actor.rig]=actor
			end
		end
		for otherRig,other in records do
			local reservation=other.reservation
			if reservation and (not actorsByRig[otherRig] or not actorsByRig[reservation.target]) then
				other.reservation=nil
				reservation=nil
			end
			if reservation and not reservation.waiting then occupancy[reservation.target]=(occupancy[reservation.target] or 0)+1 end
		end
		local target=nil
		if Rules.containsArena(arena,attacker.position) then
			if record.action and now<record.action.startedAt+duration(record.action.kind) then
				target=combat:actor(record.action.target)
			else
				target=Tactics.chooseTarget(attacker,actors,record.target,options.order,occupancy)
			end
		end
		if record.target~=(if target then target.rig else nil) then record.reservation=nil end
		record.target=if target then target.rig else nil
		local plan={goal=nil,facing=if target then target.position else nil,direct=false,speed=Warrior.walkSpeed,state="Fighting"}
		record.plan=plan
		if combat.skills and not record.action and now>=record.nextAttackAt and target then
			local result=combat.skills:activate(rig,options.order,true)
			if result.ok then
				if options.cancelShots then options.cancelShots() end
				record.reservation=nil
				return pose(record,now,false)
			end
			-- A ready skill waits for the previous normal contact's cooldown.
			-- Otherwise beginning another windup here can starve it forever.
			if result.reason=="busy" then return pose(record,now,false) end
		end
		local ranged=attacker.kind=="ranged"
		local pressure,pressureDistance=nil,math.huge
		if ranged then
			for _,other in actors do
				local separation=Tactics.flatDistance(attacker.position,other.position)
				if other.kind~="ranged" and other.kind~="medic" and Rules.hostile(attacker,other) and separation<pressureDistance then
					pressure,pressureDistance=other,separation
				end
			end
			if pressureDistance>=Tuning.retreatSafe then record.retreatOrigin,record.retreatStartedAt=nil,nil end
		end
		if options.order~="hold" then
			local escapes=Tactics.separationPoints(attacker,actors)
			local boundedEscape=ranged and pressureDistance<Tuning.retreatSafe
			if boundedEscape and #escapes>0 then
				record.retreatOrigin=record.retreatOrigin or attacker.position
				record.retreatStartedAt=record.retreatStartedAt or now
			end
			for _,point in escapes do
				if boundedEscape then
					if now-record.retreatStartedAt>=Tuning.retreatDuration then break end
					local offset=point-record.retreatOrigin
					if offset.Magnitude>Tuning.retreatLimit then point=record.retreatOrigin+offset.Unit*Tuning.retreatLimit end
				end
				point=ground(point,attacker)
				if Tactics.flatDistance(point,attacker.position)>.75 and free(point,attacker,attacker,actors,true) then
					-- Endpoint reservations do not separate coincident travellers;
					-- walk apart first, then resume the existing pursuit.
					record.action=nil
					record.reservation={target=rig,point=point,waiting=true}
					plan.goal,plan.direct,plan.state=point,true,"Separating"
					plan.speed=if ranged then Tuning.retreatSpeed else Warrior.walkSpeed
					return pose(record,now,false)
				end
			end
		end
		if not target then
			record.reservation=nil
			plan.goal=if options.order=="hold" then nil else options.homeGoal
			plan.state=if options.order=="hold" then "Holding" elseif Rules.containsArena(arena,attacker.position) then "Guarding" else "Marching"
			return pose(record,now,false)
		end
		if record.action and now<record.action.startedAt+duration(record.action.kind) then return pose(record,now,false) end
		record.action=nil
		local reach=if ranged then Ranged.range else Warrior.attackRange
		local distance=(target.position-attacker.position).Magnitude
		local canStrike=Rules.canDamage(attacker,target,arena,reach) and combat:visible(attacker,target)
		if options.order~="hold" then
			if ranged then
				record.reservation=nil
				-- A retained firing target must not hide a different melee threat.
				local retreat=pressure~=nil and (pressureDistance<Tuning.retreatTrigger
					or (record.retreatOrigin~=nil and pressureDistance<Tuning.retreatSafe))
				if retreat then
					record.retreatOrigin=record.retreatOrigin or attacker.position
					record.retreatStartedAt=record.retreatStartedAt or now
					local choices=if now-record.retreatStartedAt<Tuning.retreatDuration then Tactics.rangedPoints(attacker,pressure,true) else {}
					for _,point in choices do
						local offset=point-record.retreatOrigin
						if offset.Magnitude>Tuning.retreatLimit then point=record.retreatOrigin+offset.Unit*Tuning.retreatLimit end
						point=ground(point,attacker)
						if Tactics.flatDistance(point,attacker.position)>.75 and free(point,attacker,target,actors) then plan.goal=point;break end
					end
					plan.speed=Tuning.retreatSpeed
				elseif distance>Tuning.rangedFar then
					plan.goal=ground(target.position+Tactics.away(attacker,target)*((Tuning.rangedNear+Tuning.rangedFar)/2),attacker)
				elseif not canStrike then
					if not record.sidestepUntil or now>=record.sidestepUntil then
						record.sidestepGoal=nil
						for _,point in Tactics.rangedPoints(attacker,target,false) do
							point=ground(point,attacker)
							local viewpoint={rig=rig,position=point}
							if free(point,attacker,target,actors) and combat:visible(viewpoint,target) then record.sidestepGoal=point;break end
						end
						record.sidestepUntil=now+Tuning.sidestepInterval
					end
					plan.goal=record.sidestepGoal
				end
			else
				local point,waiting=meleeGoal(record,attacker,target,actors)
				local crowded=false
				for _,other in actors do
					if other.rig~=rig and Tactics.flatDistance(other.position,attacker.position)<Tuning.minimumSeparation then crowded=true;break end
				end
				if not canStrike or crowded or waiting then plan.goal=point end
				if waiting or not point then plan.state="Waiting";canStrike=false end
			end
		end
		if plan.goal and not Rules.containsArena(arena,plan.goal) then plan.goal=nil;canStrike=false end
		if ranged then
			record.reservation=if plan.goal then {target=target.rig,point=plan.goal,waiting=true} else nil
		end
		plan.direct=plan.goal~=nil and Tactics.flatDistance(plan.goal,attacker.position)<=Tuning.closeDistance
		if not plan.goal and canStrike and not moving(attacker) and now>=record.nextAttackAt then
			local kind=if ranged then "ranged" else "warrior"
			if combat.skills then combat.skills:lockOrdinary(rig,if ranged then Ranged.attackCooldown else Warrior.attackCooldown) end
			record.action={target=target.rig,kind=kind,startedAt=now,serverAt=workspace:GetServerTimeNow(),fire=options.fire,resolved=false}
			record.nextAttackAt=now+(if ranged then Ranged.attackCooldown else Warrior.attackCooldown)
		end
		return pose(record,now,false)
	end

	function controller:advance(rig,now)
		local record=records[rig]
		if not active or not record then return {phase="idle"} end
		record.lastNow=now
		if not permitted(rig) then self:cancel(rig);return pose(record,now,false) end
		if combat.skills and combat.skills:busy(rig) then return pose(record,now,false) end
		local action=record.action
		local accepted=false
		if action then
			local elapsed=now-action.startedAt
			if not action.resolved and elapsed>=Tuning.phases[action.kind].windup then
				action.resolved=true
				local cooldown=if action.kind=="ranged" then Ranged.attackCooldown else Warrior.attackCooldown
				record.nextAttackAt=math.max(record.nextAttackAt,now+cooldown-Tuning.phases[action.kind].windup)
				-- A severely stalled/expired cycle misses; never deliver stale damage.
				if elapsed<duration(action.kind) then
					local attacker,target=combat:actor(rig),combat:actor(action.target)
					local reach=if action.kind=="ranged" then Ranged.range else Warrior.attackRange
					if attacker and target and Rules.canDamage(attacker,target,arena,reach) and combat:visible(attacker,target) then
						if action.kind=="ranged" then accepted=type(action.fire)=="function" and action.fire(action.target)==true
						else accepted=combat:hit(rig,action.target).ok==true end
					end
				end
				if accepted then
					record.lastAttackAt=workspace:GetServerTimeNow()
					if action.kind~="ranged" then record.lastContactAt=record.lastAttackAt end
				end
			end
			if elapsed>=duration(action.kind) then record.action=nil end
		end
		return pose(record,now,accepted)
	end
	return controller
end

return CombatEncounter

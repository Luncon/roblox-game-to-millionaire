--!strict

local Shared=game:GetService("ReplicatedStorage").Shared
local Tuning=require(Shared.TacticalCombatConfig)
local Warrior=require(Shared.WarriorConfig)
local Ranged=require(Shared.RangedConfig)
local Rules=require(script.Parent.CombatRules)
local CombatTactics={}

function CombatTactics.flatDistance(a: Vector3,b: Vector3): number
	local d=a-b
	return Vector3.new(d.X,0,d.Z).Magnitude
end

function CombatTactics.stableKey(actor): string
	local rig=actor.rig
	local slot=if rig then rig:GetAttribute("ArmySlot") or rig:GetAttribute("NeutralSlot") or rig.Name else ""
	return tostring(actor.ownerId or "neutral")..":"..tostring(actor.kind)..":"..tostring(slot)
end

local function hash(key: string): number
	local value=0
	for index=1,#key do
		value=(value*31+string.byte(key,index))%65521
	end
	return value
end
local function seed(actor): number return hash(CombatTactics.stableKey(actor)) end

function CombatTactics.away(attacker,target): Vector3
	local d=Vector3.new(attacker.position.X-target.position.X,0,attacker.position.Z-target.position.Z)
	if d.Magnitude>.001 then return d.Unit end
	local a,b=CombatTactics.stableKey(attacker),CombatTactics.stableKey(target)
	local pair=if a<b then a.."/"..b else b.."/"..a
	local angle=hash(pair)*math.pi*2/65521
	return Vector3.new(math.cos(angle),0,math.sin(angle))*(if a<b then 1 else -1)
end

function CombatTactics.separationPoints(attacker,actors): {Vector3}
	local repulsion,neighbor=Vector3.zero,nil
	for _,other in actors do
		local distance=CombatTactics.flatDistance(attacker.position,other.position)
		if other.rig~=attacker.rig and math.abs(other.position.Y-attacker.position.Y)<4
			and distance<Tuning.minimumSeparation then
			repulsion+=CombatTactics.away(attacker,other)*(Tuning.minimumSeparation-distance)
			if not neighbor or CombatTactics.stableKey(other)<CombatTactics.stableKey(neighbor) then neighbor=other end
		end
	end
	if not neighbor then return {} end
	if repulsion.Magnitude<.001 then repulsion=CombatTactics.away(attacker,neighbor) end
	local direction=repulsion.Unit
	local points={}
	for _,radius in {Tuning.separationStep,Tuning.separationStep*2,Tuning.separationStep*3} do
		for _,angle in {0,math.pi/3,-math.pi/3,math.pi*2/3,-math.pi*2/3,math.pi} do
			local c,s=math.cos(angle),math.sin(angle)
			local rotated=Vector3.new(direction.X*c-direction.Z*s,0,direction.X*s+direction.Z*c)
			table.insert(points,attacker.position+rotated*radius)
		end
	end
	return points
end

function CombatTactics.chooseTarget(attacker,actors,currentTargetRig,order,occupancy)
	local range=if attacker.kind=="ranged" then Ranged.aggroRange else Warrior.aggroRange
	if order=="hold" then range=if attacker.kind=="ranged" then Ranged.range else Warrior.attackRange end
	local best,bestScore,bestKey=nil,math.huge,""
	for _,candidate in actors do
		if not Rules.hostile(attacker,candidate) then continue end
		local retained=candidate.rig==currentTargetRig
		local distance=(candidate.position-attacker.position).Magnitude
		if distance>range+(if retained and order~="hold" then Tuning.targetRetentionRange else 0) then continue end
		local score=distance+(if occupancy then occupancy[candidate.rig] or 0 else 0)*Tuning.crowdingPenalty
		if retained then score-=Tuning.targetHysteresis end
		if attacker.kind~="ranged" and candidate.kind~="ranged" then
			local defense=0
			for _,ally in actors do
				if ally.kind=="ranged" and ally.rig~=attacker.rig and not Rules.hostile(attacker,ally)
					and Rules.hostile(candidate,ally) then
					local proximity=1-CombatTactics.flatDistance(candidate.position,ally.position)/Tuning.defenseRadius
					defense=math.max(defense,Tuning.defenseBonus*math.clamp(proximity,0,1))
				end
			end
			score-=defense
		end
		local key=CombatTactics.stableKey(candidate)
		if score<bestScore-.0001 or (math.abs(score-bestScore)<=.0001 and key<bestKey) then
			best,bestScore,bestKey=candidate,score,key
		end
	end
	return best
end

function CombatTactics.meleePoints(attacker,target): {Vector3}
	local points={}
	local offset=seed(attacker)%Tuning.engagementSlots
	for index=1,Tuning.engagementSlots do
		local angle=((index-1+offset)%Tuning.engagementSlots)*math.pi*2/Tuning.engagementSlots
		table.insert(points,target.position+Vector3.new(math.cos(angle),0,math.sin(angle))*Tuning.meleeRadius)
	end
	return points
end

function CombatTactics.rangedPoints(attacker,target,retreat: boolean): {Vector3}
	local away=CombatTactics.away(attacker,target)
	local side=Vector3.new(-away.Z,0,away.X)
	if seed(attacker)%2==1 then side=-side end
	if retreat then
		return {
			attacker.position+away*Tuning.retreatStep,
			attacker.position+(away+side*.7).Unit*Tuning.retreatStep,
			attacker.position+(away-side*.7).Unit*Tuning.retreatStep,
			attacker.position+side*Tuning.retreatStep,
			attacker.position-side*Tuning.retreatStep,
		}
	end
	return {attacker.position+side*Tuning.sidestepDistance,attacker.position-side*Tuning.sidestepDistance}
end

function CombatTactics.attackPhase(startedAt: number,now: number,kind: string): (string,number)
	local phases=Tuning.phases[kind]
	local elapsed=math.max(0,now-startedAt)
	for _,name in {"windup","contact","recovery"} do
		local duration=phases[name]
		if elapsed<duration then return name,elapsed/duration end
		elapsed-=duration
	end
	return "idle",0
end

return CombatTactics

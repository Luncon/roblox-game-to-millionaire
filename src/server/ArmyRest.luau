--!strict

local Shared=game:GetService("ReplicatedStorage").Shared
local Camp=require(Shared.TrainingCampConfig)
local Warrior=require(Shared.WarriorConfig)
local Rest={}

function Rest.new(slotId: string)
	local index=Camp.arrivalIndex(slotId)
	return {phase="returning",index=index,reachedIndex=index,direction=1,cycles=0}
end

local function pause(state,now)
	state.phase="pausing"
	state.reachedIndex=state.index
	state.cycles+=1
	state.pauseUntil=now+2+(state.index+state.cycles)%4
end

function Rest.step(state,position: Vector3,now: number): (Vector3?,number,boolean)
	if state.phase~="returning" and not Camp.contains(position,2) then
		state.phase="returning"
		state.index=state.reachedIndex
	end
	local goal=Camp.point(state.index)
	local delta=position-goal
	local arrived=Vector3.new(delta.X,0,delta.Z).Magnitude<=2.25 and math.abs(delta.Y)<=6
	if state.phase=="returning" then
		-- Enter through the clear approach first. Short walks inside the reserved
		-- yard use native MoveTo rather than asking the world navmesh to resolve
		-- every point around decorative geometry.
		if not Camp.contains(position,2) then return Camp.entryPoint(state.index),Warrior.walkSpeed,false end
		if not arrived then return goal,Warrior.walkSpeed,false end
		pause(state,now)
	elseif state.phase=="walking" then
		if arrived then
			pause(state,now)
		elseif now>=state.deadline then
			-- A blocked leg reverses from the last reached point. Arbitrary jumps
			-- around the ring would let a path cut through the fire.
			state.direction=-state.direction
			state.index=(state.reachedIndex-1+state.direction)%Camp.pointCount+1
			state.deadline=now+Camp.goalTimeout
		end
	elseif now>=state.pauseUntil then
		state.index=(state.reachedIndex-1+state.direction)%Camp.pointCount+1
		state.phase="walking"
		state.deadline=now+Camp.goalTimeout
	end
	return if state.phase=="pausing" then nil else Camp.point(state.index),Camp.walkSpeed,true
end

return Rest

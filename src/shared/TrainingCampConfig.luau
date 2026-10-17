--!strict

local Camp={
	center=Vector3.new(-148,0,-12),
	pad=Vector3.new(-148,-.3,14),
	size=Vector3.new(28,.2,28),
	approachHalfWidth=8,
	approachInnerX=-32,
	ringRadius=9,
	pointCount=8,
	entryIndex=8,
	walkSpeed=5,
	goalTimeout=8,
}

function Camp.arrivalIndex(slotId: string?): number
	return if slotId=="medic" then 6 elseif slotId=="ranged" then 2 elseif slotId=="camp" then 8 else 1
end

function Camp.point(index: number): Vector3
	local angle=(index-1)*math.pi*2/Camp.pointCount
	-- Exterior ground is at .15; the foundation's origin is at 1.
	return Camp.center+Vector3.new(math.cos(angle)*Camp.ringRadius,2.15,math.sin(angle)*Camp.ringRadius)
end

function Camp.entryPoint(index: number): Vector3
	-- Stagger four body-width destinations within the gate's clear navmesh.
	local inner=index==2 or index==6
	local lower=index==1 or index==6
	return Camp.center+Vector3.new(if inner then 5 else 9,2.15,if lower then -3 else 3)
end

function Camp.contains(position: Vector3,margin: number?): boolean
	local half=Camp.size.X/2-(margin or 0)
	return math.abs(position.X-Camp.center.X)<=half+.01 and math.abs(position.Z-Camp.center.Z)<=half+.01
end

function Camp.blocksApproach(x: number,z: number,margin: number): boolean
	return x>=Camp.center.X-margin and x<=Camp.approachInnerX+margin
		and math.abs(z-Camp.center.Z)<Camp.approachHalfWidth+margin
end

return table.freeze(Camp)

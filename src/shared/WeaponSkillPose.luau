--!strict

-- Pose offsets only: no reparenting joints, replacing grips or modifying source rigs.
local Pose={}
function Pose.sample(family: string,elapsed: number)
	local right,left,twist,lean=Vector3.zero,Vector3.new(.3,0,-.1),0,0
	local offset=Vector3.zero
	if family=="spear" then
		local thrust=math.clamp((elapsed-.12)/.08,0,1)*(1-math.clamp((elapsed-.5)/.5,0,1))
		right=Vector3.new(1.3,-.3,-.25)*thrust
		left=Vector3.new(.7,.2,.3)*thrust
		offset=Vector3.new(0,0,-.8)*thrust
		twist,lean=-.25*thrust,.18*thrust
	elseif family=="axe" then
		local spin=math.clamp((elapsed-.25)/.45,0,1)
		local strength=math.clamp(elapsed/.2,0,1)*(1-math.clamp((elapsed-.7)/.5,0,1))
		right=Vector3.new(.6,0,1.4)*strength
		left=Vector3.new(.5,0,-1.1)*strength
		twist=math.pi*2*spin
	else
		local function stroke(start)
			local p=math.clamp((elapsed-start)/.18,0,1)
			return math.sin(p*math.pi)
		end
		local first,second=stroke(.08),stroke(.43)
		right=Vector3.new(1.8,0,0)*(first+second)+Vector3.new(0,.8,.9)*(first-second)
		left=Vector3.new(.4,.2,-.3)
		twist=.55*(first-second)
	end
	return {right=right,left=left,offset=offset,twist=twist,lean=lean}
end
return table.freeze(Pose)

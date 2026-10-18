--!strict

-- Pose offsets only: no reparenting joints, replacing grips or modifying source rigs.
local Pose={}
local Config=require(script.Parent.WeaponSkillConfig)
function Pose.sample(family: string,elapsed: number,formation: boolean?)
	local right,left,twist,lean=Vector3.zero,Vector3.new(.3,0,-.1),0,0
	local offset=Vector3.zero
	local rightHip,leftHip,neck=nil,nil,nil
	if family=="spear" then
		local progress=math.clamp(elapsed/Config.families.spear.duration,0,1)
		local drive=math.sin(progress*math.pi)
		-- Lean into -Z, drive the hand forward and counter-rotate the spear arm
		-- so the standard forward grip stays level throughout the lunge.
		lean=-.4-.12*drive
		right=Vector3.new(-lean,0,0)
		left=Vector3.new(1.05,.05,-.25)
		offset=Vector3.new(0,.12,-.85-.3*drive)
		rightHip=Vector3.new(.85+.12*drive,0,.06)
		leftHip=Vector3.new(-.65-.12*drive,0,-.06)
		neck=Vector3.new(-lean*.7,0,0)
		if formation then
			-- Drive the spear with the upper body while keeping both feet planted.
			lean=-.12-.12*drive
			right=Vector3.new(-lean,0,0)
			offset=Vector3.new(0,.05,-.5-.6*drive)
			left=Vector3.new(.45,.05,-.25)
			rightHip,leftHip=Vector3.zero,Vector3.zero
			neck=Vector3.new(-lean*.7,0,0)
		end
	elseif family=="axe" then
		local spin=math.clamp(elapsed/Config.families.axe.duration,0,1)
		local strength=1
		right=Vector3.new(.6,0,1.4)*strength
		left=Vector3.new(.5,0,-1.1)*strength
		twist=math.pi*2*spin
	else
		local progress=math.clamp(elapsed/Config.families.sword.duration,0,1)
		-- Two broad opposing cuts, with no idle pose before the first swing.
		local sweep=if progress<.5 then 1-4*progress else 4*progress-3
		right=Vector3.new(2.1,1.2*sweep,1.5*sweep)
		left=Vector3.new(.8,-.3*sweep,-.6)
		offset=Vector3.new(.25*sweep,0,-.25)
		twist,lean=.9*sweep,.18
	end
	return {right=right,left=left,offset=offset,twist=twist,lean=lean,rightHip=rightHip,leftHip=leftHip,neck=neck}
end
return table.freeze(Pose)

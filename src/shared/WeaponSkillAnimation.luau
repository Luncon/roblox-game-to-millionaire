--!strict

local Pose=require(script.Parent.WeaponSkillPose)
local Animation={}

function Animation.new()
	local controller={}
	local joints={}
	-- Called in PreSimulation, after the Animator writes its ordinary poses.
	-- Override that frame's Transform so tool-hold/walk tracks cannot mask a skill.
	-- Leave rest joints and equipment grips untouched.
	function controller:step(performances)
		local active={}
		for _,performance in performances do
			local sample=Pose.sample(performance.family,performance.elapsed)
			for _,motor in performance.rig:GetDescendants() do
				if not motor:IsA("Motor6D") then continue end
				local angles,offset
				if motor.Name=="RightShoulder" or motor.Name=="Right Shoulder" then angles,offset=sample.right,sample.offset
				elseif motor.Name=="LeftShoulder" or motor.Name=="Left Shoulder" then angles,offset=sample.left,Vector3.zero
				elseif motor.Name=="Root" or motor.Name=="RootJoint" then angles,offset=Vector3.new(sample.lean,sample.twist,0),Vector3.zero
				elseif motor.Name=="Waist" then angles,offset=Vector3.new(if performance.family=="spear" then 0 else sample.lean*.5,0,0),Vector3.zero
				elseif performance.family=="spear" then
					if motor.Name=="RightHip" or motor.Name=="Right Hip" then angles,offset=sample.rightHip,Vector3.zero
					elseif motor.Name=="LeftHip" or motor.Name=="Left Hip" then angles,offset=sample.leftHip,Vector3.zero
					elseif motor.Name=="Neck" then angles,offset=sample.neck,Vector3.zero
					elseif motor.Name=="RightElbow" or motor.Name=="RightWrist" then angles,offset=Vector3.zero,Vector3.zero
					elseif motor.Name=="RightKnee" then angles,offset=Vector3.new(-.55,0,0),Vector3.zero
					elseif motor.Name=="LeftKnee" then angles,offset=Vector3.new(-.25,0,0),Vector3.zero
					elseif motor.Name=="RightAnkle" or motor.Name=="LeftAnkle" then angles,offset=Vector3.zero,Vector3.zero end
				end
				if not angles then continue end
				active[motor]=true
				local record=joints[motor]
				if not record then record={base=motor.Transform};joints[motor]=record
				elseif motor.Transform~=record.applied then record.base=motor.Transform end
				-- R6 and R15 rest joints use different axes. Convert the shared
				-- torso-space pose into joint space, including upright root spins.
				local basis=motor.C0.Rotation
				record.applied=basis:Inverse()*CFrame.new(offset)*CFrame.Angles(angles.X,angles.Y,angles.Z)*basis
				motor.Transform=record.applied
			end
		end
		for motor,record in joints do
			if not active[motor] then
				if motor.Parent and motor.Transform==record.applied then motor.Transform=record.base end
				joints[motor]=nil
			end
		end
	end
	return controller
end

return Animation

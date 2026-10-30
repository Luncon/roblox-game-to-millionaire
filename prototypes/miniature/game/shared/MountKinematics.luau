--!strict
-- Authored animal anatomy is driven locally; this module never moves an authority root.
local MountKinematics = {}
type Joint = { motor: Motor6D, rest: CFrame, phase: number, amplitude: number, kind: string, side: number }
export type Rig = { joints: { Joint }, family: string }
function MountKinematics.new(model: Model): Rig?
	if model:GetAttribute("MountedVisual") ~= true then
		return nil
	end
	local joints = {}
	for _, object in model:GetDescendants() do
		if object:IsA("Motor6D") and object:GetAttribute("MountJoint") == true then
			local rest = object:GetAttribute("MountRestC0")
			local phase = object:GetAttribute("MountGaitPhase")
			local amplitude = object:GetAttribute("MountGaitAmplitude")
			local kind = object:GetAttribute("MountJointKind")
			local side = object:GetAttribute("MountLimbSide")
			if
				typeof(rest) ~= "CFrame"
				or typeof(phase) ~= "number"
				or typeof(amplitude) ~= "number"
				or typeof(kind) ~= "string"
			then
				return nil
			end
			table.insert(joints, {
				motor = object,
				rest = rest,
				phase = phase,
				amplitude = amplitude,
				kind = kind,
				side = if typeof(side) == "number" and side < 0 then -1 else 1,
			})
		end
	end
	local family = model:GetAttribute("MountAnimal")
	if #joints == 0 or typeof(family) ~= "string" then
		return nil
	end
	return { joints = joints, family = family }
end
function MountKinematics.apply(rig: Rig, time: number, speed: number): ()
	local movement = math.clamp(speed / 9, 0, 1.25)
	local frequency = if rig.family == "elephant" or rig.family == "rhino"
		then 5.6
		elseif rig.family == "crocodile" then 7
		else 8.5
	for _, joint in rig.joints do
		local cycle = time * frequency + joint.phase
		local swing = math.sin(cycle) * joint.amplitude * movement
		local transform
		if joint.kind == "leg" then
			if rig.family == "crocodile" then
				-- Splayed feet travel mainly around the hip in the ground plane.
				-- A horse-style X hinge barely moves these long lateral limbs.
				transform = CFrame.new(0, math.max(0, math.cos(cycle)) * 0.03 * movement, 0)
					* CFrame.Angles(swing * 0.18, swing * joint.side, math.cos(cycle) * 0.1 * movement * joint.side)
			else
				transform = CFrame.Angles(swing, 0, 0)
			end
		elseif joint.kind == "knee" then
			transform = CFrame.Angles(math.max(0, math.cos(cycle)) * joint.amplitude * movement, 0, 0)
		elseif joint.kind == "tail" then
			transform = CFrame.Angles(0, math.sin(cycle * 0.5) * joint.amplitude * (0.2 + movement), 0)
		elseif joint.kind == "head" then
			transform = CFrame.Angles(math.sin(cycle * 2) * joint.amplitude * movement, 0, 0)
		elseif joint.kind == "body" then
			transform = CFrame.new(0, math.abs(math.sin(cycle)) * joint.amplitude * movement, 0)
		else
			transform = CFrame.identity
		end
		joint.motor.C0 = joint.rest * transform
		joint.motor.Transform = CFrame.identity
	end
end
return table.freeze(MountKinematics)

--!strict

-- A cosmetic speed streak on the equipped clone; no forces or hit geometry.
local Effect={}
function Effect.attach(rig)
	local tool=rig:FindFirstChildOfClass("Tool")
	local handle=tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("WarriorHandle"))
	if not handle or not handle:IsA("BasePart") then return nil end
	-- Normalized spear visuals point along Handle +Y. Locate the visible tip,
	-- including rotated imported parts, without changing any source/gear weld.
	local tip=handle.Size.Y*.5
	for _,part in tool:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local frame=handle.CFrame:ToObjectSpace(part.CFrame)
		local extent=(math.abs(frame.RightVector.Y)*part.Size.X+math.abs(frame.UpVector.Y)*part.Size.Y+math.abs(frame.LookVector.Y)*part.Size.Z)*.5
		tip=math.max(tip,frame.Position.Y+extent)
	end
	local first,second=Instance.new("Attachment"),Instance.new("Attachment")
	first.Name,second.Name="SpearDashTrailLeft","SpearDashTrailRight"
	first.Position,second.Position=Vector3.new(-.12,tip,0),Vector3.new(.12,tip,0)
	first.Parent,second.Parent=handle,handle
	local trail=Instance.new("Trail")
	trail.Name,trail.Attachment0,trail.Attachment1="SpearDashTrail",first,second
	trail.Lifetime,trail.MinLength,trail.MaxLength=.1,.03,6
	trail.FaceCamera,trail.LightEmission,trail.LightInfluence=true,1,0
	trail.Color=ColorSequence.new(Color3.fromRGB(255,245,202),Color3.fromRGB(193,229,245))
	trail.Transparency=NumberSequence.new(.2,1)
	trail.WidthScale=NumberSequence.new(1,0)
	trail.Parent=handle
	return function()
		trail.Enabled=false;trail:Clear();trail:Destroy()
		first:Destroy();second:Destroy()
	end
end
return Effect

-- Native Instance/geometry checks; no stores or source templates are used.
return function()
	local Effect=require(game.ReplicatedStorage.Shared.SpearDashTrail)
	local rig=Instance.new("Model")
	local tool=Instance.new("Tool");tool.Parent=rig
	local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.2,1,.2);handle.Parent=tool
	local shaft=Instance.new("Part");shaft.Size=Vector3.new(.2,4,.2);shaft.CFrame=handle.CFrame*CFrame.new(0,2,0);shaft.Parent=tool
	local grip,originalParts=tool.Grip,2
	local ok,message=pcall(function()
		local clear=assert(Effect.attach(rig))
		local trail=assert(handle:FindFirstChild("SpearDashTrail"))
		assert(trail:IsA("Trail") and trail.Attachment0.Parent==handle and trail.Attachment1.Parent==handle)
		assert(math.abs(trail.Attachment0.Position.Y-4)<.001 and trail.Attachment0.Position.X<0 and trail.Attachment1.Position.X>0)
		local parts=0
		for _,item in rig:GetDescendants() do if item:IsA("BasePart") then parts+=1 end end
		assert(parts==originalParts and tool.Grip==grip,"Dash effect changed equipment or added physics geometry")
		clear()
		assert(#handle:GetChildren()==0 and tool.Grip==grip,"Dash effect left attachments or a trail behind")
		-- A missing tool/handle is a cosmetic no-op, never an activation error.
		tool:Destroy();assert(Effect.attach(rig)==nil)
	end)
	rig:Destroy();assert(ok,message)
	return 2
end

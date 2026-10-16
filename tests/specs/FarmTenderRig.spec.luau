return function()
	local source=game.ServerStorage.FarmTemplates.farmer
	local before=#source:GetDescendants()
	assert(source.UpperTorso.MeshId~="","Rojo lost the farmer body mesh")
	assert(source:FindFirstChildOfClass("Accessory"):FindFirstChildWhichIsA("MeshPart",true).MeshId~="","Rojo lost the farmer hat mesh")
	local frames={}
	for _,p in source:GetDescendants()do if p:IsA("BasePart")then frames[p]={p.CFrame,p.Anchored,p.CanCollide,p.Color,p.Size}end end
	local Tenders=assert(game.ServerScriptService.Game:FindFirstChild("FarmTenders"),"Passive farmer rig preparation is missing")
	Tenders=require(Tenders)
	local cases=0
	local function test(fn)fn();cases+=1 end
	local dirty=source:Clone()
	local scriptCopy=Instance.new("Script");scriptCopy.Parent=dirty.Head
	local force=Instance.new("VectorForce");force.Parent=dirty.Head
	local foreign=Instance.new("Part")
	local weld=Instance.new("Weld");weld.Part0=dirty.Head;weld.Part1=foreign;weld.Parent=dirty.Head
	dirty:SetAttribute("Damage",999)
	dirty.Humanoid.MaxHealth=999
	local rig=Tenders.prepare(dirty)
	dirty:Destroy();foreign:Destroy()
	local ok,result=pcall(function()
		test(function()
			assert(rig:FindFirstChildOfClass("Shirt").ShirtTemplate==source:FindFirstChildOfClass("Shirt").ShirtTemplate)
			assert(rig:FindFirstChildOfClass("Pants").PantsTemplate==source:FindFirstChildOfClass("Pants").PantsTemplate)
			assert(rig:FindFirstChildOfClass("Accessory"),"Farmer hat disappeared")
			assert(rig.UpperTorso.MeshId==source.UpperTorso.MeshId)
			assert(not rig:GetAttribute("Damage"))
			local appearance=rig:FindFirstChildOfClass("Humanoid")
			assert(appearance and not appearance.EvaluateStateMachine and not appearance.AutoRotate)
			assert(appearance.WalkSpeed==0 and appearance.JumpPower==0 and appearance.JumpHeight==0 and appearance.MaxHealth==100)
			assert(not appearance.BreakJointsOnDeath and not appearance.RequiresNeck and appearance.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)
			for _,d in rig:GetDescendants()do
				assert(not d:IsA("LuaSourceContainer") and not d:IsA("Constraint"))
				if d:IsA("Humanoid")then assert(d==appearance)end
				if d:IsA("BasePart")then assert(d.Anchored and not d.CanCollide and not d.CanTouch and not d.CanQuery)end
				if d:IsA("JointInstance")then assert(d.Part0 and d.Part1 and d.Part0:IsDescendantOf(rig) and d.Part1:IsDescendantOf(rig))end
			end
		end)
		test(function()
			local frame=CFrame.new(150,20,-200)*CFrame.Angles(0,.7,0)
			Tenders.pose(rig,frame,0,false)
			local hat=rig:FindFirstChildOfClass("Accessory"):FindFirstChildWhichIsA("BasePart",true)
			local hatOffset=rig.Head.CFrame:ToObjectSpace(hat.CFrame)
			local arm=rig.LeftHand.Position
			Tenders.pose(rig,frame,.55,false)
			assert((rig.LeftHand.Position-arm).Magnitude>.2,"Walking pose did not articulate arms")
			assert((rig.Head.CFrame:ToObjectSpace(hat.CFrame).Position-hatOffset.Position).Magnitude<.001,"Hat detached during articulation")
			local lowest=math.huge
			for _,name in {"LeftFoot","RightFoot"}do local p=rig[name];lowest=math.min(lowest,frame:PointToObjectSpace(p.Position).Y-p.Size.Y/2)end
			assert(lowest>=-.02 and lowest<.15,"Feet are not grounded")
			local hand=rig.RightHand.Position;Tenders.pose(rig,frame,.4,true)
			assert((rig.RightHand.Position-hand).Magnitude>.1,"Working pose did not move")
		end)
		assert(#source:GetDescendants()==before and source:FindFirstChildOfClass("Humanoid"),"Source rig was mutated")
		for p,values in frames do
			assert(p.CFrame==values[1] and p.Anchored==values[2] and p.CanCollide==values[3] and p.Color==values[4] and p.Size==values[5],"Farmer source geometry changed")
		end
		return cases
	end)
	rig:Destroy()
	task.wait() -- Destroying callbacks run at the next resumption with deferred signals.
	assert(not pcall(Tenders.pose,rig,CFrame.new(),0,false),"Destroyed worker retained its pose cache")
	assert(ok,result);return result
end

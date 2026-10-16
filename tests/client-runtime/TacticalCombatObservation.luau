-- Real observer data: rendered part positions and replicated health/phase changes.
return function(options)
	assert(game:GetService("RunService"):IsStudio())
	local world=workspace:WaitForChild("CivilizationPrototype",15)
	local folder=world:WaitForChild("Troops",15)
	local wanted={};for _,id in options.ownerIds do wanted[id]=true end
	local camera=workspace.CurrentCamera
	local original={kind=camera.CameraType,frame=camera.CFrame,subject=camera.CameraSubject}
	local records,connections={},{}
	local damageEvents=0
	local ok,result=pcall(function()
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(options.focus+Vector3.new(15,18,35),options.focus+Vector3.new(0,3,0))
		local finish=os.clock()+(options.seconds or 10)
		while os.clock()<finish do
			for _,rig in folder:GetChildren()do if wanted[rig:GetAttribute("OwnerId")]then
				local root,arm,hum=rig:FindFirstChild("HumanoidRootPart"),rig:FindFirstChild("Right Arm"),rig:FindFirstChildOfClass("Humanoid")
				if root and arm and hum then
					local record=records[rig]
					if not record then
						record={start=root.Position,moved=0,phases={},armPositions={}}
						records[rig]=record
						local previous=hum.Health
						table.insert(connections,hum.HealthChanged:Connect(function(health)
							if health<previous then damageEvents+=1 end;previous=health
						end))
					end
					record.moved=math.max(record.moved,(root.Position-record.start).Magnitude)
					local phase=rig:GetAttribute("CombatPhase")
					if phase then
						record.phases[phase]=true
						if phase=="windup" or phase=="contact"then
							record.armPositions[phase]=record.armPositions[phase] or {}
							table.insert(record.armPositions[phase],root.CFrame:PointToObjectSpace(arm.Position))
						end
					end
				end
			end end
			game:GetService("RunService").RenderStepped:Wait()
		end
		local seen,moved,cycles,visiblePose=0,0,0,0
		local maximumArmDisplacement=0
		for _,record in records do
			seen+=1;if record.moved>3 then moved+=1 end
			if record.phases.windup and record.phases.contact and record.phases.recovery then cycles+=1 end
			local delta=0
			for _,a in record.armPositions.windup or {}do for _,b in record.armPositions.contact or {}do
				delta=math.max(delta,(a-b).Magnitude)
			end end
			maximumArmDisplacement=math.max(maximumArmDisplacement,delta)
			if delta>.15 then visiblePose+=1 end
		end
		assert(seen>=6 and moved>=4,"Observer did not receive six genuinely moving NPCs")
		assert(cycles>=2 and visiblePose>=2,"Observer did not render distinct windup/contact limb poses")
		assert(damageEvents>=2,"Observer did not receive actual combat damage")
		return {ok=true,seen=seen,movingCombatants=moved,completePhaseCycles=cycles,
			visibleAttackPoses=visiblePose,maximumArmDisplacement=maximumArmDisplacement,damageEvents=damageEvents}
	end)
	for _,connection in connections do connection:Disconnect()end
	camera.CameraType,camera.CFrame,camera.CameraSubject=original.kind,original.frame,original.subject
	assert(ok,result);return result
end

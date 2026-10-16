return function()
	local Animation=require(game.ReplicatedStorage.Shared.WeaponSkillAnimation)
	local Pose=require(game.ReplicatedStorage.Shared.WeaponSkillPose)
	local count=0
	for _,elapsed in {0,.04,.1,.18,.2} do
		local dash=Pose.sample("spear",elapsed)
		assert(dash.lean<-.3,"Dash body leans away from the thrust")
		assert(math.abs(dash.right.X+dash.lean)<.001 and dash.right.Y==0 and dash.right.Z==0,"Spear arm does not counter the torso lean")
		assert(dash.twist==0 and dash.offset.Z<-.7,"Thrust turns away from its dash direction")
		assert(dash.rightHip.X>.5 and dash.leftHip.X<-.4,"Dash has no driving leg stance")
	end
	count+=1
	for _,names in {{"RightShoulder","LeftShoulder","Root","Waist","RightElbow","RightWrist","RightHip","LeftHip","RightKnee","LeftKnee","RightAnkle","LeftAnkle","Neck"},{"Right Shoulder","Left Shoulder","RootJoint","Right Hip","Left Hip","Neck"}} do
		for _,family in {"spear","axe","sword"} do
			local motors={}
			for _,name in names do
				local motor={Name=name,Parent=true,C0=CFrame.new(1,2,3),C1=CFrame.new(3,2,1),Transform=CFrame.new(0,.1,0)}
				function motor:IsA(class)return class=="Motor6D" end
				table.insert(motors,motor)
			end
			local grip={Name="RightGrip",Parent=true,C0=CFrame.new(),C1=CFrame.new(),Transform=CFrame.new()}
			function grip:IsA(class)return class=="Motor6D" end
			table.insert(motors,grip)
			local original={}
			for _,motor in motors do original[motor]={c0=motor.C0,c1=motor.C1,transform=motor.Transform} end
			local rig={GetDescendants=function()return motors end}
			local animation=Animation.new()
			animation:step({{rig=rig,family=family,elapsed=.05}})
			assert(motors[1].Transform~=original[motors[1]].transform,"Skill never took control of the player animation")
			for _,motor in motors do assert(motor.C0==original[motor].c0 and motor.C1==original[motor].c1)end
			assert(grip.Transform==original[grip].transform,"Skill changed the equipment grip")
			if family=="spear" then
				for _,motor in motors do
					if motor~=grip then assert(motor.Transform~=original[motor].transform,"Dash did not pose "..motor.Name) end
				end
			end
			animation:step({})
			for _,motor in motors do assert(motor.Transform==original[motor].transform,"Skill pose did not release immediately")end
			-- The Animator's next frame must be restored, rather than a stale pre-skill pose.
			animation:step({{rig=rig,family=family,elapsed=.05}})
			local ordinary=CFrame.new(0,.3,0);motors[1].Transform=ordinary
			animation:step({{rig=rig,family=family,elapsed=.1}});animation:step({})
			assert(motors[1].Transform==ordinary)
			animation:step({{rig=rig,family=family,elapsed=.05}})
			motors[1].Transform=ordinary;animation:step({})
			assert(motors[1].Transform==ordinary,"Cleanup overwrote an external animation edit")
			count+=1
		end
	end
	assert(Pose.sample("sword",0).right.Magnitude>2,"Sword starts in an idle pose")
	assert(Pose.sample("sword",.12).twist<-.8 and Pose.sample("sword",.24).twist>.8,"Combo lacks opposing dramatic cuts")
	assert(math.abs(Pose.sample("axe",.175).twist-math.pi)<.001,"Whirlwind spin has startup lag")
	print("PASS: player skill Transform takeover/restore for R6/R15 and all three family poses")
	return count+3
end

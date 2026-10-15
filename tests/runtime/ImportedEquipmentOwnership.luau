-- Run from an ordinary server Script with one genuine connected player nearby.
-- Network ownership auto mode is observable even before Roblox assigns a client.
return function(player)
	local Players=game:GetService("Players")
	local RunService=game:GetService("RunService")
	assert(RunService:IsRunning() and RunService:IsServer(),"Ownership regression requires running server physics")
	assert(player and player:IsA("Player") and player.Parent==Players,"Ownership regression requires one real connected Player")
	local playerRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	assert(playerRoot and playerRoot:IsA("BasePart"),"Connected player character must be ready")
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local japan=nil
	for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do if civ.id=="japan" then japan=civ end end
	assert(japan)
	local container=Instance.new("Folder")
	container.Name="ImportedEquipmentOwnershipFixture"
	container:SetAttribute("GeneratedBy","CivilizationTestFixture")
	container.Parent=workspace
	local ok,result=pcall(function()
		-- An overhead owned platform keeps the fixture close enough for automatic
		-- client assignment without moving the player or touching their settlement.
		local floor=Instance.new("Part")
		floor.Name="OwnershipFixtureFloor"; floor.Size=Vector3.new(36,1,20)
		floor.CFrame=CFrame.new(playerRoot.Position+Vector3.new(0,10,0))
		floor.Anchored=true; floor.Parent=container
		local rig=Rig.create(japan,floor.CFrame*CFrame.new(-6,4,0),player.UserId,1,{weaponLevel=1,armorLevel=1})
		rig.Parent=container
		assert(rig:GetAttribute("CustomMeleeModel")==true,"Regression must use the imported Japanese melee rig")
		local root=rig.HumanoidRootPart
		root:SetNetworkOwner(nil)
		for _=1,4 do RunService.Heartbeat:Wait() end
		assert(root:GetNetworkOwner()==nil and root:GetNetworkOwnershipAuto()==false,"Fixture did not establish explicit initial server ownership")
		assert((root.Position-playerRoot.Position).Magnitude<25,"Real player must remain near the ownership fixture")
		rig.Humanoid.Health=75
		local oldTool=rig:FindFirstChildOfClass("Tool")
		Rig.update(rig,japan,{weaponLevel=25,armorLevel=25})
		local tool=rig:FindFirstChildOfClass("Tool")
		assert(tool and tool~=oldTool,"Gear update did not rebuild the imported assembly")
		assert(tool:GetAttribute("Damage")==Tracks.weapon[25].damage)
		assert(math.abs(rig.Humanoid.Health-(Tracks.armor[25].health-25))<.002,"Upgrade changed missing health")
		local visual=nil
		for _,item in tool:GetDescendants() do if item:GetAttribute("TemplateId")=="katana" then visual=item end end
		assert(visual,"Ownership regression must use the real imported katana")
		local handle=tool.WarriorHandle
		local offsets={}
		for _,part in visual:GetDescendants() do
			if part:IsA("BasePart") then offsets[part]=handle.CFrame:ToObjectSpace(part.CFrame) end
		end
		local function assertAssembly(phase)
			local owner=root:GetNetworkOwner()
			assert(owner==nil and root:GetNetworkOwnershipAuto()==false,
				"Imported gear rebuild lost explicit server ownership "..phase.."; owner="..(if owner then owner.Name else "server").." auto="..tostring(root:GetNetworkOwnershipAuto()))
			local grips=0
			for _,joint in rig:GetDescendants() do
				assert(joint.Name~="RightGrip","Imported gear created a competing automatic grip")
				if joint.Name=="WarriorGrip" then
					grips+=1; assert(joint.Part0==rig["Right Arm"] and joint.Part1==handle)
				end
			end
			assert(grips==1,"Imported gear must retain exactly one manual grip")
			for part,offset in offsets do
				assert(not part.Anchored and part:GetNetworkOwner()==nil and not part:GetNetworkOwnershipAuto(),"Imported weapon part escaped server ownership")
				local actual=handle.CFrame:ToObjectSpace(part.CFrame)
				assert((actual.Position-offset.Position).Magnitude<.03 and actual.LookVector:Dot(offset.LookVector)>.999,"Imported weapon moved independently of its grip")
			end
		end
		-- Never repair ownership in this test after the production gear update.
		assertAssembly("immediately after update")
		local start=root.Position
		rig.Humanoid:MoveTo(floor.Position+Vector3.new(5,4,0))
		local untilTime=os.clock()+1
		repeat
			RunService.Heartbeat:Wait()
			assertAssembly("during subsequent physics frames")
		until os.clock()>=untilTime
		assert((Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(start.X,0,start.Z)).Magnitude>2,"Upgraded NPC never physically walked on the fixture platform")
		return {ok=true,cases=1,realPlayerNearby=true,explicitServerOwnership=true,
			message="Imported gear upgrade retains explicit server ownership, one manual grip, rigid katana geometry and real Humanoid movement"}
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

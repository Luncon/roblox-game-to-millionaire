-- One ordinary server Script, 26 real NPCs; no simulated connected owners or combat.
return function()
	local RunService=game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning())
	local context=require(script.Parent.SoloTestContext)
	assert(context.store.isFakeProfileStore and game:GetAttribute("SoloVerificationEnabled"),"Movement fixtures require the fake solo bootstrap")
	local Game=game.ServerScriptService.Game
	local Rig=require(Game.WarriorRig)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local Ranged=require(game.ReplicatedStorage.Shared.RangedConfig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name="AllCivilizationOutfitMovementFixture"
	container:SetAttribute("GeneratedBy","CivilizationPlaytest")
	container.Parent=workspace
	local contexts={}
	local function captureWelds(rig)
		local result={}
		for _,joint in rig:GetDescendants() do
			if joint:IsA("WeldConstraint") then
				assert(joint.Part0 and joint.Part1 and joint.Part0:IsDescendantOf(rig) and joint.Part1:IsDescendantOf(rig),"Outfit assembly contains an external or dangling weld")
				table.insert(result,{joint=joint,offset=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)})
			end
		end
		return result
	end
	local function assertRig(entry)
		local rig,root=entry.rig,entry.rig.HumanoidRootPart
		assert(rig.Humanoid.Health>0 and not root.Anchored and root:GetNetworkOwner()==nil and not root:GetNetworkOwnershipAuto(),"Outfitted NPC lost explicit server physics: "..entry.key)
		local tool=rig:FindFirstChildOfClass("Tool")
		assert(tool and not tool.RequiresHandle and tool:FindFirstChild("WarriorHandle"))
		local damage=Tracks.weapon[entry.level].damage*(if entry.role=="ranged" then Ranged.damageMultiplier else 1)
		assert(tool:GetAttribute("Damage")==damage and rig:GetAttribute("WarriorDamage")==damage)
		assert(math.abs(rig.Humanoid.MaxHealth-Tracks.armor[entry.level].health)<.002)
		local grips=0
		for _,item in rig:GetDescendants() do
			assert(item.Name~="RightGrip","Outfitted NPC gained an automatic grip: "..entry.key)
			if item.Name=="WarriorGrip" then grips+=1;assert(item.Part0==rig["Right Arm"] and item.Part1==tool.WarriorHandle) end
			if item:IsA("BasePart") then assert(not item.Anchored,"Outfit anchored a real NPC") end
		end
		assert(grips==1)
		for _,record in entry.welds do
			local joint=record.joint
			local current=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)
			assert((current.Position-record.offset.Position).Magnitude<.06 and current.LookVector:Dot(record.offset.LookVector)>.998,
				"Body/weapon visual lost welded rigidity: "..entry.key.." / "..joint.Name)
		end
	end
	local ok,result=pcall(function()
		local floor=Instance.new("Part")
		floor.Name="IsolatedOutfitMovementFloor";floor.Anchored=true
		floor.Size=Vector3.new(100,1,260);floor.CFrame=CFrame.new(-4500,20,6000);floor.Parent=container
		for index,civ in catalog do
			for column,role in {"warrior","ranged"} do
				local level=if role=="warrior" then 1 else 25
				local spawn=floor.CFrame*CFrame.new(-35+(column-1)*40,4,(index-7)*18)
				local rig=Rig.create(civ,spawn,-91000-index,1,{weaponLevel=level,armorLevel=level},role)
				rig.Parent=container
				rig.HumanoidRootPart:SetNetworkOwner(nil)
				assert((rig:GetAttribute("OutfitCivilizationId")==civ.id) or rig:GetAttribute("CustomMeleeModel")==true,"Civilization NPC spawned without its outfit")
				local entry={rig=rig,civ=civ,role=role,level=level,key=civ.id..":"..role,start=rig.HumanoidRootPart.Position}
				entry.welds=captureWelds(rig)
				table.insert(contexts,entry)
				rig.Humanoid:MoveTo(spawn.Position+Vector3.new(12,0,0))
			end
		end
		assert(#contexts==26,"Movement cohort must cover both troop classes for all thirteen civilizations")
		local started=os.clock()
		repeat
			RunService.Heartbeat:Wait()
			for _,entry in contexts do
				Rig.animate(entry.rig,os.clock(),true,false)
				assertRig(entry)
			end
		until os.clock()-started>=2
		local distances={};local minimum=math.huge
		for _,entry in contexts do
			local delta=entry.rig.HumanoidRootPart.Position-entry.start
			local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
			assert(distance>3,"Outfitted Humanoid did not physically walk: "..entry.key.." distance="..distance)
			distances[entry.key]=distance;minimum=math.min(minimum,distance)
		end
		return {ok=true,cases=1,npcCount=#contexts,minimumDisplacement=minimum,distances=distances,elapsed=os.clock()-started,
			message="All thirteen melee and ranged variants physically walked with rigid outfits/weapons, one manual grip, unchanged stats and explicit server ownership"}
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

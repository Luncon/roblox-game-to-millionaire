return function(module)
	local Rig=require(module or game.ServerScriptService.Game.WarriorRig)
	local Skills=require(game.ReplicatedStorage.Shared.WeaponSkillConfig)
	local variants=require(game.ReplicatedStorage.Shared.WarriorConfig).variants
	local sources={}
	for _,name in {"NPCTemplates","EquipmentTemplates","OutfitTemplates"} do
		local folder=game.ServerStorage:FindFirstChild(name)
		if folder then for _,item in folder:GetDescendants() do
			if item:IsA("Motor6D") or item:IsA("Weld") then sources[item]={parent=item.Parent,c0=item.C0,c1=item.C1}
			elseif item:IsA("BasePart") then sources[item]={parent=item.Parent,frame=item.CFrame,size=item.Size}end
		end end
	end
	local cases=0
	for _,civ in require(game.ReplicatedStorage.Shared.Civilizations) do
		local rig=Rig.create(civ,CFrame.new(),101,1)
		local ok,message=pcall(function()
			local shoulder=rig.Torso["Right Shoulder"]
			local rest=shoulder:GetAttribute("RestC0") or shoulder.C0
			local tool=assert(rig:FindFirstChildOfClass("Tool"))
			local family=assert(Skills.family(variants[civ.id].weaponKind))
			local grips={}
			for _,joint in rig:GetDescendants() do
				if (joint:IsA("Motor6D") or joint:IsA("Weld")) and joint.Part1 and joint.Part1:IsDescendantOf(tool) then
					grips[joint]={joint.C0,joint.C1}
				end
			end
			rig:SetAttribute("WeaponSkillActive",family)
			rig:SetAttribute("WeaponSkillStartedAt",workspace:GetServerTimeNow()-(if family=="sword" then .17 else .1))
			Rig.animate(rig,1,false)
			assert(shoulder.C0~=rest and shoulder:GetAttribute("RestC0")==rest)
			for joint,original in grips do assert(joint.C0==original[1] and joint.C1==original[2])end
			rig:SetAttribute("WeaponSkillActive",nil);rig:SetAttribute("CombatPhase","idle");Rig.animate(rig,1,false)
			assert(shoulder:GetAttribute("RestC0")==rest)
		end)
		rig:Destroy();assert(ok,message);cases+=1
	end
	local catalog={};for _,civ in require(game.ReplicatedStorage.Shared.Civilizations)do catalog[civ.id]=civ end
	for _,entry in {{id="sparta"},{id="persia"},{id="maurya"},{id="ming"},{id="sparta",kind="ranged"},{id="rome",kind="ranged"}}do
		local rig=Rig.create(catalog[entry.id],CFrame.new(0,10000,0)*CFrame.Angles(0,.63,0),101,1,nil,entry.kind)
		local ok,message=pcall(function()
			local tool=assert(rig:FindFirstChildOfClass("Tool"))
			local originalGrip=tool.Grip
			local grips={}
			for _,joint in rig:GetDescendants()do
				if (joint:IsA("Motor6D") or joint:IsA("Weld")) and joint.Part1 and joint.Part1:IsDescendantOf(tool)then
					grips[joint]={c0=joint.C0,c1=joint.C1}
				end
			end
			local shoulder=rig.Torso["Right Shoulder"]
			local rest=shoulder:GetAttribute("RestC0") or shoulder.C0
			rig.HumanoidRootPart.Anchored=true;rig.Parent=workspace
			rig:SetAttribute("WeaponSkillActive","spear")
			local handle=tool:FindFirstChild("WarriorHandle") or tool:FindFirstChild("Handle")
			assert(handle,"Spear fixture has no handle")
			for _,elapsed in {0,.04,.1,.18} do
				rig:SetAttribute("WeaponSkillStartedAt",workspace:GetServerTimeNow()-elapsed)
				rig:SetAttribute("LastHitAt",workspace:GetServerTimeNow())
				Rig.animate(rig,1,false)
				game:GetService("RunService").Heartbeat:Wait()
				game:GetService("RunService").Heartbeat:Wait()
				local forward=handle.CFrame.UpVector:Dot(rig.HumanoidRootPart.CFrame.LookVector)
				assert(forward>=.98,entry.id.." "..(entry.kind or "warrior").." spear tip is not level and forward: "..forward)
				assert(rig.Torso.CFrame.UpVector:Dot(rig.HumanoidRootPart.CFrame.LookVector)>.3,"NPC does not lean into the dash")
			end
			assert(tool.Grip==originalGrip and shoulder:GetAttribute("RestC0")==rest)
			for joint,original in grips do assert(joint.C0==original.c0 and joint.C1==original.c1,"Spear skill replaced its equipment grip")end
			rig:SetAttribute("WeaponSkillActive",nil);rig:SetAttribute("WeaponSkillStartedAt",nil)
			rig:SetAttribute("CombatPhase","idle");Rig.animate(rig,1,false)
			assert(tool.Grip==originalGrip and shoulder:GetAttribute("RestC0")==rest)
		end)
		rig:Destroy();assert(ok,message);cases+=1
	end
	for item,value in sources do
		assert(item.Parent==value.parent)
		if item:IsA("Motor6D") or item:IsA("Weld") then assert(item.C0==value.c0 and item.C1==value.c1)
		else assert(item.CFrame==value.frame and item.Size==value.size)end
	end
	return cases
end

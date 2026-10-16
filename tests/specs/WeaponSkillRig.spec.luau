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
			rig:SetAttribute("WeaponSkillStartedAt",workspace:GetServerTimeNow()-(if family=="sword" then .17 else .3))
			Rig.animate(rig,1,false)
			assert(shoulder.C0~=rest and shoulder:GetAttribute("RestC0")==rest)
			for joint,original in grips do assert(joint.C0==original[1] and joint.C1==original[2])end
			rig:SetAttribute("WeaponSkillActive",nil);rig:SetAttribute("CombatPhase","idle");Rig.animate(rig,1,false)
			assert(shoulder:GetAttribute("RestC0")==rest)
		end)
		rig:Destroy();assert(ok,message);cases+=1
	end
	local catalog={};for _,civ in require(game.ReplicatedStorage.Shared.Civilizations)do catalog[civ.id]=civ end
	for _,entry in {{id="sparta"},{id="maurya"},{id="ming"},{id="sparta",kind="ranged"},{id="rome",kind="ranged"}}do
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
			rig:SetAttribute("WeaponSkillStartedAt",workspace:GetServerTimeNow()-.3)
			Rig.animate(rig,1,false)
			game:GetService("RunService").Heartbeat:Wait()
			game:GetService("RunService").Heartbeat:Wait()
			local longest,length,axis=nil,0,nil
			for _,part in tool:GetDescendants()do if part:IsA("BasePart")then
				for _,choice in {{part.Size.X,part.CFrame.RightVector},{part.Size.Y,part.CFrame.UpVector},{part.Size.Z,part.CFrame.LookVector}}do
					if choice[1]>length then longest,length,axis=part,choice[1],choice[2]end
				end
			end end
			assert(longest and axis,"Spear skill fixture has no visible weapon geometry")
			local forward=math.abs(axis:Dot(rig.HumanoidRootPart.CFrame.LookVector))
			assert(forward>=.9,entry.id.." "..(entry.kind or "warrior").." spear skill points away from its dash: "..forward)
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

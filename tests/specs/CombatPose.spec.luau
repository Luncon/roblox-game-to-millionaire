return function(module)
	local Rig=require(module or game.ServerScriptService.Game.WarriorRig)
	local civs=require(game.ReplicatedStorage.Shared.Civilizations)
	local cases=0
	assert(type(Rig.combatStyle)=="function","Weapon-specific combat poses are missing")
	local function pose(rig,phase,progress)
		rig:SetAttribute("CombatPhase",phase)
		rig:SetAttribute("CombatPhaseStartedAt",workspace:GetServerTimeNow()-progress*.3)
		rig:SetAttribute("CombatPhaseDuration",.3)
		Rig.animate(rig,1,false)
	end
	local styles={}
	for _,entry in {{id="sparta",style="thrust"},{id="rome",style="slash"},{id="vikings",style="chop"},
		{id="seneca",kind="ranged",style="bow"},{id="britain",kind="ranged",style="firearm"}}do
		local civ=nil;for _,c in civs do if c.id==entry.id then civ=c end end
		local rig=Rig.create(civ,CFrame.new(),1,1,nil,entry.kind)
		assert(Rig.combatStyle(rig)==entry.style,"Wrong pose for "..entry.id)
		local shoulder=rig.Torso["Right Shoulder"]
		local rest=shoulder:GetAttribute("RestC0")
		pose(rig,"windup",.9);local prepared=shoulder.C0
		pose(rig,"contact",.6);local struck=shoulder.C0
		assert(prepared~=struck and prepared~=rest,"Attack does not visibly prepare and strike")
		styles[entry.style]=struck
		pose(rig,"idle",0)
		assert(shoulder:GetAttribute("RestC0")==rest,"Combat changed the imported rest geometry")
		for _,p in rig:GetDescendants()do
			if p:IsA("BasePart")then assert(not p.Anchored,"Combat pose anchored a troop")end
		end
		rig:Destroy();cases+=1
	end
	assert(styles.thrust~=styles.slash and styles.slash~=styles.chop,"Melee roles share the same swing")
	local rig=Rig.createNeutral(CFrame.new(),"warrior")
	rig:SetAttribute("LastHitAt",workspace:GetServerTimeNow())
	Rig.animate(rig,1,false)
	local flash=assert(rig:FindFirstChild("CombatHitFlash"),"Accepted hits have no visible feedback")
	assert(flash.Enabled)
	rig:SetAttribute("LastHitAt",workspace:GetServerTimeNow()-1)
	Rig.animate(rig,1,false);assert(not flash.Enabled,"Hit flash did not clear")
	rig:Destroy()
	cases+=1
	for _,entry in {{id="sparta"},{id="britain",kind="ranged"},{id="seneca",kind="ranged",vertical=true},
		{id="neutral",vertical=true,neutral=true},{id="procedural",vertical=true,neutral=true,procedural=true}}do
		local civ;for _,c in civs do if c.id==entry.id then civ=c end end
		local model=if entry.neutral then Rig.createNeutral(CFrame.new(0,8,0),"ranged") else Rig.create(civ,CFrame.new(0,8,0),1,1,nil,entry.kind)
		local ok,reason=pcall(function()
			if entry.procedural then
				-- Independent geometry fixture with Equipment's fallback hand basis.
				local arm=model["Right Arm"]
				for _,p in model.NeutralWeapon:GetChildren()do if p:IsA("BasePart")then
					for _,w in p:GetChildren()do if w:IsA("WeldConstraint")then w:Destroy()end end
				end end
				for _,p in model.NeutralWeapon:GetChildren()do if p:IsA("BasePart")then
					p.CFrame=arm.CFrame*CFrame.Angles(-math.pi/2,0,0)*arm.CFrame:ToObjectSpace(p.CFrame)
					local weld=Instance.new("WeldConstraint");weld.Part0,weld.Part1,weld.Parent=arm,p,p
				end end
				model:SetAttribute("CombatBowBasis","procedural")
			elseif entry.id=="seneca" then assert(model:GetAttribute("CombatBowBasis")=="imported")
			elseif entry.neutral then assert(model:GetAttribute("CombatBowBasis")=="neutral")end
			model.HumanoidRootPart.Anchored=true;model.Parent=workspace
			pose(model,"contact",.2)
			game:GetService("RunService").Heartbeat:Wait()
			game:GetService("RunService").Heartbeat:Wait()
			local longest,length,axis=nil,0,nil
			for _,tool in model:GetChildren()do if tool:IsA("Tool") or tool.Name=="NeutralWeapon" then
				for _,part in tool:GetDescendants()do if part:IsA("BasePart")then
					for _,choice in {{part.Size.X,part.CFrame.RightVector},{part.Size.Y,part.CFrame.UpVector},{part.Size.Z,part.CFrame.LookVector}}do
						if choice[1]>length then longest,length,axis=part,choice[1],choice[2]end
					end
				end end
			end end
			assert(longest and axis,"No visible weapon geometry")
			local expected=if entry.vertical then model.HumanoidRootPart.CFrame.UpVector else model.HumanoidRootPart.CFrame.LookVector
			assert(math.abs(axis:Dot(expected))>.9,"Contact pose misaligns the imported "..entry.id.." weapon")
		end)
		model:Destroy();assert(ok,reason);cases+=1
	end
	return cases
end

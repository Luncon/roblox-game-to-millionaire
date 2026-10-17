return function(module)
	local Motion=require(module or game.ServerScriptService.Game.EncounterMotion)
	local cases=0
	local function test(name,fn)
		local rig=Instance.new("Model")
		local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true
		root.CFrame=CFrame.new(3,5,7)*CFrame.Angles(0,.6,0);root.Parent=rig
		local humanoid=Instance.new("Humanoid");humanoid.Parent=rig
		local navigator={stops=0,routes=0,directs=0,steps=0}
		function navigator:stop()self.stops+=1 end
		function navigator:setGoal(goal)self.routes+=1;self.goal=goal end
		function navigator:step()self.steps+=1 end
		function navigator:walkCombat()self.directs+=1;return true end
		local ok,message=pcall(fn,rig,root,humanoid,navigator)
		rig:Destroy();assert(ok,message);cases+=1;print("PASS: "..name)
	end
	test("skill plans preserve their controller's facing lock without a target-facing field",function(rig,root,humanoid,navigator)
		local original=root.CFrame
		humanoid.AutoRotate=false;humanoid.WalkSpeed=0
		Motion.apply(rig,navigator,{}, {phase="skill",speed=0,state="Fighting"},1)
		assert(not humanoid.AutoRotate and humanoid.WalkSpeed==0,"Ordinary motion unlocked a skill")
		assert(root.CFrame==original and navigator.stops==1 and navigator.routes==0)
	end)
	test("active skill attributes reject stale ordinary movement and facing decisions",function(rig,root,humanoid,navigator)
		local original=root.CFrame
		rig:SetAttribute("WeaponSkillActive","spear")
		local goal=root.Position+Vector3.new(5,0,0)
		Motion.apply(rig,navigator,{}, {phase="idle",goal=goal,facing=goal,direct=true,speed=12},1)
		assert(not humanoid.AutoRotate and humanoid.WalkSpeed==0,"A stale ordinary plan overrode skill movement")
		assert(root.CFrame==original and navigator.stops==1 and navigator.routes==0 and navigator.directs==0)
	end)
	test("cancelling a skill restores ordinary travel rotation speed and routing",function(rig,root,humanoid,navigator)
		rig:SetAttribute("WeaponSkillActive","spear")
		Motion.apply(rig,navigator,{}, {phase="skill",speed=0},1)
		rig:SetAttribute("WeaponSkillActive",nil);Motion.clear(rig)
		local goal=root.Position+Vector3.new(20,0,0)
		Motion.apply(rig,navigator,{}, {phase="idle",goal=goal,direct=false,speed=12},2)
		assert(humanoid.AutoRotate and humanoid.WalkSpeed==12)
		assert(navigator.goal==goal and navigator.routes==1 and navigator.steps==1)
		assert(rig:GetAttribute("CombatPhase")=="idle")
	end)
	test("ordinary contact still faces its target and holds movement",function(rig,root,humanoid,navigator)
		local facing=root.Position+Vector3.new(5,0,0)
		Motion.apply(rig,navigator,{}, {phase="contact",facing=facing,speed=12},1)
		assert(not humanoid.AutoRotate and root.CFrame.LookVector:Dot(Vector3.xAxis)>.999)
		assert(navigator.stops==1 and navigator.routes==0)
	end)
	test("medic escort keeps marching speed on short direct following legs",function(rig,root,humanoid,navigator)
		rig:SetAttribute("WarriorClass","medic")
		Motion.apply(rig,navigator,{}, {phase="idle",goal=root.Position+Vector3.new(5,0,0),direct=true,speed=12},1)
		assert(humanoid.WalkSpeed==12 and navigator.directs==1)
	end)
	return cases
end

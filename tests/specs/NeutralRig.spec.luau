return function()
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local snapshots={}
	for _,name in {"NPCTemplates","EquipmentTemplates","OutfitTemplates"} do
		local folder=game.ServerStorage:FindFirstChild(name)
		if folder then for _,model in folder:GetChildren() do snapshots[model]=#model:GetDescendants() end end
	end
	for _,kind in {"warrior","ranged"} do
		local rig=Rig.createNeutral(CFrame.new(20,10000,30),kind)
		assert(rig.Parent==nil and rig:GetAttribute("CivilizationId")==nil and rig:GetAttribute("OwnerId")==nil)
		assert(rig:GetAttribute("WarriorClass")==kind and rig:GetAttribute("CustomMeleeModel")==nil)
		assert(rig.Humanoid.Health==100 and rig.Humanoid.MaxHealth==100)
		assert(rig.Humanoid.DisplayName:find("Neutral",1,true))
		assert((rig:GetPivot().Position-Vector3.new(20,10000,30)).Magnitude<.01)
		assert(rig.Head:FindFirstChildOfClass("SpecialMesh") and rig.Head:FindFirstChildOfClass("Decal"))
		local weapon=rig:FindFirstChild("NeutralWeapon");assert(weapon)
		for _,item in rig:GetDescendants() do
			assert(not item:IsA("LuaSourceContainer"),"Generic opponent imported behavior")
			if item:IsA("BasePart") then assert(not item.Anchored) end
		end
		Rig.animate(rig,1,true,true)
		rig:Destroy()
	end
	for model,descendants in snapshots do assert(model.Parent and #model:GetDescendants()==descendants) end
	print("PASS: generic neutral rigs have both classes, inert weapons and no civilization templates")
	return 1
end

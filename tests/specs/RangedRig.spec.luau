return function()
	local module=game.ReplicatedStorage.Shared:FindFirstChild("RangedConfig")
	assert(module,"RangedConfig is not implemented yet")
	local Config=require(module)
	local Rig=require(game.ServerScriptService.Game.WarriorRig)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local count=0
	local rigs={}
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		test("all thirteen civilizations have a distinct configured ranged warrior",function()
			for _,civ in catalog do
				local variant=Config.variants[civ.id]
				assert(variant and type(variant.weaponName)=="string")
				local rig=Rig.create(civ,CFrame.new(0,10000,0),101,1,{weaponLevel=1,armorLevel=1},"ranged")
				table.insert(rigs,rig)
				assert(rig.Parent==nil and rig:GetAttribute("WarriorClass")=="ranged")
				assert(rig:GetAttribute("CivilizationId")==civ.id)
				local tool=rig:FindFirstChildOfClass("Tool")
				assert(tool and string.find(tool.Name,variant.weaponName,1,true))
			end
		end)
		test("ranged warriors inherit every owner tier with eighty-percent damage",function()
			for index,civ in catalog do
				local rig=rigs[index]
				for level,damage in {8,11,15,20} do
					Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
					assert(rig:GetAttribute("WarriorClass")=="ranged")
					assert(rig:GetAttribute("WarriorDamage")==damage)
					assert(rig.Humanoid.MaxHealth==({100,115,135,170})[level])
					assert(rig:FindFirstChildOfClass("Tool"):GetAttribute("Damage")==damage)
				end
			end
		end)
		return count
	end)
	for _,rig in rigs do rig:Destroy() end
	assert(ok,result)
	return result
end

return function()
	local module = game.ServerScriptService.Game:FindFirstChild("WarriorRig")
	assert(module, "WarriorRig is not implemented yet")
	local Rig = require(module)
	local Config = require(game.ReplicatedStorage.Shared.WarriorConfig)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local rigs = {}
	local count = 0
	local function test(name, callback) callback(); count += 1; print("PASS: " .. name) end
	local function weapon(rig)
		for _, item in rig:GetChildren() do if item:IsA("Tool") then return item end end
		error("Warrior is not equipped with a melee tool")
	end
	local ok, result = pcall(function()
		test("all thirteen warriors have an unparented articulated humanoid rig", function()
			for i, civ in catalog do
				local frame = CFrame.new(i*10,10000,0) * CFrame.Angles(0,.5,0)
				local rig = Rig.create(civ,frame,101,1)
				table.insert(rigs,rig)
				assert(rig:IsA("Model") and rig.Parent == nil)
				assert(rig:FindFirstChildOfClass("Humanoid") and rig:FindFirstChild("HumanoidRootPart"))
				assert((rig:GetPivot().Position-frame.Position).Magnitude < .05)
				assert(rig:GetAttribute("OwnerId") == 101 and rig:GetAttribute("CivilizationId") == civ.id)
				assert(rig:GetAttribute("PlotId") == 1 and rig:GetAttribute("WarriorClass") == "warrior")
				local joints = 0
				for _, item in rig:GetDescendants() do
					if item:IsA("BasePart") then assert(not item.Anchored, "Warrior cannot walk with anchored parts") end
					if item:IsA("Motor6D") then
						assert(item.Part0 and item.Part1 and item.Part0:IsDescendantOf(rig) and item.Part1:IsDescendantOf(rig))
						joints += 1
					end
				end
				assert(joints >= 6, "R6 limbs are not connected")
			end
		end)
		test("all civilizations use configured melee equipment at every owner tier", function()
			for i, civ in catalog do
				local rig = rigs[i]
				assert(Config.variants[civ.id] and Config.variants[civ.id].weaponKind ~= "bow"
					and Config.variants[civ.id].weaponKind ~= "musket")
				for level, damage in {10,14,19,25} do
					Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
					assert(rig:GetAttribute("WeaponLevel") == level and rig:GetAttribute("ArmorLevel") == level)
					assert(rig:GetAttribute("WarriorDamage") == damage)
					assert(rig.Humanoid.MaxHealth == ({100,115,135,170})[level])
					assert(weapon(rig):GetAttribute("Damage") == damage)
					assert(weapon(rig):GetAttribute("WarriorClass") == "warrior")
					assert(string.find(weapon(rig).Name,Config.variants[civ.id].weaponName,1,true))
				end
			end
		end)
		test("weapon refresh cannot heal and armor preserves exact missing health", function()
			local rig = Rig.create(catalog[1],CFrame.new(),101,1,{weaponLevel=1,armorLevel=1})
			table.insert(rigs,rig)
			rig.Humanoid.Health = 70
			Rig.update(rig,catalog[1],{weaponLevel=2,armorLevel=1})
			assert(rig.Humanoid.Health == 70 and rig.Humanoid.MaxHealth == 100)
			Rig.update(rig,catalog[1],{weaponLevel=2,armorLevel=2})
			assert(rig.Humanoid.Health == 85 and rig.Humanoid.MaxHealth == 115)
			Rig.update(rig,catalog[1],{weaponLevel=2,armorLevel=2})
			assert(rig.Humanoid.Health == 85, "Repeated refresh healed damage")
		end)
		test("new replacements inherit latest owner tiers at full health", function()
			local rig = Rig.create(catalog[3],CFrame.new(),202,2,{weaponLevel=3,armorLevel=4})
			table.insert(rigs,rig)
			assert(rig.Humanoid.Health == 170 and rig.Humanoid.MaxHealth == 170)
			assert(rig:GetAttribute("WarriorDamage") == 19 and weapon(rig):GetAttribute("Damage") == 19)
		end)
		test("armor downgrades preserve health deficit without double clamping or healing", function()
			local rig = Rig.create(catalog[1],CFrame.new(),101,1,{weaponLevel=1,armorLevel=4})
			table.insert(rigs,rig)
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=1})
			assert(rig.Humanoid.MaxHealth == 100 and rig.Humanoid.Health == 100)
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=2})
			rig.Humanoid.Health = 85
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=1})
			assert(rig.Humanoid.MaxHealth == 100 and rig.Humanoid.Health == 70)
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=1})
			assert(rig.Humanoid.Health == 70)
		end)
		return count
	end)
	for _, rig in rigs do rig:Destroy() end
	assert(ok,result)
	return result
end

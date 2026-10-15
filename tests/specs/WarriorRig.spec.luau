return function()
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) assert(math.abs(actual-expected)<.002,tostring(actual).." ~= "..expected) end
	local module = game.ServerScriptService.Game:FindFirstChild("WarriorRig")
	assert(module, "WarriorRig is not implemented yet")
	local Rig = require(module)
	local Config = require(game.ReplicatedStorage.Shared.WarriorConfig)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local rigs = {}
	local warriors = {}
	local count = 0
	local function test(name, callback) callback(); count += 1; print("PASS: " .. name) end
	local function weapon(rig)
		for _, item in rig:GetChildren() do if item:IsA("Tool") then return item end end
		error("Warrior is not equipped with a melee tool")
	end
	local ok, result = pcall(function()
		test("all melee and ranged troops have normal head meshes that survive gear upgrades",function()
			for _,civ in catalog do
				for _,kind in {"warrior","ranged"} do
					local rig=Rig.create(civ,CFrame.new(0,10000,0),101,1,nil,kind)
					table.insert(rigs,rig)
					local head=rig.Head
					local mesh=head:FindFirstChildOfClass("SpecialMesh")
					assert(mesh and mesh.MeshType==Enum.MeshType.Head,"Rectangular troop head: "..civ.id.." / "..kind)
					local scale=mesh.Scale
					local face=head:FindFirstChildOfClass("Decal")
					if rig:GetAttribute("CustomMeleeModel")~=true then
						assert(scale==Vector3.new(1.25,1.25,1.25),"Generated head must use classic Roblox proportions")
						assert(face and face.Face==Enum.NormalId.Front and face.Texture~="","Generated troop has no face")
					else
						local original=game.ServerStorage.NPCTemplates[civ.id].Head:FindFirstChildOfClass("SpecialMesh")
						assert(original and scale==original.Scale,"Custom head proportions changed")
					end
					Rig.update(rig,civ,{weaponLevel=50,armorLevel=50})
					assert(rig.Head==head and mesh.Parent==head and mesh.Scale==scale,"Gear upgrade replaced the troop head")
					assert(not face or face.Parent==head,"Gear upgrade removed the troop face")
				end
			end
		end)
		test("all thirteen warriors have an unparented articulated humanoid rig", function()
			for i, civ in catalog do
				local frame = CFrame.new(i*10,10000,0) * CFrame.Angles(0,.5,0)
				local rig = Rig.create(civ,frame,101,1)
				table.insert(rigs,rig)
				warriors[i]=rig
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
				local rig = warriors[i]
				assert(Config.variants[civ.id] and Config.variants[civ.id].weaponKind ~= "bow"
					and Config.variants[civ.id].weaponKind ~= "musket")
				for level=1,50 do
					local damage=Tracks.weapon[level].damage
					Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
					assert(rig:GetAttribute("WeaponLevel") == level and rig:GetAttribute("ArmorLevel") == level)
					assert(rig:GetAttribute("WarriorDamage") == damage)
					assert(math.abs(rig.Humanoid.MaxHealth-Tracks.armor[level].health)<.002)
					near(rig.Humanoid.Health,Tracks.armor[level].health)
					assert(weapon(rig):GetAttribute("Damage") == damage)
					assert(weapon(rig):GetAttribute("WarriorClass") == "warrior")
					assert(string.find(weapon(rig).Name,Config.variants[civ.id].weaponName,1,true))
				end
			end
		end)
		test("unlocked armor milestones remain visible through level fifty for all civilizations",function()
			for _,civ in catalog do
				local rig=Rig.create(civ,CFrame.new(),101,1)
				table.insert(rigs,rig)
				for _,level in {1,9,10,19,20,39,40,41,50} do
					Rig.update(rig,civ,{weaponLevel=level,armorLevel=level})
					local armor=rig.CivilizationArmor
					assert((armor:FindFirstChild("ShoulderGuard")~=nil)==(level>=10))
					assert((armor:FindFirstChild("TierTrim")~=nil)==(level>=20))
					assert((armor:FindFirstChild("ChampionCloak")~=nil)==(level>=40))
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
			near(rig.Humanoid.Health,70+40/49); near(rig.Humanoid.MaxHealth,100+40/49)
			Rig.update(rig,catalog[1],{weaponLevel=2,armorLevel=2})
			near(rig.Humanoid.Health,70+40/49)
		end)
		test("new replacements inherit latest owner tiers at full health", function()
			local rig = Rig.create(catalog[3],CFrame.new(),202,2,{weaponLevel=25,armorLevel=50})
			table.insert(rigs,rig)
			near(rig.Humanoid.Health,140); near(rig.Humanoid.MaxHealth,140)
			near(rig:GetAttribute("WarriorDamage"),Tracks.weapon[25].damage); near(weapon(rig):GetAttribute("Damage"),Tracks.weapon[25].damage)
		end)
		test("armor downgrades preserve health deficit without double clamping or healing", function()
			local rig = Rig.create(catalog[1],CFrame.new(),101,1,{weaponLevel=1,armorLevel=50})
			table.insert(rigs,rig)
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=1})
			assert(rig.Humanoid.MaxHealth == 100 and rig.Humanoid.Health == 100)
			Rig.update(rig,catalog[1],{weaponLevel=1,armorLevel=2})
			rig.Humanoid.Health = Tracks.armor[2].health-30
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

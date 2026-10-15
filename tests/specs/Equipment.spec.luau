return function()
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) assert(math.abs(actual-expected)<.002,tostring(actual).." ~= "..expected) end
	local Equipment = require(game.ServerScriptService.Game.Equipment)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	-- Assistant threads cannot create Player instances; only this boundary is a test double.
	local inventory = Instance.new("Folder")
	inventory.Name = "EquipmentTestInventory"
	inventory.Parent = workspace
	local backpack = Instance.new("Backpack")
	backpack.Parent = inventory
	local player = {Character = nil}
	function player:FindFirstChildOfClass(className)
		return inventory:FindFirstChildOfClass(className)
	end
	local character = Instance.new("Model")
	character.Name = "EquipmentTestRig"
	character.Parent = workspace
	for _, definition in {
		{"HumanoidRootPart", Vector3.new(2,2,1), Vector3.new(0,0,0)},
		{"Torso", Vector3.new(2,2,1), Vector3.new(0,0,0)},
		{"Head", Vector3.new(2,1,1), Vector3.new(0,1.5,0)},
		{"Right Arm", Vector3.new(1,2,1), Vector3.new(1.5,0,0)},
		{"Left Arm", Vector3.new(1,2,1), Vector3.new(-1.5,0,0)},
		{"Right Leg", Vector3.new(1,2,1), Vector3.new(.5,-2,0)},
		{"Left Leg", Vector3.new(1,2,1), Vector3.new(-.5,-2,0)},
	} do
		local part = Instance.new("Part")
		part.Name, part.Size = definition[1], definition[2]
		part.Position = Vector3.new(10000,10000,10000) + definition[3]
		part.Anchored, part.CanCollide = true, false
		part.Parent = character
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.MaxHealth, humanoid.Health = 150, 70
	humanoid.Parent = character
	player.Character = character
	local unrelated = Instance.new("Model")
	unrelated.Name = "AvatarAccessory"
	unrelated.Parent = character
	local count = 0
	local function test(name, callback)
		callback()
		count += 1
		print("PASS: " .. name)
	end
	local function ownedTools()
		local result = {}
		for _, parent in {character, backpack} do
			for _, item in parent:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("GeneratedBy") == "CivilizationEquipment" then
					table.insert(result, item)
				end
			end
		end
		return result
	end
	local ok, result = pcall(function()
		test("all civilizations equip identifiable themed gear at every tier", function()
			for _, civ in catalog do
				for level=1,50 do
					local damage=Tracks.weapon[level].damage
					assert(Equipment.apply(player, civ, {weaponLevel=level, armorLevel=level}))
					local tools = ownedTools()
					assert(#tools == 1, "Duplicate owned tools after equipment rebuild")
					local tool = tools[1]
					assert(tool:GetAttribute("CivilizationId") == civ.id)
					assert(tool:GetAttribute("WeaponLevel") == level and tool:GetAttribute("Damage") == damage)
					assert(not tool.CanBeDropped and tool:FindFirstChild("Handle"))
					local armor = character:FindFirstChild("CivilizationArmor")
					assert(armor and armor:GetAttribute("CivilizationId") == civ.id)
					assert(armor:GetAttribute("ArmorLevel") == level and type(armor:GetAttribute("Style")) == "string")
					local source=game.ServerStorage.OutfitTemplates:FindFirstChild(civ.id)
					assert(source,"Missing civilization outfit source: "..civ.id)
					local clothed=false
					for _,definition in {{"Shirt","ShirtTemplate"},{"Pants","PantsTemplate"},{"ShirtGraphic","Graphic"}} do
						local garment=source:FindFirstChildOfClass(definition[1])
						if garment and garment[definition[2]]~="" then
							local equipped=character:FindFirstChildOfClass(definition[1])
							assert(equipped and equipped[definition[2]]==garment[definition[2]],"Civilization garment missing at tier "..level)
							clothed=true
						end
					end
					for _,item in armor:GetDescendants() do if item:GetAttribute("OutfitCivilizationId")==civ.id then clothed=true end end
					assert(clothed,"No mapped clothing/body outfit equipped for "..civ.id)
					assert(unrelated.Parent==character)
				end
			end
		end)
		test("armor preserves base health and repeated apply cannot heal repeatedly", function()
			Equipment.clear(player)
			humanoid.MaxHealth, humanoid.Health = 150, 70
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=1})
			assert(humanoid.MaxHealth == 150 and humanoid.Health == 70)
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=2})
			near(humanoid.MaxHealth,150+40/49); near(humanoid.Health,70+40/49)
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=2})
			near(humanoid.Health,70+40/49)
		end)
		test("generated equipment has no colliding touching or queryable geometry", function()
			for _, item in character:GetDescendants() do
				if item:IsA("BasePart") and (item:IsDescendantOf(character.CivilizationArmor)
					or item:IsDescendantOf(ownedTools()[1])) then
					assert(not item.CanCollide and not item.CanTouch and not item.CanQuery and item.Massless)
				end
			end
		end)
		test("clear removes generated gear and restores original health without deleting avatar items", function()
			Equipment.clear(player)
			assert(#ownedTools() == 0 and character:FindFirstChild("CivilizationArmor") == nil)
			assert(unrelated.Parent == character and humanoid.MaxHealth == 150)
			assert(character:GetAttribute("EquipmentCivilization") == nil)
		end)
		return count
	end)
	player.Character = nil
	character:Destroy()
	inventory:Destroy()
	assert(ok, result)
	return result
end

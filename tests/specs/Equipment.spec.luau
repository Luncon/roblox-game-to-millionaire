return function()
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
				for level, damage in {10,14,19,25} do
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
					assert(#armor:GetChildren() >= 3 and unrelated.Parent == character)
				end
			end
		end)
		test("armor preserves base health and repeated apply cannot heal repeatedly", function()
			Equipment.clear(player)
			humanoid.MaxHealth, humanoid.Health = 150, 70
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=1})
			assert(humanoid.MaxHealth == 150 and humanoid.Health == 70)
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=2})
			assert(humanoid.MaxHealth == 165 and humanoid.Health == 85)
			Equipment.apply(player, catalog[1], {weaponLevel=1, armorLevel=2})
			assert(humanoid.Health == 85, "Duplicate refresh healed the player")
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

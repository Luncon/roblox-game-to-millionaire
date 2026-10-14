-- Server attack validation with real owners, characters, equipped Tools and raycasts.
-- Native Tool activation is covered separately by the multiplayer client suite.
return function(first, second)
	local Players = game:GetService("Players")
	assert(first ~= second and first.Parent == Players and second.Parent == Players)
	local Game = game.ServerScriptService.Game
	local Map, Registry = require(Game.BattlefieldMap), require(Game.ClaimRegistry)
	local Economy, Rig = require(Game.Economy), require(Game.WarriorRig)
	local Combat, Melee = require(Game.CombatService), require(Game.PlayerCombatService)
	local Equipment = require(Game.Equipment)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local saved = {}
	for _, player in {first, second} do
		local character = assert(player.Character)
		saved[player] = {pivot=character:GetPivot(), anchor=character.HumanoidRootPart.Anchored,
			health=character.Humanoid.Health, civilization=player:GetAttribute("CivilizationId"),
			weaponLevel=player:GetAttribute("WeaponLevel") or 1, armorLevel=player:GetAttribute("ArmorLevel") or 1}
	end
	local container = Instance.new("Folder")
	container.Name, container.Parent = "PlayerMeleeFixture", workspace
	local combat, melee
	local cases = 0
	local function test(name, callback) callback(); cases += 1; print("PASS: " .. name) end
	local ok, result = pcall(function()
		local world = Map.build(container)
		world.model:PivotTo(CFrame.new(2600,0,2600)*world.model:GetPivot())
		local registry = Registry.new(8,{sparta=true,britain=true})
		local economy = Economy.new()
		assert(registry:claim(first.UserId,"sparta").ok)
		assert(registry:claim(second.UserId,"britain").ok)
		for _, player in {first, second} do
			economy:open(player.UserId)
			player.Character.HumanoidRootPart.Anchored = true
			player.Character:PivotTo(world:getSpawn(registry:get(player.UserId).plotId))
		end
		combat = Combat.new(world,registry,economy)
		melee = Melee.new(world,registry,economy,combat)
		local function position(x,z) return world.model.Battlefield.Position+Vector3.new(x,4,z) end
		local function equip()
			Equipment.clear(first)
			assert(Equipment.apply(first,catalog[1],economy:get(first.UserId)))
			assert(first.Character:FindFirstChildOfClass("Tool"))
		end
		local function reset(x,z)
			melee:release(first.UserId)
			world.model.Troops:ClearAllChildren()
			local character = first.Character
			character.HumanoidRootPart.Anchored = true
			local origin = position(x or 0,z or 0)
			character:PivotTo(CFrame.lookAt(origin,origin+Vector3.new(0,0,-1)))
			assert(melee:trackCharacter(first,character))
		end
		local function target(x,z,owner)
			owner = owner or second
			local civ = if owner==first then catalog[1] else catalog[2]
			local claim = registry:get(owner.UserId)
			local model = Rig.create(civ,CFrame.new(position(x,z)),owner.UserId,claim.plotId)
			model.Parent = world.model.Troops
			model.HumanoidRootPart.Anchored = true
			assert(combat:register(model,owner.UserId,"warrior"))
			return model
		end
		equip()
		test("player melee requires genuinely equipped current-civilization current-tier gear",function()
			reset(); local victim = target(0,-3)
			first.Character.Humanoid:UnequipTools()
			assert(melee:attack(first).reason=="not_equipped")
			equip()
			local tool = first.Character:FindFirstChildOfClass("Tool")
			for key,value in {GeneratedBy="Untrusted",CivilizationId="britain",WeaponLevel=4} do
				melee:release(first.UserId)
				local original = tool:GetAttribute(key)
				tool:SetAttribute(key,value)
				assert(melee:attack(first).reason=="not_equipped")
				tool:SetAttribute(key,original)
			end
			assert(victim.Humanoid.Health==100 and economy:get(first.UserId).coins==0)
		end)
		test("forward player melee deals ten and cannot repeat during the swing cooldown",function()
			reset(); local victim = target(0,-3)
			local hit = melee:attack(first)
			assert(hit.ok and hit.damage==10 and victim.Humanoid.Health==90)
			assert(melee:attack(first).reason=="cooldown" and victim.Humanoid.Health==90)
		end)
		test("rear and side targets miss and misses consume the player swing cooldown",function()
			reset(); local rear = target(0,3); local side = target(3,0)
			assert(melee:attack(first).reason=="miss")
			assert(melee:attack(first).reason=="cooldown")
			assert(rear.Humanoid.Health==100 and side.Humanoid.Health==100)
		end)
		test("player melee rejects beyond-five range and intervening real geometry",function()
			reset(); local distant = target(0,-5.1)
			assert(melee:attack(first).reason=="miss" and distant.Humanoid.Health==100)
			reset(); local victim = target(0,-3)
			local wall = Instance.new("Part")
			wall.Size,wall.CFrame,wall.Anchored,wall.Parent=Vector3.new(8,12,.2),CFrame.new(position(0,-.5)),true,container
			assert(melee:attack(first).reason=="miss" and victim.Humanoid.Health==100)
			wall:Destroy()
		end)
		test("owner allies and targets outside the arena remain protected",function()
			reset(); local ally = target(0,-3,first)
			assert(melee:attack(first).reason=="miss" and ally.Humanoid.Health==100)
			reset(); local dead = target(0,-3)
			dead.Humanoid.Health=0
			assert(melee:attack(first).reason=="miss" and economy:get(first.UserId).coins==0)
			reset(0,73); local outside = target(0,76)
			first.Character:PivotTo(CFrame.lookAt(position(0,73),position(0,76)))
			assert(melee:attack(first).reason=="miss" and outside.Humanoid.Health==100)
		end)
		test("current claim and living character are required even for a genuine equipped weapon",function()
			reset(); local victim = target(0,-3)
			registry:release(first.UserId)
			assert(melee:attack(first).reason=="not_claimed" and victim.Humanoid.Health==100)
			assert(registry:claim(first.UserId,"sparta").ok)
			reset(); victim = target(0,-3)
			local humanoid = first.Character.Humanoid
			local parent = humanoid.Parent
			humanoid.Parent = nil
			local response = melee:attack(first)
			humanoid.Parent = parent
			assert(response.reason=="invalid_actor" and victim.Humanoid.Health==100)
		end)
		test("only the nearest eligible enemy is damaged by a single swing",function()
			reset(); local near = target(0,-3); local far = target(0,-4.5)
			assert(melee:attack(first).ok)
			assert(near.Humanoid.Health==90 and far.Humanoid.Health==100)
		end)
		test("character replacement invalidates the old actor and permits a new equipped character",function()
			reset(); local old = first.Character
			first:LoadCharacterAsync()
			local deadline = os.clock()+15
			repeat task.wait(.1) until (first.Character and first.Character:FindFirstChild("HumanoidRootPart")
				and first.Character:FindFirstChild("Head") and first.Character:FindFirstChildOfClass("Humanoid")
				and (first.Character:FindFirstChild("UpperTorso") or first.Character:FindFirstChild("Torso"))) or os.clock()>deadline
			assert(first.Character~=old and first.Character:FindFirstChild("HumanoidRootPart"))
			assert(not melee:trackCharacter(first,old) and combat:actor(old)==nil)
			equip(); reset(); local victim = target(0,-3)
			assert(melee:attack(first).ok and victim.Humanoid.Health==90)
		end)
		return {ok=true,cases=cases,message="Real player melee equipment, cone, distance, LOS, protection, claim, cooldown, nearest-target and reset checks passed"}
	end)
	if melee then melee:destroy() end
	if combat then combat:destroy() end
	container:Destroy()
	for _,player in {first,second} do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			if player==first then
				Equipment.clear(player)
				for _,civ in catalog do if civ.id==saved[player].civilization then Equipment.apply(player,civ,saved[player]) end end
			end
			character.HumanoidRootPart.Anchored=saved[player].anchor
			character:PivotTo(saved[player].pivot)
			if character.Humanoid.Health>0 then character.Humanoid.Health=math.min(saved[player].health,character.Humanoid.MaxHealth) end
		end
	end
	assert(ok,result)
	return result
end

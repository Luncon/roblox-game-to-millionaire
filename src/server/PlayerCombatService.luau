--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(script.Parent.CombatRules)
local Config = require(ReplicatedStorage.Shared.WarriorConfig)
local PlayerCombatService = {}

function PlayerCombatService.new(world, registry, economy, combat)
	local controller = {}
	local characters, lastSwing = {}, {}
	local alive = true
	function controller:trackCharacter(player, character)
		if not alive or player.Parent ~= Players or player.Character ~= character then return false end
		local old = characters[player.UserId]
		if old and old ~= character then combat:unregister(old) end
		characters[player.UserId] = character
		return combat:register(character,player.UserId,"player")
	end
	function controller:attack(player)
		if not alive or player.Parent ~= Players then return {ok=false,reason="invalid"} end
		local time = os.clock()
		if time < (lastSwing[player.UserId] or -math.huge)+Config.attackCooldown then return {ok=false,reason="cooldown"} end
		lastSwing[player.UserId] = time
		local character = player.Character
		local claim, state = registry:get(player.UserId), economy:get(player.UserId)
		if not character or not claim or not state then return {ok=false,reason="not_claimed"} end
		local tool = character:FindFirstChildOfClass("Tool")
		if not tool or tool:GetAttribute("GeneratedBy") ~= "CivilizationEquipment"
			or tool:GetAttribute("CivilizationId") ~= claim.civilizationId
			or tool:GetAttribute("WeaponLevel") ~= state.weaponLevel then return {ok=false,reason="not_equipped"} end
		self:trackCharacter(player,character)
		local attacker = combat:actor(character)
		if not attacker then return {ok=false,reason="invalid_actor"} end
		local selected, nearest = nil, Config.attackRange+.0001
		for _, target in combat:actors() do
			local delta = target.position-attacker.position
			local distance = delta.Magnitude
			if distance > .001 and distance <= nearest and attacker.root.CFrame.LookVector:Dot(delta.Unit) >= .25
				and Rules.canDamage(attacker,target,world.model.Battlefield) and combat:visible(attacker,target) then
				selected, nearest = target, distance
			end
		end
		if not selected then return {ok=false,reason="miss"} end
		return combat:hit(character,selected.rig)
	end
	function controller:release(ownerId)
		local character = characters[ownerId]
		if character then combat:unregister(character) end
		characters[ownerId], lastSwing[ownerId] = nil, nil
	end
	function controller:destroy()
		alive = false
		local ids = {}
		for ownerId in characters do table.insert(ids,ownerId) end
		for _, ownerId in ids do self:release(ownerId) end
		if self.connection then self.connection:Disconnect() end
		if self.remotes then self.remotes:Destroy() end
	end
	return controller
end

function PlayerCombatService.start(world, registry, economy, combat)
	local controller = PlayerCombatService.new(world,registry,economy,combat)
	local remotes = Instance.new("Folder")
	remotes.Name = "CombatRemotes"
	local attack = Instance.new("RemoteEvent")
	attack.Name, attack.Parent = "Attack", remotes
	controller.connection = attack.OnServerEvent:Connect(function(player) controller:attack(player) end)
	controller.remotes = remotes
	remotes.Parent = ReplicatedStorage
	return controller
end

return PlayerCombatService

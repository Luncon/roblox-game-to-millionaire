--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Civilizations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Civilizations"))
local ClaimRegistry = require(script.Parent.ClaimRegistry)
local BattlefieldMap = require(script.Parent.BattlefieldMap)
local Economy = require(script.Parent.Economy)
local TycoonButtons = require(script.Parent.TycoonButtons)
local Equipment = require(script.Parent.Equipment)
local WarriorService = require(script.Parent.WarriorService)
local CombatService = require(script.Parent.CombatService)
local PlayerCombatService = require(script.Parent.PlayerCombatService)

local CivilizationService = {}

function CivilizationService.start()
	local world = BattlefieldMap.build(workspace)
	local supported = {}
	local catalog = {}
	for _, civilization in Civilizations do
		supported[civilization.id] = true
		catalog[civilization.id] = civilization
	end
	local registry = ClaimRegistry.new(world.plotCount, supported)
	local economy = Economy.new()
	local revision = 0
	local lastRequest: { [number]: number } = {}
	local army, buttons

	local remotes = Instance.new("Folder")
	remotes.Name = "CivilizationRemotes"
	local request = Instance.new("RemoteFunction")
	request.Name = "Request"
	request.Parent = remotes
	local changed = Instance.new("RemoteEvent")
	changed.Name = "Changed"
	changed.Parent = remotes
	local economyRemotes = Instance.new("Folder")
	economyRemotes.Name = "EconomyRemotes"
	local economyState = Instance.new("RemoteEvent")
	economyState.Name = "State"
	economyState.Parent = economyRemotes

	local function publishEconomy(player: Player, result, action: string)
		local state = result.state
		if state then
			player:SetAttribute("Coins", state.coins)
			player:SetAttribute("SettlementLevel", state.level)
			player:SetAttribute("WeaponLevel", state.weaponLevel)
			player:SetAttribute("ArmorLevel", state.armorLevel)
			player:SetAttribute("BarracksUpgradeLevel",state.barracksLevel)
			player:SetAttribute("EconomyRevision", state.revision)
			local stats = player:FindFirstChild("leaderstats")
			if not stats then
				stats = Instance.new("Folder")
				stats.Name = "leaderstats"
				stats.Parent = player
			end
			local coins = stats:FindFirstChild("Coins")
			if not coins then
				coins = Instance.new("IntValue")
				coins.Name = "Coins"
				coins.Parent = stats
			end
			if coins:IsA("IntValue") then coins.Value = state.coins end
		end
		if result.ok and (action == "claim" or action == "upgrade" or action == "weapon" or action == "armor" or action == "barracks") then
			if army then army:refresh(player) end
		end
		if result.ok and action == "kill" and buttons then
			local claim = registry:get(player.UserId)
			if claim then buttons:refresh(player,claim) end
		end
		economyState:FireClient(player, {ok=result.ok, reason=result.reason, state=state, action=action, amount=result.amount})
	end

	local combat = CombatService.new(world,registry,economy,publishEconomy)
	local playerCombat = PlayerCombatService.start(world,registry,economy,combat)
	army = WarriorService.start(world,registry,economy,catalog,combat)
	buttons = TycoonButtons.new(world, registry, economy, catalog, publishEconomy)

	local function snapshot()
		local availability = registry:snapshot()
		for _, entry in availability do
			if entry.ownerId then
				local owner = Players:GetPlayerByUserId(entry.ownerId)
				entry.ownerName = if owner then owner.DisplayName else "Another commander"
			end
		end
		return { revision = revision, availability = availability }
	end

	local function placeCharacter(player: Player, character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and player.Parent == Players and player.Character == character then
			local claim = registry:get(player.UserId)
			character:PivotTo(world:getSpawn(if claim then claim.plotId else nil))
			local state = economy:get(player.UserId)
			if claim and state then
				local humanoid = character:WaitForChild("Humanoid", 10)
				character:WaitForChild("Head", 10)
				local torsoName = if humanoid and humanoid:IsA("Humanoid") and humanoid.RigType == Enum.HumanoidRigType.R15 then "UpperTorso" else "Torso"
				character:WaitForChild(torsoName, 10)
				local currentClaim = registry:get(player.UserId)
				local currentState = economy:get(player.UserId)
				if player.Parent == Players and player.Character == character and currentClaim and currentState then
					Equipment.apply(player, catalog[currentClaim.civilizationId], currentState)
					playerCombat:trackCharacter(player,character)
				end
			end
		end
	end

	local function addPlayer(player: Player)
		army:refresh(player)
		player.RespawnLocation = world.entry
		player.CharacterAdded:Connect(function(character)
			task.defer(placeCharacter, player, character)
		end)
		if player.Character then
			task.defer(placeCharacter, player, player.Character)
		end
	end

	request.OnServerInvoke = function(player: Player, action: unknown, civilizationId: unknown)
		if player.Parent ~= Players then
			return { ok = false, reason = "invalid" }
		end
		local now = os.clock()
		local previousRequest = lastRequest[player.UserId]
		if previousRequest and now - previousRequest < .3 then
			return { ok = false, reason = "rate_limited", state = snapshot() }
		end
		lastRequest[player.UserId] = now
		if action == "snapshot" then
			return { ok = true, state = snapshot() }
		end
		if action ~= "select" then
			return { ok = false, reason = "invalid", state = snapshot() }
		end
		local existing = registry:get(player.UserId)
		local result = registry:claim(player.UserId, civilizationId)
		if result.ok and result.claim and not existing then
			local claim = result.claim
			world:setOwner(claim.plotId, catalog[claim.civilizationId], player.UserId, player.DisplayName)
			publishEconomy(player, {ok=true, state=economy:open(player.UserId)}, "claim")
			buttons:refresh(player, claim)
			player:SetAttribute("CivilizationId", claim.civilizationId)
			player:SetAttribute("PlotId", claim.plotId)
			revision += 1
			changed:FireAllClients(snapshot())
			if player.Character then
				task.defer(placeCharacter, player, player.Character)
			end
			print(string.format("%s claimed %s on plot %d", player.Name, claim.civilizationId, claim.plotId))
		end
		return { ok = result.ok, reason = result.reason, claim = result.claim, state = snapshot() }
	end

	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player)
		playerCombat:release(player.UserId)
		army:release(player.UserId)
		buttons:release(player.UserId)
		local claim = registry:release(player.UserId)
		lastRequest[player.UserId] = nil
		economy:close(player.UserId)
		if claim then
			world:setOwner(claim.plotId, nil, nil, nil)
			revision += 1
			changed:FireAllClients(snapshot())
		end
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
	-- Publish remotes only after handlers and the map are ready.
	remotes.Parent = ReplicatedStorage
	economyRemotes.Parent = ReplicatedStorage
	print(string.format("Civilization selection ready: 8 plots, %d civilizations, tycoon upgrades and melee/ranged armies", #Civilizations))
end

return CivilizationService

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Civilizations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Civilizations"))
local ClaimRegistry = require(script.Parent.ClaimRegistry)
local BattlefieldMap = require(script.Parent.BattlefieldMap)

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
	local revision = 0
	local lastRequest: { [number]: number } = {}

	local remotes = Instance.new("Folder")
	remotes.Name = "CivilizationRemotes"
	local request = Instance.new("RemoteFunction")
	request.Name = "Request"
	request.Parent = remotes
	local changed = Instance.new("RemoteEvent")
	changed.Name = "Changed"
	changed.Parent = remotes

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
		end
	end

	local function addPlayer(player: Player)
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
		local claim = registry:release(player.UserId)
		lastRequest[player.UserId] = nil
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
	print("Civilization selection ready: 8 plots, Sparta and Britain")
end

return CivilizationService

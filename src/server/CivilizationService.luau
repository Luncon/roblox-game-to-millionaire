--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Civilizations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Civilizations"))
local ClaimRegistry = require(script.Parent.ClaimRegistry)
local BattlefieldMap = require(script.Parent.BattlefieldMap)
local Economy = require(script.Parent.Economy)
local Equipment = require(script.Parent.Equipment)
local TycoonButtons = require(script.Parent.TycoonButtons)
local WarriorService = require(script.Parent.WarriorService)
local CombatService = require(script.Parent.CombatService)
local PlayerCombatService = require(script.Parent.PlayerCombatService)
local ProfileService = require(script.Parent.ProfileService)
local CivilizationService = {}

function CivilizationService.start(options: any?)
	options = options or {}
	local world = BattlefieldMap.build(workspace)
	local supported, catalog = {}, {}
	for _, civilization in Civilizations do
		supported[civilization.id], catalog[civilization.id] = true, civilization
	end
	local registry = ClaimRegistry.new(world.plotCount,supported)
	local revision = 0
	local lastRequest, lastLoad, activePlayers, loading, generations = {}, {}, {}, {}, {}
	local closing = false
	local army, buttons, profiles, snapshot
	local remotes = Instance.new("Folder")
	remotes.Name = "CivilizationRemotes"
	local request = Instance.new("RemoteFunction")
	request.Name, request.Parent = "Request", remotes
	local changed = Instance.new("RemoteEvent")
	changed.Name, changed.Parent = "Changed", remotes
	local economyRemotes = Instance.new("Folder")
	economyRemotes.Name = "EconomyRemotes"
	local economyState = Instance.new("RemoteEvent")
	economyState.Name, economyState.Parent = "State", economyRemotes
	local scope = if RunService:IsStudio() then "StudioDevelopment" else "Live"
	local store = options.profileStore or game:GetService("DataStoreService"):GetDataStore("CivilizationProfilesV1",scope)
	local profileOptions = table.clone(options.profileOptions or {})
	profileOptions.allowTestUserIds = RunService:IsStudio()
	profileOptions.onStatus = function(userId,status)
		local player = activePlayers[userId]
		if not player or player.Parent ~= Players then return end
		-- Deferred notifications can belong to an older load/save; read the current entry.
		status = profiles:status(userId)
		local previous = player:GetAttribute("ProgressStatus")
		player:SetAttribute("ProgressStatus",status.status)
		player:SetAttribute("ProgressError",status.reason)
		player:SetAttribute("ProgressSavedAt",status.savedAt)
		if snapshot and remotes.Parent and previous ~= status.status then
			changed:FireClient(player,snapshot(player))
		end
	end
	profiles = ProfileService.new(store,profileOptions)
	local economy = Economy.new(nil,function(userId)
		return not closing and activePlayers[userId] ~= nil and profiles:isWritable(userId)
	end)

	snapshot = function(player: Player?)
		local availability = registry:snapshot()
		for _, entry in availability do
			if entry.ownerId then
				local owner = Players:GetPlayerByUserId(entry.ownerId)
				entry.ownerName = if owner then owner.DisplayName else "Another commander"
			end
		end
		local state = {revision=revision,availability=availability}
		if player then
			local status = profiles:status(player.UserId)
			state.profile = {status=status.status,reason=status.reason,savedAt=status.savedAt,
				civilizations=profiles:getAll(player.UserId) or {}}
		end
		return state
	end
	local function broadcast()
		revision += 1
		changed:FireAllClients(snapshot()) -- Saved previews are sent only to their owner.
	end
	local function capture(player: Player)
		local claim, state = registry:get(player.UserId), economy:get(player.UserId)
		if claim and state then return profiles:set(player.UserId,claim.civilizationId,state) end
		return true
	end
	local function publishEconomy(player: Player,result,action: string)
		local state = result.state
		if result.ok and state then
			local claim = registry:get(player.UserId)
			if claim and not profiles:set(player.UserId,claim.civilizationId,state) then
				result.ok, result.reason = false, "profile_unavailable"
			end
		end
		if state then
			for attribute,field in {Coins="coins",SettlementLevel="level",WeaponLevel="weaponLevel",
				ArmorLevel="armorLevel",BarracksUpgradeLevel="barracksLevel",EconomyRevision="revision"} do
				player:SetAttribute(attribute,state[field])
			end
			local stats = player:FindFirstChild("leaderstats")
			if not stats then stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player end
			local coins = stats:FindFirstChild("Coins")
			if not coins then coins=Instance.new("IntValue");coins.Name="Coins";coins.Parent=stats end
			if coins:IsA("IntValue") then coins.Value=state.coins end
		end
		if result.ok and (action=="claim" or action=="switch" or action=="upgrade" or action=="weapon" or action=="armor" or action=="barracks") then
			if army then army:refresh(player) end
		end
		if result.ok and action=="kill" and buttons then
			local claim=registry:get(player.UserId)
			if claim then buttons:refresh(player,claim) end
		end
		if player.Parent==Players then
			economyState:FireClient(player,{ok=result.ok,reason=result.reason,state=state,action=action,amount=result.amount})
		end
	end
	local combat=CombatService.new(world,registry,economy,publishEconomy)
	local playerCombat=PlayerCombatService.start(world,registry,economy,combat)
	army=WarriorService.start(world,registry,economy,catalog,combat)
	buttons=TycoonButtons.new(world,registry,economy,catalog,publishEconomy)

	local function placeCharacter(player: Player,character: Model)
		local generation=generations[player.UserId] or 0
		local root=character:WaitForChild("HumanoidRootPart",10)
		if not root or activePlayers[player.UserId]~=player or player.Character~=character
			or generation~=(generations[player.UserId] or 0) then return end
		local claim=registry:get(player.UserId)
		character:PivotTo(world:getSpawn(if claim then claim.plotId else nil))
		if not claim then return end
		local humanoid=character:WaitForChild("Humanoid",10)
		character:WaitForChild("Head",10)
		local torso=if humanoid and humanoid:IsA("Humanoid") and humanoid.RigType==Enum.HumanoidRigType.R15 then "UpperTorso" else "Torso"
		character:WaitForChild(torso,10)
		local current=registry:get(player.UserId)
		local state=economy:get(player.UserId)
		if activePlayers[player.UserId]==player and player.Character==character and current and state
			and generation==(generations[player.UserId] or 0) then
			Equipment.apply(player,catalog[current.civilizationId],state)
			playerCombat:trackCharacter(player,character)
		end
	end
	local function loadPlayer(player: Player)
		local userId=player.UserId
		if closing or loading[userId] or activePlayers[userId]~=player or registry:get(userId) then return false end
		local now=os.clock()
		if lastLoad[userId] and now-lastLoad[userId]<10 then return false,"load_wait" end
		lastLoad[userId]=now
		loading[userId]=true
		task.spawn(function()
			if activePlayers[userId]~=player or closing then loading[userId]=nil;return end
			profiles:load(userId)
			loading[userId]=nil
			if activePlayers[userId]~=player or closing then
				if not activePlayers[userId] or activePlayers[userId]==player then profiles:release(userId) end
				return
			end
			changed:FireClient(player,snapshot(player))
		end)
		return true
	end
	local function addPlayer(player: Player)
		if closing then return end
		activePlayers[player.UserId]=player
		player:SetAttribute("ProgressMode",if options.profileStore then "test" elseif RunService:IsStudio() then "studio" else "live")
		player:SetAttribute("ProgressStatus","loading")
		player.RespawnLocation=world.entry
		army:refresh(player)
		player.CharacterAdded:Connect(function(character) task.defer(placeCharacter,player,character) end)
		if player.Character then task.defer(placeCharacter,player,player.Character) end
		loadPlayer(player)
	end
	local function select(player: Player,civilizationId: unknown,switching: boolean?)
		local userId=player.UserId
		if closing or activePlayers[userId]~=player or not profiles:isWritable(userId) then
			return {ok=false,reason="profile_unavailable",state=snapshot(player)}
		end
		if type(civilizationId)~="string" or not supported[civilizationId] then
			return {ok=false,reason="invalid",state=snapshot(player)}
		end
		local previous=registry:get(userId)
		if previous and previous.civilizationId==civilizationId then return {ok=true,claim=previous,state=snapshot(player)} end
		if previous and not switching then return {ok=false,reason="already_claimed",state=snapshot(player)} end
		local state=profiles:get(userId,civilizationId)
		if not state then return {ok=false,reason="profile_unavailable",state=snapshot(player)} end
		local available=registry:snapshot()[civilizationId]
		if available.ownerId and available.ownerId~=userId then
			return {ok=false,reason="unavailable",state=snapshot(player)}
		end
		if previous and not capture(player) then return {ok=false,reason="profile_unavailable",state=snapshot(player)} end
		local result=if switching then registry:switch(userId,civilizationId) else registry:claim(userId,civilizationId)
		if not result.ok or not result.claim then return {ok=result.ok,reason=result.reason,state=snapshot(player)} end
		local claim=result.claim
		generations[userId]=(generations[userId] or 0)+1
		if previous then
			playerCombat:release(userId)
			army:release(userId)
			buttons:release(userId)
			Equipment.clear(player)
		end
		local restored=if previous then economy:replace(userId,state) else economy:open(userId,state)
		assert(restored,"Validated profile failed to restore")
		player:SetAttribute("CivilizationId",claim.civilizationId)
		player:SetAttribute("PlotId",claim.plotId)
		world:setOwner(claim.plotId,catalog[claim.civilizationId],userId,player.DisplayName,restored.level)
		publishEconomy(player,{ok=true,state=restored},if previous then "switch" else "claim")
		buttons:refresh(player,claim)
		broadcast()
		if player.Character then task.defer(placeCharacter,player,player.Character) end
		return {ok=true,claim=claim,state=snapshot(player)}
	end
	request.OnServerInvoke=function(player: Player,action: unknown,civilizationId: unknown)
		if activePlayers[player.UserId]~=player then return {ok=false,reason="invalid"} end
		local now=os.clock()
		if lastRequest[player.UserId] and now-lastRequest[player.UserId]<.3 then
			return {ok=false,reason="rate_limited",state=snapshot(player)}
		end
		lastRequest[player.UserId]=now
		if action=="snapshot" then return {ok=true,state=snapshot(player)} end
		if action=="retry" then
			local accepted,reason=loadPlayer(player)
			return {ok=accepted,reason=reason,state=snapshot(player)}
		end
		if action=="select" or action=="switch" then return select(player,civilizationId,action=="switch") end
		return {ok=false,reason="invalid",state=snapshot(player)}
	end
	local function removePlayer(player: Player)
		local userId=player.UserId
		if activePlayers[userId]~=player then return end
		capture(player)
		activePlayers[userId]=nil
		generations[userId]=(generations[userId] or 0)+1
		playerCombat:release(userId);army:release(userId);buttons:release(userId)
		local claim=registry:release(userId)
		economy:close(userId)
		lastRequest[userId]=nil
		lastLoad[userId]=nil
		if claim then world:setOwner(claim.plotId,nil,nil,nil);broadcast() end
		task.spawn(function()
			local result=profiles:release(userId)
			if not result.ok then warn("Final progress save failed for user "..userId..": "..tostring(result.reason)) end
		end)
	end
	local shutdownResult=nil
	local shuttingDown=false
	local function shutdown()
		if shutdownResult then return shutdownResult end
		if shuttingDown then repeat task.wait() until shutdownResult;return shutdownResult end
		shuttingDown=true
		closing=true
		for _,player in activePlayers do capture(player) end
		shutdownResult=profiles:shutdown(25)
		return shutdownResult
	end
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(removePlayer)
	game:BindToClose(shutdown)
	remotes.Parent=ReplicatedStorage
	economyRemotes.Parent=ReplicatedStorage
	for _,player in Players:GetPlayers() do addPlayer(player) end
	if options.autosave~=false then profiles:startAutosave() end
	print(string.format("Civilization selection ready: 8 plots, %d civilizations, independent saved profiles (%s)",#Civilizations,scope))
	return {profiles=profiles,economy=economy,registry=registry,army=army,buttons=buttons,world=world,
		combat=combat,playerCombat=playerCombat,shutdown=shutdown,select=select,snapshot=snapshot}
end

return CivilizationService

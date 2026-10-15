--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Tracks = require(Shared.UpgradeTracks)
local Catalog = require(Shared.PadCatalog)
local Equipment = require(script.Parent.Equipment)
local TycoonButtons = {}

function TycoonButtons.new(world, registry, economy, civilizations, publishEconomy)
	local controller = {}
	local pads, contacts, traffic = {}, {}, {}
	local render, activate

	local function disconnect(bound)
		for _, connection in bound.connections do connection:Disconnect() end
	end
	local function bind(plotId, definition, pad)
		local detector = pad:FindFirstChildOfClass("ClickDetector")
		local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
		local bound = {pad=pad,definition=definition,detector=detector,prompt=prompt,
			label=pad:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel"),connections={}}
		local function connect(signal, callback) table.insert(bound.connections,signal:Connect(callback)) end
		connect(detector.MouseClick,function(player) activate(player,plotId,definition.action,20) end)
		connect(prompt.Triggered,function(player) activate(player,plotId,definition.action,20) end)
		prompt.MaxActivationDistance, prompt.HoldDuration = 10, 0
		prompt.ObjectText = if definition.action == "earn" then "Coin Button" else string.upper(definition.track) .. " Upgrade"
		if definition.action ~= "earn" then
			contacts[plotId][definition.action] = contacts[plotId][definition.action] or {}
			local touching = contacts[plotId][definition.action]
			local function overlaps(character)
				if pad.Parent == nil then return false end
				local overlap = OverlapParams.new()
				overlap.FilterType = Enum.RaycastFilterType.Include
				overlap.FilterDescendantsInstances = {character}
				overlap.MaxParts = 1
				return #workspace:GetPartBoundsInBox(pad.CFrame,pad.Size+Vector3.new(0,1,0),overlap)>0
			end
			connect(pad.Touched,function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = if character then Players:GetPlayerFromCharacter(character) else nil
				if not player or player.Character ~= character or not overlaps(character) then return end
				local previous = touching[player.UserId]
				if previous and previous.character == character and previous.pad == pad then return end
				local entry = {character=character,pad=pad}
				touching[player.UserId] = entry
				task.spawn(function()
					while touching[player.UserId] == entry do
						task.wait(.1)
						if player.Parent ~= Players or player.Character ~= character or not overlaps(character) then break end
					end
					if touching[player.UserId] == entry then touching[player.UserId] = nil end
				end)
				activate(player,plotId,definition.action,8)
			end)
		end
		return bound
	end
	local function sync(plotId,state)
		world:syncControls(plotId,state)
		local controls = world.model.Plots["Plot"..plotId].Controls
		local bound = pads[plotId]
		for action, entry in bound do
			if entry.pad.Parent ~= controls then disconnect(entry); bound[action]=nil end
		end
		for _, definition in Catalog.definitions do
			local pad = controls:FindFirstChild(definition.name)
			if pad and not bound[definition.action] then bound[definition.action]=bind(plotId,definition,pad) end
		end
	end
	render = function(plotId,state)
		sync(plotId,state)
		for action,bound in pads[plotId] do
			local definition = bound.definition
			local enabled = state ~= nil
			if action == "earn" then
				bound.pad.Color = Color3.fromRGB(240,191,54)
				bound.label.Text = if enabled then "+1 COIN\nClick or interact" else "COINS\nClaim this plot first"
				bound.prompt.ActionText = "+1 Coin"
			else
				local track = Tracks[definition.track]
				local current = if state then state[Catalog.fields[definition.track]] else 1
				local expected = if definition.repeatFrom then math.max(definition.repeatFrom,current) elseif definition.tier then definition.tier-1 else current
				local tier = track[expected]
				local cost = tier.nextCost
				local ready = enabled and current == expected
				local required = tier.requiredSettlement or 1
				local unlocked = state ~= nil and state.level >= required
				local title = string.upper(definition.track)
				if not enabled then bound.label.Text = title.."\nClaim this plot first"
				elseif not ready then bound.label.Text = string.format("%s %s\nBUY TIER %d FIRST",title,track[definition.tier].name,expected)
				elseif not cost then bound.label.Text = title.."\nMAX LEVEL"
				elseif not unlocked then bound.label.Text = string.format("%s · TIER %d\nSETTLEMENT %d REQUIRED",title,expected+1,required)
				else
					local nextTier=track[expected+1]
					local effect = if definition.track == "barracks" then string.format(" · %gs",nextTier.respawnDelay)
						elseif definition.track == "weapon" then string.format(" · %.2f DMG",nextTier.damage)
						elseif definition.track == "armor" then string.format(" · %.1f HP",nextTier.health) else ""
					bound.label.Text = string.format("%s · %s%s\n%d COINS",title,track[expected+1].name,effect,cost)
				end
				bound.pad.Color = if ready and unlocked and cost and state.coins >= cost then Color3.fromRGB(72,187,90)
					elseif not ready or not unlocked or not cost then Color3.fromRGB(105,111,120) else Color3.fromRGB(207,67,63)
				bound.prompt.ActionText = if not ready then "Previous tier required" elseif cost and not unlocked then "Upgrade settlement first" elseif cost then string.format("Upgrade · %d Coins",cost) else "Max Level"
				enabled = ready and unlocked and cost ~= nil
			end
			bound.detector.MaxActivationDistance = if enabled then 20 else 0
			bound.prompt.Enabled = enabled
		end
	end
	activate = function(player,plotId,action,maxDistance)
		if player.Parent ~= Players then return {ok=false,reason="invalid"} end
		local now = os.clock()
		local budget = traffic[player.UserId] or {tokens=30,time=now}
		traffic[player.UserId] = budget
		budget.tokens = math.min(30,budget.tokens+math.max(0,now-budget.time)*30)
		budget.time = now
		if budget.tokens < 1 then return {ok=false,reason="rate_limited"} end
		budget.tokens -= 1
		local claim = registry:get(player.UserId)
		if not claim or claim.plotId ~= plotId then return {ok=false,reason="not_owner"} end
		local bound = pads[plotId] and pads[plotId][action]
		if not bound or bound.pad.Parent == nil then return {ok=false,reason="invalid"} end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0
			or not ((root.Position-bound.pad.Position).Magnitude <= maxDistance) then return {ok=false,reason="too_far"} end
		local definition = bound.definition
		local state = economy:get(player.UserId)
		if not state then return {ok=false,reason="not_claimed"} end
		local current = if action ~= "earn" then state[Catalog.fields[definition.track]] else nil
		local expected = if definition.repeatFrom then math.max(definition.repeatFrom,current) elseif definition.tier then definition.tier-1 else current
		local result
		if action ~= "earn" and current ~= expected then
			result = {ok=false,reason="prerequisite",state=state}
		else
			result = if action == "earn" then economy:earn(player.UserId) else economy:upgrade(player.UserId,expected,definition.track)
		end
		if result.ok and action == "upgrade" then
			world:setOwner(plotId,civilizations[claim.civilizationId],player.UserId,player.DisplayName,result.state.level)
		end
		if result.ok and (definition.track == "weapon" or definition.track == "armor") then
			Equipment.apply(player,civilizations[claim.civilizationId],result.state)
		end
		publishEconomy(player,result,if action == "upgrade" then "upgrade" else definition.track)
		render(plotId,result.state)
		return result
	end
	function controller:activate(player,plotId,action)
		if not pads[plotId] then return {ok=false,reason="invalid"} end
		return activate(player,plotId,action,20)
	end
	function controller:refresh(player,claim)
		local state = economy:get(player.UserId)
		render(claim.plotId,state)
		if state then Equipment.apply(player,civilizations[claim.civilizationId],state) end
	end
	function controller:release(playerId)
		local claim = registry:get(playerId)
		if claim then render(claim.plotId,nil) end
		for _, actions in contacts do for _, touching in actions do touching[playerId]=nil end end
		traffic[playerId] = nil
	end
	for plotId=1,world.plotCount do
		pads[plotId],contacts[plotId] = {},{}
		render(plotId,nil)
	end
	return controller
end

return TycoonButtons

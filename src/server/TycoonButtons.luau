--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Tracks = require(Shared.UpgradeTracks)
local Catalog = require(Shared.PadCatalog)
local Development = require(Shared.SettlementDevelopment)
local Skills = require(Shared.WeaponSkillConfig)
local Variants = require(Shared.WarriorConfig).variants
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
		prompt.ObjectText = if definition.action == "earn" then "Coin Button"
			elseif definition.action=="collectFarm" then "Farm Collection" else string.upper(definition.track) .. " Upgrade"
		if definition.action ~= "earn" then
			contacts[plotId][definition.track] = contacts[plotId][definition.track] or {}
			local touching = contacts[plotId][definition.track]
			local contactFrame,contactSize=pad.CFrame,pad.Size+Vector3.new(0,1,0)
			local function overlaps(character)
				local overlap = OverlapParams.new()
				overlap.FilterType = Enum.RaycastFilterType.Include
				overlap.FilterDescendantsInstances = {character}
				overlap.MaxParts = 1
				-- The logical purchase zone survives replacement of its tier pad.
				return #workspace:GetPartBoundsInBox(contactFrame,contactSize,overlap)>0
			end
			connect(pad.Touched,function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = if character then Players:GetPlayerFromCharacter(character) else nil
				if not player or player.Character ~= character or not overlaps(character) then return end
				local previous = touching[player.UserId]
				if previous and previous.character == character then return end
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
			elseif action=="collectFarm" then
				local reserve=if state then state.farmCoins or 0 else 0
				bound.pad.Color=if reserve>0 then Color3.fromRGB(72,187,90) else Color3.fromRGB(185,150,70)
				bound.label.Text=string.format("COLLECT FARM\n%d / %d COINS",reserve,Development.storageCapacity(state or {}))
				bound.prompt.ActionText="Collect "..reserve.." coins"
			else
				local offer=if state then Development.offer(state,definition.track,world.model.Plots["Plot"..plotId]:GetAttribute("CivilizationId")) else nil
				local cost=if offer then offer.cost else nil
				local available=offer and offer.available
				local building=Development.buildings[definition.track]
				local title=string.upper(if building then building.title else definition.track)
				if definition.track=="skill" and available then
					local civId=world.model.Plots["Plot"..plotId]:GetAttribute("CivilizationId")
					local variant=Variants[civId]
					local family=if variant then Skills.family(variant.weaponKind) else nil
					local name=if family then Skills.families[family].name else "Weapon Skill"
					bound.label.Text=string.format("%s · %s\n%d COINS · %s",string.upper(name),Skills.tiers[offer.nextLevel].name,
						cost,if family then Skills.description(family,offer.nextLevel) else "All eligible troops")
				elseif not state then bound.label.Text=title.."\nClaim this plot first"
				elseif available then
					local track=Tracks[definition.track]
					local nextTier=if track then track[offer.nextLevel] else nil
					local effect = if definition.track == "barracks" then string.format(" · %gs",nextTier.respawnDelay)
						elseif definition.track == "weapon" then string.format(" · %.2f DMG",nextTier.damage)
						elseif definition.track == "armor" then string.format(" · %.1f HP",nextTier.health) else ""
					bound.label.Text=string.format("%s · %s%s\n%d COINS",title,
						if nextTier then nextTier.name elseif offer.nextLevel==2 then "II" else "I",effect,cost)
				else bound.label.Text=title.."\nUnavailable" end
				bound.pad.Color=if available and state.coins>=cost then Color3.fromRGB(72,187,90)
					elseif available then Color3.fromRGB(207,67,63) else Color3.fromRGB(105,111,120)
				bound.prompt.ActionText=if available then string.format("Buy · %d Coins",cost) else "Claim first"
				enabled=available==true
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
		local result
		if action=="earn" then result=economy:earn(player.UserId)
		elseif action=="collectFarm" then result=economy:collectFarm(player.UserId)
		else
			local offer=Development.offer(state,definition.track,claim.civilizationId)
			local expected=if definition.tier and not definition.repeatFrom then definition.tier-1 else offer.current
			if expected~=offer.current then result={ok=false,reason="prerequisite",state=state}
			else result=economy:upgrade(player.UserId,expected,definition.track) end
		end
		if result.ok and action == "upgrade" then
			world:setOwner(plotId,civilizations[claim.civilizationId],player.UserId,player.DisplayName,result.state.level)
		end
		if result.ok and (definition.track == "weapon" or definition.track == "armor" or definition.track=="shield") then
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
	function controller:refreshState(player,claim)
		render(claim.plotId,economy:get(player.UserId))
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

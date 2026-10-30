--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DefaultPlayers = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage.MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local MilitaryResearch = require(Shared.MilitaryResearch)
local State = require(script.Parent.State)
local Sessions = require(script.Parent.Sessions)
local Requests = require(script.Parent.Requests)
local Economy = require(script.Parent.Economy)
local Workforce = require(script.Parent.Workforce)
local Actions = require(script.Parent.Actions)
local ActiveTime = require(script.Parent.ActiveTime)
local DefaultTransport = require(script.Parent.Transport)
local DefaultWorld = require(script.Parent.World)
local DefaultCombatController = require(script.Parent.CombatController)
local Runtime = {}

function Runtime.start(options)
	local store = options.store
	local fake = type(store) == "table" and store.isFakeProfileStore == true
	local persistent = type(store) == "table" and store.isPersistentProfileStore == true
	assert(
		fake ~= persistent and type(store.UpdateAsync) == "function",
		"A trusted miniature profile adapter is required"
	)
	assert(not fake or RunService:IsStudio(), "Fake profile adapters are Studio-only")
	local injected = options.testDependencies
	assert(injected == nil or fake and RunService:IsStudio(), "Lifecycle doubles require Studio and fake storage")
	local Players = if injected then injected.players else DefaultPlayers
	local World = if injected then injected.world else DefaultWorld
	local CombatController = if injected then injected.combat else DefaultCombatController
	local Transport = if injected then injected.transport else DefaultTransport
	local heartbeat = if injected then injected.heartbeat else RunService.Heartbeat
	local bindToClose = if injected
		then injected.bindToClose
		else function(callback)
			game:BindToClose(callback)
		end
	local wait = if injected then injected.wait else task.wait
	local delay = if injected then injected.delay else task.delay
	local storageLabel = if fake then "InjectedFakeProfileStore" else store.storageLabel
	assert(type(storageLabel) == "string" and #storageLabel > 0, "Persistent storage must declare its environment")
	local clock = options.clock or os.time
	local monotonic = options.monotonic or os.clock
	local sessions = Sessions.new({
		store = options.store,
		clock = clock,
		token = function()
			return HttpService:GenerateGUID(false)
		end,
	})
	local world = World.create()
	World.installPreviews()
	local combat = CombatController.start(world)
	local contexts = {}
	local shuttingDown, shutdownDeadline = false, nil
	local releaseFailures = {}
	local loadSeconds, releaseSeconds = 75, 25
	local transport, gateway
	local actionNames = {
		"select",
		"travel",
		"collect",
		"sellAll",
		"buy",
		"place",
		"reclaim",
		"targetOutpost",
		"militaryResearch",
		"configureArmy",
	}

	local function living(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return humanoid and root and humanoid.Health > 0 and character.Parent ~= nil, root
	end

	local function active(context): boolean
		local current = sessions:snapshot(context.player.UserId)
		return not context.closing
			and current.writable
			and current.claim ~= nil
			and World.supports(current.claim.civilizationId)
			and living(context.player) == true
	end

	local function snapshot(player)
		local view = sessions:snapshot(player.UserId)
		local context = contexts[player.UserId]
		view.storageLabel = storageLabel
		if context then
			if context.closing or shuttingDown then
				view.profileStatus, view.profileReason = "closing", context.profileReason
			elseif view.loaded then
				if not view.writable then
					view.profileStatus, view.profileReason = "read_only", view.profileReason or "authority_lost"
				elseif context.saveReason then
					view.profileStatus, view.profileReason = "save_retry", context.saveReason
				else
					view.profileStatus, view.profileReason = "ready", nil
				end
			else
				view.profileStatus, view.profileReason = context.profileStatus, context.profileReason
			end
		else
			view.profileStatus = if shuttingDown then "closing" else "loading"
		end
		view.serverTime = clock()
		view.productionSpeed = Config.productionSpeed
		view.researchEnabled = Config.researchEnabled
		local completed = if view.state then view.state.militaryResearch.completed else {}
		view.militaryResearchEnabled = true
		view.armySlots = MilitaryResearch.groupSlots(completed)
		view.armyControlsUnlocked = view.armySlots > 1
		view.troopCapacity = MilitaryResearch.capacity(completed)
		view.troopCapacityUsed = if view.state then State.troopCapacityUsed(view.state) else 0
		view.troops = if view.state then State.troops(view.state) else { melee = 0, ranged = 0, medic = 0, mounted = 0 }
		view.outposts, view.army, view.armyGroups = combat:snapshot(player.UserId)
		view.buyShopPosition, view.sellShopPosition = world.buyShopPosition, world.sellShopPosition
		view.artReady = view.claim ~= nil and World.supports(view.claim.civilizationId)
		view.artKits = World.availableKits()
		view.capabilities = { select = true }
		for _, action in actionNames do
			if action ~= "select" then
				view.capabilities[action] = view.artReady and view.writable
			end
		end
		view.production = {}
		if view.claim then
			view.plotFrame = world.plots[view.claim.plotId].frame
		end
		if view.state and context then
			local assignments = Economy.workers(view.state)
			for _, building in view.state.buildings do
				local definition = Catalog.buildings[building.kind]
				if definition.output then
					local workers = assignments[building.id] or 0
					local reason = if not active(context)
						then "inactive"
						else Economy.blocked(view.state, building, workers)
					local interval = Economy.interval(view.state, definition)
					local elapsed = math.max(0, monotonic() - (context.clocks[building.id] or monotonic()))
					view.production[building.id] = {
						workers = workers,
						reason = reason,
						seconds = if reason then interval else math.max(0, interval - elapsed),
					}
				end
			end
		end
		return view
	end

	local function spatial(userId, action, args)
		local context = contexts[userId]
		if not context or context.closing then
			return { alive = false, inRange = false }
		end
		local alive, root = living(context.player)
		if not alive then
			return { alive = false, inRange = false }
		end
		if action == "select" then
			return { alive = true, inRange = true }
		end
		local view = sessions:snapshot(userId)
		if not view.claim or not view.state or not World.supports(view.claim.civilizationId) then
			return { alive = true, inRange = false }
		end
		if action == "travel" or action == "militaryResearch" or action == "configureArmy" then
			return { alive = true, inRange = true }
		end
		local plot = world.plots[view.claim.plotId]
		local range = Config.interactionRange
		local target
		if action == "sellAll" then
			target = world.sellShopPosition
		elseif action == "buy" then
			target = world.buyShopPosition
		elseif action == "place" then
			target, range = plot.frame.Position, Config.placementRange
		elseif action == "targetOutpost" then
			target = combat:position(args.outpostId)
		else
			local buildingId = if action == "collect" or action == "reclaim" then args.buildingId else "b1"
			local building = Economy.building(view.state, buildingId)
			if building then
				target = plot.frame:PointToWorldSpace(Vector3.new(building.x, 0.4, building.z))
			end
		end
		return { alive = true, inRange = target ~= nil and (root.Position - target).Magnitude <= range }
	end

	local handlers = {}
	local function advance(context, state, timers, now, enabled)
		return ActiveTime.step(state, timers, now, math.max(0, now - context.lastTick), enabled, clock())
	end
	local function pause(context)
		local now = monotonic()
		local state = sessions:current(context.player.UserId)
		if state and context.wasActive then
			local result = advance(context, state, context.clocks, now, true)
			if result.revisionChanged then
				sessions:bump(context.player.UserId)
			end
		end
		context.wasActive = false
		context.lastTick = now
		for id in context.clocks do
			context.clocks[id] = now
		end
	end
	for _, action in actionNames do
		if action ~= "select" then
			handlers[action] = function(candidate, args, userId)
				local context = contexts[userId]
				local now = monotonic()
				local timers = State.copy(context.clocks)
				advance(context, candidate, timers, now, active(context))
				local result
				if action == "collect" then
					result = Economy.collect(candidate, args)
				elseif action == "sellAll" then
					result = Economy.sellAll(candidate)
				elseif action == "targetOutpost" then
					result = combat:validateOrder(userId, args)
				else
					result = Actions.apply(candidate, action, args, clock())
				end
				if result.ok and Workforce.reconcile(candidate) then
					result.resetProduction = true
				end
				if result.ok and result.resetProduction then
					Economy.resetClocks(candidate, timers, now)
				elseif result.ok and result.resetBuildings then
					for _, id in result.resetBuildings do
						timers[id] = now
					end
				end
				if result.ok then
					Economy.pruneClocks(candidate, timers)
				end
				return result, { clocks = timers, time = now }
			end
		end
	end
	local function redraw(userId)
		local context = contexts[userId]
		local view = sessions:snapshot(userId)
		if context and view.claim then
			local plot = world.plots[view.claim.plotId]
			World.render(plot, view.state, userId)
			context.player.RespawnLocation = plot.spawn
		end
	end
	local function positionCommander(context, destination)
		local view = sessions:snapshot(context.player.UserId)
		local character = context.player.Character
		local _, root = living(context.player)
		if view.claim and character and root then
			local arrival = if destination == "buy"
				then world.buyShopArrival
				elseif destination == "sell" then world.sellShopArrival
				else world.plots[view.claim.plotId].spawn.CFrame * CFrame.new(0, 3, 0)
			character:PivotTo(arrival)
		end
	end
	gateway = Requests.new({
		sessions = sessions,
		clock = monotonic,
		context = spatial,
		handlers = handlers,
		prepareSelection = function(candidate, userId)
			local context = contexts[userId]
			advance(context, candidate, State.copy(context.clocks), monotonic(), active(context))
			return candidate
		end,
		afterCommit = function(userId, action, result, timing)
			local context = contexts[userId]
			if action == "select" then
				local state = sessions:current(userId)
				if state and Workforce.reconcile(state) then
					sessions:bump(userId)
				end
				context.clocks = {}
				context.lastTick = monotonic()
				if state then
					Economy.resetClocks(state, context.clocks, context.lastTick)
				end
				context.wasActive = active(context)
				redraw(userId)
				positionCommander(context)
			else
				context.clocks = timing.clocks
				context.lastTick = timing.time
				if action == "travel" then
					positionCommander(context, result.destination)
				end
				if action ~= "collect" and action ~= "sellAll" and action ~= "settings" then
					local view = sessions:snapshot(userId)
					World.update(world.plots[view.claim.plotId], view.state, timing.time)
				end
			end
			combat:sync(userId, sessions:snapshot(userId), monotonic())
			if action == "targetOutpost" then
				local command = combat:command(userId, result.outpostId, result.armyId)
				assert(command.ok, "Validated army command failed: " .. tostring(command.reason))
			end
		end,
	})
	transport = Transport.start({
		actions = actionNames,
		snapshot = snapshot,
		request = function(player, action, intent)
			if shuttingDown then
				return { ok = false, reason = "server_closing" }
			end
			local context = contexts[player.UserId]
			if not context or context.player ~= player or context.closing then
				return { ok = false, reason = "profile_not_writable" }
			end
			return gateway:handle(player.UserId, action, intent)
		end,
	})

	local function finishRelease(userId, context, result)
		if contexts[userId] ~= context then
			return
		end
		if not result.ok then
			releaseFailures[userId] = result.reason
			sessions:abandon(userId)
			warn("Miniature final save unavailable for " .. userId .. ": " .. tostring(result.reason))
		end
		gateway:remove(userId)
		transport:remove(userId)
		contexts[userId] = nil
	end
	local function release(userId, expected)
		local context = contexts[userId]
		if not context or context ~= expected or context.closing then
			return
		end
		pause(context)
		context.closing = true
		context.profileStatus = "closing"
		combat:remove(userId)
		local view = sessions:snapshot(userId)
		local hadLoaded = view.loaded
		if view.claim then
			World.clear(world.plots[view.claim.plotId])
		end
		for _, connection in context.connections do
			connection:Disconnect()
		end
		for _, connection in context.characterConnections do
			connection:Disconnect()
		end
		local deadline = math.min(monotonic() + releaseSeconds, shutdownDeadline or math.huge)
		delay(math.max(0, deadline - monotonic()), function()
			if contexts[userId] == context then
				finishRelease(userId, context, { ok = false, reason = "release_timeout" })
			end
		end)
		local result = sessions:release(userId)
		while
			contexts[userId] == context
			and not result.ok
			and (result.reason == "save_busy" or result.reason == "save_failed" or result.reason == "load_busy")
			and monotonic() < deadline
		do
			wait(0.5)
			if contexts[userId] ~= context then
				return
			end
			result = sessions:release(userId)
		end
		if not hadLoaded and result.reason == "profile_not_writable" then
			result = { ok = true }
		end
		finishRelease(userId, context, result)
	end
	local function onPlayer(player)
		local userId = player.UserId
		local waitingUntil = monotonic() + loadSeconds
		while contexts[userId] and contexts[userId].player ~= player do
			if shuttingDown or player.Parent ~= Players then
				return
			end
			if monotonic() >= waitingUntil then
				warn("Miniature rejoin still waiting for prior release: " .. userId)
				return
			end
			wait(0.1)
		end
		if shuttingDown or player.Parent ~= Players or contexts[userId] then
			return
		end
		local context = {
			player = player,
			clocks = {},
			lastTick = monotonic(),
			lastPush = 0,
			lastSave = monotonic(),
			closing = false,
			wasActive = false,
			connections = {},
			characterConnections = {},
			profileStatus = "loading",
			profileReason = nil,
			loadExpired = false,
		}
		contexts[userId] = context
		local function current()
			return contexts[userId] == context
				and not context.closing
				and not shuttingDown
				and player.Parent == Players
				and not context.loadExpired
		end
		local loadDeadline, attempt = monotonic() + loadSeconds, 0
		delay(loadSeconds, function()
			if current() and context.profileStatus ~= "ready" then
				context.loadExpired = true
				context.profileStatus, context.profileReason = "error", "load_timeout"
				sessions:abandon(userId)
				warn("Miniature profile load timed out for " .. userId .. "; rejoin to retry")
				transport:send(player)
			end
		end)
		while current() do
			attempt += 1
			local loaded = sessions:load(userId)
			if not current() then
				return
			end
			if loaded.ok then
				context.profileStatus, context.profileReason = "ready", nil
				context.lastSave = monotonic()
				break
			end
			local retryable = loaded.reason == "load_failed"
				or loaded.reason == "profile_in_use"
				or loaded.reason == "load_busy"
			if not retryable or monotonic() >= loadDeadline then
				context.profileStatus, context.profileReason = "error", loaded.reason
				context.loadExpired = true
				sessions:abandon(userId)
				warn(
					"Miniature profile unavailable for "
						.. userId
						.. ": "
						.. tostring(loaded.reason)
						.. "; rejoin to retry"
				)
				transport:send(player)
				return
			end
			context.profileStatus, context.profileReason = "retrying", loaded.reason
			transport:send(player)
			wait(math.min(2 ^ math.min(attempt - 1, 3), math.max(0, loadDeadline - monotonic())))
		end
		if not current() then
			return
		end
		local function characterAdded(character)
			pause(context)
			for _, connection in context.characterConnections do
				connection:Disconnect()
			end
			table.clear(context.characterConnections)
			sessions:invalidate(player.UserId)
			context.wasActive = false
			context.lastTick = monotonic()
			for id in context.clocks do
				context.clocks[id] = context.lastTick
			end
			task.spawn(function()
				character:WaitForChild("HumanoidRootPart", 10)
				if contexts[player.UserId] ~= context or context.closing or player.Character ~= character then
					return
				end
				local function strip(container)
					for _, item in container:GetChildren() do
						if item:IsA("Tool") then
							item:Destroy()
						end
					end
					table.insert(
						context.characterConnections,
						container.ChildAdded:Connect(function(item)
							if item:IsA("Tool") then
								item:Destroy()
							end
						end)
					)
				end
				strip(character)
				local backpack = player:FindFirstChildOfClass("Backpack")
				if backpack then
					strip(backpack)
				end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.commanderWalkSpeed
					table.insert(
						context.characterConnections,
						humanoid.Died:Connect(function()
							if player.Character == character then
								pause(context)
								sessions:invalidate(player.UserId)
							end
						end)
					)
				end
				positionCommander(context)
				transport:send(player)
			end)
		end
		table.insert(context.connections, player.CharacterAdded:Connect(characterAdded))
		table.insert(
			context.connections,
			player.CharacterRemoving:Connect(function()
				pause(context)
				sessions:invalidate(player.UserId)
			end)
		)
		if player.Character then
			characterAdded(player.Character)
		end
		transport:send(player)
	end
	local connections = {
		Players.PlayerAdded:Connect(function(player)
			task.spawn(onPlayer, player)
		end),
		Players.PlayerRemoving:Connect(function(player)
			local context = contexts[player.UserId]
			if context and context.player == player then
				release(player.UserId, context)
			end
		end),
	}
	local accumulated = 0
	local combatElapsed = 0
	table.insert(
		connections,
		heartbeat:Connect(function(dt)
			if shuttingDown then
				return
			end
			combatElapsed += dt
			if combatElapsed < 0.1 then
				return
			end
			local now = monotonic()
			for userId, context in contexts do
				if not context.closing then
					combat:sync(userId, sessions:snapshot(userId), now)
				end
			end
			combat:step(math.min(combatElapsed, 0.25), now)
			combatElapsed = 0
		end)
	)
	table.insert(
		connections,
		heartbeat:Connect(function(dt)
			if shuttingDown then
				return
			end
			accumulated += dt
			if accumulated < 0.25 then
				return
			end
			accumulated = 0
			local now = monotonic()
			for userId, context in contexts do
				if context.closing then
					continue
				end
				local state = sessions:current(userId)
				local dirty = false
				local enabled = active(context)
				if enabled ~= context.wasActive then
					if context.wasActive then
						pause(context)
					end
					context.wasActive = enabled
					context.lastTick = now
					for id in context.clocks do
						context.clocks[id] = now
					end
				end
				if state then
					local advanced = advance(context, state, context.clocks, now, enabled)
					if advanced.revisionChanged then
						sessions:bump(userId)
						dirty = true
					end
					local view = sessions:snapshot(userId)
					World.update(world.plots[view.claim.plotId], state, now)
				end
				context.lastTick = now
				if dirty or now - context.lastPush >= 1 then
					transport:send(context.player)
					context.lastPush = now
				end
				if sessions:writable(userId) and now - context.lastSave >= 15 then
					context.lastSave = now
					task.spawn(function()
						if contexts[userId] ~= context or context.closing or shuttingDown then
							return
						end
						local saved = sessions:save(userId)
						if contexts[userId] ~= context or context.closing or shuttingDown then
							return
						end
						if saved.ok then
							context.saveReason = nil
						elseif saved.reason ~= "save_busy" then
							if context.saveReason ~= saved.reason then
								warn("Miniature autosave unavailable for " .. userId .. ": " .. tostring(saved.reason))
							end
							context.saveReason = saved.reason
							if not sessions:writable(userId) then
								combat:remove(userId)
							end
						end
						transport:send(context.player)
					end)
				end
			end
		end)
	)
	local function shutdown()
		shuttingDown = true
		shutdownDeadline = shutdownDeadline or monotonic() + 28
		for userId, context in contexts do
			task.spawn(release, userId, context)
		end
		while next(contexts) and monotonic() < shutdownDeadline do
			wait(0.1)
		end
		for userId, context in contexts do
			finishRelease(userId, context, { ok = false, reason = "shutdown_timeout" })
		end
		return { ok = next(releaseFailures) == nil, failures = table.clone(releaseFailures) }
	end
	bindToClose(shutdown)
	world.scene.Destroying:Once(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		transport:destroy()
		combat:destroy()
	end)
	if not injected then
		ReplicatedStorage:SetAttribute("MiniatureSandboxStorage", storageLabel)
		ReplicatedStorage:SetAttribute("MiniatureSandboxReady", true)
	end
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	return { scene = world.scene, sessions = sessions, store = store, snapshot = snapshot, shutdown = shutdown }
end

return Runtime

--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage.MiniatureGame
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local State = require(script.Parent.State)
local Sessions = require(script.Parent.Sessions)
local Requests = require(script.Parent.Requests)
local Economy = require(script.Parent.Economy)
local Workforce = require(script.Parent.Workforce)
local Actions = require(script.Parent.Actions)
local ActiveTime = require(script.Parent.ActiveTime)
local Transport = require(script.Parent.Transport)
local World = require(script.Parent.World)
local CombatController = require(script.Parent.CombatController)
local Runtime = {}

function Runtime.start(options)
	assert(RunService:IsStudio(), "Miniature settlement sandbox is Studio-only")
	assert(options.store and options.store.isFakeProfileStore == true, "An injected fake store is required")
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
		view.serverTime = clock()
		view.productionSpeed = Config.productionSpeed
		view.researchEnabled = Config.researchEnabled
		view.troopCapacity = Config.troopCap
		view.troopCapacityUsed = if view.state then State.troopCapacityUsed(view.state) else 0
		view.troops = if view.state then State.troops(view.state) else { melee = 0, ranged = 0, medic = 0, mounted = 0 }
		view.outposts, view.army = combat:snapshot(player.UserId)
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
		if action == "travel" then
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
				local command = combat:command(userId, result.outpostId)
				assert(command.ok, "Validated army command failed: " .. tostring(command.reason))
			end
		end,
	})
	transport = Transport.start({
		actions = actionNames,
		snapshot = snapshot,
		request = function(player, action, intent)
			return gateway:handle(player.UserId, action, intent)
		end,
	})

	local function release(userId)
		local context = contexts[userId]
		if not context or context.closing then
			return
		end
		pause(context)
		context.closing = true
		combat:remove(userId)
		local view = sessions:snapshot(userId)
		if view.claim then
			World.clear(world.plots[view.claim.plotId])
		end
		for _, connection in context.connections do
			connection:Disconnect()
		end
		for _, connection in context.characterConnections do
			connection:Disconnect()
		end
		local deadline = monotonic() + 20
		local result = sessions:release(userId)
		while
			not result.ok
			and (result.reason == "save_busy" or result.reason == "save_failed" or result.reason == "load_busy")
			and monotonic() < deadline
		do
			task.wait(0.5)
			result = sessions:release(userId)
		end
		if not result.ok then
			sessions:abandon(userId)
		end
		gateway:remove(userId)
		transport:remove(userId)
		contexts[userId] = nil
	end
	local function onPlayer(player)
		if contexts[player.UserId] then
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
		}
		contexts[player.UserId] = context
		local loaded = sessions:load(player.UserId)
		if contexts[player.UserId] ~= context or context.closing or player.Parent ~= Players then
			if loaded.ok then
				sessions:release(player.UserId)
			end
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
		Players.PlayerAdded:Connect(onPlayer),
		Players.PlayerRemoving:Connect(function(player)
			release(player.UserId)
		end),
	}
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	local accumulated = 0
	local combatElapsed = 0
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt)
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
		RunService.Heartbeat:Connect(function(dt)
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
				if now - context.lastSave >= 15 then
					context.lastSave = now
					task.spawn(function()
						sessions:save(userId)
					end)
				end
			end
		end)
	)
	game:BindToClose(function()
		for userId in contexts do
			task.spawn(release, userId)
		end
		local deadline = monotonic() + 22
		while next(contexts) and monotonic() < deadline do
			task.wait(0.1)
		end
	end)
	world.scene.Destroying:Once(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		transport:destroy()
		combat:destroy()
	end)
	ReplicatedStorage:SetAttribute("MiniatureSandboxStorage", "InjectedFakeProfileStore")
	ReplicatedStorage:SetAttribute("MiniatureSandboxReady", true)
	return { scene = world.scene, sessions = sessions, store = options.store }
end

return Runtime

--!strict
-- Native lifecycle orchestration with actual Runtime/Sessions, fake storage,
-- native Bindables/Models, and explicit player/world/transport doubles.
-- This is not multiplayer, real storage, authored art or GUI evidence.
local Replicated = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService").Sandbox
local Storage = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local Runtime = require(Server.Runtime)
local State = require(Server.State)
local FakeStore = require(Storage.FakeProfileStore)
local Fixture = {}

local function waitFor(predicate, description)
	local deadline = os.clock() + 5
	repeat
		if predicate() then
			return
		end
		task.wait(0.01)
	until os.clock() >= deadline
	error("Runtime lifecycle fixture timed out: " .. description)
end

local function harness(initialIds, store)
	store = store or FakeStore.new()
	assert(store.isFakeProfileStore, "Runtime fixture must never use persistent storage")
	local root = Instance.new("Folder")
	root.Name, root.Parent = "NativeRuntimeLifecycle_" .. Http:GenerateGUID(false), game:GetService("Workspace")
	local timers, gates, elapsed = {}, {}, 0
	local function event()
		local value = Instance.new("BindableEvent")
		value.Parent = root
		return value
	end
	local added, removing, heartbeat = event(), event(), event()
	-- BindableEvent copies table payloads. Pass only an opaque numeric token so
	-- the explicit player double retains identity and its cyclic Parent graph
	-- never crosses Roblox's argument-serialization boundary.
	local registry, keys, serial = {}, {}, 0
	local function keyFor(value)
		if not keys[value] then
			serial += 1
			keys[value], registry[serial] = serial, value
		end
		return keys[value]
	end
	local function playerSignal(native)
		return {
			Connect = function(_self, callback)
				return native.Event:Connect(function(key)
					callback(registry[key])
				end)
			end,
		}
	end
	local players = { list = {}, PlayerAdded = playerSignal(added), PlayerRemoving = playerSignal(removing) }
	function players:GetPlayers()
		return table.clone(self.list)
	end
	local function player(id)
		local character = Instance.new("Model")
		character.Name, character.Parent = "LifecycleCommander_" .. id, root
		local humanoid, part = Instance.new("Humanoid"), Instance.new("Part")
		humanoid.EvaluateStateMachine, humanoid.RequiresNeck, humanoid.AutoRotate = false, false, false
		humanoid.Parent = character
		part.Name, part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery =
			"HumanoidRootPart", true, false, false, false
		part.Parent, character.PrimaryPart = character, part
		local backpack = Instance.new("Backpack")
		backpack.Parent = root
		local value = {
			UserId = id,
			Parent = players,
			Character = character,
			CharacterAdded = event().Event,
			CharacterRemoving = event().Event,
		}
		function value:FindFirstChildOfClass(name)
			return if name == "Backpack" then backpack else nil
		end
		return value
	end
	for _, id in initialIds or {} do
		table.insert(players.list, player(id))
	end
	local world = {}
	function world.create()
		local scene = Instance.new("Model")
		scene.Name, scene.Parent = "IsolatedWorld", root
		local result = {
			scene = scene,
			plots = {},
			buyShopPosition = Vector3.zero,
			sellShopPosition = Vector3.zero,
			buyShopArrival = CFrame.new(),
			sellShopArrival = CFrame.new(),
		}
		for i = 1, 8 do
			local model, spawn = Instance.new("Model"), Instance.new("SpawnLocation")
			spawn.Enabled = false
			model.Name, model.Parent = "Plot" .. i, scene
			spawn.Anchored, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery, spawn.Parent =
				true, false, false, false, model
			result.plots[i] = { model = model, spawn = spawn, frame = CFrame.new(i * 100, 0, 0) }
		end
		return result
	end
	function world.installPreviews() end
	function world.supports()
		return true
	end
	function world.availableKits()
		return {}
	end
	function world.render() end
	function world.update() end
	function world.clear() end
	local combat = { active = {}, steps = 0, removals = {} }
	function combat:sync(id, view)
		self.active[id] = view.writable and view.claim ~= nil
	end
	function combat:remove(id)
		self.active[id] = nil
		self.removals[id] = (self.removals[id] or 0) + 1
	end
	function combat:step()
		self.steps += 1
	end
	function combat:snapshot()
		return {}, {}, {}
	end
	function combat:destroy() end
	local transport = { sent = {}, removed = {} }
	local transportOptions, close
	function transport:send(value)
		self.sent[value] = transportOptions.snapshot(value)
	end
	function transport:remove(id)
		self.removed[id] = (self.removed[id] or 0) + 1
	end
	function transport:destroy() end
	local runtime = Runtime.start({
		store = store,
		clock = function()
			return 1000 + elapsed
		end,
		monotonic = function()
			return elapsed
		end,
		testDependencies = {
			players = players,
			world = world,
			combat = {
				start = function()
					return combat
				end,
			},
			transport = {
				start = function(options)
					transportOptions = options
					return transport
				end,
			},
			heartbeat = heartbeat.Event,
			bindToClose = function(callback)
				close = callback
			end,
			wait = function(seconds)
				local untilTime = elapsed + seconds
				repeat
					task.wait(0.01)
				until elapsed >= untilTime
			end,
			delay = function(seconds, callback)
				table.insert(timers, { at = elapsed + seconds, callback = callback })
			end,
		},
	})
	local result =
		{ runtime = runtime, store = store, players = players, combat = combat, transport = transport, gates = gates }
	function result:add(id)
		local value = player(id)
		table.insert(players.list, value)
		added:Fire(keyFor(value))
		return value
	end
	function result:remove(value)
		value.Parent = nil
		for i, item in players.list do
			if item == value then
				table.remove(players.list, i)
				break
			end
		end
		removing:Fire(keyFor(value))
	end
	function result:step(seconds)
		elapsed += seconds
		for i = #timers, 1, -1 do
			if timers[i].at <= elapsed then
				local timer = table.remove(timers, i)
				task.spawn(timer.callback)
			end
		end
		heartbeat:Fire(seconds)
		task.wait(0.03)
	end
	function result:gate()
		local gate = store:gateNext()
		table.insert(gates, gate)
		return gate
	end
	local requestSerial = 0
	function result:request(value, action, args)
		requestSerial += 1
		local view = runtime.snapshot(value)
		return transportOptions.request(value, action, {
			requestId = "lifecycle:" .. requestSerial,
			sessionId = view.sessionId,
			claimEpoch = view.claimEpoch,
			revision = view.revision,
			args = args,
		})
	end
	function result:ready(value)
		waitFor(function()
			return runtime.snapshot(value).profileStatus == "ready"
		end, "ready profile")
		task.wait(0.03)
	end
	function result:shutdown()
		assert(close, "Shutdown hook was not installed during startup")
		local complete
		task.spawn(function()
			complete = close()
		end)
		for _ = 1, 60 do
			if complete then
				return complete
			end
			self:step(0.5)
		end
		error("Native runtime shutdown exceeded its shared bound")
	end
	function result:destroy()
		for _, gate in gates do
			gate:release()
		end
		self:shutdown()
		root:Destroy()
	end
	return result
end

function Fixture.run()
	assert(game:GetService("RunService"):IsStudio(), "Runtime fixture is Studio-only")
	local count, evidence, owned =
		0, {
			method = "Actual Runtime/Sessions with fake storage, virtual clocks, native Bindables/Models and explicit service doubles",
			cases = {},
		}, {}
	local function own(initial, store)
		local value = harness(initial, store)
		table.insert(owned, value)
		return value
	end
	local function check(name, callback)
		callback()
		count += 1
		table.insert(evidence.cases, name)
		print("PASS native runtime lifecycle: " .. name)
	end
	local ok, failure = pcall(function()
		check("persistent adapters cannot enable lifecycle doubles", function()
			local accepted = pcall(function()
				Runtime.start({
					store = {
						isPersistentProfileStore = true,
						storageLabel = "never-opened-verification",
						UpdateAsync = function()
							error("Persistent fixture adapter was unexpectedly called")
						end,
					},
					testDependencies = {},
				})
			end)
			assert(not accepted, "Persistent Runtime accepted service doubles")
		end)
		check("transient acquisition retries and becomes writable without defaulting failed data", function()
			local h = own()
			h.store:queue({ beforeError = "declared transient load failure" })
			local p = h:add(101)
			waitFor(function()
				return h.runtime.snapshot(p).profileStatus == "retrying"
			end, "retry status")
			assert(
				not h.runtime.snapshot(p).writable and #h.store.commits == 0,
				"Failed acquisition admitted or wrote gameplay"
			)
			h:step(1.1)
			h:ready(p)
			assert(h:request(p, "select", { civilizationId = "sparta" }).ok, "Recovered writer could not select")
			assert(
				h.runtime.snapshot(p).state.coins == 200 and #h.store.attempts >= 2,
				"Recovery granted test money or skipped retry"
			)
			h:destroy()
		end)
		check("corrupt saved data is terminal visible and never replaced", function()
			local h = own()
			local record = { schemaVersion = 999, civilizations = {} }
			h.store:seed("miniature-development:102", record)
			local p = h:add(102)
			waitFor(function()
				return h.runtime.snapshot(p).profileStatus == "error"
			end, "terminal invalid data")
			assert(
				h.runtime.snapshot(p).profileReason == "invalid_saved_data" and #h.store.commits == 0,
				"Corrupt save was overwritten"
			)
			h:step(80)
			assert(
				h.store:read("miniature-development:102").schemaVersion == 999 and not h.runtime.snapshot(p).writable,
				"Watchdog defaulted corrupt data"
			)
			h:destroy()
		end)
		check(
			"a player browsing civilization selection retains renewable authority without choosing a civilization",
			function()
				local h = own()
				local p = h:add(111)
				h:ready(p)
				for _ = 1, 6 do
					h:step(15.1)
					waitFor(function()
						return math.abs((h.runtime.snapshot(p).lastSavedAt or 0) - (1000 + _ * 15.1)) < 0.000001
					end, "unselected lease renewal")
				end
				assert(
					h.runtime.snapshot(p).writable and h.runtime.snapshot(p).state == nil,
					"Unselected profile lost authority or created a civilization"
				)
				assert(
					h:request(p, "select", { civilizationId = "sparta" }).ok
						and h.runtime.snapshot(p).state.coins == 200,
					"Selection failed after more than one original lease duration"
				)
				h:destroy()
			end
		)
		check("a blocked initial player cannot block other joins heartbeat or shutdown registration", function()
			local store = FakeStore.new()
			local gate = store:gateNext()
			local h = own({ 103, 104 }, store)
			table.insert(h.gates, gate)
			waitFor(function()
				return gate.entered
			end, "gated initial load")
			h:ready(h.players.list[2])
			h:step(0.25)
			assert(
				h.combat.steps > 0 and not h.runtime.snapshot(h.players.list[1]).loaded,
				"Startup blocked world heartbeat or admitted pending load"
			)
			gate:release()
			h:ready(h.players.list[1])
			h:destroy()
		end)
		check(
			"rapid same-user reconnect waits for prior final save and old cleanup cannot erase new session",
			function()
				local h = own()
				local old = h:add(105)
				h:ready(old)
				assert(h:request(old, "select", { civilizationId = "sparta" }).ok, "Select failed")
				h.runtime.sessions:current(105).coins = 173 -- Declared fixture progress in injected fake storage only.
				local token = h.runtime.snapshot(old).sessionId
				local gate = h:gate()
				h:remove(old)
				waitFor(function()
					return gate.entered
				end, "gated final save")
				local fresh = h:add(105)
				task.wait(0.04)
				assert(
					h.runtime.snapshot(fresh).profileStatus == "closing" and not h.runtime.snapshot(fresh).writable,
					"Rejoin bypassed prior close"
				)
				assert(
					h:request(fresh, "select", { civilizationId = "rome" }).reason == "profile_not_writable",
					"Waiting replacement Player acted through the old context"
				)
				gate:release()
				h:step(0.2)
				h:ready(fresh)
				assert(
					h.runtime.snapshot(fresh).sessionId ~= token
						and h:request(fresh, "select", { civilizationId = "sparta" }).ok,
					"Rejoin did not acquire a fresh session"
				)
				assert(h.runtime.snapshot(fresh).state.coins == 173, "Rejoin lost final progress")
				-- Supply the current token deliberately: Player identity, independently
				-- of stale envelopes, must reject the departed instance.
				assert(
					h:request(old, "select", { civilizationId = "rome" }).reason == "profile_not_writable",
					"Departed Player acted through the replacement context"
				)
				assert(
					h.runtime.snapshot(fresh).claim.civilizationId == "sparta",
					"Rejected old Player changed the fresh claim"
				)
				h:step(30)
				assert(
					h.runtime.snapshot(fresh).writable and h.transport.removed[105] == 1,
					"Old delayed cleanup removed the new context"
				)
				h:destroy()
			end
		)
		check(
			"autosave errors remain visible recover only on acknowledgement and lease loss stops requests and combat",
			function()
				local h = own()
				local p = h:add(106)
				h:ready(p)
				assert(h:request(p, "select", { civilizationId = "sparta" }).ok, "Select failed")
				local savedAt = h.runtime.snapshot(p).lastSavedAt
				h.store:queue({ beforeError = "declared autosave outage" })
				h:step(15.25)
				waitFor(function()
					return h.runtime.snapshot(p).profileStatus == "save_retry"
				end, "save retry status")
				assert(h.runtime.snapshot(p).lastSavedAt == savedAt, "Failed save reported durability")
				h:step(15.25)
				waitFor(function()
					return h.runtime.snapshot(p).profileStatus == "ready"
				end, "save acknowledgement")
				assert(h.runtime.snapshot(p).lastSavedAt > (savedAt or 0), "Acknowledged save timestamp missing")
				local stored = h.store:read("miniature-development:106")
				stored.lease = { token = "declared-successor", expiresAt = 2000 }
				h.store:seed("miniature-development:106", stored)
				h:step(15.25)
				waitFor(function()
					return h.runtime.snapshot(p).profileStatus == "read_only"
				end, "authority loss")
				local before = h.runtime.snapshot(p).state
				assert(
					h:request(p, "buy", { kind = "house" }).reason == "profile_not_writable"
						and not h.combat.active[106],
					"Lost lease retained gameplay authority"
				)
				h:step(10)
				assert(
					h.runtime.snapshot(p).state.coins == before.coins
						and h.runtime.snapshot(p).state.buildings[3].output == before.buildings[3].output,
					"Read-only profile kept producing"
				)
				h:destroy()
			end
		)
		check(
			"final save settles partial research once and rejoin never credits offline production or research",
			function()
				local h = own()
				local initial = State.new("sparta", 1000)
				initial.coins = 2000 -- Explicit research fixture funding, never a live profile.
				h.store:seed("miniature-development:107", { schemaVersion = 1, civilizations = { sparta = initial } })
				local p = h:add(107)
				h:ready(p)
				assert(
					h:request(p, "select", { civilizationId = "sparta" }).ok
						and h:request(p, "militaryResearch", { id = "army_training" }).ok,
					"Paid research setup failed"
				)
				h:step(4.25)
				local remaining = h.runtime.snapshot(p).state.militaryResearch.project.remaining
				local output = h.runtime.snapshot(p).state.buildings[3].output
				assert(math.abs(remaining - 25.75) < 0.001, "Actual active elapsed was not applied")
				local gate = h:gate()
				h:remove(p)
				waitFor(function()
					return gate.entered
				end, "research final save")
				h:step(10)
				gate:release()
				task.wait(0.03)
				local fresh = h:add(107)
				h:ready(fresh)
				assert(h:request(fresh, "select", { civilizationId = "sparta" }).ok, "Research rejoin select failed")
				local restored = h.runtime.snapshot(fresh).state
				assert(
					restored.coins == 1000
						and restored.buildings[3].output == output
						and restored.militaryResearch.project.remaining == remaining,
					"Offline or closing time advanced or repaid research"
				)
				h:step(0.5)
				assert(
					math.abs(h.runtime.snapshot(fresh).state.militaryResearch.project.remaining - (remaining - 0.5))
						< 0.001,
					"Reactivated research clock reset or double-counted"
				)
				h:destroy()
			end
		)
		check("shutdown saves other players in parallel and fences a blocked late completion", function()
			local h = own()
			local p, second = h:add(108), h:add(109)
			h:ready(p)
			h:ready(second)
			assert(
				h:request(p, "select", { civilizationId = "sparta" }).ok
					and h:request(second, "select", { civilizationId = "rome" }).ok,
				"Parallel shutdown setup failed"
			)
			local gate = h:gate()
			local finished
			task.spawn(function()
				finished = h:shutdown()
			end)
			waitFor(function()
				return gate.entered
			end, "blocked shutdown write")
			waitFor(function()
				return h.store:read("miniature-development:109").lease == nil
					or h.store:read("miniature-development:108").lease == nil
			end, "other parallel final save")
			waitFor(function()
				return finished ~= nil
			end, "bounded shutdown result")
			assert(
				not finished.ok and next(finished.failures) ~= nil,
				"Incomplete shutdown claimed successful durability"
			)
			gate:release()
			task.wait(0.05)
			assert(
				not h.runtime.snapshot(p).loaded and not h.runtime.snapshot(second).loaded,
				"Late completion revived a closed session"
			)
			local after = h:add(110)
			task.wait(0.03)
			assert(
				not h.runtime.snapshot(after).loaded
					and h:request(after, "select", { civilizationId = "egypt" }).reason == "server_closing",
				"Shutdown admitted new gameplay"
			)
			h:destroy()
		end)
	end)
	for _, h in owned do
		local cleaned, reason = pcall(function()
			h:destroy()
		end)
		if not cleaned then
			warn("Runtime fixture cleanup: " .. tostring(reason))
		end
	end
	evidence.ok, evidence.casesPassed = ok, count
	evidence.error = if ok then nil else tostring(failure)
	Replicated:SetAttribute("MiniatureRuntimeLifecycleResult", Http:JSONEncode(evidence))
	assert(ok, failure)
	return evidence
end
return Fixture

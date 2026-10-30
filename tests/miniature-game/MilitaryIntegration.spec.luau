--!strict
local Server = game:GetService("ServerScriptService").Sandbox
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local State = require(Server.State)
local Actions = require(Server.Actions)
local ActiveTime = require(Server.ActiveTime)
local Sessions = require(Server.Sessions)
local Requests = require(Server.Requests)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)
local Military = require(Shared.MilitaryResearch)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature military integration: " .. name)
	end
	check("missing-only migration preserves original and rejects malformed fields", function()
		local legacy = State.new("sparta", 0)
		legacy.militaryResearch, legacy.armyGroups = nil, nil
		legacy.coins, legacy.goods.food = 1234, 12
		local migrated = State.upgrade(legacy, "sparta")
		assert(migrated and migrated.coins == 1234 and migrated.goods.food == 12, "Legacy progress lost")
		assert(legacy.militaryResearch == nil and legacy.armyGroups == nil, "Migration mutated original")
		assert(State.validate(migrated, "sparta"), "Migrated state invalid")
		for _, malformed in { false, 7, "bad", {}, { completed = false }, { completed = { invented = true } } } do
			local broken = State.copy(migrated)
			broken.militaryResearch = malformed
			assert(State.upgrade(broken, "sparta") == nil, "Malformed military field defaulted")
		end
		for _, malformed in { false, 7, {}, { army2 = {}, army3 = {} }, { army2 = { "b3" }, army3 = {}, army4 = {} } } do
			local broken = State.copy(migrated)
			broken.armyGroups = malformed
			assert(State.upgrade(broken, "sparta") == nil, "Malformed group field defaulted")
		end
	end)
	check("military clock runs while legacy research remains paused and revises only on completion", function()
		local state = State.new("sparta", 0)
		state.coins = 2000
		assert(Actions.apply(state, "militaryResearch", { id = "army_training" }, 0).ok, "Start failed")
		local first = ActiveTime.step(state, {}, 10, 10, true, 0)
		assert(
			state.militaryResearch.project.remaining == 20 and first.changed and not first.revisionChanged,
			"Clock failed"
		)
		ActiveTime.step(state, {}, 100, 90, false, 0)
		assert(state.militaryResearch.project.remaining == 20, "Inactive time banked")
		local finished = ActiveTime.step(state, {}, 120, 20, true, 0)
		assert(finished.revisionChanged and state.militaryResearch.completed.army_training, "Completion missing")
		assert(state.coins == 1000 and next(state.research.completed) == nil, "Legacy research or price changed")
	end)
	check("military requests retain payment replay life lease and civilization guards", function()
		local now, serial, alive = 0, 0, true
		local store = FakeStore.new()
		local options = {
			store = store,
			clock = function()
				return now
			end,
			token = function()
				serial += 1
				return "military-" .. serial
			end,
		}
		local sessions = Sessions.new(options)
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Session failed")
		sessions:current(1).coins = 2000
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return now
			end,
			context = function()
				return { alive = alive, inRange = true }
			end,
			handlers = {
				militaryResearch = function(state, args)
					return Actions.apply(state, "militaryResearch", args, now)
				end,
				configureArmy = function(state, args)
					return Actions.apply(state, "configureArmy", args, now)
				end,
			},
		})
		local function intent(id, args)
			local view = sessions:snapshot(1)
			return {
				requestId = id,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = args,
			}
		end
		local request = intent("start", { id = "army_training" })
		alive = false
		assert(gateway:handle(1, "militaryResearch", request).reason == "owner_not_alive", "Dead research accepted")
		alive = true
		assert(gateway:handle(1, "militaryResearch", request).ok, "Purchase failed")
		assert(
			gateway:handle(1, "militaryResearch", request).ok and sessions:current(1).coins == 1000,
			"Replay charged twice"
		)
		local old = intent("old", { id = "army_training" })
		assert(sessions:select(1, "rome").ok, "Switch failed")
		assert(not gateway:handle(1, "militaryResearch", old).ok, "Old civilization accepted")
		assert(next(sessions:current(1).militaryResearch.completed) == nil, "Cross-civilization progress leaked")
		assert(sessions:select(1, "sparta").ok, "Return failed")
		assert(sessions:current(1).militaryResearch.project.remaining == 30, "Switch clock advanced")
		assert(sessions:release(1).ok, "Save failed")
		now = 10000
		local restored = Sessions.new(options)
		assert(restored:load(1).ok and restored:select(1, "sparta").ok, "Restore failed")
		assert(restored:current(1).militaryResearch.project.remaining == 30, "Offline time advanced")
		assert(restored:current(1).coins == 1000, "Paid balance lost")
		local restoredView = restored:snapshot(1)
		local expiredGateway = Requests.new({
			sessions = restored,
			clock = function()
				return now
			end,
			context = function()
				return { alive = true, inRange = true }
			end,
			handlers = {
				militaryResearch = function(candidate, args)
					return Actions.apply(candidate, "militaryResearch", args, now)
				end,
			},
		})
		now += 61
		local expired = expiredGateway:handle(1, "militaryResearch", {
			requestId = "expired",
			sessionId = restoredView.sessionId,
			claimEpoch = restoredView.claimEpoch,
			revision = restoredView.revision,
			args = { id = "field_bandages" },
		})
		assert(expired.reason == "profile_not_writable", "Expired writer started research")
		assert(restored:snapshot(1).state.coins == 1000, "Expired request charged Coins")
	end)
	check("group arrays cross the request envelope but sparse or foreign structures are refused", function()
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return 0
			end,
			token = function()
				return "groups"
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Setup failed")
		local state = sessions:current(1)
		state.militaryResearch.completed = { army_training = true, officer_training = true, army_control = true }
		state.plans.training = 1
		assert(
			Actions.apply(state, "place", { kind = "training", x = 20, z = 12, rotation = 0 }, 0).ok,
			"Building setup failed"
		)
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return 0
			end,
			context = function()
				return { alive = true, inRange = true }
			end,
			handlers = {
				configureArmy = function(candidate, args)
					return Actions.apply(candidate, "configureArmy", args, 0)
				end,
			},
		})
		local function configure(id, ids)
			local view = sessions:snapshot(1)
			return gateway:handle(1, "configureArmy", {
				requestId = id,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = { armyId = 2, buildingIds = ids },
			})
		end
		assert(configure("valid", { "b4" }).ok, "Dense numeric array rejected")
		assert(not configure("sparse", { [2] = "b4" }).ok, "Sparse array accepted")
		assert(not configure("foreign", { "b999" }).ok, "Foreign building accepted")
		assert(sessions:current(1).armyGroups.army2[1] == "b4", "Rejected edit changed preset")
		assert(Military.groupSlots(state.militaryResearch.completed) == 2, "Control tier mismatch")
	end)
	return count
end

return run

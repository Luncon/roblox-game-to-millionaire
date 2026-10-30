--!strict
local Requests = require(game:GetService("ServerScriptService").Sandbox.Requests)
local Sessions = require(game:GetService("ServerScriptService").Sandbox.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)
local Economy = require(game:GetService("ServerScriptService").Sandbox.Economy)
local Actions = require(game:GetService("ServerScriptService").Sandbox.Actions)

local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature: " .. name)
	end
	local function fixture()
		local now, serial, alive, inRange, committed = 0, 0, true, true, 0
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return now
			end,
			token = function()
				serial += 1
				return "request-session-" .. serial
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Setup failed")
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return now
			end,
			context = function()
				return { alive = alive, inRange = inRange }
			end,
			handlers = {
				spend = function(state, args)
					if args.amount ~= 20 then
						return { ok = false, reason = "invalid_amount" }
					end
					state.coins -= args.amount
					return { ok = true }, { clock = 7 }
				end,
			},
			afterCommit = function(_, _, _, timing)
				if timing then
					assert(timing.clock == 7, "Server timing was not committed")
				end
				committed += 1
			end,
		})
		local function payload(requestId)
			local view = sessions:snapshot(1)
			return {
				requestId = requestId,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = { amount = 20 },
			}
		end
		return gateway,
			sessions,
			payload,
			function(nextAlive, nextRange, nextNow)
				alive, inRange, now = nextAlive, nextRange, nextNow or now
			end,
			function()
				return committed
			end
	end
	check("one accepted intent has one charge and a repeated intent returns its receipt", function()
		local gateway, sessions, payload, _, commits = fixture()
		local intent = payload("one")
		assert(gateway:handle(1, "spend", intent).ok, "Valid request rejected")
		assert(gateway:handle(1, "spend", intent).ok, "Replay receipt rejected")
		assert(sessions:current(1).coins == 180, "Replay charged twice")
		assert(not gateway:handle(2, "spend", intent).ok, "Foreign session accepted")
		assert(commits() == 1, "Replay applied server timing twice")
	end)
	check("malformed scalar nested and nonfinite payloads cannot mutate", function()
		local gateway, sessions, payload = fixture()
		for index, value in { math.huge, 0 / 0, "20", -1 } do
			local intent = payload("bad-" .. index)
			intent.args.amount = value
			assert(not gateway:handle(1, "spend", intent).ok, "Malformed amount accepted")
		end
		local intent = payload("nested")
		intent.args = { data = { nested = { over = { depth = 1 } } } }
		assert(not gateway:handle(1, "spend", intent).ok, "Unbounded payload accepted")
		local wide = {}
		for index = 1, 16 do
			local children = {}
			for child = 1, 16 do
				children["key" .. child] = string.rep("x", 128)
			end
			wide["key" .. index] = children
		end
		intent.args = wide
		assert(gateway:handle(1, "spend", intent).reason == "invalid_request", "Aggregate payload budget bypassed")
		assert(sessions:current(1).coins == 200, "Invalid traffic changed balance")
	end)
	check("life range revision civilization and lease are independently guarded", function()
		local gateway, sessions, payload, setContext = fixture()
		local intent = payload("stale")
		setContext(false, true)
		assert(not gateway:handle(1, "spend", intent).ok, "Dead owner accepted")
		setContext(true, false)
		assert(not gateway:handle(1, "spend", intent).ok, "Out-of-range owner accepted")
		setContext(true, true)
		sessions:bump(1)
		assert(not gateway:handle(1, "spend", intent).ok, "Stale revision accepted")
		intent = payload("old-faction")
		assert(sessions:select(1, "rome").ok, "Switch failed")
		assert(not gateway:handle(1, "spend", intent).ok, "Old claim epoch accepted")
		intent = payload("expired")
		setContext(true, true, 61)
		assert(not gateway:handle(1, "spend", intent).ok, "Expired authority accepted")
		assert(sessions:snapshot(1).state.coins == 200, "A rejected request changed state")
	end)
	check("request and receipt storage are bounded under repeated traffic", function()
		local gateway, sessions, payload = fixture()
		local accepted = 0
		for index = 1, 100 do
			local result = gateway:handle(1, "spend", payload("burst-" .. index))
			if result.ok then
				accepted += 1
			end
		end
		assert(accepted <= 8 and accepted > 0, "Burst budget is not bounded")
		assert(sessions:current(1).coins == 200 - accepted * 20, "Burst conservation failed")
		gateway:remove(1)
		assert(gateway:size() == 0, "Departed request state leaked")
	end)
	check("selection retries return the original receipt until its current life or claim changes", function()
		local gateway, sessions, payload, _, commits = fixture()
		local intent = payload("select-once")
		intent.args = { civilizationId = "persia" }
		assert(gateway:handle(1, "select", intent).ok, "Valid selection failed")
		local epoch = sessions:snapshot(1).claimEpoch
		assert(gateway:handle(1, "select", intent).ok, "Selection replay lost its receipt")
		assert(sessions:snapshot(1).claimEpoch == epoch and commits() == 1, "Selection replay applied again")
		intent.args.civilizationId = "sparta"
		assert(gateway:handle(1, "select", intent).reason == "request_id_reused", "Reused request ID accepted")
		intent.args.civilizationId = "persia"
		sessions:invalidate(1)
		assert(not gateway:handle(1, "select", intent).ok, "Prior-life receipt survived invalidation")
	end)
	check("competing sales of one inventory accept exactly one price-conserving mutation", function()
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return 0
			end,
			token = function()
				return "sales"
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Sales setup failed")
		sessions:current(1).goods.food = 10
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return 0
			end,
			context = function()
				return { alive = true, inRange = true }
			end,
			handlers = { sell = Economy.sell },
		})
		local view = sessions:snapshot(1)
		local function intent(id)
			return {
				requestId = id,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = { good = "food", amount = 10 },
			}
		end
		assert(gateway:handle(1, "sell", intent("first")).ok, "First sale failed")
		assert(not gateway:handle(1, "sell", intent("competing")).ok, "Competing stale sale accepted")
		assert(gateway:handle(1, "sell", intent("first")).ok, "Repeated receipt failed")
		assert(sessions:current(1).coins == 220 and sessions:current(1).goods.food == 0, "Sales created or lost value")
	end)
	check("the last private merchant plan has one buyer and never changes another owner's stock", function()
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return 0
			end,
			token = function()
				return "merchant"
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "First setup failed")
		assert(sessions:load(2).ok and sessions:select(2, "rome").ok, "Second setup failed")
		sessions:current(1).merchant.stock.house = 1
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return 0
			end,
			context = function()
				return { alive = true, inRange = true }
			end,
			handlers = {
				buy = function(state, args)
					return Actions.apply(state, "buy", args, 0)
				end,
			},
		})
		local view = sessions:snapshot(1)
		local function intent(id)
			return {
				requestId = id,
				sessionId = view.sessionId,
				claimEpoch = view.claimEpoch,
				revision = view.revision,
				args = { kind = "house" },
			}
		end
		assert(gateway:handle(1, "buy", intent("first")).ok, "Last-stock purchase failed")
		assert(not gateway:handle(1, "buy", intent("competing")).ok, "Competing purchase accepted")
		assert(gateway:handle(1, "buy", intent("first")).ok, "Purchase receipt missing")
		assert(
			sessions:current(1).coins == 120
				and sessions:current(1).plans.house == 1
				and sessions:current(1).merchant.stock.house == 0,
			"Purchase ledger failed"
		)
		assert(
			sessions:current(2).coins == 200
				and sessions:current(2).plans.house == 0
				and sessions:current(2).merchant.stock.house == 2,
			"Another owner changed"
		)
	end)
	check("reclaim and Sell All preserve authority stale and replay boundaries without duplicate value", function()
		local now, alive, inRange = 0, true, true
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return now
			end,
			token = function()
				return "reclaim-sale"
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Reclaim session setup failed")
		sessions:current(1).buildings[3].output = 12
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return now
			end,
			context = function()
				return { alive = alive, inRange = inRange }
			end,
			handlers = {
				reclaim = function(state, args)
					return Actions.apply(state, "reclaim", args, now)
				end,
				sellAll = Economy.sellAll,
				travel = function(state, args)
					return Actions.apply(state, "travel", args, now)
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
		local reclaim = intent("reclaim", { buildingId = "b3" })
		alive = false
		assert(gateway:handle(1, "reclaim", reclaim).reason == "owner_not_alive", "Dead owner reclaimed")
		alive, inRange = true, false
		assert(gateway:handle(1, "reclaim", reclaim).reason == "out_of_range", "Remote reclaim accepted")
		inRange = true
		sessions:bump(1)
		assert(gateway:handle(1, "reclaim", reclaim).reason == "stale_revision", "Stale reclaim accepted")
		reclaim = intent("reclaim", { buildingId = "b3" })
		assert(
			gateway:handle(1, "reclaim", reclaim).ok and gateway:handle(1, "reclaim", reclaim).ok,
			"Reclaim or replay failed"
		)
		assert(
			sessions:current(1).plans.farm == 1 and sessions:current(1).goods.food == 12,
			"Replay duplicated plan or output"
		)
		now = 1
		local sell = intent("sale", {})
		assert(
			gateway:handle(1, "sellAll", sell).ok and gateway:handle(1, "sellAll", sell).ok,
			"Sell All or replay failed"
		)
		assert(
			sessions:current(1).coins == 224 and sessions:current(1).goods.food == 0,
			"Sell All replay duplicated currency"
		)
		local stale = intent("stale-sale", {})
		sessions:bump(1)
		assert(gateway:handle(1, "sellAll", stale).reason == "stale_revision", "Stale Sell All accepted")
		local travel = intent("travel", { destination = "buy" })
		assert(gateway:handle(1, "travel", travel).ok and sessions:current(1).coins == 224, "Travel charged currency")
		now = 2
		assert(
			not gateway:handle(1, "travel", intent("bad-travel", { destination = "foreign", x = 999 })).ok,
			"Client chose arbitrary travel target"
		)
		local expired = intent("expired", {})
		now = 61
		assert(gateway:handle(1, "sellAll", expired).reason == "profile_not_writable", "Lost writer sold goods")
	end)
	return count
end

return run

--!strict
local Requests = require(game:GetService("ServerScriptService").Sandbox.Requests)
local Sessions = require(game:GetService("ServerScriptService").Sandbox.Sessions)
local FakeStore = require(game:GetService("ServerStorage").FakeProfileStore)

return function(): number
	local cases = 0
	for _, mode in { "valid", "dead", "distant", "stale_revision", "stale_life", "foreign", "read_only" } do
		local now, serial, commands = 0, 0, 0
		local sessions = Sessions.new({
			store = FakeStore.new(),
			clock = function()
				return now
			end,
			token = function()
				serial += 1
				return "outpost-intent-" .. tostring(serial)
			end,
		})
		assert(sessions:load(1).ok and sessions:select(1, "sparta").ok, "Outpost authority fixture setup failed")
		local gateway = Requests.new({
			sessions = sessions,
			clock = function()
				return now
			end,
			context = function()
				return { alive = mode ~= "dead", inRange = mode ~= "distant" }
			end,
			handlers = {
				targetOutpost = function(_, args)
					return { ok = args.outpostId == "outpost_1", outpostId = args.outpostId }
				end,
			},
			afterCommit = function()
				commands += 1
			end,
		})
		local view = sessions:snapshot(1)
		local intent = {
			requestId = "order",
			sessionId = view.sessionId,
			claimEpoch = view.claimEpoch,
			revision = view.revision,
			args = { outpostId = "outpost_1" },
		}
		if mode == "stale_revision" then
			sessions:bump(1)
		elseif mode == "stale_life" then
			sessions:invalidate(1)
		elseif mode == "foreign" then
			intent.sessionId = "another-owner-session"
		elseif mode == "read_only" then
			now = 61
		end
		local result = gateway:handle(1, "targetOutpost", intent)
		assert(result.ok == (mode == "valid"), "Wrong outpost intent result: " .. mode)
		if mode == "valid" then
			assert(gateway:handle(1, "targetOutpost", intent).ok, "Order replay lost its receipt")
			assert(commands == 1, "Order replay reapplied the command")
			assert(sessions:current(1).coins == 200, "Army order changed the economy")
		else
			assert(commands == 0, "Refused order reached combat: " .. mode)
		end
		cases += 1
		print("PASS miniature: outpost command authority " .. mode)
	end
	return cases
end

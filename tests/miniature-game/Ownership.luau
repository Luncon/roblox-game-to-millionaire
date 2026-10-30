--!strict
-- Native server, simulated owners. No extra clients and no player DataStores.
return function()
	local Replicated = game:GetService("ReplicatedStorage")
	assert(game:GetService("RunService"):IsStudio(), "Studio ownership fixture only")
	assert(Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong test boundary")
	local Sandbox = game.ServerScriptService.Sandbox
	local Sessions, Requests = require(Sandbox.Sessions), require(Sandbox.Requests)
	local Actions = require(Sandbox.Actions)
	local store = require(game.ServerStorage.FakeProfileStore).new()
	local serial = 0
	local sessions = Sessions.new({
		store = store,
		clock = function()
			return 0
		end,
		token = function()
			serial += 1
			return "native-simulated-owner-" .. serial
		end,
	})
	local ok, result = pcall(function()
		assert(sessions:load(101).ok and sessions:select(101, "sparta").ok, "Owner one setup")
		assert(sessions:load(102).ok and sessions:select(102, "rome").ok, "Owner two setup")
		assert(not sessions:select(102, "sparta").ok, "Exclusive claim bypassed")
		local originalPlot = sessions:snapshot(101).claim.plotId
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
		local view = sessions:snapshot(101)
		local intent = {
			requestId = "private-house",
			sessionId = view.sessionId,
			claimEpoch = view.claimEpoch,
			revision = view.revision,
			args = { kind = "house" },
		}
		assert(gateway:handle(101, "buy", intent).ok, "Owner purchase rejected")
		assert(not gateway:handle(102, "buy", intent).ok, "Foreign session accepted")
		assert(sessions:current(101).coins == 120 and sessions:current(101).plans.house == 1, "Private charge failed")
		assert(sessions:current(101).merchant.stock.house == 1, "Private stock failed")
		assert(
			sessions:current(102).coins == 200
				and sessions:current(102).plans.house == 0
				and sessions:current(102).merchant.stock.house == 2,
			"Foreign progress changed"
		)
		assert(
			sessions:select(101, "persia").ok and sessions:current(101).coins == 200,
			"Civilization isolation failed"
		)
		assert(
			sessions:select(101, "sparta").ok and sessions:current(101).coins == 120,
			"Civilization restoration failed"
		)
		assert(sessions:release(101).ok, "First departure failed")
		assert(sessions:load(103).ok and sessions:select(103, "sparta").ok, "Replacement plot claim failed")
		assert(
			sessions:snapshot(103).claim.plotId == originalPlot and sessions:current(103).coins == 200,
			"Replacement inherited someone else's progress"
		)
		assert(sessions:load(101).ok and sessions:select(101, "persia").ok, "Returning owner could not claim free plot")
		local restoredPlot = sessions:snapshot(101).claim.plotId
		assert(restoredPlot ~= originalPlot and not sessions:select(101, "sparta").ok, "Occupied plot was stolen")
		assert(sessions:release(103).ok and sessions:select(101, "sparta").ok, "Returned civilization unavailable")
		assert(
			sessions:snapshot(101).claim.plotId == restoredPlot
				and sessions:current(101).coins == 120
				and sessions:current(101).merchant.stock.house == 1
				and sessions:current(101).plans.house == 1,
			"Saved progression was bound to a physical plot"
		)
		return {
			simulatedOwners = 3,
			concurrentOwners = 2,
			exclusiveClaims = true,
			privateStock = true,
			foreignRequestsRejected = true,
			originalPlot = originalPlot,
			restoredPlot = restoredPlot,
			restoredCoins = 120,
			restoredHousePlans = 1,
			restoredHouseStock = 1,
			physicalMulticlientTest = false,
			fakeStoreOnly = true,
		}
	end)
	for _, userId in { 101, 102, 103 } do
		if sessions:snapshot(userId).loaded then
			assert(sessions:release(userId).ok, "Ownership fixture cleanup failed")
		end
		local record = store:read("miniature-development:" .. userId)
		assert(not record or record.lease == nil, "Fixture lease leaked")
	end
	Replicated:SetAttribute(
		"MiniatureOwnershipResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = result })
	)
	assert(ok, tostring(result))
	return result
end

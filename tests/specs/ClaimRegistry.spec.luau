return function()
	local module = game:GetService("ServerScriptService").Game:FindFirstChild("ClaimRegistry")
	assert(module, "ClaimRegistry is not implemented yet")
	local ClaimRegistry = require(module)
	local passed = 0
	local function test(name, callback)
		callback()
		passed += 1
		print("PASS: " .. name)
	end
	local function registry(capacity)
		return ClaimRegistry.new(capacity or 8, { sparta = true, britain = true })
	end

	test("conflicting civilization requests have exactly one winner", function()
		local claims = registry()
		assert(claims:claim(101, "sparta").ok)
		local rejected = claims:claim(102, "sparta")
		assert(not rejected.ok and rejected.reason == "unavailable")
		assert(claims:get(102) == nil)
		assert(claims:snapshot().sparta.ownerId == 101)
	end)

	test("different civilizations receive distinct plots", function()
		local claims = registry()
		local first = claims:claim(101, "sparta")
		local second = claims:claim(102, "britain")
		assert(first.ok and second.ok)
		assert(first.claim.plotId ~= second.claim.plotId)
	end)

	test("invalid identifiers leave all plots and civilizations free", function()
		local claims = registry()
		for _, value in { false, 123, {}, "unknown", "SPARTA", "" } do
			local result = claims:claim(101, value)
			assert(not result.ok and result.reason == "invalid")
		end
		assert(not claims:claim(101, nil).ok)
		assert(claims:get(101) == nil)
		assert(claims:claim(102, "sparta").claim.plotId == 1)
	end)

	test("same selection is idempotent and cannot allocate another plot", function()
		local claims = registry()
		local first = claims:claim(101, "sparta")
		local repeatRequest = claims:claim(101, "sparta")
		assert(repeatRequest.ok and repeatRequest.claim.plotId == first.claim.plotId)
		assert(claims:claim(102, "britain").claim.plotId == 2)
	end)

	test("owners cannot switch civilizations or lose their original claim", function()
		local claims = registry()
		claims:claim(101, "sparta")
		local result = claims:claim(101, "britain")
		assert(not result.ok and result.reason == "already_claimed")
		assert(claims:get(101).civilizationId == "sparta")
		assert(claims:snapshot().britain.ownerId == nil)
	end)

	test("capacity cannot be exceeded", function()
		local claims = registry(1)
		assert(claims:claim(101, "sparta").ok)
		local result = claims:claim(102, "britain")
		assert(not result.ok and result.reason == "full")
		assert(claims:get(102) == nil)
	end)

	test("departure releases civilization and reuses the available plot", function()
		local claims = registry()
		claims:claim(101, "sparta")
		local old = claims:release(101)
		assert(old.civilizationId == "sparta" and old.plotId == 1)
		assert(claims:get(101) == nil)
		assert(claims:claim(102, "sparta").claim.plotId == 1)
		assert(claims:release(999) == nil)
	end)

	test("returned snapshots and claims cannot mutate server ownership", function()
		local claims = registry()
		local result = claims:claim(101, "sparta")
		result.claim.plotId = 8
		local snapshot = claims:snapshot()
		snapshot.sparta.ownerId = 999
		snapshot.britain = nil
		local owned = claims:get(101)
		owned.civilizationId = "britain"
		assert(claims:get(101).plotId == 1)
		assert(claims:get(101).civilizationId == "sparta")
		assert(claims:snapshot().sparta.ownerId == 101)
		assert(claims:snapshot().britain ~= nil)
	end)

	return passed
end

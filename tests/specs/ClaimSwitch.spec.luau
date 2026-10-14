return function()
	local Registry=require(game.ServerScriptService.Game.ClaimRegistry)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function fixture()
		local registry=Registry.new(2,{sparta=true,britain=true,japan=true})
		assert(type(registry.switch)=="function","Atomic civilization switching is not implemented")
		return registry
	end
	test("unclaimed players can switch into an initial claim",function()
		local registry=fixture()
		local result=registry:switch(101,"sparta")
		assert(result.ok and result.claim.civilizationId=="sparta" and result.claim.plotId==1)
	end)
	test("switch atomically keeps the current plot and releases the former civilization",function()
		local registry=fixture()
		assert(registry:claim(101,"sparta").ok and registry:claim(202,"britain").ok)
		local result=registry:switch(101,"japan")
		assert(result.ok and result.claim.plotId==1 and registry:get(101).civilizationId=="japan")
		assert(registry:snapshot().sparta.ownerId==nil and registry:snapshot().japan.ownerId==101)
		assert(registry:snapshot().britain.ownerId==202)
		assert(registry:switch(101,"sparta").ok and registry:get(101).plotId==1)
	end)
	test("occupied or invalid switches preserve both owners and all plot reservations",function()
		local registry=fixture()
		assert(registry:claim(101,"sparta").ok and registry:claim(202,"britain").ok)
		assert(registry:switch(101,"britain").reason=="unavailable")
		for _,invalid in {"unknown",false,{},7} do assert(not registry:switch(101,invalid).ok) end
		assert(registry:get(101).civilizationId=="sparta" and registry:get(101).plotId==1)
		assert(registry:get(202).civilizationId=="britain" and registry:get(202).plotId==2)
		assert(registry:claim(303,"japan").reason=="full")
	end)
	test("same-civilization switches are idempotent copied claims",function()
		local registry=fixture()
		assert(registry:claim(101,"sparta").ok)
		local result=registry:switch(101,"sparta")
		assert(result.ok and result.claim.plotId==1)
		result.claim.civilizationId="japan"; result.claim.plotId=99
		assert(registry:get(101).civilizationId=="sparta" and registry:get(101).plotId==1)
	end)
	return count
end

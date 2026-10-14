return function()
	local Economy=require(game.ServerScriptService.Game.Economy)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function state(coins,level,weapon,armor,barracks)
		return {coins=coins,level=level,weaponLevel=weapon,armorLevel=armor,barracksLevel=barracks,revision=0}
	end
	test("opening a persisted civilization restores all four levels and copies its balance",function()
		local economy=Economy.new()
		local initial=state(437,4,3,2,4)
		local result=economy:open(101,initial)
		assert(result and result.coins==437 and result.level==4)
		assert(result.weaponLevel==3 and result.armorLevel==2 and result.barracksLevel==4)
		initial.coins=999; initial.weaponLevel=4; result.armorLevel=4
		assert(economy:get(101).coins==437 and economy:get(101).weaponLevel==3 and economy:get(101).armorLevel==2)
	end)
	test("opening an existing account cannot overwrite live progress with an imported snapshot",function()
		local economy=Economy.new()
		economy:open(101,state(15,2,1,1,1))
		assert(economy:earn(101).ok)
		economy:open(101,state(999,4,4,4,4))
		assert(economy:get(101).coins==16 and economy:get(101).level==2)
	end)
	test("malformed or over-cap imported states never create a fresh writable account",function()
		for _,invalid in {
			state(-1,1,1,1,1),state(1.5,1,1,1,1),state(0/0,1,1,1,1),state(math.huge,1,1,1,1),
			state(1000000001,1,1,1,1),state(0,5,1,1,1),state(0,2,3,1,1),state(0,2,1,3,1),
			state(0,2,1,1,3),{coins=0,level=1},false,"invalid",
		} do
			local economy=Economy.new()
			assert(economy:open(101,invalid)==nil,"Invalid import did not report failure")
			assert(economy:get(101)==nil,"Invalid persisted state became a default account")
			assert(not economy:earn(101).ok and not economy:rewardKill(101).ok)
		end
	end)
	test("loss of profile write authority freezes clicks purchases and final-hit credits",function()
		local writable=true
		local economy=Economy.new(function() return 10 end,function(id) assert(id==101); return writable end)
		economy:open(101,state(100,2,1,1,1))
		assert(economy:earn(101).ok)
		local before=economy:get(101)
		writable=false
		assert(economy:earn(101).reason=="profile_unavailable")
		assert(not economy:upgrade(101,1,"weapon").ok)
		assert(not economy:upgrade(101,1,"armor").ok)
		assert(not economy:upgrade(101,1,"barracks").ok)
		assert(not economy:upgrade(101,2).ok and not economy:rewardKill(101).ok)
		local after=economy:get(101)
		for key,value in before do assert(after[key]==value,"Frozen account changed "..key) end
		writable=true
		for _=1,19 do assert(economy:earn(101).ok,"Rejected frozen action consumed click budget") end
		assert(economy:earn(101).reason=="rate_limited")
		assert(economy:upgrade(101,1,"weapon").ok,"Rejected frozen purchase consumed its cooldown")
	end)
	test("revisions increase across civilization account replacement so old client states stay stale",function()
		local economy=Economy.new()
		economy:open(101,state(5,1,1,1,1))
		assert(economy:earn(101).ok)
		local previous=economy:get(101).revision
		economy:close(101)
		local restored=economy:open(101,state(40,4,4,4,4))
		assert(restored.revision>previous and restored.coins==40 and restored.barracksLevel==4)
		assert(economy:earn(101).ok and economy:get(101).revision>restored.revision)
	end)
	test("loaded data does not restore transient click buckets or purchase cooldowns",function()
		local economy=Economy.new(function() return 1 end)
		economy:open(101,state(100,2,1,1,1))
		for _=1,20 do assert(economy:earn(101).ok) end
		assert(not economy:earn(101).ok)
		assert(economy:upgrade(101,1,"weapon").ok)
		local saved=economy:get(101)
		economy:close(101); economy:open(101,saved)
		for _=1,20 do assert(economy:earn(101).ok) end
		assert(economy:upgrade(101,1,"armor").ok)
	end)
	test("same-session civilization replacement preserves exhausted click budget and purchase cooldown",function()
		local time=1
		local economy=Economy.new(function() return time end)
		assert(type(economy.replace)=="function","Civilization replacement is not implemented")
		economy:open(101,state(100,2,1,1,1))
		for _=1,20 do assert(economy:earn(101).ok) end
		local previous=economy:get(101).revision
		local other=economy:replace(101,state(100,2,1,1,1))
		assert(other and other.revision>previous)
		assert(economy:earn(101).reason=="rate_limited","Switch reset the click bucket")
		assert(economy:upgrade(101,1,"weapon").ok)
		local before=economy:get(101).revision
		local original=economy:replace(101,state(120,2,1,1,1))
		assert(original and original.revision>before and original.coins==120)
		assert(economy:earn(101).reason=="rate_limited","Switching back reset the click bucket")
		assert(economy:upgrade(101,1,"weapon").reason=="rate_limited","Switch reset a track purchase cooldown")
		time+=.5
		assert(economy:upgrade(101,1,"weapon").ok)
	end)
	test("invalid and unauthorized replacements preserve the existing account and revision",function()
		local writable=true
		local economy=Economy.new(nil,function() return writable end)
		assert(type(economy.replace)=="function","Civilization replacement is not implemented")
		economy:open(101,state(75,3,2,1,3))
		local before=economy:get(101)
		assert(economy:replace(101,state(0,1,4,1,1))==nil)
		writable=false
		assert(economy:replace(101,state(0,1,1,1,1))==nil)
		for field,value in before do assert(economy:get(101)[field]==value,"Rejected replacement changed "..field) end
	end)
	return count
end

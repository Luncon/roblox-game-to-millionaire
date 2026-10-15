return function()
	local Economy=require(game.ServerScriptService.Game.Economy)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function fixture()
		local time=0
		local economy=Economy.new(function() return time end)
		economy:open(101)
		local function advance() time+=1 end
		local function fund(amount)
			for _=1,amount do assert(economy:earn(101).ok); time+=.1 end
		end
		return economy,fund,advance
	end
	test("gear balance uses the agreed softer damage and health tiers",function()
		for _,level in {1,2,25,50} do assert(math.abs(Tracks.weapon[level].damage-(10+8*(level-1)/49))<.0001) end
		for _,level in {1,2,25,50} do assert(math.abs(Tracks.armor[level].health-(100+40*(level-1)/49))<.0001) end
	end)
	test("barracks tiers reduce each future delay by half a second and capacity stops growing at four",function()
		for level,delay in {15,14.5,14,13.5,13,12.5} do
			assert(Tracks.barracks[level].respawnDelay==delay)
			assert(Tracks.barracks[level].capacity==(if level>=4 then 2 else 1))
		end
	end)
	test("gear purchases enforce settlement gates before taking coins",function()
		for _,kind in {"weapon","armor"} do
			local economy,fund,advance=fixture()
			local field=kind.."Level"
			fund(500)
			for level=1,3 do
				local before=economy:get(101).coins
				assert(not economy:upgrade(101,level,kind).ok)
				assert(economy:get(101).coins==before and economy:get(101)[field]==level)
				assert(economy:upgrade(101,level).ok)
				advance()
				assert(economy:upgrade(101,level,kind).ok)
				advance()
			end
		end
	end)
	test("barracks upgrades cost exactly 30 75 150 and require settlements 2 3 4",function()
		local economy,fund,advance=fixture()
		assert(economy:get(101).barracksLevel==1)
		fund(600)
		for barracksLevel,cost in {30,75,150} do
			local before=economy:get(101).coins
			assert(not economy:upgrade(101,barracksLevel,"barracks").ok)
			assert(economy:get(101).coins==before and economy:get(101).barracksLevel==barracksLevel)
			assert(economy:upgrade(101,barracksLevel).ok)
			advance()
			before=economy:get(101).coins
			assert(economy:upgrade(101,barracksLevel,"barracks").ok)
			assert(economy:get(101).coins==before-cost)
			advance()
			assert(economy:upgrade(101,barracksLevel,"barracks").reason=="stale_level")
		end
		assert(economy:get(101).coins==240 and economy:get(101).barracksLevel==4)
		assert(economy:upgrade(101,4,"barracks").reason=="settlement_locked")
		assert(economy:get(101).coins==240)
	end)
	test("kill credits are fixed ten and do not refill or consume click tokens",function()
		local economy=fixture()
		assert(type(economy.rewardKill)=="function","Economy.rewardKill is not implemented")
		for _=1,20 do assert(economy:earn(101).ok) end
		assert(economy:earn(101).reason=="rate_limited")
		assert(economy:rewardKill(101).ok and economy:get(101).coins==30)
		assert(economy:earn(101).reason=="rate_limited")
		assert(not economy:rewardKill(999).ok)
	end)
	test("barracks state is copied and closed accounts cannot receive kill credits",function()
		local economy=fixture()
		local snapshot=economy:get(101)
		snapshot.barracksLevel=4
		assert(economy:get(101).barracksLevel==1)
		economy:close(101)
		assert(not economy:rewardKill(101).ok)
		economy:open(101)
		assert(economy:get(101).barracksLevel==1 and economy:get(101).coins==0)
	end)
	return count
end

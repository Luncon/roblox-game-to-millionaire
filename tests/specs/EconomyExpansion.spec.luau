return function()
	local Shared=game.ReplicatedStorage.Shared
	local Development=require(Shared.SettlementDevelopment)
	local Tracks=require(Shared.UpgradeTracks)
	local Economy=require(game.ServerScriptService.Game.Economy)
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local count=0
	local function test(name,callback) callback();count+=1;print("PASS: "..name) end
	local function state(level,extra)
		local value={coins=10000,level=level,weaponLevel=1,armorLevel=1,barracksLevel=4}
		for field,item in extra or {} do value[field]=item end
		return value
	end
	local function fixture(initial)
		local time,writable=0,true
		local economy=Economy.new(function() return time end,function() return writable end)
		assert(economy:open(101,initial))
		return economy,function(seconds) time+=seconds end,function(value) writable=value end
	end
	test("expanded buildings expose frozen tiers and independent storage capacity",function()
		assert(Development.buildings.farm.maxLevel==2,"Second farm tier is not implemented")
		for track,expected in {farm={{7,80},{12,180}},workers={{7,60},{12,140}},blacksmith={{13,150}},armorer={{13,150}},storehouse={{16,140}}} do
			local building=Development.buildings[track]
			assert(building and building.maxLevel==#expected and table.isfrozen(building.tiers))
			assert(building.unlock==expected[1][1] and building.cost==expected[1][2])
			for index,tier in building.tiers do
				assert(tier.unlock==expected[index][1] and tier.cost==expected[index][2] and table.isfrozen(tier))
			end
		end
		assert(Development.farmCapacity==60 and Development.storageCapacity({})==60)
		assert(Development.storageCapacity({storehouseLevel=1})==180)
		assert(Development.farmYield({farmLevel=2,workersLevel=2})==4 and Development.tickSeconds==5)
	end)
	test("second economic tiers enforce stage and matching farm before exact atomic charges",function()
		local economy,advance=fixture(state(11,{farmLevel=1,workersLevel=1}))
		local before=economy:get(101)
		assert(economy:upgrade(101,1,"farm").reason=="settlement_locked")
		assert(economy:get(101).coins==before.coins and economy:get(101).revision==before.revision)
		assert(economy:replace(101,state(12,{farmLevel=1,workersLevel=1})))
		assert(economy:upgrade(101,1,"workers").reason=="prerequisite")
		assert(economy:upgrade(101,1,"farm").ok and economy:get(101).coins==9820)
		assert(economy:upgrade(101,1,"workers").ok and economy:get(101).coins==9680)
		assert(economy:get(101).farmLevel==2 and economy:get(101).workersLevel==2)
		advance(1)
		assert(economy:upgrade(101,2,"farm").reason=="max_level" and economy:upgrade(101,2,"workers").reason=="max_level")
		assert(economy:get(101).coins==9680)
	end)
	test("craft buildings discount only their gear track using ceiling and retain all combat stats",function()
		local economy,advance=fixture(state(12))
		assert(economy:upgrade(101,0,"blacksmith").reason=="settlement_locked")
		assert(economy:upgrade(101,0,"armorer").reason=="settlement_locked")
		assert(economy:replace(101,state(50)))
		assert(economy:upgrade(101,0,"blacksmith").ok and economy:get(101).coins==9850)
		local preview=economy:get(101);preview.weaponLevel,preview.armorLevel=3,3
		assert(Development.offer(preview,"weapon").cost==20 and Development.offer(preview,"armor").cost==21,
			"Blacksmith discounted the wrong track or failed to round upward")
		assert(economy:upgrade(101,0,"armorer").ok and economy:get(101).coins==9700)
		for _,track in {"weapon","armor"} do
			for level=1,49 do
				local before=economy:get(101).coins
				local expected=math.ceil((15+3*(level-1))*.95)
				assert(Development.offer(economy:get(101),track).cost==expected)
				assert(economy:upgrade(101,level,track).ok and economy:get(101).coins==before-expected)
				advance(1)
			end
		end
		assert(Tracks.weapon[1].damage==10 and Tracks.weapon[50].damage==18)
		assert(Tracks.armor[1].health==100 and Tracks.armor[50].health==140)
		assert(economy:get(101).coins==1552,"Discounted full gear tracks must each cost 4074")
	end)
	test("farm and worker upgrades settle old yield while storehouse cannot bank capped time",function()
		local economy,advance=fixture(state(16,{farmLevel=1,workersLevel=1}))
		advance(12)
		assert(economy:upgrade(101,1,"farm").ok and economy:get(101).farmCoins==4)
		advance(4);assert(economy:farmStep(101).amount==0)
		advance(1);assert(economy:farmStep(101).amount==3)
		advance(7);assert(economy:upgrade(101,1,"workers").ok and economy:get(101).farmCoins==10)
		advance(5);assert(economy:farmStep(101).amount==4)
		advance(100);assert(economy:farmStep(101).state.farmCoins==60)
		advance(4);assert(economy:upgrade(101,0,"storehouse").ok and economy:get(101).farmCoins==60)
		advance(1);assert(economy:farmStep(101).amount==0,"Storage purchase banked time spent full")
		advance(4);assert(economy:farmStep(101).amount==4)
		advance(1000);assert(economy:farmStep(101).state.farmCoins==180)
		advance(4);assert(economy:collectFarm(101).amount==180)
		advance(1);assert(economy:farmStep(101).amount==0,"Expanded full reserve banked its partial interval")
		advance(4);assert(economy:farmStep(101).amount==4)
	end)
	test("new purchases and expanded reserve remain fenced by profile authority",function()
		local economy,advance,writable=fixture(state(16,{farmLevel=2,workersLevel=2}))
		local before=economy:get(101)
		writable(false);advance(100)
		for _,track in {"blacksmith","armorer","storehouse"} do assert(economy:upgrade(101,0,track).reason=="profile_unavailable") end
		assert(economy:farmStep(101).reason=="profile_unavailable" and economy:collectFarm(101).reason=="profile_unavailable")
		assert(economy:get(101).coins==before.coins and economy:get(101).revision==before.revision)
		writable(true);advance(4);assert(economy:farmStep(101).amount==0)
		advance(1);assert(economy:farmStep(101).amount==4)
	end)
	test("barracks five and six retain two slots and enforce settlements eight and fourteen",function()
		assert(#Tracks.barracks==6 and Tracks.barracks[4].nextCost==200 and Tracks.barracks[5].nextCost==300)
		for level=4,6 do assert(Tracks.barracks[level].capacity==2) end
		assert(Tracks.barracks[5].respawnDelay==13 and Tracks.barracks[6].respawnDelay==12.5 and Tracks.barracks[6].nextCost==nil)
		local economy,advance=fixture(state(7))
		assert(economy:upgrade(101,4,"barracks").reason=="settlement_locked")
		assert(economy:replace(101,state(8)))
		assert(economy:upgrade(101,4,"barracks").ok and economy:get(101).coins==9800)
		advance(1);assert(economy:upgrade(101,5,"barracks").reason=="settlement_locked")
		assert(economy:replace(101,state(14,{barracksLevel=5})))
		assert(economy:upgrade(101,5,"barracks").ok and economy:get(101).coins==9700)
		advance(1);assert(economy:upgrade(101,6,"barracks").reason=="max_level")
	end)
	test("profile expansion defaults only missing fields and validates economic tier prerequisites",function()
		local legacy=Data.copyState(state(50))
		assert(legacy and legacy.blacksmithLevel==0 and legacy.armorerLevel==0 and legacy.storehouseLevel==0)
		local valid=state(16,{barracksLevel=6,armyCampLevel=1,farmLevel=2,workersLevel=2,
			blacksmithLevel=1,armorerLevel=1,storehouseLevel=1,farmCoins=180,extraTroopClass="ranged"})
		assert(Data.copyState(valid))
		for _,change in {{blacksmithLevel=false},{armorerLevel="1"},{storehouseLevel=2},{farmCoins=181},
			{level=15},{level=11},{farmLevel=1},{farmLevel=0},{workersLevel=3},{barracksLevel=7},
			{level=13},{storehouseLevel=0}} do
			local bad=table.clone(valid);for field,value in change do bad[field]=value end
			assert(Data.copyState(bad)==nil,"Invalid expanded state accepted")
		end
		assert(Data.copyState(state(8,{barracksLevel=5})))
		assert(Data.copyState(state(7,{barracksLevel=5}))==nil and Data.copyState(state(13,{barracksLevel=6}))==nil)
		assert(Data.copyState(state(13,{blacksmithLevel=1,armorerLevel=1})))
		assert(Data.copyState(state(16,{storehouseLevel=1}))==nil,"Storehouse without a farm was accepted")
	end)
	test("all fifteen scalar fields survive independent civilization save and reload",function()
		local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
		local Service=require(game.ServerScriptService.Game.ProfileService)
		local first=Service.new(store,{clock=function() return 100 end,wait=function() end,sessionId="expansion-first"})
		assert(first:load(101).ok)
		local saved=state(16,{barracksLevel=6,armyCampLevel=1,farmLevel=2,workersLevel=2,trainingLevel=1,
			blacksmithLevel=1,armorerLevel=1,storehouseLevel=1,farmCoins=177,extraTroopClass="ranged"})
		assert(first:set(101,"sparta",saved) and first:set(101,"britain",state(10)))
		assert(first:release(101).ok)
		local second=Service.new(store,{clock=function() return 101 end,wait=function() end,sessionId="expansion-second"})
		assert(second:load(101).ok)
		local actual=second:get(101,"sparta");local fields=0
		for _,field in Development.persistentFields do fields+=1;assert(actual[field]==Data.copyState(saved)[field],"Save lost "..field) end
		assert(fields==15 and second:get(101,"britain").blacksmithLevel==0 and second:get(101,"britain").farmCoins==0)
		local economy=fixture(actual);assert(economy:get(101).farmCoins==177)
		assert(second:release(101).ok)
	end)
	return count
end

return function()
	local Shared=game.ReplicatedStorage.Shared
	local Skills=require(Shared.WeaponSkillConfig)
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local Economy=require(game.ServerScriptService.Game.Economy)
	local Development=require(Shared.SettlementDevelopment)
	local count=0
	local function test(name,fn) fn();count+=1;print("PASS: "..name) end
	local function state(level,skill)
		local value=Data.defaultState()
		value.level,value.weaponLevel,value.trainingLevel,value.coins,value.skillLevel=level,level,1,10000,skill or 0
		return value
	end
	test("all current melee variants and eligible ranged variants resolve to their weapon families",function()
		local melee=require(Shared.WarriorConfig).variants
		local ranged=require(Shared.RangedConfig).variants
		local total=0
		for _,variant in melee do assert(Skills.family(variant.weaponKind));total+=1 end
		assert(total==13)
		for _,id in {"sparta","rome"} do assert(Skills.family(ranged[id].weaponKind)=="spear") end
		assert(Skills.family(ranged.vikings.weaponKind)=="axe")
		for _,kind in {"bow","musket","crossbow","sling","unknown"} do assert(Skills.family(kind)==nil) end
		for _,kind in {"sabre","katana","rapier","khopesh","gladius","kilij","dao"} do assert(Skills.family(kind)=="sword") end
	end)
	test("exact five paid milestones preserve base damage and fixed cooldowns",function()
		local time=0
		local economy=Economy.new(function() return time end)
		assert(economy:open(101,state(50)))
		local sum=0
		for tier,price in {100,200,350,550,800} do
			local offer=Development.offer(economy:get(101),"skill")
			assert(offer.available and offer.current==tier-1 and offer.nextLevel==tier and offer.cost==price)
			assert(offer.requiredSettlement==tier*10)
			assert(economy:upgrade(101,tier-1,"skill").ok)
			sum+=price;time+=1
		end
		assert(sum==2000 and economy:get(101).coins==8000 and economy:get(101).skillLevel==5)
		assert(economy:upgrade(101,5,"skill").reason=="max_level")
		assert(Skills.families.spear.cooldown==8 and Skills.families.axe.cooldown==12 and Skills.families.sword.cooldown==9)
		assert(math.abs(Skills.tiers[5].spear*18-30.6)<.0001 and math.abs((Skills.tiers[5].sword+Skills.tiers[5].second)*18-32.4)<.0001)
	end)
	test("weapon thresholds training and insufficient funds prevent purchases without mutation",function()
		for _,level in {9,19,29,39,49} do
			local value=state(level,math.floor(level/10));value.level=50
			local economy=Economy.new();assert(economy:open(101,value))
			local before=economy:get(101)
			assert(not Development.offer(before,"skill").available)
			assert(economy:upgrade(101,before.skillLevel,"skill").reason=="prerequisite")
			assert(economy:get(101).coins==before.coins and economy:get(101).skillLevel==before.skillLevel)
		end
		local value=state(10);value.trainingLevel=0
		local economy=Economy.new();assert(economy:open(101,value))
		assert(economy:upgrade(101,0,"skill").reason=="prerequisite")
		value.trainingLevel,value.coins=1,99;assert(economy:replace(101,value))
		assert(economy:upgrade(101,0,"skill").reason=="insufficient_funds" and economy:get(101).skillLevel==0)
	end)
	test("workshops never discount skill prices and stale repeats cannot double-charge",function()
		local value=state(50);value.blacksmithLevel,value.armorerLevel=1,1
		local economy=Economy.new();assert(economy:open(101,value))
		assert(economy:upgrade(101,0,"skill").ok)
		assert(economy:get(101).coins==9900)
		assert(economy:upgrade(101,0,"skill").reason=="stale_level")
		assert(economy:upgrade(101,1,"skill").reason=="rate_limited")
		assert(economy:get(101).coins==9900 and economy:get(101).skillLevel==1)
	end)
	test("lost authority freezes skill purchases without losing saved tiers",function()
		local writable=false
		local economy=Economy.new(nil,function() return writable end)
		assert(economy:open(101,state(20,1)))
		assert(economy:upgrade(101,1,"skill").reason=="profile_unavailable")
		assert(economy:get(101).skillLevel==1 and economy:get(101).coins==10000)
	end)
	test("legacy defaults are missing-only and malformed skill data blocks loading",function()
		local legacy=state(50);legacy.skillLevel=nil
		assert(Data.copyState(legacy).skillLevel==0)
		for _,bad in {false,"1",-1,.5,6,math.huge,0/0} do
			local value=table.clone(legacy);value.skillLevel=bad
			assert(Data.copyState(value)==nil)
		end
		local value=state(9,1);assert(Data.copyState(value)==nil)
		value=state(50,1);value.trainingLevel=0;assert(Data.copyState(value)==nil)
	end)
	test("all sixteen fields round-trip independently across civilizations and economy snapshots",function()
		local sparta,britain=state(50,5),state(20,2)
		sparta.farmLevel,sparta.workersLevel,sparta.farmCoins,sparta.storehouseLevel=2,2,170,1
		sparta.blacksmithLevel,sparta.armorerLevel=1,1
		local profile=Data.decode({schemaVersion=1,civilizations={sparta=sparta,britain=britain}})
		assert(profile and profile.civilizations.sparta.skillLevel==5 and profile.civilizations.britain.skillLevel==2)
		local fields=0;for _ in profile.civilizations.sparta do fields+=1 end;assert(fields==16)
		local economy=Economy.new();assert(economy:open(101,profile.civilizations.sparta))
		for _,field in Development.persistentFields do assert(economy:get(101)[field]==sparta[field]) end
		assert(economy:replace(101,profile.civilizations.britain).skillLevel==2)
		assert(economy:replace(101,profile.civilizations.sparta).skillLevel==5)
	end)
	test("injected fake-store release and reacquisition preserve skill tiers and all original fields",function()
		local Store=require(game.ServerStorage.RuntimeTests.FakeProfileStore)
		local Profiles=require(game.ServerScriptService.Game.ProfileService)
		local store=Store.new()
		assert(store.isFakeProfileStore)
		local time=100
		local function options(id)
			return {clock=function()return time end,wait=function()end,sessionId=id,newToken=function()return id end}
		end
		local first=Profiles.new(store,options("skills-first"));assert(first:load(101).ok)
		assert(first:set(101,"sparta",state(50,5)))
		assert(first:set(101,"britain",state(20,2)))
		assert(first:release(101).ok);time+=5
		local second=Profiles.new(store,options("skills-second"));assert(second:load(101).ok)
		for _,entry in {{"sparta",50,5},{"britain",20,2}} do
			local expected=state(entry[2],entry[3]);local actual=second:get(101,entry[1])
			for _,field in Development.persistentFields do assert(actual[field]==expected[field],"Lost saved "..field)end
		end
		assert(second:release(101).ok)
	end)
	return count
end

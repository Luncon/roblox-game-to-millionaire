return function()
	local module=game.ServerScriptService.Game:FindFirstChild("ProfileData")
	assert(module,"Persistent profile validation is not implemented")
	local Data=require(module)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function state(coins,level,weapon,armor,barracks)
		return {coins=coins,level=level,weaponLevel=weapon,armorLevel=armor,barracksLevel=barracks}
	end
	test("new civilization defaults are independent zero-coin level-one states",function()
		local a,b=Data.defaultState(),Data.defaultState()
		assert(a.coins==0 and a.level==1 and a.weaponLevel==1 and a.armorLevel==1 and a.barracksLevel==1)
		a.coins=999; a.level=4
		assert(b.coins==0 and b.level==1)
	end)
	test("persistent state copies exclude runtime currency limits revisions and NPC identities",function()
		local original=state(1000000000,4,3,2,4)
		original.revision=99; original.tokens=20; original.plotId=8; original.troops={"old rig"}
		local value=Data.copyState(original)
		assert(value and value.coins==1000000000 and value.weaponLevel==3 and value.barracksLevel==4)
		assert(value.revision==nil and value.tokens==nil and value.plotId==nil and value.troops==nil)
		value.coins=0; assert(original.coins==1000000000)
	end)
	test("invalid currency missing fields and levels above settlement fail validation",function()
		for _,value in {false,"state",{},state(-1,1,1,1,1),state(1.5,1,1,1,1),state(0/0,1,1,1,1),
			state(math.huge,1,1,1,1),state(1000000001,1,1,1,1),state(0,0,1,1,1),state(0,51,1,1,1),
			state(0,2,3,1,1),state(0,2,1,3,1),state(0,2,1,1,3),state(0,4,2.5,1,1)} do
			assert(Data.copyState(value)==nil,"Malformed persisted state was accepted")
		end
	end)
	test("valid profiles copy every civilization and lease without sharing stored tables",function()
		local raw={schemaVersion=1,civilizations={},session={token="owner-token",expiresAt=200},savedAt=100}
		for index,civ in require(game.ReplicatedStorage.Shared.Civilizations) do
			raw.civilizations[civ.id]=state(index,4,4,3,2)
		end
		local decoded=Data.decode(raw)
		assert(decoded and decoded.schemaVersion==1 and decoded.savedAt==100 and decoded.session.token=="owner-token")
		for index,civ in require(game.ReplicatedStorage.Shared.Civilizations) do assert(decoded.civilizations[civ.id].coins==index) end
		decoded.civilizations.sparta.coins=999; decoded.session.token="changed"
		assert(raw.civilizations.sparta.coins==1 and raw.session.token=="owner-token")
	end)
	test("missing malformed future and unknown-civilization records fail without repair",function()
		assert(Data.decode(nil)==nil,"A failed or missing read is not a decoded profile")
		for _,raw in {false,{}, {schemaVersion=2,civilizations={}}, {schemaVersion=1,civilizations={unknown=Data.defaultState()}},
			{schemaVersion=1,civilizations={sparta=state(0,1,4,1,1)}},
			{schemaVersion=1,civilizations={},session={token="x",expiresAt=math.huge}},
			{schemaVersion=1,civilizations={},session={expiresAt=200}}} do
			assert(Data.decode(raw)==nil,"An unsafe profile was accepted")
		end
	end)
	test("legacy records gain zero-building defaults without losing high-level progress",function()
		for _,level in {1,9,10,50} do
			local original=state(731,level,level,level,math.min(4,level))
			local copied=Data.copyState(original)
			assert(copied and copied.coins==731 and copied.level==level and copied.weaponLevel==level and copied.armorLevel==level)
			for _,field in {"trainingLevel","farmLevel","workersLevel","armyCampLevel","farmCoins"} do assert(copied[field]==0,"Legacy field did not receive its safe default: "..field) end
			assert(copied.extraTroopClass=="warrior" and original.trainingLevel==nil,"Legacy decoding mutated the supplied profile")
		end
	end)
	test("eleven-field profiles retain their original values and default only the three expansion purchases",function()
		local original=state(731,50,25,19,4)
		original.trainingLevel=1;original.farmLevel=1;original.workersLevel=1;original.armyCampLevel=1
		original.farmCoins=59;original.extraTroopClass="ranged"
		local copied=Data.copyState(original)
		assert(copied)
		for field,value in original do assert(copied[field]==value,"Expansion changed a legacy scalar: "..field) end
		for _,field in {"blacksmithLevel","armorerLevel","storehouseLevel"} do
			assert(copied[field]==0 and original[field]==nil,"Expansion must default missing purchases without mutating input: "..field)
		end
	end)
	test("expanded saves validate each economic stage reserve capacity and barracks tier independently",function()
		local function expanded(level,changes)
			local value=state(900,level,1,1,4)
			for field,item in changes do value[field]=item end
			return value
		end
		for _,value in {expanded(12,{farmLevel=2,workersLevel=1}),expanded(12,{farmLevel=2,workersLevel=2}),
			expanded(8,{barracksLevel=5}),expanded(14,{barracksLevel=6,armyCampLevel=1}),
			expanded(13,{blacksmithLevel=1,armorerLevel=1}),expanded(16,{farmLevel=1,storehouseLevel=1,farmCoins=180}),
			expanded(7,{farmLevel=1,farmCoins=60})} do assert(Data.copyState(value),"Valid expanded progression was rejected") end
		for _,value in {expanded(11,{farmLevel=2}),expanded(12,{farmLevel=1,workersLevel=2}),
			expanded(7,{barracksLevel=5}),expanded(13,{barracksLevel=6}),expanded(50,{barracksLevel=7}),
			expanded(12,{blacksmithLevel=1}),expanded(12,{armorerLevel=1}),expanded(15,{farmLevel=1,storehouseLevel=1}),
			expanded(16,{storehouseLevel=1}),expanded(16,{farmLevel=1,farmCoins=61}),
			expanded(16,{farmLevel=2,workersLevel=2,storehouseLevel=1,farmCoins=181}),
			expanded(50,{blacksmithLevel=false}),expanded(50,{armorerLevel=.5}),expanded(50,{storehouseLevel=2}),
			expanded(50,{farmLevel=3}),expanded(50,{farmLevel=2,workersLevel=3})} do
			assert(Data.copyState(value)==nil,"Malformed expansion state was accepted")
			assert(Data.decode({schemaVersion=1,civilizations={sparta=value}})==nil)
		end
	end)
	test("malformed supplied development fields reject instead of silently receiving defaults",function()
		local valid=state(500,10,4,4,4)
		valid.trainingLevel=1;valid.farmLevel=1;valid.workersLevel=1;valid.armyCampLevel=1;valid.farmCoins=60;valid.extraTroopClass="ranged"
		for _,change in {{trainingLevel=-1},{trainingLevel=2},{trainingLevel=.5},{farmLevel=false},{workersLevel="1"},
			{armyCampLevel=math.huge},{farmCoins=-1},{farmCoins=61},{farmCoins=.5},{farmCoins=0/0},
			{extraTroopClass="melee"},{extraTroopClass=false},{level=4},{farmLevel=0},{barracksLevel=3}} do
			local malformed=table.clone(valid)
			for field,value in change do malformed[field]=value end
			assert(Data.copyState(malformed)==nil,"Invalid explicit development state was repaired")
			assert(Data.decode({schemaVersion=1,civilizations={sparta=malformed}})==nil,"Malformed development state entered a stored profile")
		end
	end)
	test("all sixteen civilization fields survive fake-store release reload without live clocks or commands",function()
		local Fake=require(game.ServerStorage.RuntimeTests.FakeProfileStore)
		local Service=require(game.ServerScriptService.Game.ProfileService)
		local store=Fake.new()
		local now=100
		local first=Service.new(store,{clock=function() return now end,wait=function() end,sessionId="development-save"})
		assert(first:load(101).ok)
		local expected={}
		for index,civ in require(game.ReplicatedStorage.Shared.Civilizations) do
			local value=state(index*10,16,4,4,6)
			value.trainingLevel=1;value.farmLevel=2;value.workersLevel=2;value.armyCampLevel=1
			value.blacksmithLevel=1;value.armorerLevel=1;value.storehouseLevel=1
			value.farmCoins=160+index;value.extraTroopClass=if index%2==0 then "ranged" else "warrior"
			value.farmUpdatedAt=999;value.order="hold";value.revision=900
			assert(first:set(101,civ.id,value))
			expected[civ.id]=Data.copyState(value)
		end
		assert(first:release(101).ok)
		now+=10
		local second=Service.new(store,{clock=function() return now end,wait=function() end,sessionId="development-reload"})
		assert(second:load(101).ok)
		for id,value in expected do
			local restored=second:get(101,id)
			local scalarCount=0;for _ in restored do scalarCount+=1 end
			assert(scalarCount==16,"Saved expansion profile omitted a field or retained runtime data")
			for field,number in value do assert(restored[field]==number,"Development save lost "..id.." / "..field) end
			assert(restored.farmUpdatedAt==nil and restored.order==nil and restored.revision==nil,"Transient farm/army state persisted")
		end
		assert(second:release(101).ok)
	end)
	return count
end

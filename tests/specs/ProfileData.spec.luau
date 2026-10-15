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
	return count
end

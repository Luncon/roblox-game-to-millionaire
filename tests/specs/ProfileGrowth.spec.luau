return function()
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function state(level,weapon,armor,barracks) return {coins=417,level=level,weaponLevel=weapon,armorLevel=armor,barracksLevel=barracks} end
	test("existing version-one level-four saves retain every numeric level and coin",function()
		local raw={schemaVersion=1,civilizations={sparta=state(4,4,3,4)},savedAt=100}
		local value=Data.decode(raw)
		assert(value and value.schemaVersion==1 and value.civilizations.sparta.coins==417)
		for field,number in raw.civilizations.sparta do assert(value.civilizations.sparta[field]==number) end
	end)
	test("version-one profiles accept level fifty settlement and gear with four barracks levels",function()
		local value=Data.decode({schemaVersion=1,civilizations={sparta=state(50,50,50,4),japan=state(25,24,20,3)}})
		assert(value,"Level-fifty saved profiles are rejected")
		assert(value.civilizations.sparta.level==50 and value.civilizations.sparta.weaponLevel==50 and value.civilizations.sparta.armorLevel==50)
		assert(value.civilizations.sparta.barracksLevel==4 and value.civilizations.japan.level==25)
	end)
	test("each saved field enforces its own cap and the settlement relationship",function()
		for _,invalid in {state(51,50,50,4),state(50,51,50,4),state(50,50,51,4),state(50,50,50,5),
			state(49,50,49,4),state(49,49,50,4),state(2,2,2,3),state(50,49.5,50,4)} do
			assert(Data.copyState(invalid)==nil,"Invalid independent growth cap was accepted")
		end
	end)
	test("level fifty and intermediate accounts survive save release and a new profile session",function()
		local Service=require(game.ServerScriptService.Game.ProfileService)
		local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
		local options={clock=function() return 100 end,wait=function() end,sessionId="growth-first"}
		local first=Service.new(store,options)
		assert(first:load(101).ok)
		assert(first:set(101,"sparta",state(50,50,50,4)))
		assert(first:set(101,"ming",state(25,24,20,3)))
		assert(first:save(101).ok and first:release(101).ok)
		local saved=store:read("User_101")
		assert(saved.schemaVersion==1 and saved.session==nil)
		options.sessionId="growth-second"
		local second=Service.new(store,options)
		assert(second:load(101).ok)
		for civ,expected in {sparta=state(50,50,50,4),ming=state(25,24,20,3)} do
			local actual=second:get(101,civ)
			for field,value in expected do assert(actual[field]==value,"Fresh session changed "..civ.." "..field) end
		end
		assert(second:get(101,"japan").level==1 and second:get(101,"japan").coins==0)
		assert(second:release(101).ok)
	end)
	return count
end

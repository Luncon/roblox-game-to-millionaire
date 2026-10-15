return function()
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local function near(actual,expected) assert(math.abs(actual-expected)<.0001,tostring(actual).." ~= "..expected) end
	test("settlement weapons and armor have fifty contiguous levels while barracks remains four",function()
		assert(#Tracks.settlement==50 and #Tracks.weapon==50 and #Tracks.armor==50,"Gradual fifty-level tracks are missing")
		assert(#Tracks.barracks==4)
		for level=1,50 do
			assert(Tracks.settlement[level] and Tracks.weapon[level] and Tracks.armor[level])
			near(Tracks.settlement[level].size,60+4*(level-1))
		end
		assert(Tracks.settlement[50].size==256)
	end)
	test("all fifty gear levels follow independent bounded linear damage and health curves",function()
		for level=1,50 do
			near(Tracks.weapon[level].damage,10+8*(level-1)/49)
			near(Tracks.armor[level].health,100+40*(level-1)/49)
			if level>1 then
				near(Tracks.weapon[level].damage-Tracks.weapon[level-1].damage,8/49)
				near(Tracks.armor[level].health-Tracks.armor[level-1].health,40/49)
			end
		end
		near(Tracks.weapon[50].damage,18); near(Tracks.armor[50].health,140)
	end)
	test("fifty-level prices and settlement gates remain linear finite and stop at the cap",function()
		local settlementTotal,gearTotal=0,0
		for level=1,49 do
			assert(Tracks.settlement[level].nextCost==25+10*(level-1))
			for _,kind in {"weapon","armor"} do
				assert(Tracks[kind][level].nextCost==15+3*(level-1))
				assert(Tracks[kind][level].requiredSettlement==level+1)
			end
			settlementTotal+=Tracks.settlement[level].nextCost
			gearTotal+=Tracks.weapon[level].nextCost
		end
		assert(settlementTotal==12985 and gearTotal==4263)
		for _,kind in {"settlement","weapon","armor"} do assert(Tracks[kind][50].nextCost==nil and Tracks[kind][51]==nil) end
	end)
	test("maximum-versus-starter stationary melee advantage remains bounded",function()
		assert(math.ceil(Tracks.armor[1].health/Tracks.weapon[50].damage)==6)
		assert(math.ceil(Tracks.armor[50].health/Tracks.weapon[1].damage)==14)
		assert(math.ceil(Tracks.armor[50].health/Tracks.weapon[50].damage)==8)
	end)
	return count
end

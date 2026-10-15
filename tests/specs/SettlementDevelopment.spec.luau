return function()
	local module=game.ReplicatedStorage.Shared:FindFirstChild("SettlementDevelopment")
	assert(module,"Settlement development policy is not implemented")
	local Policy=require(module)
	local count=0
	local function test(name,callback) callback();count+=1;print("PASS: "..name) end
	local function state(level)
		return {coins=0,level=level,weaponLevel=1,armorLevel=1,barracksLevel=1,
			trainingLevel=0,farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior"}
	end
	test("canonical fields and building tuning are immutable and complete",function()
		local expected={training={"trainingLevel",5,50,"Training Yard"},farm={"farmLevel",7,80,"Farm"},
			workers={"workersLevel",7,60,"Worker Camp"},armyCamp={"armyCampLevel",10,120,"Army Camp"},
			blacksmith={"blacksmithLevel",13,150,"Blacksmith"},armorer={"armorerLevel",13,150,"Armorer"},storehouse={"storehouseLevel",16,140,"Storehouse"}}
		local fields={};for _,field in Policy.persistentFields do assert(not fields[field]);fields[field]=true end
		for _,field in {"coins","level","weaponLevel","armorLevel","barracksLevel","trainingLevel","farmLevel","workersLevel","armyCampLevel","farmCoins","extraTroopClass","blacksmithLevel","armorerLevel","storehouseLevel"} do assert(fields[field]) end
		for id,values in expected do
			local building=Policy.buildings[id]
			assert(Policy.fields[id]==values[1] and building.field==values[1] and building.unlock==values[2] and building.cost==values[3] and building.title==values[4])
			assert(table.isfrozen(building))
		end
		assert(table.isfrozen(Policy.fields) and table.isfrozen(Policy.buildings) and table.isfrozen(Policy.persistentFields))
	end)
	test("building offers expose stage locks separately from funds",function()
		for _,definition in {{"training",5,50},{"farm",7,80},{"workers",7,60},{"armyCamp",10,120}} do
			local value=state(definition[2]-1)
			if definition[1]=="workers" then value.farmLevel=1 end
			if definition[1]=="armyCamp" then value.barracksLevel=4 end
			local locked=Policy.offer(value,definition[1])
			assert(locked.current==0 and locked.nextLevel==1 and locked.cost==definition[3] and not locked.available)
			value.level=definition[2]
			local ready=Policy.offer(value,definition[1]);assert(ready.available and ready.requiredSettlement==definition[2] and #ready.missing==0)
			value.level=16
			value[Policy.fields[definition[1]]]=Policy.buildings[definition[1]].maxLevel
			if definition[1]=="workers" then value.farmLevel=2 end
			local complete=Policy.offer(value,definition[1]);assert(not complete.available and complete.cost==nil and complete.nextLevel==nil)
		end
	end)
	test("worker and army camps require their actual dependent buildings",function()
		local value=state(10)
		assert(Policy.offer(value,"workers").missing[1]=="Farm I")
		assert(Policy.offer(value,"armyCamp").missing[1]=="Barracks IV")
		value.farmLevel=1;value.barracksLevel=4
		assert(Policy.offer(value,"workers").available and Policy.offer(value,"armyCamp").available)
	end)
	test("settlement nine identifies all checkpoint buildings and removes each satisfied requirement",function()
		local value=state(9)
		local offer=Policy.offer(value,"settlement")
		assert(offer.cost==105 and offer.nextLevel==10 and not offer.available and #offer.missing==4)
		for _,field in {"barracksLevel","trainingLevel","farmLevel","workersLevel"} do
			value[field]=if field=="barracksLevel" then 4 else 1
		end
		assert(Policy.offer(value,"settlement").available and #Policy.offer(value,"settlement").missing==0)
	end)
	test("legacy later settlements remain valid offers without retroactive checkpoint locks",function()
		for _,level in {8,10,25,49} do assert(Policy.offer(state(level),"settlement").available) end
		local final=Policy.offer(state(50),"settlement")
		assert(not final.available and final.cost==nil and final.nextLevel==nil)
		assert(Policy.offer(state(1),"unknown")==nil)
	end)
	test("legacy gear and barracks retain prices and settlement caps",function()
		local value=state(1)
		assert(Policy.offer(value,"weapon").cost==15 and not Policy.offer(value,"weapon").available)
		value.level=4
		assert(Policy.offer(value,"weapon").available and Policy.offer(value,"armor").available)
		assert(Policy.offer(value,"barracks").cost==30)
		value.barracksLevel=3;assert(Policy.offer(value,"barracks").cost==150)
	end)
	test("farm yield and army capacity use owned buildings without adding offline or stat bonuses",function()
		local value=state(10)
		assert(Policy.farmCapacity==60 and Policy.tickSeconds==5 and Policy.farmYield(value)==0 and Policy.armyCapacity(value)==1)
		value.farmLevel=1;assert(Policy.farmYield(value)==1)
		value.workersLevel=1;assert(Policy.farmYield(value)==2)
		value.barracksLevel=4;assert(Policy.armyCapacity(value)==2)
		value.armyCampLevel=1;assert(Policy.armyCapacity(value)==3)
	end)
	return count
end

-- One genuine client, native floor prompts and real timers. Trusted profile
-- preconditions are confined to the injected in-memory solo test store.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and game:GetAttribute("SoloVerificationEnabled"))
	assert(context and context.store and context.store.isFakeProfileStore,"Expansion tests must never open player storage")
	assert(player.Parent==game:GetService("Players") and type(round)=="function")
	local service=context.service;local uid=player.UserId
	assert(service and service.profiles:isWritable(uid))
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local fields=require(game.ReplicatedStorage.Shared.SettlementDevelopment).persistentFields
	assert(#fields==15)
	local cases,evidence=0,{}
	local function waitFor(predicate,description,seconds)
		local deadline=os.clock()+(seconds or 15)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function current() return service.economy:get(uid) end
	local function army() return service.army:get(uid) end
	local function native(options,timeout)
		local result=round("developmentInput",options,timeout or 180)
		assert(result.ok);return result
	end
	local function choose(id)
		local result=round("civilizationInput",{action="choose",civilization=id},30)
		assert(result.ok and result.currentCiv==id);return result
	end
	local function pad(action) return native({kind="pad",action=action}) end
	local function equalState(actual,expected,description)
		for _,field in fields do assert(actual[field]==expected[field],description.." changed "..field) end
	end
	if not service.registry:get(uid) then choose("sparta") end
	local originalCiv=service.registry:get(uid).civilizationId
	local original=Data.copyState(current())
	local fixtureCiv=if originalCiv=="rome" then "egypt" else "rome"
	local originalFixture=service.profiles:get(uid,fixtureCiv)
	local initial={coins=10000,level=13,weaponLevel=10,armorLevel=10,barracksLevel=4,
		trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,farmCoins=0,extraTroopClass="warrior",
		blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
	local ok,result=pcall(function()
		assert(service.profiles:set(uid,fixtureCiv,initial));choose(fixtureCiv)
		test("native economic tier purchases settle at old yield and produce at the new five-second rate",function()
			local reserve=current().farmCoins
			waitFor(function() return current().farmCoins>=reserve+2 end,"Farm I and Worker I real production",7)
			local farm=pad("farm")
			assert(farm.event.state.farmLevel==2 and farm.event.state.coins==9820)
			local oldFarmDelta=farm.event.state.farmCoins-farm.before.reserve
			assert(oldFarmDelta>=0 and oldFarmDelta%2==0,"Farm II retroactively used its new yield during purchase")
			reserve=current().farmCoins
			waitFor(function() return current().farmCoins>=reserve+3 end,"Farm II and Worker I real production",7)
			local workers=pad("workers")
			assert(workers.event.state.workersLevel==2 and workers.event.state.coins==9680,
				"Worker II exact ledger failed: "..game:GetService("HttpService"):JSONEncode(workers))
			local oldWorkerDelta=workers.event.state.farmCoins-workers.before.reserve
			assert(oldWorkerDelta>=0 and oldWorkerDelta%3==0,"Worker II retroactively used its new yield during purchase")
			reserve=current().farmCoins
			waitFor(function() return current().farmCoins>=reserve+4 end,"Farm II and Worker II real production",7)
			assert(current().coins==9680)
			evidence.yields={2,3,4}
		end)
		test("native workshop purchases charge independent rounded gear discounts without changing combat curves",function()
			pad("blacksmith");assert(current().coins==9530 and current().blacksmithLevel==1)
			pad("armorer");assert(current().coins==9380 and current().armorerLevel==1)
			local weaponInput=pad("weapon4")
			assert(string.match(weaponInput.before.label,"\n40 COINS$") and weaponInput.before.prompt=="Buy · 40 Coins","Weapon pad displayed a different price from its native purchase")
			local weapon=weaponInput.event
			assert(weapon.state.weaponLevel==11 and weapon.state.armorLevel==10 and weapon.state.coins==9340)
			local armorInput=pad("armor4")
			assert(string.match(armorInput.before.label,"\n40 COINS$") and armorInput.before.prompt=="Buy · 40 Coins","Armor pad displayed a different price from its native purchase")
			local armor=armorInput.event
			assert(armor.state.armorLevel==11 and armor.state.coins==9300)
			local tool=player.Character:FindFirstChildOfClass("Tool")
			assert(tool and math.abs(tool:GetAttribute("Damage")-(10+8*10/49))<.002)
			assert(math.abs(player.Character.Humanoid.MaxHealth-(100+40*10/49))<.002)
			for _,slot in army().slots do
				assert(slot.rig and math.abs(slot.rig:GetAttribute("WarriorDamage")-(10+8*10/49)*(if slot.kind=="ranged" then .8 else 1))<.002)
			end
			evidence.gearPrices={base=42,weapon=40,armor=40}
		end)
		test("native storage expansion starts above a full sixty only after a new active interval and collects exact reserve",function()
			choose(originalCiv)
			local full=service.profiles:get(uid,fixtureCiv);full.level=16;full.farmCoins=60
			assert(service.profiles:set(uid,fixtureCiv,full));choose(fixtureCiv)
			task.wait(5.3);assert(current().farmCoins==60,"Unowned storage exceeded the base capacity")
			local storage=pad("storehouse").event
			assert(storage.state.storehouseLevel==1 and storage.state.coins==9160 and storage.state.farmCoins==60,
				"Storage purchase credited time previously spent at full capacity")
			local began=os.clock()
			waitFor(function() return current().farmCoins>60 end,"real newly expanded reserve production",7)
			assert(os.clock()-began>=4.5 and current().farmCoins==64,"Expanded storage did not start a fresh five-second interval")
			evidence.storageGrowthSeconds=os.clock()-began
			local before=current().coins
			local collected=pad("collectFarm").event
			assert(collected.amount>=64 and collected.state.farmCoins==0 and current().coins==before+collected.amount)
			evidence.collected=collected.amount
		end)
		test("Barracks VI preserves a pending thirteen-second death and applies twelve-point-five only to the next death",function()
			local beforeCoins=current().coins
			pad("barracks5")
			assert(current().barracksLevel==5 and current().coins==beforeCoins-200)
			local before=army();local camp=before.slots.camp.rig
			local death=workspace:GetServerTimeNow();camp.Humanoid.Health=0
			waitFor(function() return army().slots.camp.respawnAt>0 end,"Barracks V death deadline")
			local deadline=army().slots.camp.respawnAt
			assert(math.abs(deadline-death-13)<.3)
			pad("barracks6")
			assert(current().barracksLevel==6 and current().coins==beforeCoins-500)
			assert(army().slots.camp.respawnAt==deadline and not army().slots.camp.rig,"Barracks purchase reset or bypassed a pending timer")
			waitFor(function() return army().slots.camp.rig~=nil end,"unchanged real thirteen-second replacement",15)
			assert(workspace:GetServerTimeNow()>=deadline)
			local replacement=army().slots.camp.rig
			assert(replacement~=camp and army().slots.warrior.rig==before.slots.warrior.rig and army().slots.ranged.rig==before.slots.ranged.rig)
			death=workspace:GetServerTimeNow();replacement.Humanoid.Health=0
			waitFor(function() return army().slots.camp.respawnAt>0 end,"Barracks VI new death deadline")
			deadline=army().slots.camp.respawnAt
			assert(math.abs(deadline-death-12.5)<.3)
			waitFor(function() return army().slots.camp.rig~=nil end,"real twelve-point-five-second replacement",14)
			assert(workspace:GetServerTimeNow()>=deadline and army().slots.camp.rig~=replacement)
			assert(player:GetAttribute("TroopCapacity")==3 and player:GetAttribute("ArmyCount")==3,"Speed upgrades changed slot capacity")
			evidence.respawnDelays={13,12.5}
		end)
		test("all fifteen fields save and restore independently without inactive farm income",function()
			choose(originalCiv)
			local saved=service.profiles:get(uid,fixtureCiv)
			assert(service.profiles:save(uid).ok)
			local stored=context.store:read("User_"..uid).civilizations[fixtureCiv]
			equalState(stored,saved,"Fake backend save")
			task.wait(5.3);equalState(service.profiles:get(uid,fixtureCiv),saved,"Inactive civilization")
			choose(fixtureCiv);equalState(current(),saved,"Restored civilization")
			evidence.savedFields=#fields
		end)
		return {ok=true,cases=cases,evidence=evidence,message="One real client: native economic tiers, workshop discounts, storage, fifteen-field saves and real barracks timers against fake profiles"}
	end)
	local cleanupOk,cleanupError=pcall(function()
		if service.registry:get(uid).civilizationId~=originalCiv then assert(service.select(player,originalCiv,true).ok) end
		assert(service.profiles:set(uid,fixtureCiv,originalFixture))
		-- The original may have an active farm; restoring its trusted snapshot is
		-- explicit test cleanup, not a production mutation bypass.
		assert(service.economy:replace(uid,original))
		assert(service.profiles:set(uid,originalCiv,original))
		equalState(current(),original,"Original active civilization cleanup")
	end)
	assert(cleanupOk,cleanupError);assert(ok,result);return result
end

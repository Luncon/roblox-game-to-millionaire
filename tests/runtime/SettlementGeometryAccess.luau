-- Genuine client inputs against fake profiles; no production events are forged.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and game:GetAttribute("SoloVerificationEnabled"))
	assert(context.store.isFakeProfileStore and player.Parent==game.Players and type(round)=="function")
	local service,uid=context.service,player.UserId
	assert(service and service.profiles:isWritable(uid))
	local Data=require(game.ServerScriptService.Game.ProfileData)
	local Development=require(game.ReplicatedStorage.Shared.SettlementDevelopment)
	local fields=Development.persistentFields
	assert(#fields==14)
	local cases,evidence=0,{purchases={}}
	local function stage(name)game:SetAttribute("SettlementGeometryAccessPhase",name)end
	local function choose(id)
		local result=round("civilizationInput",{action="choose",civilization=id},30)
		assert(result.ok and result.currentCiv==id,"Native civilization selection failed")
		return result
	end
	local function waitFor(predicate,label)
		local deadline=os.clock()+15
		repeat if predicate()then return end;task.wait(.05)until os.clock()>deadline
		error("Timed out: "..label)
	end
	local function current()return service.economy:get(uid)end
	local function equalState(actual,expected,label,allowReserveGrowth)
		for _,field in fields do
			if not (allowReserveGrowth and field=="farmCoins")then
				assert(actual[field]==expected[field],label.." changed "..field)
			end
		end
		if allowReserveGrowth then
			assert(actual.farmCoins>=expected.farmCoins and actual.farmCoins<=Development.storageCapacity(actual),
				label.." corrupted independently produced farm reserve")
		end
	end
	if not service.registry:get(uid)then choose("sparta")end
	local originalCiv=service.registry:get(uid).civilizationId
	local original=assert(Data.copyState(current()))
	local advancedCiv="britain"
	local economicCiv=if originalCiv=="rome" then "sparta" else "rome"
	local saved={[advancedCiv]=service.profiles:get(uid,advancedCiv),[economicCiv]=service.profiles:get(uid,economicCiv)}
	local anchored={}
	local function restore()
		-- Leave the original before restoring its cached profile so select() cannot
		-- return early or capture a fixture state over the restored snapshot.
		local claim=service.registry:get(uid)
		if claim and claim.civilizationId==originalCiv then assert(service.select(player,economicCiv,true).ok)end
		assert(service.profiles:set(uid,originalCiv,original))
		assert(service.select(player,originalCiv,true).ok)
		for id,state in saved do if id~=originalCiv then assert(service.profiles:set(uid,id,state))end end
		for rig,wasAnchored in anchored do
			if rig.Parent and rig:FindFirstChild("HumanoidRootPart")then rig.HumanoidRootPart.Anchored=wasAnchored end
		end
		table.clear(anchored)
		equalState(current(),original,"Original civilization cleanup",false)
	end
	local ok,result=pcall(function()
		stage("Native advanced gear and settlement pads")
		if service.registry:get(uid).civilizationId==advancedCiv then choose(economicCiv)end
		local advanced={coins=1000,level=5,weaponLevel=3,armorLevel=3,barracksLevel=4,
			trainingLevel=0,farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior",
			blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
		assert(service.profiles:set(uid,advancedCiv,advanced));choose(advancedCiv)
		waitFor(function()
			local owner=service.army:get(uid)
			return owner and owner.slots.warrior.rig and owner.slots.ranged.rig
		end,"advanced-pad fixture troops")
		-- Training is deliberately absent in this fixture. Isolate the exact input
		-- ledger from incidental neutral kills without claiming any troop motion.
		for _,slot in service.army:get(uid).slots do
			anchored[slot.rig]=slot.rig.HumanoidRootPart.Anchored
			slot.rig.HumanoidRootPart.Anchored=true
			service.encounters:cancel(slot.rig)
		end
		evidence.advancedPads=round("advancedPads",{},180)
		assert(evidence.advancedPads.ok and evidence.advancedPads.cases==6)
		local expected=table.clone(advanced)
		expected.coins,expected.level,expected.weaponLevel,expected.armorLevel=743,7,6,5
		equalState(current(),expected,"Native advanced-pad ledger",false)
		cases+=6

		stage("Native workshop and storage pads")
		local economic={coins=1000,level=16,weaponLevel=3,armorLevel=3,barracksLevel=4,
			trainingLevel=1,farmLevel=2,workersLevel=2,armyCampLevel=1,farmCoins=0,extraTroopClass="warrior",
			blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
		assert(service.profiles:set(uid,economicCiv,economic));choose(economicCiv)
		assert(round("developmentInput",{kind="command",button="Hold"},30).ok)
		assert(service.army:get(uid).order=="hold")
		for _,purchase in {
			{action="blacksmith",field="blacksmithLevel",cost=150},
			{action="armorer",field="armorerLevel",cost=150},
			{action="storehouse",field="storehouseLevel",cost=140},
		}do
			stage("Native "..purchase.action.." purchase")
			local before=assert(Data.copyState(current()))
			local input=round("developmentInput",{kind="pad",action=purchase.action},180)
			assert(input.ok and input.event and input.event.ok,"Native purchase did not succeed")
			local after=table.clone(before)
			after.coins,after[purchase.field]=before.coins-purchase.cost,1
			equalState(input.event.state,after,"Native "..purchase.action.." event",true)
			equalState(current(),after,"Native "..purchase.action.." server state",true)
			assert(service.army:get(uid).order=="hold","Purchase reset the army order")
			local plot=service.world.model.Plots["Plot"..service.registry:get(uid).plotId]
			for _,pad in plot.Controls:GetChildren()do
				assert(pad:GetAttribute("Action")~=purchase.action,"Completed purchase retained an input pad")
			end
			evidence.purchases[purchase.action]={cost=purchase.cost,coins=current().coins,
				reserve=current().farmCoins,distance=input.distance,field=purchase.field}
			cases+=1
		end
		assert(current().coins==560 and current().blacksmithLevel==1 and current().armorerLevel==1
			and current().storehouseLevel==1,"Workshop/storage final ledger differs")
		restore()
		stage("Native troop exits and training gates")
		evidence.trainingCamp=require(game.ServerStorage.RuntimeTests.TrainingCamp)(context,player,round)
		assert(evidence.trainingCamp.ok and evidence.trainingCamp.cases==7)
		cases+=evidence.trainingCamp.cases
		return {ok=true,cases=cases,evidence=evidence,
			message="Native advanced pads, workshop/storage prompts and training return paths against fake profiles"}
	end)
	local clean,cleanupError=pcall(restore)
	assert(clean,cleanupError);assert(ok,result);return result
end

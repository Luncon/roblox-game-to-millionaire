-- Real-time observation of normal infrastructure Heartbeat in a fake-store session.
return function(context,player)
	assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
	local service=context.service
	local uid=player.UserId
	local Tenders=require(game.ServerScriptService.Game.FarmTenders)
	local cases,evidence=0,{}
	for _,tier in {1,2}do
		local civ=if tier==1 then "sparta" else "britain"
		local state={coins=1000,level=12,weaponLevel=1,armorLevel=1,barracksLevel=1,
			trainingLevel=0,farmLevel=tier,workersLevel=if tier==1 then 0 else 2,
			armyCampLevel=0,farmCoins=0,extraTroopClass="warrior",blacksmithLevel=0,armorerLevel=0,storehouseLevel=0}
		assert(service.profiles:set(uid,civ,state))
		assert(service.select(player,civ,tier==2).ok)
		local claim=service.registry:get(uid)
		local plot=service.world.model.Plots["Plot"..claim.plotId]
		local farm=plot.Infrastructure.Farmland
		local workers={farm.Farmer1}
		if tier==2 then table.insert(workers,farm.Farmer2);table.insert(workers,farm.Farmer3)end
		local visits,previous,armBounds={},{},{}
		for _,rig in workers do visits[rig]={};armBounds[rig]={min=math.huge,max=-math.huge}end
		local start=os.clock()
		local duration=Tenders.cycle(tier)
		game:SetAttribute("FarmTenderVerificationPhase","Observing Farm "..tier.." for "..math.ceil(duration).." seconds")
		while os.clock()-start<duration+1 do
			local now=os.clock()
			assert(plot.Infrastructure.Farmland==farm,"Reserve income replaced the farm")
			for _,rig in workers do
				assert(rig.Parent==farm and not rig.Humanoid.EvaluateStateMachine and rig.Humanoid.WalkSpeed==0)
				assert(service.combat:actor(rig)==nil,"Passive farmer entered combat registration")
				local p=plot.Foundation.CFrame:PointToObjectSpace(rig:GetPivot().Position)
				local center=if rig.Name=="Farmer2"then 60 else -60
				assert(math.abs(p.X-center)<23.05 and math.abs(p.Z+172)<18.05)
				if previous[rig]then
					local old=previous[rig]
					assert((p-old.p).Magnitude<5*(now-old.time)+.2,"Live routine teleported")
				end
				previous[rig]={p=p,time=now}
				if rig:GetAttribute("Activity")=="Tending"then visits[rig][math.round(p.Z+172)]=true end
				local arm=rig.HumanoidRootPart.CFrame:PointToObjectSpace(rig.LeftHand.Position).Z
				armBounds[rig].min=math.min(armBounds[rig].min,arm)
				armBounds[rig].max=math.max(armBounds[rig].max,arm)
			end
			task.wait(.1)
		end
		local rows={}
		for _,rig in workers do
			local count=0;for _ in visits[rig]do count+=1 end
			assert(count==(if tier==1 then 5 else 7),"Live worker missed crop rows: "..rig.Name)
			assert(armBounds[rig].max-armBounds[rig].min>.4,"Live limbs did not articulate")
			table.insert(rows,count)
		end
		assert(service.economy:get(uid).farmCoins>0 and service.economy:get(uid).farmCoins<=60)
		evidence[tier]={seconds=os.clock()-start,rows=rows,workers=#workers,reserve=service.economy:get(uid).farmCoins}
		cases+=1
	end
	return {cases=cases,evidence=evidence}
end

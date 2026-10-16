-- Native gameplay fixture: one connected player, actual paths and fake profiles.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and context.store.isFakeProfileStore)
	local service=context.service
	local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
	local civilizations=require(game.ReplicatedStorage.Shared.Civilizations)
	local catalog={};for _,civ in civilizations do catalog[civ.id]=civ end
	local uid=player.UserId
	local cases,evidence=0,{}
	local function waitFor(predicate,label,seconds)
		local deadline=os.clock()+(seconds or 15)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..label)
	end
	local function test(name,fn)
		game:SetAttribute("TrainingCampPhase",name);fn();cases+=1;print("PASS: "..name)
	end
	local function native(options,timeout) return round("developmentInput",options,timeout or 180) end
	local function choose(id) return round("civilizationInput",{action="choose",civilization=id},30) end
	local function command(name) return native({kind="command",button=name},20) end
	if not service.registry:get(uid) then assert(choose("sparta").ok) end
	local original=service.registry:get(uid).civilizationId
	local fixture=if original=="rome" then "egypt" else "rome"
	local saved=service.profiles:get(uid,fixture)
	local initial={coins=1000,level=5,weaponLevel=1,armorLevel=1,barracksLevel=4,trainingLevel=0,
		farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior"}
	local function army() return service.army:get(uid) end
	local function plot() return service.world.model.Plots["Plot"..player:GetAttribute("PlotId")] end
	local function allArrived()
		for _,slot in army().slots do
			if not slot.rig or slot.rig:GetAttribute("WarriorState")~="Regrouped"
				or not Camp.contains(plot().Foundation.CFrame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position),1) then return false end
		end
		return true
	end
	local function checkpoint(level,gear)
		local state=service.economy:get(uid)
		state.level=level
		if gear then state.weaponLevel,state.armorLevel=gear,gear end
		assert(service.economy:replace(uid,state))
		local claim=service.registry:get(uid)
		service.world:setOwner(claim.plotId,catalog[fixture],uid,player.DisplayName,level)
		service.world:syncControls(claim.plotId,state)
		service.army:refresh(player)
		player:SetAttribute("SettlementLevel",level)
	end
	local ok,result=pcall(function()
		assert(service.profiles:set(uid,fixture,initial));assert(choose(fixture).ok)
		test("native exterior training purchase retains the existing unlock and price",function()
			local pad=plot().Controls.TrainingButton
			assert(plot().Foundation.CFrame:PointToObjectSpace(pad.Position).X+pad.Size.X/2< -128)
			evidence.purchase=native({kind="pad",action="training"})
			assert(service.economy:get(uid).coins==950 and service.economy:get(uid).trainingLevel==1)
			assert(not plot().Controls:FindFirstChild("TrainingButton") and plot().Infrastructure.TrainingYard.Campfire)
		end)
		-- Trusted progression setup isolates army resting from unrelated purchases.
		assert(choose(original).ok)
		initial.level,initial.trainingLevel,initial.armyCampLevel=10,1,1
		initial.farmLevel,initial.workersLevel,initial.coins=1,1,950
		assert(service.profiles:set(uid,fixture,initial));assert(choose(fixture).ok)
		test("three live troops walk from barracks to their campfire",function()
			assert(player:GetAttribute("ArmyCount")==3)
			local origins={};for id,slot in army().slots do origins[id]=slot.rig.HumanoidRootPart.Position end
			command("Regroup");local started=os.clock()
			waitFor(allArrived,"three native return paths",120)
			evidence.returnSeconds=os.clock()-started
			for id,slot in army().slots do
				assert((slot.rig.HumanoidRootPart.Position-origins[id]).Magnitude>80)
				assert(slot.rig.HumanoidRootPart:GetNetworkOwner()==nil and slot.rig.Humanoid.WalkSpeed==5)
			end
		end)
		test("resting troops walk slowly and pause inside the yard without crossing the fire",function()
			local observed={}
			for id,slot in army().slots do observed[id]={rig=slot.rig,start=slot.rig.HumanoidRootPart.Position,
				last=slot.rig.HumanoidRootPart.Position,health=slot.rig.Humanoid.Health,moved=0} end
			local finish=os.clock()+18
			while os.clock()<finish do
				for id,slot in army().slots do
					local record=observed[id];local rig=slot.rig;assert(rig==record.rig)
					local position=rig.HumanoidRootPart.Position
					local point=plot().Foundation.CFrame:PointToObjectSpace(position)
					assert(Camp.contains(point,1),"Resting troop left yard: "..id.." "..tostring(point))
					local delta=point-Camp.center
					assert(Vector3.new(delta.X,0,delta.Z).Magnitude>4.5,"Troop crossed the fire")
					assert(rig.Humanoid.WalkSpeed==5 and rig.Humanoid.Health==record.health)
					assert((position-record.last).Magnitude<3,"Resting troop teleported")
					record.moved=math.max(record.moved,(position-record.start).Magnitude)
					record.last=position
					record[rig:GetAttribute("RestPhase")]=true
				end
				task.wait(.1)
			end
			for id,record in observed do assert(record.walking and record.pausing and record.moved>3,"No complete resting cycle: "..id) end
			command("Regroup")
			for _,slot in army().slots do assert(slot.rig:GetAttribute("WarriorState")=="Regrouped") end
			evidence.observationSeconds=18
		end)
		test("native Hold stops wandering and Advance restores battlefield speed",function()
			command("Hold");task.wait(.5)
			local positions={};for id,slot in army().slots do positions[id]=slot.rig.HumanoidRootPart.Position end
			task.wait(1.5)
			for id,slot in army().slots do
				assert((slot.rig.HumanoidRootPart.Position-positions[id]).Magnitude<1.2)
				assert(slot.rig:GetAttribute("RestPhase")==nil)
			end
			command("Advance")
			waitFor(function() return (army().slots.warrior.rig.HumanoidRootPart.Position-positions.warrior).Magnitude>3 end,"native advance",12)
			for _,slot in army().slots do assert(slot.rig.Humanoid.WalkSpeed==12) end
			command("Regroup");waitFor(allArrived,"return after interruption",30)
		end)
		test("upgrades preserve health deficits identities and a regrouped replacement deadline",function()
			local before=army()
			before.slots.warrior.rig.Humanoid.Health-=10
			before.slots.camp.rig.Humanoid.Health=0
			waitFor(function()return army().slots.camp.respawnAt>0 end,"camp death")
			local deadline=army().slots.camp.respawnAt
			checkpoint(20,2)
			assert(army().slots.camp.respawnAt==deadline and army().slots.warrior.rig==before.slots.warrior.rig)
			assert(math.abs(before.slots.warrior.rig.Humanoid.MaxHealth-before.slots.warrior.rig.Humanoid.Health-10)<.002)
			assert(army().order=="regroup" and player:GetAttribute("TroopCapacity")==3)
			waitFor(function() return army().slots.camp.rig~=nil end,"normal replacement deadline",16)
			assert(workspace:GetServerTimeNow()>=deadline and army().slots.camp.rig~=before.slots.camp.rig)
			waitFor(allArrived,"replacement walks to yard before resting",60)
		end)
		test("native regroup uses side entrances at settlement twenty and fifty",function()
			evidence.gates={}
			for _,level in {20,50} do
				command("Hold");checkpoint(level)
				local frame=plot().Foundation.CFrame;local radius=plot().Foundation.Size.X/2-2
				for id,slot in army().slots do
					local offset=if id=="ranged" then 2 elseif id=="camp" then -2 else 0
					slot.rig:PivotTo(frame*CFrame.new(-radius+12,5,Camp.center.Z+offset))
				end
				command("Regroup")
				local crossed={}
				local started=os.clock()
				waitFor(function()
					for id,slot in army().slots do
						local point=frame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position)
						if point.X< -radius then
							if not crossed[id] then assert(math.abs(point.Z-Camp.center.Z)<Camp.approachHalfWidth,"Troop bypassed side gate") end
							crossed[id]=true
						end
					end
					return allArrived()
				end,"native level "..level.." side gate",60)
				assert(crossed.warrior and crossed.ranged and crossed.camp)
				evidence.gates[tostring(level)]=os.clock()-started
			end
		end)
		test("switching restores purchased camp and clears transient resting movement",function()
			local rigs={};for _,slot in army().slots do table.insert(rigs,slot.rig) end
			assert(choose(original).ok)
			for _,rig in rigs do assert(rig.Parent==nil) end
			assert(choose(fixture).ok and army().order=="advance")
			assert(plot().Infrastructure.TrainingYard.Campfire and not plot().Controls:FindFirstChild("TrainingButton"))
			for _,slot in army().slots do assert(slot.rig.Humanoid.WalkSpeed==12 and slot.rig:GetAttribute("RestPhase")==nil) end
		end)
		return {ok=true,cases=cases,evidence=evidence}
	end)
	local clean,errorMessage=pcall(function()
		if service.registry:get(uid).civilizationId~=original then assert(service.select(player,original,true).ok) end
		assert(service.profiles:set(uid,fixture,saved))
	end)
	assert(clean,errorMessage);assert(ok,result);return result
end

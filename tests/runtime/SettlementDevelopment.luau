-- Ordinary server Script integration. Native client input is supplied by the
-- trusted test launcher's round(action, options, timeout) callback.
return function(context,player,round)
	assert(game:GetService("RunService"):IsStudio() and game:GetAttribute("SoloVerificationEnabled"))
	assert(context and context.store and context.store.isFakeProfileStore,"Never run development fixtures against player storage")
	assert(player.Parent==game:GetService("Players") and type(round)=="function")
	local service=context.service;local uid=player.UserId
	assert(service and service.profiles:isWritable(uid))
	local function waitFor(predicate,description,seconds)
		local deadline=os.clock()+(seconds or 15)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local cases,evidence=0,{}
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function native(options,timeout) local r=round("developmentInput",options,timeout or 180);assert(r.ok);return r end
	local function choose(id) local r=round("civilizationInput",{action="choose",civilization=id},30);assert(r.ok and r.currentCiv==id);return r end
	local function current() return service.economy:get(uid) end
	local function army() return service.army:get(uid) end
	local function pad(action) return native({kind="pad",action=action}) end
	local function command(button) return native({kind="command",button=button},20) end
	local claim=service.registry:get(uid)
	if not claim then choose("sparta");claim=service.registry:get(uid) end
	local originalCiv=claim.civilizationId
	local original=current()
	local fixtureCiv=if originalCiv=="rome" then "egypt" else "rome"
	local originalFixture=service.profiles:get(uid,fixtureCiv)
	local initial={coins=1000,level=5,weaponLevel=1,armorLevel=1,barracksLevel=4,
		trainingLevel=0,farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior"}
	local ok,result=pcall(function()
		assert(service.profiles:set(uid,fixtureCiv,initial));choose(fixtureCiv)
		test("native early-tier replacement cannot purchase its successor without a complete exit",function()
			evidence.tierLatch=native({kind="tierLatch"},60)
			assert(current().weaponLevel==3 and current().coins==967)
		end)
		-- A separate trusted checkpoint precondition avoids claiming that we tested
		-- unrelated settlement levels six through nine with this focused harness.
		choose(originalCiv)
		initial.level,initial.weaponLevel,initial.coins=9,3,967
		assert(service.profiles:set(uid,fixtureCiv,initial));choose(fixtureCiv)
		local plot=service.world.model.Plots["Plot"..player:GetAttribute("PlotId")]
		test("native building purchases unlock their successors and farm production stays in its reserve",function()
			assert(not plot.Controls:FindFirstChild("UpgradeButton") and not plot.Controls:FindFirstChild("WorkersButton"))
			assert(not native({kind="inspect"}).panelVisible)
			pad("training");pad("farm")
			assert(current().coins==837 and current().trainingLevel==1 and current().farmLevel==1)
			local tool=player.Character:FindFirstChildOfClass("Tool")
			local armor=player.Character:FindFirstChild("CivilizationArmor")
			local warrior=army().slots.warrior.rig
			local reserve=current().farmCoins
			waitFor(function() return current().farmCoins>reserve end,"real five-second farm production",7)
			assert(current().coins==837 and player.Character:FindFirstChildOfClass("Tool")==tool
				and player.Character:FindFirstChild("CivilizationArmor")==armor and army().slots.warrior.rig==warrior)
			pad("workers");assert(current().coins==777 and current().workersLevel==1)
			reserve=current().farmCoins
			waitFor(function() return current().farmCoins>=reserve+2 end,"real worker-boosted farm production",7)
			assert(current().coins==777)
		end)
		test("checkpoint-ten purchase unlocks an independent third army slot",function()
			assert(plot.Controls:FindFirstChild("UpgradeButton"))
			pad("upgrade");assert(current().level==10 and current().coins==672)
			pad("armyCamp");assert(current().armyCampLevel==1 and current().coins==552)
			waitFor(function() local a=army();return a and a.slots.camp and a.slots.camp.rig end,"third automatic troop")
			local a=army();assert(a.slots.warrior.rig and a.slots.ranged.rig and a.slots.camp.kind=="warrior")
			assert(player:GetAttribute("TroopCapacity")==3 and player:GetAttribute("ArmyCount")==3)
		end)
		test("actual farm collection moves exactly the published reserve amount to the wallet",function()
			local before=current().coins
			local collected=pad("collectFarm").event
			assert(collected.amount>0 and collected.state.farmCoins==0)
			assert(current().coins==before+collected.amount)
			evidence.collected=collected.amount
		end)
		test("native army orders hold position, advance physically, and regroup outside the battle zone",function()
			command("Hold");task.wait(1)
			local positions={};for id,slot in army().slots do positions[id]=slot.rig.HumanoidRootPart.Position end
			task.wait(1.5)
			for id,slot in army().slots do
				local delta=slot.rig.HumanoidRootPart.Position-positions[id]
				assert(Vector3.new(delta.X,0,delta.Z).Magnitude<1.2,"Hold continued marching: "..id)
			end
			local camp=army().slots.camp.rig;local origin=camp.HumanoidRootPart.Position
			command("Advance")
			waitFor(function() return (camp.HumanoidRootPart.Position-origin).Magnitude>3 end,"actual advance displacement",15)
			command("Regroup")
			local began=os.clock()
			waitFor(function()
				for id,slot in army().slots do
					local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
					local position=plot.Foundation.CFrame:PointToObjectSpace(slot.rig.HumanoidRootPart.Position)
					if slot.rig:GetAttribute("WarriorState")~="Regrouped" or not Camp.contains(position,1) then return false end
				end
				return true
			end,"all three real troops walking home",120)
			for _,slot in army().slots do
				assert(not require(game.ServerScriptService.Game.CombatRules).containsArena(service.world.model.Battlefield,slot.rig.HumanoidRootPart.Position))
			end
			assert(army().order=="regroup");evidence.regroupSeconds=os.clock()-began
		end)
		test("Barracks composition preserves living troops and pending deadlines before replacement",function()
			-- The living melee camp must not conceal the main melee slot's wait.
			army().slots.warrior.rig.Humanoid.Health=0
			waitFor(function() return army().slots.warrior.respawnAt>0 end,"main warrior death with a living melee camp")
			local hud=native({kind="inspect"})
			assert(hud.campCount==1 and string.match(hud.armyText,"Next spawn %d+s"),"Living camp hid the independent main-slot respawn countdown: "..hud.armyText)
			waitFor(function() return army().slots.warrior.rig~=nil end,"main warrior's real replacement timer",16)
			local before=army();local camp=before.slots.camp.rig
			local function composition(melee,ranged)
    local board=plot.Settlement.Barracks.RecruitmentBoard
    player.Character:PivotTo(board.CFrame*CFrame.new(0,0,-3));task.wait(.45)
    assert(service.command(player,"composition",{melee=melee,ranged=ranged,medic=0}).ok)
   end
			composition(1,2);assert(army().slots.camp.rig==camp and army().slots.camp.kind=="warrior")
			camp.Humanoid.Health=0
			waitFor(function() return army().slots.camp.respawnAt>0 end,"camp death deadline")
			local deadline=army().slots.camp.respawnAt
			composition(2,1);composition(1,2)
			assert(army().slots.camp.respawnAt==deadline and not army().slots.camp.rig)
			waitFor(function() return army().slots.camp.rig~=nil end,"real barracks-four replacement timer",16)
			local after=army();assert(workspace:GetServerTimeNow()>=deadline and after.slots.camp.rig~=camp and after.slots.camp.kind=="ranged")
			assert(after.slots.warrior.rig==before.slots.warrior.rig and after.slots.ranged.rig==before.slots.ranged.rig and after.order=="regroup")
			evidence.campRespawnDelay=13.5
		end)
		test("civilization switching restores new purchases and earns no reserve while inactive",function()
			choose(originalCiv)
			local saved=service.profiles:get(uid,fixtureCiv)
			task.wait(5.3)
			assert(service.profiles:get(uid,fixtureCiv).farmCoins==saved.farmCoins)
			choose(fixtureCiv)
			for _,field in {"coins","level","weaponLevel","armorLevel","barracksLevel","trainingLevel","farmLevel","workersLevel","armyCampLevel","farmCoins","extraTroopClass","recruitMelee","recruitRanged","recruitMedic"} do
				assert(current()[field]==saved[field],"Civilization switch lost "..field)
			end
			assert(army().order=="advance","Transient orders leaked across civilization selection")
		end)
		return {ok=true,cases=cases,evidence=evidence,message="One real client: native development pads, farming, checkpoint, army orders and class replacement against fake profiles"}
	end)
	local cleanupOk,cleanupError=pcall(function()
		if service.registry:get(uid).civilizationId~=originalCiv then assert(service.select(player,originalCiv,true).ok) end
		assert(service.profiles:set(uid,fixtureCiv,originalFixture))
		for _,field in {"coins","level","weaponLevel","armorLevel","barracksLevel"} do assert(current()[field]==original[field],"Fixture changed original civilization "..field) end
	end)
	assert(cleanupOk,cleanupError)
	assert(ok,result)
	return result
end

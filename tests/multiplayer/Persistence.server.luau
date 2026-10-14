-- Two real clients, production gameplay controllers, injected in-memory storage.
-- A new ProfileService below verifies session restoration, not a real client rejoin.
local testing=game:GetService("StudioTestService")
local args=testing:GetTestArgs()
if type(args)~="table" or args.suite~="civilization-profiles" then return end
local Players,ReplicatedStorage=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.ProfileTestContext)
assert(context.store.isFakeProfileStore,"Persistence suite must never use live profile storage")
local control=Instance.new("Folder")
control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control
reports.Name,reports.Parent="Report",control
local responses={}
reports.OnServerEvent:Connect(function(player,round,response)
	responses[round]=responses[round] or {}; responses[round][player.UserId]=response
end)
control.Parent=ReplicatedStorage
local cases,nativeCases=0,0
local phase="Starting"
local function waitFor(predicate,description,timeout)
	local deadline=os.clock()+(timeout or 15)
	repeat if predicate() then return end; task.wait(.05) until os.clock()>deadline
	error("Timed out: "..description)
end
local function test(name,callback)
	phase=name; game:SetAttribute("PersistenceTestPhase",name)
	callback(); cases+=1; print("PASS: "..name)
end
local function round(name,action,player,civ,options,timeout)
	task.wait(.4)
	commands:FireClient(player,{round=name,action=action,target=player.UserId,civilization=civ,options=options})
	waitFor(function() return responses[name] and responses[name][player.UserId] end,name,timeout)
	local response=responses[name][player.UserId]
	assert(response.executed,tostring(response.result))
	return response.result
end
local function state(coins,level) return {coins=coins,level=level,weaponLevel=level,armorLevel=level,barracksLevel=level} end
local function owned(player)
	local units={}
	for _,rig in context.service.world.model.Troops:GetChildren() do
		if rig:GetAttribute("OwnerId")==player.UserId and rig.Humanoid.Health>0 then table.insert(units,rig) end
	end
	return units
end
local function equipped(player,civ,level)
	waitFor(function()
		local character=player.Character
		local tool=character and character:FindFirstChildOfClass("Tool")
		return tool and tool:GetAttribute("GeneratedBy")=="CivilizationEquipment"
			and tool:GetAttribute("CivilizationId")==civ and tool:GetAttribute("WeaponLevel")==level
			and character:FindFirstChild("CivilizationArmor")
			and character.CivilizationArmor:GetAttribute("ArmorLevel")==level
	end,"restored equipped "..civ.." gear")
	assert(player.Character.Humanoid.MaxHealth==({100,115,135,170})[level])
end
local ok,result=pcall(function()
	waitFor(function()
		if not context.service or #Players:GetPlayers()~=2 then return false end
		for _,player in Players:GetPlayers() do
			if not (responses.ready and responses.ready[player.UserId]) then return false end
			if args.phase=="failure" then
				local status=context.service.profiles:status(player.UserId).status
				if status~="locked" and status~="failed" then return false end
			elseif not context.service.profiles:isWritable(player.UserId) then return false end
		end
		return true
	end,"two loaded real clients",60)
	local players=Players:GetPlayers()
	table.sort(players,function(a,b) return a.UserId<b.UserId end)
	local first,second=players[1],players[2]
	local service,profiles=context.service,context.service.profiles
	if args.phase=="inspection" then
		test("inspection fixture restores IV Sparta and an occupied British civilization",function()
			assert(profiles:set(first.UserId,"sparta",state(417,4)))
			assert(profiles:set(first.UserId,"britain",state(29,2)))
			assert(profiles:set(first.UserId,"ming",state(23,2)))
			assert(round("inspection-sparta","select",first,"sparta").ok)
			assert(round("inspection-britain","select",second,"britain").ok)
			equipped(first,"sparta",4)
			waitFor(function() return #owned(first)==2 end,"inspection IV two-slot army")
		end)
		context.inspection={first=first,second=second,commands=commands,responses=responses}
		context.inspectionReports=responses
		game:SetAttribute("InspectionUserId",first.UserId)
		game:SetAttribute("InspectionSecondUserId",second.UserId)
		game:SetAttribute("PersistenceInspectionReady",true)
		phase="Waiting for root's viewport, independent-countdown and native-selector inspection"
		game:SetAttribute("PersistenceTestPhase",phase)
		waitFor(function() return game:GetAttribute("FinishPersistenceInspection")==true end,"root completes inspection",600)
		local helperCases,evidence=0,{}
		for name,results in responses do
			if name~="ready" and name~="inspection-sparta" and name~="inspection-britain" then
				for userId,response in results do
					assert(response.executed,"Inspection helper failed: "..tostring(response.result))
					if type(response.result)=="table" and response.result.ok then
						helperCases+=response.result.cases or 0
						evidence[name..":"..userId]=response.result
					end
				end
			end
		end
		assert(service:shutdown().ok)
		game:SetAttribute("PersistenceInspectionReady",false)
		return {ok=true,cases=cases+helperCases,inspection=evidence,
			message="Trusted inspection phase completed; helper evidence is separate from root's visual assessment"}
	end
	if args.phase=="failure" then
		local attempts=#context.store.attempts
		test("initial locked and invalid loads create neither claims accounts nor default writes",function()
			assert(attempts==2 and #context.store.commits==0)
			for _,player in players do
				assert(service.registry:get(player.UserId)==nil and service.economy:get(player.UserId)==nil)
				assert(player:GetAttribute("CivilizationId")==nil and player:GetAttribute("Coins")==nil)
				local rejected=round("failed-select-"..player.UserId,"select",player,"sparta")
				assert(not rejected.ok and rejected.reason=="profile_unavailable")
				local original=args.profileSeed["User_"..player.UserId]
				local stored=context.store:read("User_"..player.UserId)
				assert(stored.schemaVersion==original.schemaVersion and stored.civilizations.sparta.coins==original.civilizations.sparta.coins)
				if original.session then assert(stored.session.token==original.session.token) end
			end
			assert(#context.store.commits==0)
		end)
		test("repeated retry intents are storage-bounded and eligible later retries recover the original progress",function()
			-- Establish a fresh attempt timestamp after startup, which can exceed
			-- the cooldown on slower Studio clients.
			task.wait(10.1)
			for index,player in players do
				assert(round("establish-retry-"..player.UserId,"retry",player).ok)
				waitFor(function() return #context.store.attempts==attempts+index end,"fresh rejected storage load")
			end
			attempts=#context.store.attempts
			for attempt=1,3 do
				for _,player in players do
					local rejected=round("bounded-retry-"..attempt.."-"..player.UserId,"retry",player)
					assert(not rejected.ok and rejected.reason=="load_wait")
				end
			end
			assert(#context.store.attempts==attempts and #context.store.commits==0,"Retry intents bypassed the ten-second storage gate")
			for _,player in players do
				local repaired=context.store:read("User_"..player.UserId)
				-- Fixture maintenance repairs the fake record; production never repairs it.
				repaired.schemaVersion=1; repaired.session=nil
				context.store:seed("User_"..player.UserId,repaired)
			end
			task.wait(10.1)
			for _,player in players do
				assert(round("eligible-retry-"..player.UserId,"retry",player).ok)
				waitFor(function() return profiles:isWritable(player.UserId) end,"recovered profile")
				assert(profiles:get(player.UserId,"sparta").coins==args.profileSeed["User_"..player.UserId].civilizations.sparta.coins)
			end
			assert(#context.store.attempts==attempts+2 and service:shutdown().ok)
		end)
		return {ok=true,cases=cases,message="Two-client locked/malformed load isolation, bounded retry storage traffic and eligible recovery passed"}
	end
	if args.phase=="rejoin" then
		test("fresh Studio server restores both matching test users from the prior flushed snapshot",function()
			assert(type(args.profileSeed)=="table" and args.profileSeed["User_"..first.UserId] and args.profileSeed["User_"..second.UserId])
			assert(profiles:get(first.UserId,"sparta").coins==417 and profiles:get(first.UserId,"sparta").barracksLevel==4)
			assert(profiles:get(first.UserId,"japan").coins==5 and profiles:get(first.UserId,"japan").weaponLevel==2)
			assert(profiles:get(first.UserId,"britain").coins==29 and profiles:get(second.UserId,"britain").coins==0)
		end)
		test("fresh characters select their saved second civilization with real buildings gear and one troop",function()
			assert(round("rejoin-japan","select",first,"japan").ok)
			assert(round("rejoin-britain","select",second,"britain").ok)
			assert(first:GetAttribute("Coins")==5 and first:GetAttribute("SettlementLevel")==2)
			equipped(first,"japan",2)
			waitFor(function() return #owned(first)==1 end,"restored Japan warrior")
		end)
		test("fresh session switches to saved IV civilization and renders its actual maximum HUD",function()
			assert(round("rejoin-sparta","switch",first,"sparta").ok)
			equipped(first,"sparta",4)
			local hud=round("rejoin-iv-hud","progressHUD",first,nil,{expected={coins=417,level=4,weaponLevel=4,armorLevel=4,barracksLevel=4}})
			assert(hud.ok); context.hudEvidence=hud
			waitFor(function() return #owned(first)==2 end,"fresh-session IV two-slot army")
		end)
		test("second Studio server finalizes without resetting either saved civilization",function()
			assert(service:shutdown().ok)
			local stored=context.store:read("User_"..first.UserId)
			assert(stored.session==nil and stored.civilizations.sparta.coins==417 and stored.civilizations.japan.coins==5)
		end)
		return {ok=true,cases=cases,saved=context.store:dump(),hud=context.hudEvidence,
			message="Fresh Studio sessions with matching test UserIds restored independent progress, rebuilt both army capacities and rendered IV HUD; published datastore rejoin remains separate"}
	end
	test("loaded private profile previews contain only their owner's civilization progress",function()
		assert(profiles:set(first.UserId,"sparta",state(417,4)))
		assert(profiles:set(first.UserId,"britain",state(29,2)))
		local mine=round("profile-preview","snapshot",first)
		local other=round("other-preview","snapshot",second)
		assert(mine.ok and mine.state.profile.civilizations.sparta.coins==417)
		assert(mine.state.profile.civilizations.britain.level==2)
		assert(other.ok and other.state.profile.civilizations.sparta==nil,"Private progress leaked to another owner")
	end)
	local plotId,initialUnits
	test("select restores the saved IV settlement actual gear retired pads and two-slot army",function()
		assert(round("saved-sparta","select",first,"sparta").ok)
		assert(round("occupied-britain","select",second,"britain").ok)
		plotId=first:GetAttribute("PlotId")
		assert(first:GetAttribute("Coins")==417 and first:GetAttribute("SettlementLevel")==4)
		assert(first:GetAttribute("WeaponLevel")==4 and first:GetAttribute("ArmorLevel")==4 and first:GetAttribute("BarracksUpgradeLevel")==4)
		equipped(first,"sparta",4)
		local plot=service.world.model.Plots["Plot"..plotId]
		assert(plot.Foundation.Size.X==84 and plot.Settlement:GetAttribute("Architecture")=="sparta")
		assert(#plot.Controls:GetChildren()==2,"Completed profile retained purchased tier pads")
		waitFor(function() return #owned(first)==2 end,"restored IV troop capacity")
		initialUnits=owned(first)
		local classes={}
		for _,rig in initialUnits do
			classes[rig:GetAttribute("WarriorClass")]=true
			assert(rig:GetAttribute("WeaponLevel")==4 and rig.Humanoid.MaxHealth==170)
		end
		assert(classes.warrior and classes.ranged)
	end)
	test("actual IV HUD fits the real client viewport and exposes only the switch control",function()
		local hud=round("iv-hud","progressHUD",first,nil,{expected={coins=417,level=4,weaponLevel=4,armorLevel=4,barracksLevel=4}})
		assert(hud.ok); context.hudEvidence=hud
	end)
	test("occupied switch preserves original plot coins gear and both active troop identities",function()
		local rejected=round("occupied-switch","switch",first,"britain")
		assert(not rejected.ok and rejected.reason=="unavailable")
		assert(first:GetAttribute("CivilizationId")=="sparta" and first:GetAttribute("PlotId")==plotId and first:GetAttribute("Coins")==417)
		equipped(first,"sparta",4)
		assert(#owned(first)==2 and initialUnits[1].Parent and initialUnits[2].Parent)
		assert(profiles:get(first.UserId,"britain").coins==29)
	end)
	test("free civilization switch starts fresh and native pad upgrades affect only that civilization",function()
		assert(round("new-japan","switch",first,"japan").ok)
		assert(first:GetAttribute("PlotId")==plotId and first:GetAttribute("Coins")==0 and first:GetAttribute("SettlementLevel")==1)
		equipped(first,"japan",1)
		assert(#owned(first)==0 and initialUnits[1].Parent==nil and initialUnits[2].Parent==nil)
		local physical=round("japan-pads","physicalInput",first,nil,{barracksOnly=true},90)
		assert(physical.ok and physical.clicks==55 and physical.cases==4 and physical.level==2 and physical.coins==0)
		nativeCases=physical.cases
		assert(profiles:get(first.UserId,"japan").level==2 and profiles:get(first.UserId,"japan").weaponLevel==2)
		assert(profiles:get(first.UserId,"japan").armorLevel==2 and profiles:get(first.UserId,"sparta").coins==417)
	end)
	test("switching back restores IV progress and rebuilds troops rather than restoring old identities",function()
		assert(round("return-sparta","switch",first,"sparta").ok)
		assert(first:GetAttribute("Coins")==417 and first:GetAttribute("SettlementLevel")==4 and first:GetAttribute("PlotId")==plotId)
		equipped(first,"sparta",4)
		waitFor(function() return #owned(first)==2 end,"rebuilt IV army")
		for _,rig in owned(first) do assert(rig~=initialUnits[1] and rig~=initialUnits[2]) end
	end)
	test("character reset keeps the active saved profile and living troop identities",function()
		local previous=owned(first)
		first:LoadCharacterAsync()
		equipped(first,"sparta",4)
		assert(first:GetAttribute("Coins")==417 and first:GetAttribute("SettlementLevel")==4)
		assert(#owned(first)==2 and previous[1].Parent and previous[2].Parent)
	end)
	test("return to the second civilization restores its independent gear and periodic save",function()
		assert(round("return-japan","switch",first,"japan").ok)
		assert(first:GetAttribute("Coins")==0 and first:GetAttribute("SettlementLevel")==2 and first:GetAttribute("PlotId")==plotId)
		equipped(first,"japan",2)
		assert(profiles:save(first.UserId).ok)
		local savedAt=context.store:read("User_"..first.UserId).savedAt
		assert(profiles:set(first.UserId,"japan",service.economy:get(first.UserId)))
		waitFor(function()
			local stored=context.store:read("User_"..first.UserId)
			return stored.savedAt>savedAt and profiles:status(first.UserId).dirty~=true
		end,"periodic real-time profile save",40)
		local stored=context.store:read("User_"..first.UserId)
		assert(stored.civilizations.sparta.coins==417 and stored.civilizations.japan.level==2 and stored.civilizations.britain.coins==29)
	end)
	test("shutdown captures latest active economy and releases both leases",function()
		-- A server-owned mutation between periodic snapshot and shutdown exercises
		-- the final active-account capture without adding a public award endpoint.
		for _=1,5 do assert(service.economy:earn(first.UserId).ok) end
		assert(service:shutdown().ok)
		local stored=context.store:read("User_"..first.UserId)
		assert(stored.session==nil and stored.civilizations.japan.coins==5 and stored.civilizations.sparta.coins==417)
		assert(context.store:read("User_"..second.UserId).session==nil)
		assert(not service.economy:earn(first.UserId).ok and not service.economy:rewardKill(first.UserId).ok)
	end)
	test("a fresh storage session restores every civilization after the final flush",function()
		local restored=require(game.ServerScriptService.Game.ProfileService).new(context.store,{allowTestUserIds=true,sessionId="restore-proof"})
		assert(restored:load(first.UserId).ok)
		local sparta,japan,britain=restored:get(first.UserId,"sparta"),restored:get(first.UserId,"japan"),restored:get(first.UserId,"britain")
		assert(sparta.coins==417 and sparta.level==4 and sparta.barracksLevel==4)
		assert(japan.coins==5 and japan.level==2 and japan.weaponLevel==2 and japan.armorLevel==2 and japan.barracksLevel==1)
		assert(britain.coins==29 and britain.level==2)
		assert(restored:release(first.UserId).ok)
	end)
	return {ok=true,cases=cases+nativeCases,phase=phase,hud=context.hudEvidence,saved=context.store:dump(),
		message="Two-client private profiles, IV HUD, occupied/free switching, native per-civ pads, reset, autosave, final flush and fresh profile-session restore passed; real datastore rejoin is separate"}
end)
testing:EndTest(if ok then result else {ok=false,cases=cases+nativeCases,phase=phase,message=tostring(result)})

return function()
	local Service=require(game.ServerScriptService.Game.WarriorService)
	local cases=0
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	test("stable army slots separate reinforcement identity from its selected combat class",function()
		assert(type(Service.slotDefinitions)=="function","Stable army reinforcement slots are not implemented")
		for barracks=1,6 do
			for _,camp in {0,1} do for _,kind in {"warrior","ranged"} do
				local state={barracksLevel=barracks,armyCampLevel=camp,extraTroopClass=kind}
				local slots=Service.slotDefinitions(state)
				local expected=1+(if barracks>=4 then 1 else 0)+camp
				assert(#slots==expected,"Wrong independent reinforcement capacity")
				assert(slots[1].id=="warrior" and slots[1].kind=="warrior")
				local ids={}
				for _,slot in slots do assert(not ids[slot.id],"Duplicate army slot identity");ids[slot.id]=true end
				if barracks>=4 then assert(slots[2].id=="ranged" and slots[2].kind=="ranged") end
				if camp==1 then assert(slots[#slots].id=="camp" and slots[#slots].kind==kind) end
			end end
		end
	end)
	test("Army Camp II adds a dedicated melee beside the unchanged selected camp slot",function()
		for _,civ in require(game.ReplicatedStorage.Shared.Civilizations)do
			for _,kind in {"warrior","ranged"}do
				local state={barracksLevel=6,armyCampLevel=2,hospitalLevel=1,extraTroopClass=kind}
				local slots=Service.slotDefinitions(state);assert(#slots==5,civ.id)
				local byId={};for _,slot in slots do assert(not byId[slot.id]);byId[slot.id]=slot end
				assert(byId.camp.kind==kind and byId.reinforcement.kind=="warrior" and byId.medic.kind=="medic")
			end
		end
	end)

	test("class selection changes only the future camp definition and leaves previous descriptors intact",function()
		local state={barracksLevel=4,armyCampLevel=1,extraTroopClass="warrior"}
		local before=Service.slotDefinitions(state)
		state.extraTroopClass="ranged"
		local after=Service.slotDefinitions(state)
		assert(before[3].id=="camp" and before[3].kind=="warrior")
		assert(after[3].id=="camp" and after[3].kind=="ranged")
		assert(before[1].kind==after[1].kind and before[2].kind==after[2].kind)
		assert(state.barracksLevel==4 and state.armyCampLevel==1 and state.extraTroopClass=="ranged")
	end)
	test("army command boundary rejects invalid senders unclaimed players and arbitrary orders",function()
		local model=Instance.new("Model");model.Name="ArmyCommandBoundaryFixture";model.Parent=workspace
		local troops=Instance.new("Folder");troops.Name="Troops";troops.Parent=model
		local arena=Instance.new("Part");arena.Name="Battlefield";arena.Anchored=true;arena.Parent=model
		local world={model=model,plotCount=8}
		local registry={get=function() return nil end}
		local economy={get=function() return nil end,canMutate=function() return false end}
		local combat={actors=function() return {} end,actor=function() return nil end}
		local controller=Service.start(world,registry,economy,{},combat)
		local foreign=Instance.new("Folder")
		local senders={false,{},foreign}
		local connected=game:GetService("Players"):GetPlayers()[1]
		if connected then table.insert(senders,connected) end
		local ok,message=pcall(function()
			assert(type(controller.command)=="function","Authoritative army commands are not implemented")
			for _,sender in senders do
				for _,order in {"advance","hold","regroup","teleport",{},Vector3.new(1,2,3)} do
					assert(controller:command(sender,order).ok==false,"Invalid command boundary accepted a sender/order")
				end
			end
			assert(controller:command(nil,"hold").ok==false)
			assert(controller:get(if connected then connected.UserId else 0)==nil)
		end)
		controller:destroy();foreign:Destroy();model:Destroy()
		assert(ok,message)
	end)
	return cases
end

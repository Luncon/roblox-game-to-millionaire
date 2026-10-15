local testing=game:GetService("StudioTestService")
local args=testing:GetTestArgs()
if type(args)~="table" or args.suite~="world-growth" then return end
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.ProfileTestContext)
assert(context.store.isFakeProfileStore)
local control=Instance.new("Folder")
control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control
reports.Name,reports.Parent="Report",control
local responses={}
reports.OnServerEvent:Connect(function(player,round,result) responses[round]=responses[round] or {};responses[round][player.UserId]=result end)
control.Parent=Replicated
local phase,cases,evidence="Waiting for three clients",0,{}
local function waitFor(predicate,description,timeout)
	local deadline=os.clock()+(timeout or 20)
	repeat if predicate() then return end;task.wait(.1) until os.clock()>deadline
	error("Timed out: "..description)
end
local function round(name,action,player,civ,options,timeout)
	task.wait(.4)
	commands:FireClient(player,{round=name,action=action,target=player.UserId,civilization=civ,options=options})
	waitFor(function() return responses[name] and responses[name][player.UserId] end,name,timeout)
	local result=responses[name][player.UserId]
	assert(result.executed,tostring(result.result))
	return result.result
end
local function stage(name) phase=name;game:SetAttribute("WorldGrowthTestPhase",name) end
local ok,result=pcall(function()
	waitFor(function()
		if not context.service or #Players:GetPlayers()~=3 then return false end
		for _,player in Players:GetPlayers() do if not (responses.ready and responses.ready[player.UserId] and context.service.profiles:isWritable(player.UserId)) then return false end end
		return true
	end,"three ready profile-loaded clients",90)
	local players=Players:GetPlayers();table.sort(players,function(a,b) return a.UserId<b.UserId end)
	local first,second,third=players[1],players[2],players[3]
	stage("Native stable high-tier pads")
	assert(context.service.profiles:set(first.UserId,"sparta",{coins=1000,level=5,weaponLevel=3,armorLevel=3,barracksLevel=1}))
	assert(round("growth-claim","select",first,"sparta").ok)
	local native=round("growth-native","advancedPads",first,nil,nil,120)
	assert(native.ok and native.cases==6 and native.coins==743)
	evidence.native=native;cases+=native.cases
	stage("Five imported rigs across small intermediate and completed settlements")
	local imported=require(game.ServerStorage.RuntimeTests.CustomMeleeMovement)({levels={2,25,50,25,50}})
	assert(imported.ok);evidence.imported=imported;cases+=imported.cases
	stage("Three real owners and five automatic army slots")
	local army=require(game.ServerStorage.RuntimeTests.WorldGrowth)(first,second,third)
	assert(army.ok);evidence.army=army;cases+=army.cases
	stage("Completed profile and maximum HUD")
	local service=context.service
	assert(service.profiles:set(first.UserId,"ming",{coins=23,level=2,weaponLevel=2,armorLevel=2,barracksLevel=2}))
	assert(service.select(first,"ming",true).ok)
	assert(service.profiles:set(first.UserId,"sparta",{coins=417,level=50,weaponLevel=50,armorLevel=50,barracksLevel=4}))
	assert(service.select(first,"sparta",true).ok)
	local hud=round("growth-max-hud","progressHUD",first,nil,{expected={coins=417,level=50,weaponLevel=50,armorLevel=50,barracksLevel=4}})
	assert(hud.ok);evidence.hud=hud;cases+=hud.cases
	if args.inspect then
		context.inspection={first=first,second=second,third=third,commands=commands,responses=responses}
		context.inspectionReports=responses
		game:SetAttribute("InspectionUserId",first.UserId)
		game:SetAttribute("WorldGrowthInspectionReady",true)
		stage("Awaiting root world and maximum-settlement visual inspection")
		waitFor(function() return game:GetAttribute("FinishWorldGrowthInspection")==true end,"inspection completion",math.clamp(args.inspectionSeconds or 600,30,600))
		game:SetAttribute("WorldGrowthInspectionReady",false)
	end
	assert(service:shutdown().ok)
	return {ok=true,cases=cases,evidence=evidence,message="Native continued upgrades, all five imported rigs, measured starter/mid/final army navigation and completed profile/HUD passed"}
end)
testing:EndTest(if ok then result else {ok=false,cases=cases,phase=phase,message=tostring(result),evidence=evidence})

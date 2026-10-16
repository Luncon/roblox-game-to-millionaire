-- One ordinary Studio Play session with a fake store; never opens extra clients.
assert(game:GetService("RunService"):IsStudio(),"Development verification is Studio-only")
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore,"Never run fixtures against player data")
local control=Instance.new("Folder")
control.Name="PrototypeTestControl";control:SetAttribute("GeneratedBy","CivilizationPlaytest")
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control
reports.Name,reports.Parent="Report",control
local responses={}
reports.OnServerEvent:Connect(function(player,round,result)
	responses[round]=responses[round] or {};responses[round][player.UserId]=result
end)
control.Parent=Replicated
local cases,units,sequence=0,0,0
local evidence={}
local function stage(name)game:SetAttribute("TrainingCampVerificationPhase",name)end
local function waitFor(predicate,description,seconds)
	local deadline=os.clock()+(seconds or 15)
	repeat if predicate()then return end;task.wait(.1)until os.clock()>deadline
	error("Timed out: "..description)
end
local ok,result=pcall(function()
	stage("Waiting for one ready client")
	waitFor(function()
		local players=Players:GetPlayers();local p=players[1]
		return #players==1 and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			and context.service and context.service.profiles:isWritable(p.UserId)
			and responses.ready and responses.ready[p.UserId]
	end,"one client and writable fake-store profile",60)
	local player=Players:GetPlayers()[1]
	stage("Module regressions")
	local specs=game.ServerStorage.Tests:GetChildren()
	table.sort(specs,function(a,b)return a.Name<b.Name end)
	evidence.suites={}
	for _,spec in specs do
		if spec:IsA("ModuleScript")then
			local count=require(spec)();assert(count>0)
			evidence.suites[spec.Name]=count;units+=count
		end
	end
	game:SetAttribute("TrainingCampUnitCases",units)
	local function round(action,options,timeout)
		sequence+=1;local name="development-"..sequence
		stage("Native "..action.." "..tostring(options and (options.kind or options.action or options.button) or sequence))
		task.wait(.45)
		commands:FireClient(player,{round=name,action=action,target=player.UserId,options=options})
		waitFor(function()return responses[name] and responses[name][player.UserId]end,name,timeout or 60)
		local response=responses[name][player.UserId]
		assert(response.executed,tostring(response.result))
		assert(response.result.ok,"Client input failed: "..name)
		return response.result
	end
	stage("Native training camp")
	evidence.runtime=require(game.ServerStorage.RuntimeTests.TrainingCamp)(context,player,round)
	cases=evidence.runtime.cases
	return evidence.runtime
end)
stage(if ok then "Complete" else "Failed")
game:SetAttribute("TrainingCampVerificationResult",game.HttpService:JSONEncode({ok=ok,units=units,cases=cases,evidence=evidence,result=if ok then result else tostring(result)}))
if not ok then warn("Training camp verification failed: "..tostring(result))end

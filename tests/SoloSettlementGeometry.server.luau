-- One native client, production input, and an explicitly injected fake backend.
assert(game:GetService("RunService"):IsStudio())
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore,"Geometry fixtures require fake profiles")
local control=Instance.new("Folder");control.Name="PrototypeTestControl"
control:SetAttribute("GeneratedBy","CivilizationPlaytest")
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control;reports.Name,reports.Parent="Report",control
local responses={}
local connection=reports.OnServerEvent:Connect(function(player,round,result)
	responses[round]=responses[round]or {};responses[round][player.UserId]=result
end)
control.Parent=Replicated
local units,cases,sequence=0,0,0
local evidence={suites={}}
local function stage(name)game:SetAttribute("SettlementGeometryVerificationPhase",name)end
local function waitFor(predicate,label,timeout)
	local deadline=os.clock()+(timeout or 15)
	repeat if predicate()then return end;task.wait(.05)until os.clock()>deadline
	error("Timed out: "..label)
end
local ok,result=pcall(function()
	stage("Waiting for one native client and writable fake profile")
	waitFor(function()
		local player=Players:GetPlayers()[1]
		return #Players:GetPlayers()==1 and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and context.service and context.service.profiles:isWritable(player.UserId)
			and responses.ready and responses.ready[player.UserId]
	end,"one ready fake-store client",60)
	local player=Players:GetPlayers()[1]
	local specs=game.ServerStorage.Tests:GetChildren();table.sort(specs,function(a,b)return a.Name<b.Name end)
	for _,spec in specs do if spec:IsA("ModuleScript")then
		stage("Module "..spec.Name);local count=require(spec)();assert(count>0)
		evidence.suites[spec.Name]=count;units+=count;task.wait()
	end end
	game:SetAttribute("SettlementGeometryUnitCases",units)
	local function round(action,options,timeout)
		sequence+=1;local name="settlement-geometry-"..sequence
		commands:FireClient(player,{round=name,action=action,target=player.UserId,options=options})
		waitFor(function()return responses[name]and responses[name][player.UserId]end,name,timeout or 90)
		local response=responses[name][player.UserId]
		assert(response.executed,tostring(response.result));assert(response.result.ok,"Native geometry access failed: "..name)
		return response.result
	end
	stage("Native geometry matrix")
	evidence.matrix=require(game.ServerStorage.RuntimeTests.SettlementGeometry)(context,player)
	cases+=evidence.matrix.cases
	game:SetAttribute("SettlementGeometryMatrixResult",game.HttpService:JSONEncode(evidence.matrix))
	game:SetAttribute("SettlementGeometryMatrixComplete",true)
	stage("Native movement and purchase access")
	evidence.access=require(game.ServerStorage.RuntimeTests.SettlementGeometryAccess)(context,player,round)
	cases+=evidence.access.cases
	game:SetAttribute("SettlementGeometryAccessResult",game.HttpService:JSONEncode(evidence.access))
	return {cases=cases,matrix=evidence.matrix,access=evidence.access}
end)
stage(if ok then "Complete"else "Failed")
game:SetAttribute("SettlementGeometryVerificationResult",game.HttpService:JSONEncode({ok=ok,units=units,cases=cases,
	evidence=evidence,result=if ok then result else tostring(result)}))
connection:Disconnect();control:Destroy()
if not ok then warn("Settlement geometry verification failed: "..tostring(result))end

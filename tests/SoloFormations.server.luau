-- Exactly one ordinary Studio client, production services, explicitly fake storage.
assert(game:GetService("RunService"):IsStudio(),"Formation fixtures are Studio-only")
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore,"Formation fixtures must never open player storage")
local control=Instance.new("Folder");control.Name="PrototypeTestControl"
control:SetAttribute("GeneratedBy","CivilizationPlaytest")
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control;reports.Name,reports.Parent="Report",control
local responses={}
local connection=reports.OnServerEvent:Connect(function(player,round,result)
	responses[round]=responses[round] or {};responses[round][player.UserId]=result
end)
control.Parent=Replicated
local evidence={suites={}};local units,sequence=0,0
local function stage(name)
	game:SetAttribute("FormationVerificationPhase",name)
	-- Client-visible progress avoids switching Studio's viewport away from the
	-- client and making native GUI input unavailable during a running scenario.
	Replicated:SetAttribute("FormationVerificationPhase",name)
end
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
	end,"one ready client",60)
	local player=Players:GetPlayers()[1]
	local specs=game.ServerStorage.Tests:GetChildren();table.sort(specs,function(a,b)return a.Name<b.Name end)
	if script:GetAttribute("RuntimeOnly")then specs={}end -- Focused native reruns; default always includes all modules.
	for _,spec in specs do if spec:IsA("ModuleScript")then
		stage("Module "..spec.Name);local count=require(spec)();assert(count>0)
		evidence.suites[spec.Name]=count;units+=count;task.wait()
	end end
	game:SetAttribute("FormationUnitCases",units)
	local function round(action,options,timeout)
		sequence+=1;local name="tactical-"..sequence
		commands:FireClient(player,{round=name,action=action,target=player.UserId,options=options})
		waitFor(function()return responses[name] and responses[name][player.UserId]end,name,timeout or 30)
		local response=responses[name][player.UserId]
		assert(response.executed,tostring(response.result));assert(response.result.ok,"Native client action failed: "..name)
		return response.result
	end
	if script:GetAttribute("MedicalOnly")then
		evidence.medical=require(game.ServerStorage.RuntimeTests.MedicalSurvival)(context,player,round)
		return evidence.medical
	end
 if script:GetAttribute("RecruitmentOnly")then
  evidence.recruitment=require(game.ServerStorage.RuntimeTests.Recruitment)(context,player,round)
  evidence.layout=round("formationLayout",{},20)
  return evidence.recruitment
 end
	stage("Formation runtime")
 if script:GetAttribute("VikingOnly")then
  evidence.viking=require(game.ServerStorage.RuntimeTests.VikingWedge)(context,player,round,script:GetAttribute("VikingCombatOnly"))
  evidence.layout=round("formationLayout",{},20)
  return evidence.viking
 end
	if not script:GetAttribute("PersianOnly") and not script:GetAttribute("ResupplyOnly")then
		evidence.runtime=require(game.ServerStorage.RuntimeTests.Formations)(context,player,round,script:GetAttribute("RomanOnly"))
	end
	if not script:GetAttribute("RomanOnly")then
		evidence.persian=require(game.ServerStorage.RuntimeTests.PersianScreen)(context,player,round,script:GetAttribute("ResupplyOnly"))
	end
	evidence.layout=round("formationLayout",{},20)
 if not script:GetAttribute("PriorFormationsOnly")then
  evidence.viking=require(game.ServerStorage.RuntimeTests.VikingWedge)(context,player,round)
 end
	if script:GetAttribute("FullRegression")then
		stage("Existing tactical combat and movement regressions")
		local service=context.service
		service.neutralOpponents=require(game.ServerScriptService.Game.NeutralOpponentService).start(service.world,service.combat,nil,service.encounters)
		evidence.combat=require(game.ServerStorage.RuntimeTests.TacticalCombat)(context,player,round)
		evidence.movement=require(game.ServerStorage.RuntimeTests.TroopMovement)(context,player,round)
		service.neutralOpponents:destroy()
		stage("Existing medic survival regressions")
		evidence.medical=require(game.ServerStorage.RuntimeTests.MedicalSurvival)(context,player,round)
	end
	return evidence.persian or evidence.runtime
end)
stage(if ok then "Complete" else "Failed")
local encoded=game.HttpService:JSONEncode({ok=ok,units=units,evidence=evidence,
	result=if ok then result else tostring(result)})
game:SetAttribute("FormationVerificationResult",encoded)
Replicated:SetAttribute("FormationVerificationResult",encoded)
connection:Disconnect();control:Destroy()
if not ok then warn("Tactical combat verification failed: "..tostring(result))end

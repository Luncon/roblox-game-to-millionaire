-- Exactly one ordinary Studio Play client; no real storage calls.
assert(game:GetService("RunService"):IsStudio())
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore)
local control=Instance.new("Folder");control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control;reports.Name,reports.Parent="Report",control
local responses={}
local connection=reports.OnServerEvent:Connect(function(player,id,result)
	responses[id]=responses[id] or {};responses[id][player.UserId]=result
end)
control.Parent=Replicated
local function waitFor(predicate,label,seconds)
	local deadline=os.clock()+(seconds or 15)
	repeat if predicate()then return end;task.wait(.05)until os.clock()>deadline
	error("Timed out: "..label)
end
local units,sequence=0,0
local ok,result=pcall(function()
	game:SetAttribute("WeaponSkillsVerificationPhase","Waiting for one client")
	waitFor(function()
		local p=Players:GetPlayers()[1]
		return #Players:GetPlayers()==1 and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			and context.service and context.service.profiles:isWritable(p.UserId) and responses.ready and responses.ready[p.UserId]
	end,"native ready client",60)
	local player=Players:GetPlayers()[1]
	local specs=game.ServerStorage.Tests:GetChildren();table.sort(specs,function(a,b)return a.Name<b.Name end)
	for _,spec in specs do if spec:IsA("ModuleScript")then
		game:SetAttribute("WeaponSkillsVerificationPhase","Module "..spec.Name)
		units+=require(spec)();task.wait()
	end end
	local function round(action,options,seconds)
		sequence+=1;local id="skills-"..sequence
		commands:FireClient(player,{round=id,action=action,target=player.UserId,options=options})
		waitFor(function()return responses[id] and responses[id][player.UserId]end,id,seconds or 30)
		local response=responses[id][player.UserId]
		game:SetAttribute("WeaponSkillsLastNative",game.HttpService:JSONEncode({action=action,response=response}))
		assert(response.executed,tostring(response.result));assert(response.result.ok,"Native action failed: "..id)
		return response.result
	end
	return require(game.ServerStorage.RuntimeTests.WeaponSkills)(context,player,round)
end)
game:SetAttribute("WeaponSkillsVerificationPhase",if ok then "Complete" else "Failed")
local encoded=game.HttpService:JSONEncode({ok=ok,units=units,result=if ok then result else tostring(result)})
game:SetAttribute("WeaponSkillsVerificationResult",encoded)
print("WEAPON_SKILLS_RESULT "..encoded)
connection:Disconnect();control:Destroy()
if not ok then warn("Weapon skills verification failed: "..tostring(result))end

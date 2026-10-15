-- Ordinary Studio Play, ONE real client, in-memory profiles only.
-- This harness never calls ExecuteMultiplayerTestAsync or opens test windows.
assert(game:GetService("RunService"):IsStudio(),"Solo verification is Studio-only")
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore,"Solo fixtures must not access player data")
local control=Instance.new("Folder")
control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control
reports.Name,reports.Parent="Report",control
local responses={}
reports.OnServerEvent:Connect(function(player,round,result)
	responses[round]=responses[round] or {};responses[round][player.UserId]=result
end)
control.Parent=Replicated
local output=Instance.new("StringValue")
output.Name,output.Parent="SoloVerificationResult",game.ServerStorage
local phase,units,cases,evidence="Waiting for the single client",0,0,{}
local function stage(name) phase=name;game:SetAttribute("SoloVerificationPhase",name) end
local function waitFor(predicate,description,seconds)
	local deadline=os.clock()+(seconds or 15)
	repeat if predicate() then return end;task.wait(.1) until os.clock()>deadline
	error("Timed out: "..description)
end
local function publish(value)
	output.Value=game:GetService("HttpService"):JSONEncode(value)
end
local function round(player,name,action,options,timeout)
	task.wait(.4)
	commands:FireClient(player,{round=name,action=action,target=player.UserId,options=options})
	waitFor(function() return responses[name] and responses[name][player.UserId] end,name,timeout)
	local response=responses[name][player.UserId]
	assert(response.executed,tostring(response.result))
	assert(response.result.ok,"Client check did not return success: "..name)
	return response.result
end
local unverified={"Multiple connected owners and exclusive-claim races","Cross-owner NPC/player combat, assists and rewards",
	"Multiplayer networking and multi-owner projectile protection","Published-client/mobile/controller behavior"}
local ok,result=pcall(function()
	waitFor(function()
		local players=Players:GetPlayers()
		local character=if #players==1 then players[1].Character else nil
		local humanoid=if character then character:FindFirstChildOfClass("Humanoid") else nil
		return character and character:FindFirstChild("HumanoidRootPart") and humanoid and humanoid.Health>0
			and context.service and context.service.profiles:isWritable(players[1].UserId)
			and responses.ready and responses.ready[players[1].UserId]
	end,"one real living character, ready client and writable fake-store profile",60)
	local player=Players:GetPlayers()[1]
	assert(game:GetAttribute("SoloVerificationEnabled"),"Use SoloBootstrap, never the real datastore bootstrap")
	assert(player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
	stage("Fresh module specifications")
	local specs=game.ServerStorage.Tests:GetChildren()
	table.sort(specs,function(a,b) return a.Name<b.Name end)
	evidence.specs={}
	for _,spec in specs do
		if spec:IsA("ModuleScript") then
			local passed=require(spec)()
			assert(type(passed)=="number" and passed>0,"Empty suite: "..spec.Name)
			evidence.specs[spec.Name]=passed;units+=passed
		end
	end
	game:SetAttribute("SoloUnitCases",units)
	local service=context.service
	stage("Native initial civilization selection")
	assert(service.profiles:set(player.UserId,"sparta",{coins=1000,level=5,weaponLevel=3,armorLevel=3,barracksLevel=1}))
	evidence.initialSelection=round(player,"solo-initial","civilizationInput",{action="choose",civilization="sparta"})
	assert(evidence.initialSelection.currentCiv=="sparta");cases+=1
	stage("Native repeat-pad identity and contact latch")
	evidence.pads=round(player,"solo-advanced","advancedPads",nil,120)
	assert(evidence.pads.cases==6 and evidence.pads.coins==743);cases+=evidence.pads.cases
	stage("Five imported rigs physically traverse starter intermediate and final settlements")
	evidence.imported=require(game.ServerStorage.RuntimeTests.CustomMeleeMovement)({levels={2,25,50,25,50}})
	assert(evidence.imported.ok and evidence.imported.cases==3);cases+=evidence.imported.cases
	stage("One real owner automatic warrior lifecycle and fifteen-second replacement")
	evidence.lifecycle=require(game.ServerStorage.RuntimeTests.WarriorLifecycle)(player)
	assert(evidence.lifecycle.ok and evidence.lifecycle.cases==6);cases+=evidence.lifecycle.cases
	stage("Native civilization switching and restored completed profile")
	local plotId=player:GetAttribute("PlotId")
	assert(service.profiles:set(player.UserId,"ming",{coins=23,level=2,weaponLevel=2,armorLevel=2,barracksLevel=2}))
	evidence.ming=round(player,"solo-ming","civilizationInput",{action="choose",civilization="ming"})
	assert(evidence.ming.currentCiv=="ming" and evidence.ming.coins==23 and evidence.ming.plotId==plotId);cases+=1
	assert(service.profiles:set(player.UserId,"sparta",{coins=417,level=50,weaponLevel=50,armorLevel=50,barracksLevel=4}))
	evidence.sparta=round(player,"solo-sparta","civilizationInput",{action="choose",civilization="sparta"})
	assert(evidence.sparta.currentCiv=="sparta" and evidence.sparta.coins==417 and evidence.sparta.plotId==plotId);cases+=1
	evidence.cancel=round(player,"solo-cancel","civilizationInput",{action="cancel"})
	assert(not evidence.cancel.selectorVisible and evidence.cancel.hudVisible);cases+=1
	evidence.hud=round(player,"solo-max-hud","progressHUD",{expected={coins=417,level=50,weaponLevel=50,armorLevel=50,barracksLevel=4}})
	assert(evidence.hud.cases==4);cases+=evidence.hud.cases
	game:SetAttribute("SoloRuntimeCases",cases)
	game:SetAttribute("InspectionUserId",player.UserId)
	game:SetAttribute("SoloChecksComplete",true)
	publish({ok=true,unitCases=units,cases=cases,pendingInspection=true,evidence=evidence,unverified=unverified})
	stage("Awaiting single-window maximum settlement and landscape inspection")
	game:SetAttribute("WorldGrowthInspectionReady",true)
	context.inspection={first=player,commands=commands,responses=responses}
	context.inspectionReports=responses
	waitFor(function() return game:GetAttribute("FinishWorldGrowthInspection")==true end,"manual inspection completion",
		math.clamp(game:GetAttribute("SoloInspectionSeconds") or 600,30,600))
	game:SetAttribute("WorldGrowthInspectionReady",false)
	assert(service:shutdown().ok)
	return {ok=true,unitCases=units,cases=cases,evidence=evidence,unverified=unverified,
		message="Single real client: native ground upgrades and switching, max50 HUD, five imported rigs and one-owner lifecycle passed against an in-memory store"}
end)
if not ok then
	result={ok=false,unitCases=units,cases=cases,phase=phase,message=tostring(result),evidence=evidence,unverified=unverified}
	if context.service then pcall(function() context.service:shutdown() end) end
end
publish(result)
game:SetAttribute("SoloVerificationPassed",ok)
stage(if ok then "Passed" else "Failed")
if ok then print("SOLO_TEST_RESULT: PASS ("..units.." module cases, "..cases.." runtime cases)")
else warn("SOLO_TEST_RESULT: FAIL "..tostring(result.message)) end

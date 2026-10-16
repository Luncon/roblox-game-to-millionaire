-- One normal Studio Play session, with an injected in-memory profile store.
assert(game:GetService("RunService"):IsStudio())
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore)
local units=0
local ok,result=pcall(function()
	game:SetAttribute("FarmTenderVerificationPhase","Module regressions")
	local specs=game.ServerStorage.Tests:GetChildren()
	table.sort(specs,function(a,b)return a.Name<b.Name end)
	for _,spec in specs do
		if spec:IsA("ModuleScript")then units+=require(spec)()end
	end
	game:SetAttribute("FarmTenderUnitCases",units)
	game:SetAttribute("FarmTenderVerificationPhase","Waiting for one client")
	local player=nil
	local deadline=os.clock()+60
	repeat
		player=game.Players:GetPlayers()[1]
		if player and player.Character and context.service and context.service.profiles:isWritable(player.UserId)then break end
		task.wait(.1)
	until os.clock()>deadline
	assert(player and context.service.profiles:isWritable(player.UserId),"No writable fake-store player")
	assert(#game.Players:GetPlayers()==1,"Use one Studio client")
	return require(game.ServerStorage.RuntimeTests.FarmTenders)(context,player)
end)
game:SetAttribute("FarmTenderVerificationPhase",if ok then "Complete" else "Failed")
game:SetAttribute("FarmTenderVerificationResult",game.HttpService:JSONEncode({ok=ok,units=units,result=if ok then result else tostring(result)}))
if not ok then warn("Farm tender verification: "..tostring(result))end

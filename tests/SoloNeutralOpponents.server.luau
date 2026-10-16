-- One ordinary Studio Play session; no additional clients or real profile data.
assert(game:GetService("RunService"):IsStudio(),"Neutral verification is Studio-only")
local context=require(game.ServerStorage.RuntimeTests.SoloTestContext)
assert(context.store.isFakeProfileStore,"Neutral fixtures require a fake profile store")
local deadline=os.clock()+60
local player
repeat
	player=game.Players:GetPlayers()[1]
	if player and player.Character and context.service and context.service.profiles:isWritable(player.UserId) then break end
	task.wait(.1)
until os.clock()>deadline
local units=0
local ok,result=pcall(function()
	assert(player and context.service,"One connected client is required")
	local specs=game.ServerStorage.Tests:GetChildren()
	table.sort(specs,function(a,b)return a.Name<b.Name end)
	for _,spec in specs do
		if spec:IsA("ModuleScript") then
			game:SetAttribute("NeutralTestPhase",spec.Name)
			units+=require(spec)()
			task.wait()
		end
	end
	return require(game.ServerStorage.RuntimeTests.NeutralOpponents)(context,player)
end)
game:SetAttribute("NeutralRuntimeResult",game.HttpService:JSONEncode({ok=ok,units=units,
	result=if ok then result else tostring(result)}))
if not ok then warn("Neutral opponent verification failed: "..tostring(result)) end

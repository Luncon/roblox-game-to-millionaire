local testing = game:GetService("StudioTestService")
local args = testing:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "warrior-combat" then return end

local Players = game:GetService("Players")
local ok, result = pcall(function()
	local deadline = os.clock() + 45
	local players
	repeat
		players = Players:GetPlayers()
		local ready = #players == 2
		for _, player in players do
			local character = player.Character
			ready = ready and character ~= nil and character:FindFirstChild("HumanoidRootPart") ~= nil
		end
		if ready then break end
		assert(os.clock() < deadline, "Timed out waiting for two army test players")
		task.wait(.1)
	until false
	local runtime = game.ServerStorage:WaitForChild("RuntimeTests", 15)
	local combat = require(runtime.WarriorCombat)(players[1], players[2])
	local lifecycle = require(runtime.WarriorLifecycle)(players[1])
	return {ok=true,cases=combat.cases+lifecycle.cases,message=combat.message .. "; " .. lifecycle.message}
end)
testing:EndTest(if ok then result else {ok=false,message=tostring(result)})

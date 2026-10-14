local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local control = ReplicatedStorage:WaitForChild("PrototypeTestControl", 30)
if not control then return end
local player = Players.LocalPlayer
local commands = control:WaitForChild("Command")
local reports = control:WaitForChild("Report")
local request = ReplicatedStorage:WaitForChild("CivilizationRemotes"):WaitForChild("Request")

commands.OnClientEvent:Connect(function(command)
	if command.target and command.target ~= player.UserId then return end
	if command.action == "leave" then
		local testing = game:GetService("StudioTestService")
		assert(testing:CanLeaveTest(), "Client cannot leave this test")
		testing:LeaveTest()
		return
	end
	local ok, result = pcall(function()
		local first = request:InvokeServer("select", command.civilization)
		if command.action == "rapid" then
			local second = request:InvokeServer("select", command.civilization)
			return { first = first, second = second }
		end
		return first
	end)
	reports:FireServer(command.round, { executed = ok, result = result })
end)

-- The normal UI takes an initial snapshot; let its request cooldown expire.
task.wait(.5)
reports:FireServer("ready", { executed = true })

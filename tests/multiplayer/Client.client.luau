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
		if command.action=="skillInput" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("WeaponSkillInput",10))()
		end
		if command.action=="tacticalObserve" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("TacticalCombatObservation",10))(command.options)
		end
		if command.action=="advancedPads" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("AdvancedPads",10))()
		end
		if command.action=="developmentInput" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("SettlementDevelopment",10))(command.options)
		end
		if command.action == "snapshot" then return request:InvokeServer("snapshot") end
		if command.action == "retry" then return request:InvokeServer("retry") end
		if command.action == "civilizationInput" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("CivilizationInput",10))(command.options)
		end
		if command.action == "switch" then return request:InvokeServer("switch",command.civilization) end
		if command.action == "progressHUD" then
			return require(ReplicatedStorage:WaitForChild("ClientTests",10):WaitForChild("ProgressHUD",10))(command.options)
		end
		if command.action == "meleeInput" then
			return require(ReplicatedStorage:WaitForChild("ClientTests", 10):WaitForChild("MeleeInput", 10))(command.options)
		end
		if command.action == "physicalInput" then
			return require(ReplicatedStorage:WaitForChild("ClientTests", 10):WaitForChild("PhysicalInput", 10))(command.options)
		end
		if command.action == "inspectHUD" then
			local hud = player.PlayerGui:WaitForChild("CivilizationSelection", 10):WaitForChild("SettlementHUD", 10)
			local hasButtons = false
			local hasSwitch = false
			for _, item in hud:GetDescendants() do
				if item:IsA("GuiButton") then
					if item.Name == "SwitchCivilization" then hasSwitch=true else hasButtons=true end
				end
			end
			return {visible=hud.Visible, hasButtons=hasButtons,hasSwitch=hasSwitch,
				coins=hud:WaitForChild("Coins", 10).Text, progression=hud:WaitForChild("Progression", 10).Text}
		end
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

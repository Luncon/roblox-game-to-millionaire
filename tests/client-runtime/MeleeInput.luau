-- Test-only helper: exercise the engine's equipped Tool activation with mouse input.
return function()
	local Players = game:GetService("Players")
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	assert(input, "Virtual mouse input is unavailable")
	local player = Players.LocalPlayer
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	assert(tool, "Native melee test requires an equipped Tool")
	local activated = 0
	local connection = tool.Activated:Connect(function() activated += 1 end)
	local camera = workspace.CurrentCamera
	local position = Vector2.new(camera.ViewportSize.X*.5, camera.ViewportSize.Y*.5)
	local ok, result = pcall(function()
		input:SendMousePosition(position)
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(.08)
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, false, 0)
		local deadline = os.clock()+3
		repeat task.wait(.05) until activated>0 or os.clock()>deadline
		assert(activated>0,"Native mouse input did not activate the equipped weapon")
		task.wait(.6)
		local hud = player.PlayerGui:WaitForChild("CivilizationSelection",10):WaitForChild("SettlementHUD",10)
		return {activated=activated>0,activations=activated,coins=player:GetAttribute("Coins"),
			feedback=hud:WaitForChild("EconomyFeedback",10).Text,army=hud:WaitForChild("ArmyStatus",10).Text}
	end)
	pcall(function() input:SendMouseButton(position, Enum.UserInputType.MouseButton1, false, 0) end)
	connection:Disconnect()
	assert(ok,result)
	return result
end

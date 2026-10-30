--!strict
-- Start only from the actual game LocalScript. Never require PlayerModule from
-- ExecuteLuau/tool fixtures: that VM has a different cache and creates a competing
-- controller singleton/render binding. Device capability readiness can arrive
-- after the default controller's initial input-mode selection.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local InputReadiness = {}

function InputReadiness.start(screen)
	local player = Players.LocalPlayer
	local controls, stopped = nil, false
	local connections = {}
	local function refresh()
		if controls and not stopped then
			-- Keep Roblox's own selection, bindings, controlsEnabled policy,
			-- movement and touch/gamepad behavior. No forced enable or key patch.
			controls:UpdateMovementMode()
		end
	end
	-- Subscribe before requiring the default module, which can yield during
	-- startup. The final refresh also covers readiness changes while it loads.
	for _, property in { "KeyboardEnabled", "GamepadEnabled", "TouchEnabled", "PreferredInput" } do
		table.insert(connections, Input:GetPropertyChangedSignal(property):Connect(refresh))
	end
	table.insert(
		connections,
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 10)
			local root = character:WaitForChild("HumanoidRootPart", 10)
			if humanoid and root and player.Character == character and humanoid.Health > 0 then
				refresh()
			end
		end)
	)
	local function destroy()
		stopped = true
		for _, connection in connections do
			connection:Disconnect()
		end
	end
	table.insert(connections, screen.Destroying:Connect(destroy))
	task.spawn(function()
		local playerScripts = player:WaitForChild("PlayerScripts")
		local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
		if stopped or not playerModule then
			return
		end
		controls = require(playerModule):GetControls()
		refresh()
	end)
	return { destroy = destroy }
end

return InputReadiness

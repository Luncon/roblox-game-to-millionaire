--!strict
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = {}
function Camera.start(screen, target)
	local overview, zoom = false, 1
	local connections = {}
	local controller = {}
	function controller.walk()
		overview = false
		screen:SetAttribute("CameraMode", "Walk")
		local camera = workspace.CurrentCamera
		local humanoid = Players.LocalPlayer.Character
			and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if camera and humanoid then
			camera.CameraType, camera.CameraSubject = Enum.CameraType.Custom, humanoid
		end
	end
	function controller.overview()
		overview = true
		screen:SetAttribute("CameraMode", "Overview")
	end
	table.insert(
		connections,
		RunService.RenderStepped:Connect(function()
			local frame, camera = target(), workspace.CurrentCamera
			if not overview or not frame or not camera then
				return
			end
			local aspect = math.max(1, camera.ViewportSize.Y / math.max(1, camera.ViewportSize.X))
			local distance = 34 / math.tan(math.rad(camera.FieldOfView / 2)) * aspect * zoom
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(frame.Position + Vector3.new(0.65, 0.9, 0.95).Unit * distance, frame.Position)
			camera.Focus = frame
		end)
	)
	table.insert(
		connections,
		Input.PointerAction:Connect(function(wheel, _pan, pinch, processed)
			if not overview or processed then
				return
			end
			zoom = math.clamp(zoom - wheel * 0.1 - pinch * 0.1, 0.45, 2)
		end)
	)
	table.insert(
		connections,
		Players.LocalPlayer.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			controller.walk()
		end)
	)
	screen.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	controller.walk()
	return controller
end
return Camera

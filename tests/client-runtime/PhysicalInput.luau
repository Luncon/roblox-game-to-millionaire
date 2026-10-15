-- Test-only LocalScript helper. Uses actual virtual hardware input and engine movement.
return function(options)
	local barracksOnly = type(options)=="table" and options.barracksOnly==true
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(root and humanoid and humanoid.Health > 0, "Physical test requires a living character")
	local input = UserInputService:CreateVirtualInput()
	assert(input, "VirtualInput is unavailable; physical input was not tested")
	local camera = workspace.CurrentCamera
	local originalType, originalFrame, originalSubject = camera.CameraType, camera.CFrame, camera.CameraSubject
	local originalAnchor = root.Anchored
	local walkBinding = "TycoonPhysicalInputWalk" .. player.UserId
	local plot = workspace.CivilizationPrototype.Plots["Plot" .. player:GetAttribute("PlotId")]
	local controls = plot.Controls
	local coin, settlement = controls.CoinButton, controls.UpgradeButton
	local weapon,armor=nil,nil
	local cases, clicks = 0, 0
	local mouseDown, keyDown = false, false
	local activePad = coin
	local walkTo
	local function waitFor(predicate, description, timeout)
		local deadline = os.clock() + (timeout or 10)
		repeat
			if predicate() then return end
			task.wait(.05)
		until os.clock() > deadline
		local target = player:GetMouse().Target
		error("Timed out: " .. description .. "; coins=" .. tostring(player:GetAttribute("Coins"))
			.. " settlement=" .. tostring(player:GetAttribute("SettlementLevel"))
			.. " clicks=" .. clicks .. " pad=" .. activePad.Name
			.. " rootDistance=" .. string.format("%.2f", (root.Position-activePad.Position).Magnitude)
			.. " mouseTarget=" .. (if target then target:GetFullName() else "nil"))
	end
	local function aim(pad)
		activePad = pad
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt((pad.CFrame * CFrame.new(0,20,22)).Position, pad.Position)
		task.wait(.15)
	end
	local function click(pad)
		local point, visible = camera:WorldToViewportPoint(pad.Position + Vector3.new(0,pad.Size.Y/2,0))
		assert(visible, "Pad is not visible to virtual mouse")
		local position = Vector2.new(point.X, point.Y)
		input:SendMousePosition(position)
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, true, 0)
		mouseDown = true
		task.wait(.02)
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, false, 0)
		mouseDown = false
		task.wait(.12)
	end
	local function positionOutside(pad, side)
		walkTo((pad.CFrame * CFrame.new(side * 7,0,0)).Position)
	end
	local function positionOutsideGear(pad, side)
		local frame = plot.Foundation.CFrame
		local current = frame:PointToObjectSpace(root.Position)
		local destination = frame:PointToObjectSpace(pad.Position)
		local outerX = destination.X + side * 9
		-- Cross the open forecourt instead of touching other purchase pads in the row.
		walkTo(frame:PointToWorldSpace(Vector3.new(current.X,5,17)))
		walkTo(frame:PointToWorldSpace(Vector3.new(outerX,5,17)))
		walkTo(frame:PointToWorldSpace(Vector3.new(outerX,5,destination.Z)))
	end
	local function earn(amount)
		positionOutside(coin, 1)
		aim(coin)
		for _ = 1, amount do
			local before = player:GetAttribute("Coins")
			click(coin)
			clicks += 1
			waitFor(function() return player:GetAttribute("Coins") ~= before end, "one coin from actual click", 3)
			assert(player:GetAttribute("Coins") == before + 1, "A single actual click did not award exactly one coin")
		end
	end
	walkTo = function(position)
		root.Anchored = false
		RunService:UnbindFromRenderStep(walkBinding)
		RunService:BindToRenderStep(walkBinding, Enum.RenderPriority.Last.Value + 1, function()
			local delta = position - root.Position
			local horizontal = Vector3.new(delta.X,0,delta.Z)
			humanoid:Move(if horizontal.Magnitude > 1.5 then horizontal.Unit else Vector3.zero, false)
		end)
		waitFor(function()
			local delta = root.Position - position
			return Vector3.new(delta.X,0,delta.Z).Magnitude < 2
		end, "walk onto or away from ground pad")
		RunService:UnbindFromRenderStep(walkBinding)
		humanoid:Move(Vector3.zero, false)
		task.wait(.3)
	end
	local center = plot.Foundation.CFrame:PointToWorldSpace(Vector3.new(0,5,17))
	local ok, result = pcall(function()
		assert(player:GetAttribute("Coins") == 0 and player:GetAttribute("SettlementLevel") == 1)
		assert(player:GetAttribute("WeaponLevel") == 1 and player:GetAttribute("ArmorLevel") == 1)
		local initialCoins = if barracksOnly then 25 else 60
		earn(initialCoins)
		assert(player:GetAttribute("Coins") == initialCoins)
		cases += 1
		walkTo(center)
		walkTo(settlement.Position)
		waitFor(function() return player:GetAttribute("SettlementLevel") == 2 end, "first physical settlement entry")
		assert(player:GetAttribute("Coins") == initialCoins-25)
		cases += 1
		if not barracksOnly then
			task.wait(2)
			assert(player:GetAttribute("SettlementLevel") == 2 and player:GetAttribute("Coins") == 35,
				"Remaining on an upgrade pad bought a second tier despite the entry latch")
			cases += 1
			walkTo(center)
			task.wait(.4)
			walkTo(settlement.Position)
			waitFor(function() return player:GetAttribute("SettlementLevel") == 3 end, "settlement exit and reentry")
			assert(player:GetAttribute("Coins") == 0)
			cases += 1
		end
		earn(30)
		weapon=controls:WaitForChild("WeaponButton",10)
		armor=controls:WaitForChild("ArmorButton",10)
		assert(weapon and armor,"Settlement upgrade did not create tier-two gear pads")
		-- Keep the character outside pad contact; the purchase below must come from a click.
		positionOutsideGear(weapon, -1)
		aim(weapon)
		task.wait(.25)
		assert(player:GetAttribute("Coins") == 30 and player:GetAttribute("WeaponLevel") == 1,
			"Walking to the weapon click position unexpectedly purchased an upgrade")
		click(weapon)
		waitFor(function() return player:GetAttribute("WeaponLevel") == 2 end, "actual weapon pad click")
		assert(player:GetAttribute("Coins") == 15)
		cases += 1
		-- Keyboard E exercises the engine's ProximityPrompt input route without firing its event.
		positionOutsideGear(armor, 1)
		aim(armor)
		task.wait(.5)
		assert(player:GetAttribute("Coins") == 15 and player:GetAttribute("ArmorLevel") == 1,
			"Walking to the armor prompt position unexpectedly purchased an upgrade")
		input:SendKey(true, Enum.KeyCode.E, false)
		keyDown = true
		task.wait(.1)
		input:SendKey(false, Enum.KeyCode.E, false)
		keyDown = false
		waitFor(function() return player:GetAttribute("ArmorLevel") == 2 end, "actual armor proximity key")
		assert(player:GetAttribute("Coins") == 0 and math.abs(humanoid.MaxHealth-(100+40/49))<.002)
		cases += 1
		return {ok=true,cases=cases,clicks=clicks,coins=player:GetAttribute("Coins"),
			level=player:GetAttribute("SettlementLevel"),weaponLevel=player:GetAttribute("WeaponLevel"),
			armorLevel=player:GetAttribute("ArmorLevel")}
	end)
	if keyDown then pcall(function() input:SendKey(false, Enum.KeyCode.E, false) end) end
	if mouseDown then pcall(function()
		input:SendMouseButton(Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2), Enum.UserInputType.MouseButton1, false, 0)
	end) end
	root.Anchored = originalAnchor
	RunService:UnbindFromRenderStep(walkBinding)
	humanoid:Move(Vector3.zero, false)
	camera.CameraType, camera.CFrame, camera.CameraSubject = originalType, originalFrame, originalSubject
	assert(ok, result)
	return result
end

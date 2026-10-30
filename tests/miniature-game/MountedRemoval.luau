--!strict
-- Extra native cleanup acceptance after the extended mounted UI flow.
-- Only normal travel, walking and hammer input mutate gameplay.
local function run()
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Workspace = game:GetService("Workspace")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong mounted removal boundary"
	)
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(screen and actions, "Mounted removal UI unavailable")
	local previousFlow = Replicated:GetAttribute("MiniatureMountedFlowResult")
	local latest, receipts = nil, {}
	local evidence =
		{ nativeVirtualInput = true, authoritativeMutation = false, localRelocation = false, attempts = {} }
	local input = Input:CreateVirtualInput()
	local deadline = os.clock() + 90
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function waitFor(predicate, label: string)
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() >= deadline
		error(label)
	end
	local function pointClick(point)
		input:SendMousePosition(point)
		task.wait(0.08)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.08)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.25)
	end
	local function click(button)
		assert(button and button.Visible and button.Active, "Mounted removal control unavailable")
		pointClick(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function action(label, press)
		for attempt = 1, 3 do
			local previous = #receipts
			press()
			waitFor(function()
				return #receipts > previous
			end, "No mounted removal receipt: " .. label)
			local packet = receipts[previous + 1]
			table.insert(evidence.attempts, {
				label = label,
				attempt = attempt,
				requestId = packet.requestId,
				ok = packet.result.ok,
				reason = packet.result.reason,
				revision = packet.snapshot.revision,
			})
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				"Mounted removal action refused: " .. tostring(packet.result.reason)
			)
		end
		error("Mounted removal retries exhausted")
	end
	local function actorFor(id)
		for _, actor in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
			if
				actor:GetAttribute("BuildingId") == id
				and actor:GetAttribute("Role") == "mounted"
				and actor:GetAttribute("Alive")
			then
				return actor
			end
		end
		return nil
	end
	local function visualFor(id)
		for _, folder in Workspace:GetChildren() do
			if folder.Name:match("^MiniatureClientActors") then
				for _, model in folder:GetChildren() do
					if model:IsA("Model") and model:GetAttribute("ActorId") == id then
						return model
					end
				end
			end
		end
		return nil
	end
	local ok, failure = pcall(function()
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.claim
		end, "Mounted removal snapshot unavailable")
		assert(
			latest.claim.civilizationId == "sparta"
				and latest.state.coins == 9050
				and latest.troops.mounted == 2
				and latest.troopCapacityUsed == 9,
			"Mounted removal requires completed extended flow"
		)
		local targetId, otherId = "b8", "b9"
		local targetBuilding
		for _, building in latest.state.buildings do
			if building.id == targetId then
				targetBuilding = building
			end
		end
		assert(targetBuilding and targetBuilding.kind == "mount", "First mounted facility unavailable")
		waitFor(function()
			return actorFor(targetId) and actorFor(otherId)
		end, "Two living mounted actors unavailable")
		local source, other = actorFor(targetId), actorFor(otherId)
		local visual = visualFor(source.Name)
		local otherVisual = visualFor(other.Name)
		assert(visual and otherVisual, "Mounted client clones unavailable")
		evidence.before = {
			coins = latest.state.coins,
			mountPlans = latest.state.plans.mount,
			capacityUsed = latest.troopCapacityUsed,
			mounted = latest.troops.mounted,
			targetBuildingId = targetId,
			sourceActorId = source.Name,
			sourceLife = source:GetAttribute("Life"),
			otherActorId = other.Name,
			otherLife = other:GetAttribute("Life"),
			otherHealth = other:GetAttribute("Health"),
		}
		local travel = action("travel civilization", function()
			click(screen.TopNavigation.Civilization)
		end)
		assert(travel.result.destination == "civilization", "Mounted removal travel destination differs")
		click(screen.CameraControls.Walk)
		local goal = latest.plotFrame:PointToWorldSpace(Vector3.new(targetBuilding.x, 3, targetBuilding.z + 5))
		local walked = 0
		for _ = 1, 8 do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			assert(
				root and humanoid and humanoid.Health > 0 and not character:FindFirstChildOfClass("Tool"),
				"Mounted removal commander unavailable"
			)
			local delta = goal - root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			if flat.Magnitude <= 7 then
				break
			end
			local direction = flat.Unit
			Workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
			task.wait(0.2)
			pointClick(Workspace.CurrentCamera.ViewportSize * Vector2.new(0.9, 0.4))
			local before = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(math.min(2, math.max(0.15, (flat.Magnitude - 2) / humanoid.WalkSpeed)))
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.2)
			local step = root.Position - before
			local distance = Vector3.new(step.X, 0, step.Z).Magnitude
			assert(distance > 0.5, "Mounted removal normal walking blocked")
			walked += distance
		end
		if not screen:GetAttribute("HammerSelected") then
			click(screen.Hotbar.Content.Slot1)
		end
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local plot = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local packet = action("hammer reclaim mounted facility", function()
			local point, shown =
				Workspace.CurrentCamera:WorldToViewportPoint(plot.Buildings[targetId].SelectTarget.Position)
			assert(shown, "Mounted facility outside hammer view")
			pointClick(Vector2.new(point.X, point.Y))
		end)
		assert(
			packet.snapshot.state.coins == 9050 and packet.snapshot.state.plans.mount == evidence.before.mountPlans + 1,
			"Mounted reclaim lost plan or changed Coins"
		)
		waitFor(function()
			return latest.troops.mounted == 1 and latest.troopCapacityUsed == 7
		end, "Mounted reclaim did not release exactly two slots")
		waitFor(function()
			return source.Parent == nil
				and visual.Parent == nil
				and actorFor(targetId) == nil
				and visualFor(source.Name) == nil
				and not plot.Buildings:FindFirstChild(targetId)
		end, "Reclaimed mounted source or local clone leaked")
		local stillOther = actorFor(otherId)
		assert(
			stillOther == other
				and other:GetAttribute("Life") == evidence.before.otherLife
				and visualFor(other.Name) == otherVisual,
			"Reclaim replaced unaffected mounted life or local clone"
		)
		waitFor(function()
			return screen.SettlementHUD.Resources.Text:find("Mounted 1", 1, true)
				and screen.SettlementHUD.Resources.Text:find("Army 7/10", 1, true)
		end, "Mounted removal weighted HUD stale")
		assert(
			Replicated:GetAttribute("MiniatureMountedFlowResult") == previousFlow,
			"Extra removal check overwrote extended flow evidence"
		)
		evidence.after = {
			coins = latest.state.coins,
			mountPlans = latest.state.plans.mount,
			capacityUsed = latest.troopCapacityUsed,
			mounted = latest.troops.mounted,
			sourceRemoved = true,
			localCloneRemoved = true,
			buildingRemoved = true,
			otherMountedLifePreserved = true,
			otherLocalClonePreserved = true,
			otherHealth = other:GetAttribute("Health"),
			commanderWalkDistance = walked,
			hud = screen.SettlementHUD.Resources.Text,
			extendedResultPreserved = true,
		}
	end)
	connection:Disconnect()
	pcall(function()
		input:SendKey(false, Enum.KeyCode.W, false)
	end)
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if not ok then evidence else nil }
	Replicated:SetAttribute("MiniatureMountedRemovalResult", game:GetService("HttpService"):JSONEncode(result))
	assert(ok, failure)
	return result
end
return run

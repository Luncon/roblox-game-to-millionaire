--!strict
-- Native Client fixture for the isolated injected-fake-store sandbox.
-- Starts real UI placement/Overview, then waits for root's explicit server-side
-- Humanoid death setup. No debug remote or client-owned health change is used.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Lifecycle UI missing")
	local Config = require(Replicated.MiniatureGame.Config)
	local Placement = require(Replicated.MiniatureGame.Placement)
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest, before, deathConnection
	local receipts = {}
	local evidence =
		{ nativeVirtualInput = true, relocationWasFixtureSetup = true, serverDeathIsExplicitFixtureSetup = true }
	local connection = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function copy(value)
		if type(value) ~= "table" then
			return value
		end
		local result = {}
		for key, child in value do
			result[key] = copy(child)
		end
		return result
	end
	local function equal(a, b)
		if type(a) ~= type(b) then
			return false
		end
		if type(a) ~= "table" then
			return a == b
		end
		for key, value in a do
			if not equal(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	local function waitFor(predicate, label, seconds)
		local deadline = os.clock() + (seconds or 15)
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() > deadline
		error(label)
	end
	local function step(label)
		evidence.lastStep = label
		Replicated:SetAttribute(
			"NativeLifecycleProgressJSON",
			Http:JSONEncode({ step = label, ownerId = player.UserId })
		)
	end
	local function clickPoint(point)
		input:SendMousePosition(point)
		task.wait(0.05)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local function click(button)
		assert(button and button.Visible and button.Active, "Lifecycle control unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function press(page, key)
		local body = screen[page].Content
		waitFor(function()
			local button = body:FindFirstChild(key)
			return button and button.Visible and button.Active
		end, "Unavailable " .. page .. "." .. key)
		local button = body[key]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		click(body[key])
	end
	local function restoreHUD()
		if not screen.SettlementHUD.Visible and screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
	end
	local function closeManagement()
		for _, page in { "Settlement", "Build", "Inspector", "Trade", "Research", "Army", "Select" } do
			if screen[page].Visible then
				click(screen[page].Close)
			end
		end
	end
	local function buildingProgress(state)
		local result = {}
		for _, building in state.buildings do
			result[building.id] = { kind = building.kind, x = building.x, z = building.z, rotation = building.rotation }
		end
		return result
	end
	local ok, result = pcall(function()
		step("await authoritative state")
		assert(
			Replicated:GetAttribute("MiniatureSandboxReady")
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong lifecycle boundary"
		)
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.state and latest.claim
		end, "Owned lifecycle state missing")
		local oldCharacter = player.Character
		local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
		local root = oldCharacter and oldCharacter:FindFirstChild("HumanoidRootPart")
		assert(oldHumanoid and oldHumanoid.Health > 0 and root, "Old living commander missing")
		oldCharacter:PivotTo(latest.plotFrame * CFrame.new(0, 4, 12))
		evidence.placementOpened = false
		local oldConfirmPoint
		if (latest.state.plans.house or 0) > 0 then
			step("open held house plan through UI")
			restoreHUD()
			click(screen.SettlementHUD.Navigation.BuildNavigation)
			waitFor(function()
				return screen.Build.Visible
			end, "Merchant did not open")
			press("Build", "Category_Homes")
			press("Build", "Place_house")
			waitFor(function()
				return screen:GetAttribute("PlacingKind") == "house"
					and workspace:FindFirstChild("LocalPlacementFootprint")
			end, "Held plan did not open placement")
			evidence.placementOpened = true
		elseif options.requirePlacement then
			error("Lifecycle needs an owned house plan; fixture does not buy or inject one")
		end
		closeManagement()
		click(screen.CameraControls.Overview)
		if screen.SettlementHUD.Visible then
			click(screen.SettlementHUD.MinimizePanel)
		end
		waitFor(function()
			return screen:GetAttribute("CameraMode") == "Overview"
				and workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable
		end, "Overview was not active before death")
		task.wait(0.3)
		if evidence.placementOpened then
			local sites = {}
			for x = -Config.plotWidth / 2, Config.plotWidth / 2, Config.grid do
				for z = -Config.plotDepth / 2, Config.plotDepth / 2, Config.grid do
					if Placement.validate(latest.state.buildings, "house", x, z, 0) then
						table.insert(sites, { x = x, z = z })
					end
				end
			end
			table.sort(sites, function(a, b)
				return a.x * a.x + a.z * a.z < b.x * b.x + b.z * b.z
			end)
			for _, site in sites do
				local point, shown = workspace.CurrentCamera:WorldToViewportPoint(
					latest.plotFrame:PointToWorldSpace(Vector3.new(site.x, 0, site.z))
				)
				if shown and point.Y < screen.AbsoluteSize.Y - 164 then
					-- Placement's input ray uses viewport point + the GUI inset;
					-- ordinary engine ClickDetector input has its own viewport convention.
					clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
					if screen.PlacementControls.PlacementActions.ConfirmPlacement.Active then
						evidence.draftSite = site
						break
					end
				end
			end
			evidence.draftValidBeforeDeath = screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
			assert(
				evidence.draftValidBeforeDeath or not options.requireValidDraft,
				"No visible valid house draft before death"
			)
			local confirm = screen.PlacementControls.PlacementActions.ConfirmPlacement
			oldConfirmPoint = confirm.AbsolutePosition + confirm.AbsoluteSize / 2 + Gui:GetGuiInset()
		end
		before = copy(latest)
		local died = false
		deathConnection = oldHumanoid.Died:Connect(function()
			died = true
		end)
		evidence.before = {
			civilizationId = before.claim.civilizationId,
			plotId = before.claim.plotId,
			coins = before.state.coins,
			goods = copy(before.state.goods),
			plans = copy(before.state.plans),
			buildings = buildingProgress(before.state),
			revision = before.revision,
			claimEpoch = before.claimEpoch,
			sessionId = before.sessionId,
		}
		step("waiting for root's owned server Humanoid.Health=0 setup")
		Replicated:SetAttribute("NativeLifecycleOwnerId", player.UserId)
		Replicated:SetAttribute("NativeLifecycleAwaitingDeath", true)
		waitFor(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return character
				and character ~= oldCharacter
				and humanoid
				and humanoid.Health > 0
				and character:FindFirstChild("HumanoidRootPart")
		end, "New living character did not arrive after explicit server death", options.respawnTimeout or 30)
		Replicated:SetAttribute("NativeLifecycleAwaitingDeath", false)
		assert(died or oldHumanoid.Health <= 0, "Death was not observed; replacement alone is insufficient")
		step("verify new life camera and claim context")
		local character, camera = player.Character, workspace.CurrentCamera
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest.claimEpoch > before.claimEpoch
		end, "Respawn did not invalidate old claim epoch")
		waitFor(function()
			local currentCamera = workspace.CurrentCamera
			return screen:GetAttribute("CameraMode") == "Walk"
				and currentCamera.CameraType == Enum.CameraType.Custom
				and currentCamera.CameraSubject == humanoid
		end, "Walk camera did not bind the new Humanoid")
		camera = workspace.CurrentCamera
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == nil
				and not workspace:FindFirstChild("LocalPlacementFootprint")
				and not screen.PlacementControls.Visible
		end, "Old placement survived respawn")
		assert(
			latest.sessionId == before.sessionId
				and latest.claim.plotId == before.claim.plotId
				and latest.claim.civilizationId == before.claim.civilizationId,
			"Respawn changed saved session or civilization/plot"
		)
		assert(
			equal(buildingProgress(before.state), buildingProgress(latest.state)),
			"Respawn changed building progress"
		)
		assert(
			equal(before.state.plans, latest.state.plans) and equal(before.state.workers, latest.state.workers),
			"Respawn spent plans or changed workers"
		)
		assert(
			before.state.hallUpgraded == latest.state.hallUpgraded
				and equal(before.state.roster, latest.state.roster)
				and equal(before.state.settings, latest.state.settings),
			"Respawn changed hall, roster or settings"
		)
		for id in before.state.research.completed do
			assert(latest.state.research.completed[id], "Respawn lost completed research")
		end
		local project = before.state.research.project
		if project then
			local restored = latest.state.research.project
			assert(
				latest.state.research.completed[project.id]
					or restored and restored.id == project.id and restored.remaining <= project.remaining + 0.01,
				"Respawn lost or reset active research"
			)
		end
		assert(latest.state.coins >= before.state.coins, "Respawn spent owned coins")
		assert(
			math.abs(character:GetScale() - 1) < 0.001
				and not character:FindFirstChildOfClass("Tool")
				and not player.Backpack:FindFirstChildOfClass("Tool"),
			"Respawn commander is miniature or armed"
		)
		closeManagement()
		if oldConfirmPoint then
			step("native click at former placement confirmation location")
			local count = #receipts
			clickPoint(oldConfirmPoint)
			task.wait(0.4)
			assert(
				#receipts == count and screen:GetAttribute("PlacingKind") == nil,
				"Old draft submitted after respawn"
			)
			evidence.oldDraftClickWasInert = true
		end
		if options.walk ~= false then
			step("native W-key movement on new life")
			closeManagement()
			click(screen.CameraControls.Walk)
			character:PivotTo(latest.plotFrame * CFrame.new(0, 4, 12))
			root = character.HumanoidRootPart
			camera = workspace.CurrentCamera
			camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 6, 14), root.Position + Vector3.new(0, 0, -10))
			task.wait(0.25)
			clickPoint(camera.ViewportSize * Vector2.new(0.5, 0.6))
			local began = root.Position
			local focused = game:GetService("UserInputService"):GetFocusedTextBox()
			evidence.walkBefore = {
				position = { x = began.X, y = began.Y, z = began.Z },
				walkSpeed = humanoid.WalkSpeed,
				state = humanoid:GetState().Name,
				platformStand = humanoid.PlatformStand,
				sit = humanoid.Sit,
				rootAnchored = root.Anchored,
				focusedTextBox = focused and focused:GetFullName(),
				cameraMode = screen:GetAttribute("CameraMode"),
				cameraSubjectIsNewHumanoid = camera.CameraSubject == humanoid,
			}
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(1)
			local moveDirection = humanoid.MoveDirection
			evidence.walkDuring = {
				moveDirection = { x = moveDirection.X, y = moveDirection.Y, z = moveDirection.Z },
				state = humanoid:GetState().Name,
				walkSpeed = humanoid.WalkSpeed,
			}
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.2)
			local delta = root.Position - began
			evidence.newLifeWalkDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
			evidence.newLifeVerticalChange = delta.Y
			assert(evidence.newLifeWalkDistance > 5, "New-life native walking was blocked")
		end
		restoreHUD()
		evidence.after = {
			civilizationId = latest.claim.civilizationId,
			plotId = latest.claim.plotId,
			coins = latest.state.coins,
			goods = copy(latest.state.goods),
			plans = copy(latest.state.plans),
			buildings = buildingProgress(latest.state),
			revision = latest.revision,
			claimEpoch = latest.claimEpoch,
			sessionId = latest.sessionId,
		}
		evidence.characterChanged, evidence.deathObserved, evidence.progressPreserved = true, true, true
		evidence.cameraMode, evidence.cameraSubjectIsNewHumanoid =
			screen:GetAttribute("CameraMode"), camera.CameraSubject == humanoid
		evidence.ghostCleared, evidence.oldPlacementControlsHidden, evidence.ok =
			true, not screen.PlacementControls.Visible, true
		return evidence
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	Replicated:SetAttribute("NativeLifecycleAwaitingDeath", false)
	if deathConnection then
		deathConnection:Disconnect()
	end
	connection:Disconnect()
	Replicated:SetAttribute("NativeLifecyclePassed", ok)
	Replicated:SetAttribute(
		"NativeLifecycleJSON",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, result)
	return result
end

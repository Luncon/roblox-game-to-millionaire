--!strict
-- Native Client fixture for the separate injected-fake-store sandbox.
-- Every civilization change uses chooser clicks; no mutation remote is fired.
-- Relocation centers the commander for a separate real W-key walking assertion.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Kit tour UI missing")
	local Civilizations = require(Replicated.MiniatureGame.Civilizations)
	local Presentation = require(Replicated.MiniatureGame.Presentation)
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest, spartaBefore
	local receipts = {}
	local evidence = {
		nativeVirtualInput = true,
		relocationWasFixtureSetup = true,
		transitions = {},
		civilizations = {},
		localRenderInjection = false,
	}
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
	local function clickPoint(point)
		input:SendMousePosition(point)
		task.wait(0.05)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local function click(button)
		assert(button and button.Visible and button.Active, "Kit tour button unavailable")
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
	local function navigate(page)
		restoreHUD()
		click(screen.SettlementHUD.Navigation[page .. "Navigation"])
		waitFor(function()
			return screen[page].Visible
		end, "Kit tour navigation failed: " .. page)
	end
	local function ledger(view)
		return {
			civilizationId = view.claim and view.claim.civilizationId,
			plotId = view.claim and view.claim.plotId,
			coins = view.state and view.state.coins,
			goods = view.state and copy(view.state.goods),
			revision = view.revision,
			claimEpoch = view.claimEpoch,
		}
	end
	local function choose(id)
		local before = ledger(latest)
		if not screen.Select.Visible then
			if latest.state then
				navigate("Settlement")
				press("Settlement", "ChooseCivilization")
			else
				restoreHUD()
				click(screen.SettlementHUD.Navigation.SettlementNavigation)
			end
		end
		waitFor(function()
			return screen.Select.Visible
		end, "Civilization chooser missing")
		local key = "Select" .. (if id == "sparta" then "Sparta" else id)
		for attempt = 1, 3 do
			local previous = #receipts
			press("Select", key)
			waitFor(function()
				return #receipts > previous
			end, "No selection receipt: " .. id)
			local packet = receipts[#receipts]
			table.insert(evidence.transitions, {
				before = before,
				after = ledger(packet.snapshot),
				civilization = id,
				attempt = attempt,
				requestId = packet.requestId,
				result = copy(packet.result),
			})
			if packet.result.ok then
				waitFor(function()
					return latest.claim and latest.claim.civilizationId == id and latest.artReady
				end, "Wrong selection snapshot: " .. id)
				if before.plotId then
					assert(latest.claim.plotId == before.plotId, "Switch moved the owned plot")
				end
				return
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				"Selection refused: " .. tostring(packet.result.reason)
			)
			task.wait(0.3)
		end
		error("Selection attempts exhausted: " .. id)
	end
	local function previewCivilization(viewport, id, role)
		assert(viewport and viewport:IsA("ViewportFrame") and viewport.CurrentCamera, "Missing actual model viewport")
		local world = viewport:FindFirstChildOfClass("WorldModel")
		local model = world and world:FindFirstChildOfClass("Model")
		assert(model and model:GetAttribute("CivilizationId") == id, "Foreign model preview substituted for " .. id)
		if role then
			assert(
				model:GetAttribute("RosterRole") == role and model:GetAttribute("PresentationOnly"),
				"Wrong role preview"
			)
		end
		for _, item in model:GetDescendants() do
			assert(
				not item:IsA("LuaSourceContainer") and not item:IsA("ClickDetector") and not item:IsA("ProximityPrompt"),
				"Active preview content"
			)
		end
		return model
	end
	local function progress(state)
		local buildings = {}
		for _, building in state.buildings do
			buildings[building.id] =
				{ kind = building.kind, x = building.x, z = building.z, rotation = building.rotation }
		end
		return {
			buildings = buildings,
			plans = copy(state.plans),
			workers = copy(state.workers),
			hallUpgraded = state.hallUpgraded,
			completed = copy(state.research.completed),
			roster = copy(state.roster),
			settings = copy(state.settings),
		}
	end
	local function preserveSparta()
		assert(latest.state and latest.claim.civilizationId == "sparta", "Tour did not return to Sparta")
		local before, after = progress(spartaBefore.state), progress(latest.state)
		assert(equal(before.buildings, after.buildings), "Spartan building progression changed during tour")
		assert(
			equal(before.plans, after.plans) and equal(before.workers, after.workers),
			"Spartan plans/workforce changed during tour"
		)
		assert(
			before.hallUpgraded == after.hallUpgraded
				and equal(before.roster, after.roster)
				and equal(before.settings, after.settings),
			"Spartan hall/roster/settings changed during tour"
		)
		for id in before.completed do
			assert(after.completed[id], "Spartan completed research regressed: " .. id)
		end
		local project = spartaBefore.state.research.project
		if project then
			local restored = latest.state.research.project
			assert(
				latest.state.research.completed[project.id]
					or restored and restored.id == project.id and restored.remaining <= project.remaining + 0.01,
				"Spartan project lost or reset"
			)
		end
		assert(latest.state.coins >= spartaBefore.state.coins, "Tour spent Spartan coins without an economic action")
		evidence.sparta = {
			before = ledger(spartaBefore),
			after = ledger(latest),
			progressPreserved = true,
			naturalProductionAndAutomationMaySettle = true,
			buildingCount = #latest.state.buildings,
			workerCount = #latest.state.workers,
			researchBefore = copy(spartaBefore.state.research),
			researchAfter = copy(latest.state.research),
		}
	end
	local ok, result = pcall(function()
		assert(
			Replicated:GetAttribute("MiniatureSandboxReady")
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong kit tour boundary"
		)
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.artKits
		end, "Kit tour snapshot missing")
		evidence.initial = ledger(latest)
		local available = {}
		for _, civilization in Civilizations do
			if latest.artKits[civilization.id] then
				local owner = latest.claims[civilization.id]
				assert(
					not owner or not owner.ownerId or owner.ownerId == player.UserId,
					"Kit tour requires solo/free civilizations: " .. civilization.id
				)
				table.insert(available, civilization.id)
			end
		end
		assert(table.find(available, "sparta"), "Sparta must be available for preservation check")
		for _, id in available do
			evidence.lastStep = "select " .. id
			choose(id)
			if id == "sparta" then
				spartaBefore = copy(latest)
			end
			local record = ledger(latest)
			record.civilizationId = id
			local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
			waitFor(function()
				return plot:GetAttribute("CivilizationId") == id
					and plot:GetAttribute("ArtReady")
					and #plot.Buildings:GetChildren() == #latest.state.buildings
			end, "World kit not rendered: " .. id)
			assert(plot:GetAttribute("OwnerId") == player.UserId, "Foreign plot owner")
			for _, building in plot.Buildings:GetChildren() do
				assert(
					building:GetAttribute("CivilizationId") == id and building:GetAttribute("OwnerId") == player.UserId,
					"Foreign active world building"
				)
				assert(
					building:GetAttribute("BuildingId") and math.abs(building:GetScale() - 0.25) < 0.001,
					"World building identity/scale missing"
				)
			end
			record.worldBuildings = #plot.Buildings:GetChildren()
			navigate("Build")
			press("Build", "Category_Homes")
			local preview = screen.Build.Content:FindFirstChild("BuildingPreview")
			previewCivilization(preview, id)
			record.previewCivilizationId = id
			local title = screen.Build.Content:FindFirstChild("Title_house")
			assert(
				title and title.Text == Presentation.buildingName(id, "house"),
				"House label does not match active civilization"
			)
			record.houseLabel = title.Text
			navigate("Army")
			local actorPreviews = 0
			for _, role in { "melee", "ranged", "medic" } do
				local viewport = screen.Army.Content:FindFirstChild("RolePreview_" .. role)
				if options.requireRolePreviews or viewport then
					previewCivilization(viewport, id, role)
					actorPreviews += 1
				end
				local roleLabel = screen.Army.Content:FindFirstChild("Draft_" .. role)
				assert(
					roleLabel and string.find(roleLabel.Text, Presentation.roleName(id, role), 1, true),
					"Role label does not match active civilization"
				)
			end
			record.rolePreviews = actorPreviews
			for _, page in { "Settlement", "Build", "Army", "Inspector" } do
				if screen[page].Visible then
					click(screen[page].Close)
				end
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			assert(
				root and humanoid and humanoid.Health > 0 and math.abs(character:GetScale() - 1) < 0.001,
				"Normal living commander missing"
			)
			assert(
				not character:FindFirstChildOfClass("Tool") and not player.Backpack:FindFirstChildOfClass("Tool"),
				"Commander was armed"
			)
			character:PivotTo(latest.plotFrame * CFrame.new(0, 4, 12))
			click(screen.CameraControls.Walk)
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 6, 14), root.Position + Vector3.new(0, 0, -10))
			task.wait(0.25)
			clickPoint(workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.6))
			local began = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(1)
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.2)
			local walked = root.Position - began
			record.walkDistance = Vector3.new(walked.X, 0, walked.Z).Magnitude
			record.verticalChange = walked.Y
			assert(record.walkDistance > 5, "Native walk blocked: " .. id)
			record.commanderScale, record.unarmed = character:GetScale(), true
			if options.inspectFarm then
				character:PivotTo(latest.plotFrame * CFrame.new(8, 4, -2))
				click(screen.CameraControls.Overview)
				task.wait(0.3)
				local farm = plot.Buildings.b3
				local point, shown = workspace.CurrentCamera:WorldToViewportPoint(farm.SelectTarget.Position)
				assert(shown, "Tour farm outside overview")
				clickPoint(Vector2.new(point.X, point.Y))
				waitFor(function()
					return screen.Inspector.Visible and screen:GetAttribute("InspectedBuilding") == "b3"
				end, "Native farm inspection failed: " .. id)
				record.farmWorldInspection = true
			end
			table.insert(evidence.civilizations, record)
			Replicated:SetAttribute(
				"KitTourProgressJSON",
				Http:JSONEncode({ completed = #evidence.civilizations, total = #available, civilizationId = id })
			)
		end
		evidence.lastStep = "restore Sparta"
		choose("sparta")
		preserveSparta()
		evidence.available, evidence.verified = #available, #evidence.civilizations
		evidence.ok = true
		return evidence
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	if not ok and spartaBefore and latest and latest.claim and latest.claim.civilizationId ~= "sparta" then
		local restored, reason = pcall(function()
			choose("sparta")
			preserveSparta()
		end)
		evidence.restoredAfterFailure, evidence.restoreError = restored, if restored then nil else tostring(reason)
	end
	connection:Disconnect()
	Replicated:SetAttribute(
		"KitTourJSON",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, result)
	return result
end

--!strict
-- Run after InventoryFlow in the same isolated fake-store native Play.
-- Layouts mount the real modules against a read-only authoritative snapshot.
-- Mutations use actual UI. Root alone performs the explicitly signalled death.
return function()
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Inventory guards UI missing")
	local modules = player.PlayerScripts.MiniatureGame
	local UI, Inventory = require(modules.UI), require(modules.Inventory)
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	local input = Input:CreateVirtualInput()
	local deadline = os.clock() + 180
	local latest, layoutGui, deathConnection
	local receipts = {}
	local evidence = { nativeVirtualInput = true, localStateMutation = false, localRelocation = false, layouts = {} }
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function waitFor(predicate, label, seconds)
		local untilTime = math.min(deadline, os.clock() + (seconds or 15))
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() > untilTime
		error(label)
	end
	local function step(label)
		evidence.lastStep = label
		Replicated:SetAttribute("MiniatureInventoryGuardsProgress", label)
	end
	local function copy(value)
		if type(value) ~= "table" then
			return value
		end
		local result = {}
		for key, item in value do
			result[key] = copy(item)
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
	local function progress(view)
		local buildings = {}
		for _, building in view.state.buildings do
			buildings[building.id] =
				{ kind = building.kind, x = building.x, z = building.z, rotation = building.rotation }
		end
		return {
			coins = view.state.coins,
			goods = copy(view.state.goods),
			plans = copy(view.state.plans),
			buildings = buildings,
			workers = copy(view.state.workers),
			hallUpgraded = view.state.hallUpgraded,
			completed = copy(view.state.research.completed),
			roster = copy(view.state.roster),
			settings = copy(view.state.settings),
		}
	end
	local function ledger(view)
		return {
			coins = view.state.coins,
			plans = copy(view.state.plans),
			goods = copy(view.state.goods),
			buildingCount = #view.state.buildings,
			civilianCount = #view.state.workers,
			claimEpoch = view.claimEpoch,
			plotId = view.claim.plotId,
			civilizationId = view.claim.civilizationId,
		}
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
		waitFor(function()
			return button and button.Visible and button.Active
		end, "Inventory guards control unavailable: " .. (button and button:GetFullName() or "missing"))
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function press(page, name)
		local body = screen[page].Content
		waitFor(function()
			local button = body:FindFirstChild(name)
			return button and button.Visible and button.Active
		end, "Unavailable " .. page .. "." .. name)
		local button = body[name]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		click(body[name])
	end
	local function action(page, name, label)
		for attempt = 1, 3 do
			local before = #receipts
			press(page, name)
			waitFor(function()
				return #receipts > before
			end, "No receipt: " .. label)
			local packet = receipts[#receipts]
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			task.wait(0.3)
		end
		error("Inventory guards attempts exhausted: " .. label)
	end
	local function closePanels()
		for _, name in { "Settlement", "Build", "Trade", "Research", "Army", "Inspector", "Inventory", "Select" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible then
				click(panel.Close)
			end
		end
	end
	local function travel(buttonName, destination)
		local before = #receipts
		click(screen.TopNavigation[buttonName])
		waitFor(function()
			return #receipts > before
		end, "No travel receipt: " .. destination)
		local packet = receipts[#receipts]
		assert(packet.result.ok and packet.result.destination == destination, "Server travel failed: " .. destination)
		local panel = if destination == "buy" then "Build" elseif destination == "sell" then "Trade" else "Settlement"
		waitFor(function()
			return screen[panel].Visible
		end, "Travel did not open " .. panel)
	end
	local function choose(id)
		travel("Civilization", "civilization")
		press("Settlement", "ChooseCivilization")
		local packet = action("Select", "Select" .. (if id == "sparta" then "Sparta" else id), "choose " .. id)
		assert(packet.snapshot.claim.civilizationId == id, "Wrong civilization restored")
		return packet.snapshot
	end
	local function inside(object, frame)
		local p, size, fp, fs = object.AbsolutePosition, object.AbsoluteSize, frame.AbsolutePosition, frame.AbsoluteSize
		return p.X >= fp.X - 1
			and p.Y >= fp.Y - 1
			and p.X + size.X <= fp.X + fs.X + 1
			and p.Y + size.Y <= fp.Y + fs.Y + 1
	end
	local function overlaps(a, b)
		local p, s, q, t = a.AbsolutePosition, a.AbsoluteSize, b.AbsolutePosition, b.AbsoluteSize
		return p.X < q.X + t.X - 1 and q.X < p.X + s.X - 1 and p.Y < q.Y + t.Y - 1 and q.Y < p.Y + s.Y - 1
	end
	local ok, result = pcall(function()
		assert(
			game:GetService("RunService"):IsStudio()
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong inventory guards boundary"
		)
		local previousFlow = Replicated:GetAttribute("MiniatureInventoryFlowResult")
		assert(previousFlow and Http:JSONDecode(previousFlow).ok, "Run passing InventoryFlow first in the same Play")
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.claim and latest.state
		end, "Inventory guards snapshot missing")
		assert(latest.claim.civilizationId == "sparta", "Inventory guards begins on Sparta after InventoryFlow")
		assert(
			not latest.state.settings.autoCollect and not latest.state.settings.autoSell,
			"Fixture needs manual goods inventory"
		)
		step("four bounded real-module layouts")
		layoutGui = Instance.new("ScreenGui")
		layoutGui.Name, layoutGui.DisplayOrder, layoutGui.Parent = "InventoryGuardLayouts", 100, player.PlayerGui
		for _, size in { Vector2.new(320, 360), Vector2.new(320, 568), Vector2.new(640, 360), Vector2.new(1024, 768) } do
			local shell = Instance.new("Frame")
			shell.Size, shell.Parent = UDim2.fromOffset(size.X, size.Y), layoutGui
			local ui = UI.mount(shell, {
				send = function()
					error("Bounded layout must never send a mutation")
				end,
				camera = function() end,
				place = function() end,
			})
			local inventory = Inventory.start(shell, {
				guard = ui.guard,
				closePanels = ui.closePanels,
				message = ui.message,
				cancelPlacement = function() end,
				place = function()
					error("Bounded layout must never start authoritative placement")
				end,
			})
			ui.update(latest, true)
			inventory.update(latest, true)
			task.wait(0.2)
			local count = 0
			for _, button in shell.TopNavigation:GetChildren() do
				if button:IsA("TextButton") then
					count += 1
					assert(table.find({ "Buy", "Civilization", "Sell" }, button.Name), "Unexpected top navigation")
					assert(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44, "Small top travel target")
				end
			end
			assert(count == 3, "Top navigation must contain exactly three buttons")
			for _, name in { "TopNavigation", "SettlementHUD", "Hotbar", "CameraControls", "InventoryToggle" } do
				assert(inside(shell[name], shell), "Layout control outside bounds: " .. name .. " " .. tostring(size))
			end
			assert(not overlaps(shell.CameraControls, shell.InventoryToggle), "Camera and inventory controls overlap")
			assert(not overlaps(shell.CameraControls, shell.Hotbar), "Camera and hotbar overlap")
			assert(not overlaps(shell.InventoryToggle, shell.Hotbar), "Inventory toggle and hotbar overlap")
			for _, page in { "Settlement", "Build", "Trade", "Research", "Army", "Select" } do
				ui.navigate(page)
				task.wait(0.1)
				assert(inside(shell[page], shell), "Page outside bounds: " .. page)
				for _, button in shell[page]:GetDescendants() do
					if button:IsA("TextButton") then
						assert(
							button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44,
							"Small page target: " .. button.Name
						)
					end
				end
			end
			inventory.toggle()
			task.wait(0.1)
			assert(shell.Inventory.Visible and inside(shell.Inventory, shell), "Inventory panel outside bounds")
			local planControls = 0
			for kind in Catalog.buildings do
				local button = shell.Inventory.Content:FindFirstChild("Plan_" .. kind)
				assert(
					button and button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44,
					"Missing/small inventory plan: " .. kind
				)
				planControls += 1
			end
			for _, good in Catalog.goods do
				assert(
					shell.Inventory.Content:FindFirstChild("Goods_" .. good),
					"Collected-good inventory label missing"
				)
			end
			for index = 1, 9 do
				local slot = shell.Hotbar.Content:FindFirstChild("Slot" .. index)
				assert(slot and slot.AbsoluteSize.X >= 44 and slot.AbsoluteSize.Y >= 44, "Missing/small hotbar slot")
			end
			table.insert(
				evidence.layouts,
				{ width = size.X, height = size.Y, topButtons = count, planControls = planControls, hotbarSlots = 9 }
			)
			shell:Destroy()
		end
		layoutGui:Destroy()
		layoutGui = nil
		step("actual Rome to Sparta preservation")
		local before = copy(latest)
		evidence.switch = { before = ledger(before) }
		local rome = choose("rome")
		assert(rome.claim.plotId == before.claim.plotId, "Rome switch changed owned plot")
		assert(not equal(progress(rome), progress(before)), "Distinct Roman state was not loaded")
		task.wait(1)
		local restored = choose("sparta")
		assert(
			restored.sessionId == before.sessionId and restored.claim.plotId == before.claim.plotId,
			"Switch changed session/plot"
		)
		assert(equal(progress(before), progress(restored)), "Civilization switch changed saved inventory/progress")
		evidence.switch.after, evidence.switch.preserved = ledger(restored), true
		step("buy held house item for death placement draft")
		travel("Buy", "buy")
		press("Build", "Category_Homes")
		local purchaseCoins, purchasePlans = latest.state.coins, latest.state.plans.house
		assert(purchaseCoins >= 80, "Insufficient earned coins for explicit house purchase")
		local purchase = action("Build", "Buy_house", "buy death-check house")
		assert(
			purchase.snapshot.state.coins == purchaseCoins - 80
				and purchase.snapshot.state.plans.house == purchasePlans + 1,
			"House purchase ledger mismatch"
		)
		evidence.deathPurchase =
			{ coinsBefore = purchaseCoins, coinsAfter = latest.state.coins, plansAfter = latest.state.plans.house }
		travel("Civilization", "civilization")
		closePanels()
		click(screen.InventoryToggle)
		press("Inventory", "Plan_house")
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == "house"
				and screen:GetAttribute("SelectedInventoryItem") == "house"
				and workspace:FindFirstChild("LocalPlacementFootprint")
		end, "Held house did not open a real placement draft")
		click(screen.CameraControls.Overview)
		local oldCharacter = player.Character
		local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
		assert(oldHumanoid and oldHumanoid.Health > 0, "Living old commander missing")
		local died = false
		deathConnection = oldHumanoid.Died:Connect(function()
			died = true
		end)
		before = copy(latest)
		evidence.death = { before = ledger(before) }
		step("waiting for root explicit owned server Humanoid death")
		Replicated:SetAttribute("MiniatureInventoryDeathOwnerId", player.UserId)
		Replicated:SetAttribute("MiniatureInventoryDeathReady", true)
		waitFor(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return character
				and character ~= oldCharacter
				and humanoid
				and humanoid.Health > 0
				and character:FindFirstChild("HumanoidRootPart")
		end, "New living character did not arrive after explicit death", 35)
		Replicated:SetAttribute("MiniatureInventoryDeathReady", false)
		assert(died or oldHumanoid.Health <= 0, "No actual death observed")
		local character = player.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		waitFor(function()
			local camera = workspace.CurrentCamera
			return latest.claimEpoch > before.claimEpoch
				and screen:GetAttribute("CameraMode") == "Walk"
				and camera.CameraType == Enum.CameraType.Custom
				and camera.CameraSubject == humanoid
		end, "New-life authority/camera did not recover")
		assert(
			not screen:GetAttribute("PlacingKind")
				and not screen:GetAttribute("SelectedInventoryItem")
				and not screen:GetAttribute("HammerSelected"),
			"New life retained item selection"
		)
		assert(
			not workspace:FindFirstChild("LocalPlacementFootprint") and not screen.PlacementControls.Visible,
			"New life retained placement ghost"
		)
		assert(
			before.sessionId == latest.sessionId
				and before.claim.plotId == latest.claim.plotId
				and latest.claim.civilizationId == "sparta",
			"Death changed saved session or claim"
		)
		assert(equal(progress(before), progress(latest)), "Death changed saved coins/plans/goods/buildings/civilians")
		assert(
			math.abs(character:GetScale() - 1) < 0.001
				and not character:FindFirstChildOfClass("Tool")
				and not player.Backpack:FindFirstChildOfClass("Tool"),
			"New commander miniaturized or armed"
		)
		step("actual new-life W movement")
		closePanels()
		click(screen.CameraControls.Walk)
		local root = character.HumanoidRootPart
		workspace.CurrentCamera.CFrame =
			CFrame.lookAt(root.Position + Vector3.new(0, 6, 14), root.Position + Vector3.new(0, 0, -10))
		task.wait(0.25)
		clickPoint(workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.6))
		local began = root.Position
		input:SendKey(true, Enum.KeyCode.W, false)
		task.wait(1)
		local direction = humanoid.MoveDirection
		input:SendKey(false, Enum.KeyCode.W, false)
		task.wait(0.2)
		local delta = root.Position - began
		local walked = Vector3.new(delta.X, 0, delta.Z).Magnitude
		assert(walked > 5, "New-life W movement was blocked")
		evidence.death.after = ledger(latest)
		evidence.death.defaultMovementUntouched = true
		evidence.death.horizontalWalk, evidence.death.verticalChange = walked, delta.Y
		evidence.death.moveDirection = { x = direction.X, y = direction.Y, z = direction.Z }
		evidence.death.ghostCleared, evidence.death.selectionCleared, evidence.death.progressPreserved =
			true, true, true
		evidence.ok = true
		return evidence
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	Replicated:SetAttribute("MiniatureInventoryDeathReady", false)
	if layoutGui then
		layoutGui:Destroy()
	end
	if deathConnection then
		deathConnection:Disconnect()
	end
	connection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureInventoryGuardsResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, tostring(result))
	return result
end

--!strict
-- Native Client fixture for a fresh, solo, injected-fake-store sandbox.
-- Mutations use real UI/key/click input. Snapshot is the only remote fired here.
-- Travel uses the real top buttons and server arrivals; no local state or funding injection.
-- A stale-revision refusal permits at most two additional explicit fixture presses.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local Input = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Inventory UI missing")
	local input = Input:CreateVirtualInput()
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(actions, "Inventory action boundary missing")
	local latest, probeGui
	local receipts = {}
	local deadline = os.clock() + 115
	local evidence = {
		nativeVirtualInput = true,
		serverTravelButtons = true,
		localRenderInjection = false,
		localRelocation = false,
		fakeFunding = false,
		steps = {},
		attempts = {},
		retry = {},
	}
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function waitFor(predicate, label, seconds)
		local untilTime = math.min(deadline, os.clock() + (seconds or 12))
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
		table.insert(evidence.steps, label)
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.1)
		input:SendKey(false, code, false)
		task.wait(0.2)
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
		assert(button and button.Visible and button.Active, "Inventory fixture button unavailable")
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
	local function accepted(previous, label, retryPress)
		for attempt = 1, 3 do
			waitFor(function()
				return #receipts > previous
			end, "No receipt: " .. label)
			local packet = receipts[previous + 1]
			table.insert(evidence.attempts, {
				label = label,
				attempt = attempt,
				requestId = packet.requestId,
				ok = packet.result.ok == true,
				reason = packet.result.reason,
				revision = packet.snapshot and packet.snapshot.revision,
			})
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and retryPress and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			assert(
				packet.snapshot and type(packet.snapshot.revision) == "number",
				"Stale refusal omitted fresh snapshot"
			)
			waitFor(function()
				return latest
					and latest.sessionId == packet.snapshot.sessionId
					and latest.claimEpoch == packet.snapshot.claimEpoch
					and latest.revision >= packet.snapshot.revision
					and (screen:GetAttribute("Revision") or -1) >= packet.snapshot.revision
			end, "UI did not adopt fresh refusal snapshot: " .. label)
			task.wait(0.1)
			table.insert(evidence.retry, {
				label = label,
				attempt = attempt + 1,
				reason = packet.result.reason,
				freshRevision = latest.revision,
				explicitNativePress = true,
			})
			previous = #receipts
			retryPress()
		end
		error("Inventory attempts exhausted: " .. label)
	end
	local function building(id)
		for _, item in latest.state.buildings do
			if item.id == id then
				return item
			end
		end
		return nil
	end
	local function population(total, assigned)
		assert(#latest.state.workers == total, "Unexpected automatic civilian population")
		local count = 0
		for _, worker in latest.state.workers do
			if worker.buildingId then
				assert(building(worker.buildingId), "Civilian retained a removed job")
				count += 1
			end
		end
		assert(count == assigned, "Unexpected automatic civilian assignments")
		return { total = total, assigned = count, idle = total - count }
	end
	local function rootPart()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		assert(root and humanoid and humanoid.Health > 0, "Living commander missing")
		assert(math.abs(character:GetScale() - 1) < 0.001, "Commander miniaturized")
		assert(
			not character:FindFirstChildOfClass("Tool") and not player.Backpack:FindFirstChildOfClass("Tool"),
			"Commander armed"
		)
		return root
	end
	local function closePanels()
		for _, name in { "Settlement", "Build", "Trade", "Research", "Army", "Inspector", "Inventory" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible and panel:FindFirstChild("Close") then
				click(panel.Close)
			end
		end
	end
	local function travel(buttonName, destination, position)
		local function pressTravel()
			waitFor(function()
				return screen.TopNavigation[buttonName].Active
			end, "Travel button unavailable: " .. destination)
			click(screen.TopNavigation[buttonName])
		end
		local previous = #receipts
		pressTravel()
		local packet = accepted(previous, "travel " .. destination, pressTravel)
		assert(packet.result.destination == destination, "Wrong server travel destination")
		waitFor(function()
			return (rootPart().Position - position).Magnitude < 12
		end, "Server travel did not reach " .. destination)
		return packet
	end
	local function walkToFarm()
		closePanels()
		click(screen.CameraControls.Walk)
		local root = rootPart()
		local target = latest.plotFrame:PointToWorldSpace(Vector3.new(8, 3, -2))
		local delta = target - root.Position
		local planar = Vector3.new(delta.X, 0, delta.Z)
		assert(planar.Magnitude > 5, "Walking fixture began too close to farm")
		local direction = planar.Unit
		workspace.CurrentCamera.CFrame =
			CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
		task.wait(0.25)
		clickPoint(workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.6))
		local began = root.Position
		input:SendKey(true, Enum.KeyCode.W, false)
		task.wait(math.min(3, planar.Magnitude / 16))
		input:SendKey(false, Enum.KeyCode.W, false)
		task.wait(0.25)
		local walked = root.Position - began
		local distance = Vector3.new(walked.X, 0, walked.Z).Magnitude
		assert(distance > 5, "Native W walking blocked after focus")
		local farmPoint = latest.plotFrame:PointToWorldSpace(Vector3.new(8, 0.4, -8))
		assert((root.Position - farmPoint).Magnitude < 12, "Native walk did not reach farm prompt")
		return distance
	end
	local function ownedSlot(kind)
		for _, slot in screen.Hotbar.Content:GetChildren() do
			if slot:IsA("TextButton") and slot:GetAttribute("ItemKind") == kind then
				return slot
			end
		end
		error("Owned item missing from hotbar: " .. kind)
	end
	local function assertVisibleWorkers(total)
		local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		waitFor(function()
			local count = 0
			for _, actor in plot.Actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "worker" then
					count += 1
					assert(math.abs(actor:GetScale() - 0.25) < 0.001, "Wrong visible civilian scale")
				end
			end
			return count == total
		end, "Automatic civilians not rendered")
	end
	local ok, result = pcall(function()
		assert(
			game:GetService("RunService"):IsStudio()
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong inventory fixture boundary"
		)
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Inventory snapshot missing")
		step("select fresh civilization")
		if not latest.claim then
			local previous = #receipts
			press("Select", "SelectSparta")
			accepted(previous, "select Sparta", function()
				press("Select", "SelectSparta")
			end)
		end
		assert(latest.claim.civilizationId == "sparta", "Inventory fixture requires fresh Sparta")
		assert(
			latest.state.coins == 200 and #latest.state.buildings == 3,
			"Fresh default economy required; no funded fixture"
		)
		for _, amount in latest.state.goods do
			assert(amount == 0, "Fresh empty goods required")
		end
		evidence.initialPopulation = population(4, 2)
		assertVisibleWorkers(4)
		if options.waitForScene ~= false then
			step("retain starter state for native scene observation")
			waitFor(function()
				return Replicated:GetAttribute("MiniatureGameSceneResult") ~= nil
			end, "Starter scene check did not finish", 30)
			local sceneResult = Http:JSONDecode(Replicated:GetAttribute("MiniatureGameSceneResult"))
			assert(sceneResult.ok, "Starter scene failed: " .. tostring(sceneResult.result))
		end
		for _, old in
			{
				"HireWorker",
				"AssignWorker",
				"MoveBuilding",
				"UnpackBuilding",
				"Collect1",
				"Collect10",
				"SaleQuantity",
				"Sell10",
				"SellQuantity",
			}
		do
			assert(not screen:FindFirstChild(old, true), "Retired control remains: " .. old)
		end
		assert(
			screen.TopNavigation.Buy and screen.TopNavigation.Sell and screen.TopNavigation.Civilization,
			"Three top travel buttons missing"
		)
		local scene = workspace.MiniatureSandbox
		for _, identity in { "SharedBuyShop", "SharedSellShop" } do
			local shop = scene:FindFirstChild(identity)
			assert(
				shop
					and shop:GetAttribute(identity)
					and not shop:GetAttribute("OwnerId")
					and not shop:GetAttribute("CivilizationId"),
				"Shared shop incorrectly faction-owned"
			)
		end
		step("walk and collect all with E")
		evidence.walkDistance = walkToFarm()
		waitFor(function()
			return building("b3").output >= 2
		end, "Farm produced no collectable output", 15)
		local goodsBefore, previous = latest.state.goods.food, #receipts
		key(Enum.KeyCode.E)
		local collection = accepted(previous, "E collect all", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			collection.result.amount > 0 and latest.state.goods.food == goodsBefore + collection.result.amount,
			"Collection did not enter inventory"
		)
		assert(building("b3").output == 0, "E did not collect all available farm output")
		evidence.collection =
			{ amount = collection.result.amount, goodsAfter = latest.state.goods.food, outputAfter = 0 }
		step("server travel to shared sell stand and sell all")
		travel("Sell", "sell", latest.sellShopPosition)
		closePanels()
		key(Enum.KeyCode.E)
		waitFor(function()
			return screen.Trade.Visible
		end, "Sell prompt did not open Trade")
		local coinsBefore = latest.state.coins
		previous = #receipts
		press("Trade", "SellAll")
		local sale = accepted(previous, "SellAll", function()
			press("Trade", "SellAll")
		end)
		assert(
			sale.result.coins > 0 and latest.state.coins == coinsBefore + sale.result.coins,
			"SellAll did not credit coins"
		)
		for _, amount in latest.state.goods do
			assert(amount == 0, "SellAll retained collected goods")
		end
		evidence.sale = { coinsBefore = coinsBefore, coinsAfter = latest.state.coins, earned = sale.result.coins }
		step("server travel to shared buy stand and buy house item")
		travel("Buy", "buy", latest.buyShopPosition)
		closePanels()
		key(Enum.KeyCode.E)
		waitFor(function()
			return screen.Build.Visible
		end, "Buy prompt did not open Build")
		press("Build", "Category_Homes")
		coinsBefore, previous = latest.state.coins, #receipts
		local plansBefore = latest.state.plans.house
		press("Build", "Buy_house")
		accepted(previous, "buy house item", function()
			press("Build", "Buy_house")
		end)
		assert(
			latest.state.coins == coinsBefore - 80
				and latest.state.plans.house == plansBefore + 1
				and #latest.state.buildings == 3,
			"Purchase did not create a coin-only inventory item"
		)
		evidence.purchase = { price = 80, coinsAfter = latest.state.coins, plansAfter = latest.state.plans.house }
		step("return to civilization and select inventory item")
		travel("Civilization", "civilization", latest.plotFrame:PointToWorldSpace(Vector3.new(0, 3.1, 23)))
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "B did not open inventory")
		press("Inventory", "Plan_house")
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == "house"
		end, "Inventory house did not start placement")
		step("focused TextBox guards inventory, supported number and rotate hotkeys")
		probeGui = Instance.new("ScreenGui")
		probeGui.Name, probeGui.DisplayOrder, probeGui.Parent = "InventoryFocusProbe", 100, player.PlayerGui
		local probe = Instance.new("TextBox")
		probe.Name, probe.Text, probe.Size, probe.Position, probe.Parent =
			"FocusProbe", "", UDim2.fromOffset(240, 44), UDim2.fromOffset(12, 90), probeGui
		click(probe)
		waitFor(function()
			return Input:GetFocusedTextBox() == probe
		end, "Native TextBox focus missing")
		local placementText = screen.PlacementControls.PlacementStatus.Text
		for _, code in { Enum.KeyCode.B, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.R } do
			key(code)
		end
		assert(
			not screen.Inventory.Visible
				and screen:GetAttribute("SelectedInventoryItem") == "house"
				and screen:GetAttribute("PlacingKind") == "house",
			"Focused typing activated inventory hotkeys"
		)
		assert(screen.PlacementControls.PlacementStatus.Text == placementText, "Focused R changed placement rotation")
		probe:ReleaseFocus()
		probeGui:Destroy()
		probeGui = nil
		evidence.textBoxHotkeyGuard = true
		step("hammer hotbar selection cancels placement without consuming item")
		click(screen.Hotbar.Content.Slot1)
		assert(
			screen:GetAttribute("HammerSelected")
				and not screen:GetAttribute("PlacingKind")
				and not workspace:FindFirstChild("LocalPlacementFootprint"),
			"Hammer did not cancel placement"
		)
		assert(latest.state.plans.house == plansBefore + 1, "Hotbar cancellation consumed house item")
		click(ownedSlot("house"))
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == "house"
		end, "Hotbar house reselection failed")
		coinsBefore, previous = latest.state.coins, #receipts
		click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		accepted(previous, "place house item", function()
			waitFor(function()
				return screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
			end, "House placement did not refresh after refusal")
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		assert(
			latest.state.coins == coinsBefore
				and latest.state.plans.house == plansBefore
				and #latest.state.buildings == 4,
			"Placement charged again or lost item"
		)
		evidence.expandedPopulation = population(8, 2)
		assertVisibleWorkers(8)
		step("hammer reclaim nonempty farm into goods and building inventory")
		evidence.secondWalkDistance = walkToFarm()
		waitFor(function()
			return building("b3").output > 0
		end, "No output to reclaim", 15)
		local outputBefore = building("b3").output
		goodsBefore, coinsBefore = latest.state.goods.food, latest.state.coins
		local farmPlans = latest.state.plans.farm
		closePanels()
		if not screen:GetAttribute("HammerSelected") then
			click(screen.Hotbar.Content.Slot1)
		end
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local plot = scene.Plots["Plot" .. latest.claim.plotId]
		local point, shown = workspace.CurrentCamera:WorldToViewportPoint(plot.Buildings.b3.SelectTarget.Position)
		assert(shown, "Farm is outside hammer overview")
		previous = #receipts
		clickPoint(Vector2.new(point.X, point.Y))
		local reclaimed = accepted(previous, "hammer farm reclaim", function()
			local targetPoint, targetShown =
				workspace.CurrentCamera:WorldToViewportPoint(plot.Buildings.b3.SelectTarget.Position)
			assert(targetShown, "Farm moved outside hammer overview after refusal")
			clickPoint(Vector2.new(targetPoint.X, targetPoint.Y))
		end)
		assert(not building("b3") and latest.state.plans.farm == farmPlans + 1, "Hammer did not return farm item")
		assert(
			reclaimed.result.amount >= outputBefore
				and latest.state.goods.food == goodsBefore + reclaimed.result.amount
				and latest.state.coins == coinsBefore,
			"Hammer lost output or changed coins"
		)
		evidence.reclaimedPopulation = population(8, 0)
		evidence.reclaim =
			{ amount = reclaimed.result.amount, outputBefore = outputBefore, farmPlans = latest.state.plans.farm }
		step("replace reclaimed farm without extra cost and restore automatic jobs")
		click(ownedSlot("farm"))
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == "farm"
		end, "Reclaimed farm selection failed")
		point, shown =
			workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(8, 0, -8)))
		assert(shown, "Replacement ground outside overview")
		clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
		task.wait(0.2)
		previous = #receipts
		click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		accepted(previous, "replace farm item", function()
			waitFor(function()
				return screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
			end, "Farm placement did not refresh after refusal")
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		assert(
			latest.state.plans.farm == farmPlans and latest.state.coins == coinsBefore and #latest.state.buildings == 4,
			"Replacement cost or inventory mismatch"
		)
		local replacement = latest.state.buildings[#latest.state.buildings]
		assert(
			replacement.kind == "farm" and replacement.id ~= "b3" and replacement.x == 8 and replacement.z == -8,
			"Reclaimed farm not replaced on actual chosen ground"
		)
		evidence.restoredPopulation = population(8, 2)
		assertVisibleWorkers(8)
		evidence.replacement =
			{ buildingId = replacement.id, x = replacement.x, z = replacement.z, coinsUnchanged = true }
		evidence.hotbarCancellation, evidence.nativeSharedShops, evidence.ok = true, true, true
		return evidence
	end)
	for _, code in
		{ Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.B, Enum.KeyCode.R, Enum.KeyCode.One, Enum.KeyCode.Two }
	do
		pcall(function()
			input:SendKey(false, code, false)
		end)
	end
	if probeGui then
		probeGui:Destroy()
	end
	connection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureInventoryFlowResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, result)
	return result
end

--!strict
-- Real Client UI actions in the separately mapped ServicesBootstrap test place.
-- Funding, all nine completed research nodes and compact starter coordinates are
-- explicit fixture setup. No research-duration or ordinary starter pacing claim.
-- Commander PivotTo and TextBox selection are fixture setup; native clicks and
-- SendTextInput drive actions. No mutation remotes or balances are injected here.
-- Optional NativeCapacityFixture Edit attribute seeds 200 Timber, no Material
-- and 60 farm output on the server. Those goods are setup, not earned progress.
return function()
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	assert(Replicated:GetAttribute("MiniatureServicesFixture"), "Run only with ServicesBootstrap")
	local capacityFixture = Replicated:GetAttribute("NativeCapacityFixture") == true
	local expectedTimber = if capacityFixture then 200 else 80
	local expectedMaterial = if capacityFixture then 0 else 20
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Services UI missing")
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest
	local receipts = {}
	local evidence = { preUnlockedFakeSetup = true, realClocks = true, relocationWasFixtureSetup = true, receipts = {} }
	evidence.capacityFixture = capacityFixture
	evidence.seededGoods =
		{ timber = expectedTimber, material = expectedMaterial, farmOutput = if capacityFixture then 60 else 0 }
	local connection = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.result then
			table.insert(receipts, packet)
		end
	end)
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
		assert(button and button.Visible and button.Active, "Services button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function reveal(body, object)
		body.CanvasPosition =
			Vector2.new(0, math.max(0, object.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
	end
	local function press(page, key)
		local body = screen[page].Content
		waitFor(function()
			local button = body:FindFirstChild(key, true)
			return button and button.Visible and button.Active
		end, "Unavailable " .. page .. "." .. key)
		local button = body:FindFirstChild(key, true)
		reveal(body, button)
		click(button)
	end
	local function enter(page, key, value)
		local body = screen[page].Content
		local box = body:FindFirstChild(key, true)
		assert(box and box:IsA("TextBox"), "Missing input: " .. key)
		reveal(body, box)
		clickPoint(box.AbsolutePosition + box.AbsoluteSize / 2 + Gui:GetGuiInset())
		waitFor(function()
			return box:IsFocused()
		end, "Input did not focus: " .. key)
		box.CursorPosition, box.SelectionStart = #box.Text + 1, 1
		input:SendTextInput(tostring(value))
		task.wait(0.2)
		assert(box.Text == tostring(value), "Native text entry failed: " .. key)
	end
	local function navigate(page)
		if not screen.SettlementHUD.Visible and screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
		click(screen.SettlementHUD.Navigation[page .. "Navigation"])
		waitFor(function()
			return screen[page].Visible
		end, "Navigation failed: " .. page)
	end
	local function action(page, key, label)
		for attempt = 1, 3 do
			evidence.lastStep = label .. " attempt " .. attempt
			local before = #receipts
			press(page, key)
			waitFor(function()
				return #receipts > before
			end, "No receipt for " .. label)
			local packet = receipts[#receipts]
			table.insert(
				evidence.receipts,
				{ action = label, attempt = attempt, requestId = packet.requestId, result = packet.result }
			)
			if packet.result.ok then
				task.wait(0.2)
				return packet.result
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			assert(
				packet.snapshot
					and packet.snapshot.sessionId == latest.sessionId
					and packet.snapshot.claimEpoch == latest.claimEpoch,
				"Refused context changed"
			)
			task.wait(0.3)
		end
		error("Services attempts exhausted")
	end
	local function building(id)
		for _, item in latest.state.buildings do
			if item.id == id then
				return item
			end
		end
		return nil
	end
	local function worker(id)
		for _, item in latest.state.workers do
			if item.id == id then
				return item
			end
		end
		return nil
	end
	local function inventorySize()
		local amount = 0
		for _, good in { "food", "timber", "material", "crafted" } do
			amount += latest.state.goods[good]
		end
		return amount
	end
	local function nearby(id)
		local site = building(id)
		assert(site, "Missing site: " .. id)
		assert(player.Character and player.Character:FindFirstChild("HumanoidRootPart"), "Commander missing")
		player.Character:PivotTo(latest.plotFrame * CFrame.new(site.x, 4, site.z + 4))
		task.wait(0.3)
	end
	local function inspect(id)
		nearby(id)
		navigate("Settlement")
		press("Settlement", "Inspect_" .. id)
		waitFor(function()
			return screen.Inspector.Visible and screen:GetAttribute("InspectedBuilding") == id
		end, "Inspector failed")
	end
	local function buyPlace(kind, category, x, z, rotation)
		nearby("b1")
		navigate("Build")
		press("Build", "Category_" .. category)
		action("Build", "Buy_" .. kind, "buy " .. kind)
		press("Build", "Place_" .. kind)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == kind
		end, "Placement draft missing")
		for _, page in { "Settlement", "Build", "Inspector", "Trade", "Research", "Army", "Select" } do
			if screen[page].Visible then
				click(screen[page].Close)
			end
		end
		click(screen.CameraControls.Overview)
		if screen.SettlementHUD.Visible then
			click(screen.SettlementHUD.MinimizePanel)
		end
		task.wait(0.3)
		local point, shown =
			workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
		assert(shown, "Placement point outside camera")
		clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
		if rotation == 90 then
			click(screen.PlacementControls.PlacementActions.Rotate)
		end
		local result
		for attempt = 1, 3 do
			local before = #receipts
			waitFor(function()
				return screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
			end, "Placement invalid")
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
			waitFor(function()
				return #receipts > before
			end, "Placement receipt missing")
			local packet = receipts[#receipts]
			table.insert(
				evidence.receipts,
				{ action = "place " .. kind, attempt = attempt, requestId = packet.requestId, result = packet.result }
			)
			if packet.result.ok then
				result = packet.result
				break
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				"Placement refused: " .. tostring(packet.result.reason)
			)
			task.wait(0.3)
		end
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == nil
		end, "Placement ghost retained")
		if screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
		local site = result and building(result.buildingId)
		assert(
			site and site.kind == kind and site.x == x and site.z == z and site.rotation == rotation,
			"Wrong placed site"
		)
		return site.id
	end

	local ok, result = pcall(function()
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded
		end, "Initial snapshot missing")
		if not latest.claim then
			action("Select", "SelectSparta", "select Sparta")
		end
		assert(latest.claim.civilizationId == "sparta", "Services fixture requires Sparta")
		assert(
			latest.state.coins == 5000
				and latest.state.goods.timber == expectedTimber
				and latest.state.goods.material == expectedMaterial
				and #latest.state.buildings == 3,
			"Restart untouched Services Play"
		)
		if capacityFixture then
			assert(inventorySize() == 200 and building("b3").output == 60, "Capacity seed must start exactly full")
		end
		assert(
			latest.state.hallUpgraded
				and latest.state.research.completed.trade
				and latest.state.research.completed.supply
				and latest.state.research.completed.store,
			"Pre-unlocked setup missing"
		)
		local timber = buyPlace("timber", "Production", 6, 6, 0)
		local store = buyPlace("storehouse", "Civic", -6, 6, 90)
		waitFor(function()
			return string.find(screen.SettlementHUD.Resources.Text, "/400", 1, true) ~= nil
		end, "Storehouse did not display400 capacity")
		evidence.storage = { buildingId = store, displayedGoodsCapacity = 400, serverPlacementAccepted = true }
		local training = buyPlace("training", "Military", -14, -10, 90)
		local healer = buyPlace("healer", "Military", -16, 12, 0)
		nearby("b1")
		navigate("Settlement")
		local hireCoins = latest.state.coins
		local hired = action("Settlement", "HireWorker", "hire service worker")
		assert(#latest.state.workers == 3 and latest.state.coins == hireCoins - 25, "Wrong worker hire cost")
		inspect(timber)
		action("Inspector", "Assign_" .. hired.workerId, "assign timber worker")
		local assignedAt = os.clock()
		waitFor(function()
			return building(timber).output >= 1
		end, "No real nine-second timber batch", 20)
		local beforeTimber, output = latest.state.goods.timber, building(timber).output
		action("Inspector", "CollectAll", "collect timber")
		assert(
			latest.state.goods.timber == beforeTimber + output and building(timber).output == 0,
			"Timber collection lost goods"
		)
		evidence.timber = {
			buildingId = timber,
			workerId = hired.workerId,
			secondsToFirstBatch = os.clock() - assignedAt,
			amount = output,
		}
		local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local originalWorkers = {}
		for _, entry in latest.state.workers do
			originalWorkers[entry.id] = plot.Actors:WaitForChild(entry.id, 5)
		end
		nearby(training)
		navigate("Army")
		for _ = 1, 3 do
			press("Army", "More_melee")
		end
		press("Army", "More_ranged")
		press("Army", "More_medic")
		action("Army", "ApplyRoster", "apply 3/1/1 roster")
		assert(
			latest.state.roster.melee == 3
				and latest.state.roster.ranged == 1
				and latest.state.roster.medic == 1
				and #latest.state.workers == 3,
			"Roster consumed workforce or wrong capacity"
		)
		waitFor(function()
			local count = 0
			for _, actor in plot.Actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "roster" then
					count += 1
				end
			end
			return count == 5
		end, "Five roster presentations missing")
		local counts = { melee = 0, ranged = 0, medic = 0 }
		for _, actor in plot.Actors:GetChildren() do
			if actor:GetAttribute("PresentationRole") == "roster" then
				local role = actor:GetAttribute("RosterRole")
				counts[role] += 1
				assert(
					actor:GetAttribute("PresentationOnly") and not actor:FindFirstChildWhichIsA("Humanoid", true),
					"Roster became active combat actor"
				)
				assert(
					actor:GetAttribute("BuildingId") == (if role == "medic" then healer else training),
					"Roster attached to wrong site"
				)
			end
		end
		assert(counts.melee == 3 and counts.ranged == 1 and counts.medic == 1, "Wrong role presentations")
		for id, model in originalWorkers do
			assert(plot.Actors:FindFirstChild(id) == model, "Roster replaced worker: " .. id)
		end
		evidence.roster = { melee = 3, ranged = 1, medic = 1, workersRetained = 3, presentationOnly = true }
		nearby("b1")
		navigate("Research")
		action("Research", "savePreset", "save assignments")
		assert(latest.state.settings.preset[hired.workerId] == timber, "Preset failed to save assignment")
		inspect(timber)
		action("Inspector", "Unassign_" .. hired.workerId, "clear timber assignment")
		assert(worker(hired.workerId).buildingId == nil, "Unassignment failed")
		nearby("b1")
		navigate("Research")
		action("Research", "applyPreset", "restore assignments")
		assert(
			worker(hired.workerId).buildingId == timber
				and worker("w1").buildingId == "b3"
				and worker("w2").buildingId == "b3",
			"Preset did not restore owned workers"
		)
		evidence.preset = { saved = true, unassigned = true, restored = true, workers = 3 }
		for _, good in { "food", "timber", "material", "crafted" } do
			enter("Research", "Reserve_" .. good, if good == "food" then 10 else 400)
			action("Research", "SaveReserve_" .. good, "set " .. good .. " reserve")
		end
		inspect("b3")
		action("Inspector", "Unassign_w1", "pause first farm worker")
		action("Inspector", "Unassign_w2", "pause second farm worker")
		inspect(timber)
		action("Inspector", "Unassign_" .. hired.workerId, "pause timber worker")
		local foodReady, timberReady = building("b3").output, building(timber).output
		local foodBefore, timberBefore, coinsBefore =
			latest.state.goods.food, latest.state.goods.timber, latest.state.coins
		assert(foodBefore + foodReady > 10, "Not enough earned food for reserve test")
		nearby("b1")
		navigate("Research")
		action("Research", "Toggle_autoCollect", "enable Porter collection")
		waitFor(function()
			return latest.state.goods.food == foodBefore + foodReady
				and latest.state.goods.timber == timberBefore + timberReady
		end, "Porter did not conserve output", 10)
		assert(building("b3").output == 0 and building(timber).output == 0, "Porter left transferable output")
		evidence.inventoryAfterPorters = inventorySize()
		if capacityFixture then
			assert(evidence.inventoryAfterPorters > 200, "Storehouse never accepted goods beyond the original capacity")
		end
		action("Research", "Toggle_autoSell", "enable Trade Steward")
		local foodSold = foodBefore + foodReady - 10
		waitFor(function()
			return latest.state.goods.food == 10 and latest.state.coins == coinsBefore + foodSold * 2
		end, "Automatic food sale ignored reserve/price", 10)
		assert(
			latest.state.goods.timber == timberBefore + timberReady and latest.state.goods.material == expectedMaterial,
			"Trade consumed protected reserves"
		)
		evidence.automation = {
			collectedFood = foodReady,
			collectedTimber = timberReady,
			reserveFood = 10,
			soldFood = foodSold,
			saleCoins = foodSold * 2,
			nativeReserveEntry = true,
		}
		navigate("Trade")
		press("Trade", "Good_food")
		enter("Trade", "SaleQuantity", 1)
		local manualCoins = latest.state.coins
		action("Trade", "SellQuantity", "manual sale with services enabled")
		assert(
			latest.state.coins == manualCoins + 2
				and latest.state.goods.food == 9
				and latest.state.settings.autoCollect
				and latest.state.settings.autoSell,
			"Services disabled manual selling"
		)
		inspect(timber)
		assert(
			screen.Inspector.Content.CollectAll.Active and screen.Inspector.Content.CollectAll.Visible,
			"Porter disabled manual collection control"
		)
		nearby("b1")
		navigate("Research")
		action("Research", "Toggle_autoSell", "disable Trade Steward")
		action("Research", "Toggle_autoCollect", "disable Porter collection")
		action("Research", "applyPreset", "restore producing preset")
		assert(
			not latest.state.settings.autoCollect
				and not latest.state.settings.autoSell
				and worker(hired.workerId).buildingId == timber,
			"Optional services did not restore cleanly"
		)
		evidence.manualActions =
			{ saleWhileBothEnabled = true, collectionControlWhileEnabled = true, servicesRestoredOff = true }
		assert(latest.state.research.project == nil, "Effects fixture unexpectedly researched a node")
		evidence.ok = true
		return evidence
	end)
	connection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureServicesResult",
		Http:JSONEncode({ ok = ok, result = result, partialEvidence = if not ok then evidence else nil })
	)
	assert(ok, tostring(result))
	return result
end

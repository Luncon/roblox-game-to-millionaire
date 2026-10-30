--!strict
-- Client ModuleScript for the separately mapped AdvancedBootstrap test place.
-- Default: real UI house purchase/place/move/unpack, hiring, clay assignment and
-- collection. {research=true}: also waits real 30s Work + 60s Craft and the next
-- real merchant cycle, then purchases/places a workshop and crafts/sells pottery.
-- {resumePotterySale=true} resumes only the sale of already collected pottery.
-- Character relocation isolates distance guards; it is fixture setup, not a
-- walking/navigation acceptance claim. No mutation remote is fired directly.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	assert(Replicated:GetAttribute("MiniatureAdvancedFixture"), "Run only with AdvancedBootstrap")
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Management UI missing")
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest
	local receipts, evidence =
		{}, { fundedFakeSetup = true, realClocks = true, relocationWasFixtureSetup = true, receipts = {} }
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
		assert(button and button.Visible and button.Active, "Management button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function press(page, key)
		local body = screen[page].Content
		waitFor(function()
			return body:FindFirstChild(key) and body[key].Visible and body[key].Active
		end, "Unavailable " .. page .. "." .. key)
		local button = body[key]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		click(body[key])
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
			-- The first attempt's confirmation is primed by the flow. A submitted
			-- confirmation resets its flag even when refused; re-arm it explicitly.
			if attempt > 1 and key == "UnpackBuilding" then
				press(page, key)
			end
			local before = #receipts
			press(page, key)
			waitFor(function()
				return #receipts > before
			end, "No receipt for " .. label)
			local packet = receipts[#receipts]
			table.insert(evidence.receipts, {
				action = label,
				attempt = attempt,
				requestId = packet.requestId,
				result = packet.result,
				retry = attempt > 1,
			})
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
					and packet.snapshot.claimEpoch == latest.claimEpoch
					and latest.revision >= packet.snapshot.revision,
				"Stale refusal did not provide the current context"
			)
			task.wait(0.3)
		end
		error("Action attempts exhausted: " .. label)
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
	local function nearby(id)
		local target = building(id)
		assert(target, "Missing owned building: " .. id)
		local character = player.Character
		assert(character and character:FindFirstChild("HumanoidRootPart"), "Commander missing")
		character:PivotTo(latest.plotFrame * CFrame.new(target.x, 4, target.z + 4))
		task.wait(0.3)
	end
	local function inspect(id)
		nearby(id)
		navigate("Settlement")
		press("Settlement", "Inspect_" .. id)
		waitFor(function()
			return screen.Inspector.Visible and screen:GetAttribute("InspectedBuilding") == id
		end, "Inspector failed: " .. id)
	end
	local function buy(kind, category)
		nearby("b1")
		navigate("Build")
		press("Build", "Category_" .. category)
		return action("Build", "Buy_" .. kind, "buy " .. kind)
	end
	local function placement(kind, id, x, z, rotation)
		if id then
			inspect(id)
			press("Inspector", "MoveBuilding")
		else
			press("Build", "Place_" .. kind)
		end
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
		if rotation ~= 0 then
			click(screen.PlacementControls.PlacementActions.Rotate)
		end
		local before = #receipts
		waitFor(function()
			return screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
		end, "Placement did not validate")
		click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		waitFor(function()
			return #receipts > before
		end, "No placement receipt")
		local packet = receipts[#receipts]
		assert(packet.result.ok, "Placement refused: " .. tostring(packet.result.reason))
		table.insert(evidence.receipts, {
			action = if id then "move " .. kind else "place " .. kind,
			requestId = packet.requestId,
			result = packet.result,
		})
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == nil
		end, "Accepted placement left ghost")
		if screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
		local placed = building(packet.result.buildingId)
		assert(
			placed and placed.x == x and placed.z == z and placed.rotation == rotation,
			"Placement grid/rotation mismatch"
		)
		return placed
	end
	local function sellPottery(amount)
		assert(amount > 0 and amount <= latest.state.goods.crafted, "No collected pottery to sell")
		nearby("b1")
		navigate("Trade")
		press("Trade", "Good_crafted")
		local quantity = screen.Trade.Content.SaleQuantity
		local body = screen.Trade.Content
		body.CanvasPosition = Vector2.new(
			0,
			math.max(0, quantity.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8)
		)
		task.wait(0.2)
		evidence.lastStep = "focus sale quantity"
		clickPoint(quantity.AbsolutePosition + quantity.AbsoluteSize / 2 + Gui:GetGuiInset())
		waitFor(function()
			return quantity:IsFocused()
		end, "Sale quantity did not receive native focus")
		-- Fixture selection setup avoids Ctrl+A/Backspace/Return CoreGui bindings.
		-- SendTextInput uses the native focused TextBox path; Text is never assigned.
		quantity.CursorPosition, quantity.SelectionStart = #quantity.Text + 1, 1
		evidence.lastStep = "native SendTextInput quantity"
		input:SendTextInput(tostring(amount))
		task.wait(0.2)
		assert(quantity.Text == tostring(amount), "Native sale quantity entry failed: " .. quantity.Text)
		local saleCoins, goodsBefore = latest.state.coins, latest.state.goods.crafted
		action("Trade", "SellQuantity", "sell pottery")
		assert(
			latest.state.coins == saleCoins + amount * 15 and latest.state.goods.crafted == goodsBefore - amount,
			"Pottery sale ledger mismatch"
		)
		return {
			amount = amount,
			coinsBefore = saleCoins,
			coinsAfter = latest.state.coins,
			goodsBefore = goodsBefore,
			goodsAfter = latest.state.goods.crafted,
			nativeTextEntry = true,
			cursorSelectionWasFixtureSetup = true,
		}
	end
	local ok, result = pcall(function()
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded
		end, "Initial snapshot missing")
		if not latest.claim then
			action("Select", "SelectSparta", "select Sparta")
		end
		assert(latest.claim.civilizationId == "sparta", "Management fixture requires Sparta")
		if options.resumePotterySale then
			evidence.resumedSale = sellPottery(latest.state.goods.crafted)
			evidence.ok = true
			return evidence
		end
		assert(
			latest.state.coins == 5000 and latest.state.goods.timber == 80 and latest.state.goods.material == 20,
			"Advanced fixture already modified; restart Play"
		)
		assert(#latest.state.buildings == 3 and #latest.state.workers == 2, "Expected untouched starter layout")
		buy("house", "Homes")
		local house = placement("house", nil, 12, 10, 0)
		local coins, plans, count = latest.state.coins, latest.state.plans.house, #latest.state.buildings
		local moved = placement("house", house.id, 14, 10, 90)
		assert(
			moved.id == house.id
				and latest.state.coins == coins
				and latest.state.plans.house == plans
				and #latest.state.buildings == count,
			"Move altered economic state"
		)
		inspect(house.id)
		press("Inspector", "UnpackBuilding")
		assert(
			string.find(screen.Inspector.Content.UnpackBuilding.Text, "Confirm", 1, true),
			"Unpack confirmation missing"
		)
		action("Inspector", "UnpackBuilding", "unpack house")
		assert(
			not building(house.id) and latest.state.plans.house == plans + 1 and latest.state.coins == coins,
			"Unpack failed conservation"
		)
		evidence.moveUnpack = { buildingId = house.id, coins = coins, returnedPlans = latest.state.plans.house }
		nearby("b1")
		navigate("Settlement")
		local beforeHire = latest.state.coins
		local hired = action("Settlement", "HireWorker", "hire worker")
		assert(
			#latest.state.workers == 3 and latest.state.coins == beforeHire - 25 and worker(hired.workerId),
			"Hiring ledger mismatch"
		)
		buy("material", "Production")
		local clay = placement("material", nil, 12, 10, 0)
		inspect(clay.id)
		action("Inspector", "Assign_w1", "assign w1 to clay")
		assert(
			worker("w1").buildingId == clay.id and worker("w2").buildingId == "b3",
			"Assignment leaked to another worker"
		)
		local assignedAt = os.clock()
		waitFor(function()
			return building(clay.id).output >= 1
		end, "Clay did not produce one real batch", 25)
		local materialBefore, outputBefore = latest.state.goods.material, building(clay.id).output
		action("Inspector", "CollectAll", "collect clay")
		assert(
			latest.state.goods.material == materialBefore + outputBefore and building(clay.id).output == 0,
			"Clay collection did not conserve goods"
		)
		evidence.material = {
			buildingId = clay.id,
			workerId = "w1",
			secondsToFirstBatch = os.clock() - assignedAt,
			output = outputBefore,
			goodsAfter = latest.state.goods.material,
		}
		action("Inspector", "Unassign_w1", "unassign clay worker")
		assert(worker("w1").buildingId == nil, "Unassignment did not clear the owned worker")
		action("Inspector", "Assign_w1", "reassign clay worker")
		assert(worker("w1").buildingId == clay.id, "Reassignment failed")
		if options.research then
			nearby("b1")
			navigate("Settlement")
			local hallCoins, hallTimber = latest.state.coins, latest.state.goods.timber
			action("Settlement", "UpgradeHall", "upgrade hall")
			assert(
				latest.state.hallUpgraded
					and latest.state.coins == hallCoins - 160
					and latest.state.goods.timber == hallTimber - 10,
				"Hall price mismatch"
			)
			navigate("Research")
			local workStart = os.clock()
			action("Research", "StartResearch", "start Organized Work")
			assert(
				latest.state.research.project and latest.state.research.project.id == "work",
				"Wrong project started"
			)
			waitFor(function()
				return latest.state.research.completed.work
			end, "Organized Work did not complete in real time", 45)
			local workSeconds = os.clock() - workStart
			assert(workSeconds >= 29, "Research clock was accelerated")
			evidence.research = { workSeconds = workSeconds }
			press("Research", "ResearchView")
			press("Research", "ResearchDetails_craft")
			local craftStart = os.clock()
			action("Research", "StartResearch", "start Craft Traditions")
			waitFor(function()
				return latest.state.research.completed.craft
			end, "Craft Traditions did not complete in real time", 75)
			local craftSeconds = os.clock() - craftStart
			assert(craftSeconds >= 59, "Craft clock was accelerated")
			evidence.research.craftSeconds = craftSeconds
			waitFor(function()
				return latest.state.merchant.stock.workshop == 1
			end, "Workshop did not appear at next real restock", 190)
			buy("workshop", "Production")
			local workshop = placement("workshop", nil, 16, -8, 0)
			evidence.research.workshopId = workshop.id
			inspect(workshop.id)
			action("Inspector", "Assign_" .. hired.workerId, "assign hired potter")
			local inputBefore = latest.state.goods.material
			waitFor(function()
				return building(workshop.id).output >= 1
			end, "Pottery did not complete a real batch", 25)
			local craftedBefore, craftedOutput = latest.state.goods.crafted, building(workshop.id).output
			assert(latest.state.goods.material == inputBefore - craftedOutput, "Recipe input/output mismatch")
			action("Inspector", "CollectAll", "collect pottery")
			assert(latest.state.goods.crafted == craftedBefore + craftedOutput, "Pottery collection mismatch")
			evidence.research.pottery = craftedOutput
			evidence.research.sale = sellPottery(craftedOutput)
		end
		evidence.ok = true
		return evidence
	end)
	connection:Disconnect()
	for _, key in { Enum.KeyCode.R, Enum.KeyCode.A, Enum.KeyCode.LeftControl } do
		pcall(function()
			input:SendKey(false, key, false)
		end)
	end
	Replicated:SetAttribute(
		"MiniatureManagementResult",
		Http:JSONEncode({ ok = ok, result = result, partialEvidence = if not ok then evidence else nil })
	)
	assert(ok, tostring(result))
	return result
end

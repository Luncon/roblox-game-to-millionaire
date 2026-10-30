--!strict
-- Ordinary200Coin starter acceptance: earn, buy, grid-place, reclaim and direct E.
-- All requests use actual UI/native input; no authority or position injection.
type Options = { timeout: number? }
local function run(options: Options?)
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong military baseline fixture boundary"
	)
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(screen and actions, "Army-control UI missing")
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	local Placement = require(Replicated.MiniatureGame.Placement)
	local input = Input:CreateVirtualInput()
	local latest, deadline = nil, os.clock() + (if options and options.timeout then options.timeout else 240)
	local receipts = {}
	local evidence = {
		nativeVirtualInput = true,
		authorityMutation = false,
		localRelocation = false,
		attempts = {},
		placements = {},
		gridStacks = {},
	}
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function progress(text: string)
		Replicated:SetAttribute("MiniatureMilitaryBaselineFlowProgress", text)
	end
	local function waitFor(predicate, label: string, seconds: number?)
		local stop = math.min(deadline, os.clock() + (seconds or 15))
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() >= stop
		error(label)
	end
	local function clickPoint(point: Vector2)
		input:SendMousePosition(point)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local function click(button)
		waitFor(function()
			return button and button.Parent and button.Visible and button.Active
		end, "Army-control button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.12)
		input:SendKey(false, code, false)
		task.wait(0.2)
	end
	local function action(label: string, press)
		progress(label)
		for attempt = 1, 3 do
			local count = #receipts
			press()
			waitFor(function()
				return #receipts > count
			end, "Army-control receipt missing: " .. label)
			local packet = receipts[count + 1]
			table.insert(
				evidence.attempts,
				{ label = label, ok = packet.result.ok, reason = packet.result.reason, requestId = packet.requestId }
			)
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				"Army action rejected: " .. tostring(packet.result.reason)
			)
			waitFor(function()
				return screen:GetAttribute("Revision") >= packet.snapshot.revision
			end, "Fresh army receipt did not render")
		end
		error("Army retries exhausted")
	end
	local function closePanels()
		for _, name in { "Build", "Trade", "Select", "Research", "Inventory", "ArmyControls", "ArmyDeploy" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible and panel:FindFirstChild("Close") then
				click(panel.Close)
			end
		end
	end
	local function travel(name, destination)
		local packet = action("Travel " .. destination, function()
			click(screen.TopNavigation[name])
		end)
		assert(packet.result.destination == destination, "Army travel destination differs")
	end
	local function building(id)
		for _, candidate in latest.state.buildings do
			if candidate.id == id then
				return candidate
			end
		end
		return nil
	end
	local function buy(kind)
		local list = screen.Build.Content.ShopList
		local row = list["Row_" .. kind]
		-- Wheel/drag is covered by shop fixtures; reveal this paid row without
		-- changing selection, drafts, Coins or any gameplay state.
		list.CanvasPosition =
			Vector2.new(0, math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8))
		task.wait(0.15)
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("Buy " .. kind, function()
			click(row["Buy_" .. kind])
		end)
		assert(
			packet.snapshot.state.coins == coins - Catalog.buildings[kind].price
				and packet.snapshot.state.plans[kind] == plans + 1,
			"Army purchase ledger differs"
		)
	end
	local function place(kind, x, z, slotOne)
		closePanels()
		if slotOne then
			click(screen.Hotbar.Content.Slot1)
		else
			key(Enum.KeyCode.B)
		end
		waitFor(function()
			return screen.Inventory.Visible
		end, "Army inventory did not open")
		local body, tile = screen.Inventory.Content, screen.Inventory.Content["Plan_" .. kind]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, tile.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 4))
		task.wait(0.2)
		local stack = tile.StackCount.Text
		assert(tile.Visible and latest.state.plans[kind] == 1 and stack == "×1", "Actual inventory grid stack differs")
		table.insert(evidence.gridStacks, {
			kind = kind,
			stateCount = latest.state.plans[kind],
			renderedCount = stack,
			inventorySlotOne = slotOne == true,
		})
		click(tile)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == kind
		end, "Army plan not selected")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, shown =
			Workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
		assert(shown, "Army placement point is outside camera")
		local dock = screen.PlacementControls
		local first, last = dock.AbsolutePosition, dock.AbsolutePosition + dock.AbsoluteSize
		assert(
			not (point.X >= first.X and point.X <= last.X and point.Y >= first.Y and point.Y <= last.Y),
			"Army placement projection overlaps its controls"
		)
		for _ = 1, 3 do
			clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
			local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
			local localPoint = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
			if localPoint and math.abs(localPoint.X - x) < 0.01 and math.abs(localPoint.Z - z) < 0.01 then
				break
			end
		end
		local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
		local position = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
		assert(
			position and math.abs(position.X - x) < 0.01 and math.abs(position.Z - z) < 0.01,
			"Native army placement click missed"
		)
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("Place " .. kind, function()
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local placed = building(packet.result.buildingId)
		assert(
			placed and placed.kind == kind and placed.x == x and placed.z == z and placed.rotation == 0,
			"Army placement differs"
		)
		assert(latest.state.coins == coins and latest.state.plans[kind] == plans - 1, "Army placement payment differs")
		table.insert(evidence.placements, { id = placed.id, kind = kind, x = x, z = z })
		return placed
	end
	local function walkTo(point: Vector3): number
		closePanels()
		click(screen.CameraControls.Walk)
		local distance = 0
		for _ = 1, 65 do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			assert(
				root and humanoid and humanoid.Health > 0 and not character:FindFirstChildOfClass("Tool"),
				"Army commander unavailable"
			)
			local delta = point - root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			if flat.Magnitude <= 7 then
				return distance
			end
			local direction = flat.Unit
			Workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
			task.wait(0.12)
			clickPoint(Workspace.CurrentCamera.ViewportSize * Vector2.new(0.9, 0.4))
			local before = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(math.min(2, math.max(0.15, (flat.Magnitude - 2) / humanoid.WalkSpeed)))
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.12)
			local movement = root.Position - before
			local step = Vector3.new(movement.X, 0, movement.Z).Magnitude
			assert(step > 0.5 and os.clock() < deadline, "Native army walk blocked")
			distance += step
		end
		error("Commander did not reach army interaction")
	end

	local function actorsFor(id)
		local found = {}
		for _, model in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
			if model:GetAttribute("BuildingId") == id and model:GetAttribute("Alive") == true then
				table.insert(found, model)
			end
		end
		return found
	end
	local ok, failure = pcall(function()
		progress("Load ordinary starter snapshot")
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Baseline snapshot missing")
		assert(latest.claim and latest.claim.civilizationId == "sparta", "Select ordinary Sparta first")
		assert(
			latest.state.coins == 200 and #latest.state.buildings == 3 and latest.troopCapacityUsed == 0,
			"Baseline requires unchanged200Coin ordinary starter"
		)
		assert(
			not latest.armyControlsUnlocked
				and next(latest.state.militaryResearch.completed) == nil
				and latest.state.militaryResearch.project == nil,
			"Baseline must have no military research"
		)
		assert(latest.state.plans.training == 0, "Baseline must not receive a paid plan")
		local farm = building("b3")
		assert(farm and farm.kind == "farm", "Starter farm missing")
		evidence.coinsBefore = latest.state.coins
		evidence.farmWalk = walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(farm.x, 0.4, farm.z)))
		waitFor(function()
			return building("b3").output == 60
		end, "Starter farm did not produce60goods", 40)
		local goodsBefore = latest.state.goods.food
		local collect = action("Collect farm with E", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			collect.result.amount == 60 and latest.state.goods.food == goodsBefore + 60 and latest.state.coins == 200,
			"E collection did not transfer the real60output"
		)
		evidence.collection = {
			outputBefore = 60,
			goodsBefore = goodsBefore,
			goodsAfter = latest.state.goods.food,
			coins = latest.state.coins,
		}
		travel("Sell", "sell")
		waitFor(function()
			return screen.Trade.Visible
		end, "Baseline sell shop missing")
		local sale = action("Sell all earned goods", function()
			click(screen.Trade.Content.SellAll)
		end)
		assert(
			sale.result.ok and latest.state.coins == 320 and latest.state.goods.food == 0,
			"Earned sale ledger should be200to320"
		)
		evidence.sale = { coins = latest.state.coins, food = latest.state.goods.food }
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Baseline building shop missing")
		click(screen.Build.Content.ShopTabs.Category_Military)
		buy("training")
		assert(latest.state.coins == 70 and latest.state.plans.training == 1, "Paid250Coin barracks ledger differs")
		travel("Civilization", "civilization")
		local legal, why = Placement.validate(latest.state.buildings, "training", 16, -22, 0)
		assert(legal, tostring(why))
		local first = place("training", 16, -22, true)
		waitFor(function()
			return #actorsFor(first.id) == 2 and latest.troopCapacityUsed == 2
		end, "First paid barracks did not spawn two troops")
		evidence.firstPlacement = {
			buildingId = first.id,
			coins = latest.state.coins,
			plans = latest.state.plans.training,
			capacityUsed = latest.troopCapacityUsed,
		}
		evidence.reclaimWalk = walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(first.x, 0.4, first.z)))
		key(Enum.KeyCode.Two)
		waitFor(function()
			return screen:GetAttribute("HammerSelected") == true
		end, "Hammer key2 did not select")
		local source = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId].Buildings[first.id]
		waitFor(function()
			for _, prompt in source:GetDescendants() do
				if
					prompt:IsA("ProximityPrompt")
					and prompt.Enabled
					and string.find(prompt.ActionText, "Return", 1, true)
				then
					return true
				end
			end
			return false
		end, "Hammer did not enable building return prompt")
		local retired = {}
		for _, model in actorsFor(first.id) do
			retired[model.Name] = true
		end
		local reclaim = action("Hammer E returns barracks", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			reclaim.result.buildingId == first.id
				and not building(first.id)
				and latest.state.coins == 70
				and latest.state.plans.training == 1
				and latest.troopCapacityUsed == 0,
			"Reclaim lost paid plan or charged Coins"
		)
		waitFor(function()
			if #actorsFor(first.id) ~= 0 then
				return false
			end
			local folder = Workspace:FindFirstChild("MiniatureClientActors")
			if folder then
				for _, model in folder:GetChildren() do
					if model:GetAttribute("BuildingId") == first.id then
						return false
					end
				end
			end
			return true
		end, "Reclaimed barracks source/local troop visuals leaked")
		local corpses = Workspace:FindFirstChild("MiniatureRagdolls")
		if corpses then
			for _, corpse in corpses:GetChildren() do
				assert(not retired[corpse:GetAttribute("ActorId")], "Hammer reclaim created a combat corpse")
			end
		end
		evidence.reclaim = {
			coins = latest.state.coins,
			returnedPlan = latest.state.plans.training,
			capacityUsed = latest.troopCapacityUsed,
			sourceAndLocalCleanup = true,
			noCombatCorpse = true,
		}
		legal, why = Placement.validate(latest.state.buildings, "training", 28, -22, 0)
		assert(legal, tostring(why))
		local second = place("training", 28, -22, false)
		waitFor(function()
			return #actorsFor(second.id) == 2 and latest.troopCapacityUsed == 2
		end, "Replaced paid barracks did not spawn two troops")
		assert(latest.state.coins == 70 and latest.state.plans.training == 0, "Re-placement charged again")
		evidence.replacement = {
			buildingId = second.id,
			coins = latest.state.coins,
			plans = latest.state.plans.training,
			capacityUsed = latest.troopCapacityUsed,
		}
		local ownId = "outpost_" .. latest.claim.plotId
		assert(not latest.armyControlsUnlocked and latest.outposts[ownId], "Pre-unlock target missing")
		evidence.outpostWalk = walkTo(latest.outposts[ownId].position)
		local before = #receipts
		local target = action("Pre-unlock direct outpost E", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			#receipts == before + 1 and target.result.outpostId == ownId and target.result.armyId == 1,
			"Pre-unlock E did not send exactly one all-army command"
		)
		assert(
			not screen.ArmyDeploy.Visible and not screen.ArmyDeploy:GetAttribute("PanelOpen"),
			"Pre-unlock E opened an unavailable chooser"
		)
		waitFor(function()
			return latest.army.manual == true and latest.army.targetId == ownId
		end, "Pre-unlock whole army did not accept target")
		evidence.preUnlock = {
			targetId = ownId,
			manual = latest.army.manual,
			requestCount = #receipts - before,
			armyDeployOpened = false,
			armyControlsUnlocked = latest.armyControlsUnlocked,
		}
		evidence.coinsAfter = latest.state.coins
		progress("Passed")
	end)
	for _, code in { Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.B, Enum.KeyCode.Two } do
		pcall(function()
			input:SendKey(false, code, false)
		end)
	end
	pcall(function()
		input:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton1, false, 0)
	end)
	connection:Disconnect()
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if ok then nil else evidence }
	Replicated:SetAttribute("MiniatureMilitaryBaselineFlowResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end
return run

--!strict
-- Native Client acceptance for the simple shared-shop slice. No render-state injection.
-- funded=true requires a declared fake-bootstrap fixture with ONLY Coins changed to 5000.
-- Every gameplay mutation below is an explicit native UI/key/click action.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Simple shop HUD missing")
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	local input = Input:CreateVirtualInput()
	local deadline = os.clock() + 180
	local latest
	local receipts = {}
	local evidence = {
		fundedFakeBootstrap = options.funded == true,
		expectedStartingCoins = if options.funded then 5000 else 200,
		researchInjected = false,
		localRenderInjection = false,
		localRelocation = false,
		attempts = {},
		retry = {},
		placements = {},
		steps = {},
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
		local stop = math.min(deadline, os.clock() + (seconds or 12))
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() >= stop
		error(label)
	end
	local function step(label)
		evidence.lastStep = label
		table.insert(evidence.steps, label)
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
		assert(button and button.Visible and button.Active, "Simple shop button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.1)
		input:SendKey(false, code, false)
		task.wait(0.2)
	end
	local function action(label, press)
		for attempt = 1, 3 do
			local previous = #receipts
			press()
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
				revision = packet.snapshot.revision,
			})
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			waitFor(function()
				return latest.revision >= packet.snapshot.revision
					and (screen:GetAttribute("Revision") or -1) >= packet.snapshot.revision
			end, "Fresh refusal snapshot missing")
			table.insert(
				evidence.retry,
				{ label = label, attempt = attempt + 1, freshRevision = latest.revision, explicitNativePress = true }
			)
			task.wait(0.1)
		end
		error("Simple shop attempts exhausted: " .. label)
	end
	local function pressBody(page, name)
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
	local function closePanels()
		for _, name in { "Build", "Trade", "Select", "Inventory" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible then
				click(panel.Close)
			end
		end
	end
	local function rootPart()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		assert(
			root and character.Humanoid.Health > 0 and math.abs(character:GetScale() - 1) < 0.001,
			"Normal living commander missing"
		)
		assert(
			not character:FindFirstChildOfClass("Tool") and not player.Backpack:FindFirstChildOfClass("Tool"),
			"Commander armed"
		)
		return root
	end
	local function travel(name, destination)
		local packet = action("travel " .. destination, function()
			waitFor(function()
				return screen.TopNavigation[name].Active
			end, "Top travel control did not refresh")
			click(screen.TopNavigation[name])
		end)
		assert(packet.result.destination == destination, "Wrong travel destination")
		local target = if destination == "buy"
			then latest.buyShopPosition
			elseif destination == "sell" then latest.sellShopPosition
			else latest.plotFrame:PointToWorldSpace(Vector3.new(0, 3, 23))
		waitFor(function()
			return (rootPart().Position - target).Magnitude < 12
		end, "Server did not reach " .. destination)
		return packet
	end
	local function findBuilding(view, id)
		for _, building in view.state.buildings do
			if building.id == id then
				return building
			end
		end
		return nil
	end
	local function farm()
		for _, building in latest.state.buildings do
			if building.kind == "farm" then
				return building
			end
		end
		error("Starter farm missing")
	end
	local function walkTo(site)
		closePanels()
		click(screen.CameraControls.Walk)
		local root = rootPart()
		local target = latest.plotFrame:PointToWorldSpace(Vector3.new(site.x, 3, site.z + 6))
		local delta = target - root.Position
		local horizontal = Vector3.new(delta.X, 0, delta.Z)
		if horizontal.Magnitude > 1 then
			local direction = horizontal.Unit
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
			task.wait(0.25)
			clickPoint(workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.6))
			local began = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(math.min(3, horizontal.Magnitude / 16))
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.25)
			local walked = root.Position - began
			evidence.lastWalkDistance = Vector3.new(walked.X, 0, walked.Z).Magnitude
			assert(evidence.lastWalkDistance > 5, "Native W walking blocked")
		end
		local point = latest.plotFrame:PointToWorldSpace(Vector3.new(site.x, 0.4, site.z))
		assert((root.Position - point).Magnitude < 12, "Native walk did not reach building")
	end
	local function emptyGoods(view)
		for _, amount in view.state.goods do
			assert(amount == 0, "Unexpected goods in simple shop state")
		end
	end
	local function collectAndSell()
		local site = farm()
		walkTo(site)
		waitFor(function()
			return findBuilding(latest, site.id).output >= 2
		end, "No farm output", 15)
		local goodsBefore = latest.state.goods.food
		local packet = action("E collect all", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			packet.result.amount > 0 and packet.snapshot.state.goods.food == goodsBefore + packet.result.amount,
			"Collect did not transfer all output"
		)
		assert(findBuilding(packet.snapshot, site.id).output == 0, "Collect retained output")
		travel("Sell", "sell")
		closePanels()
		key(Enum.KeyCode.E)
		waitFor(function()
			return screen.Trade.Visible
		end, "Shared sell E did not open Trade")
		local coinsBefore = latest.state.coins
		local sale = action("Sell all", function()
			pressBody("Trade", "SellAll")
		end)
		assert(
			sale.snapshot.state.coins == coinsBefore + sale.result.coins and sale.result.coins > 0,
			"Shared sale coins differ"
		)
		emptyGoods(sale.snapshot)
		return sale.result.coins
	end
	local function buy(kind)
		local list = screen.Build.Content.ShopList
		local function pressBuy()
			waitFor(function()
				local row = list:FindFirstChild("Row_" .. kind)
				return row and row.Visible and row:FindFirstChild("Buy_" .. kind) and row["Buy_" .. kind].Active
			end, "Eligible military row locked: " .. kind)
			local row = list["Row_" .. kind]
			assert(
				row.Thumbnail:IsA("ViewportFrame") and row.Thumbnail.CurrentCamera,
				"Shop row lacks actual model image"
			)
			assert(
				row.Title.Text ~= "" and row.Description.Text ~= "" and row.Stock.Text ~= "",
				"Incomplete compact shop row"
			)
			list.CanvasPosition = Vector2.new(
				0,
				math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8)
			)
			task.wait(0.2)
			click(row["Buy_" .. kind])
		end
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("buy " .. kind, pressBuy)
		assert(
			packet.snapshot.state.coins == coins - Catalog.buildings[kind].price
				and packet.snapshot.state.plans[kind] == plans + 1,
			"Coin-only military item purchase differs"
		)
		emptyGoods(packet.snapshot)
		return packet
	end
	local function place(kind, x, z, rotation)
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Inventory B missing")
		pressBody("Inventory", "Plan_" .. kind)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == kind
		end, "Owned military item not selected")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, shown =
			workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
		assert(shown, "Chosen military ground outside overview")
		clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
		for _ = 1, rotation / 90 do
			key(Enum.KeyCode.R)
		end
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("place " .. kind, function()
			waitFor(function()
				return screen.PlacementControls.PlacementActions.ConfirmPlacement.Active
			end, "Military footprint not eligible")
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local building = findBuilding(packet.snapshot, packet.result.buildingId)
		assert(
			building and building.kind == kind and building.x == x and building.z == z and building.rotation == rotation,
			"Native placed military footprint differs"
		)
		assert(
			packet.snapshot.state.coins == coins and packet.snapshot.state.plans[kind] == plans - 1,
			"Military placement charged twice"
		)
		table.insert(evidence.placements, { id = building.id, kind = kind, x = x, z = z, rotation = rotation })
		return building
	end
	local function actorGroups(melee, ranged, medic)
		assert(
			latest.troops
				and latest.troops.melee == melee
				and latest.troops.ranged == ranged
				and latest.troops.medic == medic,
			"Aggregate automatic troop snapshot differs"
		)
		local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local found, counts = {}, { melee = 0, ranged = 0, medic = 0 }
		waitFor(function()
			found, counts = {}, { melee = 0, ranged = 0, medic = 0 }
			for _, actor in plot.Actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "roster" then
					local role = actor:GetAttribute("RosterRole")
					local id = actor:GetAttribute("BuildingId")
					assert(
						actor:GetAttribute("AutomaticTroop")
							and actor:GetAttribute("OwnerId") == player.UserId
							and findBuilding(latest, id),
						"Automatic actor owner/building missing"
					)
					assert(
						math.abs(actor:GetScale() - 0.25) < 0.001 and actor:GetAttribute("PresentationOnly"),
						"Active or full-size army actor"
					)
					counts[role] += 1
					found[actor.Name] = actor
				end
			end
			return counts.melee == melee and counts.ranged == ranged and counts.medic == medic
		end, "Per-building automatic actors not rendered")
		return found
	end
	local ok, result = pcall(function()
		assert(
			game:GetService("RunService"):IsStudio()
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong simple shop boundary"
		)
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Simple shop snapshot missing")
		step("choose fresh Sparta without research")
		if not latest.claim then
			action("select Sparta", function()
				pressBody("Select", "SelectSparta")
			end)
		end
		assert(
			latest.claim.civilizationId == "sparta"
				and latest.state.coins == evidence.expectedStartingCoins
				and #latest.state.buildings == 3,
			"Wrong fresh/funded simple shop fixture"
		)
		emptyGoods(latest)
		assert(
			not latest.state.hallUpgraded
				and not next(latest.state.research.completed)
				and not latest.state.research.project,
			"Fixture must not inject unlocks"
		)
		for _, amount in latest.state.plans do
			assert(amount == 0, "Fixture started with building plans")
		end
		if options.waitForScene ~= false then
			waitFor(function()
				return Replicated:GetAttribute("MiniatureGameSceneResult") ~= nil
			end, "Native scene result missing", 30)
			local sceneResult = Http:JSONDecode(Replicated:GetAttribute("MiniatureGameSceneResult"))
			assert(sceneResult.ok, "Scene contract failed: " .. tostring(sceneResult.result))
		end
		for _, name in
			{
				"Inspector",
				"Research",
				"Army",
				"UpgradeHall",
				"ChangeRoster",
				"Collect10",
				"Sell10",
				"HireWorker",
				"AssignWorker",
			}
		do
			assert(not screen:FindFirstChild(name, true), "Removed product control remains: " .. name)
		end
		assert(workspace.MiniatureSandbox.Ground.Size == Vector3.new(1200, 1, 1200), "Expanded world not active")
		actorGroups(0, 0, 0)
		step("native farm collection and shared sale")
		evidence.firstSale = collectAndSell()
		assert(options.multiple ~= true, "Multiple-building native packing is covered by the isolated scene fixture")
		local required = 700
		local earningCycles = 1
		while latest.state.coins < required do
			travel("Civilization", "civilization")
			evidence.lastSale = collectAndSell()
			earningCycles += 1
		end
		evidence.earningCycles = earningCycles
		step("buy eligible military items using coins only")
		travel("Buy", "buy")
		closePanels()
		key(Enum.KeyCode.E)
		waitFor(function()
			return screen.Build.Visible
		end, "Shared buy E did not open shop")
		local tabs = screen.Build.Content.ShopTabs
		local count = 0
		for _, tab in tabs:GetChildren() do
			if tab:IsA("TextButton") then
				count += 1
			end
		end
		assert(
			count == 3 and tabs.Category_Homes and tabs.Category_Production and tabs.Category_Military,
			"Shop must have exactly three category tabs"
		)
		click(tabs.Category_Military)
		buy("training")
		buy("ranged")
		buy("healer")
		assert(
			not latest.state.hallUpgraded and not next(latest.state.research.completed),
			"Military shopping silently unlocked research"
		)
		step("place three military building types")
		travel("Civilization", "civilization")
		local melee = place("training", 6, 8, 90)
		actorGroups(2, 0, 0)
		place("ranged", 16, 8, 90)
		actorGroups(2, 2, 0)
		place("healer", 16, -8, 0)
		actorGroups(2, 2, 1)
		local meleeCount = 2
		local original = actorGroups(meleeCount, 2, 1)
		step("hammer reclaim only one barracks and retain unrelated troops")
		travel("Civilization", "civilization")
		walkTo(melee)
		if not screen:GetAttribute("HammerSelected") then
			click(screen.Hotbar.Content.Slot1)
		end
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local coins, plans = latest.state.coins, latest.state.plans.training
		action("hammer melee barracks", function()
			local point, shown =
				workspace.CurrentCamera:WorldToViewportPoint(plot.Buildings[melee.id].SelectTarget.Position)
			assert(shown, "Melee barracks outside hammer overview")
			clickPoint(Vector2.new(point.X, point.Y))
		end)
		assert(
			not findBuilding(latest, melee.id)
				and latest.state.plans.training == plans + 1
				and latest.state.coins == coins,
			"Hammer did not return barracks item"
		)
		local retained = actorGroups(meleeCount - 2, 2, 1)
		for name, actor in original do
			if actor:GetAttribute("BuildingId") ~= melee.id then
				assert(retained[name] == actor, "Hammer replaced another building's troop")
			end
		end
		step("replace barracks item without extra cost")
		local replacement = place("training", 6, 8, 90)
		assert(
			replacement.id ~= melee.id and latest.state.coins == coins and latest.state.plans.training == plans,
			"Replacement changed coins/plans"
		)
		local restored = actorGroups(meleeCount, 2, 1)
		for name, actor in retained do
			assert(restored[name] == actor, "Replacement rebuilt unrelated actors")
		end
		evidence.troops = { melee = meleeCount, ranged = 2, medic = 1 }
		evidence.multipleMilitary = false
		evidence.perBuildingRemoval = true
		evidence.retainedUnrelatedActors = true
		evidence.replacementNoCharge = true
		evidence.noResearchRequired = true
		evidence.ok = true
		return evidence
	end)
	for _, code in { Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.B } do
		pcall(function()
			input:SendKey(false, code, false)
		end)
	end
	connection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureSimpleShopFlowResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, result)
	return result
end

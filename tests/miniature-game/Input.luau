--!strict
-- Native Studio Client fixture. Run only in the separate fake-store sandbox.
-- Relocation isolates interaction checks; a separate native W-key assertion tests walking.
return function(options)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Sandbox UI missing")
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest, receiptConnection, testGui = nil, nil, nil
	local economyEvidence, editEvidence = nil, nil
	receiptConnection = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
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
		assert(button and button.Visible and button.Active, "Button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function reveal(body, button)
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
	end
	local function inside(object, parent)
		local p, size, q, bounds =
			object.AbsolutePosition, object.AbsoluteSize, parent.AbsolutePosition, parent.AbsoluteSize
		return p.X >= q.X - 1
			and p.Y >= q.Y - 1
			and p.X + size.X <= q.X + bounds.X + 1
			and p.Y + size.Y <= q.Y + bounds.Y + 1
	end
	local function researchInputs(ui, shell)
		-- These are isolated render states. Never send them to the server or alter
		-- receipt tables: production/research authority is tested separately.
		local presentation = table.clone(latest)
		presentation.state = table.clone(latest.state)
		presentation.state.coins, presentation.state.hallUpgraded = 10000, true
		presentation.state.goods = table.clone(latest.state.goods)
		presentation.state.goods.timber = 1000
		presentation.state.research = { completed = { work = true }, project = { id = "craft", remaining = 17.2 } }
		ui.update(presentation, false)
		ui.navigate("Research")
		local body = shell.Research.Content
		local function press(button)
			reveal(body, button)
			click(button)
		end
		local function contains(label, value)
			assert(string.find(label.Text, value, 1, true), label.Name .. " missing: " .. value)
		end
		local graph = body.ResearchGraph
		assert(graph.Tree.Node_work:GetAttribute("ResearchStatus") == "Completed", "Completed graph label missing")
		assert(graph.Tree.Node_craft:GetAttribute("ResearchStatus") == "Researching", "Researching graph label missing")
		assert(graph.Tree.Node_store:GetAttribute("ResearchStatus") == "Locked", "Locked graph label missing")
		contains(body.ResearchProject, "18s remaining")
		press(body.TreePan.PanRight)
		assert(graph.CanvasPosition.X > 0, "Native tree pan failed")
		local beforeScale = graph.Tree.UIScale.Scale
		press(body.TreeZoom.ZoomIn)
		graph = body.ResearchGraph
		assert(graph.Tree.UIScale.Scale > beforeScale and graph.CanvasPosition.X > 0, "Zoom reset pan or failed")
		for _ = 1, 4 do
			local node = graph.Tree.Node_store
			if
				node.AbsolutePosition.X + node.AbsoluteSize.X / 2
				< graph.AbsolutePosition.X + graph.AbsoluteWindowSize.X - 4
			then
				break
			end
			press(body.TreePan.PanRight)
		end
		press(graph.Tree.Node_store)
		assert(body:GetAttribute("SelectedResearch") == "store", "Native graph node selection failed")
		press(body.ResearchView)
		assert(
			body:GetAttribute("SelectedResearch") == "store" and not body:GetAttribute("ResearchGraphMode"),
			"List switch lost selection"
		)
		contains(body.State_work, "Completed")
		contains(body.State_craft, "Researching")
		contains(body.State_store, "Locked")
		contains(body.ResearchProject, "18s remaining")
		local expected = {
			{ "Economy", "work", "100 coins", "30 active seconds", "10% shorter", "grain and timber 9s", "clay 13.5s" },
			{
				"Economy",
				"craft",
				"180 coins + 10 timber",
				"60 active seconds",
				"Organized Work",
				"one clay into one pottery",
				"next restock",
			},
			{ "Economy", "store", "240 coins", "90 active seconds", "Craft Traditions", "200 to 400", "next restock" },
			{
				"Army",
				"muster",
				"100 coins",
				"30 active seconds",
				"two display fighters",
				"shared between melee and ranged",
				"next restock",
			},
			{ "Army", "drill", "180 coins + 10 timber", "60 active seconds", "Muster", "two to four fighters" },
			{ "Army", "supply", "240 coins", "90 active seconds", "Drill Yard", "one display medic", "no healing" },
			{ "Civic", "records", "100 coins", "30 active seconds", "cannot hire workers", "building worker places" },
			{
				"Civic",
				"porters",
				"180 coins + 10 timber",
				"60 active seconds",
				"Settlement Records",
				"available combined goods capacity",
				"Manual collection stays available",
			},
			{
				"Civic",
				"trade",
				"240 coins",
				"90 active seconds",
				"Porter Service",
				"above each goods reserve",
				"next workshop-input batch",
				"Manual sales stay available",
			},
		}
		for _, item in expected do
			press(body["Branch_" .. item[1]])
			press(body["ResearchDetails_" .. item[2]])
			for index = 3, #item do
				contains(body.ResearchDetails, item[index])
				contains(body["ListDetails_" .. item[2]], item[index])
			end
			contains(body.ResearchDetails, "Prerequisite: improved council")
			assert(
				body.ResearchDetails.TextFits and body["ListDetails_" .. item[2]].TextFits,
				"Research effects clipped"
			)
			reveal(body, body.StartResearch)
			assert(inside(body.StartResearch, shell.Research), "Research confirmation clipped or outside panel")
		end
		press(body.Branch_Economy)
		assert(body:GetAttribute("SelectedResearch") == "store", "Economy branch forgot selected node")
		press(body.Branch_Civic)
		assert(body:GetAttribute("SelectedResearch") == "trade", "Civic branch forgot selected node")
		press(body.Branch_Economy)
		press(body.ResearchView)
		assert(
			body:GetAttribute("ResearchGraphMode") and body:GetAttribute("SelectedResearch") == "store",
			"Graph restore lost selection"
		)
		assert(body.ResearchGraph.CanvasPosition.X > 0, "Graph/list switch lost pan")
		presentation.state.research = { completed = { work = true } }
		ui.update(presentation, false)
		assert(
			body.ResearchGraph.Tree.Node_craft:GetAttribute("ResearchStatus") == "Available",
			"Available graph label missing"
		)
		contains(body.SelectedResearchState, "Requires Craft Traditions")
		assert(not body.StartResearch.Active, "Locked research confirmation was enabled")
		presentation.state.hallUpgraded = false
		ui.update(presentation, false)
		contains(body.SelectedResearchState, "Improve the council first: 160 coins + 10 timber")
		ui.update(latest, false)
	end

	local ok, result = pcall(function()
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded
		end, "Writable snapshot missing")
		if not options.layoutsOnly then
			if not latest.claim then
				local body = screen.Select.Content
				body.CanvasPosition = Vector2.zero
				reveal(body, body.SelectSparta)
				click(body.SelectSparta)
				waitFor(function()
					return latest.claim and latest.claim.civilizationId == "sparta"
				end, "Sparta was not selected")
			end
			assert(latest.claim.civilizationId == "sparta", "Fixture requires Sparta")
			local frame = latest.plotFrame
			local character = player.Character
			assert(character and character:FindFirstChild("HumanoidRootPart"), "Commander missing")
			if screen.Settlement.Visible then
				click(screen.Settlement.Close)
			end
			click(screen.CameraControls.Walk)
			waitFor(function()
				return workspace.CurrentCamera.CameraType == Enum.CameraType.Custom
			end, "Walk camera missing")
			local root = character.HumanoidRootPart
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 6, 14), root.Position + Vector3.new(0, 0, -10))
			task.wait(0.2)
			clickPoint(workspace.CurrentCamera.ViewportSize * Vector2.new(0.5, 0.6) + Gui:GetGuiInset())
			local began = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(1)
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.2)
			assert((root.Position - began).Magnitude > 5, "Native W-key movement was blocked")
			character:PivotTo(frame * CFrame.new(8, 4, -2))
			for _, name in { "Settlement", "Inspector" } do
				if screen[name].Visible then
					click(screen[name].Close)
				end
			end
			click(screen.CameraControls.Overview)
			waitFor(function()
				return screen:GetAttribute("CameraMode") == "Overview"
			end, "Overview missing")
			task.wait(0.3)
			local camera = workspace.CurrentCamera
			local beforeZoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
			input:SendPointerAction(camera.ViewportSize * Vector2.new(0.5, 0.6), { Wheel = 1 })
			task.wait(0.2)
			assert(
				(camera.CFrame.Position - camera.Focus.Position).Magnitude < beforeZoom,
				"Overview wheel zoom failed"
			)
			local farm = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId].Buildings.b3
			local point, shown = workspace.CurrentCamera:WorldToViewportPoint(farm.SelectTarget.Position)
			assert(shown, "Farm outside overview")
			clickPoint(Vector2.new(point.X, point.Y))
			waitFor(function()
				return screen:GetAttribute("InspectedBuilding") == "b3"
			end, "Farm world click failed")
			waitFor(function()
				return screen.Inspector.Content.Collect10.Active
			end, "Farm did not produce ten goods", 65)
			local beforeGoods, beforeCoins = latest.state.goods.food, latest.state.coins
			local outputBefore
			for _, building in latest.state.buildings do
				if building.id == "b3" then
					outputBefore = building.output
				end
			end
			reveal(screen.Inspector.Content, screen.Inspector.Content.Collect10)
			click(screen.Inspector.Content.Collect10)
			waitFor(function()
				return latest.state.goods.food == beforeGoods + 10
			end, "Collect10 receipt mismatch")
			local outputAfterCollect
			for _, building in latest.state.buildings do
				if building.id == "b3" then
					outputAfterCollect = building.output
				end
			end
			economyEvidence = {
				coinsBefore = beforeCoins,
				goodsBefore = beforeGoods,
				outputBefore = outputBefore,
				outputAfterCollect = outputAfterCollect,
				goodsAfterCollect = latest.state.goods.food,
			}
			character:PivotTo(frame * CFrame.new(-12, 4, -2))
			click(screen.SettlementHUD.Navigation.TradeNavigation)
			local body = screen.Trade.Content
			local sell = body.Sell10
			reveal(body, sell)
			click(sell)
			waitFor(function()
				return latest.state.goods.food == beforeGoods and latest.state.coins == beforeCoins + 20
			end, "Sell10 receipt mismatch")
			economyEvidence.coinsAfterSale, economyEvidence.goodsAfterSale = latest.state.coins, latest.state.goods.food
			body.SaleQuantity.Text = "7"
			click(screen.Trade.MinimizePanel)
			assert(not screen.Trade.Visible and screen.RestoreTrade.Visible, "Trade minimization failed")
			assert(screen.Trade:GetAttribute("PanelOpen") == true, "Minimization revoked logical availability")
			character:PivotTo(frame * CFrame.new(0, 4, 60))
			waitFor(function()
				return string.find(body.SellQuantityReason.Text, "Walk within", 1, true) ~= nil
			end, "Hidden trade stopped revalidating distance")
			character:PivotTo(frame * CFrame.new(-12, 4, -2))
			click(screen.SettlementHUD.MinimizePanel)
			click(screen.RestoreTrade)
			assert(
				screen.Trade.Visible and not screen.SettlementHUD.Visible,
				"HUD minimization closed independent trade"
			)
			assert(body.SaleQuantity.Text == "7", "Minimization discarded quantity draft")
			click(screen.RestoreSettlement)
			if options.editFlow then
				local plans, buildings = latest.state.plans.house, #latest.state.buildings
				click(screen.SettlementHUD.Navigation.BuildNavigation)
				local merchant = screen.Build.Content
				reveal(merchant, merchant.Buy_house)
				click(merchant.Buy_house)
				waitFor(function()
					return latest.state.plans.house == plans + 1
				end, "House plan purchase failed")
				editEvidence = {
					coinsAfterPurchase = latest.state.coins,
					plansBefore = plans,
					plansAfterPurchase = latest.state.plans.house,
					buildingsBefore = buildings,
				}
				merchant = screen.Build.Content
				reveal(merchant, merchant.Place_house)
				click(merchant.Place_house)
				waitFor(function()
					return screen:GetAttribute("PlacingKind") == "house"
				end, "Placement ghost missing")
				click(screen.PlacementControls.PlacementActions.CancelPlacement)
				assert(
					not workspace:FindFirstChild("LocalPlacementFootprint") and latest.state.plans.house == plans + 1,
					"Cancel consumed a plan"
				)
				click(screen.SettlementHUD.Navigation.BuildNavigation)
				merchant = screen.Build.Content
				reveal(merchant, merchant.Place_house)
				click(merchant.Place_house)
				input:SendKey(true, Enum.KeyCode.R, false)
				task.wait(0.1)
				input:SendKey(false, Enum.KeyCode.R, false)
				task.wait(0.2)
				click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
				waitFor(function()
					return #latest.state.buildings == buildings + 1
				end, "Placement receipt missing")
				local placed = latest.state.buildings[#latest.state.buildings]
				assert(
					placed.kind == "house" and placed.x == 12 and placed.z == 10 and placed.rotation == 90,
					"Rotated grid placement mismatch"
				)
				assert(
					latest.state.plans.house == plans and not workspace:FindFirstChild("LocalPlacementFootprint"),
					"Accepted placement did not consume plan and clear ghost"
				)
				editEvidence.plansAfterPlacement, editEvidence.buildingsAfter =
					latest.state.plans.house, #latest.state.buildings
				editEvidence.placement =
					{ id = placed.id, kind = placed.kind, x = placed.x, z = placed.z, rotation = placed.rotation }
			end
		end
		local UI = require(player.PlayerScripts.MiniatureGame.UI)
		assert(latest.state, "Layout fixture needs a selected civilization")
		testGui = Instance.new("ScreenGui")
		testGui.Name, testGui.Parent, testGui.DisplayOrder = "MiniatureLayoutFixture", player.PlayerGui, 100
		local count = 0
		for _, size in { Vector2.new(320, 360), Vector2.new(320, 568), Vector2.new(640, 360), Vector2.new(1024, 768) } do
			local shell = Instance.new("Frame")
			shell.Size, shell.Parent = UDim2.fromOffset(size.X, size.Y), testGui
			local ui = UI.mount(shell, {
				send = function()
					return false
				end,
				camera = function() end,
				place = function() end,
			})
			ui.update(latest, true)
			for _, page in { "Settlement", "Build", "Trade", "Research", "Army", "Select" } do
				ui.navigate(page)
				if page == "Research" and options.nativeResearchInput then
					researchInputs(ui, shell)
				end
				task.wait(0.1)
				assert(
					inside(shell.SettlementHUD, shell) and inside(shell[page], shell),
					"Panel outside viewport: " .. page .. " " .. tostring(size)
				)
				for _, object in shell[page]:GetDescendants() do
					if object:IsA("TextButton") then
						assert(
							object.AbsoluteSize.X >= 44 and object.AbsoluteSize.Y >= 44,
							"Small target: " .. object.Name
						)
					end
				end
			end
			shell:Destroy()
			count += 1
		end
		testGui:Destroy()
		return {
			ok = true,
			layouts = count,
			researchPresentationLayouts = if options.nativeResearchInput then count else 0,
			nativeResearchPresentationInputs = options.nativeResearchInput == true,
			economy = economyEvidence,
			edit = editEvidence,
			nativeEconomyLoop = not options.layoutsOnly,
			nativeWalkAndCamera = not options.layoutsOnly,
			nativeMinimization = not options.layoutsOnly,
			nativeEditFlow = options.editFlow == true,
			relocationWasFixtureSetup = true,
		}
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	input:SendKey(false, Enum.KeyCode.R, false)
	if testGui then
		testGui:Destroy()
	end
	receiptConnection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureGameInputResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = result })
	)
	assert(ok, result)
	return result
end

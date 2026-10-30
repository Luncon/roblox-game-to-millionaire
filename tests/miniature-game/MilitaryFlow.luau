--!strict
-- Real native input and real active-play research clocks. Funding comes only
-- from the explicitly selected fake-store bootstrap; this fixture grants nothing.
type Options = { timeout: number? }

local function run(options: Options?)
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong military fixture boundary"
	)
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(screen and actions, "Military UI is unavailable")
	local catalog = require(Replicated.MiniatureGame.MilitaryResearch)
	local input = Input:CreateVirtualInput()
	local deadline, latest = os.clock() + (if options and options.timeout then options.timeout else 280), nil
	local receipts = {}
	local evidence = {
		nativeVirtualInput = true,
		authorityMutation = false,
		activeClock = true,
		projects = {},
		attempts = {},
		physicalNumberOneTested = false,
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
		Replicated:SetAttribute("MiniatureMilitaryFlowProgress", text)
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
		end, "Military control is unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.1)
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
			end, "No receipt: " .. label)
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
				"Military action rejected: " .. tostring(packet.result.reason)
			)
			waitFor(function()
				return screen:GetAttribute("Revision") >= packet.snapshot.revision
			end, "Fresh research snapshot did not render")
		end
		error("Research retries exhausted")
	end
	local function tree()
		return screen.Research.Content.MilitaryResearchTree
	end
	local function visibleNode(button, graph): boolean
		local first, last = button.AbsolutePosition, button.AbsolutePosition + button.AbsoluteSize
		local corner, extent = graph.AbsolutePosition, graph.AbsolutePosition + graph.AbsoluteWindowSize
		return first.X >= corner.X + 2 and first.Y >= corner.Y + 2 and last.X <= extent.X - 2 and last.Y <= extent.Y - 2
	end
	local function revealNode(button, graph)
		for _ = 1, 20 do
			if visibleNode(button, graph) then
				return
			end
			local center = graph.AbsolutePosition + graph.AbsoluteWindowSize / 2
			local delta = button.AbsolutePosition + button.AbsoluteSize / 2 - center
			local step = Vector2.new(
				math.clamp(-delta.X, -graph.AbsoluteWindowSize.X * 0.4, graph.AbsoluteWindowSize.X * 0.4),
				math.clamp(-delta.Y, -graph.AbsoluteWindowSize.Y * 0.4, graph.AbsoluteWindowSize.Y * 0.4)
			)
			local start = graph.AbsolutePosition
				+ Vector2.new(graph.AbsoluteWindowSize.X * 0.5, graph.AbsoluteWindowSize.Y * 0.85)
				+ Gui:GetGuiInset()
			input:SendMousePosition(start)
			input:SendMouseButton(start, Enum.UserInputType.MouseButton1, true, 0)
			for index = 1, 5 do
				input:SendMousePosition(start + step * (index / 5))
				task.wait(0.04)
			end
			input:SendMouseButton(start + step, Enum.UserInputType.MouseButton1, false, 0)
			task.wait(0.2)
		end
		error("Native tree drag could not reveal node " .. button.Name)
	end
	local ok, failure = pcall(function()
		progress("Waiting for funded snapshot")
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Military snapshot not loaded")
		if not latest.claim or latest.claim.civilizationId ~= "sparta" then
			if not screen.Select.Visible then
				click(screen.SettlementHUD.ChangeCivilization)
			end
			local body = screen.Select.Content
			local choice = body.SelectSparta
			-- Selector is already positioned at Sparta in this fresh fixture.
			action("Select Sparta", function()
				click(choice)
			end)
		end
		waitFor(function()
			return latest.claim and latest.claim.civilizationId == "sparta"
		end, "Sparta selection failed")
		assert(
			next(latest.state.militaryResearch.completed) == nil and latest.state.militaryResearch.project == nil,
			"MilitaryFlow requires fresh, incomplete research"
		)
		local coinsBefore = latest.state.coins
		assert(coinsBefore >= 31000, "Use the explicit research-funded bootstrap")
		evidence.coinsBefore = coinsBefore
		click(screen.OpenResearch)
		waitFor(function()
			return screen.Research.Visible and tree():GetAttribute("SelectedResearch") ~= nil
		end, "Research tree did not open")
		local graph, root = tree().ResearchGraph, tree()
		local nodes, placeholders, connections = 0, 0, 0
		for _, object in root:GetDescendants() do
			if object:IsA("GuiButton") and object:GetAttribute("ResearchId") then
				nodes += 1
				assert(object.AbsoluteSize.X >= 44 and object.AbsoluteSize.Y >= 44, "Research node target is too small")
			elseif object:GetAttribute("FutureResearch") then
				placeholders += 1
				assert(not object:FindFirstChildWhichIsA("GuiButton", true), "Future hexagon is actionable")
			elseif string.find(object.Name, "Connection", 1, true) then
				connections += 1
			end
		end
		assert(
			nodes == 29 and placeholders == 17 and connections == 0 and root:GetAttribute("LayoutId") == "honeycomb-v1",
			"Touching military honeycomb is incomplete or retains connector lines"
		)
		evidence.tree = { nodes = nodes, placeholders = placeholders, connections = connections }
		local oldPan = graph.CanvasPosition
		click(root.TreeControls.PanLeft)
		assert(graph.CanvasPosition.X < oldPan.X, "Tree pan did not move")
		click(root.TreeControls.ZoomOut)
		local zoom = root:GetAttribute("Zoom")
		assert(zoom < 1 and zoom >= 0.75, "Tree zoom did not change")
		click(root.TreeControls.FocusSelected)
		assert(
			visibleNode(graph.HexCanvas.Hex_army_training.Node_army_training, graph),
			"Focus did not reveal selected hexagon"
		)
		local pan, selected = graph.CanvasPosition, root:GetAttribute("SelectedResearch")
		click(screen.Research.MinimizePanel)
		assert(
			not screen.Research.Visible and screen.Research:GetAttribute("PanelOpen") and screen.RestoreResearch.Visible,
			"Research minimization changed logical availability"
		)
		click(screen.RestoreResearch)
		assert(
			screen.Research.Visible
				and root:GetAttribute("SelectedResearch") == selected
				and root:GetAttribute("Zoom") == zoom
				and (graph.CanvasPosition - pan).Magnitude < 1,
			"Minimization lost tree drafts"
		)
		evidence.tree.panZoomMinimization = true
		local totalPrice = 0
		for _, id in { "army_training", "officer_training", "army_control" } do
			root, graph = tree(), tree().ResearchGraph
			local node = graph.HexCanvas["Hex_" .. id]["Node_" .. id]
			revealNode(node, graph)
			click(node)
			waitFor(function()
				return root:GetAttribute("SelectedResearch") == id and root.SelectedNode.StartMilitaryResearch.Active
			end, "Selected research did not become available")
			local coins = latest.state.coins
			local startedAt = os.clock()
			local packet = action("Start " .. id, function()
				click(root.SelectedNode.StartMilitaryResearch)
			end)
			-- Accepted intents rebuild the page; retain only fresh GUI instances.
			root, graph = tree(), tree().ResearchGraph
			node = graph.HexCanvas["Hex_" .. id]["Node_" .. id]
			local definition = catalog.nodes[id]
			assert(
				packet.snapshot.state.coins == coins - definition.price
					and packet.snapshot.state.militaryResearch.project.id == id,
				"Research purchase ledger differs"
			)
			local remaining = packet.snapshot.state.militaryResearch.project.remaining
			assert(remaining > 0 and remaining <= definition.duration, "Research remaining time is invalid")
			waitFor(function()
				return not root.SelectedNode.StartMilitaryResearch.Active
					and string.find(root.ActiveProject.Text, "remaining", 1, true) ~= nil
			end, "Active project UI did not render")
			local spawned = #receipts
			click(screen.Research.MinimizePanel)
			progress("Researching " .. id .. " while minimized")
			waitFor(function()
				return latest.state.militaryResearch.completed[id] == true
			end, "Research failed to finish: " .. id, definition.duration + 8)
			local elapsed = os.clock() - startedAt
			assert(elapsed >= definition.duration - 0.5, "Research completed without its real active duration")
			assert(
				latest.state.coins == coins - definition.price and #receipts == spawned,
				"Completion duplicated payment or a client request"
			)
			click(screen.RestoreResearch)
			waitFor(function()
				return node:GetAttribute("ResearchStatus") == "Completed"
			end, "Completed hexagon did not update")
			table.insert(evidence.projects, {
				id = id,
				duration = definition.duration,
				elapsed = elapsed,
				firstRemaining = remaining,
				coinsBefore = coins,
				coinsAfter = latest.state.coins,
				completedWhileMinimized = true,
			})
			totalPrice += definition.price
		end
		assert(
			latest.state.coins == coinsBefore - totalPrice and totalPrice == 31000,
			"Combined military research ledger differs"
		)
		evidence.coinsAfter = latest.state.coins
		click(screen.Research.Close)
		click(screen.Hotbar.Content.Slot1)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Inventory slot 1 did not open")
		click(screen.Inventory.Close)
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Inventory keyboard B did not open")
		key(Enum.KeyCode.B)
		waitFor(function()
			return not screen.Inventory.Visible
		end, "Inventory keyboard B did not close")
		key(Enum.KeyCode.Two)
		waitFor(function()
			return screen:GetAttribute("HammerSelected") == true
		end, "Hammer key 2 did not select")
		key(Enum.KeyCode.Two)
		waitFor(function()
			return screen:GetAttribute("HammerSelected") ~= true
		end, "Hammer key 2 did not clear")
		assert(screen.Hotbar.Content.Slot3.Active, "Army control did not unlock slot 3")
		key(Enum.KeyCode.Three)
		waitFor(function()
			local panel = screen:FindFirstChild("ArmyControls")
			return panel and panel.Visible
		end, "Army key 3 did not open Army Control")
		evidence.hotbar =
			{ inventorySlot = 1, inventoryKeyboardB = true, hammerKey = 2, armyKey = 3, armyOpened = true }
		progress("Passed")
	end)
	for _, code in { Enum.KeyCode.Two, Enum.KeyCode.Three } do
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
	Replicated:SetAttribute("MiniatureMilitaryFlowResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

--!strict
-- Adversarial local presentation copies. Only Snapshot reaches the server;
-- research, membership, inventory and deploy callbacks record requests locally.
type Options = { timeout: number?, awaitDeath: boolean? }
local function run(options: Options?)
	options = options or {}
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Run = game:GetService("RunService")
	local Http = game:GetService("HttpService")
	assert(
		Run:IsStudio() and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong UI-guard fixture boundary"
	)
	local player = Players.LocalPlayer
	local modules = player.PlayerScripts.MiniatureGame
	local UI, Inventory, Army = require(modules.UI), require(modules.Inventory), require(modules.ArmyControls)
	local Military = require(Replicated.MiniatureGame.MilitaryResearch)
	local Civilizations = require(Replicated.MiniatureGame.Civilizations)
	local input = Input:CreateVirtualInput()
	local deadline, authoritative = os.clock() + (options.timeout or 300), nil
	local requests, contexts = {}, {}
	local networkGameplayReceipts = 0
	local evidence = {
		localPresentationCopies = true,
		fixtureGameplayRequestsSent = 0,
		physicalNumberOneTested = false,
		physicalPhonesTested = false,
		research = {},
		layouts = {},
		previews = {},
		guards = {},
	}
	local layer = Instance.new("ScreenGui")
	layer.Name, layer.DisplayOrder, layer.ResetOnSpawn = "NativeMilitaryUIGuards", 10000, false
	layer.ZIndexBehavior, layer.Parent = Enum.ZIndexBehavior.Sibling, player.PlayerGui
	local receipt = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.requestId and packet.result then
			networkGameplayReceipts += 1
		end
		if packet.snapshot then
			authoritative = packet.snapshot
		end
	end)
	local function progress(label: string)
		Replicated:SetAttribute("MiniatureMilitaryUIGuardsProgress", label)
	end
	local function waitFor(predicate, label: string, seconds: number?)
		local stop = math.min(deadline, os.clock() + (seconds or 10))
		repeat
			if predicate() then
				return
			end
			task.wait(0.03)
		until os.clock() >= stop
		error(label)
	end
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
	local function shown(object): boolean
		while object do
			if object:IsA("GuiObject") and not object.Visible then
				return false
			end
			object = object.Parent
		end
		return true
	end
	local function click(button)
		waitFor(function()
			return button and button.Parent and button.Active and shown(button)
		end, "Local UI button unavailable")
		local point = button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset()
		input:SendMousePosition(point)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.04)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.08)
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.04)
		input:SendKey(false, code, false)
		task.wait(0.1)
	end
	local function reveal(button, scroll)
		scroll.CanvasPosition = Vector2.new(
			scroll.CanvasPosition.X,
			math.max(0, button.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - 6)
		)
		task.wait(0.05)
	end
	local function inside(object, bounds)
		local first, last = object.AbsolutePosition, object.AbsolutePosition + object.AbsoluteSize
		local start, finish = bounds.AbsolutePosition, bounds.AbsolutePosition + bounds.AbsoluteSize
		assert(
			first.X >= start.X - 1 and first.Y >= start.Y - 1 and last.X <= finish.X + 1 and last.Y <= finish.Y + 1,
			object.Name .. " escaped layout bounds"
		)
	end
	local function touchTarget(button)
		assert(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44, button.Name .. " is below44px")
	end
	local function sourceFingerprint(): string
		local rows = {}
		for _, item in Replicated.MiniatureGame.Previews:GetDescendants() do
			if item:IsA("BasePart") then
				table.insert(
					rows,
					item:GetFullName()
						.. tostring(item.CFrame)
						.. tostring(item.Size)
						.. tostring(item.Color)
						.. tostring(item.Transparency)
				)
			elseif item:IsA("Model") then
				table.insert(rows, item:GetFullName() .. tostring(item:GetScale()))
			end
		end
		table.sort(rows)
		return table.concat(rows, "\n")
	end
	local function makeView()
		local view = copy(authoritative)
		view.loaded, view.writable, view.artReady, view.armyControlsUnlocked, view.armySlots = true, true, true, true, 4
		view.claim = view.claim or { civilizationId = "sparta", plotId = 1 }
		view.state.civilizationId, view.claim.civilizationId = "sparta", "sparta"
		view.state.coins, view.state.militaryResearch = 1000000000, { completed = {} }
		view.state.armyGroups = { army2 = {}, army3 = {}, army4 = {} }
		view.state.buildings = {
			{ id = "ui-training", kind = "training", x = 16, z = -22, rotation = 0, output = 0 },
			{ id = "ui-ranged", kind = "ranged", x = 28, z = -22, rotation = 0, output = 0 },
		}
		for _, kind in
			{ "house", "farm", "timber", "material", "workshop", "storehouse", "training", "ranged", "healer", "mount" }
		do
			view.state.plans[kind] = 2
		end
		for _, good in { "food", "timber", "material", "crafted" } do
			view.state.goods[good] = 3
		end
		view.capabilities = {
			select = true,
			travel = true,
			place = true,
			buy = true,
			sellAll = true,
			reclaim = true,
			militaryResearch = true,
			configureArmy = true,
			targetOutpost = true,
		}
		view.outposts = { ui_near = { position = player.Character.HumanoidRootPart.Position } }
		view.armyGroups = {
			{ armyId = 1, buildingIds = { "ui-training", "ui-ranged" }, count = 4, alive = 4 },
			{ armyId = 2, buildingIds = {}, count = 0, alive = 0 },
			{ armyId = 3, buildingIds = {}, count = 0, alive = 0 },
			{ armyId = 4, buildingIds = {}, count = 0, alive = 0 },
		}
		return view
	end
	local function mount(size: Vector2, name: string?)
		local frame = Instance.new("Frame")
		frame.Name, frame.Size, frame.BackgroundTransparency, frame.Parent =
			name or "Presentation", UDim2.fromOffset(size.X, size.Y), 1, layer
		local context = { frame = frame, view = makeView(), forcedReason = nil }
		local ui, inventory, army
		local function send(action, args)
			table.insert(requests, { action = action, args = copy(args), context = frame.Name })
			return true
		end
		ui = UI.mount(frame, {
			send = send,
			camera = function() end,
			closeInventory = function()
				if inventory then
					inventory.close()
				end
			end,
			closeArmy = function()
				if army then
					army.clear()
				end
			end,
		})
		local function guard(action, id)
			return context.forcedReason or ui.guard(action, id)
		end
		inventory = Inventory.start(frame, {
			guard = guard,
			message = function() end,
			closePanels = function()
				ui.closePanels()
				if army then
					army.clear()
				end
			end,
			army = function()
				army.toggle()
			end,
			cancelPlacement = function() end,
			place = function(kind)
				context.placed = kind
			end,
		})
		army = Army.start(frame, {
			getView = function()
				return context.view
			end,
			guard = guard,
			send = send,
			message = function() end,
			closePanels = function()
				ui.closePanels()
				inventory.close()
			end,
			cancelSelection = function()
				inventory.clear()
			end,
		})
		context.ui, context.inventory, context.army = ui, inventory, army
		function context.update(changed)
			ui.update(context.view, changed == true)
			inventory.update(context.view, changed == true)
			army.update(context.view, changed == true)
		end
		function context.destroy()
			army.destroy()
			frame:Destroy()
		end
		table.insert(contexts, context)
		context.update(false)
		task.wait(0.3)
		return context
	end
	local function beginEdit(context)
		context.ui.closePanels()
		context.inventory.close()
		context.army.clear()
		context.army.toggle()
		task.wait(0.05)
		local card = context.frame.ArmyControls.Content.Cards.Army_2
		reveal(card, context.frame.ArmyControls.Content)
		click(card.Edit)
		assert(context.frame:GetAttribute("ArmyEditingId") == 2, "Army2 did not enter edit mode")
		assert(context.army.building("ui-training"), "Local owned-building selection did not route")
		click(context.frame.ArmyControls.MinimizePanel)
		assert(
			context.army.isEditing() and not context.frame.ArmyControls.Visible,
			"Minimization revoked editable draft"
		)
	end
	local ok, failure = pcall(function()
		progress("Read authoritative snapshot")
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return authoritative and authoritative.loaded and authoritative.state
		end, "Selected civilization snapshot required")
		local fingerprint = sourceFingerprint()
		local context = mount(Vector2.new(1024, 768), "ResearchAdversarial")
		context.ui.navigate("Research")
		task.wait(0.2)
		local tree = context.frame.Research.Content.MilitaryResearchTree
		local graph = tree.ResearchGraph
		local function prerequisites(id)
			local result, parent = {}, Military.nodes[id].predecessor
			while parent do
				result[parent] = true
				parent = Military.nodes[parent].predecessor
			end
			return result
		end
		local functional, future = 0, 0
		for _, object in tree:GetDescendants() do
			if object:GetAttribute("ResearchId") then
				functional += 1
			end
			if object:GetAttribute("FutureResearch") then
				future += 1
				assert(not object:FindFirstChildWhichIsA("GuiButton", true), "Future placeholder can receive an action")
			end
		end
		assert(functional == 29 and future == 17, "Research graph inventory differs")
		for index, id in Military.order do
			progress("Research node " .. index .. "/29 · " .. id)
			local definition = Military.nodes[id]
			context.view.state.militaryResearch = { completed = prerequisites(id) }
			context.view.state.coins = definition.price
			context.update(false)
			local node = graph.HexCanvas["Hex_" .. id]["Node_" .. id]
			graph.CanvasPosition = node.AbsolutePosition
				- graph.AbsolutePosition
				+ graph.CanvasPosition
				+ node.AbsoluteSize / 2
				- graph.AbsoluteWindowSize / 2
			task.wait(0.05)
			click(node)
			waitFor(function()
				return tree:GetAttribute("SelectedResearch") == id and tree.SelectedNode.StartMilitaryResearch.Active
			end, "Node selection/availability mismatch: " .. id)
			assert(tree.SelectedNode.DetailsScroll.ResearchName.Text == definition.name, "Selected node name differs")
			assert(
				string.find(tree.SelectedNode.DetailsScroll.ResearchCostTime.Text, tostring(definition.price), 1, true),
				"Selected node price differs"
			)
			local prerequisite = if definition.predecessor then Military.nodes[definition.predecessor].name else "none"
			assert(
				string.find(tree.SelectedNode.DetailsScroll.ResearchPrerequisite.Text, prerequisite, 1, true),
				"Selected prerequisite differs"
			)
			local expected = if definition.effect.scope == "army"
				then "+" .. definition.effect.value
				else "+" .. math.round(definition.effect.value * 100) .. "%"
			assert(
				string.find(tree.SelectedNode.DetailsScroll.ResearchEffect.Text, expected, 1, true),
				"Selected exact effect differs"
			)
			local count = #requests
			click(tree.SelectedNode.StartMilitaryResearch)
			assert(
				#requests == count + 1
					and requests[#requests].action == "militaryResearch"
					and requests[#requests].args.id == id,
				"Research button sent wrong recorded intent"
			)
			context.view.state.coins = 0
			context.update(false)
			assert(
				not tree.SelectedNode.StartMilitaryResearch.Active and node:GetAttribute("ResearchStatus") == "Locked",
				"Unaffordable node remained available"
			)
			context.view.state.militaryResearch.completed[id] = true
			context.update(false)
			assert(
				node:GetAttribute("ResearchStatus") == "Completed"
					and tree.SelectedNode.StartMilitaryResearch.Text == "Completed",
				"Completed state not rendered"
			)
			context.view.state.militaryResearch.completed[id] = nil
			context.view.state.militaryResearch.project = { id = id, remaining = definition.duration / 2 }
			context.update(false)
			assert(
				node:GetAttribute("ResearchStatus") == "Researching"
					and string.find(tree.ActiveProject.Text, tostring(math.ceil(definition.duration / 2)), 1, true),
				"Authoritative project countdown differs"
			)
			table.insert(evidence.research, {
				id = id,
				available = true,
				locked = true,
				completed = true,
				researching = true,
				exactRecordedIntent = true,
			})
		end
		context.view.state.militaryResearch = { completed = {} }
		context.view.state.coins = 1000000000
		context.update(false)
		for _ = 1, 8 do
			click(tree.TreeControls.ZoomOut)
		end
		assert(tree:GetAttribute("Zoom") == 0.75, "Zoom minimum was not clamped")
		for _ = 1, 10 do
			click(tree.TreeControls.ZoomIn)
		end
		assert(tree:GetAttribute("Zoom") == 1.5, "Zoom maximum was not clamped")
		click(tree.TreeControls.PanLeft)
		local zoom, pan, selected =
			tree:GetAttribute("Zoom"), graph.CanvasPosition, tree:GetAttribute("SelectedResearch")
		click(context.frame.Research.MinimizePanel)
		assert(
			context.frame.Research:GetAttribute("PanelOpen") and context.frame.RestoreResearch.Visible,
			"Research logical availability lost"
		)
		click(context.frame.RestoreResearch)
		assert(
			tree:GetAttribute("Zoom") == zoom
				and tree:GetAttribute("SelectedResearch") == selected
				and (graph.CanvasPosition - pan).Magnitude < 1,
			"Research drafts lost on minimize"
		)
		click(context.frame.Research.Close)
		context.ui.navigate("Research")
		task.wait(0.2)
		tree = context.frame.Research.Content.MilitaryResearchTree
		assert(
			tree:GetAttribute("SelectedResearch") == selected and tree:GetAttribute("Zoom") == zoom,
			"Research close/reopen lost drafts"
		)
		evidence.researchNavigation = {
			functional = functional,
			future = future,
			zoomMin = 0.75,
			zoomMax = 1.5,
			minimizedDrafts = true,
			reopenDrafts = true,
		}
		context.destroy()
		for _, size in { Vector2.new(320, 360), Vector2.new(320, 568), Vector2.new(640, 360), Vector2.new(1024, 768) } do
			progress("Layout " .. size.X .. "×" .. size.Y)
			local sample = mount(size, "Layout" .. size.X .. "x" .. size.Y)
			sample.ui.navigate("Research")
			task.wait(0.3)
			inside(sample.frame.Research, sample.frame)
			local localTree = sample.frame.Research.Content.MilitaryResearchTree
			inside(localTree, sample.frame.Research)
			inside(localTree.ResearchGraph, localTree)
			inside(localTree.SelectedNode, localTree)
			touchTarget(localTree.SelectedNode.StartMilitaryResearch)
			for _, button in localTree.TreeControls:GetChildren() do
				if button:IsA("GuiButton") then
					touchTarget(button)
					inside(button, localTree)
				end
			end
			assert(
				not sample.frame.Hotbar.Visible and not sample.frame.OpenResearch.Visible,
				"Research has overlapping hotbar/side entry"
			)
			sample.ui.closePanels()
			sample.inventory.toggle()
			task.wait(0.25)
			inside(sample.frame.Inventory, sample.frame)
			assert(sample.frame.Inventory.Content.AbsoluteSize.Y >= 104, "Inventory cannot show a complete grid tile")
			local tile = sample.frame.Inventory.Content.Plan_house
			reveal(tile, sample.frame.Inventory.Content)
			touchTarget(tile)
			assert(
				tile.StackCount.Text == "×2" and tile.ItemPreview:FindFirstChildOfClass("WorldModel"),
				"Grid preview/count missing"
			)
			sample.inventory.close()
			sample.army.toggle()
			task.wait(0.1)
			inside(sample.frame.ArmyControls, sample.frame)
			local cards = sample.frame.ArmyControls.Content.Cards
			for index = 2, 4 do
				local card = cards["Army_" .. index]
				reveal(card.Edit, sample.frame.ArmyControls.Content)
				touchTarget(card.Edit)
				touchTarget(card.Reset)
				click(card.Edit)
				assert(sample.frame:GetAttribute("ArmyEditingId") == index, "Scrolled army card cannot be edited")
			end
			table.insert(evidence.layouts, {
				width = size.X,
				height = size.Y,
				researchBounds = true,
				inventoryCompleteTile = true,
				armyScrollCards = true,
				minimumTargets = 44,
			})
			sample.destroy()
		end
		local guards = mount(Vector2.new(1024, 768), "ContextGuards")
		for _, civilization in Civilizations do
			progress("Preview grid " .. civilization.id)
			guards.view.claim.civilizationId, guards.view.state.civilizationId = civilization.id, civilization.id
			guards.update(true)
			guards.inventory.toggle()
			task.wait(0.05)
			local count = 0
			for _, tile in guards.frame.Inventory.Content:GetChildren() do
				if tile:IsA("GuiButton") and string.match(tile.Name, "^Plan_") then
					assert(
						tile.ItemPreview:FindFirstChildOfClass("WorldModel") and tile.StackCount.Text == "×2",
						"Civilization grid source/count missing"
					)
					assert(
						tile:GetAttribute("PreviewCivilization") == civilization.id,
						"Grid uses another civilization's preview"
					)
					count += 1
				end
			end
			assert(count == 10, "Civilization grid is incomplete")
			table.insert(evidence.previews, { civilizationId = civilization.id, plans = count })
			guards.inventory.close()
		end
		guards.view.claim.civilizationId, guards.view.state.civilizationId = "sparta", "sparta"
		guards.update(true)
		click(guards.frame.Hotbar.Content.Slot1)
		assert(guards.frame.Inventory.Visible, "Slot1 button did not open the local inventory")
		click(guards.frame.Inventory.Close)
		local textbox = Instance.new("TextBox")
		textbox.Name, textbox.Size, textbox.Position, textbox.ZIndex, textbox.Parent =
			"TypingGuard", UDim2.fromOffset(180, 44), UDim2.fromOffset(400, 8), 100, guards.frame
		textbox:CaptureFocus()
		waitFor(function()
			return Input:GetFocusedTextBox() == textbox
		end, "TextBox did not capture native focus")
		local count = #requests
		for _, code in { Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.B } do
			key(code)
		end
		assert(
			not guards.inventory.hammerSelected()
				and not guards.frame.ArmyControls:GetAttribute("PanelOpen")
				and not guards.frame.Inventory:GetAttribute("PanelOpen")
				and #requests == count,
			"Typing activated inventory/hammer/army"
		)
		textbox:ReleaseFocus()
		textbox:Destroy()
		key(Enum.KeyCode.Two)
		waitFor(function()
			return guards.inventory.hammerSelected()
		end, "Keyboard2 failed outside TextBox")
		key(Enum.KeyCode.Two)
		assert(not guards.inventory.hammerSelected(), "Keyboard2 failed to clear")
		key(Enum.KeyCode.B)
		assert(guards.frame.Inventory.Visible, "Keyboard B did not open inventory")
		key(Enum.KeyCode.B)
		assert(not guards.frame.Inventory.Visible, "Keyboard B did not close inventory")
		key(Enum.KeyCode.Three)
		assert(guards.frame.ArmyControls.Visible, "Keyboard3 did not open armies")
		key(Enum.KeyCode.Three)
		assert(not guards.frame.ArmyControls:GetAttribute("PanelOpen"), "Keyboard3 did not close armies")
		evidence.keyboard = {
			inventorySlotOneButton = true,
			textboxSuppression = true,
			hammerTwo = true,
			inventoryB = true,
			armyThree = true,
			oneExcludedByCoreGui = true,
		}
		beginEdit(guards)
		guards.view.claimEpoch += 1
		guards.update(true)
		assert(
			not guards.army.isEditing() and not guards.frame.RestoreArmyControls.Visible,
			"Stale claim retained hidden editor"
		)
		evidence.guards.claimChanged = true
		beginEdit(guards)
		guards.view.writable = false
		guards.update(false)
		assert(not guards.army.isEditing(), "Read-only context retained hidden editor")
		evidence.guards.readOnly = true
		guards.view.writable = true
		guards.update(false)
		beginEdit(guards)
		guards.view.state.buildings = { guards.view.state.buildings[2] }
		guards.update(false)
		click(guards.frame.RestoreArmyControls)
		assert(
			string.find(guards.frame.ArmyControls.Content.Editor.SelectionSummary.Text, "0 buildings", 1, true),
			"Removed building remained in hidden draft"
		)
		reveal(guards.frame.ArmyControls.Content.Editor.Save, guards.frame.ArmyControls.Content)
		click(guards.frame.ArmyControls.Content.Editor.Save)
		assert(
			requests[#requests].action == "configureArmy" and #requests[#requests].args.buildingIds == 0,
			"Removed draft building reached recorded request"
		)
		evidence.guards.removedBuilding = true
		guards.view = makeView()
		guards.update(true)
		guards.army.deploy("ui_near")
		click(guards.frame.ArmyDeploy.MinimizePanel)
		guards.view.outposts.ui_near.position += Vector3.new(100, 0, 0)
		guards.update(false)
		waitFor(function()
			return not guards.frame.ArmyDeploy:GetAttribute("PanelOpen")
				and guards.frame:GetAttribute("ArmyDeployOutpostId") == nil
		end, "Hidden deploy survived out-of-range context")
		evidence.guards.hiddenDeployRange = true
		guards.view = makeView()
		guards.update(true)
		guards.army.toggle()
		click(guards.frame.ArmyControls.MinimizePanel)
		guards.army.toggle()
		guards.army.toggle()
		assert(guards.frame.ArmyControls.Visible, "Toolbar reopen retained stale minimized flag")
		guards.army.clear()
		guards.army.deploy("ui_near")
		click(guards.frame.ArmyDeploy.MinimizePanel)
		guards.view.outposts.ui_near.position += Vector3.new(100, 0, 0)
		task.wait(0.3)
		guards.view.outposts.ui_near.position = player.Character.HumanoidRootPart.Position
		guards.army.deploy("ui_near")
		assert(guards.frame.ArmyDeploy.Visible, "New deployment retained stale minimized flag")
		evidence.guards.reopenMinimized = true
		guards.army.clear()
		if options.awaitDeath then
			progress("Await owned commander death")
			beginEdit(guards)
			local deathDeploy = mount(Vector2.new(1024, 768), "DeathDeploy")
			deathDeploy.army.deploy("ui_near")
			click(deathDeploy.frame.ArmyDeploy.MinimizePanel)
			local oldCharacter, oldEpoch = player.Character, authoritative.claimEpoch
			Replicated:SetAttribute("MiniatureMilitaryUIGuardsDeathOwnerId", player.UserId)
			Replicated:SetAttribute("MiniatureMilitaryUIGuardsDeathReady", true)
			waitFor(function()
				local humanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
				return humanoid == nil or humanoid.Health <= 0
			end, "Root did not execute the explicit owned death setup", 35)
			waitFor(function()
				return not guards.army.isEditing() and not deathDeploy.frame.ArmyDeploy:GetAttribute("PanelOpen")
			end, "Death retained hidden edit or deploy")
			waitFor(function()
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				return character ~= oldCharacter
					and humanoid
					and humanoid.Health > 0
					and authoritative.claimEpoch > oldEpoch
			end, "Real new life did not restore", 35)
			assert(
				not guards.army.building("ui-training")
					and guards.frame:GetAttribute("ArmyEditingId") == nil
					and deathDeploy.frame:GetAttribute("ArmyDeployOutpostId") == nil,
				"Fresh life reused an old hidden draft"
			)
			evidence.actualDeath = {
				oldEpoch = oldEpoch,
				newEpoch = authoritative.claimEpoch,
				hiddenEditorCleared = true,
				hiddenDeployCleared = true,
				oldDraftInert = true,
			}
			Replicated:SetAttribute("MiniatureMilitaryUIGuardsDeathReady", false)
			deathDeploy.destroy()
		else
			evidence.actualDeath =
				{ tested = false, reason = "awaitDeath option was not requested; actual Humanoid was not modified" }
		end
		assert(sourceFingerprint() == fingerprint, "UI mutated shared civilization preview sources")
		evidence.previewSourcesImmutable = true
		guards.destroy()
		assert(networkGameplayReceipts == 0, "Isolated UI fixture observed an actual network gameplay receipt")
		progress("Passed")
	end)
	for _, code in { Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.B } do
		pcall(function()
			input:SendKey(false, code, false)
		end)
	end
	pcall(function()
		input:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton1, false, 0)
	end)
	pcall(function()
		local focused = Input:GetFocusedTextBox()
		if focused and focused:IsDescendantOf(layer) then
			focused:ReleaseFocus()
		end
	end)
	Replicated:SetAttribute("MiniatureMilitaryUIGuardsDeathReady", false)
	for _, context in contexts do
		pcall(context.destroy)
	end
	layer:Destroy()
	receipt:Disconnect()
	evidence.actualNetworkGameplayReceipts = networkGameplayReceipts
	if networkGameplayReceipts ~= 0 then
		ok, failure = false, "Isolated UI fixture observed an actual network gameplay receipt"
	end
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if ok then nil else evidence }
	Replicated:SetAttribute("MiniatureMilitaryUIGuardsResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

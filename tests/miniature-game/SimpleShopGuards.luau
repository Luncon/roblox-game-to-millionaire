--!strict
-- Run after SimpleShopFlow in the same isolated fake-store native Play.
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
	assert(screen, "Simple shop guards UI missing")
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
		Replicated:SetAttribute("MiniatureSimpleShopGuardsProgress", label)
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
			troops = copy(view.troops),
			troopCapacity = view.troopCapacity,
		}
	end
	local function ledger(view)
		return {
			coins = view.state.coins,
			plans = copy(view.state.plans),
			goods = copy(view.state.goods),
			buildingCount = #view.state.buildings,
			civilianCount = #view.state.workers,
			troops = copy(view.troops),
			troopCapacity = view.troopCapacity,
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
		end, "Simple shop guards control unavailable: " .. (button and button:GetFullName() or "missing"))
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
		error("Simple shop guards attempts exhausted: " .. label)
	end
	local function closePanels()
		for _, name in { "Build", "Trade", "Inventory", "Select" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible then
				click(panel.Close)
			end
		end
	end
	local function mutation(label, pressControl)
		for attempt = 1, 3 do
			local before = #receipts
			pressControl()
			waitFor(function()
				return #receipts > before
			end, "No receipt: " .. label)
			local packet = receipts[before + 1]
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			task.wait(0.2)
		end
		error("Mutation attempts exhausted: " .. label)
	end
	local function travel(buttonName, destination)
		local packet = mutation("travel " .. destination, function()
			click(screen.TopNavigation[buttonName])
		end)
		assert(packet.result.destination == destination, "Wrong server travel destination")
		if destination == "civilization" then
			waitFor(function()
				return not screen.Build.Visible
					and not screen.Trade.Visible
					and not screen.Select.Visible
					and not screen.Inventory.Visible
			end, "Civilization travel opened a modal")
		else
			local name = if destination == "buy" then "Build" else "Trade"
			waitFor(function()
				return screen[name].Visible
			end, "Travel did not open " .. name)
		end
	end
	local function choose(id)
		travel("Civilization", "civilization")
		if not screen.SettlementHUD.Visible and screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
		click(screen.SettlementHUD.ChangeCivilization)
		local packet = action("Select", "Select" .. (if id == "sparta" then "Sparta" else id), "choose " .. id)
		assert(packet.snapshot.claim.civilizationId == id, "Wrong civilization restored")
		return packet.snapshot
	end
	local function buyHouse()
		click(screen.Build.Content.ShopTabs.Category_Homes)
		local list = screen.Build.Content.ShopList
		local row = list.Row_house
		list.CanvasPosition =
			Vector2.new(0, math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y))
		task.wait(0.2)
		return mutation("buy death-check house", function()
			click(row.Buy_house)
		end)
	end
	local function verifyTroops()
		local expected = copy(latest.troops)
		assert(expected and latest.troopCapacity == 10, "Fixed ten-troop capacity missing")
		assert(expected.melee + expected.ranged + expected.medic <= 10, "Buildings raised the global troop limit")
		local plot = workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local groups = {}
		waitFor(function()
			local counts = { melee = 0, ranged = 0, medic = 0 }
			groups = {}
			for _, actor in plot.Actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "roster" then
					local role = actor:GetAttribute("RosterRole")
					assert(
						counts[role]
							and actor:GetAttribute("AutomaticTroop")
							and actor:GetAttribute("OwnerId") == player.UserId,
						"Foreign or manual troop presentation"
					)
					local ownedBuilding = false
					for _, building in latest.state.buildings do
						if building.id == actor:GetAttribute("BuildingId") then
							ownedBuilding = true
						end
					end
					assert(ownedBuilding, "Automatic troop lost its owned building")
					counts[role] += 1
					local id = actor:GetAttribute("BuildingId")
					groups[id] = groups[id] or { melee = 0, ranged = 0, medic = 0 }
					groups[id][role] += 1
				end
			end
			return equal(expected, counts)
		end, "Automatic troop figures did not survive context change")
		for _, building in latest.state.buildings do
			local group = groups[building.id]
			if group then
				local expectedGroup = { melee = 0, ranged = 0, medic = 0 }
				if building.kind == "training" then
					expectedGroup.melee = 2
				elseif building.kind == "ranged" then
					expectedGroup.ranged = 2
				else
					assert(building.kind == "healer", "Troops appeared at a civilian building")
					expectedGroup.medic = 1
				end
				assert(equal(group, expectedGroup), "Partial or incorrect automatic building group")
			end
		end
		return { counts = expected, groups = groups }
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
			"Wrong simple shop guards boundary"
		)
		local previousFlow = Replicated:GetAttribute("MiniatureSimpleShopFlowResult")
		assert(previousFlow and Http:JSONDecode(previousFlow).ok, "Run passing SimpleShopFlow first in the same Play")
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.claim and latest.state
		end, "Simple shop guards snapshot missing")
		assert(latest.claim.civilizationId == "sparta", "Simple shop guards begins on Sparta after SimpleShopFlow")
		assert(
			not latest.state.settings.autoCollect and not latest.state.settings.autoSell,
			"Fixture needs manual goods inventory"
		)
		step("four bounded real-module layouts")
		layoutGui = Instance.new("ScreenGui")
		layoutGui.Name, layoutGui.DisplayOrder, layoutGui.Parent = "SimpleShopGuardLayouts", 100, player.PlayerGui
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
			for _, old in
				{
					"Inspector",
					"Research",
					"Army",
					"UpgradeHall",
					"ApplyRoster",
					"OpenResearch",
					"OpenArmy",
					"HireWorker",
				}
			do
				assert(not shell:FindFirstChild(old, true), "Removed product control remains: " .. old)
			end
			local rowCount = 0
			for _, page in { "Build", "Trade", "Select" } do
				ui.navigate(page)
				task.wait(0.15)
				assert(inside(shell[page], shell), "Compact popup outside bounds: " .. page)
				if page == "Build" then
					assert(
						shell.Build.AbsoluteSize.X <= 420 and shell.Build.AbsoluteSize.Y <= 360,
						"Shop became a large management panel"
					)
					for _, category in { "Homes", "Production", "Military" } do
						local tabs = shell.Build.Content.ShopTabs
						local tabCount, rowY = 0, nil
						for _, tab in tabs:GetChildren() do
							if tab:IsA("TextButton") then
								tabCount += 1
								assert(tab.AbsoluteSize.X >= 44 and tab.AbsoluteSize.Y >= 44, "Small category target")
								assert(
									not rowY or math.abs(tab.AbsolutePosition.Y - rowY) <= 1,
									"Shop tabs are not horizontal"
								)
								rowY = tab.AbsolutePosition.Y
							end
						end
						assert(
							tabCount == 3 and not tabs:FindFirstChild("Category_Civic"),
							"Shop must have exactly three tabs"
						)
						click(tabs["Category_" .. category])
						task.wait(0.15)
						local list = shell.Build.Content.ShopList
						assert(
							list:IsA("ScrollingFrame") and list.ScrollingDirection == Enum.ScrollingDirection.Y,
							"Shop list is not scrollable"
						)
						assert(inside(list, shell.Build), "Shop scroller outside compact popup")
						for kind, definition in Catalog.buildings do
							if definition.price and definition.category == category then
								local row = list:FindFirstChild("Row_" .. kind)
								assert(
									row and row.Title.Text ~= "" and row.Description.Text ~= "" and row.Stock.Text ~= "",
									"Compact shop row missing: " .. kind
								)
								local viewport = row.Thumbnail
								local world = viewport:FindFirstChildOfClass("WorldModel")
								local model = world and world:FindFirstChildOfClass("Model")
								assert(
									viewport:IsA("ViewportFrame")
										and viewport.CurrentCamera
										and model
										and model:GetAttribute("CivilizationId") == latest.state.civilizationId,
									"Actual civilization thumbnail missing: " .. kind
								)
								local buy = row["Buy_" .. kind]
								assert(
									buy.AbsoluteSize.X >= 44 and buy.AbsoluteSize.Y >= 44,
									"Small compact buy target"
								)
								rowCount += 1
							end
						end
					end
				elseif page == "Trade" then
					assert(
						shell.Trade.AbsoluteSize.X <= 280 and shell.Trade.AbsoluteSize.Y <= 200,
						"Sell popup is not compact"
					)
					assert(shell.Trade.Content.SellAll.AbsoluteSize.Y >= 44, "Small SellAll target")
				end
				for _, button in shell[page]:GetDescendants() do
					if button:IsA("TextButton") then
						assert(
							button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44,
							"Small popup target: " .. button.Name
						)
					end
				end
			end
			assert(rowCount == 9, "Not all nine building types appeared across the three tabs")
			inventory.toggle()
			task.wait(0.1)
			assert(shell.Inventory.Visible and inside(shell.Inventory, shell), "Inventory panel outside bounds")
			local planControls = 0
			for kind, definition in Catalog.buildings do
				if not definition.price then
					continue
				end
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
			table.insert(evidence.layouts, {
				width = size.X,
				height = size.Y,
				topButtons = count,
				planControls = planControls,
				hotbarSlots = 9,
				shopRows = rowCount,
			})
			shell:Destroy()
		end
		layoutGui:Destroy()
		layoutGui = nil
		step("actual Rome to Sparta preservation")
		local before = copy(latest)
		evidence.switch = { before = ledger(before) }
		local groupsBeforeSwitch = verifyTroops()
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
		evidence.switch.troops = verifyTroops()
		assert(equal(groupsBeforeSwitch, evidence.switch.troops), "Civilization switch changed automatic troop groups")
		step("buy held house item for death placement draft")
		travel("Buy", "buy")
		local purchaseCoins, purchasePlans = latest.state.coins, latest.state.plans.house
		assert(purchaseCoins >= 80, "Insufficient earned coins for explicit house purchase")
		local purchase = buyHouse()
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
		local groupsBeforeDeath = verifyTroops()
		step("waiting for root explicit owned server Humanoid death")
		Replicated:SetAttribute("MiniatureSimpleShopDeathOwnerId", player.UserId)
		Replicated:SetAttribute("MiniatureSimpleShopDeathReady", true)
		waitFor(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return character
				and character ~= oldCharacter
				and humanoid
				and humanoid.Health > 0
				and character:FindFirstChild("HumanoidRootPart")
		end, "New living character did not arrive after explicit death", 35)
		Replicated:SetAttribute("MiniatureSimpleShopDeathReady", false)
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
		evidence.death.troops = verifyTroops()
		assert(equal(groupsBeforeDeath, evidence.death.troops), "Respawn changed automatic troop groups")
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
		evidence.death.gameOwnedInputOnly = true
		evidence.death.horizontalWalk, evidence.death.verticalChange = walked, delta.Y
		evidence.death.moveDirection = { x = direction.X, y = direction.Y, z = direction.Z }
		evidence.death.ghostCleared, evidence.death.selectionCleared, evidence.death.progressPreserved =
			true, true, true
		evidence.ok = true
		return evidence
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	Replicated:SetAttribute("MiniatureSimpleShopDeathReady", false)
	if layoutGui then
		layoutGui:Destroy()
	end
	if deathConnection then
		deathConnection:Disconnect()
	end
	connection:Disconnect()
	Replicated:SetAttribute(
		"MiniatureSimpleShopGuardsResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, tostring(result))
	return result
end

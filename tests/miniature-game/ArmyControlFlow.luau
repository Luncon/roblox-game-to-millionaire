--!strict
-- Continues NativeMilitaryFlow using paid structures, actual world clicks and
-- native commander walking. No troop, profile, position or research injection.
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
		"Wrong army-control fixture boundary"
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
		Replicated:SetAttribute("MiniatureArmyControlFlowProgress", text)
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
	local function place(kind, x, z)
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Army inventory did not open")
		local body, tile = screen.Inventory.Content, screen.Inventory.Content["Plan_" .. kind]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, tile.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 4))
		task.wait(0.2)
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
	local function actors(ids)
		local result = {}
		for _, model in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
			if ids[model:GetAttribute("BuildingId")] and model:GetAttribute("Alive") == true then
				result[model.Name] =
					{ model = model, life = model:GetAttribute("Life"), health = model:GetAttribute("Health") }
			end
		end
		return result
	end
	local function unchanged(before)
		for id, saved in before do
			local current = Workspace.MiniatureSandbox.BattleActors:FindFirstChild(id)
			assert(
				current == saved.model
					and current:GetAttribute("Life") == saved.life
					and current:GetAttribute("Health") <= saved.health,
				"Preset edit replaced or healed an existing troop"
			)
		end
	end
	local function openArmy()
		if not screen.ArmyControls.Visible then
			key(Enum.KeyCode.Three)
		end
		waitFor(function()
			return screen.ArmyControls.Visible
		end, "Army Controls did not open")
	end
	local function configure(id)
		openArmy()
		click(screen.ArmyControls.Content.Cards.Army_2.Edit)
		waitFor(function()
			return screen:GetAttribute("ArmyEditingId") == 2
		end, "Army 2 editor did not open")
		click(screen.ArmyControls.MinimizePanel)
		assert(
			not screen.ArmyControls.Visible
				and screen.ArmyControls:GetAttribute("PanelOpen")
				and screen:GetAttribute("ArmyEditingId") == 2,
			"Minimizing disabled Army 2 editing"
		)
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local model = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId].Buildings[id]
		local target = model:FindFirstChild("SelectTarget") or model.PrimaryPart
		assert(target and target:IsA("BasePart"), "Army world selection target missing")
		local point, shown = Workspace.CurrentCamera:WorldToViewportPoint(target.Position)
		assert(shown, "Army building selection is outside camera")
		-- World click coordinates use viewport coordinates, unlike GuiObject input.
		clickPoint(Vector2.new(point.X, point.Y))
		click(screen.RestoreArmyControls)
		waitFor(function()
			return screen.ArmyControls.Visible
				and string.find(screen.ArmyControls.Content.Editor.SelectionSummary.Text, "1 buildings", 1, true)
					~= nil
		end, "Minimized world selection did not preserve Army 2 draft")
		local countBefore = #latest.state.armyGroups.army2
		assert(countBefore == 0, "Army fixture requires empty editable draft")
		local before = actors({ [id] = true })
		local packet = action("Save Army 2", function()
			click(screen.ArmyControls.Content.Editor.Save)
		end)
		assert(
			packet.result.armyId == 2 and #latest.state.armyGroups.army2 == 1 and latest.state.armyGroups.army2[1] == id,
			"Army 2 membership did not save"
		)
		unchanged(before)
	end
	local ok, failure = pcall(function()
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Army snapshot unavailable")
		assert(
			latest.claim and latest.claim.civilizationId == "sparta" and latest.armyControlsUnlocked,
			"Complete NativeMilitaryFlow first"
		)
		assert(
			#latest.state.armyGroups.army2 == 0 and latest.troopCapacityUsed == 0,
			"ArmyControlFlow requires empty groups and no military structures"
		)
		local coins = latest.state.coins
		local proposals = table.clone(latest.state.buildings)
		for index, site in { { kind = "training", x = 16, z = -22 }, { kind = "ranged", x = 28, z = -22 } } do
			local legal, why = Placement.validate(proposals, site.kind, site.x, site.z, 0)
			assert(legal, "Army footprint preflight failed: " .. tostring(why))
			table.insert(
				proposals,
				{ id = "army-preflight-" .. index, kind = site.kind, x = site.x, z = site.z, rotation = 0 }
			)
		end
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Army building shop unavailable")
		click(screen.Build.Content.ShopTabs.Category_Military)
		local purchased, reused = 0, {}
		for _, kind in { "training", "ranged" } do
			if latest.state.plans[kind] == 0 then
				buy(kind)
				purchased += Catalog.buildings[kind].price
			else
				reused[kind] = latest.state.plans[kind]
			end
		end
		travel("Civilization", "civilization")
		local melee = place("training", 16, -22)
		local ranged = place("ranged", 28, -22)
		waitFor(function()
			local count = 0
			for _ in actors({ [melee.id] = true, [ranged.id] = true }) do
				count += 1
			end
			return count == 4
		end, "Paid army did not spawn four troops")
		assert(
			latest.state.coins == coins - purchased and latest.troopCapacityUsed == 4,
			"Army purchase/capacity ledger differs"
		)
		evidence.coinsBefore, evidence.coinsAfter = coins, latest.state.coins
		evidence.purchase = { coinsSpentThisRun = purchased, reusedPaidPlans = reused }
		evidence.buildingWalk = walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(melee.x, 0.4, melee.z)))
		configure(melee.id)
		assert(
			#latest.armyGroups[1].buildingIds == 2 and #latest.armyGroups[2].buildingIds == 1,
			"Army 1 stopped including every structure"
		)
		local before = actors({ [melee.id] = true, [ranged.id] = true })
		action("Reset Army 2", function()
			click(screen.ArmyControls.Content.Cards.Army_2.Reset)
		end)
		assert(
			#latest.state.armyGroups.army2 == 0 and #latest.armyGroups[1].buildingIds == 2,
			"Reset changed all-troops army"
		)
		unchanged(before)
		configure(melee.id)
		evidence.membership = {
			army1Buildings = 2,
			army2Buildings = 1,
			buildingId = melee.id,
			resetReconfigured = true,
			livingActorsPreserved = true,
			minimizedWorldSelection = true,
		}
		local ownId = "outpost_" .. latest.claim.plotId
		local destination, distance = nil, math.huge
		local root = player.Character.HumanoidRootPart
		for id, site in latest.outposts do
			local candidate = (site.position - root.Position).Magnitude
			if id ~= ownId and candidate < distance then
				destination, distance = id, candidate
			end
		end
		assert(destination, "Independent target outpost missing")
		local originalTarget = latest.armyGroups[1].targetId
		progress("Walk to independent outpost")
		evidence.outpostWalk = walkTo(latest.outposts[destination].position)
		key(Enum.KeyCode.E)
		waitFor(function()
			return screen.ArmyDeploy.Visible and screen:GetAttribute("ArmyDeployOutpostId") == destination
		end, "E did not open the army deploy chooser")
		local packet = action("Deploy Army 2", function()
			click(screen.ArmyDeploy.Content.Cards.Army_2.Deploy)
		end)
		assert(
			packet.result.armyId == 2 and packet.result.outpostId == destination,
			"Army 2 deployment receipt differs"
		)
		waitFor(function()
			return latest.armyGroups[2].targetId == destination
		end, "Selected group did not target independent outpost")
		assert(
			latest.armyGroups[1].mixedTargets == true and latest.army.targetId == originalTarget,
			"Group command redirected Army 1 default"
		)
		local observedAssigned, observedUnassigned = false, false
		waitFor(function()
			for _, model in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
				local id = model:GetAttribute("BuildingId")
				if id == melee.id then
					observedAssigned = model:GetAttribute("TargetOutpostId") == destination or observedAssigned
				elseif id == ranged.id then
					assert(
						model:GetAttribute("TargetOutpostId") == originalTarget,
						"Unassigned ranged structure was redirected"
					)
					observedUnassigned = true
				end
			end
			return observedAssigned and observedUnassigned
		end, "Live or replacement actors did not reflect isolated group targets", 20)
		evidence.deployment = {
			armyId = 2,
			targetId = destination,
			defaultTargetId = originalTarget,
			assignedActorObserved = observedAssigned,
			unassignedActorObserved = observedUnassigned,
			army1MixedTargets = true,
		}
		progress("Passed")
	end)
	for _, code in { Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.B, Enum.KeyCode.Three } do
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
	Replicated:SetAttribute("MiniatureArmyControlFlowResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

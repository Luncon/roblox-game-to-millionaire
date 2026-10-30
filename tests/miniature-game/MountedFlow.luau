--!strict
-- Native client purchase/place acceptance. The bootstrap declares funding;
-- this module never grants Coins, edits drafts, relocates actors or loads controls.
type Options = { extended: boolean?, capture: boolean?, timeout: number?, captureTimeout: number? }
local function run(options: Options?)
	options = options or {}
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Workspace = game:GetService("Workspace")
	local player = Players.LocalPlayer
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong mounted UI fixture boundary"
	)
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(screen and actions, "Mounted UI unavailable")
	local MountConfig = require(Replicated.MiniatureGame.MountConfig)
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	local input = Input:CreateVirtualInput()
	local deadline, latest = os.clock() + (options.timeout or (if options.extended then 600 else 150)), nil
	local receipts, evidence =
		{}, { nativeVirtualInput = true, authoritativeMutation = false, localRelocation = false, attempts = {} }
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
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
	local function clickPoint(point)
		input:SendMousePosition(point)
		task.wait(0.08)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.08)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.25)
	end
	local function click(button)
		waitFor(function()
			return button and button.Visible and button.Active
		end, "Mounted flow button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.1)
		input:SendKey(false, code, false)
		task.wait(0.2)
	end
	local function action(label: string, press)
		Replicated:SetAttribute("MiniatureMountedFlowProgress", label)
		for attempt = 1, 3 do
			local before = #receipts
			press()
			waitFor(function()
				return #receipts > before
			end, "Missing mounted flow receipt: " .. label)
			local packet = receipts[before + 1]
			table.insert(evidence.attempts, {
				label = label,
				requestId = packet.requestId,
				ok = packet.result.ok,
				reason = packet.result.reason,
				revision = packet.snapshot.revision,
			})
			if packet.result.ok then
				return packet
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				"Mounted action refused: " .. tostring(packet.result.reason)
			)
			waitFor(function()
				return screen:GetAttribute("Revision") >= packet.snapshot.revision
			end, "Fresh mounted receipt not rendered")
		end
		error("Mounted native action retry exhausted")
	end
	local function bodyButton(page, name)
		local body = screen[page].Content
		local button = body:FindFirstChild(name)
		assert(button, "Mounted inventory/selection control missing")
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		click(button)
	end
	local function travel(name, destination)
		local packet = action("travel " .. destination, function()
			click(screen.TopNavigation[name])
		end)
		assert(packet.result.destination == destination, "Mounted flow travel destination differs")
	end
	local function closePanels()
		for _, name in { "Build", "Trade", "Select", "Inventory" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible then
				click(panel.Close)
			end
		end
	end
	local function findBuilding(id)
		for _, building in latest.state.buildings do
			if building.id == id then
				return building
			end
		end
		return nil
	end
	local function buyItem(kind)
		local list = screen.Build.Content.ShopList
		local row = list["Row_" .. kind]
		assert(row, "Extended mounted shop row missing")
		list.CanvasPosition =
			Vector2.new(0, math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8))
		task.wait(0.2)
		local coins, plans, used = latest.state.coins, latest.state.plans[kind], latest.troopCapacityUsed
		local packet = action("buy " .. kind, function()
			click(row["Buy_" .. kind])
		end)
		assert(
			packet.snapshot.state.coins == coins - Catalog.buildings[kind].price
				and packet.snapshot.state.plans[kind] == plans + 1
				and packet.snapshot.troopCapacityUsed == used,
			"Extended purchase ledger differs"
		)
	end
	local function placeItem(kind, x, z, rotation)
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Extended inventory missing")
		bodyButton("Inventory", "Plan_" .. kind)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == kind
		end, "Extended building item not selected")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, shown =
			Workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
		assert(shown, "Extended placement point outside view")
		for _ = 1, 3 do
			clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
			local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
			local localPoint = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
			if localPoint and math.abs(localPoint.X - x) < 0.01 and math.abs(localPoint.Z - z) < 0.01 then
				break
			end
		end
		local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
		local localPoint = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
		assert(
			localPoint and math.abs(localPoint.X - x) < 0.01 and math.abs(localPoint.Z - z) < 0.01,
			"Extended native click did not reach intended ground"
		)
		for _ = 1, rotation / 90 do
			key(Enum.KeyCode.R)
		end
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("place " .. kind, function()
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local placed = findBuilding(packet.result.buildingId)
		assert(
			placed and placed.kind == kind and placed.x == x and placed.z == z and placed.rotation == rotation,
			"Extended placement receipt differs"
		)
		assert(
			latest.state.coins == coins and latest.state.plans[kind] == plans - 1,
			"Extended placement charged Coins or consumed wrong plan"
		)
		table.insert(evidence.placements, { id = placed.id, kind = kind, x = x, z = z, rotation = rotation })
		return placed
	end
	local function walkTo(point)
		closePanels()
		click(screen.CameraControls.Walk)
		local distance = 0
		for _ = 1, 45 do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			assert(
				root and humanoid and humanoid.Health > 0 and not character:FindFirstChildOfClass("Tool"),
				"Extended native commander unavailable"
			)
			local delta = point - root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			if flat.Magnitude <= 7 then
				return distance
			end
			local direction = flat.Unit
			Workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
			task.wait(0.2)
			clickPoint(Workspace.CurrentCamera.ViewportSize * Vector2.new(0.9, 0.4))
			local before = root.Position
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(math.min(2, math.max(0.15, (flat.Magnitude - 2) / humanoid.WalkSpeed)))
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.15)
			local movement = root.Position - before
			local step = Vector3.new(movement.X, 0, movement.Z).Magnitude
			assert(step > 0.5 and os.clock() < deadline, "Extended native walking blocked or timed out")
			distance += step
		end
		error("Extended native commander did not reach target")
	end
	local function actorsForBuilding(id)
		local found = {}
		for _, actor in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
			if actor:GetAttribute("BuildingId") == id and actor:GetAttribute("Alive") then
				table.insert(found, actor)
			end
		end
		return found
	end
	local function extended()
		assert(
			latest.state.coins == 20000 and latest.troopCapacityUsed == 0,
			"Extended fixture requires only declared20000Coin funding and no paid army"
		)
		local manifest = {
			{ kind = "training", x = 6, z = 8, rotation = 90 },
			{ kind = "training", x = 16, z = 8, rotation = 90 },
			{ kind = "ranged", x = 26, z = 8, rotation = 90 },
			{ kind = "healer", x = 16, z = -8, rotation = 0 },
			{ kind = "mount", x = 28, z = -10, rotation = 0 },
			{ kind = "mount", x = 28, z = -24, rotation = 0 },
		}
		local Placement = require(Replicated.MiniatureGame.Placement)
		local proposed = table.clone(latest.state.buildings)
		for index, site in manifest do
			local legal, why = Placement.validate(proposed, site.kind, site.x, site.z, site.rotation)
			assert(legal, "Extended mount footprint preflight failed: " .. tostring(why))
			local candidate = table.clone(site)
			candidate.id = "preflight-" .. index
			table.insert(proposed, candidate)
		end
		evidence.extended, evidence.placements = true, {}
		evidence.before =
			{ coins = latest.state.coins, capacityUsed = 0, capacity = 10, buildings = #latest.state.buildings }
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Extended mounted shop missing")
		click(screen.Build.Content.ShopTabs.Category_Military)
		for _, site in manifest do
			buyItem(site.kind)
		end
		assert(
			latest.state.coins == 9050 and latest.troopCapacityUsed == 0,
			"Extended six-building purchase total differs from10950"
		)
		evidence.purchase = { coins = 9050, spent = 10950, mountPlans = latest.state.plans.mount, capacityUsed = 0 }
		travel("Civilization", "civilization")
		local built = {}
		for index, site in manifest do
			built[index] = placeItem(site.kind, site.x, site.z, site.rotation)
			if index == 4 then
				waitFor(function()
					return latest.troopCapacityUsed == 7
						and latest.troops.melee == 4
						and latest.troops.ranged == 2
						and latest.troops.medic == 1
				end, "Infantry army did not use seven slots")
			elseif index == 5 then
				waitFor(function()
					return latest.troopCapacityUsed == 9 and latest.troops.mounted == 1
				end, "First mounted group did not consume two slots")
			end
		end
		assert(
			latest.troopCapacityUsed == 9 and latest.troops.mounted == 1 and #actorsForBuilding(built[6].id) == 0,
			"One remaining slot accepted a second mounted group"
		)
		evidence.queued = { buildingId = built[6].id, mounted = 1, capacityUsed = 9, freeSlots = 1 }
		local reclaimId = built[1].id
		local walked = walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(built[1].x, 3, built[1].z + 5)))
		if not screen:GetAttribute("HammerSelected") then
			click(screen.Hotbar.Content.Slot2)
		end
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local plot = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		local scene = Workspace.MiniatureSandbox
		local saved = {}
		for _, actor in scene.BattleActors:GetChildren() do
			if
				actor:GetAttribute("BuildingId")
				and actor:GetAttribute("BuildingId") ~= reclaimId
				and actor:GetAttribute("Alive")
			then
				saved[actor.Name] =
					{ model = actor, life = actor:GetAttribute("Life"), health = actor:GetAttribute("Health") }
			end
		end
		local coins, plans = latest.state.coins, latest.state.plans.training
		action("hammer reclaim melee barracks", function()
			local point, visible =
				Workspace.CurrentCamera:WorldToViewportPoint(plot.Buildings[reclaimId].SelectTarget.Position)
			assert(visible, "Reclaimed barracks outside view")
			clickPoint(Vector2.new(point.X, point.Y))
		end)
		assert(
			not findBuilding(reclaimId) and latest.state.plans.training == plans + 1 and latest.state.coins == coins,
			"Hammer did not return one barracks without Coins"
		)
		waitFor(function()
			return latest.troops.mounted == 2
				and latest.troops.melee == 2
				and latest.troops.ranged == 2
				and latest.troops.medic == 1
				and latest.troopCapacityUsed == 9
		end, "Queued mounted group did not backfill released pair")
		waitFor(function()
			return #actorsForBuilding(built[6].id) == 1
		end, "Backfilled mounted source absent")
		local preserved, casualties = 0, 0
		for id, record in saved do
			local current = scene.BattleActors:FindFirstChild(id)
			if record.model.Parent then
				assert(
					current == record.model and current:GetAttribute("Life") == record.life,
					"Reclaim rebuilt an unaffected living actor"
				)
				preserved += 1
			else
				casualties += 1
			end
		end
		assert(preserved > 0, "No unaffected live actor available for preservation evidence")
		waitFor(function()
			return screen.SettlementHUD.Resources.Text:find("Mounted 2", 1, true)
				and screen.SettlementHUD.Resources.Text:find("Army 9/10", 1, true)
		end, "Weighted mounted HUD did not show backfill")
		evidence.backfill = {
			mounted = 2,
			melee = 2,
			ranged = 2,
			medic = 1,
			physicalTroops = 7,
			capacityUsed = 9,
			coins = latest.state.coins,
			trainingPlans = latest.state.plans.training,
			preservedLivingActors = preserved,
			backgroundCasualties = casualties,
			commanderWalkDistance = walked,
			hud = screen.SettlementHUD.Resources.Text,
		}
		if options.capture then
			if screen:GetAttribute("HammerSelected") then
				click(screen.Hotbar.Content.Slot2)
			end
			local targetId
			for id, post in latest.outposts do
				if post.lineId == latest.claim.plotId then
					targetId = id
					break
				end
			end
			assert(targetId, "Own lane outpost absent")
			if latest.outposts[targetId].ownerCivilizationId == "sparta" then
				for id, post in latest.outposts do
					if post.ownerCivilizationId ~= "sparta" then
						targetId = id
						break
					end
				end
			end
			local post = latest.outposts[targetId]
			local began = os.clock()
			evidence.captureWalk = walkTo(post.position + Vector3.new(0, 3, 4))
			action("E command mounted mixed army", function()
				key(Enum.KeyCode.E)
			end)
			assert(
				latest.army.targetId == targetId and latest.army.manual == true,
				"E did not redirect entire mixed army"
			)
			waitFor(function()
				return latest.outposts[targetId].ownerCivilizationId == "sparta"
			end, "Mounted mixed army did not capture commanded outpost", options.captureTimeout or 420)
			local worldPost = scene.Outposts[targetId]
			assert(
				worldPost.Flag:GetAttribute("OwnerCivilizationId") == "sparta"
					and worldPost:GetAttribute("OwnerTeam") == latest.outposts[targetId].ownerTeam,
				"Mounted capture flag differs"
			)
			evidence.capture = {
				outpostId = targetId,
				elapsedSeconds = os.clock() - began,
				flag = worldPost.Flag:GetAttribute("OwnerCivilizationId"),
				nativeE = true,
			}
		end
	end
	local ok, failure = pcall(function()
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Mounted snapshot unavailable")
		if not latest.claim then
			action("choose Sparta", function()
				bodyButton("Select", "SelectSparta")
			end)
		end
		assert(
			latest.claim.civilizationId == "sparta" and latest.state.coins >= 5000,
			"Mounted fixture requires a declared funded Spartan settlement"
		)
		assert((latest.troops.mounted or 0) == 0, "Mounted flow requires no previously allocated mounted troop")
		if options.extended then
			extended()
			return
		end
		local config = MountConfig.get("sparta")
		local beforeCoins, beforePlans, beforeUsed =
			latest.state.coins, latest.state.plans.mount, latest.troopCapacityUsed
		assert(
			beforeUsed <= 8 and Catalog.buildings.mount.price == 5000,
			"Mounted fixture has insufficient pair capacity or wrong price"
		)
		evidence.before =
			{ coins = beforeCoins, plans = beforePlans, capacityUsed = beforeUsed, capacity = latest.troopCapacity }
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Mounted shop did not open")
		click(screen.Build.Content.ShopTabs.Category_Military)
		local list = screen.Build.Content.ShopList
		waitFor(function()
			return list:FindFirstChild("Row_mount") ~= nil
		end, "Mounted military row absent")
		local row = list.Row_mount
		assert(
			row.Title.Text == config.structureName
				and row.Thumbnail.CurrentCamera
				and row.Description.Text:find("2 army slots", 1, true),
			"Mounted shop name thumbnail or capacity summary missing"
		)
		list.CanvasPosition =
			Vector2.new(0, math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8))
		task.wait(0.25)
		local purchase = action("buy mounted building", function()
			click(row.Buy_mount)
		end)
		assert(
			purchase.snapshot.state.coins == beforeCoins - 5000
				and purchase.snapshot.state.plans.mount == beforePlans + 1
				and purchase.snapshot.troopCapacityUsed == beforeUsed,
			"Mounted purchase charged incorrectly or spawned before placement"
		)
		evidence.purchase = {
			coins = purchase.snapshot.state.coins,
			plans = purchase.snapshot.state.plans.mount,
			capacityUsed = purchase.snapshot.troopCapacityUsed,
		}
		travel("Civilization", "civilization")
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Mounted inventory did not open")
		bodyButton("Inventory", "Plan_mount")
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == "mount"
		end, "Mounted inventory item did not start placement")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, visible =
			Workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(26, 0, -8)))
		assert(visible, "Mounted facility placement site outside view")
		for _ = 1, 3 do
			clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
			local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
			local localPoint = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
			if localPoint and math.abs(localPoint.X - 26) < 0.01 and math.abs(localPoint.Z + 8) < 0.01 then
				break
			end
		end
		local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
		local draftPoint = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
		assert(
			draftPoint and math.abs(draftPoint.X - 26) < 0.01 and math.abs(draftPoint.Z + 8) < 0.01,
			"Native ground click did not choose mounted placement site"
		)
		local placement = action("place mounted facility", function()
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local id = placement.result.buildingId
		local building
		for _, entry in placement.snapshot.state.buildings do
			if entry.id == id then
				building = entry
			end
		end
		assert(
			building and building.kind == "mount" and building.x == 26 and building.z == -8,
			"Mounted placement receipt differs"
		)
		assert(
			placement.snapshot.state.coins == beforeCoins - 5000 and placement.snapshot.state.plans.mount == beforePlans,
			"Mounted placement consumed wrong item or charged twice"
		)
		waitFor(function()
			return latest.troops.mounted == 1 and latest.troopCapacityUsed == beforeUsed + 2
		end, "One mounted troop did not use two army slots")
		waitFor(function()
			return screen.SettlementHUD.Resources.Text:find("Mounted 1", 1, true)
				and screen.SettlementHUD.Resources.Text:find("Army " .. (beforeUsed + 2) .. "/10", 1, true)
		end, "Mounted count or weighted HUD slots missing")
		local plot = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		waitFor(function()
			return plot.Buildings:FindFirstChild(id) ~= nil
		end, "Mounted facility not built")
		local model = plot.Buildings[id]
		assert(
			model:GetAttribute("MountStructure") and model:GetAttribute("MountAnimal") == config.animal,
			"Mounted world art identity differs"
		)
		local mountedActor
		waitFor(function()
			for _, actor in Workspace.MiniatureSandbox.BattleActors:GetChildren() do
				if
					actor:GetAttribute("BuildingId") == id
					and actor:GetAttribute("Role") == "mounted"
					and actor:GetAttribute("Alive")
				then
					mountedActor = actor
					return true
				end
			end
			return false
		end, "Mounted troop source did not spawn", 20)
		assert(
			mountedActor:GetAttribute("MountedVisual") == true
				and mountedActor:GetAttribute("MountAnimal") == config.animal,
			"Mounted rider and faction animal not rendered"
		)
		evidence.placement = {
			buildingId = id,
			x = 26,
			z = -8,
			coins = latest.state.coins,
			plans = latest.state.plans.mount,
			mounted = latest.troops.mounted,
			capacityUsed = latest.troopCapacityUsed,
			capacity = latest.troopCapacity,
			animal = config.animal,
			actorId = mountedActor.Name,
			life = mountedActor:GetAttribute("Life"),
			hud = screen.SettlementHUD.Resources.Text,
		}
	end)
	connection:Disconnect()
	pcall(function()
		input:SendKey(false, Enum.KeyCode.B, false)
		input:SendKey(false, Enum.KeyCode.W, false)
		input:SendKey(false, Enum.KeyCode.E, false)
		input:SendKey(false, Enum.KeyCode.R, false)
	end)
	Replicated:SetAttribute(
		"MiniatureMountedFlowResult",
		game:GetService("HttpService"):JSONEncode({
			ok = ok,
			result = if ok then evidence else tostring(failure),
			evidence = if not ok then evidence else nil,
		})
	)
	assert(ok, failure)
	return evidence
end
return run

--!strict
-- Native Client acceptance on the existing paid settlement. No funding, state,
-- draft, position or receipt injection; only ordinary buttons/keys/ground clicks.
type Options = { timeout: number? }
local function run(options: Options?)
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Workspace = game:GetService("Workspace")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong structure native boundary"
	)
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(screen and actions, "Structure fixture UI unavailable")
	local Catalog = require(Replicated.MiniatureGame.Catalog)
	local Config = require(Replicated.MiniatureGame.Config)
	local Placement = require(Replicated.MiniatureGame.Placement)
	local input = Input:CreateVirtualInput()
	local deadline = os.clock() + (if options then options.timeout or 240 else 240)
	local latest, receipts = nil, {}
	local evidence = {
		nativeVirtualInput = true,
		authoritativeMutation = false,
		fundingInjected = false,
		localRelocation = false,
		attempts = {},
		purchases = {},
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
		assert(button and button.Visible and button.Active, "Structure native button unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code)
		input:SendKey(true, code, false)
		task.wait(0.1)
		input:SendKey(false, code, false)
		task.wait(0.2)
	end
	local function action(label: string, press)
		Replicated:SetAttribute("MiniatureStructureFlowProgress", label)
		for attempt = 1, 3 do
			local before = #receipts
			press()
			waitFor(function()
				return #receipts > before
			end, "Missing structure action receipt: " .. label)
			local packet = receipts[before + 1]
			table.insert(evidence.attempts, {
				label = label,
				attempt = attempt,
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
				"Structure action refused: " .. tostring(packet.result.reason)
			)
			waitFor(function()
				return screen:GetAttribute("Revision") >= packet.snapshot.revision
			end, "Fresh structure snapshot not rendered")
		end
		error("Structure action retry exhausted")
	end
	local function closePanels()
		for _, name in { "Build", "Trade", "Select", "Inventory" } do
			local panel = screen:FindFirstChild(name)
			if panel and panel.Visible then
				click(panel.Close)
			end
		end
	end
	local function travel(buttonName, destination)
		local packet = action("travel " .. destination, function()
			click(screen.TopNavigation[buttonName])
		end)
		assert(packet.result.destination == destination, "Structure travel destination differs")
	end
	local function heldPlans(state)
		local amount = 0
		for _, value in state.plans do
			amount += value
		end
		return amount
	end
	local function buy(kind)
		local definition = Catalog.buildings[kind]
		click(screen.Build.Content.ShopTabs["Category_" .. definition.category])
		waitFor(function()
			return screen.Build.Content.ShopList:FindFirstChild("Row_" .. kind) ~= nil
		end, "Structure shop row missing: " .. kind)
		local list = screen.Build.Content.ShopList
		local row = list["Row_" .. kind]
		list.CanvasPosition =
			Vector2.new(0, math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8))
		task.wait(0.2)
		local before = {
			coins = latest.state.coins,
			plans = latest.state.plans[kind],
			stock = latest.state.merchant.stock[kind],
			used = latest.troopCapacityUsed,
		}
		local packet = action("buy " .. kind, function()
			click(row["Buy_" .. kind])
		end)
		local state = packet.snapshot.state
		assert(
			state.coins == before.coins - definition.price and state.plans[kind] == before.plans + 1,
			"Structure purchase ledger differs"
		)
		assert(
			state.merchant.stock[kind] == before.stock - 1 and packet.snapshot.troopCapacityUsed == before.used,
			"Purchase changed stock incorrectly or spawned troops early"
		)
		table.insert(
			evidence.purchases,
			{ kind = kind, coins = state.coins, plans = state.plans[kind], aggregatePlans = heldPlans(state) }
		)
	end
	local function chooseSites()
		-- Place ten purchased plans, reserving three held items afterward. Largest
		-- footprints first avoid fragmenting legal ground before smaller homes.
		local kinds =
			{ "training", "training", "ranged", "farm", "farm", "timber", "material", "workshop", "house", "house" }
		local proposed = table.clone(latest.state.buildings)
		local sites = {}
		for _, kind in kinds do
			local chosen
			for z = -Config.plotDepth / 2 + Config.grid, Config.plotDepth / 2 - Config.grid, Config.grid do
				for x = -Config.plotWidth / 2 + Config.grid, Config.plotWidth / 2 - Config.grid, Config.grid do
					for _, rotation in { 0, 90 } do
						if Placement.validate(proposed, kind, x, z, rotation) then
							chosen = { kind = kind, x = x, z = z, rotation = rotation }
							break
						end
					end
					if chosen then
						break
					end
				end
				if chosen then
					break
				end
			end
			assert(chosen, "No legal structure fixture site: " .. kind)
			table.insert(sites, chosen)
			table.insert(proposed, {
				id = "native-proposed-" .. #sites,
				kind = kind,
				x = chosen.x,
				z = chosen.z,
				rotation = chosen.rotation,
			})
		end
		return sites
	end
	local function place(site)
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Structure inventory missing")
		local body = screen.Inventory.Content
		local button = body:FindFirstChild("Plan_" .. site.kind)
		assert(button, "Structure inventory plan missing")
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		click(button)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == site.kind
		end, "Structure plan not equipped")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, shown = Workspace.CurrentCamera:WorldToViewportPoint(
			latest.plotFrame:PointToWorldSpace(Vector3.new(site.x, 0, site.z))
		)
		assert(shown, "Structure placement outside overview")
		local matched = false
		for _ = 1, 3 do
			clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
			local ghost = Workspace:FindFirstChild("LocalPlacementFootprint")
			local draft = ghost and latest.plotFrame:PointToObjectSpace(ghost.Position)
			if draft and math.abs(draft.X - site.x) < 0.01 and math.abs(draft.Z - site.z) < 0.01 then
				matched = true
				break
			end
		end
		assert(matched, "Structure native ground click did not reach intended site")
		for _ = 1, site.rotation / 90 do
			key(Enum.KeyCode.R)
		end
		local beforeCoins, beforePlans, beforeCount =
			latest.state.coins, latest.state.plans[site.kind], #latest.state.buildings
		local packet = action("place " .. site.kind, function()
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local building
		for _, item in packet.snapshot.state.buildings do
			if item.id == packet.result.buildingId then
				building = item
				break
			end
		end
		assert(
			building
				and building.kind == site.kind
				and building.x == site.x
				and building.z == site.z
				and building.rotation == site.rotation,
			"Structure placement receipt differs from native ghost"
		)
		assert(
			packet.snapshot.state.coins == beforeCoins
				and packet.snapshot.state.plans[site.kind] == beforePlans - 1
				and #packet.snapshot.state.buildings == beforeCount + 1,
			"Structure placement charged Coins or consumed wrong plan"
		)
		assert(
			packet.snapshot.troopCapacity == 10 and packet.snapshot.troopCapacityUsed <= 10,
			"Uncapped structures grew army capacity"
		)
		table.insert(evidence.placements, {
			id = building.id,
			kind = building.kind,
			x = building.x,
			z = building.z,
			rotation = building.rotation,
			count = #packet.snapshot.state.buildings,
			capacityUsed = packet.snapshot.troopCapacityUsed,
		})
	end
	local ok, failure = pcall(function()
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable and latest.claim
		end, "Structure fixture requires an existing writable selected civilization")
		assert(
			latest.claim.civilizationId == "sparta" and latest.troops.mounted == 1,
			"Run the ordinary paid mounted flow before this fixture"
		)
		assert(
			heldPlans(latest.state) == 0 and #latest.state.buildings >= 4,
			"Structure fixture expects no outstanding building items"
		)
		local initialCoins, initialCount, initialUsed =
			latest.state.coins, #latest.state.buildings, latest.troopCapacityUsed
		evidence.before = { coins = initialCoins, buildings = initialCount, plans = 0, capacityUsed = initialUsed }
		-- The timber merchant offers one; medics offer two. Together this is
		-- thirteen ordinary in-stock plans without waiting for another cycle.
		local purchases = {
			{ "house", 2 },
			{ "farm", 2 },
			{ "timber", 1 },
			{ "material", 1 },
			{ "workshop", 1 },
			{ "training", 2 },
			{ "ranged", 2 },
			{ "healer", 2 },
		}
		local price = 0
		for _, entry in purchases do
			assert(
				latest.state.merchant.stock[entry[1]] >= entry[2],
				"Required private stock already spent: " .. entry[1]
			)
			price += Catalog.buildings[entry[1]].price * entry[2]
		end
		assert(initialCoins >= price, "Existing wallet cannot fund declared structure purchases")
		local sites = chooseSites()
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Shared buy shop did not open")
		for _, entry in purchases do
			for _ = 1, entry[2] do
				buy(entry[1])
			end
		end
		assert(
			heldPlans(latest.state) == 13
				and latest.state.coins == initialCoins - price
				and #latest.state.buildings == initialCount,
			"Thirteenth held plan or total purchase ledger differs"
		)
		evidence.heldPlans = { count = heldPlans(latest.state), coins = latest.state.coins, totalPrice = price }
		travel("Civilization", "civilization")
		for _, site in sites do
			place(site)
		end
		local plot = Workspace.MiniatureSandbox.Plots["Plot" .. latest.claim.plotId]
		waitFor(function()
			return #plot.Buildings:GetChildren() == #latest.state.buildings
		end, "Replicated structure count differs from authoritative state")
		assert(
			#latest.state.buildings == initialCount + 10
				and #latest.state.buildings > 12
				and heldPlans(latest.state) == 3,
			"Native structure count or remaining held inventory differs"
		)
		assert(
			latest.state.coins == initialCoins - price and latest.troopCapacity == 10 and latest.troopCapacityUsed <= 10,
			"Native structure placement changed wallet or army ceiling"
		)
		evidence.after = {
			coins = latest.state.coins,
			buildings = #latest.state.buildings,
			physicalBuildings = #plot.Buildings:GetChildren(),
			heldPlans = heldPlans(latest.state),
			troopCapacity = latest.troopCapacity,
			capacityUsed = latest.troopCapacityUsed,
			mounted = latest.troops.mounted,
		}
	end)
	connection:Disconnect()
	pcall(function()
		input:SendKey(false, Enum.KeyCode.B, false)
		input:SendKey(false, Enum.KeyCode.R, false)
	end)
	Replicated:SetAttribute(
		"MiniatureStructureFlowResult",
		Http:JSONEncode({
			ok = ok,
			result = if ok then evidence else tostring(failure),
			evidence = if not ok then evidence else nil,
		})
	)
	assert(ok, failure)
	return evidence
end
return run

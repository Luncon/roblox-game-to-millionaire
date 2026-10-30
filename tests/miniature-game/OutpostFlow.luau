--!strict
-- Solo native combat acceptance. Every mutation uses actual shop/placement/E input.
-- Funded mode requires the declared fake bootstrap with only 5000 Coins changed.
-- No local combat/profile state injection, actor relocation or controller loading.
type Options = {
	funded: boolean?,
	waitForScene: boolean?,
	captureTimeout: number?,
	timeout: number?,
	largerArmy: boolean?,
}
local function run(options: Options?)
	options = options or {}
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Input = game:GetService("UserInputService")
	local Run = game:GetService("RunService")
	local Http = game:GetService("HttpService")
	local Workspace = game:GetService("Workspace")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Outpost client UI missing")
	local actions = Replicated:WaitForChild("MiniatureActions", 15)
	assert(actions, "Outpost action boundary missing")
	local Shared = Replicated:WaitForChild("MiniatureGame", 15)
	assert(Shared, "Outpost shared modules missing")
	local Catalog = require(Shared.Catalog)
	local input = Input:CreateVirtualInput()
	local deadline = os.clock() + (options.timeout or 600)
	local largerArmy = options.largerArmy ~= false
	local latest, observer
	local receipts, positions = {}, {}
	local neutralLives = {}
	local pauseCandidate
	local ownTeam, ownId, ownSite, scene
	local observed = {
		walking = false,
		damagedHealth = false,
		healthBar = false,
		meleeAttack = false,
		rangedShot = false,
		projectile = false,
		defendedZero = false,
		barProgress = false,
		pausedForDefenders = false,
		resumedAfterPause = false,
		neutralRespawn = false,
	}
	local evidence = {
		fundedFakeBootstrap = options.funded == true,
		nativeVirtualInput = true,
		localStateInjection = false,
		localRelocation = false,
		contestedNative = false,
		homeInvasionNative = false,
		attempts = {},
		placements = {},
		neutralRespawns = {},
	}
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
		if packet.requestId and packet.result then
			table.insert(receipts, packet)
		end
	end)
	local function step(label: string)
		evidence.lastStep = label
		Replicated:SetAttribute("MiniatureOutpostFlowProgress", label)
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
		task.wait(0.05)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local function click(button)
		waitFor(function()
			return button and button.Visible and button.Active
		end, "Outpost UI control unavailable")
		clickPoint(button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset())
	end
	local function key(code: Enum.KeyCode)
		input:SendKey(true, code, false)
		task.wait(0.1)
		input:SendKey(false, code, false)
		task.wait(0.2)
	end
	local function action(label: string, press)
		for attempt = 1, 3 do
			local before = #receipts
			press()
			waitFor(function()
				return #receipts > before
			end, "No receipt: " .. label)
			local packet = receipts[before + 1]
			table.insert(evidence.attempts, {
				action = label,
				attempt = attempt,
				ok = packet.result.ok,
				reason = packet.result.reason,
				requestId = packet.requestId,
			})
			if packet.result.ok then
				return packet
			end
			assert(packet.result.reason == "stale_revision" and attempt < 3, "Outpost action refused")
			waitFor(function()
				return (screen:GetAttribute("Revision") or -1) >= packet.snapshot.revision
			end, "Refusal snapshot was not rendered")
			task.wait(0.2)
		end
		error("Outpost UI retries exhausted")
	end
	local function pressBody(page: string, name: string)
		local body = screen[page].Content
		waitFor(function()
			return body:FindFirstChild(name) and body[name].Active
		end, "Outpost body control missing")
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
	local function rootPart(): BasePart
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		assert(
			character and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart"),
			"Living commander missing"
		)
		assert(
			math.abs(character:GetScale() - 1) < 0.001
				and not character:FindFirstChildOfClass("Tool")
				and not player.Backpack:FindFirstChildOfClass("Tool"),
			"Commander armed or miniaturized"
		)
		return root
	end
	local function travel(name: string, destination: string)
		local packet = action("travel " .. destination, function()
			click(screen.TopNavigation[name])
		end)
		assert(packet.result.destination == destination, "Wrong outpost setup travel destination")
		local target = if destination == "buy"
			then latest.buyShopPosition
			elseif destination == "sell" then latest.sellShopPosition
			else latest.plotFrame:PointToWorldSpace(Vector3.new(0, 3, 23))
		waitFor(function()
			return (rootPart().Position - target).Magnitude < 12
		end, "Server travel arrival missing")
	end
	local function walkTo(target: Vector3)
		closePanels()
		click(screen.CameraControls.Walk)
		local total = 0
		for _ = 1, 24 do
			local root = rootPart()
			local offset = target - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude <= 5 then
				return total
			end
			local direction = flat.Unit
			local camera = Workspace.CurrentCamera
			camera.CFrame =
				CFrame.lookAt(root.Position - direction * 14 + Vector3.new(0, 6, 0), root.Position + direction * 10)
			task.wait(0.2)
			clickPoint(camera.ViewportSize * Vector2.new(0.9, 0.4))
			local began = root.Position
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			assert(humanoid and humanoid.WalkSpeed > 0, "Walking speed unavailable")
			input:SendKey(true, Enum.KeyCode.W, false)
			task.wait(math.min(2, math.max(0.15, (flat.Magnitude - 2) / humanoid.WalkSpeed)))
			input:SendKey(false, Enum.KeyCode.W, false)
			task.wait(0.15)
			local moved = rootPart().Position - began
			local distance = Vector3.new(moved.X, 0, moved.Z).Magnitude
			assert(distance > 0.5, "Native commander walking was blocked")
			total += distance
			assert(os.clock() < deadline, "Outpost walk exceeded fixture deadline")
		end
		error("Native commander did not reach outpost")
	end
	local function building(view, id)
		for _, item in view.state.buildings do
			if item.id == id then
				return item
			end
		end
		return nil
	end
	local function earn()
		travel("Civilization", "civilization")
		local farm = building(latest, "b3")
		assert(farm and farm.kind == "farm", "Fresh starter farm missing")
		walkTo(latest.plotFrame:PointToWorldSpace(Vector3.new(farm.x, 3, farm.z + 6)))
		waitFor(function()
			return building(latest, farm.id).output >= 50
		end, "Starter food did not produce", 20)
		action("collect food", function()
			key(Enum.KeyCode.E)
		end)
		travel("Sell", "sell")
		waitFor(function()
			return screen.Trade.Visible
		end, "Sell popup missing")
		action("sell food", function()
			pressBody("Trade", "SellAll")
		end)
	end
	local function buy(kind: string)
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("buy " .. kind, function()
			local list = screen.Build.Content.ShopList
			local row = list["Row_" .. kind]
			assert(row, "Military shop row missing")
			list.CanvasPosition = Vector2.new(
				0,
				math.max(0, row.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 8)
			)
			task.wait(0.2)
			click(row["Buy_" .. kind])
		end)
		assert(
			packet.snapshot.state.coins == coins - Catalog.buildings[kind].price
				and packet.snapshot.state.plans[kind] == plans + 1,
			"Military purchase ledger differs"
		)
	end
	local function place(kind: string, x: number, z: number, rotation: number)
		closePanels()
		key(Enum.KeyCode.B)
		waitFor(function()
			return screen.Inventory.Visible
		end, "Outpost placement inventory missing")
		pressBody("Inventory", "Plan_" .. kind)
		waitFor(function()
			return screen:GetAttribute("PlacingKind") == kind
		end, "Outpost military item not selected")
		click(screen.CameraControls.Overview)
		task.wait(0.3)
		local point, shown =
			Workspace.CurrentCamera:WorldToViewportPoint(latest.plotFrame:PointToWorldSpace(Vector3.new(x, 0, z)))
		assert(shown, "Military placement ground not visible")
		clickPoint(Vector2.new(point.X, point.Y) + Gui:GetGuiInset())
		for _ = 1, rotation / 90 do
			key(Enum.KeyCode.R)
		end
		local coins, plans = latest.state.coins, latest.state.plans[kind]
		local packet = action("place " .. kind, function()
			click(screen.PlacementControls.PlacementActions.ConfirmPlacement)
		end)
		local placed = building(packet.snapshot, packet.result.buildingId)
		assert(
			placed and placed.kind == kind and placed.x == x and placed.z == z and placed.rotation == rotation,
			"Military building placement differs"
		)
		assert(
			packet.snapshot.state.coins == coins and packet.snapshot.state.plans[kind] == plans - 1,
			"Military placement charged twice"
		)
		table.insert(evidence.placements, { id = placed.id, kind = kind, x = x, z = z, rotation = rotation })
	end
	local function owned(actor): boolean
		return actor:IsA("Model")
			and actor:GetAttribute("CombatActor") == true
			and actor:GetAttribute("NeutralDefense") ~= true
			and actor:GetAttribute("CivilizationId") == "sparta"
	end
	local firstCaptureAt, startedProgressAt
	local function sample()
		if not scene or not ownSite then
			return
		end
		local now = os.clock()
		local currentProgress = ownSite:GetAttribute("CaptureProgress") or 0
		for _, actor in scene.BattleActors:GetChildren() do
			if actor:IsA("Model") and actor:GetAttribute("CombatActor") then
				if actor:GetAttribute("Team") == "neutral:" .. ownId then
					local life = actor:GetAttribute("Life")
					local previous = neutralLives[actor.Name]
					if type(life) == "number" then
						if previous and life > previous and currentProgress > 0 and currentProgress < 20 then
							observed.neutralRespawn = true
							if #evidence.neutralRespawns < 32 then
								table.insert(evidence.neutralRespawns, {
									actorId = actor.Name,
									beforeLife = previous,
									afterLife = life,
									at = now,
									progress = currentProgress,
								})
							end
						end
						neutralLives[actor.Name] = life
					end
				end
				local health, maximum = actor:GetAttribute("Health"), actor:GetAttribute("MaxHealth")
				if type(health) == "number" and type(maximum) == "number" and health > 0 and health < maximum then
					observed.damagedHealth = true
					local head = actor:FindFirstChild("Head")
					local display = head and head:FindFirstChild("HealthDisplay")
					local bar = display and display:FindFirstChild("HealthBar")
					local fill = bar and bar:FindFirstChild("Fill")
					if fill and fill:IsA("Frame") and math.abs(fill.Size.X.Scale - health / maximum) < 0.08 then
						observed.healthBar = true
					end
				end
				if owned(actor) then
					ownTeam = ownTeam or actor:GetAttribute("Team")
					local id = actor.Name .. ":" .. tostring(actor:GetAttribute("Life"))
					local point = actor:GetPivot().Position
					positions[id] = positions[id] or point
					local delta = point - positions[id]
					if Vector3.new(delta.X, 0, delta.Z).Magnitude > 5 then
						observed.walking = true
					end
					if actor:GetAttribute("Role") == "melee" and (actor:GetAttribute("AttackCount") or 0) > 0 then
						observed.meleeAttack = true
					end
					if actor:GetAttribute("Role") == "ranged" and (actor:GetAttribute("ShotCount") or 0) > 0 then
						observed.rangedShot = true
					end
				end
			end
		end
		for _, effect in scene.BattleEffects:GetChildren() do
			if
				effect:GetAttribute("VisualOnly") == true
				and effect:GetAttribute("VisualProjectile") == true
				and effect:GetAttribute("ProjectileKind") ~= "bandage"
			then
				observed.projectile = true
			end
		end
		local progress, defenders = ownSite:GetAttribute("CaptureProgress"), ownSite:GetAttribute("NeutralDefenders")
		if type(progress) == "number" then
			if type(defenders) == "number" and defenders > 0 and progress == 0 then
				observed.defendedZero = true
			end
			if progress > 0 and progress < 20 then
				if
					ownSite:GetAttribute("CaptureStatus") == "defended"
					and type(defenders) == "number"
					and defenders > 0
				then
					if not pauseCandidate or math.abs(pauseCandidate.progress - progress) > 0.0001 then
						pauseCandidate = { at = now, progress = progress }
					elseif now - pauseCandidate.at >= 0.15 then
						observed.pausedForDefenders = true
						evidence.capturePause = evidence.capturePause
							or {
								progress = progress,
								secondsUnchanged = now - pauseCandidate.at,
								defenders = defenders,
							}
					end
				else
					pauseCandidate = nil
					if
						observed.pausedForDefenders
						and ownSite:GetAttribute("CaptureStatus") == "capturing"
						and progress > evidence.capturePause.progress + 0.05
					then
						observed.resumedAfterPause = true
						evidence.captureResume = evidence.captureResume or { at = now, progress = progress }
					end
				end
				startedProgressAt = startedProgressAt or os.clock()
				local fill = ownSite.Target.CaptureDisplay.CaptureBar.Fill
				if math.abs(fill.Size.X.Scale - progress / 20) < 0.08 then
					observed.barProgress = true
				end
			end
		end
		if ownSite:GetAttribute("OwnerCivilizationId") == "sparta" then
			firstCaptureAt = firstCaptureAt or os.clock()
		end
	end
	local ok, result = pcall(function()
		assert(
			game:GetService("RunService"):IsStudio()
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Wrong outpost fixture boundary"
		)
		assert(#Players:GetPlayers() == 1, "Outpost fixture requires a solo owned Play")
		actions.Snapshot:FireServer()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Outpost writable snapshot missing")
		if not latest.claim then
			action("select Sparta", function()
				pressBody("Select", "SelectSparta")
			end)
		end
		assert(
			latest.claim.civilizationId == "sparta" and #latest.state.buildings == 3,
			"Fresh Spartan outpost state required"
		)
		assert(latest.state.coins == (if options.funded then 5000 else 200), "Outpost starting coins differ")
		if options.funded then
			assert(
				Replicated:GetAttribute("MiniatureSimpleShopFixture") == true
					or Replicated:GetAttribute("MiniatureCombatFixture") == true,
				"Funded outpost run must declare its fake bootstrap"
			)
		end
		for _, amount in latest.state.goods do
			assert(amount == 0, "Outpost fixture must not inject goods")
		end
		assert(
			not latest.state.hallUpgraded and next(latest.state.research.completed) == nil,
			"Outpost fixture must not inject research"
		)
		if options.waitForScene ~= false then
			step("await initial no-army scene verification")
			waitFor(function()
				return Replicated:GetAttribute("MiniatureGameSceneResult") ~= nil
			end, "Initial scene did not finish", 30)
			assert(Http:JSONDecode(Replicated:GetAttribute("MiniatureGameSceneResult")).ok, "Initial scene failed")
		end
		waitFor(function()
			return Replicated:GetAttribute("MiniatureCombatReady") and latest.outposts and latest.army
		end, "Combat runtime snapshot missing")
		scene = Workspace.MiniatureSandbox
		assert(#scene.Outposts:GetChildren() == 8, "Eight initial outposts missing")
		ownId = "outpost_" .. latest.claim.plotId
		ownSite = scene.Outposts[ownId]
		assert(
			ownSite
				and ownSite:GetAttribute("NeutralDefenders") == 3
				and not ownSite:GetAttribute("OwnerCivilizationId"),
			"Initial neutral defense differs"
		)
		local counts = { melee = 0, ranged = 0 }
		for _, actor in scene.BattleActors:GetChildren() do
			if actor:GetAttribute("Team") == "neutral:" .. ownId then
				local role = actor:GetAttribute("Role")
				assert(counts[role] ~= nil, "Unexpected neutral role")
				counts[role] += 1
				neutralLives[actor.Name] = actor:GetAttribute("Life")
			end
		end
		assert(counts.melee == 2 and counts.ranged == 1, "Neutral garrison is not two melee and one ranged")
		evidence.initial =
			{ coins = latest.state.coins, outposts = 8, neutralMelee = counts.melee, neutralRanged = counts.ranged }
		evidence.effectsBefore = {
			shots = scene.BattleEffects:GetAttribute("Shots") or 0,
			hits = scene.BattleEffects:GetAttribute("Hits") or 0,
			deaths = scene.BattleEffects:GetAttribute("Deaths") or 0,
			captures = scene.BattleEffects:GetAttribute("Captures") or 0,
		}
		local observerError
		local elapsed = 0
		observer = Run.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.1 then
				return
			end
			elapsed = 0
			local sampled, why = pcall(sample)
			if not sampled then
				observerError = tostring(why)
			end
		end)
		step("buy real melee, ranged and healer building items")
		while latest.state.coins < (if largerArmy then 1200 else 700) do
			earn()
		end
		travel("Buy", "buy")
		waitFor(function()
			return screen.Build.Visible
		end, "Military shop missing")
		click(screen.Build.Content.ShopTabs.Category_Military)
		buy("training")
		buy("ranged")
		buy("healer")
		if largerArmy then
			buy("training")
			buy("ranged")
		end
		travel("Civilization", "civilization")
		place("training", 6, 8, 90)
		place("ranged", 16, 8, 90)
		place("healer", 16, -8, 0)
		if largerArmy then
			place("training", 6, 20, 90)
			place("ranged", 26, 8, 90)
		end
		waitFor(function()
			local fighters = if largerArmy then 4 else 2
			return latest.troops
				and latest.troops.melee == fighters
				and latest.troops.ranged == fighters
				and latest.troops.medic == 1
		end, "Purchased army groups did not allocate their slots")
		evidence.army = {
			melee = latest.troops.melee,
			ranged = latest.troops.ranged,
			medic = latest.troops.medic,
			purchaseCoins = if largerArmy then 1200 else 700,
		}
		assert(
			latest.army.targetId == ownId and latest.army.manual == false,
			"New army did not choose its own lane automatically"
		)
		evidence.autoTarget = ownId
		step("walk commander normally to observe automatic battle")
		evidence.walkToOwnOutpost = walkTo(latest.outposts[ownId].position + Vector3.new(0, 3, 5))
		step("wait real neutral combat and twenty-second capture")
		waitFor(function()
			assert(observerError == nil, "Combat observation failed")
			return latest.outposts[ownId].ownerCivilizationId == "sparta"
				and ownSite:GetAttribute("OwnerCivilizationId") == "sparta"
		end, "Automatic army did not defeat defenders and capture its own outpost", options.captureTimeout or 420)
		sample()
		assert(
			observed.walking and observed.meleeAttack and observed.rangedShot,
			"Native army walk/melee/ranged attacks were not observed"
		)
		assert(observed.damagedHealth and observed.healthBar, "Combat health changes or health bars were not observed")
		assert(observed.defendedZero and observed.barProgress, "Defended/capturing progress states were not rendered")
		assert(observed.neutralRespawn, "No neutral NPC respawn was observed during partial capture")
		assert(
			observed.pausedForDefenders and observed.resumedAfterPause,
			"Partial capture did not pause for at least 0.15s with defenders and resume afterward"
		)
		assert(
			startedProgressAt and firstCaptureAt and firstCaptureAt - startedProgressAt >= 19,
			"Capture completed before its real twenty-second duration"
		)
		assert(
			ownSite:GetAttribute("NeutralDefenders") == 0
				and ownSite.Flag:GetAttribute("OwnerCivilizationId") == "sparta",
			"Captured outpost retained neutrals or wrong flag"
		)
		assert(
			ownTeam and ownSite:GetAttribute("OwnerTeam") == ownTeam,
			"Outpost owner does not match the actual army team"
		)
		evidence.capture = {
			outpostId = ownId,
			civilizationId = "sparta",
			observedSeconds = firstCaptureAt - startedProgressAt,
			progress = ownSite:GetAttribute("CaptureProgress"),
			label = ownSite.Target.CaptureDisplay.CaptureLabel.Text,
		}
		evidence.combat = observed
		evidence.effectsAfter = {
			shots = scene.BattleEffects:GetAttribute("Shots") or 0,
			hits = scene.BattleEffects:GetAttribute("Hits") or 0,
			deaths = scene.BattleEffects:GetAttribute("Deaths") or 0,
			captures = scene.BattleEffects:GetAttribute("Captures") or 0,
		}
		assert(
			evidence.effectsAfter.hits > evidence.effectsBefore.hits
				and evidence.effectsAfter.deaths >= evidence.effectsBefore.deaths + 3
				and evidence.effectsAfter.captures > evidence.effectsBefore.captures,
			"Authoritative combat/capture events missing"
		)
		local foreignId = "outpost_" .. (latest.claim.plotId % 8 + 1)
		local foreign = latest.outposts[foreignId]
		assert(foreign and foreignId ~= ownId, "Another outpost is unavailable")
		step("walk to another outpost center and order the whole army with E")
		evidence.walkToOtherOutpost = walkTo(foreign.position + Vector3.new(0, 3, 5))
		local prompt = scene.Outposts[foreignId].Target.TargetOutpost
		assert(
			prompt.Enabled
				and prompt:GetAttribute("ArmyTarget") == true
				and prompt:GetAttribute("OutpostId") == foreignId,
			"Native army-target prompt is unavailable"
		)
		local ordered = action("E target other outpost", function()
			key(Enum.KeyCode.E)
		end)
		assert(
			ordered.snapshot.army.targetId == foreignId and ordered.snapshot.army.manual == true,
			"E did not override default army targeting"
		)
		waitFor(function()
			local count = 0
			for _, actor in scene.BattleActors:GetChildren() do
				if owned(actor) then
					count += 1
					if actor:GetAttribute("TargetOutpostId") ~= foreignId then
						return false
					end
				end
			end
			return count > 0
		end, "Whole living army did not receive the outpost override")
		evidence.manualTarget = { outpostId = foreignId, manual = true, requestId = ordered.requestId }
		evidence.final = {
			coins = latest.state.coins,
			troopCapacity = latest.troopCapacity,
			allocated = latest.troops,
			alive = latest.army.alive,
			targetId = latest.army.targetId,
		}
		evidence.ok = true
		return evidence
	end)
	if observer then
		observer:Disconnect()
	end
	connection:Disconnect()
	pcall(function()
		input:SendKey(false, Enum.KeyCode.W, false)
	end)
	pcall(function()
		input:SendKey(false, Enum.KeyCode.E, false)
	end)
	pcall(function()
		input:SendKey(false, Enum.KeyCode.R, false)
	end)
	pcall(function()
		input:SendKey(false, Enum.KeyCode.B, false)
	end)
	Replicated:SetAttribute(
		"MiniatureOutpostFlowResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, tostring(result))
	return result
end
return run

--!strict
-- Native Client fixture for a fresh AdvancedBootstrap fake-store place.
-- Actual chooser/council/research buttons, original 30s clock, no mutation remotes.
-- A local commander relocation is explicit distance setup, not walking evidence.
return function()
	local Replicated = game:GetService("ReplicatedStorage")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	local player = game:GetService("Players").LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	assert(screen, "Research switch UI missing")
	local input = game:GetService("UserInputService"):CreateVirtualInput()
	local latest, receivedAt, snapshotCount = nil, 0, 0
	local receipts, completionTransitions, previousCompleted = {}, 0, false
	local evidence = {
		fundedFakeSetup = true,
		realClocks = true,
		nativeVirtualInput = true,
		relocationWasFixtureSetup = true,
		receipts = {},
	}
	local connection = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		local now = os.clock()
		if packet.snapshot then
			latest, receivedAt, snapshotCount = packet.snapshot, now, snapshotCount + 1
			if latest.claim and latest.claim.civilizationId == "sparta" and latest.state then
				local completed = latest.state.research.completed.work == true
				if completed and not previousCompleted then
					completionTransitions += 1
				end
				previousCompleted = completed
			end
		end
		if packet.result then
			table.insert(receipts, { packet = packet, receivedAt = now })
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
	local function capture(view, at)
		local project = view.state and view.state.research.project
		return {
			at = at,
			civilizationId = view.claim and view.claim.civilizationId,
			plotId = view.claim and view.claim.plotId,
			coins = view.state and view.state.coins,
			timber = view.state and view.state.goods.timber,
			hallUpgraded = view.state and view.state.hallUpgraded,
			workCompleted = view.state and view.state.research.completed.work == true,
			project = if project then { id = project.id, remaining = project.remaining } else nil,
			revision = view.revision,
			claimEpoch = view.claimEpoch,
		}
	end
	local function progress(label)
		evidence.lastStep = label
		Replicated:SetAttribute("ResearchSwitchProgressJSON", Http:JSONEncode({ step = label, at = os.clock() }))
	end
	local function refresh()
		local before = snapshotCount
		Replicated.MiniatureActions.Snapshot:FireServer()
		waitFor(function()
			return snapshotCount > before
		end, "Research switch snapshot did not arrive")
		return capture(latest, receivedAt)
	end
	local function click(button)
		assert(button and button.Visible and button.Active, "Research switch button unavailable")
		local point = button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset()
		input:SendMousePosition(point)
		task.wait(0.05)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.06)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local function press(page, key, beforeClick)
		local body = screen[page].Content
		waitFor(function()
			return body:FindFirstChild(key) and body[key].Visible and body[key].Active
		end, "Unavailable " .. page .. "." .. key)
		local button = body[key]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.2)
		if beforeClick then
			beforeClick()
		end
		click(body[key])
	end
	local function navigate(page)
		if not screen.SettlementHUD.Visible and screen.RestoreSettlement.Visible then
			click(screen.RestoreSettlement)
		end
		click(screen.SettlementHUD.Navigation[page .. "Navigation"])
		waitFor(function()
			return screen[page].Visible
		end, "Research switch navigation failed: " .. page)
	end
	local function action(page, key, label)
		for attempt = 1, 3 do
			progress(label .. " attempt " .. attempt)
			local before, dispatchedAt = #receipts, 0
			press(page, key, function()
				dispatchedAt = os.clock()
			end)
			waitFor(function()
				return #receipts > before
			end, "No receipt: " .. label)
			local receipt = receipts[#receipts]
			local packet = receipt.packet
			table.insert(evidence.receipts, {
				action = label,
				attempt = attempt,
				dispatchedAt = dispatchedAt,
				receivedAt = receipt.receivedAt,
				requestId = packet.requestId,
				result = packet.result,
				snapshot = capture(packet.snapshot, receipt.receivedAt),
			})
			if packet.result.ok then
				return packet, dispatchedAt, receipt.receivedAt
			end
			assert(
				packet.result.reason == "stale_revision" and attempt < 3,
				label .. " refused: " .. tostring(packet.result.reason)
			)
			task.wait(0.3)
		end
		error("Research switch attempts exhausted: " .. label)
	end
	local function choose(id)
		if not screen.Select.Visible then
			if latest.state then
				navigate("Settlement")
				press("Settlement", "ChooseCivilization")
			else
				if not screen.SettlementHUD.Visible and screen.RestoreSettlement.Visible then
					click(screen.RestoreSettlement)
				end
				click(screen.SettlementHUD.Navigation.SettlementNavigation)
			end
		end
		waitFor(function()
			return screen.Select.Visible
		end, "Research switch chooser missing")
		local packet, dispatchedAt, acceptedAt =
			action("Select", "Select" .. (if id == "sparta" then "Sparta" else id), "select " .. id)
		assert(packet.snapshot.claim.civilizationId == id and packet.snapshot.artReady, "Wrong civilization receipt")
		return capture(packet.snapshot, acceptedAt), dispatchedAt, acceptedAt
	end
	local ok, result = pcall(function()
		assert(
			game:GetService("RunService"):IsStudio()
				and Replicated:GetAttribute("MiniatureSandboxReady")
				and Replicated:GetAttribute("MiniatureAdvancedFixture")
				and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
			"Research switch requires a fresh AdvancedBootstrap fake-store Studio place"
		)
		progress("initial snapshot")
		refresh()
		waitFor(function()
			return latest and latest.loaded and latest.writable
		end, "Writable research switch profile missing")
		choose("sparta")
		local state = latest.state
		assert(
			state.coins == 5000
				and state.goods.timber == 80
				and state.goods.material == 20
				and not state.hallUpgraded
				and next(state.research.completed) == nil
				and state.research.project == nil,
			"Research switch must start in a fresh AdvancedBootstrap profile"
		)
		evidence.initial = capture(latest, receivedAt)
		local civic
		for _, building in state.buildings do
			if building.kind == "civic" then
				civic = building
			end
		end
		assert(civic and player.Character, "Owned council/commander missing")
		player.Character:PivotTo(latest.plotFrame * CFrame.new(civic.x, 4, civic.z + 4))
		task.wait(0.3)
		navigate("Settlement")
		local hallPacket = action("Settlement", "UpgradeHall", "improve council")
		evidence.afterHall = capture(hallPacket.snapshot, receivedAt)
		assert(
			evidence.afterHall.hallUpgraded and evidence.afterHall.coins == 4840 and evidence.afterHall.timber == 70,
			"Council improvement did not debit exactly 160 coins and 10 timber"
		)
		navigate("Research")
		press("Research", "Branch_Economy")
		if screen.Research.Content:GetAttribute("ResearchGraphMode") then
			press("Research", "ResearchView")
		end
		press("Research", "ResearchDetails_work")
		local startPacket, startedAt, startReceivedAt = action("Research", "StartResearch", "start Organized Work")
		evidence.started = capture(startPacket.snapshot, startReceivedAt)
		assert(
			evidence.started.coins == 4740
				and evidence.started.timber == 70
				and evidence.started.project
				and evidence.started.project.id == "work"
				and evidence.started.project.remaining > 29
				and evidence.started.project.remaining <= 30,
			"Organized Work did not start once at its exact 100-coin/30-second cost"
		)
		task.wait(1)
		evidence.beforeSwitch = refresh()
		assert(
			evidence.beforeSwitch.project and evidence.beforeSwitch.project.remaining < 30,
			"Active clock did not run"
		)
		local rome, _, romeAcceptedAt = choose("rome")
		evidence.romeEntered = rome
		assert(rome.plotId == evidence.initial.plotId, "Civilization switch moved the owned plot")
		assert(not rome.workCompleted and not rome.project, "Spartan research leaked into Rome")
		progress("remain in Rome for three real seconds")
		local pauseStartedAt = os.clock()
		task.wait(3)
		evidence.romeAfterWait = refresh()
		evidence.explicitRomeWait = os.clock() - pauseStartedAt
		assert(evidence.explicitRomeWait >= 3, "Inactive wait was accelerated")
		assert(
			evidence.romeAfterWait.civilizationId == "rome"
				and not evidence.romeAfterWait.workCompleted
				and not evidence.romeAfterWait.project,
			"Inactive Spartan project appeared in Rome"
		)
		local restored, returnDispatchedAt, returnAcceptedAt = choose("sparta")
		evidence.restored = restored
		assert(
			restored.project
				and restored.project.id == "work"
				and not restored.workCompleted
				and restored.coins == 4740
				and restored.timber == 70
				and restored.hallUpgraded,
			"Returning to Sparta lost research/progress or charged a second payment"
		)
		-- This upper bound includes all active chooser navigation, request transit,
		-- and receipt timing before Rome. It excludes the measured inactive stay.
		local activeBeforeLeavingUpper = romeAcceptedAt - evidence.beforeSwitch.at
		local remainingLost = evidence.beforeSwitch.project.remaining - restored.project.remaining
		local inactiveLower = returnDispatchedAt - romeAcceptedAt
		assert(inactiveLower >= 3, "No measured inactive civilization interval")
		assert(remainingLost >= -0.05, "Switch reset research remaining upward")
		assert(remainingLost <= activeBeforeLeavingUpper + 0.5, "Research consumed inactive time instead of pausing")
		evidence.pause = {
			remainingLost = remainingLost,
			activeBeforeLeavingUpper = activeBeforeLeavingUpper,
			inactiveSecondsLowerBound = inactiveLower,
			returnAcceptedAt = returnAcceptedAt,
			receiptTimingTolerance = 0.5,
		}
		progress("await real active-clock completion")
		waitFor(function()
			return latest.claim.civilizationId == "sparta" and latest.state.research.completed.work
		end, "Organized Work failed to resume and complete", 40)
		evidence.completed = capture(latest, receivedAt)
		evidence.wallSeconds = evidence.completed.at - startedAt
		assert(
			evidence.wallSeconds >= 33,
			"Research finished before 30 active seconds plus the explicit 3-second pause"
		)
		assert(
			evidence.wallSeconds >= 30 + inactiveLower - 0.5,
			"Research completion ignored the measured inactive civilization interval"
		)
		assert(
			evidence.completed.coins == 4740 and evidence.completed.timber == 70 and evidence.completed.project == nil,
			"Completion charged again or left an active project"
		)
		progress("verify completion remains stable without another payment")
		task.wait(2)
		evidence.afterCompletion = refresh()
		assert(
			evidence.afterCompletion.workCompleted
				and not evidence.afterCompletion.project
				and evidence.afterCompletion.coins == 4740
				and evidence.afterCompletion.timber == 70
				and completionTransitions == 1,
			"Research completed repeatedly or debited a duplicate payment"
		)
		local acceptedStarts = 0
		for _, receipt in evidence.receipts do
			if receipt.action == "start Organized Work" and receipt.result.ok then
				acceptedStarts += 1
			end
		end
		assert(acceptedStarts == 1, "Fixture submitted more than one accepted research start")
		evidence.acceptedResearchStarts, evidence.completionTransitions = acceptedStarts, completionTransitions
		evidence.ok = true
		return evidence
	end)
	connection:Disconnect()
	Replicated:SetAttribute("ResearchSwitchPassed", ok)
	Replicated:SetAttribute(
		"ResearchSwitchJSON",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(result), evidence = evidence })
	)
	assert(ok, tostring(result))
	return result
end

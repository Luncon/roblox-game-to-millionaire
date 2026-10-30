--!strict
-- Real input/clocks. Root kills only this isolated test commander at DeathReady.
local function run()
	local Replicated = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Input = game:GetService("UserInputService")
	local Gui = game:GetService("GuiService")
	local Http = game:GetService("HttpService")
	assert(game:GetService("RunService"):IsStudio(), "Studio-only lifecycle test")
	assert(Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong store")
	local player = Players.LocalPlayer
	local screen = player.PlayerGui:WaitForChild("MiniatureSandboxHUD", 15)
	local actions = Replicated.MiniatureActions
	local input = Input:CreateVirtualInput()
	local latest, snapshots = nil, 0
	local receipts, evidence = {}, { realInput = true, realClock = true, projectsInjected = false }
	local connection = actions.Receipt.OnClientEvent:Connect(function(packet)
		latest, snapshots = packet.snapshot, snapshots + 1
		if packet.requestId then
			table.insert(receipts, packet)
		end
	end)
	local function waitFor(predicate, label, seconds)
		local untilAt = os.clock() + (seconds or 15)
		repeat
			if predicate() then
				return
			end
			task.wait(0.05)
		until os.clock() >= untilAt
		error(label)
	end
	local function refresh()
		local before = snapshots
		actions.Snapshot:FireServer()
		waitFor(function()
			return snapshots > before
		end, "Missing lifecycle snapshot")
	end
	local function click(button)
		waitFor(function()
			return button and button.Parent and button.Visible and button.Active
		end, "Lifecycle button unavailable: " .. (button and button.Name or "missing"))
		local point = button.AbsolutePosition + button.AbsoluteSize / 2 + Gui:GetGuiInset()
		input:SendMousePosition(point)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.08)
		input:SendMouseButton(point, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.25)
	end
	local function action(callback)
		local before = #receipts
		callback()
		waitFor(function()
			return #receipts > before
		end, "Lifecycle action receipt missing")
		local result = receipts[#receipts]
		assert(result.result.ok, "Lifecycle action rejected: " .. tostring(result.result.reason))
		return result
	end
	local function choose(id)
		if not screen.Select.Visible then
			click(screen.SettlementHUD.ChangeCivilization)
		end
		local body = screen.Select.Content
		local button = body[if id == "sparta" then "SelectSparta" else "Select" .. id]
		body.CanvasPosition =
			Vector2.new(0, math.max(0, button.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 8))
		task.wait(0.15)
		return action(function()
			click(button)
		end)
	end
	local function progress(value)
		Replicated:SetAttribute("MiniatureMilitaryLifecycleProgress", value)
	end
	local ok, failure = pcall(function()
		refresh()
		local didSelect = latest.claim == nil
		if didSelect then
			choose("sparta")
		end
		assert(
			latest.claim.civilizationId == "sparta" and latest.state.coins == 100000,
			"Fresh research fixture required"
		)
		assert(
			next(latest.state.militaryResearch.completed) == nil and not latest.state.militaryResearch.project,
			"Project preseeded"
		)
		click(screen.OpenResearch)
		local tree = screen.Research.Content.MilitaryResearchTree
		action(function()
			click(tree.SelectedNode.StartMilitaryResearch)
		end)
		assert(latest.state.coins == 99000, "Research payment differs")
		progress("Active research")
		task.wait(4)
		refresh()
		local beforeSwitch = latest.state.militaryResearch.project.remaining
		assert(beforeSwitch < 28 and beforeSwitch > 20, "Active timer did not advance")
		choose("rome")
		assert(
			latest.state.coins == 100000
				and next(latest.state.militaryResearch.completed) == nil
				and not latest.state.militaryResearch.project,
			"Civilization research leaked"
		)
		progress("Research paused in another civilization")
		task.wait(5)
		choose("sparta")
		local afterSwitch = latest.state.militaryResearch.project.remaining
		assert(
			afterSwitch <= beforeSwitch and beforeSwitch - afterSwitch < 1.5,
			"Inactive civilization banked research time"
		)
		assert(latest.state.coins == 99000, "Returning charged research twice")
		evidence.switch =
			{ before = beforeSwitch, after = afterSwitch, inactiveSeconds = 5, coins = latest.state.coins }
		click(screen.OpenResearch)
		click(screen.Research.MinimizePanel)
		local oldCharacter = player.Character
		Replicated:SetAttribute("MiniatureMilitaryLifecycleDeathOwner", player.UserId)
		Replicated:SetAttribute("MiniatureMilitaryLifecycleDeathReady", true)
		progress("Awaiting isolated commander death")
		waitFor(function()
			return oldCharacter.Humanoid.Health <= 0
		end, "No lifecycle death", 25)
		task.wait(0.5)
		refresh()
		local deadRemaining = latest.state.militaryResearch.project.remaining
		assert(
			not screen.Research.Visible
				and not screen.Research:GetAttribute("PanelOpen")
				and not screen.RestoreResearch.Visible,
			"Death retained an open/minimized Research panel"
		)
		task.wait(2)
		refresh()
		assert(oldCharacter.Humanoid.Health <= 0, "Respawn occurred before dead-clock sample")
		local afterDead = latest.state.militaryResearch.project.remaining
		assert(math.abs(afterDead - deadRemaining) < 0.001, "Dead commander advanced research")
		progress("Waiting for original project after respawn")
		waitFor(function()
			return player.Character ~= oldCharacter
				and player.Character
				and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
				and player.Character.Humanoid.Health > 0
		end, "Commander did not respawn", 20)
		refresh()
		assert(latest.state.coins == 99000 and latest.state.militaryResearch.project, "Respawn lost paid research")
		evidence.death = { before = deadRemaining, after = afterDead, sampledSeconds = 2, panelClosed = true }
		waitFor(function()
			return latest.state.militaryResearch.completed.army_training == true
		end, "Restored project failed completion", 35)
		assert(
			latest.state.coins == 99000 and not latest.state.militaryResearch.project,
			"Completion changed payment/project"
		)
		assert(#receipts == (if didSelect then 4 else 3), "Clock completion sent an unexpected gameplay request")
		evidence.completed, evidence.coins, evidence.gameplayRequests = true, latest.state.coins, #receipts
		progress("Passed")
	end)
	Replicated:SetAttribute("MiniatureMilitaryLifecycleDeathReady", false)
	pcall(function()
		input:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton1, false, 0)
	end)
	connection:Disconnect()
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if ok then nil else evidence }
	Replicated:SetAttribute("MiniatureMilitaryLifecycleResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

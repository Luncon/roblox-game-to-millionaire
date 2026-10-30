--!strict
-- Actual HUD with local status variants. Sends no gameplay requests or storage calls.
local function run()
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Http = game:GetService("HttpService")
	assert(
		game:GetService("RunService"):IsStudio()
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wrong profile presentation fixture"
	)
	local player = Players.LocalPlayer
	local UI = require(player.PlayerScripts.MiniatureGame.UI)
	local latest, requests = nil, 0
	local connection = Replicated.MiniatureActions.Receipt.OnClientEvent:Connect(function(packet)
		if packet.snapshot then
			latest = packet.snapshot
		end
	end)
	Replicated.MiniatureActions.Snapshot:FireServer()
	local untilAt = os.clock() + 10
	repeat
		task.wait(0.05)
	until latest or os.clock() >= untilAt
	assert(latest, "No snapshot for profile presentation")
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.ResetOnSpawn, screen.Parent = "NativeProfileStatus", false, player.PlayerGui
	local evidence = { localPresentationCopies = true, layouts = {}, states = {}, gameplayRequests = 0 }
	local ok, failure = pcall(function()
		for _, size in { Vector2.new(320, 360), Vector2.new(320, 568), Vector2.new(640, 360), Vector2.new(1024, 768) } do
			local frame = Instance.new("Frame")
			frame.Size, frame.Parent = UDim2.fromOffset(size.X, size.Y), screen
			local ui = UI.mount(frame, {
				send = function()
					requests += 1
				end,
				camera = function() end,
			})
			for _, sample in
				{
					{ status = "loading", loaded = false, writable = false, text = "Loading" },
					{ status = "retrying", loaded = false, writable = false, text = "Retrying" },
					{
						status = "retrying",
						reason = "profile_in_use",
						loaded = false,
						writable = false,
						text = "previous session",
					},
					{ status = "ready", loaded = true, writable = true, text = "Progress ready" },
					{ status = "ready", loaded = true, writable = true, saved = 1793328030, text = "Saved " },
					{
						status = "save_retry",
						loaded = true,
						writable = true,
						saved = 1793328030,
						text = "Save delayed",
					},
					{
						status = "read_only",
						loaded = true,
						writable = false,
						reason = "authority_lost",
						text = "Rejoin",
					},
					{
						status = "error",
						loaded = false,
						writable = false,
						reason = "invalid_saved_data",
						text = "nothing has been reset",
					},
					{ status = "error", loaded = false, writable = false, reason = "load_failed", text = "Rejoin" },
					{ status = "closing", loaded = true, writable = false, text = "closing" },
				}
			do
				local view = table.clone(latest)
				view.profileStatus, view.profileReason = sample.status, sample.reason
				view.loaded, view.writable, view.lastSavedAt = sample.loaded, sample.writable, sample.saved
				view.storageLabel = "DataStore:MiniatureCivilizationProfilesV1:Live"
				ui.update(view, false)
				task.wait(0.02)
				local label = frame.SettlementHUD.ProfileStatus
				assert(string.find(label.Text, sample.text, 1, true), "HUD status does not give expected guidance")
				assert(
					label.Position.Y.Offset + label.Size.Y.Offset <= frame.SettlementHUD.Size.Y.Offset,
					"Profile status escaped compact HUD"
				)
				if sample.status ~= "ready" then
					assert(
						not string.match(label.Text, "^Saved %d%d:%d%d"),
						"Unconfirmed failure claimed saved durability"
					)
				end
				if not sample.writable then
					assert(
						not frame.SettlementHUD.ChangeCivilization.Visible and ui.guard("select") ~= nil,
						"Unwritable status admitted civilization actions"
					)
				end
				if size.X == 320 and size.Y == 360 then
					table.insert(evidence.states, { status = sample.status, reason = sample.reason, text = label.Text })
				end
			end
			local temporary = table.clone(latest)
			temporary.loaded, temporary.writable, temporary.profileStatus, temporary.lastSavedAt =
				true, true, "ready", 1793328030
			temporary.storageLabel = "InjectedFakeProfileStore"
			ui.update(temporary, false)
			assert(
				frame.SettlementHUD.ProfileStatus.Text == "Temporary Studio progress",
				"Fake storage presented as durable"
			)
			table.insert(evidence.layouts, { width = size.X, height = size.Y, compactBounds = true })
			frame:Destroy()
		end
		assert(requests == 0, "Status rendering emitted a gameplay request")
	end)
	screen:Destroy()
	connection:Disconnect()
	evidence.gameplayRequests = requests
	local result =
		{ ok = ok, result = if ok then evidence else tostring(failure), evidence = if ok then nil else evidence }
	Replicated:SetAttribute("MiniatureProfileStatusResult", Http:JSONEncode(result))
	assert(ok, tostring(failure))
	return result
end

return run

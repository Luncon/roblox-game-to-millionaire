--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Civilizations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Civilizations"))
local CivilizationUI = {}
local Panels=require(script.Parent.PanelVisibility)
local INK = Color3.fromRGB(30, 37, 40)
local TEXT = Color3.fromRGB(246, 240, 223)
local MUTED = Color3.fromRGB(183, 194, 193)
local GOLD = Color3.fromRGB(220, 181, 98)

local function textLabel(parent: Instance, name: string, text: string, y: number, height: number, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.new(0, 16, 0, y)
	label.Size = UDim2.new(1, -32, 0, height)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = size
	label.TextColor3 = TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function CivilizationUI.start()
	local player = Players.LocalPlayer
	local screen = Instance.new("ScreenGui")
	screen.Name = "CivilizationSelection"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "SelectionPanel"
	panel.AnchorPoint = Vector2.new(.5, .5)
	panel.Position = UDim2.fromScale(.5, .5)
	panel.Size = UDim2.new(1, -32, 1, -32)
	panel.BackgroundColor3 = INK
	panel.BorderSizePixel = 0
	panel.Parent = screen
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(480, 680)
	limit.Parent = panel
	local outline = Instance.new("UIStroke")
	outline.Color = Color3.fromRGB(105, 119, 117)
	outline.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Position=UDim2.fromOffset(0,52)
	content.Size = UDim2.new(1,0,1,-52)
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollBarThickness = 4
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = content
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	-- Extra scroll space lets the last choice move above mobile movement controls.
	padding.PaddingBottom = UDim.new(0, 112)
	padding.Parent = content
	local title = textLabel(content, "Title", "Choose your civilization", 0, 58, 24)
	title.LayoutOrder = 0
	title.Font = Enum.Font.GothamBold
	title.Parent=panel;title.Position=UDim2.fromOffset(16,6);title.Size=UDim2.new(1,-80,0,38);title.TextSize=18
	local introduction = textLabel(content, "Introduction", "13 civilizations · 8 settlement plots\nContinue your civilization, or begin another settlement.", 0, 42, 14)
	introduction.LayoutOrder = 1
	introduction.TextColor3 = MUTED
	local feedback = textLabel(content, "Feedback", "Connecting to the server…", 0, 58, 14)
	feedback.LayoutOrder = 2
	feedback.TextColor3 = GOLD
	local notice = textLabel(content, "PrototypeNotice", "Progress is saved separately for each civilization", 0, 22, 11)
	notice.LayoutOrder = 100
	notice.TextColor3 = MUTED

	local refresh = Instance.new("TextButton")
	refresh.Name = "Refresh"
	refresh.LayoutOrder = 3
	refresh.Size = UDim2.new(1, -32, 0, 40)
	refresh.BackgroundColor3 = Color3.fromRGB(54, 66, 68)
	refresh.BorderSizePixel = 0
	refresh.Font = Enum.Font.GothamMedium
	refresh.TextSize = 14
	refresh.TextColor3 = TEXT
	refresh.Text = "Refresh available civilizations"
	refresh.Parent = content

	local hud = Instance.new("Frame")
	hud.Name = "SettlementHUD"
	hud.Position = UDim2.fromOffset(16, 16)
	hud.Size = UDim2.new(1, -32, 0, 96)
	hud.BackgroundColor3 = INK
	hud.BorderSizePixel = 0
	hud.Visible = false
	hud.Parent = screen
	local hudLimit = Instance.new("UISizeConstraint")
	hudLimit.MaxSize = Vector2.new(360, 96)
	hudLimit.Parent = hud
	local ownedTitle = textLabel(hud, "Civilization", "", 8, 32, 20)
	ownedTitle.Font = Enum.Font.GothamBold
	textLabel(hud, "Instruction", "Build your civilization.\nProgress saves separately for each civilization.", 44, 44, 12).TextColor3 = MUTED

	local switchButton = Instance.new("TextButton")
	switchButton.Name = "SwitchCivilization"
	switchButton.Size = UDim2.fromOffset(88,22)
	switchButton.Position = UDim2.new(1,-100,0,6)
	switchButton.BackgroundColor3 = Color3.fromRGB(54,66,68)
	switchButton.BorderSizePixel = 0
	switchButton.Font = Enum.Font.GothamMedium
	switchButton.TextSize = 11
	switchButton.TextColor3 = TEXT
	switchButton.Text = "Change civ"
	switchButton.Parent = hud
	local selectorVisibility=Panels.attach(screen,panel,panel,'Civilizations','civilizations','selector')
	local hudVisibility=Panels.attach(screen,hud,hud,'Settlement','settlement')
	local cancel = refresh:Clone()
	cancel.Name, cancel.Text, cancel.LayoutOrder = "Cancel", "Back to settlement", 3
	cancel.Parent = content
	refresh.LayoutOrder = 4
	local buttons = {}
	for index, civilization in Civilizations do
		local button = Instance.new("TextButton")
		button.Name = civilization.id
		button.LayoutOrder = index + 4
		button.Size = UDim2.new(1, -32, 0, 138)
		button.BackgroundColor3 = Color3.fromRGB(48, 59, 62)
		button.BorderSizePixel = 0
		button.Text = ""
		button.Parent = content
		local accent = Instance.new("UIStroke")
		accent.Color = civilization.color
		accent.Thickness = 2
		accent.Parent = button
		textLabel(button, "CivilizationName", civilization.name, 6, 26, 18).Font = Enum.Font.GothamBold
		textLabel(button, "Period", civilization.period, 34, 30, 12).TextColor3 = MUTED
		local progress = textLabel(button,"Progress","Loading saved progress…",70,36,11)
		progress.TextColor3 = MUTED
		local availability = textLabel(button, "Availability", "Loading…", 110, 24, 12)
		availability.TextColor3 = GOLD
		buttons[civilization.id] = { button = button, label = availability, progress = progress }
	end

	local busy = true
	local requestNumber = 0
	local revision = -1
	local availability = nil
	local profile = nil
	local choosing = false
	local lastStatus = nil
	local requestRemote: RemoteFunction? = nil
	local function render()
		local owned = player:GetAttribute("CivilizationId")
		local plotId = player:GetAttribute("PlotId")
		local civilization = nil
		for _, entry in Civilizations do
			if entry.id == owned then civilization = entry end
		end
		local claimed = civilization ~= nil and typeof(plotId) == "number"
		selectorVisibility:setVisible(not claimed or choosing)
		hudVisibility:setVisible(claimed and not choosing)
		cancel.Visible = claimed
		cancel.Active, cancel.Selectable = claimed and not busy, claimed and not busy
		local status = player:GetAttribute("ProgressStatus") or (if profile then profile.status else "loading")
		local ready = status == "ready" or status == "saving"
		switchButton.Active, switchButton.Selectable = ready and not busy, ready and not busy
		if claimed then
			ownedTitle.Text = string.format("%s · Plot %02d", civilization.name, plotId)
			ownedTitle.TextColor3 = civilization.color:Lerp(TEXT, .65)
		end
		for id, row in buttons do
			local entry = if availability then availability[id] else nil
			local current = id == owned
			local available = entry ~= nil and entry.ownerId == nil
			local saved = if profile and profile.civilizations then profile.civilizations[id] else nil
			row.progress.Text = if saved then string.format("Settlement %d · %d coins\nWeapon %d · Armor %d · Barracks %d",saved.level,saved.coins,saved.weaponLevel,saved.armorLevel,saved.barracksLevel)
				elseif ready then "New settlement · 0 coins\nAll upgrades start at level 1" else "Saved progress is not available yet"
			row.button.Active = available and ready and not busy
			row.button.Selectable = row.button.Active
			row.button.AutoButtonColor = row.button.Active
			row.button.BackgroundColor3 = if available then Color3.fromRGB(48, 59, 62) else Color3.fromRGB(40, 46, 49)
			row.label.Text = if current then "CURRENT CIVILIZATION" elseif not ready then "Waiting for saved progress…" elseif busy then "Please wait…" elseif not entry then "Unavailable · refresh to retry" elseif available then "AVAILABLE · SELECT" else "CLAIMED · " .. (entry.ownerName or "Another commander")
		end
		local failed = status == "failed" or status == "locked" or status == "lost" or status == "closed"
		refresh.Text = if status=="lost" then "Rejoin to reload progress" elseif failed and not claimed then "Retry loading progress" else "Refresh available civilizations"
		if status~=lastStatus then
			lastStatus=status
			if status == "loading" or status == "not_loaded" then feedback.Text = "Loading your saved civilizations…"
			elseif status=="lost" then feedback.Text="Your progress session ended. Rejoin to reload it safely."
			elseif failed then feedback.Text = if player:GetAttribute("ProgressError") == "session_busy" then "Your progress is still open in another server. Wait a moment and retry." else "Your progress could not be loaded safely. Retry before choosing a civilization." end
		end
		refresh.Active = not busy and requestRemote ~= nil and status ~= "loading"
		if status=="lost" then refresh.Active=false end
		refresh.Selectable = refresh.Active
		refresh.AutoButtonColor = refresh.Active
	end

	local function acceptState(state)
		if type(state) == "table" and type(state.revision) == "number" and state.revision >= revision then
			revision = state.revision
			availability = state.availability
			if state.profile then profile = state.profile end
		end
	end

	local errors = {
		unavailable = "Another commander claimed that civilization. Choose another or wait for it to open.",
		already_claimed = "Use Change civ to switch civilizations.",
		profile_unavailable = "Your saved progress is not ready. Wait or retry loading.",
		load_wait = "Please wait a few seconds before retrying saved progress.",
		full = "All settlement plots are occupied. Try another server.",
		invalid = "That selection was not accepted. Refresh and try again.",
		rate_limited = "Please wait a moment, then try again.",
	}
	local function send(action: string, civilizationId: string?)
		if busy or not requestRemote then return end
		busy = true
		requestNumber += 1
		local ticket = requestNumber
		feedback.Text = if action == "switch" then "Restoring your civilization…" elseif action == "select" then "Claiming your settlement…" elseif action == "retry" then "Retrying saved progress…" else "Refreshing available civilizations…"
		render()
		task.delay(8, function()
			if requestNumber == ticket and busy then
				requestNumber += 1
				busy = false
				feedback.Text = "The server took too long. Refresh to check your selection."
				content.CanvasPosition = Vector2.zero
				render()
			end
		end)
		task.spawn(function()
			local ok, result = pcall(function()
				return requestRemote:InvokeServer(action, civilizationId)
			end)
			if ticket ~= requestNumber then return end
			busy = false
			if not ok or type(result) ~= "table" then
				feedback.Text = "Could not reach the server. Refresh and try again."
				content.CanvasPosition = Vector2.zero
			else
				acceptState(result.state)
				if result.ok and (action == "select" or action == "switch") then choosing = false end
				feedback.Text = if result.ok then "Choose an available civilization to claim your settlement." else errors[result.reason] or "Selection failed. Refresh and try again."
				if not result.ok then content.CanvasPosition = Vector2.zero end
			end
			render()
			if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 and panel.Visible then
				for _, row in buttons do
					if row.button.Selectable then GuiService.SelectedObject = row.button; break end
				end
			end
		end)
	end

	for id, row in buttons do
		row.button.Activated:Connect(function() send(if player:GetAttribute("CivilizationId") then "switch" else "select", id) end)
	end
	refresh.Activated:Connect(function()
		local status=player:GetAttribute("ProgressStatus")
		send(if (status=="failed" or status=="locked" or status=="closed") and not player:GetAttribute("CivilizationId") then "retry" else "snapshot",nil)
	end)
	switchButton.Activated:Connect(function() choosing=true;selectorVisibility:restore();content.CanvasPosition=Vector2.zero;render();send("snapshot",nil) end)
	cancel.Activated:Connect(function() choosing=false;render() end)
	player:GetAttributeChangedSignal("ProgressStatus"):Connect(render)
	player:GetAttributeChangedSignal("ProgressError"):Connect(render)
	player:GetAttributeChangedSignal("CivilizationId"):Connect(render)
	player:GetAttributeChangedSignal("PlotId"):Connect(render)
	render()
	require(script.Parent:WaitForChild("EconomyUI")).start(screen)
	require(script.Parent:WaitForChild("ArmyUI")).start(screen)
	task.spawn(function()
		local function startupFailure()
			local reason = ReplicatedStorage:GetAttribute("GameStartupError")
			if not reason then return false end
			busy = false
			feedback.Text = if reason == "unpublished_place"
				then "Saved progress requires a published test experience with Studio API access. For temporary progress, use the isolated test place."
				else "Server startup failed. Check Studio Output for the error, then restart Play after fixing it."
			render()
			return true
		end
		ReplicatedStorage:GetAttributeChangedSignal("GameStartupError"):Connect(startupFailure)
		if startupFailure() then return end
		local remotes = ReplicatedStorage:WaitForChild("CivilizationRemotes", 15)
		if not remotes then
			if startupFailure() then return end
			busy = false
			feedback.Text = "Server startup did not finish. Check Studio Output for errors and confirm Rojo is connected before restarting Play."
			render()
			return
		end
		requestRemote = remotes:WaitForChild("Request") :: RemoteFunction
		local changed = remotes:WaitForChild("Changed") :: RemoteEvent
		changed.OnClientEvent:Connect(function(state)
			acceptState(state)
			render()
		end)
		busy = false
		send("snapshot", nil)
	end)
end

return CivilizationUI

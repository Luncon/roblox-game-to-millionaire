--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Civilizations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Civilizations"))
local CivilizationUI = {}
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
	content.Size = UDim2.fromScale(1, 1)
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
	local introduction = textLabel(content, "Introduction", "13 civilizations · 8 settlement plots\nChoose your civilization, then build your settlement.", 0, 42, 14)
	introduction.LayoutOrder = 1
	introduction.TextColor3 = MUTED
	local feedback = textLabel(content, "Feedback", "Connecting to the server…", 0, 58, 14)
	feedback.LayoutOrder = 2
	feedback.TextColor3 = GOLD
	local notice = textLabel(content, "PrototypeNotice", "Session only · Progress is not saved yet", 0, 22, 11)
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
	textLabel(hud, "Instruction", "Build your civilization.\nCoins and upgrades last this session.", 44, 44, 12).TextColor3 = MUTED

	local buttons = {}
	for index, civilization in Civilizations do
		local button = Instance.new("TextButton")
		button.Name = civilization.id
		button.LayoutOrder = index + 3
		button.Size = UDim2.new(1, -32, 0, 100)
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
		local availability = textLabel(button, "Availability", "Loading…", 70, 24, 12)
		availability.TextColor3 = GOLD
		buttons[civilization.id] = { button = button, label = availability }
	end

	local busy = true
	local requestNumber = 0
	local revision = -1
	local availability = nil
	local requestRemote: RemoteFunction? = nil
	local function render()
		local owned = player:GetAttribute("CivilizationId")
		local plotId = player:GetAttribute("PlotId")
		local civilization = nil
		for _, entry in Civilizations do
			if entry.id == owned then civilization = entry end
		end
		local claimed = civilization ~= nil and typeof(plotId) == "number"
		panel.Visible = not claimed
		hud.Visible = claimed
		if claimed then
			ownedTitle.Text = string.format("%s · Plot %02d", civilization.name, plotId)
			ownedTitle.TextColor3 = civilization.color:Lerp(TEXT, .65)
		end
		for id, row in buttons do
			local entry = if availability then availability[id] else nil
			local available = entry ~= nil and entry.ownerId == nil
			row.button.Active = available and not busy and not claimed
			row.button.Selectable = row.button.Active
			row.button.AutoButtonColor = row.button.Active
			row.button.BackgroundColor3 = if available then Color3.fromRGB(48, 59, 62) else Color3.fromRGB(40, 46, 49)
			row.label.Text = if busy then "Please wait…" elseif not entry then "Unavailable · refresh to retry" elseif available then "AVAILABLE · SELECT" else "CLAIMED · " .. (entry.ownerName or "Another commander")
		end
		refresh.Active = not busy and requestRemote ~= nil
		refresh.Selectable = refresh.Active
		refresh.AutoButtonColor = refresh.Active
	end

	local function acceptState(state)
		if type(state) == "table" and type(state.revision) == "number" and state.revision >= revision then
			revision = state.revision
			availability = state.availability
		end
	end

	local errors = {
		unavailable = "Another commander claimed that civilization. Choose another or wait for it to open.",
		already_claimed = "Your civilization is already claimed for this session.",
		full = "All settlement plots are occupied. Try another server.",
		invalid = "That selection was not accepted. Refresh and try again.",
		rate_limited = "Please wait a moment, then try again.",
	}
	local function send(action: string, civilizationId: string?)
		if busy or not requestRemote then return end
		busy = true
		requestNumber += 1
		local ticket = requestNumber
		feedback.Text = if action == "select" then "Claiming your settlement…" else "Refreshing available civilizations…"
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
		row.button.Activated:Connect(function() send("select", id) end)
	end
	refresh.Activated:Connect(function() send("snapshot", nil) end)
	player:GetAttributeChangedSignal("CivilizationId"):Connect(render)
	player:GetAttributeChangedSignal("PlotId"):Connect(render)
	render()
	require(script.Parent:WaitForChild("EconomyUI")).start(screen)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("CivilizationRemotes", 15)
		if not remotes then
			busy = false
			feedback.Text = "The server is not ready. Stop and restart Play after Rojo finishes syncing."
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

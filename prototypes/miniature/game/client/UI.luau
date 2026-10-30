--!strict
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Config = require(Replicated:WaitForChild("MiniatureGame").Config)
local Theme = require(script.Parent.Theme)
local Panels = require(script.Parent.PanelVisibility)
local Pages = require(script.Parent.Pages)
local UI = {}

function UI.mount(screen, callbacks)
	local view, pending, page, toastGeneration = nil, false, nil, 0
	local drafts = { category = "Homes" }
	local surfaces, controllers, bodies, bindings, travelButtons = {}, {}, {}, {}, {}
	local controller = {}
	local function round(frame)
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 6), frame
	end
	local hud = Theme.frame(screen, "SettlementHUD", 130)
	hud.BackgroundColor3 = Theme.stone
	round(hud)
	local title = Theme.label(hud, "SettlementTitle", "SETTLEMENT", 24)
	title.Position, title.Size, title.Font, title.TextColor3 =
		UDim2.fromOffset(8, 0), UDim2.new(1, -56, 0, 24), Enum.Font.GothamBold, Theme.gold
	local stats = Theme.label(hud, "Resources", "Loading…", 54)
	stats.Position, stats.Size, stats.TextSize = UDim2.fromOffset(8, 24), UDim2.new(1, -16, 0, 54), 12
	local change = Theme.button(hud, "ChangeCivilization", "Change civilization", function()
		controller.navigate("Select")
	end)
	change.Position, change.Size, change.TextSize = UDim2.fromOffset(8, 82), UDim2.new(1, -16, 0, 44), 12
	local hudVisibility = Panels.attach(screen, hud, hud, "Settlement", "settlement")
	hudVisibility:setVisible(true)
	local feedback = Theme.label(screen, "ActionFeedback", "", 40)
	feedback.BackgroundColor3, feedback.BackgroundTransparency, feedback.ZIndex, feedback.Visible =
		Theme.stone, 0.08, 70, false
	feedback.TextXAlignment, feedback.TextSize = Enum.TextXAlignment.Center, 12
	round(feedback)
	local function setMessage(text)
		toastGeneration += 1
		local current = toastGeneration
		feedback.Text, feedback.Visible = text, text ~= ""
		task.delay(4, function()
			if feedback.Parent and current == toastGeneration then
				feedback.Visible = false
			end
		end)
	end
	local function guard(action, buildingId)
		if not view or not view.loaded then
			return "Loading settlement"
		end
		if not view.writable then
			return "Settlement is read only"
		end
		if not view.capabilities or not view.capabilities[action] then
			return "Action unavailable"
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return "A living commander is required"
		end
		if pending then
			return "Waiting for confirmation…"
		end
		if action == "select" then
			return nil
		end
		if not view.claim or not view.state or not view.artReady or not view.plotFrame then
			return "Choose a civilization"
		end
		if action == "travel" then
			return nil
		end
		local target, range = nil, Config.interactionRange
		if action == "place" then
			target, range = view.plotFrame.Position, Config.placementRange
		elseif action == "buy" then
			target = view.buyShopPosition
		elseif action == "sellAll" then
			target = view.sellShopPosition
		elseif action == "targetOutpost" then
			local outpost = view.outposts and view.outposts[buildingId]
			target = outpost and outpost.position
		else
			local houses, selected = 0, nil
			for _, building in view.state.buildings do
				if building.kind == "house" then
					houses += 1
				end
				if building.id == buildingId then
					selected = building
				end
			end
			if action == "reclaim" and selected then
				if selected.kind == "civic" then
					return "Keep your council building"
				end
				if selected.kind == "house" and houses <= 1 then
					return "Keep at least one house"
				end
			end
			if selected then
				target = view.plotFrame:PointToWorldSpace(Vector3.new(selected.x, 0.4, selected.z))
			end
		end
		if not target then
			return "Required building is unavailable"
		end
		if (root.Position - target).Magnitude > range then
			return "Move closer to "
				.. (
					if action == "buy"
						then "the building shop"
						elseif action == "sellAll" then "the goods shop"
						elseif action == "place" then "your plot"
						elseif action == "targetOutpost" then "the outpost center"
						else "this building"
				)
		end
		return nil
	end
	local rebuild
	function controller.closePanels()
		for _, visibility in controllers do
			visibility:setVisible(false)
		end
		page = nil
		screen:SetAttribute("OpenMenu", nil)
	end
	local function makeSurface(name, label)
		local surface = Theme.frame(screen, name, 300)
		surface.BackgroundColor3, surface.ZIndex, surface.Active = Theme.stone, 10, true
		round(surface)
		local heading = Theme.label(surface, "PanelTitle", label, 44)
		heading.Position, heading.Size, heading.Font, heading.TextColor3 =
			UDim2.fromOffset(10, 0), UDim2.new(1, -112, 0, 44), Enum.Font.GothamBold, Theme.gold
		local close = Theme.button(surface, "Close", "×", controller.closePanels)
		close.Position, close.Size, close.TextSize = UDim2.new(1, -96, 0, 0), UDim2.fromOffset(44, 44), 24
		local body = Instance.new("ScrollingFrame")
		body.Name, body.Position, body.Size = "Content", UDim2.fromOffset(0, 48), UDim2.new(1, 0, 1, -52)
		body.AutomaticCanvasSize, body.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
		body.BackgroundTransparency, body.BorderSizePixel, body.ScrollBarThickness = 1, 0, 4
		body.ScrollingDirection, body.Parent = Enum.ScrollingDirection.Y, surface
		Theme.list(body, 6)
		surfaces[name], bodies[name], bindings[name] = surface, body, {}
		controllers[name] = Panels.attach(screen, surface, surface, name, label)
	end
	for _, entry in { { "Select", "Civilizations" }, { "Build", "Building shop" }, { "Trade", "Sell goods" } } do
		makeSurface(entry[1], entry[2])
	end
	function controller.navigate(name)
		if not controllers[name] then
			return
		end
		if callbacks.closeInventory then
			callbacks.closeInventory()
		end
		if name ~= "Select" and (not view or not view.state) then
			name = "Select"
		end
		controller.closePanels()
		page = name
		controllers[name]:setVisible(true)
		controllers[name]:restore()
		screen:SetAttribute("OpenMenu", name)
		rebuild(name)
	end
	rebuild = function(name)
		local body = bodies[name]
		local scroll = body.CanvasPosition
		for _, child in body:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		bindings[name] = {}
		local order = 0
		local ctx = {
			body = body,
			player = Players.LocalPlayer,
			drafts = drafts,
			guard = guard,
			send = callbacks.send,
			message = setMessage,
		}
		function ctx.view()
			return view
		end
		function ctx.rebuild()
			rebuild(name)
		end
		function ctx.order(object)
			order += 1
			object.LayoutOrder = order
			return object
		end
		function ctx.track(update)
			table.insert(bindings[name], update)
		end
		function ctx.label(key, text, height)
			return ctx.order(Theme.label(body, key, text, height))
		end
		function ctx.button(key, text, callback)
			return ctx.order(Theme.button(body, key, text, callback))
		end
		function ctx.dynamic(key, render, height)
			local label = ctx.label(key, "", height)
			ctx.track(function()
				if view and view.state then
					label.Text = render(view)
				end
			end)
			return label
		end
		if name == "Select" or view and view.state then
			Pages[name](ctx)
		end
		body.CanvasPosition = scroll
		for _, update in bindings[name] do
			update()
		end
	end
	local nav, navSize = Theme.row(screen, "TopNavigation", 3)
	nav.BackgroundTransparency, nav.ZIndex = 1, 20
	for _, entry in { { "Buy", "buy" }, { "Civilization", "civilization" }, { "Sell", "sell" } } do
		local button = Theme.button(nav, entry[1], entry[1], function()
			local blocked = guard("travel")
			if blocked then
				setMessage(blocked)
			else
				callbacks.send("travel", { destination = entry[2] })
			end
		end)
		button.Size, button.TextSize = navSize, 13
		travelButtons[entry[1]] = button
	end
	local cameraDock = Theme.frame(screen, "CameraControls", 44)
	cameraDock.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.Padding, layout.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 4), cameraDock
	for _, mode in { "Walk", "Overview" } do
		local button = Theme.button(cameraDock, mode, mode, function()
			callbacks.camera(mode)
		end)
		button.Size = UDim2.fromOffset(100, 44)
	end
	local function resize()
		local width, height = screen.AbsoluteSize.X, screen.AbsoluteSize.Y
		local navWidth = math.min(324, width - 24)
		nav.Position, nav.Size = UDim2.fromOffset((width - navWidth) / 2, 8), UDim2.fromOffset(navWidth, 44)
		hud.Position, hud.Size = UDim2.fromOffset(16, 64), UDim2.fromOffset(math.min(196, width - 32), 130)
		for name, surface in surfaces do
			local panelWidth =
				math.min(if name == "Trade" then 280 elseif name == "Build" then 420 else 296, width - 24)
			local panelHeight = math.min(if name == "Trade" then 200 else 360, height - 132)
			surface.Position, surface.Size =
				UDim2.fromOffset((width - panelWidth) / 2, math.max(56, (height - panelHeight) / 2)),
				UDim2.fromOffset(panelWidth, panelHeight)
		end
		local toastWidth = math.min(420, width - 32)
		feedback.Position, feedback.Size =
			UDim2.fromOffset((width - toastWidth) / 2, 56), UDim2.fromOffset(toastWidth, 40)
		cameraDock.Position, cameraDock.Size = UDim2.fromOffset(16, height - 124), UDim2.fromOffset(204, 44)
	end
	local elapsed = 0
	local connections = { screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize) }
	table.insert(
		connections,
		Run.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.15 then
				return
			end
			elapsed = 0
			for _, button in travelButtons do
				Theme.enabled(button, guard("travel") == nil)
			end
			for _, updates in bindings do
				for _, update in updates do
					update()
				end
			end
			screen:SetAttribute("OpenMenu", if page and surfaces[page].Visible then page else nil)
		end)
	)
	function controller.update(nextView, changed)
		view = nextView
		if changed then
			controller.closePanels()
			if not view.state or not view.artReady then
				controller.navigate("Select")
			end
		end
		if view.state then
			local state, total, capacity = view.state, 0, Config.goodsCapacity
			for _, amount in state.goods do
				total += amount
			end
			for _, building in state.buildings do
				if building.kind == "storehouse" then
					capacity = 400
				end
			end
			title.Text = string.upper(state.civilizationId)
			stats.Text =
				string.format("%d coins\nGoods %d/%d\nPopulation %d", state.coins, total, capacity, #state.workers)
			if view.troops and view.troopCapacity then
				local mounted = view.troops.mounted or 0
				local used = view.troopCapacityUsed
					or (view.troops.melee + view.troops.ranged + view.troops.medic + mounted * 2)
				stats.Text = string.format(
					"%d coins\nGoods %d/%d · Mounted %d\nPeople %d · Army %d/%d",
					state.coins,
					total,
					capacity,
					mounted,
					#state.workers,
					used,
					view.troopCapacity
				)
			end
		else
			title.Text, stats.Text = "SETTLEMENT", if view.loaded then "Choose a civilization" else "Loading…"
		end
		for _, updates in bindings do
			for _, update in updates do
				update()
			end
		end
	end
	function controller.pending(value)
		pending = value
	end
	function controller.message(text)
		setMessage(text)
	end
	function controller.guard(action, id)
		return guard(action, id)
	end
	function controller.refresh()
		if page then
			rebuild(page)
		end
	end
	function controller.getView()
		return view
	end
	screen.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	resize()
	controller.navigate("Select")
	return controller
end
return UI

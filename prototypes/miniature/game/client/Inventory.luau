--!strict
local Replicated = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Shared = Replicated:WaitForChild("MiniatureGame")
local Catalog = require(Shared.Catalog)
local Presentation = require(Shared.Presentation)
local Theme = require(script.Parent.Theme)
local Panels = require(script.Parent.PanelVisibility)
local Inventory = {}
local kinds =
	{ "house", "farm", "timber", "material", "workshop", "storehouse", "training", "ranged", "healer", "mount" }
local goods = { food = "Grain", timber = "Timber", material = "Clay", crafted = "Pottery" }
local keys = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
}

local function thumbnail(button, kind, civilizationId)
	local previous = button:FindFirstChild("ItemPreview")
	if previous then
		previous:Destroy()
	end
	if not kind then
		return
	end
	local previews = Shared:FindFirstChild("Previews")
	local kit = previews and civilizationId and previews:FindFirstChild(civilizationId)
	local source = kit and kit:FindFirstChild(kind)
	if not source or not source:IsA("Model") then
		return
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name, viewport.BackgroundTransparency, viewport.Active = "ItemPreview", 1, false
	viewport.Position, viewport.Size = UDim2.fromOffset(2, 0), UDim2.fromOffset(56, 36)
	viewport.Ambient, viewport.LightColor = Color3.fromRGB(190, 180, 155), Color3.fromRGB(255, 238, 203)
	viewport.Parent = button
	local world, camera = Instance.new("WorldModel"), Instance.new("Camera")
	world.Parent, camera.Parent, viewport.CurrentCamera = viewport, viewport, camera
	local clone = source:Clone()
	for _, child in clone:GetDescendants() do
		if child:IsA("LuaSourceContainer") or child:IsA("ClickDetector") or child:IsA("ProximityPrompt") then
			child:Destroy()
		end
	end
	clone.Parent = world
	local frame, size = clone:GetBoundingBox()
	camera.CFrame = CFrame.lookAt(
		frame.Position + Vector3.new(1, 0.9, 1).Unit * math.max(size.X, size.Y, size.Z) * 1.75,
		frame.Position
	)
end

function Inventory.start(screen, callbacks)
	local originalBackpack = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	local view, selected, civilizationId = nil, nil, nil
	local slots, planButtons, goodsLabels, slotKinds = {}, {}, {}, {}
	local controller = {}
	local panel = Theme.frame(screen, "Inventory", 300)
	panel.ZIndex, panel.BackgroundColor3, panel.Active = 30, Theme.stone, true
	local title = Theme.label(panel, "PanelTitle", "INVENTORY", 44)
	title.Position, title.Size, title.TextColor3 = UDim2.fromOffset(8, 0), UDim2.new(1, -112, 0, 44), Theme.gold
	local visibility = Panels.attach(screen, panel, panel, "Inventory", "inventory")
	local close = Theme.button(panel, "Close", "×", function()
		visibility:setVisible(false)
	end)
	close.Position, close.Size = UDim2.new(1, -96, 0, 0), UDim2.fromOffset(44, 44)
	local body = Instance.new("ScrollingFrame")
	body.Name, body.Position, body.Size = "Content", UDim2.fromOffset(0, 48), UDim2.new(1, 0, 1, -52)
	body.BackgroundTransparency, body.BorderSizePixel, body.ScrollBarThickness = 1, 0, 6
	body.AutomaticCanvasSize, body.CanvasSize, body.Parent = Enum.AutomaticSize.Y, UDim2.new(), panel
	Theme.list(body, 6)
	local order = 0
	local function ordered(item)
		order += 1
		item.LayoutOrder = order
		return item
	end
	ordered(
		Theme.label(
			body,
			"InventoryGuide",
			"Choose a building item to place it. Buildings and collected goods stay here.",
			56
		)
	)
	local capacity = ordered(Theme.label(body, "GoodsCapacity", "Collected goods", 32))
	for _, good in Catalog.goods do
		goodsLabels[good] = ordered(Theme.label(body, "Goods_" .. good, "", 32))
	end
	ordered(Theme.label(body, "BuildingsHeading", "Building items · choose to place", 36))
	local hint = ordered(Theme.label(body, "InventoryStatus", "", 56))
	local hotbar = Theme.frame(screen, "Hotbar", 64)
	hotbar.ZIndex, hotbar.BackgroundColor3 = 40, Theme.stone
	local content = Instance.new("ScrollingFrame")
	content.Name, content.Size, content.BackgroundTransparency = "Content", UDim2.fromScale(1, 1), 1
	content.CanvasSize, content.ScrollingDirection = UDim2.fromOffset(9 * 68 + 4, 0), Enum.ScrollingDirection.X
	content.BorderSizePixel, content.ScrollBarThickness, content.Parent = 0, 4, hotbar
	local toggle = Theme.button(screen, "InventoryToggle", "Inventory · B", function()
		controller.toggle()
	end)
	toggle.ZIndex, toggle.TextSize = 45, 12
	function controller.clear()
		selected = nil
		screen:SetAttribute("SelectedInventoryItem", nil)
		screen:SetAttribute("HammerSelected", false)
	end
	function controller.close()
		visibility:setVisible(false)
	end
	function controller.toggle()
		local open = not visibility:isOpen()
		visibility:setVisible(open)
		if open then
			callbacks.closePanels()
			visibility:restore()
		end
	end
	local function choose(kind)
		if kind == "hammer" then
			local blocked = callbacks.guard("travel")
			if blocked then
				callbacks.message(blocked)
				return
			end
			callbacks.cancelPlacement()
			if selected == "hammer" then
				controller.clear()
			else
				selected = "hammer"
				visibility:setVisible(false)
				callbacks.closePanels()
				screen:SetAttribute("SelectedInventoryItem", selected)
				screen:SetAttribute("HammerSelected", true)
				callbacks.message(
					"Destroy Hammer: click an owned building to return it to inventory. Council and last house are protected."
				)
			end
			return
		end
		if not view or not view.state or (view.state.plans[kind] or 0) < 1 then
			callbacks.message("No owned building item available")
			return
		end
		local blocked = callbacks.guard("place")
		if blocked then
			callbacks.message(blocked)
			return
		end
		selected = kind
		screen:SetAttribute("SelectedInventoryItem", kind)
		screen:SetAttribute("HammerSelected", false)
		visibility:setVisible(false)
		callbacks.closePanels()
		callbacks.place(kind)
	end
	for _, kind in kinds do
		local button = ordered(Theme.button(body, "Plan_" .. kind, "", function()
			choose(kind)
		end))
		button.Size = UDim2.new(1, 0, 0, 52)
		planButtons[kind] = button
	end
	for index = 1, 9 do
		local button = Theme.button(content, "Slot" .. index, "", function()
			local kind = if index == 1 then "hammer" else slotKinds[index]
			if kind then
				choose(kind)
			end
		end)
		button.Position, button.Size, button.TextSize =
			UDim2.fromOffset((index - 1) * 68 + 4, 2), UDim2.fromOffset(64, 56), 10
		button.TextYAlignment = Enum.TextYAlignment.Top
		local label = Theme.label(button, "ItemLabel", "", 24)
		label.Position, label.Size, label.TextSize, label.TextXAlignment =
			UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 24), 10, Enum.TextXAlignment.Center
		slots[index] = button
	end
	local function refresh()
		toggle.Visible = screen:GetAttribute("OpenMenu") == nil
		local state = view and view.state
		local total = 0
		for _, good in Catalog.goods do
			local amount = state and state.goods[good] or 0
			total += amount
			goodsLabels[good].Text = goods[good] .. " × " .. amount
		end
		local maxGoods = 200
		if state then
			for _, building in state.buildings do
				if building.kind == "storehouse" then
					maxGoods = 400
				end
			end
		end
		capacity.Text = "Collected goods " .. total .. "/" .. maxGoods
		hint.Text = if selected == "hammer"
			then "Destroy Hammer selected · returns owned buildings to inventory"
			else "Slots 2–9 hold building items. Swipe the hotbar for more slots; B opens every item."
		local oldSlots = slotKinds
		slotKinds = {}
		local nextSlot = 2
		for _, kind in kinds do
			local count = state and state.plans[kind] or 0
			local label = if state
				then Presentation.buildingName(state.civilizationId, kind)
				else Catalog.buildings[kind].name
			local button = planButtons[kind]
			button.Text = label .. " × " .. count
			Theme.enabled(button, count > 0 and callbacks.guard("place") == nil)
			if count > 0 and nextSlot <= 9 then
				slotKinds[nextSlot] = kind
				nextSlot += 1
			end
		end
		for index, button in slots do
			local kind = if index == 1 then "hammer" else slotKinds[index]
			button:SetAttribute("ItemKind", kind)
			if index == 1 then
				button.Text, button.ItemLabel.Text = "1 · Destroy\nHammer", "Returns to inventory"
			else
				button.Text = ""
				button.ItemLabel.Text = if kind then index .. " · ×" .. state.plans[kind] else index .. " · Empty"
				if
					oldSlots[index] ~= kind
					or button:GetAttribute("PreviewCivilization") ~= civilizationId
					or (kind and not button:FindFirstChild("ItemPreview"))
				then
					thumbnail(button, kind, civilizationId)
					button:SetAttribute("PreviewCivilization", civilizationId)
				end
			end
			Theme.enabled(button, kind ~= nil and state ~= nil and view.writable == true)
			if kind and selected == kind then
				button.BackgroundColor3 = Theme.clay
			end
		end
	end
	local function resize()
		local width, height = screen.AbsoluteSize.X, screen.AbsoluteSize.Y
		local barWidth = math.min(616, width - 32)
		hotbar.Position, hotbar.Size =
			UDim2.fromOffset((width - barWidth) / 2, height - 72), UDim2.fromOffset(barWidth, 64)
		toggle.Position, toggle.Size = UDim2.fromOffset(width - 96, height - 124), UDim2.fromOffset(80, 44)
		local panelWidth = math.min(480, width - 32)
		panel.Position, panel.Size =
			UDim2.fromOffset(width - panelWidth - 16, 64), UDim2.fromOffset(panelWidth, math.max(112, height - 204))
	end
	function controller.update(nextView, changed)
		view = nextView
		civilizationId = view.state and view.state.civilizationId
		if changed then
			controller.clear()
			visibility:setVisible(false)
		elseif selected and selected ~= "hammer" and (not view.state or (view.state.plans[selected] or 0) == 0) then
			controller.clear()
		end
		refresh()
	end
	function controller.hammerSelected()
		return selected == "hammer"
	end
	local connections = {
		screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize),
		Input.InputBegan:Connect(function(input, processed)
			if processed or Input:GetFocusedTextBox() or Gui.MenuIsOpen then
				return
			end
			if input.KeyCode == Enum.KeyCode.B then
				controller.toggle()
			elseif keys[input.KeyCode] then
				local index = keys[input.KeyCode]
				local kind = if index == 1 then "hammer" else slotKinds[index]
				if kind then
					choose(kind)
				end
			end
		end),
	}
	local elapsed = 0
	table.insert(
		connections,
		Run.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed >= 0.2 then
				elapsed = 0
				refresh()
			end
		end)
	)
	screen.Destroying:Connect(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, originalBackpack)
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	resize()
	refresh()
	return controller
end

return Inventory

--!strict
local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("MiniatureGame")
local Military = require(Shared:WaitForChild("MilitaryResearch"))
local Layout = require(Shared:WaitForChild("MilitaryResearchLayout"))
local Theme = require(script.Parent.Theme)
local ResearchTree = {}
local TILE_WIDTH, TILE_HEIGHT = Layout.width, Layout.height
local HIT_SIZE = 60
local completedColor = Color3.fromRGB(91, 112, 68)

local function duration(seconds: number): string
	if seconds < 60 then
		return tostring(seconds) .. "s"
	elseif seconds < 3600 then
		return tostring(seconds / 60) .. " min"
	end
	return tostring(seconds / 3600) .. " hr"
end

local function effectText(effect): string
	if effect.stat == "capacity" then
		return "+" .. effect.value .. " army capacity. Mounted troops use two slots."
	elseif effect.stat == "armySlots" then
		return "+" .. effect.value .. " editable army group. Army 1 always includes all troops."
	end
	local scope = if effect.scope == "mounted" then "Mounted troop" else "Foot troop"
	local stat = if effect.stat == "health"
		then "maximum health"
		elseif effect.stat == "range" then "reach"
		else effect.stat
	local text = scope .. " " .. stat .. " +" .. math.round(effect.value * 100) .. "%. Tiers add together."
	if effect.stat == "health" then
		text ..= " Does not heal living troops."
	elseif effect.stat == "range" and effect.scope == "foot" then
		text ..= " Applies to melee, ranged and healing reach."
	end
	return text
end

function ResearchTree.reason(view, id: string): string?
	local entry = Military.nodes[id]
	local progress = view and view.state and view.state.militaryResearch
	if not entry or not progress then
		return "Research is unavailable"
	end
	if progress.completed[id] then
		return "Completed"
	end
	if progress.project then
		return if progress.project.id == id then "Researching" else "Another project is active"
	end
	if entry.predecessor and not progress.completed[entry.predecessor] then
		return "Requires " .. Military.nodes[entry.predecessor].name
	end
	if view.state.coins < entry.price then
		return "Requires " .. entry.price .. " coins"
	end
	return nil
end

local function line(parent: Instance, name: string, first: Vector2, second: Vector2, color: Color3, thickness: number)
	local delta = second - first
	local edge = Theme.frame(parent, name, thickness)
	edge.AnchorPoint, edge.Position =
		Vector2.new(0.5, 0.5), UDim2.fromOffset((first.X + second.X) / 2, (first.Y + second.Y) / 2)
	edge.Size, edge.Rotation = UDim2.fromOffset(delta.Magnitude, thickness), math.deg(math.atan2(delta.Y, delta.X))
	edge.BackgroundColor3 = color
	return edge
end

local function hexagon(parent: Instance, name: string, position: Vector2, color: Color3)
	local hex = Theme.frame(parent, name, TILE_HEIGHT)
	hex.BackgroundTransparency, hex.Size = 1, UDim2.fromOffset(TILE_WIDTH, TILE_HEIGHT)
	hex.Position = UDim2.fromOffset(position.X - TILE_WIDTH / 2, position.Y - TILE_HEIGHT / 2)
	local fills = {}
	-- Three inscribed rectangles paint the same pointy-top regular hexagon.
	for index, rotation in { 0, 60, -60 } do
		local fill = Theme.frame(hex, "Fill" .. index, TILE_HEIGHT)
		fill.AnchorPoint, fill.Position, fill.Size =
			Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(TILE_WIDTH, TILE_HEIGHT / 2)
		fill.Rotation, fill.BackgroundColor3 = rotation, color
		table.insert(fills, fill)
	end
	local corners = {}
	for _, corner in Layout.vertices() do
		table.insert(corners, Vector2.new(corner.x, corner.y))
	end
	local edges = {}
	for index, corner in corners do
		table.insert(edges, line(hex, "Edge" .. index, corner, corners[index % 6 + 1], Theme.muted, 1))
	end
	return hex, fills, edges
end

function ResearchTree.render(ctx)
	local body, drafts = ctx.body, ctx.drafts
	body.AutomaticCanvasSize, body.CanvasSize, body.ScrollingEnabled = Enum.AutomaticSize.None, UDim2.new(), false
	drafts.militaryNode = if Military.nodes[drafts.militaryNode] then drafts.militaryNode else Military.order[1]
	drafts.militaryZoom = drafts.militaryZoom or 1
	local layoutChanged = drafts.militaryLayout ~= Layout.id
	if layoutChanged then
		-- Pan belongs to this presentation, never the profile or research rules.
		drafts.militaryPan, drafts.militaryLayout = nil, Layout.id
	end
	local savedPan = drafts.militaryPan
	local root = Theme.frame(body, "MilitaryResearchTree", 300)
	root.Size, root.BackgroundTransparency = UDim2.new(1, -16, 1, -16), 1
	root:SetAttribute("LayoutId", Layout.id)
	ctx.order(root)
	local project = Theme.label(root, "ActiveProject", "", 24)
	project.TextSize, project.TextColor3 = 12, Theme.gold
	local controls = Theme.frame(root, "TreeControls", 44)
	controls.BackgroundTransparency, controls.Position = 1, UDim2.fromOffset(0, 28)
	local graph = Instance.new("ScrollingFrame")
	graph.Name, graph.BackgroundColor3, graph.BorderSizePixel = "ResearchGraph", Theme.stone, 0
	graph.ScrollBarThickness, graph.ScrollingDirection, graph.ClipsDescendants = 6, Enum.ScrollingDirection.XY, true
	graph.Active, graph.Parent = true, root
	local canvas = Theme.frame(graph, "HexCanvas", 1)
	canvas.BackgroundTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Scale, scale.Parent = drafts.militaryZoom, canvas
	local details = Theme.frame(root, "SelectedNode", 140)
	local detailScroll = Instance.new("ScrollingFrame")
	detailScroll.Name, detailScroll.BackgroundTransparency, detailScroll.BorderSizePixel = "DetailsScroll", 1, 0
	detailScroll.Size, detailScroll.ScrollBarThickness = UDim2.new(1, 0, 1, -48), 4
	detailScroll.AutomaticCanvasSize, detailScroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	detailScroll.Parent = details
	Theme.list(detailScroll, 2)
	local name = Theme.label(detailScroll, "ResearchName", "", 32)
	name.Font, name.TextColor3 = Enum.Font.GothamBold, Theme.gold
	local cost = Theme.label(detailScroll, "ResearchCostTime", "", 28)
	cost.TextSize = 12
	local effect = Theme.label(detailScroll, "ResearchEffect", "", 64)
	effect.TextSize = 12
	local prerequisite = Theme.label(detailScroll, "ResearchPrerequisite", "", 40)
	prerequisite.TextSize = 12
	local reason = Theme.label(detailScroll, "ResearchReason", "", 40)
	reason.TextSize = 12
	for index, label in { name, cost, effect, prerequisite, reason } do
		label.LayoutOrder = index
	end
	local start = Theme.button(details, "StartMilitaryResearch", "Research", function()
		local blocked = ctx.guard("militaryResearch") or ResearchTree.reason(ctx.view(), drafts.militaryNode)
		if blocked then
			ctx.message(blocked)
		else
			ctx.send("militaryResearch", { id = drafts.militaryNode })
		end
	end)
	start.Position, start.Size = UDim2.new(0, 4, 1, -44), UDim2.new(1, -8, 0, 44)
	local bounds = Layout.bounds()
	local function point(cell): Vector2
		local position = Layout.point(cell.q, cell.r)
		return Vector2.new(bounds.offsetX + position.x, bounds.offsetY + position.y)
	end
	local canvasWidth, canvasHeight = bounds.width, bounds.height
	canvas.Size = UDim2.fromOffset(canvasWidth, canvasHeight)
	local function setPan(position: Vector2)
		graph.CanvasPosition = Vector2.new(
			math.clamp(position.X, 0, math.max(0, graph.AbsoluteCanvasSize.X - graph.AbsoluteWindowSize.X)),
			math.clamp(position.Y, 0, math.max(0, graph.AbsoluteCanvasSize.Y - graph.AbsoluteWindowSize.Y))
		)
		drafts.militaryPan = graph.CanvasPosition
	end
	local function focusSelected()
		setPan(point(Layout.nodes[drafts.militaryNode]) * drafts.militaryZoom - graph.AbsoluteWindowSize / 2)
	end
	local function zoom(amount: number)
		local previous = drafts.militaryZoom
		drafts.militaryZoom = math.clamp(previous + amount, 0.75, 1.5)
		local center = (graph.CanvasPosition + graph.AbsoluteWindowSize / 2) / previous
		scale.Scale = drafts.militaryZoom
		graph.CanvasSize = UDim2.fromOffset(canvasWidth * drafts.militaryZoom, canvasHeight * drafts.militaryZoom)
		setPan(center * drafts.militaryZoom - graph.AbsoluteWindowSize / 2)
		root:SetAttribute("Zoom", drafts.militaryZoom)
	end
	local buttons = {}
	for _, item in
		{
			{
				"PanLeft",
				"←",
				function()
					setPan(graph.CanvasPosition - Vector2.new(120, 0))
				end,
			},
			{
				"ZoomOut",
				"−",
				function()
					zoom(-0.15)
				end,
			},
			{ "FocusSelected", "◎", focusSelected },
			{
				"ZoomIn",
				"+",
				function()
					zoom(0.15)
				end,
			},
			{
				"PanRight",
				"→",
				function()
					setPan(graph.CanvasPosition + Vector2.new(120, 0))
				end,
			},
		}
	do
		local button = Theme.button(controls, item[1], item[2], item[3])
		button.Size = UDim2.fromOffset(44, 44)
		table.insert(buttons, button)
	end
	local futureColor = Color3.fromRGB(62, 64, 61)
	for index, cell in Layout.civilian do
		local hex = hexagon(canvas, "FutureNode" .. index, point(cell), futureColor)
		hex:SetAttribute("FutureResearch", true)
		hex:SetAttribute("FutureFamily", "Civilian")
		local label = Theme.label(hex, "Placeholder", "?", TILE_HEIGHT)
		label.TextSize, label.TextXAlignment, label.TextColor3 = 24, Enum.TextXAlignment.Center, Theme.muted
	end
	local futureTitle = Theme.label(canvas, "CivilianFuture", "CIVILIAN · FUTURE", 28)
	local futureTitleX = point(Layout.nodes.army_training).X + TILE_WIDTH / 2
	futureTitle.Position, futureTitle.Size =
		UDim2.fromOffset(futureTitleX, 0), UDim2.fromOffset(math.max(0, canvasWidth - futureTitleX - 8), 28)
	futureTitle.TextColor3 = Theme.muted
	local nodes = {}
	local pointerGestureMoved = false
	for index, cell in Layout.reservedMilitary do
		local hex = hexagon(canvas, "ReservedNode" .. index, point(cell), futureColor)
		hex:SetAttribute("FutureResearch", true)
		hex:SetAttribute("FutureFamily", "ReservedMilitary")
		local label = Theme.label(hex, "Placeholder", "?", TILE_HEIGHT)
		label.TextSize, label.TextXAlignment, label.TextColor3 = 24, Enum.TextXAlignment.Center, Theme.muted
	end
	local function selectNode(id: string)
		drafts.militaryNode = id
		detailScroll.CanvasPosition = Vector2.zero
	end
	for _, id in Military.order do
		local entry = Military.nodes[id]
		local cell = Layout.nodes[id]
		local hex, fills, edges = hexagon(canvas, "Hex_" .. id, point(cell), Theme.wood)
		hex:SetAttribute("HexQ", cell.q)
		hex:SetAttribute("HexR", cell.r)
		local button = Theme.button(hex, "Node_" .. id, entry.name, function(input)
			local pointer = input
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			if not pointer or not pointerGestureMoved then
				selectNode(id)
			end
		end)
		-- An inscribed center cannot steal a diagonal neighbor's corner.
		button.AnchorPoint, button.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
		button.Size, button.BackgroundTransparency, button.TextSize = UDim2.fromOffset(HIT_SIZE, HIT_SIZE), 1, 11
		button:SetAttribute("ResearchId", id)
		nodes[id] = { button = button, fills = fills, edges = edges }
	end
	local function resize()
		local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
		local compact = height < 240
		project.Visible = not compact
		controls.Position = UDim2.fromOffset(0, if compact then 0 else 28)
		local contentY = if compact then 50 else 78
		local contentHeight = math.max(126, height - contentY)
		for index, button in buttons do
			button.Position = UDim2.fromOffset((width - 236) / 2 + (index - 1) * 48, 0)
		end
		if width >= 580 then
			graph.Position, graph.Size = UDim2.fromOffset(0, contentY), UDim2.new(1, -246, 0, contentHeight)
			details.Position, details.Size = UDim2.new(1, -240, 0, contentY), UDim2.fromOffset(240, contentHeight)
		else
			local graphHeight = math.max(72, math.floor((contentHeight - 6) * 0.48))
			graph.Position, graph.Size = UDim2.fromOffset(0, contentY), UDim2.fromOffset(width, graphHeight)
			details.Position, details.Size =
				UDim2.fromOffset(0, contentY + graphHeight + 6),
				UDim2.fromOffset(width, contentHeight - graphHeight - 6)
		end
	end
	local connections = {}
	local dragging, dragPosition, dragCanvas = false, Vector2.zero, Vector2.zero
	local pressedInput: InputObject? = nil
	local screen = graph:FindFirstAncestorWhichIsA("ScreenGui")
	local playerGui = graph:FindFirstAncestorWhichIsA("PlayerGui")
	local function visible(): boolean
		local ancestor = root
		while ancestor do
			if ancestor:IsA("GuiObject") and not ancestor.Visible then
				return false
			end
			if ancestor:IsA("ScreenGui") and not ancestor.Enabled then
				return false
			end
			ancestor = ancestor.Parent
		end
		return root.Parent ~= nil
	end
	local function graphOnTop(position: Vector3): boolean
		if not playerGui then
			return false
		end
		-- InputObject.Position already accounts for the GUI inset, as does
		-- BasePlayerGui's hit-query coordinate space. Do not subtract it again.
		local location = Vector2.new(position.X, position.Y)
		for _, object in playerGui:GetGuiObjectsAtPosition(location.X, location.Y) do
			if object == graph or object:IsDescendantOf(graph) then
				return true
			elseif not graph:IsDescendantOf(object) then
				return false
			end
		end
		return false
	end
	local function graphPoint(position: Vector3): Vector2?
		local inset = if screen and screen.IgnoreGuiInset then Gui:GetGuiInset() else Vector2.zero
		local screenPoint = Vector2.new(position.X, position.Y) + inset
		local ancestor = graph.Parent
		while ancestor do
			if ancestor:IsA("GuiObject") and ancestor.ClipsDescendants then
				local relative = screenPoint - ancestor.AbsolutePosition
				if
					relative.X < 0
					or relative.Y < 0
					or relative.X > ancestor.AbsoluteSize.X
					or relative.Y > ancestor.AbsoluteSize.Y
				then
					return nil
				end
			end
			ancestor = ancestor.Parent
		end
		local localPoint = screenPoint - graph.AbsolutePosition
		if
			localPoint.X < 0
			or localPoint.Y < 0
			or localPoint.X > graph.AbsoluteWindowSize.X
			or localPoint.Y > graph.AbsoluteWindowSize.Y
		then
			return nil
		end
		return (localPoint + graph.CanvasPosition) / drafts.militaryZoom
	end
	local function selectPolygon(position: Vector3)
		local localPoint = graphPoint(position)
		if not localPoint then
			return
		end
		for _, id in Military.order do
			local difference = localPoint - point(Layout.nodes[id])
			local x, y = math.abs(difference.X), math.abs(difference.Y)
			if
				x <= TILE_WIDTH / 2
				and y <= TILE_HEIGHT / 2
				and x + math.sqrt(3) * y <= math.sqrt(3) * TILE_HEIGHT / 2
			then
				selectNode(id)
				return
			end
		end
	end
	table.insert(
		connections,
		Input.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
				and visible()
				and not Input:GetFocusedTextBox()
				and not Gui.MenuIsOpen
				and graphPoint(input.Position)
				and graphOnTop(input.Position)
			then
				pressedInput = input
				pointerGestureMoved = false
				dragging, dragPosition, dragCanvas =
					input.UserInputType == Enum.UserInputType.MouseButton1,
					Vector2.new(input.Position.X, input.Position.Y),
					graph.CanvasPosition
			end
		end)
	)
	table.insert(
		connections,
		Input.InputChanged:Connect(function(input)
			if
				pressedInput
				and ((dragging and input.UserInputType == Enum.UserInputType.MouseMovement) or input == pressedInput)
				and visible()
			then
				local difference = Vector2.new(input.Position.X, input.Position.Y) - dragPosition
				if difference.Magnitude > 4 then
					pointerGestureMoved = true
					if dragging then
						setPan(dragCanvas - difference)
					end
				end
			end
		end)
	)
	table.insert(
		connections,
		Input.InputEnded:Connect(function(input)
			if input == pressedInput then
				local difference = Vector2.new(input.Position.X, input.Position.Y) - dragPosition
				if
					visible()
					and not Gui.MenuIsOpen
					and not Input:GetFocusedTextBox()
					and not pointerGestureMoved
					and graphOnTop(input.Position)
					and difference.Magnitude <= 4
					and (graph.CanvasPosition - dragCanvas).Magnitude <= 4
				then
					selectPolygon(input.Position)
				end
				pressedInput = nil
				dragging = false
			end
		end)
	)
	table.insert(
		connections,
		graph:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			drafts.militaryPan = graph.CanvasPosition
			if pressedInput and (graph.CanvasPosition - dragCanvas).Magnitude > 4 then
				pointerGestureMoved = true
			end
		end)
	)
	table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	root.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	ctx.track(function()
		local view = ctx.view()
		local progress = view and view.state and view.state.militaryResearch
		if not progress then
			Theme.enabled(start, false)
			return
		end
		local selected = Military.nodes[drafts.militaryNode]
		root:SetAttribute("SelectedResearch", selected.id)
		local active = progress.project
		name.Text = selected.name
			.. (
				if root.AbsoluteSize.Y < 240 and active
					then "\n" .. Military.nodes[active.id].name .. " · " .. math.ceil(active.remaining) .. "s"
					else ""
			)
		cost.Text = selected.price .. " coins · " .. duration(selected.duration) .. " active time"
		effect.Text = effectText(selected.effect)
		prerequisite.Text = "Requires: "
			.. (if selected.predecessor then Military.nodes[selected.predecessor].name else "none")
		local blocked = ctx.guard("militaryResearch") or ResearchTree.reason(view, selected.id)
		reason.Text = blocked or "Ready to research"
		Theme.enabled(start, blocked == nil)
		start.Text = if progress.completed[selected.id]
			then "Completed"
			elseif progress.project and progress.project.id == selected.id then "Researching…"
			else "Research"
		project.Text = if active
			then Military.nodes[active.id].name .. " · " .. math.ceil(active.remaining) .. "s remaining"
			else "MILITARY RESEARCH · One project at a time"
		for id, node in nodes do
			local state = if progress.completed[id]
				then "Completed"
				elseif active and active.id == id then "Researching"
				elseif ResearchTree.reason(view, id) then "Locked"
				else "Available"
			node.button:SetAttribute("ResearchStatus", state)
			node.button.TextColor3 = if state == "Locked" then Theme.muted else Theme.ink
			for _, fill in node.fills do
				fill.BackgroundColor3 = if state == "Completed"
					then completedColor
					elseif state == "Researching" then Theme.clay
					else Theme.wood
			end
			for _, edge in node.edges do
				edge.BackgroundColor3 = if id == selected.id
					then Theme.gold
					elseif state == "Available" then Theme.ink
					else Theme.muted
			end
		end
	end)
	zoom(0)
	resize()
	task.spawn(function()
		Run.Heartbeat:Wait()
		if graph.Parent then
			if layoutChanged then
				setPan(point(Layout.nodes.army_training) * drafts.militaryZoom - graph.AbsoluteWindowSize / 2)
			elseif savedPan then
				setPan(savedPan)
			else
				focusSelected()
			end
		end
	end)
end

return ResearchTree

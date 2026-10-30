--!strict
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("MiniatureGame")
local Military = require(Shared:WaitForChild("MilitaryResearch"))
local Theme = require(script.Parent.Theme)
local ResearchTree = {}
local TILE_WIDTH, TILE_HEIGHT = 80, 80 * math.sqrt(3) / 2
local STEP_X, STEP_Y = 104, 90
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
	-- Each rectangle spans four corners of the same regular hexagon.
	for index, rotation in { 0, 60, -60 } do
		local fill = Theme.frame(hex, "Fill" .. index, TILE_HEIGHT)
		fill.AnchorPoint, fill.Position, fill.Size =
			Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(TILE_WIDTH / 2, TILE_HEIGHT)
		fill.Rotation, fill.BackgroundColor3 = rotation, color
		table.insert(fills, fill)
	end
	local corners = {}
	for index = 0, 5 do
		local radians = math.rad(index * 60)
		table.insert(
			corners,
			Vector2.new(
				TILE_WIDTH / 2 + math.cos(radians) * TILE_WIDTH / 2,
				TILE_HEIGHT / 2 + math.sin(radians) * TILE_HEIGHT / math.sqrt(3)
			)
		)
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
	local savedPan = drafts.militaryPan
	local root = Theme.frame(body, "MilitaryResearchTree", 300)
	root.Size, root.BackgroundTransparency = UDim2.new(1, -16, 1, -16), 1
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
	local minX, minY, maxX, maxY = 0, 0, 0, 0
	for _, id in Military.order do
		local node = Military.nodes[id]
		minX, minY, maxX, maxY =
			math.min(minX, node.x), math.min(minY, node.y), math.max(maxX, node.x), math.max(maxY, node.y)
	end
	maxX, maxY = math.max(maxX, 10), math.max(maxY, 8)
	-- The civilian half is visible context; it has no selectable or purchase surface.
	local offsetX, offsetY = (8 - minX) * STEP_X, (1 - minY) * STEP_Y
	local function point(x: number, y: number): Vector2
		return Vector2.new(offsetX + x * STEP_X, offsetY + y * STEP_Y)
	end
	local canvasWidth, canvasHeight = (maxX - minX + 10) * STEP_X, (maxY - minY + 2) * STEP_Y
	canvas.Size = UDim2.fromOffset(canvasWidth, canvasHeight)
	local function setPan(position: Vector2)
		graph.CanvasPosition = Vector2.new(
			math.clamp(position.X, 0, math.max(0, graph.AbsoluteCanvasSize.X - graph.AbsoluteWindowSize.X)),
			math.clamp(position.Y, 0, math.max(0, graph.AbsoluteCanvasSize.Y - graph.AbsoluteWindowSize.Y))
		)
		drafts.militaryPan = graph.CanvasPosition
	end
	local function focusSelected()
		local node = Military.nodes[drafts.militaryNode]
		setPan(point(node.x, node.y) * drafts.militaryZoom - graph.AbsoluteWindowSize / 2)
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
	local futurePoints = {}
	for index, coordinates in
		{
			{ -6, 0 },
			{ -5, -1 },
			{ -5, 1 },
			{ -4, -2 },
			{ -4, 0 },
			{ -4, 2 },
			{ -3, -3 },
			{ -3, -1 },
			{ -3, 1 },
			{ -3, 3 },
		}
	do
		local position = point(minX + coordinates[1], coordinates[2])
		table.insert(futurePoints, position)
		if index > 1 then
			line(
				canvas,
				"FutureConnection" .. index,
				futurePoints[math.max(1, math.floor(index / 2))],
				position,
				futureColor,
				2
			)
		end
		local hex = hexagon(canvas, "FutureNode" .. index, position, futureColor)
		hex:SetAttribute("FutureResearch", true)
		hex:SetAttribute("FutureFamily", "Civilian")
		local label = Theme.label(hex, "Placeholder", "?", TILE_HEIGHT)
		label.TextSize, label.TextXAlignment, label.TextColor3 = 24, Enum.TextXAlignment.Center, Theme.muted
	end
	local futureTitle = Theme.label(canvas, "CivilianFuture", "CIVILIAN · FUTURE", 28)
	futureTitle.Position, futureTitle.Size = UDim2.fromOffset(32, 8), UDim2.fromOffset(400, 28)
	futureTitle.TextColor3 = Theme.muted
	local nodes = {}
	local lastDrag = 0
	local futureBranches = {
		{ parent = "elite_training", coordinates = { { 6, 0 }, { 8, 0 }, { 10, 0 } } },
		{ parent = "army_size_3", coordinates = { { 2, -6 }, { 4, -6 } } },
		{ parent = "rider_conditioning", coordinates = { { 4, 8 }, { 6, 8 } } },
	}
	local futureIndex = 0
	for _, branch in futureBranches do
		local prior = Military.nodes[branch.parent]
		local previous = point(prior.x, prior.y)
		for _, coordinates in branch.coordinates do
			futureIndex += 1
			local position = point(coordinates[1], coordinates[2])
			line(canvas, "ReservedConnection" .. futureIndex, previous, position, futureColor, 2)
			local hex = hexagon(canvas, "ReservedNode" .. futureIndex, position, futureColor)
			hex:SetAttribute("FutureResearch", true)
			hex:SetAttribute("FutureFamily", "ReservedMilitary")
			local label = Theme.label(hex, "Placeholder", "?", TILE_HEIGHT)
			label.TextSize, label.TextXAlignment, label.TextColor3 = 24, Enum.TextXAlignment.Center, Theme.muted
			previous = position
		end
	end
	for _, id in Military.order do
		local entry = Military.nodes[id]
		if entry.predecessor then
			local prior = Military.nodes[entry.predecessor]
			line(canvas, "Connection_" .. id, point(prior.x, prior.y), point(entry.x, entry.y), Theme.muted, 2)
		end
	end
	for _, id in Military.order do
		local entry = Military.nodes[id]
		local hex, fills, edges = hexagon(canvas, "Hex_" .. id, point(entry.x, entry.y), Theme.wood)
		local button = Theme.button(hex, "Node_" .. id, entry.name, function()
			if os.clock() - lastDrag > 0.1 then
				drafts.militaryNode = id
				detailScroll.CanvasPosition = Vector2.zero
			end
		end)
		button.Size, button.BackgroundTransparency, button.TextSize = UDim2.fromScale(1, 1), 1, 11
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
	local function visible(): boolean
		local ancestor = root
		while ancestor do
			if ancestor:IsA("GuiObject") and not ancestor.Visible then
				return false
			end
			ancestor = ancestor.Parent
		end
		return root.Parent ~= nil
	end
	table.insert(
		connections,
		graph.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and visible() then
				dragging, dragPosition, dragCanvas =
					true, Vector2.new(input.Position.X, input.Position.Y), graph.CanvasPosition
			end
		end)
	)
	table.insert(
		connections,
		Input.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and visible() then
				local difference = Vector2.new(input.Position.X, input.Position.Y) - dragPosition
				if difference.Magnitude > 4 then
					lastDrag = os.clock()
					setPan(dragCanvas - difference)
				end
			end
		end)
	)
	table.insert(
		connections,
		Input.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	)
	table.insert(
		connections,
		graph:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			drafts.militaryPan = graph.CanvasPosition
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
			if savedPan then
				setPan(savedPan)
			else
				focusSelected()
			end
		end
	end)
end

return ResearchTree

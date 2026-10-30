--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("MiniatureGame")
local Catalog = require(Shared.Catalog)
local Theme = require(script.Parent.Theme)
local Research = {}
local branches = {
	Economy = { "work", "craft", "store" },
	Army = { "muster", "drill", "supply" },
	Civic = { "records", "porters", "trade" },
}
local effects = {
	work = "Raw-goods production intervals are 10% shorter. The sandbox production-speed multiplier applies separately; pottery keeps its ordinary base interval.",
	craft = "Unlock a paid Potter's Workshop plan at the next restock. Each civilian converts one clay into one pottery per 1.5s at the current test speed (15s base).",
	store = "Unlock a paid Storehouse plan at the next restock. Place it to raise combined collected-goods capacity from 200 to 400.",
	muster = "Unlock a paid Training Yard plan at the next restock. Place it for two display fighters, shared between melee and ranged.",
	drill = "Raise a placed Training Yard's shared melee/ranged display capacity from two to four fighters.",
	supply = "Unlock a paid Healer Shelter plan at the next restock. Place it for one display medic; no healing in this sandbox.",
	records = "Establish settlement records; prerequisite for Porter Service. Civilians are assigned automatically.",
	porters = "Enable optional automatic collection into available inventory capacity. Direct E collection stays available.",
	trade = "Enable optional automatic sales while protecting the next workshop-input batch. Sell all goods remains available at the shared shop.",
}
local function complete(view, id)
	return view.state.research.completed[id] == true
end
local function cost(entry)
	return tostring(entry.price) .. " coins"
end
function Research.reason(view, id)
	local entry, state = Catalog.research[id], view.state
	if complete(view, id) then
		return "Completed"
	end
	if state.research.project then
		return if state.research.project.id == id then "Researching" else "Another project is active"
	end
	if not state.hallUpgraded then
		return "Improve the council first: 160 coins"
	end
	if entry.predecessor and not complete(view, entry.predecessor) then
		return "Requires " .. Catalog.research[entry.predecessor].name
	end
	if state.coins < entry.price then
		return "Insufficient coins"
	end
	return nil
end
function Research.status(view, id)
	if complete(view, id) then
		return "Completed"
	end
	if view.state.research.project and view.state.research.project.id == id then
		return "Researching"
	end
	return if Research.reason(view, id) then "Locked" else "Available"
end
function Research.details(id)
	local entry = Catalog.research[id]
	return entry.name
		.. "\n"
		.. cost(entry)
		.. " · "
		.. entry.duration
		.. " active seconds\nPrerequisite: improved council"
		.. (if entry.predecessor then " + " .. Catalog.research[entry.predecessor].name else "")
		.. "\n"
		.. effects[id]
end
function Research.render(ctx)
	local drafts = ctx.drafts
	local activeBranch = drafts.branch
	drafts.researchByBranch = drafts.researchByBranch or { Economy = "work", Army = "muster", Civic = "records" }
	drafts.researchPan = drafts.researchPan or {}
	drafts.researchByBranch[drafts.branch] = drafts.research
	ctx.body:SetAttribute("SelectedResearch", drafts.research)
	ctx.body:SetAttribute("ResearchGraphMode", drafts.graph)
	ctx.dynamic("ResearchProject", function(view)
		local project = view.state.research.project
		return if project
			then Catalog.research[project.id].name .. " · " .. math.ceil(project.remaining) .. "s remaining"
			else "No active research · One project at a time"
	end, 48)
	ctx.label(
		"ResearchGuide",
		"Follow each branch's arrows. Select a node for its prerequisites, cost, duration and exact effects.",
		56
	)
	for _, branch in { "Economy", "Army", "Civic" } do
		ctx.button("Branch_" .. branch, (if drafts.branch == branch then "✓ " else "") .. branch, function()
			drafts.branch, drafts.research = branch, drafts.researchByBranch[branch]
			ctx.rebuild()
		end)
	end
	ctx.button("ResearchView", if drafts.graph then "Use text list" else "Use connected tree", function()
		drafts.graph = not drafts.graph
		ctx.rebuild()
	end)
	local function selectNode(id)
		drafts.research, drafts.researchByBranch[drafts.branch] = id, id
		ctx.rebuild()
	end
	if drafts.graph then
		local graph = Instance.new("ScrollingFrame")
		graph.Name, graph.Size = "ResearchGraph", UDim2.new(1, 0, 0, 152)
		graph.CanvasSize = UDim2.fromOffset(600 * drafts.zoom, 136 * drafts.zoom)
		graph.BackgroundColor3, graph.BorderSizePixel, graph.ScrollBarThickness = Theme.stone, 0, 8
		graph.ScrollingDirection, graph.ClipsDescendants, graph.Parent = Enum.ScrollingDirection.XY, true, ctx.body
		ctx.order(graph)
		local canvas = Theme.frame(graph, "Tree", 136)
		canvas.Size = UDim2.fromOffset(600, 136)
		local scale = Instance.new("UIScale")
		scale.Scale, scale.Parent = drafts.zoom, canvas
		local function pan(position)
			local maxX = math.max(0, graph.AbsoluteCanvasSize.X - graph.AbsoluteWindowSize.X)
			local maxY = math.max(0, graph.AbsoluteCanvasSize.Y - graph.AbsoluteWindowSize.Y)
			graph.CanvasPosition = Vector2.new(math.clamp(position.X, 0, maxX), math.clamp(position.Y, 0, maxY))
			drafts.researchPan[activeBranch] = graph.CanvasPosition
		end
		local stored, ready = drafts.researchPan[activeBranch] or Vector2.zero, false
		graph:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if ready then
				drafts.researchPan[activeBranch] = graph.CanvasPosition
			end
		end)
		task.defer(function()
			if graph.Parent then
				ready = true
				pan(stored)
			end
		end)
		for index, id in branches[drafts.branch] do
			if index > 1 then
				local arrow = Theme.label(canvas, "Connection_" .. id, "→", 44)
				arrow.Position, arrow.Size = UDim2.fromOffset((index - 1) * 200 - 32, 36), UDim2.fromOffset(32, 44)
			end
			local node = Theme.button(canvas, "Node_" .. id, "", function()
				selectNode(id)
			end)
			node.Position, node.Size = UDim2.fromOffset((index - 1) * 200 + 8, 24), UDim2.fromOffset(160, 88)
			node:SetAttribute("ResearchId", id)
			ctx.track(function()
				local view = ctx.view()
				local status = Research.status(view, id)
				node.Text = (if drafts.research == id then "✓ " else "")
					.. Catalog.research[id].name
					.. "\n"
					.. status
				node:SetAttribute("ResearchStatus", status)
				node.BackgroundColor3 = if drafts.research == id then Theme.clay else Theme.wood
			end)
		end
		ctx.label("PanHint", "Pan tree: drag/scroll, or use the arrows", 32)
		local panRow, panSize = Theme.row(ctx.body, "TreePan", 4)
		ctx.order(panRow)
		for _, item in
			{
				{ "PanLeft", "←", Vector2.new(-120, 0) },
				{ "PanRight", "→", Vector2.new(120, 0) },
				{ "PanUp", "↑", Vector2.new(0, -64) },
				{ "PanDown", "↓", Vector2.new(0, 64) },
			}
		do
			local button = Theme.button(panRow, item[1], item[2], function()
				pan(graph.CanvasPosition + item[3])
			end)
			button.Size = panSize
		end
		local row, size = Theme.row(ctx.body, "TreeZoom", 2)
		ctx.order(row)
		for _, item in { { "ZoomOut", "Zoom −", -0.15 }, { "ZoomIn", "Zoom +", 0.15 } } do
			local button = Theme.button(row, item[1], item[2], function()
				drafts.zoom = math.clamp(drafts.zoom + item[3], 0.75, 1.6)
				ctx.rebuild()
			end)
			button.Size = size
		end
	else
		for _, id in branches[drafts.branch] do
			ctx.dynamic("State_" .. id, function(view)
				return Research.status(view, id) .. " · " .. Catalog.research[id].name
			end, 40)
			ctx.label("ListDetails_" .. id, Research.details(id), 216)
			ctx.dynamic("ListReason_" .. id, function(view)
				return Research.reason(view, id) or "All research prerequisites met"
			end, 48)
			ctx.button("ResearchDetails_" .. id, "Select " .. Catalog.research[id].name, function()
				selectNode(id)
			end)
		end
	end
	local id = drafts.research
	ctx.label("ResearchDetails", Research.details(id), 216)
	ctx.dynamic("SelectedResearchState", function(view)
		return Research.status(view, id) .. " · " .. (Research.reason(view, id) or "All research prerequisites met")
	end, 64)
	ctx.action("StartResearch", "Start " .. Catalog.research[id].name, "research", function()
		return { id = id }
	end, function(view)
		return Research.reason(view, id)
	end)
	ctx.label("ConvenienceHeading", "Optional settlement services", 40)
	for _, option in
		{ { "autoCollect", "porters", "Automatic collection" }, { "autoSell", "trade", "Automatic sales" } }
	do
		local setting, research, title = option[1], option[2], option[3]
		ctx.action("Toggle_" .. setting, title, "settings", function()
			return { setting = setting, value = not ctx.view().state.settings[setting] }
		end, function(view)
			return if not complete(view, research) then "Requires " .. Catalog.research[research].name else nil
		end)
		ctx.dynamic("Status_" .. setting, function(view)
			return title .. ": " .. (if view.state.settings[setting] then "On" else "Off")
		end, 32)
	end
end
return Research

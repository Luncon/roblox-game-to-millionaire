--!strict
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Catalog = require(Replicated.MiniatureGame.Catalog)
local Config = require(Replicated.MiniatureGame.Config)
local Presentation = require(Replicated.MiniatureGame.Presentation)
local Panels = require(script.Parent.PanelVisibility)
local Theme = require(script.Parent.Theme)
local ArmyControls = {}
export type View = {
	loaded: boolean?,
	writable: boolean?,
	claim: { civilizationId: string, plotId: number }?,
	state: { buildings: { { id: string, kind: string } }, armyGroups: { [string]: { string } } }?,
	armyControlsUnlocked: boolean?,
	armySlots: number?,
	armyGroups: {
		{
			armyId: number,
			buildingIds: { string },
			count: number,
			alive: number,
			targetId: string?,
			mixedTargets: boolean?,
		}
	}?,
	outposts: { [string]: { position: Vector3 } }?,
}
export type Callbacks = {
	getView: () -> View?,
	send: (string, { [string]: unknown }) -> boolean,
	guard: (string, string?) -> string?,
	message: (string) -> (),
	closePanels: () -> (),
	cancelSelection: () -> (),
}
local function preview(parent: Frame, civilization: string?, kind: string?)
	local key = tostring(civilization) .. ":" .. tostring(kind)
	if parent:GetAttribute("PreviewKey") == key then
		return
	end
	parent:SetAttribute("PreviewKey", key)
	parent:ClearAllChildren()
	local previews = Replicated.MiniatureGame:FindFirstChild("Previews")
	local kit = previews and civilization and previews:FindFirstChild(civilization)
	local source = kit and kind and kit:FindFirstChild(kind)
	if not source or not source:IsA("Model") then
		return
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name, viewport.Size, viewport.BackgroundTransparency = "BuildingPreview", UDim2.fromScale(1, 1), 1
	viewport.Ambient, viewport.LightColor = Color3.fromRGB(190, 180, 155), Color3.fromRGB(255, 238, 203)
	viewport.Parent = parent
	local world, camera = Instance.new("WorldModel"), Instance.new("Camera")
	world.Parent, camera.Parent, viewport.CurrentCamera = viewport, viewport, camera
	local clone = source:Clone()
	for _, object in clone:GetDescendants() do
		if object:IsA("LuaSourceContainer") or object:IsA("ClickDetector") or object:IsA("ProximityPrompt") then
			object:Destroy()
		end
	end
	clone.Parent = world
	local frame, size = clone:GetBoundingBox()
	camera.CFrame = CFrame.lookAt(
		frame.Position + Vector3.new(1, 0.8, 1).Unit * math.max(size.X, size.Y, size.Z) * 1.6,
		frame.Position
	)
end
function ArmyControls.start(screen: ScreenGui, callbacks: Callbacks)
	local player = Players.LocalPlayer
	local view, editing, deployment = nil, nil, nil
	local draft, connections, highlights = {}, {}, {}
	local pendingSave, pendingDeploy = nil, nil
	local stopped = false
	local refresh
	local highlightFolder = Instance.new("Folder")
	highlightFolder.Name, highlightFolder.Parent = "MiniatureArmySelection", Workspace
	local function panel(name, title)
		local frame = Theme.frame(screen, name, 440)
		frame.AnchorPoint, frame.Position, frame.ZIndex = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 112), 40
		frame.BackgroundColor3 = Theme.stone
		local heading = Theme.label(frame, "PanelTitle", title, 44)
		heading.Position, heading.Size, heading.TextColor3 =
			UDim2.fromOffset(12, 0), UDim2.new(1, -116, 0, 44), Theme.gold
		local visibility = Panels.attach(screen, frame, frame, name, title)
		local close = Theme.button(frame, "Close", "×", function()
			visibility:setVisible(false)
		end)
		close.Position, close.Size = UDim2.new(1, -96, 0, 0), UDim2.fromOffset(44, 44)
		local content = Instance.new("ScrollingFrame")
		content.Name, content.Position, content.Size = "Content", UDim2.fromOffset(0, 48), UDim2.new(1, 0, 1, -54)
		content.BackgroundTransparency, content.BorderSizePixel, content.ScrollBarThickness = 1, 0, 5
		content.CanvasSize, content.AutomaticCanvasSize, content.Parent = UDim2.new(), Enum.AutomaticSize.Y, frame
		Theme.list(content, 8)
		return frame, content, visibility
	end
	local panelFrame, content, visibility = panel("ArmyControls", "ARMIES")
	local deployFrame, deployContent, deployVisibility = panel("ArmyDeploy", "DEPLOY ARMY")
	deployFrame.ZIndex = 50
	local cards = Theme.frame(content, "Cards", 240)
	cards.LayoutOrder, cards.BackgroundTransparency = 1, 1
	local deployCards = Theme.frame(deployContent, "Cards", 240)
	deployCards.LayoutOrder, deployCards.BackgroundTransparency = 1, 1
	local grid, deployGrid = Instance.new("UIGridLayout"), Instance.new("UIGridLayout")
	for _, layout in { grid, deployGrid } do
		layout.CellPadding, layout.SortOrder = UDim2.fromOffset(8, 8), Enum.SortOrder.LayoutOrder
	end
	grid.Parent, deployGrid.Parent = cards, deployCards
	local hint = Theme.label(content, "Instructions", "Army 1 always includes all your military buildings.", 44)
	hint.LayoutOrder = 2
	local editor = Theme.frame(content, "Editor", 114)
	editor.LayoutOrder, editor.Visible = 3, false
	local summary = Theme.label(editor, "SelectionSummary", "", 48)
	summary.Position, summary.Size = UDim2.fromOffset(8, 0), UDim2.new(1, -16, 0, 48)
	local save, cancel
	local controls, deployControls = {}, {}
	local function available()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return view ~= nil
			and view.loaded == true
			and view.writable == true
			and view.claim ~= nil
			and view.state ~= nil
			and humanoid ~= nil
			and humanoid.Health > 0
	end
	local function editingActive()
		return editing ~= nil and visibility:isOpen() and not deployVisibility:isOpen()
	end
	local function idsFromDraft()
		local ids = {}
		for id in draft do
			table.insert(ids, id)
		end
		table.sort(ids)
		return ids
	end
	local function clearHighlights()
		for _, object in highlights do
			object:Destroy()
		end
		table.clear(highlights)
	end
	local function updateHighlights()
		clearHighlights()
		if not editingActive() or not available() then
			return
		end
		local scene = Workspace:FindFirstChild("MiniatureSandbox")
		if not scene then
			return
		end
		for _, object in scene:GetDescendants() do
			local id, kind = object:GetAttribute("BuildingId"), object:GetAttribute("Kind")
			local definition = if type(kind) == "string" then Catalog.buildings[kind] else nil
			if
				object:IsA("Model")
				and object:GetAttribute("OwnerId") == player.UserId
				and type(id) == "string"
				and definition
				and definition.category == "Military"
			then
				local highlight = Instance.new("Highlight")
				highlight.Name, highlight.Adornee = "ArmyMembership", object
				highlight.FillColor, highlight.OutlineColor =
					if draft[id] then Theme.gold else Theme.muted, if draft[id] then Theme.gold else Theme.muted
				highlight.FillTransparency, highlight.OutlineTransparency = if draft[id] then 0.6 else 1, 0.1
				highlight.DepthMode, highlight.Parent = Enum.HighlightDepthMode.AlwaysOnTop, highlightFolder
				table.insert(highlights, highlight)
			end
		end
	end
	local function blocked(action, id)
		local reason = callbacks.guard(action, id)
		if reason then
			callbacks.message(reason)
			return true
		end
		return false
	end
	local function beginEdit(armyId)
		if
			not available()
			or not view.armyControlsUnlocked
			or armyId > (view.armySlots or 1)
			or blocked("configureArmy")
		then
			return
		end
		callbacks.cancelSelection()
		editing, draft, pendingSave = armyId, {}, nil
		for _, id in view.state.armyGroups["army" .. armyId] do
			draft[id] = true
		end
		refresh()
	end
	local function reset(armyId)
		if not available() or blocked("configureArmy") then
			return
		end
		if callbacks.send("configureArmy", { armyId = armyId, buildingIds = {} }) then
			callbacks.message("Clearing saved Army " .. armyId .. "; current orders continue")
		end
	end
	local function deployArmy(armyId)
		if not deployment or not available() or blocked("targetOutpost", deployment) then
			return
		end
		if callbacks.send("targetOutpost", { outpostId = deployment, armyId = armyId }) then
			pendingDeploy = armyId
			callbacks.message("Army deployment requested")
		end
	end
	local function card(parent, armyId, isDeployment)
		local frame = Theme.frame(parent, "Army_" .. armyId, 240)
		frame.LayoutOrder = armyId
		local title = Theme.label(frame, "Title", "Army " .. armyId, 26)
		title.Position, title.TextColor3, title.Font = UDim2.fromOffset(8, 4), Theme.gold, Enum.Font.GothamBold
		title.Size = UDim2.new(1, -16, 0, 26)
		local count = Theme.label(frame, "Count", "", 24)
		count.Position, count.TextSize = UDim2.fromOffset(8, 30), 12
		count.Size = UDim2.new(1, -16, 0, 24)
		local imageHolder = Theme.frame(frame, "Preview", 76)
		imageHolder.Position, imageHolder.Size, imageHolder.BackgroundTransparency =
			UDim2.fromOffset(4, 55), UDim2.new(1, -8, 0, 76), 1
		local members = Theme.label(frame, "Members", "", 48)
		members.Position, members.Size, members.TextSize = UDim2.fromOffset(8, 130), UDim2.new(1, -16, 0, 48), 12
		local result = { frame = frame, count = count, members = members, preview = imageHolder }
		if isDeployment then
			local button = Theme.button(frame, "Deploy", "Deploy", function()
				deployArmy(armyId)
			end)
			button.Position, button.Size = UDim2.fromOffset(6, 188), UDim2.new(1, -12, 0, 44)
			result.deploy = button
		elseif armyId > 1 then
			local edit = Theme.button(frame, "Edit", "Edit", function()
				beginEdit(armyId)
			end)
			local erase = Theme.button(frame, "Reset", "Reset", function()
				reset(armyId)
			end)
			edit.Position, edit.Size = UDim2.fromOffset(6, 188), UDim2.new(0.5, -9, 0, 44)
			erase.Position, erase.Size = UDim2.new(0.5, 3, 0, 188), UDim2.new(0.5, -9, 0, 44)
			result.edit, result.reset = edit, erase
		else
			local all = Theme.label(frame, "AllBuildings", "Always all troops", 36)
			all.Position, all.Size, all.TextSize = UDim2.fromOffset(6, 186), UDim2.new(1, -12, 0, 44), 12
		end
		return result
	end
	for armyId = 1, 4 do
		controls[armyId], deployControls[armyId] = card(cards, armyId, false), card(deployCards, armyId, true)
	end
	save = Theme.button(editor, "Save", "Save group", function()
		if not editing or not available() or blocked("configureArmy") then
			return
		end
		if callbacks.send("configureArmy", { armyId = editing, buildingIds = idsFromDraft() }) then
			pendingSave = editing
		end
	end)
	cancel = Theme.button(editor, "Cancel", "Cancel", function()
		editing, draft, pendingSave = nil, {}, nil
		refresh()
	end)
	save.Position, save.Size = UDim2.fromOffset(8, 60), UDim2.new(0.5, -12, 0, 44)
	cancel.Position, cancel.Size = UDim2.new(0.5, 4, 0, 60), UDim2.new(0.5, -12, 0, 44)
	local function layout()
		local size = screen.AbsoluteSize
		local top = if size.Y < 500 then 60 else 112
		local width, height = math.max(180, math.min(860, size.X - 24)), math.max(80, math.min(500, size.Y - top - 82))
		for _, frame in { panelFrame, deployFrame } do
			frame.Position, frame.Size = UDim2.new(0.5, 0, 0, top), UDim2.fromOffset(width, height)
		end
		local columns = if width >= 700 then 4 elseif width >= 300 then 2 else 1
		for _, pair in { { cards, grid }, { deployCards, deployGrid } } do
			pair[1].Size = UDim2.new(1, -16, 0, math.ceil(4 / columns) * 248 - 8)
			pair[2].CellSize = UDim2.new(1 / columns, -8 * (columns - 1) / columns, 0, 240)
		end
	end
	refresh = function()
		screen:SetAttribute("ArmyEditingId", if editingActive() then editing else nil)
		screen:SetAttribute("ArmyDeployOutpostId", if deployVisibility:isOpen() then deployment else nil)
		editor.Visible = editing ~= nil
		summary.Text = if editing
			then "Army "
				.. editing
				.. ": "
				.. #idsFromDraft()
				.. " buildings selected. Click owned military structures; whole building groups join together."
			else ""
		local buildings = {}
		if view and view.state then
			for _, building in view.state.buildings do
				buildings[building.id] = building
			end
		end
		for armyId = 1, 4 do
			local row = view and view.armyGroups and view.armyGroups[armyId]
			local unlocked = available() and view.armyControlsUnlocked and armyId <= (view.armySlots or 1)
			local memberIds = row and row.buildingIds or {}
			local names, first = {}, nil
			local counts = {}
			for _, id in memberIds do
				local building = buildings[id]
				if building then
					counts[building.kind] = (counts[building.kind] or 0) + 1
					first = first or building.kind
				end
			end
			for kind, count in counts do
				table.insert(names, Presentation.buildingName(view.claim.civilizationId, kind) .. " × " .. count)
			end
			table.sort(names)
			for _, info in { controls[armyId], deployControls[armyId] } do
				info.count.Text = if not unlocked
					then "Research another army slot"
					else tostring(row and row.count or 0)
						.. " troops · "
						.. tostring(row and row.alive or 0)
						.. " alive"
				info.members.Text = if not unlocked
					then "Locked"
					elseif #memberIds == 0 then "No military buildings"
					else table.concat(names, "\n")
				preview(info.preview, view and view.claim and view.claim.civilizationId, first)
				if info.edit then
					Theme.enabled(info.edit, unlocked)
					Theme.enabled(info.reset, unlocked)
				end
				if info.deploy then
					Theme.enabled(info.deploy, unlocked and #memberIds > 0)
				end
			end
		end
		layout()
		updateHighlights()
	end
	local controller = {}
	function controller.update(nextView, changed)
		view = nextView
		if changed or not available() or not view.armyControlsUnlocked then
			controller.clear()
			return
		end
		local military = {}
		for _, building in view.state.buildings do
			local definition = Catalog.buildings[building.kind]
			if definition and definition.category == "Military" then
				military[building.id] = true
			end
		end
		for id in draft do
			if not military[id] then
				draft[id] = nil
			end
		end
		if pendingSave and editing == pendingSave then
			local confirmed, requested = view.state.armyGroups["army" .. pendingSave], idsFromDraft()
			local equal = #confirmed == #requested
			local selected = {}
			for _, id in confirmed do
				selected[id] = true
			end
			for _, id in requested do
				equal = equal and selected[id] == true
			end
			if equal then
				editing, draft, pendingSave = nil, {}, nil
			end
		end
		if pendingDeploy then
			local row = view.armyGroups and view.armyGroups[pendingDeploy]
			if row and row.targetId == deployment and not row.mixedTargets then
				deployVisibility:setVisible(false)
				pendingDeploy = nil
			end
		end
		refresh()
	end
	function controller.toggle()
		view = callbacks.getView()
		if not available() or not view.armyControlsUnlocked then
			callbacks.message("Research Army Control to manage groups")
			return
		end
		if visibility:isOpen() then
			visibility:setVisible(false)
		else
			callbacks.cancelSelection()
			callbacks.closePanels()
			deployVisibility:setVisible(false)
			visibility:setVisible(true)
			visibility:restore()
		end
		refresh()
	end
	function controller.deploy(outpostId: string)
		view = callbacks.getView()
		if not available() or blocked("targetOutpost", outpostId) then
			return
		end
		if not view.armyControlsUnlocked then
			callbacks.send("targetOutpost", { outpostId = outpostId })
			return
		end
		callbacks.cancelSelection()
		callbacks.closePanels()
		visibility:setVisible(false)
		deployment, pendingDeploy = outpostId, nil
		deployVisibility:setVisible(true)
		deployVisibility:restore()
		refresh()
	end
	function controller.building(buildingId: string): boolean
		if not editingActive() then
			return false
		end
		if not available() or blocked("configureArmy") then
			return true
		end
		local building
		for _, candidate in view.state.buildings do
			if candidate.id == buildingId then
				building = candidate
				break
			end
		end
		local definition = building and Catalog.buildings[building.kind]
		if not definition or definition.category ~= "Military" then
			callbacks.message("Choose one of your military buildings")
			return true
		end
		for armyId = 2, view.armySlots do
			if armyId ~= editing then
				for _, id in view.state.armyGroups["army" .. armyId] do
					if id == buildingId then
						callbacks.message("That building belongs to Army " .. armyId .. ". Remove it there first.")
						return true
					end
				end
			end
		end
		draft[buildingId] = if draft[buildingId] then nil else true
		refresh()
		return true
	end
	function controller.isEditing(): boolean
		return editingActive()
	end
	function controller.editingArmy(): number?
		return if editingActive() then editing else nil
	end
	function controller.clear()
		editing, deployment, draft, pendingSave, pendingDeploy = nil, nil, {}, nil, nil
		visibility:setVisible(false)
		deployVisibility:setVisible(false)
		refresh()
	end
	local elapsed = 0
	table.insert(
		connections,
		Run.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.25 or stopped then
				return
			end
			elapsed = 0
			if not available() and (visibility:isOpen() or deployVisibility:isOpen()) then
				controller.clear()
				return
			end
			if deployVisibility:isOpen() and deployment then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local post = view and view.outposts and view.outposts[deployment]
				if
					not root
					or not root:IsA("BasePart")
					or not post
					or typeof(post.position) ~= "Vector3"
					or (root.Position - post.position).Magnitude > Config.interactionRange
				then
					deployVisibility:setVisible(false)
					deployment, pendingDeploy = nil, nil
				end
			end
			if editingActive() then
				updateHighlights()
			end
		end)
	)
	table.insert(connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	for _, frame in { panelFrame, deployFrame } do
		table.insert(
			connections,
			frame:GetAttributeChangedSignal("PanelOpen"):Connect(function()
				if refresh then
					refresh()
				end
			end)
		)
	end
	function controller.destroy()
		if stopped then
			return
		end
		stopped = true
		for _, connection in connections do
			connection:Disconnect()
		end
		clearHighlights()
		highlightFolder:Destroy()
		panelFrame:Destroy()
		deployFrame:Destroy()
		screen:SetAttribute("ArmyEditingId", nil)
		screen:SetAttribute("ArmyDeployOutpostId", nil)
	end
	table.insert(connections, screen.Destroying:Connect(controller.destroy))
	refresh()
	return controller
end
return table.freeze(ArmyControls)

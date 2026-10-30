--!strict
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local UI = require(script.Parent.UI)
local Camera = require(script.Parent.Camera)
local InputReadiness = require(script.Parent.InputReadiness)
local OutpostClient = require(script.Parent.OutpostClient)
local TroopRenderer = require(script.Parent.TroopRenderer)
local Placement = require(script.Parent.Placement)
local Inventory = require(script.Parent.Inventory)
local ArmyControls = require(script.Parent.ArmyControls)
local Catalog = require(Replicated.MiniatureGame.Catalog)
local player = Players.LocalPlayer
local screen = Instance.new("ScreenGui")
screen.Name, screen.ResetOnSpawn, screen.ZIndexBehavior = "MiniatureSandboxHUD", false, Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")
InputReadiness.start(screen)
local actions = Replicated:WaitForChild("MiniatureActions", 20)
assert(actions, "Miniature sandbox actions did not start")
local ui, camera, placement, inventory, armyControls
local view, request = nil, nil
local retiredSessions = {}
local generation, counter = Http:GenerateGUID(false):sub(1, 12), 0
local connections = {}
local function send(action, args)
	if request then
		return false
	end
	local blocked = ui.guard(action, if action == "targetOutpost" then args.outpostId else args.buildingId)
	if blocked then
		ui.message(blocked)
		return false
	end
	local remote = actions:FindFirstChild(action)
	if not remote or not remote:IsA("RemoteEvent") then
		ui.message("Action unavailable in this build")
		return false
	end
	counter += 1
	local id = generation .. ":" .. counter
	request = { id = id, action = action, sessionId = view.sessionId, epoch = view.claimEpoch }
	ui.pending(true)
	ui.message("Waiting for settlement confirmation…")
	remote:FireServer({
		requestId = id,
		sessionId = view.sessionId,
		claimEpoch = view.claimEpoch,
		revision = view.revision,
		args = args,
	})
	task.delay(6, function()
		if request and request.id == id then
			request = nil
			ui.pending(false)
			placement.receipt(false)
			ui.message("Confirmation timed out. Refreshing settlement; no automatic retry.")
			actions.Snapshot:FireServer()
		end
	end)
	return true
end
ui = UI.mount(screen, {
	send = send,
	closeInventory = function()
		if inventory then
			inventory.close()
		end
	end,
	closeArmy = function()
		if armyControls then
			armyControls.clear()
		end
	end,
	camera = function(mode)
		if mode == "Walk" then
			camera.walk()
		else
			camera.overview()
		end
	end,
})
camera = Camera.start(screen, function()
	return view and view.plotFrame
end)
local outpostClient = OutpostClient.start(screen, {
	getView = function()
		return view
	end,
	send = send,
	guard = ui.guard,
	message = ui.message,
	deploy = function(id)
		armyControls.deploy(id)
	end,
})
local troopRenderer = TroopRenderer.start(screen)
placement = Placement.start(screen, function()
	return view
end, send, ui.guard)
inventory = Inventory.start(screen, {
	guard = ui.guard,
	closePanels = function()
		ui.closePanels()
		if armyControls then
			armyControls.clear()
		end
	end,
	army = function()
		armyControls.toggle()
	end,
	message = ui.message,
	cancelPlacement = function()
		placement.cancel()
	end,
	place = function(kind)
		placement.begin(kind)
	end,
})
armyControls = ArmyControls.start(screen, {
	getView = function()
		return view
	end,
	send = send,
	guard = ui.guard,
	message = ui.message,
	closePanels = function()
		ui.closePanels()
		inventory.close()
	end,
	cancelSelection = function()
		placement.cancel()
		inventory.clear()
	end,
})
local function contextSame(a, b)
	return a and b and a.sessionId == b.sessionId and a.claimEpoch == b.claimEpoch
end
local function receipt(packet)
	if type(packet) ~= "table" or type(packet.snapshot) ~= "table" then
		return
	end
	local nextView = packet.snapshot
	if retiredSessions[nextView.sessionId] then
		return
	end
	if view and view.sessionId == nextView.sessionId and nextView.claimEpoch < view.claimEpoch then
		return
	end
	local stale = contextSame(view, nextView) and nextView.revision < view.revision
	if view and view.sessionId and view.sessionId ~= nextView.sessionId then
		retiredSessions[view.sessionId] = true
	end
	local changed = not contextSame(view, nextView)
	local completed = request and packet.requestId == request.id
	local action = completed and request.action
	if changed or completed then
		request = nil
		ui.pending(false)
	end
	if not stale then
		view = nextView
	end
	screen:SetAttribute("Revision", view.revision)
	screen:SetAttribute("Writable", view.writable)
	screen:SetAttribute("CivilizationId", view.claim and view.claim.civilizationId)
	ui.update(view, changed)
	inventory.update(view, changed)
	armyControls.update(view, changed)
	if changed then
		placement.cancel()
	end
	if completed then
		local accepted = packet.result and packet.result.ok == true
		ui.message(
			if accepted
				then "Settlement updated."
				else "Request refused: " .. string.gsub(
					packet.result and packet.result.reason or "unknown",
					"_",
					" "
				)
		)
		if action == "place" then
			placement.receipt(accepted)
			if accepted then
				inventory.clear()
			end
		elseif action == "travel" and accepted then
			armyControls.clear()
			placement.cancel()
			inventory.clear()
			inventory.close()
			local destination = packet.result.destination
			if destination == "civilization" then
				ui.closePanels()
				ui.message("Back at your civilization")
			else
				ui.navigate(if destination == "buy" then "Build" else "Trade")
			end
		elseif action == "targetOutpost" and accepted then
			ui.message("Army targeting " .. packet.result.outpostId:gsub("outpost_", "outpost "))
		end
		if accepted then
			ui.refresh()
		end
	end
end
table.insert(connections, actions:WaitForChild("Receipt").OnClientEvent:Connect(receipt))
local bound = setmetatable({}, { __mode = "k" })
local ownedPrompts = setmetatable({}, { __mode = "k" })
local function updatePromptLabels()
	for prompt, original in ownedPrompts do
		if prompt.Parent and original.model:GetAttribute("OwnerId") == player.UserId then
			local editing = armyControls.isEditing()
			local kind = original.model:GetAttribute("Kind")
			local military = kind == "training" or kind == "ranged" or kind == "healer" or kind == "mount"
			prompt.ActionText = if editing and military
				then "Toggle army assignment"
				elseif inventory.hammerSelected() then "Return to inventory"
				else original.actionText
			prompt.Enabled = if editing
				then military
				else if original.reclaimOnly then inventory.hammerSelected() else original.enabled
		end
	end
end
table.insert(connections, screen:GetAttributeChangedSignal("HammerSelected"):Connect(updatePromptLabels))
table.insert(connections, screen:GetAttributeChangedSignal("ArmyEditingId"):Connect(updatePromptLabels))
local function bind(instance)
	if bound[instance] then
		return
	end
	if not instance:IsA("ClickDetector") and not instance:IsA("ProximityPrompt") then
		return
	end
	if instance:GetAttribute("ArmyTarget") then
		return
	end
	local function sharedShop(attribute)
		local ancestor = instance
		while ancestor and ancestor ~= workspace do
			if ancestor:GetAttribute(attribute) then
				return true
			end
			ancestor = ancestor.Parent
		end
		return false
	end
	local shop = if sharedShop("SharedSellShop") then "Trade" elseif sharedShop("SharedBuyShop") then "Build" else nil
	local model = instance:FindFirstAncestorOfClass("Model")
	if not shop and not model then
		return
	end
	local function activate()
		shop = if sharedShop("SharedSellShop") then "Trade" elseif sharedShop("SharedBuyShop") then "Build" else nil
		if shop then
			placement.cancel()
			inventory.clear()
			inventory.close()
			ui.navigate(shop)
			return
		end
		if model:GetAttribute("OwnerId") ~= player.UserId then
			return
		end
		local id = model:GetAttribute("BuildingId")
		if type(id) ~= "string" then
			return
		end
		if armyControls.building(id) then
			return
		end
		if inventory.hammerSelected() then
			send("reclaim", { buildingId = id })
		elseif instance:IsA("ProximityPrompt") then
			local definition = Catalog.buildings[model:GetAttribute("Kind")]
			if definition and definition.output then
				send("collect", { buildingId = id })
			end
		end
	end
	bound[instance] = true
	if instance:IsA("ClickDetector") then
		table.insert(connections, instance.MouseClick:Connect(activate))
	else
		if not shop then
			local definition = Catalog.buildings[model:GetAttribute("Kind")]
			ownedPrompts[instance] = {
				model = model,
				actionText = instance.ActionText,
				enabled = instance.Enabled,
				reclaimOnly = instance:GetAttribute("ReclaimBuilding") == true
					or not (definition and definition.output),
			}
			updatePromptLabels()
		end
		table.insert(connections, instance.Triggered:Connect(activate))
	end
end
local sandbox = workspace:WaitForChild("MiniatureSandbox", 20)
if sandbox then
	table.insert(connections, sandbox.DescendantAdded:Connect(bind))
	for _, descendant in sandbox:GetDescendants() do
		bind(descendant)
	end
end
table.insert(
	connections,
	player.CharacterAdded:Connect(function()
		placement.cancel()
		inventory.clear()
		armyControls.clear()
	end)
)
screen.Destroying:Connect(function()
	outpostClient.destroy()
	armyControls.destroy()
	troopRenderer.destroy()
	for _, connection in connections do
		connection:Disconnect()
	end
end)
actions.Snapshot:FireServer()
task.spawn(function()
	while screen.Parent do
		task.wait(2)
		if not view or not view.loaded then
			actions.Snapshot:FireServer()
		end
	end
end)

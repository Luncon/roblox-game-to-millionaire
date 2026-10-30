--!strict
local Replicated = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local Run = game:GetService("RunService")
local Shared = Replicated:WaitForChild("MiniatureGame")
local Rules = require(Shared.Placement)
local Config = require(Shared.Config)
local Theme = require(script.Parent.Theme)
local Placement = {}
function Placement.start(screen, getView, send, guard)
	local draft, ghost, pending = nil, nil, false
	local dock = Theme.frame(screen, "PlacementControls", 152)
	dock.Visible, dock.ZIndex = false, 60
	Theme.list(dock, 4)
	local status = Theme.label(dock, "PlacementStatus", "", 44)
	local row, size = Theme.row(dock, "PlacementActions", 3)
	local controller = {}
	function controller.cancel()
		draft, pending = nil, false
		dock.Visible = false
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
		screen:SetAttribute("PlacingKind", nil)
	end
	local rotate = Theme.button(row, "Rotate", "Rotate", function()
		if draft then
			draft.rotation = (draft.rotation + 90) % 360
		end
	end)
	local confirm = Theme.button(row, "ConfirmPlacement", "Place", function()
		if not draft or pending then
			return
		end
		local view = getView()
		local valid = view
			and view.state
			and Rules.validate(view.state.buildings, draft.kind, draft.x, draft.z, draft.rotation)
		if not valid or guard("place") then
			return
		end
		local args = { kind = draft.kind, x = draft.x, z = draft.z, rotation = draft.rotation }
		pending = send("place", args) == true
	end)
	local cancel = Theme.button(row, "CancelPlacement", "Cancel", controller.cancel)
	rotate.Size, confirm.Size, cancel.Size = size, size, size
	Theme.label(dock, "PlacementHint", "Tap ground to position · R rotates · Confirm commits", 28)
	function controller.begin(kind)
		controller.cancel()
		local view = getView()
		if
			not view
			or not view.state
			or not view.plotFrame
			or not view.artReady
			or (view.state.plans[kind] or 0) < 1
			or guard("place")
		then
			return
		end
		draft = {
			kind = kind,
			x = 12,
			z = 10,
			rotation = 0,
			epoch = view.claimEpoch,
			sessionId = view.sessionId,
		}
		ghost = Instance.new("Part")
		ghost.Name, ghost.Anchored, ghost.CanCollide, ghost.CanTouch, ghost.CanQuery =
			"LocalPlacementFootprint", true, false, false, false
		ghost.Transparency, ghost.Material, ghost.Parent = 0.4, Enum.Material.Neon, workspace
		dock.Visible = true
		screen:SetAttribute("PlacingKind", kind)
	end
	function controller.receipt(accepted)
		pending = false
		if accepted then
			controller.cancel()
		end
	end
	local function point(position)
		local view, camera = getView(), workspace.CurrentCamera
		if not draft or not view or not view.plotFrame or not camera then
			return
		end
		local ray = camera:ViewportPointToRay(position.X, position.Y)
		local origin, direction =
			view.plotFrame:PointToObjectSpace(ray.Origin), view.plotFrame:VectorToObjectSpace(ray.Direction)
		if math.abs(direction.Y) < 0.0001 then
			return
		end
		local t = -origin.Y / direction.Y
		if t < 0 then
			return
		end
		local localPoint = origin + direction * t
		draft.x, draft.z =
			math.round(localPoint.X / Config.grid) * Config.grid, math.round(localPoint.Z / Config.grid) * Config.grid
	end
	local connections = {}
	table.insert(
		connections,
		Input.InputBegan:Connect(function(input, processed)
			if processed or Input:GetFocusedTextBox() or Gui.MenuIsOpen or not draft then
				return
			end
			if input.KeyCode == Enum.KeyCode.R then
				draft.rotation = (draft.rotation + 90) % 360
			elseif input.KeyCode == Enum.KeyCode.Escape then
				controller.cancel()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				point(Input:GetMouseLocation() - Gui:GetGuiInset())
			end
		end)
	)
	table.insert(
		connections,
		Input.TouchTapInWorld:Connect(function(position, processed)
			if not processed then
				point(position)
			end
		end)
	)
	table.insert(
		connections,
		Run.RenderStepped:Connect(function()
			if not draft then
				return
			end
			local view = getView()
			if
				not view
				or not view.writable
				or not view.claim
				or view.claimEpoch ~= draft.epoch
				or view.sessionId ~= draft.sessionId
				or not view.state
				or (view.state.plans[draft.kind] or 0) < 1
			then
				controller.cancel()
				return
			end
			local width, depth = Rules.bounds(draft)
			ghost.Size = Vector3.new(width, 0.15, depth)
			ghost.CFrame = view.plotFrame * CFrame.new(draft.x, 0.5, draft.z)
			local valid, reason = Rules.validate(view.state.buildings, draft.kind, draft.x, draft.z, draft.rotation)
			local blocked = guard("place")
			ghost.Color = if valid and not blocked then Theme.gold else Theme.clay
			status.Text = if pending
				then "Waiting for settlement confirmation…"
				elseif blocked then blocked
				elseif valid then string.format(
					"Clear footprint · %d, %d · %d°",
					draft.x,
					draft.z,
					draft.rotation
				)
				else "Cannot place: " .. string.gsub(reason or "invalid", "_", " ")
			Theme.enabled(confirm, valid and not blocked and not pending)
			local widthPixels = math.min(420, screen.AbsoluteSize.X - 32)
			dock.Size, dock.Position =
				UDim2.fromOffset(widthPixels, 152),
				UDim2.fromOffset((screen.AbsoluteSize.X - widthPixels) / 2, screen.AbsoluteSize.Y - 284)
		end)
	)
	screen.Destroying:Connect(function()
		controller.cancel()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	return controller
end
return Placement

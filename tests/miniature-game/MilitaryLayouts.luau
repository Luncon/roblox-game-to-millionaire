--!strict
-- Native rendering against isolated presentation copies, never server progress.
local function run(view)
	local Players = game:GetService("Players")
	local Replicated = game:GetService("ReplicatedStorage")
	local Http = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local Client = player.PlayerScripts.MiniatureGame
	local UI = require(Client.UI)
	local Inventory = require(Client.Inventory)
	local ArmyControls = require(Client.ArmyControls)
	local Layout = require(Replicated.MiniatureGame.MilitaryResearchLayout)
	assert(view and view.state and view.claim, "Layout fixture requires a selected civilization")
	local presentation = table.clone(view)
	presentation.state = table.clone(view.state)
	presentation.state.goods = table.clone(view.state.goods)
	presentation.state.plans = table.clone(view.state.plans)
	presentation.state.goods.food, presentation.state.plans.training = 4, 2
	presentation.state.militaryResearch =
		{ completed = { army_training = true, officer_training = true, army_control = true } }
	presentation.armyControlsUnlocked, presentation.armySlots = true, 2
	presentation.armyGroups = {
		{ armyId = 1, buildingIds = {}, count = 0, alive = 0, capacityUsed = 0 },
		{ armyId = 2, buildingIds = {}, count = 0, alive = 0, capacityUsed = 0 },
	}
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder, gui.Parent = "MilitaryLayoutFixture", 100, player.PlayerGui
	local result = { layouts = {}, serverMutation = false, nativeRendering = true }
	local function inside(object, container)
		local p, s, q, bounds =
			object.AbsolutePosition, object.AbsoluteSize, container.AbsolutePosition, container.AbsoluteSize
		return p.X >= q.X - 1 and p.Y >= q.Y - 1 and p.X + s.X <= q.X + bounds.X + 1 and p.Y + s.Y <= q.Y + bounds.Y + 1
	end
	local function inspectHoneycomb(tree)
		local canvas = tree.ResearchGraph.HexCanvas
		local zoom, vertices = tree:GetAttribute("Zoom"), Layout.vertices()
		local rootHex = canvas.Hex_army_training
		local rootCenter = rootHex.AbsolutePosition + rootHex.AbsoluteSize / 2
		local tiles, buttons, sharedEdges = {}, {}, 0
		local maxCenterError, maxSharedVertexError = 0, 0
		-- UDim.Offset stores integer pixels. Each rendered center differs from
		-- exact axial geometry by less than1px per axis after relative rounding;
		-- the pure layout tests retain exact, unquantized shared-edge assertions.
		local pixelTolerance = math.sqrt(2) * zoom + 0.01
		for _, id in Layout.order do
			local hex = canvas["Hex_" .. id]
			table.insert(tiles, { hex = hex, cell = Layout.nodes[id] })
			table.insert(buttons, hex["Node_" .. id])
		end
		for _, group in { { "FutureNode", Layout.civilian }, { "ReservedNode", Layout.reservedMilitary } } do
			for index, cell in group[2] do
				table.insert(tiles, { hex = canvas[group[1] .. index], cell = cell })
			end
		end
		for _, object in tree:GetDescendants() do
			assert(not string.find(object.Name, "Connection", 1, true), "Research retains a cross-node connector")
		end
		for index, tile in tiles do
			local hex = tile.hex
			local expected = Layout.point(tile.cell.q, tile.cell.r)
			local offset = hex.AbsolutePosition + hex.AbsoluteSize / 2 - rootCenter
			local centerError = (offset - Vector2.new(expected.x, expected.y) * zoom).Magnitude
			maxCenterError = math.max(maxCenterError, centerError)
			assert(
				centerError <= pixelTolerance,
				"Painted military/civilian cells are mirrored or shifted from their required root faces"
			)
			assert(
				hex.Size.X.Offset == math.floor(Layout.width)
					and hex.Size.Y.Offset == math.floor(Layout.height)
					and math.abs(hex.AbsoluteSize.X - hex.Size.X.Offset * zoom) < 0.1
					and math.abs(hex.AbsoluteSize.Y - hex.Size.Y.Offset * zoom) < 0.1,
				"Painted pointy hex dimensions differ"
			)
			for edgeIndex, first in vertices do
				local second, edge = vertices[edgeIndex % 6 + 1], hex["Edge" .. edgeIndex]
				local delta = Vector2.new(second.x - first.x, second.y - first.y)
				assert(
					edge.Position.X.Offset == math.floor((first.x + second.x) / 2)
						and edge.Position.Y.Offset == math.floor((first.y + second.y) / 2)
						and edge.Size.X.Offset == math.floor(delta.Magnitude)
						and math.abs(edge.Rotation - math.deg(math.atan2(delta.Y, delta.X))) < 0.01,
					"Painted outline no longer follows the pointy polygon"
				)
			end
			for fillIndex, rotation in { 0, 60, -60 } do
				local fill = hex["Fill" .. fillIndex]
				assert(
					fill.Size.X.Offset == math.floor(Layout.width)
						and fill.Size.Y.Offset == Layout.height / 2
						and fill.Rotation == rotation,
					"Hex fill extends beyond its shared polygon"
				)
				assert(
					fill.AnchorPoint == Vector2.new(0.5, 0.5) and fill.Position == UDim2.fromScale(0.5, 0.5),
					"Hex fill is not centered inside its outline"
				)
			end
			for otherIndex = index + 1, #tiles do
				local other = tiles[otherIndex]
				if Layout.adjacent(tile.cell, other.cell) then
					local shared = 0
					for _, first in vertices do
						local position = hex.AbsolutePosition + Vector2.new(first.x, first.y) * zoom
						local nearest = math.huge
						for _, second in vertices do
							local target = other.hex.AbsolutePosition + Vector2.new(second.x, second.y) * zoom
							nearest = math.min(nearest, (position - target).Magnitude)
						end
						if nearest <= pixelTolerance then
							shared += 1
							maxSharedVertexError = math.max(maxSharedVertexError, nearest)
						end
					end
					assert(shared == 2, "Adjacent painted tiles do not share a complete border")
					sharedEdges += 1
				end
			end
		end
		for index, button in buttons do
			assert(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44, "Hex center target is below44px")
			for otherIndex = index + 1, #buttons do
				local other = buttons[otherIndex]
				local distance = (button.AbsolutePosition + button.AbsoluteSize / 2)
					- (other.AbsolutePosition + other.AbsoluteSize / 2)
				assert(
					math.abs(distance.X) >= (button.AbsoluteSize.X + other.AbsoluteSize.X) / 2 - 0.1
						or math.abs(distance.Y) >= (button.AbsoluteSize.Y + other.AbsoluteSize.Y) / 2 - 0.1,
					"Diagonal research targets overlap"
				)
			end
		end
		return {
			tiles = #tiles,
			targets = #buttons,
			sharedEdges = sharedEdges,
			pointyTop = true,
			connections = 0,
			integerUDimOffsets = true,
			maxCenterError = maxCenterError,
			maxSharedVertexError = maxSharedVertexError,
			pixelTolerance = pixelTolerance,
		}
	end
	local ok, failure = pcall(function()
		for _, size in { Vector2.new(320, 360), Vector2.new(320, 568), Vector2.new(640, 360), Vector2.new(1024, 768) } do
			local shell = Instance.new("Frame")
			shell.Size, shell.Parent = UDim2.fromOffset(size.X, size.Y), gui
			local sends = 0
			local ui = UI.mount(shell, {
				send = function()
					sends += 1
					return false
				end,
				camera = function() end,
			})
			ui.update(presentation, true)
			local inventoryCallbacks = {
				guard = ui.guard,
				message = ui.message,
				closePanels = ui.closePanels,
				cancelPlacement = function() end,
				place = function() end,
				army = function() end,
			}
			local inventory = Inventory.start(shell, inventoryCallbacks)
			inventory.update(presentation, false)
			local army = ArmyControls.start(shell, {
				getView = function()
					return presentation
				end,
				guard = ui.guard,
				message = ui.message,
				send = function()
					sends += 1
					return false
				end,
				closePanels = ui.closePanels,
				cancelSelection = inventory.clear,
			})
			army.update(presentation, false)
			ui.navigate("Research")
			task.wait(0.25)
			local tree = shell.Research.Content.MilitaryResearchTree
			local geometry = inspectHoneycomb(tree)
			assert(inside(shell.Research, shell), "Research panel exceeds viewport")
			assert(inside(tree.SelectedNode, shell.Research), "Research details exceed panel")
			assert(tree.ResearchGraph.AbsoluteSize.Y >= 69, "Research hex clipped by short graph")
			assert(tree.SelectedNode.StartMilitaryResearch.AbsoluteSize.Y >= 44, "Research action too small")
			assert(not shell.OpenResearch.Visible, "Side Research button overlays open panel")
			assert(not shell.Hotbar.Visible, "Hotbar overlays short-screen research action")
			ui.closePanels()
			inventory.toggle()
			task.wait(0.25)
			assert(inside(shell.Inventory, shell), "Inventory exceeds viewport")
			assert(shell.Inventory.Content.AbsoluteSize.Y >= 104, "Inventory clips tile count/name")
			local good = shell.Inventory.Content.Goods_food
			assert(
				good.Visible and good.StackCount.Text == "×4" and good.GoodsPreview.CurrentCamera,
				"Goods image/count missing"
			)
			assert(inside(good.StackCount, shell.Inventory.Content), "First goods count clipped")
			local plan = shell.Inventory.Content.Plan_training
			assert(
				plan.Visible and plan.StackCount.Text == "×2" and plan.ItemPreview.CurrentCamera,
				"Building image/count missing"
			)
			inventory.close()
			army.toggle()
			task.wait(0.25)
			assert(inside(shell.ArmyControls, shell), "Army controls exceed viewport")
			assert(sends == 0, "Layout-only fixture sent gameplay requests")
			local bounds = {
				width = size.X,
				height = size.Y,
				graphHeight = tree.ResearchGraph.AbsoluteSize.Y,
				inventoryHeight = shell.Inventory.Content.AbsoluteSize.Y,
				honeycomb = geometry,
			}
			table.insert(result.layouts, bounds)
			army.destroy()
			shell:Destroy()
		end
	end)
	gui:Destroy()
	Replicated:SetAttribute(
		"MiniatureMilitaryLayoutsResult",
		Http:JSONEncode({ ok = ok, result = if ok then result else tostring(failure) })
	)
	assert(ok, tostring(failure))
	return result
end

return run

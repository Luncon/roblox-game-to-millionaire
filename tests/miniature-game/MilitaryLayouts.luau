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

--!strict
local Replicated = game:GetService("ReplicatedStorage")
local Shared = Replicated:WaitForChild("MiniatureGame")
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Presentation = require(Shared.Presentation)
local Civilizations = require(Shared.Civilizations)
local Theme = require(script.Parent.Theme)
local Pages = {}
local buildingOrder =
	{ "house", "farm", "timber", "material", "workshop", "storehouse", "training", "ranged", "healer", "mount" }
local descriptions = {
	house = "Four more civilians.",
	farm = "Grow grain.",
	timber = "Gather timber.",
	material = "Dig clay.",
	workshop = "Turn clay into pottery.",
	storehouse = "Room for 400 goods.",
	training = "Two melee recruits.",
	ranged = "Two ranged troops.",
	healer = "One supporting healer.",
	mount = "One mounted troop · 2 army slots.",
}
local function preview(parent, kind, civilizationId)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name, viewport.BackgroundColor3, viewport.Active = "Thumbnail", Theme.stone, false
	viewport.Position, viewport.Size = UDim2.fromOffset(6, 8), UDim2.fromOffset(56, 64)
	viewport.Ambient, viewport.LightColor = Color3.fromRGB(190, 180, 155), Color3.fromRGB(255, 238, 203)
	viewport.Parent = parent
	local previews = Shared:FindFirstChild("Previews")
	local kit = previews and previews:FindFirstChild(civilizationId)
	local source = kit and kit:FindFirstChild(kind)
	if not source or not source:IsA("Model") then
		return
	end
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
function Pages.Select(ctx)
	for _, civilization in Civilizations do
		local button = ctx.button(
			"Select" .. (if civilization.id == "sparta" then "Sparta" else civilization.id),
			civilization.name,
			function()
				local view = ctx.view()
				if not ctx.guard("select") and view.artKits and view.artKits[civilization.id] then
					ctx.send("select", { civilizationId = civilization.id })
				end
			end
		)
		ctx.track(function()
			local view = ctx.view()
			local owner = view and view.claims and view.claims[civilization.id]
			local unavailable = not view or not view.artKits or not view.artKits[civilization.id]
			local claimed = owner and owner.ownerId and owner.ownerId ~= ctx.player.UserId
			button.Text = civilization.name
				.. (if unavailable then " · soon" elseif claimed then " · claimed" else "")
			Theme.enabled(button, not unavailable and not claimed and not ctx.guard("select"))
		end)
	end
end
function Pages.Trade(ctx)
	ctx.dynamic("TradeHoldings", function(view)
		return string.format(
			"Grain %d · Timber %d\nClay %d · Pottery %d",
			view.state.goods.food,
			view.state.goods.timber,
			view.state.goods.material,
			view.state.goods.crafted
		)
	end, 40)
	local value = ctx.dynamic("SaleTotal", function(view)
		local total = 0
		for _, good in Catalog.goods do
			total += view.state.goods[good] * Catalog.salePrices[good]
		end
		return "Total: " .. total .. " coins"
	end, 24)
	value.TextColor3 = Theme.gold
	local button = ctx.button("SellAll", "Sell all goods", function()
		local blocked = ctx.guard("sellAll")
		if blocked then
			ctx.message(blocked)
		else
			ctx.send("sellAll", {})
		end
	end)
	ctx.track(function()
		local view = ctx.view()
		local total = 0
		if view and view.state then
			for _, amount in view.state.goods do
				total += amount
			end
		end
		Theme.enabled(button, total > 0 and not ctx.guard("sellAll"))
	end)
end
function Pages.Build(ctx)
	ctx.body.AutomaticCanvasSize, ctx.body.CanvasSize, ctx.body.ScrollingEnabled =
		Enum.AutomaticSize.None, UDim2.new(), false
	local tabs, tabSize = Theme.row(ctx.body, "ShopTabs", 3)
	ctx.order(tabs)
	for _, category in { "Homes", "Production", "Military" } do
		local button = Theme.button(tabs, "Category_" .. category, category, function()
			ctx.drafts.category = category
			ctx.rebuild()
		end)
		button.Size, button.TextSize = tabSize, 12
		button.BackgroundColor3 = if ctx.drafts.category == category then Theme.clay else Theme.wood
	end
	ctx.dynamic("MerchantClock", function(view)
		return "Restock in "
			.. math.max(0, (view.state.merchant.cycle + 1) * Config.restockSeconds - (view.serverTime or 0))
			.. "s"
	end, 20)
	local list = Instance.new("ScrollingFrame")
	list.Name, list.Size = "ShopList", UDim2.new(1, 0, 1, -92)
	list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness = 1, 0, 4
	list.AutomaticCanvasSize, list.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	list.ScrollingDirection, list.Parent = Enum.ScrollingDirection.Y, ctx.body
	ctx.order(list)
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 6), Enum.SortOrder.LayoutOrder, list
	ctx.drafts.shopScroll = ctx.drafts.shopScroll or {}
	local category = ctx.drafts.category
	list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		ctx.drafts.shopScroll[category] = list.CanvasPosition
	end)
	for index, kind in buildingOrder do
		local entry = Catalog.buildings[kind]
		if not entry or entry.category ~= category then
			continue
		end
		local row = Theme.frame(list, "Row_" .. kind, 88)
		row.Size, row.LayoutOrder = UDim2.new(1, -6, 0, 88), index
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 6), row
		preview(row, kind, ctx.view().state.civilizationId)
		local title = Theme.label(row, "Title", Presentation.buildingName(ctx.view().state.civilizationId, kind), 32)
		title.Position, title.Size, title.TextSize, title.Font =
			UDim2.fromOffset(68, 3), UDim2.new(1, -150, 0, 32), 12, Enum.Font.GothamBold
		title.TextTruncate = Enum.TextTruncate.AtEnd
		local description = Theme.label(row, "Description", descriptions[kind], 28)
		description.Position, description.Size, description.TextSize, description.TextColor3 =
			UDim2.fromOffset(68, 34), UDim2.new(1, -150, 0, 28), 11, Theme.muted
		local stock = Theme.label(row, "Stock", "", 20)
		stock.Position, stock.Size, stock.TextSize = UDim2.fromOffset(68, 66), UDim2.new(1, -150, 0, 20), 11
		local buy = Theme.button(row, "Buy_" .. kind, tostring(entry.price) .. " coins\nBuy", function()
			local blocked = ctx.guard("buy")
			if blocked then
				ctx.message(blocked)
			else
				ctx.send("buy", { kind = kind })
			end
		end)
		buy.Position, buy.Size, buy.TextSize = UDim2.new(1, -78, 0, 26), UDim2.fromOffset(72, 44), 12
		ctx.track(function()
			local view = ctx.view()
			if not view or not view.state then
				return
			end
			local count = view.state.merchant.stock[kind] or 0
			stock.Text = "Stock ×" .. count
			local uniqueOwned = false
			if entry.unique then
				uniqueOwned = (view.state.plans[kind] or 0) > 0
				for _, building in view.state.buildings do
					uniqueOwned = uniqueOwned or building.kind == kind
				end
			end
			local ready = count > 0 and not uniqueOwned and view.state.coins >= entry.price and not ctx.guard("buy")
			Theme.enabled(buy, ready)
			buy.Text = if count == 0
				then "Sold out"
				elseif uniqueOwned then "Owned"
				else tostring(entry.price) .. " coins\nBuy"
		end)
	end
	task.defer(function()
		if list.Parent then
			list.CanvasPosition = ctx.drafts.shopScroll[category] or Vector2.zero
		end
	end)
end
return Pages

--!strict
local Theme = {
	stone = Color3.fromRGB(43, 49, 43),
	wood = Color3.fromRGB(72, 59, 45),
	card = Color3.fromRGB(58, 66, 53),
	ink = Color3.fromRGB(247, 237, 211),
	muted = Color3.fromRGB(207, 199, 176),
	gold = Color3.fromRGB(212, 171, 86),
	clay = Color3.fromRGB(148, 65, 47),
}
function Theme.frame(parent, name, height)
	local frame = Instance.new("Frame")
	frame.Name, frame.BorderSizePixel = name, 0
	frame.BackgroundColor3 = Theme.card
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Parent = parent
	return frame
end
function Theme.label(parent, name, text, height)
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, text
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Size = UDim2.new(1, 0, 0, height or 40)
	label.Font, label.TextSize = Enum.Font.Gotham, 14
	label.TextColor3, label.TextWrapped = Theme.ink, true
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end
function Theme.button(parent, name, text, callback)
	local button = Instance.new("TextButton")
	button.Name, button.Text = name, text
	button.Size = UDim2.new(1, 0, 0, 44)
	button.BackgroundColor3, button.TextColor3 = Theme.wood, Theme.ink
	button.BorderSizePixel, button.Font, button.TextSize = 0, Enum.Font.GothamBold, 14
	button.TextWrapped, button.AutoButtonColor = true, true
	button.Activated:Connect(callback)
	button.Parent = parent
	return button
end
function Theme.enabled(button, enabled)
	button.Active, button.Selectable, button.AutoButtonColor = enabled, enabled, enabled
	button.BackgroundColor3 = if enabled then Theme.wood else Theme.stone
	button.TextColor3 = if enabled then Theme.ink else Theme.muted
end
function Theme.list(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder = UDim.new(0, padding or 8), Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	local inset = Instance.new("UIPadding")
	inset.PaddingLeft, inset.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	inset.PaddingTop, inset.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	inset.Parent = parent
	return layout
end
function Theme.row(parent, name, count)
	local row = Theme.frame(parent, name, 44)
	row.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 4)
	layout.SortOrder, layout.Parent = Enum.SortOrder.LayoutOrder, row
	return row, UDim2.new(1 / count, -4 * (count - 1) / count, 0, 44)
end
function Theme.input(parent, name, text, callback)
	local box = Instance.new("TextBox")
	box.Name, box.Text, box.PlaceholderText = name, text, "Amount"
	box.Size, box.BackgroundColor3 = UDim2.new(1, 0, 0, 44), Theme.stone
	box.TextColor3, box.Font, box.TextSize = Theme.ink, Enum.Font.Gotham, 16
	box.ClearTextOnFocus, box.BorderSizePixel = false, 0
	box:GetPropertyChangedSignal("Text"):Connect(function()
		callback(box.Text)
	end)
	box.Parent = parent
	return box
end
return Theme

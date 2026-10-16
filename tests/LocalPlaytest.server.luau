-- Explicitly installed Studio override; fresh in-memory progress on every Play.
assert(game:GetService("RunService"):IsStudio(), "Local playtest is Studio-only")
local store = require(script.Parent.FakeProfileStore).new()
assert(store.isFakeProfileStore)
local data = require(game.ServerScriptService.Game.ProfileData)
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	return update(self, key, function(value)
		if value == nil then
			value = {schemaVersion=1, civilizations={}}
			for _, civilization in require(game.ReplicatedStorage.Shared.Civilizations) do
				local state = data.defaultState()
				state.coins = 3000
				value.civilizations[civilization.id] = state
			end
		end
		return transform(value)
	end)
end
game.ReplicatedStorage:SetAttribute("GameStartupError", nil)
game.ReplicatedStorage:SetAttribute("TemporaryProgress", true)

local function showNotice(player)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "TemporaryProgressNotice", false, 200
	local label = Instance.new("TextLabel")
	label.Size, label.Position = UDim2.new(0, 380, 0, 28), UDim2.new(0, 12, 1, -40)
	label.BackgroundColor3, label.BackgroundTransparency = Color3.fromRGB(30, 30, 30), .15
	label.TextColor3, label.TextSize = Color3.fromRGB(255, 222, 138), 14
	label.Text = "LOCAL PLAYTEST: progress resets when Play stops"
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
end
local players = game:GetService("Players")
players.PlayerAdded:Connect(function(player) task.spawn(showNotice, player) end)
for _, player in players:GetPlayers() do task.spawn(showNotice, player) end
require(game.ServerScriptService.Game.CivilizationService).start({profileStore=store})

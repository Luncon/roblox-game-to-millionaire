--!strict
-- Separate native shop verification only: 5000 Coins, zero goods, no research.
-- Ordinary gameplay Bootstrap still starts at 200 Coins with injected fake data.
local Replicated = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
assert(game:GetService("RunService"):IsStudio(), "Shop fixture is Studio-only")
assert(not Replicated:GetAttribute("MiniatureSandboxReady"), "Replace normal Bootstrap; never run both")
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local store = require(ServerStorage:WaitForChild("FakeProfileStore")).new()
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected shop fixture store key")
	if self:read(key) == nil then
		local state = State.new("sparta", os.time())
		state.coins = 5000
		assert(State.validate(state, "sparta"), "Invalid Coin-only fixture state")
		self:seed(key, { schemaVersion = 1, civilizations = { sparta = state } })
	end
	return update(self, key, transform)
end
Replicated:SetAttribute("MiniatureSimpleShopFixture", true)
Replicated:SetAttribute("MiniatureSimpleShopFunding", "5000 Coins only; zero goods, no research, ordinary real clocks")
return Runtime.start({ store = store })

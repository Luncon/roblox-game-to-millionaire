--!strict
-- Advanced verification ONLY: replace normal Bootstrap in a separate test mapping.
-- Every joining player's fake Spartan state starts with 5000 Coins, 80 Timber
-- and 20 Material. Hall, research, plans, buildings and workers stay unmodified.
-- Runtime uses real clocks; this is not starter pacing or live-storage evidence.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
assert(RunService:IsStudio(), "Advanced miniature fixture is Studio-only")
assert(not ReplicatedStorage:GetAttribute("MiniatureSandboxReady"), "Replace normal Bootstrap; do not run both")
local FakeProfileStore = require(ServerStorage:WaitForChild("FakeProfileStore"))
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local store = FakeProfileStore.new()
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected advanced fixture store key")
	if self:read(key) == nil then
		local state = State.new("sparta", os.time())
		state.coins, state.goods.timber, state.goods.material = 5000, 80, 20
		assert(State.validate(state, "sparta"), "Invalid funded fixture state")
		self:seed(key, { schemaVersion = 1, civilizations = { sparta = state } })
	end
	return update(self, key, transform)
end
ReplicatedStorage:SetAttribute("MiniatureAdvancedFixture", true)
ReplicatedStorage:SetAttribute("MiniatureAdvancedFunding", "5000 Coins / 80 Timber / 20 Material; real clocks")
return Runtime.start({ store = store })

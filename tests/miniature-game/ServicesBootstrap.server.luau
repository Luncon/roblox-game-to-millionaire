--!strict
-- Effects verification ONLY: replace normal Bootstrap in a separate test map.
-- Fake Sparta is funded and pre-unlocked: 5000 Coins,80 Timber,20 Material,
-- upgraded hall and all nine completed nodes. This does not prove native research
-- completion or progression pacing. Runtime uses real clocks and normal actions.
-- NativeCapacityFixture=true is an Edit-time test-map option: instead seed
-- 200 Timber, zero Material and 60 uncollected farm output to verify a real
-- transfer beyond the original 200-goods cap after buying the Storehouse.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
assert(game:GetService("RunService"):IsStudio(), "Services fixture is Studio-only")
assert(not ReplicatedStorage:GetAttribute("MiniatureSandboxReady"), "Replace normal Bootstrap; do not run both")
local Catalog = require(ReplicatedStorage.MiniatureGame.Catalog)
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local FakeStore = require(ServerStorage:WaitForChild("FakeProfileStore"))
local capacityFixture = ReplicatedStorage:GetAttribute("NativeCapacityFixture") == true
local store = FakeStore.new()
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected services fixture key")
	if self:read(key) == nil then
		local state = State.new("sparta", os.time())
		state.coins = 5000
		state.goods.timber = if capacityFixture then 200 else 80
		state.goods.material = if capacityFixture then 0 else 20
		if capacityFixture then
			state.buildings[3].output = 60
		end
		state.hallUpgraded = true
		for id in Catalog.research do
			state.research.completed[id] = true
		end
		state.buildings[1].x, state.buildings[1].z, state.buildings[1].rotation = -6, -10, 90
		state.buildings[2].x, state.buildings[2].z = -16, 6
		state.buildings[3].x, state.buildings[3].z = 6, -10
		state.merchant.stock = State.freshStock(state)
		assert(State.validate(state, "sparta"), "Invalid pre-unlocked services setup")
		self:seed(key, { schemaVersion = 1, civilizations = { sparta = state } })
	end
	return update(self, key, transform)
end
ReplicatedStorage:SetAttribute("MiniatureServicesFixture", true)
ReplicatedStorage:SetAttribute(
	"MiniatureServicesSetup",
	if capacityFixture
		then "Capacity fixture: 200 Timber, zero Material, 60 farm output; hall + all nine nodes pre-unlocked; real clocks"
		else "Funded compact Sparta; hall + all nine nodes pre-unlocked; real clocks"
)
return Runtime.start({ store = store })

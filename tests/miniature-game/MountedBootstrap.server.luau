--!strict
-- Explicit Coin-only native mounted acceptance seed; normal bootstrap stays200.
local Replicated = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Civilizations = require(Replicated.MiniatureGame.Civilizations)
assert(game:GetService("RunService"):IsStudio(), "Mounted fixture is Studio-only")
assert(not Replicated:GetAttribute("MiniatureSandboxReady"), "Never run two sandbox bootstraps")
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local store = require(ServerStorage:WaitForChild("FakeProfileStore")).new()
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected mounted fake-store key")
	if self:read(key) == nil then
		local civilizations = {}
		for _, civilization in Civilizations do
			local state = State.new(civilization.id, os.time())
			state.coins = 20000
			assert(State.validate(state, civilization.id), "Invalid Coin-only mounted fixture state")
			civilizations[civilization.id] = state
		end
		self:seed(key, { schemaVersion = 1, civilizations = civilizations })
	end
	return update(self, key, transform)
end
Replicated:SetAttribute("MiniatureMountedFixture", true)
Replicated:SetAttribute(
	"MiniatureMountedFunding",
	"20000 Coins per civilization; zero goods, no research or army injection"
)
return Runtime.start({ store = store })

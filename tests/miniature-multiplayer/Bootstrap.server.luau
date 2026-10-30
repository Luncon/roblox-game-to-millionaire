--!strict
-- Three real Studio clients; 20,000 Coins is the only seeded progression.
local Replicated = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
assert(game:GetService("RunService"):IsStudio(), "Three-player bootstrap is Studio-only")
local Context = require(ServerStorage:WaitForChild("ThreePlayerContext"))
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local Civilizations = require(Replicated:WaitForChild("MiniatureGame").Civilizations)
local store = require(ServerStorage:WaitForChild("FakeProfileStore")).new()
assert(store.isFakeProfileStore, "Multiplayer tests must never access player storage")
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected multiplayer fake-store key")
	if self:read(key) == nil then
		local civilizations = {}
		for _, civilization in Civilizations do
			local state = State.new(civilization.id, os.time())
			state.coins = 20000
			assert(State.validate(state, civilization.id), "Invalid Coin-only multiplayer fixture")
			civilizations[civilization.id] = state
		end
		self:seed(key, { schemaVersion = 1, civilizations = civilizations })
	end
	return update(self, key, transform)
end
Context.store = store
Replicated:SetAttribute("MiniatureThreePlayerFixture", true)
local ok, runtime = pcall(function()
	assert(not Replicated:GetAttribute("MiniatureSandboxReady"), "Never run two sandbox bootstraps")
	return Runtime.start({ store = store })
end)
if not ok then
	Context.error = tostring(runtime)
	error(runtime)
end
Context.runtime, Context.sessions, Context.scene = runtime, runtime.sessions, runtime.scene
Replicated:SetAttribute(
	"MiniatureThreePlayerFunding",
	"20,000 Coins only per civilization; no research, armies or goods seeded"
)

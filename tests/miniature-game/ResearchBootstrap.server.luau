--!strict
-- Explicit military UI fixture: Coins only, no completed projects or troops.
local Replicated = game:GetService("ReplicatedStorage")
local Storage = game:GetService("ServerStorage")
assert(game:GetService("RunService"):IsStudio(), "Research fixture is Studio-only")
assert(not Replicated:GetAttribute("MiniatureSandboxReady"), "Never run two bootstraps")
local State = require(script.Parent.State)
local Runtime = require(script.Parent.Runtime)
local Civilizations = require(Replicated.MiniatureGame.Civilizations)
local store = require(Storage.FakeProfileStore).new()
local update = store.UpdateAsync
function store:UpdateAsync(key, transform)
	assert(string.match(key, "^miniature%-development:%-?%d+$"), "Unexpected research fake-store key")
	if self:read(key) == nil then
		local civilizations = {}
		for _, civilization in Civilizations do
			local state = State.new(civilization.id, os.time())
			state.coins = 100000
			assert(State.validate(state, civilization.id), "Invalid research fixture")
			civilizations[civilization.id] = state
		end
		self:seed(key, { schemaVersion = 1, civilizations = civilizations })
	end
	return update(self, key, transform)
end
Replicated:SetAttribute("MiniatureResearchFixture", "100000 Coins per civilization; no research or army injection")
return Runtime.start({ store = store })

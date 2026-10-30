--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PersistentProfileStore = require(script.Parent.PersistentProfileStore)
local ReleaseConfig = require(script.Parent.ReleaseConfig)
local Runtime = require(script.Parent.Runtime)
local LiveStartup = {}

function LiveStartup.start(options)
	options = options or {}
	assert(
		game.PlaceId == ReleaseConfig.placeId
			and game.GameId == ReleaseConfig.universeId
			and game.CreatorType == Enum.CreatorType.User
			and game.CreatorId == ReleaseConfig.ownerId,
		"Release target does not match the authorized Clash of Civilizations experience"
	)
	local verificationScope = options.verificationScope
	if RunService:IsStudio() then
		assert(
			verificationScope ~= nil,
			"Release Studio play requires an isolated verification scope; use the default project for temporary previews"
		)
	else
		assert(verificationScope == nil, "Verification mode is forbidden on live servers")
	end
	local store = PersistentProfileStore.new({ verificationScope = verificationScope })
	ReplicatedStorage:SetAttribute("MiniatureReleaseId", ReleaseConfig.id)
	local runtime = Runtime.start({ store = store })
	print("Clash of Civilizations " .. ReleaseConfig.id .. " ready with " .. store.storageLabel)
	return runtime
end

return table.freeze(LiveStartup)

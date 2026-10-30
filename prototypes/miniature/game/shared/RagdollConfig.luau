--!strict
-- Cosmetic-only bounds and server-registered collision group names.
local Config = {
	corpseCollisionGroup = "MiniatureRagdoll",
	groundCollisionGroup = "MiniatureRagdollGround",
	supportCollisionGroup = "MiniatureRagdollSupport",
	sourceRetireSeconds = 0.35,
	lifetimeSeconds = 6,
	fadeSeconds = 1,
	maxCorpses = 12,
	maxParts = 1200,
	maxPartsPerCorpse = 320,
	maxColliders = 18,
	maxSockets = 24,
	maxSupports = 8,
	noticeMaxAge = 2,
}
return table.freeze(Config)

--!strict
local Config = require(script.Parent.Config)
local MountConfig = require(script.Parent.MountConfig)

export type RoleStats = {
	health: number,
	damage: number,
	reach: number,
	speed: number,
	cooldown: number,
	windup: number,
	recovery: number,
	heal: number,
	healRange: number,
	healCooldown: number,
}

local function profile(
	health: number,
	damage: number,
	reach: number,
	speed: number,
	cooldown: number,
	windup: number,
	heal: number?
): RoleStats
	return table.freeze({
		health = health,
		damage = damage,
		reach = reach,
		speed = speed,
		cooldown = cooldown,
		windup = windup,
		recovery = 0.25,
		heal = heal or 0,
		healRange = Config.medicHealRange,
		healCooldown = 1.25,
	})
end

local melee = profile(160, 30, 2.5, Config.playerTroopSpeed, 1, 0.22)
local mounted = table.clone(melee)
mounted.health, mounted.damage, mounted.speed = 300, 48, 9
table.freeze(mounted)

local player = table.freeze({
	melee = melee,
	ranged = profile(120, 24, Config.rangedReach, Config.playerTroopSpeed, 1.5, 0.3),
	medic = profile(100, 0, 0, Config.playerTroopSpeed, 1, 0.2, 12),
	mounted = mounted,
})

local function neutralProfile(owned: RoleStats): RoleStats
	local result = table.clone(owned)
	result.health *= 0.95
	result.damage *= 0.95
	result.speed *= 0.95
	return table.freeze(result)
end

-- Prepare frozen species profiles once. Requests only select existing data;
-- ordinary profiles and the generic mounted fallback remain unchanged.
local mountedProfiles: { [string]: { player: RoleStats, neutral: RoleStats } } = {}
for civilizationId, definition in MountConfig.definitions do
	local owned = table.clone(player.mounted)
	owned.speed = definition.speed
	table.freeze(owned)
	mountedProfiles[civilizationId] = table.freeze({ player = owned, neutral = neutralProfile(owned) })
end
table.freeze(mountedProfiles)

local BattleConfig = {
	scale = Config.scale,
	troopCap = Config.troopCap,
	captureSeconds = 20,
	capturePausesForDefenders = true,
	ownedRespawnSeconds = 10,
	neutralRespawnSeconds = 8,
	combatMargin = 6,
	contactTolerance = 0.2,
	arrivalDistance = 0.15,
	softSpacing = 1.8,
	separationSpeed = 3,
	fixedStep = 0.05,
	maxDelta = 0.5,
	player = player,
	neutral = table.freeze({
		melee = neutralProfile(player.melee),
		ranged = neutralProfile(player.ranged),
		medic = neutralProfile(player.medic),
		mounted = neutralProfile(player.mounted),
	}),
}
function BattleConfig.getProfile(role: string, civilizationId: string?, neutral: boolean?): RoleStats
	local species = if role == "mounted" and civilizationId ~= nil then mountedProfiles[civilizationId] else nil
	if species ~= nil then
		return if neutral then species.neutral else species.player
	end
	local profiles: { [string]: RoleStats } = if neutral then BattleConfig.neutral else BattleConfig.player
	local result = profiles[role]
	assert(result, "Unsupported miniature combat role")
	return result
end
return table.freeze(BattleConfig)

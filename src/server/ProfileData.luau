--!strict

local Civilizations = require(game:GetService("ReplicatedStorage").Shared.Civilizations)
local ProfileData = {}

export type State = { coins: number, level: number, weaponLevel: number, armorLevel: number, barracksLevel: number }
export type Profile = {
	schemaVersion: number,
	civilizations: { [string]: State },
	session: { token: string, expiresAt: number }?,
	savedAt: number?,
}

local known: { [string]: boolean } = {}
for _, civilization in Civilizations do known[civilization.id] = true end

local function integer(value: any, minimum: number, maximum: number): boolean
	return type(value) == "number" and value >= minimum and value <= maximum and value % 1 == 0
end

local function timestamp(value: any): boolean
	return type(value) == "number" and value >= 0 and value < math.huge
end

function ProfileData.defaultState(): State
	return { coins = 0, level = 1, weaponLevel = 1, armorLevel = 1, barracksLevel = 1 }
end

function ProfileData.copyState(value: any): State?
	if type(value) ~= "table" or not integer(value.coins, 0, 1000000000)
		or not integer(value.level, 1, 4) or not integer(value.weaponLevel, 1, value.level)
		or not integer(value.armorLevel, 1, value.level) or not integer(value.barracksLevel, 1, value.level) then
		return nil
	end
	-- Deliberately omit account revisions, rate limits, plot IDs and troop instances.
	return { coins = value.coins, level = value.level, weaponLevel = value.weaponLevel,
		armorLevel = value.armorLevel, barracksLevel = value.barracksLevel }
end

function ProfileData.isCivilization(value: any): boolean
	return type(value) == "string" and known[value] == true
end

function ProfileData.decode(value: any): Profile?
	if type(value) ~= "table" or value.schemaVersion ~= 1 or type(value.civilizations) ~= "table" then return nil end
	local civilizations: { [string]: State } = {}
	for civilizationId, state in value.civilizations do
		if not ProfileData.isCivilization(civilizationId) then return nil end
		local copied = ProfileData.copyState(state)
		if not copied then return nil end
		civilizations[civilizationId] = copied
	end
	local session = nil
	if value.session ~= nil then
		if type(value.session) ~= "table" or type(value.session.token) ~= "string"
			or #value.session.token == 0 or not timestamp(value.session.expiresAt) then return nil end
		session = { token = value.session.token, expiresAt = value.session.expiresAt }
	end
	if value.savedAt ~= nil and not timestamp(value.savedAt) then return nil end
	return { schemaVersion = 1, civilizations = civilizations, session = session, savedAt = value.savedAt }
end

return ProfileData

--!strict

local Civilizations = require(game:GetService("ReplicatedStorage").Shared.Civilizations)
local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local Development = require(game:GetService("ReplicatedStorage").Shared.SettlementDevelopment)
local ProfileData = {}

export type State = { coins: number, level: number, weaponLevel: number, armorLevel: number, barracksLevel: number,
	trainingLevel: number, farmLevel: number, workersLevel: number, armyCampLevel: number, farmCoins: number, extraTroopClass: string,
	blacksmithLevel: number, armorerLevel: number, storehouseLevel: number, skillLevel: number, hospitalLevel: number }
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
	return { coins = 0, level = 1, weaponLevel = 1, armorLevel = 1, barracksLevel = 1,
		trainingLevel=0,farmLevel=0,workersLevel=0,armyCampLevel=0,farmCoins=0,extraTroopClass="warrior",
		blacksmithLevel=0,armorerLevel=0,storehouseLevel=0,skillLevel=0,hospitalLevel=0 }
end

function ProfileData.copyState(value: any): State?
	if type(value) ~= "table" or not integer(value.coins, 0, 1000000000)
		or not integer(value.level, 1, #Tracks.settlement) then
		return nil
	end
	if not integer(value.weaponLevel, 1, math.min(value.level, #Tracks.weapon))
		or not integer(value.armorLevel, 1, math.min(value.level, #Tracks.armor))
		or not integer(value.barracksLevel, 1, math.min(value.level, #Tracks.barracks)) then
		return nil
	end
	if value.barracksLevel>1 and value.level<(Tracks.barracks[value.barracksLevel-1].requiredSettlement or 1) then return nil end
	local copied={ coins=value.coins,level=value.level,weaponLevel=value.weaponLevel,
		armorLevel=value.armorLevel,barracksLevel=value.barracksLevel }
	for _,building in Development.buildings do
		local level=if value[building.field]==nil then 0 else value[building.field]
		if not integer(level,0,building.maxLevel) or (level>0 and value.level<building.tiers[level].unlock) then return nil end
		copied[building.field]=level
	end
	if copied.hospitalLevel==1 and copied.trainingLevel~=1 then return nil end
	if copied.workersLevel>copied.farmLevel then return nil end
	if copied.armyCampLevel==1 and copied.barracksLevel<4 then return nil end
	if copied.storehouseLevel==1 and copied.farmLevel<1 then return nil end
	local reserve=if value.farmCoins==nil then 0 else value.farmCoins
	local kind=if value.extraTroopClass==nil then "warrior" else value.extraTroopClass
	if not integer(reserve,0,Development.storageCapacity(copied)) or (copied.farmLevel==0 and reserve~=0)
		or (kind~="warrior" and kind~="ranged") then return nil end
	copied.farmCoins,copied.extraTroopClass=reserve,kind
	local skill=if value.skillLevel==nil then 0 else value.skillLevel
	if not integer(skill,0,5) or (skill>0 and (copied.trainingLevel~=1 or copied.weaponLevel<skill*10)) then return nil end
	copied.skillLevel=skill
	-- Legacy settlement 10+ does not retroactively require the new checkpoint.
	-- Omit revisions, live clocks, rate limits, plot IDs and troop instances.
	return copied
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

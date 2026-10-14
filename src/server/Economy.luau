--!strict

local Tracks = require(game:GetService("ReplicatedStorage").Shared.UpgradeTracks)
local Economy = {}
local BURST = 20
local REFILL = 15
local MAX_COINS = 1000000000

type Account = {
	coins: number, level: number, weaponLevel: number, armorLevel: number, barracksLevel: number, revision: number,
	tokens: number, updatedAt: number, purchasedAt: { [string]: number },
}

function Economy.new(clock: (() -> number)?)
	local now = clock or os.clock
	local accounts: { [number]: Account } = {}
	local economy = {}

	function economy:get(playerId: number)
		local account = accounts[playerId]
		return if account then {
			coins = account.coins, level = account.level, revision = account.revision,
			weaponLevel = account.weaponLevel, armorLevel = account.armorLevel,
			barracksLevel = account.barracksLevel,
		} else nil
	end

	function economy:open(playerId: number)
		if not accounts[playerId] then
			accounts[playerId] = {
				coins = 0, level = 1, weaponLevel = 1, armorLevel = 1, barracksLevel = 1, revision = 0,
				tokens = BURST, updatedAt = now(), purchasedAt = {},
			}
		end
		return self:get(playerId)
	end

	local function rejected(playerId: number, reason: string)
		return { ok = false, reason = reason, state = economy:get(playerId) }
	end

	function economy:earn(playerId: number)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		local time = now()
		account.tokens = math.min(BURST, account.tokens + math.max(0, time - account.updatedAt) * REFILL)
		account.updatedAt = time
		if account.tokens < 1 then return rejected(playerId, "rate_limited") end
		if account.coins >= MAX_COINS then return rejected(playerId, "coin_limit") end
		account.tokens -= 1
		account.coins += 1
		account.revision += 1
		return { ok = true, state = self:get(playerId) }
	end

	function economy:upgrade(playerId: number, expectedLevel: unknown, kind: unknown)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		local trackId = if kind == nil then "settlement" else kind
		if type(trackId) ~= "string" or not Tracks[trackId] then return rejected(playerId, "invalid") end
		local progression = Tracks[trackId]
		local field = if trackId == "weapon" then "weaponLevel" elseif trackId == "armor" then "armorLevel"
			elseif trackId == "barracks" then "barracksLevel" else "level"
		local currentLevel = account[field]
		if type(expectedLevel) ~= "number" or expectedLevel % 1 ~= 0
			or expectedLevel < 1 or expectedLevel > #progression then
			return rejected(playerId, "invalid")
		end
		if expectedLevel ~= currentLevel then return rejected(playerId, "stale_level") end
		local cost = progression[currentLevel].nextCost
		if not cost then return rejected(playerId, "max_level") end
		local required = progression[currentLevel].requiredSettlement or 1
		if account.level < required then return rejected(playerId, "settlement_locked") end
		local time = now()
		if account.purchasedAt[trackId] and time - account.purchasedAt[trackId] < .4 then
			return rejected(playerId, "rate_limited")
		end
		account.purchasedAt[trackId] = time
		if account.coins < cost then return rejected(playerId, "insufficient_funds") end
		-- No yielding between checking the price and committing both values.
		account.coins -= cost
		account[field] += 1
		account.revision += 1
		return { ok = true, state = self:get(playerId) }
	end

	-- Called only by server-validated lethal combat, independently of click tokens.
	function economy:rewardKill(playerId: number)
		local account = accounts[playerId]
		if not account then return rejected(playerId, "not_claimed") end
		if account.coins > MAX_COINS - 10 then return rejected(playerId, "coin_limit") end
		account.coins += 10
		account.revision += 1
		return {ok=true, amount=10, state=self:get(playerId)}
	end

	function economy:close(playerId: number)
		accounts[playerId] = nil
	end

	return economy
end

return Economy

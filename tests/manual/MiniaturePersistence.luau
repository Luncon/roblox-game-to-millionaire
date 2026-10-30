--!strict
-- Explicit real-storage verification only. Never map this into an automatic
-- regression runner or the published bootstrap. Its scope cannot be Live.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Server = game:GetService("ServerScriptService").MiniaturePersistenceVerification
local Store = require(Server.PersistentProfileStore)
local Sessions = require(Server.Sessions)
local State = require(Server.State)
local verify = {}

function verify.run(userId: number, scope: string)
	assert(
		RunService:IsStudio() and game.GameId == 10770758443,
		"Verification requires the authorized Studio experience"
	)
	assert(userId == game.CreatorId and userId > 0, "Only the creator's isolated verification profile is permitted")
	local function session()
		return Sessions.new({
			store = Store.new({ verificationScope = scope }),
			clock = os.time,
			token = function()
				return HttpService:GenerateGUID(false)
			end,
		})
	end
	local first, second = session(), session()
	local result
	local ok, message = xpcall(function()
		assert(first:load(userId).ok, "Real profile acquisition failed")
		for id in State.supported do
			assert(first:select(userId, id).ok and first:current(userId).coins == 200, "Nonstandard initial Coins")
		end
		assert(first:select(userId, "sparta").ok, "Cannot select verification civilization")
		local candidate = State.copy(first:current(userId))
		-- Synthetic values only in the explicitly isolated verification scope.
		candidate.coins, candidate.plans.training = 321, 1
		candidate.militaryResearch.project = { id = "army_training", remaining = 17 }
		local good = next(candidate.goods)
		candidate.goods[good] = 7
		candidate.buildings[3].output = 12
		assert(first:commit(userId, candidate), "Verification candidate failed validation")
		assert(first:select(userId, "egypt").ok, "Cannot select second civilization")
		candidate = State.copy(first:current(userId))
		candidate.coins = 654
		assert(first:commit(userId, candidate) and first:save(userId).ok, "Real profile save failed")
		local locked = second:load(userId)
		assert(not locked.ok and locked.reason == "profile_in_use", "Real concurrent session acquired a locked profile")
		assert(first:release(userId).ok, "Real profile final save/release failed")
		assert(second:load(userId).ok and second:select(userId, "sparta").ok, "Fresh real session could not reload")
		local restored = second:current(userId)
		assert(
			restored.coins == 321 and restored.plans.training == 1,
			"Coins or held plans did not survive real reload"
		)
		assert(
			restored.goods[good] == 7 and restored.buildings[3].output == 12,
			"Goods or production output did not survive"
		)
		assert(restored.militaryResearch.project.remaining == 17, "Offline time changed partial research")
		assert(second:select(userId, "egypt").ok and second:current(userId).coins == 654, "Civilization saves crossed")
		assert(
			second:select(userId, "rome").ok and second:current(userId).coins == 200,
			"Unrelated civilization changed"
		)
		assert(second:release(userId).ok, "Fresh session could not release")
		result = {
			ok = true,
			store = "MiniatureCivilizationProfilesV1",
			scope = scope,
			key = "player:" .. userId,
			civilizations = 13,
			spartaCoins = 321,
			egyptCoins = 654,
			romeCoins = 200,
			partialResearchRemaining = 17,
			concurrentSessionRejected = true,
			finalReleasesSucceeded = true,
		}
	end, debug.traceback)
	if not ok then
		pcall(function()
			first:release(userId)
			second:release(userId)
		end)
		return { ok = false, scope = scope, message = tostring(message) }
	end
	return result
end

return verify

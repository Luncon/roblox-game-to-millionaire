--!strict
-- The session layer owns validation, leases and retries. This adapter only selects
-- the isolated store and preserves UpdateAsync's acknowledgement/error semantics.
local PersistentProfileStore = {}
local NAME = "MiniatureCivilizationProfilesV1"
local PREFIX = "player:"

function PersistentProfileStore.new(options)
	options = options or {}
	local runService = options.runService or game:GetService("RunService")
	local scope = "Live"
	if runService:IsStudio() then
		scope = options.verificationScope
		assert(
			type(scope) == "string" and #scope <= 50 and string.match(scope, "^Verification_[%w_%-]+$") ~= nil,
			"Studio persistence requires an explicit isolated Verification_ scope"
		)
	else
		assert(options.verificationScope == nil, "Live servers cannot use verification storage")
	end
	local service = options.dataStoreService or game:GetService("DataStoreService")
	local backend = service:GetDataStore(NAME, scope)
	local store = {
		isPersistentProfileStore = true,
		keyPrefix = PREFIX,
		storageLabel = "DataStore:" .. NAME .. ":" .. scope,
	}
	function store:UpdateAsync(key, transform)
		assert(type(key) == "string" and type(transform) == "function", "Profile key and transform required")
		local digits = string.match(key, "^player:([1-9]%d*)$")
		local userId = if digits then tonumber(digits) else nil
		assert(
			userId ~= nil and userId <= 9007199254740991 and userId % 1 == 0 and tostring(userId) == digits,
			"Persistent profiles require a canonical positive player identity"
		)
		return backend:UpdateAsync(key, function(current, keyInfo)
			local candidate = transform(current)
			if candidate == nil then
				return nil
			end
			local metadata = if keyInfo then keyInfo:GetMetadata() else nil
			return candidate, { userId }, metadata
		end)
	end
	return table.freeze(store)
end

return table.freeze(PersistentProfileStore)

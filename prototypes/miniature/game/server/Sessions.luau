--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Config = require(Shared.Config)
local State = require(script.Parent.State)
local ClaimRegistry = require(game:GetService("ServerStorage").ClaimRegistry)
local Sessions = {}
local LEASE_SECONDS = 60

local function recordValid(record): boolean
	if type(record) ~= "table" or record.schemaVersion ~= 1 or type(record.civilizations) ~= "table" then
		return false
	end
	for key in record do
		if key ~= "schemaVersion" and key ~= "civilizations" and key ~= "lease" then
			return false
		end
	end
	for id, state in record.civilizations do
		if not State.validate(state, id) then
			return false
		end
	end
	if record.lease ~= nil then
		local lease = record.lease
		if
			type(lease) ~= "table"
			or type(lease.token) ~= "string"
			or #lease.token < 1
			or #lease.token > 128
			or type(lease.expiresAt) ~= "number"
			or not (lease.expiresAt >= 0 and lease.expiresAt < math.huge)
		then
			return false
		end
		for key in lease do
			if key ~= "token" and key ~= "expiresAt" then
				return false
			end
		end
	end
	return true
end

local function upgradedRecord(saved)
	if type(saved) ~= "table" or type(saved.civilizations) ~= "table" then
		return nil
	end
	local candidate = State.copy(saved)
	for id, state in saved.civilizations do
		local upgraded = State.upgrade(state, id)
		if not upgraded then
			return nil
		end
		candidate.civilizations[id] = upgraded
	end
	return if recordValid(candidate) then candidate else nil
end

function Sessions.new(options)
	assert(options.store and options.store.isFakeProfileStore == true, "Sessions require an injected fake store")
	assert(type(options.clock) == "function" and type(options.token) == "function", "Clock and token source required")
	local entries = {}
	local loads = {}
	local claims = ClaimRegistry.new(Config.plotCount, State.supported)
	local sessions = {}

	function sessions:writable(userId): boolean
		local entry = entries[userId]
		return entry ~= nil and entry.writable and not entry.closing and options.clock() < entry.expiresAt
	end

	function sessions:current(userId)
		if not self:writable(userId) then
			return nil
		end
		local claim = claims:get(userId)
		return if claim then entries[userId].record.civilizations[claim.civilizationId] else nil
	end

	function sessions:load(userId)
		if type(userId) ~= "number" or not State.integer(math.abs(userId), 9007199254740991) then
			return { ok = false, reason = "invalid_player" }
		end
		if entries[userId] then
			return { ok = self:writable(userId), reason = "already_loaded" }
		end
		if loads[userId] then
			return { ok = false, reason = "load_busy" }
		end
		local loading = { cancelled = false }
		loads[userId] = loading
		local now, token = options.clock(), options.token()
		assert(type(token) == "string" and #token > 0 and #token <= 128, "Invalid session token")
		local reason = "load_failed"
		local ok, record = pcall(function()
			return options.store:UpdateAsync("miniature-development:" .. userId, function(saved)
				local candidate = if saved == nil
					then { schemaVersion = 1, civilizations = {} }
					else upgradedRecord(saved)
				if not recordValid(candidate) then
					reason = "invalid_saved_data"
					return nil
				end
				if candidate.lease and candidate.lease.expiresAt > now then
					reason = "profile_in_use"
					return nil
				end
				candidate.lease = { token = token, expiresAt = now + LEASE_SECONDS }
				return candidate
			end)
		end)
		if not ok or record == nil then
			loads[userId] = nil
			return { ok = false, reason = reason }
		end
		entries[userId] = {
			record = record,
			token = token,
			expiresAt = record.lease.expiresAt,
			writable = true,
			closing = false,
			saving = false,
			revision = 0,
			claimEpoch = 0,
		}
		if loading.cancelled then
			local released = self:release(userId)
			loads[userId] = nil
			return { ok = false, reason = "load_cancelled", released = released.ok }
		end
		loads[userId] = nil
		return { ok = true }
	end

	function sessions:select(userId, civilizationId, previousCandidate)
		if not self:writable(userId) then
			return { ok = false, reason = "profile_not_writable" }
		end
		if type(civilizationId) ~= "string" or not State.supported[civilizationId] then
			return { ok = false, reason = "invalid_civilization" }
		end
		local previous = claims:get(userId)
		if previousCandidate and (not previous or not State.validate(previousCandidate, previous.civilizationId)) then
			return { ok = false, reason = "invalid_result" }
		end
		local destination = if previousCandidate
				and previous
				and previous.civilizationId == civilizationId
			then previousCandidate
			else entries[userId].record.civilizations[civilizationId]
		if destination then
			destination = State.upgrade(destination, civilizationId)
			if not destination then
				return { ok = false, reason = "invalid_saved_data" }
			end
		end
		local result = claims:switch(userId, civilizationId)
		if not result.ok then
			return result
		end
		local entry = entries[userId]
		if previousCandidate then
			entry.record.civilizations[previous.civilizationId] = previousCandidate
		end
		entry.record.civilizations[civilizationId] = destination or State.new(civilizationId, options.clock())
		entry.claimEpoch += 1
		entry.revision += 1
		return { ok = true, claim = result.claim }
	end

	function sessions:bump(userId)
		entries[userId].revision += 1
	end

	function sessions:invalidate(userId)
		local entry = entries[userId]
		if entry then
			entry.claimEpoch += 1
			entry.revision += 1
		end
	end

	function sessions:commit(userId, candidate): boolean
		local claim = claims:get(userId)
		if not self:writable(userId) or not claim or not State.validate(candidate, claim.civilizationId) then
			return false
		end
		entries[userId].record.civilizations[claim.civilizationId] = candidate
		self:bump(userId)
		return true
	end

	function sessions:snapshot(userId)
		local entry = entries[userId]
		local claim = claims:get(userId)
		return {
			loaded = entry ~= nil,
			writable = self:writable(userId),
			sessionId = if entry then entry.token else nil,
			claimEpoch = if entry then entry.claimEpoch else 0,
			revision = if entry then entry.revision else 0,
			claim = claim,
			state = if entry and claim then State.copy(entry.record.civilizations[claim.civilizationId]) else nil,
			claims = claims:snapshot(),
		}
	end

	local function write(userId, release)
		local entry = entries[userId]
		if not entry or not entry.writable or options.clock() >= entry.expiresAt or (entry.closing and not release) then
			return { ok = false, reason = "profile_not_writable" }
		end
		if entry.saving then
			return { ok = false, reason = "save_busy" }
		end
		if not recordValid(entry.record) then
			entry.writable = false
			return { ok = false, reason = "invalid_state" }
		end
		local now = options.clock()
		local candidate = State.copy(entry.record)
		candidate.lease = if release then nil else { token = entry.token, expiresAt = now + LEASE_SECONDS }
		entry.saving = true
		local ok, saved = pcall(function()
			return options.store:UpdateAsync("miniature-development:" .. userId, function(current)
				if
					not recordValid(current)
					or not current.lease
					or current.lease.token ~= entry.token
					or current.lease.expiresAt <= options.clock()
				then
					return nil
				end
				return State.copy(candidate)
			end)
		end)
		entry.saving = false
		if not ok then
			return { ok = false, reason = "save_failed" }
		end
		if saved == nil then
			entry.writable = false
			return { ok = false, reason = "authority_lost" }
		end
		if not release then
			entry.expiresAt = saved.lease.expiresAt
			entry.record.lease = State.copy(saved.lease)
		end
		return { ok = true }
	end

	function sessions:save(userId)
		return write(userId, false)
	end

	function sessions:release(userId)
		if loads[userId] then
			loads[userId].cancelled = true
		end
		local entry = entries[userId]
		if not entry and loads[userId] then
			return { ok = false, reason = "load_busy" }
		end
		if entry then
			entry.closing = true
		end
		local result = write(userId, true)
		if result.reason == "save_busy" or result.reason == "save_failed" then
			return result
		end
		claims:release(userId)
		entries[userId] = nil
		return result
	end

	function sessions:abandon(userId)
		claims:release(userId)
		entries[userId] = nil
	end

	return sessions
end

return Sessions

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
	local store = options.store
	assert(
		store and (store.isFakeProfileStore == true or store.isPersistentProfileStore == true),
		"Reviewed profile store required"
	)
	local persistent = store.isPersistentProfileStore == true
	local prefix = store.keyPrefix or (if persistent then "player:" else "miniature-development:")
	assert(type(prefix) == "string" and #prefix > 0 and #prefix <= 24, "Invalid profile key prefix")
	assert(type(options.clock) == "function" and type(options.token) == "function", "Clock and token source required")
	local entries = {}
	local loads = {}
	local claims = ClaimRegistry.new(Config.plotCount, State.supported)
	local sessions = {}
	local function lose(entry, reason)
		entry.terminal = entry.terminal or reason
		entry.writable = false
		entry.profileStatus, entry.profileReason = "lost", entry.terminal
	end
	local function key(userId): string
		return prefix .. tostring(userId)
	end
	-- An acquisition can commit even when its acknowledgement throws. Cleanup is
	-- token-only: an uninitialized session must never write civilization defaults.
	local function cleanup(userId, loading)
		local ok = pcall(function()
			store:UpdateAsync(key(userId), function(current)
				if not recordValid(current) or not current.lease or current.lease.token ~= loading.token then
					return nil
				end
				local candidate = State.copy(current)
				candidate.lease = nil
				return candidate
			end)
		end)
		return { ok = ok, reason = if ok then nil else "save_failed" }
	end

	function sessions:writable(userId): boolean
		local entry = entries[userId]
		if not entry or not entry.writable or entry.terminal then
			return false
		end
		if options.clock() >= entry.expiresAt then
			lose(entry, "lease_expired")
			return false
		end
		return not entry.closing
	end

	function sessions:current(userId)
		if not self:writable(userId) then
			return nil
		end
		local claim = claims:get(userId)
		return if claim then entries[userId].record.civilizations[claim.civilizationId] else nil
	end

	function sessions:load(userId)
		if
			type(userId) ~= "number"
			or not State.integer(math.abs(userId), 9007199254740991)
			or userId == 0
			or (persistent and userId < 0)
		then
			return { ok = false, reason = "invalid_player" }
		end
		if entries[userId] then
			return { ok = self:writable(userId), reason = "already_loaded" }
		end
		local loading = loads[userId]
		if loading and (loading.inFlight or loading.cancelled) then
			return { ok = false, reason = "load_busy" }
		end
		if not loading then
			local token = options.token()
			assert(type(token) == "string" and #token > 0 and #token <= 128, "Invalid session token")
			loading = { cancelled = false, token = token }
			loads[userId] = loading
		end
		loading.inFlight, loading.profileStatus, loading.profileReason = true, "loading", nil
		local token = loading.token
		local reason = "load_failed"
		local ok, record = pcall(function()
			return store:UpdateAsync(key(userId), function(saved)
				if loads[userId] ~= loading or loading.cancelled then
					reason = "load_cancelled"
					return nil
				end
				local candidate = if saved == nil
					then { schemaVersion = 1, civilizations = {} }
					else upgradedRecord(saved)
				if not recordValid(candidate) then
					reason = "invalid_saved_data"
					return nil
				end
				local now = options.clock()
				if candidate.lease and candidate.lease.token ~= token and candidate.lease.expiresAt > now then
					reason = "profile_in_use"
					return nil
				end
				candidate.lease = { token = token, expiresAt = now + LEASE_SECONDS }
				return candidate
			end)
		end)
		loading.inFlight = false
		if loads[userId] ~= loading or loading.cancelled then
			loading.inFlight = true
			local released = cleanup(userId, loading)
			loading.inFlight = false
			if released.ok and loads[userId] == loading then
				loads[userId] = nil
			end
			return { ok = false, reason = "load_cancelled", released = released.ok }
		end
		if not ok or record == nil or not recordValid(record) or not record.lease or record.lease.token ~= token then
			loading.profileStatus = if reason == "profile_in_use" then "locked" else "failed"
			loading.profileReason = reason
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
			profileStatus = "ready",
		}
		loads[userId] = nil
		if not self:writable(userId) then
			return { ok = false, reason = "lease_expired" }
		end
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
		local writable = self:writable(userId)
		local status = entry or loads[userId]
		local claim = claims:get(userId)
		return {
			loaded = entry ~= nil,
			writable = writable,
			profileStatus = if status then status.profileStatus else "not_loaded",
			profileReason = if status then status.profileReason else nil,
			lastSavedAt = if entry then entry.lastSavedAt else nil,
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
		if entry and options.clock() >= entry.expiresAt then
			lose(entry, "lease_expired")
		end
		if not entry or not entry.writable or entry.terminal or (entry.closing and not release) then
			return { ok = false, reason = "profile_not_writable" }
		end
		if entry.saving then
			return { ok = false, reason = "save_busy" }
		end
		if not recordValid(entry.record) then
			lose(entry, "invalid_state")
			return { ok = false, reason = "invalid_state" }
		end
		local candidate = State.copy(entry.record)
		entry.saving = true
		entry.profileStatus, entry.profileReason = if release then "closing" else "saving", nil
		local savedAt
		local ok, saved = pcall(function()
			return store:UpdateAsync(key(userId), function(current)
				local now = options.clock()
				if
					entries[userId] ~= entry
					or entry.terminal
					or now >= entry.expiresAt
					or not recordValid(current)
					or not current.lease
					or current.lease.token ~= entry.token
					or current.lease.expiresAt <= now
				then
					return nil
				end
				local result = State.copy(candidate)
				result.lease = if release then nil else { token = entry.token, expiresAt = now + LEASE_SECONDS }
				savedAt = now
				return result
			end)
		end)
		entry.saving = false
		if entries[userId] ~= entry then
			return { ok = false, reason = "stale_session" }
		end
		if options.clock() >= entry.expiresAt then
			lose(entry, "lease_expired")
		end
		if entry.terminal then
			return { ok = false, reason = entry.terminal }
		end
		if not ok then
			entry.profileStatus, entry.profileReason = if entry.closing then "closing" else "ready", "save_failed"
			return { ok = false, reason = "save_failed" }
		end
		if saved == nil then
			lose(entry, "authority_lost")
			return { ok = false, reason = "authority_lost" }
		end
		if
			not recordValid(saved)
			or (not release and (not saved.lease or saved.lease.token ~= entry.token))
			or (release and saved.lease ~= nil)
		then
			lose(entry, "invalid_saved_data")
			return { ok = false, reason = "invalid_saved_data" }
		end
		entry.lastSavedAt = savedAt
		entry.profileStatus, entry.profileReason = if entry.closing then "closing" else "ready", nil
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
		local loading = loads[userId]
		if loading then
			loading.cancelled, loading.profileStatus = true, "closing"
		end
		local entry = entries[userId]
		if not entry and loading then
			if loading.inFlight then
				return { ok = false, reason = "load_busy" }
			end
			loading.inFlight = true
			local result = cleanup(userId, loading)
			loading.inFlight = false
			if result.ok and loads[userId] == loading then
				loads[userId] = nil
			end
			return result
		end
		if entry then
			entry.closing, entry.profileStatus = true, "closing"
		else
			return { ok = true }
		end
		local result = write(userId, true)
		if result.reason == "save_busy" or result.reason == "save_failed" then
			return result
		end
		if entries[userId] == entry then
			claims:release(userId)
			entries[userId] = nil
		end
		return result
	end

	function sessions:abandon(userId)
		if loads[userId] then
			loads[userId].cancelled = true
			loads[userId] = nil
		end
		if entries[userId] then
			lose(entries[userId], "abandoned")
		end
		claims:release(userId)
		entries[userId] = nil
	end

	return sessions
end

return Sessions

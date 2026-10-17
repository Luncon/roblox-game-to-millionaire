--!strict

local HttpService = game:GetService("HttpService")
local Data = require(script.Parent.ProfileData)
local ProfileService = {}

local function validUser(value: any, allowTestUserIds: boolean): boolean
	return type(value) == "number" and value ~= 0 and math.abs(value) <= 9007199254740991
		and value % 1 == 0 and (value > 0 or allowTestUserIds)
end

local function copyCivilizations(values: any): any
	local copied = {}
	for id, state in values do copied[id] = Data.copyState(state,id) end
	return copied
end

function ProfileService.new(store: any, options: any?)
	options = options or {}
	local clock = options.clock or os.time
	local waitFor = options.wait or task.wait
	local leaseSeconds = options.leaseSeconds or 120
	local saveInterval = options.saveInterval or 30
	local attempts = options.retry or 3
	assert(leaseSeconds > 0 and saveInterval > 0 and attempts >= 1 and attempts % 1 == 0, "Invalid persistence timing")
	local newToken = options.newToken or function() return HttpService:GenerateGUID(false) end
	local sessionId = options.sessionId or HttpService:GenerateGUID(false)
	local entries: { [number]: any } = {}
	local generation, stopping, autosaving = 0, false, false
	local service = {}

	local function status(entry: any): any
		return { status = entry.phase, reason = entry.reason, savedAt = entry.savedAt, dirty = entry.dirty }
	end

	local function publish(entry: any, phase: string, reason: string?)
		entry.phase, entry.reason = phase, reason
		if options.onStatus then
			local snapshot = status(entry)
			-- Storage transforms never invoke gameplay or callbacks. Status observers also
			-- cannot make set/isWritable yield while the economy is committing a change.
			task.defer(function()
				local ok, message = pcall(options.onStatus, entry.userId, snapshot)
				if not ok then warn("Profile status observer failed: " .. tostring(message)) end
			end)
		end
	end

	local function lose(entry: any, reason: string)
		if entry.terminal then return end
		entry.terminal = reason
		publish(entry, "lost", reason)
	end

	local function lock(entry: any)
		entry.operations += 1
		while entry.busy do entry.changed.Event:Wait() end
		entry.busy = true
	end

	local function unlock(entry: any)
		entry.busy = false
		entry.operations -= 1
		entry.changed:Fire()
		if entry.releaseResult and entry.operations == 0 then entry.changed:Destroy() end
	end

	local function metadata(keyInfo: any, userId: number): (any, any)
		if keyInfo then return keyInfo:GetUserIds(), keyInfo:GetMetadata() end
		local userIds = if userId > 0 then { userId } else {}
		return userIds, {}
	end

	-- One caller holds the entry lock throughout every retry. A replayed transform
	-- only validates/copies its arguments; it never changes the live profile.
	local function update(entry: any, transform: any): (boolean, any, string?)
		for attempt = 1, attempts do
			local rejection: string? = nil
			local ok, result = pcall(function()
				return store:UpdateAsync("User_" .. tostring(entry.userId), function(raw: any, keyInfo: any)
					local value, reason = transform(raw)
					rejection = reason
					if not value then return nil end
					local userIds, extra = metadata(keyInfo, entry.userId)
					return value, userIds, extra
				end)
			end)
			if ok then return true, result, rejection end
			if attempt < attempts then waitFor(2 ^ (attempt - 1)) end
		end
		return false, nil, nil
	end

	local function writable(entry: any): boolean
		if not entry or not entry.loaded or entry.closing or entry.terminal or stopping then return false end
		if entry.expiresAt <= clock() then lose(entry, "lease_expired"); return false end
		return true
	end

	function service:isWritable(userId: number): boolean
		return writable(entries[userId])
	end

	function service:status(userId: number): any
		local entry = entries[userId]
		if not entry then return { status = "not_loaded", dirty = false } end
		if entry.loaded and not entry.closing then writable(entry) end
		return status(entry)
	end

	function service:get(userId: number, civilizationId: string): any
		local entry = entries[userId]
		if not Data.isCivilization(civilizationId) or not writable(entry) then return nil end
		local state = entry.civilizations[civilizationId]
		return if state then Data.copyState(state,civilizationId) else Data.defaultState()
	end

	function service:getAll(userId: number): any
		local entry = entries[userId]
		return if writable(entry) then copyCivilizations(entry.civilizations) else nil
	end

	function service:set(userId: number, civilizationId: string, state: any): boolean
		local entry = entries[userId]
		if not writable(entry) or not Data.isCivilization(civilizationId) then return false end
		local copied = Data.copyState(state,civilizationId)
		if not copied then return false end
		entry.civilizations[civilizationId] = copied
		entry.revision += 1
		entry.dirty = true
		return true
	end

	function service:load(userId: number): any
		if not validUser(userId, options.allowTestUserIds == true) then return { ok = false, reason = "invalid_user" } end
		if stopping then return { ok = false, reason = "not_ready" } end
		local entry = entries[userId]
		if not entry or entry.phase == "closed" then
			generation += 1
			entry = {
				userId = userId, token = sessionId .. ":" .. tostring(generation) .. ":" .. newToken(),
				phase = "not_loaded", civilizations = {}, revision = 0, dirty = false, loaded = false,
				closing = false, busy = false, operations = 0, expiresAt = 0, changed = Instance.new("BindableEvent"),
			}
			entries[userId] = entry
		end
		lock(entry)
		if entry.closing or entry.terminal or stopping then
			unlock(entry)
			return { ok = false, reason = entry.terminal or "not_ready" }
		end
		if entry.loaded then
			local ok = writable(entry)
			unlock(entry)
			return { ok = ok, reason = if ok then nil else entry.terminal or "not_ready" }
		end
		publish(entry, "loading", nil)
		local succeeded, raw, reason = update(entry, function(value: any)
			if entry.closing or stopping then return nil, "not_ready" end
			local profile = if value == nil then { schemaVersion = 1, civilizations = {} } else Data.decode(value)
			if not profile then return nil, "invalid_data" end
			local now = clock()
			if profile.session and profile.session.token ~= entry.token and profile.session.expiresAt > now then
				return nil, "session_busy"
			end
			profile.session = { token = entry.token, expiresAt = now + leaseSeconds }
			return profile, nil
		end)
		local profile = if succeeded then Data.decode(raw) else nil
		if profile and profile.session and profile.session.token == entry.token then
			entry.loaded, entry.civilizations = true, profile.civilizations
			entry.expiresAt, entry.savedAt = profile.session.expiresAt, profile.savedAt
			if entry.closing or stopping then
				unlock(entry)
				return { ok = false, reason = "not_ready" }
			end
			if not writable(entry) then unlock(entry); return { ok = false, reason = entry.terminal } end
			publish(entry, "ready", nil)
			unlock(entry)
			return { ok = true }
		end
		reason = reason or "load_failed"
		if not entry.closing then publish(entry, if reason == "session_busy" then "locked" else "failed", reason) end
		unlock(entry)
		return { ok = false, reason = reason }
	end

	local function write(entry: any, releasing: boolean): any
		local snapshot = copyCivilizations(entry.civilizations)
		local revision = entry.revision
		local succeeded, raw, reason = update(entry, function(value: any)
			local profile = Data.decode(value)
			if not profile then return nil, "invalid_data" end
			if not profile.session or profile.session.token ~= entry.token then return nil, "lease_lost" end
			local now = clock()
			if entry.terminal then return nil, entry.terminal end
			if profile.session.expiresAt <= now then return nil, "lease_expired" end
			profile.civilizations = snapshot
			profile.savedAt = now
			profile.session = if releasing then nil else { token = entry.token, expiresAt = now + leaseSeconds }
			return profile, nil
		end)
		if reason then
			lose(entry, reason)
			return { ok = false, reason = reason }
		end
		if not succeeded then
			if entry.expiresAt <= clock() then lose(entry, "lease_expired") end
			local failure = if releasing then "release_failed" else "save_failed"
			if not entry.terminal then publish(entry, if releasing then "releasing" else "ready", failure) end
			return { ok = false, reason = entry.terminal or failure }
		end
		local profile = Data.decode(raw)
		if not profile then lose(entry, "invalid_data"); return { ok = false, reason = "invalid_data" } end
		-- A local expiry/loss observed while storage yielded remains terminal even
		-- if a delayed response reports a previously successful renewal.
		if entry.terminal then return { ok = false, reason = entry.terminal } end
		entry.savedAt = profile.savedAt
		if profile.session then entry.expiresAt = profile.session.expiresAt end
		entry.dirty = entry.revision ~= revision
		publish(entry, if releasing then "closed" elseif entry.closing then "releasing" else "ready", nil)
		return { ok = true }
	end

	function service:save(userId: number): any
		local entry = entries[userId]
		if not entry or entry.closing then return { ok = false, reason = "not_ready" } end
		lock(entry)
		if not writable(entry) then unlock(entry); return { ok = false, reason = entry.terminal or "not_ready" } end
		publish(entry, "saving", nil)
		local result = write(entry, false)
		unlock(entry)
		return result
	end

	function service:release(userId: number): any
		local entry = entries[userId]
		if not entry then return { ok = true } end
		if entry.releaseResult then return table.clone(entry.releaseResult) end
		-- Freeze before waiting behind a yielding save/load. Every caller then joins
		-- the same serialized final operation and observes its stored result.
		entry.closing = true
		lock(entry)
		if entry.releaseResult then local result = table.clone(entry.releaseResult); unlock(entry); return result end
		publish(entry, "releasing", nil)
		local result
		if entry.terminal then
			result = { ok = false, reason = entry.terminal }
		elseif entry.loaded then
			result = write(entry, true)
		else
			-- An acquisition may have committed even when every request threw. Only
			-- remove this exact token; never replace data with an uninitialized state.
			local succeeded, _, reason = update(entry, function(value: any)
				local profile = Data.decode(value)
				if not profile or not profile.session or profile.session.token ~= entry.token then return nil, nil end
				if profile.session.expiresAt <= clock() then return nil, "lease_expired" end
				profile.session = nil
				return profile, nil
			end)
			result = { ok = succeeded and reason == nil, reason = reason or (if succeeded then nil else "release_failed") }
		end
		entry.releaseResult = result
		publish(entry, "closed", result.reason)
		unlock(entry)
		return table.clone(result)
	end

	function service:startAutosave()
		if autosaving or stopping then return end
		autosaving = true
		task.spawn(function()
			while not stopping do
				waitFor(saveInterval)
				if stopping then break end
				for userId, entry in entries do
					if not entry.busy and writable(entry) then task.spawn(function() service:save(userId) end) end
				end
				-- An injected deterministic wait need not yield; never spin the scheduler.
				task.wait()
			end
		end)
	end

	function service:shutdown(timeout: number?): any
		stopping = true
		local pending, failures = 0, {}
		for userId, entry in entries do
			entry.closing = true
			pending += 1
			task.spawn(function()
				local result = service:release(userId)
				if not result.ok then failures[userId] = result.reason end
				pending -= 1
			end)
		end
		local deadline = os.clock() + (timeout or 25)
		while pending > 0 and os.clock() < deadline do task.wait(.01) end
		return { ok = pending == 0 and next(failures) == nil,
			reason = if pending > 0 then "shutdown_timeout" elseif next(failures) then "release_failed" else nil,
			pending = pending, failures = failures }
	end

	function service:destroy(timeout: number?): any
		return self:shutdown(timeout)
	end

	return service
end

return ProfileService

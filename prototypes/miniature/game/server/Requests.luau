--!strict
local State = require(script.Parent.State)
local Requests = {}

local function same(left, right): boolean
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in left do
		if not same(value, right[key]) then
			return false
		end
	end
	for key in right do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function bounded(value, depth, budget): boolean
	budget.nodes += 1
	if budget.nodes > 128 then
		return false
	end
	local kind = type(value)
	if kind == "number" then
		return value == value and math.abs(value) <= 1000000000
	elseif kind == "string" then
		budget.bytes += #value
		return #value <= 128 and budget.bytes <= 4096
	elseif kind == "boolean" then
		return true
	elseif kind ~= "table" or depth >= 3 then
		return false
	end
	local count = 0
	for key, child in value do
		count += 1
		if count > 32 or type(key) ~= "string" or #key > 32 or not bounded(child, depth + 1, budget) then
			return false
		end
	end
	return true
end

local function valid(payload): boolean
	if type(payload) ~= "table" then
		return false
	end
	for key in payload do
		if
			key ~= "requestId"
			and key ~= "sessionId"
			and key ~= "claimEpoch"
			and key ~= "revision"
			and key ~= "args"
		then
			return false
		end
	end
	return type(payload.requestId) == "string"
		and #payload.requestId > 0
		and #payload.requestId <= 64
		and type(payload.sessionId) == "string"
		and #payload.sessionId > 0
		and #payload.sessionId <= 128
		and State.integer(payload.claimEpoch, 1000000000)
		and State.integer(payload.revision, 9007199254740991)
		and type(payload.args) == "table"
		and bounded(payload.args, 0, { nodes = 0, bytes = 0 })
end

function Requests.new(options)
	local clients = {}
	local gateway = {}

	function gateway:remove(userId)
		clients[userId] = nil
	end

	function gateway:size(): number
		local count = 0
		for _ in clients do
			count += 1
		end
		return count
	end

	function gateway:handle(userId, action, payload)
		local now = options.clock()
		local client = clients[userId]
		if not client then
			client = { tokens = 8, last = now, receipts = {}, order = {} }
			clients[userId] = client
		end
		client.tokens = math.min(8, client.tokens + math.max(0, now - client.last) * 4)
		client.last = now
		if client.tokens < 1 then
			return { ok = false, reason = "rate_limited" }
		end
		client.tokens -= 1
		if not valid(payload) or type(action) ~= "string" then
			return { ok = false, reason = "invalid_request" }
		end
		local view = options.sessions:snapshot(userId)
		if not view.writable then
			return { ok = false, reason = "profile_not_writable" }
		end
		if payload.sessionId ~= view.sessionId then
			return { ok = false, reason = "stale_session" }
		end
		local context = options.context(userId, action, payload.args)
		if not context.alive then
			return { ok = false, reason = "owner_not_alive" }
		end
		if not context.inRange then
			return { ok = false, reason = "out_of_range" }
		end
		local cached = client.receipts[payload.requestId]
		if cached and cached.epoch == view.claimEpoch and cached.sessionId == view.sessionId then
			if cached.action ~= action or not same(cached.payload, payload) then
				return { ok = false, reason = "request_id_reused" }
			end
			return State.copy(cached.result)
		end
		if payload.claimEpoch ~= view.claimEpoch then
			return { ok = false, reason = "stale_session" }
		end
		if payload.revision ~= view.revision then
			return { ok = false, reason = "stale_revision" }
		end
		local result, timing
		if action == "select" then
			local previousCandidate
			if view.state and options.prepareSelection then
				previousCandidate, timing = options.prepareSelection(view.state, userId)
			end
			result = options.sessions:select(userId, payload.args.civilizationId, previousCandidate)
		else
			local handler = options.handlers[action]
			if not handler or not view.claim then
				return { ok = false, reason = "unavailable_action" }
			end
			local candidate = view.state
			result, timing = handler(candidate, payload.args, userId)
			if result.ok then
				if not options.sessions:commit(userId, candidate) then
					return { ok = false, reason = "invalid_result" }
				end
			end
		end
		if result.ok then
			if options.afterCommit then
				options.afterCommit(userId, action, result, timing)
			end
			client.receipts[payload.requestId] = {
				epoch = options.sessions:snapshot(userId).claimEpoch,
				sessionId = view.sessionId,
				action = action,
				payload = State.copy(payload),
				result = State.copy(result),
			}
			table.insert(client.order, payload.requestId)
			if #client.order > 32 then
				client.receipts[table.remove(client.order, 1)] = nil
			end
		end
		return result
	end

	return gateway
end

return Requests

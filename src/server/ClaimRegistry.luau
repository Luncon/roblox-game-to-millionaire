--!strict

export type Claim = { civilizationId: string, plotId: number }
export type Result = { ok: boolean, reason: string?, claim: Claim? }

local ClaimRegistry = {}

local function copyClaim(claim: Claim): Claim
	return { civilizationId = claim.civilizationId, plotId = claim.plotId }
end

function ClaimRegistry.new(plotCount: number, supported: { [string]: boolean })
	assert(plotCount > 0 and plotCount % 1 == 0, "Plot count must be a positive integer")
	local claims: { [number]: Claim } = {}
	local civilizationOwners: { [string]: number } = {}
	local plotOwners: { [number]: number } = {}
	local registry = {}

	function registry:get(playerId: number): Claim?
		local claim = claims[playerId]
		return if claim then copyClaim(claim) else nil
	end

	function registry:claim(playerId: number, civilizationId: unknown): Result
		if type(civilizationId) ~= "string" or not supported[civilizationId] then
			return { ok = false, reason = "invalid" }
		end
		local existing = claims[playerId]
		if existing then
			if existing.civilizationId == civilizationId then
				return { ok = true, claim = copyClaim(existing) }
			end
			return { ok = false, reason = "already_claimed" }
		end
		if civilizationOwners[civilizationId] ~= nil then
			return { ok = false, reason = "unavailable" }
		end
		for plotId = 1, plotCount do
			if plotOwners[plotId] == nil then
				local claim = { civilizationId = civilizationId, plotId = plotId }
				-- No yielding between checking availability and reserving both resources.
				claims[playerId] = claim
				civilizationOwners[civilizationId] = playerId
				plotOwners[plotId] = playerId
				return { ok = true, claim = copyClaim(claim) }
			end
		end
		return { ok = false, reason = "full" }
	end

	function registry:release(playerId: number): Claim?
		local claim = claims[playerId]
		if not claim then
			return nil
		end
		claims[playerId] = nil
		civilizationOwners[claim.civilizationId] = nil
		plotOwners[claim.plotId] = nil
		return copyClaim(claim)
	end

	function registry:snapshot(): { [string]: { ownerId: number?, plotId: number? } }
		local result = {}
		for civilizationId in supported do
			local ownerId = civilizationOwners[civilizationId]
			local claim = if ownerId then claims[ownerId] else nil
			result[civilizationId] = { ownerId = ownerId, plotId = if claim then claim.plotId else nil }
		end
		return result
	end

	return registry
end

return ClaimRegistry

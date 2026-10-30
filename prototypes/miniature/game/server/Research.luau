--!strict
local Catalog = require(game:GetService("ReplicatedStorage").MiniatureGame.Catalog)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.Config)
local Research = {}

function Research.start(state, id)
	if not Config.researchEnabled then
		return { ok = false, reason = "research_disabled" }
	end
	local definition = if type(id) == "string" then Catalog.research[id] else nil
	if not definition then
		return { ok = false, reason = "invalid_research" }
	end
	if not state.hallUpgraded then
		return { ok = false, reason = "hall_required" }
	end
	if state.research.project then
		return { ok = false, reason = "research_busy" }
	end
	if state.research.completed[id] then
		return { ok = false, reason = "research_complete" }
	end
	if definition.predecessor and not state.research.completed[definition.predecessor] then
		return { ok = false, reason = "research_predecessor" }
	end
	if state.coins < definition.price then
		return { ok = false, reason = "insufficient_resources" }
	end
	state.coins -= definition.price
	state.research.project = { id = id, remaining = definition.duration }
	return { ok = true, researchId = id }
end

-- Only the caller's active authoritative elapsed time advances a project.
function Research.step(state, elapsed: number, active: boolean)
	local project = state.research.project
	if
		not Config.researchEnabled
		or not active
		or not project
		or type(elapsed) ~= "number"
		or not (elapsed > 0 and elapsed < math.huge)
	then
		return { changed = false }
	end
	if elapsed < project.remaining then
		project.remaining -= elapsed
		return { changed = true }
	end
	state.research.completed[project.id] = true
	state.research.project = nil
	return { changed = true, completed = project.id, resetProduction = project.id == "work" }
end

return Research

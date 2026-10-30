--!strict
local Catalog = require(game:GetService("ReplicatedStorage").MiniatureGame.MilitaryResearch)
local Research = {}
function Research.start(state, id)
	local definition = if type(id) == "string" then Catalog.nodes[id] else nil
	if not definition then
		return { ok = false, reason = "invalid_research" }
	end
	local progress = state.militaryResearch
	if not Catalog.validate(progress) then
		return { ok = false, reason = "invalid_research_state" }
	end
	if progress.project then
		return { ok = false, reason = "research_busy" }
	end
	if progress.completed[id] then
		return { ok = false, reason = "research_complete" }
	end
	if definition.predecessor and not progress.completed[definition.predecessor] then
		return { ok = false, reason = "research_predecessor" }
	end
	if state.coins < definition.price then
		return { ok = false, reason = "insufficient_resources" }
	end
	state.coins -= definition.price
	progress.project = { id = id, remaining = definition.duration }
	return { ok = true, researchId = id }
end
function Research.step(state, elapsed: number, active: boolean)
	local progress = state.militaryResearch
	if
		not active
		or type(elapsed) ~= "number"
		or not (elapsed > 0 and elapsed < math.huge)
		or not progress
		or not progress.project
		or not Catalog.validate(progress)
	then
		return { changed = false }
	end
	local project = progress.project
	if elapsed < project.remaining then
		project.remaining -= elapsed
		return { changed = true }
	end
	progress.completed[project.id] = true
	progress.project = nil
	return { changed = true, completed = project.id }
end
return table.freeze(Research)

--!strict
local Economy = require(script.Parent.Economy)
local Actions = require(script.Parent.Actions)
local Research = require(script.Parent.Research)
local ActiveTime = {}

-- Call at the last active endpoint before switching or losing a life. Callers
-- supply fresh transient clocks on reactivation; partial/offline time never saves.
-- merchantNow separates the wall-clock stock cycle from monotonic production.
function ActiveTime.step(state, clocks, now: number, elapsed: number, active: boolean, merchantNow: number?)
	local produced = Economy.step(state, clocks, now, active)
	local restocked = Actions.restock(state, merchantNow or now)
	local research = Research.step(state, elapsed, active)
	if research.resetProduction then
		for id in clocks do
			clocks[id] = now
		end
	end
	local automated = active and Actions.automate(state)
	local revisionChanged = produced or restocked or research.completed ~= nil or automated
	return {
		clocks = clocks,
		changed = revisionChanged or research.changed,
		revisionChanged = revisionChanged,
		research = research,
	}
end

return ActiveTime

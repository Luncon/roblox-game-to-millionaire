--!strict

-- Shared test opposition for the current prototype. Restart after toggling.
return table.freeze({
	enabled=true,
	respawnDelay=10,
	slots=table.freeze({
		table.freeze({id="melee1",kind="warrior",offset=Vector3.new(-12,0,0)}),
		table.freeze({id="melee2",kind="warrior",offset=Vector3.new(12,0,0)}),
		table.freeze({id="ranged",kind="ranged",offset=Vector3.new(0,0,-16)}),
	}),
})

--!strict

local phases = {
	warrior = table.freeze({windup=.2,contact=.15,recovery=.65}),
	ranged = table.freeze({windup=.35,contact=.15,recovery=1.5}),
}
return table.freeze({
	phases=table.freeze(phases),
	meleeRadius=4,minimumSeparation=3,separationStep=4,engagementSlots=6,
	targetHysteresis=8,targetRetentionRange=8,crowdingPenalty=5,
	defenseRadius=14,defenseBonus=18,
	rangedNear=22,rangedFar=35,retreatTrigger=12,retreatSafe=18,
	retreatStep=10,retreatLimit=18,retreatSpeed=8,retreatDuration=3,
	sidestepDistance=7,sidestepInterval=1.2,closeDistance=18,
})

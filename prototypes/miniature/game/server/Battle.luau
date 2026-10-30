--!strict
-- Pure transient simulation. The controller owns claim/write authority and calls
-- removeArmy immediately when that authority ends. No player, civilian, Humanoid,
-- saved economy or production service is registered here.
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.BattleConfig)
local Military = require(game:GetService("ReplicatedStorage").MiniatureGame.MilitaryResearch)

export type Team = string | number
export type Role = "melee" | "ranged" | "medic" | "mounted"
export type Slot = { id: string, role: Role, buildingId: string, index: number, x: number, z: number }
export type OutpostDefinition = { id: string, x: number, z: number, radius: number, lineId: Team, nextId: string? }
export type Result = { ok: boolean, reason: string?, elapsed: number? }
export type Actor = {
	id: string,
	team: Team,
	civilizationId: string,
	role: Role,
	profile: Config.RoleStats?,
	buildingId: string?,
	index: number,
	formationIndex: number,
	slotId: string?,
	garrisonId: string?,
	x: number,
	z: number,
	homeX: number,
	homeZ: number,
	health: number,
	maxHealth: number,
	alive: boolean,
	life: number,
	respawnAt: number?,
	targetId: string?,
	targetLife: number?,
	targetOutpostId: string?,
	phase: string,
	combatPhase: string?,
	phaseStartedAt: number?,
	phaseDuration: number?,
	moving: boolean?,
	lastHitAt: number?,
	lastHealAt: number?,
	bandageThrownAt: number?,
	headingX: number,
	headingZ: number,
	contactAt: number?,
	contactOutpostId: string?,
	nextAttack: number,
	nextHeal: number,
	recoveryUntil: number,
}
export type Army = {
	civilizationId: string,
	lineId: Team,
	targetId: string?,
	manual: boolean,
	slots: { [string]: string },
	completedResearch: Military.Completed,
	capacity: number,
	profiles: { [string]: Config.RoleStats },
	buildingTargets: { [string]: string },
	knownBuildings: { [string]: boolean },
}
export type Outpost = {
	id: string,
	x: number,
	z: number,
	radius: number,
	lineId: Team,
	nextId: string?,
	ownerTeam: Team?,
	ownerCivilizationId: string?,
	captureTeam: Team?,
	progress: number,
	status: string,
}
export type Event = {
	kind: string,
	time: number,
	x: number,
	z: number,
	actorId: string?,
	actorLife: number?,
	targetId: string?,
	targetLife: number?,
	targetX: number?,
	targetZ: number?,
	outpostId: string?,
	team: Team?,
	civilizationId: string?,
	amount: number?,
}
export type BattleView = {
	actors: { [string]: Actor? },
	outposts: { [string]: Outpost? },
	armies: { [Team]: Army? },
}
export type BehaviorHooks = {
	valid: (Actor, Actor, number) -> boolean,
	hit: (Actor, Actor, number) -> boolean,
	heal: (Actor, Actor, number, number) -> number,
	visible: (Actor, Actor) -> boolean,
	event: (string, Actor, Actor?, number?) -> (),
}
export type Behavior = {
	stepActors: (Behavior, BattleView, { Actor }, number, number, BehaviorHooks) -> (),
	destroy: (Behavior) -> (),
}
export type Options = { visible: ((Actor, Actor) -> boolean)?, behavior: Behavior? }
export type OrderOptions = { buildingTargets: { [string]: string }, knownMilitaryBuildingIds: { string } }
export type Simulation = BattleView & {
	events: { Event },
	_postOrder: { string },
	_nextLife: number,
	_time: number?,
	_visible: (Actor, Actor) -> boolean,
	_behavior: Behavior?,
	syncArmy: (Simulation, Team, string, Team, { Slot }, number, Military.Completed?, OrderOptions?) -> Result,
	removeArmy: (Simulation, Team) -> (),
	command: (Simulation, Team, string, { string }?) -> Result,
	step: (Simulation, number, number) -> Result,
}

type CaptureInfo = { team: Team?, clear: boolean, contested: boolean }
local Battle = {}
Battle.__index = Battle

local function finite(value: number): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function identifier(value: string): boolean
	return type(value) == "string" and #value > 0 and #value <= 128
end

local function validTeam(team: Team): boolean
	return (type(team) == "number" and finite(team))
		or (type(team) == "string" and identifier(team) and string.sub(team, 1, 8) ~= "neutral:")
end

local function distance(firstX: number, firstZ: number, secondX: number, secondZ: number): number
	return math.sqrt((firstX - secondX) ^ 2 + (firstZ - secondZ) ^ 2)
end

local function inside(actor: Actor, post: Outpost, margin: number): boolean
	return distance(actor.x, actor.z, post.x, post.z) <= post.radius + margin
end

local function orderedActors(self: Simulation): { Actor }
	local result = {}
	for _, actor in self.actors do
		if actor ~= nil then
			table.insert(result, actor)
		end
	end
	table.sort(result, function(first, second)
		return first.id < second.id
	end)
	return result
end

local function stats(actor: Actor): Config.RoleStats
	return actor.profile or Config.getProfile(actor.role, actor.civilizationId, actor.garrisonId ~= nil)
end

local function life(self: Simulation): number
	self._nextLife += 1
	return self._nextLife
end

local function emit(self: Simulation, kind: string, actor: Actor, target: Actor?, now: number, amount: number?)
	table.insert(self.events, {
		kind = kind,
		time = now,
		actorId = actor.id,
		actorLife = actor.life,
		team = actor.team,
		x = actor.x,
		z = actor.z,
		outpostId = actor.targetOutpostId,
		amount = amount,
		targetId = if target ~= nil then target.id else nil,
		targetLife = if target ~= nil then target.life else nil,
		targetX = if target ~= nil then target.x else nil,
		targetZ = if target ~= nil then target.z else nil,
	})
end

local function makeActor(
	self: Simulation,
	id: string,
	team: Team,
	civilizationId: string,
	role: Role,
	x: number,
	z: number,
	index: number,
	garrisonId: string?
): Actor
	local army = self.armies[team]
	local profile = if army and garrisonId == nil
		then army.profiles[role]
		else Config.getProfile(role, civilizationId, garrisonId ~= nil)
	local actor: Actor = {
		id = id,
		team = team,
		civilizationId = civilizationId,
		role = role,
		profile = profile,
		index = index,
		formationIndex = index,
		garrisonId = garrisonId,
		x = x,
		z = z,
		homeX = x,
		homeZ = z,
		health = profile.health,
		maxHealth = profile.health,
		alive = true,
		life = life(self),
		phase = "idle",
		headingX = 0,
		headingZ = 1,
		nextAttack = 0,
		nextHeal = 0,
		recoveryUntil = 0,
	}
	self.actors[id] = actor
	return actor
end

local function cancelContact(actor: Actor)
	actor.targetId, actor.targetLife, actor.contactAt, actor.contactOutpostId = nil, nil, nil, nil
	if actor.alive then
		actor.phase = "idle"
	end
end

local function spawnGarrison(self: Simulation, post: Outpost)
	local roles: { Role } = { "melee", "melee", "ranged" }
	for index, role in roles do
		local x = post.x + (if index == 1 then -3 elseif index == 2 then 3 else 0)
		local z = post.z + (if index == 3 then 4 else 0)
		local actor = makeActor(
			self,
			"garrison:" .. post.id .. ":" .. index,
			"neutral:" .. post.id,
			"sparta",
			role,
			x,
			z,
			index,
			post.id
		)
		actor.targetOutpostId = post.id
	end
end

local function removeGarrison(self: Simulation, postId: string)
	for id, actor in self.actors do
		if actor ~= nil and actor.garrisonId == postId then
			self.actors[id] = nil
		end
	end
end

local function autoTarget(self: Simulation, team: Team, lineId: Team): string?
	local selected
	for _, id in self._postOrder do
		local post = self.outposts[id]
		if post ~= nil and post.lineId == lineId then
			selected = id
			break
		end
	end
	local visited = {}
	while selected ~= nil and not visited[selected] do
		visited[selected] = true
		local post = self.outposts[selected]
		if post == nil then
			return nil
		end
		if post.ownerTeam ~= team or post.nextId == nil or self.outposts[post.nextId] == nil then
			return selected
		end
		selected = post.nextId
	end
	return selected
end

local function setTarget(self: Simulation, army: Army, target: string?)
	army.targetId = target
	for _, id in army.slots do
		local actor = self.actors[id]
		if actor ~= nil then
			local nextTarget = army.buildingTargets[actor.buildingId or ""] or target
			if actor.targetOutpostId ~= nextTarget then
				cancelContact(actor)
			end
			actor.targetOutpostId = nextTarget
		end
	end
end

function Battle.new(definitions: { OutpostDefinition }, options: Options?): Simulation
	local self = setmetatable({
		actors = {},
		outposts = {},
		armies = {},
		events = {},
		_postOrder = {},
		_nextLife = 0,
		_behavior = if options ~= nil then options.behavior else nil,
		_visible = if options ~= nil and options.visible ~= nil
			then options.visible
			else function()
				return true
			end,
	}, Battle) :: Simulation
	for _, definition in definitions do
		assert(
			identifier(definition.id) and finite(definition.x) and finite(definition.z),
			"Invalid outpost definition"
		)
		assert(
			finite(definition.radius) and definition.radius >= 4 and self.outposts[definition.id] == nil,
			"Invalid outpost radius or duplicate ID"
		)
		local post: Outpost = {
			id = definition.id,
			x = definition.x,
			z = definition.z,
			radius = definition.radius,
			lineId = definition.lineId,
			nextId = definition.nextId,
			progress = 0,
			status = "neutral",
		}
		self.outposts[post.id] = post
		table.insert(self._postOrder, post.id)
		spawnGarrison(self, post)
	end
	return self
end

function Battle.syncArmy(
	self: Simulation,
	team: Team,
	civilizationId: string,
	lineId: Team,
	slots: { Slot },
	now: number,
	completedResearch: Military.Completed?,
	options: OrderOptions?
): Result
	if
		not validTeam(team)
		or not validTeam(lineId)
		or not identifier(civilizationId)
		or not finite(now)
		or now < 0
		or type(slots) ~= "table"
	then
		return { ok = false, reason = "invalid_army" }
	end
	local army = self.armies[team]
	local sameIdentity = army ~= nil and army.civilizationId == civilizationId and army.lineId == lineId
	local completed = completedResearch or (if sameIdentity and army then army.completedResearch else {})
	if not Military.validateCompleted(completed) then
		return { ok = false, reason = "invalid_research" }
	end
	local sameResearch = sameIdentity and army ~= nil
	if sameResearch and army then
		for _, id in Military.order do
			if army.completedResearch[id] ~= completed[id] then
				sameResearch = false
				break
			end
		end
	end
	local profiles = if sameResearch and army then army.profiles else {}
	if not sameResearch then
		for _, role in { "melee", "ranged", "medic", "mounted" } do
			profiles[role] = Military.profile(role, civilizationId, completed)
		end
		table.freeze(profiles)
	end
	local capacity = Military.capacity(completed)
	if #slots > capacity then
		return { ok = false, reason = "invalid_army" }
	end
	local known, targets = {}, {}
	if sameIdentity and army then
		for id in army.knownBuildings do
			known[id] = true
		end
		for id, target in army.buildingTargets do
			targets[id] = target
		end
	end
	if options ~= nil then
		if
			type(options) ~= "table"
			or type(options.knownMilitaryBuildingIds) ~= "table"
			or type(options.buildingTargets) ~= "table"
		then
			return { ok = false, reason = "invalid_orders" }
		end
		for key in options do
			if key ~= "knownMilitaryBuildingIds" and key ~= "buildingTargets" then
				return { ok = false, reason = "invalid_orders" }
			end
		end
		known, targets = {}, {}
		local total = 0
		for key, id in options.knownMilitaryBuildingIds do
			total += 1
			if
				type(key) ~= "number"
				or key % 1 ~= 0
				or key < 1
				or key > #options.knownMilitaryBuildingIds
				or not identifier(id)
				or known[id]
			then
				return { ok = false, reason = "invalid_orders" }
			end
			known[id] = true
		end
		if total ~= #options.knownMilitaryBuildingIds then
			return { ok = false, reason = "invalid_orders" }
		end
		for id, target in options.buildingTargets do
			if not identifier(id) or not identifier(target) or self.outposts[target] == nil then
				return { ok = false, reason = "invalid_orders" }
			end
			if known[id] then
				targets[id] = target
			end
		end
	end
	local ids, count, capacityUsed = {}, 0, 0
	for key, slot in slots do
		count += 1
		if
			type(key) ~= "number"
			or key < 1
			or key % 1 ~= 0
			or key > #slots
			or type(slot) ~= "table"
			or not identifier(slot.id)
			or ids[slot.id]
			or not identifier(slot.buildingId)
			or (slot.role ~= "melee" and slot.role ~= "ranged" and slot.role ~= "medic" and slot.role ~= "mounted")
			or not finite(slot.x)
			or not finite(slot.z)
			or math.abs(slot.x) > 1000000
			or math.abs(slot.z) > 1000000
			or not finite(slot.index)
			or slot.index < 1
			or slot.index > capacity
			or slot.index % 1 ~= 0
		then
			return { ok = false, reason = "invalid_slot" }
		end
		if options ~= nil and not known[slot.buildingId] then
			return { ok = false, reason = "invalid_orders" }
		end
		known[slot.buildingId] = true
		capacityUsed += if slot.role == "mounted" then 2 else 1
		if capacityUsed > capacity then
			return { ok = false, reason = "invalid_army" }
		end
		ids[slot.id] = true
		local previousId = if sameIdentity and army then army.slots[slot.id] else nil
		local previous = if previousId then self.actors[previousId] else nil
		if
			previous
			and (previous.role ~= slot.role or previous.buildingId ~= slot.buildingId or previous.index ~= slot.index)
		then
			return { ok = false, reason = "slot_identity_changed" }
		end
	end
	if count ~= #slots then
		return { ok = false, reason = "invalid_slot" }
	end
	-- Every validation above precedes changes to authority, lives or orders.
	if army and not sameIdentity then
		self:removeArmy(team)
		army = nil
	end
	if not army then
		army = {
			civilizationId = civilizationId,
			lineId = lineId,
			manual = false,
			slots = {},
			completedResearch = {},
			capacity = capacity,
			profiles = profiles,
			buildingTargets = {},
			knownBuildings = {},
		}
		army.targetId = autoTarget(self, team, lineId)
		self.armies[team] = army
	end
	if not sameResearch then
		army.completedResearch = table.freeze(table.clone(completed))
	end
	army.profiles = profiles
	army.capacity, army.buildingTargets, army.knownBuildings = capacity, targets, known
	for slotId, actorId in army.slots do
		if not ids[slotId] then
			self.actors[actorId] = nil
		end
	end
	local current = {}
	for formationIndex, slot in slots do
		local id = "army:" .. type(team) .. ":" .. tostring(team) .. ":" .. slot.id
		local actor = self.actors[id]
		if not actor then
			actor = makeActor(self, id, team, civilizationId, slot.role, slot.x, slot.z, slot.index, nil)
			actor.buildingId, actor.slotId = slot.buildingId, slot.id
		end
		actor.profile = profiles[actor.role]
		actor.maxHealth = actor.profile.health
		actor.health = math.min(actor.health, actor.maxHealth)
		actor.homeX, actor.homeZ = slot.x, slot.z
		local nextTarget = targets[slot.buildingId] or army.targetId
		if actor.targetOutpostId ~= nextTarget then
			cancelContact(actor)
		end
		actor.targetOutpostId = nextTarget
		actor.formationIndex = formationIndex
		current[slot.id] = id
	end
	army.slots = current
	return { ok = true }
end

function Battle.removeArmy(self: Simulation, team: Team): ()
	local army = self.armies[team]
	if army ~= nil then
		for _, id in army.slots do
			self.actors[id] = nil
		end
	end
	self.armies[team] = nil
	for _, postId in self._postOrder do
		local post = self.outposts[postId]
		if post ~= nil then
			if post.ownerTeam == team then
				post.ownerTeam, post.ownerCivilizationId, post.captureTeam = nil, nil, nil
				post.progress, post.status = 0, "neutral"
				removeGarrison(self, post.id)
				spawnGarrison(self, post)
			elseif post.captureTeam == team then
				post.captureTeam = nil
				post.progress, post.status =
					if post.ownerTeam ~= nil then 20 else 0, if post.ownerTeam ~= nil then "owned" else "neutral"
			end
		end
	end
end

function Battle.command(self: Simulation, team: Team, outpostId: string, buildingIds: { string }?): Result
	local army = self.armies[team]
	if not army then
		return { ok = false, reason = "army_not_registered" }
	end
	if self.outposts[outpostId] == nil then
		return { ok = false, reason = "invalid_outpost" }
	end
	if buildingIds ~= nil then
		if type(buildingIds) ~= "table" or #buildingIds == 0 then
			return { ok = false, reason = "invalid_group" }
		end
		local seen, count = {}, 0
		for key, id in buildingIds do
			count += 1
			if
				type(key) ~= "number"
				or key % 1 ~= 0
				or key < 1
				or key > #buildingIds
				or not identifier(id)
				or seen[id]
				or not army.knownBuildings[id]
			then
				return { ok = false, reason = "invalid_group" }
			end
			seen[id] = true
		end
		if count ~= #buildingIds then
			return { ok = false, reason = "invalid_group" }
		end
		for id in seen do
			army.buildingTargets[id] = outpostId
		end
		setTarget(self, army, army.targetId)
	else
		army.buildingTargets = {}
		army.manual = true
		setTarget(self, army, outpostId)
	end
	return { ok = true }
end

local function validContact(self: Simulation, actor: Actor, target: Actor, post: Outpost): boolean
	return actor.alive
		and target.alive
		and actor.team ~= target.team
		and inside(actor, post, Config.combatMargin)
		and inside(target, post, Config.combatMargin)
		and distance(actor.x, actor.z, target.x, target.z) <= stats(actor).reach + Config.contactTolerance
		and self._visible(actor, target)
end

local function damage(self: Simulation, actor: Actor, target: Actor, now: number)
	local amount = math.min(target.health, stats(actor).damage)
	if amount <= 0 then
		return
	end
	target.health -= amount
	target.lastHitAt = now
	emit(self, "hit", actor, target, now, amount)
	if target.health <= 0 then
		target.alive, target.phase, target.health = false, "dead", 0
		target.targetId, target.targetLife, target.contactAt, target.contactOutpostId = nil, nil, nil, nil
		target.respawnAt = now
			+ (if target.garrisonId ~= nil then Config.neutralRespawnSeconds else Config.ownedRespawnSeconds)
		emit(self, "death", target, nil, now, nil)
	end
end

local function behaviorHooks(self: Simulation, now: number): BehaviorHooks
	local function valid(actor: Actor, target: Actor, reach: number): boolean
		local post = if actor.targetOutpostId ~= nil then self.outposts[actor.targetOutpostId] else nil
		return self.actors[actor.id] == actor
			and self.actors[target.id] == target
			and actor.alive
			and target.alive
			and actor.role ~= "medic"
			and actor.team ~= target.team
			and post ~= nil
			and inside(actor, post, Config.combatMargin)
			and inside(target, post, Config.combatMargin)
			and finite(reach)
			and reach > 0
			and distance(actor.x, actor.z, target.x, target.z) <= math.min(reach, stats(actor).reach) + 0.00001
			and self._visible(actor, target)
	end
	return {
		valid = valid,
		hit = function(actor, target, reach)
			if not valid(actor, target, reach) then
				return false
			end
			damage(self, actor, target, now)
			return true
		end,
		heal = function(actor, target, amount, reach)
			local post = if actor.targetOutpostId ~= nil then self.outposts[actor.targetOutpostId] else nil
			if
				self.actors[actor.id] ~= actor
				or self.actors[target.id] ~= target
				or not actor.alive
				or not target.alive
				or actor.role ~= "medic"
				or actor.team ~= target.team
				or actor.id == target.id
				or post == nil
				or not inside(actor, post, Config.combatMargin)
				or not inside(target, post, Config.combatMargin)
				or not finite(amount)
				or amount <= 0
				or not finite(reach)
				or reach <= 0
				or distance(actor.x, actor.z, target.x, target.z) > math.min(reach, stats(actor).healRange) + 0.00001
				or not self._visible(actor, target)
			then
				return 0
			end
			local applied = math.min(amount, stats(actor).heal, target.maxHealth - target.health)
			if applied > 0 then
				target.health += applied
				target.lastHealAt, actor.lastHealAt = now, now
				emit(self, "heal", actor, target, now, applied)
			end
			return applied
		end,
		visible = self._visible,
		event = function(kind, actor, target, amount)
			emit(self, kind, actor, target, now, amount)
		end,
	}
end

local function face(actor: Actor, x: number, z: number)
	local length = distance(actor.x, actor.z, x, z)
	if length > 0.00001 then
		actor.headingX, actor.headingZ = (x - actor.x) / length, (z - actor.z) / length
	end
end

local function move(actor: Actor, actors: { Actor }, post: Outpost, x: number, z: number, dt: number, stop: number)
	local length = distance(actor.x, actor.z, x, z)
	if length <= stop then
		actor.phase = "idle"
		return
	end
	local headingX, headingZ = (x - actor.x) / length, (z - actor.z) / length
	local repelX, repelZ = 0, 0
	for _, other in actors do
		if other.alive and other.id ~= actor.id and other.team == actor.team then
			local gap = distance(actor.x, actor.z, other.x, other.z)
			if gap < Config.softSpacing then
				local awayX, awayZ
				if gap > 0.00001 then
					awayX, awayZ = (actor.x - other.x) / gap, (actor.z - other.z) / gap
				else
					local side = if actor.id < other.id then -1 else 1
					awayX, awayZ = -headingZ * side, headingX * side
				end
				local weight = (Config.softSpacing - gap) / Config.softSpacing
				repelX += awayX * weight
				repelZ += awayZ * weight
			end
		end
	end
	local repulsion = math.sqrt(repelX ^ 2 + repelZ ^ 2)
	if repulsion > 1 then
		repelX, repelZ = repelX / repulsion, repelZ / repulsion
	end
	local speed = stats(actor).speed
	local velocityX, velocityZ =
		headingX * speed + repelX * Config.separationSpeed, headingZ * speed + repelZ * Config.separationSpeed
	local magnitude = math.sqrt(velocityX ^ 2 + velocityZ ^ 2)
	local amount = math.min(speed * dt, length - stop)
	actor.headingX, actor.headingZ = velocityX / magnitude, velocityZ / magnitude
	actor.x += actor.headingX * amount
	actor.z += actor.headingZ * amount
	if actor.garrisonId ~= nil then
		local radius = post.radius + Config.combatMargin
		local offset = distance(actor.x, actor.z, post.x, post.z)
		if offset > radius then
			actor.x, actor.z =
				post.x + (actor.x - post.x) * radius / offset, post.z + (actor.z - post.z) * radius / offset
		end
	end
	actor.phase = "moving"
end

local function nearestEnemy(actor: Actor, post: Outpost, actors: { Actor }): Actor?
	if not inside(actor, post, Config.combatMargin) then
		return nil
	end
	local selected, best = nil, math.huge
	for _, target in actors do
		if target.alive and target.team ~= actor.team and inside(target, post, Config.combatMargin) then
			local range = distance(actor.x, actor.z, target.x, target.z)
			if range < best then
				selected, best = target, range
			end
		end
	end
	return selected
end

local function heal(self: Simulation, actor: Actor, post: Outpost, actors: { Actor }, dt: number, now: number): boolean
	if not inside(actor, post, Config.combatMargin) then
		return false
	end
	local patient, best = nil, math.huge
	for _, ally in actors do
		if
			ally.id ~= actor.id
			and ally.alive
			and ally.team == actor.team
			and ally.health < ally.maxHealth
			and inside(ally, post, Config.combatMargin)
		then
			local range = distance(actor.x, actor.z, ally.x, ally.z)
			if range < best then
				patient, best = ally, range
			end
		end
	end
	if patient == nil then
		return false
	end
	local profile = stats(actor)
	if best > profile.healRange then
		move(actor, actors, post, patient.x, patient.z, dt, profile.healRange)
	elseif now >= actor.nextHeal and self._visible(actor, patient) then
		local amount = math.min(profile.heal, patient.maxHealth - patient.health)
		patient.health += amount
		actor.nextHeal, actor.recoveryUntil, actor.phase = now + profile.healCooldown, now + profile.recovery, "heal"
		face(actor, patient.x, patient.z)
		emit(self, "heal", actor, patient, now, amount)
	else
		actor.phase = "idle"
	end
	return true
end

local function act(self: Simulation, actor: Actor, actors: { Actor }, dt: number, now: number)
	if not actor.alive then
		return
	end
	local post = if actor.targetOutpostId ~= nil then self.outposts[actor.targetOutpostId] else nil
	if post == nil then
		cancelContact(actor)
		return
	end
	if actor.phase == "windup" then
		if actor.contactAt ~= nil and now + 0.0000001 >= actor.contactAt then
			local target = if actor.targetId ~= nil then self.actors[actor.targetId] else nil
			if
				target ~= nil
				and actor.targetLife == target.life
				and actor.contactOutpostId == post.id
				and validContact(self, actor, target, post)
			then
				damage(self, actor, target, now)
			end
			actor.phase, actor.recoveryUntil, actor.contactAt, actor.contactOutpostId =
				"recovery", now + stats(actor).recovery, nil, nil
		end
		return
	end
	if (actor.phase == "recovery" or actor.phase == "heal") and now < actor.recoveryUntil then
		return
	end
	actor.phase = "idle"
	if actor.role == "medic" then
		if heal(self, actor, post, actors, dt, now) then
			return
		end
	else
		local target = nearestEnemy(actor, post, actors)
		if target ~= nil then
			local range, profile = distance(actor.x, actor.z, target.x, target.z), stats(actor)
			if range <= profile.reach and self._visible(actor, target) then
				face(actor, target.x, target.z)
				actor.targetId = target.id
				if now + 0.0000001 >= actor.nextAttack then
					actor.phase, actor.targetLife, actor.contactAt = "windup", target.life, now + profile.windup
					actor.contactOutpostId, actor.nextAttack = post.id, now + profile.cooldown
					emit(self, if actor.role == "ranged" then "shot" else "attack", actor, target, now, nil)
				end
			else
				move(actor, actors, post, target.x, target.z, dt, profile.reach * 0.9)
			end
			return
		end
	end
	actor.targetId, actor.targetLife = nil, nil
	if actor.garrisonId ~= nil then
		move(actor, actors, post, actor.homeX, actor.homeZ, dt, Config.arrivalDistance)
	else
		local offsetX = ((actor.formationIndex - 1) % 5 - 2) * 2.2
		local row = math.floor((actor.formationIndex - 1) / 5) * 2.2
		local offsetZ = (if actor.role == "medic" then 7 elseif actor.role == "ranged" then 4 else -3) + row
		local offset = math.sqrt(offsetX ^ 2 + offsetZ ^ 2)
		if offset > post.radius * 0.55 then
			offsetX, offsetZ = offsetX * post.radius * 0.55 / offset, offsetZ * post.radius * 0.55 / offset
		end
		move(actor, actors, post, post.x + offsetX, post.z + offsetZ, dt, Config.arrivalDistance)
	end
end

local function respawn(self: Simulation, actor: Actor, now: number)
	if actor.alive or actor.respawnAt == nil or now + 0.0000001 < actor.respawnAt then
		return
	end
	if actor.garrisonId ~= nil then
		local post = self.outposts[actor.garrisonId]
		if post == nil or post.ownerTeam ~= nil then
			self.actors[actor.id] = nil
			return
		end
	elseif self.armies[actor.team] == nil then
		self.actors[actor.id] = nil
		return
	end
	actor.x, actor.z, actor.health, actor.alive, actor.life =
		actor.homeX, actor.homeZ, actor.maxHealth, true, life(self)
	actor.respawnAt, actor.nextAttack, actor.nextHeal, actor.recoveryUntil = nil, now, now, now
	cancelContact(actor)
end

local function captureInfo(self: Simulation, post: Outpost): CaptureInfo
	local teams, present = {}, {}
	for _, actor in orderedActors(self) do
		if
			actor.alive
			and actor.garrisonId == nil
			and self.armies[actor.team] ~= nil
			and actor.team ~= post.ownerTeam
			and inside(actor, post, 0)
			and not present[actor.team]
		then
			present[actor.team] = true
			table.insert(teams, actor.team)
		end
	end
	local team = if post.captureTeam ~= nil and present[post.captureTeam] then post.captureTeam else teams[1]
	if team == nil then
		return { clear = false, contested = false }
	end
	local blocked = false
	for _, actor in orderedActors(self) do
		if actor.alive and actor.team ~= team and inside(actor, post, Config.combatMargin) then
			blocked = true
			break
		end
	end
	return {
		team = team,
		clear = #teams == 1 and (not Config.capturePausesForDefenders or not blocked),
		contested = #teams > 1,
	}
end

local function capture(self: Simulation, post: Outpost, before: CaptureInfo, dt: number, now: number)
	local current = captureInfo(self, post)
	if current.team == nil then
		post.captureTeam = nil
		post.progress, post.status =
			if post.ownerTeam ~= nil then Config.captureSeconds else 0,
			if post.ownerTeam ~= nil then "owned" else "neutral"
		return
	end
	if post.captureTeam ~= current.team then
		post.captureTeam, post.progress = current.team, 0
	end
	post.status = if current.contested then "contested" elseif not current.clear then "defended" else "capturing"
	-- Both endpoints must be clear: a kill/arrival/respawn slice never receives
	-- credit for time whose occupancy or defense changed inside that slice.
	if current.clear and before.clear and before.team == current.team then
		post.progress = math.min(Config.captureSeconds, post.progress + dt)
	end
	if post.progress + 0.0000001 >= Config.captureSeconds then
		local army = self.armies[current.team]
		if army == nil then
			return
		end
		post.ownerTeam, post.ownerCivilizationId, post.captureTeam = current.team, army.civilizationId, nil
		post.progress, post.status = Config.captureSeconds, "owned"
		removeGarrison(self, post.id)
		table.insert(self.events, {
			kind = "capture",
			time = now,
			x = post.x,
			z = post.z,
			outpostId = post.id,
			team = current.team,
			civilizationId = army.civilizationId,
		})
	end
end

function Battle.step(self: Simulation, dt: number, now: number): Result
	if not finite(dt) or dt < 0 or not finite(now) or now < 0 or (self._time ~= nil and now < self._time) then
		return { ok = false, reason = "invalid_time" }
	end
	self.events = {}
	local elapsed = math.min(dt, Config.maxDelta)
	local cursor = math.max(now - elapsed, self._time or (now - elapsed))
	local actual = math.max(0, now - cursor)
	while now - cursor > 0.0000001 do
		local slice = math.min(Config.fixedStep, now - cursor)
		local nextTime = cursor + slice
		local before = {}
		for _, id in self._postOrder do
			local post = self.outposts[id]
			if post ~= nil then
				before[id] = captureInfo(self, post)
			end
		end
		local actors = orderedActors(self)
		for _, actor in actors do
			respawn(self, actor, nextTime)
		end
		if self._behavior ~= nil then
			self._behavior:stepActors(self, actors, slice, nextTime, behaviorHooks(self, nextTime))
		else
			-- Native gameplay injects OriginalBehavior; this kernel remains a pure fixture.
			for _, actor in actors do
				if self.actors[actor.id] == actor then
					act(self, actor, actors, slice, nextTime)
				end
			end
		end
		for _, id in self._postOrder do
			local post = self.outposts[id]
			if post ~= nil then
				capture(self, post, before[id], slice, nextTime)
			end
		end
		for team, army in self.armies do
			if army ~= nil and not army.manual then
				setTarget(self, army, autoTarget(self, team, army.lineId))
			end
		end
		cursor = nextTime
	end
	self._time = now
	return { ok = true, elapsed = actual }
end

return table.freeze(Battle)

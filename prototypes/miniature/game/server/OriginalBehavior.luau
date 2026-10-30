--!strict
-- Native bridge to the unchanged full-size army modules. Numeric Battle remains
-- the life/health/capture authority; original helpers own tactical decisions,
-- reservations, attack phases, crowd steering and medical flights.
local Shared = game:GetService("ReplicatedStorage").Shared
local Source = game:GetService("ServerStorage").OriginalArmy
local Battle = require(script.Parent.Battle)
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.BattleConfig)
local Encounter = require(Source.CombatEncounter)
local Crowd = require(Source.CrowdMovement)
local Rules = require(Source.CombatRules)
local Planner = require(Source.MedicPlanner)
local Retreat = require(Source.MedicalRetreat)
local Medical = require(Source.MedicalService)
local MedicalRules = require(Source.MedicalRules)
local Warrior = require(Shared.WarriorConfig)
local Ranged = require(Shared.RangedConfig)
local Medicine = require(Shared.MedicalConfig)
local Tuning = require(Shared.TacticalCombatConfig)
local Original = {}

export type Options = { rigFactory: ((Battle.Actor) -> Model)? }
export type Behavior = Battle.Behavior & { metrics: { [string]: number } }
local VIRTUAL_Y = 10000
local scale = Config.scale

local function projected(x: number, z: number): Vector3
	return Vector3.new(x / scale, VIRTUAL_Y, z / scale)
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function profile(actor: Battle.Actor): Config.RoleStats
	return Config.getProfile(actor.role, actor.civilizationId, actor.garrisonId ~= nil)
end

local function createIdentity(actor: Battle.Actor): Model
	-- Filters in the original helpers require Instance identities. This marker
	-- has no physical parts/Humanoid and never enters the replicated DataModel.
	local rig = Instance.new("Model")
	rig.Name = actor.id
	return rig
end

function Original.new(options: Options?): Behavior
	local factory = if options ~= nil and options.rigFactory ~= nil then options.rigFactory else createIdentity
	local metrics = {
		encounterPlans = 0,
		encounterAdvances = 0,
		crowdPlans = 0,
		medicPlans = 0,
		recoveryPlans = 0,
		bandageThrows = 0,
		projectileReleases = 0,
		projectileHits = 0,
	}
	local behavior = { metrics = metrics }
	local records, byRig, pools, teamOwners, ownerTeams = {}, {}, {}, {}, {}
	local ownerSerial, destroyed = 0, false
	local shots, medicalReady, medicalSource = {}, {}, {}
	local context: { battle: Battle.BattleView?, hooks: Battle.BehaviorHooks?, now: number } = { now = 0 }

	local function current(record): boolean
		local battle = context.battle
		return battle ~= nil
			and battle.actors[record.actor.id] == record.actor
			and record.actor.life == record.life
			and record.actor.alive
			and (record.actor.garrisonId ~= nil or battle.armies[record.actor.team] ~= nil)
	end
	local function owner(team: Battle.Team): number
		if teamOwners[team] == nil then
			ownerSerial += 1
			teamOwners[team] = ownerSerial
			ownerTeams[ownerSerial] = team
		end
		return teamOwners[team]
	end
	local function forget(record)
		for _, pool in pools do
			pool.encounter:forget(record.rig)
			pool.medical:forget(record.rig)
		end
		byRig[record.rig] = nil
		record.rig:Destroy()
		records[record.actor.id] = nil
	end
	local function ensure(actor: Battle.Actor)
		local record = records[actor.id]
		if record ~= nil and (record.life ~= actor.life or record.actor ~= actor) then
			forget(record)
			record = nil
		end
		if record == nil then
			local rig = factory(actor)
			rig:SetAttribute("ArmySlot", actor.id)
			rig:SetAttribute(
				"WarriorClass",
				if actor.role == "melee" or actor.role == "mounted" then "warrior" else actor.role
			)
			local humanoid = { Health = actor.health, MaxHealth = actor.maxHealth }
			local root = { Position = projected(actor.x, actor.z), AssemblyLinearVelocity = Vector3.zero }
			local proxy = {
				rig = rig,
				root = root,
				humanoid = humanoid,
				position = root.Position,
				alive = true,
				kind = if actor.role == "melee" or actor.role == "mounted" then "warrior" else actor.role,
				ownerId = if actor.garrisonId ~= nil then nil else owner(actor.team),
				neutral = actor.garrisonId ~= nil,
				claimed = actor.garrisonId == nil,
				civilizationId = actor.civilizationId,
				plotId = actor.garrisonId or owner(actor.team),
			}
			record = {
				actor = actor,
				life = actor.life,
				rig = rig,
				humanoid = humanoid,
				root = root,
				proxy = proxy,
				velocity = Vector3.zero,
				nextThink = 0,
				readyAt = 0,
				recovery = {},
			}
			records[actor.id], byRig[rig] = record, record
		end
		record.humanoid.Health, record.humanoid.MaxHealth = actor.health, actor.maxHealth
		record.proxy.alive = actor.alive
		record.proxy.position = projected(actor.x, actor.z)
		record.root.Position, record.root.AssemblyLinearVelocity = record.proxy.position, record.velocity / scale
		return record
	end
	local function representation(rig)
		local record = byRig[rig]
		if record == nil or not current(record) then
			return nil
		end
		record.proxy.position = projected(record.actor.x, record.actor.z)
		record.root.Position = record.proxy.position
		return record.proxy
	end
	local function visible(first, second): boolean
		local source, target = byRig[first.rig], byRig[second.rig]
		local hooks = context.hooks
		if source == nil or target == nil or hooks == nil or not current(source) or not current(target) then
			return false
		end
		local from = first.position or projected(source.actor.x, source.actor.z)
		local to = second.position or projected(target.actor.x, target.actor.z)
		local reach = if source.actor.team == target.actor.team and source.actor.role == "medic"
			then profile(source.actor).healRange
			else profile(source.actor).reach
		if flat(from - to).Magnitude * scale > reach + 0.00001 then
			return false
		end
		local a, b = table.clone(source.actor), table.clone(target.actor)
		a.x, a.z, b.x, b.z = from.X * scale, from.Z * scale, to.X * scale, to.Z * scale
		return hooks.visible(a, b)
	end
	local function trace(source, from: Vector3, to: Vector3): boolean
		local hooks = context.hooks
		if hooks == nil or not current(source) then
			return false
		end
		local a, b = table.clone(source.actor), table.clone(source.actor)
		a.x, a.z, b.x, b.z = from.X * scale, from.Z * scale, to.X * scale, to.Z * scale
		return hooks.visible(a, b)
	end
	local function emit(kind: string, source, target, amount: number?)
		local hooks = context.hooks
		if hooks ~= nil then
			hooks.event(kind, source.actor, if target ~= nil then target.actor else nil, amount)
		end
	end
	local function launch(source, target, postId: string): boolean
		local hooks = context.hooks
		if hooks == nil or #shots >= Ranged.maxProjectiles or not current(source) or not current(target) then
			return false
		end
		local reach = profile(source.actor).reach
		if not hooks.valid(source.actor, target.actor, reach) then
			return false
		end
		local delta = Vector3.new(target.actor.x - source.actor.x, 0, target.actor.z - source.actor.z)
		if delta.Magnitude < 0.0001 then
			return false
		end
		local lives = {}
		for id, record in records do
			if current(record) then
				lives[id] = record.life
			end
		end
		local origin = Vector3.new(source.actor.x, 0, source.actor.z)
		table.insert(shots, {
			source = source,
			sourceLife = source.life,
			postId = postId,
			origin = origin,
			position = origin,
			direction = delta.Unit,
			remaining = reach,
			reach = reach,
			expires = context.now + reach / (Ranged.speed * scale) + 0.5,
			lives = lives,
		})
		metrics.projectileReleases += 1
		emit("shot", source, target, nil)
		return true
	end
	local function poolFor(post)
		if pools[post.id] ~= nil then
			return pools[post.id]
		end
		local radius = (post.radius + Config.combatMargin) / scale
		local arena = { Size = Vector3.new(2, radius * 2, radius * 2), CFrame = {} }
		function arena.CFrame:PointToObjectSpace(point)
			-- Original cylinder: local X is height; local Y/Z span the ellipse.
			return Vector3.new(point.Y - VIRTUAL_Y, point.X - post.x / scale, point.Z - post.z / scale)
		end
		local model = { Battlefield = arena }
		function model:FindFirstChild(name)
			return if name == "Battlefield" then arena else nil
		end
		local world = { model = model }
		local combat = {}
		function combat:actor(rig)
			return representation(rig)
		end
		function combat:actors()
			local list = {}
			for _, record in records do
				local proxy = representation(record.rig)
				if proxy ~= nil then
					table.insert(list, proxy)
				end
			end
			table.sort(list, function(a, b)
				return a.rig.Name < b.rig.Name
			end)
			return list
		end
		function combat:canAct(rig)
			local record = byRig[rig]
			return record ~= nil and current(record) and record.actor.targetOutpostId == post.id
		end
		function combat:visible(first, second)
			return visible(first, second)
		end
		function combat:hit(sourceRig, targetRig)
			local source, target = byRig[sourceRig], byRig[targetRig]
			local hooks = context.hooks
			if
				source == nil
				or target == nil
				or hooks == nil
				or not current(source)
				or not current(target)
				or not Rules.canDamage(source.proxy, target.proxy, arena, Warrior.attackRange)
				or not hooks.hit(source.actor, target.actor, Warrior.attackRange * scale)
			then
				return { ok = false }
			end
			target.humanoid.Health, target.proxy.alive = target.actor.health, target.actor.alive
			source.readyAt =
				math.max(source.readyAt, context.now + Warrior.attackCooldown - Tuning.phases.warrior.windup)
			return { ok = true }
		end
		local economy = {}
		function economy:get(ownerId)
			local battle = context.battle
			return if battle ~= nil
					and ownerTeams[ownerId] ~= nil
					and battle.armies[ownerTeams[ownerId]] ~= nil
				then { hospitalLevel = 1, trainingLevel = 0 }
				else nil
		end
		function economy:canMutate(ownerId)
			return self:get(ownerId) ~= nil
		end
		local space = {}
		local function obstacle(origin, delta, filter)
			local excluded = filter.FilterDescendantsInstances
			local source = if excluded ~= nil then byRig[excluded[1]] else nil
			if source ~= nil and trace(source, origin, origin + delta) then
				return nil
			end
			return { Distance = 0, Instance = {
				IsDescendantOf = function()
					return false
				end,
			} }
		end
		function space:Spherecast(origin, _radius, delta, filter)
			return obstacle(origin, delta, filter)
		end
		function space:Raycast(origin, delta, filter)
			return obstacle(origin, delta, filter)
		end
		local function visual(origin)
			local part = { Position = origin, Parent = true }
			function part:Destroy()
				self.Parent = nil
			end
			return part
		end
		local medical = Medical.new(world, combat, economy, function(rig)
			return combat:canAct(rig)
		end, function()
			return context.now
		end, space, visual)
		local pool = { arena = arena, combat = combat, encounter = Encounter.new(world, combat), medical = medical }
		pools[post.id] = pool
		return pool
	end
	local function destination(actor: Battle.Actor, post): Vector3
		local x = ((actor.formationIndex - 1) % 5 - 2) * 2.2
		local row = math.floor((actor.formationIndex - 1) / 5) * 2.2
		local z = (if actor.role == "medic" then 7 elseif actor.role == "ranged" then 4 else -3) + row
		local length = math.sqrt(x * x + z * z)
		if length > post.radius * 0.55 then
			x, z = x * post.radius * 0.55 / length, z * post.radius * 0.55 / length
		end
		if actor.garrisonId ~= nil then
			return projected(actor.homeX, actor.homeZ)
		end
		return projected(post.x + x, post.z + z)
	end
	local function safePoint(record, pool, point, fromInside: boolean)
		if typeof(point) ~= "Vector3" or point.X ~= point.X or point.Z ~= point.Z then
			return nil
		end
		if fromInside and not Rules.containsArena(pool.arena, point) then
			return nil
		end
		return if trace(record, record.proxy.position, point) then point else nil
	end
	local function move(record, pool, actors, plan, dt: number)
		local actor = record.actor
		actor.moving = false
		local goal = plan.goal
		if goal == nil or plan.phase == "windup" or plan.phase == "contact" then
			record.velocity = Vector3.zero
			return
		end
		local speed =
			math.min(profile(actor).speed, (plan.speed or Warrior.walkSpeed) / Warrior.walkSpeed * profile(actor).speed)
		local inside = Rules.containsArena(pool.arena, record.proxy.position)
		metrics.crowdPlans += 1
		local neighbors = {}
		for _, other in actors do
			if other.rig ~= record.rig then
				table.insert(neighbors, other)
			end
		end
		local point = Crowd.choose(record.proxy, neighbors, goal, speed / scale, function(candidate)
			if plan.allowsDetour and not plan.allowsDetour(candidate) then
				return nil
			end
			return safePoint(record, pool, candidate, inside or actor.garrisonId ~= nil)
		end)
		if point == nil then
			record.velocity = Vector3.zero
			return
		end
		if plan.allowsDetour and not plan.allowsDetour(point) then
			record.velocity = Vector3.zero
			return
		end
		if safePoint(record, pool, point, inside or actor.garrisonId ~= nil) == nil then
			record.velocity = Vector3.zero
			return
		end
		local delta = flat(point - record.proxy.position)
		if delta.Magnitude <= 0.08 then
			record.velocity = Vector3.zero
			return
		end
		local step = delta.Unit * math.min(delta.Magnitude, speed * dt / scale)
		local position = record.proxy.position + step
		actor.x, actor.z = position.X * scale, position.Z * scale
		actor.headingX, actor.headingZ = delta.Unit.X, delta.Unit.Z
		actor.moving = true
		record.velocity = step * scale / dt
		record.proxy.position, record.root.Position = position, position
		record.root.AssemblyLinearVelocity = record.velocity / scale
	end
	local function phase(record, plan)
		local actor = record.actor
		actor.combatPhase = plan.phase or "idle"
		actor.phase = if actor.combatPhase == "idle" and actor.moving then "moving" else actor.combatPhase
		actor.phaseDuration = plan.phaseDuration
		actor.phaseStartedAt = if plan.phaseStartedAt ~= nil
				and plan.attackStartedAt ~= nil
				and record.attackStarted ~= nil
			then record.attackStarted + plan.phaseStartedAt - plan.attackStartedAt
			else nil
		local target = if plan.target ~= nil then byRig[plan.target] else nil
		actor.targetId = if target ~= nil and current(target) then target.actor.id else nil
		actor.targetLife = if target ~= nil and current(target) then target.life else nil
		if plan.facing ~= nil and not actor.moving then
			local facing = flat(plan.facing - record.proxy.position)
			if facing.Magnitude > 0.001 then
				actor.headingX, actor.headingZ = facing.Unit.X, facing.Unit.Z
			end
		end
		if plan.phase == "windup" and record.attackStarted ~= record.cuedAt then
			record.cuedAt = record.attackStarted
			if actor.role == "melee" or actor.role == "mounted" then
				emit("attack", record, target, nil)
			end
		end
	end
	local function fly(dt: number)
		local hooks = context.hooks
		if hooks == nil then
			return
		end
		for index = #shots, 1, -1 do
			local shot = shots[index]
			local source = shot.source
			if
				not current(source)
				or source.life ~= shot.sourceLife
				or source.actor.targetOutpostId ~= shot.postId
				or context.now > shot.expires
			then
				table.remove(shots, index)
				continue
			end
			local length = math.min(Ranged.speed * scale * dt, shot.remaining)
			local ending = shot.position + shot.direction * length
			if not trace(source, projected(shot.position.X, shot.position.Z), projected(ending.X, ending.Z)) then
				table.remove(shots, index)
				continue
			end
			local selected, progress = nil, math.huge
			local leg = ending - shot.position
			for id, target in records do
				if
					current(target)
					and Rules.hostile(source.proxy, target.proxy)
					and shot.lives[id] == target.life
					and (Vector3.new(target.actor.x, 0, target.actor.z) - shot.origin).Magnitude
						<= shot.reach + 0.00001
				then
					local offset = Vector3.new(target.actor.x, 0, target.actor.z) - shot.position
					local t = if length > 0 then math.clamp(offset:Dot(leg) / (length * length), 0, 1) else 0
					if
						(offset - leg * t).Magnitude <= 0.35
						and t < progress
						and hooks.valid(source.actor, target.actor, shot.reach)
					then
						selected, progress = target, t
					end
				end
			end
			if selected ~= nil then
				if hooks.hit(source.actor, selected.actor, shot.reach) then
					metrics.projectileHits += 1
					selected.humanoid.Health, selected.proxy.alive = selected.actor.health, selected.actor.alive
				end
				table.remove(shots, index)
			else
				shot.position, shot.remaining = ending, shot.remaining - length
				if shot.remaining <= 0 then
					table.remove(shots, index)
				end
			end
		end
	end

	function behavior:stepActors(
		battle: Battle.BattleView,
		actors: { Battle.Actor },
		dt: number,
		now: number,
		hooks: Battle.BehaviorHooks
	)
		if destroyed then
			return
		end
		context.battle, context.hooks, context.now = battle, hooks, now
		for id, record in records do
			if battle.actors[id] ~= record.actor or record.life ~= record.actor.life or not record.actor.alive then
				forget(record)
			end
		end
		local ordered = {}
		for _, actor in actors do
			if battle.actors[actor.id] == actor and actor.alive then
				table.insert(ordered, ensure(actor))
			end
		end
		local representatives = {}
		for _, record in ordered do
			table.insert(representatives, record.proxy)
		end
		for _, record in ordered do
			if not current(record) then
				continue
			end
			local actor = record.actor
			local post = if actor.targetOutpostId ~= nil then battle.outposts[actor.targetOutpostId] else nil
			if post == nil then
				actor.phase, actor.combatPhase, actor.moving = "idle", "idle", false
				continue
			end
			local pool = poolFor(post)
			if record.postId ~= post.id then
				if record.postId ~= nil and pools[record.postId] ~= nil then
					pools[record.postId].encounter:forget(record.rig)
					pools[record.postId].medical:forget(record.rig)
				end
				record.postId, record.nextThink, record.plan = post.id, 0, nil
				local forward = flat(projected(post.x, post.z) - projected(actor.homeX, actor.homeZ))
				record.forward = if forward.Magnitude > 0.001 then forward.Unit else Vector3.new(0, 0, 1)
			end
			if actor.role == "medic" then
				if now + 0.000001 >= record.nextThink or record.plan == nil then
					metrics.medicPlans += 1
					record.plan = Planner.step(
						record.proxy,
						representatives,
						"advance",
						projected(post.x, post.z),
						record.forward,
						Rules.containsArena(pool.arena, record.proxy.position),
						function(point)
							return safePoint(
								record,
								pool,
								point,
								Rules.containsArena(pool.arena, record.proxy.position)
							)
						end,
						function(point)
							return Rules.containsArena(pool.arena, point)
						end
					)
					record.nextThink = now + Warrior.thinkInterval
				end
				move(record, pool, representatives, record.plan, dt)
				actor.combatPhase, actor.phase = "idle", if actor.moving then "moving" else "idle"
				actor.phaseStartedAt, actor.phaseDuration = nil, nil
				local id = record.proxy.ownerId
				if id ~= nil and now >= (medicalReady[id] or 0) and pool.medical:throw(record.rig, representatives) then
					medicalReady[id], medicalSource[id] = now + Medicine.cooldown, record
					actor.bandageThrownAt = now
					metrics.bandageThrows += 1
					-- MedicalService remains the only flight/healing decision. Recover
					-- its original patient choice solely to emit a visual launch cue.
					local targetPosition = record.rig:GetAttribute("BandageTargetPosition")
					local patient = MedicalRules.choose(
						record.proxy,
						representatives,
						{ hospitalLevel = 1 },
						Medicine.range,
						function(candidate)
							return candidate.position == targetPosition
								and pool.combat:canAct(candidate.rig)
								and visible(record.proxy, candidate)
						end
					)
					local recipient = if patient ~= nil then byRig[patient.rig] else nil
					if recipient ~= nil then
						emit("bandage", record, recipient, nil)
					end
				end
			else
				if now + 0.000001 >= record.nextThink or record.plan == nil then
					metrics.recoveryPlans += 1
					local support = Retreat.step(
						record.recovery,
						record.proxy,
						representatives,
						"advance",
						{ hospitalLevel = 1 },
						function(point)
							return safePoint(
								record,
								pool,
								point,
								Rules.containsArena(pool.arena, record.proxy.position)
							)
						end,
						visible
					)
					metrics.encounterPlans += 1
					record.plan = pool.encounter:step(record.rig, {
						order = "advance",
						actors = representatives,
						homeGoal = destination(actor, post),
						support = support,
						attackReady = function()
							return context.now + 0.000001 >= record.readyAt
						end,
						attackStarted = function()
							record.attackStarted = context.now
							record.readyAt = context.now
								+ (if actor.role == "ranged" then Ranged.attackCooldown else Warrior.attackCooldown)
						end,
						fire = function(targetRig)
							local target = byRig[targetRig]
							return target ~= nil and launch(record, target, post.id)
						end,
					}, now)
					record.nextThink = now + Warrior.thinkInterval
				end
				metrics.encounterAdvances += 1
				local latest = pool.encounter:advance(record.rig, now)
				record.plan = latest
				move(record, pool, representatives, record.plan, dt)
				phase(record, record.plan)
			end
		end
		for _, pool in pools do
			pool.medical:step()
		end
		for _, record in ordered do
			if current(record) and record.humanoid.Health > record.actor.health then
				local source = medicalSource[record.proxy.ownerId]
				if source ~= nil and current(source) then
					hooks.heal(
						source.actor,
						record.actor,
						record.humanoid.Health - record.actor.health,
						profile(source.actor).healRange
					)
				end
				record.humanoid.Health = record.actor.health
			end
		end
		fly(dt)
	end
	function behavior:destroy()
		if destroyed then
			return
		end
		destroyed = true
		for _, record in records do
			forget(record)
		end
		for _, pool in pools do
			pool.encounter:destroy()
			pool.medical:destroy()
		end
		table.clear(records)
		table.clear(byRig)
		table.clear(pools)
		table.clear(shots)
		table.clear(teamOwners)
		table.clear(ownerTeams)
		table.clear(medicalReady)
		table.clear(medicalSource)
		context.battle, context.hooks = nil, nil
	end
	return behavior :: Behavior
end

return table.freeze(Original)

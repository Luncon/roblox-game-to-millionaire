--!strict
-- Visuals consume Battle state; no damage, capture decisions or profile writes live here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.MiniatureGame
local Civilizations = require(Shared.Civilizations)
local RagdollConfig = require(Shared.RagdollConfig)
local OriginalTroops = require(script.Parent.OriginalTroops)
local MountedTroops = require(script.Parent.MountedTroops)
local OutpostScenery = require(script.Parent.OutpostScenery)
local OriginalRanged = require(ReplicatedStorage.OriginalArmyConfig.RangedConfig)
local OriginalMedical = require(ReplicatedStorage.OriginalArmyConfig.MedicalConfig)
local OutpostWorld = {}

type Team = string | number
type Role = "melee" | "ranged" | "medic" | "mounted"
export type Definition = { id: string, x: number, z: number, radius: number, lineId: number, nextId: string? }
export type Actor = {
	id: string,
	team: Team,
	civilizationId: string,
	role: Role,
	buildingId: string?,
	index: number?,
	x: number,
	z: number,
	health: number,
	maxHealth: number,
	alive: boolean,
	life: number,
	phase: string,
	combatPhase: string?,
	phaseStartedAt: number?,
	phaseDuration: number?,
	moving: boolean?,
	lastHitAt: number?,
	lastHealAt: number?,
	bandageThrownAt: number?,
	targetId: string?,
	targetOutpostId: string?,
	headingX: number,
	headingZ: number,
}
export type Outpost = {
	id: string,
	x: number,
	z: number,
	radius: number,
	lineId: number,
	nextId: string?,
	ownerTeam: Team?,
	ownerCivilizationId: string?,
	captureTeam: Team?,
	progress: number,
	status: string,
}
export type BattleEvent = {
	kind: string,
	actorId: string?,
	actorLife: number?,
	targetId: string?,
	targetLife: number?,
	outpostId: string?,
	team: Team?,
	x: number?,
	z: number?,
	targetX: number?,
	targetZ: number?,
	amount: number?,
	time: number?,
}
export type BattleView = {
	actors: { [string]: Actor? },
	outposts: { [string]: Outpost? },
	events: { BattleEvent },
}
export type Controller = {
	definitions: { Definition },
	models: { [string]: Model },
	update: (Controller, BattleView, number) -> (),
	createActor: (Controller, string, Role) -> Model,
	syncActors: (Controller, BattleView, number) -> (),
	destroy: (Controller) -> (),
}
type WorldView = { scene: Model, plots: { { frame: CFrame } } }
type ActorRecord = {
	model: Model,
	life: number,
	source: string,
	role: Role,
	neutral: boolean,
	bar: Frame,
	label: TextLabel,
	attacks: number,
	shots: number,
}
type SiteRecord = {
	model: Model,
	flag: BasePart,
	prompt: ProximityPrompt,
	segments: { BasePart },
	label: TextLabel,
	bar: Frame,
	color: Color3?,
}
type Effect = {
	model: Model,
	born: number,
	duration: number,
	from: Vector3,
	destination: Vector3,
	projectile: boolean,
	kind: string?,
	arc: number,
}
local neutralColor = Color3.fromRGB(157, 151, 130)
local woodColor = Color3.fromRGB(113, 82, 50)
local stoneColor = Color3.fromRGB(177, 168, 143)
local cultures: { [string]: { name: string, color: Color3 }? } = {}
for _, civilization in Civilizations do
	cultures[civilization.id] = civilization
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, frame
	object.Color, object.Material = color, material
	object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end
local function billboard(parent: BasePart, name: string, size: Vector2, offset: Vector3, range: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size = name, UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace, gui.MaxDistance, gui.AlwaysOnTop = offset, range, true
	gui.Parent = parent
	return gui
end
local function label(parent: Instance, name: string, height: number): TextLabel
	local object = Instance.new("TextLabel")
	object.Name, object.Size = name, UDim2.new(1, 0, 0, height)
	object.BackgroundTransparency, object.BorderSizePixel = 1, 0
	object.TextColor3, object.TextStrokeTransparency = Color3.fromRGB(250, 242, 219), 0.25
	object.Font, object.TextSize, object.TextWrapped = Enum.Font.GothamMedium, 12, true
	object.Parent = parent
	return object
end
local function progressBar(parent: Instance, name: string, y: number, color: Color3): Frame
	local background = Instance.new("Frame")
	background.Name, background.Position, background.Size = name, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, 6)
	background.BackgroundColor3, background.BorderSizePixel = Color3.fromRGB(48, 44, 36), 0
	local fill = Instance.new("Frame")
	fill.Name, fill.Size, fill.BackgroundColor3, fill.BorderSizePixel = "Fill", UDim2.fromScale(0, 1), color, 0
	fill.Parent, background.Parent = background, parent
	return fill
end
local function neutralTeam(team: Team): boolean
	return type(team) == "string" and string.sub(team, 1, 8) == "neutral:"
end
local function cloneActor(civilizationId: string, role: Role): Model
	local neutral = civilizationId == "neutral"
	assert(not neutral or role ~= "mounted", "Neutral defenders have no mounted roster")
	local model = if role == "mounted"
		then MountedTroops.create(civilizationId)
		else OriginalTroops.create(if neutral then "sparta" else civilizationId, role, neutral)
	model:SetAttribute("DisplayName", model:GetAttribute("OriginalDisplayName"))
	return model
end

local function createSite(definition: Definition, frame: CFrame): SiteRecord
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = definition.id, frame
	model:SetAttribute("OutpostId", definition.id)
	model:SetAttribute("LineId", definition.lineId)
	model:SetAttribute("Radius", definition.radius)
	model:SetAttribute("CaptureProgress", 0)
	model:SetAttribute("CaptureStatus", "neutral")
	model:SetAttribute("VisualOnly", true)
	local segments = {}
	for index = 0, 31 do
		local angle = index * math.pi / 16
		local point = Vector3.new(math.sin(angle) * definition.radius, 0.07, math.cos(angle) * definition.radius)
		table.insert(
			segments,
			part(
				model,
				"CaptureBoundary",
				Vector3.new(1.1, 0.12, 2 * definition.radius * math.tan(math.pi / 32)),
				frame * CFrame.new(point) * CFrame.Angles(0, angle + math.pi / 2, 0),
				neutralColor,
				Enum.Material.Pebble
			)
		)
	end
	local camp = Instance.new("Model")
	camp.Name, camp.WorldPivot = "NeutralCamp", CFrame.identity
	local footing =
		part(camp, "CampFooting", Vector3.new(23, 1, 17), CFrame.new(0, 0.5, -4), stoneColor, Enum.Material.Limestone)
	footing.CanQuery = true
	footing:SetAttribute("OriginalTroopSupport", true)
	part(camp, "LowSupplyWall", Vector3.new(18, 4, 1), CFrame.new(0, 3, -10), stoneColor, Enum.Material.Limestone)
	for _, x in { -8, 8 } do
		part(camp, "ShadePost", Vector3.new(0.7, 7, 0.7), CFrame.new(x, 4.5, -2), woodColor, Enum.Material.Wood)
	end
	for _, side in { -1, 1 } do
		part(
			camp,
			"PlainClothShade",
			Vector3.new(9.5, 0.25, 10),
			CFrame.new(side * 4.4, 8.4, -5) * CFrame.Angles(0, 0, -side * math.rad(14)),
			Color3.fromRGB(204, 189, 147),
			Enum.Material.Fabric
		)
	end
	for index = 1, 2 + definition.lineId % 3 do
		part(
			camp,
			"SupplyCrate",
			Vector3.new(2.8, 2.2, 2.8),
			CFrame.new(-6 + index * 3.2, 2.1, -8),
			woodColor,
			Enum.Material.WoodPlanks
		)
	end
	camp:ScaleTo(0.25)
	camp:PivotTo(frame)
	camp.Parent = model
	OutpostScenery.create(model, frame, definition.lineId)
	part(
		model,
		"FlagPole",
		Vector3.new(0.13, 4.5, 0.13),
		frame * CFrame.new(-3, 2.25, 0),
		woodColor,
		Enum.Material.Wood
	)
	local flag = part(
		model,
		"Flag",
		Vector3.new(1.8, 1.15, 0.07),
		frame * CFrame.new(-2.05, 3.5, 0),
		neutralColor,
		Enum.Material.Fabric
	)
	flag:SetAttribute("OutpostId", definition.id)
	local target = part(
		model,
		"Target",
		Vector3.new(1, 1, 1),
		frame * CFrame.new(0, 1.7, 0),
		neutralColor,
		Enum.Material.SmoothPlastic
	)
	target.Transparency = 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "TargetOutpost", "Send army", "Neutral outpost"
	prompt:SetAttribute("OutpostId", definition.id)
	prompt:SetAttribute("ArmyTarget", true)
	prompt.KeyboardKeyCode, prompt.HoldDuration, prompt.MaxActivationDistance = Enum.KeyCode.E, 0, 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = target
	local gui = billboard(target, "CaptureDisplay", Vector2.new(180, 54), Vector3.new(0, 3.6, 0), 190)
	local text = label(gui, "CaptureLabel", 42)
	text.Text = "Neutral outpost"
	local bar = progressBar(gui, "CaptureBar", 46, Color3.fromRGB(220, 183, 85))
	return { model = model, flag = flag, prompt = prompt, segments = segments, label = text, bar = bar, color = nil }
end

function OutpostWorld.create(world: WorldView): Controller
	assert(
		not world.scene:FindFirstChild("Outposts") and not world.scene:FindFirstChild("BattleActors"),
		"Outpost visuals already exist"
	)
	local folder, actorFolder, effectFolder = Instance.new("Folder"), Instance.new("Folder"), Instance.new("Folder")
	folder.Name, actorFolder.Name, effectFolder.Name = "Outposts", "BattleActors", "BattleEffects"
	local definitions: { Definition }, models: { [string]: Model } = {}, {}
	local sites: { [string]: SiteRecord? }, actors: { [string]: ActorRecord? } = {}, {}
	local effects: { Effect } = {}
	local lastEvents: { BattleEvent }? = nil
	local destroyed = false
	local destroyingConnection: RBXScriptConnection? = nil
	local shots, hits, deaths, captures, bandages = 0, 0, 0, 0, 0
	for plotId, plot in world.plots do
		local frame = plot.frame * CFrame.new(0, 0, -110)
		local definition: Definition = {
			id = "outpost_" .. plotId,
			x = frame.Position.X,
			z = frame.Position.Z,
			radius = 22,
			lineId = plotId,
			nextId = nil,
		}
		local site = createSite(definition, frame)
		definitions[#definitions + 1], models[definition.id], sites[definition.id] = definition, site.model, site
		site.model.Parent = folder
	end
	folder.Parent, actorFolder.Parent, effectFolder.Parent = world.scene, world.scene, world.scene
	local function dispose()
		if destroyed then
			return
		end
		destroyed = true
		if destroyingConnection then
			destroyingConnection:Disconnect()
			destroyingConnection = nil
		end
		folder:Destroy()
		actorFolder:Destroy()
		effectFolder:Destroy()
		table.clear(actors)
		table.clear(sites)
		table.clear(models)
		table.clear(effects)
		lastEvents = nil
	end
	local function update(_self: Controller, battle: BattleView, _now: number): ()
		if destroyed then
			return
		end
		local neutralCounts: { [string]: number? } = {}
		local teamCivilizations: { [Team]: string? } = {}
		for _, actor in battle.actors do
			if actor and actor.alive then
				teamCivilizations[actor.team] = actor.civilizationId
				if neutralTeam(actor.team) then
					local id = string.sub(tostring(actor.team), 9)
					neutralCounts[id] = (neutralCounts[id] or 0) + 1
				end
			end
		end
		for id, site in sites do
			if not site then
				continue
			end
			local state = battle.outposts[id]
			local ownerId = state and state.ownerCivilizationId
			local culture = ownerId and cultures[ownerId]
			local color = if culture then culture.color else neutralColor
			local progress = math.clamp(if state then state.progress else 0, 0, 20)
			local status = if state then state.status else "neutral"
			site.model:SetAttribute("OwnerTeam", if state then state.ownerTeam else nil)
			site.model:SetAttribute("OwnerCivilizationId", ownerId)
			site.model:SetAttribute("CaptureTeam", if state then state.captureTeam else nil)
			site.model:SetAttribute("CaptureProgress", progress)
			site.model:SetAttribute("CaptureStatus", status)
			site.model:SetAttribute("NeutralDefenders", neutralCounts[id] or 0)
			site.flag:SetAttribute("OwnerCivilizationId", ownerId)
			if color ~= site.color then
				site.color, site.flag.Color = color, color
				for _, segment in site.segments do
					segment.Color = color:Lerp(stoneColor, 0.45)
				end
			end
			local heading = if culture then culture.name .. " outpost" else "Neutral outpost"
			local detail = if status == "capturing"
				then string.format("Capturing %.1f / 20s", progress)
				elseif status == "contested" then string.format("Contested · %.1f / 20s", progress)
				elseif progress > 0 and status ~= "owned" then string.format("Paused · %.1f / 20s", progress)
				elseif (neutralCounts[id] or 0) > 0 then "Defended · "
					.. tostring(neutralCounts[id])
					.. " neutral guards"
				else if culture then "Captured" else "Awaiting capture"
			site.label.Text = heading .. "\n" .. detail
			site.prompt.ObjectText = heading
			site.bar.Size = UDim2.fromScale(progress / 20, 1)
			local capturingId = state and state.captureTeam and teamCivilizations[state.captureTeam]
			local capturingCulture = capturingId and cultures[capturingId]
			site.bar.BackgroundColor3 = if status == "contested"
				then Color3.fromRGB(196, 102, 73)
				elseif capturingCulture then capturingCulture.color
				else Color3.fromRGB(220, 183, 85)
		end
	end
	local function actorVisual(_self: Controller, civilizationId: string, role: Role): Model
		assert(not destroyed, "Outpost visual adapter is destroyed")
		return cloneActor(civilizationId, role)
	end
	local function newRecord(actor: Actor, now: number): ActorRecord
		local neutral = neutralTeam(actor.team)
		local sourceId = if neutral then "neutral" else actor.civilizationId
		local model = cloneActor(sourceId, actor.role)
		model.Name = actor.id
		model:SetAttribute("ActorId", actor.id)
		model:SetAttribute("Life", actor.life)
		OriginalTroops.pose(model, actor, now)
		model:SetAttribute("Role", actor.role)
		model:SetAttribute("Team", actor.team)
		model:SetAttribute("BuildingId", actor.buildingId)
		local head = model:FindFirstChild("Head")
		assert(head and head:IsA("BasePart"), "Battle actor preview has no head")
		local gui = billboard(head, "HealthDisplay", Vector2.new(82, 30), Vector3.new(0, 0.65, 0), 100)
		local text = label(gui, "RoleLabel", 20)
		text.Text = tostring(model:GetAttribute("OriginalDisplayName"))
		local bar = progressBar(
			gui,
			"HealthBar",
			23,
			if neutral then Color3.fromRGB(174, 155, 112) else Color3.fromRGB(113, 178, 102)
		)
		return {
			model = model,
			life = actor.life,
			source = actor.civilizationId,
			role = actor.role,
			neutral = neutral,
			bar = bar,
			label = text,
			attacks = 0,
			shots = 0,
		}
	end
	local function projectileKind(actor: Actor?): string
		local variant = if actor and not neutralTeam(actor.team)
			then OriginalRanged.variants[actor.civilizationId]
			else nil
		return if variant then variant.projectileKind else "arrow"
	end
	local function projectileHeight(id: string?): number
		local record = id and actors[id]
		return if record then record.model:GetPivot().Position.Y + 0.25 else 1
	end
	local function addEffect(event: BattleEvent, now: number, kind: string?)
		local projectile = kind ~= nil
		if not event.x or not event.z then
			return
		end
		if projectile and (not event.targetX or not event.targetZ) then
			return
		end
		while #effects >= 96 do
			local oldest = table.remove(effects, 1)
			oldest.model:Destroy()
		end
		local from = if not projectile
				and event.targetX
				and event.targetZ
			then Vector3.new(event.targetX, projectileHeight(event.targetId), event.targetZ)
			else Vector3.new(event.x, projectileHeight(event.actorId), event.z)
		local destination = if projectile
			then Vector3.new(event.targetX or event.x, projectileHeight(event.targetId), event.targetZ or event.z)
			else from
		local model = Instance.new("Model")
		model.Name = if projectile then "Projectile_" .. (kind or "arrow") else "ContactCue"
		model.WorldPivot = CFrame.identity
		model:SetAttribute("VisualOnly", true)
		model:SetAttribute("ActorId", event.actorId)
		model:SetAttribute("ActorLife", event.actorLife)
		local distance = (destination - from).Magnitude
		local duration, arc = 0.22, 0
		if projectile then
			model:SetAttribute("VisualProjectile", true)
			model:SetAttribute("ProjectileKind", kind)
			model:SetAttribute("OriginalProjectileScale", 0.25)
			-- Match the unchanged TroopProjectile.fire/MedicalService.make visuals.
			local size = Vector3.new(0.18, 0.18, if kind == "spear" then 3 else 1.8)
			local material, shape = Enum.Material.Wood, Enum.PartType.Block
			local color = Color3.fromRGB(214, 174, 85)
			if kind == "bullet" or kind == "stone" then
				size, shape = Vector3.new(0.4, 0.4, 0.4), Enum.PartType.Ball
				material = if kind == "bullet" then Enum.Material.Neon else Enum.Material.Slate
			elseif kind == "axe" then
				size, material = Vector3.new(0.7, 0.7, 0.2), Enum.Material.Metal
			elseif kind == "bandage" then
				size, material, shape = Vector3.new(0.7, 0.45, 0.45), Enum.Material.Fabric, Enum.PartType.Cylinder
				color = Color3.fromRGB(246, 238, 212)
			end
			local object = part(model, kind or "arrow", size, CFrame.identity, color, material)
			object.Shape = shape
			model:ScaleTo(0.25)
			if kind == "bandage" then
				duration = math.clamp(distance / (OriginalMedical.speed * 0.25), 0.12, 0.9)
				arc = OriginalMedical.arc * 0.25
			else
				duration = math.clamp(distance / (OriginalRanged.speed * 0.25), 0.05, 3)
			end
		else
			local flash = part(
				model,
				"ContactFlash",
				Vector3.new(0.25, 0.25, 0.25),
				CFrame.identity,
				Color3.fromRGB(235, 188, 86),
				Enum.Material.Neon
			)
			flash.Shape = Enum.PartType.Ball
		end
		model:PivotTo(CFrame.new(from))
		model.Parent = effectFolder
		table.insert(effects, {
			model = model,
			born = now,
			duration = duration,
			from = from,
			destination = destination,
			projectile = projectile,
			kind = kind,
			arc = arc,
		})
	end

	local function syncActors(_self: Controller, battle: BattleView, now: number): ()
		if destroyed then
			return
		end
		-- Death is a server event for this exact life, never inferred from removal.
		if battle.events ~= lastEvents then
			for _, event in battle.events do
				local id = event.actorId
				local record = id and actors[id]
				local actor = id and battle.actors[id]
				if
					event.kind == "death"
					and record
					and event.actorLife == record.life
					and (not actor or (not actor.alive and actor.life == record.life))
				then
					-- Capture can remove a defeated guard before this visual sync.
					-- Its exact-life server death event remains authoritative.
					local model = record.model
					model:SetAttribute("Alive", false)
					model:SetAttribute("Health", 0)
					local gui = model:FindFirstChild("HealthDisplay", true)
					if gui and gui:IsA("BillboardGui") then
						gui.Enabled = false
					end
					model:SetAttribute(
						"DeathNotice",
						HttpService:JSONEncode({ actorId = id, life = record.life, time = Workspace:GetServerTimeNow() })
					)
					actors[id] = nil
					task.delay(RagdollConfig.sourceRetireSeconds, function()
						model:Destroy()
					end)
				end
			end
		end
		local retained: { [string]: boolean? } = {}
		for id, actor in battle.actors do
			if not actor or not actor.alive then
				continue
			end
			retained[id] = true
			local record = actors[id]
			if
				record
				and (
					record.life ~= actor.life
					or record.source ~= actor.civilizationId
					or record.role ~= actor.role
					or record.neutral ~= neutralTeam(actor.team)
				)
			then
				record.model:Destroy()
				actors[id], record = nil, nil
			end
			if not record then
				record = newRecord(actor, now)
				actors[id] = record
			end
			record.model:SetAttribute("Health", actor.health)
			record.model:SetAttribute("MaxHealth", actor.maxHealth)
			record.model:SetAttribute("TargetOutpostId", actor.targetOutpostId)
			record.model:SetAttribute("TargetId", actor.targetId)
			record.model:SetAttribute("Phase", actor.phase)
			record.model:SetAttribute("Alive", true)
			record.bar.Size = UDim2.fromScale(math.clamp(actor.health / math.max(1, actor.maxHealth), 0, 1), 1)
			if not record.model.Parent then
				record.model.Parent = actorFolder
			end
		end
		for id, record in actors do
			if record and not retained[id] then
				record.model:Destroy()
				actors[id] = nil
			end
		end
		if battle.events ~= lastEvents then
			lastEvents = battle.events
			for _, event in battle.events do
				if event.kind == "attack" or event.kind == "shot" then
					local record = event.actorId and actors[event.actorId]
					if record and (not event.actorLife or record.life == event.actorLife) then
						record.attacks += 1
						record.model:SetAttribute("AttackCount", record.attacks)
						record.model:SetAttribute("LastAttackAt", event.time or now)
						if event.kind == "shot" then
							record.shots += 1
							record.model:SetAttribute("ShotCount", record.shots)
						end
					end
					if event.kind == "shot" then
						shots += 1
						addEffect(
							event,
							now,
							projectileKind(if event.actorId then battle.actors[event.actorId] else nil)
						)
					end
				elseif event.kind == "hit" then
					hits += 1
					addEffect(event, now, nil)
				elseif event.kind == "bandage" then
					bandages += 1
					addEffect(event, now, "bandage")
				elseif event.kind == "death" then
					deaths += 1
				elseif event.kind == "capture" then
					captures += 1
				end
			end
			effectFolder:SetAttribute("Shots", shots)
			effectFolder:SetAttribute("Bandages", bandages)
			effectFolder:SetAttribute("Hits", hits)
			effectFolder:SetAttribute("Deaths", deaths)
			effectFolder:SetAttribute("Captures", captures)
		end
		for id, record in actors do
			local actor = battle.actors[id]
			if record and actor then
				OriginalTroops.pose(record.model, actor, now)
			end
		end

		for index = #effects, 1, -1 do
			local effect = effects[index]
			local progress = (now - effect.born) / effect.duration
			if progress >= 1 then
				effect.model:Destroy()
				table.remove(effects, index)
				continue
			end
			local point = effect.from:Lerp(effect.destination, math.clamp(progress, 0, 1))
			point += Vector3.new(0, math.sin(progress * math.pi) * effect.arc, 0)
			if effect.projectile and effect.kind ~= "bandage" then
				local forward = effect.destination - effect.from
				if forward.Magnitude < 0.001 then
					forward = Vector3.new(0, 0, -1)
				end
				effect.model:PivotTo(CFrame.lookAt(point, point + forward))
			else
				effect.model:PivotTo(CFrame.new(point))
			end
		end
		effectFolder:SetAttribute("ActiveEffects", #effects)
	end
	local controller: Controller = {
		definitions = definitions,
		models = models,
		update = update,
		createActor = actorVisual,
		syncActors = syncActors,
		destroy = function(_self: Controller)
			dispose()
		end,
	}
	destroyingConnection = world.scene.Destroying:Once(dispose)
	return controller
end
return table.freeze(OutpostWorld)

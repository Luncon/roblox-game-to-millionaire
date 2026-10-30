--!strict
-- Presentation only: authority and damage stay on the replicated server actors.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Ragdolls = require(script.Parent.Ragdolls)
local RagdollConfig = require(ReplicatedStorage.MiniatureGame.RagdollConfig)
local Codec = require(ReplicatedStorage.MiniatureGame.PoseCodec)
local Interpolation = require(ReplicatedStorage.MiniatureGame.PoseInterpolation)
local Kinematics = require(ReplicatedStorage.MiniatureGame.RigKinematics)
local Renderer = {}
export type Options = { sourceFolder: Instance?, interpolationDelay: number? }
export type Controller = { folder: Folder, destroy: () -> () }
type Adornment = { object: BillboardGui | Highlight, original: Instance?, target: Instance }
type Record = {
	source: Model,
	history: Interpolation.History,
	life: number?,
	visual: Model?,
	rig: Kinematics.Rig?,
	connections: { RBXScriptConnection },
	hidden: { [BasePart | Decal]: number },
	adornments: { Adornment },
	previousActive: unknown,
	dead: boolean,
	deathConsumed: boolean,
}
local controllers: { [ScreenGui]: Controller } = setmetatable({}, { __mode = "k" })

local function restore(record: Record)
	for _, entry in record.adornments do
		if entry.object.Parent and entry.object.Adornee == entry.target then
			entry.object.Adornee = entry.original
		end
	end
	table.clear(record.adornments)
	for part, previous in record.hidden do
		if part.Parent and part.LocalTransparencyModifier == 1 then
			part.LocalTransparencyModifier = previous
		end
	end
	table.clear(record.hidden)
	if record.visual then
		record.visual:Destroy()
	end
	record.visual, record.rig = nil, nil
	if record.source:GetAttribute("ClientSmoothingActive") == true then
		record.source:SetAttribute("ClientSmoothingActive", record.previousActive)
	end
end

local function adorn(record: Record, object: Instance)
	local visual = record.visual
	if not visual then
		return
	end
	if object:IsA("BasePart") or object:IsA("Decal") then
		if record.hidden[object] == nil then
			record.hidden[object] = object.LocalTransparencyModifier
		end
		object.LocalTransparencyModifier = 1
	elseif object:IsA("BillboardGui") or object:IsA("Highlight") then
		for _, entry in record.adornments do
			if entry.object == object then
				return
			end
		end
		local target: Instance? = if object:IsA("Highlight") then visual else visual:FindFirstChild("Head")
		if target then
			table.insert(record.adornments, { object = object, original = object.Adornee, target = target })
			object.Adornee = target
		end
	end
end

local function mount(record: Record, folder: Folder, sourceFolder: Instance, delay: number, oneSample: boolean?)
	if record.visual or #record.history.samples < (if oneSample then 1 else 2) then
		return
	end
	local expected = record.source:GetAttribute("PosePartCount")
	local expectedVisuals = record.source:GetAttribute("PoseVisualCount")
	if typeof(expected) ~= "number" or expected < 7 or typeof(expectedVisuals) ~= "number" then
		return
	end
	local count, visualCount = 0, 0
	for _, object in record.source:GetDescendants() do
		if Kinematics.isAppearance(object) then
			visualCount += 1
		end
		if object:IsA("BasePart") then
			count += 1
		end
	end
	if count ~= expected or visualCount ~= expectedVisuals then
		return
	end
	local visual = record.source:Clone()
	local clonedCount = 0
	for _, object in visual:GetDescendants() do
		if
			object:IsA("BaseScript")
			or object:IsA("Animator")
			or object:IsA("BillboardGui")
			or object:IsA("Highlight")
		then
			object:Destroy()
		elseif object:IsA("BasePart") then
			clonedCount += 1
			object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
			object.LocalTransparencyModifier = 0
		elseif object:IsA("Decal") then
			object.LocalTransparencyModifier = 0
		elseif object:IsA("Tool") then
			object.Enabled, object.CanBeDropped = false, false
		end
	end
	if clonedCount ~= expected then
		visual:Destroy()
		return
	end
	local rig = Kinematics.new(visual)
	if not rig then
		visual:Destroy()
		return
	end
	visual.Name = record.source.Name
	visual:SetAttribute("ClientTroopVisual", true)
	visual:SetAttribute("ClientSmoothingActive", nil)
	visual:SetAttribute("PoseSnapshot", nil)
	local snapshot = Interpolation.sample(record.history, Workspace:GetServerTimeNow() - delay)
	if not snapshot then
		visual:Destroy()
		return
	end
	Kinematics.apply(rig, snapshot, { folder, sourceFolder, visual })
	record.visual, record.rig = visual, rig
	visual.Parent = folder
	for _, object in record.source:GetDescendants() do
		adorn(record, object)
	end
	record.source:SetAttribute("ClientSmoothingActive", true)
end

function Renderer.start(screen: ScreenGui, options: Options?): Controller
	local existing = controllers[screen]
	if existing then
		return existing
	end
	local settings = options or {}
	local delay = math.clamp(settings.interpolationDelay or 0.15, 0.05, 0.3)
	local folder = Instance.new("Folder")
	folder.Name = if settings.sourceFolder
		then "MiniatureClientActors_" .. settings.sourceFolder.Name
		else "MiniatureClientActors"
	folder.Parent = Workspace
	local ragdolls = Ragdolls.start(if settings.sourceFolder then "_" .. settings.sourceFolder.Name else nil)
	local records: { [Model]: Record } = {}
	local connections: { RBXScriptConnection } = {}
	local sourceConnections: { RBXScriptConnection } = {}
	local sourceFolder: Instance? = nil
	local stopped = false
	local controller: Controller
	local function remove(source: Model)
		local record = records[source]
		if not record then
			return
		end
		records[source] = nil
		for _, connection in record.connections do
			connection:Disconnect()
		end
		restore(record)
	end
	local function add(object: Instance)
		if not object:IsA("Model") or records[object] then
			return
		end
		local record: Record = {
			source = object,
			history = Interpolation.new(8, 0.5),
			life = nil,
			visual = nil,
			rig = nil,
			connections = {},
			hidden = {},
			adornments = {},
			previousActive = object:GetAttribute("ClientSmoothingActive"),
			dead = false,
			deathConsumed = false,
		}
		records[object] = record
		local function death(): boolean
			local encoded = object:GetAttribute("DeathNotice")
			if type(encoded) ~= "string" or #encoded > 512 or object:GetAttribute("Alive") ~= false then
				return false
			end
			local ok, notice = pcall(function()
				return HttpService:JSONDecode(encoded)
			end)
			local now = Workspace:GetServerTimeNow()
			if
				not ok
				or type(notice) ~= "table"
				or notice.actorId ~= (object:GetAttribute("ActorId") or object.Name)
				or notice.life ~= record.life
				or type(notice.time) ~= "number"
				or notice.time ~= notice.time
				or notice.time > now + 0.5
				or now - notice.time > RagdollConfig.noticeMaxAge
			then
				return false
			end
			record.dead = true
			if record.deathConsumed then
				return true
			end
			if not record.visual and sourceFolder then
				mount(record, folder, sourceFolder, delay, true)
			end
			local visual = record.visual
			if visual then
				local samples = record.history.samples
				local first, last = samples[#samples - 1], samples[#samples]
				local velocity = if first
						and last
						and last.time > first.time
					then (last.root.Position - first.root.Position) / (last.time - first.time)
					else Vector3.zero
				record.visual, record.rig, record.deathConsumed = nil, nil, true
				ragdolls.spawn(visual, notice, velocity)
			end
			return true
		end
		local function receive()
			local life = object:GetAttribute("Life")
			if typeof(life) ~= "number" then
				return
			end
			if record.life ~= life then
				restore(record)
				Interpolation.clear(record.history, life)
				record.life = life
				record.dead, record.deathConsumed = false, false
			end
			local snapshot = Codec.decode(object:GetAttribute("PoseSnapshot"))
			if not snapshot or snapshot.life ~= life then
				return
			end
			local accepted = Interpolation.push(record.history, snapshot)
			if death() then
				return
			end
			if accepted and sourceFolder then
				mount(record, folder, sourceFolder, delay)
			end
		end
		table.insert(record.connections, object:GetAttributeChangedSignal("PoseSnapshot"):Connect(receive))
		table.insert(record.connections, object:GetAttributeChangedSignal("Life"):Connect(receive))
		table.insert(record.connections, object:GetAttributeChangedSignal("DeathNotice"):Connect(receive))
		table.insert(record.connections, object:GetAttributeChangedSignal("Alive"):Connect(receive))
		table.insert(record.connections, object:GetAttributeChangedSignal("PoseVisualCount"):Connect(receive))
		table.insert(
			record.connections,
			object:GetAttributeChangedSignal("PosePartCount"):Connect(function()
				if sourceFolder then
					if not death() then
						mount(record, folder, sourceFolder, delay)
					end
				end
			end)
		)
		table.insert(
			record.connections,
			object.DescendantAdded:Connect(function(descendant)
				adorn(record, descendant)
				receive()
				if sourceFolder then
					if not death() then
						mount(record, folder, sourceFolder, delay)
					end
				end
			end)
		)
		receive()
	end
	local function bind(nextFolder: Instance?)
		if nextFolder == sourceFolder then
			return
		end
		for _, connection in sourceConnections do
			connection:Disconnect()
		end
		table.clear(sourceConnections)
		for source in records do
			remove(source)
		end
		if sourceFolder then
			ragdolls.clear()
		end
		sourceFolder = nextFolder
		if not nextFolder then
			return
		end
		table.insert(sourceConnections, nextFolder.ChildAdded:Connect(add))
		table.insert(
			sourceConnections,
			nextFolder.ChildRemoved:Connect(function(object)
				if object:IsA("Model") then
					remove(object)
				end
			end)
		)
		for _, child in nextFolder:GetChildren() do
			add(child)
		end
	end
	local function destroy()
		if stopped then
			return
		end
		stopped = true
		for _, connection in connections do
			connection:Disconnect()
		end
		bind(nil)
		ragdolls.destroy()
		folder:Destroy()
		controllers[screen] = nil
	end
	controller = { folder = folder, destroy = destroy }
	controllers[screen] = controller
	table.insert(connections, screen.Destroying:Connect(destroy))
	local scanAt = 0
	table.insert(
		connections,
		RunService.PreRender:Connect(function()
			local now = Workspace:GetServerTimeNow()
			if now >= scanAt then
				scanAt = now + 0.25
				local sandbox = Workspace:FindFirstChild("MiniatureSandbox")
				local candidate = settings.sourceFolder or (sandbox and sandbox:FindFirstChild("BattleActors"))
				bind(if candidate and candidate.Parent then candidate else nil)
			end
			local source = sourceFolder
			if not source then
				return
			end
			for _, record in records do
				local rig, visual = record.rig, record.visual
				local snapshot = Interpolation.sample(record.history, now - delay)
				if rig and visual and snapshot and not record.dead then
					Kinematics.apply(rig, snapshot, { folder, source })
					visual:SetAttribute("RenderedPoseTime", snapshot.time)
					local latest = record.history.samples[#record.history.samples]
					visual:SetAttribute("SourcePoseTime", latest.time)
				end
			end
		end)
	)
	return controller
end
return table.freeze(Renderer)

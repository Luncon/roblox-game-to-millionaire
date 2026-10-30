--!strict
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(game:GetService("ReplicatedStorage").MiniatureGame.Config)
local Tenders = require(ServerStorage.Appearance.FarmTenders)
local Workers = {}
local group = "MiniatureSandboxWorkers"

local function create(parent, id, userId)
	if not PhysicsService:IsCollisionGroupRegistered(group) then
		PhysicsService:RegisterCollisionGroup(group)
	end
	PhysicsService:CollisionGroupSetCollidable(group, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(group, group, false)
	local source = ServerStorage.FarmTemplates.farmer:Clone()
	source:ScaleTo(Config.scale)
	local model = Tenders.prepare(source)
	source:Destroy()
	model.Name = id
	model:SetAttribute("WorkerId", id)
	model:SetAttribute("OwnerId", userId)
	model:SetAttribute("PresentationRole", "worker")
	model.Parent = parent
	-- Attaching the fresh clothing Humanoid can initialize torso collision even
	-- with its state machine disabled. Sanitize the completed, parented clone.
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.CollisionGroup = group
		end
	end
	return model
end

function Workers.clear(plot)
	for _, model in plot.actors:GetChildren() do
		model:Destroy()
	end
	plot.workerState = nil
end

function Workers.sync(plot, state, userId)
	local retained = {}
	for _, worker in state.workers do
		retained[worker.id] = true
		local model = plot.actors:FindFirstChild(worker.id)
		if not model then
			model = create(plot.actors, worker.id, userId)
		end
		model:SetAttribute("BuildingId", worker.buildingId)
	end
	for _, model in plot.actors:GetChildren() do
		if model:GetAttribute("PresentationRole") == "worker" and not retained[model.Name] then
			model:Destroy()
		end
	end
	plot.workerState = state
end

function Workers.animate(plot, now: number)
	local state = plot.workerState
	if not state then
		return
	end
	local buildings = {}
	for _, building in state.buildings do
		buildings[building.id] = building
	end
	local assignments = {}
	for index, worker in state.workers do
		local model = plot.actors:FindFirstChild(worker.id)
		if model then
			local building = buildings[worker.buildingId]
			local frame, working
			if building then
				assignments[building.id] = (assignments[building.id] or 0) + 1
				local side = if assignments[building.id] % 2 == 1 then -1 else 1
				local phase = (now + index * 2) % 12
				working = phase < 2 or (phase >= 6 and phase < 8)
				local z = if phase < 2 then -2 elseif phase < 6 then phase - 4 elseif phase < 8 then 2 else 10 - phase
				local facing = if phase < 8 then 1 else -1
				local base = plot.frame
					* CFrame.new(building.x, if building.kind == "farm" then 0.82 else 0.65, building.z)
					* CFrame.Angles(0, math.rad(building.rotation), 0)
				local point = Vector3.new(side * 1.2, 0, z)
				frame = base * CFrame.lookAt(point, point + Vector3.new(0, 0, facing))
			else
				working = false
				frame = plot.frame * CFrame.new(-14 + index * 0.8, 0.45, 13)
			end
			Tenders.pose(model, frame, math.sin(now * (if working then 4 else 9)) * 0.4, working)
		end
	end
end

return Workers

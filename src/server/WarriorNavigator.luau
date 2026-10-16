--!strict

local PathfindingService = game:GetService("PathfindingService")
local Rules = require(script.Parent.CombatRules)
local Tuning = require(game.ReplicatedStorage.Shared.TacticalCombatConfig)
local WarriorNavigator = {}

local function flatDistance(a: Vector3, b: Vector3): number
	local delta = a - b
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

function WarriorNavigator.new(rig: Model, isActive: () -> boolean)
	local humanoid = rig:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local controller = {}
	local alive = true
	local goal: Vector3? = nil
	local plannedGoal: Vector3? = nil
	local waypoints = {}
	local nextWaypoint = 1
	local path: Path? = nil
	local blockedConnection: RBXScriptConnection? = nil
	local sequence = 0
	local pending: number? = nil
	local lastCompute = -math.huge
	local blocked = true
	local lastProgress = os.clock()
	local lastPosition = root.Position

	local function active(): boolean
		return alive and rig.Parent ~= nil and root.Parent ~= nil and humanoid.Health > 0 and isActive()
	end
	local function clearRoute()
		if blockedConnection then blockedConnection:Disconnect(); blockedConnection = nil end
		if path then path:Destroy(); path = nil end
		waypoints = {}
		nextWaypoint = 1
	end
	function controller:stop()
		sequence += 1
		goal = nil
		plannedGoal = nil
		blocked = true
		lastProgress = os.clock()
		if root.Parent then lastPosition = root.Position end
		clearRoute()
		if root.Parent and humanoid.Parent then humanoid:MoveTo(root.Position) end
	end
	function controller:destroy()
		alive = false
		self:stop()
	end
	-- Only used for server-chosen legs inside the clear, bounded training yard.
	function controller:walkDirect(position: Vector3)
		if not active() then return end
		self:stop()
		humanoid:MoveTo(position)
		rig:SetAttribute("NavigationStatus","Walking inside training yard")
	end
	function controller:setGoal(position: Vector3)
		if not active() then return end
		goal = position
	end

	-- Short encounter legs need tighter stopping than travelling waypoints.
	-- Ray/volume checks keep local steering on supported ground and out of walls.
	function controller:walkCombat(position: Vector3,world): boolean
		if not active() then return false end
		local arena=world.model.Battlefield
		local distance=flatDistance(root.Position,position)
		if distance>Tuning.closeDistance or not Rules.containsArena(arena,position) then return false end
		local terrain=RaycastParams.new()
		terrain.FilterType=Enum.RaycastFilterType.Include
		local surfaces={world.model.Ground,workspace.Terrain}
		local landscape=world.model:FindFirstChild("Landscape")
		if landscape and landscape:FindFirstChild("TerrainSurface") then table.insert(surfaces,landscape.TerrainSurface) end
		terrain.FilterDescendantsInstances=surfaces
		terrain.RespectCanCollide=true
		local function support(point)
			return workspace:Raycast(point+Vector3.new(0,8,0),Vector3.new(0,-24,0),terrain)
		end
		local below=support(root.Position)
		local endGround=support(position)
		if not below or not endGround or endGround.Normal.Y<.65 then return false end
		local height=math.clamp(root.Position.Y-below.Position.Y,2.5,4)
		local destination=Vector3.new(position.X,endGround.Position.Y+height,position.Z)
		local delta=destination-root.Position
		for fraction=.25,1,.25 do
			local point=root.Position+delta*fraction
			local hit=support(point)
			if not hit or hit.Normal.Y<.65 or math.abs(point.Y-height-hit.Position.Y)>2 then return false end
		end
		local filter=RaycastParams.new()
		filter.FilterType=Enum.RaycastFilterType.Exclude
		local exclude={rig}
		for _,name in {"Troops","NeutralOpponents","TroopProjectiles"}do
			for _,child in world.model:GetChildren()do if child.Name==name then table.insert(exclude,child)end end
		end
		filter.FilterDescendantsInstances=exclude
		filter.RespectCanCollide=true
		if delta.Magnitude>.01 and workspace:Blockcast(CFrame.new(root.Position+Vector3.new(0,.5,0)),Vector3.new(1.6,3.6,1.6),delta,filter) then return false end
		-- Cancel stale long routes before issuing an authoritative local goal.
		self:stop()
		if distance>.45 then humanoid:MoveTo(destination) end
		rig:SetAttribute("NavigationStatus","Combat footwork")
		return true
	end

	local function compute(destination: Vector3, now: number)
		sequence += 1
		local token = sequence
		pending = token
		lastCompute = now
		blocked = false
		local start = root.Position
		task.spawn(function()
			local candidate = PathfindingService:CreatePath({
				AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4,
			})
			local ok = pcall(function() candidate:ComputeAsync(start, destination) end)
			if pending == token then pending = nil end
			if not active() or sequence ~= token or not goal then candidate:Destroy(); return end
			if not ok or candidate.Status ~= Enum.PathStatus.Success then
				candidate:Destroy()
				blocked = true
				rig:SetAttribute("NavigationStatus", "Retrying route")
				return
			end
			clearRoute()
			path = candidate
			waypoints = candidate:GetWaypoints()
			nextWaypoint = 1
			plannedGoal = destination
			blockedConnection = candidate.Blocked:Connect(function(index)
				if index >= nextWaypoint then blocked = true end
			end)
			rig:SetAttribute("NavigationStatus", "Following route")
		end)
	end

	function controller:step(now: number)
		if not active() or not goal then return end
		local destination = goal
		if flatDistance(root.Position, destination) <= 2 and math.abs(root.Position.Y-destination.Y) <= 6 then
			humanoid:MoveTo(root.Position)
			return
		end
		if flatDistance(root.Position, lastPosition) >= 1 then
			lastPosition = root.Position
			lastProgress = now
		elseif now - lastProgress > 2 then
			humanoid.Jump = true
			blocked = true
			lastProgress = now
		end
		local changed = plannedGoal == nil or flatDistance(destination, plannedGoal) > 6
		if pending == nil and now - lastCompute >= 1.5
			and (blocked or changed or nextWaypoint > #waypoints)
			and humanoid.FloorMaterial ~= Enum.Material.Air then
			compute(destination, now)
		end
		local waypoint = waypoints[nextWaypoint]
		while waypoint and flatDistance(root.Position, waypoint.Position) <= 2.5
			and math.abs(root.Position.Y - waypoint.Position.Y) <= 6 do
			nextWaypoint += 1
			waypoint = waypoints[nextWaypoint]
		end
		if waypoint then
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
			humanoid:MoveTo(waypoint.Position)
		end
	end
	return controller
end

return WarriorNavigator

--!strict

local PathfindingService = game:GetService("PathfindingService")
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
	function controller:setGoal(position: Vector3)
		if not active() then return end
		goal = position
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
		if flatDistance(root.Position, destination) <= 2 then
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

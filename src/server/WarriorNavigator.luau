--!strict

local PathfindingService = game:GetService("PathfindingService")
local Rules = require(script.Parent.CombatRules)
local Tuning = require(game.ReplicatedStorage.Shared.TacticalCombatConfig)
local WaterNavigation = require(script.Parent.WaterNavigation)
local Crowd = require(script.Parent.CrowdMovement)
local Camp = require(game.ReplicatedStorage.Shared.TrainingCampConfig)
local WarriorNavigator = {}

local function flatDistance(a: Vector3, b: Vector3): number
	local delta = a - b
	return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

function WarriorNavigator.new(rig: Model, isActive: () -> boolean, world)
	local humanoid = rig:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	local controller = {}
	local alive = true
	local goal: Vector3? = nil
	local allowsDetour = nil
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
	local crowd=if world then Crowd.forWorld(world.model) else nil
	if crowd then crowd:register(rig,isActive) end

	local function active(): boolean
		return alive and rig.Parent ~= nil and root.Parent ~= nil and humanoid.Health > 0 and isActive()
	end
	local function clearRoute()
		if blockedConnection then blockedConnection:Disconnect(); blockedConnection = nil end
		if path then path:Destroy(); path = nil end
		waypoints = {}
		nextWaypoint = 1
	end
	function controller:stop(preserveCrowd)
		if crowd and not preserveCrowd then crowd:halt(rig) end
		sequence += 1
		goal = nil
		allowsDetour = nil
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
		if crowd then crowd:forget(rig) end
	end
	function controller:setGoal(position: Vector3,policy)
		if not active() then return end
		goal = position
		allowsDetour = policy
	end

	-- Short encounter legs need tighter stopping than travelling waypoints.
	-- Ray/volume checks keep local steering on supported ground and out of walls.
	local function supported(position: Vector3,arenaOnly: boolean,campFrame)
		if not active() then return false end
		local arena=world.model.Battlefield
		local distance=flatDistance(root.Position,position)
		if distance>Tuning.closeDistance or (arenaOnly and not Rules.containsArena(arena,position)) then return false end
		if campFrame then
			local a,b=campFrame:PointToObjectSpace(root.Position),campFrame:PointToObjectSpace(position)
			if not Camp.contains(b,2) then return false end
			local delta=Vector3.new(b.X-a.X,0,b.Z-a.Z)
			local offset=Vector3.new(Camp.center.X-a.X,0,Camp.center.Z-a.Z)
			local t=if delta.Magnitude>.01 then math.clamp(offset:Dot(delta)/delta:Dot(delta),0,1) else 0
			if (offset-delta*t).Magnitude<5 then return false end
		end
		if not WaterNavigation.allowsDirect(world.model,root.Position,position) then return false end
		local terrain=RaycastParams.new()
		terrain.FilterType=Enum.RaycastFilterType.Include
		local surfaces={world.model.Ground,workspace.Terrain}
		local landscape=world.model:FindFirstChild("Landscape")
		if landscape and landscape:FindFirstChild("TerrainSurface") then table.insert(surfaces,landscape.TerrainSurface) end
		if landscape and landscape:FindFirstChild("Waterways") then table.insert(surfaces,landscape.Waterways) end
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
		return destination
	end
	local function move(position,finalGoal,now,arenaOnly,campFrame)
		local destination=position
		if crowd then destination=crowd:move(rig,position,finalGoal,now,function(p)
			local grounded=supported(p,arenaOnly,campFrame)
			return if grounded and (not allowsDetour or allowsDetour(grounded)) then grounded else nil
		end) end
		if not destination then
			humanoid:MoveTo(root.Position);humanoid.Jump=false
			lastProgress,lastPosition=now,root.Position
			rig:SetAttribute("NavigationStatus","Yielding to troops")
			return false
		end
		humanoid:MoveTo(destination)
		return true
	end
	-- Direct camp walks are refreshed at think frequency, including after yields.
	function controller:walkDirect(position: Vector3)
		if not active() then return end
		self:stop(true)
		local plot=world and world.model.Plots:FindFirstChild("Plot"..tostring(rig:GetAttribute("PlotId")))
		if move(position,position,os.clock(),false,if plot then plot.Foundation.CFrame else nil) then
			rig:SetAttribute("NavigationStatus","Walking inside training yard")
		end
	end
	function controller:walkCombat(position: Vector3,currentWorld,policy): boolean
		world=world or currentWorld
		local destination=supported(position,true,nil)
		if not destination then return false end
		self:stop(true)
		allowsDetour=policy
		if flatDistance(root.Position,destination)>.45 and move(destination,position,os.clock(),true,nil) then
			rig:SetAttribute("NavigationStatus","Combat footwork")
		end
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
				Costs = WaterNavigation.costs,
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
			if move(waypoint.Position,destination,now,false,nil) then
				rig:SetAttribute("NavigationStatus","Following route")
			end
		end
	end
	return controller
end

return WarriorNavigator

--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.RangedConfig)
local CombatRules = require(script.Parent.CombatRules)
local TroopProjectile = {}

function TroopProjectile.new(world, combat, isShooterActive: ((Model) -> boolean)?)
	local controller = {}
	local folder = Instance.new("Folder")
	folder.Name = "TroopProjectiles"
	folder.Parent = world.model
	local arena = world.model:FindFirstChild("Battlefield") :: BasePart
	local shots = {}
	local count = 0
	local alive = true

	local function remove(part: BasePart)
		if not shots[part] then return end
		shots[part] = nil
		count -= 1
		part:Destroy()
	end
	local function active(rig: Model): boolean
		return alive and world.model:IsDescendantOf(workspace) and combat:actor(rig) ~= nil
			and (isShooterActive == nil or isShooterActive(rig))
	end
	local function rayFilter(shooter: Model): RaycastParams
		local filter = RaycastParams.new()
		filter.FilterType = Enum.RaycastFilterType.Exclude
		filter.FilterDescendantsInstances = { shooter, folder }
		return filter
	end
	function controller:count(): number
		return count
	end
	function controller:fire(shooter: Model, target: Model, kind: string?): boolean
		if not active(shooter) or count >= Config.maxProjectiles then return false end
		local attacker, victim = combat:actor(shooter), combat:actor(target)
		if not attacker or not victim or attacker.kind ~= "ranged" or attacker.ownerId == victim.ownerId
			or not CombatRules.containsArena(arena, attacker.position)
			or not CombatRules.containsArena(arena, victim.position) then return false end
		local origin = attacker.position + Vector3.new(0, 1, 0)
		local offset = victim.position - attacker.position
		if not (offset.Magnitude > .01 and offset.Magnitude <= Config.range) then return false end
		local filter = rayFilter(shooter)
		local obstruction = workspace:Raycast(origin, offset, filter)
		if obstruction and not obstruction.Instance:IsDescendantOf(target) then return false end
		local part = Instance.new("Part")
		part.Name = kind or "arrow"
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Material = Enum.Material.Wood
		part.Color = Color3.fromRGB(214, 174, 85)
		part.Size = Vector3.new(.18, .18, if kind == "spear" then 3 else 1.8)
		if kind == "bullet" or kind == "stone" then
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(.4, .4, .4)
			part.Material = if kind == "bullet" then Enum.Material.Neon else Enum.Material.Slate
		elseif kind == "axe" then
			part.Size = Vector3.new(.7, .7, .2)
			part.Material = Enum.Material.Metal
		end
		part.CFrame = CFrame.lookAt(origin, origin + offset)
		part.Parent = folder
		shots[part] = { shooter = shooter, position = origin, direction = offset.Unit,
			remaining = Config.range, expires = os.clock() + Config.range / Config.speed + .5, filter = filter }
		count += 1
		return true
	end
	function controller:cancel(shooter: Model)
		for part, shot in shots do
			if shot.shooter == shooter then remove(part) end
		end
	end
	function controller:step(dt: number)
		if not alive or not (dt > 0 and dt < math.huge) then return end
		for part, shot in shots do
			if not part.Parent or not active(shot.shooter) or os.clock() >= shot.expires then remove(part); continue end
			local distance = math.min(Config.speed * dt, shot.remaining)
			local movement = shot.direction * distance
			local hit = workspace:Raycast(shot.position, movement, shot.filter)
			if hit then
				local candidate: Instance? = hit.Instance
				while candidate and candidate ~= workspace do
					if candidate:IsA("Model") then
						local victim = combat:actor(candidate)
						if victim then
							local attacker = combat:actor(shot.shooter)
							if attacker and attacker.ownerId ~= victim.ownerId
								and CombatRules.containsArena(arena, attacker.position)
								and CombatRules.containsArena(arena, victim.position) then
								combat:hit(shot.shooter, candidate)
							end
							break
						end
					end
					candidate = candidate.Parent
				end
				remove(part)
			else
				shot.position += movement
				shot.remaining -= distance
				part.CFrame = CFrame.lookAt(shot.position, shot.position + shot.direction)
				if shot.remaining <= 0 then remove(part) end
			end
		end
	end
	function controller:destroy()
		alive = false
		for part in shots do remove(part) end
		folder:Destroy()
	end
	return controller
end

return TroopProjectile

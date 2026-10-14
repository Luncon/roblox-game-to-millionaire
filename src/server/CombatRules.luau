--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.WarriorConfig)
local CombatRules = {}
local function finite(value): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

function CombatRules.containsArena(arena: BasePart, position: Vector3): boolean
	if typeof(position) ~= "Vector3" or not finite(position.X) or not finite(position.Y) or not finite(position.Z) then return false end
	local point = arena.CFrame:PointToObjectSpace(position)
	local y, z = point.Y / (arena.Size.Y/2), point.Z / (arena.Size.Z/2)
	-- A tiny tolerance covers float32 round trips at the inclusive boundary.
	return math.abs(point.X) <= Config.arenaHeightTolerance + .0001 and y*y + z*z <= 1.00001
end

function CombatRules.canDamage(attacker, target, arena: BasePart, reach: number?): boolean
	if type(attacker) ~= "table" or type(target) ~= "table" then return false end
	for _, actor in {attacker, target} do
		if not finite(actor.ownerId) or actor.ownerId % 1 ~= 0 or actor.alive ~= true or actor.claimed ~= true
			or not CombatRules.containsArena(arena, actor.position) then return false end
	end
	local range = reach or Config.attackRange
	if not finite(range) or range <= 0 then return false end
	return attacker.ownerId ~= target.ownerId
		and (attacker.position - target.position).Magnitude <= range + .0001
end

return CombatRules

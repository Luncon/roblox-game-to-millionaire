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

local function validActor(actor): boolean
	if type(actor) ~= "table" or actor.alive ~= true then return false end
	-- Neutral membership is supplied only by CombatService's private registration.
	if actor.neutral == true then return actor.ownerId == nil end
	return finite(actor.ownerId) and actor.ownerId % 1 == 0 and actor.claimed == true
end

function CombatRules.hostile(attacker, target): boolean
	if not validActor(attacker) or not validActor(target) then return false end
	if attacker.neutral == true or target.neutral == true then
		return (attacker.neutral == true) ~= (target.neutral == true)
	end
	return attacker.ownerId ~= target.ownerId
end

function CombatRules.canDamage(attacker, target, arena: BasePart, reach: number?): boolean
	if not CombatRules.hostile(attacker,target) then return false end
	if not CombatRules.containsArena(arena,attacker.position)
		or not CombatRules.containsArena(arena,target.position) then return false end
	local range = reach or Config.attackRange
	if not finite(range) or range <= 0 then return false end
	return (attacker.position - target.position).Magnitude <= range + .0001
end

return CombatRules

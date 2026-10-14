return function(moduleOverride)
	local module = moduleOverride or game.ServerScriptService.Game:FindFirstChild("CombatRules")
	assert(module, "CombatRules is not implemented yet")
	local Rules = require(module)
	local arena = Instance.new("Part")
	arena.Shape = Enum.PartType.Cylinder
	arena.Size = Vector3.new(2,150,150)
	arena.CFrame = CFrame.new(125,30,-83) * CFrame.Angles(0,.37,.61)
	local count = 0
	local function test(name, callback) callback(); count += 1; print("PASS: " .. name) end
	local function point(height, x, z) return arena.CFrame:PointToWorldSpace(Vector3.new(height,x,z)) end
	local function actor(owner, position)
		return {ownerId=owner,position=position or point(0,0,0),alive=true,claimed=true}
	end
	local ok, result = pcall(function()
		test("arena bounds follow current transformed cylinder axes", function()
			assert(Rules.containsArena(arena, point(0,0,0)))
			assert(not Rules.containsArena(arena, Vector3.zero))
			assert(Rules.containsArena(arena, point(0,45,45)))
			assert(not Rules.containsArena(arena, point(0,60,60)))
		end)
		test("radial and height boundaries are inclusive with no outside spill", function()
			assert(Rules.containsArena(arena, point(0,75,0)))
			assert(Rules.containsArena(arena, point(0,-75,0)))
			assert(not Rules.containsArena(arena, point(0,75.01,0)))
			assert(Rules.containsArena(arena, point(16,0,0)))
			assert(Rules.containsArena(arena, point(-16,0,0)))
			assert(not Rules.containsArena(arena, point(16.01,0,0)))
			assert(not Rules.containsArena(arena, point(-16.01,0,0)))
		end)
		test("living claimed enemies within five studs can be damaged", function()
			assert(Rules.canDamage(actor(1), actor(2,point(0,3,0)), arena))
			assert(Rules.canDamage(actor(-1), actor(-2,point(0,3,0)), arena), "Studio negative user IDs must work")
		end)
		test("friendly owner and unclaimed actors are protected", function()
			assert(not Rules.canDamage(actor(1), actor(1), arena))
			for _, field in {"claimed","alive"} do
				local attacker, target = actor(1), actor(2)
				attacker[field] = false
				assert(not Rules.canDamage(attacker,target,arena))
				attacker[field], target[field] = true, false
				assert(not Rules.canDamage(attacker,target,arena))
			end
		end)
		test("melee reach uses full three-dimensional distance", function()
			assert(Rules.canDamage(actor(1), actor(2,point(3,4,0)), arena))
			assert(not Rules.canDamage(actor(1), actor(2,point(3.01,4,0)), arena))
			assert(not Rules.canDamage(actor(1), actor(2,point(0,5.01,0)), arena))
		end)
		test("both combatants must remain inside arena", function()
			assert(Rules.canDamage(actor(1,point(0,74,0)),actor(2,point(0,75,0)),arena))
			assert(not Rules.canDamage(actor(1,point(0,74,0)),actor(2,point(0,75.01,0)),arena))
			assert(not Rules.canDamage(actor(1,point(0,75.01,0)),actor(2,point(0,74,0)),arena))
			assert(not Rules.canDamage(actor(1,point(16.01,0,0)),actor(2,point(15,0,0)),arena))
		end)
		test("nonfinite positions and owner IDs cannot authorize damage", function()
			for _, invalid in {math.huge,-math.huge,0/0} do
				local position = Vector3.new(invalid,0,0)
				assert(not Rules.containsArena(arena,position))
				assert(not Rules.canDamage(actor(1,position),actor(2),arena))
				assert(not Rules.canDamage(actor(1),actor(2,position),arena))
				assert(not Rules.canDamage(actor(invalid),actor(2),arena))
			end
			for _, invalid in {"1",1.5,false} do
				assert(not Rules.canDamage(actor(invalid),actor(2),arena))
			end
			assert(not Rules.canDamage(actor(nil),actor(2),arena))
		end)
		return count
	end)
	arena:Destroy()
	assert(ok,result)
	return result
end

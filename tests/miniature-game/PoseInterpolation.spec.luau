--!strict
local Shared = game:GetService("ReplicatedStorage").MiniatureGame
local Codec = require(Shared.PoseCodec)
local Interpolation = require(Shared.PoseInterpolation)
local jointNames = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }
local function near(actual: number, expected: number)
	assert(math.abs(actual - expected) < 0.0001, "Interpolated value differs")
end
local function pose(time: number, life: number, x: number, angle: number?)
	local joints = {}
	for _, name in jointNames do
		joints[name] = CFrame.new(0.25, 0.125, 0) * CFrame.Angles(angle or 0, 0, 0)
	end
	return {
		time = time,
		life = life,
		root = CFrame.new(x, 3, 0) * CFrame.Angles(0, angle or 0, 0),
		joints = joints,
		ground = 0.4,
	}
end
local function run(): number
	local count = 0
	local function check(name, callback)
		callback()
		count += 1
		print("PASS miniature pose interpolation: " .. name)
	end
	check("empty histories produce no invented actor pose", function()
		assert(Interpolation.sample(Interpolation.new(), 10) == nil, "Empty actor history produced geometry")
	end)
	check("root translation rotation and all six original joints interpolate together", function()
		local history = Interpolation.new()
		assert(Interpolation.push(history, pose(10, 1, 0, 0)), "First pose rejected")
		assert(Interpolation.push(history, pose(10.1, 1, 0.6, 1)), "Second pose rejected")
		local middle = Interpolation.sample(history, 10.05)
		assert(middle and middle.life == 1, "Interpolated actor life differs")
		near(middle.time, 10.05)
		near(middle.root.Position.X, 0.3)
		near(middle.root.LookVector.X, -math.sin(0.5))
		for _, name in jointNames do
			near(middle.joints[name].Position.X, 0.25)
			near(middle.joints[name].UpVector.Z, math.sin(0.5))
		end
		near(middle.ground, 0.4)
	end)
	check("sampling holds endpoints rather than predicting unchecked travel", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 0))
		Interpolation.push(history, pose(10.1, 1, 0.6))
		local earlier, later = Interpolation.sample(history, -100), Interpolation.sample(history, 100)
		assert(earlier and later, "Endpoint pose missing")
		near(earlier.time, 10)
		near(earlier.root.Position.X, 0)
		near(later.time, 10.1)
		near(later.root.Position.X, 0.6)
	end)
	check("duplicate and out of order packets cannot roll a pose backwards", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 0))
		Interpolation.push(history, pose(10.1, 1, 0.6))
		assert(not Interpolation.push(history, pose(10.1, 1, 90)), "Duplicate timestamp replaced a pose")
		assert(not Interpolation.push(history, pose(10.05, 1, 99)), "Out of order packet entered history")
		near(Interpolation.sample(history, 11).root.Position.X, 0.6)
	end)
	check("stationary packet stops motion at the authoritative endpoint", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 0))
		Interpolation.push(history, pose(10.1, 1, 0.6))
		Interpolation.push(history, pose(10.2, 1, 0.6))
		for _, time in { 10.15, 10.2, 11, 100 } do
			near(Interpolation.sample(history, time).root.Position.X, 0.6)
		end
	end)
	check("history cap bounds retention without changing the newest pose", function()
		local history = Interpolation.new(3)
		for index = 0, 9 do
			assert(Interpolation.push(history, pose(10 + index * 0.1, 1, index)), "Ordered capped packet rejected")
		end
		near(Interpolation.sample(history, 0).root.Position.X, 7)
		near(Interpolation.sample(history, 100).root.Position.X, 9)
	end)
	check("long network gaps reset history instead of dragging through stale travel", function()
		local history = Interpolation.new(8, 0.5)
		Interpolation.push(history, pose(10, 1, 0))
		Interpolation.push(history, pose(10.6, 1, 80))
		near(Interpolation.sample(history, 10.2).root.Position.X, 80)
	end)
	check("new lives cannot blend from the previous corpse and stale lives stay rejected", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 0))
		assert(Interpolation.push(history, pose(10.1, 2, 100)), "New actor life rejected")
		assert(not Interpolation.push(history, pose(10.2, 1, 3)), "Dead actor life reentered history")
		local current = Interpolation.sample(history, 10)
		assert(current and current.life == 2, "Old life survived respawn")
		near(current.root.Position.X, 100)
	end)
	check("clear removes travel and respects an explicit next life boundary", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 1))
		Interpolation.clear(history, 3)
		assert(Interpolation.sample(history, 10) == nil, "Cleared life retained a pose")
		assert(not Interpolation.push(history, pose(11, 2, 2)), "Clear accepted an earlier life")
		assert(Interpolation.push(history, pose(11, 3, 3)), "Expected current life rejected after clear")
		near(Interpolation.sample(history, 11).root.Position.X, 3)
	end)
	check("invalid clocks and nonfinite geometry never poison a valid history", function()
		local history = Interpolation.new()
		Interpolation.push(history, pose(10, 1, 1))
		assert(not Interpolation.push(history, pose(0 / 0, 1, 3)), "NaN timestamp entered history")
		assert(not Interpolation.push(history, pose(math.huge, 1, 3)), "Infinite timestamp entered history")
		assert(not Interpolation.push(history, pose(11, 1, math.huge)), "Infinite root entered history")
		near(Interpolation.sample(history, 11).root.Position.X, 1)
	end)
	check("compact codec preserves timestamp life root joints and ground atomically", function()
		local original = pose(123.125, 7, -18.5, 0.6)
		local encoded = Codec.encode(original)
		assert(type(encoded) == "string", "Pose codec did not produce one atomic attribute")
		local decoded = Codec.decode(encoded)
		assert(decoded and decoded.life == 7, "Pose codec lost actor life")
		near(decoded.time, original.time)
		near(decoded.ground, original.ground)
		near(decoded.root.Position.X, original.root.Position.X)
		near(decoded.root.LookVector.X, original.root.LookVector.X)
		for _, name in jointNames do
			near(decoded.joints[name].UpVector.Z, original.joints[name].UpVector.Z)
		end
	end)
	check("codec rejects missing truncated and unrelated attribute payloads", function()
		assert(
			Codec.decode(nil) == nil and Codec.decode({}) == nil and Codec.decode("garbage") == nil,
			"Invalid attribute decoded into a pose"
		)
		local encoded = Codec.encode(pose(10, 1, 1))
		assert(Codec.decode(encoded:sub(1, #encoded - 4)) == nil, "Truncated pose decoded partially")
	end)
	check("mounted speed codec roundtrip preserves all original pose fields", function()
		local original = pose(123.125, 7, -18.5, 0.6)
		original.speed = 9.75
		local encoded = Codec.encode(original)
		assert(#string.split(encoded, "|") == 13 and encoded:sub(1, 2) == "2|", "Mounted pose did not use version two")
		local decoded = Codec.decode(encoded)
		assert(decoded and decoded.speed, "Mounted speed lost in codec")
		near(decoded.speed, 9.75)
		near(decoded.time, original.time)
		near(decoded.root.Position.X, original.root.Position.X)
		near(decoded.joints["Right Hip"].UpVector.Z, original.joints["Right Hip"].UpVector.Z)
	end)
	check("mounted gait speed interpolates and holds at stopped endpoints", function()
		local history = Interpolation.new()
		local first, second = pose(10, 1, 0), pose(10.1, 1, 0.6)
		first.speed, second.speed = 0, 12
		assert(
			Interpolation.push(history, first) and Interpolation.push(history, second),
			"Valid mounted speed packet rejected"
		)
		near(Interpolation.sample(history, 10.05).speed, 6)
		local stopped = pose(10.2, 1, 0.6)
		stopped.speed = 0
		Interpolation.push(history, stopped)
		near(Interpolation.sample(history, 100).speed, 0)
	end)
	check("negative excessive and nonfinite mounted speeds never reach history or codec", function()
		local history = Interpolation.new()
		for _, speed in { -0.1, 32.1, math.huge, 0 / 0 } do
			local invalid = pose(10, 1, 1)
			invalid.speed = speed
			assert(not Interpolation.push(history, invalid), "Invalid mounted speed entered history")
		end
		local original = pose(10, 1, 1)
		original.speed = 1
		local fields = string.split(Codec.encode(original), "|")
		for _, speed in { "-0.1", "32.1", "nan", "inf" } do
			fields[6] = speed
			assert(Codec.decode(table.concat(fields, "|")) == nil, "Invalid mounted speed decoded from attribute")
		end
	end)
	check("foot troop version one byte format remains unchanged when speed is absent", function()
		local original = pose(10, 1, 1)
		local legacy = Codec.encode(original)
		assert(
			#string.split(legacy, "|") == 12 and legacy:sub(1, 2) == "1|",
			"Foot pose version or field count changed"
		)
		local decoded = Codec.decode(legacy)
		assert(decoded and decoded.speed == nil, "Version one invented mounted gait metadata")
		original.speed = 6
		assert(Codec.encode(original) ~= legacy, "Mounted speed did not produce its separate protocol version")
		original.speed = nil
		assert(Codec.encode(original) == legacy, "Removing speed changed legacy packet bytes")
	end)
	return count
end
return run

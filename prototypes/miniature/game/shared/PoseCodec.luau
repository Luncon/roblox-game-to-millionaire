--!strict
-- One ASCII attribute carries a complete versioned pose. The terminator rejects truncation.
local Interpolation = require(script.Parent.PoseInterpolation)
local Codec = {}
local function finite(value: number): boolean
	return value == value and math.abs(value) < 1e15
end
local function encodeFrame(frame: CFrame): string
	local x, y, z = frame:ToOrientation()
	return string.format("%.5f,%.5f,%.5f,%.5f,%.5f,%.5f", frame.X, frame.Y, frame.Z, x, y, z)
end
local function decodeFrame(value: string): CFrame?
	local fields = string.split(value, ",")
	if #fields ~= 6 then
		return nil
	end
	local numbers = {}
	for _, field in fields do
		local number = tonumber(field)
		if not number or not finite(number) or math.abs(number) > 1e6 then
			return nil
		end
		table.insert(numbers, number)
	end
	return CFrame.new(numbers[1], numbers[2], numbers[3]) * CFrame.fromOrientation(numbers[4], numbers[5], numbers[6])
end
function Codec.encode(snapshot: Interpolation.Snapshot): string
	assert(Interpolation.valid(snapshot), "Cannot encode an invalid original pose")
	local fields = {
		if snapshot.speed ~= nil then "2" else "1",
		string.format("%.6f", snapshot.time),
		tostring(snapshot.life),
		string.format("%.5f", snapshot.ground),
		encodeFrame(snapshot.root),
	}
	if snapshot.speed ~= nil then
		table.insert(fields, string.format("%.4f", snapshot.speed))
	end
	for _, name in Interpolation.jointNames do
		table.insert(fields, encodeFrame(snapshot.joints[name]))
	end
	table.insert(fields, "end")
	return table.concat(fields, "|")
end
function Codec.decode(payload: unknown): Interpolation.Snapshot?
	if type(payload) ~= "string" or #payload > 2048 then
		return nil
	end
	local fields = string.split(payload, "|")
	local mounted = fields[1] == "2"
	local length = if mounted then 13 else 12
	if #fields ~= length or (fields[1] ~= "1" and not mounted) or fields[length] ~= "end" then
		return nil
	end
	local time, life, ground = tonumber(fields[2]), tonumber(fields[3]), tonumber(fields[4])
	if not time or not life or not ground or not finite(time) or not finite(life) or not finite(ground) then
		return nil
	end
	local root = decodeFrame(fields[5])
	if not root then
		return nil
	end
	local joints = {}
	local offset = if mounted then 6 else 5
	for index, name in Interpolation.jointNames do
		local frame = decodeFrame(fields[offset + index])
		if not frame then
			return nil
		end
		joints[name] = frame
	end
	local speed = if mounted then tonumber(fields[6]) else nil
	if mounted and not speed then
		return nil
	end
	local snapshot: Interpolation.Snapshot =
		{ time = time, life = life, ground = ground, root = root, joints = joints, speed = speed }
	return if Interpolation.valid(snapshot) then snapshot else nil
end
return table.freeze(Codec)

--!strict
local Interpolation = {}
Interpolation.jointNames =
	table.freeze({ "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" })
export type Snapshot = {
	time: number,
	life: number,
	root: CFrame,
	joints: { [string]: CFrame },
	ground: number,
	-- Present only for mounted visuals; movement authority remains on the server.
	speed: number?,
}
export type History = { samples: { Snapshot }, life: number?, maxSamples: number, maxGap: number }
local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end
local function frameValid(frame: CFrame): boolean
	if typeof(frame) ~= "CFrame" then
		return false
	end
	for _, value in { frame:GetComponents() } do
		if not finite(value) then
			return false
		end
	end
	return true
end
function Interpolation.valid(snapshot: Snapshot): boolean
	if
		type(snapshot) ~= "table"
		or type(snapshot.time) ~= "number"
		or not finite(snapshot.time)
		or type(snapshot.life) ~= "number"
		or not finite(snapshot.life)
		or snapshot.life < 0
		or snapshot.life % 1 ~= 0
		or type(snapshot.ground) ~= "number"
		or not finite(snapshot.ground)
		or not frameValid(snapshot.root)
		or type(snapshot.joints) ~= "table"
		or snapshot.speed ~= nil
			and (type(snapshot.speed) ~= "number" or not finite(snapshot.speed) or snapshot.speed < 0 or snapshot.speed > 32)
	then
		return false
	end
	for _, name in Interpolation.jointNames do
		if not frameValid(snapshot.joints[name]) then
			return false
		end
	end
	return true
end
function Interpolation.new(maxSamples: number?, maxGap: number?): History
	return {
		samples = {},
		life = nil,
		maxSamples = math.clamp(math.floor(maxSamples or 8), 2, 32),
		maxGap = maxGap or 0.5,
	}
end
function Interpolation.clear(history: History, life: number?): ()
	table.clear(history.samples)
	history.life = life
end
function Interpolation.push(history: History, snapshot: Snapshot): (boolean, string?)
	if not Interpolation.valid(snapshot) then
		return false, "invalid_snapshot"
	end
	if history.life and snapshot.life < history.life then
		return false, "stale_life"
	end
	local last = history.samples[#history.samples]
	if history.life == snapshot.life and last and snapshot.time <= last.time then
		return false, "stale_time"
	end
	if history.life ~= snapshot.life or last and snapshot.time - last.time > history.maxGap then
		table.clear(history.samples)
	end
	history.life = snapshot.life
	local joints = {}
	for _, name in Interpolation.jointNames do
		joints[name] = snapshot.joints[name]
	end
	local copy: Snapshot = {
		time = snapshot.time,
		life = snapshot.life,
		root = snapshot.root,
		joints = table.freeze(joints),
		ground = snapshot.ground,
		speed = snapshot.speed,
	}
	table.insert(history.samples, table.freeze(copy))
	while #history.samples > history.maxSamples do
		table.remove(history.samples, 1)
	end
	return true, nil
end
function Interpolation.sample(history: History, targetTime: number): Snapshot?
	if not finite(targetTime) then
		return nil
	end
	local samples = history.samples
	local first, last = samples[1], samples[#samples]
	if not first or not last then
		return nil
	end
	if targetTime <= first.time then
		return first
	end
	if targetTime >= last.time then
		return last
	end
	for index = 2, #samples do
		local right, left = samples[index], samples[index - 1]
		if targetTime <= right.time then
			local alpha = math.clamp((targetTime - left.time) / (right.time - left.time), 0, 1)
			local joints = {}
			for _, name in Interpolation.jointNames do
				joints[name] = left.joints[name]:Lerp(right.joints[name], alpha)
			end
			return {
				time = targetTime,
				life = right.life,
				root = left.root:Lerp(right.root, alpha),
				joints = joints,
				ground = left.ground + (right.ground - left.ground) * alpha,
				speed = if left.speed ~= nil and right.speed ~= nil
					then left.speed + (right.speed - left.speed) * alpha
					else right.speed,
			}
		end
	end
	return last
end
return table.freeze(Interpolation)

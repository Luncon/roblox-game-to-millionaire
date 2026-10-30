--!strict
-- Deserialise data only. Imported Script.Source is never compiled or executed.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local expected = {
	bear = 7,
	bull = 18,
	camel = 28,
	crocodile = 203,
	elephant = 37,
	elk = 29,
	horse = 26,
	lion = 41,
	rhino = 20,
	tiger = 85,
	wolf = 29,
}
local templates, parts = 0, 0
for name, partCount in expected do
	local models = roblox.deserializeModel(fs.readFile("assets/mount-templates/" .. name .. ".rbxm"))
	assert(#models == 1 and models[1]:IsA("Model") and models[1].Name == name, "Mount template identity differs")
	local model, count = models[1], 0
	assert(model:GetAttribute("UserSuppliedMount") == true, "Unreviewed mount template")
	for _, item in model:GetDescendants() do
		assert(
			not item:IsA("LuaSourceContainer")
				and not item:IsA("RemoteEvent")
				and not item:IsA("RemoteFunction")
				and not item:IsA("Seat")
				and not item:IsA("VehicleSeat")
				and not item:IsA("BodyMover")
				and not item:IsA("Humanoid")
				and not item:IsA("AnimationController")
				and not item:IsA("Animator")
				and not item:IsA("Animation")
				and not item:IsA("KeyframeSequence")
				and not item:IsA("ValueBase"),
			"Imported gameplay/controller/editor objects reached a runtime mount template"
		)
		if item:IsA("BasePart") then
			assert(
				item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
				"Active animal physics"
			)
			count += 1
		elseif item:IsA("JointInstance") or item:IsA("WeldConstraint") then
			assert(not item.Enabled, "Imported animal joint remained active")
		end
	end
	assert(count == partCount and model:GetAttribute("ImportedPartCount") == count, "Imported animal geometry changed")
	templates += 1
	parts += count
end
local raw = roblox.deserializeModel(fs.readFile("assets/mount-source-backups/user-imports-2026-10-29.rbxm"))
local rawParts, rawScripts = 0, 0
for _, model in raw do
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			rawParts += 1
		elseif item:IsA("LuaSourceContainer") then
			rawScripts += 1
		end
	end
end
assert(#raw == 11 and rawParts == 527 and rawScripts == 32, "Raw imported models or script audit backup lost data")
print(`Mount assets passed: {templates} inert templates, {parts} preserved parts; raw11-model/32-script backup intact`)

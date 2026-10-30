--!strict
-- Executes the actual fingerprint module against isolated source-bank doubles.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local part = { ClassName = "Part", Size = "1, 2, 3", CFrame = "0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1" }
function part:IsA(class: string): boolean
	return class == "BasePart"
end
function part:GetFullName(): string
	return "ServerStorage.MountTemplates.bull.Part"
end
local model = { ClassName = "Model", scale = 1 }
function model:IsA(class: string): boolean
	return class == "Model"
end
function model:GetFullName(): string
	return "ServerStorage.MountTemplates.bull"
end
function model:GetScale(): number
	return self.scale
end
local bank = { Name = "MountTemplates", items = { model, part } }
function bank:GetDescendants()
	return self.items
end
local otherPart = table.clone(part)
function otherPart:GetFullName(): string
	return "ServerStorage.NPCTemplates.original.Part"
end
local other = { Name = "NPCTemplates" }
function other:GetDescendants()
	return { otherPart }
end
local storage = {}
function storage:GetChildren()
	return { bank, other }
end
local fingerprint = luau.load(fs.readFile("tests/miniature/Templates.luau"), {
	environment = { game = { ServerStorage = storage } },
	injectGlobals = true,
})()
local baseline = fingerprint()
part.CFrame = "-0, -0, -0, 1, -0, -0, -0, 1, -0, -0, -0, 1"
assert(fingerprint() == baseline, "Signed zero must not invalidate unchanged source geometry")
part.CFrame = "0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0"
local finalZero = fingerprint()
part.CFrame = "-0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -0"
assert(fingerprint() == finalZero, "First and last CFrame fields were not canonicalized")
part.CFrame = "0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1"
for _, token in { "-0.1", "-0.000000001", "-1e-12", "0.1" } do
	part.CFrame = token .. ", 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1"
	assert(fingerprint() ~= baseline, "Nonzero coordinate was hidden: " .. token)
end
part.CFrame = "0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1"
part.Size = "1, 2, 4"
assert(fingerprint() ~= baseline, "Actual source size change was hidden")
part.Size = "0, 2, 3"
local unsignedSize = fingerprint()
part.Size = "-0, 2, 3"
assert(fingerprint() ~= unsignedSize, "Canonicalization leaked into Size text")
part.Size = "1, 2, 3"
model.scale = 0.25
assert(fingerprint() ~= baseline, "Actual model scale change was hidden")
model.scale = 1
otherPart.CFrame = "1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1"
assert(fingerprint() ~= baseline, "Another original source bank was excluded")
otherPart.CFrame = part.CFrame
bank.items = { part, model }
assert(fingerprint() == baseline, "Fingerprint became dependent on descendant enumeration order")
print("PASS source fingerprint: signed zeros, nonzero/tiny coordinates, size, scale, all banks, stable ordering")

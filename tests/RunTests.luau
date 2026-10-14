-- Run with Studio's --task RunScript against the generated test place.
local tests = game:GetService("ServerStorage"):FindFirstChild("Tests")
assert(tests, "Build .cache/test.project.json before running the tests")

local failures = {}
local total = 0
for _, spec in tests:GetChildren() do
	if spec:IsA("ModuleScript") then
		local ok, count = pcall(function()
			return require(spec)()
		end)
		if ok then
			total += count
		else
			table.insert(failures, spec.Name .. ": " .. tostring(count))
		end
	end
end

if #failures > 0 then
	warn("TEST_RESULT: FAIL\n" .. table.concat(failures, "\n"))
	error("Studio tests failed")
end
print("TEST_RESULT: PASS (" .. total .. " cases)")

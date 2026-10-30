--!strict
-- Read-only native verification of the eight integrated fake-sandbox outposts.
local Scenery = require(game:GetService("ServerScriptService").Sandbox.OutpostScenery)

local function run()
	local RunService = game:GetService("RunService")
	local Replicated = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	assert(RunService:IsStudio(), "Outpost scenery verification is Studio-only")
	local deadline = os.clock() + 15
	repeat
		if Replicated:GetAttribute("MiniatureSandboxReady") then
			break
		end
		task.wait(0.1)
	until os.clock() > deadline
	assert(
		Replicated:GetAttribute("MiniatureSandboxReady")
			and Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore",
		"Wait for the isolated fake sandbox"
	)
	local evidence = {
		sites = 0,
		totalParts = 0,
		partBudget = 139,
		scale = Scenery.scale,
		corridorHalfWidth = Scenery.corridorHalfWidth,
		captureRadius = Scenery.captureRadius,
		geometryInert = true,
		sitesChecked = {},
	}
	local ok, message = pcall(function()
		local scene = Workspace:FindFirstChild("MiniatureSandbox")
		local sites = scene and scene:FindFirstChild("Outposts")
		assert(sites, "Integrated outpost folder missing")
		local indices = {}
		for _, site in sites:GetChildren() do
			if not site:IsA("Model") then
				continue
			end
			local model = site:FindFirstChild("OutpostScenery")
			assert(model and model:IsA("Model"), "Developed outpost scenery missing")
			local index = model:GetAttribute("SceneryIndex")
			assert(type(index) == "number" and not indices[index], "Duplicate or missing scenery index")
			indices[index] = true
			assert(math.abs(model:GetScale() - 0.25) < 0.0001, "Outpost art is not quarter-scale")
			assert(
				model:GetAttribute("VisualOnly") and model:GetAttribute("OutpostScenery"),
				"Scenery metadata missing"
			)
			local frame = model:GetPivot()
			local parts = 0
			for _, part in model:GetDescendants() do
				assert(
					not part:IsA("LuaSourceContainer")
						and not part:IsA("Humanoid")
						and not part:IsA("Tool")
						and not part:IsA("ProximityPrompt")
						and not part:IsA("ClickDetector"),
					"Scenery contains executable or functional gameplay objects"
				)
				if not part:IsA("BasePart") then
					continue
				end
				parts += 1
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Scenery changes collision touch or query behavior"
				)
				local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
				for _, x in { -1, 1 } do
					for _, y in { -1, 1 } do
						for _, z in { -1, 1 } do
							local point = frame:PointToObjectSpace(
								part.CFrame:PointToWorldSpace(
									Vector3.new(x * part.Size.X, y * part.Size.Y, z * part.Size.Z) / 2
								)
							)
							assert(point.Y >= -0.002, "Native scenery extends below reference ground")
							assert(
								math.sqrt(point.X ^ 2 + point.Z ^ 2) <= 22.002,
								"Native scenery exceeds capture radius"
							)
							minX, maxX, minZ, maxZ =
								math.min(minX, point.X),
								math.max(maxX, point.X),
								math.min(minZ, point.Z),
								math.max(maxZ, point.Z)
						end
					end
				end
				local xGap = if minX <= 0 and maxX >= 0 then 0 else math.min(math.abs(minX), math.abs(maxX))
				local zGap = if minZ <= 0 and maxZ >= 0 then 0 else math.min(math.abs(minZ), math.abs(maxZ))
				assert(xGap >= 4.998 and zGap >= 4.998, "Native scenery blocks a five-stud approach corridor")
			end
			assert(
				parts == #Scenery.plan(index) and parts >= 90 and parts < 140,
				"Native scenery part budget or descriptor count differs"
			)
			evidence.sites += 1
			evidence.totalParts += parts
			table.insert(evidence.sitesChecked, { id = site.Name, index = index, parts = parts })
		end
		assert(evidence.sites == 8, "Expected all eight developed outposts")
	end)
	evidence.ok = ok
	evidence.message = if not ok then tostring(message) else nil
	Replicated:SetAttribute("MiniatureOutpostSceneryResult", game:GetService("HttpService"):JSONEncode(evidence))
	assert(ok, tostring(message))
	return evidence
end

return run

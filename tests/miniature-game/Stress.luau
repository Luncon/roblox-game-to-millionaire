--!strict
-- Native geometry/pose load only. Never uses live profiles or player claims.
return function()
	local Replicated = game:GetService("ReplicatedStorage")
	assert(game:GetService("RunService"):IsStudio(), "Studio stress fixture only")
	assert(Replicated:GetAttribute("MiniatureSandboxStorage") == "InjectedFakeProfileStore", "Wrong storage boundary")
	local Sandbox = game.ServerScriptService.Sandbox
	local State, World = require(Sandbox.State), require(Sandbox.World)
	local Workers, Catalog = require(Sandbox.Workers), require(Replicated.MiniatureGame.Catalog)
	local fingerprint = require(game.ServerStorage.TemplateFingerprint)
	local before = fingerprint()
	local gallery = Instance.new("Model")
	gallery.Name = "MiniatureBoundedStress"
	local plots = {}
	local ok, result = pcall(function()
		local civilizations = {}
		for id in World.availableKits() do
			table.insert(civilizations, id)
		end
		table.sort(civilizations)
		local totalParts, totalWorkers, totalRoster = 0, 0, 0
		gallery.Parent = workspace
		for index = 1, 8 do
			local id = civilizations[(index - 1) % #civilizations + 1]
			local state = State.new(id, os.time())
			state.hallUpgraded = true
			for researchId in Catalog.research do
				state.research.completed[researchId] = true
			end
			state.goods.timber, state.goods.material = 100, 100
			state.buildings = {}
			for number, site in
				{
					{ "civic", -6, -10, 90 },
					{ "house", -6, 6, 0 },
					{ "farm", 6, -10, 0 },
					{ "house", -14, 6, 0 },
					{ "timber", -6, 12, 0 },
					{ "material", -14, 12, 0 },
					{ "workshop", 6, 6, 0 },
					{ "storehouse", 14, 6, 0 },
					{ "training", -14, -10, 90 },
					{ "healer", 6, 12, 0 },
					{ "ranged", 14, -10, 90 },
					{ "timber", 14, 12, 0 },
				}
			do
				table.insert(
					state.buildings,
					{ id = "b" .. number, kind = site[1], x = site[2], z = site[3], rotation = site[4], output = 0 }
				)
			end
			state.nextBuildingId, state.nextWorkerId = 13, 9
			state.workers = {}
			for number = 1, 8 do
				table.insert(
					state.workers,
					{ id = "w" .. number, buildingId = ({ "b3", "b5", "b6", "b7" })[math.ceil(number / 2)] }
				)
			end
			assert(State.validate(state, id), "Stress state violates limits: " .. id)
			local troops = State.troops(state)
			assert(
				troops.melee == 2 and troops.ranged == 2 and troops.medic == 1,
				"Stress army is not derived from buildings"
			)
			local model = Instance.new("Model")
			model.Name, model.Parent = "StressPlot" .. index, gallery
			local buildings, actors = Instance.new("Folder"), Instance.new("Folder")
			buildings.Name, buildings.Parent, actors.Name, actors.Parent = "Buildings", model, "Actors", model
			local plot = {
				model = model,
				buildings = buildings,
				actors = actors,
				frame = CFrame.new((index - 1) % 4 * 48, 0, -300 - math.floor((index - 1) / 4) * 40),
			}
			table.insert(plots, plot)
			World.render(plot, state, -1000 - index)
			assert(#buildings:GetChildren() == 12, "Stress building count")
			local workerCount, rosterCount = 0, 0
			for _, actor in actors:GetChildren() do
				if actor:GetAttribute("PresentationRole") == "worker" then
					workerCount += 1
				else
					rosterCount += 1
				end
			end
			assert(workerCount == 8 and rosterCount == 5, "Stress automatic actor capacity")
			assert(rosterCount <= 10, "Stress army exceeded total troop cap")
			totalWorkers += workerCount
			totalRoster += rosterCount
			for _, object in model:GetDescendants() do
				assert(not object:IsA("LuaSourceContainer") and not object:IsA("Tool"), "Executable stress art")
				if object:IsA("BasePart") then
					totalParts += 1
				end
			end
			task.wait()
		end
		local times, poseUpdates = {}, 0
		local start, lastPose = os.clock(), 0
		while os.clock() - start < 3 do
			local dt = game:GetService("RunService").Heartbeat:Wait()
			table.insert(times, dt)
			local now = os.clock()
			if now - lastPose >= 0.05 then
				for _, plot in plots do
					Workers.animate(plot, now)
				end
				lastPose = now
				poseUpdates += 1
			end
		end
		table.sort(times)
		return {
			settlements = 8,
			buildings = 96,
			workers = totalWorkers,
			presentations = totalRoster,
			parts = totalParts,
			kitVarieties = math.min(8, #civilizations),
			seconds = os.clock() - start,
			poseUpdates = poseUpdates,
			heartbeatMedian = times[math.ceil(#times / 2)],
			heartbeatP95 = times[math.ceil(#times * 0.95)],
			heartbeatMax = times[#times],
			geometryOnly = true,
			repeatedCivilizationsAllowedOnlyInThisGeometryFixture = true,
		}
	end)
	for _, plot in plots do
		World.clear(plot)
	end
	gallery:Destroy()
	assert(fingerprint() == before, "Stress fixture mutated source templates")
	Replicated:SetAttribute(
		"MiniatureStressResult",
		game:GetService("HttpService"):JSONEncode({ ok = ok, result = result })
	)
	assert(ok, tostring(result))
	return result
end

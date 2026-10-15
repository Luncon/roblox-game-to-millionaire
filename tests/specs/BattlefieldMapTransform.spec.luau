return function()
	local BattlefieldMap = require(game.ServerScriptService.Game.BattlefieldMap)
	local catalog = require(game.ReplicatedStorage.Shared.Civilizations)
	local container = Instance.new("Folder")
	container.Name = "MovedSettlementTest"
	container.Parent = workspace
	local count = 0
	local function test(name, callback)
		callback()
		count += 1
		print("PASS: " .. name)
	end
	local function sameFrame(actual, expected)
		return (actual.Position - expected.Position).Magnitude < .01
			and actual.LookVector:Dot(expected.LookVector) > .9999
			and actual.UpVector:Dot(expected.UpVector) > .9999
	end
	local function corners(part, reference)
		local result = {}
		for _, x in {-1,1} do
			for _, y in {-1,1} do
				for _, z in {-1,1} do
					local localCorner = Vector3.new(x*part.Size.X/2, y*part.Size.Y/2, z*part.Size.Z/2)
					table.insert(result, reference:PointToObjectSpace(part.CFrame:PointToWorldSpace(localCorner)))
				end
			end
		end
		return result
	end
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(container)
		world.model:PivotTo(CFrame.new(1000,30,-800) * CFrame.Angles(0,math.rad(23),0) * world.model:GetPivot())
		local movedFrames, controlFrames = {}, {}
		for plotId = 1, 8 do
			local plot = world.model.Plots["Plot" .. plotId]
			movedFrames[plotId] = plot.Foundation.CFrame
			controlFrames[plotId] = {}
			for _, pad in plot.Controls:GetChildren() do
				if pad:IsA("BasePart") and (pad.Name=="CoinButton" or pad.Name=="UpgradeButton") then controlFrames[plotId][pad.Name] = pad.CFrame end
			end
		end
		test("spawn follows current foundation after moving and rotating all eight plots", function()
			for plotId = 1, 8 do
				assert(sameFrame(world:getSpawn(plotId), movedFrames[plotId] * CFrame.new(0,7,17)),
					"Spawn used the old world frame for plot " .. plotId)
			end
		end)
		test("every civilization's final settlement fits and centers on each moved foundation", function()
			for _, civ in catalog do
				for plotId = 1, 8 do
					world:setOwner(plotId, civ, 101, "MovedCommander", 50)
					local plot = world.model.Plots["Plot" .. plotId]
					assert(plot.Foundation.Size.X == 256 and plot.Foundation.Size.Z == 256)
					assert(sameFrame(plot.Foundation.CFrame, movedFrames[plotId]))
					local minimum, maximum = Vector3.new(math.huge,0,math.huge), Vector3.new(-math.huge,0,-math.huge)
					local walls = 0
					for _, part in plot.Settlement:GetDescendants() do
						if part:IsA("BasePart") then
							local perimeter = part.Parent.Name=="Perimeter" and (
								part.Name=="WestWall" or part.Name=="EastWall" or part.Name=="CourtWallLeft"
								or part.Name=="CourtWallRight" or part.Name=="ArenaWallLeft" or part.Name=="ArenaWallRight")
							if perimeter then walls += 1 end
							for _, point in corners(part, plot.Foundation.CFrame) do
								assert(math.abs(point.X) <= 128.05 and math.abs(point.Z) <= 128.05,
									civ.id .. " plot " .. plotId .. " has off-plot geometry: " .. part.Name)
								if perimeter then
									minimum = Vector3.new(math.min(minimum.X,point.X),0,math.min(minimum.Z,point.Z))
									maximum = Vector3.new(math.max(maximum.X,point.X),0,math.max(maximum.Z,point.Z))
								end
							end
						end
					end
					assert(walls == 6, "Final settlement is missing one of its six boundary wall sections")
					assert(((minimum + maximum) / 2).Magnitude < .05,
						"Final perimeter is off-center: " .. civ.id .. " plot " .. plotId)
				end
			end
		end)
		test("all upgrades preserve moved ground pads and their input instances", function()
			for plotId = 1, 8 do
				local plot = world.model.Plots["Plot" .. plotId]
				local detectors = {}
				for name in controlFrames[plotId] do detectors[name] = plot.Controls[name]:FindFirstChildOfClass("ClickDetector") end
				for level = 1, 50 do
					world:setOwner(plotId, catalog[1], 101, "MovedCommander", level)
					for name, frame in controlFrames[plotId] do
						local pad = plot.Controls[name]
						assert(sameFrame(pad.CFrame, frame), "Settlement rebuild moved " .. name)
						assert(pad:FindFirstChildOfClass("ClickDetector") == detectors[name])
					end
				end
			end
		end)
		test("release resets sizes without moving foundation pads or spawn", function()
			for plotId = 1, 8 do
				local plot = world.model.Plots["Plot" .. plotId]
				world:setOwner(plotId, nil, nil, nil)
				assert(plot.Foundation.Size.X == 60 and plot.Foundation.Size.Z == 60)
				assert(sameFrame(plot.Foundation.CFrame, movedFrames[plotId]))
				assert(sameFrame(world:getSpawn(plotId), movedFrames[plotId] * CFrame.new(0,7,17)))
				assert(#plot.Settlement:GetChildren() == 0)
				for name, frame in controlFrames[plotId] do assert(sameFrame(plot.Controls[name].CFrame, frame)) end
			end
		end)
		return count
	end)
	container:Destroy()
	assert(ok, result)
	return result
end

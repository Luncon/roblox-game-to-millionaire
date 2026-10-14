local testing = game:GetService("StudioTestService")
local args = testing:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "civilization-claims" then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("CivilizationRemotes", 15)

local control = Instance.new("Folder")
control.Name = "PrototypeTestControl"
local commands = Instance.new("RemoteEvent")
commands.Name = "Command"
commands.Parent = control
local reports = Instance.new("RemoteEvent")
reports.Name = "Report"
reports.Parent = control
local responses = {}
reports.OnServerEvent:Connect(function(player, round, response)
	responses[round] = responses[round] or {}
	responses[round][player.UserId] = response
end)
control.Parent = ReplicatedStorage

local function waitFor(predicate, description, timeout)
	local deadline = os.clock() + (timeout or 15)
	repeat
		if predicate() then return end
		task.wait(.1)
	until os.clock() > deadline
	error("Timed out: " .. description)
end

local function round(name, action, civilization, target, expected)
	task.wait(.4)
	commands:FireAllClients({ round = name, action = action, civilization = civilization, target = target })
	waitFor(function()
		local count = 0
		for _ in responses[name] or {} do count += 1 end
		return count == expected
	end, name)
	for _, response in responses[name] do
		assert(response.executed, tostring(response.result))
	end
	return responses[name]
end

local ok, result = pcall(function()
	waitFor(function()
		local count = 0
		for _ in responses.ready or {} do count += 1 end
		return count == 2 and #Players:GetPlayers() == 2
	end, "two ready clients", 45)
	local race = round("race", "select", "sparta", nil, 2)
	local winner = nil
	local losers = {}
	for userId, response in race do
		if response.result.ok then
			assert(winner == nil, "Duplicate civilization owners")
			winner = userId
		else
			assert(response.result.reason == "unavailable")
			table.insert(losers, userId)
		end
	end
	assert(winner and #losers == 1, "Expected one winner and one rejected request")
	local british = round("britain", "select", "britain", losers[1], 1)[losers[1]].result
	assert(british.ok)
	local spartan = Players:GetPlayerByUserId(winner)
	assert(spartan:GetAttribute("PlotId") ~= british.claim.plotId)
	local rapid = round("rapid", "rapid", "sparta", winner, 1)[winner].result
	assert(rapid.first.ok and not rapid.second.ok and rapid.second.reason == "rate_limited")
	local plotId = spartan:GetAttribute("PlotId")
	spartan:LoadCharacterAsync()
	waitFor(function()
		local character = spartan.Character
		local plot = workspace.CivilizationPrototype.Plots["Plot" .. plotId]
		return character and character:FindFirstChild("HumanoidRootPart")
			and (character:GetPivot().Position - plot.Foundation.Position).Magnitude < 40
	end, "claimed player respawn")
	assert(spartan:GetAttribute("CivilizationId") == "sparta")
	commands:FireAllClients({ round = "leave", action = "leave", target = winner })
	waitFor(function() return Players:GetPlayerByUserId(winner) == nil end, "owner departure")
	local plot = workspace.CivilizationPrototype.Plots["Plot" .. plotId]
	waitFor(function() return plot:GetAttribute("OwnerId") == nil end, "plot release")
	testing:AddPlayers(1)
	local newcomer = nil
	waitFor(function()
		for _, player in Players:GetPlayers() do
			if player.UserId ~= losers[1] and responses.ready and responses.ready[player.UserId] then
				newcomer = player.UserId
				return true
			end
		end
		return false
	end, "new client joins after release", 45)
	local replacement = round("reclaim", "select", "sparta", newcomer, 1)[newcomer].result
	assert(replacement.ok and replacement.claim.plotId == plotId)
	return { ok = true, cases = 6, message = "Conflict, distinct plots, throttle, respawn, departure, and reclaim passed" }
end)

local readyCount = 0
for _ in responses.ready or {} do readyCount += 1 end
testing:EndTest(if ok then result else {
	ok = false, message = tostring(result), players = #Players:GetPlayers(), ready = readyCount,
})

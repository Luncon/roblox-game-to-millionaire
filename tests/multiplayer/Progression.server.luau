-- Isolated runtime suites driven by three actual Studio clients.
local testing = game:GetService("StudioTestService")
local args = testing:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "army-progression" then return end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local started = os.clock()
local completed = false
local evidence = {}
local totalCases = 0
local allPassed = true
local phase = "Waiting for three clients"

local function finish(ok, message)
	if completed then return end
	completed = true
	local result = {
		ok = ok, cases = totalCases, suites = evidence, message = message,
		players = #Players:GetPlayers(), phase = phase, durationSeconds = os.clock() - started,
	}
	game:SetAttribute("ProgressionTestEvidence", HttpService:JSONEncode(result))
	print("PROGRESSION_TEST_RESULT: " .. HttpService:JSONEncode(result))
	testing:EndTest(result)
end
local function setPhase(value)
	phase = value
	game:SetAttribute("ProgressionTestPhase", phase)
	print("PROGRESSION_TEST_PHASE: " .. phase)
end
local function waitFor(predicate, description, timeout)
	local deadline = os.clock() + timeout
	repeat
		if completed then error("Progression test already ended") end
		if predicate() then return end
		task.wait(.1)
	until os.clock() > deadline
	error("Timed out: " .. description)
end
local function ready(player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return player.Parent == Players and character and character:FindFirstChild("HumanoidRootPart")
		and character:FindFirstChild("Head") and humanoid and humanoid.Health > 0
end

-- Startup allowances are harness limits, not engine or gameplay timing changes.
task.delay(360, function() finish(false, "Watchdog expired during " .. phase) end)
local ok, failure = pcall(function()
	setPhase("Waiting for three live clients")
	local startupTimeout = if type(args.startupTimeout) == "number" then math.clamp(args.startupTimeout, 30, 180) else 120
	waitFor(function()
		local players = Players:GetPlayers()
		if #players < 3 then return false end
		for _, player in players do if not ready(player) then return false end end
		return true
	end, "three connected players with living characters", startupTimeout)
	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.UserId < b.UserId end)
	local first, second, third = players[1], players[2], players[3]
	local runtime = game.ServerStorage:WaitForChild("RuntimeTests", 15)
	assert(runtime, "Map tests/runtime into ServerStorage.RuntimeTests")
	local function run(name, arguments, optional)
		setPhase(name)
		local module = runtime:FindFirstChild(name)
		if not module then
			evidence[name] = {ok = false, skipped = optional == true, message = "Runtime module is missing"}
			if not optional then allPassed = false end
			return
		end
		local suiteStarted = os.clock()
		local passed, result = pcall(function()
			for _, player in arguments do
				waitFor(function() return ready(player) end, "current character before " .. name, 30)
			end
			return require(module)(table.unpack(arguments))
		end)
		local valid = passed and type(result) == "table" and result.ok == true and type(result.cases) == "number"
		local message = if not passed then tostring(result)
			elseif type(result) == "table" then tostring(result.message or "Invalid suite result")
			else "Invalid suite result: " .. tostring(result)
		evidence[name] = if valid then result else {ok = false, message = message}
		evidence[name].durationSeconds = os.clock() - suiteStarted
		if valid then totalCases += result.cases else allPassed = false end
		game:SetAttribute("ProgressionTestEvidence", HttpService:JSONEncode(evidence))
		print(string.format("PROGRESSION_SUITE: %s · %s", name, if valid then "PASS" else "FAIL"))
	end
	run("CombatRewards", {first, second, third}, false)
	run("PlayerMelee", {first, second}, false)
	run("ProjectileCombat", {first, second}, false)
	run("BarracksSlots", {first, second}, false)
	run("CustomMeleeMovement", {}, false)
	setPhase("Complete")
end)
finish(ok and allPassed, if not ok then tostring(failure) elseif allPassed then "Focused progression runtime suites passed" else "One or more progression runtime suites failed")

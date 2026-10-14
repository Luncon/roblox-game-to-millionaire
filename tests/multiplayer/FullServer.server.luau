local testing = game:GetService("StudioTestService")
local args = testing:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "civilization-full-server" then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local control = Instance.new("Folder")
control.Name = "PrototypeTestControl"
local commands = Instance.new("RemoteEvent")
commands.Name, commands.Parent = "Command", control
local reports = Instance.new("RemoteEvent")
reports.Name, reports.Parent = "Report", control
local responses = {}
reports.OnServerEvent:Connect(function(player, name, response)
	responses[name] = responses[name] or {}
	responses[name][player.UserId] = response
end)
control.Parent = ReplicatedStorage

local function waitFor(predicate, description, timeout)
	local deadline = os.clock() + (timeout or 30)
	repeat
		if predicate() then return end
		task.wait(.1)
	until os.clock() > deadline
	error("Timed out: " .. description)
end
local function round(name, action, target, civilization, options, expected, timeout)
	task.wait(.4)
	commands:FireAllClients({round=name,action=action,target=target,civilization=civilization,options=options})
	waitFor(function()
		local count = 0
		for _ in responses[name] or {} do count += 1 end
		return count == expected
	end, name, timeout)
	for _, response in responses[name] do assert(response.executed, tostring(response.result)) end
	return responses[name]
end

local finished = false
task.delay(540, function()
	if not finished then testing:EndTest({ok=false,message="Eight-player test exceeded its watchdog"}) end
end)
local connections = {}
local ok, result = pcall(function()
	if args.staged then
		for _, wanted in {2,3,4,5,6,7,8} do
			waitFor(function()
				if #Players:GetPlayers() ~= wanted then return false end
				for _, player in Players:GetPlayers() do
					if not responses.ready or not responses.ready[player.UserId] or not player.Character
						or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
				end
				return true
			end, "staged startup: " .. wanted .. " real clients", 180)
			print("Eight-player startup: " .. wanted .. "/8 clients ready")
			if wanted < 8 then testing:AddPlayers(1) end
		end
	end
	waitFor(function()
		if #Players:GetPlayers() ~= 8 then return false end
		for _, player in Players:GetPlayers() do
			if not responses.ready or not responses.ready[player.UserId] or not player.Character
				or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
		end
		return true
	end, "eight real clients with characters and ready test controls", 180)
	local players = Players:GetPlayers()
	table.sort(players, function(a,b) return a.Name < b.Name end)
	local catalog = require(ReplicatedStorage.Shared.Civilizations)
	local byId, selected, occupied = {}, {}, {}
	for _, civ in catalog do byId[civ.id] = civ end
	for index, player in players do
		local id = player:GetAttribute("CivilizationId") or (args.civilizations and args.civilizations[index])
		if id and byId[id] and not occupied[id] then selected[player.UserId] = byId[id]; occupied[id] = true end
	end
	for _, player in players do
		if not selected[player.UserId] then
			for _, civ in catalog do
				if not occupied[civ.id] then selected[player.UserId] = civ; occupied[civ.id] = true; break end
			end
		end
	end
	local rules = require(game.ServerScriptService.Game.CombatRules)
	local world = workspace:WaitForChild("CivilizationPrototype", 15)
	local records = {}
	local cases = 0
	local function passed(name)
		cases += 1
		print("PASS: " .. name)
	end
	local function recordUnit(rig)
		local ownerId = rig:GetAttribute("OwnerId")
		local record = records[ownerId]
		if not record then return end
		record.units[rig] = true
		record.spawnCount += 1
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local previous = humanoid.Health
		table.insert(connections, humanoid.HealthChanged:Connect(function(health)
			if health < previous then record.hits += 1 end
			previous = health
		end))
		table.insert(connections, humanoid.Died:Connect(function()
			record.deaths += 1
			record.deathAt = workspace:GetServerTimeNow()
			record.deadRig = rig
		end))
	end
	table.insert(connections, world.Troops.ChildAdded:Connect(recordUnit))
	for index, player in players do
		local civ = selected[player.UserId]
		records[player.UserId] = {civilization=civ.id,units={},spawnCount=0,hits=0,deaths=0,arrived=false}
		local reply = round("full-claim-" .. index,"select",player.UserId,civ.id,nil,1)[player.UserId].result
		assert(reply.ok and reply.claim.civilizationId == civ.id)
		assert(player:GetAttribute("CivilizationId") == civ.id)
	end
	passed("all eight real clients select different civilizations")
	local plots = {}
	for _, player in players do
		local plotId = player:GetAttribute("PlotId")
		assert(not plots[plotId], "Duplicate plot ownership")
		plots[plotId] = true
		local plot = world.Plots["Plot" .. plotId]
		assert(plot:GetAttribute("OwnerId") == player.UserId)
		assert(plot:GetAttribute("CivilizationId") == player:GetAttribute("CivilizationId"))
	end
	assert(#world.Plots:GetChildren() == 8)
	passed("all eight plots have distinct matching owners and civilization themes")
	local hud = round("full-hud","inspectHUD",nil,nil,nil,8)
	for _, response in hud do assert(response.result.visible and response.result.coins == "0 coins" and not response.result.hasButtons) end
	passed("all eight clients display their claimed settlement HUD")
	local sampleFailure
	local sampling = true
	task.spawn(function()
		while sampling do
			local counts = {}
			for _, rig in world.Troops:GetChildren() do
				local ownerId = rig:GetAttribute("OwnerId")
				local record = records[ownerId]
				local humanoid = rig:FindFirstChildOfClass("Humanoid")
				local root = rig:FindFirstChild("HumanoidRootPart")
				if record and humanoid and root and humanoid.Health > 0 then
					counts[ownerId] = (counts[ownerId] or 0) + 1
					if counts[ownerId] > 1 then sampleFailure = "More than one living troop for an owner" end
					if root:GetNetworkOwner() ~= nil then sampleFailure = "NPC physics transferred to a client" end
					if rules.containsArena(world.Battlefield, root.Position) then record.arrived = true end
					if record.deadRig and rig ~= record.deadRig and record.deathAt then
						if workspace:GetServerTimeNow() < record.deathAt + 14.9 then sampleFailure = "Early reinforcement under eight-player load" end
						record.replaced = true
					end
				end
			end
			task.wait(.2)
		end
	end)
	local physicalCases, clicks = 0, 0
	for index, player in players do
		local civ = selected[player.UserId]
		local input = round("full-pads-" .. index,"physicalInput",player.UserId,nil,{barracksOnly=true},1,60)[player.UserId].result
		assert(input.ok and input.clicks == 55 and input.level == 2 and input.weaponLevel == 2 and input.armorLevel == 2)
		physicalCases += input.cases
		clicks += input.clicks
		local living
		waitFor(function()
			for _, rig in world.Troops:GetChildren() do
				if rig:GetAttribute("OwnerId") == player.UserId and rig.Humanoid.Health > 0 then living = rig; return true end
			end
			return false
		end, "living warrior for civilization " .. civ.id, 20)
		assert(living:GetAttribute("CivilizationId") == civ.id)
		assert(living:GetAttribute("WarriorDamage") == 14 and living.Humanoid.MaxHealth == 115)
		assert(living:GetAttribute("WeaponLevel") == 2 and living:GetAttribute("ArmorLevel") == 2)
		assert(player:GetAttribute("BarracksLevel") == 1)
		passed("native ground input deploys and upgrades " .. civ.name .. " warrior")
	end
	waitFor(function()
		for _, record in records do if not record.arrived then return false end end
		return true
	end, "every civilization's warrior physically reaches the arena", 90)
	passed("warriors from all eight settlements navigate into the shared arena")
	waitFor(function()
		for _, record in records do if record.replaced then return true end end
		return false
	end, "a real combat death and automatic fifteen-second replacement", 45)
	local hitOwners, deaths = 0, 0
	for _, record in records do
		if record.hits > 0 then hitOwners += 1 end
		deaths += record.deaths
	end
	assert(hitOwners >= 2 and deaths > 0)
	passed("eight-player arena produces melee damage, deaths, and automatic replacements")
	assert(not sampleFailure, sampleFailure)
	passed("one living unit per owner and server-owned physics hold under eight-player load")
	for _, player in players do
		assert(player.Character.Humanoid.Health == 115, "A player was damaged on its protected settlement plot")
		assert(player:GetAttribute("Coins") == 0)
	end
	passed("all eight protected owners retain full upgraded health and isolated balances")
	sampling = false
	local selected = {}
	for _, player in players do table.insert(selected,{player=player.Name,civilization=player:GetAttribute("CivilizationId"),plot=player:GetAttribute("PlotId")}) end
	return {ok=true,cases=cases+physicalCases,players=8,clicks=clicks,selected=selected,
		message="Eight real clients claimed distinct civilizations, used native ground inputs, deployed inherited gear, and fought with bounded automatic armies"}
end)
for _, connection in connections do connection:Disconnect() end
finished = true
testing:EndTest(if ok then result else {ok=false,message=tostring(result),players=#Players:GetPlayers()})

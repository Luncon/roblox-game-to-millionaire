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

local function round(name, action, civilization, target, expected, timeout)
	task.wait(.4)
	commands:FireAllClients({ round = name, action = action, civilization = civilization, target = target })
	waitFor(function()
		local count = 0
		for _ in responses[name] or {} do count += 1 end
		return count == expected
	end, name, timeout)
	for _, response in responses[name] do
		assert(response.executed, tostring(response.result))
	end
	return responses[name]
end

local function assertEquipped(player, civilization, weaponLevel, armorLevel)
	weaponLevel, armorLevel = weaponLevel or 1, armorLevel or 1
	local weapon = nil
	waitFor(function()
		local character = player.Character
		if not character or not character:FindFirstChild("CivilizationArmor") then return false end
		for _, item in character:GetChildren() do
			if item:IsA("Tool") and item:GetAttribute("GeneratedBy") == "CivilizationEquipment" then
				weapon = item
				return true
			end
		end
		return false
	end, "equipped civilization gear after claim or respawn")
	local armor = player.Character.CivilizationArmor
	assert(weapon:GetAttribute("CivilizationId") == civilization and weapon:GetAttribute("WeaponLevel") == weaponLevel)
	assert(weapon:GetAttribute("Damage") == ({10,14,19,25})[weaponLevel] and not weapon.CanBeDropped)
	assert(armor:GetAttribute("CivilizationId") == civilization and armor:GetAttribute("ArmorLevel") == armorLevel)
	assert(player.Character:FindFirstChildOfClass("Humanoid").MaxHealth == ({100,115,135,170})[armorLevel])
end

local function ownedWarriors(ownerId)
	local result = {}
	for _, rig in workspace.CivilizationPrototype.Troops:GetChildren() do
		if rig:GetAttribute("OwnerId") == ownerId then table.insert(result,rig) end
	end
	return result
end

local ok, result = pcall(function()
	waitFor(function()
		local count = 0
		for _ in responses.ready or {} do count += 1 end
		return count == 2 and #Players:GetPlayers() == 2
	end, "two ready clients", 45)
	local runtimeTests = game.ServerStorage:WaitForChild("RuntimeTests", 15)
	assert(runtimeTests, "Map tests/runtime into the test place before multiplayer checks")
	local controllerCases = require(runtimeTests.TycoonController)(Players:GetPlayers()[1])
	local economyRemotes = ReplicatedStorage:WaitForChild("EconomyRemotes", 15)
	assert(economyRemotes and economyRemotes:FindFirstChild("State"))
	assert(economyRemotes:FindFirstChild("Action") == nil, "Currency must not expose a client action remote")
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
	for _, player in Players:GetPlayers() do
		assert(player:GetAttribute("Coins") == 0 and player:GetAttribute("SettlementLevel") == 1)
		assert(player:GetAttribute("WeaponLevel") == 1 and player:GetAttribute("ArmorLevel") == 1)
		assert(player:FindFirstChild("leaderstats") and player.leaderstats.Coins.Value == 0)
		assertEquipped(player, player:GetAttribute("CivilizationId"))
	end
	local hudReports = round("hud", "inspectHUD", nil, nil, 2)
	for _, response in hudReports do
		local hud = response.result
		assert(hud.visible and not hud.hasButtons, "HUD must display progress while physical pads perform actions")
		assert(hud.hasSwitch,"HUD needs a civilization switch control")
		assert(hud.coins == "0 coins" and string.find(hud.progression, "Weapon", 1, true))
		assert(string.find(hud.progression, "Armor", 1, true))
	end
	local physical = round("physical", "physicalInput", nil, winner, 1, 90)[winner].result
	assert(physical.ok and physical.clicks == 130 and physical.cases == 6)
	assert(physical.coins == 0 and physical.level == 3 and physical.weaponLevel == 2 and physical.armorLevel == 2)
	assert(spartan:GetAttribute("Coins") == 0 and spartan:GetAttribute("SettlementLevel") == 3)
	assert(spartan:GetAttribute("WeaponLevel") == 2 and spartan:GetAttribute("ArmorLevel") == 2)
	assertEquipped(spartan, "sparta", 2, 2)
	waitFor(function()
		local rigs = ownedWarriors(winner)
		return #rigs==1 and rigs[1]:GetAttribute("WarriorDamage")==14 and rigs[1].Humanoid.MaxHealth==115
	end,"production warrior inherits physical equipment purchases")
	local ownedWarrior = ownedWarriors(winner)[1]
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
	assert(spartan:GetAttribute("Coins") == 0 and spartan:GetAttribute("SettlementLevel") == 3)
	assert(spartan:GetAttribute("WeaponLevel") == 2 and spartan:GetAttribute("ArmorLevel") == 2)
	assertEquipped(spartan, "sparta", 2, 2)
	assert(#ownedWarriors(winner)==1 and ownedWarriors(winner)[1]==ownedWarrior,
		"Character reset changed or duplicated the living army unit")
	commands:FireAllClients({ round = "leave", action = "leave", target = winner })
	waitFor(function() return Players:GetPlayerByUserId(winner) == nil end, "owner departure")
	waitFor(function() return #ownedWarriors(winner)==0 end,"departing owner's warrior cleanup")
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
	local replacementPlayer = Players:GetPlayerByUserId(newcomer)
	assert(replacementPlayer:GetAttribute("Coins") == 0 and replacementPlayer:GetAttribute("SettlementLevel") == 1)
	assert(replacementPlayer:GetAttribute("WeaponLevel") == 1 and replacementPlayer:GetAttribute("ArmorLevel") == 1)
	assert(#ownedWarriors(newcomer)==0,"Fresh outpost unexpectedly inherited the old owner's army")
	local targetPlayer=Players:GetPlayerByUserId(losers[1])
	local attackerCharacter,targetCharacter=replacementPlayer.Character,targetPlayer.Character
	local attackerRoot,targetRoot=attackerCharacter.HumanoidRootPart,targetCharacter.HumanoidRootPart
	local originalAnchored,originalTargetAnchored=attackerRoot.Anchored,targetRoot.Anchored
	attackerRoot.Anchored=true; targetRoot.Anchored=true
	local arena=workspace.CivilizationPrototype.Battlefield
	local origin=arena.Position+Vector3.new(50,4,0)
	attackerCharacter:PivotTo(CFrame.lookAt(origin,origin+Vector3.new(3,0,0)))
	targetCharacter:PivotTo(CFrame.new(origin+Vector3.new(3,0,0)))
	local originalTool=attackerCharacter:FindFirstChildOfClass("Tool")
	assert(originalTool,"Native melee requires the genuine civilization weapon")
	local delayedTool=originalTool:Clone()
	delayedTool:SetAttribute("GeneratedBy",nil)
	attackerCharacter.Humanoid:UnequipTools()
	delayedTool.Parent=replacementPlayer.Backpack
	attackerCharacter.Humanoid:EquipTool(delayedTool)
	local attackIntents=0
	local attackSpy=ReplicatedStorage.CombatRemotes.Attack.OnServerEvent:Connect(function(player)
		if player==replacementPlayer then attackIntents+=1 end
	end)
	local unmarked=round("native-unmarked","meleeInput",nil,newcomer,1,15)[newcomer].result
	assert(unmarked.activated==true or (type(unmarked.activated)=="number" and unmarked.activated>0))
	assert(attackIntents==0 and replacementPlayer:GetAttribute("Coins")==0,
		"An unmarked tool activation crossed the client combat boundary")
	delayedTool:SetAttribute("GeneratedBy","CivilizationEquipment")
	local originalMaximum=targetCharacter.Humanoid.MaxHealth
	-- Keep the lethal fixture at ten even if the normal regeneration script ticks.
	targetCharacter.Humanoid.MaxHealth=10
	targetCharacter.Humanoid.Health=10
	local marked=round("native-marked","meleeInput",nil,newcomer,1,15)[newcomer].result
	waitFor(function() return targetCharacter.Humanoid.Health<=0 and replacementPlayer:GetAttribute("Coins")==10 end,
		"native melee final hit and ten-coin reward")
	assert(attackIntents==1,"One native weapon activation should send one attack intent")
	assert(marked.coins==10 and string.find(marked.feedback,"+10",1,true),"Client HUD did not show the real kill reward")
	assert(type(marked.army)=="string" and #marked.army>0,"Barracks status is missing from the client HUD")
	attackSpy:Disconnect()
	delayedTool:Destroy()
	attackerCharacter.Humanoid:EquipTool(originalTool)
	attackerRoot.Anchored=originalAnchored
	targetRoot.Anchored=originalTargetAnchored
	targetCharacter.Humanoid.MaxHealth=originalMaximum
	return { ok = true, cases = 19 + controllerCases + physical.cases,
		message = "Claims/respawn/reclaim, isolated accounts, server controller, actual coin clicks, ground purchases, entry latch, and gear input passed" }
end)

local readyCount = 0
for _ in responses.ready or {} do readyCount += 1 end
testing:EndTest(if ok then result else {
	ok = false, message = tostring(result), players = #Players:GetPlayers(), ready = readyCount,
})

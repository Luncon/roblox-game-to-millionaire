-- Server-only controller checks. Pass a real connected player with a living character.
-- These checks exercise authorization and transactions, not physical input events.
return function(player, controllerModule)
	local Players = game:GetService("Players")
	assert(player and player.Parent == Players, "Controller checks require a live test player")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(root and humanoid and humanoid.Health > 0, "Wait for a living character first")
	local originalPivot, originalAnchored = character:GetPivot(), root.Anchored
	local originalHumanoidParent, originalRootParent = humanoid.Parent, root.Parent
	local originalCivilization = player:GetAttribute("CivilizationId")
	local originalState = {
		weaponLevel = player:GetAttribute("WeaponLevel") or 1,
		armorLevel = player:GetAttribute("ArmorLevel") or 1,
	}
	local container = Instance.new("Folder")
	container.Name = "TycoonControllerTestFixture"
	container.Parent = workspace
	local count = 0
	local resetControllerTraffic = nil
	local function test(name, callback)
		callback()
		count += 1
		print("PASS: " .. name)
		if resetControllerTraffic then resetControllerTraffic() end
	end
	local ok, result = pcall(function()
		local BattlefieldMap = require(game.ServerScriptService.Game.BattlefieldMap)
		local ClaimRegistry = require(game.ServerScriptService.Game.ClaimRegistry)
		local Economy = require(game.ServerScriptService.Game.Economy)
		local TycoonButtons = require(controllerModule or game.ServerScriptService.Game.TycoonButtons)
		local civilizations = require(game.ReplicatedStorage.Shared.Civilizations)
		local catalog, supported = {}, {}
		for _, civ in civilizations do catalog[civ.id] = civ; supported[civ.id] = true end
		local world = BattlefieldMap.build(container)
		-- Avoid sharing physical contacts with the running game's real plot pads.
		world.model:PivotTo(world.model:GetPivot() + Vector3.new(1000, 0, 1000))
		local registry = ClaimRegistry.new(8, supported)
		local time = 0
		local economy = Economy.new(function() return time end)
		local lastPublished = nil
		local controller = TycoonButtons.new(world, registry, economy, catalog, function(_, response)
			lastPublished = response
		end)
		resetControllerTraffic = function()
			controller:release(player.UserId)
			local claim = registry:get(player.UserId)
			if claim then controller:refresh(player, claim) end
		end
		local coin = world.model.Plots.Plot1.Controls.CoinButton
		local upgrade = world.model.Plots.Plot1.Controls.UpgradeButton
		local weapon,armor=nil,nil
		root.Anchored = true
		local function moveNear(pad)
			character:PivotTo(pad.CFrame * CFrame.new(0, 4, 0))
		end
		local function activate(action, plotId)
			return controller:activate(player, plotId or 1, action)
		end
		test("unclaimed player cannot earn or buy from ground pads", function()
			moveNear(coin)
			assert(not activate("earn").ok)
			moveNear(upgrade)
			assert(not activate("upgrade").ok)
			assert(not activate("weapon").ok)
			assert(not activate("armor").ok)
			assert(economy:get(player.UserId) == nil)
		end)
		local claim = registry:claim(player.UserId, "sparta").claim
		assert(claim and claim.plotId == 1)
		economy:open(player.UserId)
		world:setOwner(1, catalog.sparta, player.UserId, player.DisplayName, 1)
		controller:refresh(player, claim)
		test("owner click awards the configured fifty coins and publishes authoritative state", function()
			moveNear(coin)
			assert(activate("earn").ok)
			assert(economy:get(player.UserId).coins == 50)
			assert(lastPublished ~= nil, "Accepted action never published feedback")
		end)
		-- Purchase/denial checks intentionally begin below the first price, independently of pad payout.
		local lowFunds=economy:get(player.UserId);lowFunds.coins=1;assert(economy:replace(player.UserId,lowFunds))
		controller:refresh(player,claim)
		test("hidden future-tier actions are rejected by the server before settlement unlock", function()
			moveNear(coin)
			for _, action in {"weapon","armor","weapon3","armor3","weapon4","armor4","barracks2","barracks3","barracks4"} do
				assert(not activate(action).ok, "Hidden action bypassed settlement gate: " .. action)
			end
			assert(economy:get(player.UserId).coins == 1 and economy:get(player.UserId).barracksLevel == 1)
		end)
		test("foreign plot cannot award coins or charge upgrades", function()
			local foreignClaim = registry:claim(-989898, "britain").claim
			world:setOwner(foreignClaim.plotId, catalog.britain, -989898, "OtherCommander", 1)
			local foreign = world.model.Plots["Plot" .. foreignClaim.plotId].Controls
			moveNear(foreign.CoinButton)
			assert(not activate("earn", foreignClaim.plotId).ok)
			moveNear(foreign.UpgradeButton)
			assert(not activate("upgrade", foreignClaim.plotId).ok)
			assert(not activate("weapon", foreignClaim.plotId).ok)
			assert(not activate("armor", foreignClaim.plotId).ok)
			assert(economy:get(player.UserId).coins == 1 and economy:get(player.UserId).level == 1)
		end)
		test("distant owner cannot trigger either physical pad", function()
			character:PivotTo(CFrame.new(0, 100, 0))
			assert(not activate("earn").ok and not activate("upgrade").ok)
			assert(not activate("weapon").ok and not activate("armor").ok)
			assert(economy:get(player.UserId).coins == 1)
		end)
		test("missing humanoid or root denies coin awards", function()
			moveNear(coin)
			humanoid.Parent = nil
			assert(not activate("earn").ok)
			humanoid.Parent = originalHumanoidParent
			root.Parent = nil
			assert(not activate("earn").ok)
			root.Parent = originalRootParent
			assert(economy:get(player.UserId).coins == 1)
		end)
		test("unknown action or nonexistent plot cannot change progress", function()
			moveNear(coin)
			assert(not activate("setBalance").ok)
			assert(not activate("earn", 999).ok)
			assert(economy:get(player.UserId).coins == 1)
		end)
		test("ground upgrade rejects insufficient funds without changing settlement", function()
			moveNear(upgrade)
			assert(activate("upgrade").reason == "insufficient_funds")
			assert(economy:get(player.UserId).coins == 1 and economy:get(player.UserId).level == 1)
			assert(world.model.Plots.Plot1:GetAttribute("SettlementLevel") == 1)
		end)
		test("funded ground purchase charges exactly 25 and expands settlement", function()
			time += 1
			for _ = 1, 24 do
				assert(economy:earn(player.UserId).ok)
				time += .1
			end
			moveNear(upgrade)
			assert(activate("upgrade").ok)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).level == 2)
			assert(world.model.Plots.Plot1:GetAttribute("SettlementLevel") == 2)
			assert(world.model.Plots.Plot1.Foundation.Size.X == 64)
			assert(world.model.Plots.Plot1.Controls.UpgradeButton == upgrade)
			weapon=world.model.Plots.Plot1.Controls.WeaponButton
			armor=world.model.Plots.Plot1.Controls.ArmorButton
		end)
		test("duplicate ground purchase is bounded and cannot double charge", function()
			assert(not activate("upgrade").ok)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).level == 2)
		end)
		test("higher gear tiers remain hidden until their matching settlement stage", function()
			local controls = world.model.Plots.Plot1.Controls
			for _, pair in {{"weapon3","Weapon3Button"},{"armor3","Armor3Button"}} do
				local pad = controls:FindFirstChild(pair[2])
				assert(pad==nil)
				assert(not activate(pair[1]).ok)
			end
			assert(economy:get(player.UserId).weaponLevel == 1 and economy:get(player.UserId).armorLevel == 1)
		end)
		test("ground gear pads reject insufficient funds", function()
			time += 1
			moveNear(weapon)
			assert(activate("weapon").reason == "insufficient_funds")
			time += 1
			moveNear(armor)
			assert(activate("armor").reason == "insufficient_funds")
			assert(economy:get(player.UserId).coins == 0)
			assert(economy:get(player.UserId).weaponLevel == 1 and economy:get(player.UserId).armorLevel == 1)
		end)
		test("separate weapon and armor pads charge their own first upgrades", function()
			time += 1
			for _ = 1, 30 do
				assert(economy:earn(player.UserId).ok)
				time += .1
			end
			moveNear(weapon)
			assert(activate("weapon").ok)
			assert(economy:get(player.UserId).coins == 15 and economy:get(player.UserId).weaponLevel == 2)
			assert(economy:get(player.UserId).armorLevel == 1 and economy:get(player.UserId).level == 2)
			time += 1
			moveNear(armor)
			assert(activate("armor").ok)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).armorLevel == 2)
			assert(economy:get(player.UserId).weaponLevel == 2 and economy:get(player.UserId).level == 2)
			assert(math.abs(humanoid.MaxHealth-(100+40/49))<.002, "Armor purchase did not change actual character health")
			local ownedTools = {}
			for _, item in character:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("GeneratedBy") == "CivilizationEquipment" then
					table.insert(ownedTools, item)
				end
			end
			assert(#ownedTools == 1, "Actual character must equip exactly one owned weapon")
			assert(ownedTools[1]:GetAttribute("WeaponLevel") == 2 and math.abs(ownedTools[1]:GetAttribute("Damage")-(10+8/49))<.002)
			assert(ownedTools[1]:GetAttribute("CivilizationId") == "sparta")
			assert(character.CivilizationArmor:GetAttribute("ArmorLevel") == 2)
		end)
		test("retired tier-two gear actions cannot buy again", function()
			local controls = world.model.Plots.Plot1.Controls
			assert(controls:FindFirstChild("WeaponButton") == nil and controls:FindFirstChild("ArmorButton") == nil)
			assert(not activate("weapon").ok and not activate("armor").ok)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).weaponLevel == 2)
		end)
		test("barracks purchase retires its actual pad and preserves separate progression", function()
			for _ = 1, 30 do assert(economy:earn(player.UserId).ok); time += .1 end
			local pad = world.model.Plots.Plot1.Controls.Barracks2Button
			moveNear(pad)
			assert(activate("barracks2").ok and economy:get(player.UserId).barracksLevel == 2)
			assert(pad.Parent == nil and world.model.Plots.Plot1.Controls:FindFirstChild("Barracks2Button") == nil)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).level == 2)
			assert(economy:get(player.UserId).weaponLevel == 2 and economy:get(player.UserId).armorLevel == 2)
		end)
		test("later settlement expansion binds new pads without resetting purchased barracks", function()
			for _ = 1, 35 do assert(economy:earn(player.UserId).ok); time += .1 end
			moveNear(upgrade)
			assert(activate("upgrade").ok)
			local controls = world.model.Plots.Plot1.Controls
			assert(controls:FindFirstChild("Weapon3Button") and controls:FindFirstChild("Armor3Button") and controls:FindFirstChild("Barracks3Button"))
			assert(controls:FindFirstChild("Weapon4Button")==nil and controls:FindFirstChild("Armor4Button")==nil)
			assert(economy:get(player.UserId).barracksLevel == 2 and economy:get(player.UserId).level == 3)
			for _ = 1, 18 do assert(economy:earn(player.UserId).ok); time += .1 end
			moveNear(controls.Weapon3Button)
			assert(activate("weapon3").ok and economy:get(player.UserId).weaponLevel == 3)
			assert(controls:FindFirstChild("Weapon3Button") == nil and controls:FindFirstChild("Weapon4Button")==nil)
		end)
		test("visible high-tier pads independently reject skipped prerequisites",function()
			economy:close(player.UserId); economy:open(player.UserId)
			for level,cost in {25,35,45} do
				for _=1,cost do assert(economy:earn(player.UserId).ok); time+=.1 end
				assert(economy:upgrade(player.UserId,level).ok); time+=1
			end
			world:setOwner(1,catalog.sparta,player.UserId,player.DisplayName,4)
			controller:refresh(player,claim)
			for _,pair in {{"weapon3","Weapon3Button"},{"armor3","Armor3Button"},{"weapon4","Weapon4Button"},{"armor4","Armor4Button"},{"barracks3","Barracks3Button"},{"barracks4","Barracks4Button"}} do
				local pad=world.model.Plots.Plot1.Controls[pair[2]]
				assert(pad and not pad:FindFirstChildOfClass("ProximityPrompt").Enabled)
				moveNear(pad)
				assert(activate(pair[1]).reason=="prerequisite")
			end
			assert(economy:get(player.UserId).coins==0 and economy:get(player.UserId).weaponLevel==1 and economy:get(player.UserId).barracksLevel==1)
		end)
		test("release and reclaim begin at zero coins and first settlement tier", function()
			controller:release(player.UserId)
			registry:release(player.UserId)
			economy:close(player.UserId)
			world:setOwner(1, nil, nil, nil)
			assert(not activate("earn").ok)
			local replacement = registry:claim(player.UserId, "sparta").claim
			economy:open(player.UserId)
			world:setOwner(1, catalog.sparta, player.UserId, player.DisplayName, 1)
			controller:refresh(player, replacement)
			assert(economy:get(player.UserId).coins == 0 and economy:get(player.UserId).level == 1)
			assert(economy:get(player.UserId).weaponLevel == 1 and economy:get(player.UserId).armorLevel == 1)
			assert(world.model.Plots.Plot1:GetAttribute("SettlementLevel") == 1)
		end)
		return count
	end)
	humanoid.Parent = originalHumanoidParent
	root.Parent = originalRootParent
	root.Anchored = originalAnchored
	character:PivotTo(originalPivot)
	container:Destroy()
	local Equipment = require(game.ServerScriptService.Game.Equipment)
	if originalCivilization then
		for _, civ in require(game.ReplicatedStorage.Shared.Civilizations) do
			if civ.id == originalCivilization then Equipment.apply(player, civ, originalState); break end
		end
	else
		Equipment.clear(player)
	end
	assert(ok, result)
	return result
end

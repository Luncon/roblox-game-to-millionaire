-- Server-only integration helper; waits for the real production fifteen-second timers.
return function(player)
	local Players = game:GetService("Players")
	assert(player and player.Parent == Players, "Warrior lifecycle requires a connected test player")
	local Game = game.ServerScriptService.Game
	local WarriorService = require(Game.WarriorService)
	local BattlefieldMap = require(Game.BattlefieldMap)
	local ClaimRegistry = require(Game.ClaimRegistry)
	local Economy = require(Game.Economy)
	local Tracks = require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local civilizations = require(game.ReplicatedStorage.Shared.Civilizations)
	local catalog, supported = {}, {}
	for _, civ in civilizations do catalog[civ.id] = civ; supported[civ.id] = true end
	local originalAttributes = {}
	for _, name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do
		originalAttributes[name] = player:GetAttribute(name)
	end
	local container = Instance.new("Folder")
	container.Name = "WarriorLifecycleTestFixture"
	container.Parent = workspace
	local service = nil
	local cases = 0
	local function now() return workspace:GetServerTimeNow() end
	local function waitFor(predicate, description, timeout)
		local deadline = now() + (timeout or 3)
		repeat
			if predicate() then return end
			task.wait(.05)
		until now() > deadline
		error("Timed out: " .. description)
	end
	local function test(name, callback)
		callback()
		cases += 1
		print("PASS: " .. name)
	end
	local ok, result = pcall(function()
		local world = BattlefieldMap.build(container)
		world.model:PivotTo(CFrame.new(1400,0,1400)*world.model:GetPivot())
		local registry = ClaimRegistry.new(8,supported)
		local clock = 0
		local economy = Economy.new(function() return clock end)
		local function fund(amount)
			for _ = 1, amount do
				assert(economy:earn(player.UserId).ok)
				clock += .1
			end
		end
		local function upgrade(kind)
			local state = economy:get(player.UserId)
			local field = if kind == "weapon" then "weaponLevel" elseif kind == "armor" then "armorLevel" else "level"
			local level = state[field]
			fund(Tracks[kind][level].nextCost)
			assert(economy:upgrade(player.UserId,level,kind).ok)
			clock += 1
			if kind == "settlement" then
				world:setOwner(1,catalog.sparta,player.UserId,player.DisplayName,economy:get(player.UserId).level)
			end
			service:refresh(player)
		end
		local function status() return service:get(player.UserId) end
		local function living()
			local entry = status()
			local rig = if entry then entry.rig else nil
			local humanoid = if rig then rig:FindFirstChildOfClass("Humanoid") else nil
			return if humanoid and humanoid.Health > 0 then rig else nil
		end
		local function livingCount()
			local count = 0
			for _, rig in world.model.Troops:GetChildren() do
				local humanoid = rig:FindFirstChildOfClass("Humanoid")
				if rig:GetAttribute("OwnerId") == player.UserId and humanoid and humanoid.Health > 0 then count += 1 end
			end
			return count
		end
		assert(registry:claim(player.UserId,"sparta").ok)
		economy:open(player.UserId)
		world:setOwner(1,catalog.sparta,player.UserId,player.DisplayName,1)
		service = WarriorService.start(world,registry,economy,catalog)
		test("outpost owners have no warrior before the barracks unlock", function()
			service:refresh(player)
			task.wait(.3)
			assert(living() == nil and livingCount() == 0)
		end)
		local first = nil
		test("settlement two immediately deploys exactly one server-owned warrior", function()
			upgrade("settlement")
			waitFor(function() return living() ~= nil end,"initial warrior",1)
			first = living()
			assert(livingCount() == 1 and first.Humanoid.Health == 100)
			assert(first.HumanoidRootPart:GetNetworkOwner() == nil,"NPC physics must belong to the server")
			task.wait(.3)
			for _, joint in first:GetDescendants() do
				assert(not (joint:IsA("Motor6D") and joint.Name == "RightGrip"),"Engine RightGrip competes with the NPC's manual weapon weld")
			end
		end)
		test("repeated refresh and later settlement rebuilds retain the same living warrior", function()
			for _ = 1, 5 do service:refresh(player) end
			upgrade("settlement")
			upgrade("settlement")
			assert(living() == first and livingCount() == 1)
		end)
		test("living warrior receives owner gear in place while preserving missing health", function()
			first.Humanoid.Health = 70
			upgrade("weapon")
			assert(living() == first and first:GetAttribute("WarriorDamage") == 14)
			assert(first.Humanoid.Health == 70 and first.Humanoid.MaxHealth == 100)
			upgrade("armor")
			assert(living() == first and first.Humanoid.Health == 85 and first.Humanoid.MaxHealth == 115)
			service:refresh(player)
			assert(first.Humanoid.Health == 85 and livingCount() == 1)
		end)
		local replacement = nil
		test("death waits fifteen real seconds and replacement inherits gear bought while pending", function()
			local diedAt = now()
			first.Humanoid.Health = 0
			waitFor(function() return status() and type(status().respawnAt) == "number" and status().respawnAt > now() end,"death deadline")
			local deadline = status().respawnAt
			assert(deadline >= diedAt+14.9 and deadline <= diedAt+15.5)
			upgrade("weapon")
			upgrade("armor")
			for _ = 1, 3 do service:refresh(player) end
			assert(status().respawnAt == deadline and living() == nil,"Gear refresh bypassed the pending deadline")
			waitFor(function() return first.Parent == nil end,"three-second corpse removal",4.5)
			while now() < deadline do
				assert(living() == nil and livingCount() == 0,"Warrior respawned before fifteen seconds")
				task.wait(.05)
			end
			waitFor(function() return living() ~= nil end,"automatic warrior replacement",3)
			replacement = living()
			assert(replacement ~= first and livingCount() == 1)
			assert(replacement:GetAttribute("WarriorDamage") == 19)
			assert(replacement:GetAttribute("WeaponLevel") == 3 and replacement:GetAttribute("ArmorLevel") == 3)
			assert(replacement.Humanoid.MaxHealth == 135 and replacement.Humanoid.Health == 135)
		end)
		test("release and reclaim cancel the old fifteen-second callback without duplicating a new unit", function()
			replacement.Humanoid.Health = 0
			waitFor(function() return status() and type(status().respawnAt) == "number" and status().respawnAt > now() end,"second death deadline")
			local staleDeadline = status().respawnAt
			service:release(player.UserId)
			registry:release(player.UserId)
			economy:close(player.UserId)
			world:setOwner(1,nil,nil,nil)
			assert(living() == nil and livingCount() == 0)
			assert(registry:claim(player.UserId,"sparta").ok)
			economy:open(player.UserId)
			world:setOwner(1,catalog.sparta,player.UserId,player.DisplayName,1)
			upgrade("settlement")
			waitFor(function() return living() ~= nil end,"new claim's independent warrior")
			local reclaimed = living()
			while now() < staleDeadline+.3 do
				assert(living() == reclaimed and livingCount() == 1,"Stale replacement changed or duplicated the new claim")
				task.wait(.1)
			end
			assert(reclaimed:GetAttribute("WarriorDamage") == 10 and reclaimed.Humanoid.MaxHealth == 100)
		end)
		return {ok=true,cases=cases,message="Unlock, cap, server physics, live gear, real 15-second replacement, corpse cleanup, and stale-release cancellation passed"}
	end)
	if service then service:destroy() end
	container:Destroy()
	for _, name in {"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"} do
		player:SetAttribute(name,originalAttributes[name])
	end
	assert(ok,result)
	return result
end

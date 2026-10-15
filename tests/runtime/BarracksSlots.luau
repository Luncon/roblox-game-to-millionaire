-- Two real players verify production wall-clock delays for tiers two, three, and four.
return function(first,second)
	local T=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local function near(actual,expected) return math.abs(actual-expected)<.002 end
	local Players=game:GetService("Players")
	assert(first~=second and first.Parent==Players and second.Parent==Players)
	local Game=game.ServerScriptService.Game
	local Map,Registry,Economy,Service=require(Game.BattlefieldMap),require(Game.ClaimRegistry),require(Game.Economy),require(Game.WarriorService)
	local Tracks=require(game.ReplicatedStorage.Shared.UpgradeTracks)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local names={"BarracksLevel","WarriorCount","RangedCount","ArmyCount","TroopCapacity","ArmyRespawnDelay","WarriorRespawnAt","RangedRespawnAt"}
	local saved={}
	for _,player in {first,second} do
		saved[player]={}
		for _,name in names do saved[player][name]=player:GetAttribute(name) end
	end
	local container=Instance.new("Folder")
	container.Name="IndependentBarracksSlotsFixture"
	container.Parent=workspace
	local service=nil
	local cases=0
	local function now() return workspace:GetServerTimeNow() end
	local function waitFor(predicate,description,timeout)
		local deadline=now()+(timeout or 3)
		repeat if predicate() then return end; task.wait(.05) until now()>deadline
		error("Timed out: "..description)
	end
	local function test(name,callback) callback(); cases+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(0,0,1800)*world.model:GetPivot())
		local registry=Registry.new(8,{sparta=true,britain=true})
		registry:claim(first.UserId,"sparta"); registry:claim(second.UserId,"britain")
		local civilizations={[first]=catalog[1],[second]=catalog[2]}
		local plotIds={[first]=1,[second]=2}
		local clock=0
		local economy=Economy.new(function() return clock end)
		for _,player in {first,second} do economy:open(player.UserId) end
		service=Service.start(world,registry,economy,{sparta=catalog[1],britain=catalog[2]})
		local function upgrade(player,kind)
			local state=economy:get(player.UserId)
			local field=if kind=="settlement" then "level" else kind.."Level"
			local level=state[field]
			local cost=Tracks[kind][level].nextCost
			for _=1,cost do assert(economy:earn(player.UserId).ok); clock+=.1 end
			assert(economy:upgrade(player.UserId,level,kind).ok)
			clock+=1
			world:setOwner(plotIds[player],civilizations[player],player.UserId,player.DisplayName,economy:get(player.UserId).level)
			service:refresh(player)
		end
		local function slot(player,kind)
			local entry=service:get(player.UserId)
			return if entry then entry.slots[kind] else nil
		end
		local function kill(player,kind,delay)
			local rig=slot(player,kind).rig
			local started=now()
			rig.Humanoid.Health=0
			waitFor(function() return slot(player,kind).respawnAt>now() end,"slot death deadline")
			local deadline=slot(player,kind).respawnAt
			assert(deadline>=started+delay-.05 and deadline<=started+delay+.3)
			return rig,deadline
		end
		local firstMelee,secondMelee,firstRanged,meleeDeadline,secondDeadline,rangedDeadline
		test("barracks tiers one through three retain one melee slot",function()
			upgrade(first,"settlement")
			firstMelee=slot(first,"warrior").rig
			assert(firstMelee and slot(first,"ranged")==nil)
			upgrade(first,"barracks")
			assert(slot(first,"warrior").rig==firstMelee and slot(first,"ranged")==nil)
			upgrade(second,"settlement"); upgrade(second,"settlement")
			upgrade(second,"barracks"); upgrade(second,"barracks")
			secondMelee=slot(second,"warrior").rig
			assert(secondMelee and slot(second,"ranged")==nil)
		end)
		test("pending tier-two melee keeps fourteen-and-a-half-second deadline while higher barracks unlock ranged",function()
			firstMelee,meleeDeadline=kill(first,"warrior",14.5)
			secondMelee,secondDeadline=kill(second,"warrior",14)
			upgrade(first,"settlement"); upgrade(first,"barracks")
			upgrade(first,"settlement"); upgrade(first,"barracks")
			firstRanged=slot(first,"ranged").rig
			assert(firstRanged and firstRanged:GetAttribute("WarriorClass")=="ranged")
			assert(slot(first,"warrior").rig==nil and slot(first,"warrior").respawnAt==meleeDeadline)
			for _=1,3 do service:refresh(first) end
			assert(slot(first,"ranged").rig==firstRanged and slot(first,"warrior").respawnAt==meleeDeadline)
		end)
		test("ranged gear updates preserve missing health without replacing either slot",function()
			upgrade(first,"weapon"); upgrade(first,"armor")
			assert(near(firstRanged:GetAttribute("WarriorDamage"),T.weapon[2].damage*.8) and near(firstRanged.Humanoid.MaxHealth,T.armor[2].health))
			firstRanged.Humanoid.Health=T.armor[2].health-30
			upgrade(first,"weapon")
			assert(near(firstRanged.Humanoid.Health,T.armor[2].health-30) and near(firstRanged:GetAttribute("WarriorDamage"),T.weapon[3].damage*.8))
			upgrade(first,"armor")
			assert(slot(first,"ranged").rig==firstRanged and near(firstRanged.Humanoid.Health,T.armor[3].health-30) and near(firstRanged.Humanoid.MaxHealth,T.armor[3].health))
			assert(slot(first,"warrior").respawnAt==meleeDeadline)
		end)
		test("ranged and melee deaths use independent real thirteen-and-a-half fourteen and fourteen-and-a-half deadlines",function()
			firstRanged,rangedDeadline=kill(first,"ranged",13.5)
			local checks={{first,"warrior",meleeDeadline},{first,"ranged",rangedDeadline},{second,"warrior",secondDeadline}}
			local done={}
			while not (done[1] and done[2] and done[3]) do
				for index,check in checks do
					local current=slot(check[1],check[2])
					if now()<check[3] then assert(current.rig==nil,"A slot bypassed its death deadline")
					elseif current.rig then done[index]=true
					elseif now()>check[3]+3 then error("Slot failed to replace after its deadline") end
				end
				task.wait(.05)
			end
			assert(firstMelee.Parent==nil and firstRanged.Parent==nil and secondMelee.Parent==nil)
			assert(near(slot(first,"warrior").rig:GetAttribute("WarriorDamage"),T.weapon[3].damage))
			assert(near(slot(first,"ranged").rig:GetAttribute("WarriorDamage"),T.weapon[3].damage*.8))
			assert(near(slot(first,"warrior").rig.Humanoid.Health,T.armor[3].health) and near(slot(first,"ranged").rig.Humanoid.Health,T.armor[3].health))
		end)
		test("live two-slot army survives actual owner reset without duplicate units",function()
			local melee,ranged=slot(first,"warrior").rig,slot(first,"ranged").rig
			first:LoadCharacterAsync()
			service:refresh(first)
			assert(slot(first,"warrior").rig==melee and slot(first,"ranged").rig==ranged)
			local counts={warrior=0,ranged=0}
			for _,rig in world.model.Troops:GetChildren() do
				if rig:GetAttribute("OwnerId")==first.UserId and rig.Humanoid.Health>0 then counts[rig:GetAttribute("WarriorClass")]+=1 end
			end
			assert(counts.warrior==1 and counts.ranged==1)
		end)
		test("release removes live ranged and cancels pending melee across its old deadline",function()
			local _,deadline=kill(first,"warrior",13.5)
			service:release(first.UserId); registry:release(first.UserId); economy:close(first.UserId)
			while now()<deadline+.2 do
				assert(service:get(first.UserId)==nil)
				for _,rig in world.model.Troops:GetChildren() do assert(rig:GetAttribute("OwnerId")~=first.UserId) end
				task.wait(.1)
			end
		end)
		return {ok=true,cases=cases,message="Barracks prices/gates, real tier2/3/4 delays, pending-deadline preservation, independent ranged/melee slots, inherited gear/reset and leave cancellation passed"}
	end)
	if service then service:destroy() end
	container:Destroy()
	for _,player in {first,second} do for _,name in names do player:SetAttribute(name,saved[player][name]) end end
	assert(ok,result)
	return result
end

-- Three real owners allow an actual different-owner assist/final-hit distinction.
return function(first,second,third)
	local Players=game:GetService("Players")
	assert(first and second and third and first~=second and first~=third and second~=third)
	for _,player in {first,second,third} do assert(player.Parent==Players) end
	local Game=game.ServerScriptService.Game
	local Map=require(Game.BattlefieldMap)
	local Registry=require(Game.ClaimRegistry)
	local Economy=require(Game.Economy)
	local Rig=require(Game.WarriorRig)
	local Combat=require(Game.CombatService)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name="FinalHitRewardFixture"
	container.Parent=workspace
	local players={first,second,third}
	local saved={}
	for _,player in players do saved[player]={pivot=player.Character:GetPivot(),anchor=player.Character.HumanoidRootPart.Anchored,health=player.Character.Humanoid.Health} end
	local combat=nil
	local cases=0
	local function test(name,callback) callback(); cases+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		world.model:PivotTo(CFrame.new(1800,0,0)*world.model:GetPivot())
		local registry=Registry.new(8,{sparta=true,britain=true,mongols=true})
		local economy=Economy.new()
		local civilizations={[first]=catalog[1],[second]=catalog[2],[third]=catalog[4]}
		local plots={[first]=1,[second]=2,[third]=3}
		for _,player in players do
			assert(registry:claim(player.UserId,civilizations[player].id).ok)
			economy:open(player.UserId)
			player.Character.HumanoidRootPart.Anchored=true
			player.Character:PivotTo(world:getSpawn(plots[player]))
		end
		local publications={}
		combat=Combat.new(world,registry,economy,function(player,response,action)
			assert(action=="kill" and response.amount==10)
			table.insert(publications,{ownerId=player.UserId,coins=response.state.coins})
		end)
		local arena=world.model.Battlefield
		local function position(x,z) return arena.Position+Vector3.new(x,4,z or 0) end
		local function npc(player,x,z,health)
			local rig=Rig.create(civilizations[player],CFrame.new(position(x,z)),player.UserId,plots[player])
			rig.Parent=world.model.Troops
			rig.HumanoidRootPart.Anchored=true
			if health then rig.Humanoid.Health=health end
			assert(combat:register(rig,player.UserId,"warrior"))
			return rig
		end
		local function clear() world.model.Troops:ClearAllChildren() end
		test("accepted nonlethal damage earns nothing and immediate repeat respects cooldown",function()
			clear()
			local attacker,target=npc(first,0,0),npc(second,3,0)
			local hit=combat:hit(attacker,target)
			assert(hit.ok and hit.damage==10 and not hit.killed and target.Humanoid.Health==90)
			assert(economy:get(first.UserId).coins==0 and #publications==0)
			assert(not combat:hit(attacker,target).ok and target.Humanoid.Health==90)
		end)
		test("actual lethal NPC transition awards exactly ten once before publication",function()
			clear()
			local attacker,target=npc(first,0,0),npc(second,3,0,10)
			local before=economy:get(first.UserId).coins
			local hit=combat:hit(attacker,target)
			assert(hit.ok and hit.killed and hit.reward and hit.reward.ok and hit.reward.amount==10)
			assert(target.Humanoid.Health==0 and economy:get(first.UserId).coins==before+10)
			assert(#publications==1 and publications[1].coins==before+10)
			assert(not combat:hit(attacker,target).ok)
			combat:unregister(target)
			combat:register(target,second.UserId,"warrior")
			assert(not combat:hit(attacker,target).ok and economy:get(first.UserId).coins==before+10)
		end)
		test("self friendly unregistered and unclaimed targets cannot generate kills",function()
			clear()
			local attacker,target=npc(first,0,0),npc(first,3,0,10)
			local before=economy:get(first.UserId).coins
			assert(not combat:hit(attacker,attacker).ok)
			assert(not combat:hit(attacker,target).ok and target.Humanoid.Health==10)
			target:Destroy()
			target=npc(second,3,0,10)
			combat:unregister(target)
			assert(not combat:hit(attacker,target).ok)
			combat:register(target,second.UserId,"warrior")
			registry:release(second.UserId)
			assert(not combat:hit(attacker,target).ok and economy:get(first.UserId).coins==before)
			assert(registry:claim(second.UserId,"britain").ok)
		end)
		test("environmental death after prior accepted damage gives no final-hit reward",function()
			clear()
			local attacker,target=npc(first,0,0),npc(second,3,0,20)
			local before=economy:get(first.UserId).coins
			assert(combat:hit(attacker,target).ok and target.Humanoid.Health==10)
			target.Humanoid.Health=0
			task.wait(.05)
			assert(economy:get(first.UserId).coins==before)
			assert(not combat:hit(attacker,target).ok)
		end)
		test("blocked distant outside and dead actors cannot cause damage or reward",function()
			clear()
			local attacker,target=npc(first,0,0),npc(second,3,0,10)
			local before=economy:get(first.UserId).coins
			local wall=Instance.new("Part")
			wall.Size=Vector3.new(.2,12,6)
			wall.CFrame=CFrame.new(position(.5,0))
			wall.Anchored=true
			wall.Parent=container
			assert(not combat:hit(attacker,target).ok)
			wall:Destroy()
			target:PivotTo(CFrame.new(position(6,0)))
			assert(not combat:hit(attacker,target).ok)
			attacker:PivotTo(CFrame.new(position(73,0)))
			target:PivotTo(CFrame.new(position(76,0)))
			assert(not combat:hit(attacker,target).ok)
			attacker.Humanoid.Health=0
			assert(not combat:hit(attacker,target).ok)
			assert(target.Humanoid.Health==10 and economy:get(first.UserId).coins==before)
		end)
		test("a different owner's assist receives zero while final hitter gets ten",function()
			clear()
			local assist,attacker,target=npc(third,0,2),npc(first,0,-2),npc(second,3,0,20)
			local before=economy:get(first.UserId).coins
			assert(combat:hit(assist,target).ok and target.Humanoid.Health==10)
			assert(economy:get(third.UserId).coins==0)
			local hit=combat:hit(attacker,target)
			assert(hit.ok and hit.killed and economy:get(first.UserId).coins==before+10)
			assert(economy:get(third.UserId).coins==0 and economy:get(second.UserId).coins==0)
		end)
		test("actual current-player kill awards once and character reset invalidates the old victim",function()
			clear()
			local attacker=npc(first,0,0)
			local target=second.Character
			target.HumanoidRootPart.Anchored=true
			target:PivotTo(CFrame.new(position(3,0)))
			target.Humanoid.Health=10
			assert(combat:register(target,second.UserId,"player"))
			local before=economy:get(first.UserId).coins
			local hit=combat:hit(attacker,target)
			assert(hit.ok and hit.killed and economy:get(first.UserId).coins==before+10)
			assert(not combat:hit(attacker,target).ok)
			second:LoadCharacterAsync()
			assert(combat:actor(target)==nil and economy:get(first.UserId).coins==before+10)
		end)
		return {ok=true,cases=cases,message="Nonlethal/cooldown, NPC/player lethal rewards, exactly-once publication, cross-owner assist exclusion, protection, environment, and reset passed"}
	end)
	if combat then combat:destroy() end
	container:Destroy()
	for _,player in players do
		local character=player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.Anchored=saved[player].anchor
			character:PivotTo(saved[player].pivot)
			if character.Humanoid.Health>0 then character.Humanoid.Health=math.min(saved[player].health,character.Humanoid.MaxHealth) end
		end
	end
	assert(ok,result)
	return result
end

-- Two genuine clients; all progression is supplied by the test-only fake store.
local testing=game:GetService("StudioTestService")
local args=testing:GetTestArgs()
if type(args)~="table" or args.suite~="tactical-combat"then return end
local Players,Replicated=game:GetService("Players"),game:GetService("ReplicatedStorage")
local context=require(game.ServerStorage.RuntimeTests.ProfileTestContext)
assert(context.store.isFakeProfileStore,"Multiplayer tactical fixtures must use fake profiles")
local control=Instance.new("Folder");control.Name="PrototypeTestControl"
local commands,reports=Instance.new("RemoteEvent"),Instance.new("RemoteEvent")
commands.Name,commands.Parent="Command",control;reports.Name,reports.Parent="Report",control
local responses={}
local connection=reports.OnServerEvent:Connect(function(player,round,response)
	responses[round]=responses[round] or {};responses[round][player.UserId]=response
end)
control.Parent=Replicated
local service;local sequence=0
local function waitFor(predicate,label,timeout)
	local deadline=os.clock()+(timeout or 20)
	repeat if predicate()then return end;task.wait(.05)until os.clock()>deadline
	error("Timed out: "..label)
end
local function round(action,options,target,count,timeout)
	sequence+=1;local name="tactical-multiplayer-"..sequence
	commands:FireAllClients({round=name,action=action,options=options,target=target})
	waitFor(function()local n=0;for _ in responses[name] or {}do n+=1 end;return n==count end,name,timeout or 30)
	for _,response in responses[name]do assert(response.executed,tostring(response.result));assert(response.result.ok)end
	return responses[name]
end
local ok,result=pcall(function()
	waitFor(function()
		local players=Players:GetPlayers();if #players~=2 or not context.service then return false end
		for _,player in players do
			if not responses.ready or not responses.ready[player.UserId] or not player.Character
				or not context.service.profiles:isWritable(player.UserId)then return false end
		end
		return true
	end,"two native clients and writable fake profiles",60)
	service=context.service
	local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
	for index,player in players do
		local id=if index==1 then "sparta" else "britain"
		assert(service.profiles:set(player.UserId,id,{coins=1000,level=10,weaponLevel=1,armorLevel=1,barracksLevel=4,
			trainingLevel=1,farmLevel=1,workersLevel=1,armyCampLevel=1,extraTroopClass="warrior"}))
		round("civilizationInput",{action="choose",civilization=id},player.UserId,1)
		round("developmentInput",{kind="command",button="Hold"},player.UserId,1)
		player.Character.HumanoidRootPart.Anchored=true
	end
	local arena=service.world.model.Battlefield
	local function point(x,z)
		local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include
		filter.FilterDescendantsInstances={service.world.model.Ground,service.world.model.Landscape.TerrainSurface}
		filter.RespectCanCollide=true
		local position=arena.Position+Vector3.new(x,60,z)
		local hit=workspace:Raycast(position,Vector3.new(0,-120,0),filter);assert(hit)
		return Vector3.new(position.X,hit.Position.Y+3,position.Z)
	end
	for _,slot in service.neutralOpponents:get()do
		slot.rig.HumanoidRootPart.Anchored=true;slot.rig:PivotTo(CFrame.new(point(150,150)))
	end
	local combatants={}
	for index,player in players do
		local sign=if index==1 then -1 else 1
		local army=service.army:get(player.UserId)
		for slotId,slot in army.slots do
			local rig=slot.rig;assert(rig)
			rig.HumanoidRootPart.Anchored=true
			rig:PivotTo(CFrame.new(point(sign*(if slotId=="ranged"then 28 else 12),if slotId=="camp"then 4 else 0)))
			table.insert(combatants,rig)
		end
	end
	round("developmentInput",{kind="command",button="Advance"},players[1].UserId,1)
	assert(service.army:get(players[1].UserId).order=="advance" and service.army:get(players[2].UserId).order=="hold",
		"One real client's order changed another owner's army")
	round("developmentInput",{kind="command",button="Advance"},players[2].UserId,1)
	for _,rig in combatants do rig.HumanoidRootPart.Anchored=false;rig.HumanoidRootPart:SetNetworkOwner(nil)end
	local observations=round("tacticalObserve",{ownerIds={players[1].UserId,players[2].UserId},seconds=10,focus=arena.Position},nil,2,20)
	for _,rig in combatants do if rig.Parent and rig.Humanoid.Health>0 then
		assert(rig.HumanoidRootPart:GetNetworkOwner()==nil,"Client became combat movement authority")
	end end
	local evidence={}
	for userId,response in observations do evidence[tostring(userId)]=response.result end
	return {ok=true,cases=3,clients=2,evidence=evidence,
		message="Two native clients: isolated commander orders, server-owned movement, replicated limb poses and damage"}
end)
if service then
	for _,player in Players:GetPlayers()do if player.Character and player.Character:FindFirstChild("HumanoidRootPart")then
		player.Character.HumanoidRootPart.Anchored=false
	end end
	for _,slot in service.neutralOpponents:get()do if slot.rig then
		slot.rig.HumanoidRootPart.Anchored=false;slot.rig.HumanoidRootPart:SetNetworkOwner(nil)
	end end
end
connection:Disconnect();control:Destroy()
testing:EndTest(if ok then result else {ok=false,message=tostring(result)})

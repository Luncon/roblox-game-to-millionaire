--!strict

local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Defaults=require(Shared.NeutralOpponentConfig)
local Warrior=require(Shared.WarriorConfig)
local Ranged=require(Shared.RangedConfig)
local Rules=require(script.Parent.CombatRules)
local Rig=require(script.Parent.WarriorRig)
local Navigator=require(script.Parent.WarriorNavigator)
local Projectile=require(script.Parent.TroopProjectile)
local Topography=require(script.Parent.Topography)
local Encounter=require(script.Parent.CombatEncounter)
local Motion=require(script.Parent.EncounterMotion)
local NeutralOpponentService={}
local COLLISION_GROUP="CivilizationWarriors"

function NeutralOpponentService.start(world,combat,configuration: any?,sharedEncounter: any?)
	local config=configuration or Defaults
	local encounters=sharedEncounter or Encounter.new(world,combat)
	local controller={}
	local active=true
	local slots={}
	local arena=world.model.Battlefield
	assert(not world.model:FindFirstChild("NeutralOpponents"),"Neutral opponents already started")
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="NeutralOpponents",world.model
	local projectiles=Projectile.new(world,combat)
	local heartbeat: RBXScriptConnection?
	if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then PhysicsService:RegisterCollisionGroup(COLLISION_GROUP) end
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP,COLLISION_GROUP,false)
	local function release(slot)
		if slot.deathConnection then slot.deathConnection:Disconnect();slot.deathConnection=nil end
		if slot.destroyConnection then slot.destroyConnection:Disconnect();slot.destroyConnection=nil end
		if slot.navigator then slot.navigator:destroy();slot.navigator=nil end
		if slot.rig then projectiles:cancel(slot.rig);encounters:forget(slot.rig);combat:unregister(slot.rig) end
		slot.target=nil
	end
	local function fallen(slot,rig)
		if not active or slot.rig~=rig then return end
		release(slot)
		slot.rig=nil
		slot.respawnAt=workspace:GetServerTimeNow()+config.respawnDelay
		slot.corpses[rig]=workspace:GetServerTimeNow()+Warrior.corpseLifetime
		rig:SetAttribute("WarriorState","Fallen")
		local flash=rig:FindFirstChild("CombatHitFlash");if flash then flash.Enabled=false end
	end
	local function spawn(slot)
		local rig=Rig.createNeutral(slot.spawnFrame,slot.kind)
		slot.rig,slot.respawnAt,slot.nextAttack,slot.attackUntil=rig,0,0,0
		rig:SetAttribute("NeutralSlot",slot.id)
		rig:SetAttribute("WarriorState","Guarding")
		for _,part in rig:GetDescendants() do
			if part:IsA("BasePart") then part.CollisionGroup=COLLISION_GROUP end
		end
		rig.Parent=folder
		rig.HumanoidRootPart:SetNetworkOwner(nil)
		assert(combat:registerNeutral(rig,slot.kind),"Neutral combat registration failed")
		slot.navigator=Navigator.new(rig,function() return active and slot.rig==rig end,world)
		slot.deathConnection=rig.Humanoid.Died:Connect(function() fallen(slot,rig) end)
		slot.destroyConnection=rig.Destroying:Connect(function() fallen(slot,rig) end)
	end
	function controller:get()
		local result={}
		for id,slot in slots do
			result[id]={id=id,kind=slot.kind,rig=slot.rig,respawnAt=slot.respawnAt,spawnFrame=slot.spawnFrame}
		end
		return result
	end
	function controller:destroy()
		if not active then return end
		active=false
		if heartbeat then heartbeat:Disconnect() end
		for _,slot in slots do
			release(slot)
			if slot.rig then slot.rig:Destroy();slot.rig=nil end
			for corpse in slot.corpses do corpse:Destroy() end
			table.clear(slot.corpses)
			slot.respawnAt=0
		end
		projectiles:destroy()
		if not sharedEncounter then encounters:destroy() end
		folder:Destroy()
	end
	if not config.enabled then return controller end
	for _,definition in config.slots do
		local offset=definition.offset
		-- Ground's frame preserves translated/rotated fixture maps. The landscape
		-- sampler uses the generated map's local coordinates and triangle heights.
		local origin=world.model.Ground.CFrame*CFrame.new(0,.95,0)
		local frame=origin*CFrame.new(offset.X,Topography.sampleHeight(offset.X,offset.Z)+3,offset.Z)
		local slot={id=definition.id,kind=definition.kind,spawnFrame=frame,corpses={}}
		slots[slot.id]=slot
		spawn(slot)
	end
	local function think(now)
		local actors=combat:actors()
		local serverNow=workspace:GetServerTimeNow()
		for _,slot in slots do
			for corpse,deadline in slot.corpses do
				if serverNow>=deadline then slot.corpses[corpse]=nil;corpse:Destroy() end
			end
			if not slot.rig then
				if serverNow>=slot.respawnAt then spawn(slot) end
				continue
			end
			local rig=slot.rig
			local attacker=combat:actor(rig)
			if not attacker then fallen(slot,rig);continue end
			local plan=encounters:step(rig,{order="advance",homeGoal=slot.spawnFrame.Position,actors=actors,
				fire=function(target)return projectiles:fire(rig,target,"arrow")end},now)
			slot.target=plan.target
			Motion.apply(rig,slot.navigator,world,plan,now)
		end
	end
	local elapsed=0
	heartbeat=RunService.Heartbeat:Connect(function(dt)
		if not world.model:IsDescendantOf(workspace) or folder.Parent~=world.model then controller:destroy();return end
		projectiles:step(dt)
		elapsed+=dt
		local now=os.clock()
		if elapsed>=Warrior.thinkInterval then elapsed=0;think(now) end
		for _,slot in slots do
			if slot.rig then
				if slot.rig.Humanoid.Health>0 then
					Motion.publish(slot.rig,encounters:advance(slot.rig,now))
					Rig.animate(slot.rig,now,slot.rig.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>.5)
				end
			end
		end
	end)
	return controller
end

return NeutralOpponentService

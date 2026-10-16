--!strict

-- Only CombatService supplies damage application. Clients never select damage or targets.
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.WeaponSkillConfig)
local Tracks=require(Shared.UpgradeTracks)
local Ranged=require(Shared.RangedConfig)
local Variants=require(Shared.WarriorConfig).variants
local Rules=require(script.Parent.CombatRules)
local Skills={}

function Skills.new(world,combat,economy,damage,clock,physics)
	local now=clock or os.clock
	local space=physics or workspace
	local controller={}
	local alive=true
	local worldConnection
	local actions,deadlines,ordinary={}, {},setmetatable({}, {__mode="k"})
	local arena=world.model.Battlefield
	local function key(actor,family)
		return tostring(actor.ownerId)..":"..(if actor.kind=="player" then "player" else actor.rig:GetAttribute("ArmySlot") or actor.kind)..":"..family
	end
	local function equipped(actor,state)
		if actor.kind~="player" then
			local variant=(if actor.kind=="ranged" then Ranged.variants else Variants)[actor.civilizationId]
			return if variant then Config.family(variant.weaponKind) else nil
		end
		local tool=actor.rig:FindFirstChildOfClass("Tool")
		if not tool or tool:GetAttribute("GeneratedBy")~="CivilizationEquipment"
			or tool:GetAttribute("CivilizationId")~=actor.civilizationId
			or tool:GetAttribute("WeaponLevel")~=state.weaponLevel then return nil end
		return Config.family(tool:GetAttribute("WeaponKind"))
	end

	function controller:info(rig)
		if not alive then return nil end
		local actor=combat:actor(rig)
		if not actor or actor.neutral then return nil end
		local state=economy:get(actor.ownerId)
		if not state then return nil end
		local family=equipped(actor,state)
		if not family then return nil end
		return {actor=actor,state=state,family=family,readyAt=deadlines[key(actor,family)] or 0}
	end
	function controller:refresh(rig)
		local info=self:info(rig)
		rig:SetAttribute("WeaponSkillFamily",if info then info.family else nil)
		rig:SetAttribute("WeaponSkillLevel",if info then info.state.skillLevel or 0 else 0)
		rig:SetAttribute("WeaponSkillReadyAt",if info then workspace:GetServerTimeNow()+math.max(0,info.readyAt-now()) else 0)
	end
	function controller:busy(rig): boolean return actions[rig]~=nil end
	function controller:lockOrdinary(rig,duration)
		ordinary[rig]=math.max(ordinary[rig] or 0,now()+duration)
	end
	function controller:cancel(rig)
		local action=actions[rig]
		if not action then return end
		actions[rig]=nil
		local hum=rig:FindFirstChildOfClass("Humanoid")
		if hum then
			if hum.WalkSpeed==0 then hum.WalkSpeed=action.speed end
			hum.AutoRotate=action.autoRotate
		end
		if action.networkTaken and action.root.Parent and not action.root.Anchored then
			pcall(function() action.root:SetNetworkOwnershipAuto() end)
		end
		rig:SetAttribute("WeaponSkillActive",nil)
		rig:SetAttribute("WeaponSkillStartedAt",nil)
		rig:SetAttribute("WeaponSkillEndsAt",nil)
	end
	function controller:forgetOwner(ownerId)
		local prefix=tostring(ownerId)..":"
		for id in deadlines do if string.sub(id,1,#prefix)==prefix then deadlines[id]=nil end end
	end
	local function valid(action)
		local info=controller:info(action.rig)
		return info and info.family==action.family and info.actor.humanoid==action.humanoid
			and info.actor.civilizationId==action.civilizationId and info.actor.plotId==action.plotId
			and combat:canAct(action.rig) and Rules.containsArena(arena,info.actor.position)
	end
	local function targets(actor,reach,facing)
		local result={}
		for _,victim in combat:actors() do
			local delta=victim.position-actor.position
			if Rules.canDamage(actor,victim,arena,reach) and combat:visible(actor,victim)
				and (not facing or delta.Magnitude<.01 or actor.root.CFrame.LookVector:Dot(delta.Unit)>=.25) then
				table.insert(result,victim)
			end
		end
		table.sort(result,function(a,b)
			local da,db=(a.position-actor.position).Magnitude,(b.position-actor.position).Magnitude
			if math.abs(da-db)>.0001 then return da<db end
			local ka=tostring(a.ownerId or 0)..":"..tostring(a.rig:GetAttribute("ArmySlot") or a.kind)..":"..a.rig.Name
			local kb=tostring(b.ownerId or 0)..":"..tostring(b.rig:GetAttribute("ArmySlot") or b.kind)..":"..b.rig.Name
			return ka<kb
		end)
		return result
	end
	function controller:activate(rig,order,automatic)
		local info=self:info(rig)
		if not info or not combat:canAct(rig) then return {ok=false,reason="not_equipped"} end
		local actor,state,family=info.actor,info.state,info.family
		local tier=Config.tiers[state.skillLevel or 0]
		if not tier or state.trainingLevel~=1 or state.weaponLevel<tier.unlock then return {ok=false,reason="skill_locked"} end
		if order=="regroup" or (family=="spear" and order=="hold") then return {ok=false,reason="order_locked"} end
		if not Rules.containsArena(arena,actor.position) then return {ok=false,reason="protected"} end
		local time=now()
		if time<info.readyAt then return {ok=false,reason="cooldown"} end
		if self:busy(rig) or time<(ordinary[rig] or 0) then return {ok=false,reason="busy"} end
		local definition=Config.families[family]
		local candidates=targets(actor,if family=="spear" then 14 else definition.range,family~="axe")
		if automatic and #candidates==0 then return {ok=false,reason="no_target"} end
		local direction=Vector3.new(actor.root.CFrame.LookVector.X,0,actor.root.CFrame.LookVector.Z)
		if direction.Magnitude<.01 then return {ok=false,reason="invalid_direction"} end
		local action={rig=rig,root=actor.root,humanoid=actor.humanoid,family=family,tier=tier,
			civilizationId=actor.civilizationId,plotId=actor.plotId,startedAt=time,lastAt=time,
			direction=direction.Unit,distance=0,struck=false,resolved={},
			target=if candidates[1] then {rig=candidates[1].rig,humanoid=candidates[1].humanoid} else nil,
			speed=actor.humanoid.WalkSpeed,autoRotate=actor.humanoid.AutoRotate,
			base=Tracks.weapon[state.weaponLevel].damage*(if actor.kind=="ranged" then Ranged.damageMultiplier else 1)}
		deadlines[key(actor,family)]=time+definition.cooldown
		actions[rig]=action
		ordinary[rig]=time+definition.duration
		actor.humanoid.WalkSpeed=0
		actor.humanoid.AutoRotate=false
		actor.humanoid:Move(Vector3.zero)
		if family=="spear" and not actor.root.Anchored then
			local taken=pcall(function() actor.root:SetNetworkOwner(nil) end)
			-- Troops must remain server-owned after the dash. Only player
			-- characters return to their usual automatic ownership policy.
			action.networkTaken=taken and actor.kind=="player"
		end
		local serverAt=workspace:GetServerTimeNow()
		rig:SetAttribute("WeaponSkillActive",family)
		rig:SetAttribute("WeaponSkillStartedAt",serverAt)
		rig:SetAttribute("WeaponSkillEndsAt",serverAt+definition.duration)
		self:refresh(rig)
		return {ok=true,family=family,readyAt=serverAt+definition.cooldown}
	end
	local function contact(action,victim,index,multiplier,reach,facing)
		if not valid(action) then return false end
		local actor,target=combat:actor(action.rig),combat:actor(victim.rig)
		if not target or target.humanoid~=victim.humanoid then return false end
		local token=tostring(index)
		action.resolved[token]=action.resolved[token] or {}
		if action.resolved[token][target.humanoid] then return false end
		if not Rules.canDamage(actor,target,arena,reach) or not combat:visible(actor,target) then return false end
		local delta=target.position-actor.position
		if facing and delta.Magnitude>.01 and actor.root.CFrame.LookVector:Dot(delta.Unit)<.25 then return false end
		action.resolved[token][target.humanoid]=true
		return damage(actor,target,action.base*multiplier).ok==true
	end
	local function dash(action,elapsed)
		local actor=combat:actor(action.rig)
		local function firstInPath()
			local chosen,nearest=nil,math.huge
			for _,foe in targets(actor,5,true) do
				local delta=foe.position-actor.position
				local forward=delta:Dot(action.direction)
				local lateral=(Vector3.new(delta.X,0,delta.Z)-action.direction*forward).Magnitude
				if forward>=0 and lateral<=1.5 and forward<nearest then chosen,nearest=foe,forward end
			end
			return chosen
		end
		-- A skipped movement frame stops safely; never catch up by teleporting.
		local wanted=math.min(10,math.max(0,elapsed-.2)*(10/.3))
		local budget=math.min(wanted-action.distance,2)
		while budget>.001 and not action.struck do
			local foe=firstInPath()
			if foe then
				contact(action,foe,1,action.tier.spear,5,true)
				action.struck=true;break
			end
			local length=math.min(.5,budget)
			local movement=action.direction*length
			local filter=RaycastParams.new()
			filter.FilterType=Enum.RaycastFilterType.Exclude
			filter.FilterDescendantsInstances={action.rig}
			filter.RespectCanCollide=true
			local obstruction=space:Blockcast(action.root.CFrame,Vector3.new(2,2,1.5),movement,filter)
			if obstruction then action.struck=true;break end
			local point=action.root.Position+movement
			local floor=space:Raycast(point+Vector3.new(0,1,0),Vector3.new(0,-8,0),filter)
			if not floor or floor.Normal.Y<.7 then action.struck=true;break end
			local clearance=action.humanoid.HipHeight+action.root.Size.Y/2
			if action.humanoid.RigType==Enum.HumanoidRigType.R6 then clearance+=2 end
			point=Vector3.new(point.X,floor.Position.Y+clearance,point.Z)
			if math.abs(point.Y-action.root.Position.Y)>1 or not Rules.containsArena(arena,point) then action.struck=true;break end
			action.root.CFrame=CFrame.lookAt(point,point+action.direction)
			action.root.AssemblyLinearVelocity=Vector3.zero
			action.distance+=length;budget-=length
			actor=combat:actor(action.rig)
			if not actor then return end
		end
		if not action.struck then
			local foe=firstInPath()
			if foe then contact(action,foe,1,action.tier.spear,5,true);action.struck=true end
		end
	end
	function controller:step()
		local time=now()
		for rig,action in actions do
			local elapsed=time-action.startedAt
			if not valid(action) or elapsed>=Config.families[action.family].duration then self:cancel(rig);continue end
			action.humanoid:Move(Vector3.zero);action.humanoid.Jump=false
			if action.family=="spear" then
				if elapsed>=.2 and elapsed<=.5 and time-action.lastAt<.15 then dash(action,elapsed) end
			elseif action.family=="axe" then
				if elapsed>=.25 and not action.struck then
					action.struck=true
					local actor=combat:actor(rig)
					for index,victim in targets(actor,6,false) do
						if index>3 then break end
						contact(action,victim,1,action.tier.axe,6,false)
					end
				end
			else
				if elapsed>=.2 and not action.first then
					action.first=true
					action.firstAt=time
					if action.target then contact(action,action.target,1,action.tier.sword,5,true) end
				end
				if elapsed>=.55 and not action.second and time>=(action.firstAt or time)+.35-.00001 then
					action.second=true
					if action.target then contact(action,action.target,2,action.tier.second,5,true) end
				end
			end
			action.lastAt=time
		end
	end
	function controller:plan(rig)
		local action=actions[rig]
		if not action then return nil end
		local definition=Config.families[action.family]
		return {phase="skill",state="Fighting",speed=0,phaseStartedAt=rig:GetAttribute("WeaponSkillStartedAt"),
			phaseDuration=definition.duration,attackStartedAt=rig:GetAttribute("WeaponSkillStartedAt")}
	end
	function controller:destroy()
		alive=false
		if worldConnection then worldConnection:Disconnect();worldConnection=nil end
		local rigs={};for rig in actions do table.insert(rigs,rig) end
		for _,rig in rigs do self:cancel(rig) end
		table.clear(deadlines);table.clear(ordinary)
	end
	if typeof(world.model)=="Instance" then
		worldConnection=world.model.AncestryChanged:Connect(function()
			if not world.model:IsDescendantOf(workspace) then controller:destroy() end
		end)
	end
	return controller
end
return Skills

--!strict

-- Shared adapter: encounter decisions remain server-owned; navigation owns physics.
local Motion={}
local attributes={phase="CombatPhase",phaseStartedAt="CombatPhaseStartedAt",phaseDuration="CombatPhaseDuration",
	attackStartedAt="AttackStartedAt",lastAttackAt="LastAttackAt",lastContactAt="LastContactAt"}

function Motion.publish(rig,result)
	for field,name in attributes do
		local value=result[field]
		if rig:GetAttribute(name)~=value then rig:SetAttribute(name,value)end
	end
	if result.state and rig:GetAttribute("WarriorState")~=result.state then rig:SetAttribute("WarriorState",result.state)end
end

function Motion.clear(rig)
	for _,name in {"CombatPhaseStartedAt","CombatPhaseDuration","AttackStartedAt"}do rig:SetAttribute(name,nil)end
	rig:SetAttribute("CombatPhase","idle")
	rig.Humanoid.AutoRotate=true
end

function Motion.apply(rig,navigator,world,result,now)
	Motion.publish(rig,result)
	local humanoid,root=rig.Humanoid,rig.HumanoidRootPart
	local skillActive=result.phase=="skill" or rig:GetAttribute("WeaponSkillActive")~=nil
	local speed=if skillActive then 0 else result.speed or 12
	if result.goal and result.direct and rig:GetAttribute("WarriorClass")~="ranged"
		and rig:GetAttribute("WarriorClass")~="medic" and (result.goal-root.Position).Magnitude<8 then speed=math.min(speed,6)end
	humanoid.WalkSpeed=speed

	local face=not skillActive and result.facing and (result.phase~="idle" or not result.goal or result.direct)
	humanoid.AutoRotate=not (skillActive or face)
	if face then
		local point=Vector3.new(result.facing.X,root.Position.Y,result.facing.Z)
		if (point-root.Position).Magnitude>.01 then root.CFrame=CFrame.lookAt(root.Position,point)end
	end
	-- Root facing changes cancel Humanoid MoveTo, so issue movement last.
	if not skillActive and result.goal and (result.phase=="idle" or (result.phase=="recovery" and result.footwork)) then
		if not result.direct or not navigator:walkCombat(result.goal,world,result.allowsDetour)then
			navigator:setGoal(result.goal,result.allowsDetour);navigator:step(now)
		end
	else navigator:stop()end
end

return Motion

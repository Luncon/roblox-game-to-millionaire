--!strict
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Shield={}

-- A life receives charges once. Equipment rebuilds reuse these server attributes.
function Shield.refresh(rig,civilizationId,kind,state)
 local eligible=civilizationId==Config.civilization and (kind=='warrior' or kind=='player') and state and state.shieldLevel==1
 local remaining=rig:GetAttribute('SpartanShieldRemaining')
 if eligible and remaining==nil then
  remaining=Config.shieldHits;rig:SetAttribute('SpartanShieldRemaining',remaining)
 end
 rig:SetAttribute('ShieldCharges',if eligible then remaining else 0)
 return eligible==true
end

-- Called only after hostility, life, range, sight and cadence validation.
function Shield.block(target,source)
 local charges=target.rig:GetAttribute('ShieldCharges') or 0
 if charges<=0 then return false end
 local delta=source-target.position
 delta=Vector3.new(delta.X,0,delta.Z)
 local facing=target.root.CFrame.LookVector
 facing=Vector3.new(facing.X,0,facing.Z)
 if delta.Magnitude<.01 or facing.Magnitude<.01 or facing.Unit:Dot(delta.Unit)<Config.shieldFrontDot then return false end
 target.rig:SetAttribute('ShieldCharges',charges-1)
 target.rig:SetAttribute('SpartanShieldRemaining',charges-1)
 target.rig:SetAttribute('ShieldBlockedAt',workspace:GetServerTimeNow())
 if charges==1 then
  for _,item in target.rig:GetDescendants()do if item:GetAttribute('CombatShield')==true then item:Destroy()end end
 end
 return true
end
return Shield

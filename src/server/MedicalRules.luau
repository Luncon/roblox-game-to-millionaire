--!strict
-- Callers obtain fresh registered actors and writable authority from CombatService.
local Medical={}
local kinds={warrior=true,ranged=true,medic=true}
function Medical.patient(actor,ownerId,state): boolean
 return actor~=nil and actor.alive==true and actor.claimed==true and not actor.neutral
  and actor.ownerId==ownerId and kinds[actor.kind]==true and state~=nil and state.hospitalLevel==1
  and actor.humanoid~=nil and actor.humanoid.Health>0 and actor.humanoid.Health<actor.humanoid.MaxHealth
end
function Medical.apply(actor,life,amount): number
 if not actor or actor.humanoid~=life or life.Health<=0 or amount<=0 then return 0 end
 local before=life.Health
 life.Health=math.min(life.MaxHealth,before+amount)
 return life.Health-before
end
local function key(actor): string
 return tostring(actor.rig:GetAttribute("ArmySlot") or actor.kind)
end
function Medical.choose(source,actors,state,range,eligible)
 local best,bestFraction,bestDeficit,bestDistance,bestKey=nil,math.huge,-1,math.huge,""
 for _,a in actors do
  if a.rig==source.rig or not Medical.patient(a,source.ownerId,state)
   or a.civilizationId~=source.civilizationId or a.plotId~=source.plotId then continue end
  local distance=(a.position-source.position).Magnitude
  if distance>range or (eligible and not eligible(a)) then continue end
  local fraction=a.humanoid.Health/a.humanoid.MaxHealth
  local deficit=a.humanoid.MaxHealth-a.humanoid.Health
  local stable=key(a)
  if fraction<bestFraction or (fraction==bestFraction and (deficit>bestDeficit
   or (deficit==bestDeficit and (distance<bestDistance or (distance==bestDistance and stable<bestKey))))) then
   best,bestFraction,bestDeficit,bestDistance,bestKey=a,fraction,deficit,distance,stable
  end
 end
 return best
end
function Medical.nearest(source,actors,state,from,to,radius,eligible)
 local best,point,bestDistance,bestKey=nil,nil,radius,""
 local delta=to-from
 for _,a in actors do
  if a.rig==source.rig or not Medical.patient(a,source.ownerId,state)
   or a.civilizationId~=source.civilizationId or a.plotId~=source.plotId then continue end
  local center=a.position+Vector3.new(0,1,0)
  local t=if delta.Magnitude>.001 then math.clamp((center-from):Dot(delta)/delta:Dot(delta),0,1) else 0
  local contact=from+delta*t
  local distance=(center-contact).Magnitude
  local stable=key(a)
  if distance>radius or (eligible and not eligible(a,contact)) then continue end
  if not best or distance<bestDistance or (distance==bestDistance and stable<bestKey) then
   best,point,bestDistance,bestKey=a,contact,distance,stable
  end
 end
 return best,point
end
return table.freeze(Medical)

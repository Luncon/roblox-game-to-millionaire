--!strict
local Config=require(game:GetService("ReplicatedStorage").Shared.MedicalConfig)
local Tactics=require(script.Parent.CombatTactics)
local Rules=require(script.Parent.CombatRules)
local Recovery={}

function Recovery.step(record,fighter,actors,order,state,safe,visible)
 if record.life~=fighter.humanoid then record.life=fighter.humanoid;record.active=nil end
 local fraction=fighter.humanoid.Health/fighter.humanoid.MaxHealth
 if order~="advance" or not state or state.hospitalLevel~=1 or not fighter.alive or fraction<=0
  or fraction>=Config.resumeFraction or (fighter.kind~="warrior" and fighter.kind~="ranged") then
  record.active=nil;return nil
 end
 local medic,distance=nil,math.huge
 for _,a in actors do
  if a.kind~="medic" or not a.alive or not a.claimed or a.neutral or a.humanoid.Health<=0
   or a.ownerId~=fighter.ownerId or a.civilizationId~=fighter.civilizationId or a.plotId~=fighter.plotId then continue end
  local d=Tactics.flatDistance(a.position,fighter.position)
  if d<distance then medic,distance=a,d end
 end
 if not medic then record.active=nil;return nil end
 if fraction<=Config.criticalFraction then record.active=true end
 if not record.active then return nil end
 local plan={phase="idle",state="Seeking medic",speed=12,goal=nil,direct=false}
 if distance<=Config.recoveryDistance and visible(medic,fighter) then plan.state="Recovering";return plan end
 local away=Tactics.away(fighter,medic)
 local bestDistance=math.huge
 for _,angle in {0,math.pi/4,-math.pi/4,math.pi/2,-math.pi/2,math.pi*3/4,-math.pi*3/4,math.pi}do
  local c,s=math.cos(angle),math.sin(angle)
  local direction=Vector3.new(away.X*c-away.Z*s,0,away.X*s+away.Z*c)
  local point=safe(medic.position+direction*Config.recoveryDistance,true,true)
  if not point then continue end
  local clear=true
  for _,enemy in actors do
   if Rules.hostile(fighter,enemy) and math.abs(enemy.position.Y-point.Y)<8
    and Tactics.flatDistance(point,enemy.position)<12 then clear=false;break end
  end
  if not clear then continue end
  local patient=table.clone(fighter);patient.position=point
  if not visible(medic,patient) then continue end
  local d=Tactics.flatDistance(point,fighter.position)
  if d<bestDistance then bestDistance,plan.goal=d,point end
 end
 return plan
end
return table.freeze(Recovery)

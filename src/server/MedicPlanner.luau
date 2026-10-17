--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Tuning=require(Shared.TacticalCombatConfig)
local Tactics=require(script.Parent.CombatTactics)
local Rules=require(script.Parent.CombatRules)
local Planner={}
function Planner.step(record,medic,actors,order,home,forward,now,safe)
 local plan={phase="idle",state="Supporting",speed=12,goal=nil,direct=false}
 if order=="hold" then plan.state="Holding";return plan end
 local threat,distance=nil,math.huge
 local center,count=Vector3.zero,0
 for _,a in actors do
  if Rules.hostile(medic,a) then
   local d=Tactics.flatDistance(medic.position,a.position)
   if d<distance and math.abs(a.position.Y-medic.position.Y)<8 then threat,distance=a,d end
  elseif a.ownerId==medic.ownerId and a.rig~=medic.rig and (a.kind=="warrior" or a.kind=="ranged") then
   center+=a.position;count+=1
  end
 end
 if distance>=Tuning.retreatSafe then record.origin,record.began=nil,nil end
 if threat and (distance<Tuning.retreatTrigger or record.origin~=nil) then
  if not record.origin then record.origin,record.began=medic.position,now end
  plan.state,plan.retreat,plan.speed="Retreating",true,Tuning.retreatSpeed
  if now-record.began<Tuning.retreatDuration then
   local best=distance
   for _,point in Tactics.rangedPoints(medic,threat,true) do
    if Tactics.flatDistance(point,record.origin)>Tuning.retreatLimit then continue end
    local candidate=safe(point,true)
    if not candidate then continue end
    local closest=math.huge
    for _,a in actors do if Rules.hostile(medic,a) then closest=math.min(closest,Tactics.flatDistance(candidate,a.position)) end end
    if closest>best then best=closest;plan.goal=candidate end
   end
  end
  return plan
 end
 local goal=home
 if count>0 then
  center/=count
  local nearest,nearestDistance=nil,120
  for _,a in actors do if Rules.hostile(medic,a) then
   local d=Tactics.flatDistance(center,a.position)
   if d<nearestDistance then nearest,nearestDistance=a,d end
  end end
  local delta=if nearest then nearest.position-center else forward
  delta=Vector3.new(delta.X,0,delta.Z)
  if delta.Magnitude>.01 then forward=delta.Unit end
  goal=center-forward*12
 end
 local candidate=safe(goal,false)
 if candidate and Tactics.flatDistance(candidate,medic.position)>2 then plan.goal=candidate end
 -- Keep a minimum separation without changing fighter reservations.
 if not plan.goal then
  for _,point in Tactics.separationPoints(medic,actors)do
   local candidatePoint=safe(point,false)
   if candidatePoint then plan.goal=candidatePoint;break end
  end
 end
 return plan
end
return table.freeze(Planner)

--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Tuning=require(Shared.TacticalCombatConfig)
local Tactics=require(script.Parent.CombatTactics)
local Rules=require(script.Parent.CombatRules)
local Medical=require(script.Parent.MedicalRules)
local Config=require(Shared.MedicalConfig)
local Planner={}

local function approach(medic,patient,actors,safe,visible)
 local away=Tactics.away(medic,patient)
 local best,bestDistance=nil,math.huge
 for _,angle in {0,math.pi/4,-math.pi/4,math.pi/2,-math.pi/2,math.pi*3/4,-math.pi*3/4,math.pi}do
  local c,s=math.cos(angle),math.sin(angle)
  local direction=Vector3.new(away.X*c-away.Z*s,0,away.X*s+away.Z*c)
  local point=safe(patient.position+direction*Config.supportDistance,false)
  if not point or (point-patient.position).Magnitude>Config.range then continue end
  local leg=Vector3.new(point.X-medic.position.X,0,point.Z-medic.position.Z)
  local clear=true
  for _,enemy in actors do
   if not Rules.hostile(medic,enemy) or math.abs(enemy.position.Y-point.Y)>=8 then continue end
   local delta=Vector3.new(enemy.position.X-medic.position.X,0,enemy.position.Z-medic.position.Z)
   local t=if leg.Magnitude>.01 then math.clamp(delta:Dot(leg)/leg:Dot(leg),0,1) else 0
   if Tactics.flatDistance(point,enemy.position)<Tuning.retreatSafe or (delta-leg*t).Magnitude<Tuning.retreatTrigger then
    clear=false;break
   end
  end
  if not clear then continue end
  local from=table.clone(medic);from.position=point
  if not visible(from,patient) then continue end
  local distance=Tactics.flatDistance(point,medic.position)
  if distance<bestDistance then best,bestDistance=point,distance end
 end
 return best
end

function Planner.step(record,medic,actors,order,home,forward,now,safe,state,visible,reinforcementHome,battlefieldCenter)
 local plan={phase="idle",state="Supporting",speed=12,goal=nil,direct=false}
 if order=="hold" then plan.state="Holding";return plan end
 local threat,distance=nil,math.huge
 local front,frontDistance,frontKey=nil,math.huge,""
 local friendDistance=math.huge
 local center=battlefieldCenter or home+forward*45
 for _,a in actors do
  if Rules.hostile(medic,a) then
   local d=Tactics.flatDistance(medic.position,a.position)
   if d<distance and math.abs(a.position.Y-medic.position.Y)<8 then threat,distance=a,d end
  elseif a.ownerId==medic.ownerId and a.civilizationId==medic.civilizationId and a.plotId==medic.plotId
   and a.alive and a.claimed and a.rig~=medic.rig and (a.kind=="warrior" or a.kind=="ranged") then
   friendDistance=math.min(friendDistance,Tactics.flatDistance(medic.position,a.position))
   local d=Tactics.flatDistance(a.position,center)
   local key=tostring(a.rig:GetAttribute("ArmySlot") or a.kind)
   if d<frontDistance or (d==frontDistance and key<frontKey) then front,frontDistance,frontKey=a,d,key end
  end
 end
 if distance>=Tuning.retreatSafe then record.origin,record.began=nil,nil end
 if threat and friendDistance<=Config.escortRange and (distance<Tuning.retreatTrigger or record.origin~=nil) then
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
 -- Stay useful when replacements are still far behind the fighting army.
 -- A patient already in range needs healing, not another backline position.
 local patient=Medical.choose(medic,actors,state,Config.range,function(a)return visible(medic,a)end)
 if patient then
  plan.patient,plan.facing,plan.state=patient,patient.position,"Healing"
  return plan
 end
 local goals={}
 patient=Medical.choose(medic,actors,state,math.huge,function(a)
  goals[a.rig]=approach(medic,a,actors,safe,visible)
  return goals[a.rig]~=nil
 end)
 if patient then
  plan.patient,plan.facing,plan.state=patient,patient.position,"Seeking patient"
  plan.goal=goals[patient.rig]
  return plan
 end
 local goal=reinforcementHome or home
 if front then
  goal=front.position-forward*12
  plan.following,plan.state=front,"Following front troop"
 else plan.state="Returning to barracks" end
 local candidate=safe(goal,false,true)
 if candidate and Tactics.flatDistance(candidate,medic.position)>2 then
  plan.goal=candidate
  plan.direct=Tactics.flatDistance(candidate,medic.position)<=Tuning.closeDistance
 end
 -- Follow a distant replacement without a second withdrawal mode or timeout.
 if threat and distance<Tuning.retreatTrigger and friendDistance>Config.escortRange and plan.goal then
  plan.retreat=true
  if (plan.goal-medic.position):Dot(threat.position-medic.position)>0 then
   local best=-math.huge
   for _,point in Tactics.rangedPoints(medic,threat,true)do
    local escape=safe(point,true,true)
    if not escape then continue end
    local gap=Tactics.flatDistance(escape,threat.position)
    local score=gap-Tactics.flatDistance(escape,goal)*.1
    if gap>distance and score>best then best,plan.goal=score,escape end
   end
  end
 end
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

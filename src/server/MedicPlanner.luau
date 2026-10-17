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

function Planner.step(record,medic,actors,order,home,forward,now,safe,state,visible,reinforcementHome)
 local plan={phase="idle",state="Supporting",speed=12,goal=nil,direct=false}
 if order=="hold" then plan.state="Holding";return plan end
 local threat,distance=nil,math.huge
 local center,count=Vector3.zero,0
 local nearestFriend,friendDistance=nil,math.huge
 for _,a in actors do
  if Rules.hostile(medic,a) then
   local d=Tactics.flatDistance(medic.position,a.position)
   if d<distance and math.abs(a.position.Y-medic.position.Y)<8 then threat,distance=a,d end
  elseif a.ownerId==medic.ownerId and a.civilizationId==medic.civilizationId and a.plotId==medic.plotId
   and a.alive and a.claimed and a.rig~=medic.rig and (a.kind=="warrior" or a.kind=="ranged") then
   center+=a.position;count+=1
   local d=Tactics.flatDistance(medic.position,a.position)
   if d<friendDistance then nearestFriend,friendDistance=a,d end
  end
 end
 if friendDistance<=Config.rejoinRange then record.withdrawing=nil end
 if friendDistance>Config.escortRange or record.withdrawing then
  record.withdrawing=true;record.origin,record.began=nil,nil
  plan.state,plan.retreat,plan.withdrawing="Withdrawing to reinforcements",true,true
  local destination=reinforcementHome or home
  if nearestFriend then destination=nearestFriend.position+Tactics.away(medic,nearestFriend)*12 end
  local candidate=safe(destination,true,true) or safe(reinforcementHome or home,true,true)
  if candidate and Tactics.flatDistance(candidate,medic.position)>3 then
   plan.goal=candidate
   -- Detour around pressure in front of the homeward route; no burst timeout.
   if threat and distance<Tuning.retreatTrigger and (candidate-medic.position):Dot(threat.position-medic.position)>0 then
    local best=-math.huge
    for _,point in Tactics.rangedPoints(medic,threat,true)do
     local escape=safe(point,true,true)
     if not escape then continue end
     local gap=Tactics.flatDistance(escape,threat.position)
     local score=gap-Tactics.flatDistance(escape,candidate)*.1
     if gap>distance and score>best then best=score;plan.goal=escape end
    end
   end
  else plan.state="Waiting for reinforcements" end
  return plan
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
 local candidate=safe(goal,false,true) or safe(home,false)
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

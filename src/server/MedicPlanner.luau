--!strict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.MedicalConfig)
local Tuning=require(Shared.TacticalCombatConfig)
local Tactics=require(script.Parent.CombatTactics)
local Rules=require(script.Parent.CombatRules)
local Planner={}
local angles={0,math.pi/4,-math.pi/4,math.pi/2,-math.pi/2,math.pi*3/4,-math.pi*3/4,math.pi}

-- Only actual enemies can justify a backward step. No escort, retreat clock,
-- reinforcement destination or patient-chasing state participates in movement.
function Planner.step(medic,actors,order,battlefield,forward,onField,safe,insideBattlefield: (Vector3) -> boolean)
 local plan={phase="idle",state="Supporting troops",speed=12,goal=nil,direct=false}
 if order=="hold" then plan.state="Holding";return plan end
 if order=="regroup" then plan.state="Regrouping";return plan end
 local center,count=Vector3.zero,0
 local fighters={}
 local enemies={}
 local nearest=math.huge
 for _,a in actors do
  if Rules.hostile(medic,a) and math.abs(a.position.Y-medic.position.Y)<8 then
   table.insert(enemies,a);nearest=math.min(nearest,Tactics.flatDistance(a.position,medic.position))
  elseif a.rig~=medic.rig and a.alive and a.claimed and not a.neutral and a.humanoid and a.humanoid.Health>0
   and a.ownerId==medic.ownerId and a.civilizationId==medic.civilizationId and a.plotId==medic.plotId
   and (a.kind=="warrior" or a.kind=="ranged") and insideBattlefield(a.position) then
   center+=a.position;count+=1;table.insert(fighters,a)
  end
 end
 local function setGoal(p)
  if p and Tactics.flatDistance(p,medic.position)>2 then
   plan.goal=p;plan.direct=Tactics.flatDistance(p,medic.position)<=Tuning.closeDistance
  end
 end
 if nearest<Config.avoidRange then
  plan.state,plan.avoiding="Avoiding enemies",true
  local best=nearest
  for _,angle in angles do
   local p=safe(medic.position+Vector3.new(math.cos(angle),0,math.sin(angle))*Config.avoidStep,true,true)
   if not p then continue end
   local gap=math.huge
   for _,enemy in enemies do gap=math.min(gap,Tactics.flatDistance(p,enemy.position)) end
   if gap>best+.01 then best=gap;plan.goal=p end
  end
  setGoal(plan.goal)
  return plan
 end
 local desired=battlefield
 if onField and count>0 then
  center/=count;plan.centroid=center;desired=center
 else plan.state="Advancing to battlefield" end
 -- Project any rearward centroid onto the medic's current advance plane.
 local delta=desired-medic.position
 local backward=Vector3.new(delta.X,0,delta.Z):Dot(forward)
 if backward<0 then desired-=forward*backward end
 if Tactics.flatDistance(desired,medic.position)<=Config.supportSpacing then return plan end
 local function clear(point)
  local leg=Vector3.new(point.X-medic.position.X,0,point.Z-medic.position.Z)
  if leg.Magnitude>Tuning.closeDistance then leg=leg.Unit*Tuning.closeDistance end
  for _,enemy in enemies do
   local d=Vector3.new(enemy.position.X-medic.position.X,0,enemy.position.Z-medic.position.Z)
   local t=if leg.Magnitude>.01 then math.clamp(d:Dot(leg)/leg:Dot(leg),0,1) else 0
   if (d-leg*t).Magnitude<Config.avoidRange then return false end
  end
  return true
 end
 local bestDistance=math.huge
 local bestCoverage=-1
 local function consider(point)
  if (point-medic.position):Dot(forward)<-.01 then return end
  local p=safe(point,false,false)
  if not p or not clear(p) then return end
  local distance=Tactics.flatDistance(p,medic.position)
  local coverage=0
  if onField then
   for _,f in fighters do if (p-f.position).Magnitude<=Config.range then coverage+=1 end end
  end
  if coverage>bestCoverage or (coverage==bestCoverage and distance<bestDistance) then
   bestCoverage,bestDistance=coverage,distance;setGoal(p)
  end
 end
 if not onField then consider(desired);if plan.goal then return plan end end
 local away=medic.position-desired;away=Vector3.new(away.X,0,away.Z).Unit
 for _,angle in angles do
  local c,s=math.cos(angle),math.sin(angle)
  consider(desired+Vector3.new(away.X*c-away.Z*s,0,away.X*s+away.Z*c)*Config.supportSpacing)
 end
 return plan
end
return table.freeze(Planner)

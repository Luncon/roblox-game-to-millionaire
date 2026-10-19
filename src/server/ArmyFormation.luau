--!strict
-- Pure formation decisions. WarriorService supplies only authoritative current lives.
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
local F={}
local function flat(v)return Vector3.new(v.X,0,v.Z).Magnitude end

function F.facing(group,id)
 local angle=group.definition.facingAngles[id] or 0
 local right=Vector3.new(-group.heading.Z,0,group.heading.X)
 return group.heading*math.cos(angle)+right*math.sin(angle)
end

function F.ready(state,civilizationId,frame,actors)
 local definition=Config.forCivilization(civilizationId)
 if not definition or state.formationLevel~=1 or state.shieldLevel~=1
  or state.warCouncilLevel~=1 or state.armyCampLevel~=2 or state.hospitalLevel~=1 then return false,'formation_locked' end
 if state.selectedFormation~=definition.id then return false,'formation_unselected' end
 local count=0;for _ in actors do count+=1 end
 if count~=5 then return false,'formation_missing_troops' end
 for id,kind in Config.roles do
  local a=actors[id]
  if not a or not a.alive or not a.rig or not a.humanoid then return false,'formation_missing_troops' end
  if a.kind~=kind then return false,'formation_wrong_classes' end
  local point=frame:PointToObjectSpace(a.position)
  if not Camp.contains(point,1) or math.abs(point.Y-2.15)>5 then return false,'formation_outside_camp' end
 end
 return true
end

function F.new(anchor,destination,actors,definition)
 assert(definition and Config.byId[definition.id]==definition,'Known formation required')
 local direction=destination-anchor;direction=Vector3.new(direction.X,0,direction.Z)
 assert(direction.Magnitude>.01,'Formation needs a route')
 local members={};for id in Config.roles do
  members[id]={rig=actors[id].rig,humanoid=actors[id].humanoid}
 end
 return {definition=definition,anchor=anchor,destination=destination,heading=direction.Unit,members=members,phase='assembling'}
end

function F.goals(group,ground)
 local right=Vector3.new(-group.heading.Z,0,group.heading.X)
 local result={}
 for id in group.members do
  local offset=group.definition.offsets[id]
  result[id]=ground(group.anchor+right*offset.X-group.heading*offset.Z)
 end
 return result
end

-- canShoot supplies the server's ordinary hostility/life/arena/visibility checks.
function F.firingOpportunity(group,archer,actors,canShoot,range)
 local member=group.members.ranged
 if not group.definition.screenRange or not member or not archer or archer.rig~=member.rig then return false end
 for _,target in actors do
  if (target.position-archer.position).Magnitude<=(range or group.definition.screenRange) and canShoot(archer,target) then return true end
 end
 return false
end

-- canContact supplies ordinary server hostility/reach/arena/visibility/authority checks.
function F.contactOpportunity(group,members,actors,canContact)
 if not group.definition.breakOnMeleeContact or group.phase=='holding' then return false end
 for id,member in group.members do
  local frontline=members[id]
  if Config.roles[id]=='warrior' and frontline and frontline.alive and frontline.kind=='warrior'
   and frontline.rig==member.rig and frontline.humanoid==member.humanoid then
   for _,target in actors do if canContact(frontline,target)then return true end end
  end
 end
 return false
end

function F.step(group,actors,dt,allows,ground,hasShot,hasContact)
 for id,member in group.members do
  local a=actors[id]
  if not a or not a.alive or a.rig~=member.rig or a.humanoid~=member.humanoid then
   if Config.roles[id]=='warrior' then return nil,'frontline_lost' end
   -- Keep the surviving shield line; never capture a replacement support life.
   group.members[id]=nil
  end
 end
 -- A paused attack or lagging member must not prevent the wedge entering combat.
 if group.definition.breakOnMeleeContact and group.phase~='holding' and hasContact then return nil,'melee_contact' end
 local goals=F.goals(group,ground)
 local allArrived,coherent=true,true
 for id,goal in goals do
  local a=actors[id];local delta=a.position-goal
  if flat(delta)>Config.arrivalTolerance or math.abs(delta.Y)>5 then allArrived=false end
  if flat(delta)>Config.cohesionTolerance or math.abs(delta.Y)>5 or a.avoiding
   or (a.phase~='idle' and a.phase~='recovery') then coherent=false end
 end
 -- Positional tolerances alone can accept an inverted two-stud front arc.
 local front=actors.warrior.position
 local right=Vector3.new(-group.heading.Z,0,group.heading.X)
 local definition=group.definition
 local shape=(front-actors.camp.position):Dot(group.heading)>=definition.frontLeadMinimum
  and (front-actors.reinforcement.position):Dot(group.heading)>=definition.frontLeadMinimum
  and (front-actors.camp.position):Dot(right)>=3
  and (actors.reinforcement.position-front):Dot(right)>=3
 if definition.frontLeadMaximum then
  shape=shape and math.abs((front-actors.camp.position):Dot(group.heading))<=definition.frontLeadMaximum
   and math.abs((front-actors.reinforcement.position):Dot(group.heading))<=definition.frontLeadMaximum
 end
 for _,id in {'ranged','medic'}do
  if group.members[id] then shape=shape and (front-actors[id].position):Dot(group.heading)>=definition.supportDepthMinimum end
 end
 if group.members.ranged and group.members.medic then
  shape=shape and (actors.medic.position-actors.ranged.position):Dot(right)>=definition.supportSpacingMinimum
 end
 allArrived=allArrived and shape
 coherent=coherent and shape
 if group.phase=='assembling' then
  if allArrived then group.phase='marching' end
 elseif group.phase=='marching' and coherent then
  local remaining=flat(group.destination-group.anchor)
  if definition.screenRange and hasShot then group.phase='screening'
  elseif remaining<=.25 then group.phase=if definition.screenRange then 'screening' else 'deployed' else
   local previous=group.anchor
   local pace=Config.pace*(if group.slowApproach then definition.approachSpeedMultiplier or 1 else 1)
   group.anchor=ground(previous+group.heading*math.min(remaining,pace*math.clamp(dt,0,.25)))
   local nextGoals=F.goals(group,ground);local clear=true
   for id,point in nextGoals do if not allows(id,point)then clear=false;break end end
   if clear then goals=nextGoals else group.anchor=previous end
  end
 end
 if group.phase=='deployed' then return nil,'destination_reached' end
 return goals
end
return F

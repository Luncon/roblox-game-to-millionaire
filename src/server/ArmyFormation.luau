--!strict
-- Pure formation decisions. WarriorService supplies only authoritative current lives.
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
local F={}
local function flat(v)return Vector3.new(v.X,0,v.Z).Magnitude end

function F.ready(state,civilizationId,frame,actors)
 if civilizationId~=Config.civilization or state.formationLevel~=1 or state.shieldLevel~=1
  or state.warCouncilLevel~=1 or state.armyCampLevel~=2 or state.hospitalLevel~=1 then return false,'formation_locked' end
 if state.selectedFormation~=Config.id then return false,'formation_unselected' end
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

function F.new(anchor,destination,actors)
 local direction=destination-anchor;direction=Vector3.new(direction.X,0,direction.Z)
 assert(direction.Magnitude>.01,'Formation needs a route')
 local members={};for id in Config.roles do
  members[id]={rig=actors[id].rig,humanoid=actors[id].humanoid}
 end
 return {anchor=anchor,destination=destination,heading=direction.Unit,members=members,phase='assembling'}
end

function F.goals(group,ground)
 local right=Vector3.new(-group.heading.Z,0,group.heading.X)
 local result={}
 for id,offset in Config.offsets do result[id]=ground(group.anchor+right*offset.X-group.heading*offset.Z)end
 return result
end

function F.step(group,actors,dt,allows,ground)
 for id,member in group.members do
  local a=actors[id]
  if not a or not a.alive or a.rig~=member.rig or a.humanoid~=member.humanoid then return nil,'member_lost' end
 end
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
 local shape=(front-actors.camp.position):Dot(group.heading)>=.5
  and (front-actors.reinforcement.position):Dot(group.heading)>=.5
  and (front-actors.camp.position):Dot(right)>=3
  and (actors.reinforcement.position-front):Dot(right)>=3
  and (front-actors.ranged.position):Dot(group.heading)>=7
  and (front-actors.medic.position):Dot(group.heading)>=7
  and (actors.medic.position-actors.ranged.position):Dot(right)>=3
 allArrived=allArrived and shape
 coherent=coherent and shape
 if group.phase=='assembling' then
  if allArrived then group.phase='marching' end
 elseif group.phase=='marching' and coherent then
  local remaining=flat(group.destination-group.anchor)
  if remaining<=.25 then group.phase='deployed' else
   local previous=group.anchor
   group.anchor=ground(previous+group.heading*math.min(remaining,Config.pace*math.clamp(dt,0,.25)))
   local nextGoals=F.goals(group,ground);local clear=true
   for id,point in nextGoals do if not allows(id,point)then clear=false;break end end
   if clear then goals=nextGoals else group.anchor=previous end
  end
 end
 return goals
end
return F

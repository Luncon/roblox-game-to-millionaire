--!strict
-- Only captured archers coordinate. The caller supplies ordinary combat validation.
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Tactics=require(script.Parent.CombatTactics)
local Volley={}
local function archers(group,actors)
 local result={}
 for id,member in group.members do
  local actor=actors[id]
  if Config.rolesFor(group.definition)[id]=='ranged' and actor and actor.alive and actor.kind=='ranged'
   and actor.rig==member.rig and actor.humanoid==member.humanoid then table.insert(result,actor)end
 end
 return result
end

function Volley.choose(group,members,actors,canShoot,range)
 if not group.definition.volley then return nil end
 local shooters=archers(group,members)
 local function coverage(target)
  local count,distance=0,math.huge
  for _,archer in shooters do
   local d=(archer.position-target.position).Magnitude
   if d<=range and canShoot(archer,target)then count+=1;distance=math.min(distance,d)end
  end
  return count,distance
 end
 local previous=group.focus
 if previous then
  for _,target in actors do
   if target.rig==previous.rig and target.humanoid==previous.humanoid and coverage(target)>0 then return target end
  end
 end
 local best,bestCount,bestDistance,bestKey=nil,0,math.huge,''
 for _,target in actors do
  local count,distance=coverage(target)
  local key=Tactics.stableKey(target)
  if count>0 and (count>bestCount or (count==bestCount and (distance<bestDistance-.001
   or (math.abs(distance-bestDistance)<=.001 and key<bestKey))))then
   best,bestCount,bestDistance,bestKey=target,count,distance,key
  end
 end
 group.focus=if best then {rig=best.rig,humanoid=best.humanoid} else nil
 return best
end

function Volley.ready(group,now)
 return group.definition.volley==true and now>=(group.nextVolleyAt or 0)
end
function Volley.started(group,now)
 if not Volley.ready(group,now)then return false end
 group.nextVolleyAt=now+group.definition.shotSpacing
 return true
end
return Volley

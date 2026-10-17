--!strict
local Tactics=require(script.Parent.CombatTactics)
local Crowd={radius=3.2}
local worlds=setmetatable({}, {__mode="k"})
local function flat(v)return Vector3.new(v.X,0,v.Z)end

-- All bodies count equally, including stopped/held opponents. Test the next
-- half-second of travel; escape from an existing overlap must improve spacing.
function Crowd.choose(actor,neighbors,goal,speed,safe)
 local delta=flat(goal-actor.position)
 if delta.Magnitude<.1 then return goal end
 local length=math.min(delta.Magnitude,math.max(3.5,speed*.45))
 local direction=delta.Unit
 local function clear(point)
  local leg=flat(point-actor.position)
  for _,other in neighbors do
   if math.abs(other.position.Y-actor.position.Y)>=4 then continue end
   local offset=flat(other.position-actor.position)
   local start=offset.Magnitude
   if start>length+Crowd.radius+3 then continue end
   local velocity=flat(other.velocity or Vector3.zero)
   -- A short prediction prevents two crossing movers selecting the same gap.
   local relative=leg-velocity*math.min(.35,length/math.max(speed,1))
   local t=if relative.Magnitude>.01 then math.clamp(offset:Dot(relative)/relative:Dot(relative),0,1) else 0
   if (offset-relative*t).Magnitude<math.min(start,Crowd.radius)-.02 then return false end
   if start<Crowd.radius and (offset-leg).Magnitude<start+.2 then return false end
  end
  return true
 end
 local crowded
 for _,other in neighbors do
  if math.abs(other.position.Y-actor.position.Y)<4 and flat(other.position-actor.position).Magnitude<Crowd.radius then
   if not crowded or Tactics.stableKey(other)<Tactics.stableKey(crowded) then crowded=other end
  end
 end
 if crowded then
  local away=Tactics.away(actor,crowded)
  local p=safe(actor.position+away*3.5)
  if p and clear(p) then return p end
 end
 if clear(actor.position+direction*length) then return goal end
 for _,angle in {math.pi/4,math.pi/3,math.pi/2,-math.pi/4,-math.pi/3,-math.pi/2,math.pi*3/4,-math.pi*3/4} do
  local c,s=math.cos(angle),math.sin(angle)
  local heading=Vector3.new(direction.X*c-direction.Z*s,0,direction.X*s+direction.Z*c)
  local point=safe(actor.position+heading*length)
  if point and clear(point) then return point end
 end
 return nil
end

function Crowd.forWorld(model)
 if worlds[model] then return worlds[model] end
 local controller={records={}}
 worlds[model]=controller
 function controller:register(rig,isActive)
  self.records[rig]={rig=rig,root=rig.HumanoidRootPart,humanoid=rig.Humanoid,active=isActive,
   ownerId=rig:GetAttribute("OwnerId"),kind=rig:GetAttribute("WarriorClass")}
 end
 function controller:halt(rig)
  local record=self.records[rig]
  if record then record.goal=nil;record.detour=nil end
 end
 function controller:forget(rig)self.records[rig]=nil end
 function controller:move(rig,destination,goal,now,safe)
  local actor=self.records[rig]
  if not actor then return destination end
  local neighbors={}
  if actor.goal and flat(actor.goal-goal).Magnitude>3 then actor.detour=nil end
  actor.position=actor.root.Position;actor.goal=goal
  for otherRig,other in self.records do
   if not otherRig.Parent or not other.root.Parent or other.humanoid.Health<=0 then self.records[otherRig]=nil;continue end
   if otherRig==rig then continue end
   if not other.active() then other.goal=nil end
   other.position=other.root.Position;other.velocity=other.root.AssemblyLinearVelocity
   table.insert(neighbors,other)
  end
  -- Reserve nearby destinations. The closer arrival wins; equal arrivals use
  -- stable identity so both troops cannot repeatedly yield to one another.
  for _,other in neighbors do
   if other.goal and math.abs(other.position.Y-actor.position.Y)<4 and flat(other.goal-goal).Magnitude<1 and flat(actor.position-goal).Magnitude<8 then
    local mine,theirs=flat(actor.position-goal).Magnitude,flat(other.position-goal).Magnitude
    if theirs<mine-1 or (math.abs(theirs-mine)<=1 and Tactics.stableKey(other)<Tactics.stableKey(actor)) then
     return nil
    end
   end
  end
  if actor.detour and now<actor.detourUntil and flat(actor.position-actor.detour).Magnitude>.7 then
   local p=safe(actor.detour)
   if p and Crowd.choose(actor,neighbors,p,actor.humanoid.WalkSpeed,safe)==p then return p end
  end
  local point=Crowd.choose(actor,neighbors,destination,actor.humanoid.WalkSpeed,safe)
  if point and point~=destination then actor.detour=point;actor.detourUntil=now+.4 else actor.detour=nil end
  return point
 end
 return controller
end
return Crowd

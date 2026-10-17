--!strict
local Tactics=require(script.Parent.CombatTactics)
local Footwork={}
local function random(state,actor)
 if not state.seed then
  state.seed=17
  local key=Tactics.stableKey(actor)
  for i=1,#key do state.seed=(state.seed*31+string.byte(key,i))%65521 end
 end
 state.seed=(state.seed*25173+13849)%65521
 return state.seed/65521
end
local function flat(v)return Vector3.new(v.X,0,v.Z)end
local function retained(state,actor,now,safe)
 if state.goal and now<state.untilAt and flat(state.goal-actor.position).Magnitude>.45 then
  local p=safe(state.goal)
  if p then return state.goal end
 end
 state.goal=nil
 return nil
end
function Footwork.idle(state,actor,anchor,now,safe)
 if state.mode~="idle" then state.mode="idle";state.goal=nil;state.nextAt=now+1.5+random(state,actor)*2 end
 local p=retained(state,actor,now,safe)
 if p then return p end
 if now<state.nextAt then return nil end
 state.nextAt=now+2+random(state,actor)*3
 local angle=random(state,actor)*math.pi*2
 local length=1+random(state,actor)
 p=safe(anchor+Vector3.new(math.cos(angle),0,math.sin(angle))*length)
 if p and flat(p-actor.position).Magnitude>.6 then state.goal=p;state.untilAt=now+1;return p end
 return nil
end
function Footwork.combat(state,actor,target,now,deadline,safe)
 if state.mode~="combat" or state.target~=target.rig then
  state.mode="combat";state.target=target.rig;state.goal=nil;state.nextAt=0
 end
 if deadline-now<.25 then state.goal=nil;return nil end
 local p=retained(state,actor,now,safe)
 if p then return p end
 if now<state.nextAt then return nil end
 state.nextAt=now+.8+random(state,actor)
 if random(state,actor)<.3 then return nil end
 state.side=state.side or (if random(state,actor)<.5 then -1 else 1)
 if random(state,actor)<.25 then state.side=-state.side end
 local away=Tactics.away(actor,target)
 local distance=flat(actor.position-target.position).Magnitude
 if actor.kind=="ranged" then
  if distance<18 or distance>35 or deadline-now<.5 then return nil end
  local side=Vector3.new(-away.Z,0,away.X)*state.side
  p=actor.position+side*(2+random(state,actor)*1.2)
 else
  if distance>5.5 then return nil end
  local angle=state.side*(.22+random(state,actor)*.2)
  local c,s=math.cos(angle),math.sin(angle)
  local radius=math.clamp(distance+(random(state,actor)-.5)*.6,3.5,4.5)
  p=target.position+Vector3.new(away.X*c-away.Z*s,0,away.X*s+away.Z*c)*radius
 end
 p=safe(p)
 if p then
  state.goal=p;state.untilAt=math.min(deadline-.2,now+(if actor.kind=="ranged" then .7 else .35))
  return p
 end
 return nil
end
return table.freeze(Footwork)

return function()
 local F=require(game.ServerScriptService.Game.TroopFootwork)
 local n=0
 local function test(name,fn)fn();n+=1;print("PASS: "..name)end
 local function actor(kind,x,z)
  return {rig={Name=kind,GetAttribute=function()return kind end},ownerId=1,kind=kind,position=Vector3.new(x,0,z)}
 end
 test("idle shuffles stay close to the assigned anchor with retained goals and varied pauses",function()
  local a=actor("warrior",0,0);local state={};local goals={};local count=0
  for tick=0,120 do
   local p=F.idle(state,a,Vector3.zero,tick*.2,function(p)return p end)
   if p then assert(p.Magnitude<=3.5);goals[tostring(p)]=true;count+=1 end
  end
  local unique=0;for _ in goals do unique+=1 end
  assert(count>0 and unique>=2)
 end)
 test("melee recovery steps stay in reach and keep one committed goal",function()
  local a=actor("warrior",4,0);local b=actor("enemy",0,0);local state={};local goals=0
  for cycle=1,25 do
   local now=cycle*2
   local p=F.combat(state,a,b,now,now+.5,function(p)return p end)
   if p then
    assert((p-b.position).Magnitude>=3.3 and (p-b.position).Magnitude<=4.7)
    assert((p-a.position).Magnitude<=2.5)
    assert(F.combat(state,a,b,now+.05,now+.5,function(p)return p end)==p)
    goals+=1
   end
  end
  assert(goals>5 and goals<25)
 end)
 test("ranged strafing stays near firing distance and rejects a blocked leg",function()
  local a=actor("ranged",28,0);local b=actor("enemy",0,0);local state={};local moved=false
  for cycle=1,10 do
   local now=cycle*3
   local p=F.combat(state,a,b,now,now+1,function(p)return p end)
   if p then assert(math.abs(p.Z)>=2 and math.abs(p.X-28)<.01);moved=true end
  end
  assert(moved)
  for tick=0,20 do assert(not F.combat({},a,b,tick,tick+1,function()return nil end)) end
 end)
 test("short recovery windows cannot begin a step that postpones the next attack",function()
  local a=actor("warrior",4,0);local b=actor("enemy",0,0)
  assert(not F.combat({},a,b,1,1.1,function(p)return p end))
 end)
 return n
end

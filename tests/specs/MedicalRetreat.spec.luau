return function()
 local Recovery=require(game.ServerScriptService.Game.MedicalRetreat)
 local n=0
 local function test(name,fn)fn();n+=1;print("PASS: "..name)end
 local function actor(kind,hp,x,owner)
  return {rig={},kind=kind,ownerId=owner or 1,civilizationId="sparta",plotId=1,claimed=true,alive=true,
   humanoid={Health=hp,MaxHealth=100},position=Vector3.new(x or 0,3,0)}
 end
 local state={hospitalLevel=1}
 local function step(r,f,actors,order,s,safe,visible)
  return Recovery.step(r,f,actors,order or "advance",s or state,safe or function(p)return p end,visible or function()return true end)
 end
 test("critical fighters seek a medic and wait within recovery range",function()
  local f,m=actor("warrior",25,60),actor("medic",100,0);local r={}
  local p=step(r,f,{f,m});assert(p and p.goal and math.abs(p.goal.X-20)<.001 and r.active)
  f.position=p.goal;p=step(r,f,{f,m});assert(p and not p.goal and p.state=="Recovering")
 end)
 test("recovery latches until sixty percent without oscillating at the critical threshold",function()
  local f,m=actor("ranged",20,60),actor("medic",100,0);local r={}
  assert(step(r,f,{f,m}));f.humanoid.Health=59;assert(step(r,f,{f,m}))
  f.humanoid.Health=60;assert(not step(r,f,{f,m}) and not r.active)
  f.humanoid.Health=40;assert(not step(r,f,{f,m}));f.humanoid.Health=25;assert(step(r,f,{f,m}))
 end)
 test("recovery respects commands hospital ownership and current medic life",function()
  local f,m=actor("warrior",20,60),actor("medic",100,0);local r={}
  assert(step(r,f,{f,m}));assert(not step(r,f,{f,m},"hold") and not r.active)
  assert(not step(r,f,{f,m},"regroup"));assert(not step(r,f,{f,m},nil,{hospitalLevel=0}))
  m.ownerId=2;assert(not step(r,f,{f,m}));m.ownerId=1;m.plotId=2;assert(not step(r,f,{f,m}))
  m.plotId=1;m.humanoid.Health=0;assert(not step(r,f,{f,m}));assert(not step(r,f,{f}))
 end)
 test("a respawned fighter cannot inherit its former life recovery latch",function()
  local f,m=actor("warrior",20,60),actor("medic",100,0);local r={}
  assert(step(r,f,{f,m}));f.humanoid={Health=40,MaxHealth=100}
  assert(not step(r,f,{f,m}) and not r.active)
 end)
 test("recovery avoids hostile endpoints and retries blocked routes without attacking",function()
  local f,m,e=actor("warrior",20,60),actor("medic",100,0),actor("warrior",100,20,2)
  local p=step({},f,{f,m,e});assert(p and p.goal and (p.goal-e.position).Magnitude>=12)
  p=step({},f,{f,m},nil,nil,function()return nil end);assert(p and not p.goal and p.phase=="idle")
  f.position=Vector3.new(10,3,0)
  p=step({},f,{f,m},nil,nil,nil,function()return false end);assert(p and p.state~="Recovering")
 end)
 return n
end

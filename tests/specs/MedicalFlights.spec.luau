-- Injected geometry and clocks prove authority/flight logic, not native collision.
return function()
 local Medical=require(game.ServerScriptService.Game.MedicalService)
 local n=0
 local function test(name,fn)fn();n+=1;print("PASS: "..name)end
 local function fixture()
  local time=0
  local states={[1]={hospitalLevel=1,trainingLevel=1},[2]={hospitalLevel=1,trainingLevel=1}}
  local actors={};local writable,active,visible=true,true,true
  local combat={}
  function combat:actor(rig)local a=actors[rig];return if a and a.humanoid.Health>0 then a else nil end
  function combat:canAct(rig)return writable and self:actor(rig)~=nil end
  function combat:visible(_,target)return visible and not target.blocked end
  function combat:actors()local list={};for _,a in actors do if a.humanoid.Health>0 then table.insert(list,a)end end;return list end
  local economy={get=function(_,id)return states[id]end,canMutate=function()return writable end}
  local function actor(kind,owner,hp,x)
   local rig={attrs={},Name=kind};function rig:GetAttribute(k)return self.attrs[k]end;function rig:SetAttribute(k,v)self.attrs[k]=v end
   local a={kind=kind,ownerId=owner,civilizationId="sparta",plotId=owner,alive=true,claimed=true,rig=rig,
    humanoid={Health=hp,MaxHealth=100},position=Vector3.new(x or 0,2.15,0),root={AssemblyLinearVelocity=Vector3.zero}}
   actors[rig]=a;return a
  end
  local source=actor("medic",1,100,0);local target=actor("warrior",1,50,12)
  local physics={mode="target",calls=0,maxHeight=0}
  function physics:Spherecast(origin,radius,delta)
   self.calls+=1;self.maxHeight=math.max(self.maxHeight,origin.Y+delta.Y)
   if self.mode=="blocked" then return {Instance={IsDescendantOf=function()return false end}} end
   if self.mode=="target" and (origin+delta-(target.position+Vector3.new(0,1,0))).Magnitude<1 then
    return {Instance={IsDescendantOf=function(_,rig)return rig==target.rig end}}
   end
   return nil
  end
  function physics:Raycast()return nil end
  local created={}
  local service=Medical.new({model={}},combat,economy,function()return active end,function()return time end,physics,function(origin)
   local part={Position=origin};function part:Destroy()self.destroyed=true end;table.insert(created,part);return part
  end)
  return {service=service,source=source,target=target,actors=actors,states=states,physics=physics,created=created,create=actor,
   step=function(t)time=t;service:step()end,setWritable=function(v)writable=v end,setActive=function(v)active=v end,setVisible=function(v)visible=v end,
   time=function(t)time=t end,list=function()local list={};for _,a in actors do table.insert(list,a)end;return list end}
 end
 local function run(fn)local f=fixture();local ok,msg=pcall(fn,f);f.service:destroy();assert(ok,msg)end
 test("bandage contacts once with an arc and clamps twelve health",function()run(function(f)
  assert(f.service:throw(f.source.rig,f.list()));assert(f.service:count()==1)
  f.step(.1);f.step(.2);assert(f.target.humanoid.Health==62 and f.service:count()==0)
  assert(f.physics.calls>1 and f.physics.maxHeight>5 and f.created[1].destroyed)
  f.step(.21);assert(f.target.humanoid.Health==62 and not f.service:throw(f.source.rig,f.list()))
 end)end)
 test("a blocked critical patient does not starve a visible wounded troop",function()run(function(f)
  f.target.humanoid.Health=10;f.target.blocked=true
  local visible=f.create("ranged",1,50,10)
  assert(f.service:throw(f.source.rig,{f.source,f.target,visible}))
  assert(f.source.rig.attrs.BandageTargetPosition==visible.position)
 end)end)
 test("stale lowest-health candidates do not starve current registered patients",function()run(function(f)
  local stale=f.create("warrior",1,1,8);f.actors[stale.rig]=nil
  assert(f.service:throw(f.source.rig,{f.source,stale,f.target}))
  assert(f.source.rig.attrs.BandageTargetPosition==f.target.position)
 end)end)
 test("a near miss heals only the closest eligible wounded launch life",function()run(function(f)
  local near=f.create("ranged",1,60,11);near.position+=Vector3.new(0,0,2)
  local far=f.create("warrior",1,10,12);far.position+=Vector3.new(0,0,4)
  assert(f.service:throw(f.source.rig,{f.source,f.target,near}))
  f.target.position=Vector3.new(40,2.15,0);f.physics.mode="miss"
  f.step(.1);f.step(.2)
  assert(near.humanoid.Health==72 and far.humanoid.Health==10 and f.target.humanoid.Health==50)
  assert(f.service:count()==0 and f.service:readyAt(1)==3)
 end)end)
 test("proximity healing cannot cross a wall or reach a replacement life",function()
  for _,reason in {"wall","life","foreign","distance"}do run(function(f)
   local near=f.create("ranged",1,60,11);near.position+=Vector3.new(0,0,2)
   assert(f.service:throw(f.source.rig,{f.source,f.target,near}))
   f.target.position=Vector3.new(40,2.15,0);f.physics.mode="miss"
   if reason=="wall" then function f.physics:Raycast()return {Instance={IsDescendantOf=function()return false end}}end
   elseif reason=="life"then near.humanoid={Health=60,MaxHealth=100}
   elseif reason=="foreign"then near.ownerId=2
   else near.position+=Vector3.new(0,0,3)end
   f.step(.1);f.step(.2);assert(near.humanoid.Health==60 and f.service:count()==0)
  end)end
 end)
 test("blocked missed moving or expired bandages consume their launch cooldown",function()
  for _,mode in {"blocked","miss","moving","stalled"}do run(function(f)
   assert(f.service:throw(f.source.rig,f.list()))
   if mode=="moving" then f.target.position=Vector3.new(40,2.15,0)
   elseif mode~="stalled" then
    f.physics.mode=mode
    if mode=="miss" then f.target.position+=Vector3.new(0,0,5)end
   end
   f.step(if mode=="stalled" then 2 else .2)
   assert(f.target.humanoid.Health==50 and f.service:count()==0)
   assert(f.service:readyAt(1)==3 and not f.service:throw(f.source.rig,f.list()))
  end)end
 end)
 test("cancel regroup death and replacements preserve owner slot cooldown",function()run(function(f)
  assert(f.service:throw(f.source.rig,f.list()));f.service:cancel(f.source.rig)
  local replacement=f.create("medic",1,100,0)
  assert(not f.service:throw(replacement.rig,f.list()));f.step(3)
  assert(f.service:throw(replacement.rig,f.list()));f.setActive(false);f.step(3.1)
  assert(f.service:count()==0 and f.target.humanoid.Health==50 and f.service:readyAt(1)==6)
 end)end)
 test("pending bandages reject life replacement owner switch lease loss and hospital loss",function()
  for _,reason in {"life","claim","lease","hospital","death","sourceLife","range"}do run(function(f)
   assert(f.service:throw(f.source.rig,f.list()))
   if reason=="life" then f.target.humanoid={Health=50,MaxHealth=100}
   elseif reason=="claim" then f.target.civilizationId="britain"
   elseif reason=="lease" then f.setWritable(false)
   elseif reason=="hospital" then f.states[1].hospitalLevel=0
   elseif reason=="death" then f.source.humanoid.Health=0
   elseif reason=="sourceLife" then f.source.humanoid={Health=100,MaxHealth=100}
   elseif reason=="range" then f.source.position=Vector3.new(-50,2.15,0) end
   f.step(.2);assert(f.target.humanoid.Health==50 and f.service:count()==0)
  end)end
 end)
 test("launch rejects players foreigners full health self wrong source and blocked sight",function()run(function(f)
  f.target.humanoid.Health=100
  for _,kind in {"player","farmer","medic"}do
   local a=f.create(kind,if kind=="medic" then 2 else 1,50,10)
   assert(not f.service:throw(f.source.rig,{f.source,a}))
  end
  f.target.humanoid.Health=50;f.setVisible(false);assert(not f.service:throw(f.source.rig,f.list()))
  f.setVisible(true);f.source.kind="warrior";assert(not f.service:throw(f.source.rig,f.list()))
  f.source.kind="medic";f.target.position=Vector3.new(46,2,0);assert(not f.service:throw(f.source.rig,f.list()))
  assert(f.service:readyAt(1)==0)
 end)end)
 test("yard recovery works without a living medic and never banks full or inactive time",function()run(function(f)
  local camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
  local frame={PointToObjectSpace=function(_,p)return p end}
  f.source.humanoid.Health=0;f.target.position=camp.center+Vector3.new(0,2.15,9)
  for t=0,2,.2 do f.time(t);f.service:recover(f.target.rig,frame)end
  f.time(2.01);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==55)
  f.setWritable(false);f.time(3);f.service:recover(f.target.rig,frame)
  f.setWritable(true);f.time(4);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==55)
  f.target.humanoid.Health=98
  for t=5,7 do f.time(t);f.service:recover(f.target.rig,frame)end
  assert(f.target.humanoid.Health==100)
  f.target.humanoid.Health=99;f.time(8);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==99)
 end)end)
 test("unregistered patients and sources cannot resolve queued healing",function()
  for _,which in {"source","target"}do run(function(f)
   assert(f.service:throw(f.source.rig,f.list()))
   f.actors[if which=="source" then f.source.rig else f.target.rig]=nil
   f.step(.2);assert(f.target.humanoid.Health==50 and f.service:count()==0)
  end)end
 end)
 test("yard recovery excludes foreign physical yards and resets hidden external damage",function()run(function(f)
  local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
  local callback
  f.target.humanoid.HealthChanged={Connect=function(_,fn)callback=fn;return {Disconnect=function()end}end}
  local frame={PointToObjectSpace=function(_,p)return p end}
  f.target.position=Camp.center+Vector3.new(0,2.15,9)
  f.time(0);f.service:recover(f.target.rig,frame)
  f.time(1);f.service:recover(f.target.rig,frame)
  callback(40);callback(50) -- Damage followed by healing between samples still resets the wait.
  f.time(2);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==50)
  f.time(3);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==50)
  f.time(4);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==55)
  local foreign={PointToObjectSpace=function(_,p)return p+Vector3.new(500,0,0)end}
  f.time(5);f.service:recover(f.target.rig,foreign);assert(f.target.humanoid.Health==55 and not f.target.rig.attrs.Recovering)
  f.states[1].trainingLevel=0;f.time(6);f.service:recover(f.target.rig,frame);assert(f.target.humanoid.Health==55)
 end)end)
 return n
end

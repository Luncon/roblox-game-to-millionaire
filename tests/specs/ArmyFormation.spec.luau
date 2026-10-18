return function()
 local module=game.ServerScriptService.Game:FindFirstChild('ArmyFormation');assert(module,'ArmyFormation is missing')
 local F=require(module)
 local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
 local Camp=require(game.ReplicatedStorage.Shared.TrainingCampConfig)
 local frame={PointToObjectSpace=function(_,p)return p end}
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function setup()
  local state={formationLevel=1,warCouncilLevel=1,shieldLevel=1,armyCampLevel=2,hospitalLevel=1,selectedFormation=Config.id}
  local actors={};for id,kind in Config.roles do actors[id]={rig={},humanoid={},kind=kind,alive=true,position=Camp.point(Camp.arrivalIndex(id)),phase='idle'}end
  return state,actors
 end
 test('muster requires selected trained faction and five correctly typed current camp lives at ground height',function()
  local s,a=setup();assert(F.ready(s,'sparta',frame,a))
  assert(not F.ready(s,'britain',frame,a));s.selectedFormation='none';assert(not F.ready(s,'sparta',frame,a));s.selectedFormation=Config.id
  a.camp.kind='ranged';assert(not F.ready(s,'sparta',frame,a));a.camp.kind='warrior'
  local old=a.medic;a.medic=nil;assert(not F.ready(s,'sparta',frame,a));a.medic=old
  a.medic.position+=Vector3.new(0,30,0);assert(not F.ready(s,'sparta',frame,a))
  a.medic.position=Vector3.zero;assert(not F.ready(s,'sparta',frame,a))
 end)
 test('convex middle leads outer shieldmen and supports remain paired behind for rotated headings',function()
  local _,a=setup()
  for _,direction in {Vector3.new(0,0,-1),Vector3.new(-1,0,0),Vector3.new(.7,0,.7).Unit}do
   local g=F.new(Vector3.zero,direction*100,a);local goals=F.goals(g,function(p)return p end)
   assert((goals.warrior-goals.camp):Dot(direction)>1.9)
   assert(math.abs((goals.camp-goals.reinforcement):Dot(direction))<.001)
   assert((goals.warrior-goals.medic):Dot(direction)>10)
   assert(math.abs((goals.ranged-goals.medic):Dot(direction))<.001 and math.abs((goals.ranged-goals.medic).Magnitude-6)<.001)
  end
 end)
 test('road assembly waits for all five and marching waits for lagging attacking or unsafe members',function()
  local _,a=setup();local g=F.new(Vector3.zero,Vector3.new(0,0,-100),a)
  F.step(g,a,.2,function()return true end,function(p)return p end);assert(g.phase=='assembling' and g.anchor.Magnitude==0)
  local goals=F.goals(g,function(p)return p end);for id,p in goals do a[id].position=p end
  F.step(g,a,.2,function()return true end,function(p)return p end);assert(g.phase=='marching')
  F.step(g,a,.2,function()return true end,function(p)return p end);assert(g.anchor.Magnitude>0 and g.anchor.Magnitude<=1.21)
  local anchor=g.anchor;a.medic.position+=Vector3.new(0,0,20)
  F.step(g,a,.2,function()return true end,function(p)return p end);assert((g.anchor-anchor).Magnitude==0)
  for id,p in F.goals(g,function(p)return p end)do a[id].position=p end
  a.warrior.phase='windup';F.step(g,a,.2,function()return true end,function(p)return p end);assert((g.anchor-anchor).Magnitude==0)
  a.warrior.phase='idle';F.step(g,a,.2,function()return false end,function(p)return p end);assert((g.anchor-anchor).Magnitude==0)
 end)
 test('a dead or replaced member invalidates the captured formation life',function()
  local _,a=setup();local g=F.new(Vector3.zero,Vector3.new(0,0,-100),a)
  a.medic.rig={};local result,reason=F.step(g,a,.2,function()return true end,function(p)return p end)
  assert(not result and reason=='member_lost')
 end)
 return n
end

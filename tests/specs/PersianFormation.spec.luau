return function()
 local S=game.ReplicatedStorage.Shared;local G=game.ServerScriptService.Game
 local Config=require(S.FormationConfig);local F=require(G.ArmyFormation)
 local Data=require(G.ProfileData);local Development=require(S.SettlementDevelopment)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function setup(id)
  local def=assert(Config.forCivilization(id or 'persia'),'Persian Archer Screen is missing')
  local actors={};for slot,kind in Config.roles do actors[slot]={rig={},humanoid={},kind=kind,alive=true,phase='idle',position=Vector3.zero}end
  local group=F.new(Vector3.zero,Vector3.new(0,0,-100),actors,def)
  for slot,p in F.goals(group,function(v)return v end)do actors[slot].position=p end
  return group,actors
 end
 test('Persia purchases and selects its own screen at existing shield progression prices',function()
  local def=assert(Config.forCivilization('persia'));assert(def.id=='persian-archer-screen' and def.skillFamily=='spear' and Config.pace==6)
  local s=Data.defaultState();s.coins,s.level,s.armorLevel,s.barracksLevel=3000,20,15,6
  s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel=1,1,1,1
  local E=require(G.Economy).new(function()return 100 end,nil,function()return 'persia' end);assert(E:open(101,s))
  assert(Development.offer(s,'shield','persia').available)
  for _,p in {{'shield',0},{'armyCamp',1},{'warCouncil',0},{'formation',0}}do assert(E:upgrade(101,p[2],p[1]).ok)end
  assert(E:selectFormation(101,def.id).ok and E:get(101).coins==2150)
  assert(Data.copyState(E:get(101),'persia') and not Data.copyState(E:get(101),'rome'))
  assert(not E:selectFormation(101,'roman-shield-guard').ok)
 end)
 test('straight front and rear pair assemble for rotated road headings',function()
  for _,heading in {Vector3.new(0,0,-1),Vector3.new(1,0,0),Vector3.new(.7,0,.7).Unit}do
   local g,a=setup();g.heading=heading
   local goals=F.goals(g,function(v)return v end)
   assert(math.abs((goals.warrior-goals.camp):Dot(heading))<.001 and math.abs((goals.warrior-goals.reinforcement):Dot(heading))<.001)
   assert((goals.warrior-goals.ranged):Dot(heading)>8)
   for id,p in goals do a[id].position=p end
   F.step(g,a,.2,function()return true end,function(v)return v end);assert(g.phase=='marching')
  end
 end)
 test('firing opportunity requires the captured archer clear validation and thirty-stud range',function()
  local g,a=setup();local bow=a.ranged;local foe={position=bow.position+g.heading*30}
  assert(F.firingOpportunity(g,bow,{foe},function()return true end))
  assert(not F.firingOpportunity(g,bow,{foe},function()return false end))
  foe.position=bow.position+g.heading*30.01;assert(not F.firingOpportunity(g,bow,{foe},function()return true end))
  foe.position=bow.position;local replaced=table.clone(bow);replaced.rig={}
  assert(not F.firingOpportunity(g,replaced,{foe},function()return true end))
  g.members.ranged=nil;assert(not F.firingOpportunity(g,bow,{foe},function()return true end))
 end)
 test('Persia closes twenty-five percent farther and slows to half pace within bow range',function()
  local g,a=setup();local foe={position=a.ranged.position+g.heading*40}
  assert(g.definition.screenRange==30 and g.definition.approachRange==45)
  assert(not F.firingOpportunity(g,a.ranged,{foe},function()return true end))
  assert(F.firingOpportunity(g,a.ranged,{foe},function()return true end,g.definition.approachRange))
  assert(not F.firingOpportunity(g,a.ranged,{foe},function()return false end,g.definition.approachRange))
  g.phase='marching';g.slowApproach=true;local before=g.anchor
  assert(F.step(g,a,.2,function()return true end,function(v)return v end,false))
  assert(math.abs((g.anchor-before).Magnitude-.6)<.001)
  local normal,b=setup('rome');normal.phase='marching';local p=normal.anchor
  assert(F.step(normal,b,.2,function()return true end,function(v)return v end,false))
  assert(math.abs((normal.anchor-p).Magnitude-1.2)<.001)
 end)
 test('clear-shot deployment stops before the center and stays latched after targets leave',function()
  local g,a=setup();g.phase='marching';local anchor=g.anchor
  assert(F.step(g,a,.2,function()return true end,function(v)return v end,true))
  assert(g.phase=='screening' and g.anchor==anchor and g.anchor~=g.destination)
  a.camp.position+=Vector3.new(5,0,0);a.warrior.phase='windup'
  assert(F.step(g,a,1,function()return true end,function(v)return v end,false) and g.anchor==anchor and g.phase=='screening')
 end)
 test('Persia deploys at an empty center while Sparta and Rome retain arrival release',function()
  for _,id in {'persia','sparta','rome'}do
   local g,a=setup(id);g.anchor=g.destination;g.phase='marching'
   for slot,p in F.goals(g,function(v)return v end)do a[slot].position=p end
   local goals,reason=F.step(g,a,.2,function()return true end,function(v)return v end)
   if id=='persia'then assert(goals and g.phase=='screening')else assert(not goals and reason=='destination_reached')end
  end
 end)
 test('screen keeps support-loss capture rules and releases on frontline loss',function()
  local g,a=setup();g.phase='screening';a.ranged=nil
  assert(F.step(g,a,.2,function()return true end,function(v)return v end) and not g.members.ranged)
  a.camp.alive=false;local goals,reason=F.step(g,a,.2,function()return true end,function(v)return v end)
  assert(not goals and reason=='frontline_lost')
 end)
 return n
end

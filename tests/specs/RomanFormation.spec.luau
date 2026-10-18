return function()
 local Shared=game.ReplicatedStorage.Shared;local G=game.ServerScriptService.Game
 local Config=require(Shared.FormationConfig);local Data=require(G.ProfileData)
 local D=require(Shared.SettlementDevelopment);local F=require(G.ArmyFormation)
 local Camp=require(Shared.TrainingCampConfig)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function state()
  local s=Data.defaultState();s.coins,s.level,s.armorLevel,s.barracksLevel=3000,20,15,6
  s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel=1,1,1,1;return s
 end
 test('Rome has its own frozen formation and the same unlock prices and march speed',function()
  local rome=assert(Config.forCivilization('rome'));local sparta=assert(Config.forCivilization('sparta'))
  assert(rome.id=='roman-shield-guard' and rome.name=='Roman Shield Guard' and rome.skillFamily=='sword')
  assert(sparta.id=='spartan-shieldwall' and Config.pace==6 and not Config.forCivilization('britain'))
  local s=state();assert(D.offer(s,'shield','rome').available)
  s.shieldLevel,s.warCouncilLevel,s.armyCampLevel=1,1,2
  local offer=D.offer(s,'formation','rome');assert(offer.available and offer.cost==250 and offer.title==rome.name)
 end)
 test('Roman purchases and faction selection preserve version-one save validation and isolation',function()
  local E=require(G.Economy).new(function()return 100 end,nil,function()return 'rome' end)
  assert(E:open(101,state()))
  for _,v in {{'shield',0},{'armyCamp',1},{'warCouncil',0},{'formation',0}}do assert(E:upgrade(101,v[2],v[1]).ok)end
  assert(E:selectFormation(101,'roman-shield-guard').ok and E:get(101).coins==2150)
  local saved=E:get(101);assert(Data.copyState(saved,'rome') and not Data.copyState(saved,'sparta'))
  assert(not E:selectFormation(101,'spartan-shieldwall').ok and not Data.copyState(saved,'britain'))
  saved.selectedFormation='none';assert(Data.copyState(saved,'rome'))
 end)
 test('Roman supports stay compact between flank guards and guard facing rotates with the road',function()
  local def=Config.forCivilization('rome');local actors={}
  for id,kind in Config.roles do actors[id]={rig={},humanoid={},alive=true,kind=kind,position=Camp.point(Camp.arrivalIndex(id)),phase='idle'}end
  local s=state();s.shieldLevel,s.warCouncilLevel,s.armyCampLevel,s.formationLevel=1,1,2,1;s.selectedFormation=def.id
  assert(F.ready(s,'rome',{PointToObjectSpace=function(_,p)return p end},actors))
  for _,heading in {Vector3.new(0,0,-1),Vector3.new(1,0,0),Vector3.new(.7,0,.7).Unit}do
   local g=F.new(Vector3.zero,heading*100,actors,def);local goals=F.goals(g,function(p)return p end)
   local right=Vector3.new(-heading.Z,0,heading.X)
   assert((goals.warrior-goals.ranged):Dot(heading)>6 and (goals.warrior-goals.ranged):Dot(heading)<7)
   assert((goals.ranged-goals.camp):Dot(right)>3 and (goals.reinforcement-goals.medic):Dot(right)>3)
   assert(F.facing(g,'camp'):Dot(right)<-.6 and F.facing(g,'reinforcement'):Dot(right)>.6)
   assert(F.facing(g,'warrior'):Dot(heading)>.99)
   for id,p in goals do actors[id].position=p end
   assert(F.step(g,actors,.2,function()return true end,function(p)return p end) and g.phase=='marching')
  end
 end)
 return n
end

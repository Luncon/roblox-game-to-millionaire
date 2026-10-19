return function()
 local S=game.ReplicatedStorage.Shared;local G=game.ServerScriptService.Game
 local Config=require(S.FormationConfig);local F=require(G.ArmyFormation)
 local Data=require(G.ProfileData);local Development=require(S.SettlementDevelopment)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function state()
  local s=Data.defaultState();s.coins,s.level,s.armorLevel,s.barracksLevel=3000,20,15,6
  s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel=1,1,1,1;return s
 end
 local function setup()
  local def=assert(Config.forCivilization('vikings'),'Viking Shield Wedge is missing')
  local a={};for id,kind in Config.roles do a[id]={rig={},humanoid={},alive=true,kind=kind,phase='idle',position=Vector3.zero}end
  local g=F.new(Vector3.zero,Vector3.new(0,0,-100),a,def)
  for id,p in F.goals(g,function(v)return v end)do a[id].position=p end
  return g,a
 end
 test('Viking wedge mirrors existing shield progression without stat or speed bonuses',function()
  local def=assert(Config.forCivilization('vikings'),'Viking Shield Wedge is missing')
  assert(def.id=='viking-shield-wedge' and def.name=='Viking Shield Wedge' and def.breakOnMeleeContact and Config.pace==6)
  local s=state();local shield=Development.offer(s,'shield','vikings')
  assert(shield.available and shield.cost==150 and shield.requiredSettlement==15)
  s.shieldLevel,s.warCouncilLevel,s.armyCampLevel=1,1,2
  local offer=Development.offer(s,'formation','vikings');assert(offer.available and offer.cost==250 and offer.requiredSettlement==20)
  s.level=19;assert(not Development.offer(s,'formation','vikings').available)
 end)
 test('Viking wedge purchases and fake-store reload retain faction isolation and old save keys',function()
  local E=require(G.Economy).new(function()return 100 end,nil,function()return 'vikings' end);assert(E:open(101,state()))
  for _,p in {{'shield',0},{'armyCamp',1},{'warCouncil',0},{'formation',0}}do assert(E:upgrade(101,p[2],p[1]).ok)end
  assert(E:selectFormation(101,'viking-shield-wedge').ok and E:get(101).coins==2150)
  assert(not E:selectFormation(101,'spartan-shieldwall').ok)
  local saved=E:get(101);assert(Data.copyState(saved,'vikings') and not Data.copyState(saved,'rome'))
  local Service=require(G.ProfileService);local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
  local options={clock=function()return 100 end,wait=function()end,sessionId='viking-first'}
  local first=Service.new(store,options);assert(first:load(101).ok)
  assert(first:set(101,'vikings',saved));assert(first:set(101,'sparta',state()));assert(first:release(101).ok)
  options.sessionId='viking-reload';local second=Service.new(store,options);assert(second:load(101).ok)
  assert(second:get(101,'vikings').selectedFormation=='viking-shield-wedge' and second:get(101,'sparta').selectedFormation=='none')
  assert(second:release(101).ok)
 end)
 test('pointed Viking wedge rotates with all eight roads and keeps paired supports behind',function()
  local g,a=setup()
  for i=0,7 do
   local heading=Vector3.new(math.sin(i*math.pi/4),0,-math.cos(i*math.pi/4));g.heading=heading;g.phase='assembling'
   local goals=F.goals(g,function(v)return v end);local right=Vector3.new(-heading.Z,0,heading.X)
   assert(math.abs((goals.warrior-goals.camp):Dot(heading)-6)<.001)
   assert(math.abs((goals.warrior-goals.reinforcement):Dot(heading)-6)<.001)
   assert(math.abs((goals.reinforcement-goals.camp):Dot(right)-10)<.001)
   assert(math.abs((goals.warrior-goals.medic):Dot(heading)-14)<.001)
   assert(math.abs((goals.medic-goals.ranged):Dot(right)-6)<.001)
   for id,p in goals do a[id].position=p;assert(F.facing(g,id):Dot(heading)>.999)end
   assert(F.step(g,a,.2,function()return true end,function(v)return v end) and g.phase=='marching')
  end
 end)
 test('Viking melee and player shields deplete twice without same-life refresh refills',function()
  local Shield=require(G.ShieldCombat)
  for _,kind in {'warrior','player'}do
   local values={};local rig={GetAttribute=function(_,k)return values[k]end,SetAttribute=function(_,k,v)values[k]=v end,GetDescendants=function()return {}end}
   Shield.refresh(rig,'vikings',kind,{shieldLevel=1});assert(values.ShieldCharges==2)
   local t={rig=rig,position=Vector3.zero,root={CFrame={LookVector=Vector3.new(0,0,-1)}}}
   assert(Shield.block(t,Vector3.new(0,0,-4)));assert(Shield.block(t,Vector3.new(0,0,-4)))
   Shield.refresh(rig,'vikings',kind,{shieldLevel=1});assert(values.ShieldCharges==0)
   assert(Shield.restock(rig,'vikings',kind,{shieldLevel=1})==(kind=='warrior'))
  end
 end)
 return n
end

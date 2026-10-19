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
 test('melee opportunity uses only captured living frontline identities and server validation',function()
  local g,a=setup();local enemy={position=a.warrior.position+g.heading*4}
  local function accepted(attacker,target)return attacker==a.warrior and target==enemy end
  assert(F.contactOpportunity(g,a,{enemy},accepted))
  assert(not F.contactOpportunity(g,a,{enemy},function()return false end))
  for _,field in {'rig','humanoid','alive','kind'}do
   local old=a.warrior[field];a.warrior[field]=if field=='alive'then false elseif field=='kind'then 'ranged' else {}
   assert(not F.contactOpportunity(g,a,{enemy},accepted),'Stale contact accepted: '..field);a.warrior[field]=old
  end
  a.warrior=nil;assert(not F.contactOpportunity(g,a,{enemy},accepted))
  for _,id in {'camp','reinforcement'}do
   assert(F.contactOpportunity(g,a,{enemy},function(attacker)return attacker==a[id]end),'Flank contact ignored')
  end
  assert(not F.contactOpportunity(g,a,{enemy},function(attacker)return attacker==a.ranged or attacker==a.medic end))
 end)
 test('contact callback rejects friendlies dead targets blocked sight authority range and protected ground',function()
  local g,a=setup();local Rules=require(G.CombatRules)
  -- An explicit arena frame works in both native Studio and the CLI doubles.
  local arena={Size=Vector3.new(2,200,200),CFrame={PointToObjectSpace=function(_,v)return Vector3.new(v.Y,v.X,v.Z)end}}
  local front=a.warrior;front.ownerId,front.claimed=101,true
  local enemy={ownerId=202,claimed=true,alive=true,position=front.position+g.heading*5}
  local visible,writable=true,true
  local function valid(source,target)return writable and visible and Rules.canDamage(source,target,arena,5)end
  assert(F.contactOpportunity(g,a,{enemy},valid))
  enemy.position=front.position+g.heading*5.01;assert(not F.contactOpportunity(g,a,{enemy},valid))
  enemy.position=front.position+g.heading*4;enemy.ownerId=101;assert(not F.contactOpportunity(g,a,{enemy},valid))
  enemy.ownerId=202;enemy.alive=false;assert(not F.contactOpportunity(g,a,{enemy},valid));enemy.alive=true
  visible=false;assert(not F.contactOpportunity(g,a,{enemy},valid));visible=true
  writable=false;assert(not F.contactOpportunity(g,a,{enemy},valid));writable=true
  front.position=Vector3.new(0,0,-99);enemy.position=Vector3.new(0,0,-101)
  assert(not F.contactOpportunity(g,a,{enemy},valid))
  front.position,enemy.position=enemy.position,front.position;assert(not F.contactOpportunity(g,a,{enemy},valid))
 end)
 test('Viking contact releases during assembly march attack stalls and lost cohesion',function()
  for _,phase in {'assembling','marching'}do
   local g,a=setup();g.phase=phase;a.warrior.phase='windup';a.medic.position+=Vector3.new(0,0,40)
   local goals,reason=F.step(g,a,.2,function()return false end,function(v)return v end,false,true)
   assert(not goals and reason=='melee_contact','Contact waited on assembly or cohesion')
  end
 end)
 test('Hold and other civilizations suppress contact release while Viking ranged shots do not release',function()
  local g,a=setup();g.phase='holding'
  assert(F.step(g,a,0,function()return false end,function(v)return v end,false,true) and g.phase=='holding')
  for _,id in {'sparta','rome','persia'}do
   g.definition=Config.forCivilization(id);g.phase='marching'
   assert(not F.contactOpportunity(g,a,{{}},function()return true end))
   assert(F.step(g,a,.2,function()return true end,function(v)return v end,false,true),'Contact changed '..id)
  end
  g,a=setup();g.phase='marching'
  assert(F.step(g,a,.2,function()return true end,function(v)return v end,true,false) and g.phase=='marching')
 end)
 test('Viking arrival frontline casualty and support replacement keep shared captured-life rules',function()
  local g,a=setup();g.phase='marching';a.medic=nil
  assert(F.step(g,a,.2,function()return true end,function(v)return v end) and not g.members.medic)
  a.medic={rig={},humanoid={},alive=true,kind='medic',position=Vector3.zero,phase='idle'}
  assert(F.step(g,a,.2,function()return true end,function(v)return v end).medic==nil)
  a.camp.alive=false;local goals,reason=F.step(g,a,.2,function()return true end,function(v)return v end)
  assert(not goals and reason=='frontline_lost')
  g,a=setup();g.phase='marching';g.anchor=g.destination
  for id,p in F.goals(g,function(v)return v end)do a[id].position=p end
  goals,reason=F.step(g,a,.2,function()return true end,function(v)return v end)
  assert(not goals and reason=='destination_reached')
 end)
 return n
end

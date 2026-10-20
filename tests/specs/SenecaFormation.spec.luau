return function()
 local S=game.ReplicatedStorage.Shared;local G=game.ServerScriptService.Game
 local Config=require(S.FormationConfig);local F=require(G.ArmyFormation)
 local Data=require(G.ProfileData);local D=require(S.SettlementDevelopment);local Recruitment=require(S.ArmyRecruitment)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function state(unlocked)
  local s=Data.defaultState();s.level,s.coins,s.barracksLevel=20,3000,6
  s.trainingLevel,s.armyCampLevel,s.hospitalLevel,s.warCouncilLevel=1,2,1,1
  s.recruitMelee,s.recruitRanged,s.recruitMedic=1,3,1
  if unlocked then s.formationLevel=1;s.selectedFormation='seneca-focused-volley'end
  return s
 end
 local function setup()
  local s=state(true);local a={};local Camp=require(S.TrainingCampConfig)
  for _,slot in Recruitment.slots(s)do a[slot.id]={rig={},humanoid={},kind=slot.kind,alive=true,phase='idle',position=Camp.point(Camp.arrivalIndex(slot.id))}end
  return s,a
 end
 test('Seneca unlocks its own 1/3/1 formation without shield armor or workshop prerequisites',function()
  local def=assert(Config.forCivilization('seneca'),'Focused Volley missing')
  assert(def.id=='seneca-focused-volley' and def.requiresShields==false)
  local s=state();local offer=D.offer(s,'formation','seneca')
  assert(offer.available and offer.cost==250 and offer.requiredSettlement==20)
  assert(not D.offer(s,'shield','seneca').available and not D.offer(s,'shield','japan').available)
  assert(not Config.usesShields('seneca') and not Config.usesShields('japan'))
  for _,id in {'sparta','rome','persia','vikings'}do
   assert(Config.usesShields(id) and not D.offer(s,'formation',id).available)
  end
 end)
 test('Seneca formation purchase and save reload preserve shieldless faction isolated progress',function()
  local E=require(G.Economy).new(function()return 100 end,nil,function()return 'seneca'end);assert(E:open(101,state()))
  assert(E:upgrade(101,0,'formation').ok and E:get(101).coins==2750)
  assert(E:selectFormation(101,'seneca-focused-volley').ok and not E:selectFormation(101,'viking-shield-wedge').ok)
  local saved=E:get(101);assert(Data.copyState(saved,'seneca') and not Data.copyState(saved,'sparta'))
  saved.selectedFormation='none';assert(Data.copyState(saved,'seneca'));saved.selectedFormation='seneca-focused-volley'
  local Service=require(G.ProfileService);local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
  local options={clock=function()return 100 end,wait=function()end,sessionId='seneca-first'}
  local first=Service.new(store,options);assert(first:load(101).ok);assert(first:set(101,'seneca',saved));assert(first:release(101).ok)
  options.sessionId='seneca-second';local second=Service.new(store,options);assert(second:load(101).ok)
  local restored=second:get(101,'seneca');assert(restored.shieldLevel==0 and restored.selectedFormation=='seneca-focused-volley' and restored.recruitRanged==3)
  assert(second:get(101,'japan').selectedFormation=='none');assert(second:release(101).ok)
  local bad=table.clone(saved);bad.shieldLevel=1;bad.armorLevel=15;bad.armorerLevel=1;assert(not Data.copyState(bad,'seneca'))
 end)
 test('Focused Volley musters current 1/3/1 lives and rejects wrong missing outside or stale classes',function()
  local s,a=setup();local frame={PointToObjectSpace=function(_,p)return p end}
  assert(F.ready(s,'seneca',frame,a));a.camp.kind='warrior';assert(not F.ready(s,'seneca',frame,a));a.camp.kind='ranged'
  a.ranged.alive=false;assert(not F.ready(s,'seneca',frame,a));a.ranged.alive=true
  a.medic.position=Vector3.zero;assert(not F.ready(s,'seneca',frame,a))
 end)
 test('crescent geometry rotates on every road and deploys despite combat or support cohesion stalls',function()
  local _,a=setup();local def=Config.forCivilization('seneca')
  for i=0,7 do
   local heading=Vector3.new(math.sin(i*math.pi/4),0,-math.cos(i*math.pi/4));local g=F.new(Vector3.zero,heading*100,a,def)
   local goals=F.goals(g,function(p)return p end);local right=Vector3.new(-heading.Z,0,heading.X)
   assert((goals.reinforcement-goals.camp):Dot(right)>19.9 and (goals.warrior-goals.ranged):Dot(heading)>10)
   -- A centered medic would have its guard-healing ray blocked by the center archer.
   local leg=goals.warrior-goals.medic
   local t=math.clamp((goals.ranged-goals.medic):Dot(leg)/leg:Dot(leg),0,1)
   assert((goals.ranged-(goals.medic+leg*t)).Magnitude>2.5,'Center archer blocks medic sight to guard')
   for id,p in goals do a[id].position=p;a[id].phase='idle'end
   assert(F.step(g,a,.2,function()return true end,function(p)return p end) and g.phase=='marching')
   a.ranged.phase='windup';a.medic.position-=heading*20
   assert(F.step(g,a,.2,function()return true end,function(p)return p end,true) and g.phase=='screening')
   local anchor=g.anchor;assert(F.step(g,a,.2,function()return true end,function(p)return p end,false) and g.anchor==anchor)
  end
 end)
 test('archer losses preserve remaining captures while guard or all archers lost release the group',function()
  local _,a=setup();local g=F.new(Vector3.zero,Vector3.new(0,0,-100),a,Config.forCivilization('seneca'));g.phase='screening'
  a.camp.alive=false;assert(F.step(g,a,0,function()return true end,function(p)return p end) and not g.members.camp)
  a.camp={rig={},humanoid={},alive=true,kind='ranged',position=Vector3.zero,phase='idle'}
  assert(F.step(g,a,0,function()return true end,function(p)return p end).camp==nil)
  a.ranged.alive=false;a.reinforcement.alive=false
  local goals,reason=F.step(g,a,0,function()return true end,function(p)return p end);assert(not goals and reason=='archers_lost')
  _,a=setup();g=F.new(Vector3.zero,Vector3.new(0,0,-100),a,Config.forCivilization('seneca'));a.warrior.alive=false
  goals,reason=F.step(g,a,0,function()return true end,function(p)return p end);assert(not goals and reason=='frontline_lost')
 end)
 test('Seneca and Japan never receive shields even with a forged trained state',function()
  local Shield=require(G.ShieldCombat)
  for _,civ in {'seneca','japan'}do for _,kind in {'warrior','player','ranged'}do
   local values={};local rig={GetAttribute=function(_,k)return values[k]end,SetAttribute=function(_,k,v)values[k]=v end}
   Shield.refresh(rig,civ,kind,{shieldLevel=1});assert(values.ShieldCharges==0)
   values.SpartanShieldRemaining,values.ShieldCharges=0,0
   assert(not Shield.restock(rig,civ,kind,{shieldLevel=1}))
  end end
 end)
 return n
end

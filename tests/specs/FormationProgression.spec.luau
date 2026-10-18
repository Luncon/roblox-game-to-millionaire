return function()
 local G=game.ServerScriptService.Game
 local D=require(game.ReplicatedStorage.Shared.SettlementDevelopment)
 local Data=require(G.ProfileData)
 local n=0
 local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function ready()
  local s=Data.defaultState()
  s.coins,s.level,s.armorLevel,s.barracksLevel=3000,20,15,6
  s.trainingLevel,s.armorerLevel,s.armyCampLevel,s.hospitalLevel=1,1,1,1
  return s
 end
 test('Army Camp II is a universal paid fifth slot at eighteen after Barracks VI',function()
  local s=ready();s.level=17
  local p=D.offer(s,'armyCamp');assert(p.cost==250 and p.nextLevel==2 and not p.available)
  s.level=18;assert(D.offer(s,'armyCamp').available)
  s.barracksLevel=5;assert(not D.offer(s,'armyCamp').available)
  s.barracksLevel=6;s.armyCampLevel=2;assert(D.armyCapacity(s)==5)
 end)
 test('shield training is paid and gated by civilization armor and workshop',function()
  local s=ready()
  local p=D.offer(s,'shield','sparta');assert(p and p.available and p.cost==150 and p.requiredSettlement==15)
  assert(not D.offer(s,'shield','britain').available)
  s.armorLevel=14;assert(not D.offer(s,'shield','sparta').available)
  s.armorLevel=15;s.armorerLevel=0;assert(not D.offer(s,'shield','sparta').available)
 end)
 test('council and Spartan formation have independent building and army prerequisites',function()
  local s=ready();s.level=18
  local p=D.offer(s,'warCouncil','britain');assert(p and p.cost==200 and not p.available)
  s.level=19;assert(D.offer(s,'warCouncil','britain').available)
  s.level=20;s.warCouncilLevel=1;s.shieldLevel=1;s.armyCampLevel=2
  p=D.offer(s,'formation','sparta');assert(p and p.available and p.cost==250)
  assert(not D.offer(s,'formation','britain').available)
  for _,field in {'warCouncilLevel','shieldLevel','hospitalLevel'}do local old=s[field];s[field]=0;assert(not D.offer(s,'formation','sparta').available);s[field]=old end
  s.armyCampLevel=1;assert(not D.offer(s,'formation','sparta').available)
 end)
 test('legacy saves default only missing formation fields and reject invalid combinations',function()
  local s=ready();s.shieldLevel=nil;s.warCouncilLevel=nil;s.formationLevel=nil;s.selectedFormation=nil
  local copy=assert(Data.copyState(s,'sparta'))
  assert(copy.shieldLevel==0 and copy.warCouncilLevel==0 and copy.formationLevel==0 and copy.selectedFormation=='none')
  for _,value in {false,'1',2,-1}do s.shieldLevel=value;assert(not Data.copyState(s,'sparta'))end
  s=ready();s.armyCampLevel=2;s.warCouncilLevel=1;s.shieldLevel=1;s.formationLevel=1;s.selectedFormation='spartan-shieldwall'
  assert(Data.copyState(s,'sparta'));assert(not Data.copyState(s,'britain'))
  local full=table.clone(s)
  for field,value in {armorLevel=14,barracksLevel=5,trainingLevel=0,armorerLevel=0,armyCampLevel=1,hospitalLevel=0,warCouncilLevel=0,shieldLevel=0,formationLevel=0,selectedFormation='unknown'}do
   local bad=table.clone(full);bad[field]=value;assert(not Data.copyState(bad,'sparta'),'Invalid formation profile accepted: '..field)
  end
 end)
 test('new fields save independently without combat charges or march state',function()
  local Service=require(G.ProfileService);local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
  local options={clock=function()return 100 end,wait=function()end,sessionId='formation-save'}
  local first=Service.new(store,options);assert(first:load(101).ok)
  local s=ready();s.armyCampLevel=2;s.warCouncilLevel=1;s.shieldLevel=1;s.formationLevel=1;s.selectedFormation='spartan-shieldwall';s.shieldCharges=1;s.formationPhase='marching'
  local roman=table.clone(s);roman.selectedFormation='roman-shield-guard'
  local persian=table.clone(s);persian.selectedFormation='persian-archer-screen'
  assert(first:set(101,'sparta',s));assert(first:set(101,'rome',roman));assert(first:set(101,'persia',persian));assert(first:set(101,'britain',ready()));assert(first:release(101).ok)
  options.sessionId='formation-reload';local second=Service.new(store,options);assert(second:load(101).ok)
  local a,b,c=second:get(101,'sparta'),second:get(101,'britain'),second:get(101,'rome')
  assert(a.selectedFormation=='spartan-shieldwall' and a.armyCampLevel==2 and b.selectedFormation=='none' and b.armyCampLevel==1)
  local p=second:get(101,'persia');assert(p.selectedFormation=='persian-archer-screen' and not p.shieldCharges and not p.formationPhase)
  assert(c.selectedFormation=='roman-shield-guard' and c.formationLevel==1 and not c.shieldCharges and not c.formationPhase)
  assert(not a.shieldCharges and not a.formationPhase and #D.persistentFields==23);assert(second:release(101).ok)
 end)
 test('server purchases spend exact prices and selection preserves health-free scalar state',function()
  local E=require(G.Economy).new(function()return 100 end,nil,function()return 'sparta' end)
  assert(E:open(101,ready()))
  for _,v in {{'shield',0},{'armyCamp',1},{'warCouncil',0},{'formation',0}}do assert(E:upgrade(101,v[2],v[1]).ok,v[1])end
  assert(E:get(101).coins==2150 and D.armyCapacity(E:get(101))==5)
  assert(E:selectFormation(101,'spartan-shieldwall').ok)
  assert(E:get(101).selectedFormation=='spartan-shieldwall' and E:get(101).coins==2150)
  assert(not E:selectFormation(101,'invented').ok)
 end)
 test('server civilization and writable authority guard every new purchase',function()
  local writable=true
  local E=require(G.Economy).new(function()return 100 end,function()return writable end,function()return 'britain' end)
  assert(E:open(101,ready()));assert(not E:upgrade(101,0,'shield').ok)
  assert(E:upgrade(101,1,'armyCamp').ok and E:upgrade(101,0,'warCouncil').ok)
  assert(not E:selectFormation(101,'spartan-shieldwall').ok)
  writable=false;assert(not E:selectFormation(101,'none').ok)
 end)
 return n
end

return function()
 local S=game.ReplicatedStorage.Shared
 local R=require(S.ArmyRecruitment)
 local Data=require(game.ServerScriptService.Game.ProfileData)
 local Economy=require(game.ServerScriptService.Game.Economy)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function full()
  local s=Data.defaultState();s.level,s.barracksLevel,s.armyCampLevel,s.trainingLevel,s.hospitalLevel=20,6,2,1,1
  return s
 end
 test('legacy recruitment preserves every purchased capacity and camp class',function()
  for b=1,6 do for camp=0,2 do for _,kind in {'warrior','ranged'}do
   local s={barracksLevel=b,armyCampLevel=camp,extraTroopClass=kind,hospitalLevel=1}
   local c=R.counts(s);local capacity=(if b>=4 then 2 else 1)+camp
   assert(c.melee+c.ranged==capacity and c.medic==1)
   assert(c.ranged==(if b>=4 then 1 else 0)+(if camp>0 and kind=='ranged'then 1 else 0))
  end end end
 end)
 test('custom composition bounds all fighter counts and hospital slot',function()
  local s=full()
  for melee=0,5 do for ranged=0,5 do for medic=0,2 do
   assert(R.valid(s,{melee=melee,ranged=ranged,medic=medic})==(melee+ranged<=4 and medic<=1))
  end end end
  for _,bad in {false,{}, {melee=-1,ranged=0,medic=0},{melee=.5,ranged=0,medic=0},
   {melee=0/0,ranged=0,medic=0},{melee=math.huge,ranged=0,medic=0},{melee='1',ranged=0,medic=0}}do assert(not R.valid(s,bad))end
  s.barracksLevel,s.armyCampLevel,s.hospitalLevel=1,0,0
  assert(R.valid(s,{melee=1,ranged=0,medic=0}) and not R.valid(s,{melee=0,ranged=1,medic=0}))
  assert(not R.valid(s,{melee=0,ranged=0,medic=1}))
 end)
 test('custom roles retain formation IDs and can disable all spawns',function()
  local s=full();s.recruitMelee,s.recruitRanged,s.recruitMedic=3,1,1
  local slots={};for _,slot in R.slots(s)do slots[slot.id]=slot.kind end
  assert(slots.warrior=='warrior' and slots.camp=='warrior' and slots.reinforcement=='warrior' and slots.ranged=='ranged' and slots.medic=='medic')
  s.recruitMelee,s.recruitRanged,s.recruitMedic=0,0,0
  assert(#R.slots(s)==5);for _,slot in R.slots(s)do assert(slot.kind=='none')end
  s.recruitMelee=4;for _,slot in R.slots(s)do if slot.id~='medic'then assert(slot.kind=='warrior')end end
 end)
 test('profile custom selections round trip and reject partial or locked selections',function()
  local s=full();s.recruitMelee,s.recruitRanged,s.recruitMedic=2,2,0
  local copy=assert(Data.copyState(s,'rome'));assert(copy.recruitRanged==2 and copy.armyCampLevel==2)
  local decoded=assert(Data.decode({schemaVersion=1,civilizations={rome=copy}}));assert(decoded.civilizations.rome.recruitMedic==0)
  s.recruitMedic=nil;assert(not Data.copyState(s))
  local legacy=assert(Data.copyState(full()));assert(legacy.recruitMelee==nil)
 end)
 test('economy saves own bounded composition and never changes coins or another owner',function()
  local time,writable=0,true;local e=Economy.new(function()return time end,function()return writable end)
  assert(e:open(1,full()) and e:open(2,full()))
  local r=e:selectComposition(1,{melee=1,ranged=3,medic=0});assert(r.ok and r.state.recruitRanged==3 and r.state.coins==0)
  assert(e:get(2).recruitRanged==nil)
  assert(not e:selectComposition(1,{melee=2,ranged=3,medic=0}).ok and e:get(1).recruitRanged==3)
  assert(not e:selectComposition(1,{melee=0,ranged=0,medic=0}).ok)
  time=1;writable=false;assert(not e:selectComposition(1,{melee=0,ranged=0,medic=0}).ok)
  writable=true;assert(e:selectComposition(1,{melee=0,ranged=0,medic=0}).ok)
  assert(e:replace(1,full()));assert(e:get(1).recruitRanged==nil)
 end)
 test('fake-store reacquisition restores custom composition independently per civilization',function()
  local store=require(game.ServerStorage.RuntimeTests.FakeProfileStore).new()
  local Service=require(game.ServerScriptService.Game.ProfileService)
  local first=Service.new(store,{clock=function()return 100 end,wait=function()end,sessionId='recruit-first'})
  assert(first:load(102).ok)
  local s=full();s.recruitMelee,s.recruitRanged,s.recruitMedic=1,3,0
  assert(first:set(102,'rome',s) and first:set(102,'persia',full()) and first:release(102).ok)
  local second=Service.new(store,{clock=function()return 101 end,wait=function()end,sessionId='recruit-second'})
  assert(second:load(102).ok)
  assert(second:get(102,'rome').recruitRanged==3 and second:get(102,'rome').recruitMedic==0)
  assert(second:get(102,'persia').recruitMelee==nil and second:release(102).ok)
 end)
 return n
end

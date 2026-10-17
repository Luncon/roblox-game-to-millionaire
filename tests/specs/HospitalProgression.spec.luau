return function()
 local Shared=game.ReplicatedStorage.Shared
 local D=require(Shared.SettlementDevelopment)
 local Data=require(game.ServerScriptService.Game.ProfileData)
 local Economy=require(game.ServerScriptService.Game.Economy)
 local n=0
 local function test(name,fn) fn();n+=1;print("PASS: "..name) end
 local function state() local s=Data.defaultState();s.level=10;s.trainingLevel=1;s.coins=1000;return s end
 test("hospital is a sixteen-field missing-only migration with prerequisite validation",function()
  local s=state();s.hospitalLevel=nil;local copy=Data.copyState(s);assert(copy.hospitalLevel==0)
  assert(#D.persistentFields==16)
  for _,bad in {false,"1",-1,.5,2,math.huge,0/0} do s.hospitalLevel=bad;assert(Data.copyState(s)==nil) end
  s=state();s.hospitalLevel=1;assert(Data.copyState(s));s.trainingLevel=0;assert(not Data.copyState(s))
  s=state();s.level=9;s.hospitalLevel=1;assert(not Data.copyState(s))
 end)
 test("hospital purchase charges 200 once without camp and adds independent capacity",function()
  local e=Economy.new();e:open(1,state());local before=e:get(1)
  assert(D.offer(before,"hospital").available and D.armyCapacity(before)==1)
  local r=e:upgrade(1,0,"hospital");assert(r.ok and r.state.coins==800 and r.state.hospitalLevel==1)
  assert(r.state.armyCampLevel==0 and D.armyCapacity(r.state)==2)
  assert(e:upgrade(1,0,"hospital").reason=="stale_level")
  assert(not D.offer(e:get(1),"hospital").available)
  for _,field in D.persistentFields do if field~="coins" and field~="hospitalLevel" then assert(before[field]==r.state[field]) end end
 end)
 test("hospital rejects locked training funds and lost authority without mutation",function()
  for _,reason in {"settlement_locked","prerequisite","insufficient_funds","profile_unavailable"} do
   local s=state();if reason=="settlement_locked" then s.level=9 elseif reason=="prerequisite" then s.trainingLevel=0 elseif reason=="insufficient_funds" then s.coins=199 end
   local e=Economy.new(nil,function()return reason~="profile_unavailable" end);e:open(1,s)
   assert(e:upgrade(1,0,"hospital").reason==reason);assert(e:get(1).coins==s.coins and e:get(1).hospitalLevel==0)
  end
 end)
 test("hospital and original fifteen values survive fake-store release across civilizations",function()
  local Store=require(game.ServerStorage.RuntimeTests.FakeProfileStore)
  local Profiles=require(game.ServerScriptService.Game.ProfileService)
  local store=Store.new();local t=100
  local function options(id)return {clock=function()return t end,wait=function()end,sessionId=id,newToken=function()return id end}end
  local a=state();a.level=50;a.weaponLevel=50;a.armorLevel=37;a.barracksLevel=6;a.farmLevel=2;a.workersLevel=2;a.armyCampLevel=1;a.extraTroopClass="ranged";a.farmCoins=170;a.storehouseLevel=1;a.blacksmithLevel=1;a.armorerLevel=1;a.skillLevel=5;a.hospitalLevel=1
  local b=state()
  local first=Profiles.new(store,options("medical-first"));assert(first:load(101).ok)
  assert(first:set(101,"sparta",a) and first:set(101,"britain",b));assert(first:release(101).ok);t+=5
  local second=Profiles.new(store,options("medical-second"));assert(second:load(101).ok)
  local e=Economy.new();e:open(101,second:get(101,"sparta"))
  for id,expected in {sparta=a,britain=b} do
   local actual=second:get(101,id);assert(e:replace(101,actual))
   for _,field in D.persistentFields do assert(actual[field]==expected[field] and e:get(101)[field]==expected[field],field) end
  end
  assert(second:release(101).ok)
 end)
 return n
end

return function()
 local G=game.ServerScriptService.Game;local Data=require(G.ProfileData);local Economy=require(G.Economy)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 test('fixed Studio test grants require writable progress and preserve independent balances',function()
  local time,writable=100,true
  local E=Economy.new(function()return time end,function()return writable end,nil,function()return true end)
  assert(E:open(1,Data.defaultState()) and E:open(2,Data.defaultState()))
  assert(E:grantTestCoins(1,100000000).ok and E:get(1).coins==1000 and E:get(2).coins==0)
  assert(E:grantTestCoins(1).reason=='rate_limited');time+=.5
  assert(E:grantTestCoins(1).ok and E:get(1).coins==2000)
  writable=false;time+=1;assert(E:grantTestCoins(1).reason=='profile_unavailable' and E:get(1).coins==2000)
  assert(E:grantTestCoins(3).reason=='not_claimed')
 end)
 test('disabled environments reject direct testing grants even with valid profiles',function()
  local E=Economy.new(function()return 100 end,nil,nil,function()return false end)
  assert(E:open(1,Data.defaultState()))
  assert(E:grantTestCoins(1).reason=='testing_disabled' and E:get(1).coins==0)
 end)
 test('testing grants preserve the balance cap without partial or overflowing awards',function()
  local s=Data.defaultState();s.coins=999999001
  local E=Economy.new(function()return 100 end,nil,nil,function()return true end);assert(E:open(1,s))
  assert(E:grantTestCoins(1).reason=='coin_limit' and E:get(1).coins==999999001)
  s.coins=999999000;assert(E:replace(1,s))
  assert(E:grantTestCoins(1).ok and E:get(1).coins==1000000000)
 end)
 return n
end

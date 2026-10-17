return function()
 local Crowd=require(game.ServerScriptService.Game.CrowdMovement)
 local n=0
 local function test(name,fn)fn();n+=1;print("PASS: "..name)end
 local function actor(id,x,z)
  return {rig={Name=id,GetAttribute=function()return id end},ownerId=1,kind="warrior",position=Vector3.new(x,0,z),velocity=Vector3.zero}
 end
 local function clear(p)return p end
 test("a clear route preserves its intended destination",function()
  local a=actor("a",0,0);local goal=Vector3.new(20,0,0)
  assert(Crowd.choose(a,{},goal,12,clear)==goal)
 end)
 test("allied and enemy bodies both cause a clear passing step",function()
  for _,owner in {1,2}do
   local a,b=actor("a",0,0),actor("b",4,0);b.ownerId=owner
   local p=Crowd.choose(a,{b},Vector3.new(20,0,0),12,clear)
   assert(p and math.abs(p.Z)>1 and (p-b.position).Magnitude>=3.2)
  end
 end)
 test("fully blocked traffic yields rather than walking through a body",function()
  local a,b=actor("a",0,0),actor("b",3.5,0)
  assert(not Crowd.choose(a,{b},Vector3.new(20,0,0),12,function()return nil end))
 end)
 test("coincident troops choose finite opposing escape directions",function()
  local a,b=actor("a",0,0),actor("b",0,0)
  local pa=Crowd.choose(a,{b},Vector3.new(20,0,0),12,clear)
  local pb=Crowd.choose(b,{a},Vector3.new(20,0,0),12,clear)
  assert(pa and pb and pa:Dot(pb)<0)
 end)
 test("traffic on another floor never blocks the route",function()
  local a,b=actor("a",0,0),actor("b",3,0);b.position+=Vector3.new(0,12,0)
  local goal=Vector3.new(20,0,0);assert(Crowd.choose(a,{b},goal,12,clear)==goal)
 end)
 return n
end

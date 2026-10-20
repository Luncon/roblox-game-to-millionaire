return function()
 local G=game.ServerScriptService.Game;local S=game.ReplicatedStorage.Shared
 local Volley=require(G:FindFirstChild('SenecaVolley'));local F=require(G.ArmyFormation);local Config=require(S.FormationConfig)
 local n=0;local function test(name,fn)fn();n+=1;print('PASS: '..name)end
 local function setup()
  local a={};for id,kind in Config.rolesFor(Config.forCivilization('seneca'))do
   local rig={Name=id,GetAttribute=function()return id end}
   a[id]={rig=rig,humanoid={},alive=true,kind=kind,ownerId=101,claimed=true,position=Vector3.zero,phase='idle'}
  end
  local g=F.new(Vector3.zero,Vector3.new(0,0,-100),a,Config.forCivilization('seneca'))
  for id,p in F.goals(g,function(v)return v end)do a[id].position=p end
  local foe={rig={Name='enemy',GetAttribute=function()return 'enemy'end},humanoid={},alive=true,kind='warrior',ownerId=202,claimed=true,position=Vector3.new(0,0,-25)}
  return g,a,foe
 end
 local Rules=require(G.CombatRules)
 local function valid(a,b)return Rules.hostile(a,b) and (a.position-b.position).Magnitude<=45 end
 test('shared focus is current hostile shootable by captured archers and retained against closer distractions',function()
  local g,a,foe=setup();assert(Volley.choose(g,a,{foe},valid,40)==foe)
  local distraction=table.clone(foe);distraction.rig={Name='closer',GetAttribute=function()return 'closer'end};distraction.position=Vector3.new(0,0,-10)
  assert(Volley.choose(g,a,{distraction,foe},valid,45)==foe)
  foe.alive=false;assert(Volley.choose(g,a,{foe,distraction},valid,45)==distraction)
  assert(Volley.choose(g,a,{distraction},function()return false end,45)==nil and not g.focus)
 end)
 test('focus ignores allies outside range and lost or replaced archer lives including Humanoid identity',function()
  local g,a,foe=setup();foe.ownerId=101;assert(not Volley.choose(g,a,{foe},valid,45));foe.ownerId=202
  foe.position=Vector3.new(0,0,-100);assert(not Volley.choose(g,a,{foe},valid,45));foe.position=Vector3.new(0,0,-20)
  for _,id in {'camp','ranged','reinforcement'}do a[id].humanoid={}end
  assert(not Volley.choose(g,a,{foe},valid,45))
  assert(not Volley.choose(g,a,{foe},function()return true end,45),'Guard or medic chose a ranged focus')
 end)
 test('a surviving flank archer can deploy and focus when the center archer is lost',function()
  local g,a,foe=setup();a.ranged=nil;g.members.ranged=nil
  assert(Volley.choose(g,a,{foe},valid,40)==foe)
  a.camp=nil;g.members.camp=nil;assert(Volley.choose(g,a,{foe},valid,40)==foe)
 end)
 test('focus target Humanoid replacements are independently revalidated',function()
  local g,a,foe=setup();assert(Volley.choose(g,a,{foe},valid,40)==foe)
  local replacement=table.clone(foe);replacement.humanoid={}
  assert(not Volley.choose(g,a,{replacement},function()return false end,40) and not g.focus)
  assert(Volley.choose(g,a,{replacement},valid,40)==replacement and g.focus.humanoid==replacement.humanoid)
 end)
 test('shared shot reservation spaces starts without resetting on focus loss',function()
  local g,a,foe=setup();assert(Volley.ready(g,0));assert(Volley.started(g,0))
  assert(not Volley.ready(g,.449) and not Volley.started(g,.449))
  assert(Volley.ready(g,.45) and Volley.started(g,.45))
  Volley.choose(g,a,{},valid,45);assert(not Volley.ready(g,.8) and Volley.ready(g,.9))
  assert(Volley.choose(g,a,{foe},valid,45)==foe and not Volley.ready(g,.8))
 end)
 return n
end

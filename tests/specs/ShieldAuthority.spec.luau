-- Only connected-owner lookup is replaced; contacts, skills, rays and health are native.
return function()
 local Game=game.ServerScriptService.Game
 local Combat=require(Game.CombatService)
 local Shield=require(Game.ShieldCombat)
 local Rig=require(Game.WarriorRig)
 local Equipment=require(Game.Equipment)
 local civs={};for _,c in require(game.ReplicatedStorage.Shared.Civilizations)do civs[c.id]=c end
 local world={model=Instance.new('Model')};world.model.Name='ShieldAuthorityFixture'
 local arena=Instance.new('Part');arena.Name='Battlefield';arena.Shape=Enum.PartType.Cylinder
 arena.Size=Vector3.new(2,500,500);arena.CFrame=CFrame.new(0,10000,0)*CFrame.Angles(0,0,math.pi/2)
 arena.Anchored=true;arena.CanCollide=false;arena.CanQuery=false;arena.Parent=world.model
 local troops=Instance.new('Folder');troops.Name='Troops';troops.Parent=world.model;world.model.Parent=workspace
 local time=0;local actors={};local state={weaponLevel=10,armorLevel=15,shieldLevel=1,trainingLevel=1,skillLevel=1}
 local economy={get=function()return state end,canMutate=function()return true end}
 local combat=Combat.new(world,{},economy,nil,function()return time end)
 combat.actor=function(_,rig)return actors[rig]end
 combat.actors=function()local list={};for _,a in actors do table.insert(list,a)end;return list end
 local function make(civ,kind,x,z,owner)
  local p=Vector3.new(x or 0,10004,z or 0)
  local r=Rig.create(civs[civ],CFrame.new(p),owner or 1,1,state,'warrior')
  r.HumanoidRootPart.Anchored=true;r.Parent=troops
  actors[r]={ownerId=owner or 1,kind=kind or 'warrior',civilizationId=civ,plotId=1,claimed=true,alive=true,
   rig=r,root=r.HumanoidRootPart,humanoid=r.Humanoid,position=p}
  Shield.refresh(r,civ,kind or 'warrior',state)
  return r
 end
 local function reset()troops:ClearAllChildren();table.clear(actors);time+=20 end
 local n=0;local function test(name,fn)reset();fn();n+=1;print('PASS: '..name)end
 local ok,result=pcall(function()
  test('native frontal contacts consume exactly two shields with no hit flash or duplicate cooldown block',function()
   for _,kind in {'warrior','player'}do
    reset();local a,b=make('britain','warrior',0,-4,2),make('sparta',kind)
    local health=b.Humanoid.Health
    assert(combat:hit(a,b).blocked and b.Humanoid.Health==health and b:GetAttribute('ShieldCharges')==1)
    assert(not combat:hit(a,b).ok and b:GetAttribute('ShieldCharges')==1)
    assert(b:GetAttribute('LastHitAt')==nil)
    time+=2;assert(combat:hit(a,b).blocked and b:GetAttribute('ShieldCharges')==0)
    for _,item in b:GetDescendants()do assert(item:GetAttribute('CombatShield')~=true,'Broken visual remained')end
    time+=2;assert(combat:hit(a,b).damage>0 and b.Humanoid.Health<health)
   end
  end)
  test('native side and rear hits bypass charges and equipment refresh cannot restore a broken shield',function()
   for _,p in {Vector3.new(4,0,0),Vector3.new(0,0,4)}do
    reset();local a,b=make('britain','warrior',p.X,p.Z,2),make('sparta')
    assert(combat:hit(a,b).damage>0 and b:GetAttribute('ShieldCharges')==2)
   end
   reset();local a,b=make('britain','warrior',0,-4,2),make('sparta')
   assert(combat:hit(a,b).blocked);time+=2;assert(combat:hit(a,b).blocked)
   assert(Equipment.applyWarrior(b,civs.sparta,state))
   assert(b:GetAttribute('ShieldCharges')==0)
   local fresh=make('sparta','warrior',20,0);assert(fresh:GetAttribute('ShieldCharges')==2)
  end)
  test('friendly distant protected obstructed and forcefield contacts preserve shield charges',function()
   local a,b=make('britain','warrior',0,-4,1),make('sparta')
   assert(not combat:hit(a,b).ok);actors[a].ownerId=2
   actors[a].position=Vector3.new(0,10004,-40);assert(not combat:hit(a,b).ok)
   actors[a].position=Vector3.new(400,10004,0);assert(not combat:hit(a,b).ok)
   actors[a].position=a.HumanoidRootPart.Position
   local wall=Instance.new('Part');wall.Size=Vector3.new(10,10,1);wall.CFrame=CFrame.new(0,10004,-2)
   wall.Anchored=true;wall.Parent=world.model
   assert(not combat:hit(a,b).ok);wall:Destroy()
   local force=Instance.new('ForceField');force.Parent=b
   assert(not combat:hit(a,b).ok and b:GetAttribute('ShieldCharges')==2)
  end)
  test('native sword skill contacts share protection and resolve each contact once',function()
   local a,b=make('britain','warrior',0,-4,2),make('sparta')
   a:PivotTo(CFrame.lookAt(a.HumanoidRootPart.Position,b.HumanoidRootPart.Position))
   local health=b.Humanoid.Health
   assert(combat.skills:activate(a,'hold',false).ok and b:GetAttribute('ShieldCharges')==1)
   combat.skills:step();assert(b:GetAttribute('ShieldCharges')==1)
   time+=.24;combat.skills:step()
   assert(b:GetAttribute('ShieldCharges')==0 and b.Humanoid.Health==health)
   combat.skills:step();assert(b:GetAttribute('ShieldCharges')==0)
  end)
  return n
 end)
 combat:destroy();world.model:Destroy();assert(ok,result);return result
end

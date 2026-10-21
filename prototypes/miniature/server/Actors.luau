--!strict
local Config=require(game.ReplicatedStorage.Miniature.Config)
local Rig=require(game.ServerScriptService.Game.WarriorRig)
local Tenders=require(game.ServerScriptService.Game.FarmTenders)
local Actors={}
local function sample(route,distance)
 local length=0
 for i,a in route do length+=(route[i%#route+1]-a).Magnitude end
 local remaining=distance%length
 for i,a in route do
  local b=route[i%#route+1];local segment=(b-a).Magnitude
  if remaining<=segment then return a:Lerp(b,remaining/segment),(b-a).Unit end
  remaining-=segment
 end
 error('Route must contain distinct points')
end
local function soldier(parent,civ,index)
 local kind=if index==4 then 'ranged'else 'warrior'
 local model=Rig.create(civ,CFrame.identity,0,0,{weaponLevel=1,armorLevel=1,shieldLevel=1},kind)
 model.Name='Soldier'..index;model:SetAttribute('PreviewRole','soldier')
 model:ScaleTo(Config.scale)
 local root=model.HumanoidRootPart;local hum=model:FindFirstChildOfClass('Humanoid')
 hum.EvaluateStateMachine=false;hum.AutoRotate=false;hum.WalkSpeed=0
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local joints={}
 for _,item in model:GetDescendants()do
  if item:IsA('BasePart')then item.Anchored=item==root;item.CanCollide=false;item.CanTouch=false;item.CanQuery=false;item.CollisionGroup='MiniatureActors'
  elseif item:IsA('Motor6D')then joints[item]=item.C0 end
 end
 local foot=math.huge
 for _,name in {'Left Leg','Right Leg'}do
  local p=model[name];foot=math.min(foot,root.CFrame:PointToObjectSpace(p.Position).Y-p.Size.Y/2)
 end
 model.Parent=parent
 return function(t)
  local point,direction=sample(Config.patrol,t*Config.walkSpeed+(index-1)*2.2)
  model:PivotTo(CFrame.lookAt(point+Vector3.new(0,-foot,0),point+Vector3.new(0,-foot,0)+direction))
  local gait=math.sin(t*9+index)*.45
  for joint,rest in joints do
   local angle=if joint.Name=='Right Hip'then gait elseif joint.Name=='Left Hip'then -gait
    elseif joint.Name=='Right Shoulder'then .35-gait*.2 elseif joint.Name=='Left Shoulder'then gait*.3 else 0
   joint.C0=rest*CFrame.Angles(angle,0,0)
  end
 end
end
local function worker(parent,index)
 local template=game.ServerStorage.FarmTemplates.farmer:Clone()
 template:ScaleTo(Config.scale)
 local model=Tenders.prepare(template);template:Destroy()
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then p.CollisionGroup='MiniatureActors'end end
 model.Name='Worker'..index;model:SetAttribute('PreviewRole','worker');model.Parent=parent
 local z=-8+(index-1)*4
 local route={Vector3.new(6,Config.groundY+.18,z),Vector3.new(10,Config.groundY+.18,z)}
 return function(t)
  local clock=(t+(index-1)*2)%10
  local working=clock<3 or clock>=3+4/Config.workerSpeed
  local distance=math.clamp((clock-3)*Config.workerSpeed,0,4)
  -- Complete the return during the second half of each twenty-second cycle.
  local returning=math.floor((t+(index-1)*2)/10)%2==1
  if returning then distance=4-distance end
  local point,direction=sample(route,distance)
  if returning then direction=-direction end
  Tenders.pose(model,CFrame.lookAt(point,point+direction),math.sin(t*(if working then 4 else 9))*.5,working)
 end
end
function Actors.start(scene)
 local physics=game:GetService('PhysicsService')
 if not physics:IsCollisionGroupRegistered('MiniatureActors')then physics:RegisterCollisionGroup('MiniatureActors')end
 physics:CollisionGroupSetCollidable('MiniatureActors','Default',false)
 physics:CollisionGroupSetCollidable('MiniatureActors','MiniatureActors',false)
 local civ=require(game.ReplicatedStorage.Shared.Civilizations)[1]
 local animate={}
 for i=1,4 do table.insert(animate,soldier(scene.Actors,civ,i))end
 for i=1,2 do table.insert(animate,worker(scene.Actors,i))end
 local began=os.clock()
 for _,step in animate do step(0)end
 local elapsed=0
 local connection=game.RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
  for _,step in animate do step(os.clock()-began)end
 end)
 scene.Destroying:Once(function()connection:Disconnect()end)
end
return Actors

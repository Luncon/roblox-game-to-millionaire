--!strict
local Config=require(game.ReplicatedStorage.Miniature.Config)
local World={}
local cream=Color3.fromRGB(213,199,160)
local red=Color3.fromRGB(151,64,42)
local wood=Color3.fromRGB(105,75,46)
local function part(parent,name,size,position,color,material,solid)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=false
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
 return p
end
local function roof(model,width,depth,y)
 for _,side in {-1,1}do
  local p=part(model,'TerracottaRoof',Vector3.new(width/2+1,1,depth+2),Vector3.new(side*width/4,y,0),red,Enum.Material.Slate)
  p.CFrame*=CFrame.Angles(0,0,-side*math.rad(22))
 end
end
local function facade(model,width,depth,height)
 part(model,'Plinth',Vector3.new(width+2,1,depth+2),Vector3.new(0,.5,0),cream,Enum.Material.Limestone)
 part(model,'Walls',Vector3.new(width,height,depth),Vector3.new(0,1+height/2,0),cream,Enum.Material.Plaster)
 part(model,'Door',Vector3.new(3,5,.15),Vector3.new(0,3.5,depth/2+.1),wood,Enum.Material.Wood)
 for _,x in {-width*.3,width*.3}do
  part(model,'Window',Vector3.new(2,2,.2),Vector3.new(x,5,depth/2+.15),Color3.fromRGB(43,59,61))
 end
 roof(model,width,depth,height+2)
end
local function building(parent,id)
 local data=Config.buildings[id];local model=Instance.new('Model');model.Name=id
 model.WorldPivot=CFrame.identity
 if id=='farm'then
  part(model,'Soil',Vector3.new(26,.7,22),Vector3.new(0,.35,0),Color3.fromRGB(112,81,48),Enum.Material.Ground)
  for row=-2,2 do for col=-5,5 do
   local p=Vector3.new(col*2,.9,row*4)
   part(model,'GrainStalk',Vector3.new(.3,2.4,.3),p+Vector3.new(0,1.2,0),Color3.fromRGB(183,156,74))
   part(model,'GrainHead',Vector3.new(.7,.9,.7),p+Vector3.new(0,2.4,0),Color3.fromRGB(227,188,80))
  end end
  for _,x in {-14,14}do
   part(model,'Fence',Vector3.new(.5,2,24),Vector3.new(x,1,0),wood,Enum.Material.Wood)
  end
 elseif id=='house'then facade(model,16,14,8)
 else
  facade(model,24,16,9)
  for _,x in {-9,9}do part(model,'Column',Vector3.new(1.5,9,1.5),Vector3.new(x,5.5,11),cream,Enum.Material.Marble)end
  part(model,'Portico',Vector3.new(26,1,5),Vector3.new(0,10,10),cream)
  local banner=part(model,'Banner',Vector3.new(3,6,.2),Vector3.new(0,6,8.3),red,Enum.Material.Fabric)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.Parent=banner
  local mark=Instance.new('TextLabel');mark.Size=UDim2.fromScale(1,1);mark.BackgroundTransparency=1
  mark.Text='Λ';mark.TextColor3=Color3.fromRGB(235,211,148);mark.TextScaled=true;mark.Font=Enum.Font.GothamBold;mark.Parent=gui
 end
 model:ScaleTo(Config.scale);model:PivotTo(CFrame.new(data.position));model.Parent=parent
 model:SetAttribute('DisplayName',data.name);model:SetAttribute('Description',data.description)
 local cf,size=model:GetBoundingBox()
 local target=part(model,'SelectTarget',size+Vector3.new(.6,.6,.6),cf.Position,cream)
 target.Transparency=1;target.CanQuery=true
 local detector=Instance.new('ClickDetector');detector.MaxActivationDistance=80;detector.Parent=target
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Inspect';prompt.ObjectText=data.name
 prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=target
 return model
end
function World.create()
 assert(not workspace:FindFirstChild('MiniaturePreview'),'Preview is already running')
 local scene=Instance.new('Model');scene.Name='MiniaturePreview'
 part(scene,'Ground',Vector3.new(160,1,120),Vector3.new(0,-.5,0),Color3.fromRGB(107,133,88),Enum.Material.Grass,true)
 part(scene,'Plot',Config.plotSize,Vector3.new(0,.2,0),Color3.fromRGB(142,153,105),Enum.Material.Grass,true)
 part(scene,'CrossRoad',Vector3.new(40,.05,3),Vector3.new(0,.425,1),Color3.fromRGB(188,170,132),Enum.Material.Pebble)
 part(scene,'MainRoad',Vector3.new(3,.05,40),Vector3.new(0,.425,4),Color3.fromRGB(188,170,132),Enum.Material.Pebble)
 for _,z in {-16,16}do part(scene,'PlotEdge',Vector3.new(40,.15,.25),Vector3.new(0,.45,z),cream)end
 for _,x in {-20,20}do part(scene,'PlotEdge',Vector3.new(.25,.15,32),Vector3.new(x,.45,0),cream)end
 local buildings=Instance.new('Folder');buildings.Name='Buildings';buildings.Parent=scene
 for _,id in {'house','farm','barracks'}do building(buildings,id)end
 local actors=Instance.new('Folder');actors.Name='Actors';actors.Parent=scene
 local spawn=Instance.new('SpawnLocation');spawn.Name='CommanderSpawn';spawn.Size=Vector3.new(6,.2,6)
 spawn.Position=Vector3.new(0,.1,24);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false
 spawn.Neutral=true;spawn.Duration=0;spawn.Parent=scene
 scene:SetAttribute('Scale',Config.scale);scene.Parent=workspace
 return scene
end
return World

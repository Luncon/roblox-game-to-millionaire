--!strict
local Sites=require(game.ReplicatedStorage.Shared.SettlementSites)
local Config=require(game.ReplicatedStorage.Shared.FormationConfig)
local Room={}

function Room.build(parent,frame,civ)
 local room=Instance.new('Model');room.Name='WarCouncil';room.Parent=parent
 room:SetAttribute('CivilizationId',civ.id)
 local origin=frame*CFrame.new(Sites.warCouncil)
 local function part(name,size,offset,color,solid,material)
  local p=Instance.new('Part');p.Name,p.Size,p.CFrame=name,size,origin*CFrame.new(offset)
  p.Color,p.Material=color,material or Enum.Material.WoodPlanks
  p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,solid==true,solid==true,false;p.Parent=room
  return p
 end
 local wood,stone=Color3.fromRGB(103,77,49),Color3.fromRGB(151,145,123)
 part('Floor',Vector3.new(24,.3,20),Vector3.new(0,-.7,0),stone,true,Enum.Material.Slate)
 for _,side in {-1,1}do
  part('SideWall',Vector3.new(.8,10,20),Vector3.new(side*11.6,4.45,0),wood,true)
  part('CouncilColors',Vector3.new(.1,4,5),Vector3.new(side*11.1,5,1),civ.color,false,Enum.Material.Fabric)
 end
 part('BackWall',Vector3.new(24,10,.8),Vector3.new(0,4.45,9.6),wood,true)
 part('Roof',Vector3.new(26,.6,22),Vector3.new(0,9.75,0),civ.color,true)
 part('TableTop',Vector3.new(8,.5,6),Vector3.new(0,2.5,0),wood,true)
 for _,x in {-3,3}do for _,z in {-2,2}do
  part('TableLeg',Vector3.new(.5,3,.5),Vector3.new(x,1,z),wood,true)
 end end
 local map=part('MapTable',Vector3.new(7,.08,5),Vector3.new(0,2.79,0),Color3.fromRGB(208,191,144),false)
 map.CanQuery=true
 part('MapRoad',Vector3.new(.3,.02,4.8),Vector3.new(0,2.84,0),Color3.fromRGB(138,115,70),false)
 for id,offset in Config.offsets do
  local support=id=='ranged' or id=='medic'
  part('MapTroop_'..id,Vector3.new(.55,.2,.55),Vector3.new(offset.X*.24,2.96,offset.Z*.24-.6),
   if support then Color3.fromRGB(229,222,189) else civ.color,false)
 end
 local sign=part('CouncilSign',Vector3.new(20,2,.2),Vector3.new(0,8,-10.1),wood,false)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(800,100);gui.Parent=sign
 local label=Instance.new('TextLabel');label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1)
 label.Text='WAR COUNCIL I';label.TextScaled=true;label.Font=Enum.Font.GothamBold
 label.TextColor3=Color3.fromRGB(255,239,191);label.Parent=gui
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Plan Formation';prompt.ObjectText='War Council Map'
 prompt.HoldDuration=0;prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.Parent=map
 local click=Instance.new('ClickDetector');click.MaxActivationDistance=14;click.Parent=map
 return room
end
return Room

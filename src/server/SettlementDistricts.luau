--!strict

local Progression = require(game:GetService("ReplicatedStorage").Shared.SettlementProgression)
local Config = require(game:GetService("ReplicatedStorage").Shared.ProgressionConfig)
local Sites = require(game:GetService("ReplicatedStorage").Shared.SettlementSites)
local Camp = require(game:GetService("ReplicatedStorage").Shared.TrainingCampConfig)
local Districts = {}
local STONE = Color3.fromRGB(219, 202, 165)
local WOOD = Color3.fromRGB(113, 75, 43)
local GOLD = Color3.fromRGB(211, 169, 65)
local styles = {
	sparta={family="classical",name="Spartan sanctuary and training courts",landmark="Acropolis",material=Enum.Material.Sandstone},
	britain={family="brick",name="Georgian avenues and regimental gardens",landmark="RoyalAssembly",material=Enum.Material.Brick},
	seneca={family="longhouse",name="Bark longhouses and council village",landmark="GreatCouncilLonghouse",material=Enum.Material.WoodPlanks},
	mongols={family="yurt",name="Steppe yurts and khan's encampment",landmark="GreatKhanPavilion",material=Enum.Material.Fabric},
	vikings={family="longhouse",name="Carved timber halls and runestones",landmark="JarlsGreatHall",material=Enum.Material.WoodPlanks},
	persia={family="classical",name="Glazed colonnades and palace terraces",landmark="Apadana",material=Enum.Material.Sandstone},
	japan={family="pagoda",name="Sengoku castle courts and roofed gates",landmark="GreatTenshu",material=Enum.Material.Plaster},
	maurya={family="dome",name="Sandstone pillars and stupa precincts",landmark="MauryanAssembly",material=Enum.Material.Sandstone},
	spain={family="stucco",name="Arcaded plazas and tiled civic halls",landmark="GrandAlcazar",material=Enum.Material.Plaster},
	egypt={family="pylon",name="Pylon temples and obelisk avenues",landmark="GreatHypostyleTemple",material=Enum.Material.Sandstone},
	rome={family="classical",name="Forums and tiled civic basilicas",landmark="ImperialBasilica",material=Enum.Material.Marble},
	ottomans={family="dome",name="Tiled domed courts and minarets",landmark="ImperialCourtyard",material=Enum.Material.Marble},
	ming={family="pagoda",name="Vermilion palace courts and golden roofs",landmark="HallOfHarmony",material=Enum.Material.WoodPlanks},
}

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?, solid: boolean?): Part
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame = name, size, frame
	object.Color, object.Material = color, material or Enum.Material.Sandstone
	object.Anchored, object.CanCollide = true, solid == true
	object.CanTouch, object.CanQuery = false, solid == true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function roof(parent: Instance, frame: CFrame, width: number, depth: number, tint: Color3)
	for _, side in {-1,1} do
		part(parent,"RoofSlope",Vector3.new(width/2+1,1,depth+2),
			frame*CFrame.new(side*width/4,0,0)*CFrame.Angles(0,0,-side*.4),tint,Enum.Material.WoodPlanks)
	end
end

local function house(parent: Instance, frame: CFrame, civ, width: number, name: string)
	local style, family = styles[civ.id], styles[civ.id].family
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	model:SetAttribute("Architecture",civ.id)
	local wall = if family=="longhouse" then WOOD elseif family=="brick" then Color3.fromRGB(163,87,66) else STONE
	if civ.id=="ming" then wall=Color3.fromRGB(165,47,39) end
	local h = width*.42
	local function piece(label: string, size: Vector3, position: Vector3, tint: Color3?, material: Enum.Material?, solid: boolean?)
		return part(model,label,size,frame*CFrame.new(position),tint or wall,material or style.material,solid)
	end
	if family=="yurt" then
		local tent=piece("FeltYurt",Vector3.new(h,width*.85,width*.85),Vector3.new(0,2+h/2,0),Color3.fromRGB(229,216,180),nil,true)
		tent.Shape=Enum.PartType.Cylinder
		tent.CFrame*=CFrame.Angles(0,0,math.pi/2)
		piece("WovenRoof",Vector3.new(width,1,width),Vector3.new(0,h+2.6,0),civ.color)
		piece("SmokeVent",Vector3.new(width*.2,1.5,width*.2),Vector3.new(0,h+3.5,0),WOOD)
		piece("ClanStandard",Vector3.new(.5,h+3,.5),Vector3.new(width*.43,2+h/2,-width*.4),GOLD)
	elseif family=="longhouse" then
		piece("TimberHall",Vector3.new(width*.75,h,width),Vector3.new(0,2+h/2,0),nil,nil,true)
		roof(model,frame*CFrame.new(0,h+3,0),width*.85,width,if civ.id=="seneca" then WOOD else civ.color)
		for _, z in {-width/2,width/2} do
			piece("CarvedEndPost",Vector3.new(width*.08,h+5,width*.08),Vector3.new(0,2+(h+5)/2,z),civ.color)
		end
		local shield=piece(if civ.id=="vikings" then "RoundShield" else "WovenWallPanel",Vector3.new(width*.2,width*.2,.25),Vector3.new(width*.24,h*.65+2,-width/2-.15),civ.color)
		if civ.id=="vikings" then shield.Shape=Enum.PartType.Ball end
	elseif family=="dome" then
		piece("AssemblyBase",Vector3.new(width,h,width*.7),Vector3.new(0,2+h/2,0),nil,nil,true)
		local dome=piece("Dome",Vector3.new(width*.82,width*.52,width*.65),Vector3.new(0,h+2,0),civ.color)
		dome.Shape=Enum.PartType.Ball
		piece("Finial",Vector3.new(.7,width*.2,.7),Vector3.new(0,h+width*.29+2,0),GOLD)
		for _, side in {-1,1} do
			piece(if civ.id=="ottomans" then "Minaret" else "LionPillar",Vector3.new(width*.08,h+4,width*.08),Vector3.new(side*width*.45,2+(h+4)/2,0),nil,nil,true)
			local cap=piece(if civ.id=="ottomans" then "MinaretCap" else "LionCapital",Vector3.new(width*.13,2,width*.13),Vector3.new(side*width*.45,h+6,0),GOLD)
			if civ.id=="ottomans" then cap.Shape=Enum.PartType.Ball end
		end
	elseif family=="pagoda" then
		piece("LacquerHall",Vector3.new(width*.8,h,width*.8),Vector3.new(0,2+h/2,0),if civ.id=="ming" then wall else STONE,nil,true)
		local tint=if civ.id=="ming" then GOLD else civ.color
		piece("OverhangingRoof",Vector3.new(width+2,1.2,width+2),Vector3.new(0,h+3,0),tint,Enum.Material.Slate)
		for _, side in {-1,1} do
			part(model,"UpturnedEave",Vector3.new(2,1.2,width+2),frame*CFrame.new(side*(width/2-.25),h+3.5,0)*CFrame.Angles(0,0,side*.3),tint,Enum.Material.Slate)
			piece("LacquerPillar",Vector3.new(.8,h,.8),Vector3.new(side*width*.32,2+h/2,-width*.42),civ.color)
		end
	elseif family=="pylon" then
		piece("Sanctuary",Vector3.new(width,h,width*.7),Vector3.new(0,2+h/2,0),nil,nil,true)
		for _, side in {-1,1} do
			piece("Pylon",Vector3.new(width*.16,h+5,width*.14),Vector3.new(side*width*.32,2+(h+5)/2,-width*.38),nil,nil,true)
		end
		piece("PaintedLintel",Vector3.new(width*.84,1.3,width*.18),Vector3.new(0,h+5,-width*.38),civ.color)
		piece("RoofCornice",Vector3.new(width+1,1,width*.72),Vector3.new(0,h+2.5,0),civ.color)
	elseif family=="classical" then
		piece("Podium",Vector3.new(width+1,1,width*.8),Vector3.new(0,2.5,0))
		piece("CivicChamber",Vector3.new(width*.82,h,width*.7),Vector3.new(0,3+h/2,0),nil,nil,true)
		for _, side in {-1,1} do
			piece("Column",Vector3.new(width*.07,h,width*.07),Vector3.new(side*width*.35,3+h/2,-width*.42),nil,nil,true)
		end
		piece("PaintedEntablature",Vector3.new(width+2,1.5,width*.9),Vector3.new(0,h+3.5,0),if civ.id=="persia" then Color3.fromRGB(49,101,135) else civ.color)
		if civ.id=="sparta" then roof(model,frame*CFrame.new(0,h+5,0),width,width*.8,civ.color)
		elseif civ.id=="rome" then piece("CivicArchHeader",Vector3.new(width*.5,1.5,2),Vector3.new(0,h+1.5,-width*.43),STONE)
		else
			for _, side in {-1,1} do piece("BullCapital",Vector3.new(width*.13,1.7,width*.12),Vector3.new(side*width*.35,h+3,-width*.42),GOLD) end
		end
	else
		piece("CivicHouse",Vector3.new(width,h,width*.7),Vector3.new(0,2+h/2,0),nil,nil,true)
		roof(model,frame*CFrame.new(0,h+3,0),width,width*.8,civ.color)
		for _, side in {-1,1} do
			piece(if family=="brick" then "WhiteSashWindow" else "ArcadePier",Vector3.new(width*.16,if family=="brick" then h*.4 else h,if family=="brick" then .25 else 1),
				Vector3.new(side*width*.3,2+h*.6,-width*.36),if family=="brick" then Color3.fromRGB(191,218,221) else STONE)
		end
		piece(if family=="brick" then "Chimney" else "BellTurret",Vector3.new(1.7,4,1.7),Vector3.new(width*.3,h+4,0),if family=="brick" then wall else GOLD)
	end
	return model
end

local function garden(parent: Instance, frame: CFrame, civ, width: number)
	part(parent,"CultivatedGround",Vector3.new(width,.2,6),frame*CFrame.new(0,2.12,0),Color3.fromRGB(79,115,61),Enum.Material.Grass)
	for _, side in {-1,1} do
		part(parent,if civ.id=="seneca" then "ThreeSistersBed" else "GardenBed",Vector3.new(width*.35,.6,2),frame*CFrame.new(side*width*.25,2.5,0),Color3.fromRGB(104,147,65),Enum.Material.LeafyGrass)
	end
end

local function monument(parent: Instance, frame: CFrame, civ, tall: boolean?)
	local h=if tall then 17 else 8
	part(parent,"CeremonialPlinth",Vector3.new(6,1,6),frame*CFrame.new(0,2.5,0),STONE)
	local id=civ.id
	local label=if id=="egypt" then "Obelisk" elseif id=="seneca" then "CouncilCarving"
		elseif id=="vikings" then "Runestone" elseif id=="mongols" then "KhanStandard" else "CeremonialColumn"
	part(parent,label,Vector3.new(2,h,2),frame*CFrame.new(0,3+h/2,0),if id=="seneca" or id=="vikings" then WOOD else civ.color,
		if id=="seneca" or id=="vikings" then Enum.Material.Wood else Enum.Material.Sandstone)
	local crown=part(parent,if id=="maurya" then "LionCapital" else "CivicEmblem",Vector3.new(3,2,3),frame*CFrame.new(0,h+4,0),GOLD)
	if id=="maurya" or id=="ottomans" then crown.Shape=Enum.PartType.Ball end
end

-- Stable lots exclude the starter core, future grand hall and permanent exit.
local lots = {}
local extent=math.floor((Progression[Config.maxLevel].size/2-14)/22)*22
for x=-extent,extent,22 do
	for z=-extent,extent,22 do
		local core=math.abs(x)<41 and z>-45 and z<52
		local palace=math.abs(x)<40 and z<-27
		local exit=x>-51 and x<-21 and z<0
		local early=(x==44 and z>=-44 and z<=44) or (x==-44 and z>=-22 and z<=22)
		local wings=math.abs(math.abs(x)-66)<18 and math.abs(z+68)<20
		local infrastructure=Camp.blocksApproach(x,z,14)
		for _,site in {Sites.blacksmith,Sites.armorer,Sites.storehouse}do
			-- Keep the forecourt clear after construction and later district growth.
			if math.abs(x-site.X)<20 and math.abs(z-site.Z-10)<24 then infrastructure=true;break end
		end
		if not core and not palace and not exit and not early and not wings and not infrastructure then
			table.insert(lots,{x=x,z=z,minimum=math.ceil((math.max(math.abs(x),math.abs(z))+14-Config.initialSize/2)/(Config.sizeIncrement/2)+1)})
		end
	end
end
table.sort(lots,function(a,b)
	if a.minimum~=b.minimum then return a.minimum<b.minimum end
	if a.z~=b.z then return a.z>b.z end
	return a.x<b.x
end)

local plan, used = {}, {}
for level=15,Config.maxLevel do
	if level%2==1 then
		local best,bestScore=nil,-math.huge
		for index,lot in lots do
			if not used[index] and lot.minimum<=level then
				local angle=math.atan2(lot.x,lot.z)-level*2.399963229728653
				local difference=math.abs(math.atan2(math.sin(angle),math.cos(angle)))
				local score=lot.minimum*1000-difference
				if score>bestScore then best,bestScore=index,score end
			end
		end
		if best then plan[level]=lots[best];used[best]=true end
	end
end

function Districts.add(parent: Folder, frame: CFrame, civ, level: number)
	local feature=Instance.new("Folder")
	feature.Name,feature.Parent="GrowthFeature_"..level,parent
	feature:SetAttribute("UnlockLevel",level)
	feature:SetAttribute("CivilizationId",civ.id)
	feature:SetAttribute("Theme",styles[civ.id].name)
	local half=Progression[level].size/2
	-- A new paved course records every small land expansion and stays in place.
	part(feature,"ExpansionAvenue",Vector3.new(12,.12,4),frame*CFrame.new(0,2.08,half-2),STONE,Enum.Material.Cobblestone)
	local featureId="avenue_detail"
	if level==2 then featureId="barracks"
	elseif level==3 then house(feature,frame*CFrame.new(24,0,-25),civ,10,"FirstDwelling");featureId="dwelling"
	elseif level==4 then house(feature,frame*CFrame.new(-24,0,-25),civ,10,"Storehouse");featureId="storehouse"
	elseif level==5 then garden(feature,frame*CFrame.new(0,0,-31),civ,18);featureId="cultivated_garden"
	elseif level==6 then house(feature,frame*CFrame.new(35,0,-8),civ,8,"ArtisanWorkshop");featureId="artisan_workshop"
	elseif level==7 then garden(feature,frame*CFrame.new(36,0,10),civ,8);featureId="orchard"
	elseif level==8 then house(feature,frame*CFrame.new(-38,0,22),civ,8,"CraftHall");featureId="craft_hall"
	elseif level==9 then
		for _, x in {-12,12} do part(feature,"ProcessionalPillar",Vector3.new(2,9,2),frame*CFrame.new(x,6.5,-38),civ.color) end
		featureId="processional_entrance"
	elseif level==10 then monument(feature,frame*CFrame.new(0,0,-41),civ);featureId="civic_monument"
	elseif level==11 then garden(feature,frame*CFrame.new(42,0,-30),civ,8);featureId="district_garden"
	elseif level==12 then garden(feature,frame*CFrame.new(-44,0,4),civ,8);featureId="western_garden"
	elseif level==13 then garden(feature,frame*CFrame.new(35,0,-39),civ,8);featureId="outer_garden"
	elseif level==14 then monument(feature,frame*CFrame.new(44,0,-46),civ);featureId="district_emblem"
	elseif level==20 then
		for _, x in {-12,12} do part(feature,"CeremonialGatePier",Vector3.new(3,12,3),frame*CFrame.new(x,8,-46),civ.color) end
		part(feature,"CeremonialGateLintel",Vector3.new(27,2,3),frame*CFrame.new(0,14,-46),GOLD)
		featureId="ceremonial_gate"
	elseif level==30 then
		house(feature,frame*CFrame.new(0,0,-65),civ,42,styles[civ.id].landmark)
		local family=styles[civ.id].family
		local depth=if family=="longhouse" then .5 elseif family=="pagoda" then .4 elseif family=="yurt" then .43 else .35
		local width=if family=="longhouse" then 42*.28 elseif family=="pylon" then 42*.42
			elseif family=="brick" or family=="stucco" then 42*.4 elseif family=="classical" then 42*.6 else 42*.7
		local x=if family=="longhouse" then -42*.22 else 0
		local y=42*.42-(if family=="longhouse" then 2.2 elseif civ.id=="rome" then 2 else 0)
		local host=part(parent,"GrandIdentityHost",Vector3.new(width,3.8,.25),frame*CFrame.new(x,y,-65-42*depth-.15),civ.color)
		host:SetAttribute("IntegratedFacade",true)
		featureId="grand_"..styles[civ.id].landmark
	elseif level==40 then
		for _, x in {-66,66} do house(feature,frame*CFrame.new(x,0,-68),civ,16,"CeremonialWing") end
		featureId="ceremonial_wings"
	elseif level==Config.maxLevel then
		for _, x in {-22,22} do monument(feature,frame*CFrame.new(x,0,-103),civ,true) end
		featureId="completed_"..styles[civ.id].landmark
	elseif plan[level] then
		local lot=plan[level]
		house(feature,frame*CFrame.new(lot.x,0,lot.z),civ,14,"DistrictHouse_"..level)
		featureId="themed_district"
	else
		part(feature,"AvenueCarving",Vector3.new(1.5,3,1.5),frame*CFrame.new(if level%2==0 then -8 else 8,3.5,half-4),civ.color,styles[civ.id].material)
	end
	feature:SetAttribute("FeatureId",featureId)
end

function Districts.perimeter(parent: Folder, frame: CFrame, civ, level: number)
	if level<20 then return end
	local walls=parent:FindFirstChild("Perimeter")
	if not walls then walls=Instance.new("Folder");walls.Name="Perimeter";walls.Parent=parent end
	local r=Progression[level].size/2-2
	local timber=styles[civ.id].family=="longhouse" or civ.id=="mongols"
	local tint=if timber then WOOD else STONE
	local material=if timber then Enum.Material.WoodPlanks else Enum.Material.Sandstone
	local function wall(name: string,size: Vector3,position: Vector3,solid: boolean?)
		local existing=walls:FindFirstChild(name) :: Part
		if existing then existing.Size,existing.CFrame=size,frame*CFrame.new(position)
		else part(walls,name,size,frame*CFrame.new(position),tint,material,solid) end
	end
	local gateNear,gateFar=Camp.center.Z-Camp.approachHalfWidth,Camp.center.Z+Camp.approachHalfWidth
	wall("WestWall",Vector3.new(2,6,r+gateNear),Vector3.new(-r,5,(-r+gateNear)/2),true)
	wall("WestWallBeyondCamp",Vector3.new(2,6,r-gateFar),Vector3.new(-r,5,(r+gateFar)/2),true)
	wall("TrainingGateLintel",Vector3.new(3,2,2*Camp.approachHalfWidth+2),Vector3.new(-r,13,Camp.center.Z))
	wall("EastWall",Vector3.new(2,6,2*r),Vector3.new(r,5,0),true)
	wall("CourtWallLeft",Vector3.new(r-9,6,2),Vector3.new((-r-9)/2,5,r),true)
	wall("CourtWallRight",Vector3.new(r-9,6,2),Vector3.new((r+9)/2,5,r),true)
	wall("ArenaWallLeft",Vector3.new(r-42,6,2),Vector3.new((-r-42)/2,5,-r),true)
	wall("ArenaWallRight",Vector3.new(r+30,6,2),Vector3.new((r-30)/2,5,-r),true)
	wall("CourtGateLintel",Vector3.new(20,2,3),Vector3.new(0,13,r))
	wall("ArenaGateLintel",Vector3.new(14,2,3),Vector3.new(-36,13,-r))
	wall("ArenaExitPaving",Vector3.new(10,.1,r-11),Vector3.new(-36,2.06,(-r-11)/2))
end

-- Purchased infrastructure uses the same civilization architecture as districts.
Districts.house = house
return Districts

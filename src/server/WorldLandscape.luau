--!strict

local Layout = require(game:GetService("ReplicatedStorage").Shared.WorldConfig)
local Topography = require(script.Parent.Topography)
local Landscape = {
	sampleHeight=Topography.sampleHeight, sampleNormal=Topography.sampleNormal,
	biomeAt=Topography.biomeAt, isReserved=Topography.isReserved,
}
local function part(parent,name,size,frame,color,material,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame=name,size,frame
	p.Color,p.Material=color,material
	p.Anchored,p.CanTouch=true,false
	p.CanCollide,p.CanQuery=solid==true,solid==true
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent=parent
	return p
end
local function ground(x: number,z: number): Vector3
	return Vector3.new(x,Topography.sampleHeight(x,z),z)
end
local function foliage(parent,name,position,size,color)
	local p=part(parent,name,size,CFrame.new(position),color,Enum.Material.Grass,false)
	p.Shape=Enum.PartType.Ball
	return p
end

function Landscape.build(world: Model): Folder
	local root=Instance.new("Folder")
	root.Name,root.Parent="Landscape",world
	root:SetAttribute("GeneratedBy","CivilizationLandscape")
	root:SetAttribute("Seed",137)
	Topography.build(root)
	local biomes={}
	for _,name in {"Grassland","Forest","Desert","SnowyHighlands","Wetlands"} do
		local folder=Instance.new("Folder")
		folder.Name,folder.Parent=name,root
		folder:SetAttribute("Biome",name)
		biomes[name]=folder
	end
	local half=Layout.groundSize/2
	local random=Random.new(137)
	local planted={}
	-- Cartesian candidates avoid repeated radial rings; all ground anchors use
	-- the same connected collision sheet used by players and pathfinding.
	for index=1,190 do
		local position=ground(random:NextNumber(-half+35,half-35),random:NextNumber(-half+35,half-35))
		if Landscape.isReserved(position,18,true) then continue end
		local crowded=false
		for _,existing in planted do
			if Vector3.new(position.X-existing.X,0,position.Z-existing.Z).Magnitude<32 then crowded=true;break end
		end
		if crowded then continue end
		table.insert(planted,position)
		local name=Topography.biomeAt(position.X,position.Z)
		local group=Instance.new("Model")
		group.Name,group.Parent="Scenery"..index,biomes[name]
		group:SetAttribute("ClearanceRadius",18)
		group:SetAttribute("GroundPosition",position)
		if name=="Forest" or (name=="Grassland" and index%3==0) then
			local height=random:NextNumber(12,21)
			part(group,"Trunk",Vector3.new(3,height,3),CFrame.new(position+Vector3.new(0,height/2,0)),Color3.fromRGB(95,68,45),Enum.Material.Wood,true)
			foliage(group,"Canopy",position+Vector3.new(0,height+3,0),Vector3.new(21,22,19),Color3.fromRGB(43,87+index%25,52))
			foliage(group,"CanopySide",position+Vector3.new(7,height,3),Vector3.new(14,14,14),Color3.fromRGB(60,109,61))
		elseif name=="SnowyHighlands" then
			local height=random:NextNumber(14,22)
			part(group,"PineTrunk",Vector3.new(2,height,2),CFrame.new(position+Vector3.new(0,height/2,0)),Color3.fromRGB(96,80,68),Enum.Material.Wood,true)
			for tier=1,3 do
				foliage(group,"SnowPine",position+Vector3.new(0,height*.4+tier*4,0),Vector3.new(20-tier*4,7,20-tier*4),
					if tier==3 then Color3.fromRGB(224,235,234) else Color3.fromRGB(55,92,83)).Material=Enum.Material.Snow
			end
		elseif name=="Desert" then
			part(group,"Cactus",Vector3.new(3,12,3),CFrame.new(position+Vector3.new(0,6,0)),Color3.fromRGB(74,120,73),Enum.Material.Grass,true)
			part(group,"CactusArm",Vector3.new(8,2,2),CFrame.new(position+Vector3.new(1,7,0)),Color3.fromRGB(74,120,73),Enum.Material.Grass,false)
			foliage(group,"Sandstone",ground(position.X+8,position.Z-6)+Vector3.new(0,3,0),Vector3.new(10,6,8),Color3.fromRGB(166,137,91)).Material=Enum.Material.Sandstone
		elseif name=="Wetlands" then
			for reed=1,5 do
				local base=ground(position.X+reed*2-6,position.Z+reed%2*5-3)
				part(group,"Reeds",Vector3.new(.6,5,.6),CFrame.new(base+Vector3.new(0,2.5,0)),Color3.fromRGB(130,143,76),Enum.Material.Grass,false)
			end
		else
			local rock=foliage(group,"MeadowRock",position+Vector3.new(0,3,0),Vector3.new(12,6,9),Color3.fromRGB(129,140,125))
			rock.Material,rock.CanCollide,rock.CanQuery=Enum.Material.Rock,true,true
		end
	end

	local waterways=Instance.new("Folder")
	waterways.Name,waterways.Parent="Waterways",root
	local river=Instance.new("Folder")
	river.Name,river.Parent="ShallowRiver",waterways
	local riverPoints=Topography.riverPoints()
	for index=1,#riverPoints-1 do
		local a,b=riverPoints[index],riverPoints[index+1]
		local width=20+2*math.sin(index*.7)
		local centre=(a+b)/2+Vector3.new(0,.12,0)
		local water=part(river,"RiverSegment",Vector3.new(width,.18,(b-a).Magnitude+1.5),
			CFrame.lookAt(centre,centre+(b-a)),Color3.fromRGB(65,137,156),Enum.Material.Glass,false)
		water.Transparency=.22
		water:SetAttribute("SegmentIndex",index)
		water:SetAttribute("PointA",a);water:SetAttribute("PointB",b);water:SetAttribute("Width",width)
	end
	for _,crossing in Topography.crossings() do
		local bridge=Instance.new("Model")
		bridge.Name,bridge.Parent="DryCrossing",waterways
		bridge:SetAttribute("RouteWidth",crossing.width)
		bridge:SetAttribute("CrossingPosition",crossing.position)
		bridge:SetAttribute("PlotId",crossing.plotId)
		bridge:SetAttribute("Length",crossing.length)
		local centre=crossing.position+Vector3.new(0,.35,0)
		local frame=CFrame.lookAt(centre,centre+crossing.direction)
		part(bridge,"BridgeDeck",Vector3.new(crossing.width,.6,crossing.length),frame,Color3.fromRGB(125,99,65),Enum.Material.WoodPlanks,true)
		for _,side in {-1,1} do
			part(bridge,"Rail",Vector3.new(1,2,crossing.length),frame*CFrame.new(side*(crossing.width/2+.5),1.3,0),Color3.fromRGB(91,73,49),Enum.Material.Wood,false)
		end
	end

	local features=Instance.new("Folder")
	features.Name,features.Parent="BattlefieldFeatures",root
	local plaza=part(features,"CentralPlaza",Vector3.new(.15,70,70),CFrame.new(0,.32,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(138,132,111),Enum.Material.Cobblestone,true)
	plaza.Shape=Enum.PartType.Cylinder
	local boundary=Instance.new("Folder")
	boundary.Name,boundary.Parent="CombatBoundary",features
	for index=1,64 do
		local angle=index*2*math.pi/64
		local x,z=math.sin(angle)*Layout.arenaRadius,math.cos(angle)*Layout.arenaRadius
		local normal=Topography.sampleNormal(x,z)
		local tangent=Vector3.new(math.cos(angle),0,-math.sin(angle))
		local back=(tangent-normal*tangent:Dot(normal)).Unit
		local right=normal:Cross(back).Unit
		part(boundary,"BoundaryStone",Vector3.new(5,.2,2*math.pi*Layout.arenaRadius/64+1),
			CFrame.fromMatrix(ground(x,z)+normal*.12,right,normal,back),Color3.fromRGB(145,139,113),Enum.Material.Slate,false)
	end
	local ruins={}
	for _=1,200 do
		if #ruins==8 then break end
		local x,z=random:NextNumber(-215,215),random:NextNumber(-215,215)
		local position=ground(x,z)
		if Vector3.new(x,0,z).Magnitude>Layout.arenaRadius-25 or Landscape.isReserved(position,16,true) then continue end
		local crowded=false
		for _,existing in ruins do
			if Vector3.new(position.X-existing.X,0,position.Z-existing.Z).Magnitude<36 then crowded=true;break end
		end
		if crowded then continue end
		table.insert(ruins,position)
		local ruin=Instance.new("Model")
		ruin.Name,ruin.Parent="RuinedCourt"..#ruins,features
		ruin:SetAttribute("GroundPosition",position)
		ruin:SetAttribute("ClearanceRadius",16)
		local frame=CFrame.new(position)*CFrame.Angles(0,random:NextNumber(-math.pi,math.pi),0)
		for _,side in {-1,1} do
			local p=frame:PointToWorldSpace(Vector3.new(side*8,0,0))
			local height=5+#ruins%3
			part(ruin,"BrokenPillar",Vector3.new(3,height,3),CFrame.new(ground(p.X,p.Z)+Vector3.new(0,height/2,0)),Color3.fromRGB(161,153,131),Enum.Material.Limestone,true)
		end
		local wall=frame:PointToWorldSpace(Vector3.new(0,0,6))
		part(ruin,"LowWall",Vector3.new(18,3,2),CFrame.new(ground(wall.X,wall.Z)+Vector3.new(0,1.5,0))*frame.Rotation,Color3.fromRGB(161,153,131),Enum.Material.Limestone,true)
	end
	assert(#ruins==8,"Landscape needs eight clear irregular battlefield cover sites")
	local count=0
	for _,object in root:GetDescendants() do if object:IsA("BasePart") then count+=1 end end
	assert(count<=2000,"Landscape exceeded the 2000-part geometry budget")
	root:SetAttribute("StaticPartCount",count)
	return root
end

return Landscape

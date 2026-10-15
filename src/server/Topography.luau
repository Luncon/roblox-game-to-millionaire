--!strict

local Layout = require(game:GetService("ReplicatedStorage").Shared.WorldConfig)
local Sites = require(game:GetService("ReplicatedStorage").Shared.SettlementSites)
local Topography = {}
local BASE, SEED, THICKNESS = .15, 137, .25
local scale = Layout.groundSize/1600
local colors = {
	Grassland={Color3.fromRGB(104,135,69),Enum.Material.Grass},
	Forest={Color3.fromRGB(55,94,62),Enum.Material.LeafyGrass},
	Desert={Color3.fromRGB(209,181,116),Enum.Material.Sand},
	SnowyHighlands={Color3.fromRGB(211,225,228),Enum.Material.Snow},
	Wetlands={Color3.fromRGB(89,112,82),Enum.Material.Mud},
}

local function smooth(value: number): number
	local t=math.clamp(value,0,1)
	return t*t*(3-2*t)
end

function Topography.biomeAt(x: number,z: number): string
	x,z=x/scale,z/scale
	local wx=x+math.noise(x/210,z/210,19)*140+math.noise(z/95,x/110,37)*35
	local wz=z+math.noise(x/170,z/230,51)*150
	if wz < -180+math.noise(wx/130,9)*80 then return "SnowyHighlands" end
	if wx < -170+math.noise(wz/160,23)*90 then return "Forest" end
	if wx > 180 and wz > -25+math.noise(wx/150,31)*65 then return "Desert" end
	if wx > 95 and wz < -20 then return "Wetlands" end
	return "Grassland"
end

local river = {}
for index=0,20 do
	local x=(-220+index*22)*scale
	local z=(90+32*math.sin((x/scale+25)/83)+13*math.sin((x/scale-55)/47)-x/scale*.06)*scale
	table.insert(river,Vector3.new(x,BASE,z))
end

function Topography.riverPoints(): {Vector3}
	return table.clone(river)
end

local rectangles = {}
local function rectangle(cx: number,cz: number,ux: number,uz: number,hx: number,hz: number,kind: string)
	local rect={cx=cx,cz=cz,ux=ux,uz=uz,vx=-uz,vz=ux,hx=hx,hz=hz,kind=kind,points={}}
	for _,corner in {{-1,-1},{1,-1},{1,1},{-1,1}} do
		table.insert(rect.points,{x=cx+ux*hx*corner[1]-uz*hz*corner[2],z=cz+uz*hx*corner[1]+ux*hz*corner[2]})
	end
	table.insert(rectangles,rect)
end
for id=1,Layout.plotCount do
	local frame=Layout.plotFrame(id)
	rectangle(frame.X,frame.Z,frame.RightVector.X,frame.RightVector.Z,Layout.maxPlotSize/2,Layout.maxPlotSize/2,"plot")
	for _,site in Sites.fields do
		local p=frame:PointToWorldSpace(site)
		rectangle(p.X,p.Z,frame.RightVector.X,frame.RightVector.Z,Sites.fieldSize.X/2+3,Sites.fieldSize.Z/2+3,"farm")
	end
	for _,site in {Sites.workers,Vector3.new(-24,0,-145),Vector3.new(-48,0,-145)}do
		local p=frame:PointToWorldSpace(site)
		rectangle(p.X,p.Z,frame.RightVector.X,frame.RightVector.Z,12,12,"farm_access")
	end
	local direction=Vector3.new(frame.X,0,frame.Z).Unit
	local length=Layout.plotRadius+40
	rectangle(direction.X*length/2,direction.Z*length/2,direction.Z,-direction.X,Layout.laneWidth/2,length/2,"lane")
end
rectangle(0,Layout.groundSize/2-35,1,0,45,45,"entry")
rectangle(0,0,1,0,36,36,"plaza")
for index=1,#river-1 do
	local a,b=river[index],river[index+1]
	local d=(b-a).Unit
	rectangle((a.X+b.X)/2,(a.Z+b.Z)/2,d.Z,-d.X,14*scale,(b-a).Magnitude/2+1,"river")
end

local crossings = {}
for _,id in {1,2,8} do
	local frame=Layout.plotFrame(id)
	local direction=Vector3.new(frame.X,0,frame.Z).Unit
	for index=1,#river-1 do
		local a,b=river[index],river[index+1]
		local delta=b-a
		local denominator=delta.X*direction.Z-delta.Z*direction.X
		if math.abs(denominator)<1e-8 then continue end
		local t=-(a.X*direction.Z-a.Z*direction.X)/denominator
		if t<0 or t>1 then continue end
		local p=a+delta*t
		if p:Dot(direction)<0 then continue end
		local angle=math.abs(delta.Unit.X*direction.Z-delta.Unit.Z*direction.X)
		local length=28*scale/math.max(.25,angle)+12
		table.insert(crossings,{position=p,direction=direction,length=length,width=28,plotId=id})
		rectangle(p.X,p.Z,direction.Z,-direction.X,16,length/2,"crossing")
		break
	end
end
function Topography.crossings(): any
	local result={}
	for _,crossing in crossings do table.insert(result,table.clone(crossing)) end
	return result
end

local function outside(rect, x: number,z: number): number
	local dx,dz=x-rect.cx,z-rect.cz
	local u=math.max(0,math.abs(dx*rect.ux+dz*rect.uz)-rect.hx)
	local v=math.max(0,math.abs(dx*rect.vx+dz*rect.vz)-rect.hz)
	return math.sqrt(u*u+v*v)
end
function Topography.isReserved(position: Vector3,radius: number,includeLanes: boolean?): boolean
	for _,rect in rectangles do
		if (includeLanes or (rect.kind~="lane" and rect.kind~="river" and rect.kind~="crossing"))
			and outside(rect,position.X,position.Z)<=radius then return true end
	end
	return false
end

local function overlaps(a,b): boolean
	for _,polygon in {a,b} do
		for index,p in polygon do
			local q=polygon[index%#polygon+1]
			local ax,az=-(q.z-p.z),q.x-p.x
			local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
			for _,v in a do local n=v.x*ax+v.z*az;amin,amax=math.min(amin,n),math.max(amax,n) end
			for _,v in b do local n=v.x*ax+v.z*az;bmin,bmax=math.min(bmin,n),math.max(bmax,n) end
			if amax<bmin-.0001 or bmax<amin-.0001 then return false end
		end
	end
	return true
end

local function weights(a,b,c,x: number,z: number): (number,number,number)
	local denominator=(b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
	local u=((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/denominator
	local v=((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/denominator
	return u,v,1-u-v
end

local function intersectsArena(a,b,c): boolean
	local radius=Layout.arenaRadius
	for _,v in {a,b,c} do if v.x*v.x+v.z*v.z<=radius*radius then return true end end
	local u,v,w=weights(a,b,c,0,0)
	if u>=0 and v>=0 and w>=0 then return true end
	for _,edge in {{a,b},{b,c},{c,a}} do
		local p,q=edge[1],edge[2]
		local dx,dz=q.x-p.x,q.z-p.z
		local t=math.clamp(-(p.x*dx+p.z*dz)/(dx*dx+dz*dz),0,1)
		if (p.x+t*dx)^2+(p.z+t*dz)^2<=radius*radius then return true end
	end
	return false
end

local function rawHeight(x: number,z: number): number
	local px,pz=x/scale,z/scale
	local distance=math.huge
	for _,rect in rectangles do distance=math.min(distance,outside(rect,x,z)) end
	local field=math.clamp(2.5+2*math.noise(px/180,pz/150,SEED)
		+3*math.exp(-((px+155)/100)^2-((pz+125)/115)^2),0,6-BASE)
	local function hill(cx,cz,sx,sz,height,angle)
		local dx,dz=px-cx,pz-cz
		local u,v=dx*math.cos(angle)+dz*math.sin(angle),-dx*math.sin(angle)+dz*math.cos(angle)
		return height*math.exp(-(u/sx)^2-(v/sz)^2)
	end
	local relief=hill(-640,-590,250,145,84,-.45)+hill(610,310,205,120,46,.7)
		+hill(-360,680,210,115,61,-.2)+hill(480,-690,175,140,35,.8)
		+8*(math.noise(px/160,pz/200,71)+.5)
	local outer=smooth((math.sqrt(x*x+z*z)-Layout.arenaRadius-70*scale)/(210*scale))
	return BASE+math.clamp(field+relief*outer,0,90-BASE)*smooth(distance/(100*scale))
end

-- Shared coordinate lines refine the arena without any mixed-resolution T seams.
local coordinates={-800,-640,-480}
for value=-320,320,40 do table.insert(coordinates,value) end
for _,value in {480,640,800} do table.insert(coordinates,value) end
for index,value in coordinates do coordinates[index]=value*scale end
local vertices,cells,triangles={},{},{}
for i,x in coordinates do
	vertices[i]={}
	for j,z in coordinates do vertices[i][j]={x=x,z=z,height=rawHeight(x,z),flat=false} end
end
local function triangle(a,b,c)
	local record={a=a,b=b,c=c,id=#triangles+1}
	table.insert(triangles,record)
	for _,rect in rectangles do
		if overlaps({a,b,c},rect.points) then a.flat,b.flat,c.flat=true,true,true;break end
	end
	if intersectsArena(a,b,c) then a.capped,b.capped,c.capped=true,true,true end
	return record
end
for i=1,#coordinates-1 do
	cells[i]={}
	for j=1,#coordinates-1 do
		local a,b,c,d=vertices[i][j],vertices[i+1][j],vertices[i+1][j+1],vertices[i][j+1]
		cells[i][j]={a=a,b=b,c=c,d=d,first=triangle(a,b,c),second=triangle(a,c,d)}
	end
end
for _,row in vertices do for _,v in row do
	if v.flat then v.height=BASE elseif v.capped then v.height=math.min(v.height,6) end
end end
-- Bound both slope components; lowering only preserves every exact flat vertex.
for _=1,#coordinates*2 do
	local changed=false
	local function constrain(a,b,distance)
		local delta=.45*distance
		if a.height>b.height+delta then a.height=b.height+delta;changed=true end
		if b.height>a.height+delta then b.height=a.height+delta;changed=true end
	end
	for i=1,#coordinates do for j=1,#coordinates do
		if i<#coordinates then constrain(vertices[i][j],vertices[i+1][j],coordinates[i+1]-coordinates[i]) end
		if j<#coordinates then constrain(vertices[i][j],vertices[i][j+1],coordinates[j+1]-coordinates[j]) end
	end end
	if not changed then break end
end

local function locate(value: number): number
	for index=1,#coordinates-1 do if value<=coordinates[index+1] then return index end end
	return #coordinates-1
end
local function sample(x: number,z: number)
	x,z=math.clamp(x,coordinates[1],coordinates[#coordinates]),math.clamp(z,coordinates[1],coordinates[#coordinates])
	local cell=cells[locate(x)][locate(z)]
	local selected=cell.first
	local u,v,w=weights(selected.a,selected.b,selected.c,x,z)
	if u<-.00001 or v<-.00001 or w<-.00001 then
		selected=cell.second;u,v,w=weights(selected.a,selected.b,selected.c,x,z)
	end
	return selected,u,v,w
end
local function point(v): Vector3 return Vector3.new(v.x,v.height,v.z) end
function Topography.sampleHeight(x: number,z: number): number
	local t,u,v,w=sample(x,z)
	return t.a.height*u+t.b.height*v+t.c.height*w
end
function Topography.sampleNormal(x: number,z: number): Vector3
	local t=sample(x,z)
	local normal=(point(t.b)-point(t.a)):Cross(point(t.c)-point(t.a)).Unit
	return if normal.Y<0 then -normal else normal
end

local function solid(parent,name,size,frame,biome,className: string?)
	local p=Instance.new(className or "Part")
	p.Name,p.Size,p.CFrame=name,size,frame
	p.Color,p.Material=colors[biome][1],colors[biome][2]
	p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=true,true,true,false
	p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p:SetAttribute("Biome",biome)
	p.Parent=parent
	return p
end

function Topography.build(parent: Instance): Folder
	local root=Instance.new("Folder")
	root.Name,root.Parent="TerrainSurface",parent
	root:SetAttribute("GeneratedBy","CivilizationTopography")
	root:SetAttribute("Seed",SEED)
	root:SetAttribute("GridStep",40*scale)
	root:SetAttribute("OuterGridStep",160*scale)
	local count=0
	local function render(t)
		local a,b,c=point(t.a),point(t.b),point(t.c)
		-- Overlap coplanarly at shared edges: native wedge collision uses float
		-- transforms and can otherwise miss a down-ray exactly on a mesh seam.
		local centre=(a+b+c)/3
		a,b,c=a+(a-centre).Unit*.06,b+(b-centre).Unit*.06,c+(c-centre).Unit*.06
		local ab,ac,bc=b-a,c-a,c-b
		if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
		elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
		ab,ac,bc=b-a,c-a,c-b
		local right=ac:Cross(ab).Unit
		if right.Y<0 then b,c=c,b;ab,ac,bc=b-a,c-a,c-b;right=ac:Cross(ab).Unit end
		local up,back=bc:Cross(right).Unit,bc.Unit
		local height=math.abs(ab:Dot(up))
		local biome=Topography.biomeAt((a.X+b.X+c.X)/3,(a.Z+b.Z+c.Z)/3)
		for _,half in {{b,right,back,ab},{c,-right,-back,ac}} do
			local length=math.abs(half[4]:Dot(back))
			if length<.001 or height<.001 then continue end
			local p=solid(root,"TerrainTriangle",Vector3.new(THICKNESS,height+.06,length+.06),
				CFrame.fromMatrix((a+half[1])/2-right*THICKNESS/2,half[2],up,half[3]),biome,"WedgePart")
			p:SetAttribute("SurfaceTriangle",true)
			p:SetAttribute("TriangleId",t.id)
			p:SetAttribute("VertexA",point(t.a));p:SetAttribute("VertexB",point(t.b));p:SetAttribute("VertexC",point(t.c))
			count+=1
		end
	end
	for _,row in cells do for _,cell in row do
		local minimum=math.min(cell.a.height,cell.b.height,cell.c.height,cell.d.height)
		local maximum=math.max(cell.a.height,cell.b.height,cell.c.height,cell.d.height)
		local x,z=(cell.a.x+cell.c.x)/2,(cell.a.z+cell.c.z)/2
		local p=solid(root,if maximum-minimum<.00001 then "FlatSurface" else "SolidCellFill",
			Vector3.new(cell.b.x-cell.a.x+.06,minimum+2,cell.d.z-cell.a.z+.06),CFrame.new(x,(minimum-2)/2,z),Topography.biomeAt(x,z))
		p:SetAttribute("CellMinimum",minimum)
		count+=1
		if maximum-minimum>=.00001 then render(cell.first);render(cell.second) end
	end end
	local function skirt(a,b)
		local pa,pb=point(a),point(b)
		if pa.Y>pb.Y then pa,pb=pb,pa end
		local horizontal=Vector3.new(pb.X-pa.X,0,pb.Z-pa.Z)
		local back=horizontal.Unit
		local right=Vector3.yAxis:Cross(back)
		local middle=(pa+pb)/2
		local biome=Topography.biomeAt(middle.X,middle.Z)
		solid(root,"BoundaryFill",Vector3.new(.1,pa.Y+2,horizontal.Magnitude),
			CFrame.fromMatrix(Vector3.new(middle.X,(pa.Y-2)/2,middle.Z),right,Vector3.yAxis,back),biome)
		count+=1
		if pb.Y-pa.Y>.0001 then
			solid(root,"BoundarySlope",Vector3.new(.1,pb.Y-pa.Y,horizontal.Magnitude),
				CFrame.fromMatrix(middle,right,Vector3.yAxis,back),biome,"WedgePart")
			count+=1
		end
	end
	for index=1,#coordinates-1 do
		skirt(vertices[1][index],vertices[1][index+1]);skirt(vertices[#coordinates][index],vertices[#coordinates][index+1])
		skirt(vertices[index][1],vertices[index+1][1]);skirt(vertices[index][#coordinates],vertices[index+1][#coordinates])
	end
	root:SetAttribute("StaticPartCount",count)
	return root
end

return Topography

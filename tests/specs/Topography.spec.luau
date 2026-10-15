return function()
	local module=game.ServerScriptService.Game:FindFirstChild("Topography")
	assert(module,"Connected asymmetric Topography is not implemented")
	local Topography=require(module)
	local Layout=require(game.ReplicatedStorage.Shared.WorldConfig)
	local count=0
	local function test(name,callback) callback();count+=1;print("PASS: "..name) end
	local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
	local container=Instance.new("Model")
	container.Name,container.Parent="TopographySurfaceFixture",workspace
	local sentinel=Instance.new("Part")
	sentinel.Name,sentinel.Parent="ForeignTopographySentinel",workspace
	local ground=Instance.new("Part")
	ground.Size,ground.CFrame,ground.Anchored=Vector3.new(1600,2,1600),CFrame.new(0,-.95,0),true
	ground.Parent=container
	local ok,result=pcall(function()
		local surface=Topography.build(container)
		local highestArena=.15
		local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances={container}
		local function requireFlat(x,z,label)
			assert(math.abs(Topography.sampleHeight(x,z)-.15)<.001,"Sampled relief enters "..label)
			local hit=workspace:Raycast(Vector3.new(x,180,z),Vector3.new(0,-250,0),filter)
			assert(hit and math.abs(hit.Position.Y-.15)<.08,"Actual collider intrudes into or leaves a seam in "..label.." at "..x..","..z.." height="..tostring(if hit then hit.Position.Y else nil))
		end
		test("deterministic finite sampled ground and normals preserve the combat height and slope budget",function()
			local names={Grassland=true,Forest=true,Desert=true,SnowyHighlands=true,Wetlands=true}
			for x=-760,760,40 do for z=-760,760,40 do
				local h,normal=Topography.sampleHeight(x,z),Topography.sampleNormal(x,z)
				assert(finite(h) and h>=.149 and h<=90.001 and h==Topography.sampleHeight(x,z))
				assert(typeof(normal)=="Vector3" and finite(normal.X) and finite(normal.Y) and finite(normal.Z))
				assert(math.abs(normal.Magnitude-1)<.001 and normal.Y>0)
				assert(names[Topography.biomeAt(x,z)],"Unknown sampled biome")
				if x*x+z*z<=Layout.arenaRadius^2 then
					assert(h<=6.001,"Relief exceeds standing-actor combat headroom")
					assert(normal.Y>=math.cos(math.rad(15))-.001,"Arena slope exceeds fifteen degrees")
				end
			end end
			for x=-240,240,10 do for z=-240,240,10 do
				if x*x+z*z>Layout.arenaRadius^2 then continue end
				local h,normal=Topography.sampleHeight(x,z),Topography.sampleNormal(x,z)
				highestArena=math.max(highestArena,h)
				assert(h>=.149 and h<=6.001 and normal.Y>=math.cos(math.rad(15))-.001)
			end end
			local function fingerprint(folder)
				local values,n={},0
				for _,part in folder:GetDescendants() do
					if part:IsA("BasePart") then
						n+=1
						local id=part:GetAttribute("TriangleId")
						if part:GetAttribute("SurfaceTriangle") then values[id]={part:GetAttribute("VertexA"),part:GetAttribute("VertexB"),part:GetAttribute("VertexC")} end
					end
				end
				return values,n
			end
			local duplicate=Instance.new("Model");duplicate.Parent=container
			ground:Clone().Parent=duplicate
			local second=Topography.build(duplicate)
			local a,partsA=fingerprint(surface)
			local b,partsB=fingerprint(second)
			assert(partsA==partsB,"Identical configuration generated different terrain counts")
			for id,vertices in a do
				assert(b[id],"Repeated generation lost triangle "..id)
				for index,vertex in vertices do assert(vertex==b[id][index],"Repeated generation changed terrain vertex geometry") end
			end
			duplicate:Destroy()
		end)
		test("unequal landforms and warped biome boundaries avoid rotational repeated geography",function()
			local asymmetric,outerHigh,arenaHigh=false,.15,.15
			local crossings={}
			for x=-720,720,40 do for z=-720,720,40 do
				local h=Topography.sampleHeight(x,z)
				if math.abs(h-Topography.sampleHeight(-z,x))>1 then asymmetric=true end
				if x*x+z*z<=Layout.arenaRadius^2 then arenaHigh=math.max(arenaHigh,h) else outerHigh=math.max(outerHigh,h) end
				local a,b=Topography.biomeAt(x,z),Topography.biomeAt(x+40,z)
				if a~=b then
					local pair=if a<b then a..":"..b else b..":"..a
					crossings[pair]=crossings[pair] or {};crossings[pair][x]=true
				end
			end end
			assert(asymmetric and outerHigh>12,"World lacks unequal larger landforms")
			assert(math.max(arenaHigh,highestArena)>2.15,"Combat ground lacks two studs of noticeable relief")
			local warped=false
			for _,positions in crossings do local n=0;for _ in positions do n+=1 end;if n>=3 then warped=true end end
			assert(warped,"Biome boundaries remain fixed straight coordinate cuts")
		end)
		test("every finished plot and full radial army corridor retains the flat sampled and collision baseline",function()
			for id=1,8 do
				local frame=Layout.plotFrame(id)
				for x=-128,128,32 do for z=-128,128,32 do
					local p=frame:PointToWorldSpace(Vector3.new(x,0,z))
					requireFlat(p.X,p.Z,"finished plot "..id)
				end end
				local direction=Vector3.new(frame.Position.X,0,frame.Position.Z).Unit
				local perpendicular=Vector3.new(-direction.Z,0,direction.X)
				for along=0,Layout.plotRadius+32,16 do for _,across in {-14,-7,0,7,14} do
					local p=direction*along+perpendicular*across
					requireFlat(p.X,p.Z,"full-width troop corridor "..id)
				end end
			end
			local entry=Vector3.new(0,0,Layout.groundSize/2-35)
			requireFlat(entry.X,entry.Z,"entry spawn")
		end)
		test("native collider surfaces match the shared triangle sampler without open seams",function()
			assert(surface.Name=="TerrainSurface" and surface:GetAttribute("GeneratedBy")=="CivilizationTopography")
			assert(finite(surface:GetAttribute("Seed")))
			assert(finite(surface:GetAttribute("GridStep")) and surface:GetAttribute("GridStep")>0)
			local triangles={}
			for _,part in surface:GetDescendants() do
				if part:IsA("BasePart") then
					assert(part.Anchored and part.CanCollide and part.CanQuery)
					if part:GetAttribute("SurfaceTriangle") then
						for _,name in {"VertexA","VertexB","VertexC"} do assert(typeof(part:GetAttribute(name))=="Vector3") end
						assert(type(part:GetAttribute("TriangleId"))=="number")
						triangles[part:GetAttribute("TriangleId")]={part:GetAttribute("VertexA"),part:GetAttribute("VertexB"),part:GetAttribute("VertexC")}
					end
				end
			end
			assert(next(triangles),"No actual connected triangle colliders were generated")
			local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances={container}
			for x=-760,760,80 do for z=-760,760,80 do
				for _,offset in {Vector2.zero,Vector2.new(19,23)} do
					local px,pz=x+offset.X,z+offset.Y
					local hit=workspace:Raycast(Vector3.new(px,180,pz),Vector3.new(0,-250,0),filter)
					assert(hit,"Missing collision support at "..px..","..pz)
					assert(math.abs(hit.Position.Y-Topography.sampleHeight(px,pz))<.08,"Rendered surface disagrees with its sampler at "..px..","..pz)
					if offset~=Vector2.zero then
						assert(hit.Normal:Dot(Topography.sampleNormal(px,pz))>.99,"Actual sloped collider normal disagrees with its sampler")
					end
				end
			end end
			local function seam(first,last,id,label)
				local middle=(first+last)/2
				local direction=Vector3.new(last.X-first.X,0,last.Z-first.Z).Unit
				local across=Vector3.new(-direction.Z,0,direction.X)
				for _,offset in {-.01,0,.01} do
					local point=middle+across*offset
					local hit=workspace:Raycast(Vector3.new(point.X,180,point.Z),Vector3.new(0,-250,0),filter)
					local expected=Topography.sampleHeight(point.X,point.Z)
					assert(hit and math.abs(hit.Position.Y-expected)<.08,
						"Native terrain seam at triangle "..id.." "..label.." offset="..offset.." expected="..expected.." actual="..tostring(if hit then hit.Position.Y else nil))
				end
			end
			for id,vertices in triangles do
				local a,b,c=vertices[1],vertices[2],vertices[3]
				seam(a,b,id,"edgeAB");seam(b,c,id,"edgeBC");seam(c,a,id,"edgeCA")
				local ab,ac,bc=b-a,c-a,c-b
				if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
				elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
				local base=c-b
				local foot=b+base*((a-b):Dot(base)/base:Dot(base))
				seam(a,foot,id,"internal half-wedge join")
			end
		end)
		test("relief geometry transforms with its world while sample coordinates remain local",function()
			local move=CFrame.new(2400,20,2400)*CFrame.Angles(0,.7,0)
			container:PivotTo(move*container:GetPivot())
			local filter=RaycastParams.new();filter.FilterType=Enum.RaycastFilterType.Include;filter.FilterDescendantsInstances={container}
			for _,sample in {Vector2.new(-360,280),Vector2.new(280,-360),Vector2.new(0,0),Vector2.new(640,120)} do
				local expected=move:PointToWorldSpace(Vector3.new(sample.X,Topography.sampleHeight(sample.X,sample.Y),sample.Y))
				local hit=workspace:Raycast(expected+move.UpVector*100,-move.UpVector*200,filter)
				assert(hit and (hit.Position-expected).Magnitude<.08,"Terrain did not transform as owned geometry")
			end
		end)
		test("owned terrain cleanup preserves unrelated developer geometry",function()
			container:Destroy()
			assert(surface.Parent==nil and sentinel.Parent==workspace)
		end)
		return count
	end)
	container:Destroy();sentinel:Destroy()
	assert(ok,result)
	return result
end

return function()
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local Layout=require(game.ReplicatedStorage.Shared.WorldConfig)
	local Landscape=require(game.ServerScriptService.Game.WorldLandscape)
	local Rules=require(game.ServerScriptService.Game.CombatRules)
	local container=Instance.new("Folder")
	container.Name,container.Parent="ExpandedLandscapeFixture",workspace
	local sentinel=Instance.new("Part")
	sentinel.Name,sentinel.Parent="ForeignDeveloperGeometry",container
	local count=0
	local function test(name,callback) callback(); count+=1; print("PASS: "..name) end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local root=world.model
		test("eight final plot reservations fit supported ground without overlapping each other or the expanded arena",function()
			assert(Layout.plotCount==8 and Layout.plotRadius==560 and Layout.maxPlotSize==256 and Layout.arenaRadius==250 and Layout.groundSize==1600)
			assert(root:GetAttribute("MaximumSettlementSize")==256 and root.Battlefield.Size.Y==500 and root.Ground.Size.X==1600)
			for id=1,8 do
				local frame=root.Plots["Plot"..id].Foundation.CFrame
				assert(math.abs(Vector3.new(frame.Position.X,0,frame.Position.Z).Magnitude-560)<.01)
				assert((frame.Position-root.Battlefield.Position).Magnitude-256/math.sqrt(2)>250)
				for other=id+1,8 do
					assert((frame.Position-root.Plots["Plot"..other].Foundation.Position).Magnitude>256*math.sqrt(2)+64,"Final plot bounding circles overlap")
				end
				for _,x in {-128,128} do for _,z in {-128,128} do
					local corner=root.Ground.CFrame:PointToObjectSpace(frame:PointToWorldSpace(Vector3.new(x,0,z)))
					assert(math.abs(corner.X)<=800 and math.abs(corner.Z)<=800)
				end end
				assert(root["Path"..id]:GetAttribute("ClearRouteWidth")==28)
			end
		end)
		test("five biomes have distinct visible ground materials plus water dry crossings and battlefield landmarks",function()
			local materials={Grassland=Enum.Material.Grass,Forest=Enum.Material.LeafyGrass,Desert=Enum.Material.Sand,SnowyHighlands=Enum.Material.Snow,Wetlands=Enum.Material.Mud}
			for name,material in materials do
				local biome=root.Landscape:FindFirstChild(name)
				assert(biome and biome:GetAttribute("Biome")==name and #biome:GetChildren()>0)
			end
			local seen,parts={},0
			for _,part in root.Landscape:GetDescendants() do
				if not part:IsA("BasePart") then continue end
				parts+=1
				assert(part.Name~="GroundPatch" and part.Name~="RollingHill" and part.Name~="DistantPeak","Old decorative terrain geometry remains")
				if part:IsDescendantOf(root.Landscape.TerrainSurface) then
					local biome=part:GetAttribute("Biome")
					assert(materials[biome] and part.Material==materials[biome],"Terrain collider lacks the correct visible biome material")
					seen[biome]=true
				end
			end
			for biome in materials do assert(seen[biome],"Biome lacks an actual ground surface: "..biome) end
			assert(parts<=2000,"Landscape exceeds its 2000 static-part budget: "..parts)
			local segments={}
			for _,segment in root.Landscape.Waterways.ShallowRiver:GetChildren() do
				assert(segment:IsA("BasePart") and segment.Transparency>0 and not segment.CanCollide)
				assert(typeof(segment:GetAttribute("PointA"))=="Vector3" and typeof(segment:GetAttribute("PointB"))=="Vector3")
				assert(type(segment:GetAttribute("Width"))=="number" and segment:GetAttribute("Width")>0)
				local index=segment:GetAttribute("SegmentIndex")
				assert(type(index)=="number" and not segments[index]);segments[index]=segment
			end
			assert(#segments>=4,"River lacks a connected meandering path")
			local winding=false
			for index,segment in segments do
				local a,b=segment:GetAttribute("PointA"),segment:GetAttribute("PointB")
				assert((b-a).Magnitude>1)
				if segments[index+1] then
					local nextSegment=segments[index+1]
					assert((b-nextSegment:GetAttribute("PointA")).Magnitude<.01,"River segments do not connect")
					local nextDirection=(nextSegment:GetAttribute("PointB")-b).Unit
					if (b-a).Unit:Cross(nextDirection).Magnitude>.05 then winding=true end
				end
			end
			assert(winding,"River remains a straight stripe")
			local bridges=0
			for _,bridge in root.Landscape.Waterways:GetChildren() do
				if bridge:IsA("Model") then
					bridges+=1
					assert(bridge:GetAttribute("RouteWidth")==28 and bridge.BridgeDeck.CanCollide)
					local position,plotId=bridge:GetAttribute("CrossingPosition"),bridge:GetAttribute("PlotId")
					assert(typeof(position)=="Vector3" and type(plotId)=="number")
					local direction=Vector3.new(Layout.plotFrame(plotId).Position.X,0,Layout.plotFrame(plotId).Position.Z).Unit
					assert(math.abs(bridge.BridgeDeck.CFrame.LookVector:Dot(direction))>.99,"Dry crossing does not follow its troop road")
					assert(math.abs(Landscape.sampleHeight(position.X,position.Z)-.15)<.001,"Bridge is outside its flat approach")
				end
			end
			assert(bridges==3 and #root.Landscape.BattlefieldFeatures.CombatBoundary:GetChildren()==64)
			for id=1,8 do assert(root.Landscape.BattlefieldFeatures:FindFirstChild("RuinedCourt"..id)) end
		end)
		test("landscape scenery avoids every final plot and critical lane while the larger arena remains authoritative",function()
			for _,object in root.Landscape:GetDescendants() do
				if object:IsA("Model") and typeof(object:GetAttribute("GroundPosition"))=="Vector3" then
					local position=object:GetAttribute("GroundPosition")
					assert(not Landscape.isReserved(position,object:GetAttribute("ClearanceRadius"),true),"Scenery occupies a reserved plot or army lane")
					assert(math.abs(position.Y-Landscape.sampleHeight(position.X,position.Z))<.01,"Scenery ground anchor floats above or is buried in terrain")
				end
			end
			local arena=root.Battlefield
			assert(Rules.containsArena(arena,arena.Position+Vector3.new(249,4,0)))
			assert(not Rules.containsArena(arena,arena.Position+Vector3.new(251,4,0)))
			local first={ownerId=101,alive=true,claimed=true,position=arena.Position+Vector3.new(248,4,0)}
			local enemy={ownerId=202,alive=true,claimed=true,position=arena.Position+Vector3.new(251,4,0)}
			assert(not Rules.canDamage(first,enemy,arena))
			local move=CFrame.new(2400,20,2400)*CFrame.Angles(0,.7,0)
			world.model:PivotTo(move*world.model:GetPivot())
			assert(Rules.containsArena(arena,move:PointToWorldSpace(Vector3.new(249,5,0))))
			assert(not Rules.containsArena(arena,move:PointToWorldSpace(Vector3.new(251,5,0))))
		end)
		test("generated landscape cleanup preserves unrelated developer geometry",function()
			local ground=root.Ground
			root:Destroy()
			assert(ground.Parent==nil and sentinel.Parent==container and #container:GetChildren()==1)
		end)
		return count
	end)
	container:Destroy()
	assert(ok,result)
	return result
end

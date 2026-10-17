--!strict

-- The shallow river is cosmetic Glass over ordinary ground, so material costs
-- alone cannot distinguish it. Keep its navigation regions with the scenery.
local WaterNavigation = {}
WaterNavigation.costs = table.freeze({RiverWater=40, Water=40})

function WaterNavigation.build(waterways: Folder)
	local regions=Instance.new("Folder")
	regions.Name,regions.Parent="NavigationRegions",waterways
	local bridges={}
	for _,bridge in waterways:GetChildren() do
		local deck=bridge:FindFirstChild("BridgeDeck")
		if deck then table.insert(bridges,deck) end
	end
	local function dry(corners): boolean
		for _,deck in bridges do
			local inside=true
			for _,point in corners do
				local p=deck.CFrame:PointToObjectSpace(point)
				if math.abs(p.X)>deck.Size.X/2-1 or math.abs(p.Z)>deck.Size.Z/2 then inside=false;break end
			end
			if inside then return true end
		end
		return false
	end
	local function region(water,x1,x2,z1,z2)
		local region=Instance.new("Part")
		region.Name="RiverAvoidance"
		-- Native navigation ignores CanQuery=false modifiers. Keep the queryable
		-- volume at ankle height, below attack/bandage rays and bridge surfaces.
		region.Size=Vector3.new(x2-x1,1,z2-z1)
		region.CFrame=water.CFrame*CFrame.new((x1+x2)/2,0,(z1+z2)/2)
		region.Anchored,region.CanCollide,region.CanQuery,region.CanTouch=true,false,true,false
		region.Transparency=1
		local modifier=Instance.new("PathfindingModifier")
		modifier.Label,modifier.Parent="RiverWater",region
		region.Parent=regions
	end
	for _,water in waterways.ShallowRiver:GetChildren() do
		local hx,hz=water.Size.X/2+3,water.Size.Z/2+3
		local near=false
		for _,deck in bridges do
			if (deck.Position-water.Position).Magnitude<(deck.Size.Magnitude+water.Size.Magnitude)/2+8 then near=true;break end
		end
		if not near then region(water,-hx,hx,-hz,hz);continue end
		-- Remove only whole dry cells from the expensive region. This avoids
		-- overlapping modifier priority and leaves a cheap corridor on the deck.
		local nx,nz=math.ceil(hx*2/6),math.ceil(hz*2/6)
		for ix=0,nx-1 do
			local x1,x2=-hx+ix*hx*2/nx,-hx+(ix+1)*hx*2/nx
			local run=nil
			for iz=0,nz do
				local z1=-hz+iz*hz*2/nz
				local z2=-hz+(iz+1)*hz*2/nz
				local clear=iz==nz or dry({
					water.CFrame:PointToWorldSpace(Vector3.new(x1,0,z1)),water.CFrame:PointToWorldSpace(Vector3.new(x2,0,z1)),
					water.CFrame:PointToWorldSpace(Vector3.new(x1,0,z2)),water.CFrame:PointToWorldSpace(Vector3.new(x2,0,z2)),
				})
				if clear and run then region(water,x1,x2,run,z1);run=nil
				elseif not clear and not run then run=z1 end
			end
		end
	end
end

local function wet(waterways: Folder,point: Vector3): boolean
	for _,bridge in waterways:GetChildren() do
		local deck=bridge:FindFirstChild("BridgeDeck")
		if not deck then continue end
		local p=deck.CFrame:PointToObjectSpace(point)
		if math.abs(p.X)<=deck.Size.X/2-2 and math.abs(p.Z)<=deck.Size.Z/2 then return false end
	end
	for _,water in waterways.ShallowRiver:GetChildren() do
		local p=water.CFrame:PointToObjectSpace(point)
		if math.abs(p.X)<=water.Size.X/2+2 and math.abs(p.Z)<=water.Size.Z/2+2 then return true end
	end
	return false
end

-- Short direct steering must not bypass the pathfinder's water preference.
-- A displaced unit already in water may still take a short exit onto dry land.
function WaterNavigation.allowsDirect(world: Model,from: Vector3,to: Vector3): boolean
	local landscape=world:FindFirstChild("Landscape")
	local waterways=if landscape then landscape:FindFirstChild("Waterways") else nil
	if not waterways then return true end
	local escaping=wet(waterways,from)
	local samples=math.max(1,math.ceil((to-from).Magnitude/2))
	for index=1,samples do
		local inWater=wet(waterways,from:Lerp(to,index/samples))
		if inWater and not escaping then return false end
		if not inWater then escaping=false end
		if index==samples and inWater then return false end
	end
	return true
end

return WaterNavigation

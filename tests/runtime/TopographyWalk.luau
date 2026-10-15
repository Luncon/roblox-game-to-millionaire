-- One actual server-owned Humanoid walks uphill and downhill. No extra players,
-- owner identity simulation, damage authority or post-spawn pivots are needed.
return function()
	local Run=game:GetService("RunService")
	assert(Run:IsStudio(),"Topography walking is a Studio engine fixture")
	local Game=game.ServerScriptService.Game
	local Topography,Map,Rig,Navigator,Rules=require(Game.Topography),require(Game.BattlefieldMap),require(Game.WarriorRig),require(Game.WarriorNavigator),require(Game.CombatRules)
	local catalog=require(game.ReplicatedStorage.Shared.Civilizations)
	local container=Instance.new("Folder")
	container.Name,container.Parent="ActualTopographyWalkFixture",workspace
	local heartbeat,navigator,rig
	local active,failure=true,nil
	local cases,evidence=0,{}
	local function test(name,callback) callback();cases+=1;print("PASS: "..name) end
	local function flat(v) return Vector3.new(v.X,0,v.Z) end
	local function waitFor(predicate,description,timeout)
		local deadline=os.clock()+(timeout or 30)
		repeat assert(not failure,failure);if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Timed out: "..description)
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local transform=CFrame.new(3200,0,-2600)*CFrame.Angles(0,.3,0)
		world.model:PivotTo(transform*world.model:GetPivot())
		local arena=world.model.Battlefield
		local surfaceFilter=RaycastParams.new()
		surfaceFilter.FilterType=Enum.RaycastFilterType.Include
		surfaceFilter.FilterDescendantsInstances={world.model.Ground,world.model.Landscape.TerrainSurface}
		local obstacles={}
		for _,child in world.model.Landscape:GetChildren() do if child.Name~="TerrainSurface" then table.insert(obstacles,child) end end
		local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include
		overlap.FilterDescendantsInstances=obstacles;overlap.RespectCanCollide=true
		local function position(sample)
			return transform:PointToWorldSpace(Vector3.new(sample.x,sample.h,sample.z))
		end
		local function clear(sample)
			local point=position(sample)
			return #workspace:GetPartBoundsInBox(CFrame.new(point+Vector3.new(0,3,0))*transform.Rotation,Vector3.new(5,6,5),overlap)==0
		end
		local candidates={}
		for x=-220,220,10 do for z=-220,220,10 do
			if x*x+z*z>220^2 or x*x+z*z<60^2 then continue end
			local sample={x=x,z=z,h=Topography.sampleHeight(x,z)}
			if clear(sample) then table.insert(candidates,sample) end
		end end
		table.sort(candidates,function(a,b) return a.h>b.h end)
		local high,low
		for _,upper in candidates do
			if upper.h<=2.15 then break end
			local score=math.huge
			for _,lower in candidates do
				local distance=Vector2.new(upper.x-lower.x,upper.z-lower.z).Magnitude
				if upper.h-lower.h>=2 and distance>=35 and distance<=140 then
					local nextScore=distance+lower.h*10
					if nextScore<score then high,low,score=upper,lower,nextScore end
				end
			end
			if high then break end
		end
		assert(high and low,"No unblocked arena slope has at least two studs of actual relief")
		for _,sample in {low,high} do
			local point=position(sample)
			local hit=workspace:Raycast(point+Vector3.new(0,100,0),Vector3.new(0,-150,0),surfaceFilter)
			assert(hit and (hit.Position-point).Magnitude<.08,"Slope endpoints lack matching native collider support")
		end
		rig=Rig.create(catalog[1],CFrame.new(position(low)+Vector3.new(0,4,0)),-99001,1,nil,"ranged")
		rig.Parent=world.model.Troops;rig.HumanoidRootPart:SetNetworkOwner(nil)
		navigator=Navigator.new(rig,function() return active and rig.Parent~=nil and rig.Humanoid.Health>0 end)
		local last,lastTime=rig.HumanoidRootPart.Position,os.clock()
		local movingPose=false
		heartbeat=Run.Heartbeat:Connect(function()
			local success,message=pcall(function()
				navigator:step(os.clock())
				local root=rig.HumanoidRootPart
				local now=os.clock()
				assert(flat(root.Position-last).Magnitude<=8+(now-lastTime)*45,"Slope traversal jumped instead of walking")
				last,lastTime=root.Position,now
				assert(root:GetNetworkOwner()==nil and not root.Anchored and Rules.containsArena(arena,root.Position))
				local moving=root.AssemblyLinearVelocity.Magnitude>.5
				Rig.animate(rig,now,moving,false)
				local hip=rig.Torso:FindFirstChild("Right Hip")
				if moving and hip and hip.C0~=hip:GetAttribute("RestC0") then movingPose=true end
			end)
			if not success then failure=tostring(message) end
		end)
		local function supported(sample)
			local root=rig.HumanoidRootPart
			local localPoint=transform:PointToObjectSpace(root.Position)
			local floor=Topography.sampleHeight(localPoint.X,localPoint.Z)
			local hit=workspace:Raycast(root.Position+Vector3.new(0,1,0),Vector3.new(0,-12,0),surfaceFilter)
			assert(hit and math.abs(hit.Position.Y-floor)<.08,"Walking Humanoid lost collision support")
			assert(root.Position.Y-hit.Position.Y>=1 and root.Position.Y-hit.Position.Y<=6,"Humanoid is buried or hovering above the slope")
			assert(math.abs(floor-sample.h)<.6,"Humanoid did not reach the intended endpoint elevation")
		end
		local function walk(sample)
			local goal=position(sample)+Vector3.new(0,4,0)
			local started=os.clock()
			navigator:setGoal(goal)
			waitFor(function() return flat(rig.HumanoidRootPart.Position-goal).Magnitude<2 end,"physical slope destination",40)
			navigator:stop();task.wait(.35)
			supported(sample)
			return os.clock()-started
		end
		test("an actual Humanoid physically gains height while walking uphill on connected arena terrain",function()
			task.wait(.5);supported(low)
			local initialY=rig.HumanoidRootPart.Position.Y
			evidence.uphillSeconds=walk(high)
			evidence.verticalGain=rig.HumanoidRootPart.Position.Y-initialY
			assert(evidence.verticalGain>=1 and movingPose,"Uphill walk did not produce at least one stud of actual animated vertical movement")
		end)
		test("the same living server-owned Humanoid walks downhill without reset damage or lost combat eligibility",function()
			local upperY=rig.HumanoidRootPart.Position.Y
			evidence.downhillSeconds=walk(low)
			assert(upperY-rig.HumanoidRootPart.Position.Y>=1)
			assert(rig.Humanoid.Health==100 and rig.HumanoidRootPart:GetNetworkOwner()==nil)
			assert(Rules.containsArena(arena,rig.HumanoidRootPart.Position))
		end)
		evidence.low={x=low.x,z=low.z,height=low.h}
		evidence.high={x=high.x,z=high.z,height=high.h}
		evidence.horizontalDistance=Vector2.new(high.x-low.x,high.z-low.z).Magnitude
		return {ok=true,cases=cases,evidence=evidence,message="One real Humanoid walked uphill/downhill over native arena slopes with supported feet, server physics and unchanged combat height eligibility"}
	end)
	active=false
	if heartbeat then heartbeat:Disconnect() end
	if navigator then navigator:destroy() end
	container:Destroy()
	assert(ok,result)
	return result
end

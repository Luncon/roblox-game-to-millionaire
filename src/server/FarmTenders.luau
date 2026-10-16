--!strict

-- Passive scenery: anchored poses and an inert appearance Humanoid; no combat actor.
local Tenders={}
local Sites=require(game.ReplicatedStorage.Shared.SettlementSites)
local records={}
local allowed={Model=true,Folder=true,Accessory=true,Part=true,MeshPart=true,
	SpecialMesh=true,BlockMesh=true,CylinderMesh=true,Decal=true,Texture=true,
	SurfaceAppearance=true,Attachment=true,Motor6D=true,Weld=true,
	Shirt=true,Pants=true,ShirtGraphic=true,BodyColors=true}

function Tenders.prepare(template)
	local rig=template:Clone()
	for _,item in rig:GetDescendants()do
		if not allowed[item.ClassName]then item:Destroy()end
	end
	for _,item in {rig,table.unpack(rig:GetDescendants())}do
		for key in item:GetAttributes()do item:SetAttribute(key,nil)end
		for _,tag in item:GetTags()do item:RemoveTag(tag)end
		if item:IsA("BasePart")then
			item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false
			item.AssemblyLinearVelocity,item.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
		elseif item:IsA("JointInstance")then
			if not item.Part0 or not item.Part1 or not item.Part0:IsDescendantOf(rig) or not item.Part1:IsDescendantOf(rig)then item:Destroy()end
		end
	end
	local root=rig:FindFirstChild("HumanoidRootPart")
	assert(root and root:IsA("BasePart") and rig:FindFirstChild("LeftFoot") and rig:FindFirstChild("RightFoot"),"Farmer template needs its connected R15 body")
	root.Transparency=1;rig.PrimaryPart=root
	local parts={root}
	local ids={[root]=1}
	local pending={}
	for _,d in rig:GetDescendants()do
		if d:IsA("BasePart") and d~=root then table.insert(parts,d);ids[d]=#parts end
		if d:IsA("JointInstance")then table.insert(pending,d)end
	end
	local links,connected={}, {[1]=true}
	repeat
		local progressed=false
		for i=#pending,1,-1 do
			local joint=pending[i]
			local a,b=ids[joint.Part0],ids[joint.Part1]
			if connected[a] and not connected[b]then
				table.insert(links,{a=a,b=b,c0=joint.C0,c1=joint.C1:Inverse(),name=joint.Name})
				connected[b]=true;table.remove(pending,i);progressed=true
			end
		end
	until not progressed
	for _,name in {"Head","UpperTorso","LeftHand","RightHand","LeftFoot","RightFoot"}do
		assert(connected[ids[rig:FindFirstChild(name)]],"Disconnected farmer body: "..name)
	end
	local loose={}
	for i,p in parts do
		if not connected[i]then
			local anchor=if p:FindFirstAncestorOfClass("Accessory") then rig.Head else root
			table.insert(loose,{part=i,anchor=ids[anchor],offset=anchor.CFrame:ToObjectSpace(p.CFrame)})
		end
	end
	local footY=math.huge
	for _,name in {"LeftFoot","RightFoot"}do
		local p=rig[name];footY=math.min(footY,root.CFrame:PointToObjectSpace(p.Position).Y-p.Size.Y/2)
	end
	records[rig]={parts=parts,links=links,loose=loose,height=-footY,left=ids[rig.LeftFoot],right=ids[rig.RightFoot]}
	rig.Destroying:Connect(function() records[rig]=nil end)
	-- Classic clothing needs a Humanoid to render. Never import its behavior/stats.
	local appearance=Instance.new("Humanoid")
	appearance.RigType=Enum.HumanoidRigType.R15
	appearance.EvaluateStateMachine,appearance.AutoRotate=false,false
	appearance.WalkSpeed,appearance.JumpPower,appearance.JumpHeight=0,0,0
	appearance.BreakJointsOnDeath,appearance.RequiresNeck=false,false
	appearance.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	appearance.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
	appearance.Parent=rig
	return rig
end

function Tenders.pose(rig,frame,swing,working)
	local record=records[rig]
	assert(record,"Farmer must be prepared before posing")
	local parts=record.parts
	parts[1].CFrame=frame*CFrame.new(0,record.height,0)
	for _,link in record.links do
		local angle=0
		if working then
			if link.name=="Waist" then angle=.14+math.abs(swing)*.12
			elseif link.name=="RightShoulder" or link.name=="LeftShoulder" then angle=-.55+swing*.25
			elseif link.name=="RightElbow" or link.name=="LeftElbow" then angle=-.3 end
		else
			if link.name=="LeftHip" or link.name=="RightShoulder"then angle=swing
			elseif link.name=="RightHip" or link.name=="LeftShoulder"then angle=-swing
			elseif link.name=="LeftKnee"then angle=math.max(0,-swing)*.5
			elseif link.name=="RightKnee"then angle=math.max(0,swing)*.5 end
		end
		parts[link.b].CFrame=parts[link.a].CFrame*link.c0*CFrame.Angles(angle,0,0)*link.c1
	end
	for _,item in record.loose do parts[item.part].CFrame=parts[item.anchor].CFrame*item.offset end
	-- Set the lower foot on the soil, including during the walk's lifted step.
	local lowest=math.huge
	for _,index in {record.left,record.right}do
		local p=parts[index];lowest=math.min(lowest,frame:PointToObjectSpace(p.Position).Y-p.Size.Y/2)
	end
	local correction=frame.UpVector*(-lowest)
	for _,p in parts do p.CFrame+=correction end
end

local routes={}
local function route(level)
	local tier=if level>=2 then 2 else 1
	if routes[tier]then return routes[tier]end
	local rows,spacing=if tier==2 then 3 else 2,if tier==2 then 5 else 6
	local position=Vector3.new(-21,0,-rows*spacing)
	local facing=Vector3.zAxis
	local segments,total={},0
	local function segment(a,b,seconds,working,walking)
		table.insert(segments,{a=a,b=b,start=total,duration=seconds,working=working,walking=walking})
		total+=seconds
	end
	local function move(target)
		local direction=(target-position).Unit
		if facing:Dot(direction)<.999 then
			segment(CFrame.lookAt(position,position+facing),CFrame.lookAt(position,position+direction),.6,false,false)
		end
		segment(CFrame.lookAt(position,position+direction),CFrame.lookAt(target,target+direction),(target-position).Magnitude/4,false,true)
		position,facing=target,direction
	end
	for row=-rows,rows do
		local sign=if (row+rows)%2==0 then 1 else -1
		if row> -rows then move(Vector3.new(-sign*21,0,row*spacing))end
		move(Vector3.new(0,0,row*spacing))
		local frame=CFrame.lookAt(position,position+facing)
		segment(frame,frame,2,true,false)
		move(Vector3.new(sign*21,0,row*spacing))
	end
	-- Continuous return along the margins, inside fences and irrigation channels.
	move(Vector3.new(23,0,rows*spacing))
	move(Vector3.new(23,0,-rows*spacing-2))
	move(Vector3.new(-21,0,-rows*spacing-2))
	move(Vector3.new(-21,0,-rows*spacing))
	local result={segments=segments,duration=total}
	routes[tier]=result;return result
end

function Tenders.cycle(level)
	return route(level).duration
end

function Tenders.sample(level,elapsed,index)
	local path=route(level)
	local offset=if index==3 then path.duration*.5 elseif index==2 then path.duration*.23 else 0
	local time=(math.max(0,elapsed)+offset)%path.duration
	for _,segment in path.segments do
		if time<segment.start+segment.duration then
			local frame=segment.a:Lerp(segment.b,(time-segment.start)/segment.duration)
			local site=Sites.fields[if index==2 then 2 else 1]
			return CFrame.new(site+Vector3.new(0,-.4,0))*frame,segment.working,segment.walking
		end
	end
	error("Invalid farmer route time")
end

function Tenders.animate(rig,plotFrame,now)
	local elapsed=now-rig:GetAttribute("TendingStartedAt")
	local frame,working,walking=Tenders.sample(rig:GetAttribute("FarmLevel"),elapsed,rig:GetAttribute("WorkerIndex"))
	local swing=if walking then math.sin(elapsed*6.5)*.42 elseif working then math.sin(elapsed*3)*.3 else 0
	Tenders.pose(rig,plotFrame*frame,swing,working)
	local activity=if working then "Tending" elseif walking then "Walking" else "Turning"
	if rig:GetAttribute("Activity")~=activity then rig:SetAttribute("Activity",activity)end
end

function Tenders.create(parent,plotFrame,civ,index,level)
	local folder=game.ServerStorage:FindFirstChild("FarmTemplates")
	local template=folder and folder:FindFirstChild("farmer")
	assert(template,"Farmer asset missing: sync ServerStorage.FarmTemplates with Rojo")
	local rig=Tenders.prepare(template)
	rig.Name="Farmer"..index
	rig:SetAttribute("PassiveWorker",true)
	rig:SetAttribute("CivilizationId",civ.id)
	rig:SetAttribute("WorkerIndex",index)
	rig:SetAttribute("FarmLevel",level)
	rig:SetAttribute("TendingStartedAt",os.clock())
	Tenders.animate(rig,plotFrame,os.clock())
	rig.Parent=parent
	return rig
end

return Tenders

-- Exhaustive native audit. Geometry expectations do not use SettlementGeometry helpers.
return function(context,player)
	assert(game:GetService("RunService"):IsStudio())
	assert(context and context.store.isFakeProfileStore,"Geometry runner requires the test-only fake store")
	local Map=require(game.ServerScriptService.Game.BattlefieldMap)
	local civilizations=require(game.ReplicatedStorage.Shared.Civilizations)
	local definitions=require(game.ReplicatedStorage.Shared.PadCatalog).byAction
	local container=Instance.new("Folder");container.Name="SettlementGeometryMatrix";container.Parent=workspace
	local probes={}
	local report={variants=0,civilizations=#civilizations,levels=50,transforms=2,failureCount=0,failureKinds={},firstPerKind={},examples={},
		architecturalParts=0,nativeContactQueries=0,crossBuildingQueries=0,padChecks=0,padSupportChecks=0,skillPadChecks=0,completedSkillPads=0,roofChecks=0,atticChecks=0,maximumSettlementParts=0}
	local label,civilizationId="initializing","initializing"
	local exampleKeys={}
	local function issue(kind,detail)
		report.failureCount+=1
		report.failureKinds[kind]=(report.failureKinds[kind]or 0)+1
		local example={variant=label,kind=kind,detail=detail}
		report.firstPerKind[kind]=report.firstPerKind[kind]or example
		local key=kind..":"..civilizationId
		if not exampleKeys[key]and #report.examples<40 then table.insert(report.examples,example);exampleKeys[key]=true end
	end
	local function passive(part,root)
		local ancestor=part.Parent
		while ancestor and ancestor~=root do
			if ancestor:GetAttribute("PassiveWorker")==true then return true end
			ancestor=ancestor.Parent
		end
		return false
	end
	local function probe(part,inset)
		local class=part.ClassName
		local p=probes[class]
		if not p then
			p=Instance.new(class);p.Name="OwnedNativeGeometryProbe";p.Anchored=true;p.CanCollide=false
			p.CanTouch=false;p.CanQuery=false;p.Transparency=1;p.Parent=container;probes[class]=p
		end
		if p:IsA("Part")then p.Shape=part.Shape end
		p.CFrame=part.CFrame
		p.Size=Vector3.new(math.max(.01,part.Size.X+inset),math.max(.01,part.Size.Y+inset),math.max(.01,part.Size.Z+inset))
		return p
	end
	local function state(level)
		return {coins=10000,level=level,weaponLevel=math.min(level,4),armorLevel=math.min(level,4),
			barracksLevel=if level>=14 then 6 elseif level>=8 then 5 elseif level>=4 then 4 elseif level>=3 then 3 elseif level>=2 then 2 else 0,
			trainingLevel=if level>=5 then 1 else 0,farmLevel=if level>=12 then 2 elseif level>=7 then 1 else 0,
			workersLevel=if level>=12 then 2 elseif level>=7 then 1 else 0,armyCampLevel=if level>=10 then 1 else 0,
			farmCoins=0,extraTroopClass="warrior",blacksmithLevel=if level>=13 then 1 else 0,
			armorerLevel=if level>=13 then 1 else 0,storehouseLevel=if level>=16 then 1 else 0,skillLevel=0}
	end
	local function nativeFilter(parts)
		local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=parts
		return params
	end
	local function bounds(part,frame)
		local minimum,maximum=Vector3.one*math.huge,-Vector3.one*math.huge
		for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
			local point=frame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
			minimum=minimum:Min(point);maximum=maximum:Max(point)
		end end end
		return minimum,maximum
	end
	local ok,result=pcall(function()
		local world=Map.build(container)
		local originalPivot=world.model:GetPivot()
		local plot=world.model.Plots.Plot1
		local terrain={world.model.Ground,world.model.Landscape.TerrainSurface}
		local function group(part)
			local current,building=part,nil
			while current.Parent and current.Parent~=plot.Settlement and current.Parent~=plot.Infrastructure and current.Parent~=plot.Controls do
				if current.Parent:IsA("Model")then building=current.Parent end
				current=current.Parent
			end
			if current.Parent==plot.Controls then return current end
			if current.Parent==plot.Infrastructure then return building or (if current:IsA("Model")then current else plot.Infrastructure)end
			if current.Parent==plot.Settlement then
				if building then return building end
				if current.Name=="GrandIdentityHost"then return plot.Settlement.GrowthFeature_30:FindFirstChildWhichIsA("Model")end
				if current.Name=="Camp"then return plot.Settlement:FindFirstChild("Barracks")or current end
				if current:IsA("Folder")or current:IsA("Model")then return current end
				return plot.Settlement -- Starter architecture shares intentional joints.
			end
			return current
		end
		local function audit(value)
			local frame,half=plot.Foundation.CFrame,plot.Foundation.Size.X/2
			local parts,indices,flags,groups,skins={},{},{},{},{}
			local settlementParts=0
			for _,root in {plot.Settlement,plot.Infrastructure,plot.Controls}do
				for _,part in root:GetDescendants()do if part:IsA("BasePart")and not passive(part,root)then
					table.insert(parts,part);indices[part]=#parts
					flags[part]=part.CanQuery;part.CanQuery=true;groups[part]=group(part)
					local low,high=bounds(part,frame)
					local horizontal=math.abs(part.CFrame.UpVector:Dot(frame.UpVector))>.999
					-- Foundation/ground surface layers may intentionally meet walls.
					skins[part]=horizontal and high.Y-low.Y<=.35 and high.Y<=1.35
					if root==plot.Settlement then
						settlementParts+=1
						if math.max(math.abs(low.X),math.abs(high.X),math.abs(low.Z),math.abs(high.Z))>half+.05 then issue("bounds",part:GetFullName())end
						if not skins[part]and low.Y<.95 then issue("foundation penetration",part:GetFullName().." bottom="..low.Y)end
					end
				end end
			end
			report.architecturalParts+=#parts;report.maximumSettlementParts=math.max(report.maximumSettlementParts,settlementParts)
			if settlementParts>400 then issue("part budget",tostring(settlementParts))end
			local filter=nativeFilter({plot.Settlement,plot.Infrastructure,plot.Controls,plot.Foundation,terrain[1],terrain[2]})
			local contacts,connected={},{ }
			local queue={}
			for index,part in parts do
				contacts[index]={}
				local hits=workspace:GetPartsInPart(probe(part,.1),filter);report.nativeContactQueries+=1
				local crossing={}
				for _,other in hits do
					local otherIndex=indices[other]
					if otherIndex and other~=part then
						table.insert(contacts[index],otherIndex)
						if otherIndex>index and groups[other]~=groups[part]and not skins[part]and not skins[other]then table.insert(crossing,other)end
					elseif other==plot.Foundation or other==terrain[1]or other:IsDescendantOf(terrain[2])then
						if not connected[index]then connected[index]=true;table.insert(queue,index)end
					end
				end
				if #crossing>0 then
					local overlaps=workspace:GetPartsInPart(probe(part,-.04),nativeFilter(crossing));report.crossBuildingQueries+=1
					for _,other in overlaps do issue("independent structure overlap",part:GetFullName().." intersects "..other:GetFullName())end
				end
			end
			local cursor=1
			while queue[cursor]do
				for _,neighbor in contacts[queue[cursor]]do if not connected[neighbor]then connected[neighbor]=true;table.insert(queue,neighbor)end end
				cursor+=1
			end
			-- Report one representative per unsupported component, not every piece.
			for index,part in parts do if not connected[index]then
				issue("unsupported component",part:GetFullName())
				local pending={index};connected[index]=true;local position=1
				while pending[position]do for _,neighbor in contacts[pending[position]]do if not connected[neighbor]then connected[neighbor]=true;table.insert(pending,neighbor)end end;position+=1 end
			end end
			local roofGroups={}
			for _,part in parts do if part.Name=="RoofSlope"then
				local id=groups[part];roofGroups[id]=roofGroups[id]or {};table.insert(roofGroups[id],part)
			end end
			local wallNames={CivicHouse=true,TimberHall=true,BarkLonghouse=true,TimberLonghall=true,BrickManor=true,ColonialHall=true,InnerHall=true}
			for assembly,roofs in roofGroups do
				local gables={}
				for _,part in parts do if groups[part]==assembly and part:IsA("WedgePart")then table.insert(gables,part)end end
				if #gables<2 then issue("missing pitched attic geometry",assembly:GetFullName())end
				for _,body in parts do if groups[body]==assembly and wallNames[body.Name]then
					for _,x in {-1,1}do for _,z in {-1,1}do
						local point=body.CFrame:PointToWorldSpace(Vector3.new(x*body.Size.X/2,body.Size.Y/2,z*body.Size.Z/2))
						local covered=false
						for _,roof in roofs do local p=roof.CFrame:PointToObjectSpace(point)
							if math.abs(p.X)<=roof.Size.X/2+.02 and math.abs(p.Z)<=roof.Size.Z/2+.02 and p.Y<=roof.Size.Y/2+.05 then covered=true end
						end
						report.roofChecks+=1;if not covered then issue("wall above roof exterior",body:GetFullName().." corner "..x..","..z)end
					end end
					if #gables>=2 then
						local low=math.huge
						for _,gable in gables do local a=bounds(gable,body.CFrame);low=math.min(low,a.Y)end
						for _,x in {-body.Size.X*.2,0,body.Size.X*.2}do
							local roofUnder=-math.huge
							local origin=body.CFrame:PointToWorldSpace(Vector3.new(x,0,0))
							for _,roof in roofs do
								local normal=roof.CFrame.UpVector
								local denominator=normal:Dot(body.CFrame.UpVector)
								if math.abs(denominator)>.01 then
									local underside=roof.CFrame:PointToWorldSpace(Vector3.new(0,-roof.Size.Y/2,0))
									local distance=normal:Dot(underside-origin)/denominator
									local p=roof.CFrame:PointToObjectSpace(origin+body.CFrame.UpVector*distance)
									if math.abs(p.X)<=roof.Size.X/2+.02 and math.abs(p.Z)<=roof.Size.Z/2+.02 then roofUnder=math.max(roofUnder,distance)end
								end
							end
							if roofUnder>low+.2 then
							local sample=probes.Attic
							if not sample then
								sample=Instance.new("Part");sample.Name="OwnedAtticVolumeProbe";sample.Anchored=true
								sample.CanCollide=false;sample.CanTouch=false;sample.CanQuery=false;sample.Transparency=1
								sample.Size=Vector3.one*.04;sample.Parent=container;probes.Attic=sample
							end
							for _,z in {-body.Size.Z*.35,body.Size.Z*.35}do
								sample.CFrame=body.CFrame*CFrame.new(x,low+(roofUnder-low)*.85,z)
								report.atticChecks+=1
								if #workspace:GetPartsInPart(sample,nativeFilter(gables))==0 then issue("empty or inverted attic wedge",body:GetFullName().." x="..x.." z="..z)end
							end
							else issue("invalid pitched attic height",body:GetFullName().." x="..x)end
						end
					end
				end end
			end
			-- Furniture is not an architectural joint merely because it shares a
			-- house Model. Check it against its wall shell and raised footing.
			for _,building in plot.Infrastructure:GetChildren()do if building:IsA("Model")then
				local shells={}
				for _,part in building:GetChildren()do if part:IsA("BasePart")and
					(part.Name=="FoundationFooting"or part.Name=="CivicHouse"or part.Name=="TimberHall"or part.Name=="LacquerHall"
					or part.Name=="AssemblyBase"or part.Name=="CivicChamber"or part.Name=="Sanctuary"or part.Name=="FeltYurt")then table.insert(shells,part)end end
				if #shells>0 then for _,furniture in building:GetChildren()do
					if furniture:IsA("BasePart")and (furniture.Name=="GrainCrate"or furniture.Name=="AnvilBase"or furniture.Name=="ForgeGlow"
						or furniture.Name=="ArmorStand"or furniture.Name=="DisplayArmor")then
						if #workspace:GetPartsInPart(probe(furniture,-.04),nativeFilter(shells))>0 then issue("outdoor furniture intersects house",furniture:GetFullName())end
					end
				end end
			end end
			local collisionParts={}
			for _,part in parts do if part.CanCollide and not part:IsDescendantOf(plot.Controls)then table.insert(collisionParts,part)end end
			local collisionFilter=nativeFilter(collisionParts)
			if value.level>=2 then
				for _,kind in {"warrior","ranged"}do
					if #workspace:GetPartBoundsInBox(world:getBarracksSpawn(1,kind),Vector3.new(3,5,3),collisionFilter)>0 then issue("barracks spawn blocked",kind)end
				end
				if #workspace:GetPartBoundsInBox(frame*CFrame.new(-36,4,-half/2+2),Vector3.new(8,5,half+4),collisionFilter)>0 then issue("arena exit blocked","level "..value.level)end
			end
			local function checkPads()
				-- syncControls also rebuilds Infrastructure. Never retain collision
				-- filters or support candidates from the preceding purchase state.
				local liveParts,liveCollision,liveFlags={},{},{}
				for _,root in {plot.Settlement,plot.Infrastructure}do for _,part in root:GetDescendants()do
					if part:IsA("BasePart")and not passive(part,root)then
						table.insert(liveParts,part);liveFlags[part]=part.CanQuery;part.CanQuery=true
						if part.CanCollide then table.insert(liveCollision,part)end
					end
				end end
				local liveCollisionFilter=nativeFilter(liveCollision)
				for _,pad in plot.Controls:GetChildren()do if pad:IsA("BasePart")then
					report.padChecks+=1
					if pad:GetAttribute("Action")=="skill"then report.skillPadChecks+=1 end
					local definition=definitions[pad:GetAttribute("Action")]
					if not definition then issue("pad action",pad.Name);continue end
					local expected=frame*CFrame.new(definition.x,definition.y or 2,definition.z)
					if (pad.Position-expected.Position).Magnitude>.002 or pad.Size~=Vector3.new(8,1,6)then issue("pad coordinates changed",pad.Name)end
					if pad.CFrame.RightVector:Dot(expected.RightVector)<.99999 or pad.CFrame.UpVector:Dot(expected.UpVector)<.99999
						or pad.CFrame.LookVector:Dot(expected.LookVector)<.99999 then issue("pad orientation changed",pad.Name)end
					local candidates={plot.Foundation,terrain[1],terrain[2]}
					for _,part in liveParts do table.insert(candidates,part)end
					local groundRay=RaycastParams.new();groundRay.FilterType=Enum.RaycastFilterType.Include
					-- Capture architecture/ground before adding any support children;
					-- neither pad nor its support subtree may certify itself.
					groundRay.FilterDescendantsInstances=table.clone(candidates)
					local ownedFlags={}
					for _,part in pad:GetDescendants()do if part:IsA("BasePart")then
						ownedFlags[part]=part.CanQuery;part.CanQuery=true;table.insert(candidates,part)
						if part.CanTouch or part:GetAttribute("Action")~=nil then issue("pad support input",pad.Name)end
						local low,high=bounds(part,pad.CFrame)
						if math.max(math.abs(low.X),math.abs(high.X))>pad.Size.X/2+.01 or math.max(math.abs(low.Z),math.abs(high.Z))>pad.Size.Z/2+.01 then issue("pad support footprint",pad.Name)end
						for _,item in part:GetDescendants()do if item:IsA("ClickDetector")or item:IsA("ProximityPrompt")or item:IsA("LuaSourceContainer")then issue("pad support handler",pad.Name)end end
						local bottom=part.CFrame:PointToWorldSpace(Vector3.new(0,-part.Size.Y/2,0))
						local hit=workspace:Raycast(bottom+frame.UpVector*.02,-frame.UpVector*6,groundRay)
						report.padSupportChecks+=1
						if not hit or (bottom-hit.Position):Dot(frame.UpVector)>.05 then issue("unsupported pad footing",pad.Name.."/"..part.Name)end
					end end
					local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances=candidates
					local bottom=pad.CFrame:PointToWorldSpace(Vector3.new(0,-pad.Size.Y/2,0))
					local hit=workspace:Raycast(bottom+frame.UpVector*.02,-frame.UpVector*6,ray)
					if not hit or (bottom-hit.Position):Dot(frame.UpVector)>.05 then issue("unsupported pad",pad.Name)end
					if #workspace:GetPartBoundsInBox(pad.CFrame*CFrame.new(0,3.5,0),Vector3.new(6,6,4),liveCollisionFilter)>0 then issue("pad standing room",pad.Name)end
					for part,flag in ownedFlags do if part.Parent then part.CanQuery=flag end end
				end end
				for part,flag in liveFlags do if part.Parent then part.CanQuery=flag end end
			end
			checkPads()
			for _,phase in {"offers","workers"}do
				local alternative=table.clone(value)
				alternative.trainingLevel,alternative.armyCampLevel,alternative.blacksmithLevel,alternative.armorerLevel,alternative.storehouseLevel=0,0,0,0,0
				alternative.farmLevel=if phase=="workers"and value.level>=7 then 1 else 0
				alternative.workersLevel=0
				world:syncControls(1,alternative);checkPads()
			end
			if value.level>=10 then
				local skillState=table.clone(value)
				skillState.weaponLevel,skillState.trainingLevel,skillState.skillLevel=value.level,1,0
				world:syncControls(1,skillState)
				if not plot.Controls:FindFirstChild("SkillButton")then issue("missing eligible skill pad",label)end
				checkPads()
				if value.level==50 then
					local old=plot.Controls:FindFirstChild("SkillButton")
					local supports={}
					if old then for _,part in old:GetDescendants()do if part:IsA("BasePart")then table.insert(supports,part)end end end
					skillState.skillLevel=5;world:syncControls(1,skillState)
					if plot.Controls:FindFirstChild("SkillButton")or (old and old:IsDescendantOf(workspace))then issue("completed skill pad retained",label)end
					for _,support in supports do if support:IsDescendantOf(workspace)then issue("completed skill support retained",label)end end
					report.completedSkillPads+=1;checkPads()
				end
			end
			world:syncControls(1,value)
			for part,flag in flags do if part.Parent then part.CanQuery=flag end end
		end
		local transforms={CFrame.new(3300,30,-3100),CFrame.new(-3400,70,3200)*CFrame.Angles(0,.61,0)}
		for transformIndex,transform in transforms do
			world.model:PivotTo(transform*originalPivot)
			for _,civilization in civilizations do for level=1,50 do
				civilizationId=civilization.id
				label=civilization.id.." level "..level.." transform "..transformIndex
				local value=state(level)
				world:setOwner(1,civilization,9101,"GeometryMatrixTester",level)
				world:syncInfrastructure(1,value,civilization);world:syncControls(1,value)
				audit(value);report.variants+=1
				if level%5==0 then game:SetAttribute("SettlementGeometryVerificationPhase",label);task.wait()end
			end end
		end
		game:SetAttribute("SettlementGeometryMatrixEvidence",game.HttpService:JSONEncode(report))
		assert(report.variants==1300,"Incomplete geometry matrix")
		assert(report.skillPadChecks==13*41*2 and report.completedSkillPads==13*2,"Incomplete skill-pad geometry coverage")
		assert(report.failureCount==0,"Geometry matrix failures: "..game.HttpService:JSONEncode(report.examples))
		return {ok=true,cases=5,evidence=report,message="All 13 civilizations and 50 levels in two transformed worlds: native supports, roofs, intersections, bounds, exits and supported pads"}
	end)
	if not ok then
		report.error=tostring(result);report.lastVariant=label
		game:SetAttribute("SettlementGeometryMatrixEvidence",game.HttpService:JSONEncode(report))
	end
	container:Destroy();assert(ok,result);return result
end

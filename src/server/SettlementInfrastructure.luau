--!strict

local Shared = game:GetService("ReplicatedStorage").Shared
local Sites = require(Shared.SettlementSites)
local Camp = require(Shared.TrainingCampConfig)
local Development = require(Shared.SettlementDevelopment)
local Districts = require(script.Parent.SettlementDistricts)
local Tenders = require(script.Parent.FarmTenders)
local Infrastructure = {}

local function part(parent, name, size, frame, tint, material)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color=name,size,frame,tint
	p.Material=material or Enum.Material.Wood
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
	p.Parent=parent
	return p
end

local function label(parent, frame, name, text, tint)
	local board=part(parent,name,Vector3.new(12,2,.3),frame,tint,Enum.Material.WoodPlanks)
	local surface=Instance.new("SurfaceGui")
	surface.Face,surface.CanvasSize,surface.Parent=Enum.NormalId.Back,Vector2.new(600,120),board
	local textLabel=Instance.new("TextLabel")
	textLabel.Size,textLabel.BackgroundTransparency=UDim2.fromScale(1,1),1
	textLabel.Text,textLabel.TextColor3,textLabel.TextScaled=text,Color3.fromRGB(255,242,208),true
	textLabel.Font,textLabel.Parent=Enum.Font.GothamBold,surface
	return textLabel
end

local function model(parent,name,civ)
	local m=Instance.new("Model")
	m.Name,m.Parent=name,parent
	m:SetAttribute("CivilizationId",civ.id)
	return m
end

local function farmland(parent,frame,civ,workers,level)
	local farm=model(parent,"Farmland",civ)
	farm:SetAttribute("FarmLevel",level)
	for index,site in Sites.fields do
		local origin=frame*CFrame.new(site)
		local soil=part(farm,"Field"..index,Sites.fieldSize,origin*CFrame.new(0,-.55,0),Color3.fromRGB(107,78,47),Enum.Material.Ground)
		soil.CanCollide,soil.CanQuery=true,true
		local rows=if level>=2 then 3 else 2
		for row=-rows,rows do
			part(farm,"CropRow",Vector3.new(48,.8,2),origin*CFrame.new(0,.15,row*(if level>=2 then 5 else 6)),
				if civ.id=="egypt" or civ.id=="britain" then Color3.fromRGB(194,171,71) else Color3.fromRGB(107,147,66),Enum.Material.Grass)
		end
		if level>=2 then
			for _,side in {-1,1}do
				part(farm,"IrrigationChannel",Vector3.new(.8,.25,34),origin*CFrame.new(side*25,-.25,0),Color3.fromRGB(83,145,157),Enum.Material.SmoothPlastic)
			end
		end
		for _,side in {-1,1}do part(farm,"FieldFence",Vector3.new(56,.5,.5),origin*CFrame.new(0,1.5,side*20),Color3.fromRGB(141,104,61)) end
	end
	for index=1,1+workers do Tenders.create(farm,frame,civ,index,level) end
	part(farm,"CollectionCrate",Vector3.new(6,4,5),frame*CFrame.new(-24,1,-152),Color3.fromRGB(151,109,59))
	label(farm,frame*CFrame.new(-24,4.2,-152),"FarmStatus","FARM I",civ.color)
	farm:SetAttribute("WorkerCount",1+workers)
	return farm
end

local function trainingYard(parent,frame,civ)
	local yard=model(parent,"TrainingYard",civ)
	local origin=frame*CFrame.new(Camp.center+Vector3.new(0,-.85,0))
	local ground=part(yard,"TrainingGround",Camp.size,origin,Color3.fromRGB(139,115,77),Enum.Material.Ground)
	ground.CanCollide,ground.CanQuery=true,true
	local fire=model(yard,"Campfire",civ)
	for index=1,10 do
		local angle=index*math.pi*2/10
		local stone=part(fire,"FireRingStone",Vector3.new(1.7,.8,1.3),origin*CFrame.new(math.cos(angle)*3,.45,math.sin(angle)*3)
			*CFrame.Angles(0,-angle,0),Color3.fromRGB(103,106,105),Enum.Material.Slate)
		stone.Shape=Enum.PartType.Ball
	end
	for _,angle in {-.6,.6} do
		local log=part(fire,"FireLog",Vector3.new(5,.8,.8),origin*CFrame.new(0,.5,0)*CFrame.Angles(0,angle,0),Color3.fromRGB(99,65,39))
		log.Shape=Enum.PartType.Cylinder
	end
	local embers=part(fire,"Embers",Vector3.new(2.5,.2,2.5),origin*CFrame.new(0,.45,0),Color3.fromRGB(242,114,24),Enum.Material.Neon)
	local flame=Instance.new("Fire")
	flame.Name,flame.Size,flame.Heat="CampFlame",4,3
	flame.Color,flame.SecondaryColor=Color3.fromRGB(255,174,53),Color3.fromRGB(255,82,20)
	flame.Parent=embers
	local light=Instance.new("PointLight")
	light.Color,light.Range,light.Brightness=Color3.fromRGB(255,179,86),16,1.8
	light.Shadows,light.Parent=false,embers
	for _,side in {-1,1} do
		part(yard,"LogSeat",Vector3.new(1,1,5),origin*CFrame.new(side*12,.7,0),Color3.fromRGB(120,83,47))
		part(yard,"CampBanner",Vector3.new(.25,5,.25),origin*CFrame.new(side*12,2.5,-12),Color3.fromRGB(100,77,53))
		part(yard,"CampColors",Vector3.new(2.5,2,.15),origin*CFrame.new(side*12,4,-12),civ.color,Enum.Material.Fabric)
	end
	label(yard,origin*CFrame.new(0,4,13),"TrainingLabel","TRAINING CAMP I",civ.color)
	local length=Camp.approachInnerX-Camp.center.X
	part(parent,"TrainingApproach",Vector3.new(length,.1,6),frame*CFrame.new((Camp.center.X+Camp.approachInnerX)/2,-.8,Camp.center.Z),
		Color3.fromRGB(151,131,94),Enum.Material.Ground)
	return yard
end

function Infrastructure.sync(plot,frame,civ,state)
	local folder=plot:FindFirstChild("Infrastructure")
	if not folder then folder=Instance.new("Folder");folder.Name="Infrastructure";folder.Parent=plot end
	if not civ or not state then folder:ClearAllChildren();folder:SetAttribute("BuildKey",nil);return end
	local key=string.format("%s:%d:%d:%d:%d:%d:%d:%d:%d",civ.id,if state.level>=2 then 1 else 0,
		state.trainingLevel or 0,state.farmLevel or 0,state.workersLevel or 0,state.armyCampLevel or 0,
		state.blacksmithLevel or 0,state.armorerLevel or 0,state.storehouseLevel or 0)
	if folder:GetAttribute("BuildKey")~=key or folder:GetAttribute("BuildFrame")~=frame then
		folder:ClearAllChildren()
		if state.level>=2 then
			Districts.house(folder,frame*CFrame.new(Sites.armory),civ,10,"Armory")
			label(folder.Armory,frame*CFrame.new(24,8,14.5),"ArmoryLabel","ARMORY",civ.color)
		end
		if (state.trainingLevel or 0)>0 then
			trainingYard(folder,frame,civ)
		end
		if (state.armyCampLevel or 0)>0 then
			Districts.house(folder,frame*CFrame.new(Sites.armyCamp),civ,12,"ArmyCamp")
			label(folder.ArmyCamp,frame*CFrame.new(-24,8,31.5),"CampLabel","ARMY CAMP I",civ.color)
		end
		if (state.farmLevel or 0)>0 then farmland(folder,frame,civ,state.workersLevel or 0,state.farmLevel) end
		if (state.workersLevel or 0)>0 then
			local workers=state.workersLevel
			Districts.house(folder,frame*CFrame.new(Sites.workers+Vector3.new(0,-1.7,0)),civ,if workers>=2 then 12 else 10,"WorkerCamp")
			folder.WorkerCamp:SetAttribute("WorkersLevel",workers)
			label(folder.WorkerCamp,frame*CFrame.new(60,6,-137.5),"WorkersLabel","WORKER CAMP "..(if workers>=2 then "II" else "I"),civ.color)
			if workers>=2 then
				for index=1,3 do
					part(folder.WorkerCamp,"FarmTools",Vector3.new(.2,3,.2),frame*CFrame.new(67,index*.15+.8,-147+index),Color3.fromRGB(123,86,46))
				end
			end
		end
		for _,building in {{track="blacksmith",name="Blacksmith",text="BLACKSMITH I\n5% LOWER WEAPON COSTS"},
			{track="armorer",name="Armorer",text="ARMORER I\n5% LOWER ARMOR COSTS"},
			{track="storehouse",name="Storehouse",text="STOREHOUSE I\n180 FARM COINS"}} do
			local field=Development.fields[building.track]
			if (state[field] or 0)<1 then continue end
			local site=Sites[building.track]
			Districts.house(folder,frame*CFrame.new(site),civ,if building.track=="storehouse" then 12 else 10,building.name)
			local built=folder[building.name]
			built:SetAttribute(building.name.."Level",1)
			label(built,frame*CFrame.new(site+Vector3.new(0,8,6)),"BuildingLabel",building.text,civ.color)
			if building.track=="blacksmith" then
				part(built,"AnvilBase",Vector3.new(3,1.5,2),frame*CFrame.new(site+Vector3.new(0,2,5)),Color3.fromRGB(83,88,93),Enum.Material.Metal)
				part(built,"Anvil",Vector3.new(4,.6,1.5),frame*CFrame.new(site+Vector3.new(0,3.1,5)),Color3.fromRGB(108,115,120),Enum.Material.Metal)
				part(built,"ForgeGlow",Vector3.new(2,.3,1),frame*CFrame.new(site+Vector3.new(-3,2.5,3)),Color3.fromRGB(242,128,38),Enum.Material.Neon)
			elseif building.track=="armorer" then
				part(built,"ArmorStand",Vector3.new(.5,3,.5),frame*CFrame.new(site+Vector3.new(0,3,5)),Color3.fromRGB(111,80,49))
				part(built,"DisplayArmor",Vector3.new(2,2,1),frame*CFrame.new(site+Vector3.new(0,4,5)),civ.color,Enum.Material.Metal)
			else
				for _,x in {-3,3}do
					part(built,"GrainCrate",Vector3.new(3,3,3),frame*CFrame.new(site+Vector3.new(x,2.5,5)),Color3.fromRGB(159,119,65))
				end
			end
		end
		folder:SetAttribute("BuildKey",key);folder:SetAttribute("BuildFrame",frame)
	end
	local farm=folder:FindFirstChild("Farmland")
	if farm then
		local board=farm.FarmStatus:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
		board.Text=string.format("FARM %s · %d/%d COINS\n+%d EVERY %ds",if state.farmLevel>=2 then "II" else "I",
			state.farmCoins or 0,Development.storageCapacity(state),Development.farmYield(state),Development.tickSeconds)
	end
end

function Infrastructure.status(plot,frame,state)
	local missing=if state then Development.offer(state,"settlement").missing else {}
	local folder=plot:FindFirstChild("Infrastructure")
	if not folder then return end
	local board=folder:FindFirstChild("MilestoneStatus")
	if #missing==0 then if board then board:Destroy() end;return end
	if not board then
		label(folder,frame*CFrame.new(12,4,9),"MilestoneStatus","",Color3.fromRGB(71,62,46))
		board=folder.MilestoneStatus
		board:SetAttribute("MainHallChecklist",true)
	end
	board:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel").Text="LEVEL 10 NEEDS\n"..table.concat(missing," · ")
end

function Infrastructure.animate(modelRoot,now)
	for _,plot in modelRoot.Plots:GetChildren()do
		local folder=plot:FindFirstChild("Infrastructure")
		local farm=folder and folder:FindFirstChild("Farmland")
		if not farm then continue end
		for _,worker in farm:GetChildren()do
			if worker:GetAttribute("PassiveWorker")==true then
				Tenders.animate(worker,plot.Foundation.CFrame,now)
			end
		end
	end
end

return Infrastructure

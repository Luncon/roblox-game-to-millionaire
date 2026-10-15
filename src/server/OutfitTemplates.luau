--!strict

local ServerStorage=game:GetService("ServerStorage")
local Visuals=require(script.Parent.EquipmentVisuals)
local Outfits={}
local OWNER="CivilizationOutfit"
local states={}
local clothing={Shirt={"ShirtTemplate","Color3"},Pants={"PantsTemplate","Color3"},ShirtGraphic={"Graphic","Color3"}}
local r15={Torso="UpperTorso",["Left Arm"]="LeftUpperArm",["Right Arm"]="RightUpperArm",
	["Left Leg"]="LeftUpperLeg",["Right Leg"]="RightUpperLeg",Head="Head"}
local colors={Head="HeadColor3",Torso="TorsoColor3",UpperTorso="TorsoColor3",LowerTorso="TorsoColor3",
	["Left Arm"]="LeftArmColor3",LeftUpperArm="LeftArmColor3",LeftLowerArm="LeftArmColor3",LeftHand="LeftArmColor3",
	["Right Arm"]="RightArmColor3",RightUpperArm="RightArmColor3",RightLowerArm="RightArmColor3",RightHand="RightArmColor3",
	["Left Leg"]="LeftLegColor3",LeftUpperLeg="LeftLegColor3",LeftLowerLeg="LeftLegColor3",LeftFoot="LeftLegColor3",
	["Right Leg"]="RightLegColor3",RightUpperLeg="RightLegColor3",RightLowerLeg="RightLegColor3",RightFoot="RightLegColor3"}

local function restore(character,state)
	-- An external edit to a generated garment promotes it to avatar clothing.
	-- Never destroy that edit merely because we originally created the instance.
	local promoted={}
	for object in state.created do
		if object.Parent~=character then continue end
		for property,record in state.fields[object] or {} do
			if object[property]~=record.last then promoted[object]=true;break end
		end
		if promoted[object] then
			if object:GetAttribute("GeneratedBy")==OWNER then object:SetAttribute("GeneratedBy",nil) end
			object:SetAttribute("OutfitCivilizationId",nil)
		else object:Destroy() end
	end
	for object,fields in state.fields do
		if object.Parent~=character or state.created[object] or promoted[object] then continue end
		for property,record in fields do
			-- Foreign changes survive; the next apply captures them as its baseline.
			if object[property]==record.last then object[property]=record.original end
		end
	end
	for _,visual in state.visuals do if visual.Parent then visual:Destroy() end end
	state.fields,state.created,state.visuals={},{},{}
	character:SetAttribute("OutfitCivilizationId",nil)
end
local function stateFor(character)
	local state=states[character]
	if not state then
		state={fields={},created={},visuals={}}
		states[character]=state
		character.Destroying:Once(function() states[character]=nil end)
	end
	return state
end
local function write(state,object,property,value)
	local fields=state.fields[object]
	if not fields then fields={};state.fields[object]=fields end
	fields[property]={original=object[property],last=value}
	object[property]=value
end
local function finite(value): boolean return type(value)=="number" and value==value and math.abs(value)<1e7 end
local function validFrame(value): boolean
	if typeof(value)~="CFrame" then return false end
	for _,n in {value:GetComponents()} do if not finite(n) then return false end end
	return value.Position.Magnitude<=32
end
local function mountPiece(character,parent,source,civId,state,skipHead): boolean
	local bodyName,offset,reference=source:GetAttribute("BodyPart"),source:GetAttribute("BodyOffset"),source:GetAttribute("ReferenceSize")
	if type(bodyName)~="string" or not r15[bodyName] or (skipHead and bodyName=="Head") or not validFrame(offset)
		or typeof(reference)~="Vector3" or not finite(reference.X) or not finite(reference.Y) or not finite(reference.Z)
		or reference.X<=0 or reference.Y<=0 or reference.Z<=0 or reference.Magnitude>32 then return false end
	local base=character:FindFirstChild(bodyName) or character:FindFirstChild(r15[bodyName])
	if not base or not base:IsA("BasePart") then return false end
	local visual=Visuals.prepare(source)
	if not visual then return false end
	local ratio=base.Size/reference
	local scale=math.clamp(math.max(ratio.X,ratio.Z),.5,2)
	if math.abs(scale-1)>.001 then visual:ScaleTo(scale) end
	local handle=visual:FindFirstChild("Handle") :: BasePart
	local placement=CFrame.new(offset.Position*ratio)*(offset-offset.Position)
	if not validFrame(placement) then visual:Destroy();return false end
	local delta=base.CFrame*placement*handle.CFrame:Inverse()
	for _,part in visual:GetDescendants() do if part:IsA("BasePart") then part.CFrame=delta*part.CFrame end end
	visual:SetAttribute("GeneratedBy",OWNER)
	visual:SetAttribute("OutfitCivilizationId",civId)
	visual:SetAttribute("OutfitBodyPart",bodyName)
	visual.Parent=parent
	local weld=Instance.new("WeldConstraint")
	weld.Name,weld.Part0,weld.Part1,weld.Parent="OutfitBodyWeld",base,handle,handle
	table.insert(state.visuals,visual)
	return true
end

function Outfits.clear(character: Model)
	local state=states[character]
	if state then restore(character,state) end
end

function Outfits.apply(character: Model,civId: string,parentArmor: Model,skipHead: boolean?): boolean
	if character:GetAttribute("CustomMeleeModel")==true then return false end
	local state=stateFor(character)
	restore(character,state)
	local folder=ServerStorage:FindFirstChild("OutfitTemplates")
	local source=if folder then folder:FindFirstChild(civId) else nil
	if not source or not source:IsA("Model") then return false end
	local applied=false
	for class,properties in clothing do
		local preset=source:FindFirstChildOfClass(class)
		if not preset or preset[properties[1]]=="" then continue end
		local garments={}
		for _,item in character:GetChildren() do if item.ClassName==class then table.insert(garments,item) end end
		if #garments==0 then
			local garment=Instance.new(class)
			garment.Name="Civilization"..class
			garment:SetAttribute("GeneratedBy",OWNER)
			garment:SetAttribute("OutfitCivilizationId",civId)
			state.created[garment]=true
			table.insert(garments,garment)
		end
		for _,garment in garments do
			for _,property in properties do write(state,garment,property,preset[property]) end
			garment.Parent=character
		end
		applied=true
	end
	for _,piece in source:GetChildren() do
		if piece:IsA("Model") and mountPiece(character,parentArmor,piece,civId,state,skipHead==true) then applied=true end
	end
	if applied then
		-- Armor-only uniforms still hide modern avatar clothes and graphics.
		-- Blank existing fields without manufacturing empty clothing instances.
		for class,properties in clothing do
			local preset=source:FindFirstChildOfClass(class)
			if preset and preset[properties[1]]~="" then continue end
			for _,garment in character:GetChildren() do
				if garment.ClassName==class then write(state,garment,properties[1],"") end
			end
		end
	end
	local palette=source:FindFirstChildOfClass("BodyColors")
	if applied and palette then
		for _,body in character:GetChildren() do
			local property=colors[body.Name]
			if body:IsA("BasePart") and property then write(state,body,"Color",palette[property]) end
		end
	end
	if applied then character:SetAttribute("OutfitCivilizationId",civId) end
	return applied
end

return Outfits
